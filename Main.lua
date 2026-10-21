--// Main.lua - Froggy Hub (loader + panel) | UI v6.3: Total Restoration

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"

local SUPPORTED_GAMES = {
    [2753915549] = "BloxFruits", [4442272183] = "BloxFruits", [7449423635] = "BloxFruits",
    [7243409883] = "ElementalMagicArena",
}

local CurrentGameFolder = SUPPORTED_GAMES[game.PlaceId] or "Universal"
local GameDisplayName = (CurrentGameFolder == "BloxFruits" and "Blox Fruits") or (CurrentGameFolder == "ElementalMagicArena" and "Elemental Magic Arena") or "Universal"
local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH, CurrentGameFolder)

local ESP_FILES = { "Esp.lua" }
local ELEM_ESP_FILES = { "EspElemental.lua" }
local MOVE_FILES = { "Movement.lua" }
local CAM_FILES = { "Camlock.lua" }
local DODGE_FILES = { "AutoDodge.lua" }
local SA_FILES = { "SilentAim.lua" }
local POT_FILES = { "Potato.lua" }
local TP_FILES = { "Teleport.lua" }
local LIFT_FILES = { "AutoLift.lua" }
local DIAMOND_FILES = { "AutoDiamonds.lua" }
local AFARM_FILES = { "AutoFarmPlayers.lua" }
local HITBOX_FILES = { "HitboxExpander.lua" }
local LOGO_FILES = { "logo.png" }
local HUB_NAME = "Froggy Hub | " .. GameDisplayName

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if env.__BF_PANEL_CLEANUP then pcall(env.__BF_PANEL_CLEANUP) end

local C = {
    Bg = Color3.fromRGB(16, 16, 22), Header = Color3.fromRGB(22, 22, 30), Row = Color3.fromRGB(27, 27, 36),
    Stroke = Color3.fromRGB(52, 52, 66), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(135, 135, 150),
    Accent = Color3.fromRGB(110, 220, 90), AccentText = Color3.fromRGB(14, 24, 12), On = Color3.fromRGB(110, 220, 90),
    Off = Color3.fromRGB(58, 58, 72), Danger = Color3.fromRGB(210, 70, 70),
}

local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, color, thickness) local s = Instance.new("UIStroke"); s.Color = color or C.Stroke; s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s end
local function tween(o, t, props) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end

local function getParent()
    if gethui then local ok, ui = pcall(gethui); if ok and typeof(ui) == "Instance" then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", { Name = "FroggyHub_" .. tostring(math.random(1000, 9999)), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100 }, getParent())
local connections = {}
local tweens = {}

local function cleanup()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
    if env.__BF_ESP_CLEANUP then pcall(env.__BF_ESP_CLEANUP) end
    if env.__BF_MOVE_CLEANUP then pcall(env.__BF_MOVE_CLEANUP) end
    if env.__BF_CAM_CLEANUP then pcall(env.__BF_CAM_CLEANUP) end
    if env.__BF_DODGE_CLEANUP then pcall(env.__BF_DODGE_CLEANUP) end
    if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end
    if env.__BF_POTATO_CLEANUP then pcall(env.__BF_POTATO_CLEANUP) end
    if env.__BF_TP_CLEANUP then pcall(env.__BF_TP_CLEANUP) end
    if env.__BF_LIFT_CLEANUP then pcall(env.__BF_LIFT_CLEANUP) end
    if env.__BF_DIAMOND_CLEANUP then pcall(env.__BF_DIAMOND_CLEANUP) end
    if env.__BF_AFARM_CLEANUP then pcall(env.__BF_AFARM_CLEANUP) end
    if env.__BF_HITBOX_CLEANUP then pcall(env.__BF_HITBOX_CLEANUP) end
    if gui then gui:Destroy() end
    env.__BF_PANEL_CLEANUP = nil
end
env.__BF_PANEL_CLEANUP = cleanup

