






local M = {}

M.TABLE = {

	{"f-4", "F4"}, {"f-5", "F5"}, {"f-14", "14"}, {"f-15", "15"}, {"f-16", "16"}, {"fa-18", "18"}, {"f/a-18", "18"},
	{"av8b", "18"}, {"av-8b", "18"}, {"tornado", "TO"}, {"m-2000c-5", "M5"}, {"m-2000", "M2"}, {"mirage-f1", "M1"},
	{"mirage f1", "M1"}, {"ajs37", "37"}, {"ajs-37", "37"}, {"b-1", "51"}, {"b-52", "52"}, {"s-3b", "S3"}, {"e-2", "E2"},
	{"e-3", "E3"}, {"su-17", "FT"}, {"mig-19", "19"}, {"mig-21", "21"}, {"mig-23", "23"}, {"mig-27", "23"}, {"su-24", "24"},


	{"mig-25", "25"}, {"mig-29", "29"}, {"su-27", "27"}, {"su-30", "30"}, {"su-33", "33"}, {"j-11", "11"}, {"mig-31", "31"},
	{"su-34", "34"}, {"tu-22", "62"}, {"tu-95", "65"}, {"tu-142", "65"}, {"tu-160", "65"}, {"a-50", "50"}, {"jf-17", "KL"},
	{"kj-2000", "KJ"}, {"f-35", "35"}, {"f-22", "22"}, {"eurofighter", "EF"}, {"j-20", "20"},

	{"aim-120", "M"}, {"aim_120", "M"}, {"r-77", "M"}, {"sd-10", "M"}, {"r-37", "M"}, {"pl-12", "M"},

	{"la_combattante", "CT"}, {"ticonderog", "Y1"}, {"arleigh", "Y1"}, {"uss_", "Y1"}, {"perry", "49"}, {"vinson", "48"},
	{"stennis", "48"}, {"cvn", "48"}, {"tarawa", "48"}, {"lha", "48"}, {"albatros", "N4"}, {"kuznecow", "N4"},
	{"kuznetsov", "N4"}, {"rezky", "N4"}, {"molniya", "NS"}, {"moscow", "N3"}, {"moskva", "N3"}, {"neustrash", "N9"},
	{"piotr", "N9"}, {"type_052b", "H2"}, {"052b", "H2"}, {"type_052c", "H9"}, {"052c", "H9"}, {"type_054", "H6"},
	{"054a", "H6"}, {"type_071", "HS"}, {"type_093", "HS"},

	{"hawk", "HK"}, {"patriot", "PT"}, {"gepard", "GP"}, {"vulcan", "VL"}, {"roland", "RD"}, {"nasams", "NS"},
	{"fps-117", "EW"}, {"fps117", "EW"}, {"rapier", "RA"},
	{"snr_75", "2"}, {"p-19", "2"}, {"snr s-125", "3"}, {"s-125", "3"}, {"rls_19j6", "5"}, {"5n62", "5"}, {"s-200", "5"},
	{"9a331", "15"}, {"tor ", "15"}, {"1s91", "6"}, {"kub", "6"}, {"osa", "8"}, {"9a33", "8"}, {"s-300", "10"}, {"40b6", "10"}, {"64h6", "10"},
	{"9s18m1", "11"}, {"9a310m1", "11"}, {"buk", "11"}, {"sa-11", "11"}, {"strela-10", "13"},
	{"tunguska", "S9"}, {"2s6", "S9"}, {"shilka", "AA"}, {"zsu-23-4", "AA"}, {"hq-7", "H7"},
	{"son_9", "FC"}, {"son-9", "FC"}, {"1l13", "EW"}, {"55g6", "EW"}, {"ewr", "EW"}, {"dog ear", "DE"},
}


function M.code(unit_type)
	local t = string.lower(tostring(unit_type or ""))
	if t == "" or t == "0" then return "U" end
	for _, e in ipairs(M.TABLE) do
		if string.find(t, e[1], 1, true) then return e[2] end
	end
	return "U"
end










