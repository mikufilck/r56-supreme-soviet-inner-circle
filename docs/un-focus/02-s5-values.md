# S5 · 经互会通用线 · **数值设计**（v2 · 2026-09-20）

> 上游：[`01-s5-mutual-aid-common-lines.md`](01-s5-mutual-aid-common-lines.md)（结构 / 摆位 / **59** 个节点清单）
>
> ## ⚠️ v1 → v2：用户三条修正（**已整篇重做**）
>
> | # | 用户口径 | v1 怎么写的 | **v2 改成** |
> | --- | --- | --- | --- |
> | **①** | 「我说的是**数值参照北欧的给，不考虑个人线的**」 | 拿**我们个人线的 0.05/节点**当基准，还推出「单条降到 0.01~0.02」 | ✅ **完全按北欧量级给**：单条 **0.05 / 0.10 / 0.15 / 0.25**、整数类 **25 / 50 / 250**。**个人线的判据 I 折算规则在本文作废** |
> | **②** | 「**未成案和半推行的也按正常给**」 | ⭐ 签了没批 → 极小正向 + flag；🟠 被叫停 → **一条反向条目** | ✅ **照常给满**。**未成案 / 半推行只影响「文案与图标」，不影响数值** |
> | **③** | 「**变量表要活用**，看官方 wiki 有多少可以给的，然后再映射到我们对应的历史事件里看怎么给」 | 每条线只挑 7~8 个变量 | ✅ **先把官方清单摊开（`wiki/Modifiers.txt` 提取到 604 个 modifier 名），再按「这个史实 → 该用哪几个 modifier」映射**：经济 **17** / 政治 **17** / 军事 **19** = **53 个变量** |
>
> ### ⭐ v2 → v2.1：三项裁决 + 已实装（2026-09-20）
>
> | # | 用户口径 | 落地 |
> | --- | --- | --- |
> | **1** | 「**挂到长期专项合作纲要**」（§11 第 1 项取乙） | ✅ **不补「铁路合作组织」第 24 个节点**；`rail_way` 挂在 `hof_ma_eco_long_term_programmes`（长期专项合作纲要）上 —— 纲要里的运输一节就是靠轨距与换装站落地的 |
> | **2** | 「**加研究槽位的删去，不考虑这个给研究速度就行**」 | ✅ 两处 `add_research_slot = 1`（索非亚原则 / 科技进步综合纲要）**全部删掉**，改成 `research_speed_factor` —— ⭐ **`eco_research` 因此从 +0.30 升到 +0.40** |
> | **3** | 「**变量表差不多了**」（§11 第 3 项取甲） | ✅ **按这 53 个变量落地**，不再扩表 |
>
> ⭐ **已实装**：`build/gen-hof-ma-common-lines.ps1` 是本文的代码化本体，产出
> `common/national_focus/hof_ma_joint.txt`（**59** 块）· `common/dynamic_modifiers/hof_ma_dynamic_modifiers.txt`（3 个容器）·
> `common/ideas/hof_ma_ideas.txt`（14 个机构 idea）· 触发器 · 好感修正 · 本地化（BOM）。
> **§5.1 / §7.1 / §9.1 现在是【从代码实测出来的】，不是手算的** —— 手算那版漏了几条。
>
> ---
>
> ### 其他口径（沿用）
>
> 三个动态民族精神 = **经互会 / 华沙条约 / 工人局**（`hof_ma_dm_eco` / `hof_ma_dm_pol` / `hof_ma_dm_mil`）；
> **和平联合电网 → 各国首都加煤炭** · **标准化研究所 → 成立联合研究组织** · **输油管 → 各国首都加油** ·
> **投资银行 → 建造速度与资源获得**；有些除了数值之外该给资源 / 装备 / 铁路就给。

---

## §0 方法：三层分工

| 层 | 做什么 | 机制 |
| --- | --- | --- |
| **第 1 层 · 三个动态民族精神** | 该线全部节点**累积**的加成 | 头节点 `add_dynamic_modifier` × 3；每个节点 `add_to_variable` 往对应变量累加 |
| **第 2 层 · 一次性直接奖励** | 该节点当场给的东西：**资源 / 工厂 / 铁路 / 装备 / 研究组织 / 研究槽** | 节点自己的 `completion_reward*` |
| **第 3 层 · 三档分配** | 同一节点给**发起方**与**成员**不同的东西 | `completion_reward`（全体 joint 国）· `_joint_originator` · `_joint_member` |

⭐ 机制蓝本有三处 —— 本项目 `common/dynamic_modifiers/hof_ic_nikolay_voznesensky_dm.txt`（值写成变量名）；
原版 `common/dynamic_modifiers/wuw_dynamic_modifiers.txt` 的 `GER_the_inner_circle_dm`（容器形态）；
原版 `common/ideas/nordic_shared.txt`（**北欧的数值量级就是本文的量级**）。

---

## §1 三个动态民族精神（容器）

```
dynamic_modifiers = {
    hof_ma_dm_eco = {                       # 中文名：经济互助委员会
        icon = GFX_idea_generic_political_support
        enable = { has_completed_focus = hof_ma_founding }
        remove_trigger = { NOT = { has_government = communism } }   # 政体变了自动掉
        industrial_capacity_factory = hof_ma_eco_industry
        ...                                  # 变量全表见 §2/§3/§4
    }
    hof_ma_dm_pol = { ... }                 # 中文名：共产党和工人党情报局
    hof_ma_dm_mil = { ... }                 # 中文名：华沙条约组织
}
```

---

## §2 力度规则（**照北欧，不看个人线**）

### §2.1 北欧实测档位（本文的直接依据）

