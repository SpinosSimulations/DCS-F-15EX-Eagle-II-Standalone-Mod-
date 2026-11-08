










dofile(LockOn_Options.script_path.."Displays/common.lua")
SetScale(FOV)

clip_mask({{-1, 1}, {1, 1}, {1, -1}, {-1, -1}}, DEFAULT_LEVEL + 1)
POWER_VIS = {"DISP_PWR_RSD", 0.5, 1.5}

local GLASS_A = 215
local SKY = {0, 100, 220, GLASS_A}
local GROUND = {125, 82, 35, GLASS_A}
local C = WHITE
local LW = 0.02
local PITCH_PER_DEG = 0.03
local MRAD_PER_DEG = 17.4533


local horizon = node({0, 0}, nil, {"HUD_ROLL", "HUD_PITCH"},
	{{"rotate_using_parameter", 0, 1}, {"move_up_down_using_parameter", 1, -S(PITCH_PER_DEG / MRAD_PER_DEG)}})




NIGHT_RGB = {0, 0.004, 0.011}
poly({{-3, 0}, {3, 0}, {3, 4}, {-3, 4}}, SKY, horizon)
NIGHT_RGB = {0.004, 0.002, 0.0005}
poly({{-3, -4}, {3, -4}, {3, 0}, {-3, 0}}, GROUND, horizon)
NIGHT_RGB = nil
segments({{-3, 0, 3, 0}}, LW, C, horizon)

for p = -90, 90, 5 do
	if p ~= 0 then
		local y = p * PITCH_PER_DEG
		local half = (p % 10 == 0) and 0.24 or 0.11
		segments({{-half, y, half, y}}, LW, C, horizon)
		if p % 10 == 0 then
			text(tostring(math.abs(p)), {-half - 0.05, y}, 0.08, C, "RightCenter", horizon)
			text(tostring(math.abs(p)), {half + 0.05, y}, 0.08, C, "LeftCenter", horizon)
		end
	end
end


local BANK_R = 0.80
local ticks = {}
for _, b in ipairs({-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60}) do
	local a = math.rad(90 + b)
	local len = (b % 30 == 0) and 0.10 or 0.06
	ticks[#ticks + 1] = {BANK_R * math.cos(a), BANK_R * math.sin(a), (BANK_R + len) * math.cos(a), (BANK_R + len) * math.sin(a)}
end
segments(ticks, LW, C)
local sky_ptr = node({0, 0}, nil, {"HUD_ROLL"}, {{"rotate_using_parameter", 0, 1}})
poly({{0, BANK_R - 0.01}, {0.05, BANK_R - 0.09}, {-0.05, BANK_R - 0.09}}, C, sky_ptr)


local function wings(w, rgba)
	segments({{-0.42, 0, -0.14, 0}, {-0.14, 0, -0.14, -0.07}, {0.14, 0, 0.42, 0}, {0.14, 0, 0.14, -0.07}}, w, rgba)
	poly({{-0.025, -0.025}, {0.025, -0.025}, {0.025, 0.025}, {-0.025, 0.025}}, rgba)
end
wings(0.075, BLACK)
wings(0.04, night_hue(YELLOW))


local H = 0.14
local ADV = 0.63 * H
local function box(x1, x2, y, param, fmt)
	poly({{x1, y - 0.1}, {x2, y - 0.1}, {x2, y + 0.1}, {x1, y + 0.1}}, BLACK)
	rect(x1, y - 0.1, x2, y + 0.1, LW, GREEN)
	text(nil, {x2 - 0.04, y}, H, GREEN, "RightCenter", nil, {param, fmt})
end
box(-0.97, -0.97 + 3 * ADV + 0.08, 0, "DISP_CAS", "%.0f")
box(0.97 - 5 * ADV - 0.08, 0.97, 0, "DISP_ALT_FT", "%.0f")
box(0.97 - 4 * ADV - 0.08, 0.97, 0.86, "DISP_MACH", "%.2f")
