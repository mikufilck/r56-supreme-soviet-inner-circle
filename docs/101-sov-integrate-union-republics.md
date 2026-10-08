# 101 · 苏联「整合加盟共和国」决议组 + 洪都拉斯挂经互会

> **本文是这一套机制的唯一权威出处。** 别处只放指针（AGENTS.md 硬性规则 10）。
> 实装日期：**2026-09-25**。安全网 = `build/verify-s2.ps1` **§18（21 项）**。

---

## §0 用户口径（原文照录）

### 第一道口径（决议组的由来）

> 「洪都拉斯需要挂载经互会，应该生效
> 然后我要给苏联加一个决议组，仿照中华民国的整合军阀
> 决议组名叫整合加盟共和国
> 当波罗的海三国是苏联的附庸且为共产主义政体时，可以点击决议，决议持续 15 天，
> 其所有科学家，没有"反布尔什维克老兵"特质的陆军和海军将领将加入苏联，同时被苏联吞并
> 当斯堪的那维亚四国和土耳其是苏联的附庸且为共产主义政体时，可以点击决议，决议持续 30 天，
> 其所有科学家，陆军和海军将领将加入苏联，同时被苏联吞并
> 当波兰是苏联的附庸且为共产主义政体时，可以点击决议，决议持续 15 天，
> 其所有科学家，没有"萨纳齐亚右派指挥官"特质的陆军和海军将领加入苏联，同时被苏联吞并
> 这个决议组在完成"宣称波罗的海"国策后可用」

### 第二道口径（同日稍后 · **改成「一国一条」** —— 本文件据此定型）

> 「**是去掉丹麦冰岛，挪威瑞典芬兰，还有是要拆出来的，
> 波罗的海也是也要拆出来三个国家，不是全部一起**」

⇒ 两处改动：

| # | 改动 | 落地 |
| --- | --- | --- |
| ① | **去掉丹麦（DEN）与冰岛（ICE）**；北欧那组 = **挪威 / 瑞典 / 芬兰**（土耳其照第一道口径保留） | 决议里**没有** `tag = DEN` / `tag = ICE` |
| ② | ⭐ **一国一条决议**「不是全部一起」 | 由原来的 **3 条**（波罗的海一条 + 北欧与土耳其一条 + 波兰一条）改成 **8 条，每条只挂 1 个 tag** |

> ⚠️ **本项目代选的一处**（判据 J，用户不在场）：第二道口径里「拆出来」只对波罗的海明确说了
> 「三个国家」，**北欧那组要不要也逐国拆**没写死；土耳其也没提。
> 本项目按「**不是全部一起**」这条原则**统一处理** ⇒ **8 条一国一条，土耳其保留**。
> 一键回退：把几条决议合回一个块（每条决议只许一个 `tag`，是 `verify-s2` §18 的硬断言）。

---

## §1 蓝本 = 原版中华民国「整合军阀」

⛔ **不臆造语法** —— 整套结构照原版 **`CHI_integrate_the_warlords`** 逐字段抄：

| 项 | 原版位置 |
| --- | --- |
| 决议本体 | `F:\Hearts of Iron IV\common\decisions\CHI_decisions.txt` **L2354** |
| 分类 | `F:\Hearts of Iron IV\common\decisions\categories\CHI_decision_categories.txt` **L31** |
| 角色转移 | `CHI_decisions.txt` **L2447-2451**（`every_unit_leader = { set_nationality = ROOT }`） |
| 吞并 | `CHI_decisions.txt` **L2927**（`annex_country = { target = FROM transfer_troops = yes }`） |
| 决议面板里 set_nationality 的另一处先例 | `common/decisions/BUL.txt` **L4115** |
| `annex_country` 另一处先例 | `BUL.txt` **L8899-9022** |

蓝本用到的字段：`target_array = subjects` · `target_root_trigger` · `target_trigger` ·
`days_remove` · `remove_effect` · `fire_only_once` · `cancel_if_not_visible` · `ai_will_do`。

---

## §2 八条决议（一国一条）

