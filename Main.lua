--// Main.lua - Froggy Hub | UI v12.3: Movement Restored + PlayerGui + Async Load

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 🛠️ USAMOS PLAYER GUI
local parentGui = LocalPlayer:WaitForChild("PlayerGui")
for _, obj in ipairs(parentGui:GetChildren()) do
    if obj.Name:match("^FroggyHub_") then obj:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "FroggyHub_Main"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui

-- TEMAS
local THEMES = {
    { Name = "Froggy", Accent = Color3.fromRGB(110, 220, 90),  Accent2 = Color3.fromRGB(40, 170, 130),  Bg = Color3.fromRGB(16, 16, 22) },
    { Name = "Cyber",  Accent = Color3.fromRGB(255, 50, 150),  Accent2 = Color3.fromRGB(120, 80, 255),  Bg = Color3.fromRGB(20, 10, 30) },
    { Name = "Blood",  Accent = Color3.fromRGB(220, 60, 60),   Accent2 = Color3.fromRGB(255, 130, 60),  Bg = Color3.fromRGB(18, 10, 10) },
    { Name = "Ocean",  Accent = Color3.fromRGB(50, 200, 255),  Accent2 = Color3.fromRGB(60, 120, 255),  Bg = Color3.fromRGB(10, 18, 25) },
    { Name = "Matrix", Accent = Color3.fromRGB(60, 255, 90),   Accent2 = Color3.fromRGB(0, 150, 50),    Bg = Color3.fromRGB(6, 14, 8) },
    { Name = "Mono",   Accent = Color3.fromRGB(210, 210, 215), Accent2 = Color3.fromRGB(120, 120, 135), Bg = Color3.fromRGB(10, 10, 12) },
}
local function themeByName(name) for _, t in ipairs(THEMES) do if t.Name == name then return t end end return THEMES[1] end
local C = { Danger = Color3.fromRGB(210, 70, 70), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(150, 150, 165), AccentText = Color3.fromRGB(12, 14, 12) }

local function setPalette(theme)
    local bg, white = theme.Bg, Color3.new(1, 1, 1)
    C.Bg = bg; C.Header = bg:Lerp(white, 0.06); C.Row = bg:Lerp(white, 0.10)
    C.Stroke = bg:Lerp(white, 0.22); C.Off = bg:Lerp(white, 0.20)
    C.Accent = theme.Accent; C.Accent2 = theme.Accent2; C.On = theme.Accent
end
setPalette(themeByName("Froggy"))

-- UTILIDADES
local binds, gradients = {}, {}
local function bind(o, prop, key) table.insert(binds, { o = o, p = prop, k = key }); o[prop] = C[key]; return o end
local function tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function stroke(o, key, thickness)
    local s = Instance.new("UIStroke"); s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Miter; s.Parent = o
    bind(s, "Color", key or "Stroke"); return s
end
local function accentSeq() return ColorSequence.new(C.Accent, C.Accent2) end
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

-- ==========================================
-- 🚀 1. SELECTOR DE JUEGO
-- ==========================================
local promptGui = new("Frame", { Size = UDim2.fromOffset(320, 226), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 999 }, gui)
bind(promptGui, "BackgroundColor3", "Bg"); stroke(promptGui, "Accent", 2)
brackets(promptGui, "Accent", 14, 2, 4)
local promptScale = Instance.new("UIScale", promptGui); promptScale.Scale = 0.6
tween(promptScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)

local pTop = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, promptGui)
addGradient(pTop, accentSeq, 0)
bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, Text = "¿Qué juego estás jugando?" }, promptGui), "TextColor3", "Text")
bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255, 100, 100), Text = "// SELECCIONA TU DESTINO // v12.3" }, promptGui), "TextColor3", "Dim")

