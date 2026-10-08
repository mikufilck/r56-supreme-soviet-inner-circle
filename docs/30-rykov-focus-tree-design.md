# 30 · 李可夫个人线设计（**已实装**）

> **本文是李可夫个人线的设计文档。**
> 上游 = [`docs/29`](29-rykov-genealogy.md)（谱系 · SOP 第 0–5 步 + §5.2/§5.3 定案）；
> 出图 = [`docs/31`](31-rykov-focus-icon-prompts.md)。
>
> 🚩🚩 **唯一权威出处**：
> - **国策 id / 坐标 / 数值 / 分支结构 = 生成器 `build/gen-hof-ic-s3.ps1` 的 `$rykovLine`**
> - **文案 = 同一文件的 `$rykovLoc`**
> - 本文是**镜像说明**，改数据必须回去改生成器。**本文不含任何独立数据。**
>
> 对应关系（沿用前两人）：托洛茨基 = `docs/21` + `docs/22`；布哈林 = `docs/25` + `docs/26`。

---

## 1. 形状：**单线 · 4 节点 + 1 单结局**

用户 2026-09-16 两次定调：

| 口径 | 原话 |
| --- | --- |
| ③ 砍支线 | 「**支线 B 删掉吧，那就做单线的就可以**，汇合层照样做不影响」 |
| 结局 | 「**李可夫用单结局吧，就用劳动与国防委员会，我认为没有必要做选择**」 |

```
            席位入口  hof_ic_seat_aleksey_rykov
                 │
                 ▼
  N1  最高国民经济委员会主席           y = 1   ← 官衔升 Lv2
      hof_ic_rykov_supreme_economic_council
                 │
                 ▼
  N2  劳动国防委员会粮秣特派员          y = 2
      hof_ic_rykov_food_supply_commissar
                 │
                 ▼
  N3  劳动与国防委员会副主席            y = 3   ← 官衔升 Lv3
      hof_ic_rykov_labour_defence_council
                 │
                 ▼
  N4  扶植航空（挂 MIO）                y = 4
      hof_ic_rykov_sponsor_aviation
                 │
                 ▼
  E1  劳动与国防委员会主席              y = 6   ← 官衔升 Lv4
      hof_ic_rykov_labour_defence_chair
      （前置 = N1 且 N2 且 N3 且 N4 —— 四块并列 prerequisite = AND）
```

| 项 | 值 |
| --- | --- |
| 国策块总数 | **5**（4 节点 + 1 结局） |
| 横向跨度 | dx = 0 单列（**宽 1**）→ 入口 x 由 §10z 区块避让自动算出 |
| 岔路 | **无** —— 本人没有互斥国策，不进 `$pathChoiceOf` / `$branchGate` |
| 终局抉择事件 | **无** —— 不进 `$endingChoiceOf`，没有 `count_triggers` |
| 驱动器 | `heartofiron.1130` / `.1131`（按 `$roster.Idx = 3` 自动排号） |
| 个人数值容器 | `common/dynamic_modifiers/hof_ic_aleksey_rykov_dm.txt` |

> 💡 **单结局怎么做门控**：结局国策的 `P` 写成**四个并列的嵌套数组** = 四个独立的
> `prerequisite` 块 = **AND**（照 `docs/26` 布哈林 E1 的手法）。
> **绝不是在同一块里写四个 `focus`** —— 那样是 **OR**（见 `AGENTS.md` 铁律 / 仓库记忆）。
> `$lineSpecs` 里 `ConvY = -99`，于是 `available` 段由 `$ls.Branch -contains $f.Id` 命中。

---

## 2. 数值表

数值**全部**写进个人容器 `hof_ic_aleksey_rykov_dm`，由国策 `add_to_variable` 逐条累加
（`+X%` = 提升，`−X%` = 降低；都是民族精神带来的长期加成）。

| # | 国策 | 中文名 | 效果 |
| --- | --- | --- | --- |
| N1 | `hof_ic_rykov_supreme_economic_council` | 最高国民经济委员会主席 | 工厂产出 **+5%**；民用工厂建造速度 **+10%** |
| N2 | `hof_ic_rykov_food_supply_commissar` | 劳动国防委员会粮秣特派员 | 陆军组织度 **+5%**；战争支持度 **+5%** |
| N3 | `hof_ic_rykov_labour_defence_council` | 劳动与国防委员会副主席 | 工厂产出 **+5%**；**消费品工厂占比 −5%** |
| N4 | `hof_ic_rykov_sponsor_aviation` | 扶植航空 | 科研速度 **+5%**；**雅克夫列夫设计局 MIO 规模 +2** |
| E1 | `hof_ic_rykov_labour_defence_chair` | 劳动与国防委员会主席 | 工厂产出 **+5%**；民用工厂建造速度 **+10%**；科研速度 **+10%**；稳定度 **+5%** |

> 💡 **N3 的 `消费品工厂占比 −5%` 是刻意的**：这一条讲的是「动员」——
> 把资源从消费端抽到工业端。方向与布哈林 B 线的「按比例发展」**相反**，
> 因此不构成重复（去重口径见 `docs/29` §7）。

