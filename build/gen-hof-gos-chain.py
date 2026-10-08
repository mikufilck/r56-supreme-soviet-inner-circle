# -*- coding: utf-8 -*-
"""
gen-hof-gos-chain.py
===========================================================================
苏联「国家建筑设计局」（外国专家国策解锁的工业企业升级链）—— 生成器

用户 2026-09-25 口径：
  「写成 4+3 任选的样子，就是先选四个国家，四个国家任意顺序点完才能点三个专精，
    专精也是任意顺序」
  「不要加成国家精神，还是写新的modifier吧，改工业企业特质」

为什么必须【生成】而不是手写：
  HOI4 的 idea modifier 是【静态】的 —— 一个 idea = 一份写死的加成表。
  「任意顺序、每个都叠加」意味着「已完成的集合」有 2^4-1 + 2^3-1 = 15 + 7 = 22 种
  中间态，每一种都必须对应一个具体的 idea。⇒ 手写 22 个 idea（每个都要抄全量
  累积 modifier）不可能不出错，所以做成生成器。

产出（两个文件，都是 UTF-8 无 BOM + CRLF）：
  1. mod/heart_of_iron/common/ideas/hof_gos_chain.txt
     —— 23 个 idea：基础 1 + 阶段 1（4 国组合态 15）+ 阶段 2（专精组合态 7）
        ⚠️ 基础 idea SOV_gosproyektstroy_1 也从 ideas/SOV.txt 【搬到这里】，
           因此 ideas/SOV.txt 里原版那 17 个 gosproyektstroy idea 已全部删除。
  2. build/inject-dec-gos.txt
     —— 4 个决议块的替换文本（带 # hof:dec-begin/end 标记），
        由 build/sync-from-r56.ps1 用来替换 common/decisions/SOV.txt 里的同名块。

用法：
  python build/gen-hof-gos-chain.py
  powershell -NoProfile -File build/sync-from-r56.ps1     # 再把决议块打进 decisions/SOV.txt

设计要点（改之前先读）：
  · 阶段 1 的 4 张卡 = 原版那一张 targeted decision（targets = USA ENG GER JAP），
    「没做过的国家」都可点 ⇒ 任意顺序。
  · 阶段 2 的 3 张卡 = 原版那三张（民用/军用/造船厂），
    门槛是 hof_gos_country_phase_done（4 国全部完成）⇒ 任意顺序。
  · 进度靠 7 个布尔 flag（hof_gos_usa/eng/ger/jap + hof_gos_civ/mil/dock）；
    「当前是哪个 idea」靠 has_idea 判定（每种组合态一个 idea，唯一）。
  · 还有 2 个阶段 flag：hof_gos_started（已开始）· hof_gos_country_phase_done（4 国做完）。
  · ⚠️ 分类（决议面板页签）的 visible 判的是原版那两个 flag
    SOV_gosproyektstroy_level_2_flag —— 所以第一次升级时要顺手把它设上，
    否则整个页签会消失（该 flag 的定义在 decisions/categories/SOV_decision_categories.txt，
    我们【不覆盖】那个文件）。
"""

import os
import sys
import re

# ---------------------------------------------------------------------------
# 路径
# ---------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
R56 = r'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
MOD = os.path.join(ROOT, 'mod', 'heart_of_iron')

IDEAS_OUT = os.path.join(MOD, r'common\ideas\hof_gos_chain.txt')
INJECT_OUT = os.path.join(HERE, 'inject-dec-gos.txt')
VAN_DEC = os.path.join(R56, r'common\decisions\SOV.txt')

# ---------------------------------------------------------------------------
# 1. 加成表（全部来自原版 SOV_gosproyektstroy_* 的 modifier，逐条搬过来）
# ---------------------------------------------------------------------------
# 国别特性（原版 _2_usa / _2_eng / _2_ger / _2_jap 各自多出来的那几行）
COUNTRY_TRAIT = {
    'usa': [('production_factory_max_efficiency_factor', '0.1')],
    'eng': [('line_change_production_efficiency_factor', '0.1'),
            ('production_lack_of_resource_penalty_factor', '-0.1')],
    'ger': [('production_factory_efficiency_gain_factor', '0.05')],
    'jap': [('production_factory_start_efficiency_factor', '0.1')],
}
COUNTRIES = ['usa', 'eng', 'ger', 'jap']          # 顺序 = 原版 targets 的书写顺序
TAG = {'usa': 'USA', 'eng': 'ENG', 'ger': 'GER', 'jap': 'JAP'}

