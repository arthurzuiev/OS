local httpClient = require("httpClient")
local fs = component.proxy(component.list("filesystem")())
local json = require("json")

local githubClient = {}

function githubClient.initClient(user, repo, branch)
    branch = branch or "main"
    githubClient.client = {
        user = user,
        repo = repo,
        branch = branch,
        gitapiurl = "https://api.github.com/repos/"..user.."/"..repo,
        rawBase = "https://raw.githubusercontent.com/"..user.."/"..repo.."/"..branch
    }
end

function githubClient.ensureDirExists(path)
    local dir = fs.path(path)
    if not fs.exists(dir) then fs.makeDirectory(dir) end
end

function githubClient.getRepoData(shell)
    shell:print("Fetching repo refs...")
    local url = githubClient.client.gitapiurl .. "/git/refs/heads/" .. githubClient.client.branch
    shell:print("URL: "..url)

    local handle, err = httpClient.request(url)
    if not handle then error(err) end

    local data, _ = handle:read(2^30)
    handle:close()

    shell:print("Data type: "..type(data))
    local refs = json.decode(data)
    if type(refs) ~= "table" or not refs[1] or not refs[1].object then
        error("Unexpected refs data structure")
    end

    local commitURL = refs[1].object.url
    shell:print("Fetching commit: "..commitURL)

    local commitHandle, err2 = httpClient.request(commitURL)
    if not commitHandle then error(err2) end

    local commitData, _ = commitHandle:read(math.huge)
    commitHandle:close()

    local commit = json.decode(commitData)
    if not commit.tree or not commit.tree.url then
        error("Unexpected commit data structure")
    end

    githubClient.repo = {
        refs = refs,
        commit = commit,
        treeURL = commit.tree.url
    }

    return githubClient.repo
end

function githubClient.downloadTree(treeURL, parentDir, shell)
    shell:print("Fetching tree: "..treeURL)

    local handle, err = httpClient.request(treeURL)
    if not handle then error(err) end

    local treeDataRaw, _ = handle:read(math.huge)
    handle:close()

    local treeData = json.decode(treeDataRaw)

    for _, child in ipairs(treeData.tree) do
        local filename = parentDir.."/"..child.path

        if child.type == "tree" then
            githubClient.ensureDirExists(filename)
            githubClient.downloadTree(child.url, filename, shell)
        else
            githubClient.ensureDirExists(filename)
            shell:print("Downloading file: "..filename)
            local fileURL = githubClient.client.rawBase .. "/" .. filename
            local ok, err2 = httpClient.downloadFile(fileURL, filename)
            if not ok then shell:print("Failed: "..tostring(err2)) end
        end
    end
end

return githubClient
