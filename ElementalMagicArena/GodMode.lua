--// Froggy Hub - GodMode V5 (Anti One-Shot - Server Bypass)
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
local isHooked = false

-- 🛡️ HOOKS ANTI-DAÑO
local function setupHooks()
    if isHooked then return end
    isHooked = true
    
    local success, err = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        local oldIndex = mt.__index
        local oldNewIndex = mt.__newindex
        
        setreadonly(mt, false)
        
        -- Hook para interceptar el TakeDamage
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Config.Enabled and Config.HealthLock then
                if method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    -- Ignoramos el daño del servidor. Si el daño es mayor a 50, no lo aplicamos.
                    local args = {...}
                    if args[1] and args[1] > 50 then
                        return 
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        
        -- Hook para evitar que el Health baje a 0
        mt.__newindex = newcclosure(function(self, key, value)
            if Config.Enabled and Config.HealthLock then
                if key == "Health" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    if value <= 0 then
                        return -- Bloquea la muerte
                    end
                end
            end
            return oldNewIndex(self, key, value)
        end)
        
        setreadonly(mt, true)
    end)
    
    if not success then
        warn("[Froggy] ⚠️ Hooks no soportados. Usando modo pasivo.")
    end
end

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
    local fallbackCFrame = spawnLoc and (spawnLoc.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 100, 0)

    task.spawn(function()
        while Config.Enabled and char.Parent do
            if root.Position.Y > (workspace.FallenPartsDestroyHeight + 100) and hum.FloorMaterial ~= Enum.Material.Air then
                savedPos = root.CFrame
            end
            task.wait(1)
        end
    end)

    -- 🛡️ VIDA INFINITA Y BYPASS DEL MAXHEALTH
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.HealthLock then return end
        
        -- Forzamos MaxHealth a 999 y Health a 999
        pcall(function()
            if hum.MaxHealth < 999 then
                hum.MaxHealth = 999
            end
            if hum.Health < 999 then
                hum.Health = 999
            end
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
    end))

    -- ForceField invisible
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.HealthLock then return end
        if not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField")
            ff.Visible = false
            ff.Parent = char
        end
    end))

    -- 🛡️ SI AÚN ASÍ MUERE, RESUCITAR EN EL MISMO FRAME
    table.insert(connections, hum.Died:Connect(function()
        if not Config.Enabled or not Config.HealthLock then return end
        task.wait(0.1)
        if char and char.Parent then
            pcall(function()
                hum.MaxHealth = 999
                hum.Health = 999
            end)
            if savedPos then root.CFrame = savedPos end
        end
    end))

    -- Anti-Void
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.AntiVoid then return end
        if root.Position.Y < (workspace.FallenPartsDestroyHeight + 50) then
            if savedPos then root.CFrame = savedPos else root.CFrame = fallbackCFrame end
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end))

    -- Ghost Mode (Anti-Raycast)
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
