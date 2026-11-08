local res = external_profile("Config/Input/Aircrafts/base_keyboard_binding.lua")

local fcs = 5000

join(res.keyCommands,{


{combos = {{key = 'Up', reformers = {'RCtrl','RShift'}}}, down = 3011, up = 3011, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - Elevation up'), category = _('RADAR')},
{combos = {{key = 'Down', reformers = {'RCtrl','RShift'}}}, down = 3012, up = 3012, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - Elevation down'), category = _('RADAR')},
{combos = {{key = 'Home', reformers = {'RCtrl','RShift'}}}, down = 3015, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Scan reset'), category = _('RADAR')},
{combos = {{key = 'PageUp', reformers = {'RCtrl','RShift'}}}, down = 3016, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Range scale up'), category = _('RADAR')},
{combos = {{key = 'PageDown', reformers = {'RCtrl','RShift'}}}, down = 3017, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Range scale down'), category = _('RADAR')},

{combos = {{key = ';', reformers = {'RCtrl','RShift'}}}, down = 3020, up = 3020, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - TDC up (hold)'), category = _('RADAR')},
{combos = {{key = '.', reformers = {'RCtrl','RShift'}}}, down = 3021, up = 3021, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - TDC down (hold)'), category = _('RADAR')},
{combos = {{key = ',', reformers = {'RCtrl','RShift'}}}, down = 3022, up = 3022, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - TDC left (hold)'), category = _('RADAR')},
{combos = {{key = '/', reformers = {'RCtrl','RShift'}}}, down = 3023, up = 3023, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - TDC right (hold)'), category = _('RADAR')},
{combos = {{key = 'I', reformers = {'RCtrl','RShift'}}}, down = 3024, up = 3024, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - TMS up (DT / STT; hold 0.5 s: ACM SS; in ACM: SS / BST, hold LR BST)'), category = _('RADAR')},
{combos = {{key = 'K', reformers = {'RCtrl','RShift'}}}, down = 3025, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - TMS down (back out; in ACM: leave ACM)'), category = _('RADAR')},
{combos = {{key = 'J', reformers = {'RCtrl','RShift'}}}, down = 3026, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - TMS left (priority list; in ACM: HMD)'), category = _('RADAR')},
{combos = {{key = 'L', reformers = {'RCtrl','RShift'}}}, down = 3027, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - TMS right (next DT; in ACM: VTS)'), category = _('RADAR')},
{combos = {{key = '0', reformers = {'RCtrl','RShift'}}}, down = 3029, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Scan width A6 / A3 / A1'), category = _('RADAR')},
{combos = {{key = '9', reformers = {'RCtrl','RShift'}}}, down = 3030, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Scan bars 4B / 2B / 1B'), category = _('RADAR')},
{combos = {{key = 'E', reformers = {'RCtrl','RAlt'}}}, down = 3101, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - EXP (page in command) NORM / EXP1 / EXP2'), category = _('RADAR')},

{combos = {{key = 'G', reformers = {'RCtrl','RShift'}}}, down = 3031, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Weapon select GUN'), category = _('WEAPONS (EX)')},
{combos = {{key = 'S', reformers = {'RCtrl','RShift'}}}, down = 3032, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Weapon select SRM'), category = _('WEAPONS (EX)')},
{combos = {{key = 'M', reformers = {'RCtrl','RShift'}}}, down = 3033, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Weapon select MRM'), category = _('WEAPONS (EX)')},
{combos = {{key = 'W', reformers = {'RCtrl','RShift'}}}, down = 3034, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Weapon select cycle'), category = _('WEAPONS (EX)')},


{combos = {{key = '2'}}, down = 3110, cockpit_device_id = 5, value_down = 1.0, name = _('MASTER MODE - A/A'), category = _('WEAPONS (EX)')},
{combos = {{key = '1'}}, down = 3111, cockpit_device_id = 5, value_down = 1.0, name = _('MASTER MODE - NAV'), category = _('WEAPONS (EX)')},
{down = 3112, cockpit_device_id = 5, value_down = 1.0, name = _('MASTER MODE - Cycle A/A / NAV'), category = _('WEAPONS (EX)')},
{combos = {{key = 'A', reformers = {'RCtrl','RShift'}}}, down = 3035, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Master arm ARM / SAFE'), category = _('WEAPONS (EX)')},
{combos = {{key = 'Space', reformers = {'RCtrl','RShift'}}}, down = 3036, up = 3036, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('WEAPONS - Weapon release (selected station)'), category = _('WEAPONS (EX)')},
{combos = {{key = 'Space', reformers = {'RCtrl','RAlt'}}}, down = 3100, up = 3100, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('WEAPONS - Gun trigger (fires the gun, any weapon selected)'), category = _('WEAPONS (EX)')},

{combos = {{key = 'Z', reformers = {'RCtrl','RShift'}}}, down = 3037, cockpit_device_id = 2, value_down = 1.0, name = _('DISPLAYS - LAD left window - next format'), category = _('DISPLAYS (EX)')},
{combos = {{key = 'X', reformers = {'RCtrl','RShift'}}}, down = 3038, cockpit_device_id = 2, value_down = 1.0, name = _('DISPLAYS - LAD middle window - next format'), category = _('DISPLAYS (EX)')},
{combos = {{key = 'C', reformers = {'RCtrl','RShift'}}}, down = 3039, cockpit_device_id = 2, value_down = 1.0, name = _('DISPLAYS - LAD right window - next format'), category = _('DISPLAYS (EX)')},

{down = 3089, cockpit_device_id = 2, value_down = 1.0, name = _('DISPLAYS - LAD next layout'), category = _('DISPLAYS (EX)')},

{combos = {{key = 'Q', reformers = {'RCtrl','RShift'}}}, down = 3040, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Chaff (one)'), category = _('WEAPONS (EX)')},
{combos = {{key = 'E', reformers = {'RCtrl','RShift'}}}, down = 3041, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Flare (one)'), category = _('WEAPONS (EX)')},

{combos = {{key = 'Insert'}}, down = 3113, cockpit_device_id = 5, value_down = 1.0, name = _('CMD - MAN 1 program'), category = _('WEAPONS (EX)')},
{combos = {{key = 'Delete'}}, down = 3114, cockpit_device_id = 5, value_down = 1.0, name = _('CMD - MAN 2 program (threat program in SEMI / AUTO)'), category = _('WEAPONS (EX)')},
{combos = {{key = 'Insert', reformers = {'RCtrl'}}}, down = 3115, cockpit_device_id = 5, value_down = 1.0, name = _('CMD - Mode OFF / STBY / MAN / SEMI / AUTO'), category = _('WEAPONS (EX)')},
{combos = {{key = 'Delete', reformers = {'RCtrl'}}}, down = 3116, cockpit_device_id = 5, value_down = 1.0, name = _('CMD - Dispense select CHAFF / BOTH / FLARE'), category = _('WEAPONS (EX)')},

{combos = {{key = 'T', reformers = {'RCtrl','RShift'}}}, down = 3042, cockpit_device_id = 7, value_down = 1.0, name = _('TEWS - Scale PWR / 40 / 80 / 160 nm'), category = _('TEWS (EX)')},
{combos = {{key = 'R', reformers = {'RCtrl','RShift'}}}, down = 3043, cockpit_device_id = 7, value_down = 1.0, name = _('SIT-P - Range scale'), category = _('TEWS (EX)')},
{combos = {{key = 'Y', reformers = {'RCtrl','RShift'}}}, down = 3044, cockpit_device_id = 7, value_down = 1.0, name = _('SIT-P - Filter AIR (radar tracks)'), category = _('TEWS (EX)')},
{combos = {{key = 'U', reformers = {'RCtrl','RShift'}}}, down = 3045, cockpit_device_id = 7, value_down = 1.0, name = _('SIT-P - Filter SAM (RWR ground / ship emitters)'), category = _('TEWS (EX)')},
{combos = {{key = 'J', reformers = {'RCtrl','RAlt'}}}, down = 3083, cockpit_device_id = 7, value_down = 1.0, name = _('SIT-P - Filter JTID (datalink tracks)'), category = _('TEWS (EX)')},

{combos = {{key = 'B', reformers = {'RAlt'}}}, down = 3046, cockpit_device_id = 9, value_down = 1.0, name = _('ELEC - Battery ON / OFF'), category = _('SYSTEMS (EX)')},
{combos = {{key = '1', reformers = {'RAlt'}}}, down = 3047, cockpit_device_id = 9, value_down = 1.0, name = _('ELEC - Left generator ON / OFF'), category = _('SYSTEMS (EX)')},
{combos = {{key = '2', reformers = {'RAlt'}}}, down = 3048, cockpit_device_id = 9, value_down = 1.0, name = _('ELEC - Right generator ON / OFF'), category = _('SYSTEMS (EX)')},
{combos = {{key = 'J', reformers = {'RAlt'}}}, down = 3049, cockpit_device_id = 9, value_down = 1.0, name = _('JFS - Start / off'), category = _('SYSTEMS (EX)')},
{combos = {{key = '7', reformers = {'RAlt'}}}, down = 3054, cockpit_device_id = 9, value_down = 1.0, name = _('ENGINE - Left throttle OFF / IDLE'), category = _('SYSTEMS (EX)')},
{combos = {{key = '8', reformers = {'RAlt'}}}, down = 3055, cockpit_device_id = 9, value_down = 1.0, name = _('ENGINE - Right throttle OFF / IDLE'), category = _('SYSTEMS (EX)')},
{combos = {{key = 'Home', reformers = {'LWin'}}}, down = 3056, cockpit_device_id = 9, value_down = 1.0, name = _('ENGINE - Auto start (again: cancel)'), category = _('SYSTEMS (EX)')},
{combos = {{key = 'X', reformers = {'RAlt'}}}, down = 3057, cockpit_device_id = 9, value_down = 1.0, name = _('WARN - Master caution reset'), category = _('SYSTEMS (EX)')},
{down = 3058, cockpit_device_id = 9, value_down = 1.0, name = _('WARN - Bingo +500 lb'), category = _('SYSTEMS (EX)')},
{down = 3059, cockpit_device_id = 9, value_down = 1.0, name = _('WARN - Bingo -500 lb'), category = _('SYSTEMS (EX)')},
{combos = {{key = ']', reformers = {'RAlt'}}}, down = 3060, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Next steerpoint'), category = _('NAV (EX)')},
{combos = {{key = '[', reformers = {'RAlt'}}}, down = 3061, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Previous steerpoint'), category = _('NAV (EX)')},
{down = 3062, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - Channel +1'), category = _('NAV (EX)')},
{down = 3063, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - Channel -1'), category = _('NAV (EX)')},
{down = 3064, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - Channel +10'), category = _('NAV (EX)')},
{down = 3065, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - Channel -10'), category = _('NAV (EX)')},
{down = 3066, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - Band X / Y'), category = _('NAV (EX)')},
{down = 3067, cockpit_device_id = 10, value_down = 1.0, name = _('TACAN - OFF / T-R'), category = _('NAV (EX)')},
{down = 3068, cockpit_device_id = 10, value_down = 1.0, name = _('ILS - Frequency up'), category = _('NAV (EX)')},
{down = 3069, cockpit_device_id = 10, value_down = 1.0, name = _('ILS - Frequency down'), category = _('NAV (EX)')},
{combos = {{key = 'K', reformers = {'RAlt'}}}, down = 3070, cockpit_device_id = 10, value_down = 1.0, name = _('ILS - OFF / ON'), category = _('NAV (EX)')},
{combos = {{key = 'S', reformers = {'RAlt'}}}, down = 3071, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Steering STPT / TCN / ILS'), category = _('NAV (EX)')},
{down = 3072, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Course +1 deg'), category = _('NAV (EX)')},
{down = 3073, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Course -1 deg'), category = _('NAV (EX)')},
{down = 3074, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - GPS aiding ON / OFF'), category = _('NAV (EX)')},
{down = 3075, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - Steerpoint auto-sequencing ON / OFF'), category = _('NAV (EX)')},
{combos = {{key = ';', reformers = {'RAlt'}}}, down = 3076, cockpit_device_id = 10, value_down = 1.0, name = _('NAV - HSI range scale'), category = _('NAV (EX)')},

{combos = {{key = 'F', reformers = {'RCtrl','RShift'}}}, down = 3077, up = 3077, cockpit_device_id = 5, value_down = 1.0, value_up = 0.0, name = _('RADAR - Auto acq forward: SS / BST, hold 1 s LR BST'), category = _('RADAR')},
{combos = {{key = 'B', reformers = {'RCtrl','RShift'}}}, down = 3078, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Auto acq aft: VTS'), category = _('RADAR')},
{combos = {{key = 'D', reformers = {'RCtrl','RShift'}}}, down = 3079, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - Auto acq depress: return to search'), category = _('RADAR')},
{combos = {{key = 'V', reformers = {'RCtrl','RShift'}}}, down = 3080, cockpit_device_id = 5, value_down = 1.0, name = _('RADAR - HMD look and lock'), category = _('RADAR')},
{combos = {{key = 'P', reformers = {'RCtrl','RShift'}}}, down = 3081, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - AIM-9X uncage / cage'), category = _('WEAPONS (EX)')},
{combos = {{key = 'N', reformers = {'RCtrl','RAlt'}}}, down = 3082, cockpit_device_id = 5, value_down = 1.0, name = _('DISPLAYS - Day / night mode'), category = _('WEAPONS (EX)')},

{combos = {{key = 'Up', reformers = {'RCtrl','RAlt'}}}, down = 3084, cockpit_device_id = 2, value_down = 1.0, name = _('DISPLAYS - Castle forward: HUD in command'), category = _('DISPLAYS (EX)')},
{combos = {{key = 'Left', reformers = {'RCtrl','RAlt'}}}, down = 3085, up = 3085, cockpit_device_id = 2, value_down = 1.0, value_up = 0.0, name = _('DISPLAYS - Castle left: short left window in command, hold 1 s next format'), category = _('DISPLAYS (EX)')},
{combos = {{key = 'Down', reformers = {'RCtrl','RAlt'}}}, down = 3086, up = 3086, cockpit_device_id = 2, value_down = 1.0, value_up = 0.0, name = _('DISPLAYS - Castle down: short middle window in command, hold 1 s next format'), category = _('DISPLAYS (EX)')},
{combos = {{key = 'Right', reformers = {'RCtrl','RAlt'}}}, down = 3087, up = 3087, cockpit_device_id = 2, value_down = 1.0, value_up = 0.0, name = _('DISPLAYS - Castle right: short right window in command, hold 1 s next format'), category = _('DISPLAYS (EX)')},


{down = 3098, cockpit_device_id = 18, value_down = 1.0, name = _('PTT 1 - Mic switch forward: transmit on R1 (comm menu)'), category = _('RADIOS (EX)')},
{down = 3099, cockpit_device_id = 18, value_down = 1.0, name = _('PTT 2 - Mic switch aft: transmit on R2 (comm menu)'), category = _('RADIOS (EX)')},


{combos = {{key = 'A', reformers = {'RAlt'}}}, down = 3102, cockpit_device_id = 10, value_down = 1.0, name = _('A/P - Engage / disengage (HDG / ATT by the bank; ALT, STR if selected)'), category = _('AUTOPILOT (EX)')},
{down = 3103, cockpit_device_id = 10, value_down = 1.0, name = _('A/P - ALT HOLD select / deselect'), category = _('AUTOPILOT (EX)')},
{down = 3104, cockpit_device_id = 10, value_down = 1.0, name = _('A/P - STR (couple to the HSI steering) select / deselect'), category = _('AUTOPILOT (EX)')},
{combos = {{key = 'A', reformers = {'RAlt','RShift'}}}, down = 3105, cockpit_device_id = 10, value_down = 1.0, name = _('A/P - Paddle: autopilot off'), category = _('AUTOPILOT (EX)')},
{down = 3135, up = 3136, cockpit_device_id = 9, value_down = 1.0, value_up = 0.0, name = _('FCS - G limit override (hold): 12 g at full aft stick'), category = _('Flight Control')},
{down = 3106, cockpit_device_id = 10, value_down = 1.0, name = _('HDG select - Heading +1'), category = _('AUTOPILOT (EX)')},
{down = 3107, cockpit_device_id = 10, value_down = 1.0, name = _('HDG select - Heading -1'), category = _('AUTOPILOT (EX)')},
{down = 3108, cockpit_device_id = 10, value_down = 1.0, name = _('HDG select - Sync to the heading now'), category = _('AUTOPILOT (EX)')},
{down = 3109, cockpit_device_id = 10, value_down = 1.0, name = _('HDG select - Steering HDG (fly the selected heading)'), category = _('AUTOPILOT (EX)')},
{down = iCommandToggleCommandMenu, name = _('Communications menu'), category = _('RADIOS (EX)')},
{down = 3090, cockpit_device_id = 18, value_down = 1.0, name = _('R1 - Channel up'), category = _('RADIOS (EX)')},
{down = 3091, cockpit_device_id = 18, value_down = 1.0, name = _('R1 - Channel down'), category = _('RADIOS (EX)')},
{down = 3092, cockpit_device_id = 18, value_down = 1.0, name = _('R2 - Channel up'), category = _('RADIOS (EX)')},
{down = 3093, cockpit_device_id = 18, value_down = 1.0, name = _('R2 - Channel down'), category = _('RADIOS (EX)')},
{down = 3094, cockpit_device_id = 18, value_down = 1.0, name = _('R1 - Power on / off'), category = _('RADIOS (EX)')},
{down = 3095, cockpit_device_id = 18, value_down = 1.0, name = _('R2 - Power on / off'), category = _('RADIOS (EX)')},
{down = 3096, cockpit_device_id = 18, value_down = 1.0, name = _('R1 - Guard on / off'), category = _('RADIOS (EX)')},
{down = 3097, cockpit_device_id = 18, value_down = 1.0, name = _('R2 - Guard on / off'), category = _('RADIOS (EX)')},

{combos = {{key = 'N'}}, down = iCommandViewNightVisionGogglesOn, name = _('NVG - Goggles on / off'), category = _('NVG / HMD (EX)')},
{combos = {{key = 'N', reformers = {'RCtrl'}}}, pressed = iCommandPlane_Helmet_Brightess_Up, name = _('NVG - Gain up'), category = _('NVG / HMD (EX)')},
{combos = {{key = 'N', reformers = {'RCtrl','RShift'}}}, pressed = iCommandPlane_Helmet_Brightess_Down, name = _('NVG - Gain down'), category = _('NVG / HMD (EX)')},
{combos = {{key = 'W', reformers = {'RAlt'}}}, down = 178, cockpit_device_id = 5, value_down = 1.0, name = _('WEAPONS - Jettison fuel tanks'), category = _('WEAPONS (EX)')},



{down = fcs, name = _('FCS toggle'), category = _('Autopilot')},

{combos = {{key = 'A'}, {key = '1', reformers = {'LAlt'}}}, down = iCommandPlaneAutopilot, name = _('Autopilot - Attitude Hold'), category = _('Autopilot')},
{combos = {{key = 'H'}, {key = '2', reformers = {'LAlt'}}}, down = iCommandPlaneStabHbar, name = _('Autopilot - Altitude Hold'), category = _('Autopilot')},
{combos = {{key = '9', reformers = {'LAlt'}}}, down = iCommandPlaneStabCancel, name = _('Autopilot Disengage'), category = _('Autopilot')},
{combos = {{key = '1', reformers = {'LCtrl'}}}, down = iCommandHelicopter_PPR_button_T_up, name = _('CAS Pitch'), category = _('Autopilot')},
{combos = {{key = '2', reformers = {'LCtrl'}}}, down = iCommandHelicopter_PPR_button_K_up, name = _('CAS Roll'), category = _('Autopilot')},
{combos = {{key = '3', reformers = {'LCtrl'}}}, down = iCommandHelicopter_PPR_button_H_up, name = _('CAS Yaw'), category = _('Autopilot')},


{combos = {{key = 'T', reformers = {'LAlt'}}}, down = iCommandPlaneTrimOn, up = iCommandPlaneTrimOff, name = _('T/O Trim'), category = _('Flight Control')},


{combos = {{key = 'R', reformers = {'LCtrl'}}}, down = iCommandPlaneAirRefuel, name = _('Refueling Boom'), category = _('Systems')},
{combos = {{key = 'R', reformers = {'LAlt'}}}, down = iCommandPlaneJettisonFuelTanks, name = _('Jettison Fuel Tanks'), category = _('Systems')},
{combos = {{key = 'S'}}, down = iCommandPlane_HOTAS_NoseWheelSteeringButton, up = iCommandPlane_HOTAS_NoseWheelSteeringButton, name = _('Nose Gear Maneuvering Range'), category = _('Systems')},
{combos = {{key = 'Q', reformers = {'LAlt'}}}, down = iCommandPlane_HOTAS_NoseWheelSteeringButtonOff, name = _('Nose Wheel Steering on / off'), category = _('Systems')},
{combos = {{key = 'A', reformers = {'LCtrl'}}}, down = iCommandPlaneWheelBrakeLeftOn, up = iCommandPlaneWheelBrakeLeftOff, name = _('Wheel Brake Left On/Off'), category = _('Systems')},
{combos = {{key = 'A', reformers = {'LAlt'}}}, down = iCommandPlaneWheelBrakeRightOn, up = iCommandPlaneWheelBrakeRightOff, name = _('Wheel Brake Right On/Off'), category = _('Systems')},
{combos = {{key = 'T', reformers = {'LShift'}}}, down = iCommandClockElapsedTimeReset, name = _('Elapsed Time Clock Start/Stop/Reset'), category = _('Systems')},
{combos = {{key = 'D', reformers = {'LShift'}}}, down = iCommandPlaneFSQuantityIndicatorSelectorMAIN, name = _('Fuel Quantity Selector'), category = _('Systems')},
{combos = {{key = 'D', reformers = {'LCtrl','LAlt'}}}, down = iCommandPlaneFSQuantityIndicatorTest, up = iCommandPlaneFSQuantityIndicatorTest, value_down = 1, value_up = 0, name = _('Fuel Quantity Test'), category = _('Systems')},
{combos = {{key = 'D', reformers = {'LAlt'}}}, down = iCommandPlaneFSQuantityIndicatorSelectorINT,	up = iCommandPlaneFSQuantityIndicatorSelectorINT, value_down = 1,  value_up = 0, 	name = _('Bingo Fuel Index, CW'),  category = _('Systems')},
{combos = {{key = 'D', reformers = {'LCtrl'}}}, down = iCommandPlaneFSQuantityIndicatorSelectorINT,	up = iCommandPlaneFSQuantityIndicatorSelectorINT, value_down = -1, value_up = 0, 	name = _('Bingo Fuel Index, CCW'), category = _('Systems')},
{combos = {{key = 'L', reformers = {'RCtrl','RAlt'}}}, down = iCommandPlaneAntiCollisionLights, name = _('Anti-collision lights'), category = _('Systems')},

{combos = {{key = 'H', reformers = {'RShift'}}}, down = iCommandPlaneHUDFilterOnOff, name = _('Helmet sunglass toggle'), category = _('Systems')},


{combos = {{key = 'G', reformers = {'LAlt'}}}, down = iCommandPlaneHook, name = _('Tail Hook'), category = _('Systems')},



{combos = {{key = '2'}}, down = iCommandPlaneModeBVR, name = _('(2) Beyond Visual Range Mode'), category = _('Modes')},
{combos = {{key = '3'}}, down = iCommandPlaneModeVS, name = _('(3) Close Air Combat Vertical Scan Mode'), category = _('Modes')},
{combos = {{key = '4'}}, down = iCommandPlaneModeBore, name = _('(4) Close Air Combat Bore Mode'), category = _('Modes')},

{combos = {{key = '6'}}, down = iCommandPlaneModeFI0, name = _('(6) Longitudinal Missile Aiming Mode/FLOOD mode'), category = _('Modes')},
{combos = {{key = '7'}}, down = iCommandPlaneModeGround, name = _('(7) Air-To-Ground Mode'), category = _('Modes')},



{combos = {{key = 'Enter'}}, down = iCommandPlaneChangeLock, up = iCommandPlaneChangeLockUp, name = _('Target Lock'), category = _('Sensors')},
{combos = {{key = 'Back'}}, down = iCommandSensorReset, name = _('Radar - Return To Search/NDTWS'), category = _('Sensors')},
{down = iCommandRefusalTWS, name = _('Unlock TWS Target'), category = _('Sensors')},
{combos = {{key = 'I'}}, down = iCommandPlaneRadarOnOff, name = _('Radar On/Off'), category = _('Sensors')},
{combos = {{key = 'I', reformers = {'RAlt'}}}, down = iCommandPlaneRadarChangeMode, name = _('Radar RWS/TWS Mode Select'), category = _('Sensors')},
{combos = {{key = 'I', reformers = {'RCtrl'}}}, down = iCommandPlaneRadarCenter, name = _('Target Designator To Center'), category = _('Sensors')},
{combos = {{key = 'I', reformers = {'RShift'}}}, down = iCommandPlaneChangeRadarPRF, name = _('Radar Pulse Repeat Frequency Select'), category = _('Sensors')},



{combos = {{key = ';'}}, pressed = iCommandPlaneRadarUp, up = iCommandPlaneRadarStop, name = _('Target Designator Up'), category = _('Sensors')},
{combos = {{key = '.'}}, pressed = iCommandPlaneRadarDown, up = iCommandPlaneRadarStop, name = _('Target Designator Down'), category = _('Sensors')},
{combos = {{key = ','}}, pressed = iCommandPlaneRadarLeft, up = iCommandPlaneRadarStop, name = _('Target Designator Left'), category = _('Sensors')},
{combos = {{key = '/'}}, pressed = iCommandPlaneRadarRight, up = iCommandPlaneRadarStop, name = _('Target Designator Right'), category = _('Sensors')},
{combos = {{key = ';', reformers = {'RShift'}}}, pressed = iCommandSelecterUp, up = iCommandSelecterStop, name = _('Scan Zone Up'), category = _('Sensors')},
{combos = {{key = '.', reformers = {'RShift'}}}, pressed = iCommandSelecterDown, up = iCommandSelecterStop, name = _('Scan Zone Down'), category = _('Sensors')},
{combos = {{key = ',', reformers = {'RShift'}}}, pressed = iCommandSelecterLeft, up = iCommandSelecterStop, name = _('Scan Zone Left'), category = _('Sensors')},
{combos = {{key = '/', reformers = {'RShift'}}}, pressed = iCommandSelecterRight, up = iCommandSelecterStop, name = _('Scan Zone Right'), category = _('Sensors')},
{combos = {{key = '='}}, down = iCommandPlaneZoomIn, name = _('Display Zoom In'), category = _('Sensors')},
{combos = {{key = '-'}}, down = iCommandPlaneZoomOut, name = _('Display Zoom Out'), category = _('Sensors')},
{combos = {{key = '-', reformers = {'RCtrl'}}}, down = iCommandDecreaseRadarScanArea, name = _('Radar Scan Zone Decrease'), category = _('Sensors')},
{combos = {{key = '=', reformers = {'RCtrl'}}}, down = iCommandIncreaseRadarScanArea, name = _('Radar Scan Zone Increase'), category = _('Sensors')},


{combos = {{key = 'R', reformers = {'RShift'}}}, down = iCommandChangeRWRMode, name = _('RWR/SPO Mode Select'), category = _('Sensors')},
{combos = {{key = ',', reformers = {'RAlt'}}}, down = iCommandPlaneThreatWarnSoundVolumeDown, name = _('RWR/SPO Sound Signals Volume Down'), category = _('Sensors')},
{combos = {{key = '.', reformers = {'RAlt'}}}, down = iCommandPlaneThreatWarnSoundVolumeUp, name = _('RWR/SPO Sound Signals Volume Up'), category = _('Sensors')},


{combos = {{key = 'V', reformers = {'LCtrl'}}}, down = iCommandPlaneSalvoOnOff, name = _('Salvo Mode'), category = _('Weapons')},
{combos = {{key = 'Space', reformers = {'RAlt'}}}, down = iCommandPlanePickleOn,	up = iCommandPlanePickleOff, name = _('Weapon Release'), category = _('Weapons')},

})
return res
