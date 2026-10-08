# -*- coding: utf-8 -*-
"""彼得·斯米尔诺夫（Idx 19）第 0 步 · 第三轮（收尾：中文文库探页 + 两条补漏）"""
import os, re, time, urllib.request, urllib.parse
WS = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
DST = os.path.join(WS, 'tmp', 'smirnov')
os.makedirs(os.path.join(DST, 'txt'), exist_ok=True)
PROXY = '127.0.0.1:7993'
OP = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
OP.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]


def get(url, timeout=45, tries=2):
    last = None
    for i in range(tries):
        try:
            with OP.open(url, timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e
            time.sleep(6)
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


rep = []

# 1) 中文马克思主义文库：姓名索引与总索引（探他有没有篇目页）
for out, url in [
    ('mia-cn-names.txt', 'https://www.marxists.org/chinese/maoist/nameindex.htm'),
    ('mia-cn-index.html', 'https://www.marxists.org/chinese/index.html'),
    ('mia-cn-smirnov.html', 'https://www.marxists.org/chinese/smirnov/index.htm'),
]:
    b = get(url)
    if b.startswith(b'ERR'):
        rep.append('FAIL  %-24s %s' % (out, b[:70]))
    else:
        open(os.path.join(DST, out), 'wb').write(b)
        rep.append('ok    %-24s %d' % (out, len(b)))
    time.sleep(5)

# 2) 补漏
for lang, title, out in [
    ('zh', '苏联海军人民委员部', 'zh-nkomvmf.txt'),
    ('ru', 'Сталинские репрессии в РККА', 'ru-repress-rkka.txt'),
]:
    b = get('https://%s.wikipedia.org/api/rest_v1/page/html/%s' % (lang, urllib.parse.quote(title)))
    if b.startswith(b'ERR'):
        rep.append('FAIL  %-24s %s' % (out, b[:70]))
    else:
        t = strip_html(b)
        open(os.path.join(DST, 'txt', out), 'w', encoding='utf-8').write(t)
        rep.append('ok    %-24s %d' % (out, len(t)))
    time.sleep(5)

open(os.path.join(WS, 'build', 'fetch-smirnov3-report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
print('\n'.join(rep).encode('ascii', 'backslashreplace').decode())
