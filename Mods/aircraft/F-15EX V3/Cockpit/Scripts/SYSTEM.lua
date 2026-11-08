







local dev = GetSelf()

local update_time_step = 0.02
make_default_activity(update_time_step)

local sensor_data = get_base_data()
local birth = LockOn_Options.init_conditions.birth_place


local T = 1
local H = 1
local K = 1

local WEIGHT_ON_WHEEL_SENSOR = 0
local IAS_SENSOR = 0

local LADDER_POS = 0

local COCKPIT_POS = 0




local CANOPY_TRAVEL_S = 6.0
local CANOPY_ARG_OPEN = 0.9
local canopy_pos = 0
local canopy_param = get_param_handle("CANOPY_POS")




local FCS = 5000
local FCS_VALUE = 0

local FCS_PITCH = 5001
local FCS_PITCH_VALUE = 0
local FCS_ROLL = 5002
local FCS_ROLL_VALUE = 0

local PITCH = 2001
local ROLL = 2002


dev:listen_command(5000)
dev:listen_command(5001)
dev:listen_command(5002)

dev:listen_command(301)
dev:listen_command(302)
dev:listen_command(303)
dev:listen_command(71)









local CMD_NAV_LIGHTS = 175
local CMD_GEAR_LIGHT = 328
local CMD_ANTICOLL = 518
local CMD_FORMATION = 521
dev:listen_command(CMD_NAV_LIGHTS)
dev:listen_command(CMD_GEAR_LIGHT)
dev:listen_command(CMD_ANTICOLL)
dev:listen_command(CMD_FORMATION)
local CMD_FLOOD, CMD_AAR, CMD_MASTER = 3120, 3121, 3122
dev:listen_command(CMD_FLOOD)
dev:listen_command(CMD_AAR)
dev:listen_command(CMD_MASTER)
local STROBE = {period = 1.0, on = 0.12}

local NAV_STEPS = {0, 1.0, 0.3}
local FORMATION_STEPS = {0, 1.0, 0.5}
local GEAR_LIGHT_NAMES = {[0] = "OFF", "TAXI", "LANDING"}
local lights = {nav = 1, gear = 0, anticoll = false, formation = 1, flood = false, aar = false, master = true,
	strobe_t = 0}
local light_params = {systems = get_param_handle("EFM_SYSTEMS"), ac = get_param_handle("EFM_ELEC_AC"),
	gear = get_param_handle("EFM_GEAR_POS"),

	nav = get_param_handle("LIGHT_NAV"), acol = get_param_handle("LIGHT_ACOL"), form = get_param_handle("LIGHT_FORM"),
	gear_sw = get_param_handle("LIGHT_GEAR"), flood = get_param_handle("LIGHT_FLOOD"), aar = get_param_handle("LIGHT_AAR"),
	master = get_param_handle("LIGHT_MASTER"), power = get_param_handle("LIGHT_POWER")}


local function set_canopy(pos)
	canopy_pos = pos
	set_aircraft_draw_argument_value(38, canopy_pos * CANOPY_ARG_OPEN)
	canopy_param:set(canopy_pos)
end


function post_initialize()
	if birth == "GROUND_COLD" then
		set_aircraft_draw_argument_value(91, 0.9)
		LADDER_POS = 0.9
		COCKPIT_POS = 1
	else
		COCKPIT_POS = 0
	end
	set_canopy(COCKPIT_POS)
	FCS_VALUE = 1
end


function SetCommand(command, value)

	if command == 301 then
		K = 1 - K
		if K == 1 then
			print_message_to_user("CAS ROLL Enabled")
		else
			print_message_to_user("CAS ROLL Disabled")
		end
	end

	if command == 302 then
		H = 1 - H
		if H == 1 then
			print_message_to_user("CAS YAW Enabled")
		else
			print_message_to_user("CAS YAW Disabled")
		end
	end

	if command == 303 then
		T = 1 - T
		if T == 1 then
			print_message_to_user("CAS PITCH Enabled")
		else
			print_message_to_user("CAS PITCH Disabled")
		end
	end

	if command == 71 then
		COCKPIT_POS = 1 - COCKPIT_POS
	end

	if command == CMD_NAV_LIGHTS then
		lights.nav = lights.nav % #NAV_STEPS + 1
		print_message_to_user("NAV LIGHTS " .. ({"OFF", "BRIGHT", "DIM"})[lights.nav])
	elseif command == CMD_GEAR_LIGHT then
		lights.gear = (lights.gear + 1) % 3
		print_message_to_user("GEAR LIGHT " .. GEAR_LIGHT_NAMES[lights.gear])
	elseif command == CMD_ANTICOLL then
		lights.anticoll = not lights.anticoll
		print_message_to_user("ANTI-COLLISION " .. (lights.anticoll and "ON" or "OFF"))
	elseif command == CMD_FORMATION then
		lights.formation = lights.formation % #FORMATION_STEPS + 1
		print_message_to_user("FORMATION LIGHTS " .. ({"OFF", "BRIGHT", "DIM"})[lights.formation])
	elseif command == CMD_FLOOD then
		lights.flood = not lights.flood
		print_message_to_user("FLOOD LIGHTS " .. (lights.flood and "ON" or "OFF"))
	elseif command == CMD_AAR then
		lights.aar = not lights.aar
		print_message_to_user("AAR LIGHTS " .. (lights.aar and "ON" or "OFF"))
	elseif command == CMD_MASTER then
		lights.master = not lights.master
		print_message_to_user("EXT LIGHTS MASTER " .. (lights.master and "ON" or "OFF"))
	end

	if command == FCS then
		FCS_VALUE = 1 - FCS_VALUE
		if FCS_VALUE == 0 then
			print_message_to_user("FCS disabled")
		elseif FCS_VALUE == 1 then
			print_message_to_user("FCS enabled")
		end
	end

	if command == FCS_PITCH then
		FCS_PITCH_VALUE = value
	end

	if command == FCS_ROLL then
		FCS_ROLL_VALUE = value
	end

