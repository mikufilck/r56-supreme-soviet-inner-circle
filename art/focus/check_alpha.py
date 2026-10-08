# check_alpha.py —— 查国策图标 PNG 的背景是透明还是不透明
# 用法：python art/focus/check_alpha.py
import glob
import os
import sys
import json
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit('需要 Pillow：pip install pillow')

art = Path(__file__).resolve().parent
manifest = json.loads((art / 'manifest.json').read_text(encoding='utf-8'))
files = sorted(str(art / a['png']) for a in manifest['assets'])
if not files:
    sys.exit('没找到 art/focus/GFX_*.png')

print(f'共 {len(files)} 张\n')
print(f'{"文件":52s} {"尺寸":10s} {"四角alpha":22s} {"透明%":>7s} {"不透明%":>9s} {"四角RGB":>18s}')
print('-' * 128)

all_opaque = True
for f in files:
    im = Image.open(f).convert('RGBA')
    w, h = im.size
    px = im.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    ca = [c[3] for c in corners]
    crgb = corners[0][:3]
    hist = im.getchannel('A').histogram()
    n = w * h
    transp = sum(hist[0:10]) / n * 100.0
    opaq = sum(hist[246:256]) / n * 100.0
    if min(ca) > 200:
        tag = ''
    else:
        tag = '  <-- 有透明'
        all_opaque = False
    print(f'{os.path.basename(f):52s} {str(w) + "x" + str(h):10s} {str(ca):22s} {transp:7.1f} {opaq:9.1f} {str(crgb):>18s}{tag}')

print()
if all_opaque:
    print('==> 结论：四角【全部不透明】—— 图标是不透明矩形，'
          '在国策树里就会显出深色方块边框。需要把背景做成透明。')
else:
    print('==> 结论：四角是透明的，黑框另有原因（可能是图案本身的外框）。')
