--// Froggy Hub - Camlock / Aim assist

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_CAM_CLEANUP then
    pcall(env.__BF_CAM_CLEANUP)
end

local Config = {
    Enabled = false,              -- muestra el botón LOCK y activa el sistema
    FOV = 250,                    -- radio (px) alrededor del centro de la pantalla
    Smoothness = 0.25,            -- 0.05 = muy suave, 1 = instantáneo
    AimPart = "HumanoidRootPart", -- "HumanoidRootPart" o "Head"
    MaxDistance = 400,            -- studs
    IgnoreTeammates = true,
    WallCheck = false,            -- no fijar a quien esté tras una pared
    ShowFOV = true,
    LockKey = Enum.KeyCode.C,
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

--==================== UI: círculo FOV y botón LOCK ====================
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyCamlock"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 55
gui.Parent = getParent()

local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.Visible = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
local circleStroke = Instance.new("UIStroke", circle)
circleStroke.Color = Color3.fromRGB(110, 220, 90)
circleStroke.Thickness = 1.5
circleStroke.Transparency = 0.4

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

--==================== Lógica ====================
local connections = {}
local target = nil -- Player fijado

local function getAimPart(player)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart")
    if not hum or not part or hum.Health <= 0 then return nil end
    return part
end

local function isAllowed(player)
    if player == LocalPlayer then return false end
    if Config.IgnoreTeammates and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function isVisible(part)
    local camera = workspace.CurrentCamera
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local origin = camera.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosest()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local center = camera.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best, bestDist = nil, Config.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local part = getAimPart(player)
            if part then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    local inRange = true
                    if myRoot then
                        inRange = (part.Position - myRoot.Position).Magnitude <= Config.MaxDistance
                    end
                    if d < bestDist and inRange and (not Config.WallCheck or isVisible(part)) then
                        best, bestDist = player, d
                    end
                end
            end
        end
    end
    return best
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
    if not Config.Enabled then return end
    if target then
        target = nil
    else
        target = getClosest()
    end
    refreshButton()
end

table.insert(connections, lockBtn.Activated:Connect(toggleLock))
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.LockKey then
        toggleLock()
    end
end))

-- Se ejecuta DESPUÉS del script de cámara de Roblox para que no la pise
RunService:BindToRenderStep("FroggyCamlock", Enum.RenderPriority.Camera.Value + 1, function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    -- UI
    lockBtn.Visible = Config.Enabled
    circle.Visible = Config.Enabled and Config.ShowFOV
    circle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)

    if not Config.Enabled then
        if target then
            target = nil
            refreshButton()
        end
        return
    end

    if not target then return end

    -- soltar si el objetivo ya no es válido
    local part = isAllowed(target) and getAimPart(target) or nil
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not part
        or (myRoot and (part.Position - myRoot.Position).Magnitude > Config.MaxDistance * 1.5) then
        target = nil
        refreshButton()
        return
    end

    local camCF = camera.CFrame
    local goal = CFrame.lookAt(camCF.Position, part.Position)
    camera.CFrame = camCF:Lerp(goal, math.clamp(Config.Smoothness, 0.05, 1))
end)

env.__BF_CAM_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("FroggyCamlock") end)
    gui:Destroy()
    env.BF_CAM_CONFIG = nil
    env.__BF_CAM_CLEANUP = nil
end
