local needops = {} 

function needops.needToRecompile(objpath, deppath, modmtime, weak)
	local fileCache = GlinkGlobal.globalFileCache
	
	local objfile = fileCache:getFile(objpath);
	local depfile = fileCache:getFile(deppath);

	--print("here")
	if objfile.exists == false then return true end 
	if depfile.exists == false then return true end 
	if weak == "norecompile" then return false end

	local file = assert(io.open(depfile.path, "r"))
	local deptext = file:read("*a")
	
	if #deptext < 2 then return true end

	local arr = {} 
	for file in deptext:gmatch("[^ \n\\]+") do
		arr[#arr + 1] = file
	end

	local maxtime = (weak == "noscript") and 0 or modmtime
	
--	print("here")
	for i = 2, #arr do 
		local file = fileCache:getFile(arr[i]);
		if file.exists == false then return true end
		if file.mtime > maxtime then maxtime = file.mtime end
	end
	
--	print(maxtime > depfile.mtime)
	return maxtime > depfile.mtime
end

function needops.needToUpdateDirectory(dir)
	local fileCache = GlinkGlobal.globalFileCache
	return not fileCache:getFile(dir).exists 
end


function needops.needToUpdateFile(path)
	local fileCache = GlinkGlobal.globalFileCache
	return not fileCache:getFile(path).exists 
end

return needops