# sync-from-r56.ps1
# ---------------------------------------------------------------------------
# 从 R56 生成 Heart of Iron 的国策树副本，并在锚点注入 hof 共享国策引用。
#
# 为什么需要这个脚本：HOI4 是「整文件覆盖」。要往某个国策树里加东西，就必须
# 把该文件整个复制过来改。R56 每次更新这些文件，我们都要重新合并。手工做不可
# 维护，所以做成可反复重跑的流程。
#
# 用法：
#   powershell -NoProfile -File sync-from-r56.ps1                 # 实际同步（phase<=1）
#   powershell -NoProfile -File sync-from-r56.ps1 -VerifyOnly     # 只校验锚点，不写文件
#   powershell -NoProfile -File sync-from-r56.ps1 -MaxPhase 2     # 含 phase 2
#
# 幂等性：每次都从 R56 源头重新生成目标文件，因此重复运行结果一致。
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron',
    [string]$ListPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\attach-points.json',
    [string]$R56Root = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
    [int]$MaxPhase = 1,
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'

# --- 入口国策注入行的来源 -------------------------------------------------
# 由 build/gen-hof-ic-s3.ps1 按【花名册】产出（花名册的单一数据源在那里）。
# 不在本脚本里再手抄一份 7 个国策，就是为了避免两处维护而漂移。
# 找不到就直接报错，不静默跳过——否则会得到一个“同步成功但窗口永远填不满”的假象。
$hofIcSeatInjectPath = Join-Path (Split-Path -Parent $ListPath) 'inject-sov-seats.txt'
if (-not (Test-Path $hofIcSeatInjectPath)) {
    throw "缺少入口国策注入文件：`n  $hofIcSeatInjectPath`n请先运行 build/gen-hof-ic-s3.ps1 生成它。"
}
# ⚠️ 必须带 -Encoding UTF8。
#    PowerShell 5.1 的 Get-Content 默认按【ANSI（本机是 GBK）】解码，
#    而这个注入文件是 UTF-8 无 BOM 的，里面含中文注释。
#    不带这个参数会把注释读成乱码再写进 soviet.txt（已踩过）。
$hofIcSeatInjectLines = @(Get-Content -LiteralPath $hofIcSeatInjectPath -Encoding UTF8)

# --- 核心圈容器悬挂：往指定国策的 completion_reward 里插的行 -----------
# 机制蓝本：原版 GER_fuhrerprinzip 的 completion_reward 里有一条
#     hidden_effect = { add_dynamic_modifier = { modifier = GER_the_inner_circle_dm } }
# 我们的枢纽是 R56/原版的 SOV_the_supreme_soviet，它不在注入区内，
# 所以需要另一种补丁：定位该 focus 块，在它的 completion_reward 开头插行。
# 同样由 gen-hof-ic-s3.ps1 产出，不在这里手抄。
$hofHubInjectPath = Join-Path (Split-Path -Parent $ListPath) 'inject-sov-hub.txt'
if (-not (Test-Path $hofHubInjectPath)) {
    throw "缺少核心圈容器挂载行文件：`n  $hofHubInjectPath`n请先运行 build/gen-hof-ic-s3.ps1 生成它。"
}
$hofHubInjectLines = @(Get-Content -LiteralPath $hofHubInjectPath -Encoding UTF8)