local function makeChoice(y, text, folder, display)
    local b = new("TextButton", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 46), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 2 }, promptGui)
    bind(b, "BackgroundColor3", "Row")
    local st = stroke(b, "Stroke", 1)
    local bar = new("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, ZIndex = 3 }, b)
    bind(bar, "BackgroundColor3", "Accent")
    local lbl = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -50, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = text, ZIndex = 3 }, b)
    bind(lbl, "TextColor3", "Text")
    local bs = Instance.new("UIScale", b)
    b.MouseButton1Down:Connect(function() tween(bs, 0.08, { Scale = 0.96 }) end)
    b.Activated:Connect(function()
        promptGui:Destroy()
        loadHub(folder, display)
    end)
end
makeChoice(78, "Elemental Magic Arena", "ElementalMagicArena", "Elemental Magic Arena")
makeChoice(134, "Blox Fruits", "BloxFruits", "Blox Fruits")
bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -28), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.Gotham, TextSize = 10, Text = "FROGGY HUB  //  SISTEMAS EN ESPERA" }, promptGui), "TextColor3", "Dim")

-- ==========================================
-- 🚀 2. CARGA ASÍNCRONA
-- ==========================================
function loadHub(folder, displayName)
    local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"
    local BASE = (folder == "BloxFruits") and ROOT or (ROOT .. folder .. "/")
    
    local loading = new("Frame", { Size = UDim2.fromOffset(300, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ZIndex = 998 }, gui)
    bind(loading, "BackgroundColor3", "Bg")
    brackets(loading, "Accent", 16, 2, 4, nil, 6)
    bind(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamBold, TextSize = 18, Text = "CARGANDO..." }, loading), "TextColor3", "Accent")
    local status = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 80), Font = Enum.Font.Gotham, TextSize = 12, Text = "Conectando...", TextXAlignment = Enum.TextXAlignment.Left }, loading)
    bind(status, "TextColor3", "Text")

    task.spawn(function()
        local function download(names, label, key)
            status.Text = "Descargando " .. label .. "..."
            for _, n in ipairs(names) do
                local ok, res = pcall(function() return game:HttpGet(BASE .. n .. "?v=" .. os.time()) end)
                if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
                    local fn = loadstring(res)
                    if fn then pcall(fn) end
                end
            end
            task.wait(0.3)
            return env[key] or _G[key]
        end

        local EspC = nil
        if folder == "BloxFruits" then
            EspC = download({"Esp.lua"}, "ESP", "BF_ESP_CONFIG")
        else
            EspC = download({"EspElemental.lua"}, "ESP", "BF_ESP_CONFIG")
        end
        
        local MoveC = download({"Movement.lua"}, "Movement", "BF_MOVE_CONFIG") -- 🛠️ AQUI ESTA EL MOVEMENT
        local HitC = download({"HitboxExpander.lua"}, "Hitbox", "BF_HITBOX_CONFIG")
        local GodC = download({"GodMode.lua"}, "GodMode", "BF_GODMODE_CONFIG")
        local CombC = download({"AutoCombat.lua"}, "Combat", "BF_COMBAT_CONFIG")
        local ChatC = download({"ChatMessage.lua"}, "Chat", "BF_CHAT_CONFIG")
        
        loading:Destroy()
        buildUI(displayName, EspC, MoveC, HitC, GodC, CombC)
    end)
end

