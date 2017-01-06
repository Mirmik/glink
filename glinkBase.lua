local _local_file = debug.getinfo(1).short_src
local _n, _n, _current_directory = string.find(debug.getinfo(1).short_src, "^(.+/)[^/]+$")
__directory = _current_directory

--unstandart extension
dofile(__directory .. "/lib/copy.lua")
dofile(__directory .. "/lib/getopt.lua")

OPTS = getopt( arg, "j" )
--print(table.tostring(OPTS))

GlinkGlobal = dofile(__directory .. "/classes/GlinkGlobal.lua")
ScriptMachine = dofile(__directory .. "/classes/ScriptMachine.lua")
ModuleLibrary = dofile(__directory .. "/classes/ModuleLibrary.lua")

ModuleClass= dofile(__directory .. "/classes/ModuleClass.lua")
ImplementationClass = dofile(__directory .. "/classes/ImplementationClass.lua")
VariantModuleClass = dofile(__directory .. "/classes/VariantModuleClass.lua")

File = dofile(__directory .. "/classes/File.lua");
FileCache = dofile(__directory .. "/classes/FileCache.lua");

CXXDeclarativeCompiler = dofile(__directory .. "/classes/CXXDeclarativeCompiler.lua");
	
local script = ScriptMachine:new()
local mlib = ModuleLibrary:new(script)

GlinkGlobal.globalModuleLibrary = mlib

script:evalFile("./glink.lua", {
	OPTS = OPTS,
	print = print,
	error = error,
	table = table,
	os = os,
	script = script,

	ScriptMachine = ScriptMachine,
	CXXDeclarativeCompiler = CXXDeclarativeCompiler,
	ModuleLibrary = ModuleLibrary,

	pathops = dofile(__directory .. "/lib/pathops.lua"),
	ruleops = dofile(__directory .. "/lib/ruleops.lua"),
	text = dofile(__directory .. "/lib/text.lua"),
	find = dofile(__directory .. "/lib/find.lua"),

	Module = GlinkGlobal.Module,
	Implementation = GlinkGlobal.Implementation,
	globalModuleLibrary = GlinkGlobal.globalModuleLibrary,
})