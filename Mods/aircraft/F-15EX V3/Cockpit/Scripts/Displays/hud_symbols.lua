









HUD_LOOK = {
	C = {35, 213, 45, 255},
	WEIGHT = "bold",
	H = 10,
}
HUD_LOOK.LW = 0.15 * TEXT_CAP_RATIO * HUD_LOOK.H
HUD_LOOK.HS = 0.8 * HUD_LOOK.H

local L = HUD_LOOK
local C, LW, H, HS = L.C, L.LW, L.H, L.HS


function hud_cross(vis)
	segments({{-6, 0, 6, 0}, {0, -6, 0, 6}}, LW, C, nil, nil, vis)
end



function hud_heading_tape(prefix, vis)
	local TY = NAV_TAPE_Y
	local function gate(g) return vis and {g, vis} or g end
	segments({{-NAV_TAPE_HALF, TY, NAV_TAPE_HALF, TY}}, LW, C, nil, nil, vis)
	segments({{-3, TY - 6.5, 0, TY - 1.5}, {0, TY - 1.5, 3, TY - 6.5}}, LW, C, nil, nil, vis)
	for k = 1, NAV_TAPE_SLOTS do
		local tk = node({0, 0}, nil, {string.format("%s%02d_X", prefix, k)}, {{"move_left_right_using_parameter", 0, S(1)}})
		local lp = string.format("%s%02d_L", prefix, k)
		segments({{0, TY, 0, TY + NAV_TAPE_SHORT}}, LW, C, tk, nil, gate({lp, 0.5, 1.5}))
		segments({{0, TY, 0, TY + NAV_TAPE_LONG}}, LW, C, tk, nil, gate({lp, 1.5, 2.5}))
		text(nil, {0, TY + NAV_TAPE_LONG + 5}, HS, C, "CenterCenter", tk, {string.format("%s%02d_N", prefix, k), "%02.0f"},
			gate({lp, 1.5, 2.5}))
	end
end






HMD_LAYOUT = {AD_IN = 66, WX = -90}
HUD_LAYOUT = get_aircraft_type() == "F15IA" and {AD_IN = 100, WX = -160} or {AD_IN = 66, WX = -90}




