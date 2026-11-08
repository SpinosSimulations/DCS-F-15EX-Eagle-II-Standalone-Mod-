




















dofile(LockOn_Options.script_path.."Displays/common.lua")
dofile(LockOn_Options.script_path.."lad_touch_grid.lua")
dofile(LockOn_Options.script_path.."Displays/lad_strip.lua")
SetScale(FOV)




STRIP_BOTTOM = LAD_TOUCH.STRIP_BOTTOM

POWER_VIS = {"DISP_PWR_LAD", 0.5, 1.5}
local A = GetAspect()




local DIM_AMBER = {120, 90, 0, 255}


local H_BY_N = {0.0246, 0.0246, 0.0205, 0.0176}
local PITCH_BY_N = {0, 0.0226, 0.0205, 0.0174}
local LW = 0.0020



local FIT_MARGIN = 0.010



local ON_TCN, OFF_TCN = {"NAV_TCN_MODE", 0.5, 1.5}, {"NAV_TCN_MODE", -0.5, 0.5}
local ON_ILS, OFF_ILS = {"NAV_ILS_MODE", 0.5, 1.5}, {"NAV_ILS_MODE", -0.5, 0.5}
local GPS, NOGPS = {"NAV_GPS", 0.5, 1.5}, {"NAV_GPS", -0.5, 0.5}
local TILES = {
	{26, {{"DISP_CLOCK_H", "%02.0f"}, {"DISP_CLOCK_M", "%02.0f"}, {"DISP_CLOCK_S", "%02.0f"}}, WHITE, "tri"},
	{47, {"CAUTION"}, DIM_AMBER, "tri", vis = {"WARN_MC", -0.5, 0.5}, alt = {{"CAUTION"}, night_hue(AMBER), {"WARN_MC", 0.5, 1.5}},
		frame = AMBER},


	{47, {"A/P", {"AP_TXT", "%s"}}, WHITE, "tri", vis = {"AP_LINES", -0.5, 2.5},
		alt = {{"A/P", {"AP_TXT", "%s"}, "ALT"}, WHITE, {"AP_LINES", 2.5, 3.5}}},
	{70, {"R1", "OFF"}, GREEN, "tab", vis = {"RADIO_1_V", -0.5, 0.5},
		alt = {{"R1", {"RADIO_1_FREQ", "%.3f"}, {"RADIO_1_TXT", "%s"}}, GREEN, {"RADIO_1_V", 0.5, 1.5}}},
	{71, {"R2", "OFF"}, GREEN, "tab", vis = {"RADIO_2_V", -0.5, 0.5},
		alt = {{"R2", {"RADIO_2_FREQ", "%.3f"}, {"RADIO_2_TXT", "%s"}}, GREEN, {"RADIO_2_V", 0.5, 1.5}}},

	{66, {"HF", "02.0000", "HF OFF"}, WHITE, "tab", vis = {"HF_ON", -0.5, 0.5},
		alt = {{"HF", "02.0000", "HF ON"}, WHITE, {"HF_ON", 0.5, 1.5}}},

	{67, {"IFF OFF", {"IFF_M1", "M1-%02.0f"}, {"IFF_M2", "M2-%04.0f"}, {"IFF_M3", "M3-%04.0f"}}, WHITE, "tab",
		vis = {"IFF_ON", -0.5, 0.5},
		alt = {{"IFF ON", {"IFF_M1", "M1-%02.0f"}, {"IFF_M2", "M2-%04.0f"}, {"IFF_M3", "M3-%04.0f"}}, WHITE,
			{"IFF_ON", 0.5, 1.5}}},
	{43, {"PP-EGI1", {"DISP_PP_ERR_FT", "%.0f'"}}, GREEN, "tri", vis = GPS,
		alt = {{"PP-INS", {"DISP_PP_ERR_FT", "%.0f'"}}, GREEN, NOGPS}},
	{37, {"LAW", "OFF"}, WHITE, "tab", vis = {"LAW_ON", -0.5, 0.5}, chars = 5,
		alt = {{"LAW", {"LAW_FT", "%.0f"}}, WHITE, {"LAW_ON", 0.5, 1.5}}},
	{40, {"TCN", "OFF"}, WHITE, "tab", vis = OFF_TCN, alt = {{"TCN", {"NAV_TCN_TXT", "%s"}}, WHITE, ON_TCN}},
	{40, {"ILS", "OFF"}, WHITE, "tab", vis = OFF_ILS, chars = 6, alt = {{"ILS", {"NAV_ILS_FREQ", "%.2f"}}, WHITE, ON_ILS}},
	{42, {"HUD"}, WHITE, "tri"},

	{40, {"GCAS", "OFF"}, GREEN, "tri", vis = {"GCWS_ON", -0.5, 0.5}, alt = {{"GCAS", "ON"}, GREEN, {"GCWS_ON", 0.5, 1.5}}},

	{42, {"NF-OFF", {"NAV_TF_TXT", "%s"}}, WHITE, "tri", chars = 7},
	{46, {"POS", "UPDATE"}, WHITE, "tri"},
	{31, {"KEY", "PAD"}, WHITE, "tri"},
	{35, {"SSB", "2"}, WHITE, "tri"},
}

assert(#TILES == #LAD_STRIP.TILES, "strip: tile count differs from lad_strip.lua")
for k, t in ipairs(TILES) do assert(t[1] == LAD_STRIP.TILES[k][1], "strip: tile "..k.." width differs from lad_strip.lua") end
local GAP = LAD_STRIP.GAP
local Y0, Y1 = STRIP_BOTTOM + 0.005, A - 0.005
for k, t in ipairs(TILES) do
	local x, x2 = LAD_STRIP.edges(k)
	local xa, xb = x + GAP / 2, x2 - GAP / 2
	local fc = t.frame or t[3]
	rect(xa, Y0, xb, Y1, LW, fc)

	local m = 0.010
	if t[4] == "tab" then
		rect(xb - m, Y1 - m, xb, Y1, LW, fc)
	else
		poly({{xb, Y0}, {xb, Y0 + m}, {xb - m, Y0}}, fc, nil, nil, nil, "tri")
	end
	local function draw(lines, c, vis)
		local n = #lines
		local h, pitch = H_BY_N[math.min(n, 4)], PITCH_BY_N[math.min(n, 4)]
		local chars = t.chars or 0
		for _, line in ipairs(lines) do
			if type(line) == "string" then chars = math.max(chars, #line) end
		end
		if chars > 0 then h = math.min(h, (xb - xa - 2 * FIT_MARGIN) / (0.56 * chars - 0.14)) end
		local cx, cy = (xa + xb) / 2, (Y0 + Y1) / 2
		for i, line in ipairs(lines) do
			local y = cy + ((n + 1) / 2 - i) * pitch
			if type(line) == "table" then
				text(nil, {cx, y}, h, c, "CenterCenter", nil, line, vis)
			else
				text(line, {cx, y}, h, c, "CenterCenter", nil, nil, vis)
			end
		end
	end
	draw(t[2], t[3], t.vis)
	if t.alt then draw(t.alt[1], t.alt[2], t.alt[3]) end
end

touch_mark(0, 0.012)
