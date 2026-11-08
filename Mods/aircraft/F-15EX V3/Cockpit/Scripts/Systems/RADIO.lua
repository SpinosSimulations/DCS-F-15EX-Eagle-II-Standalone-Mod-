
























dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")

local dev = GetSelf()
local update_time_step = 0.1
make_default_activity(update_time_step)

local C = device_commands
local COMM_MENU = 179
local CHANNELS = 20
local GUARD = {243.0, 121.5}
local DEVICE = {devices.UHF1_RADIO, devices.UHF2_RADIO}

local DEFAULT_PRESETS = {
	{251.0, 264.0, 265.0, 256.0, 254.0, 250.0, 270.0, 257.0, 255.0, 262.0,
	 259.0, 268.0, 269.0, 260.0, 263.0, 261.0, 267.0, 251.5, 252.0, 253.0},
	{124.0, 127.5, 121.0, 118.5, 119.0, 120.0, 122.0, 123.0, 124.5, 125.0,
	 126.0, 128.0, 129.0, 130.0, 131.0, 132.0, 133.0, 134.0, 135.0, 136.0},
}
local BANDS = {{30.0, 87.975}, {108.0, 173.975}, {225.0, 399.975}}

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function dcs_log(s) if log and log.info then tostring("F15EX RADIO "..s) else tostring("F15EX RADIO "..s) end end

local IN = {ess = param("EFM_ELEC_ESS"), req_r = param("RADIO_REQ_R"), req_v = param("RADIO_REQ_V"),
	req_n = param("RADIO_REQ_N"), link = param("RADIO_LINK")}
local OUT = {tx = param("RADIO_TX"), ack = param("RADIO_REQ_ACK"), ok = param("RADIO_REQ_OK"), r = {},
	ptt_r = param("RADIO_PTT_R"), ptt_n = param("RADIO_PTT_N")}
for n = 1, 2 do
	OUT.r[n] = {v = param("RADIO_"..n.."_V"), ch = param("RADIO_"..n.."_CH"), freq = param("RADIO_"..n.."_FREQ"),
		g = param("RADIO_"..n.."_G"), txt = param("RADIO_"..n.."_TXT"), pwr = param("RADIO_"..n.."_PWR"),
		on = param("RADIO_"..n.."_ON"), rx = param("RADIO_"..n.."_RX")}
end



local R = {}
for n = 1, 2 do R[n] = {on = true, rx = true, ch = 1, man = nil, guard = true, presets = {}, sent = nil, sent_t = 0} end
local READBACK_WAIT = 1.0
local READBACK_TOL = 2500
local clock = 0
local S = {req_seen = 0, tx = 0}

local function in_band(f)
	for _, b in ipairs(BANDS) do if f >= b[1] - 1e-9 and f <= b[2] + 1e-9 then return true end end
	return false
end


local function load_presets(n)
	local ok, data = pcall(function() return get_aircraft_mission_data("Radio") end)
	local ch = ok and type(data) == "table" and type(data[n]) == "table" and data[n].channels or nil
	local got = 0
	for k = 1, CHANNELS do
		local f = type(ch) == "table" and tonumber(ch[k]) or nil
		if f and in_band(f) then R[n].presets[k] = f got = got + 1 else R[n].presets[k] = DEFAULT_PRESETS[n][k] end
	end
	dcs_log(string.format("R%d: %d of %d presets from the mission%s", n, got, CHANNELS,
		ok and "" or (" (get_aircraft_mission_data: "..tostring(data)..")")))
end

local function powered(n) return R[n].on and num(IN.ess) > 0.5 end

local function freq_of(n) return R[n].man or R[n].presets[R[n].ch] end


local function tune(n)
	local hz = powered(n) and math.floor(freq_of(n) * 1e6 + 0.5) or 0
	if hz == R[n].sent then return end
	R[n].sent = hz
	R[n].sent_t = clock
	local radio = GetDevice and GetDevice(DEVICE[n])
	if radio and radio.set_frequency then
		local ok, err = pcall(radio.set_frequency, radio, hz)
		if not ok then dcs_log("R"..n.." set_frequency failed: "..tostring(err)) end

		if hz > 0 and radio.set_modulation then pcall(radio.set_modulation, radio, hz < 88e6 and 1 or 0) end
	end
end

local function publish(n)
	local o, r = OUT.r[n], R[n]
	local on = powered(n)
	o.v:set(on and 1 or 0)
	o.ch:set(r.man and 0 or r.ch)
	o.freq:set(freq_of(n))
	o.g:set(r.guard and 1 or 0)
	o.rx:set(r.rx and 1 or 0)
	o.txt:set((r.man and "MAN" or ("CH "..r.ch))..(r.guard and " G" or ""))
end

local function step_channel(n, d)
	local r = R[n]
	if r.man then r.man = nil else r.ch = (r.ch - 1 + d) % CHANNELS + 1 end
end


local function entry(n, v)
	if not (n == 1 or n == 2) or type(v) ~= "number" then return false end
	if v == math.floor(v) and v >= 1 and v <= CHANNELS then
		R[n].ch, R[n].man = v, nil
		return true
	end
	local f = math.floor(v * 200 + 0.5) / 200
	if not in_band(f) then return false end
	R[n].man = f
	return true
