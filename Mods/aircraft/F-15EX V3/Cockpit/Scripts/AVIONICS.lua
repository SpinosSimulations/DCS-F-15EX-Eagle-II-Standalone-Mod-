




local dev = GetSelf()

local update_time_step = 0.01
make_default_activity(update_time_step)

local sensor_data = get_base_data()

local M_TO_FT = 3.28084
local RAD_TO_DEG = 57.29578

local function param(name) return get_param_handle(name) end

local standalone	= param("F15EX_STANDALONE")
local lua_time		= param("LUA_TIME")

local efm_tas		= param("EFM_TAS_KT")
local efm_alpha		= param("EFM_ALPHA_DEG")
local efm_beta		= param("EFM_BETA_DEG")
local efm_vv_alpha	= param("EFM_VV_ALPHA_DEG")
local efm_vv_beta	= param("EFM_VV_BETA_DEG")

local hud_fpm_x		= param("HUD_FPM_X")
local hud_fpm_y		= param("HUD_FPM_Y")
local hud_roll		= param("HUD_ROLL")
local hud_pitch		= param("HUD_PITCH")

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end




local AIR_DATA_MIN_KT = 20
local AIR_DATA_FADE_KT = 10
local alpha, beta = 0, 0








local HYST = 0.75
local readouts = {}
local function readout(name, get, period, step, tau, wrap)
	readouts[#readouts + 1] = {out = param(name), get = get, period = period, step = step, tau = tau or 0, wrap = wrap,
		t = period}
end


local function diff(a, b, wrap)
	local d = a - b
	if wrap then d = (d + wrap / 2) % wrap - wrap / 2 end
	return d
end

local function update_readouts(dt)
	for _, r in ipairs(readouts) do
		local x = r.get()
		if r.y == nil or r.tau <= 0 then
			r.y = x
		else
			r.y = r.y + diff(x, r.y, r.wrap) * (1 - math.exp(-dt / r.tau))
		end
		if r.wrap then r.y = r.y % r.wrap end
		r.t = r.t + dt
		if r.t >= r.period - 1e-9 then
			r.t = 0
			if r.shown == nil or math.abs(diff(r.y, r.shown, r.wrap)) > HYST * r.step then
				local q = math.floor(r.y / r.step + 0.5) * r.step
				if r.wrap then q = q % r.wrap end
				if q == 0 then q = 0 end
				r.shown = q
			end
			r.out:set(r.shown)
		end
	end
end

local function efm(name)
	local h = param(name)
	return function() return h:get() end
end






local HUD_PERIOD, ENGINE_PERIOD, FUEL_PERIOD = 0.01, 0.02, 0.1


readout("DISP_HDG", function() return sensor_data.getMagneticHeading() * RAD_TO_DEG end, HUD_PERIOD, 1, 0, 360)
readout("DISP_CAS", efm("EFM_CAS_KT"), HUD_PERIOD, 1, 0.05)
readout("DISP_ALT_FT", function() return sensor_data.getBarometricAltitude() * M_TO_FT end, HUD_PERIOD, 10, 0.05)
readout("DISP_MACH", efm("EFM_MACH"), HUD_PERIOD, 0.01, 0.05)
readout("DISP_G", efm("EFM_NZ"), HUD_PERIOD, 0.1, 0.05)
readout("DISP_AOA", function() return alpha end, HUD_PERIOD, 0.1, 0.05)



local function base(name, k)
	local f = sensor_data[name]
	return function() return type(f) == "function" and (f() or 0) * k or 0 end
end
local efm_nz, efm_wow = param("EFM_NZ"), param("EFM_WOW")
local g_peak = 1.0




local FPM_GROUND_TAU = 0.4
local FPM_AIR_FADE = 2.0
local fpm = {x = 0, y = 0, air = FPM_AIR_FADE}
readout("DISP_MACH_HUD", efm("EFM_MACH"), HUD_PERIOD, 0.001, 0.05)
readout("DISP_GMAX", function() return g_peak end, HUD_PERIOD, 0.1)
readout("DISP_VVI", base("getVerticalVelocity", M_TO_FT * 60), HUD_PERIOD, 10, 0.3)
readout("DISP_RALT_FT", base("getRadarAltitude", M_TO_FT), HUD_PERIOD, 10, 0.05)

for _, s in ipairs({"L", "R"}) do
	readout("DISP_RPM_"..s, efm("EFM_RPM_"..s), ENGINE_PERIOD, 1, 0.1)
	readout("DISP_FF_"..s, efm("EFM_FF_"..s.."_PPH"), ENGINE_PERIOD, 100, 0.2)
	readout("DISP_NOZ_"..s, efm("EFM_NOZ_"..s), ENGINE_PERIOD, 1, 0.1)
	readout("DISP_FTIT_"..s, efm("EFM_FTIT_"..s), ENGINE_PERIOD, 5, 0.2)
	readout("DISP_OIL_"..s, efm("EFM_OIL_"..s), ENGINE_PERIOD, 1, 0.2)
	readout("DISP_THR_"..s, efm("EFM_THROTTLE_"..s), HUD_PERIOD, 0.01)
end

for _, t in ipairs({"INT", "EXT", "TOTAL", "FEED_L", "FEED_R", "TANK1", "WING_L", "WING_R", "CFT_L", "CFT_R"}) do
	readout("DISP_FUEL_"..t, efm("EFM_FUEL_"..t.."_LB"), FUEL_PERIOD, 10)
end

readout("DISP_BATT_V", efm("EFM_BATT_V"), ENGINE_PERIOD, 0.1, 0.2)
readout("DISP_JFS_RPM", efm("EFM_JFS_RPM"), ENGINE_PERIOD, 1, 0.1)

for _, t in ipairs({"FEED_L", "FEED_R", "TANK1", "WING_L", "WING_R", "CFT_L", "CFT_R"}) do
	readout("DISP_FUEL_"..t.."_FRAC", efm("EFM_FUEL_"..t.."_FRAC"), FUEL_PERIOD, 0.01)
end


local FUS = {cap = {}, lb = {}, fr = {}}
for _, t in ipairs({"TANK1", "FEED_L", "FEED_R"}) do
	FUS.lb[t], FUS.fr[t] = param("EFM_FUEL_"..t.."_LB"), param("EFM_FUEL_"..t.."_FRAC")
end
readout("DISP_FUEL_FUS_FRAC", function()
	local lb, cap = 0, 0
	for t, h in pairs(FUS.lb) do
		local l, f = tonumber(h:get()) or 0, tonumber(FUS.fr[t]:get()) or 0
		if f > 0.05 then FUS.cap[t] = l / f end
		lb, cap = lb + l, cap + (FUS.cap[t] or 0)
	end
	return cap > 0 and math.min(1, lb / cap) or 0
end, FUEL_PERIOD, 0.01)


