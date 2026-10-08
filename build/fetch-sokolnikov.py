# -*- coding: utf-8 -*-
"""索柯里尼柯夫（Idx 16）第 0 步 · 一手/二手材料抓取"""
import os, re, time, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'sokolnikov')
for d in [DST, os.path.join(DST, 'txt')]:
    os.makedirs(d, exist_ok=True)
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]

def get(url, timeout=45):
    last = None
    for _ in range(3):
        try:
            with OP.open(url, timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e; time.sleep(4)
    return ('ERR:' + str(last)).encode('utf-8')

def strip_html(b):
    s = b.decode('utf-8', 'replace')
    s = re.sub(r'(?is)<(script|style|sup|table)[^>]*>.*?</\1>', ' ', s)
    s = re.sub(r'(?s)<[^>]+>', ' ', s)
    s = re.sub(r'&#(\d+);', lambda m: chr(int(m.group(1))), s)
    for a, b2 in [('&nbsp;', ' '), ('&lt;', '<'), ('&gt;', '>'), ('&amp;', '&'), ('&quot;', '"')]:
        s = s.replace(a, b2)
    s = re.sub(r'[ \t\xa0]+', ' ', s); s = re.sub(r'\n\s*\n+', '\n\n', s)
    return s.strip()

def wiki(lang, title, out):
    u = 'https://%s.wikipedia.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title))
    b = get(u)
    if b.startswith(b'ERR'):
        return 'FAIL  %-30s %s' % (out, b[:60])
    t = strip_html(b)
    open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(t)
    return 'ok    %-30s %d' % (out, len(t))

JOBS = [
    ('zh', '格里戈里·索柯里尼柯夫', 'zh-wiki.txt'),
    ('en', 'Grigori Sokolnikov', 'en-wiki.txt'),
    ('ru', 'Сокольников, Григорий Яковлевич', 'ru-wiki.txt'),
    ('ru', 'Червонец', 'ru-chervonets.txt'),
    ('zh', '切尔沃涅茨', 'zh-chervonets.txt'),
    ('en', 'Soviet ruble', 'en-ruble.txt'),
    ('ru', 'Денежная реформа в СССР (1922—1924)', 'ru-reform.txt'),
    ('en', 'Brest-Litovsk', 'en-brest.txt'),
]
rep = []
for lang, title, out in JOBS:
    rep.append(wiki(lang, title, out)); time.sleep(2)
open(os.path.join(WS, 'build', 'fetch-sokolnikov-report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
print('\n'.join(rep).encode('ascii','backslashreplace').decode())
