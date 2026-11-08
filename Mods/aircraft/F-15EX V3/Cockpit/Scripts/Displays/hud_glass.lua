







HUD_GLASS_MM = {{-80, -55}, {-43, -78}, {56, -78}, {92, -55}, {91, 58}, {89, 62}, {67, 81}, {37, 84}, {7, 85},
	{-24, 84}, {-53, 81}, {-78, 62}, {-79, 58}}
if get_aircraft_type() == "F15IA" then
    for _, point in ipairs(HUD_GLASS_MM) do
        point[1] = 6.46 + 1.5324 * (point[1] - 6.46)
    end
end
HUD_GLASS_MM_PER_MR = 0.735
HUD_GLASS_MR = {}
for i, v in ipairs(HUD_GLASS_MM) do
	HUD_GLASS_MR[i] = {v[1] / HUD_GLASS_MM_PER_MR, v[2] / HUD_GLASS_MM_PER_MR}
end








HUD_STOP_SPAN = {x = get_aircraft_type() == "F15IA" and {-294, 202} or {-195, 133}, y = {-142, 190}}
HUD_STOP_MR = {}
do
	local lo = {x = math.huge, y = math.huge}
	local hi = {x = -math.huge, y = -math.huge}
	for _, v in ipairs(HUD_GLASS_MR) do
		lo.x, hi.x = math.min(lo.x, v[1]), math.max(hi.x, v[1])
		lo.y, hi.y = math.min(lo.y, v[2]), math.max(hi.y, v[2])
	end
	local function map(v, a, b, s) return s[1] + (v - a) / (b - a) * (s[2] - s[1]) end
	for i, v in ipairs(HUD_GLASS_MR) do
		HUD_STOP_MR[i] = {map(v[1], lo.x, hi.x, HUD_STOP_SPAN.x), map(v[2], lo.y, hi.y, HUD_STOP_SPAN.y)}
	end
end
