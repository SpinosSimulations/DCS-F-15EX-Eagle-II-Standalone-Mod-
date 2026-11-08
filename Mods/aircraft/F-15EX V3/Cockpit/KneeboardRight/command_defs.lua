start_custom_command   = 10000
local __count_custom = start_custom_command-1
local function __custom_counter()
	__count_custom = __count_custom + 1
	return __count_custom
end

Keys =
{
		
	fcs													= 5000,
	fcs_pitch											= 5001,
	fcs_roll											= 5002,

}

start_command = 3000
local __count = start_command - 1
local function __counter()
	__count = __count + 1
	return __count
end

device_commands = {
}