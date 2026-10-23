--// Froggy Hub - GodMode (Mahoraga Manual)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Mahoraga = false, -- Se controla desde el botón flotante
    OriginalMaxHealth = 100,
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local isHooked = false

local function setupHooks()
    if isHooked then return end
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.Mahoraga then
                if method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    return -- Bloquea el daño cuando está activo
                end
            end
            return oldNamecall(self, ...)
        end)
        isHooked = true
    end)
end

local function applyInvincibility(state)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if state then
        -- Activar Modo Dios
        Config.OriginalMaxHealth = hum.MaxHealth
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if raknet and raknet.desync then pcall(function() raknet.desync(true) end) end
    else
        -- Desactivar (Volver a la normalidad)
        hum.MaxHealth = Config.OriginalMaxHealth > 0 and Config.OriginalMaxHealth or 100
        hum.Health = hum.MaxHealth
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        if raknet and raknet.desync then pcall(function() raknet.desync(false) end) end
    end
end

local function setupCharacter(char)
    setupHooks()
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    -- Aplicar el estado actual al personaje (por si respawneamos)
    task.wait(1)
    applyInvincibility(Config.Mahoraga)

    -- Anti-Caída pasivo (siempre activo)
    local root = char:WaitForChild("HumanoidRootPart")
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if root.Position.Y < (workspace.FallenPartsDestroyHeight + 50) then
            local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
            if spawnLoc then
                root.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
            else
                root.CFrame = CFrame.new(0, 100, 0)
            end
        end
    end))
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

env.__BF_GOD_CLEANUP = function()
    applyInvincibility(false)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
