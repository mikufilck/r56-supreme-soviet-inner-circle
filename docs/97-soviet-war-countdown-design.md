# 97 · **苏联「开战倒计时」决议** —— 设计与实装（v1 · 2026-09-23 · **失败判据 v3 · 2026-09-25**）

> 前置查证报告：**`docs/96-soviet-war-countdown-decision.md`**（机制逐条带出处）
> 本文只写**用户裁决 → 落地做法 → 待实测**，不重复查证推导。

> **当前动员数量、模板和本地化以文末 §8（2026-09-27）为准。** 前文 100 师及旧模板条目保留为改版前的过程记录。

---

## §0 用户裁决（2026-09-23 · 全部在提案阶段完成 → 零返工）

| # | 用户口径 | 落地 |
| :-: | --- | --- |
| 1 | **「计时中不能被玩家手动终止，所以应该是乙」** | ⭐ **乙案 = 非可选任务**：写 `days_mission_timeout` 变 mission + `available = { always = no }` ⇒ **点不了也中止不了** |
| 2 | **「100 个师生成在目标国家的首都」** + 要处理**首都失守** | `capital_scope = { create_unit = … }`；首都若不在自己控制下 ⇒ `else` 退到 `random_owned_controlled_state` |
| 3 | **模板 = 3×4 中型坦克营 + 2×4 摩托化步兵营 + 5 个团属步兵炮营**<br>⭐ **2026-09-25 用户改口径：「炮兵是错的，移除炮兵，增加两个支援连，工兵连和摩托化侦察连」** | `medium_armor` ×12（x 0–2 · y 0–3）+ `motorized` ×8（x 3–4 · y 0–3）= **20 营**<br>＋ `support = { engineer（工兵连）· mot_recon（摩托化侦察连）}`<br>⛔ 原 `artillery_brigade` ×5 **已移除** |
| 4 | **任务名 =「敌方正在动员摩托化坦克师！」** | 决议本地化键 `hof_sov_mob_war_countdown` |
| 5 | **「先做出来我看看实际效果再决定做下一步的」** | 本轮只做这一个决议，不扩展 |
| 6 | **「装备直接免费发放（没错我们有火星科技支援）」** | `start_equipment_factor = 1`（满装备）；⛔ **不给科技** |
| 7 | **失败 = 目标国不存在 或 苏联与该国不在战争中**<br>⭐ **2026-09-25 第 ③ 条 = 「还拥有至少一个州」**（用户口径「已没有任何州的已投降敌人可以不发兵，已投降但是还有州的可以发」）<br>🔴 **v2 曾把这条读成「判 `has_capitulated`」⇒ v3 已订正**（D08 根本没进入「已停止抵抗」、它只是没有省的壳子，见 §2.3.1） | 三条件写进 **`target_trigger` + `activation` + `visible`**（**同一个**条件 · **四处一致**，见 §2.3）<br>⛔ **`cancel_trigger` 已整条删除**（原因见 §2.3.1） |
| 8 | **「开战当天即生效」** | `on_action` = `on_war_relation_added` + `activate_targeted_decision`（官方 wiki 点名推荐） |
| 9 | **「29 天倒计时 + 1 天间隔 = 30 天一轮」** | `days_mission_timeout = 29` + `fire_only_once = no`（倒计时结束后由 `activation` 每日复查自然重挂 ⇒ 1 天空档） |
| 10 | **图标由本项目选**（「我记得应该有很多合适的图标」） | 决议图标 = **`GFX_decision_generic_military`**（一队坦克）；分类图 = **`GFX_decision_category_sov_great_patriotic_war`**；两个**都是原版现成 sprite** ⇒ **零缺图风险、不进兜底名单** |
| 11 | **显示在决议面板** | 挂在 `hof_sov_mob_category` 分类下（分类 = 决议面板里的一个页签） |
| 12 | ⛔ **失败不惩罚苏联**（用户否决"取消也罚"丙案：「失败为什么还要惩罚苏联……你失败还惩罚是何意味」） | **刻意不写 `cancel_effect`** |

---

## §1 落地文件（4 个新文件 · 2 个新目录）

| 文件 | 编码 | 说明 |
| --- | --- | --- |
| `common/decisions/categories/hof_sov_mob_categories.txt` | UTF-8 **无 BOM** + CRLF | 分类（决议面板页签） |
| `common/decisions/hof_sov_mob_decisions.txt` | UTF-8 **无 BOM** + CRLF | 决议本体（任务形态） |
| `common/on_actions/hof_sov_mob_on_actions.txt` | UTF-8 **无 BOM** + CRLF | 开战当天立刻激活 |
| `localisation/simp_chinese/hof_sov_mob_l_simp_chinese.yml` | UTF-8 **带 BOM** + CRLF | 5 个本地化键 |

> ⭐ `common/decisions/` 与 `common/on_actions/` 在本次之前**在本 mod 里不存在**（新建两个目录）。
> ⚠️ `common/on_actions/*.txt` 是**多文件并集**加载（同名 on_action 会合并）⇒ **不会覆盖**原版 / R56 的任何 on_action。

---

## §2 机制逐字段 —— 为什么这么写

### §2.1 ⭐⭐ 「不可取消」为什么必须写 `available = { always = no }`

```
写 days_mission_timeout ⇒ 变成 mission
mission 的 available 默认【恒真】 ⇒ 恒真就立刻执行 complete_effect 然后消失
```

- 官方 wiki 原文：`available … defaults to always true, **making it disappear instantly**`。
- ⇒ **`available = { always = no }` 不是"可选加固"，是必须的**。它让任务：
  - 一直挂在决议栏里倒计时（**看得见**）
  - 玩家永远点不动（**点不了**）
  - 只有 `timeout_effect` 会执行
- ⭐ **原版同型先例**：`common/decisions/AFG.txt` 的 `AFG_radical_students_countdown`
  —— 它 `activation` 为真、`available` 为假，就是一个**"看得见点不了的倒计时"**（原版自己就这么写）。
- ⚠️ 同时必须**不写 `days_remove`**（写了会把任务降级回普通决议 ⇒ 可点、可中止）。已加断言。

### §2.2 目标：一国一条

```txt
target_array   = enemies                       # 与 ROOT 交战的国家
target_trigger = { FROM = { has_war_with = ROOT  exists = yes } }
target_root_trigger = { is_ai = no }           # 只在【玩家扮演苏联】时
```
- ⭐ **`FROM` = 目标国**，不是发起国（官方 wiki：*"Despite what the names imply, FROM is the target"*）。
- ⚠️ 触发器名是 **`has_war_with`** —— **`is_in_war_with` 在本版本不存在**
  （`F:\Hearts of Iron IV\documentation\triggers_documentation.md` **0 命中**）。已加断言。

### §2.3 失败条件与**节奏**（**v11 现行** · 2026-09-25 · 逐目标显式激活 · 29 日任务 + 1 日间隔）

#### §2.3.0 ⚠️ 术语对齐（2026-09-25 查证）—— **「已停止抵抗」和「投降」不是同一个东西**

| 中文界面里看到的 | 引擎里它是什么 | 出处 |
| --- | --- | --- |
| **已停止抵抗** | 触发器 **`has_capitulated`** | `localisation/simp_chinese/triggers_l_simp_chinese.yml`：`TRIGGER_HAS_CAPITULATED: "已停止抵抗"` · `TRIGGER_HAS_NOT_CAPITULATED: "未停止抵抗"` · `TRIGGER_NUM_DAYS_SINCE_COUNTRY_CAPITULATED: "上次停止抵抗至今的日数"`；`documentation/triggers_documentation.md` → `has_capitulated`「checks if the country has capitulated」 |
| **投降进度** | `surrender_progress`（连续量） | `TRIGGER_MORE_THAN_X_SURRENDER_PROGRESS: "投降进度高于$PERCENTAGE$"` · `WAR_OVERVIEW_CAPITULATION_PROGRESS: "投降进度"` |
| **投降**（战争收尾那一层） | 和平会议 / `CAN_SURRENDER` 系列 | `waroverview_l_simp_chinese.yml:33-38`：`CAN_SURRENDER_FACTION_MEMBERS`「只有当这场战争中该阵营的**全部主要成员国停止抵抗**时他们才会**投降**」 |

- ⭐ **结论：代码里只有一个国家级布尔 = `has_capitulated`，它的中文名就是「已停止抵抗」**；
  「**投降**」说的是**投降进度与和平机制**那一层 —— **停止抵抗 ≠ 投降**（上面阵营规则那句就是证据）。
- ⭐ `has_capitulated` 是**可逆**的：`WAR_OVERVIEW_CAPITULATE_STATUS`「若想移除其停止抵抗的状态，
  他们必须夺回本国的首都且投降进度不高于 X」⇒ 它**会在战争中来回去**，当长期判据不稳。
- ⚠️ 界面里另有一处把 `capitulated` 写成「已投降」（`WAR_OVERVIEW_FILTER_CAPITULATED: "已投降"`，
  那是打仗总览的**过滤器标签**）⇒ 中文里两种写法都被用过，但**代码概念只有一个**。
- 📌 **本项目旧稿里的「已投降」是自造词**，自本轮起统一写「**已停止抵抗**」。