# 哪些【挂载点 id】的源文件里，需要做「国策内插行」补丁
#
# 🔄 2026-09-24 起本表【按挂载点分层】：
#     外层键 = 挂载点 id（见 attach-points.json）· 内层键 = 国策 id
#     值 = 要塞进该国策 completion_reward 开头（`{` 之后）的行
#     为什么要分层：AST 那条线在 australia_taog.txt（挂载点 ast_std），
#     SOV 那批在 soviet.txt（挂载点 sov_core）—— 单层表没法区分文件。
#     每层仍走 Add-FocusPatches：国策 id 行必须恰好命中 1 次，否则 throw。
#
# ⭐ 为什么用「在 completion_reward 开头插行」而不是改原行：
#     这一批改动绝大多数是【追加效果】（加核心）—— 原有效果一律保留，零回归。
#     只有必须【替换】原行的（宣称 → 核心）才走下面的 $ValuePatchMap。
#
# 🚩 2026-09-16 的历史记录：本表原本为空 —— 容器 DM 的挂载已改由【我们自己的】
#     中间国策 hof_ic_commissar 承担（生成器 §10y），不再补丁原版 SOV_the_supreme_soviet。
$FocusPatchMap = @{

    # ===================== 暹罗（common/national_focus/siam.txt）=====================
    'sia_std' = @{
        'SIA_farmers_into_the_city' = @(
            '# hof: 农民进城后曼谷（1134 州、7408 省）+2 胜利点',
            '1134 = { add_victory_points = { province = 7408 value = 2 } }'
        )
    }

    # ===================== 苏联（common/national_focus/soviet.txt）=====================
    'sov_core' = @{

        'SOV_transformation_of_nature' = @(
            '# hof: 莫斯科和新西伯利亚增建大坝；省份与 map/buildings.txt 的坝址一致',
            '219 = {',
            '    add_building_construction = { type = dam level = 1 instant_build = yes province = { id = 11236 } }',
            '    custom_effect_tooltip = { localization_key = building_state_modifier|dam INDENT = "    " }',
            '}',
            '570 = {',
            '    add_building_construction = { type = dam level = 1 instant_build = yes province = { id = 4734 } }',
            '    custom_effect_tooltip = { localization_key = building_state_modifier|dam INDENT = "    " }',
            '}'
        )

        'SOV_eastern_development' = @(
            '# hof: 滨海边疆区／符拉迪沃斯托克 +5，哈巴罗夫斯克 +4 胜利点',
            '408 = { add_victory_points = { province = 957 value = 5 } }',
            '409 = { add_victory_points = { province = 12189 value = 4 } }'
        )

        'SOV_develop_the_urals' = @(
            '# hof: 兹拉托乌斯特 +4 胜利点',
            '573 = { add_victory_points = { province = 10329 value = 4 } }'
        )

        'SOV_development_of_tankograd' = @(
            '# hof: 车里雅宾斯克 +5 胜利点',
            '572 = { add_victory_points = { province = 9292 value = 5 } }'
        )

        'SOV_soviet_atomic_bomb_project' = @(
            '# hof: 谢米巴拉金斯克 +4 胜利点',
            '588 = { add_victory_points = { province = 12594 value = 4 } }'
        )

        'SOV_modernize_aircraft_facilities' = @(
            '# hof: 沃罗涅日 +5 胜利点',
            '260 = { add_victory_points = { province = 413 value = 5 } }'
        )

        'SOV_the_fight_for_the_pacific' = @(
            '# hof: 堪察加／埃利佐沃 +4，滨海边疆区 +5，哈巴罗夫斯克 +5 胜利点',
            '637 = { add_victory_points = { province = 4728 value = 4 } }',
            '408 = { add_victory_points = { province = 957 value = 5 } }',
            '409 = { add_victory_points = { province = 12189 value = 5 } }'
        )

        'SOV_move_industry_to_the_urals' = @(
            '# hof: 车里雅宾斯克 +5，阿拉木图 +5，塔什干 +5 胜利点',
            '572 = { add_victory_points = { province = 9292 value = 5 } }',
            '586 = { add_victory_points = { province = 1591 value = 5 } }',
            '405 = { add_victory_points = { province = 1459 value = 5 } }'
        )

        'SOV_annex_tannu_tuva' = @(
            '# hof: 图瓦／克孜勒 +2 胜利点',
            '329 = { add_victory_points = { province = 10627 value = 2 } }'
        )

        'SOV_impregnable_forts' = @(
            '# hof: 列宁格勒、卢加与塞瓦斯托波尔胜利点',
            '195 = { add_victory_points = { province = 3151 value = 10 } }',
            '208 = { add_victory_points = { province = 9098 value = 4 } }',
            '137 = { add_victory_points = { province = 3686 value = 10 } }'
        )

        'SOV_defense_of_stalingrad' = @(
            '# hof: 斯大林格勒胜利点',
            '217 = { add_victory_points = { province = 3529 value = 10 } }'
        )

        'SOV_claim_on_bessarabia' = @(
            '# hof: 摩尔多瓦 79 核心；比萨拉比亚三州由专属替换补丁从宣称改为核心',
            '79 = { add_core_of = ROOT }'
        )

        'SOV_claim_on_the_straits' = @(
            '# hof: 伊斯坦布尔胜利点',
            '797 = { add_victory_points = { province = 9833 value = 15 } }'
        )

        # 控制斯堪的纳维亚 → 加【斯堪的纳维亚三国全境】核心
        # ⛔ 不含芬兰：芬兰是北欧但不是斯堪的纳维亚，且本线另有 FIN 的决议联动
        # 州表来源：R56 history/states 按【州 id】归并后取 owner ∩ add_core_of
        #           （NOR 11 / SWE 13 / DEN 6 = 30 州）
        'SOV_control_scandinavia' = @(
            '# hof: 斯堪的纳维亚三国全境核心（挪 11 / 瑞 13 / 丹 6）',
            'add_state_core = 110',
            'add_state_core = 142',
            'add_state_core = 143',
            'add_state_core = 144',
            'add_state_core = 967',
            'add_state_core = 1027',
            'add_state_core = 1031',
            'add_state_core = 1032',
            'add_state_core = 1033',
            'add_state_core = 1034',
            'add_state_core = 1035',
            'add_state_core = 38',
            'add_state_core = 124',
            'add_state_core = 138',
            'add_state_core = 139',
            'add_state_core = 140',
            'add_state_core = 141',
            'add_state_core = 666',
            'add_state_core = 968',
            'add_state_core = 969',
            'add_state_core = 1026',
            'add_state_core = 1028',
            'add_state_core = 1029',
            'add_state_core = 1030',
            'add_state_core = 37',
            'add_state_core = 99',
            'add_state_core = 337',
            'add_state_core = 964',
            'add_state_core = 1024',
            'add_state_core = 1025'
        )

        # 收复千岛群岛 → 加【南萨哈林 / 千岛群岛 / 北海道】核心
        # ⭐ 该 focus 解锁的和平决议（SOV_peace_deal_for_*）在 R56 里拿不到核心：
        #    事件 NSB_soviet_foreign_politics_events.260/.261 的 add_core_of 两行
        #    在 R56 被挪进了 FROM = { } 里（原版在外面）→ 见 docs/98 §4
        #    ⇒ 本线把核心直接挂在 focus 上，不再依赖那个决议。
        # 🔄 2026-09-25 用户口径「收复千岛群岛**新增**关东地方，北陆道，南东北地方，
        #    北东北地方，甲信越地方，东海道的核心」⇒ 从 3 州扩到 9 州
        #    （日本本州/东北的这 6 个州原本是 JAP 的核心）
        'SOV_recover_the_kuril_islands' = @(
            '# hof: 南萨哈林 537 / 千岛群岛 555 / 北海道 536 / 关东 282 / 北陆道 534 /',
            '#      南东北 1106 / 北东北 533 / 甲信越 535 / 东海道 532 —— 直接给核心',
            'add_state_core = 537',
            'add_state_core = 555',
            'add_state_core = 536',
            'add_state_core = 282',
            'add_state_core = 534',
            'add_state_core = 1106',
            'add_state_core = 533',
            'add_state_core = 535',
            'add_state_core = 532'
        )

        # 收复阿拉斯加 → 加【阿拉斯加 463 / 阿图岛 650】核心
        'SOV_recover_alaska' = @(
            '# hof: 阿拉斯加 463 / 阿图岛 650 核心',
            'add_state_core = 463',
            'add_state_core = 650',
            '# hof: 阿拉斯加／安克雷奇 +2 胜利点',
            '463 = { add_victory_points = { province = 13091 value = 2 } }'
        )

        # 增建东部海军基地 → 加【朝鲜半岛全境】核心
        # 州表 = R56 里 add_core_of = KOR 的 6 个州（525/527/917/918/919/920，
        #        全部 owner = JAP）—— 显式列 id，⛔ 不用 is_core_of = KOR
        #        （R56 的 KOR 还挂了 4 个瑞典州，是数据里的杂项）
        'SOV_reinforce_eastern_naval_bases' = @(
            '# hof: 朝鲜半岛全境核心（6 州）',
            'add_state_core = 525',
            'add_state_core = 527',
            'add_state_core = 917',
            'add_state_core = 918',
            'add_state_core = 919',
            'add_state_core = 920'
        )

        # 刺向南方 → 原有伊朗 11 州 + 法里亚布 1008 / 巴达赫尚 1011，共 13 州核心
        # 州名按 R56 的 ostan 命名：东阿塞拜疆 419 / 西阿塞拜疆 988 / 呼罗珊礼萨 416 /
        # 戈勒斯坦 983 / 马赞德兰 984 / 德黑兰 266 / 加兹温 986 / 吉兰 420 /
        # 阿尔达比勒 987 / 库尔德斯坦 421 / 马凯斯 417
        'SOV_the_southern_thrust' = @(
            '# hof: 伊朗 11 州及阿富汗法里亚布、巴达赫尚核心',
            'add_state_core = 419',
            'add_state_core = 988',
            'add_state_core = 416',
            'add_state_core = 983',
            'add_state_core = 984',
            'add_state_core = 266',
            'add_state_core = 986',
            'add_state_core = 420',
            'add_state_core = 987',
            'add_state_core = 421',
            'add_state_core = 417',
            'add_state_core = 1008',
            'add_state_core = 1011'
        )

        # 古巴基地 → 加【百慕大 696】核心
        'SOV_interest_in_cuba' = @(
            '# hof: 百慕大 696 核心',
            'add_state_core = 696'
        )
    }

    # ===================== 澳大利亚（common/national_focus/australia_taog.txt）=====================
    # 州表 = R56 里 owner ∩ add_core_of = NZL 的 6 个州
    #        （284 惠灵顿 / 723 坎特伯雷 / 1087 查塔姆群岛 /
    #          1136 奥克兰 / 1139 马尔伯勒 / 1140 奥塔哥）
    # ⛔ 不取 NZL 的海外属地（726 / 1089 —— 都是「新西兰托管」而非本土）
    'ast_std' = @{
        'AST_the_australian_commonwealth' = @(
            '# hof: 新西兰全境核心（6 州）',
            'add_state_core = 284',
            'add_state_core = 723',
            'add_state_core = 1087',
            'add_state_core = 1136',
            'add_state_core = 1139',
            'add_state_core = 1140'
        )
    }

    'sau_mutual' = @{
        'SAU_attack_turkey' = @(
            '# hof: 土耳其原版 22 个核心州中除苏联指定 7 州以外的 15 州',
            'add_state_core = 49',
            'add_state_core = 343',
            'add_state_core = 344',
            'add_state_core = 345',
            'add_state_core = 346',
            'add_state_core = 348',
            'add_state_core = 349',
            'add_state_core = 350',
            'add_state_core = 352',
            'add_state_core = 353',
            'add_state_core = 355',
            'add_state_core = 356',
            'add_state_core = 798',
            'add_state_core = 799',
            'add_state_core = 800'
        )
    }

    # ===================== 蒙古（common/national_focus/mongolia.txt）=====================
    'mon_mutual' = @{
        'MON_ulan_bator_promcombinat' = @(
            '# hof: 乌兰巴托 +5 胜利点',
            '330 = { add_victory_points = { province = 4801 value = 5 } }'
        )
        'MON_improve_baigaal_dalai_industries' = @(
            '# hof: 布里亚特／乌兰乌德 +4，伊尔库茨克 +2 胜利点',
            '564 = { add_victory_points = { province = 10528 value = 4 } }',
            '566 = { add_victory_points = { province = 4797 value = 2 } }'
        )
        'MON_develop_mongolia_proper' = @(
            '# hof: 戈壁／赛音山达、库苏古尔／木伦各 +4 胜利点',
            '817 = { add_victory_points = { province = 12612 value = 4 } }',
            '820 = { add_victory_points = { province = 1834 value = 4 } }'
        )
        'MON_assist_subsidized_region' = @(
            '# hof: 图瓦／克孜勒 +5，科布多／乌兰固木 +4 胜利点',
            '329 = { add_victory_points = { province = 10627 value = 5 } }',
            '818 = { add_victory_points = { province = 7843 value = 4 } }'
        )
        'MON_develop_the_rear' = @(
            '# hof: 赤塔 +3 胜利点',
            '563 = { add_victory_points = { province = 12641 value = 3 } }'
        )
        'MON_southwest_resource_prospection_area' = @(
            '# hof: 迪化 +5，准噶尔／阿勒泰 +4 胜利点；原有地区类型与修正目标另行纠正',
            '617 = { add_victory_points = { province = 4709 value = 5 } }',
            '618 = { add_victory_points = { province = 4823 value = 4 } }'
        )
        'MON_expand_chahars_processing_region' = @(
            '# hof: 察哈尔／张北 +2，锡林郭勒／锡林浩特 +4 胜利点',
            '611 = { add_victory_points = { province = 10397 value = 2 } }',
            '612 = { add_victory_points = { province = 10372 value = 4 } }'
        )
        'MON_ordos_plateau_exploitation' = @(
            '# hof: 绥远／归绥、伊克昭／鄂尔多斯各 +4 胜利点',
            '621 = { add_victory_points = { province = 7631 value = 4 } }',
            '746 = { add_victory_points = { province = 3427 value = 4 } }'
        )
        'MON_encourage_southern_agriculture' = @(
            '# hof: 内蒙古／银川 +3，酒泉 +4 胜利点',
            '616 = { add_victory_points = { province = 8127 value = 3 } }',
            '756 = { add_victory_points = { province = 7971 value = 4 } }'
        )
    }

    # ===================== 中共（common/national_focus/china_communist_sea.txt）=====================
    # 🔄 2026-09-25 新开的一层 —— 用户口径：「中共的**驱逐日寇**（R56 里的显示名是
    #    「驱逐敌寇」= `PRC_expel_the_occupiers`）新增琉球群岛，九州地方，南九州地方，
    #    山阴地方，中国地方，四国地方，关西地方的核心」。
    # ⚠️ 本层是**第一个**非 SOV / 非 AST 的层 —— 说明分层表确实必要。
    # 州表 = R56 里 JAP 的南/西日本本土核心州（与 SOV 那条各分一半：
    #        SOV 拿关东/东北/中部 6 州，PRC 拿九州·四国·中国·关西·琉球 7 州）。
    'prc_sino' = @{
        'PRC_move_capital' = @(
            '# hof: 北平（完成后改名北京）+10 胜利点',
            '608 = { add_victory_points = { province = 9843 value = 10 } }'
        )

        'PRC_urbanization' = @(
            '# hof: 仅在控制相应州时，陕西／瓦窑堡 +4、延安 +3 胜利点',
            'if = {',
            '    limit = { controls_state = 622 }',
            '    622 = { add_victory_points = { province = 12356 value = 4 } }',
            '}',
            'if = {',
            '    limit = { controls_state = 1111 }',
            '    1111 = { add_victory_points = { province = 8049 value = 3 } }',
            '}'
        )

        'PRC_urbanization_two' = @(
            '# hof: 仅在控制相应州时，西安 +9、山西／太原 +4 胜利点',
            'if = {',
            '    limit = { controls_state = 744 }',
            '    744 = { add_victory_points = { province = 7301 value = 9 } }',
            '}',
            'if = {',
            '    limit = { controls_state = 615 }',
            '    615 = { add_victory_points = { province = 4174 value = 4 } }',
            '}'
        )

        'PRC_expel_the_occupiers' = @(
            '# hof: 中共对日本本土 7 州的核心（琉球 526 / 九州 528 / 南九州 1105 /',
            '#      山阴 1107 / 中国地方 529 / 四国 530 / 关西 531）',
            'add_state_core = 526',
            'add_state_core = 528',
            'add_state_core = 1105',
            'add_state_core = 1107',
            'add_state_core = 529',
            'add_state_core = 530',
            'add_state_core = 531'
        )
    }

    # ===================== 洪都拉斯（common/national_focus/honduras.txt）=====================
    # 🔄 2026-09-25 新增 —— 本项目**第一个「只为改内容而覆盖」的挂载点**
    #    （带 `"s5": false` ⇒ 不往这棵树里注 shared_focus，至少不会钻进经互会）
    # 用户口径：「洪都拉斯的国策进行修改 —— **向北进攻**效果增加除了尤卡坦和恰帕斯之外的
    #            所有墨西哥领土的核心」
    # 「向北进攻」= `HON_liberate_mexico_again`（R56 honduras.txt；树 id = `hon_focus`）
    #   原效果**只有** create_wargoal = { type = puppet_wargoal_focus target = MEX }
    # 州表 = R56 里 owner ∩ add_core_of = MEX 的 **17 州** − 尤卡坦 474 − 恰帕斯 475 = **15 州**
    'hon_std' = @{
        'HON_liberate_mexico_again' = @(
            '# hof: 墨西哥全境核心 · 除尤卡坦 474 / 恰帕斯 475 —— 共 15 州',
            'add_state_core = 277',
            'add_state_core = 476',
            'add_state_core = 477',
            'add_state_core = 478',
            'add_state_core = 479',
            'add_state_core = 480',
            'add_state_core = 481',
            'add_state_core = 482',
            'add_state_core = 483',
            'add_state_core = 484',
            'add_state_core = 485',
            'add_state_core = 929',
            'add_state_core = 930',
            'add_state_core = 931',
            'add_state_core = 932'
        )
    }
}

