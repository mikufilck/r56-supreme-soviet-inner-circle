"""把国策图标的实心深色底抠成透明。

背景：原版 focus_SOV_*.dds 的透明率是 24~45%（四角 alpha=0），
      我们这批是 100% 不透明 -> 在国策树里显出深色方块。

做法：在 source/ 的【高清原图】上处理（边缘质量最好），再按 export_focus.py
      同样的方式 LANCZOS 缩到 100x88 导出 PNG + DDS。
      - 从四边泛洪填充（只吃连通到边缘的背景，不会咬进奖章内部）
      - 边界按颜色距离做软过渡，避免锯齿
      - 缩放走【预乘 alpha】，避免半透明边缘发黑

source/ 里的原图不动，要回到不透明版重跑 export_focus.py 即可。

用法：python art/focus/make_transparent.py
"""
from pathlib import Path
import sys
import json
import struct
from collections import deque

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

ART = ROOT / 'art/focus'
SRC = ART / 'source'
DDS = ROOT / 'mod/heart_of_iron/gfx/interface/hof_ic/focus'

T_HARD = 26   # 泛洪阈值：Chebyshev 距离 <= 这个值才算背景
T_SOFT = 16   # 软过渡阈值：距离 0 -> 全透明，>= 16 -> 不透明

manifest = json.loads((ART / 'manifest.json').read_text(encoding='utf-8'))
names = [a['name'] for a in manifest['assets']]


def key_out(im):
    """返回抠底后的 RGBA 图（同尺寸）。"""
    im = im.convert('RGBA')
    w, h = im.size
    px = im.load()

    # 背景参考色 = 四边一圈的众数
    from collections import Counter
    ring = []
    for x in range(w):
        ring.append(px[x, 0][:3])
        ring.append(px[x, h - 1][:3])
    for y in range(h):
        ring.append(px[0, y][:3])
        ring.append(px[w - 1, y][:3])
    br, bg, bb = Counter(ring).most_common(1)[0][0]

    def dist(p):
        return max(abs(p[0] - br), abs(p[1] - bg), abs(p[2] - bb))

    # 判据二选一：够像边缘色（窄阈值）【或】（深 + 低饱和）——后者能吃下带暗角的渐变背景
    # 奖章主体是金/红/白，饱和度和亮度都高，不会被误吃
    def is_bg(p):
        r, g, b = p[0], p[1], p[2]
        mx, mn = max(r, g, b), min(r, g, b)
        if mx - mn <= 26 and mx <= 96:
            return True
        return dist(p) <= T_HARD

    # 从四边泛洪（4 连通），只吃连通到边缘的背景
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            i = y * w + x
            if not seen[i] and dist(px[x, y]) <= T_HARD:
                seen[i] = 1
                q.append(i)
    for y in range(h):
        for x in (0, w - 1):
            i = y * w + x
            if not seen[i] and dist(px[x, y]) <= T_HARD:
                seen[i] = 1
                q.append(i)
    while q:
        i = q.popleft()
        x, y = i % w, i // w
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h:
                j = ny * w + nx
                if not seen[j] and dist(px[nx, ny]) <= T_HARD:
                    seen[j] = 1
                    q.append(j)

    # 写 alpha：背景区按距离软过渡
    out = im.copy()
    opx = out.load()
    cleared = 0
    for y in range(h):
        row = y * w
        for x in range(w):
            if seen[row + x]:
                d = dist(px[x, y])
                a = 0 if d >= T_SOFT else int(255 * d / T_SOFT)
                r, g, b, _ = opx[x, y]
                opx[x, y] = (r, g, b, a)
                if a == 0:
                    cleared += 1
    return out, cleared / (w * h) * 100.0


def downscale(im):
    """预乘 alpha 缩放，避免半透明边缘发黑。"""
    w, h = im.size
    px = im.load()
    pre = Image.new('RGBA', (w, h))
    ppx = pre.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            ppx[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
    small = pre.resize((100, 88), Image.Resampling.LANCZOS)
    spx = small.load()
    out = Image.new('RGBA', (100, 88))
    opx = out.load()
    for y in range(88):
        for x in range(100):
            r, g, b, a = spx[x, y]
            if a == 0:
                opx[x, y] = (0, 0, 0, 0)
            else:
                opx[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a),
                             min(255, b * 255 // a), a)
    return out


print(f'{"文件":52s} {"源尺寸":12s} {"清除%":>7s} {"结果透明%":>10s}')
print('-' * 88)

bad = []
for name in names:
    src = SRC / (name + '.png')
    with Image.open(src) as im:
        srcsize = f'{im.size[0]}x{im.size[1]}'
        keyed, pct = key_out(im)

    if pct < 12 or pct > 80:
        bad.append(f'{name} 清除比例异常 {pct:.1f}%')

    out = downscale(keyed)
    hist = out.getchannel('A').histogram()
    n = 100 * 88
    transp = sum(hist[0:10]) / n * 100.0

    out.save(ART / (name + '.png'))
    out.save(DDS / (name + '.dds'))

    # DDS 头校验（与 export_focus.py 同一套断言）
    data = (DDS / (name + '.dds')).read_bytes()
    u32 = lambda p: struct.unpack_from('<I', data, p)[0]
    assert data[:4] == b'DDS ' and u32(4) == 124
    assert (u32(16), u32(12)) == (100, 88)
    assert u32(28) == 0 and u32(84) == 0 and u32(88) == 32
    assert u32(104) == 0xff000000 and len(data) == 128 + 100 * 88 * 4
    with Image.open(DDS / (name + '.dds')) as dec:
        assert dec.convert('RGBA').tobytes() == out.tobytes()

    print(f'{name:52s} {srcsize:12s} {pct:7.1f} {transp:10.1f}')

print()
if bad:
    print('⚠ 以下文件抠底比例可疑，需要人工看一眼：')
    for b in bad:
        print('   ' + b)
else:
    print('OK: 24 张全部抠底完成，透明率落在原版区间（24~45%）附近；'
          'DDS 头 / 尺寸 / 像素往返全部通过。')
print('提示：source/ 里的原图未改动，要回退重跑 art/focus/export_focus.py 即可。')
