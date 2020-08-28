--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local loops = 0

CreateThread("heartbeat", 250)


print("Started Heartbeats")

function heartbeat()
	
	TriggerLocalEvent("onTick")

end