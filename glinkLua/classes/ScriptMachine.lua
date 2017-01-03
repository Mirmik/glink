--local File = dofile(__directory .. "/classes/File.lua")
local pathops = dofile(__directory .. "/lib/pathops.lua")
local text = dofile(__directory .. "/lib/text.lua")

local ScriptMachine = {}
ScriptMachine.__index = ScriptMachine

function ScriptMachine:new() 
	local script = {}
	setmetatable(script, self)

	script.currentFile = ""
	script.currentDir = os.getenv("PWD")
	script.mtime = 0;
	script.context = {};
	script.fileQuery = {};

	return script
end

-- load and run a script in the provided environment
-- context object will be changed in chunk
function ScriptMachine:run(scriptfile, context)
	local chunk = assert(loadfile(scriptfile, nil, context));
    chunk();
    return context;
end

function ScriptMachine:__evalFile(path, context) 
	local oldFileName = self.currentFile;
	local oldDirName = self.currentDir;

	local resolve = pathops.resolve(self.currentDir, path)
	
	local file = File:new(resolve)
	if (not file.exists) then
		print("File " .. file.path .. " is not exists")
		os.exit(1)
	end

	--Добавляем файл в стэк зависимостей.
	local oldmtime = self.mtime;
	self.fileQuery[#self.fileQuery + 1] = file;
	
	if (file.mtime > self.mtime) then self.mtime = file.mtime end

	self.currentFile = resolve;
	self.currentDir = pathops.dirname(resolve);

	-- load and run a script in the provided environment
	self:run(resolve, context) 

	--Очищаем файл из стэка зависимостей.
	table.remove(self.fileQuery, #self.fileQuery);

	self.mtime = oldmtime;
	self.currentFile = oldFileName;
	self.currentDir = oldDirName;

	-- Возвращаем измененный контекст
	return context
end

function ScriptMachine:evalFile(path, context)
	copycontext = table.shallow_copy(context)
	
	if type(path) == "table" then
		for i = 1, #path do
			self:__evalFile(path[i], copycontext) 
		end
		return
	else 
		return self:__evalFile(path, copycontext)
	end
end

return ScriptMachine