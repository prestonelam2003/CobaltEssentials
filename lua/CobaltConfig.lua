--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--FURTHER MORE, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME

local M = {}

local options = {}

local function onInit()

	print("CobaltConfig Initiated")

	-----------------------------------------OPTIONS-----------------------------------------
	options = {
		enableWhitelist = false , --weather or not the whitelist is enabled
		commandPrefix   = "/"  , -- the prefix used before a command
	}

	--CE.setOptions(options)

	-----------------------------------------USERS-----------------------------------------
	--used to set up users and their permission level based on a choser identifier
	--the default permission level is 0, negative permission levels can be created and used.

	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.registerUser(identifier,IDtype,permissionLevel,specialPerms)

	CE.registerUser("Preston", 3, 10) --never do permissions by name, this is just an example.
	CE.registerUser("348290604133908483", 1, 10) --use the discord ID like this


	-----------------------------------------PERMISSIONS-----------------------------------------
	--Used to set up specific permissions unrelated to a command like the ability to do something.
	--CE.setPermission(permission, requiredPermissionLevel, value)

	CE.setPermission("spawnVehicles", 0)



	-----------------------------------------COMMANDS-----------------------------------------
	--used to set up chat commands and their required permission level, takes a standard pointer to a function.
	--CE.registerCommand(command, function, requiredPermissionLevel)

	CE.registerCommand("kick", CC.kick, 5)
	--CE.registerCommand("testServer", server.makeServer, 0)



	-----------------------------------------WHITELIST-----------------------------------------
	--used to determine who can join the server
	
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.addWhitelist(identifier,IDtype)

	CE.addWhitelist("Preston", 3)



	-----------------------------------------BANLIST-----------------------------------------
	--used to disallow players from joining your server
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.ban(identifier,IDtype)

	CE.ban("some loser", 3)

end

local function getOptions()
	return options
end

M.onInit = onInit
M.getOptions = getOptions


M.onInit()

return M
