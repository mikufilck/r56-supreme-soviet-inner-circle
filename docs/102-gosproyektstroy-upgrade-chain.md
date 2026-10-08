# 102 · 苏联「国家建筑设计局」升级链 —— 改成 **4 国任意顺序 + 3 专精任意顺序、每项叠加**

> 用户口径（2026-09-25）：
> ① 「苏联外国专家不是会解锁一个决议组来升级一个工业企业吗，这个决议组能不能取消掉各个决议之间的互斥
>    并且能做到所有升级决议都可以先后完成」
> ② 「不要加成国家精神，还是写新的 modifier 吧，改工业企业特质，七步固定顺序累积没问题，
>    **不过原版那是怎么实现，4×3 十二个组合？**」
> ③ 「其实你要是有能力的话要不然写成 **4+3 任选**的样子，就是**先选四个国家，四个国家任意顺序点完
>    才能点三个专精，专精也是任意顺序**，这样就没那么多问题了」
> ④ 「**可以加进自动同步**」
>
> 本文是这条链的**唯一权威出处**（规格 = 生成器 `build/gen-hof-gos-chain.py`）。

---

## §0 先回答用户的问题：**原版是怎么实现的**（4×3 = 12 个组合确实存在，但不是 12 张卡）

### 0.1 它长什么样

| 项 | 原版事实（`R56 common/decisions/SOV.txt` L4688–5100，**与 F 盘原版逐字相同**） |
| --- | --- |
| 解锁 | 国策 `SOV_foreign_experts`（外国专家）→ 工业企业 `SOV_gosproyektstroy_1`（显示名「国家建筑设计局」） |
| 决议组 | 分类 `SOV_gosproyektstroy_decision_category`（页签），下有 **4 个 decision 块** |
| 卡 | 阶段 1 = **一张 targeted decision**（`targets = { USA ENG GER JAP }`，一张卡 4 个国家按钮）；阶段 2 = **三张**（民用 / 军用 / 造船厂） |
| 每项 | `days_remove` = **90 天**（变量 `SOV_gosproyektstroy_decision_time`）· `cost` = **50 PP** · 期间 `civilian_factory_use = 3` · `fire_only_once = yes` |
| 串行 | 做一项时设 `SOV_gosproyektstroy_upgrade_in_progress_flag`，所有卡的 `available` 都要求**没有**这个 flag ⇒ **同一时间只能做一项** |

### 0.2 互斥是**三样东西**造成的，**一个 `mutually_exclusive` 都没有**

1. `SOV_gosproyektstroy_level_2_flag` 与 `SOV_gosproyektstroy_level_3_flag` 是**单值 flag**
   （分别记 1–4 与 1–3）—— 一写就锁死「你选的是哪一个」。
2. 每张卡的 `visible` 里写着 **`NOT = { has_country_flag = … }`**
   ⇒ 做过一张，**同层其余全部消失**。
3. level-3 的 `remove_effect` 用 **`if / else_if` 按 `level_2_flag` 的值**只处理「当前那一个」国家。

### 0.3 ⭐ 于是：**17 个 idea、12 个组合、7 张卡、玩家一世只能点 2 张**

原版一共定义了 **17 个 idea**（`common/ideas/SOV.txt`，全部 `name = SOV_gosproyektstroy_1`）：

| 层 | 个数 | 内容 |
| --- | --- | --- |
| `_1` | 1 | 基础：三类工厂建造速度 +0.05 / `license_purchase_cost = -0.25` |
| `_2_<国>` | 4 | 各国自己那一份「国别特性」（见 §5.2）—— 四国**互不相同** |
| `_3_<国>_<方向>` | **12** | **= 4 国 × 3 方向 的笛卡尔积** |

