--- Love2D Dev Tools — Bridge Module
--- Provides TCP communication between the running game and the VS Code extension.
---
--- Usage: require(".love2d-tools.bridge")
--- Or pass "bridge" as second arg: love . bridge

local socket = require("socket")

local Bridge = {}
Bridge._VERSION = "0.1.0"

local server = nil
local client = nil
local buffer = ""
local PORT = nil
local originalPrint = print

--- Find an available port and start listening.
local function startServer()
    server = socket.tcp()
    server:settimeout(0)

    -- Try configured port or find a free one
    local port = tonumber(os.getenv("LOVE2D_BRIDGE_PORT")) or 0
    local ok, err = server:bind("127.0.0.1", port)
    if not ok then
        originalPrint("[bridge] Failed to bind: " .. tostring(err))
        server:close()
        server = nil
        return
    end

    server:listen(1)
    local _, assignedPort = server:getsockname()
    PORT = assignedPort

    -- Write port to file so the extension can discover it.
    -- Use love.filesystem.getSource() for absolute path so the extension
    -- can find the file regardless of CWD.
    local sourceDir = love.filesystem.getSource()
    local portFile = sourceDir .. "/.love2d-tools-port"
    local f = io.open(portFile, "w")
    if f then
        f:write(tostring(PORT))
        f:close()
    end

    originalPrint("[bridge] Listening on port " .. PORT)
end

--- Send a JSON message to the connected client.
local function send(data)
    if not client then return end
    local ok, err = client:send(Bridge._encode(data) .. "\n")
    if not ok then
        originalPrint("[bridge] Send error: " .. tostring(err))
        client:close()
        client = nil
    end
end

