--// Froggy Hub - ElementalMagicArena/PlayerFarm.lua (ULTRA OPTIMIZED)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_PLAYERFARM_CLEANUP then pcall(env.__BF_PLAYERFARM_CLEANUP) end

local Config = { Enabled = false }
env.BF_PLAYERFARM_CONFIG = Config

local FARM_X = 1451.5
local FARM_Y = -115.1
local FARM_Z = 85.7
local HIDE_DEPTH = 15 

local FarmPanel = nil
local weaponLoop = nil
local killTrackerCon = nil
local uiLoop = nil
local soulEventCon = nil
local honeypotEventCon = nil
local charAddedCon = nil
local mainLoopCon = nil
local thumbnailCon = nil
local isResetting = false

local kills = 0
local playerStates = {}
local currentFps = 60
local bodyPos = nil
local currentSoulTarget = nil

RunService.RenderStepped:Connect(function()
    local frames = 0
    local lastT = os.clock()
    frames += 1
    local now = os.clock()
    if now - lastT >= 1 then currentFps = frames; frames, lastT = 0, now end
end)

-- 1. SKIN SPOOFER
local function spoofSkin()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("Decal") or part:IsA("Texture") or part:IsA("Shirt") or part:IsA("Pants") or part:IsA("Accessory") then
            part:Destroy()
        elseif part:IsA("BasePart") then
            part.Color = Color3.fromRGB(163, 162, 165)
            part.Material = Enum.Material.Plastic
            if part.Name == "Head" then
                local face = part:FindFirstChild("face")
                if face then face:Destroy() end
            end
        end
    end
end

-- 2. OCULTAR FOTO
local function startThumbnailHider()
    if thumbnailCon then task.cancel(thumbnailCon) end
    thumbnailCon = task.spawn(function()
        while Config.Enabled do
            task.wait(2) -- Menos frecuente para no consumir CPU
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, obj in ipairs(playerGui:GetDescendants()) do
                    if obj:IsA("ImageLabel") and string.find(obj.Image, tostring(LocalPlayer.UserId)) then
                        obj.Image = "rbxassetid://0"
                        obj.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
                    end
                end
            end
        end
    end)
end

-- 3. EVENTOS DE HONEYPOTS (Optimizado sin bucles)
local function checkHoneypot(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("Model") or obj:IsA("BasePart") then
        local name = string.lower(obj.Name)
        if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_npc") or name:find("honeypot") or name:find("trap") then
            if not obj:GetAttribute("FroggyIgnored") then
                obj:SetAttribute("FroggyIgnored", true)
                obj.Parent = ReplicatedStorage
            end
        end
    end
end

local function setupHoneypotEvents()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        honeypotEventCon = enemies.DescendantAdded:Connect(checkHoneypot)
        for _, child in ipairs(enemies:GetChildren()) do checkHoneypot(child) end
    end
end

-- 4. SOUL SNIPER (Optimizado con evento en lugar de escaneo)
local function checkSoulPrompt(obj)
    if not obj or not obj:IsA("ProximityPrompt") then return end
    local name = string.lower(obj.Name .. obj.ObjectText .. obj.ActionText)
    if (string.find(name, "soul") or string.find(name, "alma")) and not string.find(name, "shop") then
        -- Detectamos un alma, si no tenemos un objetivo actual, lo tomamos
        if not currentSoulTarget and Config.Enabled and bodyPos then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                currentSoulTarget = obj
            end
        end
    end
end

local function setupSoulEvents()
    soulEventCon = Workspace.DescendantAdded:Connect(checkSoulPrompt)
end

-- Bucle para procesar las almas (Solo se ejecuta si hay un objetivo guardado)
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled and currentSoulTarget and bodyPos then
            local part = currentSoulTarget.Parent
            if part and part:IsA("BasePart") then
                -- 1. Bajar al alma
                bodyPos.Position = part.Position
                task.wait(0.1)
                -- 2. Activar el prompt
                pcall(function() fireproximityprompt(currentSoulTarget) end)
                -- 3. Volver al cielo
                task.wait(0.1)
                bodyPos.Position = Vector3.new(FARM_X, FARM_Y - HIDE_DEPTH, FARM_Z)
            end
            currentSoulTarget = nil -- Liberar para la siguiente alma
        end
    end
end)

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

