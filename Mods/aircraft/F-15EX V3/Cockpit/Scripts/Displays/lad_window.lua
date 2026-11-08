










dofile(LockOn_Options.script_path.."Displays/common.lua")
dofile(LockOn_Options.script_path.."Displays/formats.lua")
dofile(LockOn_Options.script_path.."Displays/lad_layouts.lua")
SetScale(FOV)

POWER_VIS = {"DISP_PWR_LAD", 0.5, 1.5}

local n = LAD_WINDOW
local pre = string.format("LAD_W%d", n)

for c = 1, #LAD_LAYOUT.K[n] do
	local root = node({0, 0}, nil, {pre.."_X", pre.."_Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})


	local under = node({0, 0}, root, {pre.."_SZ", string.format("DISP_FMT_W%d", n)},
		{{"parameter_in_range", 0, c - 0.5, c + 0.5}, {"parameter_in_range", 1, 0.5, FMT_MAX + 0.5}})
	local bands = {}
	for hx = -1, 1 do
		for hy = -1, 1 do
			if hx ~= 0 or hy ~= 0 then
				local ctl = {}
				if hx ~= 0 then ctl[#ctl + 1] = {"move_left_right_using_parameter", 0, hx * S(1)} end
				if hy ~= 0 then ctl[#ctl + 1] = {"move_up_down_using_parameter", 1, hy * S(1)} end
				bands[hx..","..hy] = node({0, 0}, root, {pre.."_EX", pre.."_EY"}, ctl)
			end
		end
	end
	XF = {k = LAD_LAYOUT.K[n][c], root = root, under = under, bands = bands, band = LAD_LAYOUT.BAND}
	WINDOW_VIS = {pre.."_SZ", c - 0.5, c + 0.5}
	draw_formats(string.format("DISP_FMT_W%d", n))
	touch_mark(n, 0.03)
	XF, WINDOW_VIS = nil, nil
end




local fmt, own = string.format("DISP_FMT_W%d", n), LAD_FMT_OWN_SOI
local gates = own and {{fmt, -1e6, own - 0.5}, {fmt, own + 0.5, 1e6}} or {false}
for l = 1, #LAD_LAYOUT.LIST do
	local x0, x1, y0, y1 = LAD_LAYOUT.rect(l, n)
	if x0 then
		for _, g in ipairs(gates) do
			local vis = {{"LAD_LAYOUT", l - 0.5, l + 0.5}}
			if g then vis[2] = g end
			soi_frame(n, x0, x1, y0, y1, vis)
		end
	end
end