end

local function ptt(n)
	if not powered(n) then dcs_log("PTT "..n..": R"..n.." off") return end
	S.tx = n
	OUT.tx:set(n)
	if num(IN.link) > 0.5 then
		S.ptt_n = (S.ptt_n or 0) + 1
		OUT.ptt_r:set(n)
		OUT.ptt_n:set(S.ptt_n)
	else
		dispatch_action(nil, COMM_MENU)
	end
end


local function read_back(n)
	local r, sent = R[n], R[n].sent
	if not powered(n) or not sent or sent <= 0 or clock - r.sent_t < READBACK_WAIT then return end
	local radio = GetDevice and GetDevice(DEVICE[n])
	if not radio or type(radio.get_frequency) ~= "function" then return end
	local ok, f = pcall(radio.get_frequency, radio)
	if not ok or type(f) ~= "number" or f < 1E6 or math.abs(f - sent) <= READBACK_TOL then return end

	if type(radio.is_frequency_in_range) == "function" then
		local ok2, inr = pcall(radio.is_frequency_in_range, radio, sent)
		if ok2 and inr == false then return end
	end
	local mhz = math.floor(f / 1E3 + 0.5) / 1E3
	if not in_band(mhz) then return end
	r.man = mhz
	r.sent = math.floor(mhz * 1E6 + 0.5)
	r.sent_t = clock
	dcs_log(string.format("R%d retuned by the comm menu: %.3f MHz", n, mhz))
end

local KEYS = {
	[C.RadioR1ChUp] = function() step_channel(1, 1) end, [C.RadioR1ChDown] = function() step_channel(1, -1) end,
	[C.RadioR2ChUp] = function() step_channel(2, 1) end, [C.RadioR2ChDown] = function() step_channel(2, -1) end,
	[C.RadioR1Power] = function() R[1].on = not R[1].on end, [C.RadioR2Power] = function() R[2].on = not R[2].on end,
	[C.RadioR1Guard] = function() R[1].guard = not R[1].guard end, [C.RadioR2Guard] = function() R[2].guard = not R[2].guard end,
	[C.RadioPtt1] = function() ptt(1) end, [C.RadioPtt2] = function() ptt(2) end,
	[C.RadioR1Rx] = function() R[1].rx = not R[1].rx end, [C.RadioR2Rx] = function() R[2].rx = not R[2].rx end,
}
for c in pairs(KEYS) do dev:listen_command(c) end

function SetCommand(command, value)
	if value == 0 then return end
	local f = KEYS[command]
	if f then
		f()
		for n = 1, 2 do tune(n) publish(n) end
	end
end

function post_initialize()
	for n = 1, 2 do
		load_presets(n)
		tune(n)
		publish(n)
		OUT.r[n].pwr:set(powered(n) and 1 or 0)
	end
	OUT.ptt_n:set(0)
	OUT.tx:set(0)
	OUT.ack:set(0)
	OUT.ok:set(1)
	S.req_seen = num(IN.req_n)
	dcs_log(string.format("up: R1 %.3f, R2 %.3f MHz (channel 1)", freq_of(1), freq_of(2)))
end


local state_last, state_t = nil, 0
local function try(obj, name, ...)
	if not obj or type(obj[name]) ~= "function" then return "-" end
	local ok, v = pcall(obj[name], obj, ...)
	return ok and tostring(v) or ("ERR " .. tostring(v))
end
local function state_line(dt)
	state_t = state_t + dt
	if state_t < 1 then return end
	state_t = 0
	local ic = GetDevice and GetDevice(devices.INTERCOM)
	local parts = {}
	for n = 1, 2 do
		local r = GetDevice(DEVICE[n])
		parts[#parts + 1] = string.format("R%d avail %s is_on %s ON %s freq %s mod %s sentHz %s inrange124 %s", n,
			try(ic, "is_communicator_available", DEVICE[n]), try(r, "is_on"), tostring(num(OUT.r[n].on)),
			try(r, "get_frequency"), try(r, "get_modulation"), tostring(R[n].sent), try(r, "is_frequency_in_range", 124E6))
	end
	parts[#parts + 1] = "intercom avail " .. try(ic, "is_communicator_available", devices.INTERCOM) ..
		" | link " .. tostring(num(IN.link))
	local line = table.concat(parts, " | ")
	if line ~= state_last then state_last = line dcs_log("state: " .. line) end
end

function update()
	local n_req = num(IN.req_n)
	if n_req ~= S.req_seen then
		S.req_seen = n_req
		local ok = entry(math.floor(num(IN.req_r) + 0.5), num(IN.req_v))
		OUT.ok:set(ok and 1 or 0)
		OUT.ack:set(n_req)
	end
	clock = clock + update_time_step
	for n = 1, 2 do
		read_back(n)
		tune(n)
		publish(n)
		OUT.r[n].pwr:set(powered(n) and 1 or 0)
	end
	state_line(update_time_step or 0.02)
end




need_to_be_closed = false
