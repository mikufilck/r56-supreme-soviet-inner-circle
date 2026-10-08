# 在【全部】工坊 mod 里搜索谁定义了 GFX_focus_GER_ascension_of_* / GER_fuhrerprinzip
$ErrorActionPreference = 'SilentlyContinue'
$ws = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360'
if (-not (Test-Path -LiteralPath $ws)) { Write-Host "工坊目录不存在: $ws"; exit }

$needles = @('GFX_focus_GER_ascension_of_himmler', 'GER_ascension_of_himmler', 'GER_fuhrerprinzip')

foreach ($n in $needles) {
    Write-Host "================ $n ================"
    foreach ($d in (Get-ChildItem -LiteralPath $ws -Directory)) {
        $hits = Get-ChildItem -LiteralPath $d.FullName -Recurse -File -Include *.gfx, *.txt -ErrorAction SilentlyContinue |
                Select-String -SimpleMatch -Pattern $n -List -ErrorAction SilentlyContinue
        if ($hits) {
            Write-Host ("  --- mod {0}" -f $d.Name)
            foreach ($h in $hits) {
                Write-Host ("      " + $h.Path.Substring($d.FullName.Length).TrimStart('\'))
            }
        }
    }
    Write-Host ''
}
