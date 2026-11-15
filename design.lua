--[[
    design.lua  |  UI_Library "Deep Blue" (cristal electrico + marco de hielo)  |  NUCLEO
    - Solo TweenService para animar (sin RenderStepped).
    - API:
        local Window = UI_Library.CreateWindow({ Title, Subtitle, Theme, Logo, IceFrame, ToggleKey })
        local Tab    = Window:CreateTab(name)
        Window:Notify({ Title, Content, Type = "Info|Success|Warning|Error", Duration })
        Window:Destroy()
        Tab:AddSection / AddToggle / AddSlider / AddButton / AddDropdown / AddTextbox / AddKeybind / AddInfo
    - Cada metodo acepta tabla de opciones o argumentos posicionales.
    - Ganchos para assets.lua: Window.TabMethods, Window.Util, Window.Theme, Tab:CreateRow(h), Tab.Page
    - Logo: por defecto se dibuja la cola de ballena con Frames (sin assets).
      Si prefieres tu imagen: CreateWindow({ Logo = "rbxassetid://123456" }).
    - IceFrame = false desactiva el marco de cristales de hielo (mas ligero). En tactil se reduce solo.
]]

local UI_Library = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local DefaultTheme = {
	Deep = Color3.fromHex("0B132B"),
	Dark = Color3.fromHex("050A18"),
	Top = Color3.fromHex("0F1D40"),
	Electric = Color3.fromHex("18C8FF"),
	Cyan = Color3.fromHex("70D8FF"),
	Blue = Color3.fromHex("1F5BFF"),
	Text = Color3.fromRGB(255, 255, 255),
	Sub = Color3.fromHex("8FB3DD"),
	Muted = Color3.fromHex("6F86B8"),
	Track = Color3.fromHex("1A2B5A"),
	RowTop = Color3.fromHex("152A5C"),
	RowBottom = Color3.fromHex("0D1A3D"),
	Success = Color3.fromHex("3DFFA8"),
	Warning = Color3.fromHex("FFC857"),
	Error = Color3.fromHex("FF5C7A"),
	Font = Enum.Font.GothamBold,
	FontHeavy = Enum.Font.GothamBlack,
	Logo = "", -- vacio = cola de ballena dibujada con Frames
}

