--// Main.lua - Froggy Hub (loader + panel) | UI v2: pestañas, switches y tarjetas

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ESP_FILES = { "Esp.lua", "esp.lua" }
local MOVE_FILES = { "Movement.lua", "movement.lua" }
local CAM_FILES = { "Camlock.lua", "camlock.lua" }
local SA_FILES = { "SilentAim.lua", "silentaim.lua" }
local POT_FILES = { "Potato.lua", "potato.lua" }
local TP_FILES = { "Teleport.lua", "teleport.lua" }
local LIFT_FILES = { "AutoLift.lua", "autolift.lua" }
local LOGO_FILES = { "logo.png", "Logo.png" }
local HUB_NAME = "Froggy Hub"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if env.__BF_PANEL_CLEANUP then
    pcall(env.__BF_PANEL_CLEANUP)
end

--// Colores
local C = {
    Bg = Color3.fromRGB(16, 16, 22),
    Header = Color3.fromRGB(22, 22, 30),
    Row = Color3.fromRGB(27, 27, 36),
    Stroke = Color3.fromRGB(52, 52, 66),
    Text = Color3.fromRGB(240, 240, 245),
    Dim = Color3.fromRGB(135, 135, 150),
    Accent = Color3.fromRGB(110, 220, 90),
    AccentText = Color3.fromRGB(14, 24, 12),
    On = Color3.fromRGB(110, 220, 90),
    Off = Color3.fromRGB(58, 58, 72),
    Danger = Color3.fromRGB(210, 70, 70),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end

local function stroke(o, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function tween(o, t, props)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", {
    Name = "FroggyHub", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
}, getParent())

local connections = {}
local tweens = {}

local function cleanup()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
    if env.__BF_ESP_CLEANUP then pcall(env.__BF_ESP_CLEANUP) end
    if env.__BF_MOVE_CLEANUP then pcall(env.__BF_MOVE_CLEANUP) end
    if env.__BF_CAM_CLEANUP then pcall(env.__BF_CAM_CLEANUP) end
    if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end
    if env.__BF_POTATO_CLEANUP then pcall(env.__BF_POTATO_CLEANUP) end
    if env.__BF_TP_CLEANUP then pcall(env.__BF_TP_CLEANUP) end
    if env.__BF_LIFT_CLEANUP then pcall(env.__BF_LIFT_CLEANUP) end
    gui:Destroy()
    env.__BF_PANEL_CLEANUP = nil
end
env.__BF_PANEL_CLEANUP = cleanup

--==================== PANTALLA DE CARGA ====================
local loading = new("Frame", {
    Size = UDim2.fromOffset(260, 200), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0,
}, gui)
corner(loading, 14)
stroke(loading, C.Stroke)
local loadScale = Instance.new("UIScale", loading)

local loadLogo = new("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62),
    Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1,
}, loading)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 24),
    Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.Accent, Text = string.upper(HUB_NAME),
}, loading)

local loadStatus = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 18),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.Dim, Text = "Iniciando...",
}, loading)

local barTrack = new("Frame", {
    Position = UDim2.new(0, 20, 1, -26), Size = UDim2.new(1, -40, 0, 6),
    BackgroundColor3 = C.Off, BorderSizePixel = 0,
}, loading)
corner(barTrack, 99)
local barFill = new("Frame", {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
}, barTrack)
corner(barFill, 99)

local function setProgress(fraction, text)
    tween(barFill, 0.35, { Size = UDim2.fromScale(fraction, 1) })
    if text then loadStatus.Text = text end
end

local function fail(message)
    loadStatus.Text = message
    loadStatus.TextColor3 = C.Danger
    warn("Froggy Hub: " .. message)
    task.delay(5, cleanup)
end

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

