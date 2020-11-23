--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns


----------------------------------------------------------INIT-----------------------------------------------------------
local M = {}

permissions = CobaltDB.new("permissions")
commands = CobaltDB.new("commands")
vehiclePermissions = CobaltDB.new("vehicles")
config = CobaltDB.new("config")

beamMPconfig = {}
local currentcfg = {}
local beamMPcfg = utils.readCfg("server.cfg")


--for key,value in pairs(beamMPcfg) do
	--beamMPconfig[key] = value
--end

local beamMPconfigMetatable = {
	
	__index = function(table, key)
		return currentcfg[key] or beamMPcfg[key]
	end,
	
	__newindex = function(table, key, value)
		if key == "Debug" then
			Set(0, value)
		elseif key == "Private" then
			Set(1, value)
		elseif key == "Cars" then
			Set(2, value)
		elseif key == "MaxPlayers" then
			Set(3, value)
		elseif key == "Map" then
			Set(4, value)
		elseif key == "Name" then 
			Set(5, value)
		elseif key == "description" then
			Set(6, value)
		else
			return nil
		end
		currentcfg[key] = value
	end
}

setmetatable(beamMPconfig, beamMPconfigMetatable)

----------------------------------------------------------EVENTS-----------------------------------------------------------



----------------------------------------------------------MUTATORS---------------------------------------------------------
--    PRE: an object, target database is passed in, alongside a set of tables to be applied to said database
--   POST: the appliedTable and it's values are passed into the targetDatabase, HOWEVER, if the table already exists, the pre-existing table will not be overridden.
--RETURNS: the tables that were applied
local function applyDefaults(targetDatabase, tables)
	local appliedTables = {}

	for tableName, table in pairs(tables) do
		--check to see if the database already recognizes this table.
		--if CobaltDB.tableExists(targetDatabase.CobaltDB_databaseName, tableName)  == false then --TODO: update this to an Object-Oriented method.
		if targetDatabase[tableName]:exists() == false then
			--write the key/value table into the database
			for key, value in pairs(table) do
				targetDatabase[tableName][key] = value
			end
			appliedTables[tableName] = tableName
		end
	end
	return appliedTables
end
---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

------------------------------------------------------DEFAULT-CONFIGS------------------------------------------------------
--THIS IS NOT THE NEW CONFIG, DO NOT CHANGE THESE FOR STARTERS, IT WONT DO ANYTHING.
--IF YOU ARE LOOKING FOR THE CONFIG, PLEASE REFER TO: beamMPserver/Resources/Server/CobaltEssentials/CobaltDB for where the json config is now stored.
local defaultConfig = 
{
	commandPrefix =		{value = "/",			description = "The character placed at the beginning of a chat message when using a command"},
	maxActivePlayers =	{value = 5,				description = "max amount of active/nonspectator players allowed on a server, any further players will be spectator and placed on a queue."},
	enableWhitelist =	{value = false,			description = "weather or not the whitelist is enabled"},

	RCONenabled =		{value = true,			description = "weather or not the server should run a q3 compliant rcon server for remote acess to the server"},
	RCONport =			{value = 20814,			description = "The port used to host the server. Since CE is external to beamMP make sure to not place this on the same port as the server."},
	RCONpassword =		{value = "password",	description = "The password required to connect to the RCON"},
	RCONkeepAliveTick = {value = 30,			description = "The amount of seconds between ticks sent to RCONclients to keep the connections alive, false to disable, This may not work?"},

	CobaltDBport =		{value = 10814,			description = "The port used for internal CobaltDB communications, please keep it unique to each server or there may be interference."}
}

local defaultPermissions = 
{
	--note: the numbers are displayed as strings because they must be, when referenced, everything will be converted to numbers appropriately.
	spawnVehicles =	{[0] = true, description = "If you may spawn vehicles or not."},
	sendMessage =	{[0]  = true, description = "If send messages in chat or not."},
	vehicleCap =	{[1] = 1, [3] = 2, [5] = 5, [10] = 10, description = "The  amount of vehicles that may be spawned based on permission level."}
}

local defaultCommands = 
{
	--orginModule[commandName] is where the command is executed from
	-- Source-Limit-Map [0:no limit | 1:Chat Only | 2:RCON Only]
	help =			{orginModule = "CC",	level = 0,	arguments = 0,	sourceLimited = 0,	description = "Lists all commands accessible by the player"},
	status =		{orginModule = "CC",	level = 0,	arguments = 0,	sourceLimited = 0,	description = "Lists all the players on the server with their ids and basic information on the server"},
	statusdetail =	{orginModule = "CC",	level = 0,	arguments = 0,	sourceLimited = 0,	description = "Lists all the players on the server in detail along with basic server information"},
	about =			{orginModule = "CC",	level = 0,	arguments = 0,	sourceLimited = 0,	description = "Displays the license, version, and copyright notice assosiated with Cobalt Essentials."},
	uptime =		{orginModule = "CC",	level = 0,	arguments = 0,	sourceLimited = 0,	description = "Get the uptime of the server"},
	countdown =		{orginModule = "CC",	level = 1,	arguments = 0,	sourceLimited = 0,	description = "Start a countdown in chat"},
	say =			{orginModule = "CC",	level = 5,	arguments = 1,	sourceLimited = 0,	description = "Say a message as the server."},
	mute =			{orginModule = "CC",	level = 5,	arguments = 1,	sourceLimited = 0,	description = "Disallow a player from talking"},
	unmute =		{orginModule = "CC",	level = 5,	arguments = 1,	sourceLimited = 0,	description = "Allow a muted player to talk"},
	kick =			{orginModule = "CC",	level = 5,	arguments = 1,	sourceLimited = 0,	description = "Kick a player from the session"},
	ban =			{orginModule = "CC",	level = 10,	arguments = 1,	sourceLimited = 0,	description = "Ban a player from the session"},
	setperm =		{orginModule = "CC",	level = 10,	arguments = 2,	sourceLimited = 0,	description = "Change a player's permission level"},
	lua =			{orginModule = "CC",	level = 10,	arguments = 1,	sourceLimited = 2,	description = "Execute Lua, return the desired reply."},
	togglechat =	{orginModule = "CC",	level = 10,	arguments = 0,	sourceLimited = 2,	description = "Toggles viewing chat in the RCON client"},
	stop =			{orginModule = "CC",	level = 10,	arguments = 0,	sourceLimited = 0,	description = "Stops the server"}
}

local defaultVehiclePermissions = 
{
	default =	{level = 1}
}

local defaultPlayerPermissions =
{
	default =	{level = 1,	whitelisted = false,	banned = false,	muted = false},
	inactive =	{level = 0}
}

applyDefaults(config, defaultConfig)
applyDefaults(permissions, defaultPermissions)
applyDefaults(commands, defaultCommands)
applyDefaults(vehiclePermissions, defaultVehiclePermissions)
applyDefaults(CobaltDB.new("playerPermissions"), defaultPlayerPermissions)
------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.permissions = permissions
M.commands = commands
M.vehiclePermissions = vehiclePermissions
M.config = config

----EVENTS-----


----MUTATORS-----
M.applyDefaults = applyDefaults

----ACCESSORS----

----FUNCTIONS----


return M