# 24 · 国策图标出图说明（托洛茨基线）

> 2026-09-15 透明版交付状态与预览见 [美术交付入口](../art/focus/README.md)；逐张校验以其中链接的清单和报告为准。

> 用途：把本 mod 现在要出的**国策图标**整理成一份可以直接连同参考图交给 GPT 的说明：
> 规格 + **美术风格参照文件的真实路径** + 每条国策的**效果（中文）** 与**文案** + 少量引导。
> ⚠️ **本文档不指定每条图具体画什么** —— 图案由出图方按文案自由发挥，下面的「引导」只是意象提示，可不用。

---

## 0. 网络渠道现状（2026 更新）

| 渠道 | 状态 | 备注 |
| --- | --- | --- |
| `zh.wikipedia.org` | ✅ **全文可抓** | 之前不可用，现已恢复 |
| `en.wikipedia.org` | ✅ **全文可抓** | 之前不可用，现已恢复 |
| `marxists.org/chinese/` | ✅ | 中文马克思主义文库，一直可用 |
| `marxists.org/archive/`（英文） | ✅ | 之前 404 是因为试的路径不对 |
| `britannica.com` | ✅ | — |

⚠️ 中文维基缺口：`伊万·尼基托维奇·斯米尔诺夫`、`列昂尼德·彼得罗维奇·谢列布里亚科夫` 两条 **404**，
须走英文 `en.wikipedia.org/wiki/Ivan_Smirnov_(politician)`、`en.wikipedia.org/wiki/Leonid_Serebryakov`。

---

## 1. 交付规格

| 项目 | 值 |
| --- | --- |
| 画布 | **100 × 88 px** |
| 格式 | AI 出 **PNG**，我方转 **DDS（ARGB8、不带 mipmap）** |
| 硬性要求 | **无文字、无字母、无数字、无水印、画面外不画边框**（边框由游戏绘制） |
| 🚩 **背景（必顶）** | **必须是透明底**（真 alpha 通道），**不要铺任何实色底**。<br>参考：原版 `focus_SOV_*.dds` 的透明率是 **24~45%**，四角 `alpha = 0`。<br>**铺了不透明深色底 = 国策树里显出深色方块边框**（2026-09-15 踩过：24 张全部 100% 不透明，进游戏全是黑框，而游戏**不报错**） |
| 构图 | 主体居中、撑满画布，**主体之外全部 alpha = 0** |
| 自检 | 导完跑 `python art/focus/check_alpha.py` —— **四角 alpha 必须是 0**，透明率应落在 **20~50%** |
| PNG 落盘 | `art/focus/`（出图后归档） |
| DDS 落盘 | `mod/heart_of_iron/gfx/interface/hof_ic/focus/` |

---

## 2. 美术风格参照（两套，路径为**实测确认生效**的那一份）

### 2.1 入口国策（7 张）→ 德国「核心圈入口」肖像式

```
参照目录：F:\Hearts of Iron IV\dlc\dlc001_german_historical_portraits\gfx\interface\goals\
  focus_GER_ascension_of_todt.dds
  focus_GER_ascension_of_speer.dds
  focus_GER_ascension_of_goring.dds
  focus_GER_ascension_of_himmler.dds
  focus_GER_ascension_of_goebbels.dds
  focus_GER_party_chancellor_hess.dds
  focus_GER_party_chancellor_bormann.dds
  focus_GER_fuhrerprinzip_todt.dds        （枢纽国策，含「人物 + 上方鹰徽」的变体）
```

> ⚠️ **别用错目录**。`F:\Hearts of Iron IV\gfx\interface\goals\focus_GER_ascension_of_*.dds`
> 里是**旧版纹章图**（工业圆章／铁锹盾／鹰徽士兵列），**已被上面那份 DLC 贴图整文件覆盖**，
> 游戏里看不到。踩过一次：只看原版基础目录 → 误判成「德国入口没有肖像」。

**风格概述**（供文字描述用，具体以参照图为准）：

- 中心是**黑白灰阶的人物半身像**（头肩像，摄影／雕刻质感，不彩色）；
- 外面套一圈**彩色装饰框**，各人不同：紫色月桂环、菱形金边牌、金色圆环等（菱形与圆环大致按"党内职位"分组）；
- **下方还有一件专属小徽章或道具**（例如盾牌徽记、砖块、鹰剑盾、金色喇叭、列柱门廊、金色门楼之类）——
  也就是「一个人物 + 下面有装饰」的版式；
- 高对比、四角暗角、整体偏暗。

