# build/ — 构建流程

本目录是「Heart of Iron」的构建工具，**不参与游戏加载**（只有 `mod/heart_of_iron/` 会被加载）。

## 为什么需要构建流程

HOI4 是**整文件覆盖**。要往某个国策树里加一个共享国策，就必须把这个文件整个复制进本 mod 再改。
R56 每次更新这些文件，我们都要重新合并——手工做不可维护，所以做成可重跑的脚本。

覆盖链：**原版 → R56 → 本 mod**。

## 文件

| 文件 | 作用 |
| --- | --- |
| `attach-points.json` | **挂载点清单**。哪个国家、复制哪个文件、树 id 是什么、第几相位做。**要增删挂载点只改这里。** |
| `sync-from-r56.ps1` | 读清单 → 从 R56 复制文件到 mod → 在锚点注入 `# hof:begin/end` 块 |
| `verify-sync.ps1` | 核对落盘结果：文件存在、**有无 BOM**、锚点是否唯一 |
| `fix-bom.ps1` | **BOM 归一化**：脚本类剥 BOM，`.yml` 加 BOM。**每次新增脚本文件后必跑。** |
| `verify-s2.ps1` | 核心圈窗口预检：括号配平、`scripted_images` 键与 `.gui` 组件名对应、本地化键、sprite 是否存在 |
| `sync-verify.txt` / `sync-result.txt` / `verify-sync-report.txt` / `bom-fix-report.txt` / `verify-s2-report.txt` | 脚本输出（可随时重跑覆盖） |

## 用法

```powershell
# 只校验锚点，不写任何文件（推荐先跑这个）
powershell -NoProfile -File sync-from-r56.ps1 -VerifyOnly

# 实际同步（默认只做 phase 1）
powershell -NoProfile -File sync-from-r56.ps1

# 含 phase 2
powershell -NoProfile -File sync-from-r56.ps1 -MaxPhase 2

# 核对结果
powershell -NoProfile -File verify-sync.ps1
```

## 注入机制

`sync-from-r56.ps1` 顶部的 `$InjectMap` 控制往哪些挂载点注入什么：

```powershell
$InjectMap = @{
    'sov_core' = @('hof_jf_sino_soviet')
}
```

注入结果（示例为 `sau_mutual`，冒烟测试已验证）：

```
focus_tree = {
	id = saudi_focus
	# hof:begin sau_mutual
	shared_focus = hof_smoketest_shared_focus
	# hof:end sau_mutual
	country = { ... }
```

- **锚点** = 文件内 `id = <treeId>` 那一行。脚本要求**恰好命中 1 次**，否则整个挂载点跳过不写（防止注错位置）。
- 注入行沿用锚点行的缩进，保持 diff 干净。
- **幂等**：每次都从 R56 源头重新生成，重复运行结果一致。已有 `# hof:begin/end` 块会被整块替换。

## 三条硬约束

1. **脚本 `.txt` / `.mod` / `descriptor.mod` 必须是 UTF-8 无 BOM。**
   ⚠️ `create_file` 工具**默认带 BOM**，新建这类文件后必须剥 BOM（跑 `fix-bom.ps1`）。
   `.yml` 本地化反之，**需要** BOM。
2. **`.mod` 文件名要排在 `Road to 56.mod` 之后**（ASCII 序），并且写 `dependencies = { "The road to 56 CN" }` 双保险。
3. **本机集成终端容易整体死掉**（连命令都不执行），且 **`Remove-Item` 被禁**。
   救急：用 VS Code 任务跑脚本、输出重定向到文件再读；删文件用 `[System.IO.File]::Delete()`。

## 🚩 构建脚本本身踩过的坑

### PowerShell 单引号字符串【不】解释转义序列

`'\tid = xxx'` 里的 `\t` 是**字面上的反斜杠 + t**，不是制表符。

踩过一次：用编辑工具改 `sync-from-r56.ps1` 的 `$InjectMap` 时写成了单引号 `'\tid = ...'`，
结果注入进 `soviet.txt` 的是语法垃圾：

```
	inlay_window = {
	\tid = hof_ic_inlay_window      <- 两个字符，不是缩进
```

