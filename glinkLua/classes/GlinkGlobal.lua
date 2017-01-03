local GlinkGlobal = {}

local ModuleClass = dofile(__directory .. "/classes/ModuleClass.lua")
local ImplementationClass = dofile(__directory .. "/classes/ImplementationClass.lua")
local ModuleLibrary = dofile(__directory .. "/classes/ModuleLibrary.lua")

GlinkGlobal.globalModuleLibrary = nil

function GlinkGlobal.Module(name, mod)
	assert(GlinkGlobal.globalModuleLibrary)
	GlinkGlobal.globalModuleLibrary:addModule( ModuleClass:new(name,mod) )
end

function GlinkGlobal.Implementation(name, impl, mod)
	assert(GlinkGlobal.globalModuleLibrary)
	GlinkGlobal.globalModuleLibrary:addImplementation( ImplementationClass:new(name,impl,mod) )
end

return GlinkGlobal