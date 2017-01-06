local files = find.findInTree("../genos", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

compiler = CXXDeclarativeCompiler:new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		AR = "ar", 
		LD = "ld", 
		OBJDUMP = "objdump" 
	},
	opts = {
		weakRecompile = "noscript",
		optimization = "-O2",
		standart = {
			cxx = "-std=gnu++11",
			cc = "-std=gnu11",
		},
		options = {
			all = "-Wl,--gc-sections -fdata-sections -ffunction-sections",
			cc = "",
			cxx = "-fno-rtti",
			ld = "",
		}
	},
	builddir = "./build",
}
--compiler.debugInfo = true;

if (ARGV[1]) then
	if ARGV[1] == "clean" then
		compiler:cleanBuildDirectory()
	else
		error(text.red("Unresolved Parametr"))
	end
	os.exit(0)
end

Module("main", {
	sources = {
		directory = "src",
		cxx = "main.cpp",
	},

	opts = {
		includePaths = ".",
	},

	modules = {
		{name = "genos.dprint", impl = "diag"},
		{name = "genos.diag", impl = "impl"},
		{name = "genos.arch.linux"},
	},

	includeModules = {
		{name = "genos.include"},
		{name = "genos.include.arch.linux32"},
	},
})

compiler:updateBuildDirectory()

local ret = compiler:assembleModule("main", {
	target = "genos"
})

if not ret then print(text.yellow("Nothing to do")) end