local _local_file = debug.getinfo(1).short_src
local _n, _n, _local_directory = string.find(debug.getinfo(1).short_src, "^(.+/)[^/]+$")
__directory = _local_directory

--unstandart extension
dofile(__directory .. "/lib/copy.lua")

GlinkGlobal = dofile(__directory .. "/classes/GlinkGlobal.lua")
ScriptMachine = dofile(__directory .. "/classes/ScriptMachine.lua")
ModuleLibrary = dofile(__directory .. "/classes/ModuleLibrary.lua")

local script = ScriptMachine:new()
local mlib = ModuleLibrary:new(script)

GlinkGlobal.globalModuleLibrary = mlib

script:evalFile("./glink.lua", {
	ARGV = arg,
	print = print,
	error = error,
	table = table,
	os = os,
	script = script,

	ScriptMachine = ScriptMachine,
	File = dofile(__directory .. "/classes/File.lua"),
	CXXModuleCompiler = dofile(__directory .. "/classes/CXXModuleCompiler.lua"),
	
	pathops = dofile(__directory .. "/lib/pathops.lua"),
	ruleops = dofile(__directory .. "/lib/ruleops.lua"),
	text = dofile(__directory .. "/lib/text.lua"),
	find = dofile(__directory .. "/lib/find.lua"),

	GlinkGlobal = GlinkGlobal,
	Module = GlinkGlobal.Module,
	Implementation = GlinkGlobal.Implementation,
	globalModuleLibrary = GlinkGlobal.globalModuleLibrary,
})