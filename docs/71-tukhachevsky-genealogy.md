# 71 · 米哈伊尔·图哈切夫斯基 关系图谱（第 0–5 步）

> **人物**：米哈伊尔·尼古拉耶维奇·图哈切夫斯基（Михаил Николаевич Тухачевский，1893-02-16 – 1937-06）
> **花名册**：`Idx 17` · `key = mikhail_tukhachevsky` · **`neutral` 营** · `Mod = army_org_factor = 0.03`
> **上游**：[`docs/23`](23-figure-focus-playbook.md)（SOP）· [`docs/10`](10-requirements-soviet-expansion.md) §2.4.2（互斥矩阵，唯一权威）
> **本件 = 第 0–5 步的产出**。第 6 步设计见 [`docs/72`](72-tukhachevsky-focus-tree-design.md)。
> **素材**：`tmp/tukhachevsky/txt/`（zh / en / ru 维基 + en-deep + **托洛茨基《斯大林评传》中译本**）

---

## 0. 来源标记

| 标记 | 含义 |
| --- | --- |
| `[W-zh]` | 中文维基（⚠️ 本条目是**繁体**页面：`縱深`/`機械化`/`傘兵`/`紅色拿破崙`） |
| `[W-en]` | 英文维基 |
| `[W-ru]` | 俄文维基 |
| `[W-en-deep]` | 英文维基 `Deep operation` |
| `[T]` | 托洛茨基《斯大林评传》**中译本**（`tmp/kalinin/txt/stalin-*.txt`）——【中文原文】 |
| `[原版]` `[R56]` | 游戏文件实测 |

---

## 1. 第 0 步 · 查现成内容（原版 / DLC / R56）

### 1.1 他有的现成件（✅ 不用自建）

| 件 | 位置 | 说明 |
| --- | --- | --- |
| **角色对象** | `common/characters/SOV.txt` **L538**（`SOV_mikhail_tukhachevsky`） | ✅ 原版已有 |
| **大幅立绘** | `interface/_leader_portraits.gfx` → `gfx/leaders/SOV/Portrait_Soviet_Mikhail_Tukhachevsky.dds` | ✅ **原版文件存在**（实测）；花名册 `Dds` 直接指向它 —— **本线不自绘** |
| **顾问位** | 同上 L546 | ⭐⭐ `slot = **theorist**`（理论家）/ `cost = 150` / `ledger = army` / `traits = { **mass_assault_expert** }` |
| **元帅位** | 同上 L570 | ⭐⭐ `field_marshal`：`brilliant_strategist` + `career_officer` + `trait_reckless` + `infantry_officer` + `offensive_doctrine`；`skill = 4` |
| 开局入册 | `history/countries/SOV - Soviet union.txt` **L96** | `recruit_character = SOV_mikhail_tukhachevsky` |
| **专属领袖特质** | —— | ⛔ **没有**（不像李维诺夫第 1 例 / 索柯里尼柯夫第 2 例） |

> ⭐⭐ **`mass_assault_expert` 的效果**（`00_traits.txt`，实测）：`mass_assault_mastery_gain_factor = 0.15`
> —— ⭐ **原版给他的顾问特质是「大兵团突击的【掌握度】增益」**。
> 📌 这条**直接指路**：他的招牌在「学说 / 掌握度」这一层，不在「装备数值」那一层。

### 1.2 🚩 **原版为他做过什么** —— 「原版专做过」检查**第 7 次执行**

| # | 件 | 位置 | 内容 |
| --- | --- | --- | --- |
| ① | ⭐⭐⭐ **国策 `SOV_approach_tukhachevsky`**（「接近图哈切夫斯基」） | 原版 `national_focus/soviet.txt` **L8868**；R56 **L10752** | 前置 `SOV_integrate_smirnovs_bloc`。效果：把他 + Kork + Feldman + 若干随机师长**转成 `trait_SOV_trotskyist`**、清掉 `trait_SOV_stalinist`、打 `SOV_aligned_left_opposition_flag`，并给左翼反对派加陆海空支持（`SOV_left_opposition_army_support = 0.07` 等） |
| ② | **元帅审判** | `common/decisions/SOV.txt` **L17045** | `SOV_great_purge_army_trial_of_the_generals_effect`（注释原文就写着 `#TRIAL OF THE GENERALS -> Tukhachevsky`） |
| ③ | **Paranoia「偏执照片」系统** | `SOV_scripted_effects.txt` L768 / `decisions/SOV.txt` L1750 / `history` L472 & L935 | `SOV_paranoia_photo_tukhachevsky` —— ⛔ **本 mod 不接**（与拉狄克同一套） |
| ④ | 大清洗目标 | `history/.../SOV` **L980** | `SOV_purge_character_effect = yes` |
| ⑤ | AI 策略 | `ai_strategy_plans/SOV_alternate_strategy_plan.txt`（4 处） | —— |
| ⑥ | 随机人名池 | `names/00_names.txt`（11 处） | —— |

