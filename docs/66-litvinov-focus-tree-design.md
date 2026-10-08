# 66 · 马克西姆·李维诺夫 个人线设计（第 6 步）（✅ **已实装**）

> **人物**：马克西姆·李维诺夫（`Idx 15`，`neutral` 营）
> **上游**：[`docs/65`](65-litvinov-genealogy.md)（谱系，✅ 第 0–5 步已完成）
> **本文 = 第 6 步设计提案** —— 🚩🚩 **先给用户过目，拿到口径再改生成器**（`docs/23` 流程铁律）。
> ✅ **2026-09-19 已实装**。**用户口径：「乙，A5 可以，实装吧」** ——
> **E1 取【乙】「外交人民委员会顾问」**；**A5 的外交联动照 §3.4 走**；**其余七项裁决全取推荐值**。
> 实测落盘：**127 国策块**（22 + **104** + 1）· **sprite 126 = 108 交付 + 18 兜底**（本线 6 张全兜底）·
> **15 人**驱动器 · 事件 **35** 个（本线 = `heartofiron.1250` / `.1251`）· 两套自检 **0 FAIL**。
> 📌 **成本对照**：本轮**零返工**（两次口径共 9 项裁决 + 1 项改名全部在提案阶段完成）——

---

## 1. 主干与推导

### 1.1 根 → 主干（详见 `docs/65` §2.1 / §2.2）

⭐⭐⭐ **根 =「从基辅监狱翻墙出去的那个人」（1902）**
⭐⭐⭐ **主干 =「让一个不被承认的国家，被一个它被排除在外的体系接纳」**

> ⭐ **一句话**：**别人在国内做事，他一辈子做的只有一件 —— 让外面肯跟俄国签字。**

| 级 | 节点 | 从上一级推 |
| --- | --- | --- |
| 根 | 1902 翻墙出去，坐上去日内瓦的火车 | —— |
| ① | **火星报的代办员** | **翻墙之后的第一件事，就是把墙外的纸送进墙内** |
| ② | **战俘交换协议** | **送纸的是他；十年后，他让对方的【政府】坐到桌前** |
| ③ | **李维诺夫议定书** | **双边签得成了，下一步是多边** |
| ④ | **侵略的定义** | **多边签得成了，下一步是给条约一把尺子** |
| ⑤ | **苏法互助条约** | **有了尺子，下一步是把俄国放进那个拿尺子的房间** |
| E1 | **国联的席位** | **房间还在，人不在了** |

⭐⭐ **首尾同轴**：**A1 是把一份在俄国境外印的报纸送进俄国；E1 是那个用这批报纸的体系给了苏联一个席位。**

### 1.2 🚩 为什么主干**不**是「他当了九年的外交人民委员」

- ❌ **「当了九年」是结果，不是原因** —— 任期长度推不出任何一个节点
- ✅ **「让外面肯跟俄国签字」能推出全部五个节点**，且**每一级的产物都是国际文件**（判据 C 过）
- 🚩 **判据 B 自检**：**换一个同类职业的人来，这条轴成立吗？**
  → **契切林外语同样好，但他主张俄国不与资本主义国家做交易** → ❌ **换个人不成立** ✅

### 1.3 🚩 刻意剔除的（见 `docs/65` §2.5，此处只列四条最要紧的）

| # | 题 | 理由 |
| --- | --- | --- |
| 1 | 🔴🔴 **莫斯科审判（布哈林 / 李可夫）** | **他被任命进那个决定布哈林与李可夫命运的委员会**，但**这两人是本 mod 已实装的本人** → 绝对不能做 |
| 2 | ⛔ **「集体安全 vs 单独安全」的选择题** | **原版 `SOV_policy_of_collective_security` × `..._individual_security` 已用 `mutually_exclusive` 占掉** |
| 3 | ⛔ **1906–1917 的军火采购十年** | 史料最生动，但**「为革命运武器」是托洛茨基军事线的邻接面** → 只在 A1 的文案里带一句 |
| 4 | ⛔ **1941–1943 驻美大使 / 第二战场** | 属于 **S6 15 国分支**的范围（`AGENTS.md` 待做项） |

---

## 2. 形状：**单线 5 节点 + 1 单结局 = 6 块**

