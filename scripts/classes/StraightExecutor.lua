local StraightExecutor = {}

local TaskTree = require("glink.classes.TaskTree")
local TaskStruct = require("glink.classes.TaskStruct")
local text = require("glink.lib.text")

StraightExecutor.__index = StraightExecutor

function StraightExecutor.new() 
	local executor = {  }
	setmetatable(executor, StraightExecutor)
	return executor
end

function StraightExecutor:useOPTS(OPTS)  	
	if (OPTS.j) then
		self.parallel = OPTS.j
	end
end


function StraightExecutor:executeRule(rulelist)
	for index, rulestruct in ipairs(rulelist) do  
		local rule = rulestruct.rule
		local check = rulestruct.check
		local echo = rulestruct.echo
		local noneed = rulestruct.noneed
		local message = rulestruct.message
		
		if noneed then goto continue end

		if check == nil then check = true end
		if echo == nil then echo = true end
		if pipe == nil then pipe = true end

		if echo then
			print(rule)
		end

		if message then
			print(message)
		end

		local iopipe = assert(io.popen(rule, 'r'))
		self.need = true

		if pipe then 
			for line in iopipe:lines() do
				print(line)
			end			
		end

		local status = iopipe:close()
		if check then
			if (status == nil) then 
				print("StraightExecutor:executeRule: " .. text.red("pipe return nil"))
				os.exit(1) 
			end
		end

		::continue::
	end
	return need
end

function StraightExecutor:executeStraight(tree) 
	local index = 1
	self.need = false
	
	for work in tree:workIterator() do
		local __ret = self:executeRule(work.rulelist)
		ret = ret or __ret
		tree:finalWork(work)
	end
	return self.need
end

function StraightExecutor:routineExecute() 
	
end

function StraightExecutor:__replaneRoutines() 
	while self.tree:haveWork() 	and self.cntact < self.maxact do
	end
end

function StraightExecutor:executeParallel(tree) 
	self.cntact = 0
	self.maxact = nil
	self.done = 0

	if self.parallel <= 0 then 
		error("wrong parallel arg")
	end

	if self.parallel == true then 
		self.maxact = 64 
	else
		self.maxact = self.parallel 
	end

	self:__replaneRoutines()
end

function StraightExecutor:execute(tree) 
	tree:prepare()
	
	if self.parallel then 
		return self:executeParallel(tree)
	else
		return self:executeStraight(tree)
	end
end

return StraightExecutor