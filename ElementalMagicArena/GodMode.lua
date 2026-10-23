--// Froggy Hub - GodMode V2 (Anti-Void Arreglado)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Enabled = false,
    AntiVoid = true,
    HealthLock = true,
    GhostMode = true,
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local savedPos = nil
local lastSafeTime = 0

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    -- Buscamos el spawn real del mapa para usarlo como emergencia
    local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
    local fallbackCFrame = spawnLoc and (spawnLoc.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 100, 0)

    -- Guardar posición segura solo si estamos en el suelo (no volando ni cayendo)
    task.spawn(function()
        while Config.Enabled and char.Parent do
            if root.Position.Y > -100 and hum.FloorMaterial ~= Enum.Material.Air then
                savedPos = root.CFrame
            end
            task.wait(1)
        end
    end)

    -- 1. Anti-Void (Si caes, te devuelve)
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.AntiVoid then return end
        
        -- Usamos el limite real de caida de Roblox (FallenPartsDestroyHeight)
        if root.Position.Y < (workspace.FallenPartsDestroyHeight + 50) then
            if savedPos then
                root.CFrame = savedPos
            else
                root.CFrame = fallbackCFrame
            end
            hum.Health = hum.MaxHealth -- Te cura al volver por si acaso
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
    
    task.spawn(function()
        while Config.Enabled and char.Parent do
            if Config.HealthLock and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            task.wait(0.1)
        end
    end)

    -- 3. Ghost Mode
    local function setGhost(state)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanQuery = not state
                part.CanTouch = not state
            end
        end
    end
    setGhost(Config.Enabled and Config.GhostMode)
    
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if Config.Enabled and Config.GhostMode then setGhost(true) end
    end))
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

env.__BF_GOD_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
