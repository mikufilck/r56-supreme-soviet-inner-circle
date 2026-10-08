# scan-portrait-registry.ps1
# ---------------------------------------------------------------------------
# 核心圈人物立绘总表（**唯一权威扫盘工具**，取代之前零散的 4 个扫描脚本）
#
# ★★ 必须包含 DLC 目录 ★★
#   本项目踩过两次：布哈林 / 李可夫的**大幅立绘在
#   `F:\Hearts of Iron IV\dlc\dlc034_no_step_back\gfx\leaders\SOV\`**，
#   只扫「原版 + R56 + mod」会得出「他们没有大图」的错误结论。
#   贴图按「原版 → DLC → 用户 → mods」覆盖，判断必须多看几份。
#
# ★ 宽松匹配：立绘文件名不一定等于角色 id
#   实测 `SOV_lev_trotsky` 的大图叫 `Portrait_Leon_Trotsky.dds`
#   实测 `SOV_leonid_serebryakov` 的大图叫 `r56_portrait_SOV_Leonid_Serebryakov.dds`
#   → 因此同时输出「全名匹配」与「姓氏宽松匹配」两栏
#
# 产出：docs/reference/reports/portrait-registry.txt
# 人工可读版：docs/reference/portrait-registry.md
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$MOD  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$HOI4 = 'F:\Hearts of Iron IV'

# ---- root 列表：mod → R56 → 原版 → 全部 DLC（顺序 = 加载顺序，后者覆盖前者）----
$ROOTS = @(
    [pscustomobject]@{ Tag = 'MOD';  Path = $MOD  },
    [pscustomobject]@{ Tag = 'R56';  Path = $R56  },
    [pscustomobject]@{ Tag = 'VAN';  Path = $HOI4 }
)
$dlcRoot = Join-Path $HOI4 'dlc'
if (Test-Path $dlcRoot) {
    Get-ChildItem $dlcRoot -Directory | Sort-Object Name | ForEach-Object {
        $ROOTS += [pscustomobject]@{ Tag = ('DLC:' + $_.Name); Path = $_.FullName }
    }
}

Write-Output ('======== 扫描 root（共 {0} 个，含 DLC）========' -f $ROOTS.Count)
foreach ($r in $ROOTS) { Write-Output ('  [{0,-34}] {1}' -f $r.Tag, $r.Path) }

