



































dofile(LockOn_Options.script_path.."command_defs.lua")

local dev = GetSelf()
local update_time_step = 0.05
make_default_activity(update_time_step)
local sensor_data = get_base_data()

local SLOTS = Keys.MslSlots
local PAIR_S = 4.0
local STALE_S = 0.6
local DSLOTS = 6
local TTI_OVER = 3.0
local COAST_S = 10.0
local MIN_CLOSE = 30.0
local ASK_MIN_S = 2.0
local LINES = 4
local ACT_FLASH_S = 4.0
local ACT_FLASH_ON, ACT_FLASH_OFF = 0.3, 0.2
local TRK_MAX = 32


local MEAN_SLOW, MEAN_RANGE = 0.30, 150000.0

local BOOST_S = 8.0

local BOOST_K = 0.7
local V_CAP = 1700.0
local V_MIN = 30.0
local SHOW_AFTER_S = 0.8
local VEL_TAU = 0.3
local ACC_TAU = 0.2
local TAU = 1.2
local DOWN, UP = 6.0, 0.25
local SEC_HYST = 0.65
local TTI_MAX = 999.0

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function dcs_log(s) if log and log.info then tostring("F15EX MSL "..s) else tostring("F15EX MSL "..s) end end

local IN = {launch_n = param("WPN_LAUNCH_N"), launch_trk = param("WPN_LAUNCH_TRK"), launch_act = param("WPN_LAUNCH_ACT"),
	stamp = param("TRK_STAMP"), dt = param("RDR_DT_TRK")}
local trk = {}
for i = 1, TRK_MAX do
	trk[i] = {}
	for _, f in ipairs({"NUM", "STT", "ASKED", "DX", "DY", "DZ", "VX", "VY", "VZ"}) do
		trk[i][f] = param(string.format("TRK_%02d_%s", i, f))
	end
end


local DL_MAX, DL_FIRST = 32, 101
local dlt = {}
for i = 1, DL_MAX do
	dlt[i] = {}
	for _, f in ipairs({"NUM", "DX", "DY", "DZ", "VX", "VY", "VZ"}) do
		dlt[i][f] = param(string.format("DL_%02d_%s", i, f))
	end
end
local OUT = {slot = {}, line = {}, dt_v = param("MSL_DT_V"), dt_tti = param("MSL_DT_TTI"), dt_ta = param("MSL_DT_TA"),
	dt_fl = param("MSL_DT_FL")}
for k = 1, SLOTS do
	OUT.slot[k] = {v = param(string.format("MSL_%02d_V", k)), trk = param(string.format("MSL_%02d_TRK", k)),
		tti = param(string.format("MSL_%02d_TTI", k)), ta = param(string.format("MSL_%02d_TA", k)),
		ln = param(string.format("MSL_%02d_LN", k))}
end
for i = 1, LINES do OUT.line[i] = param("MSL_L"..i) end
local MSLF = {}
for j = 1, DSLOTS do
	MSLF[j] = {}
	for _, f in ipairs({"SER", "X", "Y", "Z", "VX", "VY", "VZ", "AGE"}) do
		MSLF[j][f] = param(string.format("MSLF_%02d_%s", j, f))
	end
end




local S = {now = 0, launches = {}, launch_seen = 0, rx = {}, m = {}, stamp = nil, t0 = 0, t_log = 0}
for k = 1, SLOTS do S.rx[k] = {} end

local function sub(a, b) return {a[1] - b[1], a[2] - b[2], a[3] - b[3]} end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi end return x end


