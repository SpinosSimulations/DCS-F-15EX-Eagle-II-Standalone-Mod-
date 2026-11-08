























LAD_LAYOUT = {
	X0 = -0.965, X1 = 0.965,

	Y1 = 0.429,
	Y0 = -0.515,
	GAP = 0.012,
	BAND = 0.80,
	SNAP = 0.15,
	MERGE = 0.12,
	N_WIN = 8,
	START = 4,
	LIST = {
		{name = "2 WINDOW L LAYOUT", win = {[1] = {0, 2 / 3, 0, 1}, [2] = {2 / 3, 1, 0, 1}}},
		{name = "2 WINDOW R LAYOUT", win = {[2] = {0, 1 / 3, 0, 1}, [1] = {1 / 3, 1, 0, 1}}},
		{name = "4 WINDOW LAYOUT", win = {[2] = {0, 0.375, 0, 1}, [3] = {0.375, 0.625, 0, 0.5},
			[4] = {0.375, 0.625, 0.5, 1}, [1] = {0.625, 1, 0, 1}}},
		{name = "5 WINDOW LAYOUT", win = {[2] = {0, 0.25, 0, 0.5}, [3] = {0, 0.25, 0.5, 1}, [1] = {0.25, 0.75, 0, 1},
			[4] = {0.75, 1, 0, 0.5}, [5] = {0.75, 1, 0.5, 1}}},
		{name = "7 WINDOW LAYOUT", win = {[2] = {0, 0.22, 0, 0.55}, [4] = {0.22, 0.50, 0, 0.55}, [1] = {0.50, 1, 0, 0.55},
			[3] = {0, 0.22, 0.55, 1}, [5] = {0.22, 0.44, 0.55, 1}, [6] = {0.44, 0.66, 0.55, 1}, [7] = {0.66, 1, 0.55, 1}}},
		{name = "8 WINDOW LAYOUT", win = {[2] = {0, 0.25, 0, 0.5}, [4] = {0.25, 0.5, 0, 0.5}, [1] = {0.5, 0.75, 0, 0.5},
			[6] = {0.75, 1, 0, 0.5}, [3] = {0, 0.25, 0.5, 1}, [5] = {0.25, 0.5, 0.5, 1}, [7] = {0.5, 0.75, 0.5, 1},
			[8] = {0.75, 1, 0.5, 1}}},
	},
}


function LAD_LAYOUT.rect(l, w)
	local L = LAD_LAYOUT
	local s = L.LIST[l] and L.LIST[l].win[w]
	if not s then return nil end
	local W, H = L.X1 - L.X0, L.Y1 - L.Y0
	return L.X0 + s[1] * W + L.GAP / 2, L.X0 + s[2] * W - L.GAP / 2, L.Y1 - s[4] * H + L.GAP / 2, L.Y1 - s[3] * H - L.GAP / 2
end


local function raw_k(l, w)
	local x0, x1, y0, y1 = LAD_LAYOUT.rect(l, w)
	return x0 and math.min(x1 - x0, y1 - y0) / 2
end


do
	local L = LAD_LAYOUT
	L.K = {}
	for w = 1, L.N_WIN do
		local ks = {}
		for l = 1, #L.LIST do ks[#ks + 1] = raw_k(l, w) end
		table.sort(ks, function(a, b) return a > b end)
		local out = {}
		for _, k in ipairs(ks) do
			if #out == 0 or k < out[#out] * (1 - L.MERGE) - 1e-12 then out[#out + 1] = k
			else out[#out] = k end
		end
		L.K[w] = out
	end
end


function LAD_LAYOUT.class(l, w)
	local k = raw_k(l, w)
	if not k then return 0 end
	for i, ki in ipairs(LAD_LAYOUT.K[w]) do
		if ki <= k + 1e-12 then return i end
	end
	return #LAD_LAYOUT.K[w]
end


function LAD_LAYOUT.content(l, w)
	local x0, x1, y0, y1 = LAD_LAYOUT.rect(l, w)
	if not x0 then return nil end
	return (x0 + x1) / 2, (y0 + y1) / 2, LAD_LAYOUT.K[w][LAD_LAYOUT.class(l, w)]
end


function LAD_LAYOUT.extra(l, w)
	local x0, x1, y0, y1 = LAD_LAYOUT.rect(l, w)
	if not x0 then return 0, 0 end
	local _, _, k = LAD_LAYOUT.content(l, w)
	return (x1 - x0) / 2 - k, (y1 - y0) / 2 - k
end





function LAD_LAYOUT.unband(u, e)
	local B = LAD_LAYOUT.BAND
	local a = math.abs(u)
	local s = u < 0 and -1 or 1
	if a >= B + e then return u - s * e end
	if a > B then
		if a - B <= LAD_LAYOUT.SNAP or B + e - a <= LAD_LAYOUT.SNAP then return s * B end
		return s * 0.5
	end
	return u
end



function LAD_LAYOUT.band_out(u, e)
	if math.abs(u) >= LAD_LAYOUT.BAND then return u + (u < 0 and -e or e) end
	return u
end




LAD_LAYOUT.STRIP = 0.43696
function LAD_LAYOUT.window_at(l, x, y)
	local L = LAD_LAYOUT
	local g = L.GAP / 2 + 1e-9
	for pass = 1, 2 do
		for w = 1, L.N_WIN do
			local x0, x1, y0, y1 = L.rect(l, w)
			if x0 and x >= x0 - g and x <= x1 + g and y >= y0 - g and y <= y1 + g then return w end
		end
		if pass == 2 or y > L.STRIP then return nil end
		x = math.max(L.X0 + g, math.min(L.X1 - g, x))
		y = math.max(L.Y0 + g, math.min(L.Y1 - g, y))
	end
end



LAD_LAYOUT_MENU = {
	X0 = -0.30, X1 = 0.72,
	TOP = 0.75, PITCH = 0.25, H = 0.21,

	TEXT_H = 0.085,
}


function LAD_LAYOUT_MENU.box(k)
	local M = LAD_LAYOUT_MENU
	local yc = M.TOP - (k - 0.5) * M.PITCH
	return M.X0, M.X1, yc - M.H / 2, yc + M.H / 2
end


function LAD_LAYOUT_MENU.at(x, y)
	for k = 1, #LAD_LAYOUT.LIST do
		local x0, x1 = LAD_LAYOUT_MENU.box(k)
		local yc = LAD_LAYOUT_MENU.TOP - (k - 0.5) * LAD_LAYOUT_MENU.PITCH
		if x >= x0 and x <= x1 and math.abs(y - yc) <= LAD_LAYOUT_MENU.PITCH / 2 then return k end
	end
end
