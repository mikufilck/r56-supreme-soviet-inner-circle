# dump-ger-ic-raw.ps1
# ---------------------------------------------------------------------------
# 把德国核心圈的「实际实现」按【原始缩进】导出，用于照抄。
# 之前的 dump 脚本把缩进去了，看不出 swap_ideas / add_to_variable 的真实嵌套。
#
# 产出（建议）：docs/reference/reports/ger-ic-raw.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$HOI4 = 'F:\Hearts of Iron IV'

function Dump-Range([string]$file, [int]$start, [int]$end, [string]$title) {
    Write-Output ''
    Write-Output ('=' * 100)
    Write-Output ("### {0}" -f $title)
    Write-Output ("### 文件：{0}" -f $file)
    Write-Output ("### 行：{0}..{1}" -f $start, $end)
    Write-Output ('=' * 100)
    if (-not (Test-Path -LiteralPath $file)) { Write-Output '  ❌ 文件不存在'; return }
    $lines = [System.IO.File]::ReadAllLines($file)
    for ($i = $start - 1; $i -lt $end -and $i -lt $lines.Count; $i++) {
        Write-Output ("{0,6}| {1}" -f ($i + 1), $lines[$i])
    }
}

# ---------------------------------------------------------------------------
Write-Output '################################################################################'
Write-Output '# 第一部分：职务 idea 的两个等级（看数值怎么"照抄 + 追加"）'
Write-Output '################################################################################'

$gerIdeas = Join-Path $R56 'common\ideas\GER.txt'
Dump-Range $gerIdeas 11350 11395 '托特 T1 GER_todt_reich_engineer / T2 GER_todt_reich_minister_of_armaments'
Dump-Range $gerIdeas 11476 11548 '希姆莱 T1/T2/T3 三级（看 3 -> 7 -> 10 条）'

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '################################################################################'
Write-Output '# 第二部分：个人线国策的 completion_reward 原文（看 swap_ideas 怎么写）'
Write-Output '################################################################################'

$gerFocus = Join-Path $R56 'common\national_focus\germany.txt'
Dump-Range $gerFocus 21532 21660 'GER_autonomous_organization_todt  （T1 -> T2 升官衔）'
Dump-Range $gerFocus 22776 22850 'GER_expand_gestapo           （用 add_to_variable，看变量名）'
Dump-Range $gerFocus 22003 22140 'GER_wunderwaffe              （tier_3，看 add_to_variable）'

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '################################################################################'
Write-Output '# 第三部分：所有 GER_* 动态修正（原始块）——看哪些是容器、哪些吃变量'
Write-Output '################################################################################'

foreach ($root in @($HOI4, $R56)) {
    $p = Join-Path $root 'common\dynamic_modifiers'
    if (-not (Test-Path $p)) { continue }
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*(GER_[A-Za-z_0-9]+)\s*=\s*\{\s*$') {
                $id = $Matches[1]
                Write-Output ''
                Write-Output ("--- [{0}] {1}  ::  {2}  L{3}" -f $label, (Split-Path $f -Leaf), $id, ($i + 1))
                # 打印到配对右括号
                $depth = 0
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    $l = $lines[$j]
                    Write-Output ('    ' + $l)
                    $depth += ([regex]::Matches($l, '\{')).Count - ([regex]::Matches($l, '\}')).Count
                    if ($j -gt $i -and $depth -le 0) { break }
                }
            }
        }
    }
}
