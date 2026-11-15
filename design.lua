--[[
    design.lua  |  "Deep Blue Hub" (Crystal & Electric Edition)
    - Optimizado para móviles (Cero RenderStepped, solo TweenService).
    - Formato Rectángulo Ancho (620x380 por defecto).
    - Con ClipsDescendants activado para evitar que los cuadros negros se salgan del panel.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local rng = Random.new()
local UI_Library = { Version = "6.1.0" }

-- ==========================================
-- PALETA DE COLORES (DEEP OCEAN / CRYSTAL)
-- ==========================================
local C = {
    BG_Dark = Color3.fromRGB(4, 10, 26),
    BG_Panel = Color3.fromRGB(10, 24, 56),
    BG_Row = Color3.fromRGB(16, 34, 74),
    Electric = Color3.fromRGB(24, 200, 255),
    Cyan = Color3.fromRGB(112, 216, 255),
    Blue = Color3.fromRGB(31, 91, 255),
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(240, 248, 255),
    TextDim = Color3.fromRGB(130, 170, 220),
    Red = Color3.fromRGB(255, 98, 122),
    Green = Color3.fromRGB(61, 255, 168),
}
local FONT_TITLE = Enum.Font.GothamBlack
local FONT_BODY = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local EASE_BACK = Enum.EasingStyle.Back
local EASE_SINE = Enum.EasingStyle.Sine
local OUT = Enum.EasingDirection.Out

-- ==========================================
-- UTILIDADES
-- ==========================================
local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or EASE_SINE, dir or OUT), props)
    tw:Play()
    return tw
end

local function Corner(o, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
end

local function Stroke(o, color, thickness, transparency)
    return New("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, o)
end

local function Grad(o, colorSeq, rot, transp)
    local g = New("UIGradient", { Color = colorSeq, Rotation = rot or 0 }, o)
    if transp then g.Transparency = transp end
    return g
end

local function IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- ==========================================
-- LOGO (Cola de ballena hecha con Frames)
-- ==========================================
local function BuildLogo(parent, size, pos, anchor)
    local c = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        Position = pos,
        AnchorPoint = anchor or Vector2.new(0, 0),
        BackgroundTransparency = 1,
    }, parent)
    
    local parts = {
        { 0.1, 0.4, 0.5, 0.6, 0, C.Cyan },
        { 0.4, 0.1, 0.3, 0.4, 25, C.Cyan },
        { 0.4, 0.1, 0.7, 0.4, -25, C.Cyan },
        { 0.3, 0.05, 0.3, 0.4, 25, C.Electric },
        { 0.3, 0.05, 0.7, 0.4, -25, C.Electric },
        { 0.6, 0.05, 0.5, 0.8, 0, C.White },
    }
    for _, p in ipairs(parts) do
        local f = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromScale(p[1], p[2]),
            Position = UDim2.fromScale(p[3], p[4]),
            Rotation = p[5],
            BackgroundColor3 = p[6],
            BorderSizePixel = 0,
        }, c)
        Corner(f, 999)
    end
    return c
end

-- ==========================================
-- CLASE TAB
-- ==========================================
local Tab = {}
Tab.__index = Tab

function Tab:CreateRow(height)
    local r = New("Frame", {
        Size = UDim2.new(1, -10, 0, height),
        BackgroundColor3 = C.BG_Row,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = self.Page
    })
    Corner(r, 6)
    Stroke(r, C.Electric, 1.5, 0.7)
    Grad(r, ColorSequence.new(C.BG_Panel, C.BG_Row), 90)
    return r
end

