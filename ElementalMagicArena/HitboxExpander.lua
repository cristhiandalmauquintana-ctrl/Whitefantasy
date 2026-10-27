--// Froggy Hub - ElementalMagicArena/HitboxExpander.lua (V10 - Auto-Limpiador de Fantasmas)
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
    if not expandedParts[part] then
        expandedParts[part] = { Size = part.Size, CanCollide = part.CanCollide, CanTouch = part.CanTouch, CanQuery = part.CanQuery, Massless = part.Massless, Transparency = part.Transparency, Color = part.Color }
    end
    pcall(function()
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        part.CanCollide = true 
        part.Massless = true                
        part.CanQuery = true 
        part.CanTouch = true
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
        if part:IsA("BasePart") then expandPart(part) end
    end
end

local function restoreCharacter(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then restorePart(part) end
    end
end

local function restoreAll()
    for part, _ in pairs(expandedParts) do 
        if part and part.Parent then restorePart(part) end 
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

-- 🔥 BUCLE DE LIMPIEZA DE FANTASMAS (Cada 2 segundos)
task.spawn(function()
    while task.wait(2) do
        if not Config.Enabled then continue end
        
        for part, data in pairs(expandedParts) do
            -- Si la parte ya no existe en el juego, la borramos de la lista
            if not part or not part.Parent then
                expandedParts[part] = nil
            else
                -- Si la parte pertenece a un Humanoid que ya murió o desapareció, la restauramos
                local hum = part.Parent:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    restorePart(part)
                end
            end
        end
    end
end)

-- Bucle principal
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
