













local M = {}
local DEG = math.pi / 180
local NM = 1852
local G0 = 9.81

M.SYN_PERIOD, M.RAW_PERIOD, M.RAW_PERIOD_SLOW = 0.5, 1.25, 2.5
M.TURN_SLOW = 1 * DEG
M.SCAN_BOT = -20

function M.new()
	local s = {t_syn = 1e9, t_raw = 1e9, syn = {}, synr = {}, raw = {}, zcl = {}, owl = {}, ant = 0}
	for k = 1, TF_SCOPE.N do s.syn[k], s.synr[k], s.raw[k], s.zcl[k], s.owl[k] = TF_SCOPE.HIDE, 0, TF_SCOPE.HIDE,
		TF_SCOPE.HIDE, TF_SCOPE.HIDE end
	return s
end

function M.clear(s)
	local H = TF_SCOPE.HIDE
	for k = 1, TF_SCOPE.N do s.syn[k], s.synr[k], s.raw[k], s.zcl[k], s.owl[k] = H, 0, H, H, H end
	s.ant = 0
end


local function el(dh, d, gamma) return (math.atan2(dh, math.max(d, 1)) - gamma) / DEG end







function M.step(s, o, clr_m, ride, flyup_frac, sub, dt, ground, ahead, radar)
	local S = TF_SCOPE
	local N = S.N
	s.ant = math.abs(o.turn or 0) < M.TURN_SLOW and 0 or ((o.turn > 0) and 1 or -1)
	if radar then s.ant = radar.ant end

	local tg = math.tan(o.gamma)
	local dn = math.max((ride and ride.nz_hi or 2) - 1, 0.5)
	local R = math.max(o.v, 50) ^ 2 / (G0 * dn)
	for k = 1, N do
		if k % S.EVERY == 0 then
			local d = S.col_nm(k) * NM
			s.zcl[k] = S.y(el(d * tg - clr_m, d, o.gamma))
			s.owl[k] = S.y(el(d * tg + d * d / (2 * R) - flyup_frac * clr_m, d, o.gamma))
		else
			s.zcl[k], s.owl[k] = S.HIDE, S.HIDE
		end
	end
	s.t_syn, s.t_raw = s.t_syn + dt, s.t_raw + dt
	if s.t_syn >= M.SYN_PERIOD then
		s.t_syn = 0
		local e = {}
		for k = 1, N do
			local nm = S.col_nm(k)
			if radar then
				e[k] = radar.syn[k]
			elseif nm <= S.SYN_NM then
				local d = nm * NM
				local x, z = ahead(o, d / math.max(o.gs, 50))
				local hg = ground(x, z)
				e[k] = hg and el(hg - o.h, d, o.gamma) or nil
			end
		end
		for k = 1, N do
			local y = e[k] and S.y(e[k]) or S.HIDE
			s.syn[k] = y

			local a, b = e[k - 1] or e[k], e[k + 1] or e[k]
			local ka, kb = e[k - 1] and k - 1 or k, e[k + 1] and k + 1 or k
			if y ~= S.HIDE and a and b and kb > ka then
				s.synr[k] = math.atan2((b - a) * S.K_DEG, S.col_x(kb) - S.col_x(ka))
			else
				s.synr[k] = 0
			end
		end
	end
	local slow = math.abs(o.turn or 0) >= M.TURN_SLOW or sub == 4 or sub == 5
	if s.t_raw >= (slow and M.RAW_PERIOD_SLOW or M.RAW_PERIOD) then
		s.t_raw = 0
		local top = sub == 1 and 10 or 5
		local c, sn = math.cos(o.trk), math.sin(o.trk)
		local hide = -math.huge
		for k = 1, radar and 0 or N do
			local d = S.col_nm(k) * NM
			local hg = ground(o.x + d * c, o.z + d * sn)
			local y = S.HIDE
			if hg then
				local a = math.atan2(hg - o.h, d) / DEG
				local e = a - o.gamma / DEG
				if a >= hide - 0.05 and e >= M.SCAN_BOT and e <= top then y = S.y(e) end
				hide = math.max(hide, a)
			end
			s.raw[k] = y
		end
		if radar then
			for k = 1, N do s.raw[k] = radar.raw[k] and S.y(radar.raw[k]) or S.HIDE end
		end
	end
end


function M.leg_max(x0, z0, x1, z1, off, step, ground)
	local dx, dz = x1 - x0, z1 - z0
	local L = math.sqrt(dx * dx + dz * dz)
	local n = math.max(1, math.min(200, math.ceil(L / step)))
	local ux, uz = L > 1 and dx / L or 1, L > 1 and dz / L or 0
	local best
	for i = 0, n do
		local f = i / n
		for _, s in ipairs({-off, 0, off}) do
			local h = ground(x0 + dx * f - uz * s, z0 + dz * f + ux * s)
			if h and (not best or h > best) then best = h end
		end
	end
	return best
end

return M
