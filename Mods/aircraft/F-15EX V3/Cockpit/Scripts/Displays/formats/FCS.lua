










local W, G = WHITE, GREEN
local RED = {235, 30, 30, 255}
local YEL = {245, 225, 40, 255}
local HS = 0.050
local SQ = 0.040
local SQP = 0.050


local function squares(x, y, n, vis)
	local list = {}
	for k = 0, n - 1 do
		local cx = x + SQ / 2 + k * SQP
		list[#list + 1] = {cx - SQ / 2, y, cx + SQ / 2, y}
	end
	return segments(list, SQ, G, nil, nil, vis)
end
local function dashes(x, y, from, n, vis)
	local list = {}
	for k = from, n - 1 do
		local cx = x + SQ / 2 + k * SQP
		list[#list + 1] = {cx - SQ / 3, y, cx + SQ / 3, y}
	end
	return segments(list, 0.008, W, nil, nil, vis)
end

local function channels(x, y, gate, fail)
	squares(x, y, 4, gate)
	dashes(x, y, 0, 4, fail)
end


text("ACE GN 50738", {-0.80, 0.93}, HS, W, "LeftCenter")
text("DETAIL", {0, 0.96}, HS, W, "CenterCenter")
text("BIT", {0, 0.895}, HS, W, "CenterCenter")
text(nil, {0.30, 0.93}, HS, W, "LeftCenter", nil, {"DISP_LAT_ASYM", "LAT ASYM %.0f"})


local ROWS = {0.78, 0.715, 0.65, 0.585}
local on = {"EFM_ELEC_AC", 0.5, 1.5}
local function block(xl, names)
	for i, name in ipairs(names) do
		text(name, {xl - 0.02, ROWS[i]}, HS, W, "RightCenter")
		if name == "ATT" then

			squares(xl, ROWS[i], 4, {on, {"NAV_INS", 1.5, 2.5}})
			squares(xl, ROWS[i], 1, {on, {"NAV_INS", -0.5, 1.5}})
			dashes(xl, ROWS[i], 1, 4, {on, {"NAV_INS", -0.5, 1.5}})
		else
			channels(xl, ROWS[i], on, {"EFM_ELEC_AC", -0.5, 0.5})
		end
	end
end
block(-0.55, {"GYRO", "ACCEL", "ATT"})
block(-0.07, {"AOA", "A/D", "COOL"})
block(0.44, {"PSTK", "RSTK", "PEDAL", "MISC"})


text(nil, {-0.78, 0.47}, HS, W, "LeftCenter", nil, {"DISP_TRIM_P", "PTRIM %.0f%%"})
text(nil, {-0.24, 0.47}, HS, W, "LeftCenter", nil, {"DISP_TRIM_R", "RTRIM %.0f%%"})
text(nil, {0.28, 0.47}, HS, W, "LeftCenter", nil, {"DISP_TRIM_Y", "YTRIM %.0f%%"})




local N = 8
local FILL = 0.032
local function scale(axis, c, a, b, lo, hi, zero, param)
	local function at(v) return a + (b - a) * (v - lo) / (hi - lo) end
	local function seg(p0, p1) if axis == "v" then return {c, p0, c, p1} else return {p0, c, p1, c} end end
	local function cross(p, half) if axis == "v" then return {c - half, p, c + half, p} else return {p, c - half, p, c + half} end end
	segments({seg(a, b), cross(a, 0.035), cross(b, 0.035)}, 0.008, RED)
	local z = at(zero)
	for side = -1, 1, 2 do
		local lim = side > 0 and hi or lo
		if lim ~= zero then
			for k = 1, N do
				local v0, v1 = zero + (lim - zero) * (k - 1) / N, zero + (lim - zero) * k / N
				local p0, p1 = at(v0), at(v1)
				local vis = side > 0 and {param, (v0 + v1) / 2, 1e9} or {param, -1e9, (v0 + v1) / 2}
				local q = axis == "v" and {{c - FILL / 2, p0}, {c + FILL / 2, p0}, {c + FILL / 2, p1}, {c - FILL / 2, p1}}
					or {{p0, c - FILL / 2}, {p1, c - FILL / 2}, {p1, c + FILL / 2}, {p0, c + FILL / 2}}
				poly(q, YEL, nil, nil, vis, "fcsfill")
			end
		end
	end

	local gain = (b - a) / (hi - lo)
	local m = node({0, 0}, nil, {param}, {{axis == "v" and "move_up_down_using_parameter" or "move_left_right_using_parameter", 0,
		S(gain)}})
	local q = {{-0.03, z - 0.006}, {0.03, z - 0.006}, {0.03, z + 0.006}, {-0.03, z + 0.006}}
	if axis == "v" then
		for _, v in ipairs(q) do v[1] = v[1] + c end
	else
		for _, v in ipairs(q) do v[1], v[2] = v[2], v[1] + c end
	end
	poly(q, YEL, m, nil, nil, "fcsptr")
end


local function aileron(side, x, label_x, val_x, val_align)
	text(side.." AILERON", {label_x, 0.33}, HS, W, "CenterCenter")
	scale("v", x, 0.27, -0.04, -25, 25, 0, "EFM_SURF_AIL_"..side)
	text(nil, {val_x, 0.13}, HS, W, val_align, nil, {"DISP_SURF_AIL_"..side, "%.0f"})
	channels(x - 2 * SQP + (SQP - SQ) / 2, -0.09, {"EFM_FBW_ROLL", 0.5, 1.5}, {"EFM_FBW_ROLL", -0.5, 0.5})
end
aileron("L", -0.60, -0.58, -0.66, "RightCenter")
aileron("R", 0.50, 0.48, 0.56, "LeftCenter")

local function flap(side, x, val_x, val_align)
	text(side.." FLAP", {x, 0.19}, HS, W, "CenterCenter")
	scale("v", x, 0.13, -0.11, 0, 1, 0, "EFM_FLAP_POS")
	text(nil, {val_x, 0.03}, HS, W, val_align, nil, {"DISP_FLAP_DEG", "%.0f"})
end
flap("L", -0.32, -0.26, "LeftCenter")
flap("R", 0.21, 0.15, "RightCenter")

local function stab(side, x, val_x, val_align)
	text(side.." STAB", {x + 0.02, -0.165}, HS, W, "CenterCenter")
	scale("v", x, -0.22, -0.56, -30, 30, 0, "EFM_SURF_STAB_"..side)
	text(nil, {val_x, -0.39}, HS, W, val_align, nil, {"DISP_SURF_STAB_"..side, "%.0f"})
	channels(x - 2 * SQP + (SQP - SQ) / 2, -0.62, {"EFM_FBW_PITCH", 0.5, 1.5}, {"EFM_FBW_PITCH", -0.5, 0.5})
end
stab("L", -0.56, -0.62, "RightCenter")
stab("R", 0.42, 0.48, "LeftCenter")

local function rudder(side, x0, x1)
	local cx = (x0 + x1) / 2
	text(side.." RUDDER", {cx, -0.40}, HS, W, "CenterCenter")
	scale("h", -0.49, x1, x0, -30, 30, 0, "EFM_SURF_RUD")
	text(nil, {cx, -0.56}, HS, W, "CenterCenter", nil, {"DISP_SURF_RUD", "%.0f"})
	channels(cx - 2 * SQP + (SQP - SQ) / 2, -0.63, {"EFM_FBW_YAW", 0.5, 1.5}, {"EFM_FBW_YAW", -0.5, 0.5})
end
rudder("L", -0.43, -0.15)
rudder("R", 0.01, 0.29)


text("L AOA", {-0.66, -0.86}, HS, W, "CenterCenter")
text(nil, {-0.66, -0.93}, HS, W, "CenterCenter", nil, {"DISP_AOA", "%.1f"})
text("R AOA", {0.48, -0.86}, HS, W, "CenterCenter")
text(nil, {0.48, -0.93}, HS, W, "CenterCenter", nil, {"DISP_AOA", "%.1f"})


for k, ch in ipairs({"E", "X", "E", "R"}) do
	text(ch, {-0.935, -0.52 - (k - 1) * 0.065}, HS, W, "CenterCenter")
end
