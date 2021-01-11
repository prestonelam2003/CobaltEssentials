--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

-----------------------------------------------------------INIT------------------------------------------------------------

local M = {}

CElog("/!\\ ------------------------------------------------COBALT-COMPAT------------------------------------------------ /!\\","WARN")
CElog("    It appears you are still using CobaltConfig.lua, CobaltConfig.lua is deprecated.","WARN")
CElog("    You should be using CobaltDB instead.","WARN")
CElog("    All of your settings from CobaltConfig.lua will be transfered over to CobaltDB.","WARN")
CElog("    When after this session, please delete CobaltConfig as all of your settings have been transfered to CobaltDB","WARN")
CElog("    If you do not switch from CobaltConfig, various features may act up between sessions.","WARN")
CElog("/!\\ ------------------------------------------------COBALT-COMPAT------------------------------------------------ /!\\","WARN")
Sleep(10000)

local function init()

	ConfigMngrConfig = _G.config
	config = nil
	
	local CobaltConfig = require("CobaltConfig")
	
	deprecatedConfig = config
	
	_G.config = ConfigMngrConfig
	
	local existingConfigOptions = {"commandPrefix", "maxActivePlayers", "RCONport", "RCONpassword", "RCONkeepAliveTick", "enableWhitelist","RCONenabled"}
	
	for option, value in pairs(deprecatedConfig) do
		print(tostring(option) .. ":" .. tostring(value))
		for index, existingOption in pairs(existingConfigOptions) do
			local optionSet = false
			--easy 1 to 1 option translations
			if existingOption == option then
				config[option].value = value
				optionSet = true
				existingConfigOptions[index] = nil
			end
		end
	
		--special cases for option translations
		if optionSet == false then
			--if option == "enableWhitelist" then
				--config.enableWhitelist.value = (value == true and 1) or (value == true or 0)
				--config.enableWhitelist.value = value
			--elseif option == "RCONenabled" then
				--config.RCONenabled.value = (value == true and 1) or (value == true or 0)
				--config.RCONenabled.value = value
			if option == "defaultVehicleReqPerm" then
				vehiclePermissions.default.level = value
			elseif option == "defaultPermlvl" then
				players.database.default.level = value
			elseif option == "inactivePermlvl" then
				players.database.inactive.level = value
			--elseif option == "RCONkeepAliveTick" then
				--config.RCONkeepAliveTick.value = (value == false and  0) or value
				--config.RCONkeepAliveTick.value = value
			end
		end
	end	

	print("")

	CobaltConfig.loadConfig()
		
	CE.registerUser = nil
	CE.setPermission = nil
	CE.registerCommand = nil
	CE.registerVehicle = nil
	CE.addWhitelist = nil
	CE.ban = nil
	extensions.load = loadExtensions
end	

----------------------------------------------------------EVENTS-----------------------------------------------------------


----------------------------------------------------------MUTATORS---------------------------------------------------------
local function registerUser(identifier, IDtype, permissionLevel, specialPerms) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.setPermission() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	CElog("Registered " .. identifier .. " as ID Type " .. IDtype .. " @" .. permissionLevel)

	if IDtype == 1 then
		players.database[identifier].level = permissionLevel
	else
		CElog("ALL PLAYERS MUST USE IDTYPE = 1 (DISCORD ID)")
	end
end



--POST: set the permission requirement for the "flag" optional value for things like car count
local function setPermission(permission, reqPerm, value) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.setPermission() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'permissions' database to edit it directly.")
	
	permissions[permission][reqPerm] = value
end 

-- PRE: a command name, function and the required permission level is passed in.
--POST: the command is added to the commands table.
local function registerCommand(command, func, reqPerm, desc, argCount, RCONonly) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.registerCommand() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'commands' database to edit it directly.")
	CElog("Registered " .. command .. " Command @" .. reqPerm)

	commands[command].level = reqPerm
	commands[command].arguments = argCount
	commands[command].description = desc

	commands[command].orginModule = "CC"

	if RCONonly == 1 then
		commands[command].sourceLimited = 2
	else
		commands[command].sourceLimited = 0
	end
end

local function registerVehicle(name, reqPerm) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.registerVehicle() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'vehicles' database to edit it directly.")
	CElog("Set " .. name .. " @" .. reqPerm)

	vehiclePermissions[name].level = reqPerm
end

--POST: adds a player to the whitelist for this session
local function addWhitelist(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.addWhitelist() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	CElog("Added " .. identifier .. " as ID Type " .. IDtype .. " to the whitelist" )
	
	if IDtype == 1 then
		players.database[identifier].whitelisted = true
	else
		CElog("ALL PLAYERS MUST USE IDTYPE = 1 (DISCORD ID)")
	end
end

local function ban(identifier, IDtype) --DEPRECATED DUE TO CobaltDB, CobaltConfigMngr & CobaltPlayerMngr IMPLEMENTATION
	--print("CE.ban() is deprecated as of Cobalt Essentials 1.4.0! It is not supported, and may be removed in the future. For in-code implementation, please use the CobaltDB 'playerPermissions' database to edit it directly.")
	CElog("Banned " .. identifier .. " as ID Type " .. IDtype .. " from the server" )
	
	if IDtype == 1 then
		players.database[identifier].banned = true
	else
		CElog("ALL PLAYERS MUST USE IDTYPE = 1 (DISCORD ID)")
	end
end



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


CE.registerUser = registerUser
CE.setPermission= setPermission
CE.registerCommand = registerCommand
CE.registerVehicle = registerVehicle
CE.addWhitelist = addWhitelist
CE.ban = ban
local loadExtensions = extensions.load
extensions.load = function() end

init()

----EVENTS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----


return M