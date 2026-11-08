

























local AA = dofile(LockOn_Options.script_path.."Systems/aa_math.lua")
local HM = dofile(LockOn_Options.script_path.."Systems/hmd_math.lua")
local MDB

local dev = GetSelf()
local update_time_step = 0.01
make_default_activity(update_time_step)
local sensor_data = get_base_data()

local M_PER_NM = 1852.0
local M_PER_FT = 0.3048
local KT_PER_MPS = 1.943844
local MR = 1000.0
local LOG_PERIOD = 2.0
local BOX_LOG_PERIOD = 0.1

dofile(LockOn_Options.script_path.."Displays/aa_geom.lua")
dofile(LockOn_Options.script_path.."Displays/hud_glass.lua")
local G = HUDAA_GEOM










local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local function str(h) local v = h:get() return v == nil and "" or tostring(v) end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

local IN = {fam = param("SMS_FAM"), sel = param("SMS_SEL"), gun = param("SMS_GUN"), dt = param("RDR_DT_TRK"),
	dt_ok = param("RDR_DT_OK"),
	link = param("MSLLINK_STATE"), trk_count = param("TRK_COUNT"), mode = param("RADAR_MODE"),
	stt_r = param("RADAR_STT_RANGE"), stt_az = param("RADAR_STT_AZIMUTH"), stt_el = param("RADAR_STT_ELEVATION"),
	tas = param("EFM_TAS_KT"), mach = param("EFM_MACH"), nz = param("EFM_NZ"), alt = param("DISP_ALT_FT"),
	stamp = param("TRK_STAMP"), own_alt = param("RDR_OWN_ALT"), frame = param("HMD_FRAME"), clsid = param("SMS_SEL_CLSID"), wst = param("SMS_SEL_WST"),
	skr_bx = param("HMD_SKR_BX"), skr_by = param("HMD_SKR_BY"), skr_bz = param("HMD_SKR_BZ"), skr_bv = param("HMD_SKR_BV"),
	skr_tone = param("HMD_SKR_TONE"), uncage = param("SRM_UNCAGE"), p_dps = param("EFM_P_DPS"), q_dps = param("EFM_Q_DPS"), r_dps = param("EFM_R_DPS"),
	alpha = param("EFM_VV_ALPHA_DEG"), beta = param("EFM_VV_BETA_DEG"), rng_nm = param("RDR_RANGE_NM")}
local TRK_MAX = 32
local trk = {}
for i = 1, TRK_MAX do
	trk[i] = {}

	for _, f in ipairs({"NUM", "RANGE", "BRG", "ELEV", "CLOSURE", "STT", "HDG", "AZR", "ELR", "HDGR",
			"DX", "DY", "DZ", "VX", "VY", "VZ", "ACX", "ACY", "ACZ"}) do
		trk[i][f] = param(string.format("TRK_%02d_%s", i, f))
	end
end


local DL_MAX, DL_FIRST = 32, 101
local ZERO = {get = function() return 0 end}
local dl_count = param("DL_COUNT")
local dl = {}
for i = 1, DL_MAX do
	dl[i] = {AZR = ZERO, ELR = ZERO, HDGR = ZERO, ACX = ZERO, ACY = ZERO, ACZ = ZERO}
	for _, f in ipairs({"NUM", "RANGE", "BRG", "ELEV", "CLOSURE", "HDG", "DX", "DY", "DZ", "VX", "VY", "VZ"}) do
		dl[i][f] = param(string.format("DL_%02d_%s", i, f))
	end
end




local GDIR = {on = param("GUN_DIR_ON")}
for _, f in ipairs({"V", "NUM", "STT", "INRNG", "U", "W", "UR", "WR", "TOF", "RANGE"}) do GDIR[f] = param("GUN_DIR_"..f) end

local OUT = {}
for _, n in ipairs({"TD_X", "TD_Y", "TD_V", "TD_TUP", "TD_OFF", "INRNG", "RS_V", "RS_MAX", "RC_Y", "CLO", "RNG", "DLZ_V",
		"AERO_Y", "OPT_Y", "PI_Y", "MNVR_Y", "TR_Y", "MIN_Y", "WEZ_AERO", "WEZ_OPT", "WEZ_PI", "WEZ_MNVR", "WEZ_TR",
		"WEZ_MIN", "TTI", "TTI_V", "NE_LO", "NE_HI", "SHOOT_V", "SHOOT", "ASE_V", "ASE_R", "DOT_X", "DOT_Y", "ASP", "ASP_V", "TGT_ALT", "TGT_ASP", "SKR_V",
		"GUN_V", "RET_V", "RET_X", "RET_Y", "RB", "PIP_V", "WPN", "WPN_V", "AMMO", "AMMO_V", "TGT_V", "TGT_BX",
		"TGT_BY", "TGT_BZ", "TGT_STT", "SKR_X", "SKR_Y", "SKR_TONE", "TD_DL"}) do
	OUT[n] = param("HUDAA_"..n)