**已转好的 PNG 参考**（可直接给 AI 看）：
`docs/reference/images/sheet_ger_entry_real.png` 以及同目录 `real_asc_*.png` / `real_pc_*.png`

### 2.2 其余国策（17 张）→ 苏联国策图标式

```
参照目录：F:\Hearts of Iron IV\gfx\interface\goals\
  focus_SOV_the_supreme_soviet.dds
  focus_SOV_builder_of_the_red_army.dds
  focus_SOV_the_path_of_marxism_leninism.dds
  focus_SOV_socialism_in_one_country.dds
  focus_SOV_ally_bukharinists.dds
  focus_SOV_ally_zinovyevists.dds
  focus_SOV_organize_wreckers.dds
  focus_SOV_breadbasket_of_the_union.dds
  focus_SOV_military_purge.dds
  focus_SOV_the_last_purge.dds
  focus_SOV_approach_tukahchevsky.dds
  focus_SOV_the_comecon.dds
```

R56 追加参照（可选）：`D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\interface\goals\sov\`
（如 `r56_goal_SOV_trotsky_victory.dds` 就是托洛茨基本人的同风格肖像）

**风格概述**：

- **深暗血红的圆形底盘**（个别盾形）；
- 外圈一圈**金色月桂环**（两枝，顶部留口）；
- 主体是**象牙白 / 石膏灰的单色雕塑质感**（不是彩色），有清晰刻线阴影；
- 常有**一颗红星**在上方，或背后一面**红旗**；底部常有**金色绶带**；
- 左上打光、强暗角、高对比、低饱和。

> 🚩🚩 **2026-09-20 追记（这条规格的实际执行情况）**：
> **上面「主体是象牙白 / 石膏灰的单色雕塑质感（不是彩色）」这一条，从 `docs/46` 之后【事实上没再被执行】**
> —— 那之后每份出图文档改用**逐张指定的「色调」列**，`docs/49`（拉狄克）还把它升级成一条明暗 / 冷暖曲线。
> **实测**（中心区「非金 / 非红 / 非中性灰」像素占比）：托洛茨基 **1.1 %** → 拉狄克 **18.9 %** / 斯米尔加 **17.5 %**。
> → 📌 **本条规格【已被 `docs/23`「判据 G」取代】**：
> **色调只能来自「画面里那个东西本身的颜色」**（本条原意是「不许给整张图上色」，判据 G 是同一件事的可判定版本）。
> ⚠️ **只对尚未设计的线生效** —— **已交付的 11 条【不返工】**。
> 📖 完整实测与结论：`docs/70` §2.2。

**已转好的 PNG 参考**：`docs/reference/images/sheet_sov_style.png`

> ✅ 实测确认：这批苏联图标**没有** DLC 覆盖版，上面路径就是游戏里看到的那份。
> （另有一个 `gfx\interface\career_profile\profile_pictures\goals\` 下的副本，与出图无关。）

---

## 3. 要出的图（共 24 张 = 7 入口 + 17 托洛茨基专属）

> **效果列的中文说明**：`+X%` 表示"提高 X%"，`−X%` 表示"降低 X%"，都是**民族精神带来的长期加成**；
> 脚本原文见 `docs/22` §8.2，词条对照见本文档 **附录 A**。

### 3.1 入口国策 ×7（用 §2.1 的德国肖像式）

| # | 焦点 id | 中文名 | 花销 | 效果（现状） |
| --- | --- | --- | --- | --- |
| 1 | `hof_ic_seat_lev_trotsky` | 列夫·托洛茨基 | 2（=14 天） | 让托洛茨基入席（写标记 `hof_ic_seat_lev_trotsky`） |
| 2 | `hof_ic_seat_nikolay_bukharin` | 尼古拉·布哈林 | 2 | 让布哈林入席 |
| 3 | `hof_ic_seat_aleksey_rykov` | 阿列克谢·李可夫 | 2 | 让李可夫入席 |
| 4 | `hof_ic_seat_grigory_zinovyev` | 格里戈里·季诺维也夫 | 2 | 让季诺维也夫入席 |
| 5 | `hof_ic_seat_lev_kamenev` | 列夫·加米涅夫 | 2 | 让加米涅夫入席 |
| 6 | `hof_ic_seat_ivan_smirnov` | 伊万·斯米尔诺夫 | 2 | 让斯米尔诺夫入席 |
| 7 | `hof_ic_seat_leonid_serebryakov` | 列昂尼德·谢列布里亚科夫 | 2 | 让谢列布里亚科夫入席 |

> ⚠️ **现状**：这 7 个目前**只写入席标记**，**还没有给政治点、也没有给民族精神**。
> 按德国样板，入口国策应当额外附赠该角色的人物精神（精神里带 `政治点获取 −10%` 作为"入圈代价"+
> 他的专长加成）—— 这部分**属 S3 二期，尚未实现**，详见本文档 §5 待办。

**出图时**：把人物**半身像**放进装饰框即可，下方装饰件按各人史实职务选。

| 人名 | 史实职务（供选装饰件参考） |
| --- | --- |
| 列夫·托洛茨基 | 陆海军人民委员 / 革命军事委员会主席 / 最高国民经济委员会主席 |
| 尼古拉·布哈林 | 《真理报》《消息报》主编 / 共产国际执委会主席 / 1936 年宪法起草人 |
| 阿列克谢·李可夫 | 苏联人民委员会主席（1924–30）/ 最高国民经济委员会主席 |
| 格里戈里·季诺维也夫 | 共产国际**首任**执委会主席 / 列宁格勒苏维埃主席 |
| 列夫·加米涅夫 | 全俄中央执行委员会**首任**主席 / 人民委员会副主席 / 莫斯科苏维埃主席 |
| 伊万·斯米尔诺夫 | **首任苏联邮电人民委员**（1923-07-06 – 1927-11-12）⚠️ / 西伯利亚革命委员会主席 / 第五集团军革命军事委员会委员<br>⚠️ **2026-09-17 订正**：原先写「首任邮电人民委员」**说错了层级** —— 1917 年那任**俄罗斯联邦级**的历任名单里没有他（见 [`docs/38`](38-smirnov-genealogy.md) §4） |
| 列昂尼德·谢列布里亚科夫 | 中央书记处书记 / 公路与汽车运输总局局长 / **车工出身** |

> ⚠️ 人物立绘本 mod 已有（复用 R56 / DLC 的 156×210 头像）。出图时以**同一张脸**为准，不要另画长相。

### 3.2 托洛茨基专属国策 ×17（用 §2.2 的苏联式）

> 📌 **本节是纯美术简报，故意不写效果数值。**
> 效果一律以 **`docs/22` §8.2.4** 为唯一权威 —— 在这里再抄一遍就会漂移。
>
> **「文案」就是游戏里实际显示的国策描述原文**，出图方据此自定画面即可；
> 「引导」只是意象提示，**可自由发挥或不采用**。
>
> ⚠️ **2026-09 数值已大改**：17 条国策**一律不再各自挂民族精神**。
> 托洛茨基全程只有 **1 个**职务特质，靠 `swap_ideas` 升级 2 次
> （陆海军人民委员 → 革命军事委员会主席 → 共产国际执委会主席 / 人民委员会副主席）。
> 旧版每条约一行「精神 → 某某加成」的写法**已作废**。
> 依据见 `docs/11` §4.1（德国数值宪法）。

#### 支线 I · 红军缔造

**`hof_ic_trotsky_build_the_red_army` ｜ 缔造红军**
- **文案**：这辆军用专列曾经是他的战地指挥部。在那决定命运的 3 年里，他乘坐这辆专列沿着 8000 公里的前线行进，哪里危险就冲向哪里，只有短暂的磋商或者出席莫斯科的公众集会才暂时打断他的行程。
- 引导（可不用）：装甲指挥列车、铁轨、红星、成列的红军士兵。

**`hof_ic_trotsky_military_specialists` ｜ 返聘沙俄军官**
- **文案**：1919 年初，他断然反对逮捕查京将军。他写道，查京帮助苏维埃所做的工作比那些关押他的人还多，蛮横地对待这样的人则会对军官的士气具有灾难性的影响。他要求释放将军，并愿在法庭给他定罪前亲自为他作保。
- 引导（可不用）：旧式军官大檐帽、肩章、参谋地图。

**`hof_ic_trotsky_against_partisan_warfare` ｜ 反对游击主义**
> ★ **此国策触发职务升级 T2**（→ 革命军事委员会主席），出图时值得比同支线其他两张更- **文案**：正如托洛茨基所指出的，游击战的混乱反映了革命下面的农民因素，而反对它的斗争同样是为了支持无产阶级国家组织，以抵制正在瓦解它的元素化的小资产阶级无政府状态。绝大部分的军队新兵都是农民，整个国家是一片起义的农民海洋，对于这种战争方式，他们不仅有着传统，而且本能地适应。
- 引导（可不用）：制式步枪与队列，对比散乱的农民武装。

#### 支线 II · 理论

**`hof_ic_trotsky_uneven_and_combined_development` ｜ 不平衡与综合发展律**
- **文案**：在一些情况下，从一开始就领先者可以加强其领先地位，而在另一些情况下，同样地由于发展的步调不同，一些落后者可以赶上甚至超过那些先前享有优势者。
- 引导（可不用）：发展不均的地球／阶梯、追赶的箭头。

**`hof_ic_trotsky_permanent_revolution` ｜ 不断革命论**
- **文案**：在狱中，他完成了对俄国革命的见解——不断革命论。认为俄国的民主革命必然要由工人阶级来领导，以无产阶级专政来完成，并由此发展成社会主义革命。其奠基性的表述最初出自马克思，1906 年由托洛茨基针对俄国的情况重新加以表述，随后又在 1928 年进一步阐发。
- 引导（可不用）：火炬、环环相扣的连续箭头。

**`hof_ic_trotsky_socialism_in_one_country` ｜ 驳「一国社会主义」**
- **文案**：斯大林的一国社会主义论，被他斥为放弃世界革命的借口。1926 年，他与昔日的对手季诺维也夫、加米涅夫联手组成联合反对派，主张党内民主与经济计划化，谴责领导层对资产阶级分子的让步。这场争论持续了约 18 个月。
- 引导（可不用）：被打破的边界／孤岛、向外的火焰。

#### 支线 III · 党内民主

**`hof_ic_trotsky_the_new_course` ｜ 新方针**
- **文案**：1923 年 10 月，他致信中央委员会提出广泛批评，特别强调党内民主遭到破坏、经济计划化不足。改革被承诺了，他随即以一封公开信详细说明改革应取的方向。而此后党组织在压制它的主要批评者时，其猛烈和狂怒在党内反对派的漫长历史上是前所未有的。
- 引导（可不用）：党纲文件、钢笔、举手表决。

**`hof_ic_trotsky_against_the_bureaucracy` ｜ 反对官僚化**
- **文案**：无产阶级专政将通过政党夺取政权而建立，托洛茨基认为这个政党在革命中起领导作用。但是，他警告说，一旦它的任务完成，这样的党要提防用自身代替无产阶级或是支配无产阶级。
- 引导（可不用）：公文堆、印章，与工人之手。

#### 支线 IV · 经济

**`hof_ic_trotsky_limited_market_reforms` ｜ 有限市场化**
- **文案**：内战结束后，他把注意力转向俄国的经济重建。他首先提议放松战时共产主义严苛的集中制，允许市场力量运作。这个提议被否决之后，他才转而尝试把军事纪律应用于经济。
- 引导（可不用）：天平，一端工业一端农业／市场。

**`hof_ic_trotsky_labour_armies` ｜ 劳动军** ⚠️ **这是"给得更差"的那一条**
- **文案**：他转而尝试把军事纪律应用于经济：把士兵用作劳动军，并试图把交通运输系统的管理军事化。这个方向同样被党的十大否决，此后连他自己也不再主张它。
- 引导（可不用）：镐与锹、军帽、铁路。
- 📌 **设计说明**：史实上这条是 ❌ **不能算贡献**的方向（1921 年十大被否，他自己也放弃了）。
  所以做成**可与"有限市场化"互斥、且明显更差**的选项 —— 用数值表达历史评价，而不是删掉它。

**`hof_ic_trotsky_state_planning` ｜ 经济计划化**
- **文案**：他要求扩大国家计划委员会的权力，而李可夫和索柯里尼柯夫则怀疑计划性，公开指责他之所以要求扩大国家计划委员会的权力只是因为他觊觎它的领导权。他所作的报告和所提交的『提纲』是苏联经济史上最关键的文件，他在其中描绘了今后几十年的苏联经济远景。
- 引导（可不用）：计划图表、曲线、计算尺。
- 📌 **前置是「有限市场化 或 劳动军」任一即可** —— 两次尝试失败哪一次都行，最终都会走到"计划化"这个真正的贡献上。

**`hof_ic_trotsky_accelerated_industrialization` ｜ 加速工业化**
- **文案**：国家的大粮库有一半已见了底，城市居民面临着饥饿的威胁，连军队的给养都不充足，面包店外排着长队，面包价格不断上涨。正是在这样的处境下，联合反对派要求加快工业化、反对向富农让步。1928 年，斯大林开始了第一个五年计划。
- 引导（可不用）：高炉、烟囱、向上箭头。

#### 支线 V · 国际

**`hof_ic_trotsky_the_comintern_manifesto` ｜ 共产国际宣言**
- **文案**：1919 年 3 月，他与列宁共同创立第三国际，并撰写了它的首篇宣言。
- 引导（可不用）：地球、环绕的红旗、喇叭。

**`hof_ic_trotsky_the_chinese_question` ｜ 中国革命问题**
- **文案**：1927 年春天，党内斗争的火焰又一次燃烧起来。这次斗争是同到那时之前从未提出过的一个问题相联系的，但从此以后这个问题却自始至终都是斗争的中心，直到联合反对派最终被开除出党并解体为止。
- 引导（可不用）：中国城门／长城、铁路、旗帜。
- 📌 **前置是「共产国际宣言」+「反对官僚化」两个都要** —— 这是全树唯一一处跨支线连接，
  因为史实上 1927 年中国革命问题**同时**是国际问题和党内斗争的中心问题。

**`hof_ic_trotsky_united_front` ｜ 反法西斯统一战线**
- **文案**：第三国际不顾托洛茨基自 1930 年以来不断的警告，大大低估了纳粹党的危险性，同时拒绝社会民主党建立统一战线对抗纳粹，结果使德国工人阶级的组织毫无抵抗地被粉碎，并使法西斯势力横行十余年。
- 引导（可不用）：不同国家的工人帽并列、折断的剑。

#### 汇合层 ×2（**互斥**，二选一）

**`hof_ic_trotsky_the_permanent_revolutionary` ｜ 永久的革命者**（走向**国际革命**）
- **前置**：五条支线的末端节点**任走通 3 条**即可
> ★ **此国策触发职务升级 T3a**（→ 共产国际执行委员会主席）
- **文案**：要求我放弃政治活动，意味着要求我放弃为全世界工人阶级利益而进行的斗争，而这一斗争我已孜孜不倦地进行了 32 年之久，也就是我自觉生命的全部时间。只有腐朽透顶的官僚集团才会要求做出这种放弃，只有卑鄙的叛徒才能做出这种承诺。
- 引导（可不用）：举火炬行进的人、红旗、循环箭头。

**`hof_ic_trotsky_the_builder_of_the_state` ｜ 国家建设者**（走向**国内建设**）
- **前置**：同上
> ★ **此国策触发职务升级 T3b**（→ 人民委员会副主席）
- **文案**：请告诉我还有哪个人能在一年之内建立起一支堪称模范的军队而且赢得军事专家的尊重；我们有这样的人，就有了一切，我们将创造出奇迹。
- 引导（可不用）：塔吊与钢架、锤与尺、蓝图。

---

## 4. 命名与落盘

**命名规则（1:1 对齐焦点 id，免维护映射表）**：

```
sprite 名  =  "GFX_" + 焦点 id
PNG 文件名 =  sprite 名 + ".png"
```

| 焦点 id | sprite 名 / PNG 名 |
| --- | --- |
| `hof_ic_seat_lev_trotsky` | `GFX_hof_ic_seat_lev_trotsky` |
| `hof_ic_trotsky_permanent_revolution` | `GFX_hof_ic_trotsky_permanent_revolution` |

与已有 sprite 家族不冲突：立绘 `GFX_hof_ic_portrait_<角色键>`（156×210）、
席位框 `GFX_hof_ic_slot_<N>_portrait`、窗口装饰 `GFX_hof_ic_<用途>`。

**接入三步**（我方负责）：

1. PNG → DDS（ARGB8、无 mipmap），放入 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`；
2. 在 `interface/hof_icons.gfx` 注册 24 个 `spriteType`；
3. 把 `build/inject-sov-seats.txt` 与 `docs/22` §4 里的占位图标换成上表 sprite 名 →
   重跑 `gen-hof-ic-s3.ps1` → `sync-from-r56.ps1` → `verify-s2.ps1`（失败项须为 0）。

