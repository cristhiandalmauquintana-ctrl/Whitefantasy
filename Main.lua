--// Main.lua - Froggy Hub (loader + panel) | UI v8.1: Manual Game Selector

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

if env.__BF_PANEL_CLEANUP then pcall(env.__BF_PANEL_CLEANUP) end

-- TEMAS Y PALETA (Necesarios para el menú de selección)
local THEMES = {
    { Name = "Froggy", Accent = Color3.fromRGB(110, 220, 90),  Accent2 = Color3.fromRGB(40, 170, 130),  Bg = Color3.fromRGB(16, 16, 22) },
    { Name = "Cyber",  Accent = Color3.fromRGB(255, 50, 150),  Accent2 = Color3.fromRGB(120, 80, 255),  Bg = Color3.fromRGB(20, 10, 30) },
    { Name = "Blood",  Accent = Color3.fromRGB(220, 60, 60),   Accent2 = Color3.fromRGB(255, 130, 60),  Bg = Color3.fromRGB(18, 10, 10) },
    { Name = "Ocean",  Accent = Color3.fromRGB(50, 200, 255),  Accent2 = Color3.fromRGB(60, 120, 255),  Bg = Color3.fromRGB(10, 18, 25) },
    { Name = "Sunset", Accent = Color3.fromRGB(255, 140, 60),  Accent2 = Color3.fromRGB(255, 70, 130),  Bg = Color3.fromRGB(24, 12, 16) },
    { Name = "Aurora", Accent = Color3.fromRGB(90, 255, 190),  Accent2 = Color3.fromRGB(150, 110, 255), Bg = Color3.fromRGB(10, 20, 22) },
    { Name = "Sakura", Accent = Color3.fromRGB(255, 150, 190), Accent2 = Color3.fromRGB(200, 130, 255), Bg = Color3.fromRGB(26, 14, 22) },
    { Name = "Galaxy", Accent = Color3.fromRGB(150, 110, 255), Accent2 = Color3.fromRGB(70, 150, 255),  Bg = Color3.fromRGB(12, 10, 28) },
    { Name = "Matrix", Accent = Color3.fromRGB(60, 255, 90),   Accent2 = Color3.fromRGB(0, 150, 50),    Bg = Color3.fromRGB(6, 14, 8) },
    { Name = "Gold",   Accent = Color3.fromRGB(255, 200, 60),  Accent2 = Color3.fromRGB(255, 140, 40),  Bg = Color3.fromRGB(20, 16, 8) },
    { Name = "Ice",    Accent = Color3.fromRGB(160, 225, 255), Accent2 = Color3.fromRGB(120, 170, 255), Bg = Color3.fromRGB(12, 18, 28) },
    { Name = "Mono",   Accent = Color3.fromRGB(210, 210, 215), Accent2 = Color3.fromRGB(120, 120, 135), Bg = Color3.fromRGB(10, 10, 12) },
}
local function themeByName(name) for _, t in ipairs(THEMES) do if t.Name == name then return t end end return THEMES[1] end

local SETTINGS_FILE = "FroggyHub_settings.json"
local Saved = {}
if type(isfile) == "function" and type(readfile) == "function" then
    pcall(function()
        if isfile(SETTINGS_FILE) then
            local decoded = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            if type(decoded) == "table" then Saved = decoded end
        end
    end)
end

local PanelConfig = {
    Mode = (type(Saved.Mode) == "string") and Saved.Mode or "Normal",
    Scale = math.clamp(tonumber(Saved.Scale) or 1, 0.65, 1.4),
    Transparency = math.clamp(tonumber(Saved.Transparency) or 0, 0, 0.85),
    AnimBg = Saved.AnimBg ~= false,
    Particles = math.clamp(math.floor(tonumber(Saved.Particles) or 16), 0, 30),
    Animations = Saved.Animations ~= false,
    Theme = (type(Saved.Theme) == "string") and Saved.Theme or "Froggy",
}
env.BF_PANEL_CONFIG = PanelConfig