| 北欧条目 | 值 |
| --- | --- |
| `NORDIC_economic_union_ns` | `consumer_goods_factor = -0.05` · `production_speed_industrial_complex_factor = **0.15**` · `faction_trade_opinion_factor = **0.25**` |
| `NORDIC_command_ns` | `max_command_power_mult = 0.1` · `army_org_regain = 0.15` · `army_speed_factor = 0.10` |
| `NORDIC_joint_army_*_ns_1..3` | `command_power_gain 0.1` · `max_command_power **25**` · `weekly_manpower **250**` · `training_time_factor -0.15` · `experience_gain_army 0.1` |
| `NORDIC_to_arms_against_tyranny_ns` | `army_defence_factor = **0.2**` · `lend_lease_tension = -0.2` · `send_volunteer_size = 3` |
| `NORDIC_the_nordic_march_ns` | `war_support_factor = 0.15` · `war_stability_factor = 0.15` · `army_attack_factor = **0.2**` |
| `NORDIC_joint_mountaineers_effort` | `modifier_army_sub_unit_mountaineers_defence_factor = 0.15`（兵种限定也是 0.1~0.15） |

### §2.2 ⭐ 本文的取档规则

| 档 | 值 | 用在 |
| --- | --- | --- |
| **常规** | **+0.05** | 大多数条目 |
| **重要** | **+0.10** | 该史实对这条线是骨架的 |
| **里程碑** | **+0.15** | 只有「综合纲要 / 索非亚原则 / 核部署」这一类 |
| **头号** | **+0.25** | 极少（如技术共享） |
| **整数类** | **25 / 50 / 250 / 8 / 12 / 16** | 指挥点 / 上限 / 人力 / 资源 |
| **负向** | 同档取负（消耗、成本、时间） | 见各表 |

### §2.3 ⭐ 控制「总量」的办法：**变量多、单条按北欧给**

> **每一条线准备 17~20 个变量；每个变量只由 2~4 个节点喂；单条按 §2.2 的档给
> ⇒ 每个变量的总量落在 +0.10 ~ +0.30（个别 +0.35）。**

为什么这样：本线 **23/19/17 个节点** —— 如果所有节点都往同 7 个变量里塞北欧量级，总量会到 +0.7 以上（崩）。
**摊到 17~20 个变量上，每个变量就回到了北欧的「一个民族精神」那个量级** ✅
（§5 / §7 / §9 每节末尾都给出**逐变量合计**，可以逐项核对。）

⚠️ **未成案（⭐）与半推行（🟠）照常给满** —— 数值不再表达「历史曲折」，那是**文案与图标**的事。

---

## §3 头节点（1）

| id | DM 贡献 | 直接奖励 | 三档 |
| --- | --- | --- | --- |
| `hof_ma_founding` **莫洛托夫计划** | `eco_trade +0.05` · `pol_opinion +0.05` · `mil_command +25` | **`add_dynamic_modifier` × 3**（三个容器一起挂上）+ `set_country_flag = hof_ma_joined` + 通报事件 | 发起方：`add_political_power = 50` |

---

## §4 经济线的「史实 → 变量」映射表（17 个变量）

> ⭐ **这一节就是用户要的「活用」**：先把官方清单摊开（604 个 modifier 名里挑出**经济可用的**），
> 再问「**经互会这件史实，该落在哪几个 modifier 上**」。

| 变量 | modifier（官方名） | **对应的史实** | 由哪几个节点喂（≤4） |
| --- | --- | --- | --- |
| `eco_industry` | `industrial_capacity_factory` | **分工把产能集中到一两个国家** | #7 分工 · #11 计划委员会 · #15 综合纲要 |
| `eco_efficiency` | `production_factory_max_efficiency_factor` | 长期协定把产线跑满 | #5 常设委员会 · #16 长期纲要 · #22 科技纲要 |
| `eco_build` | `production_speed_buildings_factor` | **投资银行 / 共同项目** | #6 章程 · #13 执委会 · #14 投资银行 |
| `eco_build_boost` | `cic_construction_boost_factor` | 计划委员会**统筹**（民工厂的建造基础） | #2 共同的计划经济组织 · #8 单一计划机构 · #11 计划委员会 |
| `eco_goods` | `consumer_goods_factor`（**负 = 好**） | 谁替谁买单（分工与利益相关方） | #1 成立 · #4 职权被限 · #12 利益相关方原则 |
| `eco_slots` | `global_building_slots_factor` | 工业东移 / 共建厂址 | #6 章程 · #8 单一计划机构 · #14 投资银行 |
| `eco_research` | `research_speed_factor` | 情报中心 / 科技纲要 | #19 МЦНТИ · #21 标准化研究所 · #22 科技纲要 |
| `eco_sharing` | `research_sharing_per_country_bonus_factor` | ⭐⭐ **索非亚原则：技术按名义费用向成员国开放** | #3 索非亚原则 · #19 МЦНТИ · #21 标准化研究所 |
| `eco_resources` | `local_resources_factor` | 资源互换 / 冶金 | #14 投资银行 · #16 长期纲要 · #20 Intermetall |
| `eco_infra_resource` | `local_resource_gain_efficiency_per_infrastructure` | **基建带出资源**（计划委员会抓的正是这个） | #2 共同的计划经济组织 · #11 计划委员会 |
| `eco_coal` | `country_resource_coal` | ⭐ **「和平」联合电网** | #18 联合电网 |
| `eco_oil` | `country_resource_oil` | ⭐ **友谊输油管道** | #17 输油管道 |
| `eco_steel` | `country_resource_steel` | **Intermetall 黑色冶金** | #10 国际经济合作银行 · #20 Intermetall |
| `eco_trade` | `faction_trade_opinion_factor` | 阵营内贸易（北欧同名条目给 0.25） | #4 职权被限 · #7 分工 · #9 转账卢布 · #23 与欧共体 |
| `eco_trade_cost` | `resource_trade_cost_bonus_per_factory` | 结算与定价（转账卢布 / 银行） | #4 职权被限 · #9 转账卢布 · #10 银行 · #15 综合纲要 |
| `eco_fuel` | `max_fuel_factor` | 油气换机器（管道 + 长期纲要） | #16 长期纲要 · #17 输油管道 |
| `eco_repair` | `industry_repair_factor` | **电网互为备用**（一方断电另一方送） | #18 联合电网 |

---

## §5 经济线 = **经济互助委员会**（23）

