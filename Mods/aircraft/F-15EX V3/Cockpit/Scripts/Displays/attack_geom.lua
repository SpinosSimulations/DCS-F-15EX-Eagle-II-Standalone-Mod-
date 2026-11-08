


ATK_O_X			= 0.0
ATK_O_Y			= -0.40
ATK_R			= 1.10
ATK_AZ_MAX		= 60.0
ATK_MAX_TRACKS	= 32
ATK_MAX_HITS	= 32

ATK_STICK_STEPS	= 6
ATK_STICK_MPS	= 100.0
ATK_STICK_LEN	= 0.03
ATK_DT_PIECES	= 48
ATK_N_R			= 1.16
ATK_BAND_X		= -0.90
ATK_BAND_TOP	= -0.22
ATK_BAND_BOT	= -0.64
ATK_RING_DEG	= 100.0

ATK_IFF_STATES	= 3
ATK_MAX_THREATS	= 8
ATK_MAX_DL		= 32


ATK_EL_CARET_DEG = 30.0
ATK_CUR_HALF_W	= 0.018
ATK_CUR_HALF_H	= 0.035


ATK_ROT_GAIN	= -1.0






ATK_EXP_K		= {2, 4}
ATK_EXP_CX		= 0.32
ATK_EXP_CY		= -0.62
ATK_EXP_HX		= 0.22
ATK_EXP_HY		= 0.22
ATK_EXP_PAD		= 0.035
ATK_EXP_TRACKS	= 6
ATK_EXP_DL		= 4
ATK_EXP_HITS	= 4


function atk_xy(range, brg, scale_m)
	if range < 0 or range > scale_m or math.abs(brg) > math.rad(ATK_AZ_MAX) + 1e-9 then return nil end
	local r = range / scale_m * ATK_R
	return ATK_O_X + r * math.sin(brg), ATK_O_Y + r * math.cos(brg)
end



ATK_Z_X			= 0.86
ATK_Z_TOP		= -0.08
ATK_Z_BOT		= -0.84
ATK_Z_DASHES	= 14
ATK_Z_PIECES	= 40



function atk_exp_xy(x, y, k, cx, cy)
	local dx, dy = k * (x - cx), k * (y - cy)
	local lx, ly = ATK_EXP_HX - ATK_EXP_PAD, ATK_EXP_HY - ATK_EXP_PAD
	if math.abs(dx) > lx or math.abs(dy) > ly then return nil end
	return ATK_EXP_CX + dx, ATK_EXP_CY + dy
end




ATK_EXP_PIECES	= 28
function atk_exp_line(px, py, k, cx, cy, short)
	local ox, oy = ATK_EXP_CX + k * (ATK_O_X - cx), ATK_EXP_CY + k * (ATK_O_Y - cy)
	local dx, dy = k * (px - ATK_O_X), k * (py - ATK_O_Y)
	local d = math.sqrt(dx * dx + dy * dy)
	if d < 1e-9 then return nil end
	local lx, ly = ATK_EXP_HX - ATK_EXP_PAD / 2, ATK_EXP_HY - ATK_EXP_PAD / 2
	local t0, t1 = 0, 1
	for _, e in ipairs({{-dx, ox - (ATK_EXP_CX - lx)}, {dx, ATK_EXP_CX + lx - ox},
			{-dy, oy - (ATK_EXP_CY - ly)}, {dy, ATK_EXP_CY + ly - oy}}) do
		local p, q = e[1], e[2]
		if math.abs(p) < 1e-12 then
			if q < 0 then return nil end
		elseif p < 0 then t0 = math.max(t0, q / p)
		else t1 = math.min(t1, q / p) end
	end
	if t1 <= t0 then return nil end
	local len = (t1 - t0) * d
	if t1 >= 1 - 1e-9 then len = len - short end
	if len <= 0 then return nil end
	return ox + t0 * dx, oy + t0 * dy, len
end



function atk_exp_line_move(sx, sy, b)
	local h = ATK_EXP_PIECES * ATK_R / ATK_DT_PIECES / 2
	return sx + h * math.sin(b) - ATK_EXP_CX, sy + h * math.cos(b) - ATK_EXP_CY
end


function atk_under_inset(x, y)
	return math.abs(x - ATK_EXP_CX) < ATK_EXP_HX + 0.04 and math.abs(y - ATK_EXP_CY) < ATK_EXP_HY + 0.04
end
