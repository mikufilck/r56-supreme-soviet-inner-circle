# 核心圈人物立绘登记表（**唯一权威出处**）

> **用途**：查「某人有没有立绘、在哪、还缺什么」时**只看这张表**，不要重新扫盘。
> 重新扫盘很慢（5000+ 大图 + 8600+ 小图 + 39000+ sprite），而且历史上因为
> 漏扫目录 / 匹配写错，**误判过三次**。
>
> 需要刷新时跑一次工具即可（幂等）：
> ```powershell
> powershell -NoProfile -ExecutionPolicy Bypass -File docs\reference\tools\scan-portrait-registry.ps1 `
>   | Out-File -LiteralPath docs\reference\reports\portrait-registry.txt -Encoding utf8
> ```
> 原始报告：`docs/reference/reports/portrait-registry.txt`
> 最后核对：**2026-09-15**

---

## 🆔 角色对象：他们本来就是游戏内的真实角色（2026-09-15 更正）

**别再说「我们没有角色对象」** —— 7 个席位里 **6 人原版就有角色对象**，
定义在 `common/characters/SOV.txt`（原版与 R56 各一份）。角色 id = `SOV_` + 本表用的 `Key`。

| 角色 id | 原版行号 | R56 行号 | 名字 loc（官方中文，与我们自己写的**逐字一致**） |
| --- | --- | --- | --- |
| `SOV_lev_trotsky` | L2619 | L4414 | 「列夫·托洛茨基」 |
| `SOV_nikolay_bukharin` | L3020 | L4880 | 「尼古拉·布哈林」 |
| `SOV_aleksey_rykov` | L3082 | L4944 | 「阿列克谢·李可夫」 |
| `SOV_grigory_zinovyev` | L3240 | L5121 | 「格里戈里·季诺维也夫」 |
| `SOV_lev_kamenev` | L3306 | L5189 | 「列夫·加米涅夫」 |
| `SOV_ivan_smirnov` | L2705 | L4492 | 「伊万·斯米尔诺夫」 |
| `SOV_pyotr_smirnov` | L1696 | L1992 | 「彼得·斯米尔诺夫」 |
| ⛔ `SOV_leonid_serebryakov` | **无** | **无** | **两处 `common/characters` 搜 `serebr*` 零命中** |

**含义**：

1. 他们的**名字 loc 键已经存在**且是官方中文 → 我们自己那份 `hof_ic_name_<key>` 属重复，
   但**保留**（不依赖官方翻译，也不受官方改词影响）。
2. 德国的 tooltip 用 `CHARACTER = <角色 id>` 走具名参数填 `$CHARACTER$`；
   **我们改用每人一个 tooltip 键** —— 因为谢列布里亚科夫缺角色对象，用了就不统一。见 `docs/11` §4.4(5)。
3. ✅ **谢列布里亚科夫的角色条目由我们自己补** —— 方案早在 `docs/10` L294 与 `docs/17` L120 定下：
   立绘已有（R56），**只需补一个角色条目即可用**。
   R56 里本来就有一段**被注释掉的** `create_country_leader = { name = "Leonid Serebryakov" ... }`
   （`events/r56_Soviet.txt` L1371 附近，连同 `days = 278` 一起被注掉），可以直接照它写。
   > ⚠️ 2026-09-15 我曾在这里写过「别自己建角色对象」——**那是错的**，与已定方案矛盾，已删。
4. 大幅立绘路径也写在这两个角色块的 `large = ...` 里，是 §1 那张表的来源之一。

---

## 0. 🚩 扫盘必读（踩过三次的坑）

### ① **必须扫全部 DLC 目录**

```text
F:\Hearts of Iron IV\dlc\<每个 dlc 子目录>\gfx\leaders\SOV\...
```

贴图按 **原版 → DLC → 用户目录 → mods** 覆盖（后者覆盖前者），同名 `.dds` 可能有多份。

> **实例（本项目踩过两次）**：**布哈林与李可夫的大幅立绘在**
> `F:\Hearts of Iron IV\dlc\dlc034_no_step_back\gfx\leaders\SOV\`
> —— 只扫「原版 + R56 + mod」会得出「他们只有小图」的**错误结论**。

### ② **立绘文件名 ≠ 角色 id**

宽松匹配（姓氏）是必需的，否则会误判「没有大图」。但姓氏宽松又会**同姓碰撞**。

| 现象 | 实例 | 对策 |
| --- | --- | --- |
| 名字拼写不同 | `SOV_lev_trotsky` 的大图叫 **`Portrait_Leon_Trotsky.dds`** | 姓氏兜底 + **多命中时也要取值** |
| 同姓不同人 | `portrait_SOV_ivan_smirnov.dds` 属于**伊万**，不是**彼得**·斯米尔诺夫 | 显式排除正则（脚本里的 `Ex` 字段） |
| 名字是机构不是人 | `idea_SOV_kirov.dds` = sprite `GFX_idea_SOV_kirov` / `name = SOV_kirov`，是**基洛夫工厂**那个可合并民族精神（原版 `common/ideas/SOV.txt` L5552） | 别按文件名收人 |

### ③ **本项目补画的图不在 `gfx/leaders/`**

自己补的立绘放 `mod/heart_of_iron/gfx/interface/hof_ic/portraits/hof_portrait_SOV_*.dds`
（156×210），**不在 `gfx/leaders` 下** → 索引时这条路径必须单独加。

### ④ 判定口径（用户 2026-09-15 定）

| 判定 | 处理 |
| --- | --- |
| 有**大图**（156×210） | ✅ 收 |
| 无大图、有**小图**（65×67） | ✅ 收（补画成本可控） |
| 大图小图**都没有** | ❌ 删去，不进池 |

---

## 1. 19 人池现状：**大图 19 / 只有小图 0 / 都没有 0**

### 1.1 已有大图（15 人，**不用画**）

| 人物 | 营 | 大图路径 | 来源 |
| --- | --- | --- | --- |
| 列夫·托洛茨基 | left | `R56\gfx\leaders\SOV\r56_portrait_SOV_Leon_Trotsky.dds` | R56（另有原版 `Portrait_Leon_Trotsky.dds`） |
| 伊万·斯米尔诺夫 | left | `VAN\gfx\leaders\SOV\portrait_SOV_ivan_smirnov.dds` | 原版 |
| 列昂尼德·谢列布里亚科夫 | left | `R56\gfx\leaders\SOV\r56_portrait_SOV_Leonid_Serebryakov.dds` | R56 ⚠️**无角色块** |
| 尼古拉·布哈林 | right | `DLC:dlc034_no_step_back\gfx\leaders\SOV\portrait_SOV_nikolay_bukharin.dds` | **DLC** |
| 阿列克谢·李可夫 | right | `DLC:dlc034_no_step_back\gfx\leaders\SOV\portrait_SOV_aleksey_rykov.dds` | **DLC** |
| 格里戈里·季诺维也夫 | united | `VAN\gfx\leaders\SOV\portrait_SOV_grigory_zinovyev.dds` | 原版 |
| 列夫·加米涅夫 | united | `VAN\gfx\leaders\SOV\portrait_SOV_lev_kamenev.dds` | 原版 |
| 米哈伊尔·图哈切夫斯基 | neutral | `VAN\gfx\leaders\SOV\Portrait_Soviet_Mikhail_Tukhachevsky.dds` | 原版 |
| 卡尔·拉狄克 | left | `MOD\gfx\interface\hof_ic\portraits\hof_portrait_SOV_karl_radek.dds` | **本 mod 补画** |
| 叶夫根尼·普列奥布拉任斯基 | left | `MOD\...\hof_portrait_SOV_yevgeny_preobrazhensky.dds` | **本 mod 补画** |
| 伊瓦尔·斯米尔加 | left | `MOD\...\hof_portrait_SOV_ivar_smilga.dds` | **本 mod 补画** |
| 米哈伊尔·托姆斯基 | right | `MOD\...\hof_portrait_SOV_mikhail_tomsky.dds` | **本 mod 补画** |
| 马尔特米扬·里亚京 | right | `MOD\...\hof_portrait_SOV_martemyan_ryutin.dds` | **本 mod 补画** |
| 格里戈里·索柯里尼柯夫 | neutral | `MOD\...\hof_portrait_SOV_grigory_sokolnikov.dds` | **本 mod 补画** |
| 亚历山大·施利亚普尼科夫 | workers | `MOD\...\hof_portrait_SOV_aleksandr_shlyapnikov.dds` | **本 mod 补画** |

> `VAN` = `F:\Hearts of Iron IV`；`R56` = `D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125`；
> `MOD` = `mod\heart_of_iron`。
> ⚠️ **这 7 张本 mod 补画的图目前只落盘到 `gfx/`，还没注册 sprite、没改角色块**（见 §3）。

### 1.2 第二批补画大图（4 人，2026-09-15 已交付）

全部在中立营；本批大图已落盘，PNG / DDS 校验通过，sprite 注册及角色块接入尚未在本次美术任务中执行。预览与调用记录见 [交付入口](../../art/portraits/v2/README.md)。参考小图及原始出图要求见 `docs/17` §4。

| 人物 | 大图路径 | 来源 |
| --- | --- | --- |
| 米哈伊尔·加里宁 | `MOD\gfx\interface\hof_ic\portraits\hof_portrait_SOV_mikhail_kalinin.dds` | 本 mod 补画 |
| 马克西姆·李维诺夫 | `MOD\gfx\interface\hof_ic\portraits\hof_portrait_SOV_maksim_litvinov.dds` | 本 mod 补画 |
| 尼古拉·沃兹涅先斯基 | `MOD\gfx\interface\hof_ic\portraits\hof_portrait_SOV_nikolay_voznesensky.dds` | 本 mod 补画 |
| 彼得·斯米尔诺夫 | `MOD\gfx\interface\hof_ic\portraits\hof_portrait_SOV_pyotr_smirnov.dds` | 本 mod 补画 |

> ⚠️ 加里宁与彼得·斯米尔诺夫的**小图文件名不带 `SOV_` 前缀**（原数据命名不一致，不是笔误）。
> ⚠️ 彼得·斯米尔诺夫与伊万·斯米尔诺夫**同姓**，出图时不要参照错人（伊万的大图在 `gfx\leaders\SOV\portrait_SOV_ivan_smirnov.dds`）。

出图规格见 `docs/17-art-spec-portraits.md`。

---

## 2. 已删 / 已移出（仅登记，供日后复查）

### 2.1 已删：无立绘 8 人（大图小图角色块三样全无）

奥尔忠尼启则、捷尔任斯基、古比雪夫、基洛夫、米高扬、皮达可夫、穆拉洛夫、柯伦泰。

> 📌 若日后补了立绘（或 R56 更新带上），按 `docs/10` §2.4.2.1 的营表直接加回来即可。
> 生成器只对**同时在册**的两人生成互斥条件，不需要改逻辑。

### 2.2 已移出：体制营（斯大林系）9 人

**用户 2026-09-15：「斯大林系全部删去不考虑加入」。**

| 人物 | 大图 | 小图 | 角色块 |
| --- | :-: | :-: | :-: |
| 莫洛托夫 | — | Y | Y |
| 卡加诺维奇 | — | Y | Y |
| 伏罗希洛夫 | Y（原版） | Y | Y |
| 马林科夫 | — | — | Y |
| 赫鲁晓夫 | — | Y | Y |
| 贝利亚 | Y（原版） | Y | Y |
| 叶若夫 | Y（R56 大图） | Y | Y |
| 亚戈达 | — | Y | Y |
| 梅尔库洛夫 | — | Y | Y |

> 角色与立绘**仍在库里**，随时可以拉回来（拉回来时生成器里的 R1 / R3② 规则会自动复活）。

---

## 3. ⏳ 待接入（本 mod 补画的 7 张）

`art/portraits/v1/` 已交付 7 张 156×210，落盘在
`mod/heart_of_iron/gfx/interface/hof_ic/portraits/`，但**接入工作尚未做**：

- [ ] 在 `interface/hof_ic.gfx` 注册 sprite（命名 `GFX_hof_ic_portrait_<key>`，与已有立绘族一致）
- [ ] 改角色块：给这 7 人补 `portraits = { civilian = { large = "GFX_hof_ic_portrait_<key>" } }`
- [ ] 席位槽改用大幅立绘（现在用的是小图）

**交付说明**：`art/portraits/v1/README.md`；**提示词与文件清单**：`art/portraits/v1/manifest.json`；
**预览**：`art/portraits/v1/preview.html` / `preview.png`；**校验**：`art/portraits/v1/validation-report.txt`。

规格：156×210 PNG（RGBA），DDS 32 位含 Alpha、不压缩、无 mipmap，
**灰米色实底（Alpha 全 255）**，与加米涅夫 / 托洛茨基样本一致 —— 这是文档允许的方案。

---

## 4. 相关文档

| 文档 | 内容 |
| --- | --- |
| `docs/10` §2.4.2.1 | **候选池与营归属**（谁在池里，权威） |
| `docs/17-art-spec-portraits.md` | **出图规格与需求**（交给出图方，权威） |
| `docs/16-art-spec-inner-circle.md` | 核心圈窗口美术规格 |
| `art/portraits/v1/README.md` | 第一批 7 张的交付说明 |
| `docs/reference/tools/scan-portrait-registry.ps1` | 本表的生成工具（含 DLC + 宽松匹配 + 同姓排除） |
| `docs/reference/reports/portrait-registry.txt` | 原始扫描报告（逐人带完整路径） |
