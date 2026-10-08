# 从托洛茨基索引页提取篇目清单（含绝对 URL）
# 编码：marxists.org/chinese 主 index 是 GB 系，子目录是 UTF-8 -> 自动探测
$ErrorActionPreference = 'Continue'

function Read-TextAuto([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    try {
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        return $enc.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
    }
}

$base = 'https://www.marxists.org/chinese/trotsky/'
$html = Read-TextAuto (Join-Path $PSScriptRoot '..\tmp\trotsky\index.htm')

$rows = @()
$ms = [regex]::Matches($html, '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', 'IgnoreCase,Singleline')
foreach ($m in $ms) {
    $href = $m.Groups[1].Value.Trim()
    if ($href -match '^(#|mailto:|javascript:)') { continue }
    $text = [regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')
    $text = [System.Net.WebUtility]::HtmlDecode($text).Trim()
    $text = $text -replace '\s+', ' '
    if ($text -eq '') { continue }
    try { $abs = [Uri]::new([Uri]$base, $href).AbsoluteUri } catch { continue }
    $rows += ('{0}  ::  {1}' -f $abs, $text)
}

$out = Join-Path $PSScriptRoot 'trot-links.txt'
$rows | Out-File -LiteralPath $out -Encoding utf8
