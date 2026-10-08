# 抓托洛茨基中文一手材料（marxists.org/chinese/trotsky）
# 用途：重写 docs/22 §8.3 的 17 条国策描述 —— 改成【托洛茨基本人原话】
#
# 🚩 三个已知坑（见仓库记忆）：
#   ① 主 index 是 GB 系、子目录是 UTF-8 → 一律自动探测，别写死
#   ② 中文经控制台管道必乱 → 直接 WriteAllText(UTF8 无 BOM) 落盘
#   ③ 本机是 TUN + 本地 HTTP 代理 → curl 必须显式 -x
$ErrorActionPreference = 'Continue'

$proxy = 'http://127.0.0.1:7993'
$root  = Join-Path $PSScriptRoot '..\tmp\trotsky'
$htmlDir = Join-Path $root 'html'
$txtDir  = Join-Path $root 'txt'
New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir | Out-Null

# key = 落盘文件名（ASCII，便于引用）；value = URL
$targets = [ordered]@{
    'i1_red_army_oath_19180422'  = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19180422.htm'
    'i1_holy_task_19200310'      = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19200310.htm'
    'i1_order_19190309'          = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19190309.htm'
    'i1_order_19190604'          = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19190604.htm'
    'i1_orders_191808'           = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19180813-27.htm'
    'i2_marxism_military_19240319' = 'https://www.marxists.org/chinese/trotsky/marxist.org-chinese-trotsky-19240319.htm'
    'ii1_history_preface_1930'   = 'https://www.marxists.org/chinese/trotsky/1930book/trotsky-1930bookindex.htm'
    'ii2_permanent_rev_1928'     = 'https://www.marxists.org/chinese/trotsky/1928a/index.htm'
    'ii2_permanent_rev_alt'      = 'https://www.marxists.org/chinese/trotsky/permanent_revolution/index.htm'
    'iii1_lessons_of_october_1924' = 'https://www.marxists.org/chinese/trotsky/192409/index.htm'
    'iii2_betrayed_rev_1936'     = 'https://www.marxists.org/chinese/trotsky/1936book/index.htm'
    'iii2_bureaucracy_19350130'  = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19350130.htm'
    'iii2_bureaucratic_terror_19351102' = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19351102.htm'
    'iv1_nep_gosplan_19210807'   = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19210807.htm'
    'iv1_econ_theses_192512'     = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-192512.htm'
    'iv3_gosplan_19230115'       = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19230115.htm'
    'iv4_accumulation_19260502'  = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19260502.htm'
    'iv4_industry_19260907'      = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19260907.htm'
    'iv4_note_19260115'          = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19260115.htm'
    'v1_comintern_1921b'         = 'https://www.marxists.org/chinese/trotsky/marxist.org-chinese-trotsky-1921b.htm'
    'v2_china_19270507'          = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19270507.htm'
    'v2_china_book_index'        = 'https://www.marxists.org/chinese/trotsky/1926-1940book/index.htm'
    'v3_fascism_index'           = 'https://www.marxists.org/chinese/trotsky/about-FASCISM/index.htm'
    'v3_german_fascism_index'    = 'https://www.marxists.org/chinese/trotsky/german_fascism/index.htm'
    'e_life_1929book'            = 'https://www.marxists.org/chinese/trotsky/1929/trotsky_1929book.htm'
    'e_stop_politics_19281216'   = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19281216.htm'
    'x_uneven_dev_19150703'      = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19150703-09.htm'
    'x_econ_independence_19270319' = 'https://www.marxists.org/chinese/trotsky/mia-chinese-trotsky-19270319-27.htm'
}

function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?i)</p>', "`n" + "`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n" + "`n")
    $t = [regex]::Replace($t, '(?i)</div>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' ')
    $t = [regex]::Replace($t, '(\r?\n){3,}', "`n" + "`n")
    return $t.Trim()
}

function Read-TextAuto([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    try {
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        return $enc.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
    }
}

$report = @()
foreach ($k in $targets.Keys) {
    $u = $targets[$k]
    $hp = Join-Path $htmlDir "$k.htm"
    $r = & curl.exe -sS -L -x $proxy --max-time 90 -o $hp -w '%{http_code}' $u 2>&1
    $code = ($r -join '')
    if ($code -ne '200' -or -not (Test-Path $hp)) {
        $report += ('  [FAIL] {0,-30} HTTP={1}' -f $k, $code)
        continue
    }
    $html = Read-TextAuto $hp
    $txt  = Convert-HtmlToText $html
    [System.IO.File]::WriteAllText((Join-Path $txtDir "$k.txt"), $txt, (New-Object System.Text.UTF8Encoding($false)))
    $report += ('  [OK  ] {0,-30} {1,8} 字节原文 -> {2,7} 字节纯文本' -f $k, (Get-Item $hp).Length, $txt.Length)
    Start-Sleep -Milliseconds 400
}

$report | Out-File -LiteralPath (Join-Path $PSScriptRoot 'fetch-trotsky-report.txt') -Encoding utf8
