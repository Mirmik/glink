local files = find.findInTree("src", ".*.gll$", ".*HIDE.*")
script:evalFile(files, _ENV)

compiler = CXXModuleCompiler:new{
	buildutils = {
		CXX = "g++",
		CC = "gcc",
		AR = "ar",
		LD = "ld",
		OBJDUMP = "objdump",
	},

	opts = {
		--weakRecompile = "noscript",
		optimization = "-O2",

		standart = {
			cxx = "-std=c++11",
			cc = "-std=c11",
		},
	
		defines = {},
		includePaths = {"include"},
		libs = {},
		options = {
			all = "-fdata-sections -ffunction-sections -Wl,--gc-sections", 
			cc = "HereYouAre",
		}
		--ld_options = ["-fdata-sections", "-ffunction-sections", "-Wl,--gc-sections"],
	},

	builddir = "./build",
}
--compiler.debugInfo = true;

Module("main", {
	directory = "src",
	sources = {
		cxx = "main.cpp ttt.cpp"
	}
})

Implementation("main2", "impl", {
	directory = "src",
	sources = {
		cxx = "main.cpp ttt.cpp"
	}
})

if (ARGV[1]) then
	if ARGV[1] == "clean" then
		compiler:cleanBuildDirectory()
	else
		error(text.red("Unresolved Parametr"))
	end
	os.exit(0)
end

compiler:updateBuildDirectory()

local ret = compiler:assembleModule("main", {
	target = "genos"
})

if not ret then print(text.yellow("Nothing to do")) end
 