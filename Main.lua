--// main.lua: carga esp.lua desde GitHub y muestra un panel para activarlo/desactivarlo
--// CAMBIA estos dos valores por los de tu repositorio:
local GITHUB_USER = "cristhiandalmauquintana"
local GITHUB_REPO = "Whitefantasy"
local ESP_URL = ("https://raw.githubusercontent.com/%s/%s/main/esp.lua"):format(GITHUB_USER, GITHUB_REPO)

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Evitar paneles duplicados
if env.__BF_PANEL_CLEANUP then
    pcall(env.__BF_PANEL_CLEANUP)
end

--// Cargar el ESP
local okGet, source = pcall(function() return game:HttpGet(ESP_URL, true) end)
if not okGet or type(source) ~= "string" or #source == 0 then
    warn("ESP: no se pudo descargar esp.lua. Revisa usuario/repositorio en main.lua.")
    return
end
local okCompile, chunk = pcall(loadstring, source)
if not okCompile or type(chunk) ~= "function" then
    warn("ESP: esp.lua tiene un error de sintaxis.")
    return
end
local okRun, runErr = pcall(chunk)
if not okRun then
    warn("ESP: error al iniciar esp.lua: " .. tostring(runErr))
    return
end

local Config = env.BF_ESP_CONFIG
if type(Config) ~= "table" then
    warn("ESP: no se encontró la configuración del ESP.")
    return
end

--// Contenedor de la UI
local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ON_COLOR = Color3.fromRGB(60, 200, 110)
local OFF_COLOR = Color3.fromRGB(210, 70, 70)

local gui = Instance.new("ScreenGui")
gui.Name = "BFESPPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = getParent()

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(200, 150)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(70, 70, 80)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -50, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "ESP - Blox Fruits"
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local function makeToggle(text, yPos, getValue, setValue)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 34)
    btn.Position = UDim2.fromOffset(12, yPos)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function refresh()
        local on = getValue()
        btn.Text = text .. ": " .. (on and "ON" or "OFF")
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and ON_COLOR or OFF_COLOR
        }):Play()
    end

    btn.Activated:Connect(function()
        setValue(not getValue())
        refresh()
    end)
    refresh()
    return refresh
end

local refreshEsp = makeToggle("ESP", 40,
    function() return Config.Enabled end,
    function(v) Config.Enabled = v end)

makeToggle("Compañeros", 84,
    function() return Config.ShowTeammates end,
    function(v) Config.ShowTeammates = v end)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Position = UDim2.new(0, 12, 1, -22)
hint.Size = UDim2.new(1, -24, 0, 16)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(150, 150, 160)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "RightShift = ESP | Arrastra el título"
hint.Parent = frame

--// Arrastrar el panel (ratón y táctil)
local dragging, dragStart, startPos
local connections = {}

table.insert(connections, title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--// Mantener el botón sincronizado si se activa con la tecla
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Config.ToggleKey then
        task.defer(refreshEsp)
    end
end))

--// Cerrar: apaga el ESP y elimina el panel
local function cleanup()
    for _, c in ipairs(connections) do c:Disconnect() end
    if env.__BF_ESP_CLEANUP then pcall(env.__BF_ESP_CLEANUP) end
    gui:Destroy()
    env.__BF_PANEL_CLEANUP = nil
end

closeBtn.Activated:Connect(cleanup)
env.__BF_PANEL_CLEANUP = cleanup
