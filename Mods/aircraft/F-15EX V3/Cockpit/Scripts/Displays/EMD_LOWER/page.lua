







dofile(LockOn_Options.script_path.."Displays/common.lua")
TEXT_WEIGHT = "bold"
SetScale(FOV)

POWER_VIS = {"DISP_PWR_EMD", 0.5, 1.5}

local A = GetAspect()
local C = WHITE
local H = 0.13
local HL = 0.11
local LW = 0.014





local BAR_PSI = 5000
local BAR_W = 0.16
local BAR_BOTTOM, BAR_TOP = A - 1.50, A - 0.46
local BANDS = {
	{0.00, 0.08, WHITE},
	{0.08, 0.46, YELLOW},
	{0.46, 0.77, GREEN},
	{0.77, 0.89, YELLOW},
	{0.89, 1.00, RED},
}
local HYD_LOW = 1500
local AMBER_BOX = {225, 135, 0, 255}
local function hyd(name, x)

	caution_box(x - 0.26, A - 0.38, x + 0.26, A - 0.04, AMBER_BOX, LW, night_hue(AMBER_BOX), {"DISP_HYD_"..name, -1e9, HYD_LOW - 0.5},
		"hydlow")
	text(name, {x, A - 0.13}, HL, C)
	text(nil, {x, A - 0.29}, H, C, "CenterCenter", nil, {"DISP_HYD_"..name, "%.0f"})
	local bx = x - 0.06
	local h = BAR_TOP - BAR_BOTTOM
	for _, b in ipairs(BANDS) do
		local y1, y2 = BAR_BOTTOM + b[1] * h, BAR_BOTTOM + b[2] * h
		poly({{bx - BAR_W / 2, y1}, {bx + BAR_W / 2, y1}, {bx + BAR_W / 2, y2}, {bx - BAR_W / 2, y2}}, b[3])
	end
	local ptr = node({bx + BAR_W / 2 + 0.03, BAR_BOTTOM}, nil, {"HYD_"..name.."_PSI"},
		{{"move_up_down_using_parameter", 0, S(h / BAR_PSI)}})
	poly({{0, 0}, {0.13, 0.05}, {0.13, -0.05}}, C, ptr)
end
hyd("PC1", -0.62)
hyd("UTIL", 0.0)
hyd("PC2", 0.62)

segments({{-0.95, A - 1.62, 0.95, A - 1.62}}, LW, C)


text("TOTAL", {-0.62, A - 1.78}, HL, C)
text(nil, {-0.62, A - 1.94}, H, C, "CenterCenter", nil, {"DISP_FUEL_TOTAL", "%.0f"})
text("LBS", {0, A - 1.78}, HL, C)
text("INT", {0.62, A - 1.78}, HL, C)
text(nil, {0.62, A - 1.94}, H, C, "CenterCenter", nil, {"DISP_FUEL_INT", "%.0f"})




local ROW_TOP, ROW_BOT = A - 2.12, A - 2.86
local WING_TIP = 0.20
local N = 20
level_fill({{-0.24, ROW_BOT}, {0.24, ROW_BOT}, {0.27, ROW_TOP}, {-0.27, ROW_TOP}}, "DISP_FUEL_FUS_FRAC", N, FUEL_GREEN, C, LW)
local format_vis = FORMAT_VIS
local function wings(x_in, vis)
	FORMAT_VIS = vis
	level_fill({{-0.95, ROW_BOT}, {-x_in, ROW_BOT}, {-x_in, ROW_TOP}, {-0.95, ROW_BOT + WING_TIP}}, "DISP_FUEL_WING_L_FRAC",
		N, FUEL_GREEN, C, LW)
	level_fill({{x_in, ROW_BOT}, {0.95, ROW_BOT}, {0.95, ROW_BOT + WING_TIP}, {x_in, ROW_TOP}}, "DISP_FUEL_WING_R_FRAC", N,
		FUEL_GREEN, C, LW)
end



wings(0.34, {"DISP_CFT_FITTED", -0.5, 0.5})
wings(0.56, {"DISP_CFT_FITTED", 0.5, 1.5})
FORMAT_VIS = {"DISP_CFT_FITTED", 0.5, 1.5}
level_fill({{-0.48, ROW_BOT}, {-0.33, ROW_BOT}, {-0.33, ROW_TOP}, {-0.48, ROW_TOP}}, "DISP_FUEL_CFT_L_FRAC", N, FUEL_GREEN, C, LW)
level_fill({{0.33, ROW_BOT}, {0.48, ROW_BOT}, {0.48, ROW_TOP}, {0.33, ROW_TOP}}, "DISP_FUEL_CFT_R_FRAC", N, FUEL_GREEN, C, LW)
FORMAT_VIS = format_vis
text("BINGO", {-0.08, A - 3.12}, HL, C, "RightCenter")
text(nil, {0.02, A - 3.12}, HL, C, "LeftCenter", nil, {"DISP_BINGO", "%.0f"})
