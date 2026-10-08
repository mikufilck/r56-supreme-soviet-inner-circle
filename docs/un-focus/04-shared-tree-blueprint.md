# 04 · 共享／联合同策树的**蓝本解剖**（R56 萨达巴德条约）

> 用户 2026-09-20 口径：「**R56 阿富汗有一个什么条约的联合国策树，确定有做共享，
> 且我下一个要做的共享就是仿造那个**」
> ⇒ 本文就是那份「仿造对象」的**逐块解剖**，用于 **S6 15 国国别分支**及之后的每一棵共享树。

---

## §1 它是哪一个

| 项 | 值 |
| --- | --- |
| 主题 | **萨达巴德条约**（Saadabad Pact，1937-07-08；土耳其 · 伊朗 · 伊拉克 · **阿富汗**） |
| 文件 | `common/national_focus/goe_shared_saadabad_branch.txt`（**R56**） |
| 规模 | 1398 行 · 28,917 字符 · **18 个块** |
| 文件内有没有 `focus_tree = { }` | ⛔ **没有** —— 18 个块**全部是根级定义** |
| 块的类型 | ⭐⭐ **18 个全部是 `joint_focus`** —— **连头节点也是 `joint_focus`，不是 `shared_focus`** |
| 挂载方式 | **7 棵宿主树**各写一行 `shared_focus = SSB_the_saadabad_pact` |

挂载它的 7 棵树（同一份定义、7 个宿主）：

```
afghanistan.txt      iraq.txt       persia.txt      r56_afghanistan.txt
r56_iraq.txt         r56_turkey.txt  turkey.txt
```

> ⭐ **「块是 `joint_focus`」与「宿主写 `shared_focus = <id>`」是两件事** ——
> 宿主那一行只是**引用 id**，与定义那边用的是 `shared_focus` 还是 `joint_focus` **无关**。
> 本项目 S5 目前把头定义成 `shared_focus`，R56 这边用的是 `joint_focus`。
> 📌 **差别是实质的**：`shared_focus` **不支持** `completion_reward_joint_originator` / `_member`
> （本项目 S5 实测被日志抓出来，见 `docs/99` §47.13）；`joint_focus` **支持**。

---

## §2 逐块解剖（实测）

### §2.1 头节点 = 唯一带 `offset` 的块

```
joint_focus = {
        id = SSB_the_saadabad_pact
        icon = GFX_focus_TUR_treaty_of_saadabad

        x = 0
        y = 0

        offset = { x = 70 y = 0  trigger = { tag = IRQ  NOT = { … } } }
        offset = { x = 44 y = 0  trigger = { tag = IRQ  AND = { … }  has_game_rule = { … HIDE } } }
        offset = { x = 64 y = 0  trigger = { tag = IRQ  AND = { … }  has_game_rule = { … HIDE } } }
        offset = { x = 61 y = 0  trigger = { tag = AFG  has_focus_tree = afghanistan_tree      } }
        offset = { x = 23 y = 6  trigger = { tag = AFG  has_focus_tree = r56_afghanistan_focus } }
        offset = { x = 68 y = 0  … }
        offset = { x = -69 y = 0 … }
        offset = { x = -51 y = 7 … }
        offset = { x = 38 y = 0  … }
        offset = { x = 0   y = 8 … }
        …
}
```

| 要点 | 实测 |
| --- | --- |
| `offset` 条数 | **10 条，全部在【头】上**（其余 17 个块**一条都没有**） |
| 判据主体 | ⭐ **`tag = <国>`**（`AFG` / `IRQ` / `PER` / `TUR`），**不是**只用 `has_focus_tree` |
| 同一国多棵树 | ⭐⭐ **`tag = AFG` ＋ `has_focus_tree = afghanistan_tree` / `= r56_afghanistan_focus`** —— 靠 `has_focus_tree` 区分 |
| 同一国多条 offset | 用**互斥条件**（`NOT = { … }` / `has_game_rule = obsolete_focus_branches_visibility`）保证 **只命中一条**（IRQ 那三条就是） |
| offset 的 `y` | 允许**非 0**（实测用到 `y = 6 / 7 / 8`）—— 说明落点是为了**卡进宿主树的一个空位**，不是一律回到 y = 0 |

