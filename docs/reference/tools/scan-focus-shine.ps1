# scan-focus-shine.ps1
# ---------------------------------------------------------------------------
# 国策图标接入前必须钉死的两件事：
#   1. 国策图标是不是【必须】另有一张 `_shine` 贴图？它在 .gfx 里怎么注册？
#   2. 我们自己 mod 已有的 .gfx 里，sprite 注册的写法长什么样（照抄）
#
# 产出（建议）：docs/reference/reports/focus-shine.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

Write-Output '################################################################################'
Write-Output '# 1. 原版 gfx/interface/goals/ 里 SOV 国策图标：有没有 _shine 文件？'
Write-Output '################################################################################'

foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $p = Join-Path $root 'gfx\interface\goals'
    if (-not (Test-Path $p)) { Write-Output ("  [{0}] 目录不存在: {1}" -f $label, $p); continue }
    $all = Get-ChildItem $p -File -Filter 'focus_SOV_*.dds' -ErrorAction SilentlyContinue
    $shine = $all | Where-Object { $_.Name -like '*_shine*' }
    Write-Output ("  [{0}] focus_SOV_*.dds 共 {1} 个，其中带 _shine 的 {2} 个" -f $label, $all.Count, $shine.Count)
    Write-Output ''
    Write-Output ("  [{0}] 前 8 个文件名：" -f $label)
    $all | Select-Object -First 8 | ForEach-Object { '      ' + $_.Name }
    if ($shine.Count -gt 0) {
        Write-Output ''
        Write-Output ("  [{0}] 带 _shine 的前 8 个：" -f $label)
        $shine | Select-Object -First 8 | ForEach-Object { '      ' + $_.Name }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 2. 一个具体国策图标在 .gfx 里怎么注册（找 focus_SOV_ 的 spriteType 块）'
Write-Output '################################################################################'

foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $p = Join-Path $root 'interface'
    if (-not (Test-Path $p)) { continue }
    $hit = 0
    Get-ChildItem $p -Recurse -File -Filter *.gfx | ForEach-Object {
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($hit -ge 6) { break }
            if ($lines[$i] -match 'name\s*=\s*"GFX_focus_SOV_' -and $lines[$i] -notmatch '_shine') {
                # 打印本块 + 紧跟的下一块（大概率就是 _shine 或下一个图标）
                Write-Output ''
                Write-Output ("--- [{0}] {1}  L{2}" -f $label, $f.Replace($root + '\', ''), ($i + 1))
                for ($j = [Math]::Max(0, $i - 1); $j -lt $lines.Count -and $j -lt $i + 12; $j++) {
                    Write-Output ('    ' + $lines[$j])
                }
                $hit++
                $i += 6
            }
        }
    }
    Write-Output ("  [{0}] 命中 {1} 处" -f $label, $hit)
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 3. 我们自己 mod 已有的 .gfx 文件头（照抄写法用）'
Write-Output '################################################################################'
$mine = Get-ChildItem 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\interface' -File -Filter *.gfx -ErrorAction SilentlyContinue
foreach ($f in $mine) {
    Write-Output ''
    Write-Output ("--- {0}  （{1} 行）" -f $f.Name, ([System.IO.File]::ReadAllLines($f.FullName)).Count)
    $ls = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt [Math]::Min(6, $ls.Count); $i++) { Write-Output ('    ' + $ls[$i]) }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 4. 文档里 focus icon 的注册规格怎么说'
Write-Output '################################################################################'
$doc = 'F:\Hearts of Iron IV\documentation\modifiers_documentation.md'
Write-Output '  （modifiers 文档跟图标无关，改查项目文档）'
foreach ($d in @('d:\Users\xuwei\PycharmProjects\heart_of_Iron\docs\05-gfx-and-interface.md',
                 'd:\Users\xuwei\PycharmProjects\heart_of_Iron\docs\24-focus-icon-prompts.md')) {
    if (-not (Test-Path $d)) { continue }
    Write-Output ''
    Write-Output ("--- {0}" -f (Split-Path $d -Leaf))
    $ls = [System.IO.File]::ReadAllLines($d)
    for ($i = 0; $i -lt $ls.Count; $i++) {
        if ($ls[$i] -match 'shine') {
            for ($j = [Math]::Max(0, $i - 2); $j -lt $ls.Count -and $j -lt $i + 4; $j++) {
                Write-Output ('    L{0}: {1}' -f ($j + 1), $ls[$j])
            }
            Write-Output '    ---'
        }
    }
}
