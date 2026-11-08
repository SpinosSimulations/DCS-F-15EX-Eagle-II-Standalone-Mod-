


















dofile(LockOn_Options.script_path.."Displays/ew_geom.lua")

local RING = {0, 200, 0, 255}
local G = {0, 230, 0, 255}
local TRK = {255, 238, 160, 255}
local DATA = {255, 222, 110, 255}
local CYAN = {0, 220, 255, 255}
local BULLS = {255, 214, 40, 255}
local THREAT = {255, 40, 20, 255}
local MARK = {255, 0, 255, 255}
local HS = 0.05
local LW = 0.008
local CW = TEXFONT_RECT_X * HS * TEXT_CAP_RATIO / TEXFONT_CAP

local function mover(px, py, parent)
	return node({0, 0}, parent, {px, py},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
end



circle(SITP_R, 0.006, RING, nil, nil, 64)
local rose = node({0, 0}, nil, {"SITP_ROSE_ROT"}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
local ticks = {}
for k = 0, 11 do
	if k % 3 ~= 0 then
		local x1, y1 = ew_xy(math.rad(30 * k), SITP_R - 0.018)
		local x2, y2 = ew_xy(math.rad(30 * k), SITP_R + 0.018)
		ticks[#ticks + 1] = {x1, y1, x2, y2}
	end
end
segments(ticks, 0.006, RING, rose)
for k, c in ipairs(SITP_ROSE_LABELS) do
	text(c, {0, 0}, HS, WHITE, "CenterCenter", mover(string.format("SITP_ROSE_%02d_X", k), string.format("SITP_ROSE_%02d_Y", k)))
end


local own = node({0, -SITP_OFF}, nil, {"SITP_DCTR"}, {{"move_up_down_using_parameter", 0, S(SITP_OFF)}})


local NORM = {"SITP_EXP", -0.5, 0.5}

segments({{0, -0.025, 0, 0.035}, {-0.025, 0.012, 0.025, 0.012}, {-0.02, -0.025, 0.02, -0.025}}, 0.007, CYAN, own, nil,
	NORM)


for d = 0, 1 do
	local top = (d == 0 and SITP_OFF or 0) + SITP_R
	segments({{0, 0.05, 0, top - 0.005}, {-0.022, top - 0.045, 0, top - 0.005}, {0, top - 0.005, 0.022, top - 0.045}},
		0.005, YELLOW, own, nil, {NORM, {"SITP_DCTR", d - 0.5, d + 0.5}})
end
for lvl = 1, 2 do
	text("EXP"..lvl, {0.93, 0.86}, HS, G, "RightCenter", nil, nil, {"SITP_EXP", lvl - 0.5, lvl + 0.5})
end





local function line_node(px, py, b)
	return node({0, 0}, node({0, 0}, nil, {px, py},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}}),
		{b}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
end
local dl = line_node("SITP_DT_X", "SITP_DT_Y", "SITP_DT_B")
for k = 1, SITP_DT_PIECES do
	segments({{0, (k - 1) * SITP_DT_PIECE - SITP_LINE_HALF, 0, k * SITP_DT_PIECE - SITP_LINE_HALF}}, 0.006, CYAN, dl, nil,
		{{"SITP_DT_V", 0.5, 1.5}, {"SITP_DT_L", k - 0.5, 1e9}})
end



for k = 1, 6 do
	local fl = line_node(string.format("SITP_FM%02d_X", k), string.format("SITP_FM%02d_Y", k),
		string.format("SITP_FM%02d_B", k))
	local lp = string.format("SITP_FM%02d_L", k)
	for j = 1, SITP_DT_PIECES do
		segments({{0, (j - 0.7) * SITP_DT_PIECE - SITP_LINE_HALF, 0, (j - 0.3) * SITP_DT_PIECE - SITP_LINE_HALF}}, 0.007,
			WHITE, fl, nil, {lp, j - 0.5, 1e9})
	end
end







for g = 1, SITP_MAX_LEG do
	local pre = string.format("SITP_G%02d_", g)
	local at = node({0, 0}, mover(pre.."X", pre.."Y"), {pre.."A"}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
	for b = 0, SITP_LEG_BITS - 1 do
		local len = 2 ^ b * SITP_LEG_STEP
		local bit = pre.."B"..b
		local mid = node({0, 0}, at, {bit}, {{"move_left_right_using_parameter", 0, S(len / 2)}})
		segments({{-len / 2, 0, len / 2, 0}}, 0.006, WHITE, mid, nil, {bit, 0.5, 1.5})
		at = node({0, 0}, at, {bit}, {{"move_left_right_using_parameter", 0, S(len)}})
	end
end
local TRI = 0.024
for k = 1, SITP_MAX_STPT do
	local pre = string.format("SITP_S%02d_", k)
	segments({{-TRI, -0.7 * TRI, TRI, -0.7 * TRI}, {TRI, -0.7 * TRI, 0, 1.1 * TRI}, {0, 1.1 * TRI, -TRI, -0.7 * TRI}}, 0.006,
		WHITE, mover(pre.."X", pre.."Y", own), nil, {pre.."V", 0.5, 1.5})
end


local be = mover("SITP_BE_X", "SITP_BE_Y", own)
circle(0.032, 0.007, BULLS, be, nil, 16, {"SITP_BE_V", 0.5, 1.5})
poly({{-0.009, -0.009}, {0.009, -0.009}, {0.009, 0.009}, {-0.009, 0.009}}, BULLS, be, nil, {"SITP_BE_V", 0.5, 1.5}, "bed")




local ID_H, ID_X, ID_Y = 0.038, 0.045, -0.042
local SQ = 0.018
local CQ = 0.015
local dashes = {}
for _, s in ipairs({{-1, -1, 1, -1}, {1, -1, 1, 1}, {1, 1, -1, 1}, {-1, 1, -1, -1}}) do
	local x1, y1, x2, y2 = s[1] * CQ, s[2] * CQ, s[3] * CQ, s[4] * CQ
	local dx, dy = (x2 - x1) / 5, (y2 - y1) / 5
	dashes[#dashes + 1] = {x1, y1, x1 + 2 * dx, y1 + 2 * dy}
	dashes[#dashes + 1] = {x1 + 3 * dx, y1 + 3 * dy, x2, y2}
end


local IFF_RGB = {night_hue(TRK), night_hue({60, 255, 60, 255}), night_hue({255, 50, 40, 255})}
for i = 1, SITP_MAX_TRK do
	local pre = string.format("SITP_T%02d_", i)
	local n = mover(pre.."X", pre.."Y", own)
	local st = node({0, 0}, n, {pre.."H"}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
	for c, rgb in ipairs(IFF_RGB) do
		local iff = {pre.."I", c - 1.5, c - 0.5}
		poly({{-SQ, -SQ}, {SQ, -SQ}, {SQ, SQ}, {-SQ, SQ}}, rgb, n, nil, {{pre.."V", 0.5, 1.5}, iff}, "trk"..c)
		segments(dashes, 0.006, rgb, n, nil, {{pre.."V", 1.5, 2.5}, iff})
		for k = 1, SITP_STICK_STEPS do
			segments({{0, SQ, 0, SQ + k * SITP_STICK_LEN}}, 0.007, rgb, st, nil,
				{{pre.."V", 0.5, 2.5}, {pre.."L", k - 0.5, k + 0.5}, iff})
		end
	end
	text(nil, {0, 0.05}, 0.045, DATA, "CenterCenter", n, {pre.."ALT", "%.0f"}, {pre.."V", 0.5, 2.5})
	text(nil, {ID_X, ID_Y}, ID_H, DATA, "LeftCenter", n, {pre.."ID", "%s"}, {pre.."V", 0.5, 2.5})
	segments({{-0.036, -0.03, -0.036, 0.03}, {0.036, -0.03, 0.036, 0.03}}, 0.007, WHITE, n, nil,
		{{pre.."V", 0.5, 2.5}, {pre.."D", 0.5, 1.5}})
end


local DL_RGB = {night_hue(THREAT), night_hue({60, 255, 60, 255}), night_hue(TRK)}
local DW = 0.02
local dl_frames = {
	{{-DW, -0.006, 0, DW}, {0, DW, DW, -0.006}},
	nil,
	{{-DW, -0.010, -DW, DW}, {-DW, DW, DW, DW}, {DW, DW, DW, -0.010}},
}
for i = 1, SITP_MAX_DL do
	local pre = string.format("SITP_L%02d_", i)
	local n = mover(pre.."X", pre.."Y", own)
	local st = node({0, 0}, n, {pre.."H"}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
	for c = 1, 3 do
		local v = {pre.."V", c - 0.5, c + 0.5}
		if dl_frames[c] then segments(dl_frames[c], 0.007, DL_RGB[c], n, nil, v)
		else arc(DW, 0, math.pi, 0.007, DL_RGB[c], n, nil, 10, v) end
		for k = 1, SITP_STICK_STEPS do
			segments({{0, DW, 0, DW + k * SITP_STICK_LEN}}, 0.007, DL_RGB[c], st, nil, {v, {pre.."L", k - 0.5, k + 0.5}})
		end
	end
	text(nil, {0, 0.05}, 0.045, DATA, "CenterCenter", n, {pre.."ALT", "%.0f"}, {pre.."V", 0.5, 3.5})
	text(nil, {ID_X, ID_Y}, ID_H, DATA, "LeftCenter", n, {pre.."ID", "%s"}, {pre.."V", 0.5, 3.5})
	segments({{-0.036, -0.03, -0.036, 0.03}, {0.036, -0.03, 0.036, 0.03}}, 0.007, WHITE, n, nil,
		{{pre.."V", 0.5, 3.5}, {pre.."D", 0.5, 1.5}})
end




local THR_RGB = {night_hue({235, 235, 235, 255}), night_hue({255, 160, 0, 255}), night_hue(THREAT)}
for i = 1, SITP_MAX_THR do
	local pre = string.format("SITP_R%02d_", i)
	local n = mover(pre.."X", pre.."Y", own)
	local on = {pre.."V", 0.5, 2.5}
	for c, rgb in ipairs(THR_RGB) do
		local con = {on, {pre.."CLR", c - 0.5, c + 0.5}}
		segments({{-0.025, -0.018, 0.025, -0.018}, {0.025, -0.018, 0, 0.028}, {0, 0.028, -0.025, -0.018}}, 0.008, rgb, n,
			nil, con)
		poly({{-0.009, -0.009}, {0.009, -0.009}, {0, 0.008}}, rgb, n, nil,
			{{pre.."V", 1.5, 2.5}, {pre.."CLR", c - 0.5, c + 0.5}}, "fix"..c)
		text(nil, {0.055, 0.0}, 0.045, rgb, "LeftCenter", n, {pre.."TXT", "%s"}, {on, {pre.."CN", -0.5, 0.5},
			{pre.."CLR", c - 0.5, c + 0.5}})
		text(nil, {0.055, 0.0}, 0.045, rgb, "LeftCenter", n, {pre.."NUM", "%.0f"}, {on, {pre.."CN", 0.5, 1.5},
			{pre.."CLR", c - 0.5, c + 0.5}})
		if c >= 2 then
			for k, r in ipairs(SITP_RINGS) do
				dashed_arc(r, 0, 2 * math.pi, 0.005, rgb, n, nil, 25, {{pre.."V", 1.5, 2.5}, {pre.."RING", k - 0.5, k + 0.5},
					{pre.."CLR", c - 0.5, c + 0.5}})
			end
		end
	end
	segments({{-0.045, 0.045, -0.045, -0.04}, {-0.045, 0.045, -0.025, 0.045}, {-0.045, -0.04, -0.025, -0.04},
		{0.045, 0.045, 0.045, -0.04}, {0.045, 0.045, 0.025, 0.045}, {0.045, -0.04, 0.025, -0.04}}, 0.007, MARK, n, nil,
		{on, {pre.."LOCK", 0.5, 1.5}})
end




local cur = mover("SITP_CUR_DX", "SITP_CUR_DY", own)
segments({{-0.018, -0.035, -0.018, 0.035}, {0.018, -0.035, 0.018, 0.035}}, 0.008, WHITE, cur, nil, {"SITP_CUR_V", 0.5, 1.5})


local function vlegend(pb, s, p)
	local x, y = LAD_PB.pos(pb)
	x = x + (x < 0 and -0.045 or 0.045)
	local h = LAD_CHROME.LEG_H
	local step = h * 1.15
	local y0 = y + (#s - 1) / 2 * step
	for k = 1, #s do text(s:sub(k, k), {x, y0 - (k - 1) * step}, h, G, "CenterCenter") end
	if p then
		local half = (#s - 1) / 2 * step + h * 0.75
		rect(x - 0.035, y - half, x + 0.035, y + half, 0.006, G, nil, {p, 0.5, 1.5})
	end
end
vlegend(1, "LNE", "SITP_LNE")
vlegend(2, "AIR", "SITP_AIR")
vlegend(3, "GND")
vlegend(4, "SAM", "SITP_SAM")
vlegend(5, "FTF")
vlegend(13, "JTID", "SITP_JTID")
vlegend(14, "DCTR", "SITP_DCTR")
lad_legend(15, "DM", nil, G)
lad_legend(6, "AIR", nil, G)
lad_legend(7, "RDR", nil, G)

text(nil, {0.93, 0.93}, HS, G, "RightCenter", nil, {"SITP_RNG", "%.0f"})

local BX, BY = 0.93 - 7 * CW, -0.95
text(nil, {BX, BY}, HS, CYAN, "LeftCenter", nil, {"SITP_BEB", "%03.0f-"}, {"SITP_BEV", 0.5, 2.5})
text(nil, {BX + 4 * CW, BY}, HS, CYAN, "LeftCenter", nil, {"SITP_BER", "%.0f"}, {"SITP_BEV", 0.5, 2.5})
