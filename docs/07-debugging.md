# 07 · 调试：日志、控制台、报错对照表

## 7.1 第一现场：`logs/` 目录

```
%USERPROFILE%\Documents\Paradox Interactive\Hearts of Iron IV\logs\
```

四个日志各管一摊（📗 wiki）：

| 文件 | 内容 |
| --- | --- |
| `error.log` | **主要战场**。游戏预判的潜在错误。注意它**通常不包含导致崩溃的错误**，只记录"意料之外的行为"，但崩溃往往由这些行为引发 |
| `game.log` | 游戏过程中 `log` 效果 / `log` 触发器输出的内容（自己打点用） |
| `text.log` | **本地化键重复**清单（同名键被定义了多次） |
| `system.log` | 系统/图形信息；配合 `-checksum` 启动参数输出校验和比对明细 |

崩溃记录在：

```
%USERPROFILE%\Documents\Paradox Interactive\Hearts of Iron IV\crashes\
```

**用法**：

1. 启动游戏前**清空或重命名** `error.log`（推荐），或先记住文件末尾的行号。
2. 进入游戏 → 触发你改的内容 → 退出。
3. 打开 `error.log`，**只看新增部分**（否则会被原版自带的上万行噪音淹没）。
4. 用 `Ctrl+F` 搜你的前缀（本项目 `hof_` / `heartofiron`）。

## 7.2 日志行的读法

大致形如：

```
[10:31:22][effect.cpp:1234]: Unexpected token: }
```

- 第一个方括号：时间（用来区分新旧错误）。
- 第二个方括号：引擎源文件与行号 → 告诉你**错误类型**（trigger / effect / localisation / gfx / sound / map）。
- 冒号后：具体信息，通常会带**你的文件名与行号**——这是最有价值的部分。

> ⚠️ 引擎报"文件 X 第 N 行"时，实际问题**往往在 N 行之前**（例如前面的块没闭合）。从 N 行往上找最近的 `{`/`}` 不平衡处。

## 7.3 启动参数（📗 官方 wiki）

设置位置：Steam → 库 → 右键 HOI4 → 属性 → 通用 → **启动选项**。也可以给 `hoi4.exe` 或 `dowser.exe` 建快捷方式，在"目标"的引号之后追加参数（参数之间空格分隔）。

| 参数 | 作用 |
| --- | --- |
| `-debug` | 完整开发者模式，**收益最大**，见下表 |
| `-crash_data_log` | 也开启调试模式，但**不含热重载** |
| `-checksum` | `system.log` 中输出校验和比对明细，用于定位联机校验和不一致 |

`-debug` 带来的 8 项收益：

1. **热重载（最关键）**：改 mod 里的文件**立刻在游戏内生效**，不用重启，也无需 `reload` 控制台命令，同时会自动把文件错误写进 `error.log`。
   ⚠️ 只对**启动时已存在**的文件有效。例外：被别处用**直接路径引用**的文件仍可加载，例如 `load_oob = "TAG_my_oob"`（指向 `history/units/TAG_my_oob.txt`）和 sprite 引用的 GFX 图片。另外 `history/countries/`、`history/states/`、`map/` 不支持热重载。
2. **地图错误不再崩游戏**：有 `MAP_ERROR` 时正常启动会直接崩，`-debug` 下能继续加载并记录日志。
3. **扩展错误日志**：把平时不记录的（含地图定义错误）都写进 `error.log`。
4. **自动打开日志**：有错误时自动弹出日志窗口；进入国家后可用右下角的**"错误狗"**图标再次打开。
5. **主菜单就能开 nudger**。
6. **主菜单按 `` ` `` 键**可查看 GUI 元素信息（名称、位置、所用 sprite）；等价于 `gui` 控制台命令。
7. **悬停显示调试信息**：省份 ID、所在州 ID、归属国/占领国 TAG 等；悬停国旗还能看到原始 TAG 与修饰 TAG。悬停 GUI 元素时 `Ctrl+Alt+右键` 可打开调试菜单并跳转到定义该元素的 GUI 文件。
8. **解锁更多控制台命令** + 和平会议自动存档。

⚠️ 代价：`-debug` 下**多人联机被禁用**，且性能下降。另外用控制台的 `debug` 命令只提供第 5~8 项，不是完整模式。

## 7.4 控制台命令

用 `~` 打开（部分键盘布局是 `` ` `` 或 `^`）。

**modder 最常用**：

