local CXXDeclarativeRuller = {}
CXXDeclarativeRuller.__index = CXXDeclarativeRuller

optops = require("glink.lib.optops")
ruleops = require("glink.lib.ruleops")
needops = require("glink.lib.needops")
TaskTree = require("glink.classes.TaskTree")
StraightExecutor = require("glink.classes.StraightExecutor")

function CXXDeclarativeRuller.new(args) 
	local ruller = {}
	setmetatable(ruller, CXXDeclarativeRuller)

	--построение таблицы опций для optops
	ruller.optionsTable = {
		__name__ = {otype = "string"},
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
		
		includePaths = {otype = "array", default = {}, paths = true},
		ldscripts = {otype = "array", paths = true, default = {}},
		defines = {otype = "array", default = {}},
		depends = { merge = optops.f_changeMerge, otype = "array", include = optops.f_concatMerge, add = optops.f_concatMerge},
		libs = {otype = "array", default = {}},
		modules = {otype = "array"},
		includeModules = {otype = "array"},
		
		optimization = {otype = "string"},
		builddir = {otype = "string"},
		weakRecompile = {otype = "string"},
		
		targetdir = {otype = "string", merge = optops.f_changeMerge, include = optops.f_noMerge},
		target = {otype = "string", merge = optops.f_changeMerge, include = optops.f_noMerge},
		assembletype = {otype = "string", default = "objects", merge = optops.f_changeMerge, include = optops.f_noMerge},
	
		standart = {otype = "table", table = {
			cc = {otype = "string"},
			cxx = {otype = "string"},			
		}},
	
		flags = {otype = "table", table = {
			cc = {otype = "array", default = {}},
			cxx = {otype = "array", default = {}},
			ld = {otype = "array", default = {}},
			allcc = {otype = "array", default = {}}		
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
	ruller.fileCache = GlinkGlobal.globalFileCache;

--	ruller:useOPTS(_ENV.OPTS)

	return ruller	
end

function CXXDeclarativeRuller:useOPTS(OPTS)  	
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
			self.clean = true;
		elseif OPTS[1] == "rebuild" then
			self.forceRebuild = true 
		else
			error(text.red("Unresolved Parametr ") .. text.yellow(OPTS[1]))
		end
	end
end

--Create build directory if needed
function CXXDeclarativeRuller:updateDirectoryTask(taskTree, dir)
	local mkdirrule = "mkdir -p "..dir

	if self.info == "debug" then
		message = mkdirrule .. "\r\n"
	elseif self.info == "silent" then
		message = nil
	else
		message = "MKDIR " .. dir 
	end

	if taskTree:contains(dir) then return end
	taskTree:addTask(dir, {
		{rule = mkdirrule, echo = false, message = message, noneed = not needops.needToUpdateDirectory(dir)},
	})
end

function CXXDeclarativeRuller:objectTask (taskTree, srcpath, deprule, objrule, modmtime, weak, builddir)
	assert(builddir)
	local objpath = builddir .. "/" .. util.base64_encode(srcpath) .. ".o"
	local deppath = builddir .. "/" .. util.base64_encode(srcpath) .. ".d"

	local task = nil
	local objrule = ruleops.substitute(objrule, { src = srcpath, tgt = objpath })
	local deprule = ruleops.substitute(deprule, { src = srcpath, tgt = deppath })

	local message
	local depmessage

	if self.info == "debug" then
		message = objrule .. "\r\n"
	elseif self.info == "silent" then
		message = nil
	else
		message = "OBJECT " .. srcpath 
	end

	depmessage = nil

	local need = self.forceRebuild or needops.needToRecompile(objpath, deppath, modmtime, weak)

	taskTree:addTask(objpath, {
		{rule = objrule, echo = false, message = message, noneed = not need},
		{rule = deprule, echo = false, message = depmessage, noneed = not need},
	})

	taskTree:addNext(builddir, objpath)

	return objpath, need;
end

function CXXDeclarativeRuller:objectTasks(taskTree, mod)
	local weak = mod.__opts.weakRecompile  
	local sources = mod:getSources()
	local objects = {}
	local object
	local __need
	local need = false
 
	local function f(arr, deprule, ccrule) 
		if arr then
			for i = 1, #arr do
				object, __need = self:objectTask(taskTree, arr[i], deprule, ccrule, mod:getMtime(), weak, mod.__opts.builddir)
				objects[#objects + 1] = object
				need = need or __need
			end
		end
	end

	f(sources.s, mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule)
	f(sources.cc, mod.__odRules.cc_dep_rule, mod.__odRules.cc_rule)
	f(sources.cxx, mod.__odRules.cxx_dep_rule, mod.__odRules.cxx_rule)
	f(sources.fortran, mod.__odRules.fortran_dep_rule, mod.__odRules.fortran_rule)

	return objects, need;
end


function CXXDeclarativeRuller:linkTask(taskTree, mod, parts, need)
	local target = mod.__opts.target and mod.__opts.target or mod.name
	local targetdir = mod.__opts.targetdir and mod.__opts.targetdir or mod.__opts.builddir
	local message
	target = pathops.resolve(targetdir, target)
	
	local ld_rule = mod.__odRules.ld_rule
	ld_rule = ruleops.substitute(ld_rule, { objs = table.concat(parts, " "), tgt = target })
	
	if #parts == 0 then return {} end

	if self.info == "debug" then 
		message = "LINK " .. ld_rule .. "\r\n"
	elseif self.info == "silent" then
	else
		message = "LINK " .. target
	end

	taskTree:addTask(target, {
		{
			rule = ld_rule,
			echo = false, message = message, noneed = not (need or needops.needToUpdateFile(target))
		}
	})

	taskTree:multiBasesNext(parts, target)
	taskTree:addNext(targetdir, target)
			
	return {target} 
end

function CXXDeclarativeRuller:buildDirectoryDeleteTask(taskTree, mod)
	local builddir = mod.__opts.builddir
	local message
	
	local rmrule = "rm -f "..builddir.."/*.o "..builddir.."/*.d "
	
	if self.info == "debug" then 
		message = "CLEAN " .. rmrule .. "\r\n"
	elseif self.info == "silent" then
	else
		message = "CLEAN " .. builddir
	end

	if not taskTree:contains(builddir) then
		taskTree:addTask(builddir, {
			{rule = rmrule, echo = false, message = message}
		})
	end
			
	return builddir 
end

--RULES OPERATIONS
function CXXDeclarativeRuller:resolveODRule(protorules, opts) 
	assert(protorules);

	local tempoptions = ruleops.substitute(protorules.__options__, {
		OPTIMIZATION = opts.optimization,
		DEFINES = table.concat(	
			util.map(opts.defines, function(file) return "-D" .. file end), 
			" "
		),
		INCLUDE = table.concat(
			util.map(opts.includePaths, function(file) return "-I" .. file end), 
			" "
		),
	})

	local cc_options = ruleops.substitute(tempoptions, {
		STANDART = opts.standart.cc,
		OPTIONS = table.concat(table.arrayConcat(opts.flags.cc, opts.flags.allcc)," "),
	})

	local cxx_options = ruleops.substitute(tempoptions, {
		STANDART = opts.standart.cxx,
		OPTIONS = table.concat(table.arrayConcat(opts.flags.cxx, opts.flags.allcc)," "),
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
		OPTIONS = table.concat(table.arrayConcat(opts.flags.ld, opts.flags.allcc)," "),
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

function CXXDeclarativeRuller:prepareModuleTree(rootmod, addopts) 
	optops.prepare(addopts, self.optionsTable)

	local function f(mod, addopts, rootopts)
		--get module from library.
		local _opts = table.deep_copy(rootopts)

		--resolve module opts
		optops.prepare(mod.mod, self.optionsTable)
		optops.merge(mod.mod, addopts, self.optionsTable, "add")
		optops.restorePaths(mod.mod, self.optionsTable, mod.moduleDirectory)
		self:resolveIncludeModules(mod)
		optops.merge(_opts, mod.mod, self.optionsTable)

		mod.__opts = _opts
		mod.__odRules = self:resolveODRule(self.rules, mod.__opts) 
	
		--/*We need submodule's field for tree organization*/
		mod.__submods = {}
		
		local modules = mod:getModules()
		if (not modules) then return end

		--If mod have submodules, foreach
		for i = 1, #modules do
			local subrec = modules[i]
			--get submodule from library
			local sub = self.mlib:resolveSubmod(subrec);
			subrec.opts = subrec.opts and subrec.opts or {}
			optops.prepare(subrec.opts, self.optionsTable)
		
			--use Worker on it.
			f(sub, subrec.opts, mod.__opts)

			--save link in submods table
			mod.__submods[i] = sub
		end
	end

	f(rootmod, addopts, self.opts) 
end

function CXXDeclarativeRuller:makeCleanTaskTree(taskTree, mod) 
	local function f(mod)
		local directories = {}
	
		--Submodules should be resolved early
		for index, sub in ipairs(mod.__submods) do
			__directories = f(sub)
			directories = table.arrayConcat(directories, __directories)
		end

		return self:buildDirectoryDeleteTask(taskTree, mod)
	end
	
	return f(mod)
end


function CXXDeclarativeRuller:makeAssembleTaskTree(taskTree, mod) 
	local function f(mod)
		local objects, needobj, __needres, __results, need		
		
		if not mod.__opts.builddir then error(text.red("builddir should be declared")) end
		self:updateDirectoryTask(taskTree, mod.__opts.builddir)
		
		--Submodules should be resolved early
		local results = {}
		local needres = false
		for index, sub in ipairs(mod.__submods) do
			__results, __needres = f(sub)

			results = table.arrayConcat(results, __results)
			needres = __needres or needres
		end

		objects, needobj = self:objectTasks(taskTree, mod)
		need = needobj or needres		
		
		if mod.__opts.assembletype == "objects" then 
			return table.arrayConcat(objects, results), need
		
		elseif mod.__opts.assembletype == "application" then 
			local parts = table.arrayConcat(objects, results)
			if not mod.__opts.targetdir then error(text.red("targetdir should be declared")) end
			self:updateDirectoryTask(taskTree, mod.__opts.targetdir)
			return self:linkTask(taskTree, mod, parts, need), need

		elseif mod.__opts.assembletype == "static" then error("STA")
		
		elseif mod.__opts.assembletype == "dinamic" then error("STA")
		
		end
	end
	
	results = f(mod) 
	return taskTree, results
end

function CXXDeclarativeRuller:makeTaskTree(name, addops) 
	local mod = self.mlib:getModule(name)
	self:prepareModuleTree(mod, addops)

	local taskTree = TaskTree.new()

	if self.clean == true then
		self:makeCleanTaskTree(taskTree, mod)
	else
		self:makeAssembleTaskTree(taskTree, mod)
	end

	return taskTree
end

function CXXDeclarativeRuller:standartAssemble( name, addopts )
	self:useOPTS(_ENV.OPTS)
	local executor = StraightExecutor.new()
	executor:useOPTS(_ENV.OPTS)
	return executor:execute(self:makeTaskTree(name, addopts))
end

return CXXDeclarativeRuller