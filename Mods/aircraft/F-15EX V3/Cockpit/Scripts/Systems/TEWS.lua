
















dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Displays/ew_geom.lua")
local CODES = dofile(LockOn_Options.script_path.."Systems/rwr_codes.lua")
local RNG = dofile(LockOn_Options.script_path.."Systems/rwr_range.lua")
local TTI = dofile(LockOn_Options.script_path.."Systems/mws_tti.lua")
local DLINK = dofile(LockOn_Options.script_path.."Systems/datalink.lua").init()

local L16 = dofile(LockOn_Options.script_path.."Systems/link16_page.lua").init(get_param_handle)
local NCTR = dofile(LockOn_Options.script_path.."Systems/nctr_names.lua")

local dev = GetSelf()
local update_time_step = 0.05
make_default_activity(update_time_step)

local sensor_data = get_base_data()
local cmd = device_commands

local POLL_PERIOD = 0.1
local LOG_PERIOD = 1.0
local SUMMARY_PERIOD = 5.0
local REDETECT_GAP = 8.0
local FORGET_AFTER = 60.0
local AIR_MATCH = math.rad(3.0)
local AIR_MATCH_KEEP = math.rad(8.0)
local AIR_MATCH_HOLD = 10.0
local FLASH_ON, FLASH_OFF = 0.15, 0.10
local M_PER_NM = 1852.0
local M_PER_FT = 0.3048
local RAD = 57.29578




local LETHAL = {
	["10"] = 75000, ["11"] = 35000, ["6"] = 24000, ["8"] = 10000, ["13"] = 5000, ["15"] = 12000, S9 = 8000, AA = 2500,
	["2"] = 40000, ["3"] = 25000, ["5"] = 150000, H7 = 12000, HK = 40000, PT = 70000, GP = 3500, VL = 1500, RD = 8000,
	NS = 25000, RA = 7000, Y1 = 100000, ["49"] = 40000, ["48"] = 15000, CT = 10000, N4 = 30000, N3 = 75000, N9 = 75000,
	H2 = 50000, H9 = 100000, H6 = 40000, HS = 10000,
}

local EW_CODES = {EW = true, E2 = true, E3 = true, FC = true, DE = true, ["50"] = true, KJ = true}

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function str(h) local v = h:get() return v == nil and "" or tostring(v) end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local function wrap_pi(a) return (a + math.pi) % (2 * math.pi) - math.pi end


local RWR_FIELDS = {"AZIMUTH", "ELEVATION", "POWER", "SIGNAL", "GENERAL_TYPE", "UNIT_TYPE", "PRIORITY", "SOURCE", "TIME"}
local rwr = {}
for i = 1, TEWS_MAX do
	rwr[i] = {}
	for _, f in ipairs(RWR_FIELDS) do rwr[i][f] = param(string.format("RWR_CONTACT_%02d_%s", i, f)) end
end




local EWT = {MAX = 8, count = param("EWT_COUNT"), s = {}}
for i = 1, EWT.MAX do
	EWT.s[i] = {RANGE = param(string.format("EWT_%02d_RANGE", i)), REL = param(string.format("EWT_%02d_REL", i))}
end
function EWT.publish(list)
	local n = 0
	for _, c in ipairs(list) do
		if (c.gt == 2 or c.gt == 3) and c.quality == RNG.FIXED and n < EWT.MAX then
			n = n + 1
			EWT.s[n].RANGE:set(c.range)
			EWT.s[n].REL:set(c.rel)
		end
	end
	EWT.count:set(n)
end





















local MSL = {v = param("TEWS_MSL_V"), tti = param("TEWS_MSL_TTI"), act = param("TEWS_MSL_ACT"), alert = param("TEWS_ALERT")}




local HMDT = {MAX = 8, n = param("HMDT_N"), s = {}}
local HMDT_F = {"AZ", "EL", "SIG", "TXT", "NUM", "CN", "TTI"}
for i = 1, HMDT.MAX do
	HMDT.s[i] = {}
	for _, f in ipairs(HMDT_F) do HMDT.s[i][f] = param(string.format("HMDT_%02d_%s", i, f)) end
end




local HMDM = {MAX = 4, n = param("HMDM_N"), s = {}}
for i = 1, HMDM.MAX do
	HMDM.s[i] = {}
	for _, f in ipairs({"SRC", "AZ", "EL", "TTI"}) do HMDM.s[i][f] = param(string.format("HMDM_%02d_%s", i, f)) end
end


local TRK_MAX = 32
local trk = {}
for i = 1, TRK_MAX do
	trk[i] = {}
	for _, f in ipairs({"NUM", "RANGE", "BRG", "ELEV", "HDG", "GS", "COAST", "TYPE", "STT", "DL"}) do
		trk[i][f] = param(string.format("TRK_%02d_%s", i, f))
	end
end

local IFFP = {n = param("IFF_N"), num = {}, res = {}}
for i = 1, TRK_MAX do
	IFFP.num[i] = param(string.format("IFF_%02d_NUM", i))
	IFFP.res[i] = param(string.format("IFF_%02d_RES", i))
end
local P = {link = param("MSLLINK_STATE"), trk_count = param("TRK_COUNT"), dt = param("RDR_DT_TRK"),
	own_hdg = param("RDR_OWN_HDG"), alt_ft = param("DISP_ALT_FT"), chf = param("SMS_CHF"), flr = param("SMS_FLR")}






local TEWS_F = {"X", "Y", "V", "TXT", "NUM", "CN", "AIR", "SHIP", "LOCK", "RNG", "TTI", "TTIV"}
local tews = {}
for i = 1, TEWS_MAX do
	tews[i] = {}
	for _, f in ipairs(TEWS_F) do tews[i][f] = param(string.format("TEWS_T%02d_%s", i, f)) end
end
local T = {scale = param("TEWS_SCALE"), n = param("TEWS_N"), fix_n = param("TEWS_FIXES"), rot = param("TEWS_ROSE_ROT"),
	lx = {}, ly = {}}
for k = 1, #TEWS_ROSE_LABELS do
	T.lx[k] = param(string.format("TEWS_ROSE_%02d_X", k))
	T.ly[k] = param(string.format("TEWS_ROSE_%02d_Y", k))
end






local SITP_TF = {"X", "Y", "V", "H", "L", "ALT", "D", "I"}
local SITP_RF = {"X", "Y", "V", "RING", "LOCK", "TXT", "NUM", "CN", "CLR"}
local sitp_t, sitp_r = {}, {}
for i = 1, SITP_MAX_TRK do
	sitp_t[i] = {}
	for _, f in ipairs(SITP_TF) do sitp_t[i][f] = param(string.format("SITP_T%02d_%s", i, f)) end
	sitp_t[i].ID = param(string.format("SITP_T%02d_ID", i))