# --- 值补丁：整块【字面替换】 ------------------------------------------------
# 为什么要单开一张表：soviet.txt 每次都从 R56 重新生成，手工改会被下次同步覆盖。
# 用法：键 = 挂载点 id；值 = @( @{ Name=...; Old=@(旧行...); New=@(新行...) } )
#   - Old / New 里【不要写行首缩进】，缩进由脚本按命中处的缩进自动补
#   - Old 必须恰好命中 1 次，否则 throw（宁可报错也不静默改错位置）
#   - 行间空白用 \s* 匹配，所以 CRLF / 多余空行都能命中
$ValuePatchMap = @{

    'dec_sia' = @(
        @{
            Name = '河内要塞：无 DLC 分支的堡垒落到河内所属省份'
            Old = @(
                'else = {',
                '671 = {',
                'add_building_construction = {',
                'type = bunker',
                'level = 5',
                'instant_build = yes',
                'province = 4401',
                '}',
                'add_building_construction = {',
                'type = coastal_bunker',
                'level = 5',
                'instant_build = yes',
                'province = 4401'
            )
            New = @(
                'else = {',
                '671 = {',
                'add_building_construction = {',
                'type = bunker',
                'level = 5',
                'instant_build = yes',
                'province = 4075',
                '}',
                'add_building_construction = {',
                'type = coastal_bunker',
                'level = 5',
                'instant_build = yes',
                'province = 4119'
            )
        },
        @{
            Name = '三角防御网络：地图高亮落在曼谷而非海峡群岛'
            Old = @('state = 1076')
            New = @('state = 1134')
        },
        @{
            Name = '三角防御网络：DLC 分支建在曼谷州'
            Old = @('1076 = {')
            New = @('1134 = {')
        },
        @{
            Name = '三角防御网络：无 DLC 分支建在曼谷州'
            Old = @(
                'else = {',
                '671 = {',
                'add_building_construction = {',
                'type = bunker',
                'level = 5',
                'instant_build = yes',
                'province = 7408'
            )
            New = @(
                'else = {',
                '1134 = {',
                'add_building_construction = {',
                'type = bunker',
                'level = 5',
                'instant_build = yes',
                'province = 7408'
            )
        }
    )

    'event_sov_tuva' = @(
        @{
            Name = '图瓦接受并入：吞并前转移全部将领和科学家'
            Old = @(
                'name = soviet.16.a',
                'annex_country = { target = TAN }',
                'hidden_effect = {'
            )
            New = @(
                'name = soviet.16.a',
                '# hof: 图瓦角色须在吞并前转籍，否则原国家消失后无法遍历',
                'TAN = {',
                '    every_unit_leader = {',
                '        include_invisible = yes',
                '        set_nationality = ROOT',
                '    }',
                '    every_scientist = {',
                '        set_nationality = ROOT',
                '    }',
                '}',
                'annex_country = { target = TAN }',
                'hidden_effect = {'
            )
        }
    )

    'sia_std' = @(
        @{
            Name = '大泰帝国：订正 R56 旧缅甸州号并明确核心奖励'
            Old = @(
                'set_cosmetic_tag = SIA_great_thai_empire',
                'every_state = {',
                'limit = {',
                'OR = {',
                'is_in_array = { array = ROOT.indochina_states value = THIS }',
                'is_in_array = { array = ROOT.malaysia_burma_states value = THIS }',
                '}',
                '}',
                'add_core_of = ROOT',
                '}'
            )
            New = @(
                'set_cosmetic_tag = SIA_great_thai_empire',
                'custom_effect_tooltip = hof_SIA_greater_thai_empire_core_tt',
                'hidden_effect = {',
                '    hof_SIA_grant_greater_thai_empire_cores = yes',
                '}'
            )
        },
        @{
            Name = '泛泰主义：设下诱饵亦可进入且不依附隐藏的午夜会议定位'
            Old = @(
                'id =  SIA_pan_thaiism',
                'icon = GFX_focus_SIA_pan_thaiism',
                'x = 7',
                'y = 1',
                'relative_position_id = SIA_the_midnight_meeting',
                'prerequisite = { focus = SIA_the_midnight_meeting focus = SIA_phibuns_premiership }'
            )
            New = @(
                'id =  SIA_pan_thaiism',
                'icon = GFX_focus_SIA_pan_thaiism',
                '# hof: 原始绝对位置 = 午夜会议(15,6) + (7,1)；独立于会在 HIDE 下消失的午夜会议',
                'x = 22',
                'y = 7',
                'prerequisite = { focus = SIA_the_midnight_meeting focus = SIA_phibuns_premiership focus = SIA_to_lay_the_bait }'
            )
        },
        @{
            Name = '泛泰主义：设下诱饵后的民主路线满足可用条件'
            Old = @(
                'NOT = {',
                'has_government = democratic',
                '}',
                'OR = {',
                'threat > 0.25',
                'has_war_support > 0.2',
                'FRA = {',
                'OR = {',
                'has_war = yes',
                'has_capitulated = yes',
                '}',
                '}',
                'custom_trigger_tooltip = {',
                'tooltip = vichy_exist_trigger',
                'country_exists = VIC',
                '}',
                '}'
            )
            New = @(
                'OR = {',
                '    has_completed_focus = SIA_to_lay_the_bait',
                '    AND = {',
                '        NOT = { has_government = democratic }',
                '        OR = {',
                '            threat > 0.25',
                '            has_war_support > 0.2',
                '            FRA = {',
                '                OR = { has_war = yes has_capitulated = yes }',
                '            }',
                '            custom_trigger_tooltip = {',
                '                tooltip = vichy_exist_trigger',
                '                country_exists = VIC',
                '            }',
                '        }',
                '    }',
                '}'
            )
        },
        @{
            Name = '暹罗银行：隐藏分支规则下仍显示泰国稻米公司'
            Old = @(
                'allow_branch = {',
                'if = {',
                'limit = {',
                'has_game_rule = {',
                'rule = obsolete_focus_branches_visibility',
                'option = HIDE',
                '}',
                '}',
                'NOT = { has_completed_focus = SIA_thai_rice_company }',
                '}',
                '}',
                'search_filters = { FOCUS_FILTER_INDUSTRY }'
            )
            New = @(
                'search_filters = { FOCUS_FILTER_INDUSTRY }'
            )
        },
        @{
            Name = '泰国稻米公司：隐藏分支规则下仍显示暹罗银行'
            Old = @(
                'allow_branch = {',
                'if = {',
                'limit = {',
                'has_game_rule = {',
                'rule = obsolete_focus_branches_visibility',
                'option = HIDE',
                '}',
                '}',
                'NOT = { has_completed_focus = SIA_the_bank_of_siam }',
                '}',
                '}',
                'search_filters = { FOCUS_FILTER_INDUSTRY }'
            )
            New = @(
                'search_filters = { FOCUS_FILTER_INDUSTRY }'
            )
        }
    )

    'afg_r56' = @(
        @{
            Name = '打倒国王：内战后按巴拉克宰效忠者特质校验将领并保留科学家'
            # R56 两个规模分支均 keep_all_characters=yes，并显式转移王室阵营角色。
            # 校验必须放在分支汇合及原有转移之后，避免被后续脚本再次改动。
            Old = @(
                'news_event = { id = r56_afghanistan.105 hours = 18 }'
            )
            New = @(
                '# hof: 内战生成后校验双方将领；科学家全部留在共产主义原国家',
                'random_country = {',
                '    limit = { original_tag = ROOT has_civil_war = yes has_war_with = ROOT NOT = { has_government = communism } }',
                '    every_unit_leader = {',
                '        include_invisible = yes',
                '        limit = { NOT = { has_trait = AFG_barakzai_royalist } }',
                '        set_nationality = ROOT',
                '    }',
                '    every_scientist = {',
                '        include_invisible = yes',
                '        set_nationality = ROOT',
                '    }',
                '    ROOT = {',
                '        every_unit_leader = {',
                '            include_invisible = yes',
                '            limit = { has_trait = AFG_barakzai_royalist }',
                '            set_nationality = PREV.PREV',
                '        }',
                '    }',
                '}',
                'news_event = { id = r56_afghanistan.105 hours = 18 }'
            )
        }
    )

    'hun_wuw' = @(
        @{
            Name = '重燃1848年精神：内战后按法西斯主义支持者特质双向校验将领'
            # R56 用 keep_all_characters=yes 留下全部科学家，随后显式转移霍尔蒂阵营人物。
            # 只靠 start_civil_war 的 keep trigger 会被 keep_all_characters 忽略；
            # 故在内战生成与显式转移结束后，仿 baltic_shared 双向清理陆海军将领。
            Old = @(
                'custom_effect_tooltip = generic_skip_one_line_tt',
                'add_country_leader_role = {',
                'character = HUN_mihaly_karolyi'
            )
            New = @(
                '# hof: 内战生成后校验双方将领；科学家由原有 keep_all_characters=yes 留在原国家',
                'hidden_effect = {',
                '    random_country = {',
                '        limit = { original_tag = ROOT has_war_with = ROOT }',
                '        every_unit_leader = {',
                '            include_invisible = yes',
                '            limit = { NOT = { has_trait = trait_HUN_fascist_sympathies } }',
                '            set_nationality = ROOT',
                '        }',
                '        ROOT = {',
                '            every_unit_leader = {',
                '                include_invisible = yes',
                '                limit = { has_trait = trait_HUN_fascist_sympathies }',
                '                set_nationality = PREV.PREV',
                '            }',
                '        }',
                '    }',
                '}',
                'custom_effect_tooltip = generic_skip_one_line_tt',
                'add_country_leader_role = {',
                'character = HUN_mihaly_karolyi'
            )
        }
    )

    'ger_economy_mutex' = @(
        @{
            Name = '德奥合并：双路线前置、独立显示与冯·纽赖特路线坐标'
            Old = @(
                'id = GER_anschluss',
                'icon = GFX_goal_GER_anschluss',
                'alternate_icon = GFX_goal_GER_anschluss_historical',
                'prerequisite = { focus = GER_reorganize_the_wehrmacht }',
                'x = 7',
                'y = 1',
                'relative_position_id = GER_reorganize_the_wehrmacht'
            )
            New = @(
                'id = GER_anschluss',
                'icon = GFX_goal_GER_anschluss',
                'alternate_icon = GFX_goal_GER_anschluss_historical',
                'prerequisite = { focus = GER_reorganize_the_wehrmacht focus = GER_heed_von_neuraths_concerns }',
                'allow_branch = {',
                'NOT = { has_completed_focus = GER_oppose_hitler_ww }',
                'NOT = { has_completed_focus = GER_oppose_hitler }',
                'NOT = { has_completed_focus = GER_die_letzte_verschwoerung }',
                'NOT = { has_completed_focus = GER_kill_hitler }',
                '}',
                'x = 7',
                'y = 2',
                'relative_position_id = GER_remilitarize_the_rhineland',
                'offset = {',
                'x = -16',
                'y = 12',
                'trigger = {',
                'has_game_rule = { rule = obsolete_focus_branches_visibility option = HIDE }',
                'has_completed_focus = GER_heed_von_neuraths_concerns',
                '}',
                '}'
            )
        },
        @{
            Name = '整合捷克制造商：冯·纽赖特路线完成后仍显示'
            Old = @(
                'id = GER_integrate_czech_manufacturers',
                'icon = GFX_focus_PER_czech_tanks',
                'prerequisite = { focus = GER_integrate_czechoslovakia  focus = GER_fate_of_czechoslovakia }',
                'x = -2',
                'y = 1',
                'relative_position_id = GER_fate_of_czechoslovakia',
                'cost = 5',
                'ai_will_do = {',
                'base = 0',
                'modifier = {',
                'is_historical_focus_on = no',
                'add = 1',
                '}',
                '}',
                'allow_branch = {',
                'has_dlc = "Peace For Our Time"',
                'if = {',
                'limit = {',
                'has_game_rule = {',
                'rule = obsolete_focus_branches_visibility',
                'option = HIDE',
                '}',
                '}',
                'NOT = {',
                'has_completed_focus = GER_oppose_hitler',
                'has_completed_focus = GER_oppose_hitler_ww',
                'has_completed_focus = GER_die_letzte_verschwoerung',
                'has_completed_focus = GER_heed_von_neuraths_concerns',
                '}',
                '}'
            )
            New = @(
                'id = GER_integrate_czech_manufacturers',
                'icon = GFX_focus_PER_czech_tanks',
                'prerequisite = { focus = GER_integrate_czechoslovakia  focus = GER_fate_of_czechoslovakia }',
                'x = -2',
                'y = 1',
                'relative_position_id = GER_fate_of_czechoslovakia',
                'cost = 5',
                'ai_will_do = {',
                'base = 0',
                'modifier = {',
                'is_historical_focus_on = no',
                'add = 1',
                '}',
                '}',
                'allow_branch = {',
                'has_dlc = "Peace For Our Time"',
                'if = {',
                'limit = {',
                'has_game_rule = {',
                'rule = obsolete_focus_branches_visibility',
                'option = HIDE',
                '}',
                '}',
                'NOT = {',
                'has_completed_focus = GER_oppose_hitler',
                'has_completed_focus = GER_oppose_hitler_ww',
                'has_completed_focus = GER_die_letzte_verschwoerung',
                '}',
                '}'
            )
        },
        @{
            Name = '玻利瓦尔行动：冯·纽赖特路线完成后仍显示'
            Old = @(
                'id = GER_operation_bolivar',
                'icon = GFX_goal_generic_intelligence_exchange',
                'cost = 5',
                'allow_branch = {',
                'IF = {',
                'limit = {',
                'has_game_rule = {',
                'rule = obsolete_focus_branches_visibility',
                'option = HIDE',
                '}',
                '}',
                'NOT = { has_completed_focus = GER_heed_von_neuraths_concerns }',
                '}',
                'NOT = {'
            )
            New = @(
                'id = GER_operation_bolivar',
                'icon = GFX_goal_generic_intelligence_exchange',
                'cost = 5',
                'allow_branch = {',
                'NOT = {'
            )
        }
    )

    'sov_core' = @(
        @{
            Name = '无暇和平：给予苏联专属的 120% 秘密武器精神'
            Old = @(
                'add_ideas = generic_secret_weapons_ns',
                '#TODO_r56 rework this ideas modifers:',
                '#add_ideas = SOV_no_time_for_peace_idea'
            )
            New = @(
                '# hof: 无暇和平专属精神；通用 generic_secret_weapons_ns 保持 R56 原值',
                'add_ideas = hof_sov_no_time_for_peace'
            )
        },
        @{
            Name = '托洛茨基的元帅职务加强'
            # 来源：old/common/national_focus/soviet.txt（用户旧 mod）
            # ⚠️ 老文件里特质写成了大写（Brilliant_Strategist 等），引擎只认【小写】→ 此处已订正
            Old = @(
                'add_field_marshal_role = {',
                'character = SOV_lev_trotsky',
                'traits = { media_personality organisational_leader }',
                'skill = 4',
                'attack_skill = 3',
                'defense_skill = 2',
                'planning_skill = 4',
                'logistics_skill = 4',
                '}'
            )
            New = @(
                '# hof: 托洛茨基的元帅职务加强（数值来源 old/common/national_focus/soviet.txt；见 docs/95）',
                'add_field_marshal_role = {',
                '	character = SOV_lev_trotsky',
                '	traits = { media_personality organisational_leader brilliant_strategist war_hero bearer_of_artillery infantry_officer cavalry_officer armor_officer engineer_officer }',
                '	skill = 8',
                '	attack_skill = 8',
                '	defense_skill = 8',
                '	planning_skill = 8',
                '	logistics_skill = 8',
                '}'
            )
        }

        # ---------------------------------------------------------------
        # 2026-09-24 用户口径：以下 5 条把「宣称」改为「核心」（含扩大到全境）
        # ⚠️ 这些必须走【整块字面替换】而不是插行 —— 否则旧的 add_state_claim
        #    会和新加的 add_state_core 并存（工具提示里会同时出现两行）。
        # ---------------------------------------------------------------

        @{
            Name = '宣称波罗的海：宣称 → 核心（全境 + 柯尼斯堡）'
            # 原：region 37 里排除 188（梅梅尔）+ 784（维尔诺），只给宣称
            # 新：「全境」= 含梅梅尔；并加柯尼斯堡 763（东普鲁士北部；南部 5 号州是德国核心）
            Old = @(
                '# Estonia + Latvia + Lithuania except Memel',
                'custom_effect_tooltip = SOV_claims_in_baltics_tt',
                'hidden_effect = {',
                'every_state = {',
                'limit = {',
                'OR = {',
                'AND = {',
                'NOT = {',
                'state = 188',
                '}',
                'region = 37',
                '}',
                'state = 784',
                '}',
                '}',
                'add_claim_by = ROOT',
                '}',
                '}'
            )
            New = @(
                '# hof: 波罗的海全境（含梅梅尔 188）+ 维尔诺 784 —— 由宣称改为核心',
                'custom_effect_tooltip = SOV_claims_in_baltics_tt',
                'hidden_effect = {',
                '	every_state = {',
                '		limit = {',
                '			OR = {',
                '				region = 37',
                '				state = 784',
                '			}',
                '		}',
                '		add_core_of = ROOT',
                '	}',
                '	763 = { add_core_of = ROOT } #柯尼斯堡',
                '}'
            )
        }

        @{
            Name = '宣称波兰：核心并含喀尔巴阡鲁塞尼亚与乌日霍罗德'
            # 全境 = POL 的 20 个核心州 − 德国能拿到核心的 7 州
            #   德国来源：GER_restore_eastern_imperial_possessions（85/807/86/762）
            #            + GER_demand_further_polish_concessions（87/98/97/934）
            #            + 莫洛托夫事件 soviet.60（86/85/762/807 发核心）
            #   ⇒ 排除 {86, 87, 97, 98, 762, 807, 934}（85 但泽是 DNZ 的核心，本来就不在 POL 表里）
            #   ⇒ 本线给 13 州：10/88/89/90/91/92/93/94/95/96/784/935/936
            Old = @(
                '# REVISIT Covers Polish border, may want to add/remove some states',
                'add_state_claim = 89',
                'add_state_claim = 91',
                'add_state_claim = 93',
                'add_state_claim = 94',
                'add_state_claim = 95',
                'add_state_claim = 935',
                'add_state_claim = 936',
                'add_state_claim = 784',
                'add_state_claim = 96',
                'add_named_threat = { threat = 1 name = SOV_claims_on_poland }'
            )
            New = @(
                '# hof: 波兰 13 州 + 喀尔巴阡鲁塞尼亚 73 / 乌日霍罗德 996',
                'add_state_core = 10',
                'add_state_core = 88',
                'add_state_core = 89',
                'add_state_core = 90',
                'add_state_core = 91',
                'add_state_core = 92',
                'add_state_core = 93',
                'add_state_core = 94',
                'add_state_core = 95',
                'add_state_core = 96',
                'add_state_core = 784',
                'add_state_core = 935',
                'add_state_core = 936',
                'add_state_core = 73',
                'add_state_core = 996',
                'add_named_threat = { threat = 1 name = SOV_claims_on_poland }'
            )
        }

        @{
            Name = '声索黑海出海口：仅沿岸七州核心'
            # 原：只宣称海峡沿岸 5 州（341/347/340/339/797）
            # 新：这 5 州 + 安塔利亚、特拉布宗 = 7 州
            Old = @(
                'add_state_claim = 341',
                'add_state_claim = 347',
                'add_state_claim = 340',
                'add_state_claim = 339',
                'add_state_claim = 797',
                'add_named_threat = { threat = 2 name = SOV_claim_on_the_straits }'
            )
            New = @(
                '# hof: 海峡与黑海沿岸七州核心；其余土耳其州由沙特统御安纳托利亚取得',
                'add_state_core = 341',
                'add_state_core = 347',
                'add_state_core = 340',
                'add_state_core = 339',
                'add_state_core = 797',
                'add_state_core = 342',
                'add_state_core = 354',
                'add_named_threat = { threat = 2 name = SOV_claim_on_the_straits }'
            )
        }

        @{
            Name = '对希腊的最后通牒：宣称 → 核心'
            Old = @(
                'add_named_threat = { threat = 1 name = SOV_ultimatum_to_greece_t }',
                'add_state_claim = 187'
            )
            New = @(
                'add_named_threat = { threat = 1 name = SOV_ultimatum_to_greece_t }',
                '# hof: 爱琴群岛、十二群岛、克里特与塞浦路斯核心',
                'add_state_core = 187',
                'add_state_core = 164',
                'add_state_core = 182',
                'add_state_core = 183'
            )
        }

        @{
            Name = '进入高原：不丹 / 尼泊尔由宣称改为核心（西藏不动）'
            Old = @(
                'add_named_threat = { threat = 1 name = SOV_into_the_plateau_t }',
                'add_state_claim = 322',
                'add_state_claim = 758',
                'add_state_claim = 757',
                'add_state_claim = 601',
                'add_state_claim = 324',
                'add_state_claim = 323',
                'add_state_claim = 1091'
            )
            New = @(
                'add_named_threat = { threat = 1 name = SOV_into_the_plateau_t }',
                '# hof: 西藏 322/758/757/601 保持宣称；不丹 324 · 尼泊尔 323/1091 改为核心',
                'add_state_claim = 322',
                'add_state_claim = 758',
                'add_state_claim = 757',
                'add_state_claim = 601',
                'add_state_core = 324',
                'add_state_core = 323',
                'add_state_core = 1091'
            )
        }

        @{
            Name = '保障列宁格勒安全：只宣称 146 → 芬兰全境 13 州核心'
            # 原：`add_state_claim = 146 # Karjala`（只宣称卡累利阿）
            # 🔄 2026-09-25 用户口径：「保障列宁格勒安全的效杲新增芬兰全境的核心」
            # ⇒ 146 本来就在「全境」里，所以这一条直接换成一整组 add_state_core，
            #    不再保留那条单独宣称（否则工具提示里会同时出现宣称 + 核心两行）。
            # 州表 = R56 里 owner ∩ add_core_of = FIN 的 13 州。
            Old = @(
                'custom_effect_tooltip = SOV_focus_complete_effect_tt',
                'add_state_claim = 146 # Karjala'
            )
            New = @(
                'custom_effect_tooltip = SOV_focus_complete_effect_tt',
                '# hof: 芬兰全境 13 州核心（新地 111 / 奥兰 145 / 卡累利阿 146 / 萨拉 147 /',
                '#      拉皮 148 / 博腾 149 / 萨沃 150 / 佩察莫 722 / 图尔库 1036 /',
                '#      海梅 1037 / 库米 1038 / 奥卢 1039 / 米凯利 1040）',
                'add_state_core = 111',
                'add_state_core = 145',
                'add_state_core = 146',
                'add_state_core = 147',
                'add_state_core = 148',
                'add_state_core = 149',
                'add_state_core = 150',
                'add_state_core = 722',
                'add_state_core = 1036',
                'add_state_core = 1037',
                'add_state_core = 1038',
                'add_state_core = 1039',
                'add_state_core = 1040'
            )
        }
    )
}

