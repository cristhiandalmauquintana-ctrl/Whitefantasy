--// Froggy Hub - Hitbox Expander V4 (Full Body Aggressive - RESTAURADO)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 35,             -- 35 es el tamaño perfecto que tenías
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
    expandedParts[part] = { Size = part.Size, CanCollide = part.CanCollide, Massless = part.Massless, Transparency = part.Transparency, Color = part.Color }
    pcall(function()
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        part.CanCollide = false 
        part.Massless = true
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
            part.Massless = data.Massless
            part.Transparency = data.Transparency
            part.Color = data.Color
        end
    end)
    expandedParts[part] = nil
end

local function processCharacter(char)
    if not char then return end
    -- EXPANDIMOS TODO EL CUERPO
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
    for part, _ in pairs(expandedParts) do restorePart(part) end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then restoreAll() return end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                if (root.Position - myRoot.Position).Magnitude <= 1000 and not (Config.IgnoreFriends and isFriend(player)) then
                    processCharacter(player.Character)
                else
                    restoreCharacter(player.Character)
                end
            end
        end
    end
end))

env.__BF_HITBOX_CLEANUP = function()
    restoreAll()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_HITBOX_CONFIG = nil
    env.__BF_HITBOX_CLEANUP = nil
end
