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

local function kick(senderID, kickID, ...)
	print("attempting to kick " .. kickID)
	DropPlayer(tonumber(kickID), "You've been kicked from the server")
end

local function ban(senderID, banID, ...)
	print("banned" .. banID .. "for this session")
	CE.ban( GetPlayerDiscordID( banID), 1)
	DropPlayer(tonumber(banID), "You've been banned from this server")
end

local function mute(senderID,muteID, ...)
	CE.setMuted(tonumber(muteID), true)

	return "You have muted " .. muteID
end

local function unmute(senderID, unmuteID, ...)
	CE.setMuted(tonumber(unmuteID), false)
	--SendChatMessage(args[0], "You have unmuted " .. args[2])

	return "You have unmuted " .. unmuteID
end

local function status(senderID, ...)
	players = ""
	specPlayers = ""
	playerCount = 0

	if GetPlayers() ~= nil then
		for k,v in pairs(GetPlayers()) do
			playerCount = playerCount + 1
			if CE.getPlayers()[k].mode == 0 then 
				players = players .. tostring(k) .. ": " .. tostring(v) .. "\n"
			elseif CE.getPlayers()[k].mode == 1 then
				specPlayers = specPlayers .. "[Q]" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			--SendChatMessage(args[0], tostring(k) .. ": " .. tostring(v))
			elseif CE.getPlayers()[k].mode == 2 then
				specPlayers = specPlayers .. "[S]" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			end
		end
	end

	players = cobaltVersion .. " | " .. playerCount .. " Player(s) | " .. config.getOptions().serverName .. " \n" .. players .. specPlayers

	if string.sub(senderID,1,1) ~= R then
		print(players)
	end	

	return players
end

local function help(senderID, ...)
	commandList = ""
	
	for k,v in pairs(CE.getCommands()) do
		if v.RCONonly == true then
			if string.sub(senderID,1,1) ~= R then
				commandList = commandList .. tostring(k) .. ": " .. tostring(v.desc) .. "\n"
			end
		else
			commandList = commandList .. tostring(k) .. ": " .. tostring(v.desc) .. "\n"
		end
	end

	if string.sub(senderID,1,1) ~= "R" then
		print(commandList)
	end	


	return commandList
end

local function setPerm(senderID, ID, permLvl, ...)
	local players = CE.getPlayers()
	output = ID .. " PermLvl: " .. players[tonumber(ID)].perms .. " > " .. permLvl


	--security measure.
	--if if string.sub(senderID,1,1) == "R" then or players[tonumber(args[0])].perms >= tonumber(args[3]) then
		players[tonumber(ID)].perms = tonumber(permLvl)
	--end

	print(output)
	return output
end

local function countdown(senderID, ...)
	SendChatMessage( -1 , "Starting race in 5..." )
	CE.delayExec( 1000 , SendChatMessage , { -1 , "4..."} )
	CE.delayExec( 2000 , SendChatMessage , { -1 , "3..."} )
	CE.delayExec( 3000 , SendChatMessage , { -1 , "2..."} )
	CE.delayExec( 4000 , SendChatMessage , { -1 , "1..."} )
	CE.delayExec( 5000 , SendChatMessage , { -1 , "Go!!"} )
end

local function lua(senderID, toExecute, ...)
	
	print(senderID .. " executed: " .. toExecute .. "\n")
	return load(toExecute)()
end

local function testCommand(senderID, ...)
	print("Test Command Executed")
	return "Test Sucessful"
end

local function say(senderID, message, ...)

	SendChatMessage(-1, message)
end

local function uptime(senderID, ...)
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

local function toggleChat(senderID, message)
	if CE.getRconClients()[senderID].chat == false  then
		CE.getRconClients()[senderID].chat = true
		return "You are now listening to chat"

	else
		CE.getRconClients()[senderID].chat = false
		return "You are no longer listening to chat"

	end
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
M.help = help
M.setPerm = setPerm
M.countdown = countdown
M.say = say
M.lua = lua
M.uptime = uptime
M.toggleChat = toggleChat

M.testCommand = testCommand

M.onInit()

return M