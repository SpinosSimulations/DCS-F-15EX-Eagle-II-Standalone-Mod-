










settings_title("HUD PROG")

local names = {}
for k, col in ipairs(SYM_COLORS) do names[k] = col.name end
local ONOFF = {"OFF", "ON"}
local pct = {}
for k = 1, 10 do pct[k] = (k * 10).."%" end

settings_switch(1, "HUD COL", "HUDP_HUD_COL", names)
settings_switch(2, "HMD COL", "HUDP_HMD_COL", names)
lad_legend(3, "BRT\nUP")
lad_legend(4, "BRT\nDOWN")
settings_switch(15, "HMD", "HUDP_HMD_SW", ONOFF)
settings_switch(14, "NVG", "HUDP_NVG", ONOFF)
settings_switch(13, "MODE", "HUDP_NIGHT", {"DAY", "NIGHT"})

local Y0, R = 0.45, SETTINGS_ROW
local yn = settings_summary({
	{"HUD COLOUR", "HUDP_HUD_COL", names},
	{"HMD COLOUR", "HUDP_HMD_COL", names},
	{"BRIGHTNESS", "HUD_BRT", pct, 1, 10},
	{"HMD", "HUDP_HMD_SW", ONOFF},
	{"NVG", "HUDP_NVG", ONOFF},
	{"MODE", "HUDP_NIGHT", {"DAY", "NIGHT"}},
}, Y0)
text("HMD OFF", {0, yn - 0.05}, R.H, AMBER, "CenterCenter", nil, nil, {"HUDP_HMD_SW", 0.5, 1.5})


local function fpm(x, y, rgba, vis)
	local r = 0.045
	circle(r, 0.010, rgba, nil, {x, y}, 24, vis)
	segments({{-r, 0, -2.4 * r, 0}, {r, 0, 2.4 * r, 0}, {0, r, 0, 1.9 * r}}, 0.010, rgba, nil, {x, y}, vis)
end
local YS = yn - 0.30
for _, s in ipairs({{"HUD", -0.25, "HUDP_HUD_COL"}, {"HMD", 0.25, "HUDP_HMD_COL"}}) do
	for k, col in ipairs(SYM_COLORS) do
		local rgba = {col.rgb[1], col.rgb[2], col.rgb[3], 255}
		local vis = {s[3], k - 0.5, k + 0.5}
		fpm(s[2], YS, rgba, vis)
		text(s[1], {s[2], YS - 0.14}, R.H, rgba, "CenterCenter", nil, nil, vis)
	end
end
