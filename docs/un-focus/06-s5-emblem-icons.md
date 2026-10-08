# 06 · S5 图标：真图接入 + 民族精神版（v1 · 2026-09-20）

> 上游：`01-s5-mutual-aid-common-lines.md`（结构）· `02-s5-values.md`（数值）· `03-s5-icon-prompts.md`（出图提示词）
> 代码：`build/gen-hof-ma-icons.ps1`（注册）· `build/gen-hof-ma-idea-icons.py`（出方形图）
> 自检：`build/verify-s2.ps1` **§14**（9 项）

---

## §0 用户口径（本文的立文依据）

> 「**图标你不是找到了一些历史机构或者会议的图标吗，抽成透明图然后缩小成可以使用的版本不就好了**」
> 「**经互会和华约的不用，游戏内不是已经有了**」

⇒ **三条原则**：
1. **游戏里已经有的，直接用游戏自己的**（不再重复抠图）—— 经互会 / 华约 / 马列思想 三张。
2. **游戏里没有的，才去抠实物**；能抠到几张就上几张。
3. 「**其余没有可用自由文件**」这句话**当时说错了** —— 真实原因是两件事：
   ① 我那一轮 Commons 搜索**被限流（HTTP 429）**，返回的是无关结果，**根本没搜干净**；
   ② 那些徽标多数是**本地维基的「合理使用 / 非自由」文件**（不在 Commons），
      必须去 `zh.wikipedia.org` / `en.wikipedia.org` 而不是 `commons.wikimedia.org` 取。
   ⇒ 改用 **`prop=images` 列出条目里【所有】图片**（不是只看首图）＋ 逐个查 `LicenseShortName`，
      这一轮就多挖出 **4 张**（工人局 / 世界工联 / OIRT / 欧安会）。
> 「**什么叫做非自由，不允许用作其他用途还是什么，cc 协议？**」
> 「**保持现状，我们这是社区 mod 又不收费，没有商用风险，一般也不存在侵权风险，
> 再说了这些机构大多数不都解散几百万年了，哪来的侵权机构**」

⇒ **第 4 条原则（许可口径 · 2026-09-20 用户裁决【甲】）**：
**保持现状** —— 3 张**非自由（合理使用 / Fair use）**图**继续使用**，
理由 = **社区 mod · 不收费 · 无商用风险 · 机构多已解散**。
⚠️ **但「如实登记」不能省**：§2.2.1 是这批图的**许可实况**，
⛔ **不许在别处写「来源合规」** —— 「合理使用」**不是授权**，只是「维基百科自己在用」。

---

## §1 现状总账（`verify-s2` §14f 每次都会重报这张表）

> ⭐ **2026-09-25 口径订正**：用户「**经互会和华约的不是已经有了吗，游戏内自带，莫洛托夫条约也不用重新画就用那个吧**」
> ⇒ 国策里那 **3 张原版 sprite**（经互会 / 华约 / 马列思想）已从「占位」**升为「定案用图」**，
> **不再计作待办**；idea 层也顺推（经济/军事线的 idea 直接用那两张的方形版，见 `03` §0.2）。
> ⏳ **真正还等美术的 = 13 张**（政治线 10 张国策图 + 3 张政治线 idea 的方形图，逐张提示词见 `03` v3）。

| 类 | 有真图的 | 总数 | 说明 |
| --- | --- | --- | --- |
| **国策图标** | **13 / 16** | 引用 16 张 sprite | **3 张原版已有**（经互会 / 华约 / 马列思想）—— ⭐ **已定案，不是占位** ＋ **13 张本 mod 抠的实物**（第一批 `cominform` `wftu` `oirt` `osce` `ius` ＋ **第二批** `wfdy` `widf` `ioj` `ibec` `iib` `druzhba` `intermetall` `wpc`）|
| **机构 idea（可见民族精神）** | **6 / 7** | 14 个 idea 用到 7 张不同的 picture | 6 张有真图：经互会 / 华约 / **情报局** / **国际广播组织** / **赫尔辛基最后文件** / **世界和平理事会**（毕加索的鸽子）；⭐ **经济 / 军事线的 idea 已全部套用那两张的方形版**（2026-09-25）|
| **动态民族精神** | **3 / 3** | 3 张 | 三条线各一张，同上 |

