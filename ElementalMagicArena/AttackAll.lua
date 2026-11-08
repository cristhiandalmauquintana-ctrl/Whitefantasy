--// Froggy Hub - ElementalMagicArena/AttackAll.lua (V24 - MASSIVE + GHOST HITBOX)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_ATTACKALL_CLEANUP then pcall(env.__BF_ATTACKALL_CLEANUP) end

local Config = { Enabled = false, Size = 1000 } -- 🔥 TAMAÑO MANTENIDO EN 1000
env.BF_ATTACKALL_CONFIG = Config

local GROUP_NAME = "FroggyMassiveSword"
local originalData = {}
local honeypotParts = {}

-- 🔥 1. GRUPO DE COLISIÓN PARA LA ESPADA (Evita que los proyectiles te den)
pcall(function()
    PhysicsService:RegisterCollisionGroup(GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, "Default", false) -- No choca con proyectiles/mapa
end)

-- 2. HOOK ANTI-COMPRAS
if hookfunction then
    hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
    hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
end

-- 3. FUNCIONES DEL ARMA
local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function expandSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    if not originalData[handle] then
        originalData[handle] = { 
            Size = handle.Size, 
            Transparency = handle.Transparency, 
            CanCollide = handle.CanCollide, 
            Massless = handle.Massless, 
            CanTouch = handle.CanTouch,
            CanQuery = handle.CanQuery,
            CollisionGroup = handle.CollisionGroup
        }
    end
    
    handle.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
    handle.CanTouch = true
    handle.CanQuery = false -- 🔥 Evita que los raycast te detecten a distancia
    
    -- Aplicar el grupo de colisión fantasma
    pcall(function()
        PhysicsService:SetPartCollisionGroup(handle, GROUP_NAME)
    end)
end

local function restoreSword(tool)
    local handle = getHandle(tool)
    if not handle or not originalData[handle] then return end
    local data = originalData[handle]
    handle.Size = data.Size
    handle.Transparency = data.Transparency
    handle.CanCollide = data.CanCollide
    handle.Massless = data.Massless
    handle.CanTouch = data.CanTouch
    handle.CanQuery = data.CanQuery
    
    pcall(function()
        PhysicsService:SetPartCollisionGroup(handle, data.CollisionGroup)
    end)
    
    originalData[handle] = nil
end

-- Limpiar datos al morir
LocalPlayer.CharacterAdded:Connect(function()
    originalData = {}
end)

-- 4. BUCLE PRINCIPAL (Flicker)
task.spawn(function()
    while task.wait(0.25) do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                expandSword(tool)
                task.wait(0.25)
                restoreSword(tool)
            end
        end
    end
end)

-- 5. BYPASS DE HONEYPOTS
task.spawn(function()
    while task.wait(1) do
        if Config.Enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = string.lower(obj.Name)
                    if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_npc") or name:find("honeypot") or name:find("trap") then
                        if obj:IsA("BasePart") then
                            if not honeypotParts[obj] then 
                                honeypotParts[obj] = { CanTouch = obj.CanTouch, CanQuery = obj.CanQuery }
                                obj.CanTouch = false; obj.CanQuery = false
                            end
                        else
                            for _, part in ipairs(obj:GetDescendants()) do
                                if part:IsA("BasePart") and not honeypotParts[part] then 
                                    honeypotParts[part] = { CanTouch = part.CanTouch, CanQuery = part.CanQuery }
                                    part.CanTouch = false; part.CanQuery = false
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 6. LIMPIEZA
env.__BF_ATTACKALL_CLEANUP = function()
    Config.Enabled = false
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    
    for part, data in pairs(honeypotParts) do 
        if part and part.Parent then 
            part.CanTouch = data.CanTouch
            part.CanQuery = data.CanQuery
        end 
    end
    honeypotParts = {}
    
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
