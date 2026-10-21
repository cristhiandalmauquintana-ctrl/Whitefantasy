--// Froggy Hub - Teleport al enemigo más cercano (botón flotante con cooldown)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_TP_CLEANUP then
    pcall(env.__BF_TP_CLEANUP)
end

local Config = {
    Enabled = false,        -- muestra el botón flotante
    Cooldown = 3,          -- segundos entre teleports
    Offset = 4,             -- studs por detrás del enemigo al aparecer
    MaxDistance = 0,        -- 0 = sin límite (solo jugadores con personaje cargado)
    TeamCheck = true,       -- ignorar a tu mismo equipo
    IgnoreFriends = false,  -- ignorar a tus amigos de Roblox
    Key = Enum.KeyCode.T,   -- tecla opcional (PC)
}
env.BF_TP_CONFIG = Config

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--==================== Botón flotante ====================
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyTeleport"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 56
gui.Parent = getParent()

local function screenSize()
    local s = gui.AbsoluteSize
    if s.X < 50 or s.Y < 50 then
        local cam = workspace.CurrentCamera
        s = cam and cam.ViewportSize or Vector2.new(800, 600)
    end
    return s
end

local BTN = 64
local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(BTN, BTN)
btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
btn.BackgroundTransparency = 0.15
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.TextColor3 = Color3.fromRGB(240, 240, 245)
btn.Text = "TP"
btn.Visible = false
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", btn)
stroke.Color = Color3.fromRGB(110, 220, 90)
stroke.Thickness = 2

do
    local s = screenSize()
    btn.Position = UDim2.fromOffset(s.X - BTN - 310, s.Y - BTN - 110)
end

local function setBtnPos(x, y)
    local s = screenSize()
    btn.Position = UDim2.fromOffset(
        math.clamp(x, 0, math.max(0, s.X - BTN)),
        math.clamp(y, 0, math.max(0, s.Y - BTN))
    )
end

--==================== Lógica ====================
local connections = {}
local readyAt = 0
local flashUntil = 0
local flashText = ""

local friendCache = {}
local function isFriend(player)
    local cached = friendCache[player.UserId]
    if cached ~= nil then return cached end
    local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    friendCache[player.UserId] = ok and result or false
    return friendCache[player.UserId]
end

local function sameTeam(player)
    if LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return true end
    return false
end

local function isAllowed(player)
    if player == LocalPlayer then return false end
    if Config.TeamCheck and sameTeam(player) then return false end
    if Config.IgnoreFriends and isFriend(player) then return false end
    return true
end

local function nearestEnemy(myRoot)
    local best, bestDist = nil, math.huge
    if Config.MaxDistance > 0 then bestDist = Config.MaxDistance end

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    best, bestDist = root, d
                end
            end
        end
    end
    return best
end

local function flash(text)
    flashText = text
    flashUntil = os.clock() + 1.2
end

local function teleport()
    if not Config.Enabled then return end
    if os.clock() < readyAt then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    local targetRoot = nearestEnemy(myRoot)
    if not targetRoot then
        flash("NADIE")
        return
    end

    -- aparecer por detrás del enemigo, mirando hacia él
    local pos = targetRoot.Position - targetRoot.CFrame.LookVector * Config.Offset
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.CFrame = CFrame.lookAt(pos, Vector3.new(targetRoot.Position.X, pos.Y, targetRoot.Position.Z))

    readyAt = os.clock() + math.max(0, Config.Cooldown)
end

-- arrastrar el botón; un toque (sin mover) hace el teleport
local active, startMouse, startPos, moved
table.insert(connections, btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        active = input
        startMouse = input.Position
        startPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
        moved = false

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if active == input then
                    active = nil
                    if not moved then teleport() end
                end
                conn:Disconnect()
            end
        end)
    end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if not active then return end
    if active.UserInputType == Enum.UserInputType.Touch then
        if input ~= active then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    local d = input.Position - startMouse
    if d.Magnitude > 10 then moved = true end
    if moved then setBtnPos(startPos.X + d.X, startPos.Y + d.Y) end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.Key then
        teleport()
    end
end))

-- texto del botón: TP / cuenta atrás / aviso
table.insert(connections, RunService.Heartbeat:Connect(function()
    btn.Visible = Config.Enabled
    if not Config.Enabled then return end

    local now = os.clock()
    if now < flashUntil then
        btn.Text = flashText
        btn.TextSize = 12
        stroke.Color = Color3.fromRGB(210, 70, 70)
    elseif now < readyAt then
        btn.Text = tostring(math.ceil(readyAt - now))
        btn.TextSize = 20
        stroke.Color = Color3.fromRGB(210, 70, 70)
        btn.BackgroundTransparency = 0.45
    else
        btn.Text = "TP"
        btn.TextSize = 16
        stroke.Color = Color3.fromRGB(110, 220, 90)
        btn.BackgroundTransparency = 0.15
    end
end))

-- si cambia el tamaño de pantalla, mantener el botón visible
table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    setBtnPos(btn.Position.X.Offset, btn.Position.Y.Offset)
end))

env.__BF_TP_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    env.BF_TP_CONFIG = nil
    env.__BF_TP_CLEANUP = nil
end