⏳ **仍等美术的只有政治线**：**10 张国策图 + 3 张 idea 方形图** —— 逐张清单见 `03` v3 §4 / §5。

⛔ **零缺图**：§13f 会逐条验「国策引用的每个 sprite 在原版**或**本 mod 都有定义」。

---

## §2 已接入的图（逐张出处）

### §2.1 沿用【游戏自带】的四张（不动）

| 用在哪 | sprite | 原版贴图 | 规格 |
| --- | --- | --- | --- |
| 头（莫洛托夫计划） | `GFX_focus_SOV_the_path_of_marxism_leninism` | `gfx/interface/goals/focus_SOV_the_path_of_marxism_leninism.dds` | 100×88 |
| 经济线 23 个 | `GFX_focus_SOV_the_comecon` | `…/focus_SOV_the_comecon.dds` | 100×88 |
| ~~政治线 19 个~~ | ~~`GFX_goal_support_communism`~~ | ⚠️ **2026-09-20 后半段**已换成 `GFX_hof_ma_cominform`（本 mod 抠的实物，见 §2.2） | — |
| 军事线 17 个 | `GFX_focus_SOV_found_the_warsaw_pact` | `…/focus_SOV_found_the_warsaw_pact.dds` | 100×88 |

📌 **反查方法**（记下来）：拿**用户报的中文名**去原版本地化搜国策键 → 用国策键在原版
`common/national_focus/*.txt` 找 focus 块 → 读它的 `icon =`。
⛔ **不要凭 sprite 命名习惯猜** —— 原版那个叫「共产国际」的国策用的是通用图 `GFX_goal_support_communism`，
`GFX_focus_SOV_the_comintern` **这个 sprite 不存在**。

### §2.2 本 mod 抠的**五张实物**（游戏里没有的）

| key | 用在哪（节点） | 来源文件 | 档 | 处理 |
| --- | --- | --- | --- | --- |
| **`cominform`** | ⭐ **政治线 18 个节点的默认图** + `hof_ma_pol_cominform` | zh.wikipedia `File:共产党和工人党情报局标志.jpg` | **C** | **红旗 + 黄色镰锤徽** ⇒ 圆形裁成徽章 |
| `wftu` | `hof_ma_pol_wftu`（世界工会联合会） | en.wikipedia `File:World Federation of Trade Unions logo.svg` | **C** | logo 本身已带透明底 ⇒ 直接 trim |
| `oirt` | `hof_ma_pol_oir`（国际广播电视组织） | en.wikipedia `File:OIRT-IRTO.logo.png` | **C** | 同上 |
| `osce` | `hof_ma_mil_csce`（全欧安全会议 1975） | Commons `Flag of the Organization for Security and Co-operation in Europe.svg` | **B** | ⚠️ **1991 年版旗，年代早于节点 16 年** —— 用户 2026-09-20 明确批准「**年代错那也可以用没事**」 |
| `ius` | `hof_ma_pol_ius`（国际学生联合会） | Commons `Flag of International Union of Students.svg` | **A** | 旗面 ⇒ 圆形裁成徽章 |

### §2.2.1 许可实况（2026-09-20 查 `imageinfo` 的 `extmetadata` 实测，不是印象）

**「非自由」的准确含义**：**它不是「不允许用作其他用途」这类限制条款，而是【根本没有授权】。**
维基百科的图分两桶 ——

| 桶 | 许可 | 含义 |
| --- | --- | --- |
| **自由文件**（都在 Commons） | 公有领域 PD · CC0 · CC BY · CC BY-SA | **权利人已预先给出授权**，任何人可复用（**CC BY / BY-SA 要署名**，**BY-SA 还要相同方式共享**） |
| **非自由文件**（只在本地维基） | **合理使用 / Fair use** | ⛔ **没有许可** —— 维基百科靠「**为了评论〈该条目〉这一目的**」使用它；**这个理由只对维基那一页成立，不传递给你** |

