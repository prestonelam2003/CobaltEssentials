--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )

----VARIABLES----


local M = {}

--local commands = {}

--local options = {}


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

local registeredVehicles = {}

--players = {}
--local permissions = {}

rconClients = {} --RCON clients start with an R[ID]
--local lastContact = 0


age = 0 --age of the server in milliseconds
--local ticks = 0
delayedQueue = {n = 0}

RegisterEvent("onTick","onTick")

RegisterEvent("onPlayerConnecting","onPlayerConnecting")
RegisterEvent("onPlayerJoining","onPlayerJoining")
RegisterEvent("onPlayerJoin","onPlayerJoin")
RegisterEvent("onPlayerDisconnect","onPlayerDisconnect")
	
RegisterEvent("onChatMessage","onChatMessage")

RegisterEvent("onVehicleSpawn","onVehicleSpawn")
RegisterEvent("onVehicleEdited","onVehicleEdited")
RegisterEvent("onVehicleDeleted","onVehicleDeleted")

RegisterEvent("onRconCommand","onRconCommand")
RegisterEvent("onNewRconClient","onNewRconClient")

print("CobaltEssentials Initiated")

----------------------------------------------------------EVENTS-----------------------------------------------------------

function onTick()

	age = os.clock() * 1000

	for k,v in pairs(delayedQueue) do
		if k ~= "n" and v.complete == false and age >= v.execTime then
			
			v.complete = true

			v.func(table.unpack(v.args))

			delayedQueue[k] = nil
			delayedQueue.n = delayedQueue.n - 1
		end
	end

	for ID, client in pairs(rconClients) do
		if config.RCONkeepAliveTick.value ~= false and age > client.lastContact + config.RCONkeepAliveTick.value * 1000 then
			TriggerGlobalEvent("keepAlive", ID)
			client.lastContact = age
		end
	end

	if extensions.triggerEvent("onTick", age) == false then
		return -1
	end

	--ticks = ticks + 1

end

function onPlayerConnecting(ID)
	print("On Player Connecting: " .. ID)
	
	--players[ID] = M.getPlayer(ID)
	local player, canJoin, reason = players.new(ID)

	if extensions.triggerEvent("onPlayerConnecting", player) == false then
		DropPlayer(ID,"You've been kicked from the server!")	
	elseif canJoin == false then
		player:kick(reason)
	end

	players.updateQueue()
end

function onPlayerJoining(ID)

	print("On Player Joining: " .. ID)

	if extensions.triggerEvent("onPlayerJoining", players[ID]) == false then
		DropPlayer(ID,"You've been kicked from the server!")

	else
		
	end
end

function onPlayerJoin(ID)
	print("On Player Join: " .. ID)
	
	if extensions.triggerEvent("onPlayerJoin", players[ID]) == false then
		DropPlayer(ID,"You've been kicked from the server!")
	else
		SendChatMessage(-1, players[ID].name .. " joined the game")
	end

end

function onPlayerDisconnect(ID)
		
	extensions.triggerEvent("onPlayerDisconnect", players[ID]) --allow extensions to act first.

	if players[ID] then
		if players[ID].dropReason then
			print("On Player Disconnect: " .. ID .. " | Dropped for " .. players[ID].dropReason)
		else
			print("On Player Disconnect: " .. ID .. " | Disconnect")
		end

		players[ID] = nil
	else
		print("On Player Disconnect: " .. ID .. " | Left while Loading.")
	end

	players.updateQueue()
end


function onChatMessage(playerID, name ,chatMessage)
	chatMessage = chatMessage:sub(2)

	if extensions.triggerEvent("onChatMessage", players[ID], chatMessage) == false then
		return -1
	end


	if chatMessage:sub(1,1) == config.commandPrefix.value then
		print("Command")

		local command = split(chatMessage:sub(2)," ")[1]

		local args
		local s, e = chatMessage:find(' ')
		if s ~= nil then
			args = chatMessage:sub(s+1)
		end
		

		--get the command and args from the chat message.
		--local args = chatMessage
		--args[0] = playerID

		--run the command and react accordingly
		print("trying to execute command")
		
		local reply = M.command(players[playerID], command, args)
		if reply ~= nil then
			SendChatMessage(playerID, reply)
		end

		--make the chat message not appear in chat. 
		return 1
	else
			
	end
	
	if players[playerID].permissions.muted  == true or M.hasPermission(playerID, "sendMessage") == false then
		print("MUTED:[".. playerID .. "]" .. name .. " : " .. chatMessage)
		return 1
	end

	local formattedMessage = "[".. playerID .. "]" .. name .. " : " .. chatMessage
	print(formattedMessage)

	for rconID, rconClient in pairs(rconClients) do
		if rconClient.chat == true then
			TriggerGlobalEvent("RCONsend", rconID, formattedMessage) 
			rconClients[rconID].lastContact = age
		end
	end

