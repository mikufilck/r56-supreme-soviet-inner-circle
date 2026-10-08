# 05 · 美术资源：GFX、interface、DDS、旗帜、3D、字体

> ⚠️ 本章的**流程与方法**可信；具体像素尺寸、格式限制等数值需对照原版资源核实（见 `99-todo-verify.md`）。

## 5.1 核心概念：贴图必须先"注册名字"

脚本里引用的从来不是文件路径，而是注册名，通常以 `GFX_` 开头：

```
# interface/hof_icons.gfx
spriteTypes = {
	spriteType = {
		name = GFX_hof_my_icon
		texturefile = "gfx/interface/hof/hof_my_icon.dds"
	}
}
```

之后脚本里就能写 `icon = GFX_hof_my_icon`。

**关键规则**：

- sprite 定义写在 `interface/*.gfx` 里（**注意：不是 `gfx/interface/`**，这是两个完全不同的目录，wiki 专门提醒过）。
- `spriteTypes = { ... }` 是外层块，里面可以放多个 sprite。
- 类型不止 `spriteType`，还有 `corneredTileSpriteType`（任意尺寸拉伸、带角处理）、`frameAnimatedSpriteType`（逐帧动画）等。
- 名字全局唯一。多个同名 sprite 定义时**后求值的胜出**（原版 DLC 就靠这个机制覆盖头像）。
- **不需要 sprite 定义的只有三类**：`gfx/flags/` 下的旗帜、`gfx/loadingscreens/` 下的加载图、角色立绘（可选，允许直接写文件路径）。

## 5.2 图片格式（📗 已更正）

**不强制 DDS**——DDS / TGA / PNG / BMP 都能用，只要 sprite 里的信息正确。DDS 是原版主流选择，典型规格是 **ARGB8（A8R8G8B8）且不带 mipmap**。

两个例外必须记住：

- **旗帜必须是 32 位 TGA、无 RLE 编码、原点在左下角**。
- `map/` 目录下的文件有各自的严格要求（见 `06-map.md`）。

通用注意：

- **透明要写进 alpha 通道**，不要指望"把背景涂成洋红"。
- 尺寸尽量取 2 的幂（256 / 512 / 1024…）。

## 5.3 sprite 出问题时的症状（📗 wiki）

| 症状 | 原因 |
| --- | --- |
| sprite **完全透明** | 图能引用到但加载不了：`texturefile` 路径或文件名不存在、或图片本身损坏。日志中通常伴随 `Texture Handler encountered missing texture file` |
| sprite 显示成**默认占位图** | 问题在 sprite 本身（通常是名字拼错、或没遵守命名格式，例如国策图标漏了 `_shine`） |
| 角色用了**随机生成的头像** | 上面两种之一：sprite 无效或文件缺失 |

> 🚩 **国策图标必须额外提供一个以 `_shine` 结尾的光泽 sprite**，否则图标会显示异常。这是最容易漏的一条。

## 5.4 旗帜

命名规则（⚠️ 以你版本的原版 `gfx/flags/` 实际文件为准）：

```
TAG.tga              # 默认
TAG_fascism.tga      # 按意识形态变体
TAG_communism.tga
TAG_democratic.tga
TAG_neutrality.tga
```

还有不同尺寸/用途的变体（小旗、大旗等）。

**格式硬要求**：32 位 TGA、无 RLE、原点左下。

**最稳妥的做法**：复制原版一个国家的**全部**旗帜文件，改成你的 TAG，逐个替换图案——这样尺寸与命名天然对齐。

搭配脚本：`common/country_tags/*.txt` 里写 `TAG = "gfx/flags/TAG.tga"`。

> 已知坑（📗 wiki）：旗帜有时会**无法覆盖**原版，可尝试新建另一个 mod 把旗帜文件挪进去。

## 5.5 3D 模型（单位、建筑）

- 引擎使用 Paradox 自有格式：`.mesh`（模型）、`.dds`（贴图）、`.anim`（动画）、`.asset`（资源注册）。
- 导出依赖 Paradox 的 DCC 导出插件（官方提供 Maya 插件；社区有 Blender 导出方案）。
- 注册：在 `gfx/models/` 下的 `.asset` 文件中声明，再把 entity 挂到单位定义上。
- ⚠️ 这条链路**门槛高且版本敏感**，动手前务必先查官方 wiki 的 3D 章节，并从一个能跑通的原版模型复制改造开始。

