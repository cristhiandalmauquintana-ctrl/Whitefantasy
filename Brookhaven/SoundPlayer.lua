--// Froggy Hub - Brookhaven Sound Player
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_SOUND_CLEANUP then pcall(env.__BF_SOUND_CLEANUP) end

local Config = {
    Playing = false,
    SoundId = "rbxassetid://1837879082", -- ID de ejemplo (cámbialo por tu audio de 3 min)
    Volume = 5,
}
env.BF_SOUND_CONFIG = Config

local soundPart = nil
local sound = nil
local connections = {}

local function cleanupSound()
    if soundPart then
        soundPart:Destroy()
        soundPart = nil
        sound = nil
    end
end

local function playSound()
    cleanupSound()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Creamos una parte invisible que sigue al jugador
    soundPart = Instance.new("Part")
    soundPart.Name = "FroggySoundPart"
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(1,1,1)
    soundPart.Position = char.HumanoidRootPart.Position
    soundPart.Parent = workspace

    sound = Instance.new("Sound")
    sound.SoundId = Config.SoundId
    sound.Volume = Config.Volume
    sound.Looped = false
    sound.Parent = soundPart
    sound:Play()
end

-- Bucle para mantener la parte pegada al jugador y verificar si el sonido sigue vivo
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

    -- Si la parte no existe o el sonido se detuvo, lo volvemos a crear
    if not soundPart or not soundPart.Parent or not sound or not sound.IsPlaying then
        playSound()
    else
        -- Mantenemos la parte en la posición del jugador
        soundPart.Position = root.Position
    end

    -- Actualizamos el volumen en tiempo real por si el slider se mueve
    if sound then
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
