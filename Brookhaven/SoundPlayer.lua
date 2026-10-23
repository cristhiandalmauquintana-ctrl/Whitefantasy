--// Froggy Hub - Brookhaven Sound Player (Custom ID Support)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_SOUND_CLEANUP then pcall(env.__BF_SOUND_CLEANUP) end

local Config = {
    Playing = false,
    SoundId = "1837879082", -- ID por defecto
    Volume = 5,
}
env.BF_SOUND_CONFIG = Config

local soundPart = nil
local sound = nil
local currentLoadedId = nil
local connections = {}

local function cleanupSound()
    if soundPart then
        soundPart:Destroy()
        soundPart = nil
        sound = nil
        currentLoadedId = nil
    end
end

local function playSound()
    cleanupSound()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Limpiamos el ID por si pegan el link completo o solo los números
    local cleanId = tostring(Config.SoundId):match("%d+")
    if not cleanId then return end -- Si no hay números, no hace nada
    currentLoadedId = "rbxassetid://" .. cleanId

    soundPart = Instance.new("Part")
    soundPart.Name = "FroggySoundPart"
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(1,1,1)
    soundPart.Position = char.HumanoidRootPart.Position
    soundPart.Parent = workspace

    sound = Instance.new("Sound")
    sound.SoundId = currentLoadedId
    sound.Volume = Config.Volume
    sound.Looped = false
    sound.Parent = soundPart
    sound:Play()
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Playing then
        cleanupSound()
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not root then
        cleanupSound()
        return
    end

    -- Si cambiamos el ID en el panel, reiniciamos el sonido
    local cleanId = tostring(Config.SoundId):match("%d+")
    local formattedId = cleanId and ("rbxassetid://" .. cleanId) or ""
    
    if not soundPart or not soundPart.Parent or not sound or not sound.IsPlaying or currentLoadedId ~= formattedId then
        playSound()
    else
        soundPart.Position = root.Position
        sound.Volume = Config.Volume
    end
end))

env.__BF_SOUND_CLEANUP = function()
    Config.Playing = false
    cleanupSound()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SOUND_CONFIG = nil
    env.__BF_SOUND_CLEANUP = nil
end
