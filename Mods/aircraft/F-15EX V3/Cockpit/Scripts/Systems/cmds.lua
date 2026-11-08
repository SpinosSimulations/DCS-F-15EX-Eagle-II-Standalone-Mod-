
















local M = {}

M.MODES = {"OFF", "STBY", "MAN", "SEMI", "AUTO"}
M.SELS = {"CHAFF", "BOTH", "FLARE"}
M.OFF, M.STBY, M.MAN, M.SEMI, M.AUTO = 1, 2, 3, 4, 5
M.CHAFF, M.BOTH, M.FLARE = 1, 2, 3




M.ORDER = {"MAN1", "MAN2", "AIR", "SAM"}
M.PROGRAMS = {


	MAN1 = {id = 1, chaff = 2, flare = 2, salvos = 2, salvo_int = 0.5, bursts = 2, burst_int = 2.0},


	AIR = {id = 2, chaff = 2, flare = 1, salvos = 3, salvo_int = 0.4, bursts = 1, burst_int = 1.0},

	SAM = {id = 3, chaff = 2, flare = 0, salvos = 4, salvo_int = 0.5, bursts = 1, burst_int = 1.0},

	MAN2 = {id = 4, chaff = 2, flare = 2, salvos = 2, salvo_int = 0.5, bursts = 2, burst_int = 2.0},
}
M.OPTIONS = {
	auto_repeat = 5.0,
	min_left = 20,
	auto_lock = 0,
}



M.FIELDS = {
	{key = "chaff", name = "CHAFF / SALVO", lo = 0, hi = 10, step = 1, round = 1},
	{key = "flare", name = "FLARE / SALVO", lo = 0, hi = 10, step = 1, round = 1},
	{key = "salvos", name = "SALVOS", lo = 1, hi = 20, step = 1, round = 1},
	{key = "salvo_int", name = "SALVO INT", lo = 0.1, hi = 5.0, step = 0.1, round = 0.1},
	{key = "bursts", name = "BURSTS", lo = 1, hi = 20, step = 1, round = 1},
	{key = "burst_int", name = "BURST INT", lo = 0.5, hi = 30, step = 0.5, round = 0.1},
	{key = "auto_repeat", name = "AUTO REPEAT", lo = 1, hi = 60, step = 1, round = 0.5, opt = true},
	{key = "min_left", name = "MIN LEVEL", lo = 0, hi = 120, step = 5, round = 1, opt = true},
	{key = "auto_lock", name = "AUTO ON LOCK", lo = 0, hi = 1, step = 1, round = 1, opt = true},
}
M.PROG_ROWS = 6

local function copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end

function M.new(mode)
	local st = {mode = mode or M.SEMI, sel = M.BOTH, run = nil, auto_next = -1, threat = nil,
		prog = {}, opt = copy(M.OPTIONS), ed = {prog = "MAN1", row = 1}}
	for name, p in pairs(M.PROGRAMS) do st.prog[name] = copy(p) end
	return st
end


function M.totals(p)
	local n = p.salvos * p.bursts
	return p.chaff * n, p.flare * n, (p.bursts - 1) * p.burst_int + (p.salvos - 1) * p.salvo_int
end




function M.threat(rwr)
	if (rwr.sig or 0) >= 2 then return rwr.air and "AIR" or "SAM" end
	if (rwr.alert or 0) > 0 then return "AIR" end
	return nil
end

local function launching(rwr) return (rwr.sig or 0) >= 3 or (rwr.alert or 0) > 0 end