end

local WEZ_OUT = {aero = "AERO_Y", opt = "OPT_Y", pi = "PI_Y", mnvr = "MNVR_Y", tr = "TR_Y", min = "MIN_Y"}

local GD = {}
for s, side in ipairs({"L", "R"}) do
	GD[s] = {}
	for k = 1, G.FUNNEL_DASHES do
		GD[s][k] = {X = param(string.format("HUDAA_GD%s%d_X", side, k)), Y = param(string.format("HUDAA_GD%s%d_Y", side, k)),
			A = param(string.format("HUDAA_GD%s%d_A", side, k)), V = param(string.format("HUDAA_GD%s%d_V", side, k))}
	end
end
local PS = {}
for k = 1, #AA.SEARCH_PIPPERS do
	PS[k] = {X = param(string.format("HUDAA_PS%d_X", k)), Y = param(string.format("HUDAA_PS%d_Y", k)),
		V = param(string.format("HUDAA_PS%d_V", k))}
end

local S = {now = 0, t_log = 0, target = nil, src = "", stamp = nil, t0 = 0, hdg0 = 0, age = 0, clock = nil,
	att = nil, rate = {0, 0, 0}, t_box = 0, gun_att = nil, body = {0, 0, 0}, nz = 1, efm_rates = false}





local BODY_TAU = 0.06
local BODY_WIN = 0.1
local BODY_MAX = math.rad(120)







local MM = param("MASTER_MODE")
local AA_ONLY = {"WPN_V", "AMMO_V", "RS_V", "DLZ_V", "SHOOT_V", "SHOOT", "TTI_V", "ASE_V", "ASP_V", "SKR_V", "GUN_V",
	"RET_V", "PIP_V"}
local function aa_gated(h)
	return {set = function(_, v) h:set(S.aa and v or 0) end, get = function() return h:get() end}
end
S.aa = true
for _, n in ipairs(AA_ONLY) do OUT[n] = aa_gated(OUT[n]) end
for _, side in ipairs(GD) do for _, g in ipairs(side) do g.V = aa_gated(g.V) end end

local function dcs_log(s)
	if log and log.info then tostring("F15EX HUDAA "..s) else tostring("F15EX HUDAA "..s) end
end






local STREAM_JUMP = 50.0
local RET_TAU = 0.05





local RET_TAU_TWS = 0.2
local RET_HOLD = 0.3



local RET_BLINK_S = 0.25
local function ret_y(y_mr)
	if y_mr >= G.FUNNEL_Y_MIN then return y_mr, 1 end
	return G.FUNNEL_Y_MIN, (S.now % RET_BLINK_S) < RET_BLINK_S / 2 and 1 or 0
end
S.stream = AA.stream_new()

local function own_world()
	if type(sensor_data.getSelfCoordinates) ~= "function" or type(sensor_data.getSelfVelocity) ~= "function" then return nil end
	local x, y, z = sensor_data.getSelfCoordinates()
	local vx, vy, vz = sensor_data.getSelfVelocity()
	if type(x) ~= "number" or type(vx) ~= "number" then return nil end
	return {x, y or 0, z or 0}, {vx, vy or 0, vz or 0}
end





