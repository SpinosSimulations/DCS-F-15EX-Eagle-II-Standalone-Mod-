





LAD_TOUCH = {
	COLS = 160, ROWS = 80,
	ASPECT = 0.52914, STRIP_BOTTOM = 0.43696,
	WIDTH_MM = 554.6,
	VALUE_SCALE = 100000,
}


function LAD_TOUCH.cell(idx)
	local T = LAD_TOUCH
	local r, c = math.floor((idx - 1) / T.COLS), (idx - 1) % T.COLS + 1
	if idx < 1 or r > T.ROWS then return nil end
	local x = -1 + (c - 0.5) * 2 / T.COLS
	if r == 0 then return 0, c, x, (T.STRIP_BOTTOM + T.ASPECT) / 2 end
	return r, c, x, T.STRIP_BOTTOM - (r - 0.5) * (T.STRIP_BOTTOM + T.ASPECT) / T.ROWS
end


function LAD_TOUCH.name(r, c)
	if r == 0 then return string.format("LAD_STRIP_%03d", c) end
	return string.format("LAD_TOUCH_%03d_%03d", r, c)
end
