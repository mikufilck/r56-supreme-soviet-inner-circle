# 20 · 核心圈人物史实查证（个人线国策的素材库）

> 用途：为核心圈 7 人各写一条「个人线国策」时，需要把人物的**理论主张、
> 政治、经济、军事**四条贡献落到「能对应一个国策」的具体主张或事件上。
> 本文逐人查证并成清单。
>
> 花名册见 `docs/18-s3-implementation-log.md` §2；
> 人物 id 与立绘来源见 `build/gen-hof-ic-s3.ps1` 的花名册表。

---

## 0. 资料来源与可靠性说明

| 项 | 说明 |
| --- | --- |
| 本轮可用来源 | **Britannica 人物条目**（实测可稳定抓取） |
| 实测抓不到的来源 | 维基百科（中/英）、wikiwand 镜像、marxists.org、Britannica 的 topic 页 |
| 标记约定 | `[B]` = 有 Britannica 原文支持；`[待核实]` = 属公认史实但本轮**未抓到一手来源**，用前请复核 |

> ⚠️ **抓取工具的坑（2026-09-14 挂虚拟网卡复测）**：`fetch_webpage` 对本项目仍**只有 Britannica 返回内容** ——
> 英文维基返回 "Failed to extract meaningful content"，marxists.org 返回 "Not Found"。
> 结论：**下一轮直接上 Britannica**，不要在维基上浪费时间。
> 若报 `net::ERR_NETWORK_CHANGED`，是网卡正在切换，重试即可。

---

## 0.5 设计参照系（写国策前必读）

初版我把「卖点」写成了泛泛的领域分类，那是错的 —— 它不知道两棵树的实际设计语言。
下面是从原版/R56 实测出来的规格。

### A. 德国核心圈的完整结构（我们照抄的「形状」）

来源：`germany.txt` 里含 `FOCUS_FILTER_INNER_CIRCLE` 的**全部 30 个国策**
（扫描件 `docs/reference/reports/ic-all-report.txt`，脚本 `scan-ic-all.ps1`）

**它不是「一人一个国策」，而是「一人一个入口 + 一条子线」：**

| 层 | 数量 | 花销 | 说明 |
| --- | --- | --- | --- |
| 枢纽 | 1（`GER_fuhrerprinzip`） | `5` | 核心圈总开关 |
| **入口** | **每角色 1 个**，共 6 | **`2`** | `GER_ascension_of_<name>`，给该角色的招牌 idea |
| **子线** | 每角色 1–4 个，共 23 | **`@inner_circle_time_tier_N`** | 后续个人线，才是「他到底干了什么」 |
| **汇合** | 2（互斥） | `5` | 子线末端收束，给强力结局 |

实例（托特 / 希姆莱）：

```text
GER_ascension_of_todt        → GER_todt_reich_engineer（帝国工程师）
 ├ GER_form_organization_todt        → GER_organization_todt（托特组织）
 │   ├ GER_autonomous_organization_todt
 │   └ GER_plenipotentiary_of_armaments
 └ GER_wunderwaffe                   → GER_walter_dornberger

GER_ascension_of_himmler     → GER_himmler_chief_of_german_police
 ├ GER_expand_gestapo  → GER_absorb_the_abwehr → GER_hegemony_of_the_ss
 └ GER_expand_ss_security_duties → GER_strengthen_the_waffen_ss
```

**入口国策（`cost = 2`）的字段清单** —— 逐项实测，不是推测：

```text
focus = {
    id = GER_ascension_of_todt
    icon = GFX_focus_GER_ascension_of_todt      # 每人一张专属图
    prerequisite = { focus = GER_fuhrerprinzip }
    x = -7   y = 1
    relative_position_id = GER_fuhrerprinzip
    cost = 2
    available = { has_government = fascism   NOT = { 已是领袖 }  冷却旗标 }
    cancel_if_invalid = no
    continue_if_invalid = no
    search_filters = { FOCUS_FILTER_INNER_CIRCLE FOCUS_FILTER_POLITICAL_CHARACTER FOCUS_FILTER_INDUSTRY }
    select_effect = { set_country_flag = GER_todt_ascension_flag }
    completion_reward = {
        custom_effect_tooltip = { localization_key = GER_ascension_of_character_tt  CHARACTER = GER_fritz_todt }
        show_ideas_tooltip = GER_todt_reich_engineer
        if/else_if/else = { 已在席 → log ; 席位满 → 换人事件 ; 有空席 → add_ideas + set_variable }
    }
}
```

