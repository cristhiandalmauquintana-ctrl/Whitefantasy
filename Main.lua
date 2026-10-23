--// Main.lua - Froggy Hub | UI v17.2 (Brookhaven + Sound Loop)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

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

local C = { Danger = Color3.fromRGB(210, 70, 70), Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(150, 150, 165), Bg = Color3.fromRGB(16, 16, 22), Accent = Color3.fromRGB(110, 220, 90), Row = Color3.fromRGB(30, 30, 40), Off = Color3.fromRGB(50, 50, 60) }

local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end

local function makeDraggable(handle, target)
    local active, startMouse, startPos, moved
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = input; startMouse = input.Position; startPos = target.Position; moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then active = nil end
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
        if moved then target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
    end)
end

local loadHub

-- 1. SELECTOR DE JUEGO
local prompt = new("Frame", { Size = UDim2.fromOffset(300, 260), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, prompt)
new("UIStroke", { Color = C.Accent, Thickness = 2 }, prompt)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamBold, TextSize = 16, Text = "Selecciona el Juego", TextColor3 = C.Text }, prompt)

local function makeChoice(y, text, folder, display, color)
    local btn = new("TextButton", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 45), BackgroundColor3 = color or C.Row, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false }, prompt)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    new("UIStroke", { Color = C.Off }, btn)
    btn.Activated:Connect(function()
        prompt:Destroy()
        if loadHub then loadHub(folder, display) end
    end)
end
makeChoice(60, "Elemental Magic Arena", "ElementalMagicArena", "Elemental Magic Arena", C.Row)
makeChoice(115, "Blox Fruits", "BloxFruits", "Blox Fruits", C.Row)
makeChoice(170, "Brookhaven", "Brookhaven", "Brookhaven RP", Color3.fromRGB(60, 130, 200))

-- 2. CARGA DE MÓDULOS
loadHub = function(folder, displayName)
    local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"
    local BASE = (folder == "BloxFruits") and ROOT or (ROOT .. folder .. "/")
    
    local loading = new("Frame", { Size = UDim2.fromOffset(250, 100), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Bg }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, loading)
    new("UIStroke", { Color = C.Accent, Thickness = 1.5 }, loading)
    local loadText = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, Text = "Cargando...", TextColor3 = C.Accent }, loading)
    
    task.spawn(function()
        local function download(names, key)
            for _, n in ipairs(names) do
                local ok, res = pcall(game.HttpGet, game, BASE .. n .. "?v=" .. os.time())
                if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
                    local fnOk, fn = pcall(loadstring, res)
                    if fnOk and type(fn) == "function" then pcall(fn) end
                end
            end
            task.wait(0.1)
            return env[key] or _G[key]
        end

        local EspC, MoveC, HitC, CombC, CamC, SoundC = nil, nil, nil, nil, nil, nil
        
        if folder == "Brookhaven" then
            loadText.Text = "Cargando Sonidos..."
            SoundC = download({"SoundPlayer.lua"}, "BF_SOUND_CONFIG")
        elseif folder == "ElementalMagicArena" then
            loadText.Text = "Cargando ESP..."
            EspC = download({"EspElemental.lua"}, "BF_ESP_CONFIG")
            loadText.Text = "Cargando Movimiento..."
            MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
            loadText.Text = "Cargando Combate..."
            CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")
            loadText.Text = "Cargando Hitbox..."
            HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
        else
            loadText.Text = "Cargando ESP..."
            EspC = download({"Esp.lua"}, "BF_ESP_CONFIG")
            loadText.Text = "Cargando Movimiento..."
            MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
            loadText.Text = "Cargando Camlock..."
            CamC = download({"Camlock.lua"}, "BF_CAM_CONFIG")
        end
        
        loading:Destroy()
        buildUI(displayName, EspC, MoveC, HitC, CombC, CamC, SoundC)
    end)
end

