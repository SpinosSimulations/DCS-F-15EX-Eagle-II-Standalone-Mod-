





TF_SCOPE = {
	X0 = -0.66, X1 = 0.66,
	Y_SCALE = -0.56,
	Y_FV = -0.05,
	K_DEG = 0.024,
	TOP = 0.40,
	N = 40,

	TICKS = {{0, 0}, {1, 0.327}, {2, 0.495}, {4, 0.695}, {6, 0.832}, {10, 1.0}},
	SYN_NM = 6,
	RAW_NM = 10,
	HIDE = 9,
	DASH = 0.050,
	RAW_W = 0.030, RAW_H = 0.060,
	DOT = 0.012,
	EVERY = 2,

	CUE_X = -0.45, CUE_Y = 0.52, CUE_K = 0.012, CUE_MAX = 0.16,

	ANT_X = 0.48, ANT_Y = 0.58, ANT_STEP = 0.075,
}


function TF_SCOPE.frac(r)
	local T = TF_SCOPE.TICKS
	if r <= 0 then return 0 end
	for i = 2, #T do
		if r <= T[i][1] then
			local a, b = T[i - 1], T[i]
			return a[2] + (b[2] - a[2]) * (r - a[1]) / (b[1] - a[1])
		end
	end
	return 1
end
function TF_SCOPE.nm(f)
	local T = TF_SCOPE.TICKS
	if f <= 0 then return 0 end
	for i = 2, #T do
		if f <= T[i][2] then
			local a, b = T[i - 1], T[i]
			return a[1] + (b[1] - a[1]) * (f - a[2]) / (b[2] - a[2])
		end
	end
	return T[#T][1]
end
function TF_SCOPE.x(r) return TF_SCOPE.X0 + (TF_SCOPE.X1 - TF_SCOPE.X0) * TF_SCOPE.frac(r) end

function TF_SCOPE.col_f(k) return (k - 0.5) / TF_SCOPE.N end
function TF_SCOPE.col_x(k) return TF_SCOPE.X0 + (TF_SCOPE.X1 - TF_SCOPE.X0) * TF_SCOPE.col_f(k) end
function TF_SCOPE.col_nm(k) return TF_SCOPE.nm(TF_SCOPE.col_f(k)) end

function TF_SCOPE.y(e_deg)
	local S = TF_SCOPE
	local y = S.Y_FV + e_deg * S.K_DEG
	if y < S.Y_SCALE or y > S.TOP then return S.HIDE end
	return y
end

function TF_SCOPE.on_plot(param) return {param, TF_SCOPE.Y_SCALE - 1e-6, TF_SCOPE.TOP + 1e-6} end



TF_SUBMODES = {"NORM", "ECCM", "WX1", "WX2", "LPI", "VLC"}
TF_SUB_PB = {[1] = 6, [2] = 7, [3] = 8, [4] = 8, [5] = 9, [6] = 10}
TF_CLR_PB = {[100] = 1, [200] = 20, [300] = 19, [400] = 18, [500] = 17, [1000] = 16}
