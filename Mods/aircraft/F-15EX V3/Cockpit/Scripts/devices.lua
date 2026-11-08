
local count = 0
local function counter()
	count = count + 1
	return count
end

devices = {}
devices["SYSTEM"]	= counter()
devices["AVIONICS"]	= counter()

devices["ELECTRIC_SYSTEM"]	= counter()
devices["FCR"]				= counter()
devices["WEAPON_SYSTEM"]	= counter()

devices["RWR"]				= counter()
devices["TEWS"]				= counter()
devices["HUD_AA"]			= counter()

devices["WARN"]				= counter()
devices["NAV"]				= counter()

devices["NVG"]				= counter()
devices["HMD"]				= counter()

devices["RESERVED_13"]			= counter()

devices["MISSILES"]			= counter()

devices["INTERCOM"]			= counter()
devices["UHF1_RADIO"]		= counter()
devices["UHF2_RADIO"]		= counter()
devices["RADIO"]			= counter()
