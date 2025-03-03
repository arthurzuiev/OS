-- installer.lua

-- Function to check for internet access (modem availability)
local function checkInternetAccess()
    local component = require("component")
    local modem = component.modem
    if modem and modem.isOpen(1) then
        print("Internet access confirmed!")
        return true
    else
        print("Error: No internet access detected.")
        return false
    end
end

-- Function to download all files from GitHub repo
local function downloadFilesFromGithub(repoUrl, destination)
    local shell = require("shell")
    local wget = shell.execute("wget -r -np -nH --cut-dirs=3 -R index.html " .. repoUrl .. " -P " .. destination)
    if wget then
        print("Files successfully downloaded!")
        return true
    else
        print("Error: Failed to download files from GitHub.")
        return false
    end
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

    -- Step 2: Download files from GitHub repo
    local repoUrl = "https://github.com/arthurzuiev/OS.git"
    local destination = "/home/arthur/os/"
    if not downloadFilesFromGithub(repoUrl, destination) then
        return
    end

    -- Step 3: Run init.lua after download
    runInit()
end

-- Run the installer
runInstaller()
