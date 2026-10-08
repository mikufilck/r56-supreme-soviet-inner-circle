# gen-hof-ma-common-lines.ps1
# =============================================================================
# S5 · 经互会通用线（需求 C）生成器
# -----------------------------------------------------------------------------
# 上游文档（唯一权威出处）：
#   docs/10-requirements-soviet-expansion.md §4 需求 C
#   docs/un-focus/01-s5-mutual-aid-common-lines.md   —— 结构 / 摆位 / 59 个节点清单
#   docs/un-focus/02-s5-values.md                    —— 数值（照北欧量级）
#
# 产出 6 个文件：
#   1. common/national_focus/hof_ma_joint.txt              （1 头 + 58 子 = 59 块）
#   2. common/dynamic_modifiers/hof_ma_dynamic_modifiers.txt（3 个动态民族精神容器）
#   3. common/ideas/hof_ma_ideas.txt                       （12 个机构 idea）
#   4. common/scripted_triggers/hof_ma_scripted_triggers.txt
#   5. common/opinion_modifiers/hof_ma_opinion_modifiers.txt
#   6. localisation/simp_chinese/hof_ma_l_simp_chinese.yml （UTF-8 带 BOM）
#   7. build/inject-ma.txt                                 （21 行 shared_focus 注入）
#
# 与 gen-hof-ic-s3.ps1 的关系：那个人是【核心圈花名册】的生成器，本脚本是
# 【通用线】的生成器 —— 两者互不引用，各自是各自数据的唯一出处。
#
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File build\gen-hof-ma-common-lines.ps1
# =============================================================================

[CmdletBinding()]
param(
    [string]$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron',
    [string]$RepRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-ModFile {
    param([string]$RelPath, [string]$Text)
    $Text = $Text.Replace('`t', "`t")
    $full = Join-Path $ModRoot $RelPath
    $dir  = Split-Path -Parent $full
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Text, $utf8NoBom)
    $bom = (Get-Content -LiteralPath $full -Encoding Byte -TotalCount 3) -join ','
    $flag = if ($bom -eq '239,187,191') { '有BOM(错误)' } else { '无BOM(正确)' }
    Write-Output ("  写出 {0,-58} {1,8:N0} 字节  {2}" -f $RelPath, (Get-Item -LiteralPath $full).Length, $flag)
}

Write-Output '======== S5 · 经互会通用线生成 ========'

# =============================================================================
# ★ 可调常量
# =============================================================================
$maPrefix   = 'hof_ma_'
$headId     = 'hof_ma_founding'
# 三个大门共同的解锁：完成头节点即可（三条线互不串线 —— 用户口径 ⑦）
$baseX      = 0
$baseY      = 27          # ★ 苏联终局节点延至 y=25；通用线从第 27 行开始。
$offsetY    = -24         # 把带子从 y = 24 拉回 y = 0
# 🚩🚩 2026-09-20 两次订正（都是用户看游戏截图发现的）
#
# 【第一次】「拉的鬼都不认识了」—— 原来把【固定的列值】-2 / 0 / +2 直接写进每个节点的 x，
#   而 relative_position_id 指向的是【上一个节点】⇒ 每一级都在上一级基础上【又偏】一次，
#   23 级之后经济线累计偏到 x = -46、y = +23。截图里那三根细长斜柱就是这个累计漂移。
#   ⭐ 原版 nordic_shared.txt 的正确写法 = 【小偏移 + 相对父节点】：
#      x 只有 -1 / 0 / +1、y 一律 1（实测 52 个块全部如此），
#      所以北欧整棵树才只占 x ∈ [-6, +7]、y ∈ [0, 3]。
#
# 【第二次】「这些不是线性关系吧，按分类分好多条线来啊」——
#   节点被排成了【三条一路往下的长链】，那是线性关系，不是树。
#   ⭐ 北欧的结构 = 头 → 三个大门 → 各门下面【好几路并列的支线】。
#   ✅ 本线照此重构：**头 → 三条线的大门 → 每门下面按【分类】分成若干条支线**，
#      支线内部是链（先后有序），支线之间【并列】（只要求完成大门）。
#
# 【第三次】「**天哪超级无敌重叠啊**」——
#   ⛔ 上一版把每条支线锚【上一个节点】、只写小增量。官方 wiki 明写：
#      `relative_position_id` 是「把 x / y 加到那一格的位置上」，
#      而且**被引用的国策必须与它在同一棵 focus tree 里**才生效。
#      只要这个相对解析有一处没落地，小增量就会被当成【绝对坐标】——
#      15 条支线的第一个节点会全部落在那几个【相同】的增量值上 ⇒ 叠成一坨。
#      （实测：北欧那 51 个增量若被当绝对坐标，会撞上瑞典树自己的 **129** 个国策，
#        所以北欧那条路是通的 —— 但本线没必要赌这个。）
#   ✅ 现在：**58 个子节点的 relative_position_id 一律 = 头节点**（单一锚点，永不累加），
#      而且 x / y 【直接写「相对头节点的绝对格位」】——
#      ① 相对解析生效时：落点 = 头 + 格位 ✓ 就是设计的位置
#      ② 相对解析万一不生效：落点 = 格位本身，仍然【互不重叠】（格位本身唯一）
#      ⇒ 两种解释下都不会叠。
#   ✅ 间距也从 2 格放宽到 **3 格**（原版 germany 里 3 格出现 35 次，是合法档位），
#      支线之间留出更明显的空隙。
#   摆位：头 (0, 0)；三条线的大门分别落在 col 0 / 1 / 2 上，其余支线从大门横向铺开，
#         每条支线占【一列】，列内成链（每下一格 = 支线里的下一个节点）。
#   带子：经济 [-21,-18,-15,-12,-9,-6] · 政治 [-3,0,3,6,9] · 军事 [12,15,18,21]
$lineCol = @{ eco = @(-21, -18, -15, -12, -9, -6)
              pol = @(-3, 0, 3, 6, 9)
              mil = @(12, 15, 18, 21) }

# 支线划分：值 = 该支线包含的【节点在 $maEco / $maPol / $maMil 里的下标】，按支线内部先后排。
# ⚠️ 必须是这些下标的一个【划分】（每个恰好出现一次）—— §14 有断言。
# ⚠️ 每条线的【第一条支线的第一个节点】就是这条线的【大门】，它挂到头节点上。
$lineClusters = @{
    eco = @(
        @(0, 1, 4, 5, 12),        # 缔造与章程
        @(6, 7, 10, 14, 15),      # 计划与分工
        @(8, 9, 13),              # 货币与结算
        @(16, 17, 19),            # 原料与能源
        @(2, 20, 18, 21),         # 科技与标准
        @(3, 11, 22)              # 阵营贸易秩序
    )
    pol = @(
        @(0, 1, 2, 3),            # 情报局本体
        @(4, 5, 6, 7),            # 工会与青年
        @(9, 10, 11, 8),          # 和平与宣传战线
        @(12, 17),                # 党际渠道
        @(13, 14, 15, 16)         # 党际会议
    )
    mil = @(
        @(0, 3, 4, 12),           # 条约与决策
        @(1, 2, 13),              # 指挥机关
        @(5, 6, 9, 10, 11),       # 部队与装备
        @(7, 8, 14, 15, 16)       # 战备与对抗
    )
}
$lineClusterName = @{
    eco = @('缔造与章程', '计划与分工', '货币与结算', '原料与能源', '科技与标准', '阵营贸易秩序')
    pol = @('情报局本体', '工会与青年', '和平与宣传战线', '党际渠道', '党际会议')
    mil = @('条约与决策', '指挥机关', '部队与装备', '战备与对抗')
}
# 带子相对头节点往左右各伸 $stripHalf 格 ⇒ 头部落点必须再往右挪，否则会压到树
$stripHalf  = 21

# 图标：用户 2026-09-20 口径「军事线先全部用华约图标占位，工人局全部用共产国际，
# 经互会全部用经互会，莫洛托夫用马列思想，不知道这些图标意味着什么就搜国策名」
#   —— 四个 sprite【全部是原版已有的】（interface/goals.gfx），不需要我们自己注册，
#      所以本线【零缺图风险】，也不进 gen-hof-ic-focus-icons.ps1 的兜底名单。
#   反查方式 = 按【国策中文显示名】去找原版国策，再读它的 icon：
#     华沙条约组织已成立  = SOV_found_the_warsaw_pact          -> GFX_focus_SOV_found_the_warsaw_pact
#     共产国际            = SOV_the_comintern                  -> GFX_goal_support_communism
#     经济互助委员会      = SOV_found_the_comecon              -> GFX_focus_SOV_the_comecon
#     马克思-列宁主义道路 = SOV_the_path_of_marxism_leninism   -> GFX_focus_SOV_the_path_of_marxism_leninism
#
# ⭐⭐ 2026-09-25 用户口径：「**经互会和华约的不是已经有了吗，游戏内自带，
#    莫洛托夫条约也不用重新画就用那个吧**」
#    ⇒ 上面这三张【从占位升为定案】：经互会线（经济 19 张）· 华约线（军事 16 张）·
#      头（1 张）**不再各自出图**；其余仍用 `Icon = ` 单独指定（见下面节点表的 Icon 字段）。
#    ⇒ 因此 docs/un-focus/03 的「待画」从 46 张降到 **13 张**（政治线 10 + idea 3）。
#    📌 政治线现在用的是 `GFX_hof_ma_cominform`（**本 mod 自己抠的**，不是游戏自带）
#       ⇒ 本循环**不动它**，仍按 docs/un-focus/03 等美术逐张交图。
$iconHead = 'GFX_focus_SOV_the_path_of_marxism_leninism'
$iconLine = @{ eco = 'GFX_focus_SOV_the_comecon'
               pol = 'GFX_hof_ma_cominform'
               mil = 'GFX_focus_SOV_found_the_warsaw_pact' }
$srchLine = @{ eco = 'FOCUS_FILTER_INDUSTRY'
               pol = 'FOCUS_FILTER_POLITICAL'
               mil = 'FOCUS_FILTER_ARMY_XP' }

# DM 容器图标：原版 idea 通用图标（与 22 条个人线的容器同款）。
# ⚠️ 刻意【不用】上面的 focus 图标 —— DM 显示在民族精神格里，要的是方形 idea 图；
#    focus 图是带边框的国策图，形状不对。三个民族精神的专属美术列进 docs/un-focus/03。
# ⭐ 三个动态民族精神的图标 = 【民族精神（方形）版】—— 由 build/gen-hof-ma-idea-icons.py
#    从【游戏自带】的那三张国策图裁方、缩到 60x60 得到（用户口径：「经互会和华约的不用，
#    游戏内不是已经有了」）。注册见 build/gen-hof-ma-icons.ps1。
$dmIcon = @{ eco = 'GFX_idea_hof_ma_comecon'
             pol = 'GFX_idea_hof_ma_cominform'
             mil = 'GFX_idea_hof_ma_warsawpact' }

# 我们自己的 modifier tooltip 键（官方没有 <词条>_tt 的，见 tmp/mod-tt-check2.txt 实测）
$maOwnTt = @{
    'faction_trade_opinion_factor'           = 'hof_ma_tt_faction_trade_opinion_factor'
    'stability_weekly_factor'                = 'hof_ma_tt_stability_weekly_factor'
    'improve_relations_maintain_cost_factor' = 'hof_ma_tt_improve_relations_maintain_cost_factor'
    'land_equipment_upgrade_xp_cost'         = 'hof_ma_tt_land_equipment_upgrade_xp_cost'
    'static_anti_air_damage_factor'          = 'hof_ma_tt_static_anti_air_damage_factor'
    'army_fuel_capacity_factor'              = 'hof_ma_tt_army_fuel_capacity_factor'
    # 这一个【复用核心圈已写好的键】—— 同一件事不重复定义（硬性规则 10）
    'opinion_gain_monthly_factor'            = 'hof_ic_tt_opinion_gain_monthly_factor'
}
function Get-MaTt([string]$m) {
    if ($maOwnTt.ContainsKey($m)) { return $maOwnTt[$m] }
    return "${m}_tt"
}

# =============================================================================
# §1 头节点（1）
# =============================================================================
# 中文名「莫洛托夫计划」= 用户 2026-09-20 裁决（甲）；史实锚点：
#   苏联以《莫洛托夫计划》回应马歇尔计划 —— 与波、捷、匈、罗、保、南、芬、蒙等
#   签【双边贸易与互助条约网】。zh 维基〈经济互助委员会〉：「作为《莫洛托夫计划》
#   的后续阶段而出现」；〈莫洛托夫计划〉：「最終擴充并发展为了經濟互助委員會」。
$maHead = @{
    Id = 'hof_ma_founding'
    Zh = '莫洛托夫计划'
    Cost = 10
    V = @(
        'eco|faction_trade_opinion_factor|trade|0.05',
        'pol|opinion_gain_monthly_factor|opinion|0.05',
        'mil|max_command_power|command_max|25'
    )
    Raw = @(
        '# 三个动态民族精神一起挂上 —— 头节点是唯一的入口',
        'add_dynamic_modifier = { modifier = hof_ma_dm_eco }',
        'add_dynamic_modifier = { modifier = hof_ma_dm_pol }',
        'add_dynamic_modifier = { modifier = hof_ma_dm_mil }',
        'set_country_flag = hof_ma_joined'
    )
    Orig = @('add_political_power = 50')
    Desc = '1947 年 7 月起，苏联以《莫洛托夫计划》回应马歇尔计划：与波兰、捷克斯洛伐克、匈牙利、罗马尼亚、保加利亚、南斯拉夫、芬兰、蒙古等国签订一系列双边贸易与互助条约。这项计划最终扩充并发展成为经济互助委员会。—— 记于〈莫洛托夫计划〉〈经济互助委员会〉条，中文维基。'
}

