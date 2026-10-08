# -*- coding: utf-8 -*-
"""彼得·斯米尔诺夫（Idx 19）第 0 步 · 一手/二手材料抓取

⚠️ 注意与伊万·斯米尔诺夫（Idx 6）同名 —— 所有材料都要逐条分人。
"""
import os, re, time, json, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'smirnov')
for d in [DST, os.path.join(DST, 'txt')]:
    os.makedirs(d, exist_ok=True)
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')

                ]


def get(url, timeout=45):
    last = None
    for _ in range(3):
        try:
            with OP.open(url, timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e
            time.sleep(4)
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


def wiki(lang, title, out):
    u = 'https://%s.wikipedia.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title))
    b = get(u)
    if b.startswith(b'ERR'):
        return 'FAIL  %-34s %s' % (out, b[:80])
    t = strip_html(b)
    open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(t)
    return 'ok    %-34s %d' % (out, len(t))


def search(lang, q, out):
    u = ('https://%s.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s'
         '&srlimit=12&format=json' % (lang, urllib.parse.quote(q)))
    b = get(u)
    if b.startswith(b'ERR'):
        return 'FAIL  search %-28s %s' % (out, b[:80])
    try:
        j = json.loads(b.decode('utf-8', 'replace'))
        hits = j.get('query', {}).get('search', [])
    except Exception as e:
        return 'FAIL  search %-28s %s' % (out, e)
    lines = ['### %s : %s' % (lang, q)]
    for h in hits:
        lines.append('   %-55s %s' % (h['title'], re.sub(r'<[^>]+>', '', h.get('snippet', ''))))
    txt = '\n'.join(lines)
    open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(txt)
    return 'ok    search %-28s %d' % (out, len(hits))


JOBS = [
    ('ru', 'Смирнов, Пётр Александрович', 'ru-wiki.txt'),
    ('en', 'Pyotr Smirnov', 'en-wiki.txt'),
    ('en', 'Pyotr Aleksandrovich Smirnov', 'en-wiki2.txt'),
    ('zh', '彼得·斯米尔诺夫', 'zh-wiki.txt'),
    ('ru', 'Смирнов, Иван Никитич', 'ru-wiki-ivan.txt'),
    ('ru', 'Народный комиссариат Военно-Морского Флота СССР', 'ru-nkomvmf.txt'),
    ('ru', 'Политическое управление РККА', 'ru-pur.txt'),
    ('ru', 'Военный совет при народном комиссаре обороны СССР', 'ru-vs.txt'),
    ('ru', 'Сталинские репрессии в РККФ', 'ru-repress-navy.txt'),
]

rep = []
for lang, title, out in JOBS:
    rep.append(wiki(lang, title, out))
    time.sleep(2)

SEARCHES = [
    ('ru', 'Смирнов Пётр Александрович нарком ВМФ', 'search-ru-1.txt'),
    ('ru', 'Смирнов Пётр Александрович 1897 1939', 'search-ru-2.txt'),
    ('zh', '彼得·斯米尔诺夫 海军人民委员', 'search-zh-1.txt'),
    ('en', 'Pyotr Smirnov Soviet admiral commissar', 'search-en-1.txt'),
]
for lang, q, out in SEARCHES:
    rep.append(search(lang, q, out))
    time.sleep(2)

open(os.path.join(WS, 'build', 'fetch-smirnov-report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
print('\n'.join(rep).encode('ascii', 'backslashreplace').decode())
