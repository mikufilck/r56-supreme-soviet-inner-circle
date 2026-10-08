# 找出指定 sprite 名对应的 texturefile 实际路径，作为给 GPT 的风格参考图。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-icon-refs.ps1

$roots = @(
    "F:\Hearts of Iron IV",
    "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125"
)

# 德国核心圈「升格国策」图标（人物 + 装饰）
$ger = @(
    'GFX_focus_GER_ascension_of_todt', 'GFX_focus_GER_ascension_of_speer',
    'GFX_focus_GER_ascension_of_goring', 'GFX_focus_GER_ascension_of_himmler',
    'GFX_focus_GER_ascension_of_goebbels', 'GFX_focus_GER_party_chancellor_hess'
)
# 苏联国策图标（我们的风格基准）
$sov = @(
    'GFX_focus_SOV_organize_wreckers', 'GFX_focus_SOV_the_supreme_soviet',
    'GFX_goal_SOV_trotsky_victory', 'GFX_focus_generic_soviet_politics',
    'GFX_goal_arrests', 'GFX_generic_goal_communist_reforms',
    'GFX_goal_support_fourth_int', 'GFX_focus_generic_soviet_army',
    'GFX_focus_SOV_the_peoples_revolution'
)

function Find-Sprite($name) {
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $r -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue)) {
            $txt = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not $txt) { continue }
            $idx = $txt.IndexOf($name)
            if ($idx -lt 0) { continue }
            # 从命中点往后 800 字符里找第一个 texturefile
            $seg = $txt.Substring($idx, [Math]::Min(800, $txt.Length - $idx))
            $m = [regex]::Match($seg, 'texturefile\s*=\s*"([^"]+)"')
            if (-not $m.Success) { $m = [regex]::Match($seg, 'texturefile\s*=\s*([^\s\r\n]+)') }
            if ($m.Success) {
                $src = if ($f.FullName.StartsWith("F:\")) { "原版" } else { "R56 " }
                $rel = $m.Groups[1].Value.Trim().Trim('"') -replace '/', '\'
                $abs = Join-Path $r $rel
                $exist = if (Test-Path -LiteralPath $abs) { "存在" } else { "缺失" }
                return "  [$src] $name`n          -> $abs   ($exist)"
            }
            return "  [$src] $name  : .gfx 里找到但无 texturefile  （$($f.FullName)）"
        }
    }
    return "  [未找到] $name"
}

Write-Host "======== 德国核心圈升格国策图标（入口国策参考）========"
foreach ($n in $ger) { Write-Host (Find-Sprite $n) }

Write-Host "`n======== 苏联国策图标（其余国策的风格基准）========"
foreach ($n in $sov) { Write-Host (Find-Sprite $n) }