📌 **「CC 协议」≠「非自由」** —— CC 属于**自由**那一桶。所以问题不是「CC 里哪条更严」，
而是「**有 CC 就是有授权，写「合理使用」就是没授权**」。
📌 **还有第二层：这些是【机构徽标】，主要受商标权管，而不是纯著作权** ——
所以**连 PD 的欧安会旗也带 `trademarked`**：**著作权那一层能清干净，商标那一层清不掉**（除非不用这个徽标）。

**逐张实测（`LicenseShortName` / `NonFree` / `Restrictions` / `AttributionRequired`）**：

| key | 许可档 | `NonFree` | `Restrictions` | `AttributionRequired` | 权利人线索 |
| --- | --- | --- | --- | --- | --- |
| `cominform` | **合理使用**（非自由） | **true** | — | — | 出处 `ciml.250x.com`（共产国际档案站）；维基用途被限定为「仅用于〈共产党和工人党情报局〉」 |
| `wftu` | **Fair use**（非自由） | **true** | — | — | 维基备注原文 `Based on logo found on WFTU website` ⇒ **同时是该组织自己的商标** |
| `oirt` | **Fair use**（非自由） | **true** | — | — | 出处 `concours-eurovision.fr` |
| `osce` | **Public domain**（自由） | — | ⚠️ **trademarked** | false | 1991 年版旗 |
| `ius` | **CC BY-SA 4.0**（自由） | — | — | ⚠️ **true** | Commons 上传者 `Own work` |

⭐ **唯一一条【本来就有强制义务】的是 `ius`（CC BY-SA 4.0 要署名）** ——
**署名文本（备用；要放进 mod 致谢处时说一声即可）**：
> 国际学生联合会旗徽 —— 维基共享资源，**CC BY-SA 4.0**（原始上传者声明 `Own work`），
> 本项目做了裁圆 + 缩放处理。

⛔ **其余四张没有可用署名要素**（非自由文件不适用署名；公有领域不要求署名）。

> ⚠️ **曾经做过、已按用户口径撤掉的**：经互会旗徽 / 华约徽 / 共产国际徽 ——
> 游戏里本来就有对应的国策图，重复做是浪费，且会让同一机构在国策与精神格里长得不一样。

### §2.3 民族精神（方形）版

> ⚠️ **不是只有「从原版图裁方」一种来源** —— 表里既有**原版图裁方**，也有**用本 mod 抠的实物缩的**。
> 判定谁用哪张 = 生成器里的 **`$picReal`** 映射表（`hof_ma_idea_*` → picture 名）。

> 用户口径里的「**有民族精神的要做民族精神的版本**」= 同一个机构，
> **国策里那张是 100×88 的横图，民族精神格里要用 60×60 的方图**。

`build/gen-hof-ma-idea-icons.py` 做这件事（机制性、可重跑）：

| 民族精神版 sprite | 从哪张裁的 |
| --- | --- |
| `GFX_idea_hof_ma_comecon` | 原版 `focus_SOV_the_comecon.dds` |
| `GFX_idea_hof_ma_warsawpact` | 原版 `focus_SOV_found_the_warsaw_pact.dds` |
| `GFX_idea_hof_ma_cominform` | 外部实物（共产党和工人党情报局标志） |
| `GFX_idea_hof_ma_ius` | 外部实物（国际学生联合会旗徽） |
| **`GFX_idea_hof_ma_oirt`** | **外部实物**（国际广播电视组织 logo · 2026-09-21 加） |
| **`GFX_idea_hof_ma_osce`** | **外部实物**（欧安会旗 · 2026-09-21 加） |

**裁法**：居中取最大正方形 → 缩到 60×60；若裁完四角不透明，**退回**「等比装进 60×60 + 四周透明留白」。

**接到哪**：

