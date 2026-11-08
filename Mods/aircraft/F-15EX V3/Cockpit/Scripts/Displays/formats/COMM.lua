








local C = GREEN
local R = SETTINGS_ROW
local ONOFF = {"OFF", "ON"}

settings_title("COMM")

for n, s in ipairs({{1, 2, 3, -0.36}, {15, 14, 13, 0.36}}) do
	local p = "RADIO_"..n.."_"
	settings_switch(s[1], "R"..n.." PWR", p.."V", ONOFF, 0)
	settings_switch(s[2], "R"..n.." RCV", p.."RX", ONOFF, 0)
	settings_switch(s[3], "R"..n.." GRD", p.."G", ONOFF, 0)
	local x = s[4]
	text("R"..n, {x, 0.42}, 0.07, C, "CenterCenter")
	text(nil, {x, 0.30}, 0.06, C, "CenterCenter", nil, {p.."FREQ", "%.3f"}, {p.."V", 0.5, 1.5})
	text(nil, {x, 0.20}, 0.05, C, "CenterCenter", nil, {p.."TXT", "%s"}, {p.."V", 0.5, 1.5})
	text("OFF", {x, 0.30}, 0.06, C, "CenterCenter", nil, nil, {p.."V", -0.5, 0.5})
	text("RCV OFF", {x, 0.08}, R.H, AMBER, "CenterCenter", nil, nil, {{p.."V", 0.5, 1.5}, {p.."RX", -0.5, 0.5}})
end
