--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}
_G.SendChatMessageV = _G.SendChatMessage
_G.RemoveVehicleV = _G.RemoveVehicle
_G.GetPlayerVehiclesV = _G.GetPlayerVehicles

function split(s, sep)
	local fields = {}

	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
end

function RemoveVehicle(playerID, vehID)
	RemoveVehicleV(playerID,vehID)
	TriggerGlobalEvent("onVehicleDeleted", playerID, vehID)
end

function SendChatMessage(playerID, message)
	message = split(message ,"\n")

	for k,v in ipairs(message) do
		SendChatMessageV(playerID, v)
		Sleep(10)
	end
end

function GetPlayerVehicles(playerID)
	return CE.getPlayer(playerID).vehicles
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

local function copyFile(path_src, path_dst)
	local ltn12 = require("Resources/server/CobaltEssentials/socket/lua/ltn12")

	ltn12.pump.all(
		ltn12.source.file(assert(io.open(path_src, "rb"))),
		ltn12.sink.file(assert(io.open(path_dst, "wb")))
	)
end

local function parseVehData(data)
	local s, e = data:find('%[')

	data = data:sub(s)
	data = json.parse(data)

	data.serverVID = vehID
	data.clientVID = data[2]
	data.name = data[3]

	if data[4] ~= nil then
		data.info = json.parse(data[4])
	end

	return data
end

M.copyFile = copyFile
M.exists = exists
M.parseVehData = parseVehData

return M