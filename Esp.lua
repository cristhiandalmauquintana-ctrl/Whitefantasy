--// Froggy Hub - ESP para Blox Fruits
--// Texto (usuario, nivel, vida) + cajas 2D, barra de vida y tracers

local Config = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.RightShift, -- activar/desactivar
    ShowTeammates = true,
    MaxDistance = 0,                     -- studs (0 = sin límite)
    TextSize = 13,
    ColorByHealth = true,                -- texto verde -> rojo según la vida
    TextColor = Color3.fromRGB(255, 255, 255),

    -- Visual (se controlan desde el panel)
    Boxes = false,
    Tracers = false,
    HealthBar = false,
    BoxColor = Color3.fromRGB(255, 60, 60),
    TracerColor = Color3.fromRGB(255, 255, 255),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Evitar duplicados al re-ejecutar
local env = (getgenv and getgenv()) or _G
if env.__BF_ESP_CLEANUP then
    pcall(env.__BF_ESP_CLEANUP)
end

--// Exponer la config para que el panel (Main.lua) pueda controlarla
env.BF_ESP_CONFIG = Config

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--// Textos sobre la cabeza (BillboardGui)
local Container = Instance.new("Folder")
Container.Name = "BFESPContainer"
Container.Parent = getParent()

--// Cajas, barras y tracers (Frames 2D en pantalla)
local DrawGui = Instance.new("ScreenGui")
DrawGui.Name = "BFESPDraw"
DrawGui.ResetOnSpawn = false
DrawGui.IgnoreGuiInset = true
DrawGui.DisplayOrder = 50
DrawGui.Parent = getParent()

local Objects = {}      -- [Player] = { Billboard, Label, Box, BoxStroke, BarBg, BarFill, Tracer }
local Connections = {}

--// Nivel del jugador (Blox Fruits: Player.Data.Level)
local function getLevel(player)
    local data = player:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    if level and level.Value ~= nil then
        return level.Value
    end
    return "?"
end

local function isTeammate(player)
    return LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

local function healthColor(ratio)
    return Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 60)
end

local function removeESP(player)
    local data = Objects[player]
    if not data then return end
    data.Billboard:Destroy()
    data.Box:Destroy()
    data.BarBg:Destroy()
    data.Tracer:Destroy()
    Objects[player] = nil
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end

    -- Texto
    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Size = UDim2.fromOffset(220, 48)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Enabled = false
    billboard.Parent = Container

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = Config.TextSize
    label.TextColor3 = Config.TextColor
    label.TextStrokeTransparency = 0.3
    label.Parent = billboard

    -- Caja 2D
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = DrawGui

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Color = Config.BoxColor
    boxStroke.Parent = box

    -- Barra de vida
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.35
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = DrawGui

    local barFill = Instance.new("Frame")
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.fromScale(0, 1)
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
    barFill.Parent = barBg

    -- Tracer (línea)
    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Config.TracerColor
    tracer.Visible = false
    tracer.Parent = DrawGui

    Objects[player] = {
        Billboard = billboard,
        Label = label,
        Box = box,
        BoxStroke = boxStroke,
        BarBg = barBg,
        BarFill = barFill,
        Tracer = tracer,
    }
end

local function hide2D(data)
    data.Box.Visible = false
    data.BarBg.Visible = false
    data.Tracer.Visible = false
end

local function update()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        local visible = Config.Enabled
            and root ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0
            and (Config.ShowTeammates or not isTeammate(player))

        if visible and Config.MaxDistance > 0 and myRoot then
            if (root.Position - myRoot.Position).Magnitude > Config.MaxDistance then
                visible = false
            end
        end

        data.Billboard.Enabled = visible

        if not visible then
            hide2D(data)
        else
            data.Billboard.Adornee = root

            local hp = math.floor(humanoid.Health)
            local maxHp = math.floor(humanoid.MaxHealth)
            local ratio = 1
            if humanoid.MaxHealth > 0 then
                ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            end

            -- Texto
            data.Label.Text = string.format(
                "%s\nLv. %s | HP %d/%d",
                player.Name, tostring(getLevel(player)), hp, maxHp
            )
            data.Label.TextSize = Config.TextSize
            if Config.ColorByHealth and maxHp > 0 then
                data.Label.TextColor3 = healthColor(ratio)
            else
                data.Label.TextColor3 = Config.TextColor
            end

            -- Posición en pantalla (arriba y abajo del personaje)
            local rootPos = root.Position
            local top = camera:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
            local bottom = camera:WorldToViewportPoint(rootPos - Vector3.new(0, 3.2, 0))
            local inFront = top.Z > 0 and bottom.Z > 0

            if not inFront then
                hide2D(data)
            else
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.55
                local cx = (top.X + bottom.X) / 2
                local cy = (top.Y + bottom.Y) / 2

                -- Caja 2D
                if Config.Boxes then
                    data.Box.Size = UDim2.fromOffset(width, height)
                    data.Box.Position = UDim2.fromOffset(cx, cy)
                    data.BoxStroke.Color = Config.BoxColor
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

                -- Barra de vida (a la izquierda de la caja)
                if Config.HealthBar then
                    data.BarBg.Size = UDim2.fromOffset(4, height)
                    data.BarBg.Position = UDim2.fromOffset(cx - width / 2 - 6, cy)
                    data.BarFill.Size = UDim2.fromScale(1, ratio)
                    data.BarFill.BackgroundColor3 = healthColor(ratio)
                    data.BarBg.Visible = true
                else
                    data.BarBg.Visible = false
                end

                -- Tracer (desde abajo al centro hasta los pies del jugador)
                if Config.Tracers then
                    local fromX, fromY = viewport.X / 2, viewport.Y
                    local dx = cx - fromX
                    local dy = bottom.Y - fromY
                    local length = math.sqrt(dx * dx + dy * dy)
                    data.Tracer.Size = UDim2.fromOffset(length, 1.5)
                    data.Tracer.Position = UDim2.fromOffset(fromX + dx / 2, fromY + dy / 2)
                    data.Tracer.Rotation = math.deg(math.atan2(dy, dx))
                    data.Tracer.BackgroundColor3 = Config.TracerColor
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

table.insert(Connections, Players.PlayerAdded:Connect(createESP))
table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))
table.insert(Connections, RunService.RenderStepped:Connect(update))
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        Config.Enabled = not Config.Enabled
    end
end))

env.__BF_ESP_CLEANUP = function()
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    for player in pairs(Objects) do
        removeESP(player)
    end
    Container:Destroy()
    DrawGui:Destroy()
    env.BF_ESP_CONFIG = nil
    env.__BF_ESP_CLEANUP = nil
end
