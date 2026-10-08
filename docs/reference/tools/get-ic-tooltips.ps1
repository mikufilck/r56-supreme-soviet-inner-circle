# 取核心圈子线相关 tooltip 的中英原文
$ErrorActionPreference = 'SilentlyContinue'
$files = @(
    'F:\Hearts of Iron IV\localisation\simp_chinese\WUW_focus_l_simp_chinese.yml',
    'F:\Hearts of Iron IV\localisation\english\wuw_focus_l_english.yml',
    'F:\Hearts of Iron IV\localisation\english\WUW_focus_l_english.yml',
    'F:\Hearts of Iron IV\localisation\simp_chinese\WUW_ideas_l_simp_chinese.yml'
)
$keys = @('GER_focus_can_only_be_completed_by_advisor_tt', 'GER_inner_circle_focus_in_progress_tt',
          'GER_inner_circle_cd_days_tt', 'GER_fuhrerprinzip_inner_circle_tt',
          'GER_ascension_of_character_tt', 'GER_ascension_of_character_focus_tt',
          'GER_event_to_replace_ascended_advisor_tt', 'GER_a_strong_successor_trigger_tt')
foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath $f)) { Write-Host "[无] $f"; continue }
    Write-Host "######## $f"
    $lines = Get-Content -LiteralPath $f -Encoding UTF8
    foreach ($k in $keys) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ("^\s*" + [regex]::Escape($k) + "\s*:")) {
                Write-Host ("  L{0}: {1}" -f ($i + 1), $lines[$i].Trim())
            }
        }
    }
    Write-Host ''
}
