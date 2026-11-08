





LAD_STRIP = {
	X0 = -0.974, X1 = 0.974, GAP = 0.004,
	TILES = {
		{26, "CLOCK"}, {47, "CAUTION"}, {47, "AP"}, {70, "R1"}, {71, "R2"}, {66, "HF"}, {67, "IFF"}, {43, "PP"},
		{37, "LAW"}, {40, "TCN"}, {40, "ILS"}, {42, "HUD"}, {40, "GCWS"}, {42, "NFTF"}, {46, "POS"}, {31, "KEYPAD"},
		{35, "SSB"},
	},
}


function LAD_STRIP.edges(k)
	local S = LAD_STRIP
	local total = 0
	for _, t in ipairs(S.TILES) do total = total + t[1] end
	local x = S.X0
	for i, t in ipairs(S.TILES) do
		local w = (S.X1 - S.X0) * t[1] / total
		if i == k then return x, x + w end
		x = x + w
	end
end


function LAD_STRIP.at(x)
	for k, t in ipairs(LAD_STRIP.TILES) do
		local a, b = LAD_STRIP.edges(k)
		if x >= a and x < b then return k, t[2] end
	end
end






LAD_KEYPAD = {
	ID = 30,
	COLS = {-0.27, 0, 0.27}, ROWS = {0.25, 0.01, -0.23, -0.47}, ENT_Y = -0.69,
	W = 0.24, H = 0.20,
	KEYS = {"1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "CLR"},
	LINE_Y = 0.54, NOW_Y = 0.42,
	MAX = 6,


	FIELDS = {
		[1] = {"TCN", 1}, [2] = {"X/Y", "band"}, [3] = {"ILS", 3}, [4] = {"CRS", 4}, [5] = {"STPT", 5},
		[15] = {"R1", 21}, [14] = {"R2", 22},
		[20] = {"HDG", 14},
		[18] = {"LAW", 40},
		[19] = {"BINGO", 41},
	},
	PB_RTN = 13,
}


function LAD_KEYPAD.at(x, y)
	local K = LAD_KEYPAD
	local hw, hh = K.W / 2 + 0.01, K.H / 2 + 0.01
	for r, ky in ipairs(K.ROWS) do
		for c, kx in ipairs(K.COLS) do
			if math.abs(x - kx) <= hw and math.abs(y - ky) <= hh then return K.KEYS[(r - 1) * 3 + c] end
		end
	end
	if math.abs(x) <= K.COLS[3] + hw and math.abs(y - K.ENT_Y) <= hh then return "ENT" end
end
