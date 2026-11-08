













dofile(LockOn_Options.script_path.."command_defs.lua")

local dev = GetSelf()
local update_time_step = 0.1
make_default_activity(update_time_step)

local birth = LockOn_Options.init_conditions and LockOn_Options.init_conditions.birth_place
local hot = birth ~= "GROUND_COLD"

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end

local GW = {cfg = dofile(LockOn_Options.script_path.."Systems/ground_warning_config.lua"),
    valid = param("GW_VALID"), pull = param("GW_PULLUP"), obstacle = param("GW_OBSTACLE"),
    gcws = param("GCWS_ON"), pod = param("TF_POD"), tf = param("NAV_TF_STATE"),
    hud_pull = param("GW_PULLUP_WARN"), hud_obstacle = param("GW_OBSTACLE_WARN"),
    pull_called = false, obstacle_at = -1e9}
for k, v in pairs({DELAY_S = GW.cfg.delay_s, ROLL_RATE = math.rad(GW.cfg.roll_rate_deg_s),
        RECOVERY_G = GW.cfg.recovery_g, MARGIN_M = GW.cfg.margin_m, LOOK_S = GW.cfg.look_s,
        MAX_CLIMB = math.rad(GW.cfg.max_climb_deg), MIN_GS = GW.cfg.min_gs_mps, MAX_AGL = GW.cfg.max_agl_m,
        OBSTACLE_G = GW.cfg.obstacle_g, MAX_AGE = GW.cfg.profile_max_age_s, CLR_FRAC = GW.cfg.clearance_fraction}) do
    param("GW_"..k):set(v)
end
param("GW_CFG_V"):set(1)


GW.gcas = {arm = param("GCAS_ARM"), flyup = param("GCAS_FLYUP"), active = param("GCAS_ACTIVE"),
        g_avail = param("GCAS_G_AVAIL")}
for k, v in pairs({DELAY_S = GW.cfg.gcas.delay_s, ROLL_RATE = math.rad(GW.cfg.gcas.roll_rate_deg_s), G = GW.cfg.gcas.g,
        G_FRAC = GW.cfg.gcas.g_frac, MARGIN_M = GW.cfg.gcas.margin_m, LOOK_S = GW.cfg.gcas.look_s, HOLD_S = GW.cfg.gcas.hold_s}) do
    param("GCAS_"..k):set(v)
end

local E = {}
for _, n in ipairs({"TIME", "SYSTEMS", "BATT_SW", "BATT_CHARGE", "GEN_SW_L", "GEN_SW_R", "GEN_L", "GEN_R", "ELEC_AC",
		"ELEC_DC", "ELEC_ESS", "JFS", "CRANK", "THR_IDLE_L", "THR_IDLE_R", "START_L", "START_R",
		"LIT_L", "LIT_R", "AUTOSTART", "HYD_PC1", "HYD_PC2", "HYD_UTIL", "OIL_L", "OIL_R", "FUEL_LOW", "FUEL_TOTAL_LB",
		"FBW_PITCH", "FBW_ROLL", "FBW_YAW", "WOW", "NZ", "GEAR_POS", "ENG_DMG_L", "ENG_DMG_R", "TIRE"}) do
	E[n] = param("EFM_"..n)
end
local NAV_INS, NAV_GPS = param("NAV_INS"), param("NAV_GPS")
local sensor_data = get_base_data()


local POWER = {
	{out = param("DISP_PWR_HUD"), bus = "AC",  boot = 3.0},
	{out = param("DISP_PWR_LAD"), bus = "AC",  boot = 5.0},
	{out = param("DISP_PWR_EMD"), bus = "ESS", boot = 1.0},
	{out = param("DISP_PWR_RSD"), bus = "ESS", boot = 2.0},
}

local MAX_LINES = 8
local OUT = {mc = param("WARN_MC"), count = param("WARN_COUNT"), bingo = param("DISP_BINGO"), lines = {}}
for i = 1, MAX_LINES do OUT.lines[i] = param("WARN_L"..i) end

