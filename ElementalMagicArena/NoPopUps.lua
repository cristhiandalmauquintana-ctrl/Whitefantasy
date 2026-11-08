--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V12 - THE SPY METHOD)
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
local oldNewIndex = nil
local oldNamecall = nil

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

-- 2. LOS HOOKS DEL SPY (El arma secreta)
local function applyHooks()
    if not hookmetamethod or not checkcaller then return end

    -- Hook A: Interceptar cuando una ventana intenta hacerse VISIBLE
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if not checkcaller() and (key == "Visible" or key == "Enabled") and value == true then
            if self:IsA("ScreenGui") or self:IsA("Frame") then
                local name = string.lower(self.Name)
                -- Si la ventana es de misiones, forja o tiendas...
                if name:find("howtounlock") or name:find("quest") or name:find("forge") or name:find("shop") or name:find("robux") then
                    if not name:find("froggy") then
                        self:Destroy() -- La destruimos antes de que se dibuje
                        return -- Bloqueamos la propiedad Visible
                    end
                end
            end
        end
        return oldNewIndex(self, key, value)
    end)

    -- Hook B: Interceptar el Remote OpenQuest
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local name = string.lower(self.Name)
            if name:find("openquest") or name:find("howtounlock") or name:find("shop") or name:find("buy") then
                return nil
            end
        end
        return oldNamecall(self, ...)
    end)
end

local function removeHooks()
    if oldNewIndex then hookmetamethod(game, "__newindex", oldNewIndex); oldNewIndex = nil end
    if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall); oldNamecall = nil end
end

-- 3. ANTI-HONEYPOTS
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

-- 4. BUCLE DE CONTROL
local oldEnabled = false
task.spawn(function()
    while task.wait(0.2) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                applyHooks()
                print("[Froggy] Purga V12 Activada (Spy Method).")
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

            purgeHoneypots()

        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            removeHooks()
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] Purga V12 Desactivada.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    removeHooks()
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
