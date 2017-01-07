local _local_file = debug.getinfo(1).short_src
local _n, _n, _local_directory = string.find(debug.getinfo(1).short_src, "^(.+/)[^/]+$")
__directory = _local_directory

package.path = "/opt/glink/?.lua;" .. package.path

--unstandart extension
require("glink.lib.copy")
require("glink.lib.getopt")
File = require("glink.classes.File");

OPTS = getopt( arg, "" )

if OPTS["local"] == true then
	os.execute(__directory .. "/tools/copyToLocal.sh")
	os.exit(1)
end

if OPTS["global"] == true then
	os.execute("rm .glinkDirectory")
	os.exit(1)
end

--[[local templatedir
if (OPTS[1] == "ls") then
	for file in lfs.dir(__directory .. "/templates") do
		if (file ~= ".") and (file ~= "..") then print(file) end
	end
	os.exit(1)
end
]]
if (OPTS.template) then 
	if OPTS.template == true then 
		templatedir = __directory .. "/templates/init"
	else
		templatedir = __directory .. "/templates/" .. OPTS.template
	end
	local checkdir = File:new(templatedir)
	if checkdir.exists then 
		if OPTS.clean then
			os.execute("rm -r ./*")	
		end	

		if not OPTS.force then
			os.execute("cp -r -i " .. templatedir .. "/* .")
		else
			os.execute("cp -r " .. templatedir .. "/* .")
		end
	else
		print("Wrong template")
		os.exit(1)
	end
end

os.exit(1)
