--// Froggy Hub - ESP Premium para Elemental Magic Arena
--// Cajas grandes, Tracers y elementos.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Enabled = true,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowElement = true,
    ShowTracers = true,
    MaxDistance = 2000,
}

local Objects = {}
local Connections = {}

-- Función para obtener el elemento
local function getElement(player)
    local ok, elem = pcall(function() return player:GetAttribute("Element") end)
    if ok and elem then return elem end
    local char = player.Character
    if char then
        local eObj = char:FindFirstChild("Element")
        if eObj and eObj:IsA("StringValue") then return eObj.Value end
    end
    return "Default"
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ElemESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(250, 60)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Enabled = false
    billboard.Parent = game:GetService("CoreGui")

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.Parent = billboard

    local infoLabel = Instance.new("TextLabel")
    infoLabel.BackgroundTransparency = 1
    infoLabel.Position = UDim2.new(0, 0, 0.4, 0)
    infoLabel.Size = UDim2.new(1, 0, 0.4, 0)
    infoLabel.Font = Enum.Font.GothamBold
    infoLabel.TextSize = 13
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextStrokeTransparency = 0.2
    infoLabel.Parent = billboard

    -- Caja 2D Premium
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = game:GetService("CoreGui")

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 2
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Parent = box

    -- Barra de Vida
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.2
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = game:GetService("CoreGui")
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.fromScale(0, 1)
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    -- Tracer
    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false
    tracer.Parent = game:GetService("CoreGui")

    Objects[player] = {
        Billboard = billboard,
        NameLabel = nameLabel,
        InfoLabel = infoLabel,
        Box = box,
        BoxStroke = boxStroke,
        BarBg = barBg,
        BarFill = barFill,
        Tracer = tracer
    }
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        for _, data in pairs(Objects) do
            data.Billboard.Enabled = false
            data.Box.Visible = false
            data.BarBg.Visible = false
            data.Tracer.Visible = false
        end
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local visible = root and hum and hum.Health > 0
        if visible and (root.Position - myRoot.Position).Magnitude > Config.MaxDistance then
            visible = false
        end

        data.Billboard.Enabled = visible
        if visible then
            local elemName = getElement(player)
            local elemColor = Color3.fromRGB(255, 255, 255)
            
            -- Colores por elemento
            if elemName == "Fire" then elemColor = Color3.fromRGB(255, 100, 50) end
            if elemName == "Water" then elemColor = Color3.fromRGB(50, 150, 255) end
            if elemName == "Dragon" then elemColor = Color3.fromRGB(255, 0, 0) end
            if elemName == "Void" then elemColor = Color3.fromRGB(150, 0, 255) end

            data.NameLabel.Text = player.Name
            data.InfoLabel.Text = "[" .. elemName .. "]"
            data.NameLabel.TextColor3 = elemColor
            data.BoxStroke.Color = elemColor
            data.Tracer.BackgroundColor3 = elemColor

            local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
            local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

            if top.Z > 0 and bottom.Z > 0 then
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.6
                local cx, cy = (top.X + bottom.X) / 2, (top.Y + bottom.Y) / 2

                data.Box.Size = UDim2.fromOffset(width, height)
                data.Box.Position = UDim2.fromOffset(cx, cy)
                data.Box.Visible = true

                local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.BarBg.Size = UDim2.fromOffset(5, height)
                data.BarBg.Position = UDim2.fromOffset(cx - width / 2 - 8, cy)
                data.BarFill.Size = UDim2.fromScale(1, ratio)
                data.BarFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                data.BarBg.Visible = true

                -- Tracer desde abajo de la pantalla
                local viewport = Camera.ViewportSize
                local fromX, fromY = viewport.X / 2, viewport.Y
                local dx, dy = cx - fromX, bottom.Y - fromY
                local length = math.sqrt(dx * dx + dy * dy)
                
                data.Tracer.Size = UDim2.fromOffset(length, 1.5)
                data.Tracer.Position = UDim2.fromOffset(fromX + dx / 2, fromY + dy / 2)
                data.Tracer.Rotation = math.deg(math.atan2(dy, dx))
                data.Tracer.Visible = Config.ShowTracers
            else
                data.Box.Visible = false
                data.BarBg.Visible = false
                data.Tracer.Visible = false
            end
        end
    end
end))

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

env.__BF_ESP_CLEANUP = function()
    for _, c in ipairs(Connections) do c:Disconnect() end
    for p, data in pairs(Objects) do
        data.Billboard:Destroy()
        data.Box:Destroy()
        data.BarBg:Destroy()
        data.Tracer:Destroy()
    end
    env.BF_ESP_CONFIG = nil
    env.__BF_ESP_CLEANUP = nil
end
env.BF_ESP_CONFIG = Config