```text
                        席位入口  hof_ic_seat_maksim_litvinov
                                     │
                        y1  ┌────────┴──────────────┐
                            │  A1 火星报的代办员     │  1902–1904 · 一条跨境通道
                            └────────┬──────────────┘
                        y2  ┌────────┴──────────────┐
                            │  A2 战俘交换协议       │  1920-02-12 · 事实承认
                            │  ⬆ 完成时官衔升到 Lv2  │
                            └────────┬──────────────┘
                        y3  ┌────────┴──────────────┐
                            │  A3 李维诺夫议定书     │  1929-02 · 一份以他命名的多边文件
                            │  ⬆ 完成时官衔升到 Lv3  │
                            └────────┬──────────────┘
                        y4  ┌────────┴──────────────┐
                            │  A4 侵略的定义         │  1933-02-06 · 一条国际法定义
                            │  ⬆ 完成时官衔升到 Lv4  │
                            └────────┬──────────────┘
                        y5  ┌────────┴──────────────┐
                            │  A5 苏法互助条约       │  1935 · 两条互助条约
                            └────────┬──────────────┘
                        y7  ┌────────┴──────────────┐
                            │  E1 外交人民委员会顾问 │  结局（前置 = A1..A5 全）
                            └───────────────────────┘
```

### 2.1 坐标与拓扑序（⬜ 待落盘）

| 序 | id | Y | 前置 | `x` | 升衔 |
| --- | --- | --- | --- | --- | --- |
| A1 | `hof_ic_litvinov_a_courier_of_iskra` | 1 | `__entry__` | 0 | — |
| A2 | `hof_ic_litvinov_the_prisoner_exchange_agreement` | 2 | A1 | 0 | **→ Lv2** |
| A3 | `hof_ic_litvinov_the_litvinov_protocol` | 3 | A2 | 0 | **→ Lv3** |
| A4 | `hof_ic_litvinov_the_definition_of_aggression` | 4 | A3 | 0 | **→ Lv4** |
| A5 | `hof_ic_litvinov_the_franco_soviet_treaty` | 5 | A4 | 0 | — |
| E1 | `hof_ic_litvinov_the_advisor_to_the_commissariat` | **7** | **A1..A5 全部（AND）** | 0 | — |

> 📌 **与加里宁（Idx 14）完全同形**（`x` 全 = 0，`y` = 1,2,3,4,5,**7**）→ **坐标 / 官衔链 / DM / 事件号的写法全部复用**。

---

## 3. 数值表

### 3.1 花名册（**已定，不动**）

| 项 | 值 |
| --- | --- |
| `Key` | `maksim_litvinov` |
| `Idea` | `hof_ic_idea_maksim_litvinov` |
| `Mod` | `improve_relations_maintain_cost_factor = 0.03` |
| `NewArt` | `gfx/interface/hof_ic/portraits/hof_portrait_SOV_maksim_litvinov.dds`（**自绘，已交付**） |

> ⚠️ **与他的原版专属特质 `pc_for_foreign_affairs_litvinov` 不重复**：那边是
> `opinion_gain_monthly_factor` / `democratic_acceptance`（**好感涨得多快、民主国家接不接受**），
> 这边是 `improve_relations_maintain_cost_factor`（**维持关系的成本**）—— **不同量**。✅

### 3.2 五个节点的数值（**只用已实测过的 4 条**）

| 节点 | 主数值 | 次数值 |
| --- | --- | --- |
| A1 | `political_power_factor` +0.05 | `research_speed_factor` +0.05 |
| A2 | `stability_factor` +0.05 | `political_power_factor` +0.05 |
| A3 | `political_power_factor` +0.05 | `war_support_factor` +0.05 |
| A4 | `stability_factor` +0.05 | `research_speed_factor` +0.05 |
| A5 | `political_power_factor` +0.05 | `stability_factor` +0.05 |

> ⭐⭐ **A5 另有【外交联动】**（`Raw` 里的一次性效果）—— **见 §3.4**。

### 3.3 数值容器（DM）