---

## 5. ⚠️ 待办 / 风险

- [ ] **sprite 名尚未注册**（本文档是设计值）。注册前按 AGENTS 规则 7 核重名：
      不与 `common/national_focus/soviet.txt` 已有 `icon =` 冲突，也不与 R56 / 原版的 `interface/*.gfx` 重名。
- [x] ✅ **`政治点获取 −10%` 的叠加问题 —— 已解决（2026-09）**：原方案给每条托洛茨基国策的
      精神都加 `political_power_gain = -0.1`，全走完会叠到 **−170%**。
      现已按德国实测模型重写：**17 条国策一律不再挂精神**，托洛茨基全程只有 **1 个**职务特质
      （`political_power_gain` 入口 −0.10 → 二级起 −0.30，共 2 次升级）。
      见 `docs/22` §8.2、`docs/11` §4.1。
- [x] ✅ **`political_power_factor` 与 `political_power_gain` 混用 —— 已解决**：
      新方案**只用 `political_power_gain`**（德国实测词条），`political_power_factor` 已从托洛茨基线中剔除。
- [ ] 🚩 **T3a「共产国际执行委员会主席」是 alt-history**（史实上季诺维也夫/布哈林担任），
      **需要你确认** —— 见 `docs/22` §8.2.1 的说明。若砍掉，汇合A 与汇合B 的强度会不对称。
