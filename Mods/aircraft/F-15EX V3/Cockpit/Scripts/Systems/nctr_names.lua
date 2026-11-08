









local M = {}


function M.name(dcs_type)
	return (string.gsub(string.upper(dcs_type or ""), "_", " "))
end


function M.show(raw)
	raw = raw or ""
	local kind, rest = string.match(raw, "^([CT]):(.*)$")
	if kind == "C" then return rest end
	if kind == "T" then
		local name, cls = string.match(rest, "^(.*)|([^|]*)$")
		if not name then name, cls = rest, "" end
		if name ~= "" then return M.name(name) end
		return cls ~= "" and cls or "UNK"
	end
	return raw == "UNK" and "UNK" or ""
end

return M
