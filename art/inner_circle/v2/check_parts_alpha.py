"""查核心圈窗口 11 件素材的 alpha —— 判断哪些已经是透明底、哪些不是。

用法：python art/inner_circle/v2/check_parts_alpha.py
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

D = ROOT / 'mod/heart_of_iron/gfx/interface/hof_ic'

rows = [
    ('窗口底板', 'hof_ic_window_bg.dds', 'v2'),
    ('中央聚光', 'hof_ic_spotlight.dds', 'v1'),
    ('领袖圆框', 'hof_ic_leader_frame.dds', 'v1'),
    ('领袖绸带', 'hof_ic_leader_ribbon.dds', 'v1'),
    ('领袖头衔框', 'hof_ic_leader_title_box.dds', 'v1'),
    ('空席位框', 'hof_ic_seat_frame_empty.dds', 'v1'),
    ('满席位框', 'hof_ic_seat_frame_filled.dds', 'v1'),
    ('席位名牌', 'hof_ic_seat_name_box.dds', 'v1'),
    ('席位特质框', 'hof_ic_seat_trait_box.dds', 'v1'),
    ('候选格', 'hof_ic_candidate_slot.dds', 'v1'),
    ('空白立绘', 'hof_ic_blank_portrait.dds', 'v1'),
]

print(f'{"部件":12s} {"版本":5s} {"尺寸":10s} {"四角alpha":20s} {"透明%":>7s}  判定')
print('-' * 92)

need_redraw = []
for label, fn, ver in rows:
    f = D / fn
    if not f.is_file():
        print(f'{label:12s} {ver:5s}  ❌ 文件不存在 {fn}')
        continue
    im = Image.open(f).convert('RGBA')
    w, h = im.size
    px = im.load()
    ca = [px[0, 0][3], px[w - 1, 0][3], px[0, h - 1][3], px[w - 1, h - 1][3]]
    hist = im.getchannel('A').histogram()
    n = w * h
    transp = sum(hist[0:10]) / n * 100.0
    # 判据用【四角 alpha】而不是透明率 —— 名牌 / 头衔框这类薄牌子本来就几乎铺满
    # 自己的矩形（只留圆角透明），透明率低是正常的
    if label == '窗口底板':
        verdict = '不透明 ✓（底板本来就该铺满）'
    elif max(ca) == 0:
        verdict = '已是透明底 ✓ 不用重画'
    else:
        verdict = '❌ 四角不透明 —— 会盖住底板，需要透明底'
        need_redraw.append(label)
    print(f'{label:12s} {ver:5s} {str(w) + "x" + str(h):10s} {str(ca):20s} {transp:7.1f}  {verdict}')

print()
if need_redraw:
    print('需要让 GPT 重画（带透明底）的：' + '、'.join(need_redraw))
else:
    print('除底板外全部已是透明底，不需要重画。')
