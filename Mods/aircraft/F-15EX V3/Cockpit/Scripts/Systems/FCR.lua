




local dev = GetSelf()

local update_time_step = 0.05
make_default_activity(update_time_step)


link_to_target_responder = true

render_debug_info = false

perfomance =
{
	roll_compensation_limits	= {math.rad(-180.0), math.rad(180.0)},
	pitch_compensation_limits	= {math.rad(-85.0), math.rad(85.0)},

	tracking_azimuth			= {math.rad(-90.0), math.rad(90.0)},



	tracking_elevation			= {math.rad(-60.0), math.rad(60.0)},








	scan_volume_azimuth			= math.rad(120.0),
	scan_volume_elevation		= math.rad(180.0),
	scan_beam					= math.rad(120.0),
	scan_speed					= math.rad(360.0),




	max_available_distance		= 800000.0,


	ground_clutter =
	{
		sea				= {0, 0, 0},
		land			= {0, 0, 0},
		artificial		= {0, 0, 0},
		rays_density	= 0.05,
		max_distance	= 1000,
	},
}

local power = get_param_handle("MSLTEST_RADAR_POWER")
local powered = nil







local LOS_SLOTS = 32
local LOS_PER_UPDATE = 8
local los_count = get_param_handle("RDR_LOS_COUNT")
local los_own = {get_param_handle("RDR_LOS_OX"), get_param_handle("RDR_LOS_OY"), get_param_handle("RDR_LOS_OZ")}
local los_q, los_a = {}, {}
for k = 1, LOS_SLOTS do
	local p = string.format("RDR_LOS_%02d_", k)
	los_q[k] = {id = get_param_handle(p.."ID"), x = get_param_handle(p.."X"), y = get_param_handle(p.."Y"),
		z = get_param_handle(p.."Z")}
	los_a[k] = {vid = get_param_handle(p.."VID"), v = get_param_handle(p.."V"), vt = get_param_handle(p.."VT")}
end
local LOS = {state = "new", next = 1, seq = 0}




local DL_LOS_SLOTS = 16
local DL_LOS_PER_UPDATE = 3
local dl_los_count = get_param_handle("DL_LOS_COUNT")
local dl_q = {}
for k = 1, DL_LOS_SLOTS do
	local p = string.format("DL_LOS_%02d_", k)
	dl_q[k] = {q = get_param_handle(p.."Q"), ox = get_param_handle(p.."OX"), oy = get_param_handle(p.."OY"),
		oz = get_param_handle(p.."OZ"), x = get_param_handle(p.."X"), y = get_param_handle(p.."Y"), z = get_param_handle(p.."Z"),
		aq = get_param_handle(p.."AQ"), v = get_param_handle(p.."V")}
end
local DLL = {next = 1}




local clock = (os and type(os.clock) == "function") and os.clock or nil
local LOS_BUDGET_S = 0.002

local function dcs_log(s)
	if log and log.info then tostring("F15EX FCR "..s) else tostring("F15EX FCR "..s) end
end