local BINGO_DEFAULT, BINGO_STEP, BINGO_MAX = 4000, 500, 20000
local BINGO_REARM = 200

local S = {now = 0, t_log = 0, bingo = BINGO_DEFAULT, active = {}, mc = false, ready = false, prev = {},
	bingo_called = false, voice_queue = {}, s2 = nil, pwr_t = {}, fuel_called = {}, overg = false,
	pullup_t = -1}

local function dcs_log(s)
	if log and log.info then tostring("F15EX WARN "..s) else tostring("F15EX WARN "..s) end
end





local VMS = "Aircrafts/F15EX/VMS/F15EX_VMS_"
local VOICE = {caution = "Caution", bingo = "Bingo", fuel1500 = "Fuel1500", fuel800 = "Fuel800", fuel500 = "Fuel500",
	overg = "OverG", hyd = "Hydraulics", fire_l = "FireL", fire_r = "FireR", pullup = "PullUp", altitude = "Altitude",
    obstacle = "ObstacleAhead"}
local VOICE_PRIO = {pullup = 0, obstacle = 1, altitude = 2, fire_l = 3, fire_r = 3, overg = 4, hyd = 5, bingo = 6, fuel500 = 7,
	fuel800 = 7, fuel1500 = 7, caution = 8}
local sounds = {}
local function init_voice()
	if type(create_sound_host) ~= "function" then dcs_log("voice: no create_sound_host here") return end
	local ok, host = pcall(create_sound_host, "F15EX_VMS", "HEADPHONES", 0, 0, 0)
	if not ok or not host then dcs_log("voice: sound host refused: "..tostring(host)) return end
	for k, name in pairs(VOICE) do
		local ok2, s = pcall(host.create_sound, host, VMS..name)
		if ok2 and s then sounds[k] = s else dcs_log("voice: "..name.." not created: "..tostring(s)) end
	end
end



local VOICE_LEN = {caution = 0.71, bingo = 1.12, fuel1500 = 1.89, fuel800 = 1.89, fuel500 = 1.89, overg = 1.48,
	hyd = 1.76, fire_l = 2.14, fire_r = 2.14, pullup = GW.cfg.emergency_len_s, altitude = GW.cfg.law_len_s,
    obstacle = GW.cfg.obstacle_len_s}
local busy_until, busy_k = -1, nil


local function say(k)
	dcs_log("voice: "..k..(sounds[k] and "" or " (no sound)"))
	if not sounds[k] then return end
	for _, q in ipairs(S.voice_queue) do if q == k then return end end
	local at = #S.voice_queue + 1
	for i, q in ipairs(S.voice_queue) do
		if VOICE_PRIO[k] < VOICE_PRIO[q] then at = i break end
	end
	table.insert(S.voice_queue, at, k)
end


local function voice_tick()
	local first = S.voice_queue[1]
	if not first then return end
	if S.now < busy_until then
		local s = sounds[busy_k]
		if VOICE_PRIO[first] < VOICE_PRIO[busy_k] and s and s.stop then pcall(s.stop, s) else return end
	end
	table.remove(S.voice_queue, 1)
	local s = sounds[first]
	if s.stop then pcall(s.stop, s) end
	pcall(s.play_once, s)
	busy_until, busy_k = S.now + (VOICE_LEN[first] or 2.0) + 0.1, first
end

