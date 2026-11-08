





















local HM = dofile(LockOn_Options.script_path.."Systems/hmd_math.lua")
local AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Displays/hud_glass.lua")
dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")

local dev = GetSelf()
local update_time_step = 0.01
make_default_activity(update_time_step)
local sensor_data = get_base_data()

local MR = 1000.0
local HEAD_STALE = 0.5
local FOV_R = 175.0
local SYM_R = 160.0
local LOC_IN, LOC_OUT = 24.0, 80.0
local TRK_MAX = 32
local HMD_TRK = 12
local EXTRAP_MAX = 0.3



local UNBLANK_HOLD = 0.03
local BLANK_MARGIN_HUD = 6.0
local BLANK_MARGIN_EL = 0.5
local LOG_PERIOD = 5.0


local HEAD_LEAD = 0.045
local RATE_WIN = 0.05
local LEAD_MAX = math.rad(12)
local RATE_MAX = math.rad(600)

local STAMP_RATE_WIN = 0.03
local AGE_MAX = 0.25
local LEAD_EXTRA = 0.0






local COCKPIT_MASK = {{0, -5.0}, {9, -5.0}, {10, -7.5}, {14, -9.0}, {19, -10.0}, {20, -12}, {30, -20}, {45, -28},
	{60, -34}, {110, -34}, {125, -28}, {180, -22}}

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function str(h) local v = h:get() return v == nil and "" or tostring(v) end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local function wrap_pi(a) return (a + math.pi) % (2 * math.pi) - math.pi end











local S
local AX
local function sym(id)
	local s = "HMD_"..id
	return {WX = param(s.."_WX"), WY = param(s.."_WY"), WZ = param(s.."_WZ"), WV = param(s.."_WV"), WL = param(s.."_WL")}
end

local function put(h, bx, by, bz, v, l)
	local f, r, u = AX[1], AX[2], AX[3]
	h.WX:set(bx * f[1] + by * r[1] - bz * u[1])
	h.WY:set(bx * f[2] + by * r[2] - bz * u[2])
	h.WZ:set(bx * f[3] + by * r[3] - bz * u[3])
	h.WV:set(v)
	h.WL:set(l or 0)
end
local function unplace(h)
	h.WV:set(0)
	h.WL:set(0)
end

local IN = {tgt_v = param("HUDAA_TGT_V"), bx = param("HUDAA_TGT_BX"), by = param("HUDAA_TGT_BY"), bz = param("HUDAA_TGT_BZ"),
	pwr = param("DISP_PWR_HUD"), dll_ok = param("HMD_DLL_OK"), dll_az = param("HMD_DLL_AZ"), dll_el = param("HMD_DLL_EL"),
	dll_rl = param("HMD_DLL_RL"), dll_seq = param("HMD_DLL_SEQ"), dll_t = param("HMD_DLL_T"), link = param("MSLLINK_STATE"),
	trk_count = param("TRK_COUNT"), dt = param("RDR_DT_TRK"), stamp = param("TRK_STAMP"), tgt_stt = param("HUDAA_TGT_STT"),
	off = param("HMD_OFF"), sp_v = param("HUDNAV_SP_V"), sp_brg = param("NAV_BRG_REL"), sp_el = param("HUDNAV_SP_EL"),
	rt = param("HMD_RT_OK"), tgt_out = param("HMD_TGT_V"), loc_out = param("HMD_LOC_V"), sp_out = param("HMD_SP_V")}
local trk = {}
for i = 1, TRK_MAX do
	trk[i] = {}
	for _, f in ipairs({"NUM", "BRG", "ELEV", "STT", "AZR", "ELR"}) do
		trk[i][f] = param(string.format("TRK_%02d_%s", i, f))
	end
end
local OUT = {}
for _, n in ipairs({"PWR", "DRAW", "BLANK", "HEAD_OK", "SRC", "LOS_HDG", "FRAME", "EXP_AZ", "EXP_EL", "EXP_AGE", "BRG_X",
		"BRG_V"}) do
	OUT[n] = param("HMD_"..n)
end
local TAPE = {}
for k = 1, NAV_TAPE_SLOTS do
	TAPE[k] = {x = param(string.format("HMD_HT%02d_X", k)), l = param(string.format("HMD_HT%02d_L", k)),
		n = param(string.format("HMD_HT%02d_N", k))}
end
local TS = {}
for k = 1, HMD_TRK do
	TS[k] = sym(string.format("T%02d", k))
end



































