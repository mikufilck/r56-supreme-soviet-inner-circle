# scan-candidates-portraits.ps1
# ---------------------------------------------------------------------------
# 核心圈候选池 · 立绘资源核对（docs/10 §2.4.2.1）
#
# 规则（用户 2026-09-15 定）：
#   · 有【大图】→ 收
#   · 没大图但有【小图】→ 收（可低成本补大图）
#   · 大图小图都没有 → **删掉，不进池**
#   · 斯大林系（体制营）整体不考虑 —— 本次不再扫
#
# 查法（三层，逐层兜底）：
#   ① 角色块里的 portraits = { ... large = "GFX_x" small = "GFX_y" }  -> 解 sprite -> 查文件
#   ② 角色块的 idea_token -> gfx/interface/ideas/idea_<token>.dds
#   ③ 文件名兜底：gfx/leaders/<TAG>/ 与 gfx/interface/ideas/ 下按关键词找
#
# 产出（建议）：docs/reference/reports/candidates-portraits.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$MOD  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$ROOTS = @($MOD, $R56, $HOI4)

# ---------------------------------------------------------------------------
# 候选（已剔除 Stalinist / 体制营）
#   键 = 角色 id（R56 命名），值 = @(显示名, 营)
# ---------------------------------------------------------------------------
$cands = [ordered]@{
    # --- 左营 · 超工业化 ---
    'SOV_lev_trotsky'            = @('列夫·托洛茨基',       'left')
    'SOV_yevgeny_preobrazhensky' = @('叶夫根尼·普列奥布拉任斯基', 'left')
    'SOV_karl_radek'             = @('卡尔·拉狄克',         'left')
    'SOV_ivar_smilga'            = @('伊瓦尔·斯米尔加',     'left')
    'SOV_ivan_smirnov'           = @('伊万·斯米尔诺夫',     'left')
    'SOV_leonid_serebryakov'     = @('列昂尼德·谢列布里亚科夫', 'left')
    # --- 右营 · 平衡增长 ---
    'SOV_nikolay_bukharin'       = @('尼古拉·布哈林',       'right')
    'SOV_aleksey_rykov'          = @('阿列克谢·李可夫',     'right')
    'SOV_mikhail_tomsky'         = @('米哈伊尔·托姆斯基',   'right')
    'SOV_martemyan_ryutin'       = @('马尔特米扬·里亚京',   'right')
    # --- 联合营 · 季诺维也夫派 ---
    'SOV_grigory_zinovyev'       = @('格里戈里·季诺维也夫', 'united')
    'SOV_lev_kamenev'            = @('列夫·加米涅夫',       'united')
    # --- 工反营 ---
    'SOV_aleksandr_shlyapnikov'  = @('亚历山大·施利亚普尼科夫', 'workers')
    # --- 中立营 ---
    'SOV_mikhail_kalinin'        = @('米哈伊尔·加里宁',     'neutral')
    'SOV_maksim_litvinov'        = @('马克西姆·李维诺夫',   'neutral')
    'SOV_grigory_sokolnikov'     = @('格里戈里·索柯里尼柯夫', 'neutral')
    'SOV_mikhail_tukhachevsky'   = @('米哈伊尔·图哈切夫斯基', 'neutral')
    'SOV_nikolay_voznesensky'    = @('尼古拉·沃兹涅先斯基', 'neutral')
    'SOV_pyotr_smirnov'          = @('彼得·斯米尔诺夫',     'neutral')
    'SOV_grigory_ordzhonikidze'  = @('格里戈里·奥尔忠尼启则', 'neutral')
    'SOV_felix_dzerzhinsky'      = @('费利克斯·捷尔任斯基', 'neutral')
    'SOV_valerian_kuibyshev'     = @('瓦列里安·古比雪夫',   'neutral')
    'SOV_sergei_kirov'           = @('谢尔盖·基洛夫',       'neutral')
    'SOV_anastas_mikoyan'        = @('阿纳斯塔斯·米高扬',   'neutral')
    'SOV_grigory_pyatakov'       = @('格里戈里·皮达可夫',   'neutral')
    'SOV_nikolai_muralov'        = @('尼古拉·穆拉洛夫',     'neutral')
    'SOV_alexandra_kollontai'    = @('亚历山德拉·柯伦泰',   'neutral')
}

