local component = require("component")
local internet = require("internet")
local fs = require("filesystem")
local shell = require("shell")
local json = nil

local config = {
    git = {
        name = "arthurzuiev",
        repo = "OS"
    }
}

local gitAPIreposURL = "https://api.github.com/repos/"

-- constants
local NO_RESOURCE_ERR = 6
local GENERAL_ERR = 1

-- utility
local function throwError(msg, errCode)
    error(msg)
    os.exit(errCode)
end

local function installJSON()
    shell.execute('mkdir /lib')
    shell.execute('wget -fq "https://raw.githubusercontent.com/rater193/OpenComputers-1.7.10-Base-Monitor/master/lib/json.lua" "/lib/json.lua"')
    json = require("json")
end

local function confirmInternetAcess()
    -- in case it is used on floppy discs
    local internetCard = component.isAvailable("internet")
    if internetCard == false then
        print("No internet acess detected.")
        print("Aborting installation.")

        throwError("No internet acess detected.", NO_RESOURCE_ERR)
        return false
    end

    return true
end

-- core functionality 
local function stringifyResponse(response)
    local res = ""
    local resp = response()

    while(resp~=nil) do
        res = ret..tostring(resp)
        resp = responce()
    end

    return res
end

local function httpRequst(url)
    local stringifiedResponse = nil

    local success, response = internet.request(url)
    if (success) then
        stringifiedResponse = stringifyResponse(response)
    end

    return stringifiedResponse
end

local function downloadRepoTree(treeDataURL, parentdir)
    if(not parentdir) then parentdir = "" end

    local treeData = json.decode(httpRequst(treeDataURL))

    for _, child in pairs(treedata.tree) do
        --os.sleep(0.1) TODO: check if this is necessary
        local filename = parentdir.."/"..tostring(child.path)

        if(child.type=="tree") then
            downloadRepoTree(child.url, filename)
        else
            shell.execute('rm -f "'..tostring(filename)..'"')
            local repodata = httpRequst("https://raw.githubusercontent.com/"..tostring(config.git.name).."/"..tostring(config.git.repo).."/master/"..tostring(filename))
            local file = fs.open(filename, "w")
            file:write(repodata)
            file:close()
        end
    end
end

local function getTreedataURL()
    local mainData = httpRequst(gitbaseURL..tostring(config.git.name).."/"..tostring(config.git.repo).."/master")

    if (mainData) then
        local git = json.decode(data)[1].object
        local gitsha = git.sha
        local giturl = git.url

        local commitdata = httpRequst(gitcommit)

        if (commitdata) then 
            local commitdatatree = json.decode(commitdata).tree

            return commitdatatree.url
        else
            throwError("Failed to get commit data.", GENERAL_ERR)
        end
    else
        throwError("Failed to get tree data.", GENERAL_ERR)
    end
end

-- init functionality 
local function runInit()
    -- running the init.lua that was installed in tge process
    shell.execute("init.lua")
end

local function install()
    print("Installer started.")
    print()

    print("--Preparation...")
    -----------------------
    confirmInternetAcess()
    installJSON()
    -----------------------
    print("--Preparation end.")


    print()


    print("Intallation initiated.")
    -----------------------
    local treeDataURL = getTreedataURL()
    downloadRepoTree(treeDataURL)
    -----------------------
    print("Installation complete.")

    -- now run all installed shit
    shell.execute("cls")
    runInit()
end

install()