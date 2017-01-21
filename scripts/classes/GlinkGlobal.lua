local GlinkGlobal = {}

local ModuleClass = require("glink.classes.ModuleClass")
local ImplementationClass = require("glink.classes.ImplementationClass")
local ModuleLibrary = require("glink.classes.ModuleLibrary")
local FileCache = require("glink.classes.FileCache")

GlinkGlobal.globalModuleLibrary = nil
GlinkGlobal.globalFaileCache = nil

function GlinkGlobal.Module(name, mod)
	assert(GlinkGlobal.globalModuleLibrary)
	GlinkGlobal.globalModuleLibrary:addModule( ModuleClass:new(name,mod) )
end

function GlinkGlobal.Implementation(name, impl, mod)
	assert(GlinkGlobal.globalModuleLibrary)
	GlinkGlobal.globalModuleLibrary:addImplementation( ImplementationClass:new(name,impl,mod) )
end

--function GlinkGlobal.getFile(name)
--	assert(GlinkGlobal.globalFileCache)
--	return GlinkGlobal.globalFileCache:getFile(name);
--end

return GlinkGlobal