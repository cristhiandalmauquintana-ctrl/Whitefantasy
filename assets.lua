--[[
    FroggyRivalsAssets  -  extras opcionales para FroggyRivalsDesign (Pond Theme)

    Es un modulo independiente: no necesita design.lua para funcionar, pero se
    integra con sus pestañas.

    CARGA
        local Assets = loadstring(game:HttpGet("URL/assets.lua"))()

    USO RAPIDO CON LA VENTANA (agrega metodos nuevos a cada Tab)
        local Window = UI_Library.CreateWindow({Title = "Froggy"})
        Assets.Extend(Window)                       -- extiende todas las pestañas futuras
        local Tab = Window:CreateTab("Extras")      -- (o Assets.Extend(Tab) para una sola)

        Tab:AddSection("Texto")
        Tab:AddLabel("Hola charca", {Font = "Mystic", Shimmer = true})
        Tab:AddTextBox("Nombre", "Escribe aqui...", function(text, enter) end)
        Tab:AddToggleEx("ESP", false, function(v) end, "lotus")   -- lily | log | lotus | firefly
        Tab:AddSliderEx("Velocidad", 0, 100, 16, function(v) end, "koi") -- drop | lily | koi | frog | stones
        local bar = Tab:AddProgress("Cargando", "lily", 0)        -- water | drop | lily | koi | frog | stones
        bar:Set(0.5)
        Tab:AddButtonEx("Piedra", function() end, "stone", "lg")  -- wood | stone | lily | pill | outline | berry
        Tab:AddButtonRow({{Text = "A"}, {Text = "B", Style = "pill"}})
        Tab:AddDropdown("Modo", {"Uno", "Dos", "Tres"}, "Uno", function(v) end)
        Tab:AddKeybind("Tecla", Enum.KeyCode.F, function(key) end)
        Tab:AddStepper("Cantidad", 1, 10, 3, 1, function(v) end)
        Tab:AddPalette("Color", {Color3.fromRGB(105,255,90), Color3.fromRGB(110,215,230)}, 1, function(c, i) end)
        Tab:AddInfo("Mensaje importante", "warn")   -- info | warn | success | danger
        Tab:AddDivider("dots")
        local card = Tab:AddCard("Mi tarjeta")     -- card.Content sirve como destino de otros Add*
        Assets.AddButtonEx(card, "Dentro de la tarjeta", print)

    USO SIN VENTANA (cualquier GuiObject como destino)
        Assets.CreateButton(miFrame, {Text = "Hola", Style = "pill", Size = UDim2.fromOffset(120, 34),
            Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Callback = print})
        Assets.CreateSwitch(miFrame, {Style = "firefly", Default = true, Callback = print})
        Assets.CreateProgress(miFrame, {Style = "koi", Size = UDim2.new(1, -20, 0, 30)})

    OTROS
        Assets.Notify({Title = "Listo", Text = "Todo cargado", Type = "success", Duration = 4})
        Assets.Anim.*   (Ripple, Pulse, Float, Wiggle, Shake, Pop, GlowStroke, SlideIn, Typewriter,
                         Shimmer, Ambient: "bubbles" | "fireflies" | "rain" | "koi")
        Assets.Decor.*  (LilyPad, Lotus, Koi, Frog, Dragonfly, Cattail)
        Assets.Fonts.*  (Title, Body, Bold, Black, Mystic, Hand, Indie, Display, Serif, Code, Typewriter, Fantasy, Cartoon)
        Assets.Colors.* (paleta de la charca)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local rng = Random.new()
local Assets = { Version = "1.0.0" }

--------------------------------------------------------------------------
-- PALETA Y FUENTES
--------------------------------------------------------------------------
local C = {
	Deep = Color3.fromRGB(12, 46, 34),
	Forest = Color3.fromRGB(24, 92, 58),
	Neon = Color3.fromRGB(105, 255, 90),
	NeonDim = Color3.fromRGB(60, 150, 60),
	WaterDark = Color3.fromRGB(8, 38, 52),
	WaterMid = Color3.fromRGB(16, 86, 104),
	WaterLight = Color3.fromRGB(110, 215, 230),
	WaterCut = Color3.fromRGB(14, 64, 80),
	Wood = Color3.fromRGB(118, 82, 50),
	WoodDark = Color3.fromRGB(66, 44, 28),
	WoodLight = Color3.fromRGB(160, 116, 70),
	PadGreen = Color3.fromRGB(46, 150, 70),
	PadDark = Color3.fromRGB(22, 96, 46),
	PadLight = Color3.fromRGB(90, 190, 100),
	FrogGreen = Color3.fromRGB(80, 210, 70),
	FrogDark = Color3.fromRGB(38, 130, 44),
	FrogBelly = Color3.fromRGB(190, 245, 150),
	Text = Color3.fromRGB(228, 246, 228),
	TextDim = Color3.fromRGB(150, 188, 160),
	Red = Color3.fromRGB(255, 90, 90),
	Berry = Color3.fromRGB(190, 50, 70),
	BerryDark = Color3.fromRGB(110, 24, 40),
	Gold = Color3.fromRGB(255, 214, 90),
	Amber = Color3.fromRGB(255, 190, 70),
	Stone = Color3.fromRGB(150, 156, 152),
	StoneDark = Color3.fromRGB(88, 94, 92),
	Pink = Color3.fromRGB(255, 170, 200),
	Koi = Color3.fromRGB(255, 140, 60),
	White = Color3.fromRGB(255, 255, 255),
}
Assets.Colors = C

local function safeFont(name, fallback)
	local ok, f = pcall(function()
		return Enum.Font[name]
	end)
	if ok and f then
		return f
	end
	return fallback
end

local FONT_FALLBACK = Enum.Font.GothamMedium
Assets.Fonts = {
	Title = safeFont("FredokaOne", Enum.Font.GothamBold),
	Body = safeFont("GothamMedium", FONT_FALLBACK),
	Bold = safeFont("GothamBold", FONT_FALLBACK),
	Black = safeFont("GothamBlack", FONT_FALLBACK),
	Mystic = safeFont("Fondamento", FONT_FALLBACK),
	Hand = safeFont("PatrickHand", FONT_FALLBACK),
	Indie = safeFont("IndieFlower", FONT_FALLBACK),
	Display = safeFont("LuckiestGuy", Enum.Font.GothamBold),
	Serif = safeFont("Merriweather", FONT_FALLBACK),
	Code = safeFont("Code", FONT_FALLBACK),
	Typewriter = safeFont("SpecialElite", FONT_FALLBACK),
	Fantasy = safeFont("Fantasy", FONT_FALLBACK),
	Cartoon = safeFont("Cartoon", FONT_FALLBACK),
}
local F = Assets.Fonts

local function fontOf(f)
	if typeof(f) == "EnumItem" then
		return f
	end
	if type(f) == "string" and F[f] then
		return F[f]
	end
	return F.Body
end

-- tamaños listos para botones: {ancho, alto} en pixeles
Assets.Sizes = {
	xs = { 70, 24 },
	sm = { 100, 30 },
	md = { 140, 38 },
	lg = { 190, 46 },
	xl = { 250, 56 },
}

--------------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(o, r)
	return new("UICorner", { CornerRadius = r or UDim.new(0, 8) }, o)
end

local function stroke(o, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- tween infinito que se cancela solo cuando el objeto se destruye
local function loop(o, t, props, style, reverse)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, reverse ~= false),
		props
	)
	tw:Play()
	o.Destroying:Connect(function()
		tw:Cancel()
	end)
	return tw
end

local function fire(cb, ...)
	if type(cb) == "function" then
		task.spawn(cb, ...)
	end
end

-- conecta una señal y la desconecta cuando "owner" se destruye
local function bind(owner, signal, fn)
	local c = signal:Connect(fn)
	owner.Destroying:Connect(function()
		c:Disconnect()
	end)
	return c
end

local function label(parent, props)
	local p = {
		BackgroundTransparency = 1,
		Font = F.Body,
		TextSize = 14,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in pairs(props) do
		p[k] = v
	end
	return new("TextLabel", p, parent)
end

local function nextOrder(parent)
	local n = (parent:GetAttribute("FRG_Order") or 1000) + 1
	parent:SetAttribute("FRG_Order", n)
	return n
end

-- Acepta un Tab de design.lua, una tarjeta (Content), o cualquier GuiObject.
local function resolve(target)
	if typeof(target) == "Instance" then
		return target, nil
	end
	if type(target) == "table" then
		if typeof(target.Page) == "Instance" then
			return target.Page, target
		end
		if typeof(target.Content) == "Instance" then
			return target.Content, nil
		end
		if typeof(target.Instance) == "Instance" then
			return target.Instance, nil
		end
	end
	error("FroggyRivalsAssets: destino invalido (usa un Tab, una tarjeta o un GuiObject)", 3)
end

-- Crea la "fila" donde vive un elemento. En listas (UIListLayout) respeta el orden;
-- en cualquier otro contenedor se posiciona libremente con cfg.Position / cfg.Size.
local function place(target, height, cfg)
	cfg = cfg or {}
	local parent, tab = resolve(target)
	local list = parent:FindFirstChildOfClass("UIListLayout")
	local f = new("Frame", {
		Name = cfg.Name or "FRG_Row",
		BackgroundColor3 = C.Deep,
		BackgroundTransparency = cfg.Bare and 1 or 0.25,
		BorderSizePixel = 0,
	}, parent)
	if list then
		f.Size = UDim2.new(cfg.WidthScale or 1, cfg.WidthOffset or 0, 0, height)
		if tab and type(tab.NextOrder) == "function" then
			f.LayoutOrder = tab:NextOrder()
		else
			f.LayoutOrder = nextOrder(parent)
		end
	else
		f.Size = cfg.Size or UDim2.new(1, 0, 0, height)
		f.Position = cfg.Position or UDim2.new()
		f.AnchorPoint = cfg.AnchorPoint or Vector2.new()
	end
	if not cfg.Bare then
		corner(f, UDim.new(0, 10))
		stroke(f, C.NeonDim, 1, 0.55)
	end
	return f, parent
end

local function hitbox(parent, z)
	return new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = z or 5,
	}, parent)