> **注意筛选器里的第三个才是「领域」**：托特 `INDUSTRY`、希姆莱 `MANPOWER`、
> 戈培尔 `WAR_SUPPORT`，军事角色则是 `MILITARY_CHARACTER` / `ARMY_XP`。
> **一人多领域时，就是靠子线挂多个国策实现的** —— 这正是「多写几个国策」的接口。

**子线国策的字段清单**（比入口多两样）：

```text
    text_icon = GER_inner_circle_focus_style       # 核心圈专属标题条样式
    cost = @inner_circle_time_tier_1
    mutually_exclusive = { focus = A  focus = B }  # 子线内部才做互斥
```

**两个必须知道的外部依赖：**

| 依赖 | 位置 | 后果 |
| --- | --- | --- |
| `@inner_circle_time_tier_1/2/3 = 20 / 20 / 40` | **`germany.txt` 文件头 L20-22**（文件级脚本常量） | 我们照抄时要自己定义一份 |
| `style = { name = GER_inner_circle_focus_style ... }` | **原版** `common/national_focus/00_titlebar_styles.txt` L63 | 原版文件，**要用必须整文件复制**（AGENTS.md 规则 2） |

> 常量注释原话：`# This is Focus cost so x7 to get the days` ——
> **cost 的 1 个单位 = 7 天**，即 `cost = 10` → 70 天（标准国策），`cost = 2` → 14 天。
> 所以 `tier_1 = 20` 相当于 140 天的长项目。

### A2. 汇合层（你说的「分支走完再合并给强力 buff」，已实锤）

来源：`germany.txt` L24250 `GER_a_strong_successor`、L24361 `GER_loyalty_to_the_fuhrer`

```text
focus = {
    id = GER_a_strong_successor
    icon = GFX_focus_GER_a_strong_successor
    # 关键：前置=五条子线的【末端节点】同时连入，不是一个
    prerequisite = { focus = GER_hegemony_of_the_ss  focus = GER_wunderwaffe
                     focus = GER_integration_of_puppet_economies
                     focus = GER_propaganda_master
                     focus = GER_total_control_over_domestic_affairs }
    mutually_exclusive = { focus = GER_loyalty_to_the_fuhrer }   # 两个结局二选一
    x = -2   y = 5
    relative_position_id = GER_fuhrerprinzip
    cost = 5

    available = {
        has_government = fascism
        custom_trigger_tooltip = {
            tooltip = GER_a_strong_successor_trigger_tt
            count_triggers = {
                amount = 3          # ← 【5 条里走通 3 条即可】
                AND = { has_completed_focus = GER_wunderwaffe   <对应席位变量达到某档> }
                ... 其余 4 个 AND 同构 ...
            }
        }
    }
    cancel_if_invalid = no
    continue_if_invalid = no
    completion_reward = {
        hidden_effect = { country_event = GER_inner_circle.02 }   # 结局走事件
        custom_effect_tooltip = { localization_key = GER_a_strong_successor_tt ... }
    }
}
```

**三个要点**：

1. **`prerequisite` 可以写多个**（这里 5 个并列），这是德国实现「汇合」的手法。
2. **`available` 里用 `count_triggers = { amount = 3 }`** —— 不要求全通，**走通 3 条就能进**。
   这样支线多寡不影响可行性，但走得越多越早解锁。
3. **两个结局互斥***（`GER_a_strong_successor` vs `GER_loyalty_to_the_fuhrer`），
   相当于给玩家一个「收束方向」的选择。

> 💡 **对苏联版的含义**：7 名候选人如果各自出子线，末端可以汇合到
> 「苏维埃体制的走向」这类结局上，让玩家的选择有归属。具体怎么摆由你定。

### B. ⛔ 三种「类型」别混（这是上一版最大的错）

| 类型 | 代表 | 花销 | 我们怎么用它 |
| --- | --- | --- | --- |
| **核心圈小国策** | `GER_ascension_of_*` 及其子线 | `2` / 常量 | ✅ **照抄形状**（我们做的是这一类） |
| **政治线大国策** | `SOV_the_supreme_soviet` 等 | `5` / `10` | ⚠️ **只借「主题」，不借花销** |
| **国家领袖线** | `SOV_promote_to_country_leader_trotsky` | — | ❌ **与本 mod 无关，不许接** |

