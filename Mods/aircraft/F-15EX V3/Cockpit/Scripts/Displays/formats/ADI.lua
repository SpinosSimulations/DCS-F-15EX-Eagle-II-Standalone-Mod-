










dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")

local W = WHITE
local G = GREEN
local SKY, SKY_LINE = {28, 92, 205, 255}, {14, 50, 130, 255}
local GND, GND_LINE = {214, 196, 44, 255}, {140, 124, 18, 255}
local LW = 0.007
local HS = 0.055
dofile(LockOn_Options.script_path.."Displays/adi_geom.lua")
local R = ADI_BALL.R
local PER_DEG = ADI_BALL.PER_DEG
local MRAD = ADI_BALL.MRAD
local CY = -0.02

local function mover(px, py, parent)
	return node({0, 0}, parent, {px, py},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
end









local B = ADI_BALL
local STRIPE, D = B.STRIPE, B.D
local SW = 0.006
local NSEG = 64
local function half_chord(y) return math.sqrt(math.max(R * R - y * y, 0)) end
local function disc()
	local v = {}
	for k = 0, NSEG - 1 do v[#v + 1] = {R * math.cos(2 * math.pi * k / NSEG), R * math.sin(2 * math.pi * k / NSEG)} end
	return v
end

local function below(yc)
	if yc >= R then return disc() end
	local v, c = {}, half_chord(yc)
	v[#v + 1] = {c, yc}
	for k = 0, NSEG - 1 do
		local t = 2 * math.pi * k / NSEG
		local x, y = R * math.cos(t), R * math.sin(t)
		if y < yc then v[#v + 1] = {x, y} end
	end
	v[#v + 1] = {-c, yc}

	table.sort(v, function(p, q)
		local ap = math.atan2(p[2], p[1]); if ap > 0 then ap = ap - 2 * math.pi end
		local aq = math.atan2(q[2], q[1]); if aq > 0 then aq = aq - 2 * math.pi end
		return ap < aq
	end)
	return v
end

local function chord(y, w)
	local c = half_chord(math.abs(y) + w / 2)
	return c > 0.002 and {-c, y, c, y} or nil
end

local function stripes(y0, dir)
	local out, y = {}, y0 + dir * STRIPE
	while math.abs(y) < R do
		out[#out + 1] = chord(y, SW)
		y = y + dir * STRIPE
	end
	return out
end
local ball_c = node({0, CY})
poly(disc(), SKY, ball_c)
local ball_r = node({0, 0}, ball_c, {"HUD_ROLL"}, {{"rotate_using_parameter", 0, 1}})
local slide = node({0, 0}, ball_r, {"ADI_RES"}, {{"move_up_down_using_parameter", 0, -S(1)}})
for k = -B.K, B.K do
	local vis = {"ADI_K", k - 0.5, k + 0.5}
	local yc = -k * D
	if yc > -R then poly(below(yc), GND, slide, nil, vis) end
	local g, s = stripes(yc, -1), stripes(yc, 1)
	if #g > 0 then segments(g, SW, GND_LINE, slide, nil, vis) end
	if #s > 0 then segments(s, SW, SKY_LINE, slide, nil, vis) end
	local hl = math.abs(yc) < R and chord(yc, LW)
	if hl then segments({hl}, LW, W, slide, nil, vis) end
end

poly(disc(), GND, ball_r, nil, {"ADI_K", -1e9, B.GND + 0.5})
for j = 0, B.NJ - 1 do
	local all = {}
	for m = -math.ceil(R / STRIPE) - 1, math.ceil(R / STRIPE) + 1 do
		local y = -j * D + m * STRIPE
		if math.abs(y) < R then all[#all + 1] = chord(y, SW) end
	end
	segments(all, SW, GND_LINE, slide, nil, {{"ADI_K", -1e9, B.GND + 0.5}, {"ADI_J", j - 0.5, j + 0.5}})
	segments(all, SW, SKY_LINE, slide, nil, {{"ADI_K", B.SKY - 0.5, 1e9}, {"ADI_J", j - 0.5, j + 0.5}})
end


local horizon = node({0, 0}, ball_r, {"HUD_PITCH"}, {{"move_up_down_using_parameter", 0, -S(PER_DEG / MRAD)}})
local IN = (R - 0.04) / PER_DEG
for d = 5, 90, 5 do
	for _, s in ipairs({1, -1}) do
		local y = s * d * PER_DEG
		local vis = {"HUD_PITCH", (s * d - IN) * MRAD, (s * d + IN) * MRAD}
		if d % 10 == 0 then
			text(tostring(d), {0, y}, HS, W, "CenterCenter", horizon, nil, vis)
		else
			segments({{-0.022, y, 0.022, y}}, 0.010, W, horizon, nil, vis)
		end
	end
end


circle(R, LW, W, nil, {0, CY}, 64)
segments({{-R - 0.10, CY, -R + 0.01, CY}, {R - 0.01, CY, R + 0.10, CY}}, LW, W)
local w = node({0, CY}, nil, {"ADI_PT_Y"}, {{"move_up_down_using_parameter", 0, S(1)}})
segments({{-0.21, 0, -0.12, 0}, {-0.12, 0, -0.065, -0.085}, {-0.065, -0.085, 0, 0}, {0, 0, 0.065, -0.085},
	{0.065, -0.085, 0.12, 0}, {0.12, 0, 0.21, 0}}, 0.012, W, w)

local bank = {}
for _, a in ipairs({10, 20, 30, 45, 60}) do
	for _, s in ipairs({1, -1}) do
		local t = math.rad(-90 + s * a)
		local len = (a == 30 or a == 60) and 0.07 or 0.045
		bank[#bank + 1] = {R * math.cos(t), CY + R * math.sin(t), (R + len) * math.cos(t), CY + (R + len) * math.sin(t)}
	end
end
segments(bank, LW, W)
local roll = node({0, CY}, nil, {"HUD_ROLL"}, {{"rotate_using_parameter", 0, 1}})
poly({{0, -R}, {0.03, -R - 0.05}, {-0.03, -R - 0.05}}, W, roll, nil, nil, "bankptr")




local TY, K = 0.86, 0.50 / NAV_TAPE_HALF
segments({{-0.50, TY, 0.50, TY}}, LW, W)
for k = 1, NAV_TAPE_SLOTS do
	local tk = node({0, 0}, nil, {string.format("HUDNAV_T%02d_X", k)}, {{"move_left_right_using_parameter", 0, S(K)}})
	local lp = string.format("HUDNAV_T%02d_L", k)
	segments({{0, TY, 0, TY + 0.025}}, LW, W, tk, nil, {lp, 0.5, 1.5})
	segments({{0, TY, 0, TY + 0.05}}, LW, W, tk, nil, {lp, 1.5, 2.5})
	text(nil, {0, TY + 0.09}, HS, W, "CenterCenter", tk, {string.format("HUDNAV_T%02d_N", k), "%02.0f"}, {lp, 1.5, 2.5})
end
segments({{-0.03, TY - 0.06, 0, TY - 0.012}, {0, TY - 0.012, 0.03, TY - 0.06}}, 0.010, G)
local bug = node({0, 0}, nil, {"HUDNAV_BRG_X"}, {{"move_left_right_using_parameter", 0, S(K)}})
segments({{0, TY, 0, TY - 0.05}}, 0.012, W, bug, nil, {"HUDNAV_SP_V", 0.5, 2.5})
text(nil, {0.50, TY - 0.10}, HS, W, "CenterCenter", nil, {"NAV_BRG", "%03.0f"},
	{{"HUDNAV_SP_V", 0.5, 2.5}, {"HUDNAV_BRG_X", NAV_HUD_CARET - 0.5, 1e9}})
text(nil, {-0.50, TY - 0.10}, HS, W, "CenterCenter", nil, {"NAV_BRG", "%03.0f"},
	{{"HUDNAV_SP_V", 0.5, 2.5}, {"HUDNAV_BRG_X", -1e9, -NAV_HUD_CARET + 0.5}})


local BY = 0.66
rect(-0.70, BY - 0.045, -0.47, BY + 0.045, LW, W)
text(nil, {-0.485, BY}, HS, W, "RightCenter", nil, {"DISP_CAS", "%.0f"})
alpha_glyph(-0.68, BY - 0.10, TEXT_CAP_RATIO * HS, 0.006, W)
text(nil, {-0.64, BY - 0.10}, HS, W, "LeftCenter", nil, {"DISP_AOA", "%.1f"})
rect(0.45, BY - 0.045, 0.74, BY + 0.045, LW, W)
text(nil, {0.725, BY}, HS, W, "RightCenter", nil, {"DISP_ALT_FT", "%.0f"})
text("VV", {0.45, BY - 0.10}, HS, W, "LeftCenter")
text(nil, {0.74, BY - 0.10}, HS, W, "RightCenter", nil, {"DISP_VVI", "%.0f"})


do
	local _, y2 = LAD_PB.pos(2)
	local _, y3 = LAD_PB.pos(3)
	local x = -0.90
	poly({{x, y2 + 0.04}, {x + 0.04, y2 - 0.03}, {x - 0.04, y2 - 0.03}}, W, nil, nil, nil, "ptup")
	poly({{x, y3 - 0.04}, {x + 0.04, y3 + 0.03}, {x - 0.04, y3 + 0.03}}, W, nil, nil, nil, "ptdn")
	text("PT", {-0.97, (y2 + y3) / 2}, HS, W, "LeftCenter")
	lad_legend(5, "EGI1", {"ADI_SRC", 0.5, 1.5})
	lad_legend(5, "INS", {"ADI_SRC", 1.5, 2.5})
end


local TRY = -0.80
segments({{-0.30, TRY + 0.035, -0.30, TRY}, {-0.30, TRY, 0.30, TRY}, {0.30, TRY, 0.30, TRY + 0.035},
	{-0.10, TRY, -0.10, TRY + 0.02}, {0.10, TRY, 0.10, TRY + 0.02}}, LW, W)
local tr = node({0, 0}, nil, {"ADI_TURN_X"}, {{"move_left_right_using_parameter", 0, S(1)}})
segments({{0, TRY + 0.06, 0.035, TRY + 0.005}, {0.035, TRY + 0.005, -0.035, TRY + 0.005}, {-0.035, TRY + 0.005, 0, TRY + 0.06}},
	0.010, G, tr)
local SY = -0.88
rect(-0.13, SY - 0.025, 0.13, SY + 0.025, LW, W)
segments({{-0.035, SY - 0.025, -0.035, SY + 0.025}, {0.035, SY - 0.025, 0.035, SY + 0.025}}, LW, W)
local sb = node({0, SY}, nil, {"ADI_SLIP_X"}, {{"move_left_right_using_parameter", 0, S(1)}})
do
	local v = {}
	for k = 0, 11 do v[#v + 1] = {0.02 * math.cos(k * math.pi / 6), 0.02 * math.sin(k * math.pi / 6)} end
	poly(v, G, sb, nil, nil, "slip")
end
