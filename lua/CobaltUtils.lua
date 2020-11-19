--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}
_G.SendChatMessageV = _G.SendChatMessage
_G.RemoveVehicleV = _G.RemoveVehicle
_G.GetPlayerVehiclesV = _G.GetPlayerVehicles
_G.DropPlayerV = _G.DropPlayer

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
			print(message)
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

M.copyFile = copyFile
M.exists = exists
M.parseVehData = parseVehData

M.readCfg = readCfg

return M