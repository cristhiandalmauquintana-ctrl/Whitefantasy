--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V25 - Aspirador Universal)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    SearchRadius = 2000,     -- Radio de búsqueda de drops
    SelectedElement = "Light", 
    HandleSize = 3000,       -- Tamaño de la espada
    FloatHeight = 15,        -- Altura de vuelo
    AutoClickRate = 1.0,     -- 🔥 Lento: 1 clic por segundo
    FlySpeed = 60,           
    CollectDistance = 5,     
}
env.BF_WAVEFARM_CONFIG = Config

local connections = {}
local originalHandleData = {}
local autoClickThread = nil
local startPosition = nil
local arenaCenter = nil
local currentTarget = nil

-- ==========================================
-- NOCLIP SEGURO (Solo para el personaje)
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
-- FUNCIONES DE PLACA Y ARMA
-- ==========================================
local function goToElementPlate()
    local targetElement = string.lower(Config.SelectedElement)
    local platePart = nil

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if name:find(targetElement) and (name:find("plate") or name:find("pad") or name:find("statue") or name:find("base")) then
                platePart = obj
                break
            end
        end
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    
    if platePart and myRoot then
        myRoot.CFrame = CFrame.new(platePart.Position + Vector3.new(0, 3, 0))
        myRoot.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.5) 
        
        local prompt = platePart:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then pcall(function() fireproximityprompt(prompt) end) end
        local clicker = platePart:FindFirstChildWhichIsA("ClickDetector")
        if clicker then pcall(function() fireclickdetector(clicker) end) end
        
        pcall(function()
            firetouchinterest(myRoot, platePart, 0)
            task.wait(0.1)
            firetouchinterest(myRoot, platePart, 1)
        end)
    end
end

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
    if autoClickThread then task.cancel(autoClickThread) autoClickThread = nil end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")

    setLocalNoclip(false)
    if hum then hum.PlatformStand = false end
    if root and startPosition then root.CFrame = startPosition end
    if tool then restoreHandle(tool) end
end

local function startFarm()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end

    -- Guardar posición actual y establecer centro de la arena
    startPosition = root.CFrame
    arenaCenter = root.CFrame + Vector3.new(0, Config.FloatHeight, 0)
    
    hum.PlatformStand = true
    root.CFrame = arenaCenter
    root.AssemblyLinearVelocity = Vector3.zero
    
    setLocalNoclip(true)

    equipWeapon()
    task.wait(0.2)
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then expandHandle(tool) end

    if autoClickThread then task.cancel(autoClickThread) end
    autoClickThread = task.spawn(function()
        while Config.Enabled do
            local c = LocalPlayer.Character
            local t = c and c:FindFirstChildOfClass("Tool")
            if t then pcall(function() t:Activate() end) end
            task.wait(Config.AutoClickRate)
        end
    end)
end

-- ==========================================
-- ASPIRADOR UNIVERSAL DE DROPS
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

        -- Ignorar partes del mapa, personajes y jugadores
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local parent = obj.Parent
            local isCharacter = parent:FindFirstChildOfClass("Humanoid") ~= nil
            local isLocalChar = parent == char
            
            -- 🔥 Lógica del Aspirador: Si NO está anclado (cae) o tiene un prompt, es un drop
            local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
            
            if not isCharacter and not isLocalChar then
                if not obj.Anchored or hasPrompt then
                    -- Evitar partes gigantes del mapa
                    if obj.Size.Magnitude < 20 then
                        isDrop = true
                        part = obj
                    end
                end
            end
        elseif obj:IsA("Model") then
            -- Algunos drops son Modelos (como cofres)
            local primary = obj.PrimaryPart
            local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
            if primary and (not primary.Anchored or hasPrompt) then
                isDrop = true
                part = primary
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
        goToElementPlate() 
        task.wait(2.5)     
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

    if not hum.PlatformStand then hum.PlatformStand = true end
    root.AssemblyLinearVelocity = Vector3.zero
    setLocalNoclip(true)

    if tool then
        local handle = getHandle(tool)
        if handle and handle.Size ~= Vector3.new(Config.HandleSize, Config.HandleSize, Config.HandleSize) then
            expandHandle(tool)
        end
    end

    -- Vuelo y Recolección
    if not currentTarget or not currentTarget.Parent then
        currentTarget = findClosestDrop()
    end

    if currentTarget then
        local dist = (currentTarget.Position - root.Position).Magnitude
        if dist > Config.CollectDistance then
            local direction = (currentTarget.Position - root.Position).Unit
            root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), currentTarget.Position)
        else
            -- Recoger
            pcall(function()
                firetouchinterest(root, currentTarget, 0)
                task.wait(0.05)
                firetouchinterest(root, currentTarget, 1)
            end)
            
            local prompt = currentTarget:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                pcall(function() fireproximityprompt(prompt) end)
            end
            
            currentTarget = nil 
        end
    else
        -- 🔥 VOLVER AL CENTRO DE LA ARENA
        local distToCenter = (arenaCenter.Position - root.Position).Magnitude
        if distToCenter > 10 then
            local direction = (arenaCenter.Position - root.Position).Unit
            root.CFrame = CFrame.lookAt(root.Position + (direction * Config.FlySpeed * dt), arenaCenter.Position)
        else
            -- Mantenerse en el centro flotando
            root.CFrame = CFrame.new(arenaCenter.Position) 
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
