# =============================================================================
# 扫描"托洛茨基组"7 人的大幅立绘：找文件 + 读真实尺寸 + 解析 sprite 注册
# -----------------------------------------------------------------------------
# ⚠️⚠️ 本脚本的搜索范围【有已知盲区，结论已被推翻】⚠️⚠️
#
# 它只搜了 <原版>\gfx 与 <原版>\interface，【漏掉了 dlc\<DLC名>\ 子目录】，
# 因此得出了"布哈林、李可夫没有大幅立绘"的【错误结论】（见 roster-b-report.txt）。
#
# 事实：
#   注册表  dlc\dlc034_no_step_back\interface\nsb_portraits.gfx
#   贴图    dlc\dlc034_no_step_back\gfx\leaders\SOV\portrait_SOV_nikolay_bukharin.dds
#           dlc\dlc034_no_step_back\gfx\leaders\SOV\portrait_SOV_aleksey_rykov.dds
#   两者都是 156x210。
#
# 14 个 DLC 里有 13 个带 gfx\leaders，所以这是系统性盲区，不是个例。
# 正确的做法见 build\gen-hof-ic-s3.ps1 里的 $assetRoots（已包含全部 dlc\*\）。
# 保留本脚本仅作记录；要用请先把 DLC 目录加进下面的搜索根。
#
# 教训：凡是要下"X 不存在"这种否定结论，先把搜索范围列出来自检一遍。
# -----------------------------------------------------------------------------
#
# 为什么要读尺寸：docs/17 说这批人有 156x210 的"大幅立绘"，
# 但"有立绘"和"尺寸正好是席位要的 156x210"是两件事，必须实测。
# 席位槽按 156x210 原图、0.5 缩放渲染进 131x139 的框。
#
# DDS 头里取宽高的偏移（小端）：
#   0  magic 'DDS ' / 12 dwHeight / 16 dwWidth
# =============================================================================

$ErrorActionPreference = 'Continue'

$vanilla = 'F:\Hearts of Iron IV'
$r56     = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$modRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

function Get-DdsSize([string]$path) {
    try {
        $fs = [System.IO.File]::OpenRead($path)
        try {
            $buf = New-Object byte[] 20
            $null = $fs.Read($buf, 0, 20)
            $magic = [System.Text.Encoding]::ASCII.GetString($buf, 0, 4)
            if ($magic -ne 'DDS ') { return '非DDS' }
            $h = [BitConverter]::ToUInt32($buf, 12)
            $w = [BitConverter]::ToUInt32($buf, 16)
            return "${w}x${h}"
        }
        finally { $fs.Close() }
    }
    catch { return '读取失败' }
}

# --- 7 人的名字特征（小写子串匹配文件名）---------------------------------
$people = @(
    @{ Idx = 1; Key = 'lev_trotsky';            Zh = '列夫·托洛茨基';           Pat = 'trotsky' },
    @{ Idx = 2; Key = 'nikolay_bukharin';       Zh = '尼古拉·布哈林';           Pat = 'bukharin' },
    @{ Idx = 3; Key = 'aleksey_rykov';          Zh = '阿列克谢·李可夫';         Pat = 'rykov' },
    @{ Idx = 4; Key = 'grigory_zinovyev';       Zh = '格里戈里·季诺维也夫';     Pat = 'zinov' },
    @{ Idx = 5; Key = 'lev_kamenev';            Zh = '列夫·加米涅夫';           Pat = 'kamenev' },
    @{ Idx = 6; Key = 'ivan_smirnov';           Zh = '伊万·斯米尔诺夫';         Pat = 'ivan_smirnov' },
    @{ Idx = 7; Key = 'leonid_serebryakov';     Zh = '列昂尼德·谢列布里亚科夫'; Pat = 'serebryakov' }
)

Write-Output '################ 1. gfx\leaders\SOV 下的候选立绘文件 ################'
Write-Output ''
Write-Output ('  {0,-26} {1,-10} {2,-9} {3}' -f '文件', '尺寸', '来源', '字节')

