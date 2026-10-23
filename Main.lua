--// Main.lua - Froggy Hub | UI v12.4: Movement + Bubble + Drag

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
gui.Parent = parentGui

local C = { Danger = Color3.fromRGB(210, 70, 70), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(150, 150, 165), Bg = Color3.fromRGB(16, 16, 22), Accent = Color3.fromRGB(110, 220, 90) }
C.Header = C.Bg:Lerp(Color3.new(1,1,1), 0.06)
C.Row = C.Bg:Lerp(Color3.new(1,1,1), 0.10)
C.Off = C.Bg:Lerp(Color3.new(1,1,1), 0.20)

local function tween(o, t, props) return TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad), props) end
local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function stroke(o, key, thickness)
    local s = Instance.new("UIStroke"); s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = C[key] or C.Stroke; s.Parent = o; return s
end
local function brackets(parent, key, len, th, inset)
    for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
        local ax, ay = c[1], c[2]
        local px = (ax == 0) and inset or -inset
        local py = (ay == 0) and inset or -inset
        for _, size in ipairs({ Vector2.new(len, th), Vector2.new(th, len) }) do
            new("Frame", { AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, px, ay, py), Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = C[key], BorderSizePixel = 0 }, parent)
        end
    end
end

-- Arrastrar (Drag & Drop)
local function makeDraggable(handle, target, onTap)
    local active, startMouse, startPos, moved
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = input; startMouse = input.Position; startPos = target.Position; moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then active = nil; if not moved and onTap then onTap() end end
                    conn:Disconnect()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        if active.UserInputType == Enum.UserInputType.Touch then if input ~= active then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = input.Position - startMouse; if d.Magnitude > 8 then moved = true end
        if moved then target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
    end)
end

-- ==========================================
-- 1. SELECTOR DE JUEGO
-- ==========================================
local promptGui = new("Frame", { Size = UDim2.fromOffset(320, 226), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0 }, gui)
stroke(promptGui, "Accent", 2); brackets(promptGui, "Accent", 14, 2, 4)

new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, Text = "¿Qué juego estás jugando?", TextColor3 = C.Text }, promptGui)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.Accent, Text = "// SELECCIONA TU DESTINO // v12.4" }, promptGui)

local function makeChoice(y, text, folder, display)
    local b = new("TextButton", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 46), BackgroundColor3 = C.Row, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false }, promptGui)
    stroke(b, "Stroke", 1)
    b.Activated:Connect(function()
        promptGui:Destroy()
        loadHub(folder, display)
    end)
end
makeChoice(78, "Elemental Magic Arena", "ElementalMagicArena", "Elemental Magic Arena")
makeChoice(134, "Blox Fruits", "BloxFruits", "Blox Fruits")

-- ==========================================
-- 2. CARGA ASÍNCRONA
-- ==========================================
function loadHub(folder, displayName)
    local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"
    local BASE = (folder == "BloxFruits") and ROOT or (ROOT .. folder .. "/")
    
    local loading = new("Frame", { Size = UDim2.fromOffset(300, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0 }, gui)
    brackets(loading, "Accent", 16, 2, 4)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamBold, TextSize = 18, Text = "CARGANDO...", TextColor3 = C.Accent }, loading)
    local status = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 80), Font = Enum.Font.Gotham, TextSize = 12, Text = "Conectando...", TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left }, loading)

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
            task.wait(0.2)
            return env[key] or _G[key]
        end

        local EspC = download({folder == "BloxFruits" and "Esp.lua" or "EspElemental.lua"}, "ESP", "BF_ESP_CONFIG")
        local MoveC = download({"Movement.lua"}, "Movement", "BF_MOVE_CONFIG")
        local HitC = download({"HitboxExpander.lua"}, "Hitbox", "BF_HITBOX_CONFIG")
        local GodC = download({"GodMode.lua"}, "GodMode", "BF_GODMODE_CONFIG")
        local CombC = download({"AutoCombat.lua"}, "Combat", "BF_COMBAT_CONFIG")
        
        loading:Destroy()
        buildUI(displayName, EspC, MoveC, HitC, GodC, CombC)
    end)
end

