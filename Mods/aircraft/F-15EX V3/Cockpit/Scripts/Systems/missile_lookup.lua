






local L = {}
local D = dofile(LockOn_Options.script_path.."Systems/missile_data.lua")
L.data = D


local function clsids(clsid)
	local out = {clsid}
	local src = string.match(clsid, "^{F15EX_ANY_(.+)_[^_]+}$")
	if src then out[2], out[3] = "{"..src.."}", src end
	return out
end


local function ws_key(ws)
	if type(ws) == "string" then return ws end
	if type(ws) ~= "table" then return nil end
	if ws.level1 then ws = {ws.level1, ws.level2, ws.level3, ws.level4} end
	for i = 1, 4 do if type(ws[i]) ~= "number" then return nil end end
	return ws[1]..","..ws[2]..","..ws[3]..","..ws[4]
end


function L.find(clsid, ws)
	for _, c in ipairs(clsids(clsid)) do
		local hit = D.clsid[c]
		if hit then return D.w[hit[1]], hit[2] end
	end
	local k = ws_key(ws)
	local i = k and D.ws[k]
	if i then return D.w[i], "wsType "..k end
	return nil, "CLSID not in the missile data (tools/gen_missile_data.py)"
end


local lookups = {}
function L.lookup(clsid, ws)
	if type(clsid) ~= "string" or clsid == "" then return nil, "no CLSID" end
	local key = clsid.."|"..tostring(ws_key(ws) or "")
	local c = lookups[key]
	if c then return c.e, c.why end
	local w, how = L.find(clsid, ws)
	local e, why
	if not w then why = how
	elseif not w.dlz then why = w.name.." has no DLZ block in its ModelData"
	else
		e = {name = w.name, display = w.display, dlz = w.dlz, md = w.md, d_min = w.d_min, file = w.file, how = how}
		why = "ModelData"
	end
	lookups[key] = {e = e, why = why}
	return e, why
end


function L.describe(clsid, ws)
	local w, how = L.find(type(clsid) == "string" and clsid or "", ws)
	if not w then return nil, how end
	return {name = w.name, short = w.short, head = w.head, kg = w.kg, range = w.range, file = w.file, how = how}, how
end


function L.active_dist(clsid)
	if type(clsid) ~= "string" or clsid == "" then return nil end
	local w = L.find(clsid)
	return w and w.act or nil
end

return L
