--// Froggy Hub - ElementalMagicArena/AttackAll.lua (V10 - Purga Original + Equip)
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

-- 1. Coordenadas exactas de Energy
local TargetPos = Vector3.new(816.06640625, -14.519143104553223, 37.429420471191409)

-- 2. Bloquear compras de Robux
if hookfunction then
    hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
end

-- Variables
local originalData = {}
local honeypotParts = {}
local shieldedPlayersParts = {}

-- 🔥 3. LA PURGA ORIGINAL (Exactamente como la que funcionó)
local function killTouch(obj)
    if obj:IsA("BasePart") then
        obj.CanTouch = false
        obj.CanQuery = false
        if getconnections then
            for _, conn in pairs(getconnections(obj.Touched)) do
                conn:Disconnect()
            end
        end
    end
    if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
        obj.Enabled = false
    end
end

local function globalPurge()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isCharacter = obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid") ~= nil
            
            -- Si está anclado y NO es un personaje
            if obj.Anchored and not isCharacter then
                -- 🛑 EXCEPCIÓN: Protegemos la carpeta TPS (Placas de elementos)
                local isTPS = obj:IsDescendantOf(Workspace:FindFirstChild("TPS"))
                
                if not isTPS then
                    killTouch(obj) -- Destruye tiendas, gacha, duelos, UGC, etc.
                    count = count + 1
                end
            end
        elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            local pName = string.lower(obj.Name .. (obj.Parent and obj.Parent.Name or ""))
            if not pName:find("soul") and not pName:find("alma") then
                obj.Enabled = false
            end
        end
    end
    return count
end

-- 4. Funciones del Arma (Flicker)
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

-- 5. Auto-Equipar al Morir (Usa conn:Fire)
LocalPlayer.CharacterAdded:Connect(function()
    originalData = {}
    if Config.Enabled then
        task.wait(1.5) -- Esperar a que cargue el personaje en el lobby
        
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        
        if myRoot then
            myRoot.CFrame = CFrame.new(TargetPos + Vector3.new(0, 3, 0))
            myRoot.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.5)

            local tpsFolder = Workspace:FindFirstChild("TPS")
            if tpsFolder then
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
        end
    end
end)

-- 🔥 6. BUCLE PRINCIPAL (Flicker + Purga Constante)
task.spawn(function()
    while task.wait() do
        if Config.Enabled then
            globalPurge() -- Mantener el mapa limpio de tiendas constantemente
            
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

-- 7. Bypass de Honeypots y Escudos
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
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

-- 8. Limpieza al Apagar
env.__BF_ATTACKALL_CLEANUP = function()
    Config.Enabled = false
    
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    
    for p, parts in pairs(shieldedPlayersParts) do
        for part, data in pairs(parts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    end
    for part, data in pairs(honeypotParts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
