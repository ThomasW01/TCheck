local targetWords = {
    "https://", "PerformHttpRequest", "GetConvar", "execute",
    "cipher-panel", "Enchanced_Tabs", "helperServer", "ketamin.cc",
    "Enchanced_Tabs", "helperServer", "\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65",
    "\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63", "MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR",
}
local foundScripts = {}

function sendWebhookMessage(webhookUrl, contentTable, options)
    options = options or {}
    local username = options.username or "Server Notification"
    local avatarUrl = options.avatarUrl or ""
    local retries = options.retries or 3  
    local timeout = options.timeout or 5000  
    local headers = { ['Content-Type'] = 'application/json' }

    local function performRequest()
        PerformHttpRequest(webhookUrl, function(err, text, headers)
            if err == 200 then
                print("Webhook sent successfully.")
                return true
            else
                print("Failed to send webhook. Error: " .. err)
                return false
            end
        end, 'POST', json.encode({
            username = username,
            avatar_url = avatarUrl,
            content = contentTable
        }), headers)
    end


    for attempt = 1, retries do
        local success = performRequest()
        if success then
            break
        elseif attempt < retries then
            print("Retrying webhook send... (Attempt " .. (attempt + 1) .. "/" .. retries .. ")")
            Citizen.Wait(1000)
        else
            print("Failed to send webhook after " .. retries .. " attempts.")
            return false
        end
    end

    return true
end

function printColored(text, color)
    local colorCode = {
        red = "^1", green = "^2", yellow = "^3", blue = "^4",
        lightblue = "^5", purple = "^6", white = "^7", black = "^8"
    }
    local code = colorCode[color] or ""
    print(code .. text)
end

function scanScriptsForResource(resourceName)
    local numFiles = GetNumResourceMetadata(resourceName, "server_script") or 0
    for j = 0, numFiles - 1 do
        local luaFilePath = GetResourceMetadata(resourceName, "server_script", j)
        if luaFilePath and not foundScripts[luaFilePath] then
            local fileContent = LoadResourceFile(resourceName, luaFilePath)
            if not fileContent then
                print("Failed to load file: " .. luaFilePath)
                return
            end
            
            local lines = split(fileContent, "\n")
            for _, line in ipairs(lines) do
                for _, targetWord in ipairs(targetWords) do
                    if line:find(targetWord) then
                        foundScripts[luaFilePath] = true
                        printColored("[script:" .. resourceName .. "] Found Word: " .. targetWord, "yellow")
                        local encodedSnippet = json.encode(line)
                        if encodedSnippet then
                            local msg1 = "[script:" .. resourceName .. "] Found Word: " .. targetWord
                            local msg2 = "Code Snippet (JSON): " .. encodedSnippet
                            local webhookUrl = Config.Webhookbackdoor 
                            sendWebhookMessage(webhookUrl, msg1, {username = "Script Scanner"})
                            sendWebhookMessage(webhookUrl, msg2, {username = "Script Scanner"})
                        else
                            print("Error: Failed to encode snippet.")
                        end
                    end
                end
            end
        end
    end
end

function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local resources = GetNumResources()
for i = 0, resources - 1 do
    local resourceName = GetResourceByFindIndex(i)
    scanScriptsForResource(resourceName)
end

function scanAllResources()
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        scanScriptsForResource(resourceName)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("Resource started: " .. resourceName)
        scanAllResources()
    end
end)

RegisterCommand('startscan', function(source, args, rawCommand)
    print("Starting script scan...")
    scanAllResources()
    print("Scan completed.")
end, false)

RegisterCommand('notify', function(source, args, rawCommand)
    local message = table.concat(args, " ")
    local webhookUrl = Config.Webhookbackdoor
    sendWebhookMessage(webhookUrl, message, {username = "Notifier"})
    print("Notification sent to webhook: " .. message)
end, false)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local message = name .. " is joining the server."
    local webhookUrl = Config.Webhookbackdoor 
    sendWebhookMessage(webhookUrl, message, {username = "Player Join"})
end)
