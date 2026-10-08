# 22 · 托洛茨基个人国策树设计（含设计理由）

> 前置阅读：`docs/21-trotsky-genealogy.md`（谱系与聚类——本文的支线划分直接来自它的六簇）、
> `docs/20` §0.5（德国四层架构与苏联政治线重心）。
>
> 本文是**设计提案**，不是实施记录。每条国策都给了史实锚点，便于逐条否决/修改。

---

## 1. 设计前提（三条硬约束）

| 约束 | 依据 |
| --- | --- |
| **全部 `cost = 2`** | 核心圈是小国策（德国入口即 `cost = 2`）。政治线的 5/10 是**另一种类型**，只借主题不借花销 |
| **不挂派系门槛** | `available` **只认** `hof_ic_seated_lev_trotsky = yes`。挂 `SOV_the_left_opposition` 会让走右翼反对派的人一点红利吃不到 |
| **不碰国家领袖线** | `SOV_promote_to_country_leader_trotsky` 属另一套系统，本树不用它，也不拿它当奖励 |

补充：入口国策 **S3 已建好**（`hof_ic_seat_lev_trotsky`，`cost = 2`，`prerequisite = SOV_the_supreme_soviet`）。
本树**挂在它下面**，不改它。

---

## 2. 整体结构：照抄德国的四层

```text
层 1 枢纽     SOV_the_supreme_soviet（已有，R56）
层 2 入口     hof_ic_seat_lev_trotsky（已有，S3）        ← 入席
层 3 支线     5 条，每条 2–4 个国策                       ← 本文新增
层 4 汇合     2 个，互斥，count_triggers = { amount = 3 }  ← 本文新增
```

**为什么是这四层**：德国核心圈实测就是 `枢纽 1 + 每人 1 入口 + 每人 1–4 子线 + 汇合 2 个`
（共 30 个国策）。它不是"一人一个国策"——这是我第一版最大的误判。

### 2.1 网格布局（已实测有空位）

`focus-collision-report.txt`：锚点 `SOV_the_supreme_soviet` 绝对坐标 **(65, 13)**，
托洛茨基入口在 **(59, 15)**；**y = 14..20 整片为空**，X 范围 0..145。

```text
y=15   [入口 59]
y=16   I军事49   II理论53   III党内民主57   IV经济61/63   V国际67
y=17   I49       II53       III57           IV汇流62      V67
y=18   I49       II53                       IV62          V67
y=20   汇合 56（永久的革命者）  ←→  62（国家建设者）   互斥
```

---

## 3. 支线怎么分：**按 `docs/21` 的「簇」分，不按领域分**

这是本设计最核心的一条理由。

我上一版失败的原因，是把国策按「理论 / 政治 / 军事 / 经济 / 国际」五个**领域**切。
但领域之间没有推导关系，切出来的五堆**各自孤立**，最后只好像撒豆子一样摆七个国策。

而 `docs/21` §5 的六簇，本身就是**「簇内成员互为依据、或互为同一斗争的不同侧面」**：

| 簇（`docs/21`） | 本设计的支线 | 为什么它能成链 |
| --- | --- | --- |
| 簇 2 军事组织 | **支线 I** | 建军 → 征兵 → 军事专家+政委 → 反游击主义，是同一场斗争的不同环节 |
| 簇 1 理论根干 | **支线 II** | 不平衡发展 **→ 推出 →** 不断革命论 **→ 推出 →** 驳一国社会主义 |
| 簇 4 党内民主 | **支线 III** | 新方针 → 反官僚化 → 《被背叛的革命》 |
| 簇 3 经济曲折 | **支线 IV** | 要市场(被否) → 劳动军(被否) → 计划化(奠基) → 加速工业化 |
| 簇 5 国际/殖民地 | **支线 V** | 第三国际 → 中国问题 → 统一战线 |
| **簇 6 军事理论** | **→ 并入支线 I**（不开新线） | 见下方补记 |

**结论**：支线 = 簇（**除簇 6 外**，它并入支线 I）。这样每条支线内部天然有"前因后果"，玩家点下去能感到在推进一件事。

> ⚠️ **2026-09-15 补记：簇 6（军事理论）原先漏了映射** —— 本节表头写「六簇」，表里却只有 5 行。
> 用户看思维链时发现，要求核实。**复核结论：不开新支线，并入支线 I。** 理由：
>
> 1. **德国规格是每角色 1–4 条子线，本设计已有 5 条**（已超上限）—— 再开第 6 条不合适。
> 2. **簇 6 与簇 2 同属军事领域**。按合并判据（`docs/23` §2.5）
>    「合并会不会丢掉一个独立的理论主张？」→ **不会**：
>    簇 6 的内容是**簇 1 方法论在军事领域的应用**，不是新命题。
> 3. 按 `docs/23` §2.5「**三问判据**」逐条量：
>
>    | 簇 6 的条目 | 三问复核 | 判定 |
>    | --- | --- | --- |
>    | 驳「军事科学的永恒真理」/ 反对拿破仑式进攻论 | ① ⚠️ 可转（军事科学随社会条件变化）② ✗ 不是新领域 ③ ⚠️ 未核实 | ⚠️ **作支线 I 的延伸节点** |
>    | 反对向华沙进军 | ① ⚠️ ② ✗ ③ ✗（只有一次具体教训） | ⚠️ **一次性战略判断** → 可作节点，**不独立成条** |
>    | 骑兵问题（先反对后接受） | 他自己改口 | ❌ **不做**（同「劳动军」） |
>
> 4. **支线 I 现在只有 3 条国策**（德国是 1–4）—— **并入后正好 4 条**，不注水。
>
> ⏸ **具体怎么并（I4 叫什么、给什么奖励）属第 6 步设计，由用户定。**

---

## 4. 逐条国策表

### 支线 I · 红军缔造（x=51）

| # | id | 名称 | 前置 | 史实锚点 | 奖励方向 |
| --- | --- | --- | --- | --- | --- |
| I1 | `hof_ic_trotsky_build_the_red_army` | 缔造红军 | 入口 | 1918-03-01 任军事人民委员长；当时没有真正的军队；志愿军团 → 征兵制 | idea `HOF_ic_trotsky_red_army` |
| I2 | `hof_ic_trotsky_military_specialists` | **返聘沙俄军官** | I1 | 招旧沙俄军官（「军事专家」），置于共产党政委监督之下 | idea + 陆军经验 / 可点名的现成将领 |
| I3 | `hof_ic_trotsky_against_partisan_warfare` | **反对游击主义** | I2 | 与「军事反对派」斗争；察里津与斯大林冲突 | idea + 稳定/纪律 |

### 支线 II · 理论根干（x=53）

| # | id | 名称 | 前置 | 史实锚点 | 奖励方向 |
| --- | --- | --- | --- | --- | --- |
| II1 | `hof_ic_trotsky_uneven_and_combined_development` | 不平衡与综合发展律 | 入口 | 《俄国革命史》卷 1 序言（`[辞]` 该条目参考书目②） | idea（理论类） |
| II2 | `hof_ic_trotsky_permanent_revolution` | 不断革命论 | II1 | 1906《总结与展望》→ 1928《不断革命》 | idea（招牌）+ 政治点 |
| II3 | `hof_ic_trotsky_socialism_in_one_country` | 驳「一国社会主义」 | II2 | 1926 联合反对派 | idea + 对共产国际影响 |

> ⚠️ **这条链的 `prerequisite` 是本文最重要的设计**：II1 → II2 → II3 不是随便排的，
> 它是 `[辞]` 明载的推导关系（根理论 → 奠基石 → 推论）。**用 prerequisite 把谱系画进树里。**

### 支线 III · 党内民主（x=55）

| # | id | 名称 | 前置 | 史实锚点 | 奖励方向 |
| --- | --- | --- | --- | --- | --- |
| III1 | `hof_ic_trotsky_the_new_course` | 新方针 | 入口 | 1923 年 10 月致中央委员会的批评信 | 政治点 + 共产意识形态支持度 |
| III2 | `hof_ic_trotsky_against_the_bureaucracy` | 反对官僚化 | III1 | `[辞]`：他警告**党要提防用自身代替无产阶级或支配无产阶级** | idea（可给 `add_dynamic_modifier`） |

> 这条线**刻意只放 2 个国策**，因为多余的部分 R56 已经做了（`SOV_return_democracy_to_the_party`
> `SOV_dissent_in_the_party`）。**不能重复**。

