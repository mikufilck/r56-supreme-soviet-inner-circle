# ============================================================
#  从 Wayback Machine 抓取 HOI4 官方 wiki 页面到本目录
#  用法:  powershell -ExecutionPolicy Bypass -File fetch-wiki.ps1
#
#  背景：paradoxwikis.com 整域名被链路拦截（HTTP 427，连 robots.txt 亦然），
#        只能走 Wayback 存档。已存在的 .html 会自动跳过。
# ============================================================

$ErrorActionPreference = 'Continue'
$dir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'wiki'

$pages = @(
    # 已归档
    'Modding', 'Mod_structure', 'Localisation', 'Map_modding', 'Scopes', 'Console_commands',
    # 待补：最有价值的两页
    'Effects', 'Triggers',
    # 其它常用页
    'Events', 'Ideas', 'Decisions', 'National_focus', 'Modifiers', 'On_actions',
    'Characters', 'Troubleshooting', 'Nudger', 'Graphical_assets', 'Interface',
    'States', 'Country_creation', 'Replace_path', 'Scripted_GUI',
    'Military_industrial_organization', 'Doctrines', 'Buildings', 'Equipment',
    'Ideologies', 'Cosmetic_tag', 'Divisions', 'Units', 'Technologies'
)

foreach ($p in $pages) {
    $out = Join-Path $dir "$p.html"
    if (Test-Path $out) { Write-Host "skip  $p"; continue }
    try {
        # CDX API 比 availability API 可靠（后者常返回 502）
        $j = Invoke-RestMethod "https://web.archive.org/cdx/search/cdx?url=hoi4.paradoxwikis.com/$p&output=json&limit=-1&filter=statuscode:200" -TimeoutSec 60
        if ($j.Count -lt 2) { Write-Host "NONE  $p"; continue }
        $ts = $j[1][1]
        Invoke-WebRequest "https://web.archive.org/web/$ts/https://hoi4.paradoxwikis.com/$p" -OutFile $out -UseBasicParsing -TimeoutSec 180
        Write-Host ("OK    {0}  [{1}]  {2} KB" -f $p, $ts, [math]::Round((Get-Item $out).Length / 1KB))
    } catch {
        Write-Host "ERR   $p  $($_.Exception.Message)"
    }
}

# ---- HTML -> 纯文本（便于 VS Code 全局搜索）----
Write-Host "`n--- 转换为纯文本 ---"
Get-ChildItem $dir -Filter *.html | ForEach-Object {
    $t = Get-Content $_.FullName -Raw
    $t = $t -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', '' -replace '(?s)<!--.*?-->', '' -replace '<[^>]+>', "`n"
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = ($t -split "`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and $_ -notmatch '^web\.archive\.org' -and $_ -notmatch '^https?://' }) -join "`n"
    $txt = [IO.Path]::ChangeExtension($_.FullName, '.txt')
    Set-Content -Path $txt -Value $t -Encoding UTF8
    Write-Host ("txt   {0}  {1} KB" -f $_.BaseName, [math]::Round((Get-Item $txt).Length / 1KB))
}

Write-Host "`ndone."
