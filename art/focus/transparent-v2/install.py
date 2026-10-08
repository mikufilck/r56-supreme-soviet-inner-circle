"""Preflight all generated alpha assets, archive old exports, update source pointers."""
from pathlib import Path
import sys, json, shutil
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT / 'tmp/art-python'))
from PIL import Image
ART = ROOT / 'art/focus'
V2 = Path(__file__).resolve().parent
manifest = json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
for a in manifest['assets']:
    with Image.open(V2/'source'/(a['name']+'.png')) as im:
        assert im.mode == 'RGBA' and im.getchannel('A').getextrema() == (0,255), a['name']
backup = V2/'previous-opaque'
if not backup.exists():
    backup.mkdir()
    for f in ['manifest.json','validation.json','README.md','preview.html','preview.png']:
        shutil.copy2(ART/f,backup/f)
    for a in manifest['assets']:
        shutil.copy2(ART/a['png'],backup/a['png'])
        shutil.copy2(ROOT/a['dds'],backup/Path(a['dds']).name)
for a in manifest['assets']:
    a['source']='transparent-v2/source/'+a['name']+'.png'
    a['generation_record']='transparent-v2/records/'+a['name']+'.json'
(ART/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('24 generated RGBA sources verified; backup preserved; source pointers updated.')
