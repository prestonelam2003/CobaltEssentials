--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}


----------------------------------------------------------EVENTS-----------------------------------------------------------

--runs when the script is called.
function onInit()
    
end



----------------------------------------------------------MUTATORS---------------------------------------------------------



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

local function kick(sender, name, reason, ...)
	reason = reason or "You've been kicked from the server!"
	local player = players.getPlayerByName(name)
	if player then
		player:kick(reason)
		return "Kicked " .. name .. " for: " .. reason
	end
end

local function ban(sender, name, reason, ...)
	reason = reason or "You've been banned from this server."
	local player = players.getPlayerByName(name)
	if player then
		player:ban(reason)
	else
		players.database[name].banned = true
		players.database[name].banReason = reason
	end

	CElog("Banned " .. name .. " for: " .. reason)
	return "Banned " .. name .. " for: " .. reason
end

local function unban(sender, name)
	CElog("Unbanned " .. name)
	players.database[name].banned = false
	return "Unbanned " .. name
end

local function mute(sender, name, reason, ...)
	reason = reason or "Reason not specified."
	local player = players.getPlayerByName(name)
	if player then
		player:setMuted(true, reason)
	else
		players.database[name].muted = true
		players.database[name].muteReason = reason
	end

	CElog("Muted " .. name .. " for: " .. reason)
	return "You have muted " .. name .. " for: " .. reason
end

local function unmute(sender, name, ...)
	local player = players.getPlayerByName(name)
	if player then
		player:setMuted(false)
	else
		players.database[name].muted = false
	end

	CElog("unmuted " .. name)
	return "You have unmuted " .. name
end

local function status(sender, ...)
	local playersList = ""
	local playersInQueue = ""
	local specPlayersList = ""
	local currentPlayer
	playerCount = 0

	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			playerCount = playerCount + 1
			
			currentPlayer = tostring(playerID) .. ": " .. tostring(player.name) .. "\n"


			if player.gamemode.mode == 0 then 
				playersList = playersList .. "[A] " .. currentPlayer
			elseif player.gamemode.mode == 1 then
				specPlayersList = specPlayersList .. "[Q] " .. currentPlayer
			elseif player.gamemode.mode == 2 then
				specPlayersList = specPlayersList .. "[S] " .. currentPlayer
			end
		end
	end

	playersList = "CE " .. cobaltVersion .. " | " .. playerCount .. "/" .. beamMPconfig.MaxPlayers .. " Player(s) | " .. beamMPconfig.Name .. " \n" .. playersList .. specPlayersList

	return playersList
end

local function statusdetail(sender, ...)
	local playersList = ""
	local playersInQueue = ""
	local specPlayersList = ""
	local currentPlayer
	playerCount = 0

	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			playerCount = playerCount + 1
			
			currentPlayer = tostring(player)


			if player.gamemode.mode == 0 then
				playersList = playersList .. currentPlayer
			elseif player.gamemode.mode == 1 then
				specPlayersList = specPlayersList .. currentPlayer
			elseif player.gamemode.mode == 2 then
				specPlayersList = specPlayersList .. currentPlayer
			end
		end
	end

	playersList = "CE " .. cobaltVersion .. " | " .. playerCount .. "/" .. beamMPconfig.MaxPlayers .. " Player(s) | " .. beamMPconfig.Name .. " \n" .. playersList .. specPlayersList

	return playersList
end

local function connected(sender,...)
	local playersConnected = ""
	local playersLoading = ""
	local playersDownloading = ""
	local currentPlayer
	playerCount = 0


	connectedCount = 0
	loadingCount = 0
	downloadingCount = 0

	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			playerCount = playerCount + 1

			currentPlayer = tostring(playerID) .. ": " .. tostring(player.name) .. "\n"

			if player.connectStage == "connected" then 
				playersConnected = playersConnected .. "[C] " .. currentPlayer
				connectedCount = connectedCount + 1
			elseif player.connectStage == "loading" then 
				playersLoading = playersLoading .. "[L] " .. currentPlayer
				loadingCount = loadingCount + 1
			elseif player.connectStage == "downloading" then 
				playersDownloading = playersDownloading .. "[D] " .. currentPlayer
				downloadingCount = downloadingCount + 1
			end
		end
	end

	playersList = "Connected: " .. connectedCount .. " | Loading: " .. loadingCount .. " | Downloading: " .. downloadingCount .. " \n" .. playersConnected .. playersLoading .. playersDownloading

	return playersList