### 2.1 N4 · 扶植航空的 MIO 写法

🚩🚩 **写法逐字照原版**（`common/national_focus/afghanistan.txt` L909-919 / L2770-2780）：

```text
if = {
    limit = { has_dlc = "Arms Against Tyranny" }      # MIO 是该 DLC 的机制 → 必须门控
    custom_effect_tooltip = available_mio_tt          # 「军工机构可用：」
    show_mio_tooltip = SOV_yakovlev_design_bureau_organization
    mio:SOV_yakovlev_design_bureau_organization = {
        add_mio_size = 2                              # 🚩 必须嵌在 mio:<id> = { } 里
    }
    custom_effect_tooltip = generic_skip_one_line_tt  # 空行
}
```

| 要点 | 说明 |
| --- | --- |
| 🚩 `add_mio_size` **不能平铺** | 必须嵌在 `mio:<id> = { }` 内。`docs/29` §9.2 早期版本把它写成了平铺，**是错的**，实装时对照原版才发现 |
| 用 `available_mio_tt` 而不是 `unlock_mio_tt` | 该 MIO 对 SOV **默认就是开放的**（`docs/29` §9.2）→ 我们做的是**强化**，不是「建立」 |
| 目标 MIO | `SOV_yakovlev_design_bureau_organization`（游戏内中文名「**雅克夫列夫设计局**」） |
| 出处 | `common/military_industrial_organization/organizations/SOV_organization.txt` L2098 |

> 📌 **史实依托**：他 1923 年起任**航空之友协会（ОДВФ，后并入 Авиахим）主席**；
> 雅科夫列夫最初那批飞机的家族名就叫 **АИР** = **А**лексей **И**ванович **Р**ыков，
> 一直用到 1937 年的 АИР-18。详见 `docs/29` §8.3。

---

## 3. 职务链（`Tiers` / `RankGates`）

四级**直线链**（不是星形），全部史实，见 `docs/29` §2.3。

| Lv | idea id | 官衔 | 升到这里要完成 | 该级追加 |
| --- | --- | --- | --- | --- |
| 1 | `hof_ic_idea_aleksey_rykov` | 内务人民委员 | 入席即有 | — |
| 2 | `hof_ic_idea_aleksey_rykov_2` | 最高国民经济委员会主席 | **N1** | 工厂产出 +5% |
| 3 | `hof_ic_idea_aleksey_rykov_3` | 人民委员会主席 | **N3** | 工厂产出 +5%；政治点获取 +5% |
| 4 | `hof_ic_idea_aleksey_rykov_4` | 劳动与国防委员会主席 | **E1** | 工厂产出 +5%；政治点获取 +5%；科研速度 +5% |

> ⚠️ **`Lv` 字段（2026-09-16 加）**：`$rankUpOf` 原先用启发式「非最低门槛的 From 一律 = 最低门槛」，
> 那只在**星形链**上成立（托洛茨基 2 → 3a/3b）。李可夫是四级直线链，
> 启发式会把 Lv4 的 From 算成 Lv2（**跳级**）→ 升级 tooltip 会写错「以 X 取代 Y」。
> → `Tiers` 每项加 `Lv`，按 Lv 反查上一级。托洛茨基 / 布哈林的 `Tiers` 也一并补了 `Lv`。
>
> ⚠️ **接线**：`Tiers` + `RankGates` 只是**数据**，真正触发升级的是国策里的 **`Sync = $true`**。
> N1 / N3 / E1 三条都标了。§11 有断言：有 `RankGates` 的人，`Sync` 国策数必须等于门槛数
> （**布哈林就是漏了这一步**，官衔一直没升，见 §6）。

---

## 4. 文案与出处（AGENTS 规则 9）

🚩🚩 **他本人没有可引用的中文文集** —— 中文马克思主义文库没有李可夫页（5 个 URL 全 404）、
英文 marxists.org 也没有他的档案（`/archive/rykov/` 404）、俄文维基语录只 4 条且全是
1927 十五大 / 1938 审判供词。完整排查见 `docs/29` §0 与仓库记忆。

→ 按规则 9 的第二档「**历史上他人评价或记述的原文**」，用**列宁与托洛茨基**的话 ——
他们恰好都写到他经手的这几个机关。**只有 ④ 连这一档都找不到**，退到后人记述。

| # | 文案性质 | 出处 | 一手件 |
| --- | --- | --- | --- |
| ① | **列宁原话节选** | 1918-05-26《在全俄国民经济委员会第一次代表大会上的讲话》 | `tmp/rykov/lenin/txt/mia-chinese-lenin-19180526.txt` |
| ② | **托洛茨基原话节选** | 《我的生平》第三十六章「专列」 | `tmp/trotsky/txt/i1_train_1929book36.txt` |
| ③ | **托洛茨基原话节选** | 1921-08-07（就新经济政策与国家计划委员会致中央） | `tmp/trotsky/txt/iv1_nep_gosplan_19210807.txt` |
| ④ | ⚠️ **后人记述（非原文）** | 俄文维基百科「阿列克谢·伊万诺维奇·李可夫」条「纪念」节 +「Осоавиахим」条 | `tmp/rykov/txt2/wiki_ru_rykov.txt` L1138 等 |
| ⑤ | **托洛茨基原话节选** | 1926-09-07《工业化的问题》 | `tmp/trotsky/txt/iv4_industry_19260907.txt` |