### 支线 IV · 经济（x=57 / 59 → 汇流 58）—— **本树最有设计感的一段**

| # | id | 名称 | 前置 | 史实锚点 | 判定 |
| --- | --- | --- | --- | --- | --- |
| IV1 | `hof_ic_trotsky_limited_market_reforms` | **有限市场化** | 入口 | 1920 第一个主张放松严苛集中制、允许市场力量运作 —— **被否决** | ✅ 有远见但没成功 |
| IV2 | `hof_ic_trotsky_labour_armies` | 劳动军 | 入口 | 1920–21 转向军事化经济 —— **被否决，他自己放弃** | ❌ **不能算贡献** |
| IV3 | `hof_ic_trotsky_state_planning` | 经济计划化 | **IV1 或 IV2** | 1923 十二大报告与提纲 —— 多伊彻称「**苏联经济史上最关键的文件**」 | ✅ **奠基** |
| IV4 | `hof_ic_trotsky_accelerated_industrialization` | 加速工业化 | IV3 | 1926 联合反对派要求 —— **1928 斯大林五年计划事实上采纳** | ✅ **奠基** |

**三个刻意的设计动作**：

1. **IV1 与 IV2 互斥**（`mutually_exclusive`）。史实上它们是先后两次尝试、方向相反
   （E1 要市场 → 被否 → 转向 E2 军事化）。做成互斥，玩家必须选一边。
2. **IV2 的奖励要明显更差，并带负面**。因为 `docs/21` §3 判定它是 ❌ **不能算贡献**——
   他自己后来放弃了。**用机制表达历史判断**：选劳动军能拿到一些后勤/动员收益，
   但会付政治代价，且**不通向 IV3 的最优路径**。
   > 这一条是我最想推的：把一个"不能算贡献"的史实从**删除**改成**可选但更差**，
   > 既保留了戏剧性，又不歪曲历史评价。
3. **IV3 的前置是 `{ IV1 IV2 }`（同一块内 = OR）**。所以他**哪一次尝试失败都行**，
   最终都会走到"计划化"这个真正的贡献上——这正是历史的写法。

```text
prerequisite = { focus = hof_ic_trotsky_limited_market_reforms focus = hof_ic_trotsky_labour_armies }
# 同一 prerequisite 块内多个 focus = OR（任选其一）
# 多个 prerequisite 块并列 = AND（见德国 GER_blitzkrieg_across_the_pacific 的两个块）
```

> ⚠️🚩 **2026-09-16 修正（重要）**：IV1/IV2 虽然互斥，但**不能放进个人线驱动器的
> `$Branch`**。驱动器是「挑列表里第一个未完成的」→ 必然去点那条**已被互斥锁死的**。
> 官方文档对 `complete_national_focus` 只写「completes a focus for a country」，
> **没有**声明它尊重 `mutually_exclusive` → 结果是**卡死**（IV3 之后整条支线推进不了）
> **或**两条都被强推完成、互斥被架空。
>
> **现已改为岔路二选一事件**（`heartofiron.1060`，蓝本德国 `GER_inner_circle_himmler.00`）：
> - IV1/IV2 从 `$Branch` 移出，改由角色标记驱动
> - **2026-09-25 用户修订：入席国策完成即弹事件**，先决定日后进入经济支线时采用的方向；III2 前的驱动检查只作旧存档兜底
> - 玩家选定后，驱动器只点亮被选中的那一条，其余照常推进
>
> 落地细节见 `docs/18` §12；数据表在生成器的 `$pathChoiceOf`。

### 支线 V · 国际 / 殖民地（x=61）

| # | id | 名称 | 前置 | 史实锚点 | 奖励方向 |
| --- | --- | --- | --- | --- | --- |
| V1 | `hof_ic_trotsky_the_comintern_manifesto` | 共产国际宣言 | 入口 | 1919 与列宁共创第三国际并撰写首篇宣言 | 对共产国际/阵营影响 |
| V2 | `hof_ic_trotsky_the_chinese_question` | 中国革命问题 | **V1 + III2** | 1927 主张中共退出国民党、独立工农革命政策；被第三国际拒绝 → 大革命失败 | idea + 对 PRC/亚洲影响 |
| V3 | `hof_ic_trotsky_united_front` | 反法西斯统一战线 | V2 | 1930–33 主张社民党与共产党联合；1935 共产国际七大转向人民阵线 | idea + 对欧洲共产党影响 |

> ⚠️ **V2 有两个 prerequisite 块**（`{V1}` 和 `{III2}`）= **AND**。
> 这是**故意**的：`docs/21` §6 的跨簇钩子写得很清楚 —— 多伊彻明载
> **1927 中国革命问题是联合反对派斗争的「中心问题」**。
> 所以它**同时**属于国际线和党内斗争线。**用一个额外的 prerequisite 块把这条钩子脚本化**，
> 是本设计里唯一"跨支线"的连接点，也是让树从五条平行线变成一张网的关键。

### 汇合层（y=19，两个互斥）

> 📐 **坐标以生成器为准**（`build/gen-hof-ic-s3.ps1` 的 `$trotLine`），
> 这里写的是换算后的绝对值。个人线坐标都是**相对入口国策**的。
> 🚩 **2026-09-16 起入口 x 不再手写** —— 改由生成器 §10z 的**区块避让**自动推算
> （方法见 `docs/23` §2.7）。托洛茨基区块 dx −8..+2（宽 11），布哈林紧贴其右，
> 七席入口整排占列 −12..+12。→ **本节上面那些绝对列号一律已过期**，
> 以生成器每次打印的「区块避让」表为准。
> ⚠️ 汇合层两个结局的**实现**（2026-09-16 定案，照德国希姆莱）：
> 它们是**驱动器管的个人国策**（`available` 用和其它个人线国策同一段德国式双段 tooltip），
> 玩家不直接点 —— 支线走通 3 条时弹**二选一事件**（`heartofiron.1050`），
> 选项给托洛茨基打角色标记，驱动器读标记把选中的那一个推完。
> `count_triggers` 写在驱动器里，不写进 `available`。详见 `docs/11` §4.5 / `docs/18` §10.2。
> 三条支线只是**提前解锁终局的门槛**；终局完成后，托洛茨基应继续自动推进其余未完成的个人线国策。2026-09-29 修复终局完成事件漏排下一轮的问题，并为已停住的旧档加每周一次恢复，见 `docs/99` §103。
> 2026-09-15 已按**实测的原版惯例**收紧（`reference/reports/focus-spacing.txt`）：
> 分支间距 **2 格**（原版/R56 里 2 格占绝对多数），汇合层紧跟在支线末端下一行（y=19）。

| id | 名称 | 前置 | 说明 |
| --- | --- | --- | --- |
| `hof_ic_trotsky_the_permanent_revolutionary` | 永久的革命者 | 五条末端节点（一块内并列）+ `count_triggers = { amount = 3 }` | 走向**国际革命** |
| `hof_ic_trotsky_the_builder_of_the_state` | 国家建设者 | 同上 | 走向**国内建设** |

**为什么是两个互斥结局**：
1. **照德国**：`GER_a_strong_successor` vs `GER_loyalty_to_the_fuhrer` 就是互斥的两个收束。
2. **史实有真实张力**：`docs/21` §6 明确指出「他既要**加速工业化**、又反对**一国社会主义**」
   —— 这是一个尖锐矛盾，正好做成两个方向的收束。
3. **`amount = 3`**（不是 5）：照德国，**五条里走通三条即可**，不要求全通。
   这样支线多寡不影响可行性，但走得越多越早解锁。

---

## 5. 与 R56 的避让（必查）

| R56 已有 | 我们不能做 | 本文怎么处理 |
| --- | --- | --- |
| `SOV_the_fourth_international` | 再发一次第四国际 | **完全不写第四国际**（支线 V 止于 V3） |
| `SOV_return_democracy_to_the_party`、`SOV_dissent_in_the_party` | 再发泛泛的「党内民主」 | 支线 III 只留 2 个，且走**具体主张** |
| `SOV_the_left_opposition` 三选一支线 | 把本树挂它下面 | 只认「是否入席」 |
| `SOV_integrate_smirnovs_bloc` | 再处理斯米尔诺夫 | 留给 6 号人物那节 |
| `SOV_the_supreme_soviet` | 重复它的领袖/派系效果 | 只当前置，不复制奖励 |

---

## 6. 待办与风险

