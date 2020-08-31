--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )

----VARIABLES----


local M = {}

local commands = {}

local options = {}

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

local registeredVehicles = {}

local players = {}
local permissions = {}

local rconClients = {} --RCON clients start with an R[ID]


local playerCount = 0
local activeCount = 0
local queueCount = 0
local specCount = 0

local age = 0 --age of the server in milliseconds
--local ticks = 0
local delayedQueue = {n = 0}

--OPTIONS--
--whitelist.enabled = true --The default state of the whitelist.


----------------------------------------------------------EVENTS-----------------------------------------------------------

function onInit()
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
end

function onTick()

	age = os.clock() * 1000

	for k,v in ipairs(delayedQueue) do
		if v.complete == false and age >= v.execTime then
			
			v.complete = true

			v.func(table.unpack(v.args))

			delayedQueue[k] = nil
		end
	end

	if extensions.triggerEvent("onTick", age) == false then
		return -1
	end

	--ticks = ticks + 1

end

function onPlayerConnecting(ID)
	print("On Player Connecting: " .. tostring(ID))

	if extensions.triggerEvent("onPlayerConnecting", ID) == false then
		DropPlayer(ID,"You've been kicked from the server!")	
	else


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
	M.evaluateModes()
end

function onPlayerJoining(ID)

	print("On Player Joining: " .. tostring(ID))

	if extensions.triggerEvent("onPlayerJoining", ID) == false then
		DropPlayer(ID,"You've been kicked from the server!")

	else
		
	end
end

function onPlayerJoin(ID)
	print("On Player Join: " .. tostring(ID))
	
	if extensions.triggerEvent("onPlayerJoin", ID) == false then
		DropPlayer(ID,"You've been kicked from the server!")
	else
		SendChatMessage(-1, players[ID].name .. " joined the game")
	end
end

function onPlayerDisconnect(ID)
	print("On Player Disconnect")
		
	extensions.triggerEvent("onPlayerDisconnect", ID)
		

	--bump join order


	--loop through all players to decrement the join order where required
	M.bumpQueue(1)

	SendChatMessage(-1, players[ID].name .. " left the game")
	players[ID] = nil
end


function onChatMessage(playerID, name ,chatMessage)
	chatMessage = chatMessage:sub(2)

	if extensions.triggerEvent("onChatMessage", playerID, name, chatMessage) == false then
		return -1
	end


	if chatMessage:sub(1,1) == config.getOptions().commandPrefix then
		print("Command")

		local command = M.split(chatMessage:sub(2)," ")[1]

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
		
		local reply = M.command(playerID, command, args)
		if reply ~= nil then
			SendChatMessage(playerID, reply)
		end

		--make the chat message not appear in chat. 
		return 1
	else
			
	end
	
	if players[playerID].muted == true or M.hasPermission(playerID, "sendMessage") == false then
		return 1
	end

	local formattedMessage = "[".. playerID .. "]" .. name .. " : " .. chatMessage
	print(formattedMessage)

	for rconID, rconClient in pairs(rconClients) do
		if rconClient.chat == true then
			TriggerGlobalEvent("RCONsend", rconID, formattedMessage)
		end
	end

end


function onVehicleSpawn(ID, vehID,  data)
	print("On Vehicle Spawn")
	
	data = M.parseVehData(data)

	--for k,v in pairs(data) do print(tostring(k) .. ": " .. tostring(v)) end
	--for k,v in pairs(data.parts) do print(tostring(k) .. ": " .. tostring(v)) end

	if M.getSpawnAllowed(ID, vehID, data) == false or extensions.triggerEvent("onVehicleSpawn", ID, vehID, data) == false then
		return 1
	end
	
	print("Spawn Sucessful")
end

function onVehicleEdited(ID, vehID,  data)
	print("On Vehicle Edit")

	data = M.parseVehData(data)

	if extensions.triggerEvent("onVehicleEdited", ID, vehID, data) == false then
		
		return 1
	end
end

function onVehicleDeleted(ID, vehID)
	print("on Vehicle Delete")

	if extensions.triggerEvent("onVehicleDeleted", ID, vehID) == false then
		return 1
	end
end


function onRconCommand(ID, message, password, prefix)
	local reply


	print(rconClients[ID].ip .. " : " ..prefix .. " " .. password .. " " .. message)

	if password == config.getOptions().RCONpassword then
		
		if extensions.triggerEvent("onRconCommand", ID, message, password, prefix) == false then
			return 1
		end

		local args
		local command = M.split(message," ")[1]
		local s, e = message:find(' ')
		if s ~= nil then
			args = message:sub(s+1)
		end
	
		if commands[command] ~= nil then
			
			local reply = M.command(ID, command, args)

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
	
	if extensions.triggerEvent("onNewRconClient", client) == false then
		return 1
	end

	rconClients[ID] = client
