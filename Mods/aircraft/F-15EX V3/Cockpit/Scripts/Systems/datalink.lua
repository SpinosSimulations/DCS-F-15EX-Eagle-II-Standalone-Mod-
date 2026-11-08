










local M = {MAX = 32, FIRST = 101, HOSTILE = 1, FRIEND = 2, UNKNOWN = 3,
	SRC = {[1] = "AWACS", [2] = "GND", [3] = "FTR", [4] = "PPLI"},
	FIELDS = {"NUM", "RANGE", "BRG", "ELEV", "CLOSURE", "COAL", "SRC", "AGE", "HDG", "GS"},
	list = {}}

local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end

local function str(h) local v = h:get() return type(v) == "string" and v ~= "0" and v or "" end





M.GEO_PTS = {{100000, 50000}, {-150000, 200000}, {250000, -100000}}

local function geo_log(s)
	if log and log.info then tostring("F15EX DL "..s) end
end

local function geo_write()
	M.geo_done = true
	if type(lo_to_geo_coords) ~= "function" then geo_log("map grid: no lo_to_geo_coords here") return end
	local ll = {}
	for i, p in ipairs(M.GEO_PTS) do
		local ok, a, b = pcall(lo_to_geo_coords, p[1], p[2])
		if ok and type(a) == "table" then a, b = a.lat or a.latitude or a[1], a.lon or a.longitude or a[2] end
		if not ok or type(a) ~= "number" or type(b) ~= "number" then
			geo_log("map grid: lo_to_geo_coords failed ("..tostring(a)..")")
			return
		end
		ll[i] = {a, b}
	end
	for i, v in ipairs(ll) do
		M.geo[i].lat:set(v[1])
		M.geo[i].lon:set(v[2])
	end
	M.geo_ok:set(1)
	geo_log(string.format("map grid: point 1 at %.6f %.6f", ll[1][1], ll[1][2]))
end

function M.init()
	M.geo_ok = get_param_handle("DL_GEO_OK")
	M.geo_ok:set(0)
	M.geo = {}
	for i = 1, #M.GEO_PTS do
		M.geo[i] = {lat = get_param_handle(string.format("DL_GEO_%d_LAT", i)), lon = get_param_handle(string.format("DL_GEO_%d_LON", i))}
	end
	M.count = get_param_handle("DL_COUNT")
	M.donors = get_param_handle("DL_DONORS")
	M.own_coal = get_param_handle("DL_OWN_COAL")
	M.handoff_p = get_param_handle("RDR_DT_HANDOFF")
	M.slots = {}
	for i = 1, M.MAX do
		M.slots[i] = {}
		for _, f in ipairs(M.FIELDS) do M.slots[i][f] = get_param_handle(string.format("DL_%02d_%s", i, f)) end
		M.slots[i].NAME = get_param_handle(string.format("DL_%02d_NAME", i))
	end
	return M
end

function M.ident(coal, own)
	if not own or coal == 0 then return M.UNKNOWN end
	return coal == own and M.FRIEND or M.HOSTILE
end






function M.poll(own, send)
	if send then
		M.own_coal:set(own or 0)
		if not M.geo_done then geo_write() end
	end
	M.list = {}
	local n = math.min(math.floor(num(M.count) + 0.5), M.MAX)
	for i = 1, n do
		local s = M.slots[i]
		local number = math.floor(num(s.NUM) + 0.5)
		if number >= M.FIRST then
			local coal = math.floor(num(s.COAL) + 0.5)
			local id = M.ident(coal, own)
			M.list[#M.list + 1] = {number = number, range = num(s.RANGE), brg = num(s.BRG), elev = num(s.ELEV),
				closure = num(s.CLOSURE), coal = coal, dl = math.floor(num(s.SRC) + 0.5), age = num(s.AGE),
				hdg = num(s.HDG), gs = num(s.GS), id = id, iff = id == M.FRIEND and 1 or id == M.HOSTILE and 2 or 0,
				coast = false, asked = false, type = "", lock = false, stt = false, name = str(s.NAME)}
		end
	end
	return M.list
end


function M.own()
	local c = math.floor(num(M.own_coal) + 0.5)
	return c > 0 and c or nil
end

function M.get(number)
	for _, t in ipairs(M.list) do if t.number == number then return t end end
	return nil
end

function M.is_dl(number) return number >= M.FIRST end


function M.handoff() return math.floor(num(M.handoff_p) + 0.5) end



function M.label(t)
	if t.id == M.FRIEND and t.name and t.name ~= "" then return t.name end
	return M.SRC[t.dl] or "DL"
end

return M
