local text = dofile(__directory .. "/lib/text.lua")

local ModuleClass = dofile(__directory .. "/classes/ModuleClass.lua")
local ImplementationClass = dofile(__directory .. "/classes/ImplementationClass.lua")
local VariantModuleClass = dofile(__directory .. "/classes/VariantModuleClass.lua")

local ModuleLibrary = {}
ModuleLibrary.__index = ModuleLibrary

function ModuleLibrary:new(script) 
	local mlib = {}
	setmetatable(mlib, self)

	mlib.script = script
	mlib.moduleList = {}

	return mlib		
end

function ModuleLibrary:moduleInternalRoutine(Mod)
	local mod = Mod.mod;
	Mod:setMtime(self.script.mtime);
	Mod.moduleDirectory = self.script.currentDir;
	Mod.moduleFile = self.script.currentFile;
end

function ModuleLibrary:variantModuleInternalRoutine(Mod)
	local mod = Mod.mod;
	Mod.moduleDirectory = self.script.currentDir;
	Mod.moduleFile = self.script.currentFile;
end

function ModuleLibrary:addModule(Mod) 
	self:moduleInternalRoutine(Mod);
	if (self.moduleList[Mod.name]) then
		print(text.red("ModuleClass's name conflict: ") .. text.yellow(Mod.name)) 
		print("Early it was defined in\t\t" .. text.yellow(self.moduleList[Mod.name].moduleFile))
		print("Now we second have define in\t" .. text.yellow(Mod.moduleFile)) 
		error("ModuleClass's name conflict")
	end
	self.moduleList[Mod.name] = Mod;
end

function ModuleLibrary:addImplementation(Impl)
	self:moduleInternalRoutine(Impl.module);		
	
	if (self.moduleList[Impl.module.name] == nil) then
		local variant = VariantModuleClass:new(Impl.module.name)
		self:variantModuleInternalRoutine(variant)
		self.moduleList[Impl.module.name] = variant
	end

	if (self.moduleList[Impl.module.name].type == "variant") then
		self.moduleList[Impl.module.name]:addImplementation(Impl);
	else 
		print(text.red("VariantModuleClass's name conflict: ") .. text.yellow(Impl.module.name)) 
		print("Early it was defined in\t\t" .. text.yellow(self.moduleList[Impl.module.name].moduleFile))
		print("Now we second have define in\t" .. text.yellow(Impl.module.moduleFile)) 
		error("VariantModuleClass's name conflict")
	end

	return;
end

function ModuleLibrary:printInfo(name) 
	local mod = self.moduleList[name];
	if (mod == nil) then 
		print(text.red(name) .. " is undefined module") 
	else 
		if (mod.type == "simple") then
			print(text.yellow(name) .. " is simple module")	
		else 
			if (mod.type == "variant") then
				print(text.yellow(name) .. " is variant module. Defined implementations:")
				for k, v in pairs(mod.implementations) do
					print(k)
				end
			end
		end
	end
end

function ModuleLibrary:printInfoRegEx(regex)
	print("Info for modules matches regexp " .. regex)
	for k, v in pairs(self.moduleList) do
		if (k:match(regex)) then
			self:printInfo(k);
		end
	end
end

function ModuleLibrary:getModule(name)
	local rec = self:getModuleRecord(name);
	return self:moduleCopy(rec);
end

function ModuleLibrary:getRealModule(name,impl)
	local rec = self:getRealModuleRecord(name, impl);
	return self:moduleCopy(rec);
end

function ModuleLibrary:getModuleRecord(name)
	local ret = self.moduleList[name];
	if (not ret) then
		print(text.red("Попытка получения несуществующего модуля ") .. text.yellow(name))
		os.exit(1);
	end
	return ret;
end

function ModuleLibrary:getRealModuleRecord(name,impl)
	local mod = self:getModuleRecord(name);
	
	local ret;
	if (mod.type == "simple") then
		if (impl) then error "This module dont have implementations" end
		return mod;
	end

	if (mod.type == "variant") then
		if (impl == nil) then error "This module need to implementation" end
		ret = mod:getImplementation(impl);
		if (ret == nil) then error "Implementation is not released" end
		return ret; 
	end
end

function ModuleLibrary:moduleCopy(original)
	local clone = table.deep_copy(original)
	return clone;
end

function ModuleLibrary:resolveSubmod(sub)
	assert(sub.name, "resolveSubmod1")
	
	local mod = self:getRealModule(sub.name, sub.impl)
	
	assert(mod, "resolveSubmod2")
	return mod
end

return ModuleLibrary