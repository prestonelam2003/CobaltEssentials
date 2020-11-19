--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--This is to fix BeamMP's apparently dysfunctional modules, it unfortunately breaks hotswapping

RegisterEvent("onCobaltDBhandshake","onCobaltDBhandshake")

cobaltVersion = "1.4.9"

pluginName = debug.getinfo(1).source:sub(2)
local s,e

resources = debug.getinfo(1).source:sub(2)

local s, e = resources:find("\\")
resources = resources:sub(0,e-1)
local s, e = resources:find("Server")
resources = resources:sub(1,s-2)

s, e = pluginName:find("\\")
pluginName = pluginName:sub(s+1)
s, e = pluginName:find("\\")
pluginName = pluginName:sub(1,s-1)


package.path = package.path .. ";;" .. resources .. "/Server/" .. pluginName .. "/?.lua;;".. resources .. "/Server/" .. pluginName .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. resources .. "/Server/" .. pluginName .. "/?.dll;;" .. resources .. "/Server/" .. pluginName .. "/lib/?.dll"


--local neededFiles = {"lua/socket.lua","lua/mime.lua","lua/ltn12.lua","socket/core.dll","mime/core.dll"}

print("-------------Loading Cobalt Essentials v" .. cobaltVersion .. "-------------")
	CE = require("CobaltEssentials")

	print("Loading CobaltCommands")
		CC = require("CobaltCommands")

	utils = require("CobaltUtils")
		print("Utils Loaded")

	--TODO: WRITE A WAY TO LOAD THESE CONFIG OPTIONS AS AN OVERRIDE TO MAKE SERVER UPDATES/PORTS EASIER?
	--CobaltConfigOld = require("CobaltConfig")
		--print("CobaltConfig Loaded")

	json = require("json")
		print("json Lib Loaded")

	CobaltDB = require("CobaltDBconnector")
		print("CobaltDB Connector Loaded")

--FOR WHEN COBALTDB REPORTS BACK
function onCobaltDBhandshake(port)
	CobaltDB.init(port)

	players = require("CobaltPlayerMngr")
		print("Cobalt Player Manager Loaded")

	configMngr = require("CobaltConfigMngr")
		print("Config Manager Loaded")

		--Load CobaltExtensions & any of it's extensions
	extensions = require("Cobaltextensions")
		print("CobaltExtensions Loaded")


	--See if CobaltConfig needs to be loaded for compatability
	if utils.exists(resources .. "/Server/" .. pluginName .. "/lua/CobaltConfig.lua") then
		CobaltCompat = require("CobaltCompat")
	end

	if config.RCONenabled.value == true then
		print("opening RCON on port " .. config.RCONport.value)
		TriggerLocalEvent("startRCON", config.RCONport.value, package.path, package.cpath)
	end
	
	--WARNING for not having enough players in the config.
	if beamMPconfig.MaxPlayers < config.maxActivePlayers.value then
		print("/!\\ ---THE SERVER'S MAX PLAYER COUNT IS GREATER THAN THE MAX ACTIVE PLAYERS IN THE COBALT CONFIG--- /!\\")
		Sleep(2000)
	end

		--TODO: WARNING FOR NOT HAVING ENOUGH CARS ALLOWED IN THE CONFIG
	local highestCap
	for reqPerm, cap in pairs(permissions.vehicleCap) do
		if reqPerm ~= "description" and (highestCap == nil or cap > highestCap) then
		highestCap = cap
		end
	end
		
	if tonumber(highestCap) > tonumber(beamMPconfig.Cars) then
		print("/!\\ -------------------------------SERVERSIDE-VEHICLE-CAP-FOR-CARS-TOO-LOW------------------------------- /!\\")
		print("		The serverside vehicle cap (Cars) in the config is too low.")
		print("		If you do not turn it up, dynamic vehicle caps based on permission level will not work!")
		print("		Please adjust the serverside vehicle cap to " .. highestCap .. " or greater to avoid any problems.")
		print("/!\\ -------------------------------SERVERSIDE-VEHICLE-CAP-FOR-CARS-TOO-LOW------------------------------- /!\\")
		Sleep(5000)
	end
end

--
print("-------------CobaltEssentials Config-------------")
	--CobaltConfigOld.loadConfig()
	--for k,v in pairs(config.beamMP) do print(tostring(k) .. ": " .. tostring(v)) end

print("-------------Cobalt Essentials v" .. cobaltVersion .. " Loaded-------------")