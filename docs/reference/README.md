# docs/reference —— 参考层（门厅）

> **2026-09 重排说明**：这里原先是 120 个文件平铺，脚本、产出、笔记、参考图混在一起，
> 几个月后自己都认不出来。现在按**文件种类**分桶，规则是机械的（只看扩展名），
> 所以不会再退化。重排是脚本执行的，可复现：`build/reorg-reference.ps1`。

## 目录约定

| 目录 | 放什么 | 规则 |
| --- | --- | --- |
| **`INDEX.md`** | **脚本 ↔ 产出 对照索引（自动生成）** | **找不到东西时第一个看这里** |
| `tools/` | 勘查脚本（`.ps1` / `.py`） | 只读游戏 / mod 文件；结论打到 stdout 或 `../reports/` |
| `reports/` | 脚本的产出（`.txt`） | 引用它们时写 `docs/reference/reports/<名>` |
| `notes/` | 知识性笔记（`.md`） | 整理过的结论，不是程序产出 |
| `images/` | 参考图（`.png`） | 从游戏 DDS 转出来的对照图 |
| `wiki/` | **Paradox 官方 wiki 离线快照**（32 页） | 见下文 |
| 根目录 | 只留本文件 | 任何散落文件都该归入上面某一类 |

**命名约定（新增脚本请遵守）**：`<scan|dump|verify|check|find|get|list>-<主题>-<对象>.ps1`
→ 产出 `<主题>-<对象>-report.txt`。这样脚本名和产出名对得上，索引也能自动配对。

**索引怎么刷新**：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build\gen-reference-index.ps1
```

---

## wiki/ —— 官方 wiki 离线快照（32 页）

用于给 `docs/01`~`docs/08` 的结论提供依据。

- `.html` = Wayback Machine 的原始存档
- `.txt` = 剥掉标签后的纯文本，**用 VS Code 全局搜索（`Ctrl+Shift+F`）时优先搜这里**

### 归档清单（32 页）

### 总纲 / 结构
| 页面 | 文本大小 | 用途 |
| --- | --- | --- |
| `Modding` | 78 KB | **总纲**：编码规则、加载顺序、`replace_path`、调试模式、GFX、日志、常见错误 |
| `Mod_structure` | 10 KB | mod 骨架、`descriptor.mod`、子 mod、本地 mod 示例 |
| `Replace_path` | 59 KB | `replace_path` 专页 |
| `Troubleshooting` | 21 KB | 排错 |
| `Nudger` | 25 KB | 内置地图编辑器 |

### 脚本参考（最常查）
| 页面 | 文本大小 | 用途 |
| --- | --- | --- |
| `Effects` | 226 KB | **效果全集** |
| `Triggers` | 154 KB | **条件全集** |
| `Modifiers` | 119 KB | 修饰符全集 |
| `Scopes` | 3 KB | 作用域速查 |
| `On_actions` | 30 KB | 钩子 |

### 内容系统
| 页面 | 文本大小 |
| --- | --- |
| `National_focus_modding` | **74 KB** — 国策树：`shared_focus` / `joint_focus` / inlay window / shortcut / AI strategy plans |
| `Military_industrial_organization` | 67 KB |
| `Country_creation` | 53 KB |
| `Idea_modding` / `Ideas` | 31 / 38 KB |
| `Divisions` | 29 KB |
| `Interface` | 27 KB |
| `Equipment` / `Technologies` / `Ideologies` / `Doctrines` / `Buildings` | 15~18 KB 各 |
| `States` / `Characters`(未取到) / `Decisions` / `Events` / `Cosmetic_tag` / `Units` | 4~15 KB 各 |

### 本地化 / 地图
| 页面 | 文本大小 |
| --- | --- |
| `Localisation` | 54 KB — 语言、文件名规则、BOM、颜色码、`replace/` 技巧 |
| `Map_modding` | 74 KB — `definition.csv`、高度图、省份位图、大洲、补给与铁路 |

### 音频 / 阵营 / 其它
`Factions` 50 KB、`National_focus` 12 KB（游戏机制侧）

> `Console_commands.txt` 只有 1 KB —— 抓到的是 Cloudflare 验证页，**无正文**。这是已知缺口。

## 抓取方式（复现用）

直连 wiki 会失败：

```
https://hoi4.paradoxwikis.com/Modding        -> HTTP 427 (Varnish / Fastly)
https://hoi4.paradoxwikis.com/robots.txt     -> HTTP 427
```

`hoi4.paradoxwikis.com` 被 DNS 解析到 `198.18.0.26`（`198.18.0.0/15`，代理工具的 fake-IP 网段），响应头带 `X-Served-By: cache-nrt-...`，说明请求确实到达了 Fastly，但**按出口 IP 被拒**。连 `robots.txt` 都拒 → 是整域名的访问控制，不是单页限制。

绕过办法 = Wayback Machine：

```powershell
# 1) 查最新快照
(Invoke-RestMethod "https://archive.org/wayback/available?url=hoi4.paradoxwikis.com/Modding").archived_snapshots.closest

# 2) 下载存档页
Invoke-WebRequest "<closest.url>" -OutFile "Modding.html" -UseBasicParsing
```

## 🚩 抓取时的两个大坑（踩过）

**坑 1：显式时间戳可能返回 Cloudflare 验证页。**
`/web/20260819071138/https://...` 这种精确快照地址拿到的可能是 4~13 KB 的 "Client Challenge" 页面（标题就是 `Client Challenge`），**没有正文**。

**坑 2：`/web/<年份>/` 跳转形式反而能拿到真页面。**
`https://web.archive.org/web/2025/https://hoi4.paradoxwikis.com/National_focus_modding` → 313 KB **真页面**。

所以每次抓完都必须**验证大小和内容**：

```powershell
# 大小 < 20 KB 基本就是验证页
(Get-Item "docs\reference\wiki\X.html").Length / 1KB
# 用关键词确认是否含正文
Select-String -Path "docs\reference\wiki\X.html" -Pattern 'shared_focus' -Quiet
```

其它经验：

- CDX API（`/cdx/search/cdx?...&output=json`）比 availability API 可靠，后者经常 502
- 页面已被 wiki 改名：`Effect_list` → `Effects`，`Trigger_list` → `Triggers`（用旧名查会得到 "NO SNAPSHOT"）
- 本机 `Invoke-WebRequest` 偶发"无法识别为 cmdlet"，此时改用 `curl.exe -sSL -o <文件> <url>`

## 尚未取到的页面

- `Characters`（角色系统）
- `Scripted_GUI`（脚本化 GUI，与国策树 inlay window 相关）
- `Console_commands`（现有快照是验证页，需换时间戳重抓）
- `Static_modifiers`、`Defines`、`Variables`、`Arrays`、`Event_targets`、`Cosmetic_tag`(已取)、`Bookmarks`、`Resources`、`Factions`(已取)

## 使用约定

1. 引用归档里的结论时，在正文标注 `📗 wiki` 并说明页面名，便于日后回溯。
2. **快照 ≠ 当前版本**。`Mod_structure` 已被 wiki 归入 `Category:1.9`（较旧），与 `Modding` 页冲突时以后者为准。
3. 最终裁决权仍在**你游戏当前版本的原版文件**，归档只是重要参考。
