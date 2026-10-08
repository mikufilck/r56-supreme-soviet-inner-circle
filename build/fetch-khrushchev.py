# -*- coding: utf-8 -*-
"""SOP 第 0/1 步材料抓取 —— 尼基塔·赫鲁晓夫（花名册 Idx 21，regime 营）
产物目录：tmp/khrushchev/txt/
用法：python build/fetch-khrushchev.py
"""
import os, re, json, time, urllib.request, urllib.parse

WS   = r'd:\Users\xuwei\PycharmProjects\heart_of_Iron'
OUT  = os.path.join(WS, 'tmp', 'khrushchev', 'txt')
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
    """marxists.org 的中文站编码不统一：先严格 UTF-8，失败回退 GB18030。"""
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gb18030', 'replace')


def save(name, text):
    p = os.path.join(OUT, name)
    with open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    print('  -> %-30s %7d chars' % (name, len(text)))


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
    ('ru', 'Хрущёв,_Никита_Сергеевич',      'ru-wiki.txt'),
    ('en', 'Nikita_Khrushchev',             'en-wiki.txt'),
    ('zh', '尼基塔·赫鲁晓夫',                'zh-wiki.txt'),
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
        if len(txt) < 300:      # 条目名猜错了 -> 用 search 找
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
CN_CANDS = [
    'https://www.marxists.org/chinese/khrushchev/index.htm',
    'https://www.marxists.org/chinese/khrushchev/index.html',
    'https://www.marxists.org/chinese/khrushchov/index.htm',
    'https://www.marxists.org/chinese/hrushchov/index.htm',
]
for u in CN_CANDS:
    try:
        b = get(u, tries=1)
        t = dec(b)
        if len(t) < 800 and ('not found' in t.lower() or '404' in t):
            print('   404 %s' % u); continue
        save('mia-cn-index-%s.txt' % u.rstrip('/').split('/')[-1][:14], t)
        links = re.findall(r'(?i)<a\s+[^>]*href\s*=\s*"?([^"\'\s>]+)"?', t)
        save('mia-cn-links.txt', '\n'.join(links))
        print('   命中！链接 %d 条' % len(links))
        break
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# --------------------------------------------------- 3. 英文 MIA 档案（若有）
print('== 3. 英文 MIA ==')
for u in ['https://www.marxists.org/archive/khrushchev/index.htm',
          'https://www.marxists.org/archive/khrushchov/index.htm']:
    try:
        t = dec(get(u, tries=1))
        if len(t) < 600:
            print('   太短/404: %s' % u)
        else:
            save('mia-en-index-%s.txt' % u.rstrip('/').split('/')[-2][:12], t)
            links = re.findall(r'(?i)<a\s+[^>]*href\s*=\s*"?([^"\'\s>]+)"?', t)
            save('mia-en-links-%s.txt' % u.rstrip('/').split('/')[-2][:12], '\n'.join(links))
            print('   命中！链接 %d 条' % len(links))
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# ------------------------------------- 4. 中文文库总索引里搜「赫鲁晓夫」字样
print('== 4. 文库总索引检索 ==')
for u, tag in [('https://www.marxists.org/chinese/index.html', 'cn-index'),
               ('https://www.marxists.org/chinese/reference-books/index.htm', 'cn-books')]:
    try:
        t = dec(get(u))
        hits = [m.start() for m in re.finditer('赫鲁晓夫', t)]
        print('   %s: 命中 %d 处' % (u, len(hits)))
        if hits:
            for h in hits[:15]:
                print('      ...' + t[max(0, h - 90):h + 60].replace('\n', ' '))
            save(tag + '-khrushchev-hits.txt', '\n'.join(
                t[max(0, h - 250):h + 250] for h in hits))
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

# ---------------------------------------- 5. 秘密报告（《关于个人崇拜及其后果》）
print('== 5. 秘密报告候选地址 ==')
SECRET = [
    'https://www.marxists.org/chinese/reference-books/secreto-speech/index.htm',
    'https://www.marxists.org/chinese/khrushchev/1956/02/25.htm',
    'https://www.marxists.org/history/ussr/government/1956/02/25.htm',
    'https://www.marxists.org/archive/khrushchev/1956/02/25.htm',
]
for u in SECRET:
    try:
        b = get(u, tries=1)
        t = dec(b)
        if len(t) < 1200:
            print('   太短/404 (%d): %s' % (len(t), u)); continue
        tag = re.sub(r'[^a-z0-9]+', '-', u.split('marxists.org/')[1])[:60]
        save('mia-secret-' + tag + '.txt', html2txt(t))
        print('   命中！%s' % u)
    except Exception as e:                          # noqa: BLE001
        print('   FAIL %s: %s' % (u, type(e).__name__))

print('== 完成 ->', OUT)
