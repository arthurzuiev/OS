local internet = component.proxy(component.list("internet")())
local fs = component.proxy(component.list("filesystem")())

local function sleep(seconds)
    computer.pullSignal(seconds)
end

local function request(url, body, headers, timeout)
    timeout = timeout or 5
    local handle, err = internet.request(url, body, headers)
    if not handle then
        return nil, ("request failed: %s"):format(err or "unknown error")
    end

    local start = computer.uptime()

    -- Wait for connection to finish
    while true do
        local ok, connErr = handle:finishConnect()
        if ok then break end
        if connErr then return nil, ("request failed: %s"):format(connErr) end
        if computer.uptime() - start > timeout then
            handle.close()
            return nil, "request failed: connection timed out"
        end
        sleep(0.05)
    end

    return handle
end

local function downloadFile(url, path)
    local handle, err = request(url, nil, nil, 10)
    if not handle then
        return nil, ("download failed: %s"):format(err)
    end

    local file = fs.open(path, "w")
    if not file then
        handle.close()
        return nil, "failed to open file for writing"
    end

    -- Read full response
    while true do
        local chunk, readErr = handle:read(math.huge)
        if chunk then
            fs.write(file, chunk)
        elseif readErr then
            fs.close(file)
            handle.close()
            return nil, ("download failed: %s"):format(readErr)
        else
            break
        end
    end

    fs.close(file)
    handle.close()
    return true
end

return {
    request = request,
    downloadFile = downloadFile
}
