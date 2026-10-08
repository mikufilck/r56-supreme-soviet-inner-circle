# MD37 · 加米涅夫个人线图标交付

2026-09-17：5 张全部完成，按手稿交接、知识体系、文件论战、档案与印刷、巨著传承的顺序逐步加厚构图。

- [整组预览](preview.png) / [可切换背景的页面](preview.html)：左为 100×88，右为 2 倍显示，非游戏截图。
- [统一交付清单](../manifest.json) / [格式校验](../validation.json) / [透明检查报告](check-alpha-report.txt)。
- [完整提示词与调用记录](records/) / [高清源图](source/) / [构图计划](plan.json)。全部由内置 image_gen 绘制。

正式 PNG 在本目录 `GFX_hof_ic_kamenev_*.png`；DDS 在 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`。五个文件名与 MD37 sprite ID 一致。

全部真 alpha、100×88、四角透明、透明率 20%～50%；DDS 为 ARGB8、无 mipmap，与 PNG 解码像素一致。此前 64 张 PNG 哈希保持一致。通过共享 `export_focus.py` 机械缩放编码，未程序绘画或抠图。

接入者按 MD37 重跑 `build/gen-hof-ic-focus-icons.ps1`，替换入口图标兜底并注册 `_shine`。本次未修改游戏脚本，游戏内验收待接入后进行。
