# 04 · 本地化（Translation / Localisation）

## 4.1 语言与文件名（📗 官方硬性要求）

官方支持 9 种语言。**文件名必须含语言内部名，否则整个文件不会被加载**：

| 语言 | 文件名后缀 | 示例 |
| --- | --- | --- |
| 英语 | `_l_english.yml` | `localisation/english/xx_l_english.yml` |
| 法语 | `_l_french.yml` | `localisation/french/xx_l_french.yml` |
| 德语 | `_l_german.yml` | `localisation/german/xx_l_german.yml` |
| 西班牙语 | `_l_spanish.yml` | `localisation/spanish/xx_l_spanish.yml` |
| 巴西葡语 | `_l_braz_por.yml` | `localisation/braz_por/xx_l_braz_por.yml` |
| 波兰语 | `_l_polish.yml` | `localisation/polish/xx_l_polish.yml` |
| 俄语 | `_l_russian.yml` | `localisation/russian/xx_l_russian.yml` |
| 日语 | `_l_japanese.yml` | `localisation/japanese/xx_l_japanese.yml` |
| **简体中文** | `_l_simp_chinese.yml` | `localisation/simp_chinese/hof_events_l_simp_chinese.yml` |

注意 `l` 是**小写字母 L**（不是数字 1，也不是大写 I）。子目录名是习惯，真正决定语言归属的是**文件名后缀**。游戏当前语言在用户目录的 `pdx_settings.txt` 中设置。

> 🚩 **本项目原计划的 `localisation/simp_chinese/hof_events.yml` 是错的**，必须写成 `hof_events_l_simp_chinese.yml`，否则一条都不会加载。

## 4.2 文件内容格式

**首行必须是语言库声明**（语言名 + 冒号，冒号后什么都不加）：

```
l_simp_chinese:

hof_event.1.t:0 "一个新黎明"
hof_event.1.d:0 "议会终于通过了改革法案。\n这是第二行。"
hof_event.1.a:0 "很好。"
```

| 规则 | 说明 |
| --- | --- |
| `l_<语言>:` | 首行必写；直到下一个库声明或文件结束，之后的键都归入该语言。**缺了它 + 文件有 BOM + 含键 → 可能崩溃 `0xC0000005 (3221225477)`** |
| `键:版本号 "值"` | 版本号只允许数字，且**游戏根本不读它，可完全省略**（写成 `键 "值"` 亦可） |
| 键的字符集 | 只允许**英文字母、下划线、点、连字符、数字**。含空格 / 变音符号 / 非拉丁字符会**从该处起破坏整个文件**（日志报 `Expected colon(:) at line ...`） |
| 值必须在一行内 | 多行会破坏文件。换行用 `\n`，且 **`\n` 后面不要跟空格**（游戏里会显示成缩进） |
| 引号 | 值必须用英文双引号包裹；值里要输出引号用 `\"` |
| 注释 | `#` 开头的整行被忽略 |

⚠️ 任何一处语法错误都会让文件**从出错点开始全部失效**。所以**第一个报错才是根因**，不要只盯着最后一条。

字体覆盖不到的生僻字会被游戏显示成 `?`，这是字体问题，不是本地化问题。

## 4.3 ⚠️ 最大的坑：BOM

**`.yml` 文件必须保存为 UTF-8 with BOM。**

- 没有 BOM：中文乱码，或整个文件被静默丢弃，界面上显示原始键名。
- 有 BOM 但后缀不是 `.yml`：不加载。
- VS Code 里设置方法：右下角编码 → Save with Encoding → **UTF-8 with BOM**。
- 建议在 `.vscode/settings.json` 里指定：

```json
{
	"files.encoding": "utf8bom",
	"[yaml]": { "files.encoding": "utf8bom" }
}
```

## 4.4 文本里的特殊写法

| 写法 | 作用 |
| --- | --- |
| `\n` | 换行 |
| `£icon_name` | 插入已注册的图标（如政治点、人力图标） |
| `$VAR$` | 引用一个已定义的变量/局部化变量 |
| `§Y文本§!` | 颜色：`Y` 黄、`R` 红、`G` 绿、`W` 白等，`§!` 结束变色 |
| `[This.GetName]` 之类 | 数据函数（取名字/数值）⚠️ 支持范围随版本变化，详见待核实清单 |
| `\"` | 值里要输出双引号时的转义 |