# --- 取消国策互斥：按 id 删掉 `mutually_exclusive = { focus = X }` 整行 ----------
# 用户 2026-09-25 口径：「取消以下几组互斥 —— 本国专家和外国专家 / 英雄主义宣传和集体主义宣传 /
#   集体安全政策和单独安全政策 / 红军的缔造者和赓续革命精神 / 恢复哥萨克部队和团结第一」
# ⚠️ 互斥在原版 / R56 里是【两个方向各声明一次】，所以每一对都要把【两边】都删掉（共 10 行）。
# ⚠️ soviet.txt 每次从 R56 重生成 ⇒ 只能在这里打补丁，手工改会被下次同步覆盖。
# 📌 这张表动的是【原版国策之间的互斥】，与本 mod 自己的「席位互斥矩阵」（docs/10 §2.4.2）无关。
$MutexRemovalMap = @{
    'sia_std' = @(
        'SIA_thai_rice_company'
        'SIA_the_bank_of_siam'
    )
    'hun_wuw' = @(
        'wuw_HUN_expand_the_army'
        'wuw_HUN_quantity_over_quality'
    )
    'prc_sino' = @(
        'PRC_urbanization'
        'PRC_rural_region_development'
        'PRC_one_with_the_people'
        'PRC_best_of_the_best'
    )
    'ger_economy_mutex' = @(
        # 四年计划 ↔ 经济增长优先；两条都要删除
        'GER_the_four_year_plan'
        'GER_prioritize_economic_growth'
        # 普鲁士的遗产 ↔ 采纳新的装甲学说
        'GER_the_prussian_legacy'
        'GER_adopt_new_panzer_doctrine'
    )
    'sov_core' = @(
        # ① 本国专家 ↔ 外国专家
        'SOV_national_specialists'
        'SOV_foreign_experts'
        # ② 英雄主义宣传 ↔ 集体主义宣传
        'SOV_positive_heroism'
        'SOV_collectivist_propaganda'
        # ③ 集体安全政策 ↔ 单独安全政策
        'SOV_policy_of_collective_security'
        'SOV_policy_of_individual_security'
        # ④ 红军的缔造者 ↔ 赓续革命精神
        'SOV_the_builder_of_the_red_army'
        'SOV_reigniting_the_revolutionary_spirit'
        # ⑤ 恢复哥萨克部队 ↔ 团结第一
        'SOV_restore_cossack_units'
        'SOV_cohesion_first'
        # ⑥ 莫洛托夫防线 ↔ 巩固斯大林防线
        'SOV_the_molotov_line'
        'SOV_improve_the_stalin_line'
    )
}
# 德国空军三选一使用单行双目标声明；每个拥有者的整条互斥声明都要删除。
$MutexGroupRemovalMap = @{
    'prc_sino' = @(
        @{ Owner = 'PRC_asymmetric_warfare'; Targets = @('PRC_conventional_warfare', 'PRC_indirect_fire') }
        @{ Owner = 'PRC_conventional_warfare'; Targets = @('PRC_asymmetric_warfare', 'PRC_indirect_fire') }
        @{ Owner = 'PRC_indirect_fire'; Targets = @('PRC_asymmetric_warfare', 'PRC_conventional_warfare') }
    )
    'ger_economy_mutex' = @(
        @{ Owner = 'GER_dive_bombers'; Targets = @('GER_tactical_bombers', 'GER_uralbomber_program') }
        @{ Owner = 'GER_tactical_bombers'; Targets = @('GER_dive_bombers', 'GER_uralbomber_program') }
        @{ Owner = 'GER_uralbomber_program'; Targets = @('GER_dive_bombers', 'GER_tactical_bombers') }
    )
}
# 🔄 2026-09-24 起【废弃】$FocusPatchHost（写死一个文件）—— $FocusPatchMap 自己按挂载点 id 分层。