| 项 | 说明 |
| --- | --- |
| **图标** | 全部图标名**尚未核实存在**。两条路：① 照德国做专属图 `GFX_focus_hof_ic_trotsky_*`（17 张，量不小）② 复用 R56 已用过的现成 GFX（需逐个验证名字） |
| **idea 名** | 表中所有 `HOF_ic_trotsky_*` 的 idea 都**还未创建**，且**修正词条必须照原版 ideas 词汇表抄**（AGENTS.md 规则 7） |
| **`text_icon`** | 若要用核心圈专属标题条样式，须**整文件复制**原版 `00_titlebar_styles.txt` 并加自己的 style（AGENTS.md 规则 2） |
| **时间常量** | 德国子线用 `@inner_circle_time_tier_1/2/3 = 20/20/40`。本设计按你的要求全用 `cost = 2`；若想让子线有"长项目"感，可自定 `@hof_ic_time_tier_N` —— **这是个可调项，需你定** |
| **本地化** | 17 个新国策的 `<id>` 与 `<id>_desc` 键，外加全部 idea 键 |

---

## 7. 我为什么这样设计（浓缩版理由）

1. **按簇分线，不按领域分线** —— 领域之间没有推导关系，所以上一版串不起来；簇内成员互为依据，天然成链。
2. **理论线做成 prerequisite 链条** —— 不平衡发展 → 不断革命论 是**真实的推导关系**，用前置把它画进树里，玩家能感到"这条线有逻辑"。
3. **把「被否决」做成机制，而不是删掉** —— 劳动军（❌ 不能算贡献）不做成删除，而做成**与市场互斥、收益更差**的选项。机制承担了历史评价。
4. **两次失败都通向后来的真正贡献** —— 计划化的前置是「市场 **或** 劳动军」，因为历史上他就是两条路都试过、才走到计划化。
5. **唯一一条跨支线连接** —— 「中国革命问题」同时需要国际线节点**和**党内民主线节点，因为多伊彻明载它是联合反对派斗争的**中心问题**。这条 prerequisite 就是那张谱系图的边。
6. **两个互斥结局** —— 照德国汇合层；且他本人确实有「国际革命者 / 国家建设者」的双重性。
7. **`amount = 3` 而非 5** —— 照德国：五条走通三条即可，支线多寡不成为门槛。

---

## 8. 落实细节：数值与文本

### 8.0 通用模板（照德国核心圈，已实测）

> 📌 **本节已被 `docs/11` §4.1（数值宪法）取代**，那节有全部 7 条升级链与每层 modifier 原文。
> 这里只留最容易被抄错的骨架。

德国每个**职务特质**的结构（`common/ideas/GER.txt`，逐层核对过）：

```text
GER_todt_reich_engineer = {                  # T1：入口给的
    allowed = { always = no }
    removal_cost = -1
    modifier = {
        political_power_gain = -0.1          # 业务岗：入圈要付政治点
        production_speed_industrial_complex_factor = 0.1
        production_speed_infrastructure_factor = 0.1
        production_speed_rail_way_factor = 0.1
    }
}

GER_todt_reich_minister_of_armaments = {     # T2：国策 swap_ideas 升上来的
    allowed = { always = no }
    removal_cost = -1
    modifier = {
        political_power_gain = -0.3          # ← 官越大越吃政治点
        ...（T1 三条一字不改）
        production_speed_arms_factory_factor = 0.1
        production_speed_dockyard_factor = 0.1
    }
}
```

> 📌 **三条可直接套用的结论**：
> 1. `political_power_gain` **随层级加深**：入口 −0.10 → 二级及以后 −0.30。
>    **例外且有意义**：赫斯 / 鲍曼是 **+0.15 → +0.4**，因为他们是"替领袖办党务"的人，
>    反而**产**政治点。**符号本身就是设计**，别一刀切。
> 2. `allowed = { always = no }` + `removal_cost = -1` **每一层都要写**，
>    表示不可手动添加、不可移除，只能由国策给出。
> 3. **高层 = 低层的严格超集**（逐字照抄 + 追加 2~4 条），不是重写。

**修正词条词汇表（已从苏联 idea 实测，不是猜的）** —— 见 `reference/reports/sov-idea-words-report.txt`：

| 领域 | 可用词条（实测出现过） |
| --- | --- |
| 政治 | `political_power_factor` `political_power_gain` `stability_factor` `war_support_factor` `communism_drift` `drift_defence_factor` `stability_weekly` `command_power_gain_mult` |
| 军事 | `army_org_factor` `army_morale_factor` `training_time_factor` `land_doctrine_cost_factor` `conscription` `mobilization_speed` `army_core_attack_factor` `army_core_defence_factor` `max_dig_in_factor` `surrender_limit` `send_volunteer_factor` `equipment_capture_factor` |
| 经济 | `consumer_goods_factor` `industrial_capacity_factory` `repair_speed_factor` `production_speed_industrial_complex_factor` `production_speed_arms_factory_factor` `production_speed_buildings_factor` `production_factory_max_efficiency_factor` `production_efficiency_gain_factor` |
| 科研 | `research_speed_factor` |

**国策奖励只用已核实的写法**：`add_political_power` / `add_popularity` / `add_ideas` /
`swap_ideas` / `add_timed_idea` / `add_tech_bonus`（`category = industry` 已在 R56 苏联树用过）/
`add_extra_state_shared_building_slots` + `add_building_construction`。

### 8.1 「返聘沙俄军官」点谁的名（**已实测游戏内真有**）

扫了 531 个角色文件，**游戏内确实存在的沙俄旧军官**：

| 角色 id | 姓名 | 沙俄身份 | 游戏内身份（实测） |
| --- | --- | --- | --- |
| `SOV_boris_shaposhnikov` | 鲍里斯·沙波什尼科夫 | **沙俄上校、总参谋部** | `advisor` + `corps_commander`（skill 3） |
| `SOV_aleksandr_yegorov` | 亚历山大·叶戈罗夫 | 沙俄军官 | `advisor` + `field_marshal`（skill 3 / planning 4） |
| `SOV_mikhail_tukhachevsky` | 米哈伊尔·图哈切夫斯基 | 沙俄中尉 | `advisor` + `field_marshal`（skill 4 / `brilliant_strategist`） |
| `SOV_august_kork` | 奥古斯特·科尔克 | **沙俄总参谋部上校** | `advisor` + `field_marshal`（skill 4 / `career_officer organizer`） |
| `SOV_aleksandr_verkhovsky` | 亚历山大·韦尔霍夫斯基 | 沙俄上校、临时政府军事部长 | `advisor` |
| `SOV_aleksandr_prokofyev_seversky` | 亚历山大·谢韦尔斯基 | 沙俄少将 | `advisor` |

> ⚠️ **一个重要的否定发现**：**谢尔盖·加米涅夫**（红军总司令 1919–24，最典型的军事专家）
> **游戏里没有** —— 全名匹配只命中 `SOV_lev_kamenev`（那是政治家列夫·加米涅夫，同姓不同人）。
> 所以只能从前 6 个里点名。

**建议**：I2 的文本里点名**沙波什尼科夫 + 科尔克**（两个都是总参谋部上校出身，最贴合"军事专家"），
奖励给 `advisor` 相关的军事加成；图哈切夫斯基知名度最高，可放在描述里提一句。

### 8.2 逐条数值（**已按德国尺度重写**）

> ⚠️ **这一节推翻了上一版。** 上一版写的是"每条国策挂一个新的 idea" ——
> 结果 17 条国策 = 17 个**同时挂着**的精神。那是**国策**的写法，不是**个人特质**的写法。
> 德国实测模型见 **`docs/11` §4.1（数值宪法）**；
> 数据原文 `reference/reports/ger-ic-swap-chains.txt`、`reference/reports/ger-ic-idea-tiers.txt`。

#### 8.2.1 托洛茨基的职务链：**照抄德国** —— 职务 idea 进 `hidden_ideas`，`swap_ideas` 升级

