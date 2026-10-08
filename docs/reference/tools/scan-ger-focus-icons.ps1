# 找出所有定义 GER_ascension_of_himmler 的国策文件，并打印该块的 icon = 行
$ErrorActionPreference = 'SilentlyContinue'

$roots = New-Object System.Collections.ArrayList
[void]$roots.Add(@{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' })
$dlc = 'F:\Hearts of Iron IV\dlc'
if (Test-Path -LiteralPath $dlc) {
    Get-ChildItem -LiteralPath $dlc -Directory | Sort-Object Name | ForEach-Object {
        [void]$roots.Add(@{ Tag = ('DLC ' + $_.Name); Dir = $_.FullName })
    }
}
[void]$roots.Add(@{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' })
[void]$roots.Add(@{ Tag = '本 mod'; Dir = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron' })

$ids = @('GER_fuhrerprinzip', 'GER_ascension_of_himmler', 'GER_ascension_of_todt',
         'GER_party_chancellor_hess', 'GER_party_chancellor_bormann')

foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r.Dir)) { continue }
    $nf = Join-Path $r.Dir 'common\national_focus'
    if (-not (Test-Path -LiteralPath $nf)) { continue }
    Write-Host "######## ${r.Tag} : $nf"
    foreach ($f in (Get-ChildItem -LiteralPath $nf -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue)) {
        $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $l = $lines[$i]
            if (-not $l) { continue }
            foreach ($id in $ids) {
                if ($l -match ("id\s*=\s*" + [regex]::Escape($id) + "\s*$")) {
                    Write-Host ("  {0}  (L{1})  <- {2}" -f $id, ($i + 1), $f.FullName.Substring($nf.Length).TrimStart('\'))
                    # 往后 12 行找 icon =
                    for ($j = $i; $j -lt [Math]::Min($i + 14, $lines.Count); $j++) {
                        if ($lines[$j] -match 'icon\s*=') {
                            Write-Host ("       " + $lines[$j].Trim())
                        }
                    }
                }
            }
        }
    }
    Write-Host ''
}
