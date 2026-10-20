--// ESP para Blox Fruits: muestra usuario, nivel y vida sobre cada jugador

local Config = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.RightShift, -- activar/desactivar
    ShowTeammates = true,
    MaxDistance = 0,                     -- studs (0 = sin límite)
    TextSize = 13,
    ColorByHealth = true,                -- verde -> rojo según la vida
    DefaultColor = Color3.fromRGB(255, 255, 255),
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

--// Exponer la config para que el panel (main.lua) pueda controlarla
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

local Container = Instance.new("Folder")
Container.Name = "BFESPContainer"
Container.Parent = getParent()

local Objects = {}      -- [Player] = { Billboard, Label }
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

local function removeESP(player)
    local data = Objects[player]
    if not data then return end
    data.Billboard:Destroy()
    Objects[player] = nil
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end

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
    label.TextColor3 = Config.DefaultColor
    label.TextStrokeTransparency = 0.3
    label.Parent = billboard

    Objects[player] = { Billboard = billboard, Label = label }
end

local function update()
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

        if visible then
            data.Billboard.Adornee = root

            local hp = math.floor(humanoid.Health)
            local maxHp = math.floor(humanoid.MaxHealth)
            data.Label.Text = string.format(
                "%s\nLv. %s | HP %d/%d",
                player.Name, tostring(getLevel(player)), hp, maxHp
            )

            if Config.ColorByHealth and maxHp > 0 then
                local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                data.Label.TextColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 60)
            else
                data.Label.TextColor3 = Config.DefaultColor
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
    env.BF_ESP_CONFIG = nil
    env.__BF_ESP_CLEANUP = nil
end
