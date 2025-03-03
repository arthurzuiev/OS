-- installer.lua

local component = require("component")
local shell = require("shell")
local fs = require("filesystem")
local internet = require("internet")
local json = require("json")  -- To parse the GitHub API JSON response

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

-- Function to get the list of files from the GitHub repository
local function getGitHubRepoFiles(repoUrl)
    local apiUrl = repoUrl .. "/contents"  -- GitHub API endpoint to get the contents of the repo
    local response, err = internet.request(apiUrl)
    if not response then
        print("Failed to fetch repository contents: " .. err)
        return nil
    end

    local content = response.readAll()
    local files, err = json.decode(content)  -- Parse JSON response
    if not files then
        print("Failed to parse GitHub response: " .. err)
        return nil
    end

    return files
end

-- Function to download all files in the repository
local function downloadRepoFiles(repoUrl, files)
    for _, file in ipairs(files) do
        local fileUrl = file.download_url
        local filePath = "/" .. file.name  -- Save in the root directory
        if file.type == "file" then
            -- Download and save the file
            if not downloadFile(fileUrl, filePath) then
                print("Failed to download file: " .. file.name)
            end
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
    -- Step 1: Check internet access
    if not checkInternetAccess() then
        return
    end

    -- Step 2: Get the list of files in the GitHub repository
    local repoUrl = "https://api.github.com/repos/arthurzuiev/OS"  -- GitHub API URL for your repo
    local files = getGitHubRepoFiles(repoUrl)

    if not files then
        return
    end

    -- Step 3: Download all files in the repository
    downloadRepoFiles(repoUrl, files)

    -- Step 4: Run init.lua after download
    runInit()
end

-- Run the installer
runInstaller()
