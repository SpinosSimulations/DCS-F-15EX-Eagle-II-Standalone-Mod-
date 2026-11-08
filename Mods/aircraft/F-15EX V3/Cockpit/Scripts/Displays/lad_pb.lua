











LAD_PB = {
	PITCH = 0.30,
	EDGE = 0.86,
	BOX = 0.22,
	CORNER = 0.86,
	HIT = 0.145,

}


function LAD_PB.pos(n)
	local P = LAD_PB
	if n >= 1 and n <= 5 then return -P.EDGE, P.PITCH * (3 - n), "L" end
	if n >= 6 and n <= 10 then return P.PITCH * (n - 8), -P.EDGE, "B" end
	if n >= 11 and n <= 15 then return P.EDGE, P.PITCH * (n - 13), "R" end
	if n >= 16 and n <= 20 then return P.PITCH * (18 - n), P.EDGE, "T" end
end



function LAD_PB.corner(k)
	local c = LAD_PB.CORNER
	local xy = {{-c, c}, {c, c}, {c, -c}, {-c, -c}}
	return xy[k - 20][1], xy[k - 20][2]
end


function LAD_PB.at(x, y)
	local P = LAD_PB
	for n = 1, 24 do
		local bx, by
		if n <= 20 then bx, by = P.pos(n) else bx, by = P.corner(n) end
		if math.abs(x - bx) <= P.HIT and math.abs(y - by) <= P.HIT then return n end
	end
end



function LAD_PB.legend_pos(n)
	local x, y, e = LAD_PB.pos(n)
	if e == "L" then return -0.935, y, "LeftCenter" end
	if e == "R" then return 0.935, y, "RightCenter" end
	return x, y, "CenterCenter"
end



LAD_MENU1, LAD_MENU2, LAD_MENU_LAYOUT = 99, 98, 97
LAD_PB_LAYOUT = 22




LAD_MENU1_ITEMS = {
	[1] = {"ADI", 7}, [2] = {"ARMT", 2}, [3] = {"HSI", 6}, [4] = {"TF", 12}, [5] = {"TSD", 13},
	[6] = {"PROG", 18}, [8] = {"SIT-P", 5}, [9] = {"FCS", 8}, [10] = {"IRST", 16},
	[11] = {"M2", LAD_MENU2}, [12] = {"TGT IR", 14}, [13] = {"EW-P", 3}, [14] = {"A/G RDR", 11}, [15] = {"ATTACK", 1},
	[16] = {"DVR", 10}, [17] = {"HUD", 28}, [18] = {"ENG", 4}, [19] = {"EVENT", 15}, [20] = {"BIT", 9},
}





LAD_MENU2_ITEMS = {
	[1] = {"WIND\nMODEL", 19}, [2] = {"A/G\nDLVRY", 20}, [3] = {"IFF", 21}, [4] = {"IMAGERY", 22}, [5] = {"DATA\nFRAME", 23},
	[6] = {"PROG", 18}, [7] = {"COMM", 34}, [8] = {"LIGHTS", 35}, [9] = {"HUD\nPROG", 28}, [10] = {"OWS", 24},
	[11] = {"M3", LAD_MENU1}, [13] = {"LINK 16", 25}, [14] = {"SMRT\nWPNS", 26}, [15] = {"TEXT", 27},
	[19] = {"MC\nDTM", 29}, [20] = {"INS", 31},
}
local mav_ok, mav_on = false, false
if mav_ok and mav_on then LAD_MENU2_ITEMS[16] = {"MAV", 37} end



LAD_PB_MENU, LAD_PB_RCD = 11, 12
