# 96 · **苏联「开战倒计时」决议** —— 需求查证报告（v1 · 2026-09-23）

> 用户口径（2026-09-23）：
> 「我要让**苏联在玩家扮演的情况下，与任意一个国家开战的时候触发倒计时决议，不可取消**，
> **失败条件为苏联与该国家不在战争中或者该国家不存在**，
> 决议效果为**完成后给对方国家增加 100 个师**，师编制我需要你先确认一下**能不能用对方国家未解锁的科技的师编制**。
> **同时和多个国家开战的情况下都会有这个决议**。开始搜索吧，完成了向我汇报」
>
> ⚠️ **本文只做查证 + 提案，不写任何代码。**
> ✅ **2026-09-23：已完成实装** —— 设计 / 逐字段说明 / 实测清单见
> **`docs/97-soviet-war-countdown-design.md`**；本文 §7 的七项待裁已全部结案（见 §8）。
> 所有结论都标了**出处**（游戏文件 = 本机实测；官方 wiki = `docs/reference/wiki/` 离线归档 + 在线 API）。

---

## §1 结论速览

| # | 问题 | 结论 |
| :-: | --- | --- |
| 1 | **能实现吗** | ✅ **能，而且是原版机制的组合，零发明** |
| 2 | **「同时和多个国家开战 ⇒ 每个都有一条」** | ✅ **`targeted_decisions` 天然如此** —— 官方 wiki 原文：*"the decision will **clone itself for each country** that it gets targeted towards, putting the flag of the country in the bottom right of the decision's icon"* |
| 3 | **「倒计时」** | ✅ 两条路：`days_remove = N`（决议）或 `days_mission_timeout = N`（任务） |
| 4 | **「不可取消」** | ⚠️ **需要选一种做法**（三种，见 §2.4）—— 最简单的「决议 + `days_remove`」**可能**能被玩家手动中止，**这一条必须进游戏实测** |
| 5 | **「失败条件」** | ✅ **`cancel_trigger`** —— 官方 wiki 原文：*"Upon it being evaluated as true, the decision timer ends **without** `remove_effect` being executed"* |
| 6 | **「给对方 100 个师」** | ✅ `division_template = { ... }`（建模板，可给任意国家）＋ `create_unit = { owner = <敌国> count = 100 }`（**必须在 state 作用域内**） |
| 7 | ⭐ **「能不能用对方未解锁科技的师编制」** | ✅ **能** —— 但要分清两层（见 §4）：**模板本身不查科技**；**装备由引擎按"该国当前可用的最新装备"自动配给**，所以**不会造不出**，只是**品质被对方自己的科技上限压住** |

**一句话**：这套东西**原版全都有先例**，最接近的现成模板是 **阿富汗的「Qatgani Cavalry」国策**（先 `division_template` 建模板 → 再 `create_unit` 生成）。

---

## §2 决议机制（逐项带出处）

### §2.1 目标国家 —— `targeted decision`

⭐ **这是整个需求的地基**：只要决议里出现 `targets` / `target_array` / `target_trigger` / `target_root_trigger` 任意一个，
它就被标记为 **targeted**，并且**按目标国家各克隆一条**。

| 字段 | 作用 | 出处 |
| --- | --- | --- |
| `target_array = enemies` | 目标 = 当前**正在交战**的国家 | 原版 `common/decisions/*.txt` 实测：`enemies`（2）· `potential_and_current_enemies`（4）· `enemies_of_allies`（4）；官方 wiki《Decision modding》 |
| `target_trigger = { FROM = { ... } }` | 逐目标筛（**每天检查**） | 同上；官方 wiki：*"In here, ROOT is the country that gets the decision and **FROM is the potential target**"* |
| `target_root_trigger = { ... }` | 只查 ROOT（**每天**）；⭐ **写它也会让决议变成 targeted** | 官方 wiki |
| `FROM` | **= 目标国家**（不是发起国！） | 官方 wiki：*"Despite what the names imply, **FROM is the target** of the decision rather than the country doing it."* |
| `fire_only_once` | targeted 时 = **每个目标各算一次** | 官方 wiki：*"a decision targeted towards BLR will not disappear if a decision of the same ID targeted towards LIT gets completed"* |

