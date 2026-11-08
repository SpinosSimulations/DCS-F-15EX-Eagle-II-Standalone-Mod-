






local C = GREEN
local H = LAD_CHROME.LEG_H
local DY = H * 1.25 / 2

text("A/P", {0, 0.70}, 0.075, C, "CenterCenter")
text(nil, {0, 0.45}, 0.085, WHITE, "CenterCenter", nil, {"AP_STATUS", "%s"})
text(nil, {0, 0.15}, 0.06, C, "CenterCenter", nil, {"AP_INFO1", "%s"})
text(nil, {0, 0.02}, 0.06, C, "CenterCenter", nil, {"AP_INFO2", "%s"})



lad_legend(1, "A/P")
do
	local _, y = LAD_PB.pos(1)
	rect(-0.950, y - 0.045, -0.810, y + 0.045, 0.006, WHITE, XF and XF.bands and XF.bands["-1,0"],
		{"EFM_AP_ON", 0.5, 1.5})
end

local function two_lines(n, l1, l2, sel)
	local x, y = LAD_PB.legend_pos(n)
	text(l1, {x, y + DY}, H, WHITE, "LeftCenter")
	if type(l2) == "table" then
		text(nil, {x, y - DY}, H, WHITE, "LeftCenter", nil, l2)
	else
		text(l2, {x, y - DY}, H, WHITE, "LeftCenter")
	end
	if sel then text("*", {x + 0.13, y + DY}, H, WHITE, "LeftCenter", nil, nil, {sel, 0.5, 1.5}) end
end
two_lines(2, "STR", {"AP_STR_SRC", "%s"}, "EFM_AP_SEL_STR")
two_lines(3, "ALT", "HOLD", "EFM_AP_SEL_ALT")

two_lines(4, "HDG", {"NAV_HDG_SEL", "%03.0f"})






text(nil, {0, -0.13}, 0.06, WHITE, "CenterCenter", nil, {"NAV_VNAV_L1", "%s"})
text(nil, {0, -0.23}, 0.055, C, "CenterCenter", nil, {"NAV_VNAV_L2", "%s"})

local function bottom(n, l1, p2, vis)
	local x, y = LAD_PB.pos(n)
	text(l1, {x, p2 and (y + DY) or y}, H, WHITE, "CenterCenter")
	if type(p2) == "table" then text(nil, {x, y - DY}, H, WHITE, "CenterCenter", nil, p2) end
	if vis then rect(x - 0.075, y - 0.045, x + 0.075, y + 0.045, 0.006, WHITE, XF and XF.bands and XF.bands["0,-1"], vis) end
	return x, y
end
bottom(6, "PATH", nil, {"NAV_VNAV_MODE", 0.5, 1.5})
bottom(7, "RTE", nil, {"NAV_VNAV_MODE", 1.5, 2.5})
do
	local x, y = bottom(8, "TF", nil, {"NAV_VNAV_MODE", 2.5, 3.5})


	text("NO POD", {x, y + 0.078}, H, WHITE, "CenterCenter", XF and XF.bands and XF.bands["0,-1"], nil,
		{"NAV_TF_POD", -0.5, 0.5})
end
bottom(9, "CLR", {"NAV_TF_CLR", "%.0f"})
bottom(10, "RIDE", {"NAV_TF_RIDE_TXT", "%s"})
lad_legend(13, "RTN")
