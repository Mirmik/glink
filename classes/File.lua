local lfs = require("lfs")    

local File = {}
File.__index = File

function File:new(path) 
	local file = {}
	setmetatable(file, self)

	file.path = path;
	file:update()

	return file
end

function File:update()
	local attrib = lfs.attributes(self.path);

	if (attrib) then
		self.exists = true
		self.attrib = attrib
		self.mtime = attrib.modification
	else
		self.exists = false
		self.attrib = nil
		self.mtime = nil
	end
end

--File.prototype.remove = function() {
--	if (this.exists) fs.unlinkSync(this.path);
--}

return File;