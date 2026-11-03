--// Froggy Hub - ElementalMagicArena/PlayerFarm.lua (FIXED)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_PLAYERFARM_CLEANUP then pcall(env.__BF_PLAYERFARM_CLEANUP) end

local Config = {
    Enabled = false,
    SelectedElement = "energy",
    Kills = 0,
    Diamonds = 0,
    Souls = 0,
    CurrentHealth = 0,
    MaxHealth = 0
}
env.BF_PLAYERFARM_CONFIG = Config

local ElementData = {
    ["tierra"] = {Y=-14.15,X=817.53,Z=-81.78}, ["amor"] = {Y=-14.51,X=813.64,Z=398.44},
    ["demon"] = {Y=-14.51,X=816.40,Z=459.56}, ["ilusion"] = {Y=-14.51,X=815.66,Z=238.91},
    ["campos de fuerza"] = {Y=-14.51,X=814.67,Z=338.15}, ["agua"] = {Y=-14.13,X=815.78,Z=-101.62},
    ["relampago"] = {Y=-14.51,X=814.65,Z=-22.93}, ["oscuridad"] = {Y=-14.51,X=815.89,Z=78.65},
    ["life"] = {Y=-14.51,X=814.55,Z=517.56}, ["telequinesis"] = {Y=-14.51,X=815.17,Z=297.48},
    ["energy"] = {Y=-14.51,X=816.06,Z=37.42}, ["luz"] = {Y=-14.51,X=815.31,Z=16.66},
    ["diamante"] = {Y=-14.51,X=815.12,Z=378.49}, ["espiritu"] = {Y=-14.51,X=816.12,Z=177.92},
    ["mirror"] = {Y=-14.27,X=815.46,Z=496.70}, ["hierro"] = {Y=-14.51,X=816.46,Z=138.25},
    ["time"] = {Y=-14.51,X=815.46,Z=318.00}, ["lava"] = {Y=-14.51,X=816.40,Z=-2.52},
    ["veneno"] = {Y=-14.51,X=815.04,Z=118.56}, ["aurora"] = {Y=-14.51,X=814.31,Z=258.44},
    ["fenix"] = {Y=-14.51,X=816.67,Z=196.85}, ["dios de elementos"] = {Y=-14.51,X=752.07,Z=530.86},
    ["fuego"] = {Y=-14.15,X=816.63,Z=-120.46}, ["sueño"] = {Y=-14.51,X=813.53,Z=477.92},
    ["creacion"] = {Y=-14.51,X=815.37,Z=438.49}, ["espacio"] = {Y=-14.51,X=816.91,Z=57.76},
    ["realidad"] = {Y=-14.51,X=813.58,Z=418.34}, ["destruccion"] = {Y=-14.51,X=817.31,Z=158.61},
    ["aire"] = {Y=-14.15,X=814.21,Z=-61.69}, ["caos"] = {Y=-14.51,X=815.28,Z=279.75},
    ["tecnología"] = {Y=-14.51,X=814.77,Z=359.18}, ["cristal"] = {Y=-14.51,X=815.68,Z=219.55},
    ["sonido"] = {Y=-14.51,X=815.34,Z=97.98}, ["hielo"] = {Y=-14.15,X=816.05,Z=-41.79}
}

local connections = {}
local originalHandleData = {}
local M1Connection = nil
local CollectConnection = nil
local farmUI = nil
local statsLabel = nil

-- 1. Interfaz de Pantalla Negra
local function createFarmUI()
    if farmUI then farmUI:Destroy() end
    farmUI = Instance.new("ScreenGui")
    farmUI.Name = "FroggyFarmUI"
    farmUI.ResetOnSpawn = false
    farmUI.IgnoreGuiInset = true
    farmUI.DisplayOrder = 999
    farmUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = farmUI

    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -40, 0, 150)
    infoFrame.Position = UDim2.new(0, 20, 0, 50)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = farmUI

    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.fromScale(1, 1)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.TextSize = 20
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.Text = "FROGGY FARM\nIniciando..."
    statsLabel.Parent = infoFrame

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.fromOffset(200, 60)
    stopBtn.Position = UDim2.new(0.5, -100, 1, -100)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBlack
    stopBtn.TextSize = 24
    stopBtn.Text = "DETENER FARMEO"
    stopBtn.Parent = farmUI
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 12)

    stopBtn.MouseButton1Click:Connect(function()
        Config.Enabled = false
    end)

    task.spawn(function()
        while Config.Enabled and farmUI and farmUI.Parent do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                Config.CurrentHealth = math.floor(hum.Health)
                Config.MaxHealth = math.floor(hum.MaxHealth)
            end
            statsLabel.Text = string.format(
                "FROGGY FARM ACTIVO\n\nElemento: %s\nVida: %d / %d\nPlayers Eliminados: %d\nDiamantes: %d\nSouls: %d",
                string.upper(Config.SelectedElement), Config.CurrentHealth, Config.MaxHealth, Config.Kills, Config.Diamonds, Config.Souls
            )
            task.wait(0.5)
        end
    end)
