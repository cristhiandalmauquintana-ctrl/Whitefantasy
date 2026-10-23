-- ============================================================
-- WHITE FANTASY - HitboxExpander.lua (MODULAR)
-- ============================================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- 1. CREAMOS LA TABLA DE CONFIGURACIÓN PARA EL MAIN.LUA
getgenv().BF_HITBOX_CONFIG = {
    Enabled = false,
    Size = 35
}

local HitC = getgenv().BF_HITBOX_CONFIG
local originalSizes = {}
local originalMasses = {}

-- 2. LOOP PRINCIPAL DEL HITBOX
task.spawn(function()
    while task.wait(0.1) do
        if HitC.Enabled then
            local HITBOX_SIZE = HitC.Size
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local head = p.Character:FindFirstChild("Head")
                    
                    if hrp then
                        if not originalSizes[hrp] then originalSizes[hrp] = hrp.Size end
                        if originalMasses[hrp] == nil then originalMasses[hrp] = hrp.Massless end
                        
                        hrp.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
                        hrp.Transparency = 0.8
                        hrp.CanCollide = false
                        hrp.Massless = true -- TRUCO: Evita que el hitbox te empuje
                    end
                    
                    if head then
                        if not originalSizes[head] then originalSizes[head] = head.Size end
                        if originalMasses[head] == nil then originalMasses[head] = head.Massless end
                        
                        head.Size = Vector3.new(HITBOX_SIZE/1.5, HITBOX_SIZE/1.5, HITBOX_SIZE/1.5)
                        head.Transparency = 0.8
                        head.CanCollide = false
                        head.Massless = true
                    end
                end
            end
            
            -- Noclip automático para que puedas atravesarlos
            if LP.Character then
                for _, part in ipairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                    end
                end
            end
            
        else
            -- Restaurar todo si el Main apaga el botón
            for part, size in pairs(originalSizes) do
                if part and part.Parent then
                    part.Size = size
                    part.Transparency = 0
                    part.CanCollide = true
                    if originalMasses[part] ~= nil then
                        part.Massless = originalMasses[part]
                    end
                end
            end
            originalSizes = {}
            originalMasses = {}
            
            -- Restaurar colisiones del jugador
            if LP.Character then
                for _, part in ipairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                        part.CanCollide = true 
                    end
                end
            end
        end
    end
end)