> 👉 **结论**：**原版没有为他做过个人国策线** —— 只有**一条「把他拉进左翼反对派」的国策**。
> ⭐⭐ **而且方向相反**：原版做的不是「他做了什么」，是「**别人把他算进了哪个阵营**」。
> ⛔ **由此得出本线的第一处硬禁区：不做「他属于哪个派别」。**
> 📌 **这是「原版专做过」检查的第 7 次执行，也是【第 3 种性质】**（前两种：托姆斯基/里亚京「原版替他做过一件事」、
> 李维诺夫「原版把他做成了一条路线的名字」）——**这一种是「原版把他写成别人棋盘上的一枚子」**。

### 1.3 ⭐⭐⭐ 第 0 步最大发现：**「大纵深作战」在 HOI4 1.19 里已经是一条【子学说】**

| 项 | 实测 |
| --- | --- |
| 定义 | `common/doctrines/subdoctrines/land/operations_subdoctrines.txt` **L360**：`deep_battle = { ... }`（`enable_tactic = tactic_backhand_blow`、`category_tanks = { max_organisation = 4 }`、`rewards` 有 `bounding_overwatch` 等分档） |
| **苏联开局就有** | `history/countries/SOV - Soviet union.txt` **L1242-1246**：`set_sub_doctrine = deep_battle` + `add_mastery = { amount = 100 sub_doctrine = deep_battle }` |
| R56 | `national_focus/germany.txt` **L4018** `GER_counter_deep_battle`（「反纵深作战」）；`r56_ger_shared.txt` L434 `rw56_enable_deep_battle_tt` |
| **原版有没有国策给过它掌握度** | ⛔ **没有任何国策 / 事件给过 `deep_battle` 掌握度** —— **只有 history 里的开局 100 点** |

> ⛔ **推论一**：**本线【不能】把「采用大纵深」做成一串国策** —— 游戏里 1936 年开局就已经有了。
> ✅ **推论二**：**但可以给它加掌握度** —— `add_mastery = { amount = X sub_doctrine = deep_battle }` 这个口子**原版空着**。
> ✅ **合法性已实测**：`add_mastery` 是**原版广泛使用的国策奖励效果**
> （`national_focus/germany.txt` 28 处 · `china_communist_sea.txt` 42 处 · `australia_taog.txt` 11 处 …
> 另有 `decisions/`、`events/`、`factions/goals/` 在用）。
> ⚠️ **但本项目从未用过** → 见 `docs/72` §8 第 ⑦ 项，**列为待裁决项**。

### 1.4 🚩 要绕开的机制清单（**十五套** —— 比索柯里尼柯夫多一套）

