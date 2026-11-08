






dofile(LockOn_Options.common_script_path.."elements_defs.lua")
if symbols_locale_included == nil then
	dofile(LockOn_Options.common_script_path.."Fonts/symbols_locale.lua")
end
dofile(LockOn_Options.script_path.."Displays/texture_font_chars.lua")

GREEN	= {0, 255, 0, 255}
WHITE	= {255, 255, 255, 255}
AMBER	= {255, 194, 0, 255}
BLACK	= {0, 0, 0, 255}
RED		= {255, 40, 20, 255}
YELLOW	= {255, 230, 0, 255}
FUEL_GREEN = {60, 220, 40, 255}
CYAN	= {0, 220, 255, 255}





SOI_BLUE = {40, 120, 255, 255}
SOI_DOT = {LEN = 0.006, GAP = 0.006, W = 0.0045, INSET = 0.004}
function soi_frame(window, x0, x1, y0, y1, vis)
	local D = SOI_DOT
	local gates = {{"DISP_SOI", window - 0.5, window + 0.5}}
	for _, g in ipairs(vis or {}) do gates[#gates + 1] = g end
	return dotted_rect(x0 + D.INSET, y0 + D.INSET, x1 - D.INSET, y1 - D.INSET, D.LEN, D.GAP, D.W, SOI_BLUE, nil, gates)
end



function dotted_rect(x0, y0, x1, y1, dot_len, gap, w, rgba, parent, vis)
	local list = {}
	local function side(ax, ay, bx, by)
		local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
		local n = math.max(1, math.floor((len + gap) / (dot_len + gap) + 0.5))
		local pitch = (len + gap) / n
		for i = 0, n - 1 do
			local t0, t1 = i * pitch / len, math.min(1, (i * pitch + dot_len) / len)
			list[#list + 1] = {ax + (bx - ax) * t0, ay + (by - ay) * t0, ax + (bx - ax) * t1, ay + (by - ay) * t1}
		end
	end
	side(x0, y1, x1, y1)
	side(x1, y1, x1, y0)
	side(x1, y0, x0, y0)
	side(x0, y0, x0, y1)
	return segments(list, w, rgba, parent, nil, vis)
end




function touch_mark(window, r)
	local m = node({0, 0}, nil, {"LAD_TOUCH_WX", "LAD_TOUCH_WY"},
		{{"move_left_right_using_parameter", 0, S(1)}, {"move_up_down_using_parameter", 1, S(1)}})
	circle(r, r / 4, WHITE, m, nil, nil, {{"LAD_TOUCH_V", 0.5, 1.5}, {"LAD_TOUCH_WIN", window - 0.5, window + 0.5}})
end




local cur_rgba, mat_rgba = nil, {}
local function dn(rgba)
	cur_rgba = rgba
	return rgba
end

local materials = {}
function material(rgba)
	rgba = dn(rgba)
	local key = table.concat(rgba, ",")
	if not materials[key] then materials[key] = MakeMaterial(nil, rgba) mat_rgba[materials[key]] = rgba end
	return materials[key]
end

local fonts = {}
function font(rgba)
	rgba = dn(rgba)
	local key = table.concat(rgba, ",")
	if not fonts[key] then fonts[key] = MakeFont({used_DXUnicodeFontData = "font_dejavu_lgc_sans_22"}, rgba) mat_rgba[fonts[key]] = rgba end
	return fonts[key]
end




local tex_fonts = {}
function tex_font(rgba, weight)
	rgba = dn(rgba)
	weight = weight or "medium"
	local key = table.concat(rgba, ",").."/"..weight
	if tex_fonts[key] == nil then
		local ok, f = pcall(MakeFont, {
			texture		= LockOn_Options.script_path.."IndicationTextures/"..TEXFONT_WEIGHTS[weight],
			size		= TEXFONT_SIZE,
			resolution	= TEXFONT_RES,
			default		= TEXFONT_RECT,
			chars		= texfont_chars,
		}, rgba, "f15ex_tex_"..weight.."_"..table.concat(rgba, "_"))
		tex_fonts[key] = ok and f or false
		if ok and f then mat_rgba[f] = rgba end
	end
	return tex_fonts[key] or nil
end








XF = nil
local XF_HOME = nil
local function xf_home(pts, pos)
	XF_HOME = nil
	if not XF or not XF.bands or #pts == 0 then return end
	local px, py, B = pos and pos[1] or 0, pos and pos[2] or 0, XF.band
	local sx, sy
	for i, p in ipairs(pts) do
		local x, y = p[1] + px, p[2] + py
		local hx = x >= B and 1 or (x <= -B and -1 or 0)
		local hy = y >= B and 1 or (y <= -B and -1 or 0)
		if i == 1 then sx, sy = hx, hy else
			if hx ~= sx then sx = 0 end
			if hy ~= sy then sy = 0 end
		end
	end
	if sx ~= 0 or sy ~= 0 then XF_HOME = XF.bands[sx..","..sy] end
end
local function xs(v) return XF and v * XF.k or v end
local function xp(p)
	if not XF or not p then return p end
	return {p[1] * XF.k, p[2] * XF.k, p[3]}
end
local function xlist(list)
	if not XF then return list end
	local out = {}
	for i, p in ipairs(list) do out[i] = xp(p) end
	return out
end


function S(page_units)
	return xs(page_units) * GetScale()
end

local serial = 0
local function next_name(prefix)
	serial = serial + 1
	return prefix.."_"..serial
end








COLLIMATED = false
CLIP_LEVEL = nil
FORMAT_VIS = nil
POWER_VIS = nil
NIGHT_TINT = nil



NIGHT_RGB = nil





local night_hue_set = {}
function night_hue(rgba)
	local c = {rgba[1], rgba[2], rgba[3], rgba[4]}
	night_hue_set[c] = true
	return c
end


BRT_PARAM = nil
WINDOW_VIS = nil



SYM_TINT = nil
dofile(LockOn_Options.script_path.."Displays/sym_colors.lua")




local function finish(e, parent, params, ctl)
	local tint = SYM_TINT and cur_rgba and cur_rgba[1] == SYM_TINT.base[1] and cur_rgba[2] == SYM_TINT.base[2]
		and cur_rgba[3] == SYM_TINT.base[3]
	if tint then


		local base = math.max(cur_rgba[1], cur_rgba[2], cur_rgba[3]) * SYM_NIGHT / 255
		local p, c = {}, {}
		for i, v in ipairs(params or {}) do p[i] = v end
		for i, v in ipairs(ctl or {}) do c[i] = v end
		p[#p + 1] = SYM_TINT.param
		for k, col in ipairs(SYM_COLORS) do
			local r, g, b = col.rgb[1], col.rgb[2], col.rgb[3]
			local m = math.max(r, g, b)
			c[#c + 1] = {"change_color_when_parameter_equal_to_number", #p - 1, (k - 1) * 2, r / 255, g / 255, b / 255}
			c[#c + 1] = {"change_color_when_parameter_equal_to_number", #p - 1, (k - 1) * 2 + 1,
				base * r / m, base * g / m, base * b / m}
		end
		params, ctl, cur_rgba = p, c, nil
	end
	if cur_rgba then
		local l = math.max(cur_rgba[1], cur_rgba[2], cur_rgba[3]) * 0.45 / 255
		local p, c = {}, {}
		for i, v in ipairs(params or {}) do p[i] = v end
		for i, v in ipairs(ctl or {}) do c[i] = v end
		local t = NIGHT_TINT or {0, 1, 0}
		if night_hue_set[cur_rgba] then
			local m = math.max(cur_rgba[1], cur_rgba[2], cur_rgba[3])
			t = {(cur_rgba[1] / m) ^ 2, (cur_rgba[2] / m) ^ 2, (cur_rgba[3] / m) ^ 2}
		end
		local n = NIGHT_RGB or {l * t[1], l * t[2], l * t[3]}
		p[#p + 1] = "F15EX_DISP_NIGHT"
		c[#c + 1] = {"change_color_when_parameter_equal_to_number", #p - 1, 1, n[1], n[2], n[3]}
		params, ctl, cur_rgba = p, c, nil
	end
	if BRT_PARAM then
		local p, c = {}, {}
		for i, v in ipairs(params or {}) do p[i] = v end
		for i, v in ipairs(ctl or {}) do c[i] = v end
		p[#p + 1] = BRT_PARAM
		c[#c + 1] = {"opacity_using_parameter", #p - 1}
		params, ctl = p, c
	end
	if FORMAT_VIS or POWER_VIS or WINDOW_VIS then
		local p, c = {}, {}
		for i, v in ipairs(params or {}) do p[i] = v end
		for i, v in ipairs(ctl or {}) do c[i] = v end
		for _, g in ipairs({FORMAT_VIS or false, POWER_VIS or false, WINDOW_VIS or false}) do
			if g then
				p[#p + 1] = g[1]
				c[#c + 1] = {"parameter_in_range", #p - 1, g[2], g[3]}
			end
		end
		params, ctl = p, c
	end
	if params then
		e.element_params = params
		e.controllers = ctl
	end
	e.parent_element = parent and parent.name or (XF and (XF_HOME or XF.root).name) or nil
	XF_HOME = nil
	e.collimated = COLLIMATED
	if CLIP_LEVEL then
		e.h_clip_relation = h_clip_relations.COMPARE
		e.level = CLIP_LEVEL
	end
	e.use_mipfilter = true
	if COLLIMATED then
		e.additive_alpha = true
		e.blend_mode = blend_mode.IBM_REGULAR_ADDITIVE_ALPHA
	end
	Add(e)
	return e
end



local function add_gates(vis, params, ctl)
	if not vis then return end
	for _, g in ipairs(type(vis[1]) == "table" and vis or {vis}) do
		params[#params + 1] = g[1]
		ctl[#ctl + 1] = {"parameter_in_range", #params - 1, g[2], g[3]}
	end
end

local function finish_vis(e, parent, vis)
	if not vis then return finish(e, parent) end
	local p, c = {}, {}
	add_gates(vis, p, c)
	return finish(e, parent, p, c)
end



function node(pos, parent, params, controllers)
	local e = CreateElement "ceSimple"
	e.name = next_name("node")
	cur_rgba = nil
	xf_home({{0, 0}}, pos)
	e.init_pos = xp(pos) or {0, 0}
	return finish(e, parent, params, controllers)
end




function dyn_line(ends, gain, w, rgba, parent, vis)
	local e = CreateElement "ceSimpleLineObject"
	e.name = next_name("dline")
	e.vertices = xlist({{0, 0}, {0, 0.01}})
	e.material = material(rgba)
	e.width = xs(w)
	local g = S(gain)
	local p = {ends[1][1], ends[1][2], ends[2][1], ends[2][2]}
	local c = {{"line_object_set_point_using_parameters", 0, 0, 1, g, g},
		{"line_object_set_point_using_parameters", 1, 2, 3, g, g}}
	add_gates(vis, p, c)
	return finish(e, parent, p, c)
end




function dyn_loop(corners, gain, w, rgba, parent, vis)
	local e = CreateElement "ceSimpleLineObject"
	e.name = next_name("dloop")
	local n, v = #corners, {}
	for i = 0, n do v[i + 1] = {0.01 * (i % n), 0.01 * math.floor((i % n) / 2)} end
	e.vertices = xlist(v)
	e.material = material(rgba)
	e.width = xs(w)
	local g = S(gain)
	local p, at, c = {}, {}, {}
	local function index(name)
		if not at[name] then p[#p + 1] = name; at[name] = #p - 1 end
		return at[name]
	end
	for i = 0, n do
		local k = corners[i % n + 1]
		c[#c + 1] = {"line_object_set_point_using_parameters", i, index(k[1]), index(k[2]), g, g}
	end
	add_gates(vis, p, c)
	return finish(e, parent, p, c)
end






function clip_mask(verts, level)
	level = level or DEFAULT_LEVEL
	local e = CreateElement "ceMeshPoly"
	e.name = next_name("mask")
	e.primitivetype = "triangles"
	e.vertices = xlist(verts)
	e.indices = buildConvexPolyIndices(#verts)
	e.material = material({255, 0, 255, 255})
	e.init_pos = {0, 0}
	e.isvisible = false
	e.change_opacity = false
	e.collimated = false
	e.h_clip_relation = h_clip_relations.REWRITE_LEVEL
	e.level = level
	if XF then


		e.parent_element = XF.root.name
		local p, c, gates = {}, {}, {}
		if FORMAT_VIS then gates[#gates + 1] = FORMAT_VIS end
		if WINDOW_VIS then gates[#gates + 1] = WINDOW_VIS end
		if #gates > 0 then add_gates(gates, p, c) end
		if #p > 0 then
			e.element_params = p
			e.controllers = c
		end
	end
	Add(e)
	CLIP_LEVEL = level
	return e
end







JOIN_BEVEL_DEG = 150
local function end_key(x, y)
	return math.floor(x * 1e5 + 0.5)..","..math.floor(y * 1e5 + 0.5)
end

function segments(list, w, rgba, parent, pos, vis)
	local home
	if XF then
		local k, out, pts = XF.k, {}, {}
		for i, s in ipairs(list) do
			out[i] = {s[1] * k, s[2] * k, s[3] * k, s[4] * k}
			pts[#pts + 1] = {s[1], s[2]}
			pts[#pts + 1] = {s[3], s[4]}
		end
		xf_home(pts, pos)
		home = XF_HOME
		list, w, pos = out, w * k, xp(pos)
	end
	local hw = w / 2
	local segs, ends = {}, {}
	for _, s in ipairs(list) do
		local x1, y1, x2, y2 = s[1], s[2], s[3], s[4]
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		if len > 0 then
			local ux, uy = dx / len, dy / len
			local g = {p = {{x1, y1}, {x2, y2}}, u = {ux, uy}, n = {-uy * hw, ux * hw}}

			g.c = {{{x1 - uy * hw, y1 + ux * hw}, {x1 + uy * hw, y1 - ux * hw}},
				{{x2 - uy * hw, y2 + ux * hw}, {x2 + uy * hw, y2 - ux * hw}}}
			segs[#segs + 1] = g
			for e = 1, 2 do
				local k = end_key(g.p[e][1], g.p[e][2])
				ends[k] = ends[k] or {}
				table.insert(ends[k], {g, e})
			end
		end
	end
	local bevels = {}
	local cos_bevel = math.cos(math.rad(180 - JOIN_BEVEL_DEG))
	for _, at in pairs(ends) do
		if #at == 2 then
			local P = at[1][1].p[at[1][2]]

			local function away(a) local g, e = a[1], a[2] local s = e == 1 and 1 or -1 return g.u[1] * s, g.u[2] * s end
			local ax, ay = away(at[1])
			local bx, by = away(at[2])
			local c = ax * bx + ay * by
			if c > -0.99999 then
				local mx, my = ax + bx, ay + by
				local ml = math.sqrt(mx * mx + my * my)
				mx, my = mx / ml, my / ml
				if c < cos_bevel then
					local L = hw / math.sqrt((1 - c) / 2)
					for _, a in ipairs(at) do
						local g, e = a[1], a[2]
						local inner = g.n[1] * mx + g.n[2] * my > 0 and 1 or 2
						g.c[e][inner] = {P[1] + mx * L, P[2] + my * L}
						g.c[e][3 - inner] = {P[1] - mx * L, P[2] - my * L}
					end
				else
					local outer = {}
					for _, a in ipairs(at) do
						local g, e = a[1], a[2]
						outer[#outer + 1] = g.c[e][(g.n[1] * mx + g.n[2] * my > 0) and 2 or 1]
					end
					bevels[#bevels + 1] = {P, outer[1], outer[2]}
				end
			end
		elseif #at >= 3 then
			for _, a in ipairs(at) do
				local g, e = a[1], a[2]
				local s = e == 1 and -hw or hw
				for side = 1, 2 do
					g.c[e][side] = {g.c[e][side][1] + g.u[1] * s, g.c[e][side][2] + g.u[2] * s}
				end
			end
		end
	end
	local verts, inds = {}, {}
	for _, g in ipairs(segs) do
		local b = #verts
		verts[b + 1] = g.c[1][1]
		verts[b + 2] = g.c[2][1]
		verts[b + 3] = g.c[2][2]
		verts[b + 4] = g.c[1][2]
		for _, i in ipairs({0, 1, 2, 0, 2, 3}) do inds[#inds + 1] = b + i end
	end
	for _, t in ipairs(bevels) do
		local b = #verts
		verts[b + 1], verts[b + 2], verts[b + 3] = t[1], t[2], t[3]
		inds[#inds + 1], inds[#inds + 2], inds[#inds + 3] = b, b + 1, b + 2
	end
	local e = CreateElement "ceMeshPoly"
	e.name = next_name(SEG_PREFIX or "seg")
	e.primitivetype = "triangles"
	e.vertices = verts
	e.indices = inds
	e.material = material(rgba)
	e.init_pos = pos or {0, 0}
	XF_HOME = home
	return finish_vis(e, parent, vis)
end



function tex_rect(file, x0, y0, x1, y1, rgba, vis)
	local e = CreateElement "ceTexPoly"
	e.name = next_name("tex")
	e.vertices = xlist({{x0, y1}, {x1, y1}, {x1, y0}, {x0, y0}})
	e.indices = {0, 1, 2, 0, 2, 3}
	e.tex_coords = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
	e.material = MakeMaterial(LockOn_Options.script_path.."IndicationTextures/"..file, rgba)
	e.init_pos = {0, 0}
	return finish_vis(e, nil, vis)
end






function render_target_rect(mat, x0, y0, x1, y1, vis, additive)
	local e = CreateElement "ceTexPoly"
	e.name = next_name("rtv")
	e.vertices = xlist({{x0, y1}, {x1, y1}, {x1, y0}, {x0, y0}})
	e.indices = {0, 1, 2, 0, 2, 3}
	e.tex_coords = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
	e.material = mat
	e.init_pos = {0, 0}
	e.additive_alpha = additive ~= false
	e.input_space_SRGB = true
	cur_rgba = nil
	return finish_vis(e, XF and XF.under or nil, vis)
end


function poly(verts, rgba, parent, pos, vis, prefix)
	local e = CreateElement "ceMeshPoly"
	e.name = next_name(prefix or "poly")
	e.primitivetype = "triangles"
	e.vertices = xlist(verts)
	e.indices = buildConvexPolyIndices(#verts)
	e.material = material(rgba)
	e.init_pos = xp(pos) or {0, 0}
	xf_home(verts, pos)
	return finish_vis(e, parent, vis)
end


function clip_band(verts, ya, yb)
	local function clip(poly, keep, cross)
		local out = {}
		for i = 1, #poly do
			local p, q = poly[i], poly[i % #poly + 1]
			local kp, kq = keep(p), keep(q)
			if kp then out[#out + 1] = p end
			if kp ~= kq then out[#out + 1] = cross(p, q) end
		end
		return out
	end
	local function at_y(y)
		return function(p, q)
			local t = (y - p[2]) / (q[2] - p[2])
			return {p[1] + t * (q[1] - p[1]), y}
		end
	end
	local band = clip(verts, function(p) return p[2] >= ya end, at_y(ya))
	return clip(band, function(p) return p[2] <= yb end, at_y(yb))
end



function level_fill(verts, param, n, rgba, outline_rgba, w)
	local lo, hi = math.huge, -math.huge
	for _, v in ipairs(verts) do lo, hi = math.min(lo, v[2]), math.max(hi, v[2]) end
	for i = 0, n - 1 do
		local s = clip_band(verts, lo + (hi - lo) * i / n, lo + (hi - lo) * (i + 1) / n)
		if #s >= 3 then poly(s, rgba, nil, nil, {param, (i + 0.5) / n, 1e9}, "fill") end
	end
	local list = {}
	for i, v in ipairs(verts) do
		local u = verts[i % #verts + 1]
		list[#list + 1] = {v[1], v[2], u[1], u[2]}
	end
	return segments(list, w, outline_rgba or WHITE)
end



function background(rgba)
	local a = GetAspect()
	return poly({{-1, a}, {1, a}, {1, -a}, {-1, -a}}, rgba or BLACK, nil, nil, nil, "bg")
end



function rect(x1, y1, x2, y2, w, rgba, parent, vis)
	return segments({{x1, y1, x2, y1}, {x2, y1, x2, y2}, {x2, y2, x1, y2}, {x1, y2, x1, y1}}, w, rgba, parent, nil, vis)
end




function caution_box(x1, y1, x2, y2, rgba, w, outline_rgba, vis, prefix)
	local g = vis and (type(vis[1]) == "table" and vis or {vis}) or {}
	local day, night = {{"F15EX_DISP_NIGHT", -0.5, 0.5}}, {{"F15EX_DISP_NIGHT", 0.5, 1.5}}
	for _, v in ipairs(g) do day[#day + 1] = v night[#night + 1] = v end
	poly({{x1, y1}, {x2, y1}, {x2, y2}, {x1, y2}}, rgba, nil, nil, day, prefix)
	rect(x1, y1, x2, y2, w, outline_rgba, nil, night)
end



CIRCLE_MIN_SIDES = 48

function circle(r, w, rgba, parent, pos, sides, vis)
	local n = math.max(sides or 0, CIRCLE_MIN_SIDES)
	local list = {}
	for i = 0, n - 1 do
		local a1, a2 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
		list[#list + 1] = {r * math.cos(a1), r * math.sin(a1), r * math.cos(a2), r * math.sin(a2)}
	end
	return segments(list, w, rgba, parent, pos, vis)
end


function arc(r, a1, a2, w, rgba, parent, pos, n, vis)
	n = math.max(n or 0, math.ceil(CIRCLE_MIN_SIDES * math.abs(a2 - a1) / (2 * math.pi)))
	local list = {}
	for i = 0, n - 1 do
		local b1, b2 = a1 + (a2 - a1) * i / n, a1 + (a2 - a1) * (i + 1) / n
		list[#list + 1] = {r * math.cos(b1), r * math.sin(b1), r * math.cos(b2), r * math.sin(b2)}
	end
	return segments(list, w, rgba, parent, pos, vis)
end


function dashed_arc(r, a1, a2, w, rgba, parent, pos, n, vis)
	local list = {}
	for i = 0, n - 1, 2 do
		local b1, b2 = a1 + (a2 - a1) * i / n, a1 + (a2 - a1) * (i + 1) / n
		list[#list + 1] = {r * math.cos(b1), r * math.sin(b1), r * math.cos(b2), r * math.sin(b2)}
	end
	return segments(list, w, rgba, parent, pos, vis)
end






GLYPH_WIDTH = 0.35
local function string_element(value, pos, stringdefs, mat, align, parent, param, vis)
	local e = CreateElement "ceStringPoly"
	e.name = next_name("txt")
	e.material = mat
	cur_rgba = mat_rgba[mat]
	e.alignment = align or "CenterCenter"
	e.init_pos = xp(pos)
	xf_home({{0, 0}}, pos)
	e.stringdefs = stringdefs
	local params, ctl = {}, {}
	if param then
		e.formats = {param[2]}
		params[1] = param[1]
		ctl[1] = {"text_using_parameter", 0, 0}
	else
		e.value = value
	end
	add_gates(vis, params, ctl)
	if #params > 0 then return finish(e, parent, params, ctl) end
	return finish(e, parent)
end



function material_text(mat, pos, stringdefs, align, parent, param, vis)
	return string_element(nil, pos, stringdefs, mat, align, parent, param, vis)
end

function dejavu_text(value, pos, h, rgba, align, parent, param, vis)
	return string_element(value, pos, {S(h), GLYPH_WIDTH * S(h), 0, 0}, font(rgba), align, parent, param, vis)
end






TEXT_CAP_RATIO = 0.70
TEXT_WEIGHT = "medium"





HALO_RGBA, HALO_OFS, HALO_EDGE = {0, 0, 0, 255}, 0.06, 0.006
TEXT_HALO = nil
function halo_text(value, pos, h, align, parent, param, vis)
	local c = TEXT_CAP_RATIO * h
	local a = HALO_OFS * c
	for _, d in ipairs({{a, 0}, {-a, 0}, {0, a}, {0, -a}}) do
		tex_text(value, {pos[1] + d[1], pos[2] + d[2], pos[3]}, c, HALO_RGBA, align, parent, param, vis, "bold")
	end
end
function text(value, pos, h, rgba, align, parent, param, vis)
	if TEXT_HALO then
		halo_text(value, pos, h, align, parent, param, vis)
		if TEXT_HALO == "only" then return end
	end
	return tex_text(value, pos, TEXT_CAP_RATIO * h, rgba, align, parent, param, vis, TEXT_WEIGHT)
end








TEXFONT_W_FACTOR = 2
function tex_text(value, pos, h, rgba, align, parent, param, vis, weight)
	local f = tex_font(rgba, weight)
	if not f then return dejavu_text(value, pos, h / TEXT_CAP_RATIO, rgba, align, parent, param, vis) end
	align = align or "CenterCenter"
	local u = h / TEXFONT_CAP
	local x, y = pos[1], pos[2]
	if align:find("^Left") then x = x - TEXFONT_PAD_X * u elseif align:find("^Right") then x = x + TEXFONT_PAD_X * u end
	if align:find("Top$") then y = y + TEXFONT_PAD_Y * u elseif align:find("Bottom$") then y = y - TEXFONT_PAD_Y * u end
	return string_element(value, {x, y, pos[3]}, {S(TEXFONT_RECT_Y * u), TEXFONT_W_FACTOR * S(TEXFONT_RECT_X * u), 0, 0}, f, align, parent,
		param, vis)
end



function alpha_glyph(cx, cy, h, w, rgba, parent, vis)
	local rx, ry = 0.26 * h, 0.30 * h
	local list, n = {}, 8
	for k = 0, n - 1 do
		local a0, a1 = math.rad(40 + 280 * k / n), math.rad(40 + 280 * (k + 1) / n)
		list[#list + 1] = {cx + rx * math.cos(a0), cy + ry * math.sin(a0), cx + rx * math.cos(a1), cy + ry * math.sin(a1)}
	end
	local ux, uy = cx + rx * math.cos(math.rad(40)), cy + ry * math.sin(math.rad(40))
	local lx, ly = cx + rx * math.cos(math.rad(320)), cy + ry * math.sin(math.rad(320))
	list[#list + 1] = {ux, uy, ux + 0.26 * h, cy - 0.34 * h}
	list[#list + 1] = {lx, ly, lx + 0.26 * h, cy + 0.34 * h}
	return segments(list, w, rgba, parent, nil, vis)
end


function test_frame(name, rgba)
	local c = rgba or GREEN
	rect(-0.95, -0.95, 0.95, 0.95, 0.012, c)
	segments({{-0.08, 0.80, 0, 0.92}, {0, 0.92, 0.08, 0.80}}, 0.012, c)
	text(name, {0, 0.66}, 0.10, c)
	text(nil, {-0.88, -0.86}, 0.06, c, "LeftCenter", nil, {"LUA_TIME", "LUA %.1f"})
	text(nil, {0.88, -0.86}, 0.06, c, "RightCenter", nil, {"EFM_TIME", "EFM %.1f"})
end


function placement_frame(name, h, rgba)
	local c = rgba or GREEN
	local a = GetAspect()
	rect(-0.97, -a + 0.03, 0.97, a - 0.03, 0.02, c)
	segments({{-0.12, a - 0.22, 0, a - 0.10}, {0, a - 0.10, 0.12, a - 0.22}}, 0.02, c)
	text(name, {0, 0}, h or 0.16, c)
end
