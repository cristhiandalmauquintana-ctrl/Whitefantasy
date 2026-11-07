--[[
================================================================================
  FROGGY HUB  -  CHIBI UI LIBRARY   (design.lua  v4.0  "200 Members Edition")
  Estilo chibi / kawaii pastel. Todo animado con TweenService (rebotes, squash &
  stretch, confeti, ranita saltarina). Sin imagenes: todo son Frames.

  USO RAPIDO
  ----------
  local UI = loadstring(game:HttpGet("URL/design.lua"))()

  local Window = UI.CreateWindow({
      Title     = "FROGGY HUB",
      Subtitle  = "200 MEMBERS EDITION",
      Intro     = true,                    -- animacion de carga (false = sin intro)
      ToggleKey = Enum.KeyCode.RightShift, -- mostrar / ocultar
      LogEvents = true,                    -- pildora inferior con cada accion
      Resizable = true,
  })

  local Main = Window:CreateTab("MAIN")
  Main:AddSection("AUTOMATION")
  local t = Main:AddToggle("Auto Farm", false, function(v) end)   -- t:Set(true) / t:Get()
  Main:AddSlider("WalkSpeed", 16, 200, 16, function(v) end, 1)    -- (texto,min,max,def,cb,step,sufijo)
  Main:AddButton("Ribbit", function() end)
  Main:AddDropdown("Modo", {"A","B","C"}, "A", function(v) end)   -- 5to arg true = multiple
  Main:AddKeybind("Tecla", Enum.KeyCode.F, function() end)
  Main:AddTextbox("Nombre", "", "escribe...", function(txt, enter) end)
  Main:AddInfo("Titulo", "texto largo...")   -- tambien AddLabel(texto) / AddParagraph(t, c)
  Main:AddDivider()

  Window:Notify({Title = "Hola", Content = "Mensaje", Duration = 4, Type = "success"})
  -- Type: "info" | "success" | "warning" | "error"
  Window:Toggle() / :Minimize() / :Restore() / :SetTitle() / :ReplayIntro() / :Destroy()

  local Farm = UI.CreateFarmPanel(function() print("DETENER") end)
  Farm:UpdateUI(hp, maxHp, kills, diamonds, souls, fps)

  UI.Demo()  -> ventana de ejemplo.
================================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local UIS = UserInputService

local rng = Random.new()
local UI_Library = { Version = "4.0.0" }

--------------------------------------------------------------------------
-- PALETA CHIBI
--------------------------------------------------------------------------
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local C = {
	Plum = rgb(88, 56, 108),
	PlumSoft = rgb(150, 118, 170),
	Pink = rgb(255, 128, 176),
	PinkDark = rgb(214, 84, 138),
	PinkLight = rgb(255, 200, 224),
	Lav = rgb(190, 160, 255),
	LavLight = rgb(232, 220, 255),
	Sky = rgb(126, 200, 255),
	Mint = rgb(120, 226, 184),
	MintDark = rgb(64, 168, 128),
	Lemon = rgb(255, 222, 110),
	Peach = rgb(255, 178, 140),
	Red = rgb(255, 96, 110),
	RedDark = rgb(196, 56, 78),
	Frog = rgb(132, 222, 112),
	FrogDark = rgb(58, 140, 78),
	Belly = rgb(222, 248, 196),
}
local WHITE = Color3.new(1, 1, 1)
local CONFETTI = { C.Pink, C.Lav, C.Sky, C.Mint, C.Lemon, C.Peach }

local FONT = Enum.Font.FredokaOne
local FONT_BODY = Enum.Font.GothamMedium

local EASE_BACK = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out
local IN = Enum.EasingDirection.In

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
	return new("UICorner", { CornerRadius = r or UDim.new(0, 8) }, o)
end

local function stroke(o, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or C.Pink,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function grad(o, props)
	return new("UIGradient", props, o)
end

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

local function nsq(points)
	local k = {}
	for i, p in ipairs(points) do
		k[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(k)
end

local RAINBOW = cseq(C.Pink, C.Lav, C.Sky, C.Mint, C.Lemon, C.Pink)
local BG_SEQ = cseq(rgb(255, 242, 250), rgb(243, 232, 255), rgb(224, 238, 255))
local CANDY = cseq(rgb(255, 160, 196), rgb(255, 118, 168))

local function clampN(x, a, b)
	if a > b then
		a, b = b, a
	end
	return math.max(a, math.min(b, x))
end

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or OUT),
		props
	)
	tw:Play()
	return tw
end

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

local function loopTween(maid, o, t, props, style, reverse, dir)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut, -1, reverse ~= false),
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

local function measure(text, size, font)
	local ok, v = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(10000, 10000))
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

local function pointerPos(input)
	local inset = GuiService:GetGuiInset()
	return Vector2.new(input.Position.X, input.Position.Y + inset.Y)
end

-- gethui() -> CoreGui -> PlayerGui
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

local function mkText(parent, str, size, color, font, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = str,
		TextSize = size,
		TextColor3 = color or C.Plum,
		Font = font or FONT,
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

local function decimalsOf(step)
	local s = string.format("%.6f", step):gsub("0+$", "")
	local dot = s:find("%.")
	if not dot then
		return 0
	end
	return #s - dot
end

local function fmtNum(n)
	n = math.floor((tonumber(n) or 0) + 0.5)
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (n < 0 and "-" or "") .. out
end

--------------------------------------------------------------------------
-- DECORACION: confeti, destellos, burbujas
--------------------------------------------------------------------------
local function burst(parent, x, y, count, spread, colors, zi)
	colors = colors or CONFETTI
	for _ = 1, count do
		local sz = rng:NextInteger(5, 10)
		local p = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(sz, sz),
			Rotation = rng:NextInteger(0, 90),
			BackgroundColor3 = colors[rng:NextInteger(1, #colors)],
			BorderSizePixel = 0,
			ZIndex = zi or 20,
		}, parent)
		if rng:NextNumber() < 0.5 then
			corner(p, UDim.new(0.5, 0))
		end
		local a = rng:NextNumber() * math.pi * 2
		local d = spread * (0.45 + rng:NextNumber() * 0.8)
		local dur = 0.55 + rng:NextNumber() * 0.45
		tween(p, dur, {
			Position = UDim2.fromOffset(x + math.cos(a) * d, y + math.sin(a) * d - spread * 0.25),
			Rotation = p.Rotation + 200,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		}, Enum.EasingStyle.Quad)
		task.delay(dur + 0.05, function()
			p:Destroy()
		end)
	end
end

-- Destello de 4 puntas con UIScale (0 = invisible)
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
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = color or WHITE,
		BorderSizePixel = 0,
	}, f)
	corner(h, UDim.new(0.5, 0))
	grad(h, { Transparency = nsq({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }) })
	local v = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color or WHITE,
		BorderSizePixel = 0,
	}, f)
	corner(v, UDim.new(0.5, 0))
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

-- burbujas pastel que suben en bucle
local function floatBubbles(maid, parent, n, zi)
	for _ = 1, n do
		local s = rng:NextInteger(10, 34)
		local x = rng:NextNumber()
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(x, 0, 1.1, 0),
			Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = CONFETTI[rng:NextInteger(1, #CONFETTI)],
			BackgroundTransparency = rng:NextNumber(0.6, 0.82),
			BorderSizePixel = 0,
			ZIndex = zi or 2,
		}, parent)
		corner(b, UDim.new(0.5, 0))
		stroke(b, WHITE, 1.5, 0.4)
		local dur = rng:NextNumber(7, 13)
		task.delay(rng:NextNumber(0, 6), function()
			if maid.dead then
				return
			end
			local tw = TweenService:Create(
				b,
				TweenInfo.new(dur, Enum.EasingStyle.Linear, OUT, -1, false),
				{ Position = UDim2.new(x, 0, -0.1, 0) }
			)
			tw:Play()
			maid:Add(tw)
		end)
	end
end

