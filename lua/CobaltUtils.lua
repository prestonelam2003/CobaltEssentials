--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}
_G.MP.SendChatMessageV = _G.MP.SendChatMessage
_G.RemoveVehicleV = _G.RemoveVehicle
_G.GetPlayerVehiclesV = _G.GetPlayerVehicles
_G.DropPlayerV = _G.DropPlayer
lastRandomNumber = os.time()

-------------------------------------------------REPLACED-GLOBAL-FUNCTIONS-------------------------------------------------
--Trigger the on VehicleDeleted event
function RemoveVehicle(playerID, vehID)
	RemoveVehicleV(playerID,vehID)
	MP.TriggerGlobalEvent("onVehicleDeleted", playerID, vehID)
end

--Make sending multi-line chat messages with \n possible.
function MP.SendChatMessage(playerID, message)
	message = split(message ,"\n")

	for k,v in ipairs(message) do
		MP.SendChatMessageV(playerID, v)
		MP.Sleep(10)
	end
end

--make GetPlayerVehicles actually work.
function GetPlayerVehicles(playerID)
	return players[playerID].vehicles
end

function DropPlayer(playerID, reason)
	if players[playerID] ~= nil then
		players[playerID].dropReason = reason
	end
	DropPlayerV(playerID, reason)
end
---------------------------------------------------------------------------------------------------------------------------

local logTypes = {}

function CElog(string, heading, debug)
	heading = heading or "Cobalt"
	debug = debug or false

	--local out = ("[" .. os.date("%d/%m/%Y %X", os.time())):gsub("/0","/"):gsub("%[0","["):gsub("%[","[" .. color(90)) .. color(0) ..  "]"
	local out = ""

	if logTypes[heading] then
		if logTypes[heading].conditonFunc == nil or logTypes[heading].conditonFunc() then
			out = out .. "[" .. logTypes[heading].headingColor .. heading .. color(0) .. "] " .. logTypes[heading].stringColor
		end
	else
		out = out .. "[" .. color(94) .. heading .. color(0) .. "] "
	end

	out = out .. string .. color(0)

	--if heading == "WARN" then
	--	out =  out .. " [" .. color(31) .. "WARN" .. color(0) .. "] " .. color(31) .. string
	--elseif heading == "RCON" then
	--	out = out .. " [" .. color(33) .. "RCON" .. color(0) .. "] " .. color(0) .. string
	--elseif heading == "CobaltDB" then
	--	out = out .. " [" .. color(35) .. "CobaltDB" .. color(0) .. "] " .. color(0) .. string
	--elseif heading == "CHAT" then
	--	out = out .. " [" .. color(32) .. "CHAT" .. color(0) .. "] " .. color(0) .. string
	----elseif heading == "DEBUG" and ((config == nil or config.enableDebug.value == true) or (query and CobaltDB.query("config","enableDebug","value") == true)) or true then
	--elseif heading == "DEBUG" then
	--	if config == nil or config.enableDebug.value == true) or (query and CobaltDB.query("config","enableDebug","value") == true)) or true then
	--		out = out .. " [" .. color(97) .. "DEBUG" .. color(0) .. "] " .. color(0) .. string
	--	end
	--else
	--	out = out .. " [" .. color(94) .. heading .. color(0) .. "] " .. color(0) .. string
	--end


	print(out)
	return out
end

local function setLogType(heading, headingColor, conditonFunc, stringColor)
	headingColor = headingColor or 94
	stringColor = stringColor or 0
	logTypes[heading] = {}
	
	logTypes[heading].headingColor = color(headingColor)
	logTypes[heading].stringColor = color(stringColor)

	if conditonFunc then
		logTypes[heading].conditonFunc = conditonFunc
	end
end

local function getLogTypes()
	return logTypes
end

--changes the color of the console.
function color(fg,bg)
	--if (config == nil or config.enableColors.value == true) and true then
	if true then
		if bg then
			return string.char(27) .. '[' .. tostring(fg) .. ';' .. tostring(bg) .. 'm'
		else
			return string.char(27) .. '[' .. tostring(fg) .. 'm'
		end
	else
		return ""
	end
end

function split(s, sep)
	local fields = {}

	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
end

--PRE: ID is passed in, representing a player ID, an RCON ID, or C to print into console with message, a valid string.
--POST: message is output to the desired destination, if sent to players \n is seperated.

--IDs | "C" = console | "R<N>" = RCON | "<number>" = player
function output(ID, message)
	if ID == nil then
		error("ID is nil")
	end
	if message == nil then
		error("message is nil")	
	end

	if type(ID) == "string" then

		if ID == "C" then
			CElog(message)
		elseif ID:sub(1,1) == "R" then
			MP.TriggerGlobalEvent("RCONsend", ID, message)
		end
	
	elseif type(ID) == "number" then
		MP.SendChatMessage(ID, message)
	else
		error("Invalid ID")
	end