| 位置 | 字段 | 值 |
| --- | --- | --- |
| 三个动态民族精神 | `icon =` | `GFX_idea_hof_ma_comecon` / `_cominform` / `_warsawpact`（按线取） |
| ⭐ **经济线的 4 个 idea**（comecon · division_of_labour · integration_programme · joint_research_org） | `picture =` | **`hof_ma_comecon`**（= 游戏自带经互会图裁方，**2026-09-25 新增**） |
| ⭐ **军事线的 4 个 idea**（warsaw_treaty · joint_command · nuclear_umbrella） | `picture =` | **`hof_ma_warsawpact`**（= 游戏自带华约图裁方，**2026-09-25 新增**） |
| idea：情报局 / 世界和平理事会 / 国际广播组织 / 欧安会 | `picture =` | `hof_ma_cominform` / `hof_ma_wpc` / `hof_ma_oirt` / `hof_ma_osce` |
| ⏳ **仍占位的 3 个政治线 idea**（机关报 · 友好协会 · 第一书记会议） | `picture =` | `generic_communist_army`（等 `03` v3 第 3 批交图） |

---

## §3 ⬜ 还缺什么（等美术，或继续抠）

> ⭐ **2026-09-25 口径之后，本节大幅缩水** —— 详见 `03` v3。

**国策图标**：
- ✅ **定案、不用再画**：**头 1 + 经济线 19 + 军事线 16 = 36 张** —— 直接用游戏自带的
  经互会 / 华约 / 马列思想三张图（用户 2026-09-25 口径「**不是已经有了吗，游戏内自带**」）。
- ⏳ **仍要画**：**政治线 10 张**（报头 · 保卫和平 · 工人阶级统一 · WFSW · ССОД · 苏共中央国际部 ·
  1957 / 1960 / 1969 莫斯科会议 · 第一书记会议）—— 逐张提示词见 `03` v3 §4。

**idea**：
- ✅ **已用真图 11 张**（其中 **4 个经济 / 军事线 idea 于 2026-09-25 新增**，套用游戏自带那两张的方形版）。
- ⏳ **仍占位 3 张**：机关报 / 友好协会 / 第一书记会议（都是政治线的 idea）。

### 真正还缺的（逐条查过，⛔ 拿不到）

| 想要 | 查证结果 |
| --- | --- |
| ~~**世界和平理事会**~~ | ✅ **2026-09-21 已解决** —— 从 **1950 年中国「保卫世界和平」邮票（纪5）** 上裁出毕加索的鸽子，**不交美术**（见 §2.2.3）。 |
| ~~**经互会会徽 / 华约徽章**~~ | ✅ **2026-09-25 取消** —— 用户口径「**游戏内自带，不用重画**」⇒ 直接用原版那两张。 |
| 政治线剩下 7 张（保卫和平 / 工人阶级统一 / 苏共中央国际部 / 三次莫斯科会议 / 第一书记会议） | **抽象机制与会场，本来就没有徽标**（不是查不到，是历史上不存在）。 |

⇒ 这 7 张**只能让美术按 `docs/un-focus/03-s5-icon-prompts.md` 画**；
另 **3 张仍要抄实物**（报头 · WFSW 会徽 · ССОД 徽标）。

### ✅ 曾经列在这张表里、后来都挖到了的（留证）

| 机构 | 最后是从哪挖到的 |
| --- | --- |
| 世界民主青年联盟 | **FOTW**（不在维基） |
| 国际民主妇女联合会 | Commons `File:WIDF.jpg`（**名字不带 `logo` 的那张才对**） |
| 国际新闻工作者协会 | Commons 的 **SVG**（`...des journalistes logo.svg`） |
| 国际经济合作银行 / 国际投资银行 | ⚠️ **官网（只有现代标）** |
| 友谊输油管道 | **sovietznak.ru**（实物纪念章） |
| Intermetall | ⭐ **Commons 全库**（用户在拍卖站找到线索后回头一搜就有） |

📌 **四条可复用的抠图路线**（下一轮照这个顺序打）：
① 条目 `prop=images`（不是 `pageimages`）→ ② **本地维基** `zh.` / `en.` / `ru.` / `de.` / `hu.` →
③ **非维基的专题站**（FOTW 徽章/旗帜 · sovietznak.ru 苏联徽章 · 各机构官网）→
④ **Commons 全库 `list=search` 多角度换词**（机构名 / 城市名 / 桥名 / 纪念章 / 拉丁+西里尔两种拼法）。
⛔ **别只打一轮关键词就下「没有」的结论**（Intermetall 就是这么漏掉的）。

