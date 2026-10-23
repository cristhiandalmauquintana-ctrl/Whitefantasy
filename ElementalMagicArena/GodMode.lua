--// Froggy Hub - GodMode Mahoraga (Adaptación Divina)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

local Config = {
    Enabled = false,
    Duration = 6,     -- Tiempo de invulnerabilidad (segundos)
    MaxHealth = 9999, -- Vida base alta para sobrevivir al primer golpe
}
env.BF_GODMODE_CONFIG = Config

local connections = {}
local isHooked = false
local lastHitTime = 0
local isMahoragaActive = false

local function setupHooks()
    if isHooked then return end
    local success = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.Enabled then
                -- Si el Mahoraga está activo, bloqueamos TODO daño
                if isMahoragaActive then
                    if method == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                        return -- Bloqueado
                    end
                end
            end
            return oldNamecall(self, ...)
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

    -- 🛡️ Configuración inicial de vida
    task.spawn(function()
        while Config.Enabled and char.Parent do
            if hum.MaxHealth ~= Config.MaxHealth then
                hum.MaxHealth = Config.MaxHealth
                hum.Health = Config.MaxHealth
            end
            task.wait(1)
        end
    end)

    -- 🛡️ DETECCIÓN DE DAÑO (El "Trigger" del Mahoraga)
    table.insert(connections, hum.HealthChanged:Connect(function(newHealth)
        if not Config.Enabled then return end
        
        -- Si recibimos daño y NO estamos invulnerables
        if newHealth < hum.MaxHealth and not isMahoragaActive then
            -- Activamos Mahoraga
            isMahoragaActive = true
            lastHitTime = os.clock()
            
            -- Nos curamos al instante
            hum.Health = hum.MaxHealth
            
            -- Efecto visual (Opcional, para saber que se activó)
            local ff = Instance.new("ForceField")
            ff.Visible = true
            ff.Parent = char
            task.delay(Config.Duration, function() if ff then ff:Destroy() end end)
        end
    end))

    -- 🛡️ BUCLE DE MAHORAGA (Controla el tiempo y la curación)
    table.insert(connections, RunService.Stepped:Connect(function()
        if not Config.Enabled then return end
        
        if isMahoragaActive then
            -- Si el tiempo no ha pasado, mantener vivo y curado
            if os.clock() - lastHitTime < Config.Duration then
                pcall(function()
                    hum.Health = hum.MaxHealth
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                end)
            else
                -- Se acabó el tiempo, volvemos a ser vulnerables
                isMahoragaActive = false
            end
        end
    end))

    -- ForceField invisible de fondo (protección extra)
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        if not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField")
            ff.Visible = false
            ff.Parent = char
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