- 上一版我把政治线的 `cost = 5/10` 抄了过来 —— 错。
  **我们的核心圈全是小国策，一律 `cost = 2`。**
- 「参考政治线」的意思是：看**它把重心放在哪些主题上**，然后在同一批主题上做我们的小国策。
- 领袖线是**另一套系统**（`SOV_the_supreme_soviet` 自己就带 `promote_leader = yes`），
  核心圈**不接**，也不拿它当奖励。它甚至在重新完成时会**移除派系修正**，与我们无关。

### C. 苏联政治线的「重心」在哪（照抄主题用）

来源：`soviet.txt` 通往 `SOV_the_supreme_soviet` 的那条链

```text
SOV_conduct_nationwide_inspections
 ├ SOV_status_of_labour_unions          工会地位
 └ SOV_recalibration_of_quotas          定额重校
SOV_all_power_to_the_soviets
 ├ SOV_strengthen_the_trade_unions      强化工会（互斥 区域发展 / 为公益）
 └ SOV_the_peoples_revolution           人民革命
    └ SOV_the_supreme_soviet            最高苏维埃（cost 10，自己推领袖 + 移除派系修正）
```

**重心 = 工会 / 苏维埃权力 / 人民革命 / 党内纪律。**
左翼反对派那条支线另加：**党内民主 / 经济计划化 / 世界革命**。

> 托洛茨基的个人线应当落在**这批主题**上，用他自己的贡献去表达 ——
> 这样它才「像同一棵树上的东西」，而不是外挂。

### D. ⚠️ R56 已有一整套反对派机制（**必须接进去，别另起一套**）

来源：`docs/reference/reports/trotsky-r56-report.txt`（扫描脚本 `scan-trotsky-r56.ps1`）

**三选一支线**（`soviet.txt`）：

```text
SOV_the_left_opposition      ← 左翼反对派，mutually_exclusive 于右翼与中间派
SOV_the_right_opposition
SOV_the_centre
```

左翼线已有的子国策：`SOV_the_fourth_international`、
**`SOV_bring_old_trotskyists_back`**、`SOV_organize_the_wreckers`、
**`SOV_integrate_smirnovs_bloc`**（把斯米尔诺夫/斯米尔加/施利亚普尼科夫从监禁改为流放）、
`SOV_left_opposition_coup`、`SOV_left_purges`。

**状态旗标**（都挂在角色身上）：

```text
SOV_imprisoned_flag        SOV_exiled_flag
SOV_character_purged_flag  SOV_aligned_left_opposition_flag
```

**武装力量支持度变量**：`SOV_left_opposition_army_support` / `_navy_support` / `_air_support`
（左翼国策完成时设 0.25 / 0.05 / 0.15）

**托洛茨基专属现成件**：

| 名字 | 位置 | 作用 |
| --- | --- | --- |
| `SOV_lev_trotsky` | `scripted_effects/SOV_scripted_effects.txt` L4227 | 直接操作该角色的入口 |
| `SOV_promote_to_country_leader_trotsky` | 同上 L7360 | **已有**把他推为国家领袖的效果，给 `ideology = marxism` + 特质 **`permanent_revolutionary`**（有 LaR 时为 `permanent_revolutionary_LaR`） |
| `SOV_kill_trotsky_effect` | 同上 L4215 | 处决：置 `flag_trotsky_dead`、扣 `SOV_character_purged_flag`、换掉 `trotskyite_plot_nsb` idea、并同步处理墨西哥那位 |
| `trotskyite_plot` / `_nsb` / `_purged` | `ideas/SOV.txt`、`ideas/r56_soviet.txt` | 三张递进的反对派图谋 idea |
| `SOV_trotskyist_revolutionary_agitation`（+`_weakened`） | `ideas/SOV.txt` | 宣传类 idea |

> **一句话**：R56 已经把「托洛茨基在监禁/流放/被处决」这条线做完了。
> 我们的核心圈只需要接在它**后面** —— 把人清白了、再请进最高苏维埃。

---

## 1. 列夫·达维多维奇·托洛茨基（Лев Троцкий / Leon Trotsky）

