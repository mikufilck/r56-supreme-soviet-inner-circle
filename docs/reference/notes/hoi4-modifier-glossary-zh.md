# HOI4 民族精神（idea）修正词条 · 中文对照速查

> **来源**：B站专栏《钢铁雄心四：MOD常用民族精神代码总结（一）》
> `https://www.bilibili.com/opus/368272215612156732`（作者 霍默-辛普森，2020-03-19，文集共 4 篇）
> **性质**：⚠️ **第三方整理稿，非官方文档**。原为 HOI4 **1.8 / 1.9 时期**的内容。
> **本项目游戏版本 1.19.2.0** —— 相差 10 余个大版本，**词条可能已改名 / 删除 / 语义变化**。
> **使用方式**：当作「**候选词条名清单**」，写进脚本前**必须用 §0.3 的方法在当前游戏文件里核实**（AGENTS 规则 7）。

---

## 0. 使用前必读

### 0.1 数值约定

HOI4 的修正数值几乎都是**小数比例**：

| 写法 | 含义 |
| --- | --- |
| `0.05` | **+5%** |
| `-0.10` | **−10%** |
| `1.00` | **+100%** |
| `25`（个别词条如 `max_organisation`） | **绝对值**，不是百分比 |

> ⚠️ 原文里的示例数值（如 `political_power_factor = 5.0 # +500%`）只是**演示"这个位置填什么"**，
> **不是推荐值**，别照抄进自己的 mod。

### 0.2 两个易混点

- **`_factor` 后缀**通常表示"乘数型"修正（`0.05` = +5%）；不带后缀的未必绝对值，仍要看具体词条。
- 有些词条在原文里**没写 `= 数值`**（如 `winter_attrition_factor`、`light_air_research`）——
  那只表示"有这么个词条"，**赋值方式要自己查**。

### 0.3 怎么在当前版本核实（推荐流程）

