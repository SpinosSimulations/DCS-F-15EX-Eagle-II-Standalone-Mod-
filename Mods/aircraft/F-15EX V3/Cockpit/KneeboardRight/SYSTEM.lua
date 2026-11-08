

local dev = GetSelf()

local update_time_step = 0.02

make_default_activity(update_time_step)

local sensor_data = get_base_data()

local birth = LockOn_Options.init_conditions.birth_place


local T = 1
local H = 1
local K = 1

local BYPASS_DOOR_L = 0
local BYPASS_DOOR_R = 0

local RAMP_L = 0
local RAMP_R = 0

local HYDROLIC_VALUE_L = 0
local HYDROLIC_VALUE_R = 0

local RPM_SENSOR_L = 0
local RPM_SENSOR_R = 0
local G_SENSOR = 0
local MACH_SENSOR = 0
local WEIGHT_ON_WHEEL_SENSOR = 0
local IAS_SENSOR = 0
local TAS_SENSOR = 0

local LADDER_POS = 0

local COCKPIT_POS = 0

local DOORS_VALUE = 0
local DOORS_VALUE_L = 0
local DOORS_VALUE_R = 0

local FCS = 5000
local FCS_VALUE = 0

local FCS_PITCH = 5001
local FCS_PITCH_VALUE = 0
local FCS_ROLL = 5002
local FCS_ROLL_VALUE = 0

local PITCH = 2001
local PITCH_VALUE = 0
local ROLL = 2002
local ROLL_VALUE = 0


dev:listen_command(5000)
dev:listen_command(5001)
dev:listen_command(5002)

dev:listen_command(301)
dev:listen_command(302)
dev:listen_command(303)
dev:listen_command(71)


function post_initialize()
	if birth == "GROUND_COLD" then
		set_aircraft_draw_argument_value(91, 0.9)
		LADDER_POS = 0.9
		COCKPIT_POS = 1
	else
		COCKPIT_POS = 0
	end
	FCS_VALUE = 1
end


function SetCommand(command, value)

	if command == 301	then 
		K = 1 - K		
		if K == 1 then
			print_message_to_user("CAS ROLL Enabled")
		else
			print_message_to_user("CAS ROLL Disabled")		
		end
	end
	
	if command == 302	then 
		H = 1 - H
		if H == 1 then
			print_message_to_user("CAS YAW Enabled")
		else
			print_message_to_user("CAS YAW Disabled")		
		end
	end
	
	if command == 303	then 
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
		
		

	if command == FCS	then 
		FCS_VALUE = 1 - FCS_VALUE
		if FCS_VALUE == 0	then
			print_message_to_user("FCS disabled")
		elseif FCS_VALUE == 1	then
			print_message_to_user("FCS enabled")	
		end	
	end


	if command == FCS_PITCH	then
        FCS_PITCH_VALUE = value
	end
	
    if command == FCS_ROLL	then
        FCS_ROLL_VALUE = value			
    end
		
end


function sensor_data_check()
	RPM_SENSOR_L = sensor_data.getEngineLeftRPM()
	RPM_SENSOR_R = sensor_data.getEngineRightRPM()
	G_SENSOR = sensor_data.getVerticalAcceleration()
	MACH_SENSOR = sensor_data.getMachNumber()
	WEIGHT_ON_WHEEL_SENSOR = (sensor_data:getWOW_RightMainLandingGear() + sensor_data:getWOW_LeftMainLandingGear() + sensor_data:getWOW_NoseLandingGear())
	IAS_SENSOR = sensor_data.getIndicatedAirSpeed()
	TAS_SENSOR = math.floor(sensor_data.getTrueAirSpeed()*1.94384)
end


function hydraulics()
	HYDROLIC_VALUE_L = (RPM_SENSOR_L >= 40)	
    HYDROLIC_VALUE_R = (RPM_SENSOR_R >= 40)	
end


function wings_bending()

	if G_SENSOR > 0	then
		set_aircraft_draw_argument_value(338, G_SENSOR * 0.10)
		set_aircraft_draw_argument_value(339, G_SENSOR * 0.10)   
	end
	
	if G_SENSOR == 0	then
		set_aircraft_draw_argument_value(338, 0)
		set_aircraft_draw_argument_value(339, 0)
	end
	
	if G_SENSOR < 0	then
		set_aircraft_draw_argument_value(338, G_SENSOR * 0.2)
		set_aircraft_draw_argument_value(339, G_SENSOR * 0.2)
	end
	
end


