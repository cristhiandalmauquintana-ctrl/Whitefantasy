--// Deep Blue Hub - ElementalMagicArena/GameScraper.lua (Total Data Scraper V3)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SCRAPER_CLEANUP then pcall(env.__BF_SCRAPER_CLEANUP) end

local Config = {
    Enabled = true,
    WebhookURL = "https://discord.com/api/webhooks/1572743421867589812/mtt4U43zUs2xA0eVXSQS02ay4ta5ohZjEfaKphwRWM_7Xmf4_Q73OXz29b-n5DhCkfmL",
    ScanInterval = 50
}
env.BF_SCRAPER_CONFIG = Config

local running = true

local function sendWebhook(url, payload)
    local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
    if requestFunc then
        requestFunc({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    else
        pcall(function()
            HttpService:PostAsync(url, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end)
    end
end

local function scanWorkspace()
    local data = { Drops = {}, NPCs = {}, Tools = {}, Prompts = {}, Others = {} }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name
        local lowerName = string.lower(name)
        if not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
            if obj:IsA("Tool") or obj:IsA("HopperBin") then
                table.insert(data.Tools, name)
            elseif obj:IsA("ProximityPrompt") then
                table.insert(data.Prompts, name .. " (" .. tostring(obj.Parent) .. ")")
            elseif obj:IsA("Model") or obj:IsA("BasePart") then
                if lowerName:find("soul") or lowerName:find("alma") or lowerName:find("diamond") or lowerName:find("gem") or lowerName:find("drop") or lowerName:find("reward") then
                    table.insert(data.Drops, name)
                elseif obj.Parent and obj.Parent.Name == "Enemies" then
                    table.insert(data.NPCs, name)
                elseif lowerName:find("honeypot") or lowerName:find("anticheat") or lowerName:find("trap") then
                    table.insert(data.Others, "[HONEYPOT] " .. name)
                end
            end
        end
    end
    return data
end

local function scanReplicatedStorage()
    local data = { RemoteEvents = {} }
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(data.RemoteEvents, obj.Name)
        end
    end
    return data
end

local function scanPlayers()
    local data = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local info = { Name = p.Name }
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then info.Health = math.floor(hum.Health) end
            end
            table.insert(data, info)
        end
    end
    return data
end

-- Elimina duplicados
local function unique(arr)
    local seen = {}
    local clean = {}
    for _, v in ipairs(arr) do
        if not seen[v] then
            seen[v] = true
            table.insert(clean, v)
        end
    end
    return clean
end

-- 🔥 NUEVA FUNCIÓN: Divide la lista en bloques para que Discord no la corte
local function addChunkedFields(fields, title, arr)
    local list = unique(arr)
    if #list == 0 then return end
    
    local chunkSize = 30 -- Cuántos items caben cómodamente en un field de Discord
    local totalChunks = math.ceil(#list / chunkSize)
    
    for i = 1, totalChunks do
        local chunkText = ""
        local startIdx = (i - 1) * chunkSize + 1
        local endIdx = math.min(i * chunkSize, #list)
        
        for j = startIdx, endIdx do
            chunkText = chunkText .. "• " .. list[j] .. "\n"
        end
        
        local fieldName = title .. (totalChunks > 1 and (" [" .. i .. "/" .. totalChunks .. "]") or "")
        table.insert(fields, {
            name = fieldName,
            value = "```\n" .. chunkText .. "```",
            inline = false
        })
    end
end

local function sendToDiscord()
    if not Config.WebhookURL or Config.WebhookURL:find("TU_WEBHOOK_AQUI") then return end

    local wData = scanWorkspace()
    local rsData = scanReplicatedStorage()
    local playersData = scanPlayers()

    local fields = {}
    
    addChunkedFields(fields, "Drops Encontrados", wData.Drops)
    addChunkedFields(fields, "NPCs / Enemigos", wData.NPCs)
    addChunkedFields(fields, "Herramientas (Tools)", wData.Tools)
    addChunkedFields(fields, "Honeypots", wData.Others)
    addChunkedFields(fields, "Proximity Prompts", wData.Prompts)
    addChunkedFields(fields, "RemoteEvents (RS)", rsData.RemoteEvents)
    
    local pStrings = {}
    for _, p in ipairs(playersData) do
        table.insert(pStrings, p.Name .. (p.Health and (" [HP:"..p.Health.."]") or ""))
    end
    addChunkedFields(fields, "Jugadores", pStrings)

    -- Discord permite máximo 25 fields por embed. Si hay más, cortamos (rara vez pasará)
    if #fields > 25 then
        local newFields = {}
        for i = 1, 25 do table.insert(newFields, fields[i]) end
        fields = newFields
    end

    local embed = {
        title = "Deep Blue Hub - Full Scraper Report",
        description = "**JobId:** " .. tostring(game.JobId) .. "\n**PlaceId:** " .. tostring(game.PlaceId),
        color = 3447003,
        fields = fields,
        footer = { text = "Total Remotes detectados: " .. tostring(#unique(rsData.RemoteEvents)) }
    }

    sendWebhook(Config.WebhookURL, {
        username = "Deep Blue Scraper",
        embeds = { embed }
    })
end

task.spawn(function()
    task.wait(5)
    while running do
        if Config.Enabled then
            pcall(sendToDiscord)
        end
        task.wait(Config.ScanInterval)
    end
end)

env.__BF_SCRAPER_CLEANUP = function()
    running = false
    env.BF_SCRAPER_CONFIG = nil
    env.__BF_SCRAPER_CLEANUP = nil
end
