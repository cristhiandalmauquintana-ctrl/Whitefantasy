-- ============================================================
-- WHITE FANTASY - HitboxExpander.lua
-- Aumenta el hitbox a 35 studs y elimina las colisiones físicas
-- ============================================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local originalSizes = {}
local originalMasses = {}

-- Aseguramos que la tabla de configuración exista (por si este script carga antes que el Main)
if not getgenv().WhiteFantasy then
    getgenv().WhiteFantasy = { Hitbox = false }
end

local HITBOX_SIZE = 35 -- Tamaño de 35 studs

task.spawn(function()
    while task.wait(0.1) do -- Se actualiza 10 veces por segundo (anti-reversión)
        -- Leemos el estado desde el Main.lua
        if getgenv().WhiteFantasy.Hitbox then
            
            -- 1. Expandir Hitboxes de los enemigos
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
                        hrp.Massless = true -- TRUCO: No te empuja
                    end
                    
                    if head then
                        if not originalSizes[head] then originalSizes[head] = head.Size end
                        if originalMasses[head] == nil then originalMasses[head] = head.Massless end
                        
                        head.Size = Vector3.new(HITBOX_SIZE/1.5, HITBOX_SIZE/1.5, HITBOX_SIZE/1.5)
                        head.Transparency = 0.8
                        head.CanCollide = false
                        head.Massless = true -- TRUCO: No te empuja
                    end
                end
            end
            
            -- 2. Noclip automático para el jugador local (para atravesarlos)
            if LP.Character then
                for _, part in ipairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                    end
                end
            end
            
        else
            -- 3. Restaurar todo si el Main.lua apaga el botón
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
            
            -- Restaurar colisiones del jugador local
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
