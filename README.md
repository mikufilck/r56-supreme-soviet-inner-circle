# R56 最高苏维埃核心圈

**R56 Supreme Soviet Inner Circle**

基于 **Hearts of Iron IV** 与 **The road to 56 CN** 的社区子模组。
为苏联最高苏维埃增加核心圈席位、人物国策线与官衔成长，并提供经互会共通
国策及配套决议。游戏内模组名称仍为 **Heart of Iron**。

A community submod for Hearts of Iron IV and The Road to 56 CN, adding a
Supreme Soviet inner circle, character focus branches, advisor progression,
shared COMECON focuses and related decisions. The in-game mod name is
**Heart of Iron**. The current localization and development documentation
are primarily in Simplified Chinese.

## 内容

- 最高苏维埃核心圈与七个席位，22 位人物的个人国策线。
- 官衔升级、席位互斥、民族精神及相关事件。
- 经互会经济、政治、军事三条共通国策线及后来入会成员的补发机制。
- 苏联配套决议、工业企业成长，以及其他国家的兼容性与平衡调整。
- 游戏脚本、美术源文件、生成工具和开发知识库。

具体设计、数值和待验证项目以 [知识库索引](docs/00-index.md)
及其链接的权威文档为准。

## 安装

当前 `descriptor.mod` 支持 **HOI4 1.19.x**，依赖
[The road to 56 CN](https://steamcommunity.com/sharedfiles/filedetails/?id=2129897125)。
需要自行安装游戏、所用内容要求的 DLC 以及基座模组。

1. 克隆仓库或下载 GitHub 的源码 ZIP。
2. 将 `mod/heart_of_iron/` 整个文件夹复制到用户文档目录下的
   `Paradox Interactive/Hearts of Iron IV/mod/heart_of_iron/`。
3. 在同级 `mod/` 目录创建 `heart_of_iron.mod`，内容如下。该文件使用 UTF-8
   无 BOM；`path` 使用正斜杠。

```text
version="0.1.0"
name="Heart of Iron"
tags={ "Alternative History" "Gameplay" "National Focuses" "Translation" }
supported_version="1.19.*"
path="mod/heart_of_iron"
dependencies={ "The road to 56 CN" }
```

4. 在启动器中启用 **The road to 56 CN** 和 **Heart of Iron**，确保子模组在
   R56 之后加载。更换脚本后需要完全退出并重启游戏。

本项目覆盖部分 R56 文件，与修改同一文件的其他模组可能冲突。
游戏更新或重大内容变更后，建议以新局核验；旧档补发与未实测项见
[待验证清单](docs/99-todo-verify.md)。

## 目录与开发

| 路径 | 内容 |
| --- | --- |
| `mod/heart_of_iron/` | 可加载的模组文件，已包含生成后的脚本和贴图 |
| `art/` | 美术源图、交付图、预览与相关说明 |
| `build/` | 构建、同步、注入与校验工具 |
| `docs/` | 设计文档、资料出处和实施记录 |
| `AGENTS.md` | 项目协作规则 |

安装现有模组无需重新生成。修改生成内容时，请先读
[构建说明](build/README.md)、[协作规则](AGENTS.md) 和知识库索引。
工具主要使用 Windows PowerShell 5.1 与 Python，部分图像工具需要 Pillow。
现有脚本含开发机默认路径；在其他电脑运行时应传入脚本提供的路径参数，
或按自己的游戏、R56 与仓库位置调整默认值。

常用静态检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/verify-s2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File build/verify-docs.ps1
```

`verify-s2` 的部分检查需要本地游戏与 R56 文件。静态检查通过不替代游戏内
验收；修改后应检查用户文档目录中的游戏 `logs/error.log`。

编码要求：游戏脚本 UTF-8 无 BOM，本地化 `.yml` 和 PowerShell `.ps1`
使用 UTF-8 BOM，`map/definition.csv` 保留 CRLF。

`old/`、临时目录、虚拟环境、快照、编辑器配置、存档和运行报告不上传。
美术源文件纳入版本管理。

## 开源许可

- 原创代码与项目原创文档：[MIT](LICENSE)。
- 原创美术：[CC BY 4.0](LICENSES/CC-BY-4.0.txt)。
- 第三方内容保留原权利与许可，范围和出处见 [NOTICE](NOTICE.md)。

本项目为非官方社区作品，与 Paradox Interactive 或 R56 团队无隶属关系。
