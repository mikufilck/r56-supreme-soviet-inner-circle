# 列出苏联国策图标候选（原版 + R56），供挑选风格参考
$roots = @{
    "原版" = "F:\Hearts of Iron IV\gfx\interface\goals"
    "R56"  = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\interface\goals"
}
foreach ($k in $roots.Keys) {
    $r = $roots[$k]
    if (-not (Test-Path -LiteralPath $r)) { Write-Host "[$k] 目录不存在: $r"; continue }
    $hit = Get-ChildItem -LiteralPath $r -Recurse -File -Include *.dds -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match '(?i)sov|soviet' }
    Write-Host "==== $k : $($hit.Count) 个 ===="
    $hit | ForEach-Object { Write-Host ("  " + $_.FullName.Substring($r.Length).TrimStart('\')) }
}