> 📌 **对需求的直接映射**：`target_array = enemies` ⇒ **和几个国家开战就有几条决议**，每条图标右下角带那国国旗。
> ⚠️ **`enemies` 是「当前敌对国」数组** —— 宣战当天不一定立刻刷新，**建议叠 `on_war_relation_added` 立即激活**（见 §2.5）。

### §2.2 倒计时

| 写法 | 语义 | 出处 |
| --- | --- | --- |
| `days_remove = N`（决议） | 「选中后到效果生效之间的计时器」；**`-1` = 永不因计时结束而消失** | 官方 wiki《Decision modding》§ Timer upon selection |
| `days_mission_timeout = N`（任务） | **`days_mission_timeout` 这个字段本身就把「决议」变成「任务（mission）」** | 官方 wiki § Missions |
| `DECISION_ACTIVE_FOR_AMOUNT_DAYS` | 界面显示 **"Active for $AMOUNT$ days."** / 中文「**持续 $AMOUNT$ 日。**」 | 原版本地化实测 |
| `modifier = { ... }` | **计时期间给 ROOT 挂一个 modifier**（可以在倒计时里做"预警"效果） | 官方 wiki |

### §2.3 失败条件 —— `cancel_trigger` ✅

| 字段 | 语义 | 出处 |
| --- | --- | --- |
| `cancel_trigger = { ... }` | ⭐ **为真时，计时器立即结束，且【不执行】`remove_effect`**（= 拿不到奖励） | 官方 wiki 原文（§ Timer upon selection） |
| `cancel_if_not_visible = yes` | **默认 `false`**；打开就把 `visible` 的内容一并当作取消条件 | 官方 wiki |
| `cancel_effect = { ... }` | 被取消时执行的副作用（可用来**把 complete_effect 的副作用倒回去**） | 官方 wiki |
| `DECISION_WILL_BE_CANCELLED_IF` | 界面 tooltip「**§H立刻取消，如果：§!**」 | 原版本地化实测 |

⇒ **用户要的失败条件直译**：
```txt
cancel_trigger = {
    OR = {
        NOT = { FROM = { is_in_war_with = ROOT } }   # 苏联与该国不在战争中
        FROM = { exists = no }                       # 该国不存在（多半自动失效，见下）
    }
}
```
> ⭐ **原版已有几乎逐字一样的先例**（`common/decisions/AFG.txt` L1238）：
> ```txt
> cancel_trigger = { FROM = { OWNER = { OR = { has_war_with = ROOT  exists = no } } } }
> ```
> ⇒ 「不在战争中 / 不存在」这个套路**原版自己就是这么写的**。
> ⚠️ 「目标国被吞并不存在」时，targeted decision 的目标本身失效，**很可能自动消失**（官方 wiki：*"by default, it's impossible to target a non-existing country"*，`target_non_existing = yes` 才能解除）—— 具体表现仍需实测。

### §2.4 ⚠️ 「不可取消」—— 三案待裁（判据 J）

| 案 | 做法 | 代价 / 风险 |
| --- | --- | --- |
| **甲 · 普通决议 + `days_remove`** | 玩家**点一下**才起计时；之后靠 `cancel_trigger` 中止 | ⚠️ **玩家点之前它只是"可点"**——不符合「开战就自动跑」。⚠️ **能否手动中止【未确认】**：本地化里同时有 `DECISION_CANCEL_HEADER`（"When aborted:"）与 `TIMED_DECISION_ABORT_HEADER`（"Will abort if:"），**看不出有没有玩家侧的中止按钮** ⇒ **要实测** |
| **乙（推荐）· 任务 + 不写 `selectable_mission`** | 用 `days_mission_timeout` 变成 mission；**`selectable_mission` 不写（=no）⇒ 玩家点不了**；再让 `available` 恒假，使 `complete_effect` 不触发，只等 `timeout_effect` | ✅ **玩家既不能点、也不能中止** ⇒ **「不可取消」天然成立**。⚠️ 缺点：`available` 要刻意写假（`always = no`），语义绕；⚠️ 任务在界面上是「任务」不是「决议」 |
| **丙 · 甲 + 「取消也罚」** | 用甲的写法，但 `cancel_effect` 里给苏联一个惩罚 | ✅ 若甲确实能被中止，**中止≠白嫖**；⚠️ 玩家仍可主动中止来规避"敌人变强" |

