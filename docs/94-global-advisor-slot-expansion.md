# 94 · 全局槽位扩容（政治顾问 +2 / 工业企业 +2 / 总司令 +2）

> 用户口径（2026-09-20）：
> 「我要增加两个政治顾问槽位，两个工业企业槽位，两个总司令槽位，**全局的**，实际实现应该需要
> **代码上加槽位空槽**和**在 UI 调整槽位间隔**，这是一个中等工作量的修改，开工吧。
> **UI 数值的调整 width 参考值为 60-65**，同时记得 **UI 还要调整 max_slots**。」
>
> 本文是这次改动的**唯一权威出处**（槽位表 / UI 数值 / 待确认项都只写在这里）。

---

## §0 三个槽位在引擎里叫什么（先说清名词）

| 中文显示名 | 引擎里的键 | 类型 | 权威依据 |
| --- | --- | --- | --- |
| **政治顾问** | `political_advisor` | **character_slot**（角色槽） | `localisation/simp_chinese/ideas_l_simp_chinese.yml` → `political_advisor: "政治顾问"` |
| **工业企业** | `industrial_concern` | **slot**（想法 / 设计商槽） | 同上 → `industrial_concern: "工业企业"` · `idea_group_industrial_concern: "工业企业"` |
| **总司令** | `high_command` | **character_slot**（角色槽） | 同上 → `high_command: "总司令"` |

⭐ 三个名字**逐字对得上**用户的中文说法，没有猜。

---

## §1 数据侧：槽位数写在哪

⭐ **`common/idea_tags/*.txt` 是全局槽位表的唯一出处**（原版只有 `00_idea.txt` 一个文件）。
官方 wiki 两处原文佐证：

- `Triggers.txt` → `is_character_slot`：「**Character slots are defined within `/Hearts of Iron IV/common/idea_tags/*.txt`**」
- `Triggers.txt` → `amount_taken_ideas`：「**Slots types are found in `/Hearts of Iron IV/common/idea_tags/*.txt`**」

⭐ **「加槽位空槽」的机制 = 在对应类别里多写一行**（`character_slot = X` 或 `slot = X`）。
写几行就是几个槽；没填的时候游戏里显示为**空槽**。原版自己就是这么写的（`political_advisor` 三行一模一样、无名字）。

### §1.1 改动前后

| 类别（`idea_categories`） | 键 | 原文行数 | **改后** | 该类别槽位总数（前 → 后） |
| --- | --- | --- | --- | --- |
| `government` | `character_slot = political_advisor` | 3 | **5** | 3 法 + 3 顾问 = 6 → **3 法 + 5 顾问 = 8** |
| `research_production` | `slot = industrial_concern` | 1 | **3** | 4 设计商 + 1 工业 + 1 理论家 = 6 → **4 + 3 + 1 = 8** |
| `military_staff` | `character_slot = high_command` | 3 | **5** | 3 部长 + 3 总司令 = 6 → **3 + 5 = 8** |

> 🚩 **三个类别改后都恰好是 8 格** —— 这不是巧合，是 §2 的 UI 算术定下来的（8 × 50 = 400 ≤ 533）。

### §1.2 落地文件

`mod/heart_of_iron/common/idea_tags/00_idea.txt`（**新增**，UTF-8 **无 BOM** + **CRLF**）

🚩🚩 **基底取 R56 版，不是原版版** —— 因为 R56 也改了这个文件（`sync-from-r56.ps1` 的同一套道理）：

| R56 相对原版多出来的 | 位置 |
| --- | --- |
| 文件头注释 `# Mod by Sig "GreatExperiment" Altre` | 第 1 行 |
| **`etgi_ideas` 新类别**（5 个 R56 法案槽） | `research_production` 与 `academy_spirit` 之间 |
| 文件尾 `# End` | 末行 |

⛔ **若拿原版版当基底**，上面这三样会被**整文件覆盖**掉 → R56 的 5 个法案槽**静默消失**。
⚠️ **R56 将来若再改这个文件 → 必须重新合并**（同 `build/sync-from-r56.ps1` 的既有约定）。

---

## §2 UI 侧：槽位行要能放下 8 格

### §2.1 位置

`mod/heart_of_iron/interface/countrypoliticsview.gui`（**新增**，UTF-8 **无 BOM** + **CRLF**）

模板 `country_politics_idea_category_entry`（每个类别 = 一条 550 × 100 的横条）里的 `ideas_grid`：

```
gridboxtype = {
    name = "ideas_grid"
    position = { x = 17 y = 46 }
    size = { width = 100%% height = 100%% }
    # hof: 槽位 7 → 8、宽 80 → 50（容纳 政治顾问 5 / 工业企业 3 / 总司令 5；见 docs/94）
    slotsize = { width = 50 height = 64 }
    max_slots = { x = 8 y = 1 }
    format = "UPPER_LEFT"
}
```

⭐ **这条模板是三个类别共用的**（`government` / `research_production` / `military_staff` 各是一条横条），
所以**改一处 = 三条同时生效**。✅

