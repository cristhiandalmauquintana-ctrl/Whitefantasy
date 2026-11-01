--// Froggy Hub - ElementalMagicArena/AttackAll.lua (V6 - Full Auto)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_ATTACKALL_CLEANUP then pcall(env.__BF_ATTACKALL_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 1000
}
env.BF_ATTACKALL_CONFIG = Config

-- Coordenadas exactas (Energy por defecto)
local TargetPos = Vector3.new(816.06640625, -14.519143104553223, 37.429420471191409)
local tpsFolder = Workspace:FindFirstChild("TPS")

-- Guardar posiciones originales de las placas
local OriginalPlateData = {}
if tpsFolder then
    for _, obj in ipairs(tpsFolder:GetDescendants()) do
        if obj:IsA("BasePart") and string.lower(obj.Name) == "teleporter" then
            OriginalPlateData[obj] = obj.CFrame
        end
    end
end

local originalData = {}
local honeypotParts = {}
local shieldedPlayersParts = {}

-- Bloqueo de Robux
if hookfunction then
    hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
end

-- 1. Función para Esconder/Mostrar Placas
local function movePlates(hide)
    if not tpsFolder then return end
    for part, originalCFrame in pairs(OriginalPlateData) do
        if part and part.Parent then
            if hide then
                part.CFrame = CFrame.new(0, 9999, 0) -- Al cielo
            else
                part.CFrame = originalCFrame -- A su lugar
            end
        end
    end
end

-- 2. Funciones del Arma
local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function expandSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    if not originalData[handle] then
        originalData[handle] = { Size = handle.Size, Transparency = handle.Transparency, CanCollide = handle.CanCollide, Massless = handle.Massless, CanTouch = handle.CanTouch }
    end
    handle.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
    handle.CanTouch = true
end

local function restoreSword(tool)
    local handle = getHandle(tool)
    if not handle or not originalData[handle] then return end
    local data = originalData[handle]
    handle.Size = data.Size
    handle.Transparency = data.Transparency
    handle.CanCollide = data.CanCollide
    handle.Massless = data.Massless
    handle.CanTouch = data.CanTouch
    originalData[handle] = nil
end

-- 3. Auto-Equipar al Morir (Respawn)
LocalPlayer.CharacterAdded:Connect(function()
    originalData = {}
    if Config.Enabled then
        task.wait(1.5) -- Esperar a que cargue el personaje en el lobby
        
        -- Bajar placas temporalmente
        movePlates(false)
        task.wait(0.2)

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        
        if myRoot and tpsFolder then
            -- Teletransportar a Energy
            myRoot.CFrame = CFrame.new(TargetPos + Vector3.new(0, 3, 0))
            myRoot.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.5)

            -- Buscar la placa y forzar el evento
            local closestTele = nil
            local shortestDist = math.huge
            for _, obj in ipairs(tpsFolder:GetDescendants()) do
                if obj:IsA("BasePart") and string.lower(obj.Name) == "teleporter" then
                    local dist = (obj.Position - TargetPos).Magnitude
                    if dist < shortestDist then shortestDist = dist; closestTele = obj end
                end
            end

            if closestTele then
                local success = false
                if getconnections then
                    for _, conn in pairs(getconnections(closestTele.Touched)) do
                        if conn.Enabled then
                            pcall(function() conn:Fire(myRoot) success = true end)
                        end
                    end
                end
                if not success then
                    pcall(function()
                        firetouchinterest(myRoot, closestTele, 0)
                        task.wait(0.1)
                        firetouchinterest(myRoot, closestTele, 1)
                    end)
                end
            end
        end
        
        -- Volver a esconder las placas
        if Config.Enabled then movePlates(true) end
    end
end)

-- 4. Bucle de Flicker y Placas
task.spawn(function()
    while task.wait() do
        if Config.Enabled then
            movePlates(true) -- Mantener las placas en el cielo
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                expandSword(tool)
                task.wait(0.25)
                restoreSword(tool)
                task.wait(0.25)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

-- 5. Bypass de Honeypots y Escudos
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            -- Escudos
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hasShield = p.Character:FindFirstChildOfClass("ForceField") or (p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid:FindFirstChildOfClass("ForceField"))
                    if hasShield then
                        if not shieldedPlayersParts[p] then shieldedPlayersParts[p] = {} end
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and not shieldedPlayersParts[p][part] then
                                shieldedPlayersParts[p][part] = { CanTouch = part.CanTouch, CanQuery = part.CanQuery }
                                part.CanTouch = false; part.CanQuery = false
                            end
                        end
                    elseif shieldedPlayersParts[p] then
                        for part, data in pairs(shieldedPlayersParts[p]) do
                            if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end
                        end
                        shieldedPlayersParts[p] = nil
                    end
                end
            end

            -- Honeypots
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = string.lower(obj.Name)
                    if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_npc") or name:find("honeypot") or name:find("trap") then
                        if obj:IsA("BasePart") then
                            if not honeypotParts[obj] then honeypotParts[obj] = { CanTouch = obj.CanTouch, CanQuery = obj.CanQuery }; obj.CanTouch = false; obj.CanQuery = false end
                        else
                            for _, part in ipairs(obj:GetDescendants()) do
                                if part:IsA("BasePart") and not honeypotParts[part] then honeypotParts[part] = { CanTouch = part.CanTouch, CanQuery = part.CanQuery }; part.CanTouch = false; part.CanQuery = false end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 6. Limpieza total al apagar el Toggle
env.__BF_ATTACKALL_CLEANUP = function()
    Config.Enabled = false
    
    -- Devolver placas a su lugar
    movePlates(false)
    
    -- Restaurar arma
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    
    -- Restaurar escudos y honeypots
    for p, parts in pairs(shieldedPlayersParts) do
        for part, data in pairs(parts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    end
    for part, data in pairs(honeypotParts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