-- ==========================================
-- 3. PANEL PRINCIPAL
-- ==========================================
function buildUI(displayName, EspC, MoveC, HitC, GodC, CombC)
    local WIDTH, HEIGHT = 400, 300 -- Panel más compacto para móvil
    local HEADER_H = 40
    
    local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0, ClipsDescendants = true }, gui)
    stroke(frame, "Accent", 1.5); brackets(frame, "Accent", 10, 1.5, 2)
    
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C.Header, BorderSizePixel = 0 }, frame)
    local titleTxt = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -100, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = "Froggy | " .. displayName, TextColor3 = C.Text }, header)
    
    local btnMin = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -60, 0.5, -13), BackgroundColor3 = C.Row, Text = "-", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false }, header)
    stroke(btnMin, "Stroke", 1)
    local btnClose = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0.5, -13), BackgroundColor3 = C.Danger, Text = "X", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false }, header)
    stroke(btnClose, "Stroke", 1)

    local body = new("ScrollingFrame", { Position = UDim2.fromOffset(10, HEADER_H + 10), Size = UDim2.new(1, -20, 1, -(HEADER_H + 20)), BackgroundTransparency = 1, ScrollBarThickness = 2 }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 8) }, body)

    local function makeGroup(title)
        local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Row, BackgroundTransparency = 0.2 }, body)
        stroke(card, "Stroke", 1); new("UICorner", { CornerRadius = UDim.new(0, 6) }, card)
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, card)
        new("UIListLayout", { Padding = UDim.new(0, 4) }, card)
        new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(title), TextColor3 = C.Accent }, card)
        return card
    end

    local function makeToggle(parent, text, config, key)
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, parent)
        new("TextLabel", { Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text }, row)
        local btn = new("TextButton", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -36, 0.5, -9), BackgroundColor3 = C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1,1,1) }, btn)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        local function refresh() local on = config and config[key]; btn.BackgroundColor3 = on and C.Accent or C.Off; knob.Position = on and UDim2.new(1, -16, 0, 2) or UDim2.fromOffset(2, 2) end
        btn.Activated:Connect(function() if config then config[key] = not config[key]; refresh() end end)
        refresh()
    end

    local function makeSlider(parent, text, config, key, minV, maxV)
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, parent)
        new("TextLabel", { Size = UDim2.new(1, -50, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Dim }, row)
        local valLabel = new("TextLabel", { Size = UDim2.fromOffset(50, 14), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(config and config[key] or minV), TextColor3 = C.Accent }, row)
        local track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 18), BackgroundColor3 = C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local fill = new("Frame", { Size = UDim2.fromScale((config and config[key] or minV) / maxV, 1), BackgroundColor3 = C.Accent }, track)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        local hit = new("Frame", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1 }, row)
        
        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + rel * (maxV - minV) + 0.5)
            if config then config[key] = v end
            fill.Size = UDim2.fromScale(rel, 1)
            valLabel.Text = tostring(v)
        end
        hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input.Position.X) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    end

    -- Contenido
    if EspC then local g = makeGroup("ESP"); makeToggle(g, "Activar ESP", EspC, "Enabled"); makeToggle(g, "Cajas", EspC, "Boxes") end
    if MoveC then local g = makeGroup("Movimiento"); makeToggle(g, "Speed", MoveC, "SpeedEnabled"); makeSlider(g, "Velocidad", MoveC, "Speed", 16, 200); makeToggle(g, "Super Jump", MoveC, "JumpEnabled"); makeSlider(g, "Salto", MoveC, "JumpPower", 50, 300) end
    if HitC then local g = makeGroup("Hitbox"); makeToggle(g, "Hitbox 35 Studs", HitC, "Enabled") end
    if GodC then local g = makeGroup("God Mode"); makeToggle(g, "Inmortalidad", GodC, "Enabled"); makeToggle(g, "Anti-Caída", GodC, "AntiVoid") end
    if CombC then local g = makeGroup("Auto Combat"); makeToggle(g, "Activar", CombC, "Enabled"); makeToggle(g, "Auto M1", CombC, "AutoM1") end

    -- 🛠️ LÓGICA DE BURBUJA Y MINIMIZAR
    local BUBBLE = 46
    local bubble = new("TextButton", { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Header, Visible = false, Text = "F", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.Accent, AutoButtonColor = false }, gui)
    stroke(bubble, "Accent", 2); new("UICorner", { CornerRadius = UDim.new(1, 0) }, bubble)
    
    local function minimizePanel()
        bubble.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + 8, frame.Position.Y.Scale, frame.Position.Y.Offset + 8)
        frame.Visible = false
        bubble.Visible = true
    end
    
    local function restorePanel()
        frame.Position = UDim2.new(bubble.Position.X.Scale, bubble.Position.X.Offset - 8, bubble.Position.Y.Scale, bubble.Position.Y.Offset - 8)
        bubble.Visible = false
        frame.Visible = true
    end

    btnMin.Activated:Connect(minimizePanel)
    btnClose.Activated:Connect(function() gui:Destroy() end)
    
    makeDraggable(header, frame)
    makeDraggable(bubble, bubble, restorePanel) -- Si tocas la burbuja (sin arrastrar), se restaura
end