**为什么是 12 个而不是 3 个？** ⭐ 因为 **HOI4 的 idea modifier 是静态写死的**：
一个 idea = 一份固定的加成表。「美国 + 民用」与「德国 + 民用」是两个不同的 idea，
所以每一种「国别 × 方向」的组合都必须**预先写成一个 idea**。
而**卡**只需要 7 张（4 个国家按钮 + 3 张方向卡）—— 方向卡用 `if/else_if` 读 `level_2_flag`
来决定 swap 到哪一个组合 idea。

⇒ 所以原版真实形态是：**17 个 idea · 7 张卡 · 玩家一世只能点 2 张 · 最终拿到 12 个组合之一**。

---

## §1 为什么不能「把互斥删掉」就完事

因为**叠加**与**顺序**在静态 idea 下是矛盾的：

| 需求 | 静态 idea 能不能表达 |
| --- | --- |
| 只放开互斥、不叠加（12 张卡都能点一遍，最后留一个组合） | ✅ 能（≈ 改 10 行）—— 但「升级」白做 |
| **固定顺序**累积（如 USA→ENG→GER→JAP→CIV→MIL→DOCK） | ✅ 能（7 级线性链，7 个新 idea） |
| **任意顺序**累积 | ⚠️ 能，但**必须枚举「已完成的集合」**：4 国 ⇒ 2⁴−1 = **15 态**；3 专精 ⇒ 2³−1 = **7 态** ⇒ **22 个 idea** |

### 1.1 另外两条被否掉的路（记录，避免下次重走）

| 案 | 做法 | 为什么不用 |
| --- | --- | --- |
| **乙** 国家精神 | 每完成一项 `add_ideas` 一个精神（7 个精神），任意顺序天然成立 | ⛔ **用户 2026-09-25 明令「不要加成国家精神」**；且与本 mod 核心圈的动态精神容器叠一起会挤 |
| **多槽位并存** | 把 4 国做成 4 个可并存的工业企业 idea | ⛔ 工业企业只有 **3 个槽**（`docs/94` 扩的），而 UI 那组在 `slotsize width = 60` 下**恰好 8 格 = 上限**（533 / 60 = 8.88）⇒ 加不下 |
| 动态修饰符（dynamic modifier） | 7 个 DM 各自一份加成，`add_dynamic_modifier` 叠加 | ⚠️ 技术上可行且任意顺序，但**在 UI 上不显示** ⇒ 违反「改工业企业特质」的字面要求；本轮未采用（**备查**） |

### 1.2 ✅ 用户裁决 = 「4+3 任选」（枚举 22 态）

---

## §2 落地：**4 个文件 · 1 个生成器 · 1 套同步机制**

| 文件 | 角色 | 编码 |
| --- | --- | --- |
| `build/gen-hof-gos-chain.py` | ⭐ **生成器（规格的唯一出处）** | Python（项目内先例：`gen-hof-ma-idea-icons.py`） |
| `mod/heart_of_iron/common/ideas/hof_gos_chain.txt` | **23 个 idea**（基础 1 + 22 组合态）—— 由生成器产出 | UTF-8 **无 BOM** + CRLF |
| `build/inject-dec-gos.txt` | **4 个决议块的替换文本**（带 `# hof:dec-begin/end` 标记） | UTF-8 无 BOM + CRLF |
| `mod/heart_of_iron/common/decisions/SOV.txt` | **整文件覆盖 + 决议块替换**的产物（不手改） | UTF-8 无 BOM + CRLF |
| `mod/heart_of_iron/common/ideas/SOV.txt` | 原版那 17 个 idea **已删除**，只留一段指路注释 | UTF-8 无 BOM + CRLF |

⭐ **重新生成两步**：
```
python build/gen-hof-gos-chain.py          # ① 生成 ideas 文件 + 决议块注入文件
powershell -NoProfile -File build/sync-from-r56.ps1   # ② 把决议块打进 decisions/SOV.txt
```

---

## §3 状态表：23 个 idea（= 1 基础 + 22 组合态）

