# R7 · 苏联默认加载哪棵树（✅ 已定案）

> 状态：**已解决（2026-09-13，用户实测确认）**。
> 结论：**默认加载决不后退（NSB）DLC 国策树，即 `soviet.txt` 里的 `soviet_focus`。**
> 影响面：需求 A（核心圈）的挂载点**确认为唯一**，`soviet.txt` / `soviet_focus`，无障碍。

## 0. 定案

用户实测：**苏联默认加载的是 NSB 树**。

- NSB 树 = `soviet_focus`，在 R56 里由 `soviet.txt` 提供（R56 已整文件覆写该路径）→ **我们的挂载点就是它**
- 老树（`soviet_focus_old` / `soviet_old.txt`）**不再考虑** —— 用户决定：「苏联不会有人游玩老树的」

**由此产生的两个结果**

1. `mod/heart_of_iron/common/national_focus/soviet.txt` 就是最终挂载宿主，core 圈与中苏联合国策都挂在它上面。
2. 老树缺少 `SOV_the_supreme_soviet`（186 focus vs 新树 449），但因不再支持老树，这一点不再构成问题。

> 下文保留静态分析过程与风险推演，**仅作记录**。当时推导出"默认会走老树"是因为 `oldsov_on_actions.txt` 里的 `NOT = { A B }` 写法；实测结果表明该推导不成立（可能 `on_startup` 阶段 `has_game_rule` 尚未就绪，导致整个 `limit` 求值失败、分支未执行）。**这条经验值得记住：静态分析遇到逻辑反转的写法时，以实测为准。**

---

## 1. 问题

需求 A 的触发点是「完成 `SOV_the_supreme_soviet`（最高苏维埃）国策后显示核心圈窗口」。

但苏联有 **3 棵树**，且 R56 用 `on_actions` 做了切换：

| 树 id | 文件 | focus 数 | 含 `SOV_the_supreme_soviet`？ |
| --- | --- | --- | --- |
| `soviet_focus` | `soviet.txt`（29,564 行） | **449** | ✅ 有（2 处） |
| `soviet_focus_old` | `soviet_old.txt`（13,942 行） | **186** | ❌ **没有**（0 处） |
| `soviet_civil_war_focus` | `r56_soviet_civil_war.txt`（1,734 行） | — | ❌ 没有 |

**老树里根本没有「最高苏维埃」这个国策。** 如果默认加载的是老树，核心圈无从触发。

---

## 2. 静态分析结果

`common/on_actions/oldsov_on_actions.txt`（全文仅 80 行）的主判定：

```
if = { limit = { NOT = {
        has_game_rule = { rule = SOV_focus_tree_selection option = STANDARD_TREE }
        has_start_date > 1945.01.01 } }
    set_global_flag = sov_old_focus_tree
    SOV = { load_focus_tree = soviet_focus_old  ... } }
```

`NOT = { A  B }` 在 HOI4 里等价于 `NOT(A AND B)`。逐项求值：

| 项 | 1936 年剧本下的值 | 依据 |
| --- | --- | --- |
| A = `has_game_rule = { ... option = STANDARD_TREE }` | 真（该选项是规则默认值） | `00_game_rules.txt` 里 `SOV_focus_tree_selection` 的 `default = { name = STANDARD_TREE }` |
| B = `has_start_date > 1945.01.01` | **假** | 原版全库 330 处 `has_start_date` **全部**用 `<`（形如 `has_start_date < 1936.01.02`，用于判定"是否 1936 剧本"）；R56 全库仅这一处用 `>` |
| `NOT(A AND B)` | **真** | NOT(真 AND 假) = NOT(假) = 真 |

**⇒ 该分支在 1936 开局下必然执行**（A 取真或假都不影响：只要 B 为假，`A AND B` 就是假）。

**⇒ 结论：无论玩家选哪个选项，苏联都会加载老树 `soviet_focus_old`。**

注释 `#for one of my other submods` 表明作者本意大概是「玩家没选标准树 **且** 开局不晚于 1945」时才用老树，即应写成两个独立的 `NOT`。当前写法把两个条件一起包进了 `NOT`，导致逻辑反转。

### 支持该结论的旁证

- `error.log`（本日 17:53，383 KB）中 `has_start_date` **命中 0** → 该 `>` 写法**未触发解析错误**，语法被引擎接受，因此按真值参与求值。
- `sov_old_focus_tree` 这个 flag 在 R56 里被 **29 个文件**引用（ideas / decisions / ai_strategy_plans / events 等），说明作者确实围绕"老树生效"做了大量配套。

### 反对该结论的疑点（因此仍标未决）

- 用户自述见过/关注「最高苏维埃」这个国策，暗示实际游戏里加载的可能是**新树**。
- 存在一种可能：`on_startup` 阶段游戏规则或 `has_start_date` 尚未就绪，导致整个 `limit` 求值失败、分支不执行。

---

## 3. 实测方法（S2 阶段做，或用户手工确认）

任选其一：

1. **开一局苏联，数国策树规模** —— 老树 186 个 focus，新树 449 个。差距肉眼可见（新树明显更长、更密）。
2. **在树里搜「最高苏维埃」** —— 有 = 新树；没有 = 老树。
3. **看 flag** —— 控制台 `sov_old_focus_tree` 是否被设置。
4. **`-debug` 启动后查 `logs/error.log`** 里有无与 `soviet_focus_old` 相关的痕迹。

---

## 4. 三种可能的处置

| 情形 | 处置 |
| --- | --- |
| **默认确实走老树**（静态分析成立） |  nossos mod 需要**接管树选择**：在自己的 `on_actions` 里加 `on_startup`，把 SOV 显式 `load_focus_tree = soviet_focus`。这既修复了 R56 的缺陷，也让核心圈有处可挂。**但这是改玩法，需用户拍板。** |
| **默认走新树**（疑点成立） | 一切照原计划。`soviet.txt` 是唯一挂载点。 |
| **玩家可能主动选 OLD_TREE** | 若用户希望"选老树也能玩核心圈"，则须在 `soviet_old.txt` 里**另加一套入口**（老树没有 NSB 的前置链，等于要移植内容，成本高，建议不做，改为在文档里声明限制）。 |

---

## 5. 对 S1 的影响

**不阻塞。** 挂载点清单是数据驱动的，SOV 部分先按「新树 `soviet.txt`」建即可；老树是否加入清单，等 R7 定案。

---

## 6. 用户决定（2026-09-13）

> 「苏联不会有人游玩老树的，不考虑老树」

**含义**：不需要在 `soviet_old.txt` 里做核心圈 → 上面「三种处置」中的第三种（老树另加一套入口）**排除**。

**⚠️ 但这个决定不能解除 R7 的风险。** 它只说明「不该支持老树」，而 R7 问的是「**引擎实际加载的是不是老树**」。如果静态分析成立（R56 那处 `NOT` 写法导致老树分支默认执行），那么我们的核心圈挂在 `soviet.txt` 上**照样永远不可见** —— 因为玩家根本没加载那棵树。

**因此 R7 仍是需求 A 的前置阻塞项，必须实测。** 实测前不建议开工核心圈的国策部分（窗口部分不受影响，S2 可以先做）。
