local ModuleClass = dofile(__directory .. "/classes/ModuleClass.lua")

local ImplementationClass = {}

function ImplementationClass:new(name, impl, mod) 
	local Impl = {}
	
	setmetatable(Impl, self)
	Impl.__index = self

	Impl.impl = impl
	Impl.module = ModuleClass:new(name, mod)	

	return Impl
end

return ImplementationClass