| # | 决议 id | 显示名 | 目标 `tag` | 天数 | `cost` | 将领过滤 |
| --- | --- | --- | --- | --- | --- | --- |
| ① | `hof_sov_integrate_estonia` | 整合爱沙尼亚加盟共和国 | **EST** | **15** | 100 | ⛔ 排除 `BALTIC_anti_bolshevik` |
| ② | `hof_sov_integrate_latvia` | 整合拉脱维亚加盟共和国 | **LAT** | **15** | 100 | ⛔ 排除 `BALTIC_anti_bolshevik` |
| ③ | `hof_sov_integrate_lithuania` | 整合立陶宛加盟共和国 | **LIT** | **15** | 100 | ⛔ 排除 `BALTIC_anti_bolshevik` |
| ④ | `hof_sov_integrate_norway` | 整合挪威加盟共和国 | **NOR** | **30** | 150 | ✅ 无 |
| ⑤ | `hof_sov_integrate_sweden` | 整合瑞典加盟共和国 | **SWE** | **30** | 150 | ✅ 无 |
| ⑥ | `hof_sov_integrate_finland` | 整合芬兰加盟共和国 | **FIN** | **30** | 150 | ✅ 无 |
| ⑦ | `hof_sov_integrate_turkey` | 整合土耳其加盟共和国 | **TUR** | **30** | 150 | ✅ 无 |
| ⑧ | `hof_sov_integrate_poland` | 整合波兰加盟共和国 | **POL** | **15** | 100 | ⛔ 排除 `POL_sanation_right_leader` |

⛔ **不在名单里**：**丹麦 DEN · 冰岛 ICE**（用户第二道口径明令去掉）。

八条的**共同条件**（`visible` 与 `available` 里各写一遍）：

```
FROM = {
    is_subject_of = ROOT          # 是苏联的附庸
    has_government = communism    # 且为共产主义政体
}
```

八条的**解锁条件**（决议级 `target_root_trigger` **＋** 分类级 `visible` 双重）：

```
has_completed_focus = SOV_claims_in_baltic     # 「宣称波罗的海」
```

`remove_effect`（八条同构，只有 `limit` 不同）：

```
FROM = {
    every_scientist = { set_nationality = ROOT }
    every_unit_leader = {
        include_invisible = yes
        limit = { NOT = { has_trait = <该条的特质> } }   # ④⑤⑥⑦ 没有这一行
        set_nationality = ROOT
    }
}
ROOT = { annex_country = { target = FROM  transfer_troops = yes } }
```

> 📌 **每条决议只挂一个 `tag`** —— 这正是用户要的「不是全部一起」。
> `verify-s2` §18 会断言**每个块里的 `tag = ` 恰好 1 处且等于期望值**，合回去就会红。

---

## §3 五个机制要点（都是会【静默失效】的那一类）

### §3.1 ⭐⭐ 决议与分类靠【同名顶层块】关联，不是字段
- 分类文件 `categories/hof_sov_integrate_categories.txt` 的顶层块 = `hof_sov_integrate_category = { … }`
- 决议文件 `hof_sov_integrate_decisions.txt` 的顶层块 = **同名** `hof_sov_integrate_category = { … }`
- ⛔ 写 `decision_category = …` 字段 ⇒ **静默不挂分类**，面板里看不到。
  实测原版 `common/decisions/*.txt` 里 `decision_category = ` **出现 0 次**（与 `docs/97` §2 同一发现）。
- 自检：§18b。

### §3.2 ⭐⭐ 必须【先转角色、后吞并】
`annex_country` 之后这个国家就没了，它名下的角色也会一起消失。
⇒ 顺序只能是 **`set_nationality`（两次）→ `annex_country`**。
自检：§18e 里用 `IndexOf` 比较两者的**文本顺序**，反了就 FAIL。

### §3.3 `set_nationality` = 把一个角色转到另一个国家
> 官方文档 `documentation\effects_documentation.md` → `#set_nationality`：
> *"Transfer from one country to another for the character in scope."*

- `every_scientist` / `every_unit_leader` 都给**角色作用域**，所以这两个作用域能直接接 `set_nationality`。
- `every_unit_leader` ≈ **陆军 + 海军将领**（HOI4 里空军没有 unit leader）—— 对得上用户说的「陆军和海军将领」。
- ⚠️ 科学家转过来之后会不会**自动在新国家注册**（需不需要补 `add_scientist_role`）
  —— **未实测**，见 §8。

### §3.4 `annex_country = { target = FROM  transfer_troops = yes }`
- `transfer_troops = yes` **是判断项**（用户没明说「部队」）—— 取 yes 的理由：
  「吞并」在本 mod 的语境里包含军队；原版整合军阀也是这个写法。
  ⛔ 要改成不带部队：把八处那一行删掉（一处一行，零连带）。