> ⭐⭐ **官方 wiki 的 mission 范例与用户需求结构完全相同**（只差效果内容）：
> ```txt
> my_mission = {
>     activation = { has_civil_war = yes }      # ← 出现条件（每天检查）
>     available  = { has_civil_war = no  has_war = yes }
>     cancel_trigger = { has_war = no }          # ← 失败条件
>     is_good = yes
>     days_mission_timeout = 100                 # ← 倒计时
>     selectable_mission = yes
>     complete_effect = { add_ideas = my_idea }
>     timeout_effect  = { declare_war_on = { target = SOV type = annex_everything } }   # ← 到点后发生的事
> }
> ```
> ⇒ **把 `timeout_effect` 换成「给 FROM 加 100 个师」就是用户要的东西。**

### §2.5 触发时机

| 路线 | 做法 | 评价 |
| --- | --- | --- |
| **A · 纯数据** | targeted decision + `target_array = enemies`（或 `target_trigger = { FROM = { has_war_with = ROOT } }`） | ✅ **零 `on_action`**；⚠️ 每日检查 ⇒ **开战次日**才出现 |
| **B · 立即触发** | `on_action` 的 **`on_war_relation_added`** ＋ 效果 **`activate_targeted_decision = { target = FROM decision = <决议 id> }`** | ⭐ **官方 wiki 明确推荐这条路**：*"If possible, it is recommended to use this effect instead of letting it automatically activate... For instance, if the targeted decision activates by being at war with a country, `on_war_relation_added` in on_actions can be used"* ⇒ **当场出现** |

**`on_war_relation_added` 实测存在**（原版 `00_on_actions.txt` + 15 个 DLC on_action 文件 + R56），官方 wiki 定义：
> *"fired when **two countries end up at war with each other**... **ROOT is attacker, FROM is defender**"*（1.9.3）
> 对照 `on_war`：*"fired when a country goes to war against anyone and **is not fired again** when it enters war against another country unless it went to peace"* ⇒ ⛔ **`on_war` 不行，必须用 `on_war_relation_added`**（这条正是「同时和多个国家开战」的关键）

⚠️ **副作用提醒**：`on_war_relation_added` 对**任何两国**开战都触发（不只苏联）⇒ 效果里要 `limit = { ROOT = { tag = SOV } }` 之类。
⚠️ **「玩家扮演苏联」怎么判**：脚本触发器有 `is_ai`（原版 `categories/00_decision_categories.txt` 里就用 `is_ai = no`）⇒ 写进 `target_root_trigger` / `allowed` 即可。

---

## §3 「给对方 100 个师」怎么实现

### §3.1 ⛔ 先排除 `load_oob`

`load_oob = "<文件名>"` 确实能加载 `history/units/*.txt` 并生成师（原版用在 150 处，含`GER.txt` 23 处），**但它不适合本需求**：
- ⚠️ **OOB 里每个 `division` 块都写死了 `location = <province id>`** —— 实测 `history/units/` 共 **5074 个 `division` 块，5074 个都带 `location`，0 个不带**。
- ⇒ OOB 只能把师丢在**固定的省份**，而本需求的"对方"是**任意国家** ⇒ **位置对不上**。

### §3.2 ✅ 正确组合：`division_template` + `create_unit`

**① `division_template = { ... }`**（效果，1.0）
> 官方 wiki：*"**Creates and adds the specified division template to the current scope.**"*
- 可以**在任意国家的 scope 里建模板** —— 原版 R56 就是这么做的：
  `r56_on_actions.txt` L1444 起，`VIN = { ... division_template = { name = "Viet Minh Partisan" ... } ... }`