> ✅ **定案：完全照德国的结构，不给任何人新建 dynamic_modifier。**
>
> | 层 | 载谁 | 官方证据 |
> | --- | --- | --- |
> | **可见民族精神** | **整个核心圈只有 1 个**：`hof_ic_supreme_soviet_dm` | 德国 `GER_the_inner_circle_dm` |
> | **职务 idea** | `ideas = { hidden_ideas = { hof_ic_lev_trotsky* } }` —— **不占精神格** | 德国 `common/ideas/GER.txt` L11339 |
> | **官衔名的显示** | 容器精神的 tooltip → `defined_text` → `hof_ic_slot_N_name` | 德国 `GetAscendedAdvisorN` |
>
> 🚨 **职务 idea 放在 `hidden_ideas`，所以满席时精神条上仍然只有「最高苏维埃」那一个。**
> 跟德国一模一样。`hidden_ideas` 是原版真实 category
> （`common/idea_tags/00_idea.txt` L8：`hidden = yes` / `cost = 0` / `ledger = hidden`）。
>
> 🚨 **不需要 4 个近似 DM id，也不需要变量。** 数值直接硬编码在职务 idea 的分级里。
>
> ⚠️ **我先前设计过「每人一个 DM，用 `remove/add_dynamic_modifier` 换官衔名」—— 那是我发明的，德国没有。**
> 德国把官衔名交给 `defined_text` 动态求值，所以"DM 名字改不了"这个问题**根本不成立**
> （见 `docs/11` §4.2.0）。已废弃。

| 层 | 职务 idea id | 显示名（史实职务） | 由哪条国策升上去 |
| --- | --- | --- | --- |
| T1 | `hof_ic_idea_lev_trotsky` | **陆海军人民委员** | 入口国策 `hof_ic_seat_lev_trotsky`（S3 已有，需改成 `add_ideas`） |
| T2 | `hof_ic_idea_lev_trotsky_2` | **革命军事委员会主席** | I3 `..._against_partisan_warfare` 完成时 |
| T3a | `hof_ic_idea_lev_trotsky_3a` | **共产国际执行委员会主席** | 汇合A `..._the_permanent_revolutionary` |
| T3b | `hof_ic_idea_lev_trotsky_3b` | **人民委员会副主席** | 汇合B `..._the_builder_of_the_state` |

> 📋 **级数要不要加，取决于 §8.2.4 的数值怎么分段。**
> 德国每人 2~3 级；我们若要让"五条支线各给一级"，就按同一模板往上加到 T6。
> 每级都是「**照抄下一级 + 追加**」，列多加几条而已，结构不变。

**升级的写法 —— 照德国「按国策反推等级」，不要存状态变量**

德国**不记**"他升到第几级"，而是每次重新用 `has_completed_focus` 算一遍
（`GER_add_himmler_effects` / `GER_remove_himmler_effects`，
`common/scripted_effects/GER_scripted_effects.txt` L3102 起）。我们照抄：

```text
# scripted_effect：hof_ic_idea_lev_trotsky_sync_rank
# ① 先全清（每个等级各一段，德国 GER_remove_*_effects 原样）
if      = { limit = { has_idea = hof_ic_idea_lev_trotsky_3a } remove_ideas = hof_ic_idea_lev_trotsky_3a }
else_if = { limit = { has_idea = hof_ic_idea_lev_trotsky_3b } remove_ideas = hof_ic_idea_lev_trotsky_3b }
else_if = { limit = { has_idea = hof_ic_idea_lev_trotsky_2 }  remove_ideas = hof_ic_idea_lev_trotsky_2 }
else_if = { limit = { has_idea = hof_ic_idea_lev_trotsky }    remove_ideas = hof_ic_idea_lev_trotsky }

# ② 再按国策反推该给哪一级（德国 GER_add_*_effects 原样）
if      = { limit = { has_completed_focus = ..._the_permanent_revolutionary } add_ideas = hof_ic_idea_lev_trotsky_3a }
else_if = { limit = { has_completed_focus = ..._the_builder_of_the_state }    add_ideas = hof_ic_idea_lev_trotsky_3b }
else_if = { limit = { has_completed_focus = ..._against_partisan_warfare }    add_ideas = hof_ic_idea_lev_trotsky_2 }
else_if = { limit = { hof_ic_seated_lev_trotsky = yes }                       add_ideas = hof_ic_idea_lev_trotsky }
```

> 💡 **四个场景共用一个 effect**：入席 / 升官 / 换人 / 卸任 —— 全部调
> `hof_ic_lev_trotsky_sync_rank = yes`。国策里的"升级"就这一行，
> **不需要在国策里手写 remove/add**，也就永远不会漏清旧等级。
> 这就是德国解决"残留"的办法 —— 不存状态，就不存在状态不对。
>
> ⚠️ 与德国唯一的差别：德国在国策里写 `swap_ideas`（带 tooltip 好看），
> 我们统一走 `sync_rank`（因为国策可能以任意顺序完成，必须反推）。
> 想要 tooltip 就再补一句 `show_ideas_tooltip = <目标职务 idea>`。

> 📌 **为什么可以不用动态修正**：数值硬编码进职务 idea 就够了
> —— 因为**等级变更只发生在有限几个国策节点上**（德国 2~3 个，我们 6~7 个），
> 不需要"每条国策都改一点"的那种连续累积。
> 如果确实需要连续累积，再按 §4.2 的方式补一个辅助 dynamic_modifier（德国也这么做，
> 但那是**额外**数值，不是官衔本体）。

**史实依据**：
- 1918-03-14 任**陆海军人民委员**（Нарком по военным и морским делам）
- 1918-09-06 任**革命军事委员会主席**（Председатель РВСР）—— 红军真正的缔造者
- 1922 列宁《给代表大会的信》中指名他为副手人选（→ 人民委员会副主席）
- 1919 与列宁共创第三国际、撰写首篇宣言（→ 共产国际执委会主席）

> ⚠️ **T3a 属 alt-history，需要你确认**：该职史实上由季诺维也夫（1919–26）、
> 布哈林（1926–29）担任。设定"他赢了权力斗争便会落到他头上"是合理的，
> 代价是**要在这条树上多写一句本可避免的设计**。
> **T3b 无此问题**（列宁遗嘱有据）。若你想砍掉 alt-history，可只留 T3b，
> 汇合A 不再升官衔、只给数值 —— 但两个结局的强度就不对称了。

#### 8.2.2 四个等级 = **同一套模板**（改数值只改一处）

> **现行实现修订（2026-09-27）：**下面的代码块是早期示意，政治点代价与 T1/T2 数值已不代表当前生成结果；现行职务数值以 `build/gen-hof-ic-s3.ps1` 的 `lev_trotsky` `Tiers` 为准。「反对游击主义」升到 T2 时增加 `command_power_gain_mult = 0.10`（指挥点数增长 +10%），T3a/T3b 两条后续职务都继承这项收益，避免晋升时只看见政治点代价。

```text
ideas = {
	hidden_ideas = {

		hof_ic_idea_lev_trotsky = {                 # T1 —— 模板
			allowed = { always = no }
			removal_cost = -1
			modifier = {
				political_power_gain = -0.10          # 入圈代价（硬编码，跟等级走）
				army_org_factor = 0.05
				army_attack_factor = 0.05
			}
		}

		hof_ic_idea_lev_trotsky_2 = {               # T2 —— 上面全部照抄 + 追加
			allowed = { always = no }
			removal_cost = -1
			modifier = {
				political_power_gain = -0.10
				army_org_factor = 0.05
				army_attack_factor = 0.05
				supply_consumption_factor = -0.05     # 追加
				breakthrough_factor = 0.05            # 追加
			}
		}

		# ... T3a / T3b 同理
	}
}
```

> 📌 **每级的 `modifier` = 下级全部照抄 + 追加 2~4 条**（德国实测规律，见 `docs/11` §4.1）。
> `political_power_gain` **硬编码**、跟着等级走（德国 `-0.1 → -0.3`）。
> 官衔名用 idea 自己的本地化键（`hof_ic_idea_lev_trotsky:0 "陆海军人民委员"`），
> **不需要动任何 DM**。

> 🚨 **三条实现红线**：
> ① 入席 / 升官 / 换人 / 卸任**全部走 `hof_ic_idea_<key>_sync_rank`**（见 §8.2.1），
>    不要在国策或事件里手写某一级的 `remove_ideas` / `add_ideas` —— 手写才会残留；
> ② 外层**必须**是 `ideas = { hidden_ideas = { ... } }`。
>    把 idea 块直接写在文件根级 = **静默不注册**（游戏不报错，但 idea 根本不存在，
>    精神条上也不会出现）。`verify-s2.ps1` §11.0b 已加专项检查；
> ③ 若确实需要"每条国策都加一点"的**连续累积**，再按 `docs/11` §4.2 补一个辅助
>    dynamic_modifier（`add_to_variable` + 「值 = 变量名」）。
>    德国也这么做，但那是**额外**数值 —— 官衔本体始终在 idea 上。

