# -*- coding: utf-8 -*-
import os, subprocess, sys
os.chdir(r'd:\Users\xuwei\PycharmProjects\heart_of_Iron')
WS = os.getcwd()

def load(p):
    raw = open(p, 'rb').read()
    bom = raw[:3] == b'\xef\xbb\xbf'
    return bom, (raw[3:] if bom else raw).decode('utf-8').replace('\r\n', '\n')

def save(p, bom, s):
    open(p, 'wb').write((b'\xef\xbb\xbf' if bom else b'') + b'\r\n'.join(s.replace('\r', '').encode('utf-8').split(b'\n')))

P66 = 'docs/66-litvinov-focus-tree-design.md'
bom, s = load(P66)
old = ('| `mod/heart_of_iron/localisation/simp_chinese/hof_ic_l_simp_chinese.yml` | '
       '`hof_ic_franco_soviet_treaty:0 "苏法互助条约"`<br>`hof_ic_soviet_czech_treaty:0 "苏捷互助条约"` |')
assert s.count(old) == 1, s.count(old)
new = old + ('\n\n> ⚠️🚩 **两个文件的编码红线不同**（`AGENTS.md` 规则 3）：\n'
             '> · `common/opinion_modifiers/*.txt` = **UTF-8【不带】BOM**\n'
             '> · `localisation/simp_chinese/*.yml` = **UTF-8【带】BOM**，且**文件名的 `_l_simp_chinese` 后缀不能动**\n'
             '> · 两个文件**都已经存在**（托洛茨基「中国革命问题」那轮建的），本轮只是**在文件末尾追加**，'
             '**不要重写整个文件**（会动到 BOM）')
save(P66, bom, s.replace(old, new))
print('ok 编码红线注记')

# 清理临时脚本
for f in ['_lv66p1.py', '_lv66p2.py', '_lv66p3.py']:
    p = os.path.join('build', f)
    if os.path.exists(p):
        os.remove(p); print('rm', f)

# verify-docs
p = subprocess.run([r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe', '-NoProfile',
                    '-ExecutionPolicy', 'Bypass', '-File', os.path.join(WS, 'build', 'verify-docs.ps1')],
                   cwd=WS, capture_output=True)
o = (p.stdout + p.stderr).decode('utf-8', 'replace')
print('verify-docs rc', p.returncode)
print('\n'.join(l.encode('ascii', 'replace').decode() for l in o.splitlines() if '\u5931\u8d25' in l or 'FAIL' in l)[:2000])

# 行尾自查
for f in ['docs/65-litvinov-genealogy.md', 'docs/66-litvinov-focus-tree-design.md', 'docs/00-index.md']:
    r = open(f, 'rb').read()
    print('%-40s CRCRLF=%d bareLF=%d size=%d' % (f, r.count(b'\r\r\n'), r.count(b'\n') - r.count(b'\r\n'), len(r)))