local SRM = {GIMBAL = math.rad(30),
	IR_GIMBAL = math.rad(90),



	DCS_CAP = 1.0,
	IR_EXTRAP_MAX = 0.5,
	ir_stamp = nil, ir_t0 = 0, ir_clock = nil,
	HOBS = math.rad(90),
	LOG_PERIOD = 0.25,
	t_log = -1e9, cue = false,
	DES_AZ_SIGN = -1,
	TGT_AZ_SIGN = 1,
	on = false, src = "", tone = false, lim = false, ev_t = -1e9, growl = false, tone_on = false, snd = {},



	SOUNDS = {growl = {"Aircrafts/Cockpits/AIM-9X/AIM-9X_Search", "Aircrafts/F15EX/SRM/F15EX_SRM_Growl"},
		tone = {"Aircrafts/Cockpits/AIM-9X/AIM-9X_Track", "Aircrafts/F15EX/SRM/F15EX_SRM_Tone"}},
	p = {fam = param("SMS_FAM"), arm = param("SMS_ARM"), uncage = param("SRM_UNCAGE"), cool = param("SMS_COOL"),
		lock = param("WS_IR_MISSILE_LOCK"), taz = param("WS_IR_MISSILE_TARGET_AZIMUTH"),
		tel = param("WS_IR_MISSILE_TARGET_ELEVATION"), daz = param("WS_IR_MISSILE_SEEKER_DESIRED_AZIMUTH"),
		del = param("WS_IR_MISSILE_SEEKER_DESIRED_ELEVATION"), inrng = param("HUDAA_INRNG"),
		ir_on = param("SRM_IR_ON"), ir_az = param("SRM_IR_AZ"), ir_el = param("SRM_IR_EL"), ir_unc = param("SRM_IR_UNCAGED"),
		ir_lock = param("SRM_IR_LOCK"), ir_lim = param("SRM_IR_LIM"), ir_t = param("SRM_IR_T"),
		ir_range = param("SRM_IR_RANGE"), gimbal = param("SRM_WS_GIMBAL"),
		ir_dx = param("SRM_IR_DX"), ir_dy = param("SRM_IR_DY"), ir_dz = param("SRM_IR_DZ"),
		ir_vx = param("SRM_IR_VX"), ir_vy = param("SRM_IR_VY"), ir_vz = param("SRM_IR_VZ")}}




for _, n in ipairs({"LOS_OK", "LOS_AZ", "LOS_EL", "SKR_TONE", "SKR_LIM", "SKR_BX", "SKR_BY", "SKR_BZ", "SKR_BV"}) do
	OUT[n] = param("HMD_"..n)
end
local SKR = sym("SKR")






local THR_MAX = 8
local THR_FLASH_ON, THR_FLASH_OFF = 0.25, 0.15
local THR = {n = param("HMDT_N"), s = {}, out = {}}
for i = 1, THR_MAX do
	THR.s[i] = {}
	for _, f in ipairs({"AZ", "EL", "SIG", "TXT", "NUM", "CN", "TTI"}) do
		THR.s[i][f] = param(string.format("HMDT_%02d_%s", i, f))
	end
	THR.out[i] = sym(string.format("R%02d", i))
end

S = {now = 0, rt = nil, az = 0, el = 0, roll = 0, t_log = 0, was_src = 0, dll_seq = 0,
	t_dll = -1e9, blank = 0, want = 0, t_want = 0, n_trk = 0, stamp = nil,
	t0 = 0, hdg0 = 0, hist = {}, lead = 0, rate = 0,
	frame = 1 / 60, age = 0, stamped = false, dll_t = 0, dsamp = {}}
local SRC_NAME = {[0] = "none", "the DLL (camera read)", "the DLL, camera far from the jet"}
local BLANK_NAME = {[0] = "shown", "blanked (HUD)", "blanked (cockpit)"}

local function dcs_log(s)
	if log and log.info then tostring("F15EX HMD "..s) else tostring("F15EX HMD "..s) end
end




local NVG_TOGGLE = 438
local NVG = {on = false, p = param("NVG_ON")}


