glinkLib = require("glinkLib")

local text = require("glink.lib.text")
local pathops = require("glink.lib.pathops")
local ruleops = require("glink.lib.ruleops")
--local FileCache = dofile(__directory .. "/classes/FileCache.lua")

--local ModuleClass = dofile(__directory .. "/classes/ModuleClass.lua")
--local ImplementationClass = dofile(__directory .. "/classes/ImplementationClass.lua")
--local VariantModuleClass = dofile(__directory .. "/classes/VariantModuleClass.lua")

local CXXDeclarativeCompiler = {}
CXXDeclarativeCompiler.__index = CXXDeclarativeCompiler

function CXXDeclarativeCompiler:new(args) 
	local compiler = {}
	setmetatable(compiler, self)
	compiler.opts = args.opts and args.opts or {}

	--assert(args.buildutils, "Need buildutils property in CXXDeclarativeCompiler constructor's args");
	--assert(args.buildutils.CXX, "Need CXX property in buildutils");
	--assert(args.buildutils.CC, "Need CC property in buildutils");
	--assert(args.buildutils.AR, "Need AR property in buildutils");
	--assert(args.buildutils.OBJDUMP, "Need OBJDUMP property in buildutils");
	
	--//We use FileCache as file operations manager.
	compiler.fileCache = FileCache:new()


	if (not compiler.opts.optimization) then compiler.opts.optimization = "-O2" end
	compiler:restoreOptsFull(compiler.opts, '.')

	--Compiler rules prototypes.
	compiler.rules = ruleops.substitute({
		cxx_rule = "%CXX% -c %src% -o %tgt% %__options__%",
		cc_rule = "%CC% -c %src% -o %tgt% %__options__%",
		s_rule = "%CC% -c %src% -o %tgt% %__options__%",
		cxx_dep_rule = "%CXX% -MM %src% > %tgt% %__options__%",
		cc_dep_rule = "%CC% -MM %src% > %tgt% %__options__%",
		s_dep_rule = "%CC% -MM %src% > %tgt% %__options__%",
		ld_rule = "%CXX% %objs% -o %tgt% %__options__%",
		__options__ = "%STANDART% %OPTIMIZATION% %DEFINES% %INCLUDE% %OPTIONS%",
		
		fortran_rule = "%FORTRAN% -cpp -c %src% -o %tgt% %__fortran_options__%",
		fortran_dep_rule = "%FORTRAN% -cpp -MM %src% > %tgt% %__fortran_options__%",
		__fortran_options__ = "%INCLUDE%",
		
		__link_options__ = "%OPTIMIZATION% %LIBS% %SHARED% %LDSCRIPTS% %OPTIONS%",
	}, args.buildutils);

	--We use global context as default.
	compiler.mlib = GlinkGlobal.globalModuleLibrary;

	return compiler		
end

function CXXDeclarativeCompiler:standartArgsRoutine(OPTS)  	
	if (OPTS.j) then
		self.parallel = OPTS.j
	end
	
	OPTS.silent = OPTS.silent and OPTS.silent or OPTS.s
	OPTS.debug = OPTS.debug and OPTS.debug or OPTS.d

	if (OPTS.debug) then
		self.info = "debug"
	end

	if (OPTS.silent) then
		self.info = "silent"
	end

	if (OPTS.silent and OPTS.debug) then
		error(text.red("Silent and debug options at one moment???"))
	end

	if (OPTS[1]) then
		if OPTS[1] == "clean" then
			--self:cleanBuildDirectory()
			self.clean = true;
			--os.exit(0)
		elseif OPTS[1] == "rebuild" then
			self.forceRebuild = true 
		--elseif OPTS[1] == "install" then
		--	os.execute("bash ./install.sh")
		--	os.exit(0) 
		else
			error(text.red("Unresolved Parametr ") .. text.yellow(OPTS[1]))
		end
	end
end

local function __helper_stringToArray(obj) 
	if (not obj) then return {} end
	if (type(obj) == "string") then return obj:split(' ') end
	return obj
end

local function __helper_concat(array, donor)
	if (not array) then return end
	return table.arrayConcat(array, donor)
end

local function __helper_restorePathArray(array, base)
	if (not array) then return end
	for i = 1, #array do
		if not pathops.isAbsolute(array[i]) then
			array[i] = pathops.resolve(base, array[i])
		end
	end
	--print(table.tostring(array))
end


