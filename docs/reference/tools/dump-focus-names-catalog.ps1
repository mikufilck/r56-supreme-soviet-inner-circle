# =============================================================================
# 全部国策 id / 中文显示名 目录（**docs/99 §28 的固定动作**）
# -----------------------------------------------------------------------------
# 为什么需要这个：
#   `docs/99` §28 定下一条固定动作 —— **扫【原版国策 id 全表】找同名 / 近名国策**。
#   判据 K 又规定命名撞车的判定线 =「与原版【中文显示名】完全相同」。
#   → 所以必须有一张 {id → 中文名} 的全表，判断时**查表**而不是凭记忆。
#
# 覆盖：原版 + 全部 DLC + R56（**三处都要扫**，漏扫 DLC 曾导致「布哈林没有大立绘」错判）。
#
# 输出（制表符分隔，UTF-8 无 BOM）：
#   id <TAB> 中文名 <TAB> 相对文件路径
#   中文名取不到时留空。
# =============================================================================
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

# ---- 1. 先把三处的 simp_chinese 本地化收成 id -> 中文 表 ----
# ⚠️ 两种写法都要收：`KEY:0 "文本"`（多数）与 `KEY: "文本"`（NSB/R56 部分文件）。
#    只用 `:0` 的正则会**全部抓空**（docs/99 §31 记过这一坑）。
$loc = @{}
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { continue }
    $ld = Join-Path $r.Path 'localisation\simp_chinese'
    if (-not (Test-Path $ld)) { continue }
    $files = @(Get-ChildItem -LiteralPath $ld -Recurse -File -Filter *.yml -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty FullName)
    foreach ($f in $files) {
        $txt = [System.IO.File]::ReadAllText($f)
        foreach ($m in [regex]::Matches($txt, '(?m)^\s*([A-Za-z0-9_.\-]+)\s*:\s*(?:0\s*)?[ \t]*"(.*)"\s*$')) {
            $k = $m.Groups[1].Value
            if (-not $loc.ContainsKey($k)) { $loc[$k] = $m.Groups[2].Value }
        }
    }
}

# ---- 2. 再扫三处的 national_focus/*.txt，取 focus 块里的 id 与 text ----
$rows = @()
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { continue }
    $nd = Join-Path $r.Path 'common\national_focus'
    if (-not (Test-Path $nd)) { continue }
    $files = @(Get-ChildItem -LiteralPath $nd -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty FullName)
    foreach ($f in $files) {
        $txt  = [System.IO.File]::ReadAllText($f)
        $rel  = $f.Replace($r.Path + '\', '')
        # 逐个 focus / joint_focus / shared_focus 块
        foreach ($m in [regex]::Matches($txt, '(?s)\b(?:focus|joint_focus|shared_focus)\s*=\s*\{(.*?)\n\t?\}')) {
            $blk = $m.Groups[1].Value
            $idM = [regex]::Match($blk, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)')
            if (-not $idM.Success) { continue }
            $id  = $idM.Groups[1].Value
            $tM  = [regex]::Match($blk, '(?m)^\s*text\s*=\s*([A-Za-z0-9_]+)')
            $key = if ($tM.Success) { $tM.Groups[1].Value } else { $id }
            $zh  = if ($loc.ContainsKey($key)) { $loc[$key] } else { '' }
            $rows += [pscustomobject]@{ Id = $id; Zh = $zh; File = "$($r.Name)/$rel" }
        }
    }
}

$rows = @($rows | Sort-Object Id -Unique)
$lines = @()
$lines += "id`t中文名`t出处"
foreach ($x in $rows) { $lines += ("{0}`t{1}`t{2}" -f $x.Id, $x.Zh, $x.File) }

$outPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'reports\focus-names-catalog.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("写出 {0}（{1} 条国策 / 本地化键 {2} 个）" -f $outPath, $rows.Count, $loc.Count)