end

----------------------------------------------------------MUTATORS---------------------------------------------------------


local function registerUser(identifier, IDtype, permissionLevel, specialPerms)
	print("Registered " .. identifier .. " as ID Type " .. IDtype .. " @" .. permissionLevel)

	registeredUsers[IDtype][identifier] = {}
	registeredUsers[IDtype][identifier].perms = permissionLevel
	--registeredUsers[IDtype][identifier].special = specialPerms
end



--POST: set the permisson requirement for the "flag" optional value for things like car count
local function setPermission(permission, reqPerm, value)
	
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
local function registerCommand(command, func, reqPerm, desc, argCount, RCONonly)
	print("Registered " .. command .. " Command @" .. reqPerm)

	commands[command] = {}
	commands[command].func = func
	commands[command].reqPerm = reqPerm
	commands[command].desc = desc
	commands[command].argCount = argCount
	commands[command].RCONonly = RCONonly
end

local function registerVehicle(name, reqPerm)
	print("Set " .. name .. " @" .. reqPerm)

	registeredVehicles[name] = {}
	registeredVehicles[name].reqPerm = reqPerm
end

--POST: adds a player to the whitelist for this session
local function addWhitelist(identifier, IDtype)
	print("Added " .. identifier .. " as ID Type " .. IDtype .. " to the whitelist" )
	whitelist[IDtype][identifier] = true
end

--POST: removes a player from the whitelist for this session
local function removeWhitelist(identifier, IDtype)
	print("Removed " .. identifier .. " as ID Type " .. IDtype .. " from the whitelist" )

	whitelist[IDtype][identifier] = nil
end

--POST: set the whitelist as enabled or disabled (true/false) if nil or invalid, the value will toggle.
local function setWhitelistEnabled(enabled)
	if not enabled  then
		config.getOptions().enableWhitelist = not config.getOptions().enableWhitelist
	else
		enabled = enabled == true or false
		config.getOptions().enableWhitelist = enabled
	end


	if config.getOptions().enableWhitelist == enabled then
		print("Disabled Whitelist")
	else
		print("Enabled Whitelist")
	end
end

--POST: bans a player from this session
local function ban(identifier, IDtype)
	print("Banned " .. identifier .. " as ID Type " .. IDtype .. " from the server" )
	banlist[IDtype][identifier] = true
end

--POST: unbans a player from this session
local function unban(identifier, IDtype)
	print("Unbanned " .. identifier .. " as ID Type " .. IDtype .. " from the server" )
	banlist[IDtype][identifier] = nil
end

local function setOptions(options)
	options = options
end


local function bumpQueue(spots)
	for k, v in pairs(players) do
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

	players[playerID].muted = state

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
local function getPlayer(serverID)
	local player = {}
	player.serverID = serverID
	player.discordID = GetPlayerDiscordID(serverID)
	player.HWID = GetPlayerHWID(serverID)
	player.name = GetPlayerName(serverID)
	player[1] = player.discordID
	player[2] = player.HWID
	player[3] = player.name


	player.whitelisted = not config.getOptions().enableWhitelist --stuff related to banlist and whitelist is a little complicated might decide to rewrite for clarity/readability just wanted to keep it compact.
	player.banned = false
	player.perms = 0
	
	
	--loop through the 3 id types
	for k,v in ipairs(player) do
		
		--check if the player is whitelisted
		if player.whitelisted == false and whitelist[k][v] == true then
			print("Player is whitelisted")
			player.whitelisted = true
		end


		--check if the player is banned
		if player.banned == false and banlist[k][v] == true then
			print("Player is banned")
			player.banned = true
		end

		--set the player's permission level accordingly
		if registeredUsers[k][v] then

			if player.perms < tonumber(registeredUsers[k][v].perms) then

				player.perms = tonumber(registeredUsers[k][v].perms)
			end
		end
	end

	if player.perms == 0 then
		player.perms = config.getOptions().defaultPermlvl
	end

	--print a new player in chat
	local playerString = "\n" .. player.serverID .. ":" .. player.name .. " @".. player.perms .. "\n"

	for k,v in pairs(player) do
		if not (k == 1 or k == 2 or k == 3) then
			playerString = playerString .. "\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
		end
	end
	print(playerString)

	--info that changes
	player.muted = false


	player.activePerms = player.perms

	--setup if the player is a spectator and the queue if they are.

	print("playerCount:" .. GetPlayerCount())
	
	player.queue = activeCount - config.getOptions().maxActivePlayers

	-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]

	if player.queue > 0 then
		player.queue = 0
		player.mode = 1
	else
		player.queue = 0
		player.mode = 0
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