--------------------------------------------------------------------------
-- RANITA CHIBI (mascota). Se dibuja con Frames, tamanos en escala:
-- si cambias Root.Size se estira / aplasta toda la ranita.
--------------------------------------------------------------------------
local function buildFrog(parent, w, maid, props)
	local h = math.floor(w * 0.9)
	local ratio = w / h
	local ol = math.max(2, math.floor(w / 14))
	local root = new("Frame", {
		Name = "Frog",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1,
	})
	if props then
		for k, v in pairs(props) do
			root[k] = v
		end
	end
	root.Parent = parent

	local function blob(x, y, sw, sh, color)
		local o = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.new(sw, ol * 2, sh, ol * 2),
			BackgroundColor3 = C.FrogDark,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, root)
		corner(o, UDim.new(0.5, 0))
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(sw, sh),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, root)
		corner(f, UDim.new(0.5, 0))
		return f
	end
	local function dot(x, y, sw, sh, color, z, transp, par)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(sw, sh),
			BackgroundColor3 = color,
			BackgroundTransparency = transp or 0,
			BorderSizePixel = 0,
			ZIndex = z,
		}, par or root)
		corner(f, UDim.new(0.5, 0))
		return f
	end

	blob(0.22, 0.93, 0.26, 0.26 * ratio, C.Frog) -- patitas
	blob(0.78, 0.93, 0.26, 0.26 * ratio, C.Frog)
	blob(0.25, 0.27, 0.4, 0.4 * ratio, C.Frog) -- bultos de los ojos
	blob(0.75, 0.27, 0.4, 0.4 * ratio, C.Frog)
	blob(0.5, 0.64, 0.98, 0.7, C.Frog) -- cuerpo
	dot(0.5, 0.84, 0.52, 0.26, C.Belly, 4)
	dot(0.15, 0.7, 0.15, 0.15 * ratio, C.Pink, 4, 0.3)
	dot(0.85, 0.7, 0.15, 0.15 * ratio, C.Pink, 4, 0.3)

	local eyes = {}
	for _, x in ipairs({ 0.25, 0.75 }) do
		local size = UDim2.fromScale(0.2, 0.2 * ratio)
		local e = dot(x, 0.3, 0.2, 0.2 * ratio, rgb(54, 34, 70), 6)
		dot(0.32, 0.3, 0.36, 0.36, WHITE, 7, 0, e)
		dot(0.68, 0.7, 0.18, 0.18, WHITE, 7, 0, e)
		eyes[#eyes + 1] = { F = e, S = size }
	end

	local mouth = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromScale(0.14, 0.06),
		BackgroundColor3 = rgb(120, 50, 80),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, root)
	corner(mouth, UDim.new(0.5, 0))

	local M = { Root = root, Mouth = mouth, Base = root.Position }
	function M:Blink()
		for _, e in ipairs(eyes) do
			tween(e.F, 0.07, { Size = UDim2.fromScale(e.S.X.Scale * 1.1, 0.015) })
			task.delay(0.11, function()
				tween(e.F, 0.12, { Size = e.S }, EASE_BACK)
			end)
		end
	end
	function M:Happy(on)
		tween(mouth, 0.2, {
			Size = on and UDim2.fromScale(0.26, 0.15) or UDim2.fromScale(0.14, 0.06),
		}, EASE_BACK)
	end
	function M:Hop()
		local base = M.Base
		tween(root, 0.14, { Position = base - UDim2.fromOffset(0, 12) })
		task.delay(0.14, function()
			tween(root, 0.5, { Position = base }, Enum.EasingStyle.Bounce)
		end)
		self:Happy(true)
		task.delay(0.9, function()
			self:Happy(false)
		end)
	end
	task.spawn(function()
		while not maid.dead do
			task.wait(rng:NextNumber(2, 4.5))
			if maid.dead then
				break
			end
			M:Blink()
		end
	end)
	return M
end

-- Letras individuales (para el titulo con rebote)
local function buildLetters(parent, str, size, pad)
	local row = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, size * 1.4),
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
		local w = (ch == " ") and size * 0.4 or (measure(ch, size, FONT).X + 2)
		local holder = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(w, size * 1.4),
			LayoutOrder = i,
		}, row)
		local lb = new("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = ch,
			TextSize = size,
			Font = FONT,
			TextColor3 = CONFETTI[(i - 1) % #CONFETTI + 1],
			TextStrokeColor3 = C.Plum,
			TextStrokeTransparency = 0.1,
			Rotation = rng:NextInteger(-25, 25),
		}, holder)
		local sc = new("UIScale", { Scale = 0 }, lb)
		letters[i] = { Holder = holder, Label = lb, Scale = sc }
	end
	return row, letters
end

--------------------------------------------------------------------------
-- ANIMACION DE CARGA: la ranita salta de nube en nube, la barra se llena,
-- al final hace una voltereta, estalla confeti y el titulo rebota letra a letra
--------------------------------------------------------------------------
local XS = { 0.1, 0.3, 0.5, 0.7, 0.9 }
local TIPS = {
	"Despertando a la ranita...",
	"Puliendo las nubes...",
	"Contando a los miembros...",
	"Repartiendo brillitos...",
	"Listo!",
}

