--// Froggy Hub - ElementalMagicArena/AttackAll.lua (V32 - MANUAL AUTO-EQUIP)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_ATTACKALL_CLEANUP then pcall(env.__BF_ATTACKALL_CLEANUP) end

local Config = { Enabled = false, Size = 360 }
env.BF_ATTACKALL_CONFIG = Config

local SWORD_GROUP = "FroggySword"
local PLAYERS_GROUP = "FroggyPlayers"

local originalData = {}
local honeypotParts = {}

-- 🔥 1. CONFIGURAR GRUPOS DE COLISIÓN
pcall(function()
    -- Grupo para la espada
    PhysicsService:RegisterCollisionGroup(SWORD_GROUP)
    -- Grupo para los jugadores
    PhysicsService:RegisterCollisionGroup(PLAYERS_GROUP)
    
    -- La espada NO choca con el mapa (Default), pero SÍ choca con los jugadores
    PhysicsService:CollisionGroupSetCollidable(SWORD_GROUP, "Default", false)
    PhysicsService:CollisionGroupSetCollidable(SWORD_GROUP, PLAYERS_GROUP, true)
end)

-- 2. HOOK ANTI-COMPRAS
if hookfunction then
    hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
    hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
end

-- 3. FUNCIONES DE LA ESPADA
local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

-- 🔥 NUEVA FUNCIÓN: Auto-equipar arma si no hay una en la mano
local function ensureWeaponEquipped()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    -- 1. Revisar si ya tenemos un arma equipada
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and getHandle(currentTool) then
        return currentTool
    end

    -- 2. Si no hay arma, buscar en la mochila
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and getHandle(item) then
                -- Equipar el primer item que tenga un Handle válido
                pcall(function() hum:EquipTool(item) end)
                task.wait(0.2) -- Pequeña espera para que el juego procese el equipamiento
                return item
            end
        end
    end
    
    return nil
end

local function applyCollisionGroups()
    -- Ponemos a todos los jugadores en su propio grupo de colisión
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        PhysicsService:SetPartCollisionGroup(part, PLAYERS_GROUP)
                    end)
                end
            end
        end
    end
end

local function expandSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    
    if not originalData[handle] then
        originalData[handle] = { 
            Size = handle.Size, Transparency = handle.Transparency, CanCollide = handle.CanCollide, 
            Massless = handle.Massless, CanTouch = handle.CanTouch, CanQuery = handle.CanQuery,
            CollisionGroup = handle.CollisionGroup
        }
    end
    
    handle.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
    handle.CanTouch = true
    handle.CanQuery = false 
    
    -- 🔥 Asignamos la espada a su grupo exclusivo
    pcall(function() 
        PhysicsService:SetPartCollisionGroup(handle, SWORD_GROUP) 
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

-- Si el jugador muere o respawnea, restauramos la espada
LocalPlayer.CharacterAdded:Connect(function()
    originalData = {}
end)

-- 4. BUCLE DE MOVIMIENTO Y FLICKER (CON AUTO-EQUIP)
task.spawn(function()
    while task.wait(0.1) do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hum then
                -- Forzar caminar
                if hum.PlatformStand then hum.PlatformStand = false end
                if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                if hum.JumpPower < 50 then hum.JumpPower = 50 end
                if hum.Sit then hum.Sit = false end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if Config.Enabled then
            applyCollisionGroups() -- Asegurarnos de que los jugadores estén en su grupo
            
            -- 🔥 AQUI SE LLAMA A LA NUEVA FUNCION
            local tool = ensureWeaponEquipped()
            
            if tool then
                expandSword(tool)
                task.wait(0.25)
                restoreSword(tool)
                task.wait(0.25)
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
            part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery
        end 
    end
    honeypotParts = {}
    
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
