# 图标清单（供 AI 生成美术用）

> 用途：把本 mod 需要的全部图标一次性列清，交给 ChatGPT 之类生成后按名归档即可。
> 状态：**国策图标规格已实测**；窗口装饰图与其它类型尺寸待补（见第 5 节）。

---

## 1. 规格基准（实测）

| 类型 | 尺寸 | 依据 |
| --- | --- | --- |
| **国策图标** | **100 × 88 px** | 实测原版 `gfx/interface/goals/`（2954 个文件，全部 100×88）；mod 内该目录仅 3 个文件 |

**格式**：DDS / TGA / PNG / BMP 均可（只要 sprite 信息正确）。
推荐流程：**让 AI 出 PNG → 后期转 DDS（ARGB8，不带 mipmap）**，因为 AI 直接出 DDS 不现实。
⚠️ 旗帜是唯一例外（必须 32 位 TGA、无 RLE、原点左下），但本清单不涉及旗帜。

**风格要求**：与原版国策图标一致——深色底、居中主体、无文字、无边框（边框由游戏绘制）。

### 1.1 🚩 查参考图标时的致命陷阱：**DLC 覆盖**

贴图按**相对路径**在「原版 → DLC → 用户目录 → mods」中后者覆盖前者，
**同一个 `gfx/interface/goals/xxx.dds` 可能存在多份，只有最后加载的那份在游戏里可见**。

实测踩坑：德国核心圈入口图标 `focus_GER_ascension_of_*.dds`

