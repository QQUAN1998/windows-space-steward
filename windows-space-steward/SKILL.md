---
name: "windows-space-steward"
description: "Safely inspect, clean, migrate, and deduplicate Windows C drive storage across C: and D:. Use when the user asks to clean a Windows computer, free C drive space, find what occupies C:, move safe data to another drive, compare duplicate files across drives, or create a cleanup plan with risk and impact explanations before deletion."
---

# Windows Space Steward

Use this skill to govern Windows C drive pressure without surprise deletion. Always inspect first, explain risk and impact, ask for confirmation, then execute the smallest approved action. Prefer Windows PowerShell 5.1+ scripts bundled in `scripts/`.

## Why This Is Different

- It treats disk cleanup as **storage stewardship**, not blind deletion.
- It explains what each cleanup or migration will affect before asking for confirmation.
- It separates safe cache cleanup, risky app data, durable user files, and migration candidates.
- It preserves access after migration with desktop shortcuts or junctions when appropriate.
- It scans C: and D: for true duplicate files using file hashes, not filenames alone.
- It creates a desktop retained-file index after duplicate-file decisions so the user can find the surviving copy.
- It avoids common breakages by refusing direct moves of WPS sync folders, WeChat data, browser credentials, Lenovo AppData, active Codex worktrees, and system paths.

## Core Workflow

1. **Discover pressure**
   - Run `scripts/discover-storage.ps1` for C drive summary, root folders, and hotspots.
   - Run `scripts/analyze_windows_drive.ps1` for cache candidates, running processes, and protected files.
   - Check all file-system drives with `Get-PSDrive -PSProvider FileSystem`.

2. **Preview cleanup**
   - Run cleanup scripts without `-Execute` first.
   - Use `scripts/cleanup-preview.ps1` for high-level safe-cache and migrate-not-delete candidates.
   - Use `cleanup_common_cache.ps1`, `cleanup_browser_cache.ps1`, `cleanup_codex_cache.ps1`, and `cleanup_windows_components.ps1` for category-specific dry runs.

3. **Scan duplicates**
   - Run `scripts/find_duplicate_files.ps1` across C and D user data roots.
   - Treat only identical hash matches as true duplicates.
   - List duplicates separately from cleanup candidates.
   - Ask the user whether to keep C, keep D, keep both, or skip each group.

4. **Explain impact before action**
   - Every table shown to the user must include: `Item`, `Size`, `Risk`, `Recommended action`, and `Impact if deleted or moved`.
   - Read `references/impact-matrix.md` when writing the impact column.

5. **Confirm exact scope**
   - Confirm exact categories, paths, or duplicate groups.
   - Never broaden a confirmed category during execution.
   - Do not delete or move anything just because it appears in a scan.

6. **Execute and verify**
   - Add `-Execute` only after explicit confirmation.
   - Re-check free space and rerun a preview after changes.
   - For duplicate-file choices, create a desktop index folder with shortcuts to retained files by using `scripts/create_duplicate_index.ps1`.

## Safety Rules

- Never manually delete or move `C:\Windows`, `C:\Program Files`, `C:\Program Files (x86)`, `C:\ProgramData`, application install directories, or system-managed files such as `pagefile.sys`, `hiberfil.sys`, and `swapfile.sys`.
- Do not follow junctions or symbolic links while scanning for migration or duplicates.
- Do not move active app data while the owning program is running.
- Do not directly move WPS, cloud-sync, WeChat, browser profile, or Lenovo AppData directories. Prefer in-app settings, cache clearing, or uninstalling unused software.
- Treat Codex worktrees, active project folders, chat records, browser credentials, cookies, local storage, and user documents as high-risk. Report them; do not delete automatically.
- Prefer moving ordinary user project folders to D: with desktop shortcuts. Use junctions only for stable temporary roots or when the user explicitly accepts preserving the old path.
- For Windows component cleanup, require elevation and dry-run analysis first. Never use DISM `/ResetBase`.

## Common Commands

Discover:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\discover-storage.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\analyze_windows_drive.ps1
```

Dry-run low-risk caches:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\cleanup_common_cache.ps1 -IncludeUserTemp -IncludeCrashDumps -IncludePipCache -TempOlderThanDays 7
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\cleanup_browser_cache.ps1 -Browser All
```

Dry-run Codex caches only when Codex is not running:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\cleanup_codex_cache.ps1 -IncludeRuntimeCache -IncludeTmp -IncludeOldBackups
```

Scan duplicates, writing a CSV for review:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\find_duplicate_files.ps1 -OutputCsv "$env:USERPROFILE\Desktop\duplicate-candidates.csv"
```

Create a desktop retained-file index after duplicate choices:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\create_duplicate_index.ps1 -DecisionsCsv .\duplicate-decisions.csv
```

## Output Format

Use these sections for a full run:

- `Pressure summary`: drive free space, risk level, and top storage offenders.
- `Cleanup candidates`: cache/temp candidates with impact.
- `Migration candidates`: paths that can move to D: and paths that must use app settings.
- `Duplicate candidates`: true hash duplicates, grouped with keep-C/keep-D choices.
- `Action plan`: exact actions awaiting confirmation.
- `Results`: deleted, moved, skipped, locked, indexed, and final free-space delta.

## Resources

- `references/impact-matrix.md`: impact descriptions for cleanup, migration, and duplicate choices.
- `references/migration-rules.md`: how to decide shortcut, junction, in-app migration, or no action.
- `scripts/find_duplicate_files.ps1`: hash-based duplicate scanner that skips system roots and reparse points.
- `scripts/create_duplicate_index.ps1`: builds a desktop folder with shortcuts to retained duplicate files and a CSV log.
