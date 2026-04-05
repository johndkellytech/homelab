-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 05_procedures_triggers.sql
-- Description: Stored procedures, triggers, and transaction examples.
-- =============================================================

USE it_infrastructure;

DELIMITER $$

-- -------------------------------------------------------------
-- STORED PROCEDURE 1: sp_record_scan_result
-- Logs a new vulnerability scan finding for a host or VM.
-- Usage: CALL sp_record_scan_result('CVE-2021-44228', NULL, 3, CURDATE(), 'Found on web VM');
-- -------------------------------------------------------------
CREATE PROCEDURE sp_record_scan_result(
    IN p_cve_id         VARCHAR(20),
    IN p_host_id        INT,            -- pass NULL if target is a VM
    IN p_vm_id          INT,            -- pass NULL if target is a Host
    IN p_scan_date      DATE,
    IN p_notes          TEXT
)
BEGIN
    DECLARE v_vuln_id INT;

    -- Validate: exactly one of host_id / vm_id must be provided
    IF (p_host_id IS NULL AND p_vm_id IS NULL) OR
       (p_host_id IS NOT NULL AND p_vm_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Provide either host_id OR vm_id, not both and not neither.';
    END IF;

    -- Look up the vulnerability by CVE ID
    SELECT vuln_id INTO v_vuln_id
    FROM VULNERABILITIES
    WHERE cve_id = p_cve_id
    LIMIT 1;

    IF v_vuln_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CVE ID not found in VULNERABILITIES table.';
    END IF;

    -- Insert the scan result
    INSERT INTO SCAN_RESULTS (vuln_id, host_id, vm_id, scan_date, remediated, notes)
    VALUES (v_vuln_id, p_host_id, p_vm_id, p_scan_date, 0, p_notes);

    SELECT LAST_INSERT_ID() AS new_scan_id;
END$$

-- -------------------------------------------------------------
-- STORED PROCEDURE 2: sp_remediate_scan
-- Marks a scan result as remediated with today's date.
-- Usage: CALL sp_remediate_scan(3, 'Patched Log4j to 2.17.1');
-- -------------------------------------------------------------
CREATE PROCEDURE sp_remediate_scan(
    IN p_scan_id    INT,
    IN p_notes      TEXT
)
BEGIN
    UPDATE SCAN_RESULTS
    SET remediated       = 1,
        remediation_date = CURDATE(),
        notes            = CONCAT(IFNULL(notes, ''), ' | REMEDIATED: ', p_notes)
    WHERE scan_id = p_scan_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Scan ID not found.';
    END IF;

    SELECT CONCAT('Scan ', p_scan_id, ' marked as remediated.') AS result;
END$$

-- -------------------------------------------------------------
-- STORED PROCEDURE 3: sp_get_risk_report
-- Returns open vulnerabilities for a given severity level.
-- Usage: CALL sp_get_risk_report('Critical');
-- -------------------------------------------------------------
CREATE PROCEDURE sp_get_risk_report(
    IN p_severity VARCHAR(20)
)
BEGIN
    SELECT
        sr.scan_id,
        v.cve_id,
        v.vuln_name,
        v.severity,
        v.cvss_score,
        COALESCE(h.hostname, vm.vm_name)    AS asset_name,
        CASE WHEN sr.host_id IS NOT NULL THEN 'Host' ELSE 'VM' END AS asset_type,
        sr.scan_date,
        sr.notes
    FROM SCAN_RESULTS sr
    JOIN VULNERABILITIES v  ON sr.vuln_id   = v.vuln_id
    LEFT JOIN HOSTS h       ON sr.host_id   = h.host_id
    LEFT JOIN VIRTUAL_MACHINES vm ON sr.vm_id = vm.vm_id
    WHERE sr.remediated = 0
      AND (p_severity IS NULL OR v.severity = p_severity)
    ORDER BY v.cvss_score DESC, sr.scan_date ASC;
END$$

-- -------------------------------------------------------------
-- TRIGGER 1: trg_prevent_delete_active_host
-- Prevents deletion of a host that still has running VMs.
-- -------------------------------------------------------------
CREATE TRIGGER trg_prevent_delete_active_host
BEFORE DELETE ON HOSTS
FOR EACH ROW
BEGIN
    DECLARE v_vm_count INT;

    SELECT COUNT(*) INTO v_vm_count
    FROM VIRTUAL_MACHINES
    WHERE host_id = OLD.host_id
      AND status IN ('Running', 'Suspended');

    IF v_vm_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete host: it still has active or suspended VMs.';
    END IF;
END$$

-- -------------------------------------------------------------
-- TRIGGER 2: trg_log_critical_scan
-- When a Critical vuln scan is inserted, automatically creates
-- a second scan note flagging it for the Security team.
-- (Demonstrates trigger on INSERT + conditional logic)
-- -------------------------------------------------------------
CREATE TRIGGER trg_flag_critical_scan
AFTER INSERT ON SCAN_RESULTS
FOR EACH ROW
BEGIN
    DECLARE v_severity VARCHAR(20);

    SELECT severity INTO v_severity
    FROM VULNERABILITIES
    WHERE vuln_id = NEW.vuln_id;

    IF v_severity = 'Critical' THEN
        -- Update the notes to flag it (we can't INSERT into same table in MySQL trigger easily)
        UPDATE SCAN_RESULTS
        SET notes = CONCAT(IFNULL(notes, ''), ' [AUTO-FLAG: CRITICAL — requires Security team review]')
        WHERE scan_id = NEW.scan_id;
    END IF;
END$$

DELIMITER ;

-- -------------------------------------------------------------
-- TRANSACTION EXAMPLE: Decommission a VM atomically
-- Marks the VM as deleted and removes its licenses in one transaction.
-- -------------------------------------------------------------
START TRANSACTION;

    -- Step 1: mark the VM as deleted
    UPDATE VIRTUAL_MACHINES
    SET status = 'Deleted'
    WHERE vm_id = 9;   -- replace with target vm_id

    -- Step 2: remove its software licenses
    DELETE FROM SOFTWARE_LICENSES
    WHERE vm_id = 9;

    -- If both succeed, commit
    COMMIT;

-- To roll back if something goes wrong:
-- ROLLBACK;
