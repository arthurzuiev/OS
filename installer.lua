-- installer.lua

local component = require("component")
local internet = require("internet")
local fs = require("filesystem")
local shell = require("shell")

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
        print("Failed to open file for writing: " .. path)
        return false
    end

    local content = response.readAll()
    file:write(content)
    file:close()

    print("File downloaded successfully to " .. path)
    return true
end

-- Function to get the list of files from the GitHub repository
local function getGitHubRepoFiles(repoUrl)
    local apiUrl = repoUrl .. "/contents"
    local response, err = internet.request(apiUrl)
    if not response then
        print("Failed to fetch repository contents: " .. err)
        return nil
    end

    local content = response.readAll()
    local files = {}
    for line in content:gmatch("[^\r\n]+") do
        local fileUrl = line:match('"download_url": "(.-)"')
        local fileName = line:match('"name": "(.-)"')
        if fileUrl and fileName then
            table.insert(files, {url = fileUrl, name = fileName})
        end
    end

    return files
end

-- Function to download all files in the repository
local function downloadRepoFiles(repoUrl, files)
    for _, file in ipairs(files) do
        local fileUrl = file.url
        local fileName = file.name
        local filePath = "/" .. fileName
        if not downloadFile(fileUrl, filePath) then
            print("Failed to download file: " .. fileName)
        end
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
    if not checkInternetAccess() then
        return
    end

    local repoUrl = "https://api.github.com/repos/arthurzuiev/OS"
    local files = getGitHubRepoFiles(repoUrl)

    if not files then
        return
    end

    downloadRepoFiles(repoUrl, files)
    runInit()
end

-- Run the installer
runInstaller()