end


function onVehicleSpawn(ID, vehID,  data)
	print("On Vehicle Spawn")
	
	data = utils.parseVehData(data)

	--for k,v in pairs(data) do print(tostring(k) .. ": " .. tostring(v)) end
	--for k,v in pairs(data.parts) do print(tostring(k) .. ": " .. tostring(v)) end

	if players[ID].canSpawn(players[ID], vehID, data) == false or extensions.triggerEvent("onVehicleSpawn", players[ID], vehID, data) == false then
		TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
		return 1
	end

	players[ID].vehicles[vehID] = data
	
	print("Spawn Sucessful")
end

function onVehicleEdited(ID, vehID,  data)
	print("On Vehicle Edit")

	data = utils.parseVehData(data)

	if extensions.triggerEvent("onVehicleEdited", players[ID], vehID, data) == false then
		TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
		return 1
	end

	players[ID].vehicles[vehID] = data

end

function onVehicleDeleted(ID, vehID)
	ID = tonumber(ID)
	vehID = tonumber(vehID)
	print("on Vehicle Delete")

	if extensions.triggerEvent("onVehicleDeleted", players[ID], vehID) == false then
		return 1
	end

	if players[ID].vehicles[vehID] then
		players[ID].vehicles[vehID] = nil
	end
end


function onRconCommand(ID, message, password, prefix)
	local reply


	print(rconClients[ID].ip .. " : " ..prefix .. " " .. password .. " " .. message)

	rconClients[ID].lastContact = age

	if password == config.RCONpassword.value then
		
		if extensions.triggerEvent("onRconCommand", ID, message, password, prefix) == false then
			return 1
		end

		local args
		local command = split(message," ")[1]
		local s, e = message:find(' ')
		if s ~= nil then
			args = message:sub(s+1)
		end
	
		if CobaltDB.tableExists("commands", command) then
			
			local reply = M.command(rconClients[ID], command, args)

			--print("RCON REPLIES WITH COMMAND REPLY")
			if reply ~= nil then
				TriggerGlobalEvent("RCONsend", ID, reply)
			end
		else
			--print("RCON REPLIES WITH BAD COMMAND")
			TriggerGlobalEvent("RCONsend", ID, "Unrecognized Command")
		end
	else
		--print("RCON REPLIES WITH BAD PASSWORD")
		TriggerGlobalEvent("RCONsend", ID, "Bad Password")
	end
end

function onNewRconClient(ID, ip, port)
	local client = {}

	client.ID = ID
	client.ip = ip
	client.port = port
	client.chat = false
	client.lastContact = age

	client.canExecute = function(client, command)
		return command.sourceLimited ~= 1
	end
	
	if extensions.triggerEvent("onNewRconClient", client) == false then
		return 1
	end

	rconClients[ID] = client
end

----------------------------------------------------------MUTATORS---------------------------------------------------------


local function registerUser(identifier, IDtype, permissionLevel, specialPerms) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.setPermission() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	print("Registered " .. identifier .. " as ID Type " .. IDtype .. " @" .. permissionLevel)

	registeredUsers[IDtype][identifier] = {}
	registeredUsers[IDtype][identifier].perms = permissionLevel
	--registeredUsers[IDtype][identifier].special = specialPerms
end



--POST: set the permission requirement for the "flag" optional value for things like car count
local function setPermission(permission, reqPerm, value) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.setPermission() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'permissions' database to edit it directly.")
	
	if value == nil then
		permissions[permission] = {}
		permissions[permission].multiValue = false
		permissions[permission].reqPerm = reqPerm
		print("Set " .. permission .. " permission @" .. reqPerm)

	else
		if permissions[permission] then
			permissions[permission].multiValue = true
			permissions[permission].reqPerm[reqPerm] = value
		else
			permissions[permission] = {}
			permissions[permission].reqPerm = {}
			permissions[permission].multiValue = true
			permissions[permission].reqPerm[reqPerm] = value

		end
		print("Set " .. permission ..":" .. value .." permission @" .. reqPerm)
	end
