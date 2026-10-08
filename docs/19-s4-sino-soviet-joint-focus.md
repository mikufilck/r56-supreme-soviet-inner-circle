# 19 · S4 实施记录：中苏联合国策（`joint_focus` 机制）

> ⛔⛔ **本文已作废（2026-09-24）。**
>
> 用户口径（2026-09-24）：「**先取消中苏联合国策树和专属线联合国策树，占位国策也删掉**」
> ⇒ 需求 B（中苏联合）**整条取消**：
>
> - 🗑️ 删除 `common/national_focus/hof_sino_joint.txt`（5 139 B）·
>   `common/scripted_triggers/hof_sino_scripted_triggers.txt`（1 954 B）·
>   `localisation/simp_chinese/hof_sino_l_simp_chinese.yml`（1 283 B）
> - 🗑️ **那 3 个占位国策**（`hof_sino_treaty_of_alliance` / `hof_sino_joint_industry` /
>   `hof_sino_joint_defense`）随之消失 —— 它们就是用户说的「**占位国策**」
>   （本文 §3 的待办里写着「名称/效果是**占位**」「图标是通用占位」）。
> - 🚩 `build/sync-from-r56.ps1` 里的注入逻辑已摘除 —— **不摘会主菜单崩**
>   （官方 wiki：`shared_focus` 指向不存在的 id 会在主菜单崩溃）。
> - ✅ `verify-s2.ps1` **§10 已由「正向断言」改为「取消后残留检测」**（4 项负向断言）。
> - ⚠️ `attach-points.json` 的 `prc_sino` 条目**保留** —— S5 经互会通用线仍靠它挂进 PRC 那棵树。
>
> 全文见 [`docs/98`](98-sov-focus-core-overhaul.md) §1。⬇️ **以下为作废前的原文，不再维护。**

---

> 目标（`docs/10` §3 需求 B）：SOV 与 PRC 之间的联合国策。
> S4 在本项目里的定位是「**改动面最小，用来先跑通 `joint_focus` 机制**」。

---

## 1. 本轮产出

| 文件 | 内容 |
| --- | --- |
| `common/national_focus/hof_sino_joint.txt` | **新建**，根级的 3 个 `joint_focus` 定义 |
| `common/scripted_triggers/hof_sino_scripted_triggers.txt` | **新建**，`hof_sino_joint_trigger`（参与条件） |
| `localisation/simp_chinese/hof_sino_l_simp_chinese.yml` | **新建**，国策名 / 说明 / 条件提示文案 |
| `build/sync-from-r56.ps1` | 注入 `shared_focus` 到**两国树**；id 从定义文件解析 |
| `build/verify-s2.ps1` | 新增**第 10 节**：联合国策交叉引用检查 |

### 三个国策（链条）

| # | id | 名称 | 位置（基准 / SOV 偏移） |
| --- | --- | --- | --- |
| 1 | `hof_sino_treaty_of_alliance` | 中苏友好同盟互助条约 | `(2,23)` / `(58,23)` |
| 2 | `hof_sino_joint_industry` | 联合工业建设 | `(2,25)` / `(58,25)` |
| 3 | `hof_sino_joint_defense` | 联合防务体系 | `(2,27)` / `(58,27)` |

> ⚠️ **内容是「机制验证版」**：史实条目与数值待用户查证后替换
> （`docs/10` §3 原定的"国策数量待用户查史实后确定"仍未关闭）。

---

## 2. ⚠️ 一处必须纠正的旧记录

`docs/10` §3 写的改动文件是 `china_communist.txt`（7,591 行）。
**实际生效的是 `china_communist_sea.txt` / 树 `china_communist_focus_sea`** ——
NCNS 已装，sea 树在 MTTH 评分里以 1000 分胜出。
这一点 `build/attach-points.json` 的 `prc_sino` 条目里早就标注过，
但需求文档没同步。**以 `attach-points.json` 为准。**

实测该树范围：**X −6..64 / Y 0..21**（203 个国策）。

---

## 3. 查实的 `joint_focus` 机制（与原版依据）

全部来自原版实测，非推测。勘查脚本 `docs/reference/tools/scan-joint-focus.ps1`，
报告 `docs/reference/reports/joint-focus-report.txt`。

