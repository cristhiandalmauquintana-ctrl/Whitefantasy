--// Main.lua - Froggy Hub | UI v13.3: Plano y Anti-Nil
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local parentGui = LocalPlayer:WaitForChild("PlayerGui")
for _, obj in ipairs(parentGui:GetChildren()) do
    if obj.Name == "FroggyHub_Main" then obj:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "FroggyHub_Main"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = parentGui

local C = { Danger = Color3.fromRGB(210, 70, 70), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(150, 150, 165), Bg = Color3.fromRGB(16, 16, 22), Accent = Color3.fromRGB(110, 220, 90), Maho = Color3.fromRGB(180, 60, 180) }
C.Header = C.Bg:Lerp(Color3.new(1,1,1), 0.06)
C.Row = C.Bg:Lerp(Color3.new(1,1,1), 0.10)
C.Off = C.Bg:Lerp(Color3.new(1,1,1), 0.20)
C.Stroke = C.Bg:Lerp(Color3.new(1,1,1), 0.22)

local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function stroke(o, key, thickness) local s = Instance.new("UIStroke"); s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = C[key] or C.Stroke; s.Parent = o; return s end

-- Funciones auxiliares de UI
local function clampPos(x, y, w, h)
    local v = workspace.CurrentCamera.ViewportSize
    return math.clamp(x, 0, v.X - w), math.clamp(y, 0, v.Y - h)
end

local function makeDraggable(handle, target, w, h, onTap)
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
        local d = input.Position - startMouse; if d.Magnitude > 5 then moved = true end
        if moved then 
            local cx, cy = clampPos(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y, w, h)
            target.Position = UDim2.fromOffset(cx, cy) 
        end
    end)
end

-- 1. SELECTOR
local promptGui = new("Frame", { Size = UDim2.fromOffset(320, 226), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0, ZIndex = 999 }, gui)
stroke(promptGui, "Accent", 2)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, Text = "¿Qué juego estás jugando?", TextColor3 = C.Text, ZIndex = 1000 }, promptGui)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.Accent, Text = "// FROGGY HUB v13.3 //", ZIndex = 1000 }, promptGui)

local function makeChoice(y, text, folder, display)
    local b = new("TextButton", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 46), BackgroundColor3 = C.Row, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, ZIndex = 1000 }, promptGui)
    stroke(b, "Stroke", 1)
    b.Activated:Connect(function() 
        promptGui:Destroy()
        -- Llamada global a loadHub
        _G.Froggy_LoadHub(folder, display)
    end)
end
makeChoice(78, "Elemental Magic Arena", "ElementalMagicArena", "Elemental Magic Arena")
makeChoice(134, "Blox Fruits", "BloxFruits", "Blox Fruits")

-- 2. CARGA (Función Global para evitar problemas de scope)
function _G.Froggy_LoadHub(folder, displayName)
    local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"
    local BASE = (folder == "BloxFruits") and ROOT or (ROOT .. folder .. "/")
    
    local loading = new("Frame", { Size = UDim2.fromOffset(300, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0, ZIndex = 998 }, gui)
    stroke(loading, "Accent", 2)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamBold, TextSize = 18, Text = "CARGANDO...", TextColor3 = C.Accent, ZIndex = 999 }, loading)
    
    task.spawn(function()
        local function download(names, key)
            for _, n in ipairs(names) do
                local ok, res = pcall(game.HttpGet, game, BASE .. n .. "?v=" .. os.time())
                if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
                    -- Usamos pcall en loadstring para evitar errores si falla
                    local fnOk, fn = pcall(loadstring, res)
                    if fnOk and type(fn) == "function" then pcall(fn) end
                end
            end
            task.wait(0.1)
            return env[key] or _G[key]
        end

        local EspC = download({folder == "BloxFruits" and "Esp.lua" or "EspElemental.lua"}, "BF_ESP_CONFIG")
        local MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
        local HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
        local GodC = download({"GodMode.lua"}, "BF_GODMODE_CONFIG")
        local CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")
        
        loading:Destroy()
        pcall(function() _G.Froggy_BuildUI(displayName, EspC, MoveC, HitC, GodC, CombC) end)
    end)
end

