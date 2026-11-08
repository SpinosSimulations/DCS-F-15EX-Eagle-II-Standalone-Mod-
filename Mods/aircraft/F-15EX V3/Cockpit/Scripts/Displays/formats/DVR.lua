




local C = GREEN
local H = 0.065

text("DVR", {0, 0.62}, 0.075, C, "CenterCenter")
text("STBY", {0, 0.30}, 0.09, C, "CenterCenter", nil, nil, {"DISP_RCD", -0.5, 0.5})
text("REC", {0, 0.30}, 0.09, C, "CenterCenter", nil, nil, {"DISP_RCD", 0.5, 1.5})
rect(-0.15, 0.24, 0.15, 0.36, 0.008, C, nil, {"DISP_RCD", 0.5, 1.5})
text("RUN TIME", {-0.55, 0.05}, H, C, "LeftCenter")
text(nil, {0.30, 0.05}, H, C, "RightCenter", nil, {"DISP_DVR_H", "%02.0f"})
text(nil, {0.30, 0.05}, H, C, "LeftCenter", nil, {"DISP_DVR_M", ":%02.0f"})
text(nil, {0.42, 0.05}, H, C, "LeftCenter", nil, {"DISP_DVR_S", ":%02.0f"})
text("MEDIA", {-0.55, -0.07}, H, C, "LeftCenter")
text(nil, {0.30, -0.07}, H, C, "RightCenter", nil, {"DISP_DVR_MEDIA", "%.0f%%"})
text("SOURCES", {-0.55, -0.25}, H, C, "LeftCenter")
text("HUD  LAD  HMD", {-0.55, -0.33}, H, C, "LeftCenter")
