# =============================================================================
# 核心圈 S3 · 花名册驱动生成器（唯一数据源）  —— 德式机制版
# -----------------------------------------------------------------------------
# 机制蓝本：原版德国「核心集团」核心圈（实读逐条对齐过，见对话记录）
#
#   ① 容器   枢纽国策完成时 add_dynamic_modifier 挂上一格【动态民族精神】
#            HOF 这边挂 hof_ic_supreme_soviet_dm（也是 SOV_the_supreme_soviet）
#   ② 槽位   hof_ic_slot_1..7 = 人物序号，0/未赋值 = 空席
#   ③ 入席   入口国策完成 -> hof_ic_appoint_<key>
#              有空席 -> 坐进第一个空席 + add_ideas 给该人的 idea
#              已满席 -> 触发 hof_ic_replace 事件，让玩家挑一个人换掉
#   ④ 冷却   每次任命后设 hof_ic_appointment_cd（175 天，照德国）
#   ⑤ 渲染   脚本本地化 defined_text 读槽位变量 -> 名字；动态精神的 tooltip
#            直接列出当前在任者
#   ⑥ 子线   人物事件链 .01/.02 循环：点亮相邻未完成国策 -> 到点
#            complete_national_focus -> 再预约下一个（一次推进一个）
#
# 与德国的差异（有意为之）：
#   · 席位 7 个而不是 3 个（本 mod 的核心圈是 7 人）
#   · 子线驱动器的【分支表 $branches 目前为空】—— 个人线国策还没进树，
#     填了会 complete 不存在的国策而报错。等某人的个人线落地后，
#     把他的国策 id 按顺序填进 $branches，重跑本脚本即可生成驱动事件。
#
# ★ 换花名册只改 $roster；改数值改下面那组常量。
#
# 语法依据（均已核实）：
#   · 官方 documentation\effects_documentation.md：add_dynamic_modifier /
#     complete_national_focus / activate_shine_on_focus / clear_variable /
#     set_variable = { a = b }（变量间赋值）
#   · 原版 common/dynamic_modifiers/wuw_dynamic_modifiers.txt：GER_the_inner_circle_dm
#   · 原版 common/scripted_localisation/WUW_GER_scripted_loc.txt：GetAscendedAdvisor*
#   · 原版 common/scripted_effects/GER_scripted_effects.txt：冷却写法
#   · 原版 events/WUW_Germany.txt：GER_inner_circle*.01/.02 事件链
# =============================================================================

$ErrorActionPreference = 'Stop'

$modRoot  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$vanilla  = 'F:\Hearts.of.Iron.IV.v1.19.3.0'
$r56      = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-ModFile {
    param([string]$RelPath, [string]$Text)

    # ⚠️ 制表符还原（踩过）：PowerShell 单引号字符串不做转义，'`t' 是字面量。
    #    本生成器统一用双引号 + 反引号转义，这句是兜底。
    $Text = $Text.Replace('`t', "`t")

    $full = Join-Path $modRoot $RelPath
    $dir  = Split-Path -Parent $full
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Text, $utf8NoBom)
    $bom = (Get-Content -LiteralPath $full -Encoding Byte -TotalCount 3) -join ','
    $flag = if ($bom -eq '239,187,191') { '有BOM(错误)' } else { '无BOM(正确)' }
    Write-Output ("  写出 {0,-58} {1,8:N0} 字节  {2}" -f $RelPath, (Get-Item -LiteralPath $full).Length, $flag)
}

function Get-DdsSize([string]$path) {
    try {
        $fs = [System.IO.File]::OpenRead($path)
        try {
            $buf = New-Object byte[] 20
            $null = $fs.Read($buf, 0, 20)
            if ([System.Text.Encoding]::ASCII.GetString($buf, 0, 4) -ne 'DDS ') { return '非DDS' }
            $h = [BitConverter]::ToUInt32($buf, 12)
            $w = [BitConverter]::ToUInt32($buf, 16)
            return "${w}x${h}"
        }
        finally { $fs.Close() }
    }
    catch { return '读取失败' }
}

# 素材查找根：mod -> R56 -> 原版 -> 原版各 DLC（DLC 必须含，踩过盲区）
$assetRoots = @($modRoot, $r56, $vanilla)
$dlcDir = Join-Path $vanilla 'dlc'
if (Test-Path $dlcDir) {
    $assetRoots += @(Get-ChildItem $dlcDir -Directory -ErrorAction SilentlyContinue |
                     Select-Object -ExpandProperty FullName)
}
Write-Output ("素材查找根 {0} 个（含 {1} 个 DLC）" -f $assetRoots.Count, ($assetRoots.Count - 3))

# -----------------------------------------------------------------------------
# ★ 可调常量
# -----------------------------------------------------------------------------
$seatCount        = 7          # 席位数（= .gui 里的格数）
$entryCost        = -0.10      # 人物 idea 的"入圈代价"，照德国 -0.1
$cdDays           = 60         # 任命冷却天数（德国 175，我们人多、周期长，用户 2026-09-15 定为 60）
$branchStartDelay = 7          # 【首次】入席后多久开始推进个人线
$branchStartRand  = 7
$branchTierDays   = 35         # 单条个人线国策的推进耗时（德国 tier_1 = 20 周 = 140 天；用户 2026-09-15 定为 35）
$branchGapDays    = 3          # 【国策之间】的间隔：推完一条、隔多久开下一条
$branchGapRand    = 3          #   （原来和 $branchStartDelay 共用一个值，现在拆开了：
                               #     首条慢一点让玩家看到入席生效，后面快一点，整套 15 条不至于拖太久）

# 只有最高苏维埃容器显示为民族精神；个人线数值合并进当前静态职务 idea。
$dmIcon = 'GFX_idea_hof_ic_supreme_soviet'

# 事件命名空间与 id 分配（AGENTS 约定命名空间 heartofiron）
$evNamespace   = 'heartofiron'
$evReplace     = 1000          # 满席替换事件
$evBranchBase  = 1100          # 个人线驱动事件从此起，每人占 2 个（+10 留间隙）

# -----------------------------------------------------------------------------
# ★ 花名册：Idx = 存进 hof_ic_slot_N 的数值
#   Key / Zh / Dds / NewArt / Note  同上一版
#   Idea     该人的民族精神 id（= Tiers 的首级，没有 Tiers 时就是唯一的那个）
#   Mod      该精神的修正（占位值，待定 —— 见 docs/24 §5）
#   Tiers    职务分级（可选）。有则生成多级 idea，每级 = 下级全部照抄 + 追加
#             字段：Id(idea id) / Zh(史实职务名) / Pp(入圈代价) / Add(本级新增的 modifier 行)
#             🚩 Add 要含下级的全部追加项 —— 那就是“照抄 + 追加”
#   Line     个人线国策表（为空 = 不生成）
#   Branch   个人线国策 id 顺序表（**空数组 = 不生成自动驱动器**）
# -----------------------------------------------------------------------------
$roster = @(
    @{ Idx = 1; Key = 'lev_trotsky';        Zh = '列夫·托洛茨基';
       # SeatDesc = 入口国策的【描述】—— 文风照德国 GER_ascension_of_<人>_desc
       #   德国三段式：① 先立一句一般判断 ② 「作为一名…的…」交代本人资质
       #   ③ 给不给他「相对的行动自由」的收益/风险评估（德国固定话术）
       #   🚩 旧稿 7 条是一模一样的模板句（只换名字）+ 只讲席位机制 ——
       #      既没有人物色彩，又占了本该放叙事的位。现已逐人重写。
       SeatDesc = '一位能干的军事组织者在最高苏维埃中占有一席之地。列夫·托洛茨基不仅缔造了红军，还是革命的老近卫；邀请他加入最高苏维埃，风险不大而收益却很可观。';
       Dds    = 'gfx/leaders/SOV/r56_portrait_SOV_Leon_Trotsky.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_lev_trotsky.dds';
       Note   = 'R56 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_lev_trotsky';
       Mod    = @('army_org_factor = 0.05');
       # 职务分级：官衔跟着国策往上走（照德国 GER_todt_reich_engineer -> _minister_of_armaments）
       # Pp  = political_power_gain（入圈代价，德国 -0.1 -> -0.3）
       # Add = 本级新增；【必须是上一级的超集】—— 供工具提示显示「效果变化」，只允许出现 +
       #   🚩🚩 2026-09-20 订正（用户裁决「修法甲」）：Idx 17–22 六条线曾把每级写成「换一批新量纲」，
       #        升级时旧的两条被顶掉 → 游戏里显示 −5%（见 docs/99 §41）。
       #        规格与德国原版一致：GER_todt_reich_engineer → _minister_of_armaments 就是「低级的 3 条一条不动 + 新增 2 条」。
       #   ⚠️ 唯一的例外是【同级并列】的两条（托洛茨基 3a/3b）—— 它们在国策树里 Mut 互斥，
       #        玩家只能完成其中一条 → 永远不会横跳 → 不需要互相包含。
       #   📌 写新线时自检：`Lv(n).Add` 必须是 `Lv(n-1).Add` 的超集（同量纲取较大值）。
       # Lv  = 官衔等级号（2026-09-16 加）——供 $rankUpOf 反查【上一级】；3a/3b 是并列，同为 Lv 3
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_lev_trotsky';    Zh = '陆海军人民委员';           Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_lev_trotsky_2';  Zh = '革命军事委员会主席';       Pp = -0.30;
              Add = @('command_power_gain_mult = 0.10') },
           @{ Lv = 3; Id = 'hof_ic_idea_lev_trotsky_3a'; Zh = '共产国际执行委员会主席';   Pp = -0.30;
              Add = @('command_power_gain_mult = 0.10', 'justify_war_goal_time = -0.25') },
           @{ Lv = 3; Id = 'hof_ic_idea_lev_trotsky_3b'; Zh = '人民委员会副主席';         Pp = -0.30;
              Add = @('command_power_gain_mult = 0.10', 'improve_relations_maintain_cost_factor = -0.25') }
       );
       # 官衔反查表：【从高到低】排，从德国 GER_add_himmler_effects 学的手法 ——
       # 不存“他升到第几级”，每次用 has_completed_focus 重算一遍，永远不会残留
       RankGates = @(
           @{ Id = 'hof_ic_idea_lev_trotsky_3a'; Gate = 'has_completed_focus = hof_ic_trotsky_the_permanent_revolutionary' },
           @{ Id = 'hof_ic_idea_lev_trotsky_3b'; Gate = 'has_completed_focus = hof_ic_trotsky_the_builder_of_the_state' },
           @{ Id = 'hof_ic_idea_lev_trotsky_2';  Gate = 'has_completed_focus = hof_ic_trotsky_against_partisan_warfare' }
       );
       # 个人线驱动器的推进顺序（见 §6）——驱动器每次挑「列表里第一个未完成的」开。
       # ⚠️ 必须【按前置拓扑排序】，否则会先点一条前置没完成的。
       # ⚠️ 刻意【不放】两个汇合结局（永久的革命者 / 国家建设者）：
       #    它们是【玩家】在抉择事件里选的一个方向；放进来会自动推进乱点掉。
       #    ⚠️ 2026-09-16：IV1/IV2（有限市场化 / 劳动军）也移出了 ——
       #    详见 $pathChoiceOf 上面那段长注释（它们是【真 bug】，不只是表现问题）。
       Branch = @(
           'hof_ic_trotsky_build_the_red_army',               # I1
           'hof_ic_trotsky_military_specialists',             # I2
           'hof_ic_trotsky_against_partisan_warfare',         # I3  ← 完成时官衔升到第 2 级
           'hof_ic_trotsky_uneven_and_combined_development',  # II1
           'hof_ic_trotsky_permanent_revolution',             # II2
           'hof_ic_trotsky_socialism_in_one_country',         # II3
           'hof_ic_trotsky_the_new_course',                   # III1
           'hof_ic_trotsky_against_the_bureaucracy',          # III2
           # ← 这里插入岔路（$pathChoiceOf.At = IV3），由事件定方向
           'hof_ic_trotsky_state_planning',                   # IV3（前置 = IV1 或 IV2）
           'hof_ic_trotsky_accelerated_industrialization',    # IV4
           'hof_ic_trotsky_the_comintern_manifesto',          # V1
           'hof_ic_trotsky_the_chinese_question',             # V2
           'hof_ic_trotsky_united_front'                      # V3
       ) }

    @{ Idx = 2; Key = 'nikolay_bukharin';   Zh = '尼古拉·布哈林';
       SeatDesc = '作为一名党的理论家，尼古拉·布哈林拥有为政策提供依据所必需的才能。若是邀请他加入最高苏维埃，我们一方面将受益于他手中的那支笔，另一方面也能安抚那些对现行路线心存疑虑的党员。';
       Dds    = 'gfx/leaders/SOV/portrait_SOV_nikolay_bukharin.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_nikolay_bukharin.dds';
       Note   = 'DLC034 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_nikolay_bukharin';
       Mod    = @('communism_drift = 0.03');
       # 职务分级：照 docs/25 附录「职务链」/ docs/26 §7.4，全部史实
       #   T1 《真理报》主编（1917 十月革命后 ~ 1929-11）—— 入席即有
       #   T2 联共（布）中央政治局委员（1924-06-02 ~ 1929-11-17）
       #   T3 共产国际执行委员会主席（1926-11 ~ 1929-04）
       # ⚠️ docs/25 附录里的 T1b《消息报》主编【刻意不收】：那是 1934 年、他被
       #    打下之后的职务，当「升迁」用与史实相反。所以链条是 1→2→3 三级。
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_nikolay_bukharin';   Zh = '《真理报》主编';           Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_nikolay_bukharin_2'; Zh = '联共（布）中央政治局委员'; Pp = -0.30;
              Add = @('political_power_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_nikolay_bukharin_3'; Zh = '共产国际执行委员会主席';   Pp = -0.30;
              Add = @('political_power_factor = 0.05', 'opinion_gain_monthly_factor = 0.10') }
       );
       # 官衔反查表：【从高到低】排。改这条链 = 改 A3 / E1 两个升级点。
       RankGates = @(
           @{ Id = 'hof_ic_idea_nikolay_bukharin_3'; Gate = 'has_completed_focus = hof_ic_bukharin_socialism_in_one_country' },
           @{ Id = 'hof_ic_idea_nikolay_bukharin_2'; Gate = 'has_completed_focus = hof_ic_bukharin_abolish_the_tribute' }
       );
       # 个人线驱动器推进顺序（见 §6）——【按前置拓扑排序】，
       # ⚠️ 2026-09-16：A1（过渡时期的经济）与 X1（左翼共产主义）【两条都移出】——
       #    它们互为 mutually_exclusive，改由标记驱动（见 $pathChoiceOf）。
       #    E1 留在里面，但它额外卡一道 A1 的标记（见 $branchGate）。
       Branch = @(
           'hof_ic_bukharin_nep_is_not_a_retreat',             # A2
           'hof_ic_bukharin_abolish_the_tribute',              # A3
           'hof_ic_bukharin_alliance_is_the_axis',             # B1
           'hof_ic_bukharin_enrich_yourselves',                # B2
           'hof_ic_bukharin_proportional_development',         # B3
           'hof_ic_bukharin_cooperatives_into_the_system',     # B4
           'hof_ic_bukharin_socialism_in_one_country'          # E1（前置 = A3 且 B4）
       ) }

    @{ Idx = 3; Key = 'aleksey_rykov';      Zh = '阿列克谢·李可夫';
       SeatDesc = '作为一名经验丰富的行政官员，阿列克谢·李可夫已经证明自己能维持国家机器的运转。如果邀请他加入最高苏维埃，我们相信他能对[ROOT.GetNameDef]的经济恢复发挥很大作用。';
       Dds    = 'gfx/leaders/SOV/portrait_SOV_aleksey_rykov.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_aleksey_rykov.dds';
       Note   = 'DLC034 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_aleksey_rykov';
       Mod    = @('industrial_capacity_factory = 0.03');
       # 职务分级：照 docs/29 §2.3（全部史实）—— 四级【直线链】，不是星形
       #   Lv1 内务人民委员（1917-10-26 ~ 11-17，首任）  ← 入席即有
       #   Lv2 最高国民经济委员会主席（1918-04-03 ~ 1921-05-28；1923-07-06 ~ 1924-02）
       #   Lv3 人民委员会主席（1924-02-02 ~ 1930-12-19）
       #   Lv4 劳动与国防委员会主席（1926-01-19 ~ 1930-12-19，1921-05-26 起为副主席）
       # ⚠️ ⛔ 已剔：邮電人民委员（1931）—— 那是他被贬之后的职务，当「升迁」用与史实相反
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_aleksey_rykov';   Zh = '内务人民委员';           Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_aleksey_rykov_2'; Zh = '最高国民经济委员会主席'; Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_aleksey_rykov_3'; Zh = '人民委员会主席';         Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05', 'political_power_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_aleksey_rykov_4'; Zh = '劳动与国防委员会主席';   Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05', 'political_power_factor = 0.05',
                     'production_factory_efficiency_gain_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排。改这条链 = 改 N1 / N3 / E1 三个升级点。
       RankGates = @(
           @{ Id = 'hof_ic_idea_aleksey_rykov_4'; Gate = 'has_completed_focus = hof_ic_rykov_labour_defence_chair' },
           @{ Id = 'hof_ic_idea_aleksey_rykov_3'; Gate = 'has_completed_focus = hof_ic_rykov_labour_defence_council' },
           @{ Id = 'hof_ic_idea_aleksey_rykov_2'; Gate = 'has_completed_focus = hof_ic_rykov_supreme_economic_council' }
       );
       # 个人线驱动器推进顺序（见 §6）——【按前置拓扑排序】。
       # 🚩 本线是【单线 4 节点 + 1 单结局】（docs/29 §5.2 / §5.3）：
       #    没有岔路、没有 count_triggers、没有二选一事件 ——
       #    结局国策直接靠「四个节点全部完成」开门（P = 四个并列块 = AND）。
       Branch = @(
           'hof_ic_rykov_supreme_economic_council',   # N1 ← 完成时官衔升到 Lv2
           'hof_ic_rykov_food_supply_commissar',      # N2
           'hof_ic_rykov_labour_defence_council',     # N3 ← 完成时官衔升到 Lv3
           'hof_ic_rykov_sponsor_aviation',           # N4（扶植航空 —— 挂 MIO）
           'hof_ic_rykov_labour_defence_chair'        # E1 ← 完成时官衔升到 Lv4（前置 = N1..N4 全）
       ) }

    @{ Idx = 4; Key = 'grigory_zinovyev';   Zh = '格里戈里·季诺维也夫';
       SeatDesc = '最高苏维埃始终欢迎那些能够掌握党的机关的人。作为共产国际的第一位主席，邀请格里戈里·季诺维也夫加入最高苏维埃，对我们来说将是非常有利的。';
       Dds    = 'gfx/leaders/SOV/portrait_SOV_grigory_zinovyev.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_grigory_zinovyev.dds';
       Note   = '原版大幅立绘 156x210';
       Idea   = 'hof_ic_idea_grigory_zinovyev';
       Mod    = @('communism_drift = 0.02');
       # 职务分级：照 docs/32 §2.3（全部史实）—— 三级
       #   Lv1 彼得格勒（列宁格勒）苏维埃主席（1917-12-13 ~ 1926-03，1924 起改称列宁格勒）
       #   Lv2 共产国际执行委员会主席（1919-03 ~ 1926-07）
       #   Lv3 联共（布）中央政治局委员（1921 ~ 1926-07；此前 1919-1921 是【无表决权】委员）
       # ⚠️ ⛔ 已剔：两个领袖特质（born_agitator / communist_theorist）—— 那是国家领袖线，
       #    见 docs/23 §6「不要碰的现成内容」。
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_grigory_zinovyev';   Zh = '彼得格勒苏维埃主席';       Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_grigory_zinovyev_2'; Zh = '共产国际执行委员会主席';   Pp = -0.30;
              Add = @('opinion_gain_monthly_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_grigory_zinovyev_3'; Zh = '联共（布）中央政治局委员'; Pp = -0.30;
              Add = @('opinion_gain_monthly_factor = 0.05', 'political_power_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排。改这条链 = 改 A1 / D2 两个升级点。
       #    T2 ← A1 缔造第三国际：1919-03 缔造第三国际，【同一场会议】选他当执委会主席
       #    T3 ← D2 论工会的作用：《论工会在生产中的作用》提纲 1921-03 俄共十大通过，
       #           而【同一次大会】选他为政治局的【正式】委员（此前只是无表决权委员）
       # ⚠️ 两个结局【不挂官衔】—— T3（政治局委员）是【职务的顶点】，而两个结局是
       #    「同一个国际的两种形态」，不是两个职位。所以不做托洛茨基那样的 3a/3b。
       RankGates = @(
           @{ Id = 'hof_ic_idea_grigory_zinovyev_3'; Gate = 'has_completed_focus = hof_ic_zinovyev_trade_unions' },
           @{ Id = 'hof_ic_idea_grigory_zinovyev_2'; Gate = 'has_completed_focus = hof_ic_zinovyev_found_the_comintern' }
       );
       # 个人线驱动器的推进顺序（见 §6）——【按前置拓扑排序】。
       # 🚩 本线 = 3 条支线 / 9 节点 + 2 个互斥结局（docs/33 §1）。
       # ⚠️ 两个结局【不进 $Branch】（照托洛茨基）：它们是 $endingChoiceOf 管的，
       #    由二选一事件打的角色标记驱动；门控「三条支线走通两条」写在事件触发条件里。
       # ⚠️ C3 的前置是 C2 且 A4（跨簇钩子），所以 A4 必须排在 C3 之前。
       Branch = @(
           'hof_ic_zinovyev_found_the_comintern',     # A1 ← 完成时官衔升到 Lv2
           'hof_ic_zinovyev_twenty_one_conditions',   # A2
           'hof_ic_zinovyev_social_fascism',          # A3
           'hof_ic_zinovyev_bolshevization',          # A4 ← 跨簇钩子：C3 需要它
           'hof_ic_zinovyev_congress_of_the_east',    # C1
           'hof_ic_zinovyev_workers_united_front',    # C2
           'hof_ic_zinovyev_speed_and_route',         # C3（前置 = C2 且 A4）
           'hof_ic_zinovyev_party_in_revolution',     # D1
           'hof_ic_zinovyev_trade_unions'             # D2 ← 完成时官衔升到 Lv3
       ) }

    @{ Idx = 5; Key = 'lev_kamenev';        Zh = '列夫·加米涅夫';
       SeatDesc = '作为一名善于调停的人，列夫·加米涅夫在党的各派之间都说得上话。若是邀请他加入最高苏维埃，我们一方面将受益于他的斡旋，另一方面也能借此平息党内的争执。';
       Dds    = 'gfx/leaders/SOV/portrait_SOV_lev_kamenev.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_lev_kamenev.dds';
       Note   = '原版大幅立绘 156x210';
       Idea   = 'hof_ic_idea_lev_kamenev';
       Mod    = @('stability_factor = 0.03');
       # 职务分级：三级，【全部围绕列宁的文本】
       #   Lv1 《列宁全集》编辑（列宁生前起，1917 ~ 1923）  ← 入席即有
       #   Lv2 《列宁文集》主编（1924，《列宁文集》第 1 卷）
       #   Lv3 列宁研究院院长（1923 ~ 1926）
       # 🚩 用户 2026-09-17 口径：「全篇就一个大主题列宁」→ 官衔链也跟着只用列宁文献类职务，
       #    不再挂 全俄中央执行委员会主席 / 莫斯科苏维埃主席（那是被砍掉的 B 支线的世界）。
       # ⚠️ 与已完成四条线的职务【依旧全部错开】：
       #    ⛔ 《真理报》主编 = 布哈林 T1；⛔ 人民委员会主席/劳动国防委员会主席 = 李可夫 T3/T4；
       #    ⛔ 共产国际执委会主席/政治局委员 = 季诺维也夫 T2/T3
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_lev_kamenev';   Zh = '《列宁全集》编辑'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_lev_kamenev_2'; Zh = '《列宁文集》主编'; Pp = -0.30;
              Add = @('communism_drift = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_lev_kamenev_3'; Zh = '列宁研究院院长';   Pp = -0.30;
              Add = @('communism_drift = 0.05', 'political_power_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排。改这条链 = 改 A2 / A4 两个升级点。
       #    Lv2 ← A2 列宁主义（他写完那个词条，就当了《列宁文集》主编）
       #    Lv3 ← A4 列宁研究院与全集（国策名与官衔 1:1 对应）
       RankGates = @(
           @{ Id = 'hof_ic_idea_lev_kamenev_3'; Gate = 'has_completed_focus = hof_ic_kamenev_lenin_institute' },
           @{ Id = 'hof_ic_idea_lev_kamenev_2'; Gate = 'has_completed_focus = hof_ic_kamenev_leninism' }
       );
       # 单线驱动器推进顺序（见 §6）——【按前置拓扑排序】。
       # 🚩 本线 = 单线 4 节点 + 1 单结局（用户 2026-09-17 口径：
       #    砍掉互斥项，砍掉 B（苏维埃治理）与 C（商业与对外）两条支线，结局只留一个）。
       # 🚩 结局国策【留】在 $Branch 里 —— 单结局靠「四个节点全完成」开门，
       #    不用标记驱动（$endingChoiceOf 里没他）。
       Branch = @(
           'hof_ic_kamenev_lenins_charge',        # A1
           'hof_ic_kamenev_leninism',             # A2 ← 完成时官衔升到 Lv2
           'hof_ic_kamenev_against_the_lessons',  # A3
           'hof_ic_kamenev_lenin_institute',      # A4 ← 完成时官衔升到 Lv3
           'hof_ic_kamenev_executor_of_the_will'  # E1（前置 = A1..A4 全）
       ) }

    @{ Idx = 6; Key = 'ivan_smirnov';       Zh = '伊万·斯米尔诺夫';
       SeatDesc = '作为一名在内战中成长起来的老布尔什维克，伊万·斯米尔诺夫既能带兵，也能办党务。如果邀请他加入最高苏维埃，我们相信他能在军中发挥很大作用。';
       Dds    = 'gfx/leaders/SOV/portrait_SOV_ivan_smirnov.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_ivan_smirnov.dds';
       Note   = '原版大幅立绘 156x210';
       Idea   = 'hof_ic_idea_ivan_smirnov';
       Mod    = @('production_speed_buildings_factor = 0.03');
       # 职务分级：照 docs/38 §4（全部史实，升序：军事 → 边疆政权 → 全联盟）—— 三级
       #   Lv1 第五集团军革命军事委员会委员（1919-04-01 ~ 1920-05-10）  ← 入席即有
       #   Lv2 西伯利亚革命委员会主席（1919-08 ~ 1921-09，人称「西伯利亚的列宁」）
       #   Lv3 苏联邮电人民委员（1923-07-06 ~ 1927-11-12，【首任】）
       # ⚠️ 托洛茨基《我的生平》中译把 Lv1 写作「第五军军长」——与俄文/英文维基的
       #    「革命军事委员会委员」有出入（同章里另有「任命斯拉文为第五军军长」），取精确写法。
       # ⛔ 已剔：最高国民经济委员会副主席（1922–1923）—— 李可夫已有 ВСНХ 节点，避重。
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_ivan_smirnov';   Zh = '第五集团军革命军事委员会委员'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_ivan_smirnov_2'; Zh = '西伯利亚革命委员会主席';      Pp = -0.30;
              Add = @('stability_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_ivan_smirnov_3'; Zh = '苏联邮电人民委员';           Pp = -0.30;
              Add = @('stability_factor = 0.05', 'production_speed_infrastructure_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_ivan_smirnov_3'; Gate = 'has_completed_focus = hof_ic_smirnov_posts_and_telegraphs' },
           @{ Id = 'hof_ic_idea_ivan_smirnov_2'; Gate = 'has_completed_focus = hof_ic_smirnov_sibrevkom' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 5 节点 + 1 单结局】（docs/39 §2）：
       #    没有岔路、没有 count_triggers、没有二选一事件 ——
       #    结局国策直接靠「五个节点全部完成」开门（P = 五个并列块 = AND）。
       Branch = @(
           'hof_ic_smirnov_the_volga_bridgehead',     # A1
           'hof_ic_smirnov_the_fifth_army',           # A2
           'hof_ic_smirnov_sibrevkom',                # A3 ← 完成时官衔升到 Lv2
           'hof_ic_smirnov_far_eastern_republic',     # A4
           'hof_ic_smirnov_posts_and_telegraphs',     # A5 ← 完成时官衔升到 Lv3
           'hof_ic_smirnov_siberian_lenin'            # E1（前置 = A1..A5 全）
       ) }

    @{ Idx = 7; Key = 'leonid_serebryakov'; Zh = '列昂尼德·谢列布里亚科夫';
       SeatDesc = '作为一名党务工作者，列昂尼德·谢列布里亚科夫熟悉党的组织机器。若是邀请他加入最高苏维埃，我们一方面将受益于他对基层的掌握，另一方面也能借此稳住地方组织。';
       Dds    = 'gfx/leaders/SOV/r56_portrait_SOV_Leonid_Serebryakov.dds';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_leonid_serebryakov.dds';
       Note   = 'R56 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_leonid_serebryakov';
       Mod    = @('industrial_capacity_factory = 0.03');
       # ★ OwnChar = 这个人原版/R56 【没有】角色对象，要我们自建一个（见 §7b）。
       #   其他人都有（common/characters/SOV.txt），所以不用标。
       #   为什么需要：国策 tooltip 用 CHARACTER = <角色 id> 时必须指向真实角色。
       OwnChar = $true;
       # 职务分级：照 docs/41 §4（全部史实，带起止日期）—— 三级
       #   Lv1 全俄中央执行委员会主席团秘书（1919–1920）               ← 入席即有
       #   Lv2 俄共（布）中央书记（1920-04-05 ~ 1921-03-08，「三书记」之一）
       #   Lv3 苏联人民委员会公路与汽车运输总局局长（1931 ~ 1935-08-03）
       # ⛔ 已剔：共和国革命军事委员会政治部主任（ПУР РВСР）—— 用户 2026-09-17
       #    砍掉「红军的政治机关」那个节点后，官衔链也一并移出军事领域，避开与托洛茨基挤。
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_leonid_serebryakov';   Zh = '全俄中央执行委员会主席团秘书'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_leonid_serebryakov_2'; Zh = '俄共（布）中央书记';           Pp = -0.30;
              Add = @('political_power_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_leonid_serebryakov_3'; Zh = '公路与汽车运输总局局长';       Pp = -0.30;
              Add = @('political_power_factor = 0.05', 'production_speed_rail_way_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_leonid_serebryakov_3'; Gate = 'has_completed_focus = hof_ic_serebryakov_highways_and_motor_transport' },
           @{ Id = 'hof_ic_idea_leonid_serebryakov_2'; Gate = 'has_completed_focus = hof_ic_serebryakov_central_committee' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 4 节点 + 1 单结局】（docs/42 §2）：
       #    无岔路、无 count_triggers、无二选一事件 —— 结局靠「四个节点全部完成」开门。
       #    ⚠️ 用户 2026-09-17 砍掉了原案里的「红军的政治机关」→ 5 块。
       Branch = @(
           'hof_ic_serebryakov_kostroma',                     # A1
           'hof_ic_serebryakov_central_committee',            # A2 ← 完成时官衔升到 Lv2
           'hof_ic_serebryakov_commissariat_of_transport',    # A3
           'hof_ic_serebryakov_highways_and_motor_transport', # A4 ← 完成时官衔升到 Lv3
           'hof_ic_serebryakov_brilliant_worker'              # E1（前置 = A1..A4 全）
       ) }

    # =========================================================================
    # 以下是【候选池的其余 15 人】（Idx 8..22）—— 2026-09-16 加入。
    # 席位仍然只有 7 个：玩家从 22 个入口国策里挑 7 个坐进去。
    # 史实身份全部来自实抓的维基条目（tmp/figures/，见 docs/28 §3）。
    # 个人线（Branch）全为空 —— 那群还没做，按 docs/23 SOP 一人一人来。
    # =========================================================================

    # ---- 批 2 · 左营补全 ----
    @{ Idx = 8; Key = 'yevgeny_preobrazhensky'; Zh = '叶夫根尼·普列奥布拉任斯基';
       SeatDesc = '作为一名经济学家，叶夫根尼·普列奥布拉任斯基为加速工业化提供了理论依据。若是邀请他加入最高苏维埃，我们一方面将受益于他关于积累的论证，另一方面也能让那些要求加快工业化的党员看到方向。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_yevgeny_preobrazhensky.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_yevgeny_preobrazhensky';
       Mod    = @('communism_drift = 0.03');
       # 职务分级：照 docs/44 §5 / docs/45 §4（全部史实，带起止日期）—— 三级
       #   Lv1 党中央宣传鼓动部部长（1920-04 ~ 1920-06，首任）              ← 入席即有
       #   Lv2 党中央与人民委员会财政委员会主席（1921–1924）  ← 门槛 = A2（1924-01-12，正落在任内）
       #   Lv3 苏联人民委员会租让事务总委员会副主席（1924–1927）← 门槛 = A4（1926，正落在任内）
       # ⛔ 刻意避开：「俄共（布）中央书记」—— 谢列布里亚科夫（Idx 7）的 Lv2 已用，
       #    而两人同营可同席，「三书记」不能两处都写（docs/41 §10 的原始警告）。
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_yevgeny_preobrazhensky';   Zh = '党中央宣传鼓动部部长';           Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_yevgeny_preobrazhensky_2'; Zh = '党中央与人民委员会财政委员会主席'; Pp = -0.30;
              Add = @('production_factory_max_efficiency_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_yevgeny_preobrazhensky_3'; Zh = '苏联人民委员会租让事务总委员会副主席'; Pp = -0.30;
              Add = @('production_factory_max_efficiency_factor = 0.05', 'production_factory_efficiency_gain_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_yevgeny_preobrazhensky_3'; Gate = 'has_completed_focus = hof_ic_preobrazhensky_two_regulators' },
           @{ Id = 'hof_ic_idea_yevgeny_preobrazhensky_2'; Gate = 'has_completed_focus = hof_ic_preobrazhensky_scissors' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 4 节点 + 1 单结局】（docs/45 §2；用户 2026-09-17 口径「B 合并到 A」）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（钩子已随合并消失）。
       Branch = @(
           'hof_ic_preobrazhensky_agrarian_theses',    # A1 1922-03
           'hof_ic_preobrazhensky_scissors',           # A2 1924-01 ← 完成时官衔升到 Lv2
           'hof_ic_preobrazhensky_against_nepmen',     # A3 1924-05
           'hof_ic_preobrazhensky_two_regulators',     # A4 1926    ← 完成时官衔升到 Lv3
           'hof_ic_preobrazhensky_primitive_accumulation'  # E1（前置 = A1..A4 全）
       ) }

    @{ Idx = 9; Key = 'karl_radek';              Zh = '卡尔·拉狄克';
       SeatDesc = '最高苏维埃始终欢迎那些在外交场合说得上话的人。作为共产国际的早期领导人和布列斯特谈判的代表，邀请卡尔·拉狄克加入最高苏维埃，对我们来说将是非常有利的。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_karl_radek.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_karl_radek';
       Mod    = @('opinion_gain_monthly_factor = 0.03');
       # 职务分级：照 docs/47 §5 / docs/48 §4（全部史实，带起止日期）—— 三级
       #   Lv1 外交人民委员部中欧司司长（1918-03 起）        ← 入席即有
       #   Lv2 共产国际执行委员会书记（1920-03 – 1924）      ← 门槛 = A4（1923-10，正落在任内）
       #   Lv3 中山大学校长（1925 – 1927）                  ← 门槛 = A5（该级的职务就是那个节点）
       # 🚩 刻意避开的官衔（docs/48 §4）：
       #   ⛔「共产国际执委会主席」= 季诺维也夫（Idx 4）的，他的是【执委会书记】（主席 vs 书记之一）
       #   ⛔「党中央宣传鼓动部部长 / 财政委员会主席 / 租让事务总委员会副主席」= 普列奥布拉任斯基（Idx 8）的
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_karl_radek';   Zh = '外交人民委员部中欧司司长'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_karl_radek_2'; Zh = '共产国际执行委员会书记';   Pp = -0.30;
              Add = @('boost_ideology_mission_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_karl_radek_3'; Zh = '中山大学校长';             Pp = -0.30;
              Add = @('boost_ideology_mission_factor = 0.05', 'communism_drift = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_karl_radek_3'; Gate = 'has_completed_focus = hof_ic_radek_sunyatsen_university' },
           @{ Id = 'hof_ic_idea_karl_radek_2'; Gate = 'has_completed_focus = hof_ic_radek_german_october' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【两条支线 + 1 单结局】（docs/48 §2；用户 2026-09-17 口径「不砍，结局 ok」；
       #    ⭐ 2026-09-20 用户裁决：先加【丙】中国的夺权斗争；同日重审（docs/92 §5）确认
       #    【乙】与【甲】同轴 → **中国题三件合并成一条 3 节点支线**）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子。
       #    ⭐ 支线 A（x = 0）向西（德国，4 节点 + 中山大学）；支线 B（x = +2）向东（中国，3 节点）
       #       —— 同一条主干「把革命办到俄国以外」，
       #       汇合层 E1 的 P 是【平铺 OR】：两条支线任一到头即开门。
       Branch = @(
           'hof_ic_radek_central_europe_department',   # A1 1918-03 外交人民委员部中欧司
           'hof_ic_radek_founding_of_the_kpd',         # A2 1918-12 德共一大的组织工作
           'hof_ic_radek_seven_pamphlets',             # A3 1919-02~12 狱中的七本小册子
           'hof_ic_radek_german_october',              # A4 1923-10 ← 完成时官衔升到 Lv2
           'hof_ic_radek_sunyatsen_university',        # A5 1925–27 ← 完成时官衔升到 Lv3（支线 A 走到头）
           'hof_ic_radek_the_struggle_for_power_in_china',              # B1 1924-10-26 中国的夺权斗争
           'hof_ic_radek_the_condition_of_the_chinese_working_class',   # B2 1925-08-13 中国工人阶级的状况
           'hof_ic_radek_social_and_political_thought',                 # B3 1926-03-12 社会政治思想（支线 B 走到头）
           'hof_ic_radek_red_publicist'                # E1（前置 = 两条支线【任一到头】，OR）
       ) }

    @{ Idx = 10; Key = 'ivar_smilga';            Zh = '伊瓦尔·斯米尔加';
       SeatDesc = '作为一名拉脱维亚裔的经济学家，伊瓦尔·斯米尔加熟悉国民经济的管理与核算。如果邀请他加入最高苏维埃，我们相信他能在经济事务上发挥很大作用。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_ivar_smilga.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_ivar_smilga';
       Mod    = @('industrial_capacity_factory = 0.03');
       # 职务分级：照 docs/50 §5 / docs/51 §4（全部史实，带起止日期）—— 三级
       #   Lv1 芬兰陆军、海军与工人区域执行委员会主席（1917）          ← 入席即有
       #   Lv2 最高国民经济委员会燃料总局局长（1921–1923）    ← 门槛 = A2（该级的职务就是那个节点）
       #   Lv3 苏联国家计划委员会副主席（1923–1926、1931–1933 两任）← 门槛 = A5（1931-11 他再任此职）
       # 🚩 刻意避开的官衔（docs/51 §4）：
       #   ⛔「最高国民经济委员会主席」/「劳动国防委员会主席」= 李可夫（Idx 3）的
       #   ⛔「财政委员会主席 / 租让事务总委员会副主席」= 普列奥布拉任斯基（Idx 8）的
       #   ⛔「党中央书记」= 谢列布里亚科夫（Idx 7）的； 「中山大学校长」= 拉狄克（Idx 9）的
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_ivar_smilga';   Zh = '芬兰陆军、海军与工人区域执行委员会主席'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_ivar_smilga_2'; Zh = '最高国民经济委员会燃料总局局长';         Pp = -0.30;
              Add = @('fuel_gain_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_ivar_smilga_3'; Zh = '苏联国家计划委员会副主席';               Pp = -0.30;
              Add = @('fuel_gain_factor = 0.05', 'industrial_capacity_factory = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_ivar_smilga_3'; Gate = 'has_completed_focus = hof_ic_smilga_productive_forces' },
           @{ Id = 'hof_ic_idea_ivar_smilga_2'; Gate = 'has_completed_focus = hof_ic_smilga_fuel_main_directorate' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 5 节点 + 1 单结局】（docs/51 §2；用户 2026-09-17 口径「就这样处理吧，第三条保留」）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（单线只剩一个簇）。
       #    ⭐ 首尾同轴：A1 是「把边境的力量送进首都」，A5 是「把首都的工厂送到边境」。
       #    🚩 军事那一半【全部刻意剔除】（docs/50 §2.1）：缔造红军 / 军事专家 / 政委制度 /
       #       反游击 / 劳动军 = 托洛茨基（Idx 1）；一个战区 = 斯米尔诺夫（Idx 6）。
       Branch = @(
           'hof_ic_smilga_finland',                    # A1 1917       芬兰的军队与舰队
           'hof_ic_smilga_fuel_main_directorate',      # A2 1921–1923 燃料总局 ← 完成时官衔升到 Lv2
           'hof_ic_smilga_gosplan',                    # A3 1923–1926 国家计划委员会
           'hof_ic_smilga_economics_institute',        # A4 1924–1927 莫斯科国民经济学院
           'hof_ic_smilga_productive_forces',          # A5 1931–1933 生产力布局 ← 完成时官衔升到 Lv3
           'hof_ic_smilga_the_healer_of_the_gaps'      # E1（前置 = A1..A5 全）
       ) }

    # ---- 批 3 · 右营补全 + 工反营 ----
    @{ Idx = 11; Key = 'mikhail_tomsky';         Zh = '米哈伊尔·托姆斯基';
       SeatDesc = '一位从车床旁走出来的人，在最高苏维埃中自有他的位置。米哈伊尔·托姆斯基不仅领导着全苏工会，还是政治局的老成员；邀请他加入最高苏维埃，风险不大而收益却很可观。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_mikhail_tomsky.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_mikhail_tomsky';
       Mod    = @('industrial_capacity_factory = 0.03');
       # 职务分级：照 docs/53 §5 / docs/54 §4（全部史实，带起止日期）—— 三级
       #   Lv1 莫斯科工会理事会主席（1917-12 起）                ← 入席即有
       #   Lv2 全苏工会中央理事会主席（1918-10-09 – 1921）        ← 门槛 = A3（该级的职务就是那个节点）
       #   Lv3 再任全苏工会中央理事会主席（1922 – 1929）          ← 门槛 = A5（1921-05 他失去它，1922 年拿回来）
       # ⭐ Lv3 用「再任」承担叙事：玩家会发现它的门槛正是【他丢官的那件事】（docs/54 §4）。
       # 🚩 刻意避开的官衔（docs/53 §10.1 / docs/54 §4 已逐条核）：
       #   ⛔「最高国民经济委员会主席 / 副主席」= 李可夫（Idx 3）的；「人民委员会主席」也是他的
       #   ⛔「联共（布）中央政治局委员」= 季诺维也夫（Idx 4）的 Lv3（docs/33 §99）
       #   ⛔「党中央书记」= 谢列布里亚科夫（Idx 7）；「财政委员会主席」= 普列奥布拉任斯基（Idx 8）
       #   ⛔ 出版与办学全部被占：列宁研究院 / 全集（加米涅夫 Idx 5）、中山大学（拉狄克 Idx 9）、
       #      国民经济学院（斯米尔加 Idx 10）
       #   ⛔「全俄中央执行委员会土耳其斯坦事务委员会主席」（1921-05 – 1922-01）—— ⚠️ 曾是候选 Lv3，
       #      但「再任 ВЦСПС 主席」能把叙事说圆，本轮不用（备选留档 docs/54 §8）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_mikhail_tomsky';   Zh = '莫斯科工会理事会主席';       Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_mikhail_tomsky_2'; Zh = '全苏工会中央理事会主席';     Pp = -0.30;
              Add = @('production_factory_efficiency_gain_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_mikhail_tomsky_3'; Zh = '再任全苏工会中央理事会主席'; Pp = -0.30;
              Add = @('production_factory_efficiency_gain_factor = 0.05', 'political_power_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_mikhail_tomsky_3'; Gate = 'has_completed_focus = hof_ic_tomsky_the_silence_of_1921' },
           @{ Id = 'hof_ic_idea_mikhail_tomsky_2'; Gate = 'has_completed_focus = hof_ic_tomsky_central_council_of_trade_unions' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 5 节点 + 1 单结局】（docs/54 §2；用户 2026-09-17 口径「都按 A 选项，继续吧」）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（单线只剩一个簇）。
       # ⭐ 根 =「来自托木斯克的人」（本姓叶夫列莫夫，`托姆斯基` 是 1906 年逃亡路上给自己起的化名）；
       #    主干 = 给工会争一个自己的声音 —— 顺序即推导：一行 → 一城 → 全国 → 顶住 → 代价。
       # ⭐⭐ 与三处「工会邻接」的界线（docs/53 §2.1，用户裁决④ = 现在就写死）：
       #   ⛔ 原版 SOV_the_trade_union_as_labor_organizer「工会作为劳动组织者」
       #      → 原版是工会【干活】（去组织生产）；本线是工会【说话】
       #   ⚠️ 季诺维也夫线 hof_ic_zinovyev_trade_unions（docs/33 §70/§130）—— 共产国际视角
       #      → 季是【向外】（把西方工会争取到共产国际）；他是【向内】（国内工会该不该听党）
       #      ⭐ 而且两者【互斥】（左营 × 右营，docs/10 §591），游戏里碰不上面
       #   ⚠️ 施利亚普尼科夫（Idx 13）工人反对派「把国民经济交给工会」
       #      → 施要【工会管生产】；他要【工会自己说了算】
       #      🚩 R1 互斥是 workers × left，【不涉及 right】（docs/10 §560）→ 两人理论上可同席
       #      → 做 Idx 13 那一轮要回来核对本段的界线（docs/54 §8 问题④）
       # 🚩 其余刻意剔除（docs/53 §7）：⛔ 1929-04-18 交锋 = 布哈林线 A3（docs/26 §65）；
       #   ⛔ 1932 起 ОГИЗ 社长（出版题，加米涅夫 + 斯米尔加 A4）；⛔ 1929 全苏化工联合体主席（李可夫线的 ВСНХ）
       Branch = @(
           'hof_ic_tomsky_printers_union',                  # A1 1906–1907 印刷工人工会（集体合同 + 石印工人工会）
           'hof_ic_tomsky_moscow_trade_union_council',      # A2 1917-10/12 莫斯科工会理事会（10-29 列宁听取他的报告）
           'hof_ic_tomsky_central_council_of_trade_unions', # A3 1918-10-09 ВЦСПС 执行局主席 ← 完成时官衔升到 Lv2
           'hof_ic_tomsky_platform_of_ten',                 # A4 1920-10–1921-03「十人纲领」（挡回托洛茨基的整肃）
           'hof_ic_tomsky_the_silence_of_1921',             # A5 1921-05 他没有念那份稿子 ← 完成时官衔升到 Lv3
           'hof_ic_tomsky_man_from_tomsk'                   # E1（前置 = A1..A5 全）
       ) }

    @{ Idx = 12; Key = 'martemyan_ryutin';       Zh = '马尔特米扬·里亚京';
       SeatDesc = '作为一名敢于把主张写成文件的人，马尔特米扬·里亚京在地方党组织中很有影响。若是邀请他加入最高苏维埃，我们一方面将受益于他与农村的联系，另一方面也要准备好听取他的批评。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_martemyan_ryutin.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_martemyan_ryutin';
       Mod    = @('war_support_factor = 0.03');
       # 职务分级：照 docs/56 §9.1 / docs/57 §4（全部史实，带起止日期）—— 三级
       #   Lv1 哈尔滨工人与士兵代表苏维埃主席（1917-09 – 12）        ← 入席即有
       #   Lv2 红军机关报《红星报》副编辑（1928 秋 – 1930-03）             ← 门槛 = A2（该级的职务就是那个节点）
       #   Lv3 苏联国家电影照相联合公司理事会主席（1930-02 – 10）       ← 门槛 = A3（同上）
       # ⭐ 三级【就是他一生那三个载体】：一个境外苏维埃 → 一张有印量的报纸 → 一间国家摄影棚。
       # ⭐ Lv1 是 22 人里【唯一的境外苏维埃】——这一点本身就是辨识度。
       # 🚩 用户 2026-09-17 口径「删掉 A2，结局取 B」：
       #    ⛔ 原 Lv2「伊尔库茨克省执行委员会主席」（1919）【随 A2 一并移出官衔链】——
       #       照 docs/43 的「砍枝时官衔链也要一并移出那个领域」的先例（第 3 次）。
       # 🚩 刻意避开的官衔（docs/56 §9.1 / docs/57 §4 已逐条核）：
       #   ⛔「最高国民经济委员会主席 / 副主席」= 李可夫（Idx 3）的
       #      （⚠️ 他 1930-03 是 ВСНХ 主席团成员 —— 与 Lv3 的 Союзкино 主席同期，本轮只取后者）
       #   ⛔「党中央宣传鼓动部部长」= 谢列布里亚科夫（Idx 7）的
       #      （⚠️ 他是**莫斯科市委**宣传鼓动部部长 —— 太近，不用）
       #   ⛔「西伯利亚革命委员会主席」= 斯米尔诺夫（Idx 6）的
       #   ⛔「联共（布）中央政治局委员」= 季诺维也夫（Idx 4）的 Lv3
       #   ⛔ 出版与办学全被占：列宁研究院（加米涅夫 Idx 5）、中山大学（拉狄克 Idx 9）、
       #      国民经济学院（斯米尔加 Idx 10）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_martemyan_ryutin';   Zh = '哈尔滨工人与士兵代表苏维埃主席'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_martemyan_ryutin_2'; Zh = '红军机关报《红星报》副编辑';         Pp = -0.30;
              Add = @('war_support_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_martemyan_ryutin_3'; Zh = '苏联国家电影照相联合公司理事会主席';   Pp = -0.30;
              Add = @('war_support_factor = 0.05', 'drift_defence_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_martemyan_ryutin_3'; Gate = 'has_completed_focus = hof_ic_ryutin_soyuzkino' },
           @{ Id = 'hof_ic_idea_martemyan_ryutin_2'; Gate = 'has_completed_focus = hof_ic_ryutin_red_star' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 4 节点 + 1 单结局】= 5 块（docs/57 §2；用户 2026-09-17 口径「删掉 A2，结局取 B」）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（单线只剩一个簇）。
       # ⭐ 根 =「上留京诺的留京」（他的姓就是他出生的那个村的名字）；
       #    主干 = 载体一级一级被拿走，他就换一个更小的地方接着说。
       #    ⭐⭐ 首尾呼应：A1 是哈尔滨的一叠纸（一份杂志），E1 是审讯笔录上的一叠纸。
       # ⛔ 用户删掉的 A2（伊尔库茨克省 1918–1921）——理由：A1 到它需靠「建政失败逃回来」连接，
       #    而它与斯米尔诺夫（Idx 6）的西伯利亚题重叠（docs/56 §2.3）。
       # ⛔ 其余刻意剔除（docs/56 §1.3）：
       #    ⛔ 1924–1927「乌格拉诺夫式的流氓 / 战斗队 / 压会场」（他 1927-11 殴打斯米尔加与普列奥布拉任斯基）
       #    ⛔ 1929 集体化视察（农业题 + 地理撞斯米尔诺夫）；⛔ 1930-01《消灭富农阶级》社论（农业题）
       #    ⛔ 狱中 / 流放（原版 SOV_liberate_ryutin 已占）；⛔ 「暗杀」题材；⛔「反斯大林」当主语
       Branch = @(
           'hof_ic_ryutin_struggle_magazine',              # A1 1917-09/12 哈尔滨《斗争》杂志 + 工人与士兵代表苏维埃
           'hof_ic_ryutin_red_star',                       # A2 1928–1930 《红星报》副编辑 ← 完成时官衔升到 Lv2
           'hof_ic_ryutin_soyuzkino',                      # A3 1930 苏联电影（Союзкино 首任主席 + 有声电影）← 升 Lv3
           'hof_ic_ryutin_union_of_marxist_leninists',     # A4 1932 马列主义者联盟（160+ 页手稿 + 呼吁书）
           'hof_ic_ryutin_verkhne_ryutino'                 # E1（前置 = A1..A4 全）
       ) }

    @{ Idx = 13; Key = 'aleksandr_shlyapnikov';  Zh = '亚历山大·施利亚普尼科夫';
       SeatDesc = '作为一名金属工人，亚历山大·施利亚普尼科夫在车间里说话有分量。如果邀请他加入最高苏维埃，我们相信他能把工人的声音带进来。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_aleksandr_shlyapnikov.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_aleksandr_shlyapnikov';
       Mod    = @('production_speed_buildings_factor = 0.03');
       # ⭐ Mod = 建造速度 —— 与主干「一道工序归一个工位」直接对上：把事情交给做这件事的人，事情就建得快。
       # 🚩🚩 第 0 步最大发现（docs/59 §1.3）：原版把「工会」这个题【一分为二】，各给一个专属特质 ——
       #    · 托姆斯基（Idx 11，right 营）right_trade_unionist「右翼工会主义者」→ 工厂效率（工会【去干生产】）
       #    · 他（Idx 13，workers 营）left_trade_unionist「左翼工会主义者」→ 政治点 −10%（工会【跟党争权】）
       #    ⛔ 所以主干【不能】定在「工会管生产 / 跟党争权」上 —— 那是把原版特质再做成一条线。
       #    ✅ 主干改走「一道工序归一个工位」（车工思维），工会管经济只做 A5 一个中间节点。
       # 职务分级：照 docs/59 §7.1 / docs/60 §4（全部史实，带起止日期）—— 三级
       #   Lv1 全俄金属工人工会中央委员会主席（1917-06-29 – 1921）  ← 入席即有（⭐ 他一生的【职级基石】）
       #   Lv2 劳动人民委员（第一任，1917-10-27 – 1918-10）        ← 门槛 = A4（该级的职务就是那个节点）
       #   Lv3 俄共（布）中央委员（1921 – 1922）                    ← 门槛 = A6（同上）
       # ⭐⭐ Lv3 有一条【反向】的历史：他被选进中央，两年后（1922 十二大）又被选掉了
       #    —— 与 A6（他在十一大提要求 → 十二大落选）是同一件事的两面。
       # 🚩 刻意移出官衔链的（docs/60 §4.3）：
       #   ⛔「贸易与工业人民委员」= 1917-11【兼任】、只到 1918 → 与 Lv2 同期，做成 Lv2.5 会让时间轴非单调
       #   ⛔「里海-高加索方面军 РВС 主席」（1918）= 军事题（docs/51 §1.2：军事那一半几乎全被占）
       #   ⛔「驻法国商务代表」（1923）= 外交题（李维诺夫 Idx 15 / 拉狄克 Idx 9）
       #   ⚠️「Металлоимпорт 董事会主席」（–1929）本轮备选未取
       # ✅ 已交叉核对（grep 生成器全部 Zh）：【没有被任何已实装线用过】
       #   —— 唯一近似的「普列奥布拉任斯基 Lv2 党中央与人民委员会财政委员会主席」是财政委员会，不是中央委员
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_aleksandr_shlyapnikov';   Zh = '全俄金属工人工会中央委员会主席'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_aleksandr_shlyapnikov_2'; Zh = '劳动人民委员';                     Pp = -0.30;
              Add = @('production_factory_efficiency_gain_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_aleksandr_shlyapnikov_3'; Zh = '俄共（布）中央委员';               Pp = -0.30;
              Add = @('production_factory_efficiency_gain_factor = 0.05', 'political_power_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       RankGates = @(
           @{ Id = 'hof_ic_idea_aleksandr_shlyapnikov_3'; Gate = 'has_completed_focus = hof_ic_shlyapnikov_qualification_from_the_shop' },
           # 2026-09-19 用户口径「A2 删去」→ Lv2 门槛改挂 A1（工人监督 = 他就任第一任劳动人民委员时做的第一件事）
           @{ Id = 'hof_ic_idea_aleksandr_shlyapnikov_2'; Gate = 'has_completed_focus = hof_ic_shlyapnikov_workers_control' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 5 节点 + 1 单结局】= 6 块（docs/60 §2）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（单线只剩一个簇）。
       # -----------------------------------------------------------------------------
       # 🚩🚩 **2026-09-17 第二版（第一版被用户否掉，整批重做）** —— 见 docs/60 §1.0
       #    第一版主干 =「一道工序归一个工位」（从「车工」这个身份反推的隐喻）
       #    ⛔ 被否的三条理由：① **与谢列布里亚科夫（Idx 7）的主干「把散落的部件接成一台机器」是同一个隐喻**
       #       ② 六个节点的「一条轴」是【我编的】（加米涅夫那轮犯过的错，这次更隐蔽）
       #       ③ **绕开了他唯一的招牌**（「工人反对派」）—— 过度校正
       # -----------------------------------------------------------------------------
       # ⭐ 根 =「被人托付的那捆文件」：
       #    1904 年在索尔莫沃，别人把一捆非法文献【交到他手上】带回穆罗姆散发 ——
       #    ⭐⭐ 他后来把这件事称作【自己加入党的入行时刻】（en 维基原话：
       #    "which he later designated as his initiation into the RSDLP"）。
       #    ⭐ 托付他的是【工人】，不是上面 —— 这一条同时解释了他一辈子替谁办事、以及他为什么不信上面。
       # ⭐⭐ 主干 =「**国家把经济交给谁、怎么交**」—— 一条【权力移交的制度路径】
       #    ⭐ 一句话记法：**别人做的是「在机关里往上爬」，他做的是「机关里的人从哪来」。**
       #    五个尺度：制度的起点 → 划线 → 机关的来源 → 路线 → 资格
       #    🚩 2026-09-19 用户口径「A2 删去」→ 原「人的来源」那一环（机关里坐着谁）已移出，
       #       剩下五个尺度；「机关的来源」这一区别改由 A3（生产者代表大会）单独承担。
       #    ⭐⭐ 首尾呼应：**根是「别人把东西【交到他手上】」，E1 是「由他们【推出来】的机关」** ——
       #        开头他手里那捆文件是别人给的，最后他要的那个机关是工人自己推的。
       # -----------------------------------------------------------------------------
       # 🚩🚩 **2026-09-17 第三版（第二版又被用户否掉）** —— 见 docs/60 §1.0
       #    第二版主干 =「管事的人，要由干活的人选出来」（方向对，但**节点产物不够大**）
       #    ⛔ 被否的理由：**「内容水平太细节了，其他人是战略上的，这个国策看上去是一线的」**
       #       📌 诊断：第二版的 A1「厂门口站住的一群人」/ A2「温布利的那张工会证」/ A3「一次工资谈判」
       #          —— **三个节点的产物都停在「一个县城 / 一个人的经验 / 一次谈判」，没有抬到国家制度那一层**。
       #          ⭐ 判据（第 4 条）：**不只问「根推不推得出来」，还要问「产物够不够大」。**
       #          ⚠️ 最该改的是 A2 —— 它的产物原文写成「**他亲眼见过**」，**那是个人收获，不是历史产物**。
       #    ✅ 第三版改法：**保留主轴（权力移交），把每个节点的产物抬到【国家制度】那一层**。
       # -----------------------------------------------------------------------------
       # ⭐ 根 =「被人托付的那捆文件」：
       #    1904 年在索尔莫沃，别人把一捆非法文献【交到他手上】带回穆罗姆散发 ——
       #    ⭐⭐ 他后来把这件事称作【自己加入党的入行时刻】（en 维基原话：
       #    "which he later designated as his initiation into the RSDLP"）。
       #    ⭐ 托付他的是【工人】，不是上面。
       # -----------------------------------------------------------------------------
       # 🚩 整场十大（1921-03）【让给托姆斯基】（他那条线的 A5 就在那儿）——
       #    所以本线【不碰】派别活动禁令，时间轴上直接跳到 1922-03 十一大。
       # 🚩 与三处「机关线」的界线（docs/60 §1.4）：
       #    · 李可夫（ВСНХ 主席）/ 斯米尔加（计委副主席）/ 沃兹涅先斯基（计委）—— **机关的业务**
       #    · 托姆斯基 —— **工会这个组织**与党的关系
       #    · ⭐ 本线 —— **机关的来源**（机关里的人从哪来、由谁选）
       # ⛔ 刻意剔除（docs/59 §2.5）：
       #    ⛔ 立宪会议（1918-01 驱散）—— 题材过敏感 + 撞 united 营
       #    ⛔ 劳动军事化 / 与托洛茨基的正面交锋 —— 托洛茨基的题，且与他互斥、游戏里没有对手戏
       #    ⛔ 「一长制 vs 集体管理」与「专家 vs 阶级」—— ⚠️ 柯伦泰书里有大段论述，**但不是他个人署名**
       #       （只见于工人反对派纲领；用户不在场时按「安全第一」不纳入，docs/60 §8.1）
       #    ⛔ 1922「二十二人的信」（共产国际）—— 「共产国际」是季诺维也夫（Idx 4）的招牌
       #    ⛔ 1923「四十六人声明」—— 撞普列奥布拉任斯基 / 拉狄克已做过的党内民主题
       #    ⛔ 狱中 / 流放 / 1936-09 被捕 / 1937-09-02 枪决 —— 原版两处集团释放已占「把他放出来」
       #    ⛔ 他自己的回忆录与 1932 年那份决议 —— 「出版」题被加米涅夫 / 斯米尔加 / 托姆斯基三处占
       #    ⛔ 四国车间的个人经历（穆罗姆街头 / 温布利的工会证）—— ⚠️ **留作背景，不占节点**
       #       （它们是【他的成长】，不是【他的历史产物】，docs/60 §1.1）
       Branch = @(
           'hof_ic_shlyapnikov_workers_control',                  # A1 1917-10 工人监督 ← 完成时官衔升到 Lv2
           'hof_ic_shlyapnikov_not_syndicalism',                  # A2 1920-03 划线：不是工团主义
           'hof_ic_shlyapnikov_producers_congress',               # A3 1920-03 生产者代表大会：机关的来源
           'hof_ic_shlyapnikov_through_the_workers',              # A4 1920-12 通过工人，还是瞒着工人
           'hof_ic_shlyapnikov_qualification_from_the_shop',      # A5 1922-03 生产的资格 ← 升 Lv3
           'hof_ic_shlyapnikov_the_body_they_elect'               # E1（前置 = A1..A5 全）
       ) }

    # ---- 批 4 · 中立营 ----
    @{ Idx = 14; Key = 'mikhail_kalinin';        Zh = '米哈伊尔·加里宁';
       SeatDesc = '作为从十月革命起就担任国家元首的人，米哈伊尔·加里宁在农民中享有声望。若是邀请他加入最高苏维埃，我们一方面将受益于他的资历，另一方面也能借此安抚农村。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_mikhail_kalinin.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_mikhail_kalinin';
       Mod    = @('political_power_factor = 0.03');
       # ---- 官衔链 · 四级（**城 → 俄国 → 联盟 → 最高苏维埃**）----
       # (docs/62 §7.1 / docs/63 §4.1 —— ⚠️ 与李可夫（Idx 3）同型：四级直线链)
       # ⭐ 四个职务【全部未被任何已实装线用过】：
       #   ⚠️ 季诺维也夫 Lv1 是「彼得格勒【苏维埃】主席」，与「市长（市杜马选出）」不是同一个机构
       #   ⚠️ 谢列布里亚科夫 Lv1 是「全俄中央执行委员会【主席团秘书】」，与「主席」不是同一个职务
       #   ⚠️ 1922-12-30 起他是苏联中央执委会【四人并列主席之一】
       #      （另三人：彼得罗夫斯基 / 切尔维亚科夫 / 纳里马诺夫，各代表一个加盟共和国）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_mikhail_kalinin';   Zh = '彼得格勒市长';             Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_mikhail_kalinin_2'; Zh = '全俄中央执行委员会主席';   Pp = -0.30;
              Add = @('stability_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_mikhail_kalinin_3'; Zh = '苏联中央执行委员会主席';   Pp = -0.30;
              Add = @('stability_factor = 0.05', 'drift_defence_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_mikhail_kalinin_4'; Zh = '苏联最高苏维埃主席团主席'; Pp = -0.30;
              Add = @('stability_factor = 0.05', 'drift_defence_factor = 0.05', 'political_power_factor = 0.05') }
       );
       # 官衔反查表：【从高到低】排
       # ⭐⭐ 门槛与那一级在讲什么咬合（docs/63 §4.2）：
       #   Lv2 ← A1「农民出身的元首」—— 门槛与职务【同一天】（1919-03-30）
       #   Lv3 ← A3「全民国家」—— 联盟 1922 年就成立了，他到 1926 年才第一次说出「这个国家是谁的」
       #   Lv4 ← A5「没有根据的行动」—— 最高苏维埃是 1936 年宪法设立的、由全民直接选举产生的机构
       RankGates = @(
           @{ Id = 'hof_ic_idea_mikhail_kalinin_4'; Gate = 'has_completed_focus = hof_ic_kalinin_an_unfounded_operation' },
           @{ Id = 'hof_ic_idea_mikhail_kalinin_3'; Gate = 'has_completed_focus = hof_ic_kalinin_the_state_of_the_whole_people' },
           @{ Id = 'hof_ic_idea_mikhail_kalinin_2'; Gate = 'has_completed_focus = hof_ic_kalinin_a_peasant_head_of_state' }
       );
       # 个人线驱动器推进顺序——【按前置拓扑排序】。
       # 🚩 本线是【单线 5 节点 + 1 单结局】= 6 块（docs/63 §2）：
       #    无岔路、无 count_triggers、无二选一事件；无跳簇钩子（单线只剩一个簇）。
       # -----------------------------------------------------------------------------
       # ⭐⭐⭐ 根 =「上特罗伊察的贫农头生子」—— 一个【由别人出钱、用工厂的车间送出来的农家孩子】：
       #    12 俄里外那所地方自治会小学是几个村子唯一能读书的地方（学费是当地地主家出的）；
       #    13 岁被带进彼得堡当仆役 → 18 岁进「老军械库」兵工厂当车工学徒 → 1896 进普梯洛夫。
       #    ⭐ 他 1933 年自己回忆：「在工厂里我第一次学会了阶级的革命斗争，第一次认识了马克思主义。」
       #    ⭐ 对上一辈子的称呼 «староста»（村社推出来替全村说话的【老家长】），字面上就是这个位置。
       # ⭐⭐ 主干 =「一个能被普通人找到的国家」——
       #    ⭐ 一句话记法：**别人都在做「国家做什么」，他做的是「国家找不找得到」。**
       #    五个尺度：谁配坐在上面 → 先让人会读 → 说清这是谁的 → 把门常设 → 真用一次
       #    ⭐⭐ 呼应：根是「别人出钱把他送上来的」，A5 是「他在纸上替别人挡了一次」；
       #       E1 用托洛茨基的话收尾 ——「苏维埃共和国未来的主席、锁匠加里宁」。
       # -----------------------------------------------------------------------------
       # 🚩 第 0 步：**原版【没有】为他专门做过国策**（「原版专做过国策」检查第 4 次执行，又是没有）
       #    他有的现成件：角色对象 ✅ / 政治顾问 idea ✅ / 小图 ✅ / 开局入册 ✅ / 专属领袖特质 ⛔ 没有
       # 🚩 要绕开的机制【十二套】（docs/62 §1.3）—— 比施利亚普尼科夫多三套：
       #    · NSB 的 `# Kalinin / Tver` 地名链
       #    · `SOV_gain_support_from_party_members_tt`（原版把他列进「潜在的反斯大林派」）
       #    · 地名 state 247 与 R56 的 `vp_rename_exceptions = 6245`
       # 🚩🚩 **原版为他【单独】做过一个 MTTH 事件**：`purged_kalinin` + `soviet.25`
       #    （「加里宁的妻子也有嫌疑，所以他也不可信」→ `retire_character`）——
       #    ⚠️ 原版整段注释掉、**R56 启用** → ⛔ **本线不做「妻子被捕」这个题**
       # 🚩 注意：原版给他 `SOV_safe_from_purge_flag`（开局「免清洗」），又把他列进
       #    `SOV_left_purges` 清洗名单与派系对齐的集团动作 → ⛔ **本线不碰派别斗争 / 清洗**
       # ⛔ 刻意剔除（docs/62 §2.5）：
       #    ⛔ 他签名的那些法令（三穗法 / 刑事诉讼法修改 / 刑责年龄降到 12 岁 / 卡廷）
       #       —— 反面的东西，会把线拉成「他签了什么」
       #    ⛔ 1936 年他评价斯大林那段话 —— 项目口径：文案里不出现斯大林当主语
       #    ⛔ 1921-03-01 喀琅施塔得（他不带卫兵进要塞）与 1921–22 伏尔加饥荒
       #       —— ⚠️ 产物都是「他亲自去了一趟」，判据 C（产物够不够大）不过
       #    ⛔ 1923「第一个访问远东的在任国家元首」—— 地理题是斯米尔诺夫（Idx 6）的
       #    ⛔ 1925 基姆雷改名 / 1931 特维尔改名 —— 不做（矛盾部分只记在 docs/62 §2.5）
       # 🚩🚩 **生成器实测：他排掉【0 人】**（`docs/10` §2.4.2 中立营）——
       #    与另外 21 人【全部可以同席】→ 本线的每一处题材都必须真的独一无二
       #    （docs/62 §2.4 有八处邻接，`docs/23` 判据 E 是这条规则的出处）
       # ⭐ 本线【不需要】$pathChoiceOf / $branchGate / $endingChoiceOf（单线单结局）
       Branch = @(
           'hof_ic_kalinin_a_peasant_head_of_state',          # A1 1919-03-30 农民出身的元首 ← 升 Lv2
           'hof_ic_kalinin_down_with_illiteracy',             # A2 1923 扫除文盲
           'hof_ic_kalinin_the_state_of_the_whole_people',    # A3 1926 全民国家 ← 升 Lv3
           'hof_ic_kalinin_the_reception_room',               # A4 1920s–40s 接待室
           'hof_ic_kalinin_an_unfounded_operation',           # A5 1932-05-04 没有根据的行动 ← 升 Lv4
           'hof_ic_kalinin_the_all_union_elder'               # E1（前置 = A1..A5 全）
       ) }

    @{ Idx = 15; Key = 'maksim_litvinov';        Zh = '马克西姆·李维诺夫';
       SeatDesc = '作为一名职业外交官，马克西姆·李维诺夫熟悉与西方打交道的分寸。如果邀请他加入最高苏维埃，我们相信他能在国际事务上发挥很大作用。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_maksim_litvinov.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_maksim_litvinov';
       Mod    = @('improve_relations_maintain_cost_factor = -0.03');
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_maksim_litvinov';   Zh = '驻爱沙尼亚代理全权外交代表'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_maksim_litvinov_2'; Zh = '外交副人民委员';             Pp = -0.30;
              Add = @('improve_relations_maintain_cost_factor = -0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_maksim_litvinov_3'; Zh = '外交人民委员';               Pp = -0.30;
              Add = @('improve_relations_maintain_cost_factor = -0.05', 'opinion_gain_monthly_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_maksim_litvinov_4'; Zh = '驻国际联盟代表';             Pp = -0.30;
              Add = @('improve_relations_maintain_cost_factor = -0.05', 'opinion_gain_monthly_factor = 0.05', 'trade_opinion_factor = 0.05') }
       );
       # 三级门槛与那一级在讲什么咬合（docs/66 §4.2）：
       #   战俘交换协议（1920-02）→ 外交副人民委员（1921-05）  ⭐ 他就是因为那件事被提上来的
       #   李维诺夫议定书（1929-02）→ 外交人民委员（1930-07）  ⭐ 议定书签成的第二年，他接替契切林
       #   侵略的定义（1933-02）→ 驻国际联盟代表（1934）      ⭐ 因为定义下来了，苏联才被接进去
       RankGates = @(
           @{ Id = 'hof_ic_idea_maksim_litvinov_4'; Gate = 'has_completed_focus = hof_ic_litvinov_the_definition_of_aggression' },
           @{ Id = 'hof_ic_idea_maksim_litvinov_3'; Gate = 'has_completed_focus = hof_ic_litvinov_the_litvinov_protocol' },
           @{ Id = 'hof_ic_idea_maksim_litvinov_2'; Gate = 'has_completed_focus = hof_ic_litvinov_the_prisoner_exchange_agreement' }
       );
       Branch = @(
           'hof_ic_litvinov_a_courier_of_iskra',                 # A1 1902-04 火星报的代办员
           'hof_ic_litvinov_the_prisoner_exchange_agreement',    # A2 1920-02-12 战俘交换协议 ← 升 Lv2
           'hof_ic_litvinov_the_litvinov_protocol',              # A3 1929-02 李维诺夫议定书 ← 升 Lv3
           'hof_ic_litvinov_the_definition_of_aggression',       # A4 1933-02-06 侵略的定义 ← 升 Lv4
           'hof_ic_litvinov_the_franco_soviet_treaty',           # A5 1935-05 苏法互助条约
           'hof_ic_litvinov_the_advisor_to_the_commissariat'     # E1（前置 = A1..A5 全）
       ) }

    @{ Idx = 16; Key = 'grigory_sokolnikov';     Zh = '格里戈里·索柯里尼柯夫';
       SeatDesc = '作为一名财政专家，格里戈里·索柯里尼柯夫曾经稳住过我国的货币。若是邀请他加入最高苏维埃，我们一方面将受益于他对财政的把握，另一方面也能借此收敛开支。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_grigory_sokolnikov.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_grigory_sokolnikov';
       Mod    = @('consumer_goods_factor = -0.03');
       # -----------------------------------------------------------------------------
       # ⭐⭐⭐ 根 =「一个手里只有一张汇率表的人」（会六种语言，索邦读完法律与经济）
       # ⭐⭐⭐⭐ 主干 =「让一张印出来的纸，变成可以拿去算的钱」——
       #    ⭐ 一句话记法：**别人在争「拿多少」，他在争「什么算数」。**
       #    五个尺度：先把账拿到手里 → 不是钱的钱先换掉 → 换全国 → 能对外折算 → 光稳钱不够
       #    ⭐⭐ 呼应：根是「他手里有一张汇率表」，E1 是「那张表上的东西变成了硬通货」。
       # -----------------------------------------------------------------------------
       # 🚩🚩 第 0 步（「原版专做过」**第 6 次执行**）：原版【把他写成了「被请回来的那个人」】——
       #    国策 `SOV_the_need_for_policy_changes`（soviet.txt L9886）的描述就是
       #    「**我们应该把索柯里尼柯夫同志请回来**」，它的图标是
       #    `GFX_focus_hol_abandon_the_gold_standard`（「放弃金本位」）。
       #    → ⛔ 本线【不做】「被请回来」；⛔ 【不出现】「金本位」字样
       #      （⚠️ 且史实方向相反 —— **他恢复的是金准备**）
       #    ⭐ 这是「**原版把某件事替某人写成台词**」的第 **2** 例（第 1 例 = 里亚京 `SOV_liberate_ryutin`）。
       # 🚩 他还有 **22 人里第 2 例专属领袖特质 `peoples_commissar_of_finance`**
       #    （`country_leader/00_traits.txt` L8092）——
       #    `industrial_capacity_factory/dockyard = 0.15` + `production_speed_buildings_factor = -0.05`
       #    + `industry_repair_factor = -0.05` → ⭐ **全是工业侧**；
       #    花名册的 `consumer_goods_factor` 是**消费侧**，**不同量** ✅
       # 🚩 要绕开的机制【十四套】（docs/68 §1.4）；他也是**大清洗目标**（原版自标 `#NOT-SO-HISTORICAL`）
       # 🚩🚩 **生成器实测：他排掉【0 人】**（`neutral` 营第 3 人）——
       #    与另外 21 人【全部可以同席】→ 本线**每一处题材都必须真的独一无二**
       #    （docs/68 §2.4 有十二处邻接，`docs/23` 判据 E 是这条规则的出处）
       # ⭐ 本线【不需要】$pathChoiceOf / $branchGate / $endingChoiceOf（单线单结局）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_grigory_sokolnikov';   Zh = '财政副人民委员'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_grigory_sokolnikov_2'; Zh = '财政人民委员';   Pp = -0.30;
              Add = @('consumer_goods_factor = -0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_grigory_sokolnikov_3'; Zh = '驻英国全权代表'; Pp = -0.30;
              Add = @('consumer_goods_factor = -0.05', 'trade_opinion_factor = 0.05') }
       );
       # ⭐ A3 → Lv2 是**同期的**（1922-11 发行切尔沃涅茨 / 1922 秋正式任人民委员）—— **咬合紧**。
       # ⚠️ A5 → Lv3 是**松咬合** —— 史实上他去伦敦不是因为那句话，而是 1928-07 那次谈话事件。
       #    **如实说明，不编因果**（docs/69 §4.2）。
       RankGates = @(
           @{ Id = 'hof_ic_idea_grigory_sokolnikov_3'; Gate = 'has_completed_focus = hof_ic_sokolnikov_state_capitalism' },
           @{ Id = 'hof_ic_idea_grigory_sokolnikov_2'; Gate = 'has_completed_focus = hof_ic_sokolnikov_the_chervonets' }
       );
       Branch = @(
           'hof_ic_sokolnikov_the_nationalisation_of_the_banks',  # A1 1917-12 银行国有化
           'hof_ic_sokolnikov_the_turkestan_rouble',              # A2 1920 突厥卢布
           'hof_ic_sokolnikov_the_chervonets',                    # A3 1922-11 切尔沃涅茨 ← 升 Lv2
           'hof_ic_sokolnikov_what_a_dollar_costs',               # A4 1923-01 一美元值多少
           'hof_ic_sokolnikov_state_capitalism',                  # A5 1928 国家资本主义 ← 升 Lv3
           'hof_ic_sokolnikov_hard_currency'                      # E1（前置 = A1..A5 全）
       ) }


    @{ Idx = 17; Key = 'mikhail_tukhachevsky';   Zh = '米哈伊尔·图哈切夫斯基';
       SeatDesc = '一位主张把红军机械化的元帅，在最高苏维埃中占有一席之地。米哈伊尔·图哈切夫斯基不仅打过内战，还设计了未来的作战方式；邀请他加入最高苏维埃，风险不大而收益却很可观。';
       Dds    = 'gfx/leaders/SOV/Portrait_Soviet_Mikhail_Tukhachevsky.dds';
       Note   = '原版大幅立绘 156x210';
       Idea   = 'hof_ic_idea_mikhail_tukhachevsky';
       Mod    = @('army_org_factor = 0.03');
       # -----------------------------------------------------------------------------
       # ⭐⭐⭐ 根 =「一个手里只有别人的一本野战手册的军团长」（1919）
       #   方面军司令萨莫伊洛十天内五次改变第 5 军团的任务，他写信收诉，
       #   并谴责对方「应该回去阅读野战手册」。
       # ⭐⭐⭐⭐ 主干 =「把分散的构想，凭职权整合成全军必须照着执行的条令」
       #   一句话记法：**别人想出来的东西，是他让它变成条令的。**
       #   五个尺度：教谁 → 谁来当兵 → 拿什么打 → 怎么练 → 怎么打
       #   ⭐⭐ 首尾同轴：根是他手里只有【别人的】一本野战手册，
       #      E1 是那本野战手册【由他署名】、全军照着它组织与训练。
       # -----------------------------------------------------------------------------
       # 🚩🚩 第 0 步（「原版专做过」**第 7 次执行**，性质是【第 3 种】）：
       #    前两种 = 「原版替他做过一件事」（托姆斯基/里亚京）·「原版把他做成一条路线的名字」（李维诺夫）；
       #    ⭐ 这一种 = **原版把他写成【别人棋盘上的一枚子】** ——
       #    国策 `SOV_approach_tukhachevsky`（原版 soviet.txt L8868 / R56 L10752）的效果是
       #    把他 + Kork + Feldman + 若干随机师长 **转成 `trait_SOV_trotskyist`**，
       #    并给左翼反对派加陆海空支持 → 不是「他做了什么」，是「别人把他算进了哪个阵营」。
       #    → ⛔ 本线【不做】「他属于哪个派别」。
       # 🚩 他还有：元帅审判 `SOV_great_purge_army_trial_of_the_generals_effect`
       #    （decisions/SOV.txt L17045，注释就写着 `#TRIAL OF THE GENERALS -> Tukhachevsky`）
       #    + Paranoia 照片系统 `SOV_paranoia_photo_tukhachevsky` + 大清洗目标
       #    → ⛔ 审判 / 枪决 / 1937 / 平反 全不做；Paranoia 本 mod 不接。
       # ✅ 他【没有】专属领袖特质（不像李维诺夫第 1 例 / 索柯里尼柯夫第 2 例）；
       #    ⭐ 但原版给他的顾问位是 `theorist`（理论家），特质 `mass_assault_expert`
       #    → `mass_assault_mastery_gain_factor = 0.15` —— 指路：他的招牌在【学说那层】。
       # 🚩 十五套机制要绕开（docs/71 §1.4）；
       #    ⭐⭐⭐ 其中最大一件：「大纵深作战」在 HOI4 1.19 里【已经是一条子学说】
       #    `deep_battle`（doctrines/subdoctrines/land/operations_subdoctrines.txt L360），
       #    **苏联开局就带**（history/countries/SOV L1242-1246，100 掌握度）
       #    → ⛔ 不能把「采用大纵深」做成一串国策；
       #    ✅ **但原版【没有任何国策/事件】给过 `deep_battle` 掌握度** → 这个口子空着，
       #       本线在 A4 用 `add_mastery` 补上（用户 2026-09-20 批准）。
       # 🚩🚩 **生成器实测：他排掉【1 人】**（↔ 伏罗希洛夫，R1 历史交恶）——
       #    与其余 20 人【全能同席】→ 每一处题材都必须真的独一无二（docs/71 §2.4 十二处邻接）。
       # ⚠️⚠️ **两处硬撞车**：
       #    ① **托洛茨基（Idx 1）的 5 块军事** —— ⭐ 界线由史实钉死：
       #       他 1930-01 的方案【反对托洛茨基主张的民兵制】，要求建立正规军；
       #    ② **斯米尔诺夫（Idx 6）的 `the_fifth_army`** —— **两人同在第 5 军团！**
       #       → 本线一个节点都不碰第 5 军团。
       # ⚠️ **隐喻邻接**：加米涅夫（Idx 5）「把列宁的文本变成党的公共财产」
       #    → ⭐ 界线：**加米涅夫做的是「保存与传播」（出版物），他做的是「约束与执行」（条令）。**
       # ⭐ 数值：照 `docs/23` **判据 H（选哪一类）+ 判据 I（每条给多少）** ——
       #    全值 +0.05 · 半值 +0.10 或补条数 · 小值 +0.10 且必须补条数；**每节点 2–4 条**。
       # ⭐ 本线【不需要】$pathChoiceOf / $branchGate / $endingChoiceOf（单线单结局）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_mikhail_tukhachevsky';   Zh = '工农红军军事学院院长'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_mikhail_tukhachevsky_2'; Zh = '红军参谋长';         Pp = -0.30;
              Add = @('land_doctrine_cost_factor = -0.05', 'experience_gain_army_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_mikhail_tukhachevsky_3'; Zh = '国防第一副人民委员'; Pp = -0.30;
              Add = @('land_doctrine_cost_factor = -0.05', 'experience_gain_army_factor = 0.05',
              'army_armor_attack_factor = 0.05', 'special_forces_attack_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_mikhail_tukhachevsky_4'; Zh = '苏联元帅';           Pp = -0.30;
              Add = @('land_doctrine_cost_factor = -0.05', 'experience_gain_army_factor = 0.05',
              'army_armor_attack_factor = 0.05', 'special_forces_attack_factor = 0.05',
              'army_attack_factor = 0.05', 'breakthrough_factor = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/72 §4.2）：
       #   军事学院（1921-08）→ 红军参谋长（1925-11）      ⭐ 语义咬合：从【教全军】到【坐进能署名写条令的位置】
       #   空降兵与战车（1931）→ 国防第一副人民委员（1931-06）⭐ 紧咬合：他就任当年就组建伞兵
       #   四个梯次（1936）    → 苏联元帅（1935-11）          ⚠️ 松咬合：授元帅早于条令定稿 —— 如实说明，不编因果
       RankGates = @(
           @{ Id = 'hof_ic_idea_mikhail_tukhachevsky_4'; Gate = 'has_completed_focus = hof_ic_tukhachevsky_the_four_echelons' },
           @{ Id = 'hof_ic_idea_mikhail_tukhachevsky_3'; Gate = 'has_completed_focus = hof_ic_tukhachevsky_airborne_and_tanks' },
           @{ Id = 'hof_ic_idea_mikhail_tukhachevsky_2'; Gate = 'has_completed_focus = hof_ic_tukhachevsky_the_military_academy' }
       );
       Branch = @(
           'hof_ic_tukhachevsky_the_military_academy',         # A1 1921-08 军事学院 ← 升 Lv2
           'hof_ic_tukhachevsky_the_regular_army',              # A2 1930-01 正规军
           'hof_ic_tukhachevsky_airborne_and_tanks',            # A3 1931-32 空降兵与战车 ← 升 Lv3
           'hof_ic_tukhachevsky_the_deep_battle_instructions',  # A4 1933→35 纵深战斗指示
           'hof_ic_tukhachevsky_the_four_echelons',             # A5 1936 四个梯次 ← 升 Lv4
           'hof_ic_tukhachevsky_the_four_echelons',             # A5 1936 四个梯次 ← 升 Lv4
           'hof_ic_tukhachevsky_the_defence_of_the_union',      # B1 1926-12-26 联盟国防（支线 B 起点）
           'hof_ic_tukhachevsky_military_economic_mobilization',  # B2 1930-01 军事经济动员
           'hof_ic_tukhachevsky_air_mechanization',             # B3 1931 空中机械化（支线 B 走到头）
           'hof_ic_tukhachevsky_the_field_regulations'          # E1（前置 = 两条支线【任一到头】，OR）
       ) }

    @{ Idx = 18; Key = 'nikolay_voznesensky';    Zh = '尼古拉·沃兹涅先斯基';
       SeatDesc = '作为一名计划工作者，尼古拉·沃兹涅先斯基熟悉国家的账本与产能。如果邀请他加入最高苏维埃，我们相信他能在工业规划上发挥很大作用。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_nikolay_voznesensky.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_nikolay_voznesensky';
       Mod    = @('production_speed_buildings_factor = 0.03');
       # -----------------------------------------------------------------------------
       # ⭐⭐⭐ 根 =「计划是同自发势力作斗争，不是同它结合」（1931-10-08）
       #   —— 他自己写的（中文马克思主义文库有他的篇目页，4 篇，全部 1931–1934）。
       #   「社会主义计划是在斗争中而不是在同小资产阶级自发势力和由它产生的
       #     资本主义因素的结合中发挥作用的。」
       #   同篇还把「迁就现实」与「凭空乱写」一起封掉：
       #   「同轻率地作空头『计划』的癖好和过火行为作斗争也是必要的。」
       # ⭐⭐⭐⭐⭐ 主干 =「把『拿得出多少』变成一切决定的依据」
       #   一句话记法：**别人在争「要多少」，他只回答「有多少」。**
       #   五个尺度：写下立场 → 一张市里的表 → 一张全国的表 → 表在战争里被重排
       #             → 表开始决定战役 → 给那个时代的经济命名
       #   ⭐⭐ 首尾同轴：根 = 一个 27 岁教员在《真理报》上写下的立场；
       #      E1 = 一个国家在只剩一半工业区时，按「有多少」把战争打完。
       # -----------------------------------------------------------------------------
       # 🚩🚩 第 0 步（「原版专做过」**第 8 次执行**，性质是【第 5 种】）：
       #    1=托姆斯基（替他做过一件事）· 2=里亚京（同）· 3=施利亚普尼科夫（没有）
       #    4=加里宁（没有）· 5=李维诺夫（做成一条路线的名字）
       #    6=索柯里尼柯夫（「被请回来的那个人」）· 7=图哈切夫斯基（别人棋盘上的一枚子）
       #    ⭐ **5 = 原版给了他【一个顾问位 + 一张专属 idea 小图】，但没有给他任何【事】。**
       #    原版 `common/characters/SOV.txt` L2229 有完整角色对象（political_advisor，
       #    特质 `captain_of_industry` = **通用**建造速度特质，不是专属），
       #    `history/countries/SOV` L33 有 recruit_character；
       #    **没有任何国策/事件/决策提到他**，**不在任何大清洗 / Paranoia 名单里**。
       #    → ✅ 本线【不自建角色】（生成器 §7b 不动），
       #      也【不需要绕开任何「他做过的事」】—— 要绕开的是【他的岗位对应的一大片政策题】。
       # 🚩🚩 必须绕开的一整套：**原版苏联国策树里那条完整的工业 / 计划线（30 条）** ——
       #    重工业 / 五年计划（第二·三·四）/ 重工业人民委员部改组 / 工业现代化 /
       #    计划经济 / 稳步工业化 / 发展乌拉尔 / **向乌拉尔转移工业** / 发展东部 /
       #    地区发展 / **增加国家资源储备** / 优化生产线 / 铸钢工业 / 石油生产 /
       #    合成橡胶 / 发展坦克城 / 改善铁路网 / **战时经济** / 转向军备生产 /
       #    强化动员计划 / 重建和发展 / 重建国家 / 社会主义竞赛 / 斯达汉诺夫运动 /
       #    机械制造人民委员部 / 迫击炮人民委员部 / 原子弹计划 / 经互会 /
       #    共同经济空间 / 体制去中心化 / 列宁格勒理工学院 / 加盟共和国科学院
       # ⚠️⚠️ **三处硬撞车（逐条定界线）**：
       #    ① 🔴🔴 **`SOV_war_economy` 中文名就叫「战时经济」** →
       #       ⛔ E1 不叫「战时经济」；✅ E1 = **「苏联战时经济」**（**他自己那本书的书名**，
       #       中译本 =《卫国战争期内的苏联战时经济》，外国文书籍出版社 1948）→ **不同名**
       #    ② 🔴 `SOV_move_industry_to_the_urals`「向乌拉尔转移工业」做的是【搬】；
       #       ✅ 本线做的是【搬到哪去、以及在那里再建一份】—— 1941-08-07 国防委员会
       #       **第 421 号决议**把安置交给国家计委，产物 = 安置表 + **重复生产**
       #    ③ ⚠️ `SOV_fourth_five_year_plan`「第四个五年计划」同名 → ⛔ A5 不用它
       #    ⛔ 另：**「建立储备」不做**（原版 `SOV_increase_state_reserves` 描述几乎就是他的原话）
       #    ⛔ **原子能（1945-08-20 特别委员会）不做**（原版 `SOV_soviet_atomic_bomb_project` 已占 + 涉核）
       #    ⛔ **列宁格勒案件 / 处决 / 平反 不做**（全网禁区；且他被指控的事他没做过）
       #    ⛔ **「大清洗替他腾出了位子」不做**（是别人替他做的事，不是他的主张）
       # 🚩🚩 **生成器实测：他排掉【0 人】** —— `neutral` 营第 4 人，与 21 人**全能同席**
       #    → **最难的一档**（与加里宁 / 李维诺夫 / 索柯里尼柯夫 / 图哈切夫斯基同档或更难）
       #    → docs/74 §7.1 那**十二处邻接一处都不能省**
       # ⭐⭐⭐ **与斯米尔加（Idx 10）的界线（最险的一处）**：
       #    **斯米尔加做「计划这套东西是怎么被想出来的」（1921–1933）；
       #      本线做「这套东西在战争里怎么兑现」（1935–1947）。**
       #    📌 **斯米尔加 1937-01-10 就死了 —— 他根本没活到战争。**
       #    ⛔ 官衔链【不用】「苏联国家计划委员会副主席」（斯米尔加 Lv3 已占）
       #    ⛔ 官衔链【不用】「联共（布）中央政治局委员」（布哈林 / 季诺维也夫已占）
       # ⭐ 数值：照 `docs/23` **判据 H（选哪一类）+ 判据 I（每条给多少）** ——
       #    ⚠️ 席位 `Mod = production_speed_buildings_factor`（建造速度）
       #    → 本线节点改用**工业产能 / 工厂效率 / 工业综合体建造速度 / 消费品**这一组
       #    全值 +0.05 · 半值 +0.10 或补条数 · 小值 +0.10 且必须补条数；**每节点 2–4 条**。
       # ⭐ 本线【不需要】$pathChoiceOf / $branchGate / $endingChoiceOf（单线单结局）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_nikolay_voznesensky';   Zh = '列宁格勒市计划委员会主席'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_nikolay_voznesensky_2'; Zh = '苏联国家计划委员会主席';   Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05', 'production_factory_efficiency_gain_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_nikolay_voznesensky_3'; Zh = '苏联人民委员会第一副主席'; Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05', 'production_factory_efficiency_gain_factor = 0.05',
              'production_speed_buildings_factor = 0.05', 'stability_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_nikolay_voznesensky_4'; Zh = '苏联部长会议第一副主席';   Pp = -0.30;
              Add = @('industrial_capacity_factory = 0.05', 'production_factory_efficiency_gain_factor = 0.05',
              'production_speed_buildings_factor = 0.05', 'stability_factor = 0.05',
              'production_factory_max_efficiency_factor = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/75 §4.2）：
       #   列宁格勒计划委员会（1935）→ 苏联国家计委主席（1938-01-19）  ⭐ 紧咬合
       #   国家计划委员会（1938-01-19）→ 人民委员会第一副主席（1941-03-10）⚠️ 稍晚
       #   安置疏散企业（1941-08-07）→ 部长会议第一副主席（1946-03-19）    ⚠️ 松咬合（如实标注，不编因果）
       RankGates = @(
           @{ Id = 'hof_ic_idea_nikolay_voznesensky_4'; Gate = 'has_completed_focus = hof_ic_voznesensky_the_placement_of_plants' },
           @{ Id = 'hof_ic_idea_nikolay_voznesensky_3'; Gate = 'has_completed_focus = hof_ic_voznesensky_the_state_planning_committee' },
           @{ Id = 'hof_ic_idea_nikolay_voznesensky_2'; Gate = 'has_completed_focus = hof_ic_voznesensky_the_leningrad_plan' }
       );
       Branch = @(
           'hof_ic_voznesensky_the_fight_for_the_plan',        # A1 1931-10-08 为实现当前阶段的计划而斗争
           'hof_ic_voznesensky_the_leningrad_plan',            # A2 1935–1937 列宁格勒计划委员会  ← 升 Lv2
           'hof_ic_voznesensky_the_state_planning_committee',  # A3 1938-01-19 国家计划委员会    ← 升 Lv3
           'hof_ic_voznesensky_the_placement_of_plants',       # A4 1941-08-07 安置疏散企业      ← 升 Lv4
           'hof_ic_voznesensky_the_ammunition_plan',           # A5 1941–1942 弹药生产计划
           'hof_ic_voznesensky_the_war_economy'                # E1（前置 = A1..A5 全）
       ) }

    @{ Idx = 19; Key = 'pyotr_smirnov';          Zh = '彼得·斯米尔诺夫';
       SeatDesc = '作为一名政治委员，彼得·斯米尔诺夫既懂政治工作，也熟悉舰队。若是邀请他加入最高苏维埃，我们一方面将受益于他的军事经验，另一方面也能借此加强对海军的掌握。';
       NewArt = 'gfx/interface/hof_ic/portraits/hof_portrait_SOV_pyotr_smirnov.dds';
       Note   = '自绘立绘 156x210';
       Idea   = 'hof_ic_idea_pyotr_smirnov';
       Mod    = @('war_support_factor = 0.03');
       # -----------------------------------------------------------------------------
       # ⭐⭐⭐ 根 =「1926 年，海军在公文里还只是一个『局』」
       #   —— 他 1926-01 出任波罗的海舰队政治部主任；同年「苏联海军局」改称
       #      「工农红军海军局」—— **仍然只是一个局**（海军的指挥归陆海军人民委员部）。
       # ⭐⭐⭐⭐⭐ 主干 =「把舰队该有的东西，一件件从陆军那里拿回来」
       #   一句话记法：**别人在造船，他在造「部」。**
       #   ⭐⭐ 首尾同轴：根 = 海军只是一个「局」（1926）；
       #      E1 = 海军是苏联自己的一个「部」（1937-12-30）。
       #   ⭐⭐ 主干的原文凭据 = 1937-12-30 决议第 2 条：
       #      «выделив их из состава Народного комиссариата обороны СССР»
       #      （把它们从苏联国防人民委员部里【分出来】）。
       # -----------------------------------------------------------------------------
       # 🚩🚩 第 0 步（「原版专做过」**第 8 次执行**，性质是【第 6 种】）：
       #    1=托姆斯基/里亚京（替他做过一件事）· 2=李维诺夫（做成一条路线的名字）
       #    3=图哈切夫斯基（别人棋盘上的一枚子）· 4=索柯里尼柯夫（「被请回来的那个人」）
       #    5=沃兹涅先斯基（一个顾问位 + 一张专属小图，但没有事）
       #    ⭐ **6 = 完整角色对象 + 一个具体职务槽位 + 被写进【别人的】集体处置事件。**
       #    原版 `common/characters/SOV.txt` VAN L1696 / R56 L1992 有完整角色对象
       #      （advisor slot = `navy_chief`，特质 `navy_chief_naval_aviation_1` = 通用），
       #      `history/countries/SOV` VAN L106 有 recruit_character；
       #      并且 `events/SovietUnion.txt` 的 `soviet.26` 选项 A（**VAN 整块注释掉、R56 启用**）
       #      把他与 图哈切夫斯基 / 叶戈罗夫 / 布柳赫尔 / 弗里诺夫斯基 一起 `retire_character`。
       #    → ✅ 本线【不自建角色】（生成器 §7b 不动）
       #    → ⛔ **「大清洗 → 撤职 → 处决 → 平反」全不做**（他与图哈切夫斯基 Idx 17 共享同一事件）
       # 🚩🚩 必须绕开的一整套：**原版 / R56 的海军线 14 条** ——
       #    扩建红海军 / 增建西部·北部·南部·东部海军基地（R56 + 里海）/ 扩建造船厂 /
       #    合并造船厂 / **苏联海军人民委员部** / 水下作战 / **蓝水海军** / 海军步兵 /
       #    重建远东舰队 / 远东舰队现代化 / 改进海军学说
       #    ⭐ **界线**：原版那 14 条全是「**物**」（造船 / 装备 / 学说 / 陆战队 / 基地）；
       #       本线全是「**机关**」（部 / 总参谋部 / 军事委员会 / 兵种归建 / 报刊宣示）
       # ⚠️⚠️ **三处命名硬撞车（逐条定界线）**：
       #    ① 🔴🔴 原版 `SOV_pc_of_the_ussr_navy` 中文名就叫「苏联海军人民委员部」
       #       → ✅ **用户 2026-09-20 口径「名字不是完全相同就可以」** → **E1 仍取「海军人民委员部」**
       #          （原版那条做的只是「给舰队加一个动态民族精神：改装 −5% / 维修 +5%」，
       #            与本线「这个部怎么被争来的」机制毫不相干）
       #    ② ⚠️ 原版 `SOV_an_oceangoing_navy` =「蓝水海军」 → 「远洋海军」**不同名** → ✅ 可用（用户口径）
       #    ③ 🔴 原版 `SOV_third_five_year_plan` =「第三个五年计划」→ ⛔ **节点名不用它**（desc 里可如实引）
       #    ⛔ 另：**「政委机关怎么建」不做**（用户 2026-09-17 在谢列布里亚科夫那轮砍过，docs/41 §304）
       #    ⛔ **镇压喀琅施塔得不做**（与斯米尔加 Idx 10 / 托姆斯基 Idx 11 撞）
       #    ⛔ **远东不做**（= 伊万·斯米尔诺夫 Idx 6 的地理）
       #    ⛔ **「木匠 / 锁匠」母题不用**（加里宁 Idx 14 的 E1 引文就是「锁匠加里宁」—— 判据 A）
       # 🚩🚩 **生成器实测：他排掉【0 人】** —— `neutral` 营第 5 人，与 21 人**全能同席**
       #    → **最难的一档** → docs/77 §6 那**九处邻接一处都不能省**
       # ⭐⭐⭐ **同名三人**（docs/38 教训的**第 2 次**执行）：
       #    伊万·尼基季奇（Idx 6，已实装）· **彼得·亚历山德罗维奇（本线）** ·
       #    彼得·伊万诺维奇·**斯米尔诺夫-斯维特洛夫斯基**（不在名册，是本人的第一副手兼继任）
       # ⭐ 数值：照 `docs/23` **判据 H + 判据 I** ——
       #    ⚠️ 席位 `Mod = war_support_factor` → **本线全线下掉 `war_support_factor`**（撞量纲）
       #    → 改用**海军 + 机关**这一组（9 个词条**全部有官方中文 `_tt`**，免写自建键）：
       #      navy_org_factor / naval_damage_factor / navy_max_range_factor /
       #      naval_coordination / navy_leader_cost_factor / industrial_capacity_dockyard
       # ⭐ 本线【不需要】$pathChoiceOf / $branchGate / $endingChoiceOf（单线单结局）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_pyotr_smirnov';   Zh = '波罗的海舰队政治部主任'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_pyotr_smirnov_2'; Zh = '工农红军政治部主任';     Pp = -0.30;
              Add = @('political_power_factor = 0.05', 'naval_damage_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_pyotr_smirnov_3'; Zh = '苏联国防副人民委员';     Pp = -0.30;
              Add = @('political_power_factor = 0.05', 'naval_damage_factor = 0.05',
              'navy_org_factor = 0.05', 'stability_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_pyotr_smirnov_4'; Zh = '苏联海军人民委员';       Pp = -0.30;
              Add = @('political_power_factor = 0.05', 'naval_damage_factor = 0.05',
              'navy_org_factor = 0.05', 'stability_factor = 0.05',
              'naval_coordination = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/78 §4.1）：
       #   海军总参谋部（1937-12-30）→ 工农红军政治部主任（1937-06-15）⚠️ 门槛【早于】节点 → 松咬合
       #   海军航空兵（1938-01-01）  → 国防副人民委员（1937-09）          ⭐ 紧咬合
       #   海军人民委员部（1937-12-30）→ 海军人民委员                  ⭐⭐ 完全咬合（同一份决议）
       RankGates = @(
           @{ Id = 'hof_ic_idea_pyotr_smirnov_4'; Gate = 'has_completed_focus = hof_ic_pyotr_smirnov_the_commissariat' },
           @{ Id = 'hof_ic_idea_pyotr_smirnov_3'; Gate = 'has_completed_focus = hof_ic_pyotr_smirnov_the_naval_aviation' },
           @{ Id = 'hof_ic_idea_pyotr_smirnov_2'; Gate = 'has_completed_focus = hof_ic_pyotr_smirnov_the_general_staff' }
       );
       Branch = @(
           'hof_ic_pyotr_smirnov_the_naval_directorate',   # A1 1926        工农红军海军局（根）
           'hof_ic_pyotr_smirnov_the_general_staff',       # A2 1937-12-30  海军总参谋部    ← 升 Lv2
           'hof_ic_pyotr_smirnov_the_naval_aviation',      # A3 1938-01-01  海军航空兵      ← 升 Lv3
           'hof_ic_pyotr_smirnov_the_declaration',         # A4 1938-02-03  建军宣示
           'hof_ic_pyotr_smirnov_the_military_council',    # A5 1938-03-13  海军军事委员会
           'hof_ic_pyotr_smirnov_the_commissariat'         # E1 1937-12-30  海军人民委员部  ← 升 Lv4（前置 = A1..A5 全）
       ) }

    # ---- 批 5 · 体制营 ----
    #      ⭐ 2026-09-20：马林科夫加了一条【单对 R1 互斥】（↔ 沃兹涅先斯基），见 $pairRules。
    # =========================================================================
    # ⭐⭐⭐⭐⭐ 马林科夫（Idx 20）· 单线 5 节点 + 1 单结局 = 6 块 —— docs/80 / docs/81
    # -------------------------------------------------------------------------
    #   🚩 第 0 步（「原版专做过」第 9 次执行）性质 = 【第 7 种】：
    #      原版/R56 把他做成了「接班序列上的一个格子」—— 四条入口全指向
    #      「斯大林死后由他接位」（国策 SOV_prolong_the_stalin_legacy / 4 个「猎熊」决议 /
    #      prc.5 事件 / 老树 SOV_consolidate_malenkovs_position_old）→ ⛔ 四条都是领袖线，全不做。
    #   ⭐ 原版 HOI4 对他是【零】（20 条线里第一次）。
    #   🔴 要绕开的「去斯大林化」区块（原版已占 10+ 条）：
    #      SOV_begin_destalinization / SOV_stalins_cult_of_personality /
    #      SOV_denounce_stalinist_crimes / SOV_rehabilitate_stalins_legacy 等
    #      → E1 因此【不取「集体领导」】（docs/81 §4.1 丙）。
    #   ⭐⭐ 根 = 「1925 年，一个 24 岁的人被派去看管党的文件」（1927 任政治局技术秘书）
    #   ⭐⭐⭐⭐⭐ 主干 = 「给每一件要造的东西，配一个造得出来的人」
    #        —— 判据 B 自检：同时握着「中央干部管理局」和「雷达/火箭/图-4 三个特别委员会」
    #           的，22 人里只有他 → 这条轴换个人不成立。
    #   ⭐ 上一轮的施利亚普尼科夫（Idx 13，「国家把经济交给谁」）与本线最近，
    #      但他在本线的排掉名单里（workers × regime）→ 判据 E：不需要避重。
    #   ⛔ 全文案不出现：列宁格勒 / 大清洗 / 被捕 / 审判 / 处决 / 犹太 / 「斯大林」当主语
    #   ⛔ 不碰：1953「新方针」（让给赫鲁晓夫 Idx 21）/ 军事指挥（伏罗希洛夫 Idx 22）
    #   ⚠️ 本线【不自建角色】（R56 common/characters/SOV.txt L113 现成，无 role）
    # =========================================================================
    @{ Idx = 20; Key = 'georgy_malenkow';        Zh = '格奥尔基·马林科夫';
       SeatDesc = '一名熟悉党的档案与人事的人，在任何领导机构里都用得上。格奥尔基·马林科夫长年在组织局主持干部工作；邀请他加入最高苏维埃，对我们来说将是非常有利的。';
       Dds    = 'gfx/leaders/SOV/r56_portrait_SOV_Georgy_Malenkov.dds';
       Note   = 'R56 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_georgy_malenkow';
       Mod    = @('political_power_factor = 0.03');
       # 官衔链四级，【全部是「管人」的岗】—— 与主干一致（docs/81 §2）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_georgy_malenkow';   Zh = '中央政治局技术秘书'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_georgy_malenkow_2'; Zh = '中央领导干部部部长'; Pp = -0.30;
              Add = @('political_advisor_cost_factor = -0.05', 'experience_gain_army_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_georgy_malenkow_3'; Zh = '中央干部管理局局长'; Pp = -0.30;
              Add = @('political_advisor_cost_factor = -0.05', 'experience_gain_army_factor = 0.05',
              'industrial_capacity_factory = 0.05', 'stability_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_georgy_malenkow_4'; Zh = '苏联部长会议主席';   Pp = -0.30;
              Add = @('political_advisor_cost_factor = -0.05', 'experience_gain_army_factor = 0.05',
              'industrial_capacity_factory = 0.05', 'stability_factor = 0.05',
              'war_support_factor = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/81 §2）：
       #   党员登记卡（1935–1936）    → 中央领导干部部部长（1936-02） ⚠️ 门槛【早于】职务 → 松咬合
       #   中央干部管理局（1939-03-22）→ 中央干部管理局局长            ⭐⭐ 完全咬合（同一个机构）
       #   部长会议主席（1953-03-05）  → 苏联部长会议主席              ⭐⭐ 完全咬合（同一个职务）
       RankGates = @(
           @{ Id = 'hof_ic_idea_georgy_malenkow_4'; Gate = 'has_completed_focus = hof_ic_malenkow_the_premiership' },
           @{ Id = 'hof_ic_idea_georgy_malenkow_3'; Gate = 'has_completed_focus = hof_ic_malenkow_the_cadres_directorate' },
           @{ Id = 'hof_ic_idea_georgy_malenkow_2'; Gate = 'has_completed_focus = hof_ic_malenkow_the_party_card_index' }
       );
       Branch = @(
           'hof_ic_malenkow_the_party_card_index',         # A1 1935–1936  党员登记卡（根） ← 升 Lv2
           'hof_ic_malenkow_the_cadres_directorate',       # A2 1939-03-22  中央干部管理局   ← 升 Lv3
           'hof_ic_malenkow_the_state_defence_committee',  # A3 1941-06-30  国防委员会
           'hof_ic_malenkow_the_aviation_affair',          # A4 1946-05-04  航空案
           'hof_ic_malenkow_the_party_schools',            # A5 1946–1947   党校
           'hof_ic_malenkow_the_premiership'               # E1 1953-03-05  部长会议主席     ← 升 Lv4（前置 = A1..A5 全）
       ) }

    # =========================================================================
    # ⭐⭐⭐⭐⭐ 赫鲁晓夫（Idx 21）· 单线 5 节点 + 1 单结局 = 6 块 —— docs/83 / docs/84
    # -------------------------------------------------------------------------
    #   🚩🚩 第 0 步（「原版专做过」第 10 次执行）性质 = 【第 8 种】：
    #      原版/R56 把他做成了「那个真正接班的人」—— 三条夺权国策的【主语都是他】：
    #        ① SOV_khruschev_takes_the_lead_old「赫鲁晓夫掌权」（老树，与马林科夫/贝利亚三方互斥）
    #        ② SOV_civil_war_empower_khrushchev「授权赫鲁晓夫」（内战树，带他的专属肖像）
    #        ③ SOV_forge_new_future「铸就新未来」（主线，add_country_leader_role + promote_leader）
    #      → ⛔ 三条都是【国家领袖线】→ 一条都不接、不重做。
    #   🔴 要绕开的机制【16 套】：去斯大林化区块 9 条（SOV_begin_destalinization /
    #      SOV_denounce_stalinist_crimes / SOV_stalins_cult_of_personality 等全不做）
    #      + SOV_left_purges（8 人集团清洗）+ SOV_gain_support_from_party_members（3 人集团对齐）
    #      + purged_khrushchev / soviet.25.b（VAN 注释掉、R56 启用）
    #      ⚠️ 加里宁（Idx 14）那轮已为同一套绕过一次（docs/62 §1.3）→ 两人共享。
    #   ⭐⭐ 生成器 §0b 实测：他排掉【13 人】→ 只需避【能同席的 8 人】
    #      （加里宁 / 李维诺夫 / 索柯里尼柯夫 / 图哈切夫斯基 / 沃兹涅先斯基 /
    #        彼得·斯米尔诺夫 / 马林科夫 / 伏罗希洛夫 Idx 22）
    #      ⚠️ 与马林科夫（Idx 20）最近：他配【人】，本线交【物与权】（裁量见 docs/84 §7）
    #   ⭐ 根 = 「1917 年，鲁奇琴科沃的矿工把自己人送进了苏维埃」
    #   ⭐⭐⭐⭐⭐ 主干 = 「把东西交到干活的那一级手上」—— ⭐ 别人在加一层，他在往下交。
    #        判据 B 自检：他交的具体是【制度 / 规模 / 钱 / 地 / 工厂】五样，
    #                      凑在一个人身上，22 人里只有他 → 换个人不成立。
    #   ⭐⭐ 首尾同轴：根 = 归属换到自己人手上（1917）；E1 = 他把归属换给它所在的那一级（1957）。
    #   ⚠️ 本线【不自建角色】（原版 common/characters/SOV.txt L2177 现成；
    #      R56 L3700 有大幅立绘）→ 生成器 §7b 不动。
    #   ⛔ 全文案不出现：秘密报告 / 去斯大林化 / 团结在某某麾下 / 玉米 / 新切尔卡斯克 /
    #      1937 / 大清洗 / 被捕 / 处决 / 平反 / 1957 反党集团 / 1964 下台 / 赫鲁晓夫楼（未采纳节点）
    #   ⛔ 节点名里【不出现「斯大林」】（2026-09-20 用户口径「A2 改名」的直接来由）
    # =========================================================================
    @{ Idx = 21; Key = 'nikita_khrushchyov';     Zh = '尼基塔·赫鲁晓夫';
       SeatDesc = '作为一名工人出身、又在乌克兰主持过一方的干部，尼基塔·赫鲁晓夫熟悉基层。如果邀请他加入最高苏维埃，我们相信他能在地方事务上发挥很大作用。';
       Dds    = 'gfx/leaders/SOV/r56_portrait_SOV_Nikita_Khrushchev.dds';
       Note   = 'R56 大幅立绘 156x210';
       Idea   = 'hof_ic_idea_nikita_khrushchyov';
       Mod    = @('production_speed_infrastructure_factor = 0.03');
       # 官衔链四级 =【同一个职务的四次放大】—— 他一生只升过一种官（第一书记）
       #   一个矿 → 一个县 → 一个共和国 → 一个联盟
       # ⭐ 四个职务【全部未被任何已实装线用过】
       # ⛔ 不用「苏联部长会议主席」（马林科夫 Idx 20 的官衔链 Lv4 已占）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_nikita_khrushchyov';   Zh = '鲁奇琴科沃矿的副矿长'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_nikita_khrushchyov_2'; Zh = '彼得罗夫-马林斯基县党委会书记'; Pp = -0.30;
              Add = @('production_speed_infrastructure_factor = 0.05', 'political_power_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_nikita_khrushchyov_3'; Zh = '乌克兰共产党中央委员会第一书记'; Pp = -0.30;
              Add = @('production_speed_infrastructure_factor = 0.05', 'political_power_factor = 0.05',
              'war_support_factor = 0.05', 'production_speed_buildings_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_nikita_khrushchyov_4'; Zh = '苏联共产党中央委员会第一书记'; Pp = -0.30;
              Add = @('production_speed_infrastructure_factor = 0.05', 'political_power_factor = 0.05',
              'war_support_factor = 0.05', 'production_speed_buildings_factor = 0.05',
              'industrial_capacity_factory = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/84 §2）：
       #   工人速成中学（1921-12）    → 彼得罗夫-马林斯基县党委会书记（1925-07）⚠️ 门槛【早】4 年 → 松咬合
       #                               （「他先补齐了那一层，才被放到书记的位子上」）
       #   义务交售制（1946-10-15）   → 乌克兰共产党中央第一书记（1938-01）  ⚠️ 门槛【晚】8 年 → 松咬合，
       #                               但叙事完全咬合（那封信就是他在乌克兰第一书记任上写的）
       #   收购价（1953-09）          → 苏联共产党中央第一书记（1953-09-07） ⭐⭐ 完全咬合（同月）
       RankGates = @(
           @{ Id = 'hof_ic_idea_nikita_khrushchyov_4'; Gate = 'has_completed_focus = hof_ic_khrushchev_the_purchase_prices' },
           @{ Id = 'hof_ic_idea_nikita_khrushchyov_3'; Gate = 'has_completed_focus = hof_ic_khrushchev_the_obligatory_deliveries' },
           @{ Id = 'hof_ic_idea_nikita_khrushchyov_2'; Gate = 'has_completed_focus = hof_ic_khrushchev_the_workers_faculty' }
       );
       Branch = @(
           'hof_ic_khrushchev_the_workers_faculty',        # A1 1921 年末       工人速成中学         ← 升 Lv2
           'hof_ic_khrushchev_the_obligatory_deliveries',  # A2 1946-10-15      义务交售制           ← 升 Lv3
           'hof_ic_khrushchev_the_agro_towns',             # A3 1949–1951       农业城市
           'hof_ic_khrushchev_the_purchase_prices',        # A4 1953-09         收购价               ← 升 Lv4
           'hof_ic_khrushchev_the_virgin_lands',           # A5 1954-02         荒地
           'hof_ic_khrushchev_the_economic_councils'       # E1 1957-05         国民经济委员会（前置 = A1..A5 全）
       ) }

    # =========================================================================
    #  ★★★★★ 伏罗希洛夫（Idx 22 · regime 营）—— docs/86 §2 / docs/87
    #  第 0 步（「原版专做过」第 11 次执行）性质 =【第 9 种】：原版用他的名字命名了三样实物
    #    （KV-1 / KV-2 重型坦克的正式全称、「伏罗希洛夫」号巡洋舰、state 228 伏罗希洛夫格勒）
    #    + 原版写死 field_marshal 五项技能全 1 + R56 的领袖特质里带 incompetent_leader
    #  ⛔ 军事题已被占成死局（托洛茨基 5 块 / 图哈切夫斯基 6 块 / 彼得·斯米尔诺夫的海军 /
    #     斯米尔加与斯米尔诺夫的芬兰与内战）→ 招牌换到「机关 / 制度 / 命名」这一面
    #      （docs/35 §5.1 的【第 8 次运用】）
    #  ⭐ 主干 =「他把一摊事，变成一个交出去也能自己走的机关」—— 别人带兵，他建机关。
    #  ⭐ 首尾同轴：根 = 1906 年他自己给自己起了一个化名（名是他自己起的）；
    #              E1 = 1945 年他手上是一套交给别人用的管制机关。
    #  ⭐ 排掉 14 人（生成器 §0b 实测）→ 只需避【能同席的 7 人】：
    #     马林科夫 / 赫鲁晓夫（⚠️ regime × regime 无互斥规则，两处最险）· 加里宁 · 李维诺夫 ·
    #     索柯里尼柯夫 · 沃兹涅先斯基 · 彼得·斯米尔诺夫
    #  ⛔ 全文案不出现：大清洗 / 签名 / 枪决名单 / 1937 / 被捕 / 处决 / 平反 · 卡廷 ·
    #     1941 年列宁格勒的失败 · 1957 反党集团 · 他 1969 年的死 · 斯大林当主语
    #  ⛔ 节点名里不出现：国防委员会 / 常备军 / 军事学院 / 最高苏维埃主席团主席 / 苏联元帅
    # =========================================================================
    @{ Idx = 22; Key = 'kliment_voroshilov';     Zh = '克利门特·伏罗希洛夫';
       SeatDesc = '一位老布尔什维克和内战英雄，在最高苏维埃中占有一席之地。克利门特·伏罗希洛夫不仅与斯大林共过患难，还长期主持军事人民委员部；邀请他加入最高苏维埃，风险不大而收益却很可观。';
       Dds    = 'gfx/leaders/SOV/Portrait_Soviet_Kliment_Voroshilov.dds';
       Note   = '原版大幅立绘 156x210';
       Idea   = 'hof_ic_idea_kliment_voroshilov';
       Mod    = @('army_org_factor = 0.03');
       # 官衔链四级 =【从地方苏维埃主席一路做到部长会议副主席】
       #   一个市 → 一个军种（陆海军）→ 一个部（国防）→ 一个国家（部长会议）
       # ⭐ 四个职务【全部未被任何已实装线用过】
       # ⛔ 不用「苏联最高苏维埃主席团主席」（1953–1960 —— 加里宁 Idx 14 的 Lv4 已占，两人能同席）
       # ⛔ 不用「苏联人民委员会副主席」（1940 —— 与沃兹涅先斯基 Idx 18 的 Lv3 差两字，两人能同席）
       # ⛔ 不用「苏联元帅」（图哈切夫斯基 Idx 17 的 Lv4 已占）
       Tiers  = @(
           @{ Lv = 1; Id = 'hof_ic_idea_kliment_voroshilov';   Zh = '卢甘斯克苏维埃主席'; Pp = -0.10; Add = @() },
           @{ Lv = 2; Id = 'hof_ic_idea_kliment_voroshilov_2'; Zh = '苏联陆海军人民委员'; Pp = -0.30;
              Add = @('army_morale_factor = 0.05', 'political_power_factor = 0.05') },
           @{ Lv = 3; Id = 'hof_ic_idea_kliment_voroshilov_3'; Zh = '苏联国防人民委员'; Pp = -0.30;
              Add = @('army_morale_factor = 0.05', 'political_power_factor = 0.05',
              'army_attack_factor = 0.05', 'production_speed_buildings_factor = 0.05') },
           @{ Lv = 4; Id = 'hof_ic_idea_kliment_voroshilov_4'; Zh = '苏联部长会议副主席'; Pp = -0.30;
              Add = @('army_morale_factor = 0.05', 'political_power_factor = 0.05',
              'army_attack_factor = 0.05', 'production_speed_buildings_factor = 0.05',
              'industrial_capacity_factory = 0.05') }
       );
       # 三条门槛与那一级在讲什么咬合（docs/87 §3.2）：
       #   工农红军指挥员（1926-09-10）  → 苏联陆海军人民委员（1925-11-06）⚠️ 门槛【早】1 年 → 松咬合
       #   伏罗希洛夫射手（1932-12-29）  → 苏联国防人民委员（1934-06-20）  ⚠️ 门槛【早】1.5 年 → 咬合合理
       #   战利品机关条例（1943-04-05）  → 苏联部长会议副主席（1946-03-15）⚠️ 门槛【早】2.9 年 → 咬合合理
       RankGates = @(
           @{ Id = 'hof_ic_idea_kliment_voroshilov_4'; Gate = 'has_completed_focus = hof_ic_voroshilov_war_trophies_regulation' },
           @{ Id = 'hof_ic_idea_kliment_voroshilov_3'; Gate = 'has_completed_focus = hof_ic_voroshilov_the_marksmanship_badge' },
           @{ Id = 'hof_ic_idea_kliment_voroshilov_2'; Gate = 'has_completed_focus = hof_ic_voroshilov_the_red_army_commanders' }
       );
       Branch = @(
           'hof_ic_voroshilov_the_red_army_commanders',       # A1 1926-09-10    工农红军指挥员         ← 升 Lv2
           'hof_ic_voroshilov_the_marksmanship_badge',        # A2 1932-12-29    伏罗希洛夫射手         ← 升 Lv3
           'hof_ic_voroshilov_the_ranks',                     # A3 1935-09-22    个人军衔制
           'hof_ic_voroshilov_the_partisan_staff',            # A4 1942-09-06    中央游击运动总参谋部
           'hof_ic_voroshilov_war_trophies_regulation',       # A5 1943-04-05    战利品机关条例         ← 升 Lv4
           'hof_ic_voroshilov_the_allied_control_commission'  # E1 1945-02-05    盟国管制委员会（前置 = A1..A5 全）
       ) }
)

if ($roster.Count -lt $seatCount) { throw "花名册必须不少于 $seatCount 人（席位），实际 $($roster.Count) 人" }
# ⚠️ 座位 7 个、候选 22 人（docs/10 §2.4.2 的六个营）——
#    玩家从 22 个入口国策里挑 7 个坐进去；hof_ic_slot_N 存的是【候选人的 Idx】。
if ($roster.Count -ne $seatCount) {
    Write-Output ("  ℹ️ 候选池 {0} 人 / 席位 {1} 个（容差度：玩家自选）" -f $roster.Count, $seatCount)
}

# 入口国策的描述必须逐人写（照德国 GER_ascension_of_<人>_desc）。
# 缺一个就 throw —— 否则会静默地退回模板句，看上去“没问题”但人味全无。
foreach ($c in $roster) {
    if (-not ($c.ContainsKey('SeatDesc') -and $c.SeatDesc)) {
        throw "$($c.Zh) 缺 SeatDesc（入口国策的描述）"
    }
}

# 序号 -> 花名册项 的快速索引
$byIdx = @{}
foreach ($c in $roster) { $byIdx[$c.Idx] = $c }

# -----------------------------------------------------------------------------
# ★ 终局【二选一】数据（机制蓝本：德国 GER_inner_circle_himmler.00）
# -----------------------------------------------------------------------------
#   德国希姆莱的做法（实测 `germany.txt` L19714 + `WUW_Germany.txt` L23960）：
#     ① 事件弹出 2 个选项（标题/描述是叙事，选项是玩家口吻的短句）
#     ② 每个选项给【角色】打一个角色标记（set_character_flag），并把驱动器踢起来
#     ③ 驱动器 .01 读角色标记分叉，把对应的那条链一条条推完
#     ④ 两个一级国策仍然写 mutually_exclusive（手动点选的保险）
#
#   我们的映射：终局两条 = 两个互斥的个人线国策；抉择 = 事件；
#   「支线走通 N 条」这个门控放在【事件的触发条件】里（用户 2026-09-16：按原本设计弹）。
#
#   ⚠️ 事件在 §6 生成，而 §6 跑在 $lineSpecs 之前 → 数据必须放这里。
#   ⚠️ 每人只支持 2 个选项（吃不动更多）。
# -----------------------------------------------------------------------------
$endingChoiceOf = @{
    lev_trotsky = @{
        EvId   = 1050;                    # 二选一事件 id
        Char   = 'SOV_lev_trotsky';       # 打标记的角色（也是 loc scope，名字由角色自己的键提供）
        Amount = 3;                       # 原本的设计：五条支线里走通三条
        Gates  = @('hof_ic_trotsky_against_partisan_warfare',
                   'hof_ic_trotsky_socialism_in_one_country',
                   'hof_ic_trotsky_against_the_bureaucracy',
                   'hof_ic_trotsky_accelerated_industrialization',
                   'hof_ic_trotsky_united_front');
        # 标题 / 选项名【仿钢铁雄心文风】（用户 2026-09-16 口径；参照 GER_inner_circle_himmler.00）
        Title  = '托洛茨基的抉择';
        Desc   = '托洛茨基在最高苏维埃中已经站稳了脚跟。几条主张先后推行开来，剩下最后一件事没有决定：他到底要把这条路走到哪里去。\n\n「要求我放弃政治活动，意味着要求我放弃为全世界工人阶级利益而进行的斗争，而这一斗争我已孜孜不倦地进行了 32 年之久，也就是我自觉生命的全部时间。只有腐朽透顶的官僚集团才会要求做出这种放弃。」\n\n「请告诉我还有哪个人能在一年之内建立起一支堪称楷模的军队而且赢得军事专家的尊重；我们有这样的人，就有了一切，我们将创造出奇迹。」\n\n问题是，应该走哪一条路？';
        Ends   = @(
            @{ Focus = 'hof_ic_trotsky_the_permanent_revolutionary';
               Name  = '永久的革命者';
               Flag  = 'hof_ic_trotsky_ending_revolution_flag';
               Opt   = '把革命推向全世界' },
            @{ Focus = 'hof_ic_trotsky_the_builder_of_the_state';
               Name  = '国家建设者';
               Flag  = 'hof_ic_trotsky_ending_state_flag';
               Opt   = '先把这个国家建设起来' }
        )
    }

    # 季诺维也夫：3 条支线里走通 2 条 → 弹二选一（docs/32 §5.3 候选甲 / docs/33 §1）
    # 🚩 两个结局都是他本人真的走过的一端 —— 1921–22 走 E2（工人统一战线），
    #    1924–25 转向 E1（社会法西斯主义 + 布尔什维克化）。不是「一好一坏」。
    grigory_zinovyev = @{
        EvId   = 1051;                    # 接托洛茨基的 1050 之后的空号（1060/1061 已被岔路占用）
        Char   = 'SOV_grigory_zinovyev';
        Amount = 2;                       # 三条支线里走通两条
        Gates  = @('hof_ic_zinovyev_bolshevization',     # A 支线收束
                   'hof_ic_zinovyev_speed_and_route',    # C 支线收束
                   'hof_ic_zinovyev_trade_unions');      # D 支线收束
        Title  = '季诺维也夫的抉择';
        Desc   = '季诺维也夫在最高苏维埃中已经站稳了脚跟。第三国际是他缔造的，条件是他说了算，支线也铺到了各个大陆——剩下最后一件事没有决定：这个国际到底要长成什么样子。\n\n「共产国际看到了这种危险性，就从自我保护的朴素感情出发，必须采取相应的措施。因此就产生了著名的二十一条，后来围绕这个二十一条展开了非常激烈的斗争。」\n\n「把工会争取过来，意味着赢得了所有的加入组织的工人，甚至是赢得了所有的工人。而赢得所有的工人，意味着打垮资产阶级，使无产阶级革命获得胜利。」\n\n「统一战线的策略不仅同布尔什维克化不矛盾，而且是它的重要组成部分。没有这个策略就不可能有布尔什维克化。」\n\n问题是，铁板一块，还是把门打开？';
        Ends   = @(
            @{ Focus = 'hof_ic_zinovyev_monolithic_international';
               Name  = '铁板一块的国际';
               Flag  = 'hof_ic_zinovyev_ending_monolithic_flag';
               Opt   = '把纪律贯彻到底' },
            @{ Focus = 'hof_ic_zinovyev_mass_international';
               Name  = '群众的国际';
               Flag  = 'hof_ic_zinovyev_ending_mass_flag';
               Opt   = '先把群众争取过来' }
        )
    }
}

# -----------------------------------------------------------------------------
# ★ 树内岔路二选一（2026-09-16）—— 用户：「有限市场化和劳动军不也得出一个事件来选，布哈林那个互斥也是」
#
#   🚩🚩 这【不只是表现问题，是修 bug】：
#     托洛茨基的 IV1「有限市场化」/ IV2「劳动军」【两条都在 $Branch 里】且互为
#     mutually_exclusive。而驱动器 .1110 是「挑列表里第一个未完成的」→ 必然去点
#     那条已被互斥锁死的。官方 effects_documentation.md 对 complete_national_focus
#     只写「completes a focus for a country」，【没有】声明它尊重 mutually_exclusive
#     （对比 complete_prototype_reward_option 就明确写了会尊重 fire_only_once 与 allowed）
#     → 结果二选一：要么卡死，要么两条都被强推完成、岔路被架空。
#
#   做法 = 与终局【同一套标记驱动机制】（照德国 GER_inner_circle_himmler.00）：
#     ① 岔路的两个国策【移出 $Branch】
#     ② 未定方向时驱动器【原地等待】（弹事件 + 重排自己，绝不推进）
#     ③ 定过方向后，驱动器只点亮【被选中的那一条】
#     ④ 下游照常推进（IV3 的前置本来就是「IV1 或 IV2」，被选的那条满足它）
#
#   At     = 在哪一条国策【之前】插入岔路（必须是 $Branch 里的 id）
#   Gates  = 触发门控（照终局用 count_triggers）；Amount = 0 → 入席即可选
#   Term   = 选了就等于自断这条线的标记（选了它，兜底重排要停手，否则无限循环）
# -----------------------------------------------------------------------------
$pathChoiceOf = @{
    lev_trotsky = @{
        EvId   = 1060;
        Char   = 'SOV_lev_trotsky';
        Amount = 0;
        Gates  = @();                                             # 入席即弹；III2 前的驱动检查只作旧档兜底
        At     = 'hof_ic_trotsky_state_planning';               # 插在 IV3 之前
        Title  = '经济的岔路口';
        Desc   = '经济重建已经压到了桌面上。托洛茨基手里有两种办法，而它们互相排斥——一旦走上其中一条，另一条就再也走不通了。\n\n先松开战时共产主义那套严苛的集中制，让市场力量运作起来；或者反过来，把军事纪律搬到经济上来，把士兵当作劳动军。\n\n问题是，应该走哪一条？';
        Term   = @();                                            # 两条路都通向 IV3，没有死路
        Opts   = @(
            @{ Focus = 'hof_ic_trotsky_limited_market_reforms'; Name = '有限市场化';
               Flag  = 'hof_ic_trotsky_path_market_flag';  Opt = '先让市场活起来' },
            @{ Focus = 'hof_ic_trotsky_labour_armies';          Name = '劳动军';
               Flag  = 'hof_ic_trotsky_path_labour_flag';  Opt = '把军队变成劳动大军' }
        )
    }
    nikolay_bukharin = @{
        EvId   = 1061;
        Char   = 'SOV_nikolay_bukharin';
        Amount = 0;
        Gates  = @();                                            # 入席即可选（X1/A1 都是首级国策）
        At     = 'hof_ic_bukharin_nep_is_not_a_retreat';         # 插在 A2 之前
        Title  = '路线之争';
        Desc   = '布哈林一进门就得表明立场。他对过渡时期的判断，决定了他这条线往哪里走。\n\n「列宁教导说：工人阶级同农民的冲突根本不是不可避免的。托洛茨基教导说：这种冲突必定会发生。」\n\n话说到这个份上，只能选一边。';
        # 选了「左翼共产主义」= 自断 A 线（A1 被互斥锁死 → A2/A3/E1 全部作废）
        Term   = @('hof_ic_bukharin_path_left_flag');
        Opts   = @(
            @{ Focus = 'hof_ic_bukharin_economics_of_transition'; Name = '过渡时期的经济';
               Flag  = 'hof_ic_bukharin_path_nep_flag';  Opt = '走过渡时期这一条路' },
            @{ Focus = 'hof_ic_bukharin_left_communism';          Name = '左翼共产主义';
               Flag  = 'hof_ic_bukharin_path_left_flag'; Opt = '一步跨过过渡时期' }
        )
    }
}

# -----------------------------------------------------------------------------
# ★ 岔路下游的 flag 门控（只有布哈林需要）
#   选了 X1「左翼共产主义」后，A1 被 mutually_exclusive 永久锁死。
#   但驱动器的 complete_national_focus 会【绕过前置】继续强推 A2 / A3 / E1
#   → 树上出现「A1 是空的、A2 却已完成」的断链。所以这些国策必须额外卡一道标记。
# -----------------------------------------------------------------------------
$branchGate = @{
    'hof_ic_bukharin_nep_is_not_a_retreat'      = @{ Char = 'SOV_nikolay_bukharin'; Flag = 'hof_ic_bukharin_path_nep_flag' }
    'hof_ic_bukharin_abolish_the_tribute'       = @{ Char = 'SOV_nikolay_bukharin'; Flag = 'hof_ic_bukharin_path_nep_flag' }
    'hof_ic_bukharin_socialism_in_one_country'  = @{ Char = 'SOV_nikolay_bukharin'; Flag = 'hof_ic_bukharin_path_nep_flag' }
    # 📌 加米涅夫 2026-09-17 砍成【单线单结局】后，已经没有岔路了 → 他【不再需要】任何 gate
}

# 每人完整的分级 id 表（没有 Tiers 的就只有一个 id）
# 清 idea / 反推官衔 都要逐级试 —— 只删首级会残留
$tierIdsOf = @{}
foreach ($c in $roster) {
    if ($c.ContainsKey('Tiers') -and $c.Tiers) { $tierIdsOf[$c.Idx] = @($c.Tiers | ForEach-Object { $_.Id }) }
    else { $tierIdsOf[$c.Idx] = @($c.Idea) }
}

# 容器动态精神 id（一个）
$dmId = 'hof_ic_supreme_soviet_dm'

# =============================================================================
# ★ 席位互斥 —— 权威出处 docs/10 §2.4.2（三条规则 + 六个「营」）
# -----------------------------------------------------------------------------
#   规则（docs/10 §2.3 原规则）：
#     R1 历史关系恶劣   → 体制营 × 反对派全体   全交叉
#     R2 理论完全对立   → 左营 × 右营           全交叉
#     R1 追加           → 工反营 × 左营（1920-21 工会大辩论）
#     R1 单独项         → 图哈切夫斯基 ↔ 伏罗希洛夫
#     R3 理论/职能高度相近 → 季诺维也夫↔加米涅夫；安全机构四人两两互斥
#
#   做成【席位入口国策的 available 条件】，不是 mutually_exclusive ——
#   国策互斥是永久锁死，玩家点错一次无法挽回（docs/10 §2.4.1 明禁）。
#   席位条件是可逆的：对头被替换出局后这条路自动重新打开。
#
#   ★ 只对【同时在 $roster 里】的两人生成条件 → 池子扩员时自动生效，本段逻辑不用改。
#   ⚠️ 营表里的键必须与 $roster[].Key 一致（未在册的名字会被静默忽略，无害）。
# =============================================================================

$camps = @{
    # ★ 键的命名规范：= 角色 id 去掉 'SOV_' 前缀（必须等于将来 $roster[].Key，否则静默失效）
    #   2026-09-15 全表规范化：此前混用短形式（preobrazhensky / tomsky / kalinin）与
    #   全形式（lev_trotsky / nikolay_bukharin），扩员到 $roster 时会对不上。
    # 左营 · 超工业化（向农村提取资源、加速工业化、反富农让步）
    left    = @('lev_trotsky','yevgeny_preobrazhensky','karl_radek','ivar_smilga','ivan_smirnov','leonid_serebryakov')
    # 右营 · 平衡增长（对农民让步、合作社长入）
    right   = @('nikolay_bukharin','aleksey_rykov','mikhail_tomsky','martemyan_ryutin')
    # 联合营 · 季诺维也夫派（党的机关派）
    united  = @('grigory_zinovyev','lev_kamenev')
    # 工反营 · 工人反对派（工会独立）
    workers = @('aleksandr_shlyapnikov')
    # 中立营 · 【不因理论】与任何营互斥（国家元首 / 外交 / 军事专业 / 技术官僚）
    #   ⚠️ 2026-09-16 措辞收紧：原来的「与任何营都不互斥」在 7 人小池里碰巧成立，
    #      22 人池一扩就崩 —— 图哈切夫斯基（中立）对沃罗希洛夫（体制）有 1937-06 血债，
    #      那是 R1 历史交恶，个人恩怨、跳营生效，不算理论冲突。
    #   ★ 只列【有立绘】的人。原 14 人里的 8 人（奥尔忠尼启则/捷尔任斯基/古比雪夫/
    #     基洛夫/米高扬/皮达可夫/穆拉洛夫/柯伦泰）经核对【大图小图都没有】，
    #     已按用户 2026-09-15 口径删除（docs/10 §2.4.2.1）。
    neutral = @('mikhail_kalinin','maksim_litvinov','grigory_sokolnikov','mikhail_tukhachevsky','nikolay_voznesensky','pyotr_smirnov')
    # 体制营 · 斯大林系「部分回池」3 人（2026-09-15 追加，依据 docs/10 §2.4.2.2.1）
    #   ✅ 回池理由：反对派胜利后能活、对池内人物无直接血债、非安全机构、1936 年层级不高
    #        georgy_malenkow    —— 1953「新方针」＝布哈林路线（均衡增长 / 优先轻工业）
    #        nikita_khrushchyov —— 1956 秘密报告；1923-24 顿巴斯时期有托洛茨基反对派倾向
    #        kliment_voroshilov —— 老布尔什维克＋内战英雄（⚠️ 对图哈切夫斯基有血债）
    #   ❌ 确认不回池 6 人（对池内人物有直接血债，或本身就是秘密警察）：
    #        vyacheslav_molotov / lazar_kaganovich / genrikh_yagoda /
    #        nikolay_yezhov / lavrenty_beriya / vsevolod_merkulov
    #   ★ 2026-09-16：这 3 人【已入 $roster】（Idx 20-22）→ 下面 4 条营×营互斥自本条起生效
    #     （regime×left 18 + regime×right 12 + regime×united 6 + regime×workers 3 = 39 对）
    regime  = @('georgy_malenkow','nikita_khrushchyov','kliment_voroshilov')
}

# 营 × 营 全交叉互斥
$crossRules = @(
    # --- 当前生效 ---
    @('left','right'),          # R2 理论完全对立（6×4 = 24 对）
    @('workers','left'),        # R1 工会大辩论（1×6 = 6 对）
    # --- 2026-09-16 起生效（体制营 3 人已入 $roster）---
    @('regime','left'), @('regime','right'), @('regime','united'), @('regime','workers')
)
# 单对互斥
$pairRules = @(
    # --- 当前生效（两人都在 $roster 里）---
    @('lev_trotsky','grigory_zinovyev'), @('lev_trotsky','lev_kamenev'),   # R1 三人团 1923-24 / 1927 破裂
    @('grigory_zinovyev','lev_kamenev'),                                   # R3 同派同职能
    # --- R1 历史交恶（两人都在 $roster 里，2026-09-16 起生效）---
    #     🚩🚩 这一条【必须同时出现在 $pairRules（生成互斥）和 $r1Pairs（分类）】里。
    #          只放 $r1Pairs 的话断言会报「R1 = 0」但不报错 —— 互斥就静默没了。
    @('mikhail_tukhachevsky','kliment_voroshilov'),                        # R1 军事路线 + 1937-06 审判血债
    # --- R1 历史交恶 · 2026-09-20 用户裁决新增（口径：「血债做互斥」）---
    #     🚩🚩 这一对是【加害关系】，与前面那条对等的「交恶」不同：
    #          马林科夫 1949-02-21 亲自带 MGB 武装队伍赴列宁格勒、主持「列宁格勒案件」，
    #          枪决名单第一人就是池内的沃兹涅先斯基（Idx 18，本 mod 已实装的第 18 条线）。
    #          两人分属 regime / neutral，营×营【无规则】→ 不单列的话游戏里能同席。
    #     ⚠️ 它同时解释了「为什么体制营 3 人的回池判据要单独核」（docs/10 §2.4.2.2.1 已订正备注）
    @('georgy_malenkow','nikolay_voznesensky'),                            # R1 1949 列宁格勒案件
    # --- 已声明、待扩员生效（反方还不在 $roster 里）---
    @('genrikh_yagoda','nikolay_yezhov'), @('genrikh_yagoda','lavrenty_beriya'), @('genrikh_yagoda','vsevolod_merkulov'),  # R3 安全机构
    @('nikolay_yezhov','lavrenty_beriya'), @('nikolay_yezhov','vsevolod_merkulov'), @('lavrenty_beriya','vsevolod_merkulov')  #   同一把椅子
)

# ---- R1（历史交恶）单独登记：这类互斥与「营」无关，是个人恩怨，跳营生效 ----
#   🚩🚩 中立营的定义是「不因【理论】而与任何营互斥」，不是「一个敌人也没有」。
#        中立×体制的图哈切夫斯基↔沃罗希洛夫 = 1937-06 审判血债，属 R1。
#        ⭐ 2026-09-20 追加第二例，方向相反：体制×中立 马林科夫↔沃兹涅先斯基 = 1949 列宁格勒案件。
#        §11 ③ 据此只统计 R2/R3，不统计 R1。
#   🚩🚩 凡是在 $pairRules 里【新增一条 R1】，就必须同步加到这里 ——
#        只放 $pairRules 不加 $r1Keys → §11 ③「中立营不因理论互斥」这一项会 FAIL
#        （因为沃兹涅先斯基是中立营，那条互斥会被误算成「理论互斥」）。
$r1Pairs = @(
    @('lev_trotsky','grigory_zinovyev'), @('lev_trotsky','lev_kamenev'),
    @('mikhail_tukhachevsky','kliment_voroshilov'),
    @('georgy_malenkow','nikolay_voznesensky')      # R1 1949 列宁格勒案件（2026-09-20 用户裁决）
)
$r1Keys = @($r1Pairs | ForEach-Object { (@($_[0], $_[1]) | Sort-Object) -join '|' })

$rosterKeys = @($roster | ForEach-Object { $_.Key })
$inRoster   = @{}
foreach ($k in $rosterKeys) { $inRoster[$k] = $true }

$exclOf = @{}
foreach ($k in $rosterKeys) { $exclOf[$k] = New-Object System.Collections.Generic.HashSet[string] }

$addRival = {
    param([string]$a, [string]$b)
    if ($a -eq $b)        { return }
    if (-not $inRoster[$a]) { return }
    if (-not $inRoster[$b]) { return }
    $null = $exclOf[$a].Add($b)
    $null = $exclOf[$b].Add($a)
}

foreach ($rule in $crossRules) {
    foreach ($a in $camps[$rule[0]]) {
        foreach ($b in $camps[$rule[1]]) { & $addRival $a $b }
    }
}
foreach ($p in $pairRules) { & $addRival $p[0] $p[1] }

Write-Output '======== 0b. 席位互斥展开（docs/10 §2.4.2）========'
foreach ($c in $roster) {
    $rivals = @($exclOf[$c.Key] | Sort-Object)
    Write-Output ("  {0,-22} 排掉 {1,2} 人：{2}" -f $c.Key, $rivals.Count, ($rivals -join ', '))
}
$exclPairCount = ($roster | ForEach-Object { $exclOf[$_.Key].Count } | Measure-Object -Sum).Sum / 2
Write-Output ("  在册 {0} 人，展开出 {1} 对互斥" -f $roster.Count, $exclPairCount)

Write-Output '======== 0. 校验花名册素材 ========'

foreach ($c in $roster) {

    $newHit = $null
    if ($c.NewArt) {
        $p = Join-Path $modRoot ($c.NewArt -replace '/', '\')
        if (Test-Path $p) { $newHit = $p }
    }

    if ($newHit) {
        $c.Texture  = $c.NewArt
        $c.ArtState = '新美术'
    }
    elseif (-not $c.Dds) {
        throw "序号 $($c.Idx)（$($c.Zh)）既没自绘立绘也没写原版 Dds 路径"
    }
    else {
        $hit = $null
        foreach ($root in $assetRoots) {
            $p = Join-Path $root ($c.Dds -replace '/', '\')
            if (Test-Path $p) { $hit = $root; break }
        }
        if (-not $hit) { throw "序号 $($c.Idx)（$($c.Zh)）的贴图三处都找不到：$($c.Dds)" }
        $c.Texture  = $c.Dds
        $c.ArtState = $c.Note
    }

    $texFull = $null
    foreach ($root in $assetRoots) {
        $p = Join-Path $root ($c.Texture -replace '/', '\')
        if (Test-Path $p) { $texFull = $p; break }
    }
    $c.Size = if ($texFull) { Get-DdsSize $texFull } else { '?' }
    $c.SizeWarn = ($c.Size -ne '156x210')

    $flag = if ($c.SizeWarn) { 'WARN' } else { 'OK  ' }
    Write-Output ("  [{0}] {1} {2,-22} {3,-10} {4}" -f $flag, $c.Idx, $c.Key, $c.Size, $c.Texture)
}

$sizeWarned = @($roster | Where-Object { $_.SizeWarn })
if ($sizeWarned.Count -gt 0) {
    Write-Output ''
    Write-Output "  ⚠ 有 $($sizeWarned.Count) 人的立绘不是 156x210（席位槽设计尺寸）："
    foreach ($c in $sizeWarned) { Write-Output "      $($c.Zh)  $($c.Size)" }
    Write-Output '    这几位在席位里会显得模糊（长宽比接近，不会变形）。'
}

# =============================================================================
Write-Output ''
Write-Output '======== 1. 动态民族精神（容器）======='

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 动态民族精神容器（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 机制蓝本：原版 common/dynamic_modifiers/wuw_dynamic_modifiers.txt 的')
$null = $sb.AppendLine('#           GER_the_inner_circle_dm')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# ⚠️ 它【故意不写 modifier = { }】。它的作用是当一个「容器 + 展示位」：')
$null = $sb.AppendLine('#    真正加数值的是每个人自己的 idea（见 hof_ic_ideas.txt）。')
$null = $sb.AppendLine('#    它的 tooltip 由脚本本地化渲染成"当前在任者名单"。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine("$dmId = {")
$null = $sb.AppendLine("`ticon = $dmIcon")
$null = $sb.AppendLine('`tenable = { always = yes }')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`t# 政体变了就自动摘掉（照德国 remove_trigger 的做法）')
$null = $sb.AppendLine('`tremove_trigger = {')
$null = $sb.AppendLine('`t`tNOT = { has_government = communism }')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`t# 这个键在 hof_ic_l_simp_chinese.yml 里手写，内容引用 [hof_ic_slot_N_name]')
$null = $sb.AppendLine('`tcustom_modifier_tooltip = hof_ic_dm_tt')
$null = $sb.AppendLine('}')
Write-ModFile 'common/dynamic_modifiers/hof_ic_dynamic_modifiers.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 2. 人物职务 idea（hidden_ideas）======='

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 人物职务 idea（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 🚨 外层必须是 ideas = { <category> = { ... } }，不能把 idea 块直接写在文件根级。')
$null = $sb.AppendLine('#    走 hidden_ideas（原版 common/idea_tags/00_idea.txt）：')
$null = $sb.AppendLine('#        hidden = yes / cost = 0 / removal_cost = -1 / ledger = hidden')
$null = $sb.AppendLine('#    -> 职务【不显示成民族精神】，不占核心圈的精神格。')
$null = $sb.AppendLine('#    德国原版就是这么干的：common/ideas/GER.txt L11339 hidden_ideas。')
$null = $sb.AppendLine('#    玩家看到的“谁的官衔”由容器精神 hof_ic_supreme_soviet_dm 的')
$null = $sb.AppendLine('#    custom_modifier_tooltip（= hof_ic_dm_tt）经脚本本地化列出。')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# 模板照原版德国职务 idea：')
$null = $sb.AppendLine('#   allowed = { always = no } + removal_cost = -1  -> 只能由国策给出，不可手动移除')
$null = $sb.AppendLine('#   modifier 第一条统一是政治点获取 ' + $entryCost + '（德国角色 idea 全有）')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# ⚠️ 除"入圈代价"外的专长加成目前都是【占位值】，等核心圈数值统一定稿后改。')
$null = $sb.AppendLine('#    改哪：本生成器 $roster 里每人的 Mod 字段。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('ideas = {')
$null = $sb.AppendLine('`thidden_ideas = {')
$null = $sb.AppendLine()

foreach ($c in $roster) {
    # 有 Tiers 就逐级生成；没有就一级（入圈代价用全局值）
    if ($c.ContainsKey('Tiers') -and $c.Tiers) { $tiers = $c.Tiers }
    else { $tiers = @(@{ Id = $c.Idea; Zh = ''; Pp = $entryCost; Add = @() }) }

    $null = $sb.AppendLine("`t`t# $($c.Zh)")
    if ($tiers.Count -gt 1) { $null = $sb.AppendLine("`t`t# 职务分级 $($tiers.Count) 级：每级 = 下级全部照抄 + 追加（德国实测规律）") }
    foreach ($t in $tiers) {
        if ($t.Zh -ne '') { $null = $sb.AppendLine("`t`t#   $($t.Id)  =  $($t.Zh)") }
        $null = $sb.AppendLine("`t`t$($t.Id) = {")
        $null = $sb.AppendLine('`t`t`tallowed = { always = no }')
        $null = $sb.AppendLine('`t`t`tremoval_cost = -1')
        $null = $sb.AppendLine('`t`t`tmodifier = {')
        $null = $sb.AppendLine("`t`t`t`t# 入圈代价：官越大越吃政治点（德国 -0.1 -> -0.3）")
        $null = $sb.AppendLine("`t`t`t`tpolitical_power_gain = $($t.Pp)")
        # 官衔附加值可以升级同一个量纲；同一 idea 里只能输出一次。
        # 后者（当前等级 Add）覆盖入席基础值 Mod，避免引擎只取最后一行并报重复。
        $tierMods = [ordered]@{}
        foreach ($m in @($c.Mod) + @($t.Add)) {
            if ($m -notmatch '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$') { throw "无效官衔修正：$m" }
            $tierMods[$Matches[1]] = $Matches[2]
        }
        foreach ($key in $tierMods.Keys) {
            $null = $sb.AppendLine("`t`t`t`t$key = $($tierMods[$key])")
        }
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine('`t`t}')
    }
    $null = $sb.AppendLine()
}
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-ModFile 'common/ideas/hof_ic_ideas.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 3. 入席 / 替换脚本效果 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 席位效果（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 数据模型：hof_ic_slot_1 .. hof_ic_slot_7 = 角色序号；0 / 未赋值 = 空席')
$null = $sb.AppendLine('#           hof_ic_appointing            = 正在办理入席的人（替换流程用，用完即清）')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# ⚠️ 三个已验证的写法要点（不要改）：')
$null = $sb.AppendLine('#   1. 本文件【没有】包装层，效果直接顶层写 名称 = { }')
$null = $sb.AppendLine('#   2. 不做初始化。check_variable 对未赋值变量按 0 处理（原版德国同款）')
$null = $sb.AppendLine('#   3. scripted_effect 调用写法是 名称 = yes')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()

# --- 3.1 任命冷却 ---
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 任命冷却：设一个带 days 的国策 flag（原版 GER_inner_circle_set_ascension_cd 同款）')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('hof_ic_set_appointment_cd = {')
$null = $sb.AppendLine('`tset_country_flag = {')
$null = $sb.AppendLine('`t`tflag = hof_ic_appointment_cd')
$null = $sb.AppendLine("`t`tdays = $cdDays")
$null = $sb.AppendLine('`t`tvalue = 1')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

# --- 3.2 给"正在办理的人"加 idea ---
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 给 hof_ic_appointing 指向的那个人加上他的 idea（查表）')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('hof_ic_add_appointee_idea = {')
for ($k = 0; $k -lt $roster.Count; $k++) {
    $c = $roster[$k]
    $kw = if ($k -eq 0) { 'if' } else { 'else_if' }
    $null = $sb.AppendLine("`t$kw = {")
    $null = $sb.AppendLine("`t`tlimit = { check_variable = { hof_ic_appointing = $($c.Idx) } }")
    $null = $sb.AppendLine("`t`tadd_ideas = $($c.Idea)")
    $null = $sb.AppendLine('`t}')
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

# --- 3.3 卸掉某席位的 idea ---
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("# 卸掉第 $slot 席当前占位者的 idea")
    $null = $sb.AppendLine("hof_ic_remove_slot_${slot}_idea = {")
    for ($k = 0; $k -lt $roster.Count; $k++) {
        $c = $roster[$k]
        $kw = if ($k -eq 0) { 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t$kw = {")
        $null = $sb.AppendLine("`t`tlimit = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } }")
        # 职务分级：必须逐级试删，只删首级会残留
        foreach ($tid in $tierIdsOf[$c.Idx]) {
            $null = $sb.AppendLine('`t`tif = {')
            $null = $sb.AppendLine("`t`t`tlimit = { has_idea = $tid }")
            $null = $sb.AppendLine("`t`t`tremove_ideas = $tid")
            $null = $sb.AppendLine('`t`t}')
        }
        $null = $sb.AppendLine('`t}')
    }
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# --- 3.4 入席后启动个人线；空席和满席替换共用 ---
foreach ($c in $roster) {
    if ($c.Branch.Count -eq 0) { continue }
    $null = $sb.AppendLine("hof_ic_begin_$($c.Key)_line = {")
    if ($pathChoiceOf.ContainsKey($c.Key)) {
        $pc = $pathChoiceOf[$c.Key]
        $null = $sb.AppendLine('`tif = {')
        $null = $sb.AppendLine('`t`tlimit = {')
        $null = $sb.AppendLine("`t`t`t$($pc.Char) = {")
        foreach ($op in $pc.Opts) { $null = $sb.AppendLine("`t`t`t`tNOT = { has_character_flag = $($op.Flag) }") }
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine('`t`t}')
        $null = $sb.AppendLine("`t`tcountry_event = $evNamespace.$($pc.EvId)")
        $null = $sb.AppendLine('`t}')
    }
    $null = $sb.AppendLine("`tcountry_event = { id = $evNamespace.$($evBranchBase + $c.Idx * 10) days = $branchStartDelay random_days = $branchStartRand }")
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}
$null = $sb.AppendLine('hof_ic_begin_appointee_line = {')
foreach ($c in $roster) {
    if ($c.Branch.Count -eq 0) { continue }
    $null = $sb.AppendLine("`tif = { limit = { check_variable = { hof_ic_appointing = $($c.Idx) } } hof_ic_begin_$($c.Key)_line = yes }")
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

# --- 3.5 替换某席位 ---
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("# 把第 $slot 席的人换成 hof_ic_appointing（替换事件用）")
    $null = $sb.AppendLine("hof_ic_replace_slot_$slot = {")
    $null = $sb.AppendLine("`thof_ic_remove_slot_${slot}_idea = yes")
    $null = $sb.AppendLine("`tset_variable = { hof_ic_slot_$slot = hof_ic_appointing }")
    $null = $sb.AppendLine('`thof_ic_add_appointee_idea = yes')
    $null = $sb.AppendLine('`thof_ic_begin_appointee_line = yes')
    $null = $sb.AppendLine('`tclear_variable = hof_ic_appointing')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# --- 3.6 每人一个"入席"效果 ---
foreach ($c in $roster) {

    $hasBranch = ($c.Branch.Count -gt 0)

    $null = $sb.AppendLine("# ---------------------------------------------------------------------------")
    $null = $sb.AppendLine("# 序号 $($c.Idx) —— $($c.Zh)")
    if ($hasBranch) {
        $null = $sb.AppendLine("#   个人线 $($c.Branch.Count) 个国策，入席后由 hof_ic_$($c.Key).01 / .02 自动推进")
    } else {
        $null = $sb.AppendLine('#   个人线尚未进树（$branches 里是空的），所以这里【不】启动驱动事件')
    }
    $null = $sb.AppendLine("# ---------------------------------------------------------------------------")
    $null = $sb.AppendLine("hof_ic_appoint_$($c.Key) = {")
    $null = $sb.AppendLine("`tset_variable = { hof_ic_appointing = $($c.Idx) }")
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`tif = {')
    $null = $sb.AppendLine('`t`tlimit = { hof_ic_has_empty_seat = yes }')
    $null = $sb.AppendLine('')
    for ($slot = 1; $slot -le $seatCount; $slot++) {
        $kw = if ($slot -eq 1) { 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t`t$kw = {")
        $null = $sb.AppendLine("`t`t`tlimit = { check_variable = { hof_ic_slot_$slot = 0 } }")
        $null = $sb.AppendLine("`t`t`tset_variable = { hof_ic_slot_$slot = $($c.Idx) }")
        $null = $sb.AppendLine('`t`t}')
    }
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`t`thof_ic_add_appointee_idea = yes')
    $null = $sb.AppendLine('`t`tclear_variable = hof_ic_appointing')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('`telse = {')
    $null = $sb.AppendLine("`t`t# 七席已满 -> 走替换事件，让玩家挑一个人换掉（照德国 GER_inner_circle.01）")
    $null = $sb.AppendLine("`t`tcountry_event = $evNamespace.$evReplace")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`t# 不管坐进去还是走替换流程，都进冷却')
    $null = $sb.AppendLine('`thof_ic_set_appointment_cd = yes')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# --- 3.6 职务分级同步 effect（入席 / 升官 / 换人 / 卸任 四个场景共用）---
#     照德国 GER_add_<name>_effects / GER_remove_<name>_effects
#     （common/scripted_effects/GER_scripted_effects.txt L2857 / L3102）：
#       · 不存“他升到第几级”
#       · 先逐级试删，再用 has_completed_focus 反推重加
#     -> 不存状态，就不存在状态不对
foreach ($c in $roster) {

    $tids = $tierIdsOf[$c.Idx]
    $hasGates = ($c.ContainsKey('RankGates') -and $c.RankGates)

    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine("# $($c.Zh) —— 职务分级同步（$($tids.Count) 级）")
    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine("hof_ic_idea_$($c.Key)_sync_rank = {")
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("`t# ① 先把当前等级全部卸掉（从高到低逐级试，德国 GER_remove_*_effects 原样）")
    for ($t = $tids.Count - 1; $t -ge 0; $t--) {
        $kw = if ($t -eq $tids.Count - 1) { 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t$kw = {")
        $null = $sb.AppendLine("`t`tlimit = { has_idea = $($tids[$t]) }")
        $null = $sb.AppendLine("`t`tremove_ideas = $($tids[$t])")
        $null = $sb.AppendLine('`t}')
    }
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("`t# ② 只有在席才重新给 —— 卸任的人不该因为国策完成又冒出来")
    $null = $sb.AppendLine('`tif = {')
    $null = $sb.AppendLine("`t`tlimit = { hof_ic_seated_$($c.Key) = yes }")
    $null = $sb.AppendLine('')
    if ($hasGates) {
        $first = $true
        foreach ($g in $c.RankGates) {
            $kw = if ($first) { 'if' } else { 'else_if' }
            $first = $false
            $null = $sb.AppendLine("`t`t$kw = {")
            $null = $sb.AppendLine("`t`t`tlimit = { $($g.Gate) }")
            $null = $sb.AppendLine("`t`t`tadd_ideas = $($g.Id)")
            $null = $sb.AppendLine('`t`t}')
        }
        $null = $sb.AppendLine('`t`telse = {')
        $null = $sb.AppendLine("`t`t`tadd_ideas = $($tids[0])")
        $null = $sb.AppendLine('`t`t}')
    } else {
        $null = $sb.AppendLine("`t`tadd_ideas = $($tids[0])")
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# 德国「强大的继承者」事件按现任席位提名继任者；这里也按 7 个当前席位生成。
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("hof_ic_promote_slot_${slot}_chairman = {")
    foreach ($c in $roster) {
        $kw = if ($c.Idx -eq 1) { 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t$kw = {")
        $null = $sb.AppendLine("`t`tlimit = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } }")
        $null = $sb.AppendLine('`t`tadd_country_leader_role = {')
        $null = $sb.AppendLine("`t`t`tcharacter = SOV_$($c.Key)")
        $null = $sb.AppendLine('`t`t`tcountry_leader = {')
        $null = $sb.AppendLine('`t`t`t`tideology = marxism')
        $null = $sb.AppendLine('`t`t`t`texpire = 1965.3.1.1')
        $null = $sb.AppendLine('`t`t`t`ttraits = { hof_ic_commissar_party_discipline hof_ic_new_soviet_chairman_trait }')
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine('`t`t`tpromote_leader = yes')
        $null = $sb.AppendLine('`t`t}')
        $null = $sb.AppendLine('`t}')
    }
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

Write-ModFile 'common/scripted_effects/hof_ic_scripted_effects.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 4. 触发器 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 触发器（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# ⚠️ 本文件【没有】包装层，触发器直接顶层写 名称 = { }')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('# 还有至少一个空席 —— 入席脚本据此选"直接坐"还是"走替换事件"')
$null = $sb.AppendLine('hof_ic_has_empty_seat = {')
$null = $sb.AppendLine('`tOR = {')
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("`t`tcheck_variable = { hof_ic_slot_$slot = 0 }")
}
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('# 七席全满（compare = not_equals 是"该席已被占用"的原版惯用写法）')
$null = $sb.AppendLine('hof_ic_all_seats_full = {')
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("`tcheck_variable = { hof_ic_slot_$slot = 0 compare = not_equals }")
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 任命冷却是否结束（原版 GER_inner_circle_is_ascension_cd_over 同款）')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('hof_ic_is_appointment_cd_over = {')
$null = $sb.AppendLine('`tNOT = {')
$null = $sb.AppendLine('`t`thas_country_flag = {')
$null = $sb.AppendLine('`t`t`tflag = hof_ic_appointment_cd')
$null = $sb.AppendLine("`t`t`tdays < $cdDays")
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 角色是否已经在席（防止同一人重复入席；也用作个人线驱动器的存活判定）')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine()

foreach ($c in $roster) {
    $null = $sb.AppendLine("# $($c.Zh)")
    $null = $sb.AppendLine("hof_ic_seated_$($c.Key) = {")
    $null = $sb.AppendLine('`tOR = {')
    for ($slot = 1; $slot -le $seatCount; $slot++) {
        $null = $sb.AppendLine("`t`tcheck_variable = { hof_ic_slot_$slot = $($c.Idx) }")
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

Write-ModFile 'common/scripted_triggers/hof_ic_scripted_triggers.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 5. 席位动态文本 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 席位动态文本（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 机制蓝本：原版 common/scripted_localisation/WUW_GER_scripted_loc.txt 的')
$null = $sb.AppendLine('#           GetAscendedAdvisorName1..3（读槽位变量 -> 出名字）')
$null = $sb.AppendLine('# 每席四个动态键：name / trait（窗口）及 dm_desc / dm_line（民族精神）')
$null = $sb.AppendLine('# 空席走兜底条目（无 trigger 的 text 总是通过，官方 54 处同款写法）')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()

for ($slot = 1; $slot -le $seatCount; $slot++) {

    foreach ($kind in @('name', 'trait')) {

        $prefix   = if ($kind -eq 'name') { 'hof_ic_name_' } else { 'hof_ic_trait_' }
        $fallback = if ($kind -eq 'name') { 'hof_ic_seat_empty_text' } else { 'hof_ic_seat_trait_empty_text' }

        $null = $sb.AppendLine('defined_text = {')
        $null = $sb.AppendLine("`tname = hof_ic_slot_${slot}_${kind}")

        foreach ($c in $roster) {
            $null = $sb.AppendLine('')
            $null = $sb.AppendLine("`ttext = {")
            $null = $sb.AppendLine("`t`ttrigger = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } }")
            $null = $sb.AppendLine("`t`tlocalization_key = $prefix$($c.Key)")
            $null = $sb.AppendLine("`t}")
        }

        $null = $sb.AppendLine('')
        $null = $sb.AppendLine("`ttext = {")
        $null = $sb.AppendLine("`t`tlocalization_key = $fallback")
        $null = $sb.AppendLine("`t}")
        $null = $sb.AppendLine('}')
        $null = $sb.AppendLine('')
    }
}

# 德国核心集团用 has_idea 取得现任官衔。额外生成每席一行提示，空席不显示。
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine('defined_text = {')
    $null = $sb.AppendLine("`tname = hof_ic_slot_${slot}_dm_desc")
    foreach ($c in $roster) {
        foreach ($tierId in $tierIdsOf[$c.Idx]) {
            $null = $sb.AppendLine('`ttext = {')
            $null = $sb.AppendLine("`t`ttrigger = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } has_idea = $tierId }")
            $null = $sb.AppendLine("`t`tlocalization_key = idea_desc|$tierId")
            $null = $sb.AppendLine('`t}')
        }
    }
    $null = $sb.AppendLine('`ttext = { localization_key = hof_ic_dm_desc_fallback }')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine('')

    $null = $sb.AppendLine('defined_text = {')
    $null = $sb.AppendLine("`tname = hof_ic_slot_${slot}_dm_line")
    foreach ($c in $roster) {
        $null = $sb.AppendLine('`ttext = {')
        $null = $sb.AppendLine("`t`ttrigger = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } }")
        $null = $sb.AppendLine("`t`tlocalization_key = hof_ic_dm_slot_${slot}_line")
        $null = $sb.AppendLine('`t}')
    }
    $null = $sb.AppendLine('`ttext = { localization_key = hof_ic_dm_empty_text }')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine('')
}

# 替换事件的 desc 里要显示"正在办理入席的是谁"
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 正在办理入席的人的名字（替换事件的 desc 用）')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('defined_text = {')
$null = $sb.AppendLine('`tname = hof_ic_appointing_name')
foreach ($c in $roster) {
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("`ttext = {")
    $null = $sb.AppendLine("`t`ttrigger = { check_variable = { hof_ic_appointing = $($c.Idx) } }")
    $null = $sb.AppendLine("`t`tlocalization_key = hof_ic_name_$($c.Key)")
    $null = $sb.AppendLine("`t}")
}
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`ttext = {')
$null = $sb.AppendLine('`t`tlocalization_key = hof_ic_seat_empty_text')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')

Write-ModFile 'common/scripted_localisation/hof_ic_scripted_loc.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 6. 事件 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 事件（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# ① 满席替换事件（蓝本：原版 events/WUW_Germany.txt 的 GER_inner_circle.01）')
$null = $sb.AppendLine('# ② 个人线驱动器：每人 .01 / .02 两个隐藏事件循环推进他的国策分支')
$null = $sb.AppendLine('#    （蓝本：GER_inner_circle_<name>.01 / .02）')
$null = $sb.AppendLine('#    ⚠️ 只有当 $roster 里那个人的 Branch 非空时才会生成')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine("add_namespace = $evNamespace")
$null = $sb.AppendLine()
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine("# 满席替换：$evReplace")
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('country_event = {')
$null = $sb.AppendLine("`tid = $evNamespace.$evReplace")
$null = $sb.AppendLine("`ttitle = $evNamespace.$evReplace.t")
$null = $sb.AppendLine("`tdesc = $evNamespace.$evReplace.desc")
$null = $sb.AppendLine('`tis_triggered_only = yes')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`timmediate = {')
$null = $sb.AppendLine('`t`thidden_effect = { set_country_flag = hof_ic_appointment_pending }')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('')

$slotLetter = @('a', 'b', 'c', 'd', 'e', 'f', 'g')
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine("`toption = {   # 替换第 $slot 席")
    $null = $sb.AppendLine("`t`tname = $evNamespace.$evReplace.$($slotLetter[$slot - 1])")
    $null = $sb.AppendLine('`t`tai_chance = {')
    $null = $sb.AppendLine('`t`t`tbase = 1')
    $null = $sb.AppendLine('`t`t}')
    $null = $sb.AppendLine("`t`thof_ic_replace_slot_$slot = yes")
    $null = $sb.AppendLine('`t`thidden_effect = { clr_country_flag = hof_ic_appointment_pending }')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('')
}
$null = $sb.AppendLine('}')

# --- 个人线驱动器 ---
$branchChars = @($roster | Where-Object { $_.Branch.Count -gt 0 })
# 终局二选一事件数（只有 Branch 非空的人才生成）—— 供 §11 自检用
$choiceEvCount = @($branchChars | Where-Object { $endingChoiceOf.ContainsKey($_.Key) }).Count
# 岔路二选一事件数（2026-09-16 加）—— 同样只有 Branch 非空的人才生成
$pathEvCount   = @($branchChars | Where-Object { $pathChoiceOf.ContainsKey($_.Key) }).Count
foreach ($c in $branchChars) {

    $evA = $evBranchBase + $c.Idx * 10
    $evB = $evA + 1

    # ---- 推进：找第一个未完成的国策，点亮它，预约完成事件 ----
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine("# $($c.Zh) 的个人线驱动器：开下一个国策")
    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine('country_event = {')
    $null = $sb.AppendLine("`tid = $evNamespace.$evA")
    $null = $sb.AppendLine('`thidden = yes')
    $null = $sb.AppendLine('`tis_triggered_only = yes')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`ttrigger = {')
    $null = $sb.AppendLine("`t`thof_ic_seated_$($c.Key) = yes")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`timmediate = {')
    $first = $true
    # ---- 终局（汇合层）：驱动器照【角色标记】推进被选中的那一个 ----
    #   标记由二选一事件里的选项打上（照德国 GER_inner_circle_himmler.00）；
    #   没打过标记就什么也不做 —— 方向由玩家在事件里定。
    if ($endingChoiceOf.ContainsKey($c.Key)) {
        foreach ($ce in $endingChoiceOf[$c.Key].Ends) {
            $kw = if ($first) { $first = $false; 'if' } else { 'else_if' }
            $null = $sb.AppendLine("`t`t$kw = {   # 终局：$($ce.Name)")
            $null = $sb.AppendLine('`t`t`tlimit = {')
            $null = $sb.AppendLine("`t`t`t`t$($endingChoiceOf[$c.Key].Char) = { has_character_flag = $($ce.Flag) }")
            $null = $sb.AppendLine("`t`t`t`tNOT = { has_completed_focus = $($ce.Focus) }")
            $null = $sb.AppendLine('`t`t`t}')
            $null = $sb.AppendLine("`t`t`tactivate_shine_on_focus = $($ce.Focus)")
            $null = $sb.AppendLine('`t`t`tset_country_flag = {')
            $null = $sb.AppendLine("`t`t`t`tflag = hof_ic_$($c.Key)_progress")
            $null = $sb.AppendLine("`t`t`t`tdays = $branchTierDays")
            $null = $sb.AppendLine('`t`t`t`tvalue = 1')
            $null = $sb.AppendLine('`t`t`t}')
            $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evB days = $branchTierDays }")
            $null = $sb.AppendLine('`t`t}')
        }
    }
    for ($k = 0; $k -lt $c.Branch.Count; $k++) {
        $fid = $c.Branch[$k]

        # ---- 岔路（在这一条【之前】插入）----
        #   未定方向 → 弹二选一事件 + 重排自己，【绝不往前推】（否则会跳过岔路去点下游）
        #   定过方向 → 只点亮被选中的那一条
        if ($pathChoiceOf.ContainsKey($c.Key) -and $pathChoiceOf[$c.Key].At -eq $fid) {
            $pc = $pathChoiceOf[$c.Key]
            $kw = if ($first) { $first = $false; 'if' } else { 'else_if' }
            $null = $sb.AppendLine("`t`t$kw = {   # 岔路未定：弹【$($pc.Title)】并原地等待")
            $null = $sb.AppendLine('`t`t`tlimit = {')
            $null = $sb.AppendLine("`t`t`t`t$($pc.Char) = {")
            foreach ($op in $pc.Opts) { $null = $sb.AppendLine("`t`t`t`t`tNOT = { has_character_flag = $($op.Flag) }") }
            $null = $sb.AppendLine('`t`t`t`t}')
            $null = $sb.AppendLine('`t`t`t}')
            $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$($pc.EvId) days = 1 }")
            $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evA days = 5 random_days = 3 }")
            $null = $sb.AppendLine('`t`t}')
            foreach ($op in $pc.Opts) {
                $null = $sb.AppendLine("`t`telse_if = {   # 岔路已选：$($op.Name)")
                $null = $sb.AppendLine('`t`t`tlimit = {')
                $null = $sb.AppendLine("`t`t`t`t$($pc.Char) = { has_character_flag = $($op.Flag) }")
                $null = $sb.AppendLine("`t`t`t`tNOT = { has_completed_focus = $($op.Focus) }")
                $null = $sb.AppendLine('`t`t`t}')
                $null = $sb.AppendLine("`t`t`tactivate_shine_on_focus = $($op.Focus)")
                $null = $sb.AppendLine('`t`t`tset_country_flag = {')
                $null = $sb.AppendLine("`t`t`t`tflag = hof_ic_$($c.Key)_progress")
                $null = $sb.AppendLine("`t`t`t`tdays = $branchTierDays")
                $null = $sb.AppendLine('`t`t`t`tvalue = 1')
                $null = $sb.AppendLine('`t`t`t}')
                $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evB days = $branchTierDays }")
                $null = $sb.AppendLine('`t`t}')
            }
        }

        $kw = if ($first) { $first = $false; 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t`t$kw = {   # $fid")
        # 🚩 有的国策要额外卡一道岔路标记 —— 否则 complete_national_focus 会【绕过互斥】继续强推，
        #    树上会留下「A1 是空的、A2 却已完成」的断链。
        if ($branchGate.ContainsKey($fid)) {
            $g = $branchGate[$fid]
            $null = $sb.AppendLine('`t`t`tlimit = {')
            $null = $sb.AppendLine("`t`t`t`t$($g.Char) = { has_character_flag = $($g.Flag) }")
            $null = $sb.AppendLine("`t`t`t`tNOT = { has_completed_focus = $fid }")
            $null = $sb.AppendLine('`t`t`t}')
        } else {
            $null = $sb.AppendLine("`t`t`tlimit = { NOT = { has_completed_focus = $fid } }")
        }
        $null = $sb.AppendLine("`t`t`tactivate_shine_on_focus = $fid")
        $null = $sb.AppendLine('`t`t`tset_country_flag = {')
        $null = $sb.AppendLine("`t`t`t`tflag = hof_ic_$($c.Key)_progress")
        $null = $sb.AppendLine("`t`t`t`tdays = $branchTierDays")
        $null = $sb.AppendLine('`t`t`t`tvalue = 1')
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evB days = $branchTierDays }")
        $null = $sb.AppendLine('`t`t}')
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')

    # ---- 完成：到点了，把点亮的那个国策完成，再预约下一个 ----
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine("# $($c.Zh) 的个人线驱动器：完成已点亮的国策")
    $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
    $null = $sb.AppendLine('country_event = {')
    $null = $sb.AppendLine("`tid = $evNamespace.$evB")
    $null = $sb.AppendLine('`thidden = yes')
    $null = $sb.AppendLine('`tis_triggered_only = yes')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`ttrigger = {')
    $null = $sb.AppendLine("`t`thof_ic_seated_$($c.Key) = yes")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine('`timmediate = {')
    $first = $true
    for ($k = 0; $k -lt $c.Branch.Count; $k++) {
        $fid = $c.Branch[$k]

        # ---- 岔路：被选中的那一条也要能「完成」（它不在 $Branch 里，所以单独出分支）----
        if ($pathChoiceOf.ContainsKey($c.Key) -and $pathChoiceOf[$c.Key].At -eq $fid) {
            $pc = $pathChoiceOf[$c.Key]
            foreach ($op in $pc.Opts) {
                $kw = if ($first) { $first = $false; 'if' } else { 'else_if' }
                $null = $sb.AppendLine("`t`t$kw = {   # 岔路选中：$($op.Name)")
                $null = $sb.AppendLine("`t`t`tlimit = { has_shine_effect_on_focus = $($op.Focus) $($pc.Char) = { has_character_flag = $($op.Flag) } }")
                $null = $sb.AppendLine("`t`t`tcomplete_national_focus = { focus = $($op.Focus) }")
                $null = $sb.AppendLine("`t`t`tclr_country_flag = hof_ic_$($c.Key)_progress")
                $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evA days = $branchGapDays random_days = $branchGapRand }")
                $null = $sb.AppendLine('`t`t}')
            }
        }

        $kw = if ($first) { $first = $false; 'if' } else { 'else_if' }
        $null = $sb.AppendLine("`t`t$kw = {")
        $null = $sb.AppendLine("`t`t`tlimit = { has_shine_effect_on_focus = $fid }")
        $null = $sb.AppendLine("`t`t`tcomplete_national_focus = { focus = $fid }")
        $null = $sb.AppendLine("`t`t`tclr_country_flag = hof_ic_$($c.Key)_progress")
        $null = $sb.AppendLine("`t`t`t# 下一条：【国策之间】的间隔（比首次启动短，见 $branchGapDays 的注释）")
        $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$evA days = $branchGapDays random_days = $branchGapRand }")
        $null = $sb.AppendLine('`t`t}')
    }
    # ---- 终局（汇合层）：驱动器照【角色标记】推进被选中的那一个 ----
    #   ⚠️ 必须排在 `else` 兜底【之前】—— 一个 if 链里 else 之后不能再有 else_if。
    if ($endingChoiceOf.ContainsKey($c.Key)) {
        foreach ($ce in $endingChoiceOf[$c.Key].Ends) {
            $null = $sb.AppendLine("`t`telse_if = {   # 终局：$($ce.Name)")
            $null = $sb.AppendLine("`t`t`tlimit = { has_shine_effect_on_focus = $($ce.Focus) $($endingChoiceOf[$c.Key].Char) = { has_character_flag = $($ce.Flag) } }")
            $null = $sb.AppendLine("`t`t`tcomplete_national_focus = { focus = $($ce.Focus) }")
            $null = $sb.AppendLine("`t`t`tclr_country_flag = hof_ic_$($c.Key)_progress")
            # 终局在走通部分支线时即可完成；其余支线仍须继续推进。
            # 盖标记避免旧档周检与正常预约同时排队。
            $null = $sb.AppendLine("`t`t`tset_country_flag = hof_ic_$($c.Key)_post_ending_resume_v1")
            $null = $sb.AppendLine('`t`t`tif = {')
            $null = $sb.AppendLine('`t`t`t`tlimit = { NOT = { AND = {')
            foreach ($bf in $c.Branch) { $null = $sb.AppendLine("`t`t`t`t`thas_completed_focus = $bf") }
            $null = $sb.AppendLine('`t`t`t`t} } }')
            $null = $sb.AppendLine("`t`t`t`tcountry_event = { id = $evNamespace.$evA days = $branchGapDays random_days = $branchGapRand }")
            $null = $sb.AppendLine('`t`t`t}')
            $null = $sb.AppendLine('`t`t}')
        }
    }
    # 🚩 兜底：闪光的那条被玩家【手动点掉】了（或状态丢了）-> 只要还有没走完的就重新挑一个，
    #    否则链条会永远停在那里。加一层「并非全部已完成」保护，避免全走完后无限重预约。
    $null = $sb.AppendLine('`t`telse = {')
    $null = $sb.AppendLine('`t`t`tif = {')
    $null = $sb.AppendLine('`t`t`t`tlimit = {')
    $null = $sb.AppendLine('`t`t`t`t`tNOT = {')
    $null = $sb.AppendLine('`t`t`t`t`t`tAND = {')
    foreach ($bf in $c.Branch) { $null = $sb.AppendLine("`t`t`t`t`t`t`thas_completed_focus = $bf") }
    $null = $sb.AppendLine('`t`t`t`t`t`t}')
    $null = $sb.AppendLine('`t`t`t`t`t}')
    # 🚩 岔路选了「自断这条线」的方向（如布哈林的左翼共产主义）→ 剩下的国策永远不可能完成，
    #    兜底重排必须停手，否则会每 3~6 天无限重排空转。
    if ($pathChoiceOf.ContainsKey($c.Key)) {
        foreach ($tf in $pathChoiceOf[$c.Key].Term) {
            $null = $sb.AppendLine('`t`t`t`t`tNOT = {')
            $null = $sb.AppendLine("`t`t`t`t`t`t$($pathChoiceOf[$c.Key].Char) = { has_character_flag = $tf }")
            $null = $sb.AppendLine('`t`t`t`t`t}')
        }
    }
    $null = $sb.AppendLine('`t`t`t`t}')
    $null = $sb.AppendLine("`t`t`t`tcountry_event = { id = $evNamespace.$evA days = $branchGapDays random_days = $branchGapRand }")
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    # ---- 抉择：支线走通 N 条、方向还没定 -> 弹二选一事件 ----
    # 触发时机 = 每推完一条国策之后 → 第 3 条支线走通那一刻正好弹出（原本的设计）。
    # 照德国：门控写在这里，不写进国策的 available（available 只负责显示）。
    # fire_only_once 已保证不会重复弹。
    if ($endingChoiceOf.ContainsKey($c.Key)) {
        $ch = $endingChoiceOf[$c.Key]
        $null = $sb.AppendLine('`t`t# ---- 抉择：还没定过方向、且支线已走通 N 条 -> 弹二选一事件 ----')
        $null = $sb.AppendLine('`t`tif = {')
        $null = $sb.AppendLine('`t`t`tlimit = {')
        $null = $sb.AppendLine('`t`t`t`tNOT = {')
        $null = $sb.AppendLine('`t`t`t`t`tOR = {')
        foreach ($ce in $ch.Ends) { $null = $sb.AppendLine("`t`t`t`t`t`thas_completed_focus = $($ce.Focus)") }
        $null = $sb.AppendLine('`t`t`t`t`t}')
        $null = $sb.AppendLine('`t`t`t`t}')
        $null = $sb.AppendLine('`t`t`t`tcount_triggers = {')
        $null = $sb.AppendLine("`t`t`t`t`tamount = $($ch.Amount)")
        foreach ($g2 in $ch.Gates) { $null = $sb.AppendLine("`t`t`t`t`thas_completed_focus = $g2") }
        $null = $sb.AppendLine('`t`t`t`t}')
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine("`t`t`tcountry_event = { id = $evNamespace.$($ch.EvId) days = 1 }")
        $null = $sb.AppendLine('`t`t}')
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')

    # ---- 终局二选一事件本体（蓝本：GER_inner_circle_himmler.00）----
    # 选项只做两件事：给角色打标记 + 把驱动器踢起来。走哪个方向由驱动器读标记后执行。
    if ($endingChoiceOf.ContainsKey($c.Key)) {
        $ch = $endingChoiceOf[$c.Key]
        $letters = @('a', 'b', 'c', 'd')
        $null = $sb.AppendLine()
        $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
        $null = $sb.AppendLine("# $($c.Zh) 的终局二选一：支线走通 $($ch.Amount) 条后弹出（蓝本 GER_inner_circle_himmler.00）")
        $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
        $null = $sb.AppendLine('country_event = {')
        $null = $sb.AppendLine("`tid = $evNamespace.$($ch.EvId)")
        $null = $sb.AppendLine("`ttitle = $evNamespace.$($ch.EvId).t")
        $null = $sb.AppendLine("`tdesc = $evNamespace.$($ch.EvId).desc")
        $null = $sb.AppendLine('`tis_triggered_only = yes')
        $null = $sb.AppendLine('`tfire_only_once = yes')
        $null = $sb.AppendLine('')
        $null = $sb.AppendLine('`timmediate = {')
        $null = $sb.AppendLine("`t`thidden_effect = { set_country_flag = hof_ic_$($c.Key)_choice_pending }")
        $null = $sb.AppendLine('`t}')
        for ($oi = 0; $oi -lt $ch.Ends.Count; $oi++) {
            $ce = $ch.Ends[$oi]
            $null = $sb.AppendLine('')
            $null = $sb.AppendLine("`toption = {   # $($ce.Name)")
            $null = $sb.AppendLine("`t`tname = $evNamespace.$($ch.EvId).$($letters[$oi])")
            $null = $sb.AppendLine('`t`tai_chance = {')
            $null = $sb.AppendLine('`t`t`tbase = 10')
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t`tcustom_effect_tooltip = {')
            $null = $sb.AppendLine('`t`t`tlocalization_key = hof_ic_ending_choice_tt')
            $null = $sb.AppendLine("`t`t`tCHARACTER = $($ch.Char)")
            $null = $sb.AppendLine("`t`t`tFOCUS = $($ce.Focus)")
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t`thidden_effect = {')
            $null = $sb.AppendLine("`t`t`t$($ch.Char) = { set_character_flag = $($ce.Flag) }")
            # 完成上一节点的 .02 已预约 .01；重复预约会让终局国策同时跑两轮。
            $null = $sb.AppendLine("`t`t`tclr_country_flag = hof_ic_$($c.Key)_choice_pending")
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t}')
        }
        $null = $sb.AppendLine('}')
    }

    # ---- 岔路二选一事件本体（结构同终局，蓝本 GER_inner_circle_himmler.00）----
    #   选项同样只做两件事：给角色打标记 + 把驱动器踢起来。点哪条由驱动器读标记后执行。
    if ($pathChoiceOf.ContainsKey($c.Key)) {
        $pc = $pathChoiceOf[$c.Key]
        $letters = @('a', 'b', 'c', 'd')
        $null = $sb.AppendLine()
        $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
        $null = $sb.AppendLine("# $($c.Zh) 的岔路二选一：$($pc.Title)（蓝本 GER_inner_circle_himmler.00）")
        $null = $sb.AppendLine('# ---------------------------------------------------------------------------')
        $null = $sb.AppendLine('country_event = {')
        $null = $sb.AppendLine("`tid = $evNamespace.$($pc.EvId)")
        $null = $sb.AppendLine("`ttitle = $evNamespace.$($pc.EvId).t")
        $null = $sb.AppendLine("`tdesc = $evNamespace.$($pc.EvId).desc")
        $null = $sb.AppendLine('`tis_triggered_only = yes')
        $null = $sb.AppendLine('`tfire_only_once = yes')
        $null = $sb.AppendLine('')
        $null = $sb.AppendLine('`timmediate = {')
        $null = $sb.AppendLine("`t`thidden_effect = { set_country_flag = hof_ic_$($c.Key)_choice_pending }")
        $null = $sb.AppendLine('`t}')
        for ($oi = 0; $oi -lt $pc.Opts.Count; $oi++) {
            $op = $pc.Opts[$oi]
            $null = $sb.AppendLine('')
            $null = $sb.AppendLine("`toption = {   # $($op.Name)")
            $null = $sb.AppendLine("`t`tname = $evNamespace.$($pc.EvId).$($letters[$oi])")
            $null = $sb.AppendLine('`t`tai_chance = {')
            $null = $sb.AppendLine('`t`t`tbase = 10')
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t`tcustom_effect_tooltip = {')
            $null = $sb.AppendLine('`t`t`tlocalization_key = hof_ic_ending_choice_tt')
            $null = $sb.AppendLine("`t`t`tCHARACTER = $($pc.Char)")
            $null = $sb.AppendLine("`t`t`tFOCUS = $($op.Focus)")
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t`thidden_effect = {')
            $null = $sb.AppendLine("`t`t`t$($pc.Char) = { set_character_flag = $($op.Flag) }")
            # 入席时已预约首次驱动；旧档兜底由等待岔路的驱动器重排自己。
            # 这里再预约会出现两份 .01，造成同一国策被重复点亮和重复完成。
            $null = $sb.AppendLine("`t`t`tclr_country_flag = hof_ic_$($c.Key)_choice_pending")
            $null = $sb.AppendLine('`t`t}')
            $null = $sb.AppendLine('`t}')
        }
        $null = $sb.AppendLine('}')
    }
}

# 全联盟终局：从现任七席中推举新主席。七个选项的角色由席位变量决定。
$null = $sb.AppendLine('country_event = {')
$null = $sb.AppendLine('`tid = heartofiron.1400')
$null = $sb.AppendLine('`ttitle = heartofiron.1400.t')
$null = $sb.AppendLine('`tdesc = heartofiron.1400.desc')
$null = $sb.AppendLine('`tis_triggered_only = yes')
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine('`toption = {')
    $null = $sb.AppendLine("`t`tname = heartofiron.1400.slot_$slot")
    $null = $sb.AppendLine("`t`thof_ic_promote_slot_${slot}_chairman = yes")
    $null = $sb.AppendLine('`t}')
}
$null = $sb.AppendLine('}')

Write-ModFile 'events/hof_ic_events.txt' $sb.ToString()

# 旧档中终局已完成但驱动器已停止：周检只补排一次未完成的其余支线。
# 新版本在终局完成事件中立即盖同一标记，避免重复排队。
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Resume unfinished inner-circle branches after an early ending in existing saves.')
$null = $sb.AppendLine('on_actions = {')
$null = $sb.AppendLine('`ton_weekly = {')
$null = $sb.AppendLine('`t`teffect = {')
$null = $sb.AppendLine('`t`t`tif = {')
$null = $sb.AppendLine('`t`t`t`tlimit = { tag = SOV }')
foreach ($c in $branchChars) {
    if (-not $endingChoiceOf.ContainsKey($c.Key)) { continue }
    $evA = $evBranchBase + $c.Idx * 10
    $null = $sb.AppendLine('`t`t`t`tif = {')
    $null = $sb.AppendLine('`t`t`t`t`tlimit = {')
    $null = $sb.AppendLine("`t`t`t`t`t`thof_ic_seated_$($c.Key) = yes")
    $null = $sb.AppendLine("`t`t`t`t`t`tNOT = { has_country_flag = hof_ic_$($c.Key)_post_ending_resume_v1 }")
    $null = $sb.AppendLine("`t`t`t`t`t`tNOT = { has_country_flag = hof_ic_$($c.Key)_progress }")
    $null = $sb.AppendLine('`t`t`t`t`t`tOR = {')
    foreach ($ce in $endingChoiceOf[$c.Key].Ends) { $null = $sb.AppendLine("`t`t`t`t`t`t`thas_completed_focus = $($ce.Focus)") }
    $null = $sb.AppendLine('`t`t`t`t`t`t}')
    $null = $sb.AppendLine('`t`t`t`t`t`tNOT = { AND = {')
    foreach ($bf in $c.Branch) { $null = $sb.AppendLine("`t`t`t`t`t`t`thas_completed_focus = $bf") }
    $null = $sb.AppendLine('`t`t`t`t`t`t} }')
    $null = $sb.AppendLine('`t`t`t`t`t}')
    $null = $sb.AppendLine("`t`t`t`t`tset_country_flag = hof_ic_$($c.Key)_post_ending_resume_v1")
    $null = $sb.AppendLine("`t`t`t`t`tcountry_event = { id = $evNamespace.$evA days = 1 }")
    $null = $sb.AppendLine('`t`t`t`t}')
}
$null = $sb.AppendLine('`t`t`t}')
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-ModFile 'common/on_actions/hof_ic_branch_resume_on_actions.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 7. 席位立绘 sprite 注册 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 席位立绘 sprite（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# 单独成文件，是为了让手写的 interface/hof_ic.gfx 保持不动。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('spriteTypes = {')
$null = $sb.AppendLine()

foreach ($c in $roster) {
    $null = $sb.AppendLine("`t# $($c.Zh)  [$($c.ArtState)]")
    $null = $sb.AppendLine('`tspriteType = {')
    $null = $sb.AppendLine("`t`tname = `"GFX_hof_ic_portrait_$($c.Key)`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$($c.Texture)`"")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine()
}

foreach ($c in $roster) {
    $null = $sb.AppendLine("`t# $($c.Zh) —— 底部候选栏小头像")
    $null = $sb.AppendLine('`tspriteType = {')
    $null = $sb.AppendLine("`t`tname = `"GFX_hof_ic_cand_$($c.Key)`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$($c.Texture)`"")
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine()
}

$null = $sb.AppendLine('}')
Write-ModFile 'interface/hof_ic_portraits.gfx' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 7b. 自建角色对象（原版/R56 没给的人）========'

# 🚩 为什么要这一段：
#   国策 tooltip 用 `custom_effect_tooltip = { localization_key = K  CHARACTER = <角色 id> }`
#   时，CHARACTER 必须是【真实角色 id】—— 官方文档 documentation/loc_objects_documentation.md
#   把 Character 列为一种 loc scope；给一个不存在的 id 是什么都不显示。
#   7 个席位里 6 人的角色对象原版/R56 已有（common/characters/SOV.txt），
#   只有谢列布里亚科夫没有（R56 只留了一段被注释掉的 create_country_leader 草稿
#   + 一张没人用的立绘）→ 花名册里标 OwnChar 的人在这里补。
# ⚠️ 原版 SOV 的 118 个角色【没有一个是没有职责的】→ 必须至少挂一个 role。
#    给他挂 political_advisor，并用我们自己的入席触发器卡住 visible/available
#    → 入席前他在顾问列表里根本不出现，零副作用。

# 原版/R56 已有的角色（= SOV_ + key）。⚠️ 新人物落地时如果这里没有他、
# 又没标 OwnChar，下面的自检会 FAIL —— 这是故意的，逼你做个决定。
$vanillaChars = @('lev_trotsky', 'nikolay_bukharin', 'aleksey_rykov',
                  'grigory_zinovyev', 'lev_kamenev', 'ivan_smirnov',
                  # ---- 候选池其余 15 人（2026-09-16 入池）：全部在 docs/10 §2.2.1 已核实有角色块 ----
                  'yevgeny_preobrazhensky', 'karl_radek', 'ivar_smilga',
                  'mikhail_tomsky', 'martemyan_ryutin', 'aleksandr_shlyapnikov',
                  'mikhail_kalinin', 'maksim_litvinov', 'grigory_sokolnikov',
                  'mikhail_tukhachevsky', 'nikolay_voznesensky', 'pyotr_smirnov',
                  'georgy_malenkow', 'nikita_khrushchyov', 'kliment_voroshilov')

$ownChars = @($roster | Where-Object { $_.ContainsKey('OwnChar') -and $_.OwnChar })
$ownKeys  = @($ownChars | ForEach-Object { $_.Key })
$noChar   = @($roster | Where-Object { $vanillaChars -notcontains $_.Key -and $ownKeys -notcontains $_.Key })
if ($noChar.Count -gt 0) {
    $names = ($noChar | ForEach-Object { $_.Key }) -join ', '
    throw "这些人既不在原版角色名单里、也没标 OwnChar，CHARACTER = SOV_<key> 会渲染不出来：$names"
}

if ($ownChars.Count -eq 0) {
    Write-Output '  （不需要自建：花名册里的人原版/R56 都有角色对象）'
} else {

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 自建角色对象（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 只放【原版/R56 没有】的人。角色 id 一律 SOV_ + 花名册 Key，')
$null = $sb.AppendLine('# 与另外 6 人保持一致（这样生成器里 CHARACTER = SOV_<key> 人人通用）。')
$null = $sb.AppendLine('# 蓝本：原版 common/characters/SOV.txt 的 SOV_nikolay_bukharin 块。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('characters = {')
$null = $sb.AppendLine()
foreach ($c in $ownChars) {
    $null = $sb.AppendLine("`t# ---- $($c.Zh)（原版/R56 查无此角色，由我们补）----")
    $null = $sb.AppendLine("`tSOV_$($c.Key) = {")
    $null = $sb.AppendLine("`t`tname = SOV_$($c.Key)")
    $null = $sb.AppendLine('`t`tportraits = {')
    $null = $sb.AppendLine('`t`t`tcivilian = {')
    # 用【我们自己注册的 sprite】（见 §7）；sprite 名不加引号也是合法写法（原版两种都有）
    $null = $sb.AppendLine("`t`t`t`tlarge = GFX_hof_ic_portrait_$($c.Key)")
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t`tarmy = {')
    $null = $sb.AppendLine("`t`t`t`tsmall = GFX_hof_ic_portrait_$($c.Key)")
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('`t`tadvisor = {')
    $null = $sb.AppendLine('`t`t`tslot = political_advisor')
    $null = $sb.AppendLine("`t`t`tidea_token = SOV_$($c.Key)")
    $null = $sb.AppendLine('`t`t`tallowed = {')
    $null = $sb.AppendLine('`t`t`t`toriginal_tag = SOV')
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t`t# 只有坐进最高苏维埃之后才会出现在顾问列表里')
    $null = $sb.AppendLine('`t`t`tvisible = {')
    $null = $sb.AppendLine("`t`t`t`thof_ic_seated_$($c.Key) = yes")
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t`tavailable = {')
    $null = $sb.AppendLine("`t`t`t`thof_ic_seated_$($c.Key) = yes")
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t`ttraits = { }')
    $null = $sb.AppendLine('`t`t`tai_will_do = {')
    $null = $sb.AppendLine('`t`t`t`tbase = 1')
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine()
}
$null = $sb.AppendLine('}')
Write-ModFile 'common/characters/hof_ic_characters.txt' $sb.ToString()
Write-Output ("  [OK ] 自建 {0} 个角色：{1}" -f $ownChars.Count, (($ownChars | ForEach-Object { "SOV_$($_.Key)" }) -join ', '))
}
Write-Output ("  [OK ] 7 个席位的角色对象齐了：原版/R56 现成 {0} 人 + 自建 {1} 人" -f $vanillaChars.Count, $ownChars.Count)

# =============================================================================
Write-Output ''
Write-Output '======== 7c. 领袖特质升级（照德国 GER_der_fuhrer_fuhrerprinzip）========'

# 机制蓝本：原版 common/national_focus/germany.txt 的 GER_fuhrerprinzip ——
#   完成时用 swap_country_leader_traits 把领袖的原有特质升级成一个「追加版」
#   （GER_der_fuhrer -> GER_der_fuhrer_fuhrerprinzip）。
#   德国的做法很干净：【照抄原特质全部效果】+ 【升级其中一项】+ 【新增一项】：
#     political_power_factor   0.1  -> 0.25   （工具提示里显示为「政治点数 +15%」）
#     新增 party_popularity_stability_factor = 0.1（「党派支持度对稳定度修正 +10.00%」）
#
# 我们的领袖：SOV_the_supreme_soviet 用 add_country_leader_role 拉出角色
#   SOV_supreme_soviet（ideology = marxism，traits = strong_party_discipline）。
#   strong_party_discipline = 「党纪严明」（原版 common/country_leader/00_traits.txt L7700）：
#     drift_defence_factor 0.15 / compliance_gain 0.05 / resistance_decay 0.1 /
#     stability_factor 0.1 / surrender_limit 0.1
#   → 升级版照抄这 5 条，再追加与德国同量的两条。
#
# ⚠️ 格式依据：原版 common/country_leader/00_traits.txt 的 leader_traits = { <id> = { ... } }

$commissarTraitId = 'hof_ic_commissar_party_discipline'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 领袖特质升级（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 机制蓝本：原版 common/national_focus/germany.txt 的 GER_fuhrerprinzip')
$null = $sb.AppendLine('#   GER_der_fuhrer  ->  GER_der_fuhrer_fuhrerprinzip')
$null = $sb.AppendLine('# 德国的手法：【照抄原特质全部效果】+【升级一项】+【新增一项】。')
$null = $sb.AppendLine('# 我们：strong_party_discipline（党纪严明）-> 本文件里的 hof_ic_commissar_party_discipline')
$null = $sb.AppendLine('# 升级点 = 中间国策 hof_ic_commissar（人民委员）的 completion_reward。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('leader_traits = {')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 入党严明（升级版）—— 原版 strong_party_discipline 的全部效果照抄，再追加两条')
$null = $sb.AppendLine("`t$commissarTraitId = {")
$null = $sb.AppendLine('`t`trandom = no')
$null = $sb.AppendLine('`t`t# ---- 照抄原版 strong_party_discipline（党纪严明）----')
$null = $sb.AppendLine('`t`tdrift_defence_factor = 0.15')
$null = $sb.AppendLine('`t`tcompliance_gain = 0.05')
$null = $sb.AppendLine('`t`tresistance_decay = 0.1')
$null = $sb.AppendLine('`t`tstability_factor = 0.1')
$null = $sb.AppendLine('`t`tsurrender_limit = 0.1')
$null = $sb.AppendLine('`t`t# ---- 人民委员带来的追加（数值照德国 GER_der_fuhrer_fuhrerprinzip 的增量）----')
$null = $sb.AppendLine('`t`tpolitical_power_factor = 0.15')
$null = $sb.AppendLine('`t`tparty_popularity_stability_factor = 0.1')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`t# 两条全联盟终局国策的领袖特质')
$null = $sb.AppendLine('`thof_ic_new_soviet_chairman_trait = {')
$null = $sb.AppendLine('`t`trandom = no')
$null = $sb.AppendLine('`t`tpolitical_power_factor = 0.10')
$null = $sb.AppendLine('`t`tstability_factor = 0.05')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('`thof_ic_united_supreme_soviet_trait = {')
$null = $sb.AppendLine('`t`trandom = no')
$null = $sb.AppendLine('`t`tmax_command_power_mult = 0.25')
$null = $sb.AppendLine('`t`tjustify_war_goal_time = -0.20')
$null = $sb.AppendLine('`t`tnon_core_manpower = 0.15')
$null = $sb.AppendLine('`t`tconscription = 0.05')
$null = $sb.AppendLine('`t`toffensive_war_stability_factor = 0.15')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-ModFile 'common/country_leader/hof_ic_leader_traits.txt' $sb.ToString()
Write-Output ("  [OK ] $commissarTraitId（党纪严明升级版：原 5 条 + 追加 2 条）")

# =============================================================================
Write-Output ''
Write-Output '======== 8. inlay window 定义 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 inlay window（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 语法依据：原版 common/focus_inlay_windows/documentation.md')
$null = $sb.AppendLine('# 结构蓝本：原版 ger_inner_circle_inlay_window.txt（纯展示，无 scripted_buttons）')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# ⚠️ scripted_images 的键必须与 interface/hof_ic_scripted_gui.gui 里')
$null = $sb.AppendLine('#    对应 iconType 的 name 完全一致，写错则静默不生效。')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('hof_ic_inlay_window = {')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`twindow_name = hof_ic_ui_window')
$null = $sb.AppendLine('`tinternal = yes')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t# 可见条件：完成「最高苏维埃」国策后出现（容器精神也在那时挂上）')
$null = $sb.AppendLine('`tvisible = {')
$null = $sb.AppendLine('`t`thas_completed_focus = hof_ic_commissar')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`tscripted_images = {')
$null = $sb.AppendLine()
$null = $sb.AppendLine('`t`t# ---------------- 领袖位 ----------------')
$null = $sb.AppendLine('`t`thof_ic_leader_portrait = {')
$null = $sb.AppendLine('`t`t`tGFX_portrait_SOV_supreme_soviet = yes')
$null = $sb.AppendLine('`t`t}')

for ($slot = 1; $slot -le $seatCount; $slot++) {

    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("`t`t# ---------------- 席位 $slot ----------------")

    $null = $sb.AppendLine("`t`thof_ic_seat_${slot}_frame = {")
    $null = $sb.AppendLine("`t`t`tGFX_hof_ic_seat_frame_empty = { check_variable = { hof_ic_slot_$slot = 0 } }")
    $null = $sb.AppendLine("`t`t`tGFX_hof_ic_seat_frame_filled = yes")
    $null = $sb.AppendLine('`t`t}')

    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("`t`thof_ic_seat_${slot}_portrait = {")
    foreach ($c in $roster) {
        $null = $sb.AppendLine("`t`t`tGFX_hof_ic_portrait_$($c.Key) = { check_variable = { hof_ic_slot_$slot = $($c.Idx) } }")
    }
    $null = $sb.AppendLine('`t`t`tGFX_hof_ic_blank_portrait = yes')
    $null = $sb.AppendLine('`t`t}')
}

$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-ModFile 'common/focus_inlay_windows/hof_ic_inlay_window.txt' $sb.ToString()

# =============================================================================
Write-Output ''
Write-Output '======== 9. 本地化键 ========'

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('l_simp_chinese:')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # 核心圈 · 花名册与事件文案（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sb.AppendLine(' # 窗口框架的键（标题/领袖名等）手写在 hof_ic_l_simp_chinese.yml，本脚本不碰它。')
$null = $sb.AppendLine('')

foreach ($c in $roster) {
    $null = $sb.AppendLine(" hof_ic_name_$($c.Key):0 `"$($c.Zh)`"")
}
$null = $sb.AppendLine('')
$null = $sb.AppendLine(' # ⚠️ 待办：以下头衔目前统一为占位文本，尚未按史料逐人区分')
foreach ($c in $roster) {
    $null = $sb.AppendLine(" hof_ic_trait_$($c.Key):0 `"最高苏维埃委员`"")
}
$null = $sb.AppendLine('')

$null = $sb.AppendLine(' # 职务 idea 的名称；说明由 idea_desc|<id> 实时读取数值（照德国）')
# 🚩 踩过：有【职务分级表 Tiers】的人，其 idea 名由 §10c 按当前等级输出
#    （照德国：「idea 名 = 官衔」，人名在核心圈窗口里用 scripted loc 显示）
#    → 这里必须跳过那个【名字】键，否则同一个键写两遍（后写的赢）
#    且 HOI4 会记一条重复键错误。不要给 idea 写统一占位 _desc，
#    否则容器的 idea_desc|<id> 会显示那段占位文案。
$tierIdeaIds = @()
foreach ($c in $roster) {
    if ($c.ContainsKey('Tiers') -and $c.Tiers) { foreach ($t in $c.Tiers) { $tierIdeaIds += $t.Id } }
}
foreach ($c in $roster) {
    if (-not ($tierIdeaIds -contains $c.Idea)) {
        $null = $sb.AppendLine(" $($c.Idea):0 `"$($c.Zh)`"")
    }
}
$null = $sb.AppendLine('')

$null = $sb.AppendLine(' # 入口国策名与说明')
foreach ($c in $roster) {
    $null = $sb.AppendLine(" hof_ic_seat_$($c.Key):0 `"$($c.Zh)进入最高苏维埃`"")
}
$null = $sb.AppendLine('')
foreach ($c in $roster) {
    # 描述逐人写（照德国 GER_ascension_of_<人>_desc）—— 不再用「让 X 获得席位。席位共七个…」那种模板句
    $null = $sb.AppendLine(" hof_ic_seat_$($c.Key)_desc:0 `"$($c.SeatDesc)`"")
}
$null = $sb.AppendLine('')

$null = $sb.AppendLine(' # 满席替换事件')
$null = $sb.AppendLine(" $evNamespace.$evReplace.t:0 `"最高苏维埃改选`"")
$null = $sb.AppendLine(" $evNamespace.$evReplace.desc:0 `"七席已满。要让[hof_ic_appointing_name]进入最高苏维埃，必须有人让出他的席位。`"")
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb.AppendLine(" $evNamespace.$evReplace.$($slotLetter[$slot - 1]):0 `"由第 $slot 席（[hof_ic_slot_$slot`_name]）让位`"")
}
$null = $sb.AppendLine('')

$full = Join-Path $modRoot 'localisation/simp_chinese/hof_ic_roster_l_simp_chinese.yml'
$dir  = Split-Path -Parent $full
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($full, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
$bom = (Get-Content -LiteralPath $full -Encoding Byte -TotalCount 3) -join ','
Write-Output ("  写出 {0,-58} {1,8:N0} 字节  {2}" -f 'localisation/simp_chinese/hof_ic_roster_l_simp_chinese.yml', (Get-Item -LiteralPath $full).Length, $(if ($bom -eq '239,187,191') { '有BOM(正确)' } else { '无BOM(错误!)' }))

# =============================================================================
Write-Output ''
Write-Output '======== 10. 入口国策注入行 + hub 挂载行 ========'

$sb = New-Object System.Text.StringBuilder
# 入口 x 不在这里写死 —— 由 §10z 的【区块避让】统一算（方法见 docs/23 §2.7）：
#   每个人算一下自己区块（他的整条个人线）多宽，从入口往两侧铺，撞了就让开。
# 🚩 为什么要先放占位符：区块宽度要靠 $trotLine / $bukhLine 里的 X 才算得出来，
#    而那两张表在本段【之后】才定义（PowerShell 顺序执行），现在算不出来。
$null = $sb.AppendLine('# ---- 核心圈入口国策：7 名候选人各一个，完成即办理入席 ----')
$null = $sb.AppendLine('# 由 build/gen-hof-ic-s3.ps1 生成，勿手改。')
$null = $sb.AppendLine('# 前置：已完成「最高苏维埃」(SOV_the_supreme_soviet)')
$null = $sb.AppendLine('# available：任命冷却已过，且本人不在席（满席不再挡路，改由替换事件处理）')
$null = $sb.AppendLine('# 效果：调用 hof_ic_appoint_<key>，内部决定"直接坐"或"走替换事件"')
$null = $sb.AppendLine('# ⚠️ available 末尾的 NOT 块 = 席位互斥，由 docs/10 §2.4.2 的三条规则展开而来。')
$null = $sb.AppendLine('#    不要手改；要改改生成器顶部的 $camps / $crossRules / $pairRules。')
$null = $sb.AppendLine()

for ($k = 0; $k -lt $roster.Count; $k++) {

    $c = $roster[$k]

    $null = $sb.AppendLine('focus = {')
    $null = $sb.AppendLine("`tid = hof_ic_seat_$($c.Key)")
    # 专属美术：art/focus/ 交付，由 build/gen-hof-ic-focus-icons.ps1 注册为 sprite
    # （sprite 名 = 国策 id，1:1 对齐；每个图标另有一张 `<name>_shine`，缺了会显示占位图）
    $null = $sb.AppendLine("`ticon = GFX_hof_ic_seat_$($c.Key)")
    # ★ 2026-09-16（用户定）：入口不再直接挂【原版】枢纽，改挂【我们自己的】
    #   中间国策「人民委员」（见 §10y）。
    #   好处：整块核心圈的位置改由 hof_ic_commissar 一个点决定 ——
    #   入口行变宽后要整体下移/左右挪，只改那一处，不再受原版国策牵制。
    $null = $sb.AppendLine("`tprerequisite = { focus = hof_ic_commissar }")
    $null = $sb.AppendLine("`trelative_position_id = hof_ic_commissar")
    $null = $sb.AppendLine("`tx = @@HOF_IC_X_$($c.Key)@@")
    # y 相对「人民委员」（y=1 = 紧接在它下面一行）
    $null = $sb.AppendLine("`ty = 1")
    $null = $sb.AppendLine("`tcost = 2")
    $null = $sb.AppendLine("`tavailable = {")
    # 🚩🚩 照德国：available 里的【脚本触发器】必须包一层 custom_trigger_tooltip，
    #      否则玩家在「需要」列表里看到的是 hof_ic_is_appointment_cd_over 这种原始脚本名，
    #      互斥那几行更会变成一串 hof_ic_seated_xxx（实拍确认过）。
    #      德国 GER_inner_circle_cd_days_tt 用的是 custom_trigger_tooltip，同款写法。
    $null = $sb.AppendLine("`t`tcustom_trigger_tooltip = {")
    $null = $sb.AppendLine("`t`t`ttooltip = hof_ic_appointment_cd_tt")
    $null = $sb.AppendLine("`t`t`thof_ic_is_appointment_cd_over = yes")
    $null = $sb.AppendLine("`t`t}")
    $null = $sb.AppendLine("`t`tcustom_trigger_tooltip = {")
    $null = $sb.AppendLine("`t`t`ttooltip = hof_ic_not_seated_$($c.Key)_tt")
    $null = $sb.AppendLine("`t`t`tNOT = { hof_ic_seated_$($c.Key) = yes }")
    $null = $sb.AppendLine("`t`t}")
    # ---- 席位互斥（docs/10 §2.4.2）----
    foreach ($rival in ($exclOf[$c.Key] | Sort-Object)) {
        $null = $sb.AppendLine("`t`tcustom_trigger_tooltip = {")
        $null = $sb.AppendLine("`t`t`ttooltip = hof_ic_not_seated_${rival}_tt")
        $null = $sb.AppendLine("`t`t`tNOT = { hof_ic_seated_$rival = yes }")
        $null = $sb.AppendLine("`t`t}")
    }
    $null = $sb.AppendLine("`t}")
    $null = $sb.AppendLine("`tcompletion_reward = {")
    # 🚩 逐字照德国 GER_ascension_of_* 的写法（germany.txt L19671 起，共四段）：
    #    ① 抬头：「§Y某人§!被任命为§Y职务§!，并在§Y机构§!中晋升为：」
    #    ② show_ideas_tooltip = <职务 idea>（引擎摊开官衔名 + 它的全部数值）
    #    ③ 空行（德国用 generic_skip_one_line_tt，值就是 " \n"）
    #    ④ 「某人将开始随着时间的推移处理他分支中的国策。」
    #    ⚠️ 德国【没有】「七个席位之一…」那种自撰说明 —— 那条只在【满席、要走替换】时
    #       出现，而且德国用的是一句「获得事件《X的崛起》：A 可以取代 B、C 或 D。」
    #       → 我们也改成同样的条件显示（见下面那个 if）。
    $null = $sb.AppendLine("`t`tcustom_effect_tooltip = {")
    $null = $sb.AppendLine("`t`t`tlocalization_key = hof_ic_seat_ascension_tt")
    $null = $sb.AppendLine("`t`t`tCHARACTER = SOV_$($c.Key)")
    $null = $sb.AppendLine("`t`t}")
    $null = $sb.AppendLine("`t`tshow_ideas_tooltip = $($c.Idea)")
    $null = $sb.AppendLine("`t`tcustom_effect_tooltip = hof_ic_skip_line_tt")
    # ★ 照德国 GER_ascension_of_character_focus_tt
    #   ⚠️ 只给【真有条个人线】的人加 —— 没线的人写了就是假承诺。
    if ($c.Branch.Count -gt 0) {
        $null = $sb.AppendLine("`t`tcustom_effect_tooltip = {")
        $null = $sb.AppendLine("`t`t`tlocalization_key = hof_ic_ascension_focus_tt")
        $null = $sb.AppendLine("`t`t`tCHARACTER = SOV_$($c.Key)")
        $null = $sb.AppendLine("`t`t}")
        if ($pathChoiceOf.ContainsKey($c.Key)) {
            $null = $sb.AppendLine("`t`tcustom_effect_tooltip = {")
            $null = $sb.AppendLine("`t`t`tlocalization_key = hof_ic_path_event_tt")
            $null = $sb.AppendLine("`t`t`tEVENT = $evNamespace.$($pathChoiceOf[$c.Key].EvId).t")
            $null = $sb.AppendLine("`t`t}")
        }
        if ($endingChoiceOf.ContainsKey($c.Key)) {
            $null = $sb.AppendLine("`t`tcustom_effect_tooltip = {")
            $null = $sb.AppendLine("`t`t`tlocalization_key = hof_ic_ending_event_$($c.Key)_tt")
            $null = $sb.AppendLine("`t`t`tEVENT = $evNamespace.$($endingChoiceOf[$c.Key].EvId).t")
            $null = $sb.AppendLine("`t`t}")
        }
    }
    # ★ 只在【满席】时才提示要走替换流程 —— 照德国 GER_event_to_replace_ascended_advisor_tt
    #   （德国也把这句放在「已满，需要替换某人」的那个分支里，而不是无条件显示）
    $null = $sb.AppendLine("`t`tif = {")
    $null = $sb.AppendLine("`t`t`tlimit = { hof_ic_all_seats_full = yes }")
    $null = $sb.AppendLine("`t`t`tcustom_effect_tooltip = {")
    $null = $sb.AppendLine("`t`t`t`tlocalization_key = hof_ic_seat_note_tt")
    $null = $sb.AppendLine("`t`t`t`tCHARACTER = SOV_$($c.Key)")
    $null = $sb.AppendLine("`t`t`t}")
    $null = $sb.AppendLine("`t`t}")
    $null = $sb.AppendLine("`t`thof_ic_appoint_$($c.Key) = yes")
    if ($c.Branch.Count -gt 0) {
        $null = $sb.AppendLine("`t`thidden_effect = { if = { limit = { hof_ic_seated_$($c.Key) = yes } hof_ic_begin_$($c.Key)_line = yes } }")
    }
    $null = $sb.AppendLine("`t}")
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# =============================================================================
# ★ 托洛茨基个人线：17 条国策（5 支线 + 2 互斥汇合）—— docs/22 §4 / §8.2.4
# -----------------------------------------------------------------------------
# 坐标【相对入口国策 hof_ic_seat_lev_trotsky】（入口绝对 x = 59，y = 15）
#   -> x = -10 就等于 docs/22 §4 里的绝对 x = 49；x = +8 就是 x = 67
#   Y 从 1 起 = 绝对 y 16；汇合 Y = 4 = 绝对 y 19
#   间距照【实测的原版惯例】：分支间距 **2 格**（R56 germany 里 2 格出现 209 次，
#   3 格只 35 次），前置边以 dx=0/±1,dy=1（纵向）+ dx=±2,dy=0（横向）为主。
#   实测数据：reference/reports/focus-spacing.txt
#
#   P    前置。['__entry__'] = 挂在入口国策上；
#        ['A','B'] 同一块 = OR；[['A'],['B']] 多块 = AND（V2 用这个做跨支线钩子）
#   V    数值贡献："<modifier>|<变量后缀>|<增量>"
#        全部 add_to_variable 进 hof_ic_lev_trotsky_dm（个人数值容器）
#   Raw  额外一次性效果（原文，逐行写进 completion_reward）
#   Sync 完成时调一遍 sync_rank → 官衔分级重算
#   Mut  互斥
# =============================================================================

$trotPrefix = 'hof_ic_lev_trotsky'
$trotDmId   = 'hof_ic_lev_trotsky_dm'
# 🚩 累积数值的【归属抬头】键（照德国）——
#    德国的追加数值前面总有一行说明这堆数字属于谁：
#      · 国策换 idea 时，抬头 = idea 名（如「菲利普·霍尔茨曼追加效果：」）
#      · 手写 tooltip 时，抬头 = GER_wunderwaffe_dornberger_trait_tt 的
#        「§Y$人名$§! (...):  ... Effective change:」那一段
#    我们不换 idea，所以用 custom_effect_tooltip 自己写一行。
#    ⚠️ 不写这行的后果（实拍比对过）：玩家只看到「效果:」底下一串「标签: +X%」，
#    分不清这是国策本身的奖励还是「他身上那件东西变强了」，也看不出会累积。
$trotExtraHeaderTt = 'hof_ic_trotsky_extra_effects_tt'

# 官衔升级目标反查：RankGates 的 Gate 写法是 'has_completed_focus = <国策 id>'，
# 从中反查出【完成这个国策会把官衔升到哪一级】——
# 用途：升官衔国策的 tooltip 里用 effect_tooltip + swap_ideas 写出「以 X 取代 Y」
#（照德国 GER_ascended_character_trait_swap_tt + swap_ideas 的效果）
# 🚩🚩 踩过：这一段原来【写死了 $roster[0]】—— 布哈林加官衔链之后，
#    他的升级国策 tooltip 会摊不出目标官衔（RankUp 是空表）。
#    → 改成【每人一份】，键 = 花名册 Idx。凡「按人一份」的键都不许写死。
# 🚩🚩 2026-09-16 又一次改法（李可夫上树才暴露）：
#    旧启发式是「非最低门槛的 From 一律 = 最低门槛」，那只在【星形】链上成立
#    （托洛茨基 2 → 3a/3b、布哈林 1→2→3）。李可夫是【四级直线链】
#    （1→2→3→4，三个门槛分别是 2、3、4），旧逻辑会把 T4 的 From 算成 T2，
#    升级 tooltip 就会写出「以 劳动与国防委员会主席 取代 最高国民经济委员会主席」
#    （跳了一级）—— 玩家看不到中间的人民委员会主席。
#    → 改为按 Tiers 上的 【Lv】 反查上一级（并列级共享同一个 Lv）。
$rankUpOf = @{}
foreach ($c in $roster) {
    $map = @{}
    if ($c.ContainsKey('RankGates') -and $c.RankGates) {
        $tiers = @($c.Tiers)
        foreach ($g in @($c.RankGates)) {
            $lv = $null
            foreach ($t in $tiers) { if ($t.Id -eq $g.Id -and $t.ContainsKey('Lv')) { $lv = [int]$t.Lv } }
            if ($null -eq $lv -or $lv -le 1) { continue }   # Lv 1 = 入席即有，没有「从哪升上来」
            $from = $null
            foreach ($t in $tiers) {
                if ($t.ContainsKey('Lv') -and [int]$t.Lv -eq ($lv - 1)) { $from = $t.Id }
            }
            if (-not $from) { continue }
            if ($g.Gate -match 'has_completed_focus\s*=\s*(\S+)') {
                # From = 升上来之前的那一级；To = 升上去的那一级
                $map[$Matches[1]] = @{ From = $from; To = $g.Id }
            }
        }
    }
    $rankUpOf[$c.Idx] = $map
}

$trotLine = @(

    # ---------------- 支线 I · 红军缔造（x = -10）----------------
    @{ Id = 'hof_ic_trotsky_build_the_red_army'; X = -8; Y = 1; P = @('__entry__');
       V = @('army_org_factor|_army_org|0.05',
             'training_time_factor|_training_time|-0.05') }

    @{ Id = 'hof_ic_trotsky_military_specialists'; X = -8; Y = 2; P = @('hof_ic_trotsky_build_the_red_army');
       V = @('experience_gain_army_factor|_experience_gain_army|0.05',
             'land_doctrine_cost_factor|_land_doctrine_cost|-0.05',
             'modifier_army_sub_unit_infantry_attack_factor|_infantry_attack|0.05',
             'modifier_army_sub_unit_cavalry_attack_factor|_cavalry_attack|0.05');
       # 唯一会真的动到人身上的国策：点名两名沙俄总参谋部上校（docs/22 §8.2.5）
       Raw = @(
           'if = {',
           '`tlimit = { has_character = SOV_boris_shaposhnikov }',
           '`tSOV_boris_shaposhnikov = {',
           '`t`tadd_skill_level = 1',
           '`t`tadd_logistics = 1',
           '`t}',
           '}',
           'if = {',
           '`tlimit = { has_character = SOV_august_kork }',
           '`tSOV_august_kork = {',
           '`t`tadd_skill_level = 1',
           '`t`tadd_attack = 1',
           '`t}',
           '}'
       ) }

    @{ Id = 'hof_ic_trotsky_against_partisan_warfare'; X = -8; Y = 3; P = @('hof_ic_trotsky_military_specialists');
       Sync = $true;
       V = @('army_attack_factor|_army_attack|0.05',
             'supply_consumption_factor|_supply|-0.05',
             'attrition|_attrition|-0.05') }

    # ---------------- 支线 II · 理论根干（x = -6）----------------
    @{ Id = 'hof_ic_trotsky_uneven_and_combined_development'; X = -6; Y = 1; P = @('__entry__');
       # 《俄国革命史》第一章着重写落后俄国吸收先进工业技术、越过手工业和工场阶段。
       V = @('production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_trotsky_permanent_revolution'; X = -6; Y = 2; P = @('hof_ic_trotsky_uneven_and_combined_development');
       V = @('communism_drift|_communism_drift|0.02',
             'drift_defence_factor|_drift_defence|0.10',
             'no_supply_grace|_no_supply_grace|72') }

    @{ Id = 'hof_ic_trotsky_socialism_in_one_country'; X = -6; Y = 3; P = @('hof_ic_trotsky_permanent_revolution');
       V = @('send_volunteer_factor|_send_volunteer|0.25',
             'opinion_gain_monthly_same_ideology_factor|_opinion_same_ideology|0.25') }

    # ---------------- 支线 III · 党内民主（x = -2）----------------
    @{ Id = 'hof_ic_trotsky_the_new_course'; X = -4; Y = 1; P = @('__entry__');
       V = @('political_power_factor|_political_power|0.05') }

    @{ Id = 'hof_ic_trotsky_against_the_bureaucracy'; X = -4; Y = 2; P = @('hof_ic_trotsky_the_new_course');
       V = @('stability_factor|_stability|0.05',
             'political_advisor_cost_factor|_political_advisor_cost|-0.10') }

    # ---------------- 支线 IV · 经济（x = +2 / +4，汇流 +3）----------------
    # 🚩 2026-09-16 用户口径：「有限市场化的词条需要再加一到两个，不然它实际上没有比劳动军强力」。
    #    原稿只有 1 条（consumer_goods −0.05），而劳动军是 2 正 1 负 —— 历史上被证明正确的
    #    那条反而更弱，与本树「用机制承担历史评价」的意图相反。补齐到 3 条：
    #      consumer_goods_factor                       负  消费品需求下降（市场供应恢复）
    #      stability_factor                            正  物资与就业改善 → 社会秩序回稳
    #      production_speed_industrial_complex_factor  正  松开集中制 → 民用工业重建加快
    #    2026-09-25 用户追加：有限市场化增加工厂产出 +5%，与劳动军的同词条位于互斥两侧。
    #    ⚠️ 民用工厂建造速度与本线其它国策不重复：IV3 / IV4 用的是 production_speed_buildings。
    #    ⚠️ 两个新词条的官方 tooltip 键都已实测存在（stability_factor_tt /
    #       production_speed_industrial_complex_factor_tt），不用自造本地化。
    @{ Id = 'hof_ic_trotsky_limited_market_reforms'; X = -2; Y = 1; P = @('__entry__');
       Mut = 'hof_ic_trotsky_labour_armies';
       V = @('consumer_goods_factor|_consumer_goods|-0.05',
             'stability_factor|_stability|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_trotsky_labour_armies'; X = 0; Y = 1; P = @('__entry__');
       Mut = 'hof_ic_trotsky_limited_market_reforms';
       # 史实判定 ❌ 不能算贡献（1921 十大被否，他自己放弃）-> 唯一的真负面
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'war_support_factor|_war_support|0.05',
             'stability_factor|_stability|-0.05') }

    @{ Id = 'hof_ic_trotsky_state_planning'; X = -1; Y = 2;
       # 同一块内多个 = OR：哪一次尝试失败都行
       P = @('hof_ic_trotsky_limited_market_reforms', 'hof_ic_trotsky_labour_armies');
       V = @('production_speed_buildings_factor|_production_speed_buildings|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05',
             'line_change_production_efficiency_factor|_line_change_efficiency|-0.05') }

    @{ Id = 'hof_ic_trotsky_accelerated_industrialization'; X = -1; Y = 3; P = @('hof_ic_trotsky_state_planning');
       V = @('production_speed_buildings_factor|_production_speed_buildings|0.10',
             'production_factory_max_efficiency_factor|_factory_max_efficiency|0.05',
             'production_factory_efficiency_gain_factor|_factory_efficiency_gain|0.05') }

    # ---------------- 支线 V · 国际（x = +8）----------------
    @{ Id = 'hof_ic_trotsky_the_comintern_manifesto'; X = 2; Y = 1; P = @('__entry__');
       V = @('communism_drift|_communism_drift|0.02',
             'opinion_gain_monthly_factor|_opinion_monthly|0.25',
             'opinion_gain_monthly_same_ideology_factor|_opinion_same_ideology|0.25',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.15') }

    @{ Id = 'hof_ic_trotsky_the_chinese_question'; X = 2; Y = 2;
       # 两块 = AND：V1 且 III2 —— 这是全树唯一的跨支线钩子（docs/22 §4）
       P = @(@('hof_ic_trotsky_the_comintern_manifesto'), @('hof_ic_trotsky_against_the_bureaucracy'));
       V = @('send_volunteer_factor|_send_volunteer|0.25',
             'supply_consumption_factor|_supply|-0.05',
             'opinion_gain_monthly_factor|_opinion_monthly|0.25');
       Raw = @('PRC = { add_opinion_modifier = { modifier = hof_ic_chinese_question target = ROOT } }') }

    @{ Id = 'hof_ic_trotsky_united_front'; X = 2; Y = 3; P = @('hof_ic_trotsky_the_chinese_question');
       V = @('drift_defence_factor|_drift_defence|0.15',
             'opinion_gain_monthly_factor|_opinion_monthly|0.25',
             'subversive_activites_upkeep|_subversive_upkeep|-0.10') }

    # ---------------- 汇合层（互斥，Y = 4 = 绝对 y 19）----------------
    @{ Id = 'hof_ic_trotsky_the_permanent_revolutionary'; X = -4; Y = 4; Sync = $true;
       P = @('hof_ic_trotsky_against_partisan_warfare', 'hof_ic_trotsky_socialism_in_one_country',
             'hof_ic_trotsky_against_the_bureaucracy', 'hof_ic_trotsky_accelerated_industrialization',
             'hof_ic_trotsky_united_front');
       Mut = 'hof_ic_trotsky_the_builder_of_the_state';
       V = @('communism_drift|_communism_drift|0.05',
             'send_volunteer_factor|_send_volunteer|0.50',
             'operative_slot|_operative_slot|1',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.25',
             'army_attack_factor|_army_attack|0.05',
             'breakthrough_factor|_breakthrough|0.05',
             'army_org_factor|_army_org|0.05',
             'combat_width_factor|_combat_width|-0.25',
             'army_armor_attack_factor|_armor_attack|0.10') }

    @{ Id = 'hof_ic_trotsky_the_builder_of_the_state'; X = -1; Y = 4; Sync = $true;
       P = @('hof_ic_trotsky_against_partisan_warfare', 'hof_ic_trotsky_socialism_in_one_country',
             'hof_ic_trotsky_against_the_bureaucracy', 'hof_ic_trotsky_accelerated_industrialization',
             'hof_ic_trotsky_united_front');
       Mut = 'hof_ic_trotsky_the_permanent_revolutionary';
       V = @('industrial_capacity_factory|_industrial_capacity|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.10',
             'production_factory_max_efficiency_factor|_factory_max_efficiency|0.10',
             'production_factory_efficiency_gain_factor|_factory_efficiency_gain|0.05',
             'army_defence_factor|_army_defence|0.10',
             'army_core_defence_factor|_army_core_defence|0.05',
             'max_dig_in_factor|_max_dig_in|0.10',
             'local_resources_factor|_local_resources|0.10',
             'global_building_slots_factor|_building_slots|0.10') }
)

if ($trotLine.Count -ne 17) { throw "托洛茨基个人线应当是 17 条，实际 $($trotLine.Count) 条" }

# =============================================================================
# ★ 布哈林个人线：9 条国策（2 支线 + 1 互斥项 + 1 单结局）—— docs/26 §4 / §7.3
#   坐标（相对入口 hof_ic_seat_nikolay_bukharin）：X1 dx=-2 / A dx=0 / B dx=+2
#   🚩 列距用 **2 格** —— 2026-09-16 用户指出原稿的 1 格太挤（图标会被压在一起）。
#      实测惯例也是 2 格（原版/R56 里 2 格 209 次、3 格只 35 次）
#   E1 前置 = A3 且 B4（**两块并列 = AND**，写法见 E1 的 P）
#   区块宽度 = 5 列（-2..+2）—— 入口坐标由 §10z 的【区块避让】自动算，不用手改
# =============================================================================
$bukhPrefix = 'hof_ic_nikolay_bukharin'
$bukhDmId   = 'hof_ic_nikolay_bukharin_dm'
# 累积数值的归属抬头（同托洛茨基，见 $trotExtraHeaderTt 的注释）
$bukhExtraHeaderTt = 'hof_ic_bukharin_extra_effects_tt'

$bukhLine = @(

    # ---------------- 支线 A · 过渡期与 NEP（x = 0）----------------
    @{ Id = 'hof_ic_bukharin_economics_of_transition'; X = 0; Y = 1; P = @('__entry__');
       Mut = 'hof_ic_bukharin_left_communism';
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_bukharin_nep_is_not_a_retreat'; X = 0; Y = 2; P = @('hof_ic_bukharin_economics_of_transition');
       V = @('consumer_goods_factor|_consumer_goods|-0.05',
             'political_power_factor|_political_power|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }

    @{ Id = 'hof_ic_bukharin_abolish_the_tribute'; X = 0; Y = 3; P = @('hof_ic_bukharin_nep_is_not_a_retreat');
       # 🚩🚩 2026-09-16 补：这里【漏了 Sync】—— 他的 RankGates 写着
       #    T2 ← abolish_the_tribute，但这一条没接线，于是
       #    hof_ic_idea_nikolay_bukharin_sync_rank 从来没被调过 → 官衔永远停在 T1。
       #    （Lv 改造时对照三人实测发现；已加 §11 断言防复发）
       Sync = $true;    # 完成时官衔升到 Lv2：联共（布）中央政治局委员
       # 全线唯一同时带正负的国策：农民支持换政治代价（docs/26 §7.3）
       V = @('stability_factor|_stability|0.10',
             'communism_drift|_communism_drift|0.02',
             'political_power_factor|_political_power|-0.05') }

    # ---------------- 支线 B · 工农关系与平衡增长（x = +1）----------------
    @{ Id = 'hof_ic_bukharin_alliance_is_the_axis'; X = 2; Y = 1; P = @('__entry__');
       V = @('stability_factor|_stability|0.05',
             'communism_drift|_communism_drift|0.02') }

    @{ Id = 'hof_ic_bukharin_enrich_yourselves'; X = 2; Y = 2; P = @('hof_ic_bukharin_alliance_is_the_axis');
       V = @('consumer_goods_factor|_consumer_goods|-0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_bukharin_proportional_development'; X = 2; Y = 3; P = @('hof_ic_bukharin_enrich_yourselves');
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_bukharin_cooperatives_into_the_system'; X = 2; Y = 4;
       P = @('hof_ic_bukharin_proportional_development');
       # 🚩 原设定叫「富农和平长入」—— 那是托派给他扣的帽子，已改名（docs/25「重大更正」节）。
       #    词条也从 communism_drift 换成 production_speed_buildings：他原话说机制是
       #    「长入到国家机关的体系中去 / 通过银行」，且明说富农合作社是「异物」不是社会主义成分。
       V = @('stability_factor|_stability|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05') }

    # ---------------- ❌ 互斥项（x = -2，与 A1 硬互斥）----------------
    @{ Id = 'hof_ic_bukharin_left_communism'; X = -2; Y = 1; P = @('__entry__');
       Mut = 'hof_ic_bukharin_economics_of_transition';
       # 明显更差：军事上强、政治上崩 —— 用机制承担历史评价（照 docs/22 的手法）
       V = @('war_support_factor|_war_support|0.10',
             'army_attack_factor|_army_attack|0.05',
             'political_power_factor|_political_power|-0.15',
             'stability_factor|_stability|-0.10') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    @{ Id = 'hof_ic_bukharin_socialism_in_one_country'; X = 0; Y = 6;
       # 🚩 两块并列 = AND（用户定：A3 与 B4 都完成）。绝不是同一块里写两个 focus！
       P = @(@('hof_ic_bukharin_abolish_the_tribute'), @('hof_ic_bukharin_cooperatives_into_the_system'));
       # 🚩🚩 2026-09-16 补：【漏了 Sync】—— RankGates 的 T3 门槛就是这一条（同上）
       Sync = $true;    # 完成时官衔升到 Lv3：共产国际执行委员会主席
       V = @('production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'stability_factor|_stability|0.10',
             'political_power_factor|_political_power|0.10',
             'consumer_goods_factor|_consumer_goods|-0.05') }
)

if ($bukhLine.Count -ne 9) { throw "布哈林个人线应当是 9 条，实际 $($bukhLine.Count) 条" }

# -----------------------------------------------------------------------------
# ★ 李可夫个人线（docs/29 §5.2 / §5.3）—— 【单线 · 4 节点 + 1 单结局】
# -----------------------------------------------------------------------------
# 形状：没有岔路、没有跨簇钩子、没有二选一事件。就一条线，按【职务年表】排序。
# 依据 docs/23 第 1b 步：他不是理论家 → 不编排他的「理论」，改用
#   【历史重要贡献事件】建线（四件事都是「从无到有做成了的」）。
#
# 🚩 描述全部是【原文节选 + 出处】（AGENTS 规则 9）：
#   ① 列宁 1918-05-26《在全俄国民经济委员会第一次代表大会上的讲话》
#   ② 托洛茨基《我的生平》第三十六章「专列」
#   ③ 托洛茨基 1921-08-07《关于新经济政策和国家计划委员会》
#   ⑤ 托洛茨基 1926-09-07《工业化的问题》
#   ④ ⚠️ 唯一一条【无一手原文】的 —— 他本人无中文文集（中文文库无李可夫页），
#      只能用【后人记述】（俄文维基百科），已在 docs/30 里标出来。
#   一手件落盘：tmp/rykov/（列宁）、tmp/trotsky/txt/（托洛茨基）
$rykovPrefix = 'hof_ic_aleksey_rykov'
$rykovDmId   = 'hof_ic_aleksey_rykov_dm'
$rykovExtraHeaderTt = 'hof_ic_rykov_extra_effects_tt'

$rykovLine = @(

    # ---------------- 单线 · 把工业与国防组织起来（x = 0）----------------
    @{ Id = 'hof_ic_rykov_supreme_economic_council'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：最高国民经济委员会主席
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10') }

    @{ Id = 'hof_ic_rykov_food_supply_commissar'; X = 0; Y = 2;
       P = @('hof_ic_rykov_supreme_economic_council');
       V = @('army_org_factor|_army_org|0.05',
             'war_support_factor|_war_support|0.05',
             'no_supply_grace|_no_supply_grace|48') }

    @{ Id = 'hof_ic_rykov_labour_defence_council'; X = 0; Y = 3;
       P = @('hof_ic_rykov_food_supply_commissar');
       Sync = $true;    # 完成时官衔升到 Lv3：人民委员会主席
       # 动员 = 压缩消费换工业。方向与布哈林的「按比例发展」相反，不是重复（docs/29 §7）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05') }

    @{ Id = 'hof_ic_rykov_sponsor_aviation'; X = 0; Y = 4;
       P = @('hof_ic_rykov_labour_defence_council');
       V = @('experience_gain_air_factor|_experience_gain_air|0.05');
       # 🚩 挂 MIO（原版【真 MIO】：SOV_yakovlev_design_bureau_organization）。
       #    写法【逐字照原版】common/national_focus/afghanistan.txt L909-919 / L2770-2780：
       #      ① 整块包在 has_dlc = "Arms Against Tyranny" 里（MIO 是该 DLC 的机制）
       #      ② custom_effect_tooltip = available_mio_tt（「军工机构可用：」）
       #         —— 【不是】unlock_mio_tt（「建立军工机构」）：
       #            该 MIO 对 SOV 默认就是开放的（docs/29 §9.2）→ 我们做的是【强化】
       #      ③ add_mio_size 【必须】嵌在 mio:<id> = { } 里，不能平铺
       #         （踩过：docs/29 §9.2 早期把这条写成了平铺，是错的）
       Raw = @(
           'if = {',
           '    limit = { has_dlc = "Arms Against Tyranny" }',
           '    custom_effect_tooltip = available_mio_tt',
           '    show_mio_tooltip = SOV_yakovlev_design_bureau_organization',
           '    mio:SOV_yakovlev_design_bureau_organization = {',
           '        add_mio_size = 2',
           '    }',
           '    custom_effect_tooltip = generic_skip_one_line_tt',
           '}'
       ) }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    # 🚩 四个节点【全部完成】才开门：P 写成四个并列的嵌套数组 = AND。
    #    绝不是同一块里写四个 focus！（照 docs/26 布哈林 E1 的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    @{ Id = 'hof_ic_rykov_labour_defence_chair'; X = 0; Y = 6;
       P = @(@('hof_ic_rykov_supreme_economic_council'),
             @('hof_ic_rykov_food_supply_commissar'),
             @('hof_ic_rykov_labour_defence_council'),
             @('hof_ic_rykov_sponsor_aviation'));
       Sync = $true;    # 完成时官衔升到 Lv4：劳动与国防委员会主席
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.10',
             'stability_factor|_stability|0.05') }
)

if ($rykovLine.Count -ne 5) { throw "李可夫个人线应当是 5 条（4 节点 + 1 单结局），实际 $($rykovLine.Count) 条" }

# =============================================================================
# ★ 季诺维也夫个人线：11 条国策（3 支线 9 节点 + 2 个互斥结局）—— docs/33 §1
#   坐标（相对入口 hof_ic_seat_grigory_zinovyev）：D dx=-2 / A dx=0 / C dx=+2
#   列距 2 格（同布哈林 —— docs/26 的注释：1 格太挤，图标会被压在一起）
#   🚩 C3 前置 = C2 且 A4（**两块并列 = AND**）= 本线唯一的跨簇钩子（docs/32 §6）
#   🚩 两个结局【不进 $Branch】：由 $endingChoiceOf 的角色标记驱动（照托洛茨基），
#      门控「三条支线走通两条」写在二选一事件的触发条件里。
#   区块宽度 = 5 列（-2..+2）—— 入口坐标由 §10z 的【区块避让】自动算，不用手改
#
# 🚩 描述全部是【他本人的原文节选 + 出处】（AGENTS 规则 9）—— 他有完整中文文集
#    （中文马克思主义文库有他的专页，本轮抓了 26 + 3 份一手件，落盘 tmp/zinoviev/txt/）。
#    逐条出处见 docs/33 §4。⚠️ 唯一需要说明的是 A2（21 条件原文报告中文文库没有，
#    引的是他 1921-11 回顾时说「著名的二十一条」的那一句）。
# =============================================================================
$zinPrefix = 'hof_ic_grigory_zinovyev'
$zinDmId   = 'hof_ic_grigory_zinovyev_dm'
$zinExtraHeaderTt = 'hof_ic_zinovyev_extra_effects_tt'

$zinLine = @(

    # ---------------- 支线 A · 缔造共产国际，再给它立规矩（x = 0）----------------
    @{ Id = 'hof_ic_zinovyev_found_the_comintern'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：共产国际执行委员会主席
       V = @('communism_drift|_communism_drift|0.02',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.25') }

    @{ Id = 'hof_ic_zinovyev_twenty_one_conditions'; X = 0; Y = 2;
       P = @('hof_ic_zinovyev_found_the_comintern');
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_zinovyev_social_fascism'; X = 0; Y = 3;
       P = @('hof_ic_zinovyev_twenty_one_conditions');
       # ⚠️ 与托洛茨基的「反法西斯统一战线」（1934）是【对立命题】，不是重复
       #    —— 他 1924 先提「社会法西斯主义」，托洛茨基 1934 才要求联合社民党（docs/32 §7）
       V = @('war_support_factor|_war_support|0.05',
             'communism_drift|_communism_drift|0.02') }

    @{ Id = 'hof_ic_zinovyev_bolshevization'; X = 0; Y = 4;
       P = @('hof_ic_zinovyev_social_fascism');
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.10') }

    # ---------------- 支线 C · 世界革命的期限与道路（x = +2）----------------
    @{ Id = 'hof_ic_zinovyev_congress_of_the_east'; X = 2; Y = 1; P = @('__entry__');
       V = @('send_volunteer_factor|_send_volunteer|0.25',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.25') }

    @{ Id = 'hof_ic_zinovyev_workers_united_front'; X = 2; Y = 2;
       P = @('hof_ic_zinovyev_congress_of_the_east');
       V = @('stability_factor|_stability|0.05',
             'communism_drift|_communism_drift|0.02') }

    @{ Id = 'hof_ic_zinovyev_speed_and_route'; X = 2; Y = 3;
       # 🚩 跨簇钩子（docs/32 §6 / docs/33 §5）：两块并列 = AND ——
       #    得先把党改造够格（A4 布尔什维克化），再谈「世界革命走哪条路」。
       #    绝不是同一块里写两个 focus！（照布哈林 E1 / 李可夫 E1 的手法）
       P = @(@('hof_ic_zinovyev_workers_united_front'), @('hof_ic_zinovyev_bolshevization'));
       V = @('communism_drift|_communism_drift|0.05',
             'political_power_factor|_political_power|0.05') }

    # ---------------- 支线 D · 党与工会的作用（x = -2）----------------
    @{ Id = 'hof_ic_zinovyev_party_in_revolution'; X = -2; Y = 1; P = @('__entry__');
       V = @('political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_zinovyev_trade_unions'; X = -2; Y = 2;
       P = @('hof_ic_zinovyev_party_in_revolution');
       Sync = $true;    # 完成时官衔升到 Lv3：联共（布）中央政治局委员
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }

    # ---------------- 汇合层 · 两个互斥结局（X = -1 / +1, Y = 6）----------------
    # 🚩 写法照托洛茨基的两个结局：
    #    ① P 写成【一个】prerequisite 块、内含三个 focus = 【OR】（任一支线走到头就开门）
    #    ② Mut 互相指向对方（手动点选时的保险）
    #    ③ 门控（三条支线走通两条）在 $endingChoiceOf 的事件触发条件里，不在 available
    # 🚩 两个结局【都不加 Sync】—— 见 roster 里 RankGates 的注释。
    # 🚩 两个结局是「同一个国际的两种形态」，两条都成立，不是一好一坏：
    #    E1 走【纪律】面（政治点 / 意识形态防御 / 稳定度）
    #    E2 走【群众】面（意识形态输出 / 稳定度 / 志愿军，代价是压消费品）
    @{ Id = 'hof_ic_zinovyev_monolithic_international'; X = -1; Y = 6;
       P = @('hof_ic_zinovyev_bolshevization', 'hof_ic_zinovyev_speed_and_route',
             'hof_ic_zinovyev_trade_unions');
       Mut = 'hof_ic_zinovyev_mass_international';
       V = @('political_power_factor|_political_power|0.10',
             'drift_defence_factor|_drift_defence|0.15',
             'stability_factor|_stability|0.05',
             'communism_drift|_communism_drift|0.02') }

    @{ Id = 'hof_ic_zinovyev_mass_international'; X = 1; Y = 6;
       P = @('hof_ic_zinovyev_bolshevization', 'hof_ic_zinovyev_speed_and_route',
             'hof_ic_zinovyev_trade_unions');
       Mut = 'hof_ic_zinovyev_monolithic_international';
       V = @('communism_drift|_communism_drift|0.05',
             'stability_factor|_stability|0.10',
             'consumer_goods_factor|_consumer_goods|-0.05',
             'send_volunteer_factor|_send_volunteer|0.25') }
)

if ($zinLine.Count -ne 11) { throw "季诺维也夫个人线应当是 11 条（9 节点 + 2 结局），实际 $($zinLine.Count) 条" }

# =============================================================================
# ★ 加米涅夫个人线：5 条国策（**单线 4 节点 + 1 单结局**）
#   —— docs/35（谱系，SOP 第 0–5 步）+ docs/36（第 6 步设计）
#   坐标：全部 x = 0（相对入口 hof_ic_seat_lev_kamenev）—— 区块宽 1，同李可夫线
#
# 🚩🚩 用户 2026-09-17 口径（砍）：
#   「那个互斥砍掉，BC 支线也砍了，这两个支线没看出来有什么内容
#     然后结局单一个列宁遗嘱执行人就行了
#     你这加米涅夫全篇我看就一个大主题列宁」
#   → 从【3 支线 10 节点 + 1 互斥项 + 2 结局 = 13 块】砍到【单线 4 节点 + 1 结局 = 5 块】
#   → 全篇只讲一件事：**列宁的文本与遗产**（主干）
#   → 官衔链也跟着改成列宁文献类职务（见花名册 Idx 5）
#   ⚠️ 教训：B（苏维埃治理）/ C（商业与对外）确实是【拼上去的】，
#      它们有史实、有一手件，但與「列宁」这个主干【没有推导关系】——
#      按 docs/23 第 1 步的说法，这是「把分类清单当成树」的又一次重犯。
#
# 🚩 文案全部是一手件（中文专页 19 条 + 英文 6 篇，落盘 tmp/kamenev/txt/）。
#    ⚠️ 四条引的主要是【自传正文】（本人审定）与他的两篇长文；
#       **绝不引「续志」**（那是穆兹卡写的后人记述 —— docs/35 §0）。
# =============================================================================
$kamPrefix = 'hof_ic_lev_kamenev'
$kamDmId   = 'hof_ic_lev_kamenev_dm'
$kamExtraHeaderTt = 'hof_ic_kamenev_extra_effects_tt'

$kamLine = @(

    # ---------------- 单线 · 列宁的文本与遗产（x = 0）----------------
    @{ Id = 'hof_ic_kamenev_lenins_charge'; X = 0; Y = 1; P = @('__entry__');
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_kamenev_leninism'; X = 0; Y = 2;
       P = @('hof_ic_kamenev_lenins_charge');
       Sync = $true;    # 完成时官衔升到 Lv2：《列宁文集》主编
       V = @('communism_drift|_communism_drift|0.05',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.05') }

    @{ Id = 'hof_ic_kamenev_against_the_lessons'; X = 0; Y = 3;
       P = @('hof_ic_kamenev_leninism');
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_kamenev_lenin_institute'; X = 0; Y = 4;
       P = @('hof_ic_kamenev_against_the_lessons');
       Sync = $true;    # 完成时官衔升到 Lv3：列宁研究院院长
       # 奠基性最强的一条（docs/35 §4）—— 它变成了后世一切「援引列宁」的前提
       V = @('boost_ideology_mission_factor|_boost_ideology_mission|0.10',
             'political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.10') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    # 🚩 四个节点【全部完成】才开门：P 写成四个并列的嵌套数组 = AND。
    #    绝不是同一块里写四个 focus！（照李可夫 E1 的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    @{ Id = 'hof_ic_kamenev_executor_of_the_will'; X = 0; Y = 6;
       P = @(@('hof_ic_kamenev_lenins_charge'),
             @('hof_ic_kamenev_leninism'),
             @('hof_ic_kamenev_against_the_lessons'),
             @('hof_ic_kamenev_lenin_institute'));
       V = @('boost_ideology_mission_factor|_boost_ideology_mission|0.10',
             'drift_defence_factor|_drift_defence|0.15',
             'stability_factor|_stability|0.05',
             'communism_drift|_communism_drift|0.10') }
)

if ($kamLine.Count -ne 5) { throw "加米涅夫个人线应当是 5 条（4 节点 + 1 单结局），实际 $($kamLine.Count) 条" }

# =============================================================================
# 斯米尔诺夫（Idx 6）—— 单线 5 节点 + 1 单结局
# =============================================================================
# 🚩 主干（docs/38 §4 / docs/39 §1）：【把俄罗斯的东部边地一块块造成苏维埃国家的一部分】
#    根（方法，不是理论）：【永远是个忠于职守的人】（托洛茨基语）
#    → 守住桥头堡 → 打赢并结成队伍 → 把它建成政权 → 再往东一步用缓冲国挡住日本 → 用邮电网把全国连起来
#    簇数 = 1 → 支线数 = 1（docs/23 §2）；跨簇钩子 = 无。
# 🚩 文案出处（全部是【节选】，没一句是我写的）：
#    A1 / A2 / A5 / E1 ← 托洛茨基《我的生平》第三十三章〈斯维亚日斯克一月〉【中译本】
#                         （落到 tmp/smirnov/mia/ch35.txt，MIA: trotsky_1929book35.htm）
#    A3 / A4         ← 维克多·塞尔日《伊·尼·斯米尔诺夫之死》(1936-08，MIA 英文)
#                         ⚠️ 这两条入游戏文本前需中译（docs/99 §12.3）
#    A2 的「五军将士」与 A1 的「斯维亚日斯克的良心」都是那一章里的原词。
# =============================================================================
$smirPrefix = 'hof_ic_smirnov'
$smirDmId   = 'hof_ic_ivan_smirnov_dm'
$smirExtraHeaderTt = 'hof_ic_smirnov_extra_effects_tt'

$smirLine = @(

    # ---------------- 单线 · 一路向东（x = 0）----------------
    @{ Id = 'hof_ic_smirnov_the_volga_bridgehead'; X = 0; Y = 1; P = @('__entry__');
       # 这一节的产物就是「没丢」—— 守
       V = @('army_core_defence_factor|_army_core_defence|0.05',
             'max_dig_in_factor|_max_dig_in|0.10') }

    @{ Id = 'hof_ic_smirnov_the_fifth_army'; X = 0; Y = 2;
       P = @('hof_ic_smirnov_the_volga_bridgehead');
       # 产物是「一支团结成政治家庭的集团军」—— 组织与士气
       V = @('army_org_factor|_army_org|0.05',
             'army_morale_factor|_army_morale|0.05') }

    @{ Id = 'hof_ic_smirnov_sibrevkom'; X = 0; Y = 3;
       P = @('hof_ic_smirnov_the_fifth_army');
       Sync = $true;    # 完成时官衔升到 Lv2：西伯利亚革命委员会主席
       # 产物是【政权】—— 从军事占领转成治理
       V = @('stability_factor|_stability|0.05',
             'political_power_factor|_political_power|0.05') }

    @{ Id = 'hof_ic_smirnov_far_eastern_republic'; X = 0; Y = 4;
       P = @('hof_ic_smirnov_sibrevkom');
       # 产物是【缓冲国】—— 挡住外部影响、稳住东南
       V = @('drift_defence_factor|_drift_defence|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_smirnov_posts_and_telegraphs'; X = 0; Y = 5;
       P = @('hof_ic_smirnov_far_eastern_republic');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联邮电人民委员
       # 产物是【全国性的邮电网】—— 建设与信息
       # 📌 按 docs/38 §8 第 3 步：奠基性最强的条目放末端（⑤ 比 ④ 时间更晚、建制存续更久）
       V = @('production_speed_infrastructure_factor|_production_speed_infrastructure|0.05',
             'mobilization_speed|_mobilization_speed|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    #    绝不是同一块里写五个 focus！（照李可夫 / 加米涅夫 E1 的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    @{ Id = 'hof_ic_smirnov_siberian_lenin'; X = 0; Y = 7;
       P = @(@('hof_ic_smirnov_the_volga_bridgehead'),
             @('hof_ic_smirnov_the_fifth_army'),
             @('hof_ic_smirnov_sibrevkom'),
             @('hof_ic_smirnov_far_eastern_republic'),
             @('hof_ic_smirnov_posts_and_telegraphs'));
       V = @('production_speed_infrastructure_factor|_production_speed_infrastructure|0.10',
             'stability_factor|_stability|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.05',
             'compliance_growth|_compliance_growth|0.05') }
)

if ($smirLine.Count -ne 6) { throw "斯米尔诺夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($smirLine.Count) 条" }

# =============================================================================
# 谢列布里亚科夫（Idx 7）—— 单线 4 节点 + 1 单结局
# =============================================================================
# 🚩 主干（docs/41 §5.1 / docs/42 §1）：【把散落的部件接成一台能运转的机器】
#    根（方法，不是理论）：【天才的工人】—— 列宁给他的评语（其女 З. 谢列布里亚科娃回忆录篇名）
#    → 把驻军接上革命 → 把地方组织接上中央 → 把国家接上铁路 → 把国家接上公路
#    簇数 = 1 → 支线数 = 1（docs/23 §2）；跨簇钩子 = 无。
# 🚩 文案出处（全部是【节选】，没一句是我写的）：
#    A2 / E1 ← A2 = 1919-07-05 中央决议【署名名单】（他是签署人之一）
#              （托洛茨基《我的生平》第三十九章中译本，落盘 tmp/trotsky/txt/i3_military_strategy_39.txt）
#               E1 = З. Л. 谢列布里亚科娃回忆录篇名（家人记述）
#    A1 / A3 / A4 ← 俄文维基（人物条 + 〈НКПС РСФСР〉机构条）的【记述】
#              ⚠️ 按 docs/23 §7.1 优先级 3 使用：**已去引号**，不冒充原文；
#                 入游戏文本前需中译（docs/99 §13）
# ⛔ 已剔（用户 2026-09-17 砍 A2）：红军的政治机关（ПУР РВСР）—— 与托洛茨基的内战军事题略挤
# =============================================================================
$serebPrefix = 'hof_ic_leonid_serebryakov'
$serebDmId   = 'hof_ic_leonid_serebryakov_dm'
$serebExtraHeaderTt = 'hof_ic_serebryakov_extra_effects_tt'

$serebLine = @(

    # ---------------- 单线 · 接线（x = 0）----------------
    @{ Id = 'hof_ic_serebryakov_kostroma'; X = 0; Y = 1; P = @('__entry__');
       # 把驻军接上革命 —— 产物是「一团人跟着他出营房」
       V = @('army_morale_factor|_army_morale|0.05',
             'communism_drift|_communism_drift|0.05') }

    @{ Id = 'hof_ic_serebryakov_central_committee'; X = 0; Y = 2;
       P = @('hof_ic_serebryakov_kostroma');
       Sync = $true;    # 完成时官衔升到 Lv2：俄共（布）中央书记
       # 把地方组织接上中央 —— 产物是「中央机关在转」
       V = @('stability_factor|_stability|0.05',
             'political_power_factor|_political_power|0.05') }

    @{ Id = 'hof_ic_serebryakov_commissariat_of_transport'; X = 0; Y = 3;
       P = @('hof_ic_serebryakov_central_committee');
       # 把国家接上铁路 —— 产物是「从 60% 被毁的路网里恢复运转」
       V = @('production_speed_rail_way_factor|_production_speed_rail_way|0.05',
             'production_speed_supply_node_factor|_production_speed_supply_node|0.05',
             'production_speed_infrastructure_factor|_production_speed_infrastructure|0.05');
       # 莫斯科—图拉工业交通走廊：只在苏联仍拥有并控制该州、且基建未满级时施工。
       Raw = @(
           'if = {',
           '`tlimit = { 219 = { is_owned_by = ROOT is_controlled_by = ROOT infrastructure < 5 } }',
           '`t219 = { add_building_construction = { type = infrastructure level = 1 instant_build = yes } }',
           '}',
           'if = {',
           '`tlimit = { 223 = { is_owned_by = ROOT is_controlled_by = ROOT infrastructure < 5 } }',
           '`t223 = { add_building_construction = { type = infrastructure level = 1 instant_build = yes } }',
           '}'
       ) }

    @{ Id = 'hof_ic_serebryakov_highways_and_motor_transport'; X = 0; Y = 4;
       P = @('hof_ic_serebryakov_commissariat_of_transport');
       Sync = $true;    # 完成时官衔升到 Lv3：公路与汽车运输总局局长
       # 奠基性最强的一条（docs/41 §8）：1921 年 НКПС 接管汽车运输 → 1931 年这个总局
       V = @('production_speed_infrastructure_factor|_production_speed_infrastructure|0.05',
             'supply_consumption_factor|_supply_consumption|-0.05',
             'no_supply_grace|_no_supply_grace|48') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    # 🚩 四个节点【全部完成】才开门：P 写成四个并列的嵌套数组 = AND。
    #    绝不是同一块里写四个 focus！（照李可夫 / 加米涅夫 E1 的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    @{ Id = 'hof_ic_serebryakov_brilliant_worker'; X = 0; Y = 6;
       P = @(@('hof_ic_serebryakov_kostroma'),
             @('hof_ic_serebryakov_central_committee'),
             @('hof_ic_serebryakov_commissariat_of_transport'),
             @('hof_ic_serebryakov_highways_and_motor_transport'));
       V = @('production_speed_supply_node_factor|_production_speed_supply_node|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.10',
             'production_speed_rail_way_factor|_production_speed_rail_way|0.05',
             'supply_consumption_factor|_supply_consumption|-0.05',
             'production_speed_infrastructure_factor|_production_speed_infrastructure|0.05') }
)

if ($serebLine.Count -ne 5) { throw "谢列布里亚科夫个人线应当是 5 条（4 节点 + 1 单结局），实际 $($serebLine.Count) 条" }

# =============================================================================
# 普列奥布拉任斯基（Idx 8）—— 单线 4 节点 + 1 单结局
# =============================================================================
# 🚩 根（docs/44 §4 / docs/45 §1）：【过渡时期有两种调节者】
#    —— 社会主义经济不是一个封闭自足的体系，它处在前社会主义经济形式的【包围】中
# 🚩 主干：【社会主义原始积累】—— 国有工业的积累不能来自国有部门内部，
#    必须从「前社会主义的经济形式」（主要就是小农经济）里提取
#    → 1922 农村政策提纲 → 1924-01 压缩剪刀差 → 1924-05 反对耐普曼的积累 → 1926《新经济学》
#    ⭐ 顺序即推导：先看清来源 → 再管住价格 → 再清除竞争者 → 最后写成规律。
# 🚩 文案出处（全部是【节选】，没一句是我写的）：
#    A1 ← 《俄共目前农村政策的基本原则》提纲（1922-03）【中文原文】
#    A2 ← 1924-01-12 莫斯科省第十一次代表会议决议案（得 61 票）【中文原文】
#    A3 ← 1924-05-28 俄共（布）第十三次代表大会发言【中文原文】
#    A4 ← 人民委员会主席李可夫对《新经济学》的评语（俄文，待中译）
#         ⚠️《新经济学》正文没中文数字化（中文站只给 CHM）→ 引不到他自己的原句
#    E1 ← 《新经济学》第二章的书用语（经俄文维基转引）
#    ⚠️ 本线是【单线 4 节点 + 1 单结局】（docs/45 §2）——
#       用户 2026-09-17 口径「感觉 B 可以合并到 A，不需要单列支线」→ 一个节点都没丢
# =============================================================================
$preobPrefix = 'hof_ic_yevgeny_preobrazhensky'
$preobDmId   = 'hof_ic_yevgeny_preobrazhensky_dm'
$preobExtraHeaderTt = 'hof_ic_preobrazhensky_extra_effects_tt'

$preobLine = @(

    # ---------------- 单线 · 从农村提取积累（x = 0）----------------
    @{ Id = 'hof_ic_preobrazhensky_agrarian_theses'; X = 0; Y = 1; P = @('__entry__');
       # 产物是「农村政策被纳入党的路线」
       V = @('political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_preobrazhensky_scissors'; X = 0; Y = 2;
       P = @('hof_ic_preobrazhensky_agrarian_theses');
       Sync = $true;    # 完成时官衔升到 Lv2：党中央与人民委员会财政委员会主席
       # 产物是「把工农业交换条件管起来」（⚠️ 1924 年他主张【压缩】剪刀差，不是制造）
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05') }

    @{ Id = 'hof_ic_preobrazhensky_against_nepmen'; X = 0; Y = 3;
       P = @('hof_ic_preobrazhensky_scissors');
       # 产物是「挡住私人资本的侵蚀」
       V = @('communism_drift|_communism_drift|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_preobrazhensky_two_regulators'; X = 0; Y = 4;
       P = @('hof_ic_preobrazhensky_against_nepmen');
       Sync = $true;    # 完成时官衔升到 Lv3：租让事务总委员会副主席
       # 奠基性最强的一条（docs/44 §8）——【两种规律】把整条论证形式化了
       V = @('production_speed_buildings_factor|_production_speed_buildings|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    # 🚩 四个节点【全部完成】才开门：P 写成四个并列的嵌套数组 = AND。
    @{ Id = 'hof_ic_preobrazhensky_primitive_accumulation'; X = 0; Y = 6;
       P = @(@('hof_ic_preobrazhensky_agrarian_theses'),
             @('hof_ic_preobrazhensky_scissors'),
             @('hof_ic_preobrazhensky_against_nepmen'),
             @('hof_ic_preobrazhensky_two_regulators'));
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.10',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }
)

if ($preobLine.Count -ne 5) { throw "普列奥布拉任斯基个人线应当是 5 条（4 节点 + 1 单结局），实际 $($preobLine.Count) 条" }

# =============================================================================
# 拉狄克（Idx 9）—— 单线 5 节点 + 1 单结局
# =============================================================================
# 🚩 根（docs/47 §4 / docs/48 §1）：【红色笔杆子】
#    —— 14 岁给一个不识字的建筑工人念报纸入的行，此后一辈子以写作为业（自传篇名即此）
# 🚩 主干：【把革命办到俄国以外 —— 而他的武器是笔】
#    —— 他 1918–1925 的每一个岗位都落在「向外」这一侧
#    → 中欧司（建渠道）→ 德共一大（帮它建党）→ 狱中七本（被捕后照样写）
#      → 德国十月（去发动一次起义）→ 中山大学（换个方向办一所大学）
#    ⭐ 顺序即推导：先建渠道，再建党，被捕了继续写，再发动一次起义，最后转向东。
# ⭐⭐ 为什么主干不是「共产国际」（docs/47 §2.2、§4.3）：他的三个最显眼的领域
#    【全被别的线占了】—— 共产国际 = 季诺维也夫（整条线）；统一战线 = 季的 C 支线 + 托 V3；
#    中国革命问题 = 托 V2。而「德国」在 22 人里【独一份】。
#    📌 这是「招牌被占掉时，去查他另一个岗位」的第 3 次运用（docs/35 §5.1）。
# 🚩 文案出处（docs/48 §5）—— ⭐⭐ 本线是至今文案档次最高的一条：
#    【6/6 全部是中文原文，且全部出自【本人审定的自传】】
#    A1–A5 + E1 ←《拉狄克自传》（原载《格拉纳特百科辞典》第 41 卷）
#                 落盘 tmp/radek/txt/（中文马克思主义文库「卡尔·拉狄克」篇目）
#    ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# ⚠️ 本线是【单线 5 节点 + 1 单结局】（docs/48 §2）—— 用户 2026-09-17 口径
#    「不砍，结局 ok，继续吧」→ A5（中山大学）保留、结局取「红色笔杆子」。
# ⚠️ 一件【如实标注的争议】（docs/47 §5.2 尾）：docs/21 §302 写他「1924 年倒向多数派
#    攻击托洛茨基」，而其自传（1926 本人审定）写「站在党内反对派一方参加 1924 年的争论」
#    —— 两说相反 → 【本线不做「1924 年」这个节点】，绕开争议。
# =============================================================================
$radekPrefix = 'hof_ic_karl_radek'
$radekDmId   = 'hof_ic_karl_radek_dm'
$radekExtraHeaderTt = 'hof_ic_radek_extra_effects_tt'

$radekLine = @(

    # ---------------- 单线 · 把革命办到俄国以外（x = 0）----------------
    @{ Id = 'hof_ic_radek_central_europe_department'; X = 0; Y = 1; P = @('__entry__');
       # 产物是「对中欧的外交渠道」（1918-03 起，布列斯特和约签订之后）
       V = @('opinion_gain_monthly_factor|_opinion_gain_monthly|0.05',
             'improve_relations_maintain_cost_factor|_improve_relations_maintain_cost|-0.05') }

    @{ Id = 'hof_ic_radek_founding_of_the_kpd'; X = 0; Y = 2;
       P = @('hof_ic_radek_central_europe_department');
       # 产物是「在外国建了一个党」（1918-12 ~ 1919-01，秘密赴德）
       V = @('communism_drift|_communism_drift|0.05',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.05') }

    @{ Id = 'hof_ic_radek_seven_pamphlets'; X = 0; Y = 3;
       P = @('hof_ic_radek_founding_of_the_kpd');
       # 产物是「七本小册子」（1919-02-15 – 1919-12，狱中照样写与领导）
       V = @('communism_drift|_communism_drift|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_radek_german_october'; X = 0; Y = 4;
       P = @('hof_ic_radek_seven_pamphlets');
       Sync = $true;    # 完成时官衔升到 Lv2：共产国际执行委员会书记
       # 产物是「一次起义（与它的退却）」（1923-10）
       V = @('communism_drift|_communism_drift|0.05',
             'political_power_factor|_political_power|0.02') }

    @{ Id = 'hof_ic_radek_sunyatsen_university'; X = 0; Y = 5;
       P = @('hof_ic_radek_german_october');
       Sync = $true;    # 完成时官衔升到 Lv3：中山大学校长
       # 产物是「一所大学」（1925 – 1927，为东方培养干部）—— 同一条主干，方向转向东
       V = @('boost_ideology_mission_factor|_boost_ideology_mission|0.05',
             'communism_drift|_communism_drift|0.05') }

    # ---------------- 支线 B · 向东 · 中国（x = +2）----------------
    # ⭐ 2026-09-20 用户裁决（判据 J）：先在三候选里取【丙】；
    #    同日重审（docs/92 §5）确认【乙】与【甲】同轴 → **三件合并成一条 3 节点支线**。
    #    🚩 顺序 = 层层深入：**先看政局往哪走 → 再看工人的实际处境 → 最后给这个主义定性**。
    #    时间单调递增：1924-10-26 → 1925-08-13 → 1926-03-12。
    # 🚩 与托洛茨基（Idx 1）`hof_ic_trotsky_the_chinese_question`「中国革命问题」的界线【必须写死】：
    #    ⚠️ 两人**能同席**（`left × left` 无规则 → 判据 E 不适用，**矩阵兜不住**）
    #    托问「**共产党该不该把国民党摆在首位**」（组织路线）；
    #    本线问「**这场革命里工人、农民、资产阶级各占什么位置、谁在领导**」（社会结构 / 形势判断）。
    # ⛔ 刻意不用《中国革命一周年》（1926-05-30）—— 那篇最有力的段落论点与托【完全重合】
    #    （「共产党员对小资产阶级政党国民党的发号施令」）；⛔《列宁与中国革命》撞加米涅夫主干（判据 A）。
    # ✅ 判据 K：「中国的夺权斗争」0 ·「中国工人阶级的状况」0 ·「社会政治思想」0。
    @{ Id = 'hof_ic_radek_the_struggle_for_power_in_china'; X = 2; Y = 1; P = @('__entry__');
       # 产物是「一份对华形势的判断」（1924-10-26，北京政变之后）
       # ⭐ 他说的是「军阀混战会把中国革命推到哪一步」
       V = @('opinion_gain_monthly_factor|_opinion_gain_monthly|0.05',
             'political_power_factor|_political_power|0.05');
       # 对军阀均势的判断供中共研判战局：一次性战争支持度。
       Raw = @('if = { limit = { country_exists = PRC } PRC = { add_war_support = 0.05 } }') }

    @{ Id = 'hof_ic_radek_the_condition_of_the_chinese_working_class'; X = 2; Y = 2;
       P = @('hof_ic_radek_the_struggle_for_power_in_china');
       # 1925-08-13《中国工人阶级的状况》（＋1925-07-31《英国关于中国无产阶级状况的"兰皮书"》）
       # 产物 = ⭐⭐⭐ **一份把中国工人的实际处境摆到国际读者面前的实证材料**
       #   （12–18 小时工作日 · 6–12 岁童工 · 每日 6–24 戈比 · 伤者无补助 ·
       #    开滦矿工传单：「骡马死了还值一百美元；死了一个工人，工厂当局连五十美元也花费不了。」）
       # ⭐ 制度命题：**判断之外，还得有实际的材料**
       V = @('communism_drift|_communism_drift|0.05',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.05');
       # 工人境况的调查材料用于组织工作：一次性政治点。
       Raw = @('if = { limit = { country_exists = PRC } PRC = { add_political_power = 25 } }') }

    @{ Id = 'hof_ic_radek_social_and_political_thought'; X = 2; Y = 3;
       P = @('hof_ic_radek_the_condition_of_the_chinese_working_class');
       # 1926-03-12《孙中山的社会政治思想》（＋1925-03-14《中国人民的领袖》）
       # 产物 = ⭐⭐⭐ **一套对孙中山主义的思想定性**：民生（分配论 / 土地国有 / 地价税）·
       #   民权（**五权宪法** = 三权 ＋ 考试权 ＋ 监察权）· 民族（从「反满」到「反帝」）· 遗嘱
       # ⭐ 制度命题：**看清力量之后，还得把这个主义的来龙去脉说清楚**
       # ⭐ 与 A5「中山大学」同轴：先给这个主义定性，再办那所以他名字命名的学校
       # 📌 2026-09-20 用户口径：节点名取【社会政治思想】
       V = @('political_power_factor|_political_power|0.05',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.05');
       # 对孙中山思想和联盟对象的梳理，抽象成一次性内部稳定度。
       Raw = @('if = { limit = { country_exists = PRC } PRC = { add_stability = 0.05 } }') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 **P 写成【平铺】两条 = OR** —— 走通【任一条支线】即可开门（照季诺维也夫 / 图哈的汇合层写法）。
    #    A 支线走到头 = 中山大学；B 支线走到头 = 社会政治思想。
    #    ⭐ 为什么是 OR：**「往西办革命」与「往东看清中国」是同一支笔的两种用法**。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    #    E1 收束回【根】：他一辈子的身份就是那支笔（自传篇名「红色笔杆子，中山大学校长」）。
    @{ Id = 'hof_ic_radek_red_publicist'; X = 0; Y = 7;
       P = @('hof_ic_radek_sunyatsen_university',                     # 支线 A 走到头
             'hof_ic_radek_social_and_political_thought');            # 或 B 支线走到头
       V = @('political_power_factor|_political_power|0.10',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.10',
             'communism_drift|_communism_drift|0.05',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.05') }
)

if ($radekLine.Count -ne 9) { throw "拉狄克个人线应当是 9 条（两条支线 5+3 节点 + 1 单结局），实际 $($radekLine.Count) 条" }

# =============================================================================
# 斯米尔加（Idx 10）—— 单线 5 节点 + 1 单结局
# =============================================================================
# 🚩 根（docs/50 §4.1 / docs/51 §1）：【边境上的启蒙者之家】
#    —— 拉脱维亚护林员的儿子；父亲 1906-01 被沙皇讨伐队枪决；他 14 岁入党
# 🚩 主干：【把散在各处的东西接起来、算清楚】
#    → 芬兰（建渠道）→ 燃料总局（一个部门）→ 国家计委（一本总账）
#      → 国民经济学院（会算账的人）→ 生产力布局（把总账画到地图上）
#    ⭐ 顺序即推导：先接边境，再算一个部门，再算一本总账，再教人算，最后落到地图上。
# ⭐⭐ 首尾同轴：A1 =「把边境的力量送进首都」，A5 =「把首都的工厂送到边境」
#    —— 方向反了，动作是同一个（docs/51 §1.1）。
# 🚩🚩 为什么【砍掉军事那一半】（docs/50 §2.1）：
#    缔造红军 / 军事专家 / 政委制度 / 反游击 / 劳动军 = 托洛茨基（Idx 1，5 块）；
#    一个战区 = 斯米尔诺夫（Idx 6）； 而「红军的政治机关」【已被用户砍掉过】（docs/41 §310）。
#    📌 而且材料本身就指向经济：ru 维基明说「1920 年起转经济工作」；
#       他 20 部著作里 17 部是经济；docs/28 §83 的入口意象就是「经济图表 + 齿轮」。
# 🚩 文案出处（docs/51 §5）：
#    A1 ← en 维基（1917 赫尔辛基 + 1500 名水兵）   【中译稿，记 docs/99 §十六】
#    A2 ← en 维基（引 E. H. Carr：最早的部门计划）【中译稿】
#    A3 ← ru 维基〈Госплан СССР〉历任副主席名单（精确日期）
#    A4 ← ru 维基（1924–1927 国民经济学院院长）  【中译稿】
#    A5 ← ru 维基著作表（1932 书名）
#    E1 ← ⭐⭐【中文原文】托洛茨基《斯大林评传》第十六章（中译本）—— 他自己的话
#    ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# ⚠️ 本线是【单线 5 节点 + 1 单结局】（docs/51 §2）—— 用户 2026-09-17 口径
#    「就这样处理吧，第三条保留」→ 三项全取推荐值，A4（国民经济学院）保留。
# =============================================================================
$smilgaPrefix = 'hof_ic_ivar_smilga'
$smilgaDmId   = 'hof_ic_ivar_smilga_dm'
$smilgaExtraHeaderTt = 'hof_ic_smilga_extra_effects_tt'

$smilgaLine = @(

    # ---------------- 单线 · 把散在各处的东西接起来（x = 0）----------------
    @{ Id = 'hof_ic_smilga_finland'; X = 0; Y = 1; P = @('__entry__');
       # 产物是「把散在芬兰的军队、舰队与苏维埃接成一个可以调动的力量」（1917）
       V = @('army_org_factor|_army_org|0.05',
             'mobilization_speed|_mobilization_speed|0.05') }

    @{ Id = 'hof_ic_smilga_fuel_main_directorate'; X = 0; Y = 2;
       P = @('hof_ic_smilga_finland');
       Sync = $true;    # 完成时官衔升到 Lv2：最高国民经济委员会燃料总局局长
       # 产物是「顿巴斯的煤变成苏联第一份部门计划」（1921–1923）
       V = @('fuel_gain_factor|_fuel_gain|0.05',
             'max_fuel_factor|_max_fuel|0.05');
       Raw = @('add_fuel = 5000') }

    @{ Id = 'hof_ic_smilga_gosplan'; X = 0; Y = 3;
       P = @('hof_ic_smilga_fuel_main_directorate');
       # 产物是「一本国民经济计划」（1923 秋 – 1926-11-23，国家计委副主席）
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05') }

    @{ Id = 'hof_ic_smilga_economics_institute'; X = 0; Y = 4;
       P = @('hof_ic_smilga_gosplan');
       # 产物是「会算账的经济干部」（1924–1927，莫斯科国民经济学院院长）
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_smilga_productive_forces'; X = 0; Y = 5;
       P = @('hof_ic_smilga_economics_institute');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联国家计划委员会副主席（1931-11 他再任此职）
       # 产物是「工厂放到该放的地方」（1931-11-09 – 1933-01-01；1932 年著作）
       V = @('production_speed_buildings_factor|_production_speed_buildings|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    #    绝不是同一块里写五个 focus！（照李可夫 / 加米涅夫 / 谢列布里亚科夫 / 普 / 拉的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    #    E1 收束回【主干】：他一辈子的身份就是那个给时代算账的人（文案是他自己的话）。
    @{ Id = 'hof_ic_smilga_the_healer_of_the_gaps'; X = 0; Y = 7;
       P = @(@('hof_ic_smilga_finland'),
             @('hof_ic_smilga_fuel_main_directorate'),
             @('hof_ic_smilga_gosplan'),
             @('hof_ic_smilga_economics_institute'),
             @('hof_ic_smilga_productive_forces'));
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.10',
             'industrial_capacity_factory|_industrial_capacity|0.10',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }
)

if ($smilgaLine.Count -ne 6) { throw "斯米尔加个人线应当是 6 条（5 节点 + 1 单结局），实际 $($smilgaLine.Count) 条" }

# =============================================================================
# ★ 托姆斯基个人线：6 条国策（单线 5 节点 + 1 单结局）—— docs/53 §4 / docs/54 §2
# -----------------------------------------------------------------------------
# 坐标【相对入口国策 hof_ic_seat_mikhail_tomsky】
#   P    前置。['__entry__'] = 挂在入口国策上；
#        ['A','B'] 同一块 = OR；[['A'],['B']] 多块 = AND（E1 用这个做「五个全完成」）
#   V    数值贡献："<modifier>|<变量后缀>|<增量>"
#        全部 add_to_variable 进 hof_ic_mikhail_tomsky_dm（个人数值容器）
#   Sync 完成时调一遍 sync_rank → 官衔分级重算
#
# ⭐ 主干 = 给工会争一个自己的声音。顺序即推导（一行 → 一城 → 全国 → 顶住 → 代价）：
#   A1 给【一个行当】挣到一个工会 → A2 给【一座城】的工会当上主席
#   → A3 给【全国】的工会当上头 → A4 有人来整肃工会时挡回去 → A5 不肯念那份稿子
# ⭐⭐ A5（1921-05 的沉默）是【全线最强的一条】（docs/53 §7 / §8）：
#    它不是「被否决的主张」，而是一次【不肯做】的行动 —— 决议按梁赞诺夫版通过，
#    他被撤出工会工作；而 Lv3 的门槛正是它（他 1922 年把位置拿回来）。
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 A4 = 【中文原文】（季诺维也夫《论工会在生产中的作用》1921-03，记录他的立场）
#    🟢 E1 = 【中文原文（他本人的话）】（1928-07-11 布哈林与加米涅夫密谈记录）
#    🟡 A1/A2/A5 = 【中译稿】（ru/en 维基记述，⚠️ 需复核译文，docs/99 §十七）
#    🟡 A3 = 【机构条目历任名单】（ru 维基〈ВЦСПС〉，不需译）
# 出处：
#   A4 = ⭐ 季诺维也夫《论工会在生产中的作用》（俄共十大，1921-03）
#        —— 落盘 tmp/zinoviev/txt/d2_union_1921_02.txt L115 / L215
#        ⚠️ 这一篇正是季诺维也夫线 D2 的文案出处（docs/33 §130）
#           → 本线【只引其中「关于托姆斯基」的部分】，不引季诺维也夫自己的论断
#   E1 = ⭐ 1928-07-11 布哈林与加米涅夫密谈记录 —— 落盘 tmp/kamenev/txt/pol_19280711_talk_b.txt L23
#   A1/A2/A5 = ru / en 维基〈Томский, Михаил Павлович〉/〈Mikhail Tomsky〉
#   A3 = ru 维基〈ВЦСПС〉历任名单（机构条目 —— docs/23 §5 的方法，第 3 次收获）
# =============================================================================
$tomskyPrefix = 'hof_ic_mikhail_tomsky'
$tomskyDmId   = 'hof_ic_mikhail_tomsky_dm'
$tomskyExtraHeaderTt = 'hof_ic_tomsky_extra_effects_tt'

$tomskyLine = @(

    # ---------------- 单线 · 给工会争一个自己的声音（x = 0）----------------
    @{ Id = 'hof_ic_tomsky_printers_union'; X = 0; Y = 1; P = @('__entry__');
       # 产物是「一个行当的组织与一纸集体合同」（1906-08 回彼得格勒，1907 组建石印工人工会）
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_tomsky_moscow_trade_union_council'; X = 0; Y = 2;
       P = @('hof_ic_tomsky_printers_union');
       # 产物是「一座城的工会」（1917-10-28 赴彼得格勒，10-29 列宁听取报告，12 月当选主席）
       V = @('political_power_factor|_political_power|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_tomsky_central_council_of_trade_unions'; X = 0; Y = 3;
       P = @('hof_ic_tomsky_moscow_trade_union_council');
       Sync = $true;    # 完成时官衔升到 Lv2：全苏工会中央理事会主席
       # 产物是「全国工会的头」（1918-10-09 ВЦСПС 执委会选他为执行局主席）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_tomsky_platform_of_ten'; X = 0; Y = 4;
       P = @('hof_ic_tomsky_central_council_of_trade_unions');
       # 产物是「把整肃挡回去」（1920-10–1921-03 工会讨论，与列宁、季诺维也夫一起站「十人纲领」）
       # ⚠️ production_factory_efficiency_gain_factor 在原版是【负数】用的
       #    （他的 Default 特质 right_trade_unionist 里是 -0.05）
       #    → 本线用它 +5% 正是「工会有自己的声音」的正面表达（docs/54 §3）
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_tomsky_the_silence_of_1921'; X = 0; Y = 5;
       P = @('hof_ic_tomsky_platform_of_ten');
       Sync = $true;    # 完成时官衔升到 Lv3：再任全苏工会中央理事会主席（1922 年拿回来）
       # 产物是「他宁可丢官」（1921-05 第四届工会代表大会，他没有念那份稿子）
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    #    绝不是同一块里写五个 focus！（照李可夫 / 加米涅夫 / 谢列布里亚科夫 / 普 / 拉 / 斯米尔加的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    #    E1 收束回【根】：`托姆斯基` 是他在逃亡路上给自己起的名字，
    #    而文案里的那句坐标又是他给自己定的位 —— 两件事都是「自己给自己定位」。
    # ⚠️ 美术上要写死：第六张图【不画枪、不画死亡】，画的是【一个名字的来历】（docs/53 §7.2 / docs/55）。
    @{ Id = 'hof_ic_tomsky_man_from_tomsk'; X = 0; Y = 7;
       P = @(@('hof_ic_tomsky_printers_union'),
             @('hof_ic_tomsky_moscow_trade_union_council'),
             @('hof_ic_tomsky_central_council_of_trade_unions'),
             @('hof_ic_tomsky_platform_of_ten'),
             @('hof_ic_tomsky_the_silence_of_1921'));
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.10',
             'stability_factor|_stability|0.10',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05') }
)

if ($tomskyLine.Count -ne 6) { throw "托姆斯基个人线应当是 6 条（5 节点 + 1 单结局），实际 $($tomskyLine.Count) 条" }

# =============================================================================
# ★ 里亚京个人线：5 条国策（单线 4 节点 + 1 单结局）—— docs/56 §3 / docs/57 §2
# -----------------------------------------------------------------------------
# 坐标【相对入口国策 hof_ic_seat_martemyan_ryutin】
#   P    前置。['__entry__'] = 挂在入口国策上；
#        ['A','B'] 同一块 = OR；[['A'],['B']] 多块 = AND（E1 用这个做「四个全完成」）
#   V    数值贡献："<modifier>|<变量后缀>|<增量>"
#        全部 add_to_variable 进 hof_ic_martemyan_ryutin_dm（个人数值容器）
#   Sync 完成时调一遍 sync_rank → 官衔分级重算
#
# ⭐⭐ 主干 = 【载体一级一级被拿走，他就换一个更小的地方接着说】：
#   A1 一份杂志（哈尔滨《斗争》+ 工人与士兵代表苏维埃）
#   → A2 一张报纸（红军机关报《红星报》副编辑）
#   → A3 一间摄影棚（Союзкино 首任主席 + 第一次全苏有声电影会议）
#   → A4 一叠手抄稿（160+ 页手稿 + 呼吁书）
#   → E1 一句不认罪的话（1936-11-04 审讯笔录）
# ⭐⭐ 首尾呼应：A1 是哈尔滨的一叠纸（一份杂志），E1 是笔录上的一叠纸 ——
#    中间三段载体一次比一次小，话一次也没有收回。
# ⚠️ 五条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 A4 = 【中文原文】（1932 年纲领的核心诉求，zh 维基〈柳廷事件〉）
#    🟡 A1/A2 = 【中译稿】（ru / zh 维基记述，⚠️ 需复核译文，docs/99 §十八）
#    🟡 A3 = 【机构条目】（ru 维基〈Союзкино〉，不需译）
#    🟡 E1 = 【英译再中译】（1936-11-04 审讯笔录，⚠️ 需复核译文）
# 出处：
#   A1 = ru / zh 维基（1917-09 – 12 哈尔滨）
#   A2 = ru / zh 维基（1928 秋任《红星报》副编辑）
#   A3 = ⭐ ru 维基〈Союзкино〉机构条目（1930-02-13 成立 / 理事会 7 人 / 1930-08 有声电影会议）
#        —— docs/23 §5 的方法，第 4 次收获
#   A4 = ⭐ zh 维基〈柳廷事件〉（中文原文）—— 只用纲领诉求的【后半句】
#        ⛔ 前半句（结束集体化 / 放缓工业化）是布哈林与李可夫的题（docs/56 §2.5）
#   E1 = en 维基（1936-11-04 审讯笔录，**英译再中译**）
# ⚠️ 【不引】「斯大林是革命的掘墓人 / 党和革命的邪恶天才」等 —— 把斯大林当主语
#    （项目口径：文案里不出现斯大林当主语，docs/44 §9.3 / docs/45 §8②）。
# ⚠️ 【不引】他 1924–1927 反托洛茨基 / 压会场 / 战斗队那一段 —— 与主干矛盾。
# =============================================================================
$ryutinPrefix = 'hof_ic_martemyan_ryutin'
$ryutinDmId   = 'hof_ic_martemyan_ryutin_dm'
$ryutinExtraHeaderTt = 'hof_ic_ryutin_extra_effects_tt'

$ryutinLine = @(

    # ---------------- 单线 · 载体一级一级被拿走（x = 0）----------------
    @{ Id = 'hof_ic_ryutin_struggle_magazine'; X = 0; Y = 1; P = @('__entry__');
       # 产物是「一份杂志 + 一个苏维埃」（1917-09/12 哈尔滨：境外同时握住报纸与政权）
       # ⚠️ 当年 12 月建政失败、被中国当局追捕逃回伊尔库茨克 —— 这正是「载体被拿走」的第一环
       V = @('political_power_factor|_political_power|0.05',
             'communism_drift|_communism_drift|0.05') }

    @{ Id = 'hof_ic_ryutin_red_star'; X = 0; Y = 2;
       P = @('hof_ic_ryutin_struggle_magazine');
       Sync = $true;    # 完成时官衔升到 Lv2：红军机关报《红星报》副编辑
       # 产物是「一张有印量的军队机关报」（1928 秋 – 1930-03）
       # ⚠️ 它是红军机关报 —— 所以影响的是军队，不是舆论
       V = @('army_org_factor|_army_org|0.05',
             'army_morale_factor|_army_morale|0.05') }

    @{ Id = 'hof_ic_ryutin_soyuzkino'; X = 0; Y = 3;
       P = @('hof_ic_ryutin_red_star');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联国家电影照相联合公司理事会主席
       # 产物是「一间国家摄影棚 + 有声电影生产」（1930-02 成立 / 1930-08 第一次全苏会议）
       V = @('boost_ideology_mission_factor|_boost_ideology_mission|0.05',
             'communism_drift|_communism_drift|0.05');
       Raw = @('unlock_decision_category_tooltip = hof_ic_cinema_category') }

    @{ Id = 'hof_ic_ryutin_union_of_marxist_leninists'; X = 0; Y = 4;
       P = @('hof_ic_ryutin_soyuzkino');
       # 产物是「一份手抄传出去的文件」（1932-05/08 的 160+ 页手稿与呼吁书）
       # ⭐ 文案用的是纲领诉求的后半句：把被开除的人都要回来
       V = @('drift_defence_factor|_drift_defence|0.05',
             'political_power_factor|_political_power|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 6）----------------
    # 🚩 四个节点【全部完成】才开门：P 写成四个并列的嵌套数组 = AND。
    #    绝不是同一块里写四个 focus！（照李可夫 / 加米涅夫 / 谢列布里亚科夫 / 普 / 拉 / 斯米尔加 / 托姆斯基的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐ E1 收束回【根】：他的姓就是他的村的名字。
    #    而文案是他在审讯笔录上那句「继续拒绝认罪」——
    #    ⭐ 两件事都是关于【名字】的：名字是村名给的，而他到最后也没在别人的名下签过字。
    # ⚠️ 美术上要写死：第五张图【不画枪、不画刑场、不画 1937 年】，画的是【那叠没有签字的笔录】（docs/57 §6）。
    @{ Id = 'hof_ic_ryutin_verkhne_ryutino'; X = 0; Y = 6;
       P = @(@('hof_ic_ryutin_struggle_magazine'),
             @('hof_ic_ryutin_red_star'),
             @('hof_ic_ryutin_soyuzkino'),
             @('hof_ic_ryutin_union_of_marxist_leninists'));
       V = @('political_power_factor|_political_power|0.10',
             'communism_drift|_communism_drift|0.10',
             'boost_ideology_mission_factor|_boost_ideology_mission|0.05',
             'drift_defence_factor|_drift_defence|0.05') }
)

if ($ryutinLine.Count -ne 5) { throw "里亚京个人线应当是 5 条（4 节点 + 1 单结局），实际 $($ryutinLine.Count) 条" }

# =============================================================================
# 施利亚普尼科夫（Idx 13）—— 单线 6 节点 + 1 单结局（docs/60 §2）
# 🚩🚩 **第三版**（第一版「工序归工位」、第二版「由干活的人选出来」都被用户否掉 —— docs/60 §1.0）。
# ⭐⭐ 主干 =「**国家把经济交给谁、怎么交**」—— 一条【权力移交的制度路径】
#    ⭐ 一句话：**别人做的是「在机关里往上爬」，他做的是「机关里的人从哪来」。**
# ⭐ 根 =「被人托付的那捆文件」（1904）—— ⚠️ 四国车间的个人经历**留作背景，不占节点**。
# ⭐⭐ 首尾呼应：**根是「别人把东西交到他手上」，E1 是「由他们推出来的机关」。**
# 🚩 时间轴上【整场十大（1921-03）让给托姆斯基】。
# -----------------------------------------------------------------------------
$shlyapnikovPrefix = 'hof_ic_aleksandr_shlyapnikov'
$shlyapnikovDmId   = 'hof_ic_aleksandr_shlyapnikov_dm'
$shlyapnikovExtraHeaderTt = 'hof_ic_shlyapnikov_extra_effects_tt'

$shlyapnikovLine = @(

    # ---------------- 单线 · 五个尺度，一级比一级大（x = 0）----------------
    @{ Id = 'hof_ic_shlyapnikov_workers_control'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：劳动人民委员（第一任）
       # 1917-10 起任第一任劳动人民委员
       # 产物 = ⭐ **一份【工人对工业的监督】的指令** ——
       #        ⭐⭐ **国家接管工业的第一步不是没收，是让工人先监督**（所有权不动，控制权先动）
       # ⭐ 这是整条制度路径的【起点】，不是一件个人的事。
       # ⚠️ 同期他还起草了【工业国有化】的指令 —— 两步合起来才是完整路径。
       # 🚩 **2026-09-19 用户口径「A2 删去」** → 原 A2「机关里坐着谁」整块移出，
       #    本线由「单线 6 节点 + 1 结局」变为「单线 5 节点 + 1 结局」。
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'political_power_factor|_political_power|0.05') }

    @{ Id = 'hof_ic_shlyapnikov_not_syndicalism'; X = 0; Y = 2;
       P = @('hof_ic_shlyapnikov_workers_control');
       # 1920-03-08/10 在 ВЦСПС 与 МГСПС 党团会议上，布哈林与克列斯廷斯基指责他
       #   「工团主义、行会狭隘性、对苏维埃与党的不信任」
       # 产物 = ⭐ **一条划线**：**他不否定国家，也不侵犯国家所有制**，
       #        他要求的只是「工会对经济负责」—— 洛佐夫斯基当场替他辩清了这一点。
       # ⭐ 制度命题：**是国家所有 + 工会执行，还是工会所有** —— 他把自己的位置划在了前者。
       # ⚠️ 这条划线让他与无政府工团主义彻底分开（他在法国时就反对过那一派）。
       V = @('political_power_factor|_political_power|0.05',
             'drift_defence_factor|_drift_defence|0.05') }

    @{ Id = 'hof_ic_shlyapnikov_producers_congress'; X = 0; Y = 3;
       P = @('hof_ic_shlyapnikov_not_syndicalism');
       # 1920-03 在全苏工会中央理事会共产党党团会议上提交提纲
       # 产物 = ⭐⭐⭐ **一条写进纲领的条文：管理机关【由生产者代表大会选出】**
       #   ⭐ 这是整条路径的【核心制度设计】—— 他争的不是位置，是**位置的产生方式**。
       #   ⚠️ 中央视之为工团主义（见 A3 的划线）。
       # ⭐ 与本项目的三处「机关线」都不重叠：李可夫 / 斯米尔加 / 沃兹涅先斯基做的是【机关的业务】。
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_shlyapnikov_through_the_workers'; X = 0; Y = 4;
       P = @('hof_ic_shlyapnikov_producers_congress');
       # 1920-12-30 他在扩大联席会议上的报告（工会问题辩论的开场）
       # 产物 = ⭐⭐ **一条路线**：经济政策「**是通过组织在工会里的工人群众呢，
       #          还是瞒着他们，用官僚手段**」—— 他把争论从「工会的任务」提到了【路线】的高度。
       # ⭐ 这句是本线台词里最锋利的一句，也是主干在【方法】上的表达。
       V = @('stability_factor|_stability|0.05',
             'political_power_factor|_political_power|0.05') }

    @{ Id = 'hof_ic_shlyapnikov_qualification_from_the_shop'; X = 0; Y = 5;
       P = @('hof_ic_shlyapnikov_through_the_workers');
       Sync = $true;    # 完成时官衔升到 Lv3：俄共（布）中央委员（1921 – 1922）
       # 1922-03 十一大：要求每个党的官员一年中至少三个月在工业或农业中从事体力劳动
       # 产物 = ⭐ **一条【任职资格】的提案**（不是一次车间劳动）：
       #        **要管生产的人，得先在生产里待够** —— 与主干同轴：机关的资格从哪来。
       # ⛔ 刻意避开 1921-03 十大（那场让给托姆斯基）；本条在 1922-03 十一大，不同年、不同动作
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    #    绝不是同一块里写五个 focus！（照李可夫 / 加米涅夫 / 谢列布里亚科夫 / 普 / 拉 / 斯米尔加 / 托姆斯基 / 里亚京的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐ E1 = 「由他们选出的机关」—— 收在【主干的原话】上：
    #    他一辈子要的就是那个机关 —— **由干活的人推出来的、管经济的那一个**。
    #    文案用《工人反对派提纲》里最完整的那句（⭐ 有《列宁全集》中文版第 32 卷第 187 页出处）。
    #    根与 E1 的呼应：开头顶在他手上的那捆文件是【别人交给他的】，
    #    最后他要的那个机关是【工人自己推出来的】。
    @{ Id = 'hof_ic_shlyapnikov_the_body_they_elect'; X = 0; Y = 7;
       P = @(@('hof_ic_shlyapnikov_workers_control'),
             @('hof_ic_shlyapnikov_not_syndicalism'),
             @('hof_ic_shlyapnikov_producers_congress'),
             @('hof_ic_shlyapnikov_through_the_workers'),
             @('hof_ic_shlyapnikov_qualification_from_the_shop'));
       V = @('political_power_factor|_political_power|0.10',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }
)

if ($shlyapnikovLine.Count -ne 6) { throw "施利亚普尼科夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($shlyapnikovLine.Count) 条" }

# -----------------------------------------------------------------------------
# ⭐ 加里宁（Idx 14）—— 单线 5 节点 + 1 单结局 = 6 块（docs/62 谱系 / docs/63 设计）
#   ⭐⭐⭐ 根 =「上特罗伊察的贫农头生子」（一个由别人出钱、用工厂的车间送出来的农家孩子）
#   ⭐⭐ 主干 =「**一个能被普通人找到的国家**」
#      一句话记法：**别人都在做「国家做什么」，他做的是「国家找不找得到」。**
#   ⚠️ 节点名按用户 2026-09-19 口径重取（docs/63 §8.1）：**要回答「这东西叫什么」**，
#      所以五个名字全是名词短语，其中三个直接是史料里的专名。
# -----------------------------------------------------------------------------
$kalininPrefix = 'hof_ic_mikhail_kalinin'
$kalininDmId   = 'hof_ic_mikhail_kalinin_dm'
$kalininExtraHeaderTt = 'hof_ic_kalinin_extra_effects_tt'

$kalininLine = @(

    # ---------------- 单线 · 五个尺度，一级比一级大（x = 0）----------------
    @{ Id = 'hof_ic_kalinin_a_peasant_head_of_state'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：全俄中央执行委员会主席（1919-03-30）
       # 1919-03-16 斯维尔德洛夫死于流感 → 03-25 中央全会以 7:4:2 表决 → 03-30 选举他接任 ВЦИК 主席
       # 产物 = ⭐⭐ **一条标准：国家元首可以由一个农民出身、能接近群众的人来当**
       #   ⭐ 列宁的推荐词（`[W]` ru 转引）：「他自己就是特维尔省的农民，与农民经济有密切联系……
       #      彼得格勒的工人已经看出，他具有接近广大劳动群众的本领」
       #   ⭐ 托洛茨基的中文原文：「加里宁……作为**接近中农并较了解他们疾苦的人**当选为中央执行委员会主席」
       # ⚠️ **两说并存**（提名是谁提的）→ **文案里不写谁提的名**（docs/62 §8.2）
       V = @('political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_kalinin_down_with_illiteracy'; X = 0; Y = 2;
       P = @('hof_ic_kalinin_a_peasant_head_of_state');
       # 1923 出任「扫除文盲」（Долой неграмотность）协会主席，协调全苏的教育工作
       # 产物 = ⭐⭐⭐ **1.1 万个扫盲点**；到 1930 年代末识字率逼近 90%（1939 年普查 87.4%）
       # ⭐ 制度命题：**路要通，先得让人能通信** —— 这是「国家找不找得到人」的前提
       V = @('research_speed_factor|_research_speed|0.05',
             'political_power_factor|_political_power|0.05',
             'training_time_factor|_training_time|-0.05') }

    @{ Id = 'hof_ic_kalinin_the_state_of_the_whole_people'; X = 0; Y = 3;
       P = @('hof_ic_kalinin_down_with_illiteracy');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联中央执行委员会主席（1922-12-30 起）
       # 1926 在苏联政治话语里【第一次】提出：无产阶级专政的国家应当逐步被「全民国家」取代
       # 产物 = ⭐⭐⭐ **一个理论提法** —— 它是 1936 年宪法（设立最高苏维埃）的理论前身；
       #   ⭐ 1938-01-17 他成为第一任最高苏维埃主席团主席（⚠️ 本文不断言因果，只记同一条线）
       # ⭐ 制度命题：**路通向的那个地方，得先说清属于谁** —— 从「工农的国家」到「全民的国家」
       V = @('drift_defence_factor|_drift_defence|0.05',
             'communism_drift|_communism_drift|0.05') }

    @{ Id = 'hof_ic_kalinin_the_reception_room'; X = 0; Y = 4;
       P = @('hof_ic_kalinin_the_state_of_the_whole_people');
       # 1920s–1940s：苏联公民习惯写信给他（被没收 / 被冤捕 / 想进军校 / 找不到工作），
       #   他常常亲自或通过秘书处帮忙。⚠️ 这不是单一年份的事件，是一条常设的制度。
       # 产物 = ⭐⭐⭐ **25 年间约 800 万人走过他的接待室**；「给加里宁写信」成了苏联公民的惯例
       #   ⭐ 中文维基独立确认了这一条（「不少人寫信給加里寧，而加里寧也常常介入審判」）
       # ⭐ 制度命题：**把「找得到国家」从一次次姿态做成一扇常开的门**
       V = @('political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_kalinin_an_unfounded_operation'; X = 0; Y = 5;
       P = @('hof_ic_kalinin_the_reception_room');
       Sync = $true;    # 完成时官衔升到 Lv4：苏联最高苏维埃主席团主席（1938-01-17）
       # 1932-05-04：政治局用「表决单征询」决定流放 38 000 户被逐出集体农庄的农民家庭，
       #   他在表决单上写了：「Я считаю необоснованной такую операцию.」
       # 产物 = ⭐⭐⭐ **两周后政治局撤销了自己的决定，停下了已经开始的操作**
       # ⚠️⚠️ **文案不能写成因果** —— 维基原文只说时间相邻（docs/62 §8.4 / docs/63 §5.2 纪律 ①）
       # ⭐ 制度命题：**一条通道，真在上面办成过一次**
       V = @('stability_factor|_stability|0.05',
             'political_power_factor|_political_power|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    #    绝不是同一块里写五个 focus！（照李可夫 / 加米涅夫 / 谢列布里亚科夫 / 普 / 拉 / 斯米尔加 / 托姆斯基 / 里亚京 / 施利亚普尼科夫的手法）
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐ E1 收在【别人给他的那个称呼】上：
    #    托洛茨基 1919 年给他起了 «всероссийский староста»（全俄的老家长），
    #    后来又变成 «всесоюзный староста»；民间叫他 «дедушка Калинин»（亲切的祖父加里宁）。
    #    ⚠️ **这个绰号是【托洛茨基给的】，文案里必须标明是别人给他起的。**
    # ⭐ E1 的文案用托洛茨基《斯大林评传》中文译本里那句：
    #    「……在铁路工厂罢工工人名单中有**苏维埃共和国未来的主席、锁匠加里宁**。」
    #    —— **「锁匠」与「未来的主席」放在同一个短语里，正是本线的全部**。
    @{ Id = 'hof_ic_kalinin_the_all_union_elder'; X = 0; Y = 7;
       P = @(@('hof_ic_kalinin_a_peasant_head_of_state'),
             @('hof_ic_kalinin_down_with_illiteracy'),
             @('hof_ic_kalinin_the_state_of_the_whole_people'),
             @('hof_ic_kalinin_the_reception_room'),
             @('hof_ic_kalinin_an_unfounded_operation'));
       V = @('communism_drift|_communism_drift|0.10',
             'stability_factor|_stability|0.10',
             'drift_defence_factor|_drift_defence|0.05',
             'political_power_gain|_political_power_gain|0.05') }
)

if ($kalininLine.Count -ne 6) { throw "加里宁个人线应当是 6 条（5 节点 + 1 单结局），实际 $($kalininLine.Count) 条" }

# -----------------------------------------------------------------------------
# 李维诺夫（Idx 15）个人线 —— 第 0-5 步见 docs/65，第 6 步设计见 docs/66
#   ⭐⭐⭐ 根 =「从基辅监狱翻墙出去的那个人」（1902）
#   ⭐⭐⭐ 主干 =「让一个不被承认的国家，被一个它被排除在外的体系接纳」
#          —— ⭐ 一句话：别人在国内做事，他一辈子做的只有一件 —— 让外面肯跟俄国签字
#   形状：单线 5 节点 + 1 单结局 = 6 块（x 全 = 0，y = 1,2,3,4,5,7）
#   🚩 节点名按判据 F 取名词短语；其中四个是史料里的专名（议定书 / 定义 / 条约 / 职务）
# -----------------------------------------------------------------------------
$litvinovPrefix = 'hof_ic_maksim_litvinov'
$litvinovDmId   = 'hof_ic_maksim_litvinov_dm'
$litvinovExtraHeaderTt = 'hof_ic_litvinov_extra_effects_tt'

$litvinovLine = @(

    # ---------------- 单线 · 五个尺度，一级比一级大（x = 0）----------------
    @{ Id = 'hof_ic_litvinov_a_courier_of_iskra'; X = 0; Y = 1; P = @('__entry__');
       # 1901 基辅委员会全体被捕 → 关押 18 个月 → 1902 与鲍曼组织 11 人越狱（绳索 + 抓钩翻墙）
       #   → 到日内瓦，普列汉诺夫亲自把他招为《火星报》代办员
       #   → 他建了一条把报纸从德国偷运进俄国的路线
       # 产物 = ⭐⭐⭐ **一条跨境通道**：把一件在境外合法、在俄国非法的东西送进去
       #   ⭐⭐ 这是【首尾同轴】的前半 —— E1 的对应物是「一份在莫斯科签不成的条约，
       #      最后欧洲先互相同意了」；方向相反，动作是同一个：**跨境**。
       V = @('political_power_factor|_political_power|0.05',
             'communism_drift|_communism_drift|0.05') }

    @{ Id = 'hof_ic_litvinov_the_prisoner_exchange_agreement'; X = 0; Y = 2;
       P = @('hof_ic_litvinov_a_courier_of_iskra');
       Sync = $true;    # 完成时官衔升到 Lv2：外交副人民委员（1921-05）
       # 1917-11-08 任苏俄驻英代表（非正式）→ 1918-09-16 被英国逮捕 → 换回布鲁斯·洛克哈特
       #   → 回莫斯科后进外交人民委员部理事会 → 被派往斯德哥尔摩 → 哥本哈根
       #   → **1920-02-12 签成英苏战俘交换协议**
       # 产物 = ⭐⭐⭐ **一份多国协议**；英文维基原话：「这次成功的谈判等于其他国家
       #   对新生的俄国政府的【事实承认】」
       # ⭐ 制度命题：**第一次让对方的【政府】坐到桌子对面**（不是让报纸过去，是让人过来）
       V = @('opinion_gain_monthly_factor|_opinion_gain_monthly|0.05',
             'improve_relations_maintain_cost_factor|_improve_relations_maintain_cost|-0.05') }

    @{ Id = 'hof_ic_litvinov_the_litvinov_protocol'; X = 0; Y = 3;
       P = @('hof_ic_litvinov_the_prisoner_exchange_agreement');
       Sync = $true;    # 完成时官衔升到 Lv3：外交人民委员（1930-07）
       # 1928 他力主苏联加入凯洛格-白里安公约（**与他的上司契切林的立场相反**）；
       #   但签约国迟迟不批准 → 他提议签一份「正式宣告自己遵守该公约目标」的议定书
       #   → **1929-02 在莫斯科签署**（苏、波、罗、拉脱维亚、爱沙尼亚，后有其他国家加入）
       # 产物 = ⭐⭐⭐⭐ **一份以他命名的多边文件**
       # ⭐ 制度命题：**一份没人执行的纸，怎么先变成一批国家之间的相互承诺**
       V = @('political_power_factor|_political_power|0.05',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.05') }

    @{ Id = 'hof_ic_litvinov_the_definition_of_aggression'; X = 0; Y = 4;
       P = @('hof_ic_litvinov_the_litvinov_protocol');
       Sync = $true;    # 完成时官衔升到 Lv4：驻国际联盟代表（1934）
       # 1933-02-06 他在裁军会议上作【生涯最重要的演说】，试图给「侵略」下定义：
       #   一国的内部状况、被指称的治理不善、对外国居民的潜在危险、邻国的内乱
       #   —— **都不是开战的理由**
       # 产物 = ⭐⭐⭐⭐ **一条国际法定义**
       # ⚠️⚠️ 本线【不写】后面那件事（他的定义后来被用来指控他自己的国家）——
       #   那是评价，不是他的产物（docs/65 §2.5）
       V = @('drift_defence_factor|_drift_defence|0.05',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.05') }

    @{ Id = 'hof_ic_litvinov_the_franco_soviet_treaty'; X = 0; Y = 5;
       P = @('hof_ic_litvinov_the_definition_of_aggression');
       # 1933-11 赴华盛顿谈成美苏建交；1934-1938 驻国联代表（促成苏联加入国联）；
       #   1935-05-02 苏法互助条约 + 1935-05-16 苏捷互助条约
       # 产物 = ⭐⭐⭐⭐ **两个大国的建交 + 两条互助条约**
       # ⭐ 制度命题：**有了尺子，下一步是把俄国放进那个拿尺子的房间**
       #
       # 🚩🚩 【本条的外交联动】—— 见 docs/66 §3.4
       #   ⚠️ 原版 `SOV_policy_of_collective_security` 完成时会调
       #      `SOV_apply_collective_ageement_on_mutual_assistance_effects_basic`
       #      （common/scripted_effects/SOV_scripted_effects.txt L3332），三件套 =
       #      non_aggression_pact + 双向 give_guarantee + 双向 add_opinion_modifier
       #      （SOV_policies_of_collective_security_opinion，value 50 / months 36）
       #   → ⛔ 本线【不照抄】那套（照抄＝重复原版）。
       #   ✅ 本线做原版【没有做】的那一半 —— **史实上的那条链子**：
       #      · 法国 = 完整三件套（互不侵犯 + 双向保障 + 双向好感 50）
       #      · 捷克 = ⭐ **只给好感 25，不给保障** —— 因为史实上 1935-05-16 的苏捷条约
       #        附有议定书：**只有【法国先履行援助义务】，捷克才有义务援助**。
       #        → 法国拿到保障、捷克只拿到好感，这就是那条链子。
       #      · 苏联自己 = ⛔ **不给任何军事加成** —— 史实上 1935 年条约【没有军事参谋协定】。
       #   ⚠️ `give_guarantee` 必须用 `if = { limit = ... }` 包住（照原版 FRA_franco_soviet_treaty
       #      的 available 挡 is_subject = no / has_war_with）
       V = @('opinion_gain_monthly_factor|_opinion_gain_monthly|0.05',
             'improve_relations_maintain_cost_factor|_improve_relations_maintain_cost|-0.05');
       Raw = @(
           'if = {',
           '`tlimit = {',
           '`t`tFRA = { is_subject = no  NOT = { has_war_with = ROOT } }',
           '`t}',
           '`tdiplomatic_relation = { country = FRA  relation = non_aggression_pact  active = yes }',
           '`tgive_guarantee = FRA',
           '`tadd_opinion_modifier = { modifier = hof_ic_franco_soviet_treaty  target = FRA }',
           '`tFRA = {',
           '`t`tdiplomatic_relation = { country = ROOT  relation = non_aggression_pact  active = yes }',
           '`t`tgive_guarantee = ROOT',
           '`t`tadd_opinion_modifier = { modifier = hof_ic_franco_soviet_treaty  target = ROOT }',
           '`t}',
           '}',
           'if = {',
           '`tlimit = { CZE = { exists = yes } }',
           '`tCZE = { add_opinion_modifier = { modifier = hof_ic_soviet_czech_treaty  target = ROOT } }',
           '}'
       ) }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐ E1 收在【他 1939 年之后的那个职务名】上（用户 2026-09-19 裁决取【乙】）：
    #    旧候选「国联的席位」被否 —— 理由是**二战国联已经实际失效**，拿一个失效的组织当结局名不合适。
    #    → 取 ⭐「外交人民委员会顾问」（1939-05 – 1941-11 他名下的正式职务）。
    #    ⭐ 这四个字就是全部分量：**九年的人民委员，换成了两个字**。
    #    ⭐⭐ 而它底下藏着的是「他还在」—— 1941-11 德国打进来之后，他被重新派了出去
    #       （驻美特命全权大使）。**结局是向上的，不是刑场。**
    @{ Id = 'hof_ic_litvinov_the_advisor_to_the_commissariat'; X = 0; Y = 7;
       P = @(@('hof_ic_litvinov_a_courier_of_iskra'),
             @('hof_ic_litvinov_the_prisoner_exchange_agreement'),
             @('hof_ic_litvinov_the_litvinov_protocol'),
             @('hof_ic_litvinov_the_definition_of_aggression'),
             @('hof_ic_litvinov_the_franco_soviet_treaty'));
       V = @('opinion_gain_monthly_same_ideology_factor|_opinion_same_ideology|0.10',
             'trade_opinion_factor|_trade_opinion|0.10',
             'improve_relations_maintain_cost_factor|_improve_relations_maintain_cost|-0.05',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.05') }
)

if ($litvinovLine.Count -ne 6) { throw "李维诺夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($litvinovLine.Count) 条" }

# -----------------------------------------------------------------------------
# 索柯里尼柯夫（Idx 16）个人线 —— 第 0-5 步见 docs/68，第 6 步设计见 docs/69
#   ⭐⭐⭐ 根 =「一个手里只有一张汇率表的人」（会六种语言，索邦读完法律与经济）
#   ⭐⭐⭐⭐ 主干 =「让一张印出来的纸，变成可以拿去算的钱」
#          —— ⭐ 一句话：**别人在争「拿多少」，他在争「什么算数」。**
#   形状：单线 5 节点 + 1 单结局 = 6 块（x 全 = 0，y = 1,2,3,4,5,7）
#   🚩 节点名按判据 F 取名词短语；其中四个是史料里的专名（突厥卢布 / 切尔沃涅茨 / 书名 / 术语）
#   🚩🚩 第 0 步（「原版专做过」第 6 次执行）：原版【把他写成了「被请回来的那个人」】——
#      国策 `SOV_the_need_for_policy_changes` 的描述就是「我们应该把索柯里尼柯夫同志请回来」，
#      图标是 `GFX_focus_hol_abandon_the_gold_standard`。
#      → ⛔ 本线不做「被请回来」，⛔ 不出现「金本位」字样
#        （⚠️ 且史实方向相反 —— 他恢复的是金准备）
#      ⭐ 这是「原版把某件事【替某人写成台词】」的第 2 例（第 1 例是里亚京 `SOV_liberate_ryutin`）
# -----------------------------------------------------------------------------
$sokolnikovPrefix = 'hof_ic_grigory_sokolnikov'
$sokolnikovDmId   = 'hof_ic_grigory_sokolnikov_dm'
$sokolnikovExtraHeaderTt = 'hof_ic_sokolnikov_extra_effects_tt'

$sokolnikovLine = @(

    # ---------------- 单线 · 五个尺度，一级比一级大（x = 0）----------------
    @{ Id = 'hof_ic_sokolnikov_the_nationalisation_of_the_banks'; X = 0; Y = 1; P = @('__entry__');
       # 1917-12 起接管俄国各银行（他 1917-11 起任国家银行临时副政委），并成一套集中的银行体系
       # 产物 = ⭐⭐⭐ **一套集中的银行体系**
       # ⭐ 制度命题：**先把所有的账拿到一个地方** —— 这是「什么算数」的前提
       V = @('political_power_factor|_political_power|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_sokolnikov_the_turkestan_rouble'; X = 0; Y = 2;
       P = @('hof_ic_sokolnikov_the_nationalisation_of_the_banks');
       # 1920 年在突厥斯坦：把当地贬得几乎不值钱的「突厥卢布」换成全苏货币；
       #   同一年当地的余粮收集制也先一步取消（比全国早）
       # 产物 = ⭐⭐⭐ **一个统一的本位**（先行一步：一小块地方先换完）
       # ⚠️ 本节点【不写】他 1921-1922 在突厥斯坦与当地领导层的冲突（docs/68 §2.5）
       V = @('stability_factor|_stability|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_sokolnikov_the_chervonets'; X = 0; Y = 3;
       P = @('hof_ic_sokolnikov_the_turkestan_rouble');
       Sync = $true;    # 完成时官衔升到 Lv2：财政人民委员（1922 秋）
       # 1922-11 国家银行发行切尔沃涅茨：法定等于十卢布的沙皇金币；
       #   **四分之一由金 / 贵金属 / 外汇保证，四分之三由易售商品与短期债券保证**
       # 产物 = ⭐⭐⭐⭐ **一张有准备的纸币**（史实专名）
       # ⭐ 制度命题：**一小块地方换完了，该换全国** —— 而这一次的纸背后有东西
       # ⭐ 文案引他本人 1922-06-30《俄国的物价下跌》原话（docs/69 §5）
       V = @('political_power_factor|_political_power|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05') }

    @{ Id = 'hof_ic_sokolnikov_what_a_dollar_costs'; X = 0; Y = 4;
       P = @('hof_ic_sokolnikov_the_chervonets');
       # 1923-01 他把两个交易所的数字排在同一张表上：一美元在柏林值多少马克、
       #   在莫斯科自由交易所值多少卢布 → **马克贬值的速度是卢布的 2 倍半**
       # 产物 = ⭐⭐⭐ **一个对外报价**（别人肯按这个价换）
       # ⭐ 制度命题：**换完了要能【对外】折算** —— 不去问自己值多少，去问别人换多少
       # 🚩🚩 【与李维诺夫（Idx 15）的界线由他自己那句话钉死】（docs/68 §2.4 #1）：
       #    「那些做纸币生意的国家，拒绝承认俄国纸币是它们家族的一员……
       #      正如欧洲各国政府拒绝『承认』苏维埃政府是一个政府。」
       #    → **李维诺夫争「政府肯不肯签字」，本线争「市场肯不肯认钱」。**
       V = @('resource_trade_cost_bonus_per_factory|_resource_trade_cost_bonus_per_factory|1',
             'trade_opinion_factor|_trade_opinion|0.05') }

    @{ Id = 'hof_ic_sokolnikov_state_capitalism'; X = 0; Y = 5;
       P = @('hof_ic_sokolnikov_what_a_dollar_costs');
       Sync = $true;    # 完成时官衔升到 Lv3：驻英国全权代表（1929-1932）
       # ⚠️ **松咬合**：史实上他去伦敦不是因为那句话，而是因为 1928-07 那次谈话事件。
       #    如实说明，不编因果（docs/69 §4.2）。
       # 1928 他自己的判断（书中原文）：「即使在私有财产原则占主导的国家，私营企业的
       #   无限竞争也在稳步退却，让位于巨大的金融和工业公司……在这种条件下，
       #   国家的不干涉政策将意味着国家权力的瘫痪。」
       # 产物 = ⭐⭐⭐ **一个判断**（也是他 1922 年那本书的名字）
       # ⭐ 制度命题：**钱稳住了之后，他发现光稳钱不够**
       # ⚠️ 用户 2026-09-20 口径：「国家资本主义就这么用吧」（这个词在中文语境有别的
       #    政治含义，但它确实是索柯里尼柯夫的书名，也是他自己的判断）
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **「硬通货」**（用户 2026-09-20 口径：原候选「从纸币到硬通货」改短）
    #    ⭐ 它同时是**他 1924 年的书名**《从纸币到硬通货》的落点 —— 也是主干的全程。
    #    ⭐⭐ 结局的份量落在巴扎诺夫那句【他人记述的原文】上：
    #       **「他完成了交给他的每一项任务 —— 例如创造了第一个稳定的苏联货币。」**
    # ⛔ 刻意不使用「金本位」三个字（原版图标已占，且史实方向相反 —— 他恢复的是金准备）
    @{ Id = 'hof_ic_sokolnikov_hard_currency'; X = 0; Y = 7;
       P = @(@('hof_ic_sokolnikov_the_nationalisation_of_the_banks'),
             @('hof_ic_sokolnikov_the_turkestan_rouble'),
             @('hof_ic_sokolnikov_the_chervonets'),
             @('hof_ic_sokolnikov_what_a_dollar_costs'),
             @('hof_ic_sokolnikov_state_capitalism'));
       V = @('resource_trade_cost_bonus_per_factory|_resource_trade_cost_bonus_per_factory|1',
             'stability_factor|_stability|0.10',
             'consumer_goods_factor|_consumer_goods|-0.05',
             'trade_opinion_factor|_trade_opinion|0.05') }
)

if ($sokolnikovLine.Count -ne 6) { throw "索柯里尼柯夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($sokolnikovLine.Count) 条" }

# -----------------------------------------------------------------------------
# 图哈切夫斯基（Idx 17）个人线 —— 第 0-5 步见 docs/71，第 6 步设计见 docs/72
#   ⭐⭐⭐ 根 =「一个手里只有别人的一本野战手册的军团长」（1919）
#   ⭐⭐⭐⭐ 主干 =「把分散的构想，凭职权整合成全军必须照着执行的条令」
#          —— ⭐ 一句话：**别人想出来的东西，是他让它变成条令的。**
#   形状：单线 5 节点 + 1 单结局 = 6 块（x 全 = 0，y = 1,2,3,4,5,7）
#   🚩 节点名按判据 F 取名词短语；其中三个是史料里的专名（四个梯次 / 工农红军野战条令 / 正规军）
#   ⭐⭐ 首尾同轴：根是他手里只有【别人的】一本野战手册；
#      E1 是那本野战手册【由他署名】、全军照着它组织与训练 —— 同一本东西，换了署名的人。
# -----------------------------------------------------------------------------
$tukhachevskyPrefix = 'hof_ic_mikhail_tukhachevsky'
$tukhachevskyDmId   = 'hof_ic_mikhail_tukhachevsky_dm'
$tukhachevskyExtraHeaderTt = 'hof_ic_tukhachevsky_extra_effects_tt'

$tukhachevskyLine = @(

    # ---------------- 支线 A · 把仗怎么写（x = 0）----------------
    # ⭐ 2026-09-20 用户口径「图哈切夫斯基看起来是能单加一条线的样子」
    #    → 本线由【单线】改为【两条支线】：
    #    A 支线 = 把「怎么打」写成令（五个尺度，一级比一级大）
    #    B 支线 = 把「能拿出多少」算成账（x = +2，见本块末尾）
    @{ Id = 'hof_ic_tukhachevsky_the_military_academy'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：红军参谋长（1925-11）
       # 1921-08-27 任由总参谋学院改名而来的工农红军军事学院院长
       # 产物 = ⭐⭐⭐ **一所学院的教学大纲**（教谁）
       # ⭐ 制度命题：**要写出该读的东西，先得有个教人的地方**
       # ⭐ 数值（判据 I）：这个节点【没有全值词条可选】—— 学院能给的只有学说成本、
       #    军官成本、经验、训练时间，**全是半值/小值** → 只能【用四条 + 倍数补】（≈2.5 个全值）
       V = @('land_doctrine_cost_factor|_land_doctrine_cost|-0.10',
             'military_leader_cost_factor|_military_leader_cost|-0.10',
             'experience_gain_army_factor|_experience_gain_army|0.05',
             'training_time_factor|_training_time|-0.05') }

    @{ Id = 'hof_ic_tukhachevsky_the_regular_army'; X = 0; Y = 2;
       P = @('hof_ic_tukhachevsky_the_military_academy');
       # 1930-01 他提出部队改革建议：反对民兵制、要求建立一支正规军；
       #   并要求增加战车和飞机的产量、**削减骑兵单位**
       #   → ⭐ 这使他与**伏罗希洛夫和布琼尼**产生矛盾（正是 R1 历史交恶的那一对）
       # 产物 = ⭐⭐⭐ **一份部队改革方案**（谁来当兵）
       # 🚩🚩 【与托洛茨基（Idx 1）的界线由史实钉死】：
       #    ⭐ **托洛茨基建了红军；他把它改成正规军。**
       # ⚠️⚠️ 本节点【不写】第 5 军团（那是斯米尔诺夫 Idx 6 的）—— 只讲编制，不讲番号
       # ⚠️ 1930-04 他致信斯大林被拒、伏罗希洛夫在会上宣读回信那一段
       #    **不进游戏**（项目口径：文案里不出现斯大林当主语）→ 留档在 docs/71
       V = @('conscription|_conscription|0.02',
             'army_morale_factor|_army_morale|0.10',
             'army_defence_factor|_army_defence|0.05') }

    @{ Id = 'hof_ic_tukhachevsky_airborne_and_tanks'; X = 0; Y = 3;
       P = @('hof_ic_tukhachevsky_the_regular_army');
       Sync = $true;    # 完成时官衔升到 Lv3：国防第一副人民委员（1931-06）
       # 1931 年组建**世界上第一支伞兵部队**；战车依任务划分为
       #   **直接支援步兵 / 远程支援 / 远程突击** 三类编组（分别配轻型、中重型、高速战车）
       # 产物 = ⭐⭐⭐ **两样全新的编制**（拿什么打）
       # ⭐ 制度命题：**光有人还不够，条令要的那种兵器得真的造出来**
       # 2026-09-26 用户改定：三类坦克底盘可靠性 +10%，对应坦克营组织度 +5 点；
       #   空降后组织度 +100%。晋升 Lv3 的 Sync 保持原样。
       # 平面组织度 +5 点用仅国策授予的科技（见 common/technologies/hof_ic_tukhachevsky.txt）；
       # 装备可靠性用原版 add_equipment_bonus，已有设计立即生效。
       V = @('paradrop_organization_factor|_paradrop_organization|1.0',
             'no_supply_grace|_no_supply_grace|48');
       Raw = @(
           'add_equipment_bonus = {',
           '`tname = hof_ic_tukhachevsky_airborne_and_tanks',
           '`tbonus = {',
           '`t`tlight_tank_chassis = { reliability = 0.10 instant = yes }',
           '`t`tmedium_tank_chassis = { reliability = 0.10 instant = yes }',
           '`t`theavy_tank_chassis = { reliability = 0.10 instant = yes }',
           '`t}',
           '}',
           'custom_effect_tooltip = hof_ic_tukhachevsky_tank_org_tt',
           'hidden_effect = { set_technology = { hof_ic_tukhachevsky_tank_org_tech = 1 popup = no } }'
       ) }

    @{ Id = 'hof_ic_tukhachevsky_the_deep_battle_instructions'; X = 0; Y = 4;
       P = @('hof_ic_tukhachevsky_airborne_and_tanks');
       # 《纵深战斗组织临时指示》1933 → 《纵深战斗指示》1935 —— 先在部队里试着执行
       # 产物 = ⭐⭐⭐ **一份先在部队里试的指示**（怎么练）
       # ⭐ 制度命题：**有了人、有了兵器，就可以先在部队里试一遍**
       # ⭐ 数值（判据 I）：陆军进攻 +5%。
       V = @('army_attack_factor|_army_attack|0.05',
             'breakthrough_factor|_breakthrough|0.05',
             'supply_consumption_factor|_supply_consumption|-0.05',
             'no_supply_grace|_no_supply_grace|48');
       # 🚩🚩 【本条带一段自定义脚本】—— 用户 2026-09-20 批准（docs/72 §8 ⑦）
       #   `add_mastery` 给【大纵深】子学说加掌握度。
       #   ⭐ 为什么能做：`deep_battle` 在 HOI4 1.19 里已经是一条子学说，苏联开局就带，
       #      但 **原版【没有任何国策/事件】给过它掌握度** —— 这个口子空着。
       #   ✅ 合法性已实测：`add_mastery` 是原版**大量使用**的国策奖励效果
       #      （national_focus/germany.txt 28 处 / china_communist_sea.txt 42 处 /
       #       australia_taog.txt 11 处 …，另有 decisions/ · events/ 在用）。
       #   ⚠️ 本项目首次使用 → 若启动后 error.log 报错，**撤这一行即可**
       Raw = @(
           'add_mastery = {',
           '`tamount = 100',
           '`tsub_doctrine = deep_battle',
           '}'
       ) }

    @{ Id = 'hof_ic_tukhachevsky_the_four_echelons'; X = 0; Y = 5;
       P = @('hof_ic_tukhachevsky_the_deep_battle_instructions');
       Sync = $true;    # 完成时官衔升到 Lv4：苏联元帅（1935-11）
       # ⚠️ **松咬合**：授元帅是 1935-11，条令定稿是 1936 —— 如实说明，不编因果（docs/72 §4.2）
       # 1936 条令里那条作战分层：**进攻须以四个梯次同时打击敌军纵深**
       #   ① 航空兵先夺制空权并轰炸敌阵地 ② 战车+步兵+火炮的诸兵种合成突击集群突破
       #   ③ 机械化部队向纵深扩张战果、包围敌军与后方要地 ④ 预备队负责巩固所得
       # 产物 = ⭐⭐⭐ **一条作战的层级结构**（怎么打）
       # ⭐ 制度命题：**试出来的打法，得有一条说清楚的结构**
       V = @('army_attack_factor|_army_attack|0.05',
             'army_defence_factor|_army_defence|0.05',
             'supply_consumption_factor|_supply_consumption|-0.05',
             'attrition|_attrition|-0.05',
             'no_supply_grace|_no_supply_grace|48') }

    # ---------------- 支线 B · 把账怎么算（x = +2）----------------
    # ⭐ 2026-09-20 用户口径（逐字）：「图哈切夫斯基看起来是能单加一条线的样子」＋
    #    「军事经济动员我认为可以写，因为它的实际内容是估算红军规模，而不是游戏内其他内容的动员人民」。
    # 🚩 主干扩写（docs/91 §2.6）：原主干只说了「条令」那一半；B 支线是**同一动作的另一半** ——
    #    ⭐ **凭职权，把分散的东西整合成一份正式的东西：军队照着它打（条令），国家照着它备（账）。**
    # 🚩 与托洛茨基（Idx 1）`hof_ic_trotsky_state_planning`「经济计划化」的界线：
    #    托问「**谁来管国有经济的计划**」（民用经济的计划机关）；本线问「**打起来能拿出多少**」。
    # 🚩 与斯米尔加（Idx 10，国家计委 / 生产力布局）的界线：他做的是**全国生产力的地理布局**（民用、远景）；
    #    本线做的是**军事动员的估算**。⚠️ 图哈只排掉 1 人（伏罗希洛夫）→ **斯米尔加能同席 → 界线写死**。
    # 🚩 与沃兹涅先斯基（Idx 18，战时经济 / 疏散安置）的界线：
    #    他做的是**战时的实际兑现**（1941-08-07 之后）；本线做的是**战前的纸面估算**（1926–1931）。
    # 🚩 与 A3「空降兵与战车」的界线：A3 = **具体的兵种**（第一支伞兵部队 / 战车三类编组）；
    #    B3 = **跨兵种的构想与规划方法**。
    # ⛔ 刻意不做：**义务兵役法 / 军区制 / K1–K14 级别制** —— 那是**伏龙芝主持的 1924–1925 军事改革**的产物
    #    （他当时只是伏龙芝的副手）→ **判据 B 不过**；且「从志愿兵制转入义务兵制」托洛茨基已占。
    #    ⛔ 火箭与化学武器（涉密 / 黑历史）· ⛔ 审判 / 枪决 / 1937 / 平反（全项目禁区）。
    # ✅ 判据 K（22 578 条原版 / DLC / R56 中文国策名）：
    #    「联盟国防」**0** · 「军事经济动员」**0** · 「空中机械化」**0**；
    #    ⛔「国防准备」完全相同（GRE_rival_germany）· ⛔「动员准备」/「国防动员」/「动员计划」全部完全相同。
    @{ Id = 'hof_ic_tukhachevsky_the_defence_of_the_union'; X = 2; Y = 1; P = @('__entry__');
       # 1926-12-26 报告《苏维埃社会主义共和国联盟的国防》—— 他是工农红军参谋长，报告署名就是他
       # 产物 = ⭐⭐⭐ **一份国防动员准备度的诊断**（国家到底拿得出多少）
       # ⭐ 制度命题：**要写出该读的令，先得知道家底够不够**
       # ⚠️ 报告原文 8 条，此处取第 6/7/8 三条 —— 一手件俄文原文（本项目转译，不冒充中文原文）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'war_support_factor|_war_support|0.05') }

    @{ Id = 'hof_ic_tukhachevsky_military_economic_mobilization'; X = 2; Y = 2;
       P = @('hof_ic_tukhachevsky_the_defence_of_the_union');
       # 1930-01 **同一份部队改革方案的【经济面】**：按工业化后的「生产可能性」重新估算红军规模，
       #   而非沿用传统的逐年递增方式；从汽车与拖拉机的产能推算飞机与战车的产能。
       #   （同一份方案的【组织面】「反对民兵制、要求建立正规军」在 A2 —— 一份方案，两个面。）
       # 产物 = ⭐⭐⭐ **一套按生产能力反推军队规模的算法**（需要造多少）
       # ⭐ 制度命题：**知道缺什么之后，得算清楚要造多少**
       V = @('production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_tukhachevsky_air_mechanization'; X = 2; Y = 3;
       P = @('hof_ic_tukhachevsky_military_economic_mobilization');
       # 1931 他提出「空中机械化」构想：把航空、战车、无线电与化学战整合为一体；
       #   并主张「完全以新的方式对待整个武器系统、组织、战术和部队训练的规划」。
       # 产物 = ⭐⭐⭐ **一套把新兵器当成一个整体来规划的方法**（算出来的东西要合成什么）
       # ⭐ 制度命题：**数字有了，得先说清它们要合成一件什么东西**
       # 🚩 与 A3 的界线：A3 = 具体的兵种；本节点 = 跨兵种的构想与规划方法
       V = @('breakthrough_factor|_breakthrough|0.05',
             'initiative_factor|_initiative|0.05');
       # 专属 MIO 装备特质由 gen-hof-ic-mio.py 定义；完成时四家组织分别取得对应加成。
       Raw = @('hof_ic_tukh_mio_air_mechanization = yes') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 **P 写成【平铺】两条 = OR** —— 走通【任一条支线】即可开门（照季诺维也夫的汇合层写法）。
    #    A 支线走到头 = 四个梯次；B 支线走到头 = 空中机械化。
    #    ⭐ 为什么是 OR 而不是 AND：**条令与账本是同一件事的两面** ——
    #    玩家可以「先写令、顺着战场那半走到底」，也可以「先把账算清、顺着资源那半走到底」。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **工农红军野战条令**（1936 PU-36 的正式中文名）—— 史实专名 + 名词短语（判据 F 过）
    #    ⭐⭐ 首尾同轴：**根是他手里只有【别人的】一本野战手册；
    #       E1 是那本野战手册【由他署名】、全军照着它组织与训练**。
    #    ⚠️ 宗旨那句（「使其在其部署的全纵深遭到歼灭、包围并歼灭」）是
    #       **中文维基转引的条令宗旨** —— 文案里标注写清是转引（docs/72 §5）
    # ⛔ 全文案不出现：他属于哪个派别 / 审判 / 枪决 / 1937 / 平反 /
    #    第 5 军团 / 华沙战役 / 坦波夫 / 喀琅施塔得 / 「斯大林」当主语
    @{ Id = 'hof_ic_tukhachevsky_the_field_regulations'; X = 0; Y = 7;
       P = @('hof_ic_tukhachevsky_the_four_echelons',          # A 支线走到头
             'hof_ic_tukhachevsky_air_mechanization');         # 或 B 支线走到头
       V = @('army_attack_factor|_army_attack|0.10',
             'breakthrough_factor|_breakthrough|0.10',
             'army_defence_factor|_army_defence|0.05',
             'army_morale_factor|_army_morale|0.05',
             'no_supply_grace|_no_supply_grace|48') }
)

if ($tukhachevskyLine.Count -ne 9) { throw "图哈切夫斯基个人线应当是 9 条（两条支线 5+3 节点 + 1 单结局），实际 $($tukhachevskyLine.Count) 条" }

# =============================================================================
# ★ 沃兹涅先斯基个人线：6 条国策（单线 5 节点 + 1 单结局）—— docs/74 §2 / docs/75 §2
# -----------------------------------------------------------------------------
# 坐标【相对入口国策 hof_ic_seat_nikolay_voznesensky】
#   P    前置。['__entry__'] = 挂在入口国策上；
#        ['A','B'] 同一块 = OR；[['A'],['B']] 多块 = AND（E1 用这个做「五个全完成」）
#   V    数值贡献："<modifier>|<变量后缀>|<增量>" → add_to_variable 进 hof_ic_nikolay_voznesensky_dm
#   Sync 完成时调一遍 sync_rank → 官衔分级重算
#
# ⭐⭐⭐ 根 =「计划是同自发势力作斗争，不是同它结合」（1931-10-08）
#   —— 他自己写的（中文马克思主义文库有他的篇目页，4 篇，全部 1931–1934）。
#   「社会主义计划是在斗争中而不是在同小资产阶级自发势力和由它产生的
#     资本主义因素的结合中发挥作用的。」
#   同篇还把「迁就现实」与「凭空乱写」一起封掉：
#   「同轻率地作空头『计划』的癖好和过火行为作斗争也是必要的。」
# ⭐⭐⭐⭐⭐ 主干 =「把『拿得出多少』变成一切决定的依据」
#   一句话记法：**别人在争「要多少」，他只回答「有多少」。**
#   五个尺度：写下立场 → 一张市里的表 → 一张全国的表 → 表在战争里被重排
#             → 表开始决定战役 → 给那个时代的经济命名
#   ⭐⭐ 首尾同轴：根 = 一个 27 岁教员在《真理报》上写下的立场；
#      E1 = 一个国家在只剩一半工业区时，按「有多少」把战争打完。
# ⚠️ 文案档次（本次已升到 4/6）：
#    🟢 A1 = 【中文原文】（他自己 1931-10-08 的《真理报》文章）
#    🟢 A4 / A5 / E1 = 【本人著作节选】（《苏联战时经济》1947，
#       据 1948 年 Foreign Languages Publishing House 官方英译本【本项目转译】）
#       ⚠️ 中译本 =《卫国战争期内的苏联战时经济》（外国文书籍出版社 1948）—— 电子全文不可得
#    🟡 A2 / A3 = 【中译稿】（ru 维基记述）
# =============================================================================
$voznesenskyPrefix = 'hof_ic_nikolay_voznesensky'
$voznesenskyDmId   = 'hof_ic_nikolay_voznesensky_dm'
$voznesenskyExtraHeaderTt = 'hof_ic_voznesensky_extra_effects_tt'

$voznesenskyLine = @(

    # ---------------- 单线 · 一张表越做越大（x = 0）----------------
    @{ Id = 'hof_ic_voznesensky_the_fight_for_the_plan'; X = 0; Y = 1; P = @('__entry__');
       # 1931-10-08《真理报》署名文章《为实现当前阶段的计划而斗争》
       # 产物 = 一篇论【整个苏联计划方法】的署名主张（**全国尺度** —— 判据 C 过）
       # ⭐ 他的 4 篇中文原文全部在这个时期（1931–1934）→ 全线唯一的中文原文节点
       # ⭐ 数值（判据 I）：本节点讲「一种立场」，没有单一全值词条 → 用四条半值补额度
       V = @('production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_voznesensky_the_leningrad_plan'; X = 0; Y = 2;
       P = @('hof_ic_voznesensky_the_fight_for_the_plan');
       Sync = $true;    # 完成时官衔升到 Lv2：苏联国家计划委员会主席（1938-01-19）
       # 1935–1937 列宁格勒市计划委员会主席 + 列宁格勒市苏维埃执委会副主席
       # 产物 = 他亲手做的【第一张表】（机构专名）
       # ⚠️ 一处两说：en 维基作「head of the Leningrad Control Commission」
       #    → ⭐ 取 ru 的【市计划委员会主席】（与他一生的主题一致；en 那个是误译）
       # ⚠️ ⛔ 不写「他因为大清洗腾出的位子才上升」（那是别人替他做的事）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10') }

    @{ Id = 'hof_ic_voznesensky_the_state_planning_committee'; X = 0; Y = 3;
       P = @('hof_ic_voznesensky_the_leningrad_plan');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联人民委员会第一副主席（1941-03-10）
       # 1938-01-19 起任苏联国家计划委员会主席（前任梅日劳克被捕后接任）；
       #   1942-12-08 再任（至 1949-03-05）
       # 产物 = 一张全国的表（机构专名；他 34 岁）
       # ⚠️ 【不写】他 1939–1941 主张的「建立巨大的原料、燃料、冶金与生产储备」
       #    —— 原版 `SOV_increase_state_reserves`「增加国家资源储备」已占（描述几乎就是他的原话）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }

    @{ Id = 'hof_ic_voznesensky_the_placement_of_plants'; X = 0; Y = 4;
       P = @('hof_ic_voznesensky_the_state_planning_committee');
       Sync = $true;    # 完成时官衔升到 Lv4：苏联部长会议第一副主席（1946-03-19）⚠️ 松咬合
       # 1941-08-07 国防委员会第 421 号决议《关于安置被疏散企业的程序》：
       #   把保障工业疏散与动员交给国家计委；各人民委员部【必须与国家计委协商】
       #   确定工厂的【最终落脚点】并组织【重复生产】（дублирующие производства）
       # 产物 = 一张「哪个厂到哪里去」的安置表 + 重复生产（史实专名）
       # 🚩🚩 与原版 `SOV_move_industry_to_the_urals` 的界线：原版做的是【搬】，
       #    本线做的是【决定往哪搬、以及为什么在那里再造一个】
       # ⚠️ ⛔ 不写「他主持了疏散委员会」—— 疏散委员会主席是卡冈诺维奇
       # ⛔ 不画/不写乌拉尔山脉、铁路、火车（原版招牌 + 斯米尔诺夫母题）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.10',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }

    @{ Id = 'hof_ic_voznesensky_the_ammunition_plan'; X = 0; Y = 5;
       P = @('hof_ic_voznesensky_the_placement_of_plants');
       # 1941–1942 被任命为国防委员会负责「工业完成弹药生产计划」的全权代表
       #   （副手 М. З. 萨布罗夫）；1942-02 超补为国防委员会（ГКО）委员
       # 产物 = 弹药的生产计划（职务专名）
       # ⭐ 文案用【他自己书里的数字】（《苏联战时经济》第十三章「生产的计划化」）
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05');
       # 图拉是既有军工中心；失去图拉后转到仍受控的苏联核心州，避免奖励落空。
       Raw = @(
           'if = {',
           '`tlimit = { 223 = { is_owned_by = ROOT is_controlled_by = ROOT } }',
           '`t223 = {',
           '`t`tadd_extra_state_shared_building_slots = 1',
           '`t`tadd_building_construction = { type = arms_factory level = 1 instant_build = yes }',
           '`t}',
           '}',
           'else = {',
           '`trandom_owned_controlled_state = {',
           '`t`tlimit = { is_core_of = ROOT }',
           '`t`tadd_extra_state_shared_building_slots = 1',
           '`t`tadd_building_construction = { type = arms_factory level = 1 instant_build = yes }',
           '`t}',
           '}'
       ) }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **苏联战时经济**（他 1947 年那本书的书名；中译本 =《卫国战争期内的苏联战时经济》，
    #   外国文书籍出版社 1948）—— 【史实专名 + 名词短语】（判据 F 过）
    #   🔴🔴 **不叫「战时经济」**：原版 `SOV_war_economy` 的中文名就是它。
    # ⭐⭐ 首尾同轴：根 = 一个 27 岁教员在《真理报》上写下的立场；
    #   E1 = 一个国家在只剩一半工业区时，按「有多少」把战争打完。
    # ⛔ 全文案不出现：列宁格勒案件 / 审判 / 处决 / 1949–1950 / 平反 / 原子能 /
    #    乌拉尔 / 储备 / 「斯大林」当主语（项目口径，docs/44 §9.3）
    @{ Id = 'hof_ic_voznesensky_the_war_economy'; X = 0; Y = 7;
       P = @(@('hof_ic_voznesensky_the_fight_for_the_plan'),
             @('hof_ic_voznesensky_the_leningrad_plan'),
             @('hof_ic_voznesensky_the_state_planning_committee'),
             @('hof_ic_voznesensky_the_placement_of_plants'),
             @('hof_ic_voznesensky_the_ammunition_plan'));
       V = @('industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }
)

if ($voznesenskyLine.Count -ne 6) { throw "沃兹涅先斯基个人线应当是 6 条（5 节点 + 1 单结局），实际 $($voznesenskyLine.Count) 条" }

# =============================================================================
# 彼得·斯米尔诺夫（Idx 19）· 单线 5 节点 + 1 单结局 = 6 块
#   ⚠️ 命名空间用 `hof_ic_pyotr_smirnov`（**不是** `hof_ic_smirnov`）——
#      后者是**伊万·斯米尔诺夫（Idx 6）**的（同名不同人，docs/38 的教训）。
#   字段含义见上面托洛茨基那一段的注释；Sync = 完成时调 sync_rank。
# =============================================================================
$pyotrSmirnovPrefix = 'hof_ic_pyotr_smirnov'
$pyotrSmirnovDmId   = 'hof_ic_pyotr_smirnov_dm'
$pyotrSmirnovExtraHeaderTt = 'hof_ic_pyotr_smirnov_extra_effects_tt'

$pyotrSmirnovLine = @(

    # ---------------- 单线 · 一件件从陆军拿回来（x = 0）----------------
    @{ Id = 'hof_ic_pyotr_smirnov_the_naval_directorate'; X = 0; Y = 1; P = @('__entry__');
       # 1926-01 – 1928-04 波罗的海舰队政治部主任（革命军事委员会委员）
       # 产物 = 他站到舰队上的那一刻的【机构形态】：海军只是「工农红军海军局」
       # ⭐ 这就是【根】：1926 年的海军在公文里还只是一个「局」
       # ⚠️ 不出「政治委员 / 政治机关怎么建」这个题（用户 2026-09-17 已砍，docs/41 §304）
       V = @('navy_leader_cost_factor|_navy_leader_cost|-0.10',
             'naval_coordination|_naval_coordination|0.05',
             'navy_org_factor|_navy_org|0.05') }

    @{ Id = 'hof_ic_pyotr_smirnov_the_general_staff'; X = 0; Y = 2;
       P = @('hof_ic_pyotr_smirnov_the_naval_directorate');
       Sync = $true;    # 完成时官衔升到 Lv2：工农红军政治部主任（1937-06-15）⚠️ 门槛早于节点 → 松咬合
       # 1937-12-30 同一份决议成立【海军总参谋部】—— 部的作战指挥机关
       # 产物 = 一个作战指挥机关（机构专名）
       # ⛔ 不写「第一个五年计划 / 第二个五年计划」（原版已占）
       V = @('navy_org_factor|_navy_org|0.05',
             'navy_max_range_factor|_navy_max_range|0.10',
             'naval_coordination|_naval_coordination|0.05') }

    @{ Id = 'hof_ic_pyotr_smirnov_the_naval_aviation'; X = 0; Y = 3;
       P = @('hof_ic_pyotr_smirnov_the_general_staff');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联国防副人民委员（1937-09）
       # 1938-01-01 海军航空兵脱离空军建制，并入海军
       # 产物 = 一个【兵种】从别人手里拿回来
       V = @('naval_strike_attack_factor|_naval_strike_attack|0.05',
             'navy_org_factor|_navy_org|0.05',
             'naval_coordination|_naval_coordination|0.05');
       # 黑海舰队基地克里米亚优先；失控或机场满级时转到北方舰队基地摩尔曼斯克。
       Raw = @(
           'if = {',
           '`tlimit = { 137 = { is_owned_by = ROOT is_controlled_by = ROOT air_base < 10 } }',
           '`t137 = { add_building_construction = { type = air_base level = 1 instant_build = yes } }',
           '}',
           'else_if = {',
           '`tlimit = { 213 = { is_owned_by = ROOT is_controlled_by = ROOT air_base < 10 } }',
           '`t213 = { add_building_construction = { type = air_base level = 1 instant_build = yes } }',
           '}'
       ) }

    @{ Id = 'hof_ic_pyotr_smirnov_the_declaration'; X = 0; Y = 4;
       P = @('hof_ic_pyotr_smirnov_the_naval_aviation');
       # 1938-02-03 他在《真理报》上公开了建设远洋海军的思想
       # 产物 = 一份【向全国公开的建军宣示】（节点名 = 建军宣示）
       # ⚠️ 「远洋海军」这个词可以出现在文案里（与原版 `SOV_an_oceangoing_navy` =「蓝水海军」不同名，
       #    用户 2026-09-20 口径），但【节点名不用它】—— 节点名取的是那份宣示本身
       # ⛔ 节点名不用「第三个五年计划」（原版 `SOV_third_five_year_plan` 同名）
       V = @('navy_max_range_factor|_navy_max_range|0.05',
             'industrial_capacity_dockyard|_industrial_capacity_dockyard|0.05',
             'navy_leader_cost_factor|_navy_leader_cost|-0.05') }

    @{ Id = 'hof_ic_pyotr_smirnov_the_military_council'; X = 0; Y = 5;
       P = @('hof_ic_pyotr_smirnov_the_declaration');
       # 1938 海军总军事委员会成立，他任主席（成员：加列尔 / 日丹诺夫 / 伊萨科夫 / 库兹涅佐夫 / 列夫琴科）
       # 产物 = 部的【议事机关】
       # ⚠️ 一处两说：中文维基作 1938-03-13，俄文维基作 **1938-04-23** → 取 ru（附成员名单，更权威）
       V = @('naval_coordination|_naval_coordination|0.10',
             'navy_leader_cost_factor|_navy_leader_cost|-0.05',
             'navy_org_factor|_navy_org|0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **海军人民委员部**（1937-12-30 成立，他是第一任人民委员）
    #   ⚠️ 原版 `SOV_pc_of_the_ussr_navy` 的中文名【完全相同】——
    #      但用户 2026-09-20 口径：「**名字不是完全相同就可以**」+「甲也可以用」→ 取甲。
    #      原版那条做的只是「加一个动态民族精神（改装 −5% / 维修 +5%）」，
    #      与本线「这个部怎么被争来的」机制毫不相干。
    #   ⭐ 文案 = **1937-12-30 决议原文节选**（一手件，本项目据俄文原文转译）
    # ⭐⭐ 首尾同轴：根 = 海军只是一个「局」（1926）；E1 = 海军是一个「部」（1937-12-30）。
    # ⛔ 全文案不出现：大清洗 / 被捕 / 审判 / 处决 / 1939-02 / 平反 / 喀琅施塔得 / 远东 /
    #    「斯大林」当主语（项目口径，docs/44 §9.3）
    @{ Id = 'hof_ic_pyotr_smirnov_the_commissariat'; X = 0; Y = 7;
       P = @(@('hof_ic_pyotr_smirnov_the_naval_directorate'),
             @('hof_ic_pyotr_smirnov_the_general_staff'),
             @('hof_ic_pyotr_smirnov_the_naval_aviation'),
             @('hof_ic_pyotr_smirnov_the_declaration'),
             @('hof_ic_pyotr_smirnov_the_military_council'));
       Sync = $true;    # 完成时官衔升到 Lv4：苏联海军人民委员（1937-12-30）⭐⭐ 完全咬合（同一份决议）
       V = @('industrial_capacity_dockyard|_industrial_capacity_dockyard|0.05',
             'navy_org_factor|_navy_org|0.05',
             'naval_coordination|_naval_coordination|0.05',
             'naval_damage_factor|_naval_damage|0.05') }
)

if ($pyotrSmirnovLine.Count -ne 6) { throw "彼得·斯米尔诺夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($pyotrSmirnovLine.Count) 条" }

# =============================================================================
# 马林科夫（Idx 20）· 单线 5 节点 + 1 单结局 = 6 块 —— docs/80 / docs/81
#   ⚠️ 命名空间用 `hof_ic_malenkow`（花名册 Key 是【德式转写】`georgy_malenkow`）
#      —— R56 的立绘文件名却是 `Malenkov`（v）。扫盘 / 引材料时两种都要匹配。
#   ⭐⭐⭐⭐⭐ 主干 = 「给每一件要造的东西，配一个造得出来的人」
#   ⭐⭐ 首尾同轴：根 = 保管一柜子【别人的】名字（1925–1927）
#                E1 = 整个国家按一本名册办事（1953）——同一件东西，从「保管」变成「依据」
#   🚩🚩 V 字段的第二个段是【变量名后缀】。同一个词条在一条线里出现多次时，
#        后缀必须完全一致 —— 否则 Get-LineVars 只保留第一个，后面的节点会写到
#        不存在的变量上，数值静默丢失；重复词条必须共用后缀。
# =============================================================================
$malenkowPrefix = 'hof_ic_malenkow'
$malenkowDmId   = 'hof_ic_georgy_malenkow_dm'
$malenkowExtraHeaderTt = 'hof_ic_malenkow_extra_effects_tt'

$malenkowLine = @(

    # ---------------- 单线 · 配人（x = 0）----------------
    @{ Id = 'hof_ic_malenkow_the_party_card_index'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：中央领导干部部部长（1936-02）⚠️ 门槛早于职务 → 松咬合
       # 1935–1936 党证检查与交换 —— 他为全体党员与预备党员建立约 250 万份登记卡
       # 产物 = 一套【第一次能把人查得出来】的东西
       # ⭐ 这就是【根】的落实：1925 年他被派去看管的那个柜子，被他撑成了二百五十万张
       # ⛔ 不写「大清洗」（加害面，docs/80 §0.7）
       V = @('political_power_factor|_political_power|0.05',
             'political_advisor_cost_factor|_political_advisor_cost|-0.05',
             'stability_factor|_stability|0.05') }

    @{ Id = 'hof_ic_malenkow_the_cadres_directorate'; X = 0; Y = 2;
       P = @('hof_ic_malenkow_the_party_card_index');
       Sync = $true;    # 完成时官衔升到 Lv3：中央干部管理局局长（1939-03-22）⭐⭐ 完全咬合（同一个机构）
       # 1939-03-22 中央干部管理局成立，他任局长兼中央书记（至 1946）
       # 产物 = 一个【专管人的中央机关】+ 官册（номенклатура）成为制度
       # ⭐ 俄文维基：这个体系「成了马林科夫的主要党内专业」
       V = @('political_power_factor|_political_power|0.05',
             'political_advisor_cost_factor|_political_advisor_cost|-0.05',
             'mobilization_speed|_mobilization_speed|0.05') }

    @{ Id = 'hof_ic_malenkow_the_state_defence_committee'; X = 0; Y = 3;
       P = @('hof_ic_malenkow_the_cadres_directorate');
       # 1941-06-30 国防委员会成立，五人小组，他是其中之一（至 1945-09-04）
       # 产物 = 一个把党政军拧在一起的小组；他在里面管的是【人】
       #   （督导近卫迫击炮部队的组建 → 1943-07 雷达委员会 → 1946 图-4 / 火箭）
       # ⚠️ 这是党政协调机关，【不是】军事指挥（伏罗希洛夫 Idx 22 的领域）—— desc 写清楚
       V = @('mobilization_speed|_mobilization_speed|0.10',
             'conscription|_conscription|0.02',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_malenkow_the_aviation_affair'; X = 0; Y = 4;
       P = @('hof_ic_malenkow_the_state_defence_committee');
       # 1946-05-04 联共（布）中央政治局决议：他因「航空案」被撤出中央书记处
       # 产物 = 一条写进政治局决议的撤职理由 —— ⭐ **配错人的代价**
       # ⭐⭐ 这是本线的【立身之本】：正因为「配对」是他的活，飞机出问题才由他负道德责任。
       #      没有这一环，这条线只是「他当过很多官」。
       # ⭐ 九天后（1946-05-13）他被任命为第二号特别委员会主席，去管火箭。
       V = @('production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'air_accidents_factor|_air_accidents|-0.05',
             'experience_gain_air_factor|_experience_gain_air|0.05') }

    @{ Id = 'hof_ic_malenkow_the_party_schools'; X = 0; Y = 5;
       P = @('hof_ic_malenkow_the_aviation_affair');
       # 1946–1947 高级党校 + 社会科学院成立；他 1947-09 报告时已有 177 所两年制党校（学员约三万）
       # 产物 = 【名册上没有合适的人，就自己造人】
       # ⭐ 这一环是主干推出来的必然一步，不是拼上去的
       # ⭐ 文案 = 他本人 1947 报告（一手件）
       V = @('political_power_factor|_political_power|0.10',
             'political_advisor_cost_factor|_political_advisor_cost|-0.05',
             'training_time_factor|_training_time|-0.05') }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹荏择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **部长会议主席**（1953-03-05 – 1955-02-08）
    #   📌 2026-09-20 用户裁决取【乙】（甲 = 干部名册）。
    #   ⛔ 丙「集体领导」已被排除：原版已占（SOV_begin_destalinization 等 10+ 条）+ 赫鲁晓夫（Idx 21）的招牌。
    #   ⚠️ 与布哈林（Idx 2）E1 / 李可夫（Idx 3）Lv4「苏联人民委员会主席」只差几个字，
    #      但两人都在本线的排掉名单里（判据 E + 判据 K）→ 可用，已在 docs/81 §8⑦ 备案。
    #   ⭐ desc 里把「官册（номенклатура）」作为产物点名 —— 满足判据 C（产物抬到国家制度那一层）。
    # ⛔ 全文案不出现：列宁格勒 / 大清洗 / 捕获 / 审判 / 处决 / 犹太 / 「斯大林」当主语
    @{ Id = 'hof_ic_malenkow_the_premiership'; X = 0; Y = 7;
       P = @(@('hof_ic_malenkow_the_party_card_index'),
             @('hof_ic_malenkow_the_cadres_directorate'),
             @('hof_ic_malenkow_the_state_defence_committee'),
             @('hof_ic_malenkow_the_aviation_affair'),
             @('hof_ic_malenkow_the_party_schools'));
       Sync = $true;    # 完成时官衔升到 Lv4：苏联部长会议主席（1953-03-05）⭐⭐ 完全咬合（同一个职务）
       V = @('industrial_capacity_factory|_industrial_capacity|0.10',
             'stability_factor|_stability|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05') }
)

if ($malenkowLine.Count -ne 6) { throw "马林科夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($malenkowLine.Count) 条" }

# =============================================================================
#   ⭐⭐⭐⭐⭐ 赫鲁晓夫个人线（Idx 21 · regime 营）—— docs/83 / docs/84
#   主干 = 「把东西交到干活的那一级手上」—— 别人在加一层，他在往下交。
#   首尾同轴：根 = 归属换到自己人手上（1917）；E1 = 他把归属换给它所在的那一级（1957）。
#   🚩🚩 V 字段的第二个段是【变量名后缀】。同一个词条在一条线里出现多次时，
#        后缀必须完全一致 —— 否则 Get-LineVars 只保留第一个，后面的节点会写到
#        不存在的变量上，数值静默丢失。
#        本线重复的 political_power、consumer_goods、stability 与建造速度等词条都共用后缀。
#   ⚠️ stability_factor 同时也是花名册 Mod，节点加成会与它相加。
# =============================================================================
$khrushchevPrefix = 'hof_ic_khrushchev'
$khrushchevDmId   = 'hof_ic_nikita_khrushchyov_dm'
$khrushchevExtraHeaderTt = 'hof_ic_khrushchev_extra_effects_tt'

$khrushchevLine = @(

    # ---------------- 单线 · 往下交（x = 0）----------------
    @{ Id = 'hof_ic_khrushchev_the_workers_faculty'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：彼得罗夫-马林斯基县党委会书记（1925-07）⚠️ 门槛早于职务 → 松咬合
       # 1921 年末 他已经是一个矿的副矿长；这一年年底他进了顿河工业学校附属的工人速成中学
       # 产物 = 一个【已经管着一个矿的人】回到课桌前
       # ⭐ 与加里宁（Idx 14）「扫除文盲」的界线：扫盲是【认字】，速成中学是让已经在管事的人补上学历
       V = @('research_speed_factor|_research_speed|0.05',
             'political_power_factor|_political_power|0.05',
             'training_time_factor|_training_time|-0.05') }

    @{ Id = 'hof_ic_khrushchev_the_obligatory_deliveries'; X = 0; Y = 2;
       P = @('hof_ic_khrushchev_the_workers_faculty');
       Sync = $true;    # 完成时官衔升到 Lv3：乌克兰共产党中央委员会第一书记（1938-01）⚠️ 门槛晚 8 年 → 松咬合（叙事咬合）
       # 1946-10-15 他写信要求减少谷物上缴的配额；12 月又建议发放供应卡 —— 遭到怒骂，失去信任
       # 产物 = 他撞的不是某一个人，而是那个把粮食从共和国手里拿走的【制度本身】
       # ⭐ 与 A4「收购价」形成递进：先撞这个制度（1946）→ 再改它的价格（1953）→ 1958 取消它
       # 📌 节点名 2026-09-20 按用户口径改（原「给斯大林的那封信」）—— 判据 F：名词短语
       V = @('political_power_factor|_political_power|0.05',
             'stability_factor|_stability|0.05',
             'consumer_goods_factor|_consumer_goods|-0.05') }

    @{ Id = 'hof_ic_khrushchev_the_agro_towns'; X = 0; Y = 3;
       P = @('hof_ic_khrushchev_the_obligatory_deliveries');
       # 1949–1951 「消灭城乡差别」→ 把集体农庄合并成农业城市；1949-10 把样板点献上
       # 产物 = 一条被重画的【城乡界线】（就是那个把村并成城的框）
       # ⚠️ 代价写清楚：1951-03-04《真理报》他的讲话占两个整版 → 4 月莫斯科党全会众人鞭挞他
       V = @('production_speed_buildings_factor|_production_speed_buildings|0.05',
             'production_speed_infrastructure_factor|_production_speed_infrastructure|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05') }

    @{ Id = 'hof_ic_khrushchev_the_purchase_prices'; X = 0; Y = 4;
       P = @('hof_ic_khrushchev_the_agro_towns');
       Sync = $true;    # 完成时官衔升到 Lv4：苏联共产党中央委员会第一书记（1953-09-07）⭐⭐ 完全咬合（同月）
       # 1953–1956 国家收购价提高三倍（1953 那一版是马林科夫先提、他加码的 —— 已让给他，docs/81 §7）
       # 产物 = 一张【让种地的人先拿到钱】的价格表
       # ⛔ 节点名【不叫「新方针」】：托洛茨基（Idx 1）已有 hof_ic_trotsky_the_new_course「新方针」
       V = @('consumer_goods_factor|_consumer_goods|-0.05',
             'stability_factor|_stability|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05') }

    @{ Id = 'hof_ic_khrushchev_the_virgin_lands'; X = 0; Y = 5;
       P = @('hof_ic_khrushchev_the_purchase_prices');
       # 1954-02 党中央全会决议：哈萨克与西伯利亚大规模开垦荒地
       # 产物 = 4 000 万公顷（1954–1958，投资 67 亿卢布）+ 1958 年 5 850 万吨（占全苏 40% 以上）
       # ⚠️ 代价：60 年代初风沙侵蚀，几十万公顷新垦地被毁
       V = @('local_resources_factor|_local_resources|0.10',
             'production_speed_rail_way_factor|_production_speed_rail_way|0.05',
             'production_speed_buildings_factor|_production_speed_buildings|0.05');
       # 垦荒核心地带：库斯塔奈、阿克莫林斯克、巴甫洛达尔；只在仍属苏联且受控、基建未满时施工。
       Raw = @(
           'if = { limit = { 583 = { is_owned_by = ROOT is_controlled_by = ROOT infrastructure < 5 } } 583 = { add_building_construction = { type = infrastructure level = 1 instant_build = yes } } }',
           'if = { limit = { 590 = { is_owned_by = ROOT is_controlled_by = ROOT infrastructure < 5 } } 590 = { add_building_construction = { type = infrastructure level = 1 instant_build = yes } } }',
           'if = { limit = { 882 = { is_owned_by = ROOT is_controlled_by = ROOT infrastructure < 5 } } 882 = { add_building_construction = { type = infrastructure level = 1 instant_build = yes } } }'
       ) }

    # ---------------- 汇合层 · 单结局（x = 0, Y = 7）----------------
    # 🚩 五个节点【全部完成】才开门：P 写成五个并列的嵌套数组 = AND。
    # 🚩 单结局 → 不进 $endingChoiceOf：不弹抉择事件、没有 count_triggers、没有 mutually_exclusive。
    # ⭐⭐⭐ E1 = **国民经济委员会**（1957-05）—— 📌 2026-09-20 用户裁决取【丙】
    #   （甲 = 机器拖拉机站 1958-02 · 乙 = 部长会议主席 1958-03-27，⚠️ 乙与马林科夫线 E1 完全相同）
    #   俄文维基把它列在他「主要政治举措」里：撤销部门性部委、成立国民经济委员会（совнархозы）。
    #   ⭐⭐ 首尾同轴：根 = 1917 归属换到自己人手上；E1 = 他把归属换给它所在的那一级。
    #      方向反了，动作是同一个（与斯米尔加 Idx 10 那轮同型）。
    #   ⚠️ 代价：地方本位主义。
    @{ Id = 'hof_ic_khrushchev_the_economic_councils'; X = 0; Y = 7;
       P = @(@('hof_ic_khrushchev_the_workers_faculty'),
             @('hof_ic_khrushchev_the_obligatory_deliveries'),
             @('hof_ic_khrushchev_the_agro_towns'),
             @('hof_ic_khrushchev_the_purchase_prices'),
             @('hof_ic_khrushchev_the_virgin_lands'));
       V = @('industrial_capacity_factory|_industrial_capacity|0.10',
             'production_speed_industrial_complex_factor|_production_speed_industrial_complex|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05',
             'production_factory_max_efficiency_factor|_production_factory_max_efficiency|0.05') }
)

if ($khrushchevLine.Count -ne 6) { throw "赫鲁晓夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($khrushchevLine.Count) 条" }

# =============================================================================
#   ★★★★★ 伏罗希洛夫个人线（Idx 22 · regime 营）—— docs/86 / docs/87
#   主干 =「他把一摊事，变成一个交出去也能自己走的机关」—— 别人带兵，他建机关。
#   首尾同轴：根 = 1906 年他自己给自己起了一个化名（名是他自己起的）；
#             E1 = 1945 年他手上是一套交给别人用的管制机关。
#   🚩🚩 V 字段的第二个段是【变量名后缀】。同一个词条在一条线里出现多次时，
#        后缀必须完全一致 —— 否则 Get-LineVars 只保留第一个，后面的节点会写到
#        不存在的变量上，数值静默丢失。
#        本线重复的军事训练等词条应复用同一后缀。
#   ⚠️ army_org_factor 是花名册 Mod，本线【一个节点都不用】。
#   ⛔ 节点名里不出现：国防委员会 / 常备军 / 军事学院 / 最高苏维埃主席团主席 / 苏联元帅
# =============================================================================
$voroshilovPrefix = 'hof_ic_voroshilov'
$voroshilovDmId   = 'hof_ic_kliment_voroshilov_dm'
$voroshilovExtraHeaderTt = 'hof_ic_voroshilov_extra_effects_tt'

$voroshilovLine = @(

    # ---------------- 单线 · 把一摊事变机关（x = 0）----------------
    @{ Id = 'hof_ic_voroshilov_the_red_army_commanders'; X = 0; Y = 1; P = @('__entry__');
       Sync = $true;    # 完成时官衔升到 Lv2：苏联陆海军人民委员（1925-11-06）⚠️ 门槛【早】1 年 → 松咬合
       # 1926-09-10 红指挥员毕业典礼讲话：48 000 名红指挥员中 34 000 余名已受训（75%）
       # 产物 = 一支受过正规训练的红军指挥员队伍（1928 年初 49 所军校 + 6 所军事学院 + 5 个军事系）
       # ⭐ 与图哈切夫斯基（Idx 17）「军事学院」的界线：他做条令（约束），本线做指挥员的来源（培养）
       # 📌 2026-09-20 用户裁决：本节点取代原方案「伏罗希洛夫越野赛」（群众体育，与军事主题不搭）
       V = @('training_time_factor|_training_time|-0.10',
             'army_leader_cost_factor|_army_leader_cost|-0.10',
             'experience_gain_army_factor|_experience_gain_army|0.05') }

    @{ Id = 'hof_ic_voroshilov_the_marksmanship_badge'; X = 0; Y = 2;
       P = @('hof_ic_voroshilov_the_red_army_commanders');
       Sync = $true;    # 完成时官衔升到 Lv3：苏联国防人民委员（1934-06-20）⚠️ 门槛【早】1.5 年 → 咬合合理
       # 1932-12-29 批准 Осоавиахим 的「伏罗希洛夫射手」胸章
       # 产物 = 一枚胸章 = 一整套全国性的神枪手考核制度
       V = @('army_defence_factor|_army_defence|0.05',
             'experience_gain_army_factor|_experience_gain_army|0.10',
             'army_attack_factor|_army_attack|0.05') }

    @{ Id = 'hof_ic_voroshilov_the_ranks'; X = 0; Y = 3;
       P = @('hof_ic_voroshilov_the_marksmanship_badge');
       # 1935-09-22 中央执行委员会与人民委员会第 19/2135 号决议实行个人军衔
       # 1935-11-20 首批五位苏联元帅
       # 产物 = 一套军衔制度 + 一份五个人的名单
       V = @('army_morale_factor|_army_morale|0.05',
             'military_leader_cost_factor|_military_leader_cost|-0.10',
             'planning_speed|_planning_speed|0.10') }

    @{ Id = 'hof_ic_voroshilov_the_partisan_staff'; X = 0; Y = 4;
       P = @('hof_ic_voroshilov_the_ranks');
       # 1942-09-06 任游击运动总司令；指挥体系「稍作修改就沿用到战争结束」
       # 产物 = 中央游击运动总参谋部（一个机关 —— 该职位 1942-11-19 撤销，机关仍工作到战争结束）
       # ⚠️ 与托洛茨基（Idx 1）「反对游击主义」方向完全相反（他在排掉名单，不需避重）
       V = @('army_core_defence_factor|_army_core_defence|0.10',
             'special_forces_cap|_special_forces_cap|0.10',
             'land_reinforce_rate|_land_reinforce_rate|0.05',
             'no_supply_grace|_no_supply_grace|48') }

    @{ Id = 'hof_ic_voroshilov_war_trophies_regulation'; X = 0; Y = 5;
       P = @('hof_ic_voroshilov_the_partisan_staff');
       Sync = $true;    # 完成时官衔升到 Lv4：苏联部长会议副主席（1946-03-15）⚠️ 门槛【早】2.9 年 → 咬合合理
       # 1943-04-05 任战利品委员会主席；1944-04-03 批准《红军战利品机关、部队与机构条例》
       # 产物 = 一份条例 + 一整套机关
       # ⭐ 与 A4 不同型：A4 是「指挥」，这一块是「收集、保管、清点、运出、交出」
       V = @('equipment_capture_factor|_equipment_capture|0.10',
             'equipment_conversion_speed|_equipment_conversion_speed|0.05',
             'industrial_capacity_factory|_industrial_capacity|0.05',
             'production_factory_efficiency_gain_factor|_production_factory_efficiency_gain|0.05') }

    @{ Id = 'hof_ic_voroshilov_the_allied_control_commission'; X = 0; Y = 7;
       P = @(@('hof_ic_voroshilov_the_red_army_commanders'),
             @('hof_ic_voroshilov_the_marksmanship_badge'),
             @('hof_ic_voroshilov_the_ranks'),
             @('hof_ic_voroshilov_the_partisan_staff'),
             @('hof_ic_voroshilov_war_trophies_regulation'));
       # 1945-02-05 起驻匈牙利盟国管制委员会主席（至和约生效）
       # 产物 = 一整套对被占领国的管制机制（一个装上去就能自己转的机关）
       # 📌 2026-09-20 用户裁决取【丙】：原方案「无条件投降文件」作废
       #    （那个名字会让人以为要加「德国已投降」这类游戏内判断）
       # ⭐ 与李维诺夫（Idx 15）的界线：他让外国的【政府】肯签字；本线给一个被占领国【装】上一套机关
       V = @('resistance_target|_resistance_target|-0.05',
             'compliance_growth|_compliance_growth|0.10',
             'opinion_gain_monthly_factor|_opinion_gain_monthly|0.05',
             'resistance_decay|_resistance_decay|0.05') }
)

if ($voroshilovLine.Count -ne 6) { throw "伏罗希洛夫个人线应当是 6 条（5 节点 + 1 单结局），实际 $($voroshilovLine.Count) 条" }

# -----------------------------------------------------------------------------
# add_to_variable 默认【不产生任何 tooltip】—— 不补的话国策点下去玩家看不到变化。
# 德国的写法：add_to_variable = { <var> = <值> tooltip = <词条>_tt }
#   （原文见 common/national_focus/germany.txt 的 GER_wunderwaffe）
# 没有官方 `<词条>_tt` 的项目自行写本地化，键名统一 hof_ic_tt_<词条>。
# -----------------------------------------------------------------------------
$noTtMods = @(
    'combat_width_factor',
    'opinion_gain_monthly_factor',
    'improve_relations_maintain_cost_factor',
    'resistance_decay',
    'send_volunteer_factor',
    'paradrop_organization_factor',
    'no_supply_grace',
    'modifier_army_sub_unit_infantry_attack_factor',
    'modifier_army_sub_unit_cavalry_attack_factor'
)
function Get-ModTooltip([string]$m) {
    # 引擎修正键是 planning_speed，原版 tooltip 键却沿用旧名 planning_speed_factor_tt。
    if ($m -eq 'planning_speed') { return 'planning_speed_factor_tt' }
    if ($noTtMods -contains $m) { return "hof_ic_tt_$m" }
    return "${m}_tt"
}

# 汇总变量（去重、保序）—— 个人数值容器的 modifier 块要按这个顺序读
function Get-LineVars($line) {    $list = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $suffixOwner = @{}
    foreach ($f in $line) {
        if (-not $f.ContainsKey('V')) { continue }
        foreach ($v in $f.V) {
            $mod, $suf, $num = $v -split '\|'
            if ($seen.ContainsKey($mod) -and $seen[$mod] -ne $suf) {
                throw "个人线 $($f.Id)：$mod 的变量后缀从 $($seen[$mod]) 漂移到 $suf"
            }
            if ($suffixOwner.ContainsKey($suf) -and $suffixOwner[$suf] -ne $mod) {
                throw "个人线 $($f.Id)：变量后缀 $suf 同时用于 $($suffixOwner[$suf]) 与 $mod"
            }
            if (-not $seen.ContainsKey($mod)) { $seen[$mod] = $suf; $suffixOwner[$suf] = $mod; $list.Add("$mod|$suf") }
        }
    }
    return ,$list
}
$trotVars = Get-LineVars $trotLine
$bukhVars = Get-LineVars $bukhLine
$rykovVars = Get-LineVars $rykovLine
$zinVars   = Get-LineVars $zinLine
$kamVars   = Get-LineVars $kamLine
$smirVars  = Get-LineVars $smirLine
$serebVars = Get-LineVars $serebLine
$preobVars = Get-LineVars $preobLine
$radekVars = Get-LineVars $radekLine
$smilgaVars = Get-LineVars $smilgaLine
$tomskyVars = Get-LineVars $tomskyLine
$ryutinVars = Get-LineVars $ryutinLine
$shlyapnikovVars = Get-LineVars $shlyapnikovLine
$kalininVars   = Get-LineVars $kalininLine
$litvinovVars  = Get-LineVars $litvinovLine
$sokolnikovVars = Get-LineVars $sokolnikovLine
$tukhachevskyVars = Get-LineVars $tukhachevskyLine
$voznesenskyVars = Get-LineVars $voznesenskyLine
$pyotrSmirnovVars = Get-LineVars $pyotrSmirnovLine
$malenkowVars = Get-LineVars $malenkowLine
$khrushchevVars = Get-LineVars $khrushchevLine
$voroshilovVars = Get-LineVars $voroshilovLine

# -----------------------------------------------------------------------------
# ★ 人物线规格表 —— 循环体只写一份，【加人只加这张表】
#   ConvY / ConvCount：ConvY = 终局所在的那一行相对 y（§10 据此把终局也当成
#   「驱动器管的个人国策」，用同一段德国式 available）；ConvCount 不再用于 available
#   —— 门控（五条走通三条）已改到二选一事件的触发条件里，见 $endingChoiceOf。
# -----------------------------------------------------------------------------
$lineSpecs = @(
    @{ Name = '托洛茨基'; Line = $trotLine; Prefix = $trotPrefix; DmId = $trotDmId;
       Header = $trotExtraHeaderTt; Entry = 'hof_ic_seat_lev_trotsky'; Key = 'lev_trotsky';
       ConvY = 4; ConvCount = 3;          # 汇合层要「五条里走通三条」
       Branch = $roster[0].Branch; RankUp = $rankUpOf[1]; Vars = $trotVars;
       File = 'hof_ic_trotsky_dm.txt';
       DmName = '托洛茨基的个人威望';
       DmDesc = '托洛茨基在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/22 §4 / §8.2.4' },
    @{ Name = '布哈林'; Line = $bukhLine; Prefix = $bukhPrefix; DmId = $bukhDmId;
       Header = $bukhExtraHeaderTt; Entry = 'hof_ic_seat_nikolay_bukharin'; Key = 'nikolay_bukharin';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠 A3 且 B4 两块前置
       Branch = $byIdx[2].Branch; RankUp = $rankUpOf[2]; Vars = $bukhVars;
       File = 'hof_ic_bukharin_dm.txt';
       DmName = '布哈林的个人威望';
       DmDesc = '布哈林在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/26 §4 / §7.3' }

    @{ Name = '李可夫'; Line = $rykovLine; Prefix = $rykovPrefix; DmId = $rykovDmId;
       Header = $rykovExtraHeaderTt; Entry = 'hof_ic_seat_aleksey_rykov'; Key = 'aleksey_rykov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠四个节点全完成
       Branch = $byIdx[3].Branch; RankUp = $rankUpOf[3]; Vars = $rykovVars;
       File = 'hof_ic_aleksey_rykov_dm.txt';
       DmName = '李可夫的个人威望';
       DmDesc = '李可夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/30 §1 / §2' }

    @{ Name = '季诺维也夫'; Line = $zinLine; Prefix = $zinPrefix; DmId = $zinDmId;
       Header = $zinExtraHeaderTt; Entry = 'hof_ic_seat_grigory_zinovyev'; Key = 'grigory_zinovyev';
       ConvY = 6; ConvCount = 0;          # 两个互斥结局都在 y=6；门控（三条走通两条）在 $endingChoiceOf.Amount
       Branch = $byIdx[4].Branch; RankUp = $rankUpOf[4]; Vars = $zinVars;
       File = 'hof_ic_grigory_zinovyev_dm.txt';
       DmName = '季诺维也夫的个人威望';
       DmDesc = '季诺维也夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/33 §1 / §2' }

    @{ Name = '加米涅夫'; Line = $kamLine; Prefix = $kamPrefix; DmId = $kamDmId;
       Header = $kamExtraHeaderTt; Entry = 'hof_ic_seat_lev_kamenev'; Key = 'lev_kamenev';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠四个节点全完成
       Branch = $byIdx[5].Branch; RankUp = $rankUpOf[5]; Vars = $kamVars;
       File = 'hof_ic_lev_kamenev_dm.txt';
       DmName = '加米涅夫的个人威望';
       DmDesc = '加米涅夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/36 §1 / §2' }

    @{ Name = '斯米尔诺夫'; Line = $smirLine; Prefix = $smirPrefix; DmId = $smirDmId;
       Header = $smirExtraHeaderTt; Entry = 'hof_ic_seat_ivan_smirnov'; Key = 'ivan_smirnov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[6].Branch; RankUp = $rankUpOf[6]; Vars = $smirVars;
       File = 'hof_ic_ivan_smirnov_dm.txt';
       DmName = '斯米尔诺夫的个人威望';
       DmDesc = '斯米尔诺夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/39 §1 / §2' }

    @{ Name = '谢列布里亚科夫'; Line = $serebLine; Prefix = $serebPrefix; DmId = $serebDmId;
       Header = $serebExtraHeaderTt; Entry = 'hof_ic_seat_leonid_serebryakov'; Key = 'leonid_serebryakov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠四个节点全完成
       Branch = $byIdx[7].Branch; RankUp = $rankUpOf[7]; Vars = $serebVars;
       File = 'hof_ic_leonid_serebryakov_dm.txt';
       DmName = '谢列布里亚科夫的个人威望';
       DmDesc = '谢列布里亚科夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/42 §1 / §2' }

    @{ Name = '普列奥布拉任斯基'; Line = $preobLine; Prefix = $preobPrefix; DmId = $preobDmId;
       Header = $preobExtraHeaderTt; Entry = 'hof_ic_seat_yevgeny_preobrazhensky'; Key = 'yevgeny_preobrazhensky';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠四个节点全完成
       Branch = $byIdx[8].Branch; RankUp = $rankUpOf[8]; Vars = $preobVars;
       File = 'hof_ic_yevgeny_preobrazhensky_dm.txt';
       DmName = '普列奥布拉任斯基的个人威望';
       DmDesc = '普列奥布拉任斯基在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/45 §1 / §2' }

    @{ Name = '拉狄克'; Line = $radekLine; Prefix = $radekPrefix; DmId = $radekDmId;
       Header = $radekExtraHeaderTt; Entry = 'hof_ic_seat_karl_radek'; Key = 'karl_radek';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠两条支线【任一到头】（E1 的 P 是平铺 OR）
       Branch = $byIdx[9].Branch; RankUp = $rankUpOf[9]; Vars = $radekVars;
       File = 'hof_ic_karl_radek_dm.txt';
       DmName = '拉狄克的个人威望';
       DmDesc = '拉狄克在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/48 §1 / §2' }

    @{ Name = '斯米尔加'; Line = $smilgaLine; Prefix = $smilgaPrefix; DmId = $smilgaDmId;
       Header = $smilgaExtraHeaderTt; Entry = 'hof_ic_seat_ivar_smilga'; Key = 'ivar_smilga';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[10].Branch; RankUp = $rankUpOf[10]; Vars = $smilgaVars;
       File = 'hof_ic_ivar_smilga_dm.txt';
       DmName = '斯米尔加的个人威望';
       DmDesc = '斯米尔加在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/51 §1 / §2' }

    @{ Name = '托姆斯基'; Line = $tomskyLine; Prefix = $tomskyPrefix; DmId = $tomskyDmId;
       Header = $tomskyExtraHeaderTt; Entry = 'hof_ic_seat_mikhail_tomsky'; Key = 'mikhail_tomsky';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[11].Branch; RankUp = $rankUpOf[11]; Vars = $tomskyVars;
       File = 'hof_ic_mikhail_tomsky_dm.txt';
       DmName = '托姆斯基的个人威望';
       DmDesc = '托姆斯基在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/54 §1 / §2' }

    @{ Name = '里亚京'; Line = $ryutinLine; Prefix = $ryutinPrefix; DmId = $ryutinDmId;
       Header = $ryutinExtraHeaderTt; Entry = 'hof_ic_seat_martemyan_ryutin'; Key = 'martemyan_ryutin';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠四个节点全完成
       Branch = $byIdx[12].Branch; RankUp = $rankUpOf[12]; Vars = $ryutinVars;
       File = 'hof_ic_martemyan_ryutin_dm.txt';
       DmName = '里亚京的个人威望';
       DmDesc = '里亚京在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/57 §1 / §2' }

    @{ Name = '施利亚普尼科夫'; Line = $shlyapnikovLine; Prefix = $shlyapnikovPrefix; DmId = $shlyapnikovDmId;
       Header = $shlyapnikovExtraHeaderTt; Entry = 'hof_ic_seat_aleksandr_shlyapnikov'; Key = 'aleksandr_shlyapnikov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠六个节点全完成
       Branch = $byIdx[13].Branch; RankUp = $rankUpOf[13]; Vars = $shlyapnikovVars;
       File = 'hof_ic_aleksandr_shlyapnikov_dm.txt';
       DmName = '施利亚普尼科夫的个人威望';
       DmDesc = '施利亚普尼科夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/60 §1 / §2' }

    @{ Name = '加里宁'; Line = $kalininLine; Prefix = $kalininPrefix; DmId = $kalininDmId;
       Header = $kalininExtraHeaderTt; Entry = 'hof_ic_seat_mikhail_kalinin'; Key = 'mikhail_kalinin';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[14].Branch; RankUp = $rankUpOf[14]; Vars = $kalininVars;
       File = 'hof_ic_mikhail_kalinin_dm.txt';
       DmName = '加里宁的个人威望';
       DmDesc = '加里宁在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/62 §1 / §2' }

    @{ Name = '李维诺夫'; Line = $litvinovLine; Prefix = $litvinovPrefix; DmId = $litvinovDmId;
       Header = $litvinovExtraHeaderTt; Entry = 'hof_ic_seat_maksim_litvinov'; Key = 'maksim_litvinov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[15].Branch; RankUp = $rankUpOf[15]; Vars = $litvinovVars;
       File = 'hof_ic_maksim_litvinov_dm.txt';
       DmName = '李维诺夫的个人威望';
       DmDesc = '李维诺夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/65 §2 / §7' }

    @{ Name = '索柯里尼柯夫'; Line = $sokolnikovLine; Prefix = $sokolnikovPrefix; DmId = $sokolnikovDmId;
       Header = $sokolnikovExtraHeaderTt; Entry = 'hof_ic_seat_grigory_sokolnikov'; Key = 'grigory_sokolnikov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[16].Branch; RankUp = $rankUpOf[16]; Vars = $sokolnikovVars;
       File = 'hof_ic_grigory_sokolnikov_dm.txt';
       DmName = '索柯里尼柯夫的个人威望';
       DmDesc = '索柯里尼柯夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/68 §2 / §5' }

    @{ Name = '图哈切夫斯基'; Line = $tukhachevskyLine; Prefix = $tukhachevskyPrefix; DmId = $tukhachevskyDmId;
       Header = $tukhachevskyExtraHeaderTt; Entry = 'hof_ic_seat_mikhail_tukhachevsky'; Key = 'mikhail_tukhachevsky';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[17].Branch; RankUp = $rankUpOf[17]; Vars = $tukhachevskyVars;
       File = 'hof_ic_mikhail_tukhachevsky_dm.txt';
       DmName = '图哈切夫斯基的个人威望';
       DmDesc = '图哈切夫斯基在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/71 §2 / §5' }

    @{ Name = '沃兹涅先斯基'; Line = $voznesenskyLine; Prefix = $voznesenskyPrefix; DmId = $voznesenskyDmId;
       Header = $voznesenskyExtraHeaderTt; Entry = 'hof_ic_seat_nikolay_voznesensky'; Key = 'nikolay_voznesensky';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[18].Branch; RankUp = $rankUpOf[18]; Vars = $voznesenskyVars;
       File = 'hof_ic_nikolay_voznesensky_dm.txt';
       DmName = '沃兹涅先斯基的个人威望';
       DmDesc = '沃兹涅先斯基在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/74 §2 / §5' }

    @{ Name = '彼得·斯米尔诺夫'; Line = $pyotrSmirnovLine; Prefix = $pyotrSmirnovPrefix; DmId = $pyotrSmirnovDmId;
       Header = $pyotrSmirnovExtraHeaderTt; Entry = 'hof_ic_seat_pyotr_smirnov'; Key = 'pyotr_smirnov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[19].Branch; RankUp = $rankUpOf[19]; Vars = $pyotrSmirnovVars;
       File = 'hof_ic_pyotr_smirnov_dm.txt';
       DmName = '彼得·斯米尔诺夫的个人威望';
       DmDesc = '彼得·斯米尔诺夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/77 §2 / §5' }

    @{ Name = '马林科夫'; Line = $malenkowLine; Prefix = $malenkowPrefix; DmId = $malenkowDmId;
       Header = $malenkowExtraHeaderTt; Entry = 'hof_ic_seat_georgy_malenkow'; Key = 'georgy_malenkow';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[20].Branch; RankUp = $rankUpOf[20]; Vars = $malenkowVars;
       File = 'hof_ic_georgy_malenkow_dm.txt';
       DmName = '马林科夫的个人威望';
       DmDesc = '马林科夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/80 §2 / §5' }

    @{ Name = '赫鲁晓夫'; Line = $khrushchevLine; Prefix = $khrushchevPrefix; DmId = $khrushchevDmId;
       Header = $khrushchevExtraHeaderTt; Entry = 'hof_ic_seat_nikita_khrushchyov'; Key = 'nikita_khrushchyov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[21].Branch; RankUp = $rankUpOf[21]; Vars = $khrushchevVars;
       File = 'hof_ic_nikita_khrushchyov_dm.txt';
       DmName = '赫鲁晓夫的个人威望';
       DmDesc = '赫鲁晓夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/83 §2 / §4' }

    @{ Name = '伏罗希洛夫'; Line = $voroshilovLine; Prefix = $voroshilovPrefix; DmId = $voroshilovDmId;
       Header = $voroshilovExtraHeaderTt; Entry = 'hof_ic_seat_kliment_voroshilov'; Key = 'kliment_voroshilov';
       ConvY = -99; ConvCount = 0;        # 单结局：不用 count_triggers，靠五个节点全完成
       Branch = $byIdx[22].Branch; RankUp = $rankUpOf[22]; Vars = $voroshilovVars;
       File = 'hof_ic_kliment_voroshilov_dm.txt';
       DmName = '伏罗希洛夫的个人威望';
       DmDesc = '伏罗希洛夫在最高苏维埃中的个人威望。他每完成一条个人国策，下列数值就累积一层；一旦他离开最高苏维埃，这份威望随之消散，累积的加成一并失去。';
       Doc = 'docs/87 §2 / §4' }
)

# 角色职务重构的数据快照：供同源生成器枚举可达的个人线完成状态。
$roleSpecPath = Join-Path $PSScriptRoot 'hof-ic-role-spec.json'
$roleSpec = @{
    Roster = @($roster | ForEach-Object { @{ Idx = $_.Idx; Key = $_.Key; Idea = $_.Idea; Mod = $_.Mod; Tiers = $_.Tiers; RankGates = $_.RankGates; Branch = $_.Branch } })
    Lines = @($lineSpecs | ForEach-Object { @{ Key = $_.Key; Line = $_.Line; DmId = $_.DmId; File = $_.File } })
}
[IO.File]::WriteAllText($roleSpecPath, (ConvertTo-Json -InputObject $roleSpec -Depth 20), (New-Object Text.UTF8Encoding($false)))

# ---------------- 生成个人线 focus 块（两条线走同一个循环）----------------
# 把规格表摊平成一个待发射列表
$emits = New-Object System.Collections.Generic.List[object]
foreach ($ls0 in $lineSpecs) { foreach ($ff in $ls0.Line) { $emits.Add(@{ F = $ff; Ls = $ls0 }) } }

$null = $sb.AppendLine()
foreach ($ls0 in $lineSpecs) {
    $null = $sb.AppendLine("# ---- $($ls0.Name)个人线：$($ls0.Line.Count) 条国策 ----")
    $null = $sb.AppendLine("# 由 build/gen-hof-ic-s3.ps1 生成，勿手改。数据源：$($ls0.Doc)")
    $null = $sb.AppendLine('# 数值提示保留变量账本；实际修正由当前职务 idea 的静态版本承担。')
    if ($ls0.RankUp.Count -gt 0) {
        $null = $sb.AppendLine('# 升级触发点额外调 sync_rank 重算官衔等级')
    }
    $null = $sb.AppendLine()
}

foreach ($e in $emits) {
    $f  = $e.F
    $ls = $e.Ls

    $null = $sb.AppendLine('focus = {')
    $null = $sb.AppendLine("`tid = $($f.Id)")
    $null = $sb.AppendLine("`ticon = GFX_$($f.Id)")

    if ($f.ContainsKey('Mut')) {
        $null = $sb.AppendLine("`tmutually_exclusive = { focus = $($f.Mut) }")
    }

    # 前置分组：连续的字符串合成【一个】prerequisite 块（块内多个 = OR）；
    # 每个嵌套数组各自一个块（多块并列 = AND，V2 用这个做跨支线钩子）
    $pgroups = New-Object System.Collections.Generic.List[object]
    $pending = New-Object System.Collections.Generic.List[string]
    foreach ($grp in $f.P) {
        if ($grp -eq '__entry__') {
            $pending.Add($ls.Entry)
        } elseif ($grp -is [array]) {
            if ($pending.Count -gt 0) { $pgroups.Add($pending.ToArray()); $pending.Clear() }
            $pgroups.Add($grp)
        } else {
            $pending.Add($grp)
        }
    }
    if ($pending.Count -gt 0) { $pgroups.Add($pending.ToArray()) }

    foreach ($g in $pgroups) {
        $null = $sb.AppendLine('`tprerequisite = {')
        foreach ($x in $g) { $null = $sb.AppendLine("`t`tfocus = $x") }
        $null = $sb.AppendLine('`t}')
    }

    $null = $sb.AppendLine("`trelative_position_id = $($ls.Entry)")
    $null = $sb.AppendLine("`tx = $($f.X)")
    $null = $sb.AppendLine("`ty = $($f.Y)")
    $null = $sb.AppendLine('`tcost = 2')

    # 终局（汇合层）与个人线里的国策【同款】—— 都由驱动器推，所以 available 用同一段
    # 德国式双段 tooltip（进度 / ❌ 只能由 X 在完成 Y 之后开始）。
    # 🚩 2026-09-16 两轮纠正后定案（用户口径）：
    #    · 不是 `always = no`（那会被锁死，而且抉择没地方发生）
    #    · 也不是「玩家自己点的普通国策」（那就不是个人线了）
    #    · 而是**照德国希姆莱**：写成驱动器管的个人国策；抉择由【事件】给角色打标记，
    #      驱动器读标记推进选中的那一个。门控（五条走通三条）放在事件的触发条件里
    #      —— 德国就是这个做法：`available` 只负责显示，真条件在触发逻辑里。
    $choiceChar = $null
    $choiceFlag = $null
    if ($pathChoiceOf.ContainsKey($ls.Key)) {
        foreach ($op in $pathChoiceOf[$ls.Key].Opts) {
            if ($op.Focus -eq $f.Id) { $choiceChar = $pathChoiceOf[$ls.Key].Char; $choiceFlag = $op.Flag }
        }
    }
    if ($endingChoiceOf.ContainsKey($ls.Key)) {
        foreach ($ce in $endingChoiceOf[$ls.Key].Ends) {
            if ($ce.Focus -eq $f.Id) { $choiceChar = $endingChoiceOf[$ls.Key].Char; $choiceFlag = $ce.Flag }
        }
    }
    if ($ls.Branch -contains $f.Id -or $f.Y -eq $ls.ConvY -or $choiceFlag) {
        $null = $sb.AppendLine('`tavailable = {')
        $progressKeyword = 'if'
        if ($choiceFlag) {
            $null = $sb.AppendLine('`t`tif = {')
            $null = $sb.AppendLine("`t`t`tlimit = { NOT = { $choiceChar = { has_character_flag = $choiceFlag } } }")
            $null = $sb.AppendLine('`t`t`tcustom_override_tooltip = {')
            $null = $sb.AppendLine('`t`t`t`ttooltip = {')
            $null = $sb.AppendLine('`t`t`t`t`tlocalization_key = hof_ic_focus_event_choice_only_tt')
            $null = $sb.AppendLine("`t`t`t`t`tCHARACTER = $choiceChar")
            $null = $sb.AppendLine('`t`t`t`t}')
            $null = $sb.AppendLine('`t`t`t`talways = no')
            $null = $sb.AppendLine('`t`t`t}')
            $null = $sb.AppendLine('`t`t}')
            $progressKeyword = 'else_if'
        }
        $null = $sb.AppendLine("`t`t$progressKeyword = {")
        $null = $sb.AppendLine("`t`t`tlimit = { has_country_flag = hof_ic_$($ls.Key)_progress has_shine_effect_on_focus = $($f.Id) }")
        $null = $sb.AppendLine('`t`t`tcustom_override_tooltip = {')
        $null = $sb.AppendLine('`t`t`t`ttooltip = {')
        $null = $sb.AppendLine('`t`t`t`t`tlocalization_key = hof_ic_focus_in_progress_tt')
        $null = $sb.AppendLine("`t`t`t`t`tCHARACTER = SOV_$($ls.Key)")
        $null = $sb.AppendLine("`t`t`t`t`tFLAG_DAYS = [?hof_ic_$($ls.Key)_progress:days]")
        $null = $sb.AppendLine('`t`t`t`t}')
        $null = $sb.AppendLine('`t`t`t`talways = no')
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine('`t`t}')
        $null = $sb.AppendLine('`t`telse = {')
        $null = $sb.AppendLine('`t`t`tcustom_override_tooltip = {')
        $null = $sb.AppendLine('`t`t`t`ttooltip = {')
        $null = $sb.AppendLine('`t`t`t`t`tlocalization_key = hof_ic_focus_advisor_only_tt')
        $null = $sb.AppendLine("`t`t`t`t`tCHARACTER = SOV_$($ls.Key)")
        # ★ 德国的 $FOCUS$ = 入口国策的【本地化键】（GER_ascension_of_todt）——
        #   有了它，玩家看到的才是「在完成『托洛茨基进入最高苏维埃』之后开始」，
        #   而不是一句「他不在最高苏维埃中就不会被推进」的含糊话。
        $null = $sb.AppendLine("`t`t`t`t`tFOCUS = $($ls.Entry)")
        $null = $sb.AppendLine('`t`t`t`t}')
        $null = $sb.AppendLine('`t`t`t`talways = no')
        $null = $sb.AppendLine('`t`t`t}')
        $null = $sb.AppendLine('`t`t}')
        $null = $sb.AppendLine('`t}')
    }

    $null = $sb.AppendLine('`tcompletion_reward = {')
    if ($f.ContainsKey('V')) {
        # 在重选职务前记录本节点；完成效果执行时 has_completed_focus 的更新时序不可依赖。
        $null = $sb.AppendLine("`t`thidden_effect = { set_country_flag = hof_ic_done_$($f.Id) }")
        # 🚩 累积数值前先打一行【归属抬头】（照德国，见 $trotExtraHeaderTt 的注释）
        $null = $sb.AppendLine("`t`tcustom_effect_tooltip = $($ls.Header)")
        foreach ($v in $f.V) {
            $mod, $suf, $num = $v -split '\|'
            # tooltip 是必须的：否则 add_to_variable 在游戏里完全不显形
            $null = $sb.AppendLine('`t`tadd_to_variable = {')
            $null = $sb.AppendLine("`t`t`t$($ls.Prefix)$suf = $num")
            $null = $sb.AppendLine("`t`t`ttooltip = $(Get-ModTooltip $mod)")
            $null = $sb.AppendLine('`t`t}')
        }
        # 个人国策完成后按已完成节点重选职务 idea；实际效果只由该 idea 提供。
        $null = $sb.AppendLine("`t`thidden_effect = { hof_ic_role_refresh_$($ls.Key) = yes }")
    }
    if ($f.ContainsKey('Raw')) {
        if ($f.ContainsKey('V')) { $null = $sb.AppendLine('`t`tcustom_effect_tooltip = generic_skip_one_line_tt') }
        foreach ($r in $f.Raw) { $null = $sb.AppendLine("`t`t$r") }
    }
    if ($f.ContainsKey('Sync') -and $f.Sync) {
        # 原版 GER_strengthen_the_waffen_ss 在不同效果组之间插空行。
        # 否则个人威望数值与官衔更替连成一坨，玩家也无法分清两种效果。
        if ($f.ContainsKey('V') -or $f.ContainsKey('Raw')) {
            $null = $sb.AppendLine('`t`tcustom_effect_tooltip = generic_skip_one_line_tt')
        }
        # 🚩 照德国 GER_ascended_character_trait_swap_tt + swap_ideas：
        #    ① 一行「谁在核心圈中崛起，官衔提升为」
        #    ② show_ideas_tooltip 把升上去的官衔连同它的数值摊开
        #    我们的官衔是「逐级试删再反推重加」，没法像德国那样静态 swap_ideas，
        #    但 RankGates 让「完成这个国策会升到哪一级」是确定的（$rankUpTarget），
        #    所以目标官衔能写死。不这么写，玩家就看到一条光秃秃的「职务晋升」。
        $null = $sb.AppendLine("`t`t# 升官衔：重算等级（照德国 GER_add_*_effects 的反推法）")
        # 🚩 照德国 GER_ascended_character_trait_swap_tt 那一段：
        #    抬头只说「谁在核心圈中崛起」，【不】把新官衔名写进去；
        #    然后交给引擎的 swap_ideas 渲染「以新官衔取代旧官衔」+「效果变化:」+ 变化量。
        #    踩过：原来用 show_ideas_tooltip，引擎出的是「官衔名，其效果为」+【全量】，
        #    既和抬头重复，又不是玩家想知道的“变了多少”。
        $null = $sb.AppendLine("`t`tcustom_effect_tooltip = {")
        $null = $sb.AppendLine("`t`t`tlocalization_key = hof_ic_rank_up_tt")
        $null = $sb.AppendLine("`t`t`tCHARACTER = SOV_$($ls.Key)")
        $null = $sb.AppendLine("`t`t}")
        if ($ls.RankUp.ContainsKey($f.Id)) {
            $ru = $ls.RankUp[$f.Id]
            $null = $sb.AppendLine("`t`teffect_tooltip = {   # 照德国：引擎自己写「以 $($ru.To) 取代 $($ru.From)」+「效果变化:」")
            $null = $sb.AppendLine("`t`t`tswap_ideas = {")
            $null = $sb.AppendLine("`t`t`t`tremove_idea = $($ru.From)")
            $null = $sb.AppendLine("`t`t`t`tadd_idea = $($ru.To)")
            $null = $sb.AppendLine("`t`t`t}")
            $null = $sb.AppendLine("`t`t}")
        }
        # 已在上方用 swap_ideas 展示差值；真实重算藏起来，避免再显示一遍
        # remove_ideas / add_ideas 的完整效果（德国原版也用 hidden_effect 隐藏辅助操作）。
        $null = $sb.AppendLine("`t`thidden_effect = { hof_ic_idea_$($ls.Key)_sync_rank = yes }")
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()
}

# =============================================================================
# ★ 10z. 区块避让：算每人区块宽度 -> 排入口 x（docs/23 §2.7 / docs/26 §6.3）
# -----------------------------------------------------------------------------
# 用户 2026-09-15 的方法：「从托洛茨基的入口列往两侧铺开，要是侵占别人的列
# 别人避让不就行了。也就是每个人算一下区块大小然后各自避让」。
# 德国那个 15×6 的形状是【避让的结果】，不是规则 —— 要拄的是方法。
#
# ⚠️ 这一段必须在 $lineSpecs / $trotLine / $bukhLine 【之后】、写进 inject 文件【之前】。
#    入口国策块里先写了占位符 @@HOF_IC_X_<key>@@，这里算完再填。
#    好处：以后给后 5 人加个人线时，入口坐标【自动跟着变】，不用手改任何数字。
# =============================================================================
Write-Output ''
Write-Output '======== 10z. 区块避让（入口坐标）========'

# ① 每人的区块横向跨度（相对自己的入口）：取他整条线的 dx 最小/最大值
#    没有个人线的人 = 单列（Lo = Hi = 0）
$spanOf = @{}
foreach ($c in $roster) { $spanOf[$c.Key] = @{ Lo = 0; Hi = 0 } }
foreach ($ls0 in $lineSpecs) {
    $xs = @(0)
    foreach ($f in $ls0.Line) { $xs += $f.X }
    $spanOf[$ls0.Key] = @{
        Lo = [int](($xs | Measure-Object -Minimum).Minimum)
        Hi = [int](($xs | Measure-Object -Maximum).Maximum)
    }
}

# ② 从左到右铺开：每人的区块左边紧跟上一个人区块右边 + $seatGap
#    —— 被撞的人【让开】，这就是避让
$seatGap = 1
$blocks  = New-Object System.Collections.Generic.List[object]
$cursor  = 0
foreach ($c in $roster) {
    $sp = $spanOf[$c.Key]
    $entryX = $cursor - $sp.Lo                 # 区块左边落在 cursor 上 -> 反推入口 x
    $null = $blocks.Add([pscustomobject]@{
        Key = $c.Key; Zh = $c.Zh; EntryX = $entryX
        Lo = $entryX + $sp.Lo; Hi = $entryX + $sp.Hi
        W  = $sp.Hi - $sp.Lo + 1
    })
    $cursor = $entryX + $sp.Hi + 1 + $seatGap
}

# ③ 整体居中到 x = 0（入口国策都挂在 SOV_the_supreme_soviet 下面）
$allLo = [int](($blocks | ForEach-Object { $_.Lo } | Measure-Object -Minimum).Minimum)
$allHi = [int](($blocks | ForEach-Object { $_.Hi } | Measure-Object -Maximum).Maximum)
$shift = -[int][math]::Round((($allLo + $allHi) / 2))
foreach ($b in $blocks) { $b.EntryX += $shift; $b.Lo += $shift; $b.Hi += $shift }
$allLo += $shift; $allHi += $shift

# ④ 重叠自检：相邻两块不许压到一起（区块避让失效就当时报错，不静默地丑下去）
for ($i = 1; $i -lt $blocks.Count; $i++) {
    if ($blocks[$i].Lo -le $blocks[$i - 1].Hi) {
        throw "区块避让失败：$($blocks[$i - 1].Key)（占列 $($blocks[$i-1].Lo)..$($blocks[$i-1].Hi)）与 $($blocks[$i].Key)（占列 $($blocks[$i].Lo)..$($blocks[$i].Hi)）的区块重叠"
    }
}

# ⑤ 填回入口国策的 x
foreach ($b in $blocks) {
    $null = $sb.Replace("@@HOF_IC_X_$($b.Key)@@", $b.EntryX.ToString())
}
foreach ($b in $blocks) {
    $sp = $spanOf[$b.Key]
    Write-Output ("  {0,-22} 区块 dx {1,3}..{2,-3} (宽 {3,2})   入口 x = {4,3}   占列 {5,3}..{6,-3}" -f `
        $b.Key, $sp.Lo, $sp.Hi, $b.W, $b.EntryX, $b.Lo, $b.Hi)
}
Write-Output ("  整排占列 {0}..{1}（共 {2} 列）—— 区块之间留 {3} 列空档" -f $allLo, $allHi, ($allHi - $allLo + 1), $seatGap)

# =============================================================================
# ★ 10y. 中间国策「人民委员」—— 核心圈的枢纽（照德国 GER_fuhrerprinzip）
# -----------------------------------------------------------------------------
# 用户 2026-09-16 定：加一个中间国策，并把「开启核心圈」这件事
# 从原版的 SOV_the_supreme_soviet 【搬到这里来】。
#
# 照德国的四件事（原版 germany.txt L18151 GER_fuhrerprinzip）：
#   ① custom_effect_tooltip 一行「激活核心集团机制」（德：GER_fuhrerprinzip_inner_circle_tt）
#   ② add_political_power = 50
#   ③ add_popularity = { ideology = <执政意识形态> popularity = 0.05 }
#   ④ 空行 + 领袖特质【升级】（德：GER_der_fuhrer -> GER_der_fuhrer_fuhrerprinzip）
#   ⑤ （hidden_effect）add_dynamic_modifier —— 容器 DM 挂在这里
#
# 为何要它：入口国策原本直接挂在【原版】国策下，整块的位量受它牵制。
# 换成我们自己的节点后，整块核心圈（入口排 + 各人个人线）的位置由
# hof_ic_commissar 【一个点】决定 —— 改它的 x/y 就能整体挪。
# =============================================================================
Write-Output ''
Write-Output '======== 10y. 中间国策「人民委员」========'

$commissarId = 'hof_ic_commissar'

$null = $sb.AppendLine()
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('# 中间国策「人民委员」—— 核心圈的枢纽（照德国 GER_fuhrerprinzip）')
$null = $sb.AppendLine('#   所有入口国策都挂在它下面（prerequisite + relative_position_id）,')
$null = $sb.AppendLine('#   所以整块核心圈的位置由这一个点决定：要整体下移/左右挪，只改这里。')
$null = $sb.AppendLine('#   ⚠️ 容器 DM 也在这里挂载 —— 完成这个国策才算真正开启核心圈机制。')
$null = $sb.AppendLine('# ---------------------------------------------------------------------------')
$null = $sb.AppendLine('focus = {')
$null = $sb.AppendLine("`tid = $commissarId")
$null = $sb.AppendLine('# 图标复用原版「最高苏维埃」那张（用户 2026-09-16 定，不另出图）')
$null = $sb.AppendLine('`ticon = GFX_focus_SOV_the_supreme_soviet')
$null = $sb.AppendLine('`tprerequisite = { focus = SOV_the_supreme_soviet }')
$null = $sb.AppendLine('`trelative_position_id = SOV_the_supreme_soviet')
$null = $sb.AppendLine('`tx = 0')
# 放下面一点：原版枢纽自己占 y=0，入口行本来占 y=2 ——「人民委员」就放在那一行，
# 入口行跟着下移到自己下面（见 §10 里入口的 y = 1）。
$null = $sb.AppendLine('`ty = 2')
$null = $sb.AppendLine('`tcost = 1')
$null = $sb.AppendLine('`tavailable = {')
$null = $sb.AppendLine('`t`thas_government = communism')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('`tsearch_filters = { FOCUS_FILTER_POLITICAL }')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('`tcompletion_reward = {')
# ① 照德国 GER_fuhrerprinzip_inner_circle_tt
$null = $sb.AppendLine('`t`tcustom_effect_tooltip = hof_ic_commissar_inner_circle_tt')
# ② 照德国 add_political_power = 50
$null = $sb.AppendLine('`t`tadd_political_power = 50')
# ③ 照德国 add_popularity（德国是 fascism，我们是 communism）
$null = $sb.AppendLine('`t`tadd_popularity = {')
$null = $sb.AppendLine('`t`t`tideology = communism')
$null = $sb.AppendLine('`t`t`tpopularity = 0.05')
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('')
# ④ 空行 + 领袖特质升级（照德国 swap_country_leader_traits）
$null = $sb.AppendLine('`t`tcustom_effect_tooltip = hof_ic_skip_line_tt')
$null = $sb.AppendLine('`t`tif = {')
$null = $sb.AppendLine('`t`t`tlimit = { has_country_leader_with_trait = strong_party_discipline }')
$null = $sb.AppendLine('`t`t`tSOV_supreme_soviet = {')
$null = $sb.AppendLine('`t`t`t`tswap_country_leader_traits = {')
$null = $sb.AppendLine('`t`t`t`t`tremove = strong_party_discipline')
$null = $sb.AppendLine("`t`t`t`t`tadd = $commissarTraitId")
$null = $sb.AppendLine('`t`t`t`t}')
$null = $sb.AppendLine('`t`t`t}')
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('')
# ⑤ 容器 DM 挂载（原来补丁在原版 SOV_the_supreme_soviet 上，2026-09-16 搬到这里）
$null = $sb.AppendLine('`t`thidden_effect = {')
$null = $sb.AppendLine('`t`t`t# 核心圈容器（整个核心圈唯一一个可见民族精神）')
$null = $sb.AppendLine("`t`t`tadd_dynamic_modifier = { modifier = $dmId }")
$null = $sb.AppendLine('`t`t}')
$null = $sb.AppendLine('`t}')
$null = $sb.AppendLine('}')
Write-Output ("  [OK ] $commissarId：cost 1，仅挂载最高苏维埃可见容器")

# 全联盟终局仿德国「强大的继承者」/「忠于元首」：七席都完成各自终局后二选一。
# 单终局线取最后一个国策；托洛茨基、季诺维也夫的两条互斥终局取任一条。
# 地图基线：本机 1.19.3 + R56 history/states 与 map/definition.csv；含 1940—1956 年
# 的卡累利阿—芬兰加盟共和国首都彼得罗扎沃茨克。莫斯科现有 50 点，保持原值。
$hofIcCapitalVp = @(
    @{ Name = '莫斯科'; State = 219; Province = 6380; Base = 50; Urban = $true },
    @{ Name = '基辅'; State = 202; Province = 525; Base = 25; Urban = $true },
    @{ Name = '明斯克'; State = 206; Province = 11370; Base = 20; Urban = $true },
    @{ Name = '第比利斯'; State = 231; Province = 1599; Base = 5; Urban = $true },
    @{ Name = '巴库'; State = 229; Province = 7661; Base = 10; Urban = $true },
    @{ Name = '埃里温'; State = 230; Province = 12320; Base = 3; Urban = $true },
    @{ Name = '塔什干'; State = 405; Province = 1459; Base = 3; Urban = $true },
    @{ Name = '阿什哈巴德'; State = 985; Province = 12333; Base = 3; Urban = $false },
    @{ Name = '斯大林纳巴德'; State = 742; Province = 1384; Base = 1; Urban = $false },
    @{ Name = '阿拉木图'; State = 586; Province = 1591; Base = 3; Urban = $true },
    @{ Name = '伏龙芝'; State = 732; Province = 12583; Base = 1; Urban = $false },
    @{ Name = '里加'; State = 808; Province = 9340; Base = 5; Urban = $true },
    @{ Name = '塔林'; State = 812; Province = 3152; Base = 5; Urban = $true },
    @{ Name = '维尔纽斯'; State = 784; Province = 3320; Base = 3; Urban = $true },
    @{ Name = '基希讷乌'; State = 78; Province = 3707; Base = 3; Urban = $false },
    @{ Name = '彼得罗扎沃茨克'; State = 216; Province = 11159; Base = 1; Urban = $false }
)
foreach ($vp in $hofIcCapitalVp) {
    $v = [int]$vp.Base
    $vp.Target = if ($v -ge 30) { $v } elseif ($v -ge 20) { 30 } elseif ($v -ge 15) { 20 } elseif ($v -ge 10) { 15 } elseif ($v -ge 5) { 10 } elseif ($vp.Urban) { 10 } else { 5 }
}
$finaleEnds = @{}
foreach ($ls0 in $lineSpecs) {
    if ($endingChoiceOf.ContainsKey($ls0.Key)) {
        $finaleEnds[$ls0.Key] = @($endingChoiceOf[$ls0.Key].Ends | ForEach-Object { $_.Focus })
    } else {
        $finaleEnds[$ls0.Key] = @($ls0.Line[-1].Id)
    }
}
foreach ($finale in @(
    @{ Id = 'hof_ic_new_soviet_chairman'; Other = 'hof_ic_united_supreme_soviet'; X = -2 },
    @{ Id = 'hof_ic_united_supreme_soviet'; Other = 'hof_ic_new_soviet_chairman'; X = 2 }
)) {
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('focus = {')
    $null = $sb.AppendLine("`tid = $($finale.Id)")
    $null = $sb.AppendLine("`ticon = GFX_$($finale.Id)")
    $null = $sb.AppendLine('`tprerequisite = { focus = hof_ic_commissar }')
    $null = $sb.AppendLine("`tmutually_exclusive = { focus = $($finale.Other) }")
    $null = $sb.AppendLine('`trelative_position_id = hof_ic_commissar')
    $null = $sb.AppendLine("`tx = $($finale.X)")
    $null = $sb.AppendLine('`ty = 10')
    $null = $sb.AppendLine('`tcost = 5')
    $null = $sb.AppendLine('`tavailable = {')
    $null = $sb.AppendLine('`t`thas_government = communism')
    $null = $sb.AppendLine('`t`tcustom_trigger_tooltip = {')
    $null = $sb.AppendLine('`t`t`ttooltip = hof_ic_finale_gate_tt')
    $null = $sb.AppendLine('`t`t`tcount_triggers = {')
    $null = $sb.AppendLine('`t`t`t`tamount = 7')
    foreach ($ls0 in $lineSpecs) {
        $null = $sb.AppendLine('`t`t`t`tAND = {')
        $null = $sb.AppendLine("`t`t`t`t`thof_ic_seated_$($ls0.Key) = yes")
        $ends = $finaleEnds[$ls0.Key]
        if ($ends.Count -eq 1) {
            $null = $sb.AppendLine("`t`t`t`t`thas_completed_focus = $($ends[0])")
        } else {
            $null = $sb.AppendLine('`t`t`t`t`tOR = {')
            foreach ($end in $ends) { $null = $sb.AppendLine("`t`t`t`t`t`thas_completed_focus = $end") }
            $null = $sb.AppendLine('`t`t`t`t`t}')
        }
        $null = $sb.AppendLine('`t`t`t`t}')
    }
    $null = $sb.AppendLine('`t`t`t}')
    $null = $sb.AppendLine('`t`t}')
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('`tcancel_if_invalid = no')
    $null = $sb.AppendLine('`tcontinue_if_invalid = no')
    $null = $sb.AppendLine('`tsearch_filters = { FOCUS_FILTER_INNER_CIRCLE FOCUS_FILTER_POLITICAL_CHARACTER }')
    $null = $sb.AppendLine('`tcompletion_reward = {')
    if ($finale.Id -eq 'hof_ic_new_soviet_chairman') {
        $null = $sb.AppendLine('`t`thidden_effect = { country_event = heartofiron.1400 }')
        $null = $sb.AppendLine('`t`tcustom_effect_tooltip = hof_ic_new_soviet_chairman_event_tt')
    } else {
        $null = $sb.AppendLine('`t`tadd_political_power = 100')
        $null = $sb.AppendLine('`t`tadd_country_leader_trait = hof_ic_united_supreme_soviet_trait')
        $null = $sb.AppendLine('`t`tcustom_effect_tooltip = generic_skip_one_line_tt')
        # 按地图基线算出本国策自身的固定增量；与其他国策给予的胜利点叠加，不覆盖已有加成。
        foreach ($vp in $hofIcCapitalVp) {
            if ($vp.Target -gt $vp.Base) {
                $delta = [int]($vp.Target - $vp.Base)
                $null = $sb.AppendLine("`t`t$($vp.State) = { add_victory_points = { province = $($vp.Province) value = $delta } }")
            }
        }
    }
    $null = $sb.AppendLine('`t}')
    $null = $sb.AppendLine('}')
}

$injectPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\inject-sov-seats.txt'
[System.IO.File]::WriteAllText($injectPath, $sb.ToString().Replace('`t', "`t"), $utf8NoBom)
Write-Output ("  写出 {0,-58} {1,8:N0} 字节" -f 'build/inject-sov-seats.txt', (Get-Item -LiteralPath $injectPath).Length)
$focusCnt = (Select-String -LiteralPath $injectPath -Pattern '^focus = \{').Count
# 🚩 期望值一律从数据算：入口国策（= 花名册人数）+ 各条个人线的国策数 + 中间国策「人民委员」1 个
#    🚩🚩 原先写的是 `$roster.Count + $trotLine.Count + $bukhLine.Count + 1` ——
#         上第三个人（李可夫 5 条）时就报「54，应为 49」。已改成按 $lineSpecs 循环求和，
#         以后加人【不用再动这一行】（这是本项目第 11 次栽在写死数字上）。
$expFocusCnt = $roster.Count + (@($lineSpecs | ForEach-Object { $_.Line.Count }) | Measure-Object -Sum).Sum + 3
$okF = if ($focusCnt -eq $expFocusCnt) { 'OK ' } else { 'FAIL' }
$lineCntTxt = (@($lineSpecs | ForEach-Object { "$($_.Name) $($_.Line.Count)" }) -join ' + ')
Write-Output ("  [{0}] 国策块数 = {1}（{2} 入口 + {3} + 1 人民委员）" -f $okF, $focusCnt, $roster.Count, $lineCntTxt)
if ($focusCnt -ne $expFocusCnt) { throw "国策块数不对：$focusCnt，应为 $expFocusCnt" }

# -----------------------------------------------------------------------------
# 国策图标【归属表】—— 供 build/gen-hof-ic-focus-icons.ps1 做「缺图兜底」用
# -----------------------------------------------------------------------------
# 🚩 为什么要写这张表：国策块按【数据】发出去，图标 DDS 是【美术交付】的另一条线。
#    新人物上树而图未交时 icon = GFX_hof_ic_<...> 指向不存在的 sprite
#    → 游戏里图标空 + error.log 报 missing sprite（AGENTS 规则 5 明禁）。
#    兜底做法 = 复用该人的【入口图标】。而「哪个国策属于谁」只有生成器知道，
#    所以在这里写出来给图标脚本读：【不靠名字猜】——
#    花名册里有 ivan_smirnov 与 pyotr_smirnov 两个同姓，按姓氏猜会撞车。
$iconOwnerPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\focus-icon-owner.txt'
$sbOwn = New-Object System.Text.StringBuilder
$null = $sbOwn.AppendLine('# 核心圈 · 国策图标归属表（由 build/gen-hof-ic-s3.ps1 生成，勿手改）')
$null = $sbOwn.AppendLine('# 格式：<sprite 名去 GFX_ 前缀> = <花名册 Key>；只列【个人线】国策')
$null = $sbOwn.AppendLine('# 用途：图标 DDS 未交付时，按这里的 Key 复用该人的入口图标做占位')
$null = $sbOwn.AppendLine('hof_ic_new_soviet_chairman = supreme_soviet')
$null = $sbOwn.AppendLine('hof_ic_united_supreme_soviet = supreme_soviet')
foreach ($ls0 in $lineSpecs) {
    foreach ($f in $ls0.Line) { $null = $sbOwn.AppendLine("$($f.Id) = $($ls0.Key)") }
}
[System.IO.File]::WriteAllText($iconOwnerPath, $sbOwn.ToString(), $utf8NoBom)
Write-Output ("  写出 {0,-58} {1,8:N0} 字节（{2} 条归属）" -f 'build/focus-icon-owner.txt', (Get-Item -LiteralPath $iconOwnerPath).Length, (@($lineSpecs | ForEach-Object { $_.Line.Count }) | Measure-Object -Sum).Sum)

# ---------------- 10c. 个人线本地化（追加进 roster yml）----------------
# 文案全部是【史实/理论节选】，不自己写评价（AGENTS 规则 9），来源见 docs/22 §8.3 末尾的注
Write-Output ''
Write-Output '======== 10c. 个人线本地化 ========'

$trotLoc = [ordered]@{
    # =========================================================================
    # 🚩🚩 2026-09-16 全部重写（用户：「托洛茨基的国策介绍近乎全都要改，布哈林写的挺好的
    #      托洛茨基的怎么全拉了，甚至介绍文案里出现斯大林」）
    #
    # 根因：原稿取自多伊彻《先知三部曲》的【第三人称转述】（+3 条 Britannica 转译），
    #      而布哈林那 9 条是【他本人原话】—— 两者文风根本不是一个东西。
    # 修法：一律换成【托洛茨基自己的话】，一手件见 tmp/trotsky/txt/*.txt
    #      （marxists.org 中文马克思主义文库，共抓 28 份；抓取工具 build/fetch-trotsky*.ps1）
    # 另外：原稿有 2 条点到了【斯大林】（驳一国社会主义 / 加速工业化），已一并去除 ——
    #      本 mod 的设定里他是被清掉的一方，文案里不该再以他为主语。
    # 出处逐条见 docs/22 §8.3 末尾的注。
    # =========================================================================

    # ---- 支线 I · 红军缔造（《我的生平》第三十四章「专列」/ 第三十六章「军事反对派」）----
    'hof_ic_trotsky_build_the_red_army'                   = @('缔造红军', '「给我三千名逃兵组成一个团，我给他们派一名英勇善战的团长和一位优秀的政委，再给他们配上合适的营长、连长、排长——4 个星期之内，这三千名逃兵就可以成为我们这个革命国家中最优秀的团队。」')
    'hof_ic_trotsky_military_specialists'                 = @('返聘沙俄军官', '「如果我们认为我们不能把成千上万名专家，其中包括军事专家争取到我们这边，那实在是对我们自己、我们的党、我们思想的精神力量以及我们革命道义的感召力的估计太低了。」')
    'hof_ic_trotsky_against_partisan_warfare'             = @('反对游击主义', '「必须在短期内从志愿兵制转入义务兵制，从游击队转入正规军编制。我们每天不断地与游击习气作斗争，这一斗争要求坚持不懈、毫不妥协，有时还需要采取严厉措施。反游击习气的斗争，就是为建设无产阶级国家制度，反对小资产阶级、无政府主义自发势力对它的侵袭的斗争。」')

    # ---- 支线 II · 理论根干（《俄国革命史》第一章「俄罗斯发展的特点」/ 附录）----
    'hof_ic_trotsky_uneven_and_combined_development'      = @('不平衡与综合发展律', '「落后国家虽不得不追随先进国家，但它并不遵守程序：历史的落后性的特权，允许、或更确切些说强迫一个落后国家去采取一些比预定日期更早完成的事物，去跳过许多中间阶段。野蛮人放下了弓箭，立刻拿起了步枪，他们并不经历过去介于两种武器之间的旅程。」')
    'hof_ic_trotsky_permanent_revolution'                 = @('不断革命论', '「俄国当然不能独立地走到社会主义，但俄国开辟了社会主义革命纪元，就能够给欧洲社会主义发展以一个推动，以此方式，追随先进国家之后而走到社会主义。」')
    'hof_ic_trotsky_socialism_in_one_country'             = @('驳「一国社会主义」', '「1904—1905 年间，没有一个俄国马克思主义者曾经辩护过或曾经提出过在一个国家、尤其在俄国能建成社会主义制度的见解。这个见解第一次提出于印刷物上，是在二十年之后。」')

    # ---- 支线 III · 党内民主 ----
    'hof_ic_trotsky_the_new_course'                       = @('新方针', '「我们认为自己的观点是正确的，在党的范围内保留捍卫自己观点的权利，并且拒绝一切可以导致分裂危险的行动。……它表达了我们要求留在党内为党服务的愿望。」')
    'hof_ic_trotsky_against_the_bureaucracy'              = @('反对官僚化', '「无产阶级专政将通过政党夺取政权而建立，这个政党在革命中起领导作用。但是，一旦它的任务完成，这样的党要提防用自身代替无产阶级或是支配无产阶级。」')

    # ---- 支线 IV · 经济（《我的生平》第三十八章 / 1923-01-15 致中央政治局 / 1926-05-02）----
    'hof_ic_trotsky_limited_market_reforms'               = @('有限市场化', '「从乌拉尔我带回了大量经济考查材料，从中可以得出一个共同的结论：必须放弃战时共产主义。……为了经济的振兴必须不惜一切代价引入个人利益的因素，即在某种程度上恢复国内市场。我向中央委员会建议以征收粮食税代替余粮收集制，并建立商品交换制度。」')
    'hof_ic_trotsky_labour_armies'                        = @('劳动军', '「既然转入市场机制的建议已被否决，我就要求正确地、系统地实行『战时』方法，以求取得实际的经济成果。在战时共产主义制度中，所有的物资至少在原则上都国有化，并根据国家命令分配。」')
    'hof_ic_trotsky_state_planning'                       = @('经济计划化', '「我一再肯定地说，我们现在还没有一个机关直接负责有计划地领导国有经济，并在其权利、职责和人员方面都能实施这种领导。我认为，最近时期我们经济政策的失误在于孤立地提出财政问题——不稳定的卢布不可能成为经济的调节者。」')
    'hof_ic_trotsky_accelerated_industrialization'        = @('加速工业化', '「我国经济发展的速度，首先是工业化的速度问题，因此具有决定性意义。断言我们可以用乌龟爬行速度来建设社会主义，这是胡说——世界市场不等待，庄稼汉不想等待。」')

    # ---- 支线 V · 国际（1921 共产国际三大 / 1927 中国革命 / 1934 工人武装）----
    'hof_ic_trotsky_the_comintern_manifesto'              = @('共产国际宣言', '「我们提出的世界革命方针，整个来说，是否依然完全正确？……我们过去和现在都决心把握每一个时机，不论在形式上有什么变化，来发起革命。」')
    'hof_ic_trotsky_the_chinese_question'                 = @('中国革命问题', '「任务中的任务，竟不是数百万工人在职工会与共产党领导之下的觉醒与统一，不是将贫苦的农民与手艺工人吸引至运动的主流——不是的，『任务中的任务』乃是国民党的地位！」')
    'hof_ic_trotsky_united_front'                         = @('反法西斯统一战线', '「这并不是说我们否认联合战线的重要性。我们需要的联合战线，是在各阶级政党的领导人一致反抗法西斯主义的时候。……只有群众性斗争才能决定局势。」')

    # ---- 汇合层（互斥的两个终局）----
    'hof_ic_trotsky_the_permanent_revolutionary'          = @('永久的革命者', '「要求我放弃政治活动，意味着要求我放弃为全世界工人阶级利益而进行的斗争，而这一斗争我已孜孜不倦地进行了 32 年之久，也就是我自觉生命的全部时间。只有腐朽透顶的官僚集团才会要求做出这种放弃，只有卑鄙的叛徒才能做出这种承诺。」')
    'hof_ic_trotsky_the_builder_of_the_state'             = @('国家建设者', '「我们之所以用随机应变的措施来代替制度，为的是今后能在这些措施的基础上建立起可依靠的制度。我们不希望在建成健全的制度之前就被消灭。」')
}

# 布哈林个人线 9 条（文案为原文节选，来源见 docs/26 §7.2）
$bukhLoc = [ordered]@{
    'hof_ic_bukharin_economics_of_transition'      = @('过渡时期的经济', '这种联盟的路线是过渡时期全部政策的实质。因为过渡时期最明显的特点主要是两阶级社会，在这样的社会里，城市和农村、工业和农业、大生产和小生产、合理的计划和无政府主义的市场等等问题表现了主要的阶级问题，即工人阶级和农民之间的相互关系问题。')
    'hof_ic_bukharin_nep_is_not_a_retreat'         = @('新经济政策不是退却', '或者我们在过渡时期要建立无产阶级领导下的工农联盟，那么，这条路线应当是我们各种活动的基本原则。')
    'hof_ic_bukharin_abolish_the_tribute'          = @('取消「贡款」', '无产阶级不是农民的剥削者，也不可能是农民的剥削者。请取消您的『贡款』，哪怕作为失言也罢！……贡款是非常明确的历史范畴，它同社会主义毫无共同之处，也不可能有共同之处！不能这样轻率地对待理论观点。这是无知，是有害的！')
    'hof_ic_bukharin_alliance_is_the_axis'         = @('工农联盟是轴心', '在上次辩论中提出的零散的问题……这一切现在都归结为某些基本的方面……而所有这些本身极重大的问题所围绕的轴心就是工农联盟问题。')
    'hof_ic_bukharin_enrich_yourselves'            = @('发财吧', '我们农村政策的发展趋势应当是，要放宽妨碍富裕农民和富农经济发展的许多限制，有一部分甚至要废除。应当向农民，向全体农民说：发财吧！发展自己的经济吧！用不着担心，不会有人无情地欺负你们！')
    'hof_ic_bukharin_proportional_development'     = @('按比例发展', '价值规律在消亡。但按比例的劳动消耗规律仍存在。……要跳出这一规律是绝对不行的。')
    'hof_ic_bukharin_cooperatives_into_the_system' = @('合作社长入', '我国基本的农民合作社组织网将不是由富农式的而是『劳动』式的基层合作社细胞构成，这些细胞将长入到体系中去，长入到我们的一般国家机关的体系中去，并通过这一途径成为社会主义经济的单一链条中的环节。')
    'hof_ic_bukharin_left_communism'               = @('左翼共产主义', '列宁教导说：工人阶级同农民的冲突根本不是不可避免的。托洛茨基教导说：这种冲突必定会发生。')
    'hof_ic_bukharin_socialism_in_one_country'     = @('一国建成社会主义', '我们不会由于国内的阶级差别和我们技术上的落后而灭亡，甚至在低下的技术基础上我们也能够建设社会主义，社会主义的这种发展将非常缓慢，我们将以乌龟速度爬行，但我们终究在建设社会主义，并且我们定将建成它。')
}

# 李可夫个人线 5 条（docs/29 §5.2 / §5.3；出处逐条见 docs/30）
# -----------------------------------------------------------------------------
# 🚩🚩 这里是本项目【唯一一处】描述文本不是「本人原话」的个人线，原因写清楚：
#    他本人【没有可引用的中文文集】——中文马克思主义文库没有李可夫页（5 个 URL 全 404）、
#    英文 marxists.org 也没有他的档案（/archive/rykov/ 404）、俄文维基语录只有 4 条
#    且全是 1927 十五大 / 1938 审判供词（与这五个节点全不对位）。
#    → 按 AGENTS 规则 9 的第二档「历史上他人评价或记述的原文」，用【列宁与托洛茨基】的话，
#      他们恰好都写到他经手的这几个机关。
#    → 只有 ④ 连这一档都找不到，退到【后人记述】（俄文维基百科），已在 docs/30 标出。
#    ⚠️ 因此 ④ 那条【不加引号】—— 一眼能看出它不是原文节选，不冒充原文。
$rykovLoc = [ordered]@{
    # ---- ① 1918-04-03 出任最高国民经济委员会主席 ----
    # 出处：列宁，1918 年 5 月 26 日《在全俄国民经济委员会第一次代表大会上的讲话》
    #       （tmp/rykov/lenin/txt/mia-chinese-lenin-19180526.txt）
    'hof_ic_rykov_supreme_economic_council' = @('最高国民经济委员会主席', '「现在最高国民经济委员会担负着一项困难而又最能收效的任务。……在剥削者的反抗被彻底粉碎以后，在劳动者学会组织社会主义生产以后，这种原来意义的、狭义的管理机构，旧国家的机构，必定消亡，而最高国民经济委员会这样的机构必定成长、发展和巩固，它将担负起有组织的社会的一切最主要的活动。」')

    # ---- ② 1919-07 ~ 1921-08 劳动国防委员会粮秣特派员（红军与红海军的给养）----
    # 出处：托洛茨基，《我的生平》第三十六章「专列」（tmp/trotsky/txt/i1_train_1929book36.txt）
    'hof_ic_rykov_food_supply_commissar' = @('劳动国防委员会粮秣特派员', '「一个有一定效能的统一供给前线和全军的军需机构逐渐建立起来了。……同时切不可忘记，我们是在没有物资储备的情况下作战的。早在 1919 年，中央仓库已经告罄。军衬衣刚刚缝好就送上前线，枪支弹药的情况更糟。图拉的几家兵工厂的产品都是现产现运，没有总司令的签字，一车皮的弹药也不能动用。」')

    # ---- ③ 1921-05-26 就任劳动国防委员会副主席 ----
    # 出处：托洛茨基，1921 年 8 月 7 日（tmp/trotsky/txt/iv1_nep_gosplan_19210807.txt）
    'hof_ic_rykov_labour_defence_council' = @('劳动与国防委员会副主席', '「国家计划委员会目前的状况根本不可能真正有计划地领导经济工作。……劳动国防委员会的任务是确定经济政策的基本原则，对经济工作进行全面监督，具体解决其他各级经济组织解决不了的棘手问题。」')

    # ---- ④ 1923 起任航空之友协会（ОДВФ / Авиахим）主席 ----
    # ⚠️ 唯一一条【后人记述】：俄文维基百科「阿列克谢·伊万诺维奇·李可夫」条「纪念」节
    #    +「Осоавиахим」条（ОДВФ 1923-03 成立、1925 年逾 200 万人）。
    #    所以【不加引号】—— 不冒充原文节选。
    'hof_ic_rykov_sponsor_aviation' = @('扶植航空', '雅科夫列夫最初的一批飞机，家族名就叫 АИР——以阿列克谢·伊万诺维奇·李可夫命名。第一架飞机取名「А. И. 李可夫」，是为了感谢这位自学成才的设计师从 1923 年刚入航空业起，就持续得到航空之友协会（ОДВФ）及其后继者阿维阿希姆的支持；而自 ОДВФ 1923 年成立起，这一组织的主席就是李可夫本人。航空之友协会当年就发展到二百万人，АИР 这个名字一直用到 1937 年的 АИР-18。')

    # ---- ⑤ 汇合层 · 单结局：1926-01-19 接任劳动与国防委员会主席 ----
    # 出处：托洛茨基，1926 年 9 月 7 日《工业化的问题》（tmp/trotsky/txt/iv4_industry_19260907.txt）
    'hof_ic_rykov_labour_defence_chair' = @('劳动与国防委员会主席', '「这个在最高国民经济委员会内制定、还没有得到批准的五年计划，无疑将被国家计划委员会、劳动国防委员会等加以削减，因为该计划要求投入的基本建设资金和整个拨款额大大超过了党和经济领导机关的预测。」')
}

# 季诺维也夫个人线 11 条（docs/33 §4；全部是他本人的原文节选）
# 🚩 与李可夫那批不同：他【有可引用的中文文集】（中文马克思主义文库有他的专页），
#    所以下面 11 条【全部是原文节选】，没有一条退到「他人记述」。
#    ⚠️ 唯一需要说明的是 A2：21 条件本身的原始报告（1920-07-29）中文文库没有，
#    引的是他 1921-11 回顾时说「著名的二十一条」的那一句。已在 docs/33 §8 记入待办。
$zinLoc = [ordered]@{
    # ---- 支线 A · 缔造共产国际，再给它立规矩 ----
    # 出处：1919-03-02《关于成立第三国际的声明》（tmp/zinoviev/txt/ci_19190302_decl.txt）
    'hof_ic_zinovyev_found_the_comintern' = @('缔造第三国际', '「我们党认为，正式成立第三国际的时机已经完全成熟，因此我曾建议就在这第一次代表大会上成立第三国际。」')

    # 出处：1921-11-13《共产国际发展中的主要阶段》（ci_192111_stages.txt L65）
    'hof_ic_zinovyev_twenty_one_conditions' = @('加入共产国际的条件', '「共产国际看到了这种危险性，就从自我保护的朴素感情出发，必须采取相应的措施。因此就产生了著名的二十一条，后来围绕这个二十一条展开了非常激烈的斗争。」')

    # 出处：1925-03-25 共产国际执委会第五次扩大全会报告（ci_19250325_persp.txt L279 / L281）
    'hof_ic_zinovyev_social_fascism' = @('社会法西斯主义', '「在意大利，法西斯主义是资本主义资产阶级和社会民主党两种倾向的综合体，社会民主党则是法西斯主义的一翼。……包含着把社会民主党看作是资产阶级『第三』党的说法的第五次代表大会的提纲是完全正确的。」')

    # 出处：1925-03-25 报告（ci_19250325_persp.txt L343 / L347）
    'hof_ic_zinovyev_bolshevization' = @('布尔什维克化', '「工人运动的真正布尔什维克化是一个不断的过程。……布尔什维克化就在于学会从俄国的经验中，同样地，也从其他国家的斗争经验中吸取最本质的教训，把它们同某个国家的具体条件和要求结合起来。」')

    # ---- 支线 C · 世界革命的期限与道路 ----
    # 出处：1920-09-01 巴库《东方各民族代表大会告欧洲、美国和日本工人书》（ci_192009_east.txt）
    'hof_ic_zinovyev_congress_of_the_east' = @('东方各民族代表大会', '「只有欧美工人和亚非劳动群众的共同胜利才能给迄今为止一直为一小撮富人过上舒服生活而劳动的人带来解放。如果仅仅你们获得了自由，而我们还处于被奴役之中，那么你们自己很快就会重新沦为奴隶。」')

    # 出处：1921-12《关于工人统一战线……（提纲）》（ci_192112_uf.txt）
    'hof_ic_zinovyev_workers_united_front' = @('工人统一战线', '「共产党现在可以而且应当收获自己过去在群众漠不关心的十分不利的情况下所进行的斗争的果实。……共产党现在应当在一切场合下竭力使这些群众的实际行动尽可能达到更广泛和更完全的统一。」')

    # 出处：1925-03-25 报告（ci_19250325_persp.txt）
    'hof_ic_zinovyev_speed_and_route' = @('革命的速度与路线', '「俄国革命胜利后，我们大家都一致认为，下一次将轮到德国了……只是在现在……才坚定不移地提出一个问题：革命是否必定通过德国移向欧洲？……可能出现的情况是：未来的行进路线不一定首先通过德国革命。」')

    # ---- 支线 D · 党与工会的作用 ----
    # 出处：1920-05《国际工人运动的迫切问题》（ci_192005_urgent.txt L152 / L166）
    'hof_ic_zinovyev_party_in_revolution' = @('党在无产阶级革命中的作用', '「没有强大的共产党，就不可能把无产阶级从资本主义的压迫下解放出来。共产党是工人阶级的大脑。共产党是无产阶级的眼睛。……共产党是工人阶级的先锋队。」')

    # 出处：1921-03《论工会在生产中的作用》（俄共十大；tmp/zinoviev/txt/d2_union_1921_02.txt L13 / L15）
    'hof_ic_zinovyev_trade_unions' = @('论工会的作用', '「可以毫不夸大地说，现在第三国际反对其一切敌人的斗争十分之九在最近时期将在工会运动中进行。……把工会争取过来，意味着赢得了所有的加入组织的工人，甚至是赢得了所有的工人。而赢得所有的工人，意味着打垮资产阶级，使无产阶级革命获得胜利。」')

    # ---- 汇合层（互斥的两个终局）----
    # 出处：1920-05《国际工人运动的迫切问题》（ci_192005_urgent.txt L178）
    'hof_ic_zinovyev_monolithic_international' = @('铁板一块的国际', '「没有共产党的铁的专政，苏维埃政权不仅不能维持 3 年，而且连 3 个月也维持不了。每一个有觉悟的工人应当懂得，工人阶级专政不可能不通过它的先锋队，即共产党的专政来实现。」')

    # 出处：1925-03-25 报告（ci_19250325_persp.txt L365）
    'hof_ic_zinovyev_mass_international' = @('群众的国际', '「要成为一个群众工作者，必须持续不断地向工人群众保持联系，其中也包括同社会民主党工人和无党派工人保持联系。」')
}

# 加米涅夫个人线 5 条（docs/36 §5；全部是一手件）
# 🚩 他有中文专页（19 条）+ 【英文 6 篇】（中文库没有）—— 落盘 tmp/kamenev/txt/
# ⚠️ A1 / A4 引的是【自传正文】（本人审定）；**绘不引「续志」**
#    （那是 Ф. 穆兹卡写的后人记述，见 docs/35 §0）。
# 📌 用户 2026-09-17 砍掉 B/C 两支线与互斥项后，有 8 条文案【暂时不用】
#    （反对武装起义 / 苏维埃大会主席 / 莫斯科苏维埃 / 国防特派员 /
#      布列斯特与出使 / 商业与租让 / 出版原始文本 / 党的和解者）——
#    ⚠️ 它们已从 $kamLoc 【删除】，不是注释掉：否则 $locOf 的一一对应校验会报「多余」。
$kamLoc = [ordered]@{
    # ---- 单线 · 列宁的文本与遗产 ----
    # 出处：加米涅夫《伊里奇的文学遗产与列宁全集》（英文，载《共产国际》第 1 期）
    'hof_ic_kamenev_lenins_charge' = @('列宁的托付', '「如果我被杀死，我请您出版我的笔记《马克思主义论国家》。」—— 列宁 1917 年 7 月躲藏时写给他的信')
    # 出处：《列宁主义》（格拉纳特百科词典第 40 卷，1923–1924）
    'hof_ic_kamenev_leninism' = @('列宁主义', '「列宁开始进行自己的工作的时候，恰好人类——全世界从资本主义表面上和平的、有机的发展转向新的世界历史时代，转向无产阶级革命的纪元。……这就使马克思主义变成了列宁主义。」')
    # 出处：1924-11《列宁主义还是托洛茨基主义？》（他转引列宁的话）
    'hof_ic_kamenev_against_the_lessons' = @('驳《十月教训》', '「事情以我们党中央在报刊上对这些辞职的同志进行非常严厉的批评告终。而几周之后，至多几个月之后，所有这些同志都承认了自己的错误，回到了他们负责的党和苏维埃岗位上。」')
    # 出处：同上《伊里奇的文学遗产与列宁全集》
    'hof_ic_kamenev_lenin_institute' = @('列宁研究院与全集', '「我们必须把注意力转向劳动群众，把那些被资产阶级和沙皇政府藏了数十年的列宁著作交到他们手里。把列宁的著作交给劳动群众，就意味着加速他们的胜利。为此必须倾注我们全部的力量。」')
    # 出处：同上
    'hof_ic_kamenev_executor_of_the_will' = @('列宁的遗嘱执行人', '「一切与列宁有关的东西都重要。而极其重要的是列宁的著作将以何种形式交给世界无产阶级。」')
}

# -----------------------------------------------------------------------------
# 斯米尔诺夫（Idx 6）—— 单线 5 节点 + 1 单结局（docs/39 §5）
# 出处：A1 / A2 / A5 / E1 = 托洛茨基《我的生平》第三十三章〈斯维亚日斯克一月〉【中译本】
#                        （落盘 tmp/smirnov/mia/ch35.txt；MIA: trotsky_1929book35.htm）
#       A3 / A4         = 维克多·塞尔日《伊·尼·斯米尔诺夫之死》1936-08（MIA 英文）
#                        ⚠️ 这两条是中译稿，待换成中文原文（docs/99 §12.3）
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# -----------------------------------------------------------------------------
$smirLoc = [ordered]@{
    # 出处：托洛茨基《我的生平》第三十三章（他转引赖丝纳的回忆；「斯维亚日斯克的良心」是同章原词）
    'hof_ic_smirnov_the_volga_bridgehead' = @('斯维亚日斯克桥头堡', '「拉里莎·赖丝纳把伊万·尼基季奇叫作『斯维亚日斯克的良心』。她写道：伊万·尼基季奇最受人们尊敬，因为大家都感觉到，在最危急的时刻，最沉着无畏的就是他。」')
    # 出处：同上（「五军将士」是同章原词）
    'hof_ic_smirnov_the_fifth_army' = @('第五集团军与「五军将士」', '「第五军的共产党员团结在斯米尔诺夫周围，形成了一个特殊的政治家庭……『五军将士』这个词在革命词典中有其特殊的意义，它意味着真正的革命者、克尽职守的人，更主要的是纯洁的人。」')
    # 出处：塞尔日《伊·尼·斯米尔诺夫之死》（1936-08）
    'hof_ic_smirnov_sibrevkom' = @('西伯利亚革命委员会', '「列宁建议把苏维埃化和安抚西伯利亚的任务交给伊万·尼基季奇……多亏他，亚洲北部的苏维埃化，在那里白军表现得极其残忍，几乎是在没有报复行动的情况下完成的。」')
    # 出处：同上
    'hof_ic_smirnov_far_eastern_republic' = @('远东共和国', '「斯米尔诺夫创建了远东共和国——一个临时的缓冲国，使苏维埃得以避开与日本的战争。」')
    # 出处：托洛茨基《我的生平》第三十三章
    'hof_ic_smirnov_posts_and_telegraphs' = @('苏联邮电人民委员部', '「国内战争结束后，五军将士同伊万·尼基季奇一起把他们的英雄主义转移到经济建设领域。……斯米尔诺夫先领导国防工业，后来任邮电人民委员。」')
    # 出处：同上 —— 收束到「根」：托洛茨基对他的总评价
    'hof_ic_smirnov_siberian_lenin' = @('西伯利亚的列宁', '「伊万·尼基季奇永远是个忠于职守的人，在这一点上，一个革命者接近于一个优秀军人，因而革命者可以成为一名优秀军人。伊万·尼基季奇只服从他的本性，他永远是勇敢、坚强的典范。」')
}

# -----------------------------------------------------------------------------
# 谢列布里亚科夫（Idx 7）—— 单线 4 节点 + 1 单结局（docs/42 §5）
# ⚠️ 五条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 带引号 = 原文节选（A2 = 1919-07-05 中央决议署名名单；E1 = 其女回忆录篇名）
#    🟡 不带引号 = 他人记述（A1 / A3 / A4 = 俄文维基），按 docs/23 §7.1 优先级 3
#       使用，**去引号以不冒充原文**；入游戏文本前需中译（docs/99 §13）
# 出处：
#   A2 = 托洛茨基《我的生平》第三十九章（中译本）—— 落盘 tmp/trotsky/txt/i3_military_strategy_39.txt
#   E1 = З. Л. 谢列布里亚科娃回忆录篇名「列宁称我的父亲为天才的工人」
#   A1 = 俄文维基〈Серебряков, Леонид Петрович〉
#   A3 / A4 = 俄文维基〈Народный комиссариат путей сообщения РСФСР〉（机构条）
# -----------------------------------------------------------------------------
$serebLoc = [ordered]@{
    # 出处：俄文维基（记述，已去引号）
    'hof_ic_serebryakov_kostroma' = @('科斯特罗马的驻军', '1917 年 2 月，他把一团人带出营房支持革命，并成为科斯特罗马工兵代表苏维埃的组建者之一。')
    # 出处：托洛茨基《我的生平》第三十九章 —— 1919-07-05 中央政治局与组织局决议的署名名单，他是签署人之一
    'hof_ic_serebryakov_central_committee' = @('党中央书记处', '「列宁、加米涅夫、克列斯京斯基、加里宁、谢列布里亚科夫、斯大林、斯塔索娃。」')
    # 出处：俄文维基〈НКПС РСФСР〉（记述，已去引号）
    'hof_ic_serebryakov_commissariat_of_transport' = @('交通人民委员部', '第一次世界大战与国内战争中，60% 以上的路网、90% 的机车、80% 的车厢被毁。')
    # 出处：同上 —— 这条正是他 1931 年那个总局的前身（奠基性的依据）
    'hof_ic_serebryakov_highways_and_motor_transport' = @('公路与汽车运输总局', '1921 年起，汽车、畜力与有轨电车运输的管理权移交给交通人民委员部。')
    # 出处：其女 З. Л. 谢列布里亚科娃回忆录篇名 —— 收束回「根」
    'hof_ic_serebryakov_brilliant_worker' = @('天才的工人', '「列宁称我的父亲为天才的工人。」')
}

# -----------------------------------------------------------------------------
# 普列奥布拉任斯基（Idx 8）—— 单线 4 节点 + 1 单结局（docs/45 §5）
# ⚠️ 五条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 A1 / A2 / A3 是【中文原文】（中文马克思主义文库，落盘 tmp/preob/txt/）
#    A1 ← 《俄共目前农村政策的基本原则》提纲（1922-03）
#    A2 ← 1924-01-12 莫斯科省第十一次代表会议决议案（他提出、得 61 票）
#    A3 ← 1924-05-28 俄共（布）第十三次代表大会发言
# 🚩 A4 / E1 是【转引】（⚠️ 需中译，记 docs/99 §14.3）——
#    因为《新经济学》正文没有中文数字化（中文站只给 CHM）→ 引不到他自己的原句
#    A4 = 人民委员会主席李可夫对他那本书的评语（俄文原话，优先级 2「他人的评价」）
#    E1 = 《新经济学》第二章的书用语（经俄文维基转引）
# -----------------------------------------------------------------------------
$preobLoc = [ordered]@{
    # 出处：《俄共目前农村政策的基本原则》提纲（1922 年 3 月）—— 中文原文
    'hof_ic_preobrazhensky_agrarian_theses' = @('农村政策提纲', '「国家还必须向这一阶层加重（同中农和贫农相比）征收实物税和货币税，让它承担更多的社会义务，同时为了不致破坏富农和富裕农民的经济，在可行范围内利用农村中业已开始的资本主义积累过程来增加社会主义积累。」')
    # 出处：1924-01-12 莫斯科省第十一次代表会议决议案（他提出、得 61 票）—— 中文原文
    'hof_ic_preobrazhensky_scissors' = @('压缩剪刀差', '「党在新经济政策时期的基本任务仍然是巩固国营工业和农业的结合，而在现阶段是压缩所谓剪刀差。」')
    # 出处：1924-05-28 俄共（布）第十三次代表大会发言 —— 中文原文
    'hof_ic_preobrazhensky_against_nepmen' = @('反对耐普曼的积累', '「必须加强斗争反对新经济政策时期中的积累。」')
    # 出处：李可夫（人民委员会主席）对《新经济学》的评语（俄文，⚠️ 待中译）
    'hof_ic_preobrazhensky_two_regulators' = @('两种规律的斗争', '「在普列奥布拉任斯基那里，农村只是工业的奶牛。」—— 人民委员会主席李可夫对《新经济学》的评语')
    # 出处：《新经济学》第二章的书用语（经俄文维基转引，⚠️ 待中译）
    'hof_ic_preobrazhensky_primitive_accumulation' = @('社会主义原始积累', '「社会主义原始积累规律」—— 为了保障工业化的积累，必须「剥削前社会主义的经济形式」。')
}

# -----------------------------------------------------------------------------
# 拉狄克（Idx 9）—— 单线 5 节点 + 1 单结局（docs/48 §5）
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# ⭐⭐ 本线是至今文案档次最高的一条：【6/6 全部是中文原文】，
#    且全部出自【本人审定的自传】（沿用加米涅夫那轮的判据：自传正文 = 本人审定，附录才是他人续写）。
# 出处：《拉狄克自传》（为《格拉纳特百科辞典》第 41 卷所写，1926）
#       落盘 tmp/radek/txt/（中文马克思主义文库「卡尔·拉狄克」篇目，GB2312）
#       ⚠️ 六条同出一篇自传但分属不同段落，与斯米尔诺夫「四块都引《我的生平》第 33 章」同型，不重复。
#       🆕 第 7 条（A5 中国的夺权斗争）出自 1924-10-26 的《真理报》文章，与自传不同源。
# -----------------------------------------------------------------------------
$radekLoc = [ordered]@{
    # 出处：《拉狄克自传》—— 中文原文
    'hof_ic_radek_central_europe_department' = @('外交人民委员部中欧司', '「在布列斯特和约签订以后，我领导了外交人民委员部的中欧司和中央执行委员会的对外关系司。」')
    # 出处：同上
    'hof_ic_radek_founding_of_the_kpd' = @('德国共产党的第一次代表大会', '「我参加了德国共产党第一次代表大会的组织工作。在罗莎·卢森堡和李卜克内西被害以后，我秘密地留在柏林，并参加了党的领导工作。」')
    # 出处：同上
    'hof_ic_radek_seven_pamphlets' = @('狱中的七本小册子', '「我于 2 月 15 日被捕，坐牢到 12 月份，从那里我出版了七本探讨众人注目的德国工人运动问题的小册子，积极地参与了德国共产党的领导工作。」')
    # 出处：同上
    'hof_ic_radek_german_october' = @('德国十月', '「在回俄国的途中，我受共产国际的派遣在 10 月间参与领导预定的起义。10 月 22 日我回来的时候，退却已经开始。我赞同中央委员会的这一决定。」')
    # 出处：同上（自传的最后一句）
    # ---- 支线 B（向东 · 中国）的三个节点，全部是【中文原文】，与自传不同源 ----
    # 出处：《中国的夺权斗争》（1924-10-26）—— 中文原文
    #   （《1919-1927 苏联〈真理报〉有关中国革命的文献资料选编 第 1 辑》，1985-01，第 63 页）
    'hof_ic_radek_the_struggle_for_power_in_china' = @('中国的夺权斗争', '「各省督军之间的斗争使中国国力日衰，但是，这种斗争拖延下去，各派军阀的力量也受到严重消耗，这就使中国的危机日益尖锐，迫使小资产阶级知识分子势力（这种势力在中国相当大）组织起来并试图从下面采取革命的方法来解决军事资本集团无法解决的中国统一问题。」')

    # 出处：《中国工人阶级的状况》（1925-08-13）—— 中文原文
    #   （《苏联报刊关于中国革命的文献资料 第 1 辑》，安徽大学马列主义教研室编；
    #     原为《亚洲工人阶级的状况》一文的第一节，原题《中国》）
    #   ⭐ 这一句是他本人写的「为什么要把这些写出来」—— 与主干「把革命办到俄国以外（武器是笔）」直接同轴
    'hof_ic_radek_the_condition_of_the_chinese_working_class' = @('中国工人阶级的状况', '「我们对于东方产业工人的状况知道得如此之少，因而对于任何一种让欧洲读者看到他们亚洲阶级弟兄生活境况的新的努力都应当表示欢迎。」')

    # 出处：《孙中山的社会政治思想》（1926-03-12）—— 中文原文
    #   （《1919-1927 苏联〈真理报〉有关中国革命的文献资料选编 第 1 辑》，1985-01，第 175 页）
    #   ⭐ 2026-09-20 用户口径：节点名取【社会政治思想】
    'hof_ic_radek_social_and_political_thought' = @('社会政治思想', '「孙中山对资本主义发展进程的分析是从生产成果分配不合理这一角度出发的，而不是以生产本身发生的变革为出发点。」')

    # 出处：同上（自传的最后一句）—— 中山大学，支线 A 走到头
    'hof_ic_radek_sunyatsen_university' = @('中山大学', '「从 1925 年起我是中山大学的校长，并参加苏联大百科全书编辑部的工作。」')
    # 出处：同上 —— 收束回「根」（自传篇名即「红色笔杆子，中山大学校长」）
    'hof_ic_radek_red_publicist' = @('红色笔杆子', '「在革命的所有年代里，我是《真理报》和《消息报》的撰稿人。我写的主要是关于对外政策和国际工人运动问题的文章。」')
}

# -----------------------------------------------------------------------------
# 斯米尔加（Idx 10）—— 单线 5 节点 + 1 单结局（docs/51 §5）
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 E1 = 【中文原文】（托洛茨基《斯大林评传》中译本，⭐ 是他自己的话）
#    🟡 A1/A2/A4 = 【中译稿】（en/ru 维基，⚠️ 需复核译文，docs/99 §十六）
#    🟡 A3/A5 = 【名单条目 / 书名】（ru 维基机构条目与著作表，不需译）
# 出处：
#   E1 = 托洛茨基《斯大林评传》第十六章（中译本）—— 落盘 tmp/smilga/txt/stalin1946-16.txt
#   A1 = en 维基〈Ivar Smilga〉（引 Rabinowitch / Trotsky《俄国革命史》vol.3）
#   A2 = en 维基〈Ivar Smilga〉（引 E. H. Carr《Socialism in One Country》）
#   A3 = ru 维基〈Госплан СССР〉历任副主席名单（机构条目 —— docs/23 §5 的方法）
#   A4 = ru 维基〈Смилга, Ивар Тенисович〉
#   A5 = ru 维基〈Смилга, Ивар Тенисович〉著作表
# -----------------------------------------------------------------------------
$smilgaLoc = [ordered]@{
    # 出处：en 维基〈Ivar Smilga〉（记述，⚠️ 中译稿）
    'hof_ic_smilga_finland' = @('芬兰的军队与舰队', '9 月，斯米尔加率领布尔什维克代表团出席赫尔辛基第三届区域苏维埃代表大会，并当选为区域苏维埃委员会主席。十月革命前夕，他受命返回芬兰，把 1500 名武装水兵送往彼得格勒，作为后备力量。')
    # 出处：en 维基（引 E. H. Carr，⚠️ 中译稿）
    'hof_ic_smilga_fuel_main_directorate' = @('燃料总局', '作为燃料管理局局长，斯米尔加是最早尝试为苏联工业的某一部分制定计划的苏联行政官员之一。作为一个计划化的信徒，他抱怨说：「国家机关的某些分子（而机关在很大程度上也是旧秩序的遗产）总体上反对计划。」')
    # 出处：ru 维基〈Госплан СССР〉历任副主席名单（机构条目）
    'hof_ic_smilga_gosplan' = @('国家计划委员会', '「1923 年秋 — 1926 年 11 月 23 日 —— 斯米尔加，伊瓦尔·捷尼索维奇 —— 副主席」—— 苏联国家计划委员会历任副主席名单')
    # 出处：ru 维基（记述，⚠️ 中译稿）
    'hof_ic_smilga_economics_institute' = @('莫斯科国民经济学院', '1924—1927 年，他任莫斯科国民经济学院院长，并在该院讲授苏联经济政策课程。')
    # 出处：ru 维基著作表（书名，不需译）
    'hof_ic_smilga_productive_forces' = @('生产力布局', '「《第二个五年计划中生产力布局的基本路线》」（1932 年）—— 这是他 20 部著作里的最后一部，也是他第二次任国家计划委员会副主席期间的工作。')
    # 出处：托洛茨基《斯大林评传》第十六章（中译本，⭐ 中文原文 —— 他自己的话）
    'hof_ic_smilga_the_healer_of_the_gaps' = @('弥合裂缝的人', '「在最初五年间，基本的倾向是弥合分歧 —— 旧的裂缝修补了，老的创伤平复了，反对者和好了，等等。而在后来的五年内，自 1923 年起，情况倒了过来；一切裂缝扩大了，一切分歧扩大并尖锐化了，所有的创伤化脓了。」')
}

# -----------------------------------------------------------------------------
# 托姆斯基（Idx 11）—— 单线 5 节点 + 1 单结局（docs/54 §5）
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 A4 = 【中文原文】（季诺维也夫 1921-03 报告里【记录他立场】的部分）
#    🟢 E1 = 【中文原文（他本人的话）】（1928-07-11 布哈林同加米涅夫密谈时转述他的话）
#    🟡 A1/A2/A5 = 【中译稿】（ru/en 维基记述，⚠️ 需复核译文，docs/99 §十七）
#    🟡 A3 = 【机构条目历任名单】（ru 维基〈ВЦСПС〉，不需译）
# 出处：
#   A1/A2/A5 = ru / en 维基〈Томский, Михаил Павлович〉/〈Mikhail Tomsky〉
#   A3 = ru 维基〈ВЦСПС〉历任名单（机构条目 —— docs/23 §5 的方法）
#   A4 = ⭐ 季诺维也夫《论工会在生产中的作用》（俄共十大，1921-03）L115 / L215
#        —— 落盘 tmp/zinoviev/txt/d2_union_1921_02.txt
#        ⚠️ 这一篇正是季诺维也夫线 D2 的文案出处（docs/33 §130）
#           → 本线【只引其中「关于托姆斯基」的部分】，不引季诺维也夫自己的论断
#   E1 = ⭐ 1928-07-11 布哈林与加米涅夫密谈记录 —— 落盘 tmp/kamenev/txt/pol_19280711_talk_b.txt L23
#
# 📌 §5.1 的欠缺已如实记档（docs/54 §5.1 / docs/99 §十七）：他【无中译本著作】、
#    中文马克思主义文库【也无他的篇目页】→ A1/A2/A5 三条是「中译稿 + 标注待复核」，
#    用户 2026-09-17 裁决「都按 A 选项」= 接受这个档次。
# ⚠️ 【不引】托洛茨基《斯大林评传》里的 8 处 —— 全是「右翼三人组」的集体出现，
#    引它会把线拉回「右翼」（docs/53 §6.3 的注）。
# -----------------------------------------------------------------------------
$tomskyLoc = [ordered]@{
    # 出处：ru / en 维基〈Томский, Михаил Павлович〉（记述，⚠️ 中译稿）
    'hof_ic_tomsky_printers_union' = @('印刷工人工会', '1906 年 8 月他回到彼得格勒，集中做工会组织：他为彼得堡印刷工人工会争到了一纸集体合同；1907 年他又组建了雕版工与石印工人工会并担任主席，随后把这个行会与石印工与印刷工人工会合并。')
    # 出处：ru 维基〈Томский, Михаил Павлович〉（记述，⚠️ 中译稿）
    'hof_ic_tomsky_moscow_trade_union_council' = @('莫斯科工会理事会', '1917 年 10 月 28 日，莫斯科军事革命委员会派托姆斯基前往彼得格勒；10 月 29 日列宁听取了他的报告，并答应援助莫斯科的革命力量。同年 12 月他当选莫斯科工会理事会主席。')
    # 出处：ru 维基〈ВЦСПС〉历任名单（机构条目，不需译）
    'hof_ic_tomsky_central_council_of_trade_unions' = @('全苏工会中央理事会', '「1918 年 10 月 9 日，全苏工会中央理事会执行委员会选举托姆斯基为执行局主席。」—— 全苏工会中央理事会历任主席名单：1918—1921 —— 托姆斯基；1922—1929 —— 托姆斯基。')
    # 出处：季诺维也夫《论工会在生产中的作用》（1921-03，俄共十大，⭐ 中文原文）
    #   —— 只引【记录托姆斯基立场】的两句，不引季诺维也夫自己的论断
    'hof_ic_tomsky_platform_of_ten' = @('「十人纲领」', '「托姆斯基同志和其他的工会工作者反对的是对工会搞『骑兵式的袭击』。」「而事实上工会在这场争论中完全正确。」')
    # 出处：ru 维基〈Томский, Михаил Павлович〉（记述，⚠️ 中译稿）
    'hof_ic_tomsky_the_silence_of_1921' = @('1921 年 5 月的沉默', '在第四届工会代表大会上，梁赞诺夫提出了工会独立于党的决议案。中央责成托姆斯基发言反对这一方案，他没有这样做，决议遂按梁赞诺夫的版本获得通过。中央全会随后严厉谴责了梁赞诺夫和托姆斯基，并把托姆斯基撤出工会工作。')
    # 出处：1928-07-11 布哈林与加米涅夫密谈记录（⭐ 中文原文 —— 他本人的话）
    #   —— 落盘 tmp/kamenev/txt/pol_19280711_talk_b.txt L23
    'hof_ic_tomsky_man_from_tomsk' = @('来自托木斯克的人', '「托姆斯基是这样描述的：我（托姆斯基）在国际事务中比你（布哈林）右 30 公里，但是我（托姆斯基）比斯大林左 100 公里。」')
}

# -----------------------------------------------------------------------------
# 里亚京（Idx 12）—— 单线 4 节点 + 1 单结局（docs/57 §5）
# ⚠️ 五条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# 🚩 两种档次严格分开：
#    🟢 A4 = 【中文原文】（1932 年纲领的核心诉求，zh 维基〈柳廷事件〉）
#    🟡 A1/A2 = 【中译稿】（ru / zh 维基记述，⚠️ 需复核译文，docs/99 §十八）
#    🟡 A3 = 【机构条目】（ru 维基〈Союзкино〉，不需译）
#    🟡 E1 = 【英译再中译】（1936-11-04 审讯笔录，⚠️ 需复核译文）
# 出处：
#   A1 = ru / zh 维基（1917-09 – 12 哈尔滨：工人与士兵代表苏维埃主席 + 《斗争》杂志编辑）
#   A2 = ru / zh 维基（1928 秋任《红星报》副编辑，红军机关报）
#   A3 = ⭐ ru 维基〈Союзкино〉机构条目（1930-02-13 成立 / 理事会 7 人 / 1930-08-25-31 有声电影会议）
#   A4 = ⭐ zh 维基〈柳廷事件〉（中文原文）—— 只用纲领诉求的【后半句】
#        ⛔ 前半句（结束集体化 / 放缓工业化）是布哈林与李可夫的题（docs/56 §2.5）
#   E1 = en 维基（1936-11-04 审讯笔录，**英译再中译**）
#
# ⚠️ 用户 2026-09-17 口径「删掉 A2，结局取 B」：
#    ⛔ 原 A2（伊尔库茨克省 1918–1921）已删 —— 它的位置与斯米尔诺夫（Idx 6）的西伯利亚题重叠；
#       ⭐ 它对应的官衔（伊尔库茨克省执行委员会主席）也一并移出官衔链。
#    ⭐ 结局由「不下跪」改为【「上留京诺的留京」】（收束回根）。
# ⚠️ 【不引】「斯大林是革命的掘墓人 / 党和革命的邪恶天才」等 —— 把斯大林当主语
#    （项目口径：文案里不出现斯大林当主语，docs/44 §9.3）。
# ⚠️ 【不引】他 1924–1927 反托洛茨基 / 压会场 / 战斗队那一段。
# -----------------------------------------------------------------------------
$ryutinLoc = [ordered]@{
    # 出处：ru / zh 维基（记述，⚠️ 中译稿）
    'hof_ic_ryutin_struggle_magazine' = @('《斗争》杂志', '1917 年 9 月至 12 月，他任哈尔滨工人与士兵代表苏维埃主席；同年在哈尔滨编辑《斗争》杂志，并担任俄国社会民主工党（布）哈尔滨委员会主席。')
    # 出处：ru / zh 维基（记述，⚠️ 中译稿）
    'hof_ic_ryutin_red_star' = @('《红星报》', '1928 年秋他被任命为《红星报》副编辑 —— 这是红军机关报 —— 同时继续担任联共（布）中央候补委员。')
    # 出处：ru 维基〈Союзкино〉机构条目（不需译）
    'hof_ic_ryutin_soyuzkino' = @('苏联电影', '「1930 年 2 月 13 日苏联人民委员会决议成立国家电影照相联合公司『Союзкино』；理事会共 7 人，米·尼·留京任主席。1930 年 8 月 25 至 31 日召开第一次全苏『Союзкино』有声电影生产-技术会议，会议决定组织有声电影的生产。」—— 苏联国家电影照相联合公司机构条目')
    # 出处：zh 维基〈柳廷事件〉（⭐ 中文原文）
    #   —— 纲领的核心诉求，⚠️ 只用【后半句】：前半句（结束集体化 / 放缓工业化）是农业题
    'hof_ic_ryutin_union_of_marxist_leninists' = @('马列主义者联盟', '「恢复之前开除出党的人的党籍（包括托洛茨基），并『重新开始』。」')
    # 出处：en 维基（1936-11-04 审讯笔录，⚠️ 英译再中译 —— 需复核，docs/99 §十八）
    'hof_ic_ryutin_verkhne_ryutino' = @('上留京诺的留京', '「由于我绝对确信自己无罪，并认为现在的起诉绝对非法、专横和偏袒，完全出于敌意和对一次新的、这次是血腥的报复的渴望，我已断然拒绝并将继续拒绝对我的指控认罪。」')
}

# -----------------------------------------------------------------------------
# 施利亚普尼科夫（Idx 13）—— 单线 6 节点 + 1 单结局（docs/61 §1）
# 🚩🚩 **第三版**（第一、二版都被用户否掉 —— docs/60 §1.0）。七条【全部是节选】。
# 🚩 两种档次严格分开：
#    🟢🟢 E1 = 【中文原文】（《工人反对派提纲》最完整的那句，⭐ 有《列宁全集》中文版第 32 卷第 187 页出处）
#    🟢 A3 / A4 / A5 = 【中文原文】（同上，《工人反对派提纲》/ 1920-12-30 他的报告）
#    🟡 A1 / A2 / A6 = 【中译稿】（en / ru 维基记述，⚠️ 需复核译文，docs/99 §十九）
# 出处：
#   A3/A4/A5/E1 = ⭐⭐⭐ 柯伦泰《工人反对派》（莫斯科 1921 年版，译者李星）
#        —— 落盘 tmp/shlyapnikov/txt/ao-1921.txt（合并副本 build/shlyapnikov-ao.txt）
#        ⚠️ 这四条在柯伦泰的书里，但【明确标注了「施略普尼科夫的报告」/「《工人反对派提纲》」】——
#          是他本人说的，不是柯伦泰说的 → 文案里写成【他的主张】
#   A1 / A2 = ru + en 维基（记述 —— 劳动人民委员任内的两份指令 / 用工会的人充实政府机关）
#   A6 = ru 维基（记述 —— 1922-03 十一大的提案）
#
# ⭐⭐ 本线的首尾呼应：**根是「别人把东西【交到他手上】」，E1 是「由他们【推出来】的机关」**。
# ⚠️ **四国车间的个人经历（穆罗姆街头 / 温布利的工会证 / 四国工厂）不占节点** ——
#    它们是【他的成长】，不是【他的历史产物】（docs/60 §1.1）；只在本文档与谱系里作背景。
# ⚠️ 【不做】「记录 / 回忆录」这条轴（docs/59 §2.6）—— 「出版」题被三处占，且它【推不出主干】。
# ⚠️ 【不引】1932-02-19 组织局决议里「对列宁及其党的诽谤性捏造」这一句 —— 与项目口径冲突。
# ⚠️ 【不引】十一大上他讽刺列宁「领导着一个不存在的阶级的先锋队」—— 把列宁当对象、且是讽刺。
# -----------------------------------------------------------------------------
$shlyapnikovLoc = [ordered]@{
    # 出处：ru + en 维基〈Шляпников / Shliapnikov〉（记述，⚠️ 中译稿）
    'hof_ic_shlyapnikov_workers_control' = @('工人监督', '作为劳动人民委员，他帮助起草了关于工人对工业的监督与工业国有化的重要指令。')

    # ⛔ 2026-09-19 用户口径「A2 删去」→ 'hof_ic_shlyapnikov_who_sits_in_the_commissariat' 整条已移除
    # 出处：⭐ 柯伦泰《工人反对派》1921 年中文版（《工人反对派提纲》原句，中文原文）
    'hof_ic_shlyapnikov_not_syndicalism' = @('不是工团主义', '「现在工人工会对国民经济机构消极协作，应吸引前者积极与个体参与整个国民经济的管理。」')
    # 出处：⭐ 柯伦泰《工人反对派》1921 年中文版（1920-12-30 施略普尼科夫报告，中文原文）
    'hof_ic_shlyapnikov_producers_congress' = @('生产者代表大会', '「我们认为，我国生产力的恢复和发展，只有改变国民经济管理的整个组织体系之条件下，才有可能。」')
    # 出处：⭐ 柯伦泰《工人反对派》1921 年中文版（1920-12-30 施略普尼科夫报告，中文原文）
    'hof_ic_shlyapnikov_through_the_workers' = @('通过工人，还是瞒着工人', '「争论的本质，在于正在经历的过渡时刻中，我们共产党将推行自己的经济政策，是通过组织在工会里的工人群众呢，还是瞒着他们，用官僚手段，通过典范的官员呢？」')
    # 出处：ru 维基〈Шляпников, Александр Гаврилович〉（记述，⚠️ 中译稿）
    'hof_ic_shlyapnikov_qualification_from_the_shop' = @('生产的资格', '在 1922 年 3 月的第十一次代表大会上，工人反对派要求在领导层里清除「白手套」，并要求每个党的官员一年中至少有三个月在工业或农业中从事体力劳动。')
    # 出处：⭐⭐ 柯伦泰《工人反对派》1921 年中文版（《工人反对派提纲》原句，中文原文）
    #   ⭐ 原文见《列宁全集》中文版第 32 卷第 187 页（《俄共（布）第十次代表大会》）
    'hof_ic_shlyapnikov_the_body_they_elect' = @('由他们选出的机关', '「管理国民经济之权应当属于联合在各种产业工会中的生产者的全俄代表大会，应当由他们选出中央机关来管理整个国民经济。」')
}

# -----------------------------------------------------------------------------
# ⭐ 加里宁（Idx 14）的文案 —— 2 / 6 是中文原文（docs/62 §8.1）
#   ✅ A1 / E1 = 【托洛茨基中译本】里的中文原文
#   ⚠️ A2 / A3 / A4 / A5 = 中译稿（只有 `[W]` ru 一个来源）→ docs/99 待补
# -----------------------------------------------------------------------------
$kalininLoc = [ordered]@{

    # ---- A1 · 农民出身的元首（1919-03-30）----
    # 出处：⭐ 托洛茨基（中文译本，tmp/trotsky/txt/i1_marxism_opposition_38.txt）——【中文原文】
    #   ⚠️ 原文是「就在 1919 年，加里宁**在我的提议下**，作为接近中农并较了解他们疾苦的人当选为中央执行委员会主席。」
    #   ⚠️⚠️ 本线**节选掉「在我的提议下」** —— 因为「提名是谁提的」**两说并存**
    #      （托洛茨基在《革命家肖像》里自称是他提的；俄文维基记的是列宁推荐、加米涅夫执行）
    #      → 本项目不裁，所以文案里**不写谁提的名**，只写「为什么是他」（这一条两说一致）。
    #   ⭐ 另一条（备选，未采用）：列宁 1919 年的推荐词（`[W]` ru 转引，中译稿）——
    #      「他自己就是特维尔省的农民，与农民经济有密切联系……他具有接近广大劳动群众的本领」
    'hof_ic_kalinin_a_peasant_head_of_state' = @('农民出身的元首', '就在 1919 年，加里宁作为接近中农并较了解他们疾苦的人，当选为中央执行委员会主席。')

    # ---- A2 · 扫除文盲（1923）----
    # 出处：`[W]` ru 记述 —— ⚠️ 中译稿
    #   ⚠️ 英文维基完全不提这条；中文维基也没有 → **只有俄文维基一个来源**
    'hof_ic_kalinin_down_with_illiteracy' = @('扫除文盲', '1923 年他出任「扫除文盲」协会主席，协调全苏的教育工作。协会名下在全国建立了 1.1 万个扫盲点；到 1930 年代末，识字率逼近 90%。')

    # ---- A3 · 全民国家（1926）----
    # 出处：`[W]` ru 记述 —— ⚠️ 中译稿
    'hof_ic_kalinin_the_state_of_the_whole_people' = @('全民国家', '1926 年，他第一次在苏联的政治话语里提出：无产阶级专政的国家，应当逐步被「全民国家」所取代。')

    # ---- A4 · 接待室（1920s–1940s）----
    # 出处：`[W]` ru（「за четверть века через приёмную Калинина прошло около восьми миллионов посетителей」）
    #       + `[W]` zh（「不少寫信給加里寧，而加里寧也常常介入審判，因此救了不少無辜的人」）—— ⚠️ 中译稿
    'hof_ic_kalinin_the_reception_room' = @('接待室', '苏联公民习惯写信给他：被没收、被冤捕、想进军校、找不到工作。二十五年间，约八百万人走过他的接待室，很多请求被满足。')

    # ---- A5 · 没有根据的行动（1932-05-04）----
    # 出处：⭐ **他本人的手写批注**（`[W]` ru `[G]` 转引）——
    #   «Я считаю необоснованной такую операцию.»（我认为这样的行动没有根据）
    # ⚠️⚠️ **不能写成因果**：维基原文只说**时间相邻**（他写下了那句话；两周后政治局撤销了决定），
    #    **没有说「因为他所以撤销」**（docs/62 §8.4 已登记为待核）
    'hof_ic_kalinin_an_unfounded_operation' = @('没有根据的行动', '1932 年 5 月 4 日，在关于流放 38 000 户农民家庭的表决单上，他写下一句：「我认为这样的行动没有根据。」两周后，政治局撤销了这个决定。')

    # ---- E1 · 全联盟的老家长 ----
    # 出处：⭐⭐ 托洛茨基《斯大林评传》**中译本**第五章（tmp/kalinin/txt/stalin-05.txt）——【中文原文】
    #   原文：「在铁路工厂罢工工人名单中有**苏维埃共和国未来的主席、锁匠加里宁**和另一个俄国工人、
    #          斯大林未来的岳父阿利路也夫。」
    # ⭐⭐ 这一句把「**锁匠**」与「**未来的主席**」放在同一个短语里 ——
    #    **正是本线的全部**：一个从车间里出来的人被放在最高的位置上，然后他用那个位置去够人。
    # ⚠️ «全联盟的老家长»（всесоюзный староста）是**托洛茨基 1919 年给他起的绰号**
    #    （1919 年那版是 «всероссийский староста»）→ **文案里标明是别人给他起的**，不要写成「他自己叫自己」。
    'hof_ic_kalinin_the_all_union_elder' = @('全联盟的老家长', '他做了二十七年国家元首，人们叫他「全联盟的老家长」。晚年他在中央委员会里说：「我是全联盟的老家长，谁都认识我。」')
}

$litvinovLoc = [ordered]@{

    # ---- A1 · 火星报的代办员（1902-1904）----
    # 出处：⭐ 托洛茨基《斯大林评传》**中译本**（tmp/kalinin/txt/stalin-06.txt）——【中文原文】
    #   原文：「有个记者——**显然就是后来的李维诺夫，他根本不懂格鲁吉亚语**——**自国外报道**，
    #          说梯弗里斯出现了一本小册子，『造成了轰动』。」
    # ⭐⭐ 这一句恰好把他的第一份工作说全了：**「自国外报道」** —— 他在国外，往国内报。
    #   ⚠️ 「他根本不懂格鲁吉亚语」是托洛茨基的**带刺的旁注**，照引不改（是他自己的话）。
    # ⭐ 另一条（未采用，给【根】留着，不进游戏）—— 同一书中译本 stalin-05：
    #   「参加上述**基辅越狱事件**的10个人（**其中包括苏联未来的外交家李维诺夫**）不久以后都到了国外」
    'hof_ic_litvinov_a_courier_of_iskra' = @('火星报的代办员', '「有个记者——显然就是后来的李维诺夫，他根本不懂格鲁吉亚语——自国外报道，说梯弗里斯出现了一本小册子，『造成了轰动』。」—— 托洛茨基《斯大林评传》中译本')

    # ---- A2 · 战俘交换协议（1920-02-12）----
    # 出处：⭐ 列宁 / 托洛茨基电报（《列宁全集》/《托洛茨基文集》**中文版**，tmp/smirnov/mia/ch34.txt）——【中文原文】
    #   原文：「主要的是，这类报导应该寄给沃罗夫斯基①和**李维诺夫②**。这可以通过契切林办。」
    #     ① 沃罗夫斯基 = 驻斯堪的纳维亚国家大使  ② 李维诺夫 = 驻爱沙尼亚全权代表、外交副人民委员……
    # ⭐ 这封电报里的一句话点透了 A2 的位置：**「这类报导应该寄给李维诺夫」** ——
    #   1918 年他在国外，莫斯科有事要办，**寄给他**。二年后他把对方的政府请到了桌子对面。
    # ⚠️⚠️ 电报原文是节选 —— 只引那一句，**不把整封电报搬进来**。
    'hof_ic_litvinov_the_prisoner_exchange_agreement' = @('战俘交换协议', '「主要的是，这类报导应该寄给沃罗夫斯基和李维诺夫。这可以通过契切林办。」—— 列宁 / 托洛茨基电报（中文版文集）')

    # ---- A3 · 李维诺夫议定书（1929-02）----
    # 出处：`[W]` en —— ⚠️ 中译稿
    #   「Litvinov, who was frustrated by the failure of the Kellogg-Briand Pact signatories to ratify
    #     the treaty, proposed the Litvinov Protocol, in which signatories formally proclaimed
    #     themselves in mutual compliance with the pact's goals.」
    # ⚠️ 中文维基完全不提这件事；俄文维基也只提一句 → **只有英文维基一个来源**
    'hof_ic_litvinov_the_litvinov_protocol' = @('李维诺夫议定书', '1928 年的凯洛格-白里安公约把放弃战争写进了纸面，签署国却迟迟不批准。1929 年 2 月，苏联、波兰、罗马尼亚、拉脱维亚、爱沙尼亚先在莫斯科互相承诺遵守它 —— 这就是《李维诺夫议定书》。')

    # ---- A4 · 侵略的定义（1933-02-06）----
    # 出处：`[W]` en —— ⚠️ 中译稿（但**引的是他本人的原话**）
    #   法国代表保罗-邦库尔的质问 + 他的反问：
    #   「Would small nations be less insecure after their powerful neighbours who have disarmed
    #     than they are now when, in addition to economic, financial, territorial and other
    #     superiorities possessed by the great powers, the latter also enjoy the immense advantage
    #     of greater armaments.」
    # ⚠️ 本线【不写】后面那件事（1946 年英国政府、1939 年芬兰都拿他的定义来指控苏联）——
    #   那是评价，不是他的产物（docs/65 §2.5）。
    'hof_ic_litvinov_the_definition_of_aggression' = @('侵略的定义', '1933 年 2 月 6 日，法国代表保罗-邦库尔问他：全面裁军之后，小国难道不更危险吗？他反问：「小国在强大邻国裁军之后，会比现在更不安全吗？」')

    # ---- A5 · 苏法互助条约（1935-05）----
    # 出处：`[W]` en + `[W]` zh —— ⚠️ 中译稿
    #   ⭐⭐ 那句「只有法国先履行援助，捷克才有义务援助」是 **1935-05-16 苏捷条约议定书**的内容，
    #      也正是本条【外交联动】的机制来源（docs/66 §3.4）：
    #      **法国拿到保障，捷克只拿到好感** —— 用数值差把史实的那条链子写出来。
    # 🔄 用户 2026-09-19 口径：**删掉「1934 年苏联加入国联」那一句**（二战国联已实际失效）。
    'hof_ic_litvinov_the_franco_soviet_treaty' = @('苏法互助条约', '1933 年 11 月，他在华盛顿谈成了美苏建交。1935 年 5 月，他与法国签下互助条约；同月又与捷克斯洛伐克签了一份 —— 但捷克的那一份附着一句话：只有法国先履行援助，捷克才有义务援助。')

    # ---- E1 · 外交人民委员会顾问（1939-05 – 1941-11）----
    # 🚩🚩 用户 2026-09-19 裁决取【乙】—— 旧名「国联的席位」被否
    #   （理由：**二战国联已经实际失效**，拿一个失效的组织当结局名不合适）
    # 出处：`[W]` zh（年表：1939-05 – 1941-11 苏联外交人民委员会顾问；
    #   1941-11 – 1943-08 驻美特命全权大使）—— ⚠️ 中译稿
    # ⭐⭐⭐ 名字的份量全在这四个字里：**九年的人民委员，换成了两个字**。
    # ⭐⭐ 而它底下藏着的是「他还在」：**两年后德国打进来，他被重新派了出去**。
    #   → **结局是向上的，不是刑场**（与前几条线的禁区一致）。
    # ⛔ 全文案不出现「斯大林」当主语（项目口径，docs/44 §9.3）
    # ⛔ 不写「他以犹太人身份被撤」—— 族裔一个字都不进游戏（docs/65 §8.4）
    'hof_ic_litvinov_the_advisor_to_the_commissariat' = @('外交人民委员会顾问', '1939 年 5 月之后，他名下写的职务是「外交人民委员会顾问」。两年后德国打了进来，他被重新派了出去 —— 这一次是驻美特命全权大使。')
}

$sokolnikovLoc = [ordered]@{

    # ---- A1 · 银行国有化（1917-12）----
    # 出处：⚠️ 译自英文维基
    # ⛔ 不写 1918-03 布列斯特和约（**他是签字的人**，但那是托洛茨基 Idx 1 的招牌）
    'hof_ic_sokolnikov_the_nationalisation_of_the_banks' = @('银行国有化', '十月革命之后，他先做的不是打仗，是把银行拿到手里 —— 接管俄国的银行，并把它们并成一套集中的银行体系。')

    # ---- A2 · 突厥卢布（1920）----
    # 出处：⚠️ 译自俄文维基
    # ⚠️ 【不写】他 1921-1922 在突厥斯坦与当地领导层的冲突（docs/68 §2.5）
    # ⛔ 不画/不写地理与边区（那是斯米尔诺夫 Idx 6 的题）—— 本节点只讲「钱」
    'hof_ic_sokolnikov_the_turkestan_rouble' = @('突厥卢布', '1920 年他去了突厥斯坦。在当地，贬得几乎不值钱的纸币叫突厥卢布；他把它们换成了全苏货币。同一年，那里的余粮收集制也先一步取消了 —— 比全国早。')

    # ---- A3 · 切尔沃涅茨（1922-11）----
    # 出处：✅ **他本人的原文** —— 索柯里尼柯夫《俄国的物价下跌》（1922-06-30，MIA 英文 archive）
    #   「Nothing in this world is permanent, much less the value of paper money.」
    # ⭐ 那句话与切尔沃涅茨是【同一年】—— 先说「纸币的价值不永久」，再做一张有准备的纸币。
    'hof_ic_sokolnikov_the_chervonets' = @('切尔沃涅茨', '1922 年 11 月，国家银行开始发行切尔沃涅茨：它法定等于十卢布的沙皇金币；四分之一由金、贵金属与外汇保证，四分之三由易售的商品与短期债券保证。「这世上没有什么是永久的，纸币的价值尤其不是。」—— 索柯里尼柯夫《俄国的物价下跌》')

    # ---- A4 · 一美元值多少（1923-01）----
    # 出处：✅ **他本人的原文** —— 索柯里尼柯夫《俄国卢布与德国马克》（1923-01-16，MIA 英文 archive）
    #   ⭐⭐ 这一句是全项目最有用的一句邻接界线（docs/68 §2.4 #1 / docs/70 §2.3）：
    #      **他把「市场不肯认钱」与「政府不肯承认政府」并列** ——
    #      → **李维诺夫（Idx 15）争的是后者，本线争的是前者。**
    # ⛔ 不写「1922 年放松对外贸易垄断」（与李维诺夫 / 拉狄克 Idx 9 的邻接面，docs/68 §2.5）
    'hof_ic_sokolnikov_what_a_dollar_costs' = @('一美元值多少', '1923 年 1 月，他把两个交易所的数字排在同一张表上：一美元在柏林值多少马克、在莫斯科的自由交易所值多少卢布。结论是：马克贬值的速度是卢布的 2 倍半。「那些做纸币生意的国家，拒绝承认俄国纸币是它们家族的一员……正如欧洲各国政府拒绝『承认』苏维埃政府是一个政府。」—— 索柯里尼柯夫《俄国卢布与德国马克》')

    # ---- A5 · 国家资本主义（1928）----
    # 出处：✅ **他本人的原文**（1928，MIA 英文 archive）
    # 📌 用户 2026-09-20 口径：「**国家资本主义就这么用吧**」——
    #    ⚠️ 这个词在中文语境有别的政治含义，但**它确实是索柯里尼柯夫 1922 年的书名**
    #       （《国家资本主义与新财政政策》），也是他自己对苏联经济的判断。
    # ⚠️ 本节点是**松咬合**（官职升到 Lv3 靠的是 1928-07 那次谈话事件，不是这句话）—— 不编因果
    # ⚠️ 【不写】他与布哈林的私人交往 / 1925 年那次一起出访（docs/68 §2.5）
    'hof_ic_sokolnikov_state_capitalism' = @('国家资本主义', '「即使在私有财产原则占主导的国家，私营企业的无限竞争也在稳步退却，让位于巨大的金融和工业公司……在这种条件下，国家的不干涉政策将意味着国家权力的瘫痪。」—— 索柯里尼柯夫，1928 年')

    # ---- E1 · 硬通货（结局）----
    # 📌 用户 2026-09-20 口径：「**从纸币到硬通货改名叫硬通货**」→ 「硬通货」
    #    ⭐ 名字的出处仍是他 **1924 年的书名**《От дензнака к твердой валюте》（从纸币到硬通货）
    # ⭐⭐⭐ 但结局的份量落在这句 **他人记述的原文** 上 ——
    #    巴扎诺夫（斯大林的秘书）：**「他完成了交给他的每一项任务 —— 例如创造了第一个稳定的苏联货币。」**
    #    ⭐ 「**他完成了交给他的每一项任务**」—— 一个技术官员一生的全部评价。
    # ⛔ 全文案不出现「金本位」（原版图标已占；且史实方向相反 —— 他恢复的是金准备）
    # ⛔ 不写「被请回来」（原版 SOV_the_need_for_policy_changes 已占）
    # ⛔ 全文案不出现「斯大林」当主语（项目口径，docs/44 §9.3）
    # ⛔ 不写他的死（1939-05-21）与十七人审判（布哈林 / 李可夫是本 mod 已实装的本人）
    'hof_ic_sokolnikov_hard_currency' = @('硬通货', '「他完成了交给他的每一项任务 —— 例如创造了第一个稳定的苏联货币。」—— 巴扎诺夫这样记下他')
}

$tukhachevskyLoc = [ordered]@{

    # ---- A1 · 军事学院（1921-08）----
    # 出处：中文维基（转简体）
    'hof_ic_tukhachevsky_the_military_academy' = @('军事学院', '1921 年 8 月 27 日，他担任由总参谋学院改名而来的工农红军军事学院院长。')

    # ---- A2 · 正规军（1930-01）----
    # 出处：中文维基（转简体），两句话【直接出自同一段】—— 不分拆
    # 🚩🚩 这句就是与托洛茨基（Idx 1）的界线：**托洛茨基建了红军；他把它改成正规军。**
    'hof_ic_tukhachevsky_the_regular_army' = @('正规军', '1930 年 1 月，他提出部队改革的建议：不仅涉及武器现代化，还提出要重组军队 —— 反对民兵制，要求建立一支正规军；并要求增加战车和飞机的产量、削减骑兵单位。')

    # ---- A3 · 空降兵与战车（1931-32）----
    # 出处：中文维基（转简体）＋俄文维基的编组三分法（转译）
    'hof_ic_tukhachevsky_airborne_and_tanks' = @('空降兵与战车', '他于 1931 年组建了世界上第一支伞兵部队；战车依任务被划分为直接支援步兵、远程支援与远程突击三类编组，分別配备轻型、中重型与高速战车。')

    # ---- A4 · 纵深战斗指示（1933→35）----
    # 出处：中文维基（转简体）
    # ⭐ 本节点【本体就是这份文献的年表】—— 只有三行，但每一行都是一次真的修改与试行。
    'hof_ic_tukhachevsky_the_deep_battle_instructions' = @('纵深战斗指示', '相关规范历经 1933 年的《纵深战斗组织临时指示》与 1935 年的《纵深战斗指示》，先在部队里逐次试行、修正。')

    # ---- A5 · 四个梯次（1936）----
    # 出处：中文维基（转简体），逐字对应四个梯次
    # ⚠️ 本节点【长】是有意的 —— 四个梯次本身就是一个四级结构，压不成一句话。
    'hof_ic_tukhachevsky_the_four_echelons' = @('四个梯次', '进攻须以四个梯次同时打击敌军纵深：航空兵首先夺取制空权并轰炸敌阵地；由战车、步兵与火炮组成的诸兵种合成突击集群突破敌军防线；机械化部队随即向纵深扩张战果、包围敌军与后方要地；预备队则负责巩固所得。')

    # ---- E1 · 工农红军野战条令（结局）----
    # ⭐⭐⭐ 1936 年《工农红军野战条令》（PU-36）的正式中文名 —— 史实专名（判据 F 过）
    # ⭐⭐ 首尾同轴：**根是他手里只有【别人的】一本野战手册；
    #    E1 是那本野战手册【由他署名】、全军照着它组织与训练**。
    # ⚠️ 宗旨那句是**中文维基转引的条令文字** → 已用「被概括为」标明，不冒充原文。
    # ⛔ 不写 1937-06-11 的审判与枪决（全网禁区）；也不写他 1935-11 授元帅
    #    （授衔在条令定稿之前，写进去会把因果说错）
    # ---- B1 · 联盟国防（1926-12-26）----
    # 出处：俄文维基〈Тухачевский〉（本项目转译）—— 他 1926-12-26 的报告《Оборона Союза Советских
    #   Социалистических республик》（苏维埃社会主义共和国联盟的国防），共 8 条结论，此处取第 6/7/8 条。
    # 🚩 与托洛茨基（Idx 1）`state_planning`「经济计划化」的界线：托问「谁来管国有经济的计划」；
    #    本节点问「打起来能拿出多少」—— 把工业与铁路一起算进国防任务。
    # ⚠️ 转译，不冒充中文原文（AGENTS.md 规则 9：注明出处）。
    'hof_ic_tukhachevsky_the_defence_of_the_union' = @('联盟国防', '1926 年 12 月 26 日，他在报告《苏维埃社会主义共和国联盟的国防》里写道：我们贫乏的物质作战动员储备只够战争的第一阶段；只有武装力量、铁路运输和工业都具备高动员准备度，工农红军才能完成苏联的国防任务；无论是红军还是国家，都没有为战争做好准备。')

    # ---- B2 · 军事经济动员（1930-01）----
    #   ⭐ 2026-09-20 用户口径：「**B2 生产可能性改名为军事经济动员**，我当时说军事经济动员
    #      就是因为『生产可能性』这个词听起来怪怪的」—— 改名不改内容（「生产可能性」是他方案里的原文关键词，
    #      仍留在【文案】里，读者知道它是什么）。focus id 一并改为 military_economic_mobilization（🚩 美术尚未动笔）。
    # 出处：中文维基（转简体）—— 与他 1930-01 那份部队改革方案【同一份文件】，此处取【经济面】
    #   ⚠️ 同一份方案的【组织面】「反对民兵制、要求建立正规军」在 A2「正规军」—— 一份方案，两个面。
    'hof_ic_tukhachevsky_military_economic_mobilization' = @('军事经济动员', '他主张，红军的规模应依工业化后的「生产可能性」重新估算，而非沿用传统的逐年递增方式；他从汽车与拖拉机的产能推算，认为苏联战时每年可生产约四万架飞机与十万辆战车，并据此构想一支拥有二百六十个师、四万架作战飞机与五万辆作战战车的庞大军队。')

    # ---- B3 · 空中机械化（1931）----
    # 出处：中文维基（转简体）＋俄文维基（转译，末句）
    # 🚩 与 A3「空降兵与战车」的界线：A3 = 具体的兵种（第一支伞兵部队 / 战车三类编组）；
    #    本节点 = 跨兵种的构想与规划方法。
    'hof_ic_tukhachevsky_air_mechanization' = @('空中机械化', '他受恩格斯影响，主张未来战争将是动员国家全部经济与政治资源的大规模战争，并提出「空中机械化」的构想，即把航空、战车、无线电与化学战整合为一体；他要求完全以新的方式对待整个武器系统、组织、战术和部队训练的规划。')

    'hof_ic_tukhachevsky_the_field_regulations' = @('工农红军野战条令', '1936 年的《工农红军野战条令》把前几年试行过的东西写成了全年的令；其宗旨被概括为：使敌人「在其部署的全纵深遭到歼灭、包围并歼灭」。')
}

$voznesenskyLoc = [ordered]@{

    # ---- A1 · 为实现当前阶段的计划而斗争（1931-10-08）----
    # ⭐⭐⭐ 节点名 = 【他自己文章的标题】（史实专名，判据 F 过）
    # 🟢 中文原文（中文马克思主义文库《为实现当前阶段的计划而斗争》，译自《真理报》1931-10-08）
    'hof_ic_voznesensky_the_fight_for_the_plan' = @('为实现当前阶段的计划而斗争', '在新经济政策的最后阶段和社会主义时期的最初阶段的现时期，计划的作用异乎寻常地增大了。……如果说价值规律是商品资本主义生产的运动规律，那末社会主义计划则是苏维埃经济的发展规律。—— 沃兹涅先斯基《为实现当前阶段的计划而斗争》，《真理报》1931 年 10 月 8 日')

    # ---- A2 · 列宁格勒计划委员会（1935–1937）----
    # 🟡 中译稿（ru 维基）
    # ⚠️ 一处两说：en 维基作「head of the Leningrad Control Commission」→ ⭐ 取 ru 的【市计划委员会主席】
    # ⚠️ 不写「大清洗腾出位子」（别人替他做的事，不是他的主张）
    'hof_ic_voznesensky_the_leningrad_plan' = @('列宁格勒计划委员会', '1935 年至 1937 年，他是列宁格勒市计划委员会主席，兼任列宁格勒市苏维埃执行委员会副主席。这是他第一次亲手做一张表。')

    # ---- A3 · 国家计划委员会（1938-01-19）----
    # 🟡 中译稿（ru 维基 + 历史学博士赫列夫纽克的评语）
    # ⛔ 【不写】他 1939–1941 主张的「建立巨大的原料、燃料、冶金与生产储备」
    #     —— 原版 `SOV_increase_state_reserves`「增加国家资源储备」已占
    'hof_ic_voznesensky_the_state_planning_committee' = @('国家计划委员会', '1938 年 1 月 19 日起，他是苏联国家计划委员会主席（1942 年 12 月 8 日再任）。在这个位子上，他「承担了政府里的主要部分工作」。—— 历史学博士奥·赫列夫纽克')

    # ---- A4 · 安置疏散企业（1941-08-07）----
    # 🟢 本人著作节选（《苏联战时经济》第三章「国民经济的转轨」，本项目据 1948 年官方英译本转译）
    # ⭐⭐⭐ 节点名 = 【国防委员会第 421 号决议的正式名】（史实专名，判据 F 过）
    # 🚩🚩 与原版 `SOV_move_industry_to_the_urals` 的界线：原版做【搬】，本线做【决定往哪搬 + 重复生产】
    # ⛔ 不写「他主持了疏散委员会」（疏散委员会主席是卡冈诺维奇）
    'hof_ic_voznesensky_the_placement_of_plants' = @('安置疏散企业', '1941 年 8 月 7 日，国防委员会第 421 号决议《关于安置被疏散企业的程序》把保障工业疏散与动员的任务交给国家计划委员会；各人民委员部必须与它协商，确定工厂的最终落脚点，并组织重复生产。「与基本工业设备一起，工人和工程技术人员被转移到国家的东部地区，而这些地区新生产能力的建设被全力加速。」—— 沃兹涅先斯基《苏联战时经济》')

    # ---- A5 · 弹药生产计划（1941–1942）----
    # 🟢 本人著作节选（职位 = ru 维基〈Госплан СССР〉；数字 = 《苏联战时经济》第十三章「生产的计划化」）
    'hof_ic_voznesensky_the_ammunition_plan' = @('弹药生产计划', '他被任命为国防委员会负责「工业完成弹药生产计划」的全权代表。1943 年，122 毫米炮弹的产量比 1942 年增加了 90%，82 毫米迫击炮弹增加了 81%，152 毫米炮弹增加了 60%。—— 沃兹涅先斯基《苏联战时经济》')

    # ---- E1 · 卫国战争的政治经济学（结局）----
    # ⭐⭐⭐ 节点名 = 【他自己给这件事起的学名】—— 书引言第一段：「社会主义政治经济学中一个专门篇章」
    #   🔴🔴 【不叫「战时经济」】：原版 `SOV_war_economy` 的中文名就是它
    #   🔴 【也不叫「苏联战时经济」】= 书名的简称，与原版中文名只差两个字（第 0 步专门绕开过这个坑）
    # ⭐⭐ 首尾呼应：与「根」A1《论政治经济学的对象问题》（1931）是【同一门学问】——
    #   根是一篇论文的题目，E1 是这门学问里以他这件事命名的一个篇章
    # 🟢 本人著作节选（《苏联战时经济》引言第一段）
    #   🚩🚩 【出处只能取第一处】：书里第二处出现「the political economy of the Patriotic War」时，
    #     紧跟着「社会主义战时经济理论是由我们的领袖、伟大的斯大林创立的」
    #     → ⛔ 触项目口径「文案里不出现斯大林当主语」；第一处后面接的是「苏联各族人民民族利益的统一」，安全
    #   ⚠️ 中译本正式书名在末尾注明（让玩家/后人知道中译本存在）
    #   📌 2026-09-20 用户口径「有更好的可以采用更好的」（`docs/23` 判据 J）→ 由「苏联战时经济」改取本条
    #   📌 focus id 保留 `_the_war_economy`（英文 slug 语义仍成立；🔴 改 id 会连带 sprite 名与美术文件名，代价大于收益）
    'hof_ic_voznesensky_the_war_economy' = @('卫国战争的政治经济学', '「1941–1945 年的伟大卫国战争使苏联国民经济发生了根本变化；它改造了苏联经济以保证战争的胜利，并产生了战时特有的经济规律。这个时期在苏联历史上成为社会主义经济的一个特殊时期 —— 战时经济时期，并构成社会主义政治经济学中一个专门篇章 —— 卫国战争的政治经济学 —— 的主题。」—— 沃兹涅先斯基《苏联战时经济》引言（中译本名《卫国战争期内的苏联战时经济》，外国文书籍出版社，1948）')
}

$pyotrSmirnovLoc = [ordered]@{

    # ---- A1 · 工农红军海军局（1926）----
    # 出处：`[W]`zh〈苏联海军〉—— ⚠️ 中译稿
    # ⭐ 这就是【根】：1926 年，海军在公文里还只是一个「局」
    'hof_ic_pyotr_smirnov_the_naval_directorate' = @('工农红军海军局', '1926 年的苏联海军，指挥归陆海军人民委员部；在部里，它设的只是「苏联海军局」—— 同一年改称「工农红军海军局」。—— 中文维基〈苏联海军〉')

    # ---- A2 · 海军总参谋部（1937-12-30）----
    # 出处：⭐ 1937-12-30 决议第 1 条（一手件）+ `[W]`zh〈苏联海军〉—— ⚠️ 中译稿
    'hof_ic_pyotr_smirnov_the_general_staff' = @('海军总参谋部', '中央执行委员会与人民委员会决议：一、成立全联盟的海军人民委员部。同一天，舰队的作战指挥机关「海军总参谋部」也随之成立。—— 1937 年 12 月 30 日苏联中央执行委员会与人民委员会决议 / 中文维基〈苏联海军〉')

    # ---- A3 · 海军航空兵（1938-01-01）----
    # 出处：`[W]`zh〈苏联海军〉—— ⚠️ 中译稿
    'hof_ic_pyotr_smirnov_the_naval_aviation' = @('海军航空兵', '1938 年 1 月 1 日，海军航空兵脱离空军建制，并入海军。—— 中文维基〈苏联海军〉')

    # ---- A4 · 建军宣示（1938-02-03）----
    # 出处：`[W]`zh〈苏联海军〉—— ⚠️ 中译稿
    # ⚠️ 节点名「建军宣示」由用户 2026-09-20 认可；「远洋海军」这个词留在文案里
    # ⛔ 节点名不用「第三个五年计划」（原版 `SOV_third_five_year_plan` 同名）
    'hof_ic_pyotr_smirnov_the_declaration' = @('建军宣示', '1938 年 2 月 3 日，海军人民委员斯米尔诺夫在《真理报》上公开了建设远洋海军的思想：在第三个五年计划期间造出苏联第一批战列舰，还要建造重型巡洋舰、巡洋舰、驱逐舰、潜艇等。—— 中文维基〈苏联海军〉')

    # ---- A5 · 海军军事委员会（1938-04-23）----
    # 出处：`[W]`ru〈Наркомат ВМФ СССР〉—— ⚠️ 中译稿
    # ⚠️ 一处两说：`[W]`zh 作 1938-03-13，`[W]`ru 作 **1938-04-23**（附成员名单）→ ⭐ 取 ru
    'hof_ic_pyotr_smirnov_the_military_council' = @('海军军事委员会', '1938 年 4 月 23 日，海军人民委员部下设海军总军事委员会，主席是 П. А. 斯米尔诺夫，成员包括加列尔、日丹诺夫、伊萨科夫、库兹涅佐夫、列夫琴科。—— 俄文维基〈苏联海军人民委员部〉（本项目转译）')

    # ---- E1 · 海军人民委员部（结局）----
    # ⭐⭐⭐ 节点名 = 【那个机构本身】—— 用户 2026-09-20 裁决取【甲】
    #   🔴 原版 `SOV_pc_of_the_ussr_navy` 的中文名【完全相同】，
    #      但用户口径：「名字不是完全相同就可以」→ ✅ 取甲
    #   ⭐⭐ 首尾同轴：根 = 海军只是一个「局」（1926）；E1 = 海军是一个「部」
    # 🟢⭐ 文案 = **1937-12-30 决议原文节选**（一手件，本项目据俄文原文转译）
    # ⛔ 全文案不出现：大清洗 / 被捕 / 审判 / 处决 / 1939-02 / 平反 / 喀琅施塔得 / 远东
    'hof_ic_pyotr_smirnov_the_commissariat' = @('海军人民委员部', '中央执行委员会与人民委员会决议：一、成立全联盟的海军人民委员部。二、把工农红军的海军力量移交海军人民委员部，把它们从苏联国防人民委员部里分出来。三、海军人民委员须在五日内向人民委员会提交该部的条例草案与编制。—— 主席 М. 加里宁，人民委员会主席 В. 莫洛托夫，秘书 А. 戈尔金。// 1937 年 12 月 30 日苏联中央执行委员会与人民委员会决议（载《苏维埃西伯利亚报》1938 年 1 月 1 日第 1(5469) 号第 1 版；本项目据俄文原文转译）')
}

$malenkowLoc = [ordered]@{

    # ---- A1 · 党员登记卡（1935–1936）----
    # 出处：`[W]`ru〈Маленков〉—— ⚠️ 中译稿（本项目转译）
    # ⭐ 这就是【根】的落实：1925 年他被派去看管的那个柜子，被他撑成了二百五十万张
    'hof_ic_malenkow_the_party_card_index' = @('党员登记卡', '1935 至 1936 年，党在全国范围内检查并交换党证。这场运动为全体党员与预备党员建立了登记卡与档案，总数约二百五十万份；连同对非党领导人与专家的资料，它后来成了一整套干部名册的底座。—— 俄文维基〈Маленков〉（本项目据俄文转译）')

    # ---- A2 · 中央干部管理局（1939-03-22）----
    # 出处：`[W]`ru〈Маленков〉—— ⚠️ 中译稿（本项目转译）
    'hof_ic_malenkow_the_cadres_directorate' = @('中央干部管理局', '一个庞大的、中央集权的干部名册体系就这样建成了 —— 它成了马林科夫的主要党内专业。—— 俄文维基〈Маленков〉（本项目据俄文转译）')

    # ---- A3 · 国防委员会（1941-06-30）----
    # ⭐ 出处：**他本人 1947 年 9 月的报告**（MIA 英文本；本项目转译）+ `[W]`ru 的职务年表
    # ⚠️ 强调是党政协调机关，不是军事指挥
    'hof_ic_malenkow_the_state_defence_committee' = @('国防委员会', '1941 年 6 月 30 日成立的国防委员会只有五个人，其中一个是他。他在这个小组里管的是人：督导近卫迫击炮部队的组建，随后主持雷达与火箭两个特别委员会。他后来说：「党在极短的时间内，把整个国家的经济生活置于战时轨道，把一切经济活动服从于『一切为了前线』这个口号。」—— 马林科夫 1947 年 9 月在共产党情报局会议上的报告（据 MIA 英文本转译）')

    # ---- A4 · 航空案（1946-05-04）----
    # ⭐⭐ 出处：**1946-05-04 联共（布）中央政治局决议原文节选**（`[W]`ru 引；本项目转译）
    # ⭐⭐ 本线的【立身之本】—— 「配对」是他的活，所以飞机出问题才由他负道德责任
    'hof_ic_malenkow_the_aviation_affair' = @('航空案', '「马林科夫同志，作为航空工业与空军验收的负责人，对在这些部门工作中暴露出来的丑恶现象（出产劣质飞机）负有道德责任 —— 他明知这些丑恶现象，却未向中央报告。」1946 年 5 月 4 日，联共（布）中央政治局据此把他撤出中央书记处。九天后，他被任命为第二号特别委员会主席，去管火箭。—— 1946-05-04 联共（布）中央政治局决议（俄文维基〈Маленков〉引；本项目据俄文转译）')

    # ---- A5 · 党校（1946–1947）----
    # ⭐ 出处：**他本人 1947 年 9 月的报告**（MIA 英文本；本项目转译）
    'hof_ic_malenkow_the_party_schools' = @('党校', '「在各省与各边疆区，组织了 177 所两年制党校与九个月的学习班，学员总数约三万人；中央委员会设立了社会科学院。」—— 马林科夫 1947 年 9 月在共产党情报局会议上的报告（据 MIA 英文本转译）')

    # ---- E1 · 部长会议主席（1953-03-05）----
    # 📌 2026-09-20 用户裁决取【乙】（甲 = 干部名册）
    # 出处：`[W]`zh〈马林科夫〉 + `[W]`ru〈Маленков〉—— ⚠️ 中译稿（本项目转译）
    # ⭐ 官册（номенклатура）在 desc 里作为产物点名 —— 满足判据 C
    'hof_ic_malenkow_the_premiership' = @('部长会议主席', '1953 年 3 月 5 日，他接任苏联部长会议主席 —— 坐进了那个位子。而他带进去的东西是同一件：一套从 1935 年起就写着「谁可以用」的干部名册（官册，номенклатура）。这套名册比它的任何一位主人活得都久。—— 中文维基〈马林科夫〉 · 俄文维基〈Маленков〉（本项目转译）')
}

$khrushchevLoc = [ordered]@{

    # ---- A1 · 工人速成中学（1921 年末）----
    # 出处：`[W]`ru〈Хрущёв〉—— ⚠️ 中译稿（本项目转译）
    # ⭐ 与加里宁（Idx 14）「扫除文盲」的界线：扫盲是【认字】，速成中学是让已经在管事的人补上学历
    'hof_ic_khrushchev_the_workers_faculty' = @('工人速成中学', '1921 年底，他进了顿河工业学校附属的工人速成中学，并被选为那里的党组织书记 —— 而此前他已经是鲁奇琴科沃矿的副矿长。一个已经管着一个矿的人回到课桌前：他知道位子不等于会算。—— 俄文维基〈Хрущёв〉（本项目据俄文转译）')

    # ---- A2 · 义务交售制（1946-10-15）----
    # 📌 节点名 2026-09-20 按用户口径改（原「给斯大林的那封信」）—— 判据 F：名词短语
    # 出处：`[W]`zh〈赫鲁晓夫〉
    'hof_ic_khrushchev_the_obligatory_deliveries' = @('义务交售制', '1946 年 10 月 15 日，他写信要求减少谷物上缴的配额；12 月又建议发放供应卡，以保障农村人口有最低的食物保障 —— 遭到怒骂。他撞的不是某一个人，而是那个把粮食从共和国手里拿走的制度本身。—— 中文维基〈赫鲁晓夫〉')

    # ---- A3 · 农业城市（1949–1951）----
    # 出处：`[W]`zh〈赫鲁晓夫〉
    # ⚠️ 代价写在 desc 里（1951-03-04 真理报两版 → 4 月莫斯科党全会鞭挞他）
    'hof_ic_khrushchev_the_agro_towns' = @('农业城市', '为了实现他「消灭城乡差别」的理想，他还试图将集体农场合并为农业城市；他建立一个样板点，并于 1949 年 10 月把它作为七十岁寿辰的礼物献上。1951 年 3 月 4 日，《真理报》上他关于农业城市化的讲话稿整整占据两个版面 —— 但报纸随即修正了观点；4 月的莫斯科党的全体会议上，众人纷纷对他大加鞭挞。—— 中文维基〈赫鲁晓夫〉')

    # ---- A4 · 收购价（1953-09）----
    # 出处：`[W]`ru〈Хрущёв〉—— ⚠️ 中译稿（本项目转译）
    # ⛔ 节点名不叫「新方针」（托洛茨基 Idx 1 已有 hof_ic_trotsky_the_new_course「新方针」）
    'hof_ic_khrushchev_the_purchase_prices' = @('收购价', '1953 至 1956 年间，国家对集体农庄产品的收购价提高了三倍 —— 让种地的人先拿到钱，是「往下交」的第一步。这一版方案由马林科夫在 1953 年 8 月先行提出，他在 9 月提出了更高的数字。—— 俄文维基〈Хрущёв〉 · 中文维基〈赫鲁晓夫〉（本项目据俄文转译）')

    # ---- A5 · 荒地（1954-02）----
    # 出处：`[W]`zh〈赫鲁晓夫〉
    'hof_ic_khrushchev_the_virgin_lands' = @('荒地', '1954 年 2 月，党中央全会通过决议，决定在哈萨克和西伯利亚大规模开垦荒地。从 1954 年到 1958 年，政府为开荒投资 67 亿卢布，动员数十万志愿者到东部地区落户，共开垦出 4000 万公顷的土地。1958 年苏联农业丰收，垦荒区共收获谷物 5850 万吨，占当年全苏粮食总产量的 40％ 以上。—— 中文维基〈赫鲁晓夫〉')

    # ---- E1 · 国民经济委员会（1957-05）----
    # 📌 2026-09-20 用户裁决取【丙】（甲 = 机器拖拉机站 · 乙 = 部长会议主席，⚠️ 乙与马林科夫线 E1 完全相同）
    # 出处：`[W]`ru〈Хрущёв〉「Основные политические акции」节（史实专名的原文）+ `[W]`zh〈赫鲁晓夫〉
    # ⭐⭐ 首尾同轴：根 = 归属换到自己人手上（1917）；E1 = 他把归属换给它所在的那一级
    'hof_ic_khrushchev_the_economic_councils' = @('国民经济委员会', '撤销部门性部委，成立国民经济委员会（1957）。他陆续把 1.5 万个中央直属企业下放到加盟共和国管理，同时扩大加盟共和国的管理权限 —— 他把这些工厂交给了它们所在的那一级。这项改革没有从根本上改变国家管理企业的行政办法，也滋生地方本位主义等问题。—— 俄文维基〈Хрущёв〉「主要政治举措」节（本项目据俄文转译） · 中文维基〈赫鲁晓夫〉')
}

# -----------------------------------------------------------------------------
# 伏罗希洛夫（Idx 22）—— 单线 5 节点 + 1 单结局（docs/87 §2）
# 出处：A1 = 他本人 1926-09-10 红指挥员毕业典礼讲话【一手件】（`[W]`ru 引原文）
#       A3 = 1935-09-22 苏联中央执行委员会与人民委员会第 19/2135 号决议原文【一手件】
#       A4 = 潘捷列伊蒙·波诺马连科（同代人的记述原文）
#       A5 = 1944-04-03《红军战利品机关、部队与机构条例》原文【一手件】
#       A2 / E1 = `[W]`ru〈Ворошилов〉（中译稿）
# ⚠️ 六条【全部是节选】，一句都不是我写的评价（AGENTS.md 规则 9）。
# -----------------------------------------------------------------------------
$voroshilovLoc = [ordered]@{

    # ---- A1 · 工农红军指挥员（1926-09-10）----
    # 出处：他本人 1926-09-10 红指挥员毕业典礼讲话【一手件】（`[W]`ru 引原文）
    'hof_ic_voroshilov_the_red_army_commanders' = @('工农红军指挥员', '「我们应当已经可以自豪地说，这项建立一支能够管理我们红军的指挥干部队伍的、极其巨大而艰巨的任务，我们已经完成了 75%。在 48 000 名红指挥员中，我们有 34 000 多名毕业于我们的正规学校或短期训练班。」—— 1926 年 9 月 10 日红指挥员毕业典礼上的讲话。到 1928 年初，红军手里有 49 所军事学校和 6 所军事学院、5 个军事系。')

    # ---- A2 · 伏罗希洛夫射手（1932-12-29）----
    # 出处：`[W]`ru〈Ворошилов〉—— ⚠️ 中译稿（本项目据俄文转译）
    'hof_ic_voroshilov_the_marksmanship_badge' = @('伏罗希洛夫射手', '1932 年 12 月 29 日，批准 Осоавиахим 的「伏罗希洛夫射手」胸章，用于奖赏射击准确的人。一枚胸章就是一套考核：它把枪法变成了每一个青年都能去考的东西。—— 俄文维基〈Ворошилов〉（本项目据俄文转译）')

    # ---- A3 · 个人军衔制（1935-09-22）----
    # 出处：1935-09-22 苏联中央执行委员会与人民委员会第 19/2135 号决议
    #       《关于在工农红军指挥人员中实行个人军衔》原文【一手件】
    'hof_ic_voroshilov_the_ranks' = @('个人军衔制', '「设立『苏联元帅』这一军衔，由苏联政府个人授予最高指挥人员中杰出的、特别功勋卓著的人员。」—— 苏联中央执行委员会与人民委员会 1935 年 9 月 22 日第 19/2135 号决议。1935 年 11 月 20 日首次授予，五人获得：国防人民委员伏罗希洛夫、总参谋长叶戈罗夫、国防副人民委员图哈切夫斯基、骑兵监察员布琼尼、远东特别红旗集团军司令布柳赫尔。')

    # ---- A4 · 中央游击运动总参谋部（1942-09-06）----
    # 出处：潘捷列伊蒙·波诺马连科（同代人的记述原文）
    'hof_ic_voroshilov_the_partisan_staff' = @('中央游击运动总参谋部', '「由于他的威望、精力和坚持，游击运动的许多重要问题得到了解决，特别是在战斗与物资技术供应以及为游击队进行空运方面。」—— 潘捷列伊蒙·波诺马连科。1942 年 9 月 6 日他出任游击运动总司令，把指挥体系改成一套沿用至战争结束的做法：中央游击运动总参谋部变成一个强大的机关。')

    # ---- A5 · 战利品机关条例（1943-04-05）----
    # 出处：1944-04-03《红军战利品机关、部队与机构条例》原文【一手件】
    'hof_ic_voroshilov_war_trophies_regulation' = @('战利品机关条例', '「红军的战利品机关、部队与机构保证收集、保管、清点、运出与交出从敌人手中缴获的战利品武器装备、弹药、战斗技术装备、粮秣、油料以及其他军事与国民经济物资。」—— 1944 年 4 月 3 日《红军战利品机关、部队与机构条例》。他自 1943 年 4 月起任战利品委员会主席。')

    # ---- E1 · 盟国管制委员会（1945-02-05）----
    # 出处：`[W]`ru〈Ворошилов〉—— ⚠️ 中译稿（本项目据俄文转译）
    # 📌 2026-09-20 用户裁决取【丙】：原方案「无条件投降文件」作废
    # ⭐ 界线：李维诺夫（Idx 15）让外国的【政府】肯签字；本线给一个被占领国【装】上一套管制机关
    'hof_ic_voroshilov_the_allied_control_commission' = @('盟国管制委员会', '1945 年 2 月 5 日，盟国管制委员会在德布勒森开始工作。它的职责是管制并监督停战条件的执行。1945 至 1947 年间，他任驻匈牙利的盟国管制委员会主席，直到和约生效后委员会才停止活动。—— 俄文维基〈Ворошилов〉（本项目据俄文转译）')
}

# 本地化键与国策 id 必须一一对应（多条线都查）
$locOf = @{ lev_trotsky = $trotLoc; nikolay_bukharin = $bukhLoc; aleksey_rykov = $rykovLoc;
            grigory_zinovyev = $zinLoc; lev_kamenev = $kamLoc; ivan_smirnov = $smirLoc;
            leonid_serebryakov = $serebLoc; yevgeny_preobrazhensky = $preobLoc;
            karl_radek = $radekLoc; ivar_smilga = $smilgaLoc; mikhail_tomsky = $tomskyLoc;
            martemyan_ryutin = $ryutinLoc; aleksandr_shlyapnikov = $shlyapnikovLoc;
            mikhail_kalinin = $kalininLoc; maksim_litvinov = $litvinovLoc;
            grigory_sokolnikov = $sokolnikovLoc;
            mikhail_tukhachevsky = $tukhachevskyLoc;
            nikolay_voznesensky = $voznesenskyLoc;
            pyotr_smirnov = $pyotrSmirnovLoc;
            georgy_malenkow = $malenkowLoc;
            nikita_khrushchyov = $khrushchevLoc;
            kliment_voroshilov = $voroshilovLoc }
$missLoc = @()
foreach ($ls0 in $lineSpecs) {
    $d = $locOf[$ls0.Key]
    foreach ($f in $ls0.Line) { if (-not $d.Contains($f.Id)) { $missLoc += $f.Id } }
    foreach ($k in $d.Keys) { if (-not ($ls0.Line | Where-Object { $_.Id -eq $k })) { $missLoc += "(多余) $k" } }
}
if ($missLoc.Count -gt 0) { throw ("本地化键与国策 id 不匹配：" + ($missLoc -join ', ')) }

$sb2 = New-Object System.Text.StringBuilder
function Format-HofFocusDescription([string]$description) {
    # 史料摘句本身不改字；把末尾出处另起一段，避免长句与书名挤在一起。
    # HOI4 本地化使用字面量 \n 换行，不能把实际换行写进 yml 的引号里。
    $value = $description.Trim()
    $split = $value.LastIndexOf('——')
    if ($split -gt 0) {
        $body = $value.Substring(0, $split).TrimEnd()
        $source = $value.Substring($split).Trim()
        if ($body -match '[。！？」》]$' -and $source -notmatch '[「」]' -and $source.Length -le 200) {
            return $body + '\n\n' + $source
        }
    }
    return $value
}
foreach ($ls0 in $lineSpecs) {
    $d = $locOf[$ls0.Key]
    $null = $sb2.AppendLine('')
    $null = $sb2.AppendLine(' # ---------------------------------------------------------------------------')
    $null = $sb2.AppendLine(" # $($ls0.Name)个人线 $($ls0.Line.Count) 条国策（文案为史实/理论节选，来源见 $($ls0.Doc)）")
    $null = $sb2.AppendLine(' # ---------------------------------------------------------------------------')
    foreach ($f in $ls0.Line) {
        $nm = $d[$f.Id][0]
        $ds = Format-HofFocusDescription $d[$f.Id][1]
        $null = $sb2.AppendLine(" $($f.Id):0 `"$nm`"")
        $null = $sb2.AppendLine(" $($f.Id)_desc:0 `"$ds`"")
    }
}
# 职务分级名（idea 的本地化键 = idea id）
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 职务分级名（照德国：官衔随等级变）')
# 🚩 原来写死 $roster[0] —— 布哈林的官衔名根本没生成（游戏里显示原始键）。
#    凡「按人一份」的键都要循环。
foreach ($c in $roster) {
    if (-not ($c.ContainsKey('Tiers') -and $c.Tiers)) { continue }
    foreach ($t in $c.Tiers) {
        $null = $sb2.AppendLine(" $($t.Id):0 `"$($t.Zh)`"")
    }
}
# 🚩🚩 踩过：PowerShell 把 "$trotDmId:0" 里的 `名:字` 当成【作用域/驱动器限定的变量名】
#    来解析 → 整个表达式求值为 $null → 输出行变成【没有 key 的裸字符串】：
#         "托洛茨基的个人威望"
#    后果：动态民族精神只有 id、没有名字（游戏里直接显示 hof_ic_lev_trotsky_dm），
#    而且这一行会让 HOI4 的本地化解析器报错。
#    → 规律：【变量后面接冒号】一律写成子表达式 $($var)。
# 🚩🚩 踩过：这一段原来【写死了托洛茨基】—— 布哈林实装后，
#    他的容器 hof_ic_nikolay_bukharin_dm 【没有名字、没有说明】（游戏里显示原始 id），
#    累积抬头键 hof_ic_bukharin_extra_effects_tt 【根本没生成】（国策里直接显示原始键）。
#    → 铁律：凡「按人一份」的键，一律按 $lineSpecs 循环，不许写死。
foreach ($ls0 in $lineSpecs) {
    # 累积数值的归属抬头（照德国「XXX 追加效果：」）
    $null = $sb2.AppendLine(" $($ls0.Header):0 `"§Y$($ls0.Name)的职务§!追加效果：`"")
}

# ---- 终局二选一事件（照德国 GER_inner_circle_himmler.00）----
# 共享键：用 $CHARACTER$ 填人名、$FOCUS$ 填目标国策名（逐字照拄德国
# GER_inner_circle_himmler_ss_tt: "§Y$GER_heinrich_himmler$§!很快会开始致力于研究国策§Y$...$§!。"）
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 终局二选一（选项 tooltip 照德国 GER_inner_circle_himmler_ss_tt 的句式）')
$null = $sb2.AppendLine(' hof_ic_ending_choice_tt:0 "§Y$CHARACTER$§!很快会开始致力于研究国策§Y$FOCUS$§!。"')
foreach ($c0 in $roster) {
    if (-not $endingChoiceOf.ContainsKey($c0.Key)) { continue }
    $ch0  = $endingChoiceOf[$c0.Key]
    $lt   = @('a', 'b', 'c', 'd')
    $null = $sb2.AppendLine('')
    $null = $sb2.AppendLine(" # $($c0.Zh) 的终局二选一事件（$evNamespace.$($ch0.EvId)）")
    $null = $sb2.AppendLine(" $evNamespace.$($ch0.EvId).t:0 `"$($ch0.Title)`"")
    $null = $sb2.AppendLine(" $evNamespace.$($ch0.EvId).desc:0 `"$($ch0.Desc)`"")
    for ($i0 = 0; $i0 -lt $ch0.Ends.Count; $i0++) {
        $null = $sb2.AppendLine(" $evNamespace.$($ch0.EvId).$($lt[$i0]):0 `"$($ch0.Ends[$i0].Opt)`"")
    }
}

# ---- 岔路二选一事件（2026-09-16 加，结构同终局）----
foreach ($c0 in $roster) {
    if (-not $pathChoiceOf.ContainsKey($c0.Key)) { continue }
    $pc0 = $pathChoiceOf[$c0.Key]
    $lt  = @('a', 'b', 'c', 'd')
    $null = $sb2.AppendLine('')
    $null = $sb2.AppendLine(" # $($c0.Zh) 的岔路二选一事件（$evNamespace.$($pc0.EvId)）")
    $null = $sb2.AppendLine(" $evNamespace.$($pc0.EvId).t:0 `"$($pc0.Title)`"")
    $null = $sb2.AppendLine(" $evNamespace.$($pc0.EvId).desc:0 `"$($pc0.Desc)`"")
    for ($i0 = 0; $i0 -lt $pc0.Opts.Count; $i0++) {
        $null = $sb2.AppendLine(" $evNamespace.$($pc0.EvId).$($lt[$i0]):0 `"$($pc0.Opts[$i0].Opt)`"")
    }
}

# ---- 入口国策 / 升官衔 tooltip（照德国核心圈那套）----
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 入口国策 / 升官衔 tooltip（照德国核心圈）')
$null = $sb2.AppendLine(' # ⚠️ 这两条是【具名参数】写法：')
$null = $sb2.AppendLine(' #    custom_effect_tooltip = { localization_key = K  CHARACTER = SOV_<key> }')
$null = $sb2.AppendLine(' #    官方文档 documentation/loc_objects_documentation.md 把 Character 列为一种 loc scope')
$null = $sb2.AppendLine(' #    → CHARACTER 必须是【真实角色 id】，名字由角色自己的 name 键提供')
$null = $sb2.AppendLine(' hof_ic_skip_line_tt:0 " \n"')
$null = $sb2.AppendLine(' hof_ic_seat_note_tt:0 "获得事件§Y最高苏维埃改选§!：\n§Y$CHARACTER$§!可以在§Y核心圈§!中取代一位现任委员。"')
$null = $sb2.AppendLine(' hof_ic_appointment_cd_tt:0 "任命冷却已结束（距下次任命还有 [?hof_ic_appointment_cd:days_left|Y0] 天）"')
$null = $sb2.AppendLine(' hof_ic_seat_ascension_tt:0 "§Y$CHARACTER$§!被任命为§Y最高苏维埃委员§!，并在§Y核心圈§!中晋升为："')
$null = $sb2.AppendLine(' hof_ic_path_event_tt:0 "入席后获得事件§Y$EVENT$§!，由此决定先走哪条分叉国策。"')
$null = $sb2.AppendLine(' hof_ic_focus_event_choice_only_tt:0 "该国策只有在事件中选择此路线后，才会由§Y$CHARACTER$§!自动推进。"')
foreach ($choiceKey in $endingChoiceOf.Keys) {
    $null = $sb2.AppendLine(" hof_ic_ending_event_${choiceKey}_tt:0 `"完成§Y$($endingChoiceOf[$choiceKey].Amount)§!条支线后获得事件§Y`$EVENT`$§!，由此决定终局国策。`"")
}
# ---- 中间国策「人民委员」----
# ① 激活提示：逐字照德国 GER_fuhrerprinzip_inner_circle_tt（「激活核心集团机制。」）
# ② 描述：仿苏联国策介绍的文风（公文体、不带人称）
# ③ 领袖特质升级版的名字（原版 strong_party_discipline = 「党纪严明」）
$null = $sb2.AppendLine(' hof_ic_commissar:0 "人民委员"')
$null = $sb2.AppendLine(' hof_ic_commissar_desc:0 "一个人代表整个国家，本身就是不民主的做法，也是一种反革命的行为——这个作风已经被我们抛弃了。可是集体的意志仍需要一个执行者：我们在最高苏维埃的代表中选出一个常设机构，由它主持各人民委员部的日常工作。它的成员是人民委员；它只对最高苏维埃负责，也随时可以被撤换。"')
$null = $sb2.AppendLine(' hof_ic_commissar_inner_circle_tt:0 "激活最高苏维埃机制。"')
$null = $sb2.AppendLine(' hof_ic_commissar_party_discipline:0 "党纪严明"')
# 🚩 以上两条 + 下面那条 rank_up 【逐字照抄德国原文】（原版 localisation/simp_chinese/WUW_focus_l_simp_chinese.yml）：
#      GER_ascension_of_character_tt          = "§Y$CHARACTER$§!被任命为§Y全国领导§!，并在§Y核心集团§!中晋升为："
#      GER_ascended_character_trait_swap_tt   = "§Y$CHARACTER$§!在§Y核心集团§!中崛起："
#      GER_event_to_replace_ascended_advisor_tt = "获得事件§Y$CHARACTER$的崛起§!'：\\n§Y$CHARACTER$§!可以在§Y核心集团§!中取代§Y[A]§!、§Y[B]§!或§Y[C]§!。"
#   自己旧文案的问题（用户实拍后指出「写的怪怪的」）：
#     · 只高亮了人名；德国把【职务 / 机构名】也用 §Y 高亮 → 玩家看不出重点
#     · 用「任职为」，德国是「晋升为」（这是个升迁动作，不是单纯挂名）
#     · 旧句子里有个多余空格
$null = $sb2.AppendLine(' hof_ic_rank_up_tt:0 "§Y$CHARACTER$§!在§Y核心圈§!中崛起："')
# 个人线驱动器配套的两条（照德国 GER_inner_circle_focus_in_progress_tt /
# GER_focus_can_only_be_completed_by_advisor_tt）
# ⚠️ 进度分母用 $branchTierDays 插值 —— 不写死数字，改常量时这里自动跟着变
# 🚩 以下三条【逐字照抄德国原文】（原版 localisation/simp_chinese/WUW_focus_l_simp_chinese.yml）：
#      GER_inner_circle_focus_in_progress_tt         = "§Y$CHARACTER$§!正致力于该国策。\n进度：§Y$FLAG_DAYS$§!/[?temp_focus_days]天"
#      GER_focus_can_only_be_completed_by_advisor_tt = "该国策只能由§Y$CHARACTER$§!在完成§Y$FOCUS$§!之后开始。"
#      GER_ascension_of_character_focus_tt           = "§Y$CHARACTER$§!将开始随着时间的推移处理他分支中的国策。"
#   自己旧文案的问题（用户实拍对照后指出）：advisor_only 写成
#   「他不在最高苏维埃中时，这个国策不会被推进」—— 一句解释性大白话，
#   既没告诉玩家【现在缺什么】，也没有德国那种 ❌ 前缀。德国是把
#   【只能由谁推】+【要先完成哪个国策】合成一句，玩家一眼就知道要做什么。
#   → $FOCUS$ 由生成器传成入口国策键（见 §10 的 FOCUS = $($ls.Entry)）。
$null = $sb2.AppendLine(" hof_ic_focus_in_progress_tt:0 `"§Y`$CHARACTER`$§!正致力于该国策。\n进度：§Y`$FLAG_DAYS`$§!/$branchTierDays 天`"")
$null = $sb2.AppendLine(' hof_ic_focus_advisor_only_tt:0 "该国策只能由§Y$CHARACTER$§!在完成§Y$FOCUS$§!之后开始。"')
$null = $sb2.AppendLine(' hof_ic_ascension_focus_tt:0 "§Y$CHARACTER$§!将开始随着时间的推移处理他分支中的国策。"')
foreach ($c in $roster) {
    $null = $sb2.AppendLine(" hof_ic_not_seated_$($c.Key)_tt:0 `"§Y$($c.Zh)§! 不在最高苏维埃中任职`"")
    # 自建角色的人：补一条【角色名】loc（其余人用官方/R56 现成的）
    if ($c.ContainsKey('OwnChar') -and $c.OwnChar) {
        $null = $sb2.AppendLine(" SOV_$($c.Key):0 `"$($c.Zh)`"")
    }
}

# 词条 tooltip：这 5 个没有官方 <词条>_tt 键，自己写（实测见 reference/reports/modifier-tt.txt）
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 词条 tooltip（这 5 个没有官方 <词条>_tt 键，自写）')
# 🚩🚩 踩过：必须照原版格式写 `标签: $RIGHT|+=%1$` ——
#    原版形如 army_org_factor_tt: " $MODIFIER_ARMY_ORG_FACTOR$: $RIGHT|+=%1$"
#    那个 %1 是【引擎会填的数值】。漏了它，这一行就只有标签没有数字，
#    混在旁边一堆「+5.0%」里显得莫名其妙（实拍确认）。
#    也不要写整句解释，那不是 tooltip 该干的事。
$null = $sb2.AppendLine(' hof_ic_tt_combat_width_factor:0 " 战场宽度: $RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_opinion_gain_monthly_factor:0 " 各国好感月增长: $RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_improve_relations_maintain_cost_factor:0 " 改善关系持续花费: $RIGHT|-=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_resistance_decay:0 " $MODIFIER_RESISTANCE_DECAY$：$RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_send_volunteer_factor:0 " 派遣志愿军规模: $RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_paradrop_organization_factor:0 " 空降后的组织度: $RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_no_supply_grace:0 "$MODIFIER_NO_SUPPLY_GRACE$$RIGHT|+=1$小时"')
$null = $sb2.AppendLine(' hof_ic_tukhachevsky_tank_org_tt:0 " 轻型、中型、重型坦克营组织度：§G+5§!"')
$null = $sb2.AppendLine(' hof_ic_tukhachevsky_tank_org_tech:0 "战车营组织训练"')
$null = $sb2.AppendLine(' hof_ic_tt_modifier_army_sub_unit_infantry_attack_factor:0 " 步兵进攻: $RIGHT|+=%1$"')
$null = $sb2.AppendLine(' hof_ic_tt_modifier_army_sub_unit_cavalry_attack_factor:0 " 骑兵进攻: $RIGHT|+=%1$"')
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 升官衔提示（照德国 GER_ascended_character_trait_swap_tt）')
$null = $sb2.AppendLine(' # 📌 hof_ic_rank_up_tt 是【共享】键，用 $CHARACTER$ 填人名（定义见上面「入口国策 / 升官衔 tooltip」段）')

# 两条全联盟终局的描述只取史料节选：
# 主席：列宁《我们运动的迫切任务》（1900 年 11 月），《列宁全集》第 2 版第 4 卷第 333—338 页。
# https://www.marxists.org/chinese/lenin/marxist.org-chinese-lenin-190011.htm
# 团结：1924 年苏联宪法《苏维埃社会主义共和国联盟成立的宣言》。
# https://marxists.architexturez.net/chinese/reference-books/mia-chinese-russia-19240131.htm
# 主席选举事件仍取 1936 年苏联宪法第 48 条。
# https://www.marxists.org/chinese/reference-books/mia-chinese-ussr-constitution-1936.htm
$null = $sb2.AppendLine('')
$null = $sb2.AppendLine(' # 主席：列宁《我们运动的迫切任务》；团结：1924 年苏联宪法成立宣言；选举事件：1936 年苏联宪法第 48 条')
$null = $sb2.AppendLine(' hof_ic_new_soviet_chairman:0 "新生的苏维埃主席"')
$null = $sb2.AppendLine(' hof_ic_new_soviet_chairman_desc:0 "「在历史上，任何一个阶级，如果不推举出自己的善于组织运动和领导运动的政治领袖和先进代表，就不可能取得统治地位。」——列宁，《我们运动的迫切任务》"')
$null = $sb2.AppendLine(' hof_ic_united_supreme_soviet:0 "团结的最高苏维埃"')
$null = $sb2.AppendLine(' hof_ic_united_supreme_soviet_desc:0 "「这个联盟是各平权民族的自愿联合……它将是反对世界资本主义的可靠堡垒。」——《苏维埃社会主义共和国联盟成立的宣言》"')
$null = $sb2.AppendLine(' hof_ic_finale_gate_tt:0 "现任七位最高苏维埃委员均已完成各自的终局国策"')
$null = $sb2.AppendLine(' hof_ic_new_soviet_chairman_event_tt:0 "获得事件§Y最高苏维埃主席选举§!：从现任七位委员中推举新主席。"')
$null = $sb2.AppendLine(' hof_ic_new_soviet_chairman_trait:0 "新生的苏维埃主席"')
$null = $sb2.AppendLine(' hof_ic_united_supreme_soviet_trait:0 "团结的最高苏维埃"')
$null = $sb2.AppendLine(' heartofiron.1400.t:0 "最高苏维埃主席选举"')
$null = $sb2.AppendLine(' heartofiron.1400.desc:0 "「苏联最高苏维埃在两院联席会议上选出苏联最高苏维埃主席团。」"')
for ($slot = 1; $slot -le $seatCount; $slot++) {
    $null = $sb2.AppendLine(" heartofiron.1400.slot_${slot}:0 `"推举第 $slot 席：[hof_ic_slot_${slot}_name]`"")
}

# 可见容器需要自己列出个人线的变量：idea_desc|<职务> 只读取 hidden idea，
# 不会读取无图标的个人动态修正。变量和修正的唯一数据源仍是上面的 $lineSpecs。
$locPath = Join-Path $modRoot 'localisation/simp_chinese/hof_ic_roster_l_simp_chinese.yml'
$locOld = [System.IO.File]::ReadAllText($locPath)
# 去掉尾部多余空行后追加（避免重跑时越堆越多）
$locNew = $locOld.TrimEnd() + [Environment]::NewLine + $sb2.ToString()
[System.IO.File]::WriteAllText($locPath, $locNew, (New-Object System.Text.UTF8Encoding($true)))
# 两个计数【含义不同】，别混用：
#   $tierKeyCount   = 职务分级键数（有 Tiers 的人按级数算）—— 只用于进度提示
#   $ideaBlockCount = idea 块总数（没 Tiers 的人也算 1 个）—— 用于 §11 自检
$tierKeyCount   = (@($roster | ForEach-Object { if ($_.ContainsKey('Tiers') -and $_.Tiers) { $_.Tiers.Count } else { 0 } }) | Measure-Object -Sum).Sum
$ideaBlockCount = (@($roster | ForEach-Object { if ($_.ContainsKey('Tiers') -and $_.Tiers) { $_.Tiers.Count } else { 1 } }) | Measure-Object -Sum).Sum
Write-Output ("  追加 {0} 个国策键 + {1} 个职务分级键（共 {2} 个 idea 块）" -f ((@($lineSpecs | ForEach-Object { $_.Line.Count }) | Measure-Object -Sum).Sum * 2), $tierKeyCount, $ideaBlockCount)

# --- hub 挂载行（已废弃，保留空文件占位）---------------------------------------
# 🚩 2026-09-16：容器 DM 的挂载已【移到我们自己的中间国策「人民委员」】里
#    （见 §10y）。原做法是补丁原版 SOV_the_supreme_soviet 的 completion_reward，
#    但插了中间节点之后不再需要改原版文件。
# ⚠️ sync-from-r56.ps1 会检查本文件是否存在（不存在就 throw），
#    所以这里仍然写一个【只有注释】的文件，而不是干脆不生成。
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# ---- 核心圈容器挂载（已空）----')
$null = $sb.AppendLine('# 2026-09-16 起，容器 DM 改由国策 hof_ic_commissar 的 hidden_effect 挂载。')
$null = $sb.AppendLine('# 本文件刻意保持为空（只有注释）：sync 脚本仍会读它，但不再往原版国策里插任何行。')

$hubPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\inject-sov-hub.txt'
[System.IO.File]::WriteAllText($hubPath, $sb.ToString().Replace('`t', "`t"), $utf8NoBom)
Write-Output ("  写出 {0,-58} {1,8:N0} 字节（已空的占位文件）" -f 'build/inject-sov-hub.txt', (Get-Item -LiteralPath $hubPath).Length)

# =============================================================================
Write-Output ''
Write-Output '======== 11. 生成结果自检 ========'

$checks = @(
    @{ F = 'common/dynamic_modifiers/hof_ic_dynamic_modifiers.txt'; Pat = "^$dmId = \{";        Exp = 1 },
    @{ F = 'common/ideas/hof_ic_ideas.txt';                         Pat = '^ideas = \{';                Exp = 1 },
    @{ F = 'common/ideas/hof_ic_ideas.txt';                         Pat = '^\thidden_ideas = \{';        Exp = 1 },
    # 🚩 期望值随数据变化：每人一个 idea，有职务分级的人按级数算
    #    （踩过两次：写死的 10 —— 加布哈林分级后成 12、又算成 7）
    @{ F = 'common/ideas/hof_ic_ideas.txt';                         Pat = '^\t\thof_ic_idea_\w+ = \{';   Exp = $ideaBlockCount },
    # 🚩🚩 以下四条【一律跟花名册人数走】—— 候选池从 7 扩到 22 时全部磮了（都已改）
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_idea_\w+_sync_rank = \{'; Exp = $roster.Count },
    # 🚩 个人数值容器的断言【不写死人名】——原先是托洛茨基/布哈林两行硬编码，
    #    上第三个人（李可夫）时就会漏检。改成下面按 $lineSpecs 循环追加。
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_appoint_\w+ = \{';     Exp = $roster.Count },
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_begin_(?!appointee)\w+_line = \{'; Exp = $branchChars.Count },
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_begin_appointee_line = \{'; Exp = 1 },
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_replace_slot_\d+ = \{'; Exp = 7 },
    @{ F = 'common/scripted_effects/hof_ic_scripted_effects.txt';   Pat = '^hof_ic_remove_slot_\d+_idea = \{'; Exp = 7 },
    @{ F = 'common/scripted_triggers/hof_ic_scripted_triggers.txt'; Pat = '^hof_ic_seated_\w+ = \{';      Exp = $roster.Count },
    @{ F = 'common/scripted_localisation/hof_ic_scripted_loc.txt';  Pat = '^defined_text = \{';           Exp = 29 },
    # 立绘 sprite = 每人 2 个（大图位 + 候选小头像）
    @{ F = 'interface/hof_ic_portraits.gfx';                        Pat = '^\tspriteType = \{';           Exp = ($roster.Count * 2) },
    @{ F = 'common/focus_inlay_windows/hof_ic_inlay_window.txt';    Pat = 'hof_ic_seat_\d+_portrait = \{'; Exp = 7 },
    @{ F = 'common/focus_inlay_windows/hof_ic_inlay_window.txt';    Pat = 'hof_ic_seat_\d+_frame = \{';    Exp = 7 },
    # 🚩 期望值随数据变化：1 个满席替换事件 + 1 个最高苏维埃主席选举事件 + 每个人 2 个驱动器事件
    #    （.01 = 开下一个国策，.02 = 到点完成）+ 每个人 1 个终局二选一事件
    #    —— Branch / $endingChoiceOf 一改，这里自动跟着变，别再写死数字。
    @{ F = 'events/hof_ic_events.txt';                             Pat = '^country_event = \{';           Exp = (2 + 2 * $branchChars.Count + $choiceEvCount + $pathEvCount) }
    @{ F = 'common/on_actions/hof_ic_branch_resume_on_actions.txt'; Pat = '^on_actions = \{';             Exp = 1 },
    @{ F = 'common/on_actions/hof_ic_branch_resume_on_actions.txt'; Pat = '^\ton_weekly = \{';           Exp = 1 },
    @{ F = 'common/on_actions/hof_ic_branch_resume_on_actions.txt'; Pat = '^\t\t\t\t\tcountry_event = \{ id = heartofiron\.(1110|1140) days = 1 \}'; Exp = $choiceEvCount }
)

# 自建角色文件【只在需要时才存在】，所以单独追加，不放进上面的固定表
if ($ownChars.Count -gt 0) {
    $checks += @{ F = 'common/characters/hof_ic_characters.txt'; Pat = '^\tSOV_\w+ = \{'; Exp = $ownChars.Count }
}

$fail = 0
foreach ($c in $checks) {
    $p = Join-Path $modRoot $c.F
    $n = (Select-String -LiteralPath $p -Pattern $c.Pat).Count
    $ok = if ($n -eq $c.Exp) { 'OK ' } else { $fail++; 'FAIL' }
    Write-Output ("  [{0}] {1,-52} {2,-38} 实际={3} 期望={4}" -f $ok, (Split-Path $c.F -Leaf), $c.Pat, $n, $c.Exp)
}

# ---- 官衔链【接线】自检（2026-09-16 补）----
# 🚩🚩 为什么要这条：布哈林上树时 Tiers 与 RankGates 都写了，但
#    个人线的国策【一个都没标 Sync】→ hof_ic_idea_nikolay_bukharin_sync_rank
#    从未被调用 → 官衔永远停在 Lv1（《真理报》主编），
#    而且【不报任何错】。这类「数据写了两处、少接一边」的错只能靠断言拦。
#    规矩：有 RankGates 的人，个人线里 Sync 国策数【必须】等于门槛数。
foreach ($ls0 in $lineSpecs) {
    $r = @($roster | Where-Object { $_.Key -eq $ls0.Key })[0]
    $nGate = if ($r.ContainsKey('RankGates') -and $r.RankGates) { @($r.RankGates).Count } else { 0 }
    $nSync = @($ls0.Line | Where-Object { $_.ContainsKey('Sync') -and $_.Sync }).Count
    $ok = if ($nGate -eq $nSync) { 'OK ' } else { $fail++; 'FAIL' }
    Write-Output ("  [{0}] 官衔链接线 {1,-22} RankGates={2}  Sync 国策={3}" -f $ok, $ls0.Key, $nGate, $nSync)
}

# ---- 席位互斥自检（docs/10 §2.4.2）----
# 查生成器刚写出的注入片段，不依赖 sync 完成
$seatsTxt = [System.IO.File]::ReadAllText($injectPath)
$nNot     = ([regex]::Matches($seatsTxt, 'NOT = \{ hof_ic_seated_\w+ = yes \}')).Count
$expNot   = $roster.Count + 2 * $exclPairCount
$okNot    = if ($nNot -eq $expNot) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 席位互斥条件 {1,-52} 实际={2} 期望={3}（{4} 自身 + {5} 对×2）" -f `
    $okNot, 'inject-sov-seats.txt', $nNot, $expNot, $roster.Count, $exclPairCount)

# 对称性：A 排掉 B ⇔ B 排掉 A
$asym = 0
foreach ($a in $rosterKeys) {
    foreach ($b in $exclOf[$a]) { if (-not $exclOf[$b].Contains($a)) { $asym++ } }
}
$okSym = if ($asym -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 互斥对称性 {1,-52} 不对称={2}" -f $okSym, 'excl pairs', $asym)

# 关键互斥必查：托洛茨基 ↔ 布哈林（R1 历史交恶 + R2 理论完全对立）
$tb = $exclOf['lev_trotsky'].Contains('nikolay_bukharin') -and `
      $exclOf['nikolay_bukharin'].Contains('lev_trotsky')
$okTb = if ($tb) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 关键互斥：托洛茨基 ↔ 布哈林" -f $okTb)

# 关键【不】互斥必查：布哈林 ↔ 加米涅夫（1928-07-11 史实；docs/25 跨人物钩子依赖）
$bk = $exclOf['nikolay_bukharin'].Contains('lev_kamenev')
$okBk = if (-not $bk) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 关键不互斥：布哈林 ↔ 加米涅夫（应可共存）" -f $okBk)

# ---- v0.6 候选池治理自检（docs/10 §2.4.2）----
# ① 体制营必须【只含可存活 3 人】—— 2026-09-15 用户「斯大林系全部删去」→ 后追加「可回池几个」
#    回池依据：docs/10 §2.4.2.2.1（对池内人物无直接血债 + 非安全机构）
$regimeOk = @('georgy_malenkow','nikita_khrushchyov','kliment_voroshilov')
$nRegime  = @($camps['regime']).Count
$badRegime = @($camps['regime'] | Where-Object { $regimeOk -notcontains $_ })
$okRegime = if ($nRegime -eq 3 -and $badRegime.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 体制营只含可存活 3 人 {1,-24} 成员数={2} 越界={3}" -f $okRegime, 'camps.regime', $nRegime, ($badRegime -join ','))

# ② 无立绘 8 人不得出现在任何营（防止以后手滑加回来）
$noArt = @('grigory_ordzhonikidze','felix_dzerzhinsky','valerian_kuibyshev','sergei_kirov','anastas_mikoyan','grigory_pyatakov','nikolai_muralov','alexandra_kollontai')
$leak = @()
foreach ($campKey in $camps.Keys) {
    foreach ($m in $camps[$campKey]) { if ($noArt -contains $m) { $leak += ($campKey + '/' + $m) } }
}
$okLeak = if ($leak.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 无立绘 8 人不在任何营 {1,-30} 泄漏={2} {3}" -f $okLeak, 'no-portrait guard', $leak.Count, ($leak -join ','))

# ③ 中立营：不得因【理论】（R2 营×营 / R3 同职能）而与任何营互斥；
#    R1 历史交恶是个人恩怨，跳营生效，允许存在。
#    🚩🚩 原断言写的是「互斥数 = 0」—— 那在 7 人小池里碰巧成立，
#         22 人池一扩就崩（图哈切夫斯基对沃罗希洛夫）。已改为只统计 R2/R3。
$neutralLeak = 0; $neutralR1 = @()
foreach ($n in $camps['neutral']) {
    if (-not $inRoster[$n]) { continue }
    foreach ($r in $exclOf[$n]) {
        if ($r1Keys -contains ((@($n, $r) | Sort-Object) -join '|')) { $neutralR1 += "$n->$r" }
        else { $neutralLeak++ }
    }
}
$okNeu = if ($neutralLeak -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 中立营不因理论互斥 {1,-30} 理论互斥={2} R1 历史交恶={3}" -f $okNeu, 'camps.neutral', $neutralLeak, $neutralR1.Count)

# ④ 候选池完整性（docs/10 §2.4.2.1：22 人 = left6 + right4 + united2 + workers1 + neutral6 + regime3）
$poolTotal = 0; $poolAll = @()
foreach ($campKey in $camps.Keys) {
    $poolTotal += @($camps[$campKey]).Count
    $poolAll   += @($camps[$campKey])
}
$dup    = @($poolAll | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
$okPool = if ($poolTotal -eq 22 -and $dup.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 候选池 22 人且跨营无重复 {1,-26} 合计={2} 重复={3}" -f $okPool, 'camps total', $poolTotal, ($dup -join ','))

# 字面量反引号残留检查
foreach ($c in $checks) {
    $p = Join-Path $modRoot $c.F
    $t = [System.IO.File]::ReadAllText($p)
    $n = ([regex]::Matches($t, [regex]::Escape('`t'))).Count
    $ok = if ($n -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
    Write-Output ("  [{0}] 无 `t 残留 {1,-52} 命中={2}" -f $ok, (Split-Path $c.F -Leaf), $n)
}

# 映射不错位自检
$locTxt = [System.IO.File]::ReadAllText((Join-Path $modRoot 'common/scripted_localisation/hof_ic_scripted_loc.txt'))
$probe  = [regex]::Match($locTxt, 'hof_ic_slot_1 = 1 \}\s*\}\s+localization_key = (\S+)')
$got    = $probe.Groups[1].Value
$okMap  = if ($got -eq "hof_ic_name_$($roster[0].Key)") { 'OK ' } else { $fail++; 'FAIL' }
Write-Output ("  [{0}] 映射自检：slot_1=1 -> {1}（期望 hof_ic_name_{2}）" -f $okMap, $got, $roster[0].Key)

# 括号配平
foreach ($c in $checks) {
    $p = Join-Path $modRoot $c.F
    $t = [System.IO.File]::ReadAllText($p)
    $o = ([regex]::Matches($t, '\{')).Count
    $cl = ([regex]::Matches($t, '\}')).Count
    $ok = if ($o -eq $cl) { 'OK ' } else { $fail++; 'FAIL' }
    Write-Output ("  [{0}] 括号配平 {1,-52} {{={2} }}={3}" -f $ok, (Split-Path $c.F -Leaf), $o, $cl)
}

Write-Output ''
if ($branchChars.Count -eq 0) {
    Write-Output "  ℹ 个人线驱动器：0 人生成（`$branches 全空）。等个人线国策进树后填 Branch 字段重跑。"
} else {
    Write-Output ("  ℹ 个人线驱动器：$($branchChars.Count) 人生成（$(( $branchChars | ForEach-Object { $_.Zh } ) -join '、')）")
}
Write-Output ''
if ($fail -gt 0) { throw "自检失败 $fail 项" }
& python (Join-Path $PSScriptRoot 'gen-hof-ic-role-ideas.py')
if ($LASTEXITCODE -ne 0) { throw '职务 idea 静态版本生成失败' }
& python (Join-Path $PSScriptRoot 'gen-hof-ic-mio.py')
if ($LASTEXITCODE -ne 0) { throw '图哈切夫斯基 MIO 特质生成失败' }
Write-Output '全部自检通过'