> 🚩 **④ 刻意不加引号** —— 一眼能看出它不是原文节选，**不冒充原文**。
> 这是全项目唯一一条这样的描述，**如果以后找到能对位的一手件，应当替换掉**。

---

## 5. 与布哈林的去重（结论）

用户口径：「**要是和布哈林高度重复那就砍掉不写**」。已执行：

| 项 | 处理 |
| --- | --- |
| NEP 的理论辩护 / 工农联盟 / 按比例发展 /「发财吧」 | ⛔ 全部砍掉（布哈林 A、B 线已占） |
| 反对超高速工业化 | ⛔ 砍掉（布哈林「按比例发展」已占） |
| 支线 B「财政与预算」整条 | ⛔ 砍掉（酒类专卖**他是主持者非倡议者**；联盟预算之争是「反对型」主张） |
| 剩下的 | ✅ 单线 4 节点，**全部是「做成了的事」** |

> 💡 一句话：**布哈林讲「为什么」，李可夫讲「怎么办」。**
> 完整清单见 `docs/29` §5「⛔ 已砍掉的部分」与 §7。

---

## 6. 实装记录（2026-09-16）

| 项 | 结果 |
| --- | --- |
| 生成器 | `$roster[Idx=3]` 补 `Tiers` / `RankGates` / `Branch`；新增 `$rykovLine`（5 条）+ `$rykovLoc` |
| 国策块总数 | **54**（22 入口 + 17 托洛茨基 + 9 布哈林 + **5 李可夫** + 1 人民委员） |
| 事件 | **10**（1 满席替换 + 3 人 × 2 驱动器 + 2 终局抉择 + 1 岔路抉择） |
| 个人线驱动器 | **3 人**（托洛茨基、布哈林、李可夫） |
| 双自检 | `gen-hof-ic-s3.ps1` §11 **全过**；`verify-s2.ps1` 见 §7 |

### 6.1 本轮顺带修掉的 bug

| 类型 | 内容 |
| --- | --- |
| 🚩🚩 **真 bug** | **布哈林的官衔链从 2026-09-15 起就没接线** —— `Tiers`/`RankGates` 都写了，但他 9 条国策**一个都没标 `Sync`** → 3 级官衔永远停在 T1，**而且不报任何错**。已补 `Sync` 并加断言 |
| 🚩 **文档错误** | `docs/29` §9.2 把 `add_mio_size` 写成了**平铺**，实际必须嵌在 `mio:<id> = { }` 里 |
| 🚩 **写死数字** | 国策块数断言（49→54）、§11 的「个人数值容器」两行硬编码、§10c 的「追加 N 个国策键」→ **全部改为按 `$lineSpecs` 推导** |
| ⚠️ **生成器增强** | 官衔反查改按 `Lv`；新增「官衔链接线」断言；新增图标**缺图兜底**（见 §7） |

---

## 7. 待办 / 风险

- [x] ✅ **5 张国策图标已交付并注册**（2026-09-16）—— `art/focus/rykov/` 的 PNG → DDS 已落在
      `gfx/interface/hof_ic/focus/`；重跑 `gen-hof-ic-focus-icons.ps1` 后
      **兜底占位已自动消失**（**53 张交付 / 0 张兜底**），`verify-s2` 12d 也回到「贴图 53 == 注册 53」。
      透明底自检：四角 alpha = 0、透明率 37.1～38.4%（合格区间 20～50%）
- [ ] **④ 的文案是后人记述**，不是原文节选 —— 若以后找到对位的一手件应替换（见 §4）
- [x] ✅ `docs/29` §8.4 剩余项（1907 孟什维克 ❌ 档 / 原版角色块补读）—— 不影响设计，随时可补
- [ ] 条目数若变动，**本文与 `docs/31` 要同步改**，且**改数据要回去改生成器**（本文不含独立数据）

---

## 8. 相关文件

| 文件 | 内容 |
| --- | --- |
| [`docs/29-rykov-genealogy.md`](29-rykov-genealogy.md) | 谱系 · SOP 第 0–5 步 + §5.2/§5.3 定案 + §8 核实 + §9 MIO 参考（**上游**） |
| [`docs/31-rykov-focus-icon-prompts.md`](31-rykov-focus-icon-prompts.md) | 国策图标出图说明（**下游**） |
| [`docs/23-figure-focus-playbook.md`](23-figure-focus-playbook.md) | SOP（第 1b 步「非理论家改走历史重要贡献事件」就是为李可夫这类人写的） |
| [`docs/26-bukharin-focus-tree-design.md`](26-bukharin-focus-tree-design.md) | 布哈林设计（**单结局 + 多块 AND 前置**的手法来源） |
| `build/gen-hof-ic-s3.ps1` | 🚩 **唯一权威出处**：`$rykovLine` / `$rykovLoc` |
