--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE


CreateThread("heartbeat", 250)


print("Started Heartbeat")

function heartbeat()
	
	TriggerLocalEvent("onTick")

end