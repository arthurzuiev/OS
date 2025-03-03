-- installer.lua

local component = require("component")
local shell = require("shell")
local fs = require("filesystem")
local internet = require("internet")

-- Function to check for internet access (internet card availability)
local function checkInternetAccess()
    local internetCard = component.internet
    if internetCard then
        print("Internet access confirmed!")
        return true
    else
        print("Error: No internet access detected. Please connect an internet card.")
        return false
    end
end

-- Function to download file from URL
local function downloadFile(url, path)
    local response, err = internet.request(url)
    if not response then
        print("Failed to download: " .. err)
        return false
    end

    local file = fs.open(path, "w")
    if not file then
        print("Failed to open file for writing.")
        return false
    end

    -- Read response and write to the file
    local content = response.readAll()
    file:write(content)
    file:close()

    print("File downloaded successfully to " .. path)
    return true
end

-- Function to run init.lua after installation
local function runInit()
    print("Running init.lua...")
    local success, result = pcall(require, "init")
    if not success then
        print("Error: Failed to run init.lua - " .. result)
    else
        print("init.lua executed successfully.")
    end
end

-- Main installer function
local function runInstaller()
    -- Step 1: Check internet access
    if not checkInternetAccess() then
        return
    end

    -- Step 2: Download the installer file from GitHub
    local repoUrl = "https://raw.githubusercontent.com/arthurzuiev/OS/main/installer.lua"
    local localPath = "/installer.lua"  -- Save in the root directory

    if not downloadFile(repoUrl, localPath) then
        return
    end

    -- Step 3: Run init.lua after download
    runInit()
end

-- Run the installer
runInstaller()
