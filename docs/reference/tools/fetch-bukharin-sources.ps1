# fetch-bukharin-sources.ps1
# 布哈林一手来源抓取（docs/25 待核实清单）
# ⚠️ PS5.1 的 Invoke-WebRequest 因 TLS 会失败 → 一律用 curl.exe 数组传参
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$outDir = Join-Path $PSScriptRoot '..\..\..\tmp\bukharin'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outDir = (Resolve-Path $outDir).Path

$targets = [ordered]@{
    'index'      = 'https://www.marxists.org/chinese/bukharin/index.htm'
    'trotskyidx' = 'https://www.marxists.org/chinese/trotsky/index.htm'
}

foreach ($k in $targets.Keys) {
    $f = Join-Path $outDir ($k + '.htm')
    if (Test-Path $f) { [System.IO.File]::Delete($f) }
    $a = @('-s','-L','--max-time','45','--compressed',
           '-A','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
           '-o',$f,$targets[$k])
    & curl.exe @a
    if (Test-Path $f) {
        $len = (Get-Item $f).Length
        Write-Output ("{0,-12} {1,8} bytes  {2}" -f $k, $len, $targets[$k])
    } else {
        Write-Output ("{0,-12} 下载失败  {1}" -f $k, $targets[$k])
    }
}