```
# 六处写成【同一组】条件（为什么见 §2.3.1 / §2.3.2）
FROM = {
    exists = yes                                  # ① 国家存在
    has_war_with = ROOT                           # ② 与苏联处于战争状态
    any_owned_state = { always = yes }            # ③ v3：还【拥有】至少一个州（用户字面口径）
    num_of_controlled_states > 0                 # ④ v6：还【控制着】至少一个州（计数式）
    NOT = { has_country_flag = hof_sov_mob_mustered }  # ⑤ v5 一次性闸门：这个目标已经动员过了
}
# ⭐⭐ v7：cancel_trigger = 【裸条件】（拥有者作用域，照原版 INS/SIA）；三条都对苏联自己恒为假 ⇒ 永不误撤
cancel_trigger = { OR = { exists = no  NOT = { any_owned_state = { always = yes } }  NOT = { num_of_controlled_states > 0 } } }
```

- ⭐⭐ **2026-09-25 用户口径**：「**已没有任何州的已投降敌人可以不发兵，已投降但是还有州的可以发**」
  （⭐ **用户原话里的「已投降」= 中文界面里的「已停止抵抗」**，即触发器 `has_capitulated`，见 §2.3.0）
  ⇒ 这句话真正要判的是「**它还是不是一个活着的敌人**」。
- 🔴🔴 **v2 把它读错了** —— 读成了「判 `has_capitulated`（已停止抵抗）」，**引擎上不成立**：
  用户实测，内战赢下之后对手 tag（**D08**）**仍然在收 100 个师**，而控制台 `tag d08` 直接给出
  **`D08 has no provinces, switch would resign.`** ⇒ 它是**一个手里一个州都没有的壳子 tag**，
  而且**根本没有进入「已停止抵抗」状态**。
  ⇒ ✅ **v3 彻底删掉 `has_capitulated`**，判据换成纯粹的**领土判定** `any_owned_state = { always = yes }`
  —— 它把用户那条规则**完整包含**进来：**已停止抵抗且无州 ⇒ 挡掉；已停止抵抗但仍有州 ⇒ 照发**。
  ⭐ 附带好处：**领土判定天然可逆**，不必去跟踪 `has_capitulated` 那个会来回翻转的状态。
- ⭐ **`any_owned_state` 出处**：`F:\Hearts of Iron IV\documentation\triggers_documentation.md`
  —— 国家作用域的州列表触发器，写法 `any_owned_state = { <triggers> }`；本处判「**它还拥有任何一个州吗**」。
  ⚠️ 判的是 **owned（拥有）**，不是 controlled；⚠️ 引擎**没有** `num_of_owned_states`（只有 `num_of_controlled_states`）
  ⇒ **不能用计数写法**。
- ⭐⭐ **判据【六处一致】**（`verify-s2` §15h 逐处断言）：决策 5 处 + on_action 2 处。
  | 位置 | 作用 |
  | --- | --- |
  | `target_trigger` | 卡牌**该不该出现**（targeted decision 的目标筛选） |
  | `activation` | 卡牌**该不该挂着**（每日复查；`fire_only_once = no` ⇒ 到点后靠它自然重挂） |
  | `visible`（v3 新增） | 卡牌**该不该被看见** |
  | ~~`cancel_trigger`~~ ⛔ **v5：不参与** | 固定 `always = no`（见 §2.3.3）—— **`FROM` 在 mission 的 cancel 里不可靠** |
  | `timeout_effect` 的守卫 `if` | **双保险**：即使引擎照跑，也**不会误发部队** |
  | on_action 两处 `activate_targeted_decision` | 它**无视条件强制激活** ⇒ 必须自己校验目标 |
- ⛔⛔ **`cancel_trigger` 里不写 `FROM`**（v5 结论，详见 §2.3.3）：原版 525 个 mission 里 128 个用 `cancel_trigger`，
  ★ **只有 2 个用 `FROM` 且其中一处被注释掉** ⇒ **无先例**；实测写了就 **1 天一闪**。
  ✅ 固定成 `cancel_trigger = { always = no }`（原版 `AST.txt` 同形），「不再重挂」由 **⑤ 一次性闸门** 保证。
- ⚠️ **本轮唯一的新未知**：`target_trigger` / `visible` 变假时，引擎**会不会真的撤掉一个已经在跑的 mission**，
  离线**无法证实** ⇒ 所以才加了 `visible` 这一手；**最坏情况**也只是卡牌多挂 ≤29 天、
  **一兵不发**（守卫 `if` 兜住），到点后因 `activation` 为假而不再重挂。

#### 🚩 §2.3.1 2026-09-25 修的 bug：**幽灵卡 + 100 个师没落地**（⭐ 四版诊断，**第四版才对**）

> 用户三次实测，**每一次都推翻了上一版**：
> ① 「**决议栏会反复出现正在动员但是又消失**」
> ② 「**它是挂上了之后第二天就消失了而不是跑完二十九天消失，然后隔一天又出现**」
> ③ 「**？你那个bug没修好啊，现在还在动员师**」＋ 控制台截图 **`D08 has no provinces, switch would resign.`**

| | v1（❌ 作废） | v2（⚠️ 半对 · 已作废） | v3（⚠️ 半对 · 已作废，见 §2.3.2） |
| --- | --- | --- | --- |
| 用户看到 | 卡牌反复起落 | ➕ **「挂上后第二天就消失、隔一天又出现」** | ➕ **壳子 tag（无任何州）仍在收 100 个师** |
| 诊断 | 「停战后仍 `exists`、仍交战 ⇒ 每 30 天重挂一轮」 | ⛔ **`activation` 与 `cancel_trigger` 同时为真** ⇒ 每日 tick 互相打架 | ⛔ **判据本身错了**：D08 **从未进入「已停止抵抗」**，它是**没有省的壳子 tag** |
| 处置 | ~~照 v1 加 `cancel_trigger`（已停止抵抗 ⇒ 撤卡）~~ | ✅ **删掉 `cancel_trigger`** ⇒ ⭐ **闪的问题修好了**（用户已确认：倒计时现在正常跑进度条） | ✅ **`has_capitulated` → `any_owned_state`** ＋ **新增 `visible`**（⚠️ 不够：缺撤卡 + 缺「控制州」，见 §2.3.2） |

⭐⭐ **为什么「第二天消失、隔一天又出现」是 `cancel_trigger` 出问题的签名**：
`activation` 每天复查、`cancel_trigger` 也每天复查；两者**同为真**时，引擎一边激活
（`fire_only_once = no`）一边取消 ⇒ 卡牌在**每日 tick 里反复起落**，而不是等满 29 天。
**「跑完 29 天」才是超时路径**；第二天就没了 ⇒ 走的是**取消**路径（`activation` 仍为真 ⇒ 隔日又挂）。
⚠️ **在 targeted decision 的 `cancel_trigger` 里写 `NOT = { FROM = { … } }` 这种「取反的目标条件」**
疑似被判为**恒真** —— 引擎对 `cancel_trigger` 里 FROM 作用域的取反**没有可靠文档**，
本项目**没有能力离线证明**，所以**直接不用这条路**（v2 起整条 `cancel_trigger` 都不写了）。

⭐⭐ **另一条独立的隐患（v2 同一次修掉、v3 保留）**：`activate_targeted_decision` 的官方原文是
*"Activates the specified decision for the current scope, **ignoring triggers for the decision**."*
（`documentation\effects_documentation.md`）—— 它**无视条件强制激活**。
⇒ on_action 的两块都补上同一个三条件校验（否则任何一次开战事件都会给一个**已经不该出现**的
目标硬挂卡，随后再被撤掉 ⇒ 也会闪）。

⚠️ **用户提的另外两点，本项目如实登记（离线无法证实，不阻塞）**：

| 用户的说法 | 本项目的说明 |
| --- | --- |
| 「**D08 没有阵营**」 | 本决议**不查阵营**（`has_war_with` 与阵营无关）⇒ 有没有阵营不影响它。D08 是内战的临时 tag，**它还会不会出现只有游戏里能看** |
| 「**投降之后战争已经结束了，不应该是灭国了吗**」 | ⚠️ HOI4 里**停止抵抗 ≠ 停战、停止抵抗 ≠ 灭国**：停止抵抗只丢地，**tag 仍在、战争关系仍在**（§2.3.0 的 `CAN_SURRENDER` 系列是同一回事）。<br>⭐⭐ **用户给的截图把这件事定案了**：`D08 has no provinces` ⇒ 它正属于「**tag 还在、战争关系还在、手里一个州都没有**」这一类 ⇒ v3 的 `any_owned_state` **正好卡住它**，而且**不需要**它进入「已停止抵抗」 |

#### 🚩🚩 §2.3.2 v4（历史留档 · 2026-09-25 第四轮实测）：**幽灵卡 + 一百个师没落地**

> 用户原话：「**但是bug没修完，一百个师的那个还在有一个幽灵挂载，我确定现在是和平状态没有战争，
> 重进之后这个任务的国家图标是透明空白的只有一个外框，我试着让它跑完了，会再次按循环触发新的，
> 一百个师我不知道发到哪里了，tag d08 依旧是那个提示，苏联也没有获得这一百个师**」

⭐ 这次证词里有**三条**决定性信息，直接定案两件事：