# 专精特性（原版 _3_*_civ / _3_*_mil / _3_*_dock 各自多出来的那几行）
SPECS = ['civ', 'mil', 'dock']                    # 顺序 = 原版 priority 13 / 12 / 11
SPEC_SPEED = {'civ': 'production_speed_industrial_complex_factor',
              'mil': 'production_speed_arms_factory_factor',
              'dock': 'production_speed_dockyard_factor'}
SPEC_EXTRA = {
    'civ': [('consumer_goods_factor', '-0.15')],
    'mil': [('industrial_capacity_factory', '0.05')],
    'dock': [('industrial_capacity_dockyard', '0.05')],
}

BASE_ID = 'SOV_gosproyektstroy_1'


def idea_id_countries(subset):
    return 'hof_gos_c%d_%s' % (len(subset), '_'.join(subset))


def idea_id_specs(subset):
    if len(subset) == 3:
        return 'hof_gos_s3_all'
    return 'hof_gos_s%d_%s' % (len(subset), '_'.join(subset))


def modifier_lines(subset_c, subset_s):
    """返回该状态下的完整 modifier 内容行（不含外层的 modifier = { }）"""
    out = []
    for spec in SPECS:
        key = SPEC_SPEED[spec]
        out.append((key, '0.1' if spec in subset_s else '0.05'))
    out.append(('license_purchase_cost', '-0.25'))
    for c in COUNTRIES:
        if c in subset_c:
            out.extend(COUNTRY_TRAIT[c])
    for spec in SPECS:
        if spec in subset_s:
            out.extend(SPEC_EXTRA[spec])
    return out


def visible_lines(subset_c, subset_s, base=False):
    """该 idea 的 visible 条件（精确状态）"""
    b = []
    if base:
        # 基础 idea：只要【当前没有拿着本链的任何 idea】就允许再买
        #（这样玩家中途换成别的设计商之后还能买回来重新开始，不会卡死）
        return None      # 由调用方特殊处理（22 条 NOT = { has_idea = ... }）
    for c in COUNTRIES:
        if c in subset_c:
            b.append('has_country_flag = hof_gos_%s' % c)
        else:
            b.append('NOT = { has_country_flag = hof_gos_%s }' % c)
    for s in SPECS:
        if s in subset_s:
            b.append('has_country_flag = hof_gos_%s' % s)
        else:
            b.append('NOT = { has_country_flag = hof_gos_%s }' % s)
    return b


T = '\t'
L = []          # 输出缓冲（ideas 文件）


def emit(s=''):
    L.append(s)


def emit_idea(iid, subset_c, subset_s, base=False, all_state_ids=None, comment=None):
    if comment:
        for x in comment:
            emit(T + T + '# ' + x)
    emit(T + T + iid + ' = {')
    emit()
    if not base:
        emit(T + T + T + 'name = %s' % BASE_ID)
        emit()
    emit(T + T + T + 'picture = generic_industrial_concern_2')
    emit()
    emit(T + T + T + 'allowed = {')
    emit(T + T + T + T + 'original_tag = SOV')
    emit(T + T + T + '}')
    emit()
    if base:
        emit(T + T + T + 'available = {')
        emit(T + T + T + T + 'has_completed_focus = SOV_foreign_experts')
        emit(T + T + T + '}')
        emit()
    if base:
        emit(T + T + T + 'visible = {')
        for x in all_state_ids:
            emit(T + T + T + T + 'NOT = { has_idea = %s }' % x)
        emit(T + T + T + T + 'NOT = { has_global_flag = sov_old_focus_tree }')
        emit(T + T + T + '}')
    else:
        emit(T + T + T + 'visible = {')
        for x in visible_lines(subset_c, subset_s):
            emit(T + T + T + T + x)
        emit(T + T + T + '}')
    emit()
    emit(T + T + T + 'cost = 100')
    emit()
    emit(T + T + T + 'traits = { construction_company }')
    if base:
        emit()
        emit(T + T + T + 'modifier = {')
        emit(T + T + T + T + 'custom_modifier_tooltip = SOV_gosproyektstroy_1_tt')
        for k, v in modifier_lines([], []):
            emit(T + T + T + T + '%s = %s' % (k, v))
        emit(T + T + T + '}')
    else:
        emit()
        # ⛔ 不给中间态 / 终态加 custom_modifier_tooltip ——
        #    原版 _3_* 也没有；不加才能在 tooltip 里看到【当前累积的全部数值】。
        emit(T + T + T + 'modifier = {')
        for k, v in modifier_lines(subset_c, subset_s):
            emit(T + T + T + T + '%s = %s' % (k, v))
        emit(T + T + T + '}')
    emit(T + T + '}')
    emit()