> 📌 **`tag` 与 `has_focus_tree` 的分工**：
> `tag` 管「**哪个国家**」；`has_focus_tree` 管「**这个国家当前用哪棵树**」。
> 两者都要写全 —— 只写 `has_focus_tree` 会漏掉「同一棵树被多个国家用」，
> 只写 `tag` 会漏掉「同一国有两棵树」。

### §2.2 子节点：**零 offset，纯相对串链**

| 块 | x（相对父） | y（相对父） | `relative_position_id` |
| --- | --- | --- | --- |
| `SSB_military_cooperation` | −1 | 1 | `SSB_the_saadabad_pact` |
| `SSB_economic_cooperation` | +1 | 1 | `SSB_the_saadabad_pact` |
| `SSB_baghlan_sugar_factory_branches` | +2 | 1 | `SSB_economic_cooperation` |
| `SSB_expand_road_and_rail_connections` | 0 | 1 | `SSB_economic_cooperation` |
| `SSB_integration_of_our_infrastructure` | 0 | 1 | `SSB_expand_road_and_rail_connections` |
| `SSB_berlin_baghdad_railway_into_iran_afghanistan` | +3 | 1 | `SSB_expand_road_and_rail_connections` |
| `SSB_joint_military_exercises` | 0 | 2 | `SSB_military_cooperation` |
| `SSB_coordinate_military_production` | −3 | 1 | `SSB_military_cooperation` |
| … | … | … | … |
| `SSB_combined_arms` | −1 | 7 | `SSB_the_saadabad_pact` |
| `SSB_saadabad_research_cooperation` | +1 | 7 | `SSB_the_saadabad_pact` |

| 要点 | 实测 |
| --- | --- |
| `relative_position_id` | **17 处**（18 块减掉头）—— ⭐ **每个子节点都挂**，链到**上链父节点** |
| delta 范围 | **x ∈ [−3, +4] · y ∈ [1, 7]** —— 全部是**小增量** |
| 子节点的 `offset` | ⛔ **0 条** |
| 子节点能不能跳级 | ✅ 能 —— `SSB_combined_arms` 与 `SSB_saadabad_research_cooperation` 的父是**头本头**（`y` 直接 +7） |

⇒ ⭐⭐ **摆位模型一句话**：**头写 `(0,0)` + 若干条「按国分」的 `offset`；其余全部靠
`relative_position_id` 相对串链、小增量、零 offset** —— 头一动，整棵带子跟着动。

---

## §3 五份现成写法的横向比对

| 蓝本 | 块数 | 头 | 子节点 | `offset` |
| --- | --- | --- | --- | --- |
| **原版 `nordic_shared.txt`** | 52 | `shared_focus` · (40,15) | `relative_position_id` 链**父节点**，x ∈ [−6,+7] y ∈ [0,3] | **22 条，全在头上** |
| **R56 `baltic_shared.txt`** | 60 | `shared_focus` · (10,0) + 空 `trigger` 的 offset | 59 处相对链，小增量 | **只有 2 条** |
| **R56 `china_shared.txt`** | 65 | `shared_focus` · (40,0) | 相对链，x 到 +40 | **只有 3 条** |
| **R56 `r56_india_shared.txt`** | 101 | `shared_focus` · (47,0) | 相对链，x 到 +47 | 16 条 |
| ⭐⭐ **R56 `goe_shared_saadabad_branch.txt`** | **18** | **`joint_focus`** · (0,0) | **17 处相对链**，x ∈ [−3,+4] y ∈ [1,7] | **10 条，全在头上；判据 `tag` + `has_focus_tree`** |
| **本项目 S4 `hof_sino_joint.txt`** | 3 | `joint_focus` | — | **每个节点各一条**（绝对 x/y + 自带 offset） |
| **本项目 S5（现行 v6）** | 60 | `shared_focus` · (0,24) | **零相对链**（绝对格位） | **1260 条**（60 块 × 21 宿主） |

### §3.1 ⭐⭐ 结论：**R56 四棵树 + 原版北欧，五份全部是同一个模型**

> **头挂 offset（按国分）＋ 子节点 `relative_position_id` 相对串链。**
> 只有**本项目 S4**是另一种（3 个块、每块自带 offset）。

