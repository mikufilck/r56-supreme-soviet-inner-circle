# docs/100 · 「非经互会挂载点」机制 + 洪都拉斯「向北进攻」改造

> 用户口径（2026-09-25）：「**洪都拉斯的国策进行修改 —— 向北进攻效果增加除了尤卡坦和
> 恰帕斯之外的所有墨西哥领土的核心**」

本文记录**两件事**：① 本轮新加的一个机制（可以只覆盖某国的树、**不**注入经互会通用线），
② 洪都拉斯那条国策的具体改造。

---

## 1. 🆕 新机制：`"s5": false` 挂载点

### 1.1 为什么需要它

在此之前，`build/attach-points.json` 里的挂载点**只有一个用途** —— 「让 S5 经互会通用线
能挂进这棵树」。同步脚本 `build/sync-from-r56.ps1` 的实现是：

```powershell
foreach ($p in $selected) {            # selected = phase <= MaxPhase 的全部挂载点
    $InjectMap[$p.id] += $hofMaInjectLines      # ← 每一棵都注入 shared_focus = hof_ma_founding
}
```

⇒ 想改**其它国家**（不在经互会名单里）的国策树时，就没法用它 —— 一旦把洪都拉斯加进清单，
它就会**莫名拿到一整条经互会通用线**。

### 1.2 做法

给挂载点加一个字段：

```json
{ "id": "hon_std", "tag": "HON", "phase": 1, "s5": false, ... }
```

两处同步生效（**同源规则**）：

| 文件 | 规则 |
| --- | --- |
| `build/sync-from-r56.ps1` | 注入循环里 `if ($p.s5 -eq $false) { continue }` ⇒ 不注 S5；仍照常做「整文件覆盖 + `$FocusPatchMap` 补丁」 |
| `build/verify-s2.ps1` §13a | `$ap1` 只取 `s5 -ne $false` 的点做「必须引用头节点」断言；另加 **§13a-2**：`s5:false` 的点**必须没有**引用头节点 |

⭐ **为什么用黑名单（写了才跳过）而不是白名单（写了才注入）**：
将来往清单里加新的经互会国时，**不会因为忘改名单而漏注 S5**。
⚠️ `$p.s5` 在 JSON 里没写时是 `$null`，而 `$null -eq $false` 为 `$False` ⇒ 照旧注入 ✅。

### 1.3 附带的正面效果

`attach-points.json` 从「S5 名单」升级成「**同步脚本要覆盖 + 打补丁的树**的全集」——
以后要给任何国家改国策效果，都是「往清单加一条（带 `s5: false`）+ 在 `$FocusPatchMap`
加一层」两步，不需要再动同步脚本的骨架。

---

## 2. 洪都拉斯「向北进攻」`HON_liberate_mexico_again`

### 2.1 定位

| 项 | 值 |
| --- | --- |
| 中文显示名 | **「向北进攻」**（⭐ 靠 `docs/reference/reports/focus-names-catalog.txt` 反查出来的：`HON_liberate_mexico_again<TAB>向北进攻<TAB>R56/common/national_focus/honduras.txt`） |
| 源文件 | R56 `common/national_focus/honduras.txt`（127 152 B） |
| 树 id | **`hon_focus`**（⚠️ 洪都拉斯**没有** `focus_tree_selection` 规则 ⇒ R56 那棵直接生效，无需备选树） |
| 挂载点 | **`hon_std`**（⭐ 本项目**第一个**「只为改内容而覆盖」的挂载点） |
| 原效果 | **只有** `create_wargoal = { type = puppet_wargoal_focus target = MEX }`（即：只给一个傀儡宣战理由，**没有任何领土效果**） |

### 2.2 州表怎么算出来的

「墨西哥全境」= R56 里 **`add_core_of = MEX` 且 `owner = MEX`** 的全部核心州。

⚠️ 归并规则（本项目铁律）：读 `history/states/*.txt` 时**按【州 id】归并、R56 整体覆盖原版**
—— 按文件名归并会把同号的两个 mod 的州混在一起（`docs/98` §6.3 踩过）。