end
for i = 1, SITP_MAX_THR do
	sitp_r[i] = {}
	for _, f in ipairs(SITP_RF) do sitp_r[i][f] = param(string.format("SITP_R%02d_%s", i, f)) end
end

local SITP_LF = {"X", "Y", "V", "H", "L", "ALT", "D"}
local sitp_l = {}
for i = 1, SITP_MAX_DL do
	sitp_l[i] = {}
	for _, f in ipairs(SITP_LF) do sitp_l[i][f] = param(string.format("SITP_L%02d_%s", i, f)) end
	sitp_l[i].ID = param(string.format("SITP_L%02d_ID", i))
end



local function sitp_id(s)
	if s == nil or s == "UNK" or tonumber(s) then return "" end
	return s
end


local CUR = {dx = param("SITP_CUR_DX"), dy = param("SITP_CUR_DY"), v = param("SITP_CUR_V")}
local DCTR = param("SITP_DCTR")
local SITP_OFF_BASE = SITP_OFF
local HOVER_R = 0.06
local SP = {rng = param("SITP_RNG"), air = param("SITP_AIR"), sam = param("SITP_SAM"), jtid = param("SITP_JTID"),
	rot = param("SITP_ROSE_ROT"), lne = param("SITP_LNE"),


	be_v = param("SITP_BE_V"), be_x = param("SITP_BE_X"), be_y = param("SITP_BE_Y"), beb = param("SITP_BEB"),
	ber = param("SITP_BER"), bev = param("SITP_BEV"),
	dt_b = param("SITP_DT_B"), dt_l = param("SITP_DT_L"), dt_v = param("SITP_DT_V"), lx = {}, ly = {},
	dt_x = param("SITP_DT_X"), dt_y = param("SITP_DT_Y"),

	exp_k = param("SITP_EXP_K"), exp_cx = param("SITP_EXP_CX"), exp_cy = param("SITP_EXP_CY")}



SP.fm = {}
for k = 1, Keys.MslSlots do
	SP.fm[k] = {v = param(string.format("MSL_%02d_LN", k)), trk = param(string.format("MSL_%02d_TRK", k)),
		B = param(string.format("SITP_FM%02d_B", k)), L = param(string.format("SITP_FM%02d_L", k)),
		X = param(string.format("SITP_FM%02d_X", k)), Y = param(string.format("SITP_FM%02d_Y", k))}
	SP.fm[k].B:set(0) SP.fm[k].L:set(0) SP.fm[k].X:set(0) SP.fm[k].Y:set(0)
end
for k = 1, #SITP_ROSE_LABELS do
	SP.lx[k] = param(string.format("SITP_ROSE_%02d_X", k))
	SP.ly[k] = param(string.format("SITP_ROSE_%02d_Y", k))
end



local sitp_g = {}
for k = 1, SITP_MAX_LEG do
	sitp_g[k] = {}
	for _, f in ipairs({"X", "Y", "A", "L"}) do sitp_g[k][f] = param(string.format("SITP_G%02d_%s", k, f)) end
	for b = 0, SITP_LEG_BITS - 1 do sitp_g[k]["B"..b] = param(string.format("SITP_G%02d_B%d", k, b)) end
end
SP.stpt = {}
for k = 1, SITP_MAX_STPT do
	SP.stpt[k] = {}
	for _, f in ipairs({"X", "Y", "V"}) do SP.stpt[k][f] = param(string.format("SITP_S%02d_%s", k, f)) end
end
local NAVP = {be_v = param("NAV_BE_V"), be_n = param("NAV_BE_N"), be_e = param("NAV_BE_E"), be_brg = param("NAV_BE_BRG"),
	be_rng = param("NAV_BE_RNG"), be_rel = param("NAV_BE_REL"), be_dist = param("NAV_BE_DIST"), decl = param("NAV_DECL"),
	cur_x = param("SITP_CUR_X"), cur_y = param("SITP_CUR_Y"), cur_v = param("SITP_CUR_V"), sp = {}}
for i = 1, 20 do
	NAVP.sp[i] = {rel = param(string.format("NAV_SP%02d_REL", i)), dist = param(string.format("NAV_SP%02d_DIST", i)),
		ok = param(string.format("NAV_SP%02d_OK", i))}
end


local SITP_REQ = {N = param("SITP_REQ_N"), F = param("SITP_REQ_F"), seen = 0}


local S = {
	att = nil, att_hist = {},
	now = 0, t_poll = 0, t_log = 0, t_sum = 0,
	tews_scale = 1,
	sitp_scale = 3,
	air = true, sam = true, jtid = true, lne = true,
	dctr = false,
	mem = {},
	emitters = {},
	contacts = {},
	own = nil,
	csv = nil, sensors = "",
	alert = 0,
}


local function dcs_log(s)
	if log and log.info then tostring("F15EX RWR "..s) else tostring("F15EX RWR "..s) end
end

local function csv_row(fields)
	if not S.csv then return end
	for i, v in ipairs(fields) do fields[i] = tostring(v):gsub(",", ";") end
	S.csv:write(table.concat(fields, ",").."\n")
	S.csv:flush()
end

local function act(s)
	dcs_log(string.format("%.2f %s", S.now, s))
	csv_row({string.format("%.3f", S.now), "A", s})
end

local function open_csv()
	local ok, f = pcall(function()
		local stamp = (os and os.date) and os.date("%Y%m%d_%H%M%S") or tostring(math.floor(get_model_time()))
		return nil
	end)
	if ok and f then
		S.csv = f
		S.csv:write("# t,O,x,z,alt_baro_m,h_agl_m,hdg_used_deg,hdg_src,hdg_mag_deg,hdg_get_deg,pitch_deg,roll_deg,contacts\n"
			.."# t,R,slot,source,unit_type,code,general_type,az_rad,el_rad,power,signal,priority,time,true_brg_deg,"
			.."range_m,quality,method,fix_x,fix_z,looks\n# t,A,text\n")
	end
end








local TONES = {new = "Aircrafts/F15EX/RWR/F15EX_RWR_New", lock = "Aircrafts/F15EX/RWR/F15EX_RWR_Lock",
	launch = "Aircrafts/F15EX/RWR/F15EX_RWR_Launch"}
local LOCK_PLAYS = 1
local tones, pending = {}, {}
local lock_left, launch_until = 0, -1

local rwr_power = param("RWR_POWER")

