# 95 · `old/` 旧 mod 数值迁移（2026-09-20）

> 用户口径：「我在 `old` 里放了一些我以前自己写的 mod 的数值，你需要把里面**除了 `country_leader` 的部分**
> 迁移到我们的 mod 里，你可能需要**比对一下和现在我们有的版本相比有哪些变动**。
> 哦对，**`z_etc` 那个文件夹也不用动**，那个是指令集。」
>
> 本文是这次迁移的**唯一权威出处**：每一条的「现在的基底 / 老文件改了什么 / 处置 / 出处」都只写在这里。

---

## §0 一条必须先讲清的方法论

⚠️⚠️ **`old/` 里的文件不是「老 mod 的改法」，而是「旧版原版 + 老 mod 的改法」。**

实测证据：`old/common/characters/SOV.txt` 的**顶层角色块数 = 409，与原版一模一样**，
且「老 mod 有、原版没有」的 id **= 0** —— 说明它是**某个旧版本原版的副本**，用户只在上面做了自己的改动。
`old/interface/divisiondesignerview.gui`（35 KB）更是有 **1 920 行**结构性差异，全部是**旧版原版的旧布局**。
`old/history/states/217`、`219` 里还留着旧版原版的 `add_to_array = { state_victory_points = … }` 语法。

⇒ **迁移原则（三条）**：
1. **只迁「相对现在的基底真正变了的东西」**，不迁「旧版原版本来就这样、后来被原版/R56 改掉了」的东西 ——
   否则等于把 R56 的更新**倒回去**（`history/states/217` 的 `add_core_of = DON` 就是明例）。
2. **基底取「现在的实际基底」**：R56 有该文件的取 R56，否则取原版（同 `build/sync-from-r56.ps1` 的既有约定）。
3. **一个字面差异都要有结论**（迁 / 不迁 / 待裁），不许静默丢弃。

---

## §1 逐文件对照表

| # | `old/` 文件 | 现在的基底 | 老 mod 真正改了什么 | 处置 |
| --- | --- | --- | --- | --- |
| 1 | `common/defines/00_defines.lua` | 原版 `00_defines.lua` | **6 项真改** + 6 项与原版相同 + 1 处**漏前缀的 bug** | ✅ **已迁**（见 §2） |
| 2 | `common/characters/SOV.txt` | **R56**（151 块） | 给 **52 个军官**加 `trait_SOV_trotskyist`（**只有这一件事**） | ✅ **已迁**（见 §3） |
| 3 | `common/ideas/SOV.txt` | **R56** | **5 个 SOV 精神**的 `modifier` 块被大幅加强 | ✅ **已迁**（见 §4） |
| 4 | `common/national_focus/soviet.txt` | 本 mod 的 `soviet.txt`（R56 同步版） | 托洛茨基的 `add_field_marshal_role`：特质 2 → **10**、技能 4/3/2/4/4 → **全 8** | ✅ **已迁**（见 §5） |
| 5 | `common/units/super_heavy_armor.txt` | **R56** | `manpower` 300 → **500** | ✅ **已迁**（只迁这一项） |
| 6 | `history/states/217-Stalingrad Area.txt` | **R56** | ⭐ **新增 `resources { tungsten = 600 }`**（原版/R56 都没有） | ✅ **已迁**（只迁这一项） |
| 7 | `history/states/219-Moscow Area.txt` | **R56** | ⭐ **新增 `resources { tungsten = 200 }`**（原版/R56 都没有） | ✅ **已迁**（只迁这一项） |
| 8 | `common/idea_tags/00_idea.txt` | 本 mod 新建的那份 | 老 = 顾问 **5** / 工业 **2** / 理论家 **2** / 总司令 **5** | ⬜ **待裁**（见 §6.1） |
| 9 | `interface/countrypoliticsview.gui` | 本 mod 新建的那份 | 老 = `slotsize width 50` + `max_slots x 7` | ⬜ **待裁**（见 §6.2） |
| 10 | `common/units/land_cruiser.txt` | 原版 | **无有意改动**（差异全是旧版原版缺少新版才有的地形修正 / `regimental = no` 等） | ⛔ **不迁**（见 §7.1） |
| 11 | `interface/divisiondesignerview.gui` | 原版 | **无有意改动**（1 920 行差异全是旧版原版的旧布局） | ⛔ **不迁**（见 §7.2） |
| — | `common/country_leader/00_traits.txt` | — | 用户明示**排除** | ⛔ **不动**（见 §8） |
| — | `z_etc/`（7 个文件） | — | 用户明示**排除**（指令集） | ⛔ **不动** |