end

--------------------------------------------------------------------------
-- DECORACION (piezas dibujadas con Frames)
--------------------------------------------------------------------------
local Decor = {}
Assets.Decor = Decor

function Decor.LilyPad(parent, size, position, opts)
	opts = opts or {}
	local pad = new("Frame", {
		Name = "LilyPad",
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = opts.Color or C.PadGreen,
		BorderSizePixel = 0,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	corner(pad, UDim.new(0.5, 0))
	stroke(pad, C.PadDark, 1.5)
	local hl = new("Frame", {
		Size = UDim2.fromScale(0.55, 0.55),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.PadLight,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, pad)
	corner(hl, UDim.new(0.5, 0))
	if opts.Notch ~= false then
		local holder = new("Frame", {
			Name = "Notch",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Rotation = opts.NotchRotation or 0,
			ZIndex = 3,
		}, pad)
		local len = 0.52
		for _, deg in ipairs({ -22, -11, 0, 11, 22 }) do
			local a = math.rad(deg)
			new("Frame", {
				Size = UDim2.fromScale(len, 0.14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5 + math.cos(a) * len / 2, 0.5 + math.sin(a) * len / 2),
				Rotation = deg,
				BackgroundColor3 = opts.CutColor or C.WaterCut,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, holder)
		end
	end
	return pad
end

-- Flor de loto: 8 petalos externos + 5 internos + centro dorado
function Decor.Lotus(parent, size, position, opts)
	opts = opts or {}
	local root = new("Frame", {
		Name = "Lotus",
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	local function ring(count, scale, color, z)
		for i = 0, count - 1 do
			local holder = new("Frame", {
				Size = UDim2.fromScale(scale, scale),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = i * (360 / count),
				BackgroundTransparency = 1,
				ZIndex = z,
			}, root)
			local petal = new("Frame", {
				Size = UDim2.fromScale(0.3, 0.5),
				Position = UDim2.fromScale(0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				ZIndex = z,
			}, holder)
			corner(petal, UDim.new(0.5, 0))
			stroke(petal, Color3.fromRGB(200, 110, 150), 1, 0.4)
		end
	end
	ring(8, 1, opts.Outer or Color3.fromRGB(255, 205, 225), 1)
	ring(5, 0.72, opts.Inner or C.Pink, 2)
	local core = new("Frame", {
		Size = UDim2.fromScale(0.2, 0.2),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(core, UDim.new(0.5, 0))
	return root
end

-- Koi (mira a la derecha). Opts.Swim = true mueve cola y cuerpo
function Decor.Koi(parent, size, position, opts)
	opts = opts or {}
	local root = new("Frame", {
		Name = "Koi",
		Size = UDim2.fromOffset(size, size * 0.5),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	local body = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, root)
	local tail = new("Frame", {
		Size = UDim2.fromScale(0.3, 0.55),
		Position = UDim2.fromScale(0.02, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 190, 120),
		BorderSizePixel = 0,
		ZIndex = 1,
	}, body)
	corner(tail, UDim.new(0.5, 0))
	for _, y in ipairs({ 0.02, 0.62 }) do
		local fin = new("Frame", {
			Size = UDim2.fromScale(0.22, 0.3),
			Position = UDim2.fromScale(0.42, y),
			BackgroundColor3 = Color3.fromRGB(255, 190, 120),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, body)
		corner(fin, UDim.new(0.5, 0))
	end
	local torso = new("Frame", {
		Size = UDim2.fromScale(0.76, 0.7),
		Position = UDim2.fromScale(0.22, 0.15),
		BackgroundColor3 = opts.Color or C.Koi,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, body)
	corner(torso, UDim.new(0.5, 0))
	stroke(torso, Color3.fromRGB(190, 90, 30), 1)
	local patch = new("Frame", {
		Size = UDim2.fromScale(0.38, 0.55),
		Position = UDim2.fromScale(0.28, 0.2),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, torso)
	corner(patch, UDim.new(0.5, 0))
	for _, y in ipairs({ 0.12, 0.7 }) do
		local eye = new("Frame", {
			Size = UDim2.fromScale(0.09, 0.16),
			Position = UDim2.fromScale(0.82, y),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderSizePixel = 0,
			ZIndex = 4,
		}, torso)
		corner(eye, UDim.new(0.5, 0))
	end
	if opts.Swim ~= false then
		loop(tail, rng:NextNumber(0.25, 0.4), { Rotation = 22 })
		loop(body, rng:NextNumber(0.5, 0.8), { Rotation = 4 })
	end
	return root
end

-- Ranita simple (sin animacion de reposo; sirve como marcador/decoracion)
local MINI_FROG = {
	{ 0.00, 0.56, 0.34, 0.40, C.FrogDark, 1 },
	{ 0.66, 0.56, 0.34, 0.40, C.FrogDark, 1 },
	{ 0.14, 0.40, 0.72, 0.56, C.FrogGreen, 2 },
	{ 0.20, 0.52, 0.60, 0.43, C.FrogBelly, 2 },
	{ 0.08, 0.00, 0.34, 0.34, C.FrogGreen, 2 },
	{ 0.58, 0.00, 0.34, 0.34, C.FrogGreen, 2 },
	{ 0.04, 0.20, 0.92, 0.50, C.FrogGreen, 3 },
	{ 0.12, 0.04, 0.26, 0.26, C.White, 4 },
	{ 0.62, 0.04, 0.26, 0.26, C.White, 4 },
	{ 0.20, 0.12, 0.14, 0.14, Color3.fromRGB(14, 14, 14), 5 },
	{ 0.70, 0.12, 0.14, 0.14, Color3.fromRGB(14, 14, 14), 5 },
	{ 0.29, 0.50, 0.42, 0.14, Color3.fromRGB(30, 100, 40), 4 },
	{ 0.27, 0.46, 0.46, 0.12, C.FrogGreen, 5 },
}
function Decor.Frog(parent, size, position, opts)
	opts = opts or {}
	local f = new("Frame", {
		Name = "MiniFrog",
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	for _, p in ipairs(MINI_FROG) do
		local part = new("Frame", {
			Position = UDim2.fromScale(p[1], p[2]),
			Size = UDim2.fromScale(p[3], p[4]),
			BackgroundColor3 = p[5],
			BorderSizePixel = 0,
			ZIndex = p[6],
		}, f)
		corner(part, UDim.new(0.5, 0))
	end
	return f
end

function Decor.Dragonfly(parent, size, position, opts)
	opts = opts or {}
	local root = new("Frame", {
		Name = "Dragonfly",
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	local color = opts.Color or Color3.fromRGB(70, 200, 210)
	for i, y in ipairs({ 0.22, 0.4 }) do
		for _, x in ipairs({ 0.2, 0.52 }) do
			local wing = new("Frame", {
				Size = UDim2.fromScale(0.3, 0.14),
				Position = UDim2.fromScale(x, y),
				Rotation = (x < 0.4) and -18 or 18,
				BackgroundColor3 = C.White,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, root)
			corner(wing, UDim.new(0.5, 0))
			loop(wing, 0.07 + i * 0.01, { BackgroundTransparency = 0.8 }, Enum.EasingStyle.Linear)
		end
	end
	local body = new("Frame", {
		Size = UDim2.fromScale(0.78, 0.09),
		Position = UDim2.fromScale(0.1, 0.46),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	corner(body, UDim.new(0.5, 0))
	local head = new("Frame", {
		Size = UDim2.fromScale(0.14, 0.14),
		Position = UDim2.fromScale(0.82, 0.435),
		BackgroundColor3 = Color3.fromRGB(40, 120, 130),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(head, UDim.new(0.5, 0))
	return root
end

-- Espadaña: tallo + mazorca marron (se mece suave)
function Decor.Cattail(parent, height, position, opts)
	opts = opts or {}
	local root = new("Frame", {
		Name = "Cattail",
		Size = UDim2.fromOffset(height * 0.3, height),
		Position = position or UDim2.new(),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	local stem = new("Frame", {
		Size = UDim2.new(0, math.max(2, height * 0.05), 1, 0),
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.PadDark,
		BorderSizePixel = 0,
	}, root)
	corner(stem, UDim.new(0.5, 0))
	local head = new("Frame", {
		Size = UDim2.fromScale(0.62, 0.34),
		Position = UDim2.fromScale(0.5, 0.02),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(110, 70, 40),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	corner(head, UDim.new(0.5, 0))
	stroke(head, C.WoodDark, 1)
	if opts.Sway ~= false then
		loop(root, rng:NextNumber(2.2, 3.4), { Rotation = rng:NextInteger(3, 6) })
	end
	return root
end

--------------------------------------------------------------------------
-- ANIMACIONES EXTRA
--------------------------------------------------------------------------
local Anim = {}
Assets.Anim = Anim

-- Onda expansiva desde el punto de click (x, y en pantalla). Parent debe ser un GuiObject.
function Anim.Ripple(gui, x, y, color)
	local ap = gui.AbsolutePosition
	local as = gui.AbsoluteSize
	local px = (x or (ap.X + as.X / 2)) - ap.X
	local py = (y or (ap.Y + as.Y / 2)) - ap.Y
	local max = math.max(as.X, as.Y) * 2.2
	local r = new("Frame", {
		Name = "Ripple",
		Size = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(px, py),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color or C.White,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, gui)
	corner(r, UDim.new(0.5, 0))
	tween(r, 0.45, { Size = UDim2.fromOffset(max, max), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(0.5, function()
		if r.Parent then
			r:Destroy()
		end
	end)
end

function Anim.Pulse(gui, scale, t)
	local sc = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Scale = 1 }, gui)
	return loop(sc, t or 0.9, { Scale = scale or 1.06 })
end

function Anim.Float(gui, dy, t)
	local p = gui.Position
	return loop(gui, t or 2.2, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - (dy or 5)) })
end

function Anim.Wiggle(gui, deg, t)
	return loop(gui, t or 0.8, { Rotation = deg or 6 })
end

function Anim.Pop(gui, from)
	local sc = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Scale = 1 }, gui)
	sc.Scale = from or 0.7
	return tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Anim.Shake(gui, strength, duration)
	strength = strength or 6
	duration = duration or 0.35
	local base = gui.Position
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration and gui.Parent do
			local k = 1 - (os.clock() - t0) / duration
			gui.Position = UDim2.new(base.X.Scale, base.X.Offset + rng:NextNumber(-strength, strength) * k, base.Y.Scale, base.Y.Offset)
			task.wait(0.03)
		end
		if gui.Parent then
			gui.Position = base
		end
	end)
end

function Anim.GlowStroke(st, t, minT, maxT)
	st.Transparency = maxT or 0.7
	return loop(st, t or 1.2, { Transparency = minT or 0 })
end

-- Entra deslizandose desde un desplazamiento (UDim2 offset relativo a su posicion final)
function Anim.SlideIn(gui, fromOffset, t)
	local final = gui.Position
	fromOffset = fromOffset or UDim2.fromOffset(0, 24)
	gui.Position = UDim2.new(
		final.X.Scale + fromOffset.X.Scale,
		final.X.Offset + fromOffset.X.Offset,
		final.Y.Scale + fromOffset.Y.Scale,
		final.Y.Offset + fromOffset.Y.Offset
	)
	return tween(gui, t or 0.4, { Position = final }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Anim.Typewriter(lbl, text, speed, onDone)
	speed = speed or 0.03
	local handle = { Cancelled = false }
	lbl.Text = ""
	task.spawn(function()
		local len = utf8.len(text) or #text
		for i = 1, len do
			if handle.Cancelled or not lbl.Parent then
				return
			end
			local stop = utf8.offset(text, i + 1)
			lbl.Text = string.sub(text, 1, (stop or (#text + 1)) - 1)
			task.wait(speed)
		end
		if onDone then
			onDone()
		end
	end)
	function handle:Cancel()
		self.Cancelled = true
	end
	return handle
end

-- Brillo que recorre el texto (usa un UIGradient animado)
function Anim.Shimmer(lbl, c1, c2, t)
	lbl.TextColor3 = C.White
	local g = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1 or C.Neon),
			ColorSequenceKeypoint.new(0.5, c2 or C.WaterLight),
			ColorSequenceKeypoint.new(1, c1 or C.Neon),
		}),
		Offset = Vector2.new(-1, 0),
	}, lbl)
	loop(g, t or 2.2, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear, false)
	return g
end

-- Efectos de fondo: "bubbles" | "fireflies" | "rain" | "koi". Devuelve {Stop, Instance}
function Anim.Ambient(parent, kind, opts)
	opts = opts or {}
	local layer = new("Frame", {
		Name = "FRG_Ambient_" .. tostring(kind),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = opts.ZIndex or 1,
	}, parent)
	local alive = true
	local handle = { Instance = layer }
	function handle:Stop()
		alive = false
		if layer.Parent then
			layer:Destroy()
		end
	end
	layer.Destroying:Connect(function()
		alive = false
	end)
	local rate = opts.Rate or 1

	if kind == "bubbles" then
		task.spawn(function()
			while alive do
				task.wait(rng:NextNumber(0.4, 1.2) / rate)
				if not alive then
					break
				end
				local s = rng:NextInteger(5, 12)
				local x = rng:NextNumber(0.05, 0.95)
				local b = new("Frame", {
					Size = UDim2.fromOffset(s, s),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(x, 0, 1, s),
					BackgroundColor3 = C.WaterLight,
					BackgroundTransparency = 0.8,
					BorderSizePixel = 0,
				}, layer)
				corner(b, UDim.new(0.5, 0))
				stroke(b, C.White, 1, 0.4)
				local T = rng:NextNumber(3, 5.5)
				tween(b, T, {
					Position = UDim2.new(x + rng:NextNumber(-0.06, 0.06), 0, -0.1, 0),
					BackgroundTransparency = 1,
				}, Enum.EasingStyle.Linear)
				task.delay(T, function()
					if b.Parent then
						b:Destroy()
					end
				end)
			end
		end)
	elseif kind == "fireflies" then
		for _ = 1, opts.Count or 6 do
			local ff = new("Frame", {
				Size = UDim2.fromOffset(5, 5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
				BackgroundColor3 = Color3.fromRGB(255, 240, 150),
				BorderSizePixel = 0,
			}, layer)
			corner(ff, UDim.new(0.5, 0))
			local glow = new("Frame", {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 230, 120),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
			}, ff)
			corner(glow, UDim.new(0.5, 0))
			loop(glow, rng:NextNumber(0.6, 1.4), { BackgroundTransparency = 0.95, Size = UDim2.fromOffset(20, 20) })
			task.spawn(function()
				while alive and ff.Parent do
					local t = rng:NextNumber(2, 4)
					tween(ff, t, { Position = UDim2.fromScale(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.05, 0.95)) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					task.wait(t)
				end
			end)
		end
	elseif kind == "rain" then
		task.spawn(function()
			while alive do
				task.wait(rng:NextNumber(0.25, 0.8) / rate)
				if not alive then
					break
				end
				local ring = new("Frame", {
					Size = UDim2.fromOffset(4, 4),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				}, layer)
				corner(ring, UDim.new(0.5, 0))
				local st = stroke(ring, C.WaterLight, 1.5, 0.3)
				local d = rng:NextInteger(36, 64)
				tween(ring, 1.2, { Size = UDim2.fromOffset(d, d * 0.6) }, Enum.EasingStyle.Quad)
				tween(st, 1.2, { Transparency = 1 }, Enum.EasingStyle.Quad)
				task.delay(1.3, function()
					if ring.Parent then
						ring:Destroy()
					end
				end)
			end
		end)
	elseif kind == "koi" then
		task.spawn(function()
			while alive do
				task.wait(rng:NextNumber(4, 8) / rate)
				if not alive then
					break
				end
				local y = rng:NextNumber(0.15, 0.85)
				local right = rng:NextNumber() > 0.5
				local fish = Decor.Koi(layer, rng:NextInteger(40, 64), UDim2.new(right and -0.15 or 1.15, 0, y, 0))
				fish.Rotation = right and 0 or 180
				local T = rng:NextNumber(7, 11)
				tween(fish, T, { Position = UDim2.new(right and 1.15 or -0.15, 0, y + rng:NextNumber(-0.1, 0.1), 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				task.delay(T + 0.1, function()
					if fish.Parent then
						fish:Destroy()
					end
				end)
			end
		end)
	end
	return handle
end

--------------------------------------------------------------------------
-- TEXTO: etiquetas, secciones, avisos, separadores, tarjetas
--------------------------------------------------------------------------
function Assets.AddLabel(target, text, opts)
	opts = opts or {}
	local row = place(target, 0, { Bare = true, Name = "FRG_Label", Size = opts.Size, Position = opts.Position })
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 0)
	new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, row)
	local lbl = label(row, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextSize = opts.TextSize or 14,
		TextColor3 = opts.Color or C.Text,
		TextWrapped = opts.Wrap ~= false,
		TextXAlignment = Enum.TextXAlignment[opts.Align or "Left"],
		RichText = opts.RichText or false,
	})
	if opts.Shimmer then
		Anim.Shimmer(lbl, opts.Color1, opts.Color2)
	end
	local typing
	if opts.Animate then
		typing = Anim.Typewriter(lbl, tostring(text), opts.Speed)
	end
	local obj = { Instance = row, Label = lbl }
	function obj:Set(t)
		if typing then
			typing:Cancel()
		end
		lbl.Text = tostring(t)
	end
	function obj:Get()
		return lbl.Text
	end
	function obj:Destroy()
		row:Destroy()
	end
	return obj
end

function Assets.AddSection(target, text, opts)
	opts = opts or {}
	local row = place(target, 28, { Bare = true, Name = "FRG_Section" })
	local pad = Decor.LilyPad(row, 16, UDim2.new(0, 10, 0.5, 0))
	local lbl = label(row, {
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(0, 10, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = tostring(text),
		Font = fontOf(opts.Font or "Title"),
		TextSize = opts.TextSize or 16,
		TextColor3 = opts.Color or C.Neon,
	})
	local line = new("Frame", {
		Size = UDim2.new(1, -(24 + lbl.TextBounds.X + 16), 0, 2),
		Position = UDim2.new(0, 24 + lbl.TextBounds.X + 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Neon,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, row)
	corner(line, UDim.new(0.5, 0))
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, line)
	loop(pad, 3, { Rotation = 25 })
	return { Instance = row, Label = lbl }
end

local INFO_KINDS = {
	info = { Color3.fromRGB(110, 215, 230), "i" },
	warn = { Color3.fromRGB(255, 190, 70), "!" },
	success = { Color3.fromRGB(105, 255, 90), "+" },
	danger = { Color3.fromRGB(255, 90, 90), "x" },
}
function Assets.AddInfo(target, text, kind, opts)
	opts = opts or {}
	local k = INFO_KINDS[kind or "info"] or INFO_KINDS.info
	local row = place(target, 0, opts)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(row.Size.X.Scale, row.Size.X.Offset, 0, 0)
	row.BackgroundColor3 = C.WaterDark
	row.BackgroundTransparency = 0.3
	local st = row:FindFirstChildOfClass("UIStroke")
	if st then
		st.Color = k[1]
		st.Transparency = 0.4
	end
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 10) }, row)
	local icon = new("Frame", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(0, -30, 0, 0),
		BackgroundColor3 = k[1],
		BorderSizePixel = 0,
	}, row)
	corner(icon, UDim.new(0.5, 0))
	label(icon, {
		Size = UDim2.fromScale(1, 1),
		Text = k[2],
		Font = F.Black,
		TextSize = 15,
		TextColor3 = C.Deep,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local lbl = label(row, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(text),
		TextWrapped = true,
		TextSize = opts.TextSize or 13,
		Font = fontOf(opts.Font),
	})
	local obj = { Instance = row, Label = lbl }
	function obj:Set(t)
		lbl.Text = tostring(t)
	end
	return obj
end

function Assets.AddDivider(target, style)
	local row = place(target, 14, { Bare = true, Name = "FRG_Divider" })
	if style == "dots" then
		for i = -1, 1 do
			local d = new("Frame", {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.new(0.5, i * 14, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = i == 0 and C.Neon or C.NeonDim,
				BorderSizePixel = 0,
			}, row)
			corner(d, UDim.new(0.5, 0))
			loop(d, 0.9 + (i + 1) * 0.15, { Position = UDim2.new(0.5, i * 14, 0.5, -3) })
		end
	else
		local line = new("Frame", {
			Size = UDim2.new(0.9, 0, 0, 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.Neon,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
		}, row)
		corner(line, UDim.new(0.5, 0))
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, line)
	end
	return { Instance = row }
end

-- Tarjeta contenedora. card.Content es destino valido para cualquier Add*.
function Assets.AddCard(target, title, opts)
	opts = opts or {}
	local parent, tab = resolve(target)
	local card = new("Frame", {
		Name = "FRG_Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.WaterDark,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, parent)
	if parent:FindFirstChildOfClass("UIListLayout") then
		card.LayoutOrder = (tab and type(tab.NextOrder) == "function") and tab:NextOrder() or nextOrder(parent)
	end
	corner(card, UDim.new(0, 12))
	stroke(card, C.Wood, 2.5)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, card)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	local plaque = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Visible = title ~= nil,
	}, card)
	corner(plaque, UDim.new(0, 8))
	stroke(plaque, C.WoodDark, 2)
	new("UIGradient", {
		Color = ColorSequence.new(C.WoodLight, Color3.fromRGB(92, 64, 40)),
		Rotation = 90,
	}, plaque)
	local lbl = label(plaque, {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(title or ""),
		Font = fontOf(opts.Font or "Title"),
		TextSize = 15,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, card)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	local obj = { Instance = card, Content = content }
	function obj:SetTitle(t)
		lbl.Text = tostring(t)
		plaque.Visible = true
	end
	function obj:NextOrder()
		return nextOrder(content)
	end
	obj.Page = content
	return obj
end

--------------------------------------------------------------------------
-- CAJAS DE TEXTO
--------------------------------------------------------------------------
function Assets.AddTextBox(target, text, placeholder, callback, opts)
	opts = opts or {}
	local multi = opts.Multiline and true or false
	local boxH = multi and (opts.Height or 90) or 30
	local row = place(target, 24 + boxH + 10, opts)
	local title = label(row, {
		Position = UDim2.fromOffset(12, 5),
		Size = UDim2.new(1, -90, 0, 18),
		Text = tostring(text),
		Font = fontOf(opts.LabelFont),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local counter = label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 5),
		Size = UDim2.fromOffset(70, 18),
		Text = "",
		TextSize = 12,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- marco de madera por fuera, agua por dentro
	local frame = new("Frame", {
		Position = UDim2.fromOffset(10, 26),
		Size = UDim2.new(1, -20, 0, boxH),
		BackgroundColor3 = C.WoodDark,
		BorderSizePixel = 0,
	}, row)
	corner(frame, UDim.new(0, 8))
	local fst = stroke(frame, C.Wood, 2)
	local box = new("TextBox", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(1, -6, 1, -6),
		BackgroundColor3 = C.WaterDark,
		BorderSizePixel = 0,
		Text = tostring(opts.Default or ""),
		PlaceholderText = tostring(placeholder or ""),
		PlaceholderColor3 = Color3.fromRGB(110, 150, 140),
		TextColor3 = C.Text,
		Font = fontOf(opts.Font),
		TextSize = opts.TextSize or 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		MultiLine = multi,
		TextWrapped = multi,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		ZIndex = 2,
	}, frame)
	corner(box, UDim.new(0, 6))
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, (opts.ClearButton ~= false and not multi) and 28 or 8),
		PaddingTop = UDim.new(0, multi and 6 or 0),
	}, box)

	-- linea de agua que crece desde el centro al enfocar
	local ripple = new("Frame", {
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Neon,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, frame)
	corner(ripple, UDim.new(0.5, 0))

	local clear
	if opts.ClearButton ~= false and not multi then
		clear = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = C.Wood,
			Text = "x",
			Font = F.Bold,
			TextSize = 12,
			TextColor3 = C.Text,
			AutoButtonColor = false,
			Visible = false,
			ZIndex = 5,
		}, frame)
		corner(clear, UDim.new(0.5, 0))
	end

	local function updateCounter()
		if opts.MaxLength then
			counter.Text = #box.Text .. "/" .. opts.MaxLength
		end
		if clear then
			clear.Visible = #box.Text > 0
		end
	end
	updateCounter()

	local function invalid()
		tween(fst, 0.1, { Color = C.Red })
		Anim.Shake(frame, 5, 0.3)
		task.delay(0.5, function()
			if frame.Parent then
				tween(fst, 0.2, { Color = box:IsFocused() and C.Neon or C.Wood })
			end
		end)
	end

	local guard = false
	bind(box, box:GetPropertyChangedSignal("Text"), function()
		if guard then
			return
		end
		local t = box.Text
		local fixed = t
		if opts.Numeric then
			fixed = string.gsub(t, "[^%d%.%-]", "")
		end
		if opts.MaxLength and #fixed > opts.MaxLength then
			fixed = string.sub(fixed, 1, opts.MaxLength)
		end
		if fixed ~= t then
			guard = true
			box.Text = fixed
			guard = false
		end
		updateCounter()
		if opts.Live then
			fire(callback, box.Text, false)
		end
	end)
	bind(box, box.Focused, function()
		tween(fst, 0.2, { Color = C.Neon })
		tween(box, 0.2, { BackgroundColor3 = Color3.fromRGB(12, 54, 66) })
		tween(ripple, 0.3, { Size = UDim2.new(1, -16, 0, 2) }, Enum.EasingStyle.Quad)
	end)
	bind(box, box.FocusLost, function(enter)
		tween(fst, 0.2, { Color = C.Wood })
		tween(box, 0.2, { BackgroundColor3 = C.WaterDark })
		tween(ripple, 0.25, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Quad)
		if opts.Validate and not opts.Validate(box.Text) then
			invalid()
			return
		end
		if opts.OnlyEnter and not enter then
			return
		end
		fire(callback, box.Text, enter)
	end)
	if clear then
		bind(clear, clear.Activated, function()
			box.Text = ""
			box:CaptureFocus()
		end)
	end

	local obj = { Instance = box, Row = row }
	function obj:Set(t, silent)
		box.Text = tostring(t)
		if not silent then
			fire(callback, box.Text, false)
		end
	end
	function obj:Get()
		return box.Text
	end
	function obj:Focus()
		box:CaptureFocus()
	end
	function obj:Destroy()
		row:Destroy()
	end
	return obj
end

function Assets.AddTextArea(target, text, placeholder, callback, opts)
	opts = opts or {}
	opts.Multiline = true
	return Assets.AddTextBox(target, text, placeholder, callback, opts)
end

--------------------------------------------------------------------------
-- BOTONES (todas las formas y tamaños)
--------------------------------------------------------------------------
local SKINS = {}

SKINS.wood = function(p)
	corner(p, UDim.new(0, 10))
	local st = stroke(p, C.WoodDark, 2)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.WoodLight),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 84, 52)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(92, 64, 40)),
		}),
		Rotation = 90,
	}, p)
	return { stroke = st, base = C.WoodDark, hover = C.Neon, text = C.Text, textHover = C.Neon }
end

SKINS.stone = function(p)
	corner(p, UDim.new(0, 14))
	local st = stroke(p, C.StoneDark, 2)
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(176, 182, 178), Color3.fromRGB(104, 110, 108)),
		Rotation = 90,
	}, p)
	for _ = 1, 5 do
		local d = rng:NextInteger(3, 5)
		local s = new("Frame", {
			Size = UDim2.fromOffset(d, d),
			Position = UDim2.fromScale(rng:NextNumber(0.08, 0.9), rng:NextNumber(0.15, 0.8)),
			BackgroundColor3 = Color3.fromRGB(70, 76, 74),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
		}, p)
		corner(s, UDim.new(0.5, 0))
	end
	return { stroke = st, base = C.StoneDark, hover = C.Neon, text = Color3.fromRGB(28, 40, 36), textHover = Color3.fromRGB(8, 70, 28) }
end

SKINS.lily = function(p)
	corner(p, UDim.new(0.5, 0))
	p.BackgroundColor3 = C.PadGreen
	local st = stroke(p, C.PadDark, 2)
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = 28 }, p)
	for _, deg in ipairs({ -16, -8, 0, 8, 16 }) do
		local a = math.rad(deg)
		new("Frame", {
			Size = UDim2.fromScale(0.5, 0.1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.25, 0.5 + math.sin(a) * 0.25),
			Rotation = deg,
			BackgroundColor3 = C.WaterCut,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
		}, holder)
	end
	return { stroke = st, base = C.PadDark, hover = C.Neon, text = C.White, textHover = C.Neon }
end

SKINS.pill = function(p)
	corner(p, UDim.new(0.5, 0))
	local st = stroke(p, C.WaterLight, 2, 0.2)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(70, 170, 190), C.WaterMid), Rotation = 90 }, p)
	return { stroke = st, base = C.WaterLight, hover = C.Neon, text = C.White, textHover = C.White }
end

SKINS.outline = function(p)
	corner(p, UDim.new(0, 10))
	p.BackgroundColor3 = C.Neon
	p.BackgroundTransparency = 1
	local st = stroke(p, C.Neon, 2)
	return { stroke = st, base = C.Neon, hover = C.White, text = C.Neon, textHover = C.White, fillBase = 1, fillHover = 0.82 }
end

SKINS.berry = function(p)
	corner(p, UDim.new(0, 12))
	local st = stroke(p, C.BerryDark, 2)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(225, 80, 100), C.BerryDark), Rotation = 90 }, p)
	return { stroke = st, base = C.BerryDark, hover = C.Gold, text = C.White, textHover = C.Gold }
