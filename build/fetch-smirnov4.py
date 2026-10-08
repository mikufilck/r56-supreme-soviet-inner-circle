# -*- coding: utf-8 -*-
"""彼得·斯米尔诺夫（Idx 19）第 4 轮：抓 1937-12-30 决议原文（一手件）"""
import os, re, time, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'smirnov')
os.makedirs(os.path.join(DST, 'txt'), exist_ok=True)
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]


def get(url, timeout=45):
    last = None
    for _ in range(2):
        try:
            with OP.open(url, timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e
            time.sleep(5)
    return ('ERR:' + str(last)).encode('utf-8')


def strip_html(b):
    s = b.decode('utf-8', 'replace')
    s = re.sub(r'(?is)<(script|style|sup|table)[^>]*>.*?</\1>', ' ', s)
    s = re.sub(r'(?s)<[^>]+>', ' ', s)
    s = re.sub(r'&#(\d+);', lambda m: chr(int(m.group(1))), s)
    for a, b2 in [('&nbsp;', ' '), ('&lt;', '<'), ('&gt;', '>'), ('&amp;', '&'), ('&quot;', '"')]:
        s = s.replace(a, b2)
    s = re.sub(r'[ \t\xa0]+', ' ', s)
    s = re.sub(r'\n\s*\n+', '\n\n', s)
    return s.strip()


JOBS = [
    ('ru', 'Постановление ЦИК и СНК СССР от 30.12.1937 об образовании народного комиссариата военно-морского флота СССР',
     'ru-decree-19371230.txt'),
]
rep = []
for lang, title, out in JOBS:
    u = 'https://%s.wikisource.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title))
    b = get(u)
    if b.startswith(b'ERR'):
        # 退回搜索
        su = ('https://%s.wikisource.org/w/api.php?action=query&list=search&srsearch=%s'
              '&srlimit=8&format=json' % (lang, urllib.parse.quote('наркомат военно-морского флота 1937')))
        b2 = get(su)
        rep.append('FAIL  %-30s %s' % (out, b[:60]))
        if not b2.startswith(b'ERR'):
            open(os.path.join(DST, 'txt', 'search-ws-ru.txt'), 'wb').write(b2)
            rep.append('ok    search-ws-ru')
    else:
        t = strip_html(b)
        open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(t)
        rep.append('ok    %-30s %d' % (out, len(t)))
    time.sleep(6)

open(os.path.join(WS, 'build', 'fetch-smirnov4-report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
print('\n'.join(rep).encode('ascii', 'backslashreplace').decode())
