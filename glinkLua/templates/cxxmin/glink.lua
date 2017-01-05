compiler = CXXDeclarativeCompiler:new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		AR = "ar", 
		LD = "ld", 
		OBJDUMP = "objdump" 
	},
	builddir = "./build",
}

Module("main", {
	sources = {
		cxx = "main.cpp",
	},
})


compiler:updateBuildDirectory()
ret = compiler:assembleModule("main", {})