local function saveSettings()
    if type(writefile) ~= "function" then return end
    Saved.Theme = PanelConfig.Theme; Saved.Mode = PanelConfig.Mode; Saved.Scale = PanelConfig.Scale
    Saved.Transparency = PanelConfig.Transparency; Saved.AnimBg = PanelConfig.AnimBg
    Saved.Particles = PanelConfig.Particles; Saved.Animations = PanelConfig.Animations
    pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Saved)) end)
end

local C = { Danger = Color3.fromRGB(210, 70, 70), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(150, 150, 165), AccentText = Color3.fromRGB(12, 14, 12) }
local function setPalette(theme)
    local bg, white = theme.Bg, Color3.new(1, 1, 1)
    C.Bg = bg; C.Header = bg:Lerp(white, 0.06); C.Row = bg:Lerp(white, 0.10)
    C.Stroke = bg:Lerp(white, 0.22); C.Off = bg:Lerp(white, 0.20)
    C.Accent = theme.Accent; C.Accent2 = theme.Accent2; C.On = theme.Accent
end
setPalette(themeByName(PanelConfig.Theme))

local binds, gradients, refreshers = {}, {}, {}
local function bind(o, prop, key) table.insert(binds, { o = o, p = prop, k = key }); o[prop] = C[key]; return o end
local function tween(o, t, props, style, dir)
    if PanelConfig.Animations == false then t = 0 end
    if t <= 0 then for k, v in pairs(props) do pcall(function() o[k] = v end) end return nil end
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, key, thickness)
    local s = Instance.new("UIStroke"); s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o
    bind(s, "Color", key or "Stroke"); return s
end
local function accentSeq() return ColorSequence.new(C.Accent, C.Accent2) end

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
    if env.__BF_COMBAT_CLEANUP then pcall(env.__BF_COMBAT_CLEANUP) end
    if gui then gui:Destroy() end
    env.__BF_PANEL_CLEANUP = nil
end
env.__BF_PANEL_CLEANUP = cleanup

-- ==========================================
-- 🛠️ SELECTOR MANUAL DE JUEGO (FIX DUELO)
-- ==========================================
local CurrentGameFolder = "Universal"
local GameDisplayName = "Universal"
local ROOT_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)
local BASE_URL = ROOT_URL

local promptGui = new("Frame", { Size = UDim2.fromOffset(300, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ZIndex = 999 }, gui)
bind(promptGui, "BackgroundColor3", "Bg"); corner(promptGui, 14); stroke(promptGui, "Accent", 2)
local promptScale = Instance.new("UIScale", promptGui); promptScale.Scale = 0.6
tween(promptScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, Text = "¿Qué juego estás jugando?" }, promptGui), "TextColor3", "Text")

local btnElem = new("TextButton", { Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 0, 45), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, Text = "Elemental Magic Arena", AutoButtonColor = false, ZIndex = 1000 }, promptGui)
bind(btnElem, "BackgroundColor3", "Row"); bind(btnElem, "TextColor3", "Text"); corner(btnElem, 8)
local btnElemStroke = Instance.new("UIStroke", btnElem); btnElemStroke.Color = C.Accent; btnElemStroke.Thickness = 1; btnElemStroke.Parent = btnElem

local btnBlox = new("TextButton", { Position = UDim2.fromOffset(20, 115), Size = UDim2.new(1, -40, 0, 45), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, Text = "Blox Fruits", AutoButtonColor = false, ZIndex = 1000 }, promptGui)
bind(btnBlox, "BackgroundColor3", "Row"); bind(btnBlox, "TextColor3", "Text"); corner(btnBlox, 8)
local btnBloxStroke = Instance.new("UIStroke", btnBlox); btnBloxStroke.Color = C.Accent; btnBloxStroke.Thickness = 1; btnBloxStroke.Parent = btnBlox

