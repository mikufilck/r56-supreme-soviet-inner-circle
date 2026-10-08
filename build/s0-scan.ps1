# SOP 第 0 步：查现成内容（R56 + 原版，务必含 dlc 子目录）
# 🚩 教训（docs/23 第 0 步）：漏扫 dlc\<name>\ 曾导致「布哈林没有大立绘」的错误结论。
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';      Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc';  Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';       Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

# 要查的人：李可夫 + 其常见转写变体
$patterns = @('rykov', 'aleksey_rykov', 'alexei_rykov', 'aleksei_rykov')
# 只搜这些子目录（common / events / localisation 里才可能有"现成内容"）
$subdirs = @('common', 'events', 'localisation', 'gfx\interface', 'interface')

$out = @()
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { $out += "[$($r.Name)] 路径不存在：$($r.Path)"; continue }
    $out += "==================== $($r.Name)  $($r.Path) ===================="
    foreach ($sd in $subdirs) {
        $d = Join-Path $r.Path $sd
        if (-not (Test-Path $d)) { continue }
        $files = Get-ChildItem -LiteralPath $d -Recurse -File -Include *.txt,*.yml,*.gfx,*.gui -ErrorAction SilentlyContinue
        $hits = @()
        foreach ($f in $files) {
            foreach ($p in $patterns) {
                $m = Select-String -LiteralPath $f.FullName -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue
                if ($m) {
                    $hits += ('    {0}  ({1} 处)  例: {2}' -f $f.FullName.Replace($r.Path + '\', ''), $m.Count, ($m[0].Line.Trim()))
                    break
                }
            }
        }
        if ($hits.Count -gt 0) { $out += "  --- $sd ---"; $out += $hits }
    }
    $out += ''
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 's0-rykov.txt') -Encoding utf8
