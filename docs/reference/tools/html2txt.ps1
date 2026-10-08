# HTML → 纯文本（UTF-8 无 BOM）
#
# 用法：
#   A) 无参数                —— 把 docs/reference/wiki/*.html（Wayback 存档页）转成 *.txt（原用途）
#   B) -Path <html>          —— 转单个文件；不指定 -OutTxt 时输出同名 .txt
#
# ⚠️ 编码自动探测：先按**严格 UTF-8** 解（非法字节序列会抛异常），失败再按 **GB18030**。
#    ——marxists.org/chinese 的页面编码**不统一**（主 index 是 GB，子目录是 UTF-8）；
#      维基、多数现代站点是 UTF-8。不要写死编码。
param(
    [string]$Path,
    [string]$OutTxt
)

function Convert-One([string]$file, [string]$out) {
    try {
        $strict = New-Object System.Text.UTF8Encoding($false, $true)
        $t = $strict.GetString([System.IO.File]::ReadAllBytes($file))
        $used = 'UTF-8'
    } catch {
        $t = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::GetEncoding('GB18030'))
        $used = 'GB18030'
    }
    $t = $t -replace '(?s)<script.*?</script>', ' '
    $t = $t -replace '(?s)<style.*?</style>', ' '
    $t = $t -replace '(?s)<!--.*?-->', ' '
    $t = $t -replace '(?i)</p\s*>', "`r`n"
    $t = $t -replace '(?i)<br\s*/?\s*>', "`r`n"
    $t = $t -replace '(?i)</(div|h[1-6]|li|tr|td)\s*>', "`r`n"
    $t = $t -replace '(?s)<[^>]+>', ' '
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = $t -replace '[ \t]+', ' '
    $t = $t -replace '(\r?\n){3,}', "`r`n`r`n"
    $t = $t.Trim()
    if (-not $out) { $out = [IO.Path]::ChangeExtension($file, '.txt') }
    [System.IO.File]::WriteAllText($out, $t, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output ('{0,-46} {1,8} KB  [{2}]' -f (Split-Path $out -Leaf), [math]::Round((Get-Item $out).Length / 1KB), $used)
}

if ($Path) {
    Convert-One $Path $OutTxt
    exit 0
}

# 原用途：批量转 wiki/ 下的 Wayback 存档页
$dir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'wiki'
Get-ChildItem $dir -Filter *.html | ForEach-Object { Convert-One $_.FullName '' }