| 位置 | 内容 | 是否可见 |
| --- | --- | --- |
| `F:\Hearts of Iron IV\gfx\interface\goals\` | **旧版纹章图**（工业圆章／铁锹盾／鹰徽士兵列） | ❌ **被覆盖，游戏里看不到** |
| `F:\Hearts of Iron IV\dlc\dlc001_german_historical_portraits\gfx\interface\goals\` | **黑白人物半身像 + 彩色装饰框 + 下方专属小徽章** | ✅ **实际生效** |

→ **查任何参考图标，都必须按文件名在全部 root（含 `dlc\`）里找一遍，别只看原版基础目录。**
脚本：`docs/reference/tools/dds2png-real.py`（含覆盖判定）、`docs/reference/tools/scan-all-workshop-ger-icons.ps1`。

> 另：`spriteType` 的定义（`interface/*.gfx`）也可能被后加载的 root 重新定义，
> 反查 sprite → `texturefile` 时同样要取**最后一个**命中。

---

## 2. 命名规范

遵循 `10-requirements-soviet-expansion.md` §6.5：

| 类别 | 模式 | 示例 |
| --- | --- | --- |
| **国策图标（统一新规）** | **`GFX_` + 焦点 id**（1:1，免映射表） | `hof_ic_seat_lev_trotsky` → `GFX_hof_ic_seat_lev_trotsky` |
| 核心圈席位框架 | `GFX_hof_ic_slot_frame_<1..7>` | `GFX_hof_ic_slot_frame_3` |
| 核心圈窗口装饰 | `GFX_hof_ic_<用途>` | `GFX_hof_ic_decor_bg` |
| 联合国策（中苏） | `GFX_hof_jf_sino_soviet_<nn>` | — |
| 联合国策（互助会通用） | `GFX_hof_jf_mutual_aid_<线>_<nn>` | `GFX_hof_jf_mutual_aid_eco_01` |
| 联合国策（互助会国别） | `GFX_hof_jf_ma_<TAG>_<nn>` | `GFX_hof_jf_ma_MON_01` |

---

## 3. 核心圈图标（需求 A）

### 3.1 国策图标（100 × 88）

每个角色需要 **1 个入口国策图标 + N 个专属国策图标**（N 按其理论储备，托洛茨基最多）。

> ⚠️ **2026 更正**：本表原为早期 18 人候选名单（含托姆斯基、索柯里尼柯夫、里亚京、斯米尔加、拉狄克、
> 普列奥布拉任斯基、施利亚普尼科夫、图哈切夫斯基、莫洛托夫、卡加诺维奇、加里宁），**已与最终花名册不符**。
> 最终核心圈为下面 **7 人**（来源：`build/gen-hof-ic-s3.ps1` 的花名册，也是唯一真实来源）。

| # | 角色 | 角色键 | 入口 | 专属国策（预估） | 小计 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 列夫·托洛茨基 | `lev_trotsky` | 1 | 17 + 2 汇合 | 20 | ✅ 已设计（`docs/22`）、提示词见 `docs/24` |
| 2 | 尼古拉·布哈林 | `nikolay_bukharin` | 1 | 3~5 | 4~6 | ⬜ 待做 |
| 3 | 阿列克谢·李可夫 | `aleksey_rykov` | 1 | 3~4 | 4~5 | ⬜ 待做 |
| 4 | 格里戈里·季诺维也夫 | `grigory_zinovyev` | 1 | 3~4 | 4~5 | ⬜ 待做 |
| 5 | 列夫·加米涅夫 | `lev_kamenev` | 1 | 3 | 4 | ⬜ 待做 |
| 6 | 伊万·斯米尔诺夫 | `ivan_smirnov` | 1 | 3 | 4 | ⬜ 待做（R56 已有 `SOV_integrate_smirnovs_bloc`，注意避重） |
| 7 | 列昂尼德·谢列布里亚科夫 | `leonid_serebryakov` | 1 | 3 | 4 | ⬜ 待做 |

**小计：约 45 个国策图标**（托洛茨基 20 + 其余 6 人各 4~5）。
其中**近期交付 24 张**（7 入口 + 17 托洛茨基专属），见 `docs/24-focus-icon-prompts.md`。

### 3.2 窗口装饰图（尺寸待实测，见第 5 节）

| 图标名 | 用途 |
| --- | --- |
| `GFX_hof_ic_decor_bg` | 窗口主背景 |
| `GFX_hof_ic_spotlight` | 聚光叠加 |
| `GFX_hof_ic_leader_frame` | 领袖位圆框（对应德国 `GFX_circular_frame_fuhrer`） |
| `GFX_hof_ic_leader_ribbon` | 领袖名牌缎带 |
| `GFX_hof_ic_slot_frame_1..7` | 7 个席位的框架图 |
| `GFX_hof_ic_slot_empty` | 空席占位图（可选，德国用 `GFX_blank_leader_portrait` 兜底） |

> 角色头像**全部复用 R56 现有资源**，本清单不含立绘。谢列布里亚科夫已有立绘文件，只需补角色定义。

---

## 4. 联合国策图标（需求 B / C）

| 线路 | 图标数量（预估） | 命名前缀 |
| --- | --- | --- |
| 中苏联合 | 6~10（待查史实定） | `GFX_hof_jf_sino_soviet_` |
| 互助会 · 经济通用线 | 6~10 | `GFX_hof_jf_mutual_aid_eco_` |
| 互助会 · 政治通用线 | 6~10 | `GFX_hof_jf_mutual_aid_pol_` |
| 互助会 · 华约军事线 | 6~10 | `GFX_hof_jf_mutual_aid_mil_` |
| 互助会 · 国别分支 × 15 | 每国按历史事件量，暂估 3~6 | `GFX_hof_jf_ma_<TAG>_` |

15 国分支对应的 TAG：`MON`、`FIN`、`SWE`、`NOR`、`DEN`、`ICE`、`AFG`、`SAU`、`PHI`、`CUB`、`ARG`、`ETH`、`FRA`、`POL`、`HUN`。

**小计预估：约 100~150 个图标**

---

## 5. ⏳ 待实测补充（下一步）

- [ ] 德国窗口各 sprite 的像素尺寸：`GFX_inner_circle_decor_bg`、`GFX_spotlight_overlay`、`GFX_circular_frame_fuhrer`、`GFX_fuhrer_name_ribbon`、`GFX_inner_circle_leader_*`
- [ ] 民族精神 / idea 图标尺寸（国家精神、动态民族精神都要用）
- [ ] 决议图标尺寸（若互助会要用决议承载部分内容）
- [ ] 确认席位框架图的**宽高比**（德国是圆形框，苏联版是否沿用圆形）

补齐后本清单即为可交付给 AI 的完整规格。

---

## 6. 交付建议

给 AI 生成时，**分批交付**比一次性给 200 个更实际：

1. 先做 **3~5 个样图**（托洛茨基入口 + 1 个专属 + 1 个席位框）确认风格；
2. 风格定稿后再批量生成；
3. 每批按 `命名前缀_序号` 归档，我这边负责转 DDS 与注册进 `hof_icons.gfx`。