--POST: return the commands table
local function getCommands()
	return commands
end


-- PRE: a valid serverID and permission "flag" are both passed in.
--POST: returns true or false based on if the player with the provided serverID has access to this permission
local function hasPermission(serverID, permission)
	
	if permissions[permission].multiValue then
		local lastVal = 0

		for i=0,players[serverID].perms do
			if permissions[permission].reqPerm[i] then
				lastVal = permissions[permission].reqPerm[i]
			end
		end
		return lastVal
	else
		return players[serverID].perms >= permissions[permission].reqPerm

	end
end

local function getPlayers()
	return players
end

local function getRconClients()
	return rconClients
end

-- PRE: feed in  info from onCarSpawn
--POST: returns true/false on if the spawn event should be canceled.
local function getSpawnAllowed(ID, vehID,  data)

	print(tostring(ID) .." Tried to spawn \"" .. data.name .. '"')

	if M.hasPermission(ID, "spawnVehicles") == true then --TODO: flip the two around because it makes more sense
		if registeredVehicles[vehName] == nil or registeredVehicles[vehName].reqPerm <= players[ID].perms then
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
	inactivePermlvl = config.getOptions().inactivePermlvl

	for k, v in pairs(players) do
		-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
		if v.mode == 0 then

			if v.perms == inactivePermlvl then
				v.perms = v.activePerms
			else
				v.activePerms = v.perms
			end

		elseif v.mode == 1 then

			if v.queue == 0 then

				v.mode = 0
				v.perms = v.activePerms

				print(v.name .. " promoted to active player")
				SendChatMessage(v.serverID, "You have been promoted to an active player, you may now spawn vehicles.")

			else

				v.perms = inactivePermlvl
				SendChatMessage(v.serverID, "You are now in queue position " .. v.queue)

			end
			
		elseif v.mode == 2 then
			
			v.perms = inactivePermlvl
			
		end
	end
	
	--recount players
	activeCount = 0
	queueCount = 0
	specCount = 0
	for k, v in pairs(players) do
		if v.mode == 0 then
			activeCount = activeCount + 1
		elseif v.mode == 1 then
			queueCount = queueCount + 1
		elseif v.mode == 2 then
			specCount = specCount + 1
		end
	end
end


---------------------------------------------------------FUNCTIONS---------------------------------------------------------

-- PRE: a valid command is passed in along with args
--POST: the command is ran, any return info is passed back from the original function
local function command(ID, command, args)
	if commands[command] then


		if rconClients[ID] ~= nil or players[ID].perms >= commands[command].reqPerm then

			local argCount = 0
			if args ~= nil then
				args = M.split(args, " ")

				for k,v in pairs(args) do
					if argCount < commands[command].argCount then
						argCount = argCount + 1
					else
						args[argCount] = args[argCount] .. " " .. v
						args[k] = nil
					end
				end

			end

			if argCount < commands[command].argCount then
				print("Not enough arguments")
				return "Not enough arguments (" .. command .. " takes " .. commands[command].argCount .. ")"
			end

			print(ID .. " is Executing command")
			if args == nil then
				return commands[command].func(ID)
			else
				return commands[command].func(ID, table.unpack(args))
			end

		else
			print("Insufficent Perms")
			return "You do not have permission for this command"
		end

	else
		print("Command does not exist")
		return "This command does not exist type /help for a list of commands"

	end
end

local function split(s, sep)
	local fields = {}

	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
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

function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
	  if code == 13 then
		 -- Permission denied, but it exists
		 return true
	  end
   end
   return ok, err
end

function copyFile(path_src, path_dst)
	local ltn12 = require("Resources/server/CobaltEssentials/socket/lua/ltn12")

	ltn12.pump.all(
		ltn12.source.file(assert(io.open(path_src, "rb"))),
		ltn12.sink.file(assert(io.open(path_dst, "wb")))
	)
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

----MUTATORS----
M.addPlayer = addPlayer
M.registerUser = registerUser
M.setPermission = setPermission
M.registerCommand = registerCommand
M.registerVehicle = registerVehicle
M.addWhitelist = addWhitelist
M.setWhitelistEnabled = setWhitelistEnabled
M.ban = ban
M.unban = unban
M.bumpQueue = bumpQueue
M.setMuted = setMuted
M.delayExec = delayExec

----ACCESSORS----
M.getPlayer = getPlayer
M.getServerID = getServerID
M.hasPermission = hasPermission
M.getCommands = getCommands
M.getPlayers = getPlayers
M.getRconClients = getRconClients
M.getSpawnAllowed = getSpawnAllowed
M.evaluateModes = evaluateModes

----FUNCTIONS----
M.command = command
M.split = split
M.parseVehData = parseVehData
M.output = output

onInit()

return M

