# scan-sov-portraits.ps1
# 目的：找出 13 名已确认反对派角色的立绘 sprite 名，供核心圈席位使用。
#       德国窗口用的是 GFX_portrait_GER_<name> 这种命名，先确认苏联是不是同一套。
# 用法：powershell -NoProfile -File scan-sov-portraits.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

# 13 名已确认角色的角色 id（来自 docs/10 §2.2.1）
$chars = @(
    'SOV_lev_trotsky',
    'SOV_karl_radek',
    'SOV_yevgeny_preobrazhensky',
    'SOV_ivar_smilga',
    'SOV_ivan_smirnov',
    'SOV_grigory_zinovyev',
    'SOV_lev_kamenev',
    'SOV_nikolay_bukharin',
    'SOV_aleksey_rykov',
    'SOV_mikhail_tomsky',
    'SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov',
    'SOV_aleksandr_shlyapnikov'
)

# 1) 把所有 interface/*.gfx 读成一个大字符串，找 sprite 名
$gfx = New-Object System.Text.StringBuilder
foreach ($f in Get-ChildItem (Join-Path $R56 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    [void]$gfx.Append([System.IO.File]::ReadAllText($f.FullName))
}
$gfxText = $gfx.ToString()
Write-Output ("R56 interface/*.gfx 合计 {0} 字符" -f $gfxText.Length)

Write-Output ""
Write-Output "=== A. 立绘 sprite 搜索（按角色 id 的姓名部分匹配）==="
$found = @{}
foreach ($c in $chars) {
    $short = $c -replace '^SOV_', ''
    # 尝试多种命名：portrait_SOV_xxx / SOV_xxx / xxx
    $hits = @()
    foreach ($pat in @('GFX_portrait_' + $c, 'GFX_' + $c, 'GFX_hof_' + $c)) {
        if ($gfxText -match ('name\s*=\s*"' + [regex]::Escape($pat) + '"')) { $hits += $pat }
    }
    # 再模糊搜：名字里同时含 short 与 portrait 的 sprite
    foreach ($m in [regex]::Matches($gfxText, 'name\s*=\s*"(GFX_[A-Za-z0-9_]*portrait[A-Za-z0-9_]*' + [regex]::Escape($short) + '[A-Za-z0-9_]*)"')) {
        $hits += $m.Groups[1].Value
    }
    $hits = $hits | Sort-Object -Unique
    $found[$c] = $hits
    Write-Output ("  {0,-38} -> {1}" -f $c, $(if ($hits.Count -gt 0) { $hits -join ' , ' } else { '（未找到）' }))
}

Write-Output ""
Write-Output "=== B. 这些角色的 .dds 文件是否存在（按姓名模糊找）==="
foreach ($c in $chars) {
    $short = ($c -replace '^SOV_', '')
    $parts = $short -split '_'
    $lastName = $parts[-1]
    $matches = Get-ChildItem $R56 -Recurse -Filter '*.dds' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'SOV' -and $_.Name -match $lastName }
    if ($matches.Count -gt 0) {
        Write-Output ("  {0,-38} -> {1}" -f $c, (($matches | Select-Object -First 3 | ForEach-Object { $_.Name }) -join ' , '))
    } else {
        Write-Output ("  {0,-38} -> 无 dds" -f $c)
    }
}

Write-Output ""
Write-Output "=== C. 对照：德国那套立绘的 sprite 命名长什么样 ==="
foreach ($m in [regex]::Matches($gfxText, 'name\s*=\s*"(GFX_portrait_GER_[A-Za-z0-9_]+)"')) {
    Write-Output ("  " + $m.Groups[1].Value)
}
foreach ($m in [regex]::Matches($gfxText, 'name\s*=\s*"(GFX_inner_circle_leader_[A-Za-z0-9_]+)"')) {
    Write-Output ("  " + $m.Groups[1].Value)
}