-- PANTALLA DE CARGA
local loading = new("Frame", { Size = UDim2.fromOffset(260, 220), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0 }, gui)
corner(loading, 14); stroke(loading, C.Stroke)
local loadScale = Instance.new("UIScale", loading)
local loadLogo = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1 }, loading)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.Accent, Text = "FROGGY HUB" }, loading)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 136), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.Text, Text = "Juego: " .. GameDisplayName }, loading)
local loadStatus = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 160), Size = UDim2.new(1, -20, 0, 18), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.Dim, Text = "Iniciando..." }, loading)
local barTrack = new("Frame", { Position = UDim2.new(0, 20, 1, -26), Size = UDim2.new(1, -40, 0, 6), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, loading)
corner(barTrack, 99)
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, barTrack)
corner(barFill, 99)

local function setProgress(fraction, text) tween(barFill, 0.35, { Size = UDim2.fromScale(fraction, 1) }); if text then loadStatus.Text = text end end
local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    for _, name in ipairs(LOGO_FILES) do
        local ok, data = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_logo.png"
            if pcall(writefile, path, data) then local okAsset, asset = pcall(getAsset, path); if okAsset and asset and asset ~= "" then return asset end end
        end
    end
    return nil
end
local function downloadModule(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then return res end
    end
    return nil
end
local function loadOptional(names, label, configKey)
    local src = downloadModule(names); if not src then return nil end
    local chunk, err = loadstring(src); if type(chunk) ~= "function" then return nil end
    local ok, runErr = pcall(chunk); if not ok then return nil end
    return env[configKey]
end

setProgress(0.1, "Cargando logo...")
local logoAsset = fetchLogo()
if logoAsset then
    loadLogo.Image = logoAsset; tween(loadLogo, 0.3, { ImageTransparency = 0 })
end

-- CARGA DE MÓDULOS
setProgress(0.3, "Cargando Interfaz Base...")
local Config = nil
if CurrentGameFolder == "ElementalMagicArena" then
    local source = downloadModule(ELEM_ESP_FILES)
    if source then local fn = loadstring(source); if fn then pcall(fn); Config = env.BF_ESP_CONFIG end end
else
    local source = downloadModule(ESP_FILES)
    if source then local fn = loadstring(source); if fn then pcall(fn); Config = env.BF_ESP_CONFIG end end
end
if not Config then Config = { Enabled = false, ToggleKey = Enum.KeyCode.RightShift } end

local MoveConfig = loadOptional(MOVE_FILES, "Movement.lua", "BF_MOVE_CONFIG")
local CamConfig = loadOptional(CAM_FILES, "Camlock.lua", "BF_CAM_CONFIG")
local DodgeConfig = loadOptional(DODGE_FILES, "AutoDodge.lua", "BF_DODGE_CONFIG")

local DiamondConfig, AFarmConfig, HitboxConfig = nil, nil, nil
if CurrentGameFolder == "ElementalMagicArena" then
    DiamondConfig = loadOptional(DIAMOND_FILES, "AutoDiamonds.lua", "BF_DIAMOND_CONFIG")
    AFarmConfig = loadOptional(AFARM_FILES, "AutoFarmPlayers.lua", "BF_AFARM_CONFIG")
    HitboxConfig = loadOptional(HITBOX_FILES, "HitboxExpander.lua", "BF_HITBOX_CONFIG")
    if not HitboxConfig then 
        HitboxConfig = { Enabled = false, Size = 25, TargetPart = "Torso", ShowVisual = true, IgnoreFriends = true }
        env.BF_HITBOX_CONFIG = HitboxConfig
    end
end

local SAConfig = nil
if CurrentGameFolder == "ElementalMagicArena" or CurrentGameFolder == "Universal" then
    SAConfig = loadOptional(SA_FILES, "SilentAim.lua", "BF_SA_CONFIG")
end

local TpConfig = loadOptional(TP_FILES, "Teleport.lua", "BF_TP_CONFIG")
local LiftConfig = loadOptional(LIFT_FILES, "AutoLift.lua", "BF_LIFT_CONFIG")
local PotConfig = loadOptional(POT_FILES, "Potato.lua", "BF_POTATO")

setProgress(1, "Listo"); task.wait(0.5)

-- PANEL PRINCIPAL
local function screenSize() local sz = gui.AbsoluteSize; if sz.X < 50 then local cam = workspace.CurrentCamera; sz = cam and cam.ViewportSize or Vector2.new(800, 600) end; return sz end
local S0 = screenSize()
local WIDTH = math.min(340, S0.X - 24); local HEIGHT = math.min(480, S0.Y - 20)
local HEADER_H = 46; local TAB_H = 40

local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromOffset(math.floor((S0.X - WIDTH) / 2), math.floor((S0.Y - HEIGHT) / 2)), BackgroundColor3 = C.Bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true, Visible = false }, gui)
corner(frame, 14); stroke(frame, C.Stroke)
local panelScale = Instance.new("UIScale", frame); panelScale.Scale = 0.8