| 结论 | 依据 |
| --- | --- |
| 定义写**文件根级**，与 `focus_tree = { }` 平级 | `habsburg_joint.txt`、`ncns_ma_clique_joint_branch.txt` |
| 引用写**树内**，与 `focus = { }` 平级：`shared_focus = <id>` | `china_communist.txt` L66 |
| **没有 `common/joint_focuses/` 目录** | 实测不存在 |
| **`joint_focus` 不能用 `prerequisite`** | `habsburg_joint.txt` 里那两行是**注释掉**的 |
| 链条改用 `available = { has_completed_focus = <上一个> }` | 本项目采用（`has_completed_focus` 在该文件 `offset` 里被官方使用） |
| 奖励分三档：`completion_reward` / `_joint_originator` / `_joint_member` | 同上文件 L122–134 |
| 摆位：`x`/`y` 是基准，各国用 `offset = { x y trigger }` 错开 | 同上文件 L29–89 |
| `offset` 的判据官方惯用 `has_focus_tree = <树id>` | 同上文件 L34 |
| 同阵营 `is_in_faction_with = <TAG>`；领袖 `is_faction_leader = yes` | 官方各自大量使用 |
| 条件可封成 scripted_trigger 供双方共用 | `NORDIC_basic_joint_trigger`、`HABSBURG_joint_trigger` |
| 可用 `custom_trigger_tooltip` 给条件挂自定义文案 | `NORDIC_basic_joint_trigger` |

### 参与条件（`hof_sino_joint_trigger`）

逐国求值，所以 SOV 与 PRC **共用同一个触发器**即可互通
（官方的 `HABSBURG_joint_trigger` 正是这种对称写法）：

```text
hof_sino_joint_trigger = {
    custom_trigger_tooltip = {
        tooltip = hof_sino_joint_trigger_tt
        is_in_faction = yes                     # 自己在阵营内
        has_government = communism              # 自己是共产主义
        OR = { tag = SOV  tag = PRC }           # 自己只能是 SOV/PRC
        any_allied_country = {                  # 另一方同阵营、也共产、也是 SOV/PRC
            OR = { tag = SOV  tag = PRC }
            has_government = communism
        }
        OR = {                                  # 至少一方是阵营领袖
            is_faction_leader = yes
            any_allied_country = { OR = { tag = SOV  tag = PRC }  is_faction_leader = yes }
        }
    }
}
```

---

## 4. 工程上的一条原则：id 不在两处维护

`shared_focus` 要写进**两棵树**，如果同步脚本里手抄一遍 id，
改了定义忘了脚本 → 国策直接消失，而且**游戏不报错**。

所以 `sync-from-r56.ps1` 是**从 `hof_sino_joint.txt` 里正则解析出 id**，
再生成注入行的：

```text
中苏联合国策：解析到 3 个 joint_focus id（hof_sino_treaty_of_alliance, ...）
```

找不到定义文件或解析不出 id 会**直接抛错中止**，不静默跳过。
（与 S3 的花名册单一数据源是同一个思路。）

---

## 5. 校验（`verify-s2.ps1` 第 10 节，共 8 项）

| 检查 | 抓什么 |
| --- | --- |
| 根级定义 | 文件里不该出现 `focus_tree`（写错层级） |
| id 解析 | 定义是否真的存在 |
| **两国引用** | 每个 id 必须被 SOV 与 PRC **两棵树都** `shared_focus` 引用 |
| 国策名/说明键 | 缺了牌子上直接显示 id 原文 |
| `joint_trigger` 定义 | 引用了未定义的触发器 |
| 提示文案键 | `custom_trigger_tooltip` 的文案缺失 |

> 最新一次运行：**失败项 0**（同步 17/17 挂载点、205,698 行）。

---

## 6. 遗留项

### 6.1 需要实测才能定的

- [ ] **`cancel_if_invalid` / `continue_if_invalid` 的确切语义**
      （官方范例是 `yes` / `no`，含义未查实，本轮**没有使用**这两个字段）
- [ ] **脱离阵营后，已完成的联合国策是否失效/取消**（`docs/10` §7.2 Q30）
- [ ] 三个国策在**两国树里的实际位置**是否落在空处
      （按实测取 y≥23 的树下方，但**未目视确认**，与 S3 入口国策同理）
- [ ] 启动游戏后 `error.log` 无本次改动引入的新错误（**验收标准**）

### 6.2 已知未做

- [ ] **内容是机制验证版**：3 个国策的名称/效果是占位，待用户查史实后定稿
- [ ] **图标是通用占位**（`GFX_goal_generic_alliance` /
      `GFX_goal_generic_construct_civilian` / `GFX_goal_generic_major_alliance`），
      未做专属图标
- [ ] 未做 `offset` 的多国分支（当前只区分 SOV 与 PRC 两个）
