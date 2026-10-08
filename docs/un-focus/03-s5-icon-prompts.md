# S5 · 经互会通用线 · **出图文档 v3**（2026-09-25）

> 上游：`01-s5-mutual-aid-common-lines.md`（结构 / 摆位 / **59** 个节点）· `02-s5-values.md`（数值）
> 右边那篇：`06-s5-emblem-icons.md`（**实物徽标的来源与授权实况**）
> 代码：`build/gen-hof-ma-common-lines.ps1` → `common/national_focus/hof_ma_joint.txt`
> 图标脚本：`build/gen-hof-ma-idea-icons.py`（裁方 / 抠实物）+ `build/gen-hof-ma-icons.ps1`（注册 sprite）

> 🚩 **版本沿革**
> **v1（2026-09-20）** = 全量 **76** 张的设想 · **v2（2026-09-25 早些）** = 按实测收窄到「还需画 54 张」
> · ✅ **v3（本文）** = 按用户「**已经有了的就别重画**」的口径**再收窄到 13 张**（政治线 10 + idea 3）。

---

## §0 用户口径（本文的立文依据）

### 0.1 第一道（2026-09-20）—— 定下「哪条线用哪张图」

> 「图标的话军事线先全部用华约图标占位，工人局全部用共产国际，经互会全部用经互会，
> 莫洛托夫用马列思想，**不知道这些图标意味着什么就搜国策名，我报的国策名**。」

⭐ **反查方法（照做，别猜 sprite 名）**：**拿用户报的【中文名】去原版本地化里搜国策键 →
用国策键在原版 `common/national_focus/*.txt` 里找 focus 块 → 读它的 `icon =`**。
⛔ `GFX_focus_SOV_the_comintern` 这个 sprite **不存在**（原版那个叫「共产国际」的国策用的是通用图）。

### 0.2 第二道（2026-09-25）—— **「已经有的就别重画」**（本文的**收窄依据**）

> 「**经互会和华约的不是已经有了吗，游戏内自带，莫洛托夫条约也不用重新画就用那个吧**」

⇒ 三条**从「占位」升为「定案」**，**不再各自出图**：

| 位置 | 张数 | 用哪张 |
| --- | --- | --- |
| **经济线**（经互会线） | **19** | `GFX_focus_SOV_the_comecon`（**游戏自带**） |
| **军事线**（华约线） | **16** | `GFX_focus_SOV_found_the_warsaw_pact`（**游戏自带**） |
| **头**（莫洛托夫计划） | **1** | `GFX_focus_SOV_the_path_of_marxism_leninism`（**沿用现状**） |

⭐ 并且**同一条口径顺推到 idea 层**（判据 J，本项目代选、可一键回退）：
**经济线 / 军事线的 idea 图标直接用那两张的【方形版】** ——
`GFX_idea_hof_ma_comecon` / `GFX_idea_hof_ma_warsawpact`（`gen-hof-ma-idea-icons.py` 早就
把游戏自带的那两张国策图裁方、缩到 60×60 做出来了）⇒ **零新增美术**。
落在 `gen-hof-ma-common-lines.ps1` 的 `$picReal`（4 个 eco/mil idea）。

---

## §1 定案：三条线各用一张游戏自带的图

> 📌 「线」= `hof_ma_joint.txt` 里三条支线；每张图的 **sprite 都来自原版**
> （`F:\Hearts of Iron IV\interface\goals.gfx`）⇒ **零缺图风险，不进兜底名单**。

| 线 | 张数 | sprite（**定案**） | 中文名（原版国策） |
| --- | --- | --- | --- |
| **头** | 1 | `GFX_focus_SOV_the_path_of_marxism_leninism` | 马克思-列宁主义道路 |
| **经济线** | 19 | `GFX_focus_SOV_the_comecon` | 经济互助委员会 |
| **军事线** | 16 | `GFX_focus_SOV_found_the_warsaw_pact` | 华沙条约组织已成立 |
| **政治线** | 10 | ⬜ **待画**（现暂借 `GFX_hof_ma_cominform`） | — |

---

## §2 现状实况（2026-09-25 实测 · 可复现）

复现：读 `common/national_focus/hof_ma_joint.txt` 的 59 个块各自的 `icon =` ·
`common/ideas/hof_ma_ideas.txt` 的 14 个 idea 各自的 `picture =` ·
`common/dynamic_modifiers/hof_ma_dynamic_modifiers.txt` 的 3 个 `icon =`。