## 5.6 字体与中文

- 字体资源在 `gfx/fonts/`，通过 `interface/*.gfx` 的 `bitmapfont` 定义注册。
- **中文字体需要额外配置**（字库范围、字体文件、`bitmapfont` 定义）。原版中文能正常显示，说明配置存在于原版文件中——**改造时应以原版的字体定义文件为蓝本**。
- ⚠️ 自定义字体文件的具体放置位置与 `ttf` / `fnt` 支持情况，见待核实清单。

## 5.7 界面（GUI）

- 界面布局由 `interface/*.gfx` 中的 `guiTypes` / 窗口定义描述，属于较复杂的部分。
- 小改动（换图标、换文字）通过 `.gfx` 注册 + 本地化即可完成。
- 大改动（新增面板、按钮）需要理解 `guiTypes` 与 `common/scripted_guis/`（⚠️ 可用性待核实）。
- **建议**：任何界面改动都先复制原版文件到自定义文件名下再改，避免整文件覆盖带来的连带破坏。

### 5.7.1 🚩 复用原版素材时的陷阱（踩过一次）

**sprite 名字听起来通用，不代表图像内容也通用。** 必须确认图里有没有国家/阵营符号。

实例：做苏联窗口时想“先借用德国的美术把界面跑通”，选了这几个：

| sprite 名 | 名字给人的感觉 | 实际图像 |
| --- | --- | --- |
| `GFX_ascended_advisors_unappointed_frame` | “未任命的顾问框”，像通用占位框 | **德意志鹰徽** |
| `GFX_circular_frame_fuhrer` | 一个圆形框 | 元首圆框 |
| `GFX_inner_circle_decor_bg` | 核心圈装饰底板 | 德国专属装饰 |

结果整个窗口的每个席位都顶着德国国徽。**这是不可接受的错误，且光看名字发现不了。**

**对策**：复用前先确认图的内容——转 PNG 看一眼，或查它所属的 `.gfx` 文件与目录（放在 `inner_circle/`、`paranoia/` 这类目录下的基本都是某国专属）。

**确认中性的素材（可放心复用）**：

| 类别 | 例子 | 说明 |
| --- | --- | --- |
| 九宫格底板 | `GFX_tiled_plain_bg`、`GFX_tiled_window_thin_border` | `corneredTileSpriteType`，`borderSize = {64 64}`、`tilingCenter = yes` → **四角固定、中间平铺，任意尺寸不变形**，最适合做窗口/面板 |
| 空白立绘 | `GFX_blank_leader_portrait` | 无人像占位 |
| 小徽章条 | `GFX_trait_box_fuhrer` | 名字带 fuhrer 但日本、暹罗的窗口都在复用 → 视觉上是中性色块 |

> ⚠️ 九宫格瓦片要当 `background`（会缩放），**不要当 `iconType`**（不会缩放，会直接溢出）。

### 5.7.2 💡 推荐模式：sprite 间接层

`.gui` 里**只写自己的名字**（如 `GFX_hof_ic_seat_frame_empty`），它实际指向哪张 DDS 由**你自己的 `.gfx` 文件**决定。

好处：美术迭代时**只改 `.gfx` 里的 `texturefile`，`.gui` 一行都不用动**。

这个模式尤其在“先搭结构、后出美术”的流程里价值很大——结构可以先跑通，美术到位后无痛替换。

## 5.8 工作流建议

1. 先确定要引用的**注册名**（`GFX_hof_xxx`）。
2. 出图 → 转成 DDS（正确压缩 + alpha + 2 的幂）。
3. 放进 `gfx/` 下**你自己新建的子目录**（如 `gfx/interface/hof/`）。
4. 在 `interface/hof_*.gfx` 里注册。
5. 启动游戏看 `error.log` 有没有 GFX 相关报错；没问题再在脚本里引用。
6. 视觉效果必须**进游戏目视确认**，不要只看文件不报错就认为成功。