## §4 管线与纪律（写脚本时照着做）

### §4.1 两条并行管线

```
国策图标（100×88）：art/focus/ma/GFX_hof_ma_<名>_focus.png
                     → mod/heart_of_iron/gfx/interface/hof_ma/focus/GFX_hof_ma_<名>.dds
民族精神（60×60）：  art/focus/ma/GFX_idea_hof_ma_<名>.png
                     → mod/heart_of_iron/gfx/interface/hof_ma/ideas/GFX_idea_hof_ma_<名>.dds
                    ↓  build/gen-hof-ma-icons.ps1
                    mod/heart_of_iron/interface/hof_ma_icons.gfx
```

### §4.2 三条硬纪律

1. **国策图标必须成对**：每个 `GFX_hof_ma_<x>` 都要有一张 `GFX_hof_ma_<x>_shine`
   （贴图不用另画，全游戏 5900+ 个 `_shine` 都指向同一张 `gfx/interface/goals/shine_overlay.dds`）。
   ⚠️ **民族精神的图【不】需要 `_shine`**（见原版 `interface/ideas.gfx`）。
2. **`.gfx` 不能带 BOM**（脚本里已断言）；**`build/*.ps1` 必须带 BOM**。
3. **DDS 必须是 32 位带 alpha**（`dwRGBBitCount = 32` 且 `dwABitMask = 0xFF000000`），否则边角不会透明。

### §4.3 🚩 本轮踩的三个坑（都写进自检了）

| # | 坑 | 症状 | 纪律 |
| --- | --- | --- | --- |
| 1 | **PS 5.1 里 `0xFF000000` 被解析成负的 Int32**（-16777216） | 与 `ToUInt32` 的结果比较**永远不等** ⇒ 8 张本来合格的 DDS 全被判「没有 alpha」 | 比 alpha 掩码写**十进制 `4278190080`** |
| 2 | **给带 BOM 的文件再加一次 BOM** | `.ps1` 开头出现两个 BOM ⇒ PowerShell 报「意外的属性 CmdletBinding」 | 读 `.ps1` 用 `utf-8-sig` 解码；写完断言 `data.count(BOM) == 1` |
| 3 | **idea 的 `picture` 漏了 `generic_` 前缀** | `picture = build_infrastructure` ⇒ sprite `GFX_idea_build_infrastructure` **不存在**（原版叫 `GFX_idea_generic_build_infrastructure`） | `picture` 取**不带 `GFX_idea_` 前缀**的名字，且原版那批都带 `generic_`；§14d 会抓 |

---

## §5 自检清单（`build/verify-s2.ps1` §14，9 项）

> ⚠️ **§14 只验「图在不在、尺寸对不对、sprite 有没有定义」，⛔【不验许可】** ——
> 许可的事实登记在 §2.2.1，**不写「合规」二字**（用户 2026-09-20 裁决【甲】）。

| # | 断言 | 为什么要 |
| --- | --- | --- |
| 14a | `interface/hof_ma_icons.gfx` 存在且**无 BOM** | `.gfx` 带 BOM 会解析异常 |
| 14b | 国策图标**成对**（`X` + `X_shine`） | 缺 `_shine` 国策图标显示异常 |
| 14c | 引用的自家贴图**全部存在** | 防「注册了但没图」 |
| 14d | 尺寸合规：**国策 100×88 · 民族精神 60×60** | 尺寸错会被拉伸 |
| 14e | 国策引用的 `icon` 全部**有 sprite 定义**（原版 + R56 + 本 mod，共 45853 个名字） | 零缺图 |
| 14f | idea 的 `picture` → `GFX_idea_<名字>` 全部有定义 | 抓 `generic_` 这类前缀错 |
| 14g | 动态民族精神的 `icon` 全部有定义 | 同上 |
| 14h | **真图覆盖度如实报数**（不判失败） | 让进度可见 |
| — | §13f 另有一条：国策 icon 在原版**或**本 mod 有定义 | 与 §14e 互为交叉验证 |