**② `create_unit = { ... }`**（效果，1.3）
```txt
create_unit = {
    division = "name = \"X\" division_template = \"Y\" start_experience_factor = 0.5"   # ⚠️ 必须写在一行
    owner = <国家>            # ← 师归谁
    count = <数量>            # ← 一次造几个（默认 1）★★ 100 就写这里
    prioritize_location = <province>        # 可选
    allow_spawning_on_enemy_provs = yes     # 可选
    country_score = { ... }                 # 可选，MTTH 决定落在哪个省
    divisional_commander_xp = <int>
}
```
- ⚠️⚠️ **`create_unit` 只能在 state 作用域里用**（官方 wiki：*"Can only be used within a state scope, such as `capital_scope`. **The effect will do nothing when put into a country's scope.**"*）
- ⇒ 写法：`FROM = { capital_scope = { create_unit = { owner = FROM count = 100 ... } } }`

⭐ **原版现成范例（照抄即可）** —— `common/national_focus/afghanistan.txt` L1509 起：
```txt
division_template = {
    name = "Qatgani Cavalry"
    division_names_group = AFG_CAV_01
    is_locked = no
    force_allow_recruiting = yes
    regiments = { cavalry = { x = 0 y = 0 } ... }
    support   = { recon   = { x = 0 y = 0 } }
}
random_owned_controlled_state = {
    create_unit = {
        division = "division_template = \"Qatgani Cavalry\" start_experience_factor = 0.05 start_equipment_factor = 1"
        owner = AFG
        count = 2
    }
}
```

其他可用候选（都查过，本轮**不用**）：
| 效果 | 说明 | 为什么不用 |
| --- | --- | --- |
| `load_oob` | 加载 OOB 文件 | ⛔ 位置写死（见 §3.1） |
| `add_units_to_division_template` | 往**已存在**的模板里加营 | 不生成师 |
| `change_division_template` | 改某个师的模板 | 不生成师 |
| `set_oob` | 把某国 OOB 整体换成另一份 | ⛔ 会**覆盖**对方的军队编制 |
| `create_colonial_division_template` | 给**附庸**建模板 | 只建模板，且限定附庸关系 |

---

## §4 ⭐ 用户点名的问题：**能不能用对方国家未解锁的科技的师编制？**

### 结论：✅ **能** —— 但要分清「模板」「装备」两层

| 层 | 是否受对方科技限制 | 依据 |
| --- | --- | --- |
| **① 师编制（`division_template` 里的 `regiments` / `support`）** | ⛔ **不受限**。里面写的是 **sub-unit 名**（`infantry` / `cavalry` / `jungletroop` / `recon` …），定义在 `common/units/*.txt`，是**全局数据**。效果本身**只做"Cannot..."以外的事**：官方 wiki 对该效果的描述只有「Creates and adds the specified division template to the current scope」，**没有任何科技前置** | 官方 wiki Effects；原版 `SOV_scripted_effects.txt`（18 处）· `afghanistan.txt`（18 处）· `r56_on_actions.txt`（79 处）都是**随手给任意国家建模板** |
| **② 科技到底管什么** | 科技只通过 `enable_subunits`（78 处）/ `enable_equipments`（225 处）控制**玩家在编制器界面里能不能选** | 原版 `common/technologies/*.txt` 实测 |
| **③ 装备（师有没有枪炮）** | ✅ **由引擎自动配给**：官方 wiki 原文 —— *"**Created equipment will be the latest available to the country.**"* ⇒ 用的是**该国自己科技能造出来的最好装备** | 官方 wiki `create_unit` 说明 |
| **④ 免不免费** | `start_equipment_factor` 默认 **1**（= 满装备）、`start_manpower_factor` 默认 **1**（= 满人力）；⚠️ **该字段不能写 0，写 0 会被当成 1** | 同上 |

⇒ **三条实用推论**：
1. **不会"造不出来"** —— 就算对方一个坦克科技都没有，`create_unit` 照样把师造出来，营会自动配它**当前能拿到的最好装备**。
2. **但"高级师"会降级** —— 你写的是 `modern_armor` 营，对方只有 1936 年科技 ⇒ 拿到的是**低配装备**（甚至可能是"能拿到的最接近的那个"）。
3. **真想给高级师** ⇒ 得连科技（和/或装备）一起给。原版的标准写法在 `common/decisions/GER.txt` L3662（GER → 帝国专员辖区 RKG）：
   ```txt
   RKG = {
       add_manpower = 50000
       add_equipment_to_stockpile = { type = infantry_equipment amount = 5000 producer = GER }
       inherit_technology = GER        # ← ★ 把 GER 的科技全复制过来（官方 wiki："copies the current country's researched technologies from the specified country"，1.6）
       load_oob = "RK_OOB"
   }
   ```
   📌 另有 `set_technology = { <科技> = 1 }`（可只给单项）· `create_equipment_variant = { ... allow_without_tech = yes }`（**仅变体设计**能用，不适用于师编制）

