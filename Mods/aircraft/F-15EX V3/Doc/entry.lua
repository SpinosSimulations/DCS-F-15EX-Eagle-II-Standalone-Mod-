self_ID = "F15EX"
declare_plugin(self_ID,
{
image     	 = "FC3.bmp",
installed 	 = true,
dirName	  	 = current_mod_path,
displayName  = _("F-15EX"),
developerName = _("Spino"),

fileMenuName = _("F-15EX"),
update_id        = "F-15EX",
version		 = "2.2",
state		 = "installed",
info		 = _("The F-15EX Eagle II is a recent development of the F-15E Strike Eagle, and intended to replace the USAF's existing fleet of legacy F-15C air superiority fighters.  It can carry up to 22 AIM-120 AMRAAMs thanks to its outer wing pylons and AMBER missile launchers, and features advanced AESA radar, a modernized cockpit, and more powerful engines."),

Skins	=
	{
		{
		    name	= _("F-15EX"),
			dir		= "Theme"
		},
	},
Missions =
	{
		{
			name		    = _("F15EX"),
			dir			    = "Missions",
  		},
	},
LogBook =
	{

		{
			name		= _("F15EX"),
			type		= "F15EX",
		},
	},	
		
InputProfiles =
	{
		["F15EX"] = current_mod_path .. '/Input/F15EX',
	},
})

mount_vfs_model_path	(current_mod_path.."/Shapes")
mount_vfs_liveries_path (current_mod_path.."/Liveries")
mount_vfs_sound_path(current_mod_path .. "/Sounds/")
mount_vfs_texture_path (current_mod_path.."/Textures/F15EX")
mount_vfs_texture_path (current_mod_path.."/Textures/Weapons")
mount_vfs_texture_path (current_mod_path.."/Textures/Cockpit")
mount_vfs_texture_path (current_mod_path.."/Textures/AIM-174B")



local cfg_path = current_mod_path ..  "/FM/config.lua"
dofile(cfg_path)
F15EVSN[1] 				= 'F-15C'
F15EVSN[2] 				= 'F15'
F15EVSN.config_path 	= cfg_path
F15EVSN.old 			= 6
F15EVSN.user_options 	= 'F15EX'

dofile(current_mod_path.."/Views_F15Pit.lua")
make_view_settings('F15EX', ViewSettings, SnapViews)



make_flyable('F15EX',current_mod_path..'/Cockpit/KneeboardRight/', F15EVSN , current_mod_path..'/comm.lua') 


dofile(current_mod_path.."/Weapons/Loadout.lua")
dofile(current_mod_path..'/Sensors/F15EX_Sensors.lua')
dofile(current_mod_path.."/UnitPayloads/F15EX.lua")
dofile(current_mod_path..'/F15EX.lua')

plugin_done()
