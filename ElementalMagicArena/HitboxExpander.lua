--// Froggy Hub - Hitbox Expander V4 (Full Body Aggressive)
--// Expande todas las partes del cuerpo, desactiva colisiones y fuerza la detección de golpes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 35,             -- 35 es una locura, cubre todo el cuerpo
    Transparency = 0.7,
    Color = Color3.fromRGB(255, 0, 0),
    IgnoreFriends = true,
}

env.BF_HITBOX_CONFIG = Config

local expandedParts = {}
local connections = {}

local function isFriend(player)
    local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    return ok and result
end

local function expandPart(part)
    if expandedParts[part] then return end
    
    -- Guardamos las propiedades originales
    expandedParts[part] = {
        Size = part.Size,
        CanCollide = part.CanCollide,
        CanTouch = part.CanTouch,
        Massless = part.Massless,
        Transparency = part.Transparency,
        Color = part.Color
    }
    
    pcall(function()
        -- Hacemos la parte gigante
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        
        -- PROPIEDADES ANTI-CRASH Y ANTI-FÍSICA
        part.CanCollide = false 
        part.Massless = true
        
        -- 🔥 LA CLAVE: Forzamos a que los golpes y rayos detecten esta parte
        part.CanQuery = true 
        part.CanTouch = true
        
        -- VISUALES:
        part.Transparency = Config.Transparency
        part.Color = Config.Color
    end)
end

local function restorePart(part)
    if not expandedParts[part] then return end
    
    local data = expandedParts[part]
    pcall(function()
        if part and part.Parent then
            part.Size = data.Size
            part.CanCollide = data.CanCollide
            part.CanTouch = data.CanTouch
            part.Massless = data.Massless
            part.Transparency = data.Transparency
            part.Color = data.Color
        end
    end)
    
    expandedParts[part] = nil
end

local function processCharacter(char)
    if not char then return end
    -- Escaneamos TODO el personaje (Cabeza, Torso, Brazos, Piernas, Accesorios)
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
        restorePart(part)
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then
        restoreAll()
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Escanear jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and root then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist <= 1000 and not (Config.IgnoreFriends and isFriend(player)) then
                    processCharacter(player.Character)
                else
                    restoreCharacter(player.Character)
                end
            else
                restoreCharacter(player.Character)
            end
        end
    end

    -- Escanear NPCs
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("NPCs")
    if enemiesFolder then
        for _, npc in ipairs(enemiesFolder:GetChildren()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = npc:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - myRoot.Position).Magnitude <= 1000 then
                    processCharacter(npc)
                else
                    restoreCharacter(npc)
                end
            end
        end
    end
end))

-- Limpieza
table.insert(connections, RunService.Stepped:Connect(function()
    for part, _ in pairs(expandedParts) do
        if not part or not part.Parent then
            restorePart(part)
        end
    end
end))

env.__BF_HITBOX_CLEANUP = function()
    restoreAll()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_HITBOX_CONFIG = nil
    env.__BF_HITBOX_CLEANUP = nil
end
