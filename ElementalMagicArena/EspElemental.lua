--// Froggy Hub - ESP Elemental (Fixed & Sincronizado)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 🔥 CONFIGURACIÓN CORREGIDA (Igual al Main.lua)
local Config = {
    Enabled = true,
    Boxes = true,        -- Coincide con el Main
    HealthBar = true,    -- Coincide con el Main
    ShowName = true,
    ShowElement = true,
    ShowTracers = true,
    MaxDistance = 2000,
}

local Objects = {}
local Connections = {}

local function getParent()
    if gethui then local ok, ui = pcall(gethui); if ok and typeof(ui) == "Instance" then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local drawGui = getParent()

local function getElement(player)
    local ok, elem = pcall(function() return player:GetAttribute("Element") end)
    if ok and elem then return elem end
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
    billboard.Parent = drawGui

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

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = drawGui

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 2
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Parent = box

    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.2
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = drawGui
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.fromScale(0, 1)
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false
    tracer.Parent = drawGui

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

    local hitboxConfig = env.BF_HITBOX_CONFIG
    local isHitboxActive = hitboxConfig and hitboxConfig.Enabled
    local hitboxSize = isHitboxActive and hitboxConfig.Size or 0
    local hitboxPart = isHitboxActive and hitboxConfig.TargetPart or "HumanoidRootPart"

    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local visible = root and hum and hum.Health > 0
        if visible and (root.Position - myRoot.Position).Magnitude > Config.MaxDistance then visible = false end

        data.Billboard.Enabled = visible
        if visible then
            local elemName = getElement(player)
            data.NameLabel.Text = player.Name
            data.InfoLabel.Text = "[" .. elemName .. "]"

            local topPos, bottomPos
            if isHitboxActive then
                if hitboxPart == "Torso" then
                    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                    if torso then
                        topPos = torso.Position + Vector3.new(0, hitboxSize/2, 0)
                        bottomPos = torso.Position - Vector3.new(0, hitboxSize/2, 0)
                    end
                elseif hitboxPart == "Head" then
                    local head = char:FindFirstChild("Head")
                    if head then
                        topPos = head.Position + Vector3.new(0, hitboxSize/2, 0)
                        bottomPos = head.Position - Vector3.new(0, hitboxSize/2, 0)
                    end
                elseif hitboxPart == "All" then
                    topPos = root.Position + Vector3.new(0, hitboxSize, 0)
                    bottomPos = root.Position - Vector3.new(0, hitboxSize, 0)
                else
                    topPos = root.Position + Vector3.new(0, hitboxSize/2, 0)
                    bottomPos = root.Position - Vector3.new(0, hitboxSize/2, 0)
                end
            end

            if not topPos then
                topPos = root.Position + Vector3.new(0, 3, 0)
                bottomPos = root.Position - Vector3.new(0, 3.2, 0)
            end

            local top = Camera:WorldToViewportPoint(topPos)
            local bottom = Camera:WorldToViewportPoint(bottomPos)

            if top.Z > 0 and bottom.Z > 0 then
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.6
                local cx, cy = (top.X + bottom.X) / 2, (top.Y + bottom.Y) / 2

                data.Box.Size = UDim2.fromOffset(width, height)
                data.Box.Position = UDim2.fromOffset(cx, cy)
                data.Box.Visible = Config.Boxes -- Corregido

                local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.BarBg.Size = UDim2.fromOffset(5, height)
                data.BarBg.Position = UDim2.fromOffset(cx - width / 2 - 8, cy)
                data.BarFill.Size = UDim2.fromScale(1, ratio)
                data.BarFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                data.BarBg.Visible = Config.HealthBar -- Corregido

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
