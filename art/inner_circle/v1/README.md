# 核心圈界面美术 · v1

2026-09-13。11 项素材已绘制、导出并注册；游戏内视觉与 error.log 验收待完成。

用户已允许苏联主题自由设计，德国核心圈仅作功能参考。视觉采用深钢、暗金麦穗、齿轮和深红珐琅；人物为匿名空席剪影，真实角色立绘继续复用现有资源。

## 查看与使用

- `preview.html`：可切换空席/任命状态、深浅透明底的本地预览页。
- `preview.png`：浏览器渲染的预览页截图。组合区域采用美术演示布局，不是游戏截图。
- `png/`：11 张清单尺寸、真实 Alpha 的 PNG。
- `source/`：11 张未经尺寸处理的 AI 原始 PNG，便于继续修订。
- `../../../mod/heart_of_iron/gfx/interface/hof_ic/`：11 张游戏 DDS，32 位 BGRA8、不压缩、无 mipmap。
- `manifest.json`：每张素材的完整最终选用提示词、尺寸及生成来源；使用内置 `image_gen`，没有调用 CLI/API fallback。
- `export-report.txt`：实际尺寸、Alpha 统计和裁切范围。
- `integration-before/`：本次替换前的 `.gfx` 与 inlay 文件备份。

原图存在大面积透明留白的四种横条先裁切透明边，再按约定画布导出。其它素材保留完整原始画布。柔光层沿用生成的颜色与相对 Alpha，将最高 Alpha 归一化到 46/255（约 18%）。导出未增加绘制内容。

重新导出（已有输出需显式 `-Force`）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/export-inner-circle-art.ps1 -Force
```

## 接入范围与验收状态

`interface/hof_ic.gfx` 已注册全部 11 张 DDS。底板保留九宫格类型，源尺寸改为 631×583，90 像素边角保留装饰，中部拉伸；最终效果仍需游戏内确认。原有候选栏横条继续使用中性通用底衬。

`common/focus_inlay_windows/hof_ic_inlay_window.txt` 的 8 个空头像引用已改为本次剪影。席位逻辑、国策与窗口坐标未修改。

柔光与已任命框已交付并注册：当前 GUI 尚未引用柔光，已任命框等待 S3 状态逻辑接入。网页预览展示了这两项的效果，不代表游戏已实现对应切换。

已完成素材逐项缩小检查、预览页浏览器渲染检查及 `verify-s2.ps1` 八项静态预检（失败 0）。`fix-bom.ps1` 检查通过，未改动其它文件编码。

尚未启动游戏验证本次素材。需进入最高苏维埃核心圈检查：九宫格边角、框与头像对齐、中文名牌、原有 GUI 坐标及新增 `hof_` 相关 error.log。现有 GUI 的 620×650 布局不能以网页美术预览替代验收。