HUD_SYM = {}
function hud_air_data(lay)
	local IN = (lay or HMD_LAYOUT).AD_IN
	local BOX_H = 1.3 * H
	local ADV, PAD, BY = 0.63 * BOX_H, 3, 20
	local BH = 1.2 * TEXT_CAP_RATIO * H
	local function box_w(n) return n * ADV + 2 * PAD end
	local CAS_L = -IN - box_w(3)
	rect(CAS_L, BY - BH, -IN, BY + BH, LW, C)
	text(nil, {-IN - PAD, BY}, BOX_H, C, "RightCenter", nil, {"DISP_CAS", "%.0f"})
	local ALT_R = IN + box_w(5)
	rect(ALT_R - box_w(4), BY - BH, ALT_R, BY + BH, LW, C, nil, {"DISP_ALT_FT", -99999, 9999.5})
	rect(ALT_R - box_w(5), BY - BH, ALT_R, BY + BH, LW, C, nil, {"DISP_ALT_FT", 9999.5, 999999})
	text(nil, {ALT_R - PAD, BY}, BOX_H, C, "RightCenter", nil, {"DISP_ALT_FT", "%.0f"})
	local UNDER = BY - BH - 9

	do
		local cx, cy, rx, ry = CAS_L + 3.5, UNDER, 2.6, 3.0
		local list, n = {}, 8
		for k = 0, n - 1 do
			local a0, a1 = math.rad(40 + 280 * k / n), math.rad(40 + 280 * (k + 1) / n)
			list[#list + 1] = {cx + rx * math.cos(a0), cy + ry * math.sin(a0), cx + rx * math.cos(a1), cy + ry * math.sin(a1)}
		end
		local ux, uy = cx + rx * math.cos(math.rad(40)), cy + ry * math.sin(math.rad(40))
		local lx, ly = cx + rx * math.cos(math.rad(320)), cy + ry * math.sin(math.rad(320))
		list[#list + 1] = {ux, uy, ux + 2.6, cy - 3.4}
		list[#list + 1] = {lx, ly, lx + 2.6, cy + 3.4}
		segments(list, LW, C)
	end
	text(nil, {-IN, UNDER}, H, C, "RightCenter", nil, {"DISP_AOA", "%.1f"})
	text(nil, {ALT_R - PAD, BY + BH + 8}, HS, C, "RightCenter", nil, {"DISP_VVI", "%.0f"})
	text(nil, {ALT_R - PAD, UNDER}, H, C, "RightCenter", nil, {"DISP_RALT_FT", "R %.0f"})
	HUD_SYM.CAS_L, HUD_SYM.ALT_R, HUD_SYM.UNDER, HUD_SYM.BRX = CAS_L, ALT_R, UNDER, IN
end



function hud_weapon_block(lay)
	local WX = (lay or HMD_LAYOUT).WX
	HUD_SYM.WX = WX
	text(nil, {WX, -52}, H, C, "LeftCenter", nil, {"HUDAA_WPN", "%s"}, {"HUDAA_WPN_V", 0.5, 1.5})
	text(nil, {WX, -52}, H, C, "LeftCenter", nil, {"HUDAA_AMMO", "%.0f"}, {"HUDAA_AMMO_V", 0.5, 1.5})
	text("SAFE", {WX, -40}, H, C, "LeftCenter", nil, nil, {"SMS_ARM", -0.5, 0.5})
	text(nil, {WX, -64}, H, C, "LeftCenter", nil, {"DISP_MACH_HUD", "%.3f"})
	text(nil, {WX, -76}, H, C, "LeftCenter", nil, {"DISP_G", "%.1f"})
	text(nil, {WX + 28, -76}, H, C, "LeftCenter", nil, {"DISP_GMAX", "%.1f"})
end


local function and_gate(vis, g)
	local list = {}
	if type(vis[1]) == "string" then list[1] = vis else for _, v in ipairs(vis) do list[#list + 1] = v end end
	if type(g[1]) == "string" then list[#list + 1] = g else for _, v in ipairs(g) do list[#list + 1] = v end end
	return list
end




function hud_td_box(parent, box_vis, off_vis, off_param, shoot_vis, shoot_dy)
	local AG = HUDAA_GEOM
	local q = AG.TD_HALF
	rect(-q, -q, q, q, LW, C, parent, and_gate(box_vis, {"HUDAA_TD_DL", -0.5, 0.5}))
	dotted_rect(-q, -q, q, q, AG.TD_DOT, AG.TD_GAP, LW, C, parent, and_gate(box_vis, {"HUDAA_TD_DL", 0.5, 1.5}))
	if off_vis then

		text(nil, {0, -q - 7}, H, C, "CenterCenter", parent, {off_param, "%.0f"}, {off_vis, {"HUDAA_TD_TUP", -0.5, 0.5}})
		text(nil, {0, q + 7}, H, C, "CenterCenter", parent, {off_param, "%.0f"}, {off_vis, {"HUDAA_TD_TUP", 0.5, 1.5}})
	end
	local r, dy, list = AG.SHOOT_R, shoot_dy or AG.SHOOT_DY, {}
	for _, a0 in ipairs({90, 270}) do
		for k = 0, 2 do
			local a, b = math.rad(a0 + 120 * k), math.rad(a0 + 120 * (k + 1))
			list[#list + 1] = {r * math.cos(a), dy + r * math.sin(a), r * math.cos(b), dy + r * math.sin(b)}
		end
	end
	segments(list, LW, C, parent, nil, shoot_vis)






	local MH = 1.25 * H
	local cap, adv = TEXT_CAP_RATIO * MH, 0.63 * MH
	for up = 0, 1 do
		local y, tup = q + 9 + up * 13, {"HUDAA_TD_TUP", up - 0.5, up + 0.5}
		text(nil, {-4, y}, MH, C, "RightCenter", parent, {"MSL_DT_TA", "A%02.0f"},
			and_gate(box_vis, {{"MSL_DT_V", 0.5, 1.5}, {"MSL_DT_TA", -0.5, 1e6}, tup}))
		local act = and_gate(box_vis, {{"MSL_DT_V", 1.5, 2.5}, {"MSL_DT_FL", -0.5, 0.5}, tup})
		text("ACT", {-4, y}, MH, C, "RightCenter", parent, nil, act)
		rect(-4 - 3 * adv - 2, y - cap / 2 - 2.2, -4 + 2, y + cap / 2 + 2.2, LW, C, parent, act)
		text(nil, {4, y}, MH, C, "LeftCenter", parent, {"MSL_DT_TTI", "T%02.0f"},
			and_gate(box_vis, {{"MSL_DT_V", 0.5, 2.5}, {"MSL_DT_TTI", -0.5, 1e6}, tup}))
	end
end



function hud_target_block(vis)
	text(nil, {HUD_SYM.BRX, -68}, H, C, "LeftCenter", nil, {"HUDAA_TGT_ALT", "%s"}, vis)
	text(nil, {HUD_SYM.ALT_R, -68}, H, C, "RightCenter", nil, {"HUDAA_TGT_ASP", "%s"}, vis)
	text(nil, {HUD_SYM.BRX, -80}, H, C, "LeftCenter", nil, {"HUDAA_RNG", "R %.1f"}, vis)
end













function hud_range_scale(head)
	local AG = HUDAA_GEOM
	local X = HUD_SYM.BRX - AG.RS_IN
	HUD_SYM.RS_X = X
	local function g(list)
		if head then list[#list + 1] = head end
		return #list == 1 and list[1] or list
	end
	local function vmover(py) return node({0, 0}, nil, {py}, {{"move_up_down_using_parameter", 0, S(1)}}) end
	local rv = {"HUDAA_RS_V", 0.5, 1.5}
	local rs = {{X, AG.RS_BOT, X, AG.RS_TOP}}
	for k = 0, 4 do
		local y = AG.RS_BOT + (AG.RS_TOP - AG.RS_BOT) * k / 4
		rs[#rs + 1] = {X, y, X + 3, y}
	end
	segments(rs, LW, C, nil, nil, g({rv}))
	text(nil, {X, AG.RS_TOP + 6}, HS, C, "CenterCenter", nil, {"HUDAA_RS_MAX", "%.0f"}, g({rv}))
	local rc = vmover("HUDAA_RC_Y")
	segments({{X - 2, 0, X - 8, 4}, {X - 8, 4, X - 8, -4}, {X - 8, -4, X - 2, 0}}, LW, C, rc, nil, g({rv}))
	text(nil, {X - 10, 0}, HS, C, "RightCenter", rc, {"HUDAA_CLO", "%.0f"}, g({rv}))
	local dv = {"HUDAA_DLZ_V", 0.5, 1.5}
	local function on(n) return g({dv, {"HUDAA_"..n.."_Y", -1e9, AG.RS_TOP + 0.5}}) end
	local TRI = AG.WEZ_TRI
	segments({{X - TRI, -TRI, X + TRI, -TRI}, {X + TRI, -TRI, X, TRI}, {X, TRI, X - TRI, -TRI}}, LW, C, vmover("HUDAA_AERO_Y"),
		nil, on("AERO"))
	circle(AG.WEZ_CIRC, LW, C, vmover("HUDAA_OPT_Y"), {X, 0}, 12, on("OPT"))
	segments({{X - AG.WEZ_BAR, 0, X + AG.WEZ_BAR, 0}}, 2.0, C, vmover("HUDAA_PI_Y"), nil, on("PI"))
	do
		local tee = vmover("HUDAA_MNVR_Y")
		local T = AG.WEZ_TEE
		poly({{X + 1, 0}, {X + 1 + T, T * 0.6}, {X + 1 + T, -T * 0.6}}, C, tee, nil, on("MNVR"), "tee")
		segments({{X + 1 + T, 0, X + 1 + 2 * T, 0}}, LW, C, tee, nil, on("MNVR"))
	end
	segments({{X, 0, X + AG.WEZ_TR_X + 2, 0}}, LW, C, vmover("HUDAA_TR_Y"), nil, on("TR"))
	segments({{X, 0, X + AG.WEZ_TR_X, 0}}, LW, C, vmover("HUDAA_MIN_Y"), nil, on("MIN"))
	local piece = (AG.RS_TOP - AG.RS_BOT) / AG.NE_PIECES
	for k = 1, AG.NE_PIECES do
		local y0 = AG.RS_BOT + (k - 1) * piece
		segments({{X + AG.WEZ_TR_X, y0, X + AG.WEZ_TR_X, y0 + piece}}, LW, C, nil, nil,
			g({dv, {"HUDAA_NE_LO", -1e9, k - 0.5}, {"HUDAA_NE_HI", k - 0.5, 1e9}}))
	end
	text(nil, {X + 1, AG.RS_BOT - 6}, HS, C, "RightCenter", nil, {"HUDAA_TTI", "T%.0f"}, g({{"HUDAA_DLZ_V", 0.5, 1.5},
		{"HUDAA_TTI_V", 0.5, 1.5}}))
end