# ---------------------------------------------------------------------------
# 2. 生成 ideas 文件
# ---------------------------------------------------------------------------
import itertools

country_states = []
for k in range(1, 5):
    for combo in itertools.combinations(COUNTRIES, k):
        country_states.append(list(combo))
spec_states = []
for k in range(1, 4):
    for combo in itertools.combinations(SPECS, k):
        spec_states.append(list(combo))

all_ids = [idea_id_countries(c) for c in country_states] + [idea_id_specs(s) for s in spec_states]
assert len(all_ids) == 22, len(all_ids)
assert len(set(all_ids)) == 22

emit('# hof_gos_chain.txt')
emit('# ---------------------------------------------------------------------------')
emit('# 苏联「国家建筑设计局」升级链 —— {0} 个 idea'.format(1 + len(all_ids)))
emit('# ⛔ 本文件由 build/gen-hof-gos-chain.py 生成，不要手改（改生成器）。')
emit('#')
emit('# 为什么这么多 idea：HOI4 的 idea modifier 是静态的，而这条链要「4 国任意顺序 + 3 专精任意顺序」')
emit('# 且每完成一项就叠加 ⇒ 每到达一个「已完成的集合」都得有一个对应的 idea：')
emit('#   阶段 1（4 国）= 2^4-1 = 15 态 · 阶段 2（3 专精）= 2^3-1 = 7 态')
emit('#')
emit('# 编码红线：UTF-8 无 BOM + CRLF（脚本 .txt）')
emit('# ---------------------------------------------------------------------------')
emit()
emit('ideas = {')
emit(T + 'industrial_concern = {')
emit()
emit(T + T + '# ===== 基础（原版 SOV_gosproyektstroy_1，自 ideas/SOV.txt 搬来）=====')
emit_idea(BASE_ID, [], [], base=True, all_state_ids=all_ids)
emit(T + T + '# ===== 阶段 1：邀请 4 国专家（任意顺序）—— 15 个组合态 =====')
for st in country_states:
    emit_idea(idea_id_countries(st), st, [], comment=['已邀请：' + ' / '.join(x.upper() for x in st)])
emit(T + T + '# ===== 阶段 2：3 个专精方向（任意顺序，需先做完 4 国）—— 7 个组合态 =====')
for st in spec_states:
    emit_idea(idea_id_specs(st), COUNTRIES, st,
              comment=['4 国全到 + 专精：' + ' / '.join(x.upper() for x in st)])
emit(T + '}')
emit('}')
ideas_text = '\n'.join(L) + '\n'