| 用户看到的 | 推出的结论 | 出处 / 依据 |
| --- | --- | --- |
| **和平状态、没有战争**，卡还挂着；跑完又刷一个新的 | ⛔ **`target_trigger` / `visible` 变假【不会撤掉】已经在跑的 mission** —— 这是 v3 登记的「唯一新未知」，**答案是「不会」** | v3 只删了 `cancel_trigger` ⇒ 除了 29 天到点，**没有任何路径能撤卡** |
| 图标**透明空白只剩外框** | 目标是个**不成立的引用**（没省 / 已被打没影的壳子） | 卡片靠的是 `FROM` 这个目标，目标无效 ⇒ 旗帜画不出来 |
| **100 个师哪都没去**；苏联也没拿到 | ⭐ 「拥有州」**≠**「还活着」：被占领时 `owner` **不变** ⇒ `any_owned_state` 一直为真，而 D08 **控制 0 省** ⇒ `capital_scope` 与 `random_owned_controlled_state` **都落不了地** ⇒ `create_unit` 静默什么都不发。<br>📌 **「苏联没拿到」是设计如此** —— 这 100 个师本来就是**给敌方的**（卡名 =「敌方正在动员摩托化坦克师！」） | `tag d08` = `D08 has no provinces, switch would resign.` |

✅ **v4 的两处修改**：

1. **判据加一条**：`any_controlled_state = { always = yes }`（还**控制着**至少一个州）。
   出处 = `documentation/triggers_documentation.md` → COUNTRY 作用域「check if any of the states
   controlled by the scope country meets the trigger」；⭐ **原版用了 523 次、R56 用了 859 次**。
   ⇒ 没有立锥之地的敌人：**不挂卡 · 不发兵 · 也不会再去尝试落不了地的 `create_unit`**。
2. **`cancel_trigger` 加回来**，写成 **`activation` 的严格否定**（`NOT = { FROM = { <同一组 4 条> } }`）：
   - ✅ **原版先例**：`common/decisions/AFG.txt` 里 `cancel_trigger = { NOT = { FROM = { is_fully_controlled_by = ROOT } } }`，
     同形 30+ 处（**v2 当年怀疑它「恒真」是错的**，形状本身没问题）。
   - ⛔ **v2 的真正病根（现在才看清）**：v2 的判据在 D08 上**为假** ⇒ `cancel_trigger` 的**否定恒真**
     ⇒ 天天撤 + 天天挂 = 1 天一闪。**把 cancel 写成 activation 的否定，两者就不可能同真**。
   - ⇒ 目标**不存在 / 不交战 / 丢光州 / 丢光控制** ⇒ **卡牌当天就被撤掉**。

📌 **对当前这个存档的效果**：新版本一读档，`cancel_trigger` 每天复查 ⇒ **那张幽灵卡自己就没了**
（不需要控制台手工清）。
📌 **对今后所有「会自动结束的任务」的通用规律**（已升格为 `AGENTS.md` 硬性规则 18）：
**想要「条件不再满足就消失」，`cancel_trigger` 是必须的，而且必须写成 `activation` 的严格否定。**

#### 🚩🚩🚩 §2.3.3 v5（历史留档 · 2026-09-25 第五轮实测）：**又 1 天一闪 ⇒ 我上轮引错了先例**

> 用户原话：「**好了现在又变成疯狂闪现了，但是和之前的疯狂闪现不太一样，之前会跑一天再消失，
> 这个是挂载上去第二天就消失然后隔一天又挂载上去**」＋
> 「**我们真没有彻底解决这个问题的办法吗，比如说检测到这个国家没有州了就判定任务已完成然后
> 直到什么情况再触发检测它是否有州，否则就不挂**」

⭐ **病因（这次有数据，不是猜测）**：v4 我把 `cancel_trigger` 写成 `NOT = { FROM = { … } }`，并声称「原版 AFG 同形 30+ 处」。
**那个引用是错的** —— 本轮实测扫原版 + R56 全部 `common/decisions/*.txt`：

| 统计（原版） | 数 |
| --- | --- |
| 带 `days_mission_timeout` 的决议（= mission） | **525** |
| 其中带 `cancel_trigger` 的 | **128** |
| ★ **其中在 `cancel_trigger` 里用 `FROM` 的** | **2**（**其中一处还是被注释掉的**） |

⇒ **mission 的 `cancel_trigger` 里写 `FROM = { … }` 是没有先例的写法**；
v4 引的「AFG 30+ 处」其实全是**普通的州目标决议**（`type = state` 那一类），不是 mission。
⇒ 实测结果 = **天天撤 + 天天挂 = 1 天一闪**（和 v2 一模一样的签名）。

✅ **v5 换思路（照用户口径「判定任务已完成…否则就不挂」）**：

1. **`cancel_trigger = { always = no }`** —— 照原版 `common/decisions/AST.txt` 的
   `AST_foreign_overlord_reclaim_foothold_in_target_mission`（`cancel_trigger = { always = no }`）
   ⇒ **撤卡这条路彻底不参与** ⇒ **不可能再闪**。
2. 🆕 **一次性闸门**（判据第 ⑤ 条）：`NOT = { has_country_flag = hof_sov_mob_mustered }`，
   写在**与判据同一组的四处**；`timeout_effect` 的 `hidden_effect` **开头无条件**给目标盖章：
   ```
   FROM = { set_country_flag = hof_sov_mob_mustered }
   ```
   ⭐ **无条件**是关键：这一轮因为「没有立足之地」而没发兵，**也要盖章** ⇒ 否则它会一轮轮重挂。
   ⇒ **发过就不再挂** ⇒ **循环 + 幽灵卡一并终结**（不依赖引擎每日复查）。
3. **恢复条件 = 与它再次开战**：`on_action` 两处都先 `FROM/ROOT = { clr_country_flag = hof_sov_mob_mustered }`
   再校验+激活 ⇒ 语义 = **一场战争动员一次**。

📌 **两个可选变体（等用户裁决，判据 J）**：

| | 语义 | 怎么改 | 代价 |
| --- | --- | --- | --- |
| **甲（现行）** | **一场战争动员一次** | 现状 | 机制比原设计弱（原设计是 30 天一轮，10 国同盟 30 天刷 1000 个师 —— 用户当时自己就标了「可能过强」） |
| 乙 | **每 30 天一轮**（保留原设计） | 把盖章改成 `set_country_flag = { flag = hof_sov_mob_mustered days = 30 }`、并去掉 on_action 的清章 | ⚠️ **循环会回来**（只是变成 30 天一次而不是天天闪）；且壳子 tag 会每 30 天刷一次卡 |

⚠️ **仍未解释的一件事（如实登记）**：那张幽灵卡的**目标到底是谁**还没确认 —— 按「判据为真才会挂卡」推，
它应当是**拥有并控制 ≥1 个州、且与苏联交战**的国家（`tag d08` 报「无省」只说明它**控制 0 省**，
未必等于「没有任何州」）。⇒ 请用户在卡上**悬停看目标国名**；若是 D08，则说明两条领土判据对它都为真，
需要换判据（`is_fully_controlled_by = ROOT` 之类）。

#### 🚩 §2.3.4 v6（历史留档 · 2026-09-25 第六轮）：**卡面加「目标国名」＋ 判据换计数式**

> 用户原话：「**悬停显示为空，哦那判定换为省吧，说不定州有什么 bug 导致这个**」

⭐⭐ **「悬停显示为空」是我的锅**：我们的卡面文案里**从头到尾没有显示目标国名**（`_desc` 只写机制说明），
所以悬停当然什么都没有 —— 这不是「目标国没名字」。⇒ ✅ **本轮把目标国名做进卡面**：
`_desc` 与结果 tooltip 都加 `[FROM.GetName]`（⭐ **原版 targeted 决议的 `_desc` 就是这么写的**：
扫原版 `localisation/simp_chinese/*.yml`，用 `[FROM.GetName]` 的 `_desc` 有 **136 处**；
例：`NOR_prepare_state_alt_dem_desc: "…确保[FROM.GetName]能为战争做出贡献。"`）。
📌 **下次悬停就能直接看到「这张卡是谁的」** ⇒ 幽灵卡的身份不用再猜。

⚠️ **「判定换为省」这条要订正一下事实**：引擎里 **COUNTRY 作用域没有「任意省」触发器**
（扫 `triggers_documentation.md`：`province` 相关的 COUNTRY 触发器只有 **`controls_province = <具体省 id>`**，
其余 `is_capital` / `is_controlled_by` / `is_fully_controlled_by` 都是 **STATE** 作用域）。
⇒ 「按省判」只能用**写死的省 id**，没法表达「还有任意一个省」。
⇒ ✅ 于是改走**另一条引擎路径的等价判据**：**计数式**
`num_of_controlled_states > 0`（官方 triggers 文档：COUNTRY 作用域「check amount of controlled states」），
替换掉 v4/v5 的 `any_controlled_state = { always = yes }`。
⭐ 保留 `any_owned_state = { always = yes }`（用户字面口径「还有州」）。
⇒ 现行判据 = `exists` · `has_war_with` · `any_owned_state` · **`num_of_controlled_states > 0`** · `NOT(闸门 flag)`。

✅ **自检同步**（`verify-s2` §15h 增到 **8 项**）：新增 ① **负向 `any_controlled_state` 不得再出现**（防两套并存）
② ⭐ **卡面必须带 `[FROM.GetName]`**（把「能不能定位」变成断言）。

