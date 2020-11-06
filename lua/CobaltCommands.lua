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

local function kick(sender, kickID, reason, ...)
	print("attempting to kick " .. kickID)
	DropPlayer(tonumber(kickID), "You've been kicked from the server")
end

local function ban(sender, banID, reason, ...)
	print("banned" .. banID .. "for this session")
	CobaltPermissions.ban(GetPlayerDiscordID(banID), 1)
	DropPlayer(tonumber(banID), "You've been banned from this server")
end

local function mute(sender, muteID, reason, ...)
	players[muteID]:setMuted(true, reason)

	return "You have muted " .. muteID
end

local function unmute(sender, unmuteID, ...)
	players[muteID]:setMuted(false, reason)

	return "You have unmuted " .. unmuteID
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
				playersList = playersList .. "[A]" .. currentPlayer
			elseif players.gamemode.mode == 1 then
				specPlayersList = specPlayersList .. "[Q:" .. player.gamemode.queue .. "] " .. currentPlayer
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
			elseif players.gamemode.mode == 1 then
				specPlayersList = specPlayersList .. currentPlayer
			elseif player.gamemode.mode == 2 then
				specPlayersList = specPlayersList .. currentPlayer
			end
		end
	end

	playersList = "CE " .. cobaltVersion .. " | " .. playerCount .. "/" .. beamMPconfig.MaxPlayers .. " Player(s) | " .. beamMPconfig.Name .. " \n" .. playersList .. specPlayersList

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

local function setperm(sender, ID, permLvl, ...)
	--local players = CE.getPlayers()
	local reply = ID .. " PermLvl: " .. players[tonumber(ID)].permissions.level .. " > " .. permLvl


	--security measure.
	--if type(sender) == "string" or sender.permissions.level >= tonumber(permLvl) then
		players[tonumber(ID)].permissions.level = tonumber(permLvl)
	--end

	print(reply)
	return reply
end

local function countdown(sender, ...)
	SendChatMessage( -1 , "Starting race in 5..." )
	CE.delayExec( 1000 , SendChatMessage , { -1 , "4..."} )
	CE.delayExec( 2000 , SendChatMessage , { -1 , "3..."} )
	CE.delayExec( 3000 , SendChatMessage , { -1 , "2..."} )
	CE.delayExec( 4000 , SendChatMessage , { -1 , "1..."} )
	CE.delayExec( 5000 , SendChatMessage , { -1 , "Go!!"} )
end

local function lua(sender, toExecute, ...)
	
	print(sender.ID .. " executed: " .. toExecute .. "\n")
	return load(toExecute)()
end

local function testCommand(sender, ...)
	print("Test Command Executed")
	return "Test Sucessful"
end

local function say(sender, message, ...)
	SendChatMessage(-1, message)
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
	if CE.getRconClients()[sender].chat == false then
		CE.getRconClients()[sender].chat = true
		return "You are now listening to chat"

	else
		CE.getRconClients()[sender].chat = false
		return "You are no longer listening to chat"

	end
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
	..		"\n Copyright (C) 2020, Preston Elam (Cobalt) ALL RIGHTS RESERVED"
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.onInit = onInit

----UPDATERS-----

----MUTATORS-----

----ACCESSORS----

----COMMANDS----
M.kick = kick
M.ban = ban
M.mute = mute
M.unmute = unmute
M.status = status
M.statusdetail = statusdetail
M.help = help
M.setperm = setperm
M.countdown = countdown
M.say = say
M.lua = lua
M.uptime = uptime
M.togglechat = togglechat
M.about = about

M.testCommand = testCommand

M.onInit()

return M