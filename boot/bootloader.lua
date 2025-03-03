-- boot/bootloader.lua

local bootloader = {}

function bootloader.load()
    -- Access the GPU component (assuming it is available)
    local gpu = component.proxy(component.list("gpu")())

    -- Set screen resolution (adjust as needed)
    gpu.setResolution(50, 15)  -- Adjust for the screen size

    -- Infinite loop to print "Hi from bootloader"
    while true do
        gpu.set(1, 1, "Hi from bootloader")  -- Print at the top-left corner
        os.pullEvent("timer")  -- Wait for a timer event to simulate delay
    end
end

return bootloader
