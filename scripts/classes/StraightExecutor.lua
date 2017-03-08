local StraightExecutor = {}

local glinkLib = require("glinkLib")
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
		self.parallel = self.parallel == true and 999 or tonumber(OPTS.j)
	end
end


function StraightExecutor:executeRule(rulelist)
	for index, rulestruct in ipairs(rulelist) do  
		local rule = rulestruct.rule
		local check = rulestruct.check
		local echo = rulestruct.echo
		local noneed = rulestruct.noneed
		local message = rulestruct.message
		
		--Если установлен флаг noneed, операция игнорируется
		if noneed then goto continue end

		if check == nil then check = true end
		if echo == nil then echo = true end
		if pipe == nil then pipe = true end

		--echo : дублирование в консоль выполняемого правила.
		if echo then
			print(rule)
		end

		--message : при выполнение правила вывод сообщения.
		if message then
			print(message)
		end

		local iopipe = assert(io.popen(rule, 'r'))
		self.need = true

		--pipe : вывод на печать stdout выполненого правила.
		if pipe then 
			for line in iopipe:lines() do
				print(line)
			end			
		end

		--проверка возвращенного статуса..
		local status = iopipe:close()
		if check then
			if (status == nil) then 
				FaultError("StraightExecutor:executeRule", text.red("pipe return nil"))
			end
		end

		::continue::
	end
	--return need
end

function StraightExecutor:executeStraight(tree) 
	self.need = false
	
	for work in tree:workIterator() do
		self:executeRule(work.rulelist)
		tree:finalWork(work)
	end

	--Если во время сборки не было произведено никаких действий,
	--вернется false.
	return self.need
end

function StraightExecutor:CreateNewWorks() 
	while #self.tworks < self.parallel and self.tree:haveWork() do
		local work = self.parallelWorkIterator()
		if work == nil then return end
		self.tworks[#self.tworks + 1] = {
			work = work,
			index = 0, 
			currs = nil,
			pipe = nil,
		}
	end
end

function StraightExecutor:CheckWork(workerindex, twork) 
	--Проверка работы pipe и завершение rulestruct
	if twork.pipe ~= nil then
		
	end

	--Завершение работы задачи. Создание ворков на освободившихся местах..
	if twork.index == #twork.work.rulelist then
		self.tree:finalWork(twork.work)
		table.remove(self.tworks, workerindex)
		self:CreateNewWorks()
		return
	end

	twork.index = twork.index + 1
	twork.currs = twork.work.rulelist[twork.index]

	if twork.currs.message then 
		print(workerindex, twork.currs.message)
	end

	twork.pipe = assert(io.popen(twork.currs.rule, 'r'))

end

function StraightExecutor:executeParallel(tree) 
	self.need = false
	--self.tworks = {}
	---self.tree = tree
	--self.parallelWorkIterator = tree:workIterator()
	
	--self.tree:printTree()

	--self:CreateNewWorks()
	--while true do
	--	for k, t in ipairs(self.tworks) do
	--		self:CheckWork(k,t)
	--	end

	--	if #self.tworks == 0 then break end
	--end
	local ctasks = {}
	for k, v in pairs(tree.tasks) do
		ctasks[#ctasks + 1] = {
			target = v.target,
			rulelist = v.rulelist,
			next = v.next,
		}
	end

	glinkLib.straight_executor_parallel_tasks_execute(ctasks, self.parallel)

	--Если во время сборки не было произведено никаких действий,
	--вернется false.
	return self.need
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