local function init_audio()
	if type(create_sound_host) ~= "function" then dcs_log("audio: no create_sound_host here") return end
	local ok, host = pcall(create_sound_host, "F15EX_RWR_AUDIO", "HEADPHONES", 0, 0, 0)
	if not ok or not host then dcs_log("audio: sound host refused: "..tostring(host)) return end
	for k, name in pairs(TONES) do
		local ok2, s = pcall(host.create_sound, host, name)
		if ok2 and s then tones[k] = s else dcs_log("audio: "..name.." not created: "..tostring(s)) end
	end
end



local TONE_LEN = {new = 0.25, lock = 2.0, launch = 1.2}
local tone_end = {}
local function is_playing(k)
	return tones[k] ~= nil and S.now < (tone_end[k] or -1)
end

local function stop(k)
	if tones[k] and tones[k].stop then pcall(tones[k].stop, tones[k]) end
	tone_end[k] = nil
end

local function play(k)
	if not tones[k] then return end
	if tones[k].stop then pcall(tones[k].stop, tones[k]) end
	pcall(tones[k].play_once, tones[k])
	tone_end[k] = S.now + TONE_LEN[k] + 0.05
end



local launch_looping = false
local function launch_on()
	local t = tones.launch
	if not t then return end
	if t.play_continue then
		if not launch_looping then launch_looping = pcall(t.play_continue, t) end
	elseif not is_playing("launch") then
		play("launch")
	end
end

local function launch_off()
	if launch_looping or is_playing("launch") then stop("launch") end
	launch_looping = false
end

local function audio_tick()
	if num(rwr_power) < 0.5 then
		pending, lock_left, launch_until = {}, 0, -1
		launch_off()
		S.tone_on = false
		return
	end



	local launching = (S.alert or 0) > 0
	if launching and S.now >= launch_until then stop("lock") stop("new") end
	launch_until = launching and math.huge or -1
	if launching ~= (S.tone_on or false) then
		act(launching and "TONE launch on" or "TONE launch off")
		S.tone_on = launching
	end
	if launching then
		pending, lock_left = {}, 0
		launch_on()
		return
	end
	launch_off()
	if is_playing("lock") or is_playing("new") then return end
	if lock_left > 0 then
		lock_left = lock_left - 1
		play("lock")
	elseif pending.lock then
		pending.lock, lock_left = nil, LOCK_PLAYS - 1
		play("lock")
	elseif pending.new then
		pending.new = nil
		play("new")
	end
end



local function sensor(name)
	local f = sensor_data[name]
	if type(f) ~= "function" then return nil end
	local ok, a, b, c = pcall(f)
	if ok then return a, b, c end
	return nil
end




local function own_state()
	local x, _, z = sensor("getSelfCoordinates")
	local o = {alt = sensor("getBarometricAltitude") or 0, pitch = sensor("getPitch") or 0, roll = sensor("getRoll") or 0}
	o.hdg_mag = sensor("getMagneticHeading")
	o.hdg_get = sensor("getHeading")
	if num(P.link) >= 1 then
		o.hdg, o.hdg_src = math.rad(num(P.own_hdg)), "DLL"
	elseif o.hdg_mag then
		o.hdg, o.hdg_src = o.hdg_mag, "MAG"
	else
		o.hdg, o.hdg_src = 0, "NONE"
	end
	o.h_agl = sensor("getRadarAltitude") or o.alt
	local vx, _, vz = sensor("getSelfVelocity")
	o.vx, o.vz = type(vx) == "number" and vx or 0, type(vz) == "number" and vz or 0
	if type(x) == "number" and type(z) == "number" then o.x, o.z = x, z end
	return o
end


local function read_tracks()
	local list = {}
	if num(P.link) < 1 then return list end
	local iff = {}
	for i = 1, math.min(math.floor(num(IFFP.n) + 0.5), TRK_MAX) do
		iff[math.floor(num(IFFP.num[i]) + 0.5)] = math.floor(num(IFFP.res[i]) + 0.5)
	end
	local n = math.min(math.floor(num(P.trk_count) + 0.5), TRK_MAX)
	local in_stt = false
	for i = 1, n do if num(trk[i].STT) == 1 then in_stt = true end end
	for i = 1, n do
		local s = trk[i]
		local number = math.floor(num(s.NUM) + 0.5)


		if number > 0 and (not in_stt or num(s.STT) == 1 or num(s.DL) > 0.5) then
			list[#list + 1] = {number = number, range = num(s.RANGE), brg = num(s.BRG), elev = num(s.ELEV),
				hdg = num(s.HDG), gs = num(s.GS), coast = num(s.COAST) == 1, type = NCTR.show(str(s.TYPE)),
				iff = iff[number] or 0}
		end
	end
	return list
end





local function live(s)
	return num(s.SIGNAL) >= 0.5 and num(s.POWER) > 0 and num(s.TIME) >= 0
end

local LAUNCH_HOLD = 2.0

local OFF_RWR = 0.25
local PAIR_BRG = math.rad(30)





local LAUNCH_MAX = 90.0
local MSL_AGING = 0.9
local MSL_HOLD = 5.0







local ATT_HIST = 1.5
local BRG_RATE_MAX = math.rad(10)
local PROP_MAX = 2.0
local function own_att()
	local o = {t = S.now, pitch = sensor("getPitch") or 0, roll = sensor("getRoll") or 0}
	if num(P.link) >= 1 then o.hdg = math.rad(num(P.own_hdg)) else o.hdg = sensor("getMagneticHeading") or 0 end
	return o
end
local function att_at(t)
	local h, best = S.att_hist, nil
	for i = #h, 1, -1 do
		best = h[i]
		if h[i].t <= t then break end
	end
	return best or S.att or {hdg = 0, pitch = 0, roll = 0}
