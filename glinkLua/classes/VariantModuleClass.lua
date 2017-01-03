local VariantModuleClass = {}
VariantModuleClass.__index = VariantModuleClass

function VariantModuleClass:new(name, mod) 
	local Mod = {}
	
	setmetatable(Mod, self)

	Mod.name = name
	Mod.implementations = {}	
	Mod.type = "variant"

	return Mod
end

function VariantModuleClass:addImplementation(mod) 
	self.implementations[mod.impl] = mod.module;
end

function VariantModuleClass:getImplementation(name) 
	return self.implementations[name];
end

function VariantModuleClass:print() 
	table.printKeys(self.implementations);
end

return VariantModuleClass