| 命令 | 作用 |
| --- | --- |
| `tdebug` | 鼠标悬停时显示**省份 id / 州 id**（改地图、查 state 必备） |
| `debug` | 切换调试信息显示 |
| `research_on_icon_click` | 点图标直接完成研究（快速搭建测试局面） |
| `focus.nochecks` | 忽略国策的前置条件 |
| `focus.autocomplete` | 国策瞬间完成 |
| `pp` | 加政治点 |
| `manpower` | 加人力 |
| `xp` | 加经验 |
| `add_ideas <idea>` | 加国家精神 |
| `tag <TAG>` | 切换控制的国家 |
| `annex <TAG>` | 吞并 |
| `observe` | 观战模式 |
| `instantconstruction` | 瞬间建造 |

⚠️ 命令名随版本有增删，且部分需要 `-debug` 才可用。**用 `help` 命令列出当前版本的全部可用命令**——这是最可靠的确认方式。

## 7.5 常见报错对照表

| 日志关键字 | 真实原因 | 处理 |
| --- | --- | --- |
| `Unexpected token` / `Unexpected end of file` | 括号不匹配、漏 `}`、多写逗号 | 从报错行的**上方**找未闭合的块 |
| `Could not find event` / `unknown event` | 事件 id 拼错，或该文件根本没被加载 | 检查文件路径与 `is_triggered_only` |
| `Invalid scope` / `scope mismatch` | effect/trigger 用错了作用域（如对 country 用了 state 的东西） | 用 `every_*` / `owner` / `capital_scope` 切对作用域 |
| `unknown trigger` / `unknown effect` | 拼写错误，或该键在当前版本不存在 | 到原版文件里搜同类写法 |
| 界面显示 `hof_xxx` 原始键名 | 本地化键缺失 / BOM 缺失 / 目录不对 | 见 `04-localisation.md` 第 5 节 |
| `GFX_xxx` 相关 / 图片不显示 | `.gfx` 未注册、路径错、DDS 格式问题 | 见 `05-gfx-and-interface.md` |
| 某内容整体消失（idea/国策/事件成片不见） | **整文件覆盖**：你的同名文件把原版整个替换了 | 改原版文件必须复制整份，见 `01-basics.md` 1.8 |
| 开局地图/州异常 | `history/states/` 或 `map/` 被局部覆盖 | 用 `replace_path` 全量接管，或不要动 |
| 启动即崩 | 通常是 `map/`、`.gfx` 或 DLC 依赖问题 | 看 `crashes/` + `error.log` 末尾；二分法禁用改动定位 |
| `has_dlc` 相关告警 | mod 依赖某 DLC 内容但未启用 | 加 DLC 检查或声明依赖 |

## 7.6 二分定位法（最有效的调试手段）

改动很多、不知道哪出问题时：

1. 把本次改动**全部注释掉**（`#` 开头的行被忽略）或移出 mod 目录。
2. 恢复**一半**，启动，看错误是否出现。
3. 继续对出现错误的那一半二分。
4. 通常 3~4 轮就能定位到具体文件/代码块。

## 7.7 编码与行尾（📗 官方规则，务必背下来）

| 文件类型 | 编码 | 备注 |
| --- | --- | --- |
| 脚本 `.txt`（`common/`、`events/`、`history/`…） | **UTF-8 不带 BOM** | wiki 明确写 "UTF-8 **without** the byte order mark" |
| `descriptor.mod` | **UTF-8 不带 BOM** | wiki 明确写 "must NOT be saved in UTF-8 BOM format" |
| 本地化 `.yml` | **UTF-8 带 BOM** | 没有 BOM 会在日志报错，中文会乱码/不加载 |
| 一律不要用 | UTF-16 | 引擎不支持 |

- 行尾：`map/definition.csv` **必须 CRLF**，否则报 `Prov ... has no continent`；其它文件建议统一 CRLF，避免混合。
- `.gitattributes` 已按此配置（`*.yml` 用 `working-tree-encoding=UTF-8-BOM`），协作者不会互相破坏编码。
- **用户目录路径不能含非 ASCII 字符**：否则本地 mod 全部加载失败，且游戏打不开 `error.log`（弹 "The system cannot find the path specified"）。本机路径 `C:\Users\xuwei\Documents\...` 全 ASCII，安全。

## 7.8 提交前自检清单

- [ ] `error.log` 中**没有**本次改动引入的新错误
- [ ] 所有新增文本都能在游戏里正常显示（不是原始键名）
- [ ] 所有新增图片都能显示，且尺寸正确不变形
- [ ] 国策树连线无交叉、无孤立节点
- [ ] 事件能通过控制台/正常流程触发，选项按钮文字与效果一致
- [ ] 解除 `-debug` 后正常启动一次（确认不是调试模式掩盖了问题）
- [ ] `descriptor.mod` 与 `.mod` 的 `supported_version` 一致