--------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------
local function New(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function Tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Corner(o, r)
	return New("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function Stroke(o, color, thick, transp)
	return New("UIStroke", {
		Color = color,
		Thickness = thick or 1,
		Transparency = transp or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function Grad(parent, stops, rot, transp)
	local kps = {}
	for _, s in ipairs(stops) do
		kps[#kps + 1] = ColorSequenceKeypoint.new(s[1], s[2])
	end
	local g = New("UIGradient", { Color = ColorSequence.new(kps), Rotation = rot or 0 }, parent)
	if transp then
		g.Transparency = transp
	end
	return g
end

-- Panel de cristal: degradado vertical Top -> Deep -> Dark + borde con degradado
local function Glass(f, T, transp, thick)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BackgroundTransparency = transp or 0
	Grad(f, { { 0, T.Top }, { 0.45, T.Deep }, { 1, T.Dark } }, 90)
	local s = Stroke(f, T.Electric, thick or 2.2, 0)
	Grad(s, { { 0, Color3.new(1, 1, 1) }, { 0.4, T.Cyan }, { 1, T.Blue } }, 45)
	return s
end

local function Lbl(parent, props, T)
	local p = {
		BackgroundTransparency = 1,
		Font = T.Font,
		TextSize = 13,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
	}
	for k, v in pairs(props) do
		p[k] = v
	end
	return New("TextLabel", p, parent)
end

local function ClickArea(parent)
	return New("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
end

local function IsPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- Acepta tabla de opciones o argumentos posicionales
local function Opts(keys, ...)
	local first = ...
	if type(first) == "table" and getmetatable(first) == nil and (first.Name ~= nil or first.Title ~= nil or first.Options ~= nil or first.Callback ~= nil or first.Default ~= nil or first.Min ~= nil or first.Content ~= nil) then
		return first
	end
	local args, t = { ... }, {}
	for i, k in ipairs(keys) do
		t[k] = args[i]
	end
	return t
end

local function Fire(cb, ...)
	if type(cb) == "function" then
		task.spawn(cb, ...)
	end
end

local function LogoValid(id)
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

-- Esquinas diagonales de las filas (look "chaflan")
local function Diag(row, T)
	for _, p in ipairs({ { 1, -4.5, 0, 4.5 }, { 0, 4.5, 1, -4.5 } }) do
		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(p[1], p[2], p[3], p[4]),
			Size = UDim2.fromOffset(12, 2),
			Rotation = 45,
			BackgroundColor3 = T.Cyan,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, row)
	end
end

-- Cola de ballena hecha con Frames (mismas proporciones que el preview)
local function BuildLogo(parent, T, size, pos, anchor)
	local c = New("Frame", {
		Name = "WhaleLogo",
		Size = UDim2.fromOffset(size, size),
		Position = pos,
		AnchorPoint = anchor or Vector2.new(0, 0),
		BackgroundTransparency = 1,
	}, parent)
	local W, B, E = Color3.new(1, 1, 1), T.Blue, T.Electric
	local parts = {
		{ 0.10, 0.40, 0.50, 0.58, 0, W },
		{ 0.46, 0.12, 0.30, 0.36, 28, W },
		{ 0.46, 0.12, 0.70, 0.36, -28, W },
		{ 0.30, 0.06, 0.32, 0.38, 28, B },
		{ 0.30, 0.06, 0.68, 0.38, -28, B },
		{ 0.62, 0.07, 0.50, 0.84, 0, E },
		{ 0.40, 0.06, 0.52, 0.93, 0, B },
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
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	end
	return c
end

local function PlaceLogo(parent, T, size, pos, anchor)
	if LogoValid(T.Logo) then
		return New("ImageLabel", {
			Size = UDim2.fromOffset(size, size),
			Position = pos,
			AnchorPoint = anchor or Vector2.new(0, 0),
			BackgroundTransparency = 1,
			Image = T.Logo,
		}, parent)
	end
	return BuildLogo(parent, T, size, pos, anchor)
end

-- Triangulo rectangulo dentro de un rect (w x h). "corner" = vertice del angulo recto.
-- Frame + UIGradient de transparencia escalonada: corte diagonal limpio, sin imagenes.
local function RightTri(parent, x, y, w, h, corner, color, transp)
	if w < 0.5 or h < 0.5 then
		return
	end
	local f = New("Frame", {
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = color,
		BackgroundTransparency = transp or 0,
		BorderSizePixel = 0,
	}, parent)
	local a = math.deg(math.atan2(w, h))
	local second = (corner == "BR" or corner == "TR")
	local neg = (corner == "BL" or corner == "TR")
	local K = NumberSequenceKeypoint.new
	local seq = second and { K(0, 1), K(0.495, 1), K(0.505, 0), K(1, 0) } or { K(0, 0), K(0.495, 0), K(0.505, 1), K(1, 1) }
	New("UIGradient", { Rotation = neg and -a or a, Transparency = NumberSequence.new(seq) }, f)
	return f
end

-- Marco de hielo: cristales facetados (cada uno = 2 triangulos, cara clara + cara oscura + arista).
-- Se generan una sola vez (semilla fija) y se posicionan por escala alrededor de la ventana.
local function BuildIce(parent, T, light)
	local seed = 7
	local function rnd()
		seed = (seed * 16807) % 2147483647
		return seed / 2147483647
	end
	local WHITE = Color3.new(1, 1, 1)
	local holder = New("Frame", { Name = "Ice", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, parent)

	-- angle: grados horarios desde "arriba"; bw = ancho de base; h = alto; lean = posicion del apice (0..1)
	local function spike(ox, oxo, oy, oyo, angle, bw, h, lean, litLeft)
		local a = math.rad(angle)
		local mid = h / 2 - 3
		local c = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(ox, oxo + math.sin(a) * mid, oy, oyo - math.cos(a) * mid),
			Size = UDim2.fromOffset(bw, h),
			Rotation = angle,
			BackgroundTransparency = 1,
		}, holder)
		local xp = bw * lean
		local lit = T.Cyan:Lerp(WHITE, 0.25 + rnd() * 0.65)
		local dark = T.Blue:Lerp(T.Deep, 0.15 + rnd() * 0.5)
		RightTri(c, 0, 0, xp, h, "BR", litLeft and lit or dark, litLeft and 0.05 or 0.12)
		RightTri(c, xp, 0, bw - xp, h, "BL", litLeft and dark or lit, litLeft and 0.12 or 0.05)
		New("Frame", {
			Position = UDim2.fromOffset(xp - 0.5, 0),
			Size = UDim2.fromOffset(1, h),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
		}, c)
	end

	local n = light and 6 or 12
	local edges = {
		{ 0, function(t) return t, 0, 0, 0 end },
		{ 90, function(t) return 1, 0, t, 0 end },
		{ 180, function(t) return t, 0, 1, 0 end },
		{ 270, function(t) return 0, 0, t, 0 end },
	}
	for _, e in ipairs(edges) do
		local alongX = (e[1] == 0 or e[1] == 180)
		for i = 1, n do
			local t = math.clamp((i - 0.5 + (rnd() - 0.5) * 0.5) / n, 0.08, 0.92)
			local ox, oxo, oy, oyo = e[2](t)
			local h = 14 + rnd() * 30
			if rnd() < 0.2 then
				h = h + 16
			end
			local bw = 16 + rnd() * 22
			local lit = rnd() < 0.5
			spike(ox, oxo, oy, oyo, e[1] + (rnd() - 0.5) * 24, bw, h, 0.25 + rnd() * 0.5, lit)
			if not light then
				local j = (rnd() - 0.5) * 14
				spike(ox, oxo + (alongX and j or 0), oy, oyo + (alongX and 0 or j), e[1] + (rnd() - 0.5) * 50, bw * 0.6, h * 0.55, 0.3 + rnd() * 0.4, not lit)
			end
		end
	end
	-- Cumulos en las esquinas
	local corners = { { 0, 0, 315 }, { 1, 0, 45 }, { 1, 1, 135 }, { 0, 1, 225 } }
	for _, c in ipairs(corners) do
		spike(c[1], 0, c[2], 0, c[3], 34 + rnd() * 14, 48 + rnd() * 26, 0.5, rnd() < 0.5)
		spike(c[1], 0, c[2], 0, c[3] + 26, 20 + rnd() * 8, 26 + rnd() * 14, 0.4, rnd() < 0.5)
		spike(c[1], 0, c[2], 0, c[3] - 26, 20 + rnd() * 8, 26 + rnd() * 14, 0.6, rnd() < 0.5)
	end
	return holder
end

--------------------------------------------------------------------
-- Metodos de Tab (compartidos; assets.lua puede extender esta tabla)
--------------------------------------------------------------------
local TabMethods = {}
TabMethods.__index = TabMethods

-- Devuelve: row, rowStroke
function TabMethods:CreateRow(height)
	local T = self.Theme
	self._order = self._order + 1
	local r = New("Frame", {
		Size = UDim2.new(1, -4, 0, height),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = self._order,
	}, self.Page)
	Corner(r, 4)
	Grad(r, { { 0, T.RowTop }, { 1, T.RowBottom } }, 90)
	local s = Stroke(r, T.Electric, 1, 0.8)
	Diag(r, T)
	return r, s
end

function TabMethods:Select()
	self.Window:_SelectTab(self)
end

function TabMethods:AddSection(...)
	local o = Opts({ "Name" }, ...)
	local T = self.Theme
	self._order = self._order + 1
	local f = New("Frame", {
		Size = UDim2.new(1, -4, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
	}, self.Page)
	local l = Lbl(f, {
		Text = string.upper(tostring(o.Name or "Section")),
		Font = T.FontHeavy,
		TextSize = 11,
		TextColor3 = T.Cyan,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(4, 0),
	}, T)
	local line = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = T.Electric,
		BorderSizePixel = 0,
	}, f)
	New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }) }, line)
	local obj = { Frame = f }
	function obj:SetText(t)
		l.Text = string.upper(tostring(t))
	end
	return obj
