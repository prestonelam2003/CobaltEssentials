--This is to fix BeamMP's apparently dysfunctional modules, it unfortunately breaks hotswapping

print("-------------Loading CobaltEssentials-------------")
CE = require("Resources/server/CobaltEssentials/lua/CobaltEssentials")

print("Loading CobaltCommands")
CC = require("Resources/server/CobaltEssentials/lua/CobaltCommands")

--print("Loading CobaltServer")
--server = require("Resources/server/CobaltEssentials/lua/CobaltServer")

print("-------------Loading CobaltEssentials Config-------------")
config = require("Resources/server/CobaltEssentials/lua/CobaltConfig")

print("-------------Server Ready-------------")