# =============================================================================
# §2 经济线 = 经济互助委员会（СЭВ）（23）
# =============================================================================
$maEco = @(
    @{ Id = 'hof_ma_eco_founding'; Zh = '经济互助委员会'; Cost = 10;
       V = @('eco|consumer_goods_factor|goods|-0.05', 'eco|industrial_capacity_factory|industry|0.05');
       Raw = @('add_ideas = hof_ma_idea_comecon');
       Desc = '1949 年 1 月 5 日至 8 日，苏联、保加利亚、匈牙利、波兰、罗马尼亚、捷克斯洛伐克六国政府代表在莫斯科通过会议磋商后，宣布成立经济互助委员会；1 月 25 日发表《关于成立经济互助委员会的公报》。随后阿尔巴尼亚（1949）、东德（1950）、蒙古（1962）、古巴（1972）、越南（1978）分别加入。总部设在莫斯科。—— 记于〈经济互助委员会〉条，中文维基。' },

    @{ Id = 'hof_ma_eco_common_planning_organ'; Zh = '共同的计划经济组织';
       V = @('eco|cic_construction_boost_factor|build_boost|0.05', 'eco|local_resource_gain_efficiency_per_infrastructure|infra_resource|0.10');
       Raw = @('set_country_flag = hof_ma_plan_coordination');
       Desc = '经互会成立之初，计划协调推进得很快：方向看起来是各国国民经济计划的协调，但经互会自身没有任何强制权力 —— 所有决定都需一致批准，而且即使批准了，也还要各国政府各自把它转成自己的政策。超国家计划的第一次尝试，就停在「一致批准」这一步之前。—— 记于【en】Comecon 条「Stalin era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_sofia_principle'; Zh = '索非亚原则';
       V = @('eco|research_sharing_per_country_bonus_factor|sharing|0.15', 'eco|industry_repair_factor|repair|0.05', 'eco|research_speed_factor|research|0.05');
       Desc = '1949 年 8 月，经互会在保加利亚的理事会会议通过「索非亚原则」：成员国的技术向其他国家开放，只收一笔名义费用 —— 少到刚好只够付文件的成本。这一条实质上取消了阵营内部的知识产权边界，受益的自然是工业较不发达的那些成员国。—— 记于【en】Comecon 条「Stalin era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_trade_only'; Zh = '便利贸易的实际问题';
       V = @('eco|faction_trade_opinion_factor|trade|0.05', 'eco|resource_trade_cost_bonus_per_factory|trade_cost|0.25', 'eco|consumer_goods_factor|goods|-0.05');
       Desc = '1950 年夏，斯大林「似乎让经互会的工作人员措手不及」地把它的运作几乎完全停掉 —— 苏联在国内转向自给自足，在国外转向用「大使馆体系」直接干预别国事务，而不是走「章程途径」。1950 年 11 月，经互会的职权被正式限定为「便利贸易的实际问题」。此后数年，它更像一张双边换货的账桌，而不是一个共同体。—— 记于【en】Comecon 条「Stalin era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_standing_commissions'; Zh = '常设委员会';
       V = @('eco|production_factory_max_efficiency_factor|efficiency|0.05', 'eco|industrial_capacity_factory|industry|0.05');
       Desc = '1956 年起设立首批常设委员会（一说 10 个、一说 8 个），按行业对口；到 1988 年增至化工、有色金属、煤炭、和平利用原子能等 24 个。常设委员会受执行委员会领导，各国可以有选择地参加。—— 记于〈经济互助委员会〉条「组织机构」，中文维基。' },

    @{ Id = 'hof_ma_eco_charter'; Zh = '经互会章程'; Cost = 10;
       V = @('eco|production_speed_buildings_factor|build|0.05', 'eco|global_building_slots_factor|slots|0.05');
       Orig = @('add_political_power = 50');
       Desc = '经互会章程于 1959 年签署、1960 年生效（体例上参照 1957 年的罗马条约），确立「主权平等」与「一致同意」两项原则 —— 所有决议案不具法律效力，只要有一个国家认为会损害自身利益就可以拒绝。—— 记于〈经济互助委员会〉条，中文维基。' },

    @{ Id = 'hof_ma_eco_division_of_labour'; Zh = '国际社会主义分工基本原则'; Cost = 10;
       V = @('eco|industrial_capacity_factory|industry|0.10', 'eco|faction_trade_opinion_factor|trade|0.10');
       Raw = @('add_ideas = hof_ma_idea_division_of_labour');
       Desc = '1961 年 12 月，理事会会议通过《国际社会主义分工基本原则》：讲的是更紧密的计划协调，以及把同类产品的生产「集中到一两个社会主义国家去」。这一条既是整合，也是此后一切争执的根源。—— 记于【en】Comecon 条「Khrushchev era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_single_planning_organ'; Zh = '共同的单一计划机构'; Cost = 10;
       V = @('eco|cic_construction_boost_factor|build_boost|0.10', 'eco|global_building_slots_factor|slots|0.05');
       Raw = @('set_country_flag = hof_ma_supranational');
       Desc = '1962 年 11 月，苏联部长会议主席赫鲁晓夫接着提出设立「共同的单一计划机构」。捷克斯洛伐克、匈牙利、波兰抵制；反对最激烈的是民族主义情绪日益上升的罗马尼亚 —— 它坚决不接受「自己应当专事农业」这个说法。从提议到搁浅，只用了一次理事会。—— 记于【en】Comecon 条「Khrushchev era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_transferable_rouble'; Zh = '转账卢布';
       V = @('eco|faction_trade_opinion_factor|trade|0.05', 'eco|resource_trade_cost_bonus_per_factory|trade_cost|0.25');
       Desc = '1963 年 10 月 22 日，经互会成员国签订国际结算协定，确立「转账卢布」；各国自 1964 年 1 月 1 日起用它作为国际货币单位。它没有纸币或国库券那种具体形态，只用于成员国之间的非现金结算。它有 0.987412 克纯金的法定含金量 —— 但既不能兑换成资本主义国家的货币，也不能兑换黄金，只能在成员国货币之间转换。—— 记于〈转账卢布〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_eco_ibec'; Zh = '国际经济合作银行'; Icon = 'GFX_hof_ma_ibec';
       V = @('eco|resource_trade_cost_bonus_per_factory|trade_cost|0.25', 'eco|country_resource_steel|steel|8');
       # 2026-09-21 用户口径：加 20 钢的国策改成【每种可获得资源各 +20】（1.19 共 7 种）
       Resource = @('capital_scope = { add_resource = { type = oil amount = 20 } add_resource = { type = aluminium amount = 20 } add_resource = { type = rubber amount = 20 } add_resource = { type = tungsten amount = 20 } add_resource = { type = steel amount = 20 } add_resource = { type = chromium amount = 20 } add_resource = { type = coal amount = 20 } }');
       Desc = '国际经济合作银行（МБЭС）1963 年 10 月 22 日由经互会成员国依国际协定设立，是在苏联境内出现的第一个国际银行；创始成员为保加利亚、匈牙利、东德、蒙古、波兰、罗马尼亚、苏联与捷克斯洛伐克。它管的是转账卢布体系下的多边结算 —— 把成员国之间的账从一张张双边清单收进一本共同的账。—— 记于〈国际经济合作银行〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_eco_planning_committee'; Zh = '计划合作委员会';
       V = @('eco|industrial_capacity_factory|industry|0.05', 'eco|cic_construction_boost_factor|build_boost|0.10', 'eco|local_resource_gain_efficiency_per_infrastructure|infra_resource|0.10');
       Desc = '理事会下设四个委员会，其中最重要的是计划合作委员会：它由各成员国的国家计划委员会主席组成，负责协调各国的国民经济计划，地位仅在会议与执行委员会之后。这一段评语说得很直白 —— 如果它的决定不需要各国政府和党的批准，它就会被当成经互会的超国家计划机关；而它恰恰需要。—— 记于【en】Comecon 条「Other entities」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_interested_party'; Zh = '利益相关方原则';
       V = @('eco|consumer_goods_factor|goods|-0.05', 'eco|faction_trade_opinion_factor|trade|0.05');
       Desc = '1967 年，经互会采纳「利益相关方原则」：任何国家都可以退出它选定的任何项目，其余成员国照常推进协调。章程（1967 年修订）的原话是「建议和决定不适用于已声明对某一事项无兴趣的国家」—— 从此，无兴趣方没有否决权，只有不参加的权利。换言之，这一条把「否决」换成了「退出」。—— 记于【en】Comecon 条「Brezhnev era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_executive_committee'; Zh = '执行委员会';
       V = @('eco|production_speed_buildings_factor|build|0.05');
       Desc = '执行委员会由成员国各派一名副总理作为常驻代表组成，一般每季开会一次，会议主席按国名西里尔字母顺序轮流担任、任期一年。1971 与 1974 年两度增设经济部门，权限被提到常设委员会之上。—— 记于〈经济互助委员会〉条「组织机构」，中文维基。' },

    @{ Id = 'hof_ma_eco_iib'; Zh = '国际投资银行'; Icon = 'GFX_hof_ma_iib'; Cost = 10;
       V = @('eco|production_speed_buildings_factor|build|0.10', 'eco|local_resources_factor|resources|0.05', 'eco|global_building_slots_factor|slots|0.10');
       Raw = @('capital_scope = { add_building_construction = { type = industrial_complex level = 1 instant_build = yes } }');
       Desc = '国际投资银行（МИБ）的设立协定由创始国 1970 年 7 月 10 日签署，1971 年 1 月 1 日开始运作，总部设在布达佩斯。它在成立时的主要任务，就是为若干成员国共同的投资项目与发展计划提供中长期贷款 —— 也就是把「协调计划」变成「一起出钱建厂」。在「苏联时期」它累计融资的投资项目超过 70 亿欧元。—— 记于〈国际投资银行〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_eco_comprehensive_programme'; Zh = '社会主义经济一体化综合纲要'; Cost = 10;
       V = @('eco|industrial_capacity_factory|industry|0.15', 'eco|faction_trade_opinion_factor|trade|0.05', 'eco|resource_trade_cost_bonus_per_factory|trade_cost|0.25');
       Raw = @('add_ideas = hof_ma_idea_integration_programme');
       Orig = @('add_political_power = 75');
       Desc = '1969 年 4 月特别会议提出、1971 年通过《社会主义经济一体化综合纲要》。「一体化」一词自此正式启用，此后经互会的主要活动方式改为发展成员国企业与科研组织之间的联系并建立合营企业。—— 记于〈经济互助委员会〉条「主要活动」，中文维基。' },

    @{ Id = 'hof_ma_eco_long_term_programmes'; Zh = '长期专项合作纲要'; Cost = 10;
       V = @('eco|local_resources_factor|resources|0.10', 'eco|production_factory_max_efficiency_factor|efficiency|0.10', 'eco|max_fuel_factor|fuel|0.10');
       Raw = @('capital_scope = { add_building_construction = { type = rail_way level = 1 instant_build = yes } }');
       Desc = '1971 年《社会主义经济一体化综合纲要》通过之后，经互会的主要活动方式改为发展成员国企业与科研组织之间的联系并建立合营企业；实际推进最快的只有石油、电力与其他科技部门。所谓「长期专项合作纲要」，就是把一体化拆成一份份可以逐年核对的清单：能源、原料、机械、运输各自成册 —— 本节点同时接通铁路，因为纲要里的运输一节就是靠跨阵营的轨距与换装站落地的。—— 记于〈经济互助委员会〉条「主要活动」，中文维基；＋【en】Comecon 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_druzhba'; Zh = '友谊输油管道'; Icon = 'GFX_hof_ma_druzhba';
       V = @('eco|country_resource_oil|oil|12', 'eco|max_fuel_factor|fuel|0.15');
       # 2026-09-21 用户口径：只给一种资源的两条改成【+40】
       Resource = @('capital_scope = { add_resource = { type = oil amount = 40 } }');
       Desc = '「友谊」管道建于 1960 年代，把伏尔加—乌拉尔油气省的原油送到东欧的经互会国家：匈牙利、捷克斯洛伐克、波兰与东德。管线 1960 年 12 月 10 日从阿尔梅季耶夫斯克开工，用了四年建成，1964 年 10 月 15 日举行正式投产仪式；它是世界上最大的一条干线输油系统。也是这个阵营里最结实的一件实物：一根埋在地下的管子，比任何一份议定书都难退出。—— 记于〈友谊输油管道〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_eco_power_grid'; Zh = '「和平」联合电网'; Cost = 10;
       V = @('eco|country_resource_coal|coal|16', 'eco|industry_repair_factor|repair|0.15');
       # 2026-09-21 同上：只给一种资源 ⇒ 40
       Resource = @('capital_scope = { add_resource = { type = coal amount = 40 } }');
       Desc = '在经互会「慢速前进」的那些年里，真正往前走的只有石油、电力与其他科技部门 —— 电网是其中最实的一项：统一调度、互为备用，一方断电、另一方送电。电网比条约先兑现了「一体化」这个词。本节点按用户口径同时给各国首都加煤。—— 记于【en】Comecon 条「Khrushchev era」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_icsti'; Zh = '国际科学技术情报中心';
       V = @('eco|research_speed_factor|research|0.10', 'eco|research_sharing_per_country_bonus_factor|sharing|0.05');
       Raw = @('set_country_flag = hof_ma_icsti');
       Desc = '在经互会的正式层级之外还有一批「附属机构」，作用是在成员国的对口机关之间建立直接联系。它们分两类：政府间经济组织（层级较高、管的面较宽），以及国际经济组织（更靠近研究、生产、贸易的作业层）。科技情报的统一交换，就落在后一类里。—— 记于【en】Comecon 条「Affiliated agencies」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_intermetall'; Zh = 'Intermetall'; Icon = 'GFX_hof_ma_intermetall';
       V = @('eco|local_resources_factor|resources|0.10', 'eco|country_resource_steel|steel|8');
       # 2026-09-21 同上：每种可获得资源各 +20
       Resource = @('capital_scope = { add_resource = { type = oil amount = 20 } add_resource = { type = aluminium amount = 20 } add_resource = { type = rubber amount = 20 } add_resource = { type = tungsten amount = 20 } add_resource = { type = steel amount = 20 } add_resource = { type = chromium amount = 20 } add_resource = { type = coal amount = 20 } }');
       Desc = 'Intermetall 是经互会「政府间经济组织」里专门管黑色冶金的那一个 —— 英文维基把它与国际经济合作银行、国际投资银行并列为这一类的三个例子（一个管转账卢布，一个管共同项目融资，一个管钢铁）。它让成员国的轧机不再各自为战，而按同一个规格表排产。—— 记于【en】Comecon 条「Affiliated agencies」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_standardisation'; Zh = '标准化研究所'; Cost = 10;
       V = @('eco|research_sharing_per_country_bonus_factor|sharing|0.10', 'eco|research_speed_factor|research|0.05');
       Raw = @('add_ideas = hof_ma_idea_joint_research_org');
       Desc = '经互会设有三个研究所：世界社会主义体系国际经济问题研究所、标准化研究所、管理问题国际研究所。其中标准化与经济问题两个研究所都设在莫斯科，人员来自各成员国。标准化研究所处理的是各国标准之间的对接 —— 这是「索非亚原则」落到图纸上的那一半。—— 记于〈经济互助委员会〉条「组织机构」，中文维基；＋【en】Comecon 条「Structure」，本项目据英文转译。' },

    @{ Id = 'hof_ma_eco_scientific_progress'; Zh = '科技进步综合纲要'; Cost = 10;
       V = @('eco|research_speed_factor|research|0.20', 'eco|production_factory_max_efficiency_factor|efficiency|0.05');
       Desc = '1985 年通过《到 2000 年的科技进步综合纲要》，是戈尔巴乔夫时期对这个体系下的最后一次注。它把希望押在机器人与电子工业上 —— 而经互会的贸易额在世界上仍然只排在欧共体之后。—— 记于〈经济互助委员会〉条，中文维基。' },

    @{ Id = 'hof_ma_eco_eec_talks'; Zh = '与欧共体直接谈贸易协定'; Cost = 10;
       V = @('eco|faction_trade_opinion_factor|trade|0.15');
       Raw = @('every_country = {',
               '	limit = {',
               '		OR = { original_tag = FRA original_tag = GER original_tag = ITA original_tag = ENG }',
               '	}',
               '	add_opinion_modifier = { target = ROOT modifier = hof_ma_eec_trade_agreement }',
               '}');
       Desc = '1988 年 6 月 25 日之前的那一轮自由化，使经互会国家可以直接与欧洲共同体（改名后的欧共体）谈判贸易条约。阵营经济秩序在这里走到终点：从此每一条贸易协定都签给布鲁塞尔，而不是签给莫斯科 —— 英文维基把这一条与「辛纳屈主义」并列为经互会终局的起点。本节点按史实给西欧四国好感修正。—— 记于【en】Comecon 条，本项目据英文转译。' }
)

