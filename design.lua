--[[
================================================================================
  FROGGY HUB  -  LUXURY GOLD UI LIBRARY   (design.lua  v3.0)
  Basada en el HTML "Froggy Hub - 100 Members Edition" (negro + oro).

  USO RAPIDO
  ----------
  local UI = loadstring(game:HttpGet("URL/design.lua"))()

  local Window = UI.CreateWindow({
      Title      = "FROGGY HUB",
      Subtitle   = "100 MEMBERS EDITION",
      Intro      = true,                    -- intro cinematica (false = sin intro)
      ToggleKey  = Enum.KeyCode.RightShift, -- mostrar / ocultar
      LogEvents  = true,                    -- pildora inferior con cada accion
      Resizable  = true,
  })

  local Main = Window:CreateTab("MAIN")
  Main:AddSection("AUTOMATION")
  local t = Main:AddToggle("Auto Farm", false, function(v) end)   -- t:Set(true) / t:Get()
  Main:AddSlider("WalkSpeed", 16, 200, 16, function(v) end, 1)   -- (texto,min,max,def,cb,step,sufijo)
  Main:AddButton("Ribbit", function() end)
  Main:AddDropdown("Modo", {"A","B","C"}, "A", function(v) end)  -- 5to arg true = multiple
  Main:AddKeybind("Tecla", Enum.KeyCode.F, function() end)
  Main:AddTextbox("Nombre", "", "escribe...", function(txt, enter) end)
  Main:AddColorPicker("Color", Color3.fromRGB(255,214,92), function(c) end)
  Main:AddLabel("texto"); Main:AddParagraph("Titulo", "cuerpo largo..."); Main:AddDivider()

  Window:Notify({Title = "Hola", Content = "Mensaje", Duration = 4, Type = "success"})
  -- Type: "info" | "success" | "warning" | "error"
  Window:Toggle() / :Minimize() / :Restore() / :SetTitle() / :ReplayIntro() / :Destroy()

  UI.Demo()  -> abre una ventana de ejemplo igual que el HTML.
================================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local rng = Random.new()
local UI_Library = { Version = "3.0.0" }

--------------------------------------------------------------------------
-- PALETA (sacada del HTML)
--------------------------------------------------------------------------
local C = {
	Black = Color3.fromRGB(7, 7, 6),
	Void = Color3.fromRGB(5, 5, 4),
	Panel0 = Color3.fromRGB(26, 21, 11),
	Panel1 = Color3.fromRGB(12, 11, 9),
	Panel2 = Color3.fromRGB(3, 3, 3),
	Gold = Color3.fromRGB(212, 175, 55),
	GoldBright = Color3.fromRGB(255, 214, 92),
	GoldPale = Color3.fromRGB(255, 241, 196),
	GoldDark = Color3.fromRGB(122, 92, 22),
	GoldDeep = Color3.fromRGB(168, 131, 42),
	Text = Color3.fromRGB(240, 232, 208),
	Muted = Color3.fromRGB(140, 128, 100),
	Green = Color3.fromRGB(120, 220, 130),
	Warn = Color3.fromRGB(255, 176, 64),
	Red = Color3.fromRGB(255, 100, 86),
}
local WHITE = Color3.new(1, 1, 1)

-- Fuente "serif" de lujo (el HTML usa Cinzel / Bodoni). Cambiala aqui si quieres otra.
local FONT_DISPLAY = Enum.Font.Bodoni
local FONT_UI = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

--------------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			o[k] = v
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(o, r)
	if type(r) == "number" then
		r = UDim.new(0, r)
	end
	return new("UICorner", { CornerRadius = r or UDim.new(0, 6) }, o)
end

local function stroke(o, color, thickness, transparency, mode)
	return new("UIStroke", {
		Color = color or C.Gold,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
	}, o)
end

local function grad(o, props)
	return new("UIGradient", props, o)
end

-- ColorSequence con N colores repartidos de forma uniforme
local function cseq(...)
	local cols = { ... }
	local n = #cols
	if n == 1 then
		return ColorSequence.new(cols[1])
	end
	local k = {}
	for i, c in ipairs(cols) do
		k[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), c)
	end
	return ColorSequence.new(k)
end

-- NumberSequence desde { {t, v}, ... }
local function nsq(points)
	local k = {}
	for i, p in ipairs(points) do
		k[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(k)
end

local GOLD_FILL = cseq(C.GoldDark, C.GoldBright, C.GoldPale)
local BORDER_SEQ = cseq(C.GoldDark, C.GoldBright, C.GoldPale, C.GoldBright, C.GoldDark)
local PANEL_SEQ = cseq(C.Panel0, C.Panel1, C.Panel2)
local TITLE_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.Gold),
	ColorSequenceKeypoint.new(0.38, C.Gold),
	ColorSequenceKeypoint.new(0.5, C.GoldPale),
	ColorSequenceKeypoint.new(0.62, C.Gold),
	ColorSequenceKeypoint.new(1, C.Gold),
})
local HUE_SEQ = cseq(
	Color3.fromHSV(0, 1, 1),
	Color3.fromHSV(1 / 6, 1, 1),
	Color3.fromHSV(2 / 6, 1, 1),
	Color3.fromHSV(3 / 6, 1, 1),
	Color3.fromHSV(4 / 6, 1, 1),
	Color3.fromHSV(5 / 6, 1, 1),
	Color3.fromHSV(1, 1, 1)
)

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function clampN(x, a, b)
	if a > b then
		a, b = b, a
	end
	return math.max(a, math.min(b, x))
end

local function outQuart(x)
	return 1 - (1 - x) ^ 4
end

local function outBack(x)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

-- Maid: limpia conexiones, tweens, instancias, resortes y funciones
local function cleanup(x)
	pcall(function()
		local t = typeof(x)
		if t == "RBXScriptConnection" then
			x:Disconnect()
		elseif t == "Instance" then
			if x:IsA("TweenBase") then
				x:Cancel()
			else
				x:Destroy()
			end
		elseif t == "function" then
			x()
		elseif t == "table" and type(x.Destroy) == "function" then
			x:Destroy()
		end
	end)
end

local function newMaid()
	local m = { items = {}, dead = false }
	function m:Add(x)
		if self.dead then
			cleanup(x)
		else
			self.items[#self.items + 1] = x
		end
		return x
	end
	function m:Remove(x)
		for i = #self.items, 1, -1 do
			if self.items[i] == x then
				table.remove(self.items, i)
				break
			end
		end
	end
	function m:Destroy()
		self.dead = true
		local items = self.items
		self.items = {}
		for i = #items, 1, -1 do
			cleanup(items[i])
		end
	end
	return m
end

-- Tween infinito (reverse = true por defecto)
local function loopTween(maid, o, t, props, style, reverse, dir)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(
			t,
			style or Enum.EasingStyle.Sine,
			dir or Enum.EasingDirection.InOut,
			-1,
			reverse ~= false
		),
		props
	)
	tw:Play()
	if maid then
		maid:Add(tw)
	end
	return tw
end

local function fire(cb, ...)
	if type(cb) == "function" then
		task.spawn(cb, ...)
	end
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function measure(text, size, font, width)
	local ok, v = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(width or 10000, 10000))
	end)
	if ok and v then
		return v
	end
	return Vector2.new(#tostring(text) * size * 0.55, size * 1.2)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- "MEMBERS" -> "M E M B E R S"   (simula letter-spacing)
local function tracked(s)
	local words = {}
	for word in string.gmatch(s, "%S+") do
		local chars = {}
		for _, cp in utf8.codes(word) do
			chars[#chars + 1] = utf8.char(cp)
		end
		words[#words + 1] = table.concat(chars, " ")
	end
	return table.concat(words, "   ")
end

-- Monta el ScreenGui en el primer padre que acepte la asignacion:
-- gethui() (ejecutores) -> CoreGui -> PlayerGui (LocalScript normal).
-- GetService("CoreGui") no falla en un cliente normal; lo que falla es parentar a el.
local function mountGui(gui)
	local getters = {
		function()
			return gethui and gethui()
		end,
		function()
			return game:GetService("CoreGui")
		end,
		function()
			return Players.LocalPlayer:WaitForChild("PlayerGui")
		end,
	}
	for _, get in ipairs(getters) do
		local ok, p = pcall(get)
		if ok and p then
			local ok2 = pcall(function()
				gui.Parent = p
			end)
			if ok2 and gui.Parent == p then
				return p
			end
		end
	end
	error("[FroggyHub] no se pudo montar la interfaz en ningun contenedor")
end

--------------------------------------------------------------------------
-- RESORTES (fisica real: velocidad conservada, rebote, interrumpible)
--------------------------------------------------------------------------
local Spring = {}
Spring.__index = Spring

local springList = {}
local springDriver

local function magnitude(v)
	if type(v) == "number" then
		return math.abs(v)
	end
	return v.Magnitude
end

local function advance(s, dt)
	local k, d = s.K, s.D
	local steps = math.max(1, math.ceil(dt / 0.008))
	local h = dt / steps
	local pos, vel, target = s.Position, s.Velocity, s.Target
	for _ = 1, steps do
		vel = vel + ((target - pos) * k - vel * d) * h
		pos = pos + vel * h
	end
	s.Position, s.Velocity = pos, vel
	if magnitude(target - pos) < s.Eps and magnitude(vel) < s.Eps * 2 then
		s.Position = target
		s.Velocity = vel * 0
		s.Rest = true
	end
	if s.OnStep then
		local ok, err = pcall(s.OnStep, s.Position)
		if not ok then
			s.Dead = true
			warn("[FroggyHub] spring error: " .. tostring(err))
		end
	end
end

local function drive(dt)
	dt = math.min(dt, 0.05)
	local n = #springList
	for i = 1, n do
		local s = springList[i]
		if s and not s.Dead and not s.Rest then
			advance(s, dt)
		end
	end
	local j = 0
	for i = 1, #springList do
		local s = springList[i]
		if s.Dead or s.Rest then
			s.Awake = false
		else
			j = j + 1
			springList[j] = s
		end
	end
	for i = #springList, j + 1, -1 do
		springList[i] = nil
	end
	if #springList == 0 and springDriver then
		springDriver:Disconnect()
		springDriver = nil
	end
end

local function wake(s)
	if s.Dead then
		return
	end
	s.Rest = false
	if s.Awake then
		return
	end
	s.Awake = true
	springList[#springList + 1] = s
	if not springDriver then
		springDriver = RunService.RenderStepped:Connect(drive)
	end
end

-- Spring.new(valor, rigidez, razon_de_amortiguacion, onStep, epsilon)
function Spring.new(value, stiffness, ratio, onStep, eps)
	local k = stiffness or 220
	return setmetatable({
		Position = value,
		Target = value,
		Velocity = value * 0,
		K = k,
		D = 2 * (ratio or 1) * math.sqrt(k),
		OnStep = onStep,
		Eps = eps or 0.002,
		Awake = false,
		Rest = true,
		Dead = false,
	}, Spring)
end

function Spring:Set(target)
	self.Target = target
	wake(self)
end

function Spring:Snap(value)
	self.Position = value
	self.Target = value
	self.Velocity = value * 0
	self.Rest = true
	if self.OnStep then
		self.OnStep(value)
	end
end

function Spring:Kick(v)
	self.Velocity = self.Velocity + v
	wake(self)
end

function Spring:Tune(stiffness, ratio)
	self.K = stiffness
	self.D = 2 * ratio * math.sqrt(stiffness)
end

function Spring:Destroy()
	self.Dead = true
end

--------------------------------------------------------------------------
-- ELEMENTOS DECORATIVOS
--------------------------------------------------------------------------
local function diamond(parent, size, color, props)
	local d = new("Frame", {
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		BackgroundColor3 = color or C.GoldBright,
		BorderSizePixel = 0,
	}, nil)
	if props then
		for k, v in pairs(props) do
			d[k] = v
		end
	end
	d.Parent = parent
	return d
end

-- Corona dorada (el icono del HTML). width en pixeles, alto = width * 20/26
local function buildCrown(parent, width, props)
	local s = width / 26
	local f = new("Frame", {
		Name = "Crown",
		Size = UDim2.fromOffset(width, 20 * s),
		BackgroundTransparency = 1,
	}, nil)
	if props then
		for k, v in pairs(props) do
			f[k] = v
		end
	end
	local function piece(x, y, w, h, color, rot, z, round)
		local p = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x * s, y * s),
			Size = UDim2.fromOffset(w * s, h * s),
			Rotation = rot or 0,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z or 1,
		}, f)
		if round then
			corner(p, round)
		end
		return p
	end
	-- puntas (rombos)
	piece(3.6, 8.2, 5.2, 5.2, C.GoldBright, 45, 1)
	piece(22.4, 8.2, 5.2, 5.2, C.GoldBright, 45, 1)
	piece(13, 6.6, 8.2, 8.2, C.GoldBright, 45, 2)
	piece(13, 6.6, 4.2, 4.2, C.GoldPale, 45, 2).BackgroundTransparency = 0.35
	piece(3.6, 8.2, 2.6, 2.6, C.GoldPale, 45, 2).BackgroundTransparency = 0.45
	piece(22.4, 8.2, 2.6, 2.6, C.GoldPale, 45, 2).BackgroundTransparency = 0.45
	-- cuerpo y banda
	local body = piece(13, 12.8, 19, 5, C.Gold, 0, 3)
	grad(body, { Rotation = 90, Color = cseq(C.GoldBright, C.GoldDeep) })
	local band = piece(13, 17.6, 24, 4.4, WHITE, 0, 4, UDim.new(0, 1))
	grad(band, { Color = BORDER_SEQ })
	piece(13, 15.8, 22, 0.9, C.GoldPale, 0, 5).BackgroundTransparency = 0.25
	-- perlas
	piece(3.6, 4.6, 2.6, 2.6, C.GoldPale, 0, 5, UDim.new(0.5, 0))
	piece(13, 1.3, 3, 3, C.GoldPale, 0, 5, UDim.new(0.5, 0))
	piece(22.4, 4.6, 2.6, 2.6, C.GoldPale, 0, 5, UDim.new(0.5, 0))
	-- gemas de la banda
	piece(7, 17.6, 2.4, 2.4, C.GoldDark, 45, 6)
	piece(13, 17.6, 3.2, 3.2, C.GoldPale, 45, 6)
	piece(19, 17.6, 2.4, 2.4, C.GoldDark, 45, 6)
	f.Parent = parent
	return f
end

-- Destello de 4 puntas. Devuelve el frame y su UIScale (0 = invisible)
local function buildSparkle(parent, size, color)
	local f = new("Frame", {
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 8,
	}, parent)
	local sc = new("UIScale", { Scale = 0 }, f)
	local h = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = color or C.GoldPale,
		BorderSizePixel = 0,
	}, f)
	grad(h, { Transparency = nsq({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }) })
	local v = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = color or C.GoldPale,
		BorderSizePixel = 0,
	}, f)
	grad(v, { Rotation = 90, Transparency = nsq({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }) })
	return f, sc