**MEX owner ∩ core = 17 州**：

| 给核心（15） | 不给（2） |
| --- | --- |
| 277 墨西哥城 · 476 瓦哈卡 · 477 韦拉克鲁斯 · 478 哈利斯科 · 479 塔毛利帕斯 · 480 科阿韦拉 · 481 锡那罗亚 · 482 奇瓦瓦 · 483 索诺拉 · 484 下加利福尼亚 · 485 格雷罗 · 929 杜兰戈 · 930 萨卡特卡斯 · 931 圣路易斯波托西 · 932 普埃布拉 | **474 尤卡坦** · **475 恰帕斯** |

⇒ 用户明确排除的 **尤卡坦 = 474**、**恰帕斯 = 475**，两者名字逐字对得上本地化
（`state_names_l_simp_chinese.yml` 的 `STATE_474 = 尤卡坦` / `STATE_475 = 恰帕斯`）✅

### 2.3 落地写法

`$FocusPatchMap` 新开一层（插在 `completion_reward = {` 之后，**纯追加** ⇒ 原有的
`create_wargoal` 一个字不动、零回归）：

```hlt
completion_reward = {
    # hof:focus-begin HON_liberate_mexico_again
    # hof: 墨西哥全境核心 · 除尤卡坦 474 / 恰帕斯 475 —— 共 15 州
    add_state_core = 277
    add_state_core = 476
    ...（共 15 条）
    # hof:focus-end HON_liberate_mexico_again
    ROOT = { create_wargoal = { type = puppet_wargoal_focus target = MEX expire = 0 } }
}
```

### 2.4 自检（`verify-s2` §17 新增 3 项）

| 断言 | 内容 |
| --- | --- |
| §17a | `$FocusPatchMap` 分层键 = `sov_core` / `ast_std` / `prc_sino` / **`hon_std`** |
| §17b | **15 处补丁哨兵**全部落地（含 `# hof:focus-begin HON_liberate_mexico_again`） |
| §17c（新） | `honduras.txt` 里 **15 个墨西哥州的核心各命中 1 次** |
| §17c（新，负向） | **尤卡坦 474 / 恰帕斯 475 的 `add_state_core` 必须命中 0 次** |
| §13a | 22 个挂载点引用头节点 + **1 个 `s5:false` 挂载点（`hon_std`）未引用** |

---

## 3. 📌 数字变化（回写时别改错）

| 项 | 前 | **后** |
| --- | --- | --- |
| 挂载点总数 | **22** | **23**（新增 `hon_std`） |
| 其中注入 S5 的 | 22 | **22 个（不变 —— `hon_std` 带 `s5:false`）** |
| `sync` 成功/失败/行数 | 22 / 0 / 236 948 | **23 / 0 / 243 362**（+6 414 行 = honduras.txt） |
| `$FocusPatchMap` 分层 | 3（sov_core / ast_std / prc_sino） | **4**（+ `hon_std`） |
| 国策块 / 图标 / 互斥矩阵 | 169 / 174 / 74 对 170 条 | **全部不变**（本轮不加国策） |

---

## 4. ⬜ 待游戏内验证（硬性规则 5）

1. **洪都拉斯那棵树整体可加载** —— `honduras.txt` 是本项目第一次收录的「非经互会」树，
   且它**自带** `shared_focus = USC_UNIFIED_central_american_unification`（R56 的中美洲
   统一共享线）⇒ 启动后确认 `日志/error.log` 没有 missing shared focus / 重复定义报错。
2. **洪都拉斯没有拿到经互会通用线**（面板里不该出现「莫洛托夫计划」）。
3. 完成「向北进攻」后，墨西哥 15 州确实变核心，**尤卡坦与恰帕斯仍是普通州**。
4. ⚠️ **与 S5 带子的潜在冲突**：`hon_focus` 本身没被注入，**但它引用了 R56 的
   `USC_UNIFIED_central_american_unification`** —— 若那条共享线在别的国家那边也有注入，
   留意是否出现重复锚点（`verify-s2` §13 已覆盖「同树重复 shared_focus」）。
