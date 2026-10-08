# 39 · 斯米尔诺夫个人线设计（第 6 步）—— ✅ **已实装**

> **本件 = `docs/23` SOP 第 6 步的产出**（形状 / 坐标 / 数值 / 文案）。
> - 上游：[`docs/38`](38-smirnov-genealogy.md)（谱系 · 第 0–5 步）
> - 同级样板：[`docs/36`](36-kamenev-focus-tree-design.md)（加，**单线**）、
>   [`docs/30`](30-rykov-focus-tree-design.md)（李，**单线 + 单结局**）
> - 下游：出图 → [`docs/40`](40-smirnov-focus-icon-prompts.md)
>
> ✅ **2026-09-17 已写进 `build/gen-hof-ic-s3.ps1`（`$smirLine`），全链跑通**：
> 国策块数 **76**（+6）、个人数值容器 **9** 条变量、
> `sync-from-r56` 成功 17 / 失败 0、`verify-s2` **失败项 0**。
>
> 🚩🚩 **唯一权威出处**：**国策 id / 坐标 / 数值 / 分支结构 = 生成器的 `$smirLine`**；
> **文案 = 同一文件的 `$smirLoc`**。本文是**镜像说明**，不含独立数据。
>
> ⚠️ **实装前的状态**：本文曾作为**提案**存在（因为 2026-09-17 加米涅夫那轮我直接实装被砍回，`docs/18` §15.8）。
> 本轮**提交了提案后用户暂时离线，明确指示「自主推进」** → 按 §8 的推荐口径实装。
> 📌 **本线没有 `$pathChoiceOf` / `$branchGate` / `$endingChoiceOf`** —— 所以即使还要砍枝，成本很低（只改 `$smirLine` 与 `$smirLoc`）。

---

## 1. 主干与推导（第 6 步的「根 → 主干 → 节点」）

他是**非理论家**（`docs/38` §1.4：中英文库都没有他的著作篇目页），
所以按 [`docs/23`](23-figure-focus-playbook.md) **第 1b 步**用「**历史重要贡献事件**」建线。

| 层 | 内容 | 出处 |
| --- | --- | --- |
| **根**（方法 / 态度，不是理论） | 「**伊万·尼基季奇永远是个忠于职守的人，在这一点上，一个革命者接近于一个优秀军人**」 | 托洛茨基《我的生平》第三十三章（中译） |
| **主干**（一句话） | **把俄罗斯的东部边地一块块造成苏维埃国家的一部分** | 由 5 件事共同推出 |
| **节点**（每件都能从主干推出来） | 守住桥头堡 → 打赢并结成队伍 → 把它建成政权 → 再往东一步用缓冲国挡住日本 → 用邮电网把全国连起来 | `docs/38` §5 |

> 📌 这 5 件事是**同一条过程的先后环节**，不是并列的分类清单 ——
> 所以 **簇数 = 1 → 支线数 = 1 → 单线**（`docs/38` §9）。
> **跨簇钩子 = 无**（只剩一个簇，不存在「簇与簇之间」的 AND）。

---

## 2. 形状：**单线 5 节点 + 1 单结局**

```text
                席位入口  hof_ic_seat_ivan_smirnov
                          │
              y1  ┌───────┴───────┐
                  │ A1 斯维亚日斯克桥头堡 │
              y2  │ A2 第五集团军与五军将士 │
              y3  │ A3 西伯利亚革命委员会 │  ← 完成时官衔升到 Lv2
              y4  │ A4 远东共和国      │
              y5  │ A5 苏联邮电人民委员部 │  ← 完成时官衔升到 Lv3
                  └───────┬───────┘
                          │   （五个节点全完成）
              y7  ┌───────┴───────┐
                  │ E1 西伯利亚的列宁  │
                  └────────────────┘
                  （单结局，无二选一）
```

| 项 | 值 |
| --- | --- |
| 国策块总数 | **6**（5 节点 + 1 单结局）；**+ 1 入口国策**（自动生成）→ 全 mod 变 **76** 块 |
| 横向跨度 | **全部 x = 0**（宽 1，与李可夫 / 加米涅夫同形） |
| 岔路（`$pathChoiceOf`） | ⛔ **无** |
| 终局抉择（`$endingChoiceOf`） | ⛔ **无** —— 单结局，不进这张表 |
| 卡路径（`$branchGate`） | ⛔ **无**（没有岔路就不需要） |
| `$lineSpecs` 的 `ConvY` | **−99**（单结局，不用 `count_triggers`） |
| 驱动器事件 | `heartofiron.1152` / `.1153`（按 `$roster.Idx = 6` 自动排号） |
| 个人数值容器 | `common/dynamic_modifiers/hof_ic_ivan_smirnov_dm.txt`（6 条变量） |