# =============================================================================
# §3 政治线 = 共产党和工人党情报局（18）
# =============================================================================
$maPol = @(
    @{ Id = 'hof_ma_pol_cominform'; Zh = '共产党和工人党情报局'; Cost = 10;
       V = @('pol|political_power_factor|pp|0.05', 'pol|opinion_gain_monthly_same_ideology_factor|opinion_ideo|0.05');
       Raw = @('add_ideas = hof_ma_idea_cominform');
       Orig = @('add_political_power = 50');
       Desc = '1947 年 9 月 22 日，苏联、保加利亚、罗马尼亚、波兰、匈牙利、捷克斯洛伐克、南斯拉夫、法国、意大利的共产党和工人党在波兰什克拉尔斯卡-波伦巴开会，成立一个类似第三国际的组织，目的是在各共产党之间交换情报信息。与会者包括马林科夫、日丹诺夫、卡德尔、德热拉斯、哥穆尔卡。总部最初设在贝尔格莱德，1948 年迁往布加勒斯特。—— 记于〈共产党和工人党情报局〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_cominform_organ'; Zh = '《争取持久和平，争取人民民主！》';
       V = @('pol|opinion_gain_monthly_factor|opinion|0.10', 'pol|drift_defence_factor|drift|0.05');
       Raw = @('add_ideas = hof_ma_idea_cominform_press');
       Desc = '《争取持久和平，争取人民民主！》是情报局的机关报 —— 情报局会议的决议里明确写着，它的任务之一就是「领导这份报纸」。报纸用多种外文出版，1956 年 4 月情报局停止活动时一并停刊。它是这个组织唯一常年运转的部件。—— 记于〈共产党和工人党情报局〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_pol_peace_and_war'; Zh = '保卫和平和反对战争制造者的斗争';
       V = @('pol|war_support_factor|war_support|0.10', 'pol|stability_weekly_factor|stability_week|0.05');
       Desc = '「和平」这面旗帜最早是情报局自己举起来的：它把世界分成以苏联为首的「爱好和平」进步力量与以美国为首的「好战」资本主义国家两半，并宣示和平「应当成为各共产党全部活动的轴心」，多数西方共产党照此行事。到 1950 年代初，和平运动反过来盖过了情报局本身。—— 记于【en】World Peace Council 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_working_class_unity'; Zh = '工人阶级的统一';
       V = @('pol|stability_factor|stability|0.05', 'pol|conscription_factor|conscription|0.05');
       Desc = '情报局的决议给各共产党与工人党定下的任务，是先用一切斗争手段去争取「稳固而持久的和平」，并且把全部活动都从属于这件事。1950 年它通过苏斯洛夫的报告，把这层意思正式写成决议。这就是「团结」这个词在组织层面的含义。—— 记于【en】World Peace Council 条，本项目据英文转译。' },

    # ⛔ 2026-09-21 用户口径：删掉「情报局解散」节点（政治线 19 → 18）。
    #    用户 2026-09-20 已定过「删掉所有开除国家或者国家离开的历史事件」——
    #    这一条同型（机构自己结束），一并移出。`hof_ma_cominform_dissolved` 这个
    #    flag 全库只有这一处写、没有任何地方读 ⇒ 删除为零副作用。

    @{ Id = 'hof_ma_pol_wftu'; Zh = '世界工会联合会'; Icon = 'GFX_hof_ma_wftu';
       V = @('pol|weekly_manpower|manpower|250', 'pol|conscription_factor|conscription|0.05', 'pol|join_faction_tension|join|-0.25');
       Raw = @('add_manpower = 5000');
       Desc = '世界工会联合会 1945 年成立，前身是 1919 年成立的国际工会联合会；创建时有 51 个国家参加第一次代表大会，除美国劳工联合会外一度都是它的会员。1948 年起西方国家工会以它拒绝马歇尔计划为由陆续退出，并于 1949 年 12 月在伦敦另立国际自由工会联合会 —— 冷战时期，它被公认是苏联主导下的国际劳工组织。—— 记于〈世界工会联合会〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_wfdy'; Zh = '世界民主青年联盟'; Icon = 'GFX_hof_ma_wfdy';
       V = @('pol|weekly_manpower|manpower|250', 'pol|conscription_factor|conscription|0.05');
       Desc = '1945 年 11 月 10 日，世界青年大会在伦敦成立世界民主青年联盟；第一任秘书长亚历山大·谢列平曾是 1943 年解散的青年共产国际的领导人。它管的是比工会更年轻的那一档人，也是世界青年与学生联欢节的主办单位。—— 记于〈世界民主青年联盟〉条，中文维基。' },

    # ⭐ 唯一一个【游戏里没有对应图】的节点 —— 用国际学联自己的旗徽（外部实物，见
    #    docs/un-focus/06-s5-emblem-icons.md）；其余节点继续用本线那张原版图。
    @{ Id = 'hof_ma_pol_ius'; Zh = '国际学生联合会'; Icon = 'GFX_hof_ma_ius';
       V = @('pol|research_speed_factor|research|0.05', 'pol|opinion_gain_monthly_same_ideology_factor|opinion_ideo|0.05');
       Desc = '1946 年 8 月 27 日，39 个国家 43 个学生组织的近 300 名代表在布拉格举行第一届学生代表大会，达成「全世界学生团结起来防止法西斯复兴」的共识，决定成立国际学联；总部设在布拉格，是联合国教科文组织的咨询成员。它是这一层组织里唯一与学校打交道的。—— 记于〈国际学生联合会〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_widf'; Zh = '国际民主妇女联合会'; Icon = 'GFX_hof_ma_widf';
       V = @('pol|stability_factor|stability|0.05', 'pol|stability_weekly_factor|stability_week|0.05', 'pol|conscription_factor|conscription|0.05');
       Desc = '1945 年 11 月 26 日，第一届世界妇女大会在巴黎举行；12 月 1 日大会结束前通过决议，正式成立国际民主妇女联合会。1949 年 11 月它在莫斯科开会，正式决定每年 6 月 1 日为国际儿童节 —— 它处理的题目比前几个更靠近日常生活，这恰恰是它能在国内起作用的地方。—— 记于〈国际民主妇女联合会〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_wpc'; Zh = '世界和平理事会'; Icon = 'GFX_hof_ma_wpc'; Cost = 10;
       V = @('pol|opinion_gain_monthly_factor|opinion|0.10', 'pol|join_faction_tension|join|-0.25');
       Raw = @('add_ideas = hof_ma_idea_wpc');
       Desc = '世界和平理事会的前身是 1949 年 4 月巴黎—布拉格大会选出的「和平拥护者世界委员会」；1950 年 11 月在华沙召开第二次世界大会，改用「世界和平理事会」这个名字。1950 年 3 月 18 日它发起斯德哥尔摩呼吁，要求绝对禁止核武器 —— 据说在欧洲征集到 5.6 亿个签名。签署与征集签名，从此成为一种长期作业。—— 记于【en】World Peace Council 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_ioj'; Zh = '国际新闻工作者协会'; Icon = 'GFX_hof_ma_ioj';
       V = @('pol|intel_network_gain_factor|intel|0.10', 'pol|drift_defence_factor|drift|0.10');
       Desc = '1946 年 6 月，国际新闻工作者协会在丹麦哥本哈根的一次大会上成立，冷战时期总部设在布拉格。它是苏联在 1940 年代末至 1950 年代初发起成立的数十个外围组织之一；美国中央情报局曾称它为「苏联的宣传工具」。它管的是把消息往哪边发。—— 记于〈国际新闻工作者协会〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_oir'; Zh = '国际广播组织'; Icon = 'GFX_hof_ma_oirt'; Cost = 10;
       V = @('pol|drift_defence_factor|drift|0.10', 'pol|compliance_growth_on_our_occupied_states|compliance|0.10', 'pol|resistance_target|resistance|-0.10');
       Raw = @('add_ideas = hof_ma_idea_oir');
       Desc = '国际广播电视组织（OIRT）成立于 1946 年 6 月 28 日，成员包括保加利亚、捷克斯洛伐克、东德、芬兰、匈牙利、波兰、罗马尼亚和苏联等国的广播电视台，常被称作「Intervision」。中国的北京广播电台与北京电视台也曾加入，后因中苏交恶退出。—— 记于〈国际广播电视组织〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_wfsw'; Zh = '世界科学工作者协会';
       V = @('pol|research_speed_factor|research|0.10', 'pol|opinion_gain_monthly_same_ideology_factor|opinion_ideo|0.05');
       Desc = '世界科学工作者协会 1946 年 7 月 20 至 21 日在伦敦成立，由英国科学工作者协会倡议，最初有 14 个国家的 18 个组织参加。首任主席是法国的约里奥-居里 —— 他当时同时担任世界和平理事会主席，一个人领导着两个组织。—— 记于【en】World Federation of Scientific Workers 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_friendship_societies'; Zh = '友好协会体系（ССОД）'; Cost = 10;
       V = @('pol|opinion_gain_monthly_factor|opinion|0.10', 'pol|compliance_growth_on_our_occupied_states|compliance|0.10', 'pol|improve_relations_maintain_cost_factor|improve|-0.25');
       Raw = @('add_ideas = hof_ma_idea_friendship_societies');
       Desc = '苏联对外友好与文化联络协会（ССОД）1958 年由 ВОКС 改组而来。ВОКС 长期被西方政府官员、知识界与媒体批评为事实上的共产主义宣传组织；ССОД 接替它继续运作，直到 1992 年。各国「苏友协」的网络就挂在这一层上 —— 一封协会的邀请函也可以办成外交部要办的往来。—— 记于【en】VOKS 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_moscow_1957'; Zh = '1957 年莫斯科会议'; Cost = 10;
       V = @('pol|political_power_factor|pp|0.05', 'pol|party_popularity_stability_factor|party|0.05', 'pol|enemy_justify_war_goal_time|enemy_justify|0.25');
       Raw = @('add_political_power = 50');
       Desc = '1957 年 11 月 16 至 19 日，64 个共产党和工人党在莫斯科举行国际会议 —— 这是共产国际与情报局相继解散之后，世界共产主义运动第一次以这种形式集会（另有 4 个党因怕在国内遭报复而秘密出席）。会议通过《和平宣言》，把资本主义垄断集团定为世界和平的主要威胁。此前 11 月 14 至 16 日，12 个执政党已先行签署一份共同宣言。—— 记于【en】1957 年共产党和工人党国际会议条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_moscow_1960'; Zh = '1960 年莫斯科会议'; Cost = 10;
       V = @('pol|war_support_factor|war_support|0.10', 'pol|drift_defence_factor|drift|0.05');
       Desc = '1960 年 11 月 10 日至 12 月 1 日，81 个共产党和工人党在莫斯科举行会议，并发表题为《八十一个共产党和工人党声明》的共同文件。这次会议连着的正是中苏分歧：会前有 1960 年 6 月的布加勒斯特会议，会后的下一次同类集会要等到 1969 年。—— 记于【en】1960 年共产党和工人党国际会议条，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_moscow_1969'; Zh = '1969 年莫斯科会议';
       V = @('pol|stability_factor|stability|0.05', 'pol|opinion_gain_monthly_factor|opinion|0.05');
       Desc = '共产党和工人党国际会议于 1969 年 6 月 5 日至 17 日在莫斯科召开，时在中苏交恶与华约入侵捷克斯洛伐克之后。亲中派共产党均未出席；越南劳动党与朝鲜劳动党也因拒绝在中苏之间表态而未到。会议的两项重点是同反帝国主义力量合作的策略与列宁百年诞辰的庆祝 —— 前者被挪威、多米尼加和英国代表团拒绝签字。—— 记于〈共产党和工人党国际会议〉条，中文维基。' },

    @{ Id = 'hof_ma_pol_first_secretaries'; Zh = '第一书记与政府首脑会议'; Cost = 10;
       V = @('pol|political_power_factor|pp|0.10', 'pol|stability_factor|stability|0.05', 'pol|opinion_gain_monthly_factor|opinion|0.05');
       Raw = @('add_ideas = hof_ma_idea_first_secretaries');
       Orig = @('add_political_power = 75');
       Desc = '经互会最要紧、却又不在章程里的机关，是「共产党和工人党第一书记与政府首脑会议」。英文维基的原话就是「虽然不属于这个组织的正式层级」。机构表上找不到它，但所有真正的决定都在那里做出。—— 记于【en】Comecon 条「Structure」，本项目据英文转译。' },

    @{ Id = 'hof_ma_pol_international_department'; Zh = '苏共中央国际部';
       V = @('pol|improve_relations_maintain_cost_factor|improve|-0.25', 'pol|intel_network_gain_factor|intel|0.05', 'pol|drift_defence_factor|drift|0.05');
       Desc = '苏共中央国际部建立于 1943 年共产国际解散之时，继承了共产国际的档案和部分人员；1957 年，它处理与执政共产党关系的职能被划进新成立的「社会主义国家共产党工人党联络部」。1955 至 1986 年由波诺马廖夫领导。它是一个部，不是一次会议 —— 换言之，它每天都在办公。—— 记于〈苏联共产党中央委员会国际部〉条，中文维基。' }
)

