# 06 · 地图改动

> 📗 本章已按官方 wiki `Map_modding` 页校正（原文归档：`reference/wiki/Map_modding.txt`，203 KB）。
> 地图仍是 HOI4 modding 门槛最高、最容易崩的部分。

## 6.1 先选对档位

| 类型 | 要改什么 | 难度 | 建议 |
| --- | --- | --- | --- |
| **只改归属 / 人口 / 建筑** | 只动 `history/states/`，完全不碰 `map/` | ★★ | ✅ 绝大多数需求属于这档 |
| **改省份属性、增删省份** | `map/provinces.bmp` + `map/definition.csv` + state 文件 | ★★★★ | 谨慎 |
| **重画地图** | 全套 `map/` | ★★★★★ | 不建议新手 |

## 6.2 `map/` 关键文件（📗 wiki）

| 文件 | 作用 |
| --- | --- |
| `provinces.bmp` | 省份图：每种颜色 = 一个省份 |
| `definition.csv` | 颜色 → 省份属性映射（**分号分隔**，见 6.3） |
| `continent.txt` | 大洲定义，`continents = { ... }`，ID 按声明顺序分配 |
| `heightmap.bmp` | 高度图，尺寸与 `provinces.bmp` 相同 |
| `default.map` | 总配置：各子文件路径、省份上限、海洋起始等 |
| `adjacencies.csv` | 特殊连接（海峡、运河等） |
| `positions.txt` | 省份标注、港口/机场等视觉坐标 |
| `unitstacks.txt` | 部队堆叠显示坐标 |
| `buildings.txt` | 建筑/胜利点图标显示坐标 |
| `airports.txt` | 机场位置 |
| `supply_nodes.txt` / `railways.txt` | 开局补给枢纽与铁路（1.11+ 取代旧补给区） |
| `weatherpositions.txt` | 天气位置 |
| `strategicregions/*.txt` | 战略区 |
| `terrain/`（子目录） | 地形相关资源 |

## 6.3 `definition.csv`（📗 wiki，最易踩坑）

分号分隔，共 8 列：

```
Province ID; R; G; B; Province type (land|sea|lake); Coastal status (true|false); Terrain; Continent (integer)
```

硬性约束：

- **必须使用 CRLF 行尾**。用 LF 会导致报 `Prov ... has no continent`；GIMP 等工具另存时可能悄悄改掉行尾。若**所有**省份都报没大洲，基本就是行尾问题。
- **省份 ID 不能有空缺**。删掉一个省份后，后续 ID 会继承前一个的属性并连锁传递，导致大面积异常；必须填补空位。
- 陆地省份的大洲不能是 0（0 专用于海域）；大洲值必须是整数。
- 陆地省与海/湖省之间**不画边界**；某处边界异常时先查该省的 `Province type`。
- 陆地省必须属于某个已在 `continent.txt` 中声明的大洲。

游戏会在**用户目录**生成 `map/definition.csv.fixed`：含 mod 的 `definition.csv` 全部定义 **再加上**位图上所有未定义的颜色（带默认值）。注意：用户目录比 mod 更早加载，所以这个文件会被 mod 自己的 `definition.csv` 覆盖——查完记得处理。

常见报错（📗 原文）：

| 报错 | 含义 |
| --- | --- |
| `Province X has TOO LARGE BOX. Perhaps pixels are spread around the world in provinces.bmp` | 该省宽/高超过地图的 1/8，通常意味着两个省共用了同一种颜色 |
| `Prov 12345 has no continent` | 陆地省大洲 ID 为 0，或该行不是 CRLF 行尾 |
| `Province X has no pixels in provinces.bmp` | 定义里的颜色在位图上找不到像素；或删省后残留了定义 |

## 6.4 高度图（📗 wiki）

- Y 坐标 1 单位 = 高度值 10；`Y=0` 为纯黑、`Y=25.5` 为纯白；**水位线在 9.5**。想让某处沉入水下，把像素压到水位以下。
- 尺寸与 `provinces.bmp` 相同。
- ⚠️ **Paint.NET 和 MS Paint 不能用来编辑高度图**。
- 法线图由高度图生成：GIMP 用 `Filter → Map → Normal`（需反转 Y 轴），或用 NVIDIA 的 DDS 导出工具；ImageMagick 也可。

## 6.5 省份位图（📗 wiki）

- 用 GIMP / Photoshop 编辑，导出设置必须严格对齐原版（wiki 原文附有 "Correct export settings for provinces.bmp in GIMP" 的截图，见归档）。
- 不要凭记忆写尺寸：以你游戏版本的 `provinces.bmp` 为准。

## 6.6 改归属的推荐流程（不碰 `map/`）

1. 用 `-debug` 启动，鼠标悬停目标省份即可看到**省份 ID 与所在州 ID**（也可以用 nudger 的 Database 分区）。
2. 改对应 `history/states/<id>-<Name>.txt`：

   ```
   state = {
       id = 123
       name = "STATE_123"
       manpower = 1000000
       state_category = city
       provinces = { 1 2 3 }
       owner = GER
       core = GER
       buildings = { ... }
       victory_points = { 100 10 }
   }
   ```

3. 若只想改几个州 → 只放这几个文件即可（同名文件才覆盖，其余仍从原版加载）。
4. 若要**整体接管** → `replace_path = "history/states"`，注意它只卸载该目录**直接的文件**、不含子目录。

## 6.7 工具（📗 wiki）

| 用途 | 工具 |
| --- | --- |
| 内置地图编辑器 | **Nudger**：含 Database、Supply 等分区，可改大洲、补给枢纽、铁路；开 `-debug` 后可从主菜单直接打开 |
| 查省份 / 州 ID | `-debug` 悬停显示，或 nudger 的 Database |
| 位图编辑 | GIMP / Photoshop |
| 生成法线图 | GIMP `Filter → Map → Normal`（反转 Y 轴）或 NVIDIA 工具 |

## 6.8 风险清单

- 动手前**完整备份** `map/` 与 `history/states/`，并先 Git 提交一个干净基线。
- 先只改 1 个测试省/州跑通全流程，再铺开。
- 改 `map/` 后必须同步检查：state 定义、战略区、AI 区域、`positions.txt` / `unitstacks.txt` / `buildings.txt` 坐标、补给与铁路。
- 有 `MAP_ERROR` 时游戏**默认直接崩溃**（提示 "Some errors are present in the map defition …"）；只有开 `-debug` 才能继续加载并看到完整日志。
- 存档兼容：增删省份/州几乎必然破坏旧存档，发布时务必声明。
