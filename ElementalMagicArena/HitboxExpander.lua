--// Froggy Hub - Hitbox Expander (Elemental Magic Arena Edition)
--// Expande a jugadores y NPCs (Enemies) sin crashear la física.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 35,             -- 35 es perfecto para agarrar desde lejos sin crashear
    IgnoreFriends = true,
    Version = "v4.0"
}
env.BF_HITBOX_CONFIG = Config

local expandedParts = {}
local connections = {}

local function isFriend(player)
    local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    return ok and result
end

local function expandPart(part)
    if not part or expandedParts[part] then return end
    
    -- Guardar el estado original
    expandedParts[part] = { 
        Size = part.Size, 
        CanCollide = part.CanCollide, 
        Massless = part.Massless 
    }
    
    pcall(function()
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        part.CanCollide = false -- 🔥 Evita el crash de física
        part.Massless = true    -- 🔥 Evita que salgan volando
    end)
end

local function restorePart(part)
    if not part or not expandedParts[part] then return end
    local data = expandedParts[part]
    
    pcall(function()
        if part and part.Parent then
            part.Size = data.Size
            part.CanCollide = data.CanCollide
            part.Massless = data.Massless
        end
    end)
    expandedParts[part] = nil
end

local function processCharacter(char)
    if not char then return end
    -- Expande TODO el cuerpo (Torso, Brazos, Piernas, Cabeza)
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
    -- Limpieza de partes rotas (Jugadores que mueren o NPCs que desaparecen)
    for part, _ in pairs(expandedParts) do
        if not part or not part.Parent then
            restorePart(part)
        end
    end

    if not Config.Enabled then
        if next(expandedParts) ~= nil then
            restoreAll()
        end
        return
    end

    -- 1. Expandir Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not (Config.IgnoreFriends and isFriend(player)) then
                    processCharacter(player.Character)
                end
            else
                restoreCharacter(player.Character)
            end
        end
    end

    -- 2. Expandir NPCs (Carpeta Enemies)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, npc in ipairs(enemiesFolder:GetChildren()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                processCharacter(npc)
            else
                restoreCharacter(npc)
            end
        end
    end
end))

-- Si tu personaje muere, restaurar todo
table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function()
    restoreAll()
end))

env.__BF_HITBOX_CLEANUP = function()
    Config.Enabled = false
    restoreAll()
    for _, c in ipairs(connections) do c:Disconnect() end
    env.BF_HITBOX_CONFIG = nil
    env.__BF_HITBOX_CLEANUP = nil
end
