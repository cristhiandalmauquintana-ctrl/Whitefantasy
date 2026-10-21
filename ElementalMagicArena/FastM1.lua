--// Froggy Hub - Fast M1 (Auto Clicker + Animation Bypass)
--// Exclusivo para juegos con baja seguridad (Elemental Magic Arena).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_FASTM1_CLEANUP then pcall(env.__BF_FASTM1_CLEANUP) end

local Config = {
    Enabled = false,
    ClickDelay = 0.05,       -- Tiempo entre clics (0.05 = 20 clics por segundo)
    BypassAnimations = true  -- Cancelar animación para atacar más rápido
}
env.BF_FASTM1_CONFIG = Config

local connections = {}
local lastClick = 0

-- Función para cancelar animaciones de ataque
local function cancelAttackAnimations(char)
    if not Config.BypassAnimations or not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- Buscar animaciones que tengan que ver con ataques y detenerlas
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local name = string.lower(track.Name) or ""
        local assetName = track.Animation and string.lower(track.Animation.Name) or ""
        
        if string.find(name, "attack") or string.find(name, "punch") or string.find(name, "slash") or string.find(name, "m1") or
           string.find(assetName, "attack") or string.find(assetName, "punch") or string.find(assetName, "slash") then
            track:Stop(0) -- Detener instantáneamente
        end
    end
end

-- Bucle de Auto-Click
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    
    local now = os.clock()
    if now - lastClick < Config.ClickDelay then return end
    lastClick = now

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- 1. Cancelar animación para romper el cooldown
    cancelAttackAnimations(char)

    -- 2. Simular el clic izquierdo
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end))

env.__BF_FASTM1_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_FASTM1_CONFIG = nil
    env.__BF_FASTM1_CLEANUP = nil
end

print("[Froggy Hub] Fast M1 (Ratatata) cargado.")
