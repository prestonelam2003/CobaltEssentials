--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--ADDITIONALLY, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

local M = {}


----------------------------------------------------------EVENTS-----------------------------------------------------------

--runs when the script is called.
function onInit()
    
end



----------------------------------------------------------MUTATORS---------------------------------------------------------



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

local function kick(args)
	print("attempting to kick " .. args[2])
	DropPlayer(tonumber(args[2]), "You've been kicked from the server")
end

local function ban(args)
	print("banned" .. args[2] .. "for this session")
	CE.ban( GetPlayerDiscordID( args[2]), 1)
	DropPlayer(tonumber(args[2]), "You've been banned from this server")
end

local function list(args)
	players = ""

	for k,v in pairs(GetPlayers()) do
		players = players .. tostring(k) .. ": " .. tostring(v) .. "\n"
		SendChatMessage(args[0], tostring(k) .. ": " .. tostring(v))
		
	end

	--return players
end

local function help(args)
	for k,v in pairs(CE.getCommands()) do
		SendChatMessage(args[0], tostring(k) .. ": " .. v.desc)
	end
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.onInit = onInit

----UPDATERS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----
M.kick = kick
M.ban = ban
M.list = list
M.help = help

M.onInit()

return M