-- 3. INTERFAZ PRINCIPAL
function buildUI(displayName, EspC, MoveC, HitC, CombC, CamC, SoundC)
    local WIDTH, HEIGHT = 350, 420
    local viewport = workspace.CurrentCamera.ViewportSize
    local startX = (viewport.X - WIDTH) / 2
    local startY = (viewport.Y - HEIGHT) / 2
    
    local frame = new("Frame", { Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.fromOffset(startX, startY), BackgroundColor3 = C.Bg, BorderSizePixel = 1, BorderColor3 = C.Accent }, gui)
    
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Row }, frame)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = "Froggy | " .. displayName, TextColor3 = C.Text }, header)
    
    local btnMin = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -60, 0.5, -13), BackgroundColor3 = C.Bg, Text = "-", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 18 }, header)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, btnMin)
    local btnClose = new("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0.5, -13), BackgroundColor3 = C.Danger, Text = "X", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14 }, header)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, btnClose)

    local body = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 45), Size = UDim2.new(1, 0, 1, -45), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 1000) }, frame)
    local y = 5
    
    local function addTitle(text)
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text), TextColor3 = C.Accent }, body)
        y = y + 22
    end

    local function addTextBox(text, cfg, key)
        if not cfg then return end
        local row = new("Frame", { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, y), BackgroundColor3 = C.Row }, body)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text }, row)
        
        local box = new("TextBox", { Size = UDim2.fromOffset(80, 24), Position = UDim2.new(1, -90, 0.5, -12), BackgroundColor3 = C.Bg, Text = tostring(cfg[key] or ""), TextColor3 = C.Accent, Font = Enum.Font.GothamBold, TextSize = 12, PlaceholderText = "ID..." }, row)
        new("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
        new("UIStroke", { Color = C.Off }, box)
        
        box.FocusLost:Connect(function() cfg[key] = box.Text end)
        y = y + 45
    end

    local function addToggle(text, cfg, key)
        if not cfg then return end
        local row = new("Frame", { Size = UDim2.new(1, -20, 0, 35), Position = UDim2.fromOffset(10, y), BackgroundColor3 = C.Row }, body)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text }, row)
        
        local btn = new("TextButton", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = cfg[key] and C.Accent or C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = cfg[key] and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1,1,1) }, btn)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        
        btn.Activated:Connect(function()
            cfg[key] = not cfg[key]
            btn.BackgroundColor3 = cfg[key] and C.Accent or C.Off
            knob.Position = cfg[key] and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2)
        end)
        y = y + 40
    end

    local function addSlider(text, cfg, key, minV, maxV)
        if not cfg then return end
        local row = new("Frame", { Size = UDim2.new(1, -20, 0, 45), Position = UDim2.fromOffset(10, y), BackgroundColor3 = C.Row }, body)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextColor3 = C.Text }, row)
        local valLbl = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -50, 0, 2), Size = UDim2.fromOffset(40, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(cfg[key] or minV), TextColor3 = C.Accent }, row)
        
        local track = new("Frame", { Position = UDim2.fromOffset(10, 25), Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = C.Off }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local fill = new("Frame", { Size = UDim2.fromScale(((cfg[key] or minV) - minV) / (maxV - minV), 1), BackgroundColor3 = C.Accent }, track)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        
        local hit = new("Frame", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, row)
        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + rel * (maxV - minV) + 0.5)
            cfg[key] = v
            fill.Size = UDim2.fromScale(rel, 1)
            valLbl.Text = tostring(v)
        end
        hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input.Position.X) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        y = y + 50
    end

    -- SECCIÓN BROOKHAVEN
    if SoundC then
        addTitle("Reproductor de Audio")
        addTextBox("Sound ID", SoundC, "SoundId")
        addToggle("Reproducir Sonido", SoundC, "Playing")
        addToggle("Reproducir en Bucle (Loop)", SoundC, "Loop")
        addSlider("Volumen", SoundC, "Volume", 1, 10)
    end

    if EspC then addTitle("ESP"); addToggle("Activar ESP", EspC, "Enabled"); addToggle("Cajas 2D", EspC, "Boxes") end
    if MoveC then addTitle("Movimiento"); addToggle("Speed", MoveC, "SpeedEnabled"); addSlider("Velocidad", MoveC, "Speed", 16, 200); addToggle("Super Jump", MoveC, "JumpEnabled"); addSlider("Salto", MoveC, "JumpPower", 50, 300) end
    if HitC then addTitle("Hitbox"); addToggle("Hitbox 35 Studs", HitC, "Enabled") end
    if CombC then addTitle("Auto Combat"); addToggle("Activar", CombC, "Enabled") end
    if CamC then addTitle("Camlock"); addToggle("Activar", CamC, "Enabled") end

    local BUBBLE = 46
    local bubble = new("TextButton", { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Row, Visible = false, Text = "F", TextColor3 = C.Accent, Font = Enum.Font.GothamBold, TextSize = 22 }, gui)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, bubble)
    new("UIStroke", { Color = C.Accent, Thickness = 2 }, bubble)

    btnMin.Activated:Connect(function()
        bubble.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + 8, frame.Position.Y.Scale, frame.Position.Y.Offset + 8)
        frame.Visible = false
        bubble.Visible = true
    end)
    bubble.Activated:Connect(function()
        frame.Position = UDim2.new(bubble.Position.X.Scale, bubble.Position.X.Offset - 8, bubble.Position.Y.Scale, bubble.Position.Y.Offset - 8)
        bubble.Visible = false
        frame.Visible = true
    end)
    btnClose.Activated:Connect(function() gui:Destroy() end)

    makeDraggable(header, frame)
    makeDraggable(bubble, bubble)
end
