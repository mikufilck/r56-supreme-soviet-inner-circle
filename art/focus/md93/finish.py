"""Install MD93 Radek and Tukhachevsky expansion icons."""
from pathlib import Path
import contextlib
import hashlib
import json
import re
import runpy
import sys

BASE = Path(__file__).resolve().parent
ART = BASE.parent
ROOT = ART.parents[1]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

plan = json.loads((BASE / 'plan.json').read_text(encoding='utf-8'))
doc = (ROOT / 'docs/93-radek-china-and-tukh-b-icon-prompts.md').read_text(encoding='utf-8-sig')
name_table = doc.split('## §0 命名对照')[1].split('\n---\n')[0]
expected = set(re.findall(r'GFX_hof_ic_(?:radek|tukhachevsky)_\w+', name_table))
assert len(plan) == 6 and expected == {asset['name'] for asset in plan}

manifest_path = ART / 'manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
old = json.loads((BASE / 'previous-manifest.json').read_text(encoding='utf-8'))
for asset in plan:
    image = Image.open(BASE / 'source' / f"{asset['name']}.png")
    assert image.mode == 'RGBA', asset['name']
    alpha = image.resize((100, 88), Image.Resampling.LANCZOS).getchannel('A')
    assert 0.20 <= sum(alpha.histogram()[:10]) / 8800 <= 0.50, asset['name']
    if not any(existing['name'] == asset['name'] for existing in manifest['assets']):
        manifest['assets'].append({
            **asset,
            'png': f"md93/{asset['name']}.png",
            'source': f"md93/source/{asset['name']}.png",
            'generation_record': f"md93/records/{asset['name']}.json",
        })
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
runpy.run_path(str(ART / 'export_focus.py'), run_name='__main__')

for asset in old['assets']:
    digest = hashlib.sha256((ART / asset['png']).read_bytes()).hexdigest()
    assert digest == asset['sha256'], asset['name']
with (BASE / 'check-alpha-report.txt').open('w', encoding='utf-8') as output:
    with contextlib.redirect_stdout(output):
        runpy.run_path(str(ART / 'check_alpha.py'), run_name='__main__')

preview = (ART / 'preview.html').read_text(encoding='utf-8')
head = preview[:preview.index('<h2>')].replace('href="manifest.json"', 'href="../manifest.json"')
head = re.sub(r'<h1>.*?</h1>', '<h1>MD93 · 两条扩线新增图标</h1>', head, count=1)
cards = []
for asset in plan:
    card = next(section for section in re.findall(r'<article>.*?</article>', preview)
                if f"<code>{asset['name']}</code>" in section)
    cards.append(card.replace('src="', 'src="../').replace('href="', 'href="../'))
(BASE / 'preview.html').write_text(
    head + '<h2>拉狄克 · 从纸面看中国</h2><section>'
    + ''.join(cards[:3]) + '</section><h2>图哈切夫斯基 · 桌上的国家账</h2><section>'
    + ''.join(cards[3:]) + '</section></html>', encoding='utf-8')
print(f"PASS: six MD93 icons; prior {len(old['assets'])} PNG hashes unchanged.")