end

local function parseVehData(data)
	local s, e = data:find('%{')

	data = data:sub(s)

	local sucessful, tempData = pcall(json.parse, data)
	if not sucessful then
		--TODO: BACKUP THE JSON IN A FILE. tempData is the error, data is the json.
		return false
	end
	data = tempData


	data.serverVID = vehID
	data.clientVID = data.VID
	data.name = data.jbm
	data.cfg = data.vcf


	if data[4] ~= nil then
		local sucessful, tempData = pcall(json.parse, data[4])
		if not sucessful then
			--TODO: BACKUP THE JSON IN A FILE. tempData is the error, data is the json.
			return false
		end
		data.info = tempData 
	end

	return data
end

--DEPRECATED
--read a .cfg file and return a table containing it's files
local function readOldCfg(path)

	local cfg = {}
	
	local n = 1

	local file = io.open(path,"r")

	local line = file:read("*l") --get first value for line
	while line ~= nil do

		--remove comments
		local c = line:find("#")

		if c ~= nil then
			line = line:sub(1,c-1)
		end

		--see if this line even contians a value
		local equalSignIndex = line:find("=")
		if equalSignIndex ~= nil then
			
			local k = line:sub(1, equalSignIndex - 1)
			k = k:gsub(" ", "") --remove spaces in the key, they aren't required and will serve to make thigns more confusing.

			local v = line:sub(equalSignIndex + 1)

			v = load("return " ..  v)()
			
			cfg[k] = v
		end


		--get next line ready
		line = file:read("*line")
	end

	if cfg.Name then
		cfg.rawName = cfg.Name
		local s,e = cfg.Name:find("%^")
		while s ~= nil do

			if s ~= nil then
				cfg.Name = cfg.Name:sub(0,s-1) .. cfg.Name:sub(s+2)
			end
		
			s,e = cfg.Name:find("%^")
		end
	end

	return cfg
end

--read a TOML file and return a table containing it's files
--doSubtables is a boolean that dictates if the section titles used in TOML should contribute to their own subtable or if everything should go in one table.
	--doSubtables = false: contents of TOML catagories are not placed into their own subtable
	--doSubtables = true: contents of TOML catagories are placed into their own subtable
--includeComments: Dictates how comments are dealt with.
	--includeComments = -1: Comments are entirely ignored
	--includeComments = 0: Comments not placed in the main table
	--includeComments = 1: Comments are placed in a comments subtable.
local function readCfg(path,doSubtables, includeComments)
	--set default values
	doSubtables = doSubtables or false
	includeComments = (includeComments and includeComments >= -1 and includeComments <= 1) or 0

	local cfg = {}
	local comments = {}
	local lineNumber = 1
	local catagory = nil
	local currentTable = cfg

	local file = io.open(path,"r")

	--loop through all the lines
	local line = file:read("*l") --get first value for line
	while line ~= nil do
		
		--Comments
		local c = line:find("#")
		if c ~= nil then
			if includeComments ~= -1 then
				local comment = line:sub(c+1)
				if includeComments == 1 then
					currentTable.comments = currentTable.comments or {} --set default

					currentTable.comments[lineNumber] = comment --add to comments subtable
				end

				comments[lineNumber] = comment --add to main comments table
			end
			line = line:sub(1,c-1)
		end

		--Catagories/Subtables
		local tempCatagory = line:find("%[")
		if tempCatagory ~= nil then
			if doSubtables then
				catagory = line:sub(tempCatagory + 1, line:len() - 1)

				cfg[catagory] = cfg[catagory] or {} -- set default

				currentTable = cfg[catagory]
			end
		end

		--see if this line even contians a value
		local equalSignIndex = line:find("=")
		if equalSignIndex ~= nil then
			
			local k = line:sub(1, equalSignIndex - 1)
			k = k:gsub(" ", "") --remove spaces in the key, they aren't required and will serve to make thigns more confusing.

			local v = line:sub(equalSignIndex + 1)

			v = load("return " ..  v)()
			
			currentTable[k] = v
		end


		--get next line ready
		line = file:read("*line")
		lineNumber = lineNumber + 1 --increment lineNumber
	end


	if currentTable.Name then
		cfg.rawName = cfg.Name
		local s,e = cfg.Name:find("%^")
		while s ~= nil do

			if s ~= nil then
				cfg.Name = cfg.Name:sub(0,s-1) .. cfg.Name:sub(s+2)
			end
		
			s,e = cfg.Name:find("%^")
		end
	end

	return cfg, comments
