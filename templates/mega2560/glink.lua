print(text.green("Script Start"))

ruller = CXXDeclarativeRuller.new{
	buildutils = { 
		CXX = "avr-g++", 
		CC = "avr-gcc", 
		LD = "avr-ld", 
	},
	--weakRecompile = "noscript",
	optimization = "-O2",
	
	standart = {
		cxx = "-std=gnu++11",
		cc = "-std=gnu11",
	},
	
	flags = {
		cc = "",
		cxx = "-fno-rtti",
		ld = "-nostdinc -nostartfiles",
		allcc = "-mmcu=atmega2560 -DF_CPU=16000000 -Wl,--gc-sections -fdata-sections -ffunction-sections"
	},
	
	builddir = "./build"
}

Module("main", {
	sources = {
		cxx = "main.cpp",
	},

	includePaths = ".",
	
	modules = {
	},

	includeModules = {
	},
})

local ret = ruller:standartAssemble("main", {
	target = "genos",
	targetdir = ".",
	assembletype = "application"
})

if not (ret) then print(text.yellow("Nothing to do")) end