ViewSettings = {
	Cockpit = {
	[1] = {
		CockpitLocalPoint      = {6.377000,1.220000,0.000000},

		CameraViewAngleLimits  = {20.000000,140.000000},
		CameraAngleRestriction = {false,90.000000,0.500000},
		CameraAngleLimits      = {200,-90.000000,90.000000},
		EyePoint               = {0.15000,0.20000,0.000000},
		ShoulderSize		   = 0.25,
		Allow360rotation	   = false,
		limits_6DOF            = {x = {-0.08,0.5},y ={-0.25,0.10},z = {-0.25,0.25},roll = 90.000000},
	},
	},
	Chase = {
		LocalPoint      = {-5.0,1.0,3.0},
		AnglesDefault   = {0.000000,0.000000},
	},
	Arcade = {
		LocalPoint      = {-21.500000,5.618000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	},
}

local function head_pos_default(tab)
    if not tab then
	   tab = {}
	end

	tab.viewAngle = tab.viewAngle  or  63
	tab.hAngle    = tab.hAngle     or  0
	tab.vAngle    = tab.vAngle     or -9.678451
	tab.x_trans   = tab.x_trans    or  0.05
	tab.y_trans   = tab.y_trans    or -0.064373
	tab.z_trans   = tab.z_trans    or  0
	tab.rollAngle = tab.rollAngle  or  0
	
	return tab
end


SnapViews = {
[1] = {
        [1]  = head_pos_default({viewAngle = 50, hAngle = 3.5,	vAngle = -33.5}),
        [2]  = head_pos_default({viewAngle = 85, hAngle = 120, 	vAngle = -8}),
        [3]  = head_pos_default({viewAngle = 50, hAngle = 0, 	vAngle = -35}),
        [4]  = head_pos_default({viewAngle = 85, hAngle = -120, vAngle = -8}),
        [5]  = head_pos_default({viewAngle = 85, hAngle = 80, 	vAngle = -8}),
        [6]  = head_pos_default({}),
        [7]  = head_pos_default({viewAngle = 85, hAngle = -80, 	vAngle = -8}),
        [8]  = head_pos_default({viewAngle = 85, hAngle = 45, 	vAngle = 25}),
        [9]  = head_pos_default({viewAngle = 85, vAngle = 45}),
        [10] = head_pos_default({viewAngle = 85, hAngle = -45, 	vAngle = 25}),
        [11] = head_pos_default({viewAngle = 85, vAngle = -8}),
        [12] = head_pos_default({viewAngle = 85, vAngle = -8}),
        [13] = head_pos_default({}),
},
}