1. **扫游戏自己的 idea 文件**：`common/ideas/*.txt`（原版 / DLC / R56 三层，注意 `dlc\` 下的覆盖）。
   本仓库已有现成脚本产物：`docs/reference/reports/sov-idea-words-report.txt`
   （扫了 R56 的 `r56_soviet.txt`、`SOV.txt` + 原版的 `SOV.txt`、`kosovo.txt`，按出现次数排序）。
2. **扫官方 wiki 离线快照**：`docs/reference/wiki/`（有 `Modifiers` / `Idea modding` 类页面时优先看它）。
3. **扫原版国策/事件里实际用过的写法**：`common/national_focus/*.txt`、`events/*.txt`。
4. 三者都查不到 → 登记到 `docs/99-todo-verify.md`，**别写进正文当事实**。

---

## 1. 政治 / 外交

| 词条 | 中文含义 |
| --- | --- |
| `political_power_factor` | 政治点数获取 |
| `research_time_factor` | 研究时间 |
| `conscription` | 可征兵员数 |
| `justify_war_goal_time` | 正当化战争目标所需时间 |
| `trade_opinion_factor` | 贸易关系加成 |
| `drift_defence_factor` | 意识形态变化排斥加成（漂移抵抗） |
| `opinion_gain_monthly_factor` | 关系每月增加 |
| `opinion_gain_monthly_same_ideology_factor` | 同意识形态关系每月增加 |

> 📌 本项目还会用到 `stability_factor`（稳定度）、`war_support_factor`（战争支持度）、
> `communism_drift`（每日共产主义支持漂移）、`political_power_gain`（政治点获取，德国 idea 实测用的这个词条）
> —— 这几个**不在原文里**，是实测得到的，见 `docs/reference/reports/sov-idea-words-report.txt`。

---

## 2. 工业 / 经济

| 词条 | 中文含义 |
| --- | --- |
| `industrial_capacity_factory` | 工厂产出（Factory Output） |
| `production_factory_max_efficiency_factor` | 工厂最大产能 |
| `production_factory_efficiency_gain_factor` | 工厂产能增加度 |
| `line_change_production_efficiency_factor` | 换线产能维持度 |
| `global_building_slots_factor` | 地区可用建筑格 |
| `consumer_goods_factor` | 消费品需求（**负数 = 变好**） |
| `conversion_cost_civ_to_mil_factor` | 民用工厂转军用工厂成本 |
| `conversion_cost_mil_to_civ_factor` | 军用工厂转民用工厂成本 |
| `industry_air_damage_factor` | 工厂空袭受损度 |

---

## 3. 陆军

| 词条 | 中文含义 |
| --- | --- |
| `encryption` | 加密能力 |
| `decryption` | 破译能力 |
| `planning_speed` | 作战计划完成速度 |
| `max_planning` | 作战计划加成上限 |
| `army_attack_factor` | 部队攻击力 |
| `army_defence_factor` | 部队防御力 |
| `army_speed_factor` | 部队行军速度 |
| `army_morale_factor` | 部队组织度回复率（士气） |
| `army_org_factor` | 部队组织度 |
| `combat_width_factor` | 己方战场宽度 |
| `supply_consumption_factor` | 补给消耗 |
| `attrition` | 损耗 |
| `dig_in_speed_factor` | 堑壕加固速度 |
| `max_dig_in` | 堑壕最大加成 |
| `training_time_factor` | 训练时间 |
| `training_time_army_factor` | 部队训练时间 |
| `enemy_army_bonus_air_superiority_factor` | 敌方制空影响 |
| `winter_attrition_factor` | 冬季损耗 |
| `heat_attrition_factor` | 夏季损耗 |
| `acclimatization_cold_climate_gain_factor` | 寒冷适应度增长速度 |
| `acclimatization_hot_climate_gain_factor` | 炎热适应度增长速度 |
| `out_of_supply_factor` | 缺乏补给惩罚 |
| `occupation_cost` | 占领花费（原文写作"占领速度"，⚠️ 存疑） |
| `org_loss_when_moving` | 移动时组织度耗损 |
| `max_organisation` | 最大组织度（**绝对值**） |
| `army_core_attack_factor` | 核心领土单位攻击 |
| `army_core_defence_factor` | 核心领土单位防御 |
| `motorized_attack_factor` / `motorized_defence_factor` | 摩托化部队攻击 / 防御 |
| `mechanized_attack_factor` / `mechanized_defence_factor` | 机械化部队攻击 / 防御 |
| `army_artillery_attack_factor` / `army_artillery_defence_factor` | 炮兵单位攻击 / 防御 |
| `army_armor_attack_factor` / `army_armor_defence_factor` | 装甲单位攻击 / 防御 |
| `special_forces_attack_factor` / `special_forces_defence_factor` | 特种部队攻击 / 防御 |
| `cavalry_attack_factor` / `cavalry_defence_factor` | 骑兵单位攻击 / 防御 |
| `surrender_limit` | 投降倾向（原文未收，实测有，见 `sov-idea-words-report.txt`） |

---

## 4. 海军

| 词条 | 中文含义 |
| --- | --- |
| `naval_strike` | 海军对舰攻击 |
| `naval_hit_chance` | 海军命中率 |
| `naval_speed_factor` | 海军航速 |
| `naval_detection` | 海军侦测能力 |
| `navy_max_range_factor` | 海军最大航程 |
| `navy_submarine_detection_factor` | 对潜侦测能力 |
| `navy_anti_air_attack_factor` | 海军对空迎击能力 |
| `sortie_efficiency` | 航母舰载机出动架次效率 |
| `carrier_traffic` | 航母空中交管效率 |
| `transport_capacity` | 部队运载效率 |
| `amphibious_invasion` | 两栖登陆速度 |
| `amphibious_invasion_defence` | 两栖登陆防御 |
| `naval_invasion_capacity` | 登陆作战上限 |
| `invasion_preparation` | 登陆准备时间 |

---

## 5. 空军

| 词条 | 中文含义 |
| --- | --- |
| `air_attack_factor` | 空军战斗能力 |
| `air_detection` | 空军索敌能力 |
| `air_range_factor` | 空军飞行距离 |
| `air_agility_factor` | 空军灵活度 |
| `air_maximum_speed_factor` | 空军最高航速 |
| `air_accidents` | 空军事故率 |
| `air_mission_efficiency` | 空军任务执行效率 |
| `air_ace_generation_chance_factor` | 空战王牌生成率 |
| `air_bombing_targetting` | 飞机轰炸准度 |
| `naval_strike_targetting_factor` | 飞机对舰攻击准度 |
| `air_superiority_detect_factor` | 空优任务索敌效率 |
| `air_superiority_efficiency` | 空优任务效率 |
| `army_bonus_air_superiority_factor` | 制空对地面部队加成 |
| `strategic_bomb_visibility` | 战略轰炸机可见度 |
| `air_night_penalty` | 空军夜间飞行惩罚 |
| `air_weather_penalty` | 空军恶劣天气影响 |
| `air_accidents_factor` | 空军事故率加成 |

---

## 6. 经验值

| 词条 | 中文含义 |
| --- | --- |
| `experience_gain_factor` | 将领经验获取加成 |
| `experience_gain_army_unit_factor` | 陆军单位经验获取 |
| `experience_gain_navy_unit_factor` | 海军单位经验获取 |
| `experience_gain_army` | 陆军每日经验获取（**绝对值**） |
| `experience_gain_navy` | 海军每日经验获取（**绝对值**） |
| `experience_gain_air` | 空军每日经验获取（**绝对值**） |
| `experience_gain_army_factor` | 陆军每日经验获取加成 |
| `experience_gain_navy_factor` | 海军每日经验获取加成 |
| `experience_gain_air_factor` | 空军每日经验获取加成 |

> 📌 本项目实际用到的相关词条还有 `equipment_capture_factor`（缴获装备比例），见 `sov-idea-words-report.txt`。

---

## 7. 世界紧张局势

| 词条 | 中文含义 |
| --- | --- |
| `generate_wargoal_tension` | 制造宣战目标所需世界紧张局势 |
| `guarantee_tension` | 保证独立所需世界紧张局势 |
| `join_faction_tension` | 加入阵营所需世界紧张局势 |
| `send_volunteers_tension` | 派遣志愿军所需世界紧张局势 |
| `lend_lease_tension` | 租借所需世界紧张局势 |

---

## 8. 建筑 / 建造速度

| 词条 | 中文含义 |
| --- | --- |
| `production_speed_buildings_factor` | 建造速度（全部建筑） |
| `industry_repair_factor` | 工厂修复速度（原文注：**总加成勿超过 100%**） |
| `production_speed_arms_factory_factor` | 军用工厂建造速度 |
| `production_speed_industrial_complex_factor` | 民用工厂建造速度 |
| `production_speed_dockyard_factor` | 海军船坞建造速度 |
| `production_speed_bunker_factor` | 陆上要塞建造速度 |
| `production_speed_coastal_bunker_factor` | 海岸要塞建造速度 |
| `production_speed_anti_air_building_factor` | 防空炮阵建造速度 |
| `production_speed_infrastructure_factor` | 基础设施建造速度 |
| `production_speed_synthetic_refinery_factor` | 化学合成厂建造速度 |
| `production_speed_air_base_factor` | 空军基地建造速度 |
| `production_speed_naval_base_factor` | 海军基地建造速度 |
| `production_speed_rocket_site_factor` | 火箭基地建造速度 |
| `production_speed_radar_station_factor` | 雷达站建造速度 |
| `production_speed_nuclear_reactor_factor` | 核反应堆建造速度 |

---

## 9. 地区 / 资源（作用于单个州）

| 词条 | 中文含义 |
| --- | --- |
| `local_resources_factor` | 资源产量加成 |
| `local_resources` | 地区资源 |
| `local_manpower` | 地区人力 |
| `local_factories` | 地区工厂 |
| `local_supplies` | 地区补给 |

---

## 10. 研究速度（按科技类别）

| 词条 | 中文含义 |
| --- | --- |
| `light_air_research` / `medium_air_research` / `heavy_air_research` | 轻型 / 中型 / 重型飞机研究速度 |
| `armor_research` | 装甲研究速度 |
| `artillery_research` | 炮兵研究速度 |
| `naval_air_research` | 海军航空兵研究速度 |
| `infantry_weapons_research` | 武器和装备研究速度 |
| `motorized_equipment_research` | 摩托化研究速度 |
| `naval_equipment_research` | 海军研究速度 |
| `rocketry_research` | 导弹研究速度 |
| `nuclear_research` | 核能研究速度 |
| `industry_research` | 工业研究速度 |
| `electronics_research` | 电子研究速度 |
| `land_doctrine_research` | 陆战学说研究速度 |
| `naval_doctrine_research` | 海战学说研究速度 |
| `air_doctrine_research` | 空战学说研究速度 |
| `strategic_destruction_tree_research` | 战略摧毁学说研究速度 |
| `jet_technology_research` | 喷气式飞机技术研究速度 |

> 📌 本项目通用写法是 `research_speed_factor`（全部科研速度），见 `sov-idea-words-report.txt`。

---

## 11. 法案 / 顾问 / 制造商花费

| 词条 | 中文含义 |
| --- | --- |
| `mobilization_laws_cost_factor` | 征兵法案花费 |
| `trade_laws_cost_factor` | 贸易法案花费 |
| `economy_cost_factor` | 经济法案花费 |
| `political_advisor_cost_factor` | 政治顾问花费 |
| `tank_manufacturer_cost_factor` | 装甲制造商花费 |
| `naval_manufacturer_cost_factor` | 海军制造商花费 |
| `aircraft_manufacturer_cost_factor` | 飞机制造商花费 |
| `materiel_manufacturer_cost_factor` | 军需品设计花费 |
| `industrial_concern_cost_factor` | 工业企业花费 |
| `theorist_cost_factor` | 理论家花费 |
| `army_chief_cost_factor` | 陆军部长花费 |
| `navy_chief_cost_factor` | 海军部长花费 |
| `air_chief_cost_factor` | 空军部长花费 |
| `high_command_cost_factor` | 总司令花费 |
| `ai_license_acceptance` | 允许购买生产许可倾向 |
| `guarantee_cost` | 保障独立花费 |
| `autonomy_gain_global_factor` | 全局自治度增加 |
| `license_subject_master_purchase_cost` | 宗主国与附庸间生产许可花费 |

---

## 12. 抵抗运动 / 占领（1.9 起，DLC `La Résistance` 体系）

### 12.1 抵抗与顺从

| 词条 | 中文含义 |
| --- | --- |
| `resistance_target` | 抵抗目标 |
| `resistance_growth` | 抵抗增长速度 |
| `compliance_gain` | 每日顺从度增长 |
| `required_garrison_factor` | 驻军需求 |
| `non_core_manpower` | 非核心人力 |
| `target_sabotage_cost` / `target_sabotage_risk` | 破坏活动花费 / 风险 |
| `local_factory_sabotage` | 破坏建设几率 |
| `subjects_autonomy_gain` | 宗主国对附庸国自治度的影响 |

### 12.2 情报机构

| 词条 | 中文含义 |
| --- | --- |
| `agency_upgrade_time` | 情报机构升级时间 |
| `operative_slot` | 特工位 |
| `new_operative_slot_bonus` | 特工招募选项 |
| `intel_network_gain_factor` | 情报网增长（评论区补充） |

### 12.3 特工对抗

| 词条 | 中文含义 |
| --- | --- |
| `own_operative_detection_chance_factor` | 我方特工被发现几率 |
| `enemy_operative_detection_chance_factor` | 敌方特工被发现几率系数 |
| `own_operative_capture_chance_factor` | 我方特工被捕几率 |
| `enemy_operative_capture_chance_factor` | 敌方特工被捕几率 |
| `own_operative_forced_into_hiding_time_factor` / `enemy_...` | 我方 / 敌方被迫躲藏时间 |
| `own_operative_harmed_time_factor` / `enemy_...` | 我方 / 敌方被破坏时间 |
| `own_operative_intel_extraction_rate` / `enemy_...` | 我方 / 敌方特工情报获取率 |

### 12.4 密码与情报泄露

| 词条 | 中文含义 |
| --- | --- |
| `army_intel_decryption_bonus` / `navy_intel_decryption_bonus` / `airforce_intel_decryption_bonus` | 破译陆军 / 海军 / 空军密码加成 |
| `breakthrough_bonus_against` | 针对国家的突破加成 |
| `positioning` | 阵位 |
| `civilian_intel_to_others` / `army_intel_to_others` / `navy_intel_to_others` / `airforce_intel_to_others` | 泄露给他国的民政 / 陆军 / 海军 / 空军情报 |

### 12.5 行动（operation）—— 通用三件套

绝大多数行动都是 **`outcome`（效率）/ `risk`（风险）/ `cost`（花费）** 三个一组的写法：

| 行动 | 词条前缀 |
| --- | --- |
| 窃取蓝图 | `operation_steal_tech_` |
| 渗透 | `operation_infiltrate_` |
| 假情报 | `operation_fake_intel_` |
| 夺取密码 | `operation_capture_cipher_` |
| 协同打击 | `operation_coordinated_strike_` |
| 筹备合作政府 | `operation_collaboration_government_` |
| 进行颠覆 | `operation_coup_government_` |
| 营救特工 | `operation_rescue_operative_` |
| 接触抵抗组织 | `operation_make_resistance_contacts_` |
| 加强抵抗组织 | `operation_boost_resistance_` |

另有一条**通用**写法：`operation_outcome` / `operation_risk` / `operation_cost`（影响全部行动）。

### 12.6 水雷

| 词条 | 中文含义 |
| --- | --- |
| `mines_planting_by_fleets_factor` / `mines_sweeping_by_fleets_factor` | 海军布雷 / 扫雷效率 |
| `mines_planting_by_air_factor` / `mines_sweeping_by_air_factor` | 空中布雷 / 扫雷效率 |
| `naval_mines_damage_factor` | 水雷伤害 |
| `naval_mines_effect_reduction` | 规避水雷 |
| `naval_mine_hit_chance` | 水雷命中率 |
| `naval_accidents_chance` | 海军事故几率 |
| `screening_efficiency` | 屏卫效率 |

---

## 13. AI 修正

| 词条 | 中文含义 |
| --- | --- |
| `ai_call_ally_desire_factor` | 请求盟友加入战争的意愿 |
| `ai_join_ally_desire_factor` | 参战意愿 |
| `ai_get_ally_desire_factor` | 加入或扩大一个阵营的意愿 |
| `ai_focus_defense_factor` | 专注防御 |
| `ai_focus_aggressive_factor` | 专注进攻 |
| `ai_focus_war_production_factor` | 专注战时生产 |
| `ai_focus_military_advancements_factor` | 专注先进军事科技研究 |
| `ai_focus_military_equipment_factor` | 专注军备 |
| `ai_focus_peaceful_factor` | 专注和平 |
| `ai_focus_naval_factor` | 专注海军 |
| `ai_focus_naval_air_factor` | 专注海航 |
| `ai_focus_aviation_factor` | 专注空军 |

---

## 14. 本项目已实测用过的词条（**优先信这份**）

来自 `docs/reference/reports/sov-idea-words-report.txt`（扫 R56 `r56_soviet.txt` / `SOV.txt` + 原版 `SOV.txt` / `kosovo.txt`，
按出现次数降序，**是在当前游戏文件里真实出现过的写法**）：

```
build_cost_ic  naval_equipment  armor  consumer_goods_factor  reliability
air_equipment  industrial_capacity_factory  repair_speed_factor  stability_factor
naval_mines  attack_bonus_against  army_org_factor  soft_attack  maximum_speed
defense_bonus_against  production_speed_industrial_complex_factor
production_factory_max_efficiency_factor  production_speed_arms_factory_factor
production_speed_dockyard_factor  air_mission_efficiency  political_power_factor
air_agility_factor  radar_tech  license_purchase_cost  refit_speed  refit_ic_cost
army_core_defence_factor  naval_air  army_morale_factor  naval_accidents_chance
communism_drift  training_time_factor  research_speed_factor  drift_defence_factor
industrial_capacity_dockyard  naval_doctrine_cost_factor  land_doctrine_cost_factor
land_equipment_upgrade_xp_cost  production_factory_efficiency_gain_factor
equipment_conversion_speed  motorized_equipment  air_doctrine  production_speed_buildings_factor
naval_doctrine  artillery  infantry_weapons  mot_rockets  land_doctrine  conscription
equipment_capture_factor  mobilization_speed  war_support_factor
```

> ⚠️ 注意：`political_power_factor`（苏联 idea 实测）与 `political_power_gain`（德国 idea 实测）
> **是两个不同词条**，本项目两份设计文档里混用过，需统一 —— 已登记在 `docs/24-focus-icon-prompts.md` §5。

---

## 15. 已知缺口 / 待补

- [ ] 原文是**系列第 1 篇**（文集标"共 4 篇"），其余 3 篇（触发条件 / 效果写法 / 其他）尚未抓取。
- [ ] 原文标注 **1.9 抵抗运动**，且成文于 2020 —— 1.10~1.19 新增的词条（如 MIO、成就、`dlc` 新机制）**完全没覆盖**。
- [ ] 原文个别中文释义存疑（如 `occupation_cost` 写作"占领速度"）。
- [ ] 建议后续做一份**当前版本的全量词条清单**：直接扫 `common/ideas/` 与 `common/national_focus/`
      里 `modifier = { ... }` 块，统计真实出现的键名 + 出现次数，产物另存 `docs/reference/`。
      这比抄第三方清单可靠，且可随时重跑。

---

## 16. 相关文件

| 文件 | 关系 |
| --- | --- |
| `docs/03-scripting.md` | 脚本语法总则（本文件是它的"词条速查"附件） |
| `docs/reference/reports/sov-idea-words-report.txt` | **实测词条清单**（扫当前游戏文件得到，优先信这份） |
| `docs/reference/wiki/` | Paradox 官方 wiki 离线快照 |
| `docs/22-trotsky-focus-tree-design.md` §8 | 本项目 idea 数值草案（脚本原文） |
| `docs/24-focus-icon-prompts.md` 附录 A | 本项目用到的词条中文对照（含完成即得效果） |
| `docs/99-todo-verify.md` | 存疑条目登记处 |
