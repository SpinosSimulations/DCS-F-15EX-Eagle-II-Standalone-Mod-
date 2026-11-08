















local M = {}

M.LOOK_PERIOD	= 1.0
M.MAX_LOOKS		= 90
M.MIN_BASELINE	= 1500.0
M.ROUGH_DEG		= 1.5
M.FIXED_DEG		= 4.0
M.MAX_RESID		= 0.03
M.REJECT_RESID	= 0.045

M.SWING_N		= 7
M.MIN_RANGE		= 500.0
M.MAX_RANGE		= 600000.0
M.ELEV_MIN_DEG	= 0.5
M.ELEV_MAX_RANGE = 300000.0
M.ELEV_MIN_HEIGHT = 150.0



M.NONE, M.ROUGH, M.FIXED = 0, 1, 2

local function wrap_pi(a) return (a + math.pi) % (2 * math.pi) - math.pi end


function M.new()
	return {looks = {}, t_last = -1e9}
end



function M.add_look(e, t, x, z, brg)
	if t - e.t_last < M.LOOK_PERIOD - 1e-9 then return false end
	e.t_last = t
	local l = e.looks
	l[#l + 1] = {t = t, x = x, z = z, b = brg}
	while #l > M.MAX_LOOKS do table.remove(l, 1) end
	return true
end



function M.triangulate(e)
	local l = e.looks
	if #l < 3 then return nil end

	local x0, z0 = l[1].x, l[1].z
	local base = 0
	for _, k in ipairs(l) do base = math.max(base, math.sqrt((k.x - x0) ^ 2 + (k.z - z0) ^ 2)) end
	if base < M.MIN_BASELINE then return nil end

	local a11, a12, a22, b1, b2 = 0, 0, 0, 0, 0
	for _, k in ipairs(l) do
		local c, s = math.cos(k.b), math.sin(k.b)
		local m11, m12, m22 = 1 - c * c, -c * s, 1 - s * s
		a11, a12, a22 = a11 + m11, a12 + m12, a22 + m22
		b1 = b1 + m11 * k.x + m12 * k.z
		b2 = b2 + m12 * k.x + m22 * k.z
	end
	local det = a11 * a22 - a12 * a12
	if math.abs(det) < 1e-9 * #l * #l then return nil end
	local x = (a22 * b1 - a12 * b2) / det
	local z = (a11 * b2 - a12 * b1) / det

	local lo, hi, ss = 1e9, -1e9, 0
	local bref = nil
	for _, k in ipairs(l) do
		local c, s = math.cos(k.b), math.sin(k.b)
		local dx, dz = x - k.x, z - k.z
		if dx * c + dz * s < M.MIN_RANGE then return nil end
		local miss = -dx * s + dz * c
		ss = ss + miss * miss
		local b = math.atan2(dz, dx)
		bref = bref or b
		local rel = wrap_pi(b - bref)
		lo, hi = math.min(lo, rel), math.max(hi, rel)
	end
	local n = l[#l]
	local range = math.sqrt((x - n.x) ^ 2 + (z - n.z) ^ 2)
	if range < M.MIN_RANGE or range > M.MAX_RANGE then return nil end





	local w = math.min(M.SWING_N, #l)
	local acc, s_lo, s_hi = 0, 1e9, -1e9
	for i = 1, #l do
		acc = acc + wrap_pi(l[i].b - l[1].b)
		if i > w then acc = acc - wrap_pi(l[i - w].b - l[1].b) end
		if i >= w then s_lo, s_hi = math.min(s_lo, acc / w), math.max(s_hi, acc / w) end
	end
	local swing = s_hi - s_lo
	local spread = math.deg(math.min(hi - lo, swing))
	local resid = math.sqrt(ss / #l)
	local q = M.NONE
	if spread >= M.FIXED_DEG then q = M.FIXED elseif spread >= M.ROUGH_DEG then q = M.ROUGH end
	if q > M.NONE and resid > M.MAX_RESID * range then q = q - 1 end
	if resid > M.REJECT_RESID * range then q = M.NONE end
	if q == M.NONE then return nil end
	return {x = x, z = z, range = range, quality = q, spread = spread, resid = resid}
end






function M.world_angles(az, el, hdg, pitch, roll)
	local rel = -az
	local ch, sh, cp, sp, cr, sr = math.cos(hdg), math.sin(hdg), math.cos(pitch), math.sin(pitch), math.cos(roll), math.sin(roll)

	local F = {cp * ch, sp, cp * sh}
	local R0, U0 = {-sh, 0, ch}, {-sp * ch, cp, -sp * sh}
	local ce = math.cos(el)
	local a, b, c = ce * math.cos(rel), ce * math.sin(rel), math.sin(el)
	local d = {}
	for i = 1, 3 do
		local Ri = cr * R0[i] - sr * U0[i]
		local Ui = cr * U0[i] + sr * R0[i]
		d[i] = a * F[i] + b * Ri + c * Ui
	end
	return math.atan2(d[3], d[1]) % (2 * math.pi), math.asin(math.max(-1, math.min(1, d[2])))
end


function M.body_angles(brg, wel, hdg, pitch, roll)
	local ch, sh, cp, sp, cr, sr = math.cos(hdg), math.sin(hdg), math.cos(pitch), math.sin(pitch), math.cos(roll), math.sin(roll)
	local F = {cp * ch, sp, cp * sh}
	local R0, U0 = {-sh, 0, ch}, {-sp * ch, cp, -sp * sh}
	local cw = math.cos(wel)
	local d = {cw * math.cos(brg), math.sin(wel), cw * math.sin(brg)}
	local a, b, c = 0, 0, 0
	for i = 1, 3 do
		local Ri = cr * R0[i] - sr * U0[i]
		local Ui = cr * U0[i] + sr * R0[i]
		a, b, c = a + d[i] * F[i], b + d[i] * Ri, c + d[i] * Ui
	end
	return -math.atan2(b, a), math.asin(math.max(-1, math.min(1, c)))
end
M.LOOK_MAX_ATT = math.rad(30)




function M.by_elevation(height, depression)
	if not (height and depression) or height < M.ELEV_MIN_HEIGHT then return nil end
	if depression < math.rad(M.ELEV_MIN_DEG) then return nil end
	local r = height / math.tan(depression)
	if r > M.ELEV_MAX_RANGE then return nil end
	return r
end



function M.estimate(e, general_type)
	if general_type == 2 or general_type == 3 then
		local f = M.triangulate(e)
		if f then return f.range, f.quality, "TRI", f end
	end
	return 0, M.NONE, "", nil
end

return M