### 2.1 坐标与拓扑序

| 顺 | 国策 id | 中文名 | X | Y | 前置 |
| --- | --- | --- | --- | --- | --- |
| A1 | `hof_ic_smirnov_the_volga_bridgehead` | 斯维亚日斯克桥头堡 | 0 | 1 | 入口 |
| A2 | `hof_ic_smirnov_the_fifth_army` | 第五集团军与「五军将士」 | 0 | 2 | A1 |
| A3 | `hof_ic_smirnov_sibrevkom` | 西伯利亚革命委员会 | 0 | 3 | A2 |
| A4 | `hof_ic_smirnov_far_eastern_republic` | 远东共和国 | 0 | 4 | A3 |
| A5 | `hof_ic_smirnov_posts_and_telegraphs` | 苏联邮电人民委员部 | 0 | 5 | A4 |
| E1 | `hof_ic_smirnov_siberian_lenin` | 西伯利亚的列宁 | 0 | 7 | A1–A5 五个并列块（= AND） |

---

## 3. 数值表

数值**全部**写进个人容器 `hof_ic_ivan_smirnov_dm`，由国策 `add_to_variable` 逐条累加。
⛔ 修正词条**只从已实测词汇表里挑**（`docs/22` §8.0）。

| # | 国策 | 效果 | 为什么是这些词条 |
| --- | --- | --- | --- |
| A1 | 斯维亚日斯克桥头堡 | `army_core_defence_factor` **+5%**；`max_dig_in_factor` **+10%** | 这一节的产物就是「**没丢**」——守 |
| A2 | 第五集团军与「五军将士」 | `army_org_factor` **+5%**；`army_morale_factor` **+5%** | 产物是「一支**团结成政治家庭**的集团军」——组织与士气 |
| A3 | 西伯利亚革命委员会 | `stability_factor` **+5%**；`political_power_factor` **+5%** | 产物是**政权**（从军事占领转成治理） |
| A4 | 远东共和国 | `drift_defence_factor` **+5%**；`stability_factor` **+5%** | 产物是**缓冲国**——挡住外部影响、稳住东南 |
| A5 | 苏联邮电人民委员部 | `production_speed_buildings_factor` **+5%**；`research_speed_factor` **+5%** | 产物是**全国性的邮电网**——建设与信息 |
| E1 | 西伯利亚的列宁 | `political_power_factor` **+10%**；`stability_factor` **+10%**；`production_speed_buildings_factor` **+5%**；`research_speed_factor` **+5%** | 前面五条的综合 |

> ✅ **14 个 `_tt` 键已实测存在**（`build/smirnov-tt-check.txt`，扫
> `F:\Hearts of Iron IV\localisation\simp_chinese`，全部命中 `modifiers_l_simp_chinese.yml`）：
> `army_org_factor_tt` / `army_morale_factor_tt` / `army_core_attack_factor_tt` /
> `army_core_defence_factor_tt` / `max_dig_in_factor_tt` / `stability_factor_tt` /
> `drift_defence_factor_tt` / `political_power_factor_tt` / `research_speed_factor_tt` /
> `production_speed_buildings_factor_tt` / `mobilization_speed_tt` / `war_support_factor_tt` /
> `training_time_factor_tt` / `conscription_tt`
>
> ⛔ **刻意避开** `improve_relations_maintain_cost_factor`（加米涅夫那轮已实测：**没有** `_tt` 键）。

---

## 4. 官衔链（`Tiers` / `RankGates`）

三级，**全部是他真实的、带日期的职务**，且**升序排列**（军事 → 边疆政权 → 全联盟）。

| Lv | idea id | 官衔 | 升到这里要完成 | 该级追加 | 出处 |
| --- | --- | --- | --- | --- | --- |
| 1 | `hof_ic_idea_ivan_smirnov` | **第五集团军革命军事委员会委员** | 入席即有 | `production_speed_buildings_factor` +0.03（**沿用花名册现有 `Mod`**） | `docs/38` §4（1919-04-01 – 1920-05-10） |
| 2 | `hof_ic_idea_ivan_smirnov_2` | **西伯利亚革命委员会主席** | **A3** | + `stability_factor` +0.05 | `docs/38` §4（1919-08 – 1921-09） |
| 3 | `hof_ic_idea_ivan_smirnov_3` | **苏联邮电人民委员** | **A5** | + `research_speed_factor` +0.05 | `docs/38` §4（**1923-07-06 – 1927-11-12，首任**） |

