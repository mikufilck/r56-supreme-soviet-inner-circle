# SOP 第 0 步：查现成内容（R56 + 原版，务必含 dlc 子目录）
# 🚩 教训（docs/23 第 0 步）：漏扫 dlc\<name>\ 曾导致「布哈林没有大立绘」的错误结论。
# 🚩 性能：逐文件 Select-String 在 F: 盘上跑不完 —— 改成【一次调用 + -List】。
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

$rx = 'rykov|Рыков'

$subdirs = @(
    'common\characters', 'common\national_focus', 'common\ideas',
    'common\scripted_effects', 'common\scripted_triggers',
    'common\dynamic_modifiers', 'common\country_leader',
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

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 's0-rykov.txt') -Encoding utf8
Write-Host ('完成，输出 ' + $out.Count + ' 行')