end

local function twinkle(maid, sc, period, delay)
	task.delay(delay or 0, function()
		if maid.dead then
			return
		end
		loopTween(maid, sc, period / 2, { Scale = 1 }, Enum.EasingStyle.Sine, true)
	end)
end

-- Gota dorada (circulo + cono). flip = reflejo invertido
local function buildDrop(parent, r, flip, alpha)
	local box = new("Frame", {
		Size = UDim2.fromOffset(r * 2, r * 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, parent)
	local body = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = alpha or 0,
		BorderSizePixel = 0,
	}, box)
	corner(body, UDim.new(0.5, 0))
	grad(body, { Rotation = flip and -90 or 90, Color = cseq(C.GoldPale, C.GoldBright, C.GoldDark) })
	local N = 12
	local L = 3 * r
	local span = L - r / 3
	local dy = span / N
	for i = 1, N do
		local y = -(L - (i - 0.5) * dy)
		local w = 2 * 0.943 * r * ((i - 0.5) / N)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(r, r + (flip and -y or y)),
			Size = UDim2.fromOffset(math.max(w, 0.6), dy + 0.8),
			BackgroundColor3 = C.GoldPale:Lerp(C.GoldBright, (i - 1) / (N - 1)),
			BackgroundTransparency = alpha or 0,
			BorderSizePixel = 0,
		}, box)
	end
	return box
end


--------------------------------------------------------------------------
-- UTILIDADES EXTRA (continuacion)
--------------------------------------------------------------------------
local GuiService = game:GetService("GuiService")
local UIS = UserInputService

-- Posicion del puntero en el mismo espacio que AbsolutePosition
-- (el ScreenGui usa IgnoreGuiInset = true)
local function pointerPos(input)
	local inset = GuiService:GetGuiInset()
	return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
end

local function spring(maid, value, k, ratio, onStep, eps)
	local s = Spring.new(value, k, ratio, onStep, eps)
	maid:Add(s)
	return s
end

local function mkText(parent, str, size, color, font, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = str,
		TextSize = size,
		TextColor3 = color or C.Text,
		Font = font or FONT_UI,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromScale(1, 1),
	})
	if props then
		for k, v in pairs(props) do
			l[k] = v
		end
	end
	l.Parent = parent
	return l
end

local function hover(maid, obj, onIn, onOut)
	maid:Add(obj.MouseEnter:Connect(onIn))
	maid:Add(obj.MouseLeave:Connect(onOut))
end

local function hoverStroke(maid, obj, st, on, off)
	hover(maid, obj, function()
		tween(st, 0.25, { Transparency = on })
	end, function()
		tween(st, 0.25, { Transparency = off })
	end)
end

local function decimalsOf(step)
	local s = string.format("%.6f", step):gsub("0+$", "")
	local dot = s:find("%.")
	if not dot then
		return 0
	end
	return #s - dot
end

local function toHex(c)
	return string.format(
		"#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
end

local TITLE_TEXT_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.GoldDark),
	ColorSequenceKeypoint.new(0.3, C.Gold),
	ColorSequenceKeypoint.new(0.5, C.GoldPale),
	ColorSequenceKeypoint.new(0.7, C.Gold),
	ColorSequenceKeypoint.new(1, C.GoldDark),
})

--------------------------------------------------------------------------
-- TEXTO POR LETRAS (reveal escalonado + espaciado)
--------------------------------------------------------------------------
local function buildLetters(parent, str, size, font, pad, shiny)
	local row = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, size * 1.2),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, pad),
	}, row)
	local letters = {}
	local i = 0
	for _, cp in utf8.codes(str) do
		i = i + 1
		local ch = utf8.char(cp)
		local w = (ch == " ") and size * 0.45 or measure(ch, size, font).X
		local holder = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(w, size * 1.2),
			LayoutOrder = i,
		}, row)
		local lb = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 16),
			Text = ch,
			TextSize = size,
			Font = font,
			TextColor3 = shiny and WHITE or C.Gold,
			TextTransparency = 1,
		}, holder)
		local g
		if shiny then
			g = grad(lb, { Color = TITLE_TEXT_SEQ })
		end
		letters[i] = { Holder = holder, Label = lb, Grad = g }
	end
	return row, letters
end

--------------------------------------------------------------------------
-- ONDAS ELIPTICAS (anillos de agua en perspectiva)
-- Cada anillo = N segmentos rotados; el contenedor solo cambia Size/Position,
-- asi que animar 14 anillos cuesta muy poco.
--------------------------------------------------------------------------
local SEGS = 28
local ringGeo = {}
for i = 1, SEGS do
	local a1 = (i - 1) / SEGS * math.pi * 2
	local a2 = i / SEGS * math.pi * 2
	local x1, y1 = 0.5 + 0.5 * math.cos(a1), 0.5 + 0.5 * math.sin(a1)
	local x2, y2 = 0.5 + 0.5 * math.cos(a2), 0.5 + 0.5 * math.sin(a2)
	local dx, dy = x2 - x1, (y2 - y1) * 0.3
	ringGeo[i] = {
		x = (x1 + x2) / 2,
		y = (y1 + y2) / 2,
		len = math.sqrt(dx * dx + dy * dy),
		rot = math.deg(math.atan2(dy, dx)),
		front = ((math.sin(a1) + math.sin(a2)) / 2 + 1) / 2, -- 0 = lado lejano, 1 = lado cercano
	}
end

local function newRing(parent)
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(10, 3),
		Visible = false,
	}, parent)
	local segs = {}
	for i = 1, SEGS do
		local g = ringGeo[i]
		segs[i] = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(g.x, g.y),
			Size = UDim2.new(g.len, 1, 0, 2),
			Rotation = g.rot,
			BorderSizePixel = 0,
			BackgroundColor3 = C.Gold,
			BackgroundTransparency = 1,
		}, f)
	end
	return { Frame = f, Segs = segs, W = {}, Active = false, T0 = 0, RX = 0, Dur = 1 }
end

local function ringStart(r, t0, rx, dur, th, br)
	r.Active, r.T0, r.RX, r.Dur = true, t0, rx, dur
	for i, s in ipairs(r.Segs) do
		local fr = ringGeo[i].front
		local col, al
		if fr < 0.5 then
			local k = fr * 2
			col, al = C.GoldDark:Lerp(C.Gold, k), lerp(0.45, 0.75, k)
		else
			local k = (fr - 0.5) * 2
			col, al = C.Gold:Lerp(C.GoldPale, k), lerp(0.75, br, k)
		end
		s.BackgroundColor3 = col
		s.Size = UDim2.new(ringGeo[i].len, 1, 0, math.max(1, th))
		s.BackgroundTransparency = 1
		r.W[i] = al
	end
end

local function ringUpdate(r, t, cx, cy)
	local p = (t - r.T0) / r.Dur
	if p < 0 then
		r.Frame.Visible = false
		return
	end
	if p > 1 then
		r.Active = false
		r.Frame.Visible = false
		return
	end
	local rx = math.max(r.RX * outQuart(p), 1)
	r.Frame.Visible = true
	r.Frame.Size = UDim2.fromOffset(rx * 2, rx * 0.6)
	r.Frame.Position = UDim2.fromOffset(cx, cy)
	local a = (1 - p) ^ 1.5
	for i, s in ipairs(r.Segs) do
		s.BackgroundTransparency = 1 - a * r.W[i]
	end
