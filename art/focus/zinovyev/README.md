# MD34 · 季诺维也夫个人线图标交付

2026-09-17：11 张全部完成。A 支线强调大会与纪律，C 支线强调地理与跨国联系，D 支线强调工人组织。两个结局采用同一地球、六面旗帜、双柱门廊和群众的构图，分别为冷灰密集与暖色开放。

- [整组预览](preview.png) / [可切换背景的页面](preview.html)：左为实际尺寸、右为 2 倍显示，非游戏截图。
- [统一交付清单](../manifest.json) / [格式校验](../validation.json) / [透明率检查](check-alpha-report.txt)。
- [逐张完整提示词与调用记录](records/) / [高清源图](source/) / [初始构图计划](plan.json)。实际采用提示词以调用记录为准。

正式 PNG 位于本目录 `GFX_hof_ic_zinovyev_*.png`，正式 DDS 位于 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`。文件名逐项对应 MD34 的 11 个 sprite ID。

全部为 100×88、真 alpha、四角透明，透明率符合 20%～50%。DDS 为 ARGB8、无 mipmap，与 PNG 解码像素完全一致。此前 53 张 PNG 的 SHA-256 保持一致。

使用内置 image_gen 逐张绘制；E1 首次调用被工具输出审核拒绝，没有产生可用图片，明确历史游戏徽章与抽象代表构图后重试成功。未使用程序绘画或抠图。`finish.py` 调用共享 `export_focus.py` 导出；共享导出器现在支持清单指定 PNG 子目录，透明检查也从同一清单读取正式文件。

按 MD34 分工，接入者需要重跑 `build/gen-hof-ic-focus-icons.ps1`，替换缺图兜底并注册 `_shine`。本次仅交付美术，未修改游戏脚本，游戏内验收待接入后执行。
