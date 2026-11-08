







local C = GREEN
local R = SETTINGS_ROW

settings_title("LINK 16")

settings_switch(1, "SHOW", "L16_FILT", {"ALL", "FRND", "HOST", "UNK"})
settings_switch(2, "NPG", "L16_SRC", {"ALL", "PPLI", "SURV", "F2F"})
lad_legend(15, "SIT-P")

local y = 0.56
text("TERM LOAD", {-R.X, y}, R.H, WHITE, "LeftCenter")
text("GO", {R.X, y}, R.H, C, "RightCenter", nil, nil, {"L16_TERM", 0.5, 1.5})
text("NO GO", {R.X, y}, R.H, AMBER, "RightCenter", nil, nil, {"L16_TERM", -0.5, 0.5})
y = y - R.DY * 0.8
text("NET ENTRY", {-R.X, y}, R.H, WHITE, "LeftCenter")
for k, v in ipairs({{"---", AMBER}, {"CHK TIME", AMBER}, {"COARSE SYNC", C}, {"FINE SYNC", C}}) do
	text(v[1], {R.X, y}, R.H, v[2], "RightCenter", nil, nil, {"L16_NET", k - 1.5, k - 0.5})
end
y = y - R.DY * 0.8
text("TX", {-R.X, y}, R.H, WHITE, "LeftCenter")
text("RECEIVE ONLY", {R.X, y}, R.H, C, "RightCenter")
y = y - R.DY
text(nil, {-R.X, y}, R.H, C, "LeftCenter", nil, {"L16_N_PPLI", "PPLI %.0f"})
text(nil, {0, y}, R.H, C, "CenterCenter", nil, {"L16_N_SURV", "SURV %.0f"})
text(nil, {R.X, y}, R.H, C, "RightCenter", nil, {"L16_N_F2F", "F2F %.0f"})
y = y - R.DY * 0.8
text(nil, {-R.X, y}, R.H, C, "LeftCenter", nil, {"L16_N_FRD", "FRD %.0f"})
text(nil, {0, y}, R.H, RED, "CenterCenter", nil, {"L16_N_HOS", "HOS %.0f"})
text(nil, {R.X, y}, R.H, YELLOW, "RightCenter", nil, {"L16_N_UNK", "UNK %.0f"})


local TH = 0.040
y = y - R.DY * 0.9
text(" TN ID  SOURCE  BRG   RNG  ALT AGE", {-R.X - 0.05, y}, TH, WHITE, "LeftCenter")
text("NO TRACKS", {0, y - 0.07}, TH, C, "CenterCenter", nil, nil, {"L16_ROWS", -0.5, 0.5})
for k = 1, 10 do
	text(nil, {-R.X - 0.05, y - k * 0.052}, TH, C, "LeftCenter", nil, {string.format("L16_ROW_%02d", k), "%s"},
		{"L16_ROWS", k - 0.5, 99})
end