local selectionMade = false

local function finishSelection(folder, display)
    if selectionMade then return end
    selectionMade = true
    CurrentGameFolder = folder
    GameDisplayName = display
    if CurrentGameFolder == "BloxFruits" then
        BASE_URL = ROOT_URL
    else
        BASE_URL = ROOT_URL .. CurrentGameFolder .. "/"
    end
    tween(promptScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.2)
    promptGui:Destroy()
end

btnElem.Activated:Connect(function() finishSelection("ElementalMagicArena", "Elemental Magic Arena") end)
btnBlox.Activated:Connect(function() finishSelection("BloxFruits", "Blox Fruits") end)

repeat task.wait() until selectionMade
-- ==========================================

local HUB_NAME = "Froggy Hub | " .. GameDisplayName
local HUB_VERSION = "v8.1"

-- PANTALLA DE CARGA
local loading = new("Frame", { Size = UDim2.fromOffset(260, 220), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ZIndex = 998 }, gui)
bind(loading, "BackgroundColor3", "Bg"); corner(loading, 14)
local loadStroke = stroke(loading, "Accent", 2)
local loadScale = Instance.new("UIScale", loading); loadScale.Scale = 0.6
tween(loadScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
local loadPulse = TweenService:Create(loadStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.75 })
loadPulse:Play(); table.insert(tweens, loadPulse)
local loadLogo = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1 }, loading)
local loadTitle = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), Text = "FROGGY HUB" }, loading)
local loadGame = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 136), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham, TextSize = 12, Text = "Juego: " .. GameDisplayName }, loading)
bind(loadGame, "TextColor3", "Text")
local loadStatus = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 160), Size = UDim2.new(1, -20, 0, 18), Font = Enum.Font.Gotham, TextSize = 12, Text = "Iniciando..." }, loading)
bind(loadStatus, "TextColor3", "Dim")
local barTrack = new("Frame", { Position = UDim2.new(0, 20, 1, -26), Size = UDim2.new(1, -40, 0, 6), BorderSizePixel = 0 }, loading)
bind(barTrack, "BackgroundColor3", "Off"); corner(barTrack, 99)
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, barTrack)
corner(barFill, 99); addGradient(barFill, accentSeq, 0)

local function setProgress(fraction, text) tween(barFill, 0.35, { Size = UDim2.fromScale(fraction, 1) }); if text then loadStatus.Text = text end end

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
local COMBAT_FILES = { "AutoCombat.lua" }
local LOGO_FILES = { "logo.png" }

local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    local urlsToTry = { BASE_URL .. "logo.png?v=" .. os.time(), ROOT_URL .. "logo.png?v=" .. os.time() }
    for _, url in ipairs(urlsToTry) do
        local ok, data = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_logo.png"
            if pcall(writefile, path, data) then 
                local okAsset, asset = pcall(getAsset, path)
                if okAsset and asset and asset ~= "" then return asset end 
            end
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
    local src = downloadModule(names)
    if not src then warn("[Froggy] ❌ " .. (label or "?") .. ": descarga falló (404)"); return nil end
    local chunk, err = loadstring(src)
    if type(chunk) ~= "function" then warn("[Froggy] ❌ " .. (label or "?") .. ": error de sintaxis → " .. tostring(err)); return nil end
    local ok, runErr = pcall(chunk)
    if not ok then warn("[Froggy] ❌ " .. (label or "?") .. ": error de ejecución → " .. tostring(runErr)); return nil end
    local cfg = env[configKey] or _G[configKey]
    if not cfg then warn("[Froggy] ❌ " .. (label or "?") .. ": el módulo no expuso " .. configKey); return nil end
    return cfg
end

setProgress(0.1, "Cargando logo...")
local logoAsset = fetchLogo()
if logoAsset then
    loadLogo.Image = logoAsset; tween(loadLogo, 0.3, { ImageTransparency = 0 })
