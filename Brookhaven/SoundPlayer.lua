--// Froggy Hub - Brookhaven Sound Player (Global + Loop + Debug)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_SOUND_CLEANUP then pcall(env.__BF_SOUND_CLEANUP) end

local Config = {
    Playing = false,
    SoundId = "1837879082",
    Volume = 5,
    Loop = false,
}
env.BF_SOUND_CONFIG = Config

local soundPart, sound, currentLoadedId = nil, nil, nil
local connections = {}

local function cleanupSound()
    if soundPart then soundPart:Destroy(); soundPart, sound = nil, nil; currentLoadedId = nil end
end

local function playSound()
    cleanupSound()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Limpiamos el string para sacar solo los números
    local cleanId = tostring(Config.SoundId):match("%d+")
    if not cleanId then warn("[Froggy] ⚠️ ID de audio inválido.") return end
    currentLoadedId = "rbxassetid://" .. cleanId

    soundPart = Instance.new("Part")
    soundPart.Name = "FroggySoundPart"
    soundPart.Anchored = true; soundPart.CanCollide = false
    soundPart.Transparency = 1; soundPart.Size = Vector3.new(1,1,1)
    soundPart.Position = char.HumanoidRootPart.Position
    soundPart.Parent = workspace

    sound = Instance.new("Sound")
    sound.SoundId = currentLoadedId
    sound.Volume = Config.Volume
    sound.Looped = Config.Loop
    sound.Parent = soundPart
    
    -- Verificamos si el audio cargó
    sound.Loaded:Connect(function()
        print("[Froggy] ✅ Audio cargado con éxito: " .. currentLoadedId)
    end)
    
    sound:Play()
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Playing then cleanupSound(); return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then cleanupSound(); return end

    local cleanId = tostring(Config.SoundId):match("%d+")
    local formattedId = cleanId and ("rbxassetid://" .. cleanId) or ""
    
    -- Si el ID cambió, reiniciamos
    if currentLoadedId ~= formattedId then playSound(); return end

    if soundPart then
        soundPart.Position = root.Position
        if sound then 
            sound.Volume = Config.Volume 
            if sound.Looped ~= Config.Loop then sound.Looped = Config.Loop end
        end
    end
end))

env.__BF_SOUND_CLEANUP = function()
    Config.Playing = false; cleanupSound()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SOUND_CONFIG = nil; env.__BF_SOUND_CLEANUP = nil
end