local function track_rel(number)
	if not number or number <= 0 then return nil end
	local age = math.max(0, S.now - S.t0)
	if number >= DL_FIRST then
		for i = 1, DL_MAX do
			local t = dlt[i]
			if math.floor(num(t.NUM) + 0.5) == number then
				local v = {num(t.VX), num(t.VY), num(t.VZ)}
				return {num(t.DX) + v[1] * age, num(t.DY) + v[2] * age, num(t.DZ) + v[3] * age}, v, false
			end
		end
		return nil
	end
	for i = 1, TRK_MAX do
		local t = trk[i]
		if math.floor(num(t.NUM) + 0.5) == number then
			local v = {num(t.VX), num(t.VY), num(t.VZ)}
			return {num(t.DX) + v[1] * age, num(t.DY) + v[2] * age, num(t.DZ) + v[3] * age}, v, num(t.ASKED) > 0.5
		end
	end
	return nil
end

local function stt_track()
	for i = 1, TRK_MAX do
		if num(trk[i].STT) > 0.5 then return math.floor(num(trk[i].NUM) + 0.5) end
	end
	return 0
end

local function own()
	local x, y, z = sensor_data.getSelfCoordinates()
	local vx, vy, vz = sensor_data.getSelfVelocity()
	return {x or 0, y or 0, z or 0}, {vx or 0, vy or 0, vz or 0}
end



local function intercept_time(R, rh, u, V)
	local ur = dot(u, rh)
	local a = V * V - dot(u, u)
	if a <= 1.0 then return nil end
	local s = ur * ur + a
	if s <= 0 then return nil end
	return R * (ur + math.sqrt(s)) / a
end



local function mean_speed(v, R)
	return math.max(V_MIN, v * (1 - MEAN_SLOW * math.min(1, R / MEAN_RANGE)))
end



local function countdown(m, key, sec_key, meas, dt)
	if not meas or meas ~= meas or meas < 0 then m[key], m[sec_key] = nil, nil return -1 end
	meas = math.min(TTI_MAX, meas)
	local s = m[key]
	if not s then
		m[key], m[sec_key] = meas, math.floor(meas + 0.5)
		return m[sec_key]
	end
	s = s - dt + clamp((meas - s) / TAU, -DOWN, UP) * dt
	if s < 0 then s = 0 end
	m[key] = s
	local v = m[sec_key] or math.floor(s + 0.5)
	while s < v - SEC_HYST and v > 0 do v = v - 1 end
	while s > v + SEC_HYST and v < TTI_MAX do v = v + 1 end
	m[sec_key] = v
	return v
end