### §2.2 算术（为什么是 8 × 50）

> 🔄 **本节是 2026-09-20 的快照；宽度已于 2026-09-24 改为 60** —— 见下方 **§2.4**。
> （保留本节原文作过程留档，不改写历史。）

| 项 | 值 |
| --- | --- |
| 窗口宽（`countrypoliticsview`） | **550** |
| `ideas_grid` 左起 | **x = 17** |
| → **可用宽** | 550 − 17 = **533** |
| 原规格 | 7 × 80 = **560**（**本来就溢出 27 px**，靠 `clipping = no` 容忍） |
| 新规格 | **8 × 50 = 400 ≤ 533** ✅ |
| 为什么只做 8 格 | ⚠️ **不是 UI 限制** —— 8 是 §1.1 的【槽位数】定的（三个类别改后都是 8）。宽 50 的话 9 × 50 = 450 其实也放得下；要再加槽位只改 `idea_tags` + 这里同步改 `max_slots` 即可 |

`max_slots = { x = 7 y = 1 }` → **`{ x = 8 y = 1 }`**（用户口径里的「记得调整 max_slots」）。
⚠️ **`y` 保持 1**：槽高 64、grid 起点 y = 46，第二行会落到 y = 110 > 100（横条高）→ 会压到下一条横条上。

### §2.4 🔄 2026-09-24：宽度 50 → 60（用户口径）

> 用户原话：**「之前改过顾问栏的间距，50 改成 60」**

| 项 | 值 |
| --- | --- |
| 可用宽（窗口 550 − grid 左起 17） | **533** |
| 本次改动 | `slotsize = { width = 50 height = 64 }` → **`{ width = 60 height = 64 }`** |
| 算术 | **8 × 60 = 480 ≤ 533** ✅（余 **53 px**） |
| 还能再宽吗 | 8 × **66** = 528 ≤ 533 ⇒ **66 是此槽位数下的理论上限**（若再加槽位就要重新算） |
| `max_slots` | **不动**（仍是 `{ x = 8 y = 1 }`，槽位数没变） |

📌 落盘：`mod/heart_of_iron/interface/countrypoliticsview.gui`（UTF-8 **无 BOM** + CRLF）；
自检 = `verify-s2.ps1` **§16d**（现场解析 `slotsize width` 与 `max_slots.x` 并算算术）。
⚠️ 改动**不进国策数据**，所以验收仍是**硬性规则 5**：启动游戏看 `日志/error.log` + 肉眼确认槽位行不溢出。

### §2.3 基底同样取 R56 版

R56 也改了 `interface/countrypoliticsview.gui`（比原版大 1,930 字节），差 4 处：

| R56 的改动 | 内容 |
| --- | --- |
| 修拼写 | `position = { x= -2 y = 1s }` → `y = 1`（**原版这里有个 `1s` 的笔误**） |
| 次要形态学 | `ideology` 的 y `8` → `600`（R56 注释：`we got subideology instead`） |
| 修容器类型 ×2 | `buttonType idea_entry_bg` → `background idea_entry_bg` |

⛔ 拿原版版当基底会把这 4 处抹掉 → 取 **R56 版**。

---

## §3 ⚠️ 待游戏内确认：军官团视图的「总司令」行

**这是本次唯一一处我没法离线定论的地方，如实记下来。**

`interface/countryofficercorpview.gui`（**原版文件，R56 没有覆盖它**）里的 `high_command_advisors`：

```
gridBoxType = {
    name = "high_command_advisors"
    position = { x = -30 y = 0 }
    size = { width = 100% height = 100% }
    slotsize = { width = 60 height = 150 }   # ← 已在用户给的 60-65 区间内
    max_slots_horizontal = 5                 # ← 已经是 5，数值上不用改
    max_slots_vertical = 1
    format = "UPPER_LEFT"
}
```

⭐ **好消息**：位宽 **60** 与上限 **5** 原版就写着 —— 所以**从 3 格加到 5 格，这两个数一个都不用动**。
（⚠️ 但注意 `army_chief_advisors` / `navy_chief_advisors` / `air_chief_advisors` / `theorist_advisors`
四个 grid **也**写着 `max_slots_horizontal = 5`，而它们各自只有 **1** 个槽 →
⇒ 这个 `5` 是**通用样板值**，**不能当作「原版保证 5 格放得下」的证据**。）

⚠️ **担心的地方**：同一行里 `theorist` 容器从 **x = 186** 起；按 `high_command` 容器的锚点推算，
5 格 × 60 = **300 px** 的横向占用**可能**压到「理论家」那一列（3 格时只占 180 px，正好留 44 px 空隙）。
⚠️ `position = { x = -8 y = -8 }` 是**负值**，负 x 在这套 GUI 里到底是「从左边数」还是「从右边数」，
**没有官方文档能定论**（原版 `.gui` 里两种用法都有）⇒ **离线推不出真实落点**。
⚠️ `GFX_advisor_theorist_entry`（527 × 71，放在 x = 11、y = 45）是这一行的**底图**；
底图上若有烘死的分组标，挪动分组就会错位（该行**没有**「总司令 / 理论家」的 `instantTextboxType`，
标只可能在这张 DDS 上）。