| 阶段 | idea id | 状态（已完成的集合） |
| --- | --- | --- |
| — | `SOV_gosproyektstroy_1` | 什么都没做（基础） |
| 1 | `hof_gos_c1_usa` / `_eng` / `_ger` / `_jap` | 单国 |
| 1 | `hof_gos_c2_usa_eng` / `_usa_ger` / `_usa_jap` / `_eng_ger` / `_eng_jap` / `_ger_jap` | 两国（6） |
| 1 | `hof_gos_c3_usa_eng_ger` / `_usa_eng_jap` / `_usa_ger_jap` / `_eng_ger_jap` | 三国（4） |
| 1 | `hof_gos_c4_usa_eng_ger_jap` | 四国全到 ⇒ 同时设 `hof_gos_country_phase_done` |
| 2 | `hof_gos_s1_civ` / `_mil` / `_dock` | 4 国全 + 1 方向 |
| 2 | `hof_gos_s2_civ_mil` / `_civ_dock` / `_mil_dock` | 4 国全 + 2 方向 |
| 2 | `hof_gos_s3_all` | **全收集（12 条加成）** |

⭐ 命名即状态：`hof_gos_c<国数>_<国…>` / `hof_gos_s<方向数>_<方向…>` ⇒
`verify-s2` §20c 直接**从名字反推期望的 flag 集合**再与 `visible` 比对（最强的防错断言）。

### 3.1 进度载体

| 载体 | 用途 |
| --- | --- |
| **7 个布尔 flag** `hof_gos_usa/eng/ger/jap/civ/mil/dock` | 状态真值（顺序无关） |
| `hof_gos_started` | 已开始（基础 idea 的 `visible` 用它兜底） |
| `hof_gos_country_phase_done` | 4 国全到 ⇒ 解锁阶段 2 的 3 张卡 |
| `hof_gos_all_done` | 7 项全做完（留给后续扩展用） |
| `has_idea = <组合态>` | 决定 `swap_ideas` 的「从哪换到哪」 |
| ⚠️ `SOV_gosproyektstroy_level_2_flag` | **只为决议分类（页签）的 `visible`** —— 分类文件（`common/decisions/categories/SOV_decision_categories.txt`）**我们不覆盖**，它的 `visible` 判的是这个原版 flag ⇒ 第一次升级时必须顺手设上，否则整个页签会消失 |

---

## §4 决议改造（`build/inject-dec-gos.txt` → `decisions/SOV.txt` 的 4 个块）

| 卡 | 改动 | swap 分支数 |
| --- | --- | --- |
| `SOV_gosproyektstroy_bring_foreign_experts`（阶段 1，1 张卡 4 个目标） | `target_trigger` 只筛「**没做过的国家**」；外交好感、附庸与战争条件沿用原版 `available`；`fire_only_once` **yes → no**；`remove_effect` 按 `FROM.tag` 分 4 支、**每支枚举 8 种前态** | **32** |
| `SOV_gosproyektstroy_focus_civ` / `_mil` / `_dock`（阶段 2） | 门槛 = `hof_gos_country_phase_done` + **本方向还没做**；`remove_effect` **枚举 4 种前态** | 4 × 3 = **12** |

⭐⭐ **两处关键判断（都写进注释了）**：

1. **已邀请国别的顺序门写在 `target_trigger`**，由 `hof_gos_<国>` 逐目标排除；外交好感、附庸与战争条件放在原版使用的 `available` 的 `FROM` 块。2026-09-25 游戏反馈是分类页签未出现；四个目标被 `target_trigger` 全部筛掉是当前推断，待游戏内复测。恢复原版的外交条件位置后，目标应显示，条件不满足时应不可执行。
2. **`fire_only_once` 必须从 `yes` 改成 `no`** —— 阶段 1 那张卡要用 **4 次**（每国一次）；
   「同一国家不重复」由 `target_trigger` 里 `NOT = { has_country_flag = hof_gos_<国> }` 保证。

---

## §5 数值（全部来自原版，只是重新分配）

### 5.1 逐项贡献

