# 核心圈窗口 · 美术需求清单（交给 GPT 出图用）

> **现行 v3（2026-09-25）**：底板已改为 **760×740**，纵向席位框为 **131×170**；七席分两排，每席容器 150×215，顶部使用原版 `SOV_supreme_soviet` 头像，底部七个候选小框已撤除。现行素材与导出记录见 [v3](../art/inner_circle/v3/README.md)，布局唯一数据源为 `build/gen-hof-ic-gui.ps1`。本页以下 640×640 的尺寸推导保留作旧版设计过程，不再用于现行导出。

> 现行方向（2026-09-13 用户追加）：德国窗口仅作参考，允许根据苏联元素自由设计。
> 状态：第一版 11 项美术已生成并导出 PNG / DDS，已注册。交付入口见 `art/inner_circle/v1/README.md`，预览见 `art/inner_circle/v1/preview.html`。游戏内视觉与日志验收尚未完成。
> 下文保留原始需求记录；本版采用深钢、暗金麦穗与深红珐琅。空席框中央留透明孔，红星移至边框顶部；真实人物不新增立绘。

---

## 0. ⚠️ 本次改版：底板需重画为 **640 × 640**（只此一张）

> **2026-09-14 已完成重画与替换**：[640×640 新底板](../art/inner_circle/v2/hof_ic_window_bg.png) · [交付记录](../art/inner_circle/v2/README.md)。
> 新 DDS 已放入原注册路径；全画布 alpha=255、四边无透明留白，文件校验通过，其余 10 张未改。游戏内视觉验收待启动检查。

### 🔄 2026-09-15 追加要求：**其余 10 张也一并对齐 v2**

> **决定**：不只底板，**窗口的其余 10 件也重做成 v2 风格**，跟新底板配套。
>
> 现状核实（`reference/reports/inner-circle-art-versions.txt`）：
>
> | 部件 | 现状 |
> | --- | --- |
> | `hof_ic_window_bg`（窗口底板） | ✅ **已是 v2**（640×640，09-14） |
> | 其余 10 件（聚光 / 领袖圆框 / 绸带 / 头衔框 / 席位框空·满 / 席位名牌 / 特质框 / 候选格 / 空白立绘） | ⚠️ **仍是 v1**（09-13，按旧 631×583 设计） |
>
> **尺寸不用改**：§0 那张 640×640 的账就是按"全部素材 1:1、不缩放"算出来的，
> 现有 10 件的尺寸本来就放得进去（聚光 588×538、领袖圆框 165×165、席位框 131×139、
> 席位名牌 146×26、特质框 144×43、候选格 58×58、空白立绘 156×210、绸带 160×36、头衔框 115×22）。
> **要改的是风格**：配色、材质（石纹/鎏金/暗红）、边框纹样、光源方向要与 v2 底板一致。
>
> 🚩 **这 10 件全部是叠加件，背景必须透明（真 alpha）** —— 它们叠在 v2 底板上，
> 铺了实色底就会把底板盖掉。参考原版德国核心圈同名素材的透明边。
> 自检：导完逐张确认四角 `alpha = 0`（工具 `art/focus/check_alpha.py`，把路径指过去即可）。
>
> 📌 交付后**不用改任何脚本**：sprite 是间接层（`interface/hof_ic.gfx` 只写路径），
> 把新 DDS 覆盖到 `mod/heart_of_iron/gfx/interface/hof_ic/` 同名路径即可生效。

其余 10 张**尺寸不变**，继续沿用，不用重画。

| 项 | 值 |
| --- | --- |
| sprite 名 | `GFX_hof_ic_window_bg` |
| **新尺寸** | **640 × 640** |
| 旧尺寸 | 631 × 583（作废） |

### 唯一的硬要求：**画框必须铺满整张画布，四周不要留透明边**

**为什么**：旧底板名义上是 631×583，但逐行统计 alpha 后发现，它的实体画框只有
横向 `16..614`、纵向 `26..550`，**四周是透明的**。
于是贴着边缘摆的组件会"悬空"落在国策树背景上 —— 标题浮在框外、底部候选栏掉在框下。
（量法见 `docs/reference/tools/scan-window-art-bounds.ps1`）

### 640 这个尺寸是怎么算出来的（全部素材 1:1，不缩放）

| 段 | 高度 |
| --- | --- |
| 上留白 | 22 |
| 标题 | 34 |
| 间距 | 14 |
| 领袖块（圆框 165，头衔框下伸出 7） | 172 |
| 间距 | 12 |
| 第一排席位 131 × 139 | 139 |
| 间距 | 8 |
| 第二排席位 131 × 139 | 139 |
| 间距 | 12 |
| 底部候选栏 | 58 |
| 下留白 | 30 |
| **合计** | **640** |