---

## §2 defines（`common/defines/`）

### §2.1 ⚠️ 关键：**不能同名，必须是 override 文件**

🚩🚩 老文件叫 `00_defines.lua` —— **那个名字会把原版 405 669 字节的 `00_defines.lua` 整文件覆盖掉**（硬性规则 2）。

⭐ **官方 wiki 两处原文（本项目离线快照）**：

- `docs/reference/wiki/Map_modding.txt`：「**When editing Defines, make sure to use an override file
  rather than copying the entire file, as that can cause game crashes when new defines get added,
  which can happen even in 'minor' updates.**」
- `docs/reference/wiki/National_focus_modding.txt`：「Note that while modifying defines to use
  **a define override file** rather than copying over the entire file, as even otherwise 'minor'
  updates can add new defines causing potential crashes.」

⇒ **落地 = `mod/heart_of_iron/common/defines/zz_hof_ic_defines.lua`**（新名，排在 `00_defines.lua` 之后 → 覆盖生效）。

### §2.2 逐项对照

| define | 原版 | 老 mod | 处置 |
| --- | --- | --- | --- |
| `NProduction.DEFAULT_MAX_NAV_FACTORIES_PER_LINE` | 10 | 10 | ⛔ 相同，不写 |
| `NProduction.FLOATING_HARBOR_MAX_NAV_FACTORIES_PER_LINE` | 5 | 5 | ⛔ 相同，不写 |
| `NProduction.CONVOY_MAX_NAV_FACTORIES_PER_LINE` | 15 | 15 | ⛔ 相同，不写 |
| **`NProduction.CAPITAL_SHIP_MAX_NAV_FACTORIES_PER_LINE`** | **5** | **40** | ✅ **迁** |
| `NBuildings.OWNER_CHANGE_EXTRA_SHARED_SLOTS_FACTOR` | 1 | 1 | ⛔ 相同，不写 |
| **`NMilitary.MAX_DIVISION_SUPPORT_WIDTH`** | 1 | 1 | ⚠️ 用户 2026-09-20 改口径 → **仍写 1**（显式写死，见下） |
| **`NMilitary.MAX_DIVISION_SUPPORT_HEIGHT`** | **5** | 6 | ✅ **迁**（用户改口径为 **1×7** → 写成 **7**） |
| **`NMilitary.TRAINING_MAX_LEVEL`** | **2** | **3** | ✅ **迁** |
| **`NMilitary.UNIT_LEADER_TRAIT_SLOT_PER_LEVEL`** | `{0.5, 0.5, 0.5, 0.0}` | `{1.2, 1.2, 1.5, 0.0}` | ✅ **迁** |
| **`NMilitary.UNIT_LEADER_USE_NONLINEAR_XP_GAIN`** | **true** | **false** | ✅ **迁** |
| **`NAir.AIR_WING_XP_TRAINING_MAX`** | **300.0** | **500.0** | ✅ **迁** |
| **`NAir.TRAINING_DAILY_COUNTRY_EXP_SHIP_RATIO_FACTOR`** | **300.0** | **500.0** | ✅ **迁**（⚠️ 老文件**漏了 `NDefines.NAir.` 前缀** → 那行其实什么也没改，本处**已补前缀**） |

⭐ 净效果：**舰船产线上限 ×8**（5→40）· **师的支援营由 1×5 扩到 1×7**（7 格，只加高不加宽）· **训练上限 2→3 级** ·
**军官每级特质槽 0.5→1.2/1.5** · **军官 XP 不再按特质数摊薄** · **空军训练 XP 300→500** · **舰船训练 XP 比 300→500**。

