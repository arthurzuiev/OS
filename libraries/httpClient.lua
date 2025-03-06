local internet = component.proxy(component.list("internet")())
local fs = component.proxy(component.list("filesystem")())

local function request(url, body, headers, timeout)
    url = tostring(url)
    local handle, err = internet.request(url, body, headers)
    
    if not handle then
        return nil, ("request failed: %s"):format(err or "unknown error")
    end

    local start = computer.uptime()
    
    while true do
        local status, err = handle:read(math.huge)
        
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

    handle.finishConnect()

    return handle
end

local function downloadFile(url, path)
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

return {
    request = request,
    downloadFile = downloadFile
}