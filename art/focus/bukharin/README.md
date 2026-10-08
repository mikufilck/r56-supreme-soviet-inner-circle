# MD27 · 布哈林国策图标交付

2026-09-15 本批完成。需求与名称见 [MD27](../../../docs/27-bukharin-focus-icon-prompts.md)，交付文件的完整信息统一登记在 [总清单](../manifest.json) 的 `bukharin` 分组。

- [本批预览](preview.html) · [预览截图](preview.png)：实际尺寸与 2 倍预览，可切换背景。
- [格式校验](../validation.json) · [项目 alpha 检查](check-alpha-report.txt)。
- 完整生成提示词、参考图与源文件路径在 `records/`；高清原图在 `source/`。全部使用 **内置 image_gen** 绘制。
- 最终 PNG 已放入 `art/focus/`，DDS 已放入 MD27 指定目录，命名与需求逐项匹配。

画面沿用上一批苏联国策图的红色圆章、金色月桂与灰白浮雕；「左翼共产主义」采用更暗的铜色装饰和对立构图。「发财吧」采用粮仓与农具，没有钱币。

使用现有 `art/focus/export_focus.py` 导出。逐张通过尺寸、真实 alpha、四角全透明、透明率 20–50%、DDS 无 mipmap 和像素往返校验；已检查浅色背景下的本批预览。

本次未注册 sprite / `_shine`，未修改国策与游戏脚本；接入方按 MD27 完成注册及游戏内验收。
