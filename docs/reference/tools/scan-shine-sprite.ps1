# scan-shine-sprite.ps1
# ---------------------------------------------------------------------------
# 决定性检验：全游戏（含 DLC / R56）到底有没有注册过 `_shine` sprite？
#   · 若有：抄它的写法（指哪张贴图）
#   · 若无：docs/05 L51 那条“国策图标必须额外提供 _shine”就是错的，要改文档
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

# 收集所有 .gfx 根：原版 interface 下所有 + dlc 下所有 + R56
$roots = New-Object System.Collections.Generic.List[string]
foreach ($base in @($HOI4, $R56)) {
    $p = Join-Path $base 'interface'
    if (Test-Path $p) { $roots.Add($p) }
}
$dlc = Join-Path $HOI4 'dlc'
if (Test-Path $dlc) {
    Get-ChildItem $dlc -Directory | ForEach-Object {
        $ip = Join-Path $_.FullName 'interface'
        if (Test-Path $ip) { $roots.Add($ip) }
    }
}

Write-Output ("扫描 .gfx 根目录 {0} 个" -f $roots.Count)
Write-Output ''

$shineLines = New-Object System.Collections.Generic.List[string]
$shineSpr  = 0
$totalSpr  = 0
$files     = 0

foreach ($r in $roots) {
    Get-ChildItem $r -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue | ForEach-Object {
        $files++
        $f = $_.FullName
        foreach ($line in [System.IO.File]::ReadAllLines($f)) {
            if ($line -match 'name\s*=\s*"') { $totalSpr++ }
            if ($line -match '_shine') {
                if ($line -match 'name\s*=\s*"') { $shineSpr++ }
                if ($shineLines.Count -lt 40) { $shineLines.Add(("  {0}  ::  {1}" -f (Split-Path $f -Leaf), $line.Trim())) }
            }
        }
    }
}

Write-Output ("扫了 {0} 个 .gfx 文件，共 {1} 条 name= 注册" -f $files, $totalSpr)
Write-Output ("其中名字里含 _shine 的：{0} 条" -f $shineSpr)
Write-Output ''
Write-Output '--- 前 40 条含 _shine 的行（原样）---'
foreach ($l in $shineLines) { Write-Output $l }

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 若上面有命中：把第一个 _shine spriteType 整块打出来看它指哪张贴图'
Write-Output '################################################################################'
$shown = 0
foreach ($r in $roots) {
    if ($shown -ge 2) { break }
    Get-ChildItem $r -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue | ForEach-Object {
        if ($shown -ge 2) { return }
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'name\s*=\s*"[^"]*_shine"') {
                Write-Output ''
                Write-Output ("--- {0}  L{1}" -f $f.Replace($HOI4 + '\', 'HoI4\').Replace($R56 + '\', 'R56\'), ($i + 1))
                # 往前找块头
                $s = $i
                while ($s -gt 0 -and $lines[$s] -notmatch 'SpriteType|spriteType') { $s-- }
                for ($j = $s; $j -lt $lines.Count -and $j -lt $s + 8; $j++) { Write-Output ('    ' + $lines[$j]) }
                $shown++
                break
            }
        }
    }
}
if ($shown -eq 0) { Write-Output '  （全游戏一条 _shine sprite 都没有 → docs/05 L51 的说法是错的）' }
