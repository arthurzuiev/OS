local component = require("component")
local gpu = component.proxy(component.list("gpu")())
local width, height = gpu.getResolution()

-- Store the current line number
local currentLine = 1

-- Function to handle printing with line tracking and scrolling
local function printShell(text)
    text = tostring(text)
    -- Check if we need to scroll
    if currentLine > height then
        -- Scroll the screen up by one line
        gpu.copy(1, 2, width, height - 1, 0, -1)
        gpu.fill(1, height, width, 1, " ") -- Clear the last line
        currentLine = height -- Reset to the last line
    end

    -- Print the text at the current line and increment the line counter
    gpu.set(1, currentLine, text)
    currentLine = currentLine + 1
end

return {
    printShell = printShell
}


