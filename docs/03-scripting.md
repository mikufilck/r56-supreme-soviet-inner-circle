# 03 · 脚本：作用域、effect、trigger、事件、决议、国策

> ⚠️ 本章讲**语法结构**是可靠的；具体 effect / trigger 的**名称与参数**随版本增删，必须以原版文件为准。示例仅示范结构，不要照抄名字。

## 3.1 语法总则（📗 按官方 wiki `Modding` 的 Code structure 校正）

1. 一律形如 **`<属性> = <参数>`**，块用 `{ }`。**缩进对解析零影响**（整个文件写成一行也能跑），只影响可读性与括号配对的肉眼检查。
2. 未加引号的"词"只能由 `[a-zA-Z0-9_.,\-/]` 组成。含其它字符（空格、中文…）必须用 `"` 括起。
3. 字符串**最长 255 字符**，且**不能跨行**——字符串里直接换行会报错。
4. 字符串里只有两个转义有效：`\"` 输出引号、`\\` 输出反斜杠。反斜杠不能用于其它用途。
5. **参数不能留空**。写成 `icon =` 换行接 `x = 2`，引擎会把 `icon` 的参数解析成 `x`，接着 `= 2` 报错，结果"图标位置莫名其妙不对"。
6. **该给参数的地方不能省等号**。`GER = { leave_faction }` ✗ → 正确是 `leave_faction = yes`。
7. `#` 注释到行尾，**没有多行注释**。
8. **多一个 `}` 会让文件从该处起停止解析**（后面的内容全部不执行）。在 `history/countries/` 这类不强制根块的目录里尤其致命。这类错误**不一定写进 `error.log`**，可能表现为"改动完全没生效"。

**顺序问题**（📗 wiki）：

| 对象 | 顺序是否有意义 |
| --- | --- |
| effect / trigger | ✅ 按书写顺序执行，tooltip 也按此排。先 `annex_country` 再判断它是否拥有某州，永远是 false |
| modifier | ❌ 完全无关，tooltip 顺序是硬编码的 |
| 同一数据库条目的不同属性 | ❌ 无关（国策里 `completion_reward` 写在 `x`/`y` 前面也一样） |
| 同类型条目的创建顺序 | ✅ 按文件内位置；**文件名优先**（ASCII 序，可配 `00_` / `zz_` 前缀调整） |

最后一条有个会崩游戏的例子：装备（equipment）必须在**其 archetype 已存在**之后才能定义，即使 archetype 写在同一文件的后面也会**直接崩溃到桌面**。

## 3.2 作用域（scope）

| 作用域 | 说明 | 常见来源 |
| --- | --- | --- |
| country | 国家 | `GER`、`tag = ...` |
| state | 州 | `state = 123` |
| province | 省份 | `province = 1234` |
| character | 角色 | 将领、顾问、特工 |
| unit leader / division / army / fleet / air wing | 军事单位 | — |
| strategic region | 战略区 | — |

**作用域关键字**：

| 关键字 | 含义 |
| --- | --- |
| `ROOT` | 当前 effect / trigger 块的起点 |
| `THIS` | 当前所在对象 |
| `PREV` | 上一层作用域（可 `PREV.PREV`） |
| `FROM` | 触发者/来源（事件、on_action 等语境下） |
| `owner` / `controller` | 州的归属国 / 占领国 |
| `capital_scope` | 首都所在州 |

**遍历（把作用域切进去）**：

```
every_country = { limit = { has_war = yes } <effect> }
random_country = { ... }
every_owned_state = { ... }
random_state = { ... }
every_character = { ... }
```

规则：`every_*` 用来做批量操作，`random_*` 用来随机取 1 个；`limit = { ... }` 负责过滤。

## 3.3 Trigger（条件）

```
trigger = {
	tag = GER
	has_government = fascism
	is_faction_leader = yes
	num_of_civilian_factories > 50
	owns_state = 123
	controls_state = 123
	has_completed_focus = hof_my_focus
	date > 1939.1.1
	has_war = yes
	OR = { ... }
	AND = { ... }
	NOT = { ... }
	any_owned_state = { is_core_of = ROOT }
}
```

要点：

- 逻辑组合用 `AND` / `OR` / `NOT`，一个块里并列多个条件是**隐式 AND**。
- 数值比较：`> >= < <= =`。
- 日期写成 `1939.1.1`。
- **复用**：写进 `common/scripted_triggers/hof_triggers.txt`

```
hof_is_ready = {
	has_war = no
	has_stability > 0.5
}
```

调用时 `hof_is_ready = yes`。

## 3.4 Effect（效果）

