

F15IA =  {
      
		Name 			= 'F15IA',
		sounderName		= "Aircraft/Planes/F15EX",
		DisplayName		= _('F-15IA'),
        Picture 		= "F-15C.png",
        Rate 			= "50",
        Shape			= "F15EX",
        WorldID		=  WSTYPE_PLACEHOLDER,
		livery_entry    =  "F-15IA",
        
	shape_table_data 	= 
	{
		{
			file  	 	= 'F15EX';
			life  	 	= 20;
			vis   	 	= 3;
			desrt    	= 'f-15-oblomok';
			fire  	 	= { 300, 2};
			username	= 'F15EX';
			index       =  WSTYPE_PLACEHOLDER;
			classname   = "lLandPlane";
			positioning = "BYNORMAL";
		},
		{
			name  		= "f-15-oblomok";
			file  		= "f-15-oblomok";
			fire  		= { 240, 2};
		},
	},
	

	
	LandRWCategories = 
        {
        [1] = 
        {
			Name = "AircraftCarrier",
        },
        [2] = 
        {
            Name = "AircraftCarrier With Catapult",
        }, 
        [3] = 
        {
            Name = "AircraftCarrier With Tramplin",
        }, 
    },
        TakeOffRWCategories = 
        {
        [1] = 
        {
			Name = "AircraftCarrier",
        },
        [2] = 
        {
            Name = "AircraftCarrier With Catapult",
        }, 
        [3] = 
        {
            Name = "AircraftCarrier With Tramplin",
        }, 
    },
	
	mapclasskey 		= "P0091000024",
	attribute  			= {wsType_Air, wsType_Airplane, wsType_Fighter, WSTYPE_PLACEHOLDER, "Fighters", "Refuelable", "Datalink", "Link16"},
	Categories= {"{78EFB7A2-FD52-4b57-A6A6-3BF0E1D6555F}", "Interceptor",},
	 
		M_empty						=	17646.1,
		M_nominal					=	28217.1,
		M_max						=	36741,
		M_fuel_max					=	10571,
		H_max						=	20000,
		average_fuel_consumption	=	0.271,
		CAS_min						=	58,
		V_opt						=	290,
		V_take_off					=	61,
		V_land						=	71,
		has_afteburner				=	true,
		has_speedbrake				=	true,
		radar_can_see_ground		=	true,

		nose_gear_pos 				                = {4.659,	-2.267995,	0},
	    nose_gear_amortizer_direct_stroke   		=  0.212895,
	    nose_gear_amortizer_reversal_stroke  		=  -0.217485,
	    nose_gear_amortizer_normal_weight_stroke 	=  0.0,
	    nose_gear_wheel_diameter 	                = 0.56278,
	
	    main_gear_pos 						 	    = {-0.773,	-2.24217,	1.371},
	    main_gear_amortizer_direct_stroke	 	    =   0.11373,
	    main_gear_amortizer_reversal_stroke  	    = 	-0.11373,
	    main_gear_amortizer_normal_weight_stroke    =   0.0,
	    main_gear_wheel_diameter 				    =   0.88825,

		AOA_take_off				=	0.16,
		stores_number				=	12,
		bank_angle_max				=	60,
		tand_gear_max				=	1.732,
		V_max_sea_level				=	395,
		V_max_h						=	740,
		Vy_max						=	275,
		tanker_type					=	1,
		wing_area					=	60,
		wing_span					=	13.05,
		wing_type 					= 	0,
		thrust_sum_max				=	15563,
		thrust_sum_ab				=	26717,
		length						=	19.43,
		height						=	5.63,
		flaps_maneuver				=	1,
		Mach_max					=	2.5,
		range						=	2540,
		RCS							=	5,
		Ny_min						=	-3,
		Ny_max						=	9,
		Ny_max_e					=	9,
		detection_range_max			=	750,
		IR_emission_coeff			=	0.91,
		IR_emission_coeff_ab		=	4,
		crew_size					=	2,
		engines_count				=	2,
		wing_tip_pos		 		= 	{-3.9,	0.2,	6.6},
		

		TACAN_AA					= true,


		mechanimations = { Door0 = { {Transition = {"Any", "Bailout"}, Sequence = {{C = {{"JettisonCanopy", 0},},},},}, }, },
		
		net_animation = { 38, 49, 51, 83, 88, 89, 90, 91, 190, 191, 192, 198, 199, 200, 201, 208, 209, 802, 274, 275, 276, 277, 278, 279, 39, 99, 337, 399, 3080, 3090, 338, 339 },
		
		engines_nozzles = 
		{
			[1] = 
			{
				pos = 	{-6.751,	0.067,	-0.705},
				diameter			=	1.1,
				exhaust_length_ab	=	12,
				exhaust_length_ab_K	=	0.76,
				smokiness_level		=	0.05,
				afterburner_circles_count = 11,
				afterburner_circles_pos = {0.2, 0.8},
				afterburner_circles_scale = 1.0,
				afterburner_effect_texture = "afterburner_f-16c",
			},
			[2] = 
			{
				pos = 	{-6.751,	0.067,	0.705},
				diameter			=	1.1,
				exhaust_length_ab	=	12,
				exhaust_length_ab_K	=	0.76,
				smokiness_level		=	0.05,
				afterburner_circles_count = 11,
				afterburner_circles_pos = {0.2, 0.8},
				afterburner_circles_scale = 1.0,
				afterburner_effect_texture = "afterburner_f-16c",
			},
		},
		crew_members = 
		{
			[1] = 
			{
				pos 				= {6.277,	1.198,	0},
				ejection_seat_name	= 17,
				drop_canopy_name	=	"F-15E-FONAR";
				canopy_pos			= {0,0,0},
				canopy_arg			= 38,
			},
			[2] = 
			{
				pilot_body_arg		= 472,
				ejection_seat_name	= 17,
				drop_canopy_name	= 0,
				pos 				= {4.327,	1.198,	0},
				canopy_arg			= 38,
			},
		},
		brakeshute_name	=	0,
		is_tanker	=	false,
		air_refuel_receptacle_pos = 	{1.39,	0.41,	-1.66},
		fires_pos = 
		{
			[1] = 	{-1.842,	0.563,	0},
			[2] = 	{-1.644,	0.481,	2.87},
			[3] = 	{-1.389,	0.461,	-3.232},
			[4] = 	{-0.82,	0.265,	2.774},
			[5] = 	{-0.82,	0.265,	-2.774},
			[6] = 	{-0.82,	0.255,	4.274},
			[7] = 	{-0.82,	0.255,	-4.274},
			[8] = 	{-5.753,	0.06,	0.705},
			[9] = 	{-5.753,	0.06,	-0.705},
			[10] = 	{-0.992,	0.85,	0},
			[11] = 	{-1.683,	0.507,	-2.91},
		},
		
		effects_presets = {
			{effect = "OVERWING_VAPOR", file = current_mod_path.."/Effects/VSN_F15E_overwingVapor.lua"},
		},
		
		chaff_flare_dispenser = 
		{
			[1] = 
			{
				dir = 	{0,	-1,	0},
				pos = 	{1.158,	-1.77,	-0.967},
			},
			[2] = 
			{
				dir = 	{0,	-1,	0},
				pos = 	{1.158,	-1.77,	0.967},
			},
			[3] = 
			{
				dir = 	{-1,	-1,	0},
				pos = 	{-7.52,	-0.2,	-1.67},
			},
			[4] = 
			{
				dir = 	{-1,	-1,	0},
				pos = 	{-7.52,	-0.2,	1.67},
			},
		},


passivCounterm 		= {
CMDS_Edit 			= true,
SingleChargeTotal 	= 360,
chaff 				= {default = 120, increment = 30, chargeSz = 1},
flare 				= {default = 120, increment = 30, chargeSz = 2}
 },
	
        CanopyGeometry 	= {
            azimuth 	= {-145.0, 145.0},
            elevation 	= {-50.0, 90.0}
        },

Sensors = {
RADAR 	= "AN/APG-82(V)1",
RWR 	= "Abstract RWR"
},
Countermeasures = {
ECM 			= "AN/ALQ-250"
},
	Failures = {
			{ id = 'asc', 		label = _('ASC'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'autopilot', label = _('AUTOPILOT'), enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'hydro',  	label = _('HYDRO'), 	enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'l_engine',  label = _('L-ENGINE'), 	enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'r_engine',  label = _('R-ENGINE'), 	enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'radar',  	label = _('RADAR'), 	enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },


			{ id = 'mlws',  	label = _('MLWS'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'rws',  		label = _('RWS'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'ecm',   	label = _('ECM'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'hud',  		label = _('HUD'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
			{ id = 'mfd',  		label = _('MFD'), 		enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },		
	},
	HumanRadio = {
		frequency 		= 127.5,
		editable 		= true,
		minFrequency	= 30.000,
		maxFrequency 	= 399.975,
		modulation 		= MODULATION_AM
	},


	panelRadio = {
		[1] = {
			name = _('R1 ARC-210'),
			range = {{min = 30.0, max = 87.975}, {min = 108.0, max = 173.975}, {min = 225.0, max = 399.975}},
			channels = {
				[1] = {name = _('Channel 1'), default = 251.000},
				[2] = {name = _('Channel 2'), default = 264.000},
				[3] = {name = _('Channel 3'), default = 265.000},
				[4] = {name = _('Channel 4'), default = 256.000},
				[5] = {name = _('Channel 5'), default = 254.000},
				[6] = {name = _('Channel 6'), default = 250.000},
				[7] = {name = _('Channel 7'), default = 270.000},
				[8] = {name = _('Channel 8'), default = 257.000},
				[9] = {name = _('Channel 9'), default = 255.000},
				[10] = {name = _('Channel 10'), default = 262.000},
				[11] = {name = _('Channel 11'), default = 259.000},
				[12] = {name = _('Channel 12'), default = 268.000},
				[13] = {name = _('Channel 13'), default = 269.000},
				[14] = {name = _('Channel 14'), default = 260.000},
				[15] = {name = _('Channel 15'), default = 263.000},
				[16] = {name = _('Channel 16'), default = 261.000},
				[17] = {name = _('Channel 17'), default = 267.000},
				[18] = {name = _('Channel 18'), default = 251.500},
				[19] = {name = _('Channel 19'), default = 252.000},
				[20] = {name = _('Channel 20'), default = 253.000},
			},
		},
		[2] = {
			name = _('R2 ARC-210'),
			range = {{min = 30.0, max = 87.975}, {min = 108.0, max = 173.975}, {min = 225.0, max = 399.975}},
			channels = {
				[1] = {name = _('Channel 1'), default = 124.000},
				[2] = {name = _('Channel 2'), default = 127.500},
				[3] = {name = _('Channel 3'), default = 121.000},
				[4] = {name = _('Channel 4'), default = 118.500},
				[5] = {name = _('Channel 5'), default = 119.000},
				[6] = {name = _('Channel 6'), default = 120.000},
				[7] = {name = _('Channel 7'), default = 122.000},
				[8] = {name = _('Channel 8'), default = 123.000},
				[9] = {name = _('Channel 9'), default = 124.500},
				[10] = {name = _('Channel 10'), default = 125.000},
				[11] = {name = _('Channel 11'), default = 126.000},
				[12] = {name = _('Channel 12'), default = 128.000},
				[13] = {name = _('Channel 13'), default = 129.000},
				[14] = {name = _('Channel 14'), default = 130.000},
				[15] = {name = _('Channel 15'), default = 131.000},
				[16] = {name = _('Channel 16'), default = 132.000},
				[17] = {name = _('Channel 17'), default = 133.000},
				[18] = {name = _('Channel 18'), default = 134.000},
				[19] = {name = _('Channel 19'), default = 135.000},
				[20] = {name = _('Channel 20'), default = 136.000},
			},
		},
	},

Guns = {gun_mount("M_61", {
	mixes = {
		{1},
		{2},
		{3},
		{4,5},
		{6},
		{7,8},
	},
	count = 500 },{muzzle_pos = {4.00000, 0.450000, 2.000000}})


},
ammo_type_default = 5,
ammo_type = {
	_("HEI-T High Explosive Incendiary-Tracer"),
	_("HEI High Explosive Incendiary"),
	_("AP Armor Piercing"),
	_("TP Target Practice-Tracer"),
	_("SAPHEI High Explosive Armor Piercing PGU"),
	_("TP Target Practice-Tracer PGU"),
},


pylons_enumeration = {1, 15, 14, 2, 3, 13, 12, 4, 5, 11, 6, 10, 7, 9, 8},



	Pylons =     {

        pylon(1, 0, 0, 0.2, 0.0, {use_full_connector_position=false},

            {

				{ CLSID = "{F15EX_2xAIM-120D-3}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				{ CLSID = "{F15EX_2xAIM-120D}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-8}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-7}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-5}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				{ CLSID = "{F15IA_PYTHON-5}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  -0.95}},
				

            }
        ),
        pylon(2, 0, 0, 0, 0, {mass = 71.3, use_full_connector_position=true, connector = "Pylon2", arg = 308 },
            {

				{ CLSID = "{F15E_EXTTANK}" },
				{ CLSID = "{F15E_EXTTANK_EMPTY}" },
				

				{ CLSID = "{LAU_115_2xAIM-120C-7}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120C-8}"},
				{ CLSID = "{LAU_115_2xAIM-120D-3}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120D}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120C-5}" },
				{ CLSID = "{AIM200-4XRACK}", Type = 1},
				{ CLSID = "{F15EX_AIM-174B}", Type = 1},
				{ CLSID = "{APKWS_II_IRx21}"},
				{ CLSID = "{APKWS_II_IR_x21}"},
				

				

				








				



































				{ CLSID = "<CLEAN>",								arg_value = 1, add_mass = -71.3},
            }
        ),
        pylon(3, 0, 0, 0, 0, {use_full_connector_position=false, connector = "Pylon10", DisplayName = _("2A")},
            {
				{ CLSID = "{F15EX_AIM-120C-8_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-7_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-5_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D-3_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_PYTHON-5_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-9X-ED_STA2A}", attach_point_position = {0.45,  0.90,  0.0}},
            }
        ),
        pylon(4, 0, 0, 0, 0, {use_full_connector_position=false, connector = "Pylon10", DisplayName = _("2B")},
            {
				{ CLSID = "{F15EX_AIM-120C-8_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-7_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-5_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D-3_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_PYTHON-5_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-9X-ED_STA2B}", attach_point_position = {0.45,  0.90,  0.0}},
            }
        ),
        pylon(5, 0, 0, 0, 0, {mass = 71, use_full_connector_position=true, connector = "Pylon8" ,DisplayName = _("LCFT")},
            {

				{ CLSID = "{AMBER_2xAIM120C8}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C7}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C5}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D_P3I}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM260A}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
             			

				{ CLSID = "{F15EX_AIM-120C-8_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-7_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-5_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D-3_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-200A_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 316, arg_value = 0.15, Type = 1},
				{ CLSID = "{AIM200-4XRACK}", connector = "Pylon9", Type = 1},
				{ CLSID = "{AIM200_X3_F-15EX}" , attach_point_position = {-1.2,  -0.12,  0.0}, Type = 1},
				{ CLSID = "{F15EX_AIM-174B_CFT}", Type = 1},
				
				

				

				





		















            }
        ),
        pylon(6, 0, 0, 0, 0, {mass = 71, use_full_connector_position=true, connector = "Pylon8", DisplayName = _("LCFT-A")},
            {

				{ CLSID = "{AMBER_2xAIM120C8}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C7}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C5}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D_P3I}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM260A}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AIM200-4XRACK}", connector = "Pylon8_AFT", attach_point_position = {0.0,  0.0665,  0.0}, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-8_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-7_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-5_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D-3_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-200A_CFT_A}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 314, arg_value = 0.15, Type = 1},








            }
        ),
		pylon(7, 0, 0, 0, 0, {use_full_connector_position=true, connector = "Pylon20" ,DisplayName = _("TGP"), arg = 309},
            {

				{ CLSID = "{A111396E-D3E8-4b9c-8AC9-2432489304D5}", arg_value = 1.0},
				{ CLSID = "{F-15E_AAQ-14_LANTIRN}", arg_value = 1.0},
            }
		),
        pylon(8, 0, 0, 0, 0, {mass = 71.3, use_full_connector_position=true, connector = "Pylon10" ,DisplayName = _("6"), arg = 317},
            {

				{ CLSID = "{AMBER_2xAIM120C8}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C7}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C5}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D_P3I}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM260A}", attach_point_position = {0.0,  -0.115,  0.0}, Type = 1},

				{ CLSID = "{AIM200-4XRACK}", Type = 1},
				













				

				{ CLSID = "{F15E_EXTTANK}" },
				{ CLSID = "{F15E_EXTTANK_EMPTY}" },
				

				{ CLSID = "{ASG-34_LegionPod}" ,attach_point_position = {0.0, -0.225, 0.0}},
				{ CLSID = "<CLEAN>",				arg_value = 1, add_mass = -71.3},
            }
        ),
        pylon(9, 0, 0, 0, 0, {use_full_connector_position=true, connector = "Pylon21" ,DisplayName = _("NAV")},
            {				

				{ CLSID = "{F-15E_AAQ-13_LANTIRN}", connector = "Pylon21", arg_value = 1.0, },
				
            }
        ),

        pylon(10, 0, 0, 0, 0, {mass = 71, use_full_connector_position=true, connector = "Pylon12", DisplayName = _("RCFT-A")},
            {

				{ CLSID = "{AMBER_2xAIM120C8}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C7}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C5}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D_P3I}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM260A}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0,  0.0}, Type = 1},
				{ CLSID = "{AIM200-4XRACK}", connector = "Pylon12_AFT", attach_point_position = {0.0,  0.0665,  0.0}, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-8_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-7_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-5_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D-3_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-200A_CFT_RA}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 318, arg_value = 0.15, Type = 1},

				{ CLSID = "{F15EX_AIM-120C-8_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},
				{ CLSID = "{F15EX_AIM-120C-7_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},
				{ CLSID = "{F15EX_AIM-120C-5_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},
				{ CLSID = "{F15EX_AIM-120D-3_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},
				{ CLSID = "{F15EX_AIM-120D_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},
				{ CLSID = "{F15EX_AIM-200A_CFT_A}", attach_point_position = {0.2,  -0.0,  -0.041}, arg = 318, arg_value = 0.15, Type = 1, obsolete = true},








            }
        ),
		pylon(11, 0, 0, 0, 0, {mass = 71, use_full_connector_position=true, connector = "Pylon12" ,DisplayName = _("RCFT")},
            {

				{ CLSID = "{AMBER_2xAIM120C8}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C7}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120C5}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM120D_P3I}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},
				{ CLSID = "{AMBER_2xAIM260A}", attach_point_position = {1.918, -0.127,  0.0}, Type = 1},

				{ CLSID = "{F15EX_AIM-120C-8_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-7_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120C-5_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D-3_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-120D_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{F15EX_AIM-200A_CFT_F}", attach_point_position = {0.2,  -0.0,  0.0}, arg = 320, arg_value = 0.15, Type = 1},
				{ CLSID = "{AIM200-4XRACK}", connector = "Pylon13", Type = 1},
				{ CLSID = "{AIM200_X3_F-15EX}" , attach_point_position = {-0.0,  -0.0,  0.0}, Type = 1},
				{ CLSID = "{F15EX_AIM-174B_CFT}", Type = 1},
								

				

				
				





				
				















            }
		),
        pylon(12, 0, 0, 0, 0, {use_full_connector_position=false, connector = "Pylon10", DisplayName = _("11B")},
            {
				{ CLSID = "{F15EX_AIM-120C-8_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-7_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-5_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D-3_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_PYTHON-5_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-9X-ED_STA11B}", attach_point_position = {0.45,  0.90,  0.0}},
            }
        ),
        pylon(13, 0, 0, 0, 0, {use_full_connector_position=false, connector = "Pylon10", DisplayName = _("11A")},
            {
				{ CLSID = "{F15EX_AIM-120C-8_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-7_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120C-5_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D-3_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-120D_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_PYTHON-5_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
				{ CLSID = "{F15EX_AIM-9X-ED_STA11A}", attach_point_position = {0.45,  0.90,  0.0}},
            }
        ),
        pylon(14, 0, 0, 0, 0, {mass = 71.3, use_full_connector_position=true, connector = "Pylon18" ,DisplayName = _("11"), arg = 322},
            {

				{ CLSID = "{F15E_EXTTANK}" },
				{ CLSID = "{F15E_EXTTANK_EMPTY}" },
				

				{ CLSID = "{LAU_115_2xAIM-120C-7}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120C-8}"},
				{ CLSID = "{LAU_115_2xAIM-120D-3}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120D}"},
				{ CLSID = "{F15EX_LAU_115_2xAIM-120C-5}" },
				{ CLSID = "{AIM200-4XRACK}", Type = 1},
				{ CLSID = "{F15EX_AIM-174B}", Type = 1},
				{ CLSID = "{APKWS_II_IRx21}"},
				{ CLSID = "{APKWS_II_IR_x21}"},
				

				

				



































				{ CLSID = "<CLEAN>",								arg_value = 1, add_mass = -71.3},
				
            }
        ),
        pylon(15, 0, 0, 0, 0, {use_full_connector_position=false, connector = "Pylon19",DisplayName = _("12")},
            {

				{ CLSID = "{F15IA_PYTHON-5}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  0.95}},
				{ CLSID = "{F15EX_2xAIM-120D-3}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  0.95}},
				{ CLSID = "{F15EX_2xAIM-120D}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-8}" ,arg_increment = -0.1, attach_point_position = {-2.4,  0.05,  0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-7}" , attach_point_position = {-2.4,  0.05,  0.95}},
				{ CLSID = "{F15EX_2xAIM-120C-5}" , attach_point_position = {-2.4,  0.05,  0.95}},
				

            }
        ),

		
},
	
	Tasks = {
        aircraft_task(CAP),
     	aircraft_task(Escort),
      	aircraft_task(FighterSweep),
		aircraft_task(Intercept),
		aircraft_task(Reconnaissance),
    	aircraft_task(GroundAttack),
     	aircraft_task(CAS),
		aircraft_task(SEAD),

 	    aircraft_task(RunwayAttack),
    	aircraft_task(AntishipStrike),
    },	
	DefaultTask = aircraft_task(CAP),

	SFM_Data = {
	aerodynamics =
		{
			Cy0	=	0,
			Mzalfa	=	6,
			Mzalfadt	=	1,
			kjx = 2.95,
			kjz = 0.00125,
			Czbe = -0.016,
			cx_gear = 0.0268,
			cx_flap = 0.06,
			cy_flap = 0.4,
			cx_brk = 0.06,
			table_data = 
			{

				{0.0,	0.0215,		0.055,		0.08,		0.22,	0.65,	25.0,	1.2 	},
				{0.2,	0.0215,		0.055,		0.08,		0.22,	1.80,	25.0,	1.2     },
				{0.4,	0.0215,		0.055,		0.08,	   	0.22,	3.00,	25.0,	1.2     },
				{0.6,	0.0215,		0.055,		0.05,		0.28,	4.20,	25.0,	1.2     },
				{0.7,	0.0215,		0.055,		0.05,		0.28,	4.20,	23.0,	1.15    },
				{0.8,	0.0215,		0.055,		0.05,		0.28,	4.20,	21.7,	1.1     },
				{0.9,	0.0230,		0.058,		0.09,		0.20,	4.20,	20.1,	1.07    },
				{1.0,	0.0320,		0.062,		0.17,		0.15,	4.20,	18.9,	1.04    },
				{1.1,	0.0430,		0.062,	   	0.235,		0.09,	3.78,	17.4,	1.02    },
				{1.2,	0.0460,		0.062,	   	0.285,		0.08,	2.94,	17.0,	1.00 	},		
				{1.3,	0.0470,		0.06,	   	0.29,		0.10,	2.10,	16.0,	0.92 	},				
				{1.4,	0.0470,		0.056,	   	0.3,		0.136,	1.80,	15.0,	0.80 	},					
				{1.6,	0.0470,		0.052,	   	0.34,		0.21,	1.08,	13.0,	0.7 	},					
				{1.8,	0.0460,		0.042,	   	0.34,		2.43,	0.96,	12.0,	0.55 	},		
				{2.2,	0.0420,		0.037,	   	0.49,		3.5,	0.84,	 10.0,	0.37 	},					
				{2.5,	0.0420,		0.033,		0.6,		4.7,	0.84,	 9.0,	0.3 	},		
				{3.9,	0.0400,		0.023,		0.9,		6.0,	0.84,	 7.0,	0.2		},
			},
		},

		engine =
		{
			type	=	"TurboFan",
			Nmg		=	67.5,
 			Nominal_RPM		= 14710.0,
			Nominal_Fan_RPM	= 8215.0,
			Startup_Prework = 10.0,
			Startup_Duration = 35.0,
			Shutdown_Duration = 19.0,
			MinRUD	=	0,
			MaxRUD	=	1,
			MaksRUD	=	0.85,
			ForsRUD	=	0.91,
			hMaxEng	=	19,
			dcx_eng	=	0.0144,
			cemax	=	1.24,
			cefor	=	2.56,
			dpdh_m	=	6200,
			dpdh_f	=	13000,
			table_data =
			{
				[1] =	{0,		77000,	108313.6},
				[2] =	{0.2,	74000,	109850},
				[3] =	{0.4,	74000,	122000},
				[4] =	{0.6,	82000,	142000},
				[5] =	{0.7,	85000,	156000},
				[6] =	{0.8,	92000,	177000},
				[7] =	{0.9,	100000,	202000},
				[8] =	{1,		109000,	218000},
				[9] =	{1.096,	99000,	222000},
				[10] =	{1.2,	86000,	228000},
				[11] =	{1.3,	68000,	231000},
				[12] =	{1.4,	55000,	230000},
				[13] =	{1.6,	56000,	229000},
				[14] =	{1.8,	56000,	227000},
				[15] =	{2.2,	52000,	234000},
				[16] =	{2.35,	43000,	224000},
				[17] =	{3.9,	25000,	120636.4},
			},
		},
	},



	Damage = {
	[0]  = {critical_damage = 5,  args = {146}},
	[1]  = {critical_damage = 3,  args = {296}},
	[2]  = {critical_damage = 3,  args = {297}},
	[3]  = {critical_damage = 8, args = {65}},
	[4]  = {critical_damage = 2,  args = {298}},
	[5]  = {critical_damage = 2,  args = {301}},
	[7]  = {critical_damage = 2,  args = {249}},
	[8]  = {critical_damage = 3,  args = {265}},
	[9]  = {critical_damage = 3,  args = {154}},
	[10] = {critical_damage = 3,  args = {153}},
	[11] = {critical_damage = 1,  args = {167}},
	[12] = {critical_damage = 1,  args = {161}},
	[13] = {critical_damage = 2,  args = {169}},
	[14] = {critical_damage = 2,  args = {163}},
	[15] = {critical_damage = 2,  args = {267}},
	[16] = {critical_damage = 2,  args = {266}},
	[17] = {critical_damage = 2,  args = {168}},
	[18] = {critical_damage = 2,  args = {162}},
	[20] = {critical_damage = 2,  args = {183}},
	[23] = {critical_damage = 5, args = {223}},
	[24] = {critical_damage = 5, args = {213}},
	[25] = {critical_damage = 2,  args = {226}},
	[26] = {critical_damage = 2,  args = {216}},
	[29] = {critical_damage = 5, args = {224}, deps_cells = {23, 25}},
	[30] = {critical_damage = 5, args = {214}, deps_cells = {24, 26}},
	[35] = {critical_damage = 6, args = {225}, deps_cells = {23, 29, 25, 37}},
	[36] = {critical_damage = 6, args = {215}, deps_cells = {24, 30, 26, 38}}, 
	[37] = {critical_damage = 2,  args = {228}},
	[38] = {critical_damage = 2,  args = {218}},
	[39] = {critical_damage = 2,  args = {244}, deps_cells = {53}}, 
	[40] = {critical_damage = 2,  args = {241}, deps_cells = {54}}, 
	[43] = {critical_damage = 2,  args = {243}, deps_cells = {39, 53}},
	[44] = {critical_damage = 2,  args = {242}, deps_cells = {40, 54}}, 
	[51] = {critical_damage = 2,  args = {240}}, 
	[52] = {critical_damage = 2,  args = {238}},
	[53] = {critical_damage = 2,  args = {248}},
	[54] = {critical_damage = 2,  args = {247}},
	[56] = {critical_damage = 2,  args = {158}},
	[57] = {critical_damage = 2,  args = {157}},
	[59] = {critical_damage = 3,  args = {148}},
	[61] = {critical_damage = 2,  args = {147}},
	[82] = {critical_damage = 2,  args = {152}},
	[83] = {critical_damage = 2,  args = {134}},
	[84] = {critical_damage = 2,  args = {136}},
	[85] = {critical_damage = 2,  args = {135}},
	[47] = {critical_damage = 2, deps_cells = {51}},
	[48] = {critical_damage = 2, deps_cells = {52}},



	},
	
	DamageParts = 
	{  
		[1] = "f-15e-oblomok-wing-r",
		[2] = "f-15e-oblomok-wing-l",



	},
	

	lights_data = { 
	typename = "collection", 
	lights = {
		[WOLALIGHT_NAVLIGHTS] = {
            typename = "Collection",
            lights = {
                {
                    typename = "Spot", connector = "BANO_0", dir_correction = {azimuth = math.rad(180.0)}, argument = 192,
                    proto = lamp_prototypes.ANO_3_Bl, angle_max = math.rad(180.0), angle_min = math.rad(170.0),
                },
                {
                    typename = "Spot", connector = "BANO_1", dir_correction = {azimuth = math.rad(-45.0)}, argument = 190,
                    proto = lamp_prototypes.ANO_3_Kr, angle_max = math.rad(180.0), angle_min = math.rad(90.0),
                    controller = "Strobe", mode = 1, power_up_t = 0.3, cool_down_t = 0.6, period = 1.0, flash_time = 0.7,
                },
                {
                    typename = "Spot", connector = "BANO_2", dir_correction = {azimuth = math.rad(45.0)}, argument = 191,
                    proto = lamp_prototypes.ANO_3_Zl, angle_max = math.rad(180.0), angle_min = math.rad(90.0),
                    controller = "Strobe", mode = 1, power_up_t = 0.3, cool_down_t = 0.6, period = 1.0, flash_time = 0.7,
                },
            }
        },
        [WOLALIGHT_SPOTS] = {
            typename = "Collection",
            lights = {
                {
                    typename = "Collection",
                    lights = {
                        {
                            typename = "Spot", connector = "MAIN_SPOT_PTR", dir_correction = {elevation = math.rad(12.0)}, argument = 209,
                            proto = lamp_prototypes.LFS_P_27_1000,
                            exposure = {{0, 0.99, 1.0}}, movable = true,
                        },
                        {
                            typename = "Spot", connector = "MAIN_SPOT_PTR", dir_correction = {elevation = math.rad(12.0)}, argument = 209,
                            proto = lamp_prototypes.LFS_P_27_1000, range = 18.0, angle_max = math.rad(180.0), angle_min = math.rad(170.0),
                            exposure = {{0, 0.99, 1.0}}, movable = true,
                        },
                    },
                },
            },
        },
        [WOLALIGHT_TAXI_LIGHTS] = {
            typename = "Collection",
            lights = {
                {
                    typename = "Collection",
                    lights = {
                        {
                            typename = "Spot", connector = "MAIN_SPOT_PTR", argument = 208,
                            proto = lamp_prototypes.LFS_R_27_180, angle_max = math.rad(72.0),
                            exposure = {{0, 0.99, 1.0}}, power_up_t = 0.75, movable = true,
                        },
                        {
                            typename = "Spot", connector = "MAIN_SPOT_PTR", argument = 208,
                            proto = lamp_prototypes.LFS_R_27_180, range = 18.0, angle_max = math.rad(180.0), angle_min = math.rad(170.0),
                            exposure = {{0, 0.99, 1.0}}, power_up_t = 0.75, movable = true,
                        },
                    },
                },
            },
        },
        [WOLALIGHT_STROBES] = {
            typename = "collection",
            lights = {
                {
                    typename = "collection",
                    lights = {
                        {
                            typename = "Spot", connector = "RESERV1_BANO_1", dir_correction = {azimuth = math.rad(-55.0)}, argument = 199,
                            proto = lamp_prototypes.SMI_2KM,
                        },
                        {
                            typename = "Spot", connector = "RESERV_BANO_1", dir_correction = {azimuth = math.rad(55.0)}, argument = 199,
                            proto = lamp_prototypes.SMI_2KM,
                        },
                        {
                            typename = "Omni", connector = "RESERV2_BANO_1", argument = 199,
                            proto = lamp_prototypes.SMI_2KM,
                        },
                    },
                },
            },
        },
        [WOLALIGHT_FORMATION_LIGHTS] = {
            typename = "argumentlight", argument = 88,
        },
	}},
}


if ex_any_missile_pylons then ex_any_missile_pylons(F15IA) end

if ex_pylon_rules then ex_pylon_rules(F15IA) end
for _, p in ipairs(F15IA.Pylons) do
    local launchers = p.Launchers or p.launchers
    if type(launchers) == "table" then
        for i = #launchers, 1, -1 do
            local clsid = string.lower(launchers[i].CLSID or ""):gsub("[^%w]", "")
            if string.find(clsid, "aim260", 1, true) then table.remove(launchers, i) end
        end
    end
end
add_aircraft(F15IA)