function intake_ramp()

    if HYDROLIC_VALUE_L then
		if MACH_SENSOR < 0.85 and RAMP_L ~= 0.0 then
			RAMP_L = RAMP_L - 0.01
		elseif MACH_SENSOR <= 1.2 then
			RAMP_L = (MACH_SENSOR - 0.85) / 0.35 * 0.4
		elseif MACH_SENSOR <= 2.3 then
			RAMP_L = 0.4 + (MACH_SENSOR - 1.2) / 1.1 * 0.6
		end
		
	elseif RAMP_L ~= 0 then
		RAMP_L = RAMP_L - 0.01
	end
	
	RAMP_L = math.max(0, math.min(1, RAMP_L))
	set_aircraft_draw_argument_value(276, RAMP_L)

    if HYDROLIC_VALUE_R then
		if MACH_SENSOR < 0.85 and RAMP_R ~= 0.0 then
			RAMP_R = RAMP_R - 0.01
		elseif MACH_SENSOR <= 1.2 then
			RAMP_R = (MACH_SENSOR - 0.85) / 0.35 * 0.4
		elseif MACH_SENSOR <= 2.3 then
			RAMP_R = 0.4 + (MACH_SENSOR - 1.2) / 1.1 * 0.6
		end
		
	elseif RAMP_R ~= 0 then
		RAMP_R = RAMP_R - 0.01
	end

	RAMP_R = math.max(0, math.min(1, RAMP_R))
	set_aircraft_draw_argument_value(277, RAMP_R)
	
end


function intake_bypass()

	if HYDROLIC_VALUE_L then
        if MACH_SENSOR <= 0.101 and BYPASS_DOOR_L ~= 1.0  then
            BYPASS_DOOR_L = BYPASS_DOOR_L + 0.01
        elseif MACH_SENSOR <= 0.5 then
            BYPASS_DOOR_L = BYPASS_DOOR_L + ((1.0 - (MACH_SENSOR - 0.101) * 2.5) - BYPASS_DOOR_L) * 0.02
        elseif MACH_SENSOR <= 1.4 then
            BYPASS_DOOR_L = BYPASS_DOOR_L + (0.0 - BYPASS_DOOR_L) * 0.02
        elseif MACH_SENSOR <= 2.2 then
            BYPASS_DOOR_L = BYPASS_DOOR_L + (((MACH_SENSOR - 1.4) * 0.625) - BYPASS_DOOR_L) * 0.02
        else
            BYPASS_DOOR_L = BYPASS_DOOR_L + (0.5 - BYPASS_DOOR_L) * 0.02
        end
	
	elseif BYPASS_DOOR_L ~= 0 then
		BYPASS_DOOR_L = BYPASS_DOOR_L - 0.01
	end
	
	BYPASS_DOOR_L = math.max(0, math.min(1, BYPASS_DOOR_L))
	set_aircraft_draw_argument_value(278, BYPASS_DOOR_L)
	
	
	if HYDROLIC_VALUE_R then
        if MACH_SENSOR <= 0.101 and BYPASS_DOOR_R ~= 1.0 then
            BYPASS_DOOR_R = BYPASS_DOOR_R + 0.01
        elseif MACH_SENSOR <= 0.5 then
            BYPASS_DOOR_R = BYPASS_DOOR_R + ((1.0 - (MACH_SENSOR - 0.101) * 2.5) - BYPASS_DOOR_R) * 0.02
        elseif MACH_SENSOR <= 1.4 then
            BYPASS_DOOR_R = BYPASS_DOOR_R + (0.0 - BYPASS_DOOR_R) * 0.02
        elseif MACH_SENSOR <= 2.2 then
            BYPASS_DOOR_R = BYPASS_DOOR_R + (((MACH_SENSOR - 1.4) * 0.625) - BYPASS_DOOR_R) * 0.02
        else
            BYPASS_DOOR_R = BYPASS_DOOR_R + (0.5 - BYPASS_DOOR_R) * 0.02
        end
	
	elseif BYPASS_DOOR_R ~= 0 then
		BYPASS_DOOR_R = BYPASS_DOOR_R - 0.01
	end	
	
	BYPASS_DOOR_R = math.max(0, math.min(1, BYPASS_DOOR_R))	
	set_aircraft_draw_argument_value(279, BYPASS_DOOR_R)
	
end


function ladder()
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


