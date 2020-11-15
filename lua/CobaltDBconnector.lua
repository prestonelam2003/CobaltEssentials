--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

--TODO: CHANGE THE FORMAT TO DATABASES > TABLES > KEYS > VALUES


------------------------------------------------------------INIT-----------------------------------------------------------

local M = {}

local dbPath = resources .. "/server/" .. pluginName .. "/CobaltDB/"
local cobaltSysChar = string.char(0x99, 0x99, 0x99, 0x99)

socket = require("socket")
local server = socket.udp()

server:settimeout(3)
server:setsockname('0.0.0.0', 58933)

TriggerLocalEvent("initDB", package.path, package.cpath, dbPath, json.stringify(config))


--Set up metatable so that CobaltDB is intuitive to work with.
--Setup metatable for the main layer.
local databaseTemplate = {}
databaseTemplate.metatable =
{
	__index = function(DB, key)
	--print("TABLE ACCESS TRY" ,key, type(key))
		if key and not rawget(DB, key) then
			local table = DB:CobaltDB_newTable(key)
			DB[key] = table

			return table
		end
	end,

	__pairs = function(database)
	
		indexes = M.getTables(database.CobaltDB_databaseName)
	
		local function stateless_iter(indexTable, k)
		
				k, v = next(indexTable, k)
	
				v = database[k]
				--print(k, v ,database[k])
				
				if v ~= nil then
						return k, v
				end
		end	
		
		return stateless_iter, indexes, nil
	end
}

databaseTemplate.protectedKeys = 
{
	CobaltDB_databaseName = true,
	CobaltDB_newTable = true
}


--DATABASE TABLE
local tableTemplate = {}

tableTemplate.protectedKeys = 
{
	CobaltDB_databaseName = true,
	CobaltDB_tableName = true,
	exists = true
}


tableTemplate.metatable = 
{
	__index = function(table, key)
		return M.query(table.CobaltDB_databaseName, table.CobaltDB_tableName,key)
	end,

	__newindex = function(table, key, value)
		
		--is this a protectedKey?
		if tableTemplate.protectedKeys[key] ~= nil then
			rawset(table,key,value)
		else
			return M.set(table.CobaltDB_databaseName, table.CobaltDB_tableName, key, value)
		end
	end,

	__pairs = function(table)
		
		local cobaltTable = M.getTable(table.CobaltDB_databaseName, table.CobaltDB_tableName)
				
		return next, cobaltTable, nil
	end
}


--------------------------------------------------------CONSTRUCTOR--------------------------------------------------------

local function newDatabase(DBname)
	TriggerLocalEvent("openDatabase", DBname)
	
	databaseLoaderInfo = server:receive()

	if databaseLoaderInfo ~= nil then
		print("CobaltDB: " .. DBname .. " sucessfully opened.")

		newDatabase = 
		{
			CobaltDB_databaseName = DBname,
			CobaltDB_newTable = M.newTable,
			close = function(table)
				TriggerLocalEvent("closeDatabase",DBname)
			end

		}
		setmetatable(newDatabase, databaseTemplate.metatable)

		return newDatabase, databaseLoaderInfo
	else
		return nil
	end
end

local function newTable(DB, tableName)
	newTable =
	{
		CobaltDB_databaseName = DB.CobaltDB_databaseName,
		CobaltDB_tableName = tableName,
		exists = function(table)
			return M.tableExists(table.CobaltDB_databaseName, table.CobaltDB_tableName)
		end
	}
	setmetatable(newTable, tableTemplate.metatable)

	return newTable
end

----------------------------------------------------------EVENTS-----------------------------------------------------------




----------------------------------------------------------MUTATORS---------------------------------------------------------
--changes the a value in the table in
local function set(DBname, tableName, key, value)
	
	value = json.stringify(value)
	TriggerLocalEvent("set", DBname, tableName, key, value)
end

local function setPort(port)
	server:close()
	server:setsockname('0.0.0.0', port)
	TriggerLocalEvent("setCobaltDBport",port)
	return tonumber(server:receive()) == port
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------
--returns a specific value from the table
local function query(DBname, tableName, key)
	TriggerLocalEvent("query", DBname, tableName, key)
	
	local data = server:receive()
	local error

	if type(data) == "string" then
		if data:sub(1,4) == cobaltSysChar then
			error = data:sub(5)
			data = nil
		else
			if data:sub(1,1) == "E" then
				error = data
				data = nil
			else
				data = json.parse(data)
			end
		end
	end
		

	return data, error
end

--returns a read-only version of the table, or sub-table as json.
local function getTable(DBname, tableName)
	TriggerLocalEvent("getTable", DBname, tableName)
	
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

--returns a read-only list of all tables within the database
local function getTables(DBname)
	TriggerLocalEvent("getTables", DBname)
	
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

local function getKeys(DBname, tableName)
	TriggerLocalEvent("getKeys", DBname, tableName)
		
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

local function tableExists(DBname, tableName)
	TriggerLocalEvent("tableExists", DBname, tableName)
	return server:receive() == tableName
end


---------------------------------------------------------FUNCTIONS---------------------------------------------------------
local function openDatabase(DBname)
	TriggerLocalEvent("openDatabase", DBname)
	if server:receive() == DBname then
		print("CobaltDB: " .. DBname .. " sucessfully opened.")
		return true
	else
		return false
	end
end


------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


-----CONSTRUCTOR-----
M.setPort = setPort
M.new = newDatabase
M.newTable = newTable

----EVENTS-----

----MUTATORS-----
M.set = set
----ACCESSORS----
M.query = query
M.getTable = getTable
M.getTables = getTables
M.getKeys = getKeys
M.tableExists = tableExists
----FUNCTIONS----
M.openDatabase = openDatabase

return M