# MD46 · 普列奥布拉任斯基国策图标交付

2026-09-17：5 张全部完成，税单与谷堆 → 剪刀差 → 失衡天平 → 两种规律的曲线 → 从田野流向工厂的资源流。采用苏联浮雕与金色月桂，无文字、数字或人物脸部。

- [预览截图](preview.png) / [可切换背景的预览](preview.html)：原尺寸及 2 倍显示，非游戏截图。
- [权威交付清单](../manifest.json)：逐张 PNG、DDS、原图、调用记录与 SHA-256。
- [格式校验](../validation.json) / [透明检查报告](check-alpha-report.txt)。

本目录含 5 张 100×88 RGBA PNG；DDS 已放入 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`，ARGB8、无 mipmap。真 alpha、四角透明、透明率 20–50%，PNG 与 DDS 解码像素一致。此前 80 张 PNG 哈希保持不变。

高清图在 `source/`；[提示词计划](plan.json)及 `records/` 保存逐张提示词、参考路径和实际生成记录。全部通过内置 image_gen 绘制；导出仅缩放与格式转换。已逐张检查原尺寸与放大预览。

接入方需重跑 `build/gen-hof-ic-focus-icons.ps1` 更新缺图兜底并在游戏中验收；本批未修改游戏脚本。
