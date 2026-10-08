# scan-figure-content.ps1
# ---------------------------------------------------------------------------
# docs/23 SOP 第 0 步：查某个人物在【原版 / R56 / 我们自己 mod】里已有哪些现成内容。
# 目的：避免与已有国策/事件/idea 重复（AGENTS 硬规则：不能重复劳动）。
#
# 用法：
#   powershell -NoProfile -File docs\reference\tools\scan-figure-content.ps1 -Name bukharin
#   产出建议：docs\reference\reports\figure-<Name>.txt
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [int]$MaxPerFile = 24
)

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$MOD  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

$dirs = @(
    'common\national_focus', 'common\ideas', 'common\characters', 'common\dynamic_modifiers',
    'common\scripted_effects', 'common\scripted_triggers', 'common\scripted_localisation',
    'common\decisions', 'common\opinion_modifiers', 'common\unit_leader', 'common\operations',
    'events', 'history\countries'
)

Write-Output ("扫描关键词：'{0}'（不区分大小写）" -f $Name)
Write-Output ''

$focusIds = New-Object System.Collections.Generic.List[string]
$ideaIds  = New-Object System.Collections.Generic.List[string]
$charIds  = New-Object System.Collections.Generic.List[string]
$total    = 0

foreach ($root in @($HOI4, $R56, $MOD)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    if ($root -eq $MOD) { $label = '我们' }
    Write-Output ('=' * 100)
    Write-Output ("### [$label] $root")
    Write-Output ('=' * 100)

    foreach ($d in $dirs) {
        $p = Join-Path $root $d
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
            $f = $_.FullName
            $ls = [System.IO.File]::ReadAllLines($f)
            $hits = New-Object System.Collections.Generic.List[string]
            for ($i = 0; $i -lt $ls.Count; $i++) {
                if ($ls[$i] -match $Name) {
                    $hits.Add(("  L{0,-6} {1}" -f ($i + 1), $ls[$i].Trim()))
                    # 顺手收集"以这个人命名的" id
                    foreach ($m in [regex]::Matches($ls[$i], '([A-Za-z_0-9]*' + $Name + '[A-Za-z_0-9]*)')) {
                        $id = $m.Groups[1].Value
                        if ($ls[$i] -match ('focus\s*=\s*' + [regex]::Escape($id))) { $focusIds.Add($id) }
                    }
                    foreach ($m in [regex]::Matches($ls[$i], ('(?i)([A-Za-z_0-9]*' + $Name + '[A-Za-z_0-9]*)\s*=\s*\{'))) {
                        $id = $m.Groups[1].Value
                        if ($f -like '*\ideas\*') { $ideaIds.Add($id) }
                        if ($f -like '*\characters\*') { $charIds.Add($id) }
                    }
                }
            }
            if ($hits.Count -gt 0) {
                $total += $hits.Count
                Write-Output ''
                Write-Output ("--- {0}  （{1} 处）" -f $f.Replace($root + '\', ''), $hits.Count)
                $hits | Select-Object -First $MaxPerFile | ForEach-Object { Write-Output $_ }
                if ($hits.Count -gt $MaxPerFile) { Write-Output ("        ...（还有 {0} 处未列）" -f ($hits.Count - $MaxPerFile)) }
            }
        }
    }
    Write-Output ''
}

Write-Output ('=' * 100)
Write-Output '### 汇总'
Write-Output ('=' * 100)
Write-Output ("总命中 {0} 处" -f $total)
$f = @($focusIds | Sort-Object -Unique)
$i = @($ideaIds | Sort-Object -Unique)
$c = @($charIds | Sort-Object -Unique)
Write-Output ''
Write-Output ("与这个人物相关的**国策 id** ({0} 个)：" -f $f.Count)
$f | ForEach-Object { Write-Output ('  ' + $_) }
Write-Output ''
Write-Output ("**idea id** ({0} 个)：" -f $i.Count)
$i | ForEach-Object { Write-Output ('  ' + $_) }
Write-Output ''
Write-Output ("**角色 id** ({0} 个)：" -f $c.Count)
$c | ForEach-Object { Write-Output ('  ' + $_) }
