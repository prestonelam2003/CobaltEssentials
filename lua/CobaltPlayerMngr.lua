--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

-- PRE: Precondition
--POST: Postcondition

------------------------------------------------------------INIT-----------------------------------------------------------
local players = {}

local playerPermissions = CobaltDB.new("playerPermissions")
local playerData = CobaltDB.new("playerData")
local defaultPermissions = playerPermissions.default
local inactivePermissions = playerPermissions.inactive

local weakSources = {"queue"}

local activePlayers = {}
local playerQueue = {}
local spectators = {}

playerCount = 0
activeCount = 0
queueCount = 0
specCount = 0



-----------------------------------------------------(META)-TABLES-INIT-----------------------------------------------------
playersMetatable = 
{
	__len = function(table)
		return GetPlayerCount()
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

			if not (type(v) == "function" or k == "permissions" or k == "gamemode" or k == "vehicles") then
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
		
		if players[table.playerID] and players[table.playerID].gamemode.mode > 0 then
			-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
			return inactivePermissions[key] or defaultPermissions[key]
		else
			if table.CobaltPlrMgmt_database:exists() then
				return table.CobaltPlrMgmt_database[key] or defaultPermissions[key]
					
			else
				return defaultPermissions[key]
			end
			--return (table.CobaltPlrMgmt_database:exists() and table.CobaltPlrMgmt_database[key]) or defaultPermissions[key]
		end
	end,

	__newindex = function(table, key, value)
		--table.CobaltPlrMgmt_playerRegistered = true
		table.CobaltPlrMgmt_database[key] = value
	end,

	__pairs = function(table)
		
		local newTable = {}

		if table.CobaltPlrMgmt_database:exists() then
			for k,v in pairs(table.CobaltPlrMgmt_database) do
				newTable[k] = v
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
	CobaltPlrMgmt_playerID = true,
	CobaltPlrMgmt_database = true,
	--CobaltPlrMgmt_playerRegistered = true

}

--------------------------------------------------------CONSTRUCTOR--------------------------------------------------------
local function new(playerID)
	local newPlayer = {} --player object
	local canJoin = true --if the player is allowed to join
	local reason = nil --if the canJoin is false, why can't they join.

	
	--BASE STUFF
	newPlayer.playerID = playerID
	newPlayer.discordID = GetPlayerDiscordID(playerID)
	newPlayer.hardwareID = GetPlayerHWID(playerID)
	newPlayer.name = GetPlayerName(playerID)
	newPlayer.joinTime = age

	--PERMISSIONS
	newPlayer.permissions = {}
	newPlayer.permissions.playerID = newPlayer.playerID
	newPlayer.permissions.CobaltPlrMgmt_database = playerPermissions[newPlayer.discordID]

	--PLAYER DATA
	local playerData, databaseLoaderInfo = CobaltDB.new("playersDB/" .. newPlayer.discordID)
	newPlayer.data = playerData


	--GAMEMODE
	-- Mode-Map [-1:undefined 0:active, 1:inQueue 2:spectator]
	newPlayer.gamemode = {}
	newPlayer.gamemode.queue = activeCount + 1 - config.maxActivePlayers.value
	
	if newPlayer.gamemode.queue > 0 then
		newPlayer.gamemode.mode = 1
	else
		newPlayer.gamemode.queue = 0
		newPlayer.gamemode.mode = 0
	end
	
	newPlayer.gamemode.locked =  false
	newPlayer.gamemode.source = "default"

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
	if newPlayer.permissions.CobaltPlrMgmt_database:exists() then
		newPlayer.permissions.lastName = newPlayer.name
	end

	--CAN THE PLAYER JOIN?
	if newPlayer.permissions.whitelisted == false and config.enableWhitelist.value == true then
		canJoin = false
		reason = "You are not whitelisted on this server!"
	end
	
	if newPlayer.permissions.banned == true then
		canJoin = false
		reason = newPlayer.permissions.banReason or "You are banned from this server!"
	end


	players[playerID] = newPlayer

	if databaseLoaderInfo == "new" then
		TriggerGlobalEvent("onPlayerFirstConnecting", playerID)
	end

	print(tostring(newPlayer))


	return newPlayer, canJoin, reason
		--newPlayer: object
		--canJoin: boolean (if the player is allowed to join)
		--reason: string (if the canJoin is false, why can't they join.)

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
	if CobaltDB.tableExists("permissions",permission) then
		
		
		for level, value in pairs(permissions[permission]) do
			if level ~= "description" and (player.permissions.level >= tonumber(level) and (highestLevel == nil or tonumber(level) > tonumber(highestLevel))) then
			highestLevel = level
			end
		end



		return highestLevel and permissions[permission][highestLevel]
	end
end

local function canSpawn(player, vehID,  data)

	if data then --make sure the car's data exists in the first place.
		if player:hasPermission("spawnVehicles") == true then
			--if vehiclePermissions[data.name] == nil or registeredVehicles[data.name].reqPerm <= player.permissions.level then
				
			
			local vehicleDBobject --database object of the vehicle
			local defaultVehiclePermissions --a boolean refering to if vehicleDBobject is of the "default" slot
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
									print('Insufficent Permissions for the part: "' .. part .. "' Spawn Blocked" )
									return false, "Insufficent permissions for the part " .. part
								
								end
								break
							end
						end
	
					end
				end
	
				if #player.vehicles + ((player.vehicles[0] and 1) or 0) > player:hasPermission("vehicleCap") then
					print("Vehicle Cap Reached, Spawn Blocked")
					return false, "Vehicle Cap Reached"
				end
			else
				print("Insufficent Permissions for this Vehicle, Spawn Blocked")
				return false, "Insufficent permissions to spawn '" .. data.name .. "'"
			end
		else
			print("Insufficent Permissions, Spawn Blocked")
			return false, "Insufficent Spawn Permissions"
		end
	
		return true
	else
		print("Vehicle JSON could not be read for some reason, Try again.")
		return false, "There was an error processing your car, please try again."
	end
end
	
local function canExecute(player, command)
	return player.permissions.level >= command.level and command.sourceLimited ~= 2
end

local function getPlayerByID(identifier)
	local idType
	if tostring(tonumber(identifier)):len() == 8 then --discordID
		idType = discordID
	else --likely name
		idType = name
	end

	for playerID, player in pairs(players) do
		if players[idType] == identifier then
			return players[playerID]
		end
	end

	return nil
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------
local function tell(player, message)
	SendChatMessage(player.playerID, message)
end

local function kick(player, reason)
	DropPlayer(player.playerID, reason)
end

local function ban(player, reason)
	--state = (state == true and 1) or (state == true or 0)
	player.permissions.banned = 1
	player.permissions.banReason = reason

	DropPlayer(player.playerID, reason or "You are banned from this server!")
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


---CONSTRUCTOR---
players.new = new
-----EVENTS------
players.updateQueue = updateQueue

----MUTATORS-----
playerTemplate.methods.setMuted = setMuted
playerTemplate.methods.setGamemode = setGamemode
----ACCESSORS----
playerTemplate.methods.hasPermission = hasPermission
playerTemplate.methods.canSpawn = canSpawn
playerTemplate.methods.canExecute = canExecute

players.getPlayerByID = getPlayerByID
----FUNCTIONS----
playerTemplate.methods.tell = tell
playerTemplate.methods.kick = kick
playerTemplate.methods.ban = ban

players.database = playerPermissions

return players