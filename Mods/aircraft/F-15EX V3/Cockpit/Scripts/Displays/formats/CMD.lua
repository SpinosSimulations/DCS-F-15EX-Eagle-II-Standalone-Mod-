








dofile(LockOn_Options.script_path.."Displays/cmd_page.lua")
local CM = dofile(LockOn_Options.script_path.."Systems/cmds.lua")
local P = CMD_PAGE
local C = GREEN
local H = 0.055
local LH = LAD_CHROME.LEG_H
local DY = LH * 1.25 / 2

text("CMD PROGRAMS", {0, 0.72}, 0.07, C, "CenterCenter")

for _, name in ipairs(CM.ORDER) do
	local id = CM.PROGRAMS[name].id
	text("PROGRAM "..name, {0, 0.58}, 0.06, WHITE, "CenterCenter", nil, nil, {"CMD_ED_PROG", id - 0.5, id + 0.5})
end
text("OPTIONS", {0, -0.33}, 0.06, WHITE, "CenterCenter")


local FMT = {"%.0f", "%.0f", "%.0f", "%.1f S", "%.0f", "%.1f S", "%.1f S", "%.0f"}
for i, f in ipairs(CM.FIELDS) do
	local y = P.ROW_Y[i]
	text(f.name, {P.LABEL_X, y}, H, C, "LeftCenter")
	if f.key == "auto_lock" then
		text("NO", {P.VALUE_X, y}, H, WHITE, "RightCenter", nil, nil, {"CMD_V"..i, -0.5, 0.5})
		text("YES", {P.VALUE_X, y}, H, WHITE, "RightCenter", nil, nil, {"CMD_V"..i, 0.5, 1.5})
	else
		text(nil, {P.VALUE_X, y}, H, WHITE, "RightCenter", nil, {"CMD_V"..i, FMT[i]})
	end

	rect(P.BOX_X[1], y - P.ROW_H / 2, P.BOX_X[2], y + P.ROW_H / 2, 0.006, C, nil, {"CMD_ED_ROW", i - 0.5, i + 0.5})
end

text(nil, {P.LABEL_X, P.TOTAL_Y}, H, C, "LeftCenter", nil, {"CMD_TOT_C", "TOTAL %.0f CHF"})
text(nil, {0.05, P.TOTAL_Y}, H, C, "LeftCenter", nil, {"CMD_TOT_F", "%.0f FLR"})
text(nil, {P.VALUE_X, P.TOTAL_Y}, H, C, "RightCenter", nil, {"CMD_TOT_T", "%.1f S"})


for k, name in ipairs(CM.ORDER) do
	local n = P.PB_PROG[k]
	lad_legend(n, name)
	local _, y = LAD_PB.pos(n)
	local id = CM.PROGRAMS[name].id
	poly({{-0.99, y - 0.05}, {-0.955, y - 0.05}, {-0.955, y + 0.05}, {-0.99, y + 0.05}}, LAD_CHROME.LEG_RGBA, nil, nil,
		{"CMD_ED_PROG", id - 0.5, id + 0.5}, "cmdsel")
end
lad_legend(P.PB_DFLT, "DFLT")

local function two_lines(n, l1, param, names)
	local x, y = LAD_PB.legend_pos(n)
	text(l1, {x, y + DY}, LH, WHITE, "CenterCenter")
	for k, s in ipairs(names) do
		text(s, {x, y - DY}, LH, WHITE, "CenterCenter", nil, nil, {param, k - 0.5, k + 0.5})
	end
end
two_lines(P.PB_MODE, "MODE", "CMD_MODE", CM.MODES)
two_lines(P.PB_SEL, "SEL", "CMD_SEL", {"CHF", "BOTH", "FLR"})
do
	local x, y = LAD_PB.legend_pos(P.PB_KEYPAD)
	text("KEY", {x, y + DY}, LH, WHITE, "CenterCenter")
	text("PAD", {x, y - DY}, LH, WHITE, "CenterCenter")
end

for _, b in ipairs({{P.PB_DEC, "-"}, {P.PB_INC, "+"}}) do
	local x, y = LAD_PB.legend_pos(b[1])
	text(b[2], {x, y}, 0.10, WHITE, "CenterCenter")
end
lad_legend(P.PB_UP, "UP")
lad_legend(P.PB_DOWN, "DN")
lad_legend(P.PB_RTN, "RTN")
