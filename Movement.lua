--// Main.lua - Froggy Hub (loader + panel)

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ESP_FILES = { "Esp.lua", "esp.lua" }              -- prueba ambos nombres (GitHub distingue mayúsculas)
local MOVE_FILES = { "Movement.lua", "movement.lua" }   -- speed / super jump / dash
local LOGO_FILES = { "logo.png", "Logo.png" }           -- logo del repositorio
local HUB_NAME = "Froggy Hub"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Evitar paneles duplicados
if env.__BF_PANEL_CLEANUP then
    pcall(env.__BF_PANEL_CLEANUP)
end

--// Colores
local C = {
    Bg = Color3.fromRGB(20, 20, 26),
    Header = Color3.fromRGB(28, 28, 36),
    Row = Color3.fromRGB(32, 32, 40),
    Stroke = Color3.fromRGB(70, 70, 82),
    Text = Color3.fromRGB(240, 240, 245),
    Dim = Color3.fromRGB(130, 130, 145),
    Accent = Color3.fromRGB(110, 220, 90),
    On = Color3.fromRGB(60, 200, 110),
    Off = Color3.fromRGB(210, 70, 70),
}

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "FroggyHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = getParent()

local connections = {}
local tweens = {}

local function cleanup()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
    if env.__BF_ESP_CLEANUP then pcall(env.__BF_ESP_CLEANUP) end
    if env.__BF_MOVE_CLEANUP then pcall(env.__BF_MOVE_CLEANUP) end
    gui:Destroy()
    env.__BF_PANEL_CLEANUP = nil
end
env.__BF_PANEL_CLEANUP = cleanup

--==================== PANTALLA DE CARGA ====================
local loading = Instance.new("Frame")
loading.Size = UDim2.fromOffset(260, 200)
loading.AnchorPoint = Vector2.new(0.5, 0.5)
loading.Position = UDim2.fromScale(0.5, 0.5)
loading.BackgroundColor3 = C.Bg
loading.BorderSizePixel = 0
loading.Parent = gui
Instance.new("UICorner", loading).CornerRadius = UDim.new(0, 14)
local loadStroke = Instance.new("UIStroke", loading)
loadStroke.Color = C.Stroke
local loadScale = Instance.new("UIScale", loading)

local loadLogo = Instance.new("ImageLabel")
loadLogo.AnchorPoint = Vector2.new(0.5, 0.5)
loadLogo.Position = UDim2.new(0.5, 0, 0, 62)
loadLogo.Size = UDim2.fromOffset(84, 84)
loadLogo.BackgroundTransparency = 1
loadLogo.ScaleType = Enum.ScaleType.Fit
loadLogo.ImageTransparency = 1
loadLogo.Parent = loading

local loadTitle = Instance.new("TextLabel")
loadTitle.BackgroundTransparency = 1
loadTitle.Position = UDim2.fromOffset(0, 114)
loadTitle.Size = UDim2.new(1, 0, 0, 24)
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 18
loadTitle.TextColor3 = C.Accent
loadTitle.Text = string.upper(HUB_NAME)
loadTitle.Parent = loading

local loadStatus = Instance.new("TextLabel")
loadStatus.BackgroundTransparency = 1
loadStatus.Position = UDim2.fromOffset(10, 140)
loadStatus.Size = UDim2.new(1, -20, 0, 18)
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 12
loadStatus.TextColor3 = C.Dim
loadStatus.Text = "Iniciando..."
loadStatus.Parent = loading

local barTrack = Instance.new("Frame")
barTrack.Position = UDim2.new(0, 20, 1, -26)
barTrack.Size = UDim2.new(1, -40, 0, 6)
barTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
barTrack.BorderSizePixel = 0
barTrack.Parent = loading
Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = C.Accent
barFill.BorderSizePixel = 0
barFill.Parent = barTrack
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local function setProgress(fraction, text)
    TweenService:Create(barFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(fraction, 1)
    }):Play()
    if text then loadStatus.Text = text end
end

local function fail(message)
    loadStatus.Text = message
    loadStatus.TextColor3 = C.Off
    warn("Froggy Hub: " .. message)
    task.delay(5, cleanup)
end