--// Módulo opcional: si falla, el panel igual abre
local function loadOptional(names, label, configKey)
    local src = downloadModule(names)
    if not src then
        warn("Froggy Hub: no se pudo descargar " .. label)
        return nil
    end
    local chunk, err = loadstring(src)
    if type(chunk) ~= "function" then
        warn("Froggy Hub: error de sintaxis en " .. label .. ": " .. tostring(err))
        return nil
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        warn("Froggy Hub: error al iniciar " .. label .. ": " .. tostring(runErr))
        return nil
    end
    return env[configKey]
end

setProgress(0.1, "Cargando logo...")
local logoAsset = fetchLogo()
if logoAsset then
    loadLogo.Image = logoAsset
    tween(loadLogo, 0.3, { ImageTransparency = 0 })
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

setProgress(0.7, "Descargando movimiento...")
local MoveConfig = loadOptional(MOVE_FILES, "Movement.lua", "BF_MOVE_CONFIG")
setProgress(0.85, "Descargando camlock...")
local CamConfig = loadOptional(CAM_FILES, "Camlock.lua", "BF_CAM_CONFIG")
setProgress(0.88, "Descargando Silent Aim...")
local SAConfig = loadOptional(SA_FILES, "SilentAim.lua", "BF_SA_CONFIG")
setProgress(0.9, "Descargando teleport...")
local TpConfig = loadOptional(TP_FILES, "Teleport.lua", "BF_TP_CONFIG")
setProgress(0.93, "Descargando elevación...")
local LiftConfig = loadOptional(LIFT_FILES, "AutoLift.lua", "BF_LIFT_CONFIG")
setProgress(0.95, "Descargando optimización...")
local PotConfig = loadOptional(POT_FILES, "Potato.lua", "BF_POTATO")

setProgress(1, "Listo")
task.wait(0.5)

--==================== PANEL PRINCIPAL ====================
local function screenSize()
    local sz = gui.AbsoluteSize
    if sz.X < 50 or sz.Y < 50 then
        local cam = workspace.CurrentCamera
        sz = cam and cam.ViewportSize or Vector2.new(800, 600)
    end
    return sz
end

local S0 = screenSize()
local WIDTH = math.min(340, S0.X - 24)
local HEIGHT = math.min(480, S0.Y - 20)
local HEADER_H = 46
local TAB_H = 40

local frame = new("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = UDim2.fromOffset(math.floor((S0.X - WIDTH) / 2), math.floor((S0.Y - HEIGHT) / 2)),
    BackgroundColor3 = C.Bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true, Visible = false,
}, gui)
corner(frame, 14)
stroke(frame, C.Stroke)
local panelScale = Instance.new("UIScale", frame)
panelScale.Scale = 0.8

--// Cabecera (arrastrable)
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C.Header, BorderSizePixel = 0, Active = true,
}, frame)

local titleX = 14
if logoAsset then
    new("ImageLabel", {
        Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit, Image = logoAsset,
    }, header)
    titleX = 50
end

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 5), Size = UDim2.new(1, -(titleX + 90), 0, 22),
    Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.Text, Text = HUB_NAME,
}, header)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 26), Size = UDim2.new(1, -(titleX + 90), 0, 14),
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.Accent, Text = "Panel de control",
}, header)

local function headerButton(text, xOffset)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOffset, 0.5, -15),
        BackgroundColor3 = C.Row, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.Text, Text = text, AutoButtonColor = false,
    }, header)
    corner(b, 8)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Stroke }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Row }) end)
    return b
end
local closeBtn = headerButton("X", -40)
local minBtn = headerButton("-", -76)

--// Barra de pestañas
local tabBar = new("ScrollingFrame", {
    Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 0, TAB_H),
    BackgroundColor3 = C.Header, BorderSizePixel = 0, ScrollBarThickness = 0,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
}, frame)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
}, tabBar)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, tabBar)
new("Frame", {
    Position = UDim2.fromOffset(0, HEADER_H + TAB_H), Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.Stroke, BorderSizePixel = 0,
}, frame)

