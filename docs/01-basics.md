# 01 · 基础：mod 是什么、放在哪、怎么被加载

## 1.1 一句话定义

HOI4 的 mod = **一个文件夹 + 一个 `.mod` 描述文件**。游戏启动时按播放集里的顺序，把 mod 目录里的文件挂到原版目录之上；**路径和文件名相同就覆盖**。

没有编译器、没有 SDK、没有 API。全部是纯文本脚本 + 贴图/模型资源。

## 1.2 三个关键路径

### ① 游戏安装目录（只读，你的"参考书"）

```
<Steam库>\steamapps\common\Hearts of Iron IV\
```

Steam AppID = **394360**。定位方法：Steam 库 → 右键游戏 → 管理 → 浏览本地文件。

### ② 用户 mod 目录（游戏默认去这里找 mod）

```
%USERPROFILE%\Documents\Paradox Interactive\Hearts of Iron IV\mod\
```

⚠️ 注意"文档"文件夹可能被 OneDrive 或系统设置重定向到别的盘。同一层还有 `logs/`、`crashes/`、`settings.txt`、`launcher-v2.sqlite` 等。

### ③ Steam 创意工坊目录（订阅的 mod）

```
<Steam库>\steamapps\workshop\content\394360\<workshop_id>\
```

启动器会为每个工坊 mod 在 ② 里生成一个指向它的 `.mod` 文件。

## 1.3 两种开发位置

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| **A. 直接开发在 ②** | 在 `mod\heart_of_iron\` 里写代码 | 启动器自动识别，最省事 | 不方便 git 管理（路径含用户名/中文） |
| **B. 开发在本工作区 + 链接** | 代码放 `d:\...\heart_of_Iron\`，在 ② 里建目录联接 | git 友好、VS Code 友好 | 需要建链接 |

方案 B 的链接做法（Windows，管理员 PowerShell）：

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\Documents\Paradox Interactive\Hearts of Iron IV\mod\heart_of_iron" -Target "d:\Users\xuwei\PycharmProjects\heart_of_Iron"
```

⚠️ `.mod` 文件里的 `path` 是否支持绝对路径、是否支持指向 mod 目录之外，需实测。若启动器不认，退回方案 A。

## 1.4 最小可运行骨架

