--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )

----VARIABLES----


local M = {}

rconClients = {} --RCON clients start with an R[ID]
--local lastContact = 0


age = 0 --age of the server in milliseconds
--local ticks = 0
delayedQueue = {n = 0}

RegisterEvent("onTick","onTick")

RegisterEvent("onPlayerAuth","onPlayerAuth")
RegisterEvent("onPlayerFirstAuth","onPlayerFirstAuth")
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

CElog("CobaltEssentials Initiated")

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

--The first time a player has began connecting to the server, this is called.
function onPlayerFirstAuth(name)
	CElog("onPlayerFirstAuth: " .. name)

	if extensions.triggerEvent("onPlayerFirstAuth", players[ID]) == false then
		--return("You were blocked from joining by an extension")
	end

end

--the player is authenticated by the backend
function onPlayerAuth(name, role, isGuest)
	
	local player, canJoin, reason = players.new(name, role, isGuest)

	if extensions.triggerEvent("onPlayerAuth", player) == false then
		return players.cancelBind(name, "You were blocked from joining by an extension")
	elseif canJoin == false then
		return players.cancelBind(name, reason)
	end

	local authenticatedMessage = name
	if isGuest then
		authenticatedMessage = authenticatedMessage .. " authenticated as a GUEST"
	else
		authenticatedMessage = authenticatedMessage .. " authenticated as a " .. role
	end
	authenticatedMessage = authenticatedMessage .. " @" .. player.permissions.level
	CElog(authenticatedMessage)

end

function onPlayerConnecting(ID)
	CElog("On Player Connecting: " .. ID)

	local name = GetPlayerName(ID)

	players.bindPlayerToID(name, ID)

	players.updateQueue()
end

function onPlayerJoining(ID)

	CElog("On Player Joining: " .. ID)

	if extensions.triggerEvent("onPlayerJoining", players[ID]) == false then
		DropPlayer(ID,"You've been kicked from the server!")

	else
		
	end
end

function onPlayerJoin(ID)
	CElog("On Player Join: " .. ID)
	
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
			CElog("On Player Disconnect: " .. ID .. " | Dropped for " .. players[ID].dropReason)
		else
			CElog("On Player Disconnect: " .. ID .. " | Disconnected")
		end

		players[ID] = nil
	else
		CElog("On Player Disconnect: " .. ID .. " | Left while Loading.")
	end

	players.updateQueue()
end


function onChatMessage(playerID, name ,chatMessage)
	chatMessage = chatMessage:sub(2)

	if extensions.triggerEvent("onChatMessage", players[ID], chatMessage) == false then
		return -1
	end


	if chatMessage:sub(1,1) == config.commandPrefix.value then
		--CElog("Command")

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
		
		local reply = M.command(players[playerID], command, args)
		if reply ~= nil then
			SendChatMessage(playerID, reply)
		end

		--make the chat message not appear in chat. 
		return 1
	else
			
	end
	
	if players[playerID].permissions.muted ~= true and players[playerID]:hasPermission("sendMessage") == true then
		CElog("[".. playerID .. "]" .. name .. " : " .. chatMessage,"CHAT")
	else
		CElog("MUTED:[".. playerID .. "]" .. name .. " : " .. chatMessage,"CHAT")
		return 1
	end

	local formattedMessage = "[".. playerID .. "]" .. name .. " : " .. chatMessage

	for rconID, rconClient in pairs(rconClients) do
		if rconClient.chat == true then
			TriggerGlobalEvent("RCONsend", rconID, formattedMessage) 
			rconClients[rconID].lastContact = age
		end
	end

end


function onVehicleSpawn(ID, vehID,  data)
	
	data = utils.parseVehData(data)

	--for k,v in pairs(data) do print(tostring(k) .. ": " .. tostring(v)) end
	--for k,v in pairs(data.parts) do print(tostring(k) .. ": " .. tostring(v)) end
	local canSpawn, reason = players[ID]:canSpawn(vehID, data)
	canSpawn = canSpawn and extensions.triggerEvent("onVehicleSpawn", players[ID], vehID, data)
	reason = reason or "Spawn blocked by extension"

	if canSpawn then
		CElog(players[ID].name .. " Spawned a '" .. data.name .. "' (".. ID .."-".. vehID ..")")
	else
		CElog(players[ID].name .. " Tried to spawn '" .. data.name .. "' (".. ID .."-".. vehID ..") The spawn was blocked due to '" .. reason .. "'")
		players[ID]:tell("Unable to spawn vehicle: " .. reason)
		TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
		return 1
	end

	players[ID].vehicles[vehID] = data
	
end

function onVehicleEdited(ID, vehID,  data)

	data = utils.parseVehData(data)


	local canSpawn, reason = players[ID]:canSpawn(vehID, data)
	canSpawn = canSpawn and extensions.triggerEvent("onVehicleEdited", players[ID], vehID, data)
	reason = reason or "Spawn blocked by extension"

	if canSpawn then
		CElog(players[ID].name .. " edited their '" .. data.name .. "' (".. ID .."-".. vehID ..")")
	else
		CElog(players[ID].name .. "tried to edit their '" .. data.name .. "' (".. ID .."-".. vehID ..") The edit has been blocked, and the vehicle deleted due to " .. reason)
		TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
		return 1
	end

	players[ID].vehicles[vehID] = data