-- 3. PANEL (Función Global)
function _G.Froggy_BuildUI(displayName, EspC, MoveC, HitC, GodC, CombC)
    local WIDTH, HEIGHT = 400, 420
    local HEADER_H = 40
    local viewport = workspace.CurrentCamera.ViewportSize
    local startX = (viewport.X - WIDTH) / 2
    local startY = (viewport.Y - HEIGHT) / 2
    
    local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromOffset(startX, startY), BackgroundColor3 = C.Bg, BorderSizePixel = 1, BorderColor3 = C.Accent, ClipsDescendants = true, ZIndex = 2 }, gui)
    
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 3 }, frame)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -100, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = "Froggy | " .. displayName, TextColor3 = C.Text, ZIndex = 4 }, header)
    
    local btnMin = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -60, 0.5, -13), BackgroundColor3 = C.Row, Text = "-", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, ZIndex = 4 }, header)
    local btnClose = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0.5, -13), BackgroundColor3 = C.Danger, Text = "X", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, ZIndex = 4 }, header)

    local body = new("ScrollingFrame", { Position = UDim2.fromOffset(10, HEADER_H + 10), Size = UDim2.new(1, -20, 1, -(HEADER_H + 20)), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 800), ZIndex = 3 }, frame)

    local currentY = 0
    local function addTitle(text)
        new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, currentY), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text), TextColor3 = C.Accent, ZIndex = 4 }, body)
        currentY = currentY + 25
    end

    local function addToggle(text, config, key)
        if not config then return end
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 35), Position = UDim2.fromOffset(0, currentY), BackgroundColor3 = C.Row, ZIndex = 4 }, body)
        new("TextLabel", { Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text, ZIndex = 5 }, row)
        local btn = new("TextButton", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = config[key] and C.Accent or C.Off, ZIndex = 5 }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = config[key] and UDim2.new(1, -16, 0, 2) or UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 6 }, btn)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        btn.Activated:Connect(function() config[key] = not config[key]; btn.BackgroundColor3 = config[key] and C.Accent or C.Off; knob.Position = config[key] and UDim2.new(1, -16, 0, 2) or UDim2.fromOffset(2, 2) end)
        currentY = currentY + 40
    end

    local function addSlider(text, config, key, minV, maxV)
        if not config then return end
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 45), Position = UDim2.fromOffset(0, currentY), BackgroundColor3 = C.Row, ZIndex = 4 }, body)
        new("TextLabel", { Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(10, 2), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text, ZIndex = 5 }, row)
        local valLabel = new("TextLabel", { Size = UDim2.fromOffset(50, 18), Position = UDim2.new(1, -60, 0, 2), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(config[key] or minV), TextColor3 = C.Accent, ZIndex = 5 }, row)
        local track = new("Frame", { Size = UDim2.new(1, -20, 0, 6), Position = UDim2.fromOffset(10, 25), BackgroundColor3 = C.Off, ZIndex = 5 }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local rel = math.clamp(((config[key] or minV) - minV) / (maxV - minV), 0, 1)
        local fill = new("Frame", { Size = UDim2.fromScale(rel, 1), BackgroundColor3 = C.Accent, ZIndex = 6 }, track)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        local hit = new("Frame", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 18), BackgroundTransparency = 1, ZIndex = 7 }, row)
        local dragging = false
        local function update(x)
            local width = math.max(1, track.AbsoluteSize.X)
            local relX = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
            local v = math.floor(minV + relX * (maxV - minV) + 0.5)
            config[key] = v
            fill.Size = UDim2.fromScale(relX, 1)
            valLabel.Text = tostring(v)
        end
        hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input.Position.X) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        currentY = currentY + 50
    end

    if EspC then addTitle("ESP"); addToggle("Activar ESP", EspC, "Enabled"); addToggle("Cajas 2D", EspC, "Boxes") end
    if MoveC then addTitle("Movimiento"); addToggle("Speed", MoveC, "SpeedEnabled"); addSlider("Velocidad", MoveC, "Speed", 16, 200); addToggle("Super Jump", MoveC, "JumpEnabled"); addSlider("Salto", MoveC, "JumpPower", 50, 300) end
    if HitC then addTitle("Hitbox"); addToggle("Hitbox 35 Studs", HitC, "Enabled") end
    if CombC then addTitle("Auto Combat"); addToggle("Activar", CombC, "Enabled"); addToggle("Auto M1", CombC, "AutoM1") end

    local mahoBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), Position = UDim2.fromOffset(viewport.X - 120, viewport.Y / 2), BackgroundColor3 = C.Row, Text = "MAHORAGA: OFF", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false, ZIndex = 10 }, gui)
    stroke(mahoBtn, "Maho", 2)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, mahoBtn)

    mahoBtn.Activated:Connect(function()
        if GodC then
            GodC.Mahoraga = not GodC.Mahoraga
            if GodC.Mahoraga then
                mahoBtn.Text = "MAHORAGA: ON"
                mahoBtn.BackgroundColor3 = C.Maho
                mahoBtn.TextColor3 = Color3.new(1,1,1)
            else
                mahoBtn.Text = "MAHORAGA: OFF"
                mahoBtn.BackgroundColor3 = C.Row
                mahoBtn.TextColor3 = C.Text
            end
        end
    end)
    
    makeDraggable(mahoBtn, mahoBtn, 100, 40)

    local BUBBLE = 46
    local bubble = new("TextButton", { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Header, Visible = false, Text = "F", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.Accent, AutoButtonColor = false, ZIndex = 10 }, gui)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, bubble)
    
    local function minimizePanel()
        local px = frame.Position.X.Offset + 8
        local py = frame.Position.Y.Offset + 8
        local cx, cy = clampPos(px, py, BUBBLE, BUBBLE)
        bubble.Position = UDim2.fromOffset(cx, cy)
        frame.Visible = false
        bubble.Visible = true
    end
    
    local function restorePanel()
        local px = bubble.Position.X.Offset - 8
        local py = bubble.Position.Y.Offset - 8
        local cx, cy = clampPos(px, py, WIDTH, HEIGHT)
        frame.Position = UDim2.fromOffset(cx, cy)
        bubble.Visible = false
        frame.Visible = true
    end

    btnMin.Activated:Connect(minimizePanel)
    bubble.Activated:Connect(restorePanel) 
    btnClose.Activated:Connect(function() gui:Destroy() end)
    
    makeDraggable(header, frame, WIDTH, HEIGHT)
    makeDraggable(bubble, bubble, BUBBLE, BUBBLE)
end
