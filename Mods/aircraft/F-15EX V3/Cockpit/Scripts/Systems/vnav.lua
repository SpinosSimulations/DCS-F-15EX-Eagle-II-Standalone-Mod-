











local V = {}

local DEG = math.pi / 180
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

V.MODES = {"PATH", "RTE", "TF"}
V.PATH, V.RTE, V.TF = 1, 2, 3


V.CLEARANCES_FT = {100, 200, 300, 400, 500, 1000}



V.SUBMODES = {"NORM", "ECCM", "WX1", "WX2", "LPI", "VLC"}
V.VLC, V.WX2, V.LPI = 6, 4, 5
function V.clearance_ok(sub, ft)
	if ft == 100 then return sub == V.VLC end
	if sub == V.WX2 then return ft >= 500 end
	return true
end

V.RIDES = {
	{name = "SOFT", nz_lo = 0.5, nz_hi = 2.0, dive = -6 * DEG},
	{name = "MED", nz_lo = 0.0, nz_hi = 3.0, dive = -9 * DEG},
	{name = "HARD", nz_lo = -0.5, nz_hi = 4.0, dive = -12 * DEG},
}
V.K = {
	path_gamma_max = 12 * DEG, path_gamma_min = -10 * DEG,
	path_level = 1 * DEG,
	rte_gamma_up = 8 * DEG, rte_gamma_dn = -6 * DEG,
	rte_dist_min = 2000,
	tf_gamma_max = 12 * DEG,
	tf_look_s = {1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 18, 22, 26, 30},
	tf_turn_max = 90 * DEG,
	tf_period = 0.1,
	tf_flyup_s = 4,
	tf_flyup_frac = 0.4,
	fail_climb = 8 * DEG, fail_s = 5,
}

function V.new()
	return {mode = 0, gamma_ref = 0, alt_ref = nil, tf_t = 1e9, tf_gamma = 0, tf_clear_m = nil, flyup = false,
		fail_t = nil, clr_i = 5, ride = 2, sub = 1, why = ""}
end

function V.clearance_ft(st) return V.CLEARANCES_FT[st.clr_i] end
function V.ride(st) return V.RIDES[st.ride] end

function V.set_clearance(st, ft)
	if not V.clearance_ok(st.sub or 1, ft) then return false end
	for i, c in ipairs(V.CLEARANCES_FT) do if c == ft then st.clr_i = i return true end end
	return false
end

function V.set_sub(st, sub)
	if not V.SUBMODES[sub] then return false end
	st.sub = sub
	while not V.clearance_ok(sub, V.clearance_ft(st)) and st.clr_i < #V.CLEARANCES_FT do st.clr_i = st.clr_i + 1 end
	return true
end


function V.engage(st, m, o, pod)
	if m == V.TF and not pod then return false, "no NAV pod" end
	st.mode, st.alt_ref, st.flyup, st.fail_t, st.tf_t, st.why = m, nil, false, nil, 1e9, ""
	if m == V.PATH then
		st.gamma_ref = clamp(o.gamma, V.K.path_gamma_min, V.K.path_gamma_max)
		if math.abs(st.gamma_ref) < V.K.path_level then st.gamma_ref, st.alt_ref = 0, o.h end
	elseif m == V.TF then
		st.tf_gamma = o.gamma
	end
	return true
end


local function tf_fail(st, why, o)
	st.mode, st.fail_t, st.why, st.flyup = V.PATH, 0, why, false
	st.gamma_ref, st.alt_ref = V.K.fail_climb, nil
end


local function ahead(o, t)
	local w = o.turn or 0
	if math.abs(w) < 1e-4 then
		local d = o.gs * t
		return o.x + d * math.cos(o.trk), o.z + d * math.sin(o.trk), d
	end
	local turn = clamp(w * t, -V.K.tf_turn_max, V.K.tf_turn_max)
	local r = o.gs / math.abs(w)
	local s = w > 0 and 1 or -1

	local t_arc = math.abs(turn / w)
	local x = o.x + r * (math.sin(o.trk + turn) - math.sin(o.trk)) * s
	local z = o.z - r * (math.cos(o.trk + turn) - math.cos(o.trk)) * s
	local rest = o.gs * (t - t_arc)
	x, z = x + rest * math.cos(o.trk + turn), z + rest * math.sin(o.trk + turn)
	return x, z, o.gs * t
