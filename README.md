# Windows Space Steward

Windows Space Steward is a Codex skill for safely governing Windows C drive storage across C: and D:. It helps an agent inspect disk pressure, preview safe cleanup, migrate ordinary user data, find duplicate files, and explain the impact of each action before anything is deleted or moved.

## Why It Is Different From Typical Cleanup Tools

Most cleanup tools optimize for deleting cache quickly. Windows Space Steward is designed for user trust and recoverability:

- **Impact-first decisions**: every cleanup or migration candidate must explain what will happen after deletion or movement.
- **Dry-run by default**: bundled cleanup scripts preview targets first and require explicit execution flags.
- **Storage governance, not blind deletion**: it separates disposable caches, durable user files, app-managed data, active workspaces, and system paths.
- **Migration that preserves access**: ordinary desktop project folders can move to D: while desktop shortcuts remain; stable scratch roots can move behind junctions when old paths must keep working.
- **Duplicate detection by hash**: it only treats files as true duplicates after size grouping and SHA256 hashing. Same name is not enough.
- **Desktop retained-file index**: after duplicate-file "keep one" decisions, it creates a desktop index folder with shortcuts to the retained files and a CSV decision log.
- **App-data caution**: it refuses direct moves of WPS sync folders, WeChat data, browser credentials, Lenovo AppData, active Codex worktrees, and Windows system folders.
- **C/D awareness**: it is built for machines where C: is the system drive and D: is the safer long-term home for archives, caches, AI data, and large generated assets.

## What It Can Do

- Report C: and D: free space and pressure level.
- Identify C: root offenders and user-profile hotspots.
- Preview and clean low-risk caches such as pip, npm/npx, browser cache, stale temp files, and crash dumps.
- Preview Codex runtime cache cleanup while refusing to touch it when Codex is running.
- Classify migration candidates into shortcut, junction, app-settings migration, or no-action.
- Scan true duplicate files across C: and D: user-data roots.
- Generate desktop shortcut indexes for retained duplicate files.

## Install

Copy the skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse .\windows-space-steward "$env:USERPROFILE\.codex\skills\windows-space-steward"
```

Restart Codex after installation.

## Typical Use

Ask Codex:

```text
Use $windows-space-steward to scan my C and D drives, preview cleanup and migration options, and explain impacts before making changes.
```

The skill should inspect first, present a table with size, risk, recommendation, and impact, then wait for confirmation before executing any cleanup, migration, or duplicate-file decision.

## Safety Notes

Windows Space Steward is not a one-click cleaner. That is intentional. It is designed to keep the user in control of:

- what gets deleted
- what gets moved
- which duplicate copy is retained
- what shortcuts or indexes remain afterward

It should never silently delete user documents, cloud-sync data, chat data, browser credentials, active projects, or system files.