end

setProgress(0.3, "Cargando Interfaz Base...")
local Config = nil
if CurrentGameFolder == "ElementalMagicArena" then
    local source = downloadModule(ELEM_ESP_FILES)
    if source then local fn = loadstring(source); if fn then pcall(fn); Config = env.BF_ESP_CONFIG or _G.BF_ESP_CONFIG end end
else
    local source = downloadModule(ESP_FILES)
    if source then local fn = loadstring(source); if fn then pcall(fn); Config = env.BF_ESP_CONFIG or _G.BF_ESP_CONFIG end end
end
if not Config then Config = { Enabled = false, ToggleKey = Enum.KeyCode.RightShift } end

local MoveConfig = loadOptional(MOVE_FILES, "Movement.lua", "BF_MOVE_CONFIG")
local CamConfig = loadOptional(CAM_FILES, "Camlock.lua", "BF_CAM_CONFIG")
local DodgeConfig = loadOptional(DODGE_FILES, "AutoDodge.lua", "BF_DODGE_CONFIG")

local DiamondConfig, AFarmConfig, HitboxConfig, CombatConfig = nil, nil, nil, nil
local HitboxLoadFailed = false

if CurrentGameFolder == "ElementalMagicArena" then
    DiamondConfig = loadOptional(DIAMOND_FILES, "AutoDiamonds.lua", "BF_DIAMOND_CONFIG")
    AFarmConfig = loadOptional(AFARM_FILES, "AutoFarmPlayers.lua", "BF_AFARM_CONFIG")
    HitboxConfig = loadOptional(HITBOX_FILES, "HitboxExpander.lua", "BF_HITBOX_CONFIG")
    if not HitboxConfig then
        HitboxLoadFailed = true
        HitboxConfig = { Enabled = false, Size = 35, Transparency = 0.7, Color = Color3.fromRGB(255,0,0), IgnoreFriends = true, Range = 1000 }
        env.BF_HITBOX_CONFIG = HitboxConfig
    end
    CombatConfig = loadOptional(COMBAT_FILES, "AutoCombat.lua", "BF_COMBAT_CONFIG")
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
local WIDTH = math.min(540, S0.X - 24); local HEIGHT = math.min(340, S0.Y - 20)
local HEADER_H = 46; local SIDE_W = 118
local HEADER_T, CARD_T = 0.3, 0.2

local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromOffset(math.floor((S0.X - WIDTH) / 2), math.floor((S0.Y - HEIGHT) / 2)), BorderSizePixel = 0, ClipsDescendants = true, Active = true, Visible = false }, gui)
bind(frame, "BackgroundColor3", "Bg"); corner(frame, 18); stroke(frame, "Stroke")
local panelScale = Instance.new("UIScale", frame); panelScale.Scale = 0.8

local bgLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 0 }, frame); corner(bgLayer, 18)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = HEADER_T, BorderSizePixel = 0, Active = true }, frame)
bind(header, "BackgroundColor3", "Header")
local titleX = 14
local headerLogo
if logoAsset then headerLogo = new("ImageLabel", { Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset }, header); titleX = 50 end
bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 5), Size = UDim2.new(1, -(titleX + 90), 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = HUB_NAME }, header), "TextColor3", "Text")
bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -120, 0.5, -7), Size = UDim2.fromOffset(40, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Text = HUB_VERSION }, header), "TextColor3", "Dim")

local function headerButton(text, xOffset, hoverKey)
    local b = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOffset, 0.5, -15), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, Text = text, AutoButtonColor = false }, header)
    bind(b, "BackgroundColor3", "Row"); bind(b, "TextColor3", "Text"); corner(b, 8)
    local bs = Instance.new("UIScale", b)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = hoverKey == "Danger" and C.Danger or C.Stroke }); tween(bs, 0.12, { Scale = 1.1 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Row }); tween(bs, 0.12, { Scale = 1 }) end)
    b.MouseButton1Down:Connect(function() tween(bs, 0.08, { Scale = 0.9 }) end)
    return b