> 📌 照 `docs/11` §4.1 的数值宪法：`political_power_gain` 入口 **−0.10**、二级及以后 **−0.30**；
> `allowed = { always = no }` + `removal_cost = -1` 每层都要写；**高层 = 低层的严格超集**。
>
> 🚩 **与已完成五条线的官衔全部错开**：
> ⛔ 《列宁全集》编辑 / 列宁研究院院长（**加米涅夫的 T1/T3**）、
> ⛔ 共产国际执委会主席 / 政治局委员（**季诺维也夫的 T2/T3**）、
> ⛔ 人民委员会主席 / 劳动与国防委员会主席（**李可夫的 T3/T4**）、
> ⛔ 《真理报》主编（**布哈林的 T1**）。

---

## 5. 文案与出处（`AGENTS.md` 规则 9）

> 🚩 **每条都是节选，不有一句是我自己写的评价。** 出处见下表，**出处不进游戏文本**。
> 🟢 = 已是中文原文；🟡 = 需先中译（按 `docs/23` §7.1 优先级 4 记待办）。

| # | 国策 | 文案（节选） | 出处 | 档 | 语言 |
| --- | --- | --- | --- | --- | --- |
| A1 | 斯维亚日斯克桥头堡 | 「拉里莎·赖丝纳描写围攻喀山战役时这样写道：**『伊万·尼基季奇最受人们尊敬，因为大家都感觉到，在最危急的时刻，最沉着无畏的就是他。』**」 | 托洛茨基《我的生平》第三十三章〈斯维亚日斯克一月〉（中译本） | 3 同时代人的记述 | 🟢 |
| A2 | 第五集团军与「五军将士」 | 「**第五军的共产党员团结在斯米尔诺夫周围，形成了一个特殊的政治家庭**……『**五军将士**』这个词在革命词典中有其特殊的意义，它意味着真正的革命者、克尽职守的人，更主要的是纯洁的人。」 | 同上 | 3 | 🟢 |
| A3 | 西伯利亚革命委员会 | 「列宁建议把**苏维埃化和安抚西伯利亚**的任务交给伊万·尼基季奇……多亏他，亚洲北部的苏维埃化**几乎是在没有报复行动的情况下**完成的。」 | 维克多·塞尔日《伊·尼·斯米尔诺夫之死》（1936-08） | 3 | 🟡 |
| A4 | 远东共和国 | 「**斯米尔诺夫创建了远东共和国** —— 一个临时的缓冲国，**使苏维埃得以避开与日本的战争**。」 | 同上 | 3 | 🟡 |
| A5 | 苏联邮电人民委员部 | 「国内战争结束后，**五军将士同伊万·尼基季奇一起把他们的英雄主义转移到经济建设领域**。……**斯米尔诺夫先领导国防工业，后来任邮电人民委员**。」 | 托洛茨基《我的生平》第三十三章（中译本） | 3 | 🟢 |
| E1 | 西伯利亚的列宁 | 「**伊万·尼基季奇·斯米尔诺夫成了第五军军长这个事实有着重大的意义。斯米尔诺夫是一个最完全、最彻底的革命者**，他是在 30 多年前入伍的，从那时起就没有想调离也没有设法调离军队。」 | 同上 | 1（托洛茨基本人对他的记述） | 🟢 |

> 📌 **为什么 A2 / A5 / E1 都用同一章**：那一章（〈斯维亚日斯克一月〉）就是托洛茨基
> 为他写的那一段，是全项目能找到的**最集中、最贴题**的材料。
> 三处引的是**不同段落**，不重复。

---

## 6. 跨簇钩子

⛔ **无**。本线是一条直线（A1 → A2 → A3 → A4 → A5 → E1），
**没有任何 `prerequisite` 需要跨支线 AND**（与 `docs/36` §6 加米涅夫砍枝后的结论一致）。

---

## 7. 实装清单（要改 `build/gen-hof-ic-s3.ps1` 的哪几处）

| # | 位置 | 要加什么 |
| --- | --- | --- |
| 1 | `$roster[Idx=6]` | `Tiers`（3 级，带 `Lv`）、`RankGates`（2 条，**从高到低**）、`Branch`（**6 条**） |
| 2 | 新变量 | `$smirPrefix` / `$smirDmId` / `$smirExtraHeaderTt` |
| 3 | `$smirLine`（**6 条**）+ 条数断言 | 见 §2.1 / §3 |
| 4 | `$smirVars = Get-LineVars $smirLine` | —— |
| 5 | `$lineSpecs` | `ConvY = -99`、`Branch = $byIdx[6].Branch`、`RankUp = $rankUpOf[6]` |
| 6 | `$smirLoc`（6 条）+ 挂进 `$locOf` | 见 §5 |
| 7 | `build/focus-icon-owner.txt` | **自动**（生成器写）—— 图标未交付时自动兜底注册成他的入口图标 |