--OPTIONS OPERATIONS
function __helper_resolveOptions3(o,n,t)
	local opts = table.deep_copy(o)

	if n then
		table.merge(opts, n)
	end

	if t then 
		table.merge(opts, t)
	end

	return opts;
end

function __helper_resolveOptions2(o,n)
	local opts = table.deep_copy(o)

	if n then
		table.merge(opts, n)
	end

	return opts;
end

--Prepare opts
function CXXDeclarativeCompiler:restoreOpts(opts, basedir) 
	opts.includePaths = __helper_stringToArray(opts.includePaths)
	opts.ldscripts = __helper_stringToArray(opts.ldscripts)
	opts.libs = __helper_stringToArray(opts.libs)
	opts.defines = __helper_stringToArray(opts.defines)

	if (opts.options) then
		--opts.options.all = __helper_stringToArray(opts.options.all)
		opts.options.cxx = __helper_stringToArray(opts.options.cxx)
		opts.options.cc = __helper_stringToArray(opts.options.cc)
		opts.options.ld = __helper_stringToArray(opts.options.ld)
		opts.options.fortran = __helper_stringToArray(opts.options.fortran)

		--if opts.options.all then
		--	opts.options.cxx = __helper_concat(opts.options.cxx, opts.options.all);
		--	opts.options.cc = __helper_concat(opts.options.cc, opts.options.all);
		--	opts.options.ld = __helper_concat(opts.options.ld, opts.options.all);
		--end
	end
	__helper_restorePathArray(opts.includePaths, basedir)
	__helper_restorePathArray(opts.ldscripts, basedir)
	
end

--Prepare full opts
function CXXDeclarativeCompiler:restoreOptsFull (opts, basedir)
	if (opts.options == nil) then opts.options = {} end

	--if (not opts.options.all) then opts.options.all = {} end
	if (not opts.options.cxx) then opts.options.cxx = {} end
	if (not opts.options.cc) then opts.options.cc = {} end
	if (not opts.options.ld) then opts.options.ld = {} end
	if (not opts.ldscripts) then opts.ldscripts = {} end
	if (not opts.fortran) then opts.fortran = {} end
	if (not opts.libs) then opts.libs = {} end
	if (not opts.defines) then opts.defines = {} end
	if (not opts.includePaths) then opts.includePaths = {} end
	
	if (not opts.standart) then opts.standart = {} end
	if (not opts.standart.cc) then opts.standart.cc = "" end
	if (not opts.standart.cxx) then opts.standart.cxx = "" end
		
	self:restoreOpts(opts, basedir) 
end

--Prepare sources
function CXXDeclarativeCompiler:restoreSources(sources, basedir) 
	if (not sources.cxx) then sources.cxx = {} end
	if (not sources.cc) then sources.cc = {} end
	if (not sources.s) then sources.s = {} end
	if (not sources.fortran) then sources.fortran = {} end

	if (type(sources.cxx) == "string") then sources.cxx = sources.cxx:split(' ') end
	if (type(sources.cc) == "string") then sources.cc = sources.cc:split(' ') end
	if (type(sources.s) == "string") then sources.s = sources.s:split(' ') end
	if (type(sources.fortran) == "string") then sources.fortran = sources.fortran:split(' ') end

	local sourcesDirectory = sources.directory and  
			pathops.resolve(basedir, sources.directory) or 
			basedir; 

	__helper_restorePathArray(sources.cxx, sourcesDirectory);
	__helper_restorePathArray(sources.cc, sourcesDirectory);
	__helper_restorePathArray(sources.s, sourcesDirectory);
	__helper_restorePathArray(sources.fortran, sourcesDirectory);
end

--BUILD DIRECTORY OPERATIONS

--Create build directory if needed
function CXXDeclarativeCompiler:updateDirectory(dir) 
	recursiveMkdir(dir);
end

--/*Unlink all files in build directory*/
function CXXDeclarativeCompiler:cleanDirectory(dir)
	if (not lfs.attributes(dir)) then return end
	for file in lfs.dir(dir) do
		if(not (file == "." or file == "..")) then  
			if self.info == "debug" then
			end
			os.remove(pathops.resolve(dir, file))
		end
	end
end

