--// Froggy Hub - Movimiento (Speed, Super Jump, Dash)
--// Con detección de "rubberband": si el servidor te regresa, baja la velocidad un rato.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_MOVE_CLEANUP then
    pcall(env.__BF_MOVE_CLEANUP)
end

local Config = {
    -- Speed
    SpeedEnabled = false,
    Speed = 30,            -- studs/s EXTRA sobre el WalkSpeed normal
    MaxSpeed = 120,        -- tope absoluto de velocidad horizontal

    -- Super jump
    JumpEnabled = false,
    JumpPower = 100,       -- el normal suele ser 50

    -- Dash
    DashEnabled = false,
    DashMultiplier = 2,    -- multiplica la fuerza del dash (máx. 4)
    DashKey = Enum.KeyCode.V,
    DashBaseSpeed = 60,    -- velocidad base del impulso
    DashTime = 0.18,       -- duración del impulso (seg)
    DashCooldown = 0.6,
}
env.BF_MOVE_CONFIG = Config

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--==================== Estado ====================
local connections = {}
local currentExtra = 0          -- velocidad extra actual (se suaviza)
local penaltyUntil = 0          -- mientras dure, se reduce la velocidad
local lastPos = nil
local lastDir = Vector3.zero
local lastStepDist = 0
local originalJump = nil
local jumpApplied = false
local dashUntil = 0
local dashReadyAt = 0
local dashDir = Vector3.zero

local function getParts()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return hum, root
    end
end

--==================== Botón de dash (útil en móvil) ====================
local dashGui = Instance.new("ScreenGui")
dashGui.Name = "FroggyDash"
dashGui.ResetOnSpawn = false
dashGui.DisplayOrder = 60
dashGui.Parent = getParent()

local dashBtn = Instance.new("TextButton")
dashBtn.Size = UDim2.fromOffset(64, 64)
dashBtn.AnchorPoint = Vector2.new(1, 1)
dashBtn.Position = UDim2.new(1, -150, 1, -110)
dashBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
dashBtn.BackgroundTransparency = 0.15
dashBtn.BorderSizePixel = 0
dashBtn.Font = Enum.Font.GothamBold
dashBtn.TextSize = 14
dashBtn.TextColor3 = Color3.fromRGB(110, 220, 90)
dashBtn.Text = "DASH"
dashBtn.Visible = false
dashBtn.Parent = dashGui
Instance.new("UICorner", dashBtn).CornerRadius = UDim.new(1, 0)
local dashStroke = Instance.new("UIStroke", dashBtn)
dashStroke.Color = Color3.fromRGB(110, 220, 90)
dashStroke.Thickness = 2

--==================== Dash ====================
local function doDash()
    if not Config.DashEnabled then return end
    local now = os.clock()
    if now < dashReadyAt then return end
    local hum, root = getParts()
    if not hum then return end

    local dir = hum.MoveDirection
    if dir.Magnitude < 0.1 then
        local look = root.CFrame.LookVector
        dir = Vector3.new(look.X, 0, look.Z)
    end
    if dir.Magnitude < 0.1 then return end

    dashDir = dir.Unit
    dashUntil = now + Config.DashTime
    dashReadyAt = now + Config.DashCooldown
end

table.insert(connections, dashBtn.Activated:Connect(doDash))
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.DashKey then
        doDash()
    end
end))

--==================== Bucle principal ====================
local function step(dt)
    dashBtn.Visible = Config.DashEnabled

    local hum, root = getParts()
    if not hum then
        lastPos = nil
        currentExtra = 0
        return
    end

    local now = os.clock()

    --// Super jump
    if Config.JumpEnabled then
        if not originalJump then originalJump = hum.JumpPower end
        hum.UseJumpPower = true
        hum.JumpPower = Config.JumpPower
        jumpApplied = true
    elseif jumpApplied then
        if originalJump then hum.JumpPower = originalJump end
        jumpApplied = false
    end

    --// Detector de rubberband:
    --// si en un solo frame te moviste MUCHO más de lo esperado y en contra de tu
    --// dirección, el servidor te regresó -> penalizar la velocidad un rato.
    local pos = root.Position
    if lastPos then
        local delta = pos - lastPos
        local horizontal = Vector3.new(delta.X, 0, delta.Z)
        local expected = math.max(lastStepDist, 1) * 3 + 4
        if horizontal.Magnitude > expected
            and lastDir.Magnitude > 0.1
            and horizontal.Unit:Dot(lastDir) < -0.2 then
            penaltyUntil = now + 2
            currentExtra = 0
            dashUntil = 0
        end
    end
    lastPos = pos

    --// Velocidad
    local dir = hum.MoveDirection
    local penalized = now < penaltyUntil
    local target = 0
    if Config.SpeedEnabled and dir.Magnitude > 0.1 then
        target = Config.Speed
        if penalized then target = target * 0.35 end
    end

    -- suavizado: acelera y frena de forma gradual (menos "saltos" para el servidor)
    currentExtra = currentExtra + (target - currentExtra) * math.min(1, dt * 6)

    local vel = root.AssemblyLinearVelocity
    local newHorizontal = nil

    if now < dashUntil then
        local mult = math.clamp(Config.DashMultiplier, 1, 4)
        if penalized then mult = math.min(mult, 1.5) end
        newHorizontal = dashDir * (Config.DashBaseSpeed * mult)
    elseif currentExtra > 0.5 and dir.Magnitude > 0.1 then
        local total = math.min(hum.WalkSpeed + currentExtra, Config.MaxSpeed)
        newHorizontal = dir.Unit * total
    end

    if newHorizontal then
        root.AssemblyLinearVelocity = Vector3.new(newHorizontal.X, vel.Y, newHorizontal.Z)
        lastDir = newHorizontal.Unit
        lastStepDist = newHorizontal.Magnitude * dt
    else
        lastDir = dir
        lastStepDist = hum.WalkSpeed * dt
    end
end

table.insert(connections, RunService.Heartbeat:Connect(step))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    originalJump = nil
    jumpApplied = false
    lastPos = nil
    currentExtra = 0
end))

env.__BF_MOVE_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    local hum = getParts()
    if hum and jumpApplied and originalJump then
        pcall(function() hum.JumpPower = originalJump end)
    end
    dashGui:Destroy()
    env.BF_MOVE_CONFIG = nil
    env.__BF_MOVE_CLEANUP = nil
end