end

function onVehicleDeleted(ID, vehID)
	ID = tonumber(ID)
	vehID = tonumber(vehID)

	if extensions.triggerEvent("onVehicleDeleted", players[ID], vehID) == false then
		return 1
	end

	if players[ID].vehicles[vehID] then
		CElog(players[ID].name .. " deleted their '" .. players[ID].vehicles[vehID].name .. "' (".. ID .."-".. vehID ..")")
		players[ID].vehicles[vehID] = nil
	end
end


function onRconCommand(ID, message, password, prefix)
	local reply


	CElog(rconClients[ID].ip .. " : " ..prefix .. " " .. password .. " " .. message,"RCON")

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

			--CElog("RCON REPLIES WITH COMMAND REPLY")
			if reply ~= nil then
				TriggerGlobalEvent("RCONsend", ID, reply)
			end
		else
			--CElog("RCON REPLIES WITH BAD COMMAND")
			TriggerGlobalEvent("RCONsend", ID, "Unrecognized Command")
		end
	else
		--CElog("RCON REPLIES WITH BAD PASSWORD")
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
	client.type = "RCON"

	client.canExecute = function(client, command)
		return command.sourceLimited ~= 1
	end
	
	if extensions.triggerEvent("onNewRconClient", client) == false then
		return 1
	end

	rconClients[ID] = client
end
----------------------------------------------------------MUTATORS---------------------------------------------------------

--Stop server safely make sure anything that needs to be is backed up.
local function stopServer()
	--TODO: make this command back things up if required.
	exit()
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

local function getRconClients()
	return rconClients
end

-- PRE: the sender object, command object, the arguments after the commmand as a string are passed in.
--POST: the unhandledArgs string is divided up into distinct arguments for the command.
local function getArguments(sender, command, unhandledArgs)
	local args = {}
	local error
	local commandName = command
	command = commands[command]
	local commandArgs = command.arguments
	--old system/also used for commands with 0 arguments
	if type(commandArgs) == "number" then
		args = unhandledArgs
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
		if argCount < commandArgs then
			error = "Not enough arguments (" .. commandName .. " takes " .. command.arguments .. ")"
			CElog("Not enough arguments")
		end
	--loop through the command's requested args
	elseif type(commandArgs) == "table" then
		args[0] = " " .. unhandledArgs
		
		local argString = ""
		--loop through and get all the args.
		for index, argumentType in pairs(commandArgs) do
			argString = argString .. "<" .. argumentType .. ">"
			local lastArg = args[index - 1]
			local s, e = lastArg:find(" ")
			
			--see if there are even more spaces
			if s == nil then
				break
			end
			args[index-1] = lastArg:sub(1,s-1)
			args[index] = lastArg:sub(s+1)
			--print("'" .. args[index-1] .. "'")
			--print("'" .. lastArg .. "'")
			--print("'" .. args[index] .. "'" )
		end
		args[0] = nil

		--loop back through again and clean up the final args.
		for index, argumentType in pairs(commandArgs) do
			local required = true
			if argumentType:sub(1,1) == "*" then
				argumentType = argumentType:sub(2)
				required = false
			end
			--see if the argument is nil
			if args[index] == nil then
				if required then
					error = "Incorrect arguments," .. commandName .. " takes " .. #command.arguments .. "(" .. argString .. ")"
				else
					break --why keep looping through if the rest are empty.
				end
			else
				--switch statement for different types of values
				if argumentType == "player" then
					if args[index]:sub(1,1) == "{" then
						--local s, e = args[index]:find("}")
						args[index] = tonumber(args[index]:sub(2,args[index]:find("}")-1))
						--print(args[index] .. " - id")
						if players[args[index]] then
							args[index] = players[args[index]].name
							--print(args[index] .. " - name")
						else
							error = "Bad argument in position " .. index .. ", ID ".. args[index] .. " does not belong to a player!"
						end
					else
						args[index] = args[index]:gsub("+"," ")
					end
				end
			end

		end
	end

	
	--clear args if it's an empty table
	if args == {} then
		args = nil
	end

	return args, error
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------

-- PRE: a valid command is passed in along with args
--POST: the command is ran, any return info is passed back from the original function
local function command(sender, command, args)
	local message = ""
	if CobaltDB.tableExists("commands",command) then
		if sender.playerID then
			message = message .. sender.name .. ": " .. command .. " " .. (args or "")
		end
		local commandName = command
		command = commands[command]

		args, error = M.getArguments(sender, commandName, args)
		if error then
			return error
		end

		if sender:canExecute(command) then
			
			if sender.playerID then
				CElog(message)
			end

			if args == nil then
				return _G[command.orginModule][commandName](sender)
			else
				return _G[command.orginModule][commandName](sender, table.unpack(args))
			end

		else
			CElog("Insufficent Perms")
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
		CElog("Command does not exist")
		return "This command does not exist type /help for a list of commands"

	end
end

------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

----MUTATORS----
M.stopServer = stopServer
M.delayExec = delayExec

----ACCESSORS----
M.getRconClients = getRconClients
M.getArguments = getArguments

----FUNCTIONS----
M.command = command

return M

