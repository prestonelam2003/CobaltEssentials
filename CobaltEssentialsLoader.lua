--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

MP.RegisterEvent("onCobaltDBhandshake","onCobaltDBhandshake") --to make sure cobaltDB loads first

cobaltVersion = "1.7.3"

pluginPath = debug.getinfo(1).source:gsub("\\","/")
pluginPath = pluginPath:sub(1,(pluginPath:find("CobaltEssentialsLoader.lua"))-2)

utils = require("CobaltUtils")

function onInit()
	print("\n\n")
	CElog(color(107,94) .. "-------------Loading Cobalt Essentials v" .. cobaltVersion .. "------------")
		CE = require("CobaltEssentials")

		CElog("Utils Loaded")

		CElog("Loading CobaltCommands")
			CC = require("CobaltCommands")

		--TODO: WRITE A WAY TO LOAD THESE CONFIG OPTIONS AS AN OVERRIDE TO MAKE SERVER UPDATES/PORTS EASIER?
		--CobaltConfigOld = require("CobaltConfig")
			--print("CobaltConfig Loaded")

		json = require("json")
			CElog("json Lib Loaded")

		--CobaltDB = require("CobaltDBconnector")
		CobaltDB = require("EventDBconnector")
			CElog("CobaltDB Connector Loaded")
			utils.setLogType("DEBUG",97,function() return config.enableDebug.value == true end)

		MP.TriggerLocalEvent("initDB")
end

--FOR WHEN COBALTDB REPORTS BACK
function onCobaltDBhandshake(port)

	CobaltDB.init(port)

	players = require("CobaltPlayerMngr")
		CElog("Cobalt Player Manager Loaded")

	configMngr = require("CobaltConfigMngr")
		CElog("Config Manager Loaded")

		--Load CobaltExtensions & any of it's extensions
	extensions = require("CobaltExtensions")
		CElog("CobaltExtensions Loaded")

	vehicles = require("CobaltVehicles")
		CElog("CobaltVehicles Loaded")


	--See if CobaltConfig needs to be loaded for compatability
	if FS.Exists(pluginPath .. "/lua/CobaltConfig.lua") then
		CobaltCompat = require("CobaltCompat")
	end

	--WARNING for not having enough players in the config.
	if beamMPconfig.MaxPlayers > config.maxActivePlayers.value then
		CElog("/!\\ ---THE SERVER'S MAX PLAYER COUNT IS GREATER THAN THE MAX ACTIVE PLAYERS IN THE COBALT CONFIG--- /!\\","WARN")
		--Sleep(2000)
	end

	local highestCap
	for reqPerm, cap in pairs(permissions.vehicleCap) do
		if reqPerm ~= "description" and (highestCap == nil or cap > highestCap) then
		highestCap = cap
		end
	end

	if tonumber(highestCap) > tonumber(beamMPconfig.MaxCars) then
		CElog("/!\\ -------------------------------SERVERSIDE-VEHICLE-CAP-FOR-CARS-TOO-LOW------------------------------- /!\\","WARN")
		CElog("		The serverside vehicle cap (Cars) in the config is too low.","WARN")
		CElog("		If you do not turn it up, dynamic vehicle caps based on permission level will not work!","WARN")
		CElog("		Please adjust the serverside vehicle cap to " .. highestCap .. " or greater to avoid any problems.","WARN")
		CElog("/!\\ -------------------------------SERVERSIDE-VEHICLE-CAP-FOR-CARS-TOO-LOW------------------------------- /!\\","WARN")
		beamMPcfg.MaxCars = highestCap
		--Sleep(5000)
	end

	if beamMPconfig.LogChat == true then
		CElog("/!\\ -------------------------------CHAT-LOGGING-ENABLED------------------------------- /!\\","WARN")
		CElog("		The server has the option 'LogChat' enabled.","WARN")
		CElog("		This will lead to duplicate chat messages in the console and log, as Cobalt logs messages as well.","WARN")
		CElog("		Please set the option 'LogChat' to false to avoid this.","WARN")
		CElog("/!\\ -------------------------------CHAT-LOGGING-ENABLED------------------------------- /!\\","WARN")
		beamMPcfg.MaxCars = highestCap
		--Sleep(5000)
	end

	CElog("-------------Cobalt Essentials v" .. cobaltVersion .. " Loaded-------------")
end