**2026-10-01 修正：**上段是旧版迁移时的记录。R56 将陆军等级细分为 0–20，且演习上限设为 10；本模组的 `TRAINING_MAX_LEVEL = 3` 覆盖了 R56，导致只能练到“乌合之众 IV”。用户随后将目标从“常规军 IV”提高到“常规军 V”，现行值为 **14**；实际数值以 `mod/heart_of_iron/common/defines/zz_hof_ic_defines.lua` 为准。

> 🚩 **验收提醒**：defines 是**加载期**读取，改错**不报行号只报 define 名**。启动后先看 `日志/error.log`
> 有没有 `NDefines` 相关行。（控制台 `reload defines` 可热重载 —— 见 `docs/reference/wiki/Troubleshooting.txt`。）

---

## §3 `common/characters/SOV.txt` —— 52 个军官加 `trait_SOV_trotskyist`

### §3.1 老文件到底改了什么

把老文件与原版逐块比对（`difflib` opcode 统计）：**只有 52 处 replace，且 52 处的「新内容」全都是
在 `traits = { … }` 末尾多出 ` trait_SOV_trotskyist`** —— **没有任何 `country_leader` 改动**。

⇒ ⭐ **这就解释了用户那句「除了 `country_leader` 的部分」**：这个文件的改动本来就全在**军事指挥官**身上
（38 个 `corps_commander` + 9 个 `field_marshal` + 5 个 `navy_leader`）。

### §3.2 迁移结果

- **基底 = R56 的 `common/characters/SOV.txt`**（R56 有 **151** 块，原版只有 **118** 块 —— 必须用 R56 版，
  否则会丢掉 R56 新增的 45 个角色）。
- **落笔 51 / 52**：

| 情形 | 人数 | 处置 |
| --- | --- | --- |
| 正常追加 | **48** | 直接在同一职务的 `traits` 行尾追加 |
| ⚠️ **R56 改了职务**（按实际职务落笔） | **3** | `SOV_grigory_kulik`（corps→**field_marshal**）· `SOV_vladimir_kosmin`（field→**corps_commander**）· `SOV_andrey_shkuro`（corps→**field_marshal**）。R56 自己就标了注释 `#role changed like r56` |
| ⛔ **R56 已删此人** | **1** | `SOV_gordey_levchenko` —— R56 里查无此 id，**跳过并在此备案** |

- ⚠️ 另有两处（`SOV_filipp_golikov` / `SOV_vasily_chuykov`）的 traits 行**尾带 R56 的注释**（`#modified like r56` /
  `#added lucky from r56`）—— 脚本按「行尾可有注释」处理，**注释原样保留**。

- ⭐ **`trait_SOV_trotskyist` 是真实存在的原版特质**（定义在 `common/unit_leader/NSB_traits.txt`；
  原版 `common/decisions/SOV.txt` 用 16 次、`common/national_focus/soviet.txt` 用 17 次）→ **不是臆造语法**。

---

## §4 `common/ideas/SOV.txt` —— 5 个 SOV 精神的加强

基底 = **R56 的 `common/ideas/SOV.txt`**；做法 = **只替换每个 idea 的 `modifier = { … }` 块**，其余（`name` / `picture` /
`removal_cost` / `allowed` …）保持 R56。

| idea | R56 的 modifier | 老 mod 的 modifier（= 现在的值） |
| --- | --- | --- |
| `SOV_socialist_emulation_2_ns` | 5 条（`production_factory_efficiency_gain_factor 0.05` · `research_speed_factor 0.02` …） | **8 条**：`industrial_capacity_factory **1.50**` · `industrial_capacity_dockyard **1.50**` · `production_factory_max_efficiency_factor **1.00**` · `production_factory_efficiency_gain_factor **1.00**` · `research_speed_factor **0.10**` · `drift_defence_factor 0.05` · `communism_drift 0.05` · `consumer_goods_factor **−0.10**` |
| `SOV_transformation_of_nature` | 3 条（含 `global_building_slots_factor 0.1`） | **4 条**：`stability_factor 0.05` · `consumer_goods_factor **−0.06**` · `global_building_slots **5**` · `local_resources_factor **3.0**` |
| `SOV_collectivist_propaganda_ns` | 4 条 | **7 条**：`stability_factor 0.1` · `conscription_factor **0.55**` · `non_core_manpower **0.15**` · `army_morale_factor **0.10**` · `army_org_factor **0.20**` · `training_time_army_factor **−0.10**` · `weekly_manpower **5000**` |
| `SOV_the_peoples_revolution_idea` | 2 条（`max_command_power 20` · `recruitable_population 0.02`） | **6 条**：`max_command_power **200**` · `conscription 0.03` · `army_morale_factor **0.50**` · `org_loss_when_moving **−0.20**` · `attrition **−0.20**` · `weekly_manpower **5000**` |
| `SOV_soviet_atomic_bomb_project_ns` | （R56 版） | **2 条**：`operative_slot **1**` · `special_project_speed_factor **0.95**` |