local BODY_Y = HEADER_H + TAB_H + 1
local pages, tabButtons = {}, {}
local order = 0
local function nextOrder() order = order + 1 return order end
local refreshers = {}

local function selectTab(name)
    for n, page in pairs(pages) do
        page.Visible = (n == name)
        local b = tabButtons[n]
        tween(b, 0.15, {
            BackgroundColor3 = (n == name) and C.Accent or C.Row,
            TextColor3 = (n == name) and C.AccentText or C.Dim,
        })
    end
end

local function createPage(name, index)
    local page = new("ScrollingFrame", {
        Position = UDim2.fromOffset(8, BODY_Y + 8), Size = UDim2.new(1, -16, 1, -(BODY_Y + 14)),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Stroke,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, page)
    pages[name] = page

    local b = new("TextButton", {
        LayoutOrder = index, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = C.Row, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = C.Dim, Text = name, AutoButtonColor = false,
    }, tabBar)
    corner(b, 13)
    new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, b)
    b.Activated:Connect(function() selectTab(name) end)
    tabButtons[name] = b
    return page
end

local pESP = createPage("ESP", 1)
local pMove = createPage("Movimiento", 2)
local pCombat = createPage("Combate", 3)
local pPerf = createPage("Rendimiento", 4)
local pMisc = createPage("Misc", 5)

--==================== COMPONENTES ====================
local function cardFrame(page)
    local card = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Row, BorderSizePixel = 0,
    }, page)
    corner(card, 10)
    stroke(card, C.Stroke)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
    }, card)
    return card
end

--// Tarjeta simple con título
local function card(page, title)
    local c = cardFrame(page)
    new("TextLabel", {
        LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Accent, Text = string.upper(title),
    }, c)
    return c
end

--// Fila con switch
local function switchRow(parent, text, get, set, onChange, bold)
    local row = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -54, 1, 0),
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = bold and 14 or 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = bold and C.Text or Color3.fromRGB(205, 205, 215),
        Text = text, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, row)
    corner(track, 99)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, track)
    corner(knob, 99)
    local click = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, row)

    local function refresh()
        local on = get() and true or false
        tween(track, 0.15, { BackgroundColor3 = on and C.On or C.Off })
        tween(knob, 0.15, { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
        if onChange then onChange(on) end
    end
    click.Activated:Connect(function()
        set(not get())
        refresh()
    end)
    refresh()
    table.insert(refreshers, refresh)
    return row
end

--// Slider (dedo o ratón)
local function slider(parent, text, get, set, minV, maxV, stepV)
    local row = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local valueLabel = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(56, 18),
        Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.Accent,
    }, row)
    local hit = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Active = true,
    }, row)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, hit)
    corner(track, 99)
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
    }, track)
    corner(fill, 99)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, track)
    corner(knob, 99)
    stroke(knob, C.Accent, 2)

    local function refresh()
        local v = get()
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
        set(v)
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

--// Grupo: interruptor principal + opciones que solo se ven cuando está activo
local function group(page, title, get, set)
    local c = cardFrame(page)
    local sub = new("Frame", {
        LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Visible = false,
    }, c)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sub)
    local g = { sub = sub, hasSubs = false }
    local head = switchRow(c, title, get, set, function(on)
        sub.Visible = on and g.hasSubs
    end, true)
    head.LayoutOrder = 0
    function g:toggle(text, getV, setV)
        g.hasSubs = true
        switchRow(sub, text, getV, setV)
        sub.Visible = get() and true or false
    end
    function g:slider(text, getV, setV, a, b, s)
        g.hasSubs = true
        slider(sub, text, getV, setV, a, b, s)
        sub.Visible = get() and true or false
    end
    return g
end

local PALETTE = {
    Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 225, 60),
    Color3.fromRGB(80, 220, 100), Color3.fromRGB(70, 200, 255), Color3.fromRGB(90, 120, 255),
    Color3.fromRGB(190, 90, 255), Color3.fromRGB(255, 255, 255),
}