**对策**：缩进用**双引号 + 反引号**（`` "`tid = ..." ``），或写真实制表符。
**防护**：`verify-s2.ps1` 已加专项检查，扫注入块里的字面量 `\t` / `\n` / `\r`。

> 教训：这类错误 HOI4 **不一定会报错**，属于最阴的静默失败。**校验脚本要针对“刚出过的错”加规则**，而不只是查通用语法。

## 当前状态

### S1 · 挂载点同步 ✅

- 17 个挂载点同步成功，205,698 行 / 4.39 MB，0 个 BOM，0 个锚点异常
- ⏳ phase 2：PHI / ARG / SWE / NOR / AFG / DEN / ICE / ETH 的另一棵可选树

### S2 · 空壳核心圈 ✅（含 v1 美术，位置已实测确认）

产出文件：

| 文件 | 说明 |
| --- | --- |
| `mod/heart_of_iron/common/focus_inlay_windows/hof_ic_inlay_window.txt` | 窗口内容定义；`visible` = 完成 `SOV_the_supreme_soviet`；8 个 `scripted_images` |
| `mod/heart_of_iron/interface/hof_ic_scripted_gui.gui` | 窗口本体，**全仿德国组件结构**（见下） |
| `mod/heart_of_iron/interface/hof_ic.gfx` | **sprite 间接层**：注册 `GFX_hof_ic_*`，指向哪张纹理由它决定 |
| `mod/heart_of_iron/localisation/simp_chinese/hof_ic_l_simp_chinese.yml` | 界面文本 |
| `soviet.txt` 内的 `# hof:begin sov_core` 块 | `inlay_window = { id = ... position = { x = 4000 y = 1200 } }` |

#### “全仿”具体仿了哪些组件

| 区域 | 组件 |
| --- | --- |
| 窗口 | 底板、标题 |
| **领袖位** | 立绘 + 圆形框 + **名牌绸带** + 名字 + **头衔框** + 头衔 |
| **席位×7** | 框 + 立绘 + **名牌底衬** + 名字 + **特质框** + 特质 |
| **底部候选栏** | 横条底衬 + 7 个小头像位 |

与德国的两处**有意差异**：① 席位 7 个而非 5 个，因 7 个横排放不进 620 宽，改为两排 4+3；② 所有 sprite 走 `GFX_hof_ic_*` 间接层。

#### 为什么要有 `hof_ic.gfx` 这层间接

`.gui` 里只写 `GFX_hof_ic_*`，具体指向哪张 DDS 由 `hof_ic.gfx` 决定。
**美术到位后只需改这一个文件里的 `texturefile` 路径，`.gui` 一行都不用动。**

#### ⚠️ 重要教训：第一版美术用错了

初版为了“先跑通显示”，直接沿用了原版德国核心圈的 sprite。结果里面含有**带国家符号的图像**：

| 用错的 sprite | 实际内容 |
| --- | --- |
| `GFX_ascended_advisors_unappointed_frame` | **德意志鹰徽**（出现在每个席位上） |
| `GFX_circular_frame_fuhrer` | 元首圆形框 |
| `GFX_inner_circle_decor_bg` | 德国核心圈专属装饰 |

**教训：选“占位美术”时必须确认它是不是中性图。** sprite 名字听起来通用（“unappointed_frame”）不代表图像内容也通用。

#### 美术：v1 已交付并接入

成品在 `art/inner_circle/v1/`，11 张 DDS 已放到 `mod/heart_of_iron/gfx/interface/hof_ic/`，
由 `interface/hof_ic.gfx` 注册（间接层，见下）。尺寸与设计清单逐项吻合。