#### 🚩🚩🚩 §2.3.5 v7（历史留档 · 2026-09-25 第七轮）：**根因 = 我们用错了作用域**（前六轮全在错的地方打转）

> 用户第七轮原话：「**看到了国名，但这正是已经无法tag的D08的国名** 现在没有一天一闪了，在跑进度
> **跑完一轮后还会回来** 话说本来就应该国家不存在或者停止战争之后马上终止吧为什么要跑完一轮 图2实证就是它 全球目前没有进行中战争」

⭐ **决定性线索**：卡面 `[FROM.GetName]` 渲染出来的是「**苏维埃社会主义共和国联盟**」= **拥有者（苏联）自己的名字**，
而不是 D08 的「苏维埃社会主义共和国」⇒ **`FROM` 在那几个块里根本不指向目标**。

⭐⭐ **查原版同型决议，答案就摆在那里**：

| 原版决议 | 关键原文 | 说明 |
| --- | --- | --- |
| `INS.txt` `INS_start_limited_war_malaya` | `cancel_trigger = { OR = { exists = no  has_capitulated = yes  surrender_progress > var:global.… } }` | **裸条件**（拥有者作用域）；目标要靠 `var:limited_war_target = { … }` 才碰得到 |
| `SIA.txt` `SIA_start_limited_war_malaysia_burma` | 同上 + `var:limited_war_target = { has_capitulated = yes … }` | 同型 |
| `PER.txt` `PER_core_egypt_state` | `visible = { has_completed_focus = … }`（讲拥有者自己的事）· `target_trigger = { FROM = { … } }` · `remove_effect = { FROM = { add_core_of = ROOT } }` | ⭐ **只有 `target_trigger` 与效果里 FROM 才 = 目标** |

⇒ 我们前六轮把 `FROM = { … }` 塞进 `activation` / `visible` / `cancel_trigger` ⇒ **等于没写**：
- `visible` 恒真 ⇒ **永远不会撤卡**（幽灵卡挂了无数轮）；
- `activation` 恒真 ⇒ **引擎每天自动重挂**（跑完一轮又回来）；
- `cancel_trigger` 里那个否定 ⇒ 对目标为假时恒真 ⇒ **1 天一闪**（v2 / v4 两次）。

✅ **v7 的四处修改**：

1. **`activation = { always = no }`**（照原版 INS/SIA）⇒ **引擎不再自动重挂**；「开始」这件事完全交给我们自己的 on_action。
2. **`visible = { always = yes }`**（原版同形，不再塞 FROM）+ **`cancel_trigger` 写成裸条件 OR**（照原版 INS/SIA）
   ⇒ 目标「不存在 / 丢光州 / 丢光控制」**当场撤卡** —— 这正是用户说的「本来就该马上终止」。
   ⚠️ 三条都刻意选**对拥有者恒为假**的写法（`exists = no` · `NOT = { any_owned_state = … }` · `NOT = { num_of_controlled_states > 0 }`），
   ⛔ 不写 `NOT = { has_war_with = SOV }`（那条对苏联自己为真 ⇒ 会天天撤）。
3. **`selectable_mission = no`**（原版 **68 处**）⇒ 玩家点不动的正解；`available = { always = no }` 继续做双保险。
4. 🆕 **`on_action` 加 `on_daily` 每日清扫**：`every_country` + 不达标的盖 `hof_sov_mob_mustered` 章 +
   `SOV = { remove_targeted_decision = { target = PREV … } }` ⇒ **不依赖任何 FROM 绑定**，当天生效。
   ⭐ 这是回答用户「为什么要跑完一轮」的**兜底**：即使引擎侧的撤卡判断哪天再出岔子，清扫也会当天把卡收掉。

📌 判据仍然**四处一致**（`target_trigger` + `timeout_effect` 守卫 + on_action 开战两处）；`activation` / `visible` /
`cancel_trigger` 自 v7 起**不参与判据**（它们是拥有者作用域，判据放进去等于没写）。

✅ **自检**：`verify-s2` **§15h（9 项）** —— ⛔ **负向断言「不得再出现 `cancel_trigger`」** ＋
⛔ **负向断言「不得再出现 `has_capitulated`」** · `any_owned_state = { always = yes }` **恰 4 处**
（`target_trigger` / `activation` / `visible` / timeout 守卫）· **`visible` 正则**（必须带 `FROM` + `any_owned_state`）·
`timeout_effect` 守卫正则 · on_action 两处强制激活都带同一条件。

#### 🚩🚩🚩 §2.3.6 v8（历史留档 · 2026-09-25 第七轮追加）：**① `on_daily` 在本版本【不存在】 ② `fire_only_once = no` 让 mission 自己重排**

