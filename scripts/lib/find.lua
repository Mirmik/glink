local lfs = require("lfs")   
local pathops = require("glink.lib.pathops")

local find = {}

function find.findInTree(root, pattern, hide)
	local result = {}
	local function recursiveFind(dir, pattern, hide) 
		local files = {}
		local dirs = {}
--
		for file in lfs.dir(dir) do
			if ((not (file == ".")) and (not (file == ".."))) then
				if (not file:match(hide)) then
					local path = pathops.resolve(dir,file)
					local attrib = lfs.attributes(path)
					if (attrib.mode == "file") then 
						if file:match(pattern) then result[#result + 1] = path end 
					end
					if (attrib.mode == "directory") then 
						recursiveFind(path, pattern, hide)
					end
				end
			end
		end
	end

	recursiveFind(root,pattern,hide)
	return result 
end

return find