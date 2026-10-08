# -*- coding: utf-8 -*-
"""彼得·斯米尔诺夫（Idx 19）第 0 步 · 第二轮（补 429 失败项 + 建制/舰队背景）"""
import os, re, time, json, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'smirnov')
os.makedirs(os.path.join(DST, 'txt'), exist_ok=True)
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]


def get(url, timeout=60):
    last = None
    for i in range(4):
        try:
            with OP.open(url, timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e
            time.sleep(12 + 10 * i)
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


def raw(url, out, enc=None):
    b = get(url)
    if b.startswith(b'ERR'):
        return 'FAIL  %-34s %s' % (out, b[:80])
    open(os.path.join(DST, 'txt', out), 'wb').write(b)
    return 'ok    %-34s %d' % (out, len(b))


JOBS = [
    ('ru', 'Смирнов-Светловский, Пётр Иванович', 'ru-svetlovsky.txt'),
    ('ru', 'Рабоче-Крестьянский Красный Флот', 'ru-rkkf.txt'),
    ('ru', 'Народный комиссариат Военно-Морского Флота СССР', 'ru-nkomvmf.txt'),
    ('ru', 'Политическое управление РККА', 'ru-pur.txt'),
    ('ru', 'Кронштадтское восстание', 'ru-kronstadt.txt'),
    ('zh', '苏联海军', 'zh-navy.txt'),
    ('zh', '苏联海军人民委员部', 'zh-nkomvmf.txt'),
    ('zh', '大清洗', 'zh-purge.txt'),
    ('ru', 'Сталинские репрессии в РККА', 'ru-repress-rkka.txt'),
]
rep = []
for lang, title, out in JOBS:
    rep.append(wiki(lang, title, out))
    time.sleep(8)

# 中文马克思主义文库：他有没有篇目页？
for out, url in [
    ('mia-cn-smirnov.html', 'https://www.marxists.org/chinese/smirnov/index.htm'),
    ('mia-cn-index.html',   'https://www.marxists.org/chinese/index.htm'),
]:
    b = get(url)
    if b.startswith(b'ERR'):
        rep.append('FAIL  %-34s %s' % (out, b[:80]))
    else:
        open(os.path.join(DST, out), 'wb').write(b)
        rep.append('ok    %-34s %d' % (out, len(b)))
    time.sleep(8)

open(os.path.join(WS, 'build', 'fetch-smirnov2-report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
print('\n'.join(rep).encode('ascii', 'backslashreplace').decode())