| 项 | 值 |
| --- | --- |
| `DmId` | `hof_ic_idea_maksim_litvinov` |
| `File` | `hof_ic_maksim_litvinov_dm.txt` |
| `DmName` | **李维诺夫的个人威望** |
| `DmDesc` | 李维诺夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。 |
| E1 追加 | `political_power_factor` 0.10 + `stability_factor` 0.10 + `research_speed_factor` 0.05 + `war_support_factor` 0.05 |

### 3.4 ⭐⭐ A5「苏法互助条约」的外交联动（**用机制把史实的那条链子写出来**）

> ⚠️⚠️ **先说避重**：**原版早就把「苏法互保」这套做完了** ——
> `SOV_policy_of_collective_security` 完成时会调
> `SOV_apply_collective_ageement_on_mutual_assistance_effects_basic`
> （`common/scripted_effects/SOV_scripted_effects.txt` **L3332**），三件套是：
> `diplomatic_relation = { relation = non_aggression_pact }` + **双向** `give_guarantee` +
> **双向** `add_opinion_modifier = SOV_policies_of_collective_security_opinion`（`value = 50` / `months = 36`）。
> → ⛔ **本线【不照抄】这套**（照抄＝重复原版，而且玩家会叠两次）。
> ✅ **本线做原版【没有做】的那一半 —— 史实上的「链条」。**

| 对象 | 给什么 | 为什么 |
| --- | --- | --- |
| **法国 FRA** | ① `non_aggression_pact`（**双向**）② `give_guarantee`（**双向**）③ `add_opinion_modifier = hof_ic_franco_soviet_treaty`（**value 50**，双向） | 1935-05-02《苏法互助条约》—— **那一年第一份、也是唯一一份带完整互保的** |
| **捷克 CZE** | ⭐⭐ **只给好感**：`CZE = { add_opinion_modifier = { modifier = hof_ic_soviet_czech_treaty target = ROOT } }`（**value 25**）—— **不给保障** | ⭐⭐⭐ **史实：1935-05-16 的苏捷条约附有议定书 —— 只有【法国先履行援助义务】，捷克才有义务援助。**<br>→ **法国拿到保障，捷克只拿到好感** —— **这就是那条链子** |
| **苏联自己** | ⛔ **不给任何军事加成** | ⭐ **史实：1935 年的苏法条约【没有军事参谋协定】** —— 有政治承诺、无军事执行。**忠实照写** |

**新增的文件与本地化**（照托洛茨基「中国革命问题」那套的蓝本，**两个文件都已存在，只追加**）：

| 文件 | 追加内容 |
| --- | --- |
| `mod/heart_of_iron/common/opinion_modifiers/hof_ic_opinion_modifiers.txt` | `hof_ic_franco_soviet_treaty = { value = 50 }`<br>`hof_ic_soviet_czech_treaty = { value = 25 }` |
| `mod/heart_of_iron/localisation/simp_chinese/hof_ic_l_simp_chinese.yml` | `hof_ic_franco_soviet_treaty:0 "苏法互助条约"`<br>`hof_ic_soviet_czech_treaty:0 "苏捷互助条约"` |

> ⚠️🚩 **两个文件的编码红线不同**（`AGENTS.md` 规则 3）：
> · `common/opinion_modifiers/*.txt` = **UTF-8【不带】BOM**
> · `localisation/simp_chinese/*.yml` = **UTF-8【带】BOM**，且**文件名的 `_l_simp_chinese` 后缀不能动**
> · 两个文件**都已经存在**（托洛茨基「中国革命问题」那轮建的），本轮只是**在文件末尾追加**，**不要重写整个文件**（会动到 BOM）

**落点** = A5 的 `Raw`（逐行写进 `completion_reward`）：

```text
if = {
	limit = { FRA = { is_subject = no  NOT = { has_war_with = ROOT } } }
	diplomatic_relation = { country = FRA  relation = non_aggression_pact  active = yes }
	give_guarantee = FRA
	add_opinion_modifier = { modifier = hof_ic_franco_soviet_treaty  target = FRA }
	FRA = {
		diplomatic_relation = { country = ROOT  relation = non_aggression_pact  active = yes }
		give_guarantee = ROOT
		add_opinion_modifier = { modifier = hof_ic_franco_soviet_treaty  target = ROOT }
	}
}
if = {
	limit = { CZE = { exists = yes } }
	CZE = { add_opinion_modifier = { modifier = hof_ic_soviet_czech_treaty  target = ROOT } }
}
```

