--Copyright (C) 2023, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

-- PRE: Precondition
--POST: Postcondition

------------------------------------------------------------INIT-----------------------------------------------------------
local players = {}

local playerPermissions = CobaltDB.new("playerPermissions")
local playerData = CobaltDB.new("playerData")
local defaultPermissions = playerPermissions["group:default"]
local inactivePermissions = playerPermissions["group:inactive"]

local weakSources = {"queue"}

local nameIDs = {}
local unboundAuthenticated = {} --Authenticated players that haven't sent a onPlayerConnecting event yet.

local activePlayers = {}
local playerQueue = {}
local spectators = {}

local activeCount = 0
local queueCount = 0
local specCount = 0



-----------------------------------------------------(META)-TABLES-INIT-----------------------------------------------------
local playersMetatable =
{
	__len = function(table)
		return MP.GetPlayerCount()
	end,
	__pairs = function(t)
		return function(t,k)
			local v
			repeat
				k, v = next(t, k)
			until k == nil or (type(k) == "number" and type(v) == "table")
			return k, v
		end, t, nil
	end
}

setmetatable(players, playersMetatable)

vehiclesTableTemplate = {}
vehiclesTableTemplate.metatable =
{
	__len = function(table)
		local count	= 0
		for k,v in pairs(table) do
			if type(v) == "table" then
				count = count + 1
			end
		end
		return count
	end
}



playerTemplate = {}
playerTemplate.metatable = 
{
	--__index = function(table, key)
	--end,

	--__newindex = function(table, key, value)
	--end,

	--__pairs = function(table)
	--return next, newTable, startIndex
	--end,
	
	__tostring = function(player)
		local playerString = "\n" .. player.playerID .. ":" .. player.name .. " @".. player.permissions.level .. "\n"
		
		for k,v in pairs(player) do

			if not (type(v) == "function" or k == "permissions" or k == "gamemode" or k == "vehicles" or k == "data") then
				playerString = playerString .. "\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			end
		end

		if #player.vehicles > 0 then
			playerString = playerString .. "\tvehicles:\n"
				for k,v in pairs(player.vehicles) do
					playerString = playerString .. "\t\t" .. tostring(k) .. ": " .. tostring(v.name) .. "\n"
				end
		end

		playerString = playerString .. "\tgamemode:\n"
			for k,v in pairs(player.gamemode) do
				playerString = playerString .. "\t\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			end

		playerString = playerString .. "\tpermissions:\n"
			for k,v in pairs(player.permissions) do
				playerString = playerString .. "\t\t" .. tostring(k) .. ": " .. tostring(v) .. "\n"
			end
		
		return playerString
	end
}

playerTemplate.protectedKeys =
{
	
}

playerTemplate.methods = {}

--PERMS
playerTemplate.permissions = {}
playerTemplate.permissions.metatable =
{
	__index = function(table, key)
		if key == "group" then
			local group, groupName = table.CobaltPlayerMgnr_playerObject:getGroup()
			return groupName
		else
			return table.CobaltPlayerMgnr_database:exists() and table.CobaltPlayerMgnr_database[key] or players.database["group:" .. table.group][key] or defaultPermissions[key]
		end
		--if table.CobaltPlayerMgnr_playerObject and rawget(table.CobaltPlayerMgnr_playerObject, "gamemode") and table.CobaltPlayerMgnr_playerObject.gamemode.mode > 0 then
			-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
			--return inactivePermissions[key] or defaultPermissions[key]
		--else
			--return (table.CobaltPlayerMgnr_database:exists() and table.CobaltPlayerMgnr_database[key]) or (table.group and players.database["group:" .. table.group]:exists() and players.database["group:" .. table.group][key]) or defaultPermissions[key]
			--return (table.CobaltPlayerMgnr_database:exists() and table.CobaltPlayerMgnr_database[key]) or defaultPermissions[key]
		--end
	end,

	__newindex = function(table, key, value)
		table.CobaltPlayerMgnr_database[key] = value
	end,

	__pairs = function(table)
		
		local newTable = {}

		if table.CobaltPlayerMgnr_database:exists() then
			for k,v in pairs(table.CobaltPlayerMgnr_database) do
				newTable[k] = v
			end
		end

		local group, groupName = table.CobaltPlayerMgnr_playerObject:getGroup()
		newTable.group = groupName
		for k,v in pairs(group) do
			if newTable[k] == nil then
				newTable[k] = group[k]
			end
		end

		for k,v in pairs(defaultPermissions) do
			if newTable[k] == nil then
				newTable[k] = defaultPermissions[k]
			end
		end

		return next, newTable, nil
	end
}

