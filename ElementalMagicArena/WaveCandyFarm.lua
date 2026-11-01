--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V27 - Auto-Equip Weapon)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    SelectedElement = "energy", 
    SearchRadius = 2000,     
    HandleSize = 1000,       
    FloatHeight = 15,        
    FlySpeed = 150,          
    CollectDistance = 5,     
}
env.BF_WAVEFARM_CONFIG = Config

-- Coordenadas (Tu JSON completo)
local ElementData = {
    ["tierra"] = {Y=-14.159768104553223,X=817.5328369140625,Z=-81.78305053710938},
    ["amor"] = {Y=-14.519143104553223,X=813.6480102539063,Z=398.444091796875},
    ["demon"] = {Y=-14.519143104553223,X=816.405029296875,Z=459.564208984375},
    ["ilusion"] = {Y=-14.519143104553223,X=815.6622924804688,Z=238.9192352294922},
    ["campos de fuerza"] = {Y=-14.519143104553223,X=814.673095703125,Z=338.1503601074219},
    ["agua"] = {Y=-14.135136604309082,X=815.782470703125,Z=-101.6214828491211},
    ["relampago"] = {Y=-14.519143104553223,X=814.6509399414063,Z=-22.939300537109376},
    ["oscuridad"] = {Y=-14.519143104553223,X=815.8905029296875,Z=78.65248107910156},
    ["life"] = {Y=-14.519143104553223,X=814.5501098632813,Z=517.5612182617188},
    ["telequinesis"] = {Y=-14.519143104553223,X=815.1790771484375,Z=297.4894104003906},
    ["energy"] = {Y=-14.519143104553223,X=816.06640625,Z=37.429420471191409},
    ["luz"] = {Y=-14.519143104553223,X=815.3165893554688,Z=16.669418334960939},
    ["diamante"] = {Y=-14.519143104553223,X=815.1226806640625,Z=378.49517822265627},
    ["espiritu"] = {Y=-14.519143104553223,X=816.121337890625,Z=177.92054748535157},
    ["mirror"] = {Y=-14.27907657623291,X=815.46923828125,Z=496.7007141113281},
    ["hierro"] = {Y=-14.519143104553223,X=816.4691772460938,Z=138.2559356689453},
    ["time"] = {Y=-14.519143104553223,X=815.4653930664063,Z=318.00408935546877},
    ["lava"] = {Y=-14.519143104553223,X=816.4039916992188,Z=-2.5292625427246095},
    ["veneno"] = {Y=-14.519143104553223,X=815.0426635742188,Z=118.56273651123047},
    ["aurora"] = {Y=-14.519143104553223,X=814.3197021484375,Z=258.44024658203127},
    ["fenix"] = {Y=-14.519143104553223,X=816.6735229492188,Z=196.85293579101563},
    ["dios de elementos"] = {Y=-14.519143104553223,X=752.0708618164063,Z=530.8677978515625},
    ["fuego"] = {Y=-14.159768104553223,X=816.637939453125,Z=-120.46199798583985},
    ["sueño"] = {Y=-14.519143104553223,X=813.5301513671875,Z=477.92254638671877},
    ["creacion"] = {Y=-14.519143104553223,X=815.3740844726563,Z=438.4972839355469},
    ["espacio"] = {Y=-14.519143104553223,X=816.9115600585938,Z=57.76768493652344},
    ["realidad"] = {Y=-14.519143104553223,X=813.58447265625,Z=418.34515380859377},
    ["destruccion"] = {Y=-14.519143104553223,X=817.3116455078125,Z=158.61717224121095},
    ["aire"] = {Y=-14.159768104553223,X=814.2105102539063,Z=-61.69546890258789},
    ["caos"] = {Y=-14.519143104553223,X=815.2899169921875,Z=279.7561340332031},
    ["tecnología"] = {Y=-14.519143104553223,X=814.77783203125,Z=359.1853332519531},
    ["cristal"] = {Y=-14.519143104553223,X=815.6806030273438,Z=219.55162048339845},
    ["sonido"] = {Y=-14.519143104553223,X=815.3438720703125,Z=97.98532104492188},
    ["hielo"] = {Y=-14.159768104553223,X=816.0550537109375,Z=-41.79139709472656}
}

local connections = {}
local originalHandleData = {}
local currentTarget = nil
local hoverPosition = nil

local function setLocalNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not enabled end
    end
end

-- 🔥 EQUIPAR ARMA AUTOMÁTICAMENTE
local function equipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    -- Si ya tiene un arma, no hacemos nada
    if char:FindFirstChildOfClass("Tool") then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    -- Buscar el primer Tool disponible y equiparlo
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() hum:EquipTool(tool) end)
            break -- Solo equipar el primero
        end
    end
end

local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function expandHandle(tool)
    local handle = getHandle(tool)
    if not handle then return end
    if not originalHandleData[handle] then
        originalHandleData[handle] = { Size = handle.Size, Transparency = handle.Transparency, CanCollide = handle.CanCollide, Massless = handle.Massless }
    end
    handle.Size = Vector3.new(Config.HandleSize, Config.HandleSize, Config.HandleSize)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
