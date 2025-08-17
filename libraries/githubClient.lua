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
    shell:print("URL: "..url.." (type: "..type(url)..")")

    shell:print("getting handle")
    local handle, err = httpClient.request(url)
    shell:print("got handle (type: "..type(handle).."), err (type: "..type(err)..")")
    if not handle then error(err) end
    shell:print("no errors, reading data")

    local data = ""
    shell:print("handle.read type: "..type(handle.read))
    local chunk, readErr = handle.read(handle, 16384)
    shell:print("first chunk type: "..type(chunk)..", first readErr type: "..type(readErr))
    while chunk do
        data = data .. chunk
        chunk, readErr = handle.read(handle, 16384)
    end
    shell:print("finished reading, closing handle")
    handle.close(handle)
    shell:print("Handle closed, data ready (type data: "..type(data)..")")

    local refs = json.decode(data)
    shell:print("Refs type: "..type(refs))
    if type(refs) ~= "table" or not refs[1] or not refs[1].object then
        error("Unexpected refs data structure")
    end

    local commitURL = refs[1].object.url
    shell:print("Fetching commit: "..commitURL.." (type: "..type(commitURL)..")")

    local commitHandle, err2 = httpClient.request(commitURL)
    shell:print("commitHandle type: "..type(commitHandle)..", err2 type: "..type(err2))
    if not commitHandle then error(err2) end

    local commitData, _ = commitHandle.read(commitHandle, 16384)
    shell:print("commitData type: "..type(commitData))
    commitHandle.close(commitHandle)

    local commit = json.decode(commitData)
    shell:print("commit type: "..type(commit)..", commit.tree type: "..type(commit.tree))
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
    shell:print("Fetching tree: "..treeURL.." (type: "..type(treeURL)..")")

    local handle, err = httpClient.request(treeURL)
    shell:print("tree handle type: "..type(handle)..", err type: "..type(err))
    if not handle then error(err) end

    local treeDataRaw, _ = handle.read(handle, 16384)
    shell:print("treeDataRaw type: "..type(treeDataRaw))
    handle.close(handle)

    local treeData = json.decode(treeDataRaw)
    shell:print("treeData type: "..type(treeData))

    for _, child in ipairs(treeData.tree) do
        shell:print("child type: "..type(child)..", child.path type: "..type(child.path)..", child.type: "..tostring(child.type))
        local filename = parentDir.."/"..child.path

        if child.type == "tree" then
            githubClient.ensureDirExists(filename)
            githubClient.downloadTree(child.url, filename, shell)
        else
            githubClient.ensureDirExists(filename)
            shell:print("Downloading file: "..filename)
            local fileURL = githubClient.client.rawBase .. "/" .. filename
            shell:print("fileURL type: "..type(fileURL))
            local ok, err2 = httpClient.downloadFile(fileURL, filename)
            shell:print("download result ok: "..tostring(ok)..", err: "..tostring(err2))
        end
    end
end


return githubClient