# --- 需求 B：中苏联合国策 —— ⛔ 2026-09-24 用户口径「取消中苏联合国策树」--------
# 原本这里从 common/national_focus/hof_sino_joint.txt 解析出 joint_focus id 并生成
# $hofSinoSharedFocusLines，然后注入 sov_core 与 prc_sino 两个挂载点。
# 现在整条需求 B 作废：
#   · 文件 common/national_focus/hof_sino_joint.txt         已删除
#   · 文件 common/scripted_triggers/hof_sino_scripted_triggers.txt  已删除
#   · 文件 localisation/simp_chinese/hof_sino_l_simp_chinese.yml    已删除
#   · $InjectMap 里的 prc_sino 条目整条移除（它原本【只】为需求 B 存在）
#   · verify-s2.ps1 §10 由「正向断言」改为「取消后残留检测」（负向断言）
# ⚠️ attach-points.json 里的 prc_sino 条目【保留】—— S5 经互会通用线仍要靠它
#    把 shared_focus = hof_ma_founding 挂进 PRC 那棵树（同步脚本会自动补空数组）。
# 记录：docs/19-s4-sino-soviet-joint-focus.md（已标作废）、AGENTS.md、docs/99。

# --- 需求 C：经互会通用线（S5）的 shared_focus 注入行 ---------------------
# 同样是【由生成器产出】而不是在这里手抄：build/gen-hof-ma-common-lines.ps1 写出
# build/inject-ma.txt（只有一行 shared_focus = <头 id>）。
# ⚠️ 只列【头】：官方 wiki 说 shared_focus = <头 id> 会把它【以及所有通过
#    prerequisite 连到它的 shared focus】一起加进树里 —— 原版 nordic_shared.txt 就这么做。
$hofMaInjectPath = Join-Path (Split-Path -Parent $ListPath) 'inject-ma.txt'
if (-not (Test-Path $hofMaInjectPath)) {
    throw "缺少经互会通用线注入文件：`n  $hofMaInjectPath`n请先运行 build/gen-hof-ma-common-lines.ps1 生成它。"
}
$hofMaInjectLines = @(Get-Content -LiteralPath $hofMaInjectPath -Encoding UTF8)
Write-Output ("经互会通用线：注入 {0} 行（定义见 common/national_focus/hof_ma_joint.txt）" -f $hofMaInjectLines.Count)