---

## 相关

- 设计：`docs/un-focus/01-s5-mutual-aid-common-lines.md`
- 数值：`docs/un-focus/02-s5-values.md`
- 出图提示词（还没真图的那些）：`docs/un-focus/03-s5-icon-prompts.md`
- 共享树蓝本（萨达巴德解剖）：`docs/un-focus/04-shared-tree-blueprint.md`
- 战报与踩坑：`docs/99-todo-verify.md` §47.13 / §47.14 / §47.15

### §2.2.2 第二批六张实物（2026-09-21 · 用户给的线索）

> 用户口径：「**有章了，这些有什么用什么，纪念章还是什么的也可以拿过来用**」

| key | 用在哪（节点） | 来源 | 许可 | 处理 |
| --- | --- | --- | --- | --- |
| **`wfdy`** | `hof_ma_pol_wfdy`（世界民主青年联盟） | ⭐ **FOTW〈WFDY〉页的历史徽章**（`crwflags.com/fotw/images/q/qt_wfdye.gif`） | FOTW 引用 | 绿环 + 双人侧影 + 地球 + 黄带 ⇒ 抠白底 |
| **`widf`** | `hof_ma_pol_widf`（国际民主妇女联合会） | Commons **`File:WIDF.jpg`** | **CC BY-SA 4.0** | 1945 创立时的原版徽标（地球 + 和平鸽）；源图是竖版卡片 ⇒ 裁到徽标区后圆形裁章 |
| **`ioj`** | `hof_ma_pol_ioj`（国际新闻工作者协会） | Commons **`File:Organisation internationale des journalistes logo.svg`** | **CC BY-SA 4.0** | 现成矢量 ⇒ 取 960px PNG 后 trim |
| **`ibec`** | `hof_ma_eco_ibec`（国际经济合作银行） | ⚠️ **官网 favicon**（`ibec.int/favicon/apple-icon-180x180.png`） | 官方素材 | ⚠️ **现代的抽象标**，**不是 1963 年那个圆形 МБЭС**（后者未找到，见 §3） |
| **`iib`** | `hof_ma_eco_iib`（国际投资银行） | ⚠️ **官网素材包**（`iib.int/files/uploaded/iib_logo_eng.png`） | 官方素材 | ⚠️ **2014 年品牌重塑后的绿色「切割祖母绿」**（旧 МИБ 徽标未找到，见 §3）；只取左边那颗宝石，丢掉文字 |
| **`druzhba`** | `hof_ma_eco_druzhba`（友谊输油管道） | ⭐ **sovietznak.ru 实物照片**（蓝色珐琅圆章「НЕФТЕПРОВОД ДРУЖБА」） | 实物照片 | 按用户口径**用纪念章**代替不存在的「机构徽标」；抠白底 |
| **`intermetall`** | `hof_ma_eco_intermetall`（经互会黑色冶金合作组织） | ⭐ Commons **`File:Budapest, Hungary Elisabeth Bridge Medal 1974.jpg`** | **CC BY-SA 3.0** | **1974 年成立十周年纪念章**（直径 36 mm · Cu/Ni），取【正面】那枚（`INTERMETALL` / `10 ЛЕТ` / `ИНТЕРМЕТАЛЛ`，麦穗环），裁左半后圆形裁章 |
| **`wpc`** | `hof_ma_pol_wpc`（世界和平理事会）+ `hof_ma_idea_wpc` | ⭐ Commons **`File:Ji5, 3-1, Peace Dove, 1950.jpg`**（中国 纪5 3-1「保卫世界和平」） | **Public domain** | **毕加索的鸽子**（站立、朝左）+ 八边形框 + 橄榄枝环 ⇒ 裁到徽记 → `disc` 圆裁 ⇒ 国策 100×88 + 民族精神 60×60（见 §2.2.3） |
| — | — | — | — | ⚠️ **这条线索来自用户**：「**这个十周年纪念章也能用**」—— 这条**推翻了我上一轮「Intermetall 无图可用」的结论**（我上一轮只搜到同名的西德弗赖堡公司商标，**没搜到这张纪念碑章**）。 |

