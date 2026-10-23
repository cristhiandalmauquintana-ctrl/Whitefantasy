--// Froggy Hub - GodMode V15 (Evasión Automática Anti-Acumulación)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Mahoraga = false,
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local isHooked = false
local isEvading = false
local lastEvadeTime = 0

local function setupHooks()
    if isHooked then return end
    pcall(function()
        -- Bloqueamos TakeDamage
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.Mahoraga then
                if method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                    return
                end
                if method == "BreakJoints" and self:IsA("BasePart") and self.Parent == LocalPlayer.Character then
                    return
                end
            end
            return oldNamecall(self, ...)
        end)
        isHooked = true
    end)
end

local function setupCharacter(char)
    setupHooks()
    
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    -- 🛡️ Loop principal
    table.insert(connections, RunService.Stepped:Connect(function()
        if not Config.Mahoraga then return end
        
        -- 1. Vida infinita
        pcall(function()
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)

        -- 2. Evasión automática (si la vida baja, te movemos al cielo)
        if hum.Health < hum.MaxHealth - 1 and not isEvading and os.clock() - lastEvadeTime > 2 then
            isEvading = true
            lastEvadeTime = os.clock()
            
            local originalPos = root.CFrame
            local skyPos = originalPos + Vector3.new(0, 60, 0)
            
            -- Teletransporte al cielo
            root.CFrame = skyPos
            
            -- Esperamos 0.5 segundos y volvemos al suelo
            task.delay(0.5, function()
                if char and char.Parent and Config.Mahoraga then
                    pcall(function()
                        root.CFrame = originalPos
                        hum.Health = math.huge
                    end)
                end
                isEvading = false
            end)
        end
    end))

    -- 🛡️ Revivir si el servidor nos mata
    table.insert(connections, hum.Died:Connect(function()
        if not Config.Mahoraga then return end
        task.wait(0.01)
        if char and char.Parent then
            pcall(function()
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end))
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

-- Sincronización con el botón
LocalPlayer:GetAttributeChangedSignal("FroggyMahoraga"):Connect(function()
    Config.Mahoraga = LocalPlayer:GetAttribute("FroggyMahoraga")
end)

env.__BF_GOD_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
