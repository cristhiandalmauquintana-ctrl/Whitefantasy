--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V8 - TOUCHED KILLER)
local Workspace = game:GetService("Workspace")
local LocalPlayer = game:GetService("Players").LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

-- 🔥 Nombres exactos que encontramos con el Spy
local TARGET_NAMES = {"teleport asset", "shoppart", "simulatorcircle", "rankedpart", "aa", "forge"}
local connections = {}

local function killTouched(obj)
    if not Config.Enabled or not obj or not obj:IsA("BasePart") then return end
    
    local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
    local objName = string.lower(obj.Name)
    
    local isTarget = false
    for _, name in ipairs(TARGET_NAMES) do
        if objName:find(name) or parentName:find(name) then
            isTarget = true
            break
        end
    end

    if isTarget then
        -- 🔥 DESCONECTAR EL EVENTO TOUCHED
        if getconnections then
            for _, conn in pairs(getconnections(obj.Touched)) do
                conn:Disconnect()
            end
        end
        -- Como medida extra, apagar la colisión sin moverlo
        obj.CanTouch = false 
    end
end

-- Escuchar si se crean nuevas partes mientras está encendido
local function onDescendantAdded(obj)
    if Config.Enabled then
        killTouched(obj)
    end
end
table.insert(connections, Workspace.DescendantAdded:Connect(onDescendantAdded))

-- Bucle de control
local oldEnabled = false
task.spawn(function()
    while task.wait(1) do
        if Config.Enabled and not oldEnabled then
            oldEnabled = true
            -- Escaneo inicial de todo el mapa
            for _, obj in ipairs(Workspace:GetDescendants()) do
                killTouched(obj)
            end
            print("[Froggy] NoPopUps Activado (Touched Killer).")
            
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            for _, conn in ipairs(connections) do
                if conn then conn:Disconnect() end
            end
            connections = {}
            print("[Froggy] NoPopUps Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
    connections = {}
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