local function start(st, now, name, filter, why)
	local p = st.prog[name]
	local items = {}
	for b = 0, p.bursts - 1 do
		for k = 1, p.salvos do
			local t = now + b * p.burst_int + (k - 1) * p.salvo_int
			if filter ~= M.FLARE and p.chaff > 0 then items[#items + 1] = {t = t, kind = "chaff", n = p.chaff} end
			if filter ~= M.CHAFF and p.flare > 0 then items[#items + 1] = {t = t, kind = "flare", n = p.flare} end
		end
	end

	for i = 2, #items do
		local it, j = items[i], i - 1
		while j >= 1 and items[j].t > it.t do items[j + 1] = items[j] j = j - 1 end
		items[j + 1] = it
	end
	st.run = {name = name, id = p.id, items = items, next = 1, why = why,
		t_end = #items > 0 and items[#items].t or now}
	return st.run
end



function M.key(st, now, k, rwr)
	if k == "mode" then
		st.mode = st.mode % #M.MODES + 1
		if st.mode < M.MAN then st.run = nil end
		st.auto_next = -1
		return "CMD "..M.MODES[st.mode]
	elseif k == "sel" then
		st.sel = st.sel % #M.SELS + 1
		return "CMD "..M.SELS[st.sel]
	elseif k == "man1" or k == "man2" then
		if st.mode < M.MAN then return "CMD "..M.MODES[st.mode] end
		local name = k == "man1" and "MAN1" or "MAN2"
		if k == "man2" and st.mode >= M.SEMI then name = M.threat(rwr or {}) or "MAN2" end
		local r = start(st, now, name, st.sel, k == "man1" and "MAN 1" or "MAN 2")
		return "CMD "..r.why.." "..r.name
	end
	return nil
end


function M.value(st, row)
	local f = M.FIELDS[row]
	if not f then return 0 end
	return f.opt and st.opt[f.key] or st.prog[st.ed.prog][f.key]
end

local function put(st, row, v)
	local f = M.FIELDS[row]
	v = math.floor(v / f.round + 0.5) * f.round
	v = math.max(f.lo, math.min(f.hi, v))
	if f.opt then st.opt[f.key] = v else st.prog[st.ed.prog][f.key] = v end
	return v
end




function M.edit(st, what, v)
	local ed = st.ed
	if what == "prog" then
		local name = M.ORDER[v]
		if not name then return nil end
		ed.prog = name
		return "CMD EDIT "..name
	elseif what == "row" then
		if not M.FIELDS[v] then return nil end
		ed.row = v
		return nil
	elseif what == "row_next" or what == "row_prev" then
		ed.row = (ed.row - 1 + (what == "row_next" and 1 or -1)) % #M.FIELDS + 1
		return nil
	elseif what == "inc" or what == "dec" or what == "set" then
		local f = M.FIELDS[ed.row]
		local old = M.value(st, ed.row)
		local new
		if what == "set" then new = v
		elseif f.key == "auto_lock" then new = 1 - old
		else new = old + (what == "inc" and f.step or -f.step) end
		new = put(st, ed.row, new)
		if math.abs(new - old) < 1e-9 then return nil end
		return string.format("CMD %s %s %g", f.opt and "OPT" or ed.prog, f.key, new)
	elseif what == "default" then
		st.prog[ed.prog] = copy(M.PROGRAMS[ed.prog])
		return "CMD "..ed.prog.." default"
	end
	return nil
end



function M.tick(st, now, rwr, counts)
	local msg
	local th = st.mode >= M.SEMI and M.threat(rwr) or nil
	local have = function(kind) return (counts[kind] or -1) ~= 0 end

	st.ready = nil
	if th then
		local p = st.prog[th]
		if (p.chaff > 0 and have("chaff")) or (p.flare > 0 and have("flare")) then st.ready = th end
	end
	local c, f = counts.chaff or -1, counts.flare or -1
	st.min = (c > 0 and c <= st.opt.min_left) or (f > 0 and f <= st.opt.min_left)
	local trigger = launching(rwr) or (st.opt.auto_lock > 0.5 and (rwr.sig or 0) >= 2)
	if st.mode == M.AUTO and st.ready and trigger and not st.run and now >= st.auto_next then
		local r = start(st, now, st.ready, M.BOTH, "AUTO")
		msg = "CMD AUTO "..r.name
	end
	if st.mode ~= M.AUTO or not trigger then st.auto_next = -1 end
	local out = {}
	local r = st.run
	if r then
		while r.next <= #r.items and r.items[r.next].t <= now + 1e-9 do
			local it = r.items[r.next]
			if have(it.kind) then out[#out + 1] = {it.kind, it.n} end
			r.next = r.next + 1
		end
		if r.next > #r.items then
			if r.why == "AUTO" then st.auto_next = now + st.opt.auto_repeat end
			st.run = nil
		end
	end
	return out, msg
end

return M
