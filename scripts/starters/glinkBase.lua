local _local_file = debug.getinfo(1).short_src
local _n, _n, _current_directory = string.find(debug.getinfo(1).short_src, "^(.+/)[^/]+$")
__directory = _current_directory

--unstandart extension
--require("/lib/copy")
--require("/lib/getopt")
require("glink.lib.copy")
require("glink.lib.getopt")

OPTS = getopt( arg, "j" )
--print(table.tostring(OPTS))

GlinkGlobal = require("glink.classes.GlinkGlobal")
ScriptMachine = require("glink.classes.ScriptMachine")
ModuleLibrary = require("glink.classes.ModuleLibrary")

ModuleClass= require("glink.classes.ModuleClass")
ImplementationClass = require("glink.classes.ImplementationClass")
VariantModuleClass = require("glink.classes.VariantModuleClass")

File = require("glink.classes.File");
FileCache = require("glink.classes.FileCache");

CXXDeclarativeCompiler = require("glink.classes.CXXDeclarativeCompiler");
	
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

	pathops = require("glink.lib.pathops"),
	ruleops = require("glink.lib.ruleops"),
	text = require("glink.lib.text"),
	find = require("glink.lib.find"),

	Module = GlinkGlobal.Module,
	Implementation = GlinkGlobal.Implementation,
	globalModuleLibrary = GlinkGlobal.globalModuleLibrary,
})