M.WSTYPE_NAMES = {
	MiG_23_ = {"MiG-23MLD"}, MiG_29_ = {"MiG-29A", "MiG-29S"}, MiG_29G_ = {"MiG-29G"}, Su_27_ = {"Su-27"},
	Su_33_ = {"Su-33"}, F_14_ = {"F-14A"}, F_15_ = {"F-15C"}, F_15E_ = {"F-15E"}, F_16_ = {"F-16C bl.50", "F-16C bl.52d"},
	F_16A_ = {"F-16A", "F-16A MLU"}, Su_30_ = {"Su-30"}, FA_18_ = {"F/A-18A"}, FA_18C_ = {"F/A-18C"}, Su_34_ = {"Su-34"},
	Mirage_ = {"Mirage 2000-5"}, F_4E_ = {"F-4E"}, F_5E_ = {"F-5E"}, Su_24_ = {"Su-24M"}, Su_24MR_ = {"Su-24MR"},
	AV_8B_ = {"AV8BNA"}, Tu_160_ = {"Tu-160"}, B_1_ = {"B-1B"}, Tu_22M3_ = {"Tu-22M3"}, MiG_25P_ = {"MiG-25PD"},
	MiG_31_ = {"MiG-31"}, Tu_95_ = {"Tu-95MS"}, Tu_142_ = {"Tu-142"}, B_52_ = {"B-52H"}, A_50_ = {"A-50"}, E_3_ = {"E-3A"},
	S_3A_ = {"S-3B"}, S_3R_ = {"S-3B Tanker"}, E_2C_ = {"E-2C"}, C_17_ = {"C-17A"}, C_130_ = {"C-130"}, IL_76_ = {"IL-76MD"},
	AN_26B_ = {"An-26B"}, AN_30M_ = {"An-30M"}, KC_135_ = {"KC-135", "KC135MPRS"}, IL_78_ = {"IL-78M"}, Su_39_ = {"Su-25TM"},
	EWR_1L13_ = {"1L13 EWR"}, EWR_55G6_ = {"55G6 EWR"}, S300PS_SR_5N66M = {"S-300PS 40B6MD sr"},
	S300PS_SR_64H6E = {"S-300PS 64H6E sr"}, S300PS_TR_30N6 = {"S-300PS 40B6M tr"}, Buk_SR_9S18M1 = {"SA-11 Buk SR 9S18M1"},
	Buk_LN_9A310M1 = {"SA-11 Buk LN 9A310M1"}, Kub_STR_9S91 = {"Kub 1S91 str"}, Dog_Ear = {"Dog Ear radar"},
	Roland_rdr = {"Roland Radar"}, Roland_ADS = {"Roland ADS"}, Patriot_STR_ANMPQ_53 = {"Patriot str"},
	Hawk_SR_ANMPQ_50 = {"Hawk sr"}, Hawk_TR_ANMPQ_46 = {"Hawk tr"}, Hawk_CWAR_ANMPQ_55 = {"Hawk cwar"},
	Osa_9A33 = {"Osa 9A33 ln"}, Strela_9A35M3 = {"Strela-10M3"}, Tor_9A331 = {"Tor 9A331"}, Tunguska_2S6 = {"2S6 Tunguska"},
	ZSU_23_4_Shilka = {"ZSU-23-4 Shilka"}, Gepard = {"Gepard"}, Vulcan_M163 = {"Vulcan"}, S125_SR_P_19 = {"p-19 s-125 sr"},
	S125_TR_SNR = {"snr s-125 tr"}, Kuznecow_ = {"KUZNECOW"}, VINSON_ = {"VINSON"}, MOSCOW_ = {"MOSCOW"},
	ALBATROS_ = {"ALBATROS"}, REZKY_ = {"REZKY"}, PERRY_ = {"PERRY"}, MOLNIYA_ = {"MOLNIYA"}, TICONDEROGA_ = {"TICONDEROG"},
	NEUSTRASH_ = {"NEUSTRASH"},
}



M.DCS = {}
function M.load_dcs(path, opener)
	local env = setmetatable({}, {__index = _G})
	local function run(p)
		local text = opener(p)
		if not text then error("can't read "..p) end
		local f, err = loadstring(text, "@"..p)
		if not f then error(err) end
		setfenv(f, env)
		return f()
	end
	env.dofile = run
	local ok, err = pcall(run, path)
	if not ok then return 0, tostring(err) end
	local t, n = {}, 0
	if type(env.symbols) == "table" then
		local by_tuple = {}
		for _, s in ipairs(env.symbols) do if type(s[1]) == "table" then by_tuple[s[1]] = s[2] end end
		for const, names in pairs(M.WSTYPE_NAMES) do
			local code = env[const] and by_tuple[env[const]]
			if code then for _, nm in ipairs(names) do t[nm] = code end end
		end
	end
	if type(env.symbols_strings) == "table" then
		for nm, code in pairs(env.symbols_strings) do
			if type(nm) == "string" and type(code) == "string" then t[nm] = code end
		end
	end
	for nm, code in pairs(t) do if code ~= "" then M.DCS[nm] = code n = n + 1 end end
	return n, nil
end


function M.label(unit_type, code)
	if code == "EW" then return "EW" end
	return M.DCS[tostring(unit_type or "")] or code
end




function M.split(code)
	local n = tonumber(code)
	if n ~= nil then return "", n, true end
	return code, 0, false
end

return M