| 类 | 总数 | ✅ 已定 / 已成图 | ⬜ **还要画** |
| --- | --- | --- | --- |
| **国策图标** | **59** | **49**（13 各自成图 + 19 经济线 + 16 军事线 + 1 头） | **10**（政治线） |
| **机构 idea** | **14** | **11**（10 真图 + 1 …见下注） | **3**（政治线） |
| **动态民族精神** | **3** | **3** ✅ | **0** |
| **合计** | **76** | **63** | **13** |

> 📌 idea 那 11 = `comecon` · `division_of_labour` · `integration_programme` · `joint_research_org` ·
> `cominform` · `wpc` · `oir` · `warsaw_treaty` · `joint_command` · `csce` · `nuclear_umbrella`。

### 2.1 ✅ 已经各自成图的 13 张国策图标（**不再列**，只做记录）

| 节点 | sprite | 中文名 |
| --- | --- | --- |
| `hof_ma_eco_ibec` | `GFX_hof_ma_ibec` | 国际经济合作银行 |
| `hof_ma_eco_iib` | `GFX_hof_ma_iib` | 国际投资银行 |
| `hof_ma_eco_druzhba` | `GFX_hof_ma_druzhba` | 友谊输油管道 |
| `hof_ma_eco_intermetall` | `GFX_hof_ma_intermetall` | Intermetall |
| `hof_ma_pol_cominform` | `GFX_hof_ma_cominform` | 共产党和工人党情报局 |
| `hof_ma_pol_wftu` | `GFX_hof_ma_wftu` | 世界工会联合会 |
| `hof_ma_pol_wfdy` | `GFX_hof_ma_wfdy` | 世界民主青年联盟 |
| `hof_ma_pol_ius` | `GFX_hof_ma_ius` | 国际学生联合会 |
| `hof_ma_pol_widf` | `GFX_hof_ma_widf` | 国际民主妇女联合会 |
| `hof_ma_pol_wpc` | `GFX_hof_ma_wpc` | 世界和平理事会 |
| `hof_ma_pol_ioj` | `GFX_hof_ma_ioj` | 国际新闻工作者协会 |
| `hof_ma_pol_oir` | `GFX_hof_ma_oirt` | 国际广播组织 |
| `hof_ma_mil_csce` | `GFX_hof_ma_osce` | 全欧安全会议 |

---

## §3 色彩纪律（**判据 G**）

> **色调只能来自「画面里那个东西本身的颜色」。**
> 自检：把画面里的物体逐个念一遍 —— **如果那个色不属于其中任何一个物体，它就超标了。**
> ⛔ 不允许给**整张图**上一层气氛色（拉狄克 `german_october` 的整幅冷蓝夜景、斯米尔加
> `productive_forces` 的整幅青绿就是反例，见 `docs/99` §39 与判据 G）。

政治线**允许出现的色源**（不是要求调色，是限制来源）：

| 线 | 允许的色源 | 举例 |
| --- | --- | --- |
| **政治线** | 报刊的铅灰 · 胶版的墨黑 · 会场椅的木色（**不做整幅红**）· 会徽自身的色 | 「和平」鸽子的白来自**那只鸽子** |

⛔ **全篇禁**：任何**人物肖像**（S5 是制度线，不是人物线）· 任何**战斗场面** ·
刑场 / 枪 / 铁窗（全项目禁区）· 整幅渐变底 / 光晕 / 爆炸。

---

## §4 ⬜ 还要画的 **10** 张国策图标（**全在政治线**）

> **规格**：**100×88 RGBA PNG** → 交付名 `art/focus/ma/GFX_hof_ma_<节点 id 去掉 hof_ma_ 前缀>_focus.png`。
> 列说明：**来源** 甲 = 抄实物（直接抠，**不重画**）· 乙 = GPT 画
> **画面主体** = 画面里必须出现的那件**物证**（判据 G 的色源，也是判据 F 的「东西叫什么」）
> **禁** = 这一张特别要避开的邻接（不写的就是只受 §3 与 §7 的约束）