# ---------------------------------------------------------------------------
# 3. 生成决议替换块
# ---------------------------------------------------------------------------
def read_van_blocks():
    with open(VAN_DEC, 'rb') as f:
        raw = f.read()
    text = raw.decode('utf-8-sig').replace('\r\n', '\n')
    lines = text.split('\n')

    def get_block(i):
        depth = 0
        out = []
        for k in range(i, len(lines)):
            out.append(lines[k])
            depth += lines[k].count('{') - lines[k].count('}')
            if depth == 0 and k > i:
                break
        return out

    res = {}
    for iid in ['SOV_gosproyektstroy_bring_foreign_experts', 'SOV_gosproyektstroy_focus_civ',
                'SOV_gosproyektstroy_focus_mil', 'SOV_gosproyektstroy_focus_dock']:
        idx = [k for k, l in enumerate(lines) if re.match(r'^\t' + iid + r'\s*=\s*\{$', l)]
        assert len(idx) == 1, (iid, len(idx))
        res[iid] = get_block(idx[0])
    return res


def split_fields(block):
    """把决议块（含 id 行与结尾 }）按顶层字段切开"""
    inner = block[1:-1]
    out = []
    cur = None
    d = 0
    for l in inner:
        if d == 0:
            m = re.match(r'^\t\t([A-Za-z_]\w*)\s*=', l)
            if m:
                cur = [m.group(1), [l]]
                out.append(cur)
                d = l.count('{') - l.count('}')
                continue
            out.append(['__blank__' if l.strip() == '' else '__raw__', [l]])
            continue
        cur[1].append(l)
        d += l.count('{') - l.count('}')
    return out


def field(blocks, iid, name):
    for k, ls in split_fields(blocks[iid]):
        if k == name:
            return ls
    raise KeyError((iid, name))


VAN = read_van_blocks()
D = []          # inject-dec-gos.txt 缓冲


def demit(s=''):
    D.append(s)


def dec_block(iid, body):
    demit('# hof:dec-begin ' + iid)
    demit(T + iid + ' = {')
    D.extend(body)
    demit(T + '}')
    demit('# hof:dec-end ' + iid)
    demit()


# --- 决议 1：邀请外国专家（阶段 1，4 国任意顺序）---------------------------
body = []
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'priority')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'icon')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'ai_will_do')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'targets')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'allowed')
body.append('')
body += [
    T + T + '# hof 2026-09-25：原版是「4 选 1，选过就锁死」。现在改成【4 国任意顺序、都能做】：',
    T + T + '#   · target_trigger 只筛未邀请国家，保留目标按钮；外交条件沿用原版 available。',
    T + T + '#   · fire_only_once 由 yes 改 no（本卡要用 4 次，每国一次）。',
    T + T + '#   · 进度 = 7 个布尔 flag（hof_gos_usa/eng/ger/jap + hof_gos_civ/mil/dock）。',
    T + T + 'target_trigger = {',
    T + T + T + 'OR = {',
]
for c in COUNTRIES:
    body.append(T + T + T + T + "AND = {{ FROM = {{ tag = {0} }}  NOT = {{ has_country_flag = hof_gos_{1} }} }}".format(TAG[c], c))
body += [
    T + T + T + '}',
    T + T + '}',
]
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'days_remove')
body.append('')
body += [T + T + 'fire_only_once = no']
body.append('')
body += [
    T + T + 'visible = {',
    T + T + T + 'NOT = { has_country_flag = hof_gos_country_phase_done }',
    T + T + '}',
]
body.append('')
body += [
    T + T + 'available = {',
    T + T + T + 'NOT = { has_country_flag = hof_gos_country_phase_done }',
    T + T + T + 'NOT = { has_country_flag = SOV_gosproyektstroy_upgrade_in_progress_flag }',
    T + T + T + 'FROM = {',
    T + T + T + T + 'has_opinion = { target = ROOT value > 29 }',
    T + T + T + T + 'SOV_is_valid_subject = yes',
    T + T + T + T + 'NOT = { has_war_with = ROOT }',
    T + T + T + '}',
    T + T + '}',
]
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'cost')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'modifier')
body.append('')
body += field(VAN, 'SOV_gosproyektstroy_bring_foreign_experts', 'complete_effect')
body.append('')
body += [
    T + T + 'remove_effect = {',
    T + T + T + '# 安全网：还拿着基础 idea（说明玩家中途换成别的设计商又买回来了）⇒ 进度清零重来，避免卡死。',
    T + T + T + 'if = {',
    T + T + T + T + 'limit = { has_idea = ' + BASE_ID + ' }',
]
for c in COUNTRIES:
    body.append(T + T + T + T + 'clr_country_flag = hof_gos_%s' % c)
