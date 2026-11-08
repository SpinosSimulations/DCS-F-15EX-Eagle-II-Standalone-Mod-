


CMD_PAGE = {
	ID = 33,
	ROW_Y = {0.44, 0.33, 0.22, 0.11, 0.00, -0.11, -0.43, -0.54, -0.65},
	TOTAL_Y = -0.24,
	LABEL_X = -0.60,
	VALUE_X = 0.58,
	BOX_X = {-0.65, 0.63},
	ROW_H = 0.10,

	PB_PROG = {1, 2, 3, 4},
	PB_DFLT = 5, PB_MODE = 6, PB_SEL = 7, PB_KEYPAD = 8, PB_DEC = 9, PB_INC = 10,
	PB_RTN = 13, PB_DOWN = 14, PB_UP = 15,
	PB_EWP = 6,
}


function CMD_PAGE.row_at(x, y)
	local P = CMD_PAGE
	if x < P.BOX_X[1] - 0.02 or x > P.BOX_X[2] + 0.02 then return nil end
	for i, ry in ipairs(P.ROW_Y) do
		if math.abs(y - ry) <= P.ROW_H / 2 + 0.005 then return i end
	end
end
