














dofile(LockOn_Options.script_path.."Displays/tf_geom.lua")
local T = TF_SCOPE
local C = GREEN
local DIM = {0, 115, 0, 255}
local H = LAD_CHROME.LEG_H
local DY = H * 1.25 / 2
local W = 0.006
local ON = {"NAV_TF_STATE", 1.5, 2.5}

settings_title("TF")


local function num_switch(n, name, param)
	local x, y, align = LAD_PB.legend_pos(n)
	text(name, {x, y + DY}, H, WHITE, align)
	text(nil, {x, y - DY}, H, WHITE, align, nil, param)
end
num_switch(1, "CLR", {"NAV_TF_CLR", "%.0f FT"})
settings_switch(2, "RIDE", "NAV_TF_RIDE", {"SOFT", "MED", "HARD"})
settings_switch(3, "MODE", "NAV_TF_SUB", TF_SUBMODES)
num_switch(4, "FREQ", {"NAV_TF_FREQ", "F%.0f"})
do
	local x, y, align = LAD_PB.legend_pos(15)
	text("A/P", {x, y + DY}, H, WHITE, align)
	text("TF CPL", {x, y - DY}, H, WHITE, align)
end
legend_box(15, #"TF CPL", 2, {"NAV_VNAV_MODE", 2.5, 3.5}, W)
lad_legend(14, "A/P")


do
	local cx, cy = T.CUE_X, T.CUE_Y
	circle(0.018, W, C, nil, {cx, cy}, 16, ON)
	segments({{cx - 0.075, cy, cx - 0.018, cy}, {cx + 0.018, cy, cx + 0.075, cy}, {cx, cy + 0.018, cx, cy + 0.050},
		{cx - 0.075, cy, cx - 0.075, cy - 0.025}, {cx + 0.075, cy, cx + 0.075, cy - 0.025}}, W, C, nil, nil, ON)
	local box = node({cx, cy}, nil, {"NAV_TF_CUE"}, {{"move_up_down_using_parameter", 0, S(1)}})
	rect(-0.035, 0.035, 0.035, 0.060, W, C, box, ON)
end

text(nil, {-0.24, 0.60}, H, C, "LeftCenter", nil, {"NAV_TF_RALT", "R%.0f"})
text(nil, {-0.24, 0.53}, H, C, "LeftCenter", nil, {"NAV_TF_GS", "G%.0f"})
text("MEA", {0.02, 0.60}, H, C, "LeftCenter", nil, nil, {"NAV_TF_MEA_V", 0.5, 1.5})
text(nil, {0.02, 0.53}, H, C, "LeftCenter", nil, {"NAV_TF_MEA", "%.0f"}, {"NAV_TF_MEA_V", 0.5, 1.5})

do
	local x, y, s = T.ANT_X, T.ANT_Y, T.ANT_STEP
	local list = {{x - 2 * s, y, x + 2 * s, y}}
	for _, k in ipairs({-2, -1, 1, 2}) do list[#list + 1] = {x + k * s, y, x + k * s, y + 0.025} end
	segments(list, W, C, nil, nil, ON)
	local dot = node({x, y}, nil, {"NAV_TF_ANT"}, {{"move_left_right_using_parameter", 0, S(2 * s)}})
	segments({{0, 0, 0, 0.030}}, W, C, dot, nil, ON)
	circle(0.014, W, C, dot, {0, 0.044}, 12, ON)
end


do
	local list = {{T.X0, T.Y_SCALE, T.X1, T.Y_SCALE}}
	for _, tk in ipairs(T.TICKS) do
		local x = T.x(tk[1])
		list[#list + 1] = {x, T.Y_SCALE, x, T.Y_SCALE + 0.030}
		text(tostring(tk[1]), {x, T.Y_SCALE - 0.055}, H, C, "CenterCenter")
	end
	segments(list, W, C)
end

segments({{T.X0, T.Y_FV, T.X1, T.Y_FV}}, W, C, nil, nil, ON)



local function col_node(k, f)
	local p = string.format("NAV_TF_%s_%02d", f, k)
	return node({T.col_x(k), 0}, nil, {p}, {{"move_up_down_using_parameter", 0, S(1)}}), p
end
for k = 1, T.N do
	local raw, pr = col_node(k, "RAW")
	segments({{0, 0, 0, -T.RAW_H}}, T.RAW_W, DIM, raw, nil, T.on_plot(pr))
end
for k = 1, T.N do
	local mv, p = col_node(k, "SYN")
	local rt = node({0, 0}, mv, {string.format("NAV_TF_SYNR_%02d", k)}, {{"rotate_using_parameter", 0, 1}})
	segments({{-T.DASH / 2, 0, T.DASH / 2, 0}}, 0.010, C, rt, nil, T.on_plot(p))
	if k % T.EVERY == 0 then
		for _, f in ipairs({"ZCL", "OWL"}) do
			local d, pd = col_node(k, f)
			segments({{-T.DOT / 2, 0, T.DOT / 2, 0}}, T.DOT, C, d, nil, T.on_plot(pd))
		end
	end
end


text("TF RDR STBY", {0, 0.12}, 0.060, C, "CenterCenter", nil, nil, {"NAV_TF_STATE", 0.5, 1.5})
text("TF RDR OFF", {0, 0.16}, 0.060, C, "CenterCenter", nil, nil, {"NAV_TF_STATE", -0.5, 0.5})
text("NO NAV POD", {0, 0.06}, 0.050, AMBER, "CenterCenter", nil, nil, {"NAV_TF_STATE", -0.5, 0.5})
text("FLY UP", {0, 0.30}, 0.075, C, "CenterCenter", nil, nil, {ON, {"NAV_TF_FLYUP", 0.5, 1.5}})
text("TF FAIL", {0.40, 0.30}, 0.060, AMBER, "CenterCenter", nil, nil, {"NAV_TF_FAIL", 0.5, 1.5})