# ---------------------------------------------------------------------------
# ① sprite -> texturefile 映射（全 root 的 interface/*.gfx）
# ---------------------------------------------------------------------------
Write-Output '扫描 sprite 注册表……'
$sprMap = @{}
foreach ($root in $ROOTS) {
    $p = Join-Path $root 'interface'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue | ForEach-Object {
        $cur = $null
        foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
            $m = [regex]::Match($line, 'name\s*=\s*"([^"]+)"')
            if ($m.Success) { $cur = $m.Groups[1].Value; continue }
            $m = [regex]::Match($line, 'texturefile\s*=\s*"([^"]+)"')
            if ($m.Success -and $cur -and -not $sprMap.ContainsKey($cur)) {
                $sprMap[$cur] = $m.Groups[1].Value
            }
        }
    }
}
Write-Output ("  sprite 注册 {0} 条" -f $sprMap.Count)

# ---------------------------------------------------------------------------
# ② 磁盘上的立绘文件索引（大图 / 小图）
# ---------------------------------------------------------------------------
Write-Output '索引磁盘立绘文件……'
$bigFiles = @()   # gfx/leaders/**  （大图）
$smFiles  = @()   # gfx/interface/ideas/** （小图）
foreach ($root in $ROOTS) {
    $p = Join-Path $root 'gfx\leaders'
    if (Test-Path $p) { $bigFiles += Get-ChildItem $p -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue }
    $p2 = Join-Path $root 'gfx\interface\ideas'
    if (Test-Path $p2) { $smFiles += Get-ChildItem $p2 -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue }
}
Write-Output ("  大图 {0} 个 / 小图 {1} 个" -f $bigFiles.Count, $smFiles.Count)

