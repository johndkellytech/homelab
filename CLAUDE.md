# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

HomeLab infrastructure notes and engineering journal — networking, virtualization, OPNsense, Active Directory, and related lab work. Obsidian accesses this directory via a symlink at `~/Documents/brain/HomeLab/`.

## Repo Structure

Key files:
- `Build-Log.md` — engineering journal (daily config changes, troubleshooting, architectural decisions). Shared context between Claude and Gemini.
- `Network.md`, `OPNsense.md`, `DC01.md`, `Overview.md` — reference docs (Obsidian wiki-linked)

## Build Log

`Build-Log.md` is the shared journal. `GEMINI.md` carries the same directive so both assistants stay in sync.

- Read `Build-Log.md` at the start of any non-trivial lab or infrastructure work to catch recent changes.
- After any meaningful configuration change, troubleshooting resolution, or decision, append a dated entry so the other assistant sees it in the next session.

## Related

ITD 132 SQL project moved out on 2026-04-20 — now lives at `~/Documents/School/ITD132/` with its own CLAUDE.md.