> ⚠️ **实装前必须核的两条**（照 `AGENTS.md` 规则 6，拿不准就标）：
> ① **`give_guarantee` 的边界** —— 原版 `FRA_franco_soviet_treaty` 的 `available` 里挡的是
>    `is_subject = no` / `NOT { has_war_with = ROOT }` / `is_faction_leader = yes`。
>    **我们的 A5 用 `if = { limit = ... }` 包住同等条件**（上面示例已写）——
>    ⚠️ **没包住的话，与法国同阵营 / 法国已被保障时可能报错**。
> ② **`non_aggression_pact` 重复建立** —— 原版直接写 `active = yes`，**重复调用应当无害**；
>    ⚠️ **实装后看 `error.log` 确认**（规则 5）。
> ③ **同一条 `Raw` 里 `FRA` 与 `CZE` 都不在 22 人名单内** → **不触碰互斥矩阵**（`docs/10` §2.4.2 不动）。

---

## 4. 官衔链（`Tiers` / `RankGates`）

### 4.1 **四级**（驻地 → 副 → 正 → 国际组织）

| Lv | `Id` | 中文名 | `Pp` |
| --- | --- | --- | --- |
| 1 | `hof_ic_idea_maksim_litvinov` | **驻爱沙尼亚代理全权外交代表** | −0.10 |
| 2 | `hof_ic_idea_maksim_litvinov_2` | **外交副人民委员** | −0.30（+`stability_factor` 0.05） |
| 3 | `hof_ic_idea_maksim_litvinov_3` | **外交人民委员** | −0.30（+`stability_factor` 0.05） |
| 4 | `hof_ic_idea_maksim_litvinov_4` | **驻国际联盟代表** | −0.30（+`stability_factor` 0.05、`research_speed_factor` 0.05） |

### 4.2 `RankGates`（**从高到低**排）

| `Id` | `Gate` |
| --- | --- |
| `..._litvinov_4` | `has_completed_focus = hof_ic_litvinov_the_definition_of_aggression` |
| `..._litvinov_3` | `has_completed_focus = hof_ic_litvinov_the_litvinov_protocol` |
| `..._litvinov_2` | `has_completed_focus = hof_ic_litvinov_the_prisoner_exchange_agreement` |

### 4.3 ✅ 交叉核对（**四个职务全部未被任何已实装线用过**）

| 职务 | 最近的已实装线 | 为什么不撞 |
| --- | --- | --- |
| 驻爱沙尼亚代理全权外交代表 | 拉狄克（Idx 9）Lv1 = **外交人民委员部中欧司司长** | **部内司长 ≠ 驻外代表** |
| 外交副人民委员 | ⚠️ 谢列布里亚科夫（Idx 7）= **交通**人民委员**副** | **不同部** |
| 外交人民委员 | 拉狄克只到**司长** | **差两级** |
| 驻国际联盟代表 | ✅ **无人用过**（唯一的国际组织职务） | —— |

### 4.4 ⚠️ 刻意移出官衔链的

**驻美特命全权大使**（1941–1943，**职级低于人民委员，会破坏「升」的走向**）·
**工农监察人民委员**（与副人民委员同期兼任，且**「监察」是加里宁 / 李可夫邻接的机关题**）·
**驻古巴特命全权大使**（兼任，无分量）· **外交人民委员会顾问**（**是 E1 的素材，不是官衔**）。

---

## 5. 文案与出处（`AGENTS.md` 规则 9）

⭐⭐ **档次：2 / 6 是中文原文**（A1 托洛茨基中译本 · A2 中文版文集电报），其余 4 条为**英文维基自译**（其中 A4 与 E1 引的是**原文**）。

