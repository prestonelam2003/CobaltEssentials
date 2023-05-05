--Copyright (C) 2023, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

--TODO: CHANGE THE FORMAT TO DATABASES > TABLES > KEYS > VALUES


------------------------------------------------------------INIT-----------------------------------------------------------
local M = {}

pluginPath = pluginPath or (resources .. "/Server/" .. pluginName) -- for public CE compatibility

local dbPath = pluginPath .. "/CobaltDB/"
local cobaltSysChar = string.char(0x99, 0x99, 0x99, 0x99)

--TriggerLocalEvent("initDB", package.path, package.cpath, dbPath, json.stringify(config))

local port = 10814 -- port the cobaltDB server can be found on
local serverID = "server1" -- id of this server, should be unique
local forceTarget = true -- fancy feature, keep on by default

socket = require("socket")
local server = socket.udp()
server:settimeout(3)

local function init(configPort, hostname)
	if utils then

		local configPath = pluginPath .. "/dbConfig.json"

		if FS.Exists(configPath) then
			local configcontents = utils.readJson(configPath)

			if not configcontents.ServerID then
				CElog("No DB serverID specified in the config, defaulting to '"..serverID.."'","WARN")
			else
				serverID = configcontents.ServerID
				CElog("Remote CobaltDB Connector ID set to "..serverID, 'CobaltDB')
			end
			if not configcontents.remoteDBport then
				CElog("No Remote CobaltDB port specified in the config, defaulting to '"..port.."'","WARN")
			else
				port = configcontents.remoteDBport
				CElog("Remote CobaltDB Connector port set to "..port, 'CobaltDB')
			end

			if configcontents.forceTarget ~= nil then
				forceTarget = configcontents.forceTarget
				CElog("Remote CobaltDB Connector 'forceTarget' set to "..tostring(forceTarget), 'CobaltDB')
			end
		else
			CElog('No Remote CobaltDB config found, using default values', "WARN")
			utils.writeJson(configPath, {ServerID=serverID, remoteDBport=port, forceTarget=forceTarget})
		end
	end

	print("setting peer to port ", port)

	print(hostname)
	server:setpeername(hostname or 'localhost', tonumber(port))


	server:send(json.stringify({event='ping', id=serverID}))
	local resp, err = server:receive()
	if (not resp) or resp ~= "pong" or err then
		CElog('CobaltDB connection failed: '..tostring(err)..', closing server.', 'WARN')
		socket.sleep(3)
		return false
	else
		CElog('CobaltDB response OK', 'CobaltDB')
		return true
	end
end


--Set up metatable so that CobaltDB is intuitive to work with.
--setup metatable for the MAIN LAYER
--THIS TABLE IS THE MAIN LAYER / IT IS NOT THE SUB-TABLE
local databaseTemplate = {}
databaseTemplate.protectedKeys =
{
	CobaltDB_databaseName = true,
	CobaltDB_newTable = true,
	CobaltDB_targetID = true
}

databaseTemplate.metatable =
{
	__index = function(DB, key)
		if key and not rawget(DB, key) then
			local table = DB:CobaltDB_newTable(key, DB.CobaltDB_targetID)
			DB[key] = table

			return table
		end
	end,

	__pairs = function(database)

		indexes = M.getTables(database.CobaltDB_databaseName, database.CobaltDB_targetID)

		local function stateless_iter(indexTable, k)

				k, v = next(indexTable, k)
				v = database[k]

				if v ~= nil then
					return k, v
				end
		end

		return stateless_iter, indexes, nil
	end
}

--DATABASE TABLE
local tableTemplate = {}
tableTemplate.protectedKeys =
{
	CobaltDB_databaseName = true,
	CobaltDB_tableName = true,
	CobaltDB_targetID = true,
	exists = true
}
--Setup metatable for the sub-table
--THIS IS THE SUBTABLE
tableTemplate.metatable =
{
	__index = function(table, key)
		return M.query(table.CobaltDB_databaseName, table.CobaltDB_tableName, key, table.CobaltDB_targetID)
	end,

	__newindex = function(table, key, value)

		--is this a protectedKey?
		if tableTemplate.protectedKeys[key] then
			rawset(table,key,value)
		else
			return M.set(table.CobaltDB_databaseName, table.CobaltDB_tableName, key, value, table.CobaltDB_targetID)
		end
	end,

	__pairs = function(table)

		local cobaltTable = M.getTable(table.CobaltDB_databaseName, table.CobaltDB_tableName, table.CobaltDB_targetID)

		return next, cobaltTable, nil
	end
}