--// Descargar el logo del repositorio y convertirlo en asset
local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then
        return nil
    end
    for _, name in ipairs(LOGO_FILES) do
        local ok, data = pcall(function()
            return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true)
        end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_logo.png"
            if pcall(writefile, path, data) then
                local okAsset, asset = pcall(getAsset, path)
                if okAsset and asset and asset ~= "" then
                    return asset
                end
            end
        end
    end
    return nil
end

--// Descargar un módulo (prueba cada nombre de la lista)
local function downloadModule(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function()
            return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true)
        end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then
            return res
        end
    end
    return nil
end

setProgress(0.1, "Cargando logo...")
local logoAsset = fetchLogo()
if logoAsset then
    loadLogo.Image = logoAsset
    TweenService:Create(loadLogo, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()

    --// Animación del logo: pulso + balanceo
    local pulse = TweenService:Create(loadLogo,
        TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Size = UDim2.fromOffset(98, 98) })
    local sway = TweenService:Create(loadLogo,
        TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Rotation = 8 })
    table.insert(tweens, pulse)
    table.insert(tweens, sway)
    pulse:Play()
    sway:Play()
end

setProgress(0.3, "Descargando ESP...")
local source = downloadModule(ESP_FILES)
if not source then
    fail("No se pudo descargar Esp.lua del repositorio.")
    return
end

setProgress(0.45, "Preparando ESP...")
local chunk, compileErr = loadstring(source)
if type(chunk) ~= "function" then
    fail("Error de sintaxis en Esp.lua: " .. tostring(compileErr))
    return
end

setProgress(0.55, "Iniciando ESP...")
local okRun, runErr = pcall(chunk)
if not okRun then
    fail("Error al iniciar el ESP: " .. tostring(runErr))
    return
end

local Config = env.BF_ESP_CONFIG
if type(Config) ~= "table" then
    fail("No se encontró la configuración del ESP.")
    return
end

--// Movimiento: si falla, el panel igual abre (solo sin esa sección)
setProgress(0.7, "Descargando movimiento...")
local MoveConfig = nil
local moveSource = downloadModule(MOVE_FILES)
if moveSource then
    local moveChunk, moveErr = loadstring(moveSource)
    if type(moveChunk) == "function" then
        local okMove, moveRunErr = pcall(moveChunk)
        if okMove then
            MoveConfig = env.BF_MOVE_CONFIG
        else
            warn("Froggy Hub: error al iniciar Movement.lua: " .. tostring(moveRunErr))
        end
    else
        warn("Froggy Hub: error de sintaxis en Movement.lua: " .. tostring(moveErr))
    end
else
    warn("Froggy Hub: no se pudo descargar Movement.lua")
end

setProgress(1, "Listo")
task.wait(0.5)

--==================== PANEL PRINCIPAL ====================
local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
local WIDTH = math.min(320, viewport.X - 24)
local HEIGHT = math.min(440, viewport.Y - 60)
local HEADER_H = 44

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.BackgroundColor3 = C.Bg
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Active = true
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = C.Stroke
local panelScale = Instance.new("UIScale", frame)
panelScale.Scale = 0.8

--// Cabecera (sirve para arrastrar)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = C.Header
header.BorderSizePixel = 0
header.Active = true
header.Parent = frame

local titleX = 14
if logoAsset then
    local logo = Instance.new("ImageLabel")
    logo.Position = UDim2.fromOffset(10, 6)
    logo.Size = UDim2.fromOffset(32, 32)
    logo.BackgroundTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Image = logoAsset
    logo.Parent = header
    titleX = 50
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(titleX, 0)
title.Size = UDim2.new(1, -(titleX + 80), 1, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.Accent
title.Text = HUB_NAME
title.Parent = header

local function headerButton(text, xOffset)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(28, 28)
    b.Position = UDim2.new(1, xOffset, 0.5, -14)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.TextColor3 = C.Text
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local closeBtn = headerButton("X", -38)
local minBtn = headerButton("-", -72)

--// Cuerpo con scroll
local body = Instance.new("ScrollingFrame")
body.Position = UDim2.fromOffset(8, HEADER_H + 8)
body.Size = UDim2.new(1, -16, 1, -(HEADER_H + 16))
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = C.Stroke
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

local order = 0
local function nextOrder()
    order = order + 1
    return order
end

local function section(text)
    local l = Instance.new("TextLabel")
    l.LayoutOrder = nextOrder()
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, 22)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Accent
    l.Text = "  " .. string.upper(text)
    l.Parent = body
