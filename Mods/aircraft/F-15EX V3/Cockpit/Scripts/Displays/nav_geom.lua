



NAV_ROT_GAIN	= -1.0

NAV_MAX_SP		= 20


NAV_R			= 0.64
NAV_R_ROSE		= NAV_R
NAV_ROSE_DASH	= 0.034
NAV_R_LABEL		= NAV_R
NAV_ROSE_LABELS	= {"N", "3", "6", "E", "12", "15", "S", "21", "24", "W", "30", "33"}
NAV_HSI_SCALES	= {10, 20, 40, 80, 160}
NAV_R_PTR_IN	= 0.675
NAV_R_PTR_OUT	= 0.745
NAV_CDI_FULL	= 0.24
NAV_CDI_LEN		= 0.40


NAV_HUD_EDGE	= 6


NAV_HUD_DIAMOND	= 6
NAV_HUD_ILS_FULL = 40
NAV_HUD_ILS_LEN	= 60










NAV_TAPE_Y		= 96
NAV_TAPE_HALF	= 78
NAV_TAPE_PER_DEG = 4.875
NAV_TAPE_STEP	= 2




NAV_TAPE_SLOTS	= 18
NAV_TAPE_SHORT	= 2.5
NAV_TAPE_LONG	= 5
NAV_HUD_CARET_Y	= NAV_TAPE_Y
NAV_HUD_CARET	= NAV_TAPE_HALF
NAV_HUD_CARET_PER_DEG = NAV_TAPE_PER_DEG



function nav_hdg_tape(hdg)
	local out = {}
	local span = NAV_TAPE_STEP * NAV_TAPE_SLOTS
	for k = 1, NAV_TAPE_SLOTS do
		local base = NAV_TAPE_STEP * (k - 1)
		local h = base + span * math.floor((hdg - base) / span + 0.5)
		local x = (h - hdg) * NAV_TAPE_PER_DEG
		local hw = h % 360
		local kind = 0
		if math.abs(x) <= NAV_TAPE_HALF + 1e-9 then kind = (hw % 10 == 0) and 2 or 1 end
		local label = math.floor(hw / 10 + 0.5) % 36
		out[k] = {x = x, kind = kind, label = label == 0 and 36 or label}
	end
	return out
end
