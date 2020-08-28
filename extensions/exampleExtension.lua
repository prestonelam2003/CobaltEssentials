local M = {}

local lastAnnounce = 0
local announceStep = 300000

--called whenever the extension is loaded
local function onInit()
	
end

--called once every tick
local function onTick(age)
	if age > lastAnnounce + announceStep then
		local output = "Uptime: " .. (lastAnnounce + announceStep)/300000 .. " Minutes"
		
		print(output)

		lastAnnounce = lastAnnounce + announceStep
	end
end

--called whenever someone begins connecting to the server
local function onPlayerConnecting(ID)
	
end

--called when a player begins loading
local function onPlayerJoining(ID)
	
end

--called whenever a player has fully joined the session
local function onPlayerJoin(ID)
	
end

--called whenever a player disconnects from the server
local function onPlayerDisconnect(ID)
	
end

--called whenever a player sends a chat message
local function onChatMessage(playerID, name ,chatMessage)
	
end

--called whenever a player spawns a vehicle.
local function onVehicleSpawn(ID, vehID,  data)

end

--called whenever a player applies their vehicle edits.
local function onVehicleEdited(ID, vehID,  data)
	
end

--called whenever a vehicle is deleted
local function onVehicleDeleted(ID, vehID,  data)
	
end

--whenever a message is sent to the Rcon
local function onRconCommand(ID, message, password, prefix)
	
end

--whenever a new client interacts with the RCON
local function onNewRconClient(client)
	
end

M.onInit = onInit
M.onTick = onTick

M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect

M.onChatMessage = onChatMessage

M.onVehicleSpawn = onVehicleSpawn
M.onVehicleEdited = onVehicleEdited
M.onVehicleDeleted = onVehicleDeleted

M.onRconCommand = onRconCommand
M.onNewRconClient = onNewRconClient

return M