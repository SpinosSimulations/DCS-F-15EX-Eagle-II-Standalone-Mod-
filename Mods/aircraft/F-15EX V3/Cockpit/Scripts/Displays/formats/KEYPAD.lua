






dofile(LockOn_Options.script_path.."Displays/lad_strip.lua")
local K = LAD_KEYPAD
local C = GREEN
local LW = 0.008

text("KEY PAD", {0, 0.70}, 0.075, C, "CenterCenter")

rect(-0.42, K.LINE_Y - 0.065, 0.42, K.LINE_Y + 0.065, LW, WHITE)
text(nil, {-0.38, K.LINE_Y}, 0.07, WHITE, "LeftCenter", nil, {"KP_LINE", "%s"})

local NOW = {
	{1, {"NAV_TCN_TXT", "NOW %s"}}, {3, {"NAV_ILS_FREQ", "NOW %.2f"}}, {4, {"NAV_CRS", "NOW %03.0f"}},
	{5, {"NAV_STPT", "NOW %.0f"}}, {21, {"RADIO_1_FREQ", "NOW %.3f"}}, {22, {"RADIO_2_FREQ", "NOW %.3f"}},
	{14, {"NAV_HDG_SEL", "NOW %03.0f"}}, {40, {"LAW_FT", "NOW %.0f"}},
	{41, {"DISP_BINGO", "NOW %.0f"}},
	{42, {"IFF_M1", "NOW %02.0f"}}, {43, {"IFF_M2", "NOW %04.0f"}}, {44, {"IFF_M3", "NOW %04.0f"}},

	{31, {"CMD_V1", "NOW %.0f"}}, {32, {"CMD_V2", "NOW %.0f"}}, {33, {"CMD_V3", "NOW %.0f"}},
	{34, {"CMD_V4", "NOW %.1f"}}, {35, {"CMD_V5", "NOW %.0f"}}, {36, {"CMD_V6", "NOW %.1f"}},
	{37, {"CMD_V7", "NOW %.1f"}}, {38, {"CMD_V8", "NOW %.0f"}}, {39, {"CMD_V9", "NOW %.0f"}},
}
for _, n in ipairs(NOW) do
	text(nil, {0, K.NOW_Y}, 0.055, C, "CenterCenter", nil, n[2],
		{{"KP_FIELD", n[1] - 0.5, n[1] + 0.5}, {"KP_ERR_V", -0.5, 0.5}})
end
text("ERROR", {0, K.NOW_Y}, 0.06, AMBER, "CenterCenter", nil, nil, {"KP_ERR_V", 0.5, 1.5})

for r, ky in ipairs(K.ROWS) do
	for c, kx in ipairs(K.COLS) do
		rect(kx - K.W / 2, ky - K.H / 2, kx + K.W / 2, ky + K.H / 2, LW, C)
		local l = K.KEYS[(r - 1) * 3 + c]
		text(l, {kx, ky}, l == "CLR" and 0.065 or 0.09, WHITE, "CenterCenter")
	end
end
rect(K.COLS[1] - K.W / 2, K.ENT_Y - K.H / 2, K.COLS[3] + K.W / 2, K.ENT_Y + K.H / 2, LW, C)
text("ENT", {0, K.ENT_Y}, 0.08, WHITE, "CenterCenter")

for n, f in pairs(K.FIELDS) do
	lad_legend(n, f[1])
	if type(f[2]) == "number" then


		local x, y, e = LAD_PB.pos(n)
		local vis = {"KP_FIELD", f[2] - 0.5, f[2] + 0.5}
		if e == "T" then

			poly({{x - 0.05, 0.955}, {x + 0.05, 0.955}, {x + 0.05, 0.99}, {x - 0.05, 0.99}}, LAD_CHROME.LEG_RGBA, nil, nil,
				vis, "kpsel")
		else
			local s = e == "R" and -1 or 1
			poly({{-0.99 * s, y - 0.05}, {-0.955 * s, y - 0.05}, {-0.955 * s, y + 0.05}, {-0.99 * s, y + 0.05}},
				LAD_CHROME.LEG_RGBA, nil, nil, vis, "kpsel")
		end
	end
end
lad_legend(K.PB_RTN, "RTN")
