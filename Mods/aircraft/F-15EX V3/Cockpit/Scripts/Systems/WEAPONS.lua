











































dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Displays/attack_geom.lua")
dofile(LockOn_Options.script_path.."Displays/ew_geom.lua")

local dev = GetSelf()


local SRM_WS_PTR = get_param_handle("SRM_WS_PTR")
local SRM_WS_STATION = get_param_handle("SRM_WS_STATION")
local SRM_WS_9X = get_param_handle("SRM_WS_9X")

local update_time_step = 0.02
make_default_activity(update_time_step)


local LOCK_START, LOCK_FINISH, SENSOR_RESET = 509, 510, 1635

local AA_MISSILE = 7
local AMRAAM = {[24] = "AIM-120", [106] = "AIM-120C"}

local MAX_STATIONS = 16
local MAX_CONTACTS = 24
local POLL_PERIOD = 0.1
local LOG_PERIOD = 0.5
local DCS_LOG_PERIOD = 2.0





local LOCK_STEPS = {
	{caret = 10000.0, acq = 0.0},
	{caret = 40000.0, acq = 0.0},
	{caret = 100000.0, acq = 0.0},
	{caret = 100000.0, acq = math.rad(10.0)},
}
local LOCK_HOLD = 0.3
local LOCK_STEP_TIME = 1.0
local LOCK_WAIT = #LOCK_STEPS * LOCK_STEP_TIME + 0.5
local ON_CURSOR_RANGE = 3000.0
local ON_CURSOR_AZ = math.rad(3.0)
local B_UNLOCK_AFTER = 1.0
local UNLOCK_CHECK = 0.3
local POWER_CYCLE_OFF = 0.2
local CURSOR_MAX_JUMP = 5000.0
local M_PER_NM = 1852.0
local RAD_TO_DEG = 57.29578

local cmd = device_commands

local function param(name) return get_param_handle(name) end

local radar_power	= param("MSLTEST_RADAR_POWER")
local tdc_range		= param("RADAR_TDC_RANGE")
local tdc_az		= param("RADAR_TDC_AZIMUTH")
local stt_range		= param("RADAR_STT_RANGE")
local stt_az		= param("RADAR_STT_AZIMUTH")
local stt_el		= param("RADAR_STT_ELEVATION")
local stt_friendly	= param("RADAR_STT_FRIENDLY")
local radar_mode	= param("RADAR_MODE")
local tdc_caret		= param("RADAR_TDC_RANGE_CARRET_SIZE")
local acq_az		= param("ACQUSITION_ZONE_VOLUME_AZIMUTH")

local NLINES = 8
local lines = {}
for i = 1, NLINES do lines[i] = param("MSLT_L"..i) end


local LINK_NAMES = {[0] = "OFF", [1] = "UNARMED", [2] = "ARMED", [3] = "MISMATCH"}
local LINK_ARMED = 2
local MAX_TRACKS = 32
local TRK_FIELDS = {"NUM", "RANGE", "BRG", "ELEV", "CLOSURE", "COAL", "COAST", "ASKED", "TYPE", "LOCK", "STT", "HDG", "GS",
	"DL", "WF"}
local MAX_HITS = 32
local HIT_FIELDS = {"NUM", "RANGE", "BRG", "ELEV", "AGE"}
local DT_CURSOR_RANGE = 10000.0
local DT_CURSOR_AZ = math.rad(5.0)
local link_state	= param("MSLLINK_STATE")
local link_supported = param("MSLLINK_SUPPORTED")
local trk_count		= param("TRK_COUNT")
local dt_trk		= param("RDR_DT_TRK")
local dt_ok			= param("RDR_DT_OK")
local trk_slots = {}
for i = 1, MAX_TRACKS do
	local prefix = string.format("TRK_%02d_", i)
	trk_slots[i] = {}
	for _, f in ipairs(TRK_FIELDS) do trk_slots[i][f] = param(prefix..f) end
end
local hit_count		= param("HIT_COUNT")
local hit_slots = {}
for i = 1, MAX_HITS do
	local prefix = string.format("HIT_%02d_", i)
	hit_slots[i] = {}
	for _, f in ipairs(HIT_FIELDS) do hit_slots[i][f] = param(prefix..f) end
end


local rdr_plan		= param("RDR_PLAN")
local rdr_az_ofs	= param("RDR_AZ_OFS")
local rdr_el_ofs	= param("RDR_EL_OFS")
local rdr_band_range = param("RDR_BAND_RANGE")
local rdr_scan_az	= param("RDR_SCAN_AZ")
local rdr_scan_el	= param("RDR_SCAN_EL")
local rdr_scan_dt	= param("RDR_SCAN_DT")
local rdr_band_lo	= param("RDR_BAND_LO")
local rdr_band_hi	= param("RDR_BAND_HI")
local rdr_frame		= param("RDR_FRAME")
local RANGE_SCALES = {10, 20, 40, 80, 160, 320, 640}
local EL_MAX = 60.0
local M_PER_FT = 0.3048



local K4 = {
	WIDTHS = {{name = "A6", half = 60.0}, {name = "A3", half = 30.0}, {name = "A1", half = 10.0}},
	BARS = {{name = "4B", half = 6.0}, {name = "2B", half = 3.0}, {name = "1B", half = 1.5}},
	TDC_RATE = 0.96,
	TDC_DEADZONE = 0.08,
	TDC_EXP = 1.6,
	BUMP_REPEAT = 0.5,
	CAPTURE_R = 0.07,
	EL_AXIS_DEG = 20.0,
	EL_RATE = 10.0,
	MAX_PRIO = 12,
	MSG_TIME = 2.0,
}
local P4 = {az_half = param("RDR_AZ_HALF"), el_half = param("RDR_EL_HALF"), az_ctr = param("RDR_AZ_CTR"),
	azw = param("ATK_AZW"), bars = param("ATK_BARS"), msg = param("ATK_MSG"), msg_v = param("ATK_MSG_V"),
	cur = {X = param("ATK_CUR_X"), Y = param("ATK_CUR_Y"), V = param("ATK_CUR_V"), HI = param("ATK_CUR_HI"),
		LO = param("ATK_CUR_LO"), HV = param("ATK_CUR_HV")},
	el = {CY = param("ATK_EL_CY"), CV = param("ATK_EL_CV")}}



local own_hdg		= param("RDR_OWN_HDG")
local atk_on		= param("ATK_ON")
local atk_rng		= param("ATK_RNG")
local atk_scan = {V = param("ATK_SCAN_V"), L = param("ATK_SCAN_L"), R = param("ATK_SCAN_R")}
local atk_n = {X = param("ATK_N_X"), Y = param("ATK_N_Y"), V = param("ATK_N_V")}
local atk_dt = {V = param("ATK_DT_V"), B = param("ATK_DT_B"), L = param("ATK_DT_L"), BR = param("ATK_DT_BR"),
	CL = param("ATK_DT_CL"), BLK = param("ATK_DT_BLK"), I = param("ATK_DT_I"), ID = param("ATK_DT_ID"),
	TYPE = param("ATK_DT_TYPE"), strip_v = param("ATK_STRIP_V")}




atk_dt.FM = {}
for k = 1, Keys.MslSlots do
	atk_dt.FM[k] = {v = param(string.format("MSL_%02d_LN", k)), trk = param(string.format("MSL_%02d_TRK", k)),
		B = param(string.format("ATK_FM%02d_B", k)), L = param(string.format("ATK_FM%02d_L", k))}
end


local ATK_X = {count = param("EWT_COUNT"), src = {}, s = {}}
for i = 1, ATK_MAX_THREATS do
	ATK_X.src[i] = {RANGE = param(string.format("EWT_%02d_RANGE", i)), REL = param(string.format("EWT_%02d_REL", i))}
	ATK_X.s[i] = {X = param(string.format("ATK_X%02d_X", i)), Y = param(string.format("ATK_X%02d_Y", i)),
		V = param(string.format("ATK_X%02d_V", i))}
end
local atk_band = {V = param("ATK_BAND_V"), HI = param("ATK_BAND_HI"), LO = param("ATK_BAND_LO"), CY = param("ATK_BAND_CY"),
	CV = param("ATK_BAND_CV")}
local atk_cur_br	= param("ATK_CUR_BR")
local atk_strip		= param("ATK_STRIP")
local ATK_T_FIELDS = {"X", "Y", "V", "H", "L", "D", "S", "M", "P", "I", "K", "W"}
local ATK_T_HIDE = {"V", "L", "D", "S", "M", "P", "I", "K", "W"}
local KT_PER_MPS = 1.943844
local atk_t, atk_h = {}, {}
for i = 1, ATK_MAX_TRACKS do
	atk_t[i] = {}
	for _, f in ipairs(ATK_T_FIELDS) do atk_t[i][f] = param(string.format("ATK_T%02d_%s", i, f)) end
end


local ATK_L = {}
for i = 1, ATK_MAX_DL do
	ATK_L[i] = {}
	for _, f in ipairs({"X", "Y", "V", "H", "L", "D"}) do ATK_L[i][f] = param(string.format("ATK_L%02d_%s", i, f)) end
end
for i = 1, ATK_MAX_HITS do
	atk_h[i] = {}
	for _, f in ipairs({"X", "Y", "V"}) do atk_h[i][f] = param(string.format("ATK_H%02d_%s", i, f)) end
end

local FIELDS = {"RANGE", "AZIMUTH", "ELEVATION", "VX", "VY", "VZ", "RCS", "RCS_COEFF", "FRIENDLY", "NCTR", "TIME", "NOISE"}
local slots = {}
for i = 1, MAX_CONTACTS do
	local prefix = string.format("RADAR_CONTACT_%02d_", i)
	slots[i] = {}
	for _, f in ipairs(FIELDS) do slots[i][f] = param(prefix..f) end
end

local now = 0
local contacts = {}
local tracks = {}
local hits = {}

local dt = 0
local range_idx = 4
local el_ofs = 0



local S4 = {width = 1, bars = 1, acq = {x = ATK_O_X, y = ATK_O_Y + ATK_R / 2}, axis = {x = 0, y = 0},
	key = {up = 0, down = 0, left = 0, right = 0, el_up = 0, el_dn = 0}, ant = nil, bump_dir = 0, bump_t = 0, msg_until = -1}
local prio = {}
local cursor = nil
local tasks = {}
local running = nil
local history = {"", ""}
local gate_step = 1
local lock_seq = 0
local tdc_hold = -1
local cycling = false
local t_poll, t_log, t_dcs = 0, 0, 0

local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function str(h) local v = h:get() return v == nil and "" or tostring(v) end


local csv = nil
local function open_csv()
	local ok, f = pcall(function()
		local stamp = (os and os.date) and os.date("%Y%m%d_%H%M%S") or tostring(math.floor(get_model_time()))
		return nil
	end)
	if ok and f then
		csv = f
		csv:write("# t,S,power,stt_range,stt_az,stt_el,stt_friendly,tdc_range,tdc_az,radar_mode,contacts,cur_slot,"
			.."cur_range,cur_az,cur_lost,aim120_left,caret,acq_az\n# t,C,slot,range,azimuth,elevation,vx,vy,vz,rcs,rcs_coeff,friendly,"
			.."nctr,time,noise\n# t,A,text\n# t,Z,tdc_range,tdc_az,caret,origin_el,stab,vol_az,vol_el,acm,stt,cur_slot,"
			.."cur_time,cur_lost,live,expired,newest\n")
	end
end

local function dcs_log(s)
	if log and log.info then tostring("MSLTEST "..s) else tostring("MSLTEST "..s) end
end

local function csv_row(fields)
	if not csv then return end
	for i, v in ipairs(fields) do fields[i] = tostring(v):gsub(",", ";") end
	csv:write(table.concat(fields, ",").."\n")
	csv:flush()
end


local function act(s)
	local line = string.format("%.2f %s", now, s)
	dcs_log(line)
	csv_row({string.format("%.3f", now), "A", s})
	history[2] = history[1]
	history[1] = line
end


