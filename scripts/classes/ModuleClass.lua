local ModuleClass = {}
ModuleClass.__index = ModuleClass

function ModuleClass:new(name, mod) 
	local Mod = {}
	setmetatable(Mod, self)

	Mod.name = name
	Mod.mod = mod	
	Mod.type = "simple" 
	Mod.mod.__name__ = name

	return Mod
end

function ModuleClass:getOpts() 
	if not self.mod.opts then self.mod.opts = {} end
	return self.mod.opts;
end

function ModuleClass:getSources() 
	if not self.mod.sources then self.mod.sources = {} end
	return self.mod.sources;
end

function ModuleClass:getMtime() 
	return self.mtime;
end

function ModuleClass:setMtime(time) 
	self.mtime = time;
end

function ModuleClass:getModules() 
	if not self.mod.modules then self.mod.modules = {} end
	return self.mod.modules;
end

return ModuleClass