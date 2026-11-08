--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V14 - TEXT KILLER DEFINITIVO)
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

-- 1. ESPADA FANTASMA (Protege el gacha)
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

-- 2. DESTRUCTOR VISUAL (Caza textos específicos)
local function destroyBadUI()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    -- Buscar cualquier texto que coincida con las ventanas problemáticas
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = string.lower(obj.Text)
            
            if txt:find("misiones de plasma") or txt:find("sobrevivencia") or txt:find("supervivencia") then
                -- Subir por la jerarquía hasta encontrar el Frame contenedor principal
                local parent = obj.Parent
                while parent and parent ~= pg do
                    if parent:IsA("Frame") and (parent.Size.X.Scale > 0.4 or parent.Size.X.Offset > 300) then
                        parent:Destroy() -- Destruir el panel entero
                        break
                    elseif parent:IsA("ScreenGui") then
                        parent:Destroy()
                        break
                    end
                    parent = parent.Parent
                end
            end
        end
    end

    -- Destruir el HowToUnlockGui por si acaso
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and string.lower(gui.Name) == "howtounlockgui" then
            gui:Destroy()
        end
    end
end

-- 3. TELETRANSPORTE FÍSICO (Opcional, por si la UI está vinculada al piso)
local TARGET_PARTS = {"simulatorcircle", "teleport asset", "rankedpart"}
local VOID_CFRAME = CFrame.new(0, -5000, 0)

local function hideParts()
    if not Config.Enabled then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
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
    end
end

local function restoreParts()
    for obj, cf in pairs(movedParts) do
        if obj and obj.Parent then
            obj.CFrame = cf
        end
    end
    movedParts = {}
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
    while task.wait(0.15) do -- 0.15s es muy rápido, atrapa la UI antes de que se dibuje
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                print("[Froggy] NoPopUps V14 Activado (Text Killer).")
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

            destroyBadUI()
            hideParts()
            purgeHoneypots()

        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            restoreParts()
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] NoPopUps V14 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    restoreParts()
    for part, data in pairs(honeypotParts) do 
        if part and part.Parent then 
            part.CanTouch = data.CanTouch
            part.CanQuery = data.CanQuery
        end 
    end
    honeypotParts = {}
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