end
Assets.ButtonStyles = { "wood", "stone", "lily", "pill", "outline", "berry" }

local function parseButtonSize(size)
	if typeof(size) == "UDim2" then
		return size
	end
	if type(size) == "table" then
		return UDim2.fromOffset(size[1] or 140, size[2] or 38)
	end
	if size == "block" then
		return UDim2.new(1, 0, 0, 40)
	end
	local s = Assets.Sizes[size or "md"] or Assets.Sizes.md
	return UDim2.fromOffset(s[1], s[2])
end

-- Boton independiente. cfg: Text, Callback, Style, Size, Position, AnchorPoint, Icon, TextSize, Font, Disabled
function Assets.CreateButton(parent, cfg)
	cfg = cfg or {}
	local style = SKINS[cfg.Style or "wood"] and (cfg.Style or "wood") or "wood"
	local plank = new("Frame", {
		Name = "FRG_Button",
		Size = parseButtonSize(cfg.Size),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, parent)
	if cfg.Position then
		plank.Position = cfg.Position
	end
	if cfg.AnchorPoint then
		plank.AnchorPoint = cfg.AnchorPoint
	end
	if cfg.LayoutOrder then
		plank.LayoutOrder = cfg.LayoutOrder
	end
	local skin = SKINS[style](plank)
	local scale = new("UIScale", { Scale = 1 }, plank)
	local btn = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = (cfg.Icon and (cfg.Icon .. "  ") or "") .. tostring(cfg.Text or ""),
		Font = fontOf(cfg.Font or "Bold"),
		TextSize = cfg.TextSize or 14,
		TextColor3 = skin.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
	}, plank)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, btn)

	local enabled = not cfg.Disabled
	local function paintDisabled()
		plank.BackgroundTransparency = enabled and (skin.fillBase or 0) or 0.45
		btn.TextTransparency = enabled and 0 or 0.45
	end
	paintDisabled()

	bind(plank, btn.MouseEnter, function()
		if not enabled then
			return
		end
		tween(skin.stroke, 0.15, { Color = skin.hover, Thickness = 3 })
		tween(btn, 0.15, { TextColor3 = skin.textHover })
		if skin.fillHover then
			tween(plank, 0.15, { BackgroundTransparency = skin.fillHover })
		end
	end)
	bind(plank, btn.MouseLeave, function()
		tween(skin.stroke, 0.15, { Color = skin.base, Thickness = 2 })
		tween(btn, 0.15, { TextColor3 = skin.text })
		if skin.fillBase then
			tween(plank, 0.15, { BackgroundTransparency = enabled and skin.fillBase or 0.45 })
		end
		tween(scale, 0.12, { Scale = 1 })
	end)
	bind(plank, btn.MouseButton1Down, function(x, y)
		if not enabled then
			return
		end
		tween(scale, 0.08, { Scale = 0.95 })
		Anim.Ripple(plank, x, y)
	end)
	bind(plank, btn.MouseButton1Up, function()
		tween(scale, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	bind(plank, btn.Activated, function()
		if enabled then
			fire(cfg.Callback)
		end
	end)

	local obj = { Instance = plank, Button = btn }
	function obj:SetText(t)
		btn.Text = tostring(t)
	end
	function obj:SetEnabled(v)
		enabled = v and true or false
		paintDisabled()
	end
	function obj:Destroy()
		plank:Destroy()
	end
	return obj
end

-- Boton en una fila de lista/pestaña. size: "xs"|"sm"|"md"|"lg"|"xl"|"block"|{ancho,alto}|UDim2
function Assets.AddButtonEx(target, text, callback, style, size, opts)
	opts = opts or {}
	local sz = parseButtonSize(size or "block")
	local h = sz.Y.Offset > 0 and sz.Y.Offset or 40
	if style == "lily" and typeof(size) ~= "UDim2" and size ~= "block" then
		sz = UDim2.fromOffset(h, h)
	end
	local holder = place(target, h + 6, { Bare = true, Name = "FRG_ButtonSlot", Size = opts.Size, Position = opts.Position })
	local ax = ({ left = 0, center = 0.5, right = 1 })[opts.Align or "center"] or 0.5
	local cfg = {}
	for k, v in pairs(opts) do
		cfg[k] = v
	end
	cfg.Text = text
	cfg.Callback = callback
	cfg.Style = style
	cfg.Size = sz
	cfg.Position = UDim2.fromScale(ax, 0.5)
	cfg.AnchorPoint = Vector2.new(ax, 0.5)
	local b = Assets.CreateButton(holder, cfg)
	b.Slot = holder
	return b
end

-- Varios botones lado a lado. list = {{Text=, Callback=, Style=, Icon=}, ...}
function Assets.AddButtonRow(target, list, opts)
	opts = opts or {}
	local h = opts.Height or 38
	local gap = opts.Gap or 8
	local n = #list
	local holder = place(target, h + 6, { Bare = true, Name = "FRG_ButtonRow" })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local out = {}
	for i, item in ipairs(list) do
		local cfg = {}
		for k, v in pairs(item) do
			cfg[k] = v
		end
		cfg.Size = UDim2.new(1 / n, -gap * (n - 1) / n, 0, h)
		cfg.LayoutOrder = i
		out[i] = Assets.CreateButton(holder, cfg)
	end
	return out
end

--------------------------------------------------------------------------
-- INTERRUPTORES (switches) con distintos estilos
--------------------------------------------------------------------------
local SWITCH = {}
local SWITCH_SIZE = {
	lily = Vector2.new(64, 30),
	log = Vector2.new(64, 30),
	firefly = Vector2.new(64, 30),
	lotus = Vector2.new(32, 32),
}

SWITCH.lily = function(root)
	local track = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BorderSizePixel = 0 }, root)
	corner(track, UDim.new(0.5, 0))
	local st = stroke(track, C.WaterLight, 2)
	new("UIGradient", { Color = ColorSequence.new(C.WaterMid, C.WaterDark), Rotation = 90 }, track)
	local glow = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Neon,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, track)
	corner(glow, UDim.new(0.5, 0))
	local knob = Decor.LilyPad(track, 24, UDim2.new(0, 16, 0.5, 0), { ZIndex = 3 })
	local rot = 0
	return function(on, animate)
		local pos = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
		if animate then
			rot = rot + 180
			tween(knob, 0.3, { Position = pos, Rotation = rot }, Enum.EasingStyle.Back)
			tween(glow, 0.25, { BackgroundTransparency = on and 0.72 or 1 })
			tween(st, 0.25, { Color = on and C.Neon or C.WaterLight })
		else
			knob.Position = pos
			glow.BackgroundTransparency = on and 0.72 or 1
			st.Color = on and C.Neon or C.WaterLight
		end
	end
