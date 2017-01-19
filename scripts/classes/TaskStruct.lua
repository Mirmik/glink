local TaskStruct = {}

TaskStruct.__index = TaskStruct

function TaskStruct.new(target, rulelist) 
	local task = {}
	setmetatable(task, TaskStruct)

	task.target = target
	task.rulelist = rulelist
	task.next = {}

	return task
end

function TaskStruct:addNext(next)
	self.next[#self.next + 1] = next
end

return TaskStruct