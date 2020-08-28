--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local socket

local server

local magicChar = string.char(0xff, 0xff, 0xff, 0xff)

local waitingForReply = false

local rconClients = {}
local clientCount = 0

RegisterEvent("startRCON","startRCON")

function startRCON(port)
	
	local rconClients = {}

	socket = require("socket")


	server = socket.udp()
	server:settimeout(0.1)
	server:setsockname('0.0.0.0', port)

	RegisterEvent("RCONsend","RCONsend")
	RegisterEvent("RCONreply","RCONreply")
	CreateThread("listenRCON",500)

	print("RCON open on port " .. port)

end


function listenRCON()

	--if waitingForReply == false then

		local message, ip, port = server:receivefrom()

		if message ~= nil and message:sub(1,4) == magicChar then
			local ID = checkClient(ip, port)

--			print("'".. message .. "'")
--			print("'".. ip .. "'")
--			print("'".. port .. "'")


			message = message:sub(5)

			local s, e = message:find(" ")
			local prefix = message:sub(1,s-1)
			message = message:sub(s+1)
	
			local s, e = message:find(" ")
			local password = message:sub(1,s-1)
			message = message:sub(s+1)
	
			message = message:sub(1,message:len()-1)
			


--			print("'".. prefix .. "'")
--			print("'".. password .. "'")
--			print("'".. message .. "'")
			
			TriggerGlobalEvent("onRconCommand", ID, message, password, prefix)
			waitingForReply = true
		end
	--end
end

function RCONsend(rconID, message)
	local client = rconClients[rconID]

	local splitMes = split(message,"\n")
	
	if splitMes[2] ~= nil then
			splitMes[1] = splitMes[1] .. "..."
	end

	print("RCON > " .. rconID .. ": " .. splitMes[1])
	server:sendto(magicChar .. "print " .. message , client.ip, client.port)
end

function checkClient(ip, port)
	local clientID

	--loop through all current rconClients
	for ID, client in pairs(rconClients) do
		if client.ip == ip and client.port == port then
			clientID = client.ID
			break
		end
	end

	local client = {}

	if clientID then
		return clientID
	else
		--generate a new client table/object for the client
		client.ip = ip
		client.port = port
		client.ID = "R" .. clientCount

		clientCount = clientCount + 1 --increment clientCount


		--add the client to it's respective tables.
		rconClients[client.ID] = client
		TriggerGlobalEvent("onNewRconClient", client.ID, client.ip, client.port)
		return client.ID
	end
end



function RCONreply(reply)
	if reply == nil then
		reply = ""
	else
		local splitReply = split(reply,"\n")
	
		if splitReply[2] ~= nil then
			splitReply[1] = splitReply[1] .. "..."
		end
		
		print("RCON REPLY: " .. splitReply[1])
	end

	server:sendto(magicChar .. "print " .. reply , ip, port)
	waitingForReply = false
end

function split(s, sep)
	local fields = {}
	
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
end