#### 8.2.3 个人线国策怎么给他叠数值（**已实测的机制**）

> 🚨 **上一版这里是错的。** 上一版让每条国策发一次性奖励（政治点 / 工厂 / 科技加成）——
> 那只回答了"这条国策给**国家**什么"，完全没回答"这条国策让**托洛茨基**强了多少"。
> **个人线存在的意义就是后者**：点一条，他身上那件东西就更强一分。

R56 的现成写法（`common/dynamic_modifiers/0_dynamic_modifiers.txt`，原文逐字核对）：

```text
SOV_defense_industry_dynamic_modifier = {
	enable = { always = yes }
	icon = GFX_idea_man_five_year_plan_tank
	conversion_cost_civ_to_mil_factor = SOV_defense_industry_conversion_cost_civ_to_mil_factor
	...
	#FUTURE
	tank_manufacturer_cost_factor = SOV_defense_industry_tank_manufacturer_cost_factor  #-0.25 -> Tank Designer focus
	land_equipment_upgrade_xp_cost = SOV_defense_industry_land_equipment_upgrade_xp_cost #-0.1  -> Tankograd
	breakthrough_factor = SOV_defense_industry_breakthrough_factor                       #0.05  -> PC of Mortar Armament
	army_artillery_defence_factor = SOV_defense_industry_army_artillery_defence_factor   #0.05  -> PC of Mortar Armament
	max_dig_in_factor = SOV_defense_industry_max_dig_in_factor                           #0.05  -> Military Engineering University
}
```

**关键**：修正项的值直接写**变量名**，国策里 `add_to_variable` 往那个变量加值。
`SOV_the_politburo_good_dynamic_modifier` 有 **18 条**这样的修正，**每条都注着是哪个国策给的**。

以下是早期个人动态修正方案，**已由 2026-09-26 的静态职务 idea 版本替代**（见 `docs/99` §73）。数值表仍以本文件 §8.2.4 为准。

旧方案的形态是：

```text
hof_ic_lev_trotsky_dm = {                  # ← 他的"个人特质"（数值体）
	icon = GFX_idea_generic_political_support
	enable = { hof_ic_seated_lev_trotsky = yes }
	remove_trigger = { NOT = { has_government = communism } }

	army_org_factor           = hof_ic_lev_trotsky_army_org       #0.05  -> I1 缔造红军
	army_attack_factor        = hof_ic_lev_trotsky_army_attack    #0.05  -> I3 反对游击主义
	supply_consumption_factor = hof_ic_lev_trotsky_supply         #-0.05 -> I3 反对游击主义
	...
}
```

国策那一侧就只有两行：

```text
completion_reward = {
	add_to_variable = { hof_ic_lev_trotsky_army_attack = 0.05 }
	add_to_variable = { hof_ic_lev_trotsky_supply = -0.05 }
}
```

**现行性质**：国策完成状态决定当前职务 idea 内的累计数值；变量只保留原有国策提示账本。一次性奖励按各国策的 `Raw` 另行执行。

#### 8.2.4 17 条国策逐条的数值贡献

表中数值逐条计入已完成节点对应的静态职务 idea；`add_to_variable` 只保留国策提示账本，不再由 `hof_ic_lev_trotsky_dm` 提供实际效果。

> **读表方式**：变量名 = `hof_ic_lev_trotsky` + 「变量后缀」。
> 例：`_army_attack` → 变量 `hof_ic_lev_trotsky_army_attack`。
> **增量正的 = 好处；负的 = 也是好处**（花费、消耗、损耗这类词条，数字越小越好）。
> 唯一例外是 IV2 的稳定度，见文末。
>
> **词条全部实测核实过**（`reference/reports/military-modifier-words.txt`、`modifier-words-2.txt`）。
> 🚩 **兵种级词条的真名带 `modifier_` 前缀** —— 是 `modifier_army_sub_unit_infantry_attack_factor`，
> **不是** `army_sub_unit_infantry_attack_factor`（后者不存在，写了静默无效）。

**支线 I · 红军缔造 —— 组织 / 经验 / 进攻 / 补给 / 兵种**

| # | 国策 | 变量后缀 | 词条（脚本里写这个） | 中文含义 | 增量 |
| --- | --- | --- | --- | --- | --- |
| I1 | 缔造红军 | `_army_org` | `army_org_factor` | 陆军组织度 | +0.05 |
| I1 | | `_training_time` | `training_time_factor` | 训练时间 | −0.05 |
| I2 | 返聘沙俄军官 | `_experience_gain_army` | `experience_gain_army_factor` | 陆军经验获取 | +0.05 |
| I2 | | `_land_doctrine_cost` | `land_doctrine_cost_factor` | 陆军学说花费 | −0.05 |
| **I2** | | `_infantry_attack` | `modifier_army_sub_unit_infantry_attack_factor` | **步兵进攻** | **+0.05** |
| **I2** | | `_cavalry_attack` | `modifier_army_sub_unit_cavalry_attack_factor` | **骑兵进攻** | **+0.05** |
| **I3** | 反对游击主义 ★升 T2 | `_army_attack` | `army_attack_factor` | **陆军进攻** | **+0.05** |
| **I3** | | `_supply` | `supply_consumption_factor` | **补给消耗** | **−0.05** |
| I3 | | `_attrition` | `attrition` | 损耗 | −0.05 |

> I2 还**额外动到两个人身上**（升技能），见 §8.2.5。

**支线 II · 理论根干 —— 工业跨越 / 意识形态 / 武装输出革命**

| # | 国策 | 变量后缀 | 词条 | 中文含义 | 增量 |
| --- | --- | --- | --- | --- | --- |
| II1 | 不平衡与综合发展律 | `_production_speed_industrial_complex` | `production_speed_industrial_complex_factor` | 民用工厂建造速度 | +0.05 |
| II1 | | `_industrial_capacity` | `industrial_capacity_factory` | 工厂产出 | +0.05 |
| II2 | 不断革命论 | `_communism_drift` | `communism_drift` | 每日共产主义支持漂移 | +0.02 |
| II2 | | `_drift_defence` | `drift_defence_factor` | 意识形态漂移抵抗 | +0.10 |
| **II2** | | `_no_supply_grace` | `no_supply_grace` | **携行补给** | **+72 小时** |
| II3 | 驳「一国社会主义」 | `_send_volunteer` | `send_volunteer_factor` | 派遣志愿军规模 | +0.25 |
| II3 | | `_opinion_same_ideology` | `opinion_gain_monthly_same_ideology_factor` | 同意识形态国家好感月增长 | +0.25 |

**支线 III · 党内民主 —— 政治**

| # | 国策 | 变量后缀 | 词条 | 中文含义 | 增量 |
| --- | --- | --- | --- | --- | --- |
| III1 | 新方针 | `_political_power` | `political_power_factor` | 政治点获取 | +0.05 |
| III2 | 反对官僚化 | `_stability` | `stability_factor` | 稳定度 | +0.05 |
| III2 | | `_political_advisor_cost` | `political_advisor_cost_factor` | 政治顾问花费 | −0.10 |

**支线 IV · 经济 —— 生产系数，不给工厂实体**

| # | 国策 | 变量后缀 | 词条 | 中文含义 | 增量 |
| --- | --- | --- | --- | --- | --- |
| IV1 | 有限市场化 | `_consumer_goods` | `consumer_goods_factor` | 消费品需求 | −0.05 |
| **IV1** | | `_stability` | `stability_factor` | **稳定度** | **+0.05** ² |
| **IV1** | | `_production_speed_industrial_complex` | `production_speed_industrial_complex_factor` | **民用工厂建造速度** | **+0.10** ² |
| **IV1** | | `_industrial_capacity` | `industrial_capacity_factory` | **工厂产出** | **+0.05** ³ |
| **IV2** | 劳动军 ⚠️ | `_industrial_capacity` | `industrial_capacity_factory` | 工厂产出 | +0.05 |
| IV2 | | `_war_support` | `war_support_factor` | 战争支持度 | +0.05 |
| **IV2** | | `_stability` | `stability_factor` | 稳定度 | **−0.05** ⚠️ 唯一真负面 |
| IV3 | 经济计划化 | `_production_speed_buildings` | `production_speed_buildings_factor` | 建筑建造速度 | +0.05 |
| IV3 | | `_industrial_capacity` | `industrial_capacity_factory` | 工厂产出 | +0.05 |
| **IV3** | | `_consumer_goods` | `consumer_goods_factor` | 消费品需求 | **−0.05** |
| **IV3** | | `_line_change_efficiency` | `line_change_production_efficiency_factor` | 换线生产效率惩罚 | **−0.05** |
| **IV4** | 加速工业化 | `_production_speed_buildings` | `production_speed_buildings_factor` | **建筑建造速度** | **+0.10** |
| **IV4** | | `_factory_max_efficiency` | `production_factory_max_efficiency_factor` | **生产效率上限** | **+0.05** |
| **IV4** | | `_factory_efficiency_gain` | `production_factory_efficiency_gain_factor` | **生产效率增长** | **+0.05** |

