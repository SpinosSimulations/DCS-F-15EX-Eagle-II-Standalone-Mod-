

mount_vfs_texture_archives("Bazar/Textures/AvionicsCommon")
dofile(LockOn_Options.common_script_path.."tools.lua")
dofile(LockOn_Options.script_path.."devices.lua")

MainPanel = {"ccMainPanel", LockOn_Options.script_path.."mainpanel_init.lua"}

layoutGeometry = {}

creators = {}
creators[devices.SYSTEM]	= {"avLuaDevice", LockOn_Options.script_path.."SYSTEM.lua"}
creators[devices.AVIONICS]	= {"avLuaDevice", LockOn_Options.script_path.."AVIONICS.lua"}



creators[devices.ELECTRIC_SYSTEM]	= {"avSimpleElectricSystem", LockOn_Options.script_path.."Systems/ELECTRIC.lua"}
creators[devices.FCR]				= {"avSimpleRadar", LockOn_Options.script_path.."Systems/FCR.lua", {devices.ELECTRIC_SYSTEM}}
creators[devices.WEAPON_SYSTEM]		= {"avSimpleWeaponSystem", LockOn_Options.script_path.."Systems/WEAPONS.lua"}


creators[devices.RWR]				= {"avSimpleRWR", LockOn_Options.script_path.."Systems/RWR.lua"}
creators[devices.TEWS]				= {"avLuaDevice", LockOn_Options.script_path.."Systems/TEWS.lua"}
creators[devices.HUD_AA]			= {"avLuaDevice", LockOn_Options.script_path.."Systems/HUD_AA.lua"}

creators[devices.WARN]				= {"avLuaDevice", LockOn_Options.script_path.."Systems/WARN.lua"}
creators[devices.NAV]				= {"avLuaDevice", LockOn_Options.script_path.."Systems/NAV.lua"}


creators[devices.NVG]				= {"avNightVisionGoggles"}
creators[devices.HMD]				= {"avLuaDevice", LockOn_Options.script_path.."Systems/HMD.lua"}

creators[devices.MISSILES]			= {"avLuaDevice", LockOn_Options.script_path.."Systems/MISSILES.lua"}




creators[devices.INTERCOM]			= {"avIntercom", LockOn_Options.script_path.."Systems/Comms/intercom.lua", {devices.UHF1_RADIO, devices.UHF2_RADIO, devices.ELECTRIC_SYSTEM}}
creators[devices.UHF1_RADIO]		= {"avUHF_ARC_164", LockOn_Options.script_path.."Systems/Comms/arc210_r1.lua", {devices.INTERCOM, devices.ELECTRIC_SYSTEM}}
creators[devices.UHF2_RADIO]		= {"avUHF_ARC_164", LockOn_Options.script_path.."Systems/Comms/arc210_r2.lua", {devices.INTERCOM, devices.ELECTRIC_SYSTEM}}
creators[devices.RADIO]				= {"avLuaDevice", LockOn_Options.script_path.."Systems/RADIO.lua"}





















local displays = LockOn_Options.script_path.."Displays/"
local MFD = {"MFD-PLASHKA-CENTER", "MFD-PLASHKA-DOWN", "MFD-PLASHKA-RIGHT"}
local TEWS = {"TEWS-PLASHKA-CENTER", "TEWS-PLASHKA-DOWN", "TEWS-PLASHKA-RIGHT"}
local RADAR = {"RADAR-PLASHKA-CENTER", "RADAR-PLASHKA-UP", "RADAR-PLASHKA-RIGHT"}
indicators = {}
indicators[#indicators + 1] = {"ccIndicator", displays.."HUD/init.lua", nil,
	{{"ILS-PLASHKA-CENTER", "ILS-PLASHKA-DOWN", "ILS-PLASHKA-RIGHT"}}}
indicators[#indicators + 1] = {"ccIndicator", displays.."LAD_COVER/init.lua", nil,
	{MFD, {sx_l = -0.0067, sy_l = -0.0429, sz_l = -0.0028, sh = 0.0669, sw = 0.1980}}}



for n = 1, 8 do
	indicators[#indicators + 1] = {"ccIndicator", displays.."LAD_W"..n.."/init.lua", nil,
		{MFD, {sx_l = -0.0076, sy_l = -0.0429, sz_l = -0.0028, sh = 0.0669, sw = 0.1980}}}
end
indicators[#indicators + 1] = {"ccIndicator", displays.."EMD_UPPER/init.lua", nil,
	{TEWS, {sx_l = -0.0133, sy_l = -0.0332, sz_l = 0.1576, sh = -0.0304, sw = -0.0468}}}
indicators[#indicators + 1] = {"ccIndicator", displays.."EMD_LOWER/init.lua", nil,
	{TEWS, {sx_l = -0.0133, sy_l = -0.1428, sz_l = 0.1576, sh = -0.0140, sw = -0.0468}}}
indicators[#indicators + 1] = {"ccIndicator", displays.."RSD/init.lua", nil,
	{RADAR, {sx_l = 0.0621, sy_l = -0.2298, sz_l = -0.0800, sh = -0.0459, sw = -0.0543}}}



indicators[#indicators + 1] = {"ccIndicator", displays.."HMD/init.lua", nil}




























































disable_kneeboard_render_target = false
dofile(LockOn_Options.common_script_path.."KNEEBOARD/declare_kneeboard_device.lua")
