local lfs = require("lfs")   
--local pathops = require("glink.lib.pathops")
local plpath = require("pl.path")

local find = {}

function find.findInTree(root, pattern, hide, base)
	if base == nil then base = "." end 
	local result = {}
	local function recursiveFind(dir, pattern, hide) 
		local files = {}
		local dirs = {}
--
		for file in lfs.dir(dir) do
			if ((not (file == ".")) and (not (file == ".."))) then
				if (not file:match(hide)) then
					local path = plpath.join(dir,file)
					local attrib = lfs.attributes(path)
					if (attrib.mode == "file") then 
						--print(pl.path.relpath(path, base))
						if file:match(pattern) then result[#result + 1] = plpath.abspath(path) end 
					end
					if (attrib.mode == "directory") then 
						recursiveFind(path, pattern, hide)
					end
				end
			end
		end
	end

	recursiveFind(root,pattern,hide)
	--print(table.tostring(result))
	--while(1) do end
	return result 
end

return find