-- Accessing the GPU component without require
local component = component
local gpu = _G.component.proxy(component.list("gpu")())

-- Set the screen resolution (optional)
gpu.setResolution(80, 25)  -- Example: 80 characters wide, 25 rows tall

-- Display text at the top-left corner (0, 0)
gpu.set(1, 1, "Hello from BIOS!")

-- dont halt it
while true do
  computer.pullSignal()
end
