# parse-html-links.ps1 —— 从已下载的 HTML 里提取链接（标题 + href）
# 用法：powershell -File parse-html-links.ps1 -Path tmp\bukharin\index.htm [-OutFile ...]
# ⚠️ 三个坑：
#   ① 中文标题经**控制台管道**会乱码 → 用 -OutFile 直接写 UTF-8 文件，再用编辑器读
#   ② **marxists.org/chinese 的页面编码不统一**：主 index 是 **GB**，子目录（如 1919/index.htm）是 **UTF-8**
#      → 本脚本**自动探测**：先按严格 UTF-8 解（失败抛异常），失败再按 GB18030
#   ③ 所以不要写死编码；-HtmlEncoding 只在自动探测需要强制时用
param(
    [Parameter(Mandatory=$true)][string]$Path,
    [string]$OutFile,
    [string]$HtmlEncoding
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { Write-Output ('文件不存在：' + $Path); exit 1 }

$h = $null
$used = ''
if ($HtmlEncoding) {
    $h = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding($HtmlEncoding))
    $used = $HtmlEncoding
} else {
    try {
        # 严格 UTF-8：遇到非法字节序列会抛异常 → 说明不是 UTF-8
        $strict = New-Object System.Text.UTF8Encoding($false, $true)
        $h = $strict.GetString([System.IO.File]::ReadAllBytes($Path))
        $used = 'UTF-8'
    } catch {
        $h = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding('GB18030'))
        $used = 'GB18030'
    }
}
Write-Output ('编码探测：' + $used)
# 宽松匹配 <a href="...">任意</a>
$rx = [regex]'(?s)<a\s[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>'
$seen = [ordered]@{}
foreach ($m in $rx.Matches($h)) {
    $href  = $m.Groups[1].Value
    $title = $m.Groups[2].Value
    $title = $title -replace '(?s)<[^>]+>', ' '
    $title = $title -replace '&nbsp;|&#160;', ' '
    $title = ($title -replace '\s+', ' ').Trim()
    if ($title -eq '') { continue }
    $key = $href + '|' + $title
    if ($seen.Contains($key)) { continue }
    $seen[$key] = $true
}

$lines = New-Object System.Collections.Generic.List[string]
foreach ($k in $seen.Keys) {
    $parts = $k -split '\|', 2
    $lines.Add(('{0,-58} | {1}' -f $parts[0], $parts[1]))
}
$lines.Add(('--- 共 {0} 条 ---' -f $seen.Count))

if ($OutFile) {
    $full = [System.IO.Path]::GetFullPath((Join-Path $PWD $OutFile))
    $dir  = [System.IO.Path]::GetDirectoryName($full)
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output ('已写入（UTF-8 无 BOM）：' + $full)
} else {
    foreach ($l in $lines) { Write-Output $l }
}