# ---------------------------------------------------------------------------
# 人物表：Key / 中文名 / 营 / 状态
#   状态取值：收（在 19 人池内） / 删（无立绘） / 移出（体制营）
# ---------------------------------------------------------------------------
$people = @(
    # ---- 收：左营 ----
    # ⚠️ Alt = 转写变体（立绘文件名与角色 id 拼写不一致时的额外搜索词）
    #    `SOV_lev_trotsky` 的大图叫 Portrait_**Leon**_Trotsky.dds
    @{ K='lev_trotsky';            Zh='列夫·托洛茨基';            Camp='left';    St='收'; Alt='leon_trotsky' }
    @{ K='yevgeny_preobrazhensky'; Zh='叶夫根尼·普列奥布拉任斯基'; Camp='left';    St='收' }
    @{ K='karl_radek';             Zh='卡尔·拉狄克';              Camp='left';    St='收' }
    @{ K='ivar_smilga';            Zh='伊瓦尔·斯米尔加';          Camp='left';    St='收' }
    @{ K='ivan_smirnov';           Zh='伊万·斯米尔诺夫';          Camp='left';    St='收' }
    @{ K='leonid_serebryakov';     Zh='列昂尼德·谢列布里亚科夫';  Camp='left';    St='收' }
    # ---- 收：右营 ----
    @{ K='nikolay_bukharin';       Zh='尼古拉·布哈林';            Camp='right';   St='收' }
    @{ K='aleksey_rykov';          Zh='阿列克谢·李可夫';          Camp='right';   St='收' }
    @{ K='mikhail_tomsky';         Zh='米哈伊尔·托姆斯基';        Camp='right';   St='收' }
    @{ K='martemyan_ryutin';       Zh='马尔特米扬·里亚京';        Camp='right';   St='收' }
    # ---- 收：联合营 ----
    @{ K='grigory_zinovyev';       Zh='格里戈里·季诺维也夫';      Camp='united';  St='收' }
    @{ K='lev_kamenev';            Zh='列夫·加米涅夫';            Camp='united';  St='收' }
    # ---- 收：工反营 ----
    @{ K='aleksandr_shlyapnikov';  Zh='亚历山大·施利亚普尼科夫';  Camp='workers'; St='收' }
    # ---- 收：中立营 ----
    @{ K='mikhail_kalinin';        Zh='米哈伊尔·加里宁';          Camp='neutral'; St='收' }
    @{ K='maksim_litvinov';        Zh='马克西姆·李维诺夫';        Camp='neutral'; St='收' }
    @{ K='grigory_sokolnikov';     Zh='格里戈里·索柯里尼柯夫';    Camp='neutral'; St='收' }
    @{ K='mikhail_tukhachevsky';   Zh='米哈伊尔·图哈切夫斯基';    Camp='neutral'; St='收' }
    @{ K='nikolay_voznesensky';    Zh='尼古拉·沃兹涅先斯基';      Camp='neutral'; St='收' }
    # ⚠️ smirnov 姓氏碰撞：伊万·斯米尔诺夫与彼得·斯米尔诺夫同姓。
    #    `portrait_SOV_ivan_smirnov.dds` 是伊万的 → 彼得的姓氏兜底必须排除 "ivan"
    @{ K='pyotr_smirnov';          Zh='彼得·斯米尔诺夫';          Camp='neutral'; St='收'; Ex='ivan' }
    # ---- 删：无立绘 ----
    @{ K='grigory_ordzhonikidze';  Zh='格里戈里·奥尔忠尼启则';    Camp='neutral'; St='删' }
    @{ K='felix_dzerzhinsky';      Zh='费利克斯·捷尔任斯基';      Camp='neutral'; St='删' }
    @{ K='valerian_kuibyshev';     Zh='瓦列里安·古比雪夫';        Camp='neutral'; St='删' }
    @{ K='sergei_kirov';           Zh='谢尔盖·基洛夫';            Camp='neutral'; St='删' }
    @{ K='anastas_mikoyan';        Zh='阿纳斯塔斯·米高扬';        Camp='neutral'; St='删' }
    @{ K='grigory_pyatakov';       Zh='格里戈里·皮达可夫';        Camp='neutral'; St='删' }
    @{ K='nikolai_muralov';        Zh='尼古拉·穆拉洛夫';          Camp='neutral'; St='删' }
    @{ K='alexandra_kollontai';    Zh='亚历山德拉·柯伦泰';        Camp='neutral'; St='删' }
    # ---- 移出：体制营 ----
    @{ K='vyacheslav_molotov';     Zh='维亚切斯拉夫·莫洛托夫';    Camp='regime';  St='移出' }
    @{ K='lazar_kaganovich';       Zh='拉扎尔·卡加诺维奇';        Camp='regime';  St='移出' }
    @{ K='kliment_voroshilov';     Zh='克利缅特·伏罗希洛夫';      Camp='regime';  St='移出' }
    # ⚠️ Malenkow(w) vs Malenkov(v)、Khrushchyov vs Khrushchev —— 俄文转写差异，姓氏兜底会失败
    @{ K='georgy_malenkow';        Zh='格奥尔基·马林科夫';        Camp='regime';  St='移出'; Alt='malenkov' }
    @{ K='nikita_khrushchyov';     Zh='尼基塔·赫鲁晓夫';          Camp='regime';  St='移出'; Alt='khrushchev' }
    @{ K='lavrenty_beriya';        Zh='拉夫连季·贝利亚';          Camp='regime';  St='移出' }
    @{ K='nikolay_yezhov';         Zh='尼古拉·叶若夫';            Camp='regime';  St='移出' }
    @{ K='genrikh_yagoda';         Zh='亨里希·亚戈达';            Camp='regime';  St='移出' }
    @{ K='vsevolod_merkulov';      Zh='弗谢沃洛德·梅尔库洛夫';    Camp='regime';  St='移出' }
)

# ---------------------------------------------------------------------------
# 索引：大图 / 小图 / sprite 注册表
# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '索引磁盘文件……'
$bigAll = @(); $smAll = @(); $sprMap = @{}
foreach ($r in $ROOTS) {
    $p = Join-Path $r.Path 'gfx\leaders'
    if (Test-Path $p) {
        Get-ChildItem $p -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue |
            ForEach-Object { $bigAll += [pscustomobject]@{ F=$_; Root=$r.Tag } }
    }
    # ★ 本项目补画的大图放这里（GPT 交付的 156×210），不在 gfx\leaders 下
    $p = Join-Path $r.Path 'gfx\interface\hof_ic\portraits'
    if (Test-Path $p) {
        Get-ChildItem $p -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue |
            ForEach-Object { $bigAll += [pscustomobject]@{ F=$_; Root=($r.Tag + '/hof_ic') } }
    }
    $p = Join-Path $r.Path 'gfx\interface\ideas'
    if (Test-Path $p) {
        Get-ChildItem $p -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue |
            ForEach-Object { $smAll += [pscustomobject]@{ F=$_; Root=$r.Tag } }
    }
    $p = Join-Path $r.Path 'interface'
    if (Test-Path $p) {
        Get-ChildItem $p -Recurse -File -Filter *.gfx -ErrorAction SilentlyContinue | ForEach-Object {
            $cur = $null
            foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
                $m = [regex]::Match($line, 'name\s*=\s*"([^"]+)"')
                if ($m.Success) { $cur = $m.Groups[1].Value; continue }
                $m = [regex]::Match($line, 'texturefile\s*=\s*"([^"]+)"')
                if ($m.Success -and $cur -and -not $sprMap.ContainsKey($cur)) {
                    $sprMap[$cur] = [pscustomobject]@{ Rel = $m.Groups[1].Value; Root = $r.Tag; Src = $_.FullName }
                }
            }
        }
    }
}
Write-Output ('  大图 {0} 个 / 小图 {1} 个 / sprite {2} 条' -f $bigAll.Count, $smAll.Count, $sprMap.Count)