⇒ ⚠️ **本项目 S5 现行 v6 是【偏离蓝本】的那一个**（绝对格位 + 每节点 21 条 offset，共 1260 条）。
它**不是错的**（S4 已验证能渲染），但**与将来要仿造的萨达巴德式不一致**。

---

## §4 ✅ 已结案（2026-09-20 第十轮）：S5 走了**第四案**

> 用户口径：「**会不会是国策窗口宽度不够呢**，我看了一下**阿富汗的经互会是正常的，有些国家的就会重叠**。
> 查一下这个问题，**如果是的话那就把这个国策丢到下面去**」

#### 查出来的真因：**不是窗口宽度，是旧的 MaxX 表测错了**

逐格（brace-match）实测 21 棵树后：`french_focus` 表里 20 / **实测 67**、`saudi_focus` 6 / **11**、
`polish_focus` 46 / **54** ⇒ 这三棵树的带子被 offset **送进了树身里**；
而 ⭐ **`r56_afghanistan_focus` 旧表 87 = 实测 87（唯一完全对上的）⇒ 这就是「阿富汗正常」的原因**。
⚠️ `scan-mutual-tree-bbox.ps1` 把 focus 块**内部**的 `offset = { x = … }` 也算进了包围盒 —— 旧报告已加**作废警告**，
新报告 = `docs/reference/reports/mutual-tree-bbox-report-v2-celllevel.txt`。

#### 采用的第四案 = **不用任何测量**

| 项 | v7 定案 |
| --- | --- |
| 头 | `shared_focus` · `x = 0` · `y = 24` |
| 子节点 | `x = col` · `y = 24 + row` · ⛔ 无 offset · ⛔ 无 `relative_position_id` |
| offset 总数 | **0**（连萨达巴德式的「21 条」也不写） |
| 带子落点 | **21 棵树全部相同**：`x ∈ [−21,+21] · y ∈ [24,30]` |
| 安全性 | ⭐ **21 棵树真实 Y 最大 = 11** ⇒ 最少空出 13 行，**结构上必然为空** |
| 代价 | ⚠️ 要看带子得**往下滚**（用户已接受） |

> ⚠️ **与 §3.1 的关系**：萨达巴德那种「头挂 offset + 子节点相对串链」仍然是**将来做共享树的首选写法**
> （`§5 可抄清单` 照抄它即可）；S5 只是**因为 21 个宿主的空位没法可靠地量出来**才走「放下方」。
> 📌 如果将来某棵共享树**宿主少（≤ 5 个）且宿主树有空位**，就按萨达巴德那套写；否则一律放树下方。

## §5 给「下一棵共享树」的可抄清单

1. **文件**：`common/national_focus/hof_<主题>_shared.txt`（UTF-8 **无 BOM** + CRLF）。
2. **块的类型**：**全部用 `joint_focus`**（连头也是）—— 这样头也能用 `completion_reward_joint_originator` / `_member`。
3. **头**：`x = 0  y = 24`（保险基准），**唯一带 `offset` 的块**。
4. **offset 判据**：**`has_focus_tree = <宿主树 id>`**（本项目挂载点表 `build/attach-points.json` 里那 21 棵树）
   ＋ 需要区分同一国多棵树时再叠 `tag`。
   ⚠️ **每个宿主的 offset 都要写全**，且触发条件**互斥**（同一时刻只命中一条）。
5. **子节点**：**零 offset**，全部 `relative_position_id = 上链父节点`，**小增量**。
6. **宿主**：在每棵宿主树里写一行 `shared_focus = <头 id>`（由 `sync-from-r56.ps1` 注入）。
7. **自检**（照 `docs/99` §47.13 的教训）：
   - 结构性文件的外层逐个核：`ideas` 要 `ideas = { country = { … } }`、
     `dynamic_modifiers` **不要**外层 wrapper、`shared_focus` 没有 `_joint_*` 奖励键。
   - **启动后第一件事是读 `日志/error.log`**，不要靠坐标「自洽」推断引擎语义。

---

## 相关

- S5 设计：`docs/un-focus/01-s5-mutual-aid-common-lines.md`（§2.5 = 摆位定案与四次返工）
- S5 数值：`docs/un-focus/02-s5-values.md`
- S5 出图：`docs/un-focus/03-s5-icon-prompts.md`
- 摆位与结构性错误的完整记录：`docs/99-todo-verify.md` §47.11 / §47.12 / §47.13
