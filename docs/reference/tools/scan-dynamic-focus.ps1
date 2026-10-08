# 查 dynamic = yes 在国策里的用法与含义线索
$ErrorActionPreference = 'SilentlyContinue'
$roots = @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')

Write-Host '################ A) 各 root 里 focus 块内出现 dynamic = yes 的次数'
foreach ($b in $roots) {
    $d = Join-Path $b 'common\national_focus'
    if (-not (Test-Path -LiteralPath $d)) { continue }
    $hits = Select-String -Path (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt).FullName -Pattern '^\s*dynamic\s*=\s*yes' -Encoding UTF8
    Write-Host ("  [$b]  $($hits.Count) 处")
    $hits | Group-Object Path | Sort-Object Count -Descending | Select-Object -First 12 | ForEach-Object {
        Write-Host ("      {0}  ({1} 处)  L{2}" -f $_.Name.Substring($b.Length).TrimStart('\'), $_.Count, ($_.Group[0].LineNumber))
    }
}

Write-Host "`n################ B) 含 'dynamic' 的文档/说明文件"
foreach ($b in $roots) {
    $docs = Get-ChildItem -LiteralPath $b -Recurse -File -Include *.md, *.txt -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -match 'documentation|docs|readme' -or $_.Name -match 'documentation|readme' }
    foreach ($f in $docs) {
        $h = Select-String -Path $f.FullName -Pattern 'dynamic' -Encoding UTF8
        if ($h) { Write-Host ("  " + $f.FullName + "  (" + $h.Count + " 处)") }
    }
}
