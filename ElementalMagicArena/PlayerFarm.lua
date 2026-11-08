--// Froggy Hub - ElementalMagicArena/PlayerFarm.lua (V39 - TRUE AUTO FARM)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_PLAYERFARM_CLEANUP then pcall(env.__BF_PLAYERFARM_CLEANUP) end

local Config = { Enabled = false, SelectedElement = "energy" }
env.BF_PLAYERFARM_CONFIG = Config

local ElementData = {
    ["energy"] = {Y=-14.51,X=816.06,Z=37.42}, ["luz"] = {Y=-14.51,X=815.31,Z=16.66},
    ["fuego"] = {Y=-14.15,X=816.63,Z=-120.46}, ["agua"] = {Y=-14.13,X=815.78,Z=-101.62},
    ["hielo"] = {Y=-14.15,X=816.05,Z=-41.79}, ["tierra"] = {Y=-14.15,X=817.53,Z=-81.78},
    ["aire"] = {Y=-14.15,X=814.21,Z=-61.69}, ["oscuridad"] = {Y=-14.51,X=815.89,Z=78.65},
    ["lava"] = {Y=-14.51,X=816.40,Z=-2.52}, ["veneno"] = {Y=-14.51,X=815.04,Z=118.56},
    ["hierro"] = {Y=-14.51,X=816.46,Z=138.25}, ["espiritu"] = {Y=-14.51,X=816.12,Z=177.92},
    ["destruccion"] = {Y=-14.51,X=817.31,Z=158.61}, ["cristal"] = {Y=-14.51,X=815.68,Z=219.55},
    ["sonido"] = {Y=-14.51,X=815.34,Z=97.98}, ["aurora"] = {Y=-14.51,X=814.31,Z=258.44},
    ["fenix"] = {Y=-14.51,X=816.67,Z=196.85}, ["caos"] = {Y=-14.51,X=815.28,Z=279.75},
    ["tecnología"] = {Y=-14.51,X=814.77,Z=359.18}, ["diamante"] = {Y=-14.51,X=815.12,Z=378.49},
    ["amor"] = {Y=-14.51,X=813.64,Z=398.44}, ["demon"] = {Y=-14.51,X=816.40,Z=459.56},
    ["ilusion"] = {Y=-14.51,X=815.66,Z=238.91}, ["campos de fuerza"] = {Y=-14.51,X=814.67,Z=338.15},
    ["relampago"] = {Y=-14.51,X=814.65,Z=-22.93}, ["telequinesis"] = {Y=-14.51,X=815.17,Z=297.48},
    ["life"] = {Y=-14.51,X=814.55,Z=517.56}, ["mirror"] = {Y=-14.27,X=815.46,Z=496.70},
    ["time"] = {Y=-14.51,X=815.46,Z=318.00}, ["sueño"] = {Y=-14.51,X=813.53,Z=477.92},
    ["creacion"] = {Y=-14.51,X=815.37,Z=438.49}, ["espacio"] = {Y=-14.51,X=816.91,Z=57.76},
    ["realidad"] = {Y=-14.51,X=813.58,Z=418.34}, ["dios de elementos"] = {Y=-14.51,X=752.07,Z=530.86},
    ["witchcraft"] = {Y=-17.33, X=694.72, Z=251.30}, ["luck"] = {Y=-17.38, X=694.72, Z=136.30},
    ["nature"] = {Y=-17.38, X=694.72, Z=113.30}, ["void"] = {Y=-17.33, X=694.72, Z=-45.70},
    ["infection"] = {Y=-17.33, X=694.72, Z=228.30}, ["necromancy"] = {Y=-17.33, X=694.72, Z=-68.70},
    ["celestial"] = {Y=-17.38, X=694.72, Z=-22.70}, ["gold"] = {Y=-17.35, X=694.72, Z=44.30},
    ["snow"] = {Y=-17.35, X=694.72, Z=67.30}, ["dimension"] = {Y=-17.35, X=694.72, Z=90.30},
    ["nova"] = {Y=-17.33, X=694.72, Z=159.30}, ["sand"] = {Y=-17.33, X=694.72, Z=-91.70},
    ["killstreak"] = {Y=-17.40, X=694.72, Z=0.30}
}

local FARM_X = 1451.5
local FARM_Y = -115.1
local FARM_Z = 85.7
local HIDE_DEPTH = 15 

local FarmPanel = nil
local killTrackerCon = nil
local uiLoop = nil
local uiCleanerCon = nil
local bodyPos = nil
local playerStates = {}
local kills = 0
local currentFps = 60
local isRestarting = false

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

