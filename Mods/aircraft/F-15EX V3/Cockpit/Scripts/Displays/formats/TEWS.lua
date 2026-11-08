













dofile(LockOn_Options.script_path.."Displays/ew_geom.lua")

local C = GREEN
local DIM = {0, 150, 0, 255}
local H = 0.065
local HS = 0.05
local LW = 0.007


for k = 0, 11 do
	local x, y = ew_xy(math.rad(30 * k), TEWS_R_DOTS)
	local d = 0.011
	poly({{x - d, y - d}, {x + d, y - d}, {x + d, y + d}, {x - d, y + d}}, C, nil, nil, nil, "dot")
end

local rose = node({0, 0}, nil, {"TEWS_ROSE_ROT"}, {{"rotate_using_parameter", 0, EW_ROT_GAIN}})
local ticks = {}
for k = 0, 71 do
	local len = (k % 2 == 0) and TEWS_ROSE_LONG or TEWS_ROSE_SHORT
	local x1, y1 = ew_xy(math.rad(5 * k), TEWS_R_ROSE)
	local x2, y2 = ew_xy(math.rad(5 * k), TEWS_R_ROSE - len)
	ticks[#ticks + 1] = {x1, y1, x2, y2}
end
segments(ticks, 0.005, C, rose)
for k, s in ipairs(TEWS_ROSE_LABELS) do
	local n = node({0, 0}, nil, {string.format("TEWS_ROSE_%02d_X", k), string.format("TEWS_ROSE_%02d_Y", k)},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	text(s, {0, 0}, HS, C, "CenterCenter", n)
end

dashed_arc(TEWS_R_DOTS / 2, 0, 2 * math.pi, 0.004, DIM, nil, nil, 36, {"TEWS_SCALE", 0.5, 1e9})

segments({{-0.06, 0, -0.025, 0}, {0.025, 0, 0.06, 0}, {0, -0.06, 0, -0.025}, {0, 0.025, 0, 0.06}}, LW, C)


for i = 1, TEWS_MAX do
	local pre = string.format("TEWS_T%02d_", i)
	local n = node({0, 0}, nil, {pre.."X", pre.."Y"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	local on = {pre.."V", 0.5, 1.5}
	text(nil, {0, 0}, H, C, "CenterCenter", n, {pre.."TXT", "%s"}, {on, {pre.."CN", -0.5, 0.5}})
	text(nil, {0, 0}, H, C, "CenterCenter", n, {pre.."NUM", "%.0f"}, {on, {pre.."CN", 0.5, 1.5}})

	segments({{-0.07, -0.042, 0.07, -0.042}, {0.07, -0.042, 0, 0.062}, {0, 0.062, -0.07, -0.042}}, 0.006, C, n, nil,
		{on, {pre.."AIR", 0.5, 1.5}})

	segments({{-0.055, -0.03, -0.038, -0.05}, {-0.038, -0.05, 0.038, -0.05}, {0.038, -0.05, 0.055, -0.03}}, 0.006, C, n,
		nil, {on, {pre.."SHIP", 0.5, 1.5}})
	circle(0.075, 0.006, C, n, nil, 20, {on, {pre.."LOCK", 0.5, 1.5}})

	segments({{-0.035, -0.068, -0.012, -0.068}, {0.012, -0.068, 0.035, -0.068}}, 0.005, C, n, nil,
		{on, {pre.."RNG", 0.5, 1.5}})
	segments({{-0.035, -0.068, 0.035, -0.068}}, 0.005, C, n, nil, {on, {pre.."RNG", 1.5, 2.5}})


	text(nil, {0, -0.115}, HS, C, "CenterCenter", n, {pre.."TTI", "%.0f"}, {on, {pre.."TTIV", 0.5, 1.5}})
	text("--", {0, -0.115}, HS, C, "CenterCenter", n, nil, {on, {pre.."TTIV", 1.5, 2.5}})
end


local ACT = {"TEWS_ALERT", 1.5, 2.5}
text(nil, {0, 0.93}, H, C, "CenterCenter", nil, {"TEWS_MSL_TTI", "MSL ACT %.0f"},
	{{"TEWS_MSL_V", 0.5, 1.5}, ACT, {"TEWS_MSL_TTI", -0.5, 1e6}})
text("MSL ACT --", {0, 0.93}, H, C, "CenterCenter", nil, nil, {{"TEWS_MSL_V", 0.5, 1.5}, ACT, {"TEWS_MSL_TTI", -1e6, -0.5}})
text("LAUNCH", {0, 0.93}, H, C, "CenterCenter", nil, nil, {{"TEWS_MSL_V", 0.5, 1.5}, {"TEWS_ALERT", 0.5, 1.5}})


text("PWR", {-0.80, 0.93}, HS, C, "LeftCenter", nil, nil, {"TEWS_SCALE", -0.5, 0.5})
text(nil, {-0.80, 0.93}, HS, C, "LeftCenter", nil, {"TEWS_SCALE", "%.0f NM"}, {"TEWS_SCALE", 0.5, 1e9})
text(nil, {-0.80, 0.86}, HS, C, "LeftCenter", nil, {"TEWS_FIXES", "FIX %.0f"}, {"TEWS_SCALE", 0.5, 1e9})
text(nil, {0.80, 0.93}, HS, C, "RightCenter", nil, {"SMS_CHF", "CHF %3.0f"}, {"SMS_CHF", -0.5, 1e9})
text(nil, {0.80, 0.86}, HS, C, "RightCenter", nil, {"SMS_FLR", "FLR %3.0f"}, {"SMS_FLR", -0.5, 1e9})


text("CMD", {0.80, 0.77}, HS, C, "RightCenter")
for k, s in ipairs({"OFF", "STBY", "MAN", "SEMI", "AUTO"}) do
	text(s, {0.80, 0.71}, HS, C, "RightCenter", nil, nil, {"CMD_MODE", k - 0.5, k + 0.5})
end
for k, s in ipairs({"CHF", "BOTH", "FLR"}) do
	text(s, {0.80, 0.65}, HS, C, "RightCenter", nil, nil, {{"CMD_MODE", 2.5, 5.5}, {"CMD_SEL", k - 0.5, k + 0.5}})
end
for k, s in ipairs({"MAN1", "AIR", "SAM", "MAN2"}) do
	text("RUN "..s, {0.80, 0.59}, HS, C, "RightCenter", nil, nil, {"CMD_RUN", k - 0.5, k + 0.5})
	text("PRG "..s, {0.80, 0.59}, HS, C, "RightCenter", nil, nil, {{"CMD_RUN", -0.5, 0.5}, {"CMD_READY", k - 0.5, k + 0.5}})
end
text("MIN", {0.80, 0.53}, HS, C, "RightCenter", nil, nil, {"CMD_MIN", 0.5, 1.5})
text(nil, {0.80, -0.93}, HS, DIM, "RightCenter", nil, {"TEWS_N", "%.0f EMTR"})

local function down(s, x, y0)
	for k = 1, #s do text(s:sub(k, k), {x, y0 - 0.06 * (k - 1)}, HS, C, "CenterCenter") end
end
down("DCL", -0.95, 0.62)
down("AUTO", -0.95, -0.20)
down("GLOBAL", 0.95, 0.52)

dofile(LockOn_Options.script_path.."Displays/cmd_page.lua")
lad_legend(CMD_PAGE.PB_EWP, "CMD")

