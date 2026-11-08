





dofile(LockOn_Options.common_script_path.."clickable_common.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."lad_touch_grid.lua")

local gettext = require("i_18n")
_ = gettext.translate



cursor_mode =
{
	CUMODE_CLICKABLE			= 0,
	CUMODE_CLICKABLE_AND_CAMERA	= 1,
	CUMODE_CAMERA				= 2,
}
clickable_mode_initial_status = cursor_mode.CUMODE_CLICKABLE

elements = {}

local TOUCH_ARG = 900

local function touch_cell(idx)
	return {
		class = {class_type.BTN},
		hint = _("LAD"),
		device = devices.AVIONICS,
		action = {device_commands.LadTouch},
		arg = {TOUCH_ARG},
		arg_value = {idx / LAD_TOUCH.VALUE_SCALE},
		arg_lim = {{0, 1}},
		use_release_message = {false},
		use_OBB = true,
	}
end

local T = LAD_TOUCH
for r = 0, T.ROWS do
	for c = 1, T.COLS do
		elements[T.name(r, c)] = touch_cell(r * T.COLS + c)
	end
end