| 节点 | 文案 | 出处 |
| --- | --- | --- |
| **A1 火星报的代办员** | 「有个记者——**显然就是后来的李维诺夫，他根本不懂格鲁吉亚语**——**自国外报道**，说梯弗里斯出现了一本小册子，『造成了轰动』。」 | ✅ **中文原文** —— 托洛茨基《斯大林评传》中译本 |
| **A2 战俘交换协议** | 「主要的是，这类报导应该寄给沃罗夫斯基和**李维诺夫**。这可以通过契切林办。」 | ✅ **中文原文** —— 列宁 / 托洛茨基电报（中文版文集） |
| **A3 李维诺夫议定书** | 「1928 年的那份公约把『放弃战争』写进了纸面，却迟迟没有人批准。1929 年 2 月，他在莫斯科让苏联、波兰、罗马尼亚、拉脱维亚、爱沙尼亚**先互相承诺遵守它**。」 | ⚠️ 译自英文维基 |
| **A4 侵略的定义** | 「1933 年 2 月 6 日，法国代表保罗-邦库尔问他：全面裁军之后，小国难道不更危险吗？他反问：『**小国在强大邻国裁军之后，会比现在更不安全吗？现在那些大国除了经济、财政、领土上的优势之外，还额外享有庞大军备的好处。**』」 | ⚠️ 译自英文维基（**录有他的原话**） |
| **A5 苏法互助条约** | 「1933 年 11 月，他在华盛顿谈成了美苏建交。1935 年 5 月，他与法国签下互助条约；同月又与捷克斯洛伐克签了一份 —— **但捷克的那一份附着一句话：只有法国先履行援助，捷克才有义务援助。**」<br>🔄 **本轮改动**：**删掉「1934 年苏联加入国联」那一句**（用户口径：**二战国联已实际失效**，不把它当成果写） | ⚠️ 译自英文维基 |
| **E1 外交人民委员会顾问** | 「1939 年 5 月之后，他名下写的职务是「外交人民委员会顾问」。**两年后德国打了进来，他被重新派了出去** —— 这一次是驻美特命全权大使。」 | ⚠️ 译自中文维基年表（1939-05 – 1941-11 / 1941-11 – 1943-08）<br>⭐ **结局是向上的，不是刑场**；⛔ 不提族裔，不出现斯大林当主语 |

### 5.1 🚩 三条硬性写作纪律

| # | 纪律 | 理由 |
| --- | --- | --- |
| 1 | ⛔ **全文案不出现「集体安全」四个字** | 原版 `SOV_policy_of_collective_security` 已占（`docs/65` §1.3 #1） |
| 2 | ⛔ **1939-05-03 那件事只写「他被换下来」，不写「谁换了他」** | 项目口径：**文案里不出现斯大林当主语**（`docs/44` §9.3） |
| 3 | ⛔ **族裔一个字都不进游戏** | 史料已在 `docs/65` §8.4 留档，**game 文案不引** |

---

## 6. 跨簇钩子

**0 条。**（单簇线，无跳跃簇 —— 与加里宁 / 施利亚普尼科夫 / 里亚京同）

---

## 7. 实装清单（✅ **已执行**，2026-09-19；实际 **9 处手改 + 3 处自动**）

| # | 位置 | 内容 | 自动？ |
| --- | --- | --- | --- |
| 1 | `$roster[15]` | `Tiers`（4 级）/ `RankGates`（3 条）/ `Branch`（6 条） | 手 |
| 2 | `$litvinovLine` | 6 条（x 全 0，y = 1,2,3,4,5,**7**） | 手 |
| 3 | `$litvinovLoc` | 6 条（`[ordered]@{}`） | 手 |
| 4 | `$litvinovVars` | 个人数值容器 | 手 |
| 5 | 断言 | `if ($litvinovLine.Count -ne 6) { throw ... }` | 手 |
| 6 | `$lineSpecs` | `File = 'hof_ic_maksim_litvinov_dm.txt'` 等 | 手 |
| 7 | `$locOf` 校验 | 局部化键的对应检查 | 自动 |
| 8 | `build/focus-icon-owner.txt` | 缺图兜底映射 | 自动 |
| 9 | `mod/.../hof_ic_focus_icons.gfx` | 6 张 sprite 注册（**先走兜底**） | 自动 |

### 验收链（固定顺序，每步看输出）