# --- 注入内容 -------------------------------------------------------------
# 键 = 挂载点 id（见 attach-points.json），值 = 要插入的完整脚本行数组。
# 这些行会被插到该挂载点的锚点行（id = <treeId>）之后，并用
#     # hof:begin <id>   /   # hof:end <id>
# 包裹，便于识别与幂等替换。行内缩进可自由书写，脚本会再带上锚点行本身的缩进。
$InjectMap = @{

    # 需求 A：核心圈 inlay window 挂进苏联国策树
    #
    # ---- position 怎么定的（重要，改之前先读）----
    # 尺度：约 100~140 像素 / 国策格。依据两条：
    #   ① 捷克 inlay window 里原作者的注释 `#y = ~2.5`（对应 y = 350）→ ~140 px/格
    #   ② 苏联树自己的 continuous_focus_position 是 (55, 1500)，连续国策栏惯例
    #      摆在树正下方，而树的 Y 最大为 15 格 → 1500/15 = 100 px/格
    # 树的实际范围（已解析出绝对坐标）：X -11..81，Y 0..15 格
    #   → 树底大约在 y = 1500 ~ 2100 像素之间
    # 因此把 y 放到 2200（超出两种尺度的树底）即可完全避开国策树。
    #
    # ⚠️ 想微调位置的最快办法：直接改 mod 里 common/national_focus/soviet.txt
    #    中 `# hof:begin sov_core` 块里的 position 行，用 -debug 热重载即时看效果。
    #    调好后把数值告诉我，我改回这里，否则下次跑同步会被覆盖。
    #
    # ⚠️ 缩进必须用【真制表符】。PowerShell 单引号字符串【不】解释转义，
    #    写 '\t' 会变成字面的反斜杠+t，注进文件后就是语法垃圾。
    #    因此下面用双引号 + 反引号转义 "`t"。
    'sov_core' = @(
        'inlay_window = {'
        "`tid = hof_ic_inlay_window"
        "`tposition = { x = 3700 y = 2200 }"
        '}'
        ''
    ) + $hofIcSeatInjectLines

    # ⛔ prc_sino：2026-09-24 取消需求 B 后，这个挂载点【没有任何专属注入】了。
    #    它的注入内容 = 上面那个 foreach 循环统一加的 S5 经互会通用线（$hofMaInjectLines）。
    #    所以这里【不再写 prc_sino 键】—— 同步脚本的
    #        if (-not $InjectMap.ContainsKey($p.id)) { $InjectMap[$p.id] = @() }
    #    会自动为它建空表，再把 S5 的行加进去。
    #    ⚠️ 不要在 attach-points.json 里删 prc_sino —— S5 还挂在 PRC 那棵树上。
}

# --- 额外覆盖文件（非国策树）的决议块注入 -----------------------------------
# 来源：build/inject-dec-gos.txt（由 build/gen-hof-gos-chain.py 生成）。
# 格式：每块用 `# hof:dec-begin <decision id>` / `# hof:dec-end <decision id>` 包裹，
#       块内第一行就是 `<id> = {`、最后一行是收尾的 `}`（缩进已按目标文件写好）。
# ⚠️ 本脚本【不】手抄决议内容 —— 内容全部在生成器里（单一出处）。
$decGosPath = Join-Path (Split-Path -Parent $ListPath) 'inject-dec-gos.txt'
$DecisionBlockMap = @{}
if (Test-Path $decGosPath) {
    $decRaw = [System.IO.File]::ReadAllText($decGosPath)
    $decRx = '(?ms)^# hof:dec-begin (?<id>\S+)[ \t]*\r?\n(?<body>.*?)^# hof:dec-end (?<id2>\S+)[ \t]*\r?\n'
    foreach ($m in [regex]::Matches($decRaw, $decRx)) {
        $bid  = $m.Groups['id'].Value
        $bid2 = $m.Groups['id2'].Value
        if ($bid -ne $bid2) { throw "inject-dec-gos.txt 标记不配对：$bid / $bid2" }
        $body = $m.Groups['body'].Value -replace "\r?\n$", ''
        $DecisionBlockMap[$bid] = @($body -split "\r?\n")
    }
    Write-Output ('决议块注入：读入 ' + $DecisionBlockMap.Count + ' 个块（inject-dec-gos.txt）')
} else {
    Write-Output '决议块注入：未找到 inject-dec-gos.txt（跳过）—— 请先运行 build/gen-hof-gos-chain.py'
}

# --- 工具函数 -------------------------------------------------------------

function Get-TextInfo([string]$text) {
    $eol = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    return $eol
}

# 在 focus_tree 块内定位 `id = <treeId>` 那一行，返回匹配数与行文本
function Find-Anchor([string]$text, [string]$treeId) {
    $pattern = '(?m)^[ \t]*id[ \t]*=[ \t]*' + [regex]::Escape($treeId) + '[ \t]*\r?$'
    $ms = [regex]::Matches($text, $pattern)
    return $ms
}

# 相对坐标引用要求目标国策先于引用者声明。返回指定 focus 整块闭括号后的位置。
function Find-FocusBlockEnd([string]$text, [string]$focusId) {
    $pattern = '(?m)^[ \t]*focus[ \t]*=[ \t]*\{[ \t]*\r?\n[ \t]*id[ \t]*=[ \t]*' + [regex]::Escape($focusId) + '[ \t]*\r?$'
    $hits = [regex]::Matches($text, $pattern)
    if ($hits.Count -ne 1) { throw "定位 $focusId 失败：匹配 $($hits.Count) 次（应为 1）" }
    $open = $text.IndexOf('{', $hits[0].Index)
    $depth = 0
    $inComment = $false
    $inQuote = $false
    for ($i = $open; $i -lt $text.Length; $i++) {
        $ch = $text[$i]
        if ($ch -eq "`n") { $inComment = $false; continue }
        if ($inComment) { continue }
        if ($ch -eq '#') { if (-not $inQuote) { $inComment = $true }; continue }
        if ($ch -eq '"') { $inQuote = -not $inQuote; continue }
        if ($inQuote) { continue }
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') {
            $depth--
            if ($depth -eq 0) { return $i + 1 }
        }
    }
    throw "定位 $focusId 失败：花括号未闭合"
}

function Convert-BessarabiaClaimsToCores([string]$text, [string]$eol) {
    $focusId = 'SOV_claim_on_bessarabia'
    $rx = '(?m)^[ \t]*focus[ \t]*=[ \t]*\{[ \t]*\r?\n[ \t]*id[ \t]*=[ \t]*' + $focusId + '[ \t]*\r?$'
    $m = [regex]::Match($text, $rx)
    if (-not $m.Success) { throw "找不到 $focusId 的国策块" }
    $end = Find-FocusBlockEnd $text $focusId
    $block = $text.Substring($m.Index, $end - $m.Index)
    $count = ([regex]::Matches($block, 'add_claim_by[ \t]*=[ \t]*ROOT')).Count
    if ($count -ne 2) { throw "$focusId 应有两处宣称（完成与绕过），实际 $count" }
    $block = [regex]::Replace($block, 'add_claim_by[ \t]*=[ \t]*ROOT', 'add_core_of = ROOT')
    $bypass = 'bypass_effect = {'
    if (([regex]::Matches($block, [regex]::Escape($bypass))).Count -ne 1) { throw "$focusId 的 bypass_effect 未唯一定位" }
    $block = $block.Replace($bypass, $bypass + $eol + "`t`t`t79 = { add_core_of = ROOT } # hof: 摩尔多瓦核心")
    return $text.Remove($m.Index, $end - $m.Index).Insert($m.Index, $block)
}

# ---------------------------------------------------------------------------
# 往某个【已存在的国策】的 completion_reward 里插行
#
# ⚠️ 两个锚点都必须唯一，不唯一就直接 throw。
#    宁可直接报错退出，也不能“静默插错位置”——后者在游戏里只表现为
#    “精神不出现”，看不到任何报错，极难排查。
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# 值补丁：按「整块字面替换」改 R56 源文件里的数值
#
# ⚠️ Old 里每行只写【去掉缩进后的内容】；匹配时行首任意缩进、行间任意空白。
#    必须恰好命中 1 次，否则 throw。
# ---------------------------------------------------------------------------
function Update-ValuePatches {
    param([string]$Text, [string]$Eol, [array]$List)

    $n = 0
    foreach ($vp in $List) {
        $parts = @($vp.Old | ForEach-Object { [regex]::Escape($_.Trim()) })
        $rx = '(?m)^[ \t]*' + ($parts -join '\s*')
        $ms = [regex]::Matches($Text, $rx)
        if ($ms.Count -ne 1) {
            throw "值补丁失败：$($vp.Name) 命中 $($ms.Count) 次（应为 1）"
        }
        $indent = ([regex]::Match($ms[0].Value, '^[ \t]*')).Value
        $rep = (@($vp.New) | ForEach-Object { if ($_ -eq '') { $indent } else { $indent + $_ } }) -join $Eol
        $Text = $Text.Remove($ms[0].Index, $ms[0].Length).Insert($ms[0].Index, $rep)
        $n++
    }
    return [pscustomobject]@{ Text = $Text; Patched = $n }
}

# ---------------------------------------------------------------------------
# 取消国策互斥：删掉 `mutually_exclusive = { focus = <id> }` 这一整行
#
# ⚠️ 只删【单行单目标】的那种写法（原版 / R56 的苏联树里这 10 处全是这种）。
#    若某处写成多目标块，这里【不会命中】→ throw，避免静默漏删。
# ⚠️ 命中数必须恰好 1，同 Update-ValuePatches 的纪律：宁可报错也不静默改错位置。
# ---------------------------------------------------------------------------
function Remove-MutexLines {
    param([string]$Text, [array]$Ids)

    $n = 0
    foreach ($fid in $Ids) {
        $rx = '(?m)^[ \t]*mutually_exclusive[ \t]*=[ \t]*\{[ \t]*focus[ \t]*=[ \t]*' +
              [regex]::Escape($fid) + '[ \t]*\}[ \t]*(\r?\n|$)'
        $ms = [regex]::Matches($Text, $rx)
        if ($ms.Count -ne 1) {
            throw "取消互斥失败：$fid 命中 $($ms.Count) 次（应为 1）"
        }
        $Text = $Text.Remove($ms[0].Index, $ms[0].Length)
        $n++
    }
    return [pscustomobject]@{ Text = $Text; Removed = $n }
}

