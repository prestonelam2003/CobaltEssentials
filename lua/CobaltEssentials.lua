--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

----DEPENDENCIES----
--local json = require( "json" )

----VARIABLES----


local M = {}


MP.CreateEventTimer("onTick", 1000)
ageTimer = MP.CreateTimer()
--age = 0 --age of the server in milliseconds
--local ticks = 0
delayedQueue = {n = 0}

MP.RegisterEvent("onTick","onTick")

MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
MP.RegisterEvent("onPlayerFirstAuth","onPlayerFirstAuth")
MP.RegisterEvent("onPlayerConnecting","onPlayerConnecting")
MP.RegisterEvent("onPlayerJoining","onPlayerJoining")
MP.RegisterEvent("onPlayerJoin","onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect","onPlayerDisconnect")
	
MP.RegisterEvent("onConsoleInput","onConsoleInput")
MP.RegisterEvent("onChatMessage","onChatMessage")

MP.RegisterEvent("onVehicleSpawn","onVehicleSpawn")
MP.RegisterEvent("onVehicleEdited","onVehicleEdited")
MP.RegisterEvent("onVehicleDeleted","onVehicleDeleted")
MP.RegisterEvent("onVehicleReset","onVehicleReset")

MP.RegisterEvent("stop","stopServer")
MP.RegisterEvent("Cobaltstop","stopServer")

CElog("CobaltEssentials Initiated")

----------------------------------------------------------EVENTS-----------------------------------------------------------

function onTick()
	local age = ageTimer:GetCurrent()*1000

	for k,v in pairs(delayedQueue) do
		if k ~= "n" and v.complete == false and age >= v.execTime then
			
			v.complete = true

			v.func(table.unpack(v.args))

			delayedQueue[k] = nil
			delayedQueue.n = delayedQueue.n - 1
		end
	end

	if extensions then
		if extensions.triggerEvent("onTick", age) == false then
			return -1
		end
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

	local name = MP.GetPlayerName(ID)
	players.bindPlayerToID(name, ID)
	players.updateQueue()

	players[ID].connectStage = "downloading"
end

function onPlayerJoining(ID)
	players[ID].connectStage = "loading"
	CElog("On Player Joining: " .. ID)

	if extensions.triggerEvent("onPlayerJoining", players[ID]) == false then
		MP.DropPlayer(ID,"You've been kicked from the server!")

	else
		
	end
end

function onPlayerJoin(ID)
	players[ID].connectStage = "connected"

	CElog("On Player Join: " .. ID)

	if extensions.triggerEvent("onPlayerJoin", players[ID]) == false then
		MP.DropPlayer(ID,"You've been kicked from the server!")
	else
		MP.SendChatMessage(-1, players[ID].name .. " joined the game")
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

function onConsoleInput(message)
	if message == "help" then -- special case for help, it should show up without the prefix
		return M.command({type="C", canExecute=function() return true end}, "help")
	end

	local commandPrefix = config.consolePrefix.value or "CE "
	local prefixLen = commandPrefix:len()


	if message:sub(1, prefixLen) ~= commandPrefix then
		return nil
	end

	message = message:sub(prefixLen+1)

	local command, args = message
	local s, e = message:find(' ')
	if s ~= nil then
		command = message:sub(1,s-1)
		args = message:sub(s+1)
	end

	local client = { ID=0, ip="", chat=false, type="C" }

	client.canExecute = function(client, command)
		return true
	end

	local reply = M.command(client, command, args)

	return reply
end

function onChatMessage(playerID, name ,chatMessage)
	if extensions.triggerEvent("onChatMessage", players[playerID], chatMessage) == false then
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
			MP.SendChatMessage(playerID, reply)
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
end


function onVehicleSpawn(ID, vehID,  data)
	
	--local vehicle = vehicles.new(ID, vehID, data)
	
	

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
		MP.TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
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
		CElog(players[ID].name .. " tried to edit their '" .. data.name .. "' (".. ID .."-".. vehID ..") The edit has been blocked, and the vehicle deleted due to " .. reason)
		MP.TriggerGlobalEvent("onVehicleDeleted", ID, vehID)
		return 1
	end

	players[ID].vehicles[vehID] = data

end


function onVehicleReset(ID, vehID, data)
	data = json.parse(data)

	if extensions.triggerEvent("onVehicleReset", players[ID], vehID, data) == false then
		return 1
	end
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



----------------------------------------------------------MUTATORS---------------------------------------------------------

--Stop server safely make sure anything that needs to be is backed up.
function stopServer(source)
	--TODO: make this command back things up if required.
	MP.TriggerGlobalEvent("onServerStop")
	CElog("Closing server, sending stop server event to all extensions.")
	if extensions.triggerEvent("onStopServer") == false then
		return 1
	end

	local temp = config.CobaltDBport.value
	exit()
end

--    PRE: delay in milliseconds, a valid function, and args containing valid args for func are passed in.
--   POST: the delayedItem is added, after delay, func(table.unpack(args)) is executed.
--RETURNS: returns delayedItem, you can check if an item has been completed with the boolean delayedItem.complete
local function delayExec(delay, func, args)

	local delayedItem = {}

	local age = ageTimer:GetCurrent()*1000 

	delayedItem.execTime = age + delay --the time at which the func is called with args args
	delayedItem.func = func --the function that is executed
	delayedItem.args = args --the args to execute func with.
	delayedItem.complete = false

	delayedQueue.n = delayedQueue.n + 1 --increment delayedQueue.n
	delayedQueue[delayedQueue.n] = delayedItem --record

	return delayedItem
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------

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
		local argCount = 1
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
		args[0] = unhandledArgs and (" " .. unhandledArgs ) or ""

		local argString = CC.getArgumentString(commandArgs)
		
		for index, argumentType in pairs(commandArgs) do
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
					error = "Incorrect arguments, command '" .. commandName .. "' takes " .. #command.arguments .. " (" .. argString .. ")"
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
M.getArguments = getArguments

----FUNCTIONS----
M.command = command

return M

