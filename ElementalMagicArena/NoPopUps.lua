--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V17 - PHYSICAL PURGE EXACT)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local GROUP_NAME = "FroggySword"
local honeypotParts = {}
local movedParts = {}
local connections = {}

-- 1. ESPADA FANTASMA
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

-- 2. PURGA FÍSICA (Esto es lo que funcionaba)
local TARGET_PARTS = {"simulatorcircle", "teleport asset", "rankedpart", "shoppart", "forge"}
local VOID_CFRAME = CFrame.new(0, -5000, 0) -- Los mandamos al subsuelo

local function hidePhysicalParts(obj)
    if not Config.Enabled or not obj or not obj:IsA("BasePart") then return end
    
    local name = string.lower(obj.Name)
    local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
    
    -- NO TOCAR LAS PLACAS (TPS) NI ALMAS
    local tpsFolder = Workspace:FindFirstChild("TPS")
    local isTPS = tpsFolder and obj:IsDescendantOf(tpsFolder) or false
    local isSoul = name:find("soul") or name:find("alma") or parentName:find("soul") or parentName:find("alma")
    
    if not isTPS and not isSoul then
        for _, target in ipairs(TARGET_PARTS) do
            if name:find(target) or parentName:find(target) then
                if not movedParts[obj] then
                    movedParts[obj] = obj.CFrame 
                end
                obj.CFrame = VOID_CFRAME 
                break
            end
        end
    end
end

-- Escuchar si el juego spawnea algo nuevo
table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function() hidePhysicalParts(obj) end)
end))

-- 3. DESTRUCTOR DE UI (Por si el juego ya la tenía abierta)
local function destroyBadUI()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    for _, obj in ipairs(pg:GetChildren()) do
        if obj:IsA("ScreenGui") then
            local name = string.lower(obj.Name)
            if name == "howtounlockgui" or name:find("shop") or name:find("quest") then
                if not name:find("froggy") then
                    obj:Destroy()
                end
            end
        end
    end
end

-- 4. ANTI-HONEYPOTS
local function purgeHoneypots()
    if not Config.Enabled then return end
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

-- 5. BUCLE DE CONTROL
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                -- Purga inicial al encender
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    hidePhysicalParts(obj)
                end
                destroyBadUI()
                print("[Froggy] NoPopUps V17 (Purga Física) Activado.")
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

            destroyBadUI()
            purgeHoneypots()

        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            -- Restaurar objetos al apagar
            for obj, cf in pairs(movedParts) do
                if obj and obj.Parent then
                    obj.CFrame = cf
                end
            end
            movedParts = {}
            
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] NoPopUps V17 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
    for obj, cf in pairs(movedParts) do
        if obj and obj.Parent then obj.CFrame = cf end
    end
    for part, data in pairs(honeypotParts) do 
        if part and part.Parent then 
            part.CanTouch = data.CanTouch
            part.CanQuery = data.CanQuery
        end 
    end
    movedParts = {}
    honeypotParts = {}
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
