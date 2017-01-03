local files = find.findInTree("../genos", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

compiler = CXXModuleCompiler:new{
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
--compiler.debugInfo = true;
compiler.parallel = true;

if (ARGV[1]) then
	if ARGV[1] == "clean" then
		compiler:cleanBuildDirectory()
		os.exit(0)
	elseif ARGV[1] == "rebuild" then
		compiler.rebuild = true 
	else
		error(text.red("Unresolved Parametr"))
	end
end

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