⚠️ **两处「换量纲」如实记录（不是笔误，是刻意改的）**：
`global_building_slots_factor = 0.1`（**百分比**）→ `global_building_slots = 5`（**平铺格数**）；
`recruitable_population = 0.02` 被**删掉**换成 `conscription = 0.03`。
⭐ 全部 modifier 键都在原版 `Modifiers` 表内（逐个核过 `docs/reference/wiki/Modifiers.txt`）→ **不会硬报错**。

---

## §5 托洛茨基的元帅职务加强（`common/national_focus/soviet.txt`）

### §5.1 为什么不能直接改文件

`soviet.txt` 由 `build/sync-from-r56.ps1` **每次从 R56 重新生成** → 手工改一行，下次同步就被覆盖。
⇒ ⭐ **给同步脚本新增了「值补丁」机制**（`$ValuePatchMap` + `Apply-ValuePatches`），
和既有的「注入 / 国策内插」并列，**同样可反复重跑、失败即 throw**。

### §5.2 改了什么

R56 源里 `SOV_the_builder_of_the_red_army` 的 `completion_reward`：

```text
（改前）add_field_marshal_role = { character = SOV_lev_trotsky
        traits = { media_personality organisational_leader }
        skill = 4 / attack 3 / defense 2 / planning 4 / logistics 4 }

（改后）add_field_marshal_role = { character = SOV_lev_trotsky
        traits = { media_personality organisational_leader brilliant_strategist war_hero bearer_of_artillery
                   infantry_officer cavalry_officer armor_officer engineer_officer }
        skill = 8 / attack 8 / defense 8 / planning 8 / logistics 8 }
```

🚩🚩 **一处必须订正的写法**：老文件里特质是**大写**的（`Brilliant_Strategist` · `War_Hero` · `Bearer_of_Artillery` ·
`Infantry_Officer` · `Cavalry_Officer` · `Armor_Officer`）—— **引擎只认小写**（已逐个核过原版
`common/unit_leader/*.txt`：`brilliant_strategist` / `war_hero` / `bearer_of_artillery` / `infantry_officer` /
`cavalry_officer` / `armor_officer` 才是真键）⇒ **迁移时已全部改成小写**，否则会在 `error.log` 里报未知特质。

### §5.3 机制说明

- 新增 `$ValuePatchMap`（键 = 挂载点 id，值 = 一组 `@{ Name; Old=@(行…); New=@(行…) }`）
- 新增 `function Apply-ValuePatches`：把 `Old` 逐行 `Trim()` 后 `regex::Escape`、行间用 `\s*` 连接，
  **命中数 ≠ 1 就 throw**（宁可报错也不静默改错位置 —— 与既有 `Add-FocusPatches` 同一纪律）
- 缩进策略：**`Old` / `New` 里不写行首缩进**，脚本按命中处的缩进自动补；`New` 里用真制表符写**相对缩进**
- 同步日志的状态行新增一列：`/ 值补丁 N`

---

## §6 ⬜ 待裁两项（判据 J）

### §6.1 `common/idea_tags/00_idea.txt`：**理论家槽位**

| | 本 mod 现在（本轮刚做） | 老 mod |
| --- | --- | --- |
| `political_advisor` | **5** | 5 |
| `industrial_concern` | **3** | **2** |
| `theorist` | **1** | **2** ⭐ |
| `high_command` | **5** | 5 |