local function ground_voice(airborne, ess)
    local active = airborne and ess and num(E.GEAR_POS) < 0.5 and num(GW.valid) > 0.5
    local armed = active and num(GW.gcws) > 0.5
    GW.gcas.arm:set(armed and 1 or 0)
    local pull = armed and num(GW.pull) > 0.5



    if not armed then
        GW.pull_called, GW.pull_clear = false, nil
    elseif pull then
        GW.pull_clear = nil
        if not GW.pull_called then
            GW.pull_called = true
            say("pullup")
        end
    elseif GW.pull_called then
        GW.pull_clear = GW.pull_clear or S.now
        if S.now - GW.pull_clear >= GW.cfg.emergency_rearm_s then
            GW.pull_called, GW.pull_clear = false, nil
        end
    end
    local shown = GW.pull_called
    local obstacle = active and num(GW.pod) > 0.5 and num(GW.tf) > 1.5 and num(GW.obstacle) > 0.5 and not shown
    GW.hud_pull:set(shown and 1 or 0)
    GW.hud_obstacle:set(obstacle and 1 or 0)

    local allowed = {pullup = shown, obstacle = obstacle, altitude = airborne and ess and not not S.law_low}
    for i = #S.voice_queue, 1, -1 do
        local k = S.voice_queue[i]
        if allowed[k] == false then table.remove(S.voice_queue, i) end
    end
    if (not airborne or not ess) or (busy_k and allowed[busy_k] == false) then
        local snd = busy_k and sounds[busy_k]
        if snd and snd.stop then pcall(snd.stop, snd) end
        busy_k, busy_until = nil, -1
        if not airborne or not ess then S.voice_queue = {} end
    end
    if obstacle and S.now >= GW.obstacle_at then
        say("obstacle")
        GW.obstacle_at = S.now + GW.cfg.obstacle_repeat_s
    elseif not obstacle then GW.obstacle_at = -1e9 end
end


local FUEL_CALLS = {{1500, "fuel1500"}, {800, "fuel800"}, {500, "fuel500"}}
local FUEL_REARM = 200
local OVERG_G, OVERG_REARM = 9.3, 8.0




local STRIP = {law = param("LAW_ON"), law_ft = param("LAW_FT")}
local LAW_REARM = 1.1
local M_TO_FT = 3.28084

local function base(name)
	local f = sensor_data and sensor_data[name]
	if type(f) ~= "function" then return nil end
	local ok, v = pcall(f)
	return ok and type(v) == "number" and v or nil
end

local function betty(airborne)
	local fuel = num(E.FUEL_TOTAL_LB)
	local lowest
	for _, c in ipairs(FUEL_CALLS) do
		if fuel < c[1] and not S.fuel_called[c[1]] then
			S.fuel_called[c[1]] = true
			lowest = c[2]
		elseif fuel > c[1] + FUEL_REARM then
			S.fuel_called[c[1]] = nil
		end
	end
	if lowest and airborne then say(lowest) end

	local nz = num(E.NZ)
	if nz > OVERG_G and not S.overg then
		S.overg = true
		dcs_log(string.format("over-G: %.1f g", nz))
		if airborne then say("overg") end
	elseif nz < OVERG_REARM then
		S.overg = false
	end
end



local HYD_LOW = 1500
local OIL_LOW = 8
local FIRE_DMG = 0.5


local CAUTIONS = {
	{"L FIRE",    function() return num(E.ENG_DMG_L) > FIRE_DMG end, "fire_l"},
	{"R FIRE",    function() return num(E.ENG_DMG_R) > FIRE_DMG end, "fire_r"},
	{"L ENG",     function(a) return a and num(E.LIT_L) < 0.5 end},
	{"R ENG",     function(a) return a and num(E.LIT_R) < 0.5 end},
	{"L GEN",     function() return num(E.GEN_L) < 0.5 end},
	{"R GEN",     function() return num(E.GEN_R) < 0.5 end},
	{"PC1 HYD",   function() return num(E.HYD_PC1) < HYD_LOW end, "hyd"},
	{"PC2 HYD",   function() return num(E.HYD_PC2) < HYD_LOW end, "hyd"},
	{"UTIL HYD",  function() return num(E.HYD_UTIL) < HYD_LOW end, "hyd"},
	{"L OIL",     function() return num(E.START_L) > 2.5 and num(E.OIL_L) < OIL_LOW end},
	{"R OIL",     function() return num(E.START_R) > 2.5 and num(E.OIL_R) < OIL_LOW end},
	{"BATT",      function() return num(E.ELEC_DC) < 0.5 and num(E.BATT_CHARGE) < 0.3 end},
	{"FUEL LOW",  function() return num(E.FUEL_LOW) > 0.5 end},
	{"BINGO",     function() return num(E.FUEL_TOTAL_LB) < S.bingo end, "bingo"},
	{"FCS",       function() return num(E.FBW_PITCH) + num(E.FBW_ROLL) + num(E.FBW_YAW) < 2.5 end},
	{"TIRE",      function() return num(E.TIRE) > 0.5 end},
	{"INS",       function(a) return a and num(NAV_INS) < 1.5 end},
	{"GPS",       function() return num(NAV_INS) > 0.5 and num(NAV_GPS) < 0.5 end},
	{"LOW ALT",   function(a) return a and S.law_low end, "altitude"},
}


