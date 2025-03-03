local function loadScript(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local func, err = load(content, path)
        if func then
            func()
        else
            print("Error loading script: " .. err)
        end
    else
        print("File not found: " .. path)
    end
end

local bootloader = loadScript("/bootloader/bootloader.lua")
bootloader.load()