--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

--TODO: CHANGE THE FORMAT TO DATABASES > TABLES > KEYS > VALUES

local M = {}

local loadedDatabases = {}
--local loadedJson = {}

local dbpath

local cobaltSysChar = string.char(0x99, 0x99, 0x99, 0x99)

local CobaltDBport = 58933

MP.RegisterEvent("initDB","initDB")
MP.RegisterEvent("openDatabase","openDatabase")
MP.RegisterEvent("closeDatabase","closeDatabase")
MP.RegisterEvent("setCobaltDBport","setCobaltDBport")
MP.RegisterEvent("DBresend","resend")
MP.RegisterEvent("repairDBconnection","repairDBconnection")

MP.RegisterEvent("testCobaltDBconnection","testConnection")

MP.RegisterEvent("query","query")
MP.RegisterEvent("getTable","getTable")
MP.RegisterEvent("getTables","getTables")
MP.RegisterEvent("getKeys","getKeys")
MP.RegisterEvent("tableExists","tableExists")

MP.RegisterEvent("HandleSyncEvent","HandleSyncEvent")

MP.RegisterEvent("set","set")

----------------------------------------------------------EVENTS-----------------------------------------------------------
--give the CobaltDBconnector all the information it needs without having to re-calculate it all
function initDB()
	json = require("json")
	utils = require("CobaltUtils")

	dbpath = pluginPath .. "/CobaltDB/"

	if not dontusesocket then
		socket = require("socket")

		local jsonFile, error = io.open(dbpath .."config.json")
		if error == nil then
			CobaltDBport = tonumber(json.parse(jsonFile:read("*a")).CobaltDBport.value)
			jsonFile:close()
		end
	end
	CElog("CobaltDB Initiated","CobaltDB")
	MP.TriggerLocalEvent("onCobaltDBhandshake",CobaltDBport)

	if not dontusesocket then
		connector = socket.udp()
	end
end
----------------------------------------------------------MUTATORS---------------------------------------------------------

function openDatabase(DBname, requestID)

	local jsonPath = dbpath .. DBname .. ".json"

	local databaseLoaderInfo = "error" -- defines if the DB was created just now or if it was pre-existing.

	local contents, error = utils.readJson(jsonPath)

	if error then
		if error == "File does not exist" then
			CElog("JSON file does not exist, creating a new one.","CobaltDB")
			databaseLoaderInfo = "new"

			local success, error = utils.writeJson(jsonPath, nil)

			if not success then
				CElog('failed to write file "' .. tostring(jsonPath) .. '", error: ' .. tostring(error),"WARN")
			end

			loadedDatabases[DBname] = {}
		end
	else
		databaseLoaderInfo = "loaded"
		loadedDatabases[DBname] = contents
	end

	if dontusesocket then return databaseLoaderInfo end

	databaseLoaderInfo = requestID .. "[requestIDsplitter]" .. databaseLoaderInfo
	connector:sendto(databaseLoaderInfo ,"127.0.0.1", CobaltDBport)
	lastSent = databaseLoaderInfo
end

function closeDatabase(DBname)
	updateDatabase(DBname)

	--loadedJson[DBname] = nil
	loadedDatabases[DBname] = nil
end

function setCobaltDBport(port)
	CobaltDBport = tonumber(port)
	connector:sendto(CobaltDBport ,"127.0.0.1", CobaltDBport)
	lastSent = CobaltDBport
end

--tells CobaltDB that the data was not received.
function resend()
	connector:sendto(lastSent ,"127.0.0.1", CobaltDBport)
end

function testConnection()
	connector:sendto(CobaltDBport ,"127.0.0.1", CobaltDBport)
end

