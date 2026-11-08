--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (V30 - BLOCK OFFICIAL ROBLOX UI)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local connections = {}
local honeypotParts = {}

-- 1. HOOKS DE COMPRA (Bloqueo total del sistema de Roblox)
if hookmetamethod and checkcaller then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() then
            -- Bloquear funciones oficiales de compra
            if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptPurchase" or method == "PromptSubscriptionPurchase" then
                return nil
            end
            
            -- Bloquear eventos remotos del juego que intenten abrir compras
            if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") then
                local name = string.lower(self.Name)
                if name:find("purchase") or name:find("buy") or name:find("shop") or name:find("robux") then
                    return nil
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- 2. LISTA NEGRA DE INTERFACES DEL JUEGO (PlayerGui)
local BLACKLIST = {
    "survivalsquadgui",    -- Halloween
    "rankedgui",           -- Duelos
    "luckelementpopupgui", -- Regalos / Suerte
    "giftnotifgui",        -- Notificaciones de regalos
    "spinui",              -- Ruleta
    "giftui",              -- Regalos
    "giftconfettigui",     -- Confeti
    "giftspinnergui"       -- Ruleta de regalos
}

local function isSafeGui(name)
    local lowName = string.lower(name)
    -- 🔥 PROTECCIÓN ABSOLUTA PARA LOS CONTROLES DEL CELULAR
    if lowName:find("touchgui") or lowName:find("topbar") or lowName:find("chat") or 
       lowName:find("joystick") or lowName:find("jump") or lowName:find("mobile") or 
       lowName:find("froggy") then
        return true
    end
    return false
end

local function destroyBadUI()
    if not Config.Enabled then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("ScreenGui") then
            local name = string.lower(obj.Name)
            if isSafeGui(name) then continue end

            for _, bad in ipairs(BLACKLIST) do
                if name:find(bad) then
                    obj:Destroy()
                    return
                end
            end
        end
    end
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
                print("[Froggy] NoPopUps V30 (Anti-Roblox UI) Activado.")
            end
            destroyBadUI()
            purgeHoneypots()
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            for part, data in pairs(honeypotParts) do 
                if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end 
            end
            honeypotParts = {}
            print("[Froggy] NoPopUps V30 Desactivado.")
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
    for part, data in pairs(honeypotParts) do 
        if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end 
    end
    honeypotParts = {}
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
