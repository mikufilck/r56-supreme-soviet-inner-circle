# 对指定 sprite 名，列出【所有】root 里的定义（按加载顺序），用于确认真实生效的那一个。
# 加载顺序：原版 → DLC → 用户目录 → mods，后者覆盖前者。

$roots = New-Object System.Collections.ArrayList
[void]$roots.Add(@{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' })
$dlc = 'F:\Hearts of Iron IV\dlc'
if (Test-Path -LiteralPath $dlc) {
    Get-ChildItem -LiteralPath $dlc -Directory | Sort-Object Name | ForEach-Object {
        [void]$roots.Add(@{ Tag = ('DLC ' + $_.Name); Dir = $_.FullName })
    }
}
[void]$roots.Add(@{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' })

$targets = @(
    'GFX_focus_GER_ascension_of_todt',
    'GFX_focus_GER_ascension_of_speer',
    'GFX_focus_GER_ascension_of_goring',
    'GFX_focus_GER_ascension_of_himmler',
    'GFX_focus_GER_ascension_of_goebbels',
    'GFX_focus_GER_party_chancellor_hess',
    'GFX_focus_GER_party_chancellor_bormann',
    'GFX_focus_GER_fuhrerprinzip'
)

function Get-DdsSize($path) {
    try {
        $fs = [System.IO.File]::OpenRead($path)
        $br = New-Object System.IO.BinaryReader($fs)
        $null = $br.ReadBytes(12)
        $h = $br.ReadInt32(); $w = $br.ReadInt32()
        $br.Close(); $fs.Close()
        return "$w x $h"
    } catch { return '读取失败' }
}

foreach ($t in $targets) {
    Write-Host "==== $t ===="
    $hits = 0
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r.Dir)) { continue }
        $files = Get-ChildItem -LiteralPath $r.Dir -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $txt = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not $txt) { continue }
            $idx = $txt.IndexOf($t)
            if ($idx -lt 0) { continue }
            $seg = $txt.Substring($idx, [Math]::Min(700, $txt.Length - $idx))
            $m = [regex]::Match($seg, 'texturefile\s*=\s*"([^"]+)"')
            if (-not $m.Success) { continue }
            $rel = $m.Groups[1].Value.Trim() -replace '/', '\'
            $abs = Join-Path $r.Dir $rel
            $dim = if (Test-Path -LiteralPath $abs) { Get-DdsSize $abs } else { '缺失' }
            Write-Host ("  [{0,-24}] {1}   <- {2}" -f $r.Tag, $abs, $f.FullName.Substring($r.Dir.Length).TrimStart('\'))
            Write-Host ("      {0}" -f $dim)
            $hits++
        }
    }
    if ($hits -eq 0) { Write-Host '  [无命中]' }
    Write-Host ''
}
