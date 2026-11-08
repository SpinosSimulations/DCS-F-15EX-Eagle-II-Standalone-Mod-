


F15EVSN = {


	center_of_mass		= {-0.172  ,  -0.6,	   0},
	moment_of_inertia	= {39468  ,258401,227046,-715},
	suspension 			= {
		{
			wheel_axle_offset			= 0.07,
			damper_coeff				= 300.0,

			self_attitude				= false,



			yaw_limit					= math.rad(45.0),

			amortizer_max_length		= 0.43,
			amortizer_basic_length		= 0.43,
			amortizer_spring_force_factor	= 990000.0,
			amortizer_spring_force_factor_rate	= 2,
			amortizer_static_force		= 11000.0,


			amortizer_reduce_length		= 0.43,
			amortizer_direct_damper_force_factor	= 4000,



			amortizer_back_damper_force_factor		= 4000,

			anti_skid_installed		= false,

			wheel_radius			= 0.278,
			wheel_static_friction_factor	= 0.75 ,
			wheel_side_friction_factor		= 0.65 ,
			wheel_roll_friction_factor		= 0.025,
			wheel_glide_friction_factor		= 0.65 ,
			wheel_damage_force_factor		= 450.0,
			wheel_damage_speedX			= 118.3,
			wheel_damage_delta_speedX	= 11.5,
			allowable_hard_contact_length	= 0.3,

			arg_post			= 0,
			arg_amortizer		= 1,
			arg_wheel_rotation	= 101,
			arg_wheel_damage	= 134,
			damage_element		= 83
		},
		{

			amortizer_max_length		= 0.228, 
			amortizer_basic_length		= 0.228, 
			amortizer_spring_force_factor	= 29370398.0,
			amortizer_spring_force_factor_rate	= 3,
			amortizer_static_force		= 30000.0,


			amortizer_reduce_length		= 0.221, 
			amortizer_direct_damper_force_factor	= 15000.0,


			amortizer_back_damper_force_factor		= 15000.0,
			
			anti_skid_installed	= true,
			
			wheel_radius					= 0.440,
			wheel_static_friction_factor	= 0.75 ,
			wheel_side_friction_factor		= 0.85 ,
			wheel_roll_friction_factor		= 0.025,
			wheel_glide_friction_factor		= 0.65 ,
			wheel_damage_force_factor		= 450.0,
			wheel_damage_speedX			= 118.3,
			wheel_damage_delta_speedX	= 11.5,
			allowable_hard_contact_length	= 0.3,
			wheel_brake_moment_max				= 22000.0,
			
			arg_post			= 5,
			arg_amortizer		= 6,
			arg_wheel_rotation	= 102,
			arg_wheel_damage	= 136,
			damage_element		= 84
		},
		{

			amortizer_max_length		= 0.228, 
			amortizer_basic_length		= 0.228,
			amortizer_spring_force_factor		= 29370398.0,
			amortizer_spring_force_factor_rate	= 3,
			amortizer_static_force		= 30000.0,


			amortizer_reduce_length		= 0.221, 
			amortizer_direct_damper_force_factor	= 15000.0,


			amortizer_back_damper_force_factor		= 15000.0,
			
			anti_skid_installed		= true,
			
			wheel_radius		= 0.440,
			wheel_static_friction_factor	= 0.75 ,
			wheel_side_friction_factor		= 0.85 ,
			wheel_roll_friction_factor		= 0.025,
			wheel_glide_friction_factor		= 0.65 ,
			wheel_damage_force_factor		= 450.0,
			wheel_damage_speedX			= 118.3,
			wheel_damage_delta_speedX	= 11.5,
			allowable_hard_contact_length	= 0.3,
			wheel_brake_moment_max			= 22000.0,
			
			arg_post			= 3,
			arg_amortizer		= 4,
			arg_wheel_rotation	= 103,
			arg_wheel_damage	= 135,
			damage_element		= 85
		}
	},
	disable_built_in_oxygen_system	= true,




	minor_shake_ampl = 0.21,
	major_shake_ampl = 0.5,


	debugLine = "{M}:%1.3f {KCAS}:%4.1f {KEAS}:%4.1f {KTAS}:%4.1f {IAS}:%4.1f {AoA}:%2.1f {ny}:%2.1f {nx}:%1.2f {AoS}:%2.1f {mass}:%2.1f {Fy}:%2.1f {Fx}:%2.1f {wx}:%.1f {wy}:%.1f {wz}:%.1f {Vy}:%2.1f {dPsi}:%2.1f",
}