横向：第一排 4 席（4×131 + 3×22 = 590）加上名牌左右各外伸 7 → 605 宽，
两侧各余 17 → 也是 **640**。

> 上一版试过把席位缩到 0.85 硬塞进 631×583，观感太挤，已废弃。
> 现在改为放大画布、所有素材保持 1:1。

### 风格要求：与原 11 张保持一致

构图、色调、材质沿用原 `inner_circle_decor_bg` 的苏联化版本（深钢 + 暗金麦穗 + 深红珐琅），
只是**画布变大、画框顶到四边**。四角装饰纹样与中央留白区位置可按新尺寸重新分布。

---


## 1. 怎么把这些参考图交给出图的那个 AI

> ⚠️ **更正**：本文档初版写着“AI 读不了本地文件”，**那句是错的**。
> 如果对方是**有本地文件访问能力的编码助手**（能跑命令、能读磁盘的那类），
> 直接给绝对路径就行，它自己会读。下面分两种情况。

### 情况 A：对方能访问本地文件（Codex 等）—— 直接贴路径

把下面整块原样发给它：

```text
# ===== 要仿的对象：德国核心圈窗口的素材（DDS）=====
F:\Hearts of Iron IV\gfx\interface\inner_circle\inner_circle_decor_bg.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\spotlight_overlay.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\circular_frame_fuhrer.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\fuhrer_name_ribbon.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\trait_box_fuhrer.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\ascended_advisors_unappointed_frame.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\ascended_advisors_frame.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\ascended_advisor_name_box.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\ascended_advisor_trait_box.dds
F:\Hearts of Iron IV\gfx\interface\inner_circle\blank_leader_portrait.dds

# ===== 参考它的“写法”：窗口怎么用这些图 =====
F:\Hearts of Iron IV\interface\GER_inner_circle_scripted_gui.gui
F:\Hearts of Iron IV\interface\inner_circle.gfx
F:\Hearts of Iron IV\common\focus_inlay_windows\ger_inner_circle_inlay_window.txt
```

**如果它只能读文本、不能把 DDS 当图像看**，让它先跑个转换（或你用 Paint.NET / GIMP 手动另存 PNG）：

```powershell
# 示例：借助 ImageMagick（需先装）
magick "F:\Hearts of Iron IV\gfx\interface\inner_circle\circular_frame_fuhrer.dds" "circular_frame_fuhrer.png"
```

### 情况 B：纯对话式模型（网页版）—— 必须转 PNG 或截图

| 办法 | 做法 | 评价 |
| --- | --- | --- |
| **直接截游戏画面（推荐）** | 开一局德国，走到能出核心圈窗口，截图发给它 | 最直观，一张图说明整体风格 |
| **转 PNG** | 用 Paint.NET / GIMP 打开 DDS，另存 PNG 再上传 | 精确到单个组件 |
| **只发路径文本** | — | **无效**，它读不到你的磁盘 |

**建议两张一起给**：一张整体截图定风格，再单独转 2~3 张关键框（席位框、领袖圆框）定细节。

---

## 2. 需要出的图（11 张）

尺寸沿用德国的原值，**保持尺寸一致可避免拉伸变形**。

| # | 我们的 sprite 名 | 尺寸 | 用途 | 德国参考图（`F:\Hearts of Iron IV\` 下） |
| --- | --- | --- | --- | --- |
| 1 | `GFX_hof_ic_window_bg` | **640 × 640（§0 改版）** | 窗口底板（全幅深色装饰，无透明边） | `gfx/interface/inner_circle/inner_circle_decor_bg.dds` |
| 2 | `GFX_hof_ic_spotlight` | 588 × 538 | 中央聚光叠加层 | `gfx/interface/inner_circle/spotlight_overlay.dds` |
| 3 | `GFX_hof_ic_leader_frame` | 165 × 165 | 领袖位圆形边框 | `gfx/interface/inner_circle/circular_frame_fuhrer.dds` |
| 4 | `GFX_hof_ic_leader_ribbon` | 160 × 36 | 领袖名牌绸带（名字底衬） | `gfx/interface/inner_circle/fuhrer_name_ribbon.dds` |
| 5 | `GFX_hof_ic_leader_title_box` | 115 × 22 | 领袖头衔框 | `gfx/interface/inner_circle/trait_box_fuhrer.dds` |
| 6 | `GFX_hof_ic_seat_frame_empty` | 131 × 139 | **空席位**框 | `gfx/interface/inner_circle/ascended_advisors_unappointed_frame.dds` |
| 7 | `GFX_hof_ic_seat_frame_filled` | 131 × 139 | **已占席位**框 | `gfx/interface/inner_circle/ascended_advisors_frame.dds` |
| 8 | `GFX_hof_ic_seat_name_box` | 146 × 26 | 席位名牌底衬 | `gfx/interface/inner_circle/ascended_advisor_name_box.dds` |
| 9 | `GFX_hof_ic_seat_trait_box` | 144 × 43 | 席位特质框 | `gfx/interface/inner_circle/ascended_advisor_trait_box.dds` |
| 10 | `GFX_hof_ic_blank_portrait` | 156 × 210 | 空席位的人像占位（剪影） | `gfx/interface/inner_circle/blank_leader_portrait.dds` |
| 11 | `GFX_hof_ic_candidate_slot` | 58 × 58 | 底部候选栏小头像框 | 见下注 |

