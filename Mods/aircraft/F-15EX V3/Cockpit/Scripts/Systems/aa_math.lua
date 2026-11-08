



local M = {}


local sqrt, sin, cos, acos, deg, rad, abs = math.sqrt, math.sin, math.cos, math.acos, math.deg, math.rad, math.abs
local atan2, exp = math.atan2, math.exp

M.G = 9.80665
M.M_PER_NM = 1852.0





local function body_vector(brg, elev, pitch, roll)
	local ce = math.cos(elev)
	local vx, vy, vz = ce * math.cos(brg), ce * math.sin(brg), -math.sin(elev)
	local ct, st, cp, sp = math.cos(pitch), math.sin(pitch), math.cos(roll), math.sin(roll)
	local ux, uy, uz = ct * vx - st * vz, vy, st * vx + ct * vz
	return ux, cp * uy + sp * uz, -sp * uy + cp * uz
end

M.body_vector = body_vector

function M.body_angles(brg, elev, pitch, roll)
	local bx, by, bz = body_vector(brg, elev, pitch, roll)
	return math.atan2(by, bx), math.atan2(-bz, math.sqrt(bx * bx + by * by))
end





function M.body_polar(bx, by, bz)
	local l = math.sqrt(bx * bx + by * by + bz * bz)
	if l < 1e-12 then return 0, math.pi / 2 end
	bx, by, bz = bx / l, by / l, bz / l
	local off = math.acos(math.max(-1, math.min(1, bx)))
	if by * by + bz * bz < 1e-12 then return off, math.pi / 2 end
	return off, math.atan2(-bz, by)
end

function M.hud_polar(brg, elev, pitch, roll)
	return M.body_polar(body_vector(brg, elev, pitch, roll))
end





