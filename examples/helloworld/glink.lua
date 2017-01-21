ruller = CXXDeclarativeRuller.new{
	buildutils = { 
		CXX = "g++", 
		CC = "gcc", 
		LD = "ld", 
	},
	builddir = "./build",
}
ruller:useOPTS(_ENV.OPTS)

Module("main", {
	sources = {
		cc = "main.c",
	},
})

local ret = ruller:assemble("main", {
	target = "helloworld",
	targetdir = "./",
	assembletype = "application"
})

if not ret then print(text.yellow("Nothing to do")) end