local function onGuiAdded(obj)
    if not Config.Enabled or not obj then return end
    if obj:IsA("ScreenGui") or obj:IsA("Frame") then
        local name = string.lower(obj.Name)
        if not name:find("froggy") then
            if name == "howtounlockgui" or name == "luckelementpopupgui" or name == "survivalsquadgui" then
                obj:Destroy()
            end
        end
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

-- 🔥 FUNCIÓN DE INICIO LIMPIA
local function startFarm()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- Ir a la placa
    local targetName = string.lower(Config.SelectedElement)
    local data = ElementData[targetName] or ElementData["energy"]
    local ENERGY_POS = Vector3.new(data.X, data.Y, data.Z)
    
    root.CFrame = CFrame.new(ENERGY_POS + Vector3.new(0, 3, 0))
    root.AssemblyLinearVelocity = Vector3.zero
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
                    if conn.Enabled then pcall(function() conn:Fire(root) success = true end) end
                end
            end
            if not success then pcall(function() firetouchinterest(root, closestTele, 0) task.wait(0.1) firetouchinterest(root, closestTele, 1) end) end
        end
    end
    
    task.wait(2.5) -- Espera LARGA para que el juego te dé el arma
    equipWeapon()
    task.wait(0.5)

    -- Subir al cielo
    root.Anchored = false
    hum.PlatformStand = true

    local bp = Instance.new("BodyPosition")
    bp.Name = "FarmBP"
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    
    local rayOrigin = Vector3.new(FARM_X, FARM_Y + 50, FARM_Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -500, 0), rayParams)
    local hiddenPos = rayResult and Vector3.new(FARM_X, rayResult.Position.Y - HIDE_DEPTH, FARM_Z) or Vector3.new(FARM_X, FARM_Y - HIDE_DEPTH, FARM_Z)
    
    bp.Position = hiddenPos
    bp.P = 50000
    bp.D = 2000
    bp.Parent = root
    bodyPos = bp

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
    end

    spoofSkin()

    if env.BF_ATTACKALL_CONFIG then 
        env.BF_ATTACKALL_CONFIG.Enabled = true 
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        if uiCleanerCon then uiCleanerCon:Disconnect() end
        uiCleanerCon = pg.DescendantAdded:Connect(function(obj)
            task.defer(function() onGuiAdded(obj) end)
        end)
    end

    if not FarmPanel and env.BF_UI_LIBRARY then
        FarmPanel = env.BF_UI_LIBRARY.CreateFarmPanel({
            OnStop = function() Config.Enabled = false end
        })
    end

    if killTrackerCon then task.cancel(killTrackerCon) end
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

    if uiLoop then task.cancel(uiLoop) end
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
    if env.BF_ATTACKALL_CONFIG then 
        env.BF_ATTACKALL_CONFIG.Enabled = false 
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root then
        local bp = root:FindFirstChild("FarmBP"); if bp then bp:Destroy() end
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then hum.PlatformStand = false; hum.Sit = false end
    
    if FarmPanel then FarmPanel:Destroy(); FarmPanel = nil end
    if uiLoop then task.cancel(uiLoop); uiLoop = nil end
    if killTrackerCon then task.cancel(killTrackerCon); killTrackerCon = nil end
    if uiCleanerCon then uiCleanerCon:Disconnect(); uiCleanerCon = nil end
    
    playerStates = {}
    bodyPos = nil
end

-- 🔥 AUTO-RESPAWN ORDENADO
LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled and not isRestarting then
        isRestarting = true
        -- Limpiamos cualquier panel viejo
        if FarmPanel then FarmPanel:Destroy(); FarmPanel = nil end
        
        task.wait(3) -- Espera crítica para que el juego cargue el personaje
        if Config.Enabled then
            startFarm()
        end
        isRestarting = false
    end
end)

-- 🔥 BUCLE PRINCIPAL (Solo mantiene el AttackAll y verifica el panel)
task.spawn(function()
    local lastState = false
    while task.wait(0.5) do
        if Config.Enabled then
            -- Si el panel no existe y no estamos en medio de un reinicio, iniciamos
            if not FarmPanel and not isRestarting and LocalPlayer.Character then
                isRestarting = true
                startFarm()
                isRestarting = false
            end
            
            -- Mantener AttackAll encendido
            if env.BF_ATTACKALL_CONFIG and not env.BF_ATTACKALL_CONFIG.Enabled then
                env.BF_ATTACKALL_CONFIG.Enabled = true
            end
        elseif not Config.Enabled and lastState then
            stopFarm()
        end
        lastState = Config.Enabled
    end
end)

env.__BF_PLAYERFARM_CLEANUP = function()
    Config.Enabled = false
    stopFarm()
    env.BF_PLAYERFARM_CONFIG = nil
    env.__BF_PLAYERFARM_CLEANUP = nil
end
