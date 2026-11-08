



EW_ROT_GAIN		= -1.0



TEWS_MAX		= 16
TEWS_R_DOTS		= 0.66
TEWS_R_ROSE		= 0.86
TEWS_ROSE_LONG	= 0.07
TEWS_ROSE_SHORT	= 0.035
TEWS_R_LABEL	= 0.74
TEWS_R_MIN		= 0.14
TEWS_R_MAX		= 0.80
TEWS_R_EW_MIN	= 0.50
TEWS_R_EDGE		= 0.90
TEWS_ROSE_LABELS = {"N", "3", "6", "E", "12", "15", "S", "21", "24", "W", "30", "33"}
TEWS_SCALES		= {0, 40, 80, 160}





SITP_R			= 0.80
SITP_OFF		= 0.38
SITP_RS			= SITP_R + SITP_OFF
SITP_EDGE		= 0.86
SITP_R_LABEL	= 0.87
SITP_ROSE_LABELS = {"N", "E", "S", "W"}
SITP_SCALES		= {20, 40, 80, 160, 320}
SITP_MAX_TRK	= 24
SITP_MAX_THR	= 16
SITP_MAX_DL		= 32
SITP_STICK_STEPS = 6
SITP_STICK_MPS	= 100.0
SITP_STICK_LEN	= 0.025
SITP_DT_PIECE	= 0.025
SITP_DT_PIECES	= 64
SITP_LINE_HALF	= SITP_DT_PIECES * SITP_DT_PIECE / 2
SITP_MAX_LEG	= 8
SITP_LEG_STEP	= 0.01
SITP_LEG_BITS	= 8
SITP_MAX_STPT	= 9


SITP_RINGS		= {0.03, 0.045, 0.065, 0.09, 0.13, 0.18, 0.25, 0.35, 0.5}
SITP_RING_LIMIT	= 0.97


function ew_xy(brg, r)
	return r * math.sin(brg), r * math.cos(brg)
end


function sitp_inside(x, y, m)
	local dy = y - SITP_OFF
	return math.sqrt(x * x + dy * dy) <= SITP_R - (m or 0)
end

function sitp_edge(brg, e)
	local s, c = math.sin(brg), math.cos(brg)
	local t = SITP_OFF * c + math.sqrt(math.max(0, e * e - SITP_OFF * SITP_OFF * s * s))
	return t * s, t * c
end

function sitp_clip(ax, ay, bx, by)
	local dx, dy = bx - ax, by - ay
	local fx, fy = ax, ay - SITP_OFF
	local A = dx * dx + dy * dy
	if A < 1e-12 then return nil end
	local B = 2 * (fx * dx + fy * dy)
	local C = fx * fx + fy * fy - SITP_R * SITP_R
	local disc = B * B - 4 * A * C
	if disc <= 0 then return nil end
	local q = math.sqrt(disc)
	local t0, t1 = math.max(0, (-B - q) / (2 * A)), math.min(1, (-B + q) / (2 * A))
	if t1 <= t0 then return nil end
	return t0, t1
end




function sitp_exp_xy(x, y, k, cx, cy)
	if k == 1 then return x, y end
	return k * (x - cx), SITP_OFF + k * (y - cy)
end





function sitp_exp_line(x, y, k, cx, cy, short)
	local ox, oy = sitp_exp_xy(0, 0, k, cx, cy)
	local dx, dy = x - ox, y - oy
	local t0, t1 = sitp_clip(ox, oy, x, y)
	if not t0 then return nil end
	local len = (t1 - t0) * math.sqrt(dx * dx + dy * dy)
	if t1 >= 1 - 1e-9 then len = len - short end
	if len <= 0 then return nil end
	return ox + t0 * dx, oy + t0 * dy, len
end



function sitp_line_move(sx, sy, b)
	return sx + SITP_LINE_HALF * math.sin(b), sy + SITP_LINE_HALF * math.cos(b) - SITP_OFF
end


function tews_power_r(power, ew)
	local p = math.max(0, math.min(1, power or 0))
	local r = TEWS_R_MAX - p * (TEWS_R_MAX - TEWS_R_MIN)
	if ew then r = math.max(r, TEWS_R_EW_MIN) end
	return r
end


function sitp_ring(lethal_m, scale_m)
	if not lethal_m or lethal_m <= 0 then return 0 end
	local want = lethal_m / scale_m * SITP_RS
	if want < SITP_RINGS[1] * 0.7 or want > SITP_RINGS[#SITP_RINGS] * 1.3 then return 0 end
	local best, bd = 0, 1e9
	for i, r in ipairs(SITP_RINGS) do
		local d = math.abs(math.log(r / want))
		if d < bd then best, bd = i, d end
	end
	return best
end
