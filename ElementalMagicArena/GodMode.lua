--// Froggy Hub - GodMode V9 (Modo Fénix - Anti-Muerte Real)
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
    Desync = true,
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local savedPos = nil
local isHooked = false

local function setDesync(state)
    if raknet and raknet.desync then
        pcall(function() raknet.desync(state) end)
    end
end

local function setupHooks()
    if isHooked then return end
    local success = pcall(function()
        -- Hook 1: Bloquear TakeDamage
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.Enabled and Config.HealthLock then
                if method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    return
                end
                -- Hook para bloquear el estado de muerte (Modo Fénix)
                if method == "ChangeState" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    local state = ...
                    if state == Enum.HumanoidStateType.Dead then
                        return -- Si intentan matarnos, lo ignoramos
                    end
                end
            end
            return oldNamecall(self, ...)
        end)

        -- Hook 2: Bloquear Health = 0
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
            if Config.Enabled and Config.HealthLock then
                if key == "Health" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    if value <= 0 then return end 
                end
            end
            return oldNewIndex(self, key, value)
        end)
        isHooked = true
    end)
    if not success then warn("[Froggy] ⚠️ Hooks no soportados.") end
end

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    setupHooks()
    
    -- 🛡️ Evitamos que el personaje se desarme al morir
    pcall(function() hum.BreakJointsOnDeath = false end)

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

    -- 🛡️ FÉNIX: Si la vida llega a 0, la revivimos en el acto
    table.insert(connections, RunService.Stepped:Connect(function()
        if not Config.Enabled then return end
        if Config.Desync then setDesync(true) end
        if Config.HealthLock then
            pcall(function()
                if hum.Health <= 0 then
                    hum.Health = 100 -- Lo traemos de vuelta
                    hum:ChangeState(Enum.HumanoidStateType.Running) -- Lo forzamos a estar vivo
                end
            end)
        end
    end))

    -- ForceField
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.HealthLock then return end
        if not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField")
            ff.Visible = false
            ff.Parent = char
        end
    end))

    -- Anti-Void
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not Config.AntiVoid then return end
        if root.Position.Y < (workspace.FallenPartsDestroyHeight + 50) then
            if savedPos then root.CFrame = savedPos else root.CFrame = fallbackCFrame end
            pcall(function() hum.Health = 100 end)
        end
    end))

    -- Ghost Mode
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
    setDesync(false)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
