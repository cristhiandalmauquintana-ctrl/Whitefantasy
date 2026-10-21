--// Froggy Hub - Camlock + Aim Assist (separados)
--// Lock   = fija la cámara en un objetivo con un botón / tecla.
--// Assist = ayuda pasiva: atrae suavemente la cámara hacia quien esté cerca de tu mira.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_CAM_CLEANUP then
    pcall(env.__BF_CAM_CLEANUP)
end

local Config = {
    Lock = {
        Enabled = false,              -- muestra el botón LOCK
        Key = Enum.KeyCode.C,
        FOV = 250,                    -- radio (px) para elegir el objetivo
        Smoothness = 0.35,            -- 0.05 = muy suave, 1 = instantáneo
        AimPart = "HumanoidRootPart", -- "HumanoidRootPart" o "Head"
        MaxDistance = 400,            -- studs
        IgnoreTeammates = true,
        WallCheck = false,
        Prediction = 0,               -- segundos de anticipación (0 a 0.3)
        ShowFOV = true,
    },
    Assist = {
        Enabled = false,
        FOV = 140,                    -- radio (px) donde empieza a ayudar
        Strength = 0.12,              -- fuerza de atracción (0.02 a 0.5)
        AimPart = "HumanoidRootPart",
        MaxDistance = 250,
        IgnoreTeammates = true,
        WallCheck = true,
        Prediction = 0,
        ShowFOV = true,
    },
}
env.BF_CAM_CONFIG = Config

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--==================== UI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyAim"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 55
gui.Parent = getParent()

local function makeCircle(color)
    local c = Instance.new("Frame")
    c.AnchorPoint = Vector2.new(0.5, 0.5)
    c.Position = UDim2.fromScale(0.5, 0.5)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.Visible = false
    c.Parent = gui
    Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", c)
    s.Color = color
    s.Thickness = 1.5
    s.Transparency = 0.45
    return c
end

local lockCircle = makeCircle(Color3.fromRGB(110, 220, 90))
local assistCircle = makeCircle(Color3.fromRGB(70, 200, 255))

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.fromOffset(64, 64)
lockBtn.AnchorPoint = Vector2.new(1, 1)
lockBtn.Position = UDim2.new(1, -230, 1, -110)
lockBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
lockBtn.BackgroundTransparency = 0.15
lockBtn.BorderSizePixel = 0
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 14
lockBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
lockBtn.Text = "LOCK"
lockBtn.Visible = false
lockBtn.Parent = gui
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(1, 0)
local lockStroke = Instance.new("UIStroke", lockBtn)
lockStroke.Color = Color3.fromRGB(210, 70, 70)
lockStroke.Thickness = 2

--==================== Utilidades ====================
local connections = {}
local target = nil -- Player fijado por el Lock

local function getPart(player, partName)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
    if not hum or not part or hum.Health <= 0 then return nil end
    return part
end

local function allowed(player, cfg)
    if player == LocalPlayer then return false end
    if cfg.IgnoreTeammates and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function visible(part)
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer.Character
    params.FilterDescendantsInstances = char and {char} or {}
    params.RespectCanCollide = true -- ignora partes invisibles sin colisión
    local origin = camera.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function aimPosition(part, cfg)
    local pos = part.Position
    if cfg.Prediction and cfg.Prediction > 0 then
        pos = pos + part.AssemblyLinearVelocity * cfg.Prediction
    end
    return pos
end

-- Devuelve el jugador más cercano al centro de la pantalla dentro del FOV de cfg
local function getClosest(cfg)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local center = camera.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestPlayer, bestPart, bestDist = nil, nil, cfg.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if allowed(player, cfg) then
            local part = getPart(player, cfg.AimPart)
            if part then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    local inRange = true
                    if myRoot then
                        inRange = (part.Position - myRoot.Position).Magnitude <= cfg.MaxDistance
                    end
                    if d < bestDist and inRange and (not cfg.WallCheck or visible(part)) then
                        bestPlayer, bestPart, bestDist = player, part, d
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart, bestDist
end

-- Suavizado independiente de los FPS
local function smoothAlpha(s, dt)
    s = math.clamp(s, 0.01, 1)
    if s >= 1 then return 1 end
    return 1 - (1 - s) ^ (math.clamp(dt, 0, 0.1) * 60)
end

local function refreshButton()
    if target then
        lockBtn.Text = "LOCKED"
        lockBtn.TextSize = 11
        lockStroke.Color = Color3.fromRGB(110, 220, 90)
    else
        lockBtn.Text = "LOCK"
        lockBtn.TextSize = 14
        lockStroke.Color = Color3.fromRGB(210, 70, 70)
    end
end

local function toggleLock()
    if not Config.Lock.Enabled then return end
    if target then
        target = nil
    else
        target = getClosest(Config.Lock)
    end
    refreshButton()
end

table.insert(connections, lockBtn.Activated:Connect(toggleLock))
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.Lock.Key then
        toggleLock()
    end
end))

--==================== Bucle (después del script de cámara de Roblox) ====================
RunService:BindToRenderStep("FroggyAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local L, A = Config.Lock, Config.Assist

    -- círculos
    lockCircle.Visible = L.Enabled and L.ShowFOV and target == nil
    lockCircle.Size = UDim2.fromOffset(L.FOV * 2, L.FOV * 2)
    assistCircle.Visible = A.Enabled and A.ShowFOV and target == nil
    assistCircle.Size = UDim2.fromOffset(A.FOV * 2, A.FOV * 2)
    lockBtn.Visible = L.Enabled

    if not L.Enabled and target then
        target = nil
        refreshButton()
    end

    local goalPos, alpha = nil, nil

    if L.Enabled and target then
        --// LOCK: seguir al objetivo fijado
        local part = allowed(target, L) and getPart(target, L.AimPart) or nil
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not part
            or (myRoot and (part.Position - myRoot.Position).Magnitude > L.MaxDistance * 1.5) then
            target = nil
            refreshButton()
        else
            goalPos = aimPosition(part, L)
            alpha = smoothAlpha(L.Smoothness, dt)
        end
    elseif A.Enabled then
        --// ASSIST: atracción suave, más fuerte entre más cerca del centro
        local _, part, dist = getClosest(A)
        if part then
            local closeness = 1 - (dist / A.FOV) -- 0 en el borde, 1 en el centro
            goalPos = aimPosition(part, A)
            alpha = smoothAlpha(A.Strength * (0.35 + 0.65 * closeness), dt)
        end
    end

    if goalPos then
        local camCF = camera.CFrame
        local goal = CFrame.lookAt(camCF.Position, goalPos)
        camera.CFrame = camCF:Lerp(goal, alpha)
    end
end)

env.__BF_CAM_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("FroggyAim") end)
    gui:Destroy()
    env.BF_CAM_CONFIG = nil
    env.__BF_CAM_CLEANUP = nil
end[span_2](start_span)[span_2](end_span)
