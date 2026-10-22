--// Froggy Hub - ESP Elemental (Fix UI + Adornee)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.__BF_ESP_CLEANUP then pcall(env.__BF_ESP_CLEANUP) end

-- Configuración (Ahora coincide con los botones del Main)
local Config = {
    Enabled = true,
    Boxes = true,
    HealthBar = true,
    Tracers = true,
    MaxDistance = 2000,
}
env.BF_ESP_CONFIG = Config

local function getParent()
    if gethui then local ok, ui = pcall(gethui); if ok and typeof(ui) == "Instance" then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local drawGui = Instance.new("ScreenGui")
drawGui.Name = "FroggyESP_Draw"
drawGui.ResetOnSpawn = false
drawGui.IgnoreGuiInset = true
drawGui.DisplayOrder = 50
drawGui.Parent = getParent()

local Container = Instance.new("Folder")
Container.Name = "FroggyESP_Container"
Container.Parent = getParent()

local Objects = {}
local Connections = {}

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end

    -- Texto
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(200, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Enabled = false
    billboard.Parent = Container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.fromScale(1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard

    -- Caja
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = drawGui

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Parent = box

    -- Barra de vida
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.3
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = drawGui

    local barFill = Instance.new("Frame")
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.fromScale(0, 1)
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
    barFill.Parent = barBg

    -- Tracer
    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false
    tracer.Parent = drawGui

    Objects[player] = { Billboard = billboard, NameLabel = nameLabel, Box = box, BoxStroke = boxStroke, BarBg = barBg, BarFill = barFill, Tracer = tracer }
end

local function removeESP(player)
    if Objects[player] then
        Objects[player].Billboard:Destroy()
        Objects[player].Box:Destroy()
        Objects[player].BarBg:Destroy()
        Objects[player].Tracer:Destroy()
        Objects[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
table.insert(Connections, Players.PlayerAdded:Connect(createESP))
table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))

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
    local viewport = Camera.ViewportSize

    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local visible = root and hum and hum.Health > 0
        if visible and Config.MaxDistance > 0 and (root.Position - myRoot.Position).Magnitude > Config.MaxDistance then
            visible = false
        end

        data.Billboard.Enabled = visible

        if visible then
            -- 🛠️ EL ARREGLO ESTÁ ACÁ: Asignamos el Adornee
            data.Billboard.Adornee = root
            
            data.NameLabel.Text = player.Name .. "\n" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)

            local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
            local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

            if top.Z > 0 and bottom.Z > 0 then
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.6
                local cx, cy = (top.X + bottom.X) / 2, (top.Y + bottom.Y) / 2
                local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

                if Config.Boxes then
                    data.Box.Size = UDim2.fromOffset(width, height)
                    data.Box.Position = UDim2.fromOffset(cx, cy)
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

                if Config.HealthBar then
                    data.BarBg.Size = UDim2.fromOffset(4, height)
                    data.BarBg.Position = UDim2.fromOffset(cx - width / 2 - 6, cy)
                    data.BarFill.Size = UDim2.fromScale(1, ratio)
                    data.BarFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                    data.BarBg.Visible = true
                else
                    data.BarBg.Visible = false
                end

                if Config.Tracers then
                    local fromX, fromY = viewport.X / 2, viewport.Y
                    local dx, dy = cx - fromX, bottom.Y - fromY
                    local length = math.sqrt(dx * dx + dy * dy)
                    data.Tracer.Size = UDim2.fromOffset(length, 1.5)
                    data.Tracer.Position = UDim2.fromOffset(fromX + dx / 2, fromY + dy / 2)
                    data.Tracer.Rotation = math.deg(math.atan2(dy, dx))
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
            else
                data.Box.Visible = false; data.BarBg.Visible = false; data.Tracer.Visible = false
            end
        else
            data.Box.Visible = false; data.BarBg.Visible = false; data.Tracer.Visible = false
        end
    end
end))

env.__BF_ESP_CLEANUP = function()
    for _, c in ipairs(Connections) do c:Disconnect() end
    for p, _ in pairs(Objects) do removeESP(p) end
    drawGui:Destroy()
    Container:Destroy()
    env.BF_ESP_CONFIG = nil
    env.__BF_ESP_CLEANUP = nil
end