| 来源 | 加成 |
| --- | --- |
| 基础（`_1`） | 三类工厂建造速度 **+0.05 / +0.05 / +0.05** · `license_purchase_cost = -0.25` |
| **美国** | `production_factory_max_efficiency_factor = 0.1`（最大效率上限） |
| **英国** | `line_change_production_efficiency_factor = 0.1` · `production_lack_of_resource_penalty_factor = -0.1` |
| **德国** | `production_factory_efficiency_gain_factor = 0.05`（效率增长率） |
| **日本** | `production_factory_start_efficiency_factor = 0.1`（起始效率） |
| **民用** | 民用建造速度 0.05 → **0.10** · `consumer_goods_factor = -0.15` |
| **军用** | 军用建造速度 0.05 → **0.10** · `industrial_capacity_factory = 0.05` |
| **船坞** | 船坞建造速度 0.05 → **0.10** · `industrial_capacity_dockyard = 0.05` |

### 5.2 终态（`hof_gos_s3_all`，12 条）

```
production_speed_industrial_complex_factor   = 0.1
production_speed_arms_factory_factor         = 0.1
production_speed_dockyard_factor             = 0.1
license_purchase_cost                        = -0.25
production_factory_max_efficiency_factor     = 0.1     # 美
line_change_production_efficiency_factor     = 0.1     # 英
production_lack_of_resource_penalty_factor   = -0.1     # 英
production_factory_efficiency_gain_factor    = 0.05    # 德
production_factory_start_efficiency_factor   = 0.1     # 日
consumer_goods_factor                        = -0.15   # 民用
industrial_capacity_factory                  = 0.05    # 军用
industrial_capacity_dockyard                 = 0.05    # 船坞
```

### 5.3 成本（与原版一致，不额外加价）

**7 项 × 90 天 = 630 天**（串行，一次只能做一项）· **7 × 50 PP = 350 PP** ·
每项进行中占用 **3 个民用工厂**。

### 5.4 ⭐ 一处与原版不同的呈现

原版 `_2_*` 的 `modifier` 里带 `custom_modifier_tooltip = SOV_gosproyektstroy_1_tt`
（「该设计商可被升级以增加新的加成并升级现有加成。」）—— 带上它，**工具提示就只显示那句话、
看不到数值**。原版 `_3_*`（终态）**没有**它。
⇒ 本链的 22 个组合态**全部不带**它，这样玩家在工业企业槽的提示里能**看到当前累积的全部数值**。
（基础 `_1` 保留它，与原版一致。）

---

## §6 自动同步（用户口径 ④）

### 6.1 `attach-points.json` 新增 `extraFiles`

```json
"extraFiles": [
  { "id": "dec_sov", "tag": "SOV", "phase": 1,
    "srcRelativePath": "common/decisions/SOV.txt", "origin": "r56", "notes": "…" }
]
```

⭐ **为什么单开一个键而不是塞进 `points`**：`points` 的语义是「**国策树**挂载点」
（必须有 `treeId`、要做锚点注入、要参与经互会通用线 S5）；
而 `verify-s2` **§13** 与 `verify-sync.ps1` 都**只读 `points`** ⇒ 放新键**零副作用**。

### 6.2 `sync-from-r56.ps1` 新增三件事

| 新增 | 作用 |
| --- | --- |
| 读 `build/inject-dec-gos.txt` → `$DecisionBlockMap` | 按 `# hof:dec-begin/end` 标记切出 4 个块（内容**不**在脚本里手抄） |
| 函数 `Set-DecisionBlock` | 按 `<缩进><id> = {` 定位、**花括号配平扫描**找块尾、整块替换；命中数必须恰好 1 |
| 「额外覆盖文件」循环 | ① 整文件覆盖 ② 替换 4 个块 ③ **花括号差值自检** |

⭐⭐ **两个真踩到的坑**：