- [ ] 7 个入口国策目前**只给人物 idea，还没有个人 `dynamic_modifier`**（S3 二期待做）。
      按 `docs/11` §4.2：数值体应挂在 `hof_ic_<key>_dm` 上，由个人线国策 `add_to_variable` 累积。
- [ ] `hof_ic_remove_slot_N_idea` 必须**逐层试遍 4 个特质 id**（T1 / T2 / T3a / T3b），
      否则他升过级后被替换会残留精神 —— 见 `docs/22` §8.2.2 的实现红线。
- [ ] 出图顺序建议：先出 **2~3 张样图**（1 张入口 + 1 张专属）确认风格，定稿后批量。
- [ ] 其余 6 人的专属国策图标尚未设计（他们的国策树还没做，见 `docs/23` SOP）。
      每人预留 `1 入口 + 3~5 专属`，风格沿用本文档两套。

---

## 附录 A · 词条中文速查（读脚本用）

> **数值**（哪条国策给多少）见 **`docs/22` §8.2.4** —— 那是唯一权威。
> 本附录只是**词条 → 中文**的字典，顺带标出哪些经实测**不存在**。
> 实测原始数据：`reference/reports/military-modifier-words.txt`（68 个候选逐个扫过 R56 + 原版）。

### A.1 国策效果类写法