end

SWITCH.log = function(root)
	local track = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BorderSizePixel = 0 }, root)
	corner(track, UDim.new(0.5, 0))
	local st = stroke(track, C.WoodDark, 2)
	new("UIGradient", { Color = ColorSequence.new(C.WoodLight, Color3.fromRGB(92, 64, 40)), Rotation = 90 }, track)
	for i, v in ipairs({ { 0.18, 0.3, 0.34 }, { 0.5, 0.62, 0.3 }, { 0.3, 0.8, 0.22 } }) do
		local g = new("Frame", {
			Size = UDim2.new(v[3], 0, 0, 1),
			Position = UDim2.fromScale(v[1], v[2] * (i == 3 and 0.9 or 1)),
			BackgroundColor3 = C.WoodDark,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
		}, track)
		corner(g, UDim.new(0.5, 0))
	end
	local moss = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.PadGreen,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, track)
	corner(moss, UDim.new(0.5, 0))
	local knob = new("Frame", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Stone,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, track)
	corner(knob, UDim.new(0.5, 0))
	stroke(knob, C.StoneDark, 2)
	local patch = new("Frame", {
		Size = UDim2.fromScale(0.5, 0.36),
		Position = UDim2.fromScale(0.25, 0.12),
		BackgroundColor3 = C.PadLight,
		BorderSizePixel = 0,
	}, knob)
	corner(patch, UDim.new(0.5, 0))
	return function(on, animate)
		local pos = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
		if animate then
			tween(knob, 0.3, { Position = pos }, Enum.EasingStyle.Back)
			tween(moss, 0.25, { BackgroundTransparency = on and 0.55 or 1 })
			tween(st, 0.25, { Color = on and C.Neon or C.WoodDark })
		else
			knob.Position = pos
			moss.BackgroundTransparency = on and 0.55 or 1
			st.Color = on and C.Neon or C.WoodDark
		end
	end
