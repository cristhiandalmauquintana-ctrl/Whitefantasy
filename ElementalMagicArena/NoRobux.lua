--// Froggy Hub - ElementalMagicArena/NoRobux.lua (V3 - BULLETPROOF)
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOROBUX_CLEANUP then pcall(env.__BF_NOROBUX_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOROBUX_CONFIG = Config

local scanConnection = nil

-- 1. HOOKS DE COMPRA (Bloqueo a nivel de red)
local function applyHooks()
    if hookmetamethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptPurchase" or method == "PromptSubscriptionPurchase" then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end)
    elseif hookfunction then
        hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
        hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
        hookfunction(MarketplaceService.PromptPurchase, function() return end)
    end
end

-- 2. CAZADOR DE VENTANAS (Bucle rápido)
local function scanAndDestroy()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        -- Buscamos TextLabels, TextButtons o TextBoxes
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = string.lower(obj.Text)
            
            -- Si el texto menciona dinero, gemas o compras
            if text:find("robux") or text:find("r%$") or text:find("gem") or text:find("buy") or text:find("comprar") or text:find("tienda") or text:find("shop") then
                
                -- Buscamos el Frame padre que contiene esta ventana
                local parent = obj.Parent
                while parent and parent ~= playerGui do
                    -- Si encontramos un contenedor grande, lo destruimos
                    if parent:IsA("Frame") and (parent.Size.X.Scale > 0.3 or parent.Size.X.Offset > 200) then
                        parent:Destroy()
                        break
                    elseif parent:IsA("ScreenGui") and parent.Name ~= "FroggyHub" and parent.Name ~= "FroggyFarm" then
                        parent:Destroy()
                        break
                    end
                    parent = parent.Parent
                end
            end
        end
    end
end

-- 3. CONTROL DE ENCENDIDO
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled and not oldEnabled then
            oldEnabled = true
            applyHooks()
            -- Bucle de escaneo rápido
            if scanConnection then scanConnection:Disconnect() end
            scanConnection = RunService.Heartbeat:Connect(scanAndDestroy)
            print("[Froggy] NoRobux Activado (BULLETPROOF).")
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
            print("[Froggy] NoRobux Desactivado.")
        end
    end
end)

env.__BF_NOROBUX_CLEANUP = function()
    Config.Enabled = false
    if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
    env.BF_NOROBUX_CONFIG = nil
    env.__BF_NOROBUX_CLEANUP = nil
end
