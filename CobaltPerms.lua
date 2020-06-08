--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--FURTHER MORE, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

local M = {}
local CE = CobaltEssentials

local function onInit()

	-----------------------------------------USERS-----------------------------------------
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.registerUser(identifier,IDtype,permissionLevel,specialPerms)

	CE.registerUser("Preston", 3, 10)


	-----------------------------------------PERMISSIONS-----------------------------------------

	CE.setPermission()

	-----------------------------------------COMMANDS-----------------------------------------
	--CE.registerCommand(command, function, requiredPermissionLevel)

	CE.registerCommand("kick", kick(), 10)

	-----------------------------------------WHITELIST-----------------------------------------
	
	CE.setWhitelistEnabled(true)--if the whitelist is enabled, set true to enable, false to disable
	
	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.addWhitelist(identifier,IDtype)

	CE.addWhitelist("Preston", 3)

end

M.onInit = onInit

return M
