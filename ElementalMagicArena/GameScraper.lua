--// Deep Blue Hub - ElementalMagicArena/GameScraper.lua (Total Data Scraper V2)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SCRAPER_CLEANUP then pcall(env.__BF_SCRAPER_CLEANUP) end

local Config = {
    Enabled = true,
    -- 🔥 REEMPLAZA ESTO CON TU URL DE WEBHOOK REAL 🔥
    WebhookURL = "https://discord.com/api/webhooks/1572743421867589812/mtt4U43zUs2xA0eVXSQS02ay4ta5ohZjEfaKphwRWM_7Xmf4_Q73OXz29b-n5DhCkfmL",
    ScanInterval = 300
}
env.BF_SCRAPER_CONFIG = Config

local running = true

-- Función para enviar la petición HTTP compatible con ejecutores móviles
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
        -- Fallback a HttpService por si el ejecutor permite
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
        
        -- Evitar escanear el personaje del jugador local
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

-- Limita y formatea para evitar el error 400 de Discord (max 1000 caracteres por campo)
local function formatList(arr, maxItems)
    local seen = {}
    local clean = {}
    for _, v in ipairs(arr) do
        if not seen[v] then
            seen[v] = true
            table.insert(clean, v)
        end
    end
    
    if #clean == 0 then return "Ninguno" end
    
    local text = ""
    local count = 0
    for _, v in ipairs(clean) do
        if count >= maxItems or #text > 800 then
            text = text .. "\n... y " .. (#clean - count) .. " más."
            break
        end
        text = text .. "• " .. v .. "\n"
        count = count + 1
    end
    return text
end

local function sendToDiscord()
    if not Config.WebhookURL or Config.WebhookURL:find("TU_WEBHOOK_AQUI") then 
        warn("[Scraper] Falta la URL del Webhook.")
        return 
    end

    local wData = scanWorkspace()
    local rsData = scanReplicatedStorage()
    local playersData = scanPlayers()

    local fields = {}
    local function addField(name, text)
        if text and text ~= "Ninguno" and #text > 0 then
            table.insert(fields, { name = name, value = "```\n" .. text .. "```", inline = false })
        end
    end

    addField("Drops Encontrados", formatList(wData.Drops, 15))
    addField("NPCs / Enemigos", formatList(wData.NPCs, 10))
    addField("Herramientas (Tools)", formatList(wData.Tools, 10))
    addField("Honeypots", formatList(wData.Others, 10))
    addField("RemoteEvents (RS)", formatList(rsData.RemoteEvents, 15))
    
    local pStrings = {}
    for _, p in ipairs(playersData) do
        table.insert(pStrings, p.Name .. (p.Health and (" [HP:"..p.Health.."]") or ""))
    end
    addField("Jugadores", formatList(pStrings, 15))

    local embed = {
        title = "Deep Blue Hub - Scraper Report",
        description = "**JobId:** " .. tostring(game.JobId) .. "\n**PlaceId:** " .. tostring(game.PlaceId),
        color = 3447003,
        fields = fields,
        footer = { text = "Scanned at " .. os.date("%Y-%m-%d %H:%M:%S") }
    }

    sendWebhook(Config.WebhookURL, {
        username = "Deep Blue Scraper",
        embeds = { embed }
    })
end

task.spawn(function()
    task.wait(5) -- Esperar a que el juego cargue
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