end

local refreshers = {}

local function toggle(text, getValue, setValue)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = nextOrder()
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = C.Text
    btn.AutoButtonColor = true
    btn.Parent = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function refresh()
        local on = getValue()
        btn.Text = text .. ": " .. (on and "ON" or "OFF")
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.On or C.Off
        }):Play()
    end

    btn.Activated:Connect(function()
        setValue(not getValue())
        refresh()
    end)
    refresh()
    table.insert(refreshers, refresh)
end

--// Barra deslizable (arrastra con el dedo o el ratón)
local function slider(text, getValue, setValue, minV, maxV, stepV)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder()
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = C.Row
    row.BorderSizePixel = 0
    row.Parent = body
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(12, 4)
    label.Size = UDim2.new(1, -84, 0, 20)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = C.Text
    label.Text = text
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -68, 0, 4)
    valueLabel.Size = UDim2.fromOffset(56, 20)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = C.Accent
    valueLabel.Parent = row

    -- zona táctil (más alta que la barra para que sea fácil de agarrar)
    local hit = Instance.new("Frame")
    hit.BackgroundTransparency = 1
    hit.Position = UDim2.fromOffset(12, 26)
    hit.Size = UDim2.new(1, -24, 0, 24)
    hit.Active = true
    hit.Parent = row

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
    track.BorderSizePixel = 0
    track.Parent = hit
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local v = getValue()
        local rel = math.clamp((v - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLabel.Text = tostring(v)
    end

    local function setFromX(x)
        local width = math.max(1, track.AbsoluteSize.X)
        local rel = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        local v = minV + rel * (maxV - minV)
        v = math.floor(v / stepV + 0.5) * stepV
        v = math.clamp(math.floor(v * 100 + 0.5) / 100, minV, maxV)
        setValue(v)
        refresh()
    end

    local activeInput = nil

    table.insert(connections, hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
            setFromX(input.Position.X)

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if activeInput == input then activeInput = nil end
                    conn:Disconnect()
                end
            end)
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not activeInput then return end
        if activeInput.UserInputType == Enum.UserInputType.Touch then
            if input ~= activeInput then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        setFromX(input.Position.X)
    end))

    refresh()
    table.insert(refreshers, refresh)
end

local function soon(text)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder()
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = C.Row
    row.BorderSizePixel = 0
    row.Parent = body
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -112, 1, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = C.Dim
    label.Text = text
    label.Parent = row

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.fromOffset(92, 22)
    tag.Position = UDim2.new(1, -100, 0.5, -11)
    tag.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
    tag.BorderSizePixel = 0
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 11
    tag.TextColor3 = C.Dim
    tag.Text = "Coming soon"
    tag.Parent = row
    Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 6)
end

local PALETTE = {
    Color3.fromRGB(255, 60, 60),   -- rojo
    Color3.fromRGB(255, 150, 50),  -- naranja
    Color3.fromRGB(255, 225, 60),  -- amarillo
    Color3.fromRGB(80, 220, 100),  -- verde
    Color3.fromRGB(70, 200, 255),  -- cian
    Color3.fromRGB(90, 120, 255),  -- azul
    Color3.fromRGB(190, 90, 255),  -- morado
    Color3.fromRGB(255, 255, 255), -- blanco
}

local function colorRow(text, key)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder()
    row.Size = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = C.Row
    row.BorderSizePixel = 0
    row.Parent = body
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(12, 6)
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = C.Text
    label.Text = text
    label.Parent = row

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Position = UDim2.fromOffset(12, 32)
    holder.Size = UDim2.new(1, -24, 0, 26)
    holder.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = holder

    local swatches = {}
    local function refresh()
        for _, item in ipairs(swatches) do
            item.stroke.Enabled = (Config[key] == item.color)
        end
    end

    for i, color in ipairs(PALETTE) do
        local b = Instance.new("TextButton")
        b.LayoutOrder = i
        b.Size = UDim2.fromOffset(26, 26)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = true
        b.Parent = holder
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Enabled = false
        stroke.Parent = b

        table.insert(swatches, { stroke = stroke, color = color })
        b.Activated:Connect(function()
            Config[key] = color
            refresh()
        end)
    end
    refresh()