function M.glass_r(poly, dir, side, below)
	local dx, dy = math.cos(dir), math.sin(dir)
	local best
	for i = 1, #poly do
		local a, b = poly[i], poly[i % #poly + 1]
		local ex, ey = b[1] - a[1], b[2] - a[2]
		local den = dx * ey - dy * ex
		if math.abs(den) > 1e-12 then
			local t = (a[1] * ey - a[2] * ex) / den
			local u = (a[1] * dy - a[2] * dx) / den
			if t > 0 and u >= 0 and u <= 1 and (best == nil or t < best) then best = t end
		end
	end
	if best == nil then return 0 end
	return math.max(0, best - (side or 0) - (below or 0) * math.max(0, -dy))
end





M.DLZ = {
	["120D"] = {sl = 18.0, ne = 0.35, min = 0.5},
	["120C"] = {sl = 15.0, ne = 0.33, min = 0.5},
	["120B"] = {sl = 13.0, ne = 0.30, min = 0.5},
	["260A"] = {sl = 24.0, ne = 0.40, min = 0.6},
	["174B"] = {sl = 45.0, ne = 0.30, min = 2.0},
	["9X"]   = {sl = 4.5,  ne = 0.45, min = 0.3},
	["9X2"]  = {sl = 4.5,  ne = 0.45, min = 0.3},
	["9M"]   = {sl = 3.5,  ne = 0.40, min = 0.3},
	["7M"]   = {sl = 12.0, ne = 0.30, min = 0.8},
}
M.ALT_K = 0.025
M.CL_K = 1200.0



M.DLZ_FAMILY = {MRM = "120C", SRM = "9M", LRM = "174B"}



function M.dlz(code, alt_ft, mach, closure_kt, family)
	local d = M.DLZ[code] or M.DLZ[string.match(code or "", "^(%d+%a*)") or ""] or M.DLZ[M.DLZ_FAMILY[family or ""] or ""]
	if not d then return nil end
	local alt = math.max(0, alt_ft or 0) / 1000
	local f = (1 + M.ALT_K * alt) * (0.6 + 0.4 * math.max(0, mach or 0))
		* math.max(0.4, math.min(2.0, 1 + (closure_kt or 0) / M.CL_K))
	local rmax = math.max(d.sl * f, 2 * d.min)
	return rmax * M.M_PER_NM, math.max(d.ne * rmax, d.min * 1.5) * M.M_PER_NM, d.min * M.M_PER_NM
end
















M.KMH_REF = 900.0
M.DLZ_RMIN_DEFAULT = 500.0
local function lerp_alt(h, r1, r5, r10)
	if h >= 10 then return r10 end
	if h >= 5 then return r5 + (r10 - r5) * (h - 5) / 5 end
	return r1 + (r5 - r1) * (h - 1) / 4
end


function M.dlz_model(d, d_min, alt_m, own_kmh, tgt_away_kmh, aspect_deg)
	local h = math.max(0, alt_m or 0) / 1000
	local a = math.rad(aspect_deg or 180)
	local head = lerp_alt(h, d[8], d[4], d[6])
	local tail = lerp_alt(h, d[9], d[5], d[7])
	local r = tail + (head - tail) * (1 - math.cos(a)) / 2
	r = r + d[1] * (head / d[8]) * ((own_kmh or M.KMH_REF) - M.KMH_REF)
	if tgt_away_kmh then
		r = r + (d[2] + d[3] * (h - 1)) * (tgt_away_kmh - M.KMH_REF * math.cos(a))
	end
	local rmin = d_min or M.DLZ_RMIN_DEFAULT
	local rmax = math.max(r, 2 * rmin)
	local frac = math.max(0.05, math.min(0.95, d[11] + d[12] * (h - 1)))
	return rmax, math.max(frac * rmax, 1.5 * rmin), rmin
end












local function hunit(v)
	local n = math.sqrt(v[1] * v[1] + v[3] * v[3])
	if n > 0 then return v[1] / n, v[3] / n end
	return v[1], v[3]
end
local function sgn(x) return x > 0 and 1 or x < 0 and -1 or 0 end


local function maxss(a, b) if a > b then return a end return b end
local function minss(a, b) if a < b then return a end return b end
local function clamp1(x)
	x = maxss(-1, x)
	if 1 > x then return x end
	return 1
end
local function lagrange(h, r1, r5, r10)
	return (h - 5000) * r10 * (h - 1000) / 45e6 - (h - 10000) * r5 * (h - 1000) / 20e6
		+ (h - 10000) * r1 * (h - 5000) / 36e6
end




local PREP = {}
local function dlz_prep(P, md, d_min, alt_m, vt, d)
	local H = minss(15000, maxss(10, alt_m))
	P.rh = lagrange(H, md[53], md[49], md[51])
	P.rt = lagrange(H, md[54], md[50], md[52])
	P.tx, P.tz = hunit(vt)
	P.dx, P.dz = hunit(d)

	local d2 = maxss(d[1] * d[1] + d[2] * d[2] + d[3] * d[3], 1)
	local w = minss(vt[1] / d2 * d[3] - vt[3] / d2 * d[1], 0.7853982)
	P.wturn = deg(w) * (md[37] + 1.5)
	local Vt = sqrt(vt[1] * vt[1] + vt[2] * vt[2] + vt[3] * vt[3])
	P.Vt = Vt
	local hk1 = H * 0.001 - 1
	P.kc = md[46] + 0.2 * (H * H * 1e-6)
	local kt = hk1 * md[48] + md[47]
	P.kt = kt
	local T = (Vt - 250) * kt
	P.T = T
	P.Tterm = T < 0 and 0.6 * T or -T
	P.f = md[56] + hk1 * md[57]
	P.md35, P.md55, P.d_min = md[35], md[55], d_min
	return P
end
local function dlz_core(P, vx, vy, vz)
	local n = sqrt(vx * vx + vz * vz)
	local cx, cz = vx, vz
	if n > 0 then cx, cz = vx / n, vz / n end
	local tx, tz, dx, dz = P.tx, P.tz, P.dx, P.dz

	local a1 = deg(acos(clamp1(tx * cx + tz * cz))) * sgn(-tx * cz + tz * cx)
	local a2 = deg(acos(clamp1(dx * cx + dz * cz))) * sgn(-dx * cz + dz * cx)
	local a2p = a2 - P.wturn
	local Vc = sqrt(vx * vx + vy * vy + vz * vz)
	local Vt, kc, kt, T, rh, rt, md35 = P.Vt, P.kc, P.kt, P.T, P.rh, P.rt, P.md35
	local C = (Vc - 250) * kc
	local out1 = C + P.Tterm + rh
	local out2 = (C > 0 and 0.6 or 0.8) * C + T + rt
	if not (out2 > 0) then out2 = 0 end
	local X = a2p - a1
	out1 = maxss(out1, 1)
	local e_num, e_den = (out1 - out2) * 0.5, (out1 + out2) * 0.5
	local m = (Vc - 250) * 0.35
	local out3
	if abs(X) > 90 then
		local z = md35 * 0.95
		local u = rh / -kt - 250 + m
		local cap = (u + Vt) * z
		if out1 > cap then e_den, e_num = u * z, z * Vt end
		local tt = kt * 50
		out3 = C + (tt < 0 and 0.6 * tt or -tt) + rh + (Vt > 300 and (Vt - 300) * -kt or 0)
		if out3 > cap then out3 = cap elseif out1 > out3 then out3 = out1 end
	else
		local u = rt / kc + 250 + m * 1.4
		local cap = (u - Vt) * md35
		if out2 > cap then e_den, e_num = u * md35, md35 * Vt end
		out3 = (C > 0 and 0.6 or 0.8) * C + kt * 50 + rt + (Vt > 300 and (Vt - 300) * -kc or 0)
		if out3 > cap then out3 = cap elseif out2 > out3 then out3 = out2 end
	end

	local ecc = minss(e_num / e_den, 1)
	local xr = rad(X)
	local s, c = sin(xr), cos(xr)
	local g = clamp1(sqrt(1 - ecc * ecc * s * s) * c + ecc * s * s)
	local half = (e_den + P.md55) * 0.5
	local cb = cos(rad(deg(acos(g)) * sgn(s) + a1))
	local p = e_den - half
	local r0 = sqrt(maxss(half * half - (1 - cb * cb) * p * p, 0)) + p * cb
	local re = r0 * ecc
	out1 = sqrt(maxss(re * re + r0 * r0 - 2 * r0 * re * g, 0))

	local ca = cos(rad(a2p))
	local f = P.f
	local ra = rad(a1)
	out2 = ((sin(ra) * (1 - ca * ca) * sgn(a2p) + cos(ra) * ca * ca + 1) * (0.94 - f) * 0.5 + f) * out1
	if out1 > out3 then out3 = out1 end
	if out2 > out1 then out2 = out1 end
	local d_min = P.d_min
	if d_min > out2 then out2 = d_min end
	if d_min > out1 then out1 = d_min end
	return out1, out2, out3
end
function M.dlz_ed(md, d_min, alt_m, vc, vt, d)
	return dlz_core(dlz_prep(PREP, md, d_min, alt_m, vt, d), vc[1], vc[2], vc[3])
end













M.WEZ_GRID = math.rad(5)
M.WEZ_ASE_CAP = math.rad(45)
function M.wez_ed(md, d_min, alt_m, vc, vt, d, range)

	local P = dlz_prep(PREP, md, d_min, alt_m, vt, d)
	local v1, v2, v3 = vc[1], vc[2], vc[3]
	local function at(a)
		local c, s = cos(a), sin(a)
		return dlz_core(P, v1 * c - v3 * s, v2, v3 * c + v1 * s)
	end
	local function rpi(a) return (at(a)) end
	local pi, tr = dlz_core(P, v1, v2, v3)

	local best, rbest = 0, pi
	local n = math.floor(math.rad(90) / M.WEZ_GRID + 0.5)
	for k = -n, n do
		local a = k * M.WEZ_GRID
		local r = rpi(a)
		if r > rbest then best, rbest = a, r end
	end
	local lo, hi = best - M.WEZ_GRID, best + M.WEZ_GRID
	local g = (math.sqrt(5) - 1) / 2
	local x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
	local f1, f2 = rpi(x1), rpi(x2)
	for _ = 1, 12 do
		if f1 > f2 then hi, x2, f2 = x2, x1, f1 x1 = hi - g * (hi - lo) f1 = rpi(x1)
		else lo, x1, f1 = x1, x2, f2 x2 = lo + g * (hi - lo) f2 = rpi(x2) end
	end
	local xm = (lo + hi) / 2
	local fm = rpi(xm)
	if fm > rbest then best, rbest = xm, fm end
	local opt = math.max(rbest, pi)
	if opt <= d_min then return nil end
	local _, _, aero = at(best)

	local ase = 0
	if rbest >= range then
		local function edge(sgn)
			local a0, a1 = 0, M.WEZ_ASE_CAP
			if rpi(best + sgn * a1) >= range then return a1 end
			for _ = 1, 14 do
				local m = (a0 + a1) / 2
				if rpi(best + sgn * m) >= range then a0 = m else a1 = m end
			end
			return a0
		end
		local side = best > 1e-4 and -1 or best < -1e-4 and 1 or 0
		ase = side ~= 0 and edge(side) or math.min(edge(-1), edge(1))
	end
	return {aero = math.max(aero, opt), opt = opt, pi = pi, mnvr = (tr + pi) / 2, tr = tr, min = d_min, lead = best,
		ase = ase}
end







M.WEZ_OPT = 0.8
function M.wez(rmax, rne, rmin, steer)
	local opt = math.max(M.WEZ_OPT * rmax, rmin)
	local tr = math.max(math.min(rne, opt), rmin)
	local mnvr = (tr + opt) / 2
	local s = math.min(1, (steer or 0) ^ 2)
	return {aero = rmax, opt = opt, pi = opt - (opt - mnvr) * s, mnvr = mnvr, tr = tr, min = rmin}
end




M.TOF_V0, M.TOF_V1 = 1000.0, 550.0
function M.prelaunch_tti(range_m, aero_m, closure_mps, own_los_mps)
	local f = math.min(1, range_m / math.max(aero_m, 1))
	local v = M.TOF_V0 + (M.TOF_V1 - M.TOF_V0) * f + ((closure_mps or 0) - (own_los_mps or 0))
	if v < 50 then return nil end
	return range_m / v
end


M.SCALES = {5, 10, 20, 40, 80, 160}
function M.range_scale(range_m, rmax_m)
	local need = math.max(range_m or 0, rmax_m or 0) * 1.1 / M.M_PER_NM
	for _, s in ipairs(M.SCALES) do if s >= need then return s end end
	return M.SCALES[#M.SCALES]
end
















M.MUZZLE_MPS = 1086.0
M.DRAG_K = 9.74e-4
M.SCALE_H = 9000.0
M.WINGSPAN_M = 12.0



M.MUZZLE_FROM_EYE = {4.00 - 6.377, 2.00, -(0.45 - 1.220)}






local function flight_paths(ranges, v, opts)
	local k = M.DRAG_K * math.exp(-math.max(opts.alt_m or 0, 0) / M.SCALE_H)
	local al, be = opts.alpha or 0, opts.beta or 0
	local va = {v * math.cos(al) * math.cos(be), v * math.sin(be), v * math.sin(al) * math.cos(be)}
	local gz = (opts.nz or 1) * M.G
	local out = {}
	local u = {M.MUZZLE_MPS, 0, 0}
	local x = {0, 0, 0}
	local s, t, dt = 0, 0, 0.005
	local order = {}
	for i = 1, #ranges do order[i] = i end
	table.sort(order, function(a, b) return ranges[a] < ranges[b] end)
	local j = 1
	while j <= #order do
		local r = ranges[order[j]]
		local us = math.sqrt(u[1] * u[1] + u[2] * u[2] + u[3] * u[3])
		if s >= r or us < 50 or t > 10 then
			local back = (s - r) / math.max(us, 50)
			out[order[j]] = {pos = {x[1] - u[1] * back, x[2] - u[2] * back, x[3] - u[3] * back}, t = t - back}
			j = j + 1
		else
			local w1, w2, w3 = u[1] + va[1], u[2] + va[2], u[3] + va[3]
			local kw = k * math.sqrt(w1 * w1 + w2 * w2 + w3 * w3)
			u[1] = u[1] - kw * w1 * dt
			u[2] = u[2] - kw * w2 * dt
			u[3] = u[3] + (gz - kw * w3) * dt
			x[1], x[2], x[3] = x[1] + u[1] * dt, x[2] + u[2] * dt, x[3] + u[3] * dt
			s = s + us * dt
			t = t + dt
		end
	end
	return out
end


local function rotate_back(a, n, angle)
	local c, s = math.cos(angle), -math.sin(angle)
	local d = n[1] * a[1] + n[2] * a[2] + n[3] * a[3]
	local x = {n[2] * a[3] - n[3] * a[2], n[3] * a[1] - n[1] * a[3], n[1] * a[2] - n[2] * a[1]}
	return {a[1] * c + x[1] * s + n[1] * d * (1 - c), a[2] * c + x[2] * s + n[2] * d * (1 - c),
		a[3] * c + x[3] * s + n[3] * d * (1 - c)}
end


M.FUNNEL_RANGES = {}
for k = 1, 16 do M.FUNNEL_RANGES[k] = math.floor(150 * (1524 / 150) ^ ((k - 1) / 15) + 0.5) end

M.SEARCH_PIPPERS = {304.8, 685.8, 1219.2}


function M.funnel(v_mps, nz, pitch, roll, ranges, opts)
	ranges = ranges or M.FUNNEL_RANGES
	opts = opts or {}
	local v = math.max(v_mps or 0, 50)
	nz = nz or 1
	local w = {opts.p or 0, opts.q or M.G * (nz - math.cos(pitch or 0) * math.cos(roll or 0)) / v, opts.r or 0}
	local wl = math.sqrt(w[1] * w[1] + w[2] * w[2] + w[3] * w[3])
	local n = wl > 1e-9 and {w[1] / wl, w[2] / wl, w[3] / wl}
	local m = M.MUZZLE_FROM_EYE
	local fp = flight_paths(ranges, v, {alt_m = opts.alt_m, alpha = opts.alpha, beta = opts.beta, nz = nz})
	local out = {}
	for i, r in ipairs(ranges) do
		local t, pos = fp[i].t, fp[i].pos

		local b = {m[1] + pos[1], m[2] + pos[2], m[3] + pos[3]}
		if n then b = rotate_back(b, n, wl * t) end
		local x = math.atan2(b[2], b[1])
		local y = -math.atan2(b[3], math.sqrt(b[1] * b[1] + b[2] * b[2]))
		out[i] = {x = x, y = y, w = M.WINGSPAN_M / 2 / r, r = r, t = t}
	end
	return out
end




local function body_axes(h, p, r)
	local ch, sh, cp, sp, cr, sr = math.cos(h), math.sin(h), math.cos(p), math.sin(p), math.cos(r), math.sin(r)
	return {cp * ch, cp * sh, -sp},
		{sr * sp * ch - cr * sh, sr * sp * sh + cr * ch, sr * cp},
		{cr * sp * ch + sr * sh, cr * sp * sh - sr * ch, cr * cp}
end
local function dot3(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
function M.body_rates(h0, p0, r0, h1, p1, r1, dt)
	local x0, y0, z0 = body_axes(h0, p0, r0)
	local x1, y1, z1 = body_axes(h1, p1, r1)

	return (dot3(z0, y1) - dot3(y0, z1)) / 2 / dt, (dot3(x0, z1) - dot3(z0, x1)) / 2 / dt,
		(dot3(y0, x1) - dot3(x0, y1)) / 2 / dt
end










M.STREAM_DT = 0.02



M.STREAM_T_MAX = 4.0


M.EYE_BODY = {6.377, 0, -1.220}
M.MUZZLE_BODY = {4.00, 2.00, -0.45}


local function world_axes(h, p, r)
	local x, y, z = body_axes(h, p, r)
	local function w(a) return {a[1], -a[3], a[2]} end
	return w(x), w(y), w(z)
end
M.world_axes = world_axes
local function to_world(ax, b)
	return {ax[1][1] * b[1] + ax[2][1] * b[2] + ax[3][1] * b[3], ax[1][2] * b[1] + ax[2][2] * b[2] + ax[3][2] * b[3],
		ax[1][3] * b[1] + ax[2][3] * b[2] + ax[3][3] * b[3]}
end

function M.stream_new() return {b = {}, t_fire = nil} end
function M.stream_reset(st) st.b = {} st.t_fire = nil end



function M.stream_update(st, now, dt, pos, vel, h, p, r)
	local b = st.b
	if dt > 0 then
		local n = math.max(1, math.ceil(dt / 0.01))
		local s = dt / n
		local DRAG_K, SCALE_H, G = M.DRAG_K, M.SCALE_H, M.G
		for i = 1, #b do
			local k = b[i]
			local v, x = k.v, k.x
			for _ = 1, n do
				local sp = sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
				local x2 = x[2]
				local kd = DRAG_K * exp(-(x2 > 0 and x2 or 0) / SCALE_H) * sp
				v[1] = v[1] - kd * v[1] * s
				v[2] = v[2] - (kd * v[2] + G) * s
				v[3] = v[3] - kd * v[3] * s
				x[1], x[2], x[3] = x[1] + v[1] * s, x[2] + v[2] * s, x[3] + v[3] * s
			end
			k.age = k.age + dt
		end
		while #b > 0 and b[#b].age > M.STREAM_T_MAX do b[#b] = nil end
	end
	if st.t_fire == nil or now - st.t_fire >= M.STREAM_DT or now < st.t_fire then
		local ax = {world_axes(h, p, r)}
		local m = to_world(ax, M.MUZZLE_BODY)
		local f = ax[1]
		table.insert(b, 1, {x = {pos[1] + m[1], pos[2] + m[2], pos[3] + m[3]}, age = 0,
			v = {vel[1] + M.MUZZLE_MPS * f[1], vel[2] + M.MUZZLE_MPS * f[2], vel[3] + M.MUZZLE_MPS * f[3]}})
		st.t_fire = now
	end
end





function M.stream_funnel(st, ranges, pos, h, p, r)
	local ax = {world_axes(h, p, r)}
	local e = to_world(ax, M.EYE_BODY)
	local ex, ey, ez = pos[1] + e[1], pos[2] + e[2], pos[3] + e[3]
	local a1, a2, a3 = ax[1], ax[2], ax[3]


	local PX, PY, PZ, PD, PA = st.px, st.py, st.pz, st.pd, st.pa
	if not PX then
		PX, PY, PZ, PD, PA = {}, {}, {}, {}, {}
		st.px, st.py, st.pz, st.pd, st.pa = PX, PY, PZ, PD, PA
	end
	local b = st.b
	local np = #b
	for i = 1, np do
		local k = b[i]
		local kx = k.x
		local d1, d2, d3 = kx[1] - ex, kx[2] - ey, kx[3] - ez
		local bx = d1 * a1[1] + d2 * a1[2] + d3 * a1[3]
		local by = d1 * a2[1] + d2 * a2[2] + d3 * a2[3]
		local bz = d1 * a3[1] + d2 * a3[2] + d3 * a3[3]
		PX[i], PY[i], PZ[i], PD[i], PA[i] = bx, by, bz, sqrt(bx * bx + by * by + bz * bz), k.age
	end
	local out = {}
	for j, R in ipairs(ranges) do
		for i = 2, np do
			local ad, cd = PD[i - 1], PD[i]
			if ad <= R and cd >= R and cd > ad then
				local u = (R - ad) / (cd - ad)
				local ax_, ay_, az_ = PX[i - 1], PY[i - 1], PZ[i - 1]
				local bx, by, bz = ax_ + u * (PX[i] - ax_), ay_ + u * (PY[i] - ay_), az_ + u * (PZ[i] - az_)
				if bx > 0 then
					out[j] = {x = atan2(by, bx), y = -atan2(bz, sqrt(bx * bx + by * by)),
						w = M.WINGSPAN_M / 2 / R, r = R, t = PA[i - 1] + u * (PA[i] - PA[i - 1])}
				end
				break
			end
		end
	end
	return out
end






function M.funnel_dashes(pts, step, n)
	local c = {}
	for i = 1, #pts do
		if not pts[i] then break end
		c[i] = pts[i]
	end
	local sides = {{}, {}}
	if #c < 2 then return sides[1], sides[2] end



	local tx, ty = c[#c].x - c[1].x, c[#c].y - c[1].y
	local l = math.sqrt(tx * tx + ty * ty)
	if l < 1e-9 then tx, ty, l = 0, -1, 1 end
	for s, sgn in ipairs({-1, 1}) do
		local nx, ny = -ty / l * sgn, tx / l * sgn
		local line = {}
		for i = 1, #c do
			line[i] = {(c[i].x + nx * c[i].w) * 1000, (c[i].y + ny * c[i].w) * 1000}
		end
		local out, acc = sides[s], 0.5 * step
		for i = 2, #line do
			local x0, y0, x1, y1 = line[i - 1][1], line[i - 1][2], line[i][1], line[i][2]
			local l = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
			local ang = math.atan2(y1 - y0, x1 - x0)
			while acc <= l and #out < n do
				local u = l > 0 and acc / l or 0
				out[#out + 1] = {x0 + u * (x1 - x0), y0 + u * (y1 - y0), ang}
				acc = acc + step
			end
			acc = acc - l
		end
	end
	return sides[1], sides[2]
end











local function cross_turn(v, w, t)


	if math.abs(w) < 1e-6 then return {v[1] * t, v[2] * t, v[3] * t} end
	local s, c = math.sin(w * t) / w, (1 - math.cos(w * t)) / w

	return {v[1] * s - v[3] * c, v[2] * t, v[3] * s + v[1] * c}
end





local function accel_turn(v, a, t)
	local v2 = v[1] * v[1] + v[2] * v[2] + v[3] * v[3]
	if v2 < 1 then return {v[1] * t + 0.5 * a[1] * t * t, v[2] * t + 0.5 * a[2] * t * t, v[3] * t + 0.5 * a[3] * t * t} end
	local kt = (a[1] * v[1] + a[2] * v[2] + a[3] * v[3]) / v2
	local at = {kt * v[1], kt * v[2], kt * v[3]}
	local an = {a[1] - at[1], a[2] - at[2], a[3] - at[3]}
	local W = math.sqrt(an[1] * an[1] + an[2] * an[2] + an[3] * an[3]) / math.sqrt(v2)
	local h = 0.5 * t * t
	if W < 1e-6 then
		return {v[1] * t + a[1] * h, v[2] * t + a[2] * h, v[3] * t + a[3] * h}
	end

	local s, c = math.sin(W * t) / W, (1 - math.cos(W * t)) / (W * W)
	return {v[1] * s + an[1] * c + at[1] * h, v[2] * s + an[2] * c + at[2] * h, v[3] * s + an[3] * c + at[3] * h}
end
M.accel_turn = accel_turn



function M.turn_state(v, a, t)
	local disp = accel_turn(v, a, t)
	local v2 = v[1] * v[1] + v[2] * v[2] + v[3] * v[3]
	if v2 < 1 then return disp, {v[1] + a[1] * t, v[2] + a[2] * t, v[3] + a[3] * t}, {a[1], a[2], a[3]} end
	local kt = (a[1] * v[1] + a[2] * v[2] + a[3] * v[3]) / v2
	local at = {kt * v[1], kt * v[2], kt * v[3]}
	local an = {a[1] - at[1], a[2] - at[2], a[3] - at[3]}
	local W = math.sqrt(an[1] * an[1] + an[2] * an[2] + an[3] * an[3]) / math.sqrt(v2)
	if W < 1e-6 then return disp, {v[1] + a[1] * t, v[2] + a[2] * t, v[3] + a[3] * t}, {a[1], a[2], a[3]} end
	local c, s = math.cos(W * t), math.sin(W * t)
	local vt, ac = {}, {}
	for i = 1, 3 do
		vt[i] = v[i] * c + an[i] * s / W + at[i] * t
		ac[i] = an[i] * c - W * v[i] * s + at[i]
	end
	return disp, vt, ac
end


function M.director(d, v, vel, w, h, p, r, alt_m, acc)
	local ax = {world_axes(h, p, r)}
	local e = to_world(ax, M.EYE_BODY)
	local m = to_world(ax, M.MUZZLE_BODY)
	local k = M.DRAG_K * math.exp(-math.max(alt_m or 0, 0) / M.SCALE_H)
	local vt = {v[1] + vel[1], v[2] + vel[2], v[3] + vel[3]}
	local U = M.MUZZLE_MPS
	local vo2 = vel[1] ^ 2 + vel[2] ^ 2 + vel[3] ^ 2


	local use_acc = acc and (acc[1] ~= 0 or acc[2] ~= 0 or acc[3] ~= 0)
	local function Q(t)
		local tm = use_acc and accel_turn(vt, acc, t) or cross_turn(vt, w or 0, t)
		return {d[1] + tm[1] - m[1], d[2] + tm[2] - m[2] + 0.5 * M.G * t * t, d[3] + tm[3] - m[3]}
	end
	local function len(a) return math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2) end


	local L = U + math.sqrt(vo2)
	local t, dirw
	for _ = 1, 4 do

		local function f(x) return math.log(1 + k * L * x) / k - len(Q(x)) end
		local lo, hi = 1e-3, M.STREAM_T_MAX
		if f(hi) < 0 then return nil end
		if f(lo) > 0 then hi = lo end
		for _ = 1, 40 do
			local mid = 0.5 * (lo + hi)
			if f(mid) < 0 then lo = mid else hi = mid end
		end
		t = hi
		local q = Q(t)
		local ql = len(q)
		local u = {q[1] / ql, q[2] / ql, q[3] / ql}

		local b = u[1] * vel[1] + u[2] * vel[2] + u[3] * vel[3]
		local disc = b * b - vo2 + U * U
		if disc < 0 then return nil end
		L = b + math.sqrt(disc)
		dirw = {(L * u[1] - vel[1]) / U, (L * u[2] - vel[2]) / U, (L * u[3] - vel[3]) / U}
	end

	local function hud(a)
		local bx = a[1] * ax[1][1] + a[2] * ax[1][2] + a[3] * ax[1][3]
		local by = a[1] * ax[2][1] + a[2] * ax[2][2] + a[3] * ax[2][3]
		local bz = a[1] * ax[3][1] + a[2] * ax[3][2] + a[3] * ax[3][3]
		return math.atan2(by, bx), -math.atan2(bz, math.sqrt(bx * bx + by * by))
	end
	local gx, gy = hud(dirw)
	local tx, ty = hud({d[1] - e[1], d[2] - e[2], d[3] - e[3]})
	return tx - gx, ty - gy, t, dirw
end




function M.aspect(brg, hdg_rel_deg)
	local rel = ((math.deg(brg) + 180) - hdg_rel_deg + 180) % 360 - 180
	local a = 180 - math.abs(rel)
	local side = rel >= 0 and 1 or -1
	local tens = math.floor(a / 10 + 0.5)
	local txt = tens >= 18 and "H" or tens <= 0 and "T" or string.format("%d%s", tens, side > 0 and "R" or "L")
	return a, side, txt
end






function M.track_alt_ft(own_alt_m, range_m, elev)
	return (own_alt_m + range_m * math.sin(elev)) / 0.3048
end

function M.alt_text(ft)
	ft = math.max(0, ft)
	return string.format("%d-%d", math.floor(ft / 1000), math.floor(ft % 1000 / 100))
end







M.ALT_TAU = 3
M.ALT_BAND_FT = 100
function M.alt_filter()
	local F = {s = {}}

	function F.update(key, ft, now)
		local e = F.s[key]
		if not e or now - e.t > 3 or now < e.t or math.abs(ft - e.h) > 3000 then
			e = {h = ft, r = 0, t = now}
			F.s[key] = e
			return ft
		end
		local dt = now - e.t
		if dt <= 0 then return e.h end
		local w = 1 / M.ALT_TAU
		local hp = e.h + e.r * dt
		local res = ft - hp
		e.h = hp + math.min(1, 2 * w * dt) * res
		e.r = e.r + w * w * dt * res
		e.t = now
		return e.h
	end

	function F.step(key, ft, step, round)
		local e = F.s[key]
		local q = math.floor(ft / step + (round and 0.5 or 0))
		if e then
			local field = round and "qr" or "qf"
			local old = e[field]
			if old then
				local lo = (old - (round and 0.5 or 0)) * step - M.ALT_BAND_FT
				local hi = (old + (round and 0.5 or 1)) * step + M.ALT_BAND_FT
				if ft >= lo and ft < hi then q = old end
			end
			e[field] = q
		end
		return q
	end

	function F.text(key, raw_ft, now)
		local ft = math.max(0, F.update(key, raw_ft, now))
		local q = math.max(0, F.step(key, ft, 100, false))
		return string.format("%d-%d", math.floor(q / 10), q % 10)
	end

	function F.kft(key, raw_ft, now)
		local ft = math.max(0, F.update(key, raw_ft, now))
		return math.max(0, F.step(key, ft, 1000, true))
	end
	return F
end




M.WPN_LETTER = {["120"] = "A", ["9"] = "S", ["7"] = "M", ["174"] = "L", ["260"] = "J"}
M.FAM_LETTER = {SRM = "S", MRM = "M", LRM = "L"}
function M.weapon_text(sel)
	sel = sel or ""
	local _, _, fam, code, count = string.find(sel, "^(%a+) ([%w%-]+) (%d+)$")
	if not fam then return sel end
	local _, _, num, variant = string.find(code, "^(%d+)(%a*%-?%d*)$")
	local letter = num and M.WPN_LETTER[num]

	if not letter then return M.FAM_LETTER[fam] and string.format("%s%s %s", M.FAM_LETTER[fam], count, code) or sel end
	if num == "120" then return string.format("A %s %s", variant, count) end
	return letter..count..variant
end

return M