### ⇒ 判据 J：两个修法都列出来，等用户看一眼游戏再定

| | 甲 · 只压窄「总司令」格 | 乙 · 把「理论家」块右移 |
| --- | --- | --- |
| 做法 | `high_command_advisors` 的 `slotsize width` 60 → **~44** | `theorist` 容器 `x` 186 → **~268**，`slotsize width` 70 → **~55** |
| 效果 | 5 × 44 = 220，能塞进「理论家」左边那 224 px | 5 × 60 = 300 保持位宽，「理论家」跟到它右边 |
| 代价 | ⛔ **44 < 60**（低于用户给的参考区间）；肖像约 53 px 宽 → 相邻格**会压边** | ⛔ 擅自动了「理论家」那块（用户没要求）；⚠️ 若底图烘死了分组标 → **错位** |
| 可逆性 | 改一行 | 改两行 |

📌 **推荐 = 先不动**：因为
① 用户给的两个数（width 60-65、max_slots）**在 `high_command_advisors` 上原版就满足**；
② `countrypoliticsview.gui` 那条改动**已经**覆盖了「同一个槽位在政治面板里的显示」；
③ 这两条支线（拉狄克 / 图哈）都是**苏联专属**，而军官团视图是所有国家共用的屏 —— 动它影响面最大。
👉 **请启动游戏看一眼**：政治 → 军事参谋（看 5 格排布）· 军官团界面（看总司令行是否压到理论家）。
**挤了就按甲或乙回我一个字，我再改。**

---

## §4 影响面

| 项 | 说明 |
| --- | --- |
| 生效范围 | **全局**：`common/idea_tags/00_idea.txt` 对所有国家生效（正是用户要的「全局的」） |
| 谁多出来槽位 | **每个国家**的政治顾问 3 → 5 · 工业企业 1 → 3 · 总司令 3 → 5 |
| 空槽 | 没有人/没有设计商填的时候，槽位**空着**（这就是用户说的「加槽位空槽」） |
| 存档 | 不涉及存档结构，属于加载期数据 |
| 与其它 mod | ⚠️ 任何**同样覆盖 `00_idea.txt`** 的 mod 会与本 mod 互相整文件覆盖（R56 已经被我们合并进来处理掉了） |
| 本项目第一次覆盖原版 `.gui` | ⭐ 之前 `mod/heart_of_iron/interface/` 里**全是本项目自己的文件**（`hof_ic*.gfx` / `hof_ic_scripted_gui.gui`）；`countrypoliticsview.gui` 是**第一份原版 UI 覆盖** |

---

## §5 落地清单与校验

| 文件 | 编码 | 行尾 | 基底 | 改了哪几行 |
| --- | --- | --- | --- | --- |
| `mod/heart_of_iron/common/idea_tags/00_idea.txt` | UTF-8 **无 BOM** | **CRLF** | R56 版 | `political_advisor` +2 · `industrial_concern` +2 · `high_command` +2（各带一行 `# hof:` 注释） |
| `mod/heart_of_iron/interface/countrypoliticsview.gui` | UTF-8 **无 BOM** | **CRLF** | R56 版 | `ideas_grid`：`slotsize width` 80 → 50 · `max_slots` x 7 → 8（带一行 `# hof:` 注释） |

✅ 两个文件均已核验：**无 BOM**（脚本/UI 红线）· **CRLF** · **无裸 LF** · **无 `\r\r\n`**。

✅ 全链重跑（2026-09-20）：

| 步骤 | 结果 |
| --- | --- |
| `build/gen-hof-ic-s3.ps1` | **全部自检通过**（175 块 / 22 人驱动器） |
| `build/gen-hof-ic-focus-icons.ps1` | **174 = 108 交付 + 66 兜底** · 括号 1393/1393 |
| `build/sync-from-r56.ps1` | **成功 17 / 失败 0 / 205,698 行** |
| `build/verify-s2.ps1` | **失败项 0** |
| `build/gen-reference-index.ps1` | 213 行 |
| `build/verify-docs.ps1` | **失败项 0** |

> 🚩 本次改动**不进入**上面任何一条自检的覆盖范围（槽位与 UI 不在国策数据里）
> ⇒ **验收标准仍是硬性规则 5：启动游戏后 `日志/error.log` 不出现本次改动引入的新错误**，
> 并且**肉眼确认** §3 那两处。

---

## §6 相关文件

- `docs/10` §2.4.2（互斥矩阵，**与本改动无关**，不要顺手改）
- `AGENTS.md` 硬性规则 2（整文件覆盖）· 3（编码红线）
- `build/sync-from-r56.ps1`（同类「从 R56 取基底」的既有做法）
