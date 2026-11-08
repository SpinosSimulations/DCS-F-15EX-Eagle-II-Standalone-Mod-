












local M = {ROWS = 10, SYNC_S = 30, NPG = {[1] = "SURV", [2] = "SURV", [3] = "F2F", [4] = "PPLI"},
	ID = {[1] = "HOS", [2] = "FRD", [3] = "UNK"}, last_t = nil}
local M_PER_NM = 1852

function M.init(param)
	M.p = {}
	for _, n in ipairs({"TERM", "NET", "N_PPLI", "N_SURV", "N_F2F", "N_FRD", "N_HOS", "N_UNK", "ROWS", "TOTAL"}) do
		M.p[n] = param("L16_"..n)
	end
	M.filt, M.src = param("L16_FILT"), param("L16_SRC")
	M.row = {}
	for k = 1, M.ROWS do M.row[k] = param(string.format("L16_ROW_%02d", k)) end
	return M
end

local function n_of(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end


function M.pass(t, filt, src)
	if filt == 2 and t.id ~= 2 then return false end
	if filt == 3 and t.id ~= 1 then return false end
	if filt == 4 and t.id ~= 3 then return false end
	if src >= 2 and M.NPG[t.dl] ~= ({"", "PPLI", "SURV", "F2F"})[src] then return false end
	return true
end


function M.row_text(t, label, kft)
	local b = math.floor(math.deg(t.brg) + 0.5)
	return string.format("%3d %s %-6s %s%03d %5.1f %3dK %2dS", t.number, M.ID[t.id] or "UNK", label:sub(1, 6),
		b < 0 and "L" or "R", math.abs(b), t.range / M_PER_NM, kft, math.min(99, math.floor(t.age + 0.5)))
end



function M.update(list, link, own, now, label, kft)
	local p = M.p
	p.TERM:set(link and 1 or 0)
	if #list > 0 then M.last_t = now end
	p.NET:set(not link and 0 or not own and 1 or (M.last_t and now - M.last_t <= M.SYNC_S) and 3 or 2)
	local c = {PPLI = 0, SURV = 0, F2F = 0, [1] = 0, [2] = 0, [3] = 0}
	for _, t in ipairs(list) do
		local g = M.NPG[t.dl]
		if g then c[g] = c[g] + 1 end
		c[t.id] = (c[t.id] or 0) + 1
	end
	p.N_PPLI:set(c.PPLI) p.N_SURV:set(c.SURV) p.N_F2F:set(c.F2F)
	p.N_HOS:set(c[1]) p.N_FRD:set(c[2]) p.N_UNK:set(c[3])
	p.TOTAL:set(#list)
	local filt, src = math.floor(n_of(M.filt) + 0.5), math.floor(n_of(M.src) + 0.5)
	local shown = {}
	for _, t in ipairs(list) do if M.pass(t, filt, src) then shown[#shown + 1] = t end end
	table.sort(shown, function(a, b) return a.range < b.range end)
	for k = 1, M.ROWS do
		local t = shown[k]
		M.row[k]:set(t and M.row_text(t, label(t), kft(t)) or " ")
	end
	p.ROWS:set(math.min(#shown, M.ROWS))
end

return M
