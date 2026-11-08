--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V5 - THE DEFINITIVE SHIELD)
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local connections = {}
local GROUP_NAME = "FroggySword"

-- 1. ESPADA FANTASMA (Para no tocar el gacha/tiendas físicas)
pcall(function()
    PhysicsService:RegisterCollisionGroup(GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, "Default", false)
end)

local function applyGhostGroup(tool)
    if not tool or not tool:IsA("Tool") then return end
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() PhysicsService:SetPartCollisionGroup(part, GROUP_NAME) end)
        end
    end
end

-- 2. HOOK METAMETHOD (El bloqueo definitivo de ventanas)
local oldIndex, oldNewIndex = nil, nil

local function applyUIHook()
    if not hookmetamethod or not checkcaller then return end

    -- Bloquear la lectura de "Visible" o "Enabled" para que el juego crea que la ventana ya está cerrada
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and self:IsA("ScreenGui") then
            local name = string.lower(self.Name)
            if name:find("halloween") or name:find("duel") or name:find("shop") or name:find("gacha") then
                if key == "Enabled" or key == "Visible" then
                    return false -- Le mentimos al juego diciendo que está apagada
                end
            end
        end
        return oldIndex(self, key)
    end)

    -- Bloquear la escritura (si el juego intenta prenderla, lo forzamos a apagarla)
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if not checkcaller() and self:IsA("ScreenGui") then
            local name = string.lower(self.Name)
            if name:find("halloween") or name:find("duel") or name:find("shop") or name:find("gacha") then
                if (key == "Enabled" or key == "Visible") and value == true then
                    return -- Ignoramos la orden de encenderse
                end
            end
        end
        return oldNewIndex(self, key, value)
    end)
end

local function removeUIHook()
    if oldIndex then hookmetamethod(game, "__index", oldIndex); oldIndex = nil end
    if oldNewIndex then hookmetamethod(game, "__newindex", oldNewIndex); oldNewIndex = nil end
end

-- 3. DESTRUCTOR DE EMERGENCIA (Por si el Hook falla o la UI se llama distinto)
local function emergencySniper(container)
    if not Config.Enabled or not container then return end
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("ScreenGui") then
            local name = string.lower(obj.Name)
            if name:find("halloween") or name:find("duel") or name:find("shop") or name:find("gacha") then
                if not name:find("froggy") then
                    obj:Destroy()
                end
            end
        end
    end
end

-- 4. LÓGICA DE CONTROL
local function startShield()
    applyUIHook()
    
    -- Escuchar armas equipadas para la Espada Fantasma
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
        if Config.Enabled then
            char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and Config.Enabled then
                    applyGhostGroup(child)
                end
            end)
        end
    end))

    -- Escanear nuevas ventanas (Capa extra)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        table.insert(connections, pg.DescendantAdded:Connect(function()
            task.defer(function() emergencySniper(pg) end)
        end))
    end

    print("[Froggy] NoPopUps Definitivo Activado.")
end

local function stopShield()
    removeUIHook()
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    connections = {}
    print("[Froggy] NoPopUps Definitivo Desactivado.")
end

-- 5. BUCLE DE CONTROL
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                startShield()
            end
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end
            
            -- Escaneo pasivo de emergencia
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then emergencySniper(pg) end
            
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            stopShield()
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    stopShield()
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
