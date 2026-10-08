from pathlib import Path
import json, re, shutil
ART=Path(__file__).resolve().parents[1]
ROOT=ART.parents[1]
manifest=json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
batch=json.loads((ART/'bukharin/plan.json').read_text(encoding='utf-8'))
expected=set(re.findall(r'GFX_hof_ic_bukharin_[a-z_]+',(ROOT/'docs/27-bukharin-focus-icon-prompts.md').read_text(encoding='utf-8')))
expected.discard('GFX_hof_ic_bukharin_')
assert {a['name'] for a in batch}==expected and len(batch)==9
backup=ART/'bukharin/previous-manifest.json'
if not backup.exists():shutil.copy2(ART/'manifest.json',backup)
existing={a['id'] for a in manifest['assets']}
manifest['assets'].extend(a for a in batch if a['id'] not in existing)
(ART/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('MD27 exact ID check passed; batch appended.')
