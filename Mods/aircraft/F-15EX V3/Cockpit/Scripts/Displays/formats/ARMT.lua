







local CYAN = {0, 220, 255, 255}
local OUTLINE = {80, 230, 170, 255}
local SEL_FILL = {120, 235, 140, 255}
local DIM = {150, 150, 150, 255}
local H = 0.055
local HS = 0.045
local LW = 0.008




local side = {{0.24, 0.58}, {0.62, -0.14}, {0.54, -0.44}, {0.24, -0.46}}
local list = {}
for k = 1, #side - 1 do
	local a, b = side[k], side[k + 1]
	list[#list + 1] = {a[1], a[2], b[1], b[2]}
	list[#list + 1] = {-a[1], a[2], -b[1], b[2]}
end
segments(list, LW, OUTLINE)




local POS, WING = {}, {}
for i, r in ipairs((dofile(LockOn_Options.script_path.."Systems/stations.lua").current())) do
	POS[i], WING[i] = {r.x, r.y}, r.wing
end






local INV_W = 6
local U = H * TEXT_CAP_RATIO / TEXFONT_CAP
local CW, LH = TEXFONT_RECT_X * U, TEXFONT_RECT_Y * U
local LINE_Y = {0.035, -0.035, -0.035 - LH}
local HALF = INV_W * CW / 2
local MARGIN = 0.012









local OV_TOP, OV_BOT, OV_X = 1.7 * U, 1.4 * U, 0.4 * U
local function box_round_lines(cx, cy, ys, rgba, vis)
	local x0, x1 = cx - HALF - MARGIN, cx + HALF + MARGIN
	local function rect_fill(a, b, c, d)
		if b - a > 1e-6 and d - c > 1e-6 then poly({{a, c}, {b, c}, {b, d}, {a, d}}, rgba, nil, nil, vis, "sel") end
	end
	local top, bot = cy + ys[1] + LH / 2, cy + ys[#ys] - LH / 2
	rect_fill(x0, cx - HALF + OV_X, bot - MARGIN, top + MARGIN)
	rect_fill(cx + HALF - OV_X, x1, bot - MARGIN, top + MARGIN)
	rect_fill(cx - HALF, cx + HALF, top - OV_TOP, top + MARGIN)
	rect_fill(cx - HALF, cx + HALF, bot - MARGIN, bot + OV_BOT)
	for k = 1, #ys - 1 do
		rect_fill(cx - HALF, cx + HALF, cy + ys[k + 1] + LH / 2 - OV_TOP, cy + ys[k] - LH / 2 + OV_BOT)
	end
end
local function inv_text(value, pos, rgba, param, vis)
	return tex_text(value, pos, H * TEXT_CAP_RATIO, rgba, "CenterCenter", nil, param, vis, "medium_inv")
end


local function station_text(i, pos, h, rgba, param, on)
	local sel = "SMS_SEL_PYLON"
	text(nil, pos, h, rgba, "CenterCenter", nil, param, {on, {sel, -1e9, i - 0.5}})
	text(nil, pos, h, rgba, "CenterCenter", nil, param, {on, {sel, i + 0.5, 1e9}})
end
for i, p in ipairs(POS) do
	local pre = string.format("SMS_P%02d_", i)
	local on = {pre.."V", 0.5, 1.5}
	local selv = {"SMS_SEL_PYLON", i - 0.5, i + 0.5}
	box_round_lines(p[1], p[2], LINE_Y, SEL_FILL, selv)
	inv_text(nil, {p[1], p[2] + LINE_Y[1]}, SEL_FILL, {"SMS_SEL_ITOP", "%s"}, selv)
	inv_text(nil, {p[1], p[2] + LINE_Y[2]}, SEL_FILL, {"SMS_SEL_ICODE", "%s"}, selv)
	inv_text(nil, {p[1], p[2] + LINE_Y[3]}, SEL_FILL, {"SMS_SEL_IN", "%s"}, selv)
	station_text(i, {p[1], p[2] + LINE_Y[1]}, H, WHITE, {pre.."TOP", "%s"}, on)
	station_text(i, {p[1], p[2] + LINE_Y[2]}, H, WHITE, {pre.."CODE", "%s"}, on)
	station_text(i, {p[1], p[2] + LINE_Y[3]}, HS, DIM, {pre.."N", "x%.0f"}, {pre.."N", 1.5, 99})
	if WING[i] then text("PYLN", {p[1], p[2]}, H, WHITE, "CenterCenter", nil, nil, {pre.."V", -0.5, 0.5}) end
end



text(nil, {-0.88, 0.86}, HS, WHITE, "LeftCenter", nil, {"SMS_GUN", "GUN %.0f"})
text(nil, {0.88, 0.86}, HS, WHITE, "RightCenter", nil, {"SMS_CHF", "CHF %.0f"}, {"SMS_CHF", -0.5, 1e9})
text("CHF --", {0.88, 0.86}, HS, WHITE, "RightCenter", nil, nil, {"SMS_CHF", -1e9, -0.5})
text(nil, {0.88, 0.79}, HS, WHITE, "RightCenter", nil, {"SMS_FLR", "FLR %.0f"}, {"SMS_FLR", -0.5, 1e9})
text("FLR --", {0.88, 0.79}, HS, WHITE, "RightCenter", nil, nil, {"SMS_FLR", -1e9, -0.5})




local AX, AY = 0.64, 0.30
box_round_lines(AX, AY, {0}, GREEN, {"SMS_ARM", 0.5, 1.5})
inv_text("_ARM__", {AX, AY}, GREEN, nil, {"SMS_ARM", 0.5, 1.5})
text("SAFE", {AX, AY}, H, WHITE, "CenterCenter", nil, nil, {"SMS_ARM", -0.5, 0.5})

text("COOL", {AX, AY - 0.13}, H, WHITE, "CenterCenter", nil, nil, {"SMS_COOL", 0.5, 2.5})
rect(AX - 0.09, AY - 0.17, AX + 0.09, AY - 0.09, 0.007, WHITE, nil, {"SMS_COOL", 1.5, 2.5})


rect(-0.26, -0.90, 0.26, -0.81, 0.008, CYAN)
text(nil, {0, -0.855}, H, CYAN, "CenterCenter", nil, {"SMS_SEL", "%s"})


text("A/A", {-0.94, 0.20}, HS, WHITE, "LeftCenter")
text("ARMT", {-0.94, -0.60}, HS, DIM, "LeftCenter")












