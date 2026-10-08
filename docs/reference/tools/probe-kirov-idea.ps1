# probe-kirov-idea.ps1 —— 确认 idea_SOV_kirov 是否为人物小像
$ErrorActionPreference = 'Stop'
$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

Write-Output '=== 1. 哪个 sprite 用了 idea_SOV_kirov.dds ==='
foreach ($r in @($HOI4, $R56)) {
    $p = Join-Path $r 'interface'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter *.gfx | ForEach-Object {
        $cur = $null
        foreach ($l in [System.IO.File]::ReadAllLines($_.FullName)) {
            $m = [regex]::Match($l, 'name\s*=\s*"([^"]+)"')
            if ($m.Success) { $cur = $m.Groups[1].Value; continue }
            if ($l -match 'idea_SOV_kirov\.dds') {
                Write-Output ("  {0}  ->  sprite = {1}   [{2}]" -f $r, $cur, (Split-Path $_.FullName -Leaf))
            }
        }
    }
}

Write-Output ''
Write-Output '=== 2. 谁引用了 kirov 相关的 idea / 角色 ==='
foreach ($r in @($HOI4, $R56)) {
    foreach ($sub in @('common\ideas', 'common\characters', 'common\scripted_effects')) {
        $p = Join-Path $r $sub
        if (-not (Test-Path $p)) { continue }
        $h = Select-String -Path (Join-Path $p '*.txt') -Pattern 'kirov' -ErrorAction SilentlyContinue
        foreach ($m in $h) {
            Write-Output ("  [{0}] {1}:{2}  {3}" -f (Split-Path $r -Leaf), (Split-Path $m.Path -Leaf), $m.LineNumber, $m.Line.Trim())
        }
    }
}
