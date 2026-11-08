










settings_title("LIGHTS")

local ROWS = {
	{1, "NAV", "LIGHT_NAV", {"OFF", "BRT", "DIM"}},
	{2, "A-COL", "LIGHT_ACOL", {"OFF", "ON"}},
	{3, "FORM", "LIGHT_FORM", {"OFF", "BRT", "DIM"}},
	{4, "FLOOD", "LIGHT_FLOOD", {"OFF", "ON"}},
	{5, "AAR", "LIGHT_AAR", {"OFF", "ON"}},
	{15, "GEAR LT", "LIGHT_GEAR", {"OFF", "TAXI", "LDG"}},
	{14, "MASTER", "LIGHT_MASTER", {"OFF", "ON"}},
}
local summary = {}
for i, r in ipairs(ROWS) do
	settings_switch(r[1], r[2], r[3], r[4])
	summary[i] = {r[2], r[3], r[4]}
end
local Y0, R = 0.45, SETTINGS_ROW
local yn = settings_summary(summary, Y0) - 0.05
text("NO AC POWER", {0, yn}, R.H, AMBER, "CenterCenter", nil, nil, {"LIGHT_POWER", -0.5, 0.5})
text("MASTER OFF", {0, yn - R.DY}, R.H, AMBER, "CenterCenter", nil, nil, {"LIGHT_MASTER", 0.5, 1.5})
text("GEAR LT: GEAR UP", {0, yn - 2 * R.DY}, R.H, AMBER, "CenterCenter", nil, nil,
	{{"LIGHT_GEAR", 1.5, 3.5}, {"EFM_GEAR_POS", -1, 0.95}})
