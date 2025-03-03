-- Required Libraries wget -fq "https://raw.githubusercontent.com/arthurzuiev/OS/main/installer.lua" "/installer.lua"
local component = require("component")
local internet = require("internet")
local fs = require("filesystem")
local shell = require("shell")
local json = nil

-- Configuration
local config = {
    git = {
        owner = "arthurzuiev",  -- GitHub username
        repo = "OS"             -- Repository name
    }
}

-- Constants
local NO_INTERNET_ERR = 6
local GENERAL_ERR = 1

-- Utility Functions
local function throwError(msg, errCode)
    error(msg)
    os.exit(errCode)
end

local function installJSON()
    if not fs.exists("/lib/json.lua") then
        shell.execute('wget -fq "https://raw.githubusercontent.com/rater193/OpenComputers-1.7.10-Base-Monitor/master/lib/json.lua" "/lib/json.lua"')
    end
    json = require("json")
end

local function confirmInternetAccess()
    if not component.isAvailable("internet") then
        throwError("No internet access detected.", NO_INTERNET_ERR)
    end
end

-- Utility Function to Fetch Data
local function httpRequest(url)
    local success, response = pcall(function() return internet.request(url) end)
    
    if not success then
        throwError("Failed to fetch data from: " .. url, GENERAL_ERR)
    end
    
    local data = ""
    for chunk in response do
        data = data .. chunk
    end
    
    -- Check if the data is empty (potentially an empty file)
    if data == "" then
        throwError("The file at " .. url .. " is empty or does not contain valid data.", GENERAL_ERR)
    end
    
    return data
end

-- Function to Ensure Directory Exists
local function ensureDirectoryExists(filePath)
    local dir = fs.path(filePath)
    if not fs.exists(dir) then
        fs.makeDirectory(dir)
    end
end

-- Function to Download Repo Tree
local function downloadRepoTree(treeDataURL, parentDir)
    parentDir = parentDir or ""
    local treeData = json.decode(httpRequest(treeDataURL))

    for _, child in ipairs(treeData.tree) do
        local filename = parentDir .. "/" .. child.path
        print("Processing: " .. filename)

        if child.type == "tree" then
            -- It's a directory, so create it and recursively download its contents
            ensureDirectoryExists(filename)
            downloadRepoTree(child.url, filename)
        else
            -- It's a file, so download it and write it to the correct path
            ensureDirectoryExists(filename) -- Make sure the directory exists before writing the file
            
            local fileData = httpRequest("https://raw.githubusercontent.com/" .. config.git.owner .. "/" .. config.git.repo .. "/main/" .. filename)
            if fileData == "" then
                print("Warning: File is empty: " .. filename)
            else
                -- Proceed with downloading and saving the file
                shell.execute('rm -f "' .. filename .. '"')
                
                -- Open the file and write to it
                local file, err = io.open(filename, "w")
                if not file then
                    print("Error: Failed to open file for writing: " .. err)
                else
                    file:write(fileData)
                    file:close()
                end
            end
        end
    end
end


-- Function to Get Tree Data URL
local function getTreeDataURL()
    local refsData = httpRequest("https://api.github.com/repos/" .. config.git.owner .. "/" .. config.git.repo .. "/git/refs/heads/main")
    local refs = json.decode(refsData)
    local commitData = httpRequest(refs.object.url)
    local commit = json.decode(commitData)
    return commit.tree.url
end

-- Installation Process
local function install()
    print("Installer started.\n")
    confirmInternetAccess()
    installJSON()
    print("Preparation complete.\n")

    print("Installation initiated.")
    local treeDataURL = getTreeDataURL()
    downloadRepoTree(treeDataURL)
    print("Installation complete.\n")
end

-- Run Installer
install()