- 用户本轮口径是「顾问 +2 / 工业企业 +2 / 总司令 +2」→ 顾问 3→5、工业 1→3、总司令 3→5 ✅ 与老 mod 的顾问/总司令一致。
- ⚠️ **老 mod 还多一个 `theorist`（1→2）**，而本轮口径没提。
- ⚠️ 工业：老 mod 是 **2**，本轮口径 +2 得到 **3**。

✅ **2026-09-20 用户裁决：「理论家不用动」** → 取 **甲**：`theorist` 保持 **1**、`industrial_concern` 保持 **3**、`political_advisor` 5、`high_command` 5。**代码零改动。**

### §6.2 `interface/countrypoliticsview.gui`：槽位宽度

| | 本 mod 现在 | 老 mod |
| --- | --- | --- |
| `slotsize width` | **60**（用户本轮口径） | **50** |
| `max_slots` | **x = 8** | **x = 7** |

- 用户先说 60-65，随后改口「**宽度还得缩，要 60**」→ 现为 **60**（8 × 60 = 480 ≤ 533 ✅）。
- ⚠️ 老 mod 用的是 **50**；若你要的是 50：8 × 50 = 400（更宽松），但图标更小。
✅ **2026-09-20 用户裁决：「ui 宽度那改成 50 吧」** → 取 **乙**：`slotsize = { width = 50 height = 64 }`
（**8 × 50 = 400 ≤ 533** ✅，比 60 更宽松）。已落地并回写 `docs/94`。

### §6.3 另外两处「原版/R56 跟老 mod 不一致，我按「不倒退」处理了」的

| 位置 | R56 现在 | 老文件 | 我为何**没有**跟着老文件改 |
| --- | --- | --- | --- |
| `history/states/217` `arms_factory` | **1** | 2 | 老文件的 2 是**旧版原版值**，R56 已下调 → 跟着改等于**撤销 R56 的平衡** |
| `history/states/219` `arms_factory` | **6**（R56 注释 `# was 7`） | 7 | 同上：R56 **特地**从 7 改成 6 并留下注释 |
| 两州的 `1939.1.1 { buildings { … } }` 块 | **无** | 有 | 旧版原版内容，R56 已移除 |
| 两州的 `add_to_array = { state_victory_points = … }` | **无** | 有 | 旧版原版语法，R56 已换写法 |
| 217 的 `add_core_of = DON` | **无** | 有 | 旧版原版内容（**给顿河核心**），R56 已删 |
| 两州的 `manpower` | 1 452 863 / 8 147 312 | 1 135 070 / 8 335 992 | 旧版原版值 |

✅ **2026-09-20 用户裁决：「217 和 219 的那三个保持 R56 吧」** → 取 **甲**：`arms_factory` / `manpower` / `1939.1.1` 块
**一律保持 R56**，不照抄老文件。**代码零改动**（本轮只迁了两州的 `tungsten`）。

---

## §7 ⛔ 明确**不迁**的两个文件

### §7.1 `common/units/land_cruiser.txt`

老文件 **909 B** vs 原版 **1 444 B**。差异全部是**老文件缺少新版才有的内容**：
`category_divisional_support_battalions` · `regimental = no` · 以及**整套地形修正**（forest / hills / mountain /
jungle / marsh / urban / river / amphibious）。**没有任何一项是老 mod 自己加的**。
⇒ 迁过去 = **把 unit 退版**（陆巡洋舰会重新变成在所有地形都无惩罚）。⛔ **不迁**。

### §7.2 `interface/divisiondesignerview.gui`

老文件 **35 009 B** vs 原版 **48 196 B**，**1 920 行**结构性差异 —— 例如
`GFX_division_3d_entry` vs 新的 `GFX_division_3d_entry_half_width`、`size 510×44` vs `250×42`、
新版多出 `hq_overlay_images` 等容器。
⇒ 全部是**旧版原版的旧编制器布局**。⛔ **不迁**（迁过去会破坏新版编制器，并丢掉 `No Step Back` 之后的改动）。

