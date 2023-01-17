--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

-- PRE: Precondition
--POST: Postcondition
--RETURNS: What the method returns

-----------------------------------------------------------INIT------------------------------------------------------------

local M = {}
local MT = {}

loaded = {}

local eventAllowed = true

local function init()
	CElog("-------------Loading Extensions-------------")

	local extensionsToLoad = utils.readCfg(pluginPath .. "/LoadExtensions.cfg")

	if not extensionsToLoad then
		extensionsToLoad = {}
		local files = FS.ListFiles(pluginPath.."/extensions")
		for i, path in ipairs(files or {}) do
			local filename = string.match(path, "^([%w_]+)%.lua$")
			if filename then
				extensionsToLoad[filename] = filename
			end
		end
	else
		CElog("LoadExtensions.cfg found, disabling autoload")
	end

	for extensionName,extensionPath in pairs(extensionsToLoad) do
		M.load(extensionName, extensionPath)
	end
	CElog("-------------Extensions Loaded-------------")
end

----------------------------------------------------------EVENTS-----------------------------------------------------------

----------------------------------------------------------MUTATORS---------------------------------------------------------

local function isAvailable(extPath)
  if package.loaded[extPath] then
    return true
  end

  for _, searcher in ipairs(package.searchers) do
	local success, loader = pcall(searcher, extPath) -- catch syntax errors

	if not success then
		CElog("Failed to load extension '"..extPath.."':"..tostring(loader), "WARN")
		return false
	end

    if type(loader) == 'function' then
      return true
    end
  end
  return false
end

-- PRE: the string "extensionName" is passed in.
--POST: any file named <extensionName>.lua is loaded, the module is placed under a global variable named after string extensionName and it's init is executed, if the file exists, function returns true.
local function load(extensionName, extensionPath)
	extensionPath = extensionPath or extensionName

	if loaded[extensionName] == nil then
		local path = "extensions/" .. extensionPath
		if not isAvailable(path) then
			CElog("Extension unavailable: " .. tostring(extensionName) .. " at location: " .. tostring(path), "WARN")
			return false
		end

		local module = require(path)

		if type(module.COBALT_VERSION) == "string" then
			local cobaltVer, extensionVer = compareCobaltVersion(cobaltVersion, module.COBALT_VERSION)

			if cobaltVer > extensionVer then
				CElog(string.format("Extension '%s' is outdated (%s), it might not work as intended.", extensionName, module.COBALT_VERSION), "WARN")
			elseif cobaltVer < extensionVer then
				CElog(string.format("Extension '%s' is newer (%s) than Cobalt Essentials, it might not work as intended." ,extensionName, module.COBALT_VERSION), "WARN")
			end
		else
			CElog(string.format("Extension '%s' does not specify a version, it might be outdated.", extensionName, module.COBALT_VERSION), "WARN")
		end

		_G[extensionName] = module
		loaded[extensionName] = module

		if type(module.onInit) == "function"  then
			local success, error = pcall(module.onInit)
			if not success then
				_G[extensionName] = nil
				loaded[extensionName] = nil
				package.loaded[extensionName] = nil
				CElog("Failed to load extension '"..extensionName.."':"..tostring(error), "WARN")
				CElog("Extension unavailable: " .. tostring(extensionName) .. " at location: " .. tostring(path), "WARN")
				return false
			end
		end

		CElog("Loaded Extension " .. color(32)..extensionName..color(0))
	end
end


-- PRE: the string "extensionName" is passed in.
--POST: any extensions named extensionName will be unloaded returns true if the path exists and was unloaded.
local function unload(extensionName)
	if not loaded[extensionName] then return false end
	local module = loaded[extensionName]

	if type(module.onUnload) == "function" then module.onUnload() end

	_G[extensionName] = nil
	loaded[extensionName] = nil
	package.loaded[extensionName] = nil

	return true
end

local function cancelEvent()
	eventAllowed = false
end


---------------------------------------------------------ACCESSORS---------------------------------------------------------

-- PRE: a string 'event' is passed in, coresponding to a function in a module
--POST: any function at index event of a module is executed with parameters parameters
local function triggerEvent(event, ...)
	local args = {...}

	--reset eventAllowed
	eventAllowed = true

	--loop through all loaded modules
	for k,v in pairs(loaded) do

		--check to see if this module has the desired event
		if type(v[event]) == "function" then
			local success, res = pcall(v[event],table.unpack(args))
			if not success then
				CElog(string.format("Extension %s threw an error while handling event %s: %s", k, event, res), "WARN")
			else
				if res == false then eventAllowed = false end
			end
		end
	end

	return eventAllowed
end

--POST: returns any modules loaded as extensions
local function getLoaded()
	return loaded
end


---------------------------------------------------------FUNCTIONS---------------------------------------------------------


------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

MT.__index = function(tbl, key)
	if key == nil then return nil end

	if loaded[key] ~= nil then return loaded[key] end

	print(key)

	return rawget(tbl, key)
end

setmetatable(M, MT)



----EVENTS-----

----MUTATORS-----
M.load = load
M.unload = unload
M.cancelEvent = cancelEvent

----ACCESSORS----
M.triggerEvent = triggerEvent
M.getLoaded = getLoaded


----FUNCTIONS----

init()
return M