生卒：1879-11-07 — 1940-08-21（墨西哥城郊科约阿坎，被斯大林特工暗杀）
本位：**理论家 + 军事组织者**，内战与战时共产主义时期公认的「二号人物」

### 1.1 托洛茨基：理论与历史贡献总表（供设计师取材）

> ⚠️ **本节只是「索引」，不是「结构」** —— 它按理论/政治/军事/经济/国际分了五堆，
> 但**没有说哪条推出哪条、哪条被推翻、哪条成了奠基**，因此很难直接串成国策树。
> **要做线请看 `docs/21-trotsky-genealogy.md`**（理论谱系 + 有效性判定 + 强相关聚类）。

> 上一版我在这里直接给了一套「7 个国策」的设计，**那是错的** —— 它们彼此孤立：
> 没有后续国策，也没有汇合层，不成一棵树。按你的要求，这里只**整理并分类素材**，
> 设计由你来做。德国核心圈的完整四层架构（含**汇合层**）见 §0.5 A / A2。

#### 1.1.1 来源说明（含一处更正）

本轮拿到了**新的一手来源** `[中]` = **中文马克思主义文库**。

| 标记 | 含义 |
| --- | --- |
| `[B]` | Britannica 人物条目 |
| `[中]` | 中文马克思主义文库：多伊彻《武装的先知》中译本、双山编《简略年谱》、怀特《如何组织红军》 |
| `[待核实]` | 公认史实但本轮未抓到一手来源 |

> ✅ **更正**：上一版我写「marxists.org 抓不到」是**错的** —— 我只试了**英文**路径
> （`/archive/trotsky/`，404）。**中文库路径 `/chinese/` 完全可抓**：
>
> - 托洛茨基专页 `https://www.marxists.org/chinese/trotsky/index.htm`
> - 简略年谱 `.../chinese/trotsky/marxist.org-chinese-trotsky-life.htm`
> - 多伊彻《武装的先知》`.../chinese/isaac-deutcher/1954book/index.htm`（分章：
>   第 6 章「不断革命论」、第 10 章「人民委员」、第 12 章「武装共和国」、
>   第 13 章「革命与征服 —— 托洛茨基军事思想评论」）
> - 怀特《如何组织红军》`.../chinese/trotsky/review/mia-chinese-john-g-wright-on-trotsky-19410816.htm`

#### 1.1.2 A. 理论贡献（9 条）

| # | 主张 / 著作 | 内容 | 年份 | 来源 |
| --- | --- | --- | --- | --- |
| T1 | **不断革命论** | 《总结与展望》狱中写成。俄国民主革命必然由工人阶级领导、以无产阶级专政完成，并由此发展为社会主义革命；革命不能在一国范围内完成 | 1906 | `[B][中]` |
| T2 | **反驳「一国社会主义」** | 斥斯大林的一国社会主义论是「放弃世界革命的借口」 | 1926 | `[B]` |
| T3 | **党内民主 + 经济计划化** | 十月致中央委员会的批评信：指控党内民主被破坏、经济计划化不足；随后公开信细化方向，引发「新方针」争论 | 1923 | `[B]` |
| T4 | **《十月教训》** | 把季诺维也夫、加米涅夫在十月问题上的动摇，与 1923 年德国共产主义起义的失败挂钩 | 1924 | `[B]` |
| T5 | **共产国际首篇宣言** | 参与创建第三国际并撰写其首篇宣言 | 1919 | `[B][中]` |
| T6 | 列宁的「内政副手」 | 列宁恢复期请他协助纠正三人团在**对外贸易政策、民族事务、官僚体制改革**三方面的错误 | 1922–23 | `[B]` |
| T7 | **军事理论：驳「军事科学的永恒真理」** | 论文《军事学说及伪军事理论》。主张军事科学没有永恒真理，只有「几条逻辑法则和欧几里得假设」；引克劳塞维茨「战争是政治的继续」，指内战中战略与政治的一致性毫不掩饰 | 1920s | `[中]` |
| T8 | 反对拿破仑式进攻论 | 论证俄国文明水平低、内战只能以准拿破仑方式打；反对图哈切夫斯基让红军照搬拿破仑式进攻理论 | 1920s | `[中]` |
| T9 | 不平衡与综合发展律 / 《被背叛的革命》 | 落后国何以跳过某些发展阶段；苏联官僚化与「堕落的工人国家」 | — / 1936 | `[待核实]` |

