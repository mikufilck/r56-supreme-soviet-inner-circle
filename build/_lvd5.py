# -*- coding: utf-8 -*-
import os, subprocess
os.chdir(r'd:\Users\xuwei\PycharmProjects\heart_of_Iron')
WS = os.getcwd()

# ---- 清理临时脚本 ----
for f in ['_lvi1.py', '_lvi2.py', '_lvi3.py', '_lv67.py', '_lvd1.py', '_lvd2.py', '_lvd3.py',
          '_lvd4.py', '_gen.log', '_gen.txt', '_out.txt', '_dm.txt', '_verr.txt',
          '_sync-from-r56.txt', '_verify-s2.txt']:
    p = os.path.join('build', f)
    if os.path.exists(p):
        os.remove(p); print('rm', f)

# ---- 记忆 ----
MEM = os.path.join(os.environ['APPDATA'], 'Code', 'User', 'workspaceStorage',
                   '82ec085de9c284eec1fb61bba6fa5acb', 'GitHub.copilot-chat',
                   'memory-tool', 'memories', 'repo', 'hoi4-modding.md')
raw = open(MEM, 'rb').read()
body = raw.decode('utf-8').rstrip('\r\n')
ADD = '''

## ✅ 第二十轮：李维诺夫（Idx 15）个人线实装（2026-09-19）

📄 `docs/65`（谱系）· `docs/66`（设计）· **`docs/67`（出图，新）** · `docs/18` §25 · `docs/99` §21

### 形状
- **单线 5 节点 + 1 单结局 = 6 块**（`$litvinovLine`，x 全 0，y = 1,2,3,4,5,**7**）
- 节点：火星报的代办员 → 战俘交换协议 → 李维诺夫议定书 → 侵略的定义 → 苏法互助条约 →
  E1 **外交人民委员会顾问**
- **官衔链四级**（驻爱沙尼亚代表 → 外交副人民委员 → 外交人民委员 → **驻国联代表**）；门槛 A2 / A3 / A4
- **文案 2/6 中文原文**（A1 托洛茨基中译本 / A2 中文版文集电报）

### 🔴 用户口径（两道、9 项，**全部在提案阶段 → 零返工**）
- ① **「国联的席位改一下，有其他选项吗（二战国联已经实际失效）」**
- ② **「乙，A5 可以，实装吧」** → **E1 取【乙】「外交人民委员会顾问」**（我推荐甲「驻美特命全权大使」，用户取乙）
  ⭐ 教训：**结局名不要挂在【已经失效的组织】上** —— 这是判据 F 之外的**第二条命名纪律**。

### ⭐⭐⭐ 本轮最有价值的一处：A5 的「用数值差写史实里的不对等」
- **先查清原版**：`SOV_policy_of_collective_security` 完成时调
  `SOV_apply_collective_ageement_on_mutual_assistance_effects_basic`
  （`common/scripted_effects/SOV_scripted_effects.txt` **L3332**），三件套 =
  `non_aggression_pact` + 双向 `give_guarantee` + 双向 `add_opinion_modifier`
  （`SOV_policies_of_collective_security_opinion`，value 50 / months 36，`nsb_opinion_modifiers.txt` L185）
- ⛔ **本线不照抄**（照抄＝重复原版 + 玩家叠两次）
- ✅ **做原版没做的那一半 —— 史实的那条链子**：
  **法国** = 双向互不侵犯 + 双向互相保障 + **双向好感 50**；
  **捷克** = ⭐ **只给好感 25、不给保障**（**史实：1935-05-16 苏捷条约议定书 —— 法国先动，捷克才动**）；
  **苏联** = ⛔ **不给任何军事加成**（**史实：1935 年条约没有军事参谋协定**）
- 📌 **可复用套路**：**A 与 B 名义上同一条约、实际义务不对等时，用 opinion value 的差把史实写出来。**
- ⚠️ `give_guarantee` 必须用 `if = { limit = { X = { is_subject = no  NOT = { has_war_with = ROOT } } } }` 包住

### 📌 数字变化（**回写时别改错**）
| 项 | 前（加里宁后） | **后（李维诺夫后）· 实测** |
| --- | --- | --- |
| 国策块 | 121 | **127**（22 入口 + **104** 个人线 + 1 人民委员） |
| sprite | 120 | **126** |
| **已交付** | 97 | **108**（⭐ **本轮美术交付 11 张：托姆斯基 6 + 里亚京 5**） |
| 缺图兜底 | 23 | **18**（= 加里宁 6 + 李维诺夫 6 + 施利亚普尼科夫 6，**只剩三条线**） |
| 个人线驱动器 | 14 | **15** |
| 事件 | 33 | **35**（Idx 15 → `heartofiron.1250` / `.1251`） |
- ✅ 全链绿：`gen-hof-ic-s3`（127 块 / 15 人）· `focus-icons`（126 = 108 + 18）·
  `sync` 17/0（205698 行）· `verify-s2` 0 · `gen-reference-index` 211 行 · `verify-docs` 0
- 落盘：DM `hof_ic_maksim_litvinov_dm.txt` = **1408 字节**（4 变量）；**2 条好感修正**写进
  `common/opinion_modifiers/hof_ic_opinion_modifiers.txt`；**2 条本地化键**写进
  `localisation/simp_chinese/hof_ic_l_simp_chinese.yml`

### 🚩 第 0 步：原版把他做成了一条【外交路线】的名字（第 5 次执行，性质全新）
- 前 4 次都是「**原版为他做过一件关于他的事**」；**李维诺夫是「原版把他做成了一条路线的名字」**：
  ① ⭐⭐ **独一无二的领袖特质 `pc_for_foreign_affairs_litvinov`**（`00_traits.txt` L7950）→ **22 人里第 1 例**
  ② ⭐⭐ **国策 `SOV_policy_of_collective_security`**（`soviet.txt` L12471），
     `mutually_exclusive` vs `SOV_policy_of_individual_security`
  ③ ⭐ **`MR_pact_litvinov`** + R56 的 `### LITVINOV IN DA HOUSE ###` AI 策略组
  ④ **大清洗目标**（原版列入，**R56 移除**并注释「Litvinov was not purged... Died 1951」）
- 👉 **提炼的新判据**：**原版把一个「政策」做成国策并挂上某人的名字时，
  那个【二选一】就是禁区，但【这套政策是怎么一件件搭起来的】是可做的。**

### ⚠️ 一处订正（第 4 次靠【机构 / 俄文维基】抓错）
- **中文维基写他 1922 年任热那亚会议「苏联代表团团长」= ❌ 错的**（俄文维基：是代表团【成员】，团长是契切林）
- 📌 **「团长 / 首任 / 任期」这类事实：中文维基的年表条目会写错，必须用俄文维基复核。**

### 📌 素材情况
- ⛔ **中文马克思主义文库【没有】他的篇目页**（`marxists.org/chinese/litvinov/` 404）；**英文 MIA 也没有** `archive/litvinov/`（404）
- ⭐ **「文库无页」≠「无中文材料」（第 3 次）**：**托洛茨基《斯大林评传》中译本里有 5 处写他**
- ⭐ **他有本人著作【书目】至少 7 本**（《反对侵略》1938 等）—— ⚠️ **但正文一份未拿到**

### ⛔ 刻意剔除九个题（最硬的一条）
- 🔴🔴 **莫斯科审判** —— **他被任命进那个决定布哈林与李可夫命运的委员会**，
  但 **布哈林（Idx 2）与李可夫（Idx 3）是本 mod 已实装的本人** → **绝对不做**
- 其余：他的清洗 / 妻子与家庭 / 「集体安全 vs 单独安全」选择题 / 1946「战争不可避免」/
  1908 巴黎兑换钞票被捕 / **1906–1917 军火采购十年** / 1941–43 驻美大使与第二战场 / 他的死与「是否被谋杀」

### 🔧 工具坑补记（本轮新增）
- 🚩 **PowerShell 的 `Raw` 数组用【literal `` `t ``】写缩进** —— `sb.ToString().Replace('`t', "`t")`
  在【写文件那一刻】才把它换成真 tab（生成器 L48 / L4105 / L4822）。
  → ✅ **写 `Raw` 时照抄这个约定**，别直接塞真 tab 到源码里。
- 🚩 **终端彻底挂掉时，`mcp_pylance_mcp_s_pylanceRunCodeSnippet` + `subprocess.run` 是可靠后路** ——
  本轮终端丢失 `python` PATH + 一度掉进 Interactive Python REPL（`<<'PY'` heredoc 不支持、`>>> ` 卡住），
  **必须 `exit()` 才能回 PowerShell**。
- 🚩 **PowerShell 脚本的输出是 GBK** → `subprocess.run(..., capture_output=True)` 后
  **必须 `.decode('gbk')`**（不是 utf-8），否则日志全成乱码没法 grep。
'''
out = (body + '\n' + ADD).replace('\r', '')
open(MEM, 'wb').write(b'\r\n'.join(out.encode('utf-8').split(b'\n')))
r = open(MEM, 'rb').read()
print('memory lines', r.count(b'\n') + 1, 'CRCRLF', r.count(b'\r\r\n'), 'bareLF', r.count(b'\n') - r.count(b'\r\n'))

# ---- 终校 ----
PS = r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
for script in ['verify-docs.ps1', 'gen-reference-index.ps1']:
    p = subprocess.run([PS, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', os.path.join(WS, 'build', script)],
                       cwd=WS, capture_output=True)
    o = (p.stdout + p.stderr).decode('gbk', 'replace')
    print('###', script, 'rc=', p.returncode)
    print('\n'.join(x.encode('ascii','backslashreplace').decode() for x in o.splitlines()[-3:]))
    if p.returncode != 0:
        open('build/_err.txt','w',encoding='utf-8').write(o)