> **第 11 张的参考**：德国底部候选栏用的是 `gfx/interface/inner_circle/` 下若干 `*_available_small.dds`（58×58）。这些是"人物小头像 + 框"的合成图，我们不需要按人物出图——**只需出一个 58×58 的空框**，人像由游戏渲染。

---

## 3. 每张图的苏联化设计要点

**核心原则：把德国符号替换为苏联符号，结构、比例、光影、金属质感全部保持一致**（这样才叫"仿制"而不是"另画一套"）。

| # | 德国是什么样的 | 苏联版应该怎么画 |
| --- | --- | --- |
| 1 | 深色羊皮纸/石质底板，四角有纳粹风格装饰纹样，边缘暗角 | 同样深色底板，四角换成**苏联风格装饰**：可参考五角星、麦穗、齿轮、绶带、锤子镰刀（但**别用国徽全貌**，用抽象纹样更耐看）。整体偏冷灰/深红 |
| 2 | 中央柔和的圆形光斑 | 直接沿用同构图即可，几乎无需改动，偏冷白光 |
| 3 | 金属圆框，顶部有**帝国鹰徽**浮雕 | 金属圆框保留，顶部换成**五角星**浮雕。材质偏钢青/暗金 |
| 4 | 深色缎带，两端有装饰收口 | 同结构，缎带改为**深红**（苏联红），收口可带金色细边 |
| 5 | 细长条，左侧有小图标位 | 同结构，颜色随缎带体系 |
| 6 | 金属方框，中央有**帝国鹰徽**浮水印（空席状态的灰暗版） | 金属方框保留，中央换**五角星**浮水印，**灰暗低对比**表示"空席" |
| 7 | 同 6 但更亮、有光泽，表示"已有人" | 同 6 但提亮、加高光，表示"已占" |
| 8 | 窄长条底衬，两端有装饰 | 同结构，与 4 同色系 |
| 9 | 较宽的框，用于显示特质名 | 同结构 |
| 10 | 深色人形剪影，不显示具体人物 | 同上，冷色调 |

**统一风格词（可直接放进 GPT 提示）**：
> Soviet socialist realism / WWII Soviet propaganda poster aesthetic, dark steel and deep crimson palette, gold accents, hammer & sickle and red star motifs (abstract, not the full state emblem), aged metal texture, low-key dramatic lighting, matches the visual weight of the German Inner Circle window but with Soviet iconography.

---

## 4. 输出要求

| 项 | 要求 |
| --- | --- |
| 格式 | **DDS**（首选）或 PNG/TGA/BMP（HOI4 都支持，但 DDS 最省事） |
| 位深 | 32 位含 Alpha 通道；底板按 §0 全幅覆盖、无透明边，其余组件继续保留各自透明区 |
| 尺寸 | **严格按上表**，尤其是两个席位框和领袖圆框 |
| 放置 | `mod/heart_of_iron/gfx/interface/hof_ic/`（文件名建议与 sprite 名一致的小写形式） |
| 注册 | 我会在 `mod/heart_of_iron/interface/hof_ic.gfx` 里注册，你只需把文件放进去 |

---

## 5. 过渡期怎么办

在美术到位之前，窗口会用一个**中性占位版**（游戏通用瓦片 `GFX_tiled_plain_bg` / `GFX_tiled_window_thin_border`）——不带任何国徽，但也不精致。

一旦美术到位，**只需改 `interface/hof_ic.gfx` 里的 `texturefile` 路径**，`.gui` 结构和布局完全不用动。这是我在设计时特意留的间接层。

---

## 6. 相关文档

- `docs/11-s0-german-inner-circle-dissection.md` §5 — 德国窗口的完整组件结构
- `docs/10-requirements-soviet-expansion.md` §6.5 — 命名规范
- `docs/12-icon-list.md` — 国策图标清单（同样是交付 GPT 出图用的，可一并处理）
