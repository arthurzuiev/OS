local githubClient = {}

githubClient.httpClient = require("httpClient")
githubClient.fs  = component.proxy(component.list("filesystem")())
githubClient.json = require("json")

githubclient.initClient = function(name, reponame, branch)
    githubclient.client = {}
    client.name = name
    client.reponame = reponame
    client.branch = branch or "master"
    client.gitapiurl = "https://api.github.com/repos/" .. name .. "/" .. reponame
    client.userrawdataurl = "https://raw.githubusercontent.com/" .. name .. "/" .. reponame .. "/" .. client.branch
    client.branch = "master"
    return client
end

github.ensureDirExists = function(filePath)
    local dir = fs.path(filePath)
    if not fs.exists(dir) then
        fs.makeDirectory(dir)
    end
end

githubClient.getRepoData = function(client)
    local req = githubClient.httpClient:request(githubClient.client.gitapiurl .. "/git/refs/heads/" .. client.branch)
    local data, _ = req:read(math.huge)

    githubClient.repo = {
        refs = githubClient.json.decode(data),
        commitData = refs.object.url,
        commit = json.decode(commitData),
        treeURL = commit.tree.url
    }

    return githubClient.repo
end

githubClient.downloadTree = function(treeURL, parentDir)
    parentDir = parentDir or ""
    local treeData = json.decode(githubClient.request(treeDataURL))

    for _, child in ipairs(treeData.tree) do
        local filename = parentDir .. "/" .. child.path

        if child.type == "tree" then
            -- It's a directory, so create it and recursively download its contents
            githubClient.ensureDiExists(filename)
            githubClient.downloadTree(child.url, filename)
        else
            -- It's a file, so download it and write it to the correct path
            githubClient.ensureDiExists(filename) -- Make sure the directory exists before writing the file
            
            local fileURL = "https://raw.githubusercontent.com/" .. githubClient.client.name .. "/" .. githubClient.client.repo .. "/" .. githubClient.client.branch .. "/" .. filename
            githubClient.httpClient.downloadFile(fileURL, filename)
        end
    end
end