playerTemplate.permissions.protectedKeys =
{

	CobaltPlayerMgnr_database = true,
	CobaltPlayerMgnr_playerObject = true
}

--------------------------------------------------------CONSTRUCTOR--------------------------------------------------------
local function new(name, role, isGuest, identifiers)
	local newPlayer = {} --player object
	local canJoin = true --if the player is allowed to join
	local reason = nil --if the canJoin is false, why can't they join.

	--BASE STUFF
	--newPlayer.discordID = GetPlayerDiscordID(playerID)
	--newPlayer.hardwareID = GetPlayerHWID(playerID)
	newPlayer.beammp = identifiers.beammp
	newPlayer.ip = identifiers.ip
	newPlayer.guest = isGuest
	newPlayer.name = name
	newPlayer.joinTime = ageTimer:GetCurrent()*1000
	newPlayer.connectStage = 0

	--PERMISSIONS
	--newPlayer.permissions.playerID = newPlayer.playerID
	newPlayer.permissions = {}
	newPlayer.permissions.CobaltPlayerMgnr_playerObject = newPlayer
	newPlayer.permissions.CobaltPlayerMgnr_database = playerPermissions[newPlayer.name]

	--PLAYER DATA
	local playerData, databaseLoaderInfo = CobaltDB.new("playersDB/" .. newPlayer.name)
	newPlayer.data = playerData


	--GAMEMODE
	-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
	--newPlayer.gamemode = {}
	--newPlayer.gamemode.queue = activeCount + 1 - config.maxActivePlayers.value
	
	--if newPlayer.gamemode.queue > 0 then
		--newPlayer.gamemode.mode = 1
	--else
		--newPlayer.gamemode.queue = 0
		--newPlayer.gamemode.mode = 0
	--end
	
	--newPlayer.gamemode.locked =  false
	--newPlayer.gamemode.source = "default"



	--VEHICLES
	newPlayer.vehicles = {}
	setmetatable(newPlayer.vehicles, vehiclesTableTemplate.metatable)

	for methodName, method in pairs(playerTemplate.methods) do
		newPlayer[methodName] = method
	end

	--SET METATABLES
	setmetatable(newPlayer.permissions, playerTemplate.permissions.metatable)
	setmetatable(newPlayer, playerTemplate.metatable)

	--RECORD NAME
	--if newPlayer.permissions.CobaltPlayerMgnr_database:exists() then
		--newPlayer.permissions.lastName = newPlayer.name
	--end

	--CAN THE PLAYER JOIN?
	if newPlayer.permissions.whitelisted == false and config.enableWhitelist.value == true then
		canJoin = false
		reason = "You are not whitelisted on this server!"
	end


	if newPlayer.permissions.banned == true then
		canJoin = false
		reason = newPlayer.permissions.banReason or "You are banned from this server!"
	end

	unboundAuthenticated[name] = newPlayer
	--players[playerID] = newPlayer

	--if databaseLoaderInfo == "new" then
		--MP.TriggerGlobalEvent("onPlayerFirstConnecting", playerID)
	--end

	--print(tostring(newPlayer))


	return newPlayer, canJoin, reason
		--newPlayer: object
		--canJoin: boolean (if the player is allowed to join)
		--reason: string (if the canJoin is false, why can't they join.)

end

local function bindPlayerToID(name, playerID)
	local player = unboundAuthenticated[name]

	--assign some values that require a playerID
	player.playerID = playerID
	player.hardwareID = nil--MP.GetPlayerHWID(playerID)


	--GAMEMODE
	-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
	player.gamemode = {}
	player.gamemode.queue = activeCount + 1 - config.maxActivePlayers.value

	if player.gamemode.queue > 0 then
		player.gamemode.mode = 1
	else
		player.gamemode.queue = 0
		player.gamemode.mode = 0
	end

	player.gamemode.locked =  false
	player.gamemode.source = "default"

	--add player to playerList
	players[playerID] = player

	if databaseLoaderInfo == "new" then
		MP.TriggerGlobalEvent("onPlayerFirstAuth", playerID)
	end
	unboundAuthenticated[name] = nil

	CElog(tostring(player))

end

local function cancelBind(name, reason)
	CElog(name .. " was blocked from joining due to: " .. reason)
	unboundAuthenticated[name] = nil
	return reason
end

----------------------------------------------------------EVENTS-----------------------------------------------------------
local function updateQueue()
	--TODO: REQUIRES REWRITE, THIS IS NOT VERY ROBUST

	--recount players
	activeCount = 0
	queueCount = 0
	specCount = 0
	activePlayers = {}
	playerQueue = {}
	spectators = {}
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if player.gamemode.mode == 0 then --Active Players
				activeCount = activeCount + 1
				activePlayers[playerID] = player
			elseif player.gamemode.mode == 1 then --Players in queue
				queueCount = queueCount + 1
				playerQueue[playerID] = player
			elseif player.gamemode.mode == 2 then --Players who are Spectating
				spectators = specCount + 1
				spectators[playerID] = player
			end
		end
	end

	openSlots = config.maxActivePlayers.value - activeCount

	if openSlots >= 1 then
		for i = 1, openSlots do
			local toPromote
			for playerID, player in pairs(playerQueue) do
				if toPromote == nil or toPromote.joinTime > player.joinTime then
					toPromote = player
				end
				toPromote:setGamemode(0,false,"queue")
				playerQueue[toPromote.playerID] = nil
				activePlayers[toPromote.playerID] = toPromote
			end
		end
	end
end

----------------------------------------------------------MUTATORS---------------------------------------------------------
local function setMuted(player, state, reason)
	--state = (state == true and 1) or (state == true or 0)
	player.permissions.muted = state

	if state == true then
		player.permissions.muteReason = reason
		player:tell("You've been muted for: " .. reason )
	else
		player:tell("You've been unmuted")
	end
end

-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
-- PRE: A player is passed in along with a desired mode, if the mode is locked and, source, containing where the request came from.
-- PRE: mode, as defined on the modemap above, locked is a boolean defining if the gamemode should be moved around via certain automatic processes, such as the queue, source defines if lock is overridden, a number source is a permission level.
--POST: Depending on the source, if it's locked or not, etc. the gamemode of player will be changed. If changed, returns the mode, otherwise returns nil

local function setGamemode(player, mode, locked, source)
	
	local changeAllowed = true

	--figure out if change is allowed
	if player.gamemode.locked == true then
		for _,weakSource in pairs(weakSources) do
			if source == weakSource then
				changeAllowed = false
				break
			end
		end
	end

	if changeAllowed == true then
		player.gamemode.mode = mode
		player.gamemode.locked = locked
		player.gamemode.source = source

		return mode
	end
end

---------------------------------------------------------ACCESSORS---------------------------------------------------------
-- PRE: a valid serverID and permission "flag" are both passed in.
--POST: returns true or false based on if the player with the provided serverID has access to this permission
local function hasPermission(player, permission) 
	
	local highestLevel

	if permissions[permission]:exists() then
		--CElog(permission)

		for level, value in pairs(permissions[permission]) do
			if level ~= "description" and (player.permissions.level >= tonumber(level) and (highestLevel == nil or (tonumber(level) > tonumber(highestLevel)))) and permissions[permission][level] ~= nil then
				highestLevel = level
			end
		end

		return highestLevel and permissions[permission][highestLevel]
	end
end

local function canSpawn(player, vehID,  data)

	if data then --make sure the car's data exists in the first place.
		if player:hasPermission("spawnVehicles") == true then


			local vehicleDBobject --database object of the vehicle
			local defaultVehiclePermissions --a boolean referring to if vehicleDBobject is of the "default" slot
			if vehiclePermissions[data.name]:exists() then
				vehicleDBobject = vehiclePermissions[data.name]
				defaultVehiclePermissions = false
			else
				vehicleDBobject = vehiclePermissions["default"]
				defaultVehiclePermissions = true
			end

			if player.permissions.level >= vehicleDBobject.level then

				for key, value in pairs(vehicleDBobject) do
					if key:sub(1,10) == "partlevel:" then
						local part = key:sub(11)

						for slot, part2 in pairs(data.vcf.parts) do
							if part == part2 then
								if value > player.permissions.level then
									CElog('Insufficient Permissions for the part: "' .. part .. "' Spawn Blocked" )
									return false, "Insufficient permissions for the part: " .. part

								end
								break
							end
						end

					end
				end

				if #player.vehicles - ((player.vehicles[vehID] == nil and 0) or 1) >= player:hasPermission("vehicleCap") then
						CElog("Vehicle Cap Reached, Spawn Blocked")
						return false, "Vehicle Cap Reached"
				end
			else
				CElog("Insufficient Permissions for this Vehicle, Spawn Blocked")
				return false, "Insufficient permissions to spawn '" .. data.name .. "'"
			end
		else
			CElog("Insufficient Permissions, Spawn Blocked")
			return false, "Insufficient Spawn Permissions"
		end

		return true
	else
		CElog("Vehicle JSON could not be read for some reason, Try again.")
		return false, "There was an error processing your car, please try again."
	end
end
	
local function canExecute(player, command)
	return player.permissions.level >= command.level and command.sourceLimited ~= 2
end

--returns the group object and group name that the player belongs to.
local function getGroup(player)
	--Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
	if player.gamemode ~= nil and player.gamemode.mode > 0 then
		--player is inactive/spectator
		--CElog(player.name .. " joined group 'inactive'")
		return players.database["group:inactive"], "inactive"
	else
		--player is active
		if player.guest == true then
			--guest
			--CElog(player.name .. " joined group 'guest'")
			return players.database["group:guest"], "guest"
		else
			--no guest
			if player.permissions.CobaltPlayerMgnr_database.group == nil then
				--default
				--CElog(player.name .. " joined group 'default'")
				return players.database["group:default"], "default"
			else
				--has a group assigned
				local assignedGroup = player.permissions.CobaltPlayerMgnr_database.group

				if players.database["group:" .. assignedGroup] ~= nil then
					--group exists
					--CElog(player.name .. " joined group '".. assignedGroup .."'")
					return players.database["group:" .. assignedGroup], assignedGroup
				else
					--group doesn't exist, to default
					--CElog("WARNING: " .. player.name .. " could not join non-existent group:'".. assignedGroup .. "' so their group was set to default")
					return players.database["group:default"], "default"
				end
			end
		end
	end
	--return group, groupName
end

--DEPRECATED
local function getPlayerByName(name)
	for playerID, player in pairs(players)  do
		if type(player) == "table" and type(playerID) == "number" then
			if player.name == name then
				return players[playerID]
			end
		end
	end

	return nil
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------
local function tell(player, message)
	MP.SendChatMessage(player.playerID, message)
end

local function kick(player, reason)
	MP.DropPlayer(player.playerID, reason)
end

local function ban(player, reason)
	--state = (state == true and 1) or (state == true or 0)
	player.permissions.banned = true
	player.permissions.banReason = reason

	MP.DropPlayer(player.playerID, reason or "You are banned from this server!")
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


---CONSTRUCTOR---
players.new = new
players.bindPlayerToID = bindPlayerToID
players.cancelBind = cancelBind
-----EVENTS------
players.updateQueue = updateQueue

----MUTATORS-----
playerTemplate.methods.setMuted = setMuted
playerTemplate.methods.setGamemode = setGamemode
----ACCESSORS----
playerTemplate.methods.hasPermission = hasPermission
playerTemplate.methods.canSpawn = canSpawn
playerTemplate.methods.canExecute = canExecute
playerTemplate.methods.getGroup = getGroup

players.getPlayerByName = getPlayerByName
----FUNCTIONS----
playerTemplate.methods.tell = tell
playerTemplate.methods.kick = kick
playerTemplate.methods.ban = ban

players.database = playerPermissions

return players
