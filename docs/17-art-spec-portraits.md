# 人物立绘补充需求（交给出图 AI 用）

> **状态（2026-09-15 更新）**：第 3 节 **7 张已全部交付**（`art/portraits/v1/`）。
> 第 4 节本批已交付，见 [第二批预览与交付记录](../art/portraits/v2/README.md)；最新资源状态统一见下述登记表。
>
> 📌 **立绘资源的完整登记表见 `docs/reference/portrait-registry.md`** ——
> 谁有大图、路径在哪、还缺什么，一律以那张表为准，**不要重新扫盘**（扫一次要跑 5000+ 大图）。
> 本文件**只负责「交给出图方怎么做」**；第 5 节那批「已有大图不用画」的人
> 也不在本文件重复罗列（避免两处不同步，AGENTS 规则 10）。

> 任务：为若干苏联人物**依据现有小图，补画成大幅立绘**。
> 产出后放进 `mod/heart_of_iron/gfx/interface/hof_ic/portraits/`，我会注册 sprite 并接进核心圈窗口。

> **首批交付（2026-09-14）**：第 3 节七张已全部完成，斯米尔加的细圆眼镜已补齐（修订前大图存 `drafts/`）；
> 156×210 PNG / 32 位含 Alpha DDS 检查通过。采用与加米涅夫 / 托洛茨基样本一致的灰米色实底。
> 预览见 `art/portraits/v1/preview.html`，交付说明与完整提示词见 `art/portraits/v1/README.md` / `manifest.json`。
> **输入核对**：三张 imprisoned 小图实测 67×69，其余 65×67；托洛茨基样图实际从 R56 工坊目录读取。

---

## 1. 背景：为什么需要补

HOI4 角色的立绘分两档，R56 里两者并不总是齐全：

| 档位 | 尺寸 | 用途 | 谁在用 |
| --- | --- | --- | --- |
| `army.small` / `civilian.small` | **65 × 67** | 顾问卡、想法图标 | 几乎每个角色都有 |
| `army.large` / `civilian.large` | **156 × 210** | 领袖头像、**德国核心圈的席位** | 只有一部分角色有 |

我们的核心圈窗口，席位槽按 **156 × 210** 的原图、以 0.5 缩放渲染进 131×139 的框。
**用 65×67 的小图硬撑会变形**（小图是近正方形 65×67，而席位槽是 3:4 竖版）。

所以要请你**看着这张小图，画一张同一个人物的大图**。

---

## 2. 风格基准（**先读这两张，照它们画**）

这两张是「合格样本」，请把它们当风格与构图的标准：

```text
# 你要仿的构图/画风（原版苏联领袖立绘，156x210）
F:\Hearts of Iron IV\gfx\leaders\SOV\portrait_SOV_lev_kamenev.dds

# R56 自己画的那批（也是 156x210，风格与上面一致）
F:\Hearts of Iron IV\gfx\leaders\SOV\r56_portrait_SOV_Leon_Trotsky.dds
```

**要点**：

- **画风**：写实油画/半调网点风格，低饱和、偏褐灰或灰蓝，接近老照片上色
- **构图**：**头肩像**，人物居中偏左或居中，脸部清晰可辨
- **背景**：纯色或极简虚化背景，不要场景
- **尺寸**：**严格 156 × 210**（宽 × 高，竖版）
- **格式**：32 位含 alpha 通道的 DDS（或 PNG/TGA，我来转）
- **一致性**：同一批图的光照方向、色调、笔触要统一，看起来像一个人画的

> ⚠️ 这些人物是历史人物，请**依据小图里已有的面孔**来画，保持同一张脸、同一年龄段与神态。小图分辨率低，做合理的细节补完即可，不要改变人物特征。

---

## 3. ✅ 已交付（7 张）—— 反对派，核心圈席位要用

> **状态：2026-09-14 全部完成，无需重做。** 本表保留作记录与「已用过哪些小图」的台账。

