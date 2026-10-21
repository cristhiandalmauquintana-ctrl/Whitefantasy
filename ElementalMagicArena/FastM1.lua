--// Froggy Hub - Fast M1 + Hitbox Expander (Siempre Activo)
--// Agranda la hitbox del enemigo y le da "ratatata" sin parar.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local env = (getgenv and getgenv()) or _G
if env.__BF_FASTM1_CLEANUP then pcall(env.__BF_FASTM1_CLEANUP) end

local Config = {
    Enabled = false,
    ClickDelay = 0.05,
    ExpandHitbox = true,
    HitboxSize = 15 -- Tamaño de la hitbox (No muy grande para no crashear)
}
env.BF_FASTM1_CONFIG = Config

local connections = {}
local lastClick = 0
local currentTargetPart = nil
local originalSize = nil

-- Función para encontrar al enemigo más cercano
local function getClosestEnemy()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closestPart = nil
    local shortestDist = 50 -- Rango de búsqueda para M1 (corto)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist < shortestDist then
                    closestPart = root
                    shortestDist = dist
                end
            end
        end
    end
    return closestPart
end

-- Función para expandir la hitbox del enemigo
local function updateHitbox(targetPart)
    if not Config.ExpandHitbox then return end
    
    if currentTargetPart ~= targetPart then
        -- Restaurar la hitbox anterior
        if currentTargetPart and currentTargetPart.Parent and originalSize then
            pcall(function() currentTargetPart.Size = originalSize end)
        end
        
        currentTargetPart = targetPart
        if currentTargetPart then
            originalSize = currentTargetPart.Size
            pcall(function()
                -- Expandimos solo el HumanoidRootPart
                currentTargetPart.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
            end)
        end
    end
end

-- Bypass de animación
local function cancelAnimations(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if string.find(string.lower(track.Name), "attack") or string.find(string.lower(track.Name), "punch") then
                track:Stop(0)
            end
        end
    end
end

-- Loop principal
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then
        if currentTargetPart and currentTargetPart.Parent and originalSize then
            pcall(function() currentTargetPart.Size = originalSize end)
            currentTargetPart = nil
        end
        return
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then return end

    -- 1. Encontrar enemigo y expandir hitbox
    local target = getClosestEnemy()
    updateHitbox(target)

    -- 2. Hacer el clic (Fast M1)
    local now = os.clock()
    if now - lastClick >= Config.ClickDelay then
        lastClick = now
        cancelAnimations(char)
        
        -- Simular clic izquierdo
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
        
        -- Si tenemos target, forzar que el ratón esté sobre él
        if target and mouse then
            pcall(function()
                local cam = Workspace.CurrentCamera
                local screenPos = cam:WorldToViewportPoint(target.Position)
                if screenPos.Z > 0 then
                    mousemoverel(screenPos.X - cam.ViewportSize.X/2, screenPos.Y - cam.ViewportSize.Y/2)
                end
            end)
        end
    end
end))

env.__BF_FASTM1_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    if currentTargetPart and currentTargetPart.Parent and originalSize then
        pcall(function() currentTargetPart.Size = originalSize end)
    end
    env.BF_FASTM1_CONFIG = nil
    env.__BF_FASTM1_CLEANUP = nil
end
