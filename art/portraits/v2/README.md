# MD17 · 第二批立绘交付

2026-09-15 已完成本批全部人物。身份与资源状态的权威登记见 [人物立绘登记表](../../../docs/reference/portrait-registry.md) §1.2。

- [对照预览](preview.html) · [预览截图](preview.png)：游戏小图、最终尺寸与放大预览。
- [交付清单及校验结果](manifest.json)：最终 PNG / DDS 路径、尺寸、哈希、逐张生成记录。
- 高清原图在 `source/`，最终 PNG 在 `png/`；DDS 已放入 MD17 指定的 mod 目录。
- 完整提示词与输入参考路径见 `records/`，采用 **内置 image_gen**，未使用 CLI。

依照游戏小图补完面孔，沿用首批左上柔光、低饱和褐灰色调、灰米色实底。彼得·斯米尔诺夫按他自己的军装小图绘制。

全部导出为 156×210 RGBA PNG / ARGB8 DDS、无 mipmap；DDS 头和像素往返校验通过，已查看最终尺寸对照预览。重新导出命令：`python art/portraits/v2/export.py`，仅执行缩放、编码与校验。

本次仅交付美术，未改 sprite 注册或角色块。游戏内接入与验收由接入方处理。