⚠️ **`intermetall` 与 `ius` 一样是【本来就有强制义务】的（CC BY-SA 3.0 · `AttributionRequired=true`）** ——
**备用署名文本**：
> 匈牙利布达佩斯「伊丽莎白桥」纪念章（Intermetall 成立十周年，1974）—— 维基共享资源，
> **CC BY-SA 3.0**（原始上传者声明 `Own work`），本项目做了裁切 + 缩放处理。

🚩🚩 **本轮最重要的一条纠错 —— 用户线索里的 ① 不成立**：
Commons 的 **`File:World Federation of Democratic Youth.svg` 其实是【会员国地图】**（下载后肉眼核过：一张绿色/白色的世界地图），
**不是徽标**；同页的 `File:Wfdy1.png` 也只是一面写了「WFDY」三字的黄旗。
⇒ **改用 FOTW〈WFDY〉页的三张历史徽章图**（英 / 德 / 法三版），取**英文版**。
📌 **教训：下载后必须眼看一遍** —— 文件名的可信度低于图像本身（本条与 §2.2.1 的 `WIDF logo.jpg` 是同一类坑：
那个名字的图其实是荷兰的一枚「WAAR IS DAT FEESTJE?」珐琅别针，**真正的 WIDF 徽标是 `File:WIDF.jpg`**）。

### §2.2.4 旧 МБЭС / 旧 МИБ 徽标 —— **2026-09-21 专门找过，没找到**

> 用户口径：「**找一下旧的，没有的话那就用现代的**」

查证范围与结果：

| 找什么 | 查了哪里 | 结果 |
| --- | --- | --- |
| **旧圆形 МБЭС 徽**（「МЕЖДУНАРОДНЫЙ БАНК ЭКОНОМИЧЕСКОГО СОТРУДНИЧЕСТВА」+ 手写体 МБЭС） | `ibec.int` 官网（首页 / about / 新闻页全部 `<img>`）· ru / de / en / hu 四语维基条目图 · Commons 全库搜 `МБЭС` `СЭБ банк` `International Bank for Economic` · Wayback Machine | ⛔ **只找到现代抽象标**（官网 CSS 用的 `sprites.svg` 里是 `logo` / `logo-color` / `logo-ru` 等 symbol）。<br>⚠️ Wayback 这台机器**大面积超时 / 403**，`CDX` 与 `available` 两个接口都没走通。 |
| **旧 МИБ 徽标**（1970–1991） | `iib.int` 新闻素材包 · hu / ru / en 维基条目图 · Commons 搜 `International Investment Bank logo` | ⛔ **只有 2014 年品牌重塑后的绿色宝石标**；官网自己就写明 2014 年换过标。 |

✅ **按用户裁决执行**：**两张都用【现代官方标】**（已实装）——
`ibec` = 官网 favicon 180px（现代抽象标）· `iib` = 官网素材包 `iib_logo_eng.png`（绿色宝石，只取宝石）。
⚠️ **代价如实记**：这两张与节点的 1949 / 1970 年代背景**有年代差** ——
本项目的处理口径与 `osce` 相同（用户 2026-09-20：**「年代错那也可以用没事」**）。

### §2.2.3 世界和平理事会（毕加索的鸽子）—— **2026-09-21 已解决：直接从物件上裁，不交美术**

> 用户口径：「**不对啊，就算有著作权那使用的组织和作者本人都已不存在，而且我们这个是公开免费共享 mod 啊**」
> 「**直接用吧，不让美术画了**」

⛔ **我上一轮错了两处**：
① 我自己写了「毕加索著作权未到期 ⇒ **不能用**」—— **那道线是我自己加的，不是用户裁决**；
② 我自己写了「**这张抠不出图，只能交美术**」—— **也错了**（原因见本节末）。

✅ **最后采用的做法：从 1950 年中国「保卫世界和平」邮票上直接裁。**