local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C.Header, BorderSizePixel = 0, Active = true }, frame)
local titleX = 14
if logoAsset then new("ImageLabel", { Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset }, header); titleX = 50 end
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 5), Size = UDim2.new(1, -(titleX + 90), 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Text, Text = HUB_NAME }, header)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 26), Size = UDim2.new(1, -(titleX + 90), 0, 14), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Accent, Text = "Panel de control" }, header)

local function headerButton(text, xOffset)
    local b = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOffset, 0.5, -15), BackgroundColor3 = C.Row, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.Text, Text = text, AutoButtonColor = false }, header)
    corner(b, 8)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Stroke }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Row }) end)
    return b
end
local closeBtn = headerButton("X", -40); local minBtn = headerButton("-", -76)

local tabBar = new("ScrollingFrame", { Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = C.Header, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X }, frame)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, tabBar)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, tabBar)
new("Frame", { Position = UDim2.fromOffset(0, HEADER_H + TAB_H), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0 }, frame)

local PanelConfig = { Mode = "Normal", Scale = 1, Transparency = 0 }
env.BF_PANEL_CONFIG = PanelConfig

local function applyPanelStyle()
    local scale = PanelConfig.Scale or 1; local trans = PanelConfig.Transparency or 0
    tween(panelScale, 0.2, { Scale = scale }); tween(frame, 0.25, { BackgroundTransparency = trans })
    tween(header, 0.25, { BackgroundTransparency = math.min(trans + 0.05, 0.9) }); tween(tabBar, 0.25, { BackgroundTransparency = math.min(trans + 0.05, 0.9) })
    task.defer(function() local sz = screenSize(); local scaledW = WIDTH * scale; local scaledH = HEIGHT * scale; local x = math.clamp(frame.Position.X.Offset, 0, math.max(0, sz.X - scaledW)); local y = math.clamp(frame.Position.Y.Offset, 0, math.max(0, sz.Y - scaledH)); frame.Position = UDim2.fromOffset(x, y) end)
end

local BODY_Y = HEADER_H + TAB_H + 1; local pages, tabButtons = {}, {}; local order = 0
local function nextOrder() order = order + 1 return order end
local refreshers = {}

local function selectTab(name)
    for n, page in pairs(pages) do page.Visible = (n == name); local b = tabButtons[n]; tween(b, 0.15, { BackgroundColor3 = (n == name) and C.Accent or C.Row, TextColor3 = (n == name) and C.AccentText or C.Dim }) end
end

local function createPage(name, index)
    local page = new("ScrollingFrame", { Position = UDim2.fromOffset(8, BODY_Y + 8), Size = UDim2.new(1, -16, 1, -(BODY_Y + 14)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Stroke, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, page)
    pages[name] = page
    local b = new("TextButton", { LayoutOrder = index, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Row, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Dim, Text = name, AutoButtonColor = false }, tabBar)
    corner(b, 13); new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, b)
    b.Activated:Connect(function() selectTab(name) end); tabButtons[name] = b; return page
end

local pESP = createPage("ESP", 1); local pMove = createPage("Movimiento", 2); local pCombat = createPage("Combate", 3)
local pPerf = createPage("Rendimiento", 4); local pAjustes = createPage("Ajustes", 5); local pMisc = createPage("Misc", 6)

local function cardFrame(page)
    local card = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Row, BorderSizePixel = 0 }, page)
    corner(card, 10); stroke(card, C.Stroke)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, card)
    return card
