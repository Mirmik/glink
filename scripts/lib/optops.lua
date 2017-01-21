-- Операции над опциями модулей.

optops = {}

text = require("glink.lib.text")
pathops = require("glink.lib.pathops")

function optops.default(opt, dtbl)
	for key, property in pairs(dtbl) do
		if opt[key] == nil then
			opt[key] = dtbl[key]
		end
	end
end

function optops.f_changeMerge(old, new) return new end
function optops.f_noMerge(old, new) return old end
function optops.f_nilMerge(old, new) return nil end
function optops.f_changeWeakMerge(old, new) return new and new or old end
function optops.f_straightStringPrepare(inp) 
	assert (type(inp) == "string") 
	return inp 
end

function optops.f_stringToArrayPrepare(inp) 
	assert (type(inp) == "string" or type(inp) == "table") 
	if type(inp) == "string" then
		return string.split(inp, ' ')
	end
	return inp
end

function optops.f_concatMerge(old, new) 
	if not new then return old end
	if not old then return new end
	return table.arrayConcat(old, new)
end

function optops.prepareMetaTable(opttable) 
	for key, opt in pairs(opttable) do
		if opt.otype == "string" then
			optops.default(opt, {
				merge = optops.f_changeWeakMerge,
				prepare = optops.f_straightStringPrepare,
			})
		
		elseif opt.otype == "table" then
			optops.prepareMetaTable(opt.table)
		
		elseif opt.otype == "array" then
			optops.default(opt, {
				merge = optops.f_concatMerge,
				prepare = optops.f_stringToArrayPrepare,
			})	

		else
			print(text.red("option table error"))
			os.exit(-1)
		end
	end
end

function optops.prepare(opts, metatbl) 
	function step1(opts, metatbl) 	
		for key, opt in pairs(opts) do
			local proto = metatbl[key]
			if proto == nil then
				print("Wrong property name " .. text.red(key) .. " in module " .. text.red(opts.__name__))
				os.exit(-1)
			end	
		
			if proto.otype == "table" then
				if type(opt) ~= "table" then
					print(text.red(key) .. " must be table")
					os.exit(-1)
				end	
				step1(opt, proto.table)
			else
				opts[key] = proto.prepare(opt)
			end
		end
	end
	step1(opts,metatbl)

	function step2(opts, metatbl) 	
		for key, proto in pairs(metatbl) do
			local opt = opts[key]
			if opt == nil then
				if proto.otype == "table" then
					opts[key] = {}
					step2(opts[key], proto.table)
				elseif proto.default ~= nil then
					opts[key] = proto.default
				end 
			end
		end
	end
	step2(opts, metatbl)
end	

function optops.merge(bot, top, meta, optional_method) 
	--print("B", table.tostring(top))
	for key, proto in pairs(meta) do
		if proto.otype == "table" then
			optops.merge(bot[key], top[key], proto.table, optional_method)
		else
			if optional_method and proto[optional_method] then
				bot[key] = proto[optional_method](bot[key], top[key])
			else
				--print(key, bot[key], top[key])
				--print(key,bot[key], top[key], optional_method)
				bot[key] = proto.merge(bot[key], top[key])
				--print(bot[key])
			end
		end
	end
end

function optops.restorePaths(tbl, meta, basedir) 
	for key, proto in pairs(meta) do
		if proto.otype == "table" then
			optops.restorePaths(tbl[key], proto.table, basedir)
		else
			if proto.paths and tbl[key] then	
				for index, path in ipairs(tbl[key]) do
					tbl[key][index] = pathops.resolve(basedir, path)
				end
			end
		end
	end
end

return optops