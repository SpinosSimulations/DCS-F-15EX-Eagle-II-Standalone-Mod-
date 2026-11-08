








HMD_WORLD = {}

local function gates(W, id, ...)
	local list = {}
	for _, g in ipairs(W.vis(id)) do list[#list + 1] = g end
	for _, g in ipairs({...}) do list[#list + 1] = g end
	return list
end
HMD_WORLD.gates = gates


local function mover(W, id)
	return W.mover(W.xy(id).."_X", W.xy(id).."_Y")
end
HMD_WORLD.mover = mover





function HMD_WORLD.td_box(W)
	local m = mover(W, "TGT")
	local q = HUDAA_GEOM.TD_HALF
	local ty = -q - 2 - TEXT_CAP_RATIO * W.H / 2
	hud_td_box(m, gates(W, "TGT", W.HEAD), nil, nil, gates(W, "TGT", {"HUDAA_SHOOT_V", 0.5, 1.5}, W.HEAD),
		ty - TEXT_CAP_RATIO * W.H / 2 - 2 - HUDAA_GEOM.SHOOT_R)
	text(nil, {0, ty}, W.H, W.C, "CenterCenter", m, {"ATK_DT_TYPE", "%s"}, gates(W, "TGT", W.HEAD))
end






















function HMD_WORLD.sp_diamond(W)
	local m = mover(W, "SP")
	local d = NAV_HUD_DIAMOND
	segments({{-d, 0, 0, d}, {0, d, d, 0}, {d, 0, 0, -d}, {0, -d, -d, 0}}, W.LW, W.C, m, nil, gates(W, "SP", W.HEAD))
	return m
end



function HMD_WORLD.seeker(W)
	local AG = HUDAA_GEOM
	local SKR_R = AG.SEEKER_R
	local sk = mover(W, "SKR")
	circle(SKR_R, W.LW, W.C, sk, nil, 24, gates(W, "SKR", W.HEAD, {"SRM_UNCAGE", -1.5, 0.5}))
	circle(AG.SEEKER_UNC_R, W.LW, W.C, sk, nil, 40, gates(W, "SKR", W.HEAD, {"SRM_UNCAGE", 0.5, 1.5}))
	local dm = 0.55 * SKR_R
	segments({{-dm, 0, 0, dm}, {0, dm, dm, 0}, {dm, 0, 0, -dm}, {0, -dm, -dm, 0}}, W.LW, W.C, sk, nil,
		gates(W, "SKR", W.HEAD, {"HMD_SKR_TONE", 0.5, 1.5}))
	local xr = SKR_R * 0.7
	segments({{-xr, -xr, xr, xr}, {-xr, xr, xr, -xr}}, W.LW, W.C, sk, nil, gates(W, "SKR", W.HEAD, {"HMD_SKR_LIM", 0.5, 1.5}))
end


function HMD_WORLD.tracks(W, n)
	for k = 1, n do
		circle(5, W.LW, W.C, mover(W, string.format("T%02d", k)), nil, 12, gates(W, string.format("T%02d", k), W.HEAD))
	end
end



function HMD_WORLD.missiles(W, n, TW, MH, FL)
	for k = 1, n do
		local id = string.format("M%02d", k)
		local m = mover(W, id)
		local MV = gates(W, id, W.HEAD)
		local tti = string.format("HMD_M%02d_TTI", k)
		circle(13, TW, W.C, m, nil, 24, MV)
		circle(21, W.LW, W.C, m, nil, 32, gates(W, id, W.HEAD, FL))
		local sp = {}
		for _, a in ipairs({45, 135, 225, 315}) do
			local c, s = math.cos(math.rad(a)), math.sin(math.rad(a))
			sp[#sp + 1] = {15 * c, 15 * s, 27 * c, 27 * s}
		end
		segments(sp, TW, W.C, m, nil, MV)
		text("M", {0, 0}, MH, W.C, "CenterCenter", m, nil, MV)
		text(nil, {0, -33}, MH, W.C, "CenterCenter", m, {tti, "%.0f"}, gates(W, id, W.HEAD, {tti, -0.5, 1e6}))
		text("--", {0, -33}, MH, W.C, "CenterCenter", m, nil, gates(W, id, W.HEAD, {tti, -1e6, -0.5}))
	end
end
