"""Prepare MD28 reference decodes and a resumable art plan."""
from pathlib import Path
import sys, json, re, shutil
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT/'tmp/art-python'))
from PIL import Image
B = Path(__file__).resolve().parent
for d in ['source','records','references']:
    (B/d).mkdir(parents=True, exist_ok=True)
rows = re.findall(r'\| \d+ \| `(GFX_hof_ic_seat_([^`]+))` \| ([^|]+) \|', (ROOT/'docs/28-entry-focus-icon-prompts.md').read_text(encoding='utf-8'))
concepts = ['a ledger and wheat feeding a small factory','a golden speaking trumpet and folded blank newspaper','a gear and rising economic bar chart','a red trade union banner on a gear','a thick blank manuscript with wheat','a large steel wrench across a metalworking gear','a modest medal ribbon with wheat ears','a globe with a blank treaty scroll','gold bullion and an open treasury ledger','a marshal star above tank tracks, mechanized warfare','a planning chart with a factory silhouette','a prominent naval anchor','an archive card drawer and small aircraft silhouette','wheat ears crossed with a metalworker wrench','crossed cavalry sabres and a small horse head']
van=Path('F:/Hearts of Iron IV/gfx/leaders/SOV')
r56=Path('D:/Program Files (x86)/Steam/steamapps/workshop/content/394360/2129897125/gfx/leaders/SOV')
extra={'mikhail_tukhachevsky':van/'Portrait_Soviet_Mikhail_Tukhachevsky.dds','georgy_malenkow':r56/'r56_portrait_SOV_Georgy_Malenkov.dds','nikita_khrushchyov':r56/'r56_portrait_SOV_Nikita_Khrushchev.dds','kliment_voroshilov':van/'Portrait_Soviet_Kliment_Voroshilov.dds'}
plan=[]
for i,(name,key,title) in enumerate(rows):
    candidates=[ROOT/f'art/portraits/{v}/png/hof_portrait_SOV_{key}.png' for v in ['v1','v2']]
    src=next((p for p in candidates if p.exists()),extra.get(key))
    assert src and src.exists(), key
    ref=B/'references'/f'{key}.png'
    Image.open(src).convert('RGBA').save(ref)
    plan.append(dict(name=name,id=name[4:],key=key,title=title.strip(),group='entry',portrait_source=str(src),reference=str(ref),concept=concepts[i],size=[100,88]))
assert len(plan)==15
(B/'plan.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
if not (B/'previous-manifest.json').exists():
    shutil.copy2(ROOT/'art/focus/manifest.json',B/'previous-manifest.json')
print('Prepared 15 exact portrait references')
