



































local AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")
dofile(LockOn_Options.script_path.."Displays/hud_glass.lua")

local dev = GetSelf()
local update_time_step = 0.02
make_default_activity(update_time_step)
local sensor_data = get_base_data()

local birth = LockOn_Options.init_conditions and LockOn_Options.init_conditions.birth_place
local M_PER_NM, M_TO_FT, KT_PER_MPS = 1852.0, 3.28084, 1.943844
local TWO_PI = 2 * math.pi
local DATA_PERIOD = 0.05




local INS_OFF, INS_STORE, INS_GC, INS_NAV, INS_IFA = 0, 1, 2, 3, 4
local ALIGN = {
	GC = {time = 240, coarse = 60},
	SH = {time = 40, coarse = 15},
	IFA = {time = 120, coarse = 20},
}
local Q_START = 15.9
local DRIFT_NMH = 0.8
local SH_POS_M, SH_HDG_DEG = 3, 0.5
local GPS_TAU = 20
local GPS_ERR_M = 5
local STILL_KT = 2
local SEQ_RANGE_NM = 1.0
local TCN_MAX_NM = 390
local ILS_MAX_NM = 25
local TAPE_VERT_HOLD = math.rad(85)
local LOC_FULL, GS_FULL, GS_ANGLE = 2.5, 0.7, 3.0
local CMD_K, CMD_MAX = 4, 30


local RTE_LOOK_S, RTE_LOOK_MIN, RTE_LOOK_MAX = 25, 2000, 8000
local RTE_INTERCEPT = math.rad(45)
local RTE_BANK = math.rad(30)
local RTE_LEAD_MIN_NM, RTE_LEAD_MAX_NM = 0.3, 6
local RTE_CDI_NM = 2
local WCA_MIN_GS, WCA_MAX, WCA_K = 40, math.rad(30), 0.03
local VN = dofile(LockOn_Options.script_path.."Systems/vnav.lua")
dofile(LockOn_Options.script_path.."Displays/tf_geom.lua")
local TS = dofile(LockOn_Options.script_path.."Systems/tf_scope.lua")
local VN_COUPLE_S = 3
local BEACON_TACAN, BEACON_VORTAC, BEACON_LOC, BEACON_GS = 4, 5, 16640, 16896

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local function wrap_pi(a) return (a + math.pi) % TWO_PI - math.pi end
local function wrap360(d) d = d % 360 if d < 0 then d = d + 360 end return d end
local function dcs_log(s) if log and log.info then tostring("F15EX NAV "..s) else tostring("F15EX NAV "..s) end end
local function sensor(name)
	local f = sensor_data[name]
	if type(f) ~= "function" then return nil end
	local ok, a, b, c = pcall(f)
	if ok then return a, b, c end
	return nil
end

local IN = {ess = param("EFM_ELEC_ESS"), systems = param("EFM_SYSTEMS"), time = param("EFM_TIME"), wow = param("EFM_WOW"),
	fuel = param("EFM_FUEL_TOTAL_LB"), ff_l = param("EFM_FF_L_PPH"), ff_r = param("EFM_FF_R_PPH"),
	auto = param("EFM_AUTOSTART")}
local clock_time = get_absolute_model_time or get_model_time

local OUT = {}
for _, n in ipairs({"INS", "ALIGN_S", "GPS", "ERR_M", "STPT", "STPT_V", "STPT_N", "STPT_WX", "STPT_WY", "STPT_WY_V", "STPT_WZ", "RNG", "BRG", "ETE_M", "ETE_S", "ETA_H",
		"ETA_M", "FUEL", "GS", "HDG", "HDG_RAD", "BRG_REL", "AUTOSEQ", "STEER", "CRS", "CRS_REL", "CDI", "CDI_V", "TOFROM",
		"TCN_MODE", "TCN_CH", "TCN_BAND", "TCN_V", "TCN_BRG", "TCN_RNG", "TCN_ID", "TCN_REL", "ILS_MODE", "ILS_FREQ",
		"ILS_V", "ILS_GS_V", "ILS_LOC", "ILS_GS", "ILS_CRS", "HSI_RNG", "STRIP_1", "STRIP_2", "INS_TXT", "TCN_TXT",
		"ETE_H", "CMD_HDG", "CMD_REL", "CMD_V", "TCN_X", "TCN_Y", "TCN_PV", "TCN_ETE_V", "TCN_ETE_H", "TCN_ETE_M",
		"TCN_ETE_S", "ILS_SUB", "BE_V", "BE_N", "BE_E", "BE_BRG", "BE_RNG", "BE_REL", "BE_DIST", "DECL",
		"INS_MODE", "INS_Q", "INS_Q_V", "INS_OK", "INS_SH", "ALIGN_TXT", "ALIGN_M", "ALIGN_SS", "HDG_SEL", "AP_CMD_V",
		"AP_CMD_TRUE", "CDI_SHOW", "HDG_TRUE", "AP_FPA_V", "AP_FPA_CMD", "AP_ALT_V", "AP_ALT_CMD_FT", "AP_NZ_V", "AP_NZ_LO",
		"AP_NZ_HI", "VNAV_MODE", "VNAV_L1", "VNAV_L2", "TF_CLR", "TF_RIDE", "TF_RIDE_TXT", "TF_POD", "STPT_GY", "STPT_GY_V"}) do
	OUT[n] = param("NAV_"..n)
end
local SP = {}
for i = 1, NAV_MAX_SP do
	SP[i] = {x = param(string.format("NAV_SP%02d_X", i)), y = param(string.format("NAV_SP%02d_Y", i)),
		v = param(string.format("NAV_SP%02d_V", i)),

		rel = param(string.format("NAV_SP%02d_REL", i)), dist = param(string.format("NAV_SP%02d_DIST", i)),
		ok = param(string.format("NAV_SP%02d_OK", i))}
end
local RL = {}
for k = 1, #NAV_ROSE_LABELS do RL[k] = {x = param(string.format("NAV_RL%02d_X", k)), y = param(string.format("NAV_RL%02d_Y", k))} end

local AP = {}
for _, n in ipairs({"ON", "ROLL", "PITCH", "SEL_ALT", "SEL_STR", "H_REF_FT", "HDG_REF", "THETA_REF", "PHI_REF", "DISC",
		"SEL_VNAV", "FPA_REF", "DISC_WHY"}) do
	AP[n] = param("EFM_AP_"..n)
end
for _, n in ipairs({"TXT", "LINES", "STATUS", "INFO1", "INFO2", "STR_SRC"}) do AP["O_"..n] = param("AP_"..n) end
local HUD = {}
for _, n in ipairs({"SP_X", "SP_Y", "SP_V", "SP_EL", "BRG_X", "LOC_X", "GS_Y", "ILS_V", "GS_V", "TXT", "ETE"}) do HUD[n] = param("HUDNAV_"..n) end
HUD.GEAR = param("EFM_GEAR_POS")
local TAPE = {}
for k = 1, NAV_TAPE_SLOTS do
	TAPE[k] = {x = param(string.format("HUDNAV_T%02d_X", k)), l = param(string.format("HUDNAV_T%02d_L", k)),
		n = param(string.format("HUDNAV_T%02d_N", k))}
end