function Resolve-Sprite([string]$gfx) {
    if (-not $gfx -or -not $sprMap.ContainsKey($gfx)) { return $null }
    $e = $sprMap[$gfx]
    $rel = $e.Rel -replace '/', '\'
    foreach ($r in $ROOTS) {
        # texturefile 写的是相对路径；按声明它的 root 优先，其余 root 兜底
        $f = Join-Path $r.Path $rel
        if (Test-Path $f) { return [pscustomobject]@{ Path=$f; Root=$r.Tag; Decl=$e.Root } }
    }
    return [pscustomobject]@{ Path=$null; Root=$null; Decl=$e.Root; Missing=$e.Rel }
}

Write-Output ''
Write-Output '======== 逐个核对 ========'
Write-Output ''
Write-Output ('{0,-24} {1,-24} {2,-8} {3,-6} {4,-6} {5,-6} {6}' -f '角色 id','中文名','营','状态','大图','小图','角色块')
Write-Output ('-' * 118)

$rows = @()
foreach ($p in $people) {
    $cid = 'SOV_' + $p.K

    # ---- 角色块 ----
    $block = $null; $blockPath = $null
    foreach ($r in $ROOTS) {
        $dir = Join-Path $r.Path 'common\characters'
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem $dir -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
            if ($block) { return }
            $lines = [System.IO.File]::ReadAllLines($_.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match ('^\s*' + [regex]::Escape($cid) + '\s*=\s*\{')) {
                    $d = 0; $buf = New-Object System.Collections.Generic.List[string]
                    for ($j = $i; $j -lt $lines.Count; $j++) {
                        $buf.Add($lines[$j])
                        $d += ([regex]::Matches($lines[$j],'\{')).Count - ([regex]::Matches($lines[$j],'\}')).Count
                        if ($j -gt $i -and $d -le 0) { break }
                    }
                    $block = $buf -join "`n"; $blockPath = $_.FullName; break
                }
            }
        }
        if ($block) { break }
    }

    $big = $null; $howBig = ''
    $small = $null; $howSmall = ''

    if ($block) {
        foreach ($m in [regex]::Matches($block, 'large\s*=\s*"([^"]+)"')) {
            if (-not $big) { $x = Resolve-Sprite $m.Groups[1].Value; if ($x -and $x.Path) { $big = $x; $howBig = '角色块' } }
        }
        foreach ($m in [regex]::Matches($block, 'small\s*=\s*"([^"]+)"')) {
            if (-not $small) { $x = Resolve-Sprite $m.Groups[1].Value; if ($x -and $x.Path) { $small = $x; $howSmall = '角色块' } }
        }
        $mt = [regex]::Match($block, 'idea_token\s*=\s*([A-Za-z_0-9]+)')
        if ($mt.Success -and -not $small) {
            $want = 'idea_' + $mt.Groups[1].Value + '.dds'
            $hit = $smAll | Where-Object { $_.F.Name -ieq $want } | Select-Object -First 1
            if ($hit) { $small = [pscustomobject]@{ Path=$hit.F.FullName; Root=$hit.Root }; $howSmall = 'idea_token' }
        }
    }
    # ---- 搜索键：角色 id + 转写变体别名 ----
    $skeys = @($p.K)
    if ($p.Alt) { $skeys += ($p.Alt -split ',') }

    # ---- 文件名兜底（全名精确 -> 姓氏宽松，均可带排除正则）----
    # 排除正则 + 多命中都赋值：前两版分别因为「多命中就放弃」（托洛茨基被误判缺图）
    # 和「不排除同姓」（彼得·斯米尔诺夫误用伊万的大图）出错。
    # 第三版加 Alt：处理 Malenkow/Malenkov 类转写差异。
    $exOk = { param($n) -not ($p.Ex) -or ($n -inotmatch $p.Ex) }
    if (-not $big) {
        foreach ($sk in $skeys) {
            $hit = $bigAll | Where-Object { $_.F.Name -imatch [regex]::Escape($sk) -and (& $exOk $_.F.Name) } | Select-Object -First 1
            if ($hit) { $big = [pscustomobject]@{ Path=$hit.F.FullName; Root=$hit.Root }; $howBig = '全名'; break }
        }
    }
    if (-not $small) {
        foreach ($sk in $skeys) {
            $hit = $smAll | Where-Object { $_.F.Name -imatch [regex]::Escape($sk) -and (& $exOk $_.F.Name) } | Select-Object -First 1
            if ($hit) { $small = [pscustomobject]@{ Path=$hit.F.FullName; Root=$hit.Root }; $howSmall = '全名'; break }
        }
    }
    if (-not $big) {
        foreach ($sk in $skeys) {
            $sn = ($sk -split '_')[-1]
            $hits = @($bigAll | Where-Object { $_.F.Name -imatch $sn -and (& $exOk $_.F.Name) })
            if ($hits.Count -ge 1) {
                $big = [pscustomobject]@{ Path=$hits[0].F.FullName; Root=$hits[0].Root }
                $howBig = if ($hits.Count -eq 1) { '姓氏' } else { ('姓氏(命中' + $hits.Count + ')') }
                break
            }
        }
    }
    if (-not $small) {
        foreach ($sk in $skeys) {
            $sn = ($sk -split '_')[-1]
            $hits = @($smAll | Where-Object { $_.F.Name -imatch $sn -and (& $exOk $_.F.Name) })
            if ($hits.Count -ge 1) {
                $small = [pscustomobject]@{ Path=$hits[0].F.FullName; Root=$hits[0].Root }
                $howSmall = if ($hits.Count -eq 1) { '姓氏' } else { ('姓氏(命中' + $hits.Count + ')') }
                break
            }
        }
    }

    $hb = if ($big) { 'Y' } else { '-' }
    $hs = if ($small) { 'Y' } else { '-' }
    $hblk = if ($block) { 'Y' } else { '-' }
    $flag = ''
    if ($howBig -like '姓氏(命中*') { $flag = ' ⚠多命中需人工确认' }
    Write-Output ('{0,-24} {1,-24} {2,-8} {3,-6} {4,-6} {5,-6} {6}{7}' -f $cid, $p.Zh, $p.Camp, $p.St, $hb, $hs, $hblk, $flag)
    if ($big)   { Write-Output ('      大图[{0,-12}] {1}' -f $howBig, $big.Path) }
    if ($small) { Write-Output ('      小图[{0,-12}] {1}' -f $howSmall, $small.Path) }

    $rows += [pscustomobject]@{
        Id=$cid; Zh=$p.Zh; Camp=$p.Camp; St=$p.St
        Big=[bool]$big; Small=[bool]$small; Block=[bool]$block
        BigPath= if($big){$big.Path}else{''};      BigHow=$howBig
        SmallPath=if($small){$small.Path}else{''}; SmallHow=$howSmall
        BlockPath=if($blockPath){$blockPath}else{''}
    }
}

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output ('=' * 118)
Write-Output '### 汇总'
Write-Output ('=' * 118)