for s in SPECS:
    body.append(T + T + T + T + 'clr_country_flag = hof_gos_%s' % s)
body += [
    T + T + T + T + 'clr_country_flag = hof_gos_started',
    T + T + T + T + 'clr_country_flag = hof_gos_country_phase_done',
    T + T + T + '}',
]
for c in COUNTRIES:
    body.append('')
    body.append(T + T + T + ('if' if c == COUNTRIES[0] else 'else_if') + ' = {')
    body.append(T + T + T + T + 'limit = {')
    body.append(T + T + T + T + T + 'FROM = { tag = %s }' % TAG[c])
    body.append(T + T + T + T + '}')
    body.append(T + T + T + T + 'set_country_flag = hof_gos_%s' % c)
    body.append(T + T + T + T + '# 原版 flag，只为决议分类（页签）的 visible —— 分类文件我们不覆盖。')
    body.append(T + T + T + T + 'set_country_flag = SOV_gosproyektstroy_level_2_flag')
    body.append(T + T + T + T + 'set_country_flag = hof_gos_started')
    # 枚举「当前状态」（不含该国的所有 subset，【含空集】）→ 换成含该国的 subset
    # ⚠️ 空集必须带上 —— 它对应「还没邀请过任何国家」时手里拿的是基础 idea。
    for prev_c in ([[]] + country_states):
        if c in prev_c:
            continue
        cur_id = BASE_ID if not prev_c else idea_id_countries(prev_c)
        nxt = sorted(set(prev_c) | {c}, key=COUNTRIES.index)
        nxt_id = idea_id_countries(nxt)
        body.append(T + T + T + T + 'if = {')
        body.append(T + T + T + T + T + 'limit = { has_idea = %s }' % cur_id)
        body.append(T + T + T + T + T + 'swap_ideas = {')
        body.append(T + T + T + T + T + T + 'remove_idea = %s' % cur_id)
        body.append(T + T + T + T + T + T + 'add_idea = %s' % nxt_id)
        body.append(T + T + T + T + T + '}')
        if len(nxt) == 4:
            body.append(T + T + T + T + T + '# 4 国到齐 ⇒ 解锁阶段 2（3 张专精卡）')
            body.append(T + T + T + T + T + 'set_country_flag = hof_gos_country_phase_done')
        body.append(T + T + T + T + '}')
    body.append(T + T + T + '}')
body.append('')
body += [
    T + T + T + 'clr_country_flag = SOV_gosproyektstroy_upgrade_in_progress_flag',
    T + T + '}',
]
dec_block('SOV_gosproyektstroy_bring_foreign_experts', body)

