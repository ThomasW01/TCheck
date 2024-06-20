local QBCore = exports['qb-core']:GetCoreObject()
local json = require("json")

local Config = {
    ValidLicenses = {},
    ValidDiscordIds = {},
    WebhookUrl = "https://discord.com/api/webhooks/1251970288812294176/eHK5Wck1WekLQOsPALDP-GxDufB1yNNzYf4XQMh739W8Bl2B7Lm-yaTZQezJGpqRKkuU"
}

local function loadConfig()
    local jsonString = LoadResourceFile(GetCurrentResourceName(), "list.json")
    if not jsonString then
        print("Failed to load list.json")
        return
    end

    local jsonData = json.decode(jsonString)
    if not jsonData then
        print("Failed to parse list.json")
        return
    end

    Config.ValidLicenses = jsonData.ValidLicenses or {}
    Config.ValidDiscordIds = jsonData.ValidDiscordIds or {}
end

local function isLicenseValid(playerLicense)
    for _, validLicense in ipairs(Config.ValidLicenses) do
        if playerLicense == validLicense then
            return true
        end
    end
    return false
end

local function isDiscordIdValid(discordId)
    for _, validDiscordId in ipairs(Config.ValidDiscordIds) do
        if discordId == validDiscordId then
            return true
        end
    end
    return false
end

local function sendToWebhook(webhookUrl, data)
    local headers = {
      ['Content-Type'] = 'application/json'
    }
  
    local jsonData = json.encode(data)
    if not jsonData then
      print("Failed to encode data to JSON.")
      return
    end
  
    if PerformHttpRequest then
      PerformHttpRequest(webhookUrl, function(err, text, headers)
        if err ~= 200 then
          print('Error sending webhook:', err)
        else
          print('Webhook sent successfully:', text)
        end
      end, 'POST', jsonData, headers)
    else
      print("PerformHttpRequest is not available.")
    end
end

local function handleAddEntry(action, value)
    if action == "addLicense" then
      Config.ValidLicenses[#Config.ValidLicenses + 1] = value
    elseif action == "addDiscordId" then
      Config.ValidDiscordIds[#Config.ValidDiscordIds + 1] = value
    end
end

local function createEmbed(playerId, playerLicense, playerDiscordId, isValid)
    local color, statusText, title, statusIcon
    if isValid then
        color = 15158332 
        statusText = "The license and Discord ID are invalid."
        title = "❌ License and Discord ID Verification Failed"
        statusIcon = ":x:"
    else
        color = 3066993
        statusText = "The license or Discord ID is valid."
        title = "✅ License and Discord ID Verification Passed"
        statusIcon = ":white_check_mark:"
    end

    local serverName = GetConvar("sv_hostname")
    local serverIP = GetConvar("sv_endpointPrivacy")
    local playerName = GetPlayerName(playerId) or "Test Player"

    return {
        username = "License Check Bot",
        avatar_url = "https://your-avatar-url.com/avatar.png",
        embeds = {{
            title = title,
            description = "Player License and Discord ID Verification Result",
            fields = {
                { name = "🔗 Player ID", value = tostring(playerId), inline = true },
                { name = "📄 Player Name", value = playerName, inline = true },
                { name = "📀 License", value = playerLicense or "Test", inline = true },
                { name = "💿 Discord ID", value = playerDiscordId or "Test", inline = true },
                { name = "📊 Status", value = statusIcon .. " " .. statusText, inline = false },
                { name = "💻 Server Name", value = serverName, inline = true },
                { name = "📡 Server IP", value = serverIP, inline = true },
            },
            color = color,
            footer = {
                text = "License Check Bot",
                icon_url = "https://your-footer-icon-url.com/icon.png" 
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
end

local function isDirectory(path)
    if lfs then
        local attr = lfs.attributes(path)
        return attr and attr.mode == "directory"
    else
        print("LuaFileSystem not available for directory check.")
        return false
    end
end

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    sendToWebhook(Config.WebhookUrl, {
        action = "playerConnecting", 
        value = playerName,
    })

    local identifiers = GetPlayerIdentifiers(src)
    if not identifiers or #identifiers == 0 then
        deferrals.done("No identifiers found. Connection refused.")
        return
    end

    local playerLicense, playerDiscordId
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "license:") then
            playerLicense = identifier
        elseif string.match(identifier, "discord:") then
            playerDiscordId = identifier
        end
    end

    if not playerLicense or not playerDiscordId then
        deferrals.done("Required identifiers not found. Connection refused.")
        return
    end

    local isValid = isLicenseValid(playerLicense) or isDiscordIdValid(playerDiscordId)
    local data = createEmbed(src, playerLicense, playerDiscordId, isValid)
    sendToWebhook(Config.WebhookUrl, data)

    if isValid then
        deferrals.done()
    else
        deferrals.done()
    end
end)