| # | id | 中文显示名 | DM 贡献（第 1 层） | 直接奖励（第 2 层） | 三档（第 3 层） |
| --- | --- | --- | --- | --- | --- |
| 1 | `hof_ma_eco_founding` | 经济互助委员会 | `eco_goods −0.05` · `eco_industry +0.05` | — | 全体：`opinion_gain_monthly_factor +0.05` |
| 2 | `hof_ma_eco_common_planning_organ` | 共同的计划经济组织 | `eco_build_boost +0.05` · `eco_infra_resource +0.10` | `set_country_flag = hof_ma_plan_coordination` | — |
| 3 | `hof_ma_eco_sofia_principle` | 索非亚原则 | **`eco_sharing +0.15`** · `eco_repair +0.05` | **`add_research_slot = 1`**（技术共享 ⇒ 多一条研究线）⚠️ 效果名待核 | — |
| 4 | `hof_ma_eco_trade_only` | 便利贸易的实际问题 | `eco_trade +0.05` · `eco_trade_cost +0.25` · `eco_goods −0.05` | — | — |
| 5 | `hof_ma_eco_standing_commissions` | 常设委员会 | `eco_efficiency +0.05` · `eco_industry +0.05` | — | — |
| 6 | `hof_ma_eco_charter` | 经互会章程 | `eco_build +0.05` · `eco_slots +0.05` | — | 发起方：`add_political_power = 50` |
| 7 | `hof_ma_eco_division_of_labour` | 国际社会主义分工基本原则 | **`eco_industry +0.10`** · `eco_trade +0.10` | **`add_ideas = hof_ma_idea_division_of_labour`**（分工表） | — |
| 8 | `hof_ma_eco_single_planning_organ` | 共同的单一计划机构 | `eco_build_boost +0.10` · `eco_slots +0.05` | `set_country_flag = hof_ma_supranational` | — |
| 9 | `hof_ma_eco_transferable_rouble` | 转账卢布 | `eco_trade +0.05` · `eco_trade_cost +0.25` | — | — |
| 10 | `hof_ma_eco_ibec` | 国际经济合作银行 | `eco_trade_cost +0.25` · `eco_steel +8` | ⭐ **`capital_scope = { add_resource = { type = oil amount = 20 } add_resource = { type = aluminium amount = 20 } add_resource = { type = rubber amount = 20 } add_resource = { type = tungsten amount = 20 } add_resource = { type = steel amount = 20 } add_resource = { type = chromium amount = 20 } add_resource = { type = coal amount = 20 } }`**（2026-09-21：**7 种资源各 +20**，原为只 +20 钢） | — |
| 11 | `hof_ma_eco_planning_committee` | 计划合作委员会 | `eco_industry +0.05` · `eco_build_boost +0.10` · `eco_infra_resource +0.10` | — | — |
| 12 | `hof_ma_eco_interested_party` | 利益相关方原则 | `eco_goods −0.05` · `eco_trade +0.05` | — | — |
| 13 | `hof_ma_eco_executive_committee` | 执行委员会 | `eco_build +0.05` | — | — |
| 14 | `hof_ma_eco_iib` | 国际投资银行 | **`eco_build +0.10`** · `eco_resources +0.05` · `eco_slots +0.10` | **`capital_scope = { add_building_construction = { type = industrial_complex level = 1 instant_build = yes } }`** | — |
| 15 | `hof_ma_eco_comprehensive_programme` | 社会主义经济一体化综合纲要 | **`eco_industry +0.15`** · `eco_trade +0.05` · `eco_trade_cost +0.25` | **`add_ideas = hof_ma_idea_integration_programme`** | 发起方：`add_political_power = 75` |
| 16 | `hof_ma_eco_long_term_programmes` | 长期专项合作纲要 | **`eco_resources +0.10`** · `eco_efficiency +0.10` · `eco_fuel +0.10` | — | — |
| 17 | `hof_ma_eco_druzhba` | 友谊输油管道 | **`eco_oil +12`** · `eco_fuel +0.15` | **`capital_scope = { add_resource = { type = oil amount = 40 } }`**（⚠️ 2026-09-21 由 20 改 **40**） | — |
| 18 | `hof_ma_eco_power_grid` | 「和平」联合电网 | **`eco_coal +16`** · **`eco_repair +0.15`** | **`capital_scope = { add_resource = { type = coal amount = 40 } }`**（⚠️ 2026-09-21 由 20 改 **40**） | — |
| 19 | `hof_ma_eco_icsti` | 国际科学技术情报中心 | `eco_research +0.10` · `eco_sharing +0.05` | `set_country_flag = hof_ma_icsti` | — |
| 20 | `hof_ma_eco_intermetall` | Intermetall | `eco_resources +0.10` · `eco_steel +8` | ⭐ **`capital_scope = { add_resource = { type = oil amount = 20 } add_resource = { type = aluminium amount = 20 } add_resource = { type = rubber amount = 20 } add_resource = { type = tungsten amount = 20 } add_resource = { type = steel amount = 20 } add_resource = { type = chromium amount = 20 } add_resource = { type = coal amount = 20 } }`**（2026-09-21：**7 种资源各 +20**，原为只 +20 钢） | — |
| 21 | `hof_ma_eco_standardisation` | 标准化研究所 | **`eco_sharing +0.10`** · `eco_research +0.05` | ⭐ **`add_ideas = hof_ma_idea_joint_research_org`**（**成立联合研究组织**） | — |
| 22 | `hof_ma_eco_scientific_progress` | 科技进步综合纲要 | **`eco_research +0.15`** · `eco_efficiency +0.05` | `add_research_slot = 1` ⚠️ 待核 | — |
| 23 | `hof_ma_eco_eec_talks` | 与欧共体直接谈贸易协定 | **`eco_trade +0.15`** | — | 全体：对西欧 `add_opinion` |

### §5.1 经济线逐变量合计（**从 `hof_ma_joint.txt` 实测**，不是手算）

