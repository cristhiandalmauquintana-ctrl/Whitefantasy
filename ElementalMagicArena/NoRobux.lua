--// Froggy Hub - ElementalMagicArena/NoRobux.lua
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOROBUX_CLEANUP then pcall(env.__BF_NOROBUX_CLEANUP) end

local Config = {
    Enabled = false
}
env.BF_NOROBUX_CONFIG = Config

local shopConnections = {}

-- 1. HOOK ANTI-COMPRAS (Bloquea oficiales y Remotes del juego)
local function applyHooks()
    if hookmetamethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptPurchase" or method == "PromptSubscriptionPurchase" then
                    return nil
                end
                if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") then
                    local name = string.lower(self.Name)
                    if name:find("purchase") or name:find("buy") or name:find("shop") or name:find("robux") then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    elseif hookfunction then
        hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
        hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
    end
end

-- 2. CAZADOR DE VENTANAS (Optimizado con Debounce)
local lastGuiCheck = 0
local function checkNewGuiObj(obj)
    if not obj or not obj.Parent then return end
    local now = tick()
    if now - lastGuiCheck < 0.1 then return end 
    lastGuiCheck = now
    
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local txt = string.lower(obj.Text)
        if txt:find("robux") or txt:find("r%$") or txt:find("gem") or txt:find("buy") or txt:find("comprar") then
            local parent = obj.Parent
            while parent and not parent:IsA("ScreenGui") and parent ~= LocalPlayer:FindFirstChild("PlayerGui") do
                if parent:IsA("Frame") and (parent.Size.X.Scale > 0.4 or parent.Size.X.Offset > 300) then
                    parent:Destroy()
                    break
                end
                parent = parent.Parent
            end
        end
    end
end

-- 3. CONTROL DE ENCENDIDO / APAGADO
local function enableNoRobux()
    applyHooks()
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        table.insert(shopConnections, pg.DescendantAdded:Connect(function(obj)
            task.defer(function() checkNewGuiObj(obj) end)
        end))
    end
    print("[Froggy] NoRobux Activado.")
end

local function disableNoRobux()
    for _, conn in ipairs(shopConnections) do
        if conn then conn:Disconnect() end
    end
    shopConnections = {}
    print("[Froggy] NoRobux Desactivado.")
end

-- Bucle de verificación para el Toggle del Hub
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled and not oldEnabled then
            oldEnabled = true
            enableNoRobux()
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            disableNoRobux()
        end
    end
end)

env.__BF_NOROBUX_CLEANUP = function()
    Config.Enabled = false
    disableNoRobux()
    env.BF_NOROBUX_CONFIG = nil
    env.__BF_NOROBUX_CLEANUP = nil
end
