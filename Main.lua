--// Main.lua - Froggy Hub (loader + panel) | UI v11.4: Starship + Lockfile + Anti-Override

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"

local env = (getgenv and getgenv()) or _G

-- 🛑 SISTEMA DE BLOQUEO (LOCKFILE)
local LOCK_FILE = "FroggyHub.lock"
if type(isfile) == "function" and type(readfile) == "function" and isfile(LOCK_FILE) then
    local lock_time = tonumber(readfile(LOCK_FILE)) or 0
    local now = os.time()
    -- Si el bloqueo tiene menos de 5 segundos, significa que ya hay un script ejecutándose
    if now - lock_time < 5 then
        warn("[Froggy] ⚠️ Ya hay una instancia de Froggy Hub ejecutándose. Abortando duplicado.")
        return
    end
end
-- Crear el bloqueo
if type(writefile) == "function" then pcall(writefile, LOCK_FILE, tostring(os.time())) end

-- 💥 BORRADOR NUCLEAR
local function destroyAllHubs()
    local places = {
        game:GetService("CoreGui"),
        game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"),
        (gethui and gethui()) or game:GetService("CoreGui")
    }
    for _, parent in pairs(places) do
        if parent then
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("ScreenGui") and (obj.Name == "FroggyHub_Main" or obj.Name:match("^FroggyHub_")) then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
end
destroyAllHubs()

-- 🛡️ ANTÍDOTO CONTRA SCRIPTS VIEJOS (Vigilante en segundo plano)
task.spawn(function()
    while true do
        task.wait(1.0)
        local places = {
            game:GetService("CoreGui"),
            game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"),
            (gethui and gethui()) or game:GetService("CoreGui")
        }
        for _, parent in pairs(places) do
            if parent then
                for _, obj in ipairs(parent:GetChildren()) do
                    -- Si encuentra un FroggyHub que NO sea el de esta versión, lo mata
                    if obj:IsA("ScreenGui") and obj.Name:match("^FroggyHub_") and obj.Name ~= "FroggyHub_v11.4" then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end
end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- TEMAS
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

local MAX_P = 40
local PanelConfig = {
    Mode = (type(Saved.Mode) == "string") and Saved.Mode or "Normal",
    Scale = math.clamp(tonumber(Saved.Scale) or 1, 0.65, 1.4),
    Transparency = math.clamp(tonumber(Saved.Transparency) or 0, 0, 0.85),
    AnimBg = Saved.AnimBg ~= false,
    Particles = math.clamp(math.floor(tonumber(Saved.Particles) or 22), 0, MAX_P),
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

local function corner(o, r) return nil end

local function stroke(o, key, thickness)
    local s = Instance.new("UIStroke"); s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Miter; s.Parent = o
    bind(s, "Color", key or "Stroke"); return s
end
local function accentSeq() return ColorSequence.new(C.Accent, C.Accent2) end
local function glowSeq() return ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Accent), ColorSequenceKeypoint.new(0.5, C.Bg), ColorSequenceKeypoint.new(1, C.Accent2) }) end
local function lineSeq()
    local hi = C.Accent:Lerp(Color3.new(1, 1, 1), 0.6)
    return ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Accent2), ColorSequenceKeypoint.new(0.5, hi), ColorSequenceKeypoint.new(1, C.Accent2) })
end
local function borderSeq()
    return ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Accent), ColorSequenceKeypoint.new(0.3, C.Stroke), ColorSequenceKeypoint.new(0.7, C.Stroke), ColorSequenceKeypoint.new(1, C.Accent2) })
end
local function addGradient(parent, fn, rotation)
    local g = Instance.new("UIGradient"); g.Color = fn(); g.Rotation = rotation or 0; g.Parent = parent
    table.insert(gradients, { g = g, fn = fn }); return g
end

local ALL_CORNERS = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }
local function brackets(parent, key, len, th, inset, corners, z)
    inset = inset or 0
    for _, c in ipairs(corners or ALL_CORNERS) do
        local ax, ay = c[1], c[2]
        local px = (ax == 0) and inset or -inset
        local py = (ay == 0) and inset or -inset
        for _, size in ipairs({ Vector2.new(len, th), Vector2.new(th, len) }) do
            local f = new("Frame", { AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, px, ay, py), Size = UDim2.fromOffset(size.X, size.Y), BorderSizePixel = 0, ZIndex = z or 5 }, parent)
            bind(f, "BackgroundColor3", key or "Accent")
        end
    end
end

local function makeParticle(parent, i, w, h)
    local streak = (i % 5 == 0)
    local s = math.random(3, 6)
    local f = new("Frame", {
        Size = streak and UDim2.fromOffset(math.random(16, 34), 1) or UDim2.fromOffset(s, s),
        Rotation = streak and 0 or 45, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 0,
    }, parent)
    bind(f, "BackgroundColor3", (i % 2 == 0) and "Accent" or "Accent2")
    if streak then
        local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new(0, 1); g.Parent = f
    end
    return { f = f, streak = streak, x = math.random() * w, y = math.random() * h, sp = 8 + math.random() * 22, dr = 6 + math.random() * 14, ph = math.random() * 6.28 }
end
local function stepParticle(p, dt, t, w, h)
    if p.streak then
        p.x = p.x - p.sp * dt * 7
        if p.x < -40 then p.x = w + 40; p.y = math.random() * h end
        p.f.Position = UDim2.fromOffset(p.x, p.y)
    else
        p.y = p.y - p.sp * dt
        if p.y < -10 then p.y = h + 10; p.x = math.random() * w end
        p.f.Position = UDim2.fromOffset(p.x + math.sin(t * 0.8 + p.ph) * p.dr, p.y)
        p.f.BackgroundTransparency = 0.45 + 0.35 * (0.5 + 0.5 * math.sin(t * 2.2 + p.ph))
    end
end

local function makeScan(parent, height, z)
    local scan = new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z or 0, Visible = false }, parent)
    local band = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = z or 0 }, scan)
    bind(band, "BackgroundColor3", "Accent")
    local bg = Instance.new("UIGradient"); bg.Rotation = 90; bg.Transparency = NumberSequence.new(1, 0.86); bg.Parent = band
    local line = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = z or 0 }, scan)
    bind(line, "BackgroundColor3", "Accent")
    local lg = Instance.new("UIGradient"); lg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }); lg.Parent = line
    return scan