# =============================================================================
# §4 军事线 = 华沙条约组织（ОВД）（17）
# =============================================================================
# ⚠️ 2026-09-20 用户口径：删掉「欧洲集体安全总条约」（1954-02-10）与「申请加入北约」（1954）
#    两个【提出过但未成案】的节点 —— 军事线由 19 → 17。
$maMil = @(
    @{ Id = 'hof_ma_mil_warsaw_treaty'; Zh = '华沙条约组织'; Cost = 10;
       V = @('mil|army_defence_factor|defence|0.10', 'mil|war_support_factor|war_support|0.05', 'mil|conscription_factor|conscription|0.05');
       Raw = @('add_ideas = hof_ma_idea_warsaw_treaty');
       Orig = @('add_political_power = 50');
       Desc = '1955 年 5 月 14 日，苏联与波兰、捷克斯洛伐克、匈牙利、罗马尼亚、保加利亚、阿尔巴尼亚及东德签订《友好合作互助条约》，正式名称为《友好合作互助条约组织》。八个签署国「重申他们希望建立一个基于所有欧洲国家参与的欧洲集体安全体系，无论其社会和政治制度如何」，以回应德意志联邦共和国加入北约。—— 记于〈华沙条约组织〉条，中文维基。' },

    @{ Id = 'hof_ma_mil_joint_command'; Zh = '联合武装部队司令部'; Cost = 10;
       V = @('mil|command_power_gain|command|0.10', 'mil|max_command_power|command_max|25', 'mil|army_org_factor|org|0.05');
       Raw = @('add_ideas = hof_ma_idea_joint_command');
       Orig = @('add_command_power = 25');
       Desc = '联合武装部队司令部是华约的军事指挥机构，负责对华约武装部队的领导、训练、装备和调动。各缔约国派一名将军常驻；苏联国防部第一副部长任总司令（首任科涅夫，1955 至 1960 年），其他成员国的国防部长或副部长任副总司令。总指挥部在华沙，军事总部在莫斯科。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_joint_staff'; Zh = '联合武装部队总参谋部';
       V = @('mil|army_org_factor|org|0.10', 'mil|max_planning_factor|planning|0.10');
       Desc = '联合武装部队总参谋部与司令部同时设立，首任总参谋长安东诺夫大将（1955 至 1962 年）。华约的联合参谋长同时也是苏联武装力量第一副总参谋长。—— 记于〈华沙条约组织〉条「华沙条约组织武装部队历任首长」，中文维基。' },

    @{ Id = 'hof_ma_mil_political_consultative'; Zh = '政治协商委员会'; Cost = 10;
       V = @('mil|war_support_factor|war_support|0.10');
       Raw = @('set_country_flag = hof_ma_pcc');
       Desc = '政治协商委员会是华约的最高决策机构，由各缔约国党的总书记或第一书记、国家元首、总理、国防部长和外交部长组成，负责协商和决定缔约国的国防、政治、外交和经济等重大问题。第一次会议 1956 年 1 月在布拉格举行。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_standing_bodies'; Zh = '联合秘书处与常设委员会';
       V = @('mil|command_power_gain|command|0.05', 'mil|army_org_factor|org|0.05');
       Desc = '政治协商委员会下设的两条常设腿：常设委员会（驻莫斯科，负责政策准备）与联合秘书处（执行机构，也设在莫斯科）。一个负责想，一个负责办。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_integrated_units'; Zh = '一体化部队';
       V = @('mil|army_attack_factor|attack|0.05', 'mil|conscription_factor|conscription|0.05', 'mil|weekly_manpower|manpower|250', 'mil|army_fuel_capacity_factor|fuel|0.10');
       Desc = '除各国自有的军队之外，条约体系里还有直接归联合司令部的一体化部队与分队。这一层部队不挂在任何一国的国防部下面，是「联合」这两个字最实的部分。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_unified_equipment'; Zh = '统一装备制式'; Cost = 10;
       V = @('mil|supply_consumption_factor|supply|-0.10', 'mil|production_speed_arms_factory_factor|production|0.10', 'mil|land_equipment_upgrade_xp_cost|equip_xp|-0.10', 'mil|army_fuel_capacity_factor|fuel|0.10');
       Raw = @('add_equipment_to_stockpile = { type = infantry_equipment amount = 2000 }');
       Desc = '冷战期间，苏联按自己的样子塑造东欧各国军队，把它们整成准备与北约对抗的部队 —— 装备制式统一是这件事的一部分：一国的弹药在另一国的枪里能用，一国的油料加进另一国的坦克。而统一之所以维持得住，靠的是指挥链：联合武装部队总司令与总参谋长历来由苏联国防部第一副部长、苏联武装部队第一副总参谋长出任。—— 记于【en】Warsaw Pact 条＋〈华沙条约组织〉条「结构」，本项目据英文/中文转译。' },

    @{ Id = 'hof_ma_mil_air_defence'; Zh = '统一防空系统'; Cost = 10;
       V = @('mil|static_anti_air_damage_factor|aa|0.15', 'mil|industry_air_damage_factor|air_dmg|-0.15', 'mil|army_defence_factor|defence|0.05');
       Raw = @('capital_scope = { add_building_construction = { type = anti_air_building level = 2 instant_build = yes } }');
       Desc = '联合武装部队司令部的职责是「对华约武装部队的领导、训练、装备和调动」，而它指挥与控制的是成员国的全部军事力量；总司令同时是苏联国防部第一副部长。防空是这件事里最不能分国界的一项 —— 空情图上一条线画错，后面所有拦截都错。本节点按用户口径把防空落到首都。—— 记于〈华沙条约组织〉条「结构」，中文维基；＋【en】Warsaw Pact 条，本项目据英文转译。' },

    @{ Id = 'hof_ma_mil_joint_exercises'; Zh = '联合演习'; Cost = 10;
       V = @('mil|army_org_factor|org|0.10', 'mil|max_planning_factor|planning|0.05', 'mil|attrition|attrition|-0.10', 'mil|training_time_factor|training|-0.10');
       Raw = @('army_experience = 25');
       Desc = '1961 年起举行「友谊演习」等年度联合演习。联合部队在入侵演习中反复演练大规模使用核武器，例如 1964 年捷克方向的计划与「七日抵达莱茵河」演习。把损耗练在演习场里，就少练在战场上。—— 记于〈华沙条约组织〉条，中文维基。' },

    @{ Id = 'hof_ma_mil_doctrine'; Zh = '统一军事学说'; Cost = 10;
       V = @('mil|army_attack_factor|attack|0.10', 'mil|breakthrough_factor|breakthrough|0.05');
       Raw = @('army_experience = 25');
       Desc = '阿尔巴尼亚 1968 年退出后，罗马尼亚仍是唯一拥有独立军事学说的条约成员国 —— 该学说否认苏联有权使用其武装力量，并避免绝对依赖苏联的军事装备来源。它也是唯一在遭受武装袭击时没有义务对苏联进行军事防御的非苏联成员国。一份共同条令里，这一个是例外。—— 记于〈华沙条约组织〉条「罗马尼亚和阿尔巴尼亚」，中文维基。' },

    @{ Id = 'hof_ma_mil_officer_training'; Zh = '军官培养体系';
       V = @('mil|conscription_factor|conscription|0.05', 'mil|weekly_manpower|manpower|250', 'mil|training_time_factor|training|-0.10');
       Raw = @('army_experience = 25');
       Desc = '华约的军官训练不走各国自办的路：国防部长委员会的主要任务之一就是研究「联合武装部队的训练、演习、组织建设等问题」，而联合武装部队总司令历来由苏联国防部第一副部长出任、总参谋长历来由苏联武装部队第一副总参谋长出任。训练大纲与指挥岗位用的是同一套体系 —— 一批人在同一间教室里读完同一套教材，这比任何一份共同条令都更牢固。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_licensed_production'; Zh = '许可生产与军事技术援助';
       V = @('mil|production_speed_arms_factory_factor|production|0.15', 'mil|land_equipment_upgrade_xp_cost|equip_xp|-0.10');
       Raw = @('add_equipment_to_stockpile = { type = small_plane_fighter_airframe amount = 120 }');
       Desc = '华约各国的装备来源本来统一在苏联身上 —— 到 1960 年代末，罗马尼亚之所以被单列出来，正因为它「避免绝对依赖苏联的军事装备来源」，后来连情报与安全部门的苏联顾问都撤了出去。也就是说，默认状态就是依赖：许可生产把「援助」变成了「同一套图纸」。—— 记于〈华沙条约组织〉条「罗马尼亚和阿尔巴尼亚」，中文维基。' },

    @{ Id = 'hof_ma_mil_defence_ministers'; Zh = '国防部长委员会'; Cost = 10;
       V = @('mil|command_power_gain|command|0.05', 'mil|max_command_power|command_max|25', 'mil|max_planning_factor|planning|0.05');
       Desc = '国防部长委员会是华约的最高军事机构，由缔约国国防部长、华约联合武装部队总司令和总参谋长等人组成，主要任务是研究共同的军事政策及联合武装部队的训练、演习、组织建设等问题。1969 年设立。—— 记于〈华沙条约组织〉条「结构」，中文维基。' },

    @{ Id = 'hof_ma_mil_committees'; Zh = '军事委员会与各专业委员会';
       V = @('mil|supply_consumption_factor|supply|-0.05', 'mil|supply_factor|supply_cap|0.10');
       Desc = '政治协商委员会下设两条常设腿：常设委员会（驻莫斯科）与联合秘书处（设在莫斯科的执行机构）—— 一个负责想，一个负责办。1969 年 3 月 17 日布达佩斯会议在讨论欧洲安全的同时，也审议了「加强和完善华约军事组织」的问题，分口办事的各类专业委员会正是这一轮「完善」的产物：它们管的是最不体面也最要紧的事，油料表、备件号、运输时刻。—— 记于〈华沙条约组织〉条「结构」，中文维基；＋〈华沙条约组织〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_mil_mbfr'; Zh = '维也纳裁军谈判'; Cost = 10;
       V = @('mil|war_support_factor|war_support|0.05');
       Raw = @('every_country = {',
               '	limit = {',
               '		OR = { original_tag = USA original_tag = ENG original_tag = FRA original_tag = GER }',
               '	}',
               '	add_opinion_modifier = { target = ROOT modifier = hof_ma_mbfr_detente }',
               '}');
       Desc = '中欧相互均衡裁军谈判（MBFR，通称中欧裁军谈判）是关于中欧常规武装力量削减的一系列谈判，自 1973 年至 1989 年在维也纳举行，由北约与华约各成员国共同参加，预备性会谈 1973 年 1 月在维也纳举行。苏方拒绝「MBFR」这个名称，因为「均衡」一词暗示中欧占常规优势的华约本应比北约削减得更多。谈判本身没有谈成，但「坐下来」这件事持续了十五年。本节点按史实给西方四国好感修正。—— 记于〈中欧相互均衡裁军谈判〉条，中文维基。' },

    @{ Id = 'hof_ma_mil_csce'; Zh = '全欧安全会议'; Icon = 'GFX_hof_ma_osce'; Cost = 10;
       V = @('mil|army_defence_factor|defence|0.05', 'mil|war_support_factor|war_support|0.05');
       Raw = @('add_ideas = hof_ma_idea_csce');
       Desc = '华约政治协商委员会 1969 年 3 月 17 日布达佩斯会议通过《关于加强欧洲和平与安全的宣言》，并向所有欧洲国家发出呼吁。此后是 1972 年 11 月起在埃斯波迪波利举行的大使级筹备会谈、1973 年 7 月 3 日赫尔辛基开幕的 35 国会议，以及 1975 年 7 月 30 日至 8 月 1 日由 35 个参加国签署的《赫尔辛基最后文件》。1955 年那句「所有欧洲国家参与的集体安全体系」，二十年后在这里落了地。—— 记于〈欧洲安全与合作会议〉条，中文维基；＋〈华沙条约组织〉条，俄文维基，本项目据俄文转译。' },

    @{ Id = 'hof_ma_mil_nuclear'; Zh = '核部署与作战计划'; Cost = 10;
       V = @('mil|army_attack_factor|attack|0.15', 'mil|army_defence_factor|defence|0.10', 'mil|breakthrough_factor|breakthrough|0.05');
       Raw = @('add_ideas = hof_ma_idea_nuclear_umbrella');
       Orig = @('add_command_power = 50');
       Desc = '在成员国的核部署安排加上华约统一作战计划：1987 年波兰公开的核打击地图显示，计划假定北约首次打击后，用核武器对莱茵河以东的奥地利、丹麦、德国和荷兰实施短暂而迅速的入侵与占领。—— 记于〈华沙条约组织〉条「后华沙条约组织」，中文维基。' }
)