| 我们的 sprite | 尺寸 | 文件 |
| --- | --- | --- |
| `GFX_hof_ic_window_bg` | 631×583 | `hof_ic_window_bg.dds` |
| `GFX_hof_ic_spotlight` | 588×538 | `hof_ic_spotlight.dds` |
| `GFX_hof_ic_leader_frame` | 165×165 | `hof_ic_leader_frame.dds` |
| `GFX_hof_ic_leader_ribbon` | 160×36 | `hof_ic_leader_ribbon.dds` |
| `GFX_hof_ic_leader_title_box` | 115×22 | `hof_ic_leader_title_box.dds` |
| `GFX_hof_ic_seat_frame_empty` | 131×139 | `hof_ic_seat_frame_empty.dds` |
| `GFX_hof_ic_seat_frame_filled` | 131×139 | `hof_ic_seat_frame_filled.dds`（暂未使用，留给 S3 区分空/占） |
| `GFX_hof_ic_seat_name_box` | 146×26 | `hof_ic_seat_name_box.dds` |
| `GFX_hof_ic_seat_trait_box` | 144×43 | `hof_ic_seat_trait_box.dds` |
| `GFX_hof_ic_blank_portrait` | 156×210 | `hof_ic_blank_portrait.dds` |
| `GFX_hof_ic_candidate_slot` | 58×58 | `hof_ic_candidate_slot.dds` |

**版面尺寸定为 631×583，与底板美术严格 1:1**（不拉伸、不留空）。
名牌与特质框**叠在席位框内部**（席位容器仅 139 高）——这是照抄德国的做法；
若把名牌放到框下方，两排席位会把窗口撑到约 700 高，底板就装不下了。

出图需要的信息（参考图路径、每张图的苏联化要点）见 **`docs/16-art-spec-inner-circle.md`**。

其它：布局参数集中在 `.gui` 顶部用 `@` 变量定义；`verify-s2.ps1` 预检 **9 项全通过**
（含“空 spriteType 组件与 scripted_images 键一一对应”、“`.gui` 引用的 sprite 与本地化键是否都已注册”、
“`.gfx` 里的 `texturefile` 路径是否真实存在”）。

#### ⏳ 待确认 / 留给 S3 的事

1. **窗口位置 ✅ 已解决**：现为 `{ x = 4000 y = 2200 }`，实测窗口落在国策树**下方**，不再遮挡任何国策（用户截图确认）。
   微调方法写在 `sync-from-r56.ps1` 里 `$InjectMap` 的注释里。
2. **`GFX_hof_ic_seat_frame_filled` 尚未使用**。空格／已占两种框的贴图都在，但现在是写死用 `_empty`；
   S3 接上席位变量后，要把 frame 也纳入 `scripted_images` 才能按状态切换。
3. **底部候选栏目前是 7 个静态框**。要显示真实候选人物的小头像，同样需要把 `hof_ic_candidate_N`
   纳入 `scripted_images` 并接上候选名单逻辑。
4. **`GFX_hof_ic_spotlight` 已接入**（作为 `background_spotlight`）；聚光位置在 `.gui` 顶部的 `@` 变量里，可调。

#### 🚫 失败的尝试 → ✅ 最终可用的估算法

想“算出”窗口该放哪，先试了三条路，**均失败**：

1. 直接扫 focus 的 `x`/`y` → 树里 466 处用 `relative_position_id`，绝对坐标推不出
2. 递归解析相对坐标求包围盒 → 能解出来，但得到的范围与 inlay 位置无线性关系
3. 用德国/日本/暹罗/澳洲四国交叉标定倍率 → 得出 **68.4 / 46.2 / 138.9 / 133.3 px/格**，四者悬殊，说明包围盒本身不可靠

**后来找到可用方法**（详见 `docs/11` §5.1）：

- 用 `continuous_focus_position`（连续国策栏惯例在树正下方）与捷克窗口里原作者写的注释 `#y = ~2.5`
  交叉推出 **≈ 100~140 像素 / 国策格**
- 据此算出苏联树底大约在 y = 1500~2100，把窗口放到 2200 即可避开
- **实测有效**（用户截图确认窗口已在树下方）

⚠️ 精度有限（包围盒解析有噪声），**当估算用，最终仍需游戏内目视微调**。脚本留在 `docs/reference/calibrate-*.ps1`。

### 下一步

S3：给 7 个席位接上 `hof_ic_slot_1..7` 变量与真实角色立绘。

## 相关文档

- `docs/14-tree-attachment-matrix.md` — 挂载点矩阵与裁决机制
- `docs/15-r7-sov-default-tree.md` — 苏联默认树问题（未决）
- `docs/10-requirements-soviet-expansion.md` — 需求定稿
