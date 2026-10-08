"""Read MD24 and decode the exact in-use portrait references for icon generation."""
from pathlib import Path
import sys, re, json
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[1]
sys.path.insert(0,str(ROOT/'tmp/art-python'))
from PIL import Image
for d in ['references','source','records']:
    (BASE/d).mkdir(parents=True,exist_ok=True)
doc=(ROOT/'docs/24-focus-icon-prompts.md').read_text(encoding='utf-8-sig')
entries=re.findall(r'\| [1-7] \| `(hof_ic_seat_[^`]+)` \| ([^|]+) \| ([^|]+) \|',doc)
specials=re.findall(r'\*\*`(hof_ic_trotsky_[^`]+)` ｜ ([^*]+)\*\*\s*\n> ([^\n]+)',doc)
assert len(entries)==7 and len(specials)==17
gfx=(ROOT/'mod/heart_of_iron/interface/hof_ic_portraits.gfx').read_text(encoding='utf-8-sig')
portrait_paths=dict(re.findall(r'name\s*=\s*"GFX_hof_ic_portrait_([^"]+)"\s*texturefile\s*=\s*"([^"]+)"',gfx))
game=Path('F:/Hearts of Iron IV')
r56=Path('D:/Program Files (x86)/Steam/steamapps/workshop/content/394360/2129897125')
assets=[]
for ident,title,role in entries:
    key=ident.removeprefix('hof_ic_seat_')
    rel=portrait_paths[key]
    candidates=[ROOT/'mod/heart_of_iron'/rel,r56/rel]+[p/rel for p in sorted((game/'dlc').iterdir(),reverse=True) if p.is_dir()]+[game/rel]
    source=next(p for p in candidates if p.is_file())
    with Image.open(source) as im:
        assert im.size==(156,210),(source,im.size)
        im.convert('RGBA').save(BASE/'references'/f'{key}.png')
    assets.append(dict(id=ident,name='GFX_'+ident,title=title.strip(),group='entry',description=role.strip(),portrait_source=str(source),reference=f'references/{key}.png'))
    print(key,source)
for ident,title,desc in specials:
    assets.append(dict(id=ident,name='GFX_'+ident,title=title.strip(),group='trotsky',description=desc))
for a in assets:
    a.update(size=[100,88],status='pending')
manifest=BASE/'manifest.json'
if manifest.exists():
    raise FileExistsError('Manifest already exists; preserve progress')
manifest.write_text(json.dumps(dict(mode='built-in image_gen',assets=assets),ensure_ascii=False,indent=2),encoding='utf-8')
print('24 icon specifications prepared')