$in = @($rows | Where-Object { $_.St -eq '收' })
Write-Output ''
Write-Output ('【19 人池】大图 {0} / 只有小图 {1} / 都没有 {2}' -f `
    @($in | Where-Object {$_.Big}).Count, `
    @($in | Where-Object {-not $_.Big -and $_.Small}).Count, `
    @($in | Where-Object {-not $_.Big -and -not $_.Small}).Count)

Write-Output ''
Write-Output '--- ★ 仍缺大图（要交给出图方）---'
foreach ($r in ($in | Where-Object { -not $_.Big } | Sort-Object Camp, Id)) {
    $s = if ($r.Small) { '有小图可作参照' } else { '连小图都没有' }
    Write-Output ('   {0,-26} {1,-24} {2,-8} {3}' -f $r.Id, $r.Zh, $r.Camp, $s)
}

Write-Output ''
Write-Output '--- 已有大图 ---'
foreach ($r in ($in | Where-Object { $_.Big } | Sort-Object Camp, Id)) {
    Write-Output ('   {0,-26} {1,-24} {2,-8} [{3}]' -f $r.Id, $r.Zh, $r.Camp, $r.BigHow)
}

Write-Output ''
Write-Output '--- 已删 / 已移出（仅登记，供日后复查）---'
foreach ($r in ($rows | Where-Object { $_.St -ne '收' } | Sort-Object St, Id)) {
    $a = if ($r.Big) { '大Y' } else { '大-' }
    $b = if ($r.Small) { '小Y' } else { '小-' }
    $c = if ($r.Block) { '块Y' } else { '块-' }
    Write-Output ('   [{0,-4}] {1,-26} {2,-24} {3} {4} {5}' -f $r.St, $r.Id, $r.Zh, $a, $b, $c)
}
