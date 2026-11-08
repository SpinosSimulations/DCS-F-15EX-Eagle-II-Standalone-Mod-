







local M = {}


function M.start(now, code)
	return {t0 = now, code = code}
end


function M.shown(tti)
	return math.ceil(math.max(tti, 0))
end








M.EMIT_WINDOW = 2.5
M.EMIT_MIN_N = 3
M.EMIT_MIN_RATE = 0.005
M.EMIT_STALE = 2.5

function M.emit_new() return {t = {}, p = {}} end


function M.emit_add(st, now, p)
	local n = #st.p
	if n > 0 and p == st.p[n] then return false end
	st.t[n + 1], st.p[n + 1] = now, p
	while #st.t > 0 and now - st.t[1] > M.EMIT_WINDOW do
		table.remove(st.t, 1) table.remove(st.p, 1)
	end
	return true
end


function M.emit_tti(st, now)
	local n = #st.t
	if n < M.EMIT_MIN_N or now - st.t[n] > M.EMIT_STALE then return nil end
	local mt, mp = 0, 0
	for i = 1, n do mt, mp = mt + st.t[i], mp + st.p[i] end
	mt, mp = mt / n, mp / n
	local stt, stp = 0, 0
	for i = 1, n do
		local dt = st.t[i] - mt
		stt, stp = stt + dt * dt, stp + dt * (st.p[i] - mp)
	end
	if stt <= 0 then return nil end
	local rate = stp / stt
	if rate < M.EMIT_MIN_RATE then return nil end
	local p_now = math.min(mp + rate * (now - mt), 1)
	return math.max(0, (1 - p_now) / rate)
end

return M