> ⚠️ **本节结论已被 v9 部分推翻**：`fire_only_once = yes` 是**错的**（它把用户要的「每月一轮」一起杀了）；
> `on_daily` 不存在、以及四个真钩子 —— 这两条**仍然有效**。现行版见 [`§2.3.7`](#-237-v9现行--2026-09-25-第八轮用户的「两层校验」-找回「每月一轮」-抓到一个结构性静默失效)。

> 用户第七轮的两条原话（同一次报告）：
> ① 「**倒计时仍然在进行，挂完一轮还会回来** 我尝试挑选了一个国家**开战并无条件白和**，倒计时依旧在进行，
> 倒计时结束后会再挂一轮新的，但是不会给它刷新那一百个师」
> ② （上一条已确认）「**跑完一轮后还会回来** …… 全球目前没有进行中战争」

⭐ **v7 只解决了「引擎不再自动重挂」，没解决「跑完一轮又回来」** —— 因为重挂来源**有两个**，v7 只掐掉了一个。
v8 补上第二个，并把 v7 那台**从未运行过**的清扫装置接上真正存在的钩子。

| # | 根因 | 证据（实测，不是推测） | v8 修法 |
| :-: | --- | --- | --- |
| ① | ⭐⭐ **`on_daily` 在 1.19.2 里【根本不存在】** ⇒ v7 那台「每日清扫」**一次都没跑过** | 扫**原版 17 个 + R56 21 个** `common/on_actions/*.txt` 的**顶层键**：存在 `on_weekly` / `on_monthly` / `on_peace` / `on_capitulation` / `on_uncapitulation` / `on_annex` / `on_civil_war_end` / `on_state_control_changed` / `on_startup` / `on_war_relation_added`；**不存在** `on_daily` / `on_yearly` / `on_war_relation_removed` | 清扫逻辑抽成 **scripted effect `hof_sov_mob_janitor`**，挂到**四个真实存在的钩子**上（见下） |
| ② | ⭐⭐ **`fire_only_once = no` 时 mission 会自己重排下一轮** | 用户实测「倒计时跑完 → 再挂一轮新的」；`activation = { always = no }` 已经**不可能**是驱动源 | **`fire_only_once = yes`**（原版同型 `INS` / `SIA` / `AST` / `PER` **全部**是 `yes`）⇒ 这张卡只跑一次；要再来一次**必须**由我们的 on_action 重新挂（= 与那个敌国**再次开战**） |

⭐⭐ **由此得到一个通用结论（已写进 `AGENTS.md` 硬性规则 18）**：
**这个版本里能用的周期钩子只有 `on_weekly` / `on_monthly`；事件型钩子是 `on_peace` / `on_annex` /
`on_civil_war_end` / `on_capitulation` / `on_uncapitulation` / `on_state_control_changed`；`on_startup` 开机一次。**
⛔ **`on_daily` / `on_yearly` / `on_war_relation_removed` 一个都不存在** —— 写了**不报错**，只是**永远不触发**（最贵的那种静默失效）。
📌 判据的权威出处 = **原版 + R56 的 `common/on_actions/*.txt` 顶层键实测**，⛔ **不是** wiki 的钩子列表
（离线 wiki 快照里那份列表**不含**存在的这一层事实，本项目已因此白写一版）。

✅ **v8 的三处落地**：

1. **`fire_only_once = yes`**（`common/decisions/hof_sov_mob_decisions.txt`）。
2. **新建 `common/scripted_effects/hof_sov_mob_effects.txt`**（⭐ 本项目第一个 `common/scripted_effects/` 文件；
   ⚠️ 该目录的文件**不需要任何外壳**，顶层直接写 `名字 = { … }` —— 出处 = 原版 `00_scripted_effects.txt` 头部示例）：
   ```text
   hof_sov_mob_janitor = { SOV = { every_country = { limit = { OR = { NOT = { has_war_with = SOV } … } } … } } }
   ```
   ⭐⭐ **作用域要点**：整段**不依赖任何 `FROM` 绑定** —— `every_country` 里作用域 = 那个国家自己（条件都在它身上判），
   撤卡是**拥有者的效果** ⇒ 先切 `SOV = { … }` 再用 `PREV` 指回目标。
   ⇒ 所以它**可以安全地挂在任何 on_action 上**，不管那个钩子的 ROOT / FROM 是什么。
   动作两件：① `set_country_flag = hof_sov_mob_mustered`（判据里有 `NOT = { has_country_flag = … }` ⇒ 不再挂新卡）
   ② `SOV = { remove_targeted_decision = { target = PREV  decision = hof_sov_mob_war_countdown } }`（撤掉正在跑的那张卡）。
3. **`common/on_actions/hof_sov_mob_on_actions.txt`：`on_daily` 整块删除**，改为四个**真实存在**的钩子
   全部调用 `hof_sov_mob_janitor = yes`：**`on_peace`**（白和 ≠ 停战协议，和平事件照触发）·
   **`on_annex`** · **`on_civil_war_end`** · **`on_weekly`**（兜底：漏掉的事件型钩子最多拖 7 天，但**一定**会被清掉）。
   ⛔ **故意不挂 `on_war_relation_removed`**（该钩子在本版本不存在）；`on_peace` 已经覆盖「双方停战」这条主路径。

📌 **判据本身零改动**：仍然是**四处一致**（`target_trigger` / `timeout_effect` 守卫 / on_action 两处
`activate_targeted_decision`）+ v7 那三条拥有者作用域的写法。v8 改的是**「什么时候开始 / 什么时候清扫」**，
不是**「谁算敌人」**。

✅ **自检**（`verify-s2` **§15h**，在本轮之前那批断言之上新增 4 类）：① ⛔ **负向断言 `on_daily` 出现次数 = 0**（防回退）② ⭐ **`fire_only_once = yes` 必须存在**
③ ⭐ 四个钩子各 **1 次** `hof_sov_mob_janitor = yes` ④ ⭐ 新文件存在 + **无 BOM** + 含
`every_country` / `set_country_flag` / `remove_targeted_decision` / `num_of_controlled_states`。

> 🚩🚩 **本轮真踩的坑（工具层）**：新文件 `common/scripted_effects/hof_sov_mob_effects.txt` **被写成了带 BOM**，
> 被 `verify-s2` §15 的编码红线当场抓住（**游戏不报错，但脚本 `.txt` 带 BOM 违反硬性规则 3**）。
> ⇒ 📌 **凡是新建的脚本 `.txt`，创建后立刻验前三字节**（`EF BB BF` = 有 BOM ⇒ 必须剥）。
> ✅ 顺手给 `verify-s2` 加了**失败清单落盘** `build/verify-s2-failures.txt`（真 UTF-8）——
> 因为**控制台输出编码（GBK）会把 `✗` 和中文一起替换成 `?`**，从重定向日志里**根本分不出 Pass 与 Fail**。

#### ⭐⭐⭐ §2.3.7 v9（历史留档 · 2026-09-25 第八轮）：**用户的「两层校验」+ 找回「每月一轮」+ 抓到一个结构性静默失效**

> 用户原话：「**不对，你这写的意思是开战之后只会发一百个师吗，但是我希望开战期间每个月都给敌方发**……
> 等等，我想到了一个方式，**我们做两层校验呢？首先苏联是玩家控制，且正在战争中，再开始检测敌方国家是否有州**，
> 这不就解决我们的问题了吗」

⭐⭐ **用户两件事都说对了，而且第一件是我的错**：
1. 🔴 **v5 那个「无条件盖章」（`hof_sov_mob_mustered`）把节奏改成了【一次性】** —— 那是**我自己选的**，
   而且**没有报告**（判据 J 的反面教材；`docs/99` §54 六 那张表里还写着「一次性闸门」）。
   ⇒ 用户要的是**开战期间每月一轮**。
2. ⭐⭐ **「两层校验」正是正确的架构**（而且原版逐字有先例）。

| 层 | 作用域 | 写什么 | 在哪几个块里 |
| :-: | --- | --- | --- |
| **层 1** | **拥有者层（苏联自己）** | `is_ai = no`（玩家控制）· `has_war = yes`（还在打）· 「苏联自己没了立足之地 ⇒ 撤卡」 | `activation` · `visible` · `cancel_trigger` —— ⛔ **裸条件，绝不写 `FROM`** |
| **层 2** | **目标层（那个敌国）** | 「还交战 / 还有州 / 还有立足之地 / 尚未被清扫」 | `target_trigger` · `timeout_effect` 的分支守卫 · `hof_sov_mob_janitor` · on_action 两处强制激活 —— ⭐ **`FROM` 才 = 目标** |

⭐⭐ **原版先例（比我上一版引的 AFG 更贴）**：`common/decisions/ETH.txt` 的
**`ETH_time_based_war_escalation_mission`** —— 一张**周期性**的战事倒计时，与我们要的完全同形：

```text
ETH_time_based_war_escalation_mission = {
	allowed = { original_tag = ETH }
	available = { hidden_trigger = { always = no } }     # 「看得见、点不了」的正解写法
	activation = { has_war = yes  has_global_flag = …  check_variable = { … } }   # ⭐ 拥有者层裸条件
	visible = { hidden_trigger = { has_global_flag = … } }
	cancel_if_not_visible = yes
	fire_only_once = no                                  # ⭐ 周期重排 = 反复计时
	selectable_mission = no
	days_mission_timeout = ETH_war_escalation_length
	timeout_effect = { ETH_escalate_the_war_effect = yes  … }
}
```

⇒ **`fire_only_once` 的语义被澄清了**：它管的是「**要不要周期重排**」，**不是「防幽灵」的开关**。

| 值 | 含义 | 原版例 |
| :-: | --- | --- |
| `no` | **周期型**（跑完一轮 ⇒ 引擎自动重排下一轮，只要 `activation` 仍成立） | `AFG_radical_students_countdown`（365 天一轮）· **`ETH_time_based_war_escalation_mission`** |
| `yes` | **一次性**（跑完就结束） | `INS` / `SIA` / `AST` / `PER` 那些「只跑一次的倒计时」 |

✅ **v9 的三处修改**：

1. **`activation = { is_ai = no  has_war = yes }`** —— 层 1 拥有者层裸条件（原版 ETH 同形）。
   ⇒ 引擎只在「玩家控制的苏联正在打仗」时维持/重排这张卡。
2. **`fire_only_once = no`** ⇒ 到点后**引擎自动重排下一轮** = **每 29 天一轮**（= 用户要的「每月一轮」）。
3. **`timeout_effect` 删掉那个「无条件盖章」** —— 盖章改由清扫做，**且只在「目标已不算数」时做**
   （`hof_sov_mob_mustered` 的语义：`已经发过一次` ⇒ **`已被清扫`**）。
   ⭐ 清扫同时变**双向**：不达标 ⇒ 盖章 + 撤卡；**达标 ⇒ 清章**（自愈 ⇒ 它重新变回有效时周期自动恢复）。
4. **`cancel_trigger` 加第 4 条 `NOT = { has_war = yes }`**（层 1：苏联和所有人都停战了 ⇒ 当场撤卡）。

#### 🚩🚩🚩 §2.3.7b 顺手抓到的**结构性静默失效**（本轮最值钱的一条）

⭐ **起因**：改 `activation` / 清章时我做了一次「**块首局部替换**」，**留下了孤儿行**：
原 `limit = { … }` 的残余（`is_ai = no` + 一个 `FROM = { … }`）和一个**多余的右括号**
⇒ `on_actions = { }` 的外壳在 `on_war_relation_added` 之后**提前闭合**，
**四个清扫钩子全部落在外壳【外面】⇒ 引擎不认** —— 症状与 v7 的 `on_daily` **一模一样**（那台清扫一次都不会跑）。

🔴🔴 **而旧的断言全绿**：`verify-s2` 只数「钩子出现 1 次」「`hof_sov_mob_janitor = yes` 出现 4 次」
—— **它们确实各出现 1 次，只是不在外壳里**。

✅ **新增守卫（`verify-s2` §15h-3c）**：对 `on_actions` 文件做**逐行花括号深度走**——
① 末值必须 0 ② 任何一行都不许为负 ③ **五个钩子必须正好落在 depth 2**（外壳 1 + 钩子 1）。
⛔ 只数「出现次数」是不够的：**「写对了」与「写在该在的地方」是两件事**。
✅ **已做负向测试**：故意在文件末尾加一个 `}` ⇒ `verify-s2` **当场 exit 1**；还原后 exit 0（字节一致）。

📌 **可复用教训（已进 `AGENTS.md` 硬性规则 18）**：
**嵌套块只替换「块首」时，剩下的原块体会变成孤儿行** ⇒ 改完必须跑「花括号深度走」，
而不是只看「括号总数相等」（本项目总括号数在事故后是 `38 / 39`，一眼能看出，但**如果我把替换写成 3 换 3 就看不出了**）。

#### §2.3.8 v10（历史留档 · 2026-09-25）：清扫把有效敌人误判为失效

清扫效果 `hof_sov_mob_janitor` 的 `every_country` 遍历中，旧版把 `NOT = { tag = SOV }` 写进了「目标失效」的 `OR`。对每一个敌国，这个条件恒真，因此不论它是否交战、有州、有控制州，清扫都会给它盖 `hof_sov_mob_mustered` 章，并撤掉倒计时。`else` 清章分支也永远到不了。任务随后又因周期配置被重新评估，造成反复出现、消失；即使到点，守卫也会被错误的章挡住。

现把 `NOT = { tag = SOV }` 移到 `every_country` 的 `limit`，只用于排除决议拥有者。失效 `OR` 只保留三项：不再与苏联交战、没有拥有州、没有控制州。有效敌国走 `else` 清章，继续每轮发兵。`build/verify-s2.ps1` §15h 现检查这一层级关系，防止只凭关键词计数漏掉同类逻辑错误。

语法与作用域依据：[Paradox Wiki《Decision modding》](https://hoi4.paradoxwikis.com/Decision_modding) 的目标决议说明，以及本机原版 `F:/Hearts of Iron IV/common/decisions/ETH.txt` 的周期任务。用户随后实测 **v10 仍反复挂卡**，见 §2.3.9。

#### §2.3.9 v11（2026-09-25）：由每个敌国自己的状态控制下一轮

用户实测：D08 每隔数日闪现；对保加利亚宣战时，D08 和保加利亚同时倒计时；与保加利亚白和后，两国的卡先撤、随后又同时重现。这推翻了 v10 的“仅修清扫条件即可解决”判断。D08 是苏联内战后没有可控制省份的临时 tag，`tag d08` 报 `D08 has no provinces, switch would resign.`，见 §2.3.1。

关键结构缺口：v9/v10 的 `activation = { is_ai = no has_war = yes }` 只检查**苏联是否仍在任何一场战争**，而 `fire_only_once = no` 允许引擎自动重排。苏联与其他国家交战时，这两个字段无法表达“**该目标**仍与苏联交战并控制州”。`target_trigger` 和清扫效果即使正确，也无法保证已经被引擎排定的任务不会先出现再撤。保加利亚白和后跟 D08 一起重现，正符合这个缺口。

现行流程：

1. 决议的 `activation = { always = no }`、`fire_only_once = yes`，关闭引擎自动挂载与重排。`target_trigger` 和到期守卫继续保留。
2. `on_war_relation_added` 仍在开战当天校验目标，合格才调用 `activate_targeted_decision`。
3. 29 日任务到期且目标仍合格时，给目标设置 2 日 `hof_sov_mob_waiting` 标记，并安排 1 日后的隐藏事件 `hof_sov_mob.1`。事件重新检查目标是否与苏联交战、是否拥有并控制州、苏联是否由玩家控制；合格才显式激活下一轮。**每个目标各自循环**。
4. `on_weekly` 只在苏联作用域调用清扫和补挂。补挂同样逐目标校验，负责旧存档与目标恢复控制州的情形；已激活的任务会被引擎拒绝重复激活，`waiting` 防止在轮间 1 日抢跑。其余事件钩子只清扫。

引擎依据：本机 `documentation/effects_documentation.md` 对 `activate_targeted_decision` 明确写明：忽略正常条件、冷却与 `fire_only_once`，但无法重复激活界面中已经运行的任务；原版 `common/decisions/JAP.txt` 也用 `target_array = enemies` 与 `target_trigger = { FROM = { ... } }`。隐藏事件格式参照本项目已有的 `events/hof_ic_events.txt`。本机制的运行效果仍待游戏内验证，见 `docs/99` §58。

### §2.4 开战当天立刻生效

⭐⭐ **第一件事：必须套 `on_actions = { }` 外壳。**
本项目 2026-09-23 实测：**原版 `common/on_actions/` 下 17 个文件全部套壳、0 个不套**；
R56 的 **21 个也全部套壳**。⇒ 顶层直接写 `on_war_relation_added = { }` 会**静默不触发**。

⭐ 同时实测：**同名 on_action 跨多文件出现是常态**（`on_war_relation_added` 在**原版 12 个文件里都有**、
`on_actions` 这个壳名本身 17 个文件都有）⇒ 引擎是**合并**所有文件里的同名块
⇒ **新增自己的 on_actions 文件不会覆盖原版 / R56**（这是本项目选"新建文件"而不是"改原版文件"的依据）。

```txt
on_actions = {
    on_war_relation_added = {
        effect = {
            # ① 玩家扮演的苏联【主动】宣战 ⇒ 目标 = FROM（守方）
            if = { limit = { tag = SOV  is_ai = no }
                   activate_targeted_decision = { target = FROM decision = hof_sov_mob_war_countdown } }
            # ② 玩家扮演的苏联【被动】被宣战 ⇒ 目标 = ROOT（攻方）
            if = { limit = { FROM = { tag = SOV  is_ai = no } }
                   FROM = { activate_targeted_decision = { target = ROOT decision = hof_sov_mob_war_countdown } } }
        }
    }
}
```
- ⛔ **不能用 `on_war`** —— ⭐ **原版 `00_on_actions.txt` 自己的注释就是原文出处**：
  *"on_war is fired when a country goes to war against anyone and is **not fired again** when it enters
  war against another country unless it went to peace first"* ⇒ 多国同时开战时只响一次。
- ⭐ `activate_targeted_decision` **只对 mission 有效**（官方 wiki：*"Only works on **missions**"*）
  —— 我们这条**正是 mission** ⇒ 走得通。
- ⚠️ 纯数据路线（只靠 `activation` 每日复查）也能跑，但会**晚一天**；本 effect 是"当天"。

### §2.5 师编制（⭐ **2026-09-25 已改：20 营 + 2 个支援连**）

> 🚩 **用户 2026-09-25 口径**：「**100 个师的那个炮兵是错的，移除炮兵，增加两个支援连，工兵连和摩托化侦察连**」

**现在的编制**（`common/decisions/hof_sov_mob_decisions.txt`）：

| 部分 | 内容 |
| --- | --- |
| `regiments` | `medium_armor` ×12（x 0–2 · y 0–3）+ `motorized` ×8（x 3–4 · y 0–3）= **20 营** |
| `support` | `engineer = { x = 0 y = 0 }`（**工兵连**）+ `mot_recon = { x = 0 y = 1 }`（**摩托化侦察连**）|

- **5×5 是营级网格的硬上限**：`common/defines/00_defines.lua` 实测
  `MAX_DIVISION_BRIGADE_WIDTH = 5` · `MAX_DIVISION_BRIGADE_HEIGHT = 5`
  （对照：原版 `history/units/` **全库 x 最大 4 · y 最大 4**）⇒ 20 营落在 y = 0..3，**第 5 行空着**。
- ⚠️ **支援连走【另一个网格】**：本 mod `zz_hof_ic_defines.lua` 写的是
  `MAX_DIVISION_SUPPORT_WIDTH = 1` · `MAX_DIVISION_SUPPORT_HEIGHT = 7`
  ⇒ **x 只能是 0**、y 依次 0 / 1。
  ⭐ 原版先例：`history/units/AUS_1936.txt` 就是
  `engineer = { x = 0 y = 0 }` + `recon = { x = 0 y = 1 }` —— 不是我们自创。
- ⭐ **两个支援连的 id 出处**（全部逐字核过）：
  · `engineer` = `common/units/engineer.txt` → 中文名「**工兵连**」（`unit_l_simp_chinese.yml` L393）
  · `mot_recon` = `common/units/recon.txt` **L93**（注释 `#trucks, motorcyles, ill-placed cars`，
    `need = { motorized_equipment = 20 }`）→ 中文名「**摩托化侦察连**」（同 yml L385）
    ⛔ **不叫 `motorized_recon`** —— 那个 id 不存在（同文件里另有 `recon` 骑兵侦察分队 /
    `armored_car_recon` 装甲车侦察连 / `light_tank_recon` 轻型坦克侦察连，都不是我们要的）。
- ⭐ **列序也对**：原版装甲师是"装甲在左、摩托化在右"
  （`GER_1936.txt` Panzer-Division：`light_armor` x=1、`motorized` x=2；
  `ENG_1939.txt` Armour Division：`medium_armor` x=0、`motorized` x=3）—— 与本线 x 0–2 / x 3–4 一致。

> 📎 **旧记录（2026-09-23，已作废）**：原编制 12 + 8 + 5 = **25 营占满 5×5**，
> 其中 `artillery_brigade` 混编在 `regiments` 网格的合法性当时实测过（原版
> `history/units/BEL_WW_1936.txt` 的 `artillery_brigade = { x = 3 y = 0 }` 与步兵同格、
> `common/national_focus/china_shared.txt` 的 `{ x = 2 y = 1 }` ⇒ **y 不受「只能第 0 行」限制**）——
> 那个结论**仍然成立**，只是**这条决议现在不用炮兵了**。

### §2.6 装备：免费 + 按对方自己的科技上限

- `start_equipment_factor = 1`（默认值就是 1，写出来只为显式）⇒ **满装备、不扣库存**。
- ⭐ **模板不受对方科技限制** —— `regiments` 里写的是 **sub-unit 名**（定义在 `common/units/*.txt`，全局数据）；
  科技只通过 `enable_subunits` / `enable_equipments` 控制**玩家界面能不能选**。
- ⭐ **装备由引擎自动配** —— 官方 wiki `create_unit` 原文：
  *"**Created equipment will be the latest available to the country.**"*
  ⇒ **不会"造不出"，只会"降级"**（按对方自己科技能拿到的最好型号）。
- `start_experience_factor = 1` ⇒ **师的经验度 = 第 4 级（Veterans / 久经沙场）= 满经验**。
  - 🔄 **2026-09-25 用户先裁【3.0（Seasoned）】，同日又改为【第 4 级，1.0】**（原值 0.5 = 第 2 级 Regular）。
  - ⭐ **为什么是 1（= 1.0）**：`defines` 的 `UNIT_EXP_LEVELS = { 0.1, 0.3, 0.75, 0.9 }`
    （注释原文 *"Experience needed to progress to the next level"*）⇒ **5 级**：
    `0` Green / 乌合之众 · `1` Trained / 训练初成 · `2` Regular / 训练有素 = **[0.3, 0.75)** ·
    `3` Seasoned / 经验丰富 = **[0.75, 0.9)** · **`4` Veterans / 久经沙场 = [0.9, 1.0]**。
    ⭐ 等级名逐字对得上原版本地化：`core_l_english.yml` 的 **`UNIT_LEVEL_4: "Veterans"`** /
    `core_l_simp_chinese.yml` 的 **`UNIT_LEVEL_4: "久经沙场"`**。
  - ⭐ **`1` 有先例**：原版 + R56 的 OOB 里共 **90 处** 写 `start_experience_factor = 1`。
  - ⛔ **不能照字面写 `4`** —— 该字段是 **0–1 的系数**，不是等级序号；
    界面按**百分比**显示（`SWE_swedish_shooting_movement_tt`「初始经验从 §Y10%§! 提高到 §Y30%§!」）。

### §2.7 模板只建一次

- 用**目标国自己的国家标记** `hof_sov_mob_template_1941` 去重 ⇒ 每国一份模板，
  之后每一轮（每 30 天）直接复用，不会每轮重建。
- 模板名 **「1941摩托化坦克师」**（🔄 2026-09-25 用户命名；原名 `hof_sov_mob_1941`）；
  `create_unit` 里的字符串**必须引用同一个名字**（已加断言）。
  - ⚠️ 名字是**中文字串**，写在两个地方（`division_template = { name = … }` 与
    `create_unit` 的 inline spec `division_template = \"…\"`）—— 两处必须逐字一致。
  - ⚠️ 模板名是**直接当显示名用**的（会出现在对方的编制器里），**不走本地化键**。
  - 去重用的国家标记仍叫 `hof_sov_mob_template_1941`（内部 id，与显示名无关）。

### §2.8 ⭐⭐ 本轮被自检抓出的一个【真错】：`on_actions` 没套外壳

- 第一版 `hof_sov_mob_on_actions.txt` **顶层直接写 `on_war_relation_added = { }`**（照 `docs/03` §3.6 的示例）。
- 事后实测发现：**原版 17 个 on_actions 文件【全部】套 `on_actions = { }`，0 个不套**；R56 21 个也全部套。
  ⇒ 不套外壳时那个 on_action 会**静默不触发**（开战当天不会激活决议，而且不一定进 `error.log`）。
- ✅ 已改正，并把「必须有 `on_actions` 外壳」写进 `verify-s2` **§15e** 的断言里。
- 📌 **教训**：`docs/03-scripting.md` 的示例**是对的**，是本实装漏了；
  但这也说明**「照自己的文档写」不能替代「照原版全库普查一遍」** ——
  本条和 §49.2 的另外三条同源：**能现场数出来的（17/17 对 0/21）就别靠记忆。**

---

## §3 本地化（5 个键）

| 键 | 文本 |
| --- | --- |
| `hof_sov_mob_category` | 敌军动员 |
| `hof_sov_mob_category_desc` | 与苏联交战的敌国正在动员装甲部队。每一条倒计时对应一个敌国。 |
| `hof_sov_mob_war_countdown` | **敌方正在动员摩托化坦克师！**（用户指定） |
| `hof_sov_mob_war_countdown_desc` | 机制说明（倒计时 → 100 个师 → 失败条件 → 不可点选/中止） |
| `hof_sov_mob_result_tt` | §R敌方动员完成：该国获得 100 个「摩托化坦克师」师。§! |

> ⚠️ **文案口径（本项目第一次为"决议"写文案）**：
> `_desc` 写的是**机制说明**，**不冒充史实、不引历史评价**
> ⇒ **不属于硬性规则 9 的适用范围**（那条管的是"国策/事件描述必须用原文节选"，
> 因为那些在陈述历史；本文件在陈述规则）。
> ⭐ 这条口径记在这里当先例：**以后写决议 / 决议类文案，先判"它在陈述历史还是陈述规则"。**

---

## §4 与查证报告（`docs/96`）的差异

| 项 | `docs/96` §5 的原骨架 | **实装值** | 原因 |
| --- | --- | --- | --- |
| 倒计时字段 | `days_remove = <N>`（甲案） | **`days_mission_timeout = 29`**（乙案） | 用户裁决 ①：乙案才能保证"点不了、中止不了" |
| 效果字段 | `remove_effect` | **`timeout_effect`** | 乙案的对应物 |
| 模板名 | `<模板名>` 占位 | **「1941摩托化坦克师」** | 🔄 2026-09-25 用户命名（原名 `hof_sov_mob_1941`） |
| 兵种 | 未定 | `medium_armor` / `motorized`（营）＋ `engineer` / `mot_recon`（支援连） | ⭐ 2026-09-25 用户改口径：**移除炮兵、加两个支援连** |
| `cancel_effect` | 「或者：给苏联一个半途而废的惩罚」 | **不写** | 用户裁决 ⑫ |
| 数值面 | 未定 | **无任何 modifier**（本决议不给苏联挂数值） | 需求里没有数值项 |

---

## §5 ⬜ 必须游戏内实测（硬性规则 5 / 6）

> `docs/96` §6 原有 5 项 **全部仍然有效**，下面是**本实装新增/细化的项**。

| # | 要验的 | 怎么看 |
| :-: | --- | --- |
| 1 | ✅ **【已有答案 · 2026-09-25 第四轮实测】`target_trigger` / `visible` 变假【不会】撤掉已在跑的 mission**（所以 v4 才把 `cancel_trigger` 加回来） | 现已由 `cancel_trigger` 承担；本条留作历史记录 |
| 2 | **`available = { always = no }` 时任务卡片长什么样** | 决议栏里是否"看得见、点不了"，倒计时天数是否正常显示 |
| 3 | ⭐⭐ **v9：到点后【应该】自动重排下一轮（= 开战期间每 30 天一轮）** `fire_only_once = no` + `activation = { is_ai = no  has_war = yes }` | 记下第一次发兵的日子 ⇒ **第 30 天前后应再出现一张新的 29 天倒计时**（同一个敌国）；<br>⚠️ v8 的 `= yes`（一次性）**已被推翻** |
| 4 | **`on_war_relation_added` + `activate_targeted_decision` 是否当场生效** | **开战当天**看决议栏（对照：等一天再看，区分"当天"与"次日"） |
| 5 | **首都失守时的兜底分支是否真的走 else** | 先打掉对方首都再等倒计时结束，看 100 个师落在哪 |
| 6 | **给一个没有装甲科技的小国发兵会不会报错** | 看 `日志/error.log` + 在编制器里看那 **20 格营位 + 2 格支援位**是否完整（有没有被丢掉几营） |
| 7 | **装备到底扣不扣对方库存** | 记录发兵前后对方的装备库存 |
| 8 | ⭐ **`30 天一轮`是否过强** | 这是用户要"先做出来看效果"的核心 —— 一个 10 国同盟 30 天就能刷出 **1000 个师** |
| 9 | ⭐⭐ **2026-09-25 修的那个 bug 是否真修好**（**三版诊断，第三版才对**） | 再打一场内战 / 把对方打到只剩壳子：<br>① **已无任何州**（无论是否已停止抵抗）⇒ 卡牌**应当消失**、**不再每天起落**、**一兵不发**<br>② **已停止抵抗但仍有州** ⇒ 卡牌**应当继续**、照发 100 个师（**用户口径**）<br>③ 全程**不应**再出现「第二天消失、隔一天又出现」 |
| 10 | ⭐ **v3 新增的 `visible` 到底有没有用**（它和 `target_trigger` 是**两个独立的杠杆**） | 把对方打到**只剩壳子**（无任何州）的那一刻：看卡牌是**当天消失**、还是拖到 29 天满。<br>⚠️ 离线**推不出**——引擎「mission 跑到一半、`visible` / `target_trigger` 变假」的行为**没有可靠文档** |
| 11 | ⭐⭐⭐ **v8：白和 / 停战之后卡片【是否当场消失】**（用户第七轮的原症状：白和了倒计时还在跑） | 打一场小仗后**无条件白和**。预期：`on_peace` 钩子当天触发清扫 ⇒ **卡牌立刻消失**；<br>最坏情况 = `on_weekly` 兑底（≤7 天），**但不应再跑完一整轮**。⚠️ **看 `日志/error.log` 里有没有 `hof_sov_mob_janitor` / `on_peace` 的错误行** |
| 12 | ⭐⭐ **v8：与同一敌国【再次开战】会不会重新挂卡** | 白和 ⇒ 过几天再宣战 ⇒ 应当重新出现 29 天倒计时（on_action 先 `clr_country_flag` 清章再强制激活） |
| 13 | ⭐⭐⭐ **v9：节奏是不是「开战期间每 30 天一轮」** | 打一场长仗（> 60 天，不要白和）⇒ 应当按 29 天周期**反复**发兵，直到战争结束（= 用户口径「每个月都给敌方发」） |
| 14 | ⭐⭐⭐ **v9：那张卡是不是真的在清扫（不是只写在文件里）** | 白和之后看 `文档\Paradox Interactive\Hearts of Iron IV\logs\error.log`：<br>① 若钩子落在外壳外，引擎**不会报错**，只能靠「卡不撤」反向发现；<br>② ⭐ 现在的 `verify-s2` **§15h-3c** 会当场报出「钩子不在外壳里」（已有负向测试） |

---

## §6 本项目新增的自检（`build/verify-s2.ps1` **§15** · 失败项 0 · **本次执行 996 条检查**（含逐人/逐节点循环））

抓的都是**静默失效**（错了在游戏里只会"什么都不发生"）：

- 编码红线（3 个 `.txt` 无 BOM / `.yml` 带 BOM + 文件名 + 首行）
- **分类块与决议块同名挂载**（实测原版 `decisions/*.txt` 里 `decision_category = ` **0 次** ⇒ 靠顶层块名关联）
- 关键字段齐全（`target_array` / `target_root_trigger` / `target_trigger` / `days_mission_timeout = 29` /
  `available = { always = no }` / `selectable_mission = no` / **`fire_only_once = yes`** / `timeout_effect`）
  ⭐ **`cancel_trigger` 自 v7 起【必须有】但必须是【裸条件 OR】**（拥有者作用域 · 照原版 INS/SIA · 见 §2.3.5）
- **负向断言**：不得出现 `is_in_war_with` · 不得出现 `days_remove`
  · ⭐ **`cancel_trigger` 里不得再出现 `FROM`**（前六轮 1 天一闪与幽灵卡的根因）
  · 🔴 **不得再出现 `has_capitulated`**（v2 那条错误判据 · 见 §2.3.1）
  · 🔴 **不得出现 `on_daily`**（v8：本版本（1.19.2）**没有**这个钩子，清扫会静默不跑）
- **师编制 20 营**（12 / 8）· 无叠格 · 全部落在 5×5 内 · **无预期外兵种**（⭐ 已移除的 `artillery_brigade` 再出现就会被抓到）
- ⭐ **支援连**：恰好 `engineer`（工兵连）+ `mot_recon`（摩托化侦察连）两个、各 1 个、不叠格、落在 1×7 支援栏内
- ⭐⭐ **判据在各处的分布（v8 实况）**：`any_owned_state = { always = yes }` 与 `num_of_controlled_states > 0`
  在决策文件里**各 3 处**（`target_trigger` / `cancel_trigger` / timeout 守卫）· on_action 侧**各 2 处**
  —— `activation` / `visible` / `cancel_trigger` **都是拥有者作用域**，判据不写进去（见 §2.3.5）
- ⭐ **v8 on_action**：两处 `activate_targeted_decision`（开战先清章 + 校验强制激活）＋ **四个真钩子各一次**
  `hof_sov_mob_janitor = yes`（`on_peace` / `on_annex` / `on_civil_war_end` / `on_weekly`）
- ⭐⭐ **v9 结构守卫（§15h-3c）**：`on_actions` 文件的**逐行花括号深度走** —— 末值必须 0 · 任何一行不许为负 ·
  **五个钩子必须正好在 depth 2**（外壳 1 + 钩子 1）。🚩 这是抓到「钩子写对了但在外壳外面」的唯一手段（只数次数会全绿）
- ⭐ **v9 节奏**：`fire_only_once = no` 必须存在（`yes` ⇒ 退化成一次性）· `activation` 必须是层 1 拥有者条件
- ⭐ **v8 scripted effect**：`common/scripted_effects/hof_sov_mob_effects.txt` 存在 · **无 BOM** ·
  `hof_sov_mob_janitor` 定义齐全（`every_country` + `set_country_flag` + `remove_targeted_decision` + 判据）
- ⭐ **on_action 侧**：两处 `activate_targeted_decision` 的 `limit` 都带同一个三条件校验
  （`activate_targeted_decision` **无视条件强制激活** ⇒ 不校验就会硬挂卡）
- `create_unit` 引用的模板名与 `division_template.name` 一致 · `count = 100` · 落在 state 作用域 · 有兜底分支
- on_action 三项 · 未误用 `on_war`
- 5 个本地化键齐全
- 引用的 2 个 icon 能解析到 sprite 定义

> 🚩🚩 **写这一节时真踩的坑**：负向断言 `-match 'is_in_war_with'` **把文件头解释
> "为什么不能用 is_in_war_with" 的【注释】也当成实际代码**，自己把自己判失败。
> ⇒ **教训：负向文本断言必须先剥注释**（`[regex]::Replace($t, '(?m)#[^\n]*', '')`）。
> 已在脚本里写死这条注释，避免下次重犯。

---

## §7 ⬜ 可调项（用户没点名，我取的默认值 —— 判据 J 报告，不阻塞实装）

| # | 项 | 我取的 | 备选 | 代价 |
| :-: | --- | --- | --- | --- |
| 1 | 师的经验度 `start_experience_factor` | ✅ **1（= 第 4 级 Veterans / 满经验）**<br>🔄 **2026-09-25 用户先裁「3.0」，同日改为「第 4 级，1.0」** | ~~0.3（第 1 级）~~ · ~~0.8（第 3 级）~~ | 改一个数 |
| 2 | 分类名 | **「敌军动员」** | 用户可指定 | 改 2 条本地化 |
| 3 | 决议图标 | **`GFX_decision_generic_military`**（一队坦克） | `GFX_decision_generic_tank`（单辆坦克）· `GFX_decision_generic_motorized`（卡车）· `GFX_decision_generic_merge_plant_tank`（坦克厂） | 改一行 |
| 4 | 对象范围 | **所有与苏联交战的国家**（照用户"任意一个国家"字面）—— 唯一例外 = **已无任何州的壳子 tag**（v3 判据） | 只给主要国家 / 再排除流亡政府（⚠️ 流亡政府**仍有州**，v3 判据挡不住它） | 加一行 `target_trigger`（⚠️ 必须**四处同步**，否则 §15h 会红） |
| 5 | 每轮 100 个师 + 30 天 | 照用户字面 | 递减 / 设上限 / 只发一次 | 改 `count` 或 `fire_only_once` |
| 6 | 模板名 | ✅ **「1941摩托化坦克师」**<br>🔄 **2026-09-25 用户命名**（原名 `hof_sov_mob_1941`） | — | 改 2 处（已改） |

---

## §8 · 2026-09-27 · 按年份升级敌军动员（当前权威数据）

| 倒计时到期日 | 决议标题 | 每轮发兵 | 模板 |
| --- | --- | ---: | --- |
| 1941-01-01 以前 | 敌方正在动员摩托化坦克师！ | 100 师 | 原有「1941摩托化坦克师」：12 中坦营 + 8 摩托化营，工兵／摩托化侦察各 1 支援连 |
| 1941-01-01 至 1943-12-31 | 敌方正在动员机械化坦克师！ | 200 师 | 新「1941机械化坦克师」：15 中坦营 + 10 机械化营，工兵／通信／摩托化侦察／后勤／野战医院各 1 支援连 |
| 1944-01-01 起 | 敌方正在大规模动员机械化坦克师！ | 300 师 | 复用同一套「1941机械化坦克师」模板 |

阶段按**倒计时到期日**判定；跨过 1944-01-01 的任务按 300 师发放，面板标题和说明也随当前日期变更。模板用目标国国家标记分别去重；已拥有旧模板的存档仍会新建机械化模板。投放仍在目标国控制的首都进行，首都失守时退到其任一自有且受控的州；师经验度和免费满装备写法不变。阶段标题／说明用 `common/scripted_localisation/hof_sov_mob_scripted_loc.txt`，具体定义在 `common/decisions/hof_sov_mob_decisions.txt`。

**游戏内待验：**1941 与 1944 年界日的标题／数量、旧档首次生成新模板、25 个战斗营及五个支援连是否完整、没有机械化科技的敌国是否取得满装备。静态编制和数量由 `verify-s2` §15d 检查。

---

## 相关

- 查证报告：`docs/96-soviet-war-countdown-decision.md`
- 未决与实测清单：`docs/99-todo-verify.md` **§48**（查证）/ **§49**（实装）/ **§54**（倒计时 bug 三版诊断）
- 自检：`build/verify-s2.ps1` **§15**（17 个子块：13a–13h · 14 · 15a–15h）—— **§15h 是修 bug 的回归守卫**，v9 起含：
  ⛔ 不得再出现 `cancel_trigger` 里的 `FROM` · ⛔ 不得再出现 `has_capitulated` · ⛔ 不得出现 `on_daily`（本版本没有这个钩子）·
  ⭐ `activation` = 层 1（`is_ai = no` + `has_war = yes`）· ⭐ `fire_only_once = no`（每月一轮）·
  ⭐ 决策侧**不许**盖章（盖章只由清扫做）· 清扫**双向**（盖章 + `else` 清章）·
  ⭐⭐ **`on_actions` 嵌套结构深度走**（末值 0 / 无负深度 / 五个钩子在 depth 2）
- ⭐ **失败清单落盘**：`build/verify-s2-failures.txt`（真 UTF-8）—— 控制台是 GBK，会把 `✗` 与中文一起换成 `?`，
  从重定向日志里**分不出 Pass 与 Fail**，所以必须靠这份旁路文件定位失败项
- 落地文件：`mod/heart_of_iron/common/decisions/**` · `mod/heart_of_iron/common/on_actions/**` ·
  `mod/heart_of_iron/localisation/simp_chinese/hof_sov_mob_l_simp_chinese.yml`