end 

-- PRE: a command name, function and the required permission level is passed in.
--POST: the command is added to the commands table.
local function registerCommand(command, func, reqPerm, desc, argCount, RCONonly) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.registerCommand() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'commands' database to edit it directly.")
	print("Registered " .. command .. " Command @" .. reqPerm)

	commands[command] = {}
	commands[command].func = func
	commands[command].reqPerm = reqPerm
	commands[command].desc = desc
	commands[command].argCount = argCount
	commands[command].RCONonly = RCONonly
end

local function registerVehicle(name, reqPerm) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.registerVehicle() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'vehicles' database to edit it directly.")
	print("Set " .. name .. " @" .. reqPerm)

	registeredVehicles[name] = {}
	registeredVehicles[name].reqPerm = reqPerm
end

--POST: adds a player to the whitelist for this session
local function addWhitelist(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.addWhitelist() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	print("Added " .. identifier .. " as ID Type " .. IDtype .. " to the whitelist" )
	whitelist[IDtype][identifier] = true
end

--POST: removes a player from the whitelist for this session
local function removeWhitelist(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.removeWhitelist() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	print("Removed " .. identifier .. " as ID Type " .. IDtype .. " from the whitelist" )

	whitelist[IDtype][identifier] = nil
end

--POST: set the whitelist as enabled or disabled (true/false) if nil or invalid, the value will toggle.
local function setWhitelistEnabled(enabled)
	print("CE.setWhitelistEnabled() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'config' database to edit it directly.")	

	if not enabled  then
		config.enableWhitelist.value = not config.enableWhitelist.value
	else
		enabled = enabled == true or false
		config.enableWhitelist.value = enabled
	end


	if config.enableWhitelist.value == enabled then
		print("Disabled Whitelist")
	else
		print("Enabled Whitelist")
	end
end

--POST: bans a player from this session
local function ban(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.ban() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	print("Banned " .. identifier .. " as ID Type " .. IDtype .. " from the server" )
	banlist[IDtype][identifier] = true
end

--POST: unbans a player from this session
local function unban(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.unban() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	print("Unbanned " .. identifier .. " as ID Type " .. IDtype .. " from the server" )
	banlist[IDtype][identifier] = nil
end

local function bumpQueue(spots)
	for k, v in ipairs(players) do
		-- Mode-Map [0:active, 1:inQueue 2:spectator]
		if v.mode == 1	then
			v.queue = v.queue - 1
		end
	end

	M.evaluateModes()
end

-- PRE: a valid playerID and a boolean state is passed in.
--POST: the player at players[playerID] is either muted or unmuted based on state.
local function setMuted(playerID, state)
	print("CE.setMuted() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")

	players[playerID].permissions.muted = state

	if state == true then
		SendChatMessage(playerID, "You've been muted")
		print("muted " .. playerID)
	else
		SendChatMessage(playerID, "You've been unmuted")
		print("unmuted " .. playerID)
	end

end

--    PRE: delay in milliseconds, a valid function, and args containing valid args for func are passed in.
--   POST: the delayedItem is added, after delay, func(table.unpack(args)) is executed.
--RETURNS: returns delayedItem, you can check if an item has been completed with the boolean delayedItem.complete
local function delayExec(delay, func, args)

	local delayedItem = {}

	delayedItem.execTime = age + delay --the time at which the func is called with args args
	delayedItem.func = func --the function that is executed
	delayedItem.args = args --the args to execute func with.
	delayedItem.complete = false

	delayedQueue.n = delayedQueue.n + 1 --increment delayedQueue.n
	delayedQueue[delayedQueue.n] = delayedItem --record

	return delayedItem
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------

-- PRE: Takes in the serverID of a player
--POST: returns a complete table on the player.
local function getPlayer(serverID) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	print("CE.getPlayer() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. Please use players.new() instead.")
	if players[serverID] ~= nil then
		return players[serverID]
	else
		local player = {}
		player.serverID = serverID
		player.discordID = GetPlayerDiscordID(serverID)
		player.HWID = GetPlayerHWID(serverID)
		player.name = GetPlayerName(serverID)

		--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
		player[1] = player.discordID
		player[2] = player.HWID
		player[3] = player.name

		player.permissions = CobaltPermissions.getPlayerPermissions(player.discordID)

		--local playerPerms = CobaltPermissions.getPlayerPermissions(player.discordID)
		--player.permissions = {}
		--playerPerms.whitelisted = playerPerms.whitelisted == 1
		--playerPerms.banned = playerPerms.banned == 1
		--for k,v in pairs(playerPerms) do
			--player.permissions[k] = v
		--end

		--print a new player in chat
		local playerString = "\n" .. player.serverID .. ":" .. player.name .. " @".. player.permissions.level .. "\n"

		for k,v in pairs(player) do
			if not (k == 1 or k == 2 or k == 3 or k == "permissions") then
				playerString = playerString .. "\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			end
		end
		playerString = playerString .. "\tPermissions\n"
		for k,v in pairs(player.permissions) do
			playerString = playerString .. "\t\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
		end
		print(playerString)

		--info that changes
		--player.permissions.muted = false


		print("playerCount:" .. GetPlayerCount())

		--TODO: work out a more friendly way to handle activePerms vs permissions.level with everything else
		------GAMEMODE------
		--setup if the player is a spectator and the queue if they are.
		
		player.gamemode = {}

		--player.gamemode.activePerms = player.permissions.level

		player.gamemode.queue = activeCount - config.maxActivePlayers.value

		-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
	
		if player.gamemode.queue > 0 then
			player.gamemode.queue = 0
			player.gamemode.mode = 1
		else
			player.gamemode.queue = 0
			player.gamemode.mode = 0
		end
	
		player.vehicles = {}
	
		return player
	end
end

-- PRE: the identifier is passed in
--POST: the serverID of the player will be returned, will return -1 if no one is found
local function getPlayerID(identifier)
	local idType
	if tostring(tonumber(identifier)):len() == 8 then --discordID
		idType = discordID
	else --likely name
		idType = name
	end

	for playerID, player in pairs(players) do
		if players[idType] == identifier then
			return playerID
		end
	end

	return -1
end

--POST: return the commands table
local function getCommands() --DEPRECATED
	print("CE.getCommands is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. The commands table is now public, so directly use it instead.")
	return commands
end


-- PRE: a valid serverID and permission "flag" are both passed in.
--POST: returns true or false based on if the player with the provided serverID has access to this permission
local function hasPermission(serverID, permission) --DEPRECATED
	print("CE.hasPermission() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. Please use player:hasPermission() instead.")

	if permissions[permission].multiValue then
		local lastVal = 0

		for i=0,players[serverID].permissions.level do
			if permissions[permission].reqPerm[i] then
				lastVal = permissions[permission].reqPerm[i]
			end
		end
		return lastVal
	else
		return players[serverID].permissions.level >= permissions[permission].reqPerm
	end
end

local function getPlayers() --DEPRECATED
	print("CE.getPlayers is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. The players table is now public, so directly use it instead.")
	return players
end

local function getRconClients()
	return rconClients
end

-- PRE: feed in  info from onCarSpawn
--POST: returns true/false on if the spawn event should be canceled.
local function getSpawnAllowed(ID, vehID,  data) --DEPRECATED
	print("CE.getSpawnAllowed() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. Please use player:canSpawn() instead.")

	print(tostring(ID) .." Tried to spawn \"" .. data.name .. '"')

	if M.hasPermission(ID, "spawnVehicles") == true then --TODO: flip the two around because it makes more sense
		if registeredVehicles[data.name] == nil or registeredVehicles[data.name].reqPerm <= players[ID].permissions.level then
			local vehCount = 0
			--for k,v in pairs(GetPlayerVehicles(ID)) do
				--vehCount = vehCount + 1
			--end

			if vehID + 1 <= M.hasPermission(ID, "vehicleCap") then

			else
				print("Too many cars, Spawn Blocked")
				return false
			end
		else
			print("Spawn Blocked")
			return false
		end
	else
		print("Spawn Blocked")
		return false
	end
end

local function evaluateModes()
	inactivePermlvl = config.inactivePermlvl

	for playerID, player in ipairs(players) do
		-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
		if player.gamemode.mode == 0 then

			--if player.permissions.level == inactivePermlvl then
				--player.permissions.level = player.gamemode.activePerms
			--else
				--player.gamemode.activePerms = player.permissions.level
			--end

		elseif player.gamemode.mode == 1 then

			if player.queue == 0 then

				player.gamemode.mode = 0
				--player.permissions.level = player.gamemode.activePerms

				print(player.name .. " promoted to active player")
				SendChatMessage(playerID, "You have been promoted to an active player, you may now spawn vehicles.")

			else

				--player.permissions.level = inactivePermlvl
				SendChatMessage(pplayerID, "You are now in queue position " .. player.queue)

			end
			
		--elseif player.gamemode.mode == 2 then
			
			--player.permissions.level = inactivePermlvl
			
		end
	end
	
	--recount players
	activeCount = 0
	queueCount = 0
	specCount = 0
	for serverID, player in ipairs(players) do
		if player.gamemode.mode == 0 then
			activeCount = activeCount + 1
		elseif player.gamemode.mode == 1 then
			queueCount = queueCount + 1
		elseif player.gamemode.mode == 2 then
			specCount = specCount + 1
		end
	end
end


---------------------------------------------------------FUNCTIONS---------------------------------------------------------

-- PRE: a valid command is passed in along with args
--POST: the command is ran, any return info is passed back from the original function
local function command(sender, command, args)
	if CobaltDB.tableExists("commands",command) then
		local commandName = command
		command = commands[command]

		if sender:canExecute(command) then
			--count the arguments
			local argCount = 0
			if args ~= nil then
				args = split(args, " ")

				for k,v in pairs(args) do
					if argCount < command.arguments then
						argCount = argCount + 1
					else
						args[argCount] = args[argCount] .. " " .. v
						args[k] = nil
					end
				end
			end
			if argCount < command.arguments then
				print("Not enough arguments")
				return "Not enough arguments (" .. commandName .. " takes " .. command.arguments .. ")"
			end

			print((sender.ID or sender.playerID) .. " is Executing " .. commandName)

			if args == nil then
				return _G[command.orginModule][commandName](sender)
			else
				return _G[command.orginModule][commandName](sender, table.unpack(args))
			end

		else
			print("Insufficent Perms")
			return "You do not have permission to use this command."
		end

		
		--if rconClients[ID] ~= nil or players[ID].permissions.level >= commands[command].reqPerm then

			--local argCount = 0
			--if args ~= nil then
				--args = split(args, " ")

				--for k,v in pairs(args) do
					--if argCount < commands[command].argCount then
						--argCount = argCount + 1
					--else
						--args[argCount] = args[argCount] .. " " .. v
						--args[k] = nil
					--end
				--end

			--end

			--if argCount < commands[command].argCount then
				--print("Not enough arguments")
				--return "Not enough arguments (" .. command .. " takes " .. commands[command].argCount .. ")"
			--end

			--print(ID .. " is Executing command")

			--local sender = ID

			--if players[ID] ~= nil then
				--sender = players[ID]
			--end

			--if args == nil then
				--return commands[command].func(sender)
			--else
				--return commands[command].func(sender, table.unpack(args))
			--end

		--else
			--print("Insufficent Perms")
			--return "You do not have permission for this command"
		--end

	else
		print("Command does not exist")
		return "This command does not exist type /help for a list of commands"

	end
end

------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

----MUTATORS----
--M.registerUser = registerUser --deprecated
--M.setPermission = setPermission --deprecated
--M.registerCommand = registerCommand --deprecated
--M.registerVehicle = registerVehicle --deprecated
--M.addWhitelist = addWhitelist --deprecated
M.setWhitelistEnabled = setWhitelistEnabled --deprecated
--M.ban = ban --deprecated
--M.unban = unban --deprecated
--M.bumpQueue = bumpQueue --deprecated
M.setMuted = setMuted --deprecated
M.delayExec = delayExec

----ACCESSORS----
M.getPlayer = getPlayer --deprecated
M.getPlayerID = getPlayerID --deprecated
--M.hasPermission = hasPermission --deprecated
M.getCommands = getCommands --deprecated
---M.getPlayers = getPlayers --deprecated
M.getRconClients = getRconClients
--M.getSpawnAllowed = getSpawnAllowed --deprecated
--M.evaluateModes = evaluateModes --deprecated

----FUNCTIONS----
M.command = command

return M