local function read_launches()
	local n = num(IN.launch_n)
	if n == S.launch_seen then return end
	S.launch_seen = n
	local number = math.floor(num(IN.launch_trk) + 0.5)
	if number <= 0 then number = stt_track() end
	S.launches[#S.launches + 1] = {t = S.now, trk = number, act = num(IN.launch_act)}
	dcs_log(string.format("%.2f launch on track %02d, active at %s", S.now, number,
		num(IN.launch_act) > 0 and string.format("%.0f m", num(IN.launch_act)) or "? (pitbull from the questions)"))
end


local function new_missile(k, serial)
	while S.launches[1] and S.now - S.launches[1].t > PAIR_S do table.remove(S.launches, 1) end
	local l = table.remove(S.launches, 1)

	local used = {}
	for _, m in pairs(S.m) do if m.out and not m.done then used[m.out] = true end end
	local out = (k - 1) % SLOTS + 1
	if used[out] then
		out = nil
		for o = 1, SLOTS do if not used[o] then out = o break end end
	end
	S.m[k] = {serial = serial, t0 = S.now, trk = l and l.trk or 0, act = l and l.act or 0, active = false,
		asked = false, last_rel = nil, last_v = nil, last_seen = S.now, out = out}
	dcs_log(string.format("%.2f missile %d in slot %d (%s, out %s): %s", S.now, serial, k, k > SLOTS and "DLL" or "hook",
		tostring(out), l and string.format("track %02d", l.trk) or "no radar launch to pair (not ours to guide: an AIM-9X?)"))
end

local function go_active(m, k, why)
	m.active = true
	m.t_act = S.now
	dcs_log(string.format("%.2f missile %d (slot %d) ACTIVE on track %02d: %s", S.now, m.serial, k, m.trk, why))
end

local function nop() end
local NO_OUT = {v = {set = nop}, trk = {set = nop}, tti = {set = nop}, ta = {set = nop}, ln = {set = nop}}





local function line_on(m, rx, present, asked)
	if m.trk >= DL_FIRST then return present and not rx.lost end
	if not present then m.bound = false
	elseif asked then m.bound = true end
	return m.bound and (asked or m.active) or false
end
local function update_missile(k, m, op, ov)
	local rx = S.rx[k]
	local o = m.out and OUT.slot[m.out] or NO_OUT
	local rel, vrel, asked = track_rel(m.trk)
	local present = rel ~= nil
	if rel then
		m.last_rel, m.last_v, m.last_seen = {rel[1] - S.now * vrel[1], rel[2] - S.now * vrel[2], rel[3] - S.now * vrel[3]},
			vrel, S.now
	elseif m.last_rel and S.now - m.last_seen <= COAST_S then
		local L, v = m.last_rel, m.last_v
		rel, vrel = {L[1] + v[1] * S.now, L[2] + v[2] * S.now, L[3] + v[3] * S.now}, v
	end
	if not rel then
		m.bound = false
		o.v:set(3) o.trk:set(m.trk) o.tti:set(-1) o.ta:set(-1) o.ln:set(0)
		return nil
	end


	local tp = {op[1] + rel[1], op[2] + rel[2], op[3] + rel[3]}
	local tv = {ov[1] + vrel[1], ov[2] + vrel[2], ov[3] + vrel[3]}
	if m.t_s ~= rx.t then
		local age = math.max(0, S.now - rx.t)
		local tps = {tp[1] - tv[1] * age, tp[2] - tv[2] * age, tp[3] - tv[3] * age}
		local r, rd = sub(tps, rx.p), sub(tv, rx.v)
		local Rs = math.sqrt(dot(r, r))
		m.t_s, m.R_s, m.close_s = rx.t, Rs, Rs > 1 and -dot(r, rd) / Rs or 0
	end

	local closing = m.close_s >= MIN_CLOSE
	local R = closing and m.R_s - m.close_s * (S.now - m.t_s) or m.R_s
	local why = closing and R < -m.close_s * TTI_OVER and string.format("past its impact by %.0f s with no new data", TTI_OVER)
		or m.was_closing and m.close_s < 0 and "opening from its target (past it)"
	if why then
		m.done = true
		dcs_log(string.format("%.2f missile %d (slot %d) %s: done", S.now, m.serial, k, why))
		return nil
	end
	m.was_closing = m.was_closing or closing
	if asked then m.asked = true end
	if not m.active then
		if m.act > 0 and R <= m.act then go_active(m, k, string.format("%.0f m to go, inside its %.0f m", R, m.act))
		elseif m.act <= 0 and m.asked and not asked and S.now - m.t0 >= ASK_MIN_S then




			go_active(m, k, "it stopped asking the launcher")
		end
	end


	local r = sub(tp, rx.p)
	local Rn = math.sqrt(dot(r, r))
	local tti, ta = -1, -1
	local age = S.now - m.t0
	if Rn > 1 and age >= SHOW_AFTER_S then
		local rh = {r[1] / Rn, r[2] / Rn, r[3] / Rn}
		local vm = rx.sp or math.sqrt(dot(rx.v, rx.v))


		if age < BOOST_S and (rx.acc or 0) > 0 then vm = math.min(V_CAP, vm + BOOST_K * rx.acc * (BOOST_S - age)) end
		tti = intercept_time(Rn, rh, tv, mean_speed(vm, Rn))
		if not tti then

			local closing_now = -dot(r, sub(tv, rx.v)) / Rn
			if closing_now > V_MIN then tti = Rn / closing_now end
		end
		if tti then
			tti = clamp(tti, 0, TTI_MAX)
			if not m.active and m.act > 0 and Rn > m.act then
				ta = clamp(tti * (1 - m.act / Rn), 0, TTI_MAX)
			end
		else
			tti = -1
		end
	end
	local dt = clamp(S.now - (m.t_show or S.now), 0, 0.2)
	m.t_show = S.now
	local shown, shown_ta = countdown(m, "tti_s", "tti_sec", tti, dt), countdown(m, "ta_s", "ta_sec", ta, dt)
	o.v:set(m.active and 2 or 1) o.trk:set(m.trk) o.tti:set(shown) o.ta:set(shown_ta)
	o.ln:set(line_on(m, rx, present, asked) and 1 or 0)
	m.tti, m.ta, m.R = shown, shown_ta, R
	return m
end



local function sec(x)
	if not x or x < 0 then return "--" end
	x = math.min(TTI_MAX, math.floor(x + 0.5))
	return string.format(x > 99 and "%03d" or "%02d", x)
end

function SetCommand(command, value)
	local i = command - Keys.MslBase
	if i < 0 or i >= 8 * SLOTS then return end
	local k, f = math.floor(i / 8) + 1, i % 8
	local rx = S.rx[k]
	if f == 0 then
		local serial = math.floor(value + 0.5)
		if serial ~= rx.serial then
			rx.serial, rx.p, rx.v, rx.ok = serial, {0, 0, 0}, {0, 0, 0}, false
			rx.new = true
		end
		rx.t = get_model_time()
	elseif rx.p and f <= 3 then
		rx.p[f] = value
		if f == 3 then rx.ok = true end
	elseif rx.v and f <= 6 then
		rx.v[f - 3] = value
	end
end

function post_initialize()
	for i = 1, LINES do OUT.line[i]:set("") end
	S.launch_seen = num(IN.launch_n)
	for c = Keys.MslBase, Keys.MslBase + 8 * SLOTS - 1 do dev:listen_command(c) end
	dcs_log("up")
end




local function mslf_sample(rx, f)
	local p = {num(f.X), num(f.Y), num(f.Z)}
	local t = S.now - math.max(0, num(f.AGE))
	rx.n = (rx.n or 0) + 1
	if rx.pt and rx.pt_t and t > rx.pt_t + 0.02 then
		local d = t - rx.pt_t
		local vd = {(p[1] - rx.pt[1]) / d, (p[2] - rx.pt[2]) / d, (p[3] - rx.pt[3]) / d}
		local a = math.min(1, d / VEL_TAU)
		if rx.vm then
			for i = 1, 3 do rx.vm[i] = rx.vm[i] + a * (vd[i] - rx.vm[i]) end
		else
			rx.vm = vd
		end

		local raw = math.sqrt(dot(vd, vd))
		if rx.n >= 3 and rx.raw_sp and d > 0 then
			local inst = (raw - rx.raw_sp) / d
			if math.abs(inst) < 600 then rx.acc = (rx.acc or 0) + math.min(1, d / ACC_TAU) * (inst - (rx.acc or 0)) end
		end
		rx.raw_sp = raw
		rx.sp = math.sqrt(dot(rx.vm, rx.vm))
	elseif not rx.vm then
		rx.vm = {num(f.VX), num(f.VY), num(f.VZ)}
		rx.sp = math.sqrt(dot(rx.vm, rx.vm))
		rx.acc = 0
	end
	rx.pt, rx.pt_t = p, t
	rx.p, rx.v = p, rx.vm
	rx.t, rx.ok, rx.dll = t, true, true
end

function update()
	S.now = get_model_time()
	local stamp = num(IN.stamp)
	if stamp ~= S.stamp then S.stamp, S.t0 = stamp, S.now end
	read_launches()
	local op, ov = own()




	local present = {}
	for j = 1, DSLOTS do
		local f = MSLF[j]
		local ser = math.floor(num(f.SER) + 0.5)
		if ser > 0 then
			local k = SLOTS + ser
			present[k] = true
			local rx = S.rx[k]
			if not rx then
				rx = {serial = ser, new = true}
				S.rx[k] = rx
			end
			rx.lost = false

			local p = {num(f.X), num(f.Y), num(f.Z)}
			if not rx.p or p[1] ~= rx.p[1] or p[2] ~= rx.p[2] or p[3] ~= rx.p[3] then
				mslf_sample(rx, f)
			end
		end
	end
	local keys = {}
	for k in pairs(S.rx) do
		if k > SLOTS and not present[k] and not S.rx[k].lost then
			local m = S.m[k]
			S.rx[k].lost = true
			if m and not m.done then
				dcs_log(string.format("%.2f missile %d (slot %d) out of the DLL's feed: kept on its last data, TTI %s",
					S.now, m.serial, k, m.tti and m.tti >= 0 and string.format("%.1f s", m.tti) or "-"))
			else
				S.rx[k].gone = true
			end
		end
		keys[#keys + 1] = k
	end
	table.sort(keys)
	local dt_trk = math.floor(num(IN.dt) + 0.5)
	local best, lines = nil, {}
	local out_v = {}
	for _, k in ipairs(keys) do
		local rx = S.rx[k]
		if rx.gone or (rx.t and not rx.dll and S.now - rx.t > STALE_S) or (rx.lost and (not S.m[k] or S.m[k].done)) then
			if S.m[k] then
				local m = S.m[k]
				dcs_log(string.format("%.2f missile %d (slot %d) gone, track %02d, last TTI %s, %s", S.now, m.serial, k, m.trk,
					m.tti and string.format("%.1f s", m.tti) or "-", m.active and "active" or "not active"))
			end
			S.m[k] = nil
			S.rx[k] = k <= SLOTS and {} or nil
			rx = S.rx[k] or {}
		end
		if rx.new then rx.new = false new_missile(k, rx.serial) end
		local m = S.m[k]
		local live = m and not m.done and rx.ok and update_missile(k, m, op, ov)
		if m and not m.done and m.out then
			out_v[m.out] = true
			if not rx.ok then OUT.slot[m.out].ln:set(0) end
		end
		if live and live.trk > 0 then
			if live.trk == dt_trk and (not best or (live.tti >= 0 and (best.tti < 0 or live.tti < best.tti))) then best = live end
			if #lines < LINES then
				lines[#lines + 1] = {tti = live.tti, s = string.format("%02d %s T%s", live.trk,
					live.active and "ACT" or ("A"..sec(live.ta)), sec(live.tti))}
			end
		end
	end
	for o = 1, SLOTS do
		if not out_v[o] then
			local s = OUT.slot[o]
			s.v:set(0) s.trk:set(0) s.tti:set(-1) s.ta:set(-1) s.ln:set(0)
		end
	end
	table.sort(lines, function(a, b) return (a.tti < 0 and 1e9 or a.tti) < (b.tti < 0 and 1e9 or b.tti) end)
	for i = 1, LINES do OUT.line[i]:set(lines[i] and lines[i].s or "") end
	OUT.dt_v:set(best and (best.active and 2 or 1) or 0)
	OUT.dt_tti:set(best and best.tti or -1)
	OUT.dt_ta:set(best and best.ta or -1)

	local since = best and best.t_act and S.now - best.t_act
	OUT.dt_fl:set((since and since < ACT_FLASH_S and since % (ACT_FLASH_ON + ACT_FLASH_OFF) >= ACT_FLASH_ON) and 1 or 0)
	S.t_log = S.t_log + update_time_step
	if S.t_log >= 1.0 and #lines > 0 then
		S.t_log = 0
		local l = {}
		for i, x in ipairs(lines) do l[i] = x.s end
		dcs_log(string.format("%.2f in flight: %s", S.now, table.concat(l, " | ")))
	end
end




need_to_be_closed = false
