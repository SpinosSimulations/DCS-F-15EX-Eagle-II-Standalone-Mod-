

start_custom_command = 10000
local __count_custom = start_custom_command - 1
local function __custom_counter()
	__count_custom = __count_custom + 1
	return __count_custom
end

Keys =
{
	fcs			= 5000,
	fcs_pitch	= 5001,
	fcs_roll	= 5002,


	HmdHeadAz	= 10001,
	HmdHeadEl	= 10002,
	HmdHeadRoll	= 10003,


	HmdHeadTime	= 10004,


	IffOwnCoal	= 10005,


	MslBase		= 10020,
	MslSlots	= 6,


	BullsX		= 10070,
	BullsZ		= 10071,
}

start_command = 3000
local __count = start_command - 1
local function __counter()
	__count = __count + 1
	return __count
end

device_commands =
{


	MsltRadarPower	= 3001,
	MsltNextContact	= 3002,
	MsltLock		= 3003,
	MsltUnlock		= 3004,
	MsltFire		= 3005,
	MsltTestA		= 3006,
	MsltTestB		= 3007,
	MsltTestC		= 3008,





	RdrElUp			= 3011,
	RdrElDown		= 3012,
	RdrScanReset	= 3015,
	RdrRangeUp		= 3016,
	RdrRangeDown	= 3017,

	RdrTdcX			= 3018,
	RdrTdcY			= 3019,
	RdrTdcUp		= 3020,
	RdrTdcDown		= 3021,
	RdrTdcLeft		= 3022,
	RdrTdcRight		= 3023,
	RdrTmsUp		= 3024,
	RdrTmsDown		= 3025,
	RdrTmsLeft		= 3026,
	RdrTmsRight		= 3027,
	RdrAntElev		= 3028,
	RdrWidth		= 3029,
	RdrBars			= 3030,

	WpnGun			= 3031,
	WpnSrm			= 3032,
	WpnMrm			= 3033,
	WpnCycle		= 3034,
	WpnMasterArm	= 3035,
	WpnFire			= 3036,

	FmtLeft			= 3037,
	FmtMiddle		= 3038,
	FmtRight		= 3039,


	CmChaff			= 3040,
	CmFlare			= 3041,

	TewsScale		= 3042,
	SitpRange		= 3043,
	SitpAir			= 3044,
	SitpSam			= 3045,
	SitpJtid		= 3083,



	ElecBattery		= 3046,
	ElecGenL		= 3047,
	ElecGenR		= 3048,
	Jfs				= 3049,
	ThrottleIdleL	= 3054,
	ThrottleIdleR	= 3055,
	AutoStart		= 3056,

	MasterCaution	= 3057,
	BingoUp			= 3058,
	BingoDown		= 3059,

	NavStptNext		= 3060,
	NavStptPrev		= 3061,
	NavTcnUp		= 3062,
	NavTcnDown		= 3063,
	NavTcnUp10		= 3064,
	NavTcnDown10	= 3065,
	NavTcnBand		= 3066,
	NavTcnMode		= 3067,
	NavIlsUp		= 3068,
	NavIlsDown		= 3069,
	NavIlsMode		= 3070,
	NavSteer		= 3071,
	NavCrsUp		= 3072,
	NavCrsDown		= 3073,
	NavGps			= 3074,
	NavAutoSeq		= 3075,
	NavHsiRange		= 3076,


	RdrAcqFwd		= 3077,
	RdrAcqAft		= 3078,
	RdrAcqDepress	= 3079,
	RdrHmdAcq		= 3080,
	SrmUncage		= 3081,
	DispDayNight	= 3082,



	CastleFwd		= 3084,
	CastleLeft		= 3085,
	CastleDown		= 3086,
	CastleRight		= 3087,


	LadTouch		= 3088,

	LadLayoutNext	= 3089,

	RadioR1ChUp		= 3090,
	RadioR1ChDown	= 3091,
	RadioR2ChUp		= 3092,
	RadioR2ChDown	= 3093,
	RadioR1Power	= 3094,
	RadioR2Power	= 3095,
	RadioR1Guard	= 3096,
	RadioR2Guard	= 3097,
	RadioPtt1		= 3098,
	RadioPtt2		= 3099,
	RadioR1Rx		= 3118,
	RadioR2Rx		= 3119,

	LightsFlood		= 3120,
	LightsAar		= 3121,
	LightsMaster	= 3122,
	NwsButton		= 3123,
	NwsButtonUp		= 3124,
	GLimitOverride	= 3135,
	GLimitOverrideUp = 3136,

	GunTrigger		= 3100,


	RdrExp			= 3101,


	ApEngage		= 3102,
	ApAltHold		= 3103,
	ApSteer			= 3104,
	ApPaddle		= 3105,

	NavHdgUp		= 3106,
	NavHdgDown		= 3107,
	NavHdgSync		= 3108,
	NavSteerHdg		= 3109,


	MmAA			= 3110,
	MmNav			= 3111,
	MmCycle			= 3112,

	CmdMan1			= 3113,
	CmdMan2			= 3114,
	CmdMode			= 3115,
	CmdSel			= 3116,


	ApVnav			= 3117,
}
















