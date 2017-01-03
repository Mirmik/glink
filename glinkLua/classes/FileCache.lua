--local File = dofile(__directory .. "/classes/File.lua")
local lfs = require("lfs");
local pathops = dofile(__directory .. "/lib/pathops.lua")

local FileCache = {}
FileCache.__index = FileCache

function FileCache:new()
	local fcache = {}
	setmetatable(fcache, self)

	fcache.cache = {}

	return fcache
end

function FileCache:addFile(file)
	self.cache[file.path] = file;
end

function FileCache:getFile(path)
	if self.cache[path] then return self.cache[path] end
	return self:updateFile(path)
end

function FileCache:updateFile(path)
	self.cache[path] = File:new(path)
	return self.cache[path]
end

return FileCache