local function buildIntro(gui, maid, owner)
	local I = { Running = false, Run = 0, _tweens = {} }

	local root = new("Frame", {
		Name = "Intro",
		Visible = false,
		Active = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 50,
	}, gui)
	grad(root, { Rotation = 90, Color = cseq(rgb(176, 222, 255), rgb(255, 214, 238), rgb(224, 206, 255)) })
	floatBubbles(maid, root, 16, 51)
	for i = 1, 10 do
		local f, sc = buildSparkle(root, rng:NextInteger(14, 24), CONFETTI[(i % #CONFETTI) + 1])
		f.Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.08, 0.9))
		f.ZIndex = 52
		twinkle(maid, sc, rng:NextNumber(1.6, 3), rng:NextNumber(0, 2))
	end

	local textHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 55 }, root)

	local sub = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.315),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = C.Pink,
		BorderSizePixel = 0,
		ZIndex = 55,
	}, root)
	corner(sub, UDim.new(0.5, 0))
	stroke(sub, WHITE, 3, 0)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
	}, sub)
	local subScale = new("UIScale", { Scale = 0 }, sub)
	local subLbl = mkText(sub, "", 14, WHITE, FONT, {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		TextStrokeColor3 = C.PinkDark,
		TextStrokeTransparency = 0.5,
		ZIndex = 56,
	})

	-- escenario con las nubes
	local stage = new("Frame", {
		Name = "Stage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.6, 0),
		Size = UDim2.new(0.8, 0, 0, 170),
		BackgroundTransparency = 1,
		ZIndex = 54,
	}, root)
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 170), MinSize = Vector2.new(260, 170) }, stage)

	local PAD_Y = 128
	local pads = {}
	for i, x in ipairs(XS) do
		local p = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(x, 0, 0, PAD_Y),
			Size = UDim2.fromOffset(74, 22),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 54,
		}, stage)
		corner(p, UDim.new(0.5, 0))
		stroke(p, CONFETTI[i], 3, 0)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -4),
			Size = UDim2.fromOffset(46, 8),
			BackgroundColor3 = CONFETTI[i],
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 53,
		}, p).ZIndex = 53
		pads[i] = p
	end

	local FW = 58
	local FH = math.floor(FW * 0.9)
	local carrier = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(XS[1], 0, 0, PAD_Y + 4),
		Size = UDim2.fromOffset(FW, FH),
		BackgroundTransparency = 1,
		ZIndex = 56,
	}, stage)
	local frog = buildFrog(carrier, FW, maid, { Position = UDim2.new(0.5, 0, 1, 0), ZIndex = 56 })
	local fr = frog.Root

	-- barra de progreso
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.87),
		Size = UDim2.new(0.56, 0, 0, 22),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 55,
	}, root)
	corner(track, UDim.new(0.5, 0))
	stroke(track, WHITE, 3, 0)
	new("UISizeConstraint", { MaxSize = Vector2.new(400, 22), MinSize = Vector2.new(180, 22) }, track)
	local fill = new("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(0, 0, 1, -6),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 56,
	}, track)
	corner(fill, UDim.new(0.5, 0))
	grad(fill, { Color = cseq(C.Pink, C.Lav, C.Sky) })
	local rider = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = C.Frog,
		BorderSizePixel = 0,
		ZIndex = 58,
	}, track)
	corner(rider, UDim.new(0.5, 0))
	stroke(rider, WHITE, 3, 0)
	for _, x in ipairs({ 0.3, 0.7 }) do
		local e = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.42),
			Size = UDim2.fromOffset(5, 6),
			BackgroundColor3 = C.Plum,
			BorderSizePixel = 0,
			ZIndex = 59,
		}, rider)
		corner(e, UDim.new(0.5, 0))
	end
	local pct = mkText(track, "0%", 16, C.Plum, FONT, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 0, -4),
		Size = UDim2.fromOffset(80, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 56,
	})
	local tip = mkText(track, TIPS[1], 14, C.Plum, FONT_BODY, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 8),
		Size = UDim2.new(1.4, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 56,
	})

	local skip = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.2,
		Text = "SKIP",
		Font = FONT,
		TextSize = 13,
		TextColor3 = C.PinkDark,
		AutoButtonColor = false,
		ZIndex = 60,
	}, root)
	corner(skip, UDim.new(0.5, 0))
	stroke(skip, C.Pink, 2, 0)
	hover(maid, skip, function()
		tween(skip, 0.25, { Size = UDim2.fromOffset(78, 31) }, EASE_BACK)
	end, function()
		tween(skip, 0.25, { Size = UDim2.fromOffset(70, 28) }, EASE_BACK)
	end)
	maid:Add(skip.MouseButton1Click:Connect(function()
		I:Skip()
	end))

	local function padPos(i)
		return UDim2.new(XS[i], 0, 0, PAD_Y)
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

		local function alive()
			return self.Running and self.Run == run
		end
		local function sleep(t)
			task.wait(t)
			return alive()
		end

		-- reset
		carrier.Position = UDim2.new(XS[1], 0, 0, PAD_Y + 4)
		fr.Position = UDim2.new(0.5, 0, 1, 0)
		fr.Size = UDim2.fromOffset(FW, FH)
		fr.Rotation = 0
		frog:Happy(false)
		fill.Size = UDim2.new(0, 0, 1, -6)
		rider.Position = UDim2.new(0, 3, 0.5, 0)
		pct.Text = "0%"
		tip.Text = TIPS[1]
		subScale.Scale = 0
		textHolder:ClearAllChildren()

		local vp = viewport()
		local tsz = math.floor(clampN(vp.X * 0.075, 34, 60) + 0.5)
		local trow, tl = buildLetters(textHolder, owner.Title, tsz, math.floor(tsz * 0.04 + 0.5))
		trow.Position = UDim2.new(0, 0, 0.19, 0)
		trow.ZIndex = 55
		subLbl.Text = string.upper(owner.Subtitle)

		self._conn = RunService.Heartbeat:Connect(function()
			if alive() then
				local q = clampN(fill.Size.X.Scale, 0, 1)
				pct.Text = tostring(math.floor(q * 100 + 0.5)) .. "%"
			end
		end)

		local function setProgress(q, t)
			tween(fill, t, { Size = UDim2.new(q, 0, 1, -6) }, Enum.EasingStyle.Quad)
			tween(rider, t, { Position = UDim2.new(q, 0, 0.5, 0) }, Enum.EasingStyle.Quad)
		end

		local function land(k)
			local pad = pads[k]
			tween(fr, 0.08, { Size = UDim2.fromOffset(FW * 1.2, FH * 0.8) })
			tween(pad, 0.08, { Position = padPos(k) + UDim2.fromOffset(0, 5) })
			task.delay(0.08, function()
				tween(pad, 0.4, { Position = padPos(k) }, EASE_BACK)
				tween(fr, 0.35, { Size = UDim2.fromOffset(FW, FH) }, EASE_BACK)
			end)
			-- onda
			local ring = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(XS[k], 0, 0, PAD_Y + 4),
				Size = UDim2.fromOffset(24, 9),
				BackgroundTransparency = 1,
				ZIndex = 53,
			}, stage)
			corner(ring, UDim.new(0.5, 0))
			local rs = stroke(ring, CONFETTI[k], 3, 0)
			tween(ring, 0.7, { Size = UDim2.fromOffset(130, 40) }, Enum.EasingStyle.Quart)
			tween(rs, 0.7, { Transparency = 1 })
			task.delay(0.75, function()
				ring:Destroy()
			end)
			burst(stage, stage.AbsoluteSize.X * XS[k], PAD_Y - 6, 7, 38, CONFETTI, 57)
			frog:Happy(true)
		end

		task.spawn(function()
			if not sleep(0.35) then
				return
			end
			local hops = #XS - 1
			for k = 1, hops do
				tip.Text = TIPS[k]
				setProgress(k / hops * 0.9, 0.9)
				-- agacharse
				frog:Happy(false)
				tween(fr, 0.14, { Size = UDim2.fromOffset(FW * 1.18, FH * 0.76) })
				if not sleep(0.14) then
					return
				end
				-- saltar
				local dur = 0.56
				tween(carrier, dur, { Position = UDim2.new(XS[k + 1], 0, 0, PAD_Y + 4) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				tween(fr, dur / 2, { Position = UDim2.new(0.5, 0, 1, -58), Size = UDim2.fromOffset(FW * 0.88, FH * 1.16) })
				if not sleep(dur / 2) then
					return
				end
				tween(fr, dur / 2, { Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(FW, FH) }, Enum.EasingStyle.Quad, IN)
				if not sleep(dur / 2) then
					return
				end
				land(k + 1)
				if not sleep(0.2) then
					return
				end
			end

			-- final: voltereta + confeti + titulo
			tip.Text = TIPS[#TIPS]
			setProgress(1, 0.7)
			tween(fr, 0.16, { Size = UDim2.fromOffset(FW * 1.22, FH * 0.7) })
			if not sleep(0.16) then
				return
			end
			frog:Happy(true)
			tween(fr, 0.45, { Position = UDim2.new(0.5, 0, 1, -130), Size = UDim2.fromOffset(FW * 0.9, FH * 1.15) })
			tween(fr, 0.8, { Rotation = 360 }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			if not sleep(0.4) then
				return
			end

			local abs = root.AbsoluteSize
			local W, H = abs.X, abs.Y
			if W < 10 or H < 10 then
				local v = viewport()
				W, H = v.X, v.Y
			end
			burst(root, W * 0.5, H * 0.42, 40, math.min(W, H) * 0.42, CONFETTI, 58)
			task.delay(0.25, function()
				if alive() then
					burst(root, W * 0.28, H * 0.3, 18, 90, CONFETTI, 58)
					burst(root, W * 0.72, H * 0.3, 18, 90, CONFETTI, 58)
				end
			end)
			for i, L in ipairs(tl) do
				task.delay((i - 1) * 0.07, function()
					if not alive() then
						return
					end
					tween(L.Scale, 0.5, { Scale = 1 }, EASE_BACK)
					tween(L.Label, 0.5, { Rotation = 0 }, EASE_BACK)
					-- baile suave
					task.delay(0.6, function()
						if alive() then
							local tw = TweenService:Create(
								L.Label,
								TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
								{ Position = UDim2.new(0.5, 0, 0.5, -6) }
							)
							tw:Play()
							self._tweens[#self._tweens + 1] = tw
						end
					end)
				end)
			end
			task.delay(0.5, function()
				if alive() then
					tween(subScale, 0.55, { Scale = 1 }, EASE_BACK)
				end
			end)

			if not sleep(0.4) then
				return
			end
			tween(fr, 0.4, { Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(FW, FH) }, Enum.EasingStyle.Bounce)
			if not sleep(0.4) then
				return
			end
			land(#XS)
			if not sleep(1.6) then
				return
			end
			self:_finish()
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

local MIN_W, MIN_H = 340, 260
local TAB_H, TAB_GAP = 36, 6

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
	self.Subtitle = cfg.Subtitle or "200 MEMBERS EDITION"
	self.LogEvents = cfg.LogEvents ~= false
	self.ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	self.OnClose = cfg.OnClose
	self.State = "hidden"
	self._prev = "open"
	self._notifN = 0
	self._logN = 0
	self._tok = 0
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

	local vp = viewport()
	self.Size = Vector2.new(math.floor(math.min(560, vp.X * 0.94)), math.floor(math.min(400, vp.Y * 0.74)))
	self.Pos = Vector2.new(0, 0)

	local win = new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Visible = false,
		ZIndex = 10,
	}, gui)
	corner(win, 22)
	grad(win, { Rotation = 60, Color = BG_SEQ })
	local wscale = new("UIScale", { Scale = 0.001 }, win)
	local wst = stroke(win, WHITE, 4, 0)
	local wg = grad(wst, { Color = RAINBOW })
	loopTween(maid, wg, 6, { Rotation = 360 }, Enum.EasingStyle.Linear, false, IN)
	self._win, self._wscale = win, wscale

	-- fondo: manchas suaves, burbujas y destellos
	local fx = new("Frame", {
		Name = "FX",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
	}, win)
	local function softBlob(x, y, s, color)
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
		}, fx)
		corner(b, UDim.new(0.5, 0))
		loopTween(maid, b, rng:NextNumber(3, 5), { Position = UDim2.fromScale(x, y + 0.04) }, Enum.EasingStyle.Sine, true)
	end
	softBlob(0.92, 0.08, 220, C.Pink)
	softBlob(0.05, 0.95, 240, C.Sky)
	softBlob(0.6, 0.55, 160, C.Lav)
	floatBubbles(maid, fx, 10, 1)
	for i = 1, 5 do
		local f, sc = buildSparkle(fx, rng:NextInteger(10, 16), CONFETTI[i])
		f.Position = UDim2.fromScale(rng:NextNumber(0.1, 0.95), rng:NextNumber(0.1, 0.9))
		twinkle(maid, sc, rng:NextNumber(2, 3.4), rng:NextNumber(0, 2))
	end

	----------------------------------------------------------------------
	-- barra superior
	----------------------------------------------------------------------
	local top = new("Frame", {
		Name = "TopBar",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 48),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 3,
	}, win)
	corner(top, 16)
	stroke(top, C.PinkLight, 2, 0)

	local mascot = buildFrog(top, 38, maid, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 3),
		ZIndex = 5,
	})
	mascot.Base = mascot.Root.Position
	mascot.Root.Rotation = -5
	loopTween(maid, mascot.Root, 1.3, { Rotation = 5 }, Enum.EasingStyle.Sine, true)
	self._mascot = mascot

	local titleLbl = mkText(top, self.Title, 22, C.Pink, FONT, {
		Position = UDim2.fromOffset(58, 3),
		Size = UDim2.new(1, -150, 0, 26),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextStrokeColor3 = WHITE,
		TextStrokeTransparency = 0,
		ZIndex = 4,
	})
	local subLbl = mkText(top, string.upper(self.Subtitle), 11, C.PlumSoft, FONT_BODY, {
		Position = UDim2.fromOffset(59, 28),
		Size = UDim2.new(1, -150, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})
	self._titleLbl, self._subLbl = titleLbl, subLbl

	local function dotButton(pos, color, kind)
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = pos,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = color,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 5,
		}, top)
		corner(b, UDim.new(0.5, 0))
		stroke(b, WHITE, 2.5, 0)
		local ic = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, b)
		local n = (kind == "x") and 2 or 1
		for i = 1, n do
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(12, 3),
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				Rotation = (kind == "x") and (i == 1 and 45 or -45) or 0,
				ZIndex = 7,
			}, ic).ZIndex = 7
		end
		hover(maid, b, function()
			tween(b, 0.3, { Size = UDim2.fromOffset(32, 32) }, EASE_BACK)
			tween(ic, 0.4, { Rotation = 90 }, EASE_BACK)
		end, function()
			tween(b, 0.3, { Size = UDim2.fromOffset(28, 28) }, EASE_BACK)
			tween(ic, 0.4, { Rotation = 0 }, EASE_BACK)
		end)
		return b
	end
	local btnMin = dotButton(UDim2.new(1, -46, 0.5, 0), C.Lemon, "min")
	local btnCls = dotButton(UDim2.new(1, -10, 0.5, 0), C.Pink, "x")
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
		Position = UDim2.fromOffset(10, 64),
		Size = UDim2.new(1, -20, 1, -74),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, win)
	local SIDE_W = 116
	local side = new("Frame", {
		Size = UDim2.new(0, SIDE_W, 1, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, body)
	corner(side, 16)
	stroke(side, C.PinkLight, 2, 0)
	local tabScroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, side)
	local blob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(6, 26),
		Size = UDim2.new(1, -12, 0, TAB_H - 4),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
	}, tabScroll)
	corner(blob, UDim.new(0.5, 0))
	grad(blob, { Rotation = 0, Color = cseq(rgb(255, 150, 190), rgb(255, 184, 150)) })
	stroke(blob, WHITE, 2, 0)
	local tabList = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, tabScroll)
	new("UIListLayout", { Padding = UDim.new(0, TAB_GAP), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
	}, tabList)
	self._blob, self._tabList = blob, tabList

	local pages = new("Frame", {
		Position = UDim2.fromOffset(SIDE_W + 8, 0),
		Size = UDim2.new(1, -(SIDE_W + 8), 1, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, body)
	corner(pages, 16)
	stroke(pages, C.LavLight, 2, 0)
	self._pages = pages

	----------------------------------------------------------------------
	-- arrastrar (barra superior)
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
	-- redimensionar
	----------------------------------------------------------------------
	if resizable then
		local grip = new("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -4),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 20,
		}, win)
		for _, p in ipairs({ { 16, 16 }, { 10, 16 }, { 16, 10 } }) do
			local d = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p[1], p[2]),
				Size = UDim2.fromOffset(5, 5),
				BackgroundColor3 = C.Pink,
				BorderSizePixel = 0,
				ZIndex = 21,
			}, grip)
			corner(d, UDim.new(0.5, 0))
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
				self:_setPos(rs.pos0 + (ns - rs.size0) / 2)
			end
		end))
		maid:Add(UIS.InputEnded:Connect(function(input)
			if rs and (input == rs.input or isPress(input)) then
				rs = nil
			end
		end))
	end

	----------------------------------------------------------------------
	-- burbuja (minimizado): la ranita flotando
	----------------------------------------------------------------------
	local bub = new("TextButton", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(56, 96),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
	}, gui)
	corner(bub, UDim.new(0.5, 0))
	grad(bub, { Rotation = 60, Color = BG_SEQ })
	local bubScale = new("UIScale", { Scale = 0.001 }, bub)
	local bst = stroke(bub, WHITE, 4, 0)
	local bgr = grad(bst, { Color = RAINBOW })
	loopTween(maid, bgr, 3.5, { Rotation = 360 }, Enum.EasingStyle.Linear, false, IN)
	local bfrog = buildFrog(bub, 40, maid, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		ZIndex = 31,
	})
	bfrog.Root.Position = UDim2.new(0.5, 0, 0.5, 8)
	loopTween(maid, bfrog.Root, 0.7, { Position = UDim2.new(0.5, 0, 0.5, 2) }, Enum.EasingStyle.Sine, true)
	self._bub, self._bubScale = bub, bubScale

	local bd
	maid:Add(bub.InputBegan:Connect(function(input)
		if isPress(input) then
			bd = { start = input.Position, from = bub.AbsolutePosition + bub.AbsoluteSize / 2, moved = false, input = input }
		end
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if bd and (input == bd.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - bd.start
			local dv = Vector2.new(d.X, d.Y)
			if dv.Magnitude > 6 then
				bd.moved = true
			end
			if bd.moved then
				local v = viewport()
				local p = bd.from + dv
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
		Size = UDim2.new(0, 300, 1, -96),
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
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 70,
	}, gui)
	corner(pill, UDim.new(0.5, 0))
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
	}, pill)
	local pillSt = stroke(pill, C.Pink, 2.5, 1)
	local pillLbl = mkText(pill, "", 13, C.Plum, FONT, {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	self._pill, self._pillSt, self._pillLbl = pill, pillSt, pillLbl

	local flash = new("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, gui)
	self._flash = flash

	self._intro = buildIntro(gui, maid, self)

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
-- ESTADOS (abierta / minimizada / oculta) con rebote
--------------------------------------------------------------------------
function Window:_clampPos(p)
	local vp = viewport()
	local w, h = self.Size.X, self.Size.Y
	return Vector2.new(
		clampN(p.X, 100 - vp.X / 2 - w / 2, vp.X / 2 - 100 + w / 2),
		clampN(p.Y, -vp.Y / 2 + h / 2, vp.Y / 2 - 44 + h / 2)
	)
end

function Window:_setPos(p)
	self.Pos = self:_clampPos(p)
	self._win.Position = UDim2.new(0.5, self.Pos.X, 0.5, self.Pos.Y)
end

function Window:_showBubble()
	self._tok = self._tok + 1
	self._bub.Visible = true
	self._bubScale.Scale = 0.2
	tween(self._bubScale, 0.55, { Scale = 1 }, EASE_BACK)
end

function Window:_hideBubble()
	if not self._bub.Visible then
		return
	end
	self._tok = self._tok + 1
	local tok = self._tok
	tween(self._bubScale, 0.25, { Scale = 0.001 }, EASE_BACK, IN)
	task.delay(0.27, function()
		if self._tok == tok and self._bub then
			self._bub.Visible = false
		end
	end)
end

function Window:_hideWindow()
	self._tok = self._tok + 1
	local tok = self._tok
	tween(self._wscale, 0.3, { Scale = 0.001 }, EASE_BACK, IN)
	task.delay(0.32, function()
		if self._tok == tok and self._win then
			self._win.Visible = false
		end
	end)
end

function Window:_open()
	if self.Destroyed then
		return
	end
	self.State = "open"
	self._tok = self._tok + 1
	if not self._win.Visible then
		self._win.Visible = true
		self._wscale.Scale = 0.55
	end
	tween(self._wscale, 0.6, { Scale = 1 }, EASE_BACK)
	if self._bub.Visible then
		self:_hideBubble()
	end
	self._mascot:Hop()
end

function Window:Minimize()
	if self.Destroyed or self.State ~= "open" then
		return
	end
	self.State = "min"
	self:_hideWindow()
	task.delay(0.15, function()
		if self.State == "min" and not self.Destroyed then
			self:_showBubble()
		end
	end)
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
		self._subLbl.Text = string.upper(subtitle)
	end
end

function Window:_playIntro()
	if self.Destroyed then
		return
	end
	self._introRunning = true
	self.State = "hidden"
	self._tok = self._tok + 1
	self._win.Visible = false
	self._wscale.Scale = 0.001
	self._bub.Visible = false
	self._intro:Play(function()
		self:_afterIntro()
	end)
end

function Window:_afterIntro()
	if self.Destroyed then
		return
	end
	local flash = self._flash
	tween(flash, 0.35, { BackgroundTransparency = 0 })
	task.delay(0.38, function()
		if self.Destroyed then
			return
		end
		self._intro:Hide()
		self._introRunning = false
		self:_open()
		tween(flash, 0.9, { BackgroundTransparency = 1 })
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
	if self._bub then
		self._bub.Visible = false
	end
	if self._win and self._win.Visible then
		tween(self._wscale, 0.3, { Scale = 0.001 }, EASE_BACK, IN)
	end
	if type(self.OnClose) == "function" then
		task.spawn(self.OnClose)
	end
	task.delay(0.4, function()
		self.Maid:Destroy()
	end)
end

--------------------------------------------------------------------------
-- LOG (pildora) y NOTIFICACIONES
--------------------------------------------------------------------------
function Window:_log(msg)
	if not self.LogEvents or self.Destroyed then
		return
	end
	self._logN = self._logN + 1
	local n = self._logN
	self._pillLbl.Text = msg
	tween(self._pill, 0.25, { BackgroundTransparency = 0.05 })
	tween(self._pillSt, 0.25, { Transparency = 0 })
	tween(self._pillLbl, 0.25, { TextTransparency = 0 })
	task.delay(1.8, function()
		if self._logN == n and not self.Destroyed then
			tween(self._pill, 0.3, { BackgroundTransparency = 1 })
			tween(self._pillSt, 0.3, { Transparency = 1 })
			tween(self._pillLbl, 0.3, { TextTransparency = 1 })
		end
	end)
end

local NOTIFY_COLORS = { info = C.Sky, success = C.Mint, warning = C.Lemon, error = C.Red }

local function noteIcon(parent, kind, accent)
	local circ = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, parent)
	corner(circ, UDim.new(0.5, 0))
	stroke(circ, WHITE, 2.5, 0)
	local function bar(x, y, w, h, rot)
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromOffset(w, h),
			Rotation = rot,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, circ)
		corner(b, UDim.new(0.5, 0))
	end
	if kind == "success" then
		bar(0.38, 0.58, 8, 3.5, 45)
		bar(0.6, 0.5, 14, 3.5, -50)
	elseif kind == "error" then
		bar(0.5, 0.5, 15, 3.5, 45)
		bar(0.5, 0.5, 15, 3.5, -45)
	else
		mkText(circ, kind == "warning" and "!" or "i", 20, WHITE, FONT, {
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
		})
	end
end

function Window:Notify(opts)
	if self.Destroyed then
		return
	end
	if type(opts) ~= "table" then
		opts = { Content = tostring(opts) }
	end
	local kind = opts.Type or "info"
	local title = tostring(opts.Title or self.Title)
	local content = tostring(opts.Content or "")
	local dur = opts.Duration or 4
	local accent = NOTIFY_COLORS[kind] or C.Sky
	local textW = 300 - 66
	local th = TextService:GetTextSize(title, 15, FONT, Vector2.new(textW, 1000)).Y
	local ch = 0
	if content ~= "" then
		ch = TextService:GetTextSize(content, 13, FONT_BODY, Vector2.new(textW, 1000)).Y
	end
	local h = math.max(58, 12 + th + (ch > 0 and 4 + ch or 0) + 16)

	self._notifN = self._notifN + 1
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		BackgroundTransparency = 1,
		LayoutOrder = self._notifN,
	}, self._notifList)
	local card = new("Frame", {
		Position = UDim2.new(1.4, 0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, holder)
	corner(card, 16)
	grad(card, { Rotation = 60, Color = BG_SEQ })
	stroke(card, accent, 3, 0)
	noteIcon(card, kind, accent)
	mkText(card, title, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(54, 10),
		Size = UDim2.new(1, -66, 0, th),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	if ch > 0 then
		mkText(card, content, 13, C.PlumSoft, FONT_BODY, {
			Position = UDim2.fromOffset(54, 10 + th + 4),
			Size = UDim2.new(1, -66, 0, ch),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	local timeline = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}, card)
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 8 }, card)

	tween(card, 0.6, { Position = UDim2.new(0, 0, 0, 0) }, EASE_BACK)
	if dur > 0 then
		tween(timeline, dur, { Size = UDim2.new(0, 0, 0, 4) }, Enum.EasingStyle.Linear)
	end

	local closed = false
	local obj = {}
	function obj:Close()
		if closed then
			return
		end
		closed = true
		tween(card, 0.35, { Position = UDim2.new(1.4, 0, 0, 0) }, EASE_BACK, IN)
		task.delay(0.35, function()
			tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quart)
			task.delay(0.3, function()
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
-- PESTANAS (cambio con slide, tinta elastica y filas que rebotan una a una)
--------------------------------------------------------------------------
function Window:CreateTab(name)
	name = tostring(name or "TAB")
	local tab = setmetatable({}, Tab)
	local maid = self.Maid
	tab.Window = self
	tab.Name = name
	tab.Index = #self.Tabs + 1
	tab.Color = CONFETTI[(tab.Index - 1) % #CONFETTI + 1]
	tab._n = 0
	tab.Items = {}

	local btn = new("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, TAB_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = tab.Index,
	}, self._tabList)
	local dot = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = tab.Color,
		BorderSizePixel = 0,
	}, btn)
	corner(dot, UDim.new(0.5, 0))
	local lbl = mkText(btn, string.upper(name), 13, C.PlumSoft, FONT, {
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -34, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	tab.Button, tab.Label, tab.Dot = btn, lbl, dot

	local page = new("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.Pink,
		ScrollBarImageTransparency = 0.2,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
	}, self._pages)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
	}, page)
	tab.Page = page

	hover(maid, btn, function()
		if self.ActiveTab ~= tab then
			tween(lbl, 0.2, { TextColor3 = C.Pink })
			tween(dot, 0.3, { Size = UDim2.fromOffset(15, 15) }, EASE_BACK)
		end
	end, function()
		if self.ActiveTab ~= tab then
			tween(lbl, 0.2, { TextColor3 = C.PlumSoft })
			tween(dot, 0.3, { Size = UDim2.fromOffset(11, 11) }, EASE_BACK)
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
	local dir = 1
	if old then
		dir = (t.Index > old.Index) and 1 or -1
		old.Page.Visible = false
		tween(old.Label, 0.25, { TextColor3 = C.PlumSoft })
		tween(old.Dot, 0.3, { BackgroundColor3 = old.Color, Size = UDim2.fromOffset(11, 11) }, EASE_BACK)
	end
	self.ActiveTab = t
	t.Page.Visible = true
	tween(t.Label, 0.25, { TextColor3 = WHITE })
	tween(t.Dot, 0.3, { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(13, 13) }, EASE_BACK)

	-- tinta elastica: se mueve con rebote y se estira como gelatina
	local blob = self._blob
	local y = 8 + (t.Index - 1) * (TAB_H + TAB_GAP) + TAB_H / 2
	blob.Visible = true
	if instant then
		blob.Position = UDim2.fromOffset(6, y)
	else
		tween(blob, 0.5, { Position = UDim2.fromOffset(6, y) }, EASE_BACK)
		tween(blob, 0.14, { Size = UDim2.new(1, -4, 0, TAB_H + 12) })
		task.delay(0.14, function()
			if not self.Destroyed then
				tween(blob, 0.4, { Size = UDim2.new(1, -12, 0, TAB_H - 4) }, EASE_BACK)
			end
		end)
		self._mascot:Hop()
	end

	if not instant then
		t.Page.CanvasPosition = Vector2.new(0, 0)
		t.Page.Position = UDim2.fromOffset(dir * 34, 0)
		tween(t.Page, 0.5, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart)
		for i, it in ipairs(t.Items) do
			it.Frame.Visible = false
			it.Frame.Position = UDim2.fromOffset(dir * 70, 0)
			it.Scale.Scale = 0.8
			task.delay(math.min((i - 1) * 0.05, 0.55), function()
				if self.Destroyed then
					return
				end
				it.Frame.Visible = true
				tween(it.Frame, 0.55, { Position = UDim2.fromOffset(0, 0) }, EASE_BACK)
				tween(it.Scale, 0.55, { Scale = 1 }, EASE_BACK)
			end)
		end
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

--------------------------------------------------------------------------
-- BASE DE FILAS
--------------------------------------------------------------------------
local function makeItem(tab, h, plain)
	tab._n = tab._n + 1
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab._n,
	}, tab.Page)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = plain and 1 or 0.12,
		BorderSizePixel = 0,
	}, holder)
	local st
	if not plain then
		corner(row, 16)
		st = stroke(row, C.PinkLight, 2, 0)
		hover(tab.Window.Maid, row, function()
			tween(st, 0.2, { Color = C.Pink })
		end, function()
			tween(st, 0.2, { Color = C.PinkLight })
		end)
	end
	local sc = new("UIScale", { Scale = 1 }, row)
	tab.Items[#tab.Items + 1] = { Frame = row, Scale = sc }
	return row, st, holder
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

local function faceDots(parent, z)
	for _, x in ipairs({ 0.32, 0.68 }) do
		local e = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.42),
			Size = UDim2.fromOffset(3, 4),
			BackgroundColor3 = C.Plum,
			BorderSizePixel = 0,
			ZIndex = z,
		}, parent)
		corner(e, UDim.new(0.5, 0))
	end
