--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--This is to fix BeamMP's apparently dysfunctional modules, it unfortunately breaks hotswapping
cobaltVersion = "CE 1.3.6"
pluginName = debug.getinfo(1).source:sub(2)

local resources = debug.getinfo(1).source:sub(2)
local s, e = resources:find("\\")
resources = resources:sub(0,e-1)

for i = 0, 1 do
	local s, e = pluginName:find("\\")
	pluginName = pluginName:sub(s+1)
end
local s, e = pluginName:find("\\")
pluginName = pluginName:sub(1,e-1)


package.path = package.path .. ";;" .. resources .. "/server/" .. pluginName .. "/?.lua;;".. resources .. "/server/" .. pluginName .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. resources .. "/server/" .. pluginName .. "/?.dll"

local neededFiles = {"lua/socket.lua","lua/mime.lua","lua/ltn12.lua","socket/core.dll","mime/core.dll"}

print("-------------Loading CobaltEssentials-------------")
CE = require("CobaltEssentials")

print("Loading CobaltCommands")
CC = require("CobaltCommands")

extensions = require("CobaltExtensions")
print("CobaltExtensions Loaded")

utils = require("CobaltUtils")
print("Utils Loaded")

json = require("json")
print("json Lib Loaded")

print("-------------Loading CobaltEssentials Config-------------")
config = require("CobaltConfig")

if config.getOptions().RCONenabled == true then
	print("-------------Loading RCON-------------")
	print("Verifying LuaSocket Library")
--
--	for k,v in pairs({"lua","socket","mime"}) do
--		if utils.exists(v) then
--		
--		else
--			print(v .. " is missing!")
--			os.execute("mkdir " .. v)
--		end
--	end
--
--	for k,v in pairs(neededFiles) do
--		if utils.exists(v) then
--		else
--			print(v .. " is missing!")
--			utils.copyFile(resources .."/server/" .. pluginName .. "/socket/" .. v, v)
--		end
--	end

	print("All good!")
	print("opening RCON on port " .. config.getOptions().RCONport)

	TriggerLocalEvent("startRCON", config.getOptions().RCONport, package.path, package.cpath)
	
end

print("-------------" .. cobaltVersion .. " Loaded-------------")