- 决议是 **targeted decision** ⇒ 在决议作用域里 `FROM` = 被点选的那个国家，`ROOT` = 苏联。

### §3.5 两个特质 id 是**裸 id**（没有 `trait_` 前缀）

| 中文名（用户口径） | 特质 id | 定义处 |
| --- | --- | --- |
| 反布尔什维克老兵 | **`BALTIC_anti_bolshevik`** | `F:\Hearts of Iron IV\common\unit_leader\NSB_traits.txt` **L30**（`type = all` · `trait_type = personality_trait`） |
| 萨纳齐亚右派指挥官 | **`POL_sanation_right_leader`** | 同上 **L76**（同形态） |

⭐ 触发写法有原版先例：`common/scripted_effects/POL_scripted_effects.txt` **L369**
`NOT = { has_trait = POL_sanation_right_leader }` —— 逐字同款，没有猜。
📌 全文件 `has_trait` **恰好 4 处**（EST / LAT / LIT 各 1 + POL 1），自检 §18f。

---

## §4 🚩 判据 K：显示名统一取「整合XX加盟共和国」

拆成单国后，**四个**「整合XX」的短名与原版 / R56 的**中文显示名完全相同** ⇒ 禁区：

| 拟用短名 | 占用者（**完全相同**） |
| --- | --- |
| ❌ 「整合爱沙尼亚」 | R56 决议 `baltic_integrate_estonia_r56` |
| ❌ 「整合挪威」 | R56 决议 `den_integrate_norway_r56` · R56 国策 `SWE_integrate_norway` |
| ❌ 「整合芬兰」 | R56 决议 `den_integrate_finland_r56` · R56 国策 `SWE_integrate_finland` |
| ❌ 「整合波兰」 | 原版决议 `SOV_integrate_poland`（`nsb_decisions_l_simp_chinese.yml`） |

✅ **0 命中（短名本可用）**：`整合拉脱维亚` · `整合立陶宛` · `整合瑞典` · `整合土耳其` ·
`整合丹麦` / `整合冰岛`（但两国已不在名单里）。

**采用方案 = 甲（统一长名）**：八条一律「**整合XX加盟共和国**」——

- 与上面四个占用的名字**都不完全相同**（各多出「加盟共和国」）⇒ 判据 K 允许；
- 与**分类名**「整合加盟共和国」同一构词，读起来是一组；
- 与项目已实装的波兰那条（`hof_sov_integrate_poland`）**风格一致**。

> 📌 另两处**差一两个字**的近似（判据 K 明确可用，不构成禁区）：
> 原版 `GER_demand_lithuanian_integration`「**要求**整合立陶宛」·
> 原版 `LIT_forcefully_incorporate_estonia`「**强行**整合爱沙尼亚」。

---

## §5 判断项（判据 J · 已实装，可一键回退）

| # | 项 | 取值 | 依据 / 回退 |
| --- | --- | --- | --- |
| 1 | **北欧那组的国别** | **NOR / SWE / FIN**（**不含 DEN / ICE**） | 用户第二道口径「去掉丹麦冰岛，挪威瑞典芬兰」；改 `decisions` 里的 `tag` 行 |
| 2 | **土耳其** | **保留**（单独一条，30 天） | 第一道口径「斯堪的那维亚四国**和土耳其**」；第二道口径**没提**它 ⇒ 按「不是全部一起」单独成条。要删就删 `hof_sov_integrate_turkey` 整块 + 它的两个本地化键 |
| 3 | **拆分粒度** | **一国一条 · 8 条** | 用户第二道口径「拆出来……不是全部一起」——对波罗的海是明说的，对北欧那组是本项目的**统一处理**（见 §0 末尾的代选说明） |
| 4 | `cost` | 15 天的 = **100** · 30 天的 = **150** | 用户未指定；比原版整合军阀（150 / 90 天）便宜一点，因为天数短得多 |
| 5 | `ai_will_do` | **`base = 1`** | AI 苏联会做，但权重低（不会抢着吞附庸） |
| 6 | `include_invisible = yes` | 只保留在 `every_unit_leader` | 本机 `error.log` 把 `every_scientist` 内的此字段报为 `Unknown effect-type`；已移除。科学家中未显示者是否全部转移，见 `docs/99` §59 待实测。 |
| 7 | `transfer_troops = yes` | 八条都写 | 见 §3.4 |
| 8 | 图标 | 分类 `GFX_decision_category_generic_communism` · 八条决议 `GFX_decision_generic_form_nation` | **全部是原版现成 sprite** ⇒ **零缺图风险、不需要注册 `.gfx`** |
| 9 | `visible_when_empty` | **`no`** | 没有可点的决议时收起页签；原版惯例（`00_decision_categories.txt` L629/659 · `00_formable_categories.txt` L732 · `AFG_decision_categories.txt` L6/20/34 全是 `no`） |
| 10 | `fire_only_once = yes` | 八条都写 | 被吞并的国家不复存在 ⇒ 卡片自然消失；即使日后被放出来，也已不可再点 |