> IV4 原来只给 `production_speed_arms_factory_factor`（军工厂建造速度）—— 那太窄了，
> 改成**建筑建造速度**（含所有建筑）+ **生产效率的两个词条**。这正是"加速工业化"该给的。

> ² **2026-09-16 补强 IV1**（用户口径：「有限市场化的数值词条需要再加一到两个，
> 不然它实际上没有比劳动军强力，哪怕劳动军有负面词条」）。
> 原稿 IV1 只有 1 条（消费品需求 −0.05），而 IV2 是 2 正 1 负 ——
> **历史上被证明正确的那条反而更弱**，与本树「用机制承担历史评价」的意图相反。
> 现补齐到 3 条正收益，明确强于 IV2：
>
> | | 词条 | 计 |
> | --- | --- | --- |
> | **IV1 有限市场化** | 消费品需求 −5%、稳定度 +5%、民用工厂建造 +10% | **3 正** |
> | **IV2 劳动军** | 工厂产出 +5%、战争支持 +5%、**稳定度 −5%** | 2 正 **1 负** |
>
> ³ **2026-09-25 用户追加**：IV1「有限市场化」再增加工厂产出 +5%，成为 4 条正收益。该词条与互斥的 IV2「劳动军」可以分别出现，不会在同一条路线重复领取。
>
> ⚠️ 两条新词条刻意**避开本线已用过的** `production_speed_buildings`
> （IV3 / IV4 在用），改用 `production_speed_industrial_complex`（民用工厂）。
> ⚠️ 两个官方 tooltip 键都已实测存在（`stability_factor_tt` /
> `production_speed_industrial_complex_factor_tt`），**不需要自造本地化**。

**支线 V · 国际 —— 外交关系 / 意识形态输出**

| # | 国策 | 变量后缀 | 词条 | 中文含义 | 增量 |
| --- | --- | --- | --- | --- | --- |
| V1 | 共产国际宣言 | `_communism_drift` | `communism_drift` | 每日共产主义支持漂移 | +0.02 |
| **V1** | | `_opinion_monthly` | `opinion_gain_monthly_factor` | **各国好感月增长** | **+0.25** |
| **V1** | | `_opinion_same_ideology` | `opinion_gain_monthly_same_ideology_factor` | 同意识形态国家好感月增长 | **+0.25** |
| **V1** | | `_boost_ideology_mission` | `boost_ideology_mission_factor` | 意识形态宣传任务效果 | **+0.15** |
| V2 | 中国革命问题 | `_send_volunteer` | `send_volunteer_factor` | 派遣志愿军规模 | +0.25 |
| **V2** | | `_supply` | `supply_consumption_factor` | **补给消耗**（苏俄与中国革命共同的难题） | **−0.05** |
| **V2** | | `_opinion_monthly` | `opinion_gain_monthly_factor` | **各国好感月增长** | **+0.25** |
| V3 | 反法西斯统一战线 | `_drift_defence` | `drift_defence_factor` | 意识形态漂移抵抗 | +0.15 |
| **V3** | | `_opinion_monthly` | `opinion_gain_monthly_factor` | **各国好感月增长** | **+0.25** |
| **V3** | | `_subversive_upkeep` | `subversive_activites_upkeep` | 颠覆活动维持费 | **−0.10** |

> V2 还**给中共一个专属外交修正**（一次性），见 §8.2.6。

**汇合层 —— 两倍量级，两条路彻底分开**

| 国策 | 变量后缀 | 词条 | 中文含义 | 增量 |
| --- | --- | --- | --- | --- |
| **汇合A** 永久的革命者 ★升 T3a | `_communism_drift` | `communism_drift` | 每日共产主义支持漂移 | +0.05 |
| | `_send_volunteer` | `send_volunteer_factor` | 派遣志愿军规模 | **+0.50** |
| | `_operative_slot` | `operative_slot` | 特工位 | **+1** |
| | `_boost_ideology_mission` | `boost_ideology_mission_factor` | 意识形态宣传任务效果 | +0.25 |
| | `_army_attack` | `army_attack_factor` | **陆军进攻** | **+0.05** |
| | `_breakthrough` | `breakthrough_factor` | **突破** | **+0.05** |
| | `_army_org` | `army_org_factor` | **陆军组织度** | **+0.05** |
| | `_combat_width` | `combat_width_factor` | **己方战场宽度**（负数 = 同样兵力占更多宽度） | **−0.25** |
| | `_armor_attack` | `army_armor_attack_factor` | **装甲单位攻击** | **+0.10** |
| **汇合B** 国家建设者 ★升 T3b | `_industrial_capacity` | `industrial_capacity_factory` | 工厂产出 | **+0.10** |
| | `_production_speed_buildings` | `production_speed_buildings_factor` | 建筑建造速度 | **+0.10** |
| | `_factory_max_efficiency` | `production_factory_max_efficiency_factor` | **生产效率上限** | **+0.10** |
| | `_factory_efficiency_gain` | `production_factory_efficiency_gain_factor` | **生产效率增长** | **+0.05** |
| | `_army_defence` | `army_defence_factor` | 陆军防御 | **+0.10** |
| | `_army_core_defence` | `army_core_defence_factor` | 核心领土防御 | +0.05 |
| | `_max_dig_in` | `max_dig_in_factor` | 最大堑壕 | **+0.10** |
| | `_local_resources` | `local_resources_factor` | **本地资源产量** | **+0.10** |
| | `_building_slots` | `global_building_slots_factor` | **建筑位**（各州可多建工厂） | **+0.10** |

> **两条路现在各自成体系**：
> **A = 武装输出革命**（进攻 / 突破 / 组织 + 志愿军 + 特工 + 宣传），
> **B = 国家建设**（工厂产出 / 生产效率上限 + 增长 / 建筑速度 + 固守）。
> 不是"一边给国际一边给两个工厂"。

**累加总览**

| 中文含义 | 词条 | 汇合A 路线 | 汇合B 路线 |
| --- | --- | --- | --- |
| 陆军组织度 | `army_org_factor` | +0.10 | +0.05 |
| 训练时间 | `training_time_factor` | −0.05 | −0.05 |
| 陆军经验获取 | `experience_gain_army_factor` | +0.05 | +0.05 |
| 陆军学说花费 | `land_doctrine_cost_factor` | −0.05 | −0.05 |
| **步兵进攻** | `modifier_army_sub_unit_infantry_attack_factor` | +0.05 | +0.05 |
| **骑兵进攻** | `modifier_army_sub_unit_cavalry_attack_factor` | +0.05 | +0.05 |
| **携行补给** | `no_supply_grace` | +72 小时 | +72 小时 |
| **陆军进攻** | `army_attack_factor` | +0.10 | +0.05 |
| **突破** | `breakthrough_factor` | +0.05 | — |
| **己方战场宽度** | `combat_width_factor` | **−0.25** | — |
| **装甲单位攻击** | `army_armor_attack_factor` | **+0.10** | — |
| **陆军防御** | `army_defence_factor` | — | +0.10 |
| **核心领土防御** | `army_core_defence_factor` | — | +0.05 |
| **最大堑壕** | `max_dig_in_factor` | — | +0.10 |
| 补给消耗 | `supply_consumption_factor` | −0.10 | −0.10 |
| 损耗 | `attrition` | −0.05 | −0.05 |
| 每日共产主义支持漂移 | `communism_drift` | +0.09 | +0.04 |
| 意识形态漂移抵抗 | `drift_defence_factor` | +0.25 | +0.25 |
| 派遣志愿军规模 | `send_volunteer_factor` | **+1.00** | +0.50 |
| 各国好感月增长 | `opinion_gain_monthly_factor` | +0.75 | +0.75 |
| 同意识形态好感月增长 | `opinion_gain_monthly_same_ideology_factor` | +0.50 | +0.50 |
| 意识形态宣传任务效果 | `boost_ideology_mission_factor` | +0.40 | +0.15 |
| 颠覆活动维持费 | `subversive_activites_upkeep` | −0.10 | −0.10 |
| 政治点获取 | `political_power_factor` | +0.05 | +0.05 |
| 稳定度 | `stability_factor` | +0.05 | +0.05 |
| 政治顾问花费 | `political_advisor_cost_factor` | −0.10 | −0.10 |
| 消费品需求 | `consumer_goods_factor` | −0.10 | −0.10 |
| 换线生产效率惩罚 | `line_change_production_efficiency_factor` | −0.05 | −0.05 |
| 工厂产出 | `industrial_capacity_factory` | +0.15 | **+0.25** |
| 民用工厂建造速度 | `production_speed_industrial_complex_factor` | +0.15 或 +0.05 | +0.15 或 +0.05 |
| 建筑建造速度 | `production_speed_buildings_factor` | +0.15 | **+0.25** |
| **生产效率上限** | `production_factory_max_efficiency_factor` | +0.05 | **+0.15** |
| **生产效率增长** | `production_factory_efficiency_gain_factor` | +0.05 | **+0.10** |
| **本地资源产量** | `local_resources_factor` | — | **+0.10** |
| **建筑位** | `global_building_slots_factor` | — | **+0.10** |
| 战争支持度 | `war_support_factor` | +0.05 | +0.05 |
| 特工位 | `operative_slot` | **+1** | — |

