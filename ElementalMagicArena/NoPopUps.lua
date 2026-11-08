--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V11 - FORENSIC PURGE)
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
local connections = {}

-- 1. ESPADA FANTASMA (Para no tocar físicamente el gacha)
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

-- 2. BLOQUEO DE REMOTES (Intercepta OpenQuest y compras de Robux)
local oldNamecall = nil
if hookmetamethod and checkcaller then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        -- Si el script del juego intenta disparar un evento al servidor
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local name = string.lower(self.Name)
            
            -- 🔥 BLOQUEAR EL REMOTE DE LAS MISIONES
            if name == "openquest" or name:find("howtounlock") then
                return nil 
            end
            
            -- 🔥 BLOQUEAR REMOTES DE TIENDAS
            if name:find("shop") or name:find("buy") or name:find("purchase") or name:find("robux") or name:find("gacha") then
                return nil
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- 3. DESTRUCTOR DE UI ESPECÍFICO (Destruye HowToUnlockGui)
local function destroyBadGUIs()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("ScreenGui") or obj:IsA("Frame") then
            local name = string.lower(obj.Name)
            -- 🔥 Destruir solo las ventanas problemáticas
            if name == "howtounlockgui" or name == "contextactiongui" or name:find("quest") or name:find("shop") then
                -- Verificar que no sea de Froggy para no auto-destruirnos
                if not name:find("froggy") then
                    obj:Destroy()
                end
            end
        end
    end
end

-- 4. ANTI-HONEYPOTS (Para que la espada no te kickee)
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
    while task.wait(0.2) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                print("[Froggy] Purga Forense Activada.")
            end

            -- Espada Fantasma
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

            -- Destruir ventanas
            destroyBadGUIs()

            -- Proteger de Honeypots
            purgeHoneypots()

        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            -- Restaurar Honeypots
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] Purga Forense Desactivada.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
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
