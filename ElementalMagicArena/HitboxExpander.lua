--// Froggy Hub - HitboxExpander.lua (V13 - Optimizado para Daño Pasivo)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

if not getgenv().BF_HITBOX_CONFIG then
    getgenv().BF_HITBOX_CONFIG = {
        Enabled = false,
        Size = 35,             
        Transparency = 0.7,
        Color = Color3.fromRGB(255, 0, 0),
        IgnoreFriends = true,
    }
end
local Config = getgenv().BF_HITBOX_CONFIG
local expandedParts = {}
local connections = {}

local function expandPart(part)
    if not part or not part:IsA("BasePart") then return end
    
    -- Guardamos los datos originales si es la primera vez
    if not expandedParts[part] then
        expandedParts[part] = { 
            Size = part.Size, 
            CanCollide = part.CanCollide, 
            Transparency = part.Transparency, 
            Color = part.Color, 
            Massless = part.Massless 
        }
    end

    -- 🔥 EL TRUCO: Si ya tiene el tamaño correcto, no lo tocamos (Evita saturar el servidor)
    local targetSize = Vector3.new(Config.Size, Config.Size, Config.Size)
    if part.Size ~= targetSize then
        pcall(function()
            part.Size = targetSize
            -- Mantenemos tu lógica: Atravesar la caja pero que la espada haga daño
            part.CanCollide = false 
            part.Massless = true                
            part.CanQuery = true 
            part.CanTouch = true
            
            part.Transparency = Config.Transparency
            part.Color = Config.Color
        end)
    end
end

local function restorePart(part)
    local data = expandedParts[part]
    if data then
        pcall(function()
            part.Size = data.Size
            part.CanCollide = data.CanCollide
            part.Transparency = data.Transparency
            part.Color = data.Color
            part.Massless = data.Massless
        end)
        expandedParts[part] = nil
    end
end

local function processCharacter(char)
    if not char then return end
    -- Expandimos TODO el cuerpo como en tu V5 original
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            expandPart(part)
        end
    end
end

local function restoreCharacter(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            restorePart(part)
        end
    end
end

local function restoreAll()
    for part, _ in pairs(expandedParts) do 
        if part and part.Parent then restorePart(part) end 
    end
    expandedParts = {}
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        if next(expandedParts) then restoreAll() end
        return 
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Escanear Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - myRoot.Position).Magnitude <= 1000 then
                    processCharacter(player.Character)
                else
                    restoreCharacter(player.Character)
                end
            else
                restoreCharacter(player.Character)
            end
        end
    end

    -- Escanear NPCs / Zombis / Esqueletos
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local name = obj.Name:lower()
                if name:find("zombie") or name:find("boss") or name:find("enemy") or name:find("dummy") or name:find("skeleton") or name:find("esqueleto") then
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                    if root and (root.Position - myRoot.Position).Magnitude <= 250 then 
                        processCharacter(obj)
                    else
                        restoreCharacter(obj)
                    end
                end
            end
        end
    end
end))

env.__BF_HITBOX_CLEANUP = function()
    restoreAll()
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
end