--RULES OPERATIONS
function CXXDeclarativeCompiler:resolveODRule(protorules, opts) 
	assert(protorules);

	local tempoptions = ruleops.substitute(protorules.__options__, {
		OPTIMIZATION = opts.optimization,
		DEFINES = table.concat(opts.defines," "),
		INCLUDE = table.concat(
			util.map(opts.includePaths, function(file) return "-I" .. file end), 
			" "
		),
	})

	local cc_options = ruleops.substitute(tempoptions, {
		STANDART = opts.standart.cc,
		OPTIONS = table.concat(opts.options.cc," "),
	})

	local cxx_options = ruleops.substitute(tempoptions, {
		STANDART = opts.standart.cxx,
		OPTIONS = table.concat(opts.options.cxx," "),
	})

	local fortran_options = ruleops.substitute(protorules.__fortran_options__, {
		INCLUDE = table.concat(
			util.map(opts.includePaths, function(file) return "-I" .. file end), 
			" "
		),
	})

	local ret = {};
	ret.cc_rule = ruleops.substitute(protorules.cc_rule, {__options__= cc_options});
	ret.cc_dep_rule = ruleops.substitute(protorules.cc_dep_rule, {__options__= cc_options});
	ret.cxx_rule = ruleops.substitute(protorules.cxx_rule, {__options__= cxx_options});
	ret.cxx_dep_rule = ruleops.substitute(protorules.cxx_dep_rule, {__options__= cxx_options});
	ret.fortran_rule = ruleops.substitute(protorules.fortran_rule, {__fortran_options__= fortran_options});
	ret.fortran_dep_rule = ruleops.substitute(protorules.fortran_dep_rule, {__fortran_options__= fortran_options});

	return ret;
end

function CXXDeclarativeCompiler:resolveLinkRule(protorules, opts) 
	assert(protorules);

	local tempoptions = ruleops.substitute(protorules.__link_options__, {
		OPTIMIZATION = opts.optimization,
		LIBS = table.concat(util.map(opts.libs, function(file) return "-l" .. file end), 
			" "),
		LDSCRIPTS = table.concat(
			util.map(opts.ldscripts, function(file) return "-T" .. file end), 
			" "
		),
		OPTIONS = table.concat(opts.options.ld," "),
		SHARED = opts.sharedLibrary and "-shared" or ""
	})
	
	local ret = {};
	ret.ld_rule = ruleops.substitute(protorules.ld_rule, {__options__= tempoptions});
	
	return ret;
end

function CXXDeclarativeCompiler:moduleStateRestore(mod)
	--Restore Opts State.
	local opts = mod:getOpts();
	self:restoreOpts(opts, mod.moduleDirectory);

	--Restore Sources State.
	local sources = mod:getSources();
	self:restoreSources(sources, mod.moduleDirectory);
end

function CXXDeclarativeCompiler:addOptsStateRestore(addopts, mod) 
	if addopts then
		self:restoreOpts(addopts, mod.moduleDirectory);
	end
end

function CXXDeclarativeCompiler:resolveIncludeModules(mod)
	local incmodsrec = mod.mod.includeModules;
	if incmodsrec == nil then
		return 
	end

	local incmods = {};
		
	--Create all includeModules copies.
	for i = 1, #incmodsrec do
		local inc = incmodsrec[i]
		incmods[i] = self.mlib:getRealModule(inc.name, inc.impl)
	end

	--/*For each included module:*/
	for i = 1, #incmods do
		local inc = incmods[i]
		self:moduleStateRestore(inc);
		
		--If inc have own includeModules, resolve these.
		self:resolveIncludeModules(inc);

		--Merge included module to mod and change mtime, if needed. 
		table.merge(mod.mod, inc.mod);
		
		if mod:getMtime() < inc:getMtime() then mod:setMtime(inc:getMtime()) end
	end

	mod.mod.includeModules = nil;
end

