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

function GlinkGlobal.FaultError(modulename, message)
	print(text.red("FaultError") .. "(" .. modulename .. "): " .. message)
	print("ScriptSouce: " .. debug.getinfo(2).short_src .. " " .. debug.getinfo(2).currentline)
	os.exit(1) 
end

function GlinkGlobal.FaultErrorInOptions(opts, message)
	print(text.red("FaultError") .. "(" .. opts.__name__ .. "): " .. message)
	print("ScriptSouce: " .. opts.__file__ .. ":" .. opts.__line__) 
	os.exit(1) 
end

function GlinkGlobal.FaultErrorDeep(modulename, message, deep)
	print(text.red("FaultError") .. "(" .. modulename .. "): " .. message)
	print("ScriptSouce:")
	for i = 2, deep+1 do
		print(debug.getinfo(i).short_src, debug.getinfo(i).currentline)
	end
	os.exit(1) 
end

return GlinkGlobal