local StraightExecutor = {}

local TaskTree = require("glink.classes.TaskTree")
local TaskStruct = require("glink.classes.TaskStruct")
local text = require("glink.lib.text")

StraightExecutor.__index = StraightExecutor

function StraightExecutor.new(tree) 
	local executor = { tree = tree:copy() }
	executor.tree:prepare()
	setmetatable(executor, StraightExecutor)
	return executor
end

function StraightExecutor:executeRule(rulelist) 
	for index, rulestruct in ipairs(rulelist) do  
		local rule = rulestruct.rule
		local check = rulestruct.check
		local echo = rulestruct.echo
		local message = rulestruct.message
		
		if check == nil then check = true end
		if echo == nil then echo = true end
		if pipe == nil then pipe = true end

		local pipe = assert(io.popen(rule, 'r'))
		
		if pipe then 
			for line in pipe:lines() do
				print(line)
			end			
		end

		if echo then
			print(rule)
		end

		if message then
			print(message)
		end

		local status = pipe:close()
		if check then
			if (status == nil) then 
				print("StraightExecutor:executeRule: pipe return nil")
				os.exit(1) 
			end
		end
	end
end

function StraightExecutor:execute() 
	local index = 1
	local ret = false
	for work in self.tree:workIterator() do
		ret = true
		self:executeRule(work.rulelist)
		self.tree:finalWork(work)
	end
	return ret
end

return StraightExecutor