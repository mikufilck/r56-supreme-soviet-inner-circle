# 103 · 最高苏维埃核心圈一次性奖励审查

> 2026-09-25 建档，2026-09-29 更新。燃料、交通、海军航空、弹药、垦荒与电影六项已经实装；空降试验部队仍是候选。个人线数值与完成效果的单一数据源仍是 `build/gen-hof-ic-s3.ps1`。

## 扫描范围与德国蓝本

检查了原版 `F:/Hearts of Iron IV/common/national_focus/germany.txt` 中 `GER_ascension_of_todt` 至 `GER_loyalty_to_the_fuhrer` 的 **29 个德国核心圈国策**，以及本模组 `common/national_focus/soviet.txt` 中 **175 个 `hof_ic_` 国策**（22 入口、152 个人线、1 中央国策）。德国实例包括：`GER_form_organization_todt`、`GER_employ_philipp_holzmann` 直接建厂；`GER_plenipotentiary_of_the_four_year_plan` 给科研加速；`GER_strengthen_the_waffen_ss` 创建师；`GER_optimize_reich_labour_service` 解锁决议分类。德国 `GER_wunderwaffe` 也通过人物特质处理新军事顾问，而不只是加一条国家修正。

苏联 152 个个人线国策在本轮之前已有非数值的一次性效果集中在五处：托洛茨基“返聘沙俄军官”加强两位现成将领、“中国革命问题”加外交关系；李可夫“扶植航空”加强现成雅科夫列夫 MIO；李维诺夫“苏法互助条约”建立外交关系；图哈切夫斯基“纵深战斗指示”给大纵深子学说掌握度。其余个人节点主要是动态修正与官衔升级。因此有增加实物奖励的空间，但不宜让 152 条节点都额外送一次东西：这些人物可以轮流入席，永久性奖励会持续累积。

## 候选（按内容契合度与实施成本排序）

| 节点 | 甲：具体奖励 | 乙：较轻奖励 | 依据与代价 |
| --- | --- | --- | --- |
| `hof_ic_smilga_fuel_main_directorate` 燃料总局 | 一次性增加燃料储备，数额按游戏经济规模平衡；原版 `add_fuel` 效果已存在。 | 保持现有燃料获取和储量修正。 | 该节点就是建立燃料部门计划。甲很直观，但储油已满时可能浪费；可以给完成时提示。 |
| `hof_ic_serebryakov_commissariat_of_transport` 交通人民委员部 | 在苏联拥有且控制的核心州完成少量铁路或基础设施工程。 | 给铁路研究加速。 | 节点史料写明战后路网修复；甲需要先选历史地点，并避免向失控州凭空建设。 |
| `hof_ic_pyotr_smirnov_the_naval_aviation` 海军航空兵 | 在苏联控制的海军基地州增加一级空军基地，配合海军轰炸机研究加速。 | 仅给海军轰炸机研究加速。 | 节点是海军航空兵归属变更。甲比直接送海军轰炸机更稳定，但空军基地只是兵种建设的抽象表达。 |
| `hof_ic_voznesensky_the_ammunition_plan` 弹药生产计划 | 在控制中的后方核心州增加少量军用工厂。 | 一次性军工建设加速或炮兵科研加速。 | 节点史料有炮弹、迫击炮弹的实际增产；甲可见，但不能和苏联工业通用线过量叠加。 |
| `hof_ic_khrushchev_the_virgin_lands` 荒地 | 在仍由苏联控制的哈萨克州增加基础设施或建筑位。 | 解锁一次性的垦荒决议，玩家选择建设地点。 | 节点对应 1954 年垦荒。甲会把后期事件前移到 1936 年后的任意时点；乙更能承载成本及生态后果，但要新增决议。 |
| `hof_ic_ryutin_soyuzkino` 苏联电影 | 解锁有声电影／新闻影片宣传决议。 | 一次性政治点或战争支持。 | 节点是国家电影机构和有声电影生产，不宜把摄影棚机械地算成民用工厂；甲须建立并平衡新决议。 |
| `hof_ic_tukhachevsky_airborne_and_tanks` 空降兵与战车 | 解锁一支小规模空降试验部队，前提是能确认编制、装备、科技和有效落点。 | 给空降兵与装甲科技研究加速。 | 德国 `GER_strengthen_the_waffen_ss` 有建师先例；但这里史实说的是兵种改革，直接送大部队容易让“试验”变成凭空出现的野战军。 |

**先前已取甲的四处**：燃料总局一次性增加 5000 燃料；交通人民委员部在仍属苏联且受苏联控制的莫斯科州、图拉州各建一级基础设施；海军航空兵优先在克里米亚建一级空军基地，条件不满足时尝试摩尔曼斯克；弹药生产计划优先在图拉增加一格建筑位和一座军工厂，条件不满足时选择可控的苏联核心州。原数值奖励均保留。具体条件和效果以生成器的 `Raw` 字段为准。

### 2026-09-29 · 非终局数值复核后的实物候选

本轮复查后，**最适合的工厂奖励仍是已实装的沃兹涅先斯基「弹药生产计划」军工厂**；「安置疏散企业」再送工厂会与原版工业转移内容重复。尚未实装且值得向用户报告的三项是：

