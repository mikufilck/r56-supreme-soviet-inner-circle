# 按【文件名】在全部 root 里找 focus_GER_ascension_* / fuhrerprinzip 贴图，看是否有 DLC 覆盖版
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    'F:\Hearts of Iron IV',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
)
foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r)) { continue }
    Write-Host "######## $r"
    Get-ChildItem -LiteralPath $r -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'GER_ascension_of_|GER_fuhrerprinzip' } |
        ForEach-Object { Write-Host ("  " + $_.FullName + "   " + $_.Length + " B") }
    Write-Host ''
}
