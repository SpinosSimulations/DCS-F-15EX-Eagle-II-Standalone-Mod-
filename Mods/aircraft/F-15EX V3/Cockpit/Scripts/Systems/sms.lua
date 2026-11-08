













local SMS = {}

SMS.MAX_STATIONS = 16
SMS.FAMILIES = {"GUN", "SRM", "MRM", "LRM"}
SMS.MISSILES = {"SRM", "MRM", "LRM"}
SMS.IS_MISSILE = {SRM = true, MRM = true, LRM = true}
SMS.RADAR = {MRM = true, LRM = true}


SMS.SELECTABLE = {"SRM", "MRM", "LRM"}
SMS.IS_STORE = {SRM = true, MRM = true, LRM = true}
SMS.EXTRA = {}
function SMS.add_family(name, classify)
	if SMS.IS_STORE[name] then return end
	SMS.SELECTABLE[#SMS.SELECTABLE + 1] = name
	SMS.IS_STORE[name] = true
	SMS.EXTRA[#SMS.EXTRA + 1] = classify
end




function SMS.use_layout(rows, order)
	SMS.ORDER, SMS.SIDE, SMS.ARM, SMS.TIER = {}, {}, {}, {}
	for i, r in ipairs(rows) do SMS.SIDE[i], SMS.ARM[i], SMS.TIER[i] = r.side, r.arm, r.tier end
	for k, p in ipairs(order) do SMS.ORDER[k] = p end
	SMS.NPYLONS = #rows
end








SMS.BY_CLSID = {
	{"AIM-174", "LRM", "174B"},
	{"C8E06185-7CD6-4C90-959F-044679E90751", "LRM", "174B"},
	{"AIM-260", "MRM", "260A"}, {"AIM260", "MRM", "260A"},
	{"AIM-120D-3", "MRM", "120D-3"}, {"AIM-120D3", "MRM", "120D-3"}, {"AIM120D3", "MRM", "120D-3"},
	{"AIM-120D", "MRM", "120D"}, {"AIM120D", "MRM", "120D"},
	{"AIM-120C-8", "MRM", "120C-8"}, {"AIM-120C8", "MRM", "120C-8"}, {"AIM120C8", "MRM", "120C-8"},
	{"AIM-120C-7", "MRM", "120C-7"}, {"AIM-120C7", "MRM", "120C-7"}, {"AIM120C7", "MRM", "120C-7"},
	{"AIM-120C-5", "MRM", "120C-5"}, {"AIM-120C5", "MRM", "120C-5"}, {"AIM120C5", "MRM", "120C-5"},
	{"AIM-120C", "MRM", "120C"}, {"AIM120C", "MRM", "120C"},
	{"AIM-200", "MRM", "200A"}, {"AIM200", "MRM", "200A"},



	{"AIM-9X-ED", "SRM", "9X"},
	{"F15EX_AIM-9X_", "SRM", "9X2"}, {"F-15EX_AIM-9X_", "SRM", "9X2"}, {"AIM-9X2", "SRM", "9X2"}, {"AIM-9X-2", "SRM", "9X2"},
	{"AIM-9X", "SRM", "9X"}, {"AIM9X", "SRM", "9X"},
	{"PYTHON-5", "SRM", "P5"},


	{"APKWS", "SRM", "APK"},
	{"EXTTANK", "FUEL", "FUEL"},
	{"AAQ-14", "POD", "TGP"},
	{"LANTIRN", "POD", "NAV"}, {"AAQ_33", "POD", "TGP"}, {"AAQ-33", "POD", "TGP"}, {"LEGIONPOD", "POD", "IRST"},
	{"A111396E-D3E8-4B9C-8AC9-2432489304D5", "POD", "TGP"},
}

SMS.AA_MISSILE = 7
SMS.BY_WSTYPE = {[21] = {"MRM", "7M", "SARH"}, [22] = {"SRM", "9M", "IR"}, [24] = {"MRM", "120B", "ARH"},
	[106] = {"MRM", "120C-5", "ARH"}, [136] = {"SRM", "9X", "IR"}}


SMS.STOCK_SEEKER = {[1] = {"SRM", "R550", "IR"}, [2] = {"SRM", "MICAIR", "IR"}, [3] = {"MRM", "MICARF", "ARH"},
	[4] = {"MRM", "530D", "SARH"}, [5] = {"MRM", "R-98", "SARH"}, [6] = {"MRM", "R-4R", "SARH"},
	[7] = {"MRM", "R-40R", "SARH"}, [9] = {"MRM", "R-24R", "SARH"}, [10] = {"SRM", "R-60", "IR"},
	[11] = {"MRM", "R-33", "SARH"}, [12] = {"MRM", "R-27AE", "ARH"}, [13] = {"MRM", "R-27R", "SARH"},
	[14] = {"MRM", "R-27ER", "SARH"}, [15] = {"SRM", "R-27T", "IR"}, [16] = {"SRM", "R-27ET", "IR"},
	[17] = {"MRM", "R-27EM", "SARH"}, [18] = {"SRM", "R-73", "IR"}, [19] = {"MRM", "R-77", "ARH"},
	[20] = {"MRM", "R-37", "ARH"}, [23] = {"MRM", "AIM54", "ARH"}, [26] = {"SRM", "R-24T", "IR"}, [27] = {"SRM", "R-40T", "IR"},
	[135] = {"SRM", "9P", "IR"}}
SMS.MISSILE = {4, 4}

SMS.BY_HEAD = {[1] = {"SRM", "IR"}, [2] = {"MRM", "ARH"}, [6] = {"MRM", "SARH"}}




function SMS.short_code(name, family)
	local s = string.upper(tostring(name or ""))
	s = string.gsub(s, "_", "-")
	s = string.gsub(s, "^AIM%-", "")
	local t1, rest = string.match(s, "^([%w%-%.]+)%s*(.*)$")
	if not t1 then return "AAM" end
	local t2 = string.match(rest, "^([%w%-%.]+)")
	if #t1 <= 2 and t2 then t1 = t1..t2 end
	local c = string.sub(t1, 1, 6)
	if tonumber(c) then c = string.sub(string.sub(family or "M", 1, 1)..c, 1, 6) end
	return c
end
SMS.FUEL_TANK = 43





SMS.describe = nil
function SMS.classify(clsid, w)
	clsid = tostring(clsid or "")
	if clsid == "" or clsid == "<CLEAN>" then return nil end
	local up = clsid:upper()
	for _, f in ipairs(SMS.EXTRA) do
		local fam, code, info = f(up, w or {})
		if fam then return fam, code, info or {} end
	end
	if not up:find("F15EX_ANY_", 1, true) then
		for _, e in ipairs(SMS.BY_CLSID) do
			if up:find(e[1], 1, true) then return e[2], e[3], {} end
		end
	end
	w = w or {}
	if w.level3 == SMS.AA_MISSILE and SMS.BY_WSTYPE[w.level4] then
		local e = SMS.BY_WSTYPE[w.level4]
		return e[1], e[2], {seeker = e[3]}
	end
	if w.level1 == SMS.MISSILE[1] and w.level2 == SMS.MISSILE[2] and SMS.describe then
		local ok, d = pcall(SMS.describe, clsid, w)
		local h = ok and type(d) == "table" and SMS.BY_HEAD[d.head]
		if h then return h[1], SMS.short_code(d.short or d.name, h[1]), {seeker = h[2], kg = d.kg} end
	end
	if w.level1 == SMS.MISSILE[1] and w.level2 == SMS.MISSILE[2] and w.level3 == SMS.AA_MISSILE then
		local s = SMS.STOCK_SEEKER[w.level4]
		if s then return s[1], s[2], {seeker = s[3]} end
		return "MRM", "AAM", {}
	end
	if w.level3 == SMS.FUEL_TANK then return "FUEL", "FUEL" end
	if w.level1 == 4 and (w.level2 == 4 or w.level2 == 5 or w.level2 == 7) then return "AG", "A/G" end
	return "UNK", "UNK"
end



function SMS.scan(get_info)
	local list = {}
	for i = 0, SMS.MAX_STATIONS - 1 do
		local s = get_info(i)
		if s then
			local fam, code, info = SMS.classify(s.CLSID, s.weapon)
			if fam then
				local w = type(s.weapon) == "table" and s.weapon or {}
				list[#list + 1] = {station = i, pylon = i + 1, side = SMS.SIDE[i + 1] or "C", clsid = tostring(s.CLSID),
					count = tonumber(s.count) or 0, family = fam, code = code, seeker = info and info.seeker,
					kg = info and info.kg, info = info, wst = w.level1 and string.format("%s,%s,%s,%s", tostring(w.level1),
					tostring(w.level2), tostring(w.level3), tostring(w.level4)) or nil}
			end
		end
	end
	return list
end



function SMS.nav_pod(list)
	for _, e in ipairs(list) do
		if string.find(string.upper(e.clsid or ""), "AAQ-13", 1, true) then return true end
	end
	return false
end


function SMS.totals(list)
	local t = {}
	for _, e in ipairs(list) do t[e.family] = (t[e.family] or 0) + e.count end
	return t
end

local function by_pylon(list, pylon)
	for _, e in ipairs(list) do if e.pylon == pylon then return e end end
	return nil
end




SMS.ROUND_KG = {["9X"] = 85, ["9X2"] = 85, ["9M"] = 86, ["7M"] = 231, ["174B"] = 860, P5 = 105, APK = 15}
SMS.ROUND_KG_DEFAULT = 160

local function round_kg(e)
	return SMS.ROUND_KG[e.code] or (type(e.kg) == "number" and e.kg > 0 and e.kg) or SMS.ROUND_KG_DEFAULT
end


function SMS.moment(list)
	local m = 0
	for _, e in ipairs(list) do
		if SMS.IS_STORE[e.family] and e.count > 0 then
			m = m + e.count * round_kg(e) * (SMS.ARM[e.pylon] or 0)
		end
	end
	return m
end










function SMS.next_station(list, family, after_pylon, code)
	local m0 = SMS.moment(list)
	local best, best_t, best_m = nil, nil, nil
	for _, p in ipairs(SMS.ORDER) do
		local e = by_pylon(list, p)
		if e and e.family == family and e.count > 0 and (not code or e.code == code) then
			local t = SMS.TIER[p] or 3
			local m = math.abs(m0 - round_kg(e) * (SMS.ARM[p] or 0))
			if not best or t < best_t or (t == best_t and m < best_m - 1e-6) then best, best_t, best_m = e, t, m end
		end
	end
	return best
end



function SMS.types(list, family)
	local t, seen = {}, {}
	for _, p in ipairs(SMS.ORDER) do
		local e = by_pylon(list, p)
		if e and e.family == family and e.count > 0 and not seen[e.code] then
			seen[e.code] = true
			t[#t + 1] = e.code
		end
	end
	return t
end


function SMS.next_type(state, list, family, wrap)
	local t = SMS.types(list, family)
	for k, c in ipairs(t) do
		if c == state.code[family] then return t[k + 1] or (wrap and t[1] ~= c and t[1]) or nil end
	end
	return nil
end


function SMS.select_type(state, list, family, code)
	local e = SMS.next_station(list, family, nil, code)
	state.code[family] = e and code or nil
	state.station[family] = e and e.pylon or nil
end



SMS.CYCLE = {GUN = "SRM", SRM = "MRM", MRM = "LRM", LRM = "GUN"}
function SMS.cycle(state, list)
	local f = state.family
	local nt = f ~= "GUN" and SMS.next_type(state, list, f)
	if nt then SMS.select_type(state, list, f, nt) return end
	f = SMS.CYCLE[f]
	if f == "LRM" and not SMS.types(list, "LRM")[1] then f = SMS.CYCLE[f] end
	state.family = f
	local t = f ~= "GUN" and SMS.types(list, f)
	if t and t[1] then SMS.select_type(state, list, f, t[1]) end
end



function SMS.press(state, list, family)
	if family == "MRM" and (state.family == "MRM" or state.family == "LRM") then
		local mrm, lrm = SMS.types(list, "MRM"), SMS.types(list, "LRM")
		local f = state.family
		local nt = SMS.next_type(state, list, f)
		if not nt then

			local other = f == "MRM" and lrm or mrm
			if other[1] then f, nt = f == "MRM" and "LRM" or "MRM", other[1]
			else nt = (f == "MRM" and mrm or lrm)[1] end
		end
		if nt then SMS.select_type(state, list, f, nt) end
		state.family = f
		return
	end
	if state.family == family and family ~= "GUN" then
		local nt = SMS.next_type(state, list, family, true)
		if nt then SMS.select_type(state, list, family, nt) end
	end
	state.family = family
end




SMS.GUN_ROUNDS = 500
SMS.GUN_RATE = 100




function SMS.new_state()
	return {family = "MRM", armed = false, station = {}, code = {}, gun = {rounds = SMS.GUN_ROUNDS, firing = false}}
end


function SMS.gun_rounds(state)
	return math.ceil(state.gun.rounds - 1e-9)
end


function SMS.gun_tick(state, dt)
	local g = state.gun
	if not g.firing then return false end
	g.rounds = math.max(0, g.rounds - SMS.GUN_RATE * dt)
	return g.rounds <= 0
end



function SMS.refresh(state, list)
	for _, f in ipairs(SMS.SELECTABLE) do
		local p, c = state.station[f], state.code[f]
		local e = p and by_pylon(list, p)
		if not (e and e.family == f and e.count > 0 and e.code == c) then

			local nx = c and SMS.next_station(list, f, p, c)
			if not nx then
				local first = SMS.types(list, f)[1]
				nx = first and SMS.next_station(list, f, p, first)
			end
			state.station[f] = nx and nx.pylon or nil
			state.code[f] = nx and nx.code or nil
		end
	end
end




function SMS.step(state, list, family, from)
	if from and state.station[family] ~= from then
		SMS.refresh(state, list)
		return
	end
	local nx = SMS.next_station(list, family, state.station[family], state.code[family])
	if nx then state.station[family] = nx.pylon else SMS.refresh(state, list) end
end



function SMS.status(state, e)
	if e.count <= 0 or not SMS.IS_STORE[e.family] then return "" end
	if e.family ~= state.family or e.code ~= state.code[e.family] then return e.family end
	if state.armed and state.station[e.family] == e.pylon then return "RDY" end
	return "STBY"
end


function SMS.count(list, family, code)
	local n = 0
	for _, e in ipairs(list) do if e.family == family and e.code == code then n = n + e.count end end
	return n
end



function SMS.selected_text(state, list)
	if state.family == "GUN" then
		local n = SMS.gun_rounds(state)
		return n > 0 and string.format("GUN %d", n) or "GUN ---"
	end
	local p = state.station[state.family]
	local e = p and by_pylon(list, p)
	if not e then return state.family.." ---" end
	return string.format("%s %s %d", state.family, e.code, SMS.count(list, state.family, e.code))
end


function SMS.mirror(pylon)
	local a = SMS.ARM and SMS.ARM[pylon]
	if not a or math.abs(a) < 1e-6 then return nil end
	local best, d = nil, nil
	for p, b in pairs(SMS.ARM) do
		if p ~= pylon and b * a < 0 then
			local e = math.abs(b + a) + math.abs((SMS.TIER[p] or 0) - (SMS.TIER[pylon] or 0)) * 100
			if not d or e < d then best, d = p, e end
		end
	end
	return best
end

SMS.by_pylon = by_pylon
return SMS