local function mask_el(az_deg)
	local a = math.min(math.abs(az_deg), 180)
	for k = 2, #COCKPIT_MASK do
		local p, q = COCKPIT_MASK[k - 1], COCKPIT_MASK[k]
		if a <= q[1] then return p[2] + (q[2] - p[2]) * (a - p[1]) / (q[1] - p[1]) end
	end
	return COCKPIT_MASK[#COCKPIT_MASK][2]
end

local function inside(poly, x, y)
	local c = false
	local j = #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if (a[2] > y) ~= (b[2] > y) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then c = not c end
		j = i
	end
	return c
end


local function edge_dist(poly, x, y)
	local best = math.huge
	local j = #poly
	for i = 1, #poly do
		local ax, ay, bx, by = poly[j][1], poly[j][2], poly[i][1], poly[i][2]
		local dx, dy = bx - ax, by - ay
		local t = clamp(((x - ax) * dx + (y - ay) * dy) / math.max(dx * dx + dy * dy, 1e-12), 0, 1)
		local ex, ey = ax + t * dx - x, ay + t * dy - y
		best = math.min(best, math.sqrt(ex * ex + ey * ey))
		j = i
	end
	return best
end



local function blank_cause(az, el, cur)
	local bx, by, bz = HM.body_dir(az, el)
	local _, _, x, y, c = HM.to_head(bx, by, bz, 0, 0, 0)
	if c > 0 then
		local px, py = x * MR, y * MR
		if inside(HUD_GLASS_MR, px, py) then return 1 end
		if cur == 1 and edge_dist(HUD_GLASS_MR, px, py) < BLANK_MARGIN_HUD then return 1 end
	end
	local edge = mask_el(math.deg(az))
	if math.deg(el) < edge then return 2 end
	if cur == 2 and math.deg(el) < edge + BLANK_MARGIN_EL then return 2 end
	return 0
end


local function lead_head(az, el, roll)
	local h = S.hist
	h[#h + 1] = {t = S.now, az = az, el = el, roll = roll}
	while #h > 2 and S.now - h[2].t >= RATE_WIN do table.remove(h, 1) end
	local o = h[1]
	local dt = S.now - o.t
	S.lead, S.rate = 0, 0
	if dt < 0.5 * RATE_WIN then return az, el, roll end

	local a, e, r, rate = HM.lead_rotation(o, h[#h], dt, function(rate)
		if rate > RATE_MAX then return nil end
		S.lead = math.min(HEAD_LEAD, LEAD_MAX / math.max(rate, 1e-9))
		return S.lead
	end)
	S.rate = rate
	return a, e, r
end


local function lead_samples(o, s, age)
	local dt = s.t - o.t
	S.rate = 0
	S.lead = 0
	if dt < 0.004 then return s.az, s.el, s.roll end

	local a, e, r, rate = HM.lead_rotation(o, s, dt, function(rate)
		if rate > RATE_MAX then return nil end
		S.lead = math.min(math.max(age, 0) + S.frame + LEAD_EXTRA, LEAD_MAX / math.max(rate, 1e-9))
		return S.lead
	end)
	S.rate = rate
	return a, e, r
end


local function dll_sample(t, az, el, roll)
	local h = S.dsamp
	local p = h[#h]
	if p and t <= p.t then
		S.dsamp = {}
		h, p = S.dsamp, nil
	end
	if p and t - p.t < 0.1 then S.frame = S.frame + 0.1 * ((t - p.t) - S.frame) end
	h[#h + 1] = {t = t, at = S.now, az = az, el = el, roll = roll}
	while #h > 2 and t - h[2].t >= STAMP_RATE_WIN do table.remove(h, 1) end
end


local function lead_dll()
	local h = S.dsamp
	local s = h[#h]
	if not s then return nil end
	local age = S.now - s.at
	S.age = age
	if age > AGE_MAX then return nil end
	return lead_samples(h[1], s, age)
end


local function own_ccw_hdg()
	local v = type(sensor_data.getHeading) == "function" and sensor_data.getHeading() or 0
	return type(v) == "number" and v or 0
end

local TGT = sym("TGT")


local function target()
	if num(IN.tgt_v) < 0.5 then unplace(TGT) return end
	put(TGT, num(IN.bx), num(IN.by), num(IN.bz), 1, 1)
end






















































local SP = sym("SP")
local function steerpoint(pitch, roll, los_brg)
	if num(IN.sp_v) < 0.5 then
		unplace(SP)
		OUT.BRG_V:set(0)
		return
	end
	local brg = num(IN.sp_brg)
	local bx, by, bz = AA.body_vector(brg, num(IN.sp_el), pitch, roll)
	put(SP, bx, by, bz, 1, 2)
	OUT.BRG_X:set(clamp(math.deg(wrap_pi(brg - los_brg)) * NAV_HUD_CARET_PER_DEG, -NAV_HUD_CARET, NAV_HUD_CARET))
	OUT.BRG_V:set(1)
end

































local function tracks(pitch, roll)
	local shown = 0
	if num(IN.link) >= 1 then
		local stamp = num(IN.stamp)
		if stamp ~= S.stamp then S.stamp, S.t0, S.hdg0 = stamp, S.now, own_ccw_hdg() end
		local dtk = clamp(S.now - S.t0, 0, EXTRAP_MAX)
		local dpsi = wrap_pi(own_ccw_hdg() - S.hdg0)
		local dt_num = math.floor(num(IN.dt) + 0.5)
		local n = math.min(math.floor(num(IN.trk_count) + 0.5), TRK_MAX)
		for i = 1, n do
			if shown >= HMD_TRK then break end
			local s = trk[i]
			local number = math.floor(num(s.NUM) + 0.5)
			if number > 0 and number ~= dt_num and num(s.STT) ~= 1 then
				local brg = num(s.BRG) + num(s.AZR) * dtk + dpsi
				local elev = num(s.ELEV) + num(s.ELR) * dtk
				local bx, by, bz = AA.body_vector(brg, elev, pitch, roll)
				shown = shown + 1
				put(TS[shown], bx, by, bz, 1, 0)
			end
		end
	end
	for k = shown + 1, HMD_TRK do unplace(TS[k]) end
	S.n_trk = shown
end



local function threats()
	local n = math.min(math.floor(num(THR.n) + 0.5), THR_MAX)
	local flash = (S.now % (THR_FLASH_ON + THR_FLASH_OFF)) < THR_FLASH_ON
	for i = 1, THR_MAX do
		local s, o = THR.s[i], THR.out[i]
		local sig = i <= n and math.floor(num(s.SIG) + 0.5) or 0
		if sig > 0 then
			local bx, by, bz = HM.body_dir(num(s.AZ), num(s.EL))
			put(o, bx, by, bz, (sig == 3 and not flash) and 0 or sig, sig == 3 and (flash and 1 or 2) or 0)
		else
			unplace(o)
		end
	end
	S.n_thr = n
end













local MSL_MAX = 4
local RWR_SLOTS = 16
local MSL_EXTRAP = 1.2
local MSL_RATE_MAX = math.rad(30)
local MSL_SETTLE = 0.15
local MSL_FLASH_ON, MSL_FLASH_OFF = 0.3, 0.2
local MSL = {n = param("HMDM_N"), s = {}, out = {}, rwr = {}, st = {}, alert = param("TEWS_ALERT")}
for i = 1, MSL_MAX do
	MSL.s[i] = {}
	for _, f in ipairs({"SRC", "AZ", "EL", "TTI"}) do MSL.s[i][f] = param(string.format("HMDM_%02d_%s", i, f)) end
	MSL.out[i] = sym(string.format("M%02d", i))
	MSL.out[i].TTI = param(string.format("HMD_M%02d_TTI", i))
end
for i = 1, RWR_SLOTS do
	MSL.rwr[i] = {}
	for _, f in ipairs({"AZIMUTH", "ELEVATION", "GENERAL_TYPE", "SOURCE"}) do
		MSL.rwr[i][f] = param(string.format("RWR_CONTACT_%02d_%s", i, f))
	end
end
for _, n in ipairs({"MS_V", "MS_TTI", "MFL"}) do OUT[n] = param("HMD_"..n) end


local function msl_raw(s)
	local src = num(s.SRC)
	if src ~= 0 then
		for i = 1, RWR_SLOTS do
			local r = MSL.rwr[i]
			if num(r.SOURCE) == src and math.floor(num(r.GENERAL_TYPE) + 0.5) == 4 then
				return -num(r.AZIMUTH), num(r.ELEVATION)
			end
		end
	end
	return num(s.AZ), num(s.EL)
end


local function msl_track(st, az, el, pitch, roll, ccw)
	if st.az ~= az or st.el ~= el then
		local b, e = HM.level_dir(az, el, pitch, roll)
		local w = b - ccw
		local pw, pe = w, e
		if st.t then
			local dt = S.now - st.t
			local k = math.min(dt, MSL_EXTRAP)
			pw, pe = st.w + st.rw * k + st.cw * math.max(0, 1 - dt / MSL_SETTLE),
				st.e + st.re * k + st.ce * math.max(0, 1 - dt / MSL_SETTLE)
			local rw, re = wrap_pi(w - st.w) / dt, (e - st.e) / dt
			if dt >= 0.05 and dt <= 3 and math.sqrt(rw * rw + re * re) <= MSL_RATE_MAX then
				st.rw, st.re = rw, re
			else
				st.rw, st.re = 0, 0
			end
			if dt > 0 then
				st.dt_sum, st.n_rep = (st.dt_sum or 0) + dt, (st.n_rep or 0) + 1
			end
		else
			st.rw, st.re = 0, 0
		end
		st.cw, st.ce = wrap_pi(pw - w), pe - e
		st.w, st.e, st.t, st.az, st.el = w, e, S.now, az, el
	end
	local dt = S.now - st.t
	local k, f = math.min(dt, MSL_EXTRAP), math.max(0, 1 - dt / MSL_SETTLE)
	return st.w + st.rw * k + st.cw * f + ccw, clamp(st.e + st.re * k + st.ce * f, -math.pi / 2, math.pi / 2)
end

local function missiles(pitch, roll)
	local n = math.min(math.floor(num(MSL.n) + 0.5), MSL_MAX)
	local ccw = own_ccw_hdg()
	local seen = {}
	for i = 1, MSL_MAX do
		local s, o = MSL.s[i], MSL.out[i]
		if i <= n then
			local key = string.format("%.0f", num(s.SRC))
			if key == "0" then key = "slot"..i end
			local st = MSL.st[key]
			if not st then
				st = {first = S.now}
				MSL.st[key] = st
				dcs_log(string.format("H6 missile %s incoming, RWR az %.1f el %.1f deg", key, math.deg(num(s.AZ)), math.deg(num(s.EL))))
			end
			seen[key] = true
			local az, el = msl_raw(s)
			local brg, elev = msl_track(st, az, el, pitch, roll, ccw)
			local bx, by, bz = AA.body_vector(brg, elev, pitch, roll)
			local tti = num(s.TTI)
			o.TTI:set(tti)
			put(o, bx, by, bz, 1, 1)
		else
			unplace(o)
		end
	end
	for key, st in pairs(MSL.st) do
		if not seen[key] then
			dcs_log(string.format("H6 missile %s off the list after %.1f s; RWR reports every %s s", key, S.now - st.first,
				st.n_rep and string.format("%.2f", st.dt_sum / st.n_rep) or "-"))
			MSL.st[key] = nil
		end
	end
	S.n_msl = n
	return n > 0
end

local function hide_world()
	unplace(TGT)
	unplace(SP)
	OUT.BRG_V:set(0)
	for _, t in ipairs(TS) do unplace(t) end
	for _, o in ipairs(THR.out) do unplace(o) end
	for _, o in ipairs(MSL.out) do unplace(o) end
end


local function srm_audio_init()
	if type(create_sound_host) ~= "function" then dcs_log("SRM audio: no create_sound_host here") return end
	local ok, host = pcall(create_sound_host, "F15EX_SRM_AUDIO", "HEADPHONES", 0, 0, 0)
	if not ok or not host then dcs_log("SRM audio: sound host refused: "..tostring(host)) return end
	for k, names in pairs(SRM.SOUNDS) do
		for _, name in ipairs(names) do
			local ok2, s = pcall(host.create_sound, host, name)
			if ok2 and s then
				SRM.snd[k] = s
				dcs_log("SRM audio: "..k.." = "..name)
				break
			end
			dcs_log("SRM audio: "..name.." not created: "..tostring(s))
		end
	end
end


local function srm_sound(k, on)
	local s = SRM.snd[k]
	local flag = k == "growl" and "growl" or "tone_on"
	if not s then return end
	if on then
		if s.play_continue then
			if not SRM[flag] then SRM[flag] = pcall(s.play_continue, s) end
		else
			local ok, p = pcall(s.is_playing, s)
			if not (ok and p) then pcall(s.play_once, s) end
			SRM[flag] = true
		end
	elseif SRM[flag] then
		if s.stop then pcall(s.stop, s) end
		SRM[flag] = false
	end
end

local function body_az_el(bx, by, bz)
	return math.atan2(by, bx), math.atan2(-bz, math.sqrt(bx * bx + by * by))
end




local function ir_target()
	local p = SRM.p
	if num(p.ir_lock) < 0.5 then return nil end
	local stamp = num(p.ir_t)
	if stamp ~= SRM.ir_stamp then SRM.ir_stamp, SRM.ir_t0 = stamp, S.now end
	local age = S.now - stamp
	local clock = age >= -0.005 and age <= SRM.IR_EXTRAP_MAX
	if clock ~= SRM.ir_clock then
		SRM.ir_clock = clock
		dcs_log(string.format("SRM 9X seeker data age %.3f s: %s", age,
			clock and "from its stamp" or "stamp's clock differs, from its arrival"))
	end
	local dt = clamp(clock and age or (S.now - SRM.ir_t0), 0, SRM.IR_EXTRAP_MAX)
	local dx = num(p.ir_dx) + num(p.ir_vx) * dt
	local dy = num(p.ir_dy) + num(p.ir_vy) * dt
	local dz = num(p.ir_dz) + num(p.ir_vz) * dt


	local brg = wrap_pi(math.atan2(dz, dx) + own_ccw_hdg())
	local elev = math.atan2(dy, math.sqrt(dx * dx + dz * dz))
	return AA.body_vector(brg, elev, sensor_data.getPitch(), sensor_data.getRoll())
end


local function seeker(ok)
	local p = SRM.p

	local selected = str(p.fam) == "SRM"
	if not selected or num(p.cool) == 0 then
		if SRM.on then
			SRM.on = false
			p.daz:set(0) p.del:set(0) p.uncage:set(0)
			p.ir_on:set(0) p.ir_unc:set(0)
			unplace(SKR) OUT.SKR_TONE:set(0) OUT.SKR_LIM:set(0) OUT.SKR_BV:set(0)
			srm_sound("growl", false) srm_sound("tone", false)
			dcs_log(selected and "SRM: no 9X left, seeker off" or "SRM: deselected, seeker to the boresight")
			SRM.src, SRM.tone = "", false
		end
		return
	end
	SRM.on = true
	p.ir_on:set(1)
	local ix, iy, iz = ir_target()
	local ir = ix ~= nil

	local tone = num(p.lock) > 0





	local state = num(p.uncage)
	if state < -0.5 and tone then
		state = 1
		p.uncage:set(1)
		dcs_log("SRM: acquired (tone while searching on the HMD)")
	end
	local uncaged = state > 0.5
	if uncaged and not (tone or ir) then
		p.uncage:set(0)
		uncaged = false
		dcs_log("SRM: caged (no tone)")
	end
	local search = state < -0.5 and not uncaged
	p.ir_unc:set(uncaged and 1 or 0)
	local az, el, src



	local rdr = num(IN.tgt_v) > 0.5 and num(IN.tgt_stt) > 0.5
	if uncaged and ir then
		az, el = body_az_el(ix, iy, iz)
		src = "TRACK 9X"
	elseif uncaged then
		az, el, src = SRM.TGT_AZ_SIGN * num(p.taz), num(p.tel), "TRACK"
	elseif search and ok then
		az, el, src = S.az, S.el, "HMD SEARCH"
	elseif search then
		az, el, src = 0, 0, "HMD SEARCH (no head)"
	elseif rdr then
		az, el = body_az_el(num(IN.bx), num(IN.by), num(IN.bz))
		src = "RADAR"
	else
		az, el, src = 0, 0, "BORESIGHT"
	end


	local cue = false
	local rbx, rby, rbz
	if rdr then
		rbx, rby, rbz = num(IN.bx), num(IN.by), num(IN.bz)
		local rl = math.sqrt(rbx * rbx + rby * rby + rbz * rbz)
		cue = not search and rl > 0 and math.acos(clamp(rbx / rl, -1, 1)) <= SRM.HOBS and num(p.inrng) == 1
	end

	p.ir_az:set(az)
	p.ir_el:set(el)

	local function on_gimbal(g, x, y, z)
		if math.acos(clamp(x, -1, 1)) <= g then return x, y, z, false end
		local s = math.sqrt(y * y + z * z)
		local k = math.sin(g) / math.max(s, 1e-9)
		return math.cos(g), y * k, z * k, true
	end
	local ax, ay, az_, lim = on_gimbal(math.min(SRM.IR_GIMBAL, SRM.DCS_CAP), HM.body_dir(az, el))



	local g = num(p.gimbal)
	if not (g > 0.1 and g < 1.6) then g = SRM.GIMBAL end
	g = math.min(g, SRM.DCS_CAP)
	local cx, cy, cz = on_gimbal(g, ax, ay, az_)
	local daz, del = body_az_el(cx, cy, cz)
	p.daz:set(SRM.DES_AZ_SIGN * daz)
	p.del:set(del)





	local bx, by, bz = ax, ay, az_
	if tone then
		local taz, tel = SRM.TGT_AZ_SIGN * num(p.taz), num(p.tel)
		bx, by, bz = HM.body_dir(taz, tel)
		lim = false
	elseif cue then
		bx, by, bz = rbx, rby, rbz
		lim = false
	end
	local shoot = tone



	if ok then put(SKR, bx, by, bz, 1, lim and 1 or 0) else unplace(SKR) end
	OUT.SKR_BX:set(bx) OUT.SKR_BY:set(by) OUT.SKR_BZ:set(bz) OUT.SKR_BV:set(1)
	OUT.SKR_TONE:set(shoot and 1 or 0)
	OUT.SKR_LIM:set(lim and 1 or 0)
	local armed = num(p.arm) == 1
	srm_sound("tone", armed and shoot)
	srm_sound("growl", armed and not shoot)
	if src ~= SRM.src or tone ~= SRM.tone or lim ~= SRM.lim or cue ~= SRM.cue then
		dcs_log(string.format("SRM seeker %s%s%s%s%s, desired az %.1f el %.1f, WS lock %.2f target az %.1f el %.1f%s",
			src, tone and " TONE" or "", ir and " 9X-LOCK" or "", cue and " RADAR-CUED" or "", lim and " LIMIT" or "",
			math.deg(az), math.deg(el), num(p.lock), math.deg(num(p.taz)), math.deg(num(p.tel)),
			uncaged and " (uncaged)" or ""))
		SRM.src, SRM.tone, SRM.lim, SRM.cue = src, tone, lim, cue
	end

	if S.now - SRM.t_log >= SRM.LOG_PERIOD then
		SRM.t_log = S.now
		local raz, rel = 0, 0
		if rdr then raz, rel = body_az_el(rbx, rby, rbz) end
		local iaz, iel = 0, 0
		if ir then iaz, iel = body_az_el(ix, iy, iz) end
		dcs_log(string.format("SRM 4Hz %s desired %.1f/%.1f WS lock %.2f target %.1f/%.1f radar %s%.1f/%.1f cue %d "
			.."9X %s%.1f/%.1f %.1f km lim %d", src, math.deg(az), math.deg(el), num(p.lock), math.deg(num(p.taz)),
			math.deg(num(p.tel)), rdr and "" or "none ", math.deg(raz), math.deg(rel), cue and 1 or 0, ir and "" or "none ",
			math.deg(iaz), math.deg(iel), num(p.ir_range) / 1000, num(p.ir_lim) > 0.5 and 1 or 0))
	end

	if num(p.lock) > 0 and rdr and S.now - SRM.ev_t >= LOG_PERIOD then
		SRM.ev_t = S.now
		local raz, rel = body_az_el(num(IN.bx), num(IN.by), num(IN.bz))
		dcs_log(string.format("SRM evidence: WS target az %.2f el %.2f vs radar az %.2f el %.2f deg (TGT_AZ_SIGN %d)",
			math.deg(num(p.taz)), math.deg(num(p.tel)), math.deg(raz), math.deg(rel), SRM.TGT_AZ_SIGN))
	end
end

function post_initialize()
	srm_audio_init()
	for _, h in pairs(OUT) do h:set(0) end
	for _, t in ipairs(TS) do unplace(t) end
	for _, o in ipairs(THR.out) do unplace(o) end
	for _, o in ipairs(MSL.out) do unplace(o) o.TTI:set(0) end
	unplace(TGT) unplace(SP) unplace(SKR)
	param("HMD_RL_TXT"):set("")
	dcs_log("H11: world symbols placed at render time by F15EX_MslLink.dll (HMD_<id>_W* -> X / Y / V)")
	dev:listen_command(NVG_TOGGLE)
	NVG.p:set(0)
	dcs_log("up (HUD look, measured head lead); head from the DLL's main view read only")
end

function SetCommand(command, value)
	if command == NVG_TOGGLE then
		NVG.on = not NVG.on
		NVG.p:set(NVG.on and 1 or 0)
		dcs_log("NVG toggle: "..(NVG.on and "on" or "off"))
		return
	end
end

function update()
	S.now = get_model_time()



	local off = num(IN.off) > 0.5
	local pwr = num(IN.pwr) > 0.5 and not off
	if off ~= (S.was_off or false) then dcs_log(off and "switched OFF (HUD PROG)" or "switched ON (HUD PROG)") S.was_off = off end
	OUT.PWR:set(pwr and 1 or 0)

	local seq = num(IN.dll_seq)
	if seq ~= S.dll_seq then S.dll_seq = seq S.t_dll = S.now end
	local dll_ok = math.floor(num(IN.dll_ok) + 0.5)
	local src = 0
	if S.now - S.t_dll < HEAD_STALE and (dll_ok == 1 or dll_ok == 2) then
		src = dll_ok
		S.az, S.el, S.roll = num(IN.dll_az), num(IN.dll_el), num(IN.dll_rl)
		local t = num(IN.dll_t)
		if t > 0 and t ~= S.dll_t then
			S.dll_t = t
			dll_sample(t, S.az, S.el, S.roll)
		end
	end

	OUT.EXP_AGE:set(1e6)
	local ok = src > 0 and not off

	if src ~= S.lead_src then S.hist, S.lead_src = {}, src end
	S.stamped = false
	if ok then
		local a, e, r
		if S.dll_t > 0 then a, e, r = lead_dll() end
		if a then
			S.stamped = true
			S.az, S.el, S.roll = a, e, r
			S.hist = {}
		else
			S.az, S.el, S.roll = lead_head(S.az, S.el, S.roll)
		end
	else
		S.hist = {}
	end
	OUT.FRAME:set(S.frame)
	OUT.HEAD_OK:set(ok and 1 or 0)
	OUT.SRC:set(src)
	OUT.LOS_OK:set(ok and 1 or 0)
	OUT.LOS_AZ:set(S.az)
	OUT.LOS_EL:set(S.el)
	if src ~= S.was_src then
		dcs_log(ok and string.format("head: from %s", SRC_NAME[src])
			or string.format("head: none for %.1f s (no DLL read)", HEAD_STALE))
		S.was_src = src
	end



	local want = ok and blank_cause(S.az, S.el, S.blank) or 0
	if want ~= S.want then S.want, S.t_want = want, S.now end
	if S.blank ~= want and (want ~= 0 or S.now - S.t_want >= UNBLANK_HOLD) then
		dcs_log(string.format("%s at az %.1f el %.1f", BLANK_NAME[want], math.deg(S.az), math.deg(S.el)))
		S.blank = want
	end
	OUT.BLANK:set(S.blank)
	OUT.DRAW:set((pwr and S.blank == 0) and 1 or 0)


	local any = num(MSL.n) >= 0.5
	local launch = not any and math.floor(num(MSL.alert) + 0.5) == 1
	OUT.MS_V:set(any and 1 or (launch and 2 or 0))
	OUT.MS_TTI:set(any and num(MSL.s[1].TTI) or -1)
	if launch ~= (S.launch_banner or false) then
		dcs_log(launch and "launch, no active missile: LAUNCH banner on" or "LAUNCH banner off")
		S.launch_banner = launch
	end
	OUT.MFL:set((S.now % (MSL_FLASH_ON + MSL_FLASH_OFF)) < MSL_FLASH_ON and 1 or 0)
	if any ~= (S.any_msl or false) then
		dcs_log(any and "H6 incoming missile: MSL banner on" or "H6 no incoming missile: MSL banner off")
		S.any_msl = any
	end

	local pitch, roll = sensor_data.getPitch(), sensor_data.getRoll()
	AX = {HM.body_axes(-own_ccw_hdg(), pitch, roll)}
	local rt = num(IN.rt) > 0.5
	if rt ~= S.rt then
		dcs_log(rt and "H11: world symbols placed by the DLL at render time" or "H11: world symbols NOT placed (HMD_RT_OK 0): SYM FAIL")
		S.rt = rt
	end
	
	if ok then


		local brg = HM.tape_bearing(S.az, S.el, S.roll, pitch, roll)
		local hdg = math.deg(sensor_data.getMagneticHeading() + brg) % 360
		OUT.LOS_HDG:set(math.floor(hdg + 0.5) % 360)
		for k, t in ipairs(nav_hdg_tape(hdg)) do
			TAPE[k].x:set(t.x)
			TAPE[k].l:set(t.kind)
			TAPE[k].n:set(t.label)
		end
		target()

		steerpoint(pitch, roll, brg)
		tracks(pitch, roll)
		threats()
		missiles(pitch, roll)
	else
		hide_world()



		S.n_trk, S.n_msl = 0, 0
	end
	seeker(ok)
	if S.now - S.t_log >= LOG_PERIOD then
		S.t_log = S.now
		dcs_log(string.format("head src %d dll ok %d seq %d az %.1f el %.1f roll %.1f rate %.0f lead %.3f (%s, age %.3f frame %.3f) | %s | tgt %d loc %d sp %d trk %d msl %d | pitch %.1f roll %.1f",
			src, dll_ok, seq, math.deg(S.az), math.deg(S.el), math.deg(S.roll), math.deg(S.rate), S.lead,
			S.stamped and "measured" or "fixed", S.age, S.frame, BLANK_NAME[S.blank],
			num(IN.tgt_out), num(IN.loc_out), num(IN.sp_out), S.n_trk, S.n_msl or 0, math.deg(pitch), math.deg(roll)))
	end
end




need_to_be_closed = false