end

function TabMethods:AddToggle(...)
	local o = Opts({ "Name", "Default", "Callback" }, ...)
	local T = self.Theme
	local row, rowStroke = self:CreateRow(38)
	Lbl(row, { Text = o.Name or "Toggle", Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(12, 0) }, T)
	local track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = T.Track,
		BorderSizePixel = 0,
	}, row)
	Corner(track, 11)
	local tStroke = Stroke(track, T.Cyan, 1.5, 0.7)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = T.Muted,
		BorderSizePixel = 0,
	}, track)
	Corner(knob, 7)
	local btn = ClickArea(row)

	local obj = { Frame = row, Value = false }
	local function apply(v, silent)
		obj.Value = v and true or false
		local on = obj.Value
		Tween(track, 0.16, { BackgroundColor3 = on and T.Electric or T.Track })
		Tween(tStroke, 0.16, { Thickness = on and 3 or 1.5, Transparency = on and 0.35 or 0.7 })
		Tween(knob, 0.16, { Position = on and UDim2.new(0, 25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = on and Color3.new(1, 1, 1) or T.Muted })
		Tween(rowStroke, 0.16, { Transparency = on and 0.45 or 0.8 })
		if not silent then
			Fire(o.Callback, on)
		end
	end
	function obj:Set(v)
		apply(v, false)
	end
	function obj:Get()
		return obj.Value
	end
	btn.MouseButton1Click:Connect(function()
		apply(not obj.Value, false)
	end)
	apply(o.Default == true, true)
	return obj
end

function TabMethods:AddSlider(...)
	local o = Opts({ "Name", "Min", "Max", "Default", "Increment", "Suffix", "Callback" }, ...)
	local T = self.Theme
	local min, max = o.Min or 0, o.Max or 100
	local inc = o.Increment or 1
	local suffix = o.Suffix or ""
	local row = self:CreateRow(54)
	Lbl(row, { Text = o.Name or "Slider", Size = UDim2.new(1, -90, 0, 20), Position = UDim2.fromOffset(12, 8) }, T)
	local valLbl = Lbl(row, {
		Text = "",
		Size = UDim2.fromOffset(78, 20),
		Position = UDim2.new(1, -90, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = T.Cyan,
	}, T)
	local bar = New("Frame", {
		Position = UDim2.new(0, 12, 0, 36),
		Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = T.Track,
		BorderSizePixel = 0,
	}, row)
	Corner(bar, 3)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
	Corner(fill, 3)
	Grad(fill, { { 0, T.Blue }, { 1, T.Cyan } }, 0)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bar)
	Corner(knob, 7)
	Stroke(knob, T.Electric, 2, 0)
	local hit = New("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 28),
		AutoButtonColor = false,
		ZIndex = 3,
	}, row)

	local obj = { Frame = row, Value = min }
	local function render(v)
		local rel = (max == min) and 0 or (v - min) / (max - min)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		valLbl.Text = tostring(v) .. suffix
	end
	local function normalize(v)
		v = math.clamp(v, min, max)
		v = math.floor((v - min) / inc + 0.5) * inc + min
		v = math.clamp(v, min, max)
		return math.floor(v * 10000 + 0.5) / 10000
	end
	local function setValue(v, silent)
		v = normalize(v)
		if v == obj.Value and not silent then
			return
		end
		obj.Value = v
		render(v)
		if not silent then
			Fire(o.Callback, v)
		end
	end
	function obj:Set(v)
		setValue(v, false)
	end
	function obj:Get()
		return obj.Value
	end

	local dragging = false
	local function fromX(x)
		local w = bar.AbsoluteSize.X
		if w <= 0 then
			return
		end
		local rel = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
		setValue(min + (max - min) * rel, false)
	end
	hit.InputBegan:Connect(function(input)
		if IsPress(input) then
			dragging = true
			fromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	self.Window:_Track(UIS.InputChanged:Connect(function(input)
		if dragging and IsMove(input) then
			fromX(input.Position.X)
		end
	end))

	obj.Value = normalize(o.Default or min)
	render(obj.Value)
	return obj
end

function TabMethods:AddButton(...)
	local o = Opts({ "Name", "Callback" }, ...)
	local T = self.Theme
	self._order = self._order + 1
	local row = New("Frame", {
		Size = UDim2.new(1, -4, 0, 36),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = self._order,
	}, self.Page)
	Corner(row, 4)
	Grad(row, { { 0, T.Blue }, { 1, T.Electric } }, 0)
	Stroke(row, T.Cyan, 1.2, 0.6)
	Diag(row, T)
	local btn = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = o.Name or "Button",
		Font = T.FontHeavy,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
	}, row)
	local obj = { Frame = row }
	local function click()
		Tween(row, 0.07, { BackgroundTransparency = 0.45 })
		task.delay(0.07, function()
			if row.Parent then
				Tween(row, 0.18, { BackgroundTransparency = 0 })
			end
		end)
		Fire(o.Callback)
	end
	btn.MouseButton1Click:Connect(click)
	function obj:SetText(t)
		btn.Text = tostring(t)
	end
	function obj:Fire()
		click()
	end
	return obj
