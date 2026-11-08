








dofile(LockOn_Options.common_script_path.."wsTypes_SAM.lua")
dofile(LockOn_Options.common_script_path.."wsTypes_Airplane.lua")
dofile(LockOn_Options.common_script_path.."wsTypes_Ship.lua")
dofile(LockOn_Options.common_script_path.."wsTypes_Missile.lua")
local dev = GetSelf()

local update_time_step = 0.1
make_default_activity(update_time_step)

MaxThreats			= 16
EmitterLiveTime		= 7.0
EmitterSoundTime	= 0.5
LaunchSoundDelay	= 15.0
DefaultType			= 100
RWR_detection_coeff	= 0.85





eyes = {}
eyes[1] = {position = {x = 7.5, y = 0.0, z = 0.6}, orientation = {azimuth = math.rad(45), elevation = 0.0}, field_of_view = math.rad(120)}
eyes[2] = {position = {x = 7.5, y = 0.0, z = -0.6}, orientation = {azimuth = math.rad(-45), elevation = 0.0}, field_of_view = math.rad(120)}
eyes[3] = {position = {x = -8.0, y = 1.0, z = 2.0}, orientation = {azimuth = math.rad(135), elevation = 0.0}, field_of_view = math.rad(120)}
eyes[4] = {position = {x = -8.0, y = 1.0, z = -2.0}, orientation = {azimuth = math.rad(-135), elevation = 0.0}, field_of_view = math.rad(120)}


eyes[5] = {position = {x = 0.0, y = 1.0, z = 0.0}, orientation = {azimuth = 0.0, elevation = math.rad(90)}, field_of_view = math.rad(120)}
eyes[6] = {position = {x = 0.0, y = -1.0, z = 0.0}, orientation = {azimuth = 0.0, elevation = math.rad(-90)}, field_of_view = math.rad(120)}

local function param(name) return get_param_handle(name) end
local function num(h) local v = h:get() return type(v) == "number" and v or (tonumber(v) or 0) end
local power = param("RWR_POWER")
local E = {systems = param("EFM_SYSTEMS"), ess = param("EFM_ELEC_ESS")}
local powered = nil

local function dcs_log(s)
	if log and log.info then tostring("F15EX RWR "..s) else tostring("F15EX RWR "..s) end
end

function post_initialize()
end

function SetCommand(command, value)
end


function update()
	local on = num(E.systems) < 0.5 or num(E.ess) > 0.5
	dev:set_power(on)
	power:set(on and 1 or 0)
	if on ~= powered then
		dcs_log("device power "..(on and "ON" or "OFF"))
		powered = on
	end
end




need_to_be_closed = false