end

-- 2. Forzar Equipamiento
local function equipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char:FindFirstChildOfClass("Tool") then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() hum:EquipTool(tool) end)
            break
        end
    end
end

-- 3. Teletransporte a la placa al morir
local function teleportToElement()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetName = string.lower(Config.SelectedElement)
    local data = ElementData[targetName]
    if not data then return end

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

-- 4. Sistema de Combate (Fijar en el cielo de la arena + Hitbox)
local function startCombat()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- 🔥 FIX: Fijar 100 studs arriba de donde está la arena actual, no en 0,0,0
    local arenaX, arenaZ = root.Position.X, root.Position.Z
    root.Anchored = true
    root.CFrame = CFrame.new(arenaX, 100, arenaZ) -- 100 studs de altura sobre la arena

    -- Expandir Handle
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if handle then
            if not originalHandleData[handle] then
                originalHandleData[handle] = { Size = handle.Size, Transparency = handle.Transparency, CanCollide = handle.CanCollide }
            end
            handle.Size = Vector3.new(1000, 1000, 1000)
            handle.Transparency = 1
            handle.CanCollide = false
            handle.CanTouch = true
        end
    end

    -- Spam M1 (Clic en el centro de la pantalla para registrar el golpe)
    if M1Connection then M1Connection:Disconnect() end
    M1Connection = task.spawn(function()
        local camera = Workspace.CurrentCamera
        while Config.Enabled do
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Tool") then
                pcall(function()
                    -- Clic en el centro de la pantalla
                    local cx = camera.ViewportSize.X / 2
                    local cy = camera.ViewportSize.Y / 2
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                end)
            else
                equipWeapon() -- Si perdió el arma, la equipa de nuevo
            end
            task.wait(0.15)
        end
    end)
end

-- 5. Recolección
local DiamondNames = {"diamond", "gem", "coin", "cash", "drop", "reward", "loot", "money"}
local SoulNames = {"soul", "alma"}

local function startCollecting()
    if CollectConnection then CollectConnection:Disconnect() end
    CollectConnection = task.spawn(function()
        while Config.Enabled do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    local name = string.lower(obj.Name)
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        if not obj.Parent:FindFirstChildOfClass("Humanoid") then
                            for _, dName in ipairs(DiamondNames) do
                                if name:find(dName) then
                                    pcall(function()
                                        firetouchinterest(myRoot, obj, 0)
                                        task.wait(0.01)
                                        firetouchinterest(myRoot, obj, 1)
                                        Config.Diamonds = Config.Diamonds + 1
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local pName = string.lower(obj.Name .. obj.ObjectText .. obj.ActionText)
                        for _, sName in ipairs(SoulNames) do
                            if pName:find(sName) then
                                pcall(function()
                                    fireproximityprompt(obj)
                                    Config.Souls = Config.Souls + 1
                                end)
                                break
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- 6. Auto-Equipar y subir al cielo al respawnear
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        task.wait(1.5)
        teleportToElement()
        task.wait(1)
        equipWeapon()
        task.wait(0.5)
        startCombat()
    end
end))

-- 7. Bucle Principal
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not farmUI then
                pcall(function() game:GetService("SoundService").RespectFilteringEnabled = false end)
                for _, sound in ipairs(Workspace:GetDescendants()) do
                    if sound:IsA("Sound") then sound.Volume = 0 end
                end
                createFarmUI()
                
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    if not char:FindFirstChildOfClass("Tool") then equipWeapon() end
                    startCombat()
                    startCollecting()
                end
            end
        else
            if farmUI then farmUI:Destroy(); farmUI = nil end
            if M1Connection then task.cancel(M1Connection); M1Connection = nil end
            if CollectConnection then task.cancel(CollectConnection); CollectConnection = nil end
            pcall(function() game:GetService("SoundService").RespectFilteringEnabled = true end)

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end

            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle and originalHandleData[handle] then
                    local data = originalHandleData[handle]
                    handle.Size = data.Size
                    handle.Transparency = data.Transparency
                    handle.CanCollide = data.CanCollide
                    originalHandleData[handle] = nil
                end
            end
        end
    end
end)

env.__BF_PLAYERFARM_CLEANUP = function()
    Config.Enabled = false
    env.BF_PLAYERFARM_CONFIG = nil
    env.__BF_PLAYERFARM_CLEANUP = nil
end
