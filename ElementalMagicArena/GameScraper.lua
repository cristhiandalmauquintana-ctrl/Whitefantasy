--// Deep Blue Hub - ElementalMagicArena/GameScraper.lua (Total Data Scraper)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SCRAPER_CLEANUP then pcall(env.__BF_SCRAPER_CLEANUP) end

local Config = {
    Enabled = true,
    -- ⚠️ REEMPLAZA ESTO CON TU URL DE WEBHOOK REAL ⚠️
    WebhookURL = "https://discord.com/api/webhooks/1572743421867589812/mtt4U43zUs2xA0eVXSQS02ay4ta5ohZjEfaKphwRWM_7Xmf4_Q73OXz29b-n5DhCkfmL",
    ScanInterval = 300 -- 5 minutos
}
env.BF_SCRAPER_CONFIG = Config

local running = true

local function scanWorkspace()
    local data = { Drops = {}, NPCs = {}, Tools = {}, Prompts = {}, Others = {} }
    
    -- Escanear absolutamente todo en el Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local className = obj.ClassName
        local name = obj.Name
        
        -- Evitar escanear el personaje del jugador local para no ensuciar los datos
        if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then continue end

        if obj:IsA("Tool") or obj:IsA("HopperBin") then
            table.insert(data.Tools, name)
        elseif obj:IsA("ProximityPrompt") then
            table.insert(data.Prompts, name .. " (" .. obj.Parent.Name .. ")")
        elseif obj:IsA("Model") or obj:IsA("BasePart") then
            local lowerName = string.lower(name)
            if lowerName:find("soul") or lowerName:find("alma") or lowerName:find("diamond") or lowerName:find("gem") or lowerName:find("drop") or lowerName:find("reward") then
                table.insert(data.Drops, name)
            elseif obj.Parent and obj.Parent.Name == "Enemies" then
                table.insert(data.NPCs, name)
            elseif lowerName:find("honeypot") or lowerName:find("anticheat") or lowerName:find("trap") then
                table.insert(data.Others, "[HONEYPOT] " .. name)
            end
        end
    end
    return data
end

local function scanReplicatedStorage()
    local data = { RemoteEvents = {}, Modules = {}, Assets = {} }
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(data.RemoteEvents, obj.Name)
        elseif obj:IsA("ModuleScript") then
            table.insert(data.Modules, obj.Name)
        end
    end
    return data
end

local function scanPlayers()
    local data = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local info = { Name = p.Name, DisplayName = p.DisplayName }
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then info.Health = math.floor(hum.Health) end
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then info.Pos = tostring(root.Position) end
            end
            table.insert(data, info)
        end
    end
    return data
end

local function cleanArray(arr, maxItems)
    -- Elimina duplicados y limita la cantidad para no romper el límite de 2000 caracteres de Discord
    local seen = {}
    local clean = {}
    for _, v in ipairs(arr) do
        if not seen[v] then
            seen[v] = true
            table.insert(clean, v)
        end
    end
    if #clean > maxItems then
        local extra = #clean - maxItems
        local trimmed = {}
        for i = 1, maxItems do table.insert(trimmed, clean[i]) end
        table.insert(trimmed, "... y " .. extra .. " más.")
        return trimmed
    end
    return clean
end

local function sendToDiscord()
    if not Config.WebhookURL or Config.WebhookURL:find("TU_WEBHOOK_AQUI") then return end

    local workspaceData = scanWorkspace()
    local rsData = scanReplicatedStorage()
    local playersData = scanPlayers()

    local fields = {}
    local function addField(name, value)
        if value and #value > 0 then
            table.insert(fields, {
                name = name,
                value = "```\n" .. table.concat(cleanArray(value, 20), "\n") .. "\n```",
                inline = false
            })
        end
    end

    addField("Drops Encontrados", workspaceData.Drops)
    addField("NPCs / Enemigos", workspaceData.NPCs)
    addField("Herramientas (Tools)", workspaceData.Tools)
    addField("Honeypots / Trampas", workspaceData.Others)
    addField("Proximity Prompts", workspaceData.Prompts)
    addField("RemoteEvents (ReplicatedStorage)", rsData.RemoteEvents)

    -- Formatear jugadores
    local pStrings = {}
    for _, p in ipairs(playersData) do
        local str = p.Name
        if p.Health then str = str .. " | HP: " .. p.Health end
        if p.Pos then str = str .. " | Pos: " .. p.Pos end
        table.insert(pStrings, str)
    end
    addField("Jugadores en el Servidor", pStrings)

    local embed = {
        title = "Deep Blue Hub - Scraper Report",
        description = "**Servidor JobId:** " .. game.JobId .. "\n**PlaceId:** " .. game.PlaceId,
        color = 3447003, -- Color azul
        fields = fields,
        footer = {
            text = "Scanned at " .. os.date("%Y-%m-%d %H:%M:%S")
        }
    }

    -- Enviar petición HTTP
    local payload = HttpService:JSONEncode({
        username = "Deep Blue Scraper",
        embeds = { embed }
    })

    pcall(function()
        HttpService:PostAsync(Config.WebhookURL, payload, Enum.HttpContentType.ApplicationJson)
    end)
end

task.spawn(function()
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