⚠️ **仍需游戏内实测的一处**：`division_template` 效果给一个**没解锁某 sub-unit** 的国家时，
引擎是**照建**、还是**静默丢掉那个营**、还是**报错** —— 静态文件看不出，**必须进游戏跑一次**（见 §6）。

---

## §5 提案骨架（**不含数值 / 文案，等你过目后再出正式设计**）

```txt
# 新文件：common/decisions/categories/hof_sov_war_categories.txt
hof_sov_war_category = {
    icon = ...
    allowed = { original_tag = SOV }          # 只在苏联面板里出现
    ...
}

# 新文件：common/decisions/hof_sov_war_countdown.txt
hof_sov_war_category = {
    hof_sov_war_countdown = {
        # ── 目标：所有与苏联交战的国家 ⇒ 一国一条 ──
        target_array   = enemies
        target_trigger = { FROM = { has_war_with = ROOT } }

        # ── 只在【玩家扮演苏联】时 ──
        target_root_trigger = { is_ai = no }

        # ── 倒计时 ──（甲/乙/丙三案见 §2.4）
        days_remove = <N>

        # ── 胜利：给对方 100 个师 ──
        remove_effect = {
            FROM = {
                capital_scope = {
                    create_unit = {
                        division = "division_template = \"<模板名>\" start_experience_factor = 0.5"
                        owner = FROM
                        count = 100
                    }
                }
            }
        }

        # ── 失败条件 ──
        cancel_trigger = {
            OR = {
                NOT = { FROM = { exists = yes } }
                NOT = { FROM = { is_in_war_with = ROOT } }
            }
        }
        cancel_effect = { }        # 或者：给苏联一个"半途而废"的惩罚

        ai_will_do = { base = 0 }  # AI 不点（我们本来就不希望 AI 碰它）
    }
}

# 模板：由 on_action / 一个 scripted_effect 先给【目标国】建好
#   FROM = { division_template = { name = "<模板名>" regiments = { ... } } }
```

⚠️ **两个必须一起解决的工程点**：
1. **模板必须先存在** —— `create_unit` 只按**名字**找模板；模板得在**目标国自己的 scope**里先建（`division_template` 效果）。
   ⇒ 建议在 `on_war_relation_added` 里**建模板**，在**决议的 `remove_effect`** 里 `create_unit`。
2. **100 个师放哪** —— `create_unit` 只能在 state 作用域 ⇒ 要么全塞首都（`capital_scope`，会堆成一片），
   要么 `every_owned_state = { limit = {...} create_unit = { count = <分摊> } }` 摊开。**这条要你定。**

---

## §6 ⬜ 必须游戏内实测的 5 项（硬性规则 5 / 6）

| # | 要验的 | 怎么验 |
| :-: | --- | --- |
| 1 | **目标国没解锁该 sub-unit 时，`division_template` 照建还是丢营 / 报错** | 给一个纯农业小国建一个含 `modern_armor` 的模板，看 `error.log` + 编制器里那一格 |
| 2 | **`create_unit` 的装备到底从哪来**（免费发放 vs 扣对方库存） | 造 100 个师前后看对方库存 |
| 3 | **普通决议在计时中能不能被玩家手指中止**（决定 §2.4 取甲还是乙） | 手动点一下带 `days_remove` 的决议，看有没有中止按钮 |
| 4 | **目标国被吞并 / 战争结束后，targeted decision 是消失、变灰、还是残留** | 打一场速战 |
| 5 | **`on_war_relation_added` + `activate_targeted_decision` 是否当场生效** | 开战当天看决议栏 |

---

## §7 待你裁决（判据 J）—— ✅ **2026-09-23 已全部结案，见 §8**