```
add_political_power = 50
set_country_flag = hof_done
clr_country_flag = hof_done
add_ideas = { hof_my_idea }
remove_ideas = { hof_my_idea }
add_equipment_to_stockpile = { type = infantry_equipment amount = 1000 }
add_state_core = 123
```

要点：

- **复用**：`common/scripted_effects/hof_effects.txt`

```
hof_reward = {
	add_political_power = 25
	set_country_flag = hof_rewarded
}
```

调用时 `hof_reward = yes`。

- **隐藏操作**用 `hidden_effect = { ... }`（不显示在 tooltip 里）。
- **美化 tooltip** 用 `custom_tooltip = hof_my_tooltip_key`，避免把 `every_country` 之类的实现细节暴露给玩家。

**调试技巧**：把复杂 effect 一步步拆开写，每步之间用 `log = "..."`（⚠️ 需确认该 effect 在本版本可用），或干脆拆成多个 scripted_effect 逐个二分定位。

### 3.4.1 修正词条（modifier）速查

`idea` / 国策 / 决议里 `modifier = { ... }` 能写哪些键名，见
**`docs/reference/notes/hoi4-modifier-glossary-zh.md`**（按政治/工业/陆海空/经验/建筑/抵抗/情报分类的中文对照）。

⚠️ 那是**第三方整理稿（1.9 时期）**，只能当**候选词条名**用。
**写进脚本前必须核实**：优先看 `docs/reference/reports/sov-idea-words-report.txt`（扫当前游戏文件得到的实测清单），
或直接扫 `common/ideas/`、`common/national_focus/` 里真实出现过的键名。

数值约定：`0.05` = **+5%**，`-0.10` = **−10%**，`1.00` = **+100%**（个别词条如 `max_organisation` 是绝对值）。

## 3.5 事件（`events/*.txt`）

```
add_namespace = heartofiron  # 本机 1.19.2 原版写法；namespace = 会导致 Malformed token

country_event = {
	id = heartofiron.1
	title = heartofiron.1.t
	desc = heartofiron.1.d
	picture = GFX_report_event_generic_parliament
	is_triggered_only = yes

	trigger = { tag = GER }
	mean_time_to_happen = {
		months = 6
		modifier = { factor = 0.5 has_war = yes }
	}

	option = {
		name = heartofiron.1.a
		ai_chance = { base = 80 }
		effect = {
			add_political_power = 25
		}
	}
	option = {
		name = heartofiron.1.b
		trigger = { has_stability > 0.7 }
		ai_chance = { base = 20 }
		effect = { hidden_effect = { hof_reward = yes } }
	}
}
```

要点与坑：

- **id 必须全局唯一**。推荐命名空间式 `mymod.1`，避免和原版/其它 mod 撞号。
- `is_triggered_only = yes` → 不能被 MTTH 自动触发，只能由 effect 触发：
  `country_event = { id = heartofiron.1 days = 30 }`（`days` 可省略 → 立即）。
- `hidden = yes` → 静默事件，不弹窗。
- 三种文本（`title` / `desc` / `option name`）都要在本地化文件里有对应键。
- 事件类型：`country_event`、`state_event`、`news_event`、`unit_leader_event` 等，作用域不同，写之前先确认收件人。
- `desc` 可以写成 `desc = { text = key trigger = { ... } }` 做条件文本（⚠️ 具体写法以原版为准）。

## 3.6 决议

**分类**（`common/decisions/categories/*.txt`）：

```
hof_category = {
	icon = generic_political_actions
	allowed = { always = yes }
	visible = { always = yes }
}
```

**内容**：

```
hof_category = {
	hof_reform = {
		icon = generic_political_actions
		cost = 50
		fire_only_once = yes
		days_remove = 90
		available = { has_political_power > 50 }
		visible = { has_war = no }
		activation = { ... }
		complete_effect = { add_political_power = -50 hof_reward = yes }
		remove_effect = { ... }
		ai_will_do = { factor = 1 }
	}
}
```

- `available` = 现在能不能点；`visible` = 玩家能不能看见。
- `days_remove` + `remove_effect` 用于"持续 N 天后结算"的决议；`fire_only_once` 只做一次。

### 3.6.1 ⭐⭐ 三条会【静默失效】的决议 / 任务坑（2026-09-23 实测）

