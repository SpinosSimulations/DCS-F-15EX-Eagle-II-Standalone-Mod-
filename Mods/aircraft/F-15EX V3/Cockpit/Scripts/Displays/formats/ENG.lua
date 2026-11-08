









local C = GREEN
local H = 0.058
local XL0, XL, XR = -0.62, 0.12, 0.52
local DY = 0.075

local y = 0.62
text("ENGINE", {XL0, y}, H, C, "LeftCenter")
text("L", {XL, y}, H, C, "RightCenter")
text("R", {XR, y}, H, C, "RightCenter")
y = y - 1.2 * DY
local function row(label, l, r, fmt)
	text(label, {XL0, y}, H, C, "LeftCenter")
	text(nil, {XL, y}, H, C, "RightCenter", nil, {l, fmt})
	text(nil, {XR, y}, H, C, "RightCenter", nil, {r, fmt})
	y = y - DY
end
row("RPM%", "DISP_RPM_L", "DISP_RPM_R", "%.0f")
row("TEMP° C", "DISP_FTIT_L", "DISP_FTIT_R", "%.0f")
row("FF/PPH", "DISP_FF_L", "DISP_FF_R", "%.0f")
row("NOZ POS%", "DISP_NOZ_L", "DISP_NOZ_R", "%.0f")
row("OIL PSI", "DISP_OIL_L", "DISP_OIL_R", "%.0f")

y = y - 0.6 * DY
text("CRUISE DATA", {0, y}, H, C, "CenterCenter")
y = y - 1.2 * DY
local XV = 0.02
local valid = {"DISP_CRZ_V", 0.5, 1.5}
local function crz(label, param, fmt)
	text(label, {XL0, y}, H, C, "LeftCenter")
	if param then
		text(nil, {XV, y}, H, C, "LeftCenter", nil, {param, fmt}, valid)
		text("---", {XV, y}, H, C, "LeftCenter", nil, nil, {"DISP_CRZ_V", -0.5, 0.5})
	else
		text("---", {XV, y}, H, C, "LeftCenter")
	end
	y = y - DY
end
crz("RANGE NM", "DISP_CRZ_RNG", "%.0f")
text("TIME HRS MIN", {XL0, y}, H, C, "LeftCenter")
text(nil, {XV, y}, H, C, "LeftCenter", nil, {"DISP_CRZ_H", "%02.0f"}, valid)
text(nil, {XV + 0.075, y}, H, C, "LeftCenter", nil, {"DISP_CRZ_M", ":%02.0f"}, valid)
text("--:--", {XV, y}, H, C, "LeftCenter", nil, nil, {"DISP_CRZ_V", -0.5, 0.5})
y = y - DY
crz("COMMAND ALT KFT")
crz("COMMAND MACH")


text("END", {0, -0.62}, H, C, "CenterCenter")
text("FUEL", {0, -0.69}, H, C, "CenterCenter")
text(nil, {0, -0.76}, H, C, "CenterCenter", nil, {"NAV_FUEL", "%.0f"}, {{"NAV_STPT_V", 0.5, 1.5}, {"NAV_FUEL", 0.5, 1e9}})
text("----", {0, -0.76}, H, C, "CenterCenter", nil, nil, {"NAV_STPT_V", -0.5, 0.5})




local LH = LAD_CHROME.LEG_H
lad_legend(1, "BINGO")
lad_legend(2, "BNG +")
lad_legend(3, "BNG -")
local x1, y1 = LAD_PB.legend_pos(1)
text(nil, {x1, y1 - 1.25 * LH}, LH, C, "LeftCenter", nil, {"DISP_BINGO", "%.0f"})
lad_legend(15, "LAW")
lad_legend(14, "LAW +")
lad_legend(13, "LAW -")
local x15, y15 = LAD_PB.legend_pos(15)
text(nil, {x15, y15 - 1.25 * LH}, LH, C, "RightCenter", nil, {"LAW_FT", "%.0f"}, {"LAW_ON", 0.5, 1.5})
text("OFF", {x15, y15 - 1.25 * LH}, LH, C, "RightCenter", nil, nil, {"LAW_ON", -0.5, 0.5})
lad_legend(16, "LAW ON", {"LAW_ON", 0.5, 1.5})
lad_legend(16, "LAW OFF", {"LAW_ON", -0.5, 0.5})