| # | 人物 | 中文名 | 参考小图（**源文件，读它**） | 请输出为 |
| --- | --- | --- | --- | --- |
| 1 | Karl Radek | 卡尔·拉狄克 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_karl_radek.dds` | `hof_portrait_SOV_karl_radek.dds` |
| 2 | Yevgeny Preobrazhensky | 叶夫根尼·普列奥布拉任斯基 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_yevgeny_preobrazhensky.dds` | `hof_portrait_SOV_yevgeny_preobrazhensky.dds` |
| 3 | Ivar Smilga | 伊瓦尔·斯米尔加 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_ivar_smilga_imprisoned.dds` | `hof_portrait_SOV_ivar_smilga.dds` |
| 4 | Mikhail Tomsky | 米哈伊尔·托姆斯基 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_mikhail_tomsky.dds` | `hof_portrait_SOV_mikhail_tomsky.dds` |
| 5 | Martemyan Ryutin | 马尔特米扬·里亚京 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_martemyan_ryutin_imprisoned.dds` | `hof_portrait_SOV_martemyan_ryutin.dds` |
| 6 | Grigory Sokolnikov | 格里戈里·索柯里尼柯夫 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_grigory_sokolnikov.dds` | `hof_portrait_SOV_grigory_sokolnikov.dds` |
| 7 | Aleksandr Shlyapnikov | 亚历山大·施利亚普尼科夫 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_aleksandr_shlyapnikov_imprisoned.dds` | `hof_portrait_SOV_aleksandr_shlyapnikov.dds` |

> 第 3、5、7 张的参考小图带 `_imprisoned`（囚服/憔悴状态），交付时已按要求画成正常状态。

---

## 4. ✅ 第二批：本次补画需求与输入记录（已交付）

本节保留本次补画的输入要求；最终大图资源与接入状态见 `docs/reference/portrait-registry.md` §1.2。

| # | 人物 | 中文名 | 参考小图（**源文件，读它**） | 请输出为 |
| --- | --- | --- | --- | --- |
| 1 | Mikhail Kalinin | 米哈伊尔·加里宁 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_mikhail_kalinin.dds` | `hof_portrait_SOV_mikhail_kalinin.dds` |
| 2 | Maxim Litvinov | 马克西姆·李维诺夫 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_maksim_litvinov.dds` | `hof_portrait_SOV_maksim_litvinov.dds` |
| 3 | Nikolay Voznesensky | 尼古拉·沃兹涅先斯基 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_SOV_nikolay_voznesensky.dds` | `hof_portrait_SOV_nikolay_voznesensky.dds` |
| 4 | Pyotr Smirnov | 彼得·斯米尔诺夫 | `F:\Hearts of Iron IV\gfx\interface\ideas\idea_pyotr_smirnov.dds` | `hof_portrait_SOV_pyotr_smirnov.dds` |

> ✅ **好消息**：这 4 张的参考小图**都是正常顾问图**（不带 `_imprisoned`），
> 没有牢栏、囚服、档案纸要处理，比第一批简单。
>
> ⚠️ 加里宁与彼得·斯米尔诺夫的**小图文件名不带 `SOV_` 前缀**（原数据命名不一致，不是笔误），路径照上表写即可。
>
> ⚠️ **彼得·斯米尔诺夫与伊万·斯米尔诺夫同姓**。若要拿「已有大图」当风格参考，
> **别拿错成伊万**（`gfx\leaders\SOV\portrait_SOV_ivan_smirnov.dds` —— 那是另一个人）。

---

## 5. 已有大幅立绘的人（**不用画**）

见 **`docs/reference/portrait-registry.md` §1.1** —— 19 人池里有大图的 **15 人**，逐人带完整路径。

此处**不重复罗列**，避免两处不同步（AGENTS 规则 10）。

---

## 6. 已从候选池删去的人（**不要画**）

| 类别 | 人数 | 名单 |
| --- | :-: | --- |
| **无立绘删除** | 8 | 奥尔忠尼启则、捷尔任斯基、古比雪夫、基洛夫、米高扬、皮达可夫、穆拉洛夫、柯伦泰（大图小图角色块三样全无） |
| **体制营移出** | 9 | 莫洛托夫、卡加诺维奇、伏罗希洛夫、马林科夫、赫鲁晓夫、贝利亚、叶若夫、亚戈达、梅尔库洛夫（用户：「斯大林系全部删去不考虑加入」） |

> 上一版本里的「可选补的 8 张」已作废：其中 **4 人属体制营已移出**、
> **4 人升为第 4 节的必补项**。
>
> ⚠️ **谢列布里亚科夫是特例**：他**有大图但无角色定义**
> （`r56_portrait_SOV_Leonid_Serebryakov.dds`），角色定义由我在 mod 里补，**不需要出图**。

---

## 7. 交付要求

| 项 | 要求 |
| --- | --- |
| 尺寸 | **严格 156 × 210**（宽 × 高） |
| 格式 | DDS（首选）或 PNG / TGA / BMP（我来转） |
| 位深 | **32 位含 alpha**，背景透明或与其余立绘一致的实底 |
| 放置 | `mod/heart_of_iron/gfx/interface/hof_ic/portraits/` |
| 命名 | 严格按上表的「请输出为」列 |
| 注册 | 由我在 `interface/hof_ic.gfx` 里加，你不用管 |

**先交第 4 节的 4 张即可**，我看过效果确认风格无误后，再讨论还要不要动别的。

> 第 4 节的 4 张与第 3 节已交付的 7 张**必须同一画风同一批交付感**：
> 同一光照方向（左上柔光）、同一低饱和褐灰色调、同一笔触、同一灰米色实底。
> 可直接用 `art/portraits/v1/png/` 里已交付的 7 张当风格参考。
