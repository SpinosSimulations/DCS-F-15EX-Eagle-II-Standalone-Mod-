











dofile(LockOn_Options.script_path.."Displays/common.lua")
SetScale(MILLYRADIANS)
COLLIMATED = true
dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")
dofile(LockOn_Options.script_path.."Displays/aa_geom.lua")
dofile(LockOn_Options.script_path.."Displays/hud_symbols.lua")
TEXT_WEIGHT = HUD_LOOK.WEIGHT
SYM_TINT = {param = "HUD_SYM_SEL", base = HUD_LOOK.C}

local C = HUD_LOOK.C
local LW = HUD_LOOK.LW
local H = HUD_LOOK.H
local HS = HUD_LOOK.HS












local HUD_CLIP = true
dofile(LockOn_Options.script_path.."Displays/hud_glass.lua")
local MASK_MM = HUD_GLASS_MM
local MASK = {}
for i, v in ipairs(MASK_MM) do
	MASK[i] = {v[1] * 0.001 / GetScale(), v[2] * 0.001 / GetScale()}
end
if HUD_CLIP then
	clip_mask(MASK)
end
POWER_VIS = {"DISP_PWR_HUD", 0.5, 1.5}
BRT_PARAM = "HUD_BRT"





local HUD_MASK_DEBUG = false
if HUD_MASK_DEBUG then
	local clip, coll = CLIP_LEVEL, COLLIMATED
	CLIP_LEVEL, COLLIMATED = nil, false
	local list = {}
	for i, v in ipairs(MASK) do
		local w = MASK[i % #MASK + 1]
		list[#list + 1] = {v[1], v[2], w[1], w[2]}
	end
	segments(list, 1, {255, 0, 255, 255})
	segments({{-5, 0, 5, 0}, {0, -5, 0, 5}}, 1, {255, 0, 255, 255})
	CLIP_LEVEL, COLLIMATED = clip, coll
	text(string.format("SCALE %.6g", GetScale()), {30, -38}, 7, C, "LeftCenter")
end

local function mover(px, py)
	return node({0, 0}, nil, {px, py},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
end
local function vmover(py)
	return node({0, 0}, nil, {py}, {{"move_up_down_using_parameter", 0, S(1)}})
end

local function dashed_circle(r, n, fill, parent, vis)
	local list = {}
	for j = 0, n - 1 do
		local a0 = 2 * math.pi * j / n
		local a1 = a0 + 2 * math.pi * fill / n
		for k = 0, 2 do
			local b0, b1 = a0 + (a1 - a0) * k / 3, a0 + (a1 - a0) * (k + 1) / 3
			list[#list + 1] = {r * math.cos(b0), r * math.sin(b0), r * math.cos(b1), r * math.sin(b1)}
		end
	end
	return segments(list, LW, C, parent, nil, vis)
end
local function dot(r, parent, vis, prefix)
	local v = {}
	for k = 0, 7 do v[#v + 1] = {r * math.cos(k * math.pi / 4), r * math.sin(k * math.pi / 4)} end
	return poly(v, C, parent, nil, vis, prefix or "dot")
end


hud_cross()




hud_heading_tape("HUDNAV_T")
local caret = node({0, NAV_HUD_CARET_Y}, nil, {"HUDNAV_BRG_X"}, {{"move_left_right_using_parameter", 0, S(1)}})
segments({{0, -1.5, 0, -9}}, LW, C, caret, nil, {"HUDNAV_SP_V", 0.5, 2.5})


for _, s in ipairs({1, -1}) do
	local pin = s > 0 and {"HUDNAV_BRG_X", NAV_HUD_CARET - 0.5, 1e9} or {"HUDNAV_BRG_X", -1e9, -NAV_HUD_CARET + 0.5}
	text(nil, {s * NAV_HUD_CARET, NAV_HUD_CARET_Y - 16}, HS, C, s > 0 and "RightCenter" or "LeftCenter", nil,
		{"NAV_BRG", "%03.0f"}, {{"HUDNAV_SP_V", 0.5, 2.5}, pin})
end




local horizon = node({0, 0}, nil, {"HUD_ROLL", "HUD_PITCH"},
	{{"rotate_using_parameter", 0, 1}, {"move_up_down_using_parameter", 1, -S(1)}})








local HOR = 100
segments({{-HOR, -5, -HOR, 0}, {-HOR, 0, -24, 0}, {24, 0, HOR, 0}, {HOR, 0, HOR, -5}}, LW, C, horizon)
local IN, OUTR, TICK = 24, 60, 5
local pos, neg = {}, {}
for d = 5, 175, 5 do
	local y = d * 17.4533
	local label = tostring(d <= 90 and d or 180 - d)
	local t = d < 90 and TICK or (d > 90 and -TICK or 0)
	for _, s in ipairs({-1, 1}) do
		pos[#pos + 1] = {s * IN, y, s * OUTR, y}
		if t ~= 0 then pos[#pos + 1] = {s * OUTR, y, s * OUTR, y - t} end
		for k = 0, 3 do
			local x0 = IN + k * (OUTR - IN) / 4
			neg[#neg + 1] = {s * x0, -y, s * (x0 + (OUTR - IN) / 4 * 0.6), -y}
		end
		if t ~= 0 then neg[#neg + 1] = {s * OUTR, -y, s * OUTR, -y + t} end
	end
	text(label, {-OUTR - 3, y - t / 2}, H, C, "RightCenter", horizon)
	text(label, {OUTR + 3, y - t / 2}, H, C, "LeftCenter", horizon)
	text(label, {-OUTR - 3, -y + t / 2}, H, C, "RightCenter", horizon)
	text(label, {OUTR + 3, -y + t / 2}, H, C, "LeftCenter", horizon)
end
segments(pos, LW, C, horizon)
segments(neg, LW, C, horizon)


local fpm = node({0, 0}, nil, {"HUD_FPM_X", "HUD_FPM_Y"},
	{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
circle(6, LW, C, fpm, {0, 0}, 16)
segments({{-18, 0, -6, 0}, {6, 0, 18, 0}, {0, 6, 0, 13}}, LW, C, fpm)








hud_air_data(HUD_LAYOUT)
local ALT_R = HUD_SYM.ALT_R




hud_weapon_block(HUD_LAYOUT)


do
	local r, x, y, list = 3.5, HUD_SYM.WX + 4, -28, {}
	for k = 0, 2 do
		local a = math.rad(90 + 60 * k)
		list[#list + 1] = {x + r * math.cos(a), y + r * math.sin(a), x - r * math.cos(a), y - r * math.sin(a)}
	end
	segments(list, LW, C, nil, nil, {"DISP_SOI", -0.5, 0.5})
end



local AG = HUDAA_GEOM



local td = mover("HUDAA_TD_X", "HUDAA_TD_Y")
hud_td_box(td, {"HUDAA_TD_V", 0.5, 2.5}, {"HUDAA_TD_V", 1.5, 3.5}, "HUDAA_TD_OFF",
	{{"HUDAA_SHOOT_V", 0.5, 1.5}, {"HUDAA_TD_V", 0.5, 1.5}})



local rv = {"HUDAA_RS_V", 0.5, 1.5}
hud_range_scale()

local BRX = HUD_SYM.BRX
hud_target_block(rv)




local av = {"HUDAA_ASE_V", 0.5, 1.5}

local ase_bands = {}
do
	local lo = AG.ASE_MIN - 1
	while lo < AG.ASE_MAX + 1 do
		local hi = lo * AG.ASE_BAND
		ase_bands[#ase_bands + 1] = {lo, hi, math.sqrt(lo * hi)}
		lo = hi
	end
	ase_bands[1][1] = -1
	ase_bands[#ase_bands][2] = 1e3
end
for j = 0, AG.ASE_DASHES - 1 do
	local share = 2 * math.pi / AG.ASE_DASHES
	local a = share * (j + 0.5)
	local ca, sa = math.cos(a), math.sin(a)
	local n = node({0, 0}, nil, {"HUDAA_ASE_R", "HUDAA_ASE_R"},
		{{"move_left_right_using_parameter", 0, S(ca)}, {"move_up_down_using_parameter", 1, S(sa)}})

	for _, b in ipairs(ase_bands) do
		local rb, half, segs = b[3], share * AG.ASE_DUTY / 2, {}
		local function pt(t) return rb * (math.cos(a + t) - ca), rb * (math.sin(a + t) - sa) end
		for k = 0, AG.ASE_ARC_PIECES - 1 do
			local x1, y1 = pt(-half + 2 * half * k / AG.ASE_ARC_PIECES)
			local x2, y2 = pt(-half + 2 * half * (k + 1) / AG.ASE_ARC_PIECES)
			segs[#segs + 1] = {x1, y1, x2, y2}
		end
		segments(segs, LW, C, n, nil, {av, {"HUDAA_ASE_R", b[1], b[2]}})
	end
end
local asp = node({0, 0}, nil, {"HUDAA_ASP"}, {{"rotate_using_parameter", 0, 1}})
local asp_out = node({0, 0}, asp, {"HUDAA_ASE_R"}, {{"move_up_down_using_parameter", 0, S(1)}})
segments({{0, 0, 0, AG.ASPECT_LEN}}, LW, C, asp_out, nil, {av, {"HUDAA_ASP_V", 0.5, 1.5}})
local sdot = mover("HUDAA_DOT_X", "HUDAA_DOT_Y")
dot(2.2, sdot, {"HUDAA_ASE_V", 0.5, 1.5})



circle(AG.SKR_FOV_R, LW, C, nil, {0, 0}, 40, {"HUDAA_SKR_V", 0.5, 2.5})
local skr = mover("HUDAA_SKR_X", "HUDAA_SKR_Y")
circle(AG.SEEKER_R, LW, C, skr, {0, 0}, 24, {{"HUDAA_SKR_V", 1.5, 2.5}, {"SRM_UNCAGE", -1.5, 0.5}})
circle(AG.SEEKER_UNC_R, LW, C, skr, {0, 0}, 40, {{"HUDAA_SKR_V", 1.5, 2.5}, {"SRM_UNCAGE", 0.5, 1.5}})
do
	local dm = 0.55 * AG.SEEKER_R
	segments({{-dm, 0, 0, dm}, {0, dm, dm, 0}, {dm, 0, 0, -dm}, {0, -dm, -dm, 0}}, LW, C, skr, nil,
		{{"HUDAA_SKR_V", 1.5, 2.5}, {"HUDAA_SKR_TONE", 0.5, 1.5}})
end





local DEG = 17.4533
circle(10 * DEG, LW, C, vmover("ACM_HUD_Y"), {0, 0}, 72, {"RDR_ACM", 0.5, 1.5})
circle(2 * DEG, LW, C, nil, {0, 0}, 32, {"RDR_ACM", 1.5, 2.5})
dashed_circle(1.25 * DEG, 10, 0.55, nil, {"RDR_ACM", 2.5, 3.5})
text("LR", {1.25 * DEG * 0.75 + 3, 1.25 * DEG * 0.75 + 3}, H, C, "LeftBottom", nil, nil, {"RDR_ACM", 2.5, 3.5})
segments({{0, 9, 0, 130}}, LW, C, nil, nil, {"RDR_ACM", 3.5, 4.5})





local gv = {"HUDAA_GUN_V", 0.5, 1.5}
local no_ret = {"HUDAA_RET_V", -0.5, 0.5}
for _, side in ipairs({"L", "R"}) do
	for k = 1, AG.FUNNEL_DASHES do
		local f = string.format("HUDAA_GD%s%d_", side, k)
		local n = node({0, 0}, mover(f.."X", f.."Y"), {f.."A"}, {{"rotate_using_parameter", 0, 1}})
		segments({{-AG.FUNNEL_DASH_LEN / 2, 0, AG.FUNNEL_DASH_LEN / 2, 0}}, LW, C, n, nil,
			{gv, no_ret, {f.."V", 0.5, 1.5}})
	end
end
local ret = mover("HUDAA_RET_X", "HUDAA_RET_Y")
local retv = {gv, {"HUDAA_RET_V", 0.5, 1.5}}
do
	local R = AG.RETICLE_R
	local list = {}
	for k = 0, 11 do
		local a = math.rad(30 * k)
		local T = AG.RETICLE_TICK
		list[#list + 1] = {R * math.cos(a), R * math.sin(a), (R + T) * math.cos(a), (R + T) * math.sin(a)}
	end
	segments(list, LW, C, ret, nil, retv)
end
circle(AG.RETICLE_R, LW, C, ret, {0, 0}, 60, retv)
dot(AG.RETICLE_DOT, ret, retv, "pip")




local rb_step = AG.RB_MAX_FT / 1000 / AG.RB_PIECES
local RB_W = AG.RB_W
for i = 1, AG.RB_PIECES do
	local a0 = math.pi / 2 - 2 * math.pi * (i - 1) / AG.RB_PIECES
	local a1 = math.pi / 2 - 2 * math.pi * i / AG.RB_PIECES
	local ri, ro = AG.RB_R - RB_W / 2, AG.RB_R + RB_W / 2
	poly({{ri * math.cos(a0), ri * math.sin(a0)}, {ri * math.cos(a1), ri * math.sin(a1)},
		{ro * math.cos(a1), ro * math.sin(a1)}, {ro * math.cos(a0), ro * math.sin(a0)}}, C, ret, nil,
		{gv, {"HUDAA_RET_V", 0.5, 1.5}, {"HUDAA_RB", (i - 0.5) * rb_step, 1e9}}, "rb")
end
for k = 1, 3 do
	dot(AG.PIPPER_R, mover(string.format("HUDAA_PS%d_X", k), string.format("HUDAA_PS%d_Y", k)),
		{gv, {"HUDAA_PIP_V", 0.5, 1.5}, {string.format("HUDAA_PS%d_V", k), 0.5, 1.5}}, "pip")
end





local sp = mover("HUDNAV_SP_X", "HUDNAV_SP_Y")
local d = NAV_HUD_DIAMOND
segments({{-d, 0, 0, d}, {0, d, d, 0}, {d, 0, 0, -d}, {0, -d, -d, 0}}, LW, C, sp, nil, {"HUDNAV_SP_V", 0.5, 2.5})
segments({{-d, -d, d, d}, {-d, d, d, -d}}, LW, C, sp, nil, {"HUDNAV_SP_V", 1.5, 2.5})
local loc = node({0, 0}, nil, {"HUDNAV_LOC_X"}, {{"move_left_right_using_parameter", 0, S(1)}})
segments({{0, -NAV_HUD_ILS_LEN / 2, 0, NAV_HUD_ILS_LEN / 2}}, LW, C, loc, nil, {"HUDNAV_ILS_V", 0.5, 1.5})
local gs = vmover("HUDNAV_GS_Y")
segments({{-NAV_HUD_ILS_LEN / 2, 0, NAV_HUD_ILS_LEN / 2, 0}}, LW, C, gs, nil, {"HUDNAV_GS_V", 0.5, 1.5})
text(nil, {BRX, -80}, H, C, "LeftCenter", nil, {"NAV_RNG", "N %.1f"}, {{"NAV_STPT_V", 0.5, 1.5}, {"HUDAA_RS_V", -0.5, 0.5}})


local NAV_MM = {"MASTER_MODE", 2.5, 3.5}
text("NAV", {BRX, -56}, H, C, "LeftCenter", nil, nil, NAV_MM)
text(nil, {BRX, -68}, H, C, "LeftCenter", nil, {"NAV_STPT", "%.0f"}, {NAV_MM, {"NAV_STPT_V", 0.5, 1.5}})
text(nil, {BRX, -92}, HS, C, "LeftCenter", nil, {"HUDNAV_ETE", "%s"}, {NAV_MM, {"NAV_STPT_V", 0.5, 1.5}})


























































































text(nil, {0, -96}, H, C, "CenterCenter", nil, {"HUDNAV_TXT", "%s"})


text("NWS", {0, -84}, H, C, "CenterCenter", nil, nil, {"EFM_NWS", 0.5, 1.5})
text("NWS HI", {0, -84}, H, C, "CenterCenter", nil, nil, {"EFM_NWS", 1.5, 2.5})
