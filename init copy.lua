-- INSTALLER bios friendly (ಥ﹏ಥ) 
local gpu
local internet
local fs

-- configurables
local packages = {
    json = "https://raw.githubusercontent.com/rater193/OpenComputers-1.7.10-Base-Monitor/master/lib/json.lua",
    httpClient = "https://raw.githubusercontent.com/arthurzuiev/OS/main/libraries/httpClient.lua",
    githubClient = "https://raw.githubusercontent.com/arthurzuiev/OS/main/libraries/githubClient.lua",
}

-- utils
function sleep(seconds)
    computer.pullSignal(seconds)
end

local function require(moduleName)
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

    return func()
end

-- integrated modules
shell = {
    -- Internal state
    _screenWidth = 80, -- Default width, will be updated dynamically
    _screenHeight = 25, -- Default height, will be updated dynamically
    _cursorX = 1,
    _cursorY = 1,
    _lastLine = 1,

    -- Initialize shell (call once at start)
    init = function(self)
        if not gpu then
            error("GPU component is required!")
        end
        self._screenWidth, self._screenHeight = gpu.getResolution()
        self._cursorX, self._cursorY = 1, 1
        self:clear()
    end,

    -- Clears the screen
    clear = function(self)
        gpu.fill(1, 1, self._screenWidth, self._screenHeight, " ")
        self._cursorX, self._cursorY = 1, 1
    end,

    -- Prints text with scrolling support
    print = function(self, text)
        text = tostring(text)

        for i = 1, #text do
            local char = text:sub(i, i)
            if char == "\n" or self._cursorX > self._screenWidth then
                self._cursorX = 1
                self._cursorY = self._cursorY + 1
            end
            if self._cursorY > self._screenHeight then
                self:scroll()
                self._cursorY = self._screenHeight
            end
            if char ~= "\n" then
                gpu.set(self._cursorX, self._cursorY, char)
                self._cursorX = self._cursorX + 1
            end
        end
        self._cursorY = self._cursorY + 1
        self._cursorX = 1
        if self._cursorY > self._screenHeight then
            self:scroll()
            self._cursorY = self._screenHeight
        end
        sleep(1)
    end,

    -- Scrolls the screen up
    scroll = function(self)
        gpu.copy(1, 2, self._screenWidth, self._screenHeight - 1, 0, -1)
        gpu.fill(1, self._screenHeight, self._screenWidth, 1, " ")
    end,

    -- Gets user input (with backspace support)
    input = function(self, prompt)
        if prompt then self:print(prompt) end
        local buffer = ""
        local cursorPos = 1
        local blink = true
        local lastBlink = os.clock() 
    
        while true do
            local event, _, char = coroutine.yield()
            
            if event == "key_down" then
                char = string.char(char)
    
                if char == "\n" or char == "\r" then -- Enter key
                    self:print("")
                    return buffer
                elseif char == "\b" then -- Backspace
                    if #buffer > 0 then
                        buffer = buffer:sub(1, -2)
                        cursorPos = cursorPos - 1
                        gpu.set(self._cursorX - 1, self._cursorY, " ") -- Clear character
                        gpu.set(self._cursorX, self._cursorY, " ") 
                        self._cursorX = math.max(1, self._cursorX - 1)
                    end
                elseif #char == 1 then -- Regular character
                    buffer = buffer .. char
                    gpu.set(self._cursorX, self._cursorY, char)
                    self._cursorX = self._cursorX + 1
                    cursorPos = cursorPos + 1
                end
    
                lastBlink = os.clock() -- Reset cursor blink timer
                gpu.set(self._cursorX, self._cursorY, "_") -- Show cursor
            end
        end
    end
}

httpClient = {
    request = function(url, body, headers, timeout)
        local handle, err = internet.request(url, body, headers)
        
        if not handle then
            return nil, ("request failed: %s"):format(err or "unknown error")
        end
    
        local start = computer.uptime()
        
        while true do
            local status, err = handle.finishConnect()
            
            if status then 
                break
            end
            
            if status == nil then
                return nil, ("request failed: %s"):format(err or "unknown error")
            end
            
            if computer.uptime() >= start + timeout then
                handle.close()
    
                return nil, "request failed: connection timed out"
            end
            
            sleep(0.05) 
        end
    
        return handle
    end,

    downloadFile = function(url, path)
        local handle, err = httpClient.request(url, nil, nil, 5)
        
        if not handle then
            return nil, ("download failed: %s"):format(err)
        end
    
        local file = fs.open(path, "w")

        -- read handle and write to file
        while true do
            local data, err = handle.read(math.huge)
            
            if not data then
                if err then
                    return nil, ("download failed: %s"):format(err)
                end
                break
            end
            
            fs.write(file, data)
        end

        fs.close(file)

        return true
    end
}

local function check_component(cname, name)
    -- Check if the component is nil (missing)
    if not cname then
        error("This program requires the component '" .. tostring(name) .. "' to run. The requirement is not fulfilled.")
    end
end


local function init_installer()
    -- INIT COMPONENTS--------------

    local gpu_component = component.list("gpu")()
    local internet_component = component.list("internet")()
    local filesystem_component = component.list("filesystem")()

    check_component(gpu_component, "gpu")
    check_component(internet_component, "Internet Card")
    check_component(filesystem_component, "Filesystem")

    gpu = component.proxy(gpu_component)
    internet = component.proxy(internet_component)
    fs = component.proxy(filesystem_component)

    -- INIT COMPONENTS END---------
    -- Initialize shell at the start
    shell:init()
    shell:print("init...")
    
    _G.require = require

    -- Display intro message
    shell:print("init complete.")
    --sleep(3)
    shell:clear()
end

local function package_installation()
    shell:init()
    shell:print("installing packages...")
    -- INSTALL PACKAGES--------------

    -- make sure /libraries/ directory exists
    if not fs.exists("/libraries") then
        fs.makeDirectory("/libraries")
    end

    -- install this shit
    for name, url in pairs(packages) do
        shell:print("    Downloading: " .. name .. ".lua")
        local status, err = httpClient.downloadFile(url, "/libraries/" .. name .. ".lua")
        if not status then
            shell:print("Failed to download " .. name .. ": " .. err)
        end
    end

    shell:print("package instalation comeplete.")
    
    --sleep(3)
    shell:clear()
end

local function OSInstall()
    shell:print("hi from install function")
    local gitClient = require("githubClient")
    
    shell:print("init client")
    sleep(1)
    gitClient.initClient("arthurzuiev", "OS", "main")
    
    shell:print("get linkey")
    sleep(1)

    local repoData = gitClient.getRepoData(shell)
    local treeURL = repoData.treeURL
    local parentDir = ""

    shell:print(treeURL)

    --sleep(5)

    gitClient.downloadTree(treeURL, parentDir, shell)
end

init_installer()
package_installation()
OSInstall()

shell:input("Installation done. Do you want to reboot? (not yet... in developemnt)> ")
