# 1) 找 GER_the_inner_circle_dm_tt 定义在哪（含 dlc 子目录、含 localisation）
# 2) 找核心圈 inlay window 文件并导出
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' }
)

Write-Host '################ A) 哪些文件提到 GER_the_inner_circle_dm_tt'
foreach ($r in $roots) {
    $hits = Get-ChildItem -LiteralPath $r.Dir -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -lt 3000000 } |
            Select-String -SimpleMatch -Pattern 'GER_the_inner_circle_dm_tt' -ErrorAction SilentlyContinue
    foreach ($h in $hits) {
        Write-Host ("  [{0}] {1}  L{2}" -f $r.Tag, $h.Path.Substring($r.Dir.Length).TrimStart('\'), $h.LineNumber)
        Write-Host ("        " + $h.Line.Trim())
    }
}

Write-Host "`n################ B) 核心圈窗口定义文件"
foreach ($r in $roots) {
    $hits = Get-ChildItem -LiteralPath $r.Dir -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'inner_circle' -and $_.DirectoryName -match 'inlay' }
    foreach ($h in $hits) { Write-Host ("  [{0}] {1}" -f $r.Tag, $h.FullName) }
}

Write-Host "`n################ C) scripted_localisation 里提到 inner_circle 的"
foreach ($r in $roots) {
    foreach ($s in @('common\scripted_localisation')) {
        $d = Join-Path $r.Dir $s
        if (-not (Test-Path -LiteralPath $d)) { continue }
        Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt | ForEach-Object {
            $t = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            if ($t -match 'inner_circle|ascended_advisor') {
                Write-Host ("  [{0}] {1}" -f $r.Tag, $_.FullName.Substring($r.Dir.Length).TrimStart('\'))
            }
        }
    }
}
