# 搜游戏内真实存在的「沙俄旧军官」角色 —— 供「返聘沙俄军官」国策点名用。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-tsarist-officers.ps1

$roots = @(
    "F:\Hearts of Iron IV",
    "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125"
)

# 史实上的「军事专家」候选（托洛茨基招募的旧沙俄军官）
$known = @(
    'sergei_kamenev', 'kamenev', 'vatsetis', 'vacetis', 'bonch', 'lebedev',
    'svechin', 'shaposhnikov', 'brusilov', 'yegorov', 'egorov', 'tukhachevsky',
    'rattel', 'samoylo', 'altvater', 'sytin', 'parsky', 'gittis', 'kork',
    'uborevich', 'shorin', 'gusev', 'lashevich', 'akhromeev'
)

# 1. 收集全部角色文件并【只读一遍】
$charFiles = @()
foreach ($r in $roots) {
    $d = Join-Path $r "common\characters"
    if (-not (Test-Path -LiteralPath $d)) { continue }
    $charFiles += (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue)
}
Write-Host "角色文件合计: $($charFiles.Count)"

$corpus = @{}
foreach ($f in $charFiles) {
    $src = if ($f.FullName.StartsWith("F:\")) { "原版" } else { "R56 " }
    $corpus["$src $($f.Name)"] = (Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue)
}
Write-Host "已读入: $($corpus.Count) 个文件`n"

Write-Host "======== 2. 已知沙俄军官姓名命中情况 ========"
$hitCount = 0
foreach ($n in $known) {
    $pat = "(SOV_\w*" + [regex]::Escape($n) + "\w*)"
    $ids = @()
    foreach ($k in $corpus.Keys) {
        $t = $corpus[$k]
        if ($t -and ($t -match $pat)) {
            $ids += ([regex]::Matches($t, $pat) | ForEach-Object { $_.Groups[1].Value })
        }
    }
    $ids = $ids | Select-Object -Unique
    if ($ids.Count -gt 0) {
        Write-Host ("[命中] {0,-18} -> {1}" -f $n, ($ids -join ", "))
        $hitCount++
    }
}
Write-Host "`n命中姓名数: $hitCount / $($known.Count)"

# 3. 反向：列出苏联角色文件里的全部 SOV_* 角色 id，供人工挑
Write-Host "`n======== 3. 苏联角色文件里的全部 SOV_* 角色 id ========"
foreach ($k in ($corpus.Keys | Sort-Object)) {
    if ($k -notmatch 'sov') { continue }
    $t = $corpus[$k]
    if (-not $t) { continue }
    $ids = [regex]::Matches($t, '(?m)^\s*(SOV_\w+)\s*=\s*\{') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    if ($ids.Count -gt 0) {
        Write-Host ("--- {0}  ({1} 个)" -f $k, $ids.Count)
        $ids | ForEach-Object { Write-Host ("      " + $_) }
    }
}