function Tab:AddSection(str)
    local holder = New("Frame", { Size = UDim2.new(1, -10, 0, 24), BackgroundTransparency = 1, Parent = self.Page })
    local lbl = New("TextLabel", {
        BackgroundTransparency = 1, Text = string.upper(str), Font = FONT_BOLD, TextSize = 11, TextColor3 = C.Cyan,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,16), Parent = holder
    })
    local line = New("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.fromOffset(0,18), BackgroundColor3 = C.Electric, BorderSizePixel = 0, Parent = holder })
    Grad(line, ColorSequence.new(C.Electric, C.BG_Dark))
end

function Tab:AddToggle(str, default, callback)
    local row = self:CreateRow(38)
    New("TextLabel", { BackgroundTransparency = 1, Text = str, Font = FONT_BODY, TextSize = 13, TextColor3 = C.Text, Position = UDim2.fromOffset(12,0), Size = UDim2.new(1,-70,1,0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    
    local track = New("Frame", { AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-12,0.5,0), Size = UDim2.fromOffset(40,20), BackgroundColor3 = C.BG_Dark, BorderSizePixel = 0, Parent = row })
    Corner(track, 10)
    local stroke = Stroke(track, C.Blue, 1.5, 0)
    local knob = New("Frame", { AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,2,0.5,0), Size = UDim2.fromOffset(16,16), BackgroundColor3 = C.TextDim, BorderSizePixel = 0, Parent = track })
    Corner(knob, 8)
    
    local state = default and true or false
    local function render(anim)
        if anim then
            Tween(knob, 0.2, { Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0), BackgroundColor3 = state and C.White or C.TextDim }, EASE_BACK)
            Tween(track, 0.2, { BackgroundColor3 = state and C.Electric or C.BG_Dark })
            Tween(stroke, 0.2, { Transparency = state and 0.2 or 0 })
        else
            knob.Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)
            knob.BackgroundColor3 = state and C.White or C.TextDim
            track.BackgroundColor3 = state and C.Electric or C.BG_Dark
        end
    end
    render(false)
    
    local btn = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1,1), Parent = row })
    btn.MouseButton1Click:Connect(function()
        state = not state
        render(true)
        if callback then callback(state) end
    end)
    
    return { Set = function(_, v) state = v; render(false) end, Get = function() return state end }
end

function Tab:AddButton(str, callback)
    local row = self:CreateRow(34)
    local btn = New("TextButton", { BackgroundTransparency = 1, Text = str, Font = FONT_BOLD, TextSize = 13, TextColor3 = C.White, Size = UDim2.fromScale(1,1), Parent = row })
    btn.MouseEnter:Connect(function() Tween(row, 0.1, { BackgroundTransparency = 0, BackgroundColor3 = C.Electric }) end)
    btn.MouseLeave:Connect(function() Tween(row, 0.1, { BackgroundTransparency = 0.2, BackgroundColor3 = C.BG_Row }) end)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
end

