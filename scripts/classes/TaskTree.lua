local TaskTree = {}

local TaskStruct = require("glink.classes.TaskStruct")
local text = require("glink.lib.text")

TaskTree.__index = TaskTree

function TaskTree.new() 
	local tree = {}
	setmetatable(tree, TaskTree)

	tree.tasks = {}
	tree.tasksTotal = 0
	return tree
end

function TaskTree:getTask(target)
	local ret = self.tasks[target]
	if not ret then
		error("TaskTree::getTask error: " .. text.red(target))
	end  
	return ret
end

function TaskTree:addTask(target, rulelist)
	if type(rulelist) == "string" then 
		rulelist = {{rule = rulelist}}
	end
	
	if self.tasks[target] then
		print("TaskTree conflict with name " .. text.red(target))
		os.exit(-1)
	end  

	self.tasks[target] = TaskStruct.new(target, rulelist)
	self.tasksTotal = self.tasksTotal + 1
end

function TaskTree:__countReference()
	for target, task in pairs(self.tasks) do
		task.totalReference = 0
		task.rcounter = 0
	end

	for target, task in pairs(self.tasks) do
		for index, depend in ipairs(task.next) do
			if not self.tasks[depend] then
				print("TaskTree::countReference conflict with name " .. text.red(task.target))
				os.exit(-1)
			end
			self.tasks[depend].totalReference = self.tasks[depend].totalReference + 1
		end
	end
end

function TaskTree:__startArrayPrepare()
	self.works = {}
	for target, task in pairs(self.tasks) do
		if task.totalReference == 0 then
			self.works[#self.works + 1] = task
		end
	end
end

function TaskTree:prepare()
	self:__countReference()
	self:__startArrayPrepare()
	self.windex = 0
end

function TaskTree:copy()
	return table.deep_copy(self) 
end

function TaskTree:addNext(base, next)
	tbase = self:getTask(base)
	tbase:addNext(next)
end

function TaskTree:multiBasesNext (bases, next)
	for index, base in ipairs(bases) do self:addNext(base, next) end
end

function TaskTree:printTree() 
	print("TaskTree")
	for target, task in pairs(self.tasks) do
		print(target, task.totalReference)
		for index, rule in ipairs(task.rulelist) do
			print(rule.rule)
		end
	end
end

function TaskTree:printWorks() 
	print("TaskTree::works")
	for index, task in ipairs(self.works) do
		for i, r in ipairs(task.rulelist) do
			print(r)
		end
	end
end

function TaskTree:contains(target)
	return self.tasks[target] and true or false
end

function TaskTree:workIterator() 
	return function ()
		self.windex = self.windex + 1
		if self.windex == #self.works + 1 then
			if self.windex ~= self.tasksTotal + 1 then
				print("StraightExecutor::error maybe RingDepends!!")
				os.exit(-1)
			end
			return nil
		end 
		return self.works[self.windex]
	end
end

function TaskTree:haveWork() 
	return self.works[self.windex + 1] ~= nil
end

function TaskTree:finalWork(work) 
	for index, name in ipairs(work.next) do
		local task = self:getTask(name)
		task.rcounter = task.rcounter + 1
		if task.rcounter == task.totalReference then
			self.works[#self.works + 1] = task
		end
 	end
end

return TaskTree