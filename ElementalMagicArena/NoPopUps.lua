--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V18 - PERMA BLOCK)
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
local connections = {}

-- 1. ESPADA FANTASMA (Protege el gacha físico)
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

-- 2. HOOK ANTI-ROBUX Y ANTI-MISIONES (Corta el cable desde el servidor)
local oldNamecall = nil
if hookmetamethod and checkcaller then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local name = string.lower(self.Name)
            -- 🔥 Bloqueo del Remote que abre las misiones de Halloween
            if name == "openquest" or name:find("howtounlock") or name:find("purchase") or name:find("robux") then
                return nil
            end
        end
        return oldNamecall(self, ...)
    end)
    
    if hookfunction then
        hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
        hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
    end
end

-- 3. DESTRUCTOR INSTANTÁNEO DE UI (Perma Block)
local function destroyBadUI(obj)
    if not Config.Enabled or not obj then return end
    
    -- Si es un ScreenGui y su nombre es HowToUnlockGui o similar
    if obj:IsA("ScreenGui") then
        local name = string.lower(obj.Name)
        if name == "howtounlockgui" or name:find("quest") or name:find("shop") then
            if not name:find("froggy") then
                obj:Destroy()
            end
        end
    end
end

local pg = LocalPlayer:WaitForChild("PlayerGui")
table.insert(connections, pg.DescendantAdded:Connect(function(obj)
    task.defer(function() destroyBadUI(obj) end)
end))

-- 4. DESTRUCTOR DEL CÍRCULO FÍSICO (Perma Block)
local function destroyBadParts(obj)
    if not Config.Enabled or not obj or not obj:IsA("BasePart") then return end
    
    local name = string.lower(obj.Name)
    local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
    
    -- No tocar TPS (placas) ni Almas
    local tpsFolder = Workspace:FindFirstChild("TPS")
    local isTPS = tpsFolder and obj:IsDescendantOf(tpsFolder) or false
    local isSoul = name:find("soul") or name:find("alma") or parentName:find("soul") or parentName:find("alma")
    
    if not isTPS and not isSoul then
        -- 🔥 Destruir el círculo de Halloween / Supervivencia
        if name:find("teleport asset") or name:find("rankedpart") or parentName:find("sobrevivencia") or parentName:find("supervivencia") then
            obj:Destroy()
        end
    end
end

table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function() destroyBadParts(obj) end)
end))

-- 5. ANTI-HONEYPOTS
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

-- 6. BUCLE DE CONTROL
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                -- Purga inicial (limpia lo que ya estaba abierto o en el mapa)
                for _, obj in ipairs(pg:GetChildren()) do destroyBadUI(obj) end
                for _, obj in ipairs(Workspace:GetDescendants()) do destroyBadParts(obj) end
                print("[Froggy] NoPopUps V18 (Perma Block) Activado.")
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

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
            print("[Froggy] NoPopUps V18 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
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
