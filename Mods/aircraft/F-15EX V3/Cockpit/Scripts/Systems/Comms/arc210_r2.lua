



dofile(LockOn_Options.common_script_path..'Radio.lua')
dofile(LockOn_Options.common_script_path.."mission_prepare.lua")

local gettext = require("i_18n")
_ = gettext.translate

local dev = GetSelf()

device_timer_dt = 0.2

presets = {}

innerNoise			= getInnerNoise(2.5E-6, 10.0)
frequency_accuracy	= 500.0
band_width			= 12E3
power				= 10.0

goniometer = {isLagElement = true, T1 = 0.3, bias = {{valmin = math.rad(0), valmax = math.rad(360), bias = math.rad(1)}}}

agr = {
	input_signal_deviation		= rangeUtoDb(4E-6, 0.5),
	output_signal_deviation		= 5 - (-4),
	input_signal_linear_zone	= 10.0,
	regulation_time				= 0.25,
}

GUI = {
	range = {min = 30E6, max = 399.975E6, step = 1E3},
	displayName = _('R2 ARC-210'),
	AM = true,
	FM = true,
}

guard_receiver = {
	default_frequency = 121.5E6,
	modulation = 0,
}

staticNoises = {
	{
		effect = {"Aircrafts/Cockpits/Static"},
	},
	{
		filter = {1, 2, 2E6, 3E6},
		effect = {"Aircrafts/Cockpits/Atmospheric"},
	},
}



function post_initialize()
	pcall(dev.set_frequency, dev, 124E6)
	pcall(dev.set_modulation, dev, 0)
	local hex = tostring(dev.link):match("(%x+)$")
	get_param_handle("F15EX_R2_PTR"):set("p" .. (hex or ""))
end

need_to_be_closed = false