#### 1.1.3 B. 政治贡献与经历（11 条）

| # | 事件 | 内容 | 年份 | 来源 |
| --- | --- | --- | --- | --- |
| P1 | 圣彼得堡苏维埃主席 | 领导罢工运动与对抗沙俄政府的行动 | 1905 | `[B][中]` |
| P2 | 入党并当选中央委员 | 8 月在狱中被接纳为布尔什维克党员；9 月出狱后当选彼得格勒苏维埃主席 | 1917 | `[B][中]` |
| P3 | **十月起义的实际指挥** | 组建并主持「军事革命委员会」；11-13 普尔科沃之战击破克伦斯基反扑 | 1917 | `[B]` |
| P4 | 拒绝联合政府 | 与列宁一同否决与孟什维克、社会革命党人组建联合政府的提案 | 1917 | `[B]` |
| P5 | 政治局首批成员 | 1919 年政治局成立时五名初始成员之一 | 1919 | `[B]` |
| P6 | **联合反对派** | 与旧敌季诺维也夫、加米涅夫联手，主张党内民主、经济计划化，谴责领导层对资产阶级的让步 | 1926 | `[B]` |
| P7 | 一路被排挤 | 1925 免军事人民委员 → 1926 逐出政治局 → 1927 开除出党 → 1929 流放 → 1940 遇刺 | 1925–40 | `[B][中]` |
| P8 | **改任电气技术发展局局长** | 被免军职后任电气技术发展局局长兼工业与技术委员会主席 —— 从军事转向工业 / 电气化 | 1925 | `[中]` |
| P9 | **中国问题主张** | 屡次提议中共退出国民党、采取独立的工农革命政策，均被斯大林控制的第三国际拒绝，终致 1927 年大革命失败 | 1927 | `[中]` |
| P10 | **反法西斯统一战线主张** | 自 1930 年起不断警告纳粹危险，主张社民党与共产党建立统一战线；第三国际拒绝，结果德国工人阶级组织被粉碎 | 1930–33 | `[中]` |
| P11 | 出版自由 / 贸易自由的论辩 | 主张「凡是有资本的人就有权」；为按比例分配印报设备给各党作辩护 | 1917 | `[中]` |

#### 1.1.4 C. 军事贡献（18 条，他最不可替代的部分）

| # | 主张 / 事件 | 内容 | 年份 | 来源 |
| --- | --- | --- | --- | --- |
| M1 | **从废墟中创建红军** | 1918-03-01 任军事人民委员长兼最高军事委员会主席；当时实际上还没有真正的军队 | 1918 | `[B][中]` |
| M2 | 从志愿军到征兵制 | 1918-02-23 法令组建志愿军团；1918-05-28 起实行征兵制 | 1918 | `[中]` |
| M3 | **小而精的正规军路线** | 力主建立**规模小但有纪律、专业称职**的军队；**放弃**军队民主化与游击战术 | 1918 | `[B]` |
| M4 | **军事专家 + 政委制度** | 招募旧沙俄军官（「军事专家」），置于**共产党军事委员（政委）的监督**之下 | 1918 | `[B]` |
| M5 | 与「军事反对派」斗争 | 反对游击主义；论证游击战的混乱反映革命下面的农民因素，反对它即支持无产阶级国家组织 | 1918–19 | `[中]` |
| M6 | 与斯大林的察里津之争 | 军事路线遭极左纯粹派与党内对手（尤其斯大林）抵制；两人在察里津防务上激烈冲突 | 1918 | `[B][中]` |
| M7 | **红军誓词** | 由他起草（「我是劳动人民子弟，苏维埃共和国公民……」） | 1918 | `[中]` |
| M8 | **连坐法令** | 「任何部队擅自后退，首先要枪毙该部队的政委，其次是部队指挥员」 | 1918 | `[中]` |
| M9 | **争取设立勇敢勋章** | 布尔什维克已废除一切勋章，他三次反复要求设勇敢勋章 | 1918 | `[中]` |
| M10 | **反军国主义 / 裁军** | 其法令开篇：「必须使人类摆脱军国主义……社会主义的目的是普遍裁军、持久和平」 | 1918 | `[中]` |
| M11 | 战果 | 22 个战线上获胜；内战结束时红军约 500 万人 | 1918–20 | `[中]` |
| M12 | 反对向华沙进军 | 公开表示从未相信红军会占领华沙，反对向华沙挺进 | 1920 | `[中]` |
| M13 | 骑兵问题 | 起初反对布琼尼的骑兵部队计划（认为骑兵时代已过），1919-09 改变看法并肯定骑兵价值 | 1919 | `[中]` |
| M14 | 为军官辩护 | 断然反对逮捕查京将军，称他帮苏维埃做的工作比关押他的人还多 | 1919 | `[中]` |
| M15 | **《革命是怎样被武装起来的》** | 其军事文集，军事思想的主要载体 | 1920s | `[中]` |
| M16 | 镇压喀琅施塔得 | 站到列宁一边，指挥部队镇压喀琅施塔得叛乱的驻军 | 1921 | `[B]` |
| M17 | 布列斯特的「不战不和」 | 亲自到场把谈判变成宣传场；在列宁的「签约」与布哈林的「革命战争」之间提出「不战不和」 | 1918 | `[B]` |
| M18 | 军事外交威胁 | 公开威胁芬兰政府，称若芬兰对彼得格勒动手就派巴什基尔骑兵师进攻赫尔辛基 | 1919 | `[中]` |

