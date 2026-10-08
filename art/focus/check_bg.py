# check_bg.py —— ① 原版国策图标有没有透明  ② 我们的背景是不是纯色（能否自动抠）
import glob
import os
import sys
from collections import Counter

try:
    from PIL import Image
except ImportError:
    sys.exit('需要 Pillow')

HOI4 = r'F:\Hearts of Iron IV'

print('=== ① 原版国策图标（focus_SOV_*.dds）的 alpha ===')
print(f'{"文件":48s} {"尺寸":10s} {"四角alpha":22s} {"透明%":>7s}')
print('-' * 96)

pat = os.path.join(HOI4, 'gfx', 'interface', 'goals', 'focus_SOV_*.dds')
vfiles = sorted(glob.glob(pat))[:8]
if not vfiles:
    print('  （没找到原版 DDS）')
for f in vfiles:
    try:
        im = Image.open(f)
        mode = im.mode
        im = im.convert('RGBA')
        w, h = im.size
        px = im.load()
        ca = [px[0, 0][3], px[w - 1, 0][3], px[0, h - 1][3], px[w - 1, h - 1][3]]
        hist = im.getchannel('A').histogram()
        n = w * h
        transp = sum(hist[0:10]) / n * 100.0
        print(f'{os.path.basename(f):48s} {str(w) + "x" + str(h):10s} {str(ca) + " (" + mode + ")":22s} {transp:7.1f}')
    except Exception as e:
        print(f'{os.path.basename(f):48s} 读不了：{e}')

print()
print('=== ② 我们的图标：背景是不是纯色（决定能否程序化抠底）===')
print(f'{"文件":46s} {"全图不同色数":>12s} {"最大占比色":>26s} {"占比%":>7s}')
print('-' * 100)

for f in sorted(glob.glob(os.path.join('art', 'focus', 'GFX_*.png')))[:6]:
    im = Image.open(f).convert('RGBA')
    cols = Counter(im.getdata())
    top, cnt = cols.most_common(1)[0]
    n = im.size[0] * im.size[1]
    print(f'{os.path.basename(f):46s} {len(cols):12d} {str(top[:3]):>26s} {cnt / n * 100:7.1f}')

print()
print('=== ③ 边缘一圈的颜色（看背景是否被渐变/噪点污染）===')
f = os.path.join('art', 'focus', 'GFX_hof_ic_trotsky_state_planning.png')
im = Image.open(f).convert('RGBA')
w, h = im.size
ring = []
for x in range(w):
    ring.append(im.getpixel((x, 0)))
    ring.append(im.getpixel((x, h - 1)))
for y in range(h):
    ring.append(im.getpixel((0, y)))
    ring.append(im.getpixel((w - 1, y)))
rc = Counter(ring)
print(f'边缘像素 {len(ring)} 个，不同颜色 {len(rc)} 种')
for c, k in rc.most_common(5):
    print(f'   {c}  x{k}')