local function colorRow(parent, text, key)
    local row = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text,
    }, row)
    local holder = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 26),
    }, row)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    }, holder)

    local swatches = {}
    local function refresh()
        for _, item in ipairs(swatches) do
            item.stroke.Enabled = (Config[key] == item.color)
        end
    end
    for i, color in ipairs(PALETTE) do
        local b = new("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(26, 26), BackgroundColor3 = color,
            BorderSizePixel = 0, Text = "", AutoButtonColor = true,
        }, holder)
        corner(b, 99)
        local s = new("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 255, 255), Enabled = false }, b)
        table.insert(swatches, { stroke = s, color = color })
        b.Activated:Connect(function()
            Config[key] = color
            refresh()
        end)
    end
    refresh()
end

local missing = {}
local function soon(parent, text)
    local row = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -96, 1, 0), Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text,
    }, row)
    local tag = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 20),
        BackgroundColor3 = C.Off, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = C.Dim, Text = "Próximamente",
    }, row)
    corner(tag, 6)
end

--==================== CONTENIDO ====================
--// ESP
do
    local g = group(pESP, "ESP", function() return Config.Enabled end, function(v) Config.Enabled = v end)
    g:toggle("Mostrar compañeros", function() return Config.ShowTeammates end, function(v) Config.ShowTeammates = v end)

    local vis = card(pESP, "Visual")
    switchRow(vis, "Cajas 2D", function() return Config.Boxes end, function(v) Config.Boxes = v end)
    switchRow(vis, "Tracers", function() return Config.Tracers end, function(v) Config.Tracers = v end)
    switchRow(vis, "Barra de vida", function() return Config.HealthBar end, function(v) Config.HealthBar = v end)
    switchRow(vis, "Texto según vida", function() return Config.ColorByHealth end, function(v) Config.ColorByHealth = v end)

    local col = card(pESP, "Colores")
    colorRow(col, "Cajas", "BoxColor")
    colorRow(col, "Tracers", "TracerColor")
    colorRow(col, "Texto (sin vida)", "TextColor")
end

--// Movimiento
if MoveConfig then
    local s = group(pMove, "Speed", function() return MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end)
    s:slider("Velocidad extra", function() return MoveConfig.Speed end, function(v) MoveConfig.Speed = v end, 5, 200, 5)

    local j = group(pMove, "Super Jump", function() return MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end)
    j:slider("Fuerza de salto", function() return MoveConfig.JumpPower end, function(v) MoveConfig.JumpPower = v end, 50, 300, 10)

    local d = group(pMove, "Dash Multiplier", function() return MoveConfig.DashEnabled end, function(v) MoveConfig.DashEnabled = v end)
    d:slider("Multiplicador", function() return MoveConfig.DashMultiplier end, function(v) MoveConfig.DashMultiplier = v end, 1, 8, 0.5)
else
    table.insert(missing, "Speed / Super Jump / Dash")
end

if TpConfig then
    local t = group(pMove, "Teleport (botón TP)", function() return TpConfig.Enabled end, function(v) TpConfig.Enabled = v end)
    t:slider("Cooldown (seg)", function() return TpConfig.Cooldown end, function(v) TpConfig.Cooldown = v end, 1, 60, 1)
    t:slider("Distancia detrás del enemigo", function() return TpConfig.Offset end, function(v) TpConfig.Offset = v end, 2, 15, 1)
    t:toggle("Team check", function() return TpConfig.TeamCheck end, function(v) TpConfig.TeamCheck = v end)
    t:toggle("Ignorar amigos", function() return TpConfig.IgnoreFriends end, function(v) TpConfig.IgnoreFriends = v end)
else
    table.insert(missing, "Teleport")
end

