





dofile(LockOn_Options.script_path.."devices.lua")
local dev = GetSelf()



GUI = {}




interphone = {
	interphone = true,
}
local function dcs_log(s) if log and log.info then tostring("F15EX RADIO "..s) else tostring("F15EX RADIO "..s) end end

if make_default_activity then
	make_default_activity(1.0)
end

local function call(name, ...)
	if type(dev[name]) ~= "function" then return "MISSING" end
	local ok, err = pcall(dev[name], dev, ...)
	return ok and "ok" or tostring(err)
end


function post_initialize()
	dcs_log("INTERCOM set_communicator R1: " .. call("set_communicator", devices.UHF1_RADIO) ..
		", R2: " .. call("set_communicator", devices.UHF2_RADIO) ..
		", make_setup_for_communicator: " .. call("make_setup_for_communicator"))

	local hex = tostring(dev.link):match("(%x+)$")
	get_param_handle("F15EX_IC_PTR"):set("p" .. (hex or ""))
	dcs_log("INTERCOM up (avIntercom), pointer " .. (hex and "sent" or "MISSING"))
end

function SetCommand(command, value)
end

function update()
end

need_to_be_closed = false
