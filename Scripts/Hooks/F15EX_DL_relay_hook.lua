











do
	local TYPES = {F15EX = true, F15EX_CFT = true, F15IA = true}
	local MOD_NAMES = {"F-15EX V3 log", "F-15EX V3 no log", "F-15EX V3"}
	local PREFIX = "F-15EX DL relay: "
	local REFRESH = 5.0

	local function say(level, s)
		if log and log.write then tostring("F15EX_RELAY", level, s) end
	end

	local L = lfs
	if not (L and L.writedir) then
		local ok, m = pcall(require, "lfs")
		L = ok and m or nil
	end
	if not (L and L.writedir and DCS and DCS.setUserCallbacks and net) then
		say(log.ERROR, "not started: lfs / DCS / net missing")
		return
	end

	local LK, lk_tried
	local function link()
		if lk_tried then return LK end
		lk_tried = true
		local m = package.loaded.F15EX_FM
		if type(m) == "table" then LK = m return LK end
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
		if not bin then say(log.ERROR, "relay off: no Mods\\aircraft\\F-15EX*\\bin\\F15EX_FM.dll") return nil end
		local cpath = package.cpath
		package.cpath = bin.."?.dll;"..cpath
		local ok, r = pcall(require, "F15EX_FM")
		package.cpath = cpath
		if ok and type(r) == "table" then
			LK = r
			say(log.INFO, "the DLL's module from "..bin)
		else
			say(log.ERROR, "relay off: the DLL's module not loaded from "..bin..": "..tostring(r))
		end
		return LK
	end
	local function clock()
		if DCS.getRealTime then
			local ok, t = pcall(DCS.getRealTime)
			if ok and type(t) == "number" then return t end
		end
		return os.clock()
	end
	local function server_id() return net.get_server_id and net.get_server_id() or 1 end
	local function is_server()
		return DCS.isServer and DCS.isServer() and DCS.isMultiplayer and DCS.isMultiplayer()
	end

	math.randomseed(os.time() + math.floor((os.clock() * 1000003) % 1000003))
	local function token()
		local t = {}
		for i = 1, 24 do t[i] = string.format("%x", math.random(0, 15)) end
		return table.concat(t)
	end


	local function slot_type(id)
		local slot = net.get_player_info(id, "slot")
		local unit = slot and tostring(slot):match("^(%d+)")
		if not unit then return nil end
		if DCS.getUnitType then
			local ok, t = pcall(DCS.getUnitType, unit)
			if ok and type(t) == "string" and t ~= "" then return t end
		end
		if DCS.getUnitProperty and DCS.UNIT_TYPE then
			local ok, t = pcall(DCS.getUnitProperty, unit, DCS.UNIT_TYPE)
			if ok and type(t) == "string" and t ~= "" then return t end
		end
		return nil
	end

	local S = {tokens = {}, told = {}, t = -1e9, on = false, listen = nil}
	local C = {join = nil, t = -1e9}

	local function server_refresh()
		local lk = link()
		if not lk then return end
		local lines, ex = {}, {}
		for _, id in ipairs(net.get_player_list() or {}) do
			if id ~= server_id() then
				local side = tonumber(net.get_player_info(id, "side")) or 0
				local t = slot_type(id)
				local is_ex = t and TYPES[t] and 1 or 0
				S.tokens[id] = S.tokens[id] or token()
				lines[#lines + 1] = string.format("%d\t%d\t%d\t%s", id, side, is_ex, S.tokens[id])
				if is_ex == 1 then ex[#ex + 1] = {id = id, t = t, side = side} end
			end
		end

		local listen = lk.players(table.concat(lines, "\n").."\n")
		local addr, port
		if listen then addr, port = listen:match("^([^\t\r\n]+)\t(%d+)") end
		if not addr then return end
		if addr ~= S.listen then
			S.listen = addr
			say(log.INFO, "the DLL listens on "..addr..":"..port)
		end
		for _, p in ipairs(ex) do
			local key = addr..":"..port.."|"..tostring(net.get_player_info(p.id, "slot"))
			if S.told[p.id] ~= key then
				net.send_chat_to(PREFIX..addr..":"..port.." "..S.tokens[p.id], p.id)
				S.told[p.id] = key
				say(log.INFO, string.format("told player %d (%s, side %d) where the relay is", p.id, p.t, p.side))
			end
		end
	end

	local function client_refresh()
		local lk = link()
		if C.join and lk then lk.join(C.join) end
	end

	local function stop()
		if LK then LK.stop() end
		S.tokens, S.told, S.t, S.on, S.listen = {}, {}, -1e9, false, nil
		C.join, C.t = nil, -1e9
	end

	local cb = {}
	function cb.onSimulationStart()
		stop()
		lk_tried = LK ~= nil
		S.on = is_server() and true or false
		if S.on then say(log.INFO, "server: relay players file on") end
	end
	function cb.onSimulationStop() stop() end
	function cb.onPlayerConnect() S.t = -1e9 end
	function cb.onPlayerChangeSlot() S.t = -1e9 end
	function cb.onPlayerDisconnect(id)
		S.tokens[id], S.told[id] = nil, nil
		S.t = -1e9
	end
	function cb.onChatMessage(message, from)
		if S.on or from ~= server_id() or type(message) ~= "string" then return end
		local host, port, tok = message:match("^"..PREFIX:gsub("%-", "%%-").."(%S+):(%d+) (%x+)$")
		if not host then return end
		C.join = host.."\t"..port.."\t"..tok.."\n"
		C.t = -1e9
		say(log.INFO, "client: the server's relay is at "..host..":"..port)
	end
	function cb.onSimulationFrame()
		local now = clock()
		if S.on then
			if now - S.t >= REFRESH then
				S.t = now
				local ok, err = pcall(server_refresh)
				if not ok then say(log.ERROR, "server: "..tostring(err)) end
			end
		elseif C.join and now - C.t >= REFRESH then
			C.t = now
			local ok, err = pcall(client_refresh)
			if not ok then say(log.ERROR, "client: "..tostring(err)) end
		end
	end
	DCS.setUserCallbacks(cb)
	say(log.INFO, "loaded")
end
