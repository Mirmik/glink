function table.val_to_str ( v )
	if "string" == type( v ) then
	v = string.gsub( v, "\n", "\\n" )
	if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
		return "'" .. v .. "'"
	end
	return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
	else
	return "table" == type( v ) and table.tostring( v ) or
		tostring( v )
	end
end

function table.key_to_str ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
	return k
	else
	return "[" .. table.val_to_str( k ) .. "]"
	end
end

function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
	table.insert( result, table.val_to_str( v ) )
	done[ k ] = true
	end
	for k, v in pairs( tbl ) do
	if not done[ k ] then
		table.insert( result,
		table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
	end
	end
	return "{" .. table.concat( result, "," ) .. "}"
end

function table.shallow_copy (t) -- shallow-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do target[k] = v end
    setmetatable(target, meta)
    return target
end

function table.deep_copy (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = table.deep_copy(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

function table.printKeys(t)
	for k,v in pairs(t) do
		print(k)
	end
end

function string:split(sep)
	local t={} ; i=1
    for str in self:gmatch("[^"..sep.."]+") do
        t[i] = str
        i = i + 1
    end
    return t
end

function table.arrayConcat(a,b,...)
	local c = {}
	local cindex = 1
	for aindex = 1, #a do c[cindex] = a[aindex]; cindex = cindex + 1 end
	for bindex = 1, #b do c[cindex] = b[bindex]; cindex = cindex + 1 end
    for i,v in ipairs(arg) do
        for j = 1, #v do c[cindex] = v[j]; cindex = cindex + 1 end
    end
	return c
end

local lfs = require("lfs")
function recursiveMkdir(dir)
	local function f(dir)
		if (lfs.attributes(dir)) then return end
		
		local parentdir = pathops.dirname(dir);
		if (not lfs.attributes(parentdir)) then f(parentdir) end

		print("MKDIR\t" .. pathops.resolve(process.env.PWD, dir));
		fs.mkdirSync(dir);
	end
	f(dir);
end

function table.merge(target, object)     
    for key, variable in pairs(object) do
        if (type(key) == "number") then
            target[#target + 1] = object[key]
        elseif target[key] == nil then 
            target[key] = object[key] 
        else
        	if (type(object[key]) == "table") and (type(target[key]) == "table") then
            	table.merge(target[key], object[key]) 
        	elseif type(object[key]) == type(target[key]) then
            	target[key] = variable
        	else
                print(key)
                print(target[key])
        		print(table.tostring(object[key]))
                error "Merge Error"
        	end
        end
    end
end

function table.contains(array, object)     
    for i = 1, #array do
    	if array[i] == object then return true end
    end
    return nil
end

util = {}
function util.map(array, func)
	local outarray = {}
	for i = 1, #array do
		outarray[i] = func(array[i])
	end
	return outarray
end

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function util.base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function util.base64_decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(7-i) or 0) end
        return string.char(c)
	end))
end