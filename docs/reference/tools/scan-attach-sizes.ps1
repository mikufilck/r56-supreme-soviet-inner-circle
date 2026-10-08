# scan-attach-sizes.ps1
# 目的：统计「互助会国别分支」候选挂载文件的规模，用于成本评估。
# 用法：powershell -NoProfile -File scan-attach-sizes.ps1

$ErrorActionPreference = 'Stop'
$root = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus'

# 备选挂载文件（按国家分组，含默认树与可选树）
$groups = [ordered]@{
    'SOV 苏联'      = @('soviet.txt')
    'PRC 中共'      = @('china_communist_sea.txt','china_communist.txt')
    'MON 蒙古'      = @('mongolia.txt')
    'FIN 芬兰'      = @('finland.txt')
    'SWE 瑞典'      = @('r56_sweden.txt','sweden.txt')
    'NOR 挪威'      = @('r56_norway.txt','norway.txt')
    'DEN 丹麦'      = @('denmark.txt','r56_denmark.txt')
    'ICE 冰岛'      = @('iceland.txt','r56_iceland.txt')
    'AFG 阿富汗'    = @('r56_afghanistan.txt','afghanistan.txt')
    'SAU 沙特'      = @('saudi_arabia.txt')
    'PHI 菲律宾'    = @('r56_philippines.txt','philippines.txt')
    'CUB 古巴'      = @('Cuba.txt')
    'ARG 阿根廷'    = @('r56_argentina.txt','argentina.txt')
    'ETH 埃塞俄比亚'= @('r56_ethiopia.txt','ethiopia.txt')
    'FRA 法国'      = @('france.txt','free_france.txt','vichy_france.txt')
    'POL 波兰'      = @('poland.txt')
    'HUN 匈牙利'    = @('hungary_wuw.txt','hungary.txt')
}

$grandLines = 0
$grandBytes = 0
$fileCount = 0

"{0,-16} {1,-24} {2,9} {3,8}" -f '国家', '文件', '行数', 'KB'
'-' * 62

foreach ($g in $groups.Keys) {
    $first = $true
    foreach ($f in $groups[$g]) {
        $p = Join-Path $root $f
        $name = if ($first) { $g } else { '' }
        $first = $false
        if (Test-Path $p) {
            $lines = ([System.IO.File]::ReadAllLines($p)).Count
            $kb = [math]::Round((Get-Item $p).Length / 1KB)
            "{0,-16} {1,-24} {2,9} {3,8}" -f $name, $f, $lines, $kb
            $grandLines += $lines
            $grandBytes += (Get-Item $p).Length
            $fileCount++
        } else {
            "{0,-16} {1,-24} {2,9} {3,8}" -f $name, $f, 'MISSING', '-'
        }
    }
}

'-' * 62
"{0,-16} {1,-24} {2,9} {3,8}" -f ('合计 ' + $fileCount + ' 个文件'), '', $grandLines, [math]::Round($grandBytes / 1KB)

""
"=== 变体对照 ==="
"全部支持（含可选树）: $fileCount 个文件 / $grandLines 行"