function Resolve-Sprite([string]$gfx) {
    if (-not $gfx) { return $null }
    $rel = $sprMap[$gfx]
    if (-not $rel) { return $null }
    foreach ($root in $ROOTS) {
        $f = Join-Path $root ($rel -replace '/', '\')
        if (Test-Path $f) { return [pscustomobject]@{ Path = $f; Root = (Split-Path $root -Leaf) } }
    }
    return $null
}

# ---------------------------------------------------------------------------
# ③ 逐个候选查
# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '=== 逐个候选核对 ==='
Write-Output ("{0,-30} {1,-22} {2,-8} {3,-8} {4}" -f '角色 id', '姓名', '营', '角色块', '立绘')
Write-Output ('-' * 118)

$result = @()
foreach ($cid in $cands.Keys) {
    $name = $cands[$cid][0]
    $camp = $cands[$cid][1]
    $key  = $cid -replace '^SOV_', ''

    # 找角色块
    $block = $null
    $blockFile = $null
    foreach ($root in $ROOTS) {
        $p = Join-Path $root 'common\characters'
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
            if ($block) { return }
            $lines = [System.IO.File]::ReadAllLines($_.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match ('^\s*' + [regex]::Escape($cid) + '\s*=\s*\{')) {
                    $depth = 0
                    $buf = New-Object System.Collections.Generic.List[string]
                    for ($j = $i; $j -lt $lines.Count; $j++) {
                        $buf.Add($lines[$j])
                        $depth += ([regex]::Matches($lines[$j], '\{')).Count - ([regex]::Matches($lines[$j], '\}')).Count
                        if ($j -gt $i -and $depth -le 0) { break }
                    }
                    $block = $buf -join "`n"
                    $blockFile = $_.FullName
                    break
                }
            }
        }
        if ($block) { break }
    }

    $big = $null; $small = $null; $howBig = ''; $howSmall = ''

    if ($block) {
        # ① 角色块里显式写的 large / small sprite
        foreach ($m in [regex]::Matches($block, 'large\s*=\s*"([^"]+)"')) {
            if (-not $big) { $r = Resolve-Sprite $m.Groups[1].Value; if ($r) { $big = $r; $howBig = '角色块 large' } }
        }
        foreach ($m in [regex]::Matches($block, 'small\s*=\s*"([^"]+)"')) {
            if (-not $small) { $r = Resolve-Sprite $m.Groups[1].Value; if ($r) { $small = $r; $howSmall = '角色块 small' } }
        }
        # ② idea_token
        $mt = [regex]::Match($block, 'idea_token\s*=\s*([A-Za-z_0-9]+)')
        if ($mt.Success -and -not $small) {
            $want = 'idea_' + $mt.Groups[1].Value + '.dds'
            $hit = $smFiles | Where-Object { $_.Name -ieq $want } | Select-Object -First 1
            if ($hit) { $small = [pscustomobject]@{ Path = $hit.FullName; Root = '' }; $howSmall = 'idea_token' }
        }
    }

    # ③ 文件名兜底
    if (-not $big) {
        $hit = $bigFiles | Where-Object { $_.Name -imatch $key } | Select-Object -First 1
        if ($hit) { $big = [pscustomobject]@{ Path = $hit.FullName; Root = '' }; $howBig = '文件名匹配' }
    }
    if (-not $small) {
        $hit = $smFiles | Where-Object { $_.Name -imatch $key } | Select-Object -First 1
        if ($hit) { $small = [pscustomobject]@{ Path = $hit.FullName; Root = '' }; $howSmall = '文件名匹配' }
    }

    $verdict = if ($big -and $small) { '大图+小图' }
               elseif ($big) { '仅大图' }
               elseif ($small) { '仅小图（需补大图）' }
               else { '★ 无立绘 → 删' }
    $hasBlock = if ($block) { '有' } else { '无' }

    Write-Output ("{0,-30} {1,-22} {2,-8} {3,-8} {4}" -f $cid, $name, $camp, $hasBlock, $verdict)
    if ($big)   { Write-Output ("       大图：{0}  [{1}]" -f ($big.Path -replace [regex]::Escape($MOD + '\'), 'MOD\'), $howBig) }
    if ($small) { Write-Output ("       小图：{0}  [{1}]" -f ($small.Path -replace [regex]::Escape($MOD + '\'), 'MOD\'), $howSmall) }

    $result += [pscustomobject]@{
        Id = $cid; Name = $name; Camp = $camp; Block = $hasBlock
        Big = [bool]$big; Small = [bool]$small; Verdict = $verdict
    }
}

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output ('=' * 118)
Write-Output '### 结论'
Write-Output ('=' * 118)

$keep = @($result | Where-Object { $_.Big -or $_.Small })
$drop = @($result | Where-Object { -not $_.Big -and -not $_.Small })

Write-Output ''
Write-Output ("【保留】{0} 人" -f $keep.Count)
foreach ($camp in @('left','right','united','workers','neutral')) {
    $g = @($keep | Where-Object { $_.Camp -eq $camp })
    if ($g.Count -eq 0) { continue }
    Write-Output ''
    Write-Output ("  · {0} 营（{1} 人）" -f $camp, $g.Count)
    foreach ($r in $g) {
        $tag = if ($r.Big -and $r.Small) { '大+小' } elseif ($r.Big) { '仅大' } else { '仅小' }
        $nb  = if ($r.Block -eq '有') { '' } else { '  ⚠️无角色块，需新建' }
        Write-Output ("      {0,-32} {1,-22} {2}{3}" -f $r.Id, $r.Name, $tag, $nb)
    }
}

Write-Output ''
Write-Output ("【删除】{0} 人（大图小图都没有）" -f $drop.Count)
foreach ($r in $drop) { Write-Output ("      {0,-32} {1,-22} {2}营" -f $r.Id, $r.Name, $r.Camp) }
