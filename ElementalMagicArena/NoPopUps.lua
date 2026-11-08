--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V6 - NO CRASH, ZERO HOOKS)
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local GROUP_NAME = "FroggySword"
local scanConnection = nil

-- 1. ESPADA FANTASMA (Evita tocar gacha/tiendas)
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

-- 2. CAZADOR DE VENTANAS (Por nombres específicos)
local blocklist = {"halloween", "duel", "shop", "store", "gacha", "purchase", "robux", "gem", "buy"}

local function scanAndDestroy()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    -- Revisar solo las ventanas principales (Cero lag)
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("Frame") then
            local name = string.lower(gui.Name)
            local isBad = false
            
            for _, word in ipairs(blocklist) do
                if name:find(word) then
                    isBad = true
                    break
                end
            end

            -- No destruir nuestra propia UI
            if isBad and not name:find("froggy") then
                gui:Destroy()
            end
        end
    end
end

-- 3. LÓGICA DE ACTIVACIÓN
local function startShield()
    -- Bucle muy ligero de escaneo (solo mira los hijos directos del PlayerGui)
    if scanConnection then scanConnection:Disconnect() end
    scanConnection = RunService.Heartbeat:Connect(scanAndDestroy)
    print("[Froggy] NoPopUps V6 Activado (Modo Ligero).")
end

local function stopShield()
    if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
    print("[Froggy] NoPopUps V6 Desactivado.")
end

-- 4. BUCLE PRINCIPAL
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                startShield()
            end
            
            -- Mantener la espada fantasma
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end
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
