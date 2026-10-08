"""Decode the supplied DDS references, without altering their artwork."""
from pathlib import Path
import re
import sys
import json

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

spec = (ROOT / 'docs/17-art-spec-portraits.md').read_text(encoding='utf-8-sig')
section = spec.split('## 3.')[1].split('## 4.')[0]
assets = []
out = Path(__file__).resolve().parent / 'references'
out.mkdir(parents=True, exist_ok=True)
for line in section.splitlines():
    if not re.match(r'\| [1-7] \|', line):
        continue
    cells = [s.strip() for s in line.strip('|').split('|')]
    source = Path(cells[3].strip('`'))
    name = Path(cells[4].strip('`')).stem
    with Image.open(source) as im:
        im.convert('RGBA').save(out / (name + '.png'))
        print(name, im.size, im.mode)
    assets.append(dict(name=name, english=cells[1], chinese=cells[2], reference=str(source), size=[156,210]))
with Image.open(Path('F:/Hearts of Iron IV/gfx/leaders/SOV/portrait_SOV_lev_kamenev.dds')) as im:
    im.convert('RGBA').save(out / 'style_kamenev.png')
    print('style_kamenev', im.size)
(out.parent / 'manifest.json').write_text(json.dumps(dict(mode='built-in image_gen', assets=assets), ensure_ascii=False, indent=2), encoding='utf-8')
