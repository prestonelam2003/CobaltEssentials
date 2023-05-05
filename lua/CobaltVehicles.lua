--Copyright (C) 2021, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns
local totalSpawned = 0 --This will be incremented when a vehicle is spawned to generate a serverID for the vehicle
local spawned = {}

local M = {}
local VehicleObject = {}

----------------------------------------------------------INIT-----------------------------------------------------------



----------------------------------------------------------EVENTS-----------------------------------------------------------
--Create a new vehicle and determine if it's allowed to spawn or not.
local function newVehicle(pid, vid, data)
	local allowed = true
	local Vehicle = {}
	Vehicle.data = M.parseVehData(data)
	Vehicle.pid = pid
	Vehicle.vid = vid
	Vehicle.ID = totalSpawned



	local allowed, reason = players[pid]:canSpawn(Vehicle.data)




	if allowed then
		totalSpawned = totalSpawned + 1
		return Vehicle
	else
		return false, reason
	end
end

local function parseVehData(data)
	local s, e = data:find('%{')

	data = data:sub(s)

	local successful, tempData = pcall(json.parse, data)
	if not successful then
		--TODO: BACKUP THE JSON IN A FILE. tempData is the error, data is the json.
		return false
	end

	data = tempData

	--place entries under new name
	--data.serverVID = vehID
	--data.clientVID = data.VID
	data.name = data.jbm
	data.cfg = data.vcf

	--clear out double entries
	data.jbm = nil
	data.vcf = nil



	if data[4] ~= nil then
		local successful, tempData = pcall(json.parse, data[4])
		if not successful then
			--TODO: BACKUP THE JSON IN A FILE. tempData is the error, data is the json.
			return false
		end
		data.info = tempData
	end

	return data
end
----------------------------------------------------------MUTATORS---------------------------------------------------------



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------
local function update(Vehicle)
	local allowed = true
	local reason

	if allowed then
		return Vehicle
	else
		return false, reason
	end
end

VehicleObject.update = update()
------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.spawned = spawned
M.new = newVehicle
M.parseVehData = parseVehData

----EVENTS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----


return M