foreach ($p in $people) {

    Write-Output ''
    Write-Output "== $($p.Idx) $($p.Zh)  (匹配 '$($p.Pat)') =="

    $hits = @()
    foreach ($root in @($r56, $vanilla)) {
        $label = if ($root -eq $r56) { 'R56' } else { '原版' }
        $dir = Join-Path $root 'gfx\leaders\SOV'
        if (-not (Test-Path $dir)) { continue }
        foreach ($f in (Get-ChildItem $dir -Filter '*.dds' -File -ErrorAction SilentlyContinue)) {
            if ($f.Name.ToLower().Contains($p.Pat)) {
                $hits += [pscustomobject]@{
                    Name  = $f.Name
                    Size  = (Get-DdsSize $f.FullName)
                    Root  = $label
                    Bytes = $f.Length
                    Full  = $f.FullName
                }
            }
        }
    }

    if ($hits.Count -eq 0) {
        Write-Output '  （gfx\leaders\SOV 下无匹配文件）'
    }
    else {
        foreach ($h in ($hits | Sort-Object -Property @{E = { $_.Size -ne '156x210' } }, Name)) {
            $mark = if ($h.Size -eq '156x210') { '  <<< 正好 156x210' } else { '' }
            Write-Output ('  {0,-26} {1,-10} {2,-9} {3,10:N0}{4}' -f $h.Name, $h.Size, $h.Root, $h.Bytes, $mark)
        }
    }
}

Write-Output ''
Write-Output ''
Write-Output '################ 2. gfx\interface\ideas 下的匹配文件（小图备选）################'
Write-Output ''

foreach ($p in $people) {
    $hits = @()
    foreach ($root in @($vanilla, $r56)) {
        $label = if ($root -eq $r56) { 'R56' } else { '原版' }
        $dir = Join-Path $root 'gfx\interface\ideas'
        if (-not (Test-Path $dir)) { continue }
        foreach ($f in (Get-ChildItem $dir -Filter '*.dds' -File -ErrorAction SilentlyContinue)) {
            if ($f.Name.ToLower().Contains($p.Pat)) {
                $hits += ('{0} [{1}] {2}' -f $f.Name, $label, (Get-DdsSize $f.FullName))
            }
        }
    }
    if ($hits.Count -eq 0) { Write-Output ("  {0,-14} 无" -f $p.Key) }
    else { foreach ($h in ($hits | Sort-Object -Unique)) { Write-Output ("  {0,-14} {1}" -f $p.Key, $h) } }
}

Write-Output ''
Write-Output ''
Write-Output '################ 3. GFX_portrait_SOV_* 的 sprite 注册（含子目录）################'
Write-Output ''

# 之前在 interface\*.gfx 顶层没搜到布哈林/李可夫，说明注册可能在子目录，
# 所以这次对 interface\ 做递归（.gfx 文件不多，代价可接受）。
$wantNames = @(
    'GFX_portrait_SOV_lev_trotsky',
    'GFX_portrait_SOV_nikolay_bukharin',
    'GFX_portrait_SOV_aleksey_rykov',
    'GFX_portrait_SOV_grigory_zinovyev',
    'GFX_portrait_SOV_lev_kamenev',
    'GFX_portrait_SOV_ivan_smirnov',
    'GFX_portrait_SOV_leonid_serebryakov'
)

$reg = @{}
foreach ($root in @($vanilla, $r56)) {
    $label = if ($root -eq $r56) { 'R56' } else { '原版' }
    $dir = Join-Path $root 'interface'
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in (Get-ChildItem $dir -Recurse -Filter '*.gfx' -File -ErrorAction SilentlyContinue)) {
        $L = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 0; $i -lt $L.Count; $i++) {
            foreach ($t in $wantNames) {
                if ($L[$i] -match ('^\s*name\s*=\s*"' + [regex]::Escape($t) + '"\s*$')) {
                    $tf = '(无 texturefile)'
                    for ($j = $i + 1; $j -le [Math]::Min($i + 4, $L.Count - 1); $j++) {
                        if ($L[$j] -match 'texturefile\s*=\s*"([^"]+)"') { $tf = $Matches[1]; break }
                    }
                    if (-not $reg.ContainsKey($t)) {
                        $reg[$t] = ('{0}  ({1} : {2})' -f $tf, $label, $f.Name)
                    }
                }
            }
        }
    }
}

foreach ($t in $wantNames) {
    if ($reg.ContainsKey($t)) { Write-Output ("  {0,-40} => {1}" -f $t, $reg[$t]) }
    else { Write-Output ("  {0,-40} => 未注册" -f $t) }
}

Write-Output ''
Write-Output ''
Write-Output '################ 4. mod 内是否已有新美术（portraits 目录）################'
Write-Output ''

$artDir = Join-Path $modRoot 'gfx\interface\hof_ic\portraits'
if (Test-Path $artDir) {
    $arts = Get-ChildItem $artDir -File -ErrorAction SilentlyContinue
    if ($arts) {
        foreach ($a in $arts) {
            Write-Output ('  {0,-52} {1,-10} {2,10:N0} 字节' -f $a.Name, (Get-DdsSize $a.FullName), $a.Length)
        }
    }
    else { Write-Output '  [空] 目录存在但无文件' }
}
else { Write-Output '  [无] 目录不存在（美术未交付）' }