民用工厂建造速度的两个总值分别对应「有限市场化」与「劳动军」互斥分叉。此次按用户要求移除了托洛茨基职务晋升链中的陆军指挥官花费、I2 的将领花费，以及 II2 和汇合 A 的核心领土进攻；这些词条不再计入总览。

> 📌 **`send_volunteer_factor` 合计 +100% —— 不用改。** 你指出得对：这个基数本来就低，
> 原版/R56 的民族精神普遍给到 +25%~+50%，+100% 也未必能多派出几个师。
> 保留汇合A 的 `+0.50`。

**IV2「劳动军」仍是唯一带真负面的**：`stability_factor` 记 **−0.05**，且**不触发任何职务升级**。
用数值表达 `docs/21` §3 对它的 ❌ 判定。

**升级触发点**：T2 挂在 **I3**（军职 → 军事簇末端）；T3 挂在**两个汇合**（国家 / 国际层面）。
**层级跟着权力范围走**，跟德国"帝国工程师 → 帝国军备部长"同一条逻辑。

#### 8.2.5 I2「返聘沙俄军官」附带的将领奖励（一次性效果）

个人线国策**原则上只写 `add_to_variable`**（§8.2.3）。**I2 是唯一例外** ——
这条讲的正是"把沙俄军官请回来"，所以它该真的**动到那几个人身上**。

已核实的写法（`common/decisions/r56_POL_decisions.txt` 原文，逐字）：

```text
add_trait = { trait = panzer_expert }
add_skill_level = 3
add_attack = 3
add_defense = 3
add_logistics = 3
```

按 §8.1 实测存在的沙俄旧军官，点名 **沙波什尼科夫** 与 **科尔克**（两人都是沙俄总参谋部上校）：

```text
completion_reward = {
	add_to_variable = { hof_ic_lev_trotsky_experience_gain_army = 0.05 }
	...（§8.2.4 的 I2 那几行）
	if = {
		limit = { has_character = SOV_boris_shaposhnikov }
		SOV_boris_shaposhnikov = {
			add_skill_level = 1
			add_logistics = 1
		}
	}
	if = {
		limit = { has_character = SOV_august_kork }
		SOV_august_kork = {
			add_skill_level = 1
			add_attack = 1
		}
	}
}
```

> ✅ **已建文件（2026-09）**：`common/unit_leader/hof_ic_traits.txt` —— `trait_hof_ic_tsarist_officer`
> （陆军组织度 +5%、步兵进攻 +5%），授予写法 `add_unit_leader_trait = trait_hof_ic_tsarist_officer`。
> 蓝本：`00_traits.txt` 的 `old_guard`（证明 trait 可带 `modifier` / `non_shared_modifier`）、
> `NSB_traits.txt` 的 `BALTIC_ex_russian`（证明 `gain_xp = { always = no }` 可写）。
> 文件已跑 `build/fix-bom.ps1` 剥掉 BOM（脚本 `.txt` 不能带 BOM）。
> **不建文件而直接写特质名 = 静默失效** —— 现在两条路都可用：下面的"升技能"版，或直接给特质。

#### 8.2.6 V2「中国革命问题」的对中共外交修正（一次性）

**长期好感不是 modifier 词条**，而是独立的 `opinion_modifier` 定义
（R56 的 `SOV_international_socialist_association` 定义在 `common/opinion_modifiers/`）。

已核实的块结构（`common/opinion_modifiers/nsb_opinion_modifiers.txt` 原文）——
🚩 **外面还有一层 `opinion_modifiers = { }` 包裹**，漏了就静默无效：

```text
opinion_modifiers = {

	hof_ic_chinese_question = {
		value = 50
	}
}
```

> 建在**新文件** `common/opinion_modifiers/hof_ic_opinion_modifiers.txt`。

国策里这样用：

```text
completion_reward = {
	PRC = { add_opinion_modifier = { modifier = hof_ic_chinese_question target = ROOT } }
}
```

可选字段（`nsb_opinion_modifiers.txt` 头部注释列的）：`min_trust` `max_trust` `decay`
`months` / `years` / `days`（限时）`trade = yes/no`。

### 8.3 本地化文本（**史实/理论节选，非自撰**）

**三条原则**：
1. 描述一律取自**史实记述或理论原文**，不自己写评价（`AGENTS.md` 规则 9）。
2. **一段话即可**，不标出处、不加引号 —— **贴合国策题目**最重要。
3. 找不到贴题节选时，用历史上他人的评价或权威条目原文。

键名规则：`<focus_id>` 与 `<focus_id>_desc`（照 R56 现有 7 个入口国策的做法）。