end

SWITCH.lotus = function(root)
	local box = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.WaterDark, BorderSizePixel = 0 }, root)
	corner(box, UDim.new(0, 9))
	local st = stroke(box, C.WaterLight, 2)
	local flower = Decor.Lotus(box, 26, UDim2.fromScale(0.5, 0.5), { ZIndex = 2 })
	local sc = new("UIScale", { Scale = 0 }, flower)
	return function(on, animate)
		if animate then
			if on then
				tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				tween(flower, 0.4, { Rotation = 0 })
			else
				flower.Rotation = 0
				tween(sc, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			tween(st, 0.25, { Color = on and C.Neon or C.WaterLight })
		else
			sc.Scale = on and 1 or 0
			st.Color = on and C.Neon or C.WaterLight
		end
	end
end

SWITCH.firefly = function(root)
	local track = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 24, 32), BorderSizePixel = 0 }, root)
	corner(track, UDim.new(0.5, 0))
	local st = stroke(track, C.WaterMid, 2)
	for _, v in ipairs({ { 0.3, 0.3 }, { 0.5, 0.7 }, { 0.62, 0.25 }, { 0.78, 0.6 } }) do
		local s = new("Frame", {
			Size = UDim2.fromOffset(2, 2),
			Position = UDim2.fromScale(v[1], v[2]),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
		}, track)
		corner(s, UDim.new(0.5, 0))
	end
	local knob = new("Frame", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, track)
	local glow = new("Frame", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 230, 120),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, knob)
	corner(glow, UDim.new(0.5, 0))
	loop(glow, 0.8, { Size = UDim2.fromOffset(32, 32) })
	local core = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(110, 120, 100),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, knob)
	corner(core, UDim.new(0.5, 0))
	return function(on, animate)
		local pos = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
		local coreC = on and Color3.fromRGB(255, 244, 160) or Color3.fromRGB(110, 120, 100)
		local glowT = on and 0.65 or 1
		if animate then
			tween(knob, 0.35, { Position = pos }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			tween(core, 0.25, { BackgroundColor3 = coreC })
			tween(glow, 0.25, { BackgroundTransparency = glowT })
			tween(st, 0.25, { Color = on and Color3.fromRGB(255, 230, 120) or C.WaterMid })
		else
			knob.Position = pos
			core.BackgroundColor3 = coreC
			glow.BackgroundTransparency = glowT
			st.Color = on and Color3.fromRGB(255, 230, 120) or C.WaterMid
		end
	end
end
Assets.SwitchStyles = { "lily", "log", "lotus", "firefly" }

-- Interruptor suelto. cfg: Style, Default, Callback, Position, AnchorPoint
function Assets.CreateSwitch(parent, cfg)
	cfg = cfg or {}
	local style = SWITCH[cfg.Style or "lily"] and (cfg.Style or "lily") or "lily"
	local dim = SWITCH_SIZE[style]
	local root = new("Frame", {
		Name = "FRG_Switch",
		Size = UDim2.fromOffset(dim.X, dim.Y),
		Position = cfg.Position or UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = cfg.AnchorPoint or Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
	}, parent)
	local apply = SWITCH[style](root)
	local state = cfg.Default and true or false
	apply(state, false)
	local hit = hitbox(root, 6)
	local obj = { Instance = root }
	local function set(v, silent, animate)
		v = v and true or false
		if v == state then
			return
		end
		state = v
		apply(v, animate ~= false)
		if not silent then
			fire(cfg.Callback, v)
		end
	end
	bind(root, hit.Activated, function()
		set(not state)
	end)
	function obj:Set(v, silent)
		set(v, silent)
	end
	function obj:Get()
		return state
	end
	function obj:Toggle()
		set(not state)
	end
	return obj
end

function Assets.AddToggleEx(target, text, default, callback, style, opts)
	opts = opts or {}
	local row = place(target, 44, opts)
	local lbl = label(row, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local function tint(on)
		tween(lbl, 0.2, { TextColor3 = on and C.Neon or C.Text })
	end
	local sw = Assets.CreateSwitch(row, {
		Style = style,
		Default = default,
		Callback = function(v)
			tint(v)
			fire(callback, v)
		end,
	})
	lbl.TextColor3 = sw:Get() and C.Neon or C.Text
	local rowHit = hitbox(row, 4)
	bind(row, rowHit.Activated, function()
		sw:Toggle()
	end)
	local obj = { Instance = row }
	function obj:Set(v, silent)
		local before = sw:Get()
		sw:Set(v, true)
		if sw:Get() ~= before then
			tint(sw:Get())
			if not silent then
				fire(callback, sw:Get())
			end
		end
	end
	function obj:Get()
		return sw:Get()
	end
	function obj:Toggle()
		sw:Toggle()
	end
	return obj
end

--------------------------------------------------------------------------
-- BARRAS: estilos compartidos por sliders y barras de progreso
--------------------------------------------------------------------------
local function styleTrack(bar)
	bar.BackgroundColor3 = C.WaterDark
	bar.BackgroundTransparency = 0
	corner(bar, UDim.new(0.5, 0))
	stroke(bar, C.WoodLight, 1.5)
end

local function makeFill(bar, c1, c2, animated)
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
	}, bar)
	corner(fill, UDim.new(0.5, 0))
	local g = new("UIGradient", { Color = ColorSequence.new(c1 or Color3.fromRGB(60, 170, 255), c2 or C.Neon) }, fill)
	if animated ~= false then
		g.Offset = Vector2.new(-0.25, 0)
		loop(g, 1.6, { Offset = Vector2.new(0.25, 0) })
	end
	return fill