local efm_variant = param("EFM_VARIANT")
readout("DISP_CFT_FITTED", function() return efm_variant:get() == "config_cft" and 1 or 0 end, FUEL_PERIOD, 1)



local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function efm_abs(name)
	local h = param(name)
	return function() return math.abs(num(h)) end
end



local FLAP_DEG = 30
for _, s in ipairs({"AIL_L", "AIL_R", "STAB_L", "STAB_R", "RUD"}) do
	readout("DISP_SURF_"..s, efm_abs("EFM_SURF_"..s), ENGINE_PERIOD, 1, 0.05)
end
do
	local flap = param("EFM_FLAP_POS")
	readout("DISP_FLAP_DEG", function() return num(flap) * FLAP_DEG end, ENGINE_PERIOD, 1, 0.05)
	for _, a in ipairs({{"P", "PITCH"}, {"R", "ROLL"}, {"Y", "YAW"}}) do
		local h = param("EFM_TRIM_"..a[2])
		readout("DISP_TRIM_"..a[1], function() return num(h) * 100 end, ENGINE_PERIOD, 1)
	end
	local da = param("EFM_FBW_DA_TRIM")
	readout("DISP_LAT_ASYM", function() return num(da) end, FUEL_PERIOD, 1, 0.5)
end

do
	local err = param("NAV_ERR_M")
	readout("DISP_PP_ERR_FT", function() return num(err) * M_TO_FT end, FUEL_PERIOD, 1)
end


local CRZ = {MIN_PPH = 500, hours = 0, rng = 0, v = param("DISP_CRZ_V"), h = param("DISP_CRZ_H"), m = param("DISP_CRZ_M"),
	ff_l = param("EFM_FF_L_PPH"), ff_r = param("EFM_FF_R_PPH"), fuel = param("EFM_FUEL_TOTAL_LB"), gs = param("NAV_GS")}
readout("DISP_CRZ_RNG", function() return CRZ.rng end, FUEL_PERIOD, 1, 1.0)
local function update_cruise()
	local ff = num(CRZ.ff_l) + num(CRZ.ff_r)
	local ok = ff > CRZ.MIN_PPH
	CRZ.v:set(ok and 1 or 0)
	if not ok then CRZ.rng = 0 return end
	CRZ.hours = num(CRZ.fuel) / ff
	CRZ.rng = CRZ.hours * num(CRZ.gs)
	local mins = math.floor(CRZ.hours * 60)
	CRZ.h:set(math.floor(mins / 60))
	CRZ.m:set(mins % 60)
end



local ADI_TURN = {STD = 3, AT_STD = 0.10, MAX = 0.28, TAU = 0.3, SLIP_PER_DEG = 0.025, SLIP_MAX = 0.095,
	rate = 0, hdg = nil, x = param("ADI_TURN_X"), slip = param("ADI_SLIP_X"),

	k = param("ADI_K"), j = param("ADI_J"), res = param("ADI_RES")}
dofile(LockOn_Options.script_path.."Displays/adi_geom.lua")
local function update_adi(dt)
	local h = sensor_data.getMagneticHeading() * RAD_TO_DEG
	if ADI_TURN.hdg then
		local r = ((h - ADI_TURN.hdg + 180) % 360 - 180) / dt
		ADI_TURN.rate = ADI_TURN.rate + (r - ADI_TURN.rate) * (1 - math.exp(-dt / ADI_TURN.TAU))
	end
	ADI_TURN.hdg = h
	ADI_TURN.x:set(clamp(ADI_TURN.rate / ADI_TURN.STD * ADI_TURN.AT_STD, -ADI_TURN.MAX, ADI_TURN.MAX))
	ADI_TURN.slip:set(clamp(beta * ADI_TURN.SLIP_PER_DEG, -ADI_TURN.SLIP_MAX, ADI_TURN.SLIP_MAX))
end

local RCD = {on = false, run = 0, p = param("DISP_RCD"),
	MEDIA_S = 4 * 3600}
local DVR = {h = param("DISP_DVR_H"), m = param("DISP_DVR_M"), s = param("DISP_DVR_S"), media = param("DISP_DVR_MEDIA")}
local function update_dvr(dt)
	if RCD.on then RCD.run = math.min(RCD.MEDIA_S, RCD.run + dt) end
	local t = math.floor(RCD.run)
	DVR.h:set(math.floor(t / 3600))
	DVR.m:set(math.floor(t / 60) % 60)
	DVR.s:set(t % 60)
	DVR.media:set(math.floor(100 * (1 - RCD.run / RCD.MEDIA_S) + 0.5))
end






local HYD_PSI = 3000
local HYD_FULL_RPM = 50
local HYD_TAU = 1.0
local efm_rpm = {L = param("EFM_RPM_L"), R = param("EFM_RPM_R")}
local HYD_SYSTEMS = {"PC1", "UTIL", "PC2"}
local hyd, hyd_out, hyd_primed = {}, {}, false
for _, k in ipairs(HYD_SYSTEMS) do
	hyd[k] = 0
	hyd_out[k] = param("HYD_"..k.."_PSI")
	readout("DISP_HYD_"..k, function() return hyd[k] end, ENGINE_PERIOD, 10)
end




local clock_time = get_absolute_model_time or get_model_time
local clock_h, clock_m, clock_s = param("DISP_CLOCK_H"), param("DISP_CLOCK_M"), param("DISP_CLOCK_S")
local function update_clock()
	local t = math.floor(clock_time()) % 86400
	clock_h:set(math.floor(t / 3600))
	clock_m:set(math.floor(t / 60) % 60)
	clock_s:set(t % 60)
end



local efm_systems = param("EFM_SYSTEMS")
local efm_hyd = {PC1 = param("EFM_HYD_PC1"), PC2 = param("EFM_HYD_PC2"), UTIL = param("EFM_HYD_UTIL")}
local function update_hydraulics(dt)
	if efm_systems:get() == 1 then
		for _, k in ipairs(HYD_SYSTEMS) do
			hyd[k] = efm_hyd[k]:get()
			hyd_out[k]:set(hyd[k])
		end
		hyd_primed = true
		return
	end
	local function pump(side) return HYD_PSI * clamp(efm_rpm[side]:get() / HYD_FULL_RPM, 0, 1) end
	local l, r = pump("L"), pump("R")
	local want = {PC1 = l, PC2 = r, UTIL = math.max(l, r)}
	for _, k in ipairs(HYD_SYSTEMS) do
		if hyd_primed then
			hyd[k] = hyd[k] + (want[k] - hyd[k]) * dt / (HYD_TAU + dt)
		else
			hyd[k] = want[k]
		end
		hyd_out[k]:set(hyd[k])
	end
	hyd_primed = true
