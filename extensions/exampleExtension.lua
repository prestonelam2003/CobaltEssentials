local M = {}
M.COBALT_VERSION = "1.6.0"


local lastAnnounce = 0
local announceStep = 300000


--called whenever the extension is loaded
local function onInit()
	
end

--called once every tick
local function onTick(age)
	if age > lastAnnounce + announceStep then
		local output = "Uptime: " .. (lastAnnounce + announceStep)/60000 .. " Minutes"
		
		CElog(output)

		lastAnnounce = lastAnnounce + announceStep
	end
end


--called whenever a player is authenticated by the server for the first time.
local function onPlayerFirstAuth(player)
	
end


--called whenever the player is authenticated by the server.
local function onPlayerAuth(player)
	
end

--called whenever someone begins connecting to the server
local function onPlayerConnecting(player)
	
end

--called when a player begins loading
local function onPlayerJoining(player)
	
end

--called whenever a player has fully joined the session
local function onPlayerJoin(player)
	
end

--called whenever a player disconnects from the server
local function onPlayerDisconnect(player)
	
end


--called whenever a player sends a chat message
local function onChatMessage(player, chatMessage)
	
end

--called whenever a player spawns a vehicle.
local function onVehicleSpawn(player, vehID,  data)

end

--called whenever a player applies their vehicle edits.
local function onVehicleEdited(player, vehID,  data)
	
end

--called whenever a player resets their vehicle, holding insert spams this function.
local function onVehicleReset(player, vehID, data)
	
end

--called whenever a vehicle is deleted
local function onVehicleDeleted(player, vehID,  source)
	
end

--whenever a message is sent to the Rcon
local function onRconCommand(player, message, password, prefix)
	
end

--whenever a new client interacts with the RCON
local function onNewRconClient(client)
	
end

--called when the server is stopped through the stopServer() function
local function onStopServer()
	
end


M.onInit = onInit
M.onTick = onTick

M.onPlayerFirstAuth = onPlayerFirstAuth

M.onPlayerAuth = onPlayerAuth
M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect

M.onChatMessage = onChatMessage

M.onVehicleSpawn = onVehicleSpawn
M.onVehicleEdited = onVehicleEdited
M.onVehicleReset = onVehicleReset
M.onVehicleDeleted = onVehicleDeleted

M.onRconCommand = onRconCommand
M.onNewRconClient = onNewRconClient

M.onStopServer = onStopServer

return M