end

-- PRE: number, time in seconds is passed in, followed by boolean hours, boolean minutes, boolean seconds, boolean milliseconds.
--POST: the formatted time is output as a string.
function formatTime(time)
	time = math.floor((time * 1000) + 0.5)
	local milliseconds = time % 1000
	time = math.floor(time/1000)
	local seconds = time % 60
	time = math.floor(time/60)
	if seconds < 10 then
		seconds = "0" .. seconds
	end
	if time < 10 then
		time = "0" .. time
	end
	if milliseconds < 10 then
		milliseconds = "00" .. milliseconds
	elseif milliseconds < 100 then
		milliseconds = "0" .. milliseconds
	end

	return  time ..":".. seconds .. ":" .. milliseconds
end

--linear congruential generator
randomNumberGeneratorA = 1103515245
randomNumberGeneratorC = 12345
randomNumberGeneratorM = 2^31
local function random(upper,lower)
	upper = upper or 1
	lower = lower or 0
	lastRandomNumber = ((lastRandomNumber * randomNumberGeneratorA + randomNumberGeneratorC) % randomNumberGeneratorM)
	--CElog("Random Number:" .. (lastRandomNumber/ randomNumberGeneratorM),"DEBUG")

	local randomOutput = lastRandomNumber / randomNumberGeneratorM --This shouldn't actually be used for upper and lowers, this is just a correction on the 0-1 value
	--if randomOutput < lower then randomOutput = lower end
	--if randomOutput > upper then randomOutput = upper end

	return randomOutput
end

function formatVersionAsTable(versionString)
	local version = {}
	local tag = "[Release]"

	local s, e = versionString:find("%[")
	if s then
		tag = versionString:sub(s)
		versionString = versionString:sub(1,s-2)
		s, e = versionString:find("%]")
		tag = tag:sub(1,s)

	end
	
	print("'".. tag .."'")
	version = split(versionString,".")
	
	return version, tag
end

--RETURNS TRUE IF VER1 IS NEWER THAN vER2
function compareCobaltVersion(ver1,ver2)
	
	local ver1strength = 0
	local ver2strength = 0
	
	if type(ver1) == "string" then
		ver1 = formatVersionAsTable(ver1)
	end
	if type(ver2) == "string" then
		ver2 = formatVersionAsTable(ver2)
	end

	for key,version in pairs(ver1) do
		local strengthChange = 1/(key^10) * tonumber(version)
		ver1strength = ver1strength + strengthChange
		--print(version .. ":" .. strengthChange)
	end
	--print("------------" .. ver1strength)
	for key,version in pairs(ver2) do
		local strengthChange = 1/(key^10) * tonumber(version)
		ver2strength = ver2strength + strengthChange
		--print(version .. ":" .. strengthChange)
	end
	--print("------------" .. ver2strength)
	--print(ver1strength > ver2strength)
	--print("------------")
	return ver1strength > ver2strength
end


-- FS related functions
local function readJson(path)
	if not FS.Exists(path) then
		return nil, "File does not exist"
	end

	local jsonFile, error = io.open(path,"r")
	if not jsonFile or error then
		return nil, error
	end

	local jsonText = jsonFile:read("*a")
	jsonFile:close()
	local success, data = pcall(json.parse, jsonText)

	if not success then
		print("Error while parsing file", path, data)
		return nil, "Error while parsing JSON"
	end

	return data, nil
end

local function writeJson(path, data)
	local success, error = FS.CreateDirectory(FS.GetParentFolder(path))

	if not success then
		CElog('failed to create directory for file "' .. tostring(path) .. '", error: ' .. tostring(error),"WARN")
		return false, error
	end

	local jsonFile, error = io.open(path,"w")
	if not jsonFile or error then
		return nil, error
	end

	jsonFile:write(json.stringify(data or {}))
	jsonFile:close()

	return true, nil
end

local function copyFile(path_src, path_dst)
	local ltn12 = require("Resources/server/CobaltEssentials/socket/lua/ltn12")

	ltn12.pump.all(
		ltn12.source.file(assert(io.open(path_src, "rb"))),
		ltn12.sink.file(assert(io.open(path_dst, "wb")))
	)
end
-- FS related functions



setLogType("WARN",31,false,31)
setLogType("RCON",33)
setLogType("CobaltDB",35)
setLogType("CHAT",32)

M.random = random
M.parseVehData = parseVehData

M.setLogType = setLogType
M.getLogTypes = getLogTypes

M.readOldCfg = readOldCfg
M.readCfg = readCfg

M.readJson = readJson
M.writeJson = writeJson

M.copyFile = copyFile

return M