end


local function sensor_data_check()
	WEIGHT_ON_WHEEL_SENSOR = (sensor_data:getWOW_RightMainLandingGear() + sensor_data:getWOW_LeftMainLandingGear() + sensor_data:getWOW_NoseLandingGear())
	IAS_SENSOR = sensor_data.getIndicatedAirSpeed()
end


local function canopy()
	if canopy_pos ~= COCKPIT_POS then
		local step = update_time_step / CANOPY_TRAVEL_S
		if COCKPIT_POS > canopy_pos then
			set_canopy(math.min(COCKPIT_POS, canopy_pos + step))
		else
			set_canopy(math.max(COCKPIT_POS, canopy_pos - step))
		end
	end
end



local function ladder()
	if LADDER_POS > 0 and WEIGHT_ON_WHEEL_SENSOR and COCKPIT_POS == 0 then
		LADDER_POS = LADDER_POS - 0.01
		LADDER_POS = math.max(0, math.min(0.9, LADDER_POS))
		set_aircraft_draw_argument_value(91, LADDER_POS)
	elseif LADDER_POS < 0.9 and WEIGHT_ON_WHEEL_SENSOR and COCKPIT_POS == 1 and IAS_SENSOR == 0 then
		LADDER_POS = LADDER_POS + 0.01
		LADDER_POS = math.max(0, math.min(0.9, LADDER_POS))
		set_aircraft_draw_argument_value(91, LADDER_POS)
	end
end



local function fcs()
	dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
	dispatch_action(nil, ROLL, FCS_ROLL_VALUE)
end


local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end

local function exterior_lights()

	local ac = (num(light_params.systems) < 0.5 or num(light_params.ac) > 0.5) and 1 or 0
	local power = lights.master and ac or 0
	local nav = NAV_STEPS[lights.nav] * power
	set_aircraft_draw_argument_value(190, nav)
	set_aircraft_draw_argument_value(191, nav)
	set_aircraft_draw_argument_value(192, nav)
	local gear_down = num(light_params.gear) > 0.95 and 1 or 0
	set_aircraft_draw_argument_value(208, (lights.gear == 1 and 1 or 0) * gear_down * power)
	set_aircraft_draw_argument_value(209, (lights.gear == 2 and 1 or 0) * gear_down * power)
	lights.strobe_t = (lights.strobe_t + update_time_step) % STROBE.period
	local flash = (lights.anticoll and lights.strobe_t < STROBE.on) and power or 0
	set_aircraft_draw_argument_value(198, flash)
	set_aircraft_draw_argument_value(199, flash)
	local form = FORMATION_STEPS[lights.formation] * power
	set_aircraft_draw_argument_value(88, form)
	for arg = 200, 205 do set_aircraft_draw_argument_value(arg, form) end
	set_aircraft_draw_argument_value(206, (lights.flood and 1 or 0) * power)
	set_aircraft_draw_argument_value(210, (lights.aar and 1 or 0) * power)
	light_params.nav:set(lights.nav)
	light_params.acol:set(lights.anticoll and 2 or 1)
	light_params.form:set(lights.formation)
	light_params.gear_sw:set(lights.gear + 1)
	light_params.flood:set(lights.flood and 2 or 1)
	light_params.aar:set(lights.aar and 2 or 1)
	light_params.master:set(lights.master and 2 or 1)
	light_params.power:set(ac)
end


function update()
	sensor_data_check()
	canopy()
	ladder()
	fcs()
	exterior_lights()
end





need_to_be_closed = false
