ruller = CXXDeclarativeRuller.new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		LD = "ld", 
	},
	--weakRecompile = "noscript",
	optimization = "-O2",
	standart = {
		cxx = "-std=gnu++11",
		cc = "-std=gnu11",
	},

	flags = {
		allcc = "-Wl,--gc-sections -fdata-sections -ffunction-sections",
		cc = "",
		cxx = "",
		ld = "",
	},
	
	builddir = "./build",
}

ruller:useOPTS(_ENV.OPTS)

Module("main", {
	sources = {
		cxx = "",
		cc = "main.c",
		s = "",
	},

	includePaths = ".",
	
	modules = {
	},

	includeModules = {
	},
})

local tree = ruller:makeTaskTree("main", {
	target = "helloworld",	
})

local executor = StraightExecutor.new()
executor:useOPTS(_ENV.OPTS)
executor:execute(tree)

if not ret then print(text.yellow("Nothing to do")) end