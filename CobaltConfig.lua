--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--FURTHER MORE, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME

local M = {}
local CE = CobaltEssentials

local function onInit()

	-----------------------------------------USERS-----------------------------------------
	--used to set up users and their permission level based on a choser identifier
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.registerUser(identifier,IDtype,permissionLevel,specialPerms)

	CE.registerUser("Preston", 3, 10)


	-----------------------------------------PERMISSIONS-----------------------------------------
	--Used to set up specific permissions unrelated to a command like the ability to do something.

	CE.setPermission()



	-----------------------------------------COMMANDS-----------------------------------------
	--used to set up chat commands and their required permission level, takes a standard pointer to a function.
	--CE.registerCommand(command, function, requiredPermissionLevel)

	CE.registerCommand("kick", kick(), 10)



	-----------------------------------------WHITELIST-----------------------------------------
	--used to determine who can join the server

	CE.setWhitelistEnabled(true)--if the whitelist is enabled, set true to enable, false to disable
	
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.addWhitelist(identifier,IDtype)

	CE.addWhitelist("Preston", 3)



	-----------------------------------------BANLIST-----------------------------------------
	--used to disallow players from joining your server
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.ban(identifier,IDtype)

	CE.ban("example person", 3)

end

M.onInit = onInit

return M
