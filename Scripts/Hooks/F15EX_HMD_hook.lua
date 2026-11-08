











do



	local MOD_NAMES = {"F-15EX V3 log", "F-15EX V3 no log", "F-15EX V3"}
	local HM_REL = "Cockpit/Scripts/Systems/hmd_math.lua"
	local CMD_AZ, CMD_EL, CMD_ROLL, CMD_TIME, CMD_COAL = 10001, 10002, 10003, 10004, 10005
	local TIME_WRAP = 64.0
	local TYPES = {F15EX = true, F15EX_CFT = true, F15IA = true}
	local LOG_PERIOD = 10.0
	local JIG = 2e-6

	local function say(level, s)
		if log and log.write then tostring("F15EX_HMD", level, s) end
	end

	local L = lfs
	if not (L and L.writedir) then
		local ok, m = pcall(require, "lfs")
		L = ok and m or nil
	end
	local HM
	if L then
		local air = L.writedir().."Mods/aircraft/"
		local function exists(p) return type(L.attributes) == "function" and L.attributes(p, "mode") == "file" end
		local path
		for _, n in ipairs(MOD_NAMES) do
			if exists(air..n.."/"..HM_REL) then path = air..n.."/"..HM_REL break end
		end
		if not path and type(L.dir) == "function" then
			local ok_dir, it, st = pcall(L.dir, air)
			if ok_dir then
				for n in it, st do
					if n:sub(1, 6) == "F-15EX" and exists(air..n.."/"..HM_REL) then path = air..n.."/"..HM_REL break end
				end
			end
		end
		if path then
			local ok, m = pcall(dofile, path)
			if ok and type(m) == "table" then HM = m say(log.INFO, "hmd_math.lua from "..path)
			else say(log.ERROR, "hmd_math.lua not loaded: "..tostring(m)) end
		else
			say(log.ERROR, "hmd_math.lua not found under "..air.." (no F-15EX folder has "..HM_REL..")")
		end
	end



	local LK, lk_tried
	local function link()
		if lk_tried then return LK end
		lk_tried = true
		local m = package.loaded.F15EX_FM
		if type(m) == "table" then LK = m return LK end
		if not (L and L.writedir and L.attributes) then say(log.ERROR, "units: no lfs, no DLL module") return nil end
		local air = L.writedir().."Mods\\aircraft\\"
		local function has(n) return L.attributes(air..n.."\\bin\\F15EX_FM.dll", "mode") == "file" end
		local bin
		for _, n in ipairs(MOD_NAMES) do
			if has(n) then bin = air..n.."\\bin\\" break end
		end
		if not bin and type(L.dir) == "function" then
			local ok_dir, it, st = pcall(L.dir, air)
			if ok_dir then
				for n in it, st do
					if n:sub(1, 6) == "F-15EX" and has(n) then bin = air..n.."\\bin\\" break end
				end
			end
		end
		if not bin then say(log.ERROR, "units: no Mods\\aircraft\\F-15EX*\\bin\\F15EX_FM.dll") return nil end
		local cpath = package.cpath
		package.cpath = bin.."?.dll;"..cpath
		local ok, r = pcall(require, "F15EX_FM")
		package.cpath = cpath
		if ok and type(r) == "table" then
			LK = r
			say(log.INFO, "units: the DLL's module from "..bin)
		else
			say(log.ERROR, "units: the DLL's module not loaded from "..bin..": "..tostring(r))
		end
		return LK
	end

	local E = Export
	local function fn(name) return E and type(E[name]) == "function" and E[name] or nil end
	local get_self, get_cam = fn("LoGetSelfData"), fn("LoGetCameraPosition")

	local send, how
	if fn("LoSetCommand") then
		local set = fn("LoSetCommand")
		send = function(az, el, roll, t, coal)
			set(CMD_AZ, az) set(CMD_EL, el) set(CMD_ROLL, roll) set(CMD_TIME, t)
			if coal then set(CMD_COAL, coal) end
		end
		how = "Export.LoSetCommand"
	elseif net and type(net.dostring_in) == "function" then
		send = function(az, el, roll, t, coal)
			net.dostring_in("export", string.format(
				"LoSetCommand(%d,%.9g) LoSetCommand(%d,%.9g) LoSetCommand(%d,%.9g) LoSetCommand(%d,%.9g)",
				CMD_AZ, az, CMD_EL, el, CMD_ROLL, roll, CMD_TIME, t)
				..(coal and string.format(" LoSetCommand(%d,%.9g)", CMD_COAL, coal) or ""))
		end
		how = "net.dostring_in export"
	end








	local MSL = {BASE = 10020, SLOTS = 6, PERIOD = 0.1, NEAR_M = 600, t = -1e9, serial = 0, slots = {}, by_id = {},
		seen = {}, logged = false, failed = false}
	local get_world = fn("LoGetWorldObjects")
	local set_cmd = fn("LoSetCommand")
	local function msl_send(c, v)
		if set_cmd then set_cmd(c, v)
		else net.dostring_in("export", string.format("LoSetCommand(%d,%.9g)", c, v)) end
	end





	MSL.QUERY = "local o = LoGetWorldObjects('ballistic') or {} local r = {} for id, v in pairs(o) do "
		.."local ty, p = v.Type, v.Position if type(ty) == 'table' and type(p) == 'table' and ty.level2 == 4 then "
		.."r[#r + 1] = string.format('[%s]={Name=%q,CoalitionID=%s,Type={level1=%s,level2=%s,level3=%s,level4=%s},"
		.."Position={x=%.3f,y=%.3f,z=%.3f}}', tostring(id), tostring(v.Name), tostring(v.CoalitionID), "
		.."tostring(ty.level1), tostring(ty.level2), tostring(ty.level3), tostring(ty.level4), p.x, p.y, p.z) end end "
		.."return '{'..table.concat(r, ',')..'}'"
	MSL.DIAG = 30.0
	MSL.diag_t = -1e9
	local function world_ballistic(t)
		local objs = get_world and get_world("ballistic")
		if type(objs) == "table" and next(objs) ~= nil then return objs, "direct" end
		local why = "direct: "..type(objs)..(type(objs) == "table" and " (empty)" or "")
		if net and type(net.dostring_in) == "function" then
			local ok, str = pcall(net.dostring_in, "export", MSL.QUERY)
			if ok and type(str) == "string" and str:sub(1, 1) == "{" then
				local f = (loadstring or load)("return "..str)
				local ok2, tbl = pcall(f or error)
				if ok2 and type(tbl) == "table" then
					if next(tbl) ~= nil then return tbl, "export state" end
					why = why..", export state: none"
				else
					why = why..", export state: unreadable"
				end
			else
				why = why..", export state: "..tostring(str)
			end
		end
		if not MSL.logged and t - MSL.diag_t >= MSL.DIAG then
			MSL.diag_t = t
			say(log.INFO, "missile export: no missiles in flight seen ("..why..")")
		end
		return nil
	end

	local function missiles(self, t)
		if t - MSL.t < MSL.PERIOD - 1e-6 then return end
		local dt = t - MSL.t
		MSL.t = t
		local objs, path = world_ballistic(t)
		if type(objs) ~= "table" then objs = {} end
		local own = self.Position
		local coal = tonumber(self.CoalitionID)

		local list = {}
		for id, o in pairs(objs) do
			local ty = type(o) == "table" and o.Type
			local p = type(o) == "table" and o.Position
			if type(ty) == "table" and ty.level2 == 4 and type(p) == "table" and p.x then
				if not MSL.logged then
					MSL.logged = true
					say(log.INFO, string.format("missile export: first missile seen: %s, type %s.%s.%s.%s, coalition %s (%s)",
						tostring(o.Name), tostring(ty.level1), tostring(ty.level2), tostring(ty.level3), tostring(ty.level4),
						tostring(o.CoalitionID), tostring(path)))
				end
				list[id] = o
			end
		end

		for k = 1, MSL.SLOTS do
			local s = MSL.slots[k]
			if s and not list[s.id] then
				say(log.INFO, string.format("missile export: slot %d (serial %d) gone", k, s.serial))
				MSL.by_id[s.id] = nil
				MSL.slots[k] = nil
			end
		end

		for id, o in pairs(list) do
			local p = o.Position
			local k = MSL.by_id[id]
			if not k and not MSL.seen[id] and own and own.x then
				MSL.seen[id] = true
				local d = math.sqrt((p.x - own.x) ^ 2 + (p.y - own.y) ^ 2 + (p.z - own.z) ^ 2)
				local oc = tonumber(o.CoalitionID)
				if d <= MSL.NEAR_M and not (oc and coal and oc ~= coal) then
					for s = 1, MSL.SLOTS do
						if not MSL.slots[s] then
							MSL.serial = MSL.serial + 1
							MSL.slots[s] = {id = id, serial = MSL.serial}
							MSL.by_id[id] = s
							k = s
							say(log.INFO, string.format("missile export: ours %s in slot %d (serial %d), %.0f m off",
								tostring(o.Name), s, MSL.serial, d))
							break
						end
					end
				end
			end
			if k then
				local s = MSL.slots[k]
				local vx, vy, vz = 0, 0, 0
				if s.p and dt > 0 and dt < 1 then
					vx, vy, vz = (p.x - s.p.x) / dt, (p.y - s.p.y) / dt, (p.z - s.p.z) / dt
				end
				s.p = {x = p.x, y = p.y, z = p.z}
				local b = MSL.BASE + 8 * (k - 1)

				msl_send(b, s.serial + ((s.serial + math.floor(t / MSL.PERIOD)) % 2 == 0 and 1 or -1) * JIG * 1000)
				msl_send(b + 1, p.x) msl_send(b + 2, p.y) msl_send(b + 3, p.z)
				msl_send(b + 4, vx) msl_send(b + 5, vy) msl_send(b + 6, vz)
			end
		end
	end




	local BE = {X = 10070, Z = 10071, PERIOD = 1.0, t = -1e9, by_coal = nil, n = 0, logged = false}
	local function bulls_read()
		BE.by_coal = {}
		local m = DCS and DCS.getCurrentMission and DCS.getCurrentMission()
		m = type(m) == "table" and (m.mission or m) or nil
		local c = type(m) == "table" and m.coalition
		if type(c) ~= "table" then say(log.INFO, "bullseye: no coalition table in the mission") return end
		for side, id in pairs({red = 1, blue = 2}) do
			local b = type(c[side]) == "table" and c[side].bullseye
			if type(b) == "table" and tonumber(b.x) and tonumber(b.y) then
				BE.by_coal[id] = {x = tonumber(b.x), z = tonumber(b.y)}
				say(log.INFO, string.format("bullseye %s: x %.0f z %.0f", side, b.x, b.y))
			end
		end
	end
	local function bulls(self, t)
		if t - BE.t < BE.PERIOD - 1e-6 then return end
		BE.t = t
		if not BE.by_coal then bulls_read() end
		local b = BE.by_coal[tonumber(self.CoalitionID) or 0]
		if not b then return end
		BE.n = BE.n + 1
		local j = (BE.n % 2 == 0) and 1e-3 or -1e-3
		msl_send(BE.X, b.x + j)
		msl_send(BE.Z, b.z + j)
	end








	local UN = {done = false}
	local SHORT = {F15EX = "F-15EX", F15EX_CFT = "F-15EX", F15IA = "F-15IA", ["FA-18C_hornet"] = "F/A-18C"}
	local function short_type(t)
		if SHORT[t] then return SHORT[t] end
		local g = DCS and DCS.getUnitTypeAttribute
		local ok, s = false, nil
		if type(g) == "function" then ok, s = pcall(g, t, "DisplayNameShort") end
		if ok and type(s) == "string" and s ~= "" and #s <= 10 then return s end
		s = tostring(t):match("^([^_]+)") or tostring(t)
		return s:upper():sub(1, 10)
	end


	local function type_rcs(t)
		local g = DCS and DCS.getUnitTypeAttribute
		if type(g) ~= "function" then return 0 end
		local ok, r = pcall(g, t, "RCS")
		r = ok and tonumber(r) or nil
		return (r and r > 0 and r < 1e4) and r or 0
	end




	UN.PERIOD = 2.0
	local function runtime_id(u)
		local gp, k = DCS and DCS.getUnitProperty, DCS and DCS.UNIT_RUNTIME_ID
		if type(gp) ~= "function" or k == nil then return 0 end
		local ok, r = pcall(gp, u.id, k)
		r = ok and tonumber(r) or nil
		return (r and r > 0) and math.floor(r) or 0
	end
	local function units_send()
		local lines, n_obj = {}, 0
		for _, u in ipairs(UN.list) do
			if u.obj == 0 then u.obj = runtime_id(u) end
			if u.obj ~= 0 then n_obj = n_obj + 1 end
			lines[#lines + 1] = string.format("%d\t%d\t%s\t%.6g\t%d", u.id, u.coal, u.short, u.rcs, u.obj)
		end
		if UN.written and n_obj == UN.n_obj then return end
		local lk = link()
		if not (lk and lk.units(table.concat(lines, "\n").."\n")) then UN.list = {} return end
		UN.written, UN.n_obj = true, n_obj
		say(log.INFO, string.format("units: %d units handed to the DLL, %d with an object ID", #lines, n_obj))

		local pid = fn("LoGetPlayerPlaneId") and tonumber(fn("LoGetPlayerPlaneId")())
		if pid and not UN.checked then
			for _, u in ipairs(UN.list) do
				if u.obj == pid then
					UN.checked = true
					say(log.INFO, string.format("units: own object ID %d = unit %d (%s): runtime IDs match the export's", pid, u.id, u.short))
				end
			end
		end
	end
	local function units_write(t)
		if not UN.done then
			UN.done, UN.list, UN.written, UN.n_obj, UN.checked = true, {}, false, -1, false
			local m = DCS and DCS.getCurrentMission and DCS.getCurrentMission()
			m = type(m) == "table" and (m.mission or m) or nil
			local c = type(m) == "table" and m.coalition
			if type(c) ~= "table" then return end
			for side, id in pairs({red = 1, blue = 2}) do
				for _, ctry in ipairs(type(c[side]) == "table" and c[side].country or {}) do
					for _, cat in ipairs({"plane", "helicopter", "vehicle", "ship"}) do
						for _, g in ipairs(type(ctry[cat]) == "table" and ctry[cat].group or {}) do
							for _, u in ipairs(g.units or {}) do
								if tonumber(u.unitId) and u.type then
									UN.list[#UN.list + 1] = {id = tonumber(u.unitId), coal = id, short = short_type(u.type),
										rcs = type_rcs(u.type), obj = 0}
								end
							end
						end
					end
				end
			end
			if DCS and type(DCS.getUnitProperty) == "function" and DCS.UNIT_RUNTIME_ID ~= nil then
				say(log.INFO, "units: object IDs via DCS.getUnitProperty UNIT_RUNTIME_ID")
			else
				say(log.ERROR, "units: no DCS.getUnitProperty / UNIT_RUNTIME_ID here: no object IDs (radar uses contact / default RCS)")
			end
			UN.t = t
			units_send()
			return
		end
		if UN.n_obj >= 0 and UN.n_obj < #UN.list and t - UN.t >= UN.PERIOD then
			UN.t = t
			units_send()
		end
	end




    local RF={t=-1e9,failed=false}
    local RF_QUERY=[[
        if not (coalition and coalition.getGroups and Group and Group.Category and timer) then return 'unavailable' end
        local rows={string.format('%.3f',timer.getTime())};local count=0
        for _,side in ipairs({0,1,2}) do
            for _,g in pairs(coalition.getGroups(side,Group.Category.SHIP) or {}) do
                if g:isExist() then for _,u in pairs(g:getUnits() or {}) do
                    if u:isExist() and u:isActive() then
                        local on=u:getRadar()
                        if on then
                            local p=u:getPoint();local id=u:getID()
                            rows[#rows+1]=string.format('%u,%.3f,%.3f,%.3f',id,p.x,p.y,p.z);count=count+1
                            if count>=128 then return table.concat(rows,';') end
                        end
                    end
                end end
            end
        end
        return table.concat(rows,';')
    ]]
    local function rf_send(t)
        if RF.failed or (t>=RF.t and t-RF.t<1) then return end
        RF.t=t
        local lk=link();if not lk then return end
        if type(lk.rf)~='function' then RF.failed=true return end
        if not (net and net.dostring_in) then RF.failed=true return end
        local ok,text=pcall(net.dostring_in,'mission',RF_QUERY)
        if not ok or type(text)~='string' or text=='unavailable' then return end
        if not lk.rf(text) then RF.failed=true end
    end
	local WX = {done = false, failed = false, t = -1e9, last = nil, static = nil, fog_note = false}
	local FOG_QUERY = "local w=world and world.weather if not (w and w.getFogThickness and w.getFogVisibilityDistance) then return 'unavailable' end return tostring(w.getFogThickness())..','..tostring(w.getFogVisibilityDistance())"
	local SOLAR_QUERY = "if not (coord and coord.LOtoLL) then return '' end local lat,lon=coord.LOtoLL({x=0,y=0,z=0}) return tostring(lat)..','..tostring(lon)"
	local function preset_layers(cl)
		if type(cl.preset) ~= "string" then return nil end

		local f = loadfile and loadfile("Config/Effects/clouds.lua")
		if not f then return nil end
		local env = setmetatable({_ = function(v) return v end}, {__index = _G})
		setfenv(f, env)
		local ok = pcall(f)
		local preset = ok and env.clouds and env.clouds.presets and env.clouds.presets[cl.preset]
		if not (preset and type(preset.layers) == "table") then return nil end
		local low = math.huge
		for _, l in ipairs(preset.layers) do low = math.min(low, tonumber(l.altitudeMin) or math.huge) end
		if low == math.huge then return nil end

		local shift, rows = (tonumber(cl.base) or low) - low, {}
		for _, l in ipairs(preset.layers) do
			local lo, hi, cover = tonumber(l.altitudeMin), tonumber(l.altitudeMax), tonumber(l.coverage)
			if lo and hi and hi > lo and cover then
				if #rows >= 8 then return nil end
				rows[#rows+1] = string.format("%.1f:%.1f:%.3f", lo+shift, hi+shift, math.max(0, math.min(10, cover*10)))
			end
		end
		return #rows > 0 and table.concat(rows, ",") or nil
	end
	local function weather_send()
		local t = DCS and DCS.getModelTime and DCS.getModelTime() or 0
		if t >= WX.t and t - WX.t < 5 then return end
		WX.t = t
		local lk = link()
		if not (lk and lk.weather) then return end
		if not WX.static then
			local m = DCS and DCS.getCurrentMission and DCS.getCurrentMission()
			m = type(m) == "table" and (m.mission or m) or nil
			local w = type(m) == "table" and m.weather
			if type(w) ~= "table" then return end
			local fog = (w.enable_fog and type(w.fog) == "table") and w.fog or {}
			WX.fog_vis, WX.fog_top = tonumber(fog.visibility) or 0, tonumber(fog.thickness) or 0
			local cl = type(w.clouds) == "table" and w.clouds or {}
			local base, thick, dens = tonumber(cl.base) or 0, tonumber(cl.thickness) or 0, tonumber(cl.density) or 0
			local rain = ({[1] = 4, [2] = 15, [3] = 2, [4] = 6})[tonumber(cl.iprecptns) or 0] or 0
			local layers = preset_layers(cl)
			if cl.preset and not layers then

				say(log.ERROR, "weather: preset layers unavailable; legacy mission cloud values used")
			end
			WX.static = string.format("vis=%.0f;cloud_base=%.0f;cloud_top=%.0f;cloud_dens=%.0f;rain=%.1f",
				type(w.visibility) == "table" and tonumber(w.visibility.distance) or 40000, base, base+thick, dens, rain)
			if layers then WX.static = WX.static..";layers="..layers end
			local date = type(m.date) == "table" and m.date or {}
			local geo = net and net.dostring_in and net.dostring_in("mission", SOLAR_QUERY)
			local lat, lon
			if type(geo) == "string" then lat, lon = geo:match("^([%d%.%-]+),([%d%.%-]+)$") end
			lat, lon = tonumber(lat), tonumber(lon)
			local ok_terrain, terrain = pcall(require, "terrain")
			local summer = ok_terrain and terrain.GetTerrainConfig and terrain.GetTerrainConfig("SummerTimeDelta")
			if lat and lon and date.Year and date.Month and date.Day and tonumber(m.start_time) and
				type(summer) == "number" and DCS.getSunAzimuthElevation then
				local local_s = m.start_time + t - summer*3600
				local az, el = DCS.getSunAzimuthElevation(lat, lon, date.Year, date.Month, date.Day, local_s)
				if type(az) == "number" and type(el) == "number" then
					WX.static = WX.static..string.format(";solar=1;year=%d;month=%d;day=%d;local_s=%.3f;ref_t=%.3f;lat=%.9f;lon=%.9f;sun_az=%.6f;sun_el=%.6f",
						date.Year,date.Month,date.Day,local_s,t,lat,lon,az,el)
				end
			else say(log.INFO, "weather: sun reference unavailable; solar model off") end
		end
		if net and type(net.dostring_in) == "function" then
			local result = net.dostring_in("mission", FOG_QUERY)
			local thick, vis
			if type(result) == "string" then thick, vis = result:match("^([%d%.%-]+),([%d%.%-]+)$") end
			thick, vis = tonumber(thick), tonumber(vis)
			if thick and vis and thick >= 0 and vis >= 0 then WX.fog_top, WX.fog_vis = thick, vis
			elseif not WX.fog_note then WX.fog_note = true say(log.INFO, "weather: live fog unavailable; mission-start fog retained") end
		end
		local text = WX.static..string.format(";fog_vis=%.0f;fog_top=%.0f",WX.fog_vis,WX.fog_top)
		if text ~= WX.last then
			local ok = lk.weather(text)
			if ok then WX.last = text end
			say(log.INFO, "weather: "..text..(ok and " (handed to the DLL)" or " (not taken by this DLL)"))
			if not ok then WX.failed = true end
		end
	end

	if HM and get_self and get_cam and send then
		local t_log, sent, was_ours, failed = -1e9, 0, false, false
		local function axis(v) return {v.x, v.y, v.z} end
		local function now() return DCS and DCS.getModelTime and DCS.getModelTime() or 0 end





		local HT = {HITCH_MS = 40, PERIOD = 60, last = nil, last_mt = nil, step_ms = 0, msl_ms = 0, t_sum = -1,
			frames = 0, hitches = 0, worst = 0, step_sum = 0, step_worst = 0, msl_worst = 0, lines = 0}
		function HT.wall()
			if DCS and DCS.getRealTime then
				local ok, w = pcall(DCS.getRealTime)
				if ok and type(w) == "number" then return w end
			end
			return os.clock()
		end
		function HT.frame(w, mt)
			local gap = HT.last and (w - HT.last) * 1000
			local moved = HT.last_mt and mt > HT.last_mt
			if gap and moved and gap < 5000 then
				HT.frames = HT.frames + 1
				HT.worst = math.max(HT.worst, gap)
				if gap > HT.HITCH_MS then
					HT.hitches = HT.hitches + 1
					if HT.lines < 200 then
						HT.lines = HT.lines + 1
						say(log.INFO, string.format("hitch: %.0f ms frame at model t %.2f; this hook's step before it %.2f ms "
							.."(missile export %.2f ms)", gap, mt, HT.step_ms, HT.msl_ms))
					end
				end
			end
			HT.last, HT.last_mt = w, mt
			if HT.t_sum < 0 then HT.t_sum = w end
			if w - HT.t_sum >= HT.PERIOD and HT.frames > 0 then
				say(log.INFO, string.format("frames %d in %.0f s: %d over %d ms, worst %.0f ms; this hook %.3f ms mean, "
					.."worst %.2f ms (missile export worst %.2f ms)", HT.frames, w - HT.t_sum, HT.hitches, HT.HITCH_MS,
					HT.worst, HT.step_sum / HT.frames, HT.step_worst, HT.msl_worst))
				HT.t_sum, HT.frames, HT.hitches, HT.worst, HT.step_sum, HT.step_worst, HT.msl_worst = w, 0, 0, 0, 0, 0, 0
			end
		end
		function HT.done(w0, ours)
			HT.step_ms = (HT.wall() - w0) * 1000
			if not ours then return end
			HT.step_sum = HT.step_sum + HT.step_ms
			HT.step_worst = math.max(HT.step_worst, HT.step_ms)
			HT.msl_worst = math.max(HT.msl_worst, HT.msl_ms)
		end

		local function step()
			local self = get_self()
			local ours = self ~= nil and TYPES[self.Name] == true
			if ours ~= was_ours then
				say(log.INFO, ours and ("in "..tostring(self.Name)..": sending head angles via "..how) or "not in an F15EX: idle")
				was_ours = ours
			end
			if not ours then return end
			local cam = get_cam()
			if not (cam and cam.x and cam.y and cam.z) then return end
			local f, r, u = HM.body_axes(self.Heading, self.Pitch, self.Bank)
			local az, el, roll = HM.head_angles(axis(cam.x), axis(cam.y), axis(cam.z), f, r, u)
			if not az then return end



			local j = (sent % 2 == 0) and JIG or -JIG
			local t = now()
			local coal = tonumber(self.CoalitionID)
			send(az / HM.SCALE.az + j, el / HM.SCALE.el + j, roll / HM.SCALE.roll + j,
				(t % TIME_WRAP) / (TIME_WRAP / 2) - 1, coal and coal + j)
			sent = sent + 1
			if not MSL.failed then
				local m0 = HT.wall()
				local ok, err = pcall(missiles, self, t)
				HT.msl_ms = (HT.wall() - m0) * 1000
				if not ok then
					MSL.failed = true
					say(log.ERROR, "missile export stopped: "..tostring(err))
				end
			end
			if not UN.failed then
				local ok, err = pcall(units_write, t)
				if not ok then UN.failed = true say(log.ERROR, "units: "..tostring(err)) end
			end
            if not RF.failed then
                local ok,err=pcall(rf_send,t)
                if not ok then RF.failed=true say(log.ERROR,'weapon RF: '..tostring(err)) end
            end
			if not WX.failed then
				local ok, err = pcall(weather_send)
				if not ok then WX.failed = true say(log.ERROR, "weather: "..tostring(err)) end
			end
			if not BE.failed then
				local ok, err = pcall(bulls, self, t)
				if not ok then
					BE.failed = true
					say(log.ERROR, "bullseye stopped: "..tostring(err))
				end
			end
			if t - t_log >= LOG_PERIOD then
				t_log = t
				say(log.INFO, string.format("sent %d | head az %.1f el %.1f roll %.1f | jet hdg %.1f pitch %.1f bank %.1f | coalition %s",
					sent, math.deg(az), math.deg(el), math.deg(roll), math.deg(self.Heading), math.deg(self.Pitch),
					math.deg(self.Bank), tostring(self.CoalitionID)))
			end
		end

		local cb = {}
		function cb.onSimulationStart()
			was_ours, failed, t_log = false, false, -1e9
			MSL.t, MSL.slots, MSL.by_id, MSL.seen, MSL.logged, MSL.failed, MSL.diag_t = -1e9, {}, {}, {}, false, false, -1e9
			BE.t, BE.by_coal, BE.failed = -1e9, nil, false
			UN.done, UN.failed = false, false
			RF.t,RF.failed=-1e9,false
			WX.done, WX.failed, WX.t, WX.last, WX.static, WX.fog_note = false, false, -1e9, nil, nil, false
			lk_tried = LK ~= nil
			HT.last, HT.last_mt, HT.t_sum, HT.frames, HT.hitches, HT.worst, HT.lines = nil, nil, -1, 0, 0, 0, 0
			HT.step_sum, HT.step_worst, HT.msl_worst = 0, 0, 0
		end
		function cb.onSimulationFrame()
			if failed then return end
			local w0 = HT.wall()
			if was_ours then HT.frame(w0, now()) else HT.last = nil end
			HT.msl_ms = 0
			local ok, err = pcall(step)
			HT.done(w0, was_ours)
			if not ok then
				failed = true
				say(log.ERROR, "stopped: "..tostring(err))
			end
		end
		DCS.setUserCallbacks(cb)
		say(log.INFO, "loaded (hook); sends via "..how)
	else
		say(log.ERROR, string.format("not started: hmd_math %s, Export.LoGetSelfData %s, Export.LoGetCameraPosition %s, sender %s",
			tostring(HM ~= nil), tostring(get_self ~= nil), tostring(get_cam ~= nil), tostring(how)))
	end
end