end
local closeBtn = headerButton("X", -40, "Danger"); local minBtn = headerButton("-", -76)

local tabBar = new("ScrollingFrame", { Position = UDim2.fromOffset(0, HEADER_H + 2), Size = UDim2.new(0, SIDE_W, 1, -(HEADER_H + 2)), BackgroundTransparency = HEADER_T, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, frame)
bind(tabBar, "BackgroundColor3", "Header"); corner(tabBar, 14)
new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, tabBar)

local BODY_Y = HEADER_H + 2; local pages, tabButtons = {}, {}; local order = 0
local function nextOrder() order = order + 1 return order end
local currentTab = nil

local function selectTab(name, instant)
    currentTab = name
    for n, page in pairs(pages) do
        local on = (n == name)
        page.Visible = on
        tween(tabButtons[n], 0.2, { BackgroundColor3 = on and C.Accent or C.Row, TextColor3 = on and C.AccentText or C.Dim })
    end
end

local function createPage(name, index)
    local page = new("ScrollingFrame", { Position = UDim2.fromOffset(SIDE_W + 8, BODY_Y + 8), Size = UDim2.new(1, -(SIDE_W + 16), 1, -(BODY_Y + 14)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, frame)
    bind(page, "ScrollBarImageColor3", "Accent")
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, page)
    pages[name] = page
    local b = new("TextButton", { LayoutOrder = index, Size = UDim2.new(1, 0, 0, 34), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = name, AutoButtonColor = false }, tabBar)
    b.BackgroundColor3 = C.Row; b.TextColor3 = C.Dim
    corner(b, 9); new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 8) }, b)
    b.Activated:Connect(function() if currentTab ~= name then selectTab(name) end end)
    b.MouseEnter:Connect(function() if currentTab ~= name then tween(b, 0.12, { BackgroundColor3 = C.Stroke, TextColor3 = C.Text }) end end)
    b.MouseLeave:Connect(function() if currentTab ~= name then tween(b, 0.12, { BackgroundColor3 = C.Row, TextColor3 = C.Dim }) end end)
    tabButtons[name] = b; return page
end

local pESP = createPage("ESP", 1); local pMove = createPage("Movimiento", 2); local pCombat = createPage("Combate", 3)
local pPerf = createPage("Rendimiento", 4); local pAjustes = createPage("Ajustes", 5); local pMisc = createPage("Misc", 6)

local function cardFrame(page)
    local card = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = CARD_T, BorderSizePixel = 0 }, page)
    bind(card, "BackgroundColor3", "Row"); corner(card, 10); stroke(card, "Stroke")
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, card)
    return card
end

local function card(page, title)
    local c = cardFrame(page)
    local t = new("TextLabel", { LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(title) }, c)
    bind(t, "TextColor3", "Accent")
    return c
end

local function switchRow(parent, text, get, set, onChange, bold)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    bind(row, "BackgroundColor3", "Accent"); corner(row, 6)
    local label = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -60, 1, 0), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = bold and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = bold and 0 or 0.12, Text = text, TextTruncate = Enum.TextTruncate.AtEnd }, row)
    bind(label, "TextColor3", "Text")
    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0 }, row)
    track.BackgroundColor3 = C.Off; corner(track, 99)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track)
    corner(knob, 99)
    local click = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2, AutoButtonColor = false }, row)
    local function refresh()
        local on = get() and true or false
        tween(track, 0.2, { BackgroundColor3 = on and C.On or C.Off })
        tween(knob, 0.25, { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
        if onChange then onChange(on) end
    end
    click.MouseEnter:Connect(function() tween(row, 0.15, { BackgroundTransparency = 0.9 }) end)
    click.MouseLeave:Connect(function() tween(row, 0.15, { BackgroundTransparency = 1 }) end)
    click.Activated:Connect(function() set(not get()); refresh() end); refresh(); table.insert(refreshers, refresh); return row
end

local function group(page, title, get, set)
    local c = cardFrame(page)
    local sub = new("Frame", { LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, c)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sub)
    local g = { sub = sub, hasSubs = false }
    local head = switchRow(c, title, get, set, function(on) sub.Visible = on and g.hasSubs end, true)
    head.LayoutOrder = 0
    function g:toggle(text, getV, setV) g.hasSubs = true; switchRow(sub, text, getV, setV); sub.Visible = get() and true or false end
    return g
end

local function soon(parent, text)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    bind(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, row), "TextColor3", "Dim")
    local tag = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 20), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10, Text = "Próximamente" }, row)
    bind(tag, "BackgroundColor3", "Off"); bind(tag, "TextColor3", "Dim"); corner(tag, 6)