function Tab:AddSlider(str, min, max, default, callback, step)
    local row = self:CreateRow(48)
    New("TextLabel", { BackgroundTransparency = 1, Text = str, Font = FONT_BODY, TextSize = 13, TextColor3 = C.Text, Position = UDim2.fromOffset(12,6), Size = UDim2.new(1,-50,0,16), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local valLbl = New("TextLabel", { BackgroundTransparency = 1, Text = tostring(default), Font = FONT_BOLD, TextSize = 12, TextColor3 = C.Cyan, Position = UDim2.new(1,-50,0,6), Size = UDim2.fromOffset(40,16), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
    
    local bar = New("Frame", { Position = UDim2.fromOffset(12,30), Size = UDim2.new(1,-24,0,6), BackgroundColor3 = C.BG_Dark, BorderSizePixel = 0, Parent = row })
    Corner(bar, 3)
    local fill = New("Frame", { Size = UDim2.fromScale((default-min)/(max-min),1), BackgroundColor3 = C.Electric, BorderSizePixel = 0, Parent = bar })
    Corner(fill, 3)
    Grad(fill, ColorSequence.new(C.Blue, C.Electric))
    
    local knob = New("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale((default-min)/(max-min),0.5), Size = UDim2.fromOffset(12,12), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = bar })
    Corner(knob, 6)
    
    local val = default
    local dragging = false
    
    local hit = New("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0,20), Size = UDim2.new(1,0,0,28), Parent = row })
    
    local function update(x)
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local pct = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
        val = math.floor((min + (max-min)*pct) / step + 0.5) * step
        valLbl.Text = tostring(val)
        fill.Size = UDim2.fromScale(pct, 1)
        knob.Position = UDim2.fromScale(pct, 0.5)
        if callback then callback(val) end
    end
    
    hit.InputBegan:Connect(function(input)
        if IsPress(input) then
            dragging = true
            update(input.Position.X)
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    
    return { Get = function() return val end }
end

function Tab:AddDropdown(str, options, default, callback, multi)
    local row = self:CreateRow(38)
    row.ClipsDescendants = true
    New("TextLabel", { BackgroundTransparency = 1, Text = str, Font = FONT_BODY, TextSize = 13, TextColor3 = C.Text, Position = UDim2.fromOffset(12,0), Size = UDim2.new(0.4,0,0,38), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    
    local valLbl = New("TextLabel", { BackgroundTransparency = 1, Text = tostring(default), Font = FONT_BOLD, TextSize = 12, TextColor3 = C.Cyan, Position = UDim2.new(0.4,0,0,0), Size = UDim2.new(0.6,-12,0,38), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
    
    local list = New("Frame", { Position = UDim2.fromOffset(10,38), Size = UDim2.new(1,-20,0,0), BackgroundTransparency = 1, Parent = row })
    New("UIListLayout", { Padding = UDim.new(0,4), Parent = list })
    
    local isOpen = false
    local current = default
    local btns = {}
    
    local function setOpen(state)
        isOpen = state
        Tween(row, 0.2, { Size = UDim2.new(1,-10,0, state and (38 + #options * 28 + 10) or 38) })
    end
    
    for i, opt in ipairs(options) do
        local b = New("TextButton", { Size = UDim2.new(1,0,0,24), BackgroundColor3 = C.BG_Panel, Text = " " .. opt, Font = FONT_BODY, TextSize = 12, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = list })
        Corner(b, 4)
        b.MouseButton1Click:Connect(function()
            current = opt
            valLbl.Text = opt
            setOpen(false)
            if callback then callback(opt) end
        end)
    end
    
    local head = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,0,38), Parent = row })
    head.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
end

-- ==========================================
-- VENTANA PRINCIPAL
-- ==========================================
function UI_Library.CreateWindow(cfg)
    cfg = cfg or {}
    if UI_Library._current then UI_Library._current:Destroy() end
    
    local Window = { Tabs = {}, Active = nil, State = "open" }
    UI_Library._current = Window
    
    -- GUI
    local gui = New("ScreenGui", { Name = "DeepBlueUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999 })
    pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    Window.Gui = gui
    
    -- Main Frame (RECTÁNGULO ANCHO) + CLIPS
    local W, H = 620, 380
    local main = New("Frame", { 
        AnchorPoint = Vector2.new(0.5,0.5), 
        Position = UDim2.fromScale(0.5,0.5), 
        Size = UDim2.fromOffset(W, H), 
        BackgroundColor3 = C.BG_Panel, 
        BorderSizePixel = 0,
        ClipsDescendants = true -- 🔥 CORTA LO QUE SE SALGA
    }, gui)
    Corner(main, 12)
    local mainStroke = Stroke(main, C.Electric, 2, 0)
    Grad(mainStroke, ColorSequence.new(C.Electric, C.Blue))
    Grad(main, ColorSequence.new(C.BG_Panel, C.BG_Dark), 90)
    
    local scale = New("UIScale", { Scale = 0.8 }, main)
    Tween(scale, 0.4, { Scale = 1 }, EASE_BACK)
    
    -- Top Bar
    local top = New("Frame", { Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, Parent = main })
    if cfg.Logo and cfg.Logo ~= "" then
        New("ImageLabel", { Size = UDim2.fromOffset(32,32), Position = UDim2.fromOffset(16,8), BackgroundTransparency = 1, Image = cfg.Logo, Parent = top })
    else
        BuildLogo(top, 28, UDim2.fromOffset(16,10))
    end
    New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "DEEP BLUE HUB", Font = FONT_TITLE, TextSize = 16, TextColor3 = C.White, Position = UDim2.fromOffset(56, 6), Size = UDim2.new(1,-100,0,20), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Subtitle or "CRYSTAL EDITION", Font = FONT_BODY, TextSize = 11, TextColor3 = C.Cyan, Position = UDim2.fromOffset(56, 26), Size = UDim2.new(1,-100,0,14), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    
    local closeBtn = New("TextButton", { AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-16,0.5,0), Size = UDim2.fromOffset(28,28), BackgroundColor3 = C.BG_Dark, Text = "×", Font = FONT_TITLE, TextSize = 18, TextColor3 = C.Cyan, Parent = top })
    Corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end)
    
    -- Body
    local side = New("Frame", { 
        Position = UDim2.fromOffset(16,60), 
        Size = UDim2.fromOffset(130, H-76), 
        BackgroundColor3 = C.BG_Dark, 
        BackgroundTransparency = 0.3, 
        BorderSizePixel = 0, 
        Parent = main,
        ClipsDescendants = true -- 🔥 CORTA LO QUE SE SALGA
    })
    Corner(side, 8)
    Stroke(side, C.Electric, 1, 0.8)
    New("UIListLayout", { Padding = UDim.new(0,6), Parent = side })
    
    local content = New("Frame", { 
        Position = UDim2.fromOffset(154,60), 
        Size = UDim2.new(1,-170,H-76), 
        BackgroundColor3 = C.BG_Dark, 
        BackgroundTransparency = 0.5, 
        BorderSizePixel = 0, 
        Parent = main,
        ClipsDescendants = true -- 🔥 CORTA LO QUE SE SALGA
    })
    Corner(content, 8)
    
    -- Drag
    local drag, dStart, dPos
    top.InputBegan:Connect(function(i)
        if IsPress(i) then drag, dStart, dPos = true, i.Position, main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            main.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X, dPos.Y.Scale, dPos.Y.Offset + d.Y)
        end
    end)
    
    -- Methods
    function Window:_Select(t)
        if Window.Active == t then return end
        if Window.Active then Window.Active.Page.Visible = false; Window.Active.Btn.BackgroundTransparency = 1 end
        Window.Active = t
        t.Page.Visible = true
        Tween(t.Btn, 0.2, { BackgroundTransparency = 0.8, BackgroundColor3 = C.Electric })
    end
    
    function Window:CreateTab(name)
        local t = setmetatable({ Window = Window, Name = name }, Tab)
        
        local btn = New("TextButton", { Size = UDim2.new(1,0,0,34), BackgroundColor3 = C.Electric, BackgroundTransparency = 1, Text = " " .. name, Font = FONT_BOLD, TextSize = 12, TextColor3 = C.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = side })
        Corner(btn, 6)
        btn.MouseButton1Click:Connect(function() Window:_Select(t) end)
        
        local page = New("ScrollingFrame", { 
            Size = UDim2.fromScale(1,1), 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0, 
            ScrollBarThickness = 2, 
            ScrollBarImageColor3 = C.Electric, 
            Visible = false, 
            Parent = content,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar -- 🔥 Para que el scroll no tape los botones
        })
        New("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        New("UIPadding", { PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), PaddingBottom = UDim.new(0,10) }, page)
        
        t.Btn, t.Page = btn, page
        Window.Tabs[#Window.Tabs+1] = t
        if #Window.Tabs == 1 then Window:_Select(t) end
        return t
    end
    
    function Window:Notify(n)
        local nt = New("Frame", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-16,0,16), Size = UDim2.fromOffset(250,50), BackgroundColor3 = C.BG_Panel, BorderSizePixel = 0, Parent = gui })
        Corner(nt, 8)
        Stroke(nt, C.Electric, 2)
        New("TextLabel", { BackgroundTransparency = 1, Text = n.Title or "Info", Font = FONT_BOLD, TextSize = 14, TextColor3 = C.Cyan, Position = UDim2.fromOffset(10,6), Size = UDim2.new(1,-20,0,20), TextXAlignment = Enum.TextXAlignment.Left, Parent = nt })
        New("TextLabel", { BackgroundTransparency = 1, Text = n.Content or "", Font = FONT_BODY, TextSize = 12, TextColor3 = C.White, Position = UDim2.fromOffset(10,26), Size = UDim2.new(1,-20,0,20), TextXAlignment = Enum.TextXAlignment.Left, Parent = nt })
        Tween(nt, 0.3, { Position = UDim2.new(1,-16,0,80) }, EASE_BACK)
        task.delay(n.Duration or 3, function() 
            Tween(nt, 0.3, { Position = UDim2.new(1,300,0,80) }, EASE_BACK, Enum.EasingDirection.In)
            task.wait(0.3) nt:Destroy() 
        end)
    end
    
    function Window:Destroy()
        if gui then gui:Destroy() end
    end
    
    return Window
end

return UI_Library
