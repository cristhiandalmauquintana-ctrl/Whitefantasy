--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V23 - BLACK SCREEN KILLER)
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

-- 2. LISTA NEGRA DE GUIs (Sin TournamentGui)
local BLACKLIST = {
    "survivalsquadgui",   -- Halloween / Supervivencia
    "rankedgui",          -- Duelos
    "luckelementpopupgui",-- Popup de elemento bloqueado (Robux)
    "howtounlockgui",     -- UI de desbloqueo
    "coderedemptiongui",  -- Códigos
    "killrewardpopup",    -- Recompensas de kills
    "giftnotifgui",       -- Notificaciones de regalos
    "spinui",             -- Ruleta
    "giftui",             -- Regalos
    "giftconfettigui",    -- Confeti
    "giftspinnergui"      -- Ruleta de regalos
}

local function onGuiAdded(obj)
    if not Config.Enabled or not obj then return end
    
    if obj:IsA("ScreenGui") or (obj:IsA("Frame") and obj.Parent == LocalPlayer:FindFirstChild("PlayerGui")) then
        local name = string.lower(obj.Name)
        
        if name:find("froggy") then return end
        
        for _, badName in ipairs(BLACKLIST) do
            if name == badName or name:find(badName) then
                obj:Destroy() 
                return
            end
        end
    end
end

local pg = LocalPlayer:WaitForChild("PlayerGui")
table.insert(connections, pg.DescendantAdded:Connect(function(obj)
    task.defer(function() onGuiAdded(obj) end)
end))

-- 3. BLACK SCREEN KILLER (Destructor de fondos oscuros)
local function destroyBlackFrames()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    for _, obj in ipairs(pg:GetDescendants()) do
        -- Buscar Frames que cubran toda la pantalla
        if obj:IsA("Frame") and (obj.Size.X.Scale >= 0.95 and obj.Size.Y.Scale >= 0.95) then
            local name = string.lower(obj.Name)
            local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
            
            -- Verificar que no sea de Froggy Hub ni del juego base (Chat, HUD, etc)
            if not name:find("froggy") and not parentName:find("froggy") and not name:find("chat") and not name:find("hud") then
                -- Verificar que sea un color oscuro/negro
                local c = obj.BackgroundColor3
                if c.R < 0.15 and c.G < 0.15 and c.B < 0.15 and obj.BackgroundTransparency < 0.8 then
                    obj:Destroy() -- Adiós pantalla negra
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
                for _, obj in ipairs(pg:GetChildren()) do onGuiAdded(obj) end
                destroyBlackFrames()
                print("[Froggy] NoPopUps V23 Activado.")
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end

            -- Escanear fondos negros y honeypots constantemente
            destroyBlackFrames()
            purgeHoneypots()

        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then 
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end 
            end
            honeypotParts = {}
            print("[Froggy] NoPopUps V23 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
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
