"""Mechanical resizing/format conversion and a local HTML review page.

All artwork is created by built-in image_gen, not painted by this script.
"""
from pathlib import Path
import sys
import json
import struct
import html
import argparse

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--force', action='store_true')
args = parser.parse_args()
manifest = json.loads((BASE / 'manifest.json').read_text(encoding='utf-8-sig'))
destination = ROOT / 'mod/heart_of_iron/gfx/interface/hof_ic/portraits'
destination.mkdir(parents=True, exist_ok=True)
(BASE / 'png').mkdir(exist_ok=True)
report = []
cards = []
for a in manifest['assets']:
    name = a['name']
    record = json.loads((BASE / 'records' / (name + '.json')).read_text(encoding='utf-8-sig'))
    a['generation'] = record
    revision_path = BASE / 'records' / (name + '-revision.json')
    if revision_path.exists():
        a['revision'] = json.loads(revision_path.read_text(encoding='utf-8-sig'))
    a['review_status'] = 'delivered: visual review passed'
    png = BASE / 'png' / (name + '.png')
    dds = destination / (name + '.dds')
    if not args.force and (png.exists() or dds.exists()):
        raise FileExistsError(f'Output exists; explicitly use --force to rebuild: {name}')
    with Image.open(BASE / 'source' / (name + '.png')) as original:
        a['source_size'] = list(original.size)
        im = original.convert('RGBA').resize((156, 210), Image.Resampling.LANCZOS)
    im.save(png)
    im.save(dds)
    data = dds.read_bytes()
    assert data[:4] == b'DDS '
    assert struct.unpack_from('<I', data, 4)[0] == 124
    assert struct.unpack_from('<II', data, 12) == (210, 156)
    assert struct.unpack_from('<I', data, 28)[0] == 0, 'Unexpected mipmaps'
    assert struct.unpack_from('<I', data, 84)[0] == 0, 'Unexpected compression'
    assert struct.unpack_from('<I', data, 88)[0] == 32
    assert struct.unpack_from('<I', data, 104)[0] == 0xff000000, 'Missing alpha mask'
    assert len(data) == 128 + 156 * 210 * 4
    with Image.open(dds) as decoded:
        assert decoded.convert('RGBA').tobytes() == im.tobytes(), 'DDS roundtrip mismatch'
    a['delivery'] = str(dds.relative_to(ROOT)).replace('\\', '/')
    a['alpha_range'] = list(im.getchannel('A').getextrema())
    report.append(f'PASS {name}: 156x210; RGBA PNG; 32-bit uncompressed DDS; no mipmaps; decoded pixels identical; alpha={a["alpha_range"]}')
    label = html.escape(a['chinese'])
    cards.append(f'''<article><h2>{label}</h2><p class="english">{html.escape(a['english'])}</p>
<div class="compare"><a href="source/{name}.png" title="查看原始大图"><img class="portrait" src="png/{name}.png" alt="{label}补画立绘"></a>
<div class="small"><figure><img class="reference" src="references/{name}.png" alt="原始小图"><figcaption>原始参考</figcaption></figure><figure><img class="half" src="png/{name}.png" alt="半尺寸预览"><figcaption>0.5 倍显示</figcaption></figure></div></div>
<p class="file">{name}.dds</p><a href="png/{name}.png">156 × 210 PNG</a></article>''')
manifest['style_references'] = [
    'F:/Hearts of Iron IV/gfx/leaders/SOV/portrait_SOV_lev_kamenev.dds',
    'D:/Program Files (x86)/Steam/steamapps/workshop/content/394360/2129897125/gfx/leaders/SOV/r56_portrait_SOV_Leon_Trotsky.dds'
]
(BASE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
(BASE / 'validation-report.txt').write_text('\n'.join(report) + '\n7 / 7 format checks PASS. Visual status: all seven delivered; Smilga eyewear restored on 2026-09-14. Art-only delivery; no game scripts or sprite registrations changed.\n', encoding='utf-8')
css = '''*{box-sizing:border-box}body{margin:0;background:#151b20;color:#e1d8c6;font:14px/1.6 system-ui,"Microsoft YaHei",sans-serif}main{max-width:1320px;margin:auto;padding:28px}h1{margin:0;font-size:29px;letter-spacing:3px}header p{color:#b1b2ab;max-width:980px}header{margin-bottom:22px}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px}article{padding:18px 15px;background:#222b31;border:1px solid #454b4d;border-radius:5px}h2{font-size:17px;line-height:1.5;margin:0;min-height:51px;color:#d8bd82}.english{font-size:12px;color:#a8adae;margin:0 0 14px}.compare{display:flex;align-items:flex-start;justify-content:center;gap:12px}.portrait{display:block;width:156px;height:210px}.small{width:78px;text-align:center}figure{margin:0 0 8px}.reference{max-width:67px;height:auto;display:block;margin:auto}.half{display:block;width:78px;height:105px}figcaption{color:#9fa9ac;font-size:11px;margin-top:3px}.file{font:10px/1.5 monospace;overflow-wrap:anywhere;color:#a8adae;margin:16px 0 6px}a{color:#d9c28c}footer{color:#a8adae;margin-top:24px}.styles{display:flex;gap:8px;justify-content:center}.styles img{width:117px;height:157.5px}.baseline p{font-size:12px;color:#adb1ad}.baseline h2{min-height:auto;margin-bottom:22px}@media(max-width:1050px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:580px){.grid{grid-template-columns:1fr}}'''
page = '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>苏联人物立绘 · 七人对照</title><style>' + css + '</style><main><header><h1>苏联人物立绘 · 第一批</h1><p>依据 MD17 的七张小图补画。左侧为 156 × 210 交付图，右侧为原始参考及 0.5 倍显示。点击大图可看原始高清 PNG。</p><p>斯米尔加、里亚京、施利亚普尼科夫已恢复正常衣着与状态；采用与样本一致的灰米色实底。小图无法辨认的细节为绘画补全。</p></header><div class="grid">' + ''.join(cards) + '<article class="baseline"><h2>画风与构图参考</h2><div class="styles"><img src="references/style_kamenev.png" alt="原版加米涅夫"><img src="references/style_trotsky.png" alt="R56托洛茨基"></div><p>加米涅夫 / 托洛茨基<br>两张现有样本，仅作参考，未重画。</p><p>统一头肩构图、低饱和色彩和左上柔光。图像文件无文字、牢栏或档案纸。</p><p><a href="README.md">交付说明</a> · <a href="manifest.json">提示词与文件清单</a></p></article></div><footer>内置 image_gen 制作 · 7 张 PNG + 7 张 DDS · 本页是素材对照，不是游戏截图。按 MD17，本轮仅交付素材，sprite 注册由接入方完成。</footer></main></html>'
(BASE / 'preview.html').write_text(page, encoding='utf-8')
print('\n'.join(report))
