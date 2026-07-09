# Migration Rules

Choose the least surprising migration method.

## Move With Desktop Shortcut

Use for ordinary user folders such as project archives, presentation assets, images, exports, and old deliverables.

Pattern:

1. Move folder to `D:\DesktopArchive\<date>\`.
2. Create a `.lnk` shortcut on the desktop with the original display name.
3. Verify destination exists and source is gone.

Impact: desktop remains easy to use, but absolute paths to the old folder change.

## Move With Junction

Use for stable scratch roots such as `C:\tmp` when old scripts may still reference the original path.

Pattern:

1. Verify source is not a reparse point.
2. Move source to `D:\MigratedFromC\<name>`.
3. Create a junction at the original C path pointing to the D path.
4. Verify both paths show the same file count and size.

Impact: old paths continue to work, but future writes go to D:.

## Use App Settings

Use for cloud-sync, chat, browser profiles, package managers, model stores, and vendor app data.

Examples:

- WPSDrive and WPS Cloud Files: use WPS settings.
- WeChat data: use WeChat migration or storage settings.
- Lenovo AppData: use Lenovo app settings, cache clearing, or uninstall unused components.
- npm/pip/cache roots: prefer tool config such as `npm config set cache D:\Caches\npm --global` or `setx PIP_CACHE_DIR D:\Caches\pip`.

Impact: preserves app state and avoids corrupting databases or sync metadata.

## No Action

Use for system folders, program install folders, active worktrees, browser credentials, chat records, and unknown directories with running owning processes.

Impact: keeps the machine stable; report size and alternatives instead.