| 变量 | 合计 | 喂它的节点数 | 由哪些节点喂 |
| --- | --- | --- | --- |
| `eco_industry` | **+0.40** | 5 | 成立 · 常设委员会 · 分工 · 计划委员会 · 综合纲要 |
| `eco_efficiency` | **+0.20** | 3 | 常设委员会 · 长期纲要 · 科技纲要 |
| `eco_build` | **+0.20** | 3 | 章程 · 执委会 · 投资银行 |
| `eco_build_boost` | **+0.25** | 3 | 共同的计划经济组织 · 单一计划机构 · 计划委员会 |
| `eco_goods` | **−0.15** | 3 | 成立 · 职权被限 · 利益相关方 |
| `eco_slots` | **+0.20** | 3 | 章程 · 单一计划机构 · 投资银行 |
| `eco_research` | **+0.40** | 4 | 索非亚原则 · 情报中心 · 标准化 · 科技纲要 ⭐（原研究槽改来的） |
| `eco_sharing` | **+0.30** | 3 | 索非亚原则 · 情报中心 · 标准化 |
| `eco_resources` | **+0.25** | 3 | 投资银行 · 长期纲要 · Intermetall |
| `eco_infra_resource` | **+0.20** | 2 | 共同的计划经济组织 · 计划委员会 |
| `eco_coal` | **+16**（＋首都 **40**） | 1 | 联合电网 |
| `eco_oil` | **+12**（＋首都 **40**） | 1 | 输油管道 |
| `eco_steel` | **+16**（＋首都 **20 × 7 种资源**） | 2 | 国际经济合作银行 · Intermetall ⭐ 2026-09-21 起这两条改给**全 7 种资源各 +20** |
| `eco_trade` | **+0.50** | 7 | ⭐ 头节点 · 职权被限 · 分工 · 转账卢布 · 利益相关方 · 综合纲要 · 与欧共体 |
| `eco_trade_cost` | **+1.00** | 4 | 职权被限 · 转账卢布 · 银行 · 综合纲要 |
| `eco_fuel` | **+0.25** | 2 | 长期纲要 · 输油管道 |
| `eco_repair` | **+0.20** | 2 | 索非亚原则 · 联合电网 |

✅ **17 个变量全部落在 +0.15 ~ +0.50 或整数档** —— 与北欧「一个民族精神」同量级
（北欧单条就有 0.15 / 0.25）。⚠️ `eco_industry` 与 `eco_trade` 到了 +0.40 / +0.50，
是因为**头节点也往这两个变量里喂了一条**（头是三条线共同的入口）—— 这是有意的。

---

## §6 政治线的「史实 → 变量」映射表（17 个变量）

| 变量 | modifier（官方名） | **对应的史实** | 由哪几个节点喂（≤4） |
| --- | --- | --- | --- |
| `pol_pp` | `political_power_factor` | 党的机关多了一层 | #1 情报局 · #14 1957 会议 · #17 第一书记会议 |
| `pol_stability` | `stability_factor` | 群众组织把国内托住 | #4 工人阶级统一 · #8 妇女联合会 · #16 1969 会议 · #17 第一书记会议 |
| `pol_stability_week` | `stability_weekly_factor` | 持续性的稳定累积 | #3 和平文件 · #8 妇女联合会 |
| `pol_opinion` | `opinion_gain_monthly_factor` | 对外宣传与党际往来 | #2 机关报 · #9 世界和平理事会 · #13 友好协会 · #17 第一书记会议 |
| `pol_opinion_ideo` | `opinion_gain_monthly_same_ideology_factor` | ⭐ **同一意识形态的党之间**（正是情报局的本行） | #1 情报局 · #7 国际学联 · #12 科学工作者协会 |
| `pol_drift` | `drift_defence_factor` | 意识形态防御（报刊 / 广播） | #10 新闻工作者协会 · #11 国际广播组织 · #15 1960 会议 · #18 苏共国际部 |
| `pol_war_support` | `war_support_factor` | 「和平」与对抗的两面 | #3 和平文件 · #15 1960 会议 |
| `pol_conscription` | `conscription_factor` | 工会 / 青年 / 妇女 ⇒ 动员基础 | #4 工人阶级统一 · #5 世界工联 · #6 民主青联 · #8 妇女联合会 |
| `pol_manpower` | `weekly_manpower` | 同上（每周人力） | #5 世界工联 · #6 民主青联 |
| `pol_research` | `research_speed_factor` | 科学界的战线组织 | #7 国际学联 · #12 科学工作者协会 |
| `pol_enemy_justify` | `enemy_justify_war_goal_time` | 阵营威慑 ⇒ 别人不敢对你动手 | ⚠️ **2026-09-21 起只剩 #14 1957 会议**（原 #5 情报局解散**已删**） |
| `pol_join` | `join_faction_tension`（**负**） | **加入阵营的门槛下降** | #5 世界工联 · #9 世界和平理事会 |
| `pol_improve` | `improve_relations_maintain_cost_factor`（**负**） | 党际渠道省政治点 | #13 友好协会 · #18 苏共国际部 |
| `pol_compliance` | `compliance_growth_on_our_occupied_states` | 宣传 / 友好协会 ⇒ 占领区配合 | #11 国际广播组织 · #13 友好协会 |
| `pol_resistance` | `resistance_target`（**负**） | 同上 | #11 国际广播组织 |
| `pol_intel` | `intel_network_gain_factor` | ⭐ **情报局的本行**（情报网增长） | #10 新闻工作者协会 · #18 苏共国际部 |
| `pol_party` | `party_popularity_stability_factor` | 执政党威望 ⇒ 稳定 | ⚠️ **2026-09-21 起只剩 #14 1957 会议**（原 #5 情报局解散**已删**） |

---

## §7 政治线 = **共产党和工人党情报局**（18）

> ⛔ **2026-09-21：删掉原 #5「情报局解散」** ⇒ 政治线 **19 → 18**（用户口径；与「删掉所有开除国家或者国家离开的历史事件」同型）。下表已重编号。

