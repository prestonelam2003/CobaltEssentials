--Created by Preston Elam (CobaltTetra) 2020
--THIS COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE
--FURTHERMORE YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )

----VARIABLES----
local executionPath = arg[0]


local M = {}

----TABLES----
local options = {}
local commands = {}

local banlist = {}
      banlist[1] = {}
	  banlist[2] = {}
	  banlist[3] = {}

local whitelist = {}
      whitelist[1] = {}
	  whitelist[2] = {}
	  whitelist[3] = {}

local registeredUsers = {}
	  registeredUsers[1] = {}
	  registeredUsers[2] = {}
	  registeredUsers[3] = {}

local players = {}
local permsissions = {}

--OPTIONS--
whitelist.enabled = true --The default state of the whitelist.



----------------------------------------------------------EVENTS-----------------------------------------------------------

local function onInit()
	RegisterEvent("onPlayerJoin","onPlayerJoin")
	RegisterEvent("onPlayerConnecting","onPlayerConnecting")
	RegisterEvent("onPlayerJoining","onPlayerJoining")
	RegisterEvent("onChatMessage","onChatMessage")
	RegisterEvent("onVehicleSpawn","onVehicleSpawn")
	print("Test1")
	print("Test2:" .. arg[0])
	print("Test3:" .. executionPath)

end

local function onPlayerJoin(ID)
	M.addPlayer(ID)
end

local function onPlayerConnecting(ID)
	
end

local function onPlayerJoining(ID)

end

local function onChatMessage(playerID, chatMessage)
	
end

local function onVehicleSpawn(ID, data)
	
end





----------------------------------------------------------MUTATORS---------------------------------------------------------

-- PRE: Takes in the serverID of a player
--POST: adds that player entirely to the server player list.
local function addPlayer(serverID)
	local player = {}
	player.serverID = ID
	player.discordID = GetPlayerDiscordID(ID)
	player.HWID = GetPlayerHWID(ID)
	player.name = GetPlayerName(ID)
	player.perm = 0 --TODO: CREATE A WAY TO EVLAUATE PERMISSION LEVEL/ID
	players[serverID] = player
end


local function registerUser(identifier,IDtype,permissionLevel,specialPerms)
	registeredUsers[IDtype][identifier] = {}
	registeredUsers[IDtype][identifier].perm = permissionLevel
	registeredUsers[IDtype][identifier].special = specialPerms
end


local function setPermission(permission, reqPerm)
	permsissions[permission] = reqPerm
end 

-- PRE: a command name, function and the required permission level is passed in.
--POST: the command is added to the commands table.
local function registerCommand(command, func, reqPerm)
	commands[command] = {}
	commands[command].func = func
	commands[command].reqPerm = reqPerm
end

local function addWhitelist(identifier,IDtype)
	whitelist.players[IDtype][identifier] = identifier
end

local function setWhitelistEnabled(enabled)
	whitelist.enabled = enabled
end

local function ban(identifier IDtype)
	banlist[IDtype][identifier]
end

local function unban(identifier IDtype)
	
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------

--     PRE: the identifier is passed in along with type, type dictates the type of identifier that is being passed in.
--TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
-- RETURNS: the serverID of said player, will return -1 if no one is found
local getServerID(identifier, IDtype)
	local serverID = -1

	for ID,Name in pairs(GetPlayers()) do
		
		--TYPE = 1
		if type == 1 and GetPlayerDiscordID(ID) == identifier then
			serverID = ID
		end
		
		--TYPE = 2
		if type == 2 and GetPlayerHWID(ID) == identifier then
			serverID = ID
		end
		
		--TYPE = 3
		if type == 3 and name == identifier then
			serverID = ID
		end

	end

	return serverID
end



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

-- PRE: a valid command is passed in along with args
--POST: the command is ran, any return info is passed back from the original function
local function command(ID, command, args)
	if players[ID].perms >= commands[command].reqPerm then
		command.func(args)
	else
		return(-1)
	end

end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

----EVENTS----
M.onInit = onInit
M.onPlayerJoin = onPlayerJoin
M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onChatMessage = onChatMessage
M.onVehicleSpawn = M.onVehicleSpawn

----MUTATORS----
M.addPlayer = addPlayer
M.registerCommand = registerCommand
M.registerUser = registerUser

----ACCESSORS----
m.getServerID = getServerID

----FUNCTIONS----

return M