| # | 机制 | 位置 | 本线处置 |
| --- | --- | --- | --- |
| 1 | `SOV_approach_tukhachevsky`（把他拉进左翼反对派） | 原版 L8868 / R56 L10752 | ⛔ **不做「他属于哪个派别」** |
| 2 | `SOV_left_opposition_army_support` 等变量 + `SOV_aligned_left_opposition_flag` | `scripted_effects/SOV_scripted_effects.txt` | ⛔ 不碰派系对齐子系统 |
| 3 | `SOV_great_purge_army_trial_of_the_generals_effect`（元帅审判） | `decisions/SOV.txt` L17045 | ⛔ **绝不出现审判 / 枪决 / 1937** |
| 4 | `SOV_paranoia_photo_tukhachevsky` + Paranoia 脚本 GUI | `scripted_guis/SOV_paranoia_system_scripted_gui.txt` | ⛔ 本 mod 不接 |
| 5 | `SOV_purge_character_effect` | `history` L980 | ⛔ 不做清洗 |
| 6 | **`deep_battle` 子学说** | `doctrines/subdoctrines/land/operations_subdoctrines.txt` L360 | ⛔ 不做「采用大纵深」；✅ **只考虑给它加掌握度**（§1.3） |
| 7 | `SOV_soviet_civil_war_*` 全局标记（那条国策的 `available`/`bypass`） | `national_focus/soviet.txt` | ⛔ 不碰内战标记 |
| 8 | `SOV_integrate_smirnovs_bloc`（它的前置，三人一个动作） | 同上 | ⛔ 不碰集团释放 |
| 9 | **托洛茨基的 5 块军事国策**（`build_the_red_army` / `military_specialists` / `against_partisan_warfare` / `labour_armies` / `the_builder_of_the_state`） | 我们自己的 mod | ⛔ 见 §2.4 第 1 条 |
| 10 | **斯米尔诺夫的 `the_fifth_army`** | 我们自己的 mod | ⛔⛔ 见 §2.4 第 2 条（**本轮新发现的硬撞车**） |
| 11 | `common/ai_strategy_plans/SOV_alternate_strategy_plan.txt` | 原版（4 处提到他） | ⛔ 不碰 AI 策略 |
| 12 | `names/00_names.txt` 随机人名池（11 处） | 原版 | ⛔ 不碰 |
| 13 | `interface/ideas.gfx` / `ideas_characters.gfx` / `_leader_portraits.gfx` 里他的图标 | 原版 | ⚠️ 我们**复用**立绘 sprite，不新增 |
| 14 | DLC 版 `focus_SOV_approach_tukahchevsky.dds`（注意原版拼写少一个 `h`） | `gfx/interface/goals/` | ⛔ 本线不用这个图标 |
| 15 | **R56 的 `GER_counter_deep_battle`** | R56 `national_focus/germany.txt` L4018 | ⛔ 不碰德国侧 |

---

## 2. 第 1b 步 · 史实结构化（**非理论家走法**）

> ⚠️ **他算不算「理论家」？** —— 按本项目 SOP 的定义（**中文马克思主义文库有没有他的篇目页**）：
> ⛔ **没有** —— MIA 中文站索引查过（`tmp/tukhachevsky/txt/mia-cn-index.html`），
> ⛔ **英文 MIA 的苏联栏目**也没有。
> ✅ **但他是货真价实的军事理论家**（`[W-en]`：`a military officer and theoretician`）→
> ⭐ **所以走 `docs/23` 第 1b 步（非理论家），但文案尽量用他的东西 / 关于他的原文。**

### 2.1 根 → 主干

⭐⭐⭐ **根 =「一个手里只有别人的一本野战手册的军团长」（1919）**
> `[W-zh]`：1919 年东方战线，方面军司令**萨莫伊洛（Самойло）**在**十天之内五次改变第 5 军团的任务**，
> 且每次新任务都与上一次完全相反 → 图哈切夫斯基**不得不写信抱怨**，
> ⭐⭐ 并在信里**谴责这位方面军司令「应该回去阅读野战手册」**。

⭐⭐⭐⭐ **主干 =「把分散的构想，凭职权整合成全军必须照着执行的条令」**
> ⭐ **一句话**：**别人想出来的东西，是他让它变成条令的。**

| 级 | 节点 | 从上一级推 |
| --- | --- | --- |
| 根 | 他手里**只有别人的**一本野战手册（1919） | —— |
| ① | **军事学院**（1921-08） | **要写出该读的东西，先得有个教人的地方** |
| ② | **正规军**（1930-01） | **教出来的人，得有一支照新办法编成的军队去装** |
| ③ | **空降兵与战车**（1931–32） | **光有人还不够，条令要的那种兵器得真的造出来** |
| ④ | **纵深战斗指示**（1933 → 1935） | **有了人、有了兵器，就可以先在部队里试一遍** |
| ⑤ | **四个梯次**（1936） | **试出来的打法，得有一条说清楚的结构** |
| E1 | **工农红军野战条令**（1936） | **这条结构从此成为全军照着组织与训练的东西** |

⭐⭐ **首尾同轴**：**根是「他手里只有别人的一本野战手册」；E1 是「那本野战手册由他署名，全军照着它组织与训练」**
—— **同一本东西，换了署名的人。**

### 2.2 🚩 为什么主干**不**是「他发明了纵深作战」