1. **赫鲁晓夫「垦荒」**：在受控的哈萨克核心州增建铁路／基础设施，比全国工业产能更贴近开垦所需的运输网络；需先选定史实地点，并考虑 1954 年工程可在早期游戏解锁的时间问题。
2. **里亚京「国家电影公司」**：解锁有声电影或新闻影片的宣传决议。摄影棚不适合直接算作民用工厂；决议可体现电影作为持续宣传渠道，但需另写费用与冷却机制。
3. **图哈切夫斯基「空降兵与战车」**：可考虑一支编制和装备均已核实的小规模试验部队；现有节点已提供兵种相关数值及 MIO 加成，直接赠送常规野战师容易超过「试验」的尺度。

其中**垦荒与电影已在用户 2026-09-29 授权后实施**，详见下节。空降试验部队仍是候选，尚未修改完成效果。

### 已实施：垦荒与电影巡映

赫鲁晓夫「荒地」完成时，州 **583 库斯塔奈、590 阿克莫林斯克、882 巴甫洛达尔**各加一级基础设施；每州分别要求苏联拥有并控制、基建低于 5 级。州 ID／名称依据本机 1.19.3 `history/states/` 与 `localisation/english/state_names_l_english.yml`。这三地是哈萨克垦荒重点；历史研究列出的开垦面积约为库斯塔奈 600 万、阿克莫拉逾 400 万、巴甫洛达尔逾 200 万公顷：[哈萨克垦荒地区研究](https://pmc.ncbi.nlm.nih.gov/articles/PMC12171232/)。未对已失控或满级的州强行建设；原数值词条保留。

里亚京「苏联电影」完成后解锁**苏联电影巡映**分类，三条决议各花 25 政治点、只能执行一次。前两部直接增加基础数值，第三部提供 180 天民族精神。电影是历史实片，决议表示 1936 年之后的重映，并不宣称里亚京本人导演或拍摄：

| 决议影片 | 内容依据 | 决议奖励 |
| --- | --- | --- |
| 1930《像他们那样》（Будьте такими，亦称 Р.В.С.） | 内战中布尔什维克获乡村援助，[俄罗斯文化部／国家电影基金开放馆藏](https://www.culture.ru/live/movies/17479/budte-takimi-rvs-allyur-dva-kresta)明确载为「Союзкино」作品。 | 即时战争支持度 +10 个百分点 |
| 1930《记住他们的面孔》（Запомните их лица） | 反犹太煽动与工人之间的冲突，同一[开放馆藏](https://www.culture.ru/live/movies/17486/zapomnite-ikh-lica-prestuplenie-gospodina-surkova)明确载为「Союзкино」作品。 | 即时稳定度 +10 个百分点 |
| 1932《迎击计划》（Встречный） | 列宁格勒工人的工业超额计划；[国家电影基金的年代研究](https://gosfilmofond.ru/speczproekty-sovetskaya-programma-na-veneczianskom-kinofestivale-1932-goda/)确认影片年代与主题，[列宁电影制片厂厂史](https://ca.lenfilm.ru/studio/history/)确认其 1930–1932 年名称为「列宁格勒联盟电影制片厂」。 | 180 天工厂生产效率增长 +5% |

影片中文名是本模组对俄文片名的译法；上述来源未提供权威中文译名。**未选《生路》**：它虽是著名的 1931 年苏联有声片，但[国家电影基金](https://gosfilmofond.ru/sotrudniki-otdela-czifrovoj-restavraczii-gosfilmofonda-rf-zavershili-restavracziyu-filma-putyovka-v-zhizn/)明确列其出品方为「Межрабпомфильм」，不应误算作「Союзкино」影片。

电影分类、决议、第三部的 180 天民族精神和本地化分别落在 `common/decisions/categories/hof_ic_cinema_categories.txt`、`common/decisions/hof_ic_cinema_decisions.txt`、`common/ideas/hof_ic_cinema_ideas.txt` 与 `localisation/simp_chinese/hof_ic_cinema_l_simp_chinese.yml`。旧档只要已完成里亚京国策即可显示新分类；已完成国策本身不会重复执行新的完成效果。游戏内验收见 `docs/99` §101。

## 明确不加或暂不加

| 节点 | 原因 |
| --- | --- |
| `hof_ic_voznesensky_the_placement_of_plants` 安置疏散企业 | 原版已有 `SOV_move_industry_to_the_urals` 与 `SOV_industry_relocation` 决议组；再直接给迁厂效果会重复。适合考虑缩短原迁厂决议时间，但须核实原脚本变量和完成顺序。 |
| `hof_ic_trotsky_military_specialists` 返聘沙俄军官 | 已给沙波什尼科夫、科尔克两名原有角色加技能；两人原版／R56 已有将领角色，不能重复招募。 |
| `hof_ic_rykov_sponsor_aviation` 扶植航空 | 已加强雅科夫列夫 MIO，不再送第二个同名设计局。 |
| `hof_ic_litvinov_the_franco_soviet_treaty` 苏法互助条约 | 已有双边条约与保证独立效果，新增装备或工厂与条约内容不符。 |

## 实装边界

涉及建筑、单位时，只能把奖励落在苏联**实际拥有并控制**的州；失去国土时避免静默失效。新奖励尽量使用原版已经出现的 `add_fuel`、`add_building_construction`、`add_tech_bonus`、`unlock_decision_category_tooltip`、`create_unit` 语法。新增一次性奖励应放在个人线 `Raw` 段并保留生成器；改动后重生成、同步到完整 `soviet.txt`，再运行项目自检及游戏内 `error.log` 复核。