end

local function getParent()
    if gethui then local ok, ui = pcall(gethui); if ok and typeof(ui) == "Instance" then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- 🛠️ NOMBRE ESPECÍFICO DE LA VERSIÓN PARA QUE EL ANTÍDOTO LO RECONOZCA
local gui = new("ScreenGui", { Name = "FroggyHub_v11.4", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, getParent())
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
    if env.__BF_CHAT_CLEANUP then pcall(env.__BF_CHAT_CLEANUP) end
    if env.__BF_GOD_CLEANUP then pcall(env.__BF_GOD_CLEANUP) end

    if type(delfile) == "function" then pcall(delfile, LOCK_FILE) end

    if gui then gui:Destroy() end
    env.__BF_PANEL_CLEANUP = nil
end
env.__BF_PANEL_CLEANUP = cleanup

-- ==========================================
-- 🚀 FUNCIÓN DE INICIO
-- ==========================================
local function StartHub(CurrentGameFolder, GameDisplayName)
    local ROOT_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)
    local BASE_URL = ROOT_URL
    if CurrentGameFolder == "ElementalMagicArena" then BASE_URL = ROOT_URL .. "ElementalMagicArena/" end

    local HUB_NAME = "Froggy Hub | " .. GameDisplayName
    local HUB_VERSION = "v11.4"
    
    local GAME_FILE = "FroggyHub_game.txt"
    if type(writefile) == "function" then pcall(function() writefile(GAME_FILE, CurrentGameFolder) end) end

    -- PANTALLA DE CARGA
    local LW, LH = 300, 262
    local loading = new("Frame", { Size = UDim2.fromOffset(LW, LH), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 998 }, gui)
    bind(loading, "BackgroundColor3", "Bg")
    local loadStroke = stroke(loading, "Accent", 2)
    brackets(loading, "Accent", 16, 2, 4, nil, 6)
    local loadScale = Instance.new("UIScale", loading); loadScale.Scale = 0.6
    tween(loadScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
    local loadPulse = TweenService:Create(loadStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.75 })
    loadPulse:Play(); table.insert(tweens, loadPulse)

    local loadStars = {}
    for i = 1, 22 do loadStars[i] = makeParticle(loading, i, LW, LH) end
    local loadScan = makeScan(loading, 30, 1); loadScan.Visible = true

    local function ring(size, key, th, tr)
        local r = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, loading)
        local s = stroke(r, key, th); s.Transparency = tr; return r
    end
    local ring1 = ring(96, "Accent", 2, 0.35)
    local ring2 = ring(80, "Accent2", 2, 0.25)
    local ring3 = ring(64, "Accent", 1, 0.5)

    local loadFallback = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(50, 50), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 34, TextColor3 = Color3.new(1, 1, 1), Text = "F", ZIndex = 4 }, loading)
    addGradient(loadFallback, accentSeq, 90)
    local loadLogo = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1, ZIndex = 5 }, loading)

    local loadTitle = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBlack, TextSize = 19, TextColor3 = Color3.new(1, 1, 1), Text = "F R O G G Y   H U B", ZIndex = 4 }, loading)
    pcall(addGradient, loadTitle, accentSeq, 0)
    local loadGame = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 174), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham, TextSize = 11, Text = "DESTINO: " .. string.upper(GameDisplayName), ZIndex = 4 }, loading)
    bind(loadGame, "TextColor3", "Text")
    local loadStatus = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 194), Size = UDim2.new(1, -40, 0, 16), Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = "> iniciando_", ZIndex = 4 }, loading)
    bind(loadStatus, "TextColor3", "Dim")

    local LOAD_BLOCKS = 20
    local barTrack = new("Frame", { Position = UDim2.fromOffset(20, 220), Size = UDim2.new(1, -40, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }, loading)
    local loadBlocks = {}
    for i = 1, LOAD_BLOCKS do
        local b = new("Frame", { Position = UDim2.new((i - 1) / LOAD_BLOCKS, 0, 0, 0), Size = UDim2.new(1 / LOAD_BLOCKS, -2, 1, 0), BorderSizePixel = 0, ZIndex = 4 }, barTrack)
        bind(b, "BackgroundColor3", "Off"); loadBlocks[i] = b
    end
    local loadPct = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 236), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 11, Text = "0%", ZIndex = 4 }, loading)
    bind(loadPct, "TextColor3", "Accent")

    local shownPct, targetPct, prevBlocks, statusToken = 0, 0, 0, 0
    local function typeStatus(text)
        statusToken = statusToken + 1
        local my = statusToken
        task.spawn(function()
            for i = 1, #text do
                if my ~= statusToken or not loadStatus.Parent then return end
                loadStatus.Text = "> " .. text:sub(1, i) .. "_"
                task.wait(0.012)
            end
            if my == statusToken and loadStatus.Parent then loadStatus.Text = "> " .. text end
        end)
    end
    local function setProgress(fraction, text)
        targetPct = math.clamp(fraction, 0, 1) * 100
        local n = math.floor(math.clamp(fraction, 0, 1) * LOAD_BLOCKS + 0.5)
        for i = prevBlocks + 1, n do
            task.delay((i - prevBlocks) * 0.03, function()
                local b = loadBlocks[i]
                if b and b.Parent then
                    b.BackgroundColor3 = Color3.new(1, 1, 1)
                    tween(b, 0.3, { BackgroundColor3 = C.Accent })
                end
            end)
        end
        if n > prevBlocks then prevBlocks = n end
        if text then typeStatus(text) end
    end

    local lt0 = os.clock()
    local loadConn
    loadConn = RunService.Heartbeat:Connect(function(dt)
        local t = os.clock() - lt0
        ring1.Rotation = (t * 70) % 360
        ring2.Rotation = 360 - ((t * 45) % 360)
        ring3.Rotation = 45 + math.sin(t * 2) * 10
        loadScan.Position = UDim2.fromOffset(0, -30 + ((t % 2.2) / 2.2) * (LH + 30))
        for _, p in ipairs(loadStars) do stepParticle(p, dt, t, LW, LH) end
        shownPct = shownPct + (targetPct - shownPct) * math.min(1, dt * 8)
        loadPct.Text = string.format("%d%%", math.floor(shownPct + 0.5))
    end)
    table.insert(connections, loadConn)

    local ESP_FILES = { "Esp.lua" }; local ELEM_ESP_FILES = { "EspElemental.lua" }
    local MOVE_FILES = { "Movement.lua" }; local CAM_FILES = { "Camlock.lua" }
    local DODGE_FILES = { "AutoDodge.lua" }; local SA_FILES = { "SilentAim.lua" }
    local POT_FILES = { "Potato.lua" }; local TP_FILES = { "Teleport.lua" }
    local LIFT_FILES = { "AutoLift.lua" }; local DIAMOND_FILES = { "AutoDiamonds.lua" }
    local AFARM_FILES = { "AutoFarmPlayers.lua" }; local HITBOX_FILES = { "HitboxExpander.lua" }
    local COMBAT_FILES = { "AutoCombat.lua" }; local GODMODE_FILES = { "GodMode.lua" }
    local CHAT_FILES = { "ChatMessage.lua" }; local LOGO_FILES = { "logo.png" }

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
            if BASE_URL ~= ROOT_URL then
                local okRoot, resRoot = pcall(function() return game:HttpGet(ROOT_URL .. name .. "?v=" .. os.time(), true) end)
                if okRoot and type(resRoot) == "string" and #resRoot > 0 and resRoot:sub(1, 3) ~= "404" then return resRoot end
            end
        end
        return nil
    end

    local function loadOptional(names, label, configKey)
        local src = downloadModule(names)
        if not src then return nil end
        local chunk = loadstring(src)
        if type(chunk) ~= "function" then return nil end
        local ok = pcall(chunk)
        if not ok then return nil end
        return env[configKey] or _G[configKey]
    end

    task.spawn(function()
        setProgress(0.1, "Cargando logo...")
        local logoAsset = fetchLogo()
        if logoAsset then
            loadLogo.Image = logoAsset; loadFallback.Visible = false
            tween(loadLogo, 0.3, { ImageTransparency = 0 })
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

        setProgress(0.45, "Modulos de movimiento...")
        local MoveConfig = loadOptional(MOVE_FILES, "Movement.lua", "BF_MOVE_CONFIG")
        local CamConfig = loadOptional(CAM_FILES, "Camlock.lua", "BF_CAM_CONFIG")
        local DodgeConfig = loadOptional(DODGE_FILES, "AutoDodge.lua", "BF_DODGE_CONFIG")

        setProgress(0.62, "Sistemas de combate...")
        local DiamondConfig, AFarmConfig, HitboxConfig, CombatConfig, GodConfig = nil, nil, nil, nil, nil
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
            GodConfig = loadOptional(GODMODE_FILES, "GodMode.lua", "BF_GODMODE_CONFIG")
        end

        local SAConfig = nil
        if CurrentGameFolder == "ElementalMagicArena" or CurrentGameFolder == "Universal" then
            SAConfig = loadOptional(SA_FILES, "SilentAim.lua", "BF_SA_CONFIG")
        end

        setProgress(0.82, "Utilidades extra...")
        local TpConfig = loadOptional(TP_FILES, "Teleport.lua", "BF_TP_CONFIG")
        local LiftConfig = loadOptional(LIFT_FILES, "AutoLift.lua", "BF_LIFT_CONFIG")
        local PotConfig = loadOptional(POT_FILES, "Potato.lua", "BF_POTATO")

        loadOptional(CHAT_FILES, "ChatMessage.lua", "BF_CHAT_CONFIG")

        setProgress(1, "Sistemas en linea. Listo")
        task.wait(0.7)

        -- ==========================================
        -- 🛸 PANEL PRINCIPAL (Se construye DESPUÉS de descargar)
        -- ==========================================
        local function screenSize() local sz = gui.AbsoluteSize; if sz.X < 50 then local cam = workspace.CurrentCamera; sz = cam and cam.ViewportSize or Vector2.new(800, 600) end; return sz end
        local S0 = screenSize()
        local WIDTH = math.min(540, S0.X - 24); local HEIGHT = math.min(340, S0.Y - 20)
        local HEADER_H = 46; local SIDE_W = 118
        local HEADER_T, CARD_T = 0.3, 0.2

        local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromOffset(math.floor((S0.X - WIDTH) / 2), math.floor((S0.Y - HEIGHT) / 2)), BorderSizePixel = 0, ClipsDescendants = true, Active = true, Visible = false }, gui)
        bind(frame, "BackgroundColor3", "Bg")
        local frameStroke = Instance.new("UIStroke")
        frameStroke.Thickness = 2; frameStroke.Color = Color3.new(1, 1, 1); frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        frameStroke.LineJoinMode = Enum.LineJoinMode.Miter; frameStroke.Parent = frame
        local borderGrad = addGradient(frameStroke, borderSeq, 0)
        local panelScale = Instance.new("UIScale", frame); panelScale.Scale = 0.8

        local bgLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 0 }, frame)
        local glow = new("Frame", { Size = UDim2.fromScale(1.6, 1.6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 0 }, bgLayer)
        local glowGrad = addGradient(glow, glowSeq, 0)

        local function makeOrb(key)
            local o = new("Frame", { Size = UDim2.fromOffset(170, 170), BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 0 }, bgLayer)
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = o
            bind(o, "BackgroundColor3", key); return o
        end
        local orb1, orb2 = makeOrb("Accent"), makeOrb("Accent2")

        local particles = {}
        for i = 1, MAX_P do particles[i] = makeParticle(bgLayer, i, WIDTH, HEIGHT) end
        local scan = makeScan(bgLayer, 28, 0)

        local function updateBgVisibility()
            local on = PanelConfig.AnimBg
            orb1.Visible = on; orb2.Visible = on
            if not on then scan.Visible = false end
            for i, p in ipairs(particles) do p.f.Visible = on and i <= PanelConfig.Particles end
        end
        updateBgVisibility()

        brackets(frame, "Accent", 14, 2, 3, nil, 6)

        local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = HEADER_T, BorderSizePixel = 0, Active = true }, frame)
        bind(header, "BackgroundColor3", "Header")
        local titleX = 14
        local headerLogo
        if logoAsset then headerLogo = new("ImageLabel", { Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset }, header); titleX = 50 end
        bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 5), Size = UDim2.new(1, -(titleX + 90), 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = HUB_NAME }, header), "TextColor3", "Text")
        local subtitle = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 26), Size = UDim2.new(1, -(titleX + 90), 0, 14), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Text = "PANEL DE CONTROL // NAV-SYS" }, header)
        addGradient(subtitle, accentSeq, 0)
        bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -120, 0.5, -7), Size = UDim2.fromOffset(40, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Text = HUB_VERSION }, header), "TextColor3", "Dim")

        for i = 1, 3 do
            local s = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -158 + i * 7, 0.5, 0), Size = UDim2.fromOffset(3, 16), Rotation = 25, BorderSizePixel = 0, BackgroundTransparency = 0.7 - i * 0.2 }, header)
            bind(s, "BackgroundColor3", "Accent")
        end
        local led = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -176, 0.5, 0), Size = UDim2.fromOffset(7, 7), Rotation = 45, BorderSizePixel = 0 }, header)
        bind(led, "BackgroundColor3", "Accent")

        local function headerButton(text, xOffset, hoverKey)
            local b = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOffset, 0.5, -15), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, Text = text, AutoButtonColor = false }, header)
            bind(b, "BackgroundColor3", "Row"); bind(b, "TextColor3", "Text"); stroke(b, "Stroke", 1)
            local bs = Instance.new("UIScale", b)
            b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = hoverKey == "Danger" and C.Danger or C.Stroke }); tween(bs, 0.12, { Scale = 1.1 }) end)
            b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Row }); tween(bs, 0.12, { Scale = 1 }) end)
            b.MouseButton1Down:Connect(function() tween(bs, 0.08, { Scale = 0.9 }) end)
            return b
        end
        local closeBtn = headerButton("X", -40, "Danger"); local minBtn = headerButton("-", -76)

        local tabBar = new("ScrollingFrame", { Position = UDim2.fromOffset(0, HEADER_H + 2), Size = UDim2.new(0, SIDE_W, 1, -(HEADER_H + 2)), BackgroundTransparency = HEADER_T, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, frame)
        bind(tabBar, "BackgroundColor3", "Header")
        new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, tabBar)
        local sideDivider = new("Frame", { Position = UDim2.new(0, SIDE_W, 0, HEADER_H + 2), Size = UDim2.new(0, 1, 1, -(HEADER_H + 2)), BorderSizePixel = 0 }, frame)
        bind(sideDivider, "BackgroundColor3", "Stroke")

        local accentLine = new("Frame", { Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, frame)
        local lineGrad = addGradient(accentLine, lineSeq, 0)

        local BODY_Y = HEADER_H + 2; local pages, tabButtons, tabIndicators = {}, {}, {}; local order = 0
        local function nextOrder() order = order + 1 return order end
        local currentTab = nil

        local function selectTab(name, instant)
            currentTab = name
            for n, page in pairs(pages) do
                local on = (n == name)
                page.Visible = on
                tween(tabButtons[n], 0.2, { BackgroundColor3 = on and C.Accent or C.Row, TextColor3 = on and C.AccentText or C.Dim })
                tween(tabIndicators[n], 0.25, { BackgroundTransparency = on and 0 or 1, Rotation = on and 135 or 45 }, Enum.EasingStyle.Back)
                if on and not instant then
                    page.Position = UDim2.fromOffset(SIDE_W + 26, BODY_Y + 8)
                    tween(page, 0.3, { Position = UDim2.fromOffset(SIDE_W + 8, BODY_Y + 8) }, Enum.EasingStyle.Back)
                    local i = 0
                    for _, ch in ipairs(page:GetChildren()) do
                        if ch:IsA("Frame") then
                            i = i + 1; ch.BackgroundTransparency = 1
                            task.delay(0.05 * i, function() if ch.Parent then tween(ch, 0.35, { BackgroundTransparency = CARD_T }) end end)
                        end
                    end
                end
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
            stroke(b, "Stroke", 1)
            new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 8) }, b)
            local ind = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(7, 7), Rotation = 45, BorderSizePixel = 0, BackgroundTransparency = 1, BackgroundColor3 = C.AccentText }, b)
            tabIndicators[name] = ind
            b.Activated:Connect(function() if currentTab ~= name then selectTab(name) end end)
            b.MouseEnter:Connect(function() if currentTab ~= name then tween(b, 0.12, { BackgroundColor3 = C.Stroke, TextColor3 = C.Text }) end end)
            b.MouseLeave:Connect(function() if currentTab ~= name then tween(b, 0.12, { BackgroundColor3 = C.Row, TextColor3 = C.Dim }) end end)
            tabButtons[name] = b; return page
        end

        local pESP = createPage("ESP", 1); local pMove = createPage("Movimiento", 2); local pCombat = createPage("Combate", 3)
        local pPerf = createPage("Rendimiento", 4); local pAjustes = createPage("Ajustes", 5); local pMisc = createPage("Misc", 6)

        local function cardFrame(page)
            local outer = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = CARD_T, BorderSizePixel = 0 }, page)
            bind(outer, "BackgroundColor3", "Row"); stroke(outer, "Stroke")
            local c = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0 }, outer)
            new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, c)
            new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, c)
            brackets(outer, "Accent", 8, 2, 0, { { 0, 0 }, { 1, 1 } })
            return c
        end

        local function card(page, title)
            local c = cardFrame(page)
            local row = new("Frame", { LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), BorderSizePixel = 0 }, c)
            local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(6, 6), Rotation = 45, BorderSizePixel = 0 }, row)
            bind(d, "BackgroundColor3", "Accent")
            local t = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(title) }, row)
            bind(t, "TextColor3", "Accent")
            return c
        end

        local function switchRow(parent, text, get, set, onChange, bold)
            local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
            bind(row, "BackgroundColor3", "Accent")
            local label = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -60, 1, 0), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = bold and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = bold and 0 or 0.12, Text = text, TextTruncate = Enum.TextTruncate.AtEnd }, row)
            bind(label, "TextColor3", "Text")
            local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0 }, row)
            track.BackgroundColor3 = C.Off; stroke(track, "Stroke", 1)
            local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track)
            local click = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2, AutoButtonColor = false }, row)
            local function refresh()
                local on = get() and true or false
                tween(track, 0.2, { BackgroundColor3 = on and C.On or C.Off })
                tween(knob, 0.25, { Position = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0), Rotation = on and 135 or 45 }, Enum.EasingStyle.Back)
                if onChange then onChange(on) end
            end
            click.MouseEnter:Connect(function() tween(row, 0.15, { BackgroundTransparency = 0.9 }) end)
            click.MouseLeave:Connect(function() tween(row, 0.15, { BackgroundTransparency = 1 }) end)
            click.Activated:Connect(function() set(not get()); refresh() end); refresh(); table.insert(refreshers, refresh); return row
        end

        local function slider(parent, text, get, set, minV, maxV, stepV)
            local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
            bind(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextTruncate = Enum.TextTruncate.AtEnd }, row), "TextColor3", "Dim")
            local valueLabel = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(56, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, row)
            bind(valueLabel, "TextColor3", "Accent")
            local hit = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Active = true, ZIndex = 2 }, row)
            local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 4), BorderSizePixel = 0 }, hit)
            bind(track, "BackgroundColor3", "Off")
            local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track); addGradient(fill, accentSeq, 0)
            local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track); stroke(knob, "Accent", 2)
            local knobScale = Instance.new("UIScale", knob)
            local function refresh() local v = get() or minV; local rel = math.clamp((v - minV) / (maxV - minV), 0, 1); tween(fill, 0.08, { Size = UDim2.fromScale(rel, 1) }); tween(knob, 0.08, { Position = UDim2.new(rel, 0, 0.5, 0) }); valueLabel.Text = tostring(v) end
            local function setFromX(x) local width = math.max(1, track.AbsoluteSize.X); local rel = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1); local v = minV + rel * (maxV - minV); v = math.floor(v / stepV + 0.5) * stepV; v = math.clamp(math.floor(v * 100 + 0.5) / 100, minV, maxV); set(v); refresh() end
            local activeInput = nil
            table.insert(connections, hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activeInput = input; tween(knobScale, 0.12, { Scale = 1.3 }, Enum.EasingStyle.Back); setFromX(input.Position.X)
                    local conn; conn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            if activeInput == input then activeInput = nil; tween(knobScale, 0.12, { Scale = 1 }) end
                            conn:Disconnect()
                        end
                    end)
                end
            end))
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
            bind(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, row), "TextColor3", "Dim")
            local tag = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 20), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10, Text = "Próximamente" }, row)
            bind(tag, "BackgroundColor3", "Off"); bind(tag, "TextColor3", "Dim"); stroke(tag, "Stroke", 1)
        end

        local function actionButton(parent, text, onClick, danger)
            local b = new("TextButton", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, Text = text, AutoButtonColor = false }, parent)
            if danger then b.BackgroundColor3 = C.Danger else bind(b, "BackgroundColor3", "Stroke") end
            bind(b, "TextColor3", "Text")
            local st = stroke(b, "Accent", 1); st.Transparency = 0.6
            local bs = Instance.new("UIScale", b)
            b.MouseEnter:Connect(function() tween(bs, 0.12, { Scale = 1.03 }); tween(st, 0.12, { Transparency = 0 }) end)
            b.MouseLeave:Connect(function() tween(bs, 0.12, { Scale = 1 }); tween(st, 0.12, { Transparency = 0.6 }) end)
            b.MouseButton1Down:Connect(function() tween(bs, 0.08, { Scale = 0.96 }) end)
            b.MouseButton1Up:Connect(function() tween(bs, 0.12, { Scale = 1.03 }, Enum.EasingStyle.Back) end)
            b.Activated:Connect(onClick)
            return b
        end

        local function infoRow(parent, left, right)
            local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, parent)
            bind(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = left }, row), "TextColor3", "Dim")
            bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = right }, row), "TextColor3", "Text")
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
        end

        -- CONTENIDO: MOVIMIENTO
        if MoveConfig then
            local s = group(pMove, "Speed", function() return MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end)
            s:slider("Velocidad extra", function() return MoveConfig.Speed end, function(v) MoveConfig.Speed = v end, 5, 200, 5)
            local j = group(pMove, "Super Jump", function() return MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end)
            j:slider("Fuerza de salto", function() return MoveConfig.JumpPower end, function(v) MoveConfig.JumpPower = v end, 50, 300, 10)
        end
        if TpConfig then
            local t = group(pMove, "Teleport (botón TP)", function() return TpConfig.Enabled end, function(v) TpConfig.Enabled = v end)
            t:slider("Cooldown (seg)", function() return TpConfig.Cooldown end, function(v) TpConfig.Cooldown = v end, 1, 60, 1)
        end

        -- CONTENIDO: COMBATE
        do
            if CurrentGameFolder == "ElementalMagicArena" then
                if CombatConfig then
                    local g = group(pCombat, "Auto Combat", function() return CombatConfig.Enabled end, function(v) CombatConfig.Enabled = v end)
                    g:toggle("Auto M1 (Clics)", function() return CombatConfig.AutoM1 end, function(v) CombatConfig.AutoM1 = v end)
                    g:slider("Velocidad de M1", function() return CombatConfig.M1Delay end, function(v) CombatConfig.M1Delay = v end, 0.1, 0.5, 0.01)
                    g:toggle("Auto Skills (Z-X-C-V)", function() return CombatConfig.AutoSkills end, function(v) CombatConfig.AutoSkills = v end)
                    g:slider("Delay de Skills", function() return CombatConfig.SkillDelay end, function(v) CombatConfig.SkillDelay = v end, 0.5, 5.0, 0.1)
                else
                    local combatCard = card(pCombat, "Auto Combat")
                    soon(combatCard, "AutoCombat.lua no cargado")
                end

                if HitboxLoadFailed then
                    local warnCard = card(pCombat, "⚠️ Hitbox Expander no cargado")
                    bind(new("TextLabel", {
                        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 40),
                        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                        Text = "El módulo HitboxExpander.lua falló al ejecutar. Abrí la consola (F9) para ver el error exacto. Los controles NO harán nada hasta que se arregle.",
                    }, warnCard), "TextColor3", "Danger")
                end

                HitboxConfig.Size = 35
                local g = group(pCombat, "Hitbox Expander (Cuerpo Entero)",
                    function() return HitboxConfig.Enabled end,
                    function(v) HitboxConfig.Enabled = v; if v then HitboxConfig.Size = 35 end end)
                g:toggle("Ignorar amigos", function() return HitboxConfig.IgnoreFriends ~= false end, function(v) HitboxConfig.IgnoreFriends = v end)
                bind(new("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                    Text = "Tamaño fijo al máximo: 35 studs (Toda la hitbox)", TextColor3 = C.Dim
                }, g.sub), "TextColor3", "Dim")

                -- 🛠️ GOD MODE
                if GodConfig then
                    local gg = group(pCombat, "God Mode (Inmortal)",
                        function() return GodConfig.Enabled end,
                        function(v) GodConfig.Enabled = v end)
                    gg:toggle("Anti-Caída (Void)", function() return GodConfig.AntiVoid end, function(v) GodConfig.AntiVoid = v end)
                    gg:toggle("Bloqueo de Vida", function() return GodConfig.HealthLock end, function(v) GodConfig.HealthLock = v end)
                    gg:toggle("Ghost Mode (Hitbox 0)", function() return GodConfig.GhostMode end, function(v) GodConfig.GhostMode = v end)
                else
                    local godCard = card(pCombat, "God Mode")
                    soon(godCard, "GodMode.lua no cargado")
                end
            end
        end

        if CamConfig then
            local g = group(pCombat, "Camlock", function() return CamConfig.Enabled end, function(v) CamConfig.Enabled = v end)
            g:slider("Radio FOV", function() return CamConfig.FOV end, function(v) CamConfig.FOV = v end, 50, 600, 10)
            g:slider("Suavizado", function() return CamConfig.Smoothness end, function(v) CamConfig.Smoothness = v end, 0.05, 1, 0.05)
        end

        -- CONTENIDO: RENDIMIENTO
        if PotConfig then
            local g = group(pPerf, "Gráficos patata", function() return PotConfig.Enabled end, function(v) PotConfig.Set(v) end)
            g:toggle("Quitar partículas", function() return PotConfig.NoParticles end, function(v) PotConfig.NoParticles = v end)
            g:toggle("Quitar texturas", function() return PotConfig.NoTextures end, function(v) PotConfig.NoTextures = v end)
        end

        -- ESTILO DEL PANEL + CAMBIO DE TEMA
        local function applyPanelStyle()
            local scale = PanelConfig.Scale or 1; local trans = PanelConfig.Transparency or 0
            tween(panelScale, 0.2, { Scale = scale }); tween(frame, 0.25, { BackgroundTransparency = trans })
            tween(header, 0.25, { BackgroundTransparency = HEADER_T + (1 - HEADER_T) * trans })
            tween(tabBar, 0.25, { BackgroundTransparency = HEADER_T + (1 - HEADER_T) * trans })
            tween(glow, 0.25, { BackgroundTransparency = 0.85 + 0.15 * trans })
            task.defer(function()
                local sz = screenSize(); local scaledW = WIDTH * scale; local scaledH = HEIGHT * scale
                local x = math.clamp(frame.Position.X.Offset, 0, math.max(0, sz.X - scaledW)); local y = math.clamp(frame.Position.Y.Offset, 0, math.max(0, sz.Y - scaledH))
                frame.Position = UDim2.fromOffset(x, y)
            end)
        end

        local refreshThemeTiles = function() end
        local function applyTheme(theme)
            PanelConfig.Theme = theme.Name
            setPalette(theme)
            for _, b in ipairs(binds) do if b.o and b.o.Parent then tween(b.o, 0.35, { [b.p] = C[b.k] }) end end
            for _, g in ipairs(gradients) do pcall(function() g.g.Color = g.fn() end) end
            for _, r in ipairs(refreshers) do pcall(r) end
            if currentTab then selectTab(currentTab, true) end
            refreshThemeTiles(); saveSettings()
        end

        -- AJUSTES
        do
            local themeCard = card(pAjustes, "Temas de color")
            local grid = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, themeCard)
            new("UIGridLayout", { CellSize = UDim2.new(1 / 4, -6, 0, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal }, grid)
            local tiles = {}
            for i, t in ipairs(THEMES) do
                local tile = new("TextButton", { LayoutOrder = i, BackgroundColor3 = t.Bg, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, grid)
                local st = Instance.new("UIStroke"); st.Color = t.Accent; st.Thickness = 1; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.LineJoinMode = Enum.LineJoinMode.Miter; st.Parent = tile
                local sw = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, tile)
                local sg = Instance.new("UIGradient"); sg.Color = ColorSequence.new(t.Accent, t.Accent2); sg.Parent = sw
                new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -22), Size = UDim2.new(1, -16, 0, 16), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(235, 235, 240), Text = t.Name }, tile)
                local check = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(8, 8), Rotation = 45, BackgroundColor3 = t.Accent, BorderSizePixel = 0, Visible = false }, tile)
                local ts = Instance.new("UIScale", tile)
                tile.MouseEnter:Connect(function() tween(ts, 0.12, { Scale = 1.06 }, Enum.EasingStyle.Back) end)
                tile.MouseLeave:Connect(function() tween(ts, 0.12, { Scale = 1 }) end)
                tile.MouseButton1Down:Connect(function() tween(ts, 0.08, { Scale = 0.94 }) end)
                tile.Activated:Connect(function() tween(ts, 0.15, { Scale = 1.06 }, Enum.EasingStyle.Back); applyTheme(t) end)
                tiles[t.Name] = { stroke = st, check = check }
            end
            refreshThemeTiles = function()
                for name, tl in pairs(tiles) do
                    local sel = (PanelConfig.Theme == name)
                    tween(tl.stroke, 0.2, { Thickness = sel and 2.5 or 1 }); tl.check.Visible = sel
                end
            end
            refreshThemeTiles()

            local ap = card(pAjustes, "Apariencia del panel")
            local presetRow = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, ap)
            new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, presetRow)
            local presets = { { Name = "Discreto", Scale = 0.7, Trans = 0.5 }, { Name = "Normal", Scale = 1, Trans = 0 }, { Name = "Grande", Scale = 1.25, Trans = 0 } }
            local presetButtons = {}
            local function refreshPresets() for _, b in ipairs(presetButtons) do local active = (PanelConfig.Mode == b.data.Name); tween(b.btn, 0.15, { BackgroundColor3 = active and C.Accent or C.Row, TextColor3 = active and C.AccentText or C.Dim }) end end
            for i, p in ipairs(presets) do
                local btn = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1 / 3, -4, 1, 0), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, Text = p.Name, AutoButtonColor = false }, presetRow)
                btn.BackgroundColor3 = C.Row; btn.TextColor3 = C.Dim
                stroke(btn, "Stroke")
                table.insert(presetButtons, { btn = btn, data = p })
                btn.Activated:Connect(function() PanelConfig.Mode = p.Name; PanelConfig.Scale = p.Scale; PanelConfig.Transparency = p.Trans; applyPanelStyle(); refreshPresets(); for _, r in ipairs(refreshers) do r() end; saveSettings() end)
            end
            refreshPresets(); table.insert(refreshers, refreshPresets)
            slider(ap, "Escala del panel", function() return PanelConfig.Scale end, function(v) PanelConfig.Scale = v; PanelConfig.Mode = "Personalizado"; applyPanelStyle(); refreshPresets(); saveSettings() end, 0.65, 1.4, 0.05)
            slider(ap, "Transparencia", function() return PanelConfig.Transparency end, function(v) PanelConfig.Transparency = v; PanelConfig.Mode = "Personalizado"; applyPanelStyle(); refreshPresets(); saveSettings() end, 0, 0.85, 0.05)

            local fx = card(pAjustes, "Efectos y animaciones")
            switchRow(fx, "Fondo animado", function() return PanelConfig.AnimBg end, function(v) PanelConfig.AnimBg = v; updateBgVisibility(); saveSettings() end)
            slider(fx, "Cantidad de partículas", function() return PanelConfig.Particles end, function(v) PanelConfig.Particles = math.floor(v); updateBgVisibility(); saveSettings() end, 0, MAX_P, 2)
            switchRow(fx, "Animaciones de interfaz", function() return PanelConfig.Animations end, function(v) PanelConfig.Animations = v; saveSettings() end)

            local info = card(pAjustes, "Información")
            infoRow(info, "Versión", HUB_VERSION)
            infoRow(info, "Juego", GameDisplayName)
            infoRow(info, "Mostrar / ocultar", "Ctrl Der.")
            actionButton(info, "Restablecer ajustes", function()
                PanelConfig.Mode = "Normal"; PanelConfig.Scale = 1; PanelConfig.Transparency = 0
                PanelConfig.AnimBg = true; PanelConfig.Particles = 22; PanelConfig.Animations = true
                updateBgVisibility(); applyPanelStyle(); applyTheme(THEMES[1])
                for _, r in ipairs(refreshers) do pcall(r) end
            end, true)
            -- 🎮 Cambiar de juego
            actionButton(info, "Cambiar de juego (reiniciar)", function()
                if type(delfile) == "function" and type(isfile) == "function" then
                    pcall(function() if isfile(GAME_FILE) then delfile(GAME_FILE) end end)
                elseif type(writefile) == "function" then
                    pcall(writefile, GAME_FILE, "")
                end
                env.BF_SELECTED_GAME = nil
                _G.BF_SELECTED_GAME = nil
                tween(panelScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                task.delay(PanelConfig.Animations and 0.22 or 0, cleanup)
            end, false)
        end

        do
            local sc = card(pMisc, "Próximamente")
            for _, name in ipairs({ "Fly", "Noclip", "Fruit Finder", "Server Hop", "Anti-AFK" }) do soon(sc, name) end
            for _, name in ipairs(missing) do soon(sc, name .. " (módulo no cargado)") end
        end

        selectTab("ESP", true)
        applyPanelStyle()

        -- ARRASTRE, BURBUJA Y ATAJOS
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
        local bubble = new("TextButton", { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false, ZIndex = 2 }, gui)
        bind(bubble, "BackgroundColor3", "Header")
        local bubbleStroke = stroke(bubble, "Accent", 2)
        local bubbleScale = Instance.new("UIScale", bubble)
        local bubblePulse = TweenService:Create(bubbleStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 4 })
        bubblePulse:Play(); table.insert(tweens, bubblePulse)
        local bubbleRing = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = 2 }, bubble)
        stroke(bubbleRing, "Accent2", 1.5)
        if logoAsset then new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset, Active = false, ZIndex = 3 }, bubble)
        else bind(new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 22, Text = "F", Active = false, ZIndex = 3 }, bubble), "TextColor3", "Accent") end
        bubble.MouseEnter:Connect(function() tween(bubbleScale, 0.12, { Scale = 1.12 }, Enum.EasingStyle.Back) end)
        bubble.MouseLeave:Connect(function() tween(bubbleScale, 0.12, { Scale = 1 }) end)

        local function setBubblePos(x, y) local sz = screenSize(); bubble.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, sz.X - BUBBLE)), math.clamp(y, 0, math.max(0, sz.Y - BUBBLE))) end
        local minimizing = false
        local function restorePanel()
            bubble.Visible = false; frame.Visible = true
            setPanelPos(bubble.Position.X.Offset - 8, bubble.Position.Y.Offset - 8)
            panelScale.Scale = 0.4; tween(panelScale, 0.3, { Scale = PanelConfig.Scale }, Enum.EasingStyle.Back)
        end
        local function minimizePanel()
            if minimizing or not frame.Visible then return end
            minimizing = true
            setBubblePos(frame.Position.X.Offset + 8, frame.Position.Y.Offset + 8)
            tween(panelScale, 0.18, { Scale = 0.4 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(PanelConfig.Animations and 0.18 or 0, function()
                frame.Visible = false; bubble.Visible = true
                bubbleScale.Scale = 0; tween(bubbleScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
                minimizing = false
            end)
        end

        makeDraggable(bubble, function() return Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset) end, setBubblePos, restorePanel)
        minBtn.Activated:Connect(minimizePanel)

        table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local sz = screenSize(); WIDTH = math.min(540, sz.X - 24); HEIGHT = math.min(340, sz.Y - 20)
            frame.Size = UDim2.fromOffset(WIDTH, HEIGHT); setPanelPos(frame.Position.X.Offset, frame.Position.Y.Offset); setBubblePos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
        end))

        table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.RightControl then if frame.Visible then minimizePanel() else restorePanel() end end
        end))
        closeBtn.Activated:Connect(function()
            tween(panelScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(PanelConfig.Animations and 0.22 or 0, cleanup)
        end)

        local t0 = os.clock()
        table.insert(connections, RunService.Heartbeat:Connect(function(dt)
            local t = os.clock() - t0
            if bubble.Visible then bubbleRing.Rotation = (t * 90) % 360 end
            if not frame.Visible or not PanelConfig.AnimBg then return end
            glowGrad.Rotation = (t * 14) % 360
            borderGrad.Rotation = (t * 55) % 360
            lineGrad.Offset = Vector2.new(math.sin(t * 1.4) * 0.5, 0)
            led.BackgroundTransparency = 0.5 - 0.5 * math.sin(t * 4)
            if headerLogo then headerLogo.Rotation = math.sin(t * 1.6) * 5 end
            local sp = (t % 6) / 4
            if sp <= 1 then scan.Visible = true; scan.Position = UDim2.fromOffset(0, -28 + sp * (HEIGHT + 28)) else scan.Visible = false end
            orb1.Position = UDim2.fromOffset(WIDTH * 0.15 + math.sin(t * 0.5) * 70 - 85, HEIGHT * 0.30 + math.cos(t * 0.4) * 70 - 85)
            orb2.Position = UDim2.fromOffset(WIDTH * 0.75 + math.cos(t * 0.45) * 60 - 85, HEIGHT * 0.70 + math.sin(t * 0.55) * 70 - 85)
            for i = 1, PanelConfig.Particles do
                local p = particles[i]
                if p then stepParticle(p, dt, t, WIDTH, HEIGHT) end
            end
        end))

        for _, t in ipairs(tweens) do if t ~= loadPulse and t ~= bubblePulse then pcall(function() t:Cancel() end) end end
        pcall(function() loadPulse:Cancel() end)
        local hide = TweenService:Create(loadScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
        hide:Play(); task.wait(0.3)
        pcall(function() loadConn:Disconnect() end)
        loading:Destroy()

        -- 🚀 Secuencia de arranque del panel
        frame.Visible = true
        tween(panelScale, 0.4, { Scale = PanelConfig.Scale }, Enum.EasingStyle.Back)
        if PanelConfig.Animations then
            header.Position = UDim2.fromOffset(0, -HEADER_H)
            tabBar.Position = UDim2.fromOffset(-SIDE_W, HEADER_H + 2)
            accentLine.Size = UDim2.new(0, 0, 0, 2)
            tween(header, 0.45, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
            task.delay(0.12, function() tween(tabBar, 0.45, { Position = UDim2.fromOffset(0, HEADER_H + 2) }, Enum.EasingStyle.Back) end)
            task.delay(0.2, function() tween(accentLine, 0.6, { Size = UDim2.new(1, 0, 0, 2) }, Enum.EasingStyle.Quint) end)
        end
        selectTab("ESP")
        print("[Froggy Hub] Panel " .. HUB_VERSION .. " cargado con éxito para: " .. GameDisplayName)
    end)
end

-- ==========================================
-- 🚀 SELECTOR DE JUEGO (EVENT-DRIVEN + PERSISTENCIA)
-- ==========================================
local GAME_FILE = "FroggyHub_game.txt"
local VALID_GAMES = {
    BloxFruits = "Blox Fruits",
    ElementalMagicArena = "Elemental Magic Arena",
    Universal = "Universal",
}

if not env.BF_SELECTED_GAME and not _G.BF_SELECTED_GAME
    and type(isfile) == "function" and type(readfile) == "function" then
    pcall(function()
        if isfile(GAME_FILE) then
            local v = readfile(GAME_FILE):gsub("%s+", "")
            if VALID_GAMES[v] then
                env.BF_SELECTED_GAME = v
                _G.BF_SELECTED_GAME = v
            end
        end
    end)
end

if not env.BF_SELECTED_GAME and not _G.BF_SELECTED_GAME then
    local promptGui = new("Frame", { Size = UDim2.fromOffset(320, 226), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 999 }, gui)
    bind(promptGui, "BackgroundColor3", "Bg"); stroke(promptGui, "Accent", 2)
    brackets(promptGui, "Accent", 14, 2, 4)
    local promptScale = Instance.new("UIScale", promptGui); promptScale.Scale = 0.6
    tween(promptScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)

    local pTop = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, promptGui)
    addGradient(pTop, accentSeq, 0)
    bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, Text = "¿Qué juego estás jugando?" }, promptGui), "TextColor3", "Text")
    local pSub = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255, 100, 100), Text = "// SELECCIONA TU DESTINO // v11.4" }, promptGui)

    local function makeChoice(y, text, folder, display)
        local b = new("TextButton", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 46), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 2 }, promptGui)
        bind(b, "BackgroundColor3", "Row")
        local st = stroke(b, "Stroke", 1)
        local bar = new("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, ZIndex = 3 }, b)
        bind(bar, "BackgroundColor3", "Accent")
        local lbl = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -50, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = text, ZIndex = 3 }, b)
        bind(lbl, "TextColor3", "Text")
        local arrow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(8, 8), Rotation = 45, BorderSizePixel = 0, ZIndex = 3 }, b)
        bind(arrow, "BackgroundColor3", "Accent2")
        local bs = Instance.new("UIScale", b)
        b.MouseEnter:Connect(function()
            tween(st, 0.15, { Color = C.Accent }); tween(bar, 0.2, { Size = UDim2.new(0, 8, 1, 0) }, Enum.EasingStyle.Back)
            tween(arrow, 0.2, { Position = UDim2.new(1, -12, 0.5, 0), Rotation = 135 }, Enum.EasingStyle.Back)
        end)
        b.MouseLeave:Connect(function()
            tween(st, 0.15, { Color = C.Stroke }); tween(bar, 0.2, { Size = UDim2.new(0, 3, 1, 0) })
            tween(arrow, 0.2, { Position = UDim2.new(1, -18, 0.5, 0), Rotation = 45 })
        end)
        b.MouseButton1Down:Connect(function() tween(bs, 0.08, { Scale = 0.96 }) end)
        b.Activated:Connect(function()
            promptGui:Destroy()
            StartHub(folder, display) -- 🛠️ Se llama directo, sin bucles
        end)
        return b
    end
    makeChoice(78, "Elemental Magic Arena", "ElementalMagicArena", "Elemental Magic Arena")
    makeChoice(134, "Blox Fruits", "BloxFruits", "Blox Fruits")
    bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -28), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.Gotham, TextSize = 10, Text = "FROGGY HUB  //  SISTEMAS EN ESPERA" }, promptGui), "TextColor3", "Dim")
else
    -- Si ya hay un juego guardado, saltamos el menú directo al Hub
    StartHub(env.BF_SELECTED_GAME or _G.BF_SELECTED_GAME, VALID_GAMES[env.BF_SELECTED_GAME or _G.BF_SELECTED_GAME] or "Universal")
end
