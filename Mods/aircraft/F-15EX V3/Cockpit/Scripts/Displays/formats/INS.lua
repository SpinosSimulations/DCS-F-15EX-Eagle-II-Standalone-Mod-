









local G, A, W = GREEN, AMBER, WHITE
local DIM = {0, 150, 0, 255}
local H, HB = 0.05, 0.075
local X = -0.50
local CW = TEXFONT_RECT_X * H * TEXT_CAP_RATIO / TEXFONT_CAP

text("INS", {0, 0.70}, H, G)


local CWL = TEXFONT_RECT_X * LAD_CHROME.LEG_H * TEXT_CAP_RATIO / TEXFONT_CAP
local XB = LAD_LAYOUT.BAND + 0.005
for pb, l in ipairs({"OFF", "SH", "GC", "NAV", "IFA"}) do
	lad_legend(pb, l)
	local _, y = LAD_PB.pos(pb)
	rect(-0.96, y - 0.05, math.min(-XB, -0.935 + #l * CWL + 0.02), y + 0.05, 0.006, W, nil,
		{"NAV_INS_MODE", pb - 1.5, pb - 0.5})
end


text(nil, {X, 0.48}, HB, A, "LeftCenter", nil, {"NAV_ALIGN_TXT", "%s"}, {"NAV_INS_OK", -0.5, 0.5})
text(nil, {X, 0.48}, HB, G, "LeftCenter", nil, {"NAV_ALIGN_TXT", "%s"}, {"NAV_INS_OK", 0.5, 2.5})
local aligning = {"NAV_ALIGN_S", 0.5, 1e9}
text("TIME", {X, 0.32}, H, G, "LeftCenter", nil, nil, aligning)
text(nil, {X + 5 * CW, 0.32}, H, G, "LeftCenter", nil, {"NAV_ALIGN_M", "%.0f:"}, aligning)
text(nil, {X + 7 * CW, 0.32}, H, G, "LeftCenter", nil, {"NAV_ALIGN_SS", "%02.0f"}, aligning)
text(nil, {X, 0.22}, H, G, "LeftCenter", nil, {"NAV_INS_Q", "QUAL %.1f"}, {"NAV_INS_Q_V", 0.5, 1.5})
text("STORED HDG", {X, 0.06}, H, G, "LeftCenter", nil, nil, {"NAV_INS_SH", 0.5, 1.5})
text("NO STORED HDG", {X, 0.06}, H, DIM, "LeftCenter", nil, nil, {"NAV_INS_SH", -0.5, 0.5})
text("GPS ON", {X, -0.04}, H, G, "LeftCenter", nil, nil, {"NAV_GPS", 0.5, 1.5})
text("GPS OFF", {X, -0.04}, H, A, "LeftCenter", nil, nil, {"NAV_GPS", -0.5, 0.5})
text(nil, {X, -0.14}, H, G, "LeftCenter", nil, {"NAV_ERR_M", "ERR %.0f M"}, {"NAV_INS", 1.5, 2.5})
text("SELECT NAV", {X, -0.36}, HB, A, "LeftCenter", nil, nil, {"NAV_INS_OK", 0.5, 1.5})


lad_legend(13, "GPS")
do
	local _, y = LAD_PB.pos(13)
	rect(math.max(XB, 0.935 - 3 * CWL - 0.02), y - 0.05, 0.96, y + 0.05, 0.006, W, nil, {"NAV_GPS", 0.5, 1.5})
end
lad_legend(15, "HSI")