end

local function restoreHandle(tool)
    local handle = getHandle(tool)
    if not handle or not originalHandleData[handle] then return end
    local data = originalHandleData[handle]
    handle.Size = data.Size
    handle.Transparency = data.Transparency
    handle.CanCollide = data.CanCollide
    handle.Massless = data.Massless
    originalHandleData[handle] = nil
end

local function stopFarm()
    Config.Enabled = false
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local tool = char and char:FindFirstChildOfClass("Tool")
    setLocalNoclip(false)
    if hum then hum.PlatformStand = false end
    if tool then restoreHandle(tool) end
    hoverPosition = nil
end

local function startFarm()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    hum.PlatformStand = true
    setLocalNoclip(true)
    
    hoverPosition = root.Position + Vector3.new(0, Config.FloatHeight, 0)
    equipWeapon() -- Equipar al iniciar
end

-- Auto-Equipar al Morir
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        stopFarm()
        task.wait(1.5)
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local targetName = string.lower(Config.SelectedElement)
        local data = ElementData[targetName]

        if myRoot and data then
            local targetPos = Vector3.new(data.X, data.Y, data.Z)
            myRoot.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            myRoot.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.5)

            local tpsFolder = Workspace:FindFirstChild("TPS")
            if tpsFolder then
                local closestTele, shortestDist = nil, math.huge
                for _, obj in ipairs(tpsFolder:GetDescendants()) do
                    if obj:IsA("BasePart") and string.lower(obj.Name) == "teleporter" then
                        local dist = (obj.Position - targetPos).Magnitude
                        if dist < shortestDist then shortestDist = dist; closestTele = obj end
                    end
                end
                if closestTele then
                    local success = false
                    if getconnections then
                        for _, conn in pairs(getconnections(closestTele.Touched)) do
                            if conn.Enabled then pcall(function() conn:Fire(myRoot) success = true end) end
                        end
                    end
                    if not success then pcall(function() firetouchinterest(myRoot, closestTele, 0) task.wait(0.1) firetouchinterest(myRoot, closestTele, 1) end) end
                end
            end
        end
        task.wait(1)
        equipWeapon() -- 🔥 Volver a equipar el arma después de tocar la placa
        task.wait(0.5)
        startFarm()
    end
end))

-- Buscar caramelos
local function findClosestDrop()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, shortestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isDrop, part = false, nil
        local objName = string.lower(obj.Name)
        
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local isCharacter = obj.Parent:FindFirstChildOfClass("Humanoid") ~= nil
            if not isCharacter and obj ~= myRoot then
                local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
                if not obj.Anchored or (hasPrompt and (objName:find("soul") or objName:find("alma") or objName:find("candy"))) then
                    if obj.Size.Magnitude < 20 then isDrop = true; part = obj end
                end
            end
        end
        
        if isDrop and part then
            local dist = (part.Position - myRoot.Position).Magnitude
            if dist <= Config.SearchRadius and dist < shortestDist then
                shortestDist = dist; closest = part
            end
        end
    end
    return closest
end

-- Bucle de vuelo
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")

    if not char or not hum or not root or hum.Health <= 0 then return end

    hum.PlatformStand = true
    setLocalNoclip(true)

    -- 🔥 MANTENER EL ARMA EQUIPADA SIEMPRE
    if not tool then
        equipWeapon()
        tool = char:FindFirstChildOfClass("Tool")
    end

    -- Expandir Handle
    if tool then
        local handle = getHandle(tool)
        if handle and handle.Size ~= Vector3.new(Config.HandleSize, Config.HandleSize, Config.HandleSize) then
            expandHandle(tool)
        end
    end

    -- Lógica de vuelo
    if not currentTarget or not currentTarget.Parent then
        currentTarget = findClosestDrop()
    end

    if currentTarget then
        local dist = (currentTarget.Position - root.Position).Magnitude
        if dist > Config.CollectDistance then
            local direction = (currentTarget.Position - root.Position).Unit
            root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), currentTarget.Position)
            root.AssemblyLinearVelocity = Vector3.zero
        else
            pcall(function()
                firetouchinterest(root, currentTarget, 0)
                task.wait(0.05)
                firetouchinterest(root, currentTarget, 1)
            end)
            
            local prompt = currentTarget:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled and (string.lower(currentTarget.Name):find("soul") or string.lower(currentTarget.Name):find("alma")) then
                pcall(function() fireproximityprompt(prompt) end)
            end
            currentTarget = nil 
        end
    else
        -- Volver a flotar si no hay caramelos
        if hoverPosition then
            local distToHover = (hoverPosition - root.Position).Magnitude
            if distToHover > 2 then
                local direction = (hoverPosition - root.Position).Unit
                root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), hoverPosition)
            else
                root.CFrame = CFrame.new(hoverPosition)
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

function Config.Start()
    if Config.Enabled then return end
    Config.Enabled = true
    startFarm()
end

env.__BF_WAVEFARM_CLEANUP = function()
    stopFarm()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_WAVEFARM_CONFIG = nil
    env.__BF_WAVEFARM_CLEANUP = nil
end