end

function TabMethods:AddDropdown(...)
	local o = Opts({ "Name", "Options", "Default", "Callback" }, ...)
	local T = self.Theme
	local multi = o.Multi == true
	local options = o.Options or {}
	local HEAD = 38
	local row = self:CreateRow(HEAD)
	row.ClipsDescendants = true
	Lbl(row, { Text = o.Name or "Dropdown", Size = UDim2.new(0.45, -12, 0, HEAD), Position = UDim2.fromOffset(12, 0) }, T)
	local valLbl = Lbl(row, {
		Text = "",
		Size = UDim2.new(0.55, -24, 0, HEAD),
		Position = UDim2.new(0.45, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = T.Cyan,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, T)
	local head = New("TextButton", {
		Size = UDim2.new(1, 0, 0, HEAD),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, row)
	local list = New("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEAD),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.Electric,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, row)
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local obj = { Frame = row }
	local selected = multi and {} or nil
	local buttons = {}
	local open = false

	local function isSel(opt)
		if multi then
			return selected[opt] == true
		end
		return selected == opt
	end
	local function getValue()
		if multi then
			local t = {}
			for _, opt in ipairs(options) do
				if selected[opt] then
					t[#t + 1] = opt
				end
			end
			return t
		end
		return selected
	end
	local function display()
		if multi then
			local names = {}
			for i, x in ipairs(getValue()) do
				names[i] = tostring(x)
			end
			valLbl.Text = #names > 0 and table.concat(names, ", ") or "Ninguno"
		else
			valLbl.Text = selected ~= nil and tostring(selected) or "Ninguno"
		end
	end
	local function paint()
		for opt, b in pairs(buttons) do
			local on = isSel(opt)
			Tween(b, 0.12, { BackgroundTransparency = on and 0.6 or 0.4, BackgroundColor3 = on and T.Electric or T.Track, TextColor3 = on and Color3.new(1, 1, 1) or T.Sub })
		end
	end
	local function listHeight()
		local n = math.min(#options, 5)
		return n > 0 and (n * 26 + (n - 1) * 4) or 0
	end
	local function setOpen(state)
		open = state
		local h = listHeight()
		list.Size = UDim2.new(1, -16, 0, h)
		Tween(row, 0.18, { Size = UDim2.new(1, -4, 0, state and (HEAD + h + 8) or HEAD) })
	end
	local function build()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		buttons = {}
		for i, opt in ipairs(options) do
			local b = New("TextButton", {
				Size = UDim2.new(1, -4, 0, 26),
				BackgroundColor3 = T.Track,
				BackgroundTransparency = 0.4,
				Text = "   " .. tostring(opt),
				Font = T.Font,
				TextSize = 12,
				TextColor3 = T.Sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, list)
			Corner(b, 6)
			buttons[opt] = b
			b.MouseButton1Click:Connect(function()
				if multi then
					selected[opt] = not selected[opt] or nil
				else
					selected = opt
					setOpen(false)
				end
				display()
				paint()
				Fire(o.Callback, getValue())
			end)
		end
		paint()
	end

	head.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	function obj:Get()
		return getValue()
	end
	function obj:Set(v)
		if multi then
			selected = {}
			for _, x in ipairs(type(v) == "table" and v or {}) do
				selected[x] = true
			end
		else
			selected = v
		end
		display()
		paint()
		Fire(o.Callback, getValue())
	end
	function obj:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then
			selected = multi and {} or nil
		end
		build()
		display()
		if open then
			setOpen(true)
		end
	end

	if multi then
		for _, x in ipairs(type(o.Default) == "table" and o.Default or {}) do
			selected[x] = true
		end
	else
		selected = o.Default
	end
	build()
	display()
	return obj
end

function TabMethods:AddTextbox(...)
	local o = Opts({ "Name", "Default", "Placeholder", "Callback" }, ...)
	local T = self.Theme
	local row = self:CreateRow(38)
	Lbl(row, { Text = o.Name or "Textbox", Size = UDim2.new(0.4, -12, 1, 0), Position = UDim2.fromOffset(12, 0) }, T)
	local boxBg = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0.6, -20, 0, 24),
		BackgroundColor3 = T.Track,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, row)
	Corner(boxBg, 6)
	local stroke = Stroke(boxBg, T.Electric, 1, 0.5)
	local box = New("TextBox", {
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		BackgroundTransparency = 1,
		Text = tostring(o.Default or ""),
		PlaceholderText = o.Placeholder or "...",
		PlaceholderColor3 = T.Muted,
		Font = T.Font,
		TextSize = 12,
		TextColor3 = T.Cyan,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = o.ClearOnFocus == true,
		ClipsDescendants = true,
	}, boxBg)
	box.Focused:Connect(function()
		Tween(stroke, 0.12, { Transparency = 0, Thickness = 1.5 })
	end)
	box.FocusLost:Connect(function(enter)
		Tween(stroke, 0.12, { Transparency = 0.5, Thickness = 1 })
		Fire(o.Callback, box.Text, enter)
	end)
	local obj = { Frame = row }
	function obj:Get()
		return box.Text
	end
	function obj:Set(t)
		box.Text = tostring(t)
	end
	return obj
end

function TabMethods:AddKeybind(...)
	local o = Opts({ "Name", "Default", "Callback", "Changed" }, ...)
	local T = self.Theme
	local key = o.Default or Enum.KeyCode.Unknown
	if type(key) == "string" then
		key = Enum.KeyCode[key] or Enum.KeyCode.Unknown
	end
	local row = self:CreateRow(38)
	Lbl(row, { Text = o.Name or "Keybind", Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0) }, T)
	local kb = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(92, 24),
		BackgroundColor3 = T.Track,
		BackgroundTransparency = 0.3,
		Text = "",
		Font = T.Font,
		TextSize = 12,
		TextColor3 = T.Cyan,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Corner(kb, 6)
	local kStroke = Stroke(kb, T.Electric, 1, 0.5)

	local obj = { Frame = row }
	local listening = false
	local function show()
		kb.Text = listening and "..." or (key == Enum.KeyCode.Unknown and "Ninguna" or key.Name)
		Tween(kStroke, 0.12, { Transparency = listening and 0 or 0.5, Thickness = listening and 2 or 1 })
	end
	kb.MouseButton1Click:Connect(function()
		listening = true
		show()
	end)
	self.Window:_Track(UIS.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode ~= Enum.KeyCode.Escape then
					key = input.KeyCode
					Fire(o.Changed, key)
				end
				show()
			end
			return
		end
		if not gp and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
			Fire(o.Callback, key)
		end
	end))
	function obj:Get()
		return key
	end
	function obj:Set(k)
		key = k or Enum.KeyCode.Unknown
		show()
	end
	show()
	return obj
end

function TabMethods:AddInfo(...)
	local o = Opts({ "Title", "Content" }, ...)
	local T = self.Theme
	local row = self:CreateRow(40)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, -4, 0, 0)
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, row)
	New("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 12) }, holder)
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	local bar = New("Frame", {
		Position = UDim2.fromOffset(6, 8),
		Size = UDim2.new(0, 3, 1, -16),
		BackgroundColor3 = T.Electric,
		BorderSizePixel = 0,
	}, row)
	Corner(bar, 2)
	local title = Lbl(holder, {
		Text = o.Title or o.Name or "",
		Font = T.FontHeavy,
		TextColor3 = T.Cyan,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Visible = (o.Title or o.Name) ~= nil,
	}, T)
	local content = Lbl(holder, {
		Text = o.Content or "",
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextColor3 = T.Sub,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
	}, T)
	local obj = { Frame = row }
	function obj:Set(t, c)
		if t then
			title.Text = tostring(t)
			title.Visible = true
		end
		if c then
			content.Text = tostring(c)
		end
	end
	return obj
end

--------------------------------------------------------------------
-- Ventana
--------------------------------------------------------------------
function UI_Library.CreateWindow(cfg)
	cfg = cfg or {}
	local T = {}
	for k, v in pairs(DefaultTheme) do
		T[k] = v
	end
	if type(cfg.Theme) == "table" then
		for k, v in pairs(cfg.Theme) do
			T[k] = v
		end
	end
	if cfg.Logo then
		T.Logo = cfg.Logo
	end

	local Window = {
		Theme = T,
		Tabs = {},
		Active = nil,
		TabMethods = TabMethods,
		Util = { New = New, Tween = Tween, Corner = Corner, Stroke = Stroke, Glass = Glass, Grad = Grad, Lbl = Lbl, Fire = Fire, Opts = Opts, Diag = Diag, BuildLogo = BuildLogo },
	}
	local conns, destroyed = {}, false
	function Window:_Track(c)
		conns[#conns + 1] = c
		return c
	end
	Window.Util.Track = function(c)
		return Window:_Track(c)
	end

	-- ScreenGui
	local guiName = cfg.Name or "DeepBlueUI"
	local gui = New("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	for _, c in ipairs(gui.Parent:GetChildren()) do
		if c.Name == guiName and c ~= gui then
			c:Destroy()
		end
	end
	Window.Gui = gui

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local W = math.min(620, vp.X - 80)
	local H = math.min(360, vp.Y - 80)
	local MIN_W, MIN_H = math.min(460, vp.X - 20), math.min(280, vp.Y - 20)
	local MAX_W, MAX_H = 900, 600
	local curW, curH = W, H
	local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled

	-- Ventana principal
	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H),
		BorderSizePixel = 0,
	}, gui)
	Corner(main, 16)
	Glass(main, T, 0, 2.2)
	local scale = New("UIScale", { Scale = 0.6 }, main)
	Window.Main = main

	if cfg.IceFrame ~= false then
		BuildIce(main, T, touch)
	end
	-- borde interior
	local inner = New("Frame", {
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1,
	}, main)
	Corner(inner, 12)
	Stroke(inner, T.Cyan, 1, 0.65)

	-- Barra superior
	local top = New("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, main)
	PlaceLogo(top, T, 28, UDim2.fromOffset(22, 8))
	local titleLbl = Lbl(top, {
		Text = cfg.Title or "Deep Blue Hub",
		Font = T.FontHeavy,
		TextSize = 15,
		Position = UDim2.fromOffset(60, 6),
		Size = UDim2.new(1, -150, 0, 18),
	}, T)
	local subLbl = Lbl(top, {
		Text = cfg.Subtitle or "",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = T.Cyan,
		Position = UDim2.fromOffset(60, 24),
		Size = UDim2.new(1, -150, 0, 14),
	}, T)
	local function TopButton(text, xOff, hoverColor)
		local b = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOff, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = T.Track,
			BackgroundTransparency = 0.35,
			Text = text,
			Font = T.FontHeavy,
			TextSize = 16,
			TextColor3 = T.Cyan,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, top)
		Corner(b, 8)
		b.MouseEnter:Connect(function()
			Tween(b, 0.12, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0, TextColor3 = Color3.new(1, 1, 1) })
		end)
		b.MouseLeave:Connect(function()
			Tween(b, 0.12, { BackgroundColor3 = T.Track, BackgroundTransparency = 0.35, TextColor3 = T.Cyan })
		end)
		return b
	end
	local minBtn = TopButton("–", -60, T.Blue)
	local closeBtn = TopButton("×", -22, T.Error)
	local topLine = New("Frame", {
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.Cyan,
		BorderSizePixel = 0,
	}, main)
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, topLine)

	-- Barra lateral de pestanas
	local side = New("ScrollingFrame", {
		Position = UDim2.fromOffset(22, 56),
		Size = UDim2.new(0, 138, 1, -76),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, main)
	Corner(side, 4)
	Grad(side, { { 0, Color3.fromRGB(21, 42, 92) }, { 1, Color3.fromRGB(5, 10, 24) } }, 90)
	Stroke(side, T.Electric, 1, 0.82)
	New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
	New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

	-- Contenido
	local content = New("Frame", {
		Position = UDim2.fromOffset(168, 56),
		Size = UDim2.new(1, -190, 1, -76),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, main)

	-- Grip de redimension
	local grip = New("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -7, 1, -7),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "◢",
		Font = T.FontHeavy,
		TextSize = 12,
		TextColor3 = T.Cyan,
		AutoButtonColor = false,
		ZIndex = 5,
	}, main)

	-- Arrastre de la ventana
	do
		local dragging, dStart, dPos = false, nil, nil
		top.InputBegan:Connect(function(input)
			if IsPress(input) then
				dragging, dStart, dPos = true, input.Position, main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		Window:_Track(UIS.InputChanged:Connect(function(input)
			if dragging and IsMove(input) then
				local d = input.Position - dStart
				main.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X, dPos.Y.Scale, dPos.Y.Offset + d.Y)
			end
		end))
	end

	-- Redimension
	do
		local resizing, rStart, rW, rH, rPos = false, nil, 0, 0, nil
		grip.InputBegan:Connect(function(input)
			if IsPress(input) then
				resizing, rStart, rW, rH, rPos = true, input.Position, curW, curH, main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						resizing = false
					end
				end)
			end
		end)
		Window:_Track(UIS.InputChanged:Connect(function(input)
			if resizing and IsMove(input) then
				local d = input.Position - rStart
				local v = gui.AbsoluteSize
				local w = math.clamp(rW + d.X, MIN_W, math.max(MIN_W, math.min(MAX_W, v.X - 80)))
				local h = math.clamp(rH + d.Y, MIN_H, math.max(MIN_H, math.min(MAX_H, v.Y - 80)))
				curW, curH = w, h
				main.Size = UDim2.fromOffset(w, h)
				main.Position = UDim2.new(rPos.X.Scale, rPos.X.Offset + (w - rW) / 2, rPos.Y.Scale, rPos.Y.Offset + (h - rH) / 2)
			end
		end))
	end

	-- Icono flotante (minimizado)
	local icon = New("Frame", {
		Name = "FloatingIcon",
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.fromOffset(20, 120),
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	Corner(icon, 27)
	Glass(icon, T, 0, 2)
	local iconScale = New("UIScale", { Scale = 1 }, icon)
	PlaceLogo(icon, T, 34, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

	local minimized = false
	local function SetMinimized(state)
		if state == minimized or destroyed then
			return
		end
		minimized = state
		if state then
			local p = main.AbsolutePosition
			local v = gui.AbsoluteSize
			icon.Position = UDim2.fromOffset(math.clamp(p.X, 0, math.max(0, v.X - 54)), math.clamp(p.Y, 0, math.max(0, v.Y - 54)))
			Tween(scale, 0.16, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.16, function()
				if minimized and not destroyed then
					main.Visible = false
					iconScale.Scale = 0.3
					icon.Visible = true
					Tween(iconScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			end)
		else
			icon.Visible = false
			main.Visible = true
			scale.Scale = 0.6
			Tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end

	-- Arrastre del icono + click para restaurar
	do
		local dragging, moved, dStart, dPos = false, false, nil, nil
		icon.InputBegan:Connect(function(input)
			if IsPress(input) then
				dragging, moved, dStart, dPos = true, false, input.Position, icon.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if not moved then
							SetMinimized(false)
						end
					end
				end)
			end
		end)
		Window:_Track(UIS.InputChanged:Connect(function(input)
			if dragging and IsMove(input) then
				local d = input.Position - dStart
				if d.Magnitude > 6 then
					moved = true
				end
				if moved then
					icon.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X, dPos.Y.Scale, dPos.Y.Offset + d.Y)
				end
			end
		end))
	end

	minBtn.MouseButton1Click:Connect(function()
		SetMinimized(true)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)

	if cfg.ToggleKey then
		Window:_Track(UIS.InputBegan:Connect(function(input, gp)
			if not gp and input.KeyCode == cfg.ToggleKey then
				SetMinimized(not minimized)
			end
		end))
	end

	-- Animacion de apertura (pop rapido)
	Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)

	--------------------------------------------------------------
	-- Notificaciones
	--------------------------------------------------------------
	local notifW = math.min(270, vp.X - 28)
	local notifHolder = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.new(0, notifW, 1, -28),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, gui)
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, notifHolder)
	local notifCount = 0

	function Window:Notify(n)
		if destroyed then
			return
		end
		n = n or {}
		local color = ({ Info = T.Electric, Success = T.Success, Warning = T.Warning, Error = T.Error })[n.Type or "Info"] or T.Electric
		local dur = n.Duration or 3.5
		notifCount = notifCount + 1

		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = notifCount,
		}, notifHolder)
		local card = New("Frame", {
			Position = UDim2.new(1, 60, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
		}, wrap)
		Corner(card, 10)
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		Grad(card, { { 0, T.Top }, { 1, T.Dark } }, 90)
		Stroke(card, color, 1.2, 0)
		local holder = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, card)
		New("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 12) }, holder)
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
		local bar = New("Frame", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(0, 3, 1, -16),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, card)
		Corner(bar, 2)
		Lbl(holder, {
			Text = n.Title or "Aviso",
			Font = T.FontHeavy,
			TextSize = 13,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 1,
		}, T)
		Lbl(holder, {
			Text = n.Content or "",
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextColor3 = T.Sub,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
		}, T)
		local pbar = New("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, holder)
		local pfill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, pbar)
		Corner(pfill, 1)

		Tween(card, 0.26, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
		Tween(pfill, dur, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
		task.delay(dur, function()
			if card.Parent then
				Tween(card, 0.22, { Position = UDim2.new(1, 60, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.24, function()
					wrap:Destroy()
				end)
			end
		end)
	end

	--------------------------------------------------------------
	-- Pestanas
	--------------------------------------------------------------
	function Window:_SelectTab(tab)
		if Window.Active == tab then
			return
		end
		local prev = Window.Active
		if prev then
			prev.Page.Visible = false
			Tween(prev.Button, 0.18, { BackgroundTransparency = 1, TextColor3 = T.Sub })
			Tween(prev.Indicator, 0.18, { BackgroundTransparency = 1 })
			Tween(prev.BtnStroke, 0.18, { Transparency = 1 })
		end
		Window.Active = tab
		tab.Page.Visible = true
		tab.Page.Position = UDim2.fromOffset(0, 8)
		Tween(tab.Page, 0.16, { Position = UDim2.fromOffset(0, 0) })
		Tween(tab.Button, 0.18, { BackgroundTransparency = 0.82, TextColor3 = Color3.new(1, 1, 1) })
		Tween(tab.Indicator, 0.18, { BackgroundTransparency = 0 })
		Tween(tab.BtnStroke, 0.18, { Transparency = 0.55 })
	end

	function Window:CreateTab(name)
		local Tab = setmetatable({ Window = Window, Name = name, Theme = T, _order = 0 }, TabMethods)

		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = T.Electric,
			BackgroundTransparency = 1,
			Text = tostring(name),
			Font = T.Font,
			TextSize = 13,
			TextColor3 = T.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = #Window.Tabs + 1,
		}, side)
		Corner(btn, 3)
		New("UIPadding", { PaddingLeft = UDim.new(0, 14) }, btn)
		local bStroke = Stroke(btn, T.Electric, 1.2, 1)
		local ind = New("Frame", {
			Position = UDim2.new(0, -6, 0.2, 0),
			Size = UDim2.new(0, 3, 0.6, 0),
			BackgroundColor3 = T.Electric,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, btn)
		Corner(ind, 2)

		local page = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Electric,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, content)
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		New("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }, page)

		Tab.Button, Tab.Indicator, Tab.BtnStroke, Tab.Page = btn, ind, bStroke, page
		btn.MouseButton1Click:Connect(function()
			Window:_SelectTab(Tab)
		end)

		Window.Tabs[#Window.Tabs + 1] = Tab
		if #Window.Tabs == 1 then
			Window:_SelectTab(Tab)
		end
		return Tab
	end

	--------------------------------------------------------------
	-- Utilidades de ventana
	--------------------------------------------------------------
	function Window:SetTitle(t, s)
		if t then
			titleLbl.Text = tostring(t)
		end
		if s then
			subLbl.Text = tostring(s)
		end
	end
	function Window:Minimize()
		SetMinimized(true)
	end
	function Window:Restore()
		SetMinimized(false)
	end
	function Window:Toggle()
		SetMinimized(not minimized)
	end

	function Window:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(conns)
		if gui then
			gui:Destroy()
		end
	end

	return Window
end

return UI_Library