if LiftConfig then
    local l = group(pMove, "Elevarse con poca vida", function() return LiftConfig.Enabled end, function(v) LiftConfig.Enabled = v end)
    l:slider("Activar con vida (%)", function() return LiftConfig.Threshold end, function(v) LiftConfig.Threshold = v end, 5, 95, 5)
    l:slider("Altura (studs)", function() return LiftConfig.Height end, function(v) LiftConfig.Height = v end, 50, 3000, 50)
    l:toggle("Bajar solo al recuperar vida", function() return LiftConfig.AutoDescend end, function(v) LiftConfig.AutoDescend = v end)
    l:slider("Bajar al recuperar (%)", function() return LiftConfig.RecoverPercent end, function(v) LiftConfig.RecoverPercent = v end, 10, 100, 5)
else
    table.insert(missing, "Elevarse con poca vida")
end

--// Combate
if CamConfig then
    local g = group(pCombat, "Camlock", function() return CamConfig.Enabled end, function(v) CamConfig.Enabled = v end)
    g:slider("Radio FOV", function() return CamConfig.FOV end, function(v) CamConfig.FOV = v end, 50, 600, 10)
    g:slider("Suavizado", function() return CamConfig.Smoothness end, function(v) CamConfig.Smoothness = v end, 0.05, 1, 0.05)
    g:slider("Predicción (seg)", function() return CamConfig.Prediction end, function(v) CamConfig.Prediction = v end, 0, 0.5, 0.05)
    g:slider("Soltar a distancia (0 = nunca)", function() return CamConfig.ReleaseDistance end, function(v) CamConfig.ReleaseDistance = v end, 0, 2000, 50)
    g:toggle("Girar personaje al objetivo", function() return CamConfig.FaceTarget end, function(v) CamConfig.FaceTarget = v end)
    g:toggle("Apuntar a la cabeza", function() return CamConfig.AimPart == "Head" end,
        function(v) CamConfig.AimPart = v and "Head" or "HumanoidRootPart" end)
    g:toggle("Team check", function() return CamConfig.TeamCheck end, function(v) CamConfig.TeamCheck = v end)
    g:toggle("Ignorar amigos", function() return CamConfig.IgnoreFriends end, function(v) CamConfig.IgnoreFriends = v end)
    g:toggle("Wall check", function() return CamConfig.WallCheck end, function(v) CamConfig.WallCheck = v end)
    g:toggle("Mostrar círculo FOV", function() return CamConfig.ShowFOV end, function(v) CamConfig.ShowFOV = v end)
else
    table.insert(missing, "Camlock")
end

if SAConfig then
    local g = group(pCombat, "Silent Aim", function() return SAConfig.Enabled end, function(v) SAConfig.Enabled = v end)
    g:slider("Radio FOV", function() return SAConfig.FOV end, function(v) SAConfig.FOV = v end, 50, 600, 10)
    g:slider("Distancia máxima", function() return SAConfig.MaxDistance end, function(v) SAConfig.MaxDistance = v end, 0, 1000, 50)
    g:slider("Predicción (seg)", function() return SAConfig.Prediction end, function(v) SAConfig.Prediction = v end, 0, 0.5, 0.05)
    g:toggle("Atacar NPCs", function() return SAConfig.AttackNPCs end, function(v) SAConfig.AttackNPCs = v end)
    g:toggle("Apuntar a la cabeza", function() return SAConfig.AimPart == "Head" end,
        function(v) SAConfig.AimPart = v and "Head" or "HumanoidRootPart" end)
    g:toggle("Team check", function() return SAConfig.TeamCheck end, function(v) SAConfig.TeamCheck = v end)
    g:toggle("Ignorar amigos", function() return SAConfig.IgnoreFriends end, function(v) SAConfig.IgnoreFriends = v end)
    g:toggle("Wall check", function() return SAConfig.WallCheck end, function(v) SAConfig.WallCheck = v end)
else
    table.insert(missing, "Silent Aim")
end

