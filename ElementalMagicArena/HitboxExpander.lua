--// Froggy Hub - HitboxExpander.lua (V5 - PvP + Zombies)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

-- CONFIGURACIÓN
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

local function isFriend(player)
    return false 
end

local function expandPart(part)
    if not expandedParts[part] then
        expandedParts[part] = {
            Size = part.Size, CanCollide = part.CanCollide, CanTouch = part.CanTouch,
            CanQuery = part.CanQuery, Massless = part.Massless,
            Transparency = part.Transparency, Color = part.Color
        }
    end

    pcall(function()
        -- Hacemos la parte gigante
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        
        -- PROPIEDADES ANTI-FÍSICA (Para que no te empujen)
        part.CanCollide = false 
        part.Massless = true                
        
        -- 🔥 LA CLAVE DEL DAÑO: Forzamos a que los golpes y roces detecten esta parte
        part.CanQuery = true 
        part.CanTouch = true
        
        -- VISUALES
        part.Transparency = Config.Transparency
        part.Color = Config.Color
    end)
end

local function restorePart(part)
    local data = expandedParts[part]
    if data then
        pcall(function()
            part.Size = data.Size
            part.CanCollide = data.CanCollide
            part.CanTouch = data.CanTouch
            part.CanQuery = data.CanQuery
            part.Massless = data.Massless
            part.Transparency = data.Transparency
            part.Color = data.Color
        end)
        expandedParts[part] = nil
    end
end

local function processCharacter(char)
    if not char then return end
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
        if part and part.Parent then
            restorePart(part)
        end
    end
    expandedParts = {}
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    table.insert(connections, player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if Config.Enabled then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local root = char:FindFirstChild("HumanoidRootPart")
            if myRoot and root and (root.Position - myRoot.Position).Magnitude <= 1000 then
                processCharacter(char)
            end
        end
    end))
end

for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))

-- 🛠️ El bucle principal
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        if next(expandedParts) then restoreAll() end
        return 
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- 1. Escanear JUGADORES (PvP)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - myRoot.Position).Magnitude <= 1000 then
                    if Config.IgnoreFriends and isFriend(player) then
                        restoreCharacter(player.Character)
                    else
                        processCharacter(player.Character)
                    end
                else
                    restoreCharacter(player.Character)
                end
            else
                restoreCharacter(player.Character)
            end
        end
    end

    -- 2. 🔥 ESCANEAR ZOMBIS Y NPCS (El nuevo parche)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                -- Filtramos para que solo agrande cosas que parezcan enemigos
                local name = obj.Name:lower()
                if name:find("zombie") or name:find("boss") or name:find("enemy") or name:find("dummy") then
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                    if root and (root.Position - myRoot.Position).Magnitude <= 150 then -- Rango de 150 studs
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