end
V.ahead = ahead




local function tf_gamma(st, o, dt, ground, tfr)
	if tfr then
		if tfr.fail then return nil end
		if tfr.ready then st.tf_gamma, st.flyup, st.tf_clear_m = tfr.gamma, tfr.flyup, tfr.clr_m end
		return st.tf_gamma
	end
	st.tf_t = st.tf_t + dt
	if st.tf_t < V.K.tf_period then return st.tf_gamma end
	st.tf_t = 0
	local clr = V.clearance_ft(st) * 0.3048
	local r = V.ride(st)
	local h0 = ground(o.x, o.z)
	if not h0 then return nil end
	local need, minclr = -math.huge, math.huge
	for _, t in ipairs(V.K.tf_look_s) do
		local x, z, d = ahead(o, t)
		local hg = ground(x, z) or h0
		need = math.max(need, math.atan2(hg + clr - o.h, math.max(d, 50)))
		if t <= V.K.tf_flyup_s then minclr = math.min(minclr, o.h + o.v * t * math.sin(o.gamma) - hg) end
	end
	st.tf_clear_m = o.h - h0
	st.flyup = math.min(minclr, st.tf_clear_m) < V.K.tf_flyup_frac * clr
	st.tf_gamma = clamp(need, r.dive, V.K.tf_gamma_max)
	return st.tf_gamma
end

V.tf_compute = tf_gamma




function V.step(st, o, inp, dt, ground)
	local out = {v = false, fpa = 0, alt_v = false, alt_ft = 0, nz_v = false, nz_lo = 1, nz_hi = 1, l1 = "", l2 = ""}
	if st.mode == 0 then return out end
	if st.mode == V.TF then
		if not inp.pod then tf_fail(st, "NAV POD", o)
		else
			local g = tf_gamma(st, o, dt, ground, inp.tfr)
			if not g then tf_fail(st, "NO TERRAIN", o) end
		end
	end
	local K = V.K
	if st.mode == V.PATH then
		if st.fail_t then
			st.fail_t = st.fail_t + dt
			if st.fail_t >= K.fail_s then
				st.fail_t, st.gamma_ref, st.alt_ref = nil, 0, o.h
			end
		end
		out.v, out.fpa = true, st.gamma_ref / DEG
		if st.alt_ref then out.alt_v, out.alt_ft = true, st.alt_ref / 0.3048 end
		out.l1 = st.fail_t and ("TF FAIL - "..st.why) or "VNAV PATH"
		out.l2 = st.alt_ref and string.format("HOLD ALT %d FT", math.floor(st.alt_ref / 0.3048 / 10 + 0.5) * 10)
			or string.format("HOLD FPA %+.1f", st.gamma_ref / DEG)
	elseif st.mode == V.RTE then
		out.v, out.l1 = true, "VNAV RTE"
		local wp = inp.wp
		if wp and wp.alt and wp.alt > 0 then
			st.alt_ref = nil
			local g = clamp(math.atan2(wp.alt - o.h, math.max(wp.dist or 0, K.rte_dist_min)), K.rte_gamma_dn, K.rte_gamma_up)
			out.fpa, out.alt_v, out.alt_ft = g / DEG, true, wp.alt / 0.3048
			out.l2 = string.format("STPT ALT %d FT", math.floor(wp.alt / 0.3048 / 10 + 0.5) * 10)
		else
			st.alt_ref = st.alt_ref or o.h
			out.fpa, out.alt_v, out.alt_ft = 0, true, st.alt_ref / 0.3048
			out.l2 = string.format("NO STPT ALT  HOLD %d FT", math.floor(st.alt_ref / 0.3048 / 10 + 0.5) * 10)
		end
	elseif st.mode == V.TF then
		local r = V.ride(st)
		out.v, out.fpa = true, (st.flyup and K.tf_gamma_max or st.tf_gamma) / DEG
		out.nz_v, out.nz_lo, out.nz_hi = true, r.nz_lo, r.nz_hi
		if st.flyup then out.nz_lo = 1 end
		out.l1 = st.flyup and "VNAV TF  FLY UP" or "VNAV TF"
		out.l2 = string.format("SET %d %s  CLR %s", V.clearance_ft(st), r.name,
			st.tf_clear_m and string.format("%d", math.floor(st.tf_clear_m / 0.3048 + 0.5)) or "---")
	end
	return out
end

return V