> ⚠️ **托洛茨基的 17 条个人线国策现在一条都不用这些**（它们只写 `add_to_variable`，
> 见 `docs/22` §8.2.3）。保留此表是为了读**别条线 / R56 原树**的脚本时能对照。

| 脚本写法 | 中文 |
| --- | --- |
| `add_political_power = N` | 立即获得 **N 政治点** |
| `add_popularity = { ideology = communism popularity = X }` | 共产主义支持率 **+X%** |
| `add_tech_bonus = { name = … bonus = 1 uses = 1 category = industry }` | **工业类**科技：研究进度 **+100%**（**1 次**） |
| `add_extra_state_shared_building_slots = 2` | 全国各州共享建筑位 **+2** |
| `add_building_construction = { type = industrial_complex level = 2 instant_build = yes }` | **立即建成** 1 座 **2 级民用工厂** |
| `add_to_variable = { <变量> = 0.05 }` | **往变量加 0.05**（当前核心圈仅作国策数值提示账本；实际修正见静态职务 idea，`docs/99` §73） |

### A.2 军事 —— 进攻 / 防御

| 脚本写法 | 中文 |
| --- | --- |
| `army_attack_factor` | 陆军进攻 |
| `army_defence_factor` | 陆军防御 |
| `army_core_attack_factor` | 核心领土进攻 |
| `army_core_defence_factor` | 核心领土防御 |
| `breakthrough_factor` | 突破 |
| `army_artillery_attack_factor` | 炮兵进攻 |
| `army_artillery_defence_factor` | 炮兵防御 |
| `max_dig_in_factor` | 最大堑壕 |
| `dig_in_speed_factor` | 挖壕速度 |
| `cas_damage_reduction` | 近距空中支援伤害减免 |
| `surrender_limit` | 投降上限 |
| `max_surrender_limit_offset` | 最大投降上限偏移 |
| `army_armor_attack_factor` | 装甲单位攻击 |
| `army_armor_defence_factor` | 装甲单位防御 |
| `army_armor_speed_factor` | 装甲单位速度 |
| `combat_width_factor` | 己方战场宽度（**负数 = 同样兵力占更多宽度**） |