end

local function card(page, title)
    local c = cardFrame(page)
    new("TextLabel", { LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Accent, Text = string.upper(title) }, c)
    return c
end

local function switchRow(parent, text, get, set, onChange, bold)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, parent)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -54, 1, 0), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = bold and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = bold and C.Text or Color3.fromRGB(205, 205, 215), Text = text, TextTruncate = Enum.TextTruncate.AtEnd }, row)
    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, row)
    corner(track, 99)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track)
    corner(knob, 99)
    local click = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2, AutoButtonColor = false }, row)
    local function refresh() local on = get() and true or false; tween(track, 0.15, { BackgroundColor3 = on and C.On or C.Off }); tween(knob, 0.15, { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }); if onChange then onChange(on) end end
    click.Activated:Connect(function() set(not get()); refresh() end); refresh(); table.insert(refreshers, refresh); return row
end

local function slider(parent, text, get, set, minV, maxV, stepV)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text, TextTruncate = Enum.TextTruncate.AtEnd }, row)
    local valueLabel = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(56, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.Accent }, row)
    local hit = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Active = true, ZIndex = 2 }, row)
    local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, hit)
    corner(track, 99)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, track); corner(fill, 99)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track); corner(knob, 99); stroke(knob, C.Accent, 2)
    local function refresh() local v = get() or minV; local rel = math.clamp((v - minV) / (maxV - minV), 0, 1); fill.Size = UDim2.fromScale(rel, 1); knob.Position = UDim2.new(rel, 0, 0.5, 0); valueLabel.Text = tostring(v) end
    local function setFromX(x) local width = math.max(1, track.AbsoluteSize.X); local rel = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1); local v = minV + rel * (maxV - minV); v = math.floor(v / stepV + 0.5) * stepV; v = math.clamp(math.floor(v * 100 + 0.5) / 100, minV, maxV); set(v); refresh() end
    local activeInput = nil
    table.insert(connections, hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeInput = input; setFromX(input.Position.X); local conn; conn = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then if activeInput == input then activeInput = nil end; conn:Disconnect() end end) end end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input) if not activeInput then return end; if activeInput.UserInputType == Enum.UserInputType.Touch then if input ~= activeInput then return end; elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end; setFromX(input.Position.X) end))
    refresh(); table.insert(refreshers, refresh)
end

local function group(page, title, get, set)
    local c = cardFrame(page)
    local sub = new("Frame", { LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, c)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sub)
    local g = { sub = sub, hasSubs = false }
    local head = switchRow(c, title, get, set, function(on) sub.Visible = on and g.hasSubs end, true)
    head.LayoutOrder = 0
    function g:toggle(text, getV, setV) g.hasSubs = true; switchRow(sub, text, getV, setV); sub.Visible = get() and true or false end
    function g:slider(text, getV, setV, a, b, s) g.hasSubs = true; slider(sub, text, getV, setV, a, b, s); sub.Visible = get() and true or false end
    return g
end

local missing = {}
local function soon(parent, text)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text }, row)
    local tag = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 20), BackgroundColor3 = C.Off, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.Dim, Text = "Próximamente" }, row)
    corner(tag, 6)
end

-- CONTENIDO: ESP
do
    local g = group(pESP, "ESP", function() return Config.Enabled end, function(v) Config.Enabled = v end)
    if CurrentGameFolder == "BloxFruits" then
        g:toggle("Mostrar compañeros", function() return Config.ShowTeammates end, function(v) Config.ShowTeammates = v end)
    end
    local vis = card(pESP, "Visual")
    switchRow(vis, "Cajas 2D", function() return Config.Boxes end, function(v) Config.Boxes = v end)
    switchRow(vis, "Tracers", function() return Config.Tracers end, function(v) Config.Tracers = v end)
    switchRow(vis, "Barra de vida", function() return Config.HealthBar end, function(v) Config.HealthBar = v end)
    switchRow(vis, "Texto según vida", function() return Config.ColorByHealth end, function(v) Config.ColorByHealth = v end)
end

