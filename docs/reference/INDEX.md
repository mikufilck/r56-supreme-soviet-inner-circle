# docs/reference 索引（自动生成）

> 本文件由 `build/gen-reference-index.ps1` 生成，**不要手改**。
> 重排/新增脚本后重跑该脚本即可刷新。生成时间：2026-09-25 13:09

## 目录约定

| 目录 | 放什么 | 规则 |
| --- | --- | --- |
| `tools/` | 勘查脚本（`.ps1` / `.py`） | 只读游戏/mod 文件，把结论打到 stdout 或 `../reports/` |
| `reports/` | 脚本的产出（`.txt`） | 文件名与被引用的文档一一对应 |
| `notes/` | 知识性笔记（`.md`） | 不是程序产出，是整理过的结论 |
| `images/` | 参考图（`.png`） | 从游戏 DDS 转出来的对照图 |
| `wiki/` | Paradox 官方 wiki 离线快照 | 32 页纯文本，用 `Ctrl+Shift+F` 全局搜 |
| 根目录 | 只留 `README.md` | 任何散落文件都应归入上面某一类 |

**命名约定（新脚本请遵守）**：`<scan|dump|verify|check|find|get>-<主题>-<对象>.ps1`，产出 `<主题>-<对象>-report.txt`。

---

## 脚本 → 产出（共 94 个脚本）