1. **`decisions/SOV.txt` 的花括号本来就「不平」**（实测 **5913 `{` / 5912 `}`**）——
   因为文件里有**注释掉的代码块**带花括号。所以自检**不能**写「`{` 数 == `}` 数」，
   必须比较**替换前后的差值**（`$srcDelta` vs `$d1`）。第一次就因为这个 red 了。
2. **id 行的缩进是一级 tab、字段是两级**（`\t<id> = {` / `\t\t<field>`）——
   注入文件里的行按目标文件缩进**原样写好**，`Set-DecisionBlock` **不再做缩进换算**。

---

## §7 边界情况与已知代价（如实登记）

| # | 情况 | 行为 | 处置 |
| :-: | --- | --- | --- |
| ① | **某个国家在轮到它之前变得不可用**（被吞并 / 与苏联交战 / 好感 < 30） | 那一国的**按钮不亮** ⇒ 该阶段走不完（阶段 2 不会解锁） | ⚠️ **任意顺序已经大幅缓解**（美国不行可以先做德国）；这是「固定顺序」方案才有的硬伤。**保留**：好感可以通过外交改善 |
| ② | **玩家中途换成别的工业企业**（本链 idea 被顶掉，flag 还在） | 阶段 1 的卡仍可见，`remove_effect` 的「前态 = 基础 idea」分支会**清零进度重新开始** | ✅ 已加安全网，**不会卡死**；阶段 2 中途换走则可能留下「flag 已设但没有 idea」——**只是白做，不锁死**（重新买基础 idea 会清零重来） |
| ③ | 22 个组合态都在设计师列表里「可能出现」 | 每个态的 `visible` 是**精确状态** ⇒ 同时只会有一个可见 | ✅ 与原版同型 |
| ④ | 组合态的 idea 也可能被玩家花 100 PP「买」（它出现在列表里） | 与原版 `_2_*` / `_3_*` 的行为**一致**（原版也这样） | ✅ 照原版，不额外加固 |
| ⑤ | `common/ideas/SOV.txt` 是我们的整文件覆盖副本（R56 更新要手工重合并） | 老问题（`docs/95` §6 已登记） | ✅ 本轮只删了 17 个 idea、留了指路注释，diff 很小 |

---

## §8 自检（`build/verify-s2.ps1` **§20** · 11 项）

① 编码（两个脚本 `.txt` 无 BOM）· ② 类别 = `industrial_concern` · ③ **idea 数 = 23** ·
④ ⭐ **23 个 idea 的 `visible` 与名字（组合态）逐条对齐** · ⑤ 终态 = 12 条完整加成 ·
⑥ `SOV_gosproyektstroy_*` 已从 `ideas/SOV.txt` 移出（不重复定义）· ⑦ 产物含全部新标记 ·
⑧ `swap_ideas` = **66**（= 原版 38 − 旧 16 + 新 44）· ⑨ ⭐ **挖掉 4 个决议块后与 R56 源逐行相同** ·
⑩ 同步脚本五件套在位 · ⑪ `attach-points.json` 的 `extraFiles` 恰一条。

---

## §9 ⬜ 待游戏内验证（硬性规则 5）

| # | 项 | 期望 |
| :-: | --- | --- |
| ① | 做完「外国专家」国策后买下「国家建筑设计局」 | 决议页签出现，阶段 1 那张卡显示**四个国家目标**；满足外交条件的目标可点（阶段 1 任意顺序） |
| ② | 依次邀请 4 国（**乱序**，例如 德→美→日→英） | 每完成一项：卡片消失 → 90 天后工业企业 tooltip 的数值**增加一项**，且**总是同一组**（与顺序无关） |
| ③ | 4 国到齐 | 阶段 1 卡消失，**3 张专精卡同时出现**（任意顺序） |
| ④ | 做完 3 个专精 | 工业企业 tooltip = §5.2 的 **12 条** |
| ⑤ | `日志/error.log` | **不出现**本次改动引入的报错（尤其：23 个 idea 全被加载、`hof_gos_chain.txt` 无解析错误） |