end

-- CONTENIDO: ESP
do
    local g = group(pESP, "ESP", function() return Config.Enabled end, function(v) Config.Enabled = v end)
    if CurrentGameFolder == "BloxFruits" then
        g:toggle("Mostrar compañeros", function() return Config.ShowTeammates end, function(v) Config.ShowTeammates = v end)
    end
end

-- CONTENIDO: COMBATE
do
    if CurrentGameFolder == "ElementalMagicArena" then
        if CombatConfig then
            local g = group(pCombat, "Auto Combat", function() return CombatConfig.Enabled end, function(v) CombatConfig.Enabled = v end)
            g:toggle("Auto M1 (Clics)", function() return CombatConfig.AutoM1 end, function(v) CombatConfig.AutoM1 = v end)
            g:toggle("Auto Skills (Z-X-C-V)", function() return CombatConfig.AutoSkills end, function(v) CombatConfig.AutoSkills = v end)
        else
            local combatCard = card(pCombat, "Auto Combat")
            soon(combatCard, "AutoCombat.lua no cargado")
        end

        HitboxConfig.Size = 35
        local g = group(pCombat, "Hitbox Expander (Cuerpo Entero)",
            function() return HitboxConfig.Enabled end,
            function(v) HitboxConfig.Enabled = v; if v then HitboxConfig.Size = 35 end end)
        g:toggle("Ignorar amigos", function() return HitboxConfig.IgnoreFriends ~= false end, function(v) HitboxConfig.IgnoreFriends = v end)
    end
end

selectTab("ESP", true)
applyPanelStyle()

-- Arrastre básico
local function makeDraggable(handle, getPos, setPos)
    local active, startMouse, startPos, moved
    table.insert(connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = input; startMouse = input.Position; startPos = getPos(); moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then active = nil; conn:Disconnect() end
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
makeDraggable(header, function() return Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset) end, function(x, y) frame.Position = UDim2.fromOffset(x, y) end)

closeBtn.Activated:Connect(function()
    tween(panelScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(PanelConfig.Animations and 0.22 or 0, cleanup)
end)

task.wait(0.3); loading:Destroy()
frame.Visible = true; tween(panelScale, 0.35, { Scale = PanelConfig.Scale }, Enum.EasingStyle.Back)
print("[Froggy Hub] Panel " .. HUB_VERSION .. " cargado con éxito para: " .. GameDisplayName)

-- 🐸 MENSAJE ENVIADO POR EL PERSONAJE
local function sendPlayerChat()
    local msg = "FroggyHub On Top! Hecho por Froggy / kinnnnj8"
    task.spawn(function()
        task.wait(2)
        local sent = false
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channels = TextChatService:FindFirstChild("TextChannels")
                local general = channels and channels:FindFirstChild("RBXGeneral")
                if general then general:SendAsync(msg) sent = true end
            end
        end)
        if not sent then pcall(function() StarterGui:SetCore("ChatSendMessage", msg) end) end
    end)
end
sendPlayerChat()
