












local C = GREEN
local H = LAD_CHROME.LEG_H
local DY = H * 1.25 / 2
local W = 0.006
local R = SETTINGS_ROW

settings_title("IFF")


for m, fmt in ipairs({"%02.0f", "%04.0f", "%04.0f"}) do
	local x, y, align = LAD_PB.legend_pos(m)
	text("M"..m, {x, y + DY}, H, WHITE, align)
	text("*", {x + 0.085, y + DY}, H, WHITE, align, nil, nil, {"IFF_M"..m.."_ON", 0.5, 1.5})
	text(nil, {x, y - DY}, H, WHITE, align, nil, {"IFF_M"..m, fmt})
end
settings_switch(4, "M4", "IFF_M4", {"A", "B", "OUT"})
settings_switch(5, "MC", "IFF_MC_ON", {"OFF", "ON"}, 0)


for m = 1, 3 do
	local x, y = LAD_PB.pos(5 + m)
	text("M"..m, {x, y + DY}, H, WHITE, "CenterCenter")
	text("CODE", {x, y - DY}, H, WHITE, "CenterCenter")
end
settings_switch(9, "MASTER", "IFF_MASTER", {"NORM", "LOW", "EMER"})
do
	local x, y = LAD_PB.pos(10)
	text("I/P", {x, y}, H, WHITE, "CenterCenter")
	rect(x - 0.065, y - 0.045, x + 0.065, y + 0.045, W, WHITE, XF and XF.bands and XF.bands["0,-1"], {"IFF_IP", 0.5, 1.5})
end


settings_switch(15, "AAI", "IFF_ON", {"OFF", "ON"}, 0)
settings_switch(14, "AUTO ID", "IFF_AUTO", {"ALL", "DT", "MAN"})
lad_legend(13, "INTG")


local y = 0.56
text("XPDR", {-R.X, y}, R.H, WHITE, "LeftCenter")
text(nil, {R.X, y}, R.H, C, "RightCenter", nil, {"IFF_M1", "M1-%02.0f"})
y = y - R.DY * 0.8
text(nil, {-R.X, y}, R.H, C, "LeftCenter", nil, {"IFF_M2", "M2-%04.0f"})
text(nil, {R.X, y}, R.H, C, "RightCenter", nil, {"IFF_M3", "M3-%04.0f"})
y = y - R.DY * 0.8
for k, v in ipairs({"NORM", "LOW", "EMER"}) do
	text(v, {-R.X, y}, R.H, k == 3 and AMBER or C, "LeftCenter", nil, nil, {"IFF_MASTER", k - 0.5, k + 0.5})
end
for k, v in ipairs({"M4 A", "M4 B", "M4 OUT"}) do
	text(v, {R.X, y}, R.H, k == 3 and AMBER or C, "RightCenter", nil, nil, {"IFF_M4", k - 0.5, k + 0.5})
end
text(nil, {0, y}, R.H, WHITE, "CenterCenter", nil, {"IFF_IP_S", "I/P %.0f"}, {"IFF_IP", 0.5, 1.5})

y = y - R.DY * 1.1
text("AAI", {-R.X, y}, R.H, WHITE, "LeftCenter")
text("OFF", {R.X, y}, R.H, AMBER, "RightCenter", nil, nil, {"IFF_ON", -0.5, 0.5})
for k, v in ipairs({"AUTO ALL", "AUTO DT", "MANUAL"}) do
	text(v, {R.X, y}, R.H, C, "RightCenter", nil, nil, {{"IFF_ON", 0.5, 1.5}, {"IFF_AUTO", k - 0.5, k + 0.5}})
end
y = y - R.DY * 0.8
text(nil, {-R.X, y}, R.H, C, "LeftCenter", nil, {"IFF_CNT_F", "FRIEND %.0f"})
text(nil, {0, y}, R.H, C, "CenterCenter", nil, {"IFF_CNT_N", "NO REPLY %.0f"})
text(nil, {R.X, y}, R.H, C, "RightCenter", nil, {"IFF_CNT_U", "UNK %.0f"})


local TH = 0.042
y = y - R.DY * 0.9
text("TN  REPLY       RANGE    BRG", {-R.X, y}, TH, WHITE, "LeftCenter")
text("NO TRACKS", {0, y - 0.07}, TH, C, "CenterCenter", nil, nil, {"IFF_ROWS", -0.5, 0.5})
for k = 1, 8 do
	text(nil, {-R.X, y - k * 0.058}, TH, C, "LeftCenter", nil, {string.format("IFF_ROW_%d", k), "%s"},
		{"IFF_ROWS", k - 0.5, 99})
end
