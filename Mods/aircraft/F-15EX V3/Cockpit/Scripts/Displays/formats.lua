







dofile(LockOn_Options.script_path.."Displays/lad_pb.lua")
dofile(LockOn_Options.script_path.."Displays/lad_layouts.lua")
FORMATS = {
	{id = 1, file = "ATTACK", legend = "ATTACK"},
	{id = 2, file = "ARMT", legend = "ARMT"},
	{id = 3, file = "TEWS", legend = "EW-P"},
	{id = 4, file = "ENG", legend = "ENG"},
	{id = 5, file = "SITP", legend = "SIT-P"},
	{id = 6, file = "HSI", legend = "HSI"},
	{id = 7, file = "ADI", legend = "ADI"},
	{id = 8, file = "FCS", legend = "FCS"},
	{id = 9, file = "BIT", legend = "BIT"},
	{id = 10, file = "DVR", legend = "DVR"},

	{id = 12, file = "TF", legend = "TF"},
	{id = 11, legend = "A/G RDR"}, {id = 13, legend = "TSD"}, {id = 14, legend = "TGT IR"},
	{id = 15, legend = "EVENT"}, {id = 16, legend = "IRST"}, {id = 17, legend = "HUD"}, {id = 18, legend = "PROG"},

	{id = 21, file = "IFF", legend = "IFF"},
	{id = 19, legend = "WIND MODEL"}, {id = 20, legend = "A/G DLVRY"},
	{id = 22, legend = "IMAGERY"}, {id = 23, legend = "DATA FRAME"}, {id = 24, legend = "OWS"},
	{id = 25, file = "LINK16", legend = "LINK 16"},
	{id = 26, legend = "SMRT WPNS"}, {id = 27, legend = "TEXT"},
	{id = 28, file = "HUDPROG", legend = "HUD PROG"}, {id = 29, legend = "MC DTM"},

	{id = 30, file = "KEYPAD", legend = "KEY PAD"},

	{id = 31, file = "INS", legend = "INS"},

	{id = 32, file = "AP", legend = "A/P"},

	{id = 33, file = "CMD", legend = "CMD"},


	{id = 34, file = "COMM", legend = "COMM"},


	{id = 35, file = "LIGHTS", legend = "LIGHTS"},
}














FMT_MAX = 35











LAD_CHROME = {
	LEG_RGBA = WHITE,
	LEG_H = 0.052,
}