end

--------------------------------------------------------------------------
-- INTRO CINEMATICA (camara siguiendo la gota -> impacto -> titulo)
--------------------------------------------------------------------------
local HOR, WY, FALL, TT = 1.5, 2.0, 2.4, 6.5

local function buildIntro(gui, maid, owner)
	local I = { Running = false, Run = 0, _tweens = {} }
	local R2 = Random.new()

	local root = new("Frame", {
		Name = "Intro",
		Visible = false,
		Active = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Void,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 50,
	}, gui)
	local world = new("Frame", {
		Name = "World",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1,
	}, root)

	-- estrellas (se estiran con la velocidad de la camara)
	local stars = {}
	for i = 1, 70 do
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.GoldBright,
			BorderSizePixel = 0,
		}, world)
		corner(f, UDim.new(0.5, 0))
		stars[i] = { F = f, x = 0, y = 0, r = 1 }
	end
	-- bokeh (3 circulos concentricos = brillo suave)
	local bokeh = {}
	for i = 1, 14 do
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(60, 60),
		}, world)
		for _, k in ipairs({ 1, 0.62, 0.3 }) do
			local c = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(k, k),
				BackgroundColor3 = C.Gold,
				BackgroundTransparency = 0.965,
				BorderSizePixel = 0,
			}, f)
			corner(c, UDim.new(0.5, 0))
		end
		bokeh[i] = { F = f, x = 0, y = 0, r = 30 }
	end
	-- agua
	local floor = new("Frame", {
		Name = "Water",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
	}, world)
	grad(floor, {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 44, 14)),
			ColorSequenceKeypoint.new(0.1, Color3.fromRGB(22, 18, 10)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(9, 8, 6)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 2, 2)),
		}),
	})
	local horizon = new("Frame", {
		BackgroundColor3 = C.GoldPale,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Visible = false,
	}, world)
	grad(horizon, { Transparency = nsq({ { 0, 1 }, { 0.5, 0.15 }, { 1, 1 } }) })
	local glints = {}
	for i = 1, 18 do
		glints[i] = {
			F = new("Frame", { BackgroundColor3 = C.GoldPale, BorderSizePixel = 0, Visible = false }, world),
			x = 0, y = 0, l = 20, s = 1, p = 0,
		}
	end
	-- impacto
	local glow = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.GoldBright,
		BorderSizePixel = 0,
		Visible = false,
	}, world)
	corner(glow, UDim.new(0.5, 0))
	grad(glow, { Transparency = nsq({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }) })
	local jet = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
	}, world)
	corner(jet, UDim.new(0.5, 0))
	grad(jet, { Rotation = 90, Color = cseq(C.GoldPale, C.GoldDeep) })
	local rings = {}
	for i = 1, 14 do
		rings[i] = newRing(world)
	end
	local parts = {}
	for i = 1, 22 do
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 226, 140),
			BorderSizePixel = 0,
			Visible = false,
		}, world)
		corner(f, UDim.new(0.5, 0))
		parts[i] = { F = f, x = 0, y = 0, vx = 0, vy = 0, s = 2, Dead = true }
	end
	-- gota (centrada en el circulo de la gota)
	local dropG = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(2, 2),
		Visible = false,
	}, world)
	for _, g in ipairs({ { 64, 0.92 }, { 38, 0.86 }, { 18, 0.78 } }) do
		local c = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(g[1], g[1]),
			BackgroundColor3 = C.GoldBright,
			BackgroundTransparency = g[2],
			BorderSizePixel = 0,
		}, dropG)
		corner(c, UDim.new(0.5, 0))
	end
	local streak = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -27),
		Size = UDim2.fromOffset(2, 0),
		BackgroundColor3 = C.GoldPale,
		BorderSizePixel = 0,
	}, dropG)
	grad(streak, { Rotation = 90, Transparency = nsq({ { 0, 1 }, { 1, 0.45 } }) })
	local drop = buildDrop(dropG, 9, false, 0)
	drop.Position = UDim2.fromScale(0.5, 0.5)

	-- vineta
	local function edge(pos, size, rot)
		local f = new("Frame", {
			Position = pos,
			Size = size,
			BackgroundColor3 = C.Void,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, root)
		grad(f, { Rotation = rot, Transparency = nsq({ { 0, 0.2 }, { 1, 1 } }) })
	end
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90)
	edge(UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.3), -90)
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.18, 1), 0)
	edge(UDim2.fromScale(0.82, 0), UDim2.fromScale(0.18, 1), 180)

	-- UI (titulo, divisor, progreso)
	local ui = new("Frame", { Name = "UI", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, root)
	local textHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, ui)
	local dv = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.345),
		Size = UDim2.fromOffset(0, 1),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
	}, ui)
	grad(dv, { Transparency = nsq({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }) })
	local dvDia = diamond(dv, 7, C.GoldPale, { Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 })

	local pTrack = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.93),
		Size = UDim2.new(0.5, 0, 0, 2),
		BackgroundColor3 = C.Gold,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
	}, ui)
	new("UISizeConstraint", { MaxSize = Vector2.new(360, 2) }, pTrack)
	local pFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, pTrack)
	grad(pFill, { Color = GOLD_FILL })
	local pLbl = mkText(ui, "00", 18, C.Gold, FONT_DISPLAY, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.93, -10),
		Size = UDim2.fromOffset(120, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local skip = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(64, 26),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.2,
		Text = "SKIP",
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = C.Gold,
		AutoButtonColor = false,
		ZIndex = 9,
	}, root)
	corner(skip, 6)
	local skipSt = stroke(skip, C.Gold, 1, 0.5)
	hover(maid, skip, function()
		tween(skipSt, 0.2, { Transparency = 0 })
		tween(skip, 0.2, { TextColor3 = C.GoldPale })
	end, function()
		tween(skipSt, 0.2, { Transparency = 0.5 })
		tween(skip, 0.2, { TextColor3 = C.Gold })
	end)
	maid:Add(skip.MouseButton1Click:Connect(function()
		I:Skip()
	end))

	local function randomize()
		for _, s in ipairs(stars) do
			s.x, s.y, s.r = R2:NextNumber(), R2:NextNumber() * 3, R2:NextNumber() * 1.4 + 0.4
			s.F.BackgroundTransparency = 1 - (R2:NextNumber() * 0.5 + 0.2)
		end
		for _, b in ipairs(bokeh) do
			b.x, b.y, b.r = R2:NextNumber(), R2:NextNumber() * HOR, R2:NextNumber() * 50 + 25
			b.F.Size = UDim2.fromOffset(b.r * 2, b.r * 2)
		end
		for _, g in ipairs(glints) do
			g.x, g.y = R2:NextNumber(), HOR + 0.06 + R2:NextNumber() * 1.2
			g.l, g.s, g.p = R2:NextNumber() * 40 + 14, R2:NextNumber() * 2 + 1, R2:NextNumber() * 6
			g.F.Size = UDim2.fromOffset(g.l, 1.5)
		end
	end

	local function spawnRing(t0, rx, dur, th, br)
		for _, r in ipairs(rings) do
			if not r.Active then
				ringStart(r, t0, rx, dur, th, br)
				return
			end
		end
	end

	local function reveal(letters, step, alive, shine)
		for i, L in ipairs(letters) do
			task.delay((i - 1) * step, function()
				if not alive() then
					return
				end
				tween(L.Label, 1, { TextTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart)
				if shine and L.Grad then
					L.Grad.Offset = Vector2.new(-1, 0)
					task.delay(0.4 + (i - 1) * 0.08, function()
						if not alive() then
							return
						end
						local tw = TweenService:Create(
							L.Grad,
							TweenInfo.new(2.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
							{ Offset = Vector2.new(1, 0) }
						)
						tw:Play()
						I._tweens[#I._tweens + 1] = tw
					end)
				end
			end)
		end
	end

	function I:Stop()
		self.Running = false
		self.Run = self.Run + 1
		if self._conn then
			self._conn:Disconnect()
			self._conn = nil
		end
		for _, tw in ipairs(self._tweens) do
			pcall(function()
				tw:Cancel()
			end)
		end
		self._tweens = {}
	end

	function I:Hide()
		root.Visible = false
	end

	function I:_finish()
		local cb = self._done
		self._done = nil
		self:Stop()
		if cb then
			cb()
		end
	end

	function I:Skip()
		if self.Running then
			self:_finish()
		end
	end

	function I:Play(onDone)
		self:Stop()
		self.Run = self.Run + 1
		local run = self.Run
		self.Running = true
		self._done = onDone
		root.Visible = true
		randomize()
		for _, r in ipairs(rings) do
			r.Active = false
			r.Frame.Visible = false
		end
		for _, p in ipairs(parts) do
			p.Dead = true
			p.F.Visible = false
		end
		glow.Visible, jet.Visible = false, false
		world.Position = UDim2.new()
		dv.Size = UDim2.fromOffset(0, 1)
		dvDia.BackgroundTransparency = 1
		pFill.Size = UDim2.fromScale(0, 1)
		pLbl.Text = "00"

		local vp = viewport()
		textHolder:ClearAllChildren()
		local tsz = math.floor(clampN(vp.X * 0.08, 30, 64) + 0.5)
		local ssz = math.floor(clampN(vp.X * 0.017, 11, 15) + 0.5)
		local trow, tl = buildLetters(textHolder, owner.Title, tsz, FONT_DISPLAY, math.floor(tsz * 0.06 + 0.5), true)
		trow.Position = UDim2.new(0, 0, 0.27, 0)
		local srow, sl = buildLetters(textHolder, owner.Subtitle, ssz, FONT_UI, math.floor(ssz * 0.4 + 0.5), false)
		srow.Position = UDim2.new(0, 0, 0.395, 0)

		local function alive()
			return self.Running and self.Run == run
		end

		local t0 = os.clock()
		local lastCy
		local imp, idleT, shaken = false, 0, false

		self._conn = RunService.RenderStepped:Connect(function(dt)
			if not alive() then
				return
			end
			local t = os.clock() - t0
			local abs = root.AbsoluteSize
			local W, H = abs.X, abs.Y
			if W < 10 or H < 10 then
				local v = viewport()
				W, H = v.X, v.Y
			end

			-- camara
			local cam
			if t < FALL then
				cam = 1.6 * (t / FALL) ^ 2
			else
				cam = 1.6 - 0.24 * outQuart(math.min(1, (t - FALL) / 1.9))
			end
			local cy = cam * H
			local moved = lastCy == nil or math.abs(cy - lastCy) > 0.02
			local vcam = lastCy and (cy - lastCy) / math.max(dt, 0.001) or 0
			lastCy = cy
			local hy = HOR * H - cy

			if moved then
				local streakK = math.abs(vcam) * 0.011
				for _, s in ipairs(stars) do
					s.F.Position = UDim2.fromOffset(s.x * W, s.y * H - cy * 0.5)
					s.F.Size = UDim2.fromOffset(s.r * 2, s.r * 2 + streakK)
				end
				for _, b in ipairs(bokeh) do
					b.F.Position = UDim2.fromOffset(b.x * W, b.y * H - cy)
				end
				if hy < H then
					floor.Visible = true
					floor.Position = UDim2.fromOffset(0, hy)
					floor.Size = UDim2.new(1, 0, 0, math.max(H - hy, 1))
					horizon.Visible = hy > -2
					horizon.Position = UDim2.fromOffset(0, hy)
				else
					floor.Visible = false
					horizon.Visible = false
				end
			end
			for _, g in ipairs(glints) do
				local y = g.y * H - cy
				if hy < H and y > 0 and y < H then
					g.F.Visible = true
					g.F.Position = UDim2.fromOffset(g.x * W, y)
					g.F.BackgroundTransparency = 1 - (0.1 + 0.35 * math.max(0, math.sin(t * g.s + g.p)))
				else
					g.F.Visible = false
				end
			end

			-- gota
			if t < FALL then
				dropG.Visible = true
				dropG.Position = UDim2.fromOffset(W / 2, 0.4 * H + 7)
				streak.Size = UDim2.fromOffset(2, 150 * math.min(1, t / FALL * 2))
			else
				dropG.Visible = false
			end

			-- impacto
			local ix, iy = W / 2, WY * H - cy
			if t >= FALL and not imp then
				imp = true
				local base = math.min(W * 0.55, 820)
				for i = 0, 5 do
					spawnRing(t + i * 0.2, base * (1 - i * 0.06), 3.4, 2.2 - i * 0.2, 1)
				end
				spawnRing(t + 0.05, base * 0.35, 1.6, 2.6, 1)
				for _, p in ipairs(parts) do
					p.x, p.y = ix, 0
					p.vx = (R2:NextNumber() - 0.5) * H * 0.5
					p.vy = -(120 + R2:NextNumber() * 300)
					p.s = 1.5 + R2:NextNumber() * 2.2
					p.Dead = false
					p.F.Size = UDim2.fromOffset(p.s * 2, p.s * 2)
					p.F.Visible = true
				end
				task.delay(0.7, function()
					if alive() then
						reveal(tl, 0.1, alive, true)
					end
				end)
				task.delay(1.8, function()
					if alive() then
						tween(dv, 1.2, { Size = UDim2.fromOffset(math.min(W * 0.5, 420), 1) }, Enum.EasingStyle.Quart)
						tween(dvDia, 0.8, { BackgroundTransparency = 0 })
					end
				end)
				task.delay(2.3, function()
					if alive() then
						reveal(sl, 0.06, alive, false)
					end
				end)
			end
			if imp and t > 3.6 and t > idleT then
				idleT = t + 0.8 + R2:NextNumber() * 0.5
				spawnRing(t, (0.18 + R2:NextNumber() * 0.22) * W, 3, 1.4, 0.8)
			end
			for _, r in ipairs(rings) do
				if r.Active then
					ringUpdate(r, t, ix, iy)
				end
			end

			if imp then
				local q = t - FALL
				-- temblor de camara
				if q < 0.5 then
					local k = (1 - q / 0.5) ^ 2 * 7
					world.Position = UDim2.fromOffset(R2:NextNumber(-k, k), R2:NextNumber(-k, k))
				elseif not shaken then
					shaken = true
					world.Position = UDim2.new()
				end
				-- resplandor plano
				if q < 0.9 then
					local p = q / 0.9
					local rr = math.min(W * 0.35, 260) * outQuart(p)
					glow.Visible = true
					glow.Size = UDim2.fromOffset(math.max(rr * 2, 2), math.max(rr * 0.6, 1))
					glow.Position = UDim2.fromOffset(ix, iy)
					glow.BackgroundTransparency = 1 - 0.6 * (1 - p)
				else
					glow.Visible = false
				end
				-- chorro
				if q < 0.6 then
					local p = q / 0.6
					local h = H * 0.17 * math.sin(math.pi * p)
					jet.Visible = true
					jet.Size = UDim2.fromOffset(8, math.max(h, 1))
					jet.Position = UDim2.fromOffset(ix, iy)
				else
					jet.Visible = false
				end
				-- salpicaduras
				for _, p in ipairs(parts) do
					if not p.Dead then
						p.vy = p.vy + 900 * dt
						p.y = p.y + p.vy * dt
						p.x = p.x + p.vx * dt * 0.4
						if p.y > 8 then
							p.Dead = true
							p.F.Visible = false
						else
							p.F.Position = UDim2.fromOffset(p.x, WY * H + p.y - cy)
							p.F.BackgroundTransparency = 1 - math.min(1, (8 - p.y) / 80 + 0.2)
						end
					end
				end
			end

			-- progreso
			local pr = math.min(1, t / TT)
			local pe = pr < 0.5 and 2 * pr * pr or 1 - (-2 * pr + 2) ^ 2 / 2
			pFill.Size = UDim2.fromScale(pe, 1)
			pLbl.Text = string.format("%02d", math.floor(pe * 100 + 0.5))

			if t >= TT + 0.6 then
				self:_finish()
			end
		end)
	end

	maid:Add(function()
		I:Stop()
	end)
	return I
end


--------------------------------------------------------------------------
-- VENTANA
--------------------------------------------------------------------------
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

local MIN_W, MIN_H = 340, 250

function UI_Library.CreateWindow(cfg)
	cfg = cfg or {}
	if UI_Library._current then
		pcall(function()
			UI_Library._current:Destroy()
		end)
	end
	local self = setmetatable({}, Window)
	UI_Library._current = self
	local maid = newMaid()
	self.Maid = maid
	self.Tabs = {}
	self.Title = cfg.Title or "FROGGY HUB"
	self.Subtitle = cfg.Subtitle or "100 MEMBERS EDITION"
	self.LogEvents = cfg.LogEvents ~= false
	self.ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	self.OnClose = cfg.OnClose
	self.State = "hidden"
	self._prev = "open"
	self._notifN = 0
	self._logN = 0
	self._hideWin = true
	local resizable = cfg.Resizable ~= false

	local gui = new("ScreenGui", {
		Name = "FroggyHub_" .. tostring(rng:NextInteger(1000, 9999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 9999,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	mountGui(gui)
	maid:Add(gui)
	self.Gui = gui

	----------------------------------------------------------------------
	-- marco principal
	----------------------------------------------------------------------
	local vp = viewport()
	self.Size = Vector2.new(math.floor(math.min(540, vp.X * 0.94)), math.floor(math.min(420, vp.Y * 0.72)))
	self.Pos = Vector2.new(0, 0)

	local win = new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true, -- evita que los clics sobre la ventana lleguen al juego
		Visible = false,
		ZIndex = 10,
	}, gui)
	corner(win, 10)
	grad(win, { Rotation = 35, Color = PANEL_SEQ })
	local wscale = new("UIScale", { Scale = 0.001 }, win)
	local wstroke = stroke(win, WHITE, 2.5, 0)
	local wgrad = grad(wstroke, { Color = BORDER_SEQ })
	loopTween(maid, wgrad, 5, { Rotation = 360 }, Enum.EasingStyle.Linear, false, Enum.EasingDirection.In)
	self._win = win

	self._scaleSp = spring(maid, 0.001, 190, 0.55, function(s)
		wscale.Scale = math.max(s, 0.001)
		if self._hideWin and s < 0.05 then
			win.Visible = false
		end
	end, 0.001)
	self._posSp = spring(maid, Vector2.new(0, 0), 520, 0.9, function(p)
		win.Position = UDim2.new(0.5, p.X, 0.5, p.Y)
	end, 0.05)

	-- efectos de fondo (recortados al marco)
	local fx = new("Frame", {
		Name = "FX",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
	}, win)
	local shimmer = new("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(-0.7, 0),
		Size = UDim2.fromScale(0.6, 1),
		BackgroundColor3 = C.GoldPale,
		BorderSizePixel = 0,
	}, fx)
	grad(shimmer, { Transparency = nsq({ { 0, 1 }, { 0.5, 0.9 }, { 1, 1 } }) })
	TweenService:Create(
		shimmer,
		TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.5),
		{ Position = UDim2.fromScale(1.1, 0) }
	):Play()

	-- polvo dorado ascendente
	for i = 1, 14 do
		local d = diamond(fx, 4, C.GoldBright, { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, 6) })
		task.spawn(function()
			task.wait(rng:NextNumber(0, 8))
			while not maid.dead do
				local dur = rng:NextNumber(7, 15)
				local x = rng:NextNumber()
				d.Position = UDim2.new(x, 0, 1, 6)
				d.Rotation = 45
				d.BackgroundTransparency = 1
				tween(d, dur, { Position = UDim2.new(x, 0, 1, -(self.Size.Y + 12)), Rotation = 225 }, Enum.EasingStyle.Linear)
				tween(d, dur * 0.15, { BackgroundTransparency = 0.2 })
				task.wait(dur * 0.15)
				tween(d, dur * 0.85, { BackgroundTransparency = 1 }, Enum.EasingStyle.Linear)
				task.wait(dur * 0.85)
			end
		end)
	end
	-- ondas decorativas (esquina inferior derecha)
	for i = 0, 1 do
		local rp = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.84, 0, 0.88, 0),
			Size = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
		}, fx)
		corner(rp, UDim.new(0.5, 0))
		local rst = stroke(rp, C.Gold, 1.4, 1)
		task.spawn(function()
			task.wait(i * 1.7)
			while not maid.dead do
				rp.Size = UDim2.fromOffset(10, 10)
				rst.Transparency = 0.5
				tween(rp, 3.4, { Size = UDim2.fromOffset(300, 300) }, Enum.EasingStyle.Quad)
				tween(rst, 3.4, { Transparency = 1 }, Enum.EasingStyle.Quad)
				task.wait(3.4)
			end
		end)
	end

	-- filigrana + esquinas
	local fil = new("Frame", {
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, win)
	corner(fil, 5)
	stroke(fil, C.Gold, 1, 0.72)
	for _, p in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		diamond(win, 6, C.GoldBright, {
			Position = UDim2.new(p[1], p[1] == 0 and 4 or -4, p[2], p[2] == 0 and 4 or -4),
			ZIndex = 8,
		})
	end

	----------------------------------------------------------------------
	-- barra superior
	----------------------------------------------------------------------
	local top = new("Frame", {
		Name = "TopBar",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 44),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 3,
	}, win)
	corner(top, 4)
	local ul = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.GoldBright,
		BorderSizePixel = 0,
	}, top)
	grad(ul, { Transparency = nsq({ { 0, 1 }, { 0.2, 0 }, { 0.8, 0 }, { 1, 1 } }) })

	local crown = buildCrown(top, 28, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), ZIndex = 4 })
	for i, sp in ipairs({ { 8, 8, 9 }, { 36, 30, 7 } }) do
		local f, sc = buildSparkle(top, sp[3], C.GoldPale)
		f.Position = UDim2.fromOffset(sp[1], sp[2])
		twinkle(maid, sc, 2.4 + i * 0.5, i * 0.7)
	end

	local titleLbl = mkText(top, self.Title, 20, WHITE, FONT_DISPLAY, {
		Position = UDim2.fromOffset(50, 4),
		Size = UDim2.new(1, -150, 0, 22),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})
	local tg = grad(titleLbl, { Color = TITLE_TEXT_SEQ })
	tg.Offset = Vector2.new(-0.25, 0) -- antes del tween: asi barre de -0.25 a 0.25
	loopTween(maid, tg, 3.2, { Offset = Vector2.new(0.25, 0) }, Enum.EasingStyle.Sine, true)
	local subLbl = mkText(top, tracked(string.upper(self.Subtitle)), 10, C.Gold, FONT_UI, {
		Position = UDim2.fromOffset(50, 27),
		Size = UDim2.new(1, -150, 0, 12),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})
	self._titleLbl, self._subLbl = titleLbl, subLbl

	local function iconButton(pos, kind)
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = pos,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = C.Gold,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 5,
		}, top)
		corner(b, 5)
		local bs = stroke(b, C.Gold, 1, 0.5)
		local ic = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, b)
		local lines = {}
		for i = 1, (kind == "x") and 2 or 1 do
			lines[i] = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(13, 2),
				BackgroundColor3 = C.Gold,
				BorderSizePixel = 0,
				Rotation = (kind == "x") and (i == 1 and 45 or -45) or 0,
			}, ic)
		end
		hover(maid, b, function()
			tween(b, 0.25, { BackgroundTransparency = 0.82 })
			tween(bs, 0.25, { Transparency = 0 })
			for _, l in ipairs(lines) do
				tween(l, 0.25, { BackgroundColor3 = C.GoldPale })
			end
			if kind == "x" then
				tween(ic, 0.35, { Rotation = 90 }, Enum.EasingStyle.Back)
			end
		end, function()
			tween(b, 0.25, { BackgroundTransparency = 1 })
			tween(bs, 0.25, { Transparency = 0.5 })
			for _, l in ipairs(lines) do
				tween(l, 0.25, { BackgroundColor3 = C.Gold })
			end
			if kind == "x" then
				tween(ic, 0.35, { Rotation = 0 })
			end
		end)
		return b
	end
	local btnMin = iconButton(UDim2.new(1, -42, 0.5, 0), "min")
	local btnCls = iconButton(UDim2.new(1, -8, 0.5, 0), "x")
	maid:Add(btnMin.MouseButton1Click:Connect(function()
		self:Minimize()
	end))
	maid:Add(btnCls.MouseButton1Click:Connect(function()
		self:Destroy()
	end))

	----------------------------------------------------------------------
	-- cuerpo: barra lateral + paginas
	----------------------------------------------------------------------
	local body = new("Frame", {
		Position = UDim2.fromOffset(10, 56),
		Size = UDim2.new(1, -20, 1, -66),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, win)
	local side = new("Frame", {
		Size = UDim2.new(0, 94, 1, 0),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, body)
	corner(side, 5)
	stroke(side, C.Gold, 1, 0.75)
	local tabScroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, side)
	local tabList = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, tabScroll)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
	}, tabList)
	local marker = new("Frame", {
		Position = UDim2.fromOffset(6, 14),
		Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 3,
	}, tabScroll)
	corner(marker, 2)
	grad(marker, { Rotation = 90, Color = cseq(C.GoldPale, C.Gold) })
	self._markerSp = spring(maid, 14, 320, 0.6, function(y)
		marker.Position = UDim2.fromOffset(6, y)
	end, 0.05)
	self._marker, self._tabList = marker, tabList

	local pages = new("Frame", {
		Position = UDim2.fromOffset(102, 0),
		Size = UDim2.new(1, -102, 1, 0),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, body)
	corner(pages, 5)
	stroke(pages, C.Gold, 1, 0.75)
	self._pages = pages

	----------------------------------------------------------------------
	-- arrastrar (barra superior) con resorte
	----------------------------------------------------------------------
	local drag
	maid:Add(top.InputBegan:Connect(function(input)
		if isPress(input) then
			drag = { start = input.Position, from = self.Pos, input = input }
		end
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if drag and (input == drag.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - drag.start
			self:_setPos(drag.from + Vector2.new(d.X, d.Y))
		end
	end))
	maid:Add(UIS.InputEnded:Connect(function(input)
		if drag and (input == drag.input or isPress(input)) then
			drag = nil
		end
	end))

	----------------------------------------------------------------------
	-- redimensionar (esquina inferior derecha)
	----------------------------------------------------------------------
	if resizable then
		local grip = new("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -3, 1, -3),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 20,
		}, win)
		for _, p in ipairs({ { 15, 15 }, { 10, 15 }, { 15, 10 }, { 5, 15 }, { 10, 10 }, { 15, 5 } }) do
			diamond(grip, 3, C.Gold, { Position = UDim2.fromOffset(p[1], p[2]), ZIndex = 21 })
		end
		local rs
		maid:Add(grip.InputBegan:Connect(function(input)
			if isPress(input) then
				rs = { start = input.Position, size0 = self.Size, pos0 = self.Pos, input = input }
			end
		end))
		maid:Add(UIS.InputChanged:Connect(function(input)
			if rs and (input == rs.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = input.Position - rs.start
				local v = viewport()
				local ns = Vector2.new(
					clampN(rs.size0.X + d.X, MIN_W, math.max(MIN_W, v.X - 20)),
					clampN(rs.size0.Y + d.Y, MIN_H, math.max(MIN_H, v.Y - 20))
				)
				self.Size = ns
				win.Size = UDim2.fromOffset(ns.X, ns.Y)
				self:_setPos(rs.pos0 + (ns - rs.size0) / 2, true)
			end
		end))
		maid:Add(UIS.InputEnded:Connect(function(input)
			if rs and (input == rs.input or isPress(input)) then
				rs = nil
			end
		end))
	end

	----------------------------------------------------------------------
	-- burbuja (minimizado)
	----------------------------------------------------------------------
	local bub = new("TextButton", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(54, 90),
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
	}, gui)
	corner(bub, UDim.new(0.5, 0))
	grad(bub, { Rotation = 60, Color = PANEL_SEQ })
	local bubScale = new("UIScale", { Scale = 0.001 }, bub)
	local bst = stroke(bub, WHITE, 2.5, 0)
	local bgr = grad(bst, { Color = BORDER_SEQ })
	loopTween(maid, bgr, 3, { Rotation = 360 }, Enum.EasingStyle.Linear, false, Enum.EasingDirection.In)
	local bcrown = buildCrown(bub, 34, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 2),
		ZIndex = 2,
	})
	loopTween(maid, bcrown, 1.1, { Position = UDim2.new(0.5, 0, 0.5, -3) }, Enum.EasingStyle.Sine, true)
	self._bub = bub
	self._bubSp = spring(maid, 0.001, 260, 0.55, function(s)
		bubScale.Scale = math.max(s, 0.001)
		bub.Visible = s > 0.02
	end, 0.001)

	local bd
	maid:Add(bub.InputBegan:Connect(function(input)
		if isPress(input) then
			bd = { start = input.Position, from = bub.AbsolutePosition + bub.AbsoluteSize / 2, moved = false, input = input }
		end
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if bd and (input == bd.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - bd.start
			local dv2 = Vector2.new(d.X, d.Y)
			if dv2.Magnitude > 6 then
				bd.moved = true
			end
			if bd.moved then
				local v = viewport()
				local p = bd.from + dv2
				bub.Position = UDim2.fromOffset(clampN(p.X, 34, v.X - 34), clampN(p.Y, 34, v.Y - 34))
			end
		end
	end))
	maid:Add(UIS.InputEnded:Connect(function(input)
		if bd and (input == bd.input or isPress(input)) then
			local wasClick = not bd.moved
			bd = nil
			if wasClick then
				self:Restore()
			end
		end
	end))

	----------------------------------------------------------------------
	-- notificaciones, log y flash
	----------------------------------------------------------------------
	local notifList = new("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -64),
		Size = UDim2.new(0, 290, 1, -96),
		BackgroundTransparency = 1,
		ZIndex = 60,
	}, gui)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, notifList)
	self._notifList = notifList

	local pill = new("Frame", {
		Name = "LogPill",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 70,
	}, gui)
	corner(pill, 5)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
	}, pill)
	local pillSt = stroke(pill, C.Gold, 1, 1)
	local pillLbl = mkText(pill, "", 12, C.GoldPale, FONT_UI, {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	self._pill, self._pillSt, self._pillLbl = pill, pillSt, pillLbl

	local flash = new("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.GoldPale,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, gui)
	self._flash = flash

	self._intro = buildIntro(gui, maid, self)

	----------------------------------------------------------------------
	-- tecla para mostrar / ocultar
	----------------------------------------------------------------------
	maid:Add(UIS.InputBegan:Connect(function(input, gpe)
		if gpe or self._listening then
			return
		end
		if input.KeyCode == self.ToggleKey and self.ToggleKey ~= Enum.KeyCode.Unknown then
			self:Toggle()
		end
	end))

	if cfg.Intro ~= false then
		self:_playIntro()
	else
		self:_open()
	end
	return self
end

--------------------------------------------------------------------------
-- ESTADOS (abierta / minimizada / oculta)
--------------------------------------------------------------------------
function Window:_setPos(p, snap)
	self.Pos = self:_clampPos(p)
	if snap then
		self._posSp:Snap(self.Pos)
	else
		self._posSp:Set(self.Pos)
	end
end

function Window:_clampPos(p)
	local vp = viewport()
	local w, h = self.Size.X, self.Size.Y
	return Vector2.new(
		clampN(p.X, 100 - vp.X / 2 - w / 2, vp.X / 2 - 100 + w / 2),
		clampN(p.Y, -vp.Y / 2 + h / 2, vp.Y / 2 - 44 + h / 2)
	)
end

function Window:_showBubble()
	self._bubSp:Tune(220, 0.5)
	self._bubSp:Set(1)
end

function Window:_hideBubble()
	self._bubSp:Tune(320, 1)
	self._bubSp:Set(0.001)
end

function Window:_hideWindow()
	self._hideWin = true
	self._scaleSp:Tune(320, 1)
	self._scaleSp:Set(0.001)
end

function Window:_open()
	if self.Destroyed then
		return
	end
	self.State = "open"
	self._hideWin = false
	if not self._win.Visible then
		self._win.Visible = true
		self._scaleSp:Snap(0.7)
	end
	self._scaleSp:Tune(190, 0.55)
	self._scaleSp:Set(1)
	self:_hideBubble()
end

function Window:Minimize()
	if self.Destroyed or self.State ~= "open" then
		return
	end
	self.State = "min"
	self:_hideWindow()
	self:_showBubble()
end

function Window:Restore()
	if self.Destroyed then
		return
	end
	if self.State == "min" then
		self:_open()
	end
end

function Window:Toggle()
	if self.Destroyed or self._introRunning then
		return
	end
	if self.State == "hidden" then
		if self._prev == "min" then
			self.State = "min"
			self:_showBubble()
		else
			self:_open()
		end
	else
		self._prev = self.State
		self.State = "hidden"
		self:_hideWindow()
		self:_hideBubble()
	end
end

function Window:SetToggleKey(key)
	self.ToggleKey = key
end

function Window:SetTitle(title, subtitle)
	if title then
		self.Title = title
		self._titleLbl.Text = title
	end
	if subtitle then
		self.Subtitle = subtitle
		self._subLbl.Text = tracked(string.upper(subtitle))
	end
end

function Window:_playIntro()
	if self.Destroyed then
		return
	end
	self._introRunning = true
	self.State = "hidden"
	self._hideWin = true
	self._scaleSp:Snap(0.001)
	self._win.Visible = false
	self:_hideBubble()
	self._intro:Play(function()
		self:_afterIntro()
	end)
end

function Window:_afterIntro()
	if self.Destroyed then
		return
	end
	local flash = self._flash
	tween(flash, 0.4, { BackgroundTransparency = 0 })
	task.delay(0.42, function()
		if self.Destroyed then
			return
		end
		self._intro:Hide()
		self._introRunning = false
		self:_open()
		tween(flash, 1, { BackgroundTransparency = 1 })
	end)
end

function Window:ReplayIntro()
	if self.Destroyed or self._introRunning then
		return
	end
	self:_playIntro()
end

function Window:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	if UI_Library._current == self then
		UI_Library._current = nil
	end
	self.State = "closed"
	if self._intro then
		self._intro:Stop()
		self._intro:Hide()
	end
	self:_hideBubble()
	if self._win and self._win.Visible then
		self._hideWin = true
		self._scaleSp:Tune(320, 1)
		self._scaleSp:Set(0.02)
	end
	if type(self.OnClose) == "function" then
		task.spawn(self.OnClose)
	end
	task.delay(0.4, function()
		self.Maid:Destroy()
	end)
end

--------------------------------------------------------------------------
-- LOG (pildora inferior) y NOTIFICACIONES
--------------------------------------------------------------------------
function Window:_log(msg)
	if not self.LogEvents or self.Destroyed then
		return
	end
	self._logN = self._logN + 1
	local n = self._logN
	self._pillLbl.Text = msg
	tween(self._pill, 0.2, { BackgroundTransparency = 0.1 })
	tween(self._pillSt, 0.2, { Transparency = 0 })
	tween(self._pillLbl, 0.2, { TextTransparency = 0 })
	task.delay(1.7, function()
		if self._logN == n and not self.Destroyed then
			tween(self._pill, 0.3, { BackgroundTransparency = 1 })
			tween(self._pillSt, 0.3, { Transparency = 1 })
			tween(self._pillLbl, 0.3, { TextTransparency = 1 })
		end
	end)
end

local NOTIFY_COLORS = { info = C.Gold, success = C.Green, warning = C.Warn, error = C.Red }

function Window:Notify(opts)
	if self.Destroyed then
		return
	end
	if type(opts) ~= "table" then
		opts = { Content = tostring(opts) }
	end
	local title = tostring(opts.Title or self.Title)
	local content = tostring(opts.Content or "")
	local dur = opts.Duration or 4
	local accent = NOTIFY_COLORS[opts.Type or "info"] or C.Gold
	local textW = 290 - 56
	local th = measure(title, 14, FONT_BOLD, textW).Y
	local ch = content ~= "" and measure(content, 12, FONT_UI, textW).Y or 0
	local h = math.max(54, 12 + th + (ch > 0 and 4 + ch or 0) + 16)

	self._notifN = self._notifN + 1
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		BackgroundTransparency = 1,
		LayoutOrder = self._notifN,
	}, self._notifList)
	local card = new("Frame", {
		Position = UDim2.new(1.3, 0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, holder)
	corner(card, 6)
	grad(card, { Rotation = 35, Color = PANEL_SEQ })
	stroke(card, accent, 1.2, 0.35)
	local bar = new("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, card)
	diamond(card, 8, accent, { Position = UDim2.fromOffset(24, h / 2) })
	mkText(card, title, 14, accent == C.Gold and C.GoldBright or accent, FONT_BOLD, {
		Position = UDim2.fromOffset(44, 10),
		Size = UDim2.new(1, -56, 0, th),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	if ch > 0 then
		mkText(card, content, 12, C.Text, FONT_UI, {
			Position = UDim2.fromOffset(44, 10 + th + 4),
			Size = UDim2.new(1, -56, 0, ch),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	local timeline = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, card)
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, card)

	local notifMaid = self.Maid
	local sp = spring(notifMaid, 1.3, 220, 0.72, function(x)
		card.Position = UDim2.new(x, 0, 0, 0)
	end, 0.002)
	sp:Set(0)
	if dur > 0 then
		tween(timeline, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	end

	local closed = false
	local obj = {}
	function obj:Close()
		if closed then
			return
		end
		closed = true
		sp:Set(1.3)
		task.delay(0.35, function()
			tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quart)
			task.delay(0.3, function()
				sp:Destroy()
				notifMaid:Remove(sp)
				holder:Destroy()
			end)
		end)
	end
	hit.MouseButton1Click:Connect(function()
		obj:Close()
	end)
	if dur > 0 then
		task.delay(dur, function()
			obj:Close()
		end)
	end
	return obj
end


--------------------------------------------------------------------------
-- PESTANAS
--------------------------------------------------------------------------
function Window:CreateTab(name)
	name = tostring(name or "TAB")
	local tab = setmetatable({}, Tab)
	local maid = self.Maid
	tab.Window = self
	tab.Name = name
	tab.Index = #self.Tabs + 1
	tab._n = 0

	local btn = new("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = C.Gold,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = tab.Index,
	}, self._tabList)
	corner(btn, 4)
	local lbl = mkText(btn, string.upper(name), 12, C.Muted, FONT_BOLD, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -14, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	tab.Button, tab.Label = btn, lbl

	local page = new("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Gold,
		ScrollBarImageTransparency = 0.3,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
	}, self._pages)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10),
	}, page)
	tab.Page = page

	hover(maid, btn, function()
		if self.ActiveTab ~= tab then
			tween(lbl, 0.2, { TextColor3 = C.GoldPale })
		end
	end, function()
		if self.ActiveTab ~= tab then
			tween(lbl, 0.2, { TextColor3 = C.Muted })
		end
	end)
	maid:Add(btn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end))

	self.Tabs[#self.Tabs + 1] = tab
	if #self.Tabs == 1 then
		self:SelectTab(tab, true)
	end
	return tab
end

function Window:SelectTab(t, instant)
	if type(t) == "string" then
		for _, x in ipairs(self.Tabs) do
			if x.Name == t then
				t = x
				break
			end
		end
	end
	if type(t) ~= "table" or self.ActiveTab == t then
		return
	end
	local old = self.ActiveTab
	if old then
		old.Page.Visible = false
		tween(old.Button, 0.3, { BackgroundTransparency = 1 })
		tween(old.Label, 0.3, { TextColor3 = C.Muted })
	end
	self.ActiveTab = t
	t.Page.Visible = true
	tween(t.Button, 0.3, { BackgroundTransparency = 0.88 })
	tween(t.Label, 0.3, { TextColor3 = C.GoldBright })
	local y = 14 + (t.Index - 1) * 36
	self._marker.Visible = true
	if instant then
		self._markerSp:Snap(y)
	else
		self._markerSp:Set(y)
		t.Page.Position = UDim2.fromOffset(0, 14)
		tween(t.Page, 0.45, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

--------------------------------------------------------------------------
-- BASE DE FILAS
--------------------------------------------------------------------------
local function makeRow(tab, h, bindHover)
	tab._n = tab._n + 1
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, h or 40),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		LayoutOrder = tab._n,
	}, tab.Page)
	corner(row, 5)
	local st = stroke(row, C.Gold, 1, 0.65)
	if bindHover ~= false then
		hoverStroke(tab.Window.Maid, row, st, 0.2, 0.65)
	end
	return row, st