#### 1.1.5 D. 经济贡献（6 条）

| # | 主张 | 内容 | 年份 | 来源 |
| --- | --- | --- | --- | --- |
| E1 | **最先主张放松战时共产主义** | 第一个提出放松严苛集中制、**允许市场力量运作** —— 被否决 | 1920 | `[B]` |
| E2 | **军事化经济（被否决后的转向）** | 转而主张以军事纪律改造经济：**劳动军**、把交通系统的行政军事化 | 1920 | `[B]` |
| E3 | **工会问题（三方争论）** | 托洛茨基派：由**代表中央国家权威的工会**管理工业；列宁派：工会只管劳动条件；「工人反对派」：工会直接管理工业 | 1920–21 | `[B][中]` |
| E4 | 接受新经济政策 | 与列宁一起接受向新经济政策的退却，也接受列宁对工会的常规看法 —— 因此在十大上损失大量政治影响力 | 1921 | `[B]` |
| E5 | 谴责对资产阶级让步 | 联合反对派的核心经济指控之一 | 1926 | `[B]` |
| E6 | **电气化 / 工业委员会** | 1925 被免军职后任电气技术发展局局长兼工业与技术委员会主席 | 1925 | `[中]` |

> 注：E1 与 E2 的先后顺序很重要 —— **他先要市场，被否决后才转向军事化**。
> 这是两个方向完全不同的选项，别写反。

#### 1.1.6 E. 国际 / 共产国际（6 条）

| # | 主张 / 事件 | 内容 | 年份 | 来源 |
| --- | --- | --- | --- | --- |
| I1 | 创建第三国际 | 与列宁共同创立共产国际，撰写首篇宣言 | 1919 | `[B][中]` |
| I2 | 中国问题 | 主张中共退出国民党、独立工农革命政策 | 1927 | `[中]` |
| I3 | 反法西斯统一战线 | 主张社民党与共产党联合对抗纳粹 | 1930–33 | `[中]` |
| I4 | 第四国际 | 流亡期间组建，与共产国际对立 | 1938 | `[中]` |
| I5 | 国际主义立场 | 一战爆发即坚持国际主义、主张革命反对战争 | 1914 | `[中]` |
| I6 | 亚洲革命的分寸 | 认为中东革命缺乏内在力量，应利用其作对英外交筹码而非军事冒险 | 1919 | `[中]` |

#### 1.1.7 ⚠️ 与 R56 已有内容的重复边界

设计前先划线，避免撞车：

| R56 已有（已被占用） | 对应上表的条目 |
| --- | --- |
| `SOV_the_left_opposition` | 左翼反对派总入口（与右翼、中间派三选一互斥） |
| `SOV_the_fourth_international` | **I4 第四国际** |
| `SOV_bring_old_trotskyists_back` | 请回老托派（拉狄克、普列奥布拉任斯基） |
| `SOV_organize_the_wreckers` | 组织破坏者 |
| `SOV_left_opposition_coup` / `SOV_left_purges` | 政变 / 清洗 |
| `SOV_integrate_smirnovs_bloc` | 斯米尔诺夫集团 |