end

--// Contenido
section("ESP")
toggle("ESP",
    function() return Config.Enabled end,
    function(v) Config.Enabled = v end)
toggle("Mostrar compañeros",
    function() return Config.ShowTeammates end,
    function(v) Config.ShowTeammates = v end)

section("Visual")
toggle("Cajas 2D",
    function() return Config.Boxes end,
    function(v) Config.Boxes = v end)
toggle("Tracers",
    function() return Config.Tracers end,
    function(v) Config.Tracers = v end)
toggle("Barra de vida",
    function() return Config.HealthBar end,
    function(v) Config.HealthBar = v end)
toggle("Texto según vida",
    function() return Config.ColorByHealth end,
    function(v) Config.ColorByHealth = v end)

section("Colores")
colorRow("Cajas", "BoxColor")
colorRow("Tracers", "TracerColor")
colorRow("Texto (sin vida)", "TextColor")

section("Movimiento")
if MoveConfig then
    toggle("Speed",
        function() return MoveConfig.SpeedEnabled end,
        function(v) MoveConfig.SpeedEnabled = v end)
    slider("  Velocidad extra",
        function() return MoveConfig.Speed end,
        function(v) MoveConfig.Speed = v end,
        5, 200, 5)

    toggle("Super Jump",
        function() return MoveConfig.JumpEnabled end,
        function(v) MoveConfig.JumpEnabled = v end)
    slider("  Fuerza de salto",
        function() return MoveConfig.JumpPower end,
        function(v) MoveConfig.JumpPower = v end,
        50, 300, 10)

    toggle("Dash Multiplier",
        function() return MoveConfig.DashEnabled end,
        function(v) MoveConfig.DashEnabled = v end)
    slider("  Multiplicador",
        function() return MoveConfig.DashMultiplier end,
        function(v) MoveConfig.DashMultiplier = v end,
        1, 8, 0.5)
else
    soon("Speed")
    soon("Super Jump")
    soon("Dash Multiplier")
end
soon("Fly")
soon("Noclip")
soon("Teleport")

section("Misc")
soon("Fruit Finder")
soon("Server Hop")
soon("Anti-AFK")
soon("Guardar ajustes")

local hint = Instance.new("TextLabel")
hint.LayoutOrder = nextOrder()
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, 0, 0, 44)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextWrapped = true
hint.TextColor3 = C.Dim
hint.Text = "RightShift = ESP  |  V o botón DASH = dash  |  Arrastra la barra superior para mover"
hint.Parent = body

--// Minimizar
local minimized = false
minBtn.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    minBtn.Text = minimized and "+" or "-"
    frame.Size = minimized and UDim2.fromOffset(WIDTH, HEADER_H) or UDim2.fromOffset(WIDTH, HEIGHT)
end)

--// Arrastrar: solo sigue el dedo/ratón que empezó en la cabecera
local dragging = false
local dragInput, dragStart, startPos

table.insert(connections, header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPos = frame.Position

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
                conn:Disconnect()
            end
        end)
    end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragInput then return end

    if dragInput.UserInputType == Enum.UserInputType.Touch then
        if input ~= dragInput then return end -- ignora otros dedos
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local delta = input.Position - dragStart
    local screen = gui.AbsoluteSize
    local size = frame.AbsoluteSize
    local maxX = math.max(0, (screen.X - size.X) / 2)
    local maxY = math.max(0, (screen.Y - size.Y) / 2)

    frame.Position = UDim2.new(
        0.5, math.clamp(startPos.X.Offset + delta.X, -maxX, maxX),
        0.5, math.clamp(startPos.Y.Offset + delta.Y, -maxY, maxY)
    )
end))

--// Sincronizar botones si el ESP se cambia con la tecla
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Config.ToggleKey then
        task.defer(function()
            for _, refresh in ipairs(refreshers) do
                refresh()
            end
        end)
    end
end))

closeBtn.Activated:Connect(cleanup)

--// Transición: la carga se cierra y el panel aparece
for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
local hide = TweenService:Create(loadScale,
    TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
hide:Play()
hide.Completed:Wait()
loading:Destroy()

frame.Visible = true
TweenService:Create(panelScale,
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