end

local function rowLabel(row, str, rightReserve)
	return mkText(row, str, 14, C.Text, FONT_UI, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -(14 + (rightReserve or 14)), 0, 40),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

local function hitButton(parent, z)
	return new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = z or 6,
	}, parent)
end

--------------------------------------------------------------------------
-- SECCION / LABEL / PARRAFO / DIVISOR
--------------------------------------------------------------------------
function Tab:AddSection(str)
	self._n = self._n + 1
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = self._n,
	}, self.Page)
	diamond(f, 5, C.Gold, { Position = UDim2.fromOffset(3, 9) })
	local lbl = mkText(f, tracked(string.upper(str)), 11, C.Gold, FONT_BOLD, {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -16, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
	}, f)
	grad(line, { Transparency = nsq({ { 0, 0 }, { 1, 1 } }) })
	local obj = { Instance = f }
	function obj:SetText(s)
		lbl.Text = tracked(string.upper(s))
	end
	return obj
end

function Tab:AddLabel(str)
	self._n = self._n + 1
	local lbl = mkText(self.Page, str, 13, C.Muted, FONT_UI, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = self._n,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, lbl)
	local obj = { Instance = lbl }
	function obj:SetText(s)
		lbl.Text = s
	end
	return obj
end

function Tab:AddParagraph(title, body)
	self._n = self._n + 1
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		LayoutOrder = self._n,
	}, self.Page)
	corner(row, 5)
	stroke(row, C.Gold, 1, 0.75)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
	}, row)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local t = mkText(row, title, 15, C.GoldBright, FONT_DISPLAY, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	local b = mkText(row, body or "", 13, C.Muted, FONT_UI, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
	})
	local obj = { Instance = row }
	function obj:Set(ti, bo)
		if ti then
			t.Text = ti
		end
		if bo then
			b.Text = bo
		end
	end
	return obj
