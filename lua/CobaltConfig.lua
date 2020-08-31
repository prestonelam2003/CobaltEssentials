--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE


--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME

local M = {}

local options = {}

local function onInit()

	print("CobaltConfig Initiated")

	-----------------------------------------OPTIONS-----------------------------------------
	options = {
		serverName = "Cobalt Essentials Server", --the name of the server as it's refered to within CobaltEssentials
		maxActivePlayers = 2 , --max amount of nonspectator players allowed on a server, any further players will be spectator and placed on a queue.
		enableWhitelist = false , --weather or not the whitelist is enabled
		commandPrefix   = "/"  , -- the prefix used before a command
		defaultVehicleReqPerm = 0, --default requiredPermissionLevel to spawn a vehicle
		defaultPermlvl = 1, --default permissionLevel for unregistered users
		inactivePermlvl = 0,

		
		RCONenabled = true , --if the server should also run a q3 compliant rcon server for remote acess to the server's console
		RCONport = 20814 , --the port used to host the server. Since CE is external to beamMP make sure to not place this on the same port as the server.
		RCONpassword = "password", --the password required to access the RCON.
		RCONkeepAliveTick = 30 -- the amount of seconds between ticks sent to RCONclients to keep the connections alive, false to disable.
	}

	--CE.setOptions(options)

	-----------------------------------------USERS-----------------------------------------
	--used to set up users and their permission level based on a choser identifier
	--unregistered users will get the defaultPermlvl

	--ID-TYPE-MAP: 1: discordID | 2: HWID | 3: NAME
	--CE.registerUser(identifier,IDtype,permissionLevel,specialPerms)

	CE.registerUser("Preston", 3, 10) --never do permissions by name, this is just an example.
	CE.registerUser("168500725305835520", 1, 10) --use the discord ID like this


	-----------------------------------------PERMISSIONS-----------------------------------------
	--Used to set up specific permissions unrelated to a command like the ability to do something.
	--CE.setPermission(permission, requiredPermissionLevel, value)

	CE.setPermission("spawnVehicles", 1)
	CE.setPermission("sendMessage", 0)

	CE.setPermission("vehicleCap", 1, 1)
	CE.setPermission("vehicleCap", 10, 2)
	CE.setPermission("vehicleCap", 11, 3)
	-----------------------------------------COMMANDS-----------------------------------------
	--used to set up chat commands and their required permission level, takes a standard pointer to a function.
	--CE.registerCommand(command, function, requiredPermissionLevel, argCount, RCONonly)

	CE.registerCommand("kick", CC.kick, 5, "kick a player from the session", 1)
	CE.registerCommand("ban", CC.ban, 6, "ban a player from the session", 1)
	CE.registerCommand("mute", CC.mute, 5, "disallow a player from talking", 1)
	CE.registerCommand("unmute", CC.unmute, 5, "allow a muted player to talk again", 1)
	CE.registerCommand("status",CC.status, 0, "lists all the players on the server with their ids and basic information on the server", 0)
	CE.registerCommand("help",CC.help,0, "get a list of each command", 0)
	CE.registerCommand("setperm", CC.setPerm,9,"Change the permission level of a player", 2)
	CE.registerCommand("countdown",CC.countdown,0,"Start a countdown in chat", 0)
	CE.registerCommand("uptime", CC.uptime,0, "Get the uptime of the server", 0)
	CE.registerCommand("say", CC.say,10, "Say a message as the server.", 1)
	CE.registerCommand("lua", CC.lua,10,"Execute lua", 1, true) -- lua is likely to not work if executed through chat, try the rcon
	CE.registerCommand("togglechat", CC.toggleChat,10 ,"Toggles viewing chat in the RCON client", 0, true) -- lua is likely to not work if executed through chat, try the rcon

	--debug functions
	--CE.registerCommand("progressQueue",onPlayerDisconnect,0,"simulate a disconnect")
	--CE.registerCommand("test",CC.testCommand,"Test the command system")

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

	-----------------------------------------VEHICLES-----------------------------------------
	--used to set required permissions for VEHICLES
	--CE.registerVehicle(vehicleName, requiredPermissionLevel)

	CE.registerVehicle("example",10)

	----------------------------------------EXTENSIONS----------------------------------------
	print("-------------Loading Extensions-------------")
	--used to load 3rd party extensions NOTE: filename does not include the .extension at the end
	--extensions.load(<filename>) 


	extensions.load("exampleExtension")


end

local function getOptions()
	return options
end

M.onInit = onInit
M.getOptions = getOptions


M.onInit()

return M