# 删除指定国策自己的多目标互斥声明，逐个核对拥有者、目标和命中数。
function Remove-MutexGroupLines {
    param([string]$Text, [array]$Groups)

    $n = 0
    foreach ($group in $Groups) {
        $owner = [string]$group.Owner
        $end = Find-FocusBlockEnd $Text $owner
        $idRx = '(?m)^[ \t]*id[ \t]*=[ \t]*' + [regex]::Escape($owner) + '[ \t]*\r?$'
        $idHits = [regex]::Matches($Text, $idRx)
        if ($idHits.Count -ne 1 -or $idHits[0].Index -ge $end) {
            throw "取消多目标互斥失败：$owner 的 id 未唯一定位到国策块"
        }
        $start = $idHits[0].Index
        $block = $Text.Substring($start, $end - $start)
        $targets = @($group.Targets | ForEach-Object { 'focus[ \t]*=[ \t]*' + [regex]::Escape($_) }) -join '[ \t]+'
        $rx = '(?m)^[ \t]*mutually_exclusive[ \t]*=[ \t]*\{[ \t]*' + $targets + '[ \t]*\}[ \t]*(\r?\n|$)'
        $hits = [regex]::Matches($block, $rx)
        if ($hits.Count -ne 1) {
            throw "取消多目标互斥失败：$owner 的目标行命中 $($hits.Count) 次（应为 1）"
        }
        $Text = $Text.Remove($start + $hits[0].Index, $hits[0].Length)
        $n++
    }
    return [pscustomobject]@{ Text = $Text; Removed = $n }
}

# ---------------------------------------------------------------------------
# 按 decision id 把【整个块】替换掉（额外覆盖文件用；不做锚点注入）
#
# ⚠️ 定位 = `<缩进><id> = {` 行，必须恰好命中 1 次；块尾用花括号配平扫描。
#    与 $ValuePatchMap 的分工：那个是「逐行字面替换」，这个按 id 认整块，
#    适合整块重写（内容由生成器产出，见 build/inject-dec-gos.txt）。
# ---------------------------------------------------------------------------
function Set-DecisionBlock {
    param([string]$Text, [string]$Eol, [string]$Id, [array]$Lines)

    $pat = '(?m)^([ \t]*)' + [regex]::Escape($Id) + '[ \t]*=[ \t]*\{[ \t]*\r?$'
    $ms = [regex]::Matches($Text, $pat)
    if ($ms.Count -ne 1) { throw "决议块替换失败：$Id 的 id 行命中 $($ms.Count) 次（应为 1）" }

    $open = $Text.IndexOf('{', $ms[0].Index)
    if ($open -lt 0) { throw "决议块替换失败：$Id 找不到起始花括号" }
    $depth = 0
    $end = -1
    for ($k = $open; $k -lt $Text.Length; $k++) {
        $ch = $Text[$k]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') { $depth--; if ($depth -eq 0) { $end = $k; break } }
    }
    if ($end -lt 0) { throw "决议块替换失败：$Id 花括号配平失败" }

    $rep = ($Lines -join $Eol)
    return $Text.Remove($ms[0].Index, $end - $ms[0].Index + 1).Insert($ms[0].Index, $rep)
}

function Add-FocusPatches {
    param([string]$Text, [string]$Eol, [hashtable]$Map)

    $patched = 0
    foreach ($fid in $Map.Keys) {
        $lines = @($Map[$fid])
        $beginMark = '# hof:focus-begin ' + $fid
        $endMark   = '# hof:focus-end ' + $fid

        # 幂等安全网：已存在就先把旧块整体删掉
        if ($Text.Contains($beginMark)) {
            $rx = [regex]::Escape($beginMark) + '.*?' + [regex]::Escape($endMark)
            $Text = [regex]::Replace($Text, $rx, '', 'Singleline')
        }

        # 1) 找该国策的 id 行，必须恰好 1 次
        $idPat = '(?m)^([ \t]*)id[ \t]*=[ \t]*' + [regex]::Escape($fid) + '[ \t]*\r?$'
        $idMs = [regex]::Matches($Text, $idPat)
        if ($idMs.Count -ne 1) {
            throw "国策内插行失败：$fid 的 id 行命中 $($idMs.Count) 次（应为 1）"
        }

        # 2) 只在该国策块内找 completion_reward；原版有时在 { 后同行写注释。
        $afterId = $idMs[0].Index + $idMs[0].Length
        $focusEnd = Find-FocusBlockEnd $Text $fid
        $rest = $Text.Substring($afterId, $focusEnd - $afterId)
        $crPat = '(?m)^([ \t]*)completion_reward[ \t]*=[ \t]*\{[^\r\n]*\r?$'
        $crMs = [regex]::Matches($rest, $crPat)
        if ($crMs.Count -lt 1) {
            throw "国策内插行失败：$fid 找不到 completion_reward = {"
        }

        # 3) 插在 `{` 之后，缩进比 completion_reward 那一行多一级
        $cr = $crMs[0]
        $indent = $cr.Groups[1].Value + "`t"
        $insAt = $afterId + $cr.Index + $cr.Length
        $block = @($beginMark) + $lines + @($endMark)
        $insText = ($block | ForEach-Object { $indent + $_ }) -join $Eol
        $Text = $Text.Insert($insAt, $Eol + $insText)
        $patched++
    }

    return @{ Text = $Text; Patched = $patched }
}

# R56 的西南勘探国策在 available 中检查 617/618，却误把完成奖励给 817/820。
# 只在该国策块内纠正四处州 id；命中数变化时停止同步，避免误改别的蒙古国策。
function Fix-MongoliaSouthwestTargets([string]$Text) {
    $focusId = 'MON_southwest_resource_prospection_area'
    $rx = '(?m)^[ \t]*focus[ \t]*=[ \t]*\{[ \t]*\r?\n[ \t]*id[ \t]*=[ \t]*' + $focusId + '[ \t]*\r?$'
    $hits = [regex]::Matches($Text, $rx)
    if ($hits.Count -ne 1) { throw "蒙古西南勘探国策定位失败：命中 $($hits.Count) 次" }
    $start = $hits[0].Index
    $end = Find-FocusBlockEnd $Text $focusId
    $block = $Text.Substring($start, $end - $start)
    foreach ($pair in @(@('820', '618'), @('817', '617'))) {
        $idRx = '(?<!\d)' + $pair[0] + '(?!\d)'
        $count = ([regex]::Matches($block, $idRx)).Count
        if ($count -ne 2) { throw "蒙古西南勘探国策目标州 $($pair[0]) 命中 $count 次（应为 2）" }
        $block = [regex]::Replace($block, $idRx, $pair[1])
    }
    return $Text.Remove($start, $end - $start).Insert($start, $block)
}

# --- 主流程 ---------------------------------------------------------------

$parsedList = Get-Content -LiteralPath $ListPath -Raw -Encoding UTF8 | ConvertFrom-Json
$points = $parsedList.points
# extraFiles = 【非国策树】的整文件覆盖清单（首例 = common/decisions/SOV.txt，见 docs/102）。
# ⚠️ 单独一个键，不动 points 的既有语义（verify-s2 §13 / verify-sync.ps1 都只读 points）。
$extraPoints = $parsedList.extraFiles
$selected = $points | Where-Object { $_.phase -le $MaxPhase }

# --- 需求 C：把经互会通用线的注入行并进【每一个】相位 1 挂载点 -------------
# 不要再手抄一份 21 个 id 的名单 —— 名单长在 attach-points.json 里（单一出处）。
# 头节点带 21 条 offset（判据 = has_focus_tree），不在这份名单里的国家也照常能挂，
# 只是落回保险基准 (x = 0, y = 24)，压不到任何一棵树。
# ⚠️ 2026-09-25：带 `"s5": false` 的挂载点【不】注入 —— 它只是「为了改内容而覆盖」的树
#    （首例 = 洪都拉斯 hon_std：我们没有把它拉进经互会）。
#    ⭐ 用【黑名单】而不是白名单：将来加点不会因为忘改名单而漏注 S5。
#    （$p.s5 在 JSON 里没写时为 $null，`$null -eq $false` 为 False ⇒ 照旧注入）
$s5Skipped = @()
foreach ($p in $selected) {
    if ($p.s5 -eq $false) { $s5Skipped += $p.id; continue }
    if (-not $InjectMap.ContainsKey($p.id)) { $InjectMap[$p.id] = @() }
    $InjectMap[$p.id] = @($InjectMap[$p.id]) + $hofMaInjectLines
}
Write-Output ("经互会通用线：已并入 {0} 个挂载点的注入表（{1} 个带 s5:false 跳过{2}）" -f ($selected.Count - $s5Skipped.Count), $s5Skipped.Count, $(if ($s5Skipped.Count) { '：' + ($s5Skipped -join ',') } else { '' }))

Write-Output "同步清单: $ListPath"
Write-Output ("目标 mod : " + $ModRoot)
Write-Output ("R56 根   : " + $R56Root)
Write-Output ("选取相位 : <= " + $MaxPhase + "   （共 " + $selected.Count + " / " + $points.Count + " 个挂载点）")
Write-Output ("模式     : " + $(if ($VerifyOnly) { '仅校验（不写文件）' } else { '实际同步' }))
Write-Output ""
Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f 'ID', 'TAG', '源文件', '树ID', '结果')
Write-Output ('-' * 130)

$okCount = 0
$failCount = 0
$totalLines = 0