end

function Tab:AddDivider()
	self._n = self._n + 1
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundTransparency = 1,
		LayoutOrder = self._n,
	}, self.Page)
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
	}, f)
	grad(line, { Transparency = nsq({ { 0, 1 }, { 0.5, 0.1 }, { 1, 1 } }) })
	diamond(f, 5, C.GoldPale, { Position = UDim2.fromScale(0.5, 0.5) })
	return { Instance = f }
end

--------------------------------------------------------------------------
-- TOGGLE
--------------------------------------------------------------------------
function Tab:AddToggle(str, default, callback)
	local win = self.Window
	local maid = win.Maid
	local row, st = makeRow(self, 40, false)
	local state = default and true or false
	local label = rowLabel(row, str, 76)
	local btn = hitButton(row)
	hoverStroke(maid, btn, st, 0.2, 0.65)

	local trk = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(48, 22),
		BackgroundColor3 = C.Black,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, row)
	corner(trk, 5)
	local tst = stroke(trk, C.Gold, 1.2, 0.35)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, trk)
	grad(fill, { Color = GOLD_FILL })
	local knob = diamond(trk, 12, C.Gold, { Position = UDim2.new(0, 13, 0.5, 0), ZIndex = 2 })
	local kst = stroke(knob, C.GoldPale, 1, 0)

	local sp = spring(maid, state and 1 or 0, 260, 0.5, function(p)
		local q = clampN(p, 0, 1)
		knob.Position = UDim2.new(0, lerp(13, 35, p), 0.5, 0)
		knob.Rotation = 45 + 180 * p
		fill.Size = UDim2.fromScale(q, 1)
		knob.BackgroundColor3 = C.Gold:Lerp(C.Black, q)
		kst.Color = C.GoldPale:Lerp(C.Black, q)
		tst.Color = C.Gold:Lerp(C.GoldPale, q)
		label.TextColor3 = C.Text:Lerp(C.GoldPale, q)
	end, 0.002)
	sp:Snap(state and 1 or 0)

	local obj = { Instance = row }
	local function set(v, silent)
		v = v and true or false
		if v == state then
			return
		end
		state = v
		sp:Set(v and 1 or 0)
		if not silent then
			win:_log(string.format("Toggle “%s” → %s", str, tostring(v)))
			fire(callback, v)
		end
	end
	function obj:Set(v, silent)
		set(v, silent)
	end
	function obj:Get()
		return state
	end
	maid:Add(btn.MouseButton1Click:Connect(function()
		set(not state, false)
	end))
	return obj