# =============================================================================
# §5 机构 idea（12）—— 国策「直接奖励」那一列的载体
# =============================================================================
# 这些是【可见的民族精神】（照原版 NORDIC_command_ns 那一类）：
# 国策点下去，玩家在精神格里多出这一个机构。
# ⚠️ 它们的数值【不进 §5.1/§7.1/§9.1 的逐变量合计】—— 见 docs/un-focus/02 §5.2/§7.2/§9.2。
$maIdeas = @(
    @{ Id = 'hof_ma_idea_comecon'; Zh = '经济互助委员会'; Line = 'eco';
       Mod = @('production_speed_industrial_complex_factor = 0.05');
       Desc = '成员国按协调过的计划分工生产，同类产品的产线向一两个国家集中。' },
    @{ Id = 'hof_ma_idea_division_of_labour'; Zh = '国际社会主义分工表'; Line = 'eco';
       Mod = @('production_speed_industrial_complex_factor = 0.05');
       Desc = '哪一国造什么、造多少，写在一张表上；计划合作委员会照着它核对。' },
    @{ Id = 'hof_ma_idea_integration_programme'; Zh = '社会主义经济一体化纲要'; Line = 'eco';
       Mod = @('production_speed_industrial_complex_factor = 0.05', 'industrial_capacity_dockyard = 0.05');
       Desc = '一体化自此成为正式用语：生产、科技、贸易、货币各自有分册。' },
    @{ Id = 'hof_ma_idea_joint_research_org'; Zh = '联合研究组织'; Line = 'eco';
       Mod = @('research_speed_factor = 0.05', 'research_sharing_per_country_bonus_factor = 0.05');
       Desc = '标准化研究所与三个研究所把成员国的标准、情报与文献并成一套。' },
    @{ Id = 'hof_ma_idea_cominform'; Zh = '共产党和工人党情报局'; Line = 'pol';
       Mod = @('political_power_factor = 0.05');
       Desc = '九国党的常设联络机关：交换情报，也交换口径。' },
    @{ Id = 'hof_ma_idea_cominform_press'; Zh = '《争取持久和平，争取人民民主！》'; Line = 'pol';
       Mod = @('opinion_gain_monthly_factor = 0.05');
       Desc = '情报局的机关报，用多种文字同时出版，直送各党基层。' },
    @{ Id = 'hof_ma_idea_wpc'; Zh = '世界和平理事会'; Line = 'pol';
       Mod = @('opinion_gain_monthly_factor = 0.05');
       Desc = '以斯德哥尔摩呼吁为起点，把和平做成一个可以长期签名的机构。' },
    @{ Id = 'hof_ma_idea_oir'; Zh = '国际广播组织'; Line = 'pol';
       Mod = @('drift_defence_factor = 0.05', 'compliance_growth_on_our_occupied_states = 0.05');
       Desc = '节目交换与技术标准：唯一不需要对方政府同意就能抵达的那一层。' },
    @{ Id = 'hof_ma_idea_friendship_societies'; Zh = '对外友好与文化联络协会'; Line = 'pol';
       Mod = @('opinion_gain_monthly_factor = 0.05', 'improve_relations_maintain_cost_factor = -0.05');
       Desc = '各国「苏友协」的网络，接替 1925 年的 ВОКС；往来不必都走外交部。' },
    @{ Id = 'hof_ma_idea_first_secretaries'; Zh = '第一书记与政府首脑会议'; Line = 'pol';
       Mod = @('political_power_factor = 0.05', 'stability_factor = 0.05');
       Desc = '章程上找不到、机构表上没有，但所有真正的决定都在这里做出。' },
    @{ Id = 'hof_ma_idea_warsaw_treaty'; Zh = '华沙条约组织'; Line = 'mil';
       Mod = @('army_defence_factor = 0.05', 'war_support_factor = 0.05');
       Desc = '《友好合作互助条约组织》：八国承诺共同防御任何受到攻击的成员。' },
    @{ Id = 'hof_ma_idea_joint_command'; Zh = '联合武装部队司令部'; Line = 'mil';
       Mod = @('command_power_gain = 0.05', 'army_org_factor = 0.05');
       Desc = '各国派一名将军常驻，总指挥部在华沙、军事总部在莫斯科。' },
    @{ Id = 'hof_ma_idea_csce'; Zh = '赫尔辛基最后文件'; Line = 'mil';
       Mod = @('war_support_factor = 0.05', 'stability_factor = 0.05');
       Desc = '1975 年 8 月 1 日签署：演习通报与信任措施写进条文。' },
    @{ Id = 'hof_ma_idea_nuclear_umbrella'; Zh = '核保护伞'; Line = 'mil';
       Mod = @('army_attack_factor = 0.05');
       Desc = '在成员国的核部署安排加上一份统一的作战计划。' }
)

# =============================================================================
# §6 三个动态民族精神（容器）
# =============================================================================
# 机制蓝本：本项目 common/dynamic_modifiers/hof_ic_<人>_dm.txt（值写成变量名）
#   原因：idea 的 modifier 是静态的、读不了变量；DM 可以读。
#   值由国策 add_to_variable 逐条累加。
$maDms = @(
    @{ Id = 'hof_ma_dm_eco'; Zh = '经济互助委员会'; Line = 'eco';
       Desc = '经互会成员国之间协调计划、分工生产、互换能源与原料。这条线每完成一个国策，下列数值就累积一层。' },
    @{ Id = 'hof_ma_dm_pol'; Zh = '共产党和工人党情报局'; Line = 'pol';
       Desc = '从情报局到群众组织、再到第一书记会议：党际协调的每一层。这条线每完成一个国策，下列数值就累积一层。' },
    @{ Id = 'hof_ma_dm_mil'; Zh = '华沙条约组织'; Line = 'mil';
       Desc = '从条约本体到联合司令部、统一制式、防空与核部署。这条线每完成一个国策，下列数值就累积一层。' }
)

# =============================================================================
# §7 逐国 offset（22 条 · 2026-09-21 加暹罗）—— 数据源 docs/reference/reports/mutual-tree-bbox-report.txt
#   ⚠️ v7 起 offset 一条都不发射，本表【仅存档】；数字仅供将来要重新启用 offset 时参考。
# =============================================================================
# 表里存的是【该树的 X 最大】（MaxX），头部落点在发出去时才算：
#     offset.x = MaxX + $stripHalf + 3
#   ⚠️ 为什么不是 MaxX + 4：带子从头节点往【左】还要伸 $stripHalf (=15) 格，
#      头部落点必须让【带子的最左边】也落在树的右侧（MaxX + 3 > MaxX），否则会压到树。
# y 一律 -24（把带子从保险基准 y = 24 拉回 y = 0）
$maOffsets = @(
    @{ Tree = 'soviet_focus';                  MaxX =   81 },   # SOV
    @{ Tree = 'Mongolia_focus';                MaxX =   36 },   # MON
    @{ Tree = 'finnish_focus';                 MaxX =   41 },   # FIN
    @{ Tree = 'sweden_focus';                  MaxX =   35 },   # SWE
    @{ Tree = 'norwegian_focus';               MaxX =   94 },   # NOR
    @{ Tree = 'danish_focus';                  MaxX =   67 },   # DEN
    @{ Tree = 'iceland_tree';                  MaxX =   37 },   # ICE
    @{ Tree = 'r56_afghanistan_focus';         MaxX =   87 },   # AFG
    @{ Tree = 'saudi_focus';                   MaxX =    6 },   # SAU
    @{ Tree = 'philippines_focus';             MaxX =   73 },   # PHI
    @{ Tree = 'cuban_focus';                   MaxX =   72 },   # CUB
    @{ Tree = 'argentine_focus_tree';          MaxX =   39 },   # ARG
    @{ Tree = 'ethiopia_tree';                 MaxX =   75 },   # ETH
    @{ Tree = 'french_focus';                  MaxX =   20 },   # FRA
    @{ Tree = 'polish_focus';                  MaxX =   46 },   # POL
    @{ Tree = 'wuw_hungarian_focus';           MaxX =   90 },   # HUN
    @{ Tree = 'estonia_tree';                  MaxX =   49 },   # EST
    @{ Tree = 'latvia_tree';                   MaxX =   48 },   # LAT
    @{ Tree = 'lithuania_tree';                MaxX =   56 },   # LIT
    @{ Tree = 'australia_taog_focus';          MaxX =  127 },   # AST
    @{ Tree = 'siam_focus';                    MaxX =  106 },   # SIA（2026-09-21 加；逐格实测 X 最大 106）
    # PRC（2026-09-20 第四轮口径：中共纳入通用线）—— 最后一项【不能带尾逗号】
    @{ Tree = 'china_communist_focus_sea';     MaxX =   64 }    # PRC
)

# =============================================================================
# §8 发射：国策文件
# =============================================================================
Write-Output ''
Write-Output '======== 1. 国策文件 common/national_focus/hof_ma_joint.txt ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 需求 C：经互会通用线（S5）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 由 build/gen-hof-ma-common-lines.ps1 生成，勿手改。')
$null = $sb.AppendLine('# 设计见 docs/un-focus/01-s5-mutual-aid-common-lines.md；数值见 docs/un-focus/02-s5-values.md。')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# 结构：1 个 shared_focus（头）+ 58 个 joint_focus（3 条线：经济 23 / 政治 18 / 军事 17）')
$null = $sb.AppendLine('#   · 头 = 莫洛托夫计划 · 三条线互不串线（真实历史里三个机构本来就是并列搭起来的）')
$null = $sb.AppendLine('#   · 摆位：不使用 relative_position_id；图瓦专用 y+60 offset，其余国家保持绝对格位。')
$null = $sb.AppendLine('#     ① 每个节点写【绝对格位】：头 (0, 24)，子节点 (col, 24 + row)')
$null = $sb.AppendLine('#     ② 图瓦本国树深至 y=80，故 59 个节点均对 TAN 单独下移 60 行')
$null = $sb.AppendLine('#     ⇒ 带子占 x ∈ [-21, +21]、y ∈ [24, 30]，【对 22 棵树全都是空区】：')
$null = $sb.AppendLine('#        ⭐ 实测（逐格解析 mod/heart_of_iron/common/national_focus/*.txt）：')
$null = $sb.AppendLine('#          21 棵树真实 Y 最大 = **11**（philippines_focus）⇒ y 从 24 起 = 至少空出 13 行')
$null = $sb.AppendLine('#     （2026-09-20 用户口径「会不会是国策窗口宽度不够……那就把这个国策丢到下面去」）')
$null = $sb.AppendLine('#       后台实测：不是宽度问题，是【旧的 MaxX 表测错了】——')
$null = $sb.AppendLine('#       french_focus 表里 20 / 实测 67、saudi_focus 6/11、polish_focus 46/54')
$null = $sb.AppendLine('#       ⇒ 这三棵树的带子被 offset 送进了树身里。阿富汗实测 87 = 表里 87，所以它正常。')
$null = $sb.AppendLine('#       既然测量不可靠，就【彻底不用测量】—— 见 docs/99 §47.14')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# 图标：四个 sprite 全部是【原版已有的】（interface/goals.gfx），零缺图风险。')
$null = $sb.AppendLine('#   头 = 马克思-列宁主义道路 · 经济 = 经互会 · 政治 = 共产国际 · 军事 = 华沙条约组织')
$null = $sb.AppendLine('#   （用户 2026-09-20 口径：按【国策中文显示名】反查原版国策，再读它的 icon）')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()

# ---- 头 ----
# ⚠️ 计数器必须【在发射头节点之前】初始化（头也带 21 条 offset）
$tuvaOffsetY = 60     # 图瓦本国树最深 y=80；经互会带子移到 y=87..93
$maOffsetBlocks = 0

