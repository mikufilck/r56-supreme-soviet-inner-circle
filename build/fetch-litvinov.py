# -*- coding: utf-8 -*-
"""李维诺夫（Idx 15）第 0 步补扫 · 一手/二手材料抓取"""
import os, re, json, time, urllib.request, urllib.error

WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'litvinov')
for d in [DST, os.path.join(DST, 'txt'), os.path.join(DST, 'inst')]:
    os.makedirs(d, exist_ok=True)

PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]

def get(url, timeout=40):
    try:
        with OP.open(url, timeout=timeout) as r:
            return r.read()
    except Exception as e:
        return ('ERR:' + str(e)).encode('utf-8')

def strip_html(b):
    s = b.decode('utf-8', 'replace')
    s = re.sub(r'(?is)<(script|style|sup|table)[^>]*>.*?</\1>', ' ', s)
    s = re.sub(r'(?s)<[^>]+>', ' ', s)
    s = re.sub(r'&nbsp;', ' ', s)
    s = re.sub(r'&lt;', '<', s); s = re.sub(r'&gt;', '>', s); s = re.sub(r'&amp;', '&', s)
    s = re.sub(r'&#(\d+);', lambda m: chr(int(m.group(1))), s)
    s = re.sub(r'[ \t\xa0]+', ' ', s)
    s = re.sub(r'\n\s*\n+', '\n\n', s)
    return s.strip()

def wiki(lang, title, out):
    url = 'https://%s.wikipedia.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title))
    b = get(url)
    if b.startswith(b'ERR'):
        print('  FAIL', lang, title, b[:120])
        return 0
    t = strip_html(b)
    open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(t)
    print('  ok', out, len(t))
    return len(t)

import urllib.parse
jobs = [
    ('zh', '马克西姆·李维诺夫', 'zh-wiki.txt'),
    ('en', 'Maxim Litvinov', 'en-wiki.txt'),
    ('ru', 'Литвинов, Максим Максимович', 'ru-wiki.txt'),
    ('ru', 'Народный комиссариат по иностранным делам', 'ru-nkid.txt'),
    ('zh', '苏联外交人民委员部', 'zh-nkid.txt'),
    ('zh', '李维诺夫协定', 'zh-protocol.txt'),
    ('en', 'Litvinov Protocol', 'en-protocol.txt'),
    ('en', 'Litvinov Pact', 'en-pact.txt'),
]
print('== Wikipedia ==')
for lang, title, out in jobs:
    wiki(lang, title, out)
    time.sleep(0.6)

print('== 中文马克思主义文库索引（找他的篇目页）==')
for u, out in [('https://www.marxists.org/chinese/reference-books/index.htm', 'mia-cn-index.txt'),
               ('https://www.marxists.org/chinese/index.html', 'mia-cn-home.txt')]:
    b = get(u)
    if b.startswith(b'ERR'):
        print('  FAIL', u, b[:120]); continue
    open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(b.decode('utf-8', 'replace'))
    print('  ok', out, len(b))
    time.sleep(0.5)

print('== MIA 英文 archive 里他的页 ==')
b = get('https://www.marxists.org/archive/litvinov/index.htm')
if b.startswith(b'ERR'):
    print('  FAIL litvinov index', b[:160])
else:
    open(os.path.join(DST, 'txt', 'mia-en-litvinov-index.htm'), 'wb').write(b)
    print('  ok mia-en-litvinov-index.htm', len(b))

print('done')