end

--------------------------------------------------------------------------
-- SLIDER
--------------------------------------------------------------------------
function Tab:AddSlider(str, min, max, default, callback, step, suffix)
	local win = self.Window
	local maid = win.Maid
	min, max = min or 0, max or 100
	step = (step and step > 0) and step or 1
	suffix = suffix or ""
	local dec = decimalsOf(step)
	local function fmt(v)
		return string.format("%." .. dec .. "f", v) .. suffix
	end
	local val = clampN(default or min, min, max)
	local row = makeRow(self, 58)

	mkText(row, str, 14, C.Text, FONT_UI, {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -110, 0, 22),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local vlbl = mkText(row, fmt(val), 17, C.GoldBright, FONT_DISPLAY, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 4),
		Size = UDim2.fromOffset(90, 24),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local bar = new("Frame", {
		Position = UDim2.new(0, 14, 0, 38),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(20, 19, 16),
		BorderSizePixel = 0,
	}, row)
	corner(bar, 3)
	stroke(bar, C.Gold, 1.2, 0.3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
	corner(fill, 2)
	grad(fill, { Color = GOLD_FILL })
	local knob = diamond(bar, 13, C.GoldPale, { Position = UDim2.fromScale(0, 0.5), ZIndex = 3 })
	stroke(knob, C.Gold, 1.2, 0)
	local hit = new("TextButton", {
		Position = UDim2.new(0, 8, 0, 26),
		Size = UDim2.new(1, -16, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	}, row)

	local ks = spring(maid, 13, 420, 0.6, function(s)
		knob.Size = UDim2.fromOffset(s, s)
	end, 0.02)
	local sp = spring(maid, 0, 380, 1, function(p)
		local q = clampN(p, 0, 1)
		fill.Size = UDim2.fromScale(q, 1)
		knob.Position = UDim2.fromScale(q, 0.5)
	end, 0.0005)
	local function frac(v)
		return max > min and (v - min) / (max - min) or 0
	end
	sp:Snap(frac(val))

	local function snapVal(v)
		v = clampN(v, min, max)
		v = min + math.floor((v - min) / step + 0.5) * step
		v = clampN(v, min, max)
		return tonumber(string.format("%." .. dec .. "f", v))
	end
	local function set(v, silent)
		v = snapVal(v)
		local changed = v ~= val
		val = v
		vlbl.Text = fmt(v)
		sp:Set(frac(v))
		if changed and not silent then
			win:_log(string.format("Slider “%s” → %s", str, fmt(v)))
			fire(callback, v)
		end
	end

	local dragging, dragInput = false, nil
	local function fromInput(input)
		local a = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
		set(min + clampN(a, 0, 1) * (max - min), false)
	end
	local function stop()
		if not dragging then
			return
		end
		dragging, dragInput = false, nil
		self.Page.ScrollingEnabled = true
		ks:Set(13)
		tween(vlbl, 0.2, { TextColor3 = C.GoldBright })
	end
	maid:Add(hit.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, dragInput = true, input
			self.Page.ScrollingEnabled = false
			ks:Set(18)
			tween(vlbl, 0.2, { TextColor3 = C.GoldPale })
			fromInput(input)
		end
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			fromInput(input)
		end
	end))
	maid:Add(UIS.InputEnded:Connect(function(input)
		if dragging and (input == dragInput or isPress(input)) then
			stop()
		end
	end))

	local obj = { Instance = row }
	function obj:Set(v, silent)
		set(v, silent)
	end
	function obj:Get()
		return val
	end
	return obj
end

--------------------------------------------------------------------------
-- BOTON
--------------------------------------------------------------------------
function Tab:AddButton(str, callback)
	local win = self.Window
	local maid = win.Maid
	local row, st = makeRow(self, 40, false)
	row.ClipsDescendants = true
	st.Transparency = 0.15
	st.Thickness = 1.3

	local fillF = new("Frame", {
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, row)
	corner(fillF, 5)
	grad(fillF, { Rotation = -70, Color = cseq(C.GoldDark, C.Gold, C.GoldPale, C.Gold) })
	local shine = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(-0.3, 0, 0.5, 0),
		Size = UDim2.new(0, 30, 2, 0),
		Rotation = 20,
		BackgroundColor3 = C.GoldPale,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, row)
	local lbl = mkText(row, string.upper(str), 13, C.GoldBright, FONT_BOLD, {
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})
	local btn = hitButton(row, 6)

	hover(maid, btn, function()
		tween(fillF, 0.5, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Quart)
		tween(lbl, 0.3, { TextColor3 = C.Black })
		tween(st, 0.3, { Color = C.GoldPale, Transparency = 0 })
		shine.Position = UDim2.new(-0.3, 0, 0.5, 0)
		tween(shine, 0.8, { Position = UDim2.new(1.2, 0, 0.5, 0) }, Enum.EasingStyle.Quad)
	end, function()
		tween(fillF, 0.5, { Position = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quart)
		tween(lbl, 0.3, { TextColor3 = C.GoldBright })
		tween(st, 0.3, { Color = C.Gold, Transparency = 0.15 })
	end)

	maid:Add(btn.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local p = pointerPos(input) - row.AbsolutePosition
		local d = row.AbsoluteSize.X * 1.6
		local r = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = C.GoldPale,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, row)
		corner(r, UDim.new(0.5, 0))
		tween(r, 0.7, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
		task.delay(0.75, function()
			r:Destroy()
		end)
	end))
	maid:Add(btn.Activated:Connect(function()
		win:_log(string.format("Button “%s” clicked", str))
		fire(callback)
	end))

	local obj = { Instance = row }
	function obj:SetText(s)
		lbl.Text = string.upper(s)
	end
	function obj:Fire()
		fire(callback)
	end
	return obj
end

--------------------------------------------------------------------------
-- DROPDOWN (simple o multiple)
--------------------------------------------------------------------------
function Tab:AddDropdown(str, options, default, callback, multi)
	local win = self.Window
	local maid = win.Maid
	options = options or {}
	local row, st = makeRow(self, 40, false)
	row.ClipsDescendants = true
	local isOpen = false
	local current, picked = nil, {}
	local optBtns = {}

	local head = hitButton(row, 6)
	head.Size = UDim2.new(1, 0, 0, 40)
	hoverStroke(maid, head, st, 0.2, 0.65)
	rowLabel(row, str, 14).Size = UDim2.new(0.5, -14, 0, 40)
	local vlbl = mkText(row, "", 13, C.Gold, FONT_UI, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -38, 0, 0),
		Size = UDim2.new(0.5, -44, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
	}, row)
	for i = 1, 2 do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, i == 1 and -2.5 or 2.5, 0.5, 1),
			Size = UDim2.fromOffset(8, 2),
			Rotation = i == 1 and 45 or -45,
			BackgroundColor3 = C.Gold,
			BorderSizePixel = 0,
		}, chev)
	end

	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 44),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.Gold,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 4,
	}, row)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function listHeight()
		local vis = math.min(#options, 5)
		return vis * 30 + math.max(vis - 1, 0) * 4
	end
	local function display()
		if multi then
			local t = {}
			for _, o in ipairs(options) do
				if picked[o] then
					t[#t + 1] = tostring(o)
				end
			end
			vlbl.Text = #t > 0 and table.concat(t, ", ") or "None"
		else
			vlbl.Text = current ~= nil and tostring(current) or "Select"
		end
	end
	local function getValue()
		if not multi then
			return current
		end
		local t = {}
		for _, o in ipairs(options) do
			if picked[o] then
				t[#t + 1] = o
			end
		end
		return t
	end
	local function paint()
		for i, ob in ipairs(optBtns) do
			local v = options[i]
			local on = multi and picked[v] or (not multi and current == v)
			tween(ob.Label, 0.2, { TextColor3 = on and C.GoldBright or C.Muted })
			tween(ob.Btn, 0.2, { BackgroundTransparency = on and 0.85 or 1 })
			ob.Dot.BackgroundTransparency = on and 0 or 1
		end
	end
	local function resize()
		local h = isOpen and (40 + 8 + listHeight() + 8) or 40
		tween(row, 0.35, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
		tween(list, 0.35, { Size = UDim2.new(1, -16, 0, listHeight()) }, Enum.EasingStyle.Quart)
	end
	local function setOpen(o)
		isOpen = o
		resize()
		tween(chev, 0.35, { Rotation = o and 180 or 0 }, Enum.EasingStyle.Quart)
		tween(st, 0.25, { Transparency = o and 0.2 or 0.65 })
	end
	local function choose(i)
		local v = options[i]
		if multi then
			picked[v] = (not picked[v]) or nil
		else
			current = v
		end
		display()
		paint()
		local out = getValue()
		local shown = multi and ("{" .. #out .. "}") or tostring(out)
		win:_log(string.format("Dropdown “%s” → %s", str, shown))
		fire(callback, out)
		if not multi then
			setOpen(false)
		end
	end
	local function build()
		for _, ob in ipairs(optBtns) do
			ob.Btn:Destroy()
		end
		optBtns = {}
		for i, o in ipairs(options) do
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = C.Gold,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 5,
			}, list)
			corner(b, 4)
			local dot = diamond(b, 5, C.Gold, { Position = UDim2.fromOffset(12, 15), BackgroundTransparency = 1, ZIndex = 6 })
			local l = mkText(b, tostring(o), 13, C.Muted, FONT_UI, {
				Position = UDim2.fromOffset(24, 0),
				Size = UDim2.new(1, -30, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 6,
			})
			maid:Add(b.MouseButton1Click:Connect(function()
				choose(i)
			end))
			optBtns[i] = { Btn = b, Label = l, Dot = dot }
		end
		paint()
	end

	if multi and type(default) == "table" then
		for _, v in ipairs(default) do
			picked[v] = true
		end
	elseif default ~= nil and not multi then
		current = default
	end
	build()
	display()
	maid:Add(head.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end))

	local obj = { Instance = row }
	function obj:Get()
		return getValue()
	end
	function obj:Set(v, silent)
		if multi then
			picked = {}
			for _, x in ipairs(type(v) == "table" and v or { v }) do
				picked[x] = true
			end
		else
			current = v
		end
		display()
		paint()
		if not silent then
			fire(callback, getValue())
		end
	end
	function obj:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then
			current, picked = nil, {}
		end
		build()
		display()
		if isOpen then
			resize()
		end
	end
	function obj:Close()
		setOpen(false)
	end
	return obj
end

--------------------------------------------------------------------------
-- KEYBIND
--------------------------------------------------------------------------
function Tab:AddKeybind(str, default, callback, changed)
	local win = self.Window
	local maid = win.Maid
	local row = makeRow(self, 40)
	local key = default
	local listening = false
	rowLabel(row, str, 120)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(100, 24),
		BackgroundColor3 = C.Black,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, row)
	corner(btn, 4)
	local bst = stroke(btn, C.Gold, 1.2, 0.35)
	local btxt = mkText(btn, "", 12, C.GoldBright, FONT_BOLD, {
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local function show()
		btxt.Text = listening and "..." or (key and string.upper(key.Name) or "NONE")
		tween(bst, 0.2, { Transparency = listening and 0 or 0.35 })
		tween(btxt, 0.2, { TextColor3 = listening and C.GoldPale or C.GoldBright })
	end
	show()

	maid:Add(btn.MouseButton1Click:Connect(function()
		listening = not listening
		win._listening = listening
		show()
	end))
	maid:Add(UIS.InputBegan:Connect(function(input, gpe)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape then
					-- cancelar: se queda la tecla anterior
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					key = nil
				else
					key = input.KeyCode
				end
				show()
				task.defer(function()
					win._listening = false
				end)
				win:_log(string.format("Keybind “%s” → %s", str, key and key.Name or "NONE"))
				fire(changed, key)
			end
			return
		end
		if not gpe and key and input.KeyCode == key then
			win:_log(string.format("Keybind “%s” pressed", str))
			fire(callback, key)
		end
	end))

	local obj = { Instance = row }
	function obj:Set(k)
		key = k
		show()
	end
	function obj:Get()
		return key
	end
	return obj
end

--------------------------------------------------------------------------
-- TEXTBOX
--------------------------------------------------------------------------
function Tab:AddTextbox(str, default, placeholder, callback)
	local win = self.Window
	local maid = win.Maid
	local row = makeRow(self, 40)
	rowLabel(row, str, 14).Size = UDim2.new(0.5, -14, 0, 40)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.5, -14, 0, 26),
		BackgroundColor3 = C.Black,
		BorderSizePixel = 0,
		Text = default or "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = C.Muted,
		TextColor3 = C.GoldPale,
		Font = FONT_UI,
		TextSize = 13,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, row)
	corner(box, 4)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
	local bst = stroke(box, C.Gold, 1.2, 0.5)
	maid:Add(box.Focused:Connect(function()
		tween(bst, 0.2, { Transparency = 0, Color = C.GoldBright })
	end))
	maid:Add(box.FocusLost:Connect(function(enter)
		tween(bst, 0.2, { Transparency = 0.5, Color = C.Gold })
		win:_log(string.format("Textbox “%s” → %s", str, box.Text))
		fire(callback, box.Text, enter)
	end))

	local obj = { Instance = row }
	function obj:Set(s)
		box.Text = tostring(s)
	end
	function obj:Get()
		return box.Text
	end
	return obj
end

--------------------------------------------------------------------------
-- COLOR PICKER
--------------------------------------------------------------------------
function Tab:AddColorPicker(str, default, callback)
	local win = self.Window
	local maid = win.Maid
	local row, st = makeRow(self, 40, false)
	row.ClipsDescendants = true
	local color = default or C.GoldBright
	local h, s, v = color:ToHSV()
	local isOpen = false
	local PY = 48
	local PANEL_H = 212

	local head = hitButton(row, 6)
	head.Size = UDim2.new(1, 0, 0, 40)
	hoverStroke(maid, head, st, 0.2, 0.65)
	rowLabel(row, str, 70)
	local sw = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, 20),
		Size = UDim2.fromOffset(40, 20),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, row)
	corner(sw, 4)
	stroke(sw, C.GoldPale, 1.2, 0.2)

	local sv = new("Frame", {
		Position = UDim2.new(0, 14, 0, PY),
		Size = UDim2.new(1, -28, 0, 96),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
	}, row)
	corner(sv, 4)
	stroke(sv, C.Gold, 1, 0.5)
	local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2 }, sv)
	corner(white, 4)
	grad(white, { Transparency = nsq({ { 0, 0 }, { 1, 1 } }) })
	local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3 }, sv)
	corner(black, 4)
	grad(black, { Rotation = 90, Transparency = nsq({ { 0, 1 }, { 1, 0 } }) })
	local cur = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, sv)
	corner(cur, UDim.new(0.5, 0))
	stroke(cur, WHITE, 2, 0)
	local svHit = hitButton(sv, 7)

	local hue = new("Frame", {
		Position = UDim2.new(0, 14, 0, PY + 96 + 10),
		Size = UDim2.new(1, -28, 0, 12),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, row)
	corner(hue, 6)
	grad(hue, { Color = HUE_SEQ })
	local hk = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(6, 18),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, hue)
	corner(hk, 2)
	stroke(hk, Color3.new(0, 0, 0), 1, 0.2)
	local hueHit = hitButton(hue, 7)

	local hexLbl = mkText(row, "HEX", 11, C.Gold, FONT_BOLD, {
		Position = UDim2.fromOffset(14, PY + 96 + 10 + 12 + 10),
		Size = UDim2.fromOffset(34, 26),
	})
	local hex = new("TextBox", {
		Position = UDim2.fromOffset(52, PY + 96 + 10 + 12 + 10),
		Size = UDim2.fromOffset(110, 26),
		BackgroundColor3 = C.Black,
		BorderSizePixel = 0,
		Text = toHex(color),
		TextColor3 = C.GoldPale,
		Font = FONT_UI,
		TextSize = 13,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	corner(hex, 4)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, hex)
	stroke(hex, C.Gold, 1.2, 0.5)

	local function apply(silent)
		color = Color3.fromHSV(h, s, v)
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		sw.BackgroundColor3 = color
		cur.Position = UDim2.fromScale(s, 1 - v)
		hk.Position = UDim2.new(h, 0, 0.5, 0)
		hex.Text = toHex(color)
		if not silent then
			fire(callback, color)
		end
	end
	apply(true)

	local drag, dragInput
	local function fromPointer(input)
		local p = pointerPos(input)
		if drag == "sv" then
			s = clampN((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			v = 1 - clampN((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
		elseif drag == "hue" then
			h = clampN((p.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 0.999)
		end
		apply(false)
	end
	local function begin(kind, input)
		if isPress(input) then
			drag, dragInput = kind, input
			self.Page.ScrollingEnabled = false
			fromPointer(input)
		end
	end
	maid:Add(svHit.InputBegan:Connect(function(input)
		begin("sv", input)
	end))
	maid:Add(hueHit.InputBegan:Connect(function(input)
		begin("hue", input)
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if drag and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			fromPointer(input)
		end
	end))
	maid:Add(UIS.InputEnded:Connect(function(input)
		if drag and (input == dragInput or isPress(input)) then
			drag, dragInput = nil, nil
			self.Page.ScrollingEnabled = true
			win:_log(string.format("Color “%s” → %s", str, toHex(color)))
		end
	end))
	maid:Add(hex.FocusLost:Connect(function()
		local t = hex.Text:gsub("[^%x]", "")
		if #t == 6 then
			local c = Color3.fromRGB(tonumber(t:sub(1, 2), 16), tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16))
			h, s, v = c:ToHSV()
			apply(false)
		else
			hex.Text = toHex(color)
		end
	end))

	maid:Add(head.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		tween(row, 0.35, { Size = UDim2.new(1, 0, 0, isOpen and PANEL_H or 40) }, Enum.EasingStyle.Quart)
		tween(st, 0.25, { Transparency = isOpen and 0.2 or 0.65 })
	end))

	local obj = { Instance = row }
	function obj:Set(c, silent)
		h, s, v = c:ToHSV()
		apply(silent)
	end
	function obj:Get()
		return color
	end
	return obj
end

--------------------------------------------------------------------------
-- DEMO (equivalente al HTML + componentes extra)
--------------------------------------------------------------------------
function UI_Library.Demo(opts)
	opts = opts or {}
	local W = UI_Library.CreateWindow({
		Title = "FROGGY HUB",
		Subtitle = "100 MEMBERS EDITION",
		Intro = opts.Intro ~= false,
		ToggleKey = Enum.KeyCode.RightShift,
		LogEvents = true,
		Resizable = true,
	})

	local Main = W:CreateTab("MAIN")
	Main:AddSection("AUTOMATION")
	Main:AddToggle("Auto Farm", false, function(v) end)
	Main:AddToggle("God Mode", true, function(v) end)
	Main:AddSlider("WalkSpeed", 16, 200, 16, function(v)
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = v
		end
	end, 1)
	Main:AddButton("Ribbit", function()
		W:Notify({ Title = "Ribbit!", Content = "Froggy Hub funcionando.", Duration = 3, Type = "success" })
	end)

	local Visual = W:CreateTab("VISUAL")
	Visual:AddSection("ESP")
	Visual:AddToggle("Player ESP", false, function(v) end)
	Visual:AddSlider("FOV", 70, 120, 90, function(v)
		local cam = workspace.CurrentCamera
		if cam then
			cam.FieldOfView = v
		end
	end, 1)
	Visual:AddButton("Reset Camera", function()
		local cam = workspace.CurrentCamera
		if cam then
			cam.FieldOfView = 70
		end
		W:Notify({ Title = "Camera", Content = "FOV restablecido a 70.", Type = "info" })
	end)

	local Extra = W:CreateTab("EXTRA")
	Extra:AddSection("COMPONENTES")
	Extra:AddDropdown("Modo", { "Normal", "Rapido", "Sigiloso" }, "Normal", function(v) end)
	Extra:AddDropdown("Objetivos", { "Jugadores", "NPCs", "Items", "Cofres" }, { "Items" }, function(v) end, true)
	Extra:AddKeybind("Tecla", Enum.KeyCode.F, function()
		W:Notify({ Title = "Keybind", Content = "Presionaste la tecla.", Duration = 2 })
	end)
	Extra:AddTextbox("Nombre", "", "escribe...", function(txt, enter) end)
	Extra:AddColorPicker("Color", Color3.fromRGB(255, 214, 92), function(c) end)
	Extra:AddDivider()
	Extra:AddParagraph("Froggy Hub", "Interfaz de lujo negro y oro. Arrastra la barra superior, minimiza con el boton - y cambia el tamano desde la esquina inferior derecha.")
	Extra:AddButton("Repetir intro", function()
		W:ReplayIntro()
	end)
	Extra:AddButton("Probar notificaciones", function()
		W:Notify({ Title = "Info", Content = "Mensaje informativo.", Type = "info" })
		task.delay(0.3, function()
			W:Notify({ Title = "Listo", Content = "Operacion completada.", Type = "success" })
		end)
		task.delay(0.6, function()
			W:Notify({ Title = "Cuidado", Content = "Esto es una advertencia.", Type = "warning" })
		end)
		task.delay(0.9, function()
			W:Notify({ Title = "Error", Content = "Algo salio mal.", Type = "error" })
		end)
	end)

	return W
end

return UI_Library
