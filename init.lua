-- variables
local gpu = component.proxy(component.list("gpu")())  -- Access the GPU component
local fs = component.proxy(component.list("filesystem")()) -- Access the Filesystem component really big changes

-- graphics config
local initResolutionX = 50
local initResolutionY = 15
local currLine = 0
local clearonNext = false

-- boot sequence config
local seqDelay = 0.1
local seuqnceCount = 0

-- sys check
local function checkComponent(component, name)
    if not component then
        error(name.." not found!")
    end
end

-- preinit
checkComponent(gpu, "GPU")

local function gd_clearLine(line)
    gpu.set(1, line, string.rep(" ", initResolutionX))
end

local function gd_clearScreen()
    for i = 1, initResolutionY do
        gd_clearLine(i)
    end
end

local function gd_displayMessage(text)
    if clearonNext then
        gd_clearScreen()
        clearonNext = false
    end

    currLine = currLine + 1
    gpu.set(1,currLine , text)

    if currLine + 1 > initResolutionY then
        currLine = 0
        clearonNext = true
    end
end

-- other (time - other library like function)
local function time_sleep(seconds)
    local startTime = computer.uptime()
    while computer.uptime() - startTime < seconds do
        computer.pullSignal(1)
    end
end

-- core functions
local function openFile(path)
    local file
    local handle, path = fs.open(path, "r")

    if not handle then
        gd_displayMessage("reopening: "..path)
        local handle = openFile(path)
        time_sleep(1)
    end

    return handle
end

local function boot_the_loader(loader)
    local path = "/boot/" .. loader .. ".lua"

    local handle openFile(path)

    local code = ""
    repeat
        local chunk = fs.read(handle, math.huge) -- Read full file
        if chunk then code = code .. chunk end
    until not chunk

    fs.close(handle)

    local func, loadErr = load(code, "=" .. loader)

    if not func then
        error("Error loading loader " .. loader .. ": " .. loadErr)
    end

    gd_displayMessage(path)

    return func
end


-- main function
local function bootloader()
    gd_displayMessage("Boot init.")
    
    for seq = 0, seuqnceCount do
        local loader = boot_the_loader("boot0" .. seq)
        --loader.load()
        time_sleep(seqDelay)
    end

    computer.beep(440, 0.5)
end


-- ONINIT
gpu.setResolution(initResolutionX, initResolutionY)
gd_clearScreen()

time_sleep(2)
bootloader()

-- TEMP haltprevent : replace with main kernel loop
while true do
    computer.pullSignal()
end
