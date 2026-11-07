--// Froggy Hub - ElementalMagicArena/PlayerFarm.lua (ENTRY ANIMATION FIX)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_PLAYERFARM_CLEANUP then pcall(env.__BF_PLAYERFARM_CLEANUP) end

local Config = { Enabled = false, SelectedElement = "energy" }
env.BF_PLAYERFARM_CONFIG = Config

local ElementData = {
    ["energy"] = {Y=-14.51,X=816.06,Z=37.42},
    ["witchcraft"] = {Y=-17.33, X=694.72, Z=251.30},
    ["luck"] = {Y=-17.38, X=694.72, Z=136.30},
    ["nature"] = {Y=-17.38, X=694.72, Z=113.30},
    ["void"] = {Y=-17.33, X=694.72, Z=-45.70},
    ["infection"] = {Y=-17.33, X=694.72, Z=228.30},
    ["necromancy"] = {Y=-17.33, X=694.72, Z=-68.70},
    ["celestial"] = {Y=-17.38, X=694.72, Z=-22.70},
    ["gold"] = {Y=-17.35, X=694.72, Z=44.30},
    ["snow"] = {Y=-17.35, X=694.72, Z=67.30},
    ["dimension"] = {Y=-17.35, X=694.72, Z=90.30},
    ["nova"] = {Y=-17.33, X=694.72, Z=159.30},
    ["sand"] = {Y=-17.33, X=694.72, Z=-91.70},
    ["killstreak"] = {Y=-17.40, X=694.72, Z=0.30}
}

local FARM_X = 1451.5
local FARM_Y = -115.1
local FARM_Z = 85.7
local HIDE_DEPTH = 15 

local FarmPanel = nil
local weaponLoop = nil
local killTrackerCon = nil
local uiLoop = nil
local charAddedCon = nil
local mainLoopCon = nil
local isResetting = false

local kills = 0
local playerStates = {}
local currentFps = 60
local bodyPos = nil

local function spoofSkin()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("Decal") or part:IsA("Texture") or part:IsA("Shirt") or part:IsA("Pants") or part:IsA("Accessory") then
            part:Destroy()
        elseif part:IsA("BasePart") then
            part.Color = Color3.fromRGB(163, 162, 165)
            part.Material = Enum.Material.Plastic
        end
    end
end

local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function expandSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    if not handle:GetAttribute("FroggyOriginalSize") then
        handle:SetAttribute("FroggyOriginalSize", handle.Size)
        handle:SetAttribute("FroggyOriginalTransparency", handle.Transparency)
        handle:SetAttribute("FroggyOriginalCanCollide", handle.CanCollide)
    end
    handle.Size = Vector3.new(1000, 1000, 1000)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
    handle.CanTouch = true
end

local function restoreSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    local size = handle:GetAttribute("FroggyOriginalSize")
    if size then
        handle.Size = size
        handle.Transparency = handle:GetAttribute("FroggyOriginalTransparency")
        handle.CanCollide = handle:GetAttribute("FroggyOriginalCanCollide")
        handle:SetAttribute("FroggyOriginalSize", nil)
    end
end

local function equipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then pcall(function() hum:EquipTool(tool) end); break end
        end
    end
end

local function teleportToElement()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local targetName = string.lower(Config.SelectedElement)
    local data = ElementData[targetName] or ElementData["energy"]
    
    local ENERGY_POS = Vector3.new(data.X, data.Y, data.Z)
    myRoot.CFrame = CFrame.new(ENERGY_POS + Vector3.new(0, 3, 0))
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.5)
    
    local tpsFolder = Workspace:FindFirstChild("TPS")
    if tpsFolder then
        local closestTele, shortestDist = nil, math.huge
        for _, obj in ipairs(tpsFolder:GetDescendants()) do
            if obj:IsA("BasePart") and string.lower(obj.Name) == "teleporter" then
                local dist = (obj.Position - ENERGY_POS).Magnitude
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
    -- 🔥 AQUÍ ESTÁ EL FIX: Esperamos 3.5 segundos a que la animación del juego termine
    task.wait(3.5)
end

local function getGameStats()
    local diamonds, souls = 0, 0
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local d = stats:FindFirstChild("Diamonds") or stats:FindFirstChild("Gems")
        if d then diamonds = d.Value end
        local s = stats:FindFirstChild("Souls") or stats:FindFirstChild("Soul")
        if s then souls = s.Value end
    end
    return diamonds, souls
