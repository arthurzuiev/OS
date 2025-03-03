-- Required Libraries
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
    print(msg)
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

local function httpRequest(url)
    local success, response = internet.request(url)
    if not success then
        throwError("Failed to fetch data from: " .. url, GENERAL_ERR)
    end
    local data = ""
    for chunk in response do
        data = data .. chunk
    end
    return data
end

local function downloadRepoTree(treeDataURL, parentDir)
    parentDir = parentDir or ""
    local treeData = json.decode(httpRequest(treeDataURL))
    for _, child in ipairs(treeData.tree) do
        local filename = parentDir .. "/" .. child.path
        if child.type == "tree" then
            downloadRepoTree(child.url, filename)
        else
            shell.execute('rm -f "' .. filename .. '"')
            local fileData = httpRequest("https://raw.githubusercontent.com/" .. config.git.owner .. "/" .. config.git.repo .. "/main/" .. filename)
            local file = fs.open(filename, "w")
            file:write(fileData)
            file:close()
        end
    end
end

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