| # | 问题 | 备选 | 我的倾向 |
| :-: | --- | --- | --- |
| 1 | **倒计时「不可取消」怎么实现** | 甲 普通决议 · **乙 非可选任务** · 丙 甲+取消也罚 | **乙**（唯一能保证"点不了"） |
| 2 | **倒计时长度** | 需要你给一个数 | —— |
| 3 | **触发时机** | A 纯数据（次日） · **B `on_war_relation_added`（当场）** | **B**（官方推荐） |
| 4 | **100 个师的模板长什么样** | 照当前科技自动配装 · 固定给一套"苏式"编制 · 连科技一起给 | ⚠️ 需要你定 |
| 5 | **100 个师放哪** | 全在首都 · 按州摊开 · 按国大小给 | ⚠️ 需要你定 |
| 6 | **失败时要不要也罚一下苏联** | 要 / 不要 | 不要（先按字面） |
| 7 | **这功能叫什么 / 属于哪个面板** | 需要一个显示名 + 一个图标 | ⚠️ 需要你定 |

---

## §8 ✅ 用户裁决（2026-09-23）—— 七项全部结案，**已实装**

> 全文设计与逐字段说明见 **`docs/97-soviet-war-countdown-design.md`**。

| §7 的 # | 裁决 | 落地 |
| :-: | --- | --- |
| 1 | ⭐ **乙案**（「计时中不能被玩家手动终止，所以应该是乙」） | `days_mission_timeout = 29` + ⭐ **`available = { always = no }`**（关键：mission 的 `available` 默认恒真 ⇒ 不写这个会瞬间完成消失）+ ⛔ 不写 `days_remove` |
| 2 | **29 天倒计时 + 1 天间隔 = 30 天一轮** | `days_mission_timeout = 29` + `fire_only_once = no`（到点后由 `activation` 每日复查自然重挂） |
| 3 | **B —— 开战当天即生效** | `on_war_relation_added` + `activate_targeted_decision`（主动/被动两条分支） |
| 4 | **模板 = 3×4 中型坦克 + 2×4 摩托化 + 5 团属步兵炮** | `medium_armor` ×12 · `motorized` ×8 · `artillery_brigade` ×5 = **25 营**（⭐ 正好是 5×5 引擎上限）；**装备免费**（`start_equipment_factor = 1`），⛔ **不给科技**<br>⚠️ **2026-09-25 用户改口径：「炮兵是错的，移除炮兵，增加两个支援连，工兵连和摩托化侦察连」** ⇒ 现为 **20 营 + 2 支援连**，本文这一行是**当时的记录**，现行口径见 `docs/97` §2.5 |
| 5 | **全在目标国首都**，首都失守要处理 | `capital_scope = { create_unit }`；`else` 退到 `random_owned_controlled_state` |
| 6 | ⛔ **失败不罚苏联**（用户：「失败为什么还要惩罚苏联……你失败还惩罚是何意味」） | **刻意不写 `cancel_effect`** |
| 7 | **面板 = 决议栏**；任务名 = **「敌方正在动员摩托化坦克师！」**；图标由本项目选 | 分类 `hof_sov_mob_category`（页签「敌军动员」）；图标取**原版现成** `GFX_decision_generic_military` + `GFX_decision_category_sov_great_patriotic_war`（**零缺图风险**） |

> ✅ **本轮零返工**：13 条口径全部在提案阶段确认，代码一次写完。
> ⭐ **唯一由本项目代选的两项**（分类名 / 决议图标）按判据 J **列在 `docs/97` §7 备查**，不阻塞实装。


---

## 相关

- 决议机制官方文档（在线 API 全文已核对）：`Decision modding`（Paradox wiki）
- 本机离线归档：`docs/reference/wiki/Effects.txt`（`create_unit` / `division_template` / `load_oob` / `inherit_technology`）·
  `docs/reference/wiki/On_actions.txt`（`on_war_relation_added` / `on_declare_war`）
- 原版现成范例：`common/national_focus/afghanistan.txt` L1509（建模板 + 生成师）·
  `common/decisions/GER.txt` L3662（`inherit_technology` + `load_oob`）·
  `common/scripted_effects/SOV_scripted_effects.txt`（`create_unit` 115 处）
- 本机路径常量与踩坑：`AGENTS.md` 硬性规则 1–17