```yaml
 hof_ic_trotsky_build_the_red_army:0 "缔造红军"
 hof_ic_trotsky_build_the_red_army_desc:0 "这辆军用专列曾经是他的战地指挥部。在那决定命运的 3 年里，他乘坐这辆专列沿着 8000 公里的前线行进，哪里危险就冲向哪里，只有短暂的磋商或者出席莫斯科的公众集会才暂时打断他的行程。"
 hof_ic_trotsky_military_specialists:0 "返聘沙俄军官"
 hof_ic_trotsky_military_specialists_desc:0 "1919 年初，他断然反对逮捕查京将军。他写道，查京帮助苏维埃所做的工作比那些关押他的人还多，蛮横地对待这样的人则会对军官的士气具有灾难性的影响。他要求释放将军，并愿在法庭给他定罪前亲自为他作保。"
 hof_ic_trotsky_against_partisan_warfare:0 "反对游击主义"
 hof_ic_trotsky_against_partisan_warfare_desc:0 "正如托洛茨基所指出的，游击战的混乱反映了革命下面的农民因素，而反对它的斗争同样是为了支持无产阶级国家组织，以抵制正在瓦解它的元素化的小资产阶级无政府状态。绝大部分的军队新兵都是农民，整个国家是一片起义的农民海洋，对于这种战争方式，他们不仅有着传统，而且本能地适应。"
 hof_ic_trotsky_uneven_and_combined_development:0 "不平衡与综合发展律"
 hof_ic_trotsky_uneven_and_combined_development_desc:0 "在一些情况下，从一开始就领先者可以加强其领先地位，而在另一些情况下，同样地由于发展的步调不同，一些落后者可以赶上甚至超过那些先前享有优势者。"
 hof_ic_trotsky_permanent_revolution:0 "不断革命论"
 hof_ic_trotsky_permanent_revolution_desc:0 "在狱中，他完成了对俄国革命的见解——不断革命论。认为俄国的民主革命必然要由工人阶级来领导，以无产阶级专政来完成，并由此发展成社会主义革命。其奠基性的表述最初出自马克思，1906 年由托洛茨基针对俄国的情况重新加以表述，随后又在 1928 年进一步阐发。"
 hof_ic_trotsky_socialism_in_one_country:0 "驳「一国社会主义」"
 hof_ic_trotsky_socialism_in_one_country_desc:0 "斯大林的一国社会主义论，被他斥为放弃世界革命的借口。1926 年，他与昔日的对手季诺维也夫、加米涅夫联手组成联合反对派，主张党内民主与经济计划化，谴责领导层对资产阶级分子的让步。这场争论持续了约 18 个月。"
 hof_ic_trotsky_the_new_course:0 "新方针"
 hof_ic_trotsky_the_new_course_desc:0 "1923 年 10 月，他致信中央委员会提出广泛批评，特别强调党内民主遭到破坏、经济计划化不足。改革被承诺了，他随即以一封公开信详细说明改革应取的方向。而此后党组织在压制它的主要批评者时，其猛烈和狂怒在党内反对派的漫长历史上是前所未有的。"
 hof_ic_trotsky_against_the_bureaucracy:0 "反对官僚化"
 hof_ic_trotsky_against_the_bureaucracy_desc:0 "无产阶级专政将通过政党夺取政权而建立，托洛茨基认为这个政党在革命中起领导作用。但是，他警告说，一旦它的任务完成，这样的党要提防用自身代替无产阶级或是支配无产阶级。"
 hof_ic_trotsky_limited_market_reforms:0 "有限市场化"
 hof_ic_trotsky_limited_market_reforms_desc:0 "内战结束后，他把注意力转向俄国的经济重建。他首先提议放松战时共产主义严苛的集中制，允许市场力量运作。这个提议被否决之后，他才转而尝试把军事纪律应用于经济。"
 hof_ic_trotsky_labour_armies:0 "劳动军"
 hof_ic_trotsky_labour_armies_desc:0 "他转而尝试把军事纪律应用于经济：把士兵用作劳动军，并试图把交通运输系统的管理军事化。这个方向同样被党的十大否决，此后连他自己也不再主张它。"
 hof_ic_trotsky_state_planning:0 "经济计划化"
 hof_ic_trotsky_state_planning_desc:0 "他要求扩大国家计划委员会的权力，而李可夫和索柯里尼柯夫则怀疑计划性，公开指责他之所以要求扩大国家计划委员会的权力只是因为他觊觎它的领导权。他所作的报告和所提交的『提纲』是苏联经济史上最关键的文件，他在其中描绘了今后几十年的苏联经济远景。"
 hof_ic_trotsky_accelerated_industrialization:0 "加速工业化"
 hof_ic_trotsky_accelerated_industrialization_desc:0 "国家的大粮库有一半已见了底，城市居民面临着饥饿的威胁，连军队的给养都不充足，面包店外排着长队，面包价格不断上涨。正是在这样的处境下，联合反对派要求加快工业化、反对向富农让步。1928 年，斯大林开始了第一个五年计划。"
 hof_ic_trotsky_the_comintern_manifesto:0 "共产国际宣言"
 hof_ic_trotsky_the_comintern_manifesto_desc:0 "1919 年 3 月，他与列宁共同创立第三国际，并撰写了它的首篇宣言。"
 hof_ic_trotsky_the_chinese_question:0 "中国革命问题"
 hof_ic_trotsky_the_chinese_question_desc:0 "1927 年春天，党内斗争的火焰又一次燃烧起来。这次斗争是同到那时之前从未提出过的一个问题相联系的，但从此以后这个问题却自始至终都是斗争的中心，直到联合反对派最终被开除出党并解体为止。"
 hof_ic_trotsky_united_front:0 "反法西斯统一战线"
 hof_ic_trotsky_united_front_desc:0 "第三国际不顾托洛茨基自 1930 年以来不断的警告，大大低估了纳粹党的危险性，同时拒绝社会民主党建立统一战线对抗纳粹，结果使德国工人阶级的组织毫无抵抗地被粉碎，并使法西斯势力横行十余年。"
 hof_ic_trotsky_the_permanent_revolutionary:0 "永久的革命者"
 hof_ic_trotsky_the_permanent_revolutionary_desc:0 "要求我放弃政治活动，意味着要求我放弃为全世界工人阶级利益而进行的斗争，而这一斗争我已孜孜不倦地进行了 32 年之久，也就是我自觉生命的全部时间。只有腐朽透顶的官僚集团才会要求做出这种放弃，只有卑鄙的叛徒才能做出这种承诺。"
 hof_ic_trotsky_the_builder_of_the_state:0 "国家建设者"
 hof_ic_trotsky_the_builder_of_the_state_desc:0 "请告诉我还有哪个人能在一年之内建立起一支堪称楷模的军队而且赢得军事专家的尊重；我们有这样的人，就有了一切，我们将创造出奇迹。"
```

> 📌 **引文来源**（供核对，不入游戏文本）：
>
> 🚩🚩 **2026-09-16 全部重写**（用户：「托洛茨基的国策介绍近乎全都要改，布哈林写的挺好的
> 托洛茨基的怎么全拉了，甚至介绍文案里出现斯大林」）。
>
> **根因**：上面那版取自多伊彻《武装的先知》《被解除武装的先知》的**第三人称转述**
> （＋3 条译自 Britannica），而布哈林那 9 条是**他本人原话** —— 两者文风根本对不上。
>
> **修法**：一律换成**托洛茨基自己的话**。一手件已抓到本地：
> `tmp/trotsky/txt/*.txt`（28 份，中文马克思主义文库；抓取工具 `build/fetch-trotsky.ps1` ~ `fetch-trotsky3.ps1`）。
>
> **逐条出处**：
>
> | 国策 | 出处 |
> | --- | --- |
> | 缔造红军 / 国家建设者 | 《我的生平》第三十四章「专列」 |
> | 返聘沙俄军官 / 反对游击主义 | 《我的生平》第三十六章「军事反对派」 |
> | 不平衡与综合发展律 | 《俄国革命史》第一卷第一章「俄罗斯发展的特点」 |
> | 不断革命论 / 驳「一国社会主义」 | 《俄国革命史》附录「关于不断革命论问题之历史的回顾」 |
> | 反对官僚化 | 《马克思主义思想辞典》「托洛茨基主义」条目 |
> | 有限市场化 / 劳动军 | 《我的生平》第三十八章「转入新经济政策阶段及我与列宁的关系」 |
> | 经济计划化 | 《就国家计划委员会和劳动国防委员会问题致中央政治局》(1923-01-15) |
> | 加速工业化 | 《社会主义积累的规律、计划原则、工业化速度及无原则性》(1926-05-02)＋《提纲》(1925-12) |
> | 共产国际宣言 | 《世界经济危机与共产国际的新任务》(1921，共产国际三大报告) |
> | 中国革命问题 | 《中国革命中的阶级关系》(1927-03-18) |
> | 反法西斯统一战线 | 《工人武装及其敌人》(1934《法国向何处去？》) |
> | 永久的革命者 | 《就停止政治活动问题致联共（布）中央和共产国际执委会》(1928-12-16) |
>
> ⚠️ 原稿有 **2 条点到「斯大林」**（驳「一国社会主义」/ 加速工业化），已一并去除 ——
> 本 mod 的设定里他是被清掉的一方，文案里不该再以他为主语。
>
> > **唯一权威出处** = 生成器 `build/gen-hof-ic-s3.ps1` 的 `$trotLoc`（AGENTS 规则 10：
> > 同一份数据只在一处写全）。上面这段 yaml 已过期，仅作对照，**改文案请改生成器**。

---

## 9. 建议实施顺序

1. 先定**图标方案**（专属图 or 复用）——这决定要不要给 GPT 出需求
2. **建 idea 定义文件**：`common/ideas/hof_ic_trotsky_ideas.txt`（新建文件名 + `hof_` 前缀，不塞进原版文件）
3. **建本地化**：`localisation/simp_chinese/hof_ic_trotsky_l_simp_chinese.yml`（UTF-8 **带 BOM**、首行 `l_simp_chinese:`）
4. 写进 `build/gen-hof-ic-s3.ps1` 的花名册驱动流程（**单一数据源**，别手写进 `soviet.txt`）
5. 跑 `sync-from-r56.ps1` + `verify-s2.ps1`，**失败项必须为 0**

> ⚠️ 17 个国策会显著扩大 `soviet.txt` 的注入量（当前注入 135 行）。
> 同步脚本的锚点唯一性检查需保持通过。