```text
build/gen-hof-ic-s3.ps1        → 121 + 6 = 127 国策块 · 15 人驱动器 · 自检全过
build/gen-hof-ic-focus-icons.ps1 → sprite 120 + 6 = 126（97 交付 + 29 兜底）
build/sync-from-r56.ps1        → 成功 17 / 失败 0
build/verify-s2.ps1            → 失败项 0
build/gen-reference-index.ps1  → 211 行
build/verify-docs.ps1          → 失败项 0
```

### 7.1 数目推算（**照公式算，不写死**）

| 项 | 前（加里宁后） | **后（李维诺夫后）· 实测** |
| --- | --- | --- |
| 国策块 | 121 | **127**（22 + **104** 个人线 + 1） |
| sprite | 120 | **126** |
| 已交付 | 97 | **108**（⭐ **本轮美术交付 11 张：托姆斯基 6 + 里亚京 5**） |
| 缺图兜底 | 23 | **18**（= 加里宁 6 + 李维诺夫 6 + 施利亚普尼科夫 6） |
| 个人线驱动器 | 14 | **15** |
| 事件 | 33 | **35**（Idx 15 → `heartofiron.1250` / `.1251`） |

> 🚩 **交付数与兜底数不是同一个东西**：本轮新增的 6 块**全部走兜底**，
> **交付数的上涨只由美术交付的那 11 张推动**（97 → 108）。
> 📌 **兜底 18 的构成** = 加里宁 6 + 李维诺夫 6 + 施利亚普尼科夫 6（**只剩三条线走兜底**）。

---

## 8. ✅ 裁决记录（⬜ **提案，待用户过目**）

| # | 事项 | 推荐 | 备选 | 代价 |
| --- | --- | --- | --- | --- |
| ① | **主干** | ⭐⭐⭐ **「让一个不被承认的国家，被一个它被排除在外的体系接纳」** | A.「用对方的语言把事说成对方能接受的样子」（**判据 B 略弱**）<br>B.「九年外交人民委员」 | 改主干 = **两块数据全换 + `docs/65` §2 重写** |
| ② | **根** | ⭐⭐⭐ **「1902 从基辅监狱翻墙出去的那个人」**（托洛茨基中译本有原文） | A.「比亚韦斯托克的犹太商人之子」（**判据 B 不过**） | 改根 = 只改 `docs/65` §2.1 + §5 文案 |
| ③ | **节点数** | ⭐⭐ **5 节点 + 1 单结局 = 6 块**（与加里宁同形） | A. 砍 A5 → 4 + 1 = 5 块 | 砍一个 = **三处文档 + 2 块数据** |
| ④ | **E1 的名字** ✅ **2026-09-19 用户裁决取【乙】「外交人民委员会顾问」**<br>（我推荐的是【甲】驻美特命全权大使，用户取乙）<br>**用户理由：「国联的席位」要改 —— 二战国联已经实际失效**<br>→ **`id = hof_ic_litvinov_the_advisor_to_the_commissariat`**（旧候选的 id 从未落盘） | ⭐⭐⭐ **甲：驻美特命全权大使**（1941-11 – 1943-08）<br>· **史实专名、名词短语**（判据 F 过）<br>· ⭐⭐ **首尾对照**：1917 年他是英国**连身份都不承认**的「非正式代表」，1941 年他是华盛顿以最高规格接待的**特命全权大使**<br>· ⭐ **罗斯福说任命他「最幸运」** —— 评价原文在握<br>· ⭐ 与**根**（被派到国外做事）闭合 —— 他是**被重新派出去**的<br>· ⚠️ **代价**：要给 §2.5 #8 让路 —— **只取「职务」这一层，不写第二战场 / 租借** | **乙：外交人民委员会顾问**（1939-05 – 1941-11）—— ⭐ 史实专名，**九年的人民委员变成「顾问」四个字**；⚠️ 读起来像没内容<br>**丙：《侵略定义公约》**（1933-07，苏联与 8 个邻国签）—— ⭐ 史实专名；⚠️ 与 A4「侵略的定义」几乎同义<br>**丁：辞职信**（1939-05-03 那次谈话中要他签的那封）—— ⭐ 画面极强；⚠️ 与里亚京 E1「上留京诺的留京」的「不签」母题太近<br>**戊：特命全权大使**（＝甲的短名） | 改名 = **一处数据 + 一个 id + 四处摘要**（`docs/65` §2.3 / `docs/00-index` / `docs/23` §5 / `AGENTS.md`）<br>🚩 **连带动 id**：`hof_ic_litvinov_the_seat_in_the_league` → 按新名重取 |
| ⑤ | **官衔链** | ⭐⭐ **4 级**（驻爱沙尼亚代表 → 外交副人民委员 → 外交人民委员 → 驻国联代表） | A. 砍到 3 级（去掉 Lv1） | 砍一级 = **一处数据** |
| ⑥ | **A2 是否保留** | ⭐⭐ **保留**（「事实承认」是本线主干的第一次落地） | A. 砍掉 → 4 节点 | 砍一个 = **三处文档 + 2 块数据** |
| ⑦ | **数值组** | ✅ **已采纳** —— 只用 `political_power_factor` / `stability_factor` / `research_speed_factor` / `war_support_factor` **4 条** | — | —— |
| ⑧ | **文案档次** | ⭐⭐ **2/6 中文原文 + 4 条英文自译** | A. 先把 4 条中译稿拿回来再实装（**要多抓一轮史料**） | —— |
| ⑨ | ✅ **2026-09-19 用户裁决：「A5 可以」—— 照 §3.4 整套执行**<br>**用户口径：「可以额外设置一下和法国的联动，比如和托洛茨基的中共一样加好感度，或者给两国加史实上有的什么东西」** | ⭐⭐⭐ **§3.4 的整套**：<br>**法国** = 互不侵犯条约（双向）+ 互相保障（双向）+ **双向好感 50**<br>**捷克** = ⭐ **只给好感 25，不给保障**（**史实：1935-05-16 苏捷条约的议定书 —— 只有法国先履行援助，捷克才有义务援助**）<br>**苏联** = ⛔ **不给任何军事加成**（**史实：1935 年条约【没有军事参谋协定】**） | **A. 只给法国加好感**（最省事，照托洛茨基「中国革命问题」的蓝本）<br>**B. 照抄原版 `SOV_policies_of_collective_security` 的三件套** —— ⛔ **重复原版**，而且玩家会叠两次<br>**C. 也给法国加一个史实上的国家精神**（`FRA = { add_ideas = ... }`，原版有这样用的先例）—— ⚠️ **会给别国塞一个「苏联的」精神，语义别扭** | 联动 = **2 条 opinion modifier + 2 条本地化 + 一段 `Raw`**<br>⚠️ `give_guarantee` **必须用 `if = { limit = ... }` 包住**（照原版挡 `is_subject = no` / `has_war_with`） |

