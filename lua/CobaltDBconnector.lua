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

TriggerLocalEvent("initDB", package.path, package.cpath, dbPath, json.stringify(config))

local port = 10814
socket = require("socket")
local server = socket.udp()
server:settimeout(3)

local function init(configPort)

	port = configPort
	server:setsockname('0.0.0.0', tonumber(port))

end


--Set up metatable so that CobaltDB is intuitive to work with.
--setup metatable for the MAIN LAYER
--THIS TABLE IS THE MAIN LAYER / IT IS NOT THE SUB-TABLE
local databaseTemplate = {}
databaseTemplate.metatable =
{
	__index = function(DB, key)
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
				--CElog(k, v ,database[k])
				
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
--Setup metatable for the sub-table
--THIS IS THE SUBTABLE
tableTemplate.metatable = 
{
	__index = function(table, key)
		return M.query(table.CobaltDB_databaseName, table.CobaltDB_tableName,key)
	end,

	__newindex = function(table, key, value)
		
		--is this a protectedKey?
		if tableTemplate.protectedKeys[key] then
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
		if databaseLoaderInfo:sub(1,2) == "E:" then
			CElog(DBname .. " could not be opened after 5 tries due to: " .. databaseLoaderInfo:sub(3),"CobaltDB")
			return nil, "CobaltDB failed to load " .. DBname .. "after 5 tries due to : " .. databaseLoaderInfo:sub(3)
		else
			CElog(DBname .. " sucessfully opened.","CobaltDB")

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
		end
	else
		return nil, "No response from CobaltDB"
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

--used to make sure the socket is connected
local function reconnectSocket()
	server:setsockname('0.0.0.0', tonumber(port))
end


--changes the a value in the table in
local function set(DBname, tableName, key, value)
	if value == nil then
		value = "null"
	else
		value = json.stringify(value)
	end

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
	--reconnectSocket()
	
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
		
	--server:close()
	return data, error
end

--returns a read-only version of the table, or sub-table as json.
local function getTable(DBname, tableName)
	--reconnectSocket()
	
	TriggerLocalEvent("getTable", DBname, tableName)
	
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	--server:close()
	return data, error
end

--returns a read-only list of all tables within the database
local function getTables(DBname)
	--reconnectSocket()
	
	TriggerLocalEvent("getTables", DBname)
	
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	--server:close()
	return data, error
end

local function getKeys(DBname, tableName)
	--reconnectSocket()

	TriggerLocalEvent("getKeys", DBname, tableName)
		
	local data = server:receive()
	local error

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	--server:close()
	return data, error
end

local function tableExists(DBname, tableName)
	--reconnectSocket()	

	TriggerLocalEvent("tableExists", DBname, tableName)
	
	exists = server:receive() == tableName

	--server:close()
	return exists
end


---------------------------------------------------------FUNCTIONS---------------------------------------------------------
local function openDatabase(DBname)
	--reconnectSocket()
	
	TriggerLocalEvent("openDatabase", DBname)
	if server:receive() == DBname then
		CElog(DBname .. " sucessfully opened.","CobaltDB")
		
		--server:close()
		return true
	else
		
		--server:close()
		return false
	end
end


------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


-----CONSTRUCTOR-----
M.init = init
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