# MD24 · 托洛茨基线国策图标

2026-09-14 完成 **24 张：7 张人物入口 + 17 张托洛茨基专属**。

- [总览页面](preview.html)：左侧为 100×88 原尺寸，右侧为 2 倍预览，可切换只看原尺寸，并打开高清原图。
- [总览截图](preview.png)（素材排版，非游戏截图）。
- [交付清单](manifest.json)含完整焦点 ID、PNG / DDS 路径、来源、尺寸和 SHA-256。
- [校验结果](validation.json)：24 张全部通过尺寸、DDS 头、无 mipmap、像素往返一致性检查。

## 文件

| 内容 | 路径 |
| --- | --- |
| 最终 PNG，RGBA、100×88 | 本目录 `GFX_*.png` |
| 最终 DDS，ARGB8、100×88、无 mipmap | `../../mod/heart_of_iron/gfx/interface/hof_ic/focus/GFX_*.dds` |
| 高清原图 | `source/` |
| 全部生成提示词与参考路径 | `generation-plan.json` |
| 实际逐张调用记录、原始生成文件路径 | `records/`（托洛茨基入口以 `-revision.json` 为最终版） |
| 人物参考 PNG | `references/` |
| 未采用草稿 | `drafts/` |

全部图像通过 **内置 image_gen** 绘制。人物依据当前游戏 / DLC / R56 实际肖像；入口装饰参考德国历史肖像 DLC 的生效贴图，专属图参考原版苏联国策图。实际源文件路径保存在清单和调用记录中。

采用深炭色不透明背景、无文字与水印。人物入口使用灰阶肖像、金色与暗红装饰及职业徽章；专属图使用灰白浮雕、红星、暗红圆章、金色月桂和空白绶带。

## 导出与接入

`python art/focus/export_focus.py` 从高清原图重新导出整套 PNG / DDS，并生成清单、校验记录与 HTML 总览。使用 Pillow，仅执行 RGBA 转换、Lanczos 缩放及 DDS 编码，没有程序绘画或后期补画。

已逐张查看总览中的主体与裁切，文件校验全部通过。DDS 是随 PNG 提供的接入素材；**本次未修改 sprite 注册、国策生成器或游戏脚本**。按 MD24 §4，由接入方继续注册与替换占位图，再做游戏内验收。