end

local function help(sender, ...)
	local commandList = ""
	
	for commandName, command in pairs(commands) do
		if sender:canExecute(command) then
			commandList = commandList .. tostring(commandName) .. ": " .. tostring(command.description) .. "\n"
		end
	end

	return commandList
end

local function setperm(sender, name, permLvl, ...)
	--local players = CE.getPlayers()
	local reply

	--security measure.
	if sender.ip ~= nil or sender.permissions.level >= tonumber(permLvl) then
		players.database[name].level = tonumber(permLvl)
		reply = "Set level of " .. name .. " to " .. permLvl
	else
		reply = "Unable to set level of " .. name .. " to " .. permLvl .. " because it exceeds your own level."
	end

	CElog(reply)
	return reply
end
local function setgroup(sender, name, group, ...)
	--local players = CE.getPlayers()
	local reply = ""

	if group == "none" then
		reply = "Cleared the groups of " .. name
		players.database[name].group = nil
	elseif players.database["group:".. group]:exists() then
		--security measure.
		if sender.ip ~= nil or sender.permissions.level >= (players.database["group:".. group].level or 0) then
			reply = "Set group of " .. name .. " to " .. group
			players.database[name].group = group
		else
			reply = "Unable to set group of " .. name .. " to " .. group .. " because the permission level of the group (".. (players.database["group:".. group].level or 0) ..") exceeds yours. (".. sender.permissions.level .. ")"
		end
	else
		reply = "Unable to set " .. name .. " group, " .. group .. " does not exist"
	end



	--security measure.
	--if type(sender) == "string" or sender.permissions.level >= tonumber(permLvl) then
		--players.database[name].group = group
	--end

	CElog(reply)
	return reply
end
local function whitelist(sender, arguments)
	local returnString = ""
	local action
	local argument
	if arguments:find(" ") then
		action = arguments:sub(1,arguments:find(" ") - 1)
		argument = arguments:sub(arguments:find(" ")+1)
	else
		action = arguments
		argument = nil
	end
	
	if action == "enable" then
		config.enableWhitelist.value = true
		returnString = "The whitelist has been enabled."
	elseif action == "disable" then
		config.enableWhitelist.value = false
		returnString = "The whitelist has been disabled."
	elseif action == "add" then
		
		if argument then
			returnString = argument .. " has been whitelisted on this server."
			players.database[argument].whitelisted = true
		else
			returnString = "You must specify a player"
		end

	elseif action == "remove" then
		
		if argument then
			returnString = argument .. " has been unwhitelisted on this server."
			players.database[argument].whitelisted = false
		else
			returnString = "You must specify a player"
		end
	
	elseif action == "help" then
		returnString = returnString .. "enable: turns on the whitelist\n"
		returnString = returnString .. "disable: turns off the whitelist\n"
		returnString = returnString .. "add: adds a player to the whitelist\n"
		returnString = returnString .. "remove: removes a player from the whitelist\n"
	else
		returnString = action .. " is not a valid sub command of the whitelist, try whitelist help"
	end

	return returnString
end

local function setcfg(sender, option, value)
	local from
	if beamMPconfig[option] then
		from = beamMPconfig[option]
		beamMPconfig[option] = value
		return option .. " changed from " .. from .. " to " .. value
	else
		return option .." is not a config option, please use the same names as used in the Server.cfg"
	end
end