| # | 节点 | 交付文件名 | 中文名 | 来源 | 画面主体（物证） | 提示词要点 | 禁 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `hof_ma_pol_cominform_organ` | `GFX_hof_ma_pol_cominform_organ_focus.png` | 《争取持久和平，争取人民民主！》 | **甲** · 报头 | 报纸头版（报头部分） | 直接抠报头 | 不写正文内容 |
| 2 | `hof_ma_pol_peace_and_war` | `GFX_hof_ma_pol_peace_and_war_focus.png` | 保卫和平和反对战争制造者的斗争 | 乙 | 一份**布达佩斯会议文件** + 一枚墨水瓶 | 文件抬头日期 1949-11 | ⛔ 不画武器 / 不画废墟 |
| 3 | `hof_ma_pol_working_class_unity` | `GFX_hof_ma_pol_working_class_unity_focus.png` | 工人阶级的统一 | 乙 | **两只握住同一件工具的手**（工人手套） | 手套是帆布的（色源） | 不画人 |
| 4 | `hof_ma_pol_wfsw` | `GFX_hof_ma_pol_wfsw_focus.png` | 世界科学工作者协会 | **甲** · WFSW 会徽 | 会徽本体 | 直接抠图 | — |
| 5 | `hof_ma_pol_friendship_societies` | `GFX_hof_ma_pol_friendship_societies_focus.png` | 友好协会体系（ССОД） | **甲** · ССОД 徽标 | 徽标本体 | 直接抠图 | — |
| 6 | `hof_ma_pol_international_department` | `GFX_hof_ma_pol_international_department_focus.png` | 苏共中央国际部 | 乙 | 一排**收发筐** + 一份**电报稿** | 电报纸条是白的（色源） | 不画大楼外观 |
| 7 | `hof_ma_pol_moscow_1957` | `GFX_hof_ma_pol_moscow_1957_focus.png` | 1957 年莫斯科会议 | 乙 | 一张**《和平宣言》文本** + 一排话筒 | 话筒是金属网罩的（色源） | ⛔ 不画主席台人像 |
| 8 | `hof_ma_pol_moscow_1960` | `GFX_hof_ma_pol_moscow_1960_focus.png` | 1960 年莫斯科会议 | 乙 | **81 面小旗**排成一片（旗面无图案） | ⭐ 用**数量**表现规模 | ⛔ 不画具体国旗 |
| 9 | `hof_ma_pol_moscow_1969` | `GFX_hof_ma_pol_moscow_1969_focus.png` | 1969 年莫斯科会议 | 乙 | 一份**会议名册**，页边写满旁注 | 名册的纸边泛黄（色源） | 不写具体人名 |
| 10 | `hof_ma_pol_first_secretaries` | `GFX_hof_ma_pol_first_secretaries_focus.png` | 第一书记与政府首脑会议 | 乙 | 一间**关着门的小会议室**：一张桌、几把椅、烟灰缸 | ⭐ **门是关着的** —— 这就是「章程里找不到的机关」 | 不画人 |

> 📌 **还需要「抄实物」的只剩 3 张**：**报头** · **WFSW 会徽** · **ССОД 徽标**
> （经互会会徽与华约徽章**已按 §0.2 取消** —— 那两张直接用游戏自带的）。

---

## §5 ⬜ 还要画的 **3** 张 idea 图标（方形 · 60×60）

> **规格**：**60×60 RGBA PNG**，交付名 `art/focus/ma/GFX_idea_hof_ma_<名>.png`。
> ⚠️ 民族精神图**不需要** `_shine`（原版 `interface/ideas.gfx` 就不带）。

| # | idea id | 当前 picture | 拟用 picture | 来源 | 建议画面 |
| --- | --- | --- | --- | --- | --- |
| 1 | `hof_ma_idea_cominform_press` | `generic_communist_army` | `hof_ma_pol_cominform_organ` | **甲** | 与国策 §4 #1 同源：**报头**（方形版） |
| 2 | `hof_ma_idea_friendship_societies` | `generic_communist_army` | `hof_ma_pol_friendship_societies` | **甲** | 与国策 §4 #5 同源：**ССОД 徽标**（方形版） |
| 3 | `hof_ma_idea_first_secretaries` | `generic_communist_army` | `hof_ma_pol_first_secretaries` | 乙 | 与国策 §4 #10 同主体：**关着的门** |

> ⭐ **这 3 张都是国策图同主体的方形版** ⇒ 国策那 10 张定了之后，这 3 张基本是**机械裁方**
> （`build/gen-hof-ma-idea-icons.py` 那条路径）。

---

## §6 命名与接入（交付方与接入方各做什么）

### 6.1 命名规范

| 类 | 交付文件名（放 `art/focus/ma/`） | 最终 sprite |
| --- | --- | --- |
| 国策图标 | `GFX_hof_ma_<节点 id 去掉 hof_ma_ 前缀>_focus.png`（100×88） | `GFX_hof_ma_<同名>` |
| idea 图标 | `GFX_idea_hof_ma_<同名>.png`（60×60） | `GFX_idea_hof_ma_<同名>` |

> ⚠️ **国策版的文件名必须带 `_focus` 后缀** —— `build/gen-hof-ma-icons.ps1` 靠它区分国策版与 idea 版。
> 📌 §2.1 那 13 张是**早期按主题命名**的（如 `hof_ma_eco_ibec` 的 sprite 叫 `GFX_hof_ma_ibec`）——
> **保持不动**，新图一律按节点 id 命名。

