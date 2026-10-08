# 最高苏维埃核心圈 v3 资源

本轮游戏界面使用 `hof_ic_window_bg.png`（760×740）和 `hof_ic_seat_frame.png`（导出为 131×170 的空席、在任两张 DDS）。原图由 imagegen 根据 v2 底板与原席位框重绘；导出路径为 `mod/heart_of_iron/gfx/interface/hof_ic/`。两张席位框使用同一外框，空席与在任由脚本切换剪影和人物肖像。

底板提示词：保留 v2 的黑蓝钢材质、暗红与金色边框及四角麦穗齿轮装饰，延展为 760:740 比例，内部留白，画框铺满画布，不加入文字、肖像或候选小框。

席位框提示词：参照旧空席与在任框，保留苏维埃红星、枪灰色金属及细金线，改为更高的透明头像框，中央及外部透明，不加入人像、字牌或背景。

现行 GUI 坐标的单一数据源是 `build/gen-hof-ic-gui.ps1`；焦点树挂载坐标由 `build/sync-from-r56.ps1` 保持。顶部头像直接引用原版 `GFX_portrait_SOV_supreme_soviet`，不使用生成的仿照图。
