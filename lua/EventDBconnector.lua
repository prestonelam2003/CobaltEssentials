--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

--TODO: CHANGE THE FORMAT TO DATABASES > TABLES > KEYS > VALUES


------------------------------------------------------------INIT-----------------------------------------------------------
local M = {}

local cobaltSysChar = string.char(0x99, 0x99, 0x99, 0x99)

local requestTag = "" .. color(43) .. "[Request]" .. color(0) .. ""
local receiveTag = "" .. color(42) .. "[Receive]" .. color(0) .. ""

dontusesocket = true

function init()
	--dontusesocket = true
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
	local res = MP.TriggerLocalEvent("openDatabase", DBname)

	local databaseLoaderInfo = res[1]
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
					MP.TriggerLocalEvent("closeDatabase",DBname)
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
--changes the a value in the table in
local function set(DBname, tableName, key, value)
	if value == nil then
		value = "null"
	else
		value = json.stringify(value)
	end

	MP.TriggerLocalEvent("set", DBname, tableName, key, value)
end

local function setPort(port)
	server:close()
	server:setsockname('0.0.0.0', port)
	MP.TriggerLocalEvent("setCobaltDBport",port)
	return tonumber(server:receive()) == port
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------
--returns a specific value from the table
local function query(DBname, tableName, key)
	--CElog(requestTag .. " query - " ..DBname .. ">" .. tableName .. ">" .. key,"CobaltDB")

	local res = MP.TriggerLocalEvent("query", DBname, tableName, key)

	local data = res[1]

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
	--if type(data) ~= "table" then
	--end
	return data, error
end

--returns a read-only version of the table, or sub-table as json.
local function getTable(DBname, tableName)
	--reconnectSocket()
	--CElog(requestTag .. " #"    .. requestID .. ": getTable - " ..DBname .. ">" .. tableName,"CobaltDB" )

	local res = MP.TriggerLocalEvent("getTable", DBname, tableName, requestID)

	local data = res[1]
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
	--CElog(requestTag .. " #"    .. requestID .. ": getTables - " ..DBname,"CobaltDB")

	local res = MP.TriggerLocalEvent("getTables", DBname, requestID)

	local data = res[1]
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
	--CElog(requestTag .. " #"    .. requestID .. ": getKeys - " ..DBname .. ">" .. tableName,"CobaltDB")

	local res = MP.TriggerLocalEvent("getKeys", DBname, tableName, requestID)

	local data = res[1]
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
	--CElog(requestTag .. " #"    .. requestID .. ": tableExists - " ..DBname .. ">" .. tableName,"CobaltDB")

	local res = MP.TriggerLocalEvent("tableExists", DBname, tableName, requestID)

	exists = res[1] == tableName

	return exists
end

local function getCurrentRequestID()
	return requestID
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------
--This, err isn't used at all not sure why it exists, please don't use it
local function openDatabase(DBname)
	local res = MP.TriggerLocalEvent("openDatabase", DBname)

	if res[1] == DBname then
		--CElog(DBname .. " sucessfully opened.","CobaltDB")
		return true
	else
		return false
	end
end

--repair the connection to CobaltDB in the event of a disconnect.
--note: BeamMP functions time out after 6ish seconds, so since this is almost always a socket timeout problem, we have to factor in that there will be 2 seconds already gone to work with.
local function repairCobaltDBconnection(reason)

	CElog("/!\\ --------------------------COBALT-DB-CONNECTION-REPAIR-------------------------- /!\\\n","WARN")
	CElog("Cobalt Essentials has detected an error in your connection to CobaltDB","WARN")
	CElog("Please stand by while CE attempts to repair the connection.","WARN")

	--server = socket.udp()
	--server:settimeout(timeout)
	server:close()
	server:setsockname('0.0.0.0', tonumber(port))

	CElog("Socket has been reset, running a connection test.\n","WARN")

	local startTime = os.clock() * 1000
	MP.TriggerLocalEvent("testCobaltDBconnection")--request test

	local data, error = server:receive()--wait  for test
	local recTime = os.clock() * 1000

	if data == port then
		CElog(color(32) .. "CobaltDB Connection sucessfully repaired with a propagation delay of " .. math.floor(recTime - startTime) .. "ms","WARN")
		--CElog(color(32) .. "CobaltDB Connection sucessfully repaired with a propagation delay of " .. (startTime - recTime) .. "ms","CobaltDB")
		CElog("/!\\ --------------------------COBALT-DB-CONNECTION-REPAIR-------------------------- /!\\","WARN")
		return true
	else
		CElog("CobaltDB Connection repair was unsucessful, please try restarting your server.","WARN")
		CElog("If you are running multiple servers, make sure each server has a unique CobaltDBport","WARN")
		CElog("If the problem persists, please reach out to Cobalt Essentials support in our discord.","WARN")
		CElog("/!\\ --------------------------COBALT-DB-CONNECTION-REPAIR-------------------------- /!\\","WARN")
		return false
	end
end

local function receiveDB(expectedRequestID)
	requestID = requestID + 1 --increment requestID because
	--CElog(receiveTag .. " #" expectedRequestID ..": requested.","CobaltDB")
	local data,error = server:receive()
	--CElog((data or "nil") .. " was received.","CobaltDB")

	local s, e = data:find("%[requestIDsplitter%]")--find the index of the splitter
	local recRequestID

	if s ~= nil then
		recRequestID = data:sub(1,s-1)
		data = data:sub(e+1)
		--CElog(receiveTag .. " #" .. recRequestID .. ":" .. data,"CobaltDB")
	end

	if data == nil or expectedRequestID ~= tonumber(recRequestID) or s == nil then
		if repairCobaltDBconnection(error) == true then

			CElog("Requesting resend of last CobaltDB request","CobaltDB")
			MP.TriggerLocalEvent("DBresend")
			data, error = server:receive()


			s, e = data:find("%[requestIDsplitter%]")--find the index of the splitter
			recRequestID = data:sub(1,s-1)
			data = data:sub(e+1)

			if expectedRequestID ~= tonumber(recRequestID) then
				return nil
			end
		end
	end

	return data
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

M.getCurrentRequestID = getCurrentRequestID
----FUNCTIONS----
M.openDatabase = openDatabase--This, err isn't used at all not sure why it exists, please don't use it
M.reconnectSocket = reconnectSocket
M.socket = server
M.receiveDB = receiveDB

return M
