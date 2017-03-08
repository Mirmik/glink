local _local_file = debug.getinfo(1).short_src
local _n, _n, _current_directory = string.find(debug.getinfo(1).short_src, "^(.+/)[^/]+$")
__directory = _current_directory

--unstandart extension
--require("/lib/copy")
--require("/lib/getopt")
require("glink.lib.copy")
require("glink.lib.getargs")

OPTS = getargs( arg, "j" )
--print(table.tostring(OPTS))

GlinkGlobal = require("glink.classes.GlinkGlobal")
FaultError = GlinkGlobal.FaultError
FaultErrorInOptions = GlinkGlobal.FaultErrorInOptions
FaultErrorDeep = GlinkGlobal.FaultErrorDeep

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
GlinkGlobal.globalFileCache = FileCache.new()

script:evalFile("./glink.lua", {
	OPTS = OPTS,
	print = print,
	error = error,
	require = require,
	table = table,
	os = os,
	script = script,

	ScriptMachine = ScriptMachine,
	CXXDeclarativeCompiler = CXXDeclarativeCompiler,
	CXXDeclarativeRuller = require("glink.classes.CXXDeclarativeRuller"),
	ModuleLibrary = ModuleLibrary,
	
	TaskTree = require("glink.classes.TaskTree"),
	TaskStruct = require("glink.classes.TaskStruct"),
	StraightExecutor = require("glink.classes.StraightExecutor"),

	pathops = require("glink.lib.pathops"),
	ruleops = require("glink.lib.ruleops"),
	text = require("glink.lib.text"),
	find = require("glink.lib.find"),
	needops = require("glink.lib.needops"),

	Module = GlinkGlobal.Module,
	Implementation = GlinkGlobal.Implementation,
	globalModuleLibrary = GlinkGlobal.globalModuleLibrary,
})