---

## §8 用户明示排除的两处

| 路径 | 内容（仅备案，不动） |
| --- | --- |
| `common/country_leader/00_traits.txt` | 2 个领袖特质：`pc_military_naval_affairs`（一堆工业/海军加成）· **`strong_party_discipline`**（注释就写着 `#THE SUPREME SOVIET`）。⚠️ 本项目**已有自己的升级版** —— `mod/heart_of_iron/common/country_leader/hof_ic_leader_traits.txt`（AGENTS 记的「党纪严明升级版」）⇒ 真要迁这份，**得先和我们的版本对齐**，本轮按用户口径**不动** |
| `z_etc/`（7 个文件） | 用户口径：「那个是指令集」→ ⛔ **不动** |

---

## §9 📌 落地清单与校验

### §9.1 新增/修改的文件

| 文件 | 编码 | 基底 | 说明 |
| --- | --- | --- | --- |
| `common/defines/zz_hof_ic_defines.lua` | UTF-8 无 BOM + CRLF | —— | **新增**（override 文件，7 项） |
| `common/characters/SOV.txt` | UTF-8 无 BOM + CRLF | **R56** | 新增覆盖（51 处特质追加） |
| `common/ideas/SOV.txt` | UTF-8 无 BOM + CRLF | **R56** | 新增覆盖（5 个 modifier 块） |
| `common/units/super_heavy_armor.txt` | UTF-8 无 BOM + CRLF | **R56** | 新增覆盖（`manpower` 500） |
| `history/states/217-Stalingrad Area.txt` | UTF-8 无 BOM + CRLF | **R56** | 新增覆盖（`tungsten = 600`） |
| `history/states/219-Moscow Area.txt` | UTF-8 无 BOM + CRLF | **R56** | 新增覆盖（`tungsten = 200`） |
| `common/national_focus/soviet.txt` | UTF-8 无 BOM + CRLF | **R56**（同步生成） | 由新机制 `$ValuePatchMap` 落笔 |
| `build/sync-from-r56.ps1` | **UTF-8 **带 BOM** + CRLF** | —— | 新增 `$ValuePatchMap` + `Apply-ValuePatches` + 状态行列 |

⭐ 全部核验：**无 BOM**（脚本/UI/.txt 红线；`.ps1` 反过来必须**带** BOM）· **CRLF** · **无 `\r\r\n`** · **花括号配平**。

### §9.2 ⚠️ 一个既有的小瑕疵（**不是本轮引入**）

`soviet.txt` 里有 **1 个裸 LF**，位置在注入块的 `# hof:end sov_core` 之后。
已核对：**R56 源文件本身 bareLF = 0** ⇒ 是**注入机制**留下的（早于本轮）。HOI4 不介意，留档待日后清。

### §9.3 自检

| 步骤 | 结果 |
| --- | --- |
| `build/sync-from-r56.ps1` | **成功 17 / 失败 0 / 205 698 行**（`sov_core` 值补丁 **1**） |
| `build/gen-hof-ic-s3.ps1` | 见本轮全链校验 |
| `build/verify-s2.ps1` | 见本轮全链校验 |
| `build/verify-docs.ps1` | 见本轮全链校验 |

> 🚩 本次改动**大部分不在**既有自检的覆盖范围（defines / characters / ideas / units / states 都不是国策数据）
> ⇒ **验收标准仍是硬性规则 5：启动游戏后 `日志/error.log` 不出现本次改动引入的新错误**，
> 并肉眼确认：编制器支援栏变成 2×6、托洛茨基授元帅后技能全 8、5 个 SOV 精神的数值。

---

## §10 相关文件

- `docs/94`（全局槽位扩容 —— §6.1 / §6.2 那两项就是它的后续）
- `docs/reference/wiki/Map_modding.txt` · `National_focus_modding.txt`（**defines 必须用 override 文件**的原文）
- `docs/reference/wiki/Modifiers.txt`（modifier 键的权威表）
- `build/sync-from-r56.ps1`（新增「值补丁」机制）· `AGENTS.md` 硬性规则 2 / 3 / 5 / 10
