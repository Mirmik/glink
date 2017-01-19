local pathops = {}

local at = function(str,i) return str:sub(i,i) end

function pathops.simplify(P) 
    assert(type(P) == "string")

    -- Split path into anchor and relative path.
    local anchor = ''
    local sep = '/'
   
   	-- According to POSIX, in path start '//' and '/' are distinct,
	-- but '///+' is equivalent to '/'.
	if P:match '^//' and at(P,3) ~= '/' then 
        anchor = '/'
        P = P:sub(3)
    elseif at(P,1) == '/' then
        anchor = '/'
        P = P:match '^/*(.*)$'
    end
    
    local parts = {}
    for part in P:gmatch('[^'..sep..']+') do
        if part == '..' then
            if #parts ~= 0 and parts[#parts] ~= '..' then
                table.remove(parts)
            else
                table.insert(parts, part)
            end
        elseif part ~= '.' then
            table.insert(parts, part)
        end
    end
    P = anchor..table.concat(parts, sep)
    if P == '' then P = '.' end
    return P
end


function pathops.resolve(base, path)
	base = base:match('/$') and base or (base .. '/')
	local res = pathops.simplify(base .. path)
	return res
end

function pathops.dirname(path)
    retpath = path:gsub('[^/]+/*$', '');
    if (retpath == path) then retpath = "./" end
    return retpath
end

function pathops.isAbsolute(path)
    return at(path, 1) == '/'
end

return pathops