| 反例 | 为什么不用 |
| --- | --- |
| ❌「他发明了纵深作战」 | **两处来源都不支持**：`[W-zh]` 明说理论源头是**斯维钦 1926 年的《战略》**；`[W-en]` 更谨慎 —— 「**his exact role is unclear and disputed because of shortage of firsthand sources, and his published works containing only limited amounts of theory on the subject**」（他的确切作用**有争议**，一手材料稀缺，**他自己发表的著作里关于这个题的理论含量有限**） |
| ❌「他把红军机械化了」 | ⚠️ **判据 B 不过**：换任何一个 1930 年代的军事改革家来，这条轴都成立 |
| ❌「红色拿破仑」当主干 | 那是**别人给的绰号**，不是他的动作 |

> ⭐⭐⭐ **主干特意选在两处来源【都同意】的那一点上**：
> `[W-zh]` 明说 —— 「連續戰役與縱深打擊的構想雖早已存在，**圖哈切夫斯基的關鍵貢獻卻在於憑藉其在軍中的職權，
> 將這些分散的構想加以整合、寫入正式條令，使紅軍得以據此進行組織與訓練**」；
> `[W-en]` 用 `codified into the army in 1936 in the Provisional Field Regulations of 1936` 承认同一件事。
> → 📌 **两说并存时，主干落在交集上，分歧写进文档**（`docs/72` §5.1）。

### 2.3 ⚠️ 一处必须如实标注的分歧（**死亡日期**）

| 来源 | 日期 |
| --- | --- |
| `[W-zh]` | 1937 年 **6 月 11 日** |
| `[W-en]` | 1937 年 **6 月 12 日** |
| `[W-ru]` | 待核（本次未逐字核到） |

→ 📌 **本线不做「他死」这个题**，所以**这个分歧不进游戏**，只在此留档（`docs/72` §8 第 ⑧ 项）。

### 2.4 🚩🚩 十二处邻接（**他排掉 1 人 → 与 20 人可同席**，所以一处都不能省）

> 📌 **生成器 §0b 实测：他排掉【1 人】** —— **伏罗希洛夫**（R1 历史交恶）。
> ⚠️ **反过来说：其余 20 人都能同席** —— **比加里宁 / 李维诺夫 / 索柯里尼柯夫（都排掉 0 人）好一点，但仍是难避重的一档**。