**兵种级（🚩 真名带 `modifier_` 前缀）**

| 脚本写法 | 中文 |
| --- | --- |
| `modifier_army_sub_unit_infantry_attack_factor` | 步兵进攻 |
| `modifier_army_sub_unit_infantry_defence_factor` | 步兵防御 |
| `modifier_army_sub_unit_cavalry_attack_factor` | 骑兵进攻 |
| `modifier_army_sub_unit_cavalry_defence_factor` | 骑兵防御 |
| `modifier_army_sub_unit_cavalry_speed_factor` | 骑兵速度 |
| `modifier_army_sub_unit_militia_attack_factor` | 民兵进攻 |
| `modifier_army_sub_unit_militia_defence_factor` | 民兵防御 |
| `modifier_army_sub_unit_militia_max_org_factor` | 民兵最大组织度 |
| `modifier_army_sub_unit_mountaineers_attack_factor` | 山地兵进攻 |
| `modifier_army_sub_unit_mountaineers_defence_factor` | 山地兵防御 |
| `modifier_army_sub_unit_marine_attack_factor` | 陆战队进攻 |
| `modifier_army_sub_unit_paratrooper_attack_factor` | 伞兵进攻 |
| `modifier_army_sub_unit_irregular_infantry_attack_factor` | 非正规步兵进攻 |
| `modifier_army_sub_unit_armored_car_attack_factor` | 装甲车进攻 |

