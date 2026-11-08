--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V7 - PHYSICAL PURGE STABLE)
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local GROUP_NAME = "FroggySword"
local movedObjects = {}
local isHidden = false

-- 1. ESPADA FANTASMA (Capa extra de seguridad)
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

-- 2. IDENTIFICAR OBJETOS A MOVER
local function isTargetObject(obj)
    if not obj:IsA("BasePart") then return false end
    
    local name = string.lower(obj.Name .. (obj.Parent and obj.Parent.Name or ""))
    
    -- NO mover almas ni la carpeta TPS (placas de elementos)
    if name:find("soul") or name:find("alma") then return false end
    local tpsFolder = Workspace:FindFirstChild("TPS")
    if tpsFolder and obj:IsDescendantOf(tpsFolder) then return false end

    -- Mover si tiene un prompt/click o si su nombre suena a tienda/duelo/gacha
    local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
    local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
    local isShop = name:find("shop") or name:find("gacha") or name:find("store") or 
                   name:find("duel") or name:find("halloween") or name:find("chest") or name:find("cofre")

    return hasPrompt or hasClick or isShop
end

-- 3. MOVER AL SUBSUELO Y RESTAURAR
local function hideTargets()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isTargetObject(obj) then
            if not movedObjects[obj] then
                movedObjects[obj] = obj.CFrame -- Guardar ubicación original
            end
            obj.CFrame = CFrame.new(0, -5000, 0) -- Mandarlo al subsuelo
        end
    end
    isHidden = true
end

local function restoreTargets()
    for obj, cf in pairs(movedObjects) do
        if obj and obj.Parent then
            obj.CFrame = cf -- Devolver a su lugar
        end
    end
    movedObjects = {}
    isHidden = false
end

-- 4. ESCUCHAR SI APARECEN COSAS NUEVAS MIENTRAS ESTÁ OCULTO
local newObjConnection = Workspace.DescendantAdded:Connect(function(obj)
    if Config.Enabled and isHidden and isTargetObject(obj) then
        if not movedObjects[obj] then
            movedObjects[obj] = obj.CFrame
        end
        obj.CFrame = CFrame.new(0, -5000, 0)
    end
end)

-- 5. BUCLE PRINCIPAL (Revisa si tienes el arma en la mano)
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            
            if tool then
                -- Si tienes arma: Aplicar Espada Fantasma y Esconder cosas
                applyGhostGroup(tool)
                if not isHidden then
                    hideTargets()
                end
            else
                -- Si NO tienes arma: Devolver todo a su lugar
                if isHidden then
                    restoreTargets()
                end
            end
        elseif oldEnabled then
            -- Si se apaga el script, restaurar todo
            oldEnabled = false
            restoreTargets()
        end
        oldEnabled = Config.Enabled
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    restoreTargets()
    if newObjConnection then newObjConnection:Disconnect() end
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
