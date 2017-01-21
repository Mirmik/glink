local files = find.findInTree("../genos", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

ruller = CXXDeclarativeRuller.new{
	buildutils = { 
		CXX = "arm-none-eabi-g++", 
		CC = "arm-none-eabi-gcc", 
		LD = "arm-none-eabi-ld", 
	},
	weakRecompile = "noscript",
	optimization = "-O2",
	standart = {
		cxx = "-std=gnu++11",
		cc = "-std=gnu11",
	},
	flags = {
		allcc = "-nostdinc -mthumb -mcpu=cortex-m4 -Wl,--gc-sections -fdata-sections -ffunction-sections",
		cc = "",
		cxx = "-fno-rtti",
		ld = "-nostdlib -lgcc",
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
		{name = "genos.irqtbl"},
		{name = "genos.libc", opts = {weakRecompile = "noscript",}},
		{name = "genos.arch.stm32"},
	},

	includeModules = {
		{name = "genos.include"},
		{name = "genos.include.libc",},
		{name = "genos.include.arch.stm32f407"},
	},
})

local ret = ruller:standartAssemble("main", {
	target = "genos",
	targetdir = ".",
	assembletype = "application"
})

if not ret then print(text.yellow("Nothing to do")) end 