end

local function calculateHiddenPosition()
    local rayOrigin = Vector3.new(FARM_X, FARM_Y + 50, FARM_Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -500, 0), rayParams)
    if rayResult then return Vector3.new(FARM_X, rayResult.Position.Y - HIDE_DEPTH, FARM_Z)
    else return Vector3.new(FARM_X, FARM_Y - HIDE_DEPTH, FARM_Z) end
end

function startFarm()
    if weaponLoop then task.cancel(weaponLoop) end
    if killTrackerCon then task.cancel(killTrackerCon) end
    if uiLoop then task.cancel(uiLoop) end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- 🔥 FIX: Asegurarnos de que el juego no nos tenga anclados de la animación
    if root.Anchored then root.Anchored = false end
    
    root.AssemblyLinearVelocity = Vector3.zero
    hum.PlatformStand = true

    local bp = root:FindFirstChild("FarmBP")
    if bp then bp:Destroy() end
    bodyPos = Instance.new("BodyPosition")
    bodyPos.Name = "FarmBP"
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.Position = calculateHiddenPosition()
    bodyPos.P = 50000
    bodyPos.D = 2000
    bodyPos.Parent = root

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
    end

    spoofSkin()

    if not FarmPanel and env.BF_UI_LIBRARY then
        FarmPanel = env.BF_UI_LIBRARY.CreateFarmPanel({
            OnStop = function() Config.Enabled = false end
        })
    end

    weaponLoop = task.spawn(function()
        while Config.Enabled do
            local c = LocalPlayer.Character
            if c then
                local tool = c:FindFirstChildOfClass("Tool")
                if not tool then equipWeapon() task.wait(0.2)
                else
                    if getHandle(tool) then
                        expandSword(tool)
                        task.wait(0.25)
                        restoreSword(tool)
                        task.wait(0.25)
                    else task.wait(0.5) end
                end
            else task.wait(0.5) end
        end
    end)

    killTrackerCon = task.spawn(function()
        while Config.Enabled do
            task.wait(0.25)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local c = p.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then playerStates[p] = true
                    elseif playerStates[p] and (not h or h.Health <= 0) then kills = kills + 1; playerStates[p] = false end
                end
            end
        end
    end)

    uiLoop = task.spawn(function()
        while Config.Enabled do
            task.wait(0.5)
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if FarmPanel and h then
                local d, s = getGameStats()
                FarmPanel:UpdateUI(h.Health, h.MaxHealth, kills, d, s, currentFps)
            end
        end
    end)
end

local function stopFarm()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root then
        local bp = root:FindFirstChild("FarmBP"); if bp then bp:Destroy() end
        root.Anchored = true 
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(FARM_X, FARM_Y + 5, FARM_Z)
        root.Anchored = false
    end
    if hum then hum.PlatformStand = false; hum.Sit = false end
    if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end end end
    
    if FarmPanel then FarmPanel:Destroy(); FarmPanel = nil end
    if uiLoop then task.cancel(uiLoop); uiLoop = nil end
    if weaponLoop then task.cancel(weaponLoop); weaponLoop = nil end
    if killTrackerCon then task.cancel(killTrackerCon); killTrackerCon = nil end
    
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    playerStates = {}
    bodyPos = nil
end

if charAddedCon then charAddedCon:Disconnect() end
charAddedCon = LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        task.wait(2) -- Esperar a que cargue el personaje
        teleportToElement() -- Toca la placa y espera 3.5s a la animación
        equipWeapon()
        task.wait(0.5)
        startFarm() -- Ahora sí, nos vamos bajo el mapa sin conflicto
        isResetting = false
    end
end)

if mainLoopCon then task.cancel(mainLoopCon) end
mainLoopCon = task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.Enabled then
            if not FarmPanel and not isResetting and LocalPlayer.Character then
                isResetting = true
                task.spawn(function()
                    task.wait(2)
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end)
            end
        else
            if FarmPanel then stopFarm() end
            isResetting = false
        end
    end
end)

env.__BF_PLAYERFARM_CLEANUP = function()
    Config.Enabled = false
    stopFarm()
    if charAddedCon then charAddedCon:Disconnect(); charAddedCon = nil end
    if mainLoopCon then task.cancel(mainLoopCon); mainLoopCon = nil end
    env.BF_PLAYERFARM_CONFIG = nil
    env.__BF_PLAYERFARM_CLEANUP = nil
end
