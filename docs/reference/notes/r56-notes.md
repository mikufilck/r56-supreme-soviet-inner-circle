# Road to 56（R56）笔记

> 记录日期：2026-09-13。信息来源：Steam 公开 API（仅元数据）+ R56 官方 GitHub 仓库。
> 原始抓取文件已清理，本文件只保留结论。

## 一、两条分发渠道

| | 稳定版 | 测试版 |
| --- | --- | --- |
| 渠道 | Steam 创意工坊（**仅此一处**） | GitHub `deliciousmods/1956_beta` |
| 标识 | 工坊 ID **`820260968`** | 分支 **`Beta-Edits`** |
| 名称 | The Road to 56 | The Road to 56 [Beta] |
| 体积 | 1307.4 MB | 仓库约 1.57 GB |
| 最后更新 | **2026-09-08** | 持续推送（2026-09-13 仍有提交） |
| Release / Tag | — | **均无**（无打包好的版本包） |
| 适配版本 | 未知（Steam API 不提供文件内容） | 仓库 README 标注 **`[1.19.* Compatibility]`** |

⚠️ 易混淆：工坊 `3506850939`「Road to 56 : Expanded」（759.6 MB）是**另一款 mod**，不是官方本体。

## 二、从 GitHub 手动安装（不需要 Steam）

1. 下载分支源码包：
   `https://github.com/deliciousmods/1956_beta/archive/refs/heads/Beta-Edits.zip`
2. 解压到 `Documents\Paradox Interactive\Hearts of Iron IV\mod\1956_beta\`
   （上游 README 原文即要求把仓库放在 `mod` 目录内）
3. 与 `1956_beta` 文件夹**同级**创建 `1956_beta.mod`。内容取自仓库的 `descriptor.mod`，再补一行 `path`：

```
version="1.14.*"
tags={
	"Beta"
}
name="The Road to 56 [Beta]"
supported_version="1.19.*"
replace_path="history/states"
replace_path="map/strategicregions"
path="mod/1956_beta"
```

- ⚠️ **不要**抄仓库里的 `remote_file_id="1088963694"`——那是工坊条目绑定用的，手动安装写上会出问题。
- 上游 README 说 `.mod` 文件要去其 Discord 的 coding 频道索取；按上面从 `descriptor.mod` 补 `path` 的写法等价。
- 上游 README 另注明：**R56 的文件结构与原版不同**，有自己的命名规范，不遵守会产生严重 bug。

## 三、两个必须知道的机制影响

1. **`replace_path="history/states"` + `replace_path="map/strategicregions"`**
   启用后**原版全部州定义与战略区被整体卸载**，全量使用 R56 自己的版本。
   这既是它与任何改地图/改州 mod 必然冲突的根因，也是 `01-basics.md` §1.8 那条机制的真实案例。

2. **与自建苏联 mod 叠加的成本**
   若要与 R56 共存，覆盖链变成「原版 → R56 → 你的 mod」。且 R56 已大规模重写国策树，其 `soviet.txt` 与原版差异巨大，改动必须基于 **R56 版本**而非原版。

## 四、参考价值

R56 本身是「大规模重写国策树」的标杆项目。它的仓库是研究 `shared_focus` / `joint_focus` / 整树重写手法的**合法且免 Steam** 的样本。

## 五、苏联国策树侦察结论（2026-09-13）

⚠️ 数据取自 **Beta 分支** `common/national_focus/soviet.txt`（稳定版数值会有出入，须以实际文件复核）。原始文件已清理，以下为统计结论。

### 规模对比

| | 原版 1.19.2.0 | R56（Beta） | 差异 |
| --- | --- | --- | --- |
| 字节 | 470,699 | **687,548** | +46% |
| 行数 | 19,860 | **29,564** | +9,704 |
| `focus` 块 | 311 | **449** | +138 |

### 机制使用情况（关键）

| 机制 | 原版 | R56 |
| --- | --- | --- |
| `shared_focus` | 0 | **0** |
| `joint_focus` | 0 | **0** |
| `inlay_window` | 0 | **0** |

**推论：**

1. **两边都没用过这三样机制** → 我们加的共享/联合国策与核心圈在 R56 基座上**没有先例可抄**，范例只能从原版本体借（`habsburg_joint.txt`、`indonesia_joint.txt`、`baltic_shared.txt`、`jap_imperial_influence_inlay_window.txt` 等）。
2. **好消息**：不存在与 R56 现有 id / 机制撞车的问题，挂钩点干净。
3. **坏消息**：树 id 仍叫 **`soviet_focus`**（R56 未改名）。这意味着我们 mod 里那份 `soviet.txt` 必须是**基于 R56 的 29,564 行版本**，不是原版的 19,860 行。
4. 覆盖链变成三层：**原版 → R56 → 我们的 mod**。R56 每次更新 `soviet.txt`，我们都得重新合并。

### 其它参数差异

| 项 | 原版 | R56 |
| --- | --- | --- |
| 树 id | `soviet_focus` | `soviet_focus`（同） |
| `default` | `no` | `no` |
| `continuous_focus_position` | `{ x = 55 y = 1500 }` | `{ x = 55 y = 1500 }` |

### 工程要求

- 我们的 `.mod` **必须排在 R56 之后加载**，否则覆盖不生效。用 `dependencies = { "<R56 的 name>" }` 强制顺序——具体字符串要从 R56 实际的 `.mod` / `descriptor.mod` 里读，不能凭猜。
- 需要一个同步脚本：从 R56 的 `soviet.txt` 自动生成本 mod 的副本，并在固定锚点注入补丁（带 `# hof:begin/end` 标记），R56 更新后重跑即可。

### 备注

GitHub API 有速率限制（本次已触发）；改用 `raw.githubusercontent.com` 直取文件不受此限制，且不受限速。

