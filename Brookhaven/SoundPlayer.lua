--// Froggy Hub - Brookhaven Sound Player (Global + Loop)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_SOUND_CLEANUP then pcall(env.__BF_SOUND_CLEANUP) end

local Config = {
    Playing = false,
    SoundId = "1837879082",
    Volume = 5,
    Loop = false, -- 🛠️ NUEVA OPCIÓN
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
    
    local cleanId = tostring(Config.SoundId):match("%d+")
    if not cleanId then return end
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
    sound.Looped = Config.Loop -- 🛠️ APLICAMOS EL BUCLE
    sound.Parent = soundPart
    sound:Play()
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Playing then cleanupSound(); return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then cleanupSound(); return end

    local cleanId = tostring(Config.SoundId):match("%d+")
    local formattedId = cleanId and ("rbxassetid://" .. cleanId) or ""
    
    if currentLoadedId ~= formattedId then playSound(); return end

    if soundPart then
        soundPart.Position = root.Position
        
        if sound then 
            sound.Volume = Config.Volume 
            -- 🛠️ Si el usuario cambia el toggle de Bucle en el panel, lo aplicamos en vivo
            if sound.Looped ~= Config.Loop then
                sound.Looped = Config.Loop
            end
            -- Si por alguna razon el sonido se detuvo y no está en bucle, lo reiniciamos
            if not sound.IsPlaying and not Config.Loop then
                playSound()
            end
        end
    end
end))

env.__BF_SOUND_CLEANUP = function()
    Config.Playing = false; cleanupSound()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SOUND_CONFIG = nil; env.__BF_SOUND_CLEANUP = nil
end