-- CONTENIDO: MOVIMIENTO (RESTAURADO CON JUMP)
if MoveConfig then
    local s = group(pMove, "Speed", function() return MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end)
    s:slider("Velocidad extra", function() return MoveConfig.Speed end, function(v) MoveConfig.Speed = v end, 5, 200, 5)

    local j = group(pMove, "Super Jump", function() return MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end)
    j:slider("Fuerza de salto", function() return MoveConfig.JumpPower end, function(v) MoveConfig.JumpPower = v end, 50, 300, 10)

    local d = group(pMove, "Dash Multiplier", function() return MoveConfig.DashEnabled end, function(v) MoveConfig.DashEnabled = v end)
    d:slider("Multiplicador", function() return MoveConfig.DashMultiplier end, function(v) MoveConfig.DashMultiplier = v end, 1, 8, 0.5)
end

if TpConfig then
    local t = group(pMove, "Teleport (botón TP)", function() return TpConfig.Enabled end, function(v) TpConfig.Enabled = v end)
    t:slider("Cooldown (seg)", function() return TpConfig.Cooldown end, function(v) TpConfig.Cooldown = v end, 1, 60, 1)
    t:slider("Distancia detrás", function() return TpConfig.Offset end, function(v) TpConfig.Offset = v end, 2, 15, 1)
end

if LiftConfig then
    local l = group(pMove, "Elevarse con poca vida", function() return LiftConfig.Enabled end, function(v) LiftConfig.Enabled = v end)
    l:slider("Activar con vida (%)", function() return LiftConfig.Threshold end, function(v) LiftConfig.Threshold = v end, 5, 95, 5)
    l:slider("Altura (studs)", function() return LiftConfig.Height end, function(v) LiftConfig.Height = v end, 50, 3000, 50)
end

-- CONTENIDO: COMBATE
if CamConfig then
    local g = group(pCombat, "Camlock", function() return CamConfig.Enabled end, function(v) CamConfig.Enabled = v end)
    g:slider("Radio FOV", function() return CamConfig.FOV end, function(v) CamConfig.FOV = v end, 50, 600, 10)
    g:slider("Suavizado", function() return CamConfig.Smoothness end, function(v) CamConfig.Smoothness = v end, 0.05, 1, 0.05)
end

if DodgeConfig then
    local g = group(pCombat, "Auto Dodge (Ken/Dash)", function() return DodgeConfig.Enabled end, function(v) DodgeConfig.Enabled = v end)
    g:slider("Rango", function() return DodgeConfig.DetectRange end, function(v) DodgeConfig.DetectRange = v end, 10, 100, 5)
    g:toggle("Auto-Ken", function() return DodgeConfig.AutoKen end, function(v) DodgeConfig.AutoKen = v end)
    g:toggle("Auto-Dash", function() return DodgeConfig.AutoDash end, function(v) DodgeConfig.AutoDash = v end)
end

-- HITBOX EXPANDER
if HitboxConfig then
    local g = group(pCombat, "Hitbox Expander (Selectivo)", function() return HitboxConfig.Enabled end, function(v) HitboxConfig.Enabled = v end)
    g:slider("Tamaño Hitbox", function() return HitboxConfig.Size end, function(v) HitboxConfig.Size = v end, 10, 100, 5)
    g:toggle("Mostrar caja 3D", function() return HitboxConfig.ShowVisual end, function(v) HitboxConfig.ShowVisual = v end)
    g:toggle("Expandir Torso", function() return HitboxConfig.TargetPart == "Torso" end, function(v) HitboxConfig.TargetPart = v and "Torso" or "HumanoidRootPart"; for _, r in ipairs(refreshers) do r() end end)
    g:toggle("Expandir Cabeza", function() return HitboxConfig.TargetPart == "Head" end, function(v) HitboxConfig.TargetPart = v and "Head" or "HumanoidRootPart"; for _, r in ipairs(refreshers) do r() end end)
end