---

## 9. 相关文件

| 文件 | 内容 |
| --- | --- |
| [`docs/65-litvinov-genealogy.md`](65-litvinov-genealogy.md) | **谱系**（第 0–5 步，⭐ §1.3 十三套机制 · §2.4 十一处邻接） |
| [`docs/23-figure-focus-playbook.md`](23-figure-focus-playbook.md) | **SOP 手册**（⭐ **判据 A–F**） |
| [`docs/10`](10-requirements-soviet-expansion.md) §2.4.2 | **互斥矩阵唯一权威出处**（⚠️ **他排掉 0 人**） |
| [`docs/28`](28-entry-focus-icon-prompts.md) §102 | 入口图标（**地球仪与条约卷轴**；国联徽记） |
| [`docs/63`](63-kalinin-focus-tree-design.md) | 上一位（加里宁，**同形**） |

> ✅ **2026-09-19 已实装并全链绿**。出图说明 = [`docs/67`](67-litvinov-focus-icon-prompts.md)（6 张）。
> **落盘的 9 处** = `$roster[15]`（`Tiers`/`RankGates`/`Branch`）· `$litvinovLine` · `$litvinovLoc` ·
> `$litvinovVars` · 断言 · `$lineSpecs` · `$locOf` · **`common/opinion_modifiers/hof_ic_opinion_modifiers.txt`（2 条）** ·
> **`localisation/simp_chinese/hof_ic_l_simp_chinese.yml`（2 条键）**。
> 🚩 **下一步 = Idx 16 · 格里戈里·索柯里尼柯夫**（`neutral` 营，⚠️ **同样排掉 0 人**，最难避重的一档）。
