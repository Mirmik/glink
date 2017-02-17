local files = find.findInTree("../genos", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

ruller = CXXDeclarativeRuller.new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		LD = "ld", 
	},
	weakRecompile = "noscript",
	optimization = "-O2",
	standart = {
		cxx = "-std=gnu++14",
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

Module("main", {
	sources = {
		cxx = "main.cpp",
	},

	includePaths = ".",
	
	modules = {
		{name = "genos.dprint", impl = "diag"},
		{name = "genos.diag", impl = "impl"},
		{name = "genos.arch.linux32"},
	},

	includeModules = {
		{name = "genos.include"},
		{name = "genos.include.arch.linux32"},
	},
})

local ret = ruller:standartAssemble("main", {
	target = "genos",
	targetdir = ".",
	assembletype = "application"
})

if not ret then print(text.yellow("Nothing to do")) end 