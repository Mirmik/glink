local text = {}

function text.block(str)
	return  string.char(27) .. str ..  string.char(27) .. "[0m"
end

function text.red(str)
	return text.block("[31;1m" .. str)
end

function text.green(str)
	return text.block("[32;1m" .. str)
end

function text.yellow(str)
	return text.block("[33;1m" .. str)
end

return text