local function after(dt, fn) tasks[#tasks + 1] = {at = now + dt, fn = fn} end

local function run_tasks()
	local due = {}
	for i = #tasks, 1, -1 do
		if tasks[i].at <= now + 1e-9 then
			due[#due + 1] = tasks[i]
			table.remove(tasks, i)
		end
	end
	table.sort(due, function(a, b) return a.at < b.at end)
	for _, t in ipairs(due) do t.fn() end
end




local RADAR_MODE_STT = 3
local function locked() return num(radar_mode) == RADAR_MODE_STT end

local function xy(range, az) return range * math.cos(az), range * math.sin(az) end


local function hold_gate()
	tdc_caret:set(LOCK_STEPS[gate_step].caret)
	acq_az:set(LOCK_STEPS[gate_step].acq)
end

local function poll_contacts()
	hold_gate()
	contacts = {}
	for i = 1, MAX_CONTACTS do
		local r = num(slots[i].RANGE)
		if r > 0 then
			contacts[#contacts + 1] = {slot = i, range = r, az = num(slots[i].AZIMUTH), el = num(slots[i].ELEVATION),
				nctr = str(slots[i].NCTR), time = num(slots[i].TIME)}
		end
	end





	if cursor and (cursor.acm or cursor.trk) then
		tdc_az:set(cursor.baz or cursor.az)
		tdc_range:set(cursor.range)
	elseif cursor then
		local cx, cy = xy(cursor.range, cursor.az)
		local best = nil
		for _, c in ipairs(contacts) do
			local x, y = xy(c.range, c.az)
			local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
			if c.time >= 0 and d < CURSOR_MAX_JUMP and (not best or c.time < best.time) then best = c end
		end
		if best then
			if cursor.lost then act(string.format("cursor contact found again, slot %02d", best.slot)) end

			if best.slot ~= cursor.slot and not cursor.lost and now - (S4.slot_log_t or -1e9) >= 5 then
				S4.slot_log_t = now
				act(string.format("cursor contact moved slot %02d -> %02d", cursor.slot, best.slot))
			end
			cursor = {slot = best.slot, range = best.range, az = best.az, el = best.el, nctr = best.nctr, lost = false}
		elseif not cursor.lost then
			cursor.lost = true
			act(string.format("cursor contact lost (slot %02d)", cursor.slot))
		end
		tdc_az:set(cursor.az)
		tdc_range:set(cursor.range)
	end
end

local function next_contact()
	local live = {}
	for _, c in ipairs(contacts) do if c.time >= 0 then live[#live + 1] = c end end
	if #live == 0 then act("NEXT: no contacts") return end
	local pick = live[1]
	if cursor then
		for _, c in ipairs(live) do
			if c.slot > cursor.slot then pick = c break end
		end
	end
	cursor = {slot = pick.slot, range = pick.range, az = pick.az, el = pick.el, nctr = pick.nctr, lost = false}
	tdc_az:set(cursor.az)
	tdc_range:set(cursor.range)
	act(string.format("NEXT: cursor slot %02d %.1f nm az %.1f el %.1f %s", pick.slot, pick.range / M_PER_NM,
		pick.az * RAD_TO_DEG, pick.el * RAD_TO_DEG, pick.nctr))
end


local function link() return math.floor(num(link_state) + 0.5) end
local function link_present() return link() >= 1 end
local function link_name() return LINK_NAMES[link()] or tostring(link()) end




local DLINK = dofile(LockOn_Options.script_path.."Systems/datalink.lua").init()



function atk_dt.type_of(t)
	local s = t.dl and (t.id == DLINK.FRIEND and t.name or "") or t.type
	if s == nil or s == "UNK" or tonumber(s) then return "" end
	return s
end


local function track_of(number)
	for _, t in ipairs(tracks) do if t.number == number then return t end end
	return DLINK.get(number)
end
















local IFF = {RANGE_NM = 300.0, DELAY = 1.0, UNK = 0, FRIEND = 1, NO_REPLY = 2, own = nil, st = {}, ROWS = 8,
	on_p = param("IFF_ON"), auto_p = param("IFF_AUTO"), intg_p = param("IFF_INTG_N"), intg_seen = 0,
	pub = {n = param("IFF_N"), num = {}, res = {}, row = {}, rows = param("IFF_ROWS"), cnt = {}},
	TXT = {[0] = "UNKNOWN", [1] = "FRIEND", [2] = "NO REPLY"}}
for k = 1, IFF.ROWS do IFF.pub.row[k] = param(string.format("IFF_ROW_%d", k)) end
for k, s in pairs({[0] = "U", [1] = "F", [2] = "N"}) do IFF.pub.cnt[k] = param("IFF_CNT_"..s) end


for k = 1, MAX_TRACKS do
	IFF.pub.num[k] = param(string.format("IFF_%02d_NUM", k))
	IFF.pub.res[k] = param(string.format("IFF_%02d_RES", k))
end
function IFF.publish()
	local n = math.min(#tracks, MAX_TRACKS)
	for k = 1, n do
		IFF.pub.num[k]:set(tracks[k].number)
		IFF.pub.res[k]:set(tracks[k].iff or IFF.UNK)
	end
	IFF.pub.n:set(n)

	local by, cnt = {}, {[0] = 0, [1] = 0, [2] = 0}
	for k = 1, n do
		by[k] = tracks[k]
		local r = tracks[k].iff or IFF.UNK
		cnt[r] = cnt[r] + 1
	end
	table.sort(by, function(a, b) return a.range < b.range end)
	for k = 1, IFF.ROWS do
		local t = by[k]
		if t then
			local b = math.floor(math.deg(t.brg) + 0.5)
			IFF.pub.row[k]:set(string.format("%02d  %-8s %5.1f NM  %s%03d", t.number % 100, IFF.TXT[t.iff or IFF.UNK],
				t.range / M_PER_NM, b < 0 and "L" or "R", math.abs(b)))
		else
			IFF.pub.row[k]:set(" ")
		end
	end
	IFF.pub.rows:set(math.min(n, IFF.ROWS))
	for r, h in pairs(IFF.pub.cnt) do h:set(cnt[r]) end
end
function IFF.set_own(value)
	local c = math.floor(value + 0.5)
	if c ~= IFF.own then
		act(string.format("IFF: own coalition %d", c))
		IFF.own = c
	end
end
function IFF.update()
	if num(IFF.on_p) < 0.5 then
		if next(IFF.st) then act("IFF: off, answers cleared") end
		IFF.st = {}
		for _, t in ipairs(tracks) do t.iff = IFF.UNK end
		IFF.publish()
		return
	end
	local seen = {}
	local auto = math.floor(num(IFF.auto_p) + 0.5)
	local intg = num(IFF.intg_p) ~= IFF.intg_seen
	if intg then
		IFF.intg_seen = num(IFF.intg_p)
		act("IFF: INTG")
	end
	for _, t in ipairs(tracks) do
		seen[t.number] = true
		local e = IFF.st[t.number]
		if not e then e = {t0 = nil, res = IFF.UNK} IFF.st[t.number] = e end
		local in_fan = t.range <= IFF.RANGE_NM * M_PER_NM and math.abs(t.brg) <= math.rad(ATK_AZ_MAX) + 1e-9
		if intg and in_fan then e.res, e.t0, e.ask = IFF.UNK, nil, true end

		local want = e.ask or auto <= 1 or (auto == 2 and (t.number == dt or t.stt))
		if e.res == IFF.UNK and IFF.own and in_fan and want then
			if not e.t0 then
				e.t0 = now
			elseif now - e.t0 >= IFF.DELAY - 1e-9 then
				e.res, e.ask = t.coal == IFF.own and IFF.FRIEND or IFF.NO_REPLY, nil
				act(string.format("IFF %02d %s (coal %d)", t.number, e.res == IFF.FRIEND and "FRIEND" or "NO REPLY", t.coal))
			end
		end
		t.iff = e.res
	end
	for number in pairs(IFF.st) do if not seen[number] then IFF.st[number] = nil end end
	IFF.publish()
end


local NCTR = dofile(LockOn_Options.script_path.."Systems/nctr_names.lua")

local function poll_tracks()
	tracks = {}
	DLINK.list = {}
	if not link_present() then IFF.publish() return end
	local n = math.min(math.floor(num(trk_count) + 0.5), MAX_TRACKS)
	for i = 1, n do
		local s = trk_slots[i]
		local number = math.floor(num(s.NUM) + 0.5)
		if number > 0 then
			tracks[#tracks + 1] = {slot = i, number = number, range = num(s.RANGE), brg = num(s.BRG), elev = num(s.ELEV),
				closure = num(s.CLOSURE), coal = math.floor(num(s.COAL) + 0.5), coast = num(s.COAST) == 1,
				asked = num(s.ASKED) == 1, type = NCTR.show(str(s.TYPE)), lock = num(s.LOCK) == 1, stt = num(s.STT) == 1,
				hdg = num(s.HDG), gs = num(s.GS), link = math.floor(num(s.DL) + 0.5), wf = math.floor(num(s.WF) + 0.5)}
		end
	end
	IFF.update()
	DLINK.poll(IFF.own, true)

	local h = DLINK.handoff()
	if DLINK.is_dl(dt) and h > 0 then
		for _, t in ipairs(tracks) do
			if t.number == h then
				act(string.format("DT %03d handed to radar track %02d", dt, h))
				dt = h
				dt_trk:set(dt)
				break
			end
		end
	end
	hits = {}
	local nh = math.min(math.floor(num(hit_count) + 0.5), MAX_HITS)
	for i = 1, nh do
		local s = hit_slots[i]
		local r = num(s.RANGE)
		if r > 0 then
			hits[#hits + 1] = {slot = i, number = math.floor(num(s.NUM) + 0.5), range = r, brg = num(s.BRG),
				elev = num(s.ELEV), age = num(s.AGE)}
		end
	end


	if cursor and (cursor.acm or cursor.trk) then
		local t = track_of(cursor.acm or cursor.trk)
		if t then
			cursor.range, cursor.az, cursor.el = t.range, t.brg, t.elev
			tdc_az:set(cursor.baz or cursor.az)
			tdc_range:set(cursor.range)
		elseif cursor.trk then
			act(string.format("lock cursor: track %02d gone, back to the contacts", cursor.trk))
			cursor.trk = nil
		end
	end

	if dt ~= 0 and not track_of(dt) then
		act(string.format("DT %02d dropped (track gone)", dt))
		dt = 0
		dt_trk:set(0)
	end

	for i = #prio, 1, -1 do
		if not track_of(prio[i]) then
			act(string.format("PRIO %02d dropped (track gone)", prio[i]))
			table.remove(prio, i)
		end
	end
end


local function cursor_to_track(pick)
	local px, py = xy(pick.range, pick.brg)
	local best, best_d = nil, DT_CURSOR_RANGE
	for _, c in ipairs(contacts) do
		local x, y = xy(c.range, c.az)
		local d = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
		if c.time >= 0 and d < best_d and math.abs(c.az - pick.brg) <= DT_CURSOR_AZ then best, best_d = c, d end
	end
	if best then
		cursor = {slot = best.slot, range = best.range, az = best.az, el = best.el, nctr = best.nctr, lost = false}
		tdc_az:set(cursor.az)
		tdc_range:set(cursor.range)
	end
	return best
end









local SOI = {fmt = param("DISP_SOI_FMT"), ATTACK = 1, TEWS = 3, SITP = 5, HSI = 6,
	sitp = {x = 0, y = SITP_RS / 2}, sitp_rng = param("SITP_RNG"),
	cur = {X = param("SITP_CUR_X"), Y = param("SITP_CUR_Y"), V = param("SITP_CUR_V")},
	rng = {N = param("SOI_RNG_N"), D = param("SOI_RNG_D"), F = param("SOI_RNG_F")},

	tdc = {X = param("SOI_TDC_X"), Y = param("SOI_TDC_Y"), N = param("SOI_TMS_N"), D = param("SOI_TMS_D"), n = 0,
		fmt = param("SOI_HOTAS_FMT"),


		EL = param("SOI_EL_AX"), ELN = param("SOI_EL_N"), eln = 0,

		ELR = param("SOI_EL_RATE")}}


local function range_nm() return RANGE_SCALES[range_idx] end
local function scale_m() return range_nm() * M_PER_NM end

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end


local function acq_polar()
	local dx, dy = S4.acq.x - ATK_O_X, S4.acq.y - ATK_O_Y
	return math.sqrt(dx * dx + dy * dy), math.deg(math.atan2(dx, dy))
end

local function acq_set_polar(r, b)
	r, b = clamp(r, 0, ATK_R), clamp(b, -ATK_AZ_MAX, ATK_AZ_MAX)
	S4.acq.x, S4.acq.y = ATK_O_X + r * math.sin(math.rad(b)), ATK_O_Y + r * math.cos(math.rad(b))
end

local function acq_range() local r = acq_polar() return r / ATK_R * scale_m() end
local function acq_brg() local _, b = acq_polar() return b end

local function send_controls()
	rdr_plan:set(0)
	rdr_az_ofs:set(0)
	P4.az_half:set(K4.WIDTHS[S4.width].half)
	P4.el_half:set(K4.BARS[S4.bars].half)
	P4.az_ctr:set(acq_brg())
	rdr_el_ofs:set(el_ofs)

	rdr_band_range:set(math.max(M_PER_NM, acq_range()))
end


local function set_range(idx, why)
	idx = clamp(idx, 1, #RANGE_SCALES)
	if idx == range_idx then return false end
	local r, b = acq_polar()
	local m = r / ATK_R * scale_m()
	range_idx = idx
	acq_set_polar(m / scale_m() * ATK_R, b)
	act(string.format("RADAR range %d nm%s", range_nm(), why and (" ("..why..")") or ""))
	return true
end

local function control(command)
	if command == cmd.RdrWidth then
		S4.width = S4.width % #K4.WIDTHS + 1
		act("RADAR width "..K4.WIDTHS[S4.width].name)


		P4.msg:set(K4.WIDTHS[S4.width].name.." "..K4.BARS[S4.bars].name) S4.msg_until = now + K4.MSG_TIME
	elseif command == cmd.RdrBars then
		S4.bars = S4.bars % #K4.BARS + 1
		act("RADAR bars "..K4.BARS[S4.bars].name)
		P4.msg:set(K4.WIDTHS[S4.width].name.." "..K4.BARS[S4.bars].name) S4.msg_until = now + K4.MSG_TIME
	elseif command == cmd.RdrScanReset then
		if SOI.tms(command) then return true end
		el_ofs = 0
		act("RADAR elevation reset")
	elseif command == cmd.RdrRangeUp or command == cmd.RdrRangeDown then
		if SOI.range(command == cmd.RdrRangeUp) then return true end
		set_range(range_idx + (command == cmd.RdrRangeUp and 1 or -1))
	elseif command == cmd.RdrExp then
		if not SOI.tms(command) then SOI.exp_step() end
		return true
	else
		return false
	end
	send_controls()
	return true
end



local function shape(v)
	local a = math.abs(v)
	if a <= K4.TDC_DEADZONE then return 0 end
	return (v < 0 and -1 or 1) * ((math.min(a, 1) - K4.TDC_DEADZONE) / (1 - K4.TDC_DEADZONE)) ^ K4.TDC_EXP
end

local function slew(dt_s)
	local ix = clamp(shape(S4.axis.x) + S4.key.right - S4.key.left, -1, 1)
	local iy = clamp(shape(S4.axis.y) + S4.key.up - S4.key.down, -1, 1)
	if ix == 0 and iy == 0 then S4.bump_dir = 0 return end


	local rate = K4.TDC_RATE / SOI.k(SOI.ATTACK) * dt_s
	local nx, ny = S4.acq.x + ix * rate, S4.acq.y + iy * rate
	local dx, dy = nx - ATK_O_X, ny - ATK_O_Y
	local r = math.sqrt(dx * dx + dy * dy)
	local bump = 0
	if r > ATK_R and iy > 0 then bump = 1 elseif dy < 0 and iy < 0 then bump = -1 end
	if dy < 0 then r = 0 end
	acq_set_polar(r, math.deg(math.atan2(dx, dy)))


	if S4.bump_dir * iy <= 0 then S4.bump_dir = 0 end
	if bump ~= 0 and (bump ~= S4.bump_dir or now - S4.bump_t >= K4.BUMP_REPEAT - 1e-9) then
		S4.bump_dir, S4.bump_t = bump, now
		set_range(range_idx + bump, "cursor bump")
	end
end


local function ant_elev(v)
	if S4.ant and math.abs(v - S4.ant) < 0.004 then return end
	S4.ant = v
	if SOI.hotas_page() then
		local t = SOI.tdc
		t.eln = t.eln + 1
		t.EL:set(clamp(v, -1, 1))
		t.ELN:set(t.eln)
		return
	end
	el_ofs = clamp(v, -1, 1) * K4.EL_AXIS_DEG
end

local function flash(s)
	P4.msg:set(s)
	S4.msg_until = now + K4.MSG_TIME
end







local RSW = {silent = param("RDR_SILENT"), on = param("ATK_RDR_ON"), req = param("RDR_PWR_REQ"), seen = 0,

	lock_try = param("RDR_LOCK_TRY"), lock_ovr = param("RDR_LOCK_OVR")}
function RSW.is_on() return num(RSW.silent) < 0.5 end
local function set_power(on, why)
	radar_power:set(1)
	RSW.silent:set(on and 0 or 1)
	RSW.on:set(on and 1 or 0)
	act("radar "..(on and "ON" or "OFF")..(why and (" ("..why..")") or ""))
end


local function stt_vs_cursor()
	if not cursor then return "no cursor to compare" end

	local body = cursor.baz ~= nil
	local dr, da = num(stt_range) - cursor.range, num(stt_az) - (body and cursor.baz or cursor.az)
	local on = math.abs(dr) <= ON_CURSOR_RANGE and math.abs(da) <= ON_CURSOR_AZ
	return string.format("%s (dR %+.1f km, dAz %+.1f deg%s)", on and "ON the cursor's contact" or "NOT the cursor's contact",
		dr / 1000, da * RAD_TO_DEG, body and string.format(", body; dEl %+.1f", (num(stt_el) - cursor.bel) * RAD_TO_DEG) or "")
end



local function lock(tag, first, gave_up)
	if not RSW.is_on() then flash("RADAR OFF") act(tag.." LOCK: radar off") return false end
	if not cursor then act(tag.." LOCK: no cursor") return false end
	lock_seq = lock_seq + 1
	local id = lock_seq
	local i = first or gate_step

	local tn = cursor.acm or cursor.trk or dt
	RSW.lock_try:set(tn)
	local function try_step()
		if not cursor then RSW.lock_try:set(0) act(tag.." LOCK: cursor gone") return end
		gate_step = i
		hold_gate()
		tdc_az:set(cursor.baz or cursor.az)
		tdc_range:set(cursor.range)
		tdc_hold = now + LOCK_HOLD + LOCK_STEP_TIME
		dispatch_action(nil, LOCK_START)
		after(LOCK_HOLD, function() dispatch_action(nil, LOCK_FINISH) end)
		act(string.format("%s LOCK step %d: caret %.0f km acq %.0f deg, 509 on slot %02d %.1f nm", tag, i,
			LOCK_STEPS[i].caret / 1000, LOCK_STEPS[i].acq * RAD_TO_DEG, cursor.slot, cursor.range / M_PER_NM))
		local t0 = now
		local function watch()
			if id ~= lock_seq then return end
			if locked() then
				RSW.lock_try:set(0)
				act(string.format("%s STT up at step %d after %.1f s, %s", tag, i, now - t0, stt_vs_cursor()))
			elseif now - t0 >= LOCK_STEP_TIME - 1e-9 then
				if i < #LOCK_STEPS then
					i = i + 1
					try_step()
				else
					gate_step = 1
					RSW.lock_try:set(0)
					act(string.format("%s LOCK: no STT at any gate step (track %02d)", tag, tn))
					if gave_up then gave_up() end
				end
			else
				after(0.1, watch)
			end
		end
		after(0.1, watch)
	end
	try_step()
	return true
end

local function unlock(tag)
	RSW.lock_try:set(0)
	lock_seq = lock_seq + 1
	local id = lock_seq
	dispatch_action(nil, SENSOR_RESET)
	act(tag.." UNLOCK: SensorReset (1635)")
	after(UNLOCK_CHECK, function()

		if id ~= lock_seq then act(tag.." UNLOCK: a newer lock / unlock since, no check") return end
		if not locked() then
			act(tag.." UNLOCK: STT down after SensorReset")
			return
		end
		act(tag.." UNLOCK: STT still up, radar power cycle")
		cycling = true
		radar_power:set(0)
		after(POWER_CYCLE_OFF, function()
			cycling = false
			radar_power:set(1)
			after(0.3, function() act(tag.." UNLOCK: after power cycle STT "..(locked() and "UP" or "down")) end)
		end)
	end)
end


function SOI.page() return math.floor(num(SOI.fmt) + 0.5) end
function SOI.radar() local p = SOI.page() return p == SOI.ATTACK or p == SOI.SITP end

function SOI.acq() return SOI.page() == SOI.SITP and SOI.sitp or S4.acq end

function SOI.xy(t)
	if SOI.page() == SOI.SITP then
		local s = num(SOI.sitp_rng) * M_PER_NM
		if s <= 0 or t.range < 0 then return nil end
		local x, y = ew_xy(t.brg, t.range / s * SITP_RS)
		if not sitp_inside(x, y) then return nil end
		return x, y
	end
	return atk_xy(t.range, t.brg, scale_m())
end


SOI.bump_dir, SOI.bump_t = 0, -1
function SOI.bump(b, iy)
	if SOI.bump_dir * iy <= 0 then SOI.bump_dir = 0 end
	if b ~= 0 and (b ~= SOI.bump_dir or now - SOI.bump_t >= K4.BUMP_REPEAT - 1e-9) then
		SOI.bump_dir, SOI.bump_t = b, now
		SOI.range(b > 0)
	end
end




SOI.off_base, SOI.dctr = SITP_OFF, get_param_handle("SITP_DCTR")
function SOI.sync_off()
	SITP_OFF = num(SOI.dctr) > 0.5 and 0 or SOI.off_base
end
function SOI.slew(dt_s)
	SOI.sync_off()
	local ix = clamp(shape(S4.axis.x) + S4.key.right - S4.key.left, -1, 1)
	local iy = clamp(shape(S4.axis.y) + S4.key.up - S4.key.down, -1, 1)
	local c = SOI.sitp
	local rate = K4.TDC_RATE / SOI.k(SOI.SITP) * dt_s
	c.x, c.y = c.x + ix * rate, c.y + iy * rate
	local dy = c.y - SITP_OFF
	local r = math.sqrt(c.x * c.x + dy * dy)
	local edge = r >= SITP_R
	if edge then c.x, c.y = c.x * SITP_R / r, SITP_OFF + dy * SITP_R / r end
	SOI.bump((edge and iy > 0 and dy > 0) and 1 or ((edge and iy < 0 and dy < 0) and -1 or 0), iy)
end

function SOI.tews_tdc()
	local iy = clamp(shape(S4.axis.y) + S4.key.up - S4.key.down, -1, 1)
	SOI.bump(iy >= 0.5 and 1 or (iy <= -0.5 and -1 or 0), iy)
end



function SOI.feed(ss)
	local ix, iy = 0, 0
	if SOI.hotas_page() and not ss then
		ix = clamp(shape(S4.axis.x) + S4.key.right - S4.key.left, -1, 1)
		iy = clamp(shape(S4.axis.y) + S4.key.up - S4.key.down, -1, 1)
	end
	SOI.tdc.X:set(ix)
	SOI.tdc.Y:set(iy)
end
function SOI.hotas_page()
	local p = SOI.page()
	return p > 0 and p ~= SOI.ATTACK and p ~= SOI.SITP and p ~= SOI.TEWS and p == math.floor(num(SOI.tdc.fmt) + 0.5)
end

function SOI.why(what)
	return string.format("%s: no radar page in command (soi fmt %d, hotas fmt %d)", what, SOI.page(),
		math.floor(num(SOI.tdc.fmt) + 0.5))
end
function SOI.tms(command)
	local d = ({[cmd.RdrTmsUp] = 1, [cmd.RdrTmsDown] = 2, [cmd.RdrTmsLeft] = 3, [cmd.RdrTmsRight] = 4, [cmd.RdrExp] = 5,
		[cmd.RdrScanReset] = 8})[command]
	if not d or not SOI.hotas_page() then return false end
	SOI.tdc.n = SOI.tdc.n + 1
	SOI.tdc.D:set(d)
	SOI.tdc.N:set(SOI.tdc.n)
	return true
end
function SOI.show(on)
	SOI.sync_off()
	SOI.cur.X:set(SOI.sitp.x)
	SOI.cur.Y:set(SOI.sitp.y)
	SOI.cur.V:set((on and SOI.page() == SOI.SITP) and 1 or 0)

	local e, k = SOI.exp.p, SOI.k(SOI.SITP)
	e.sitp:set(SOI.exp.sitp)
	e.sk:set(k)
	e.scx:set(SOI.sitp.x)
	e.scy:set(SOI.sitp.y)
	e.sdx:set(k > 1 and 0 or SOI.sitp.x)
	e.sdy:set(k > 1 and SITP_OFF or SOI.sitp.y)
	e.atk:set(SOI.exp.atk)
end







SOI.exp = {atk = 0, sitp = 0, p = {atk = param("ATK_EXP"), sitp = param("SITP_EXP"), sk = param("SITP_EXP_K"),
	scx = param("SITP_EXP_CX"), scy = param("SITP_EXP_CY"), sdx = param("SITP_CUR_DX"), sdy = param("SITP_CUR_DY")}}

function SOI.k(page)
	local lvl = page == SOI.SITP and SOI.exp.sitp or (page == SOI.ATTACK and SOI.exp.atk or 0)
	return lvl > 0 and ATK_EXP_K[lvl] or 1
end
function SOI.exp_step()
	local p = SOI.page()
	if p ~= SOI.ATTACK and p ~= SOI.SITP then act("EXP: no radar page in command") return end
	local key = p == SOI.SITP and "sitp" or "atk"
	SOI.exp[key] = (SOI.exp[key] + 1) % (#ATK_EXP_K + 1)
	act(string.format("EXP: %s %s", p == SOI.SITP and "SIT-P" or "ATTACK",
		SOI.exp[key] > 0 and string.format("EXP%d (x%d)", SOI.exp[key], ATK_EXP_K[SOI.exp[key]]) or "NORM"))
end


function SOI.atk_place(range, brg, scale)
	local px, py = atk_xy(range, brg, scale)
	if not px then return nil end
	if SOI.k(SOI.ATTACK) > 1 and atk_under_inset(px, py) then return nil, nil, px, py end
	return px, py, px, py
end



SOI.inset = {t = {}, l = {}, h = {}, nt = 0, nl = 0, nh = 0, cx = 0, cy = 0}
for i = 1, ATK_EXP_TRACKS do
	SOI.inset.t[i] = {}
	for _, f in ipairs({"X", "Y", "V", "H", "L", "D", "I"}) do SOI.inset.t[i][f] = param(string.format("ATK_E%02d_%s", i, f)) end
end
for i = 1, ATK_EXP_DL do
	SOI.inset.l[i] = {}
	for _, f in ipairs({"X", "Y", "V", "H", "L", "D"}) do SOI.inset.l[i][f] = param(string.format("ATK_EL%02d_%s", i, f)) end
end
for i = 1, ATK_EXP_HITS do
	SOI.inset.h[i] = {}
	for _, f in ipairs({"X", "Y", "V"}) do SOI.inset.h[i][f] = param(string.format("ATK_EH%02d_%s", i, f)) end
end

function SOI.inset_begin(cx, cy)
	local s = SOI.inset
	s.cx, s.cy, s.nt, s.nl, s.nh = cx, cy, 0, 0, 0
end

function SOI.inset_slot(kind, px, py)
	local k = SOI.k(SOI.ATTACK)
	if k == 1 or not px then return nil end
	local x, y = atk_exp_xy(px, py, k, SOI.inset.cx, SOI.inset.cy)
	if not x then return nil end
	local s = SOI.inset
	local key, list, max = ({T = "nt", L = "nl", H = "nh"})[kind], ({T = s.t, L = s.l, H = s.h})[kind],
		({T = ATK_EXP_TRACKS, L = ATK_EXP_DL, H = ATK_EXP_HITS})[kind]
	if s[key] >= max then return nil end
	s[key] = s[key] + 1
	local h = list[s[key]]
	h.X:set(x) h.Y:set(y)
	return h
end

function SOI.inset_end()
	local s = SOI.inset
	for i = s.nt + 1, ATK_EXP_TRACKS do s.t[i].V:set(0) s.t[i].D:set(0) end
	for i = s.nl + 1, ATK_EXP_DL do s.l[i].V:set(0) s.l[i].D:set(0) end
	for i = s.nh + 1, ATK_EXP_HITS do s.h[i].V:set(0) end
end
function SOI.inset_hide()
	SOI.inset_begin(0, 0)
	SOI.inset_end()
	SOI.inset_line(SOI.inset.dt)
	for _, h in ipairs(SOI.inset.fm) do SOI.inset_line(h) end
end


SOI.inset.dt = {X = param("ATK_EDT_X"), Y = param("ATK_EDT_Y"), L = param("ATK_EDT_L")}
SOI.inset.fm = {}
for k = 1, Keys.MslSlots do
	SOI.inset.fm[k] = {}
	for _, f in ipairs({"X", "Y", "B", "L"}) do SOI.inset.fm[k][f] = param(string.format("ATK_EFM%02d_%s", k, f)) end
end
function SOI.inset_line(h, px, py, brg, short)
	local k = SOI.k(SOI.ATTACK)
	local sx, sy, len
	if k > 1 and px then sx, sy, len = atk_exp_line(px, py, k, SOI.inset.cx, SOI.inset.cy, short) end
	if not sx then h.L:set(0) return end
	local mx, my = atk_exp_line_move(sx, sy, brg)
	h.X:set(mx) h.Y:set(my)
	if h.B then h.B:set(brg) end
	h.L:set(math.min(ATK_EXP_PIECES, math.floor(len / (ATK_R / ATK_DT_PIECES))))
end


SOI.band_dy, SOI.band_dv = param("ATK_BAND_DY"), param("ATK_BAND_DV")


SOI.rng_nm = param("RDR_RANGE_NM")
SOI.wez = {src = {v = param("HUDAA_DLZ_V")}, h = {}}
for _, n in ipairs({"V", "W", "RC", "CV", "AN", "LO", "HI"}) do SOI.wez.h[n] = param("ATK_Z_"..n) end
for _, n in ipairs({"AERO", "OPT", "PI", "MNVR", "TR", "MIN"}) do
	SOI.wez.h[n] = param("ATK_Z_"..n)
	SOI.wez.src[n] = param("HUDAA_WEZ_"..n)
end
function SOI.wez_update(t, scale_m)
	local h, src = SOI.wez.h, SOI.wez.src
	if not t then h.V:set(0) h.W:set(0) h.CV:set(0) return end
	local function y(r) return ATK_Z_BOT + clamp(r / scale_m, 0, 1) * (ATK_Z_TOP - ATK_Z_BOT) end
	h.V:set(1)
	h.RC:set(y(t.range))
	h.CV:set(t.range <= scale_m and 1 or 0)
	if num(src.v) ~= 1 then h.W:set(0) return end


	for _, n in ipairs({"AERO", "OPT", "PI", "MNVR", "TR", "MIN"}) do
		h[n]:set(ATK_Z_BOT + math.max(num(src[n]) / scale_m, 0) * (ATK_Z_TOP - ATK_Z_BOT))
	end
	h.AN:set(math.floor(num(src.AERO) / M_PER_NM + 0.5))
	local piece = (ATK_Z_TOP - ATK_Z_BOT) / ATK_Z_PIECES
	h.LO:set((y(num(src.MIN)) - ATK_Z_BOT) / piece)
	h.HI:set((y(num(src.TR)) - ATK_Z_BOT) / piece)
	h.W:set(1)
end

function SOI.range(up)
	local p = SOI.page()
	if p ~= SOI.TEWS and p ~= SOI.SITP and p ~= SOI.HSI then return false end
	SOI.rng.D:set(up and 1 or -1)
	SOI.rng.F:set(p)
	SOI.rng.N:set(num(SOI.rng.N) + 1)
	return true
end


local function prio_place(number)
	for i, n in ipairs(prio) do if n == number then return i end end
	return nil
end



local function on_fan()
	local list = {}
	for _, t in ipairs(tracks) do
		local px, py = SOI.xy(t)
		if px then list[#list + 1] = {t = t, x = px, y = py} end
	end
	return list
end



local function under_cursor()

	local best, best_d, a = nil, K4.CAPTURE_R / (SOI.page() == SOI.SITP and SOI.k(SOI.SITP) or 1), SOI.acq()
	for _, e in ipairs(on_fan()) do
		local d = math.sqrt((e.x - a.x) ^ 2 + (e.y - a.y) ^ 2)
		if d < best_d then best, best_d = e.t, d end
	end
	if best then return best end
	for _, t in ipairs(DLINK.list) do
		local px, py = SOI.xy(t)
		if px then
			local d = math.sqrt((px - a.x) ^ 2 + (py - a.y) ^ 2)
			if d < best_d then best, best_d = t, d end
		end
	end
	return best
end

local function designate(t, tag)
	dt = t.number
	dt_trk:set(dt)
	local best = cursor_to_track(t)
	act(string.format("%s: DT %02d %.1f nm az %.1f %s coal %d%s, cursor %s", tag, dt, t.range / M_PER_NM,
		t.brg * RAD_TO_DEG, t.type, t.coal, t.coast and " COAST" or "",
		best and string.format("slot %02d", best.slot) or "unchanged (no contact near the DT)"))
end

local function tms_up()
	local t = under_cursor()
	if not t then act("TMS UP: no track under the cursor") return end
	if t.number ~= dt then designate(t, "TMS UP") return end
	if t.dl then
		flash("DL TRACK")
		act(string.format("TMS UP: DT %03d is a DL track (%s): the radar is cued to it, no lock", dt, DLINK.label(t)))
		return
	end
	if locked() then act(string.format("TMS UP: DT %02d already STT", dt)) return end
	if running then act("busy with test "..running..": TMS UP ignored") return end
	if not t.lock then
		flash("NOT LOCKABLE")
		act(string.format("TMS UP: DT %02d not lockable (%.1f nm)", dt, t.range / M_PER_NM))
		return
	end
	if not cursor_to_track(t) then
		if num(RSW.lock_ovr) < 0.5 then
			flash("NO CONTACT")
			act(string.format("TMS UP: DT %02d, no radar contact near it", dt))
			return
		end


		cursor = {slot = 0, range = t.range, az = t.brg, el = t.elev, nctr = t.type, lost = false, trk = t.number}
		tdc_az:set(cursor.az)
		tdc_range:set(cursor.range)
		act(string.format("TMS UP: DT %02d, no radar contact near it: locking on the track (%.1f nm)", dt,
			t.range / M_PER_NM))
	end
	lock("TMS")
end

local function tms_down()
	if locked() then
		unlock("TMS")
	elseif dt ~= 0 then
		act(string.format("TMS DOWN: DT %02d dropped", dt))
		dt = 0
		dt_trk:set(0)
	elseif #prio > 0 then
		prio = {}
		act("TMS DOWN: priority list cleared")
	else
		act("TMS DOWN: nothing to undo")
	end
end



local function tms_right()
	local fan = on_fan()
	local order = {}
	for _, n in ipairs(prio) do
		for _, e in ipairs(fan) do if e.t.number == n then order[#order + 1] = e end end
	end
	for _, e in ipairs(fan) do
		if not prio_place(e.t.number) then order[#order + 1] = e end
	end
	if #order == 0 then act("TMS RIGHT: no track on the fan") return end
	local pick = order[1]
	for i, e in ipairs(order) do
		if e.t.number == dt then pick = order[i % #order + 1] break end
	end
	local a = SOI.acq()
	a.x, a.y = pick.x, pick.y
	designate(pick.t, "TMS RIGHT")
end

local function tms_left()
	local t = under_cursor() or (dt ~= 0 and track_of(dt)) or nil
	if not t then act("TMS LEFT: no track under the cursor and no DT") return end
	if t.dl then
		flash("DL TRACK")
		act(string.format("TMS LEFT: %03d is a DL track, not for the priority list", t.number))
		return
	end
	local i = prio_place(t.number)
	if i then
		table.remove(prio, i)
		act(string.format("TMS LEFT: %02d off the priority list", t.number))
	elseif #prio >= K4.MAX_PRIO then
		flash("LIST FULL")
		act(string.format("TMS LEFT: list full (%d), %02d not added", K4.MAX_PRIO, t.number))
	else
		prio[#prio + 1] = t.number
		act(string.format("TMS LEFT: %02d priority %d", t.number, #prio))
	end
end


local function hotas(command, value)
	if command == cmd.RdrTdcX then S4.axis.x = value
	elseif command == cmd.RdrTdcY then S4.axis.y = value
	elseif command == cmd.RdrAntElev then ant_elev(value)
	elseif command == cmd.RdrElUp then S4.key.el_up = value > 0 and 1 or 0
	elseif command == cmd.RdrElDown then S4.key.el_dn = value > 0 and 1 or 0
	elseif command == cmd.RdrTdcUp then S4.key.up = value > 0 and 1 or 0
	elseif command == cmd.RdrTdcDown then S4.key.down = value > 0 and 1 or 0
	elseif command == cmd.RdrTdcLeft then S4.key.left = value > 0 and 1 or 0
	elseif command == cmd.RdrTdcRight then S4.key.right = value > 0 and 1 or 0
	elseif command == cmd.RdrTmsUp or command == cmd.RdrTmsDown or command == cmd.RdrTmsLeft
			or command == cmd.RdrTmsRight then
		if value == 0 then return true end
		if SOI.tms(command) then return true end
		if not link_present() then act("TMS: no radar link") return true end
		if not SOI.radar() then act(SOI.why("TMS")) return true end
		if command == cmd.RdrTmsUp then tms_up()
		elseif command == cmd.RdrTmsDown then tms_down()
		elseif command == cmd.RdrTmsLeft then tms_left()
		else tms_right() end
	else
		return false
	end
	return true
end

















local ACM = {mode = 0, ss_el = -3.0, fwd_t = nil, fwd_long = false, busy = nil, retry_at = -1, was_locked = false,
	layer = false, last = 0, tms_t = nil, tms_long = false,
	TMS_LONG = 0.5,
	NAMES = {[0] = "", "SS", "BST", "LRBST", "VTS", "GUNS", "HMD"},
	SS = 1, BST = 2, LRBST = 3, VTS = 4, GUNS = 5, HMD = 6,
	LONG = 1.0,
	RETRY = 0.1,
	SS_EL = -3.0,
	SS_RATE = 20.0,
	MRAD_PER_DEG = 17.4533,
	p = {mode = param("RDR_ACM"), az = param("RDR_ACM_AZ"), el = param("RDR_ACM_EL"), trk = param("RDR_ACM_TRK"),
		legend = param("ATK_ACM"), hud_y = param("ACM_HUD_Y"), fam = param("SMS_FAM"), uncage = param("SRM_UNCAGE"),
		los_ok = param("HMD_LOS_OK"), los_az = param("HMD_LOS_AZ"), los_el = param("HMD_LOS_EL"),
		busy = param("RDR_ACM_BUSY")}}


function ACM.send()
	local m, p = ACM.mode, ACM.p
	local el, az = 0, 0
	if m == ACM.SS then el = ACM.ss_el
	elseif m == ACM.HMD then el, az = math.deg(num(p.los_el)), math.deg(num(p.los_az)) end
	p.mode:set(m)
	p.az:set(az)
	p.el:set(el)
	p.legend:set(ACM.NAMES[m])
	p.hud_y:set(m == ACM.SS and el * ACM.MRAD_PER_DEG or 0)
	p.busy:set(ACM.busy and 1 or 0)
end








ACM.SCAN_AZ_MAX = 60.0
ACM.ACM_RANGE = 10.0 * M_PER_NM





ACM.AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
ACM.sd = get_base_data()
ACM.LOCK_AZ_MAX = 90.0
function ACM.lock_body()
	if locked() or not (cursor and cursor.acm) then return nil end
	if ACM.mode == 0 then cursor.baz, cursor.bel = nil, nil return nil end
	local az, el = ACM.AA.body_angles(cursor.az, cursor.el or 0, ACM.sd.getPitch(), ACM.sd.getRoll())
	cursor.baz, cursor.bel = az, el
	return az, el
end
function ACM.scan_centre()
	if locked() then return end
	local baz = ACM.lock_body()
	if baz then
		local lim = math.rad(ACM.LOCK_AZ_MAX)
		tdc_az:set(clamp(baz, -lim, lim))
		return
	end
	if now < tdc_hold then return end
	local az, range
	if ACM.mode == ACM.HMD then az = math.deg(num(ACM.p.los_az))
	elseif ACM.mode ~= 0 then az = 0
	else az = num(rdr_scan_az) end
	if ACM.mode ~= 0 then range = ACM.ACM_RANGE
	elseif cursor and not cursor.lost then range = cursor.range
	else range = range_nm() * M_PER_NM / 2 end
	tdc_az:set(math.rad(clamp(az, -ACM.SCAN_AZ_MAX, ACM.SCAN_AZ_MAX)))
	tdc_range:set(range)
end

function ACM.stop_lock()
	if ACM.busy then lock_seq = lock_seq + 1 RSW.lock_try:set(0) end
	ACM.busy = nil
	if cursor and cursor.acm then cursor.acm = nil end
end

function ACM.set(m, why)
	if m == ACM.mode then return false end
	if m ~= 0 then
		if not link_present() then flash("NO RADAR LINK") act("ACM "..ACM.NAMES[m]..": no radar link") return false end
		if not RSW.is_on() then flash("RADAR OFF") act("ACM "..ACM.NAMES[m]..": radar off") return false end
		if locked() then act("ACM "..ACM.NAMES[m]..": inhibited in STT") return false end
		if m == ACM.HMD and num(ACM.p.los_ok) ~= 1 then flash("NO HEAD") act("ACM HMD: no helmet line of sight") return false end
	end
	local was = ACM.mode
	ACM.mode = m
	if m == 0 then ACM.layer = false elseif m ~= ACM.GUNS or ACM.layer then ACM.layer, ACM.last = true, m end
	ACM.retry_at = -1
	if m == ACM.SS then ACM.ss_el = ACM.SS_EL end
	ACM.stop_lock()
	act(string.format("ACM %s -> %s (%s)", was == 0 and "search" or ACM.NAMES[was], m == 0 and "search" or ACM.NAMES[m], why))
	ACM.send()
	return true
end


function ACM.short_fwd() ACM.set(ACM.mode == ACM.SS and ACM.BST or ACM.SS, "castle forward") end


function ACM.weapon(family)
	if family == "GUN" and ACM.mode == 0 and not locked() and link_present() and RSW.is_on() then
		ACM.set(ACM.GUNS, "weapon GUN")
	elseif family == "GUN" and ACM.layer and ACM.mode ~= ACM.GUNS and not locked() then
		ACM.set(ACM.GUNS, "weapon GUN")
	elseif family ~= "GUN" and ACM.mode == ACM.GUNS then
		if ACM.layer then ACM.set(ACM.SS, "weapon "..family) else ACM.set(0, "weapon "..family) end
	elseif family ~= "GUN" and ACM.layer and ACM.last == ACM.GUNS then
		ACM.last = ACM.SS
	end
end


function ACM.choose(m, why)
	if m == ACM.HMD and num(ACM.p.los_ok) ~= 1 then flash("NO HEAD") act("ACM HMD: no helmet line of sight") return end
	if locked() then
		ACM.layer, ACM.last = true, m
		act(string.format("ACM: STT broken for %s (%s)", ACM.NAMES[m], why))
		unlock("ACM")
		return
	end
	ACM.set(m, why)
end


function ACM.leave(why)
	local was = ACM.layer or ACM.mode ~= 0
	ACM.layer = false
	if locked() then unlock("ACM "..why) end
	if not ACM.set(0, why) and was then act("ACM -> search ("..why..")") end
end



function ACM.tms(command, value)
	if command == cmd.RdrTmsUp then
		if value > 0 then
			ACM.tms_t, ACM.tms_long = now, false
		elseif ACM.tms_t then
			local long = ACM.tms_long
			ACM.tms_t = nil
			if long then return true end
			if not link_present() then act("TMS: no radar link")
			elseif ACM.layer and locked() then
				act("TMS UP: ACM, already STT")
			elseif ACM.layer then
				local cur = ACM.mode ~= 0 and ACM.mode or ACM.last
				ACM.choose(cur == ACM.SS and ACM.BST or ACM.SS, "TMS up")
			elseif SOI.tms(command) then act("TMS UP: to the page in command")
			elseif not SOI.radar() then act(SOI.why("TMS"))
			else tms_up() end
		end
		return true
	end
	if not ACM.layer or (command ~= cmd.RdrTmsDown and command ~= cmd.RdrTmsLeft and command ~= cmd.RdrTmsRight) then
		return false
	end
	if value == 0 then return true end
	if command == cmd.RdrTmsDown then ACM.leave("TMS down")
	elseif command == cmd.RdrTmsRight then ACM.choose(ACM.VTS, "TMS right")
	else ACM.choose(ACM.HMD, "TMS left") end
	return true
end


function ACM.command(command, value)
	if command == cmd.RdrAcqFwd then
		if value > 0 then
			ACM.fwd_t, ACM.fwd_long = now, false
		elseif ACM.fwd_t then
			if not ACM.fwd_long then ACM.short_fwd() end
			ACM.fwd_t = nil
		end
		return true
	end
	if command ~= cmd.RdrAcqAft and command ~= cmd.RdrAcqDepress and command ~= cmd.RdrHmdAcq
			and command ~= cmd.SrmUncage then return false end
	if value == 0 then return true end
	if command == cmd.RdrAcqAft then
		ACM.set(ACM.VTS, "castle aft")
	elseif command == cmd.RdrAcqDepress then
		ACM.layer = false
		if locked() then unlock("ACM RTS") end
		if not ACM.set(0, "castle depress") then act("ACM: return to search") end
	elseif command == cmd.RdrHmdAcq then
		ACM.set(ACM.HMD, "HMD look and lock")
	else


		if str(ACM.p.fam) ~= "SRM" then flash("SRM NOT SEL") act("UNCAGE: SRM not selected") return true end
		local u = num(ACM.p.uncage) == 0 and -1 or 0
		ACM.p.uncage:set(u)
		act("SRM "..(u == -1 and "UNCAGE: HMD search" or "CAGE").." (key)")
	end
	return true
end


function ACM.slew(dt_s)
	local iy = clamp(shape(S4.axis.y) + S4.key.up - S4.key.down, -1, 1)
	ACM.ss_el = clamp(ACM.ss_el + iy * ACM.SS_RATE * dt_s, -19, 28)
end



function ACM.tick()
	if ACM.fwd_t and not ACM.fwd_long and now - ACM.fwd_t >= ACM.LONG - 1e-9 then
		ACM.fwd_long = true
		ACM.set(ACM.LRBST, "castle forward held")
	end
	if ACM.tms_t and not ACM.tms_long and now - ACM.tms_t >= ACM.TMS_LONG - 1e-9 then
		ACM.tms_long = true
		if not link_present() then act("TMS: no radar link")
		else ACM.choose(ACM.layer and ACM.LRBST or ACM.SS, "TMS up held") end
	end
	local lk = locked()
	if lk and ACM.mode ~= 0 then
		act(string.format("ACM %s: STT up, normal STT%s", ACM.NAMES[ACM.mode], ACM.layer and " (still in ACM)" or ""))
		ACM.mode = 0
		ACM.busy = nil
	elseif not lk and ACM.layer and ACM.mode == 0 and cycling then

	elseif not lk and ACM.layer and ACM.mode == 0 then

		local m = ACM.last ~= 0 and ACM.last or ACM.SS
		if m == ACM.HMD and num(ACM.p.los_ok) ~= 1 then m = ACM.SS end
		if m == ACM.GUNS and str(ACM.p.fam) ~= "GUN" then m = ACM.SS end
		if not ACM.set(m, ACM.was_locked and "STT down, back to ACM" or "ACM") then
			ACM.layer = false
			act("ACM: left (the mode can't start)")
		end
	elseif not lk and ACM.was_locked and ACM.mode == 0 and str(ACM.p.fam) == "GUN" then
		ACM.set(ACM.GUNS, "STT dropped, GUN selected")
	end
	ACM.was_locked = lk
	ACM.send()
end










ACM.zone = {stab = nil, el = nil, origin = param("SCAN_ZONE_ORIGIN_ELEVATION"), vol_az = param("SCAN_ZONE_VOLUME_AZIMUTH"),
	vol_el = param("SCAN_ZONE_VOLUME_ELEVATION"), pb = param("RADAR_PITCH_BANK_STABILIZATION"),
	pitch = param("RADAR_PITCH_STABILIZATION"), bank = param("RADAR_BANK_STABILIZATION"),
	VTS_EL = 30.0,
	EL_MIN = -40.0, EL_MAX = 60.0}
function ACM.scan_zone()
	local Z, m = ACM.zone, ACM.mode
	local stab, el = 1, num(rdr_scan_el)
	if m ~= 0 then
		stab = 0
		if m == ACM.SS then el = ACM.ss_el
		elseif m == ACM.VTS then el = Z.VTS_EL
		elseif m == ACM.HMD then el = math.deg(num(ACM.p.los_el))
		else el = 0 end
		local _, bel = ACM.lock_body()
		if bel then el = math.deg(bel) end
		el = clamp(el, Z.EL_MIN, Z.EL_MAX)
	end
	Z.pb:set(stab)
	Z.pitch:set(stab)
	Z.bank:set(stab)
	Z.origin:set(math.rad(el))
	if stab ~= Z.stab or (stab == 0 and m ~= Z.m) then
		act(string.format("scan zone: %s, origin el %+.0f deg (volume %.0f x %.0f deg as the radar holds it)",
			stab == 1 and "stabilised (search)" or ("aircraft-referenced (ACM "..ACM.NAMES[m]..")"), el,
			math.deg(num(Z.vol_az)), math.deg(num(Z.vol_el))))
	end
	Z.stab, Z.m = stab, m
end




function ACM.log_zone()
	local Z = ACM.zone
	local live, dead, newest = 0, 0, -1
	for _, c in ipairs(contacts) do
		if c.time >= 0 then
			live = live + 1
			if newest < 0 or c.time < newest then newest = c.time end
		else dead = dead + 1 end
	end
	local cur = cursor or {slot = 0, lost = false}
	local ct = -2
	for _, c in ipairs(contacts) do if c.slot == cur.slot then ct = c.time end end
	csv_row({string.format("%.3f", now), "Z", num(tdc_range), num(tdc_az), num(tdc_caret),
		string.format("%.1f", math.deg(num(Z.origin))), Z.stab or -1, string.format("%.0f", math.deg(num(Z.vol_az))),
		string.format("%.0f", math.deg(num(Z.vol_el))), ACM.mode == 0 and "search" or ACM.NAMES[ACM.mode],
		locked() and 1 or 0, cur.acm and "acm" or cur.slot, ct, cur.lost and 1 or 0, live, dead, newest})
end





function ACM.poll()
	if ACM.mode == 0 or locked() then return end
	if ACM.busy then
		if ACM.gave_up or now - ACM.busy >= LOCK_WAIT then
			act(string.format("ACM %s: no STT on DT %02d, searching again", ACM.NAMES[ACM.mode], dt))
			ACM.stop_lock()
			ACM.retry_at = now + ACM.RETRY
		end
		return
	end
	if now < ACM.retry_at then return end
	local n = math.floor(num(ACM.p.trk) + 0.5)
	local t = n > 0 and track_of(n)
	if not t then return end
	designate(t, "ACM "..ACM.NAMES[ACM.mode])
	cursor = {slot = 0, range = t.range, az = t.brg, el = t.elev, nctr = t.type, lost = false, acm = t.number}
	ACM.busy, ACM.gave_up = now, false
	ACM.p.busy:set(1)
	act(string.format("ACM %s: track %02d %.1f nm az %+.1f el %+.1f, locking on the track", ACM.NAMES[ACM.mode], n,
		t.range / M_PER_NM, math.deg(t.brg), math.deg(t.elev)))
	lock("ACM", 1, function() ACM.gave_up = true end)
end


local function station_info(i)
	local ok, s = pcall(dev.get_station_info, dev, i)
	if ok and type(s) == "table" then return s end
	return nil
end

local function amraam_stations()
	local list = {}
	for i = 0, MAX_STATIONS - 1 do
		local s = station_info(i)
		local w = s and s.weapon
		if w and (s.count or 0) > 0 then


			local name = (w.level3 == AA_MISSILE and AMRAAM[w.level4])
				or (tostring(s.CLSID or ""):find("120", 1, true) and "AIM-120 by CLSID")
			if name then list[#list + 1] = {station = i, count = s.count, name = name} end
		end
	end
	return list
end

local function aim120_left()
	local n = 0
	for _, s in ipairs(amraam_stations()) do n = n + s.count end
	return n
end

local function fire(tag)
	local list = amraam_stations()
	if #list == 0 then act(tag.." FIRE: no AIM-120 left") return false end
	local st = list[1].station
	local before = list[1].count
	dev:select_station(st)
	after(0.1, function()
		dev:launch_station(st)
		local target = cursor and string.format("cursor slot %02d %.1f nm %s%s", cursor.slot, cursor.range / M_PER_NM,
			cursor.nctr, cursor.lost and " (LOST)" or "") or "no cursor"
		act(string.format("%s LAUNCH station %d (%s), %s, STT %s", tag, st, list[1].name, target,
			locked() and string.format("UP %.1f nm", num(stt_range) / M_PER_NM) or "down"))
		after(0.5, function()
			local s = station_info(st)
			local left = s and s.count or 0
			act(string.format("%s station %d count %d -> %d%s", tag, st, before, left,
				left < before and "" or " (NOTHING LEFT THE RAIL)"))
		end)
	end)
	return true
end


local function wait_lock(tag, t0, then_fn)
	if locked() then
		act(string.format("%s STT up after %.1f s", tag, now - t0))
		then_fn()
	elseif now - t0 > LOCK_WAIT then
		act(string.format("%s no STT in %.1f s: aborted", tag, LOCK_WAIT))
		running = nil
	else
		after(0.1, function() wait_lock(tag, t0, then_fn) end)
	end
end

local function test_a()
	if locked() then act("A: needs no lock, unlock first") return end

	if link() == LINK_ARMED then
		if dt == 0 then act("A: no DT (NEXT first)") return end
		if num(dt_ok) ~= 1 then act(string.format("A: DT %02d not firm (no shoot cue)", dt)) return end
		local t = track_of(dt)
		act(string.format("A: fire on DT %02d, no lock (link ARMED)%s", dt,
			t and string.format(", %.1f nm %s", t.range / M_PER_NM, t.type) or ""))
		fire("A")
		return
	end
	if not cursor then act("A: no cursor (NEXT first)") return end
	act("A: fire on the cursor, no lock"..(link_present() and " (link "..link_name()..": stock shot)" or ""))
	fire("A")
end

local function test_b()
	running = "B"
	if not lock("B") then running = nil return end
	local t0 = now
	after(0.1, function() wait_lock("B", t0, function()
		if fire("B") then
			after(0.1 + B_UNLOCK_AFTER, function()
				unlock("B")
				after(1.0, function() running = nil end)
			end)
		else
			running = nil
		end
	end) end)
end

local function test_c()
	running = "C"
	if not lock("C") then running = nil return end
	local t0 = now
	after(0.1, function() wait_lock("C", t0, function()
		fire("C")
		after(0.2, function() running = nil end)
	end) end)
end








local S7 = {SMS = dofile(LockOn_Options.script_path.."Systems/sms.lua"), list = {}, busy_until = -1, pyl = {},
	ST = dofile(LockOn_Options.script_path.."Systems/stations.lua")}
S7.layout, S7.unit = S7.ST.current()
S7.SMS.use_layout(S7.layout, S7.ST.ORDER)



function S7.SMS.describe(clsid, w)
	if not S7.mdb then S7.mdb = dofile(LockOn_Options.script_path.."Systems/missile_lookup.lua") end
	return S7.mdb.describe(clsid, w)
end
S7.NPYLONS = S7.SMS.NPYLONS
S7.state = S7.SMS.new_state()
S7.p = {sel = param("SMS_SEL"), fam = param("SMS_FAM"), arm = param("SMS_ARM"), selp = param("SMS_SEL_PYLON"),
	chf = param("SMS_CHF"), flr = param("SMS_FLR"), cool = param("SMS_COOL"), gun = param("SMS_GUN"),
	clsid = param("SMS_SEL_CLSID"), wst = param("SMS_SEL_WST"),
	itop = param("SMS_SEL_ITOP"), icode = param("SMS_SEL_ICODE"), in_ = param("SMS_SEL_IN"),
	navpod = param("SMS_NAV_POD")}



S7.INV_W = 6
function S7.inv(s)
	s = string.sub(s or "", 1, S7.INV_W)
	local l = math.floor((S7.INV_W - #s) / 2)
	return string.rep("_", l)..s..string.rep("_", S7.INV_W - #s - l)
end
for i = 1, S7.NPYLONS do
	local pre = string.format("SMS_P%02d_", i)
	S7.pyl[i] = {TOP = param(pre.."TOP"), CODE = param(pre.."CODE"), N = param(pre.."N"), V = param(pre.."V")}
end



function S7.count_of(name)
	local f = dev[name]
	if type(f) ~= "function" then return -1 end
	local ok, v = pcall(f, dev)
	return (ok and tonumber(v)) or -1
end

function S7.poll()
	local SMS, st = S7.SMS, S7.state
	S7.list = SMS.scan(station_info)
	SMS.refresh(st, S7.list)
	S7.p.sel:set(SMS.selected_text(st, S7.list))
	S7.p.fam:set(st.family)
	S7.p.arm:set(st.armed and 1 or 0)
	S7.p.selp:set(st.family ~= "GUN" and st.station[st.family] or 0)
	local sel_e = st.family ~= "GUN" and st.station[st.family] and SMS.by_pylon(S7.list, st.station[st.family])
	S7.p.clsid:set(sel_e and sel_e.clsid or "")
	S7.p.wst:set(sel_e and sel_e.wst and ("w"..sel_e.wst) or "")
	S7.p.chf:set(S7.count_of("get_chaff_count"))
	S7.p.flr:set(S7.count_of("get_flare_count"))
	S7.p.cool:set(((SMS.totals(S7.list).SRM or 0) > 0) and (st.armed and 2 or 1) or 0)
	S7.p.gun:set(SMS.gun_rounds(st))
	S7.p.navpod:set(SMS.nav_pod(S7.list) and 1 or 0)
	for i = 1, S7.NPYLONS do
		local e, h = SMS.by_pylon(S7.list, i), S7.pyl[i]
		h.TOP:set(e and SMS.status(st, e) or "")
		h.CODE:set(e and (e.count > 0 and e.code or "") or "")
		h.N:set(e and e.count or 0)
		h.V:set(e and 1 or 0)
	end
	local top, code, n = "", "", ""
	if sel_e then
		top = SMS.status(st, sel_e)
		code = sel_e.count > 0 and sel_e.code or ""
		n = sel_e.count > 1 and string.format("x%d", sel_e.count) or ""
	end
	S7.p.itop:set(S7.inv(top))
	S7.p.icode:set(S7.inv(code))
	S7.p.in_:set(S7.inv(n))
end



function S7.select(family, why)
	local SMS, st = S7.SMS, S7.state
	S7.list = SMS.scan(station_info)
	SMS.refresh(st, S7.list)
	if family then SMS.press(st, S7.list, family) else SMS.cycle(st, S7.list) end
	family = st.family
	if family ~= "GUN" then S7.gun_up("weapon select "..family) end
	S7.mrm_cancel("weapon select "..family)
	S7.poll()
	ACM.weapon(family)
	act("WPN select "..family.." ("..why.."): "..SMS.selected_text(st, S7.list))
	S7.MM.set(S7.MM.AA, "weapon select "..family)
end







S7.MM = {AA = 1, AG = 2, NAV = 3, INST = 4, NAMES = {"A/A", "A/G", "NAV", "INST"}, CYCLE = {1, 3},
	p = param("MASTER_MODE"), mode = 3}

























































function S7.MM.set(m, why)
	local M = S7.MM
	if m == M.mode then return end
	act(string.format("MM %s -> %s (%s)", M.NAMES[M.mode], M.NAMES[m], why))
	M.mode = m
	M.p:set(m)
end
function S7.MM.command(command)
	local M = S7.MM

	if command == cmd.MmAA then M.set(M.AA, "A/A button")
	elseif command == cmd.MmNav then M.set(M.NAV, "NAV button")
	elseif command == cmd.MmCycle then
		local k = 1
		for i, m in ipairs(M.CYCLE) do if m == M.mode then k = i end end
		M.set(M.CYCLE[k % #M.CYCLE + 1], "cycle")
	else return false end
	return true
end




function S7.fire()
	local st, SMS = S7.state, S7.SMS

	if not st.armed then flash("SAFE") act("WPN FIRE: master arm SAFE") return end

	if st.family == "GUN" then act("WPN FIRE: GUN selected, the release does nothing (gun trigger)") return end
	if running then act("WPN FIRE: busy with test "..running) return end
	if now < S7.busy_until then act("WPN FIRE: launch in progress") return end
	local p = st.station[st.family]
	local e = p and SMS.by_pylon(S7.list, p)
	if not (e and e.count > 0) then flash("NO "..st.family) act("WPN FIRE: no "..st.family.." left") return end
	local how = "stock"
	local radar = SMS.RADAR[st.family]

	if e.seeker == "SARH" and not locked() then flash("NO STT") act("WPN FIRE: semi-active "..e.code.." needs STT") return end
	if radar and link() == LINK_ARMED and not locked() then
		if dt == 0 then flash("NO DT") act("WPN FIRE: no DT") return end
		if num(dt_ok) ~= 1 then flash("NO SHOOT CUE") act(string.format("WPN FIRE: DT %02d not firm", dt)) return end
		how = string.format("link, DT %02d", dt)
	elseif radar and locked() then
		how = string.format("STT %.1f nm", num(stt_range) / M_PER_NM)
	end
	local before, fam = e.count, st.family
	dev:select_station(e.station)
	if radar then


		S7.mrm = {e = e, before = before, how = how, t0 = now, fam = fam}
		S7.busy_until = now + S7.MRM_DELAY + 0.6
		act(string.format("WPN %s release held: pylon %d, launch in %.1f s if still held", fam, e.pylon, S7.MRM_DELAY))
		return
	end
	S7.busy_until = now + 0.6
	after(0.1, function() S7.launch(e, fam, before, how) end)
end

S7.MRM_DELAY = 0.5

function S7.mrm_tick()
	local m = S7.mrm
	if m and now - m.t0 >= S7.MRM_DELAY - 1e-9 then
		S7.mrm = nil
		S7.launch(m.e, m.fam, m.before, m.how)
	end
end

function S7.mrm_cancel(why)
	local m = S7.mrm
	if not m then return end
	S7.mrm = nil
	S7.busy_until = -1
	act(string.format("WPN %s cancelled after %.2f s (%s)", m.fam, now - m.t0, why))
end






function S7.srm_tick()
	local st, station, is9x = S7.state, nil, false
	if st.family == "SRM" and not S7.mrm and not running then
		local p = st.station.SRM
		local e = p and S7.SMS.by_pylon(S7.list, p)
		if e and e.count > 0 then station, is9x = e.station, e.code == "9X" or e.code == "9X2" or e.code == "P5" end
	end
	if station then dev:select_station(station) end
	SRM_WS_STATION:set(station or -1)
	SRM_WS_9X:set(is9x and 1 or 0)
	if station ~= S7.srm_station then
		act(station and string.format("SRM seeker: station %d selected every update", station) or "SRM seeker: no station")
		S7.srm_station = station
	end
end




S7.lp = {n = param("WPN_LAUNCH_N"), trk = param("WPN_LAUNCH_TRK"), act = param("WPN_LAUNCH_ACT"),
	sel_act = param("SMS_SEL_ACT_M"), count = 0}

function S7.launch(e, fam, before, how)
	local st, SMS = S7.state, S7.SMS
	dev:launch_station(e.station)
	act(string.format("WPN LAUNCH %s pylon %d (station %d) %s, %s", fam, e.pylon, e.station, e.code, how))
	if SMS.RADAR[fam] then
		local L = S7.lp
		L.count = L.count + 1
		L.trk:set(dt)
		L.act:set(num(L.sel_act))
		L.n:set(L.count)
	end
	after(0.5, function()
		local s = station_info(e.station)
		local left = s and s.count or 0
		act(string.format("WPN pylon %d count %d -> %d%s", e.pylon, before, left,
			left < before and "" or " (NOTHING LEFT THE RAIL)"))
		S7.list = SMS.scan(station_info)
		SMS.step(st, S7.list, fam, e.pylon)
		S7.poll()
	end)
end






S7.FIRE, S7.FIRE_OFF, S7.MODE_CANNON = 84, 85, 113
S7.sent_at = -1

function S7.send(command)
	S7.sent_at = now
	dispatch_action(nil, command)
end


function S7.gun_down(src)
	local st = S7.state
	if st.gun.firing then return end
	if S7.SMS.gun_rounds(st) <= 0 then flash("NO GUN") act("WPN GUN: empty ("..src..")") return end
	st.gun.firing = true
	S7.burst = {t0 = now, src = src, r0 = st.gun.rounds, echoes = 0}
	if src == "EX" then S7.send(S7.FIRE) end
	act(string.format("WPN GUN %s trigger down, %d rounds, family %s, %s", src, S7.SMS.gun_rounds(st), st.family,
		st.armed and "ARM" or "SAFE"))
end

function S7.gun_up(why)
	local st, b = S7.state, S7.burst
	if not (st.gun.firing and b) then return end
	st.gun.firing = false
	S7.burst = nil
	if b.src == "EX" then S7.send(S7.FIRE_OFF) end
	act(string.format("WPN GUN %s burst %.2f s, %.0f rounds counted, %d left (%s; %d echoes)", b.src, now - b.t0,
		b.r0 - st.gun.rounds, S7.SMS.gun_rounds(st), why, b.echoes))
	S7.poll()
end

function S7.gun_tick(dt)
	local b = S7.burst
	if not (S7.state.gun.firing and b) then return end
	if b.src == "EX" then S7.send(S7.FIRE) end
	if S7.SMS.gun_tick(S7.state, dt) then
		flash("GUN EMPTY")
		S7.gun_up("empty, counted")
	end
end


function S7.raw(command, value)
	local b = S7.burst
	if now == S7.sent_at then
		if b then b.echoes = b.echoes + 1 end
		return
	end
	local st = S7.state
	act(string.format("WPN STOCK %d (value %s), family %s, %s, gun %s", command, tostring(value), st.family,
		st.armed and "ARM" or "SAFE", st.gun.firing and ("firing ("..b.src..")") or "idle"))
	if command == S7.FIRE then S7.gun_down("stock")
	elseif command == S7.FIRE_OFF and b and b.src == "stock" then S7.gun_up("stock 85") end
end






S7.CM = {
	chaff = {fn = "drop_chaff", get = "get_chaff_count", disp = {0, 1}, n = 0},
	flare = {fn = "drop_flare", get = "get_flare_count", disp = {2, 3}, n = 0},
}


S7.wow = get_param_handle("EFM_WOW")

function S7.drop(kind)
	if S7.wow:get() > 0.5 then act("CM "..kind..": blocked, weight on wheels") return end
	local c = S7.CM[kind]
	local f = dev[c.fn]
	local before = S7.count_of(c.get)
	if type(f) ~= "function" then act("CM "..kind..": the weapon system has no "..c.fn) return end
	c.n = c.n + 1
	local n = c.n
	local d = c.disp[(n - 1) % #c.disp + 1]
	local ok, err = pcall(f, dev, 1, d)
	if before == 0 then flash(kind == "chaff" and "CHF 0" or "FLR 0") end
	after(0.2, function()
		act(string.format("CM %s #%d dispenser %d: count %d -> %d%s", kind, n, d, before, S7.count_of(c.get),
			ok and "" or (" ERROR "..tostring(err))))
		S7.poll()
	end)
end












S7.CMD = {M = dofile(LockOn_Options.script_path.."Systems/cmds.lua"), rwr = {}, alert = param("TEWS_ALERT"),
	out = {mode = param("CMD_MODE"), sel = param("CMD_SEL"), run = param("CMD_RUN"), ready = param("CMD_READY"),
		min = param("CMD_MIN"), ed_prog = param("CMD_ED_PROG"), ed_row = param("CMD_ED_ROW"), v = {},
		tot_c = param("CMD_TOT_C"), tot_f = param("CMD_TOT_F"), tot_t = param("CMD_TOT_T")},
	req = {n = param("CMD_REQ_N"), f = param("CMD_REQ_F"), v = param("CMD_REQ_V"), seen = nil},
	keys = {[cmd.CmdMan1] = "man1", [cmd.CmdMan2] = "man2", [cmd.CmdMode] = "mode", [cmd.CmdSel] = "sel"}}
for i = 1, #S7.CMD.M.FIELDS do S7.CMD.out.v[i] = param("CMD_V"..i) end
for i = 1, TEWS_MAX do
	local f = function(n) return param(string.format("RWR_CONTACT_%02d_%s", i, n)) end
	S7.CMD.rwr[i] = {sig = f("SIGNAL"), pw = f("POWER"), time = f("TIME"), gt = f("GENERAL_TYPE")}
end
do
	local birth = LockOn_Options.init_conditions and LockOn_Options.init_conditions.birth_place
	S7.CMD.st = S7.CMD.M.new(birth == "GROUND_COLD" and S7.CMD.M.OFF or S7.CMD.M.SEMI)
end


function S7.CMD.summary()
	local sig, pw, air = 0, -1, false
	for _, c in ipairs(S7.CMD.rwr) do
		local s, p = math.floor(num(c.sig) + 0.5), num(c.pw)
		if s >= 1 and p > 0 and num(c.time) >= 0 and (s > sig or (s == sig and p > pw)) then
			sig, pw, air = s, p, math.floor(num(c.gt) + 0.5) == 1
		end
	end
	return {sig = sig, air = air, alert = num(S7.CMD.alert)}
end

function S7.CMD.key(k)
	local C = S7.CMD
	local m = C.M.key(C.st, now, k, C.summary())
	if m then act(m) flash(m:sub(5)) end
	C.publish()
end


S7.CMD.REQ = {[1] = "prog", [2] = "row", [3] = "inc", [4] = "dec", [5] = "default", [8] = "row_next", [9] = "row_prev"}
function S7.CMD.requests()
	local C, R = S7.CMD, S7.CMD.req
	local n = num(R.n)
	if R.seen == nil then R.seen = n return end
	if n == R.seen then return end
	R.seen = n
	local f, v = math.floor(num(R.f) + 0.5), num(R.v)
	if f == 6 then C.key("mode") return end
	if f == 7 then C.key("sel") return end
	local m
	if f > 100 then
		C.st.ed.row = f - 100
		m = C.M.edit(C.st, "set", v)
	elseif C.REQ[f] then
		m = C.M.edit(C.st, C.REQ[f], math.floor(v + 0.5))
	end
	if m then act(m) end
end

function S7.CMD.tick()
	local C = S7.CMD
	C.requests()
	local counts = {chaff = S7.count_of("get_chaff_count"), flare = S7.count_of("get_flare_count")}
	local drops, m = C.M.tick(C.st, now, C.summary(), counts)
	if m then act(m) flash(m:sub(5)) end
	for _, d in ipairs(drops) do
		for _ = 1, d[2] do S7.drop(d[1]) end
	end
	C.publish()
end

function S7.CMD.publish()
	local C, st = S7.CMD, S7.CMD.st
	C.out.mode:set(st.mode)
	C.out.sel:set(st.sel)
	C.out.run:set(st.run and st.run.id or 0)
	C.out.ready:set(st.ready and st.prog[st.ready].id or 0)
	C.out.min:set(st.min and 1 or 0)
	local p = st.prog[st.ed.prog]
	C.out.ed_prog:set(p.id)
	C.out.ed_row:set(st.ed.row)
	for i, h in ipairs(C.out.v) do h:set(C.M.value(st, i)) end
	local tc, tf, tt = C.M.totals(p)
	C.out.tot_c:set(tc)
	C.out.tot_f:set(tf)
	C.out.tot_t:set(tt)
end

function S7.command(command)
	if command == cmd.CmChaff then S7.drop("chaff")
	elseif command == cmd.CmFlare then S7.drop("flare")
	elseif S7.CMD.keys[command] then S7.CMD.key(S7.CMD.keys[command])
	elseif command == cmd.WpnGun then S7.select("GUN", "key")
	elseif command == cmd.WpnSrm then S7.select("SRM", "key")
	elseif command == cmd.WpnMrm then S7.select("MRM", "key")
	elseif command == cmd.WpnCycle then S7.select(nil, "cycle")
	elseif command == cmd.WpnMasterArm then
		S7.state.armed = not S7.state.armed
		if not S7.state.armed then S7.gun_up("SAFE") S7.mrm_cancel("SAFE") end
		S7.poll()
		act("WPN master arm "..(S7.state.armed and "ARM" or "SAFE"))
	elseif command == cmd.WpnFire then S7.fire()
	elseif command == S7.JETT_TANKS then S7.jettison_tanks()
	elseif S7.MM.command(command) then
	else return false end
	return true
end



S7.JETT_TANKS = 178
function S7.jettison_tanks()
	S7.poll()
	local n = 0
	for _, e in ipairs(S7.list) do
		if e.family == "FUEL" and e.count > 0 then
			local ok, err = pcall(dev.emergency_jettison, dev, e.station)
			act(string.format("JETT tank pylon %d (%s)%s", e.pylon, e.clsid, ok and "" or (" ERROR "..tostring(err))))
			n = n + 1
		end
	end
	if n == 0 then act("JETT tanks: none fitted") end
	flash(n > 0 and "JETT TANKS" or "NO TANKS")
	after(0.5, S7.poll)
end


function S7.start()
	S7.poll()
	act(string.format("SMS layout %s, %d pylons", S7.unit, S7.NPYLONS))
	for _, e in ipairs(S7.list) do
		local r = S7.layout[e.pylon]
		act(string.format("SMS pylon %d (%s) %s %s x%d (%s)", e.pylon, r and r.label or "?", e.family, e.code, e.count,
			e.clsid))
	end
	local names, seen = {}, {}
	local function add(t)
		if type(t) ~= "table" then return end
		for k, v in pairs(t) do
			if type(v) == "function" and not seen[k] then seen[k] = true names[#names + 1] = tostring(k) end
		end
	end
	if type(dev) == "table" then add(dev) end
	local mt = getmetatable(dev)
	add(mt and mt.__index)
	table.sort(names)
	act("WPN methods: "..(#names > 0 and table.concat(names, " ") or "none listed"))
	act(string.format("SMS %s, %s, CHF %d FLR %d", S7.SMS.selected_text(S7.state, S7.list),
		S7.state.armed and "ARM" or "SAFE", S7.count_of("get_chaff_count"), S7.count_of("get_flare_count")))
end


local function deg(a) return a * RAD_TO_DEG end




local function track_line(t)
	if t.dl then
		return (string.format("%s%03d %5.1fNM %+03.0f %s", t.number == dt and ">" or " ", t.number, t.range / M_PER_NM,
			deg(t.brg), DLINK.label(t))):sub(1, 34)
	end
	return (string.format("%s%02d %5.1fNM %+03.0f%s%s%s%s", t.number == dt and ">" or " ", t.number, t.range / M_PER_NM,
		deg(t.brg), t.type ~= "" and " "..t.type or "", t.coast and " C" or "", t.asked and " M" or "", t.stt and " S" or "")):sub(1, 34)
end


local function hit_line(h)
	return (string.format(" %5.1fNM %+03.0f %+03.0f %.1fS --", h.range / M_PER_NM, deg(h.brg), deg(h.elev), h.age)):sub(1, 34)
end

local function in_scale(x) return x.range <= range_nm() * M_PER_NM end



local function picture()
	local list = {}


	local in_stt = false
	for _, x in ipairs(tracks) do if x.stt then in_stt = true end end
	for _, x in ipairs(tracks) do
		if in_scale(x) and (not in_stt or x.stt or (x.link or 0) > 0) then list[#list + 1] = {kind = "T", x = x} end
	end
	for _, h in ipairs(hits) do
		if not in_stt and h.number == 0 and in_scale(h) then list[#list + 1] = {kind = "H", x = h} end
	end
	table.sort(list, function(a, b) return a.x.range < b.x.range end)
	return list
end



local AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
local own_alt_m = param("RDR_OWN_ALT")
AA.F = AA.alt_filter()
local function alt_kft(x)
	local ft = AA.track_alt_ft(num(own_alt_m), x.range, x.elev)
	if x.number then return string.format("%d", AA.F.kft(x.number, ft, now)) end
	return string.format("%d", math.max(0, math.floor(ft / 1000 + 0.5)))
end

local function wrap180(a) return (a + 180) % 360 - 180 end



local function aspect(x)
	local rel = wrap180((deg(x.brg) + 180) - x.hdg)
	local tens = math.floor((180 - math.abs(rel)) / 10 + 0.5)
	if tens >= 18 then return "H" elseif tens <= 0 then return "T" end
	return string.format("%d%s", tens, rel >= 0 and "R" or "L")
end


local function brg_rng(x)
	return string.format("%03d-%d", math.floor((num(own_hdg) + deg(x.brg)) % 360 + 0.5) % 360,
		math.floor(x.range / M_PER_NM + 0.5))
end


local NAVBE = {v = param("NAV_BE_V"), n = param("NAV_BE_N"), e = param("NAV_BE_E"), decl = param("NAV_DECL"),
	dt = param("ATK_DT_BE"), cur = param("ATK_CUR_BE")}
local function be_str(rel_deg, range_m)
	if num(NAVBE.v) < 0.5 then return "" end
	local tb = math.rad(num(own_hdg) + rel_deg)
	local n, e = num(NAVBE.n) + range_m * math.cos(tb), num(NAVBE.e) + range_m * math.sin(tb)
	return string.format("%03d-%d", math.floor(math.deg(math.atan2(e, n) - num(NAVBE.decl)) + 0.5) % 360,
		math.floor(math.sqrt(n * n + e * e) / M_PER_NM + 0.5))
end


local function init_picture()
	for i = 1, ATK_MAX_TRACKS do
		for _, f in ipairs(ATK_T_FIELDS) do atk_t[i][f]:set(0) end
	end
	for i = 1, ATK_MAX_HITS do for _, f in ipairs({"X", "Y", "V"}) do atk_h[i][f]:set(0) end end
	for i = 1, ATK_MAX_DL do for _, h in pairs(ATK_L[i]) do h:set(0) end end
	for i = 1, ATK_MAX_THREATS do for _, h in pairs(ATK_X.s[i]) do h:set(0) end end
	for _, h in pairs(SOI.wez.h) do h:set(0) end
	SOI.band_dy:set(0) SOI.band_dv:set(0)
	for _, l in ipairs({SOI.inset.t, SOI.inset.l, SOI.inset.h, SOI.inset.fm, {SOI.inset.dt}}) do
		for _, slot in ipairs(l) do for _, h in pairs(slot) do h:set(0) end end
	end
	for _, f in ipairs(atk_dt.FM) do f.B:set(0) f.L:set(0) end
	for _, h in pairs(atk_scan) do h:set(0) end
	for _, h in pairs(atk_n) do h:set(0) end


	for _, h in pairs({atk_dt.V, atk_dt.B, atk_dt.L, atk_dt.I, atk_dt.strip_v, atk_band.V, atk_band.CY, atk_band.CV, atk_band.HI, atk_band.LO,
			atk_rng}) do h:set(0) end

	for _, h in pairs(P4.cur) do h:set(0) end
	for _, h in pairs(P4.el) do h:set(0) end
	P4.msg_v:set(0)
	atk_dt.CL:set(0)
	for _, h in pairs({atk_dt.BR, atk_dt.BLK, atk_cur_br, atk_strip, P4.azw, P4.bars, P4.msg, NAVBE.dt, NAVBE.cur}) do
		h:set("")
	end
	atk_on:set(0)
end

local function hide_picture()
	for i = 1, ATK_MAX_TRACKS do
		for _, f in ipairs(ATK_T_HIDE) do atk_t[i][f]:set(0) end
	end
	for i = 1, ATK_MAX_HITS do atk_h[i].V:set(0) end
	for i = 1, ATK_MAX_DL do ATK_L[i].V:set(0) ATK_L[i].D:set(0) end
	for i = 1, ATK_MAX_THREATS do ATK_X.s[i].V:set(0) end
	SOI.inset_hide()
	SOI.wez_update(nil)
	SOI.band_dv:set(0)
	for _, f in ipairs(atk_dt.FM) do f.L:set(0) end
	for _, h in pairs({atk_scan.V, atk_n.V, atk_dt.V, atk_dt.L, atk_dt.strip_v, atk_band.V, atk_band.CV, P4.cur.V, P4.cur.HV, P4.el.CV,
			P4.msg_v}) do h:set(0) end
end


local function update_cursor()
	P4.cur.X:set(S4.acq.x)
	P4.cur.Y:set(S4.acq.y)

	P4.cur.V:set((SOI.k(SOI.ATTACK) > 1 and atk_under_inset(S4.acq.x, S4.acq.y)) and 0 or 1)
	local r = acq_range()
	atk_cur_br:set(string.format("%03d-%d", math.floor((num(own_hdg) + acq_brg()) % 360 + 0.5) % 360,
		math.floor(r / M_PER_NM + 0.5)))
	NAVBE.cur:set(be_str(acq_brg(), r))
	local lo, hi = num(rdr_band_lo) / M_PER_FT, num(rdr_band_hi) / M_PER_FT
	if RSW.is_on() and hi > lo then
		P4.cur.HI:set(clamp(math.floor(hi / 1000 + 0.5), 0, 99))
		P4.cur.LO:set(clamp(math.floor(lo / 1000 + 0.5), 0, 99))
		P4.cur.HV:set(num(P4.cur.V))
	else
		P4.cur.HV:set(0)
	end


	if RSW.is_on() then
		local half = K4.WIDTHS[S4.width].half
		local c = 0
		if half < ATK_AZ_MAX then
			c = num(rdr_scan_dt) == 1 and num(rdr_scan_az) or clamp(acq_brg(), half - ATK_AZ_MAX, ATK_AZ_MAX - half)
		end
		atk_scan.L:set(math.rad(clamp(c - half, -ATK_AZ_MAX, ATK_AZ_MAX)))
		atk_scan.R:set(math.rad(clamp(c + half, -ATK_AZ_MAX, ATK_AZ_MAX)))
		atk_scan.V:set(1)
	else
		atk_scan.V:set(0)
	end

	P4.msg_v:set((now < S4.msg_until and (S4.msg_until - now) % 0.375 > 0.125) and 1 or 0)
end


local function update_picture(list)
	local scale_m = range_nm() * M_PER_NM
	atk_rng:set(range_nm())
	local nt, nh = 0, 0

	local dtt = dt ~= 0 and track_of(dt)
	local dcx, dcy = nil, nil
	if dtt then dcx, dcy = atk_xy(dtt.range, dtt.brg, scale_m) end
	SOI.inset_begin(dcx or S4.acq.x, dcy or S4.acq.y)
	for _, e in ipairs(list) do
		local x = e.x
		local px, py, qx, qy = SOI.atk_place(x.range, x.brg, scale_m)
		local stick = e.kind == "T" and (x.gs < 20 and 0 or clamp(math.floor(x.gs / ATK_STICK_MPS + 0.5), 1, ATK_STICK_STEPS))
		if px and e.kind == "T" and nt < ATK_MAX_TRACKS then
			nt = nt + 1
			local s = atk_t[nt]
			s.X:set(px) s.Y:set(py)
			s.V:set(x.coast and 2 or 1)
			s.H:set(math.rad(x.hdg))
			s.L:set(stick)
			s.D:set(x.number == dt and 1 or 0)
			s.S:set(x.stt and 1 or 0)
			s.M:set(x.asked and 1 or 0)
			s.P:set(prio_place(x.number) or 0)
			s.I:set(x.iff or 0)
			s.K:set((x.link or 0) > 0 and 1 or 0)
			s.W:set(x.wf or 0)
		elseif px and e.kind == "H" and nh < ATK_MAX_HITS then
			nh = nh + 1
			atk_h[nh].X:set(px) atk_h[nh].Y:set(py) atk_h[nh].V:set(1)
		end
		local s = SOI.inset_slot(e.kind == "T" and "T" or "H", qx, qy)
		if s and e.kind == "T" then
			s.V:set(x.coast and 2 or 1)
			s.H:set(math.rad(x.hdg))
			s.L:set(stick)
			s.D:set(x.number == dt and 1 or 0)
			s.I:set(x.iff or 0)
		elseif s then
			s.V:set(1)
		end
	end
	for i = nt + 1, ATK_MAX_TRACKS do
		for _, f in ipairs(ATK_T_HIDE) do atk_t[i][f]:set(0) end
	end
	for i = nh + 1, ATK_MAX_HITS do atk_h[i].V:set(0) end


	local nl = 0
	for _, t in ipairs(DLINK.list) do
		local px, py, qx, qy = SOI.atk_place(t.range, t.brg, scale_m)
		local stick = t.gs < 20 and 0 or clamp(math.floor(t.gs / ATK_STICK_MPS + 0.5), 1, ATK_STICK_STEPS)
		if px and nl < ATK_MAX_DL then
			nl = nl + 1
			local s = ATK_L[nl]
			s.X:set(px) s.Y:set(py)
			s.V:set(t.id)
			s.H:set(math.rad(t.hdg))
			s.L:set(stick)
			s.D:set(t.number == dt and 1 or 0)
		end
		local s = SOI.inset_slot("L", qx, qy)
		if s then
			s.V:set(t.id)
			s.H:set(math.rad(t.hdg))
			s.L:set(stick)
			s.D:set(t.number == dt and 1 or 0)
		end
	end
	for i = nl + 1, ATK_MAX_DL do ATK_L[i].V:set(0) ATK_L[i].D:set(0) end
	SOI.inset_end()

	local nx = 0
	for i = 1, math.min(math.floor(num(ATK_X.count) + 0.5), ATK_MAX_THREATS) do
		local tx, ty = SOI.atk_place(num(ATK_X.src[i].RANGE), num(ATK_X.src[i].REL), scale_m)
		if tx then
			nx = nx + 1
			ATK_X.s[nx].X:set(tx) ATK_X.s[nx].Y:set(ty) ATK_X.s[nx].V:set(1)
		end
	end
	for i = nx + 1, ATK_MAX_THREATS do ATK_X.s[i].V:set(0) end

	P4.azw:set(K4.WIDTHS[S4.width].name)
	P4.bars:set(K4.BARS[S4.bars].name)

	local nb = wrap180(-num(own_hdg))
	if math.abs(nb) <= ATK_AZ_MAX then
		atk_n.X:set(ATK_O_X + ATK_N_R * math.sin(math.rad(nb)))
		atk_n.Y:set(ATK_O_Y + ATK_N_R * math.cos(math.rad(nb)))
		atk_n.V:set(1)
	else
		atk_n.V:set(0)
	end

	local t = dt ~= 0 and track_of(dt)
	if t then
		local r_page = t.range / scale_m * ATK_R
		local on_fan = atk_xy(t.range, t.brg, scale_m) ~= nil
		atk_dt.B:set(t.brg)
		atk_dt.L:set(on_fan and math.max(0, math.floor((r_page - 0.05) / (ATK_R / ATK_DT_PIECES))) or 0)
		atk_dt.BR:set(brg_rng(t))
		NAVBE.dt:set(be_str(deg(t.brg), t.range))


		atk_dt.CL:set(math.floor(t.closure * KT_PER_MPS + 0.5))
		atk_dt.BLK:set(string.format("%sK %d %s %03d", alt_kft(t), math.floor(t.gs * KT_PER_MPS + 0.5), aspect(t),
			math.floor((num(own_hdg) + t.hdg) % 360 + 0.5) % 360))
		atk_dt.I:set(t.iff or 0)
		atk_dt.ID:set(t.dl and DLINK.label(t) or t.type)

		atk_dt.TYPE:set(atk_dt.type_of(t))
		atk_dt.V:set(1)
		local qx, qy = atk_xy(t.range, t.brg, scale_m)
		SOI.inset_line(SOI.inset.dt, qx, qy, t.brg, 0.05)
	else
		atk_dt.ID:set("")
		atk_dt.TYPE:set("")
		atk_dt.V:set(0)
		atk_dt.L:set(0)
		SOI.inset_line(SOI.inset.dt)
	end
	SOI.wez_update(t or nil, scale_m)


	local drawn, nd = {}, 0
	for _, f in ipairs(atk_dt.FM) do
		local n = math.floor(num(f.trk) + 0.5)
		local ft = num(f.v) > 0.5 and n > 0 and not drawn[n] and track_of(n)
		local fx, fy = ft and atk_xy(ft.range, ft.brg, scale_m)
		if fx then
			drawn[n] = true
			f.B:set(ft.brg)
			f.L:set(math.max(0, math.floor((ft.range / scale_m * ATK_R - 0.05) / (ATK_R / ATK_DT_PIECES))))
			nd = nd + 1
			SOI.inset_line(SOI.inset.fm[nd], fx, fy, ft.brg, 0.05)
		else
			f.L:set(0)
		end
	end
	for i = nd + 1, #SOI.inset.fm do SOI.inset_line(SOI.inset.fm[i]) end

	local lo, hi = num(rdr_band_lo) / M_PER_FT, num(rdr_band_hi) / M_PER_FT
	if RSW.is_on() and hi > lo then
		atk_band.HI:set(math.max(0, math.floor(hi / 1000 + 0.5)))
		atk_band.LO:set(math.max(0, math.floor(lo / 1000 + 0.5)))
		atk_band.V:set(1)

		local fd = t and (AA.track_alt_ft(num(own_alt_m), t.range, t.elev) - lo) / (hi - lo)
		SOI.band_dy:set(fd and ATK_BAND_BOT + clamp(fd, 0, 1) * (ATK_BAND_TOP - ATK_BAND_BOT) or 0)
		SOI.band_dv:set((fd and fd >= 0 and fd <= 1) and 1 or 0)
		local f = (num(own_alt_m) / M_PER_FT - lo) / (hi - lo)
		if f >= 0 and f <= 1 then
			atk_band.CY:set(ATK_BAND_BOT + f * (ATK_BAND_TOP - ATK_BAND_BOT))
			atk_band.CV:set(1)
		else
			atk_band.CV:set(0)
		end
	else
		atk_band.V:set(0)
		atk_band.CV:set(0)
		SOI.band_dv:set(0)
	end
end

local function update_page_link()
	atk_on:set(1)
	local list = picture()
	update_picture(list)
	local l = {}
	local nt, nh = 0, 0
	for _, e in ipairs(list) do if e.kind == "T" then nt = nt + 1 else nh = nh + 1 end end
	l[1] = RSW.is_on() and string.format("%s %s %dNM EL%+03.0f %s T%d H%d", K4.WIDTHS[S4.width].name,
		K4.BARS[S4.bars].name, range_nm(), el_ofs, link_name(), nt, nh) or ("RADAR OFF  LINK "..link_name())
	local t = dt ~= 0 and track_of(dt)
	l[2] = t and ("DT "..track_line(t):sub(2)..(num(dt_ok) == 1 and " SHOOT" or "")):sub(1, 34) or "DT NONE"
	for i = 1, 3 do
		local e = list[i]
		l[2 + i] = e and (e.kind == "T" and track_line(e.x) or hit_line(e.x)) or ""
	end
	l[6] = string.format("%s  AIM-120 %d  SUPP %d", locked() and string.format("STT %.1fNM", num(stt_range) / M_PER_NM)
		or "STT NO", aim120_left(), math.floor(num(link_supported) + 0.5))
	if running then
		l[7] = string.format("RUN %s  GATE %d  CUR %s", running, gate_step,
			cursor and string.format("%02d%s", cursor.slot, cursor.lost and " LOST" or "") or "-")
	else

		l[7] = (string.format("SCAN %+03.0f/%+03.0f%s %d-%dK%s", num(rdr_scan_az), num(rdr_scan_el),
			num(rdr_scan_dt) == 1 and "*" or "", math.floor(num(rdr_band_lo) / M_PER_FT / 1000 + 0.5),
			math.floor(num(rdr_band_hi) / M_PER_FT / 1000 + 0.5), t and (t.lock and " LK" or " NOLK") or "")):sub(1, 34)
	end
	l[8] = history[1]:sub(1, 34)
	for i = 1, NLINES do lines[i]:set(l[i]:upper()) end


	atk_strip:set((l[1].."  "..(running and l[7] or history[1])):sub(1, 64):upper())
	atk_dt.strip_v:set(running and 1 or 0)
end

local function update_page()
	if link_present() then update_page_link() return end
	atk_on:set(0)
	hide_picture()
	local l = {}
	l[1] = string.format("RADAR %s  CONTACTS %d", RSW.is_on() and "ON" or "OFF", #contacts)
	if cursor then
		l[2] = string.format("CUR %02d %.1fNM %+.1f %+.1f", cursor.slot, cursor.range / M_PER_NM, deg(cursor.az),
			deg(cursor.el))
		l[3] = "NCTR "..cursor.nctr..(cursor.lost and "  LOST" or "")
	else
		l[2] = "CUR NONE"
		l[3] = ""
	end
	l[4] = locked() and string.format("STT %.1fNM %+.1f", num(stt_range) / M_PER_NM, deg(num(stt_az))) or "STT NO"
	local list = amraam_stations()
	l[5] = string.format("AIM-120 %d  NEXT ST %s", aim120_left(), list[1] and tostring(list[1].station) or "-")
	l[6] = string.format("RUN %s  GATE %d %.0fKM", running or "-", gate_step, LOCK_STEPS[gate_step].caret / 1000)
	l[7] = history[1]:sub(1, 34)
	l[8] = history[2]:sub(1, 34)
	for i = 1, NLINES do lines[i]:set(l[i]:upper()) end
end

local function log_state()
	local cur = cursor or {slot = 0, range = 0, az = 0, lost = false}
	local row = {string.format("%.3f", now), "S", RSW.is_on() and 1 or 0, num(stt_range), num(stt_az), num(stt_el),
		str(stt_friendly), num(tdc_range), num(tdc_az), str(radar_mode), #contacts, cur.slot, cur.range, cur.az,
		cur.lost and 1 or 0, aim120_left(), num(tdc_caret), num(acq_az)}
	csv_row(row)
	for _, c in ipairs(contacts) do
		local s = slots[c.slot]
		csv_row({string.format("%.3f", now), "C", c.slot, num(s.RANGE), num(s.AZIMUTH), num(s.ELEVATION), num(s.VX),
			num(s.VY), num(s.VZ), num(s.RCS), num(s.RCS_COEFF), str(s.FRIENDLY), str(s.NCTR), num(s.TIME), num(s.NOISE)})
	end
	if link_present() then
		csv_row({string.format("%.3f", now), "L", link(), dt, num(dt_ok), #tracks, num(link_supported),
			K4.WIDTHS[S4.width].half, range_nm(), acq_brg(), el_ofs, num(rdr_scan_az), num(rdr_scan_el), num(rdr_scan_dt), num(rdr_band_lo),
			num(rdr_band_hi), num(rdr_frame), #hits})
		for _, t in ipairs(tracks) do
			csv_row({string.format("%.3f", now), "T", t.slot, t.number, t.range, t.brg, t.elev, t.closure, t.coal,
				t.coast and 1 or 0, t.asked and 1 or 0, t.type, t.lock and 1 or 0, t.stt and 1 or 0})
		end
		for _, h in ipairs(hits) do
			csv_row({string.format("%.3f", now), "H", h.slot, h.number, h.range, h.brg, h.elev, h.age})
		end
	end
	if not csv then
		dcs_log(table.concat(row, ","))
		for _, c in ipairs(contacts) do
			dcs_log(string.format("C %02d %.0f m az %.4f el %.4f %s", c.slot, c.range, c.az, c.el, c.nctr))
		end
	end
end

local function dcs_summary()
	local cur = cursor and string.format("cur %02d %.1f nm%s", cursor.slot, cursor.range / M_PER_NM,
		cursor.lost and " LOST" or "") or "cur none"
	dcs_log(string.format("%.2f state: radar %s, %d contacts, %s, STT %s, AIM-120 %d%s", now,
		RSW.is_on() and "on" or "off", #contacts, cur,
		locked() and string.format("%.1f nm", num(stt_range) / M_PER_NM) or "no", aim120_left(),
		link_present() and string.format(", link %s, %d tracks, DT %d%s, %s %s %d nm, %d hits, prio %d%s", link_name(),
			#tracks, dt, num(dt_ok) == 1 and " firm" or "", K4.WIDTHS[S4.width].name, K4.BARS[S4.bars].name, range_nm(),
			#hits, #prio, ACM.mode ~= 0 and string.format(", ACM %s el %+.0f acm trk %d", ACM.NAMES[ACM.mode],
				num(ACM.p.el), math.floor(num(ACM.p.trk) + 0.5)) or "") or ""))
end


dev:listen_command(cmd.MsltRadarPower)
dev:listen_command(cmd.MsltNextContact)
dev:listen_command(cmd.MsltLock)
dev:listen_command(cmd.MsltUnlock)
dev:listen_command(cmd.MsltFire)
dev:listen_command(cmd.MsltTestA)
dev:listen_command(cmd.MsltTestB)
dev:listen_command(cmd.MsltTestC)
for _, c in ipairs({cmd.RdrElUp, cmd.RdrElDown, cmd.RdrScanReset, cmd.RdrRangeUp, cmd.RdrRangeDown, cmd.RdrTdcX,
		cmd.RdrTdcY, cmd.RdrTdcUp, cmd.RdrTdcDown, cmd.RdrTdcLeft, cmd.RdrTdcRight, cmd.RdrTmsUp, cmd.RdrTmsDown,
		cmd.RdrTmsLeft, cmd.RdrTmsRight, cmd.RdrAntElev, cmd.RdrWidth, cmd.RdrBars, cmd.WpnGun, cmd.WpnSrm, cmd.WpnMrm,
		cmd.WpnCycle, cmd.WpnMasterArm, cmd.WpnFire, S7.FIRE, S7.FIRE_OFF, S7.MODE_CANNON, cmd.CmChaff, cmd.CmFlare,
		S7.JETT_TANKS, cmd.RdrAcqFwd, cmd.RdrAcqAft, cmd.RdrAcqDepress, cmd.RdrHmdAcq, cmd.SrmUncage, cmd.DispDayNight,
		cmd.GunTrigger, cmd.RdrExp, cmd.MmAA, cmd.MmNav, cmd.MmCycle, cmd.CmdMan1, cmd.CmdMan2, cmd.CmdMode, cmd.CmdSel}) do
	dev:listen_command(c)
end
dev:listen_command(Keys.IffOwnCoal)

function post_initialize()
	now = get_model_time()
	open_csv()
	dcs_log("driver up, CSV "..(csv and "open" or "NOT open (dcs.log only)"))


	local okl, link = pcall(function() return dev.link end)
	local hex = okl and link ~= nil and tostring(link):match("(%x+)%s*$") or nil
	SRM_WS_PTR:set(hex and ("P"..hex) or "")
	dcs_log(string.format("O13: device link %s (%s, %s) -> SRM_WS_PTR %s", tostring(link), type(link),
		okl and "read" or "error", hex and ("P"..hex) or "none"))
	for i = 0, MAX_STATIONS - 1 do
		local s = station_info(i)
		if s and s.CLSID and s.CLSID ~= "" then
			local w = s.weapon or {}
			act(string.format("station %d %s count %s wsType %s.%s.%s.%s", i, tostring(s.CLSID), tostring(s.count),
				tostring(w.level1), tostring(w.level2), tostring(w.level3), tostring(w.level4)))
		end
	end
	local birth = LockOn_Options.init_conditions and LockOn_Options.init_conditions.birth_place
	set_power(birth == "AIR_HOT" or birth == "GROUND_HOT", "birth "..tostring(birth))
	dt_trk:set(0)
	ACM.p.uncage:set(0)
	ACM.send()
	init_picture()
	send_controls()
	hold_gate()
	S7.start()
	S7.MM.p:set(S7.MM.mode)
	update_page()
end




function S4.el_tick(dt_s)
	local k = S4.key.el_up - S4.key.el_dn
	local page = SOI.hotas_page()
	SOI.tdc.ELR:set(page and k or 0)
	if k ~= 0 and not page then el_ofs = clamp(el_ofs + k * K4.EL_RATE * dt_s, -EL_MAX, EL_MAX) end
	if S4.el_held ~= (k ~= 0) then
		S4.el_held = k ~= 0
		if not S4.el_held and not page then act(string.format("RADAR elevation %+.1f deg", el_ofs)) end
	end
	rdr_el_ofs:set(el_ofs)


	if RSW.is_on() and link_present() then
		local f = (clamp(num(rdr_scan_el), -ATK_EL_CARET_DEG, ATK_EL_CARET_DEG) + ATK_EL_CARET_DEG) / (2 * ATK_EL_CARET_DEG)
		P4.el.CY:set(ATK_BAND_BOT + f * (ATK_BAND_TOP - ATK_BAND_BOT))
		P4.el.CV:set(1)
	else
		P4.el.CV:set(0)
	end
end

function SetCommand(command, value)
	if command == Keys.IffOwnCoal then IFF.set_own(value) return end
	if command == S7.FIRE or command == S7.FIRE_OFF or command == S7.MODE_CANNON then S7.raw(command, value) return end
	if command == cmd.GunTrigger then


		if value == 0 then S7.gun_up("gun trigger up")
		elseif not S7.state.armed then flash("SAFE") act("WPN GUN trigger: master arm SAFE")
		else S7.gun_down("EX") end
		return
	end
	if command == cmd.WpnFire and value == 0 then
		S7.gun_up("trigger up")
		S7.mrm_cancel("release let go")

		return
	end
	if command == cmd.DispDayNight then
		local h = get_param_handle("F15EX_DISP_NIGHT")
		h:set(h:get() > 0.5 and 0 or 1)
		return
	end
	if ACM.command(command, value) then return end

	if ACM.tms(command, value) then return end
	if hotas(command, value) then return end
	if value == 0 then return end
	if control(command) then return end
	if S7.command(command) then return end
	if command == cmd.MsltRadarPower then
		set_power(num(RSW.silent) > 0.5, "key")
	elseif command == cmd.MsltNextContact then

		if link_present() and #tracks > 0 then tms_right() else next_contact() end
	elseif running then
		act("busy with test "..running..": key ignored")
	elseif command == cmd.MsltLock then

		if link_present() then
			local t = dt ~= 0 and track_of(dt)
			if not t then act("LOCK: no DT (NEXT first)") return end
			if not t.lock then act(string.format("LOCK: DT %02d not lockable (%.1f nm)", dt, t.range / M_PER_NM)) return end
			if not cursor_to_track(t) then act(string.format("LOCK: DT %02d, no radar contact near it", dt)) return end
		end
		lock("KEY")
	elseif command == cmd.MsltUnlock then
		unlock("KEY")
	elseif command == cmd.MsltFire then
		fire("KEY")
	elseif command == cmd.MsltTestA then
		test_a()
	elseif command == cmd.MsltTestB then
		test_b()
	elseif command == cmd.MsltTestC then
		test_c()
	end
end

function update()
	now = get_model_time()
	run_tasks()
	SOI.rng_nm:set(range_nm())

	local req = num(RSW.req)
	if req ~= RSW.seen then
		RSW.seen = req
		if req > 0 then
			set_power(num(RSW.silent) > 0.5, "RDR")
			if num(RSW.silent) > 0.5 then flash("RADAR OFF") end
		end
	end
	S7.gun_tick(update_time_step)
	S7.mrm_tick()
	S7.srm_tick()
	S7.CMD.tick()



	if link_present() then
		if ACM.mode == ACM.SS then ACM.slew(update_time_step)
		elseif SOI.page() == SOI.SITP then SOI.slew(update_time_step)
		elseif SOI.page() == SOI.ATTACK then slew(update_time_step) end
		update_cursor()
	end
	if SOI.page() == SOI.TEWS and not (ACM.mode == ACM.SS) then SOI.tews_tdc() end
	SOI.feed(ACM.mode == ACM.SS)
	S4.el_tick(update_time_step)
	SOI.show(link_present())
	ACM.tick()
	t_poll = t_poll + update_time_step
	t_log = t_log + update_time_step
	t_dcs = t_dcs + update_time_step
	if t_poll >= POLL_PERIOD - 1e-9 then
		t_poll = 0
		poll_contacts()
		poll_tracks()
		ACM.poll()
		send_controls()
		S7.poll()
		update_page()
	end
	local zone_due = t_log >= LOG_PERIOD - 1e-9
	if zone_due then
		t_log = 0
		log_state()
	end
	if t_dcs >= DCS_LOG_PERIOD - 1e-9 then
		t_dcs = 0
		dcs_summary()
	end
	ACM.scan_centre()
	ACM.scan_zone()
	if zone_due then ACM.log_zone() end
end




need_to_be_closed = false
