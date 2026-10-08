# 核心圈国策图标交付

2026-09-15：整套图标已改为真 alpha 透明底并替换 PNG / DDS；交付数量与逐张状态见 [清单](manifest.json)。

布哈林新增批次见 [MD27 交付入口](bukharin/README.md)。

李可夫个人线新增批次见 [MD31 交付入口](rykov/README.md)。

季诺维也夫个人线新增批次见 [MD34 交付入口](zinovyev/README.md)。

加米涅夫个人线新增批次见 [MD37 交付入口](kamenev/README.md)。

斯米尔诺夫个人线新增批次见 [MD40 交付入口](smirnov/README.md)。

谢列布里亚科夫个人线新增批次见 [MD43 交付入口](serebryakov/README.md)。

普列奥布拉任斯基个人线新增批次见 [MD46 交付入口](preobrazhensky/README.md)。

拉狄克个人线新增批次见 [MD49 交付入口](radek/README.md)。

斯米尔加个人线新增批次见 [MD52 交付入口](smilga/README.md)。

托姆斯基个人线新增批次见 [MD55 交付入口](tomsky/README.md)。

里亚京个人线新增批次见 [MD58 交付入口](ryutin/README.md)。

施利亚普尼科夫个人线新增批次见 [MD61 交付入口](shlyapnikov/README.md)。
加里宁个人线新增批次见 [MD64 交付入口](kalinin/README.md)。
李维诺夫个人线新增批次见 [MD67 交付入口](litvinov/README.md)。
索柯里尼柯夫个人线新增批次见 [MD70 交付入口](sokolnikov/README.md)。
图哈切夫斯基个人线新增批次见 [MD73 交付入口](tukhachevsky/README.md)。
拉狄克与图哈切夫斯基扩线新增批次见 [MD93 交付入口](md93/README.md)。
沃兹涅先斯基个人线新增批次见 [MD76 交付入口](voznesensky/README.md)。
彼得·斯米尔诺夫个人线新增批次见 [MD79 交付入口](pyotr_smirnov/README.md)。
马林科夫个人线新增批次见 [MD82 交付入口](malenkow/README.md)。
赫鲁晓夫个人线新增批次见 [MD85 交付入口](khrushchev/README.md)。
伏罗希洛夫个人线新增批次见 [MD88 交付入口](voroshilov/README.md)。

2026-09-16 候选人入口图标新增批次见 [MD28 交付入口](entries-v2/README.md)。

- [总览页面](preview.html)：左侧为原尺寸，右侧为 2 倍预览，可切换浅灰、深灰、纯白、地图棕背景，检查透明轮廓，并打开高清原图。
- [总览截图](preview.png)（素材排版，非游戏截图）。
- [交付清单](manifest.json)含完整焦点 ID、PNG / DDS 路径、来源、尺寸和 SHA-256。
- [校验结果](validation.json)：全部通过尺寸、透明率、DDS 头、无 mipmap、像素往返一致性检查。
- [项目透明率检查](voroshilov/check-alpha-report.txt)：按 MD24 调用现有 `check_alpha.py`，使用工作区 Pillow 依赖。

## 文件

| 内容 | 路径 |
| --- | --- |
| 最终 PNG，RGBA、100×88 | 由 `manifest.json` 的 `png` 字段定位（含批次子目录） |
| 最终 DDS，ARGB8、100×88、无 mipmap | `../../mod/heart_of_iron/gfx/interface/hof_ic/focus/GFX_*.dds` |
| 当前透明高清原图 | 由 `manifest.json` 的 `source` 字段定位 |
| 当前提示词、参考路径、实际调用记录 | 由 `manifest.json` 的 `generation_record` 字段定位 |
| 原始不透明版本的生成计划与高清图 | `generation-plan.json`、`source/`、`records/` |
| 替换前 PNG / DDS 和清单备份 | `transparent-v2/previous-opaque/` |
| 人物参考 PNG | `references/` |
| 未采用草稿 | `drafts/` |

全部图像通过 **内置 image_gen** 绘制。人物依据当前游戏 / DLC / R56 实际肖像；入口装饰参考德国历史肖像 DLC 的生效贴图，专属图参考原版苏联国策图。实际源文件路径保存在清单和调用记录中。

轮廓外采用真实透明背景。人物、职业徽章、红色圆章衬底、月桂与绶带作为主体保留。本轮使用内置 image_gen 逐张编辑，保留生成的 alpha，不采用颜色阈值抠图；生成器输出的假棋盘格版本已排除。

## 导出与接入

`python art/focus/export_focus.py` 从高清原图重新导出整套 PNG / DDS，并生成清单、校验记录与 HTML 总览。使用 Pillow，仅执行 RGBA 转换、Lanczos 缩放及 DDS 编码，没有程序绘画或后期补画。

已逐张查看浅色背景总览中的主体与裁切，文件校验全部通过。PNG 与已有 DDS 路径均已替换，**本次未修改 sprite 注册、国策生成器或游戏脚本**。游戏内显示仍需实际启动验收。