end

--------------------------------------------------------------------------
-- SECCION / LABEL / INFO / DIVISOR
--------------------------------------------------------------------------
function Tab:AddSection(str)
	local row = makeItem(self, 30, true)
	local pill = new("Frame", {
		Position = UDim2.fromOffset(2, 3),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),
		BackgroundColor3 = C.Lav,
		BorderSizePixel = 0,
	}, row)
	corner(pill, UDim.new(0.5, 0))
	stroke(pill, WHITE, 2, 0)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }, pill)
	local lbl = mkText(pill, string.upper(str), 12, WHITE, FONT, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),
		TextStrokeColor3 = C.Plum,
		TextStrokeTransparency = 0.75,
	})
	local obj = { Instance = row }
	function obj:SetText(s)
		lbl.Text = string.upper(s)
	end
	return obj
end

function Tab:AddInfo(title, body)
	local row = makeItem(self, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 0)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
	}, row)
	local ic = new("Frame", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = C.Sky,
		BorderSizePixel = 0,
	}, row)
	corner(ic, UDim.new(0.5, 0))
	stroke(ic, WHITE, 2, 0)
	mkText(ic, "i", 17, WHITE, FONT, { TextXAlignment = Enum.TextXAlignment.Center })
	local col = new("Frame", {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -38, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, row)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, col)
	local t = mkText(col, title or "", 15, C.Pink, FONT, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
	})
	local b = mkText(col, body or "", 13, C.PlumSoft, FONT_BODY, {
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
	obj.SetText = function(_, s)
		b.Text = s
	end
	return obj
end

function Tab:AddParagraph(title, body)
	return self:AddInfo(title, body)
end

function Tab:AddLabel(str)
	local row = makeItem(self, 0, true)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 0)
	local lbl = mkText(row, str, 13, C.PlumSoft, FONT_BODY, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, lbl)
	local obj = { Instance = row }
	function obj:SetText(s)
		lbl.Text = s
	end
	return obj
end

function Tab:AddDivider()
	local row = makeItem(self, 14, true)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 8),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
	}, row)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, box)
	for i = 1, 7 do
		local d = new("Frame", {
			Size = UDim2.fromOffset(i == 4 and 10 or 6, i == 4 and 10 or 6),
			BackgroundColor3 = CONFETTI[i % #CONFETTI + 1],
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, box)
		corner(d, UDim.new(0.5, 0))
	end
	return { Instance = row }
end

--------------------------------------------------------------------------
-- TOGGLE (interruptor con carita que se sonroja)
--------------------------------------------------------------------------
function Tab:AddToggle(str, default, callback)
	local win = self.Window
	local maid = win.Maid
	local row = makeItem(self, 46)
	local state = default and true or false
	local label = mkText(row, str, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -88, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local btn = hitButton(row)

	local trk = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(54, 28),
		BackgroundColor3 = rgb(226, 216, 240),
		BorderSizePixel = 0,
	}, row)
	corner(trk, UDim.new(0.5, 0))
	stroke(trk, WHITE, 2, 0)
	local fill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, trk)
	corner(fill, UDim.new(0.5, 0))
	grad(fill, { Color = cseq(C.Pink, C.Peach) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(15, 14),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, trk)
	corner(knob, UDim.new(0.5, 0))
	stroke(knob, C.PinkLight, 1.5, 0)
	faceDots(knob, 4)
	local cheeks = {}
	for _, x in ipairs({ 0.12, 0.88 }) do
		local c = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.68),
			Size = UDim2.fromOffset(6, 4),
			BackgroundColor3 = C.Pink,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, knob)
		corner(c, UDim.new(0.5, 0))
		cheeks[#cheeks + 1] = c
	end

	local function render(animate)
		local x = state and 39 or 15
		if animate then
			tween(knob, 0.4, { Position = UDim2.fromOffset(x, 14) }, EASE_BACK)
			tween(knob, 0.09, { Size = UDim2.fromOffset(30, 18) })
			task.delay(0.09, function()
				tween(knob, 0.35, { Size = UDim2.fromOffset(22, 22) }, EASE_BACK)
			end)
			tween(fill, 0.25, { BackgroundTransparency = state and 0 or 1 })
			for _, c in ipairs(cheeks) do
				tween(c, 0.25, { BackgroundTransparency = state and 0.15 or 1 })
			end
			tween(label, 0.25, { TextColor3 = state and C.PinkDark or C.Plum })
		else
			knob.Position = UDim2.fromOffset(x, 14)
			fill.BackgroundTransparency = state and 0 or 1
			for _, c in ipairs(cheeks) do
				c.BackgroundTransparency = state and 0.15 or 1
			end
			label.TextColor3 = state and C.PinkDark or C.Plum
		end
	end
	render(false)

	local obj = { Instance = row }
	local function set(v, silent)
		v = v and true or false
		if v == state then
			return
		end
		state = v
		render(true)
		if not silent then
			win:_log(string.format("Toggle %s -> %s", str, tostring(v)))
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
-- SLIDER (perilla con carita)
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
	local row = makeItem(self, 66)

	mkText(row, str, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -110, 0, 24),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(72, 22),
		BackgroundColor3 = C.Pink,
		BorderSizePixel = 0,
	}, row)
	corner(pill, UDim.new(0.5, 0))
	stroke(pill, WHITE, 2, 0)
	local vlbl = mkText(pill, fmt(val), 13, WHITE, FONT, { TextXAlignment = Enum.TextXAlignment.Center })

	local bar = new("Frame", {
		Position = UDim2.new(0, 16, 0, 46),
		Size = UDim2.new(1, -32, 0, 10),
		BackgroundColor3 = rgb(232, 222, 246),
		BorderSizePixel = 0,
	}, row)
	corner(bar, UDim.new(0.5, 0))
	stroke(bar, WHITE, 2, 0)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
	corner(fill, UDim.new(0.5, 0))
	grad(fill, { Color = cseq(C.Pink, C.Lav) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, bar)
	corner(knob, UDim.new(0.5, 0))
	stroke(knob, C.Pink, 2.5, 0)
	faceDots(knob, 4)
	local hit = new("TextButton", {
		Position = UDim2.new(0, 8, 0, 34),
		Size = UDim2.new(1, -16, 0, 32),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	}, row)

	local function frac(v)
		return max > min and (v - min) / (max - min) or 0
	end
	local function place(q, animated)
		if animated then
			tween(fill, 0.1, { Size = UDim2.fromScale(q, 1) })
			tween(knob, 0.1, { Position = UDim2.fromScale(q, 0.5) })
		else
			fill.Size = UDim2.fromScale(q, 1)
			knob.Position = UDim2.fromScale(q, 0.5)
		end
	end
	place(frac(val), false)

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
		place(frac(v), true)
		if changed and not silent then
			win:_log(string.format("Slider %s -> %s", str, fmt(v)))
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
		tween(knob, 0.35, { Size = UDim2.fromOffset(22, 22) }, EASE_BACK)
		tween(pill, 0.3, { Size = UDim2.fromOffset(72, 22) }, EASE_BACK)
	end
	maid:Add(hit.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, dragInput = true, input
			self.Page.ScrollingEnabled = false
			tween(knob, 0.3, { Size = UDim2.fromOffset(30, 30) }, EASE_BACK)
			tween(pill, 0.3, { Size = UDim2.fromOffset(82, 26) }, EASE_BACK)
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
-- BOTON (caramelo 3D que se hunde, con chispitas)
--------------------------------------------------------------------------
function Tab:AddButton(str, callback)
	local win = self.Window
	local maid = win.Maid
	local row = makeItem(self, 46, true)

	local shadow = new("Frame", {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.PinkDark,
		BorderSizePixel = 0,
	}, row)
	corner(shadow, 16)
	local face = new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, row)
	corner(face, 16)
	grad(face, { Rotation = 90, Color = CANDY })
	stroke(face, WHITE, 2.5, 0)
	local shine = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(-0.2, 0, 0.5, 0),
		Size = UDim2.new(0, 26, 2, 0),
		Rotation = 20,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, face)
	local gloss = new("Frame", {
		Position = UDim2.fromOffset(14, 5),
		Size = UDim2.new(0.5, 0, 0, 5),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, face)
	corner(gloss, UDim.new(0.5, 0))
	local lbl = mkText(face, str, 15, WHITE, FONT, {
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeColor3 = C.PinkDark,
		TextStrokeTransparency = 0.55,
		ZIndex = 4,
	})
	local btn = hitButton(row, 8)
	btn.Size = UDim2.new(1, 0, 0, 44)

	hover(maid, btn, function()
		tween(face, 0.2, { Position = UDim2.fromOffset(0, -2) }, EASE_BACK)
		shine.Position = UDim2.new(-0.2, 0, 0.5, 0)
		tween(shine, 0.7, { Position = UDim2.new(1.2, 0, 0.5, 0) })
	end, function()
		tween(face, 0.25, { Position = UDim2.fromOffset(0, 0) }, EASE_BACK)
	end)
	maid:Add(btn.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		tween(face, 0.06, { Position = UDim2.fromOffset(0, 5) })
		local p = pointerPos(input) - row.AbsolutePosition
		burst(row, p.X, p.Y, 9, 44, CONFETTI, 9)
	end))
	maid:Add(btn.InputEnded:Connect(function(input)
		if isPress(input) then
			tween(face, 0.35, { Position = UDim2.fromOffset(0, 0) }, EASE_BACK)
		end
	end))
	maid:Add(btn.Activated:Connect(function()
		win:_log(string.format("Button %s clicked", str))
		win._mascot:Hop()
		fire(callback)
	end))

	local obj = { Instance = row }
	function obj:SetText(s)
		lbl.Text = s
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
	local row, st = makeItem(self, 46)
	row.ClipsDescendants = true
	local isOpen = false
	local current, picked = nil, {}
	local optBtns = {}

	local head = hitButton(row, 6)
	head.Size = UDim2.new(1, 0, 0, 46)
	mkText(row, str, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.5, -14, 0, 46),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local vlbl = mkText(row, "", 13, C.PinkDark, FONT, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -46, 0, 0),
		Size = UDim2.new(0.5, -50, 0, 46),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -24, 0, 23),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = C.Pink,
		BorderSizePixel = 0,
	}, row)
	corner(chev, UDim.new(0.5, 0))
	for i = 1, 2 do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, i == 1 and -3 or 3, 0.5, 1),
			Size = UDim2.fromOffset(8, 3),
			Rotation = i == 1 and 45 or -45,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
		}, chev)
	end

	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 52),
		Size = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Pink,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 4,
	}, row)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function listHeight()
		local vis = math.min(#options, 5)
		return vis * 32 + math.max(vis - 1, 0) * 4
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
			local on = (multi and picked[v]) or (not multi and current == v)
			tween(ob.Label, 0.2, { TextColor3 = on and WHITE or C.PlumSoft })
			tween(ob.Btn, 0.25, { BackgroundTransparency = on and 0 or 1 })
			tween(ob.Dot, 0.3, { BackgroundTransparency = on and 0 or 1 }, EASE_BACK)
		end
	end
	local function resize()
		local h = isOpen and (46 + 6 + listHeight() + 10) or 46
		tween(row, 0.45, { Size = UDim2.new(1, 0, 0, h) }, EASE_BACK)
		tween(list, 0.45, { Size = UDim2.new(1, -20, 0, listHeight()) }, EASE_BACK)
	end
	local function setOpen(o)
		isOpen = o
		resize()
		tween(chev, 0.4, { Rotation = o and 180 or 0 }, EASE_BACK)
		tween(st, 0.25, { Color = o and C.Pink or C.PinkLight })
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
		win:_log(string.format("Dropdown %s -> %s", str, shown))
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
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = C.Pink,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 5,
			}, list)
			corner(b, UDim.new(0.5, 0))
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(16, 16),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = WHITE,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, b)
			corner(dot, UDim.new(0.5, 0))
			local l = mkText(b, tostring(o), 14, C.PlumSoft, FONT, {
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -36, 1, 0),
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
	local row = makeItem(self, 46)
	local key = default
	local listening = false
	mkText(row, str, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -130, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(104, 28),
		BackgroundColor3 = C.LavLight,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, row)
	corner(btn, UDim.new(0.5, 0))
	local bst = stroke(btn, C.Lav, 2, 0)
	local btxt = mkText(btn, "", 13, C.Plum, FONT, {
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local function show()
		btxt.Text = listening and "..." or (key and string.upper(key.Name) or "NONE")
		tween(bst, 0.2, { Color = listening and C.Pink or C.Lav })
		tween(btn, 0.2, { BackgroundColor3 = listening and C.PinkLight or C.LavLight })
	end
	show()

	maid:Add(btn.MouseButton1Click:Connect(function()
		listening = not listening
		win._listening = listening
		show()
		tween(btn, 0.3, { Size = UDim2.fromOffset(112, 30) }, EASE_BACK)
		task.delay(0.15, function()
			tween(btn, 0.3, { Size = UDim2.fromOffset(104, 28) }, EASE_BACK)
		end)
	end))
	maid:Add(UIS.InputBegan:Connect(function(input, gpe)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape then
					-- cancelar
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					key = nil
				else
					key = input.KeyCode
				end
				show()
				task.defer(function()
					win._listening = false
				end)
				win:_log(string.format("Keybind %s -> %s", str, key and key.Name or "NONE"))
				fire(changed, key)
			end
			return
		end
		if not gpe and key and input.KeyCode == key then
			win:_log(string.format("Keybind %s pressed", str))
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
	local row = makeItem(self, 46)
	mkText(row, str, 15, C.Plum, FONT, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.5, -14, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0.5, -14, 0, 30),
		BackgroundColor3 = C.LavLight,
		BorderSizePixel = 0,
		Text = default or "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = C.PlumSoft,
		TextColor3 = C.Plum,
		Font = FONT_BODY,
		TextSize = 14,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, row)
	corner(box, UDim.new(0.5, 0))
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, box)
	local bst = stroke(box, C.Lav, 2, 0)
	maid:Add(box.Focused:Connect(function()
		tween(bst, 0.2, { Color = C.Pink })
		tween(box, 0.3, { BackgroundColor3 = WHITE })
	end))
	maid:Add(box.FocusLost:Connect(function(enter)
		tween(bst, 0.2, { Color = C.Lav })
		tween(box, 0.3, { BackgroundColor3 = C.LavLight })
		win:_log(string.format("Textbox %s -> %s", str, box.Text))
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
-- PANEL DE FARMEO (flotante)
-- UI_Library.CreateFarmPanel(onStop | {OnStop=fn, Title="AUTO FARM"})
-- Panel:UpdateUI(hp, maxHp, kills, diamonds, souls, fps)
--------------------------------------------------------------------------
local FarmPanel = {}
FarmPanel.__index = FarmPanel

function UI_Library.CreateFarmPanel(opts)
	local onStop
	local title = "AUTO FARM"
	if type(opts) == "function" then
		onStop = opts
	elseif type(opts) == "table" then
		onStop = opts.OnStop or opts.Callback
		title = opts.Title or title
	end
	local self = setmetatable({}, FarmPanel)
	self.OnStop = onStop
	local maid = newMaid()
	self.Maid = maid

	local gui = new("ScreenGui", {
		Name = "FroggyFarm_" .. tostring(rng:NextInteger(1000, 9999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 9998,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	mountGui(gui)
	maid:Add(gui)
	self.Gui = gui

	local panel = new("Frame", {
		Name = "FarmPanel",
		Position = UDim2.fromOffset(16, 90),
		Size = UDim2.fromOffset(250, 262),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 2,
	}, gui)
	corner(panel, 22)
	grad(panel, { Rotation = 60, Color = BG_SEQ })
	local pst = stroke(panel, WHITE, 4, 0)
	local pg = grad(pst, { Color = RAINBOW })
	loopTween(maid, pg, 6, { Rotation = 360 }, Enum.EasingStyle.Linear, false, IN)
	local pscale = new("UIScale", { Scale = 0.3 }, panel)
	tween(pscale, 0.6, { Scale = 1 }, EASE_BACK)

	local head = new("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 40),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 3,
	}, panel)
	corner(head, 14)
	stroke(head, C.PinkLight, 2, 0)
	local fr = buildFrog(head, 32, maid, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 3),
		ZIndex = 5,
	})
	fr.Base = fr.Root.Position
	mkText(head, title, 17, C.Pink, FONT, {
		Position = UDim2.fromOffset(50, 0),
		Size = UDim2.new(1, -58, 1, 0),
		TextStrokeColor3 = WHITE,
		TextStrokeTransparency = 0,
		ZIndex = 4,
	})

	-- barra de vida
	local hpTrack = new("Frame", {
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 0, 22),
		BackgroundColor3 = rgb(232, 222, 246),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, panel)
	corner(hpTrack, UDim.new(0.5, 0))
	stroke(hpTrack, WHITE, 2.5, 0)
	local hpFill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Mint,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, hpTrack)
	corner(hpFill, UDim.new(0.5, 0))
	local hpText = mkText(hpTrack, "HP 0 / 0", 12, C.Plum, FONT, {
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})

	-- tarjetas
	local grid = new("Frame", {
		Position = UDim2.fromOffset(14, 90),
		Size = UDim2.new(1, -28, 0, 104),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, panel)
	new("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 48),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local values = {}
	local defs = {
		{ "KILLS", C.Pink, "kills" },
		{ "DIAMANTES", C.Sky, "diamonds" },
		{ "ALMAS", C.Lav, "souls" },
		{ "FPS", C.Mint, "fps" },
	}
	for i, d in ipairs(defs) do
		local card = new("Frame", {
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 3,
		}, grid)
		corner(card, 14)
		stroke(card, d[2], 2.5, 0)
		mkText(card, d[1], 10, d[2], FONT, {
			Position = UDim2.fromOffset(10, 4),
			Size = UDim2.new(1, -10, 0, 14),
			ZIndex = 4,
		})
		values[d[3]] = mkText(card, "0", 18, C.Plum, FONT, {
			Position = UDim2.fromOffset(10, 18),
			Size = UDim2.new(1, -10, 0, 26),
			ZIndex = 4,
		})
	end

	-- boton DETENER
	local shadow = new("Frame", {
		Position = UDim2.fromOffset(14, 208),
		Size = UDim2.new(1, -28, 0, 40),
		BackgroundColor3 = C.RedDark,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, panel)
	corner(shadow, 16)
	shadow.Position = UDim2.fromOffset(14, 212)
	local stopFace = new("Frame", {
		Position = UDim2.fromOffset(14, 206),
		Size = UDim2.new(1, -28, 0, 40),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, panel)
	corner(stopFace, 16)
	grad(stopFace, { Rotation = 90, Color = cseq(rgb(255, 130, 140), rgb(255, 84, 100)) })
	stroke(stopFace, WHITE, 2.5, 0)
	mkText(stopFace, "DETENER", 16, WHITE, FONT, {
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeColor3 = C.RedDark,
		TextStrokeTransparency = 0.5,
		ZIndex = 5,
	})
	local stopBtn = new("TextButton", {
		Position = UDim2.fromOffset(14, 206),
		Size = UDim2.new(1, -28, 0, 46),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, panel)
	self.StopButton = stopBtn
	hover(maid, stopBtn, function()
		tween(stopFace, 0.2, { Position = UDim2.fromOffset(14, 204) }, EASE_BACK)
	end, function()
		tween(stopFace, 0.25, { Position = UDim2.fromOffset(14, 206) }, EASE_BACK)
	end)
	maid:Add(stopBtn.InputBegan:Connect(function(input)
		if isPress(input) then
			tween(stopFace, 0.06, { Position = UDim2.fromOffset(14, 211) })
		end
	end))
	maid:Add(stopBtn.InputEnded:Connect(function(input)
		if isPress(input) then
			tween(stopFace, 0.35, { Position = UDim2.fromOffset(14, 206) }, EASE_BACK)
		end
	end))
	maid:Add(stopBtn.Activated:Connect(function()
		fr:Hop()
		fire(self.OnStop)
	end))

	-- arrastrar por la cabecera
	local drag
	maid:Add(head.InputBegan:Connect(function(input)
		if isPress(input) then
			drag = { start = input.Position, from = panel.AbsolutePosition, input = input }
		end
	end))
	maid:Add(UIS.InputChanged:Connect(function(input)
		if drag and (input == drag.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - drag.start
			local v = viewport()
			local p = drag.from + Vector2.new(d.X, d.Y)
			panel.Position = UDim2.fromOffset(clampN(p.X, 0, v.X - 60), clampN(p.Y, 0, v.Y - 60))
		end
	end))
	maid:Add(UIS.InputEnded:Connect(function(input)
		if drag and (input == drag.input or isPress(input)) then
			drag = nil
		end
	end))

	self._panel, self._scale = panel, pscale
	self._hpFill, self._hpText, self._values = hpFill, hpText, values
	self._frog = fr
	return self
end

function FarmPanel:UpdateUI(hp, maxHp, kills, diamonds, souls, fps)
	if self.Destroyed then
		return
	end
	hp, maxHp = tonumber(hp) or 0, tonumber(maxHp) or 0
	local q = maxHp > 0 and clampN(hp / maxHp, 0, 1) or 0
	local col = q > 0.5 and C.Mint or (q > 0.25 and C.Lemon or C.Red)
	tween(self._hpFill, 0.35, { Size = UDim2.fromScale(q, 1), BackgroundColor3 = col }, EASE_BACK)
	self._hpText.Text = "HP " .. fmtNum(hp) .. " / " .. fmtNum(maxHp)
	local v = self._values
	v.kills.Text = fmtNum(kills)
	v.diamonds.Text = fmtNum(diamonds)
	v.souls.Text = fmtNum(souls)
	v.fps.Text = fmtNum(fps)
end

function FarmPanel:SetVisible(on)
	if self.Destroyed then
		return
	end
	if on then
		self._panel.Visible = true
		self._scale.Scale = 0.3
		tween(self._scale, 0.5, { Scale = 1 }, EASE_BACK)
	else
		tween(self._scale, 0.25, { Scale = 0.001 }, EASE_BACK, IN)
		task.delay(0.27, function()
			if not self.Destroyed then
				self._panel.Visible = false
			end
		end)
	end
end

function FarmPanel:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	tween(self._scale, 0.25, { Scale = 0.001 }, EASE_BACK, IN)
	task.delay(0.3, function()
		self.Maid:Destroy()
	end)
end

--------------------------------------------------------------------------
-- DEMO
--------------------------------------------------------------------------
function UI_Library.Demo(opts)
	opts = opts or {}
	local W = UI_Library.CreateWindow({
		Title = "FROGGY HUB",
		Subtitle = "200 MEMBERS EDITION",
		Intro = opts.Intro ~= false,
		ToggleKey = Enum.KeyCode.RightShift,
		LogEvents = true,
		Resizable = true,
	})

	local Main = W:CreateTab("MAIN")
	Main:AddSection("AUTOMATION")
	Main:AddToggle("Auto Farm", false, function() end)
	Main:AddToggle("God Mode", true, function() end)
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
	Visual:AddToggle("Player ESP", false, function() end)
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
	Extra:AddDropdown("Modo", { "Normal", "Rapido", "Sigiloso" }, "Normal", function() end)
	Extra:AddDropdown("Objetivos", { "Jugadores", "NPCs", "Items", "Cofres" }, { "Items" }, function() end, true)
	Extra:AddKeybind("Tecla", Enum.KeyCode.F, function()
		W:Notify({ Title = "Keybind", Content = "Presionaste la tecla.", Duration = 2 })
	end)
	Extra:AddTextbox("Nombre", "", "escribe...", function() end)
	Extra:AddDivider()
	Extra:AddInfo("Froggy Hub", "Gracias por ser parte de los 200 miembros! Arrastra la barra superior, minimiza con el boton amarillo y cambia el tamano desde la esquina.")
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