function gears_doors()

	local FRONT_GEAR_DOOR = get_aircraft_draw_argument_value(0)
	local RIGHT_GEAR_DOOR = get_aircraft_draw_argument_value(3)
	local LEFT_GEAR_DOOR = get_aircraft_draw_argument_value(5)

	if FRONT_GEAR_DOOR then
		DOORS_VALUE = (FRONT_GEAR_DOOR * 5)
		DOORS_VALUE = math.max(0, math.min(1, DOORS_VALUE))
		set_aircraft_draw_argument_value(117, DOORS_VALUE )
	elseif FRONT_GEAR_DOOR == 0 and DOORS_VALUE > 0 then
		DOORS_VALUE = 0
		set_aircraft_draw_argument_value(117, 0)
	end

	if RIGHT_GEAR_DOOR then
		DOORS_VALUE_R = (FRONT_GEAR_DOOR * 11)
		DOORS_VALUE_R = math.max(0, math.min(1, DOORS_VALUE_R))
		set_aircraft_draw_argument_value(115, DOORS_VALUE_R )
	elseif RIGHT_GEAR_DOOR == 0 and DOORS_VALUE_R > 0 then
		DOORS_VALUE_R = 0
		set_aircraft_draw_argument_value(115, 0)
	end

	if LEFT_GEAR_DOOR then
		DOORS_VALUE_L = (FRONT_GEAR_DOOR * 11)
		DOORS_VALUE_L = math.max(0, math.min(1, DOORS_VALUE_L))
		set_aircraft_draw_argument_value(116, DOORS_VALUE_L )
	elseif LEFT_GEAR_DOOR == 0 and DOORS_VALUE_L > 0 then
		DOORS_VALUE_L = 0
		set_aircraft_draw_argument_value(116, 0)
	end
end


function fcs()
	

	if FCS_VALUE == 1 then
		dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
		dispatch_action(nil, ROLL, FCS_ROLL_VALUE)
		return
	end

	if FCS_VALUE == 1 then
	
		if FCS_PITCH_VALUE == 0 then
			dispatch_action(nil, PITCH, 0)
		end

		if FCS_ROLL_VALUE == 0 then
			dispatch_action(nil, ROLL, 0)	
		end		
		
		if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then

			if TAS_SENSOR >= 1350 and TAS_SENSOR < 1620 then
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then			
					FCS_PITCH_VALUE = math.max(-0.35, math.min(0.35, FCS_PITCH_VALUE))
					FCS_ROLL_VALUE = math.max(-0.35, math.min(0.35, FCS_ROLL_VALUE))
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)	
				end	
			end		
			
			if TAS_SENSOR >= 1080 and TAS_SENSOR < 1350 then
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then			
					FCS_PITCH_VALUE = math.max(-0.5, math.min(0.5, FCS_PITCH_VALUE))
					FCS_ROLL_VALUE = math.max(-0.5, math.min(0.5, FCS_ROLL_VALUE))
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)	
				end	
			end					

			if TAS_SENSOR >= 810 and TAS_SENSOR < 1080 then
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then			
					FCS_PITCH_VALUE = math.max(-0.6, math.min(0.6, FCS_PITCH_VALUE))
					FCS_ROLL_VALUE = math.max(-0.75, math.min(0.75, FCS_ROLL_VALUE))
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)	
				end	
			end			
				
			if TAS_SENSOR >= 675 and TAS_SENSOR < 810 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.65, math.min(0.65, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-0.85, math.min(0.85, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end
			
			if TAS_SENSOR >= 567 and TAS_SENSOR < 675 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.70, math.min(0.70, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-0.9, math.min(0.9, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end			
			
			if TAS_SENSOR < 567 and TAS_SENSOR >= 459 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.75, math.min(0.75, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-0.9, math.min(0.9, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end		

			if TAS_SENSOR < 459 and TAS_SENSOR >= 405 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.8, math.min(0.8, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-0.9, math.min(0.9, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end		

			if TAS_SENSOR < 405 and TAS_SENSOR >= 351 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.85, math.min(0.85, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-0.9, math.min(0.9, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end					
			
			if TAS_SENSOR < 351 and TAS_SENSOR >= 243 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-0.9, math.min(0.9, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-1, math.min(1, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end		
			
			if TAS_SENSOR < 243 and TAS_SENSOR >= 0 then	
				if FCS_PITCH_VALUE ~= 0 or FCS_ROLL_VALUE ~= 0 then
					FCS_PITCH_VALUE = math.max(-1, math.min(1, FCS_PITCH_VALUE))		
					FCS_ROLL_VALUE = math.max(-1, math.min(1, FCS_ROLL_VALUE))		
					dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
					dispatch_action(nil, ROLL, FCS_ROLL_VALUE)			
				end	
			
			end										
			
		end
		
	end	
		
	
	if FCS_VALUE == 0 then
	
		dispatch_action(nil, PITCH, FCS_PITCH_VALUE)
		dispatch_action(nil, ROLL, FCS_ROLL_VALUE)	
		
	end

end
	

function update()

	sensor_data_check()
	hydraulics()




	ladder()
	gears_doors()
	fcs()
	
end


need_to_be_closed = false