foreach ($p in $selected) {
    $src = Join-Path $R56Root ($p.srcRelativePath -replace '/', '\')
    $status = ''

    if (-not (Test-Path $src)) {
        $status = '✗ 源文件缺失'
        $failCount++
        Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f $p.id, $p.tag, $p.srcRelativePath, $p.treeId, $status)
        continue
    }

    $text = [System.IO.File]::ReadAllText($src)
    $eol = Get-TextInfo $text
    $lineCount = ($text -split "`r?`n").Count

    # 1) 锚点校验：必须恰好命中 1 次，否则不写（防止注错位置）
    $ms = Find-Anchor $text $p.treeId
    if ($ms.Count -ne 1) {
        $status = ('✗ 锚点命中 {0} 次（应为 1）' -f $ms.Count)
        $failCount++
        Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f $p.id, $p.tag, $p.srcRelativePath, $p.treeId, $status)
        continue
    }

    # 2) 注入（如该挂载点配了注入项）
    $injected = 0
    $injectList = @()
    if ($InjectMap.ContainsKey($p.id)) { $injectList = $InjectMap[$p.id] }

    if ($injectList.Count -gt 0) {
        $beginMark = '# hof:begin ' + $p.id
        $endMark = '# hof:end ' + $p.id
        # injectList 里存的是完整脚本行（不再自动接 shared_focus 前缀），
        # 因此可以注入任意结构，例如 inlay_window 声明块。
        $block = @($beginMark) + $injectList + @($endMark)

        if ($text.Contains($beginMark)) {
            # 已存在 → 整块替换。注意：本脚本每次都从 R56 源头重生成，
            # 正常路径走不到这里；此分支仅作安全网（例如手工改过目标文件后重跑）。
            $rx = [regex]::Escape($beginMark) + '.*?' + [regex]::Escape($endMark)
            $text = [regex]::Replace($text, $rx, ($block -join $eol), 'Singleline')
        } else {
            # 插到锚点行之后，并沿用锚点行的缩进以保持文件风格一致
            # （HOI4 不关心空白，这只是为了让 diff 干净）
            $anchorRaw = $ms[0].Value
            $indent = ([regex]::Match($anchorRaw, '^[ \t]*')).Value
            $anchorLine = $anchorRaw.TrimEnd()
            $indented = ($block | ForEach-Object { $indent + $_ }) -join $eol
            if ($p.id -eq 'sov_core') {
                $afterSupremeSoviet = Find-FocusBlockEnd $text 'SOV_the_supreme_soviet'
                $text = $text.Insert($afterSupremeSoviet, $eol + $indented)
            } else {
                $text = $text.Remove($ms[0].Index, $ms[0].Length).Insert($ms[0].Index, $anchorLine + $eol + $indented)
            }
        }
        $injected = $injectList.Count
    }

    # 2b) 国策内插行补丁（按挂载点分层：sov_core -> soviet.txt；ast_std -> australia_taog.txt）
    $patched = 0
    if ($FocusPatchMap.ContainsKey($p.id) -and $FocusPatchMap[$p.id].Count -gt 0) {
        $res = Add-FocusPatches -Text $text -Eol $eol -Map $FocusPatchMap[$p.id]
        $text = $res.Text
        $patched = $res.Patched
    }
    if ($p.id -eq 'mon_mutual') {
        $text = Fix-MongoliaSouthwestTargets $text
    }

    # 2c) 值补丁（整块字面替换；R56 重生成会覆盖手工改，所以写在这里）
    $valuePatched = 0
    if ($ValuePatchMap.ContainsKey($p.id) -and $ValuePatchMap[$p.id].Count -gt 0) {
        $res2 = Update-ValuePatches -Text $text -Eol $eol -List $ValuePatchMap[$p.id]
        $text = $res2.Text
        $valuePatched = $res2.Patched
    }
    if ($p.id -eq 'sov_core') {
        $text = Convert-BessarabiaClaimsToCores $text $eol
    }

    # 2d) 取消国策互斥（删 `mutually_exclusive = { focus = X }` 整行）
    $mutexRemoved = 0
    if ($MutexRemovalMap.ContainsKey($p.id) -and $MutexRemovalMap[$p.id].Count -gt 0) {
        $res3 = Remove-MutexLines -Text $text -Ids $MutexRemovalMap[$p.id]
        $text = $res3.Text
        $mutexRemoved = $res3.Removed
    }
    if ($MutexGroupRemovalMap.ContainsKey($p.id) -and $MutexGroupRemovalMap[$p.id].Count -gt 0) {
        $res4 = Remove-MutexGroupLines -Text $text -Groups $MutexGroupRemovalMap[$p.id]
        $text = $res4.Text
        $mutexRemoved += $res4.Removed
    }

    # 3) 落盘（UTF-8 无 BOM）
    $dst = Join-Path $ModRoot ($p.srcRelativePath -replace '/', '\')
    $dstDir = Split-Path $dst -Parent
    if (-not $VerifyOnly) {
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        [System.IO.File]::WriteAllText($dst, $text, (New-Object System.Text.UTF8Encoding($false)))
    }

    $status = ('✓ 锚点唯一 / {0} 行 / 行尾 {1} / 注入 {2} / 内插 {3} / 值补丁 {4} / 删互斥 {5}' -f $lineCount, ($eol -replace "`r", '\r' -replace "`n", '\n'), $injected, $patched, $valuePatched, $mutexRemoved)
    $okCount++
    $totalLines += $lineCount
    Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f $p.id, $p.tag, $p.srcRelativePath, $p.treeId, $status)
}

# --- 额外覆盖文件（非国策树）----------------------------------------------
# 只做两件事：① 整文件覆盖；② 按 inject-dec-gos.txt 替换指定 decision 块。
# ⛔ 不做锚点注入（没有 treeId）、不参与经互会通用线（S5）。
$extraSelected = @()
if ($null -ne $extraPoints) { $extraSelected = @($extraPoints | Where-Object { $_.phase -le $MaxPhase }) }
if ($extraSelected.Count -gt 0) {
    Write-Output ''
    Write-Output ("额外覆盖文件（非国策树）：{0} 个" -f $extraSelected.Count)
    foreach ($p in $extraSelected) {
        $src = Join-Path $R56Root ($p.srcRelativePath -replace '/', '\')
        if (-not (Test-Path $src)) {
            Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f $p.id, $p.tag, $p.srcRelativePath, '-', '✗ 源文件缺失')
            $failCount++
            continue
        }
        $text = [System.IO.File]::ReadAllText($src)
        $eol = Get-TextInfo $text
        $lineCount = ($text -split "`r?`n").Count
        $srcDelta = ([regex]::Matches($text, '\{')).Count - ([regex]::Matches($text, '\}')).Count
        $blocks = 0
        if ($p.id -eq 'dec_sov') {
            foreach ($bid in @($DecisionBlockMap.Keys)) {
                $text = Set-DecisionBlock -Text $text -Eol $eol -Id $bid -Lines $DecisionBlockMap[$bid]
                $blocks++
            }
        }
        if ($ValuePatchMap.ContainsKey($p.id) -and $ValuePatchMap[$p.id].Count -gt 0) {
            $resExtra = Update-ValuePatches -Text $text -Eol $eol -List $ValuePatchMap[$p.id]
            $text = $resExtra.Text
            $blocks += $resExtra.Patched
        }
        # 花括号【差值】自检：替换前后差值的改变必须是 0，否则 throw（绝不写出坏文件）
        # ⚠️ 不能用「{ 数 == } 数」—— R56/原版这些文件里【注释掉的代码块】带花括号，
        #    源文件本身就不平（实测 decisions/SOV.txt = 5913 / 5912）。所以只比较【差值】。
        $d0 = $srcDelta
        $d1 = ([regex]::Matches($text, '\{')).Count - ([regex]::Matches($text, '\}')).Count
        if ($d1 -ne $d0) { throw ("额外覆盖文件 {0} 花括号差值变了（{1} -> {2}）—— 已中止，未写文件" -f $p.id, $d0, $d1) }

        $dst = Join-Path $ModRoot ($p.srcRelativePath -replace '/', '\')
        $dstDir = Split-Path $dst -Parent
        if (-not $VerifyOnly) {
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            [System.IO.File]::WriteAllText($dst, $text, (New-Object System.Text.UTF8Encoding($false)))
        }
        $status = ('✓ 整文件覆盖 / {0} 行 / 行尾 {1} / 补丁块 {2}' -f $lineCount, ($eol -replace "`r", '\r' -replace "`n", '\n'), $blocks)
        $okCount++
        $totalLines += $lineCount
        Write-Output ("{0,-14} {1,-4} {2,-46} {3,-32} {4}" -f $p.id, $p.tag, $p.srcRelativePath, '-', $status)
    }
}

# 大坝需要 map/buildings.txt 中对应州、省份的 dam_spawn，否则地图上没有模型位置。
# 以 R56 完整文件为基底，保留它的全部建筑点，再加入两个位于河道上的坝址。
$mapRelative = 'map/buildings.txt'
$mapSource = Join-Path $R56Root ($mapRelative -replace '/', '\')
if (-not (Test-Path -LiteralPath $mapSource)) { throw "地图建筑点源文件缺失：$mapSource" }
$mapText = [System.IO.File]::ReadAllText($mapSource)
$mapEol = Get-TextInfo $mapText
foreach ($stateId in @(219, 570)) {
    if ([regex]::IsMatch($mapText, "(?m)^$stateId;dam_spawn;")) {
        throw "R56 已有州 $stateId 的大坝位置，请核对后更新本模组的坝址"
    }
}
$damSpawns = @(
    '219;dam_spawn;3390.00;9.90;1665.00;0.00;0',
    '570;dam_spawn;4074.00;10.40;1604.00;0.00;0'
)
if (-not $mapText.EndsWith("`n")) { $mapText += $mapEol }
$mapText += ($damSpawns -join $mapEol) + $mapEol
$mapDestination = Join-Path $ModRoot ($mapRelative -replace '/', '\')
if (-not $VerifyOnly) {
    $mapDirectory = Split-Path $mapDestination -Parent
    if (-not (Test-Path -LiteralPath $mapDirectory)) { New-Item -ItemType Directory -Path $mapDirectory -Force | Out-Null }
    [System.IO.File]::WriteAllText($mapDestination, $mapText, (New-Object System.Text.UTF8Encoding($false)))
}
$okCount++
$totalLines += ($mapText -split "`r?`n").Count
Write-Output ('map_dams       SOV  map/buildings.txt                              -                                ✓ R56 全文件覆盖 / 莫斯科与新西伯利亚大坝位置')

Write-Output ('-' * 130)
Write-Output ("成功 {0} / 失败 {1} / 合计 {2} 行" -f $okCount, $failCount, $totalLines)

if ($failCount -gt 0) {
    Write-Output ""
    Write-Output "⚠️ 有挂载点校验未通过，未写入。请检查 treeId 或源文件路径。"
    exit 1
}

if ($VerifyOnly) {
    Write-Output ""
    Write-Output "（仅校验模式，未修改任何文件）"
}