local function lines(s)
	local out = {}
	for l in string.gmatch(s, "[^\n]+") do out[#out + 1] = l end
	return out
end


function lad_legend(n, s, vis, rgba)
	local x, y, align = LAD_PB.legend_pos(n)
	local L = lines(s)
	local h = LAD_CHROME.LEG_H
	local _, _, edge = LAD_PB.pos(n)
	for i, l in ipairs(L) do
		local dy = ((#L + 1) / 2 - i) * h * 1.25
		if edge == "R" and #L == 1 and #l <= 3 and n == LAD_PB_RCD then

			for k = 1, #l do
				text(l:sub(k, k), {LAD_PB.EDGE + 0.04, y + (2 - k) * h * 1.15}, h, rgba or LAD_CHROME.LEG_RGBA, "CenterCenter",
					nil, nil, vis)
			end
		else
			text(l, {x, y + dy}, h, rgba or LAD_CHROME.LEG_RGBA, align, nil, nil, vis)
		end
	end
end






LAD_CHROME.LEG_ADV = 0.56
LAD_CHROME.BOX_PAD = 0.022
local EDGE_BAND = {T = "0,1", B = "0,-1", L = "-1,0", R = "1,0"}
function legend_box(n, chars, n_lines, vis, w, rgba)
	local C = LAD_CHROME
	local x, y, align = LAD_PB.legend_pos(n)
	local _, _, edge = LAD_PB.pos(n)
	local tw, th = chars * C.LEG_ADV * C.LEG_H, ((n_lines - 1) * 1.25 + 1) * C.LEG_H
	local x0, x1
	if align == "LeftCenter" then x0, x1 = x, x + tw
	elseif align == "RightCenter" then x0, x1 = x - tw, x
	else x0, x1 = x - tw / 2, x + tw / 2 end
	local p = C.BOX_PAD
	SEG_PREFIX = "bandfill"
	local e = rect(x0 - p, y - th / 2 - p, x1 + p, y + th / 2 + p, w or 0.006, rgba or C.LEG_RGBA,
		XF and XF.bands and XF.bands[EDGE_BAND[edge]], vis)
	SEG_PREFIX = nil
	return e
end




local function value_vis(param, k, first, scale)
	local s, off = scale or 1, 1 - (first or 1)
	return {param, (k - 0.5 - off) / s, (k + 0.5 - off) / s}
end

function settings_title(s)
	text(s, {0, 0.70}, 0.075, GREEN, "CenterCenter")
end


function settings_switch(n, name, param, values, first)
	local x, y, align = LAD_PB.legend_pos(n)
	local dy = LAD_CHROME.LEG_H * 1.25 / 2
	text(name, {x, y + dy}, LAD_CHROME.LEG_H, WHITE, align)
	for k, v in ipairs(values) do
		text(v, {x, y - dy}, LAD_CHROME.LEG_H, WHITE, align, nil, nil, value_vis(param, k, first))
	end
end



SETTINGS_ROW = {X = 0.40, DY = 0.11, H = 0.05}
function settings_summary(rows, y0)
	local R = SETTINGS_ROW
	for i, r in ipairs(rows) do
		local y = y0 - (i - 1) * R.DY
		text(r[1], {-R.X, y}, R.H, GREEN, "LeftCenter")
		for k, v in ipairs(r[3]) do
			text(v, {R.X, y}, R.H, GREEN, "RightCenter", nil, nil, value_vis(r[2], k, r[4], r[5]))
		end
	end
	return y0 - #rows * R.DY
end





local function chrome(param)
	for _, f in ipairs(FORMATS) do
		if f.halo then
			FORMAT_VIS = {param, f.id - 0.5, f.id + 0.5}
			TEXT_HALO = "only"
			lad_legend(LAD_PB_MENU, "M")
			lad_legend(LAD_PB_RCD, "RCD")
			TEXT_HALO = nil
			local x, y = LAD_PB.pos(LAD_PB_RCD)
			rect(x + 0.005, y - 0.10, x + 0.075, y + 0.10, 0.006 + HALO_EDGE, HALO_RGBA, nil, {"DISP_RCD", 0.5, 1.5})
		end
	end
	FORMAT_VIS = {param, 0.5, FMT_MAX + 0.5}
	lad_legend(LAD_PB_MENU, "M")
	lad_legend(LAD_PB_RCD, "RCD")
	local x, y = LAD_PB.pos(LAD_PB_RCD)
	rect(x + 0.005, y - 0.10, x + 0.075, y + 0.10, 0.006, LAD_CHROME.LEG_RGBA, nil, {"DISP_RCD", 0.5, 1.5})
end


local function menu(param, id, items)
	FORMAT_VIS = {param, id - 0.5, id + 0.5}
	for n, it in pairs(items) do lad_legend(n, it[1]) end
	local x6, y6 = LAD_PB.pos(6)
	local x7 = LAD_PB.pos(7)
	local yb = y6 + 0.10
	segments({{x6 - 0.06, y6 + 0.04, x6 - 0.06, yb}, {x6 - 0.06, yb, x7 - 0.06, yb}}, 0.006, LAD_CHROME.LEG_RGBA)
	text("M/M", {x7 + 0.02, yb}, LAD_CHROME.LEG_H, LAD_CHROME.LEG_RGBA, "CenterCenter")
end



local function layout_menu(param)
	FORMAT_VIS = {param, LAD_MENU_LAYOUT - 0.5, LAD_MENU_LAYOUT + 0.5}
	local M = LAD_LAYOUT_MENU
	for k, l in ipairs(LAD_LAYOUT.LIST) do
		local x0, x1, y0, y1 = M.box(k)
		poly({{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}}, {38, 40, 44, 255}, nil, nil, nil, "laybox")
		for _, v in ipairs({{WHITE, {"LAD_LAYOUT", -1e9, k - 0.5}}, {WHITE, {"LAD_LAYOUT", k + 0.5, 1e9}},
				{GREEN, {"LAD_LAYOUT", k - 0.5, k + 0.5}}}) do
			rect(x0, y0, x1, y1, 0.012, v[1], nil, v[2])
			text(l.name, {(x0 + x1) / 2, (y0 + y1) / 2}, M.TEXT_H, v[1], "CenterCenter", nil, nil, v[2])
		end
	end
end


local function frame(f)
	text(f.legend, {0, 0.62}, 0.075, GREEN, "CenterCenter")
end


function draw_formats(param)
	chrome(param)
	for _, f in ipairs(FORMATS) do
		FORMAT_VIS = {param, f.id - 0.5, f.id + 0.5}
		if f.file or f.path then
			dofile(f.path or LockOn_Options.script_path.."Displays/formats/"..f.file..".lua")
			CLIP_LEVEL = nil
		else
			frame(f)
		end
	end
	menu(param, LAD_MENU1, LAD_MENU1_ITEMS)
	menu(param, LAD_MENU2, LAD_MENU2_ITEMS)
	layout_menu(param)
	FORMAT_VIS = nil
end
