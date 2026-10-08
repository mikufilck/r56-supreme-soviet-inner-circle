# -*- coding: utf-8 -*-
import os, re, time, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'litvinov', 'txt')
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]

def get(url, timeout=45):
    for attempt in range(3):
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
    b = get('https://%s.wikipedia.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title)))
    if b.startswith(b'ERR'):
        print('  FAIL', lang, title, b[:90]); return
    t = strip_html(b)
    open(os.path.join(DST, out), 'w', encoding='utf-8').write(t)
    print('  ok', out, len(t))

print('== 补抓 wiki ==')
for lang, title, out in [
    ('ru', 'Народный комиссариат иностранных дел СССР', 'ru-nkid.txt'),
    ('zh', '苏联外交人民委员部', 'zh-nkid.txt'),
    ('zh', '李维诺夫协定', 'zh-protocol.txt'),
    ('en', 'Litvinov Protocol', 'en-protocol.txt'),
    ('en', 'Franco-Soviet Treaty of Mutual Assistance', 'en-fr-sov-pact.txt'),
    ('ru', 'Договор о ненападении между Германией и Советским Союзом', 'ru-mr-pact.txt'),
    ('zh', '集体安全', 'zh-collective-security.txt'),
    ('ru', 'Коллективная безопасность', 'ru-collective-security.txt'),
]:
    wiki(lang, title, out)
    time.sleep(3)

print('== MIA 搜索 ==')
for u, out in [
    ('https://www.marxists.org/archive/index.htm', 'mia-en-archive-index.txt'),
    ('https://www.marxists.org/chinese/reference-books/mia-chinese-m-lenin-1900/index.htm', 'mia-lenin-idx.txt'),
]:
    b = get(u)
    if b.startswith(b'ERR'):
        print('  FAIL', u, b[:90]); continue
    open(os.path.join(DST, out), 'w', encoding='utf-8').write(strip_html(b))
    print('  ok', out, len(b))
    time.sleep(2)
print('done')
