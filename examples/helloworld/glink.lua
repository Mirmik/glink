compiler = CXXModuleCompiler:new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		AR = "ar", 
		LD = "ld", 
		OBJDUMP = "objdump" 
	},
	opts = {
		--weakRecompile = "noscript",
		optimization = "-O2",
		standart = {
			cxx = "-std=gnu++11",
			cc = "-std=gnu11",
		},
		options = {
			all = "-Wl,--gc-sections -fdata-sections -ffunction-sections",
			cc = "",
			cxx = "",
			ld = "",
		}
	},
	builddir = "./build",
}

compiler:standartArgsRoutine(OPTS)

Module("main", {
	sources = {
		directory = nil,
		cxx = "",
		cc = "main.c",
		s = "",
	},

	opts = {
		includePaths = ".",
	},

	modules = {
	},

	includeModules = {
	},
})

compiler:updateBuildDirectory()

local ret = compiler:assembleModule("main", {
	target = "helloworld"
})

if not ret then print(text.yellow("Nothing to do")) end