**还没被占用的**（即你的可用空间）：**A 组全部理论、C 组全部军事、D 组全部经济**、
I1 / I2 / I3 / I5 / I6、P8 / P9 / P10 / P11。

#### 1.1.8 附：可用的效果词汇（只列已核实写法）

| 写法 | 出处 |
| --- | --- |
| `show_ideas_tooltip = X` / `add_ideas = X` | 德国入口国策 |
| `swap_ideas = { remove_idea = X  add_idea = Y }` | 德国子线 |
| `add_extra_state_shared_building_slots = 1` + `add_building_construction = { type = arms_factory level = 1 instant_build = yes }` | 德国子线 |
| `prerequisite` 写多个 / `count_triggers = { amount = N }` | **德国汇合层**（见 §0.5 A2） |
| `add_political_power = 50` | 两边都有 |
| `add_popularity = { ideology = communism  popularity = 0.05 }` | 苏联政治线 |
| `add_timed_idea = { idea = X  days = 365 }` | 两边都有 |
| `add_tech_bonus = { name = X  bonus = 1  uses = 1  category = industry }` | 苏联政治线 |

> ⚠️ **注意 E1 与 M6 的张力**：托洛茨基**既最早要市场**（E1，被否决）、
> 又**与斯大林正面冲突**（M6 察里津），而斯大林后来恰恰用
> 「新经济政策退却」与「一国社会主义」掌权。
> 这条人物线的戏剧性正来自这个错位 —— 也解释了为什么他的经济主张
> 从「要市场」拐到「劳动军」。

#### 1.1.9 ✅ 已完成的改动（2026-09-14）

7 个入口国策的花销已从 **`cost = 5` 改为 `cost = 2`**：

| 步骤 | 结果 |
| --- | --- |
| 改 `build/gen-hof-ic-s3.ps1` L536 | `cost = 5` → `cost = 2` |
| 重跑生成器 | 全部自检通过，`inject-sov-seats.txt` 已是 `cost = 2` |
| 重跑 `sync-from-r56.ps1` | 17 / 17 挂载点成功，`soviet.txt` 注入 135 行 |
| 重跑 `verify-s2.ps1` | **失败项 0** |

---

## 2. 待做：其余 6 人

按花名册顺序，逐个补。

| # | 人物 | 状态 |
| --- | --- | --- |
| 1 | 列夫·托洛茨基 | ✅ `docs/21`（图谱）+ `docs/22`（设计） |
| 2 | 尼古拉·布哈林 | ✅ **`docs/25`（关系图谱，SOP 第 0–5 步）** / ⬜ 第 6 步设计待做 |
| 3 | 阿列克谢·李可夫 | ✅ **`docs/29`（关系图谱，SOP 第 0–5 步）** / ⬜ 第 6 步设计待做<br>✅ 与布哈林的重复已砍；走**「历史重要贡献事件」法**（非理论家，`docs/23` 第 1b 步）<br>✅ 审查后**砍到单线 / 4 节点**；末端走 **MIO（雅克夫列夫设计局）** |
| 4 | 格里戈里·季诺维也夫 | ⬜ 待做（⚠️ 与托洛茨基高度纠缠，先查 `docs/21`） |
| 5 | 列夫·加米涅夫 | ⬜ 待做 |
| 6 | 伊万·斯米尔诺夫 | ⬜ 待做 |
| 7 | 列昂尼德·谢列布里亚科夫 | ⬜ 待做 |

### 已知的现成线索

Britannica 的托洛茨基条目里已经带出了下面几位，写他们的条目时可直接引用：

- **布哈林**：1917 年 1 月与托洛茨基在纽约合编俄文报《新世界》；1918 年和谈中**主张「革命战争」**
  （与列宁的「签约」、托洛茨基的「不战不和」并列的第三条路线）；1926 年前后是**斯大林—布哈林领导层**的一半
- **季诺维也夫 / 加米涅夫**：1922–23 与斯大林结成**三人团**排挤托洛茨基；十四大上被谴责；
  1926 年与托洛茨基组成联合反对派；加米涅夫在十月革命问题上曾有动摇（《十月教训》的攻击对象）
