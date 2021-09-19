--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

-- PRE: Precondition
--POST: Postcondition
--RETURNS: What the method returns

-----------------------------------------------------------INIT------------------------------------------------------------

local M = {}

loaded = {}

local eventAllowed = true

local function init()
	CElog("-------------Loading Extensions-------------")

	local extensionsToLoad = utils.readCfg(resources .. "/server/" .. pluginName .. "/LoadExtensions.cfg")

	for extensionName,extensionPath in pairs(extensionsToLoad) do
		--CElog(tostring(extensionName) .. ": " .. tostring(extensionPath))
		M.load(extensionName, extensionPath)
	end
	CElog("-------------Extensions Loaded-------------")
end

----------------------------------------------------------EVENTS-----------------------------------------------------------

----------------------------------------------------------MUTATORS---------------------------------------------------------

-- PRE: the string "extension" is passed in.
--POST: any file named <extension>.lua is loaded, the module is placed under a global variable named after string extension and it's init is executed, if the file exists, function returns true.
local function load(extension, extensionPath)
	extensionPath = extensionPath or extension
	
	if loaded[extension] == nil then
		local module = require("extensions/" .. extensionPath)
	
		_G[extension] = module
		loaded[extension] = module

		if module.onInit then module.onInit() end

		CElog("Loaded Extension " .. extension)
	end
end


--DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK DOES NOT WORK 
-- PRE: the string "extension" is passed in.
--POST: any extensions named extension will be unloaded returns true if the path exists and was unloaded.
local function unload(extension)
	
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
		if v[event] ~= nil then
			v[event](table.unpack(args))

			
			--if a nil parameter isn't ignored, make sure parameters isn't nil or don't use it
			--if parameters == nil then
				--v[event]()
			--else
				--v[event](parameters)
			--end


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
