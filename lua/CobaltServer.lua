--Created by Preston Elam (CobaltTetra) 2020
--THIS SCRIPT IS PROTECTED UNDER AN GPLv3 LICENSE
--ADDITIONALLY, YOU MAY EDIT THIS SCRIPT, BUT BY USING IT YOU AGREE TO NOT REMOVE THE CREDIT ON THE FIRST LINE IF IT IS RESDITRIBUTED, YOUR OWN CREDIT MAY BE ADDED ON LINE2.

--    PRE: Precondition
--   POST: Postcondition
--RETURNS: What the method returns

local M = {}
local socket = require("socket")
local server

----------------------------------------------------------EVENTS-----------------------------------------------------------

--runs when the script is called.
local function makeServer()
    server = socket.tcp()
	server:bind('*',69420)
	local k,v = server:listen(10)
	print(k,v)
	print("Ready to  accept")
	server = server:accept()
	print("Ready to receive")
	print(server:receive('*a'))
end

----------------------------------------------------------MUTATORS---------------------------------------------------------



---------------------------------------------------------ACCESSORS---------------------------------------------------------



---------------------------------------------------------FUNCTIONS---------------------------------------------------------



------------------------------------------------------PUBLICINTERFACE------------------------------------------------------


----EVENTS-----
--M.onInit = onInit
M.makeServer = makeServer

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----

--M.onInit()

return M