function CXXDeclarativeCompiler:moduleTreeToArray (mod)
	local array = {}
	array[1] = mod

	function f(mod) 
		for i = 1, #mod.__submods do 
			local sub = mod.__submods[i]
			array[#array + 1] = sub;
			f(sub);
		end
	end	

	f(mod)
	return array
end

--This operation construct module array for compile ops.
--@mod - Main module. Root of tree.
--@addopts - module's added options
function CXXDeclarativeCompiler:prepareModuleArray(mod, addopts)
	--Worker
	local function f(mod, parentopts, addopts)
		--Add all relative paths to absolute.
		--We use moduleDirectory field's information to this
		self:moduleStateRestore(mod);
		self:addOptsStateRestore(addopts, mod);		
		
		--Apply include modules. It's first operation, because submodules
		--should include all include modules's paths and depends.
		self:resolveIncludeModules(mod);

		--Resolve opts struct. It contains opts: parent, module, added
		mod.__opts = __helper_resolveOptions3(parentopts, mod:getOpts(), addopts)
		mod.__odRules = self:resolveODRule(self.rules, mod.__opts) 

		assert(mod.__opts.builddir)
		self:updateDirectory(mod.__opts.builddir)

		--/*We need submodule's field for tree organization*/
		mod.__submods = {}
		if (not mod:getModules()) then return end

		--If mod have submodules, foreach
		local modules = mod:getModules()
		for i = 1, #modules do
			local subrec = modules[i]
			--get submodule from library
			local sub = self.mlib:resolveSubmod(subrec);
			--add to submodules field.
			mod.__submods[i] = sub
			--use Worker on it.
			f(sub, mod.__opts, subrec.opts);
		end
	end	

	--Invoke worker for main module
	f(mod, self.opts, addopts);

	--Result of worker's recursive invoke is module's tree.
	--This function expand it to array
	local modarray = self:moduleTreeToArray(mod)
	
	return modarray;
end

--MODARRAY OPERATIONS AND CHECKERS
function CXXDeclarativeCompiler:getAllModuleNames(modarray)
	local names = {}
	for i = 1, #modarray do
		local mod = modarray[i]
		names[i] = mod.name
	end
	return names;
end

function CXXDeclarativeCompiler:getAllDependsNames(modarray)
	local depends = {}
	for i = 1, #modarray do
		local mod = modarray[i]
		if mod.mod.depends then  
			if (type(mod.mod.depends) == "string") then 
				mod.mod.depends = mod.mod.depends:split(' ')
			end
			for j = 1, #mod.mod.depends do
				depends[#depends + 1] = {}
				depends[#depends].dep = mod.mod.depends[j]
				depends[#depends].mod = mod
			end
		end
	end
	return depends
end

function CXXDeclarativeCompiler:checkModuleArrayDepends (modarray)
	local nams = self:getAllModuleNames(modarray);
	local deps = self:getAllDependsNames(modarray);

	for i = 1, #deps do
		local dep = deps[i]
		if (not table.contains(nams, dep.dep)) then
			print(text.red("Unresolved depend:") .. text.yellow(dep.mod.name) 
				.. " needs " .. text.yellow(dep.dep));
			self.mlib:printInfo(dep.dep);
			os.exit(1);
		end
	end
end

function CXXDeclarativeCompiler:checkModuleArrayOptions (modarray)
	for i = 1, #modarray do
		local mod = modarray[1]
		if mod.__opts.weakRecompile == "noscript" then 
		elseif mod.__opts.weakRecompile == "norecompile" then
		elseif mod.__opts.weakRecompile == nil then
		else
			print("Wrong " .. text.yellow("weakRecompile")
				.. " option value. " .. text.red(mod.__opts.weakRecompile));
			print("It can be: 'noscript', 'norecompile', undefined.");
			os.exit(1);
		end
	end
end

function CXXDeclarativeCompiler:__assembleObjects(mod, objects) 
	local linkRule = self:resolveLinkRule(self.rules, mod.__opts).ld_rule;
	local target = mod.__opts.target or "target"

	local executable = self:executableUpdate(objects, target, linkRule, mod:getMtime(), mod.__opts.weakRecompile);
	return executable;
end


function CXXDeclarativeCompiler:executableCreate(objectfiles, objects, targetfile, rule)
	rule = ruleops.substitute(rule, {
		objs = table.concat(objects, " "),
		tgt = targetfile.path
	})
	
	if self.info == "debug" then 
		print("LINK " .. rule .. "\r\n");
	elseif self.info == "silent" then
	else
		print("LINK " .. targetfile.path );
	end

	local pipe = assert(io.popen(rule, 'r'))
	local status = pipe:close()
	if (status == nil) then os.exit(1) end
	
	self.fileCache:updateFile(targetfile.path)
end

function CXXDeclarativeCompiler:executableUpdate(objects, target, ldrule, modmtime, weak)
	local objectfiles = {}
	
	for i = 1, #objects do
		local obj = objects[i] 
		objectfiles[i] = self.fileCache:getFile(obj)
	end

	local targetfile = self.fileCache:getFile(target)

	local maxtime = (weak == "noscript") and 0 or modmtime

	for i = 1, #objectfiles do 
		local file = objectfiles[i]
		if file.mtime > maxtime then maxtime = file.mtime end
	end

	if (not targetfile.exists) or (maxtime > targetfile.mtime) then
		self:executableCreate(objectfiles, objects, targetfile, ldrule)
		return targetfile.path;
	end

	return false;
end

function CXXDeclarativeCompiler:objectCreate(sourcefile, objectfile, dependfile, rule, deprule)
	rule = ruleops.substitute(rule, {
		src = sourcefile.path,
		tgt = objectfile.path
	})
	
	deprule = ruleops.substitute(deprule, {
		src = sourcefile.path,
		tgt = dependfile.path
	})
	
	if self.info == "debug" then 
		print(rule .. "\r\n") 
	elseif self.info == "silent" then
	else
		print("OBJECT " .. sourcefile.path) 
	end

	local objpipe = assert(io.popen(rule, 'r'))
	local objstatus = objpipe:close()
	if (objstatus == nil) then os.exit(1) end

	if self.debugInfo then 
		print(deprule) 
	end

	local deppipe = assert(io.popen(deprule, 'r'))
	local depstatus = deppipe:close()
	if (depstatus == nil) then os.exit(1) end

	self.fileCache:updateFile(objectfile.path);
	self.fileCache:updateFile(dependfile.path);
end

function CXXDeclarativeCompiler:needToRecompile(objfile, depfile, modmtime, weak)
	if self.forceRebuild then return true end
	if objfile.exists == false then return true end 
	if depfile.exists == false then return true end 
	if weak == "norecompile" then return false end

	local file = assert(io.open(depfile.path, "r"))
	local deptext = file:read("*a")
	
	if #deptext < 2 then return true end

	local arr = {} 
	for file in deptext:gmatch("[^ \n\\]+") do
		arr[#arr + 1] = file
	end

	local maxtime = (weak == "noscript") and 0 or modmtime
	
	for i = 2, #arr do 
		local file = self.fileCache:getFile(arr[i]);
		if file.exists == false then return true end
		if file.mtime > maxtime then maxtime = file.mtime end
	end
	
	return maxtime > depfile.mtime
end

function CXXDeclarativeCompiler:objectUpdate (path, deprule, objrule, modmtime, weak, dir)
	assert(dir)
	local sourcefile = self.fileCache:getFile(path);
	local objectfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".o");
	local dependfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".d");

	if (self:needToRecompile(objectfile, dependfile, modmtime, weak)) then
		self:objectCreate(sourcefile, objectfile, dependfile, objrule, deprule);
	end

	return objectfile.path;
end

function CXXDeclarativeCompiler:__updateModObjects(mod) 
	assert(mod)
	local weak = mod.__opts.weakRecompile  

	local sources = mod:getSources()
	local objects = {}

	if sources.s then
		for i = 1, #sources.s do
			objects[#objects + 1] = self:objectUpdate(sources.s[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.cc then
		for i = 1, #sources.cc do
			objects[#objects + 1] = self:objectUpdate(sources.cc[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.cxx then
		for i = 1, #sources.cxx do
			objects[#objects + 1] = self:objectUpdate(sources.cxx[i], mod.__odRules.cxx_dep_rule, mod.__odRules.cxx_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.fortran then
		for i = 1, #sources.fortran do
			--print(sources.fortran[i])
			objects[#objects + 1] = self:objectUpdate(sources.fortran[i], mod.__odRules.fortran_dep_rule, mod.__odRules.fortran_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	return objects;
end


--EXTERNAL API
--Main executable assemle method
--@name - name of assembled module
--@addopts - module's added options*/
function CXXDeclarativeCompiler:assembleModuleStraight (name, addopts)
	--Get module from library.
	local mod = self.mlib:getModule(name)

	--Main prepare operation.
	--In this operation we restore and resolve opts structs.
	--Function returns module array, that ready to compile operation.*/
	local modarray = self:prepareModuleArray(mod, addopts)
	
		if self.clean then 
		for i = 1, #modarray do
			self:cleanDirectory(modarray[i].__opts.builddir)
		end
		return
	end

	--//Check depends of modules.
	self:checkModuleArrayDepends(modarray);
	self:checkModuleArrayOptions(modarray);

	--Compile operation.
	local objects = {}
	for i = 1, #modarray do
		local mod = modarray[i]
		local modobjs = self:__updateModObjects(mod)
		objects = table.arrayConcat(objects, modobjs);
	end
	
	local ret
	--Assemble operation.
	if (objects[1]) then
		ret = self:__assembleObjects(mod, objects);
	end

	--If nothing to do, return false.
	return ret;
end

function CXXDeclarativeCompiler:objectTask (path, deprule, objrule, modmtime, weak, dir)
	assert(dir)
	local sourcefile = self.fileCache:getFile(path);
	local objectfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".o");
	local dependfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".d");

	local task = {
		sourcefile = sourcefile,
		objectfile = objectfile,
		dependfile = dependfile,
		
		objrule = ruleops.substitute(objrule, {
			src = sourcefile.path,
			tgt = objectfile.path
		}),
	
		deprule = ruleops.substitute(deprule, {
			src = sourcefile.path,
			tgt = dependfile.path
		}),

		needRecompile = self:needToRecompile(objectfile, dependfile, modmtime, weak),		
	}

	return task;
end

function CXXDeclarativeCompiler:objectTasks(mod)
	local weak = mod.__opts.weakRecompile  
	local sources = mod:getSources()
	local objects = {}

	if sources.s then
		for i = 1, #sources.s do
			objects[#objects + 1] = self:objectTask(sources.s[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.cc then
		for i = 1, #sources.cc do
			objects[#objects + 1] = self:objectTask(sources.cc[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.cxx then
		for i = 1, #sources.cxx do
			objects[#objects + 1] = self:objectTask(sources.cxx[i], mod.__odRules.cxx_dep_rule, mod.__odRules.cxx_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	if sources.fortran then
		for i = 1, #sources.fortran do
			objects[#objects + 1] = self:objectTask(sources.fortran[i], mod.__odRules.fortran_dep_rule, mod.__odRules.fortran_rule, mod:getMtime(), weak, mod.__opts.builddir)
		end
	end

	return objects;
end

function CXXDeclarativeCompiler:prepareLibTasks(tasks)
	local result = {}
	for key, task in ipairs(tasks) do
		local message
		if self.info == "debug" then
			message = task.objrule .. "\r\n"
		elseif self.info == "silent" then
			message = nil
		else
			message = "OBJECT " .. task.sourcefile.path 
		end

		if task.needRecompile then
			result[#result + 1] = {
				rule = task.objrule,
				message = message,
				next = {
					rule = task.deprule,
					message = nil,
					next = nil
				}
			}
		end
		
	end
	return result
end

function CXXDeclarativeCompiler:assembleModuleParallel (name, addopts)
	--Get module from library.
	local mod = self.mlib:getModule(name)

	--Main prepare operation.
	--In this operation we restore and resolve opts structs.
	--Function returns module array, that ready to compile operation.*/
	local modarray = self:prepareModuleArray(mod, addopts)
	
	if self.clean then 
		for i = 1, #modarray do
			self:cleanDirectory(modarray[i].__opts.builddir)
		end
		return true
	end

	--//Check depends of modules.
	self:checkModuleArrayDepends(modarray);
	self:checkModuleArrayOptions(modarray);

	--Compile operation.
	local tasks = {}
	for i = 1, #modarray do
		local mod = modarray[i]
		local modtasks = self:objectTasks(mod)
		tasks = table.arrayConcat(tasks, modtasks);
	end

	local sources = {}	
	local objects = {}	
	local updated = {}	


	for i = 1, #tasks do
		local file = tasks[i].sourcefile.path
		sources[#sources + 1] = file
		objects[#objects + 1] = tasks[i].objectfile.path
		if tasks[i].needRecompile then
			updated[#updated + 1] = file
			--print("PARALLEL_OBJECT", file)
		end
	end

	--print("Parallel Assemble. files:", #updated)

	local j 
	j = (self.parallel == true) and #tasks or tonumber(self.parallel)
	ctasks = self:prepareLibTasks(tasks)
	glinkLib.parallel_tasks_execute(ctasks, j)
	
	for key, task in ipairs(tasks) do
		self.fileCache:updateFile(task.objectfile.path)
		self.fileCache:updateFile(task.dependfile.path)
	end

	local ret
	if (objects[1]) then
		ret = self:__assembleObjects(mod, objects);
	end

	return ret;
end


function CXXDeclarativeCompiler:assembleModule (name, addopts)
	if self.parallel then
		return self:assembleModuleParallel(name,addopts)
	else
		return self:assembleModuleStraight(name,addopts)
	end
end

return CXXDeclarativeCompiler