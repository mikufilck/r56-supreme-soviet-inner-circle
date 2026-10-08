-- ===========================================================================
-- Heart of Iron · Defines 覆盖文件
-- ---------------------------------------------------------------------------
-- 为什么是【独立文件】而不是改写原版 00_defines.lua：
--   官方 wiki 明写「When editing Defines, make sure to use an override file
--   rather than copying the entire file, as that can cause game crashes when
--   new defines get added, which can happen even in 'minor' updates.」
--   （见 docs/reference/wiki/Map_modding.txt · National_focus_modding.txt）
-- ⇒ 本文件只写【要改的那几项】，靠文件名排在 00_defines.lua 之后生效。
-- ⚠️ 文件名的排序必须 > "00_defines"，也不要叫 00_defines.lua（那是整文件覆盖）。
-- 来源：old/common/defines/00_defines.lua（用户旧 mod 的数值）
-- ===========================================================================

NDefines.NProduction.CAPITAL_SHIP_MAX_NAV_FACTORIES_PER_LINE = 40

NDefines.NMilitary.MAX_DIVISION_SUPPORT_WIDTH = 1
NDefines.NMilitary.MAX_DIVISION_SUPPORT_HEIGHT = 7
NDefines.NMilitary.TRAINING_MAX_LEVEL = 14 -- R56 UNIT_LEVEL_14: 常规军 V
NDefines.NMilitary.UNIT_LEADER_TRAIT_SLOT_PER_LEVEL = {
		1.2, -- field marshal
		1.2, -- corps commander
		1.5, -- navy general
		0.0, -- operative
		}
NDefines.NMilitary.UNIT_LEADER_USE_NONLINEAR_XP_GAIN = false

NDefines.NAir.AIR_WING_XP_TRAINING_MAX = 500.0
NDefines.NAir.TRAINING_DAILY_COUNTRY_EXP_SHIP_RATIO_FACTOR = 500.0
