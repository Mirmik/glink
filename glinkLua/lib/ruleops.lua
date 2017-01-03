local ruleops = {}

function ruleops.__substitute(rule,list)
	for key, value in pairs(list) do
		rule = rule:gsub("%%" .. key .. "%%", value)
	end 
	return rule
end

function ruleops.__substitute_list(rules,list)
	local newrules = {}
	--print(table.tostring(rules))
	for key, value in pairs(rules) do
		newrules[key] = ruleops.__substitute(value, list)
	end
	return newrules
end

function ruleops.substitute(rules, list)
	if (type(rules) == "string") then
		return ruleops.__substitute(rules, list)
	else
		return ruleops.__substitute_list(rules, list)
	end
end

return ruleops