local ILS_FREQS = {}
for mhz = 108, 111 do
	for _, t in ipairs({1, 3, 5, 7, 9}) do
		ILS_FREQS[#ILS_FREQS + 1] = mhz + t / 10
		ILS_FREQS[#ILS_FREQS + 1] = mhz + t / 10 + 0.05
	end
end




local S = {now = 0, t_data = 0, t_log = 0, ins = 0, align = 0, gps = true, err_n = 0, err_e = 0, drift_dir = nil,
	mode = INS_OFF, kind = nil, q = Q_START, ok = false, store = nil, auto = false, auto_seen = false, nav_q = DRIFT_NMH,
	route = {}, stpt = 1, autoseq = true, last_rng = nil, steer = 1, crs = 0, tcn_mode = 1, tcn_ch = 1, tcn_band = 0,
	ils_mode = 0, ils_i = 1, ils_sub = 1, hsi_i = 3, decl = 0, decl_src = nil, beacons = {}, moving_logged = false,
	hdg_sel = 0, mag_now = 0, ap_disc = 0, ap_status = nil, trk_ref = nil, leg = nil, wca = 0, xtk = nil, vn = VN.new(),
	vn_t = 0, vn_coupled = false, trk_prev = nil, turn = 0, terrain = nil, pod = param("SMS_NAV_POD")}


local NAVX = nil
local function cur_wp() return NAVX and NAVX.cur() or S.route[S.stpt] end
local function on_mark() return NAVX and NAVX.cur() ~= nil end








local function set_steer(n)
	S.steer = n
	if n == 5 then S.trk_ref = nil end
	if n == 6 then S.leg, S.autoseq = nil, true end
end


local function ground(x, z)
	if S.terrain == nil then
		local ok, m = pcall(require, "terrain")
		S.terrain = (ok and type(m) == "table" and type(m.GetHeight) == "function") and m or false
		if not S.terrain then dcs_log("TF: no terrain.GetHeight here") end
	end
	if not S.terrain then return nil end
	local ok, h = pcall(S.terrain.GetHeight, x, z)
	return ok and type(h) == "number" and h or nil
end


local function load_beacons()
	local list = {}
	if type(get_terrain_related_data) ~= "function" then dcs_log("beacons: no get_terrain_related_data") return list end
	local ok, file = pcall(get_terrain_related_data, "beacons")
	if not ok or not file then ok, file = pcall(get_terrain_related_data, "beaconsFile") end
	if not ok or type(file) ~= "string" then dcs_log("beacons: no beacon file for this map") return list end
	local f = loadfile and loadfile(file)
	if not f then dcs_log("beacons: cannot load "..file) return list end
	local env = setmetatable({_ = function(s) return s end}, {__index = _G})
	if setfenv then setfenv(f, env) end
	local ok2, err = pcall(f)
	local t = rawget(env, "beacons") or beacons
	if not ok2 or type(t) ~= "table" then dcs_log("beacons: "..tostring(err)) return list end
	for _, b in ipairs(t) do
		if type(b.position) == "table" and type(b.type) == "number" then
			list[#list + 1] = {type = b.type, channel = b.channel, freq = b.frequency, x = b.position[1], h = b.position[2],
				z = b.position[3], dir = b.direction or 0, id = tostring(b.callsign or ""), name = tostring(b.display_name or "")}
		end
	end
	dcs_log(string.format("beacons: %d from %s", #list, file))
	return list
end

local function tacan_id(s)
	s = s:upper():gsub("[^%u%d ]", "")
	if s == "" then s = "TCN" end
	if tonumber(s) then s = "T"..s end
	return s
end


local function load_route()
	local r = {}
	local ok, wps = pcall(get_mission_route or function() return nil end)
	if ok and type(wps) == "table" then
		for i, w in ipairs(wps) do
			if type(w) == "table" and type(w.x) == "number" and type(w.y) == "number" then
				r[#r + 1] = {n = i - 1, x = w.x, z = w.y, alt = w.alt or 0, agl = w.alt_type == "RADIO"}
			end
		end
	end
	dcs_log(string.format("route: %d steerpoints", #r))
	return r
end


local function own_state()
	local o = {}
	local x, y, z = sensor("getSelfCoordinates")
	o.x, o.y, o.z = x or 0, y or 0, z or 0
	local vx, vy, vz = sensor("getSelfVelocity")
	o.gs = math.sqrt((vx or 0) ^ 2 + (vz or 0) ^ 2)
	o.v = math.sqrt(o.gs ^ 2 + (vy or 0) ^ 2)
	o.gamma = math.atan2(vy or 0, math.max(o.gs, 1))
	o.trk = math.atan2(vz or 0, vx or 0)
	o.mag = sensor("getMagneticHeading") or 0
	o.pitch, o.roll = sensor("getPitch") or 0, sensor("getRoll") or 0

	local h = sensor("getHeading")
	if h then
		local d1, d2 = wrap_pi(h - o.mag), wrap_pi(TWO_PI - h - o.mag)
		local lim = math.rad(25)
		local pick = S.decl_src
		if math.abs(d1) < lim and math.abs(d2) >= lim then pick = 1
		elseif math.abs(d2) < lim and math.abs(d1) >= lim then pick = 2 end
		if pick then
			if pick ~= S.decl_src then
				dcs_log(string.format("declination from %s: %.1f deg (getHeading %.1f, magnetic %.1f)",
					pick == 1 and "getHeading" or "2 pi - getHeading", math.deg(pick == 1 and d1 or d2), math.deg(h), math.deg(o.mag)))
				S.decl_src = pick
			end
			local d = pick == 1 and d1 or d2

			S.decl_n = (S.decl_n or 0) + 1
			S.decl = S.decl + wrap_pi(d - S.decl) * (S.decl_n < 250 and 0.05 or 0.001)


		end
	end
	o.hdg_true = o.mag + S.decl
	return o
end




local function sh_valid(o)
	local s = S.store
	if not s then return false end
	return math.sqrt((o.x - s.x) ^ 2 + (o.z - s.z) ^ 2) <= SH_POS_M and math.abs(wrap_pi(o.mag - s.hdg)) <= math.rad(SH_HDG_DEG)
end

local function start_align(kind, o, why)
	S.kind, S.align, S.q, S.ok = kind, 0, Q_START, false
	S.sh_bad = kind == "SH" and not sh_valid(o)
	dcs_log("INS: "..kind.." alignment "..(why or "started")..(S.sh_bad and ", no valid stored heading (the jet moved)" or ""))
end


local function align_text(airborne)
	if S.ins == 0 then return "NO INS" end
	if S.ins == 2 then return "" end
	local k = S.kind or "GC"
	if k == "SH" and S.sh_bad then return "SH NO HDG" end
	if k == "IFA" and not airborne then return "IFA AIR ONLY" end
	if k == "IFA" and not S.gps then return "IFA NO GPS" end
	if S.ok then return k.." OK" end
	if S.align < ALIGN[k].coarse then return k.." NO TAXI" end
	return string.format("%s %.1f", k, S.q)
end

local function update_ins(o, dt, airborne)
	local powered = num(IN.systems) < 0.5 or num(IN.ess) > 0.5
	if not powered then
		if S.ins ~= 0 then dcs_log("INS: power lost, OFF") end
		S.ins, S.kind, S.ok = 0, nil, false
		return
	end

	local auto = num(IN.auto) > 0.5
	if auto and not S.auto_seen and S.mode == INS_OFF and not airborne then
		S.mode, S.auto = sh_valid(o) and INS_STORE or INS_GC, true
		dcs_log("INS: auto-start selects "..(S.mode == INS_STORE and "STORE" or "GC"))
	end
	S.auto_seen = auto
	if S.mode == INS_OFF then
		if S.ins ~= 0 then dcs_log("INS: OFF") end
		S.ins, S.kind, S.ok = 0, nil, false
		return
	end
	local still = o.gs * KT_PER_MPS <= STILL_KT

	if (S.ins == 2 or S.ok) and not airborne and still then S.store = {x = o.x, z = o.z, hdg = o.mag} end
	if S.ins == 2 then
		if S.mode == INS_NAV then

			if S.gps then
				local k = dt / (GPS_TAU + dt)
				S.err_n, S.err_e = S.err_n * (1 - k), S.err_e * (1 - k)
				local e = math.sqrt(S.err_n ^ 2 + S.err_e ^ 2)
				if e < GPS_ERR_M then S.err_n, S.err_e = S.err_n + 0.01 * dt, S.err_e end
				S.drift_dir = nil
			else
				if not S.drift_dir then S.drift_dir = math.random() * TWO_PI end
				local v = S.nav_q * M_PER_NM / 3600
				S.err_n = S.err_n + v * math.cos(S.drift_dir) * dt
				S.err_e = S.err_e + v * math.sin(S.drift_dir) * dt
			end
			return
		end
		S.ins, S.kind = 1, nil
	end

	local want = (S.mode == INS_STORE and "SH") or (S.mode == INS_GC and "GC") or (S.mode == INS_IFA and "IFA")
		or S.kind or (airborne and "IFA" or "GC")
	if S.ins == 0 then S.ins = 1 S.kind = nil end
	if want ~= S.kind then start_align(want, o) end
	local A = ALIGN[S.kind]
	if S.kind == "IFA" then
		if airborne and S.gps and not S.ok then S.align = S.align + dt end
	elseif not airborne then
		if not still then

			if S.align > 0 or S.ok then start_align(S.kind, o, "restarted: the jet moved") end
		elseif not S.sh_bad and not S.ok then
			S.align = S.align + dt
		end
	end
	if S.align > A.coarse then
		local f = math.min(1, (S.align - A.coarse) / (A.time - A.coarse))
		S.q = DRIFT_NMH * (Q_START / DRIFT_NMH) ^ (1 - f)
	end
	if not S.ok and S.align >= A.time then
		S.ok = true
		dcs_log(string.format("INS: %s OK after %.0f s", S.kind, S.align))
	end
	if S.ok and (S.mode == INS_NAV or S.auto) then
		S.mode, S.ins, S.auto, S.nav_q = INS_NAV, 2, false, S.q
		S.err_n, S.err_e = 0, 0
		dcs_log("INS: NAV ("..S.kind.." alignment)")
	end
end


local function radio_horizon_nm(h1_m, h2_m)
	return math.min(TCN_MAX_NM, 1.23 * (math.sqrt(math.max(0, h1_m) * M_TO_FT) + math.sqrt(math.max(0, h2_m) * M_TO_FT)))
end

local function find_tacan(o)
	if S.tcn_mode == 0 or S.tcn_band ~= 0 then return nil end
	local best, bd = nil, 1e30
	for _, b in ipairs(S.beacons) do
		if (b.type == BEACON_TACAN or b.type == BEACON_VORTAC) and b.channel == S.tcn_ch then
			local d = math.sqrt((b.x - o.x) ^ 2 + (b.z - o.z) ^ 2)
			if d < bd and d / M_PER_NM <= radio_horizon_nm(o.y, b.h + 10) then best, bd = b, d end
		end
	end
	return best
end

local function find_ils(o)
	local f = ILS_FREQS[S.ils_i] * 1e6
	local loc, gs
	for _, b in ipairs(S.beacons) do
		if b.freq and math.abs(b.freq - f) < 1000 then
			local d = math.sqrt((b.x - o.x) ^ 2 + (b.z - o.z) ^ 2) / M_PER_NM
			if d <= ILS_MAX_NM then
				if b.type == BEACON_LOC and (not loc or d < loc.d) then loc = {b = b, d = d} end
				if b.type == BEACON_GS and (not gs or d < gs.d) then gs = {b = b, d = d} end
			end
		end
	end
	return loc and loc.b, gs and gs.b
end

local function nearest(o, test)
	local best, bd = nil, 1e30
	for _, b in ipairs(S.beacons) do
		if test(b) then
			local d = (b.x - o.x) ^ 2 + (b.z - o.z) ^ 2
			if d < bd then best, bd = b, d end
		end
	end
	return best
end


local function mag(true_rad) return wrap360(math.deg(true_rad - S.decl)) end


local function rte_lead(o, w, nxt, brg_true)
	local inbound = brg_true
	if S.leg and S.leg.stpt == S.stpt then
		local ln, le = w.x - S.leg.x, w.z - S.leg.z
		if ln * ln + le * le > 2500 then inbound = math.atan2(le, ln) end
	end
	local turn = math.abs(wrap_pi(math.atan2(nxt.z - w.z, nxt.x - w.x) - inbound))
	local r = o.gs * o.gs / (9.81 * math.tan(RTE_BANK))
	local lead = r * math.tan(math.min(turn, math.rad(120)) / 2)
	return clamp(lead, RTE_LEAD_MIN_NM * M_PER_NM, RTE_LEAD_MAX_NM * M_PER_NM)
end



local function rte_passed(o, w, px, pz, rng, brg_true)
	if S.leg and S.leg.stpt == S.stpt then
		local ln, le = w.x - S.leg.x, w.z - S.leg.z
		local len = math.sqrt(ln * ln + le * le)
		if len > 50 and ((px - S.leg.x) * ln + (pz - S.leg.z) * le) / len >= len then return "abeam" end
	end
	local r = o.gs * o.gs / (9.81 * math.tan(RTE_BANK))
	if rng < 1.2 * r and math.abs(wrap_pi(brg_true - o.trk)) > math.pi / 2 then return "inside the turn radius" end
	return nil
end


local function wp_alt(w)
	if not w or not w.alt or w.alt <= 0 then return nil end
	if w.agl then
		local g = ground(w.x, w.z)
		return g and (g + w.alt) or nil
	end
	return w.alt
end










local TF = {MIN_GS_KT = 100, MEA_OFF = 2 * M_PER_NM, MEA_STEP = 1000, MEA_PAD_FT = 1000, MEA_PERIOD = 20, MEA_AHEAD = 10 * M_PER_NM,
	sc = TS.new(), cmp = VN.new(), freq = 1, mea_t = 1e9, mea_sp = nil, mea = nil, P = {}, col = {}}
TF.warning = {cfg = dofile(LockOn_Options.script_path.."Systems/ground_warning_config.lua"),
    profile = param("GW_MAP_PROFILE"), elapsed = 1e9}
for _, n in ipairs({"STATE", "TXT", "SUB", "FREQ", "RALT", "GS", "MEA", "MEA_V", "CUE", "FLYUP", "FAIL", "ANT"}) do
	TF.P[n] = param("NAV_TF_"..n)
end
for k = 1, TF_SCOPE.N do
	TF.col[k] = {}
	for _, f in ipairs({"SYN", "SYNR", "RAW", "ZCL", "OWL"}) do TF.col[k][f] = param(string.format("NAV_TF_%s_%02d", f, k)) end
end





TF.R = {raw = {}, syn = {}, cr = {}, cs = {}}
for _, n in ipairs({"WANT", "CLR_M", "DIVE_DEG", "SUB", "COLS", "SYN_M", "V", "READY", "GAMMA", "FLYUP", "FAIL", "CLR_FT", "ANT"}) do
	TF.R[n] = param("TFR_"..n)
end
do
	local r = {}
	for k = 1, TF_SCOPE.N do
		r[k] = string.format("%.1f", TF_SCOPE.col_nm(k) * M_PER_NM)
		TF.R.cr[k] = param(string.format("TFR_RAW_%02d", k))
		TF.R.cs[k] = param(string.format("TFR_SYN_%02d", k))
	end
	TF.R.COLS:set(table.concat(r, " "))
	TF.R.SYN_M:set(TF_SCOPE.SYN_NM * M_PER_NM)
end

function TF.read()
	local R = TF.R
	if num(R.V) < 0.5 then return nil end
	local t = {ready = num(R.READY) > 0.5, gamma = math.rad(num(R.GAMMA)), flyup = num(R.FLYUP) > 0.5,
		fail = num(R.FAIL) > 0.5, clr_m = num(R.CLR_FT) >= 0 and num(R.CLR_FT) / M_TO_FT or nil, ant = num(R.ANT)}
	for k = 1, TF_SCOPE.N do
		local a, b = num(R.cr[k]), num(R.cs[k])
		R.raw[k], R.syn[k] = a < 900 and a or nil, b < 900 and b or nil
	end
	t.raw, t.syn = R.raw, R.syn
	return t
end
local function tf_update(o, of, airborne, dt, w)
	local vn, P = S.vn, TF.P
	local pod = num(S.pod) > 0.5
	local powered = num(IN.systems) < 0.5 or num(IN.ess) > 0.5
	local st = not pod and 0 or ((airborne and powered and o.gs * KT_PER_MPS >= TF.MIN_GS_KT) and 2 or 1)
	P.STATE:set(st)
	P.SUB:set(vn.sub)
	local R = TF.R
	R.WANT:set((pod and (st == 2 or vn.mode == VN.TF)) and 1 or 0)
	R.CLR_M:set(VN.clearance_ft(vn) / M_TO_FT)
	R.DIVE_DEG:set(math.deg(VN.ride(vn).dive))
	R.SUB:set(vn.sub)
	P.FREQ:set(TF.freq)
	P.TXT:set(st == 0 and "TF-OFF" or st == 1 and "TF-STBY" or "TF-"..VN.SUBMODES[vn.sub])


	local gw = TF.warning
	gw.elapsed = gw.elapsed + dt
	if st ~= 2 or num(R.V) > 0.5 then
		gw.profile:set("")
		gw.elapsed = 1e9
	elseif gw.elapsed >= gw.cfg.profile_period_s then
		gw.elapsed = 0
		local p = {string.format("%.6f", num(IN.time))}
		for d = gw.cfg.profile_step_m, o.gs * gw.cfg.look_s, gw.cfg.profile_step_m do
			local x, z = VN.ahead(of, d / o.gs)
			local h = ground(x, z)
			if h then p[#p + 1] = string.format("%.2f %.2f %.2f", x, z, h) end
		end
		gw.profile:set(table.concat(p, " "))
	end
	P.GS:set(math.floor(o.gs * KT_PER_MPS + 0.5))
	P.RALT:set(math.floor((sensor("getRadarAltitude") or 0) * M_TO_FT / 10 + 0.5) * 10)

	TF.mea_t = TF.mea_t + dt
	if not pod then
		TF.mea, TF.mea_sp = nil, nil
	elseif TF.mea_t >= TF.MEA_PERIOD or TF.mea_sp ~= (w and w.n or 0) then
		TF.mea_t, TF.mea_sp = 0, w and w.n or 0
		local x1, z1 = o.x + TF.MEA_AHEAD * math.cos(o.trk), o.z + TF.MEA_AHEAD * math.sin(o.trk)
		if w and S.ins == 2 then x1, z1 = w.x, w.z end
		local h = TS.leg_max(o.x, o.z, x1, z1, TF.MEA_OFF, TF.MEA_STEP, ground)
		TF.mea = h and math.ceil((h * M_TO_FT + TF.MEA_PAD_FT) / 100) * 100 or nil
	end
	P.MEA:set(TF.mea or 0)
	P.MEA_V:set(TF.mea and 1 or 0)
	P.FAIL:set(vn.fail_t and 1 or 0)
	local sc = TF.sc
	if st ~= 2 then
		TS.clear(sc)
		P.CUE:set(0)
		P.FLYUP:set(0)
	else
		local c = TF.cmp
		c.clr_i, c.ride = vn.clr_i, vn.ride
		local r = TF.read()
		local g
		if r then
			g, c.flyup = r.ready and r.gamma or o.gamma, r.ready and r.flyup
		else
			g = VN.tf_compute(c, of, dt, ground) or o.gamma
		end
		local cue = math.deg(g - o.gamma) * TF_SCOPE.CUE_K
		P.CUE:set(math.max(-TF_SCOPE.CUE_MAX, math.min(TF_SCOPE.CUE_MAX, cue)))
		P.FLYUP:set((c.flyup or (vn.mode == VN.TF and vn.flyup)) and 1 or 0)
		TS.step(sc, of, VN.clearance_ft(vn) / M_TO_FT, VN.ride(vn), VN.K.tf_flyup_frac, vn.sub, dt, ground, VN.ahead, r)
	end
	P.ANT:set(sc.ant)
	for k = 1, TF_SCOPE.N do
		local h = TF.col[k]
		h.SYN:set(sc.syn[k])
		h.SYNR:set(sc.synr[k])
		h.RAW:set(sc.raw[k])
		h.ZCL:set(sc.zcl[k])
		h.OWL:set(sc.owl[k])
	end
end

local function update_data(o, airborne)
	OUT.INS:set(S.ins)
	local left = (S.ins == 1 and S.kind and not S.ok) and math.max(0, math.ceil(ALIGN[S.kind].time - S.align)) or 0
	OUT.ALIGN_S:set(left)
	OUT.ALIGN_M:set(math.floor(left / 60))
	OUT.ALIGN_SS:set(left % 60)
	OUT.INS_MODE:set(S.mode)
	OUT.INS_OK:set(S.ins == 2 and 2 or (S.ok and 1 or 0))
	OUT.INS_Q:set(S.ins == 2 and S.nav_q or S.q)

	OUT.INS_Q_V:set((S.ins == 2 or (S.ins == 1 and S.kind and S.align >= ALIGN[S.kind].coarse)) and 1 or 0)
	OUT.INS_SH:set(sh_valid(o) and 1 or 0)
	local at = align_text(airborne)
	OUT.ALIGN_TXT:set(at == "" and (S.gps and "NAV GPS" or "NAV INS") or at)
	OUT.GPS:set(S.gps and 1 or 0)
	local err = math.sqrt(S.err_n ^ 2 + S.err_e ^ 2)
	OUT.ERR_M:set(math.floor(err + 0.5))
	OUT.HDG:set(math.floor(wrap360(math.deg(o.mag)) + 0.5) % 360)
	OUT.GS:set(math.floor(o.gs * KT_PER_MPS + 0.5))
	OUT.AUTOSEQ:set(S.autoseq and 1 or 0)
	OUT.STEER:set(S.steer)
	OUT.ILS_SUB:set(S.ils_sub)
	OUT.HSI_RNG:set(NAV_HSI_SCALES[S.hsi_i])
	OUT.INS_TXT:set(S.ins == 0 and "INS OFF" or S.ins == 1 and at or (S.gps and "NAV GPS" or "NAV INS"))


	local nav = S.ins == 2
	local px, pz = o.x + S.err_n, o.z + S.err_e
	local w = cur_wp()
	local brg_true, rng = 0, 0
	if w and nav then
		local dn, de = w.x - px, w.z - pz
		rng = math.sqrt(dn * dn + de * de)
		brg_true = math.atan2(de, dn)

		local seq_ok = S.autoseq and airborne and S.stpt < #S.route and not on_mark()
		local passed = S.steer == 6 and seq_ok and rte_passed(o, w, px, pz, rng, brg_true)
		if S.steer == 6 and seq_ok
				and (passed or rng < rte_lead(o, w, S.route[S.stpt + 1], brg_true)) then
			S.stpt = S.stpt + 1
			S.leg = {stpt = S.stpt, x = w.x, z = w.z}
			dcs_log(string.format("steerpoint %d (RTE %s, %.1f nm from the last)", S.route[S.stpt].n,
				passed or "lead turn", rng / M_PER_NM))
			S.last_rng = nil
			return update_data(o, airborne)
		end

		if seq_ok and S.last_rng and rng < SEQ_RANGE_NM * M_PER_NM and rng > S.last_rng then
			S.stpt = S.stpt + 1
			S.leg = {stpt = S.stpt, x = w.x, z = w.z}
			dcs_log(string.format("steerpoint %d (auto)", S.route[S.stpt].n))
			S.last_rng = nil
			return update_data(o, airborne)
		end
		S.last_rng = rng
	end
	OUT.STPT_V:set(w and nav and 1 or 0)
	OUT.STPT:set(w and w.n or 0)
	OUT.STPT_N:set(#S.route)
	OUT.STPT_WX:set(w and w.x or 0)
	OUT.STPT_WZ:set(w and w.z or 0)
	local wy = wp_alt(w)
	OUT.STPT_WY:set(wy or 0)
	OUT.STPT_WY_V:set(wy and 1 or 0)


	if w and not w.gy then
		local t = S.terrain
		if t == nil then
			local ok, m = pcall(require, "terrain")
			t = ok and type(m) == "table" and type(m.GetHeight) == "function" and m or nil
		end
		if t then
			local ok, h = pcall(t.GetHeight, w.x, w.z)
			if ok and type(h) == "number" then w.gy = h end
		end
	end
	OUT.STPT_GY:set(w and w.gy or 0)
	OUT.STPT_GY_V:set((w and w.gy) and 1 or 0)
	OUT.RNG:set(math.floor(rng / M_PER_NM * 10 + 0.5) / 10)
	OUT.BRG:set(math.floor(mag(brg_true) + 0.5) % 360)
	local ete = (w and nav and o.gs > 25) and rng / o.gs or nil
	OUT.ETE_H:set(ete and math.floor(ete / 3600) or 0)
	OUT.ETE_M:set(ete and math.floor(ete / 60) % 60 or 0)
	OUT.ETE_S:set(ete and math.floor(ete % 60) or 0)

	HUD.ETE:set(ete and string.format("%02d:%02d:%02d E", num(OUT.ETE_H), num(OUT.ETE_M), num(OUT.ETE_S)) or "--:--:-- E")
	local eta = ete and (math.floor(clock_time()) + ete) % 86400 or 0
	OUT.ETA_H:set(math.floor(eta / 3600))
	OUT.ETA_M:set(math.floor(eta / 60) % 60)
	local ff = num(IN.ff_l) + num(IN.ff_r)
	OUT.FUEL:set(ete and math.floor((num(IN.fuel) - ff * ete / 3600) / 10 + 0.5) * 10 or 0)
	if w and nav then
		OUT.STRIP_1:set(string.format("%03d/%.0f", num(OUT.BRG), rng / M_PER_NM))
		OUT.STRIP_2:set(ete and string.format("ETA %02d:%02d", num(OUT.ETA_H), num(OUT.ETA_M)) or "ETA --:--")
	else
		OUT.STRIP_1:set("---/---")
		OUT.STRIP_2:set("ETA --:--")
	end
	S.brg_rel = w and nav and wrap_pi(brg_true - o.hdg_true) or nil


	local be = S.be and S.be.x and S.be.z and nav
	OUT.BE_V:set(be and 1 or 0)
	if be then
		local bn, bE = px - S.be.x, pz - S.be.z
		local d = math.sqrt(bn * bn + bE * bE)
		OUT.BE_N:set(bn)
		OUT.BE_E:set(bE)
		OUT.BE_BRG:set(math.floor(mag(math.atan2(bE, bn)) + 0.5) % 360)
		OUT.BE_RNG:set(math.floor(d / M_PER_NM + 0.5))
		OUT.BE_DIST:set(d)
		S.be_rel = wrap_pi(math.atan2(-bE, -bn) - o.hdg_true)
	else
		S.be_rel = nil
	end
	OUT.DECL:set(S.decl)
	S.hud_txt = at
	S.sp_rng, S.sp_true = rng, brg_true


	local scale = NAV_HSI_SCALES[S.hsi_i] * M_PER_NM
	for i = 1, NAV_MAX_SP do
		local p = S.route[i]
		local vis = 0
		SP[i].x:set(0)
		SP[i].y:set(0)
		SP[i].ok:set(p and nav and 1 or 0)
		if p and nav then
			local dn, de = p.x - px, p.z - pz
			SP[i].rel:set(wrap_pi(math.atan2(de, dn) - o.hdg_true))
			SP[i].dist:set(math.sqrt(dn * dn + de * de))
			local r = math.sqrt(dn * dn + de * de) / scale * NAV_R
			if r <= NAV_R then
				local b = math.atan2(de, dn) - o.hdg_true
				SP[i].x:set(r * math.sin(b))
				SP[i].y:set(r * math.cos(b))
				vis = (i == S.stpt and not on_mark()) and 2 or 1
			end
		end
		SP[i].v:set(vis)
	end


	local t = find_tacan(o)
	OUT.TCN_MODE:set(S.tcn_mode)
	OUT.TCN_CH:set(S.tcn_ch)
	OUT.TCN_BAND:set(S.tcn_band)
	OUT.TCN_TXT:set(string.format("%d%s", S.tcn_ch, S.tcn_band == 0 and "X" or "Y"))
	OUT.TCN_V:set(t and 1 or 0)
	S.tcn_rel, S.tcn_true = nil, nil
	if t then
		local dn, de = t.x - o.x, t.z - o.z
		local slant = math.sqrt(dn * dn + de * de + (t.h - o.y) ^ 2)
		S.tcn_true = math.atan2(de, dn)
		S.tcn_rel = wrap_pi(S.tcn_true - o.hdg_true)
		OUT.TCN_BRG:set(math.floor(mag(S.tcn_true) + 0.5) % 360)
		OUT.TCN_RNG:set(math.floor(slant / M_PER_NM * 10 + 0.5) / 10)
		OUT.TCN_ID:set(tacan_id(t.id))

		local r = math.sqrt(dn * dn + de * de) / scale * NAV_R
		OUT.TCN_PV:set(r <= NAV_R and 1 or 0)
		OUT.TCN_X:set(r <= NAV_R and r * math.sin(S.tcn_rel) or 0)
		OUT.TCN_Y:set(r <= NAV_R and r * math.cos(S.tcn_rel) or 0)
		local closing = o.gs * math.cos(wrap_pi(S.tcn_true - o.trk))
		local tte = closing > 25 and slant / closing or nil
		OUT.TCN_ETE_V:set(tte and 1 or 0)
		OUT.TCN_ETE_H:set(tte and math.floor(tte / 3600) or 0)
		OUT.TCN_ETE_M:set(tte and math.floor(tte / 60) % 60 or 0)
		OUT.TCN_ETE_S:set(tte and math.floor(tte % 60) or 0)
	else
		OUT.TCN_ID:set("")
		OUT.TCN_PV:set(0)
		OUT.TCN_ETE_V:set(0)
	end


	OUT.ILS_MODE:set(S.ils_mode)
	OUT.ILS_FREQ:set(ILS_FREQS[S.ils_i])
	local loc, gs = nil, nil
	if S.ils_mode == 1 then loc, gs = find_ils(o) end
	S.loc_dev, S.gs_dev, S.loc_crs = nil, nil, nil
	if loc then
		local crs = math.rad(loc.dir + 180)
		local to_loc = math.atan2(loc.z - o.z, loc.x - o.x)
		local dev = wrap_pi(to_loc - crs)
		if math.abs(dev) < math.rad(35) then
			S.loc_dev = clamp(math.deg(dev) / LOC_FULL, -1, 1)
			S.loc_crs = crs
		end
	end
	if gs and S.loc_dev then
		local d = math.sqrt((gs.x - o.x) ^ 2 + (gs.z - o.z) ^ 2)
		local elev = math.deg(math.atan2(o.y - gs.h, d))
		S.gs_dev = clamp((elev - GS_ANGLE) / GS_FULL, -1, 1)
	end
	OUT.ILS_V:set(S.loc_dev and 1 or 0)
	OUT.ILS_GS_V:set(S.gs_dev and 1 or 0)
	OUT.ILS_LOC:set(S.loc_dev or 0)
	OUT.ILS_GS:set(S.gs_dev or 0)
	OUT.ILS_CRS:set(S.loc_crs and math.floor(mag(S.loc_crs) + 0.5) % 360 or 0)




	if o.gs > WCA_MIN_GS then
		S.wca = S.wca + (clamp(wrap_pi(o.hdg_true - o.trk), -WCA_MAX, WCA_MAX) - S.wca) * WCA_K
	end



	local crs_true, dev, tofrom, cmd_true = nil, nil, 1, nil
	S.xtk = nil
	if S.steer == 5 then
		if not S.trk_ref then
			S.trk_ref = o.trk
			dcs_log(string.format("GT: holding ground track %03d", math.floor(mag(o.trk) + 0.5) % 360))
		end
		cmd_true = S.trk_ref + S.wca
	elseif S.steer == 6 and w and nav then

		if not S.leg or S.leg.stpt ~= S.stpt then
			S.leg = {stpt = S.stpt, x = px, z = pz}
			dcs_log(string.format("RTE: leg to steerpoint %d from present position", w.n))
		end
		local ln, le = w.x - S.leg.x, w.z - S.leg.z
		local len = math.sqrt(ln * ln + le * le)
		local trk_des = brg_true
		if len >= 50 then
			local b = math.atan2(le, ln)
			local rn, re = px - S.leg.x, pz - S.leg.z
			local along = (rn * ln + re * le) / len
			local xtk = -rn * math.sin(b) + re * math.cos(b)
			local look = clamp(o.gs * RTE_LOOK_S, RTE_LOOK_MIN, RTE_LOOK_MAX)
			trk_des = b - clamp(math.atan2(xtk, look), -RTE_INTERCEPT, RTE_INTERCEPT)

			if along > len and S.stpt < #S.route then trk_des = brg_true end
			crs_true, dev, S.xtk = b, clamp(-xtk / (RTE_CDI_NM * M_PER_NM), -1, 1), xtk
		end
		cmd_true = trk_des + S.wca
	elseif S.steer == 1 and S.brg_rel then
		crs_true, dev, cmd_true = brg_true, 0, brg_true + S.wca
	elseif S.steer == 2 and S.tcn_true then
		crs_true = math.rad(S.crs) + S.decl


		local d = wrap_pi(S.tcn_true - crs_true)
		tofrom = math.abs(d) <= math.pi / 2 and 1 or -1
		if tofrom < 0 then d = -wrap_pi(d + math.pi) end
		dev = clamp(math.deg(d) / 10, -1, 1)
		cmd_true = crs_true + math.rad(clamp(CMD_K * math.deg(d), -CMD_MAX, CMD_MAX)) + S.wca
	elseif S.steer == 3 and S.loc_dev then
		crs_true, dev = S.loc_crs, S.loc_dev
		cmd_true = crs_true + math.rad(clamp(CMD_K * S.loc_dev * LOC_FULL, -CMD_MAX, CMD_MAX)) + S.wca
	elseif S.steer == 4 then
		cmd_true = math.rad(S.hdg_sel) + S.decl
	end

	OUT.CMD_V:set(cmd_true and 1 or 0)
	OUT.CMD_HDG:set(cmd_true and (math.floor(mag(cmd_true) + 0.5) % 360) or 0)

	OUT.AP_CMD_V:set(cmd_true and 1 or 0)
	OUT.AP_CMD_TRUE:set(cmd_true and wrap360(math.deg(cmd_true)) or 0)
	OUT.HDG_SEL:set(S.hdg_sel)
	S.cmd_rel = cmd_true and wrap_pi(cmd_true - o.hdg_true) or nil
	OUT.CRS:set(S.steer == 2 and S.crs or (crs_true and math.floor(mag(crs_true) + 0.5) % 360 or 0))
	OUT.CDI_V:set(crs_true and 1 or 0)
	OUT.CDI:set(dev and dev * NAV_CDI_FULL or 0)
	OUT.TOFROM:set(tofrom)
	OUT.CDI_SHOW:set((S.steer == 2 or S.steer == 3 or (S.steer == 6 and crs_true)) and 1 or 0)
	OUT.HDG_TRUE:set(wrap360(math.deg(o.hdg_true)))
	S.crs_rel = crs_true and wrap_pi(crs_true - o.hdg_true) or 0



	local ddt = S.data_dt or DATA_PERIOD
	if S.trk_prev and o.gs > 25 then S.turn = S.turn + (wrap_pi(o.trk - S.trk_prev) / ddt - S.turn) * 0.3 end
	S.trk_prev = o.trk
	local pod = num(S.pod) > 0.5
	OUT.TF_POD:set(pod and 1 or 0)
	local vn = S.vn
	if vn.mode ~= 0 then

		local coupled = num(AP.ON) > 0.5 and num(AP.SEL_VNAV) > 0.5
		S.vn_t = S.vn_t + ddt
		if coupled then S.vn_coupled = true end
		if (S.vn_coupled and not coupled) or (not S.vn_coupled and S.vn_t > VN_COUPLE_S) then
			dcs_log(string.format("VNAV %s off (%s)", VN.MODES[vn.mode],
				S.vn_coupled and (num(AP.ON) > 0.5 and "VNAV deselected" or "A/P off") or "the A/P didn't take it"))
			vn.mode = 0
		end
	end
	local was = vn.mode
	local wa = (S.steer == 6 or vn.mode == VN.RTE) and nav and wp_alt(w)
	local of = {x = o.x, z = o.z, h = o.y, v = o.v, gs = o.gs, trk = o.trk, gamma = o.gamma, turn = S.turn}
	local c = VN.step(vn, of, {pod = pod, wp = wa and {alt = wa, dist = rng} or nil, tfr = TF.read()}, ddt, ground)
	tf_update(o, of, airborne, ddt, w)
	if was == VN.TF and vn.mode ~= VN.TF then dcs_log("VNAV TF FAIL ("..vn.why.."): fly-up, then PATH") end
	OUT.AP_FPA_V:set(c.v and 1 or 0)
	OUT.AP_FPA_CMD:set(c.fpa)
	OUT.AP_ALT_V:set(c.alt_v and 1 or 0)
	OUT.AP_ALT_CMD_FT:set(c.alt_ft)
	OUT.AP_NZ_V:set(c.nz_v and 1 or 0)
	OUT.AP_NZ_LO:set(c.nz_lo)
	OUT.AP_NZ_HI:set(c.nz_hi)
	OUT.VNAV_MODE:set(vn.mode)
	OUT.VNAV_L1:set(vn.mode ~= 0 and c.l1 or "VNAV OFF")
	OUT.VNAV_L2:set(c.l2)
	OUT.TF_CLR:set(VN.clearance_ft(vn))
	OUT.TF_RIDE:set(vn.ride)
	OUT.TF_RIDE_TXT:set(VN.ride(vn).name)
	S.vn_cmd = c
end


local function update_frame(o)
	local h = math.rad(wrap360(math.deg(o.mag)))
	OUT.HDG_RAD:set(h)
	for k = 1, #NAV_ROSE_LABELS do
		local a = math.rad(30 * (k - 1)) - h
		RL[k].x:set(NAV_R_LABEL * math.sin(a))
		RL[k].y:set(NAV_R_LABEL * math.cos(a))
	end

	local dh = S.data_hdg and wrap_pi(o.hdg_true - S.data_hdg) or 0
	OUT.BRG_REL:set(S.brg_rel and (S.brg_rel - dh) or 0)
	OUT.TCN_REL:set(S.tcn_rel and (S.tcn_rel - dh) or 0)
	OUT.CRS_REL:set((S.crs_rel or 0) - dh)
	OUT.CMD_REL:set(S.cmd_rel and (S.cmd_rel - dh) or 0)
	OUT.BE_REL:set(S.be_rel and (S.be_rel - dh) or 0)






	local vert = math.abs(o.pitch) > TAPE_VERT_HOLD
	if (S.ins == 2 and not vert) or S.tape_hdg == nil then S.tape_hdg = wrap360(math.deg(o.mag)) end
	for k, t in ipairs(nav_hdg_tape(S.tape_hdg)) do
		TAPE[k].x:set(t.x)
		TAPE[k].l:set(t.kind)
		TAPE[k].n:set(t.label)
	end
	local MR = 1000
	if S.brg_rel and S.sp_rng and S.sp_rng > 50 then
		local w = cur_wp()
		local elev = math.atan2((w.alt or 0) - o.y, S.sp_rng)

		local ang, dir = AA.hud_polar(S.brg_rel - dh, elev, o.pitch, o.roll)
		local edge = AA.glass_r(HUD_STOP_MR, dir, NAV_HUD_EDGE)
		local r = math.min(ang * MR, edge)
		HUD.SP_X:set(r * math.cos(dir))
		HUD.SP_Y:set(r * math.sin(dir))
		HUD.SP_V:set(ang * MR <= edge and 1 or 2)
		HUD.SP_EL:set(elev)
		HUD.BRG_X:set(clamp(math.deg(S.brg_rel - dh) * NAV_HUD_CARET_PER_DEG, -NAV_HUD_CARET, NAV_HUD_CARET))
	else
		HUD.SP_V:set(0)
		HUD.BRG_X:set(0)
	end

	local gear_down = num(HUD.GEAR) > 0.9
	HUD.ILS_V:set(gear_down and S.ils_mode == 1 and S.loc_dev and 1 or 0)
	HUD.GS_V:set(gear_down and S.ils_mode == 1 and S.gs_dev and 1 or 0)
	HUD.LOC_X:set((S.loc_dev or 0) * NAV_HUD_ILS_FULL)
	HUD.GS_Y:set(-(S.gs_dev or 0) * NAV_HUD_ILS_FULL)
	HUD.TXT:set(S.hud_txt or "NO INS")
end




local AP_COUPLED = {"NAV", "TCN", "ILS", "AHDG", "AGT", "RTE"}
local STEER_NAMES = {"NAV", "TCN", "ILS", "HDG", "GT", "RTE"}
local AP_DISC_WHY = {"A/P key", "paddle", "stick", "FBW: CAS off, unpowered or on the wheels", "attitude limits",
	"bad input", "off in the FBW config"}
local function ap_text()
	local on = num(AP.ON) > 0.5
	local roll, pitch = math.floor(num(AP.ROLL) + 0.5), math.floor(num(AP.PITCH) + 0.5)
	local main, lines = "OFF", 2
	if on then
			if pitch == 3 and S.vn.mode ~= 0 then
			main = VN.MODES[S.vn.mode]
		elseif roll == 3 then
			main = AP_COUPLED[S.steer] or "STR"
			if pitch == 2 then lines = 3 end
		elseif pitch == 2 then main = "ALT"
		else main = roll == 1 and "HDG" or "ATT" end
	end
	local status = "A/P "..main..(lines == 3 and "/ALT" or "")
	AP.O_TXT:set(main)
	AP.O_LINES:set(lines)
	AP.O_STATUS:set(status)
	AP.O_STR_SRC:set(STEER_NAMES[S.steer] or "NAV")
	local i1, i2 = "", ""
	if on then
		if pitch == 3 then i1 = string.format("FLY FPA %+.1f", num(AP.FPA_REF))
		elseif pitch == 2 then i1 = string.format("HOLD ALT %d FT", math.floor(num(AP.H_REF_FT) / 10 + 0.5) * 10)
		else i1 = string.format("HOLD PITCH %+.1f", num(AP.THETA_REF)) end
		if roll == 1 then
			i2 = string.format("HOLD HDG %03d", math.floor(wrap360(num(AP.HDG_REF) - math.deg(S.decl)) + 0.5) % 360)
		elseif roll == 2 then
			local b = num(AP.PHI_REF)
			i2 = string.format("HOLD BANK %s%.0f", b < 0 and "L" or "R", math.abs(b))
		elseif S.steer == 5 and S.trk_ref then
			i2 = string.format("HOLD TRK %03d", math.floor(mag(S.trk_ref) + 0.5) % 360)
		elseif S.steer == 6 and S.xtk then
			i2 = string.format("RTE STPT %d XTK %.1f %s", num(OUT.STPT), math.abs(S.xtk) / M_PER_NM, S.xtk > 0 and "R" or "L")
		else
			i2 = string.format("STEER %s %03d", STEER_NAMES[S.steer] or "", num(OUT.CMD_HDG))
		end
	end
	AP.O_INFO1:set(i1)
	AP.O_INFO2:set(i2)
	if status ~= S.ap_status then
		if S.ap_status then dcs_log(status..(i1 ~= "" and (", "..i1..", "..i2) or "")) end
		S.ap_status = status
	end
	local d = num(AP.DISC)
	if d > S.ap_disc then
		dcs_log(string.format("A/P disconnected by itself: %s (%d so far)", AP_DISC_WHY[math.floor(num(AP.DISC_WHY) + 0.5)] or "?", d))
	end
	S.ap_disc = d
end


local C = device_commands
for c = C.NavStptNext, C.NavHsiRange do dev:listen_command(c) end
for c = C.ApEngage, C.NavSteerHdg do dev:listen_command(c) end

dev:listen_command(Keys.BullsX)
dev:listen_command(Keys.BullsZ)



local SOI_RNG = {N = param("SOI_RNG_N"), D = param("SOI_RNG_D"), F = param("SOI_RNG_F"), seen = 0}
local function soi_range()
	local n = num(SOI_RNG.N)
	if n == SOI_RNG.seen then return end
	SOI_RNG.seen = n
	if math.floor(num(SOI_RNG.F) + 0.5) ~= 6 then return end
	S.hsi_i = clamp(S.hsi_i + (num(SOI_RNG.D) < 0 and -1 or 1), 1, #NAV_HSI_SCALES)
	S.t_data = DATA_PERIOD
end













local POS_UPD_NM = 1.0
local REQ = {N = param("NAV_REQ_N"), F = param("NAV_REQ_F"), V = param("NAV_REQ_V"), ACK = param("NAV_REQ_ACK"),
	OK = param("NAV_REQ_OK"), seen = 0}
local function request(f, v, o)
	local function int(lo, hi) return v == math.floor(v) and v >= lo and v <= hi end
	if NAVX then
		local r = NAVX.request(f, v)
		if r ~= nil then return r end
	end
	if f == 1 then
		if not int(1, 126) then return false end
		S.tcn_ch = v
	elseif f == 2 then S.tcn_band = 1 - S.tcn_band
	elseif f == 3 then
		for i, fq in ipairs(ILS_FREQS) do
			if math.abs(fq - v) < 0.006 then S.ils_i = i return true end
		end
		return false
	elseif f == 4 then
		if not int(0, 360) then return false end
		S.crs = v % 360
	elseif f == 5 then
		for i, w in ipairs(S.route) do
			if w.n == v then S.stpt, S.last_rng = i, nil return true end
		end
		return false
	elseif f == 6 then S.tcn_mode = 1 - S.tcn_mode
	elseif f == 7 then
		S.ils_mode = 1 - S.ils_mode
		dcs_log("ILS "..(S.ils_mode == 1 and "ON" or "OFF").." (LAD status strip)")
	elseif f == 9 then


		if not int(1, 7) then return false end
		if v == 5 then S.steer = 4 return true end
		if v == 6 then set_steer(5) return true end
		if v == 7 then set_steer(6) return true end
		S.steer = math.min(v, 3)
		if v >= 3 then
			S.ils_sub, S.ils_mode = v - 2, 1
			dcs_log("ILS ON (HSI steering key "..v..")")
		end
	elseif f == 10 then S.autoseq = not S.autoseq
	elseif f == 11 then

		local i = S.hsi_i + (v > 0 and 1 or -1)
		if i < 1 or i > #NAV_HSI_SCALES then return false end
		S.hsi_i = i
	elseif f == 12 then

		if not int(INS_OFF, INS_IFA) then return false end
		if v ~= S.mode then dcs_log("INS: mode "..({[0] = "OFF", "STORE", "GC", "NAV", "IFA"})[v]) end
		S.mode, S.auto = v, false
	elseif f == 13 then
		S.gps = not S.gps
		dcs_log("GPS aiding "..(S.gps and "ON" or "OFF"))
	elseif f == 14 then


		if not int(0, 360) then return false end
		S.hdg_sel, S.steer = v % 360, 4
	elseif f == 15 then
		if not int(0, 3) then return false end
		local ok, why = VN.engage(S.vn, v, {h = o.y, gamma = o.gamma}, num(S.pod) > 0.5)
		if not ok then dcs_log("VNAV "..VN.MODES[v].." refused: "..why) return false end
		S.vn_t, S.vn_coupled = 0, false
		dcs_log(v == 0 and "VNAV off (A/P format)" or string.format("VNAV %s selected at fpa %+.1f, %.0f ft", VN.MODES[v],
			math.deg(o.gamma), o.y * M_TO_FT))
	elseif f == 16 then
		return VN.set_clearance(S.vn, v)
	elseif f == 17 then
		if not int(1, #VN.RIDES) then return false end
		S.vn.ride = v
	elseif f == 18 then
		if not int(1, #VN.SUBMODES) then return false end
		VN.set_sub(S.vn, v)
		dcs_log(string.format("TF sub-mode %s, clearance %d ft", VN.SUBMODES[v], VN.clearance_ft(S.vn)))
	elseif f == 19 then
		if not int(1, 8) then return false end
		TF.freq = v
	elseif f == 8 then
		local w = cur_wp()
		if S.ins ~= 2 or not w then return false end
		local d = math.sqrt((w.x - o.x) ^ 2 + (w.z - o.z) ^ 2)
		if d > POS_UPD_NM * M_PER_NM then
			dcs_log(string.format("POS UPDATE refused: steerpoint %d is %.1f nm away", w.n, d / M_PER_NM))
			return false
		end
		dcs_log(string.format("POS UPDATE on steerpoint %d: error %.0f m -> %.0f m", w.n,
			math.sqrt(S.err_n ^ 2 + S.err_e ^ 2), d))
		S.err_n, S.err_e = w.x - o.x, w.z - o.z
	else
		return false
	end
	return true
end
local function requests(o)
	local n = num(REQ.N)
	if n == REQ.seen then return end
	REQ.seen = n
	local ok = request(math.floor(num(REQ.F) + 0.5), num(REQ.V), o)
	REQ.OK:set(ok and 1 or 0)
	REQ.ACK:set(n)
	S.t_data = DATA_PERIOD
end

function post_initialize()
	SOI_RNG.seen = num(SOI_RNG.N)
	REQ.seen = num(REQ.N)
	S.now = get_model_time()
	S.route = load_route()
	S.beacons = load_beacons()
	S.stpt = #S.route >= 2 and 2 or 1
	local hot = birth ~= "GROUND_COLD"
	local o = own_state()
	S.mag_now = o.mag
	S.hdg_sel = math.floor(wrap360(math.deg(o.mag)) + 0.5) % 360
	if hot then
		S.mode, S.ins, S.kind, S.ok = INS_NAV, 2, "GC", true
	else
		S.store = {x = o.x, z = o.z, hdg = o.mag}
	end
	local t = nearest(o, function(b) return (b.type == BEACON_TACAN or b.type == BEACON_VORTAC) and type(b.channel) == "number" end)
	if t then S.tcn_ch = t.channel dcs_log(string.format("TACAN preset to the nearest: %d X %s", t.channel, t.id)) end
	local l = nearest(o, function(b) return b.type == BEACON_LOC end)
	if l then
		local best = 1
		for i, f in ipairs(ILS_FREQS) do if math.abs(f * 1e6 - l.freq) < math.abs(ILS_FREQS[best] * 1e6 - l.freq) then best = i end end
		S.ils_i = best
		dcs_log(string.format("ILS preset to the nearest: %.2f %s", ILS_FREQS[best], l.name))
	end
	OUT.TCN_ID:set("")
	AP.O_TXT:set("OFF")
	AP.O_LINES:set(2)
	AP.O_STATUS:set("A/P OFF")
	AP.O_INFO1:set("")
	AP.O_INFO2:set("")
	AP.O_STR_SRC:set("NAV")
	OUT.VNAV_L1:set("VNAV OFF")
	OUT.VNAV_L2:set("")
	OUT.TF_RIDE_TXT:set(VN.ride(S.vn).name)
	OUT.STRIP_1:set("---/---")
	OUT.STRIP_2:set("ETA --:--")
	OUT.INS_TXT:set("INS OFF")
	OUT.ALIGN_TXT:set("NO INS")
	HUD.ETE:set("--:--:-- E")
	HUD.TXT:set("")
	local o2 = own_state()
	update_data(o2, false)
	dcs_log("up, birth "..tostring(birth)..", INS "..S.ins..", mode "..S.mode..(S.store and ", heading stored" or ""))
end

function SetCommand(command, value)
	if command == Keys.BullsX or command == Keys.BullsZ then
		S.be = S.be or {}
		S.be[command == Keys.BullsX and "x" or "z"] = value
		if S.be.x and S.be.z and not S.be.logged then
			S.be.logged = true
			dcs_log(string.format("bullseye x %.0f z %.0f", S.be.x, S.be.z))
		end
		return
	end
	if value == 0 then return end
	if (command == C.NavStptNext or command == C.NavStptPrev) and NAVX then NAVX.clear() end
	if command == C.NavStptNext then
		if #S.route > 0 then S.stpt = S.stpt % #S.route + 1 end
		S.last_rng = nil
	elseif command == C.NavStptPrev then
		if #S.route > 0 then S.stpt = (S.stpt - 2) % #S.route + 1 end
		S.last_rng = nil
	elseif command == C.NavTcnUp then S.tcn_ch = S.tcn_ch % 126 + 1
	elseif command == C.NavTcnDown then S.tcn_ch = (S.tcn_ch - 2) % 126 + 1
	elseif command == C.NavTcnUp10 then S.tcn_ch = (S.tcn_ch + 9) % 126 + 1
	elseif command == C.NavTcnDown10 then S.tcn_ch = (S.tcn_ch - 11) % 126 + 1
	elseif command == C.NavTcnBand then S.tcn_band = 1 - S.tcn_band
	elseif command == C.NavTcnMode then S.tcn_mode = 1 - S.tcn_mode
	elseif command == C.NavIlsUp then S.ils_i = S.ils_i % #ILS_FREQS + 1
	elseif command == C.NavIlsDown then S.ils_i = (S.ils_i - 2) % #ILS_FREQS + 1
	elseif command == C.NavIlsMode then
		S.ils_mode = 1 - S.ils_mode
		dcs_log("ILS "..(S.ils_mode == 1 and "ON" or "OFF").." (key 3070)")
	elseif command == C.NavSteer then set_steer(S.steer % 6 + 1)
	elseif command == C.NavHdgUp then S.hdg_sel = (S.hdg_sel + 1) % 360
	elseif command == C.NavHdgDown then S.hdg_sel = (S.hdg_sel - 1) % 360
	elseif command == C.NavHdgSync then S.hdg_sel = math.floor(wrap360(math.deg(S.mag_now)) + 0.5) % 360
	elseif command == C.NavSteerHdg then S.steer = 4
	elseif command == C.NavCrsUp then S.crs = (S.crs + 1) % 360
	elseif command == C.NavCrsDown then S.crs = (S.crs - 1) % 360
	elseif command == C.NavGps then
		S.gps = not S.gps
		dcs_log("GPS aiding "..(S.gps and "ON" or "OFF"))
	elseif command == C.NavAutoSeq then S.autoseq = not S.autoseq
	elseif command == C.NavHsiRange then S.hsi_i = S.hsi_i % #NAV_HSI_SCALES + 1
	end
	S.t_data = DATA_PERIOD
end

function update()
	local dt = update_time_step
	S.now = get_model_time()
	soi_range()
	local o = own_state()
	S.mag_now = o.mag
	requests(o)
	local airborne = num(IN.wow) < 0.5 and num(IN.time) > 0
	update_ins(o, dt, airborne)
	S.t_data = S.t_data + dt
	if S.t_data >= DATA_PERIOD - 1e-9 then
		S.data_dt = S.t_data
		S.t_data = 0
		update_data(o, airborne)
		ap_text()
		S.data_hdg = o.hdg_true
	end
	update_frame(o)
	S.t_log = S.t_log + dt
	if S.t_log >= 10 then
		S.t_log = 0
		dcs_log(string.format("t=%.0f INS %d (%s, err %.0f m, GPS %s), decl %.1f, stpt %d/%d %.1f nm brg %03d, TCN %s %s %s, ILS %s %.2f loc %s gs %s, steer %d",
			S.now, S.ins, tostring(OUT.INS_TXT:get()), math.sqrt(S.err_n ^ 2 + S.err_e ^ 2), S.gps and "on" or "off",
			math.deg(S.decl), num(OUT.STPT), #S.route, num(OUT.RNG), num(OUT.BRG), S.tcn_mode == 1 and "TR" or "OFF",
			tostring(OUT.TCN_TXT:get()), num(OUT.TCN_V) == 1 and string.format("%s %03d %.1f nm", tostring(OUT.TCN_ID:get()),
			num(OUT.TCN_BRG), num(OUT.TCN_RNG)) or "no station", S.ils_mode == 1 and "ON" or "OFF", ILS_FREQS[S.ils_i],
			S.loc_dev and string.format("%+.2f", S.loc_dev) or "-", S.gs_dev and string.format("%+.2f", S.gs_dev) or "-", S.steer))
		if S.vn.mode ~= 0 and S.vn_cmd then
			local c = S.vn_cmd
			dcs_log(string.format("VNAV %s fpa cmd %+.1f (DLL flies %+.1f, pitch mode %d), now %+.1f, alt %s, nz %s, %.0f ft, turn %.1f deg/s%s",
				VN.MODES[S.vn.mode], c.fpa, num(AP.FPA_REF), num(AP.PITCH), math.deg(o.gamma),
				c.alt_v and string.format("%.0f ft", c.alt_ft) or "-", c.nz_v and string.format("%.1f..%.1f", c.nz_lo, c.nz_hi) or "-",
				o.y * M_TO_FT, math.deg(S.turn), S.vn.tf_clear_m and string.format(", clearance %.0f ft%s",
				S.vn.tf_clear_m * M_TO_FT, S.vn.flyup and " FLY UP" or "") or ""))
		end
	end
end




need_to_be_closed = false
