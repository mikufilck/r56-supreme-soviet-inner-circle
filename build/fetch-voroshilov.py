# -*- coding: utf-8 -*-
"""SOP 第 0/1 步材料抓取 —— 克里门特·伏罗希洛夫（花名册 Idx 22，regime 营）—— 最后一位
产物目录：tmp/voroshilov/txt/
用法：python build/fetch-voroshilov.py
"""
import os, re, json, time, urllib.request, urllib.parse

WS   = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
OUT  = os.path.join(WS, 'tmp', 'voroshilov', 'txt')
PROXY = 'http://127.0.0.1:7993'
os.makedirs(OUT, exist_ok=True)

_op = urllib.request.build_opener(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
_op.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')]


def get(url, tries=3, timeout=25):
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
    print('  -> %-34s %8d chars' % (name, len(text)))


def html2txt(h):
    h = re.sub(r'(?is)<(script|style|sup)[^>]*>.*?</\1>', ' ', h)
    h = re.sub(r'(?i)<br\s*/?>', '\n', h)
    h = re.sub(r'(?i)</(p|div|li|h[1-6]|tr)>', '\n', h)
    h = re.sub(r'(?s)<[^>]+>', '', h)
    h = (h.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&lt;', '<')
          .replace('&gt;', '>').replace('&quot;', '"').replace('&#39;', "'"))
    h = re.sub(r'[ \t\u00a0]+', ' ', h)
    h = re.sub(r'\n\s*\n\s*\n+', '\n\n', h)
    return h.strip()


# ---------------------------------------------------------------- 1. 维基三条
WIKI = [
    ('ru', 'Ворошилов,_Климент_Ефремович', 'ru-wiki.txt'),
    ('en', 'Kliment_Voroshilov',            'en-wiki.txt'),
    ('zh', '克利缅特·伏罗希洛夫',            'zh-wiki.txt'),
]

print('== 1. 维基全文 ==')
for lang, title, fname in WIKI:
    try:
        url = ('https://%s.wikipedia.org/w/api.php?action=query&prop=extracts'
               '&explaintext=1&exlimit=1&redirects=1&format=json&titles=%s'
               % (lang, urllib.parse.quote(title)))
        js = json.loads(get(url).decode('utf-8'))
        pg = list(js['query']['pages'].values())[0]
        txt = pg.get('extract') or ''
        if len(txt) < 300:
            s = ('https://%s.wikipedia.org/w/api.php?action=query&list=search'
                 '&format=json&srlimit=5&srsearch=%s'
                 % (lang, urllib.parse.quote(title.replace('_', ' '))))
            sj = json.loads(get(s).decode('utf-8'))
            hits = [x['title'] for x in sj['query']['search']]
            print('   [%s] 直查太短(%d)，search 命中：%s' % (lang, len(txt), hits))
            if hits:
                url2 = ('https://%s.wikipedia.org/w/api.php?action=query&prop=extracts'
                        '&explaintext=1&exlimit=1&redirects=1&format=json&titles=%s'
                        % (lang, urllib.parse.quote(hits[0])))
                js2 = json.loads(get(url2).decode('utf-8'))
                pg2 = list(js2['query']['pages'].values())[0]
                txt = pg2.get('extract') or txt
                print('   [%s] 改用条目：%s -> %d 字符' % (lang, hits[0], len(txt)))
        save(fname, txt)
    except Exception as e:                          # noqa: BLE001
        print('   [%s] FAIL %s: %s' % (lang, type(e).__name__, str(e)[:100]))

# ------------------------------------------------------------ 2. 中文文库篇目页
print('== 2. 中文马克思主义文库 ==')
CN = [
    'https://www.marxists.org/chinese/voroshilov/index.htm',
    'https://www.marxists.org/chinese/voroshilov/index.html',
    'https://www.marxists.org/chinese/vorochilov/index.htm',
    'https://www.marxists.org/chinese/woroschilow/index.htm',
]
for u in CN:
    try:
        t = dec(get(u, tries=1))
        if len(t) < 800:
            print('   404/太短 (%d): %s' % (len(t), u)); continue
        save('mia-cn-index.txt', t)
        links = re.findall(r'(?i)<a\s+[^>]*href\s*=\s*"?([^"\'\s>]+)"?', t)
        save('mia-cn-links.txt', '\n'.join(links))
        print('   命中！链接 %d 条' % len(links))
        break
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# --------------------------------------------------- 3. 英文 MIA 档案（若有）
print('== 3. 英文 MIA ==')
for u in ['https://www.marxists.org/archive/voroshilov/index.htm',
          'https://www.marxists.org/archive/voroshilov/']:
    try:
        t = dec(get(u, tries=1))
        if len(t) < 600:
            print('   太短/404: %s' % u); continue
        save('mia-en-index.txt', t)
        links = re.findall(r'(?i)<a\s+[^>]*href\s*=\s*"?([^"\'\s>]+)"?', t)
        save('mia-en-links.txt', '\n'.join(links))
        print('   命中！链接 %d 条' % len(links))
        break
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# ------------------------------------- 4. 中文文库总索引里搜「伏罗希洛夫」字样
print('== 4. 文库总索引检索 ==')
for u, tag in [('https://www.marxists.org/chinese/index.html', 'cn-index'),
               ('https://www.marxists.org/chinese/reference-books/index.htm', 'cn-books')]:
    try:
        t = dec(get(u))
        hits = [m.start() for m in re.finditer('伏罗希洛夫|伏洛希洛夫', t)]
        print('   %s: 命中 %d 处' % (u, len(hits)))
        if hits:
            for h in hits[:12]:
                print('      ...' + t[max(0, h - 90):h + 60].replace('\n', ' '))
            save(tag + '-voroshilov-hits.txt', '\n'.join(
                t[max(0, h - 250):h + 250] for h in hits))
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# ---------------------------------- 5. KV 坦克 / 首批元帅 / 1957 反党集团
print('== 5. 补充条目 ==')
EXTRA = [
    ('ru', 'КВ-1',                    'ru-kv1.txt'),
    ('ru', 'КВ-2',                    'ru-kv2.txt'),
    ('ru', 'Маршал_Советского_Союза', 'ru-marshal.txt'),
    ('ru', 'Антипартийная_группа',    'ru-antiparty.txt'),
    ('ru', 'Луганск',                 'ru-lugansk.txt'),
]
for lang, title, fname in EXTRA:
    try:
        url = ('https://%s.wikipedia.org/w/api.php?action=query&prop=extracts'
               '&explaintext=1&exlimit=1&redirects=1&format=json&titles=%s'
               % (lang, urllib.parse.quote(title)))
        js = json.loads(get(url).decode('utf-8'))
        pg = list(js['query']['pages'].values())[0]
        txt = pg.get('extract') or ''
        if len(txt) < 200:
            print('   [%s] 太短 (%d): %s' % (lang, len(txt), title)); continue
        save(fname, txt)
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s %s: %s' % (lang, title, type(e).__name__))

print('== 完成 ->', OUT)