> 🚩 **踩过的坑**：写成 `army_sub_unit_infantry_attack_factor`（**少 `modifier_` 前缀**）
> **游戏里根本不存在的词条**，**不报错、完全不生效**。已逐个实测确认。

### A.3 军事 —— 组织 / 补给 / 损耗

| 脚本写法 | 中文 |
| --- | --- |
| `army_org_factor` | 陆军组织度 |
| `army_morale_factor` | 陆军士气 |
| `army_org_regain` | 组织度恢复 |
| `supply_consumption_factor` | 补给消耗（**负数 = 变好**） |
| `out_of_supply_factor` | 缺补给影响（**负数 = 变好**） |
| `attrition` | 损耗（**负数 = 变好**） |

### A.4 军事 —— 训练 / 动员 / 经验 / 学说

| 脚本写法 | 中文 |
| --- | --- |
| `training_time_factor` | 训练时间 |
| `conscription_factor` | 征兵系数 |
| `conscription` | 征兵率（**绝对值**，如 `0.01`） |
| `mobilization_speed` | 动员速度 |
| `special_forces_cap` | 特种部队上限 |
| `equipment_capture_factor` | 装备缴获 |
| `experience_gain_army_factor` | 陆军经验获取 |
| `land_doctrine_cost_factor` | 陆军学说花费 |
| `military_leader_cost_factor` | 将领花费 |
| `command_power_gain_mult` | 指挥点数获取 |
| `max_command_power` | 最大指挥点数（**绝对值**，如 `20`） |

### A.5 工业 / 科研

| 脚本写法 | 中文 |
| --- | --- |
| `research_speed_factor` | 科研速度 |
| `industrial_capacity_factory` | 工厂产出 |
| `consumer_goods_factor` | 消费品需求（**负数 = 变好**） |
| `production_speed_buildings_factor` | 建筑建造速度 |
| `production_speed_industrial_complex_factor` | 民用工厂建造速度 |
| `production_speed_arms_factory_factor` | 军工厂建造速度 |
| `production_factory_max_efficiency_factor` | 工厂最大生产效率 |
| `production_factory_efficiency_gain_factor` | 工厂生产效率增长 |
| `line_change_production_efficiency_factor` | 换线生产效率惩罚（**负数 = 变好**） |
| `conversion_cost_civ_to_mil_factor` | 民用转军工花费（**负数 = 变好**） |
| `local_resources_factor` | 本地资源产量 |
| `global_building_slots_factor` | 建筑位（全局，各州可多建工厂） |

### A.6 政治 / 国际

| 脚本写法 | 中文 |
| --- | --- |
| `political_power_factor` | 政治点获取 |
| `political_power_gain` | 政治点获取（**另一个词条**；德国角色 idea 用的是这个） |
| `stability_factor` | 稳定度 |
| `war_support_factor` | 战争支持度 |
| `communism_drift` | 每日共产主义支持漂移 |
| `drift_defence_factor` | 意识形态漂移抵抗 |
| `political_advisor_cost_factor` | 政治顾问花费 |
| `opinion_gain_monthly_factor` | 各国好感月增长（**不含同意识形态**那条） |
| `send_volunteer_factor` | 派遣志愿军规模 |
| `opinion_gain_monthly_same_ideology_factor` | 同意识形态国家好感月增长 |
| `operative_slot` | 特工位（**绝对值**，如 `1`） |
| `subversive_activites_upkeep` | 颠覆活动维持费 |
| `boost_ideology_mission_factor` | 意识形态宣传任务效果 |

### A.7 ❌ 实测不存在 —— **不要写**