-- RESTO DE OPCIONES (AutoFarm, Diamonds, SilentAim...)
if AFarmConfig then
    local g = group(pCombat, "Auto Farm Players", function() return AFarmConfig.Enabled end, function(v) AFarmConfig.Enabled = v end)
    g:slider("Rango", function() return AFarmConfig.Range end, function(v) AFarmConfig.Range = v end, 50, 2000, 50)
end

-- CONTENIDO: RENDIMIENTO
if PotConfig then
    local g = group(pPerf, "Gráficos patata", function() return PotConfig.Enabled end, function(v) PotConfig.Set(v) end)
    g:toggle("Quitar partículas", function() return PotConfig.NoParticles end, function(v) PotConfig.NoParticles = v end)
    g:toggle("Quitar texturas", function() return PotConfig.NoTextures end, function(v) PotConfig.NoTextures = v end)
end

-- CONTENIDO: AJUSTES
do
    local themeCard = card(pAjustes, "Temas de Color")
    local themeRow = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, themeCard)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, themeRow)
    local THEMES = {
        { Name = "Froggy", Accent = Color3.fromRGB(110, 220, 90), Bg = Color3.fromRGB(16, 16, 22) },
        { Name = "Cyber", Accent = Color3.fromRGB(255, 50, 150), Bg = Color3.fromRGB(20, 10, 30) },
        { Name = "Blood", Accent = Color3.fromRGB(220, 60, 60), Bg = Color3.fromRGB(18, 10, 10) },
        { Name = "Ocean", Accent = Color3.fromRGB(50, 200, 255), Bg = Color3.fromRGB(10, 18, 25) },
        { Name = "Dark", Accent = Color3.fromRGB(200, 200, 200), Bg = Color3.fromRGB(10, 10, 10) },
    }
    local function applyTheme(theme)
        local oldC = {}; for k, v in pairs(C) do oldC[k] = v end
        C.Accent = theme.Accent; C.On = theme.Accent; C.Bg = theme.Bg; C.Header = theme.Bg:Lerp(Color3.new(1,1,1), 0.05); C.Row = theme.Bg:Lerp(Color3.new(1,1,1), 0.1); C.Stroke = theme.Bg:Lerp(Color3.new(1,1,1), 0.2); C.AccentText = Color3.fromRGB(14, 24, 12)
        local function colorMatches(c1, c2) return math.abs(c1.R - c2.R) < 0.02 and math.abs(c1.G - c2.G) < 0.02 and math.abs(c1.B - c2.B) < 0.02 end
        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("TextButton") or desc:IsA("TextLabel") then
                for k, v in pairs(oldC) do
                    if colorMatches(desc.BackgroundColor3, v) then desc.BackgroundColor3 = C[k] end
                    if colorMatches(desc.TextColor3, v) then desc.TextColor3 = C[k] end
                end
            elseif desc:IsA("UIStroke") then for k, v in pairs(oldC) do if colorMatches(desc.Color, v) then desc.Color = C[k] end end end
        end
        for _, refresh in ipairs(refreshers) do refresh() end; applyPanelStyle()
    end
    for _, t in ipairs(THEMES) do
        local b = new("TextButton", { Size = UDim2.fromOffset(50, 26), BackgroundColor3 = t.Accent, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(0,0,0), Text = t.Name, AutoButtonColor = false }, themeRow)
        corner(b, 6); b.Activated:Connect(function() applyTheme(t) end)
    end

    local ap = card(pAjustes, "Apariencia del panel")
    local presetRow = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, ap)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, presetRow)
    local presets = { { Name = "Discreto", Scale = 0.7, Trans = 0.5 }, { Name = "Normal", Scale = 1, Trans = 0 }, { Name = "Grande", Scale = 1.25, Trans = 0 } }
    local presetButtons = {}
    local function refreshPresets() for _, b in ipairs(presetButtons) do local active = (PanelConfig.Mode == b.data.Name); tween(b.btn, 0.15, { BackgroundColor3 = active and C.Accent or C.Row, TextColor3 = active and C.AccentText or C.Dim }) end end
    for i, p in ipairs(presets) do
        local btn = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1/3, -4, 1, 0), BackgroundColor3 = C.Row, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Dim, Text = p.Name, AutoButtonColor = false }, presetRow)
        corner(btn, 6); stroke(btn, C.Stroke)
        table.insert(presetButtons, { btn = btn, data = p })
        btn.Activated:Connect(function() PanelConfig.Mode = p.Name; PanelConfig.Scale = p.Scale; PanelConfig.Transparency = p.Trans; applyPanelStyle(); refreshPresets() end)
    end
    refreshPresets()
    slider(ap, "Escala del panel", function() return PanelConfig.Scale end, function(v) PanelConfig.Scale = v; PanelConfig.Mode = "Personalizado"; applyPanelStyle(); refreshPresets() end, 0.65, 1.4, 0.05)
    slider(ap, "Transparencia", function() return PanelConfig.Transparency end, function(v) PanelConfig.Transparency = v; PanelConfig.Mode = "Personalizado"; applyPanelStyle(); refreshPresets() end, 0, 0.85, 0.05)
