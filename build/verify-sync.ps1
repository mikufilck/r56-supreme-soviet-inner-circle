# verify-sync.ps1
# 目的：核对 sync-from-r56.ps1 的落盘结果。
#       重点查 BOM —— 脚本 .txt 带 BOM 会导致整文件静默不加载，是最隐蔽的坑。
# 用法：powershell -NoProfile -File verify-sync.ps1

$ErrorActionPreference = 'Stop'
$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$ListPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\attach-points.json'

$points = (Get-Content -LiteralPath $ListPath -Raw -Encoding UTF8 | ConvertFrom-Json).points |
          Where-Object { $_.phase -le 1 }

Write-Output ("{0,-14} {1,-46} {2,10} {3,7} {4,6} {5}" -f 'ID', '相对路径', '字节', '行数', 'BOM', '锚点')
Write-Output ('-' * 110)

$bomBad = 0
$missing = 0
$anchorBad = 0
$totalBytes = 0

foreach ($p in $points) {
    $f = Join-Path $ModRoot ($p.srcRelativePath -replace '/', '\')
    if (-not (Test-Path $f)) {
        Write-Output ("{0,-14} {1,-46} {2,10} {3,7} {4,6} {5}" -f $p.id, $p.srcRelativePath, '-', '-', '-', '✗ 文件不存在')
        $missing++
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($f)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if ($hasBom) { $bomBad++ }
    $totalBytes += $bytes.Length

    $text = [System.IO.File]::ReadAllText($f)
    $lines = ($text -split "`r?`n").Count

    $anchorPattern = '(?m)^[ \t]*id[ \t]*=[ \t]*' + [regex]::Escape($p.treeId) + '[ \t]*\r?$'
    $anchorHits = ([regex]::Matches($text, $anchorPattern)).Count
    if ($anchorHits -ne 1) { $anchorBad++ }

    Write-Output ("{0,-14} {1,-46} {2,10} {3,7} {4,6} {5}" -f `
        $p.id, $p.srcRelativePath, $bytes.Length, $lines, $hasBom, "$anchorHits 次")
}

Write-Output ('-' * 110)
Write-Output ("文件缺失 {0} / 带 BOM {1} / 锚点异常 {2}" -f $missing, $bomBad, $anchorBad)
Write-Output ("总体积 {0:N2} MB" -f ($totalBytes / 1MB))

Write-Output ""
Write-Output "=== mod 目录实际结构 ==="
Get-ChildItem $ModRoot -Recurse -File | ForEach-Object {
    Write-Output ("  " + $_.FullName.Replace($ModRoot + '\', '') + "   (" + $_.Length + " 字节)")
}

Write-Output ""
Write-Output "=== descriptor.mod BOM 复检 ==="
$dm = Join-Path $ModRoot 'descriptor.mod'
if (Test-Path $dm) {
    $b = [System.IO.File]::ReadAllBytes($dm)
    $hb = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    Write-Output ("  {0} 字节 | BOM={1}" -f $b.Length, $hb)
    Write-Output ("  内容: " + ([System.IO.File]::ReadAllText($dm) -replace "`r?`n", ' | '))
} else {
    Write-Output "  descriptor.mod 不存在"
}
