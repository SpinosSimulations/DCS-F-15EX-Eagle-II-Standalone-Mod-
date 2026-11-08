
















dofile(LockOn_Options.script_path.."Displays/attack_geom.lua")

local ON = {"ATK_ON", 0.5, 1.5}
local DIM = {0, 140, 0, 255}


local TRK = {255, 235, 30, 255}
local IFF_RGB = {night_hue(TRK), night_hue({60, 255, 60, 255}), night_hue({255, 50, 40, 255})}
local DT_LINE = {40, 220, 255, 255}
local DATA = {255, 222, 110, 255}
local HD = 0.06
local LW = 0.008




local O = {ATK_O_X, ATK_O_Y}
local A1, A2 = math.rad(90 - ATK_AZ_MAX), math.rad(90 + ATK_AZ_MAX)
local NORM = ON
arc(ATK_R, A1, A2, LW, GREEN, nil, O, 32, NORM)

dashed_arc(ATK_R / 2, math.rad(90 - ATK_RING_DEG), math.rad(90 + ATK_RING_DEG), LW, GREEN, nil, O, 35, NORM)

local edges = {}
for _, b in ipairs({-ATK_AZ_MAX, ATK_AZ_MAX}) do
	local s, c = math.sin(math.rad(b)), math.cos(math.rad(b))
	edges[#edges + 1] = {O[1], O[2], O[1] + ATK_R * s, O[2] + ATK_R * c}
	local ox, oy = (b < 0 and -c or c), (b < 0 and s or -s)
	for q = 1, 3 do
		local x, y0 = O[1] + ATK_R * q / 4 * s, O[2] + ATK_R * q / 4 * c
		edges[#edges + 1] = {x, y0, x + 0.025 * ox, y0 + 0.025 * oy}
	end
end
segments(edges, LW, GREEN, nil, nil, NORM)

segments({{O[1], O[2] - 0.04, O[1], O[2] + 0.04}, {O[1] - 0.03, O[2] + 0.01, O[1] + 0.03, O[2] + 0.01},
	{O[1] - 0.015, O[2] - 0.035, O[1] + 0.015, O[2] - 0.035}}, LW, WHITE, nil, nil, NORM)


for _, side in ipairs({"L", "R"}) do
	local n = node(O, nil, {"ATK_SCAN_"..side}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
	segments({{0, 0.62 * ATK_R, 0, ATK_R}}, LW, GREEN, n, nil, {"ATK_SCAN_V", 0.5, 1.5})
end


local nn = node({0, 0}, nil, {"ATK_N_X", "ATK_N_Y"},
	{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
text("N", {0, 0}, HD, WHITE, "CenterCenter", nn, nil, {"ATK_N_V", 0.5, 1.5})


local dl = node(O, nil, {"ATK_DT_B"}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
local piece = ATK_R / ATK_DT_PIECES
for k = 1, ATK_DT_PIECES do
	segments({{0, (k - 1) * piece, 0, k * piece}}, 0.006, DT_LINE, dl, nil, {"ATK_DT_L", k - 0.5, 1e9})
end


for k = 1, 6 do
	local fl = node(O, nil, {string.format("ATK_FM%02d_B", k)}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
	local lp = string.format("ATK_FM%02d_L", k)
	for j = 1, ATK_DT_PIECES do
		segments({{0, (j - 0.7) * piece, 0, (j - 0.3) * piece}}, 0.007, WHITE, fl, nil, {lp, j - 0.5, 1e9})
	end
end


for i = 1, ATK_MAX_HITS do
	local pre = string.format("ATK_H%02d_", i)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	poly({{-0.016, -0.008}, {0.016, -0.008}, {0.016, 0.008}, {-0.016, 0.008}}, DIM, n, nil, {pre.."V", 0.5, 1.5}, "brick")
end



local dot = {}
local THR_RED = night_hue(RED)
for k = 0, 7 do dot[#dot + 1] = {0.008 * math.cos(k * math.pi / 4), 0.008 * math.sin(k * math.pi / 4)} end
for i = 1, ATK_MAX_THREATS do
	local pre = string.format("ATK_X%02d_", i)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	local v = {pre.."V", 0.5, 1.5}
	circle(0.026, 0.007, THR_RED, n, nil, 20, v)
	circle(0.017, 0.005, WHITE, n, nil, 16, v)
	poly(dot, THR_RED, n, nil, v, "thr")
end







local SQ = 0.020
local CQ = 0.018
local box = {{-SQ, -SQ, SQ, -SQ}, {SQ, -SQ, SQ, SQ}, {SQ, SQ, -SQ, SQ}, {-SQ, SQ, -SQ, -SQ}}
local dashes = {}
for _, s in ipairs({{-1, -1, 1, -1}, {1, -1, 1, 1}, {1, 1, -1, 1}, {-1, 1, -1, -1}}) do
	local x1, y1, x2, y2 = s[1] * CQ, s[2] * CQ, s[3] * CQ, s[4] * CQ
	local dx, dy = (x2 - x1) / 5, (y2 - y1) / 5
	dashes[#dashes + 1] = {x1, y1, x1 + 2 * dx, y1 + 2 * dy}
	dashes[#dashes + 1] = {x1 + 3 * dx, y1 + 3 * dy, x2, y2}
end
local brackets = {}
for _, bx in ipairs({-0.042, 0.042}) do
	for d = 0, 2 do
		local y0 = -0.036 + d * 0.027
		brackets[#brackets + 1] = {bx, y0, bx, y0 + 0.018}
	end
end



local WEDGE = {{-0.012, SQ + 0.034}, {0.012, SQ + 0.034}, {0, SQ + 0.006}}
local function track_symbol(pre, full)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	local st = node({0, 0}, n, {pre.."H"}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
	for c = 1, ATK_IFF_STATES do
		local col, iff = IFF_RGB[c], {pre.."I", c - 1.5, c - 0.5}
		segments(box, 0.008, col, n, nil, {{pre.."V", 0.5, 1.5}, iff})
		segments(dashes, 0.007, col, n, nil, {{pre.."V", 1.5, 2.5}, iff})
		if full then poly({{-SQ, -SQ}, {SQ, -SQ}, {SQ, SQ}, {-SQ, SQ}}, col, n, nil, {{pre.."M", 0.5, 1.5}, iff}, "msl") end
		poly(WEDGE, col, n, nil, {{pre.."D", 0.5, 1.5}, {pre.."V", 0.5, 2.5}, iff}, "wedge")
		for k = 1, ATK_STICK_STEPS do
			segments({{0, SQ, 0, SQ + k * ATK_STICK_LEN}}, 0.008, col, st, nil,
				{{pre.."L", k - 0.5, k + 0.5}, {pre.."V", 0.5, 1.5}, iff})
		end
	end

	for k = 1, ATK_STICK_STEPS do
		local d = {}
		for j = 0, k - 1 do
			local y0 = SQ + j * ATK_STICK_LEN
			d[#d + 1] = {0, y0 + 0.006, 0, y0 + ATK_STICK_LEN - 0.006}
		end
		segments(d, 0.007, TRK, st, nil, {{pre.."L", k - 0.5, k + 0.5}, {pre.."V", 1.5, 2.5}})
	end
	segments(brackets, 0.008, WHITE, n, nil, {pre.."D", 0.5, 1.5})
	if full then
		circle(0.06, 0.006, WHITE, n, nil, 20, {pre.."S", 0.5, 1.5})

		text(nil, {0.05, 0.045}, 0.04, DATA, "LeftCenter", n, {pre.."P", "%.0f"}, {pre.."P", 0.5, 12.5})

	end
end
for i = 1, ATK_MAX_TRACKS do track_symbol(string.format("ATK_T%02d_", i), true) end






local DL_RGB = {IFF_RGB[3], IFF_RGB[2], IFF_RGB[1]}
local DL_W = 0.022
local dl_frames = {
	{{-DL_W, -0.006, 0, DL_W}, {0, DL_W, DL_W, -0.006}},
	nil,
	{{-DL_W, -0.010, -DL_W, DL_W}, {-DL_W, DL_W, DL_W, DL_W}, {DL_W, DL_W, DL_W, -0.010}},
}
local function dl_symbol(pre)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	local st = node({0, 0}, n, {pre.."H"}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
	for c = 1, 3 do
		local v = {pre.."V", c - 0.5, c + 0.5}
		if dl_frames[c] then segments(dl_frames[c], 0.008, DL_RGB[c], n, nil, v)
		else arc(DL_W, 0, math.pi, 0.008, DL_RGB[c], n, nil, 10, v) end
		for k = 1, ATK_STICK_STEPS do
			segments({{0, DL_W, 0, DL_W + k * ATK_STICK_LEN}}, 0.007, DL_RGB[c], st, nil, {v, {pre.."L", k - 0.5, k + 0.5}})
		end
	end
	segments(brackets, 0.008, WHITE, n, nil, {{pre.."V", 0.5, 3.5}, {pre.."D", 0.5, 1.5}})
end
for i = 1, ATK_MAX_DL do dl_symbol(string.format("ATK_L%02d_", i)) end
for i = 1, ATK_MAX_TRACKS do
	local pre = string.format("ATK_T%02d_", i)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	segments({{-SQ, -SQ - 0.012, SQ, -SQ - 0.012}}, 0.006, WHITE, n, nil, {{pre.."V", 0.5, 2.5}, {pre.."K", 0.5, 1.5}})
end



local cn = node({0, 0}, nil, {"ATK_CUR_X", "ATK_CUR_Y"},
	{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
segments({{-ATK_CUR_HALF_W, -ATK_CUR_HALF_H, -ATK_CUR_HALF_W, ATK_CUR_HALF_H},
	{ATK_CUR_HALF_W, -ATK_CUR_HALF_H, ATK_CUR_HALF_W, ATK_CUR_HALF_H}}, LW, WHITE, cn, nil, {"ATK_CUR_V", 0.5, 1.5})
text(nil, {0.035, 0.028}, 0.045, WHITE, "LeftCenter", cn, {"ATK_CUR_HI", "%02.0f"}, {"ATK_CUR_HV", 0.5, 1.5})
text(nil, {0.035, -0.028}, 0.045, WHITE, "LeftCenter", cn, {"ATK_CUR_LO", "%02.0f"}, {"ATK_CUR_HV", 0.5, 1.5})




do
	local ev = {ON, {"ATK_EXP", 0.5, 2.5}}
	local x0, y0 = ATK_EXP_CX - ATK_EXP_HX, ATK_EXP_CY - ATK_EXP_HY
	local x1, y1 = ATK_EXP_CX + ATK_EXP_HX, ATK_EXP_CY + ATK_EXP_HY
	poly({{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}}, BLACK, nil, nil, ev, "exp_bg")
	rect(x0, y0, x1, y1, LW, WHITE, nil, ev)





	local function inset_line(px, py, b, l, w, rgba, a, z)
		local n = node({0, 0}, node({ATK_EXP_CX, ATK_EXP_CY}, nil, {px, py},
			{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}}),
			{b}, {{"rotate_using_parameter", 0, ATK_ROT_GAIN}})
		local h = ATK_EXP_PIECES * piece / 2
		for j = 1, ATK_EXP_PIECES do
			segments({{0, (j - a) * piece - h, 0, (j - z) * piece - h}}, w, rgba, n, nil, {ev[1], ev[2], {l, j - 0.5, 1e9}})
		end
	end
	inset_line("ATK_EDT_X", "ATK_EDT_Y", "ATK_DT_B", "ATK_EDT_L", 0.006, DT_LINE, 1, 0)
	for k = 1, 6 do
		local pre = string.format("ATK_EFM%02d_", k)
		inset_line(pre.."X", pre.."Y", pre.."B", pre.."L", 0.007, WHITE, 0.7, 0.3)
	end
	for i = 1, ATK_EXP_HITS do
		local pre = string.format("ATK_EH%02d_", i)
		local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
			{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
		poly({{-0.016, -0.008}, {0.016, -0.008}, {0.016, 0.008}, {-0.016, 0.008}}, DIM, n, nil, {pre.."V", 0.5, 1.5}, "ebrick")
	end
	for i = 1, ATK_EXP_DL do dl_symbol(string.format("ATK_EL%02d_", i)) end
	for i = 1, ATK_EXP_TRACKS do track_symbol(string.format("ATK_E%02d_", i), false) end
end



text(nil, {-0.90, 0.89}, HD, DATA, "LeftCenter", nil, {"ATK_CUR_BR", "%s"}, ON)

text(nil, {0.90, 0.89}, 0.075, GREEN, "RightCenter", nil, {"ATK_RNG", "%.0f"}, ON)


for k, c in ipairs({"D", "C", "L"}) do text(c, {-0.94, 0.74 - 0.065 * (k - 1)}, HD, GREEN, "CenterCenter", nil, nil, ON) end

text(nil, {0, 0.55}, 0.07, DATA, "CenterCenter", nil, {"ATK_MSG", "%s"}, {"ATK_MSG_V", 0.5, 1.5})



local bv = {"ATK_BAND_V", 0.5, 1.5}
local bt = {{ATK_BAND_X, ATK_BAND_TOP, ATK_BAND_X, ATK_BAND_BOT},
	{ATK_BAND_X - 0.03, ATK_BAND_TOP, ATK_BAND_X, ATK_BAND_TOP}, {ATK_BAND_X - 0.03, ATK_BAND_BOT, ATK_BAND_X, ATK_BAND_BOT}}
for q = 1, 3 do
	local yq = ATK_BAND_TOP + (ATK_BAND_BOT - ATK_BAND_TOP) * q / 4
	bt[#bt + 1] = {ATK_BAND_X, yq, ATK_BAND_X + 0.02, yq}
end
segments(bt, LW, GREEN, nil, nil, bv)
for _, e in ipairs({{"ATK_BAND_HI", ATK_BAND_TOP}, {"ATK_BAND_LO", ATK_BAND_BOT}}) do
	circle(0.016, 0.006, WHITE, nil, {ATK_BAND_X + 0.045, e[2]}, 14, bv)
	text(nil, {ATK_BAND_X + 0.07, e[2]}, HD, WHITE, "LeftCenter", nil, {e[1], "%02.0f"}, bv)
end
local bd = node({ATK_BAND_X, 0}, nil, {"ATK_BAND_DY"}, {{"move_up_down_using_parameter", 0, S(1)}})
segments({{-0.014, -0.014, 0.014, -0.014}, {0.014, -0.014, 0.014, 0.014}, {0.014, 0.014, -0.014, 0.014},
	{-0.014, 0.014, -0.014, -0.014}}, 0.006, TRK, bd, nil, {bv, {"ATK_BAND_DV", 0.5, 1.5}})
local bc = node({ATK_BAND_X, 0}, nil, {"ATK_BAND_CY"}, {{"move_up_down_using_parameter", 0, S(1)}})
poly({{0, 0}, {-0.035, 0.02}, {-0.035, -0.02}}, WHITE, bc, nil, {"ATK_BAND_CV", 0.5, 1.5}, "caret")

local ec = node({ATK_BAND_X, 0}, nil, {"ATK_EL_CY"}, {{"move_up_down_using_parameter", 0, S(1)}})
segments({{0.005, 0, 0.035, 0.016}, {0.035, 0.016, 0.035, -0.016}, {0.035, -0.016, 0.005, 0}}, 0.006, GREEN, ec, nil,
	{"ATK_EL_CV", 0.5, 1.5})


text(nil, {-0.90, -0.64}, 0.075, GREEN, "LeftCenter", nil, {"ATK_ACM", "%s"}, {ON, {"RDR_ACM", 0.5, 6.5}})

local dv = {"ATK_DT_V", 0.5, 1.5}
for c = 1, ATK_IFF_STATES do
	segments({{-0.88, -0.755, -0.85, -0.755}, {-0.85, -0.755, -0.85, -0.725}, {-0.85, -0.725, -0.88, -0.725},
		{-0.88, -0.725, -0.88, -0.755}}, 0.006, IFF_RGB[c], nil, nil, {dv, {"ATK_DT_I", c - 1.5, c - 0.5}})
end
text(nil, {-0.90, -0.80}, HD, DATA, "LeftCenter", nil, {"ATK_DT_BLK", "%s"}, dv)

text(nil, {-0.82, -0.74}, HD, DATA, "LeftCenter", nil, {"ATK_DT_ID", "%s"}, dv)


segments({{0.57, -0.36, 0.57, -0.53}, {0.57, -0.36, 0.60, -0.36}, {0.57, -0.53, 0.60, -0.53}}, LW, GREEN, nil, nil, dv)
text(nil, {0.61, -0.40}, HD, DATA, "LeftCenter", nil, {"ATK_DT_BR", "%s"}, dv)
text(nil, {0.61, -0.49}, HD, DATA, "LeftCenter", nil, {"ATK_DT_CL", "%.0f"}, dv)



do
	local zv = {ON, {"ATK_Z_V", 0.5, 1.5}}
	local cv = {ON, {"ATK_Z_W", 0.5, 1.5}}
	local X, step = ATK_Z_X, (ATK_Z_TOP - ATK_Z_BOT) / ATK_Z_DASHES
	local d = {}
	for k = 0, ATK_Z_DASHES - 1 do
		local y0 = ATK_Z_BOT + k * step
		d[#d + 1] = {X, y0 + 0.2 * step, X, y0 + 0.8 * step}
	end
	segments(d, LW, GREEN, nil, nil, zv)
	local rc = node({0, 0}, nil, {"ATK_Z_RC"}, {{"move_up_down_using_parameter", 0, S(1)}})
	segments({{X - 0.05, 0, X - 0.008, 0}, {X - 0.035, 0.02, X - 0.008, 0}, {X - 0.008, 0, X - 0.035, -0.02}}, LW, GREEN, rc,
		nil, {ON, {"ATK_Z_V", 0.5, 1.5}, {"ATK_Z_CV", 0.5, 1.5}})

	local function on(n) return {ON, {"ATK_Z_W", 0.5, 1.5}, {"ATK_Z_"..n, -1e9, ATK_Z_TOP + 1e-3}} end
	local T = 0.022
	local ra = node({0, 0}, nil, {"ATK_Z_AERO"}, {{"move_up_down_using_parameter", 0, S(1)}})
	segments({{X - T, -T * 0.8, X + T, -T * 0.8}, {X + T, -T * 0.8, X, T}, {X, T, X - T, -T * 0.8}}, LW, GREEN, ra, nil,
		on("AERO"))
	text(nil, {X - 0.035, 0}, HD, GREEN, "RightCenter", ra, {"ATK_Z_AN", "%.0f"}, on("AERO"))
	circle(0.014, LW, GREEN, node({0, 0}, nil, {"ATK_Z_OPT"}, {{"move_up_down_using_parameter", 0, S(1)}}), {X, 0}, 14,
		on("OPT"))
	segments({{X - 0.025, 0, X + 0.025, 0}}, 0.016, GREEN,
		node({0, 0}, nil, {"ATK_Z_PI"}, {{"move_up_down_using_parameter", 0, S(1)}}), nil, on("PI"))
	local tee = node({0, 0}, nil, {"ATK_Z_MNVR"}, {{"move_up_down_using_parameter", 0, S(1)}})
	poly({{X + 0.008, 0}, {X + 0.033, 0.015}, {X + 0.033, -0.015}}, GREEN, tee, nil, on("MNVR"), "ztee")
	segments({{X + 0.033, 0, X + 0.055, 0}}, LW, GREEN, tee, nil, on("MNVR"))
	local TX = X + 0.03
	segments({{X, 0, TX + 0.012, 0}}, LW, GREEN, node({0, 0}, nil, {"ATK_Z_TR"}, {{"move_up_down_using_parameter", 0, S(1)}}),
		nil, on("TR"))
	segments({{X, 0, TX, 0}}, LW, GREEN, node({0, 0}, nil, {"ATK_Z_MIN"}, {{"move_up_down_using_parameter", 0, S(1)}}), nil,
		on("MIN"))
	local piece = (ATK_Z_TOP - ATK_Z_BOT) / ATK_Z_PIECES
	for k = 1, ATK_Z_PIECES do
		local y0 = ATK_Z_BOT + (k - 1) * piece
		segments({{TX, y0, TX, y0 + piece}}, LW, GREEN, nil, nil,
			{ON, {"ATK_Z_W", 0.5, 1.5}, {"ATK_Z_LO", -1e9, k - 0.5}, {"ATK_Z_HI", k - 0.5, 1e9}})
	end
end



text(nil, {0.61, -0.58}, HD, {0, 220, 255, 255}, "LeftCenter", nil, {"ATK_DT_BE", "%s"}, dv)
text(nil, {0.93, -0.91}, HD, {0, 220, 255, 255}, "RightCenter", nil, {"ATK_CUR_BE", "%s"}, ON)



for i = 1, 4 do
	text(nil, {-0.28, -0.60 - 0.065 * (i - 1)}, HD, DATA, "LeftCenter", nil, {"MSL_L"..i, "%s"}, ON)
end


for _, k in ipairs({{"INLV", -0.72, ON}, {"RDR", -0.42, {ON, {"ATK_RDR_ON", 0.5, 1.5}}}, {"IRST", -0.10, false}}) do
	text(k[1], {k[2], -0.91}, HD, GREEN, "CenterCenter", nil, nil, ON)
	if k[3] then rect(k[2] - 0.10, -0.955, k[2] + 0.10, -0.865, 0.006, GREEN, nil, k[3]) end
end
text("RADAR OFF", {0, 0.10}, 0.075, GREEN, "CenterCenter", nil, nil, {ON, {"ATK_RDR_ON", -0.5, 0.5}})