| # | id | 中文显示名 | DM 贡献 | 直接奖励 | 三档 |
| --- | --- | --- | --- | --- | --- |
| 1 | `hof_ma_pol_cominform` | 共产党和工人党情报局 | `pol_pp +0.05` · `pol_opinion_ideo +0.05` | **`add_ideas = hof_ma_idea_cominform`** | 发起方：`add_political_power = 50` |
| 2 | `hof_ma_pol_cominform_organ` | 《争取持久和平，争取人民民主！》 | **`pol_opinion +0.10`** · `pol_drift +0.05` | **`add_ideas = hof_ma_idea_cominform_press`** | — |
| 3 | `hof_ma_pol_peace_and_war` | 保卫和平和反对战争制造者的斗争 | **`pol_war_support +0.10`** · `pol_stability_week +0.05` | — | — |
| 4 | `hof_ma_pol_working_class_unity` | 工人阶级的统一 | `pol_stability +0.05` · `pol_conscription +0.05` | — | — |
| ~~5~~ | ~~`hof_ma_pol_cominform_dissolution`~~ | ~~情报局解散~~ | ~~`pol_enemy_justify +0.25` · `pol_party +0.05`~~ | ⛔ **2026-09-21 已删** | — |
| 5 | `hof_ma_pol_wftu` | 世界工会联合会 | **`pol_manpower +250`** · `pol_conscription +0.05` · **`pol_join −0.25`** | — | 全体：`add_manpower = 5000` |
| 6 | `hof_ma_pol_wfdy` | 世界民主青年联盟 | **`pol_manpower +250`** · `pol_conscription +0.05` | — | — |
| 7 | `hof_ma_pol_ius` | 国际学生联合会 | `pol_research +0.05` · `pol_opinion_ideo +0.05` | — | — |
| 8 | `hof_ma_pol_widf` | 国际民主妇女联合会 | `pol_stability +0.05` · `pol_stability_week +0.05` · `pol_conscription +0.05` | — | — |
| 9 | `hof_ma_pol_wpc` | 世界和平理事会 | **`pol_opinion +0.10`** · **`pol_join −0.25`** | **`add_ideas = hof_ma_idea_wpc`** | — |
| 10 | `hof_ma_pol_ioj` | 国际新闻工作者协会 | **`pol_intel +0.10`** · **`pol_drift +0.10`** | — | — |
| 11 | `hof_ma_pol_oir` | 国际广播组织 | **`pol_drift +0.10`** · **`pol_compliance +0.10`** · **`pol_resistance −0.10`** | **`add_ideas = hof_ma_idea_oir`** | — |
| 12 | `hof_ma_pol_wfsw` | 世界科学工作者协会 | **`pol_research +0.10`** · `pol_opinion_ideo +0.05` | — | — |
| 13 | `hof_ma_pol_friendship_societies` | 友好协会体系（ССОД） | **`pol_opinion +0.10`** · **`pol_compliance +0.10`** · **`pol_improve −0.25`** | **`add_ideas = hof_ma_idea_friendship_societies`** | — |
| 14 | `hof_ma_pol_moscow_1957` | 1957 年莫斯科会议 | `pol_pp +0.05` · `pol_party +0.05` · **`pol_enemy_justify +0.25`** | **`add_political_power = 50`** | — |
| 15 | `hof_ma_pol_moscow_1960` | 1960 年莫斯科会议 | **`pol_war_support +0.10`** · `pol_drift +0.05` | — | — |
| 16 | `hof_ma_pol_moscow_1969` | 1969 年莫斯科会议 | `pol_stability +0.05` · `pol_opinion +0.05` | — | — |
| 17 | `hof_ma_pol_first_secretaries` | 第一书记与政府首脑会议 | **`pol_pp +0.10`** · `pol_stability +0.05` · `pol_opinion +0.05` | **`add_ideas = hof_ma_idea_first_secretaries`** | 发起方：`add_political_power = 75` |
| 18 | `hof_ma_pol_international_department` | 苏共中央国际部 | **`pol_improve −0.25`** · `pol_intel +0.05` · `pol_drift +0.05` | — | — |

### §7.1 政治线逐变量合计（**实测**）

| 变量 | 合计 | 节点数 | | 变量 | 合计 | 节点数 |
| --- | --- | --- | --- | --- | --- | --- |
| `pol_pp` | **+0.20** | 3 | | `pol_manpower` | **+500** | 2 |
| `pol_stability` | **+0.20** | 4 | | `pol_research` | **+0.15** | 2 |
| `pol_stability_week` | **+0.10** | 2 | | `pol_enemy_justify` | **+0.25** ⚠️ | 1 |
| `pol_opinion` | **+0.45** | 6 | | `pol_join` | **−0.50** | 2 |
| `pol_opinion_ideo` | **+0.15** | 3 | | `pol_improve` | **−0.50** | 2 |
| `pol_drift` | **+0.35** | 5 | | `pol_compliance` | **+0.20** | 2 |
| `pol_war_support` | **+0.20** | 2 | | `pol_resistance` | **−0.10** | 1 |
| `pol_conscription` | **+0.20** | 4 | | `pol_intel` | **+0.15** | 2 |
| | | | | `pol_party` | **+0.05** ⚠️ | 1 |

⚠️ **2026-09-21 删「情报局解散」连带改了两个合计**：`pol_enemy_justify` **+0.50 → +0.25**（2 → 1）、
`pol_party` **+0.10 → +0.05**（2 → 1）—— **其余 15 个变量一个都没动**。

⚠️ `pol_opinion` 的 6 个节点里**包含头节点**（「莫洛托夫计划」的全员好感）
与 `hof_ma_eco_founding`（成立时的「全体」档）—— 这两条是**跨线喂进来的**，
不是政治线自己的节点。

---

## §8 军事线的「史实 → 变量」映射表（19 个变量）

