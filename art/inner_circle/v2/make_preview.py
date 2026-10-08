"""把核心圈窗口的 11 件素材按 .gui 里的真实坐标合成一张预览图。

用途：底板已是 v2（640x640），但其余 10 件还是 v1 —— 先合成看一眼，
      再决定这 10 件要不要重画。

做法：解析 interface/hof_ic_scripted_gui.gui（容器嵌套 -> 绝对坐标）
      + 解析 interface/hof_ic.gfx（sprite 名 -> dds 路径），
      然后把贴图按 alpha 叠加到底板上，输出 art/inner_circle/v2/preview_mix.png

用法：python art/inner_circle/v2/make_preview.py
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

GUI = ROOT / 'mod/heart_of_iron/interface/hof_ic_scripted_gui.gui'
GFX = ROOT / 'mod/heart_of_iron/interface/hof_ic.gfx'
MOD = ROOT / 'mod/heart_of_iron'
OUT = Path(__file__).resolve().parent / 'preview_mix.png'

# ---------------------------------------------------------------- sprite -> dds
sprite2tex = {}
cur = None
for line in GFX.read_text(encoding='utf-8-sig').splitlines():
    m = re.search(r'name\s*=\s*"([^"]+)"', line)
    if m:
        cur = m.group(1)
    m = re.search(r'texturefile\s*=\s*"([^"]+)"', line)
    if m and cur:
        sprite2tex[cur] = MOD / m.group(1).replace('/', '\\')
        cur = None

# ------------------------------------------------- 解析 .gui：容器嵌套 + 绝对坐标
lines = GUI.read_text(encoding='utf-8-sig').splitlines()
stack = []          # [(缩进对应的容器绝对x, 绝对y)]
placements = []     # (spriteName, absX, absY, scale, label)
pending = {}        # 当前元素收集到的字段
elem_indent = None
elem_is_container = False

def flush(pend, indent, is_container):
    """元素收尾：iconType/background 有 spriteType 就登记；container 压栈。"""
    x = pend.get('x', 0)
    y = pend.get('y', 0)
    # 🚩 只加【最近一层】父容器的【绝对】偏移 —— stack 里存的已经是绝对值，
    #    全加起来会重复累加（踩过：seat_7 被顶到 x=2013）
    parent = None
    for (ci, cx, cy) in stack:
        if ci < indent:
            parent = (cx, cy)
    if parent:
        x += parent[0]
        y += parent[1]

    spr = pend.get('spriteType')
    name = pend.get('name', '')
    # .gui 里留空的 spriteType 由 scripted_images 在运行时供给；预览里用对应贴图代替
    if not spr:
        if re.match(r'hof_ic_seat_\d+_frame$', name):
            spr = 'GFX_hof_ic_seat_frame_empty'
        elif name == 'hof_ic_leader_portrait':
            spr = 'GFX_hof_ic_blank_portrait'
    if spr and sprite2tex.get(spr):
        placements.append((spr, x, y, pend.get('scale', 1.0), name))
    if is_container:
        stack.append((indent, x, y))

depth_re = re.compile(r'^(\s*)')
for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        continue
    indent = len(line) - len(line.lstrip('\t'))
    leading = line[:len(line) - len(line.lstrip())]
    indent = len(leading.expandtabs(4))

    if pending and stripped.startswith('position'):
        pass

    if re.match(r'^(iconType|background|containerWindowType|instantTextBoxType|buttonType)\s*=\s*\{', stripped):
        if pending:
            flush(pending, elem_indent, elem_is_container)
        pending = {'name': '', 'x': 0, 'y': 0, 'scale': 1.0}
        elem_indent = indent
        elem_is_container = stripped.startswith('containerWindowType')
        continue

    if pending is not None:
        m = re.search(r'name\s*=\s*"([^"]*)"', stripped)
        if m and not re.search(r'texturefile', stripped):
            pending['name'] = m.group(1)
        m = re.search(r'spriteType\s*=\s*"([^"]*)"', stripped)
        if m:
            pending['spriteType'] = m.group(1)
        m = re.search(r'position\s*=\s*\{\s*x\s*=\s*(-?\d+)\s*y\s*=\s*(-?\d+)', stripped)
        if m:
            pending['x'] = int(m.group(1))
            pending['y'] = int(m.group(2))
        m = re.search(r'scale\s*=\s*([0-9.]+)', stripped)
        if m:
            pending['scale'] = float(m.group(1))

if pending:
    flush(pending, elem_indent, elem_is_container)

print(f'解析到 {len(placements)} 个贴图放置点，{len(sprite2tex)} 个 sprite 注册')
print()

# ------------------------------------------------------------------- 合成
board_tex = sprite2tex['GFX_hof_ic_window_bg']
board = Image.open(board_tex).convert('RGBA')
W, H = board.size
print(f'底板 {board_tex.name}  {W}x{H}')

canvas = board.copy()
missing = []
for spr, x, y, scale, label in placements:
    tex = sprite2tex.get(spr)
    if tex is None:
        missing.append(f'{spr}（.gfx 里没注册）')
        continue
    if not tex.is_file():
        missing.append(f'{spr}（文件不存在 {tex}）')
        continue
    im = Image.open(tex).convert('RGBA')
    if scale != 1.0:
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.Resampling.LANCZOS)
    # 组件位置是相对容器左上角；但游戏里窗口是 lower_left 对齐，
    # 这里 canvas 本身就是底板上->下，容器 y 已经是"从容器顶部算"，直接贴即可。
    canvas.alpha_composite(im, (x, y))
    print(f'  {label:34s} {spr:32s} @({x:4d},{y:4d})  {im.size[0]}x{im.size[1]}')

if missing:
    print()
    print('未贴入：')
    for m in missing:
        print('  ' + m)

canvas.save(OUT)
print()
print('写出 ' + str(OUT.relative_to(ROOT)))
