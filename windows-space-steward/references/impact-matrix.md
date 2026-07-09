# Impact Matrix

Use these impact notes whenever presenting cleanup, migration, or duplicate options.

| Item type | Risk | Impact if deleted or moved | Recommendation |
| --- | --- | --- | --- |
| User Temp older than 7 days | Low | Some installers or apps may leave locked files; skipped locked files are normal. Deleted files are usually disposable. | Delete stale entries only. |
| pip cache | Low | Future package installs may re-download wheels and source archives. Offline reuse is lost. | Safe to delete. |
| npm cache / npx cache | Low | Future npm or npx commands may re-download tools. | Safe to delete; use npm first, then remove `_npx` only if inside npm cache. |
| Browser Cache, Code Cache, GPUCache | Low | Websites may load slower once; cache rebuilds automatically. | Safe to delete while browser is closed or script accepts it. |
| Browser Service Worker / Local Storage / Cookies / Login Data | Medium to High | Offline site data, sessions, settings, or credentials may be lost. | Do not delete unless explicitly requested and explained. |
| Codex runtime cache | Medium | Codex may re-download runtime dependencies; never clean while Codex is running. | Clean only after Codex is closed. |
| Codex worktrees or active projects | High | Work can be lost or hidden from current threads. | Never delete automatically. |
| Windows Temp | Medium | Requires elevation for full cleanup; locked files are expected. | Delete stale entries only. |
| DISM component cleanup | Medium | Can reclaim component-store space but needs admin; `/ResetBase` prevents uninstalling old updates. | Use `/AnalyzeComponentStore`, then `/StartComponentCleanup`; never `/ResetBase`. |
| Desktop project folders | Low to Medium | Files remain usable if moved, but old absolute paths may break. | Move to D: and create desktop shortcuts. |
| C:\tmp or generated scratch outputs | Low to Medium | Old scripts expecting `C:\tmp` may fail if path disappears. | Move to D: and preserve old path with a junction if needed. |
| WPSDrive / WPS Cloud Files | Medium | Direct moves can break sync state or offline cache. | Use WPS settings or clear offline cache in the app. |
| WeChat data | High | Chat history, files, images, and account data can be damaged. | Do not move or delete directly; use app migration tools. |
| Lenovo AppData / browser data | Medium to High | Lenovo services or browser profiles may break. | Use Lenovo settings, clear cache, or uninstall unused components. |
| Duplicate files with identical hash | Low to Medium | Content remains available at the kept path; removed path will no longer open unless indexed. | Ask keep-C/keep-D/keep-both; create desktop shortcut index to kept files. |
| Same name but different hash | High | Files are not duplicates despite same name. | Never delete automatically. |