以下词条在 R56 + 原版的 `common/ideas`、`common/dynamic_modifiers`、`common/scripted_effects`
里**一次都没出现过**。写了不会报错，只会静默无效。

| 词条 | 常见误用场景 |
| --- | --- |
| `division_attack_factor` | 想写"师级进攻" |
| `armor_attack_factor` | 想写"装甲进攻"（**正解是 `army_armor_attack_factor`**） |
| `combat_width` | 想写"战场宽度"（**正解是 `combat_width_factor`**） |
| `army_sub_unit_infantry_attack_factor` 等**无 `modifier_` 前缀**的兵种词条 | 想写"兵种级加成"（**正解带 `modifier_` 前缀**，见 A.2） |
| `army_logistics_factor` | 想写"后勤" |
| `general_cost_factor` | 想写"将领花费"（**正解是 `military_leader_cost_factor`**） |
| `research_speed_factor_land` | 想写"陆装科研" |
| `breakthrough_progress_factor` | 想写"突破进度" |
| `mobile_equipment_concentration` | 想写"摩托化集中度" |
| `efficiency_growth_factor` | 想写"效率增长" |

> 数值含义：`+0.05` = **+5%**，`−0.10` = **−10%**；
> 标"绝对值"的（`conscription`、`operative_slot`、`max_command_power`）不是百分比。
>
> 📌 **两个政治点词条的分工（刻意，不是混用）**：
> **职务 idea 用 `political_power_gain`**（照德国角色 idea 的"入圈代价"写法）；
> **个人线奖励用 `political_power_factor`**，计入当前职务 idea 的静态版本（见 `docs/99` §73）。
> 两个词条分别表示每日政治点数值与政治点获取比例，不能互相替换。

### A.8 效果型写法（不是 modifier，是 `completion_reward` 里的动作）

| 脚本写法 | 中文 | 实测出处 |
| --- | --- | --- |
| `add_skill_level = N` | 将领**技能等级 +N** | `common\decisions\r56_POL_decisions.txt` |
| `add_attack = N` / `add_defense = N` / `add_logistics = N` | 将领**攻击 / 防御 / 后勤属性 +N** | 同上 |
| `add_trait = { trait = X }` | 给将领加特质 | 同上 |
| `add_unit_leader_trait = trait_X` | 同上（另一种写法） | `common\decisions\BUL.txt` |
| `add_opinion_modifier = { modifier = X target = Y }` | 给某国加好感修正 | `common\national_focus\soviet.txt` |
| `add_to_variable = { <变量> = 0.05 }` | 往变量加值（个人累积用） | `docs\11` §4.2 |

**`opinion_modifier` 的定义块**（建在 `common\opinion_modifiers\*.txt`）：

```text
opinion_modifiers = {          # ← 外面这层包裹不能漏，漏了静默无效
	hof_ic_chinese_question = {
		value = 50
	}
}
```

可选字段（原版 `nsb_opinion_modifiers.txt` 头部注释）：
`min_trust` `max_trust` `decay` `months` / `years` / `days`（限时）`trade = yes/no`。

**将领特质的定义位置**：`common\unit_leader\*.txt`
（R56 的 `trait_SOV_trotskyist` 在 `NSB_traits.txt`）。
🚩 **不新建定义文件、直接写特质名 = 静默失效。**

### A.9 三个名词别混

| 名词 | 是什么 | 在树里的角色 |
| --- | --- | --- |
| **入口国策** | `hof_ic_seat_*` ×7，花销 2 | 把某个人"选进"最高苏维埃 |
| **个人线（专属国策）** | 以他为前置的一串小国策，花销都是 2 | 他的理论/功绩，逐条**往他身上叠数值**（见 `docs/11` §4.2） |
| **汇合层** | 支线末端合流后的 2 个互斥结局，y=20 | 五条里走通 3 条即可解锁，给**两倍量级**的特质数值 |

---

## 6. 相关文件

| 文件 | 作用 |
| --- | --- |
| `docs/12-icon-list.md` | 图标规格与全局命名规范（§1.1 有 DLC 覆盖陷阱） |
| `docs/22-trotsky-focus-tree-design.md` | 托洛茨基国策树设计（焦点 id / 脚本数值 / 描述文本原文） |
| `docs/23-figure-focus-playbook.md` | 写人物国策线的 8 步 SOP |
| `docs/reference/tools/dds2png-real.py` | **把生效版德国入口图标转 PNG**（含 DLC 覆盖判定） |
| `docs/reference/tools/make_sov_sheet.py` | 生成苏联风格参考拼图 |
| `docs/reference/images/` | 转好的参考 PNG |
