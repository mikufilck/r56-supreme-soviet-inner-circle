"""S5 经互会通用线 —— 民族精神（idea / DM）方形图 + 国际学联徽（游戏里没有的那张）。

机制：
  ① 游戏自带的三张国策图（经互会 / 华约 / 共产国际）本来就是 100x88，**不用重做**；
     这里只把它们**裁成方形、缩到 60x60**，做成 idea / dynamic_modifier 能用的
     「民族精神版」—— 原版 idea 图就是方形的。
  ② 游戏里【没有】的机构徽标（目前一张：国际学联旗）才从外部实物抠图，两个规格都出。

产出：
  art/focus/ma/GFX_idea_hof_ma_<名>.png              60x60 预览
  mod/heart_of_iron/gfx/interface/hof_ma/ideas/*.dds 60x60 DDS（民族精神版）
  mod/heart_of_iron/gfx/interface/hof_ma/focus/*.dds 100x88 DDS（国策版 · 仅外部实物那批）

跑完再跑 build/gen-hof-ma-icons.ps1 注册 sprite。
用法：python build/gen-hof-ma-idea-icons.py
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tmp' / 'art-python'))
from PIL import Image

VANILLA = Path(r'F:\Hearts.of.Iron.IV.v1.19.3.0')
ART = ROOT / 'art' / 'focus' / 'ma'
IDEA_DDS = ROOT / 'mod' / 'heart_of_iron' / 'gfx' / 'interface' / 'hof_ma' / 'ideas'
FOCUS_DDS = ROOT / 'mod' / 'heart_of_iron' / 'gfx' / 'interface' / 'hof_ma' / 'focus'
RAW = ROOT / 'tmp' / 'ma-emblems'
for d in (ART, IDEA_DDS, FOCUS_DDS):
    d.mkdir(parents=True, exist_ok=True)

# ---- ① 游戏自带图 → 只出【民族精神（方形）版】----
#    用户口径：「经互会和华约的不用，游戏内不是已经有了」⇒ 这两张国策图原版就有、规格也对，
#    这里只把它们裁方缩到 60x60，给 idea / dynamic_modifier 用。
FROM_VANILLA = {
    'comecon':    'gfx/interface/goals/focus_SOV_the_comecon.dds',
    'warsawpact': 'gfx/interface/goals/focus_SOV_found_the_warsaw_pact.dds',
}
# ---- ② 外部实物（游戏里没有的机构徽标）----
#    处理方式：disc = 先圆形裁成徽章（旗面/方图用）；trim = 直接抠掉透明边（已经是抠好的 logo）
FROM_RAW = {
    'cominform': ('disc', True),    # 共产党和工人党情报局标志（红旗 + 镰锤徽）→ 两个规格
    'ius':       ('disc', True),    # 国际学生联合会旗徽 → 两个规格
    'wftu':      ('trim', False),   # 世界工会联合会 logo → 只出 100x88
    'oirt':      ('trim', True),    # 国际广播电视组织 logo → 两个规格（idea：国际广播组织）
    'osce':      ('disc', True),    # 欧安会旗（用户已批准「年代错也可以用」）→ 两个规格（idea：赫尔辛基最后文件）
}

# ---- ③ 第二批外部实物（2026-09-21 · 用户给的线索）----
#    条目 = (源文件名, 处理方式, 归一化裁剪框 或 None, 是否同时出民族精神版)
#    处理方式：'disc' = 圆形裁成徽章 · 'trim' = 直接抠透明边 · 'white' = 先抠掉白底再 trim
RAW2 = ROOT / 'tmp' / 'ma-emblems2'
FROM_RAW2 = {
    # 世界民主青年联盟 1945 年徽标（⭐ FOTW 的历史徽章图；Commons 那张同名的 svg **其实是会员国地图**）
    'wfdy':    ('wfdy_fotw_e.gif',  'white', None,                     False),
    # 国际经济合作银行官方标记（官网 favicon 180px；⚠️ 现代的抽象标，不是 1963 年那个圆形 МБЭС）
    'ibec':    ('ibec_icon180.png', 'white', None,                     False),
    # 国际民主妇女联合会 1945 年成立时的原版徽标（源图是一张竖版卡片：上方 WIDF 字样、中间是地球+和平鸽）
    'widf':    ('widf.jpg',         'disc',  (0.00, 0.26, 1.00, 0.94), False),
    # 国际新闻工作者协会 1946 年徽标（Commons 的 SVG，已取 960px PNG）
    'ioj':     ('ioj.png',          'trim',  None,                     False),
    # 「友谊」输油管道纪念徽章（sovietznak.ru 实物照片，蓝珐琅圆形）
    'druzhba': ('druzhba_badge.jpg','white', None,                     False),
    # 世界和平理事会 = **毕加索的鸽子** —— 取自 **1950 年中国「保卫世界和平」邮票（纪5 3-1）**：
    # 邮票是 PD（`File:Ji5, 3-1, Peace Dove, 1950.jpg`），图案是毕加索的鸽子 + 橄榄枝环，正好不需要美术画。
    'wpc':     ('wpc_dove_stamp.png', 'disc', (0.19, 0.205, 0.81, 0.625), True),
    # Intermetall（经互会黑色冶金合作组织）1974 年成立十周年纪念章 —— 取【正面】那枚（INTERMETALL / 10 ЛЕТ / ИНТЕРМЕТАЛЛ）
    'intermetall': ('intermetall_medal.jpg', 'disc', (0.00, 0.00, 0.47, 1.00), False),
    # 国际投资银行官方 logo（iib.int 新闻素材包，2014 现代版）—— 只取左边那颗「切割祖母绿」，丢掉右边文字
    'iib':     ('iib_a.png',        'white', (0.00, 0.00, 0.30, 1.00), False),
}

IDEA = 60


def white(im, thr=238, spread=16):
    """把接近纯白的底抠成透明（扫描件 / 官网 logo 的常见底）。"""
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r >= thr and g >= thr and b >= thr and (max(r, g, b) - min(r, g, b)) <= spread:
                px[x, y] = (r, g, b, 0)
    return im


def crop_frac(im, box):
    """按归一化比例裁剪。"""
    if not box:
        return im
    w, h = im.size
    l, tp, r, b = box
    return im.crop((int(l * w), int(tp * h), int(r * w), int(b * h)))


def disc(im):
    """圆形裁成徽章 —— 四角必然透明。"""
    from PIL import ImageDraw
    w, h = im.size
    side = min(w, h)
    bbox = im.getchannel('A').getbbox()
    if bbox and (bbox[2] - bbox[0]) > 0.6 * w and (bbox[3] - bbox[1]) > 0.6 * h:
        cx, cy = w / 2, h / 2          # 整幅就是一张旗/方图 ⇒ 取几何中心
    elif bbox:
        cx, cy = (bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2
    else:
        cx, cy = w / 2, h / 2
    cx = max(side / 2, min(w - side / 2, cx)); cy = max(side / 2, min(h - side / 2, cy))
    im = im.crop((int(cx - side / 2), int(cy - side / 2), int(cx + side / 2), int(cy + side / 2)))
    mask = Image.new('L', (side, side), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, side - 1, side - 1), fill=255)
    im.putalpha(Image.composite(im.getchannel('A'), Image.new('L', (side, side), 0), mask))
    return im


def alpha_ok(im, name):
    """照 art/focus/export_focus.py 的口径自检：四角必须全透明。"""
    w, h = im.size
    for p in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        if im.getpixel(p)[3] != 0:
            raise AssertionError(f'{name}: 角 {p} 不透明')


def fit(im, W, H, margin):
    """等比装进 WxH、居中、留透明边；自动放大到满足 export_focus.py 的 alpha 口径。"""
    bbox = im.getchannel('A').getbbox()
    if bbox:
        im = im.crop(bbox)
    canvas = None
    for scale in [1.0, 1.08, 1.16, 1.24, 1.32, 1.4, 1.5, 1.6]:
        r = min((W - 2 * margin) * scale / im.width, (H - 2 * margin) * scale / im.height)
        nw, nh = max(1, int(im.width * r)), max(1, int(im.height * r))
        canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        small = im.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas.paste(small, ((W - nw) // 2, (H - nh) // 2), small)
        a = canvas.getchannel('A').histogram(); tot = W * H
        if (0.20 <= a[0] / tot <= 0.50 and sum(a[250:]) / tot > 0.20
                and all(canvas.getpixel(q)[3] == 0 for q in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)])):
            return canvas
    return canvas


rows = []
for name, rel in FROM_VANILLA.items():
    src = VANILLA / rel
    if not src.is_file():
        print(f'  [SKIP] {name}: 找不到 {rel}')
        continue
    with Image.open(src) as raw_img:
        src_img = raw_img.convert('RGBA')
    idea = fit(src_img, IDEA, IDEA, 4)
    alpha_ok(idea, name)
    idea.save(ART / f'GFX_idea_hof_ma_{name}.png')
    idea.save(IDEA_DDS / f'GFX_idea_hof_ma_{name}.dds')
    rows.append(f'{name:11s} 民族精神版 60x60    <- 游戏自带 {rel.split("/")[-1]}')

for name, (how, need_idea) in FROM_RAW.items():
    src_path = RAW / f'{name}.png'
    if not src_path.is_file():
        print(f'  [SKIP] {name}: 找不到 {src_path}')
        continue
    with Image.open(src_path) as raw_img:
        src_img = raw_img.convert('RGBA')
    if how == 'disc':
        src_img = disc(src_img)
    focus = fit(src_img.copy(), 100, 88, 6)
    alpha_ok(focus, name)
    focus.save(ART / f'GFX_hof_ma_{name}_focus.png')
    focus.save(FOCUS_DDS / f'GFX_hof_ma_{name}.dds')
    row = f'{name:11s} 国策版 100x88'
    if need_idea:
        idea = fit(src_img.copy(), IDEA, IDEA, 4)
        alpha_ok(idea, name)
        idea.save(ART / f'GFX_idea_hof_ma_{name}.png')
        idea.save(IDEA_DDS / f'GFX_idea_hof_ma_{name}.dds')
        row += '  ＋ 民族精神版 60x60'
    rows.append(row + '    <- 外部实物（游戏里没有）')

for name, (fname, how, box, need_idea) in FROM_RAW2.items():
    src_path = RAW2 / fname
    if not src_path.is_file():
        print(f'  [SKIP] {name}: 找不到 {src_path}')
        continue
    with Image.open(src_path) as raw_img:
        src_img = raw_img.convert('RGBA')
    src_img = crop_frac(src_img, box)
    if how == 'white':
        src_img = white(src_img)
    if how == 'disc':
        src_img = disc(src_img)
    focus = fit(src_img.copy(), 100, 88, 6)
    alpha_ok(focus, name)
    focus.save(ART / f'GFX_hof_ma_{name}_focus.png')
    focus.save(FOCUS_DDS / f'GFX_hof_ma_{name}.dds')
    row = f'{name:11s} 国策版 100x88（{how}）'
    if need_idea:
        idea = fit(src_img.copy(), IDEA, IDEA, 4)
        alpha_ok(idea, name)
        idea.save(ART / f'GFX_idea_hof_ma_{name}.png')
        idea.save(IDEA_DDS / f'GFX_idea_hof_ma_{name}.dds')
        row += '  ＋ 民族精神版 60x60'
    rows.append(row + '    <- 外部实物（第二批）')

print('==== 生成结果 ====')
print('\n'.join(rows))

# ---- 自检 ----
bad = []
for f in sorted(IDEA_DDS.glob('GFX_idea_hof_ma_*.dds')) + sorted(FOCUS_DDS.glob('GFX_hof_ma_*.dds')):
    with Image.open(f) as im:
        want = (100, 88) if '\\focus' in str(f) else (60, 60)
        if im.size != want:
            bad.append(f'{f.name} {im.size} != {want}')
        if im.mode != 'RGBA':
            bad.append(f'{f.name} mode={im.mode}')
print('==== 自检 ====')
print('  [OK ] 全部 DDS 尺寸与 32 位 RGBA 合规' if not bad else '  [FAIL] ' + '; '.join(bad))