local function update_law(airborne)
	local agl = base("getRadarAltitude")
	local set = num(STRIP.law_ft)
	if not (airborne and agl and num(STRIP.law) > 0.5 and set > 0 and num(E.GEAR_POS) < 0.5) then
		S.law_low = false
		return
	end
	local ft = agl * M_TO_FT
	if ft < set then S.law_low = true elseif ft > set * LAW_REARM then S.law_low = false end
end

local function update_cautions(airborne, ess)
	local list, new, generic = {}, {}, false
	for _, c in ipairs(CAUTIONS) do
		local on = ess and c[2](airborne)
		if on then
			list[#list + 1] = c[1]
			if not S.active[c[1]] then
				new[#new + 1] = c[1]

				if not c[3] then generic = true elseif airborne and c[3] ~= "bingo" then say(c[3]) end
			end
		end
		S.active[c[1]] = on or nil
	end
	if #new > 0 then
		S.mc = true
		dcs_log("caution: "..table.concat(new, ", ").." (now "..#list..")")
		if airborne and generic then say("caution") end
	end
	if not ess then S.mc = false end
	OUT.mc:set(S.mc and 1 or 0)
	OUT.count:set(#list)
	for i = 1, MAX_LINES do
		local t = list[i] or ""
		if i == MAX_LINES and #list > MAX_LINES then t = "+"..(#list - MAX_LINES + 1).." MORE" end
		OUT.lines[i]:set(t)
	end

	local fuel = num(E.FUEL_TOTAL_LB)
	if ess and fuel < S.bingo and not S.bingo_called then
		S.bingo_called = true
		dcs_log(string.format("bingo: %.0f lb below %d", fuel, S.bingo))
		if airborne then say("bingo") end
	elseif fuel > S.bingo + BINGO_REARM then
		S.bingo_called = false
	end
end


local function onoff(v) return v > 0.5 and "ON" or "OFF" end
local REPORTS = {
	{"BATT_SW",    function(v) return "BATTERY "..onoff(v) end},
	{"GEN_SW_L",   function(v) return "L GEN "..onoff(v) end},
	{"GEN_SW_R",   function(v) return "R GEN "..onoff(v) end},
	{"JFS",        function(v) return ({[0] = "JFS OFF", [1] = "JFS START", [2] = "JFS RUNNING"})[math.floor(v + 0.5)] end},
	{"CRANK",      function(v) return ({[0] = "JFS CRANK OFF", [1] = "JFS CRANK L", [2] = "JFS CRANK R"})[math.floor(v + 0.5)] end},
	{"THR_IDLE_L", function(v) return v > 0.5 and "L THROTTLE IDLE" or "L THROTTLE OFF" end},
	{"THR_IDLE_R", function(v) return v > 0.5 and "R THROTTLE IDLE" or "R THROTTLE OFF" end},
	{"LIT_L",      function(v) return v > 0.5 and "L ENGINE LIGHT-OFF" or "L ENGINE OUT" end},
	{"LIT_R",      function(v) return v > 0.5 and "R ENGINE LIGHT-OFF" or "R ENGINE OUT" end},
	{"AUTOSTART",  function(v, old) if v > 0.5 and old < 0.5 then return "AUTO START" elseif v < 0.5 and old > 0.5 then return "AUTO START DONE" end end},
}

local function report()
	for _, r in ipairs(REPORTS) do
		local v = num(E[r[1]])
		local old = S.prev[r[1]]
		if old ~= nil and math.abs(v - old) > 0.5 then
			local m = r[2](v, old)
			if m then
				if print_message_to_user then print_message_to_user(m) end
				dcs_log("switch: "..m)
			end
		end
		S.prev[r[1]] = v
	end
end


local function update_power(dt)
	local efm_up = num(E.TIME) > 0
	if efm_up and S.s2 == nil and num(E.TIME) > 1.0 then
		S.s2 = num(E.SYSTEMS) > 0.5
		dcs_log("EFM systems "..(S.s2 and "present (S2): displays follow the buses" or "MISSING: displays always powered"))
	end
	for i, p in ipairs(POWER) do
		local on
		if S.s2 == false then on = true
		elseif not efm_up or S.s2 == nil then on = hot


		elseif p.bus == "AC" then
			on = num(E.ELEC_AC) > 0.5 or (num(E.ELEC_ESS) > 0.5 and num(E.JFS) > 1.5)
		else on = num(E.ELEC_ESS) > 0.5 end
		if on then S.pwr_t[i] = (S.pwr_t[i] or (hot and p.boot or 0)) + dt else S.pwr_t[i] = 0 end
		p.out:set(S.pwr_t[i] >= p.boot and 1 or 0)
	end
end


local LISTEN = {device_commands.MasterCaution, device_commands.BingoUp, device_commands.BingoDown}
for _, c in ipairs(LISTEN) do dev:listen_command(c) end

for c = device_commands.ElecBattery, device_commands.AutoStart do dev:listen_command(c) end

function post_initialize()
	S.now = get_model_time()
	OUT.bingo:set(S.bingo)
	OUT.mc:set(0)
	OUT.count:set(0)
	for i = 1, MAX_LINES do OUT.lines[i]:set("") end
	for _, p in ipairs(POWER) do p.out:set(hot and 1 or 0) end
	init_voice()
	dcs_log("up, birth "..tostring(birth))
end

function SetCommand(command, value)
	if value == 0 then return end
	if command == device_commands.MasterCaution then
		S.mc = false
	elseif command == device_commands.BingoUp then
		S.bingo = math.min(BINGO_MAX, S.bingo + BINGO_STEP)
		OUT.bingo:set(S.bingo)
	elseif command == device_commands.BingoDown then
		S.bingo = math.max(0, S.bingo - BINGO_STEP)
		OUT.bingo:set(S.bingo)
	end
end



local MC_REQ = {p = get_param_handle("WARN_MC_REQ"), seen = nil}
local function mc_request()
	local n = num(MC_REQ.p)
	if MC_REQ.seen and n ~= MC_REQ.seen then S.mc = false end
	MC_REQ.seen = n
end

local BINGO_REQ = {n = get_param_handle("BINGO_REQ_N"), v = get_param_handle("BINGO_REQ_V"), seen = nil}
local function bingo_request()
	local n = num(BINGO_REQ.n)
	if BINGO_REQ.seen and n ~= BINGO_REQ.seen then
		S.bingo = math.max(0, math.min(BINGO_MAX, num(BINGO_REQ.v)))
		OUT.bingo:set(S.bingo)
	end
	BINGO_REQ.seen = n
end

function update()
	local dt = update_time_step
	S.now = get_model_time()
	bingo_request()
	update_power(dt)
	if num(E.TIME) <= 0 then return end
	local airborne = num(E.WOW) < 0.5
	local ess = S.s2 ~= false and num(E.ELEC_ESS) > 0.5
	mc_request()
	report()
	update_law(airborne)
	update_cautions(airborne, ess)
	if ess then betty(airborne) end
	ground_voice(airborne, ess)
	voice_tick()
	S.t_log = S.t_log + dt
	if S.t_log >= 10 then
		S.t_log = 0
		local list = {}
		for i = 1, MAX_LINES do local t = OUT.lines[i]:get() if t ~= "" then list[#list + 1] = t end end
		dcs_log(string.format("t=%.0f power HUD %d LAD %d EMD %d RSD %d, MC %d, cautions: %s", S.now, num(POWER[1].out),
			num(POWER[2].out), num(POWER[3].out), num(POWER[4].out), S.mc and 1 or 0, table.concat(list, " ")))
	end
end




need_to_be_closed = false
