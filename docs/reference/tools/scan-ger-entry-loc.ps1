# 用截图里的中文文案反查：哪个 localisation 文件提供这些键，以及哪个国策在用。
$ErrorActionPreference = 'SilentlyContinue'

$roots = New-Object System.Collections.ArrayList
[void]$roots.Add(@{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' })
$dlc = 'F:\Hearts of Iron IV\dlc'
if (Test-Path -LiteralPath $dlc) {
    Get-ChildItem -LiteralPath $dlc -Directory | Sort-Object Name | ForEach-Object {
        [void]$roots.Add(@{ Tag = ('DLC ' + $_.Name); Dir = $_.FullName })
    }
}
[void]$roots.Add(@{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' })
[void]$roots.Add(@{ Tag = '本 mod'; Dir = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron' })

$needles = @('全国领导托特', '全国领导施佩尔', '全国领导戈林', '全国领导希姆莱', '全国领导戈培尔', '党魁赫斯', '党魁鲍曼')

foreach ($n in $needles) {
    Write-Host "==== $n ===="
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r.Dir)) { continue }
        $locdir = Join-Path $r.Dir 'localisation'
        if (-not (Test-Path -LiteralPath $locdir)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $locdir -Recurse -File -Include *.yml -ErrorAction SilentlyContinue)) {
            $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            $ln = 0
            foreach ($l in $lines) {
                $ln++
                if ($l -and $l.Contains($n)) {
                    Write-Host ("  [{0}] {1}" -f $r.Tag, $f.FullName.Substring($r.Dir.Length).TrimStart('\'))
                    Write-Host ("      L{0}: {1}" -f $ln, $l.Trim())
                }
            }
        }
    }
    Write-Host ''
}
