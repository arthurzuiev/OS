local githubClient = {}

githubClient.httpClient = require("httpClient")
githubClient.fs  = component.proxy(component.list("filesystem")())
githubClient.json = require("json")

githubClient.initClient = function(name, reponame, branch)
    githubClient.client = {}
    githubClient.client.name = name
    githubClient.client.reponame = reponame
    githubClient.client.branch = branch or "master"
    githubClient.client.gitapiurl = "https://api.github.com/repos/" .. name .. "/" .. reponame
    githubClient.client.userrawdataurl = "https://raw.githubusercontent.com/" .. name .. "/" .. reponame .. "/" .. githubClient.client.branch
    return githubClient.client
end

githubClient.ensureDirExists = function(filePath)
    local dir = fs.path(filePath)
    if not fs.exists(dir) then
        fs.makeDirectory(dir)
    end
end

githubClient.getRepoData = function(shell)
    shell:print("Fetching repo data...")
    local apiurl = githubClient.client.gitapiurl
    local additionURL = "/git/refs/heads/"..githubClient.client.branch

    local url = apiurl .. additionURL
    urlW = tostring(url)
    shell:print("URL: " .. url)
    local req, err = githubClient.httpClient:request(url)
    if err then
        error(err.." | " .. url)
    end
    shell:print("Request successful, reading data...")
    local data, _ = req:read(math.huge)
    shell:print("Data type: " .. type(data))
    shell:print("Raw Data: " .. tostring(data))

   local refs = githubClient.json.decode(data)
    -- refs is an array, take the first element
    local firstRef = refs[1]
    if not firstRef or not firstRef.object then
        error("Unexpected API response structure")
    end

    local commitURL = firstRef.object.url
    local commitDataReq, err = githubClient.httpClient:request(commitURL)
    if not commitDataReq then error(err) end

    local commitData, _ = commitDataReq:read(math.huge)
    local commit = githubClient.json.decode(commitData)
    local treeURL = commit.tree.url

    local treeURL = commit.tree.url

    githubClient.repo = {
        refs = refs,
        commitData = commitData,
        commit = commit,
        treeURL = treeURL
    }


    return githubClient.repo
end

githubClient.downloadTree =  function(treeURL, parentDir, shell)
    parentDir = parentDir or ""
    shell:print("Fething download data...")

    local treeData = githubClient.json.decode(
        githubClient.httpClient:request(treeURL):read(math.huge)
    )

    shell:print("Downloading:")
    for _, child in ipairs(treeData.tree) do
        local filename = parentDir .. "/" .. child.path

        if child.type == "tree" then
            -- It's a directory, so create it and recursively download its contents
            githubClient.ensureDirExists(filename)
            githubClient.downloadTree(child.url, filename)
        else
            -- It's a file, so download it and write it to the correct path
            githubClient.ensureDirExists(filename) -- Make sure the directory exists before writing the file
            shell:print("    " .. filename)
            local fileURL = "https://raw.githubusercontent.com/" .. githubClient.client.name .. "/" .. githubClient.client.reponame .. "/" .. githubClient.client.branch .. "/" .. filename
            githubClient.httpClient.downloadFile(fileURL, filename)
        end
    end
end

return githubClient