local function terrain_module()
	local how = {}
	for _, n in ipairs({"Terrain", "terrain"}) do
		local g = type(_G) == "table" and _G[n] or nil
		how[#how + 1] = n.."="..type(g)
		if type(g) == "table" and type(g.isVisible) == "function" then return g, table.concat(how, " ") end
	end
	if type(require) == "function" then
		local ok, m = pcall(require, "terrain")
		how[#how + 1] = "require('terrain')="..(ok and type(m) or ("error: "..tostring(m)))
		if ok and type(m) == "table" and type(m.isVisible) == "function" then return m, table.concat(how, " ") end
	else
		how[#how + 1] = "require="..type(require)
	end
	return nil, table.concat(how, " ")
end

local function yes(v) return v == true or v == 1 end


local function los_pick(ox, oy, oz)
	local T, how = terrain_module()
	if not T then dcs_log("LOS: no Terrain.isVisible here ("..how.."): terrain masking off") return nil end
	local gh = type(T.GetHeight) == "function" and select(2, pcall(T.GetHeight, ox, oz)) or nil
	if type(gh) ~= "number" then gh = oy - 3000 end
	local orders = {
		{"x, alt, z", function(a, b, c, d, e, f) return T.isVisible(a, b, c, d, e, f) end},
		{"x, z, alt", function(a, b, c, d, e, f) return T.isVisible(a, c, b, d, f, e) end},
	}
	local log_s = {}
	local pick
	for _, o in ipairs(orders) do
		local ok1, up = pcall(o[2], ox, oy, oz, ox + 10, oy + 3000, oz + 10)
		local ok2, down = pcall(o[2], ox, oy, oz, ox + 10, gh - 50, oz + 10)
		log_s[#log_s + 1] = string.format("(%s): up %s, into the ground %s", o[1], ok1 and tostring(up) or ("error "..tostring(up)),
			ok2 and tostring(down) or ("error "..tostring(down)))
		if not pick and ok1 and ok2 and yes(up) and not yes(down) then pick = o end
	end
	dcs_log(string.format("LOS: %s; GetHeight %s (%.0f m under us, own alt %.0f m); %s", how, type(T.GetHeight),
		gh, oy, table.concat(log_s, "; ")))
	if not pick then dcs_log("LOS: no argument order passed the check: terrain masking off") return nil end


	dcs_log("LOS: on, order "..pick[1]..string.format(", %d per update", LOS_PER_UPDATE))
	return pick[2]
end

local function los_step()
	if LOS.state == "off" then return end
	local n = math.min(LOS_SLOTS, math.floor(los_count:get() or 0))
	if n <= 0 then return end
	local ox, oy, oz = los_own[1]:get(), los_own[2]:get(), los_own[3]:get()
	if LOS.state == "new" then
		LOS.fn = los_pick(ox, oy, oz)
		LOS.state = LOS.fn and "on" or "off"
		if not LOS.fn then return end
	end
	local now = get_model_time()
	for i = 1, math.min(LOS_PER_UPDATE, n) do
		if clock and i > 1 and clock() - LOS.t0 >= LOS_BUDGET_S then break end
		local k = LOS.next
		if k > n then k = 1 end
		LOS.next = k + 1
		local q = los_q[k]
		local id = q.id:get()
		if id and id > 0 then
			local ok, v = pcall(LOS.fn, ox, oy, oz, q.x:get(), q.y:get(), q.z:get())
			if not ok then
				dcs_log("LOS: isVisible failed ("..tostring(v).."): terrain masking off")
				LOS.state = "off"
				return
			end
			LOS.seq = LOS.seq + 1
			local a = los_a[k]
			a.vid:set(id)
			a.v:set(yes(v) and 1 or 0)
			a.vt:set(now + LOS.seq * 1e-6)
		end
	end
end

local function dl_los_step()
	if LOS.state == "off" then return end
	local n = math.min(DL_LOS_SLOTS, math.floor(dl_los_count:get() or 0))
	if n <= 0 then return end
	if LOS.state == "new" then
		local q = dl_q[1]
		LOS.fn = los_pick(q.ox:get(), q.oy:get(), q.oz:get())
		LOS.state = LOS.fn and "on" or "off"
		if not LOS.fn then return end
	end
	for i = 1, math.min(DL_LOS_PER_UPDATE, n) do
		if clock and i > 1 and clock() - LOS.t0 >= LOS_BUDGET_S then break end
		local k = DLL.next
		if k > n then k = 1 end
		DLL.next = k + 1
		local q = dl_q[k]
		local id = q.q:get()
		if id and id > 0 and id ~= q.aq:get() then
			local ok, v = pcall(LOS.fn, q.ox:get(), q.oy:get(), q.oz:get(), q.x:get(), q.y:get(), q.z:get())
			if not ok then
				dcs_log("LOS: isVisible failed ("..tostring(v).."): terrain masking off")
				LOS.state = "off"
				return
			end
			q.v:set(yes(v) and 1 or 0)
			q.aq:set(id)
		end
	end
end







local SURF_PERIOD = 2.0
local surf_out, gnd_out = get_param_handle("RDR_SURF"), get_param_handle("RDR_GND_H")
local own_hdg = get_param_handle("RDR_OWN_HDG")
local SURF = {t = -1e9, T = nil, tried = false}

local function surf_step()
	local now = get_model_time()
	if now - SURF.t < SURF_PERIOD then return end
	SURF.t = now
	if not SURF.tried then SURF.T = terrain_module(); SURF.tried = true end
	local T = SURF.T
	if not T or type(T.GetHeight) ~= "function" then return end
	local ox, oy, oz = los_own[1]:get(), los_own[2]:get(), los_own[3]:get()
	if not ox or (ox == 0 and oz == 0 and oy == 0) then return end
	local ok, gh = pcall(T.GetHeight, ox, oz)
	if not ok or type(gh) ~= "number" then return end
	gnd_out:set(gh)
	local h = math.rad(own_hdg:get() or 0)
	local d = math.min(30000, math.max(5000, 5 * (oy - gh)))
	local cx, cz = ox + d * math.cos(h), oz + d * math.sin(h)
	local has_type = type(T.GetSurfaceType) == "function"
	local water, n, lo, hi = 0, 0, 1e9, -1e9
	for i = -2, 2 do
		for j = -2, 2 do
			local x, z = cx + 2000 * i, cz + 2000 * j
			local okh, y = pcall(T.GetHeight, x, z)
			if okh and type(y) == "number" then
				n = n + 1
				local wet
				if has_type then
					local okt, st = pcall(T.GetSurfaceType, x, z)
					st = okt and type(st) == "string" and st:lower() or ""
					wet = st:find("sea") or st:find("water") or st:find("lake") or st:find("river")
				else
					wet = y < 1
				end
				if wet then water = water + 1 else lo = math.min(lo, y); hi = math.max(hi, y) end
			end
		end
	end
	if n == 0 then return end
	local id
	if water * 2 > n then id = 1
	elseif hi - lo < 30 then id = 4
	elseif hi - lo < 200 then id = 5
	else id = 6 end
	surf_out:set(id)
end

function post_initialize()
    get_param_handle("RDR_APG82_V1"):set(get_aircraft_type() == "F15IA" and 1 or 0)
end

function SetCommand(command, value)
end

function update()
	local on = power:get() == 1
	if on ~= powered then
		dev:set_power(on)
		powered = on
	end
	LOS.t0 = clock and clock() or 0
	los_step()
	dl_los_step()
	surf_step()
end




need_to_be_closed = false
