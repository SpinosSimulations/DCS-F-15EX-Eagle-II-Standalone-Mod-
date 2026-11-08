mount_vfs_texture_archives("Bazar/Textures/AvionicsCommon")
dofile(LockOn_Options.common_script_path.."tools.lua")
dofile(LockOn_Options.script_path.."devices.lua")


attributes = {
	"support_for_cws",
}


layoutGeometry = {}


creators = {}
creators[devices.SYSTEM] = {"avLuaDevice",LockOn_Options.script_path.."SYSTEM.lua"}

indicators = {}

disable_kneeboard_render_target = false
dofile(LockOn_Options.common_script_path.."KNEEBOARD/declare_kneeboard_device.lua")