-- ==========================================
-- 🚀 3. CONSTRUCCIÓN DEL PANEL
-- ==========================================
function buildUI(displayName, EspC, MoveC, HitC, GodC, CombC)
    local WIDTH, HEIGHT = 540, 340
    local HEADER_H, SIDE_W = 46, 118
    
    local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ClipsDescendants = true }, gui)
    bind(frame, "BackgroundColor3", "Bg")
    local fSt = stroke(frame, "Stroke", 2)
    
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 0.3 }, frame)
    bind(header, "BackgroundColor3", "Header")
    bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 5), Size = UDim2.new(1, -100, 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = "Froggy Hub | " .. displayName }, header), "TextColor3", "Text")
    bind(new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0.5, -7), Size = UDim2.fromOffset(40, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Text = "v12.3" }, header), "TextColor3", "Dim")
    
    local closeBtn = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0.5, -15), BackgroundColor3 = C.Danger, Text = "X", TextColor3 = C.Text, Font = Enum.Font.GothamBold, AutoButtonColor = false }, header)
    closeBtn.Activated:Connect(function() gui:Destroy() end)

    local body = new("ScrollingFrame", { Position = UDim2.fromOffset(10, HEADER_H + 10), Size = UDim2.new(1, -20, 1, -(HEADER_H + 20)), BackgroundTransparency = 1, ScrollBarThickness = 2 }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 8) }, body)

    local function makeGroup(title)
        local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Row, BackgroundTransparency = 0.2 }, body)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, card)
        new("UIStroke", { Color = C.Stroke }, card)
        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, card)
        new("UIListLayout", { Padding = UDim.new(0, 6) }, card)
        
        bind(new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(title) }, card), "TextColor3", "Accent")
        return card
    end

    local function makeToggle(parent, text, config, key)
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, parent)
        bind(new("TextLabel", { Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, row), "TextColor3", "Text")
        
        local btn = new("TextButton", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, -10), BackgroundColor3 = C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1,1,1) }, btn)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        
        local function refresh()
            local on = config and config[key]
            tween(btn, 0.15, { BackgroundColor3 = on and C.Accent or C.Off })
            tween(knob, 0.15, { Position = on and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2) })
        end
        btn.Activated:Connect(function()
            if config then config[key] = not config[key]; refresh() end
        end)
        refresh()
    end

    -- 🛠️ NUEVO: FUNCIÓN DE SLIDER PARA MOVEMENT
    local function makeSlider(parent, text, config, key, minV, maxV)
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, parent)
        bind(new("TextLabel", { Size = UDim2.new(1, -50, 0, 15), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, row), "TextColor3", "Dim")
        local valLabel = bind(new("TextLabel", { Size = UDim2.fromOffset(50, 15), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(config and config[key] or minV) }, row), "TextColor3", "Accent")
        
        local track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local fill = new("Frame", { Size = UDim2.fromScale((config and config[key] or minV) / maxV, 1), BackgroundColor3 = C.Accent }, track)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        
        local hit = new("Frame", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 12), BackgroundTransparency = 1 }, row)
        local dragging = false
        
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + rel * (maxV - minV) + 0.5)
            if config then config[key] = v end
            fill.Size = UDim2.fromScale(rel, 1)
            valLabel.Text = tostring(v)
        end
        
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- CONTENIDO
    if EspC then
        local espG = makeGroup("ESP")
        makeToggle(espG, "Activar ESP", EspC, "Enabled")
        makeToggle(espG, "Cajas 2D", EspC, "Boxes")
    end

    -- 🛠️ MOVEMENT RESTAURADO
    if MoveC then
        local movG = makeGroup("Movimiento (Movement)")
        makeToggle(movG, "Activar Speed", MoveC, "SpeedEnabled")
        makeSlider(movG, "Velocidad extra", MoveC, "Speed", 16, 200)
        makeToggle(movG, "Super Jump", MoveC, "JumpEnabled")
        makeSlider(movG, "Fuerza de salto", MoveC, "JumpPower", 50, 300)
    end

    if HitC then
        local hitG = makeGroup("Hitbox Expander")
        makeToggle(hitG, "Activar Hitbox (35 Studs)", HitC, "Enabled")
    end

    if GodC then
        local godG = makeGroup("God Mode")
        makeToggle(godG, "Activar Inmortalidad", GodC, "Enabled")
    end

    if CombC then
        local combG = makeGroup("Auto Combat")
        makeToggle(combG, "Activar Combate", CombC, "Enabled")
        makeToggle(combG, "Auto M1", CombC, "AutoM1")
    end
end
