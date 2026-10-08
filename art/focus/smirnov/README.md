# MD40 · 斯米尔诺夫个人线图标交付

6 张全部完成：桥头堡、第五集团军、西伯利亚革命委员会、远东共和国、邮电人民委员部、雪原结局。以河桥、队伍、木屋、界桩、电线与雪路逐步向东推进，人物仅用背影。

- [整组预览](preview.png) / [可切换背景的页面](preview.html)：左为实际尺寸，右为 2 倍显示，非游戏截图。
- [统一清单](../manifest.json) / [格式校验](../validation.json) / [透明检查报告](check-alpha-report.txt)。
- [完整提示词与调用记录](records/) / [高清源图](source/) / [构图计划](plan.json)。全部采用内置 image_gen 绘制。

正式 PNG 在本目录 `GFX_hof_ic_smirnov_*.png`；DDS 在 `mod/heart_of_iron/gfx/interface/hof_ic/focus/`。六个文件名与 MD40 sprite ID 一致。

全部为 100×88、真 alpha、四角透明，透明率符合 20%～50%。DDS 为 ARGB8、无 mipmap，与 PNG 解码像素一致。此前 69 张 PNG 哈希保持不变。使用共享 `export_focus.py` 机械缩放与编码，未程序绘画或抠图。

接入者重跑 `build/gen-hof-ic-focus-icons.ps1` 即可替换入口兜底并注册 `_shine`。本次未修改游戏脚本，游戏内验收待接入后执行。
