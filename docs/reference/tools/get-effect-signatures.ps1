# 从官方 effects 文档里抽出待用效果的签名与说明
$ErrorActionPreference = 'SilentlyContinue'
$f = 'F:\Hearts of Iron IV\documentation\effects_documentation.md'
$lines = Get-Content -LiteralPath $f -Encoding UTF8
$want = @('complete_national_focus', 'activate_shine_on_focus', 'add_dynamic_modifier',
          'remove_dynamic_modifier', 'set_country_flag', 'add_country_leader_trait',
          'activate_shine_on_focus', 'force_update_dynamic_modifier')
foreach ($w in $want) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ("^##\s+" + [regex]::Escape($w) + "\s*$")) {
            Write-Host "======== $w   (L$($i+1)) ========"
            for ($j = $i; $j -lt [Math]::Min($i + 40, $lines.Count); $j++) {
                if ($j -gt $i -and $lines[$j] -match '^##\s') { break }
                Write-Host $lines[$j]
            }
            Write-Host ''
        }
    }
}

Write-Host "`n################ 触发器：has_shine_effect_on_focus"
$tf = 'F:\Hearts of Iron IV\documentation\triggers_documentation.md'
$tl = Get-Content -LiteralPath $tf -Encoding UTF8
for ($i = 0; $i -lt $tl.Count; $i++) {
    if ($tl[$i] -match '^##\s+has_shine_effect_on_focus\s*$') {
        Write-Host "======== L$($i+1) ========"
        for ($j = $i; $j -lt [Math]::Min($i + 25, $tl.Count); $j++) {
            if ($j -gt $i -and $tl[$j] -match '^##\s') { break }
            Write-Host $tl[$j]
        }
    }
}