$null = $sb.AppendLine('# ---- 头：莫洛托夫计划（唯一的 shared_focus）----')
$null = $sb.AppendLine('shared_focus = {')
$null = $sb.AppendLine("`tid = $($maHead.Id)")
$null = $sb.AppendLine("`ticon = $iconHead")
$null = $sb.AppendLine("`tx = $baseX")
$null = $sb.AppendLine("`ty = $baseY")
$null = $sb.AppendLine("`toffset = { x = 0 y = $tuvaOffsetY trigger = { tag = TAN } }")
$maOffsetBlocks++
$null = $sb.AppendLine("`tcost = $($maHead.Cost)")
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 普通树 y=27..33；图瓦单独 y=87..93')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 准入（用户口径：共产主义政体 且 与苏联同一阵营或为其附庸 —— 与北欧一样「符合条件大家都能点」）')
$null = $sb.AppendLine('`t# ⚠️ 用 available 而不是 allow_branch：allow_branch 只在国策树加载时判定，')
$null = $sb.AppendLine('`t#    一个国家【中途】转成共产主义时不一定刷新得到；available 是持续判定的，')
$null = $sb.AppendLine('`t#    而且正好给出用户要的「看得见、点不了」。')
$null = $sb.AppendLine('`tavailable = {')
$null = $sb.AppendLine('`t`tcustom_trigger_tooltip = {')
$null = $sb.AppendLine('`t`t`ttooltip = hof_ma_available_government_tt')
$null = $sb.AppendLine('`t`t`thas_government = communism')
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t`tcustom_trigger_tooltip = {')
$null = $sb.AppendLine('`t`t`ttooltip = hof_ma_available_tt')
$null = $sb.AppendLine('`t`t`tOR = {')
$null = $sb.AppendLine('`t`t`t`ttag = SOV')
$null = $sb.AppendLine('`t`t`t`tis_in_faction_with = SOV')
$null = $sb.AppendLine('`t`t`t`tis_subject_of = SOV')
$null = $sb.AppendLine('`t`t`t}')
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine()
$null = $sb.AppendLine("`tsearch_filters = { $($srchLine.pol) }")
$null = $sb.AppendLine()
$null = $sb.AppendLine('`tcompletion_reward = {')
$null = $sb.AppendLine('`t`thidden_effect = { SOV = { set_country_flag = hof_ma_done_hof_ma_founding } }')
$null = $sb.AppendLine('`t`tif = {')
$null = $sb.AppendLine('`t`t`tlimit = { hof_ma_eligible = yes }')
$null = $sb.AppendLine("`t`tcustom_effect_tooltip = hof_ma_head_dm_tt")
$null = $sb.AppendLine('`t`t# 累积数值：三个容器一起喂')
foreach ($v in $maHead.V) {
    $dm, $mod, $suf, $num = $v -split '\|'
    $null = $sb.AppendLine('`t`tadd_to_variable = {')
    $null = $sb.AppendLine("`t`t`thof_ma_${dm}_$suf = $num")
    $null = $sb.AppendLine("`t`t`ttooltip = $(Get-MaTt $mod)")
    $null = $sb.AppendLine('`t`t}')
}
foreach ($r in $maHead.Raw) { $null = $sb.AppendLine("`t`t$r") }
# 🚩 2026-09-20 订正：`shared_focus`【不支持】completion_reward_joint_originator /
#    _member（那两个键只有 joint_focus 有）。日志实测：
#    `Unexpected token: completion_reward_joint_originator ... hof_ma_joint.txt`
#    ⇒ 头节点的 Orig 效果改挂普通的 completion_reward。
foreach ($r in $maHead.Orig) { $null = $sb.AppendLine("`t`t$r") }
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t`thidden_effect = { SOV = { hof_ma_reconcile_all = yes } }')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

# ---- 三条线 ----
$lineNodes = @(
    @{ Key = 'eco'; Name = '经济互助委员会'; Nodes = $maEco },
    @{ Key = 'pol'; Name = '共产党和工人党情报局'; Nodes = $maPol },
    @{ Key = 'mil'; Name = '华沙条约组织'; Nodes = $maMil }
)
$totalFocus = 1
# 布局包围盒（自检用：漂移一旦回来，§14 会 FAIL）
$stripMinX = 999; $stripMaxX = -999; $stripMaxY = 0
foreach ($ln in $lineNodes) {
    $clusters = $lineClusters[$ln.Key]
    $cols     = $lineCol[$ln.Key]
    $names    = $lineClusterName[$ln.Key]
    if ($clusters.Count -ne $cols.Count)  { throw "$($ln.Key)：支线数 $($clusters.Count) 与列数 $($cols.Count) 不一致" }
    if ($names.Count    -ne $cols.Count)  { throw "$($ln.Key)：支线名数 $($names.Count) 与列数 $($cols.Count) 不一致" }
    # 大门 = 第一条支线的第一个节点（它挂到头节点上）
    $gate = $ln.Nodes[$clusters[0][0]].Id
    $null = $sb.AppendLine("# =============================================================================")
    $null = $sb.AppendLine("# $($ln.Name)：$($ln.Nodes.Count) 条 = $($clusters.Count) 条支线（照原版 nordic_shared 的放射写法）")
    $null = $sb.AppendLine("#   大门 = $gate（prerequisite 挂头节点）；其余支线 prerequisite 挂【大门】；摆位一律绝对坐标 + 自带 offset")
    $null = $sb.AppendLine("# =============================================================================")
    for ($k = 0; $k -lt $clusters.Count; $k++) {
        $col    = $cols[$k]
        $isGate = ($k -eq 0)
        $row0   = if ($isGate) { 1 } else { 2 }
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("# ---- 支线 $($k + 1)：$($names[$k])（$($clusters[$k].Count) 条 · 第 $col 列）----")
        for ($j = 0; $j -lt $clusters[$k].Count; $j++) {
        $n   = $ln.Nodes[$clusters[$k][$j]]
        $row = $row0 + $j
        # ⚠️ $prev 现在【只用于 prerequisite】（支线内成链）；摆位一律锚头节点
        $prev = if ($j -gt 0)                { $ln.Nodes[$clusters[$k][$j - 1]].Id }
                elseif ($isGate)             { $maHead.Id }
                else                         { $gate }
        if ($col -lt $stripMinX) { $stripMinX = $col }
        if ($col -gt $stripMaxX) { $stripMaxX = $col }
        if ($row -gt $stripMaxY) { $stripMaxY = $row }
        $cost = if ($n.ContainsKey('Cost')) { $n.Cost } else { 5 }
        $null = $sb.AppendLine('joint_focus = {')
        $null = $sb.AppendLine("`tid = $($n.Id)")
                # 图标：默认用本线那张（原版已有），节点自带 Icon 时用节点自己的
        $ic = if ($n.ContainsKey('Icon')) { $n.Icon } else { $iconLine[$ln.Key] }
        $null = $sb.AppendLine("`ticon = $ic")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("`tprerequisite = { focus = $prev }")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("`t# (x, y) = 【绝对格位】（带子固定在树下方：列 $col、行 $($baseY + $row)）")
        $null = $sb.AppendLine("`t# 不写 relative_position_id；图瓦节点单独下移")
        $null = $sb.AppendLine("`tx = $col")
        $null = $sb.AppendLine("`ty = $($baseY + $row)")
        $null = $sb.AppendLine("`toffset = { x = 0 y = $tuvaOffsetY trigger = { tag = TAN } }")
        $maOffsetBlocks++
        $null = $sb.AppendLine("`tcost = $cost")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("`tsearch_filters = { $($srchLine[$ln.Key]) }")
        $null = $sb.AppendLine()
        if ($n.Id -eq 'hof_ma_mil_warsaw_treaty') {
            $null = $sb.AppendLine("`t# 军事线大门：用户口径「门槛做看得见点不了的」—— 额外一道 available")
            $null = $sb.AppendLine('`tavailable = {')
            $null = $sb.AppendLine('`t`tcustom_trigger_tooltip = {')
            $null = $sb.AppendLine('`t`t`ttooltip = hof_ma_mil_gate_tt')
            $null = $sb.AppendLine('`t`t`thas_army_size = { size > 15 }')
            $null = $sb.AppendLine('`t`t`thas_war_support > 0.30')
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t}')
            $null = $sb.AppendLine()
        }
        $null = $sb.AppendLine("`t# 谁是 joint：由触发器定义（见 common/scripted_triggers/hof_ma_scripted_triggers.txt）")
        $null = $sb.AppendLine('`tjoint_trigger = { hof_ma_joint_trigger = yes }')
        $null = $sb.AppendLine()
        $null = $sb.AppendLine('`tcompletion_reward = {')
        $null = $sb.AppendLine("`t`thidden_effect = { SOV = { set_country_flag = hof_ma_done_$($n.Id) } }")
        $null = $sb.AppendLine('`t`tif = {')
        $null = $sb.AppendLine('`t`t`tlimit = { hof_ma_eligible = yes }')
        $null = $sb.AppendLine("`t`tcustom_effect_tooltip = hof_ma_line_dm_tt")
        foreach ($v in $n.V) {
            $dm, $mod, $suf, $num = $v -split '\|'
            $null = $sb.AppendLine('`t`tadd_to_variable = {')
            $null = $sb.AppendLine("`t`t`thof_ma_${dm}_$suf = $num")
            $null = $sb.AppendLine("`t`t`ttooltip = $(Get-MaTt $mod)")
            $null = $sb.AppendLine('`t`t}')
        }
        if ($n.ContainsKey('Raw')) { foreach ($r in $n.Raw) { $null = $sb.AppendLine("`t`t`t$r") } }
        $null = $sb.AppendLine('`t`t}')
        # 首都资源不受资格限制。完成奖励先给联合参与国，再把尚未领取者补到所有挂载树。
        if ($n.ContainsKey('Resource')) {
            $resourceFlag = "hof_ma_resource_done_$($n.Id)"
            $null = $sb.AppendLine('`t`tif = {')
            $null = $sb.AppendLine("`t`t`tlimit = { NOT = { has_country_flag = $resourceFlag } }")
            foreach ($r in $n.Resource) { $null = $sb.AppendLine("`t`t`t$r") }
            $null = $sb.AppendLine("`t`t`thidden_effect = { set_country_flag = $resourceFlag }")
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine("`t`thidden_effect = { hof_ma_distribute_resource_$($n.Id) = yes }")
        }
        $null = $sb.AppendLine('`t`thidden_effect = { SOV = { hof_ma_reconcile_all = yes } }')
        $null = $sb.AppendLine('`t}')
        if ($n.ContainsKey('Orig') -and $n.Orig.Count -gt 0) {
            $null = $sb.AppendLine()
            $null = $sb.AppendLine('`tcompletion_reward_joint_originator = {')
            $null = $sb.AppendLine('`t`tif = {')
            $null = $sb.AppendLine('`t`t`tlimit = { hof_ma_eligible = yes }')
            foreach ($r in $n.Orig) { $null = $sb.AppendLine("`t`t`t$r") }
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t}')
        }
        $null = $sb.AppendLine('}')
        $null = $sb.AppendLine()
        $totalFocus++
        }
    }
}
$maJointText = $sb.ToString()
Write-ModFile 'common/national_focus/hof_ma_joint.txt' $maJointText
Write-Output ("  头 1 + 经济 $($maEco.Count) + 政治 $($maPol.Count) + 军事 $($maMil.Count) = $totalFocus 个块")