| # | 邻接对象 | 它的母题 / 它的题 | 本线的界线 |
| --- | --- | --- | --- |
| 1 | 🚩🚩 **托洛茨基（Idx 1）** | 5 块军事：`build_the_red_army` 缔造红军 / `military_specialists` 军事专家 / `against_partisan_warfare` 反游击 / `labour_armies` 劳动军 | ⛔ **绝不碰**：缔造红军 · 军事专家制度 · 反游击 · 劳动军<br>⭐ **界线由史实钉死**（`[W-zh]`）：他 **1930-01 的方案【反对托洛茨基主张保留革命因素的民兵制】，要求建立一支正规军** ——<br>**托洛茨基建了红军；他把它改成正规军。** |
| 2 | 🚩🚩 **斯米尔诺夫（Idx 6）** | `the_fifth_army` + `the_volga_bridgehead` | ⛔⛔ **本轮新发现的硬撞车**：**图哈切夫斯基 1919-04 起正是第 5 军团司令**，而**斯米尔诺夫 1919 年是第 5 军团革命军事委员会委员** —— **两人同在第 5 军团！**<br>→ ⛔ **本线一个节点都不碰第 5 军团**（根那件事发生在第 5 军团，**但只写「他写信给方面军司令」这件事本身，不写军团番号**） |
| 3 | 🚩 **加米涅夫（Idx 5）** | **把列宁的文本与遗产变成党的公共财产**（列宁研究院 / 全集 / 文集） | ⚠️⚠️ **两处来源都有的隐喻重叠**（「把文字变成正式的东西」）<br>→ ⛔ **本线不画书、不画出版物、不画图书馆**；⭐ **界线**：**加米涅夫做的是「保存与传播」（印出来给人读），他做的是「约束与执行」（全军的令）** |
| 4 | **施利亚普尼科夫（Idx 13）** | 「制度的物证」—— 账本 / 名单 / 计划表 / 抽屉 | ⛔ 不画账本、不画名单、不画格子表、不画抽屉 |
| 5 | **加里宁（Idx 14）** | 「一张被翻开的纸 + 一道被走过的门」 | ⛔ 不画门、不画信；⚠️ **本线也有「翻开的纸」** → 界线：**加里宁是士兵在学识字，他是军官在看条令** |
| 6 | **李维诺夫（Idx 15）** | 「一条线」（墙头 / 桌中线 / **刻度线** / 车票） | ⛔ 不画尺、不画刻度、不画墙、不画车票 |
| 7 | **索柯里尼柯夫（Idx 16）** | 「一张纸与一枚币」 | ⛔ 不画钱、不画币、不画铸锭 |
| 8 | **斯米尔加（Idx 10）** | 冰海 / 煤 / **网格墙** / **计算尺** / 裂缝 | ⛔ 不画计算尺、不画网格墙、不画地图与分区表 |
| 9 | **拉狄克（Idx 9）** | 地图 / 地下会场 / 册子 / 空街 / **教室** / 笔尖 | ⛔ 不画教室、不画笔尖、不画地图；⚠️ **本线 A1 是「学院」** → 界线：**拉狄克的是「一间亮着灯的教室」（他教中国学员）；本线的是「一所军事学院的编制与课程」（制度的产物）** |
| 10 | **托姆斯基（Idx 11）** | 讲台 / 会旗 / 纵队 / 雪路 | ⛔ 不画讲台、不画会旗、不画队列行军 |
| 11 | **普列奥布拉任斯基（Idx 8）** | 天平 + 剪刀 | ⛔ 不画天平、不画剪刀 |
| 12 | **季诺维也夫（Idx 4）** | 「同一母题的两种形态」（成对） | ⛔ 本线不做成对手法 |
| 13 | 🚩🚩 **伏罗希洛夫（未实装，但矩阵里有）** | —— | ⭐ **本线与他互斥（R1 历史交恶）** —— 生成器实测。<br>⭐ **界线有史实**（`[W-zh]`）：图哈切夫斯基要求**增加战车和飞机的产量、削减骑兵单位**，**这使他与伏罗希洛夫和布琼尼产生了矛盾** → **本线【可以有】「削减骑兵」这件事**（那是他的方案的内容，不是攻击某人） |

---

## 3. 第 2–4 步 · 有效性判定 / 奠基性判定 / 聚类成支线

### 3.1 有效性判定

| 级 | 事件 | 年份 | 来源 | 为什么有效 |
| --- | --- | --- | --- | --- |
| 根 | 写信谴责方面军司令「应回去阅读野战手册」 | 1919 | `[W-zh]` | ⭐ **它是主干的种子**：他第一次拿一本手册去规劝别人 |
| A1 | 任工农红军军事学院院长 | 1921-08-27 | `[W-zh]`/`[W-en]` | ✅ 产物 = 一所学院的教学大纲 |
| A2 | 部队改革建议（削减骑兵、建正规军） | 1930-01 | `[W-zh]` | ✅ 产物 = 一份具体的改革方案；⭐ **与托洛茨基的界线就在这里** |
| A3 | 组建世界上第一支伞兵部队 / 战车三分类 | 1931–1932 | `[W-zh]` | ✅ 产物 = **两样全新的编制** |
| A4 | 《纵深战斗组织临时指示》→《纵深战斗指示》 | 1933 / 1935 | `[W-zh]`/`[W-en]` | ✅ 产物 = 一份先在部队里试的指示 |
| A5 | 条令里的「四个梯次」 | 1936 | `[W-zh]` | ✅ 产物 = 一条作战的层级结构 |
| E1 | 《工农红军野战条令》（PU-36） | **1936** | `[W-zh]`/`[W-en]` | ✅ 产物 = **全军照它组织与训练** |

### 3.2 奠基性判定（哪些是奠基性的、哪些是延伸的）

- **奠基性**：根 · A1 · A2 · E1
- **延伸性**：A3 · A4 · A5

### 3.3 聚类 → **单簇**

五个尺度全部落在同一根轴上（**构想 → 条令**），**没有第二条可以从根推出来的支线** →
**单线 5 节点 + 1 单结局**（与加里宁 / 李维诺夫 / 索柯里尼柯夫同形）。

---

## 4. 第 5 步 · 跨簇钩子

**0 条。**（单簇线 —— 与最近四条同）

---

## 5. 素材状况与文案可能来源

