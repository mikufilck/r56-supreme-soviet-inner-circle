# 确认：opinion modifier 与 unit leader trait 分别定义在哪个目录
$ErrorActionPreference = 'Stop'

foreach ($r in @('D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
                 'F:\Hearts of Iron IV')) {
    Write-Output ("===== $r =====")
    foreach ($sub in @('common\opinion_modifiers', 'common\unit_leader', 'common\unit_leader_traits',
                       'common\opinion_modifier', 'common\characters')) {
        $d = Join-Path $r $sub
        if (Test-Path -LiteralPath $d) {
            $files = Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue
            Write-Output ("  [有] $sub  -> $($files.Count) 个文件: " + (($files | Select-Object -First 4 -ExpandProperty Name) -join ', '))
        } else {
            Write-Output ("  [无] $sub")
        }
    }
    Write-Output ''
}

# 找 SOV_international_socialist_association 定义在哪
Write-Output '===== SOV_international_socialist_association 定义位置 ====='
foreach ($r in @('D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
                 'F:\Hearts of Iron IV')) {
    foreach ($f in Get-ChildItem -LiteralPath $r -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        $t = [System.IO.File]::ReadAllText($f.FullName)
        if ($t -match '(?m)^\s*SOV_international_socialist_association\s*=\s*\{') {
            $rel = $f.FullName.Replace($r, '').TrimStart('\')
            Write-Output ("  $rel")
        }
    }
}

# 找几个 SOV 将领特质定义在哪
Write-Output ''
Write-Output '===== trait_SOV_trotskyist 定义位置 ====='
foreach ($r in @('D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
                 'F:\Hearts of Iron IV')) {
    foreach ($f in Get-ChildItem -LiteralPath $r -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        $t = [System.IO.File]::ReadAllText($f.FullName)
        if ($t -match '(?m)^\s*trait_SOV_trotskyist\s*=\s*\{') {
            $rel = $f.FullName.Replace($r, '').TrimStart('\')
            Write-Output ("  $rel")
        }
    }
}