# --- 决议 2/3/4：三个专精（阶段 2，任意顺序）-------------------------------
DIR_META = [
    ('SOV_gosproyektstroy_focus_civ', 'civ'),
    ('SOV_gosproyektstroy_focus_mil', 'mil'),
    ('SOV_gosproyektstroy_focus_dock', 'dock'),
]
for iid, spec in DIR_META:
    body = []
    body += field(VAN, iid, 'priority')
    body.append('')
    body += field(VAN, iid, 'icon')
    body.append('')
    body += field(VAN, iid, 'ai_will_do')
    body.append('')
    body += field(VAN, iid, 'allowed')
    body.append('')
    body += [
        T + T + '# hof 2026-09-25：方向阶段改为【3 个方向任意顺序、都能做】。',
        T + T + '# 门槛 = hof_gos_country_phase_done（4 国全部邀请完毕）。',
        T + T + 'available = {',
        T + T + T + 'has_country_flag = hof_gos_country_phase_done',
        T + T + T + 'NOT = { has_country_flag = hof_gos_%s }' % spec,
        T + T + T + 'NOT = { has_country_flag = SOV_gosproyektstroy_upgrade_in_progress_flag }',
        T + T + '}',
    ]
    body.append('')
    body += field(VAN, iid, 'days_remove')
    body.append('')
    body += field(VAN, iid, 'fire_only_once')
    body.append('')
    body += [
        T + T + 'visible = {',
        T + T + T + 'has_country_flag = hof_gos_country_phase_done',
        T + T + T + 'NOT = { has_country_flag = hof_gos_%s }' % spec,
        T + T + '}',
    ]
    body.append('')
    body += field(VAN, iid, 'cost')
    body.append('')
    body += field(VAN, iid, 'modifier')
    body.append('')
    body += field(VAN, iid, 'complete_effect')
    body.append('')
    body += [
        T + T + 'remove_effect = {',
        T + T + T + 'set_country_flag = hof_gos_%s' % spec,
    ]
    for prev_s in ([[]] + spec_states):
        if spec in prev_s:
            continue
        cur_id = idea_id_specs(prev_s) if prev_s else idea_id_countries(COUNTRIES)
        nxt = sorted(set(prev_s) | {spec}, key=SPECS.index)
        nxt_id = idea_id_specs(nxt)
        body.append(T + T + T + 'if = {')
        body.append(T + T + T + T + 'limit = { has_idea = %s }' % cur_id)
        body.append(T + T + T + T + 'swap_ideas = {')
        body.append(T + T + T + T + T + 'remove_idea = %s' % cur_id)
        body.append(T + T + T + T + T + 'add_idea = %s' % nxt_id)
        body.append(T + T + T + T + '}')
        if len(nxt) == 3:
            body.append(T + T + T + T + '# 3 个方向全做完')
            body.append(T + T + T + T + 'set_country_flag = hof_gos_all_done')
        body.append(T + T + T + '}')
    body.append('')
    body += [
        T + T + T + 'clr_country_flag = SOV_gosproyektstroy_upgrade_in_progress_flag',
        T + T + '}',
    ]
    dec_block(iid, body)

inject_text = '\n'.join(D) + '\n'

# ---------------------------------------------------------------------------
# 4. 自检（生成前先验证，避免写出坏文件）
# ---------------------------------------------------------------------------
def check(name, text):
    ob, cb = text.count('{'), text.count('}')
    assert ob == cb, '%s 花括号不配平：%d vs %d' % (name, ob, cb)
    assert "'" not in text, '%s 含单引号（会破坏 PowerShell 单引号字符串/或意外）' % name


check('hof_gos_chain.txt', ideas_text)
check('inject-dec-gos.txt', inject_text)

# 决议块：每张卡的枚举分支数
n_bring = inject_text.count('swap_ideas = {', inject_text.index('hof:dec-begin SOV_gosproyektstroy_bring_foreign_experts'),
                            inject_text.index('hof:dec-end SOV_gosproyektstroy_bring_foreign_experts'))
print('阶段 1 卡的 swap 分支数 = %d（应为 8×4=32：每国 8 种前态，含空集）' % n_bring)
assert n_bring == 32, n_bring
for _iid, _spec in DIR_META:
    _s = inject_text.index('hof:dec-begin ' + _iid)
    _e = inject_text.index('hof:dec-end ' + _iid)
    _n = inject_text.count('swap_ideas = {', _s, _e)
    print('   %s 的 swap 分支数 = %d（应为 4：空集 + 另外两个专精）' % (_iid, _n))
    assert _n == 4, (_iid, _n)

# ---------------------------------------------------------------------------
# 5. 写文件（UTF-8 无 BOM + CRLF）
# ---------------------------------------------------------------------------
os.makedirs(os.path.dirname(IDEAS_OUT), exist_ok=True)
with open(IDEAS_OUT, 'wb') as f:
    f.write(ideas_text.replace('\n', '\r\n').encode('utf-8'))
with open(INJECT_OUT, 'wb') as f:
    f.write(inject_text.replace('\n', '\r\n').encode('utf-8'))

print('已生成：')
print('  ' + IDEAS_OUT)
print('     %d 个 idea（基础 1 + 阶段 1 的 15 + 阶段 2 的 7）' % (1 + len(all_ids)))
print('  ' + INJECT_OUT)
print('     4 个决议块（阶段 1 卡 32 个 swap 分支；3 张专精卡各 4 个）')