local OWN_HIST = 0.6
S.hist = {}
local function own_record()
	local p, v = own_world()
	S.own_p, S.own_v = p, v
	if not p then S.hist = {} return end
	local h = S.hist
	if h[#h] and h[#h].t >= S.now then return end
	h[#h + 1] = {t = S.now, p = p, v = v}
	while #h > 2 and h[1].t < S.now - OWN_HIST do table.remove(h, 1) end
end

local function own_at(tq)
	local h = S.hist
	if #h == 0 then return nil end
	if tq <= h[1].t then return h[1].p, h[1].v end
	for i = #h, 2, -1 do
		local a, b = h[i - 1], h[i]
		if tq >= a.t then
			local k = b.t > a.t and math.min(1, (tq - a.t) / (b.t - a.t)) or 1
			local function mix(u, w) return {u[1] + k * (w[1] - u[1]), u[2] + k * (w[2] - u[2]), u[3] + k * (w[3] - u[3])} end
			return mix(a.p, b.p), mix(a.v, b.v)
		end
	end
	return h[#h].p, h[#h].v
end


local function stream_step(hdg, pitch, roll)
	local pos, vel = own_world()
	local st = S.stream
	if not pos then
		if S.stream_src ~= "lcos" then
			S.stream_src = "lcos"
			dcs_log(string.format("%.2f gun: no world position, lead-computing funnel", S.now))
		end
		return nil
	end
	if S.stream_src ~= "stream" then
		S.stream_src = "stream"
		dcs_log(string.format("%.2f gun: historical funnel (bullet stream)", S.now))
	end
	local dt = S.stream_t and S.now - S.stream_t or 0
	local last = S.stream_pos
	if dt < 0 or dt > 0.5 or (last and math.sqrt((pos[1] - last[1] - vel[1] * dt) ^ 2 + (pos[2] - last[2] - vel[2] * dt) ^ 2
			+ (pos[3] - last[3] - vel[3] * dt) ^ 2) > STREAM_JUMP) then
		AA.stream_reset(st)
		dt = 0
	end
	S.stream_t, S.stream_pos = S.now, pos
	AA.stream_update(st, S.now, dt, pos, vel, -hdg, pitch, roll)
	return pos, vel
end











local EXTRAP_MAX = 0.3
local function own_ccw_hdg()
	local v = type(sensor_data.getHeading) == "function" and sensor_data.getHeading() or 0
	return type(v) == "number" and v or 0
end
local function wrap_pi(a) return (a + math.pi) % (2 * math.pi) - math.pi end


local function data_age()
	local age = S.now - (S.stamp or S.now)
	local clock = age >= -0.005 and age <= EXTRAP_MAX
	if clock ~= S.clock then
		S.clock = clock
		dcs_log(string.format("%.2f track data age %.3f s: %s", S.now, age,
			clock and "from TRK_STAMP" or "TRK_STAMP's clock differs, from its arrival"))
	end
	S.age = clamp(clock and age or (S.now - S.t0), 0, EXTRAP_MAX)
end

local function extrapolate(t, s, hdg_now)
	local dt = S.age
	local dx, dy, dz = num(s.DX), num(s.DY), num(s.DZ)
	if dx ~= 0 or dy ~= 0 or dz ~= 0 then
		local vx, vy, vz = num(s.VX), num(s.VY), num(s.VZ)
		local ax, ay, az = num(s.ACX), num(s.ACY), num(s.ACZ)
		local yaw_then = t.brg - math.atan2(dz, dx)
		local op, ov = own_at(S.now - dt)
		if op and S.own_p then


			local disp, vt, acc = AA.turn_state({vx + ov[1], vy + ov[2], vz + ov[3]}, {ax, ay, az}, dt)
			dx = dx + disp[1] - (S.own_p[1] - op[1])
			dy = dy + disp[2] - (S.own_p[2] - op[2])
			dz = dz + disp[3] - (S.own_p[3] - op[3])
			t.vt, t.acc = vt, acc
			vx, vy, vz = vt[1] - S.own_v[1], vt[2] - S.own_v[2], vt[3] - S.own_v[3]
		else
			dx, dy, dz = dx + vx * dt, dy + vy * dt, dz + vz * dt
			t.acc = {ax, ay, az}
		end
		local h = math.sqrt(dx * dx + dz * dz)
		t.range = math.sqrt(h * h + dy * dy)
		t.closure = t.range > 1e-6 and -(dx * vx + dy * vy + dz * vz) / t.range or 0
		t.brg = wrap_pi(math.atan2(dz, dx) + hdg_now)
		t.elev = math.atan2(dy, h)
		t.hdg = t.hdg + math.deg(wrap_pi(hdg_now - yaw_then) + num(s.HDGR) * dt)
		t.world = true
		t.d, t.v, t.w = {dx, dy, dz}, {vx, vy, vz}, num(s.HDGR)
		return t
	end
	local dpsi = wrap_pi(hdg_now - S.hdg0)
	t.range = math.max(0, t.range - t.closure * dt)
	t.brg = wrap_pi(t.brg + num(s.AZR) * dt + dpsi)
	t.elev = t.elev + num(s.ELR) * dt
	t.hdg = t.hdg + math.deg(dpsi + num(s.HDGR) * dt)
	return t
end






local OWN_LEAD_EXTRA = 0.0
local RATE_TAU = 0.03
local RATE_MAX = math.rad(400)
local function own_attitude()
	local hdg, pitch, roll = own_ccw_hdg(), sensor_data.getPitch(), sensor_data.getRoll()
	local a = S.att
	if a and S.now > a.t then
		local dt = S.now - a.t
		local d = {wrap_pi(hdg - a.hdg) / dt, (pitch - a.pitch) / dt, wrap_pi(roll - a.roll) / dt}
		local k = math.min(1, dt / RATE_TAU)
		for i = 1, 3 do
			S.rate[i] = math.abs(d[i]) > RATE_MAX and 0 or S.rate[i] + k * (d[i] - S.rate[i])
		end
	end
	S.att = {t = S.now, hdg = hdg, pitch = pitch, roll = roll}
	local frame = num(IN.frame)
	local lead = clamp((frame > 0.004 and frame < 0.1) and frame or 1 / 60, 0, 0.1) + OWN_LEAD_EXTRA
	S.lead = lead
	return hdg, pitch, roll, wrap_pi(hdg + S.rate[1] * lead), clamp(pitch + S.rate[2] * lead, -math.pi / 2, math.pi / 2),
		wrap_pi(roll + S.rate[3] * lead)
end



local function find_target(hdg_now, pitch, roll)
	local dt = math.floor(num(IN.dt) + 0.5)
	local stt_trk = nil
	if num(IN.link) >= 1 then
		local n = math.min(math.floor(num(IN.trk_count) + 0.5), TRK_MAX)
		for i = 1, n do
			local s = trk[i]
			local number = math.floor(num(s.NUM) + 0.5)
			if number > 0 then
				local t = extrapolate({range = num(s.RANGE), brg = num(s.BRG), elev = num(s.ELEV),
					closure = num(s.CLOSURE), hdg = num(s.HDG)}, s, hdg_now)
				t.stt = num(s.STT) == 1
				t.number = number
				if dt ~= 0 and number == dt then t.src = "DT" return t end
				if num(s.STT) == 1 then t.src = "STT TRK" stt_trk = t end
			end
		end
	end
	if stt_trk then return stt_trk end


	if dt >= DL_FIRST and num(IN.link) >= 1 then
		for i = 1, math.min(math.floor(num(dl_count) + 0.5), DL_MAX) do
			local s = dl[i]
			if math.floor(num(s.NUM) + 0.5) == dt then
				local t = extrapolate({range = num(s.RANGE), brg = num(s.BRG), elev = num(s.ELEV),
					closure = num(s.CLOSURE), hdg = num(s.HDG)}, s, hdg_now)
				t.src, t.dl, t.number = "DL DT", true, dt
				return t
			end
		end
	end



	if math.floor(num(IN.mode) + 0.5) == 3 and num(IN.stt_r) > 0 then
		local brg, elev = HM.level_dir(num(IN.stt_az), num(IN.stt_el), pitch or 0, roll or 0)
		return {range = num(IN.stt_r), brg = brg, elev = elev, closure = 0, src = "STT", stt = true}
	end
	return nil
end


local function missile_code()
	local _, _, code = string.find(str(IN.sel), "^%a+ ([%w%-]+)")
	return code
end




local function missile_db()
	if not MDB then MDB = dofile(LockOn_Options.script_path.."Systems/missile_lookup.lua") end
	return MDB
end


local function selected_missile()
	local clsid = str(IN.clsid)
	local wst = string.match(str(IN.wst), "^w(.+)$")
	if clsid ~= S.dlz_clsid or wst ~= S.dlz_wst then
		S.dlz_clsid, S.dlz_wst, S.dlz_e = clsid, wst, nil
		if clsid ~= "" then
			local ok, e, why = pcall(function() return missile_db().lookup(clsid, wst) end)
			if ok then S.dlz_e = e else why = tostring(e) end
			local e = S.dlz_e
			dcs_log(string.format("%.2f DLZ %s: %s", S.now, clsid, e and string.format("ModelData of %s (%s, by %s, Rmin %s m)",
				e.name, e.md and "ED's DLZ" or "ModelData not ED's 58: our reading", tostring(e.how), tostring(e.d_min))
				or ("estimate ("..tostring(why)..")")))
		end
	end
	return S.dlz_e
end

local function y_of(range_m, scale_nm)
	return G.RS_BOT + clamp(range_m / (scale_nm * M_PER_NM), 0, 1) * (G.RS_TOP - G.RS_BOT)
end

local function hide(list) for _, n in ipairs(list) do OUT[n]:set(0) end end

function post_initialize()
	for _, h in pairs(OUT) do h:set(0) end
	for _, n in ipairs({"WPN", "TGT_ALT", "TGT_ASP"}) do OUT[n]:set("") end
	for _, side in ipairs(GD) do for _, g in ipairs(side) do g.X:set(0) g.Y:set(0) g.A:set(0) g.V:set(0) end end
	for _, p in ipairs(PS) do p.X:set(0) p.Y:set(0) end
	local f = {}
	for _, n in ipairs({"getPitch", "getRoll"}) do f[#f + 1] = n..(type(sensor_data[n]) == "function" and "" or " MISSING") end
	dcs_log("up; base data: "..table.concat(f, " "))
end

function SetCommand(command, value)
end



local SEL_ACT = {p = param("SMS_SEL_ACT_M"), clsid = nil}
local function selected_active()
	local clsid = str(IN.clsid)
	if clsid == SEL_ACT.clsid then return end
	SEL_ACT.clsid = clsid
	local d
	if clsid ~= "" then
		local ok, r = pcall(function() return missile_db().active_dist(clsid) end)
		if ok then d = r else dcs_log("active distance "..clsid..": "..tostring(r)) end
	end
	SEL_ACT.p:set(d or 0)
end

function update()
	S.now = get_model_time()
	local mm = num(MM)
	S.aa = mm < 0.5 or math.abs(mm - 1) < 0.5
	selected_active()
	local stamp = num(IN.stamp)
	if stamp ~= S.stamp then S.stamp, S.t0, S.hdg0 = stamp, S.now, own_ccw_hdg() end
	own_record()
	data_age()

	local hdg, pitch, roll, hdg_p, pitch_p, roll_p = own_attitude()
	do
		local step = math.max(S.now - (S.gun_t or S.now), 0)
		S.gun_t = S.now
		local k = math.min(1, step / BODY_TAU)
		local e = {math.rad(num(IN.p_dps)), math.rad(num(IN.q_dps)), math.rad(num(IN.r_dps))}
		if not S.efm_rates and (e[1] ~= 0 or e[2] ~= 0 or e[3] ~= 0) then
			S.efm_rates = true
			dcs_log(string.format("%.2f gun: body rates from the EFM", S.now))
		end
		local w
		if S.efm_rates then
			w = e
		else
			local g = S.gun_att
			if g and S.now - g.t >= BODY_WIN then
				w = {AA.body_rates(g.h, g.p, g.r, -hdg, pitch, roll, S.now - g.t)}
				S.gun_att = nil
			end
			if not S.gun_att then S.gun_att = {t = S.now, h = -hdg, p = pitch, r = roll} end
			if w then k = math.min(1, BODY_WIN / BODY_TAU) end
		end
		if w then
			for i = 1, 3 do
				if math.abs(w[i]) <= BODY_MAX then S.body[i] = S.body[i] + k * (w[i] - S.body[i]) end
			end
		end
		S.nz = S.nz + math.min(1, step / BODY_TAU) * (num(IN.nz) - S.nz)
	end
	local fam = str(IN.fam)
	local t = find_target(hdg_p, pitch_p, roll_p)



	OUT.WPN:set(AA.weapon_text(str(IN.sel)))
	local missile = fam == "MRM" or fam == "SRM" or fam == "LRM"
	OUT.WPN_V:set(missile and 1 or 0)
	OUT.AMMO:set(math.max(0, math.floor(num(IN.gun) + 0.5)))
	OUT.AMMO_V:set(fam == "GUN" and 1 or 0)


	local az, el
	if t then
		az, el = AA.body_angles(t.brg, t.elev, pitch_p, roll_p)



		local ang, dir = AA.hud_polar(t.brg, t.elev, pitch_p, roll_p)
		local r = ang * MR
		local edge = AA.glass_r(HUD_STOP_MR, dir, G.TD_EDGE, G.TD_EDGE_BELOW)
		local off = r > edge
		r = math.min(r, edge)
		OUT.TD_X:set(r * math.cos(dir))
		OUT.TD_Y:set(r * math.sin(dir))
		local flash_on = (S.now % G.TD_FLASH) < G.TD_FLASH / 2
		OUT.TD_V:set(off and (flash_on and 2 or 3) or 1)
		OUT.TD_TUP:set((off and math.sin(dir) < 0) and 1 or 0)

		OUT.TD_OFF:set(math.floor(math.deg(ang) + 0.5))

		local bx, by, bz = AA.body_vector(t.brg, t.elev, pitch_p, roll_p)
		OUT.TGT_BX:set(bx) OUT.TGT_BY:set(by) OUT.TGT_BZ:set(bz) OUT.TGT_V:set(1)
		OUT.TGT_STT:set(t.stt and 1 or 0)
		OUT.TD_DL:set(t.dl and 1 or 0)
	else
		OUT.TD_V:set(0)
		OUT.TGT_V:set(0)
		OUT.TGT_STT:set(0)
		OUT.TD_DL:set(0)
	end









	local code = str(IN.clsid) ~= "" and missile_code() or nil
	local asp_a, asp_side, asp_txt
	if t and t.hdg then asp_a, asp_side, asp_txt = AA.aspect(t.brg, t.hdg) end
	local msl = missile and selected_missile() or nil
	local tas = num(IN.tas) / KT_PER_MPS
	local own_los = t and tas * AA.body_vector(t.brg, t.elev, pitch_p, roll_p) or 0
	local pos, vel = own_world()

	local fx, fy, vb = 0, 0, 0
	if vel then
		vb = wrap_pi(math.atan2(vel[3], vel[1]) + hdg_p)
		fx, fy = AA.body_angles(vb, math.atan2(vel[2], math.sqrt(vel[1] * vel[1] + vel[3] * vel[3])), pitch_p, roll_p)
	end
	S.dlz_src = nil





	local ASE_OUT = 1.5
	local function ase_allow(aero, range)
		local f = aero > 0 and clamp((ASE_OUT * aero - range) / ((ASE_OUT - 1) * aero), 0, 1) or 0
		return math.rad(G.ASE_A_MIN + f * (G.ASE_A_FULL - G.ASE_A_MIN))
	end
	local z, fb, err_x, err_y, allow
	if t and msl and msl.md and t.world and vel then
		local vt = {t.v[1] + vel[1], t.v[2] + vel[2], t.v[3] + vel[3]}

		z = AA.wez_ed(msl.md, msl.d_min or AA.DLZ_RMIN_DEFAULT, pos[2] + t.d[2] / 2, vel, vt, t.d, t.range)
		if z then
			S.dlz_src = msl.name..", ED's DLZ"

			local gx, gy = AA.body_angles(wrap_pi(vb + z.lead), t.elev, pitch_p, roll_p)
			err_x, err_y, allow = gx - fx, gy - fy, ase_allow(z.aero, t.range)
		end
	elseif t and (msl or (missile and code)) then
		local rmax, rne, rmin
		if msl then


			local away
			if t.hdg then away = (own_los - t.closure) * 3.6 end
			local alt_m = num(IN.own_alt) > 0 and num(IN.own_alt) or num(IN.alt) * M_PER_FT
			rmax, rne, rmin = AA.dlz_model(msl.dlz, msl.d_min, alt_m, tas * 3.6, away, asp_a)
			S.dlz_src = msl.name..", our reading"
		else
			rmax, rne, rmin = AA.dlz(code, num(IN.alt), num(IN.mach), t.closure * KT_PER_MPS, str(IN.fam))
			S.dlz_src = rmax and "estimate"
		end
		if rmax then

			fb = {rmax, rne, rmin}
			err_x, err_y = az - fx, el - fy
			z = AA.wez(rmax, rne, rmin, nil)
			allow = ase_allow(z.aero, t.range)
		end
	end





	local ase_r, steer, dot_x, dot_y
	if t and z and allow then
		local want = math.max(allow, math.rad(G.ASE_A_MIN))
		local step = math.max(S.now - (S.ase_t or S.now), 0)
		S.ase_a = S.ase_a and (S.ase_a + (want - S.ase_a) * math.min(1, step / G.ASE_TAU)) or want
		local a = S.ase_a
		ase_r = G.ASE_MIN + clamp((math.deg(a) - G.ASE_A_MIN) / (G.ASE_A_FULL - G.ASE_A_MIN), 0, 1) * (G.ASE_MAX - G.ASE_MIN)
		steer = math.sqrt(err_x * err_x + err_y * err_y) / a
		dot_x, dot_y = err_x / a * ase_r, err_y / a * ase_r
		if fb then z = AA.wez(fb[1], fb[2], fb[3], steer) end
	else
		S.ase_a = nil
	end
	S.ase_t = S.now
	S.ase_r, S.steer = ase_r, steer
	S.wez = z
	if t then


		local rs = num(IN.rng_nm)
		local scale = rs > 0 and rs or AA.range_scale(t.range, z and z.aero)
		local function y_cue(r) return G.RS_BOT + math.max(r / (scale * M_PER_NM), 0) * (G.RS_TOP - G.RS_BOT) end
		OUT.RS_MAX:set(scale)
		OUT.RC_Y:set(y_of(t.range, scale))
		OUT.CLO:set(math.floor(t.closure * KT_PER_MPS + 0.5))
		OUT.RNG:set(math.floor(t.range / M_PER_NM * 10 + 0.5) / 10)
		OUT.RS_V:set(1)
		local tgt_ft = AA.track_alt_ft(num(IN.own_alt), t.range, t.elev)
		S.altf = S.altf or AA.alt_filter()
		OUT.TGT_ALT:set(S.altf.text(t.number or t.src, tgt_ft, S.now))
		OUT.TGT_ASP:set(asp_txt or "")
		if z then
			for k, n in pairs(WEZ_OUT) do
				OUT[n]:set(y_cue(z[k]))
				OUT["WEZ_"..k:upper()]:set(z[k])
			end
			local piece = (G.RS_TOP - G.RS_BOT) / G.NE_PIECES
			OUT.NE_LO:set((y_of(z.min, scale) - G.RS_BOT) / piece)
			OUT.NE_HI:set((y_of(z.tr, scale) - G.RS_BOT) / piece)
			OUT.DLZ_V:set(1)



			local in_zone = t.range <= z.aero and t.range >= z.min
			local in_range = in_zone and (not t.dl or num(IN.dt_ok) == 1)
			local shoot = in_range and steer and steer <= 1
			OUT.SHOOT_V:set((shoot and (S.now % 0.5) < 0.3) and 1 or 0)



			local full = ase_r and ase_r >= G.ASE_MAX - 1
			OUT.SHOOT:set((shoot and full) and 1 or 0)
			OUT.INRNG:set((in_zone and not t.dl) and 1 or 0)
			local tti = AA.prelaunch_tti(t.range, z.aero, t.closure, own_los)
			OUT.TTI:set(tti and math.min(999, math.floor(tti + 0.5)) or 0)
			OUT.TTI_V:set(tti and 1 or 0)
		else
			hide({"DLZ_V", "SHOOT_V", "SHOOT", "INRNG", "TTI_V"})
		end
	else
		hide({"RS_V", "DLZ_V", "SHOOT_V", "SHOOT", "INRNG", "TTI_V"})
		OUT.TGT_ALT:set("")
		OUT.TGT_ASP:set("")
	end
	if ase_r then
		OUT.ASE_R:set(ase_r)
		local lim = G.ASE_MAX + 10
		OUT.DOT_X:set(clamp(dot_x, -lim, lim))
		OUT.DOT_Y:set(clamp(dot_y, -lim, lim))
		OUT.ASE_V:set(1)


		OUT.ASP:set(asp_a and -math.rad(asp_a) * asp_side or 0)
		OUT.ASP_V:set(asp_a and 1 or 0)
	else
		OUT.ASE_V:set(0)
		OUT.ASP_V:set(0)
	end



	local sv, sx, sy, stone = 0, 0, 0, 0
	if fam == "SRM" then
		sv = 2
		if num(IN.skr_bv) == 1 then
			local ang, dir = AA.body_polar(num(IN.skr_bx), num(IN.skr_by), num(IN.skr_bz))
			local r = ang * MR
			if r <= AA.glass_r(HUD_STOP_MR, dir, num(IN.uncage) == 1 and G.SEEKER_UNC_R or G.SEEKER_R) then
				sx, sy = r * math.cos(dir), r * math.sin(dir)
				stone = num(IN.skr_tone) == 1 and 1 or 0
			else
				sv = 1
			end
		elseif t and num(OUT.TD_V) == 1 then
			sx, sy = num(OUT.TD_X), num(OUT.TD_Y)
		elseif t then
			sv = 0
		end
	end
	OUT.SKR_V:set(sv)
	OUT.SKR_X:set(sx)
	OUT.SKR_Y:set(sy)
	OUT.SKR_TONE:set(stone)


	GDIR.on:set(fam == "GUN" and 1 or 0)
	if fam == "GUN" then
		local v = num(IN.tas) / KT_PER_MPS
		local nz = S.nz
		local gopt = {p = S.body[1], q = S.body[2], r = S.body[3], alt_m = num(IN.alt) * M_PER_FT,
			alpha = math.rad(num(IN.alpha)), beta = math.rad(num(IN.beta))}
		local pos, vel = stream_step(hdg, pitch, roll)


		local function at(ranges, fill)
			local out = {}
			if pos then
				local l = S.lead or 0
				out = AA.stream_funnel(S.stream, ranges, {pos[1] + vel[1] * l, pos[2] + vel[2] * l, pos[3] + vel[3] * l},
					-hdg_p, pitch_p, roll_p)
			end
			if fill then
				local lc
				for k = 1, #ranges do
					if not out[k] then
						lc = lc or AA.funnel(v, nz, pitch, roll, ranges, gopt)
						out[k] = lc[k]
					end
				end
			end
			return out
		end
		local ret = t and t.range <= G.GUN_TRACK_M

		local L, R = {}, {}
		if not ret then L, R = AA.funnel_dashes(at(AA.FUNNEL_RANGES, not pos), G.FUNNEL_DASH_STEP, G.FUNNEL_DASHES) end
		for s, side in ipairs({L, R}) do
			for k, g in ipairs(GD[s]) do
				local d = side[k]
				if d and d[2] >= G.FUNNEL_Y_MIN then
					g.X:set(d[1]) g.Y:set(d[2]) g.A:set(d[3]) g.V:set(1)
				else
					g.V:set(0)
				end
			end
		end


		local gnum = math.floor(num(GDIR.NUM) + 0.5)
		local dll = ret and num(GDIR.V) == 1 and ((t.number and gnum == t.number) or
			(t.stt and not t.number and gnum == 0 and num(GDIR.STT) == 1))
		if dll then

			local l = S.lead or 0
			local u, w = num(GDIR.U) + num(GDIR.UR) * l, num(GDIR.W) + num(GDIR.WR) * l
			local cr, sr = math.cos(roll_p), math.sin(roll_p)
			if S.ret_src ~= "dll" then
				dcs_log(string.format("%.2f gun: director in the DLL on %s%s%s", S.now, t.src,
					num(GDIR.STT) == 1 and " (STT)" or " (TWS)", num(GDIR.INRNG) == 1 and "" or ", out of range"))
			end
			S.ret_src, S.ret_u, S.ret_t = "dll", nil, nil
			OUT.RET_X:set((u * cr - w * sr) * MR)
			local yy, vv = ret_y((u * sr + w * cr) * MR)
			OUT.RET_Y:set(yy)
			OUT.RB:set(t.range / M_PER_FT / 1000)
			OUT.RET_V:set(vv)
			OUT.PIP_V:set(0)
		elseif ret then


			local x, y
			if pos and t.d then

				local vrel = t.vt and {t.vt[1] - vel[1], t.vt[2] - vel[2], t.vt[3] - vel[3]} or t.v
				x, y = AA.director(t.d, vrel, vel, t.w, -hdg_p, pitch_p, roll_p, num(IN.alt) * M_PER_FT, t.acc)
			end
			local fresh = S.ret_t and S.now - S.ret_t < 0.2
			if x then
				if S.ret_src ~= "director" then dcs_log(string.format("%.2f gun: director reticle on %s%s", S.now, t.src,
					t.stt and " (STT)" or " (TWS)")) end
				S.ret_src, S.dir_t = "director", S.now
			elseif fresh and S.ret_src == "director" and S.now - (S.dir_t or -1e9) < RET_HOLD then

			else
				local p = at({math.max(t.range, AA.FUNNEL_RANGES[1])}, true)[1]
				x, y = p.x, p.y
				if S.ret_src ~= "funnel" then dcs_log(string.format("%.2f gun: reticle on the funnel (%s)", S.now, t.src)) end
				S.ret_src = "funnel"
			end



			local cr, sr = math.cos(roll_p), math.sin(roll_p)
			local dtr = fresh and math.max(S.now - S.ret_t, 0) or 0
			if fresh and S.ret_u then
				S.ret_u, S.ret_w = S.ret_u + S.ret_du * dtr, S.ret_w + S.ret_dw * dtr
			end
			if x then
				local u, w = x * cr + y * sr, -x * sr + y * cr
				if fresh and S.ret_u and dtr > 1e-4 then
					local a = 1 - math.exp(-dtr / (t.stt and RET_TAU or RET_TAU_TWS))
					local b = a * a / (2 - a)
					local ru, rw = u - S.ret_u, w - S.ret_w
					S.ret_u, S.ret_w = S.ret_u + a * ru, S.ret_w + a * rw
					S.ret_du, S.ret_dw = S.ret_du + b * ru / dtr, S.ret_dw + b * rw / dtr
				elseif not (fresh and S.ret_u) then
					S.ret_u, S.ret_w, S.ret_du, S.ret_dw = u, w, 0, 0
				end
			else
				S.ret_du, S.ret_dw = S.ret_du or 0, S.ret_dw or 0
			end
			S.ret_t = S.now
			local rx, ry = S.ret_u * cr - S.ret_w * sr, S.ret_u * sr + S.ret_w * cr
			OUT.RET_X:set(rx * MR)
			local yy, vv = ret_y(ry * MR)
			OUT.RET_Y:set(yy)
			OUT.RB:set(t.range / M_PER_FT / 1000)
			OUT.RET_V:set(vv)
			OUT.PIP_V:set(0)
		else



			local pp = at(AA.SEARCH_PIPPERS, not pos)
			for k = 1, #AA.SEARCH_PIPPERS do
				local p = pp[k]
				if p and p.y * MR < G.FUNNEL_Y_MIN then p = nil end
				if p then
					PS[k].X:set(p.x * MR)
					PS[k].Y:set(p.y * MR)
				end
				PS[k].V:set(p and 1 or 0)
			end
			OUT.RET_V:set(0)
			OUT.PIP_V:set(1)
		end
		OUT.GUN_V:set(1)
	else
		if S.stream_t then AA.stream_reset(S.stream) S.stream_t, S.stream_pos = nil, nil end
		hide({"GUN_V", "RET_V", "PIP_V"})
	end

	S.t_log = S.t_log + update_time_step
	local src = t and t.src or ""
	if src ~= S.src then
		dcs_log(string.format("%.2f target %s -> %s", S.now, S.src == "" and "none" or S.src, src == "" and "none" or src))
		S.src = src
	end


	if t and t.stt and S.now - S.t_box >= BOX_LOG_PERIOD - 1e-9 then
		S.t_box = S.now
		dcs_log(string.format("BOX %.2f %s %.0f m az %+.2f el %+.2f deg age %.3f %s lead %.3f rates y %+.1f p %+.1f r %+.1f deg/s",
			S.now, t.src, t.range, math.deg(az), math.deg(el), S.age, t.world and "W" or "B", S.lead,
			math.deg(S.rate[1]), math.deg(S.rate[2]), math.deg(S.rate[3])))
	end
	if S.t_log >= LOG_PERIOD - 1e-9 then
		S.t_log = 0
		if t then
			dcs_log(string.format("%.1f %s %s %.1f nm brg %+.1f el %+.1f -> hud az %+.1f el %+.1f deg, pitch %+.1f roll %+.1f, "
				.."closure %.0f kt, aspect %s%s", S.now, fam, t.src, t.range / M_PER_NM, math.deg(t.brg), math.deg(t.elev),
				math.deg(az), math.deg(el), math.deg(pitch), math.deg(roll), t.closure * KT_PER_MPS, asp_txt or "-",
				S.wez and string.format(", %s WEZ aero %.1f opt %.1f pi %.1f mnvr %.1f tr %.1f min %.1f nm (%s), "
					.."lead %+.1f deg, ASE %.1f deg %.0f mr, steer %.2f, scale %d nm",
					tostring(code), S.wez.aero / M_PER_NM, S.wez.opt / M_PER_NM, S.wez.pi / M_PER_NM, S.wez.mnvr / M_PER_NM,
					S.wez.tr / M_PER_NM, S.wez.min / M_PER_NM, tostring(S.dlz_src), math.deg(S.wez.lead or 0),
					math.deg(S.ase_a or 0), S.ase_r or 0, S.steer or -1, num(OUT.RS_MAX)) or ""))
		end
	end
end




need_to_be_closed = false