end

local BAR = {}

-- cada estilo recibe (bar) y devuelve render(alpha, animate) y opcionalmente snap(alpha)
BAR.water = function(bar)
	styleTrack(bar)
	local fill = makeFill(bar)
	return function(a, animate)
		if animate then
			tween(fill, 0.25, { Size = UDim2.fromScale(a, 1) })
		else
			fill.Size = UDim2.fromScale(a, 1)
		end
	end
end

BAR.drop = function(bar)
	styleTrack(bar)
	local fill = makeFill(bar, nil, nil, false)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, bar)
	local tail = new("Frame", {
		Size = UDim2.fromOffset(11, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.08),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(120, 210, 255),
		BorderSizePixel = 0,
	}, knob)
	corner(tail, UDim.new(0, 2))
	local drop = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 210, 255), BorderSizePixel = 0 }, knob)
	corner(drop, UDim.new(0.5, 0))
	local shine = new("Frame", {
		Size = UDim2.fromScale(0.28, 0.28),
		Position = UDim2.fromScale(0.2, 0.22),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, drop)
	corner(shine, UDim.new(0.5, 0))
	return function(a, animate)
		if animate then
			tween(fill, 0.25, { Size = UDim2.fromScale(a, 1) })
			tween(knob, 0.25, { Position = UDim2.fromScale(a, 0.5) })
		else
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
		end
	end
end

BAR.lily = function(bar)
	styleTrack(bar)
	local fill = makeFill(bar)
	local knob = Decor.LilyPad(bar, 24, UDim2.fromScale(0, 0.5), { ZIndex = 3 })
	return function(a, animate)
		if animate then
			tween(fill, 0.25, { Size = UDim2.fromScale(a, 1) })
			tween(knob, 0.25, { Position = UDim2.fromScale(a, 0.5), Rotation = a * 360 })
		else
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
			knob.Rotation = a * 360
		end
	end
end

BAR.koi = function(bar)
	styleTrack(bar)
	local fill = makeFill(bar, Color3.fromRGB(255, 120, 50), Color3.fromRGB(255, 230, 190))
	local fish = Decor.Koi(bar, 38, UDim2.fromScale(0, 0.5), { ZIndex = 3 })
	return function(a, animate)
		if animate then
			tween(fill, 0.3, { Size = UDim2.fromScale(a, 1) })
			tween(fish, 0.3, { Position = UDim2.fromScale(a, 0.5) })
		else
			fill.Size = UDim2.fromScale(a, 1)
			fish.Position = UDim2.fromScale(a, 0.5)
		end
	end
end

BAR.frog = function(bar)
	styleTrack(bar)
	local fill = makeFill(bar)
	local frog = Decor.Frog(bar, 28, UDim2.new(0, 0, 0.5, -6), { ZIndex = 3 })
	return function(a, animate)
		local pos = UDim2.new(a, 0, 0.5, -6)
		if animate then
			tween(fill, 0.3, { Size = UDim2.fromScale(a, 1) })
			tween(frog, 0.15, { Position = UDim2.new(a, 0, 0.5, -18), Rotation = 12 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.15, function()
				if frog.Parent then
					tween(frog, 0.15, { Position = pos, Rotation = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end)
		else
			fill.Size = UDim2.fromScale(a, 1)
			frog.Position = pos
		end
	end
end

-- piedras de rio: se iluminan una a una
BAR.stones = function(bar, count)
	bar.BackgroundTransparency = 1
	local n = count or 10
	local stones = {}
	for i = 1, n do
		local s = new("Frame", {
			Size = UDim2.fromOffset(16, 12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale((i - 1) / (n - 1), 0.5),
			BackgroundColor3 = C.Stone,
			BorderSizePixel = 0,
		}, bar)
		corner(s, UDim.new(0.5, 0))
		stroke(s, C.StoneDark, 1.5)
		stones[i] = s
	end
	local function render(a, animate)
		local lit = math.floor(a * (n - 1) + 0.5) + 1
		if a <= 0 then
			lit = 0
		end
		for i, s in ipairs(stones) do
			local on = i <= lit
			local color = on and C.Neon or C.Stone
			if animate then
				tween(s, 0.2, { BackgroundColor3 = color })
			else
				s.BackgroundColor3 = color
			end
		end
	end
	local function snap(a)
		return math.floor(a * (n - 1) + 0.5) / (n - 1)
	end
	return render, snap
end
Assets.BarStyles = { "water", "drop", "lily", "koi", "frog", "stones" }

--------------------------------------------------------------------------
-- SLIDER con estilos
--------------------------------------------------------------------------
function Assets.AddSliderEx(target, text, min, max, default, callback, style, opts)
	opts = opts or {}
	min = tonumber(min) or 0
	max = tonumber(max) or 100
	if max < min then
		min, max = max, min
	end
	local range = math.max(max - min, 1e-9)
	local isInt = (min % 1 == 0) and (max % 1 == 0)
	local step = opts.Step or (isInt and 1 or 0.01)
	local decimals = step >= 1 and 0 or (step >= 0.1 and 1 or 2)
	local function snap(v)
		v = math.clamp(v, min, max)
		local n = math.floor((v - min) / step + 0.5)
		local r = math.clamp(min + n * step, min, max)
		return tonumber(string.format("%." .. decimals .. "f", r))
	end
	local function fmt(v)
		return string.format("%." .. decimals .. "f", v)
	end
	local value = snap(tonumber(default) or min)

	local row = place(target, 58, opts)
	label(row, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -90, 0, 18),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valueLbl = label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(70, 18),
		Text = fmt(value),
		Font = F.Bold,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local bar = new("Frame", {
		Position = UDim2.new(0, 16, 0, 40),
		Size = UDim2.new(1, -32, 0, 8),
		BackgroundColor3 = C.WaterDark,
		BorderSizePixel = 0,
	}, row)
	local build = BAR[style or "drop"] or BAR.drop
	local render, snapAlpha = build(bar, opts.Stones)
	local function show(v, animate)
		render((v - min) / range, animate)
		valueLbl.Text = fmt(v)
	end
	show(value, false)

	local function setValue(v, silent, animate)
		v = snap(v)
		if v == value then
			return
		end
		value = v
		show(v, animate)
		if not silent then
			fire(callback, v)
		end
	end

	local hit = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 20, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	}, bar)
	local dragging = false
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		if snapAlpha then
			a = snapAlpha(a)
		end
		setValue(min + range * a, false, false)
	end
	bind(row, hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local page = row.Parent
			if page and page:IsA("ScrollingFrame") then
				page.ScrollingEnabled = false
			end
			fromX(input.Position.X)
		end
	end)
	bind(row, UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	bind(row, UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				local page = row.Parent
				if page and page:IsA("ScrollingFrame") then
					page.ScrollingEnabled = true
				end
			end
		end
	end)

	local obj = { Instance = row }
	function obj:Set(v, silent)
		setValue(tonumber(v) or value, silent, true)
	end
	function obj:Get()
		return value
	end
	return obj
end

--------------------------------------------------------------------------
-- BARRAS DE PROGRESO
--------------------------------------------------------------------------
-- Barra suelta. cfg: Style, Size, Position, AnchorPoint, Alpha, Stones
function Assets.CreateProgress(parent, cfg)
	cfg = cfg or {}
	local holder = new("Frame", {
		Name = "FRG_Progress",
		Size = cfg.Size or UDim2.new(1, 0, 0, 30),
		Position = cfg.Position or UDim2.new(),
		AnchorPoint = cfg.AnchorPoint or Vector2.new(),
		BackgroundTransparency = 1,
	}, parent)
	local bar = new("Frame", {
		Size = UDim2.new(1, -24, 0, cfg.Height or 10),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.WaterDark,
		BorderSizePixel = 0,
	}, holder)
	local build = BAR[cfg.Style or "water"] or BAR.water
	local render = build(bar, cfg.Stones)
	local alpha = math.clamp(cfg.Alpha or 0, 0, 1)
	render(alpha, false)
	local obj = { Instance = holder }
	function obj:Set(a, animate)
		alpha = math.clamp(tonumber(a) or 0, 0, 1)
		render(alpha, animate ~= false)
	end
	function obj:Get()
		return alpha
	end
	return obj
end

function Assets.AddProgress(target, text, style, initial, opts)
	opts = opts or {}
	local row = place(target, 58, opts)
	local lbl = label(row, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -90, 0, 18),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local pct = label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(70, 18),
		Text = "0%",
		Font = F.Bold,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local bar = Assets.CreateProgress(row, {
		Style = style,
		Alpha = initial or 0,
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 30),
		Height = 10,
		Stones = opts.Stones,
	})
	local function fmt(a)
		if opts.Format then
			return opts.Format(a)
		end
		return math.floor(a * 100 + 0.5) .. "%"
	end
	pct.Text = fmt(bar:Get())
	local obj = { Instance = row }
	function obj:Set(a, animate)
		bar:Set(a, animate)
		pct.Text = fmt(bar:Get())
	end
	function obj:Get()
		return bar:Get()
	end
	function obj:SetText(t)
		lbl.Text = tostring(t)
	end
	return obj
end

--------------------------------------------------------------------------
-- DROPDOWN (seleccion simple o multiple)
--------------------------------------------------------------------------
local function chevron(parent, position)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, parent)
	for _, side in ipairs({ -1, 1 }) do
		local b = new("Frame", {
			Size = UDim2.fromOffset(9, 2),
			Position = UDim2.new(0.5, side * 3.2, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = side * 45,
			BackgroundColor3 = C.Neon,
			BorderSizePixel = 0,
		}, holder)
		corner(b, UDim.new(0.5, 0))
	end
	return holder
end

function Assets.AddDropdown(target, text, options, default, callback, opts)
	opts = opts or {}
	local multi = opts.Multi and true or false
	local maxVisible = opts.MaxVisible or 5
	local HEAD = 42
	options = options or {}
	local row = place(target, HEAD, opts)
	row.ClipsDescendants = true
	label(row, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.45, -12, 0, HEAD),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valueLbl = label(row, {
		Position = UDim2.new(0.45, 0, 0, 0),
		Size = UDim2.new(0.55, -38, 0, HEAD),
		Text = "",
		Font = F.Bold,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = chevron(row, UDim2.new(1, -20, 0, HEAD / 2))
	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, HEAD),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	}, row)

	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEAD + 2),
		Size = UDim2.new(1, -16, 0, 10),
		BackgroundColor3 = C.WaterDark,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Neon,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 3,
	}, row)
	corner(list, UDim.new(0, 8))
	stroke(list, C.Wood, 2)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 5) }, list)

	local selected = {} -- set de valores (en modo simple solo uno)
	local buttons = {}
	local open = false

	local function selectedList()
		local out = {}
		for _, o in ipairs(options) do
			if selected[o] then
				table.insert(out, o)
			end
		end
		return out
	end
	local function refresh()
		for o, b in pairs(buttons) do
			local on = selected[o] and true or false
			b.TextColor3 = on and C.Neon or C.Text
			b.BackgroundColor3 = on and C.Forest or C.Wood
			b.BackgroundTransparency = on and 0.1 or 0.55
		end
		local sel = selectedList()
		if multi then
			valueLbl.Text = (#sel == 0) and "Ninguno" or ((#sel <= 2) and table.concat(sel, ", ") or (#sel .. " seleccionados"))
		else
			valueLbl.Text = sel[1] and tostring(sel[1]) or "Elegir..."
		end
	end
	local function listHeight()
		return math.min(#options, maxVisible) * 30 + 8
	end
	local function setOpen(v)
		open = v
		list.Size = UDim2.new(1, -16, 0, listHeight())
		local h = v and (HEAD + 2 + listHeight() + 8) or HEAD
		tween(row, 0.25, { Size = UDim2.new(row.Size.X.Scale, row.Size.X.Offset, 0, h) }, Enum.EasingStyle.Quad)
		tween(arrow, 0.25, { Rotation = v and 180 or 0 })
	end

	local function build()
		for _, b in pairs(buttons) do
			b:Destroy()
		end
		buttons = {}
		for i, o in ipairs(options) do
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = C.Wood,
				BackgroundTransparency = 0.55,
				AutoButtonColor = false,
				Text = tostring(o),
				Font = F.Body,
				TextSize = 13,
				TextColor3 = C.Text,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = i,
				ZIndex = 4,
			}, list)
			corner(b, UDim.new(0, 6))
			buttons[o] = b
			bind(b, b.MouseEnter, function()
				tween(b, 0.12, { BackgroundTransparency = 0.2 })
			end)
			bind(b, b.MouseLeave, function()
				tween(b, 0.12, { BackgroundTransparency = selected[o] and 0.1 or 0.55 })
			end)
			bind(b, b.Activated, function()
				if multi then
					selected[o] = (not selected[o]) or nil
					refresh()
					fire(callback, selectedList())
				else
					selected = { [o] = true }
					refresh()
					setOpen(false)
					fire(callback, o)
				end
			end)
		end
		refresh()
	end

	if multi then
		for _, v in ipairs(type(default) == "table" and default or {}) do
			selected[v] = true
		end
	elseif default ~= nil then
		selected[default] = true
	end
	build()
	bind(row, head.Activated, function()
		setOpen(not open)
	end)

	local obj = { Instance = row }
	function obj:Get()
		if multi then
			return selectedList()
		end
		return selectedList()[1]
	end
	function obj:Set(v, silent)
		selected = {}
		if multi then
			for _, x in ipairs(type(v) == "table" and v or {}) do
				selected[x] = true
			end
		elseif v ~= nil then
			selected[v] = true
		end
		refresh()
		if not silent then
			fire(callback, multi and selectedList() or v)
		end
	end
	function obj:SetOptions(list2, keep)
		options = list2 or {}
		if not keep then
			selected = {}
		end
		build()
		if open then
			setOpen(true)
		end
	end
	function obj:Open()
		setOpen(true)
	end
	function obj:Close()
		setOpen(false)
	end
	return obj