--saves the table's changes to a file
function updateDatabase(DBname)

	local filePath = dbpath .. DBname

	local success, error = utils.writeJson(filePath..".temp", loadedDatabases[DBname])

	if success then
		success, error = FS.Remove(filePath .. ".json")
		if success then
			success, error = FS.Rename(filePath .. ".temp", filePath .. ".json")
		end
	end

	if not success then
		CElog('Failed to update database "'..DBname..'"on disk: '..tostring(error), "WARN")
	end

	----CElog("Updated: '" .. dbpath .. DBname .. ".json'","DEBUG")
end



--changes the table
function set(DBname, tableName, key, value)

	if loadedDatabases[DBname] ~= nil then

		if loadedDatabases[DBname][tableName] == nil then
			loadedDatabases[DBname][tableName] = {}
		end

		if key ~= nil then
			if value == "null" then
				loadedDatabases[DBname][tableName][key] = nil
			else
				loadedDatabases[DBname][tableName][key] = json.parse(value)
			end
			updateDatabase(DBname)
		end

	else --TABLE DOESN'T EXIST
		error("CobaltDB Table " .. DBname .. " not loaded!")
	end

end


---------------------------------------------------------ACCESSORS---------------------------------------------------------

--returns a specific value from the table
function query(DBname, tableName, key, requestID)
	local data

	if loadedDatabases[DBname] == nil then
		--error here, database isn't open
		data = cobaltSysChar .. "E:" .. DBname .. "not found."
	else
		if loadedDatabases[DBname][tableName] == nil then
			--error here, table doesn't exist
			data = cobaltSysChar .. "E:" .. DBname .. " > " .. tableName .. " not found."
		else
			if loadedDatabases[DBname][tableName][key] == nil then
				data = cobaltSysChar .. "E:" .. DBname .. " > " .. tableName .. " > " .. key .. " not found."
			else
				--send the value as json
				data = json.stringify(loadedDatabases[DBname][tableName][key])
			end
		end
	end

	if dontusesocket then return data end

	data = requestID .. "[requestIDsplitter]" .. data
	connector:sendto(data ,"127.0.0.1", CobaltDBport)
	lastSent = data
end

--returns a read-only version of the table as json.
function getTable(DBname, tableName, requestID)
	local data

	if loadedDatabases[DBname] == nil then
		--error here, database isn't open
		data = cobaltSysChar .. "E:" .. DBname .. "not found."
	else
		if loadedDatabases[DBname][tableName] == nil then
			--error here, tableName doesn't exist
			data = cobaltSysChar .. "E:" .. DBname .. " > " .. tableName .. " not found."
		else
			--send the table as json
			data = json.stringify(loadedDatabases[DBname][tableName])
		end
	end

	if dontusesocket then return data end

	data = requestID .. "[requestIDsplitter]" .. data
	connector:sendto(data ,"127.0.0.1", CobaltDBport)
	lastSent = data
end

--returns a read-only list of all table names within the database
function getTables(DBname, requestID)
	local data = {}
	for id, _ in pairs(loadedDatabases[DBname]) do
		data[id] = id
	end

	data = json.stringify(data)

	if dontusesocket then return data end

	data = requestID .. "[requestIDsplitter]" .. data
	connector:sendto(data ,"127.0.0.1", CobaltDBport)
	lastSent = data
end

function getKeys(DBname, tableName, requestID)
	local data = {}
	for id, _ in pairs(loadedDatabases[DBname][tableName]) do
		data[id] = id
	end

	data = json.stringify(data)

	if dontusesocket then return data end

	data = requestID .. "[requestIDsplitter]" .. data
	connector:sendto(data ,"127.0.0.1", CobaltDBport)
	lastSent = data
end

function tableExists(DBname, tableName, requestID)
	local data = "E: database not open"

	if loadedDatabases[DBname] ~= nil and loadedDatabases[DBname][tableName] ~= nil then
		data = tableName
	end

	if dontusesocket then return data end

	data = requestID .. "[requestIDsplitter]" .. data
	connector:sendto(data ,"127.0.0.1", CobaltDBport)
	lastSent = data
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


----EVENTS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----


return M
