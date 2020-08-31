--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--This is to fix BeamMP's apparently dysfunctional modules, it unfortunately breaks hotswapping
cobaltVersion = "CE 1.3.3"


local neededFiles = {"lua/socket.lua","lua/mime.lua","lua/ltn12.lua","socket/core.dll","mime/core.dll"}

print("-------------Loading CobaltEssentials-------------")
CE = require("Resources/server/CobaltEssentials/lua/CobaltEssentials")

print("Loading CobaltCommands")
CC = require("Resources/server/CobaltEssentials/lua/CobaltCommands")

extensions = require("Resources/server/CobaltEssentials/lua/CobaltExtensions")
print("CobaltExtensions Loaded")

utils = require("Resources/server/CobaltEssentials/lua/CobaltUtils")
print("Utils Loaded")

json = require("Resources/server/CobaltEssentials/lua/json")
print("json Lib Loaded")

print("-------------Loading CobaltEssentials Config-------------")
config = require("Resources/server/CobaltEssentials/lua/CobaltConfig")

if config.getOptions().RCONenabled == true then
	print("-------------Loading RCON-------------")
	print("Verifying LuaSocket Library")

	for k,v in pairs({"lua","socket","mime"}) do
		if utils.exists(v) then
		
		else
			print(v .. " is missing!")
			os.execute("mkdir " .. v)
		end
	end

	for k,v in pairs(neededFiles) do
		if utils.exists(v) then
		else
			print(v .. " is missing!")
			utils.copyFile("Resources/server/CobaltEssentials/socket/" .. v, v)
		end
	end

	print("All good!")
	print("opening RCON on port " .. config.getOptions().RCONport)

	TriggerLocalEvent("startRCON", config.getOptions().RCONport)
	
end

print("-------------" .. cobaltVersion .. " Loaded-------------")
