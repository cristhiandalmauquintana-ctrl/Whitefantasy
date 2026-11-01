--// Froggy Hub - ElementalMagicArena/CarTransform.lua
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_CARTRANSFORM_CLEANUP then pcall(env.__BF_CARTRANSFORM_CLEANUP) end

local Config = {
    Enabled = false,
    CarID = 15244136642,
    MaxSpeed = 150,
    Acceleration = 80,
    Deceleration = 120,
    CarAngle = 180,
    HeightOffset = 0,
    HitRadius = 10,
    Damage = 1000
}
env.BF_CARTRANSFORM_CONFIG = Config

local myCar = nil
local moveConnection = nil
local speedConnection = nil
local hitConnection = nil
local currentSpeed = 0
local hitCooldowns = {}
local savedToolData = {}

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
end

local function launchEnemy(enemyHum, enemyRoot)
    if not enemyHum or not enemyRoot or enemyHum.Health <= 0 then return end
    local now = os.clock()
    if hitCooldowns[enemyHum] and (now - hitCooldowns[enemyHum]) < 1 then return end
    hitCooldowns[enemyHum] = now

    enemyHum:TakeDamage(Config.Damage)
    enemyHum.PlatformStand = true

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local dir = (enemyRoot.Position - myRoot.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = (dir * 100) + Vector3.new(0, 50, 0)
    bv.Parent = enemyRoot

    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.AngularVelocity = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
    bav.Parent = enemyRoot

    task.delay(0.5, function()
        if bv then bv:Destroy() end
        if bav then bav:Destroy() end
        if enemyHum and enemyHum.Parent then enemyHum.PlatformStand = false end
    end)
end

local function enterCar()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end

    currentSpeed = 0
    hum.JumpPower = 50

    -- Invisibilidad
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end

    -- Hitbox de arma
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool then
        for _, part in ipairs(equippedTool:GetDescendants()) do
            if part:IsA("BasePart") then
                savedToolData[part] = {Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide}
                part.Size = Vector3.new(20, 20, 20)
                part.Transparency = 1
                part.CanCollide = false
                part.CanTouch = true
                part.Touched:Connect(function(hit)
                    if hit and hit.Parent then
                        local eHum = hit.Parent:FindFirstChildOfClass("Humanoid")
                        local eRoot = hit.Parent:FindFirstChild("HumanoidRootPart") or hit.Parent:FindFirstChild("Torso")
                        if eHum and eRoot and hit.Parent ~= char then launchEnemy(eHum, eRoot) end
                    end
                end)
            end
        end
    end

    -- Aceleración
    speedConnection = RunService.Heartbeat:Connect(function(dt)
        if not hum or hum.Health <= 0 then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            currentSpeed = math.min(Config.MaxSpeed, currentSpeed + (Config.Acceleration * dt))
        else
            currentSpeed = math.max(0, currentSpeed - (Config.Deceleration * dt))
        end
        hum.WalkSpeed = currentSpeed
    end)

    -- Movimiento y Hitbox de seguridad
    moveConnection = RunService.RenderStepped:Connect(function()
        if not myCar or not myCar.Parent or not root then return end
        local targetCFrame = root.CFrame * CFrame.new(0, Config.HeightOffset, 0) * CFrame.Angles(0, math.rad(Config.CarAngle), 0)
        myCar:PivotTo(targetCFrame)

        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, npc in ipairs(enemies:GetChildren()) do
                local eRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
                local eHum = npc:FindFirstChildOfClass("Humanoid")
                if eRoot and eHum and eHum.Health > 0 then
                    if (eRoot.Position - root.Position).Magnitude <= Config.HitRadius then
                        launchEnemy(eHum, eRoot)
                    end
                end
            end
        end
    end)
end

local function exitCar()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
    if speedConnection then speedConnection:Disconnect(); speedConnection = nil end

    for part, data in pairs(savedToolData) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
        end
    end
    savedToolData = {}

    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.CanCollide = true
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        end
    end

    currentSpeed = 0
    hitCooldowns = {}
end

local function spawnCar()
    if myCar then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local success, model = pcall(function() return InsertService:LoadAsset(Config.CarID):GetChildren()[1] end)
    if not success or not model then
        success, model = pcall(function() return game:GetObjects("rbxassetid://" .. Config.CarID)[1] end)
    end
    if not model then 
        notify("Error", "No se pudo cargar el auto.")
        return 
    end

    myCar = model
    myCar.Name = "FroggySuperCar"
    
    for _, part in ipairs(myCar:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = true; part.CanCollide = false end
    end

    myCar:PivotTo(root.CFrame * CFrame.new(0, Config.HeightOffset, 0))
    myCar.Parent = workspace
    
    task.wait(0.1)
    enterCar()
end

-- Loop principal que verifica si está activado o desactivado
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not myCar then spawnCar() end
        else
            if myCar then
                exitCar()
                myCar:Destroy()
                myCar = nil
            end
        end
    end
end)

env.__BF_CARTRANSFORM_CLEANUP = function()
    Config.Enabled = false
    if myCar then exitCar(); myCar:Destroy(); myCar = nil end
    env.BF_CARTRANSFORM_CONFIG = nil
    env.__BF_CARTRANSFORM_CLEANUP = nil
end
