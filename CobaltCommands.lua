--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--ADDITIONALLY, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

local M = {}


----------------------------------------------------------EVENTS-----------------------------------------------------------

--runs when the script is called.
function onInit()
    
end



----------------------------------------------------------MUTATORS---------------------------------------------------------



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------

local function kick(args)
	print("attempting to kick " .. args[1])
	DropPlayer(toNumber(args[1]), "You've been kicked from the server")
end



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------

M.onInit = onInit

----UPDATERS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----
M.kick = kick

return M