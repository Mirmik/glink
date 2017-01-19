local CXXDeclarativeRuller = {}
CXXDeclarativeRuller.__index = CXXDeclarativeRuller

optops = require("glink.lib.optops")
ruleops = require("glink.lib.ruleops")
TaskTree = require("glink.classes.TaskTree")

function CXXDeclarativeRuller.new(args) 
	local ruller = {}
	setmetatable(ruller, CXXDeclarativeRuller)

	--построение таблицы опций для optops
	ruller.optionsTable = {
		buildutils = {otype = "table", table = {
			CC = { otype = "string", merge = optops.f_nilMerge },
			CXX = { otype = "string", merge = optops.f_nilMerge },
			LD = { otype = "string", merge = optops.f_nilMerge }		
		}},
	
		sources = {otype = "table", table = {
			cc = { merge = optops.f_changeMerge, otype = "array", include = optops.f_concatMerge, add = optops.f_concatMerge, paths = true},
			cxx = { merge = optops.f_changeMerge, otype = "array", include = optops.f_concatMerge, add = optops.f_concatMerge, paths = true},
			s = { merge = optops.f_changeMerge, otype = "array", include = optops.f_concatMerge, add = optops.f_concatMerge, paths = true}		
		}},
		
		includePaths = {otype = "array", paths = true},
		ldscripts = {otype = "array", paths = true, default = {}},
		defines = {otype = "array", default = {}},
		libs = {otype = "array", default = {}},
		modules = {otype = "array"},
		includeModules = {otype = "array"},
		
		optimization = {otype = "string"},
		builddir = {otype = "string"},
		
		targetdir = {otype = "string", merge = optops.f_changeMerge, include = optops.f_noMerge},
		target = {otype = "string", merge = optops.f_changeMerge, include = optops.f_noMerge},
		assembletype = {otype = "string", default = "objects", merge = optops.f_changeMerge, include = optops.f_noMerge},
	
		standart = {otype = "table", table = {
			cc = {otype = "string"},
			cxx = {otype = "string"},			
		}},
	
		flags = {otype = "table", table = {
			cc = {otype = "array"},
			cxx = {otype = "array"},
			ld = {otype = "array"},
			allcc = {otype = "array"}		
		}}
	}

	--автоматическое дополнение таблицы
	optops.prepareMetaTable(ruller.optionsTable)

	ruller.opts = table.deep_copy(args)
	optops.prepare(ruller.opts, ruller.optionsTable)

	--Compiler rules prototypes.
	ruller.rules = ruleops.substitute({
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
	}, ruller.opts.buildutils);

	--We use global context as default.
	ruller.mlib = GlinkGlobal.globalModuleLibrary;
	--//We use FileCache as file operations manager.
	ruller.fileCache = FileCache:new()

	return ruller	
end


function CXXDeclarativeRuller:standartArgsRoutine(OPTS)  	
	--if (OPTS.j) then
	--	self.parallel = OPTS.j
	--end
	
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

function CXXDeclarativeRuller:needToRecompile(objfile, depfile, modmtime, weak)
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

function CXXDeclarativeRuller:objectTask (tasktree, path, deprule, objrule, modmtime, weak, dir)
	assert(dir)
	local sourcefile = self.fileCache:getFile(path);
	local objectfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".o");
	local dependfile = self.fileCache:getFile(dir .. "/" .. util.base64_encode(path) .. ".d");

	local task = nil
	local objrule = ruleops.substitute(objrule, { src = sourcefile.path, tgt = objectfile.path })
	local deprule = ruleops.substitute(deprule, { src = sourcefile.path, tgt = dependfile.path })

	if self.info == "debug" then
		message = objrule .. "\r\n"
	elseif self.info == "silent" then
		message = nil
	else
		message = "OBJECT " .. sourcefile.path 
	end

	local need = self:needToRecompile(objectfile, dependfile, modmtime, weak)
	if need then 
		tasktree:addTask(objectfile.path, {
			{rule = objrule, echo = false, message = message},
			{rule = deprule, echo = false},
		})
	end
	
	return objectfile.path, need;
