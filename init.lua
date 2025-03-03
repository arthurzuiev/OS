local shell = require("shell")
local bootloader = dofile("/bootloader/bootloader.lua")

shell.execute("/installer.lua")

bootloader.load()