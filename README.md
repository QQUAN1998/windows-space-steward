# Windows Space Steward

Windows Space Steward 是一个面向 Codex 的 Windows 磁盘空间治理 Skill。它不是传统意义上的“一键清理垃圾”工具，而是帮助 AI 代理在 Windows 电脑上安全地完成 C 盘体检、清理预览、迁移规划、重复文件识别和可追溯处理。

它特别适合这类机器：C 盘是系统盘，D 盘还有较多空间，用户希望释放 C 盘，但又不想误删文档、破坏软件同步目录、弄丢微信/浏览器/Codex 数据。

## 核心亮点

- **先解释影响，再执行动作**  
  每个清理、迁移、去重候选项都必须说明“删除/迁移后会影响什么”，例如是否会导致下次重新下载缓存、是否可能破坏同步状态、是否会让旧路径失效。

- **默认只预览，不直接删除**  
  内置脚本默认 dry-run，先列出目标、大小、风险和跳过原因。只有用户明确确认后，才会加执行参数。

- **不是盲目清垃圾，而是磁盘空间治理**  
  它会区分：可丢弃缓存、普通用户资料、软件托管数据、系统目录、活跃项目、重复文件、可迁移目录。不同类型走不同策略。

- **迁移后尽量不影响使用**  
  普通桌面项目可迁到 D 盘并在桌面保留快捷方式；稳定临时目录可迁到 D 盘并用 junction 保持原路径可用；WPS、微信、浏览器、Lenovo AppData 等软件数据则提示走软件设置，不直接手搬。

- **重复文件按 hash 识别，不靠文件名猜**  
  先按大小分组，再计算 SHA256。只有 hash 一致才算真正重复。文件名相同但内容不同不会被误判为可删。

- **二选一后建立桌面索引**  
  如果用户在 C/D 两盘重复文件中选择只保留一个副本，Skill 会创建桌面索引文件夹，里面放保留文件快捷方式和 CSV 处理记录，避免“清完以后找不到文件”。

- **专门保护高风险数据**  
  默认不直接删除或移动 Windows 系统目录、Program Files、ProgramData、WPS 同步目录、微信聊天记录、浏览器登录数据、Lenovo AppData、Codex worktrees、用户文档和活动项目。

## 能做什么

- 扫描 C/D 盘容量、C 盘压力和主要占用来源。
- 找出 C 盘根目录大项、用户目录热点、AppData 热点、AI/开发工具缓存。
- 预览并清理低风险缓存：pip、npm/npx、浏览器 Cache/Code Cache/GPUCache、过期 Temp、崩溃转储。
- 在 Codex 运行时拒绝清理 Codex runtime/tmp cache，避免破坏当前会话。
- 判断哪些内容适合迁移到 D 盘，哪些必须通过软件设置迁移，哪些不应该动。
- 扫描 C/D 盘真实重复文件，并让用户选择保留 C、保留 D、都保留或跳过。
- 对重复文件处理结果生成桌面快捷方式索引和处理记录。

## 典型工作流

1. 扫描 C/D 盘容量和 C 盘热点。
2. 罗列可清理项，并说明大小、风险、建议动作和删除影响。
3. 罗列可迁移项，并说明迁移方式和迁移影响。
4. 扫描重复文件，只把 hash 一致的文件列为真重复。
5. 等待用户确认具体要清理、迁移或二选一的项目。
6. 执行最小范围动作。
7. 复查剩余空间，生成桌面索引和结果报告。

## 和普通清理工具的区别

| 维度 | 普通清理工具 | Windows Space Steward |
| --- | --- | --- |
| 默认行为 | 倾向一键删除 | 默认预览，确认后才执行 |
| 风险说明 | 常只显示“可释放多少空间” | 必须说明删除/迁移后的影响 |
| 文件迁移 | 通常不处理 | 支持快捷方式、junction、软件设置迁移建议 |
| 重复文件 | 可能按文件名/大小判断 | 必须 hash 一致才算重复 |
| 用户可追溯 | 删除后很难知道保留在哪 | 二选一后创建桌面索引 |
| 软件数据 | 容易误清缓存或配置 | 明确保护 WPS、微信、浏览器、Lenovo、Codex 等高风险目录 |
| 定位 | 清理工具 | C/D 盘空间治理助手 |

## 安装

把 skill 文件夹复制到 Codex skills 目录：

```powershell
Copy-Item -Recurse .\windows-space-steward "$env:USERPROFILE\.codex\skills\windows-space-steward"
```

然后重启 Codex。

## 使用方式

在 Codex 中这样说：

```text
Use $windows-space-steward to scan my C and D drives, preview cleanup and migration options, and explain impacts before making changes.
```

或者中文：

```text
用 windows-space-steward 帮我扫描 C/D 盘，列出可清理、可迁移、重复文件，并说明每一项处理后的影响，等我确认后再执行。
```

## 安全边界

Windows Space Steward 不是为了“尽可能删得多”，而是为了“释放空间但不制造混乱”。它应该始终遵守：

- 不静默删除用户文档。
- 不直接移动系统目录和程序安装目录。
- 不直接搬 WPS、微信、浏览器、Lenovo AppData 等软件托管数据。
- 不在 Codex 运行时清理 Codex runtime cache。
- 不把文件名相同当成重复文件。
- 不在用户确认前删除、迁移或去重。
- 去重后必须保留桌面索引，让用户能找到最终保留文件。

## English Summary

Windows Space Steward is a Codex skill for safely governing Windows C drive storage across C: and D:. It helps an agent inspect disk pressure, preview safe cleanup, migrate ordinary user data, find true duplicate files by hash, and explain the impact of each action before anything is deleted or moved.

It is different from typical cleanup tools because it is impact-first, dry-run-first, migration-aware, duplicate-indexed, and cautious around app-managed data such as WPS, WeChat, browser profiles, Lenovo AppData, and active Codex worktrees.
