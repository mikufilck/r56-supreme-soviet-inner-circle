# MD61 · 施利亚普尼科夫国策图标交付

2026-09-24：当前第四版的 6 张图标全部完成，顺序为账本与计划表 → 纸面界线 → 生产者大会 → 文件的两条去路 → 外套与三格日历 → 工人举起名单。

- [六张预览](preview.png) / [可切换背景的预览](preview.html)：左侧原尺寸，右侧 2 倍，非游戏截图。
- [权威交付清单](../manifest.json)：逐张 PNG、DDS、高清原图、生成记录与 SHA-256。
- [格式校验](../validation.json) / [透明检查报告](check-alpha-report.txt)。
- [提示词计划](plan.json)与 `records/`：保存六张实际提示词、参考图路径和生成路径。

本目录含 6 张 100×88 RGBA PNG；DDS 已放入 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`，ARGB8、无 mipmap。四角 alpha 为 0，透明率 20–50%，PNG 与 DDS 解码像素一致。此前 108 张 PNG 的 SHA-256 未变。

六张均由内置 image_gen 绘制，导出仅缩放与格式转换。已检查原尺寸和放大预览；只采用 md61 第四版的六个现行 sprite 名，十个作废名未纳入清单。接入方需重跑 `build/gen-hof-ic-focus-icons.ps1` 并在游戏中验收。
