# =============================================================================
# SOP 第 0 步：查季诺维也夫的现成内容（原版 + 原版-dlc + R56）
# -----------------------------------------------------------------------------
# 🚩 教训（docs/23 第 0 步）：漏扫 dlc\<name>\ 曾导致「布哈林没有大立绘」的错误结论。
# 🚩 性能：逐文件 Select-String 在 F: 盘上跑不完 —— 改成【一次调用 + -List】。
# 🚩 人名转写变体：Зиновьев / Zinoviev / Zinovyev；本名 Радомысльский（Радомышельский）
#    化名 Апфельбаум —— 不搜本名会漏掉角色定义等处。
# =============================================================================
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

$rx = 'zinov|Зиновьев|Радомысльск|Радомышельск|Апфельбаум|季诺维也夫'

$subdirs = @(
    'common\characters', 'common\national_focus', 'common\ideas',
    'common\scripted_effects', 'common\scripted_triggers',
    'common\dynamic_modifiers', 'common\country_leader',
    'common\decisions', 'common\ideologies',
    'events', 'localisation\simp_chinese', 'interface'
)

$out = @()
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { $out += "[$($r.Name)] 路径不存在：$($r.Path)"; continue }
    $out += "==================== $($r.Name) ===================="
    foreach ($sd in $subdirs) {
        $d = Join-Path $r.Path $sd
        if (-not (Test-Path $d)) { continue }
        $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -in @('.txt', '.yml', '.gfx', '.gui') } |
                   Select-Object -ExpandProperty FullName)
        if ($files.Count -eq 0) { continue }
        $m = Select-String -Path $files -Pattern $rx -List -ErrorAction SilentlyContinue
        if ($m) {
            $out += "  --- $sd （$($m.Count) 个文件命中）---"
            foreach ($x in $m) {
                $out += ('    {0}' -f $x.Path.Replace($r.Path + '\', ''))
                $out += ('        ' + $x.Line.Trim())
            }
        }
    }
    $out += ''
}

# 立绘文件名单扫（不在上面的扩展名过滤里）
$out += '==================== 立绘文件名命中 ===================='
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { continue }
    $hits = @(Get-ChildItem -LiteralPath $r.Path -Recurse -File -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -match 'zinov|Зиновьев' })
    foreach ($h in $hits) { $out += ('  [{0}] {1}   {2:N0} 字节' -f $r.Name, $h.FullName.Replace($r.Path + '\', ''), $h.Length) }
}
$out += ''

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 's0-zin.txt') -Encoding utf8
Write-Host ('完成，输出 ' + $out.Count + ' 行 -> build/s0-zin.txt')
