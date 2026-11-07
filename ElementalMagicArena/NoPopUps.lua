--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (DYNAMIC TELEPORT SHIELD)
local Workspace = game:GetService("Workspace")
local LocalPlayer = game:GetService("Players").LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local movedObjects = {} -- Guarda las coordenadas originales
local lastWeaponState = false
local loopConnection = nil

-- Coordenada segura (Lejos de la arena, arriba en el cielo)
local VOID_CFRAME = CFrame.new(0, 5000, 0)

-- 🔥 FUNCIÓN PARA IDENTIFICAR SI EL OBJETO ES UNA TIENDA O PLACA
local function isTargetObject(obj)
    if not obj:IsA("BasePart") then return false end
    
    local name = string.lower(obj.Name .. (obj.Parent and obj.Parent.Name or ""))
    
    -- Si es un alma, NO lo tocamos
    if name:find("soul") or name:find("alma") then return false end

    -- Buscamos si tiene prompts o clicks, o si su nombre es de tienda
    local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
    local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
    local isShop = name:find("shop") or name:find("gacha") or name:find("store") or 
                   name:find("duel") or name:find("chest") or name:find("cofre") or 
                   name:find("teleporter") or name:find("tps") -- Incluye las placas de TPS

    return hasPrompt or hasClick or isShop
end

-- 🔥 MOVER TODO AL CIELO
local function hideTargets()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isTargetObject(obj) then
            if not movedObjects[obj] then
                movedObjects[obj] = obj.CFrame -- Guardamos dónde estaba
            end
            obj.CFrame = VOID_CFRAME -- Lo mandamos al cielo
        end
    end
end

-- 🔥 DEVOLVER TODO A SU LUGAR
local function restoreTargets()
    for obj, cf in pairs(movedObjects) do
        if obj and obj.Parent then
            obj.CFrame = cf
        end
    end
    movedObjects = {}
end

-- Escuchar si el juego spawnea tiendas nuevas
local function onDescendantAdded(obj)
    if not Config.Enabled then return end
    if isTargetObject(obj) and lastWeaponState then
        if not movedObjects[obj] then
            movedObjects[obj] = obj.CFrame
        end
        obj.CFrame = VOID_CFRAME
    end
end

local addedConnection = Workspace.DescendantAdded:Connect(onDescendantAdded)

-- 🔥 BUCLE DE CONTROL (Revisa el arma cada 0.5s)
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local hasWeapon = char and char:FindFirstChildOfClass("Tool") ~= nil
            
            if hasWeapon then
                -- Tiene arma: Ocultar todo
                if not lastWeaponState then
                    lastWeaponState = true
                    hideTargets()
                end
            else
                -- No tiene arma: Devolver todo
                if lastWeaponState then
                    lastWeaponState = false
                    restoreTargets()
                end
            end
        elseif oldEnabled then
            -- Si se apaga el Toggle, restauramos
            oldEnabled = false
            restoreTargets()
            lastWeaponState = false
        end
        oldEnabled = Config.Enabled
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    restoreTargets()
    if addedConnection then addedConnection:Disconnect() end
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