end

function CXXDeclarativeRuller:objectTasks(mod, tasktree)
	local weak = mod.__opts.weakRecompile  
	local sources = mod:getSources()
	local tasks = {}
	local objects = {}
	local cobjects = {}
	local compiled
	local task
	local object

	if sources.s then
		for i = 1, #sources.s do
			object, compiled = self:objectTask(tasktree, sources.s[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
			if compiled then cobjects[#cobjects + 1] = object end
			objects[#objects + 1] = object
		end
	end

	if sources.cc then
		for i = 1, #sources.cc do
			object, compiled = self:objectTask(tasktree, sources.cc[i], mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule, mod:getMtime(), weak, mod.__opts.builddir)
			if compiled then cobjects[#cobjects + 1] = object end
			objects[#objects + 1] = object
		end
	end

	if sources.cxx then
		for i = 1, #sources.cxx do
			object, compiled = self:objectTask(tasktree, sources.cxx[i], mod.__odRules.cxx_dep_rule, mod.__odRules.cxx_rule, mod:getMtime(), weak, mod.__opts.builddir)
			if compiled then cobjects[#cobjects + 1] = object end
			objects[#objects + 1] = object
		end
	end

	if sources.fortran then
		for i = 1, #sources.fortran do
			object, compiled = self:objectTask(tasktree, sources.fortran[i], mod.__odRules.fortran_dep_rule, mod.__odRules.fortran_rule, mod:getMtime(), weak, mod.__opts.builddir)
			if compiled then cobjects[#cobjects + 1] = object end
			objects[#objects + 1] = object
		end
	end

	return objects, cobjects;
end

--RULES OPERATIONS
function CXXDeclarativeRuller:resolveODRule(protorules, opts) 
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
		OPTIONS = table.concat(opts.flags.cc," "),
	})

	local cxx_options = ruleops.substitute(tempoptions, {
		STANDART = opts.standart.cxx,
		OPTIONS = table.concat(opts.flags.cxx," "),
	})

	local fortran_options = ruleops.substitute(protorules.__fortran_options__, {
		INCLUDE = table.concat(
			util.map(opts.includePaths, function(file) return "-I" .. file end), 
			" "
		),
	})

	local ld_options = ruleops.substitute(protorules.__link_options__, {
		OPTIMIZATION = opts.optimization,
		LIBS = table.concat(util.map(opts.libs, function(file) return "-l" .. file end), 
			" "),
		LDSCRIPTS = table.concat(
			util.map(opts.ldscripts, function(file) return "-T" .. file end), 
			" "
		),
		OPTIONS = table.concat(opts.flags.ld," "),
		SHARED = opts.sharedLibrary and "-shared" or ""
	})
	
	local ret = {};
	ret.cc_rule = ruleops.substitute(protorules.cc_rule, {__options__= cc_options});
	ret.cc_dep_rule = ruleops.substitute(protorules.cc_dep_rule, {__options__= cc_options});
	ret.cxx_rule = ruleops.substitute(protorules.cxx_rule, {__options__= cxx_options});
	ret.cxx_dep_rule = ruleops.substitute(protorules.cxx_dep_rule, {__options__= cxx_options});
	ret.fortran_rule = ruleops.substitute(protorules.fortran_rule, {__fortran_options__= fortran_options});
	ret.fortran_dep_rule = ruleops.substitute(protorules.fortran_dep_rule, {__fortran_options__= fortran_options});
	ret.ld_rule = ruleops.substitute(protorules.ld_rule, {__options__= ld_options});
	
	return ret;
end

function CXXDeclarativeRuller:resolveIncludeModules(mod)
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
		optops.prepare(inc.mod, self.optionsTable)
		optops.restorePaths(inc.mod, self.optionsTable, inc.moduleDirectory)
		
		--If inc have own includeModules, resolve these.
		self:resolveIncludeModules(inc);

		--Merge included module to mod and change mtime, if needed. 
		optops.merge(mod.mod, inc.mod, self.optionsTable,"include");
		if mod:getMtime() < inc:getMtime() then mod:setMtime(inc:getMtime()) end
	end

	mod.mod.includeModules = nil;
end

--Create build directory if needed
function CXXDeclarativeRuller:updateDirectory(dir) 
	recursiveMkdir(dir);
end

function CXXDeclarativeRuller:evaluateTasks(name, addopts) 
	local tasktree = TaskTree.new()

	optops.prepare(addopts, self.optionsTable)
	function f(mod, addopts, rootopts)
		--get module from library.
		local _opts = table.deep_copy(rootopts)

		--resolve module opts
		optops.prepare(mod.mod, self.optionsTable)
		--print(table.tostring(mod.mod))
		optops.merge(mod.mod, addopts, self.optionsTable, "add")
		--print(table.tostring(addopts))
		--print(table.tostring(mod.mod))
		optops.restorePaths(mod.mod, self.optionsTable, mod.moduleDirectory)
		self:resolveIncludeModules(mod)
		optops.merge(_opts, mod.mod, self.optionsTable)

		mod.__opts = _opts
		mod.__odRules = self:resolveODRule(self.rules, mod.__opts) 
	
		assert(mod.__opts.builddir)
		self:updateDirectory(mod.__opts.builddir)

		--/*We need submodule's field for tree organization*/
		mod.__submods = {}
		if (not mod:getModules()) then return end

		--If mod have submodules, foreach
		local modules = mod:getModules()

		local results = {}
		local compiled = {}
		
		for i = 1, #modules do
			local subrec = modules[i]
			--get submodule from library
			local sub = self.mlib:resolveSubmod(subrec);
			--add to submodules field.
			mod.__submods[i] = sub
			subrec.opts = subrec.opts and subrec.opts or {}
			optops.prepare(subrec.opts, self.optionsTable)
			--use Worker on it.
			__results, __compiled = f(sub, subrec.opts, mod.__opts)
			results = table.arrayConcat(results, __results)
			compiled = table.arrayConcat(compiled, __compiled)
		end

		local objects
		local cobjects
		objects, cobjects = self:objectTasks(mod, tasktree)
		
		if mod.__opts.assembletype == "objects" then 
			return table.arrayConcat(objects, results), table.arrayConcat(cobjects, compiled) 
		
		elseif mod.__opts.assembletype == "application" then 
			local parts = table.arrayConcat(objects, results)
			local cparts = table.arrayConcat(cobjects, compiled)
			return self:linkTask(tasktree, mod, parts, cparts)

		elseif mod.__opts.assembletype == "static" then error("STA")
		
		elseif mod.__opts.assembletype == "dinamic" then error("STA")
		
		end
	end
	local mod = self.mlib:getModule(name)
	results = f(mod, addopts, self.opts) 
	return tasktree, results
end

function CXXDeclarativeRuller:linkTask(tasktree, mod, parts, cparts)
	local target = mod.__opts.target and mod.__opts.target or mod.name
	local targetdir = mod.__opts.targetdir and mod.__opts.targetdir or mod.__opts.builddir
	local message
	target = pathops.resolve(targetdir, target)
	local ld_rule = mod.__odRules.ld_rule
	
	if #cparts == 0 then return {} end

	if self.info == "debug" then 
		message = "LINK " .. ld_rule .. "\r\n"
	elseif self.info == "silent" then
	else
		message = "LINK " .. target
	end

	tasktree:addTask(target, {
		{rule = ruleops.substitute(ld_rule, { objs = table.concat(parts, " "), tgt = target }),echo = false, message = message}
	})
			
	for index, part in ipairs(cparts) do tasktree:addNext(part, target) end
	return {target} 
end

return CXXDeclarativeRuller