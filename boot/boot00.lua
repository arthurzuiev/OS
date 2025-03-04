-- sets global variables and functions
local fs = component.proxy(component.list("filesystem")())

local function load()
    _G.require = function(moduleName)
        local path = "/libraries/" .. moduleName .. ".lua" -- Ensure correct path
        
        if moduleName == "Component" or moduleName == "component" then return component end -- Return component API directly
    
        if not fs.exists(path) or fs.isDirectory(path) then
            error("Module not found: " .. moduleName)
        end
    
        local handle, err = fs.open(path, "r")
        if not handle then
            error("Failed to open module: " .. moduleName)
        end
    
        local code = ""
        repeat
            local chunk = fs.read(handle, math.huge) -- Read full file
            if chunk then code = code .. chunk end
        until not chunk
    
        fs.close(handle)
    
        local func, loadErr = load(code, "=" .. path)
        if not func then
            error("Error loading module " .. moduleName .. ": " .. loadErr)
        end
    
        return func() -- Execute and return module's result
    end
end

return {
    load = load
}