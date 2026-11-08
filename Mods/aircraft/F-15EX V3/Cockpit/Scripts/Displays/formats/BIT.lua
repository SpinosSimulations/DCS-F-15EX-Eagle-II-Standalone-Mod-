




local C = GREEN
local DIM = {0, 150, 0, 255}


local H = 0.05
local XLBL, XL, XR = 0, -0.08, 0.62
local DY = 0.066

text("BIT", {0, 0.70}, H, C)
text("L", {XL - 0.04, 0.63}, H, C)
text("R", {XR - 0.04, 0.63}, H, C)

local y = 0.56
local function row(label, l, r, fmt)
	text(label, {-0.70, y}, H, C, "LeftCenter")
	text(nil, {XL, y}, H, C, "RightCenter", nil, {l, fmt})
	text(nil, {XR, y}, H, C, "RightCenter", nil, {r, fmt})
	y = y - DY
end
row("RPM %", "DISP_RPM_L", "DISP_RPM_R", "%.0f")
row("FTIT C", "DISP_FTIT_L", "DISP_FTIT_R", "%.0f")
row("FF PPH", "DISP_FF_L", "DISP_FF_R", "%.0f")
row("OIL PSI", "DISP_OIL_L", "DISP_OIL_R", "%.0f")


local function states(side, x, crank)
	local st = "EFM_START_"..side
	text("OFF", {x, y}, H, DIM, "RightCenter", nil, nil, {{st, -0.5, 0.5}, {"EFM_CRANK", -0.5, crank - 0.5}})
	text("OFF", {x, y}, H, DIM, "RightCenter", nil, nil, {{st, -0.5, 0.5}, {"EFM_CRANK", crank + 0.5, 9}})
	text("CRANK", {x, y}, H, C, "RightCenter", nil, nil, {{st, -0.5, 0.5}, {"EFM_CRANK", crank - 0.5, crank + 0.5}})
	text("LIGHT", {x, y}, H, AMBER, "RightCenter", nil, nil, {st, 0.5, 1.5})
	text("ACCEL", {x, y}, H, C, "RightCenter", nil, nil, {st, 1.5, 2.5})
	text("RUN", {x, y}, H, C, "RightCenter", nil, nil, {st, 2.5, 3.5})
end
text("START", {-0.70, y}, H, C, "LeftCenter")
states("L", XL, 1)
states("R", XR, 2)
y = y - DY
local function onoff(label, l, r, on, off)
	text(label, {-0.70, y}, H, C, "LeftCenter")
	for _, s in ipairs({{l, XL}, {r, XR}}) do
		text(on or "ON", {s[2], y}, H, C, "RightCenter", nil, nil, {s[1], 0.5, 1.5})
		text(off or "OFF", {s[2], y}, H, AMBER, "RightCenter", nil, nil, {s[1], -0.5, 0.5})
	end
	y = y - DY
end
onoff("GEN", "EFM_GEN_L", "EFM_GEN_R")
onoff("THROTTLE", "EFM_THR_IDLE_L", "EFM_THR_IDLE_R", "IDLE", "OFF")


y = y - 0.02
segments({{-0.72, y + 0.035, 0.72, y + 0.035}}, 0.005, DIM)
local hx = {-0.45, 0.05, 0.55}
for i, k in ipairs({"PC1", "UTIL", "PC2"}) do
	text(k, {hx[i], y}, H, C)
	text(nil, {hx[i], y - DY}, H, C, "CenterCenter", nil, {"DISP_HYD_"..k, "%.0f"})
end
y = y - 2 * DY - 0.02
segments({{-0.72, y + 0.035, 0.72, y + 0.035}}, 0.005, DIM)


local y0 = y
text(nil, {-0.70, y}, H, C, "LeftCenter", nil, {"DISP_BATT_V", "BATT %.1f V"})
y = y - DY
for i, b in ipairs({{"AC", "EFM_ELEC_AC"}, {"DC", "EFM_ELEC_DC"}, {"ESS", "EFM_ELEC_ESS"}}) do
	local x = -0.70 + (i - 1) * 0.20
	text(b[1], {x, y}, H, C, "LeftCenter", nil, nil, {b[2], 0.5, 1.5})
	text(b[1], {x, y}, H, DIM, "LeftCenter", nil, nil, {b[2], -0.5, 0.5})
end
y = y - DY
text("JFS OFF", {-0.70, y}, H, DIM, "LeftCenter", nil, nil, {"EFM_JFS", -0.5, 0.5})
text("JFS START", {-0.70, y}, H, AMBER, "LeftCenter", nil, nil, {"EFM_JFS", 0.5, 1.5})
text("JFS RUN", {-0.70, y}, H, C, "LeftCenter", nil, nil, {"EFM_JFS", 1.5, 2.5})
text(nil, {-0.02, y}, H, C, "RightCenter", nil, {"DISP_JFS_RPM", "%.0f%%"}, {"EFM_JFS", 0.5, 2.5})
text("AUTO START", {-0.70, y - DY}, H, AMBER, "LeftCenter", nil, nil, {"EFM_AUTOSTART", 0.5, 99})
y = y0
text(nil, {0.70, y}, H, C, "RightCenter", nil, {"DISP_FUEL_TOTAL", "FUEL %.0f"})
y = y - DY
text(nil, {0.70, y}, H, C, "RightCenter", nil, {"DISP_BINGO", "BINGO %.0f"})
y = y0 - 4 * DY


segments({{-0.72, y + 0.035, 0.72, y + 0.035}}, 0.005, DIM)
text("NO CAUTIONS", {0, y - DY}, H, DIM, "CenterCenter", nil, nil, {"WARN_COUNT", -0.5, 0.5})
for i = 1, 8 do
	local col, r = math.floor((i - 1) / 4), (i - 1) % 4
	text(nil, {col == 0 and -0.70 or 0.02, y - r * DY}, H, AMBER, "LeftCenter", nil, {"WARN_L"..i, "%s"})
end
