








dofile(LockOn_Options.script_path.."Displays/common.lua")
TEXT_WEIGHT = "bold"
SetScale(FOV)

POWER_VIS = {"DISP_PWR_EMD", 0.5, 1.5}

local A = GetAspect()
local C = WHITE
local H = 0.13
local HL = 0.11
local LW = 0.014
local XL, XR = -0.42, 0.90

local function row(label, y, left, right, fmt)
	text(label, {0, y}, HL, C)
	text(nil, {XL, y}, H, C, "RightCenter", nil, {left, fmt})
	text(nil, {XR, y}, H, C, "RightCenter", nil, {right, fmt})
end

local function rule(y)
	segments({{-0.95, y, 0.95, y}}, LW, C)
end




local function radio(n, x, align)
	local on, off = {"RADIO_"..n.."_V", 0.5, 1.5}, {"RADIO_"..n.."_V", -0.5, 0.5}
	local s = align == "LeftCenter" and 1 or -1
	text("R"..n, {x, A - 0.13}, HL, C, align)
	text(nil, {x + s * 0.20, A - 0.13}, HL, C, align, nil, {"RADIO_"..n.."_TXT", "%s"}, on)
	text("OFF", {x, A - 0.30}, HL, C, align, nil, nil, off)
	text(nil, {x, A - 0.30}, HL, C, align, nil, {"RADIO_"..n.."_FREQ", "%.3f"}, on)
end
radio(1, -0.92, "LeftCenter")
radio(2, 0.92, "RightCenter")
rule(A - 0.42)




local AMBER_BOX = {225, 135, 0, 255}
local LIT = {L = {"EFM_LIT_L", 0.5, 1.5}, R = {"EFM_LIT_R", 0.5, 1.5}}
local UNLIT = {L = {"EFM_LIT_L", -0.5, 0.5}, R = {"EFM_LIT_R", -0.5, 0.5}}
local TURNING = {L = {"EFM_RPM_L", 1, 1000}, R = {"EFM_RPM_R", 1, 1000}}
local STOPPED = {L = {"EFM_RPM_L", -1000, 1}, R = {"EFM_RPM_R", -1000, 1}}
local function off_box(cx, y, vis)

	caution_box(cx - 0.23, y - 0.085, cx + 0.23, y + 0.085, AMBER_BOX, LW, night_hue(AMBER_BOX), vis, "offbox")
	text("OFF", {cx, y}, H, C, "CenterCenter", nil, nil, vis)
end
local function engine_row(y, left, right, on, off)
	text(nil, {XL, y}, H, C, "RightCenter", nil, {left, "%.0f"}, on.L)
	text(nil, {XR, y}, H, C, "RightCenter", nil, {right, "%.0f"}, on.R)
	off_box(XL - 0.21, y, off.L)
	off_box(XR - 0.21, y, off.R)
end
text("RPM%", {0, A - 0.60}, HL, C)
engine_row(A - 0.60, "DISP_RPM_L", "DISP_RPM_R", TURNING, STOPPED)
row("TEMP °C", A - 0.80, "DISP_FTIT_L", "DISP_FTIT_R", "%.0f")
text("FF", {0, A - 0.98}, HL, C)
text("PPH", {0, A - 1.12}, HL, C)
engine_row(A - 1.04, "DISP_FF_L", "DISP_FF_R", LIT, UNLIT)





local DIAL_Y = A - 1.32
local R_NEEDLE, R_TICK = 0.33, 0.38
local function dial_angle(pct) return math.rad(-20 - 0.9 * pct) end
local function dial(x, param)
	local ticks = {}
	for p = 0, 100, 5 do
		local a = dial_angle(p)
		local r2 = R_TICK + ((p % 50 == 0) and 0.09 or 0.05)
		ticks[#ticks + 1] = {x + R_TICK * math.cos(a), DIAL_Y + R_TICK * math.sin(a),
			x + r2 * math.cos(a), DIAL_Y + r2 * math.sin(a)}
	end
	segments(ticks, 0.02, C)
	for _, p in ipairs({0, 50, 100}) do
		local a = dial_angle(p)
		text(tostring(p), {x + 0.58 * math.cos(a), DIAL_Y + 0.58 * math.sin(a)}, 0.08, C)
	end
	local needle = node({x, DIAL_Y}, nil, {param}, {{"rotate_using_parameter", 0, -math.rad(0.9)}})
	local a = dial_angle(0)
	segments({{0.04 * math.cos(a), 0.04 * math.sin(a), R_NEEDLE * math.cos(a), R_NEEDLE * math.sin(a)}}, 0.045, C, needle)
end
dial(-0.72, "EFM_NOZ_L")
dial(0.40, "EFM_NOZ_R")
text("NOZ", {0.02, A - 1.61}, HL, C)
text("POS%", {0.02, A - 1.75}, HL, C)

rule(A - 1.94)
row("OIL PSI", A - 2.10, "DISP_OIL_L", "DISP_OIL_R", "%.0f")
rule(A - 2.26)
