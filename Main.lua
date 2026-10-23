--// Froggy Hub - GodMode V11 (Fénix - Anti-Lobby)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Mahoraga = false,
    OriginalMaxHealth = 100,
    LastSafePosition = nil,
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local isHooked = false

-- 🛡️ HOOKS (Intento de bloquear daño en el cliente)
local function setupHooks()
    if isHooked then return end
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.Mahoraga and method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                return
            end
            return oldNamecall(self, ...)
        end)
        isHooked = true
    end)
end

-- 🛡️ LÓGICA DE FÉNIX (Si el servidor te mata, te revivimos)
local function setupCharacter(char)
    setupHooks()
    
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    -- Guardar posición segura constantemente
    task.spawn(function()
        while char.Parent do
            if root.Position.Y > (workspace.FallenPartsDestroyHeight + 50) and hum.Health > 0 then
                Config.LastSafePosition = root.CFrame
            end
            task.wait(0.5)
        end
    end)

    -- 🛡️ MODO MAHORAGA (Vida infinita y escudo)
    table.insert(connections, RunService.Stepped:Connect(function()
        if Config.Mahoraga then
            pcall(function()
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end)
            if raknet and raknet.desync then pcall(function() raknet.desync(true) end) end
        end
    end))

    -- 🔥 EL TRUCO: Si el servidor te mata, te revivimos antes del lobby
    table.insert(connections, hum.Died:Connect(function()
        if not Config.Mahoraga then return end
        
        -- Revivir al instante
        task.wait(0.05) 
        if char and char.Parent then
            pcall(function()
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                -- Teletransportar a la última posición segura si es necesario
                if Config.LastSafePosition then
                    root.CFrame = Config.LastSafePosition
                end
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end))
end

-- Función para aplicar el modo desde el botón flotante
local function updateInvincibility()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.Mahoraga then
        Config.OriginalMaxHealth = hum.MaxHealth
    else
        -- Restaurar
        hum.MaxHealth = Config.OriginalMaxHealth > 0 and Config.OriginalMaxHealth or 100
        hum.Health = hum.MaxHealth
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        if raknet and raknet.desync then pcall(function() raknet.desync(false) end) end
    end
end

-- Conectar el evento de cambio de estado (para el botón)
LocalPlayer:GetAttributeChangedSignal("FroggyMahoraga"):Connect(function()
    Config.Mahoraga = LocalPlayer:GetAttribute("FroggyMahoraga")
    updateInvincibility()
end)

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

env.__BF_GOD_CLEANUP = function()
    if raknet and raknet.desync then pcall(function() raknet.desync(false) end) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_GODMODE_CONFIG = nil
    env.__BF_GOD_CLEANUP = nil
end