| # | 坑 | 不这么做会怎样 |
| :-: | --- | --- |
| 1 | ⭐⭐ **不写 `decision_category` 字段** —— 决议与分类靠**同名顶层块**关联（`common/decisions/*.txt` 里的顶层块名 = `categories/*.txt` 里的分类名）。实测原版 `decision_category = ` **0 次** | 写成字段 ⇒ **静默不挂分类**、面板里看不到 |
| 2 | ⭐⭐ **mission 的 `available` 默认【恒真】** ⇒ 想要一个"看得见、点不了的倒计时"必须写 `available = { always = no }`（写 `days_mission_timeout` 就把决议变成 mission） | 不写 ⇒ 任务**瞬间完成并消失** |
| 3 | ⭐ **`is_in_war_with` 在本版本【不存在】**（`documentation/triggers_documentation.md` **0 命中**） | 触发器永远为假 ⇒ 静默不生效；战争判定一律用 `has_war_with` |

⭐ 另两条常用参数：
- **targeted decision**：写 `targets` / `target_array` / `target_trigger` / `target_root_trigger`
  **任意一个**就会按目标国**各克隆一条**；⚠️ **`FROM` = 目标国**，不是发起国。
- **`create_unit` 只能在 state 作用域**（`capital_scope` / `random_owned_controlled_state`）；
  放进国家作用域会**什么都不做**。

📌 **实战实例**：`common/decisions/hof_sov_mob_decisions.txt`（苏联开战倒计时任务），
见 `docs/96`（查证）/ `docs/97`（设计与实装）；自检 = `verify-s2.ps1` **§15** 共 17 项。

## 3.7 国策（`common/national_focus/*.txt`）

```
focus_tree = {
	id = hof_focus_tree
	country = {
		factor = 0
		modifier = { add = 10 tag = GER }
	}
	focus = {
		id = hof_industry_1
		icon = GFX_focus_generic_industry
		x = 5
		y = 0
		cost = 10
		prerequisite = { focus = hof_root }
		mutually_exclusive = { focus = hof_other }
		available = { has_war = no }
		bypass = { ... }
		completion_reward = { hof_reward = yes }
		ai_will_do = { factor = 1 }
	}
}
```

- `x` / `y` 是网格坐标：**x 越大越靠右，y 越大越靠下**。`x=5` 是居中列。
- 图标必须是已注册的 `GFX_` 名字（见 `05-gfx-and-interface.md`）。
- **务必先在一张纸上画网格**再填坐标，否则连线会交叉。
- 树里至少要有一个能被"无条件拿到"的起始国策，否则 AI 可能卡死。

## 3.8 on_actions（`common/on_actions/*.txt`）

```
on_actions = {
	on_startup = {
		effect = { ... }
	}
	on_monthly = {
		effect = { ... }
	}
	on_state_control_changed = {
		effect = { ... }
	}
}
```

⚠️⚠️ **`on_actions = { }` 外壳是必须的**（2026-09-23 实测）：原版 `common/on_actions/` 下
**17 个文件全部套壳、0 个不套**；R56 的 **21 个也全部套壳**。
⇒ **顶层直接写 `on_war_relation_added = { }` 会静默不触发**（`error.log` 也不一定报）。

✅ **「覆盖还是合并」已结案 = 合并**：同名 on_action 跨多文件出现是常态
（`on_war_relation_added` 在**原版 12 个文件里都有**）⇒ 引擎合并所有同名块。稳妥做法：

1. 优先**新建自己的 on_action 文件**（`common/on_actions/hof_*.txt`），只写你需要的钩子 —— **不会覆盖**原版 / R56；
2. 必须改原版时，仍然**复制原版整个文件**再改（整文件覆盖规则）。

📌 **实战实例**：`common/on_actions/hof_sov_mob_on_actions.txt`（开战倒计时决议的即刻激活），
见 `docs/97` §2.4 / §2.8；自检 = `verify-s2.ps1` **§15e**。

## 3.9 AI

AI 不是必做项，但完全不管 AI 的 mod 在 AI 手里会走偏。常用目录：

| 路径 | 作用 |
| --- | --- |
| `common/ai_strategy/` | 让 AI 倾向某行为（如优先造某兵种、守某地） |
| `common/ai_focuses/` | AI 的国策优先级 |
| `common/ai_templates/` | AI 编制模板 |
| `common/ai_equipment/` | AI 装备生产倾向 |

`ai_will_do = { base = 100 modifier = { factor = 2 <trigger> } }` 是国策/决议/AI 里最常见的写法。

## 3.10 写脚本的实用心法

1. **先读原版**。找功能最接近的原版文件，复制成自己的新文件再改——这是最快学会语法的方式。
2. **一次只改一件事**，改完启动看 `error.log`。不要一口气写 500 行再启动。
3. **复杂逻辑拆成 scripted_effect / scripted_trigger**，像写函数一样复用。
4. **id 命名带前缀**，这是唯一能避免和别的 mod 撞车的办法。
