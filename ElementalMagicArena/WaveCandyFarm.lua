--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V28 - Sin AutoClick)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    SearchRadius = 2000,     
    SelectedElement = "Light", 
    HandleSize = 3000,       
    FloatHeight = 50,        -- Sube 50 studs
    FlySpeed = 60,           
    CollectDistance = 5,     
}
env.BF_WAVEFARM_CONFIG = Config

local connections = {}
local originalHandleData = {}
local anchorPosition = nil
local currentTarget = nil

-- ==========================================
-- NOCLIP SEGURO
-- ==========================================
local function setLocalNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

-- ==========================================
-- FUNCIONES DE ARMA
-- ==========================================
local function equipWeapon()
    local char = LocalPlayer.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") or name:find("dark") then
                pcall(function() char.Humanoid:EquipTool(tool) end)
                break
            end
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

-- ==========================================
-- ESTADO DEL FARM
-- ==========================================
local function stopFarm()
    Config.Enabled = false

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")

    if root then root.Anchored = false end
    setLocalNoclip(false)
    if hum then hum.PlatformStand = false end
    if tool then restoreHandle(tool) end
end

local function startFarm()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end

    -- 🔥 FIJAR POSICIÓN 50 STUDS ARRIBA
    anchorPosition = root.Position + Vector3.new(0, Config.FloatHeight, 0)
    
    hum.PlatformStand = true
    setLocalNoclip(true)
    
    root.CFrame = CFrame.new(anchorPosition)
    root.AssemblyLinearVelocity = Vector3.zero
    root.Anchored = true -- 🔥 Clavado en el aire

    equipWeapon()
    task.wait(0.2)
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then expandHandle(tool) end
end

-- ==========================================
-- BÚSQUEDA ESTRICTA DE DROPS
-- ==========================================
local function findClosestDrop()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest = nil
    local shortestDist = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isDrop = false
        local part = nil
        
        local objName = string.lower(obj.Name)
        local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""

        -- 🛑 Evitar tiendas, gacha, cofres de la base
        if not objName:find("shop") and not objName:find("gacha") and not parentName:find("shop") and not parentName:find("gacha") then
            
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local isCharacter = obj.Parent:FindFirstChildOfClass("Humanoid") ~= nil
                
                if not isCharacter and obj ~= myRoot then
                    local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
                    if not obj.Anchored or (hasPrompt and (objName:find("soul") or objName:find("alma") or objName:find("candy"))) then
                        if obj.Size.Magnitude < 20 then
                            isDrop = true
                            part = obj
                        end
                    end
                end
            end
        end

        if isDrop and part then
            local dist = (part.Position - myRoot.Position).Magnitude
            if dist <= Config.SearchRadius and dist < shortestDist then
                shortestDist = dist
                closest = part
            end
        end
    end
    return closest
end

-- ==========================================
-- RESPAWN Y BUCLE
-- ==========================================
table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function() stopFarm() end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
    if Config.Enabled then
        stopFarm()
        task.wait(1.5) 
        startFarm()
    end
end))

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")

    if not char or not hum or not root then return end

    -- Mantener Handle
    if tool then
        local handle = getHandle(tool)
        if handle and handle.Size ~= Vector3.new(Config.HandleSize, Config.HandleSize, Config.HandleSize) then
            expandHandle(tool)
        end
    end

    if not currentTarget or not currentTarget.Parent then
        currentTarget = findClosestDrop()
    end

    if currentTarget then
        root.Anchored = false
        
        local dist = (currentTarget.Position - root.Position).Magnitude
        if dist > Config.CollectDistance then
            local direction = (currentTarget.Position - root.Position).Unit
            root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), currentTarget.Position)
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
        local distToAnchor = (anchorPosition - root.Position).Magnitude
        if distToAnchor > 2 then
            root.Anchored = false 
            local direction = (anchorPosition - root.Position).Unit
            root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), anchorPosition)
        else
            root.Anchored = true 
            root.CFrame = CFrame.new(anchorPosition)
            root.AssemblyLinearVelocity = Vector3.zero
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
