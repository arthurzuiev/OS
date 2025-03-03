local component = require("component")

local function confirmInternetAcess()
    local internetCard = component.isAvailable("internet")
    if internetCard == false then
        print("This program requires internet access to download the necessary files.")
        print("Please insert a network card and try again.")
        return false
    end

    return true
end

local function downloadFile()
end

local function downloadOSFiles()
end

local function install()
    confirmInternetAcess()
    downloadOSFiles()
end

install()