| 脚本 | 用途（取自脚本头部注释） | 主要产出 |
| --- | --- | --- |
| `calibrate-inlay-scale.ps1` | calibrate-inlay-scale.ps1 | `inlay-scale-report.txt` `inlay-scale-v2-report.txt` |
| `calibrate-v2.ps1` | calibrate-v2.ps1 | — |
| `check-idea-icons.ps1` | 1) 找可用的 idea 图标 sprite（communism / political 系列） | `idea-icons.txt` |
| `check-sov-icon-overrides.ps1` | 检查苏联参考图标是否也存在 DLC 覆盖版（按文件名，全 root） | `sov-icon-overrides.txt` |
| `dds2png.py` | 把参考用的 .dds 转成 .png 以便查看（Pillow 支持 DXT1/3/5 读取） | — |
| `dds2png-real.py` | DLC001 German Historical Portraits —— 真实生效的入口图标（后加载覆盖原版） | — |
| `dump-focus-names-catalog.ps1` | 全部国策 id / 中文显示名 目录（**docs/99 §28 的固定动作**） | `focus-names-catalog.txt` |
| `dump-ger-ic-idea-tiers.ps1` | Dump the modifier blocks of ALL tiers of the German Inner Circle office ideas, | `ger-ic-idea-tiers.txt` |
| `dump-ger-ic-line.ps1` | Dump the German Inner Circle "personal line" focuses with their actual rewards. | `ger-ic-line-rewards.txt` |
| `dump-ger-ic-raw.ps1` | dump-ger-ic-raw.ps1 | `ger-ic-raw.txt` |
| `dump-ger-ic-swap.ps1` | Extract the swap_ideas upgrade CHAIN of the German Inner Circle personal lines. | `ger-ic-swap-chains.txt` |
| `dump-ger-inner-circle.ps1` | 1) 抽取德国核心圈相关国策块原文（括号配平）  2) 找相关的 dynamic_modifier 定义 | `ger-inner-circle-dump.txt` |
| `dump-ic-events.ps1` | 从 WUW_Germany.txt 里导出指定事件的完整块（先回退到外层 country_event = { 再配平） | `ic-events.txt` `ic-events-dump.txt` `ic-events-dump2.txt` |
| `dump-inner-circle-dm.ps1` | 找 GER_the_inner_circle_dm 的定义并整块导出 | `inner-circle-dm-dump.txt` |
| `dump-portraits.ps1` | dump-portraits.ps1 | `candidates-portraits.txt` `candidates-portraits-loose.txt` `hof-ic-portraits-report.txt` |
| `fetch-bukharin-docs.ps1` | fetch-bukharin-docs.ps1 | — |
| `fetch-bukharin-sources.ps1` | fetch-bukharin-sources.ps1 | — |
| `fetch-wiki.ps1` | 从 Wayback Machine 抓取 HOI4 官方 wiki 页面到本目录 | — |
| `find-ascended-advisor-vars.ps1` | 找 GetAscendedAdvisor1 / GetAscendedAdvisorDesc1 的定义（遍历所有名含 scripted_localisation 的目录，含 dlc） | `ascended-advisor-vars.txt` |
| `find-ger-ascension-dds.ps1` | 按【文件名】在全部 root 里找 focus_GER_ascension_* / fuhrerprinzip 贴图，看是否有 DLC 覆盖版 | `ger-ascension-dds.txt` |
| `find-ger-ic-removal.ps1` | find-ger-ic-removal.ps1 | `ger-ic-removal.txt` |
| `find-get-ascended-advisor.ps1` | 找 GetAscendedAdvisor1/2/3 的 defined_text 定义 | `get-ascended-advisor.txt` |
| `find-ic-events.ps1` | 找出德国核心圈事件文件，并导出关键块 | `ic-events.txt` `ic-events-dump.txt` `ic-events-dump2.txt` |
| `find-ic-tt-loc.ps1` | 只在 localisation 目录里找 GER_the_inner_circle_dm_tt（含 dlc 下的 localisation） | `ic-tt-loc.txt` |
| `find-inner-circle-tt.ps1` | 1) 找 GER_the_inner_circle_dm_tt 定义在哪（含 dlc 子目录、含 localisation） | — |
| `get-effect-signatures.ps1` | 从官方 effects 文档里抽出待用效果的签名与说明 | `effect-signatures.txt` |
| `get-ic-tooltips.ps1` | 取核心圈子线相关 tooltip 的中英原文 | `ic-tooltips.txt` |
| `html2txt.ps1` | HTML → 纯文本（UTF-8 无 BOM） | — |
| `inspect-ger-icons.py` |  | — |
| `list-sov-icons.ps1` | 列出苏联国策图标候选（原版 + R56），供挑选风格参考 | `sov-icons-list.txt` |
| `make_ger_misc.py` |  | — |
| `make_ger_sheet.py` | 把德国 7 个「升格国策」入口图标拼成一张对比图，一次看全 | — |
| `make_sov_sheet.py` | 苏联国策图标风格参考拼图（原版 + R56） | — |
| `parse-html-links.ps1` | parse-html-links.ps1 —— 从已下载的 HTML 里提取链接（标题 + href） | — |
| `probe-kirov-idea.ps1` | probe-kirov-idea.ps1 —— 确认 idea_SOV_kirov 是否为人物小像 | — |
| `probe-soviet-fates.ps1` | probe-soviet-fates.ps1 | — |
| `scan-all-workshop-ger-icons.ps1` | 在【全部】工坊 mod 里搜索谁定义了 GFX_focus_GER_ascension_of_* / GER_fuhrerprinzip | `all-workshop-ger-icons.txt` |
| `scan-ascension-shape.ps1` | 扫描德国核心圈「升格国策」的形态，为我们的核心圈个人线定形。 | `ascension-shape-report.txt` |
| `scan-attach-sizes.ps1` | scan-attach-sizes.ps1 | `attach-sizes-report.txt` |
| `scan-candidates-portraits.ps1` | scan-candidates-portraits.ps1 | `candidates-portraits.txt` `candidates-portraits-loose.txt` |
| `scan-candidates-portraits-loose.ps1` | scan-candidates-portraits-loose.ps1 | `candidates-portraits-loose.txt` |
| `scan-combat-width.ps1` | scan-combat-width.ps1 | `combat-width.txt` |
| `scan-dynamic-focus.ps1` | 查 dynamic = yes 在国策里的用法与含义线索 | `dynamic-focus.txt` |
| `scan-dynamic-modifier-rules.ps1` | scan-dynamic-modifier-rules.ps1 | `dynamic-modifier-rules.txt` |
| `scan-figure-content.ps1` | scan-figure-content.ps1 | — |
| `scan-focus-collision.ps1` | 解析苏联国策树的绝对坐标，检查"核心圈 7 个入口国策"要占的格子是否空闲 | `focus-collision-report.txt` |
| `scan-focus-shine.ps1` | scan-focus-shine.ps1 | `focus-shine.txt` |
| `scan-focus-spacing.ps1` | scan-focus-spacing.ps1 | `focus-spacing.txt` |
| `scan-ger-entry-loc.ps1` | 用截图里的中文文案反查：哪个 localisation 文件提供这些键，以及哪个国策在用。 | `ger-entry-loc-report.txt` |
| `scan-ger-focus-icons.ps1` | 找出所有定义 GER_ascension_of_himmler 的国策文件，并打印该块的 icon = 行 | `ger-focus-icons-report.txt` |
| `scan-ger-ic-grid.ps1` | scan-ger-ic-grid.ps1 | `ger-ic-grid.txt` |
| `scan-ger-ic-idea-category.ps1` | scan-ger-ic-idea-category.ps1 | `ger-ic-idea-category.txt` |
| `scan-hof-ic-portraits.ps1` | 核心圈 · 立绘接入前置核查 | `hof-ic-portraits-report.txt` |
| `scan-ic-all.ps1` | 列出德国核心圈「全部」国策（不只升格国策），确认每人是否有后续个人线。 | `ic-all-report.txt` |
| `scan-ic-consts.ps1` | 挖德国核心圈用的脚本常量与样式，作为我们核心圈个人线的成本基准。 | `ic-consts-report.txt` |
| `scan-ic-ideas.ps1` | 打印德国核心圈的角色专属 idea，作为我们核心圈 idea 的【修正词条模板】。 | `ic-ideas-report.txt` |
| `scan-ic-merge.ps1` | 打印德国核心圈的「汇合国策」（分支走完后合并给强力 buff 的那种）。 | — |
| `scan-icon-refs.ps1` | 找出指定 sprite 名对应的 texturefile 实际路径，作为给 GPT 的风格参考图。 | `icon-refs-report.txt` `icon-refs-report2.txt` |
| `scan-icon-refs2.ps1` | 对指定 sprite 名，列出【所有】root 里的定义（按加载顺序），用于确认真实生效的那一个。 | — |
| `scan-idea-tags.ps1` | scan-idea-tags.ps1 | `idea-tags.txt` |
| `scan-inner-circle-art.ps1` | scan-attach-sizes.ps1 -> 现用于盘点德国核心圈纹理 | `inner-circle-art-report.txt` `inner-circle-art-verify.txt` `inner-circle-art-versions.txt` |
| `scan-inner-circle-art-versions.ps1` | scan-inner-circle-art-versions.ps1 | `inner-circle-art-versions.txt` |
| `scan-inner-circle-refs.ps1` | 定点搜索核心圈相关标识（避开 -Include/-LiteralPath 的坑，只扫相关目录） | — |
| `scan-joint-focus.ps1` | 摸清 joint_focus / shared_focus 机制（需求 B：中苏联合国策 的前置查证） | `joint-focus-report.txt` |
| `scan-modifier-tt.ps1` | scan-modifier-tt.ps1 | `modifier-tt.txt` |
| `scan-multi-tree.ps1` | scan-multi-tree.ps1 | `multi-tree-report.txt` |
| `scan-mutual-tree-bbox.ps1` | scan-mutual-tree-bbox.ps1 | `mutual-tree-bbox-report.txt` `mutual-tree-bbox-report-v2-celllevel.txt` |
| `scan-officer-roles.ps1` | 打印指定的苏联角色块，看他们有没有可用身份（将领/顾问/首脑）。 | `officer-roles-report.txt` |
| `scan-official-docs.ps1` | 官方 documentation 目录：文件大小 + 含 dynamic / national focus 的行 | `official-docs-scan.txt` |
| `scan-portrait-registry.ps1` | scan-portrait-registry.ps1 | `portrait-registry.txt` |
| `scan-roster-art.ps1` | scan-roster-art.ps1 | `roster-art-report.txt` `roster-art-report2.txt` |
| `scan-roster-art2.ps1` | scan-roster-art2.ps1 | — |
| `scan-roster-final.ps1` | scan-roster-final.ps1 | `roster-final-report.txt` |
| `scan-shine-sprite.ps1` | scan-shine-sprite.ps1 | `shine-sprite.txt` |
| `scan-sov-characters.ps1` | scan-sov-characters.ps1 | `sov-characters-report.txt` |
| `scan-sov-idea-words.ps1` | 收集苏联 idea 里实际用过的修正词条名，作为我们 idea 的【已验证词汇表】。 | `sov-idea-words-report.txt` |
| `scan-sov-portrait-inventory.ps1` | scan-sov-portrait-inventory.ps1 | `sov-portrait-inventory.txt` |
| `scan-sov-portraits.ps1` | scan-sov-portraits.ps1 | `sov-portraits-report.txt` `sov-portraits-report2.txt` |
| `scan-sov-portraits2.ps1` | scan-sov-portraits2.ps1 | — |
| `scan-sov-roster-b.ps1` | 扫描"托洛茨基组"7 人的大幅立绘：找文件 + 读真实尺寸 + 解析 sprite 注册 | — |
| `scan-tree-bbox.ps1` | scan-tree-bbox.ps1 | `mutual-tree-bbox-report.txt` `mutual-tree-bbox-report-v2-celllevel.txt` `tree-bbox-report.txt` |
| `scan-tree-extent.ps1` | scan-tree-extent.ps1 | `tree-extent-report.txt` |
| `scan-tree-rules2.ps1` | scan-tree-rules2.ps1 | — |
| `scan-trotsky-r56.ps1` | 摸清 R56 现有的「反对派系统」——特别是托洛茨基相关的一切 | `trotsky-r56-report.txt` |
| `scan-tsarist-officers.ps1` | 搜游戏内真实存在的「沙俄旧军官」角色 —— 供「返聘沙俄军官」国策点名用。 | `tsarist-officers-report.txt` |
| `scan-ui-art.ps1` | scan-ui-art.ps1 | `ui-art-report.txt` |
| `scan-unregistered-portraits.ps1` | scan-unregistered-portraits.ps1 | `unregistered-portraits-report.txt` |
| `scan-window-art-bounds.ps1` | 量 hof_ic_window_bg.dds 的实际覆盖范围（逐行/逐列统计 alpha） | `window-art-bounds-report.txt` |
| `verify-bom-and-logs.ps1` | verify-bom-and-logs.ps1 | — |
| `verify-has-start-date.ps1` | verify-has-start-date.ps1 | `has-start-date-verify.txt` |
| `verify-inner-circle-art.ps1` | verify-inner-circle-art.ps1 | `inner-circle-art-report.txt` `inner-circle-art-verify.txt` `inner-circle-art-versions.txt` |
| `verify-sov-old-tree.ps1` | verify-sov-old-tree.ps1 | `sov-old-tree-verify.txt` |
| `verify-sov-rule.ps1` | verify-sov-rule.ps1 | `sov-rule-verify.txt` |
| `zoom-ger-4.py` |  | — |

## 产出报告一览（共 93 个）

| 报告 | 行数 | 首行 |
| --- | --- | --- |
| `all-workshop-ger-icons.txt` | 20 (0.8 KB) | ================ GFX_focus_GER_ascension_of_himmler ================ |
| `ascended-advisor-vars.txt` | 106 (3.3 KB) | ################ F:\Hearts of Iron IV |
| `ascension-shape-report.txt` | 49 (4.8 KB) | === 1. GER_ascension_of_* 形态 === |
| `attach-sizes-report.txt` | 36 (2.2 KB) | 国家               文件                              行数       KB |
| `bom-logs-verify.txt` | 44 (4.5 KB) | === 1. .mod 文件 BOM 检查 === |
| `bukharin-index-links.txt` | 85 (10.7 KB) | ../ernest-mandel/marxist.org-chinese-mandel-1988.htm       | 从资本主义向社会主义过渡时期中的一党制和官僚制度 |
| `candidates-portraits.txt` | 103 (8.7 KB) | 扫描 sprite 注册表…… |
| `candidates-portraits-loose.txt` | 59 (3.8 KB) | 全盘 dds 索引：10345 个 |
| `combat-width.txt` | 102 (6.5 KB) | ################################################################################ |
| `dynamic-focus.txt` | 48 (3.2 KB) | ################ A) 各 root 里 focus 块内出现 dynamic = yes 的次数 |
| `dynamic-modifier-rules.txt` | 629 (37.1 KB) | ##### 1. DM 块内「一层」字段名（按出现次数降序）##### |
| `effect-signatures.txt` | 141 (3.9 KB) | ======== complete_national_focus   (L2870) ======== |
| `figure-bukharin.txt` | 321 (16.7 KB) | 扫描关键词：'bukharin'（不区分大小写） |
| `focus-collision-report.txt` | 30 (1 KB) | 文件: D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\national_focus\soviet.txt |
| `focus-names-catalog.txt` | 22577 (1957.2 KB) | id	中文名	出处 |
| `focus-scan-report.txt` | 382 (26.9 KB) | === 全局计数（D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus）=== |
| `focus-shine.txt` | 158 (6.5 KB) | ################################################################################ |
| `focus-spacing.txt` | 89 (2.9 KB) | ================================================================================================ |
| `ger-ascension-dds.txt` | 29 (2.7 KB) | ######## F:\Hearts of Iron IV |
| `ger-entry-loc-report.txt` | 18 (0.5 KB) | ==== 全国领导托特 ==== |
| `ger-focus-icons-report.txt` | 53 (2.6 KB) | ########  : F:\Hearts of Iron IV\common\national_focus |
| `ger-ic-grid.txt` | 57 (4.3 KB) | germany.txt 行数：38872 |
| `ger-ic-idea-category.txt` | 71 (10.3 KB) | ################################################################################ |
| `ger-ic-idea-tiers.txt` | 823 (24.2 KB) | # German Inner Circle office ideas - ALL TIERS, with modifiers |
| `ger-ic-line-rewards.txt` | 536 (18.8 KB) | # German Inner Circle personal-line focuses (R56) - reward dump |
| `ger-ic-raw.txt` | 1173 (40.7 KB) | ################################################################################ |
| `ger-ic-removal.txt` | 320 (24.6 KB) | ################################################################################ |
| `ger-ic-swap-chains.txt` | 141 (7.3 KB) | # German Inner Circle personal lines - idea UPGRADE CHAINS |
| `ger-inner-circle-dump.txt` | 623 (17.8 KB) | ################ R56 : D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\natio… |
| `germany-calib-report.txt` | 53 (1.8 KB) | 文件: D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.t… |
| `get-ascended-advisor.txt` | 1829 (58 KB) | ######## [R56] D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\scripted_loca… |
| `has-start-date-verify.txt` | 86 (6.3 KB) | === 1. 原版 + R56 里 has_start_date 的出现次数与写法 === |
| `hof-ic-portraits-report.txt` | 103 (6 KB) | ################ 1. 立绘贴图路径解析 ################ |
| `ic-all-report.txt` | 77 (6.9 KB) | germany.txt 共切出 focus 块: 909 |
| `ic-consts-report.txt` | 118 (17.5 KB) | === inner_circle_time_tier === |
| `ic-events.txt` | 43 (1.2 KB) | ################ A) 含 GER_inner_circle 的事件文件 |
| `ic-events-dump.txt` | 17 (0.4 KB) | 总行数 = 24649 |
| `ic-events-dump2.txt` | 242 (6.9 KB) | 总行数 = 24649 |
| `ic-events-dump3.txt` | 624 (14.1 KB) | 总行数 = 24649 |
| `ic-ideas-report.txt` | 336 (6.2 KB) | ======== [原版] GER.txt  GER_organization_todt L5846 ======== |
| `icon-refs-report.txt` | 31 (2.2 KB) | ======== 德国核心圈升格国策图标（入口国策参考）======== |
| `icon-refs-report2.txt` | 48 (2.8 KB) | ==== GFX_focus_GER_ascension_of_todt ==== |
| `ic-refs-2.txt` | 1153 (114.7 KB) | ######## [R56] 待扫文件数 = 780 |
| `ic-tooltips.txt` | 32 (3.9 KB) | ######## F:\Hearts of Iron IV\localisation\simp_chinese\WUW_focus_l_simp_chinese.yml |
| `ic-tt-found.txt` | 32 (2.8 KB) | ################ A) 哪些文件提到 GER_the_inner_circle_dm_tt |
| `ic-tt-loc.txt` | 24 (2.3 KB) | ######## F:\Hearts of Iron IV  (localisation 目录数 = 1) |
| `idea-icons.txt` | 68 (3.1 KB) | ################ A) 候选 idea 图标 sprite |
| `idea-tags.txt` | 86 (3.8 KB) | ========================================================================================== |
| `inlay-scale-report.txt` | 9 (0.8 KB) | 国家                  X min    X max    Y min    Y max     未解  inlay 位置 / 比例 |
| `inlay-scale-v2-report.txt` | 7 (0.9 KB) | 树             Xmax  Ymax   CFP.x   CFP.y inlay.x inlay.y   推断（假设 1 格 = 100px） |
| `inner-circle-art-report.txt` | 58 (4.5 KB) | === 德国核心圈窗口用到的纹理（给 GPT 出图时的参考基准）=== |
| `inner-circle-art-verify.txt` | 33 (1.6 KB) | 文件                                 实际尺寸         规格尺寸         位深 结果 |
| `inner-circle-art-versions.txt` | 51 (3.9 KB) | ==================================================================================================== |
| `inner-circle-dm-dump.txt` | 24 (0.8 KB) | ################ [R56] D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\dynam… |
| `joint-focus-report.txt` | 252 (7.8 KB) | ============================================================================= |
| `military-modifier-words.txt` | 213 (9.7 KB) | # 军事/补给/进攻类词条核实（R56 + 原版） |
| `modifier-tt.txt` | 216 (9.2 KB) | 我们从 hof_ic_trotsky_dm.txt 读到 39 个词条 |
| `modifier-words-2.txt` | 1207 (123.7 KB) | # 第二批词条核实（兵种进攻 / 外交关系 / 将领特质 / 生产效率） |
| `modifier-words-3.txt` | 787 (73 KB) | # 第三批核实：战场宽度 / 装甲攻击 / 资源 / 建筑位 |
| `multi-tree-report.txt` | 509 (45.1 KB) | === 需裁决：同一 TAG 有多个 focus_tree（含各自 country 评分块） === |
| `mutual-tree-bbox-report.txt` | 75 (4.4 KB) | ============================================================================= |
| `mutual-tree-bbox-report-v2-celllevel.txt` | 85 (6.2 KB) | !!! 2026-09-21 作废警告 !!! |
| `officer-roles-report.txt` | 108 (2.7 KB) | 文件行数: 6382 |
| `official-docs-scan.txt` | 90 (5.4 KB) | ################ F:\Hearts of Iron IV\documentation |
| `portrait-registry.txt` | 188 (17.9 KB) | ======== 扫描 root（共 49 个，含 DLC）======== |
| `portraits-dump.txt` | 140 (2.6 KB) | ########## SOV_lev_trotsky ########## |
| `prc-tree-report.txt` | 11 (0.4 KB) | 文件: D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\china_com… |
| `probe-kirov.txt` | 212 (15 KB) | === 1. 哪个 sprite 用了 idea_SOV_kirov.dds === |
| `roster-art-report.txt` | 23 (2 KB) | gfx/leaders 下立绘文件: 3552 个不同 basename |
| `roster-art-report2.txt` | 38 (3.6 KB) | 解析到角色块: 163 个 |
| `roster-b-report.txt` | 58 (2.8 KB) | ################ 1. gfx\leaders\SOV 下的候选立绘文件 ################ |
| `roster-final-report.txt` | 92 (7.5 KB) | 角色                             civilian.large                     army.large                         结论 |
| `shine-sprite.txt` | 70 (4.1 KB) | 扫描 .gfx 根目录 30 个 |
| `sov-characters-report.txt` | 148 (7 KB) | SOV.txt 大小: 140093 字符 |
| `sov-icon-overrides.txt` | 25 (1.8 KB) | ==== focus_SOV_the_supreme_soviet.dds |
| `sov-icons-list.txt` | 142 (5.6 KB) | ==== R56 : 57 个 ==== |
| `sov-idea-words-report.txt` | 240 (7.4 KB) | 扫描文件: 4 |
| `soviet-fates.txt` | 24 (0.9 KB) | ==================== Khrushchev ==================== |
| `soviet-fates2.txt` | 27 (1.4 KB) | ==================== Khrushchev ==================== |
| `sov-old-tree-verify.txt` | 91 (3.7 KB) | === 1. 核心圈入口国策在两个 SOV 树文件里的存在情况 === |
| `sov-portrait-inventory.txt` | 376 (14.5 KB) | ===== A. SOV 大图  (gfx/leaders/SOV/*.dds) ===== |
| `sov-portraits-report.txt` | 69 (3.2 KB) | R56 interface/*.gfx 合计 7711983 字符 |
| `sov-portraits-report2.txt` | 206 (13.7 KB) | === A. 递归扫描 interface（含子目录），列出所有含 SOV 的人物立绘 sprite === |
| `sov-rule-verify.txt` | 66 (2.3 KB) | === 1. 全 mod 搜索 'SOV_focus_tree_selection'（引用处会暴露是否可达） === |
| `trait-accumulation-verify.txt` | 207 (11.7 KB) | # dynamic_modifier 定义（角色特质累积容器）—— 看 modifier 里怎么引用变量 |
| `tree-bbox-report.txt` | 39 (2.1 KB) | 解析到 focus 节点: 449 个 |
| `tree-extent-report.txt` | 45 (2.4 KB) | === 1. 苏联国策树坐标范围（含负值）=== |
| `tree-rules-full.txt` | 190 (5 KB) | ############ A. 游戏规则：完整块（含全部选项与 default）############ |
| `trotsky-r56-report.txt` | 206 (13.4 KB) | ============================================================================= |
| `tsarist-officers-report.txt` | 298 (8.3 KB) | 角色文件合计: 531 |
| `ui-art-report.txt` | 160 (4.7 KB) | interface 下 .gfx 合计 7709464 字符 |
| `unregistered-portraits-report.txt` | 282 (18.7 KB) | === A. 磁盘上存在的 SOV 立绘 DDS 文件 === |
| `window-art-bounds-report.txt` | 84 (4.1 KB) | 文件: D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\gfx\interface\hof_ic\hof_ic_window_bg.dds |