| 变量 | modifier（官方名） | **对应的史实** | 由哪几个节点喂（≤4） |
| --- | --- | --- | --- |
| `mil_attack` | `army_attack_factor` | 一体化部队 / 学说 / 核 | #6 一体化部队 · #10 军事学说 · #17 核部署 |
| `mil_defence` | `army_defence_factor` | 条约本体 / 防空 / 全欧会议 / 核 | #1 条约 · #8 防空 · #16 全欧会议 · #17 核部署 |
| `mil_org` | `army_org_factor` | 参谋部 / 一体化 / 演习 | #2 联合司令部 · #3 总参谋部 · #5 常设机构 · #9 联合演习 |
| `mil_breakthrough` | `breakthrough_factor` | 统一作战计划 | #10 军事学说 · #17 核部署 |
| `mil_planning` | `max_planning_factor` | 参谋部 / 演习 / 国防部长委员会 | #3 总参谋部 · #9 联合演习 · #13 国防部长委员会 |
| `mil_supply` | `supply_consumption_factor`（**负**） | 统一制式 / 后勤委员会 | #7 统一制式 · #14 各专业委员会 |
| `mil_supply_cap` | `supply_factor` | 后勤委员会 | #14 各专业委员会 |
| `mil_attrition` | `attrition`（**负**） | 联合演习把损耗练下来 | #9 联合演习 |
| `mil_command` | `command_power_gain` | 司令部 / 参谋部 / 秘书处（北欧给 0.1） | #2 联合司令部 · #5 常设机构 · #13 国防部长委员会 |
| `mil_command_max` | `max_command_power` | 同上（北欧给 **25**） | #2 联合司令部 · #13 国防部长委员会 |
| `mil_war_support` | `war_support_factor` | 条约 / 政协 / 裁军 / 全欧会议 | #1 条约 · #4 政治协商委员会 · #15 MBFR · #16 全欧会议 |
| `mil_conscription` | `conscription_factor` | 条约义务 / 一体化 / 军官培养 | #1 条约 · #6 一体化部队 · #11 军官培养 |
| `mil_manpower` | `weekly_manpower` | 同上（北欧给 **250**） | #6 一体化部队 · #11 军官培养 |
| `mil_production` | `production_speed_arms_factory_factor` | 制式统一 / 许可生产 | #7 统一制式 · #12 许可生产 |
| `mil_training` | `training_time_factor`（**负**） | 演习 / 军官培养（北欧给 −0.15） | #9 联合演习 · #11 军官培养 |
| `mil_equip_xp` | `land_equipment_upgrade_xp_cost`（**负**） | 制式统一 ⇒ 改装备便宜 | #7 统一制式 · #12 许可生产 |
| `mil_aa` | `static_anti_air_damage_factor` | ⭐ **统一防空系统** | #8 统一防空 |
| `mil_air_dmg` | `industry_air_damage_factor`（**负**） | 同上 | #8 统一防空 |
| `mil_fuel` | `army_fuel_capacity_factor` | 一体化部队 / 制式（油料通用） | #6 一体化部队 · #7 统一制式 |

---

## §9 军事线 = **华沙条约组织**（17）

| # | id | 中文显示名 | DM 贡献 | 直接奖励 | 三档 |
| --- | --- | --- | --- | --- | --- |
| 1 | `hof_ma_mil_warsaw_treaty` | 华沙条约组织 | **`mil_defence +0.10`** · `mil_war_support +0.05` · `mil_conscription +0.05` | **`add_ideas = hof_ma_idea_warsaw_treaty`** | 发起方：`add_political_power = 50` |
| 2 | `hof_ma_mil_joint_command` | 联合武装部队司令部 | **`mil_command +0.10`** · **`mil_command_max +25`** · `mil_org +0.05` | **`add_ideas = hof_ma_idea_joint_command`** | 发起方：`add_command_power = 25` |
| 3 | `hof_ma_mil_joint_staff` | 联合武装部队总参谋部 | **`mil_org +0.10`** · **`mil_planning +0.10`** | — | — |
| 4 | `hof_ma_mil_political_consultative` | 政治协商委员会 | **`mil_war_support +0.10`** | `set_country_flag = hof_ma_pcc` | — |
| 5 | `hof_ma_mil_standing_bodies` | 联合秘书处与常设委员会 | `mil_command +0.05` · `mil_org +0.05` | — | — |
| 6 | `hof_ma_mil_integrated_units` | 一体化部队 | `mil_attack +0.05` · `mil_conscription +0.05` · **`mil_manpower +250`** · `mil_fuel +0.10` | — | — |
| 7 | `hof_ma_mil_unified_equipment` | 统一装备制式 | **`mil_supply −0.10`** · **`mil_production +0.10`** · **`mil_equip_xp −0.10`** · `mil_fuel +0.10` | **`add_equipment_to_stockpile = { type = infantry_equipment amount = 2000 }`** | — |
| 8 | `hof_ma_mil_air_defence` | 统一防空系统 | ⭐ **`mil_aa +0.15`** · **`mil_air_dmg −0.15`** · `mil_defence +0.05` | **`capital_scope = { add_building_construction = { type = anti_air_building level = 2 instant_build = yes } }`** | — |
| 9 | `hof_ma_mil_joint_exercises` | 联合演习 | **`mil_org +0.10`** · `mil_planning +0.05` · **`mil_attrition −0.10`** · **`mil_training −0.10`** | **`army_experience = 25`**（北欧同款） | — |
| 10 | `hof_ma_mil_doctrine` | 统一军事学说 | **`mil_attack +0.10`** · `mil_breakthrough +0.05` | **`army_experience = 25`** | — |
| 11 | `hof_ma_mil_officer_training` | 军官培养体系 | `mil_conscription +0.05` · **`mil_manpower +250`** · **`mil_training −0.10`** | **`army_experience = 25`** | — |
| 12 | `hof_ma_mil_licensed_production` | 许可生产与军事技术援助 | **`mil_production +0.15`** · **`mil_equip_xp −0.10`** | **`add_equipment_to_stockpile = { type = fighter amount = 120 }`** | — |
| 13 | `hof_ma_mil_defence_ministers` | 国防部长委员会 | `mil_command +0.05` · **`mil_command_max +25`** · `mil_planning +0.05` | — | — |
| 14 | `hof_ma_mil_committees` | 军事委员会与各专业委员会 | `mil_supply −0.05` · **`mil_supply_cap +0.10`** | — | — |
| 15 | `hof_ma_mil_mbfr` | 维也纳裁军谈判 | `mil_war_support +0.05` | — | 全体：对北约国 `add_opinion` |
| 16 | `hof_ma_mil_csce` | 全欧安全会议（赫尔辛基） | `mil_defence +0.05` · `mil_war_support +0.05` | **`add_ideas = hof_ma_idea_csce`**（信任措施） | — |
| 17 | `hof_ma_mil_nuclear` | 核部署与作战计划 | **`mil_attack +0.15`** · **`mil_defence +0.10`** · `mil_breakthrough +0.05` | **`add_ideas = hof_ma_idea_nuclear_umbrella`** | 发起方：`add_command_power = 50` |

### §9.1 军事线逐变量合计（**实测**）

| 变量 | 合计 | 节点数 | | 变量 | 合计 | 节点数 |
| --- | --- | --- | --- | --- | --- | --- |
| `mil_attack` | **+0.30** | 3 | | `mil_manpower` | **+500** | 2 |
| `mil_defence` | **+0.30** | 4 | | `mil_production` | **+0.25** | 2 |
| `mil_org` | **+0.30** | 4 | | `mil_training` | **−0.20** | 2 |
| `mil_breakthrough` | **+0.10** | 2 | | `mil_equip_xp` | **−0.20** | 2 |
| `mil_planning` | **+0.20** | 3 | | `mil_aa` | **+0.15** | 1 |
| `mil_supply` | **−0.15** | 2 | | `mil_air_dmg` | **−0.15** | 1 |
| `mil_supply_cap` | **+0.10** | 1 | | `mil_fuel` | **+0.20** | 2 |
| `mil_attrition` | **−0.10** | 1 | | | | |
| `mil_command` | **+0.20** | 3 | | | | |
| `mil_command_max` | **+75** | 3 | | | | |
| `mil_war_support` | **+0.25** | 4 | | | | |
| `mil_conscription` | **+0.15** | 3 | | | | |

⚠️ `mil_command_max` 的 3 个节点里**包含头节点**（+25）。

### §9.5 机构 idea 的附加数值（**不进上面三张合计表**）

国策的「直接奖励」那一列里有 14 处 `add_ideas = hof_ma_idea_*`。它们是**可见的民族精神**
（照原版 `NORDIC_command_ns` 那一类），玩家点下去在精神格里多出这一个机构。
数值**刻意小**（+0.05 一档），并且**不并进 §5.1 / §7.1 / §9.1** —— 那三张表统计的是
三个动态民族精神容器里的变量，这里是静态 idea，两者互不覆盖。

| idea | 挂在 | 附加数值 |
| --- | --- | --- |
| `hof_ma_idea_comecon` | 经济 #1 | `production_speed_industrial_complex_factor = 0.05` |
| `hof_ma_idea_division_of_labour` | 经济 #7 | `production_speed_industrial_complex_factor = 0.05` |
| `hof_ma_idea_integration_programme` | 经济 #15 | `production_speed_industrial_complex_factor = 0.05` · `industrial_capacity_dockyard = 0.05` |
| `hof_ma_idea_joint_research_org` | 经济 #21 | `research_speed_factor = 0.05` · `research_sharing_per_country_bonus_factor = 0.05` |
| `hof_ma_idea_cominform` | 政治 #1 | `political_power_factor = 0.05` |
| `hof_ma_idea_cominform_press` | 政治 #2 | `opinion_gain_monthly_factor = 0.05` |
| `hof_ma_idea_wpc` | 政治 #9 | `opinion_gain_monthly_factor = 0.05` |
| `hof_ma_idea_oir` | 政治 #11 | `drift_defence_factor = 0.05` · `compliance_growth_on_our_occupied_states = 0.05` |
| `hof_ma_idea_friendship_societies` | 政治 #13 | `opinion_gain_monthly_factor = 0.05` · `improve_relations_maintain_cost_factor = −0.05` |
| `hof_ma_idea_first_secretaries` | 政治 #17 | `political_power_factor = 0.05` · `stability_factor = 0.05` |
| `hof_ma_idea_warsaw_treaty` | 军事 #1 | `army_defence_factor = 0.05` · `war_support_factor = 0.05` |
| `hof_ma_idea_joint_command` | 军事 #2 | `command_power_gain = 0.05` · `army_org_factor = 0.05` |
| `hof_ma_idea_csce` | 军事 #16 | `war_support_factor = 0.05` · `stability_factor = 0.05` |
| `hof_ma_idea_nuclear_umbrella` | 军事 #17 | `army_attack_factor = 0.05` |

📌 **一处与本文 §5/§7/§9 表格的差异（如实登记）**：政治线 #9「世界和平理事会」
在本文原稿里**没有** idea；实装时给它加了 `hof_ma_idea_wpc` ——
它本来就是「一个组织」，与 #2（机关报）、#14（友好协会）同型，加了才齐。

---

## §10 直接奖励怎么写（第 2 层）

```txt
# ① 资源（落在首都）—— 原版有先例：common/decisions/AFG.txt 的 add_resource = { type=oil amount=10 }
capital_scope = { add_resource = { type = coal  amount = 40 } }   # 联合电网 → 煤（2026-09-21 由 20 改 40）
capital_scope = { add_resource = { type = oil   amount = 40 } }   # 输油管   → 油（同上）
# ⭐（2026-09-21 用户口径）银行 / Intermetall 由「只 +20 钢」改成【每种可获得资源各 +20】：
capital_scope = { add_resource = { type = oil amount = 20 } add_resource = { type = aluminium amount = 20 } add_resource = { type = rubber amount = 20 } add_resource = { type = tungsten amount = 20 } add_resource = { type = steel amount = 20 } add_resource = { type = chromium amount = 20 } add_resource = { type = coal amount = 20 } }

# ② 建筑（落在首都）—— instant_build 才当场看得见
capital_scope = { add_building_construction = { type = industrial_complex  level = 1 instant_build = yes } }   # 投资银行
capital_scope = { add_building_construction = { type = anti_air_building level = 2 instant_build = yes } }   # 统一防空
# 铁路：建筑类型名 = rail_way（原版 common/decisions/SOV.txt 已证实）
capital_scope = { add_building_construction = { type = rail_way level = 1 instant_build = yes } }

# ③ 装备（按许可生产给「现成的一批」）
add_equipment_to_stockpile = { type = infantry_equipment amount = 2000 }
add_equipment_to_stockpile = { type = fighter amount = 120 }

# ④ 一个 idea（「成立某个组织」这类条目的载体）
add_ideas = hof_ma_idea_joint_research_org      # 标准化研究所 → 联合研究组织
add_ideas = hof_ma_idea_warsaw_treaty           # 条约本体
add_ideas = hof_ma_idea_cominform_press         # 机关报

# ⑤ 研究槽 / 经验
add_research_slot = 1        # ⚠️ 效果名待核
army_experience = 25         # 原版北欧这么给的
```

