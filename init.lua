-- init.lua

-- Access the file system component
local fs = component.proxy(component.list("filesystem")())

-- Open bootloader.lua
local file = fs.open("boot/bootloader.lua", "r")
local bootloader_code = fs.read(file, fs.size(file))  -- Read the entire file
fs.close(file)

-- Compile and execute the bootloader code
local bootloader = load(bootloader_code)

-- Run the bootloader
bootloader()
