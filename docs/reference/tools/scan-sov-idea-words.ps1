# 收集苏联 idea 里实际用过的修正词条名，作为我们 idea 的【已验证词汇表】。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-sov-idea-words.ps1

$r56 = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\ideas"
$van = "F:\Hearts of Iron IV\common\ideas"

$files = @()
foreach ($d in @($r56, $van)) {
    if (-not (Test-Path -LiteralPath $d)) { continue }
    $files += (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'SOV|soviet' })
}
Write-Host "扫描文件: $($files.Count)"
$files | ForEach-Object { Write-Host "  " + $_.FullName.Replace($r56, '[R56]').Replace($van, '[原版]') }

$words = @{}
foreach ($f in $files) {
    $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) { continue }
    foreach ($l in $lines) {
        # 形如  xxx = 0.05   或  xxx = -0.1   （在 modifier 块内）
        if ($l -match '^\s*([a-z][a-z0-9_]{4,})\s*=\s*-?\d') {
            $k = $Matches[1]
            # 排除结构关键字
            if ($k -notin @('cost','base','factor','uses','bonus','level','days','amount','value','threshold')) {
                if (-not $words.ContainsKey($k)) { $words[$k] = 0 }
                $words[$k]++
            }
        }
    }
}

Write-Host "`n======== 苏联 idea 里用过的修正词条（按出现次数降序）========"
$words.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    "{0,5}  {1}" -f $_.Value, $_.Key
}
