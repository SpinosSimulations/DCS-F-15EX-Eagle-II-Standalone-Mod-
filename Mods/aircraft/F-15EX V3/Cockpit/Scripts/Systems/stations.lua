












local ST = {}

local function row(label, side, arm, tier, x, y, wing)
	return {label = label, side = side, arm = arm, tier = tier, x = x, y = y, wing = wing or false}
end


local function layout(fore_l, aft_l, aft_r, fore_r, body_arm)
	return {
		row("1",    "L", -4.0,      1, -0.68,  0.62, true),
		row("2",    "L", -2.94,     3, -0.42,  0.70, true),
		row("2A",   "L", -3.26,     2, -0.44, -0.28),
		row("2B",   "L", -2.62,     4, -0.36,  0.04),
		row(fore_l, "L", -body_arm, 5, -0.12,  0.04),
		row(aft_l,  "L", -body_arm, 5, -0.16, -0.28),
		row("TGP",  "C", 0,         6, -0.15,  0.74),
		row("6",    "C", 0,         6,  0.00, -0.56),
		row("NAV",  "C", 0,         6,  0.15,  0.74),
		row(aft_r,  "R", body_arm,  5,  0.16, -0.28),
		row(fore_r, "R", body_arm,  5,  0.12,  0.04),
		row("11B",  "R", 2.62,      4,  0.36,  0.04),
		row("11A",  "R", 3.26,      2,  0.44, -0.28),
		row("11",   "R", 2.94,      3,  0.42,  0.70, true),
		row("12",   "R", 4.0,       1,  0.68,  0.62, true),
	}
end

ST.LAYOUTS = {
	F15EX     = layout("LF", "LA", "RA", "RF", 1.43),
	F15EX_CFT = layout("LCFT", "LCFT-A", "RCFT-A", "RCFT", 1.73),
	F15IA     = layout("LCFT", "LCFT-A", "RCFT-A", "RCFT", 1.73),
}

ST.ORDER = {1, 15, 14, 2, 3, 13, 12, 4, 5, 11, 6, 10, 7, 9, 8}
ST.DEFAULT = "F15EX"


function ST.of(unit_type)
	return ST.LAYOUTS[unit_type] or ST.LAYOUTS[ST.DEFAULT], (ST.LAYOUTS[unit_type] and unit_type) or ST.DEFAULT
end


function ST.current()
	local t
	if type(get_aircraft_type) == "function" then
		local ok, v = pcall(get_aircraft_type)
		if ok and type(v) == "string" then t = v end
	end
	return ST.of(t)
end

return ST
