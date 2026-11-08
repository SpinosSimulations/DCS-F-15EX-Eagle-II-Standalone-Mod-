






















dofile(LockOn_Options.script_path.."Displays/common.lua")
SetScale(MILLYRADIANS)
COLLIMATED = true
dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")
dofile(LockOn_Options.script_path.."Displays/aa_geom.lua")

local LOC_IN, LOC_OUT = 24, 80
local HMD_TRK = 12
local MSL_MAX = 4
local RED = {255, 38, 30, 255}
local RED_NIGHT = {1, 0.15, 0.12}





local ZOOM = 1.3

do
	dofile(LockOn_Options.script_path.."Displays/hud_symbols.lua")
	TEXT_WEIGHT = HUD_LOOK.WEIGHT
	SYM_TINT = {param = "HMD_SYM_SEL", base = HUD_LOOK.C}
	POWER_VIS = {"HMD_DRAW", 0.5, 1.5}
	BRT_PARAM = "HUD_BRT"
	local C, LW, H, HS = HUD_LOOK.C, HUD_LOOK.LW, HUD_LOOK.H, HUD_LOOK.HS
	local AG = HUDAA_GEOM
	local HEAD = {"HMD_HEAD_OK", 0.5, 1.5}
	local NO_HEAD = {"HMD_HEAD_OK", -0.5, 0.5}
	XF = {k = ZOOM, root = node({0, 0})}


	hud_cross()
	hud_heading_tape("HMD_HT", HEAD)
	hud_air_data()
	hud_weapon_block()
	hud_target_block({"HUDAA_RS_V", 0.5, 1.5})


	hud_range_scale(HEAD)
	text("NO HEAD", {0, -96}, H, C, "CenterCenter", nil, nil, NO_HEAD)
	text("SYM FAIL", {0, -96}, H, C, "CenterCenter", nil, nil, {HEAD, {"HMD_RT_OK", -0.5, 0.5}})

	local function mover(px, py)
		return node({0, 0}, nil, {px, py}, {{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	end

	local function world_mover(px, py)
		local xf = XF
		XF = nil
		local m = mover(px, py)
		XF = xf
		return m
	end

	dofile(LockOn_Options.script_path.."Displays/HMD/world.lua")
	local WH = {xy = function(id) return "HMD_"..id end, mover = world_mover, HEAD = HEAD, C = C, LW = LW, H = H,
		vis = function(id) return {{"HMD_"..id.."_V", 0.5, 1.5}} end}


	HMD_WORLD.td_box(WH)


















	local spm = HMD_WORLD.sp_diamond(WH)
	local d = NAV_HUD_DIAMOND
	segments({{-d, 0, 0, d}, {0, d, d, 0}, {d, 0, 0, -d}, {0, -d, -d, 0}}, LW, C, spm, nil, {{"HMD_SP_V", 1.5, 2.5}, HEAD})
	segments({{-d, -d, d, d}, {-d, d, d, -d}}, LW, C, spm, nil, {{"HMD_SP_V", 1.5, 2.5}, HEAD})
	local BV = {"HMD_BRG_V", 0.5, 1.5}
	local caret = node({0, NAV_HUD_CARET_Y}, nil, {"HMD_BRG_X"}, {{"move_left_right_using_parameter", 0, S(1)}})
	segments({{0, -1.5, 0, -9}}, LW, C, caret, nil, {BV, HEAD})
	for _, s in ipairs({1, -1}) do
		local pin = s > 0 and {"HMD_BRG_X", NAV_HUD_CARET - 0.5, 1e9} or {"HMD_BRG_X", -1e9, -NAV_HUD_CARET + 0.5}
		text(nil, {s * NAV_HUD_CARET, NAV_HUD_CARET_Y - 16}, HS, C, s > 0 and "RightCenter" or "LeftCenter", nil,
			{"NAV_BRG", "%03.0f"}, {BV, pin, HEAD})
	end



	local LV = {{"HMD_LOC_V", 0.5, 1.5}, HEAD}
	local rot = node({0, 0}, nil, {"HMD_LOC_ROT"}, {{"rotate_using_parameter", 0, 1}})
	segments({{LOC_IN, 0, LOC_OUT, 0}, {LOC_OUT, 0, LOC_OUT - 6, 4}, {LOC_OUT, 0, LOC_OUT - 6, -4}}, LW, C, rot, nil, LV)
	local loc = mover("HMD_LOC_X", "HMD_LOC_Y")
	text(nil, {0, 0}, H, C, "CenterCenter", loc, {"HMD_LOC_OFF", "%.0f"}, LV)



	HMD_WORLD.seeker(WH)



	circle(5 * 17.4533 / ZOOM, LW, C, nil, nil, 64, {{"RDR_ACM", 5.5, 6.5}, {"RDR_ACM_BUSY", -0.5, 0.5}, HEAD})





	local RLV = {{"HMD_RL_V", 0.5, 1.5}, HEAD}
	local rrot = node({0, 0}, nil, {"HMD_RL_ROT"}, {{"rotate_using_parameter", 0, 1}})
	segments({{112, 7, 120, 0}, {120, 0, 112, -7}, {120, 7, 128, 0}, {128, 0, 120, -7}}, LW, C, rrot, nil, RLV)
	local rl = mover("HMD_RL_X", "HMD_RL_Y")
	text(nil, {0, 6}, HS, C, "CenterCenter", rl, {"HMD_RL_TXT", "%s"}, {RLV[1], RLV[2], {"HMD_RL_CN", -0.5, 0.5}})
	text(nil, {0, 6}, HS, C, "CenterCenter", rl, {"HMD_RL_NUM", "%.0f"}, {RLV[1], RLV[2], {"HMD_RL_CN", 0.5, 1.5}})
	text(nil, {0, -6}, HS, C, "CenterCenter", rl, {"HMD_RL_TTI", "%.0f"}, {RLV[1], RLV[2], {"HMD_RL_TTI", -0.5, 1e6}})
	text("--", {0, -6}, HS, C, "CenterCenter", rl, nil, {RLV[1], RLV[2], {"HMD_RL_TTI", -1e6, -0.5}})


	HMD_WORLD.tracks(WH, HMD_TRK)

	do
		local C = RED
		NIGHT_TINT = RED_NIGHT
		local TW = 2 * LW
		local MH = 1.4 * H
		local FL = {"HMD_MFL", 0.5, 1.5}

		HMD_WORLD.missiles({xy = WH.xy, vis = WH.vis, mover = world_mover, HEAD = HEAD, C = C, LW = LW}, MSL_MAX, TW, MH, FL)

		local MLV = {{"HMD_ML_V", 0.5, 1.5}, HEAD}
		local mrot = node({0, 0}, nil, {"HMD_ML_ROT"}, {{"rotate_using_parameter", 0, 1}})
		local ch = {}
		for _, x0 in ipairs({76, 86, 96}) do
			ch[#ch + 1] = {x0, 10, x0 + 8, 0}
			ch[#ch + 1] = {x0 + 8, 0, x0, -10}
		end
		segments(ch, TW, C, mrot, nil, MLV)
		local ml = mover("HMD_ML_X", "HMD_ML_Y")
		text("M", {0, 7}, H, C, "CenterCenter", ml, nil, MLV)
		text(nil, {0, -7}, H, C, "CenterCenter", ml, {"HMD_ML_TTI", "%.0f"}, {MLV[1], MLV[2], {"HMD_ML_TTI", -0.5, 1e6}})
		text("--", {0, -7}, H, C, "CenterCenter", ml, nil, {MLV[1], MLV[2], {"HMD_ML_TTI", -1e6, -0.5}})


		local BY, BH = -36, 9
		local MS = {"HMD_MS_V", 0.5, 1.5}
		text(nil, {0, BY}, 1.5 * H, C, "CenterCenter", nil, {"HMD_MS_TTI", "MSL ACT %.0f"}, {MS, {"HMD_MS_TTI", -0.5, 1e6}})
		text("MSL ACT --", {0, BY}, 1.5 * H, C, "CenterCenter", nil, nil, {MS, {"HMD_MS_TTI", -1e6, -0.5}})
		text("LAUNCH", {0, BY}, 1.5 * H, C, "CenterCenter", nil, nil, {"HMD_MS_V", 1.5, 2.5})
		rect(-55, BY - BH, 55, BY + BH, TW, C, nil, {{"HMD_MS_V", 0.5, 2.5}, FL})
	end
	XF = nil
	POWER_VIS, NIGHT_TINT, SYM_TINT, BRT_PARAM = nil, nil, nil, nil
end