local function toggleModules(state)
    if env.BF_ATTACKALL_CONFIG then env.BF_ATTACKALL_CONFIG.Enabled = state end
    if env.BF_HITBOX_CONFIG then env.BF_HITBOX_CONFIG.Enabled = state end
    if env.BF_SILENTCOLLECT_CONFIG then env.BF_SILENTCOLLECT_CONFIG.Enabled = state end
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

local function teleportToEnergy()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local ENERGY_POS = Vector3.new(816.06640625, -14.519143104553223, 37.429420471191409)
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
    task.wait(1.5)
end

local function calculateHiddenPosition()
    local rayOrigin = Vector3.new(FARM_X, FARM_Y + 50, FARM_Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -500, 0), rayParams)
    if rayResult then
        return Vector3.new(FARM_X, rayResult.Position.Y - HIDE_DEPTH, FARM_Z)
    else
        return Vector3.new(FARM_X, FARM_Y - HIDE_DEPTH, FARM_Z)
    end
end

function startFarm()
    if weaponLoop then task.cancel(weaponLoop) end
    if killTrackerCon then task.cancel(killTrackerCon) end
    if uiLoop then task.cancel(uiLoop) end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local hiddenPos = calculateHiddenPosition()

    root.Anchored = false
    hum.PlatformStand = true

    local bp = root:FindFirstChild("FarmBP")
    if bp then bp:Destroy() end
    bodyPos = Instance.new("BodyPosition")
    bodyPos.Name = "FarmBP"
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.Position = hiddenPos
    bodyPos.P = 50000
    bodyPos.D = 2000
    bodyPos.Parent = root

    local bg = root:FindFirstChild("FarmBG")
    if bg then bg:Destroy() end
    bg = Instance.new("BodyGyro")
    bg.Name = "FarmBG"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.CFrame = root.CFrame
    bg.P = 50000
    bg.D = 2000
    bg.Parent = root

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
    end

    toggleModules(true)
    spoofSkin()
    startThumbnailHider()
    
    -- Setup de eventos
    setupHoneypotEvents()
    setupSoulEvents()

    -- Hook Anti-KillFeed
    if hookmetamethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                local args = {...}
                local name = string.lower(self.Name)
                if string.find(name, "kill") or string.find(name, "death") or string.find(name, "damage") or string.find(name, "combat") then
                    for i, arg in ipairs(args) do
                        if arg == LocalPlayer.Character or arg == LocalPlayer.Name or arg == LocalPlayer then
                            args[i] = "Anon"
                        end
                    end
                    return oldNamecall(self, table.unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end)
    end

    if not FarmPanel and env.BF_UI_LIBRARY then
        FarmPanel = env.BF_UI_LIBRARY.CreateFarmPanel({
            OnStop = function() Config.Enabled = false end
        })
    end

    weaponLoop = task.spawn(function()
        while Config.Enabled do
            local c = LocalPlayer.Character
            if c and not c:FindFirstChildOfClass("Tool") then equipWeapon() end
            if env.BF_ATTACKALL_CONFIG then env.BF_ATTACKALL_CONFIG.Enabled = true end
            task.wait(0.5)
        end
    end)

    killTrackerCon = task.spawn(function()
        while Config.Enabled do
            task.wait(0.2) -- 0.2 es suficiente para contar kills
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
    toggleModules(false)
    if root then
        local bp = root:FindFirstChild("FarmBP"); if bp then bp:Destroy() end
        local bg = root:FindFirstChild("FarmBG"); if bg then bg:Destroy() end
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
    if thumbnailCon then task.cancel(thumbnailCon); thumbnailCon = nil end
    
    if soulEventCon then soulEventCon:Disconnect(); soulEventCon = nil end
    if honeypotEventCon then honeypotEventCon:Disconnect(); honeypotEventCon = nil end
    
    playerStates = {}
    currentSoulTarget = nil
    bodyPos = nil
end

if charAddedCon then charAddedCon:Disconnect() end
charAddedCon = LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        task.wait(2)
        teleportToEnergy()
        task.wait(1)
        equipWeapon()
        task.wait(0.5)
        startFarm()
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