end
local function att_tick()
	S.att = own_att()
	local h = S.att_hist
	h[#h + 1] = S.att
	while #h > 1 and S.now - h[1].t > ATT_HIST do table.remove(h, 1) end
end

local function live_event(e, c)
	local ev = S.now - math.max(c.time, 0)
	if e.ev and ev <= e.ev + 0.02 and c.az == e.ev_az and c.el == e.ev_el then return end
	local a = att_at(ev)
	local b, w = RNG.world_angles(c.az, c.el, a.hdg, a.pitch, a.roll)
	local dt = e.ev and ev - e.ev or 0
	if dt >= 0.3 and dt <= 4.0 then
		e.brg_rate = clamp(wrap_pi(b - e.w_brg) / dt, -BRG_RATE_MAX, BRG_RATE_MAX)
	else
		e.brg_rate = 0
	end
	e.ev, e.ev_az, e.ev_el, e.w_brg, e.w_el = ev, c.az, c.el, b, w
end

local function live_rel(c)
	local e, a = c.e, S.att
	if not (e and e.ev and a) then return end
	local brg = e.w_brg + (e.brg_rate or 0) * math.min(math.max(S.now - e.ev, 0), PROP_MAX)
	local az, el = RNG.body_angles(brg, e.w_el, a.hdg, a.pitch, a.roll)
	c.rel, c.el_live = -az, el
end

local function read_contacts(own, tracks)
	local list, by_key = {}, {}
	for i = 1, TEWS_MAX do
		local s = rwr[i]
		local ut = str(s.UNIT_TYPE)
		if ut ~= "" and ut ~= "0" and live(s) then
			local c = {slot = i, unit_type = ut, az = num(s.AZIMUTH), el = num(s.ELEVATION), power = num(s.POWER),
				signal = math.floor(num(s.SIGNAL) + 0.5), gt = math.floor(num(s.GENERAL_TYPE) + 0.5),
				priority = num(s.PRIORITY), source = num(s.SOURCE), time = num(s.TIME)}
			c.code = CODES.code(ut)
			c.label = CODES.label(ut, c.code)
			c.key = c.source ~= 0 and string.format("%.0f", c.source) or (ut.."@"..math.floor(c.az * RAD / 10 + 0.5))
			c.rel = -c.az

			c.brg, c.wel = RNG.world_angles(c.az, c.el, own.hdg, own.pitch, own.roll)
			local old = by_key[c.key]
			if not old then
				by_key[c.key] = c
				list[#list + 1] = c
			elseif c.power > old.power or c.signal > old.signal then
				c.signal = math.max(c.signal, old.signal)
				for k = 1, #list do if list[k] == old then list[k] = c end end
				by_key[c.key] = c
			else
				old.signal = math.max(old.signal, c.signal)
			end
		end
	end

	for _, c in ipairs(list) do
		local e = S.emitters[c.key]
		if not e then
			e = {rng = RNG.new(), first = S.now, signal = 0, code = c.code}
			S.emitters[c.key] = e
			act(string.format("NEW %s (%s, type %d, source %s) rel %+.0f deg, power %.2f", c.code, c.unit_type, c.gt,
				c.key, c.rel * RAD, c.power))
			pending.new = true
		end


		if e.last and S.now - e.last > REDETECT_GAP then
			act(string.format("REDETECT %s %s after %.0f s", e.code, c.key, S.now - e.last))
			pending.new = true
			e.signal = 0
		end
		if c.signal ~= e.signal then
			local names = {[1] = "SEARCH", [2] = "LOCK", [3] = "LAUNCH"}
			if e.signal ~= 0 or c.signal > 1 then
				act(string.format("%s %s (%s) %s -> %s, rel %+.0f deg", c.code, c.key, c.unit_type,
					names[e.signal] or tostring(e.signal), names[c.signal] or tostring(c.signal), c.rel * RAD))
			end
			if c.signal == 2 and e.signal < 2 then pending.lock = true end
			e.signal = c.signal
		end
		e.last = S.now
		c.e = e
		live_event(e, c)
		c.brg, c.wel = e.w_brg, e.w_el
		live_rel(c)
		c.range, c.quality, c.method = 0, RNG.NONE, ""
		if own.x and (c.gt == 2 or c.gt == 3) then

			if math.abs(own.pitch) < RNG.LOOK_MAX_ATT and math.abs(own.roll) < RNG.LOOK_MAX_ATT
				and RNG.add_look(e.rng, S.now, own.x, own.z, c.brg) then
				local f = RNG.triangulate(e.rng)
				if f and (not e.fix or f.quality >= e.fix.quality or #e.rng.looks >= RNG.MAX_LOOKS) then e.fix = f end
			end
			if e.fix then
				c.range = math.sqrt((e.fix.x - own.x) ^ 2 + (e.fix.z - own.z) ^ 2)
				c.quality, c.method = e.fix.quality, "TRI"

				if c.gt == 2 and e.fix.quality >= RNG.FIXED then
					S.mem[c.key] = {x = e.fix.x, z = e.fix.z, code = c.code, label = c.label}
				end
			end
		end
		if c.quality == RNG.NONE and c.gt == 1 then



			local best, bd, kept
			local function try(t)
				local d = math.abs(wrap_pi(t.brg - c.rel))
				if e.match == t.number and d <= AIR_MATCH_KEEP then kept = t end
				if d <= AIR_MATCH and (not bd or d < bd) then best, bd = t, d end
			end
			for _, t in ipairs(tracks) do try(t) end
			for _, t in ipairs(DLINK.list) do if t.id ~= 2 then try(t) end end
			local t = kept or best
			if t then
				e.match, e.match_t, e.match_r = t.number, S.now, t.range
				c.range, c.quality, c.method = t.range, RNG.FIXED, DLINK.is_dl(t.number) and "DL" or "RDR"
			elseif e.match and S.now - e.match_t <= AIR_MATCH_HOLD then
				c.range, c.quality, c.method = e.match_r, RNG.FIXED, "HOLD"
			else
				e.match = nil
			end
		end

		if c.signal >= 3 then
			e.t_launch = S.now
			if e.launch and e.launch.done then e.launch = nil end
			if not e.launch then
				e.launch = TTI.start(S.now, c.code)
				act(string.format("LAUNCH %s %s: TTI -- until a missile emits", c.code, c.key))
			end
		elseif e.launch and S.now - (e.t_launch or -1e9) > LAUNCH_HOLD then
			if c.signal >= 2 and not e.launch.done and S.now - e.launch.t0 <= LAUNCH_MAX then
				if not e.launch.held then
					act(string.format("LAUNCH %s %s held: no launch call, still locked", c.code, c.key))
					e.launch.held = true
				end
			else
				act(string.format("LAUNCH %s %s over after %.1f s%s", c.code, c.key, S.now - e.launch.t0,
					e.launch.done and " (its missile gone)" or ""))
				e.launch = nil
			end
		end
		c.tti = nil
		if c.gt == 4 then

			e.emit = e.emit or TTI.emit_new()
			TTI.emit_add(e.emit, S.now, c.power)
			local t = TTI.emit_tti(e.emit, S.now)





			if t then
				e.tti_t, e.tti_v, e.tti_held = S.now, t, nil
			elseif e.tti_t and c.time > MSL_AGING and S.now - e.tti_t <= MSL_HOLD then
				t = math.max(0, e.tti_v - (S.now - e.tti_t))
				if not e.tti_held then
					act(string.format("MSL %s %s not heard (data %.1f s old): TTI counted down, held %.0f s at most",
						c.code, c.key, c.time, MSL_HOLD))
					e.tti_held = true
				end
			end
			if t and not e.emit_shown then
				act(string.format("EMIT TTI %s %s: %.0f s at power %.3f", c.code, c.key, t, c.power))
			end
			e.emit_shown = t ~= nil
			e.emit_ever = e.emit_ever or t ~= nil
			c.tti = t and TTI.shown(t) or nil

			c.threat = c.tti ~= nil or not e.emit_ever
		else
			c.threat = e.launch ~= nil
		end
	end




	for _, c in ipairs(list) do
		if c.gt ~= 4 and c.e and c.e.launch then
			local L = c.e.launch
			local best, bd
			for _, m in ipairs(list) do
				if m.gt == 4 and m.threat and m.e.first >= L.t0 - 1.0 then
					local d = math.abs(wrap_pi(m.brg - c.brg))
					if d <= PAIR_BRG and (not bd or d < bd) then best, bd = m, d end
				end
			end
			if best then
				c.tti = best.tti
				if L.msl ~= best.key then
					act(string.format("LAUNCH %s %s: its missile %s (%s) active", c.code, c.key, best.key, best.unit_type))
				end
				L.msl = best.key
			elseif L.msl and not L.done then
				act(string.format("LAUNCH %s %s: its missile %s gone or going past", c.code, c.key, L.msl))
				L.done = true
			end
		end
	end

	for k, e in pairs(S.emitters) do
		if e.launch and e.last and S.now - e.last > OFF_RWR then
			act(string.format("LAUNCH %s %s over: off the RWR", e.code, k))
			e.launch = nil
		end
		if S.now - (e.last or S.now) > FORGET_AFTER then
			act(string.format("FORGET %s %s", e.code, k))
			S.emitters[k] = nil
		end
	end

	local alert = 0
	for _, c in ipairs(list) do
		if c.gt == 4 and c.threat then alert = 2
		elseif c.e and c.e.launch and alert < 1 then alert = 1 end
	end
	if alert ~= S.alert then
		act(({[0] = "ALERT off", "ALERT LAUNCH (no active missile seen)", "ALERT MISSILE ACTIVE"})[alert])
		S.alert = alert
	end
	return list
end


local function set_code(h, code)
	local txt, n, is_num = CODES.split(code)
	h.TXT:set(txt)
	h.NUM:set(n)
	h.CN:set(is_num and 1 or 0)
end

local function flash_on()
	return (S.now % (FLASH_ON + FLASH_OFF)) < FLASH_ON
end

local function update_tews()
	local list = S.contacts
	local scale_nm = TEWS_SCALES[S.tews_scale]
	local fl = flash_on()

	local own = S.own or {hdg = 0}
	local h = own.hdg_mag or own.hdg or 0
	T.rot:set(-h)
	for k = 1, #TEWS_ROSE_LABELS do
		local x, y = ew_xy(math.rad(30 * (k - 1)) - h, TEWS_R_LABEL)
		T.lx[k]:set(x)
		T.ly[k]:set(y)
	end
	local fixes, soonest, any = 0, nil, false
	for i = 1, TEWS_MAX do
		local h, c = tews[i], list[i]
		if c then
			local r
			if scale_nm == 0 then
				r = tews_power_r(c.power, EW_CODES[c.code])
			elseif c.quality >= RNG.ROUGH then
				r = math.min(c.range / (scale_nm * M_PER_NM) * TEWS_R_DOTS, TEWS_R_EDGE)
			else
				r = TEWS_R_EDGE
			end
			local x, y = ew_xy(c.rel, r)
			h.X:set(x) h.Y:set(y)


			local launch = c.signal >= 3 or (c.e ~= nil and c.e.launch ~= nil)
			local air = c.gt == 1
			h.V:set(1)
			set_code(h, c.label)
			h.AIR:set((air and not (launch and not fl)) and 1 or 0)
			h.SHIP:set(c.gt == 3 and 1 or 0)
			h.LOCK:set((c.signal >= 2 and not (launch and not air and not fl)) and 1 or 0)
			h.RNG:set(c.quality)
			if c.quality == RNG.FIXED then fixes = fixes + 1 end
			h.TTI:set(c.tti or 0)
			h.TTIV:set(c.tti and 1 or (c.threat and 2 or 0))
			if c.tti and (not soonest or c.tti < soonest) then soonest = c.tti end
			if c.threat then any = true end
		else
			for _, f in ipairs({"V", "AIR", "SHIP", "LOCK", "RNG", "TTIV"}) do h[f]:set(0) end
		end
	end
	MSL.v:set(any and (fl and 1 or 2) or 0)
	MSL.tti:set(soonest or -1)
	MSL.act:set(S.alert == 2 and 1 or 0)
	MSL.alert:set(S.alert or 0)
	T.scale:set(scale_nm)
	T.n:set(#list)
	T.fix_n:set(fixes)
end


local function publish_hmd()
	local list, ms = {}, {}
	for _, c in ipairs(S.contacts) do
		if c.gt ~= 4 then list[#list + 1] = c elseif c.threat then ms[#ms + 1] = c end
	end

	table.sort(ms, function(a, b)
		if a.tti and b.tti and a.tti ~= b.tti then return a.tti < b.tti end
		if (a.tti ~= nil) ~= (b.tti ~= nil) then return a.tti ~= nil end
		return a.power > b.power
	end)
	local nm = math.min(#ms, HMDM.MAX)
	for i = 1, nm do
		local c, h = ms[i], HMDM.s[i]
		h.SRC:set(c.source)
		h.AZ:set(c.rel)
		h.EL:set(c.el)
		h.TTI:set(c.tti or -1)
	end
	HMDM.n:set(nm)
	local function rank(c) return c.threat and 3 or math.min(c.signal, 2) end
	table.sort(list, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then return ra > rb end
		if a.tti and b.tti and a.tti ~= b.tti then return a.tti < b.tti end
		if (a.tti ~= nil) ~= (b.tti ~= nil) then return a.tti ~= nil end
		return a.power > b.power
	end)
	local n = math.min(#list, HMDT.MAX)
	for i = 1, n do
		local c, h = list[i], HMDT.s[i]
		h.AZ:set(c.rel)
		h.EL:set(c.el)
		h.SIG:set(c.threat and 3 or math.min(c.signal, 2))
		set_code(h, c.label)
		h.TTI:set(c.tti or -1)
	end
	for i = n + 1, HMDT.MAX do HMDT.s[i].SIG:set(0) end
	HMDT.n:set(n)
end


local AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
local own_alt_m = param("RDR_OWN_ALT")
AA.F = AA.alt_filter()
local function alt_kft(t)
	local ft = AA.track_alt_ft(num(own_alt_m), t.range, t.elev)
	if t.number then return AA.F.kft(t.number, ft, S.now) end
	return math.max(0, math.floor(ft / 1000 + 0.5))
end

local function update_sitp(own, tracks)
	DCTR:set(S.dctr and 1 or 0)
	SITP_OFF = S.dctr and 0 or SITP_OFF_BASE
	local cur_on, cur_x, cur_y = num(CUR.v) > 0.5, num(CUR.dx), num(CUR.dy)

	local function hovered(x, y)
		return cur_on and (x - cur_x) ^ 2 + (y - cur_y) ^ 2 <= HOVER_R * HOVER_R
	end
	local scale_m = SITP_SCALES[S.sitp_scale] * M_PER_NM
	local k_m = SITP_RS / scale_m


	local ek, ecx, ecy = math.max(1, num(SP.exp_k)), num(SP.exp_cx), num(SP.exp_cy)
	local LINE_SHORT = 0.04
	local function place(x, y) return sitp_exp_xy(x, y, ek, ecx, ecy) end
	SP.rng:set(SITP_SCALES[S.sitp_scale])
	SP.air:set(S.air and 1 or 0)
	SP.sam:set(S.sam and 1 or 0)
	SP.jtid:set(S.jtid and 1 or 0)
	SP.lne:set(S.lne and 1 or 0)


	local hr = own.hdg_mag or own.hdg or 0
	SP.rot:set(-hr)
	for k = 1, #SITP_ROSE_LABELS do
		local x, y = ew_xy(math.rad(90 * (k - 1)) - hr, SITP_R_LABEL)
		SP.lx[k]:set(x)
		SP.ly[k]:set(y)
	end
	local n, dt = 0, math.floor(num(P.dt) + 0.5)
	SP.dt_v:set(0)
	SP.dt_l:set(0)
	local function dt_line(t, x, y)
		local sx, sy, len = sitp_exp_line(x, y, ek, ecx, ecy, LINE_SHORT)
		if not sx then return end
		local mx, my = sitp_line_move(sx, sy, t.brg)
		SP.dt_x:set(mx) SP.dt_y:set(my)
		SP.dt_b:set(t.brg)
		SP.dt_l:set(math.max(0, math.floor(len / SITP_DT_PIECE)))
		SP.dt_v:set(1)
	end
	local fired, nf = {}, 0
	for _, f in ipairs(SP.fm) do
		local tn = math.floor(num(f.trk) + 0.5)
		if num(f.v) > 0.5 and tn > 0 then fired[tn] = true end
	end
	local function fm_line(t, x, y)
		if not fired[t.number] or nf >= #SP.fm then return end
		local sx, sy, len = sitp_exp_line(x, y, ek, ecx, ecy, LINE_SHORT)
		if not sx then return end
		fired[t.number] = nil
		nf = nf + 1
		local mx, my = sitp_line_move(sx, sy, t.brg)
		SP.fm[nf].X:set(mx) SP.fm[nf].Y:set(my)
		SP.fm[nf].B:set(t.brg)
		SP.fm[nf].L:set(math.max(0, math.floor(len / SITP_DT_PIECE)))
	end
	if S.air then
		table.sort(tracks, function(a, b) return a.range < b.range end)
		for _, t in ipairs(tracks) do
			local x, y = place(ew_xy(t.brg, t.range * k_m))
			if sitp_inside(x, y) and n < SITP_MAX_TRK then
				n = n + 1
				local h = sitp_t[n]
				h.X:set(x) h.Y:set(y)
				h.V:set(t.coast and 2 or 1)
				h.H:set(math.rad(t.hdg))
				h.L:set(t.gs < 20 and 0 or clamp(math.floor(t.gs / SITP_STICK_MPS + 0.5), 1, SITP_STICK_STEPS))
				h.ALT:set(alt_kft(t))
				h.ID:set((t.number == dt or hovered(x, y)) and sitp_id(t.type) or "")
				h.I:set(t.iff)
				h.D:set(t.number == dt and 1 or 0)
				if t.number == dt then dt_line(t, x, y) end
				fm_line(t, x, y)
			end
		end
	end
	for i = n + 1, SITP_MAX_TRK do sitp_t[i].V:set(0) sitp_t[i].D:set(0) end

	local nl = 0
	if S.jtid then
		for _, t in ipairs(DLINK.list) do
			local x, y = place(ew_xy(t.brg, t.range * k_m))
			if sitp_inside(x, y) and nl < SITP_MAX_DL then
				nl = nl + 1
				local h = sitp_l[nl]
				h.X:set(x) h.Y:set(y)
				h.V:set(t.id)
				h.H:set(math.rad(t.hdg))
				h.L:set(t.gs < 20 and 0 or clamp(math.floor(t.gs / SITP_STICK_MPS + 0.5), 1, SITP_STICK_STEPS))
				h.ALT:set(alt_kft(t))
				h.ID:set((t.number == dt or hovered(x, y)) and sitp_id(t.id == DLINK.FRIEND and t.name or "") or "")
				h.D:set(t.number == dt and 1 or 0)
				if t.number == dt then dt_line(t, x, y) end
				fm_line(t, x, y)
			end
		end
	end
	for i = nl + 1, SITP_MAX_DL do sitp_l[i].V:set(0) sitp_l[i].D:set(0) end
	for i = nf + 1, #SP.fm do SP.fm[i].L:set(0) end

	local m = 0
	for _, c in ipairs(S.contacts) do
		local ground = c.gt == 2 or c.gt == 3
		if (S.sam or not ground) and m < SITP_MAX_THR then
			m = m + 1
			local h = sitp_r[m]
			local x, y, v, ring
			local fx, fy = place(ew_xy(c.rel, c.quality == RNG.FIXED and c.range * k_m or 0))
			if c.quality == RNG.FIXED and sitp_inside(fx, fy) then
				x, y = fx, fy
				v = 2
				ring = ground and sitp_ring(LETHAL[c.code], scale_m / ek) or 0
				if ring > 0 and not sitp_inside(x, y, SITP_RINGS[ring] + SITP_R - SITP_RING_LIMIT) then ring = 0 end
			else
				x, y = sitp_edge(c.rel, SITP_EDGE)
				v, ring = 1, 0
			end
			h.X:set(x) h.Y:set(y) h.V:set(v) h.RING:set(ring)
			h.LOCK:set(c.signal >= 2 and 1 or 0)
			h.CLR:set(c.signal >= 2 and 3 or (EW_CODES[c.code] and 1 or 2))
			set_code(h, c.label)
		end
	end


	if S.sam and own.x and own.hdg then
		local heard = {}
		for _, c in ipairs(S.contacts) do heard[c.key] = true end
		for key, q in pairs(S.mem) do
			if m >= SITP_MAX_THR then break end
			if not heard[key] then
				local rel = wrap_pi(math.atan2(q.z - own.z, q.x - own.x) - own.hdg)
				local rng = math.sqrt((q.x - own.x) ^ 2 + (q.z - own.z) ^ 2)
				local x, y = place(ew_xy(rel, rng * k_m))
				if sitp_inside(x, y) then
					m = m + 1
					local h = sitp_r[m]
					local ring = sitp_ring(LETHAL[q.code], scale_m / ek)
					if ring > 0 and not sitp_inside(x, y, SITP_RINGS[ring] + SITP_R - SITP_RING_LIMIT) then ring = 0 end
					h.X:set(x) h.Y:set(y) h.V:set(2) h.RING:set(ring) h.LOCK:set(0)
					h.CLR:set(EW_CODES[q.code] and 1 or 2)
					set_code(h, q.label)
				end
			end
		end
	end
	for i = m + 1, SITP_MAX_THR do sitp_r[i].V:set(0) sitp_r[i].RING:set(0) sitp_r[i].LOCK:set(0) end

	local g, ns = 0, 0
	if S.lne and ek == 1 then
		local prev
		for i = 1, #NAVP.sp do
			local q = NAVP.sp[i]
			if num(q.ok) < 0.5 then break end
			local px, py = ew_xy(num(q.rel), num(q.dist) * k_m)
			if ns < SITP_MAX_STPT and sitp_inside(px, py) then
				ns = ns + 1
				local h = SP.stpt[ns]
				h.X:set(px) h.Y:set(py) h.V:set(1)
			end
			if prev and g < SITP_MAX_LEG then
				local t0, t1 = sitp_clip(prev[1], prev[2], px, py)
				if t0 then
					g = g + 1
					local dx, dy = px - prev[1], py - prev[2]
					local h = sitp_g[g]
					h.X:set(prev[1] + t0 * dx)
					h.Y:set(prev[2] + t0 * dy - SITP_OFF)

					h.A:set((math.pi / 2 - math.atan2(dx, dy)) / EW_ROT_GAIN)
					local n = math.min(2 ^ SITP_LEG_BITS - 1,
						math.floor((t1 - t0) * math.sqrt(dx * dx + dy * dy) / SITP_LEG_STEP + 0.5))
					h.L:set(n)
					for b = 0, SITP_LEG_BITS - 1 do h["B"..b]:set(math.floor(n / 2 ^ b) % 2) end
				end
			end
			prev = {px, py}
		end
	end
	for k = g + 1, SITP_MAX_LEG do
		for _, h in pairs(sitp_g[k]) do h:set(0) end
	end
	for k = ns + 1, SITP_MAX_STPT do for _, h in pairs(SP.stpt[k]) do h:set(0) end end


	local be = num(NAVP.be_v) > 0.5
	local bx, by = place(ew_xy(num(NAVP.be_rel), num(NAVP.be_dist) * k_m))
	SP.be_v:set((be and sitp_inside(bx, by)) and 1 or 0)
	SP.be_x:set(bx) SP.be_y:set(by)
	if be and num(NAVP.cur_v) > 0.5 then
		local cx, cy = num(NAVP.cur_x), num(NAVP.cur_y)
		local r = math.sqrt(cx * cx + cy * cy) / k_m
		local tb = math.atan2(cx, cy) + (own.hdg or 0)
		local bn, bE = num(NAVP.be_n) + r * math.cos(tb), num(NAVP.be_e) + r * math.sin(tb)
		SP.beb:set(math.floor(math.deg(math.atan2(bE, bn) - num(NAVP.decl)) + 0.5) % 360)
		SP.ber:set(math.floor(math.sqrt(bn * bn + bE * bE) / M_PER_NM + 0.5))
		SP.bev:set(2)
	elseif be then
		SP.beb:set(num(NAVP.be_brg))
		SP.ber:set(num(NAVP.be_rng))
		SP.bev:set(1)
	else
		SP.bev:set(0)
	end
end


local function sitp_requests()
	local n = num(SITP_REQ.N)
	if n == SITP_REQ.seen then return end
	SITP_REQ.seen = n
	local f = math.floor(num(SITP_REQ.F) + 0.5)
	local key = ({[1] = "lne", [2] = "air", [4] = "sam", [13] = "jtid", [14] = "dctr"})[f]
	if key then
		S[key] = not S[key]
		act(string.format("SIT-P %s %s (touch)", key:upper(), S[key] and "on" or "off"))
	end
end


local function log_rows(own)
	local function d(a) return a and string.format("%.2f", a * RAD) or "" end
	csv_row({string.format("%.3f", S.now), "O", own.x and string.format("%.1f", own.x) or "",
		own.z and string.format("%.1f", own.z) or "", string.format("%.1f", own.alt), string.format("%.1f", own.h_agl),
		d(own.hdg), own.hdg_src, d(own.hdg_mag), d(own.hdg_get), d(own.pitch), d(own.roll), #S.contacts})
	for _, c in ipairs(S.contacts) do
		local f = c.e.fix
		csv_row({string.format("%.3f", S.now), "R", c.slot, c.key, c.unit_type, c.code, c.gt, string.format("%.5f", c.az),
			string.format("%.5f", c.el), string.format("%.4f", c.power), c.signal, string.format("%.3f", c.priority),
			string.format("%.2f", c.time), string.format("%.2f", c.brg * RAD), string.format("%.0f", c.range), c.quality,
			c.method, f and string.format("%.0f", f.x) or "", f and string.format("%.0f", f.z) or "", #c.e.rng.looks})
	end
end

local function summary()
	local parts = {}
	for _, c in ipairs(S.contacts) do
		parts[#parts + 1] = string.format("%s %+.0f p%.2f s%d%s", c.code, c.rel * RAD, c.power, c.signal,
			c.quality > 0 and string.format(" %.1fnm/%s%d", c.range / M_PER_NM, c.method, c.quality) or "")
	end

	if #parts == 0 then
		local s = rwr[1]
		local ut = s.UNIT_TYPE:get()
		parts[1] = string.format("slot 01 raw: unit_type %s (%s), power %s, time %s, signal %s",
			tostring(ut), type(ut), tostring(s.POWER:get()), tostring(s.TIME:get()), tostring(s.SIGNAL:get()))
	end
	dcs_log(string.format("%.1f %d contacts%s", S.now, #S.contacts, #parts > 0 and (": "..table.concat(parts, ", ")) or ""))
end


for _, c in ipairs({cmd.TewsScale, cmd.SitpRange, cmd.SitpAir, cmd.SitpSam, cmd.SitpJtid}) do dev:listen_command(c) end



local SOI_RNG = {N = param("SOI_RNG_N"), D = param("SOI_RNG_D"), F = param("SOI_RNG_F"), seen = 0}
local function soi_range()
	local n = num(SOI_RNG.N)
	if n == SOI_RNG.seen then return end
	SOI_RNG.seen = n
	local f, d = math.floor(num(SOI_RNG.F) + 0.5), num(SOI_RNG.D) < 0 and -1 or 1
	if f == 5 then
		S.sitp_scale = clamp(S.sitp_scale + d, 1, #SITP_SCALES)
		act("SIT-P range "..SITP_SCALES[S.sitp_scale].." nm (range key, SIT-P in command)")
	elseif f == 3 then
		S.tews_scale = clamp(S.tews_scale + d, 1, #TEWS_SCALES)
		act("TEWS scale "..(TEWS_SCALES[S.tews_scale] == 0 and "PWR" or (TEWS_SCALES[S.tews_scale].." nm"))
			.." (range key, TEWS in command)")
	end
end

function post_initialize()
	SOI_RNG.seen = num(SOI_RNG.N)
	SITP_REQ.seen = num(SITP_REQ.N)
	S.now = get_model_time()
	open_csv()
	init_audio()

	local ok, n, err = pcall(CODES.load_dcs, "Scripts/Aircrafts/_Common/Cockpit/AN_ALR_SymbolsBase.lua", function(p)
		local f = io.open(p, "rb")
		if not f then return nil end
		local s = f:read("*a")
		f:close()
		return s
	end)
	dcs_log(ok and (err and ("RWR labels: DCS table not read ("..err.."), F-15E codes only") or
		string.format("RWR labels: %d types from DCS's table", n)) or ("RWR labels: load failed: "..tostring(n)))
	local names = {}
	for _, n in ipairs({"getSelfCoordinates", "getHeading", "getMagneticHeading", "getRadarAltitude",
			"getBarometricAltitude", "getPitch", "getRoll", "getSelfVelocity"}) do
		names[#names + 1] = n..(type(sensor_data[n]) == "function" and "" or " MISSING")
	end
	S.sensors = table.concat(names, " ")
	act("up, CSV "..(S.csv and "open" or "NOT open").."; base data: "..S.sensors)
	for i = 1, TEWS_MAX do
		for _, f in ipairs(TEWS_F) do if f ~= "TXT" then tews[i][f]:set(0) end end
		tews[i].TXT:set("")
	end
	for i = 1, SITP_MAX_TRK do for _, f in ipairs(SITP_TF) do sitp_t[i][f]:set(0) end sitp_t[i].ID:set("") end
	for i = 1, SITP_MAX_DL do for _, f in ipairs(SITP_LF) do sitp_l[i][f]:set(0) end sitp_l[i].ID:set("") end
	for i = 1, SITP_MAX_THR do
		for _, f in ipairs(SITP_RF) do if f ~= "TXT" then sitp_r[i][f]:set(0) end end
		sitp_r[i].TXT:set("")
	end
	for _, h in pairs(SP) do if h.set then h:set(0) end end
	T.scale:set(0) T.n:set(0) T.fix_n:set(0) T.rot:set(0)
	MSL.v:set(0) MSL.tti:set(0) MSL.act:set(0) MSL.alert:set(0)
	for i = 1, HMDT.MAX do
		for _, f in ipairs(HMDT_F) do if f ~= "TXT" then HMDT.s[i][f]:set(0) end end
		HMDT.s[i].TXT:set("")
	end
	HMDT.n:set(0)
	for i = 1, HMDM.MAX do for _, h in pairs(HMDM.s[i]) do h:set(0) end end
	HMDM.n:set(0)
	S.own = own_state()
	update_tews()
	update_sitp(S.own, {})
	EWT.publish({})
end

function SetCommand(command, value)
	if value == 0 then return end
	if command == cmd.TewsScale then
		S.tews_scale = S.tews_scale % #TEWS_SCALES + 1
		act("TEWS scale "..(TEWS_SCALES[S.tews_scale] == 0 and "PWR" or (TEWS_SCALES[S.tews_scale].." nm")))
	elseif command == cmd.SitpRange then
		S.sitp_scale = S.sitp_scale % #SITP_SCALES + 1
		act("SIT-P range "..SITP_SCALES[S.sitp_scale].." nm")
	elseif command == cmd.SitpAir then
		S.air = not S.air
		act("SIT-P AIR "..(S.air and "on" or "off"))
	elseif command == cmd.SitpSam then
		S.sam = not S.sam
		act("SIT-P SAM "..(S.sam and "on" or "off"))
	elseif command == cmd.SitpJtid then
		S.jtid = not S.jtid
		act("SIT-P JTID "..(S.jtid and "on" or "off"))
	end
end

function update()
	S.now = get_model_time()
	att_tick()
	soi_range()
	sitp_requests()
	S.t_poll = S.t_poll + update_time_step
	S.t_log = S.t_log + update_time_step
	S.t_sum = S.t_sum + update_time_step
	if S.t_poll >= POLL_PERIOD - 1e-9 then
		S.t_poll = 0
		S.own = own_state()
		local tracks = read_tracks()
		if num(P.link) >= 1 then DLINK.poll(DLINK.own()) else DLINK.list = {} end
		L16.update(DLINK.list, num(P.link) >= 1, DLINK.own(), S.now, DLINK.label, alt_kft)
		S.contacts = read_contacts(S.own, tracks)
		publish_hmd()
		update_sitp(S.own, tracks)
		EWT.publish(S.contacts)

	end
	for _, c in ipairs(S.contacts or {}) do live_rel(c) end
	if S.t_poll > 0 then publish_hmd() end
	update_tews()
	audio_tick()
	if S.t_log >= LOG_PERIOD - 1e-9 then
		S.t_log = 0
		log_rows(S.own)
	end
	if S.t_sum >= SUMMARY_PERIOD - 1e-9 then
		S.t_sum = 0
		summary()
	end
end




need_to_be_closed = false