| 类 | 情况 |
| --- | --- |
| ⛔ **中文马克思主义文库** | **没有他的篇目页**（MIA 中文站索引 / 英文站苏联栏目都查过） |
| ✅ **中文原文（他人记述）** | ⭐ **托洛茨基《斯大林评传》中译本**（`tmp/kalinin/txt/stalin-13.txt`，**16 处**提到他）—— 主要是**华沙战役 1920** 与三人团时期 |
| ✅ **中文原文（他自己 / 条令）** | ⭐ **`[W-zh]` 转引的条令宗旨**：「**使其在其部署的全纵深遭到歼灭、包围并歼灭**」—— ⚠️ 是**转引**，标注时要写清 |
| ✅ **中文原文（他的方案）** | ⭐ `[W-zh]` 记他 1930 年方案的规模：「**正面宽达 450 公里、并深入敌阵 100 至 200 公里的总体战**」 |
| 📚 **俄文维基** | 79 426 字符（最详；本次只做了抽样核对） |
| 📚 **英文维基 `Deep operation`** | 61 320 字符 —— ⭐ 纵深作战理论的独立条目，**第 6 步设计时再细读** |

### 5.1 🚩 文案档次的**预判**（比索柯里尼柯夫那条差）

- ⛔ **没有他的任何一篇中文译文** → **拿不到「本人原文」**
- ✅ 可用的是：**① 托洛茨基中译本里关于他的记述**（他人记述的原文）· **② 条令宗旨的中文表述**（转引）· **③ 他方案内容的中文表述**（转引）
- 📌 **所以本线大约 2–3 / 6 是中文原文**，**其余为中译稿** —— 与加里宁 / 李维诺夫同档，**不如索柯里尼柯夫**（他那条 4/6）。

---

## 6. 与已实装 16 条线的**性质对照**（一句话总结）

| 线 | 一句话 |
| --- | --- |
| 托洛茨基 | 他把红军**建起来** |
| **图哈切夫斯基（本线）** | ⭐ **他把它【写成条令】** |

> 🚩 **下一位**（做完他之后）：**Idx 18 · 尼古拉·沃兹涅先斯基**（`neutral` 营，`Mod = industrial_capacity_factory = 0.03`）。
> ⚠️ **做他时要注意**：**「计划 / 工业」这一层的题被斯米尔加（Idx 10 · 计委 / 生产力布局）与李可夫（Idx 3 · ВСНХ）占过**，
> 且 **原版有完整的苏联五年计划国策线** → ⚠️ **必须逐条比**。

---

## 7. 相关文件

| 文件 | 内容 |
| --- | --- |
| [`docs/72-tukhachevsky-focus-tree-design.md`](72-tukhachevsky-focus-tree-design.md) | **第 6 步设计**（✅ **已实装** 2026-09-20，`docs/18` §27） |
| [`docs/73-tukhachevsky-focus-icon-prompts.md`](73-tukhachevsky-focus-icon-prompts.md) | **第 7 步出图说明**（6 张，⬜ 待美术交付，现走缺图兜底） |
| [`docs/23-figure-focus-playbook.md`](23-figure-focus-playbook.md) | **SOP 手册**（⭐ **判据 A–I**） |
| [`docs/10`](10-requirements-soviet-expansion.md) §2.4.2 | **互斥矩阵唯一权威出处**（⚠️ **他排掉 1 人：伏罗希洛夫**） |
| [`docs/28`](28-entry-focus-icon-prompts.md) | 入口图标（⚠️ §103 附近有他的条目，第 7 步再核） |
| [`docs/62`](62-kalinin-genealogy.md) | ⚠️ 加米涅夫那条线（**「把文字变成制度」的隐喻邻接**） |
| [`docs/68`](68-sokolnikov-genealogy.md) | 上一位（索柯里尼柯夫） |

> ✅ **第 6 步见 [`docs/72`](72-tukhachevsky-focus-tree-design.md)**（用户 2026-09-20 口径：「**就这样实装吧**」）
> ✅ **第 7 步见 [`docs/73`](73-tukhachevsky-focus-icon-prompts.md)** → ⬜ **等美术交付 6 张 DDS**。
> 🚩 **下一位**：**Idx 18 · 尼古拉·沃兹涅先斯基**（`neutral` 营，`Mod = industrial_capacity_factory = 0.03`）。
