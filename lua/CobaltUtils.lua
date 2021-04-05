--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}
_G.SendChatMessageV = _G.SendChatMessage
_G.RemoveVehicleV = _G.RemoveVehicle
_G.GetPlayerVehiclesV = _G.GetPlayerVehicles
_G.DropPlayerV = _G.DropPlayer
lastRandomNumber = os.time()

-------------------------------------------------REPLACED-GLOBAL-FUNCTIONS-------------------------------------------------
--Trigger the on VehicleDeleted event
function RemoveVehicle(playerID, vehID)
	RemoveVehicleV(playerID,vehID)
	TriggerGlobalEvent("onVehicleDeleted", playerID, vehID)
end

--Make sending multi-line chat messages with \n possible.
function SendChatMessage(playerID, message)
	message = split(message ,"\n")

	for k,v in ipairs(message) do
		SendChatMessageV(playerID, v)
		Sleep(10)
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
			out = out .. " [" .. logTypes[heading].headingColor .. heading .. color(0) .. "] " .. logTypes[heading].stringColor
		end
	else
		out = out .. " [" .. color(94) .. heading .. color(0) .. "] "
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
			TriggerGlobalEvent("RCONsend", ID, message)
		end
	
	elseif type(ID) == "number" then
		SendChatMessage(ID, message)
	else
		error("Invalid ID")
	end
end

local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
	  if code == 13 then
		 -- Permission denied, but it exists
		 return true
	  end
   end
   return ok, err
end

local function createDirectory(path)
	os.execute("mkdir " .. dbpath:gsub("/","\\"))
end

local function copyFile(path_src, path_dst)
	local ltn12 = require("Resources/server/CobaltEssentials/socket/lua/ltn12")

	ltn12.pump.all(
		ltn12.source.file(assert(io.open(path_src, "rb"))),
		ltn12.sink.file(assert(io.open(path_dst, "wb")))
	)
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

--read a .cfg file and return a table containing it's files
local function readCfg(path)

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

setLogType("WARN",31,false,31)
setLogType("RCON",33)
setLogType("CobaltDB",35)
setLogType("CHAT",32)

M.random = random
M.copyFile = copyFile
M.exists = exists
M.parseVehData = parseVehData

M.setLogType = setLogType
M.getLogTypes = getLogTypes

M.readCfg = readCfg

return M