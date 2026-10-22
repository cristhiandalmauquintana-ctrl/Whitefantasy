--// Froggy Hub - God Mode (Anti-Void + Health Lock + Ghost)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Enabled = false,
    AntiVoid = true,
    HealthLock = true,
    GhostMode = true, -- Hace que las hitboxes enemigas te ignoren
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local savedPos = nil

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    -- Guardar posición segura cada segundo
    task.spawn(function()
        while Config.Enabled and char.Parent do
            if root.Position.Y > -20 then
                savedPos = root.CFrame
            end
            task.wait(1)
        end
    end)

    -- 1. Anti-Void (Si caes, te devuelve)
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.AntiVoid then return end
        if root.Position.Y < -50 then
            if savedPos then
                root.CFrame = savedPos
            else
                root.CFrame = CFrame.new(0, 50, 0) -- CFrame de emergencia
            end
        end
    end))

    -- 2. Health Lock (Bloqueo de vida)
    table.insert(connections, hum.HealthChanged:Connect(function(newHealth)
        if Config.Enabled and Config.HealthLock then
            if newHealth < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end))
    
    -- Loop de vida por si acaso el server intenta matarte
    task.spawn(function()
        while Config.Enabled and char.Parent do
            if Config.HealthLock and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            task.wait(0.1)
        end
    end)

    -- 3. Ghost Mode (Desactiva colisiones de tu cuerpo)
    local function setGhost(state)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if state then
                    part.CanQuery = false
                    part.CanTouch = false
                else
                    part.CanQuery = true
                    part.CanTouch = true
                end
            end
        end
    end
    setGhost(Config.Enabled and Config.GhostMode)
    
    -- Actualizar Ghost Mode dinámicamente
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if Config.Enabled and Config.GhostMode then
            setGhost(true)
        end
    end))
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

env.__BF_GOD_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
