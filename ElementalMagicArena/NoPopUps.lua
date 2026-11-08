--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V19 - THE SPY BLOCKER)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local GROUP_NAME = "FroggySword"
local honeypotParts = {}
local movedParts = {}
local connections = {}
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

-- 2. HOOKS DEL SPY (El que bloqueó la Forja por accidente)
local function applyHooks()
    if not hookmetamethod or not checkcaller then return end

    -- Hook A: Bloquear el cambio de propiedad a Visible/Enabled (El que funcionó)
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if not checkcaller() and (key == "Visible" or key == "Enabled") and value == true then
            if self:IsA("ScreenGui") or self:IsA("Frame") then
                local name = string.lower(self.Name)
                
                -- 🔥 Si es HowToUnlock (Misiones), Shop, etc., lo destruimos
                if name == "howtounlockgui" or name:find("quest") or name:find("shop") or name:find("forge") then
                    if not name:find("froggy") then
                        self:Destroy()
                        return -- Bloquea la propiedad para que no se muestre
                    end
                end
            end
        end
        return oldNewIndex(self, key, value)
    end)

    -- Hook B: Bloquear Remotes de compra y misiones
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local name = string.lower(self.Name)
            if name == "openquest" or name:find("howtounlock") or name:find("purchase") or name:find("robux") or name:find("shop") then
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

-- 3. PURGA FÍSICA (Para el círculo de Halloween en el lobby)
local TARGET_PARTS = {"simulatorcircle", "teleport asset", "rankedpart", "shoppart", "forge"}
local VOID_CFRAME = CFrame.new(0, -5000, 0)

local function hidePhysicalParts(obj)
    if not Config.Enabled or not obj or not obj:IsA("BasePart") then return end
    
    local name = string.lower(obj.Name)
    local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
    
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

local function restoreParts()
    for obj, cf in pairs(movedParts) do
        if obj and obj.Parent then obj.CFrame = cf end
    end
    movedParts = {}
end

table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function() hidePhysicalParts(obj) end)
end))

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
                applyHooks()
                for _, obj in ipairs(Workspace:GetDescendants()) do hidePhysicalParts(obj) end
                print("[Froggy] NoPopUps V19 Activado (Spy Hook Blocker).")
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
            restoreParts()
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] NoPopUps V19 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    removeHooks()
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
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