> 📌 **不需要**再给每个目标设 `set_country_flag` 来隐藏卡片（第一版有，拆成单国后**已删除**）：
> 每条决议只对一个国家生效，吞并后那个国家**根本不在 `subjects` 里** ⇒ 卡片自动消失。
> `verify-s2` §18 因此不再断言 flag。

---

## §6 文件清单（3 个文件 · 本轮重建其中 2 个）

| 文件 | 编码 | 说明 |
| --- | --- | --- |
| `mod/heart_of_iron/common/decisions/categories/hof_sov_integrate_categories.txt` | UTF-8 **无 BOM** + CRLF | 分类（1 个块） |
| `mod/heart_of_iron/common/decisions/hof_sov_integrate_decisions.txt` | UTF-8 **无 BOM** + CRLF | 决议容器 + **8 条决议** |
| `mod/heart_of_iron/localisation/simp_chinese/hof_sov_integrate_l_simp_chinese.yml` | UTF-8 **带 BOM** + CRLF | **18 个键**（分类 2 + 8 条 × 2） |

⛔ **旧的两条合并式决议已整体清除**（不是注释掉）：`hof_sov_integrate_baltic` /
`hof_sov_integrate_nordic` 的决议块与本地化键**都不存在**了；自检 §18g 会查这件事。

⭐ `common/decisions/*.txt` 是**多文件并集**加载 ⇒ **不覆盖**原版 / R56 的任何决议或分类。
📌 **文案口径**：八条 `_desc` 写的是**机制说明**（条件 + 天数 + 完成后发生什么），
不引历史评价 ⇒ **不属于硬性规则 9 的适用范围**（那条管的是陈述**历史**的文本）。
📌 本 mod 的 `common/decisions/` 目录里现在有**两组**：`hof_sov_mob_*`（开战倒计时，`docs/97`）
与 `hof_sov_integrate_*`（本文）。

---

## §7 自检：`verify-s2.ps1` **§18（21 项）**

覆盖：三个文件在不在 · 编码红线（脚本无 BOM / yml 有 BOM + 首行语言头）·
**分类 ↔ 决议同名顶层块** · 未误用 `decision_category` 字段 · 分类挂 `SOV_claims_in_baltic` ·
**决议块 = 8 条** · ⭐ **每块 `tag` 恰好 1 处且等于期望值**（「不是全部一起」）·
**天数 15/30/15** · **特质过滤**（EST/LAT/LIT 各排 `BALTIC_anti_bolshevik`、POL 排
`POL_sanation_right_leader`、NOR/SWE/FIN/TUR 一个都不许有）· 结构一致
（`every_scientist` ×1 + `every_unit_leader` ×1 + `set_nationality` ×2 + `annex_country` ×1 +
`transfer_troops = yes` ×1 + `target = FROM` ×1）· **先转角色后吞并**的顺序 ·
八条都判 `SOV_claims_in_baltic` · `visible`/`available` 都判「附庸 + 共产主义」·
**全文件 `has_trait` 恰好 4 处** · **旧的两条合并式决议已清除** ·
**DEN / ICE 不在 tag 里** · 本地化 **18 键** · **8 个显示名逐个比对** · 分类显示名。

> 🚩 **本节踩过的坑（第 3 次同型）**：所有**计数 / 负向**断言必须先**剥掉注释**再跑 ——
> 决议文件头部的说明性注释里本身就写着 `has_trait` / `every_unit_leader` /
> `annex_country = { target = FROM transfer_troops = yes }` 这些字样，不剥注释会让断言
> **自己把自己判失败**。✅ 写法：`$dtNC = [regex]::Replace($dt, '(?m)#[^\n]*', '')`。