✅ **不必改的**：`$camps`（他已在 `left` 营）、`$crossRules` / `$pairRules`
（他已被 **R2 布哈林 ↔ 左营** 覆盖）。

### 7.1 ⚠️ 一处要在实装时核对

花名册里他现在是 `Mod = @('production_speed_buildings_factor = 0.03')`。
`Tiers` 的 **Lv1 必须与它一致**（否则入口 idea 会被写两套修正）。
实装时先看生成器对 `Mod` 与 `Tiers[0].Add` 的合并方式，**只留一份**。

---

## 8. 三项裁定 —— ✅ 已按推荐口径实装（2026-09-17）

> 🚩 **背景**：提案写完后用户**暂时离线**，明确指示「**自主推进、做合理的决定**」。
> 因此下面三条按**我在提案里的推荐**落地，每条都标了「怎么改回去」。

| # | 问题 | ✅ 采用 | 备选（怎么改） |
| --- | --- | --- | --- |
| ① | **块数** | **6 块**（5 节点 + 1 结局）—— 五件事各自是独立的产品，砍任何一块都会断掉「一路向东」的链条 | 砍 **A5 邮电人民委员部** → 5 块（删 `$smirLine` 一条 + `$smirLoc` 一条 + 把 E1 的 `P` 从五个并列块减为四个 + `Tiers` 降为 2 级 + `Branch` 减一条） |
| ② | **结局取哪个** | 🅐 **「西伯利亚的列宁」** —— 他的外号，正面收束到主干（与李可夫 / 加米涅夫「收束到招牌职务」一致） | 换 E1 的**标题 + 一条文案**即可，其余 5 块不受影响（🅑「苏兹达尔的囚徒」/ 🅒「第一次莫斯科审判」） |
| ③ | **A5 的文案** | 🅐 托洛茨基《我的生平》中译本那句（**已需中文**） | 换 `$smirLoc` 里 `posts_and_telegraphs` 那一条为塞尔日那则轶事（需中译） |

### 8.1 实装时改掉的两个小地方（相对提案）

| 项 | 提案写的 | 实际怎么写的 | 为什么 |
| --- | --- | --- | --- |
| `Tiers` 的 Lv1 修正 | 把 `production_speed_buildings_factor = 0.03` 写进 `Tiers[0].Add` | **留在花名册的 `Mod` 不动，`Add` 从 Lv1 留空** | 生成器 `foreach ($m in $c.Mod)` 是**每一级都加** —— 写进 `Add` 会重复叠加（**提案 §7.1 的担心就是这条，已核实并解决**） |
| A1 的文案 | 只用赖丝纳那段话 | 把同章原词「**斯维亚日斯克的良心**」一并引上 | 「良心」比「尊敬」更贴「桥头堡」这个题目（`docs/23` §7.1「贴题优先于文采」） |

### 8.2 ✅ 验收结果

| 项 | 结果 |
| --- | --- |
| `gen-hof-ic-s3.ps1` | **全部自检通过**；国策块数 **76**（+6） |
| 个人数值容器 | `common/dynamic_modifiers/hof_ic_ivan_smirnov_dm.txt`，**9 条变量** |
| 官衔链自检 | `ivan_smirnov` RankGates=**2** Sync 国策=**2** ✅ |
| 图标 | 75 个 sprite（64 已交付 + **11 张兜底**，其中**本线 6 张**）—— 待美术 |
| `sync-from-r56` | 成功 **17 / 失败 0**（205698 行） |
| `verify-s2` | **失败项 0** |

---

## 9. 相关文件

| 文件 | 内容 |
| --- | --- |
| [`docs/38-smirnov-genealogy.md`](38-smirnov-genealogy.md) | 谱系 · 第 0–5 步（**上游**，含完整引文库 §6） |
| [`docs/23-figure-focus-playbook.md`](23-figure-focus-playbook.md) | **SOP 手册**（本文是它第 6 步的产出） |
| [`docs/36-kamenev-focus-tree-design.md`](36-kamenev-focus-tree-design.md) | 加米涅夫设计 —— **单线**形状的来源 |
| [`docs/30-rykov-focus-tree-design.md`](30-rykov-focus-tree-design.md) | 李可夫设计 —— **单线 + 单结局**手法 |
| [`docs/18-s3-implementation-log.md`](18-s3-implementation-log.md) §15.8 | 🚩 **「设计先过一眼再实装」那条教训的原文** |
| `build/smirnov-tt-check.txt` | 14 个修正词条 `_tt` 键的实测结果 |
| `build/gen-hof-ic-s3.ps1` | 🚩 **实装后这里才是唯一权威出处**（现在还没有 `$smirLine`） |