# =============================================================================
# §9 发射：三个动态民族精神
# =============================================================================
Write-Output ''
Write-Output '======== 2. 三个动态民族精神 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 需求 C：经互会通用线的三个动态民族精神（由 build/gen-hof-ma-common-lines.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 🚩 值写成【变量名】，由国策 add_to_variable 累加 —— 蓝本：R56')
$null = $sb.AppendLine('#    common/dynamic_modifiers/0_dynamic_modifiers.txt 的 SOV_defense_industry_dynamic_modifier')
$null = $sb.AppendLine('#    原因：idea 的 modifier 是静态的、读不了变量。')
$null = $sb.AppendLine('# 数值刷新：每天自动重算；add_to_variable 后要立刻生效就补 force_update_dynamic_modifier')
$null = $sb.AppendLine('# 逐变量合计见 docs/un-focus/02-s5-values.md §5.1 / §7.1 / §9.1。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
# 🚩 2026-09-20 订正：dynamic_modifiers【没有外层 wrapper】—— 原版/R56 都是每个 DM 直接写在文件根级
#    （实测 R56 common/dynamic_modifiers/AFG.txt / AST.txt）。写了 wrapper 会报
#    `invalid modifier: hof_ma_dm_eco`。
foreach ($dm in $maDms) {
    # 汇总本线用到的变量（去重、保序）
    $vars = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $nodes = switch ($dm.Line) { 'eco' { $maEco } 'pol' { $maPol } 'mil' { $maMil } }
    foreach ($n in $nodes) {
        foreach ($v in $n.V) {
            $d, $mod, $suf, $num = $v -split '\|'
            if ($d -ne $dm.Line) { continue }
            if (-not $seen.ContainsKey($mod)) { $seen[$mod] = $true; $vars.Add("$mod|$suf") }
        }
    }
    # 头节点里属于本容器的变量也要收（否则容器读不到那个变量）
    foreach ($v in $maHead.V) {
        $d, $mod, $suf, $num = $v -split '\|'
        if ($d -ne $dm.Line) { continue }
        if (-not $seen.ContainsKey($mod)) { $seen[$mod] = $true; $vars.Add("$mod|$suf") }
    }
    $null = $sb.AppendLine("$($dm.Id) = {")
    $null = $sb.AppendLine("`ticon = $($dmIcon[$dm.Line])")
    $null = $sb.AppendLine('`tenable = {')
    $null = $sb.AppendLine('`t`thas_country_flag = hof_ma_joined')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('`tremove_trigger = {')
    $null = $sb.AppendLine('`t`tNOT = { hof_ma_eligible = yes }')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine()
    foreach ($vv in $vars) {
        $mod, $suf = $vv -split '\|'
        $null = $sb.AppendLine("`t$mod = hof_ma_$($dm.Line)_$suf")
    }
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
    Write-Output ("  [OK ] $($dm.Zh)：容器读入 $($vars.Count) 条变量")
}
Write-ModFile 'common/dynamic_modifiers/hof_ma_dynamic_modifiers.txt' $sb.ToString()

# =============================================================================
# §10 发射：机构 idea
# =============================================================================
Write-Output ''
Write-Output '======== 3. 机构 idea ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 需求 C：经互会通用线的机构 idea（由 build/gen-hof-ma-common-lines.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 这些都是【可见的民族精神】（照原版 NORDIC_command_ns 那一类）：国策「直接奖励」')
$null = $sb.AppendLine('# 那一列的载体 —— 点下去，玩家在精神格里多出这一个机构。')
$null = $sb.AppendLine('# ⚠️ 它们的数值【不进】docs/un-focus/02 §5.1/§7.1/§9.1 的逐变量合计（另见 §5.2/§7.2/§9.2）。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
# 🚩🚩 2026-09-20 订正：common/ideas/*.txt 必须有【类别外层】。日志实测 14 条
#    `Unexpected token: hof_ma_idea_*`（把每个 idea 当成了类别的名字）。
#    蓝本 = 原版 common/ideas/nordic_shared.txt：
#      ideas = {
#          country = {
#              <id> = { picture = ...  cancel = { ... }  modifier = { ... } }
#          }
#      }
#    `picture` 取的是【不带 GFX_idea_ 前缀】的名字（原版 nordic 写 picture = generic_war_preparation）。
$null = $sb.AppendLine('ideas = {')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`tcountry = {')
$null = $sb.AppendLine()
foreach ($id in $maIdeas) {
    # 三类各给一个【已核过存在于 interface/ideas.gfx】的通用图
    # ⭐ 三个挂「机构本体」的 idea 用【真图】（民族精神版，见 build/gen-hof-ma-icons.ps1）；
    #    其余仍是原版通用图占位 —— 等美术按 docs/un-focus/03 交图后逐个替换。
    # 🚩 idea 的 picture 取的是【不带 GFX_idea_ 前缀】的名字，且原版那批都带 `generic_`
    #    （如 picture = generic_war_preparation -> GFX_idea_generic_war_preparation）。
    #    踩过：漏掉 generic_ 前缀 -> sprite 不存在。verify-s2 §14d 会抓。
    $picReal = @{ 'hof_ma_idea_comecon'       = 'hof_ma_comecon'      # 原版图裁方
                  'hof_ma_idea_cominform'     = 'hof_ma_cominform'   # 抠的实物
                  'hof_ma_idea_warsaw_treaty' = 'hof_ma_warsawpact'  # 原版图裁方
                  'hof_ma_idea_oir'           = 'hof_ma_oirt'        # 抠的实物（2026-09-21 加）
                  'hof_ma_idea_csce'          = 'hof_ma_osce'        # 抠的实物（2026-09-21 加）
                  'hof_ma_idea_wpc'           = 'hof_ma_wpc'         # 毕加索的鸽子（1950 年中国「保卫世界和平」邮票裁出）
                  # ⭐ 2026-09-25 用户口径：「经互会和华约的不是已经有了吗，游戏内自带」
                  #    ⇒ 经济线 / 军事线的 idea 直接套用那两张的【方形版】（`gen-hof-ma-idea-icons.py`
                  #      从游戏自带国策图裁方、缩到 60x60 的同一批产物）—— **零新增美术**。
                  #    ⛔ 没套用的只剩 3 个政治线 idea（机关报 / 友好协会 / 第一书记会议），
                  #      它们等 docs/un-focus/03 第 3 批交图。
                  'hof_ma_idea_division_of_labour'    = 'hof_ma_comecon'
                  'hof_ma_idea_integration_programme' = 'hof_ma_comecon'
                  'hof_ma_idea_joint_research_org'    = 'hof_ma_comecon'
                  'hof_ma_idea_joint_command'         = 'hof_ma_warsawpact'
                  'hof_ma_idea_nuclear_umbrella'      = 'hof_ma_warsawpact' }
    $pic = if ($picReal.ContainsKey($id.Id)) { $picReal[$id.Id] }
           elseif ($id.Id -match 'warsaw|joint_command|csce|nuclear') { 'generic_war_preparation' }
           elseif ($id.Id -match 'cominform|wpc|oir|friendship|first_secretaries') { 'generic_communist_army' }
           else { 'generic_build_infrastructure' }
    $null = $sb.AppendLine("`t`t$($id.Id) = {")
    $null = $sb.AppendLine("`t`t`tname = $($id.Id)")
    $null = $sb.AppendLine("`t`t`tpicture = $pic")
    $null = $sb.AppendLine('`t`t`tcancel = { NOT = { hof_ma_eligible = yes } }')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('`t`t`tmodifier = {')
    foreach ($m in $id.Mod) { $null = $sb.AppendLine("`t`t`t`t$m") }
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    $null = $sb.AppendLine()
}
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-ModFile 'common/ideas/hof_ma_ideas.txt' $sb.ToString()
Write-Output ("  共 $($maIdeas.Count) 个机构 idea")

# =============================================================================
# §11 发射：触发器 + 好感修正
# =============================================================================
Write-Output ''
Write-Output '======== 4. 触发器与好感修正 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 需求 C：经互会通用线的触发器（由 build/gen-hof-ma-common-lines.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 本文件【没有】包装层，触发器直接顶层写 名称 = { }（同 common/scripted_triggers 的官方写法）')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('# 谁是「经互会」的一员（= 已完成头节点）—— 逐国求值。')
$null = $sb.AppendLine('# ⚠️ 刻意写得【宽松】：如果要求「至少还有一个同阵营成员也完成了头节点」，')
$null = $sb.AppendLine('#    1936 年开局的苏联（没有任何共产主义盟友）就一条都点不动 —— 那是功能性的坏掉。')
$null = $sb.AppendLine('hof_ma_joint_trigger = {')
$null = $sb.AppendLine('`thof_ma_eligible = yes')
$null = $sb.AppendLine('`tcustom_trigger_tooltip = {')
$null = $sb.AppendLine('`t`ttooltip = hof_ma_joint_trigger_tt')
$null = $sb.AppendLine("`t`thas_completed_focus = $headId")
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('hof_ma_eligible = {')
$null = $sb.AppendLine('`thas_government = communism')
$null = $sb.AppendLine('`tOR = { tag = SOV is_in_faction_with = SOV is_subject_of = SOV }')
$null = $sb.AppendLine('}')
Write-ModFile 'common/scripted_triggers/hof_ma_scripted_triggers.txt' $sb.ToString()

# 已完成的联合国策由苏联保留进度；每次国策完成与每周钩子补发给新成员。
# 每次从权威进度重建专用变量，避免旧存档中的增量与补发重复叠加。
$maStages = @($maHead)
foreach ($ln in $lineNodes) { $maStages += @($ln.Nodes) }
# 用挂载点清单确定资源接收范围，避免在生成器里手抄一份国家名单。
$attachListPath = Join-Path $RepRoot 'build/attach-points.json'
$attachList = Get-Content -LiteralPath $attachListPath -Raw -Encoding UTF8 | ConvertFrom-Json
$maResourceTreeIds = @($attachList.points | Where-Object { $_.s5 -ne $false } |
    ForEach-Object { $_.treeId } | Sort-Object -Unique)
