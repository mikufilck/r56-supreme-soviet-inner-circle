# -*- coding: utf-8 -*-
"""SOP 第 0/1 步材料抓取 · 第二批 —— 赫鲁晓夫的英文 MIA 全文（HTML 那些）
产物目录：tmp/khrushchev/txt/
用法：python build/fetch-khrushchev2.py
"""
import os, re, time, urllib.request

WS   = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
OUT  = os.path.join(WS, 'tmp', 'khrushchev', 'txt')
PROXY = 'http://127.0.0.1:7993'
BASE = 'https://www.marxists.org/archive/khrushchev/'
os.makedirs(OUT, exist_ok=True)

_op = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
_op.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]


def get(url, tries=3, timeout=30):
    last = None
    for i in range(tries):
        try:
            return _op.open(url, timeout=timeout).read()
        except Exception as e:                      # noqa: BLE001
            last = e
            time.sleep(2 + 2 * i)
    raise last


def dec(b):
    for enc in ('utf-8', 'iso-8859-1', 'gb18030'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            continue
    return b.decode('utf-8', 'replace')


def save(name, text):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    print('  -> %-40s %8d chars' % (name, len(text)))


def html2txt(h):
    h = re.sub(r'(?is)<(script|style|sup)[^>]*>.*?</\1>', ' ', h)
    h = re.sub(r'(?i)<br\s*/?>', '\n', h)
    h = re.sub(r'(?i)</(p|div|li|h[1-6]|tr)>', '\n', h)
    h = re.sub(r'(?s)<[^>]+>', '', h)
    h = (h.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&lt;', '<')
          .replace('&gt;', '>').replace('&quot;', '"').replace('&#39;', "'"))
    h = re.sub(r'[ \t\u00a0]+', ' ', h)
    h = re.sub(r'\n\s*\n\s*\n+', '\n\n', h)
    # marxists.org 的中文页常见「节选」提示行，保留
    return h.strip()


PAGES = [
    ('1956/02/24.htm',      'mia-1956-02-24-secret-speech.txt', '秘密报告全文（英）'),
    ('1956/02/24-abs.htm',  'mia-1956-02-24-abstract.txt',      '秘密报告摘要（英）'),
    ('1961/04/18.htm',      'mia-1961-04-18.txt',               '1961-04-18'),
    ('1961/04/22.htm',      'mia-1961-04-22.txt',               '1961-04-22'),
    ('1962/09/28.htm',      'mia-1962-09-28.txt',               '1962-09-28'),
    ('1962/10/23.htm',      'mia-1962-10-23.txt',               '1962-10-23'),
    ('1962/10/24.htm',      'mia-1962-10-24.txt',               '1962-10-24'),
    ('1962/10/26.htm',      'mia-1962-10-26.txt',               '1962-10-26'),
    ('1962/10/27.htm',      'mia-1962-10-27.txt',               '1962-10-27'),
    ('../../reference/archive/dimitrov/obituary.htm',
                            'mia-1949-dimitrov-obituary.txt',   '1949-07 季米特洛夫悼词'),
]

print('== 英文 MIA 全文（HTML）==')
for rel, fname, tag in PAGES:
    u = BASE + rel
    try:
        b = get(u)
        t = html2txt(dec(b))
        if len(t) < 400:
            print('   太短 (%d): %s' % (len(t), u)); continue
        save(fname, t)
        print('      [%s]' % tag)
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# --- 中文文库里的《赫鲁晓夫回忆录》/ 反斯大林报告 候选（再试一批命名）---
print('== 中文文库候选（再试）==')
CN = [
    'https://www.marxists.org/chinese/reference-books/1964-khrushchev/index.htm',
    'https://www.marxists.org/chinese/reference-books/khrushchev-1970/index.htm',
    'https://www.marxists.org/chinese/reference-books/khrushchev-remembers/index.htm',
    'https://www.marxists.org/chinese/khrushchov/index.htm',
    'https://www.marxists.org/chinese/reference-books/mia-chinese-khrushchev.htm',
]
for u in CN:
    try:
        t = dec(get(u, tries=1))
        if len(t) < 900:
            print('   太短 (%d): %s' % (len(t), u)); continue
        tag = re.sub(r'[^a-zA-Z0-9]+', '-', u.split('chinese/')[1])[:60]
        save('mia-cn-' + tag + '.txt', t)
        print('   命中！%s' % u)
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

print('== 完成 ->', OUT)