> 🚩 **本节第 4 次踩坑（新）**：**`tag = ` 的匹配不能用行首锚** —— 本文件把
> `target_trigger` 写成单行 `target_trigger = { FROM = { tag = EST } }`，
> `^\s*tag` 会**一个都抓不到**（第一跑 8 条全红）。
> ✅ 正解：`\btag\s*=\s*([A-Z]{3})\b` —— `\b` 同时排除 `original_tag` / `set_cosmetic_tag`
> （`tag` 前面是下划线，无词边界）。
> 📌 这是**本项目第 4 条「自检脚本自身的纪律」**：**写断言时先确认目标文本的【排版形态】**
> （单行 / 多行 / 缩进），别假设它跟你想的一样。

---

## §8 ⬜ 待游戏内验证（硬性规则 5）· 共 6 项

| # | 项 | 怎么看 |
| --- | --- | --- |
| ① | **分类页签是否出现** | 苏联完成「宣称波罗的海」后，决议面板里应多出「整合加盟共和国」一栏 |
| ② | **八张卡片是否各自独立** | 让某国做苏联附庸 + 转共产主义 → **只有那一国**的卡片出现（其余七张不出现） |
| ③ | **`every_scientist` 会不会报错** | ⚠️ 依赖「科学家」系统的 DLC；本写法**没有加 DLC 保护**（照 R56 `australia.txt` L3912 的先例）。启动后看 `日志/error.log` |
| ④ | **科学家转过来后在不在苏联的科学家列表里** | ⚠️ 可能需要补 `add_scientist_role`（见 §3.3）。若不在，就在 `set_nationality` 后面补一行 |
| ⑤ | **将领真的转过去了、且特质过滤生效** | 吞并后打开苏联的将领列表，看 EST/LAT/LIT（排 `BALTIC_anti_bolshevik`）与 POL（排 `POL_sanation_right_leader`） |
| ⑥ | **部队是否一并接收** | `transfer_troops = yes` 的效果；不想要就删那八行 |

---

## §9 同一轮的另一件事：洪都拉斯挂经互会

> 用户口径：「**洪都拉斯需要挂载经互会，应该生效**」

`build/attach-points.json` 的 `hon_std` **原先带 `"s5": false`**（那是 2026-09-25 早些时候为了
「只覆盖内容、不注入经互会」而加的，见 `docs/100`）⇒ **本轮把它去掉**，
洪都拉斯照常拿到 `shared_focus = hof_ma_founding`。

- ⭐ `"s5": false` 这个**机制保留**（黑名单规则：写了才跳过，将来加点不会漏注），只是**现在没有点带它**。
- `verify-s2` §13a-2 同步改成**空名单也能过**：
  `当前没有 s5:false 挂载点（机制保留备用）—— 23 个挂载点全部注入经互会通用线`。
- 实测：`sync-from-r56.ps1` ⇒「已并入 **23** 个挂载点的注入表（**0** 个带 s5:false 跳过）」；
  `honduras.txt` **L8** 出现 `shared_focus = hof_ma_founding`（L23 是它自带的
  `USC_UNIFIED_central_american_unification`，两者共存 ✅）。

---

## §10 数字（本轮）

| 项 | 前 | **后** |
| --- | --- | --- |
| 挂载点 | 23 | **23**（不变；只是 `hon_std` 从「跳过」变回「注入」） |
| 注入经互会的挂载点 | 22 | **23** |
| `sync` | 23 / 0 / 243 362 行 | **23 / 0 / 243 362 行**（不变 —— 本轮不动国策树） |
| **决议分类** | 1 | **2** |
| **决议条数** | 2 | **10**（+8：一国一条） |
| **本地化键（本组）** | 8 | **18**（分类 2 + 8 条 × 2） |
| 国策块 / 国策图标 / 互斥对数 / `NOT` 条件 | 169 / 174 / 74 / 170 | **全部不变** |
| 新增自检 | — | **`verify-s2` §18（21 项）** |

> 🚩 本轮改动**不进入**任何既有的国策自检覆盖范围（决议不是国策数据）⇒
> 验收标准仍是**硬性规则 5**：启动游戏后 `日志/error.log` 不出现本次改动引入的新错误。