--------------------------------------------------------CONSTRUCTOR--------------------------------------------------------


local function newDatabase(dbName, targetID)
	if targetID == "local" then targetID = serverID end
	targetID = forceTarget and (targetID or serverID) or nil --default to local DBs
	server:send(json.stringify({event = "openDatabase", id=serverID, dbname = dbName, targetid=targetID}))

	local dbResponseString = server:receive()
	if dbResponseString ~= nil then
		local parsedResposnse = json.parse(dbResponseString)

		if not parsedResposnse or not parsedResposnse.targetID then
			CElog(dbName .. " could not be opened, Remote DB returned an invalid response: " .. dbResponseString, "WARN")
			return nil, "Invalid response from CobaltDB"
		else
			CElog(dbName .. " successfully opened, target is: " .. parsedResposnse.targetID, "CobaltDB")

			local dbHandle =
			{
				CobaltDB_databaseName = dbName,
				CobaltDB_newTable = M.newTable,
				CobaltDB_targetID = parsedResposnse.targetID,
				close = function(table)
					TriggerLocalEvent("closeDatabase",dbName)
				end

			}
			setmetatable(dbHandle, databaseTemplate.metatable)

			return dbHandle, parsedResposnse.isNew and "new" or "existing"
		end
	else
		print("No response from CobaltDB")
		return nil, "No response from CobaltDB"
	end
end

local function newTable(DB, tableName)
	newTable =
	{
		CobaltDB_databaseName = DB.CobaltDB_databaseName,
		CobaltDB_targetID = DB.CobaltDB_targetID,
		CobaltDB_tableName = tableName,
		exists = function(table)
			return M.tableExists(table.CobaltDB_databaseName, table.CobaltDB_tableName, table.CobaltDB_targetID)
		end
	}
	setmetatable(newTable, tableTemplate.metatable)

	return newTable
end

----------------------------------------------------------EVENTS-----------------------------------------------------------




----------------------------------------------------------MUTATORS---------------------------------------------------------

--changes the a value in the table in
local function set(DBname, tableName, key, value, targetID)
	targetID = targetID or serverID --default to local DBs
	if value == nil then
		value = "null"
	else
		value = json.stringify(value)
	end

	server:send(json.stringify({event = "set", id=serverID, dbname = DBname, table = tableName, key = key, value = value, targetid=targetID}))
end

local function setPort(port)
	server:close()
	server:setsockname('0.0.0.0', port)
	TriggerLocalEvent("setCobaltDBport",port)
	return tonumber(server:receive()) == port
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------
--returns a specific value from the table
local function query(DBname, tableName, key, targetID)
	targetID = targetID or serverID --default to local DBs

	server:send(json.stringify({event = "query", id=serverID, dbname = DBname, table = tableName, key = key, targetid=targetID}))

	local data, error = server:receive()

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
local function getTable(DBname, tableName, targetID)
	targetID = targetID or serverID --default to local DBs

	server:send(json.stringify({event = "getTable", id=serverID, dbname = DBname, table = tableName, targetid=targetID}))

	local data, error = server:receive()

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

--returns a read-only list of all tables within the database
local function getTables(DBname, targetID)
	targetID = targetID or serverID --default to local DBs

	server:send(json.stringify({event = "getTables", id=serverID, dbname = DBname, targetid=targetID}))

	local data, error = server:receive()

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

local function getKeys(DBname, tableName, targetID)
	targetID = targetID or serverID --default to local DBs

	server:send(json.stringify({event = "getKeys", id=serverID, dbname = DBname, table = tableName, targetid=targetID}))


	local data, error = server:receive()

	if data:sub(1,4) == cobaltSysChar then
		error = data:sub(5)
		data = nil
	else
		data = json.parse(data)
	end

	return data, error
end

local function tableExists(DBname, tableName, targetID)
	targetID = targetID or serverID --default to local DBs

	server:send(json.stringify({event = "tableExists", id=serverID, dbname = DBname, table = tableName, targetid=targetID}))


	exists = server:receive() == tableName

	return exists
end


------------------------------------------------------PUBLIC INTERFACE------------------------------------------------------


-----CONSTRUCTOR-----
M.init = init
M.new = newDatabase
M.newTable = newTable

----MUTATORS-----
M.set = set

----ACCESSORS----
M.query = query
M.getTable = getTable
M.getTables = getTables
M.getKeys = getKeys
M.tableExists = tableExists

----FUNCTIONS----
M.openDatabase = newDatabase
M.setPort = function(...) end

return M