## 4.5 排查清单

界面显示成 `hof_event.1.t` 这样的原始键名时，按顺序查：

1. 键名拼写是否和脚本里**完全一致**（大小写敏感）。
2. 文件是否在 `localisation/<语言>/` 目录内。
3. 文件后缀是否 `.yml`。
4. 文件是否 UTF-8 **with BOM**。
5. 行格式是否漏了 `:0`，或值没用英文双引号。
6. 你玩的游戏语言是否就是那个目录（游戏内设置 → 语言）。

## 4.6 覆盖原版文本：用 `replace/` 文件夹（📗 官方技巧）

**不要**为了改一个词就把原版整个 `.yml` 复制过来——原版会频繁增删键，你的副本很快过时。

正确做法：把文件放进名为 **`replace`** 的子文件夹，它会优先于非 `replace` 里的条目：

```
localisation/english/replace/mod_replace_l_english.yml
```

```
l_english:

POLITICS_ADD_POLITICAL_POWER:0 "新文本：$VAL|=+0$。"
```

这样只覆盖你写的那几个键，其余继续走原版，版本升级时几乎不用维护。

键重复的情况会记录在用户目录的 `logs/text.log`。⚠️ 普通（非 `replace`）重复时的取值优先级**没有稳定规律**，看起来偏向原版文件——所以想要**稳定**覆盖就必须用 `replace/`。

## 4.7 颜色与特殊字符（📗 官方字符表）

颜色规则以**节符号 `§`** 开始 + 一个字母，以 `§!` 结束。**必须写结束符**，否则颜色会溢出到后面的文本。

| 代码 | 颜色 | RGB |
| --- | --- | --- |
| `§!` | 结束当前规则 | — |
| `§Y` / `§H` | 黄（H = header） | 255, 189, 0 |
| `§W` / `§T` | 白（T = Title） | 255, 255, 255 |
| `§R` | 红 | 255, 50, 50 |
| `§G` | 绿 | 0, 159, 3 |
| `§B` | 蓝 | 0, 0, 255 |
| `§C` | 青 | 35, 206, 255 |
| `§O` | 橙 | 255, 112, 25 |
| `§L` | 灰橙（lilac） | 195, 176, 145 |
| `§g` | 浅灰 | 176, 176, 176 |
| `§b` | 黑 | 0, 0, 0 |
| `§0`~`§9`、`§t` | 渐变色阶（详见归档） | — |

其它特殊写法：

| 写法 | 作用 |
| --- | --- |
| `\n` | 换行（后面别跟空格） |
| `\"` | 在值里输出双引号 |
| `£icon_name` | 插入已注册的文本图标 |
| `$VAR$`、`$VAL|=+0$` | 变量与格式化 |
| `[TAG.GetName]` | 动态本地化（**只在这些 `.yml` 里生效，写在普通字符串里无效**） |

新增颜色可用 `interface/core.gfx` 里的 `textcolors = { ... }` 扩展，但**颜色键不能超过 1 个字母**（多字母会覆盖同首字母的键）。

**报错**：颜色问题不提示文件和行号，只说字符：

- `Could not find coloring for character 'M'` → 某处写了 `§M`
- `Could not find coloring for character ' '` → `§` 后面缺了字母（通常是漏掉 `§!` 的 `!`）
- `Could not find coloring for character id '0'` → `§` 后面什么都没有（即字符串以 `§` 结尾）

搜索时**不能用 Windows 资源管理器**（它不搜 `.yml`），要用 VS Code 的全局搜索。

## 4.7 命名规范（本项目）

| 对象 | 键名 |
| --- | --- |
| 事件 | `heartofiron.<n>.t` / `.d` / `.a` / `.b` |
| 国策 | `hof_<focus_id>` / `hof_<focus_id>_desc` |
| 决议 | `hof_<decision_id>` / `hof_<decision_id>_desc` |
| 想法 | `hof_<idea_id>` / `hof_<idea_id>_desc` |
| 通用 tooltip | `hof_tt_<说明>` |
