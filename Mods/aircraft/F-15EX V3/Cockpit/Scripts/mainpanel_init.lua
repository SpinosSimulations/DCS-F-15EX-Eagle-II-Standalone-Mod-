



shape_name			= get_aircraft_type() == "F15IA" and "Cockpit_F15IA_LAD" or "Cockpit_F15EX_LAD"
is_EDM				= true
new_model_format	= true
draw_pilot			= false


cockpit_local_point	= {6.377, 1.220, 0.000}

external_model_canopy_arg	= 38






mirrors_data =
{
	center_point	= {0.59, 0.065, 0.0},
	width			= 0.80,
	aspect			= 2.5,
	rotation		= 0.0,
	animation_speed	= 2.0,
	near_clip		= 0.1,
	middle_clip		= 10,
	far_clip		= 60000,
}

day_texture_set_value		= 0.0
night_texture_set_value		= 0.1
dusk_border					= 0.4

ambient_light					= {255, 255, 255}
ambient_color_day_texture		= {72, 100, 160}
ambient_color_night_texture		= {40, 60, 150}
ambient_color_from_devices		= {50, 50, 40}
ambient_color_from_panels		= {35, 25, 25}

local controllers = LoRegisterPanelControls()

local function param_gauge(arg, param, input, output)
	local g			 = CreateGauge("parameter")
	g.arg_number	 = arg
	g.parameter_name = param
	g.input			 = input or {0.0, 1.0}
	g.output		 = output or {0.0, 1.0}
	return g
end




canopy				= CreateGauge("external_arg")
canopy.external_arg	= 38
canopy.arg_number	= 181


canopy.input		= {0.0, 0.05, 0.9}
canopy.output		= {0.0, 0.1144, 0.9496}



mirrors_draw			= CreateGauge()
mirrors_draw.arg_number	= 3
mirrors_draw.input		= {0, 1}
mirrors_draw.output		= {0, 1}
mirrors_draw.controller	= controllers.mirrors_draw




stick_pitch	= param_gauge(74,  "EFM_STICK_PITCH", {-1.0, 1.0}, {-1.0, 1.0})
stick_roll	= param_gauge(71,  "EFM_STICK_ROLL",  {-1.0, 1.0}, {-1.0, 1.0})
pedals		= param_gauge(500, "EFM_PEDAL",       {-1.0, 1.0}, {-1.0, 1.0})
throttle_l	= param_gauge(104, "EFM_THROTTLE_L")
throttle_r	= param_gauge(105, "EFM_THROTTLE_R")




shoot_light	= param_gauge(162, "HUDAA_SHOOT")

need_to_be_closed = true
