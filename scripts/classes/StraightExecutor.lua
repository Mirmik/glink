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
	local need = false 
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
		need = true

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
	local ret = false
	tree:prepare()
	
	for work in tree:workIterator() do
		local __ret = self:executeRule(work.rulelist)
		ret = ret or __ret
		tree:finalWork(work)
	end
	return ret
end

function StraightExecutor:execute(tree) 
	if self.parallel then
		error(text.red("parallel assemble is not supported yet"))
	else
		return self:executeStraight(tree)
	end
end

return StraightExecutor