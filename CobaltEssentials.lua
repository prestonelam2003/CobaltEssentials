--Created by Preston Elam (CobaltTetra) 2020
--THIS COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE
--FURTHERMORE YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )
--local config = require("CobaltEssentials\\CobaltConfig")
--local config = require("Resources/server/CobaltEssentials/CobaltConfig")
local config = require("Resources/server/CobaltEssentials/CobaltConfig")

----VARIABLES----


local M = {}

local commands = {}

--TODO: try to come up with a way to combine banlist, whitelist and registeredUsers in a way that keeps everything efficent (even if it's not nessesary) & makes things a little cleaner but not confusing.

--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
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
--whitelist.enabled = true --The default state of the whitelist.


----------------------------------------------------------EVENTS-----------------------------------------------------------

function onInit()
	config = require("Resources/server/CobaltEssentials/CobaltConfig")

	print("CobaltEssentials Initiating...")

	RegisterEvent("onPlayerJoin","onPlayerJoin")
	RegisterEvent("onPlayerConnecting","onPlayerConnecting")
	RegisterEvent("onPlayerJoining","onPlayerJoining")
	RegisterEvent("onChatMessage","onChatMessage")
	RegisterEvent("onVehicleSpawn","onVehicleSpawn")
	RegisterEvent("onPlayerDisconnect","onPlayerDisconnect")

	print("CobaltEssentials Initiated")
end

function onPlayerJoin(ID)
	print("On Player Join")
end

function onPlayerConnecting(ID)
	print("On Player Connecting")
	local player = M.getPlayer(ID)
	
	if player.banned then
		DropPlayer(ID , "You are banned from this server!")
	else
		if not player.whitelisted then
			DropPlayer(ID, "You are not whitelisted on this server!")
		else
			players[ID] = player
		end
	end
end

function onPlayerJoining(ID)
	print("On Player Joining")

end

function onChatMessage(playerID, chatMessage)
	print("On Chat Message")
		
	--check to see if it is a command
	if chatMessage:sub(1,1) == config.options.commandPrefix then
		
		--reformat the chat message.
		chatMessage = chatMessage:sub(2):split(" ")

		--get the command and args from the chat message.
		local command = chatMessage[1]
		local args = chatMessage:remove(1)

		--run the command and react accordingly
		print("trying to execute command")
		M.command(playerID, command, args) --TODO: react accordingly

		--make the chat message not appear in chat.
		return 1
	else

	end
end

local function onPlayerDisconnect()
	print("On Player Disconnect")
end


function onVehicleSpawn(ID, data)
	print("On Vehicle Spawn")
	if M.hasPermission(ID, "spawnVehicles") == false then
		--cancelEvent() --TODO: UPDATE, CANCEL EVENT WILL NOT EXIST IN THE FINAL VERSION
		return 1
	end
end



--  TODO: figure out a way to smoothly implement a dynamic vehicle cap per player.
--MAYBE?: via an optional value for "permission flags"?


----------------------------------------------------------MUTATORS---------------------------------------------------------


local function registerUser(identifier,IDtype,permissionLevel,specialPerms)
	registeredUsers[IDtype][identifier] = {}
	registeredUsers[IDtype][identifier].perm = permissionLevel
	registeredUsers[IDtype][identifier].special = specialPerms
end



--POST: set the permisson requirement for the "flag" optional value for things like car count
local function setPermission(permission, reqPerm, value)
	permsissions[permission] = {}
	permsissions[permission].reqPerm = reqPerm
end 

-- PRE: a command name, function and the required permission level is passed in.
--POST: the command is added to the commands table.
local function registerCommand(command, func, reqPerm)
	commands[command] = {}
	commands[command].func = func
	commands[command].reqPerm = reqPerm
end

--POST: adds a player to the whitelist for this session
local function addWhitelist(identifier, IDtype)
	whitelist[IDtype][identifier] = true
end

--POST: removes a player from the whitelist for this session
local function removeWhitelist(identifier, IDtype)
	whitelist[IDtype][identifier] = nil
end

--POST: set the whitelist as enabled or disabled (true/false) if nil or invalid, the value will toggle.
local function setWhitelistEnabled(enabled)
	if config.options then
		if not enabled  then
			config.options.enableWhitelist = not config.options.enableWhitelist
		else
			enabled = enabled == true or false
	
			config.options.enableWhitelist = enabled
		end
	end
end

--POST: bans a player from this session
local function ban(identifier, IDtype)
	banlist[IDtype][identifier] = true
end

--POST: unbans a player from this session
local function unban(identifier, IDtype)
	banlist[IDtype][identifier] = nil
end



---------------------------------------------------------ACCESSORS---------------------------------------------------------

-- PRE: Takes in the serverID of a player
--POST: returns a complete table on the player.
local function getPlayer(serverID)
	local player = {}
	player.serverID = serverID
	player.discordID = GetPlayerDiscordID(serverID)
	player.HWID = GetPlayerHWID(serverID)
	player.name = GetPlayerName(serverID)
	player[1] = player.discordID
	player[2] = player.HWID
	player[3] = player.name


	player.whitelisted = not whitelist.enabled --stuff related to banlist and whitelist is a little complicated might decide to rewrite for clarity/readability just wanted to keep it compact.
	player.banned = false
	player.perms = 0
	for k,v in ipairs(player) do
		player.whitelisted = player.whitelisted == true or (whitelist[k][ tonumber(v) ]  or false)
		player.banned = player.banned == true or (banlist[k][ tonumber(v) ] or false)
		player.perms = ((registeredUsers[k][ tonumber(v) ] or 0) > player.perms) and registeredUsers[k][ tonumber(v) ] or player.perms --takes the highest level perms availible
	end

	return player
end


--     PRE: the identifier is passed in along with type, type dictates the type of identifier that is being passed in.
--TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
-- RETURNS: the serverID of said player, will return -1 if no one is found
local function getServerID(identifier, IDtype)
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


-- PRE: a valid serverID and permission "flag" are both passed in.
--POST: returns true or false based on if the player with the provided serverID has access to this permission
local function hasPermission(serverID, permission)
	return (players[serverID].perm >= permsissions[permission].reqPerm) or true
end



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

-- PRE: a valid command is passed in along with args
--POST: the command is ran, any return info is passed back from the original function
local function command(ID, command, args)
	if commands[command] then
		
		print("Executing command")

		if players[ID].perms >= commands[command].reqPerm then
			return command.func(args)
		else
			return 0
		end

	else
		print("Insufficent Perms")
		return -1

	end

end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

----EVENTS----
--M.onPlayerJoin = onPlayerJoin
--M.onPlayerConnecting = onPlayerConnecting
--M.onPlayerJoining = onPlayerJoining
--M.onChatMessage = onChatMessage
--M.onVehicleSpawn = M.onVehicleSpawn

----MUTATORS----
M.addPlayer = addPlayer
M.registerUser = registerUser
M.setPermission = setPermission
M.registerCommand = registerCommand
M.addWhitelist = addWhitelist
M.setWhitelistEnabled = setWhitelistEnabled
M.ban = ban
M.unban = unban

----ACCESSORS----
M.getPlayer = getPlayer
M.getServerID = getServerID
M.hasPermission = hasPermission

----FUNCTIONS----
M.command = command

return M

