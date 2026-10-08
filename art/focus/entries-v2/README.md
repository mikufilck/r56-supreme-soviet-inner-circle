# MD28 · 候选人入口国策图标交付

修订：图哈切夫斯基圆环内的灰色衬底已按用户要求改为红色，保留灰阶肖像、金色月桂与外部透明；PNG、DDS 和预览同步更新。[本次编辑提示词](records/tukhachevsky-red-correction.json)。

2026-09-16：MD28 的 15 张肖像式入口国策图标全部完成。沿用指定立绘身份，灰阶头肩像搭配职业徽章；根据用户追加意见，使用红色与金色月桂两种配色。

- [整组预览](preview.png) / [可切换背景的预览页面](preview.html)：左为 100×88 原尺寸，右为 2 倍放大，非游戏截图。
- [统一交付清单](../manifest.json)：逐张 PNG、DDS、高清源图与调用记录路径。
- [格式校验](../validation.json) / [透明率检查报告](check-alpha-report.txt)。
- [提示词与生成记录](records/) / [人物参考图](references/) / [高清原图](source/)。全部使用内置 image_gen 逐张生成。

最终 PNG 位于 `art/focus/GFX_hof_ic_seat_<key>.png`，DDS 位于 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`。均为 100×88；DDS 为 ARGB8、无 mipmap，PNG 与 DDS 解码像素完全一致。全部真 alpha、四角为 0，透明率符合 20%～50% 要求。之前 33 张 PNG 的 SHA-256 保持一致。

仅完成美术贴图交付；sprite 注册、候选池扩员与游戏内验收按 MD28 §4 由实现者接入。完整源图和实际提示词已随项目归档，未程序抠图。

`prepare.py` 准备人物参考与清单；`finish.py` 将本批追加到统一清单、调用共享导出器，并生成检查报告和 HTML 预览。