--// Rendimiento
if PotConfig then
    local g = group(pPerf, "Gráficos patata", function() return PotConfig.Enabled end, function(v) PotConfig.Set(v) end)
    g:toggle("Quitar partículas y efectos", function() return PotConfig.NoParticles end, function(v) PotConfig.NoParticles = v end)
    g:toggle("Quitar texturas", function() return PotConfig.NoTextures end, function(v) PotConfig.NoTextures = v end)
    g:toggle("Materiales planos", function() return PotConfig.FlatMaterials end, function(v) PotConfig.FlatMaterials = v end)
else
    table.insert(missing, "Gráficos patata")
end

--// Misc
do
    local sc = card(pMisc, "Próximamente")
    for _, name in ipairs({ "Fly", "Noclip", "Fruit Finder", "Server Hop", "Anti-AFK", "Guardar ajustes" }) do
        soon(sc, name)
    end
    for _, name in ipairs(missing) do
        soon(sc, name .. " (módulo no cargado)")
    end

    local hc = card(pMisc, "Controles")
    new("TextLabel", {
        LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C.Dim,
        Text = "RightShift: ESP\nV / botón DASH: dash\nC / botón LOCK: camlock\nT / botón TP: teleport\nRightControl: abrir o minimizar\nArrastra la barra superior para mover el panel.",
    }, hc)
end

selectTab("ESP")

--==================== POSICIÓN, ARRASTRE Y BURBUJA ====================
local function clampPanel(x, y)
    local sz = screenSize()
    return math.clamp(x, 0, math.max(0, sz.X - WIDTH)),
           math.clamp(y, 0, math.max(0, sz.Y - HEIGHT))
end

local function setPanelPos(x, y)
    x, y = clampPanel(x, y)
    frame.Position = UDim2.fromOffset(x, y)
end

local function makeDraggable(handle, getPos, setPos, onTap)
    local active, startMouse, startPos, moved

    table.insert(connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            active = input
            startMouse = input.Position
            startPos = getPos()
            moved = false
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then
                        active = nil
                        if not moved and onTap then onTap() end
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
        if d.Magnitude > 8 then moved = true end
        if moved then setPos(startPos.X + d.X, startPos.Y + d.Y) end
    end))
end

makeDraggable(header,
    function() return Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset) end,
    setPanelPos)

local BUBBLE = 52
local bubble = new("TextButton", {
    Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Header, BorderSizePixel = 0,
    AutoButtonColor = false, Text = "", Visible = false,
}, gui)
corner(bubble, 99)
stroke(bubble, C.Accent, 2)

if logoAsset then
    new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -14, 1, -14),
        BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset, Active = false,
    }, bubble)
else
    new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 22,
        TextColor3 = C.Accent, Text = "F", Active = false,
    }, bubble)
end

local function setBubblePos(x, y)
    local sz = screenSize()
    bubble.Position = UDim2.fromOffset(
        math.clamp(x, 0, math.max(0, sz.X - BUBBLE)),
        math.clamp(y, 0, math.max(0, sz.Y - BUBBLE))
    )
end

local function restorePanel()
    bubble.Visible = false
    frame.Visible = true
    setPanelPos(bubble.Position.X.Offset - 8, bubble.Position.Y.Offset - 8)
end

local function minimizePanel()
    setBubblePos(frame.Position.X.Offset + 8, frame.Position.Y.Offset + 8)
    frame.Visible = false
    bubble.Visible = true
end

makeDraggable(bubble,
    function() return Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset) end,
    setBubblePos,
    restorePanel)

minBtn.Activated:Connect(minimizePanel)

table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local sz = screenSize()
    WIDTH = math.min(340, sz.X - 24)
    HEIGHT = math.min(480, sz.Y - 20)
    frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
    setPanelPos(frame.Position.X.Offset, frame.Position.Y.Offset)
    setBubblePos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if frame.Visible then minimizePanel() else restorePanel() end
    end
end))

--// Sincronizar switches si el ESP se cambia con la tecla
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
task.wait(0.3)
loading:Destroy()

frame.Visible = true
tween(panelScale, 0.3, { Scale = 1 })
