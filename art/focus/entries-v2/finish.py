"""Append MD28 art, use shared exporter, and prepare batch QA/preview."""
from pathlib import Path
import sys, json, runpy, contextlib, hashlib, re
ROOT = Path(__file__).resolve().parents[3]
ART = ROOT/'art/focus'
B = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tmp/art-python'))
from PIL import Image
plan=json.loads((B/'plan.json').read_text(encoding='utf-8'))
manifest=json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
old=json.loads((B/'previous-manifest.json').read_text(encoding='utf-8'))
for a in plan:
    name=a['name']
    source=B/'source'/f'{name}.png'
    im=Image.open(source)
    assert im.mode=='RGBA',name
    alpha=im.resize((100,88),Image.Resampling.LANCZOS).getchannel('A')
    assert .2<=sum(alpha.histogram()[:10])/8800<=.5,name
    if not any(x['name']==name for x in manifest['assets']):
        manifest['assets'].append({**a,'source':f'entries-v2/source/{name}.png','generation_record':f'entries-v2/records/{name}.json','reference':f'entries-v2/references/{a["key"]}.png'})
(ART/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
runpy.run_path(str(ART/'export_focus.py'),run_name='__main__')
for a in old['assets']:
    assert hashlib.sha256((ART/a['png']).read_bytes()).hexdigest()==a['sha256'],a['name']
with (B/'check-alpha-report.txt').open('w',encoding='utf-8') as f:
    with contextlib.redirect_stdout(f):
        runpy.run_path(str(ART/'check_alpha.py'),run_name='__main__')
preview=(ART/'preview.html').read_text(encoding='utf-8')
head=preview[:preview.index('<h2>')]
head=head.replace('核心圈 · 透明国策图标','MD28 · 15 位候选人入口图标').replace('href="manifest.json"','href="../manifest.json"')
cards=[]
for a in plan:
    card=next(c for c in re.findall(r'<article>.*?</article>',preview) if f'<code>{a["name"]}</code>' in c)
    card=card.replace('src="','src="../').replace('href="','href="../')
    cards.append(card)
(B/'preview.html').write_text(head+'<h2>红色与金色月桂 · 灰阶肖像</h2><section>'+''.join(cards)+'</section></html>',encoding='utf-8')
print(f'PASS: MD28 all {len(plan)} delivered; previous {len(old["assets"])} PNG hashes unchanged.')
