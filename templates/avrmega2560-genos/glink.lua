local files = find.findInTree("../genos", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

compiler = CXXDeclarativeCompiler:new{
	buildutils = { 
		CXX = "arm-none-eabi-g++", 
		CC = "arm-none-eabi-gcc", 
		AR = "arm-none-eabi-ar", 
		LD = "arm-none-eabi-ld", 
		OBJDUMP = "arm-none-eabi-objdump" 
	},
	opts = {
		--weakRecompile = "noscript",
		optimization = "-O2",
		standart = {
			cxx = "-std=gnu++11",
			cc = "-std=gnu11",
		},
		options = {
			all = "-nostdinc -mthumb -mcpu=cortex-m4 -Wl,--gc-sections -fdata-sections -ffunction-sections",
			cc = "",
			cxx = "-fno-rtti",
			ld = "-nostdlib -lgcc",
		}
	},
	builddir = "./build",
}

compiler:standartArgsRoutine(OPTS)

Module("main", {
	sources = {
		directory = "src",
		cxx = "main.cpp test.cpp",
	},

	opts = {
		includePaths = ".",
	},

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

compiler:updateBuildDirectory()

local ret = compiler:assembleModule("main", {
	target = "genos"
})

if not ret then print(text.yellow("Nothing to do")) end