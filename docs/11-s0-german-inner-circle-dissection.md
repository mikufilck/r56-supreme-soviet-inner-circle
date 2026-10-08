# S0 · 德国核心圈实现拆解（只读）

> 目的：搞清楚德国 Inner Circle 到底由哪些文件构成、数据怎么存、生命周期怎么走，作为我们做苏联版核心圈的实现依据。
> 状态：**拆解完成，未写任何代码。**
> 数据来源：`F:\Hearts of Iron IV\`（原版）+ `D:\...\workshop\content\394360\2129897125\`（R56 CN）。

---

## 0. 三条最重要的结论

1. **全部逻辑都在原版 `common/` 与 `interface/` 里，代码不在 DLC 文件夹**（`dlc043_gotterdammerung` 只有 `gfx`/`interface`/`music`/`sound`）。这印证了"DLC 只放美术、逻辑锁在 `has_dlc`"的规律。
2. ⚠️ **R56 覆写了其中 4 个文件**——我们要仿造的对象是 **R56 版**，不是原版。
3. **席位模型 = 变量存"角色序号"**，不是布尔标记。空席 = `0`，有人 = `1..N`。这是整套机制的地基。

---

## 1. 涉及文件清单

| 文件 | 在 R56 中被覆写 | 作用 |
| --- | --- | --- |
| `common/focus_inlay_windows/ger_inner_circle_inlay_window.txt` | ✅ | 窗口内容定义：`window_name = ger_inner_circle_ui_window`、`internal = yes`、`visible` 条件、`scripted_images` 靠变量/领袖判定选图 |
| `common/national_focus/germany.txt` | ✅ | ① 树内声明 `inlay_window = { id = ger_inner_circle_inlay_window  position = {...} }` ② **国策就是席位入口**：`set_variable = { GER_ascended_advisor_N = <序号> }` |
| `common/scripted_effects/GER_scripted_effects.txt` | ✅ | 每个角色一组「施加 / 替换 / 移除」效果；`GER_remove_replaced_advisor_N_effects` 负责换人 |
| `common/scripted_triggers/GER_scripted_triggers.txt` | ✅ | 席位可点条件、冷却判定（如 `GER_inner_circle_is_ascension_cd_over`） |
| `common/on_actions/12_wuw_on_actions.txt` | ❌ | 周期性维护（事件挂起标志、冷却复位等） |
| `common/scripted_localisation/WUW_GER_scripted_loc.txt` | ❌ | 动态文本：当前席位上的角色名 / 特质 |
| `interface/GER_inner_circle_scripted_gui.gui` | ❌ | **窗口本体** |
| `interface/GER_inner_circle_hidden_scripted_gui.gui` | ❌ | 隐藏版窗口 |
| `interface/nationalfocusview.gfx` | ❌ | sprite 注册 |
| `localisation/english/wuw_focus_l_english.yml` | — | 国策与窗口文本键 |
| `localisation/english/wuw_events_l_english.yml` | — | 事件文本键 |

> 📌 设计含义：我们做苏联版时，**要仿造的是这些文件的 R56 版本**；而 `on_actions` / `scripted_localisation` / `interface/*.gui` 这几个 R56 没动，可以对照原版直接改造成我们自己的。

---

## 2. 数据模型

| 对象 | 形态 | 说明 |
| --- | --- | --- |
| 席位变量 | `GER_ascended_advisor_1` / `_2` / `_3` | 值为 `0` = 空席；`1..7` = 具体角色序号 |
| 领袖位 | 不占变量 | 由 `has_country_leader` 判定当前领袖是谁，窗口据此换头像 |
| 角色序号表 | 分散在各 `if/else_if` 里 | 例如 `1` = 托特、`2` = 施佩尔、`3` = 戈林…（顺序即"序号"） |
| 冷却 | `GER_inner_circle_cd_flag` | 配合 `GER_inner_circle_set_ascension_cd = yes` |
| 事件挂起 | `GER_inner_circle_event_pending_flag` | 防止同回合重复触发 |

**关键点：用"变量 + 序号表"而不是布尔，好处是**
- 一个变量同时表达"有没有人"和"是谁"，窗口只需读一个值就能换图；
- 换人只需改一个值；
- 不需要为每个角色各建一个标记。

---

## 3. 生命周期（四步）

**① 入席**（国策 `completion_reward` 内）

```
依次检查 GER_ascended_advisor_1 → _2 → _3 是否为 0
第一个为 0 的槽 → set_variable = { <该槽> = <角色序号> }
```

即**"填第一个空位"**逻辑，所以**席位总数可以任意扩**（我们要 7 席只需加 `_4`~`_7`）。

**② 防重复**：`check_variable = { <槽> = <序号> compare = not_equals }` 用来判断"这人是否已在圈内"，避免重复点。

**③ 换人 / 罢免**（已有现成范例）

`GER_remove_replaced_advisor_N_effects` 的做法是：
1. 用 `check_variable = { GER_ascended_advisor_N = 1..7 }` 逐项匹配当前坐着谁；
2. 命中后调用对应角色的移除效果（`GER_remove_<角色>_effects`）；
3. 兜底 `else` 里 `log = "..."` 输出异常。

→ **这就是 Q25「席位可替换、可罢免」的现成答案**，我们直接照搬结构即可。

**④ 冷却与节奏**

- 国策耗时用 `@` 变量分档：`@inner_circle_time_tier_1/2/3`；
- 配合 `set_temp_variable = { temp_focus_days = @inner_circle_time_tier_N }` 仅为 tooltip 显示用；
- `has_country_flag = GER_inner_circle_cd_flag` + `NOT = {...}` 控制节奏，并有 `tooltip = GER_inner_circle_cd_days_tt` 说明剩余天数。

---

## 4. 国策层面的规格

| 特征 | 值 | 我们的对应做法 |
| --- | --- | --- |
| 席位入口国策 | 每个候选角色一条 | 同 |
| 专属后续国策 | 入席后可点（`check_variable` 判定） | 同（对应 Q19 的"入席后再点自己的国策"） |
| 筛选项 | `FOCUS_FILTER_INNER_CIRCLE` | 需注册我们自己的 `FOCUS_FILTER_HOF_INNER_CIRCLE` |
| 文本图标样式 | `text_icon = GER_inner_circle_focus_style` | 需做 `hof_ic_focus_style`，让核心圈国策在视觉上独立成类 |
| 相关事件 | `GER_inner_circle.01`（替换确认）、`GER_inner_circle_<角色>.00/.01`（角色分支与启动） | 我们需对应的事件命名空间 |
| 角色分支事件 | `country_event = { id = ... days = ... random_days = ... }` 延迟触发 | 同结构 |

### 4.1 ★ 个人线 =「一个职务特质的逐级升级」—— 数值宪法（已实测）

> **数据来源（两份都是脚本跑出来的原文，不是读文档猜的）**
> - `reference/reports/ger-ic-swap-chains.txt` —— 20 条个人线国策的 `swap_ideas` 链
>   （脚本 `reference/tools/dump-ger-ic-swap.ps1`）
> - `reference/reports/ger-ic-idea-tiers.txt` —— 全部职务 idea **每一层**的 modifier 全文
>   （脚本 `reference/tools/dump-ger-ic-idea-tiers.ps1`）

**这是本项目最容易做错的一条。** 把它当成"一条国策挂一个新的民族精神"，就会得到
"17 条个人线国策 = 17 个同时挂着的精神"。德国**不是**这么写的。

#### (1) 结构：全程**只有一个**职务特质，靠 `swap_ideas` 换名字往上升

```text
GER_ascension_of_todt                          （入口，cost=2）
   └─ 挂 GER_todt_reich_engineer               ← 「帝国工程师」
GER_form_organization_todt                     （tier_1）
   └─ 挂 GER_organization_todt                 ← 这是【另一个人】（霍尔茨曼）的特质
GER_autonomous_organization_todt               （tier_2）
   └─ swap_ideas: GER_todt_reich_engineer → GER_todt_reich_minister_of_armaments
   └─ swap_ideas: GER_organization_todt   → GER_organization_todt_improved
```

实测 7 条链，**名字跟着"升迁"变**：

| 人物 | 入口特质 | 第一级升级 | 第二级升级 |
| --- | --- | --- | --- |
| 托特 | 帝国工程师 | 帝国军备部长 | — |
| 施佩尔 | 帝国建筑师 | 帝国军备部长 | — |
| 戈林 | 四年计划总监 | 四年计划全权代表 | — |
| 希姆莱 | 德国警察总监 | 帝国安全局局长 | 党卫队全国领袖 |
| 戈培尔 | 帝国宣传部长 | 宣传部（部务） | 宣传大师 |
| 赫斯 | 党务总理 | 党务总理（进阶） | 平起平坐者之首 |
| 鲍曼 | 元首秘书 | 元首秘书（进阶） | 幕后褐衣权臣 |

> 📌 **"跟顾问有点像"就体现在这里**：一个槽、一个职务、一个名字，只是官越做越大。
> 不是往身上叠 buff。

#### (2) 每一层 =「上一层全部照抄 + 追加 2~4 条」，**不是替换**

`GER_himmler_*` 三层原文对照（逐字核对过）：

| 词条 | 警察总监 | 帝国安全局长 | 党卫队全国领袖 |
| --- | --- | --- | --- |
| `political_power_gain` | −0.10 | −0.30 | −0.30 |
| `resistance_damage_to_garrison` | −0.25 | −0.25 | −0.25 |
| `foreign_subversive_activites` | −0.30 | −0.30 | −0.30 |
| `non_core_manpower` | 0.02 | 0.02 | **0.04** |
| `subversive_activites_upkeep` | — | −0.25 | −0.25 |
| `operative_slot` | — | 1 | 1 |
| `intelligence_agency_defense` | — | 0.20 | 0.20 |
| `intel_from_combat_factor` | — | 0.25 | 0.25 |
| `resistance_growth` | — | — | −0.15 |
| `compliance_growth` | — | — | −0.10 |
| `special_forces_cap` | — | — | 0.05 |

→ 高层是低层的**严格超集**，只在少数词条上"抬数值"（`non_core_manpower 0.02→0.04`）。

#### (3) 数值尺度 —— **这就是"个人特质"和"国策"的分界线**

| 项 | 职务特质（`common/ideas/`） | 国策（`completion_reward`） |
| --- | --- | --- |
| 单条修正幅度 | **2% ~ 30%，绝大多数 5%** | 同左，但可叠加多条 |
| 条数 | 每层 2 ~ 5 条 | — |
| 政治点 | **只以 `political_power_gain` 出现**：入口 −0.10，二级起 −0.30 | `add_political_power = 50 ~ 100` |
| 建筑 | **从不出现** | `add_extra_state_shared_building_slots` + `add_building_construction`（instant_build） |
| 科技 | **从不出现** | `add_tech_bonus` |
| 变量 | **从不出现** | `add_to_variable` 喂给动态修正 |
| 解锁 | **从不出现** | `unlock_decision_tooltip` 等 |

反例验证：`GER_prioritize_the_four_year_plan` 给 `add_dynamic_modifier`×3；
`GER_wunderwaffe` 只给两个 `add_to_variable`。**这些一次性/解锁收益全在国策里，一条没进 idea。**

#### (4) 四条可直接照抄的规则

1. **政治点符号本身是设计**：管业务的人 **−0.10 → −0.30**（官越大越吃政治点）；
   替领袖办党务的人 **+0.15 → +0.4**（赫斯/鲍曼，他们是**产**政治点的）。
2. **特质只放长期、被动、可累加的**词条（组织度、生产效率、抵抗、情报、人力）；
   **一次性收益一律留给国策**。
3. 每层 `allowed = { always = no }` + `removal_cost = -1`（只能由国策给出，不可手动移除）。
4. **层级 2~3 层就够**，别为了"内容多"硬堆。

#### (5) 我们踩过的错（留证）

| ❌ 错法 | 后果 |
| --- | --- |
| 每条个人线国策 `add_ideas` 一个新 idea | 会同时挂 N 个精神，且**互相独立地叠** |
| idea 里写 `research_speed_factor`、`political_power_factor` | 那是国策味，不是职务味 |
| 17 条国策各给 `add_political_power = 25~50` | 单条线累计 500+ 政治点 |
| idea 名用泛称（「最高苏维埃委员」） | 看不出职务，也做不出"升迁"的叙事 |

| ✅ 正解 |
| --- |
| **职务 idea 承担官衔及个人线持续数值；晋升或完成个人国策时换成包含既有奖励的新版本。**现行苏联实现见 `docs/99` §73。 |

### 4.2 ★★ 个人线怎么让他变强（早期动态修正方案，现已由静态职务版本替代）

> **这是本文件最重要的一条，也是我栽得最狠的一处。**
> 第一版把个人线国策写成了"发一次性奖励"（政治点 / 工厂 / 科技加成）——
> 那只回答了"这条国策给**国家**什么"，**没回答"这条国策让这个人强了多少"**。
> **个人线存在的意义就是后者：点一条，他身上那件东西就更强一分。**

**R56 的现成写法**（`common/dynamic_modifiers/0_dynamic_modifiers.txt`，原文逐字核对）：

```text
SOV_defense_industry_dynamic_modifier = {
	enable = { always = yes }
	#INITIAL
	conversion_cost_civ_to_mil_factor = SOV_defense_industry_conversion_cost_civ_to_mil_factor
	#FUTURE
	tank_manufacturer_cost_factor = SOV_defense_industry_tank_manufacturer_cost_factor  #-0.25 -> Tank Designer focus
	land_equipment_upgrade_xp_cost = SOV_defense_industry_land_equipment_upgrade_xp_cost #-0.1  -> Tankograd
	breakthrough_factor = SOV_defense_industry_breakthrough_factor                       #0.05  -> PC of Mortar Armament
	max_dig_in_factor = SOV_defense_industry_max_dig_in_factor                           #0.05  -> Military Engineering University
}
```

**修正项的值直接写成变量名**；国策里 `add_to_variable` 往那个变量加值。
`SOV_the_politburo_good_dynamic_modifier` 有 **18 条**这样的修正，**每条都注着是哪个国策给的**；
`SOV_the_red_fleet_dynamic_modifier` 同型（10 条）。

**为什么必须是 dynamic_modifier**：idea 的 `modifier` 是**静态的、读不了变量**；
只有 `dynamic_modifier` 的值可以写成变量名。于是两个载体分工明确：

| 载体 | 回答什么 | 能随国策成长吗 |
| --- | --- | --- |
| 职务 idea | **他是谁**（官衔名 + 入圈代价） | 能换名（`swap_ideas`），但**数值写死** |
| 个人 dynamic_modifier | **他能干什么**（全部数值） | ✅ 能，靠 `add_to_variable` |

**写法**：

```text
# 动态修正一侧
hof_ic_<key>_dm = {
	enable = { hof_ic_seated_<key> = yes }
	army_attack_factor = hof_ic_<key>_army_attack      # 值 = 变量名
}

# 国策一侧（每条个人线国策就这两行）
completion_reward = {
	add_to_variable = { hof_ic_<key>_army_attack = 0.05 }
}
```

**词条不许臆造**：68 个候选词条已逐个扫过 R56 + 原版，结果在
`reference/reports/military-modifier-words.txt`（✅ / ❌ 都有标注）。
例：`army_attack_factor`、`supply_consumption_factor`、`out_of_supply_factor`、`attrition`、`breakthrough_factor` **可用**；
`division_attack_factor`、`army_logistics_factor`、`army_sub_unit_*`、`general_cost_factor` **不存在，别写**。

**度量级**：单条个人线国策 ≈ **0.05**；**汇合层 ≈ 0.10 或以上**。
参照 R56：`SOV_the_politburo_good_dynamic_modifier` 几乎全 0.05，
`SOV_defense_industry_dynamic_modifier` 有 0.05 / 0.10 / 0.25 三档。

**个人线国策不要给的东西**：政治点、工厂、一次性科技加成 —— 那些是"国策奖励"的语法，
属于别条线；个人线的产出是**这个人本身变强**。

#### 4.2.0 ★★★ 德国的真实实现（2026-09-15 原文核对）—— **官衔在 idea 上，不在 DM 上**

> 🚨 **本节修正 §4.2 的偏向。** 原文核对后确认：德国的个人线是**三件套分工**，
> 职务**官衔名走 `idea` + `swap_ideas`**，`dynamic_modifier` 只管"额外的累积数值"。
> 原始证据：`reference/reports/ger-ic-raw.txt`、`ger-ic-removal.txt`。

| 部件 | 管什么 | 证据 |
| --- | --- | --- |
| **职务 idea**（每人 2~3 级）—— 在 **`hidden_ideas`** 里 | **官衔名 + 招牌数值** | `common/ideas/GER.txt` L11339 是 `hidden_ideas = {`，L11350 托特、L11476 希姆莱 |
| **辅助 dynamic_modifier** | 个人线国策累积的**额外**数值 | `add_to_variable` + `GER_wunderwaffen` / `GER_military_intelligence_service` / `GER_four_year_plan_initiative_modifier` |
| **容器 DM** `GER_the_inner_circle_dm`（中文名就是「**核心集团**」） | **唯一一个可见民族精神**；**一条数值都没有** | `wuw_dynamic_modifiers.txt` L941 |

> 🚨🚨 **最大的一个误解：德国职务 idea 在 `hidden_ideas` 里，不显示为民族精神。**
> `hidden_ideas` 是原版定义的真实 category（`common/idea_tags/00_idea.txt` L8）：
> `hidden = yes` / `cost = 0` / `removal_cost = -1` / `ledger = hidden`。
> → **满席不会多出一堆精神格**；玩家的信息来源是：
> ① 容器精神的 tooltip，② 核心圈窗口里的席位名牌 / 特质框。
>
> 🚨 **`common/ideas/` 下的文件外层必须是 `ideas = { <category> = { ... } }`。**
> 把 idea 块直接写在文件根级 = **静默不注册**（游戏不报错，但 idea 根本不存在）。
> `verify-s2.ps1` §11.0b 已加专项检查（要求 `ideas` / `hidden_ideas` / 裸块 = 1 / 1 / 0）。

**中国名怎么来的：容器精神的 tooltip 用脚本本地化列出席位**

```text
GER_the_inner_circle_dm 的 custom_modifier_tooltip = GER_the_inner_circle_dm_tt
```
```text
wuw_ideas_l_simp_chinese.yml L354:
GER_the_inner_circle_dm_tt: "现任§Y核心集团§!顾问：\n[GetAscendedAdvisor1][GetAscendedAdvisor2][GetAscendedAdvisor3]"
```

而 `GetAscendedAdvisorN` 是 `defined_text`（`common/scripted_localisation/WUW_GER_scripted_loc.txt`），
**读槽位变量 + `has_idea` 反推当前官衔**：

```text
defined_text = {
	name = GetAscendedAdvisorDesc1
	text = { trigger = { check_variable = { GER_ascended_advisor_1 = 0 } } localization_key = empty_key }
	text = { trigger = { check_variable = { GER_ascended_advisor_1 = 1 }
	                     has_idea = GER_todt_reich_minister_of_armaments }
	         localization_key = idea_desc|GER_todt_reich_minister_of_armaments }
	text = { trigger = { check_variable = { GER_ascended_advisor_1 = 1 }
	                     has_idea = GER_todt_reich_engineer }
	         localization_key = idea_desc|GER_todt_reich_engineer }
	...
}
```

> 💡 **三个关键点**：
> 1. **槽位变量** `GER_ascended_advisor_1..3`：0 = 空，1 = 托特，2 = 施佩尔…（德国核心圈是 **3 席**）
> 2. **`has_idea = <等级 id>`** 判断这个人当前是第几级 —— **同样不存状态**
> 3. **`idea_desc|<idea id>`** 是官方的 loc 引用写法，把隐藏 idea 的描述搬进 tooltip
>    （`wuw_dynamic_modifiers.txt` 里还留了一行注释掉的 `#custom_modifier_tooltip = idea_desc|GER_todt_reich_engineer`）
> → 所以**官衔名根本不需要换 DM id**：它是 `defined_text` 动态求值的。

**① 职务 idea：数值全部硬编码，上级 = 下级照抄 + 追加**
**（且它们住在 `hidden_ideas` 里，不占精神格）**

```text
GER_todt_reich_engineer = {                 # T1
	allowed = { always = no }
	removal_cost = -1
	modifier = {
		political_power_gain = -0.1
		production_speed_industrial_complex_factor = 0.1
		production_speed_infrastructure_factor = 0.1
		production_speed_rail_way_factor = 0.1
	}
}

GER_todt_reich_minister_of_armaments = {    # T2 —— 上面 3 条一字不改照抄，再加 2 条
	allowed = { always = no }
	removal_cost = -1
	modifier = {
		political_power_gain = -0.3          # ← 官越大越吃政治点
		production_speed_industrial_complex_factor = 0.1
		production_speed_infrastructure_factor = 0.1
		production_speed_rail_way_factor = 0.1
		production_speed_arms_factory_factor = 0.1     # 新增
		production_speed_dockyard_factor = 0.1         # 新增
	}
}
```

希姆莱同规律：**3 条 → 7 条 → 10 条**（`GER_himmler_chief_of_german_police` →
`GER_himmler_director_reich_security` → `GER_himmler_reichsfuhrer_ss`），
`political_power_gain` 恒为 `-0.1 → -0.3 → -0.3`。
**全程没有变量、没有 dynamic_modifier。**

**② 升级 = `swap_ideas`，写在国策的 `completion_reward` 里**

```text
completion_reward = {
	custom_effect_tooltip = {
		localization_key = GER_ascended_character_trait_swap_tt
		CHARACTER = GER_fritz_todt
	}
	swap_ideas = {
		remove_idea = GER_todt_reich_engineer
		add_idea = GER_todt_reich_minister_of_armaments
	}
}
```

**③ 换人 / 卸任 = scripted effect，用 `has_completed_focus` 反推该给哪一级** ← **最关键的一手**

德国**不记"他升到第几级"**，每次重新判断：

```text
GER_add_himmler_effects = {
	if      = { limit = { has_completed_focus = GER_strengthen_the_waffen_ss } add_ideas = GER_himmler_reichsfuhrer_ss }
	else_if = { limit = { OR = { has_completed_focus = GER_expand_ss_security_duties
	                             has_completed_focus = GER_absorb_the_abwehr } }
	            add_ideas = GER_himmler_director_reich_security }
	else_if = { limit = { has_completed_focus = GER_ascension_of_himmler } add_ideas = GER_himmler_chief_of_german_police }
}

GER_remove_himmler_effects = {
	if      = { limit = { has_idea = GER_himmler_reichsfuhrer_ss }        remove_ideas = GER_himmler_reichsfuhrer_ss }
	else_if = { limit = { has_idea = GER_himmler_director_reich_security } remove_ideas = GER_himmler_director_reich_security }
	else_if = { limit = { has_idea = GER_himmler_chief_of_german_police }  remove_ideas = GER_himmler_chief_of_german_police }
}
```

> 💡 **所以"残留"根本不是问题** —— 国策完成状态是游戏自己记着的，永远准确。
> 我之前担心的"不知道他升到第几级"，德国用 `has_completed_focus` 一句话解决了。
> 位置：`common/scripted_effects/GER_scripted_effects.txt` L2857 / L3102 起。

**④ 额外的累积数值才用 `add_to_variable` + 辅助 DM（注意 `tooltip =` 参数）**

```text
GER_add_or_modify_wunderwaffen = yes
add_to_variable = {
	GER_wunderwaffen_special_project_speed_factor = 0.05
	tooltip = special_project_speed_factor_tt
}
```

辅助 DM 的值写成变量名（与 §4.2 说的一致）：

```text
GER_communist_intel_modifier = {
	enable = { always = yes }
	icon = GFX_idea_generic_spy_intel
	drift_defence_factor = GER_communist_intel_drift_defence_factor
	communism_drift = GER_communist_intel_communism_drift
	...
}
```

**⑤ 结论：对我们的启示**

| 别做 | 该做 |
| --- | --- |
| ❌ 把官衔名塞进 dynamic_modifier | ✅ 官衔名 = **职务 idea**，`swap_ideas` 升级 |
| ❌ 为改名字准备 4 个近似 DM id | ✅ 4 个近似 **idea** id（德国本来就 3 个） |
| ❌ 存"他升到第几级"的变量 | ✅ 用 `has_completed_focus` 反推 |
| ✅ 个人线国策的**累积**数值 | ✅ 在当前职务 idea 的静态版本中累计；`add_to_variable` 仅保留国策数值提示的账本 |

→ **2026-09-26 修订**：这里的奇迹武器和情报动态修正是德国的其他系统，不能据此断言德国核心圈也拆分职务与个人累计值。苏联现按用户裁决，将个人线累计数值并入静态职务 idea 的各状态版本；生成方法与旧档迁移见 `docs/99` §73。下文动态修正示例保留作早期方案记录。

#### 4.2.1 「官衔显示名」这一层：DM 的名字改不了，只能换 id（2026-09 实测）

> ⚠️ **本节结论仍然成立，但用途变了。** 官衔名走 idea（见 §4.2.0），
> 所以"换 DM id 改名字"这条路**不需要了**。本节的价值在于：
> 如果将来真要把某个 DM 的名字随进度变，得知道它做不到。

| 问题 | 结论 | 证据 |
| --- | --- | --- |
| DM 的数值能靠变量改吗？ | ✅ **能，而且完全不用 remove/add** | `force_update_dynamic_modifier` 文档原话：*"updates the modifiers in current scope（use if you don't want to wait for **daily update**）"* → 数值本来就**每天自动重算** |
| 同一个 DM 重复 `add` 会叠成两层吗？ | ❌ 不会 | `add_dynamic_modifier` 文档：*"**Updates the cooldown if exists**"* |
| DM 有 `name` 字段吗？ | ❌ **没有** | 游戏 41 个 DM 文件里 `name =` **0 处**；字段频次表里也没这个键 |
| 能用 scripted localisation 让名字动态化吗？ | ❌ **不采用** | 2024 个 `defined_text` 与 13382 个 idea id **交集为 0**，游戏里无任何先例 |
| 有条件移除的触发器吗？ | ✅ `has_dynamic_modifier = { modifier = X }` | 原版 + R56 共 **3400+** 处 |

→ **结论**：DM 的显示名 = **DM id 对应的本地化键**，静态。
想改官衔名，**只能换 DM id**；但**换 id 跟数值毫无关系**，数值一直躺在变量里。

→ 为避免"席位被顶掉时残留一个精神"，移除**必须**写成条件块（4 个等级 id 各一段）：

```text
if = {
    limit = { has_dynamic_modifier = { modifier = hof_ic_<key>_dm } }
    remove_dynamic_modifier = { modifier = hof_ic_<key>_dm }
}
```

→ 落地方案（每人 4 个等级 id，**同一时刻只挂 1 个，满席仍是 7 格**）：见 `docs/22` §8.2.1。

### 4.3 ★ 席位互斥（政见对立的人不能同席）

**名单与规则：见 `docs/10` §2.4.2（唯一权威出处，本节不重复）。**

**实现方式 —— 写进入口国策的 `available`，不用 `mutually_exclusive`**：

```text
focus = {
    id = hof_ic_seat_<key>
    available = {
        hof_ic_is_appointment_cd_over = yes
        NOT = { hof_ic_seated_<key> = yes }
        NOT = { hof_ic_seated_<对头> = yes }    # ← 按 docs/10 §2.4.2 展开
    }
}
```

**为什么不用 `mutually_exclusive`**（`docs/10` §2.4.1 已定）：

| | 席位条件（本方案） | `mutually_exclusive` |
| --- | --- | --- |
| 可逆性 | **可逆** —— 对头被替换出局后自动重新打开 | **永久** —— 点错一次无法挽回 |
| 语义 | 表达"同一议事机构里坐不下" | 表达"两条路线只能选一条" |
| 用于席位竞争 | ✅ 本方案 | ❌ 明禁 |

**生成侧**：`build/gen-hof-ic-s3.ps1` 顶部的 `$camps` / `$crossRules` / `$pairRules`。
只对**同时在花名册里**的两人生成条件 → **候选池扩员时自动生效**，逻辑不用改。
自检项：`席位互斥条件` / `互斥对称性` / `关键互斥：托洛茨基 ↔ 布哈林` /
`关键不互斥：布哈林 ↔ 加米涅夫`。

⚠️ **候选池未扩员前的临时状态**：花名册只有 7 人（全是反对派），
互斥展开后**最多只能同席 3 人**。按 `docs/10` §2.4.2.1 的分批扩员计划补齐批 2–4 后消失。

---

### 4.4 ★★ 本地化：tooltip 的写法（2026-09-15 实拍比对后照抄）

**起因**：我们的国策 tooltip 在游戏里是「`效果:` 底下一串**光秃秃的数字**」，
玩家分不清那是国策奖励还是“他身上那件东西变强了”。德国那边每一堆数字**都有抬头**。

#### (1) 三段式：抬头 → 摊开 → 说明

德国入口国策（`common/national_focus/germany.txt` L18340 起）的 reward：

```text
custom_effect_tooltip = { localization_key = GER_ascension_of_character_tt  CHARACTER = GER_fritz_todt }
show_ideas_tooltip = GER_todt_reich_engineer
custom_effect_tooltip = generic_skip_one_line_tt
custom_effect_tooltip = { localization_key = GER_ascension_of_character_focus_tt  CHARACTER = GER_fritz_todt }
```

游戏里长这样：

```text
弗里茨·托特被任命为全国领导，并在核心集团中晋升为:      ← 抬头
国家工程师，其效果为                                    ← show_ideas_tooltip 摊开的 idea 名
每日政治点数获取: -0.10
基础设施建设速度: +10.00%

弗里茨·托特将开始随着时间的推移处理他分支中的国策。      ← 第二句说明
```

| 指令 | 作用 |
| --- | --- |
| `custom_effect_tooltip = { localization_key = K  ARG = 值 }` | **具名参数**本地化。`$CHARACTER$` 填角色对象 → 取自角色名 loc 键 |
| `show_ideas_tooltip = <idea id>` | 引擎摊开该 idea：**名字 + 它的全部词条与数值**（**`hidden_ideas` 里的也能用**） |
| `custom_effect_tooltip = generic_skip_one_line_tt` | 空行分隔（vanilla `wuw_focus_l_english.yml:119`，值就是 `" \n"`） |

#### (2) 升官衔 / 换特质：抬头 +「以新取代旧」+「效果变化:」

```text
custom_effect_tooltip = { localization_key = GER_ascended_character_trait_swap_tt  CHARACTER = GER_fritz_todt }
swap_ideas = { remove_idea = GER_todt_reich_engineer  add_idea = GER_todt_reich_minister_of_armaments }
```

游戏里：

```text
弗里茨·托特在核心集团中崛起:
以国家军备部长取代国家工程师          ← swap_ideas 的引擎渲染
效果变化:                              ← 新 idea 的词条差值
每日政治点数获取: -0.20
军用工厂建设速度: +10.00%
```

> 📌 另有 `GER_wunderwaffe_dornberger_trait_tt`：**整段手写**（`§Y人名§! (...): ... Effective change:`
> + 逐行 `标签: §G值§!`）—— 数值要写死时照它。
> ⚠️「**X 追加效果：**」那个抬头**不是**手写键，而是 `swap_ideas` 换到的 **idea 自己的名字**。

#### (3) `available` 里的脚本触发器必须包 `custom_trigger_tooltip`

```text
custom_trigger_tooltip = { tooltip = GER_inner_circle_cd_days_tt  NOT = { has_country_flag = GER_inner_circle_cd_flag } }
```

不包 → 玩家在「需要」列表里看到的是 **原始脚本名**（如 `hof_ic_is_appointment_cd_over`）。
冷却剩余天数用 `[?<flag>:days_left|Y0]`（flag 必须是 `set_country_flag = { days = N }` 设的）。

#### (4) 其它照抄项

- `search_filters = { FOCUS_FILTER_INNER_CIRCLE FOCUS_FILTER_INDUSTRY }` → tooltip 末尾的「筛选器: …」
- `cancel_if_invalid = no` / `continue_if_invalid = no` + `custom_override_tooltip` → 显示「❌ 该国策只能由 X …」
- ⚠️ **不能改用 `mutually_exclusive`** 去白拿那行「与下列国策互斥」的文案 ——
  见 §4.3：我们要**可逆**，德国那条是**永久**的。只能 `custom_trigger_tooltip` 逐条写。

#### (5) 我们的落地（`build/gen-hof-ic-s3.ps1`）

| 位置 | 写法 |
| --- | --- |
| 入口国策 `hof_ic_seat_*` | `custom_effect_tooltip = hof_ic_seat_ascension_<key>_tt` → `show_ideas_tooltip = <该人 idea>` → 空行 → `hof_ic_seat_note_tt` |
| 入口国策 `available` | 冷却与每条互斥各包一层 `custom_trigger_tooltip`（键 `hof_ic_appointment_cd_tt` / `hof_ic_not_seated_<key>_tt`） |
| 升官衔国策（3 条 `Sync`） | `hof_ic_rank_up_lev_trotsky_tt` + `show_ideas_tooltip = <目标官衔>`（目标官衔从 `RankGates` 反查得出） |
| 个人线累积数值 | `hof_ic_trotsky_extra_effects_tt`（「§Y托洛茨基的个人威望§!追加效果：」），见 §4.2 |

> ✅ **2026-09-16 更新：我们现在就用 `CHARACTER = <角色 id>` 这套**（与德国一致）。
> 本节上面那行「没用 CHARACTER」是旧结论，已作废：
> ① 7 个席位里 6 人原版/R56 本来就有角色对象，只有谢列布里亚科夫没有
> ② 我们已按 `docs/10` L294 / `docs/17` L120 的既定方案**给他自建了一个**
> （`common/characters/hof_ic_characters.txt`，生成器 §7b）→ 现在 7 人齐了
> ③ 所以 7 人统一走共享键 + `CHARACTER = SOV_<key>`（人名由角色自己的 `name` 键提供）
> —— 详见 `docs/reference/portrait-registry.md`「角色对象」节。

---

### 4.5 ★★ 「抉择」（二选一）怎么写 —— 希姆莱蓝本

> 2026-09-16 读通。出处：`common/national_focus/germany.txt` L19714 / L19755 / L19887、
> `events/WUW_Germany.txt` L23960（简体中文文案在 `localisation/simp_chinese/WUW_events_l_simp_chinese.yml`）。

**先说不是什么**：❌ 不是国策树上两个互斥国策让玩家点；❌ 也不是独立循环检测；
❌ 更不是把国策 `available` 写成 `always = no` 再靠事件去完成。

**它是四件套**：

| # | 环节 | 德国的写法 |
| --- | --- | --- |
| 1 | **触发点** | 入口国策 `GER_ascension_of_himmler` 的 `completion_reward` 里（只在「有空位、直接入席」的 `else` 分支）`country_event = GER_inner_circle_himmler.00` |
| 2 | **抉择事件 `.00`** | `fire_only_once` + `is_triggered_only` 的**可见事件**；`immediate` 设 `GER_inner_circle_event_pending_flag`（防重入）；**两个选项**各带 `custom_effect_tooltip`，选项体内是 `hidden_effect` |
| 3 | **选项干什么** | 只做三件事：`GER_heinrich_himmler = { set_character_flag = <标记> }` → 延迟触发驱动器 `.01` → 清 pending flag |
| 4 | **驱动器读标记** | `.01` 里 `if/else_if` 按 `has_character_flag` 分叉成两条链，每条链内部**才是**「挑第一个未完成的」；两条链末端**汇合到同一条国策** |

```text
# .00 的选项（节选）
option = { #SS
    name = GER_inner_circle_himmler.00.a
    custom_effect_tooltip = GER_inner_circle_himmler_ss_tt
    hidden_effect = {
        GER_heinrich_himmler = { set_character_flag = GER_himmler_ss_focus_flag }
        country_event = { id = GER_inner_circle_himmler.01 days = ... random_days = ... }
        clr_country_flag = GER_inner_circle_event_pending_flag
    }
}

# .01 读标记分叉
if = { limit = { GER_heinrich_himmler = { has_character_flag = GER_himmler_ss_focus_flag } }
       ... 推 SS 链 ... }
else_if = { limit = { GER_heinrich_himmler = { has_character_flag = GER_himmler_gestapo_focus_flag } }
       ... 推 盖世太保 链 ... }
```

**三个容易看漏的点**：

1. **门控（几选几）写在【事件的触发条件】里，不写进国策 `available`** ——
   德国那两个一级国策的 `available` 里**只有** `custom_override_tooltip`（显示用）。
2. **两个国策仍然写 `mutually_exclusive`** —— 它是**手动点选的保险**，不是主机制。
3. **文案文风**（我们照拄）：
   - `.t` = 短名词短语（「希姆莱的职责」）
   - `.desc` = 三段式：【现状】→【限制：只能选一个】→【问题是，应该选哪个？】
   - `.a/.b` = 玩家口吻的短句（「武装党卫军是我们的优先部队」）
   - 选项 tooltip 是**共享键**：`§Y$CHARACTER$§!很快会开始致力于研究国策§Y$FOCUS$§!。`

**我们的映射**（托洛茨基，见 `docs/18` §10.2）：

| 德国 | 我们 |
| --- | --- |
| 触发点 = 完成入口国策 | **触发点 = 支线走通 3 条**（驱动器 `.1111` 里查 `count_triggers`）—— 按本项目的原设计 |
| `GER_heinrich_himmler` | `SOV_lev_trotsky` |
| `GER_himmler_ss_focus_flag` / `_gestapo_focus_flag` | `hof_ic_trotsky_ending_revolution_flag` / `_state_flag` |
| 两条链末端汇合 | 两个终局本身互为 `mutually_exclusive` |
| 事件 `GER_inner_circle_himmler.00` | `heartofiron.1050` |
| 共享 tooltip `GER_inner_circle_himmler_ss_tt` | `hof_ic_ending_choice_tt` |

> 🚩 **实现坑**：终局那两段 `else_if` 在驱动器 `.1111` 里**必须排在 `else` 兜底之前** ——
> 一个 `if` 链里 `else` 之后不能再有 `else_if`。

---

### 4.6 ★★ 入口国策的「描述」文风 —— 逐人写，不许用模板句

> 2026-09-16 用户实拍对照后指出。德国原文见 `localisation/simp_chinese/WUW_focus_l_simp_chinese.yml`
> 的 `GER_ascension_of_<人>_desc`（共 5 人：托特 / 施佩尔 / 戈林 / 希姆莱 / 戈培尔）。

**德国的三段式**（每一段都有具体功能，不是随便凑的）：

| 段 | 作用 | 例子 |
| --- | --- | --- |
| ① | **先立一句一般判断**（把「这类人」的价值说出来） | 「一位优秀的指挥官在元首的核心集团中占有一席之地。」<br>「元首的核心集团始终欢迎那些能够帮助他维持民众支持的人。」 |
| ② | **交代本人资质**（多以「作为一名…的…，」起） | 「作为一名受过训练的建筑师，阿尔伯特·斯佩尔……」<br>「作为一名拥有军事经验的优秀工程师，弗里茨·托德已经证明自己是元首的得力顾问。」 |
| ③ | **给不给他「相对的行动自由」的收益 / 风险评估** | 「若是给予他相对的行动自由，我们一方面将受益于他的专业技能，另一方面还能与[ROOT.GetAdjective]建筑行业的大佬构筑良好关系。」<br>「给予他一定的行动自由，风险不大而收益却很可观。」 |

**五个可复用的手艺点**：

1. 🚩 **每人一句，逐人写** —— 德国 5 条没有一句是重复的模板。
2. 🚩 **话术是固定的**：「给予他**相对的行动自由**」/「**风险不大而收益却很可观**」——
   照抄这几句，观感立刻就对。
3. 🚩 **可以用 `[ROOT.GetNameDef]` / `[ROOT.GetAdjective]`** 让文案贴合玩家国家
   （托特那条：「我们相信他能对`[ROOT.GetNameDef]`发挥很大作用」）。
4. 🚩 **描述里【不写机制】。** 「席位共七个；满了会替换」这种规则说明**不属于描述**——
   德国把它放在 `available` 的条件 tooltip 里（`GER_event_to_replace_ascended_advisor_tt`）。
5. 🚩 **描述是【在朝者的评估口吻】**（「我们相信」「对我们来说将是非常有利的」），
   不是第三人称百科腔。

**我们踩过的错**：7 条描述是同一个模板句，只换了人名，而且只讲席位机制 ——
既没有人物色彩，又占了本该放叙事的位。2026-09-16 已逐人重写（数据源 =
`gen-hof-ic-s3.ps1` 花名册里的 `SeatDesc` 字段；缺一个生成器就 `throw`）。

---

## 5. 界面层面

**窗口**：`containerWindowType`，`name = "ger_inner_circle_ui_window"`，尺寸 **600 × 550**，`orientation = lower_left`。

子组件（`scripted_images` 的键必须与这些子组件名对应）：

| 子组件名 | 类型 | 用途 |
| --- | --- | --- |
| `background` | background | 主背景（`GFX_inner_circle_decor_bg`） |
| `background_spotlight` | background | 聚光叠加（`GFX_spotlight_overlay`） |
| `inner_circle_title_name` | instantTextBox | 标题（`hoi_36header`） |
| `fuhrer_container` → `fuhrer_portrait_container` | container | 领袖位容器 |
| `fuhrer_portrait` | icon | 领袖头像（`GFX_inner_circle_leader_*`） |
| `fuhrer_frame` | icon | 圆形头像框（`GFX_circular_frame_fuhrer`） |
| `fuhrer_name_box` / `fuhrer_name` | icon / instantTextBox | 名牌缎带 + 名字 |
| 顾问容器族 | container | 由 `@ASCENDED_ADVISOR_CONTAINER_POS_Y`、`@…_WIDTH/HEIGHT`、`@ADVISOR_CONTAINER_POS_Y` 等 `@` 变量参数化 |

**已观察到的写法技巧**：

- 文件顶部用 `@变量名 = 值` 集中定义坐标与尺寸 → 改布局只动几行，**可维护性高**（正好符合你 Q24 的要求，我们会沿用这个习惯）。
- `context_aware_tooltip = GER_fuhrer_tooltip` 做悬停提示。
- **窗口是纯展示**：读到的部分没有交互按钮（`hide_button` 是被注释掉的）→ 对应 **Q28：窗口不做交互，一切靠国策驱动**。

### 5.1 `inlay_window` 的 `position` 怎么定（实测与推导）

树内声明写法（`focus_tree` 顶层，可多个）：

```
inlay_window = {
    id = inlay_window_id
    position = { x = XXX y = YYY }   # 与 continuous_focus_position 同尺度
    override_position = { x = ... y = ... trigger = { ... } }   # 可选，满足条件时改写位置
}
```

**尺度：约 100~140 像素 / 国策格。** 两条独立依据：

| 依据 | 内容 | 推出 |
| --- | --- | --- |
| 捷克窗口原作者的注释 | `position = { x = 9990 y = 350 } #y = ~2.5`（`czechoslovakia_mu.txt`） | ≈ **140 px/格** |
| `continuous_focus_position` | 连续国策栏惯例摆在树正下方；苏联树 `{ x = 55 y = 1500 }` 而树高 15 格 | 1500/15 = **100 px/格** |

**定位方法（已验证可用）**：

1. 用 `docs/reference/tools/scan-tree-bbox.ps1` 解析出目标树的**绝对坐标包围盒**（树里大量用 `relative_position_id`，必须沿依赖链累加）。
2. 苏联树实测：**X -11..81、Y 0..15 格** → 树底约在 y = 1500~2100 px。
3. 把窗口放到树底之外：我们用 `{ x = 4000 y = 2200 }`。

**验证推演是否可信的办法**：算出的坐标反推回格数，看是否落在包围盒内。
我们原来的 `(4000, 1200)` 反推约 `(28.6, 8.6)` 格 —— 正在树肚子里，与截图里“窗口压在国策树上”完全吻合，印证尺度可用。

⚠️ **两条注意**：
- **德国窗口的 `(4500, 1150)` 不能照搬**到别的树上——每棵树的尺寸不同。
- 每棵树的 px/格 估值不一致（德 68、日 46、暹罗 139、澳 133），说明包围盒解析本身有噪声（正则会把嵌套块里的 `x`/`y` 也算进去）→ **以上结果当估值用，最终仍需游戏内目视微调**。

---

## 6. 与需求文档的对应（Q19 / Q25 / Q26 / Q27 / Q28）

| 问题 | 德国做法 | 我们直接复用 |
| --- | --- | --- |
| **Q19** 国策与席位关系 | 点国策 → 写入席位变量 → 再点该角色专属国策；加成为角色效果 | ✅ 一致，全盘照搬 |
| **Q25** 席位可否替换 | `GER_remove_replaced_advisor_N_effects` 提供完整的换人流程 | ✅ 照搬结构 |
| **Q26** 席位数量 | "填第一个空位"逻辑，**与席位数量无关** | ✅ 因此扩到 **7 席** 技术上零成本 |
| **Q27** 民族精神粒度 | **每个角色一套**施加/移除效果（即每角色独立） | ✅ 每角色一个动态民族精神 |
| **Q28** 窗口交互 | 纯展示，无按钮 | ✅ 纯展示 |

> 关于 **Q26 扩到 7 席**：你的条件是"如果体制方与反对派不互斥就加席位"。按 §2.4.2 的矩阵，两组之间**只是部分互斥**（托洛茨基↔莫洛托夫/卡加诺维奇/伏罗希洛夫、布哈林↔莫洛托夫/卡加诺维奇、图哈切夫斯基↔伏罗希洛夫），而**加里宁、李维诺夫等与反对派并无互斥关系** → 存在可共存的情形 → **建议采纳 7 席**。

---

## 7. 图标规格（实测）

| 类型 | 尺寸 | 位置 | 备注 |
| --- | --- | --- | --- |
| **国策图标** | **100 × 88** | `gfx/interface/goals/` | 原版 2954 个文件；R56 只加了 3 个 |

> 其余类型（民族精神、决议、窗口装饰图）的尺寸在下一轮补齐——上一轮的终端输出被截断了。

---

## 8. R2 结论：原版 vs R56 对比（已完成）

**结论：R56 没有新增任何核心圈机制，只是规模扩张。可以放心"以原版为蓝本 + 做 R56 适配"。**

| 文件 | 原版 | R56 | 核心圈相关计数 |
| --- | --- | --- | --- |
| `focus_inlay_windows/ger_inner_circle_inlay_window.txt` | 275 行 | 277 行 | advisor 变量 **69 = 69**；全文差异仅 R56 多 2 行 |
| `national_focus/germany.txt` | 827 KB / 38,872 行 | 1619 KB / 72,008 行 | IC 标记 330 → **335**（树整体扩写 +33k 行） |
| `scripted_effects/GER_scripted_effects.txt` | 76 KB / 3,110 行 | 92 KB / 3,647 行 | IC 标记 **75 = 75**（完全一致） |
| `scripted_triggers/GER_scripted_triggers.txt` | 23 KB / 1,477 行 | 25 KB / 1,551 行 | IC 标记 **2 = 2**（完全一致） |
| `on_actions/12_wuw_on_actions.txt` | 67 KB / 3,163 行 | **未覆写** | — |
| `scripted_localisation/WUW_GER_scripted_loc.txt` | 73 KB / 3,186 行 | **未覆写** | — |
| `interface/GER_inner_circle_scripted_gui.gui` | 12 KB / 478 行 | **未覆写** | — |

**三条可直接执行的推论**

1. R56 **完全没碰** `12_wuw_on_actions.txt`、`WUW_GER_scripted_loc.txt`、`interface/GER_inner_circle_scripted_gui.gui` → 这三个文件在原版与 R56 下**是同一份**，我们直接以原版为蓝本仿造，零差异风险。
2. R56 覆写了 `germany.txt` / `GER_scripted_effects.txt` / `GER_scripted_triggers.txt`，但**核心圈部分内容一致**（effects 75=75、triggers 2=2、advisor 变量 69=69），只是整体行号位移 → 把原版的核心圈段落移植进 **R56 版**这三个文件即可。
3. inlay window 仅差 2 行 → 同样以原版为蓝本。

**改法定型**

> **以原版实现为蓝本**（结构清晰、R56 未改），**落到 R56 版的宿主文件里**。对应关系：德国的宿主是 `germany.txt`，我们的宿主是 R56 版 `soviet.txt`（已经是 R56 副本）。

---

## 9. 剩余待办

- [ ] **R1** 实测德国窗口各 sprite 的像素尺寸（美术生成基准）
- [ ] **R3** `FOCUS_FILTER_*` 自定义筛选项的注册位置（我们要 `FOCUS_FILTER_HOF_INNER_CIRCLE`）
- [ ] **R4** puppet 判定触发器的准确写法
- [ ] **R5** 各线国策数量（按史实查）—— 进行中
- [x] ~~**R2** 对比原版与 R56 的核心圈实现~~ ✅ 完成（见 §8）

**S0 到此结束。** 以上全部为只读分析，未产生任何游戏脚本改动。
