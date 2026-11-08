


















dofile(LockOn_Options.script_path.."Displays/nav_geom.lua")

local W, G, A, C = WHITE, GREEN, AMBER, CYAN
local HS = 0.05
local LW = 0.007
local CW = TEXFONT_RECT_X * HS * TEXT_CAP_RATIO / TEXFONT_CAP

local function turner(p)
	return node({0, 0}, nil, {p}, {{"rotate_using_parameter", 0, NAV_ROT_GAIN}})
end
local function mover(px, py, parent)
	return node({0, 0}, parent, {px, py},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
end


local rose = node({0, 0}, nil, {"NAV_HDG_RAD"}, {{"rotate_using_parameter", 0, 1}})
local dashes = {}
local r1, r2 = NAV_R_ROSE - NAV_ROSE_DASH / 2, NAV_R_ROSE + NAV_ROSE_DASH / 2
for k = 0, 71 do
	if k % 6 ~= 0 then
		local a = math.rad(5 * k)
		dashes[#dashes + 1] = {r1 * math.sin(a), r1 * math.cos(a), r2 * math.sin(a), r2 * math.cos(a)}
	end
end
segments(dashes, 0.008, W, rose)
for k, s in ipairs(NAV_ROSE_LABELS) do
	text(s, {0, 0}, HS, W, "CenterCenter", mover(string.format("NAV_RL%02d_X", k), string.format("NAV_RL%02d_Y", k)))
end

local m1, m2 = NAV_R + 0.03, NAV_R + 0.075
segments({{m1, 0, m2, 0}, {-m1, 0, -m2, 0}, {0, -m1, 0, -m2}}, LW, W)



local _, ytop = LAD_PB.pos(18)
segments({{0, NAV_R + 0.03, 0, ytop - 0.075}}, LW, W)
SEG_PREFIX = "bandfill"
segments({{0, NAV_R + 0.03, 0, ytop - 0.075}}, LW, W, XF and XF.bands and XF.bands["0,1"])
SEG_PREFIX = nil

segments({{0, 0.055, 0, -0.045}, {-0.045, 0.012, 0.045, 0.012}, {-0.022, -0.035, 0.022, -0.035}}, LW, W)


local cmdv = {"NAV_CMD_V", 0.5, 1.5}
local cmd = turner("NAV_CMD_REL")
poly({{0, NAV_R_PTR_IN}, {0.035, NAV_R_PTR_OUT}, {-0.035, NAV_R_PTR_OUT}}, A, cmd, nil, cmdv, "cmd")


local tv = {"NAV_TCN_V", 0.5, 1.5}
local tcn = turner("NAV_TCN_REL")
local ci, co = NAV_R_PTR_IN, NAV_R_PTR_OUT
segments({{-0.035, ci, 0, co - 0.035}, {0, co - 0.035, 0.035, ci},
	{-0.035, ci + 0.035, 0, co}, {0, co, 0.035, ci + 0.035},
	{-0.015, -ci, -0.015, -co}, {0.015, -ci, 0.015, -co}}, 0.008, G, tcn, nil, tv)
local stn = mover("NAV_TCN_X", "NAV_TCN_Y")
circle(0.022, 0.007, G, stn, nil, 8, {tv, {"NAV_TCN_PV", 0.5, 1.5}})



local cv = {"NAV_CDI_V", 0.5, 1.5}
local devv = {cv, {"NAV_CDI_SHOW", 0.5, 1.5}}
local crs = turner("NAV_CRS_REL")
local DY, DH = NAV_R - 0.085, 0.035
segments({{0, NAV_R - 0.02, 0, DY + DH}, {0, DY - DH, 0, NAV_R - 0.17},
	{0, DY + DH, 0.02, DY}, {0.02, DY, 0, DY - DH}, {0, DY - DH, -0.02, DY}, {-0.02, DY, 0, DY + DH}},
	LW, C, crs, nil, cv)
segments({{0, -NAV_R + 0.02, 0, -NAV_R + 0.17}}, LW, C, crs, nil, devv)
for _, x in ipairs({-NAV_CDI_FULL, -NAV_CDI_FULL / 2, NAV_CDI_FULL / 2, NAV_CDI_FULL}) do
	circle(0.015, 0.005, C, crs, {x, 0}, 10, devv)
end
local bar = node({0, 0}, crs, {"NAV_CDI"}, {{"move_left_right_using_parameter", 0, S(1)}})
local half = NAV_CDI_LEN / 2
segments({{0, -half, 0, half}}, 0.010, C, bar, nil, devv)
poly({{0.09, 0.10}, {0.12, 0.05}, {0.06, 0.05}}, C, crs, nil, {devv[1], devv[2], {"NAV_TOFROM", 0.5, 1.5}}, "to")
poly({{0.09, -0.10}, {0.12, -0.05}, {0.06, -0.05}}, C, crs, nil, {devv[1], devv[2], {"NAV_TOFROM", -1.5, -0.5}}, "from")


for i = 1, NAV_MAX_SP do
	local pre = string.format("NAV_SP%02d_", i)
	local n = mover(pre.."X", pre.."Y")
	circle(0.016, 0.005, C, n, nil, 8, {pre.."V", 0.5, 1.5})
	poly({{-0.025, 0}, {0, 0.025}, {0.025, 0}, {0, -0.025}}, C, n, nil, {pre.."V", 1.5, 2.5}, "sp")
end


local function hms(x, y, rgba, ph, pm, ps, vis)
	text(nil, {x, y}, HS, rgba, "LeftCenter", nil, {ph, "%02.0f:"}, vis)
	text(nil, {x + 3 * CW, y}, HS, rgba, "LeftCenter", nil, {pm, "%02.0f:"}, vis)
	text(nil, {x + 6 * CW, y}, HS, rgba, "LeftCenter", nil, {ps, "%02.0f"}, vis)
end


local TX, TY = -0.78, -0.50
local ton = {"NAV_TCN_MODE", 0.5, 1.5}
text("TCN OFF", {TX, TY}, HS, G, "LeftCenter", nil, nil, {"NAV_TCN_MODE", -0.5, 0.5})
text(nil, {TX, TY}, HS, G, "LeftCenter", nil, {"NAV_TCN_TXT", "TCN %s"}, ton)
text(nil, {TX, TY - 0.075}, HS, G, "LeftCenter", nil, {"NAV_TCN_BRG", "%03.0f /"}, {ton, tv})
text(nil, {TX + 6 * CW, TY - 0.075}, HS, G, "LeftCenter", nil, {"NAV_TCN_RNG", "%.1f"}, {ton, tv})
hms(TX, TY - 0.15, G, "NAV_TCN_ETE_H", "NAV_TCN_ETE_M", "NAV_TCN_ETE_S", {ton, tv, {"NAV_TCN_ETE_V", 0.5, 1.5}})
text("NO STATION", {TX, TY - 0.075}, HS, G, "LeftCenter", nil, nil, {ton, {"NAV_TCN_V", -0.5, 0.5}})


local SX, SY = 0.40, -0.62
local sv = {"NAV_STPT_V", 0.5, 1.5}
text(nil, {SX, SY}, HS, C, "LeftCenter", nil, {"NAV_STPT", "STR %.0f"}, sv)
text(nil, {SX, SY - 0.075}, HS, C, "LeftCenter", nil, {"NAV_BRG", "%03.0f /"}, sv)
text(nil, {SX + 6 * CW, SY - 0.075}, HS, C, "LeftCenter", nil, {"NAV_RNG", "%.1f"}, sv)
hms(SX, SY - 0.15, C, "NAV_ETE_H", "NAV_ETE_M", "NAV_ETE_S", sv)
text("E", {SX + 9 * CW, SY - 0.15}, HS, C, "LeftCenter", nil, nil, sv)
text("STR ---", {SX, SY}, HS, C, "LeftCenter", nil, nil, {"NAV_STPT_V", -0.5, 0.5})


do
	local x, y = LAD_PB.legend_pos(1)
	text("CMD", {x, y + 0.065}, HS, A, "LeftCenter", nil, nil, cmdv)
	text("HDG", {x, y}, HS, A, "LeftCenter", nil, nil, cmdv)
	text(nil, {x, y - 0.065}, HS, A, "LeftCenter", nil, {"NAV_CMD_HDG", "%03.0f"}, cmdv)
end

do
	local _, y = LAD_PB.pos(2)
	for k, ch in ipairs({"H", "D", "G"}) do
		text(ch, {-0.91, y + (2 - k) * 0.06}, LAD_CHROME.LEG_H, W, "CenterCenter")
	end
end

do
	local x, y = LAD_PB.legend_pos(14)
	text("CRS", {x, y + 0.035}, LAD_CHROME.LEG_H, W, "RightCenter")
	text(nil, {x, y - 0.035}, LAD_CHROME.LEG_H, W, "RightCenter", nil, {"NAV_CRS", "%03.0f"}, cv)
	text("---", {x, y - 0.035}, LAD_CHROME.LEG_H, W, "RightCenter", nil, nil, {"NAV_CDI_V", -0.5, 0.5})
end



local EDGE_BAND = {T = "0,1", B = "0,-1", L = "-1,0", R = "1,0"}
local function box_at(n, w, h, vis)
	local x, y, e = LAD_PB.pos(n)
	rect(x - w, y - h, x + w, y + h, 0.006, W, XF and XF.bands and XF.bands[EDGE_BAND[e]], vis)
end

lad_legend(4, "INS")

lad_legend(18, "AUTO\nSEQ")
box_at(18, 0.085, 0.075, {"NAV_AUTOSEQ", 0.5, 1.5})

do
	local x17, y = LAD_PB.pos(17)
	local x16 = LAD_PB.pos(16)
	poly({{x17, y - 0.03}, {x17 + 0.03, y + 0.025}, {x17 - 0.03, y + 0.025}}, W, nil, nil, nil, "rdn")
	poly({{x16, y + 0.03}, {x16 + 0.03, y - 0.025}, {x16 - 0.03, y - 0.025}}, W, nil, nil, nil, "rup")
	local xm = (x16 + x17) / 2
	text("RNG", {xm, y + 0.035}, LAD_CHROME.LEG_H, W, "CenterCenter")
	text(nil, {xm, y - 0.035}, LAD_CHROME.LEG_H, W, "CenterCenter", nil, {"NAV_HSI_RNG", "%.0f"})
end

do
	local _, y = LAD_PB.pos(2)
	rect(-0.945, y - 0.095, -0.875, y + 0.095, 0.006, W, XF and XF.bands and XF.bands["-1,0"], {"NAV_STEER", 3.5, 4.5})
end

lad_legend(6, "TCN")
box_at(6, 0.075, 0.045, {"NAV_STEER", 1.5, 2.5})
lad_legend(7, "ILST")
box_at(7, 0.085, 0.045, {{"NAV_STEER", 2.5, 3.5}, {"NAV_ILS_SUB", 1.5, 2.5}})
lad_legend(8, "GT")
box_at(8, 0.06, 0.045, {"NAV_STEER", 4.5, 5.5})
lad_legend(19, "RTE")
box_at(19, 0.075, 0.045, {"NAV_STEER", 5.5, 6.5})
lad_legend(9, "ILSN")
box_at(9, 0.085, 0.045, {{"NAV_STEER", 2.5, 3.5}, {"NAV_ILS_SUB", 0.5, 1.5}})
lad_legend(10, "NAV")
box_at(10, 0.075, 0.045, {"NAV_STEER", 0.5, 1.5})
