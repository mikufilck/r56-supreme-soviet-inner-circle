# 核心圈底板 · 640×640 改版

2026-09-14 按 MD16 §0 完成，仅替换 `GFX_hof_ic_window_bg` 的底板贴图。

- [最终 PNG](hof_ic_window_bg.png)：640×640 RGBA，四边铺满，全部像素 alpha=255，无透明留白。
- [最终 DDS](hof_ic_window_bg.dds)：640×640 ARGB8，无 mipmap。
- 已替换 `mod/heart_of_iron/gfx/interface/hof_ic/hof_ic_window_bg.dds`，沿用现有 sprite 注册。
- [高清原图](source/hof_ic_window_bg.png)、[最终提示词及生成记录](generation.json)、[校验结果](validation.json)。使用内置 image_gen，Python 仅做缩放、编码和校验。
- 替换前 DDS 保存为 `previous-hof_ic_window_bg.dds`，旧版 PNG 仍保存在 `../v1/`。

新图沿用深钢、暗金麦穗与齿轮、深红珐琅。已查看 640×640 成品；尺寸、全画布 alpha、DDS 头及像素往返校验通过，其余 10 张 DDS 的 SHA-256 均未改变。

本次未修改 GUI 布局或游戏脚本；游戏内视觉验收待实际启动检查。