if ($maResourceTreeIds.Count -lt 1) { throw '经互会资源分发找不到已挂载的国策树' }
$maVarNames = @{}
foreach ($stage in $maStages) {
    foreach ($v in $stage.V) {
        $dm, $mod, $suf, $num = $v -split '\|'
        $maVarNames["hof_ma_${dm}_$suf"] = $true
    }
}
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Generated by build/gen-hof-ma-common-lines.ps1. Do not edit by hand.')
$null = $sb.AppendLine('hof_ma_bootstrap_progress = {')
foreach ($stage in $maStages) {
    $null = $sb.AppendLine("`tif = { limit = { has_completed_focus = $($stage.Id) } set_country_flag = hof_ma_done_$($stage.Id) }")
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('hof_ma_clear_member = {')
foreach ($varName in @($maVarNames.Keys | Sort-Object)) {
    $null = $sb.AppendLine("`tset_variable = { $varName = 0 }")
}
foreach ($dm in $maDms) {
    $null = $sb.AppendLine("`tif = { limit = { has_dynamic_modifier = { modifier = $($dm.Id) } } remove_dynamic_modifier = { modifier = $($dm.Id) } }")
}
foreach ($id in $maIdeas) {
    $null = $sb.AppendLine("`tif = { limit = { has_idea = $($id.Id) } remove_ideas = $($id.Id) }")
}
$null = $sb.AppendLine('`tclr_country_flag = hof_ma_joined')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('hof_ma_reconcile_member = {')
$null = $sb.AppendLine('`tif = {')
$null = $sb.AppendLine('`t`tlimit = { hof_ma_eligible = yes SOV = { has_country_flag = hof_ma_done_hof_ma_founding } }')
$null = $sb.AppendLine('`t`tset_country_flag = hof_ma_joined')
# unlock_national_focus 按原版跳过节点，不执行 completion_reward；持续奖励仍由下方统一重建。
# 仅对实际挂载通用线的国策树同步，避免向其它国策树写入不存在的节点。
$null = $sb.AppendLine('`t`tif = {')
$null = $sb.AppendLine('`t`t`tlimit = { OR = {')
foreach ($treeId in $maResourceTreeIds) {
    $null = $sb.AppendLine("`t`t`t`thas_focus_tree = $treeId")
}
$null = $sb.AppendLine('`t`t`t} }')
foreach ($stage in $maStages) {
    $null = $sb.AppendLine("`t`t`tif = { limit = { SOV = { has_country_flag = hof_ma_done_$($stage.Id) } NOT = { has_completed_focus = $($stage.Id) } } unlock_national_focus = $($stage.Id) }")
}
$null = $sb.AppendLine('`t`t}')
foreach ($dm in $maDms) {
    $null = $sb.AppendLine("`t`tif = { limit = { NOT = { has_dynamic_modifier = { modifier = $($dm.Id) } } } add_dynamic_modifier = { modifier = $($dm.Id) } }")
}
foreach ($varName in @($maVarNames.Keys | Sort-Object)) {
    $null = $sb.AppendLine("`t`tset_variable = { $varName = 0 }")
}
foreach ($stage in $maStages) {
    $null = $sb.AppendLine("`t`tif = { limit = { SOV = { has_country_flag = hof_ma_done_$($stage.Id) } }")
    foreach ($v in $stage.V) {
        $dm, $mod, $suf, $num = $v -split '\|'
        $null = $sb.AppendLine("`t`t`tadd_to_variable = { hof_ma_${dm}_$suf = $num }")
    }
    if ($stage.ContainsKey('Raw')) {
        foreach ($r in $stage.Raw) {
            if ($r -match '^add_ideas\s*=\s*(\S+)') {
                $ideaId = $Matches[1]
                $null = $sb.AppendLine("`t`t`tif = { limit = { NOT = { has_idea = $ideaId } } add_ideas = $ideaId }")
            }
        }
    }
    $null = $sb.AppendLine('`t`t}')
}
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('hof_ma_reconcile_all = {')
$null = $sb.AppendLine('`tevery_country = {')
$null = $sb.AppendLine('`t`tif = { limit = { hof_ma_eligible = yes } hof_ma_reconcile_member = yes }')
$null = $sb.AppendLine('`t`tif = { limit = { has_country_flag = hof_ma_joined NOT = { hof_ma_eligible = yes } } hof_ma_clear_member = yes }')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')

# 四项首都资源只在节点首次完成时逐国发放一次；成员资格不参与判定。
# 联合参与国可能在 completion_reward 中先领取，统一用国家旗标去重。
foreach ($stage in $maStages) {
    if (-not $stage.ContainsKey('Resource')) { continue }
    $resourceFlag = "hof_ma_resource_done_$($stage.Id)"
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("hof_ma_distribute_resource_$($stage.Id) = {")
    $null = $sb.AppendLine('`tevery_country = {')
    $null = $sb.AppendLine('`t`tlimit = {')
    $null = $sb.AppendLine('`t`t`texists = yes')
    $null = $sb.AppendLine("`t`t`tNOT = { has_country_flag = $resourceFlag }")
    $null = $sb.AppendLine('`t`t`tOR = {')
    foreach ($treeId in $maResourceTreeIds) {
        $null = $sb.AppendLine("`t`t`t`thas_focus_tree = $treeId")
    }
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    foreach ($r in $stage.Resource) { $null = $sb.AppendLine("`t`t$r") }
    $null = $sb.AppendLine("`t`tset_country_flag = $resourceFlag")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')
}
Write-ModFile 'common/scripted_effects/hof_ma_membership_effects.txt' $sb.ToString()

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Generated by build/gen-hof-ma-common-lines.ps1. Do not edit by hand.')
$null = $sb.AppendLine('on_actions = {')
$null = $sb.AppendLine('`ton_startup = { effect = { SOV = { hof_ma_bootstrap_progress = yes hof_ma_reconcile_all = yes } } }')
$null = $sb.AppendLine('`ton_weekly = { effect = { if = { limit = { tag = SOV } hof_ma_bootstrap_progress = yes hof_ma_reconcile_all = yes } } }')
$null = $sb.AppendLine('}')
Write-ModFile 'common/on_actions/hof_ma_membership_on_actions.txt' $sb.ToString()

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 需求 C：经互会通用线的好感修正（由 build/gen-hof-ma-common-lines.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 蓝本：原版 common/opinion_modifiers/nsb_opinion_modifiers.txt')
$null = $sb.AppendLine('# 🚨 外层 opinion_modifiers = { } 绝对不能漏 —— 漏了游戏不报错、静默无效。')
$null = $sb.AppendLine('# 名称的本地化键就是修正名本身，写在 localisation/simp_chinese/hof_ma_l_simp_chinese.yml。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('opinion_modifiers = {')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 1988-06-25 经互会国家获准直接与欧共体谈贸易协定 —— 对西欧四国')
$null = $sb.AppendLine('`thof_ma_eec_trade_agreement = {')
$null = $sb.AppendLine('`t`tvalue = 30')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 1973-10-30 维也纳中欧相互均衡裁军谈判（MBFR）—— 对四国谈判对手')
$null = $sb.AppendLine('`thof_ma_mbfr_detente = {')
$null = $sb.AppendLine('`t`tvalue = 30')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('}')
Write-ModFile 'common/opinion_modifiers/hof_ma_opinion_modifiers.txt' $sb.ToString()

# =============================================================================
# §12 发射：本地化（UTF-8 带 BOM，文件名含 _l_simp_chinese，首行 l_simp_chinese:）
# =============================================================================
Write-Output ''
Write-Output '======== 5. 本地化 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('l_simp_chinese:')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # 需求 C：经互会通用线（S5）—— 由 build/gen-hof-ma-common-lines.ps1 生成，勿手改')
$null = $sb.AppendLine(' # 设计见 docs/un-focus/01，数值见 docs/un-focus/02。')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ---------- 三个动态民族精神 ----------')
foreach ($dm in $maDms) {
    $null = $sb.AppendLine(" $($dm.Id):0 `"$($dm.Zh)`"")
    $null = $sb.AppendLine(" $($dm.Id)_desc:0 `"$($dm.Desc)`"")
}
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ---------- 机构 idea ----------')
foreach ($id in $maIdeas) {
    $null = $sb.AppendLine(" $($id.Id):0 `"$($id.Zh)`"")
    $null = $sb.AppendLine(" $($id.Id)_desc:0 `"$($id.Desc)`"")
}
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ---------- 好感修正 ----------')
$null = $sb.AppendLine(' hof_ma_eec_trade_agreement:0 "与经互会直接通商"')
$null = $sb.AppendLine(' hof_ma_mbfr_detente:0 "维也纳裁军谈判"')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ---------- 头节点 ----------')
$null = $sb.AppendLine(" $($maHead.Id):0 `"$($maHead.Zh)`"")
$null = $sb.AppendLine(" $($maHead.Id)_desc:0 `"$($maHead.Desc)`"")
$null = $sb.AppendLine('')
foreach ($ln in $lineNodes) {
    $null = $sb.AppendLine(" # ---------- $($ln.Name)（$($ln.Nodes.Count) 条）----------")
    foreach ($n in $ln.Nodes) {
        $null = $sb.AppendLine(" $($n.Id):0 `"$($n.Zh)`"")
        $null = $sb.AppendLine(" $($n.Id)_desc:0 `"$($n.Desc)`"")
    }
    $null = $sb.AppendLine('')
}
$null = $sb.AppendLine(' # ---------- 条件 tooltip ----------')
$null = $sb.AppendLine(' hof_ma_available_government_tt:0 "本国是共产主义政体"')
$null = $sb.AppendLine(' hof_ma_available_tt:0 "本国与苏联处于同一阵营，或是苏联的附庸"')
$null = $sb.AppendLine(' hof_ma_joint_trigger_tt:0 "本国已完成§Y莫洛托夫计划§!，是经互会的一员"')
$null = $sb.AppendLine(' hof_ma_mil_gate_tt:0 "华沙条约组织只能在真正需要它的时候成立：本国须已有一支成规模的军队（陆军规模 > 15），且战争支持度高于 30%"')
$null = $sb.AppendLine(' hof_ma_head_dm_tt:0 "§Y经济互助委员会§!、§Y共产党和工人党情报局§!、§Y华沙条约组织§! 三个民族精神将随这条通用线一同成长："')
$null = $sb.AppendLine(' hof_ma_line_dm_tt:0 "本线对应民族精神的累积加成："')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ---------- 词条 tooltip（官方没有 <词条>_tt 的，自写；照原版格式 标签: $RIGHT|+=%1$）----------')
$null = $sb.AppendLine(' hof_ma_tt_faction_trade_opinion_factor:0 " 阵营内贸易好感: $RIGHT|+=%1$"')
$null = $sb.AppendLine(' hof_ma_tt_stability_weekly_factor:0 " 稳定度周增长: $RIGHT|+=%1$"')
$null = $sb.AppendLine(' hof_ma_tt_improve_relations_maintain_cost_factor:0 " 改善关系维持花费: $RIGHT|+=%1$"')
$null = $sb.AppendLine(' hof_ma_tt_land_equipment_upgrade_xp_cost:0 " 陆军装备改装经验花费: $RIGHT|+=%1$"')
$null = $sb.AppendLine(' hof_ma_tt_static_anti_air_damage_factor:0 " 固定防空伤害: $RIGHT|+=%1$"')
$null = $sb.AppendLine(' hof_ma_tt_army_fuel_capacity_factor:0 " 陆军燃料容量: $RIGHT|+=%1$"')
$null = $sb.AppendLine('')

$locPath = Join-Path $ModRoot 'localisation/simp_chinese/hof_ma_l_simp_chinese.yml'
$locDir = Split-Path -Parent $locPath
if (-not (Test-Path $locDir)) { New-Item -ItemType Directory -Path $locDir -Force | Out-Null }
[System.IO.File]::WriteAllText($locPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
$bom = (Get-Content -LiteralPath $locPath -Encoding Byte -TotalCount 3) -join ','
Write-Output ("  写出 {0,-58} {1,8:N0} 字节  {2}" -f 'localisation/simp_chinese/hof_ma_l_simp_chinese.yml', (Get-Item -LiteralPath $locPath).Length, $(if ($bom -eq '239,187,191') { '有BOM(正确)' } else { '无BOM(错误!)' }))

# =============================================================================
# §13 发射：注入行（21 行 shared_focus）—— 由 sync-from-r56.ps1 读
# =============================================================================
Write-Output ''
Write-Output '======== 6. shared_focus 注入行 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# ---- 需求 C：经互会通用线（定义见 common/national_focus/hof_ma_joint.txt）----')
$null = $sb.AppendLine('# 只列【头】。官方 wiki：shared_focus = <头 id> 会把它【以及所有通过 prerequisite')
$null = $sb.AppendLine('# 连到它的 shared focus】一起加进树里 —— 原版 nordic_shared.txt 就是这么做的。')
$null = $sb.AppendLine("shared_focus = $headId")

$injectPath = Join-Path $RepRoot 'build\inject-ma.txt'
[System.IO.File]::WriteAllText($injectPath, $sb.ToString(), $utf8NoBom)
Write-Output ("  写出 {0,-58} {1,8:N0} 字节（1 行 shared_focus）" -f 'build/inject-ma.txt', (Get-Item -LiteralPath $injectPath).Length)

# =============================================================================
# §14 自检
# =============================================================================
Write-Output ''
Write-Output '======== 7. 生成结果自检 ========'

$fail = 0
function Check([string]$name, [bool]$ok, [string]$detail) {
    if ($ok) { Write-Output "  [ OK ] $name$detail" }
    else { Write-Output "  [FAIL] $name$detail"; $script:fail++ }
}

Check '国策块总数 = 59' ($totalFocus -eq 59) "（实测 $totalFocus）"
Check '经济线 23' ($maEco.Count -eq 23) "（实测 $($maEco.Count)）"
Check '政治线 18' ($maPol.Count -eq 18) "（实测 $($maPol.Count)）"
Check '军事线 17' ($maMil.Count -eq 17) "（实测 $($maMil.Count)）"
Check 'offset 涉及的树 22 棵（仅存档，不再发射）' ($maOffsets.Count -eq 22) "（实测 $($maOffsets.Count)）"
Check '机构 idea 14 个' ($maIdeas.Count -eq 14) "（实测 $($maIdeas.Count)）"
Check '动态民族精神 3 个' ($maDms.Count -eq 3) "（实测 $($maDms.Count)）"
# 🚩 布局自检（2026-09-20 起，改过三轮）：
#    v1「拉的鬼都不认识了」= 固定列值 + 锚上一节点 → 每级累加漂移
#    v3「天哪超级无敌重叠啊」= 小增量 + 锚头节点 → 根级 joint_focus 不解析相对关系 ⇒ 叠成一坨
#    ✅ v4 = 【绝对格位 + 每块自带 21 条 offset】，完全不依赖 relative_position_id。
# ① 保险基准包围盒（不套 offset 时）：x ∈ [-21, +21]、y ∈ [24, 30]
Check "保险基准包围盒 x ∈ [-$stripHalf, +$stripHalf]" (($stripMinX -ge (-1 * $stripHalf)) -and ($stripMaxX -le $stripHalf)) "（实测 x $stripMinX .. $stripMaxX）"
Check '保险基准高度：y 从 27 到 33（苏联终局节点最低 y=25）' ($baseY -eq 27) "（实测 y 从 $baseY 到 $($baseY + $stripMaxY)）"
Check '布局高度 y ≤ 6 行' ($stripMaxY -le 6) "（实测最高第 $stripMaxY 行）"
# ② 58 个子节点必须占【58 个互不相同的格位】（列, 行）
$cellSeen = @{}
foreach ($ln in $lineNodes) {
    $colsA = $lineCol[$ln.Key]
    for ($k = 0; $k -lt $lineClusters[$ln.Key].Count; $k++) {
        for ($j = 0; $j -lt $lineClusters[$ln.Key][$k].Count; $j++) {
            if ($k -eq 0) { $r = 1 + $j } else { $r = 2 + $j }
            $key = "$($colsA[$k]),$r"
            if (-not $cellSeen.ContainsKey($key)) { $cellSeen[$key] = 0 }
            $cellSeen[$key] = $cellSeen[$key] + 1
        }
    }
}
$dupCells = @($cellSeen.Keys | Where-Object { $cellSeen[$_] -gt 1 })
Check '58 个子节点占 58 个互不相同的格位（无叠格）' ($dupCells.Count -eq 0 -and $cellSeen.Count -eq 58) "（重复 $($dupCells.Count) 处 · 实占 $($cellSeen.Count) 格）"
# ③ v7：一条 offset 都不写；一处 relative_position_id 也不写
Check '59 个国策各有一条仅供图瓦使用的纵向 offset' ($maOffsetBlocks -eq 59) "（实测 $maOffsetBlocks）"
Check '全文件不出现 relative_position_id 指令（注释里提到不算）' (-not $maJointText.Contains('relative_position_id =')) ''
# ④ 苏联核心圈终局是当前最深节点；逐树链式实测另由 verify-s2 §13h 完成。
$realYMax = 25
Check "带子 y 起点 $baseY > 苏联终局 Y 最大 $realYMax" ($baseY -gt $realYMax) "（空出 $($baseY - $realYMax) 行）"
# 支线划分自检：每条线的支线必须恰好覆盖它自己的节点一次（漏一个 = 该节点不会出现在树里）
$badPart = @()
foreach ($ln in $lineNodes) {
    $seen = @{}; $dup = 0
    foreach ($cl in $lineClusters[$ln.Key]) { foreach ($ix in $cl) { if ($seen.ContainsKey($ix)) { $dup++ } else { $seen[$ix] = $true } } }
    $miss = 0
    for ($q = 0; $q -lt $ln.Nodes.Count; $q++) { if (-not $seen.ContainsKey($q)) { $miss++ } }
    if (($dup -gt 0) -or ($miss -gt 0) -or ($seen.Count -ne $ln.Nodes.Count)) { $badPart += "$($ln.Key)(dup=$dup miss=$miss)" }
}
Check '支线划分覆盖每条线的每个节点恰好一次' ($badPart.Count -eq 0) "（坏：$($badPart -join ', ')）"

# id 唯一 + 前缀
$allIds = @($maHead.Id)
foreach ($ln in $lineNodes) { foreach ($n in $ln.Nodes) { $allIds += $n.Id } }
$dup = @($allIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
Check '国策 id 无重复' ($dup.Count -eq 0) "（重复：$($dup -join ', ')）"
$badPfx = @($allIds | Where-Object { $_ -notlike 'hof_ma_*' })
Check '国策 id 全部 hof_ma_ 前缀' ($badPfx.Count -eq 0) "（越界：$($badPfx -join ', ')）"

# 每个节点必须有 Desc
$noDesc = @()
foreach ($ln in $lineNodes) { foreach ($n in $ln.Nodes) { if (-not $n.Desc) { $noDesc += $n.Id } } }
Check '每个节点都有描述' ($noDesc.Count -eq 0) "（缺：$($noDesc -join ', ')）"

# idea 只能被真的用到（防止写了没人用的死 idea）
$usedIdeas = @()
foreach ($ln in $lineNodes) {
    foreach ($n in $ln.Nodes) {
        if ($n.ContainsKey('Raw')) {
            foreach ($r in $n.Raw) {
                if ($r -match '^add_ideas\s*=\s*(\S+)') { $usedIdeas += $Matches[1] }
            }
        }
    }
}
$declared = @($maIdeas | ForEach-Object { $_.Id })
$unused = @($declared | Where-Object { $usedIdeas -notcontains $_ })
$undeclared = @($usedIdeas | Where-Object { $declared -notcontains $_ })
Check '宣告的 idea 全部被国策用到' ($unused.Count -eq 0) "（没人用：$($unused -join ', ')）"
Check '国策用到的 idea 全部已宣告' ($undeclared.Count -eq 0) "（未宣告：$($undeclared -join ', ')）"

# 变量必须落在正确的容器里（eco 线不能写 pol 变量之外的容器名）
$badDm = @()
foreach ($ln in $lineNodes) {
    foreach ($n in $ln.Nodes) {
        foreach ($v in $n.V) {
            $d, $mod, $suf, $num = $v -split '\|'
            if ('eco', 'pol', 'mil' -notcontains $d) { $badDm += "$($n.Id):$v" }
            if ($num -notmatch '^-?[0-9.]+$') { $badDm += "$($n.Id):坏数值:$v" }
        }
    }
}
Check 'V 的三段/四段格式与数值格式正确' ($badDm.Count -eq 0) "（坏：$($badDm -join ' / ')）"

Write-Output ''
if ($fail -eq 0) { Write-Output '==================== 失败项: 0 ====================' }
else { Write-Output "==================== 失败项: $fail ===================="; exit 1 }