end








dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Displays/lad_pb.lua")
dofile(LockOn_Options.script_path.."Displays/lad_layouts.lua")
local CYCLE = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local fmt = {}
for n, id in ipairs({1, 2, 8, 5, 6, 7, 4, 3}) do
	fmt[n] = {param = param(string.format("DISP_FMT_W%d", n)), id = id, prev = id,
		x = param(string.format("LAD_W%d_X", n)), y = param(string.format("LAD_W%d_Y", n)),
		sz = param(string.format("LAD_W%d_SZ", n)),
		ex = param(string.format("LAD_W%d_EX", n)), ey = param(string.format("LAD_W%d_EY", n))}
end
local FMT_KEYS = {[device_commands.FmtLeft] = "L", [device_commands.FmtMiddle] = "M", [device_commands.FmtRight] = "R"}
for k in pairs(FMT_KEYS) do dev:listen_command(k) end
dev:listen_command(device_commands.LadLayoutNext)




local LAYOUT = {at = LAD_LAYOUT.START, p = param("LAD_LAYOUT")}
local function layout_publish()
	LAYOUT.p:set(LAYOUT.at)
	for n, w in ipairs(fmt) do
		local cx, cy = LAD_LAYOUT.content(LAYOUT.at, n)
		w.x:set(cx or 0)
		w.y:set(cy or 0)
		w.sz:set(LAD_LAYOUT.class(LAYOUT.at, n))
		local ex, ey = LAD_LAYOUT.extra(LAYOUT.at, n)
		w.ex:set(ex)
		w.ey:set(ey)
	end
end





local function side_window(side)
	local function edge(s)
		local best, bx, by = 1, nil, nil
		for n = 1, LAD_LAYOUT.N_WIN do
			local x0, x1, y0, y1 = LAD_LAYOUT.rect(LAYOUT.at, n)
			if x0 then
				local x = s == "L" and x0 or -x1
				if not bx or x < bx - 1e-6 or (math.abs(x - bx) <= 1e-6 and y1 > by) then best, bx, by = n, x, y1 end
			end
		end
		return best
	end
	if side ~= "M" then return edge(side) end
	local l, r = edge("L"), edge("R")
	local best, bd, by = 1, nil, nil
	for n = 1, LAD_LAYOUT.N_WIN do
		local x0, x1, y0, y1 = LAD_LAYOUT.rect(LAYOUT.at, n)
		if x0 and n ~= l and n ~= r then
			local d = math.abs((x0 + x1) / 2)
			if not bd or d < bd - 1e-6 or (math.abs(d - bd) <= 1e-6 and y1 > by) then best, bd, by = n, d, y1 end
		end
	end
	return best
end









local SOI = {
	HOLD = 1.0,
	at = 1,
	press = {},
	p = param("DISP_SOI"), fmt = param("DISP_SOI_FMT"),
}
local CASTLE = {[device_commands.CastleLeft] = "L", [device_commands.CastleDown] = "M", [device_commands.CastleRight] = "R"}
for c in pairs(CASTLE) do dev:listen_command(c) end
dev:listen_command(device_commands.CastleFwd)

local function soi_publish()
	SOI.p:set(SOI.at)
	SOI.fmt:set(SOI.at == 0 and 0 or fmt[SOI.at].id)
end

local function set_format(i, id)
	local w = fmt[i]
	if id == LAD_MENU_LAYOUT and w.id ~= LAD_MENU_LAYOUT then w.prev = w.id end
	w.id = id
	w.param:set(id)
	soi_publish()
end

local function set_layout(l)
	LAYOUT.at = l
	layout_publish()

	if SOI.at ~= 0 and LAD_LAYOUT.class(l, SOI.at) == 0 then SOI.at = 1 end
	soi_publish()
end


