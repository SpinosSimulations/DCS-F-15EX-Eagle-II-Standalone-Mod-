






local M = {}

local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
local function cross(a, b)
	return {a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1]}
end
local function norm(a)
	local l = math.sqrt(dot(a, a))
	if l < 1e-12 then return nil end
	return {a[1] / l, a[2] / l, a[3] / l}
end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end



function M.body_axes(hdg, pitch, bank)
	local ch, sh, cp, sp, cb, sb = math.cos(hdg), math.sin(hdg), math.cos(pitch), math.sin(pitch), math.cos(bank),
		math.sin(bank)
	local f = {cp * ch, sp, cp * sh}
	local r0 = {-sh, 0, ch}
	local u0 = {-sp * ch, cp, -sp * sh}
	local r = {cb * r0[1] - sb * u0[1], cb * r0[2] - sb * u0[2], cb * r0[3] - sb * u0[3]}
	local u = {cb * u0[1] + sb * r0[1], cb * u0[2] + sb * r0[2], cb * u0[3] + sb * r0[3]}
	return f, r, u
end



function M.head_angles(cx, cy, cz, f, r, u)
	local fwd = norm(cx)
	local right = norm(cz)
	if not fwd or not right then return nil end
	local az = math.atan2(dot(fwd, r), dot(fwd, f))
	local el = math.asin(clamp(dot(fwd, u), -1, 1))

	local ref_r = norm(cross(fwd, u))
	if not ref_r then return az, el, 0 end
	local ref_u = cross(ref_r, fwd)
	local roll = math.atan2(-dot(right, ref_u), dot(right, ref_r))
	return az, el, roll
end



M.SCALE = {az = math.pi, el = math.pi / 2, roll = math.pi}



function M.to_head(bx, by, bz, az, el, roll)
	local d = norm({bx, by, bz})
	if not d then return nil end
	local ca, sa, ce, se, cr, sr = math.cos(az), math.sin(az), math.cos(el), math.sin(el), math.cos(roll), math.sin(roll)
	local hf = {ce * ca, ce * sa, -se}
	local hr0 = {-sa, ca, 0}
	local hu0 = {-se * ca, -se * sa, -ce}
	local hr = {cr * hr0[1] - sr * hu0[1], cr * hr0[2] - sr * hu0[2], cr * hr0[3] - sr * hu0[3]}
	local hu = {cr * hu0[1] + sr * hr0[1], cr * hu0[2] + sr * hr0[2], cr * hu0[3] + sr * hr0[3]}
	local c = dot(d, hf)
	local x, y = dot(d, hr), dot(d, hu)
	local off = math.acos(clamp(c, -1, 1))
	local dir = (x * x + y * y < 1e-12) and math.pi / 2 or math.atan2(y, x)
	return off, dir, off * math.cos(dir), off * math.sin(dir), c
end


function M.head_axes(az, el, roll)
	local ca, sa, ce, se, cr, sr = math.cos(az), math.sin(az), math.cos(el), math.sin(el), math.cos(roll), math.sin(roll)
	local hr0, hu0 = {-sa, ca, 0}, {-se * ca, -se * sa, -ce}
	return {ce * ca, ce * sa, -se},
		{cr * hr0[1] - sr * hu0[1], cr * hr0[2] - sr * hu0[2], cr * hr0[3] - sr * hu0[3]},
		{cr * hu0[1] + sr * hr0[1], cr * hu0[2] + sr * hr0[2], cr * hu0[3] + sr * hr0[3]}
end



function M.axes_angles(hf, hr, az_hint)
	local el = math.asin(clamp(-hf[3], -1, 1))
	local h = hf[1] * hf[1] + hf[2] * hf[2]
	local az = h > 1e-10 and math.atan2(hf[2], hf[1]) or (az_hint or 0)
	local ca, sa, ce, se = math.cos(az), math.sin(az), math.cos(el), math.sin(el)
	local roll = math.atan2(-dot(hr, {-se * ca, -se * sa, -ce}), dot(hr, {-sa, ca, 0}))
	return az, el, roll
end






function M.lead_rotation(o, s, dt, k_of)
	local of, or_, ou = M.head_axes(o.az, o.el, o.roll)
	local sf, sr, su = M.head_axes(s.az, s.el, s.roll)

	local function col(i) return {sf[i], sr[i], su[i]} end
	local function ocol(i) return {of[i], or_[i], ou[i]} end
	local R = {}
	for i = 1, 3 do
		R[i] = {}
		for j = 1, 3 do R[i][j] = dot(col(i), ocol(j)) end
	end
	local ax = {R[3][2] - R[2][3], R[1][3] - R[3][1], R[2][1] - R[1][2]}
	local sn = 0.5 * math.sqrt(dot(ax, ax))
	local cs = 0.5 * (R[1][1] + R[2][2] + R[3][3] - 1)
	local ang = math.atan2(sn, cs)
	local rate = ang / dt
	local k = k_of(rate)
	local n = norm(ax)
	if not k or k <= 0 or not n or ang < 1e-9 then return s.az, s.el, s.roll, rate end

	local a = rate * k
	local c, sa = math.cos(a), math.sin(a)
	local function turn(v)
		local nx = cross(n, v)
		local nd = dot(n, v) * (1 - c)
		return {v[1] * c + nx[1] * sa + n[1] * nd, v[2] * c + nx[2] * sa + n[2] * nd, v[3] * c + nx[3] * sa + n[3] * nd}
	end
	local az, el, roll = M.axes_angles(turn(sf), turn(sr), s.az)
	return az, el, roll, rate
end







function M.tape_bearing(az, el, roll, pitch, bank)
	local hf, _, hu = M.head_axes(az, el, roll)
	local cp, sp, ct, st = math.cos(bank), math.sin(bank), math.cos(pitch), math.sin(pitch)
	local function level(v)
		local y, z1 = cp * v[2] - sp * v[3], sp * v[2] + cp * v[3]
		return {ct * v[1] + st * z1, y, -st * v[1] + ct * z1}
	end
	local f, u = level(hf), level(hu)
	local se = clamp(-f[3], -1, 1)
	local ce = math.sqrt(1 - se * se)
	local dx, dy = ce * f[1] - se * u[1], ce * f[2] - se * u[2]
	if dx * dx + dy * dy < 1e-12 then return (M.level_dir(az, el, pitch, bank)) end
	return math.atan2(dy, dx)
end



function M.los_bearing(az, el, pitch, roll)
	return (M.level_dir(az, el, pitch, roll))
end



function M.level_dir(az, el, pitch, roll)
	local bx, by, bz = M.body_dir(az, el)
	local cp, sp, ct, st = math.cos(roll), math.sin(roll), math.cos(pitch), math.sin(pitch)
	local y, z1 = cp * by - sp * bz, sp * by + cp * bz
	local x, z = ct * bx + st * z1, -st * bx + ct * z1
	local h = math.sqrt(x * x + y * y)
	local elev = math.atan2(-z, h)
	if h < 1e-6 then return 0, elev end
	return math.atan2(y, x), elev
end


function M.body_dir(az, el)
	local ce = math.cos(el)
	return ce * math.cos(az), ce * math.sin(az), -math.sin(el)
end

return M
