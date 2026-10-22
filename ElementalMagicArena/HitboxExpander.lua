--// Froggy Hub - Hitbox Expander V5 (Live Force - Full Body)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 35,             
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
    -- Si no está en la tabla, guardamos sus propiedades originales
    if not expandedParts[part] then
        expandedParts[part] = {
            Size = part.Size,
            CanCollide = part.CanCollide,
            CanTouch = part.CanTouch,
            CanQuery = part.CanQuery,
            Massless = part.Massless,
            Transparency = part.Transparency,
            Color = part.Color
        }
    end
    
    -- 🔥 LA CLAVE: Forzamos la aplicación constantemente
    pcall(function()
        -- Si el servidor lo reseteó, lo volvemos a agrandar
        if part.Size ~= Vector3.new(Config.Size, Config.Size, Config.Size) then
            part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        end
        
        part.CanCollide = false 
        part.Massless = true
        part.CanQuery = true 
        part.CanTouch = true
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
            part.CanQuery = data.CanQuery
            part.Massless = data.Massless
            part.Transparency = data.Transparency
            part.Color = data.Color
        end
    end)
    
    expandedParts[part] = nil
end

local function processCharacter(char)
    if not char then return end
    -- Escaneamos todo el cuerpo
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

-- 🛠️ Escuchar cuando un jugador nuevo entra o respawnea
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5) -- Dar tiempo a que las partes carguen
        if Config.Enabled then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local root = char:FindFirstChild("HumanoidRootPart")
            if myRoot and root and (root.Position - myRoot.Position).Magnitude <= 1000 then
                processCharacter(char)
            end
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        if next(expandedParts) then restoreAll() end
        return 
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

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