**技术事实（都取自原版实测，不是推测）**

| 写法 | 出处 | 结论 |
| --- | --- | --- |
| `capital_scope = { ... }` | 原版 `common/ai_strategy_plans/ai_faction_theaters.txt` L41 | ✅ 合法作用域 ⇒ 可以「给首都加东西」 |
| `add_resource = { type amount }` | 原版 `common/decisions/AFG.txt` L63 | ✅ |
| `add_building_construction` | 原版 `common/mios/aat_mio_decisions.txt` | ✅ |
| `rail_way`（建筑类型名） | 原版 `common/decisions/SOV.txt` L13450 | ✅ **铁路的建筑名就是 `rail_way`** |
| `country_resource_coal/oil/steel` | 官方 `wiki/Modifiers.txt` L897 | ✅ *"Directly modifies the country's resource stockpile"* |
| `research_sharing_per_country_bonus_factor` | 官方 `wiki/Modifiers.txt` | ✅「科技共享时每国加成」—— 正对「索非亚原则」 |
| `army_experience = 25` | 原版 `nordic_shared.txt` 的 `NORDIC_northern_command` | ✅ |

---

## §11 ✅ 待确认 —— **三项已全部裁决（2026-09-20）**

| # | 问题 | 裁决 | 落地 |
| --- | --- | --- | --- |
| **1** | 要不要补「铁路合作组织」第 24 个节点 | **乙** —— 不补，挂到 #16 长期专项合作纲要 | `hof_ma_eco_long_term_programmes` 的 `Raw` 里加 `capital_scope = { add_building_construction = { type = rail_way level = 1 instant_build = yes } }`；经济线仍是 **23** 条 |
| **2** | `add_research_slot = 1` 这个效果名待核 | **不用核了** —— 用户口径「加研究槽位的删去，不考虑这个给研究速度就行」 | 两处 `add_research_slot` 删除，改成 `research_speed_factor`：索非亚原则 **+0.05**、科技进步综合纲要 **+0.15**（原 0.15 保留，另加 0.05）⇒ `eco_research` **+0.40** |
| **3** | 变量表还要不要再扩 | **甲** —— 就按这 53 个（17 + 17 + 19）落地 | 不再扩表；未进表的（`production_lack_of_resource_penalty_factor` · `fuel_gain_factor` · `min_export` · `justify_war_goal_time` · `decryption_factor` · 海军 / 空军全系）**留给后续的 S6 国别分支**用 |

---

## §12 还没做（本文范围内）

~~① 三个 DM 与 idea 的本地化词条~~ —— ✅ **已做**（`hof_ma_l_simp_chinese.yml`，UTF-8 带 BOM）

~~② 逐节点文案~~ —— ✅ **已做**（**59** 条，见下）

~~③ 图标 sprite 名~~ —— ✅ **已做**（**16** 张：**3 张原版已有**占位 ＋ **13 张本 mod 抠的实物**，零缺图；见 `docs/un-focus/03` / `06`）

~~④ 写进生成器~~ —— ✅ **已做**（`build/gen-hof-ma-common-lines.ps1`）

~~⑤ §11 的三项裁决~~ —— ✅ **已全部裁决**（见 §11）

### ⚠️ 文案档次的如实说明（硬性规则 9）

**59** 条描述**不是本人著作节选**（这条线没有「本人」—— 它写的是三个机构），
用的是**史实陈述 + 逐条出处**：多为中文维基〈经济互助委员会〉〈华沙条约组织〉
〈共产党和工人党情报局〉〈莫洛托夫计划〉条的行文，外加节点自身的**成立日期 / 文件名 / 机构名**。
**没有一条是自撰的评价**，但**也不是一手引文**。

⬜ **可以继续做的**：为「本身就是一份文件」的节点（经互会章程 · 国际社会主义分工基本原则 ·
一体化综合纲要 · 华沙条约 · 情报局三次会议文件 · 赫尔辛基最后文件）**补一手引文**
（引该文件自己的条文原句，标注条号 / 日期 / 出版出处）。这是一轮独立的查证工作。

### 📌 回写状态

本文 → `AGENTS.md`（S5 段）· `docs/99` §47.10 · `docs/un-focus/README.md` · 记忆文件

---

## 附注 · 2026-09-21 · 图标权利口径的一处改判（与数值无关，只作指路）

> 用户口径：「**不对啊，就算有著作权那使用的组织和作者本人都已不存在，而且我们这个是公开免费共享 mod 啊**」

我在 `06` 里给**世界和平理事会**（`hof_ma_pol_wpc`）那张**毕加索《和平鸽》**自己加了一道「著作权未到期 ⇒ 不能用」的门槛
—— ⛔ **那道线是我自己加的，不是用户裁决**。已按用户口径**改判为【用】**。
⚠️ 但**两处事实要纠正**：① 毕加索 **1973-04-08** 去世 ⇒ 著作权到 **~2043 年**，
且 **Succession Picasso / ADAGP 在积极维权**（**不是**「无人主张」那一档）；② **世界和平理事会现在还在**（`wpc-in.org`）。
📌 全文见 `06` **§2.2.3** 与 `99` **§47.22**；出图提示词见 `03` **§2.1 / §4.3 第 10 行**。