end

--------------------------------------------------------------------------
-- KEYBIND
--------------------------------------------------------------------------
function Assets.AddKeybind(target, text, default, callback, opts)
	opts = opts or {}
	local row = place(target, 44, opts)
	label(row, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -120, 1, 0),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local key = nil
	if typeof(default) == "EnumItem" then
		key = default
	elseif type(default) == "string" then
		local ok, k = pcall(function()
			return Enum.KeyCode[default]
		end)
		if ok then
			key = k
		end
	end
	local b = Assets.CreateButton(row, {
		Text = key and key.Name or "Ninguna",
		Style = "wood",
		Size = UDim2.fromOffset(92, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextSize = 13,
	})
	local listening = false
	local function show()
		b:SetText(listening and "..." or (key and key.Name or "Ninguna"))
	end
	bind(row, b.Button.Activated, function()
		listening = true
		show()
	end)
	bind(row, UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode ~= Enum.KeyCode.Escape then
					key = input.KeyCode
					fire(opts.OnChanged, key)
				end
				show()
			end
		elseif key and not processed and input.KeyCode == key then
			fire(callback, key)
		end
	end)
	local obj = { Instance = row }
	function obj:Get()
		return key
	end
	function obj:Set(k)
		if typeof(k) == "EnumItem" then
			key = k
		elseif type(k) == "string" then
			local ok, v = pcall(function()
				return Enum.KeyCode[k]
			end)
			if ok then
				key = v
			end
		else
			key = nil
		end
		show()
	end
	return obj
end

--------------------------------------------------------------------------
-- STEPPER (- valor +) con repeticion al mantener
--------------------------------------------------------------------------
function Assets.AddStepper(target, text, min, max, default, step, callback, opts)
	opts = opts or {}
	min = tonumber(min) or 0
	max = tonumber(max) or 100
	step = tonumber(step) or 1
	local decimals = step >= 1 and 0 or (step >= 0.1 and 1 or 2)
	local value = math.clamp(tonumber(default) or min, min, max)
	local row = place(target, 44, opts)
	label(row, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -170, 1, 0),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valueLbl = label(row, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -46, 0.5, 0),
		Size = UDim2.fromOffset(58, 28),
		Text = string.format("%." .. decimals .. "f", value),
		Font = F.Bold,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local function change(delta, silent)
		local nv = math.clamp(math.floor((value + delta - min) / step + 0.5) * step + min, min, max)
		nv = tonumber(string.format("%.4f", nv))
		if nv == value then
			return false
		end
		value = nv
		valueLbl.Text = string.format("%." .. decimals .. "f", value)
		tween(valueLbl, 0.08, { TextSize = 17 })
		task.delay(0.08, function()
			if valueLbl.Parent then
				tween(valueLbl, 0.12, { TextSize = 14 })
			end
		end)
		if not silent then
			fire(callback, value)
		end
		return true
	end
	local function holdButton(txt, x, delta)
		local b = Assets.CreateButton(row, {
			Text = txt,
			Style = "wood",
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.new(1, x, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			TextSize = 18,
		})
		local held = 0
		bind(b.Instance, b.Button.MouseButton1Down, function()
			held = held + 1
			local id = held
			change(delta)
			task.spawn(function()
				task.wait(0.4)
				while held == id and b.Instance.Parent do
					if not change(delta) then
						break
					end
					task.wait(0.07)
				end
			end)
		end)
		bind(b.Instance, b.Button.MouseButton1Up, function()
			held = held + 1
		end)
		bind(b.Instance, b.Button.MouseLeave, function()
			held = held + 1
		end)
	end
	holdButton("-", -108, -step)
	holdButton("+", -10, step)
	local obj = { Instance = row }
	function obj:Get()
		return value
	end
	function obj:Set(v, silent)
		change((tonumber(v) or value) - value, silent)
	end
	return obj
end

--------------------------------------------------------------------------
-- PALETA DE COLORES (nenufares de colores)
--------------------------------------------------------------------------
function Assets.AddPalette(target, text, colors, default, callback, opts)
	opts = opts or {}
	colors = colors or { C.Neon, C.WaterLight, C.Gold, C.Pink, C.Koi, C.Red }
	local row = place(target, 0, opts)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(row.Size.X.Scale, row.Size.X.Offset, 0, 0)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }, row)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	label(row, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = tostring(text),
		Font = fontOf(opts.Font),
		LayoutOrder = 1,
	})
	local grid = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, row)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(28, 28),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local index = 1
	if type(default) == "number" then
		index = math.clamp(default, 1, #colors)
	elseif typeof(default) == "Color3" then
		for i, c in ipairs(colors) do
			if c == default then
				index = i
			end
		end
	end
	local swatches = {}
	local function refresh(animate)
		for i, s in ipairs(swatches) do
			local on = i == index
			local st = s:FindFirstChildOfClass("UIStroke")
			local sc = s:FindFirstChildOfClass("UIScale")
			if animate then
				tween(st, 0.15, { Color = on and C.White or C.PadDark, Thickness = on and 3 or 1.5 })
				tween(sc, 0.2, { Scale = on and 1.12 or 1 }, Enum.EasingStyle.Back)
			else
				st.Color = on and C.White or C.PadDark
				st.Thickness = on and 3 or 1.5
				sc.Scale = on and 1.12 or 1
			end
		end
	end
	for i, c in ipairs(colors) do
		local s = new("TextButton", {
			BackgroundColor3 = c,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, grid)
		corner(s, UDim.new(0.5, 0))
		stroke(s, C.PadDark, 1.5)
		new("UIScale", { Scale = 1 }, s)
		swatches[i] = s
		bind(s, s.Activated, function()
			if index ~= i then
				index = i
				refresh(true)
				fire(callback, colors[i], i)
			end
		end)
	end
	refresh(false)
	local obj = { Instance = row }
	function obj:Get()
		return colors[index], index
	end
	function obj:Set(i, silent)
		if type(i) == "number" and colors[i] then
			index = i
			refresh(true)
			if not silent then
				fire(callback, colors[i], i)
			end
		end
	end
	return obj
end

--------------------------------------------------------------------------
-- NOTIFICACIONES (toasts)
--------------------------------------------------------------------------
local NOTIFY_KINDS = {
	info = C.WaterLight,
	success = C.Neon,
	warn = C.Amber,
	danger = C.Red,
}
local notifyGui, notifyHolder

local function resolveGuiParent()
	local ok, p = pcall(function()
		return gethui and gethui()
	end)
	if ok and p then
		return p
	end
	ok, p = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and p then
		return p
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function ensureNotifyGui()
	if notifyGui and notifyGui.Parent then
		return notifyHolder
	end
	notifyGui = Instance.new("ScreenGui")
	notifyGui.Name = "FroggyRivalsNotifications"
	notifyGui.ResetOnSpawn = false
	notifyGui.IgnoreGuiInset = true
	notifyGui.DisplayOrder = 1000
	notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local okParent = pcall(function()
		notifyGui.Parent = resolveGuiParent()
	end)
	if not okParent or not notifyGui.Parent then
		notifyGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	notifyHolder = new("Frame", {
		Size = UDim2.new(0, 280, 1, -24),
		Position = UDim2.new(1, -12, 0, 12),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
	}, notifyGui)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, notifyHolder)
	return notifyHolder
end

local notifyCount = 0
-- cfg: Title, Text, Type (info|success|warn|danger), Duration (segundos, 0 = fija)
function Assets.Notify(cfg)
	cfg = cfg or {}
	local holder = ensureNotifyGui()
	local color = NOTIFY_KINDS[cfg.Type or "info"] or NOTIFY_KINDS.info
	local duration = cfg.Duration or 4
	notifyCount = notifyCount + 1

	local wrap = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = notifyCount,
	}, holder)
	local toast = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 320, 0, 0),
		BackgroundColor3 = C.WaterDark,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, wrap)
	corner(toast, UDim.new(0, 12))
	stroke(toast, C.Wood, 2.5)
	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, toast)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 46), PaddingRight = UDim.new(0, 12) }, body)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	local pad = Decor.LilyPad(toast, 26, UDim2.new(0, 24, 0, 24), { Color = color, CutColor = C.WaterDark })
	loop(pad, 2.5, { Rotation = 20 })
	label(body, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = tostring(cfg.Title or "Froggy"),
		Font = F.Title,
		TextSize = 16,
		TextColor3 = color,
		LayoutOrder = 1,
	})
	if cfg.Text then
		label(body, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = tostring(cfg.Text),
			TextWrapped = true,
			TextSize = 13,
			TextColor3 = C.Text,
			LayoutOrder = 2,
		})
	end
	local timer = new("Frame", {
		Size = UDim2.new(1, -24, 0, 3),
		Position = UDim2.new(0, 12, 1, -9),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, toast)
	corner(timer, UDim.new(0.5, 0))
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		tween(toast, 0.3, { Position = UDim2.new(1, 320, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.35, function()
			if wrap.Parent then
				wrap:Destroy()
			end
		end)
	end
	tween(toast, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	if duration > 0 then
		tween(timer, duration, { Size = UDim2.new(0, 0, 0, 3) }, Enum.EasingStyle.Linear)
		task.delay(duration, close)
	end
	local click = hitbox(toast, 10)
	click.Activated:Connect(close)
	return { Close = close, Instance = wrap }
end

--------------------------------------------------------------------------
-- EXTENDER design.lua: agrega los Add* de este modulo a cada Tab
--------------------------------------------------------------------------
local EXT = {
	AddLabel = Assets.AddLabel,
	AddSection = Assets.AddSection,
	AddInfo = Assets.AddInfo,
	AddDivider = Assets.AddDivider,
	AddCard = Assets.AddCard,
	AddTextBox = Assets.AddTextBox,
	AddTextArea = Assets.AddTextArea,
	AddButtonEx = Assets.AddButtonEx,
	AddButtonRow = Assets.AddButtonRow,
	AddToggleEx = Assets.AddToggleEx,
	AddSliderEx = Assets.AddSliderEx,
	AddProgress = Assets.AddProgress,
	AddDropdown = Assets.AddDropdown,
	AddKeybind = Assets.AddKeybind,
	AddStepper = Assets.AddStepper,
	AddPalette = Assets.AddPalette,
}

-- Assets.Extend(Window) -> todas las pestañas nuevas quedan extendidas
-- Assets.Extend(Tab)    -> solo esa pestaña
function Assets.Extend(obj)
	if type(obj) ~= "table" then
		return obj
	end
	if type(obj.CreateTab) == "function" then
		local original = obj.CreateTab
		obj.CreateTab = function(self, ...)
			return Assets.Extend(original(self, ...))
		end
	else
		for name, fn in pairs(EXT) do
			obj[name] = function(self, ...)
				return fn(self, ...)
			end
		end
	end
	return obj
end

return Assets