`mod\heart_of_iron\` 里面：

```
heart_of_iron/
├── descriptor.mod          # 必需：mod 元数据
├── common/                 # 游戏规则类脚本
├── events/                 # 事件
├── history/                # 国家/州/单位初始状态
├── localisation/
│   └── simp_chinese/       # 中文
├── gfx/                    # 图片
├── interface/              # .gfx 索引文件
├── map/                    # 仅地图 mod 需要
└── sound/                  # 音效
```

与 `heart_of_iron\` **同级**再放一个 `heart_of_iron.mod`：

```
mod/
├── heart_of_iron/          # 内容
└── heart_of_iron.mod       # 启动器入口
```

## 1.5 `descriptor.mod`（必需）

放在 mod 文件夹**内部**，描述 mod 本身：

```
version="0.1.0"
tags={
	"Gameplay"
	"Historical"
}
name="Heart of Iron"
supported_version="1.x.*"
```

可选字段：

```
dependencies={
	"Some Other Mod"
}
replace_path="history/states"
replace_path="common/characters"
picture="thumbnail.png"
```

## 1.6 `heart_of_iron.mod`（启动器入口）

放在 `mod/` 下，**与文件夹同级**。内容 = `descriptor.mod` 的内容 + `path`：

```
version="0.1.0"
tags={
	"Gameplay"
}
name="Heart of Iron"
supported_version="1.x.*"
path="mod/heart_of_iron"
```

- `path`：指向 mod 内容目录，相对 `mod/` 或绝对路径（⚠️ 绝对路径需实测）。
- `remote_file_id="1234567890"`：上传到创意工坊后启动器自动写入。
- **上传前两份文件要同步**，否则工坊页面信息和实际不符。

**只写在 `.mod`（用户级）里、写进 `descriptor.mod` 无效的属性**（📗 wiki）：

```
user_dir = "MyModSave"                 # 存档隔离目录，见 08-publishing.md
dependencies = { "Other Mod" }         # 只改加载顺序，见 8.3
replace_path = "history/states"        # 见 1.8
```

其它硬性要求（📗 wiki）：

| 要求 | 说明 |
| --- | --- |
| **不要存成 UTF-8 BOM** | `descriptor.mod` 明确不能带 BOM |
| `path` 分隔符 | **只能用正斜杠 `/`**。写 `mod\my_mod` 是错的——`\` 会被当成转义符 |
| `path` 字符集 | 只能是 **ASCII**。路径含中文/变音符号 → mod 加载失败 |
| `name` | 必须全局唯一，`dependencies` 靠它匹配 |
| `picture` | 必须是 mod 根目录下的文件，**< 1 MB**，写在 `name` 之后；本地 mod 在启动器里不会显示图片 |
| `thumbnail.png` | 工坊配图，建议 **1:1 比例**，Steam 用 `.png` |

**另一个隐蔽的坑**：用户目录路径本身含非 ASCII 字符时，放在里面的 mod 会全部加载失败、且 `error.log` 打不开。解法是改游戏目录 `launcher-settings.json` 的 `gameDataPath` 迁移整个用户目录。本机路径 `C:\Users\xuwei\Documents\...` 是纯 ASCII，安全。

## 1.7 `supported_version`

- 形式为 `"主版本.次版本.*"`，例如游戏版本是 `1.15.4` 就写 `"1.15.*"`。
- 版本号看**启动器标题栏或游戏主菜单右下角**，不要猜。
- 不匹配时启动器会警告，游戏通常仍能加载，但可能报错甚至崩溃。
- ⚠️ 本知识库写作时的 HOI4 主版本号未验证，请以你本机为准。

## 1.8 加载顺序与覆盖规则（最重要的一节）

**三条规则：**

1. **不同文件名 → 合并**。原版 `common/ideas/` 里有 20 个文件，你只放 1 个，结果是 21 个文件都被加载。
2. **相同相对路径 + 相同文件名 → 整文件覆盖**。后加载的完全取代先加载的，**包括文件里的每一行**。
3. **`replace_path="目录"` → 该目录原版文件全部不加载**，只用你的。

推论（血泪）：

- 想改原版 `common/ideas/_my_idea.txt` 里的一个数值 → 必须把**整个文件**复制到你的 mod 同路径下再改，否则那个文件里其它几百个 idea 全部消失。
- 想要**新增**内容 → 另起一个新文件名，放进对应目录，最安全。
- 加地图、大改 state/characters 才考虑 `replace_path`，因为它会让其它 mod 对同一目录的改动**全部失效**。

**顺序由谁定？**（📗 已按官方 wiki `Modding` 页校正，原文见 `reference/wiki/Modding.txt`）

完整加载顺序：

1. **游戏本体**（优先级最低）
2. **DLC**，按其内部 ID / 发售顺序
3. **用户目录**（通常只放 nudger 的输出，但放别的文件也生效）
4. **mods**，按用户目录里 `.mod` 文件的**文件名 ASCII 序**排序

也就是说：决定两个 mod 谁覆盖谁的，是 `mod/` 下**描述文件的名字**，不是启动器里手拖的顺序。

可以用这两个手段干预：

- `dependencies = { "A Mod" }`：强制本 mod 排在 A 之后加载（**只改顺序，不代表"必须安装 A 才能运行"**）。子 mod 必须用。
- 求值顺序（同类型条目在多文件重复时）也按**文件名 ASCII 序**：`00_` 前缀靠前，`zz_` 前缀靠后——这正是原版用 `00_` 命名的原因。

**另外两个细节**（📗 wiki）：

- mod 根目录等同于游戏根目录，**多套一层目录会导致文件完全不加载**（`mod/yourmod/test/common/...` ✗）。
- mod 里的 `dlc/` 目录**没有任何作用**。要改 DLC 的文件，必须按它在本体中的真实加载位置放，例如改 `dlc/dlc023_man_the_guns/music/mtg_music.txt` 要写成 `modname/music/mtg_music.txt`。

## 1.9 启动方式与调试入口

| 用途 | 做法 |
| --- | --- |
| 正常启动 | Paradox 启动器 → 播放集 → 播放 |
| 开发者模式 | Steam → 属性 → 启动选项 填 `-debug`（开控制台 + 详细日志 + 调试界面） |
| 开关控制台 | 游戏中按 `~`（部分键盘布局是 `` ` `` 或 `^`） |
| 看日志 | `Documents\Paradox Interactive\Hearts of Iron IV\logs\error.log` |
| 看崩溃 | 同级的 `crashes\` 目录 |

⚠️ 其它启动参数（如 nudge 地图工具）的确切写法见 `99-todo-verify.md`。

## 1.10 成就与校验和

- **启用任何 mod 都会禁用成就**（无例外）。
- 主菜单显示的**校验和（checksum）**会随 mod 改变。
- 多人联机要求双方**校验和一致**，即 mod 组合与顺序完全一致。
