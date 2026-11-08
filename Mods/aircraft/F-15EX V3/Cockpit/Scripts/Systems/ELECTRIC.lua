




local dev = GetSelf()

local update_time_step = 0.2
make_default_activity(update_time_step)

local birth = LockOn_Options.init_conditions and LockOn_Options.init_conditions.birth_place
local hot = birth ~= "GROUND_COLD"

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local E = {time = param("EFM_TIME"), systems = param("EFM_SYSTEMS"), ess = param("EFM_ELEC_ESS"),
	gen_l = param("EFM_GEN_L"), gen_r = param("EFM_GEN_R")}

local state = {}
local function set(batt, g1, g2)
	if state.batt ~= batt then dev:DC_Battery_on(batt) state.batt = batt end
	if state.g1 ~= g1 then dev:AC_Generator_1_on(g1) state.g1 = g1 end
	if state.g2 ~= g2 then dev:AC_Generator_2_on(g2) state.g2 = g2 end
end

local function follow()
	if num(E.time) <= 1.0 then
		set(hot, hot, hot)
	elseif num(E.systems) < 0.5 then
		set(true, true, true)
	else
		set(num(E.ess) > 0.5, num(E.gen_l) > 0.5, num(E.gen_r) > 0.5)
	end
end

function post_initialize()
	follow()
end

function SetCommand(command, value)
end


local t = 0
function update()
	t = t + update_time_step
	if t >= 1.0 then t = 0 state = {} end
	follow()
end




need_to_be_closed = false
