# MD31 · 李可夫个人线图标交付

5 张全部完成：工业委员会、粮秣供给、劳动国防委员会副主席、扶植航空、劳动国防委员会主席。最后两级委员会共用齿轮盾徽，结局增加工业、铁路与航空的完整调度链。

- [整组预览](preview.png) / [可切换背景的页面](preview.html)：左侧原尺寸，右侧 2 倍显示，非游戏截图。
- [统一交付清单](../manifest.json) / [格式校验](../validation.json) / [透明率报告](check-alpha-report.txt)。
- [完整提示词与调用记录](records/) / [高清源图](source/) / [构图计划](plan.json)。均由内置 image_gen 逐张绘制。

正式 PNG：`art/focus/GFX_hof_ic_rykov_*.png`。正式 DDS：`mod/heart_of_iron/gfx/interface/hof_ic/focus/GFX_hof_ic_rykov_*.dds`。逐张文件名以统一清单为准。

全部为 100×88、真 alpha、四角透明，透明率在 20%～50%。DDS 为无 mipmap 的 ARGB8，与 PNG 解码像素完全一致。此前 48 张 PNG 哈希保持不变。导出使用共享 `export_focus.py`，仅机械缩放和编码，未程序绘画或抠图。

接入：按 MD31 约定，由实现者重跑 `build/gen-hof-ic-focus-icons.ps1`，使这 5 张的入口图标兜底自动消失，并注册 `_shine`。本次交付未修改游戏脚本，游戏内验收待接入后执行。
