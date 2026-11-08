



NOCFT_ENABLED = false
dofile(current_mod_path .. "/F15EX_nocft.lua")
local HAVE_NOCFT = NOCFT_ENABLED == true

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
version		 = "3.0",
state		 = "installed",
info		 = _("The F-15EX Eagle II is a recent development of the F-15E Strike Eagle, and intended to replace the USAF's existing fleet of legacy F-15C air superiority fighters.  It can carry up to 22 AIM-120 AMRAAMs thanks to its outer wing pylons and AMBER missile launchers, and features advanced AESA radar, a modernized cockpit, and more powerful engines. Do not redistribute. A new version of the F-15EX, not made or supported by Eagle Dynamics."),

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



binaries = {'F15EX_FM'},



load_immediately = true,
		
InputProfiles =
	{
		["F15EX"] = current_mod_path .. '/Input/F15EX',
		["F15EX_CFT"] = current_mod_path .. '/Input/F15EX',
		["F15IA"] = current_mod_path .. '/Input/F15EX',
	},
})

mount_vfs_model_path	(current_mod_path.."/Shapes")
mount_vfs_liveries_path (current_mod_path.."/Liveries")
mount_vfs_sound_path(current_mod_path .. "/Sounds/")
mount_vfs_texture_path (current_mod_path.."/Textures/F15EX")
mount_vfs_texture_path (current_mod_path.."/Textures/Weapons")
mount_vfs_texture_path (current_mod_path.."/Textures/Cockpit")
mount_vfs_texture_path (current_mod_path.."/Textures/AIM-174B")




local STANDALONE = {F15EX = true, F15EX_CFT = true, F15IA = true}
local function cockpit_path(unit)
	if STANDALONE[unit] then return current_mod_path..'/Cockpit/Scripts/' end
	return current_mod_path..'/Cockpit/KneeboardRight/'
end

local cfg_path = current_mod_path ..  "/FM/config.lua"
dofile(cfg_path)
F15EVSN[1] 				= self_ID
F15EVSN[2] 				= 'F15EX_FM'
F15EVSN.config_path 	= cfg_path
if not STANDALONE['F15EX'] then F15EVSN.old = 6 end
F15EVSN.user_options 	= 'F15EX'

dofile(current_mod_path.."/Views_F15Pit.lua")
if HAVE_NOCFT then
	make_view_settings('F15EX', ViewSettings, SnapViews)



	make_flyable('F15EX', cockpit_path('F15EX'), F15EVSN , current_mod_path..'/comm.lua')
end

local cfg_path = current_mod_path ..  "/FM/config_cft.lua"


dofile(cfg_path)
F15EVSN[1] 				= self_ID
F15EVSN[2] 				= 'F15EX_FM'
F15EVSN.config_path 	= cfg_path
if not STANDALONE['F15EX_CFT'] then F15EVSN.old = 6 end
F15EVSN.user_options 	= 'F15EX_CFT'

dofile(current_mod_path.."/Views_F15Pit.lua")
make_view_settings('F15EX_CFT', ViewSettings, SnapViews)



make_flyable('F15EX_CFT', cockpit_path('F15EX_CFT'), F15EVSN , current_mod_path..'/comm.lua') 

local cfg_path = current_mod_path ..  "/FM/config_cft.lua"


dofile(cfg_path)
F15EVSN[1] 				= self_ID
F15EVSN[2] 				= 'F15EX_FM'
F15EVSN.config_path 	= cfg_path
if not STANDALONE['F15IA'] then F15EVSN.old = 6 end
F15EVSN.user_options 	= 'F15IA'

dofile(current_mod_path.."/Views_F15Pit.lua")
make_view_settings('F15IA', ViewSettings, SnapViews)



make_flyable('F15IA', cockpit_path('F15IA'), F15EVSN , current_mod_path..'/comm.lua') 

dofile(current_mod_path.."/Weapons/Loadout.lua")


do
	local SENSOR_RADAR, SENSOR_RWR = 1, 3
	local RADAR_MULTIROLE = 2
	local ASPECT_HEAD_ON, ASPECT_TAIL_ON = 0, 1
	local HEMISPHERE_UPPER, HEMISPHERE_LOWER = 0, 1
	APG_82 = {
		Name = "AN/APG-82",
		category = SENSOR_RADAR,
		type = RADAR_MULTIROLE,
		scan_volume =
		{
			azimuth = {-70.0, 70.0},
			elevation = {-70.0, 70.0}
		},




		max_measuring_distance = 300000.0,
		scan_period = 0.001,
		air_search = {
			centered_scan_volume =
			{
				azimuth_sector = 45.0,
				elevation_sector = 45.0
			},
			RCS = 1,
			detection_distance =
			{
				[HEMISPHERE_UPPER] =
				{
					[ASPECT_HEAD_ON] = 230000.0,
					[ASPECT_TAIL_ON] = 162000.0
				},
				[HEMISPHERE_LOWER] =
				{
					[ASPECT_HEAD_ON] = 196000.0,
					[ASPECT_TAIL_ON] = 136000.0
				}
			},
			lock_on_distance_coeff = 0.95,
			multiple_targets_tracking = true,
			TWS_max_targets = 12,
			velocity_limits =
			{
				radial_velocity_min = 200.0 / 3.6,
				relative_radial_velocity_min = 200.0 / 3.6,
			},
		},
		surface_search = {
			vehicles_detection = true,
			RCS = 100,
			RBM_detection_distance = 185000.0,
			GMTI_detection_distance = 185000.0,
			HRM_detection_distance = 185000.0
		}
	}
	declare_sensor(APG_82)
    local ia_radar = {}
    for key, value in pairs(APG_82) do ia_radar[key] = value end
    ia_radar.Name = "AN/APG-82(V)1"
    local range_scale = (1 / 3) ^ 0.25
    ia_radar.max_measuring_distance = APG_82.max_measuring_distance * range_scale
    ia_radar.air_search = {}
    for key, value in pairs(APG_82.air_search) do ia_radar.air_search[key] = value end
    ia_radar.air_search.detection_distance = {}
    for hemisphere, aspects in pairs(APG_82.air_search.detection_distance) do
        local scaled = {}
        for aspect, distance in pairs(aspects) do scaled[aspect] = distance * range_scale end
        ia_radar.air_search.detection_distance[hemisphere] = scaled
    end
    declare_sensor(ia_radar)
	f15exrwr = {
		Name = "AN/ALQ-250",
		category = SENSOR_RWR,
		detection_dist_to_radar_detection_dist_max_ratio = 0.95,
		lock_on_detection = true
	}
	declare_sensor(f15exrwr)
end
if HAVE_NOCFT then
	dofile(current_mod_path.."/UnitPayloads/F15EX.lua")
	dofile(current_mod_path..'/F15EX.lua')
end
dofile(current_mod_path..'/F15EX_CFT.lua')
dofile(current_mod_path..'/F15IA.lua')

plugin_done()
