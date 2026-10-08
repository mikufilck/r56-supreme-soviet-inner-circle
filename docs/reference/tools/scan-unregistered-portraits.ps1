# scan-unregistered-portraits.ps1
# 目的：找出「文件存在但没被注册成 sprite」的角色立绘。
#       R56 里有一批 r56_portrait_SOV_*.dds，角色定义里没引用它们。
#       若能把它们注册出来，就能给更多角色配上立绘。
# 用法：powershell -NoProfile -File scan-unregistered-portraits.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$Van = 'F:\Hearts of Iron IV'

# 1) 收集两边所有 .dds 里名字含 SOV 且含 portrait 的
Write-Output "=== A. 磁盘上存在的 SOV 立绘 DDS 文件 ==="
$files = @()
foreach ($root in @($Van, $R56)) {
    $hit = Get-ChildItem (Join-Path $root 'gfx') -Recurse -Filter '*.dds' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'SOV' -and $_.Name -match 'portrait' }
    foreach ($h in $hit) {
        $rel = $h.FullName.Substring($root.Length).TrimStart('\') -replace '\\', '/'
        $files += [pscustomobject]@{ Root = $(if ($root -eq $Van) { 'vanilla' } else { 'r56' }); Rel = $rel; Name = $h.Name }
    }
}
Write-Output ("  合计 " + $files.Count + " 个")
foreach ($f in ($files | Sort-Object Name)) {
    Write-Output ("   [{0,-7}] {1}" -f $f.Root, $f.Rel)
}

# 2) 收集两边所有已注册的 sprite 名
Write-Output ""
Write-Output "=== B. 已注册的立绘 sprite 与文件的差集（= 没被注册的素材）==="
$gfxText = New-Object System.Text.StringBuilder
foreach ($root in @($Van, $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
        [void]$gfxText.Append([System.IO.File]::ReadAllText($f.FullName))
    }
}
$all = $gfxText.ToString()

$unreg = @()
foreach ($f in $files) {
    # 从文件名推出可能的 sprite 名：去掉扩展名
    $base = $f.Name -replace '\.dds$', ''
    $guess = 'GFX_' + $base
    $alt = 'GFX_' + ($base -replace '^r56_', '')
    $registered = ($all -match ('name\s*=\s*"' + [regex]::Escape($guess) + '"')) -or
                  ($all -match ('name\s*=\s*"' + [regex]::Escape($alt) + '"'))
    if (-not $registered) {
        $unreg += $f
        Write-Output ("   未注册: {0}" -f $f.Rel)
    }
}
Write-Output ("  未注册素材共 " + $unreg.Count + " 个")

# 3) 只看反派/反对派相关的（名字里含常见姓氏）
Write-Output ""
Write-Output "=== C. 其中与反对派相关的（含下列姓氏之一的）==="
$kw = @('trotsky','bukharin','rykov','tomsky','radek','smilga','smirnov','zinovyev','kamenev',
        'preobrazhensky','ryutin','sokolnikov','shlyapnikov','serebryakov','piatakov','muralov',
        'antonov','krestinsky','uglanov','kollontai','myasnikov','slepkov','bubnov','rudzutak',
        'frunze','dzerzhinsky','kuibyshev','ordzhonikidze','kirov','mikoyan','zhdanov','sverdlov')
foreach ($f in ($unreg | Sort-Object Name)) {
    $low = $f.Name.ToLower()
    foreach ($k in $kw) {
        if ($low -match $k) { Write-Output ("   {0,-58} [{1}]" -f $f.Rel, $k); break }
    }
}

# 4) 顺带确认：SOV_supreme_soviet 这个领袖位的立绘在哪
Write-Output ""
Write-Output "=== D. GFX_portrait_SOV_supreme_soviet 的定义位置 ==="
foreach ($root in @($Van, $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
        $t = [System.IO.File]::ReadAllText($f.FullName)
        if ($t -match 'name\s*=\s*"GFX_portrait_SOV_supreme_soviet"') {
            foreach ($m in [regex]::Matches($t, '(?s)name\s*=\s*"GFX_portrait_SOV_supreme_soviet".{0,200}')) {
                Write-Output ("   [" + $root + "] " + $f.Name)
                Write-Output ("      " + ($m.Value -replace '\s+', ' '))
            }
        }
    }
}
