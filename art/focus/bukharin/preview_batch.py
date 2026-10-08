from pathlib import Path
import sys, runpy, contextlib
ART=Path(__file__).resolve().parents[1]
ROOT=ART.parents[1]
s=(ART/'preview.html').read_text(encoding='utf-8')
s=s.split('<h2>')[0]+'<h2>布哈林专属'+s.split('<h2>布哈林专属',1)[1]
s=s.replace('src="','src="../').replace('href="','href="../')
(ART/'bukharin/preview.html').write_text(s,encoding='utf-8')
sys.path.insert(0,str(ROOT/'tmp/art-python'))
with (ART/'bukharin/check-alpha-report.txt').open('w',encoding='utf-8') as f:
    with contextlib.redirect_stdout(f):
        runpy.run_path(str(ART/'check_alpha.py'),run_name='__main__')
