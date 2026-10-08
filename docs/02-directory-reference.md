# 02 · 目录对照表

> ⚠️ 本表来自模型知识整理，**未经本机原版文件核对**（本机未安装 HOI4）。使用前请对照 `steamapps/common/Hearts of Iron IV/` 实际目录。不确定条目在表尾「存疑」列出。

## 2.1 顶层目录

| 目录/文件 | 作用 | 你会改动它的频率 |
| --- | --- | --- |
| `common/` | 游戏规则总仓库：国家、idea、国策、决议分类、科技、建筑、AI、脚本化的 effect/trigger，以及各种定义文件 | ★★★★★ |
| `events/` | 事件定义（`country_event` / `news_event` / `state_event` / `unit_leader_event` 等） | ★★★★★ |
| `history/` | 开局状态：国家、州、部队、将领 | ★★★★ |
| `localisation/` | 文本，按语言分子目录 | ★★★★★ |
| `gfx/` | 图片、旗帜、模型、字体资源。⚠️ 与 `interface/` 是**两个不同目录** | ★★★ |
| `interface/` | `.gfx`（sprite 注册，把贴图绑定成 `GFX_xxx` 名字）与 `.gui`（界面布局） | ★★★ |
| `map/` | 地图。**门槛最高、最易崩**，仅做地图 mod 时需要 | ★ |
| `sound/` | 音效 | ★ |
| `music/` | 音乐 | ★ |
| `decisions/` | 决议内容 ⚠️（与 `common/decisions/` 的分工见存疑项） | ★★★ |
| `tools/` | 官方随游戏附带的工具/示例 | — |
| `dlc/` | DLC 内容，结构与本体一致 | **在 mod 内建 `dlc/` 目录完全无效**；要改 DLC 文件须按真实加载位置放 |
| `hoi4.exe` | 主程序 | 只读 |
| `dlc_load.json` | 记录启用的 mod（`"mod/xxx.mod"` 形式）与禁用的 DLC；启动器每次启动前覆写，也可手改来脱离启动器切换 | 少动 |

## 2.2 `common/` 细分（按用途）

| 路径 | 作用 |
| --- | --- |
| `common/country_tags/*.txt` | 定义国家 TAG：`TAG = "gfx/flags/TAG.tga"` |
| `common/countries/*.txt` | 国家属性（颜色、图形文化等） |
| `common/country_definitions/`? | ⚠️ 存疑，见 `99-todo-verify.md` |
| `common/ideologies/` | 意识形态定义 |
| `common/ideas/` | 国家精神 / 民族精神（`add_ideas` 的目标） |
| `common/characters/*.txt` | 角色系统（国家元首、将领、顾问、特工等） |
| `common/agencies/` | 情报机构 |
| `common/units/` | 兵种、装备（equipment）、单位统计 |
| `common/technologies/*.txt` | 科技树 |
| `common/national_focus/*.txt` | 国策树 |
| `common/decisions/categories/*.txt` | 决议**分类**定义 |
| `common/scripted_effects/*.txt` | 可复用 effect |
| `common/scripted_triggers/*.txt` | 可复用 trigger |
| `common/scripted_loc/` | 脚本化本地化命令 |
| `common/on_actions/*.txt` | 钩子：`on_startup`、`on_daily`、`on_monthly`、`on_state_control_changed`… |
| `common/buildings/` | 建筑定义 |
| `common/state_category/` | 州规模类别（人口/建筑位） |
| `common/bookmarks/` | 开局书签 |
| `common/ai_strategy/` | AI 行为倾向 |
| `common/ai_focuses/`、`ai_templates/`、`ai_equipment/` | AI 国策/编制/装备偏好 |
| `common/bop/` | 势力平衡（Balance of Power）⚠️ 依赖 DLC |
| `common/special_projects/` | 特殊科研项目 ⚠️ 依赖版本/DLC |
| `common/missions/` | 任务系统 ⚠️ 依赖版本/DLC |
| `common/defines/` | 全局数值常量 | 
| `common/scripted_guis/` | 脚本化 GUI ⚠️ 存疑，见待核实清单 |

## 2.3 `history/` 细分

| 路径 | 作用 | 关键语法 |
| --- | --- | --- |
| `history/countries/<TAG> - <Name>.txt` | 开局政治/资源/科技/部队 | 设政体支持率、稳定度、战争支持度、`load_oob` 等 |
| `history/states/<id>-<Name>.txt` | 州：省份、人口、建筑、归属 | `state = { id= name= manpower= state_category= provinces={} owner= core= buildings= victory_points= }` |
| `history/units/*.txt` | 初始部队（OOB，Order of Battle） | 通过 `load_oob` 引用 |
| `history/general/*.txt`? | 将领 ⚠️ 新版已迁移到 `common/characters/` |
| `history/` 其它 | 外交关系、战争状态等 | 参考原版 |

## 2.4 命名建议（本项目）

| 类型 | 建议 |
| --- | --- |
| 自定义文件 | `hof_` 前缀，如 `common/ideas/hof_ideas.txt` |
| 自定义键/ID | `hof_` 前缀，如 `hof_my_idea` |
| 事件 | `heartofiron.1`、`heartofiron.2`（命名空间式） |
| 本地化 | `localisation/simp_chinese/hof_events.yml` |

**永远不要**把自定义内容塞进原版文件名里（那会触发整文件覆盖）。