| 项 | 值 |
| --- | --- |
| 来源 | Commons **`File:Ji5, 3-1, Peace Dove, 1950.jpg`** —— 中国 **纪5 3-1「保卫世界和平」**（1950，中国人民邮政 400 圓） |
| 许可 | **Public domain**（`NonFree` 空 · `AttributionRequired` 空） |
| 图案 | ⭐ **毕加索的鸽子**（站立、面向左）+ 八边形边框 + **橄榄枝环** —— 正是世界和平理事会会徽的那个母题 |
| 规格 | 原图 **2836×3696** |
| 处理 | 裁到八边形徽记（归一化 `0.19 / 0.205 / 0.81 / 0.625`）→ `disc` 圆裁 → `fit` 100×88；idea 版 60×60 |
| 落地 | `GFX_hof_ma_wpc`（国策）＋ `GFX_idea_hof_ma_wpc`（民族精神，挂在 `$picReal['hof_ma_idea_wpc']`） |

⭐⭐ **这个做法好在三点**：
1. **不用美术**（用户口径）；
2. **图源本身是 PD** ⇒ 权利风险**回到与前面那些历史徽标同一档**（不再单独落在 Succession Picasso 那一头）；
3. 图源是**中国邮票** —— 对一个中文 HOI4 mod **主题也贴**。

⚠️ **但事实仍然如实登记（不写「合规」）**：
**画面里那只鸽子本身是毕加索的作品**（1973 年去世 ⇒ 著作权到 ~2043 年；
**Succession Picasso / ADAGP 是全球维权最积极的版权方之一**）。
**PD 的是【这张 1950 年的中国邮票】，不是那只鸽子。**
📌 口径同 §0 第 4 条：**继续用，但如实登记**；决定权在用户。
⚠️ 另外纠正两处**用户的前提**（这是判断依据，不是修辞）：**毕加索遗产会仍在积极维权**、
**世界和平理事会现在还在**（`wpc-in.org`）。

⛔ **我上一轮为什么说「抠不出图」—— 是关键词没打对**：
我打的是 `World Peace Council` / `Peace doves` / `Dove of Peace` / `苏联邮票`，
**漏了【中文】角度「保卫世界和平 邮票」** —— 一打就出 **纪5（1950）+ 纪10（1951）共 6 枚**；
其中 **纪10 是三角形票，正中就是那只展翅的飞鸽**（备选，未用）。
📌 **第三次证明同一条纪律**：**全库检索要换多角度、多语种关键词（这次是【中文】）** ——
① Intermetall 漏了「布达佩斯 / 桥」；② 本轮漏了「中文」；两次都是「一轮就下结论」的错。

### §2.2.5 曾经列在缺图表里、后来都挖到了的（留证）

| 机构 | 最后是从哪挖到的 |
| --- | --- |
| 世界民主青年联盟 | **FOTW**（不在维基） |
| 国际民主妇女联合会 | Commons `File:WIDF.jpg`（**名字不带 `logo` 的那张才对**） |
| 国际新闻工作者协会 | Commons 的 **SVG** |
| 国际经济合作银行 / 国际投资银行 | ⚠️ **官网（只有现代标）** |
| 友谊输油管道 | **sovietznak.ru**（实物纪念章） |
| Intermetall | ⭐ Commons 全库 —— 关键词要带「**布达佩斯 / Elisabeth Bridge / 纪念章**」 |
| **世界和平理事会** | ⭐ Commons 全库 —— 关键词要带【**中文**】「**保卫世界和平 邮票**」（纪5 / 纪10） |

📌 **四条可复用的抠图路线**（下一轮照这个顺序打）：
① 条目 `prop=images`（不是 `pageimages`）→ ② **本地维基** `zh.` / `en.` / `ru.` / `de.` / `hu.` →
③ **非维基的专题站**（FOTW 徽章/旗帜 · sovietznak.ru 苏联徽章 · 各机构官网）→
④ **Commons 全库 `list=search` 多角度换词**（机构名 / **城市名** / **桥名** / 纪念章 /
**中文名** / 拉丁 + 西里尔两种拼法）。
⛔ **别只打一轮关键词就下「没有」的结论**（Intermetall 与 WPC 都是这么漏掉的）。