--- Minimal JSON encoder (no external dependency).
function Bridge._encode(value)
    local t = type(value)
    if t == "string" then
        local escaped = value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
        -- Escape remaining control characters (U+0000–U+001F) as \uXXXX
        escaped = escaped:gsub('[%z\1-\31]', function(c)
            return string.format('\\u%04x', c:byte())
        end)
        return '"' .. escaped .. '"'
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        -- Check if array
        local isArray = #value > 0
        if isArray then
            local parts = {}
            for i = 1, #value do
                parts[i] = Bridge._encode(value[i])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(value) do
                if type(k) == "string" then
                    parts[#parts + 1] = Bridge._encode(k) .. ":" .. Bridge._encode(v)
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

--- Minimal JSON decoder.
function Bridge._decode(str)
    -- Use load to parse JSON (safe subset)
    local fn, err = load("return " .. str:gsub('null', 'nil'):gsub('%[', '{'):gsub('%]', '}'):gsub('"([^"]-)":', '["%1"]='))
    if fn then
        local ok, result = pcall(fn)
        if ok then return result end
    end
    return nil
end

--- Process a single command from the extension.
local function handleCommand(line)
    local msg = Bridge._decode(line)
    if not msg or not msg.cmd then return end

    local id = msg.id
    local response = { id = id, type = "response" }

    if msg.cmd == "reload" then
        local moduleName = msg.module
        if moduleName and package.loaded[moduleName] then
            local oldModule = package.loaded[moduleName]
            package.loaded[moduleName] = nil
            local ok, newModule = pcall(require, moduleName)
            if ok then
                -- If both old and new are tables, merge new keys/functions
                -- into the old table so existing references stay valid.
                if type(oldModule) == "table" and type(newModule) == "table" then
                    -- Carry runtime state (non-functions: fonts, images, counters
                    -- assigned in load() / init()) from old into new. Without this,
                    -- the new functions' closures point at the freshly-loaded module
                    -- table where these fields are nil, and draw() crashes.
                    for k, oldV in pairs(oldModule) do
                        if newModule[k] == nil and type(oldV) ~= "function" then
                            newModule[k] = oldV
                        end
                    end
                    -- Clear functions that were removed/renamed in the new version.
                    for k, oldV in pairs(oldModule) do
                        if newModule[k] == nil and type(oldV) == "function" then
                            oldModule[k] = nil
                        end
                    end
                    -- Mirror new keys back into old so external references see the update.
                    for k, v in pairs(newModule) do
                        oldModule[k] = v
                    end
                    -- Fix __index self-references:
                    -- If newModule.__index points to newModule itself,
                    -- redirect it to oldModule so metatables work correctly.
                    if rawget(oldModule, "__index") == newModule then
                        oldModule.__index = oldModule
                    end
                    -- Preserve metatable if new one has it
                    local mt = getmetatable(newModule)
                    if mt then
                        setmetatable(oldModule, mt)
                    end
                    -- Point package.loaded back to old table reference
                    package.loaded[moduleName] = oldModule
                end
                response.success = true
            else
                -- Restore old module on failure
                package.loaded[moduleName] = oldModule
                response.success = false
                response.error = tostring(newModule)
            end
        else
            response.success = false
            response.error = "Module not loaded: " .. tostring(moduleName)
        end

    elseif msg.cmd == "screenshot" then
        -- Save screenshot to a temp file; send the file path back.
        -- This avoids sending large base64 data over TCP.
        local sourceDir = love.filesystem.getSource()
        local screenshotPath = sourceDir .. "/.love2d-tools-screenshot.png"
        love.graphics.captureScreenshot(function(imageData)
            local ok2, err2 = pcall(function()
                local fileData = imageData:encode("png")
                local bytes = fileData:getString()
                local f = io.open(screenshotPath, "wb")
                if f then
                    f:write(bytes)
                    f:close()
                    send({ id = id, type = "response", success = true, data = screenshotPath })
                else
                    send({ id = id, type = "response", success = false, error = "Cannot write screenshot file" })
                end
            end)
            if not ok2 then
                send({ id = id, type = "response", success = false, error = tostring(err2) })
            end
        end)
        return -- Response sent asynchronously from callback

    elseif msg.cmd == "eval" then
        local code = msg.code
        if code then
            local fn, compileErr = load(code)
            if fn then
                local ok, result = pcall(fn)
                if ok then
                    response.success = true
                    response.data = tostring(result)
                else
                    response.success = false
                    response.error = tostring(result)
                end
            else
                response.success = false
                response.error = tostring(compileErr)
            end
        end

    elseif msg.cmd == "perf" then
        response.success = true
        response.data = {
            fps = love.timer.getFPS(),
            dt = love.timer.getDelta(),
            memory = collectgarbage("count"),
            drawCalls = love.graphics.getStats and love.graphics.getStats().drawcalls or 0,
            textureMemory = love.graphics.getStats and love.graphics.getStats().texturememory or 0,
        }

    elseif msg.cmd == "inspect" then
        -- Inspect a Lua table path and return its children
        local targetPath = msg.path or ""
        local target = _G

        if targetPath ~= "" then
            for part in targetPath:gmatch("[^%.]+") do
                if type(target) == "table" then
                    target = target[part]
                else
                    target = nil
                    break
                end
            end
        end

        if target == nil then
            response.success = false
            response.error = "Path not found: " .. targetPath
        elseif type(target) ~= "table" then
            response.success = true
            response.data = {}
        else
            local entries = {}
            local count = 0
            for k, v in pairs(target) do
                if count >= 200 then break end -- Limit entries
                local keyStr = tostring(k)
                -- Skip internal/bridge keys at root level
                if targetPath == "" and (keyStr:sub(1,1) == "_" and keyStr ~= "_G") then
                    -- skip private globals
                elseif targetPath == "" and (keyStr == "Bridge" or keyStr == "socket" or keyStr == "server" or keyStr == "client" or keyStr == "buffer") then
                    -- skip bridge internals
                else
                    entries[#entries + 1] = {
                        key = keyStr,
                        value = type(v) == "table" and ("{...}" ) or tostring(v),
                        type = type(v),
                        hasChildren = type(v) == "table",
                    }
                    count = count + 1
                end
            end
            -- Sort by key name
            table.sort(entries, function(a, b) return a.key < b.key end)
            response.success = true
            response.data = entries
        end

    elseif msg.cmd == "shader" then
        -- Receive GLSL shader code and compile it
        local code = msg.code
        if code then
            local ok, shaderOrErr = pcall(love.graphics.newShader, code)
            if ok then
                -- Store the shader globally so the game can use it
                _G._love2d_tools_shader = shaderOrErr
                response.success = true
                response.data = "Shader compiled successfully"
            else
                response.success = false
                response.error = tostring(shaderOrErr)
            end
        else
            response.success = false
            response.error = "No shader code provided"
        end

    elseif msg.cmd == "profile_start" then
        -- Start profiling using debug.sethook
        _G._love2d_tools_profile = {}
        _G._love2d_tools_profile_stack = {}
        local profile = _G._love2d_tools_profile
        local stack = _G._love2d_tools_profile_stack

        debug.sethook(function(event)
            local now = love.timer.getTime()
            local info = debug.getinfo(2, "nSl")
            if not info then return end

            local name = info.name or "(anonymous)"
            local source = info.short_src or "?"
            local line = info.linedefined or 0
            local key = source .. ":" .. line .. ":" .. name

            if event == "call" or event == "tail call" then
                stack[#stack + 1] = { key = key, startTime = now }
                if not profile[key] then
                    profile[key] = { name = name, source = source, line = line, calls = 0, totalTime = 0, selfTime = 0 }
                end
            elseif event == "return" then
                if #stack > 0 then
                    local frame = stack[#stack]
                    if frame.key == key then
                        local elapsed = now - frame.startTime
                        local entry = profile[key]
                        if entry then
                            entry.calls = entry.calls + 1
                            entry.totalTime = entry.totalTime + elapsed
                            entry.selfTime = entry.selfTime + elapsed
                        end
                        -- Subtract child time from parent's self time
                        stack[#stack] = nil
                        if #stack > 0 then
                            local parent = profile[stack[#stack].key]
                            if parent then
                                parent.selfTime = parent.selfTime - elapsed
                            end
                        end
                    end
                end
            end
        end, "cr")

        response.success = true
        response.data = "Profiling started"

    elseif msg.cmd == "profile_stop" then
        -- Stop profiling and return results
        debug.sethook()

        local profile = _G._love2d_tools_profile or {}
        local results = {}

        for _, entry in pairs(profile) do
            if entry.calls > 0 and entry.selfTime > 0.00001 then
                results[#results + 1] = {
                    name = entry.name,
                    source = entry.source,
                    line = entry.line,
                    calls = entry.calls,
                    totalTime = entry.totalTime,
                    selfTime = math.max(0, entry.selfTime),
                }
            end
        end

        -- Sort by self time descending
        table.sort(results, function(a, b) return a.selfTime > b.selfTime end)

        -- Limit to top 100 entries
        local trimmed = {}
        for i = 1, math.min(100, #results) do
            trimmed[i] = results[i]
        end

        _G._love2d_tools_profile = nil
        _G._love2d_tools_profile_stack = nil

        response.success = true
        response.data = trimmed

    elseif msg.cmd == "ping" then
        response.success = true
        response.data = "pong"
    else
        response.success = false
        response.error = "Unknown command: " .. tostring(msg.cmd)
    end

    send(response)
end

--- Base64 encoding.
function Bridge._base64(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return (data:gsub(".", function(x)
        local r, byte = "", x:byte()
        for i = 8, 1, -1 do
            r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == "1" and 2^(6-i) or 0)
        end
        return b:sub(c+1, c+1)
    end) .. ({"", "==", "="})[#data % 3 + 1]
end

--- Override print() to forward output to the extension.
function Bridge._hookPrint()
    print = function(...)
        local args = {...}
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(args[i])
        end
        local message = table.concat(parts, "\t")

        -- Still print to console
        originalPrint(...)

        -- Forward to extension
        send({
            type = "log",
            data = {
                level = "info",
                message = message,
                args = args,
            },
        })
    end
end

--- Poll for new connections and data. Call from love.update().
function Bridge.update()
    if not server then return end

    -- Accept new connections
    if not client then
        local newClient = server:accept()
        if newClient then
            newClient:settimeout(0)
            client = newClient
            originalPrint("[bridge] Client connected")
        end
    end

    -- Read data from client
    if client then
        while true do
            local line, err = client:receive("*l")
            if line then
                handleCommand(line)
            else
                if err == "closed" then
                    originalPrint("[bridge] Client disconnected")
                    client = nil
                end
                break
            end
        end
    end
end

--- Clean up on exit.
function Bridge.quit()
    if client then client:close() end
    if server then server:close() end
    local sourceDir = love.filesystem.getSource()
    os.remove(sourceDir .. "/.love2d-tools-port")
end

--- Initialize the bridge.
function Bridge.init()
    startServer()
    Bridge._hookPrint()

    -- Wrap love.run (the main loop) to inject Bridge.update() every frame.
    -- love.run is defined by Love2D's boot.lua before main.lua loads,
    -- so it's always available here. Games almost never override love.run,
    -- and even if they do, this wrap still works because it captures whatever
    -- love.run is at require-time (boot.lua's default).
    -- This avoids the problem of main.lua overwriting love.update / love.load hooks.
    local originalRun = love.run
    love.run = function()
        local step = originalRun()
        return function()
            Bridge.update()
            local result = step()
            if result then
                Bridge.quit()
            end
            return result
        end
    end
end

-- Auto-initialize when required
Bridge.init()

return Bridge