local function next_format(i)
	local at = 0
	for k, id in ipairs(CYCLE) do if id == fmt[i].id then at = k end end
	set_format(i, CYCLE[at % #CYCLE + 1])
end









dofile(LockOn_Options.script_path.."lad_touch_grid.lua")
local TOUCH = {
	DOUBLE = 0.4,
	SHOW = 0.3,
	last_win = nil, last_t = -1, shown_t = nil,
	x = param("LAD_TOUCH_X"), y = param("LAD_TOUCH_Y"), v = param("LAD_TOUCH_V"), win = param("LAD_TOUCH_WIN"),
	wx = param("LAD_TOUCH_WX"), wy = param("LAD_TOUCH_WY"),
}
dev:listen_command(device_commands.LadTouch)








local HSI_PB = {}

local ENG_PB = {}

local AP_PB, AP_FMT = {}, {ID = 32, prev = nil}




local INS_FMT = {ID = 31, PB = {}, cold_win = nil, ins = param("NAV_INS")}


dofile(LockOn_Options.script_path.."Displays/cmd_page.lua")
local CMD_FMT = {PB = {}, n = 0, f = param("CMD_REQ_F"), v = param("CMD_REQ_V"), np = param("CMD_REQ_N")}
CMD_FMT.np:set(0)
function CMD_FMT.request(f, v)
	CMD_FMT.n = CMD_FMT.n + 1
	CMD_FMT.f:set(f)
	CMD_FMT.v:set(v or 0)
	CMD_FMT.np:set(CMD_FMT.n)
end
local SITP_REQ = {n = param("SITP_REQ_N"), f = param("SITP_REQ_F")}
local RDR_PWR_REQ = param("RDR_PWR_REQ")
local ADI = {PT_STEP = 1, PT_MAX = 10, PER_DEG = 0.025,
	pt = 0, src = 1, pt_y = param("ADI_PT_Y"), src_p = param("ADI_SRC")}




dofile(LockOn_Options.script_path.."Displays/sym_colors.lua")
local NVG_TOGGLE = 438
local HUDP = {ID = 28, PB = {}, hud = 1, hmd = 1, hmd_on = true,
	p_hud = param("HUDP_HUD_COL"), p_hmd = param("HUDP_HMD_COL"), p_sw = param("HUDP_HMD_SW"), p_nvg = param("HUDP_NVG"),
	p_night = param("HUDP_NIGHT"), sel_hud = param("HUD_SYM_SEL"), sel_hmd = param("HMD_SYM_SEL"),
	night = param("F15EX_DISP_NIGHT"), nvg = param("NVG_ON"), hmd_off = param("HMD_OFF"),



	brt = {[0] = 1.0, [1] = 0.1}, BRT_STEP = 0.1, BRT_MIN = 0.1, p_brt = param("HUD_BRT")}

local COMM_FMT = {ID = 34, PB = {}}

local LIGHTS_FMT = {ID = 35, PB = {}}

local TF_FMT = {ID = 12, PB = {}, sub = param("NAV_TF_SUB"), freq = param("NAV_TF_FREQ")}

local IFF_FMT = {ID = 21, PB = {}}


local L16_FMT = {ID = 25, PB = {}, filt = 1, src = 1, p_filt = param("L16_FILT"), p_src = param("L16_SRC")}
L16_FMT.p_filt:set(1)
L16_FMT.p_src:set(1)
L16_FMT.PB[1] = function() L16_FMT.filt = L16_FMT.filt % 4 + 1 L16_FMT.p_filt:set(L16_FMT.filt) end
L16_FMT.PB[2] = function() L16_FMT.src = L16_FMT.src % 4 + 1 L16_FMT.p_src:set(L16_FMT.src) end
L16_FMT.PB[15] = function(win) set_format(win, 5) end











































































































































































local function window_button(win, pb)
	local id = fmt[win].id

	if pb == LAD_PB_LAYOUT then
		set_format(win, id == LAD_MENU_LAYOUT and fmt[win].prev or LAD_MENU_LAYOUT)
		return true
	end
	if id == LAD_MENU_LAYOUT then return false end
	if id == LAD_MENU1 or id == LAD_MENU2 then
		local it = (id == LAD_MENU1 and LAD_MENU1_ITEMS or LAD_MENU2_ITEMS)[pb]
		if it then set_format(win, it[2]) end
		return it ~= nil
	end
	if pb == LAD_PB_MENU then
		set_format(win, LAD_MENU1)
		return true
	end
	if pb == LAD_PB_RCD then
		RCD.on = not RCD.on
		RCD.p:set(RCD.on and 1 or 0)
		return true
	end



















	if id == 7 then
		if pb == 2 or pb == 3 then
			ADI.pt = math.max(-ADI.PT_MAX, math.min(ADI.PT_MAX, ADI.pt + (pb == 2 and 1 or -1) * ADI.PT_STEP))
			ADI.pt_y:set(ADI.pt * ADI.PER_DEG)
			return true
		elseif pb == 5 then
			ADI.src = ADI.src % 2 + 1
			ADI.src_p:set(ADI.src)
			return true
		end
	end
		if id == 6 and HSI_PB[pb] then
		HSI_PB[pb](win)
		return true
	end
	if id == 4 and ENG_PB[pb] then
		ENG_PB[pb](win)
		return true
	end
	if id == AP_FMT.ID and AP_PB[pb] then
		AP_PB[pb](win)
		return true
	end
	if id == LIGHTS_FMT.ID and LIGHTS_FMT.PB[pb] then
		LIGHTS_FMT.PB[pb](win)
		return true
	end
	if id == TF_FMT.ID and TF_FMT.PB[pb] then
		TF_FMT.PB[pb](win)
		return true
	end
	if id == IFF_FMT.ID and IFF_FMT.PB[pb] then
		IFF_FMT.PB[pb](win)
		return true
	end
	if id == L16_FMT.ID and L16_FMT.PB[pb] then
		L16_FMT.PB[pb](win)
		return true
	end
	if id == COMM_FMT.ID and COMM_FMT.PB[pb] then
		COMM_FMT.PB[pb](win)
		return true
	end
	if id == HUDP.ID and HUDP.PB[pb] then
		HUDP.PB[pb](win)
		return true
	end
	if id == INS_FMT.ID and INS_FMT.PB[pb] then
		INS_FMT.PB[pb](win)
		return true
	end

	if id == 3 and pb == CMD_PAGE.PB_EWP then
		set_format(win, CMD_PAGE.ID)
		return true
	end
	if id == CMD_PAGE.ID and CMD_FMT.PB[pb] then
		CMD_FMT.PB[pb](win)
		return true
	end


	if id == 5 and (pb == 1 or pb == 2 or pb == 4 or pb == 13 or pb == 14) then
		SITP_REQ.f:set(pb)
		SITP_REQ.n:set(num(SITP_REQ.n) + 1)
		return true
	end


	if id == 1 and pb == 7 then
		RDR_PWR_REQ:set(num(RDR_PWR_REQ) + 1)
		return true
	end
	return false
end









dofile(LockOn_Options.script_path.."Displays/lad_strip.lua")
local REQ = {TIMEOUT = 0.5, q = {}, n = 0, sent = nil,
	f = param("NAV_REQ_F"), v = param("NAV_REQ_V"), np = param("NAV_REQ_N"), ack = param("NAV_REQ_ACK"),
	ok = param("NAV_REQ_OK"), mc = param("WARN_MC_REQ"), mc_n = 0}
local RREQ = {r = param("RADIO_REQ_R"), v = param("RADIO_REQ_V"), np = param("RADIO_REQ_N"), ack = param("RADIO_REQ_ACK"),
	ok = param("RADIO_REQ_OK")}
local function nav_request(f, v, from_keypad)
	REQ.q[#REQ.q + 1] = {f = f, v = v or 0, kp = from_keypad}
end
local function radio_request(n, v, from_keypad)
	REQ.q[#REQ.q + 1] = {radio = n, v = v or 0, kp = from_keypad}
end








local APREQ = {f = param("AP_REQ_F"), np = param("AP_REQ_N"), n = 0}
APREQ.np:set(0)
local function ap_request(cmd)
	APREQ.n = APREQ.n + 1
	APREQ.f:set(cmd)
	APREQ.np:set(APREQ.n)
end



local KP = {ERR_S = 1.5, field = 1, buf = "", prev = nil, err_t = nil,
	line = param("KP_LINE"), fieldp = param("KP_FIELD"), errv = param("KP_ERR_V"),
	NAMES = {[1] = "TCN", [3] = "ILS", [4] = "CRS", [5] = "STPT", [14] = "HDG", [21] = "R1", [22] = "R2",

		[31] = "CHF", [32] = "FLR", [33] = "SALVOS", [34] = "SLV INT", [35] = "BURSTS", [36] = "BST INT",
		[37] = "AUTO RPT", [38] = "MIN", [39] = "LOCK 0/1", [40] = "LAW", [41] = "BINGO",

		[42] = "M1", [43] = "M2", [44] = "M3",

		[50] = "LAT", [51] = "LONG", [52] = "ELEV",

		[53] = "IMP ANG", [54] = "IMP AZ", [55] = "IMP VEL"}}









local STRIP_SW = {LAW_FIELD = 40, LAW_MIN = 50, LAW_MAX = 20000,
	on = {IFF_ON = true, GCWS_ON = true, LAW_ON = true, HF_ON = false}, law_ft = 500, p = {}}
for k in pairs(STRIP_SW.on) do STRIP_SW.p[k] = param(k) end
STRIP_SW.p.LAW_FT = param("LAW_FT")
function STRIP_SW.publish()
	for k, on in pairs(STRIP_SW.on) do STRIP_SW.p[k]:set(on and 1 or 0) end
	STRIP_SW.p.LAW_FT:set(STRIP_SW.law_ft)
end
function STRIP_SW.toggle(k)
	STRIP_SW.on[k] = not STRIP_SW.on[k]
	STRIP_SW.publish()
end

function STRIP_SW.law_set(ft)
	STRIP_SW.law_ft = math.max(STRIP_SW.LAW_MIN, math.min(STRIP_SW.LAW_MAX, math.floor(ft + 0.5)))
	STRIP_SW.on.LAW_ON = true
	STRIP_SW.publish()
end
STRIP_SW.publish()








local IFF_XP = {IP_S = 18, FIELDS = {[42] = 1, [43] = 2, [44] = 3}, DIGITS = {2, 4, 4},
	code = {0, 0, 0}, on = {M1 = true, M2 = true, M3 = true, MC = true}, m4 = 1, master = 1, ip_t = nil, p = {}}
for _, n in ipairs({"M1", "M2", "M3", "M1_ON", "M2_ON", "M3_ON", "MC_ON", "M4", "MASTER", "IP", "IP_S"}) do
	IFF_XP.p[n] = param("IFF_"..n)
end
function IFF_XP.publish()
	local p = IFF_XP.p
	for m = 1, 3 do p["M"..m]:set(IFF_XP.code[m]) end
	for k, on in pairs(IFF_XP.on) do p[k.."_ON"]:set(on and 1 or 0) end
	p.M4:set(IFF_XP.m4)
	p.MASTER:set(IFF_XP.master)
	local left = IFF_XP.ip_t and math.max(0, IFF_XP.IP_S - (get_model_time() - IFF_XP.ip_t)) or 0
	p.IP:set(left > 0 and 1 or 0)
	p.IP_S:set(math.ceil(left))
end

function IFF_XP.set_code(m, s)
	if not s:match("^[0-7]+$") or #s ~= IFF_XP.DIGITS[m] or (m == 1 and tonumber(s:sub(2, 2)) > 3) then return false end
	IFF_XP.code[m] = tonumber(s)
	IFF_XP.on["M"..m] = true
	IFF_XP.publish()
	return true
end
function IFF_XP.tick()
	if IFF_XP.ip_t then
		if get_model_time() - IFF_XP.ip_t >= IFF_XP.IP_S then IFF_XP.ip_t = nil end
		IFF_XP.publish()
	end
end
IFF_XP.publish()






STRIP_SW.BINGO_FIELD, STRIP_SW.BINGO_STEP, STRIP_SW.LAW_STEP = 41, 500, 100
STRIP_SW.bingo = {v = param("BINGO_REQ_V"), np = param("BINGO_REQ_N"), now = param("DISP_BINGO"), n = 0}
STRIP_SW.bingo.np:set(0)
function STRIP_SW.bingo_set(lb)
	local b = STRIP_SW.bingo
	b.n = b.n + 1
	b.v:set(math.floor(lb + 0.5))
	b.np:set(b.n)
end
function STRIP_SW.bingo_step(d)
	STRIP_SW.bingo_set(num(STRIP_SW.bingo.now) + d * STRIP_SW.BINGO_STEP)
end
function STRIP_SW.law_step(d)
	STRIP_SW.law_set(STRIP_SW.law_ft + d * STRIP_SW.LAW_STEP)
end
local function kp_publish()
	KP.line:set(KP.NAMES[KP.field].." "..KP.buf.."_")
	KP.fieldp:set(KP.field)
	KP.errv:set(KP.err_t and 1 or 0)
end
local function keypad_toggle()
	local w = LAD_LAYOUT.class(LAYOUT.at, 1) > 0 and 1 or math.max(SOI.at, 1)
	if fmt[w].id == LAD_KEYPAD.ID then
		set_format(w, KP.prev or 1)
	else
		KP.prev = fmt[w].id
		KP.buf, KP.err_t = "", nil
		set_format(w, LAD_KEYPAD.ID)
		kp_publish()
	end
	SOI.at = w
	soi_publish()
end
local function keypad_key(k)
	KP.err_t = nil
	if k == "CLR" then
		KP.buf = KP.buf:sub(1, -2)
	elseif k == "ENT" then
		if KP.buf ~= "" then
			local v = tonumber(KP.buf)
			if not v then KP.err_t = get_model_time()
			elseif KP.field == STRIP_SW.LAW_FIELD then STRIP_SW.law_set(v)
			elseif KP.field == STRIP_SW.BINGO_FIELD then STRIP_SW.bingo_set(v)

			elseif IFF_XP.FIELDS[KP.field] then
				if not IFF_XP.set_code(IFF_XP.FIELDS[KP.field], KP.buf) then KP.err_t = get_model_time() end
			elseif KP.field >= 31 then CMD_FMT.request(100 + KP.field - 30, v)
			elseif KP.field >= 21 then radio_request(KP.field - 20, v, true)
			else nav_request(KP.field, v, true) end
			KP.buf = ""
		end
	elseif #KP.buf < (KP.field >= 50 and 10 or LAD_KEYPAD.MAX) and not (k == "." and KP.buf:find(".", 1, true)) then
		KP.buf = KP.buf..k
	end
	kp_publish()
end
local function keypad_button(pb)
	if pb == LAD_KEYPAD.PB_RTN then keypad_toggle() return true end
	local f = LAD_KEYPAD.FIELDS[pb]
	if not f then return false end
	if f[2] == "band" then
		nav_request(2)
	else
		KP.field, KP.buf, KP.err_t = f[2], "", nil
		kp_publish()
	end
	return true
end



HSI_PB[6] = function() nav_request(9, 2) end
HSI_PB[7] = function() nav_request(9, 4) end
HSI_PB[9] = function() nav_request(9, 3) end
HSI_PB[10] = function() nav_request(9, 1) end
HSI_PB[18] = function() nav_request(10) end
HSI_PB[17] = function() nav_request(11, -1) end
HSI_PB[16] = function() nav_request(11, 1) end
local function keypad_field(f)
	local w = LAD_LAYOUT.class(LAYOUT.at, 1) > 0 and 1 or math.max(SOI.at, 1)
	if fmt[w].id ~= LAD_KEYPAD.ID then keypad_toggle() end
	KP.field, KP.buf, KP.err_t = f, "", nil
	kp_publish()
end
HSI_PB[14] = function() keypad_field(4) end






















IFF_XP.auto, IFF_XP.intg_n = 1, 0
IFF_XP.p.AUTO, IFF_XP.p.INTG_N = param("IFF_AUTO"), param("IFF_INTG_N")
IFF_XP.p.AUTO:set(1)
IFF_XP.p.INTG_N:set(0)
for m = 1, 3 do
	IFF_FMT.PB[m] = function() IFF_XP.on["M"..m] = not IFF_XP.on["M"..m] IFF_XP.publish() end
	IFF_FMT.PB[5 + m] = function() keypad_field(41 + m) end
end
IFF_FMT.PB[4] = function() IFF_XP.m4 = IFF_XP.m4 % 3 + 1 IFF_XP.publish() end
IFF_FMT.PB[5] = function() IFF_XP.on.MC = not IFF_XP.on.MC IFF_XP.publish() end
IFF_FMT.PB[9] = function() IFF_XP.master = IFF_XP.master % 3 + 1 IFF_XP.publish() end
IFF_FMT.PB[10] = function() IFF_XP.ip_t = not IFF_XP.ip_t and get_model_time() or nil IFF_XP.publish() end
IFF_FMT.PB[15] = function() STRIP_SW.toggle("IFF_ON") end
IFF_FMT.PB[14] = function() IFF_XP.auto = IFF_XP.auto % 3 + 1 IFF_XP.p.AUTO:set(IFF_XP.auto) end
IFF_FMT.PB[13] = function() IFF_XP.intg_n = IFF_XP.intg_n + 1 IFF_XP.p.INTG_N:set(IFF_XP.intg_n) end

HSI_PB[2] = function() nav_request(9, 5) end
HSI_PB[8] = function() nav_request(9, 6) end
HSI_PB[19] = function() nav_request(9, 7) end
HSI_PB[1] = function() keypad_field(14) end
HSI_PB[4] = function(win) set_format(win, INS_FMT.ID) end
for pb = 1, 5 do INS_FMT.PB[pb] = function() nav_request(12, pb - 1) end end
INS_FMT.PB[13] = function() nav_request(13) end
INS_FMT.PB[15] = function(win) set_format(win, 6) end
local function ins_tick()
	local w = INS_FMT.cold_win
	if not w then return end
	if fmt[w].id ~= INS_FMT.ID then INS_FMT.cold_win = nil return end
	local v = INS_FMT.ins:get()
	if type(v) == "number" and v > 1.5 then
		set_format(w, 6)
		INS_FMT.cold_win = nil
	end
end

local function radio_tile(f)
	local w = LAD_LAYOUT.class(LAYOUT.at, 1) > 0 and 1 or math.max(SOI.at, 1)
	if fmt[w].id == LAD_KEYPAD.ID and KP.field == f then keypad_toggle() else keypad_field(f) end
end



local function format_tile(F)
	local w = LAD_LAYOUT.class(LAYOUT.at, 1) > 0 and 1 or math.max(SOI.at, 1)
	if fmt[w].id == F.ID then
		set_format(w, F.prev or 1)
	else
		F.prev = fmt[w].id
		set_format(w, F.ID)
	end
	SOI.at = w
	soi_publish()
end
local function ap_toggle() format_tile(AP_FMT) end
AP_PB[1] = function() ap_request(device_commands.ApEngage) end
AP_PB[2] = function() ap_request(device_commands.ApSteer) end
AP_PB[3] = function() ap_request(device_commands.ApAltHold) end
AP_PB[4] = function() keypad_field(14) end
AP_PB[13] = ap_toggle





local VNQ = {q = {}, t = 0, mode = param("NAV_VNAV_MODE"), cmd_v = param("NAV_AP_CMD_V"), clr = param("NAV_TF_CLR"),
	ride = param("NAV_TF_RIDE"), on = param("EFM_AP_ON"), str = param("EFM_AP_SEL_STR"), vnav = param("EFM_AP_SEL_VNAV"),
	CLR = {200, 300, 400, 500, 1000}, STEP_S = 0.1, WAIT_S = 1.5}
local function vn_tick()
	local f = VNQ.q[1]
	if not f then return end
	local t = get_model_time()
	if t < VNQ.t then return end
	local r = f(t)
	if r == "stop" then VNQ.q = {}
	elseif r then table.remove(VNQ.q, 1) VNQ.t = t + VNQ.STEP_S end
end
local function vn_mode() return math.floor(num(VNQ.mode) + 0.5) end
local function vn_one_touch(m, steer_v)
	if vn_mode() == m then
		nav_request(15, 0)
		VNQ.q = {function() if num(VNQ.vnav) > 0.5 then ap_request(device_commands.ApVnav) end return true end}
		return
	end
	if steer_v then nav_request(9, steer_v) end
	nav_request(15, m)
	local t_end = get_model_time() + VNQ.WAIT_S
	VNQ.q = {
		function(t) if vn_mode() == m then return true end return t > t_end and "stop" or false end,
		function() if num(VNQ.str) < 0.5 then ap_request(device_commands.ApSteer) end return true end,
		function() if num(VNQ.vnav) < 0.5 then ap_request(device_commands.ApVnav) end return true end,
		function() if num(VNQ.on) < 0.5 then ap_request(device_commands.ApEngage) end return true end,
	}
end
AP_PB[6] = function() vn_one_touch(1, 6) end
AP_PB[7] = function() vn_one_touch(2, 7) end
AP_PB[8] = function() vn_one_touch(3, num(VNQ.cmd_v) < 0.5 and 6 or nil) end
AP_PB[9] = function()
	local now, nxt = num(VNQ.clr), VNQ.CLR[1]
	for i, c in ipairs(VNQ.CLR) do if c == now then nxt = VNQ.CLR[i % #VNQ.CLR + 1] end end
	nav_request(16, nxt)
end
AP_PB[10] = function() nav_request(17, math.floor(num(VNQ.ride) + 0.5) % 3 + 1) end





TF_FMT.CLR = {[6] = {100, 200, 300, 400, 500, 1000}, [4] = {500, 1000}}
local function tf_cycle(list, now)
	for i, c in ipairs(list) do if c == now then return list[i % #list + 1] end end
	return list[1]
end
TF_FMT.PB[1] = function()
	nav_request(16, tf_cycle(TF_FMT.CLR[math.floor(num(TF_FMT.sub) + 0.5)] or VNQ.CLR, num(VNQ.clr)))
end
TF_FMT.PB[2] = AP_PB[10]
TF_FMT.PB[3] = function() nav_request(18, math.floor(num(TF_FMT.sub) + 0.5) % 6 + 1) end
TF_FMT.PB[4] = function() nav_request(19, math.floor(num(TF_FMT.freq) + 0.5) % 8 + 1) end
TF_FMT.PB[15] = AP_PB[8]
TF_FMT.PB[14] = ap_toggle


local function hudp_publish()
	HUDP.p_hud:set(HUDP.hud)
	HUDP.p_hmd:set(HUDP.hmd)
	HUDP.p_sw:set(HUDP.hmd_on and 2 or 1)
	HUDP.hmd_off:set(HUDP.hmd_on and 0 or 1)
	HUDP.p_brt:set(HUDP.brt[num(HUDP.night) > 0.5 and 1 or 0])
end
local function hudp_tick()
	local night = num(HUDP.night) > 0.5 and 1 or 0
	HUDP.p_brt:set(HUDP.brt[night])
	HUDP.sel_hud:set((HUDP.hud - 1) * 2 + night)
	HUDP.sel_hmd:set((HUDP.hmd - 1) * 2 + night)
	HUDP.p_night:set(night + 1)
	HUDP.p_nvg:set(num(HUDP.nvg) > 0.5 and 2 or 1)
end
HUDP.PB[1] = function() HUDP.hud = HUDP.hud % #SYM_COLORS + 1 hudp_publish() end
HUDP.PB[2] = function() HUDP.hmd = HUDP.hmd % #SYM_COLORS + 1 hudp_publish() end
HUDP.PB[15] = function() HUDP.hmd_on = not HUDP.hmd_on hudp_publish() end
HUDP.PB[14] = function() dispatch_action(nil, NVG_TOGGLE) end
HUDP.PB[13] = function() HUDP.night:set(num(HUDP.night) > 0.5 and 0 or 1) end
local function hudp_brt(d)
	local n = num(HUDP.night) > 0.5 and 1 or 0
	HUDP.brt[n] = math.max(HUDP.BRT_MIN, math.min(1, math.floor((HUDP.brt[n] + d) * 10 + 0.5) / 10))
	hudp_publish()
end
HUDP.PB[3] = function() hudp_brt(HUDP.BRT_STEP) end
HUDP.PB[4] = function() hudp_brt(-HUDP.BRT_STEP) end



for pb, cmd in pairs({[1] = 175, [2] = 518, [3] = 521, [4] = device_commands.LightsFlood, [5] = device_commands.LightsAar,
	[15] = 328, [14] = device_commands.LightsMaster}) do
	LIGHTS_FMT.PB[pb] = function() dispatch_action(nil, cmd, 1) end
end


for pb, cmd in pairs({[1] = device_commands.RadioR1Power, [2] = device_commands.RadioR1Rx, [3] = device_commands.RadioR1Guard,
	[15] = device_commands.RadioR2Power, [14] = device_commands.RadioR2Rx, [13] = device_commands.RadioR2Guard}) do
	COMM_FMT.PB[pb] = function() dispatch_action(nil, cmd, 1) end
end


ENG_PB[1] = function() keypad_field(STRIP_SW.BINGO_FIELD) end
ENG_PB[2] = function() STRIP_SW.bingo_step(1) end
ENG_PB[3] = function() STRIP_SW.bingo_step(-1) end
ENG_PB[15] = function() keypad_field(STRIP_SW.LAW_FIELD) end
ENG_PB[14] = function() STRIP_SW.law_step(1) end
ENG_PB[13] = function() STRIP_SW.law_step(-1) end
ENG_PB[16] = function() STRIP_SW.toggle("LAW_ON") end



local CP = CMD_PAGE
for k, pb in ipairs(CP.PB_PROG) do CMD_FMT.PB[pb] = function() CMD_FMT.request(1, k) end end
CMD_FMT.PB[CP.PB_DFLT] = function() CMD_FMT.request(5) end
CMD_FMT.PB[CP.PB_MODE] = function() CMD_FMT.request(6) end
CMD_FMT.PB[CP.PB_SEL] = function() CMD_FMT.request(7) end
CMD_FMT.PB[CP.PB_DEC] = function() CMD_FMT.request(4) end
CMD_FMT.PB[CP.PB_INC] = function() CMD_FMT.request(3) end
CMD_FMT.PB[CP.PB_DOWN] = function() CMD_FMT.request(8) end
CMD_FMT.PB[CP.PB_UP] = function() CMD_FMT.request(9) end
CMD_FMT.PB[CP.PB_RTN] = function(win) set_format(win, 3) end
CMD_FMT.row = param("CMD_ED_ROW")
CMD_FMT.PB[CP.PB_KEYPAD] = function() keypad_field(30 + math.max(1, math.floor(num(CMD_FMT.row) + 0.5))) end






local STRIP_ACT = {
	CAUTION = function() REQ.mc_n = REQ.mc_n + 1 REQ.mc:set(REQ.mc_n) end,
	TCN = function() nav_request(6) end,
	ILS = function() nav_request(7) end,
	POS = function() nav_request(8) end,
	KEYPAD = keypad_toggle,
	R1 = function() radio_tile(21) end,
	R2 = function() radio_tile(22) end,
	AP = ap_toggle,
	HUD = function() format_tile(HUDP) end,
	IFF =function() STRIP_SW.toggle("IFF_ON") end,
	GCWS = function() STRIP_SW.toggle("GCWS_ON") end,
	LAW = function() STRIP_SW.toggle("LAW_ON") end,
	HF = function() STRIP_SW.toggle("HF_ON") end,
}
local function strip_touch(x)
	local _, key = LAD_STRIP.at(x)
	if key and STRIP_ACT[key] then STRIP_ACT[key]() end
end

local function req_tick()
	local t = get_model_time()
	local s = REQ.sent
	if s then
		local D = s.radio and RREQ or REQ
		local ack = D.ack:get()
		if type(ack) == "number" and ack >= s.n then
			if s.kp and D.ok:get() ~= 1 then KP.err_t = t kp_publish() end
			REQ.sent = nil
		elseif t - s.t > REQ.TIMEOUT then
			REQ.sent = nil
		end
	end
	if not REQ.sent and #REQ.q > 0 then
		local r = table.remove(REQ.q, 1)
		REQ.n = REQ.n + 1
		r.n, r.t = REQ.n, t
		if r.radio then
			RREQ.r:set(r.radio)
			RREQ.v:set(r.v)
			RREQ.np:set(REQ.n)
		else
			REQ.f:set(r.f)
			REQ.v:set(r.v)
			REQ.np:set(REQ.n)
		end
		REQ.sent = r
	end
	if KP.err_t and t - KP.err_t >= KP.ERR_S then
		KP.err_t = nil
		kp_publish()
	end
end

function LAD_touch(x, y)
	local t = get_model_time()
	TOUCH.x:set(x)
	TOUCH.y:set(y)
	TOUCH.v:set(1)
	TOUCH.shown_t = t
	local win = LAD_LAYOUT.window_at(LAYOUT.at, x, y)
	TOUCH.win:set(win or 0)
	if not win then
		TOUCH.wx:set(x)
		TOUCH.wy:set(y)
		TOUCH.last_win = nil
		if y > LAD_TOUCH.STRIP_BOTTOM then strip_touch(x) end
		return
	end


	local cx, cy, half = LAD_LAYOUT.content(LAYOUT.at, win)
	local ex, ey = LAD_LAYOUT.extra(LAYOUT.at, win)
	TOUCH.wx:set((x - cx) / half)
	TOUCH.wy:set((y - cy) / half)
	local wx, wy = LAD_LAYOUT.unband((x - cx) / half, ex / half), LAD_LAYOUT.unband((y - cy) / half, ey / half)
	local pb = LAD_PB.at(wx, wy)


	local entry = fmt[win].id == LAD_MENU_LAYOUT and pb ~= LAD_PB_LAYOUT and LAD_LAYOUT_MENU.at(wx, wy)
	if entry then
		set_format(win, fmt[win].prev)
		set_layout(entry)
		TOUCH.last_win = nil
		if LAD_LAYOUT.class(entry, win) == 0 then return end
	elseif pb and fmt[win].id == LAD_KEYPAD.ID and keypad_button(pb) then
		TOUCH.last_win = nil
	elseif pb and window_button(win, pb) then
		TOUCH.last_win = nil
	elseif not pb and fmt[win].id == CMD_PAGE.ID and CMD_PAGE.row_at(wx, wy) then
		CMD_FMT.request(2, CMD_PAGE.row_at(wx, wy))
		TOUCH.last_win = nil

	elseif fmt[win].id == LAD_KEYPAD.ID then
		local k = not pb and LAD_KEYPAD.at(wx, wy)
		if k then keypad_key(k) end
		TOUCH.last_win = nil
	elseif win == TOUCH.last_win and t - TOUCH.last_t <= TOUCH.DOUBLE + 1e-9 then
		next_format(win)
		TOUCH.last_win = nil
	else
		TOUCH.last_win, TOUCH.last_t = win, t
	end
	SOI.at = win
	soi_publish()
end

local function touch_tick()
	if TOUCH.shown_t and get_model_time() - TOUCH.shown_t >= TOUCH.SHOW - 1e-9 then
		TOUCH.v:set(0)
		TOUCH.shown_t = nil
	end
end


function post_initialize()
	standalone:set(1)
	local ic = LockOn_Options.init_conditions
	if ic and ic.birth_place == "GROUND_COLD" and fmt[5].id == 6 then
		fmt[5].id, fmt[5].prev, INS_FMT.cold_win = INS_FMT.ID, INS_FMT.ID, 5
	end
	for _, w in ipairs(fmt) do w.param:set(w.id) end
	layout_publish()
	soi_publish()
	ADI.src_p:set(ADI.src)
	RCD.p:set(0)
	kp_publish()
	STRIP_SW.publish()
	hudp_publish()
	hudp_tick()
	REQ.np:set(0)
	RREQ.np:set(0)
	RDR_PWR_REQ:set(0)
	REQ.mc:set(0)
end


function SetCommand(command, value)

	if command == device_commands.LadTouch then
		local _, _, x, y = LAD_TOUCH.cell(math.floor(value * LAD_TOUCH.VALUE_SCALE + 0.5))
		if x then LAD_touch(x, y) end
		return
	end
	local side = CASTLE[command]
	if side then
		if value > 0 then
			SOI.press[side] = get_model_time()
		elseif SOI.press[side] ~= nil then
			local short = SOI.press[side] ~= false
			SOI.press[side] = nil
			if short then
				SOI.at = side_window(side)
				soi_publish()
			end
		end
		return
	end
	if value == 0 then return end
	if command == device_commands.CastleFwd then
		SOI.at = 0
		soi_publish()
		return
	end
	if FMT_KEYS[command] then
		next_format(side_window(FMT_KEYS[command]))
	elseif command == device_commands.LadLayoutNext then
		set_layout(LAYOUT.at % #LAD_LAYOUT.LIST + 1)
	end
end


local function soi_tick()
	local t = get_model_time()
	for side, t0 in pairs(SOI.press) do
		if t0 and t - t0 >= SOI.HOLD - 1e-9 then
			SOI.press[side] = false
			next_format(side_window(side))
		end
	end
end


function update()
	lua_time:set(get_model_time())
	vn_tick()
	IFF_XP.tick()

	hud_roll:set(sensor_data.getRoll())
	hud_pitch:set(sensor_data.getPitch() * 1000.0)
	do
		local k, j, res = ADI_BALL.step(sensor_data.getPitch() * 1000.0)
		ADI_TURN.k:set(k)
		ADI_TURN.j:set(j)
		ADI_TURN.res:set(res)
	end

	local valid = clamp((efm_tas:get() - AIR_DATA_MIN_KT) / AIR_DATA_FADE_KT, 0, 1)
	alpha = efm_alpha:get() * valid
	beta = efm_beta:get() * valid


	local vv_a, vv_b = efm_vv_alpha:get() * valid, efm_vv_beta:get() * valid
	local fx, fy = clamp(vv_b / RAD_TO_DEG * 1000.0, -100.0, 100.0), clamp(-vv_a / RAD_TO_DEG * 1000.0, -150.0, 60.0)
	fpm.air = efm_wow:get() == 1 and 0 or math.min(FPM_AIR_FADE, fpm.air + update_time_step)
	local tau = FPM_GROUND_TAU * (1 - fpm.air / FPM_AIR_FADE)
	local k = tau > 0 and (1 - math.exp(-update_time_step / tau)) or 1
	fpm.x, fpm.y = fpm.x + (fx - fpm.x) * k, fpm.y + (fy - fpm.y) * k
	hud_fpm_x:set(fpm.x)
	hud_fpm_y:set(fpm.y)

	local nz = efm_nz:get()
	if efm_wow:get() == 1 then g_peak = 1.0 elseif type(nz) == "number" and nz > g_peak then g_peak = nz end

	update_hydraulics(update_time_step)
	update_cruise()
	update_adi(update_time_step)
	update_dvr(update_time_step)
	update_readouts(update_time_step)
	update_clock()
	soi_tick()
	touch_tick()
	req_tick()
	ins_tick()
	hudp_tick()


end





need_to_be_closed = false
