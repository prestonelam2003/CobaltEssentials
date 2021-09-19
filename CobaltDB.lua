--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

--TODO: CHANGE THE FORMAT TO DATABASES > TABLES > KEYS > VALUES

local M = {}

local loadedDatabases = {}
local loadedJson = {}

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
	socket = require("socket")
	utils = require("CobaltUtils")

	_G.dbpath = pluginPath .. "/CobaltDB/"

	local jsonFile, error = io.open(dbpath .."config.json")
	if error == nil then
		CobaltDBport = tonumber(json.parse(jsonFile:read("*a")).CobaltDBport.value)
		jsonFile:close()
	end

	CElog("CobaltDB Initiated","CobaltDB")
	MP.TriggerLocalEvent("onCobaltDBhandshake",CobaltDBport)

	connector = socket.udp()
end
----------------------------------------------------------MUTATORS---------------------------------------------------------

function openDatabase(DBname, requestID)
	local jsonPath = dbpath .. DBname .. ".json"

	local jsonFile, error = io.open(jsonPath,"r")
	--CElog(jsonFile, error)

	local databaseLoaderInfo = "loaded" -- defines if the DB was created just now or if it was pre-existing.

	if jsonFile == nil then
		databaseLoaderInfo = "new"
		CElog("JSON file does not exist, creating a new one.","CobaltDB")
		--CElog(jsonFile, error)
		jsonFile, error = io.open(jsonPath, "w")
		local openAttempts = 1
		if error then
			print(error)
			--os.execute("mkdir " .. dbpath:gsub("/","\\") .. "\\playersDB")
			local subfolders = split(DBname,"/")

			local path = ""
			for index,subfolder in pairs(subfolders) do
					if index < #subfolders then
					path = path .. "/" ..  subfolder
					os.execute("mkdir " .. dbpath:gsub("/","\\") .. path:gsub("/","\\"))

					CElog('Folder created at: "' .. path ..'"')
				end
			end
			--while error and openAttempts < 5 do
				jsonFile, error = io.open(jsonPath, "w")
				--openAttempts = openAttempts + 1
			--end
		end
		--if error then
			--connector:sendto("E:" .. error ,"127.0.0.1", CobaltDBport)
			--return false
		--end

		jsonFile:write("{}")
		jsonFile:close()
		jsonFile, error = io.open(jsonPath,"r")
		loadedJson[DBname] = "{}"
		loadedDatabases[DBname] = {}
	else
		local jsonText = jsonFile:read("*a")

		loadedJson[DBname] = jsonText
		loadedDatabases[DBname] = json.parse(jsonText)

		jsonFile:close()
	end

	if dontusesocket then return databaseLoaderInfo end

	databaseLoaderInfo = requestID .. "[requestIDsplitter]" .. databaseLoaderInfo
	connector:sendto(databaseLoaderInfo ,"127.0.0.1", CobaltDBport)
	lastSent = databaseLoaderInfo
end

function closeDatabase(DBname)
	updateDatabase(DBname)

	loadedJson[DBname] = nil
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
	--update current json
	loadedJson[DBname] = json.stringify(loadedDatabases[DBname])

	--write table
	local filePath = dbpath .. DBname
	local jsonFile, error = io.open(filePath .. ".temp","w")
	jsonFile:write(loadedJson[DBname])
	jsonFile:close()
	os.remove(filePath .. ".json")
	os.rename(filePath .. ".temp", filePath .. ".json")
	--CElog("Updated: '" .. dbpath .. DBname .. ".json'","DEBUG")
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
