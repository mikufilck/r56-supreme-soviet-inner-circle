# 苏联人物立绘 · 第一批七人

按 `docs/17-art-spec-portraits.md` 第 3 节制作，使用内置 `image_gen` 逐人依据小图补画。**七张必补图已全部完成**，斯米尔加的细圆眼镜已于 2026-09-14 补齐；八张可选图等待用户审阅风格后决定。

斯米尔加的修订保留原有面孔、衣着、构图与画风，补上细金属圆框眼镜；修订前大图保存在 `drafts/`，最终提示词见 `records/hof_portrait_SOV_ivar_smilga-revision.json`。修订使用内置 image_gen。

## 交付位置

- 游戏 DDS：`mod/heart_of_iron/gfx/interface/hof_ic/portraits/hof_portrait_SOV_*.dds`（相对项目根目录）。
- 本目录 `png/`：同名 156×210 PNG。
- `source/`：七张生成原始大图。
- `references/`：实际读取的七张小图与两张风格样本的 PNG 解码副本。
- `preview.html` / `preview.png`：参考小图、补画图与 0.5 倍显示的对照。
- `manifest.json` / `records/`：完整提示词、输入依据、原始生成位置与交付文件清单。
- `validation-report.txt`：尺寸、DDS 头、像素往返解码与 Alpha 检查。

所有交付图严格为 **156×210**，PNG 为 RGBA；DDS 为 **32 位含 Alpha、不压缩、无 mipmap**。本批采用与加米涅夫 / 托洛茨基样本一致的灰米色实底，Alpha 全为 255，并非透明剪影。文档允许这种实底方案。

斯米尔加、里亚京、施利亚普尼科夫去除原图牢栏、纸张与囚禁状态，恢复正常衣着。其余人物同样去除顾问图标框与档案纸，保留面孔、帽子及面部毛发等可辨特征。低分辨率小图中不可见的细节为合理绘画补全。

本轮按 MD17 只交付素材，**未修改 sprite 注册、人物定义或游戏脚本**。接入方可按清单名字注册 DDS；游戏内显示与日志检查在接入后进行。

按 MD17 的最新定位，本批属于后续扩展池；当前核心圈选用的另一组人物已有现成立绘。

## 输入路径核对

文档给出的托洛茨基大图不在原版目录，实际从以下 R56 路径读取：

```text
D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\leaders\SOV\r56_portrait_SOV_Leon_Trotsky.dds
```

其余七张小图与加米涅夫样本均按文档原路径读取。三张 imprisoned 小图实测为 **67×69**，其余为 **65×67**。

## 复现机械导出

绘画由内置 image_gen 完成；脚本只解码、缩放及转换格式，不绘制人物。

```powershell
python -m pip install --target tmp/art-python Pillow
python art/portraits/v1/export_portraits.py --force
```

已逐张检查 DDS 解码后与对应 PNG 的 RGBA 像素完全一致。原始大图保留，可继续基于同一张脸修订。
