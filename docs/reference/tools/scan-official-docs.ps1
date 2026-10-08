# 官方 documentation 目录：文件大小 + 含 dynamic / national focus 的行
$ErrorActionPreference = 'SilentlyContinue'
$dirs = @(
    'F:\Hearts of Iron IV\documentation',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\documentation'
)
foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) { Write-Host "  [无] $d"; continue }
    Write-Host "################ $d"
    Get-ChildItem -LiteralPath $d -File | Sort-Object Name | ForEach-Object {
        Write-Host ("  {0,-46} {1,10:N0} B" -f $_.Name, $_.Length)
    }
    Write-Host ''
}

Write-Host "`n################ 含 'dynamic' 的行（只看 .md）"
foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) { continue }
    Get-ChildItem -LiteralPath $d -File -Filter *.md | ForEach-Object {
        $h = Select-String -Path $_.FullName -Pattern 'dynamic' -Encoding UTF8
        if ($h) {
            Write-Host ("  --- " + $_.Name + "  (" + $h.Count + " 处)")
            $h | Select-Object -First 25 | ForEach-Object { Write-Host ("      L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
        }
    }
}

Write-Host "`n################ 含 'focus' 的 .md 文件与其行数"
foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) { continue }
    Get-ChildItem -LiteralPath $d -File -Filter *.md | ForEach-Object {
        $h = Select-String -Path $_.FullName -Pattern 'focus' -Encoding UTF8
        if ($h) { Write-Host ("  {0,-46} {1} 处" -f $_.Name, $h.Count) }
    }
}