end

-- CONTENIDO: MISC
do
    local sc = card(pMisc, "Próximamente")
    for _, name in ipairs({ "Fly", "Noclip", "Fruit Finder", "Server Hop", "Anti-AFK" }) do soon(sc, name) end
    for _, name in ipairs(missing) do soon(sc, name .. " (módulo no cargado)") end
end

selectTab("ESP")

-- 🔥 RESTAURACIÓN DE ARRASTRE Y MINIMIZACIÓN 🔥
local function clampPanel(x, y) local sz = screenSize(); local scale = PanelConfig.Scale or 1; return math.clamp(x, 0, math.max(0, sz.X - WIDTH * scale)), math.clamp(y, 0, math.max(0, sz.Y - HEIGHT * scale)) end
local function setPanelPos(x, y) x, y = clampPanel(x, y); frame.Position = UDim2.fromOffset(x, y) end

local function makeDraggable(handle, getPos, setPos, onTap)
    local active, startMouse, startPos, moved
    table.insert(connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = input; startMouse = input.Position; startPos = getPos(); moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then active = nil; if not moved and onTap then onTap() end end
                    conn:Disconnect()
                end
            end)
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        if active.UserInputType == Enum.UserInputType.Touch then if input ~= active then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = input.Position - startMouse; if d.Magnitude > 8 then moved = true end; if moved then setPos(startPos.X + d.X, startPos.Y + d.Y) end
    end))
end
makeDraggable(header, function() return Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset) end, setPanelPos)

local BUBBLE = 52
local bubble = new("TextButton", { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Header, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false }, gui)
corner(bubble, 99); stroke(bubble, C.Accent, 2)
if logoAsset then new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -14, 1, -14), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset, Active = false }, bubble)
else new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.Accent, Text = "F", Active = false }, bubble) end

local function setBubblePos(x, y) local sz = screenSize(); bubble.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, sz.X - BUBBLE)), math.clamp(y, 0, math.max(0, sz.Y - BUBBLE))) end
local function restorePanel() bubble.Visible = false; frame.Visible = true; setPanelPos(bubble.Position.X.Offset - 8, bubble.Position.Y.Offset - 8) end
local function minimizePanel() setBubblePos(frame.Position.X.Offset + 8, frame.Position.Y.Offset + 8); frame.Visible = false; bubble.Visible = true end

makeDraggable(bubble, function() return Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset) end, setBubblePos, restorePanel)
minBtn.Activated:Connect(minimizePanel)

table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local sz = screenSize(); WIDTH = math.min(340, sz.X - 24); HEIGHT = math.min(480, sz.Y - 20)
    frame.Size = UDim2.fromOffset(WIDTH, HEIGHT); setPanelPos(frame.Position.X.Offset, frame.Position.Y.Offset); setBubblePos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then if frame.Visible then minimizePanel() else restorePanel() end end
end))
closeBtn.Activated:Connect(cleanup)

for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
local hide = TweenService:Create(loadScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
hide:Play(); task.wait(0.3); loading:Destroy()
frame.Visible = true; tween(panelScale, 0.3, { Scale = PanelConfig.Scale })
print("[Froggy Hub] Panel v6.3 cargado con éxito para: " .. GameDisplayName)