local function countdown(sender, ...)
	MP.SendChatMessage( -1 , "Starting race in 5..." )
	CE.delayExec( 1000 , MP.SendChatMessage , { -1 , "4..."} )
	CE.delayExec( 2000 , MP.SendChatMessage , { -1 , "3..."} )
	CE.delayExec( 3000 , MP.SendChatMessage , { -1 , "2..."} )
	CE.delayExec( 4000 , MP.SendChatMessage , { -1 , "1..."} )
	CE.delayExec( 5000 , MP.SendChatMessage , { -1 , "Go!!"} )
end

local function lua(sender, toExecute, ...)
	
	CElog(sender.ID .. " executed: " .. toExecute .. "\n")
	return load(toExecute)()
end

local function testCommand(sender, ...)
	CElog("Test Command Executed")
	return "Test Sucessful"
end

local function say(sender, message, ...)
	MP.SendChatMessage(-1, message)
end

local function uptime(sender, ...)
	local clock = math.floor(os.clock())
	
	local seconds = clock % 60
	
	local minutes = math.floor(clock/60) % 60

	local hours = math.floor((math.floor(clock/60)/60))

	--make the string formatting look nice
	if seconds < 10 then
		seconds = "0" .. seconds
	end
	if minutes < 10 then
		minutes = "0" .. minutes
	end
	if hours < 10 then
		hours = "0" .. hours
	end

	
	return(hours .. ":" .. minutes .. ":" .. seconds)

end

local function togglechat(sender, ...)
	if rconClients[sender.ID].chat == false then
		rconClients[sender.ID].chat = true
		return "You are now listening to chat"

	else
		rconClients[sender.ID].chat = false
		return "You are no longer listening to chat"

	end
end


local function stop(sender, ...)
	CE.stopServer()
end

--This is part of the copyright notice, if you edit Cobalt Essentials, you may not remove the copyright notice here.
--The /about command, which points back to this function, must also stay enabled for all permissions.
--The command must output the text as seen below, the function can be updated/modernized however, it must ultimately get this copyright notice back to the user in clear text.
--If for whatever reason this copyright has to be removed, contact me (Preston#3615 on discord at this time) and I can approve it.
--You may add your credit to this command alongside mine, so long as it follows GPLv3 standards.
--You may adjust line 1 and 2 to suit whatever Cobalt Essentials has turned into, so long as the original development credit goes to Preston Elam (Cobalt) and as per GPLv3 states, it's also gotta be under a GPLv3 license.
--
--All in all, I've (Preston Elam) worked really hard on this beamMP plugin, i've made it open source and released it under a GPLv3 license so that if for whatever reason the direction I take the plugin doesn't satisfy you, or 
--I stop developing it, someone else can pick up where I left off, and to be honest I just want credit. I'm not a lawyer at a big buisness, if you fuck up some copyright notices or accidentally break the command im not gonna sue you,
--I just really want to be recognized for all the time and effort I've put into Cobalt Essentials
--																									-Preston Elam (Cobalt)
local function about(sender, ...)
	return	"This server is running Cobalt Essentials version " .. cobaltVersion .. " developed by Preston Elam (Cobalt)"			--Line 1
	..		"\n Cobalt Essentials is released under a GPLv3 license."																--Line 2
	..		"\n Copyright (C) 2021, Preston Elam (Cobalt) ALL RIGHTS RESERVED"
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.onInit = onInit

----UPDATERS-----

----MUTATORS-----

----ACCESSORS----

----COMMANDS----
M.kick = kick
M.ban = ban
M.unban = unban --TODO
M.mute = mute
M.unmute = unmute
M.status = status
M.statusdetail = statusdetail
M.connected = connected
M.help = help
M.setgroup = setgroup
M.setperm = setperm
M.whitelist = whitelist
M.setcfg = setcfg
M.countdown = countdown
M.say = say
M.lua = lua
M.uptime = uptime
M.togglechat = togglechat
M.stop = stop
M.about = about

M.testCommand = testCommand

M.onInit()

return M