### 6.2 接入三步（**接入方** = 本项目）

| 步 | 做什么 |
| --- | --- |
| 1 | 把 PNG 放进 `art/focus/ma/`，跑 `python build/gen-hof-ma-idea-icons.py`（若要抠实物 / 裁方）+ `powershell -File build/gen-hof-ma-icons.ps1`（导出 DDS + 注册 sprite） |
| 2 | 在 **`build/gen-hof-ma-common-lines.ps1`** 的节点表里给该节点加 `Icon = 'GFX_hof_ma_<...>'`（⚠️ 国策）；或把 idea id 加进 **`$picReal`**（⚠️ idea 的 `picture` 取的是**不带 `GFX_idea_` 前缀**的名字） |
| 3 | 重跑链：`gen-hof-ma-common-lines` → `gen-hof-ma-icons` → `sync-from-r56` → `verify-s2` → `gen-reference-index` → `verify-docs` |

> 🚩 **`_shine` 不用另画**：全游戏 5900+ 个 `_shine` 都是同一张 `gfx/interface/goals/shine_overlay.dds`，
> 由 `gen-hof-ic-focus-icons.ps1` / `gen-hof-ma-icons.ps1` 自动注册（缺了图标会显示异常）。
>
> 🚩 **§1 那三张是【原版 sprite】，所以它们不在兜底机制的名单里** ——
> 这与 22 条个人线的缺图兜底不是一回事，别混。
> 换掉占位图**不会**产生 missing sprite（新图一定先注册再改 `icon =`）。

---

## §7 禁区汇总（与 22 条个人线、与原版）

| 类别 | 具体 |
| --- | --- |
| **全项目禁区** | 刑场 · 枪决 · 铁窗 · 1937 年 · 人物肖像（本线是制度线） |
| **已被 22 条个人线占掉的母题（本线不碰）** | 出版物特写 / 书籍封面（**加米涅夫**：列宁研究院、全集）· 生产力布局图 / 区域规划图（**斯米尔加**）· 花名册 / 盖章名录（**马林科夫**）· 车间车床特写（**施利亚普尼科夫**，明令废案）· 工会会旗 / 讲台（**托姆斯基**）· 军事学院 / 条令封面（**图哈切夫斯基**）· 红军野战条令（同上） |
| **本线特别禁令** | **任何战斗场面** · 核爆与蘑菇云 · 「一方对另一方下命令」（政治线不出现印章压人）· 具体国旗（用**数量与符号**表现多国）· 可读的外文长句 |
| **色彩** | 判据 G：色源必须是画面里那件物证；⛔ 不给整张图上气氛色 |

> ⚠️ 「**出版物特写 / 书籍封面**」是**加米涅夫**的母题，但**报头**（§4 #1）是**报纸**不是书，
> 且是情报局的机关报报头 —— 两者不同轴，**可以画**（这是唯一一处贴边的，已单独标明）。

---

## §8 批次建议（只剩两批）

| 批 | 内容 | 张数 | 说明 |
| --- | --- | --- | --- |
| **第 1 批** | **甲 · 抄实物 3 张**（报头 · WFSW 会徽 · ССОД 徽标） | 3 | ❗**不用画**，只要找图 + 去背 + 缩放；一次到位、效果最好 |
| **第 2 批** | 政治线剩下 7 张（乙） | 7 | 抽象 / 会场类，建议先各试 1 张定调 |
| **第 3 批** | idea 方形 3 张 | 3 | ⭐ 全是国策图同主体的方形版 ⇒ **第 1、2 批定了就基本是机械裁方** |

> 📌 **§3 的色彩纪律与 §7 的禁区对三批一律适用**，不因为「先做」而放宽。

---

## §9 ⚠️ 判据 J：留给用户裁决的两项（**不阻塞**，已按推荐值实装）

| # | 问题 | 本项目取的 | 备选 | 一键回退 |
| --- | --- | --- | --- | --- |
| 1 | **经济线 / 军事线的 idea 图标**要不要也「**直接用游戏自带那张的方形版**」？ | ✅ **要**（4 个 eco/mil idea 已映射到 `hof_ma_comecon` / `hof_ma_warsawpact`） | 让美术按节点各画一张方形版 | 从 `gen-hof-ma-common-lines.ps1` 的 `$picReal` 删掉那 4 行 |
| 2 | **政治线那 10 个节点**要不要也「**整条共用一张图**」（现成的 `GFX_hof_ma_cominform`）？ | ⛔ **不**，仍按本文件逐张交图 | 若也共用 ⇒ **待画降到 0 张**（但政治线 10 格会长得一样） | 把 10 个节点的 `icon` 指回 `GFX_hof_ma_cominform` 即可 |
