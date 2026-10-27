--[[
    FroggyRivalsDesign  -  UI Library (Pond Theme)
    Uso:
        local UI_Library = loadstring(game:HttpGet("URL/design.lua"))()
        local Window = UI_Library.CreateWindow({Title = "Froggy", Subtitle = "Pond Edition"})
        local Tab = Window:CreateTab("Main")
        local t = Tab:AddToggle("ESP", false, function(v) end)   -- t:Set(true)
        Tab:AddSlider("Velocidad", 0, 100, 16, function(v) end)
        Tab:AddButton("Hacer algo", function() end)
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local rng = Random.new()
local TAB_WATER = Color3.fromRGB(18, 92, 110)
local TAB_ACTIVE = Color3.fromRGB(26, 130, 110)
local UI_Library = {}

--------------------------------------------------------------------------
-- PALETA
--------------------------------------------------------------------------
local C = {
	DeepGreen = Color3.fromRGB(12, 46, 34),
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

local function newMaid()
	local m = { items = {} }
	function m:Add(x)
		table.insert(self.items, x)
		return x
	end
	function m:Destroy()
		for _, x in ipairs(self.items) do
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
				end
			end)
		end
		self.items = {}
	end
	return m
end

-- Tween infinito (reverse = true por defecto, false para rotaciones lineales)
local function loopTween(maid, o, t, props, style, reverse)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, reverse ~= false),
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
	return cam and cam.ViewportSize or Vector2.new(800, 600)
end

local function fadeOut(root, t)
	for _, d in ipairs(root:GetDescendants()) do
		local props
		if d:IsA("GuiObject") then
			props = { BackgroundTransparency = 1 }
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				props.TextTransparency = 1
			end
		elseif d:IsA("UIStroke") then
			props = { Transparency = 1 }
		end
		if props then
			tween(d, t, props, Enum.EasingStyle.Linear)
		end
	end
end

local function resolveParent()
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

local function makeDraggable(handle, target, maid, opts)
	opts = opts or {}
	local dragging, dragStart, startPos, moved = false, nil, nil, false
	maid:Add(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					c:Disconnect()
					if dragging then
						dragging = false
						if not moved and opts.OnClick then
							opts.OnClick()
						end
					end
				end
			end)
		end
	end))
	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			local d = input.Position - dragStart
			if d.Magnitude > 5 then
				moved = true
			end
			if moved then
				local x = startPos.X.Offset + d.X
				local y = startPos.Y.Offset + d.Y
				if opts.Clamp then
					local vp = viewport()
					x = math.clamp(x, opts.Clamp, vp.X - opts.Clamp)
					y = math.clamp(y, opts.Clamp, vp.Y - opts.Clamp)
				end
				target.Position = UDim2.new(startPos.X.Scale, x, startPos.Y.Scale, y)
			end
		end
	end))
end

--------------------------------------------------------------------------
-- ELEMENTOS DECORATIVOS
--------------------------------------------------------------------------

-- Rana 2D (contenedor cuadrado). Vista frontal: cabeza, ojos saltones, sonrisa,
-- mejillas, patas traseras y delanteras. Devuelve el Frame de la rana.
local FROG_OUTLINE = Color3.fromRGB(26, 92, 40)
local FROG_LEG = Color3.fromRGB(38, 130, 44)
local FROG_FOOT = Color3.fromRGB(63, 166, 60)
local FROG_MOUTH = Color3.fromRGB(30, 100, 40)
local FROG_BLUSH = Color3.fromRGB(255, 140, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(14, 14, 14)
-- { x, y, w, h, color, zindex, outline, transparency }
local FROG_PARTS = {
	{ 0.00, 0.56, 0.34, 0.40, FROG_LEG, 1, true },   -- muslo trasero izq
	{ 0.66, 0.56, 0.34, 0.40, FROG_LEG, 1, true },   -- muslo trasero der
	{ 0.00, 0.86, 0.32, 0.14, FROG_FOOT, 1, true },  -- pie izq
	{ 0.68, 0.86, 0.32, 0.14, FROG_FOOT, 1, true },  -- pie der
	{ 0.14, 0.40, 0.72, 0.56, C.FrogGreen, 2, true }, -- cuerpo
	{ 0.20, 0.52, 0.60, 0.43, C.FrogBelly, 2 },      -- barriga
	{ 0.28, 0.82, 0.16, 0.16, C.FrogGreen, 3, true }, -- mano izq
	{ 0.56, 0.82, 0.16, 0.16, C.FrogGreen, 3, true }, -- mano der
	{ 0.08, 0.00, 0.34, 0.34, C.FrogGreen, 2, true }, -- bulto ojo izq
	{ 0.58, 0.00, 0.34, 0.34, C.FrogGreen, 2, true }, -- bulto ojo der
	{ 0.04, 0.20, 0.92, 0.50, C.FrogGreen, 3, true }, -- cabeza
	{ 0.12, 0.04, 0.26, 0.26, WHITE, 4, true },      -- ojo izq
	{ 0.62, 0.04, 0.26, 0.26, WHITE, 4, true },      -- ojo der
	{ 0.198, 0.118, 0.143, 0.143, BLACK, 5 },        -- pupila izq
	{ 0.698, 0.118, 0.143, 0.143, BLACK, 5 },        -- pupila der
	{ 0.212, 0.126, 0.045, 0.045, WHITE, 6 },        -- brillo izq
	{ 0.712, 0.126, 0.045, 0.045, WHITE, 6 },        -- brillo der
	{ 0.10, 0.50, 0.14, 0.10, FROG_BLUSH, 4, false, 0.55 }, -- mejilla izq
	{ 0.76, 0.50, 0.14, 0.10, FROG_BLUSH, 4, false, 0.55 }, -- mejilla der
	{ 0.29, 0.50, 0.42, 0.14, FROG_MOUTH, 4 },       -- boca (pastilla oscura)
	{ 0.27, 0.46, 0.46, 0.12, C.FrogGreen, 5 },      -- tapa: deja solo la sonrisa
}

local function buildFrog(parent, size, props)
	local f = new("Frame", {
		Name = "Frog",
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	}, parent)
	for k, v in pairs(props or {}) do
		f[k] = v
	end
	local base = f.Position

	-- "Rig": contenedor anclado a los pies para aplastar / estirar la rana
	local rig = new("Frame", {
		Name = "Rig",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, f)

	local parts = {}
	for i, p in ipairs(FROG_PARTS) do
		local part = new("Frame", {
			Position = UDim2.fromScale(p[1], p[2]),
			Size = UDim2.fromScale(p[3], p[4]),
			BackgroundColor3 = p[5],
			BackgroundTransparency = p[8] or 0,
			BorderSizePixel = 0,
			ZIndex = p[6],
		}, rig)
		corner(part, UDim.new(0.5, 0))
		if p[7] then
			stroke(part, FROG_OUTLINE, 1)
		end
		parts[i] = part
	end

	-- parpados (ojos 12 y 13)
	local lids = {}
	for _, i in ipairs({ 12, 13 }) do
		local e = FROG_PARTS[i]
		local lid = new("Frame", {
			Position = UDim2.fromScale(e[1], e[2]),
			Size = UDim2.fromScale(e[3], 0),
			BackgroundColor3 = C.FrogGreen,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, rig)
		corner(lid, UDim.new(0.5, 0))
		table.insert(lids, { lid = lid, w = e[3], h = e[4] })
	end

	-- lengua: el holder gira sobre la boca, la lengua crece hacia arriba
	local tHolder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.fromScale(0.2, 0.2),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, rig)
	local tongue = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.45, 0),
		BackgroundColor3 = Color3.fromRGB(255, 120, 140),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, tHolder)
	corner(tongue, UDim.new(0.5, 0))

	local alive = true
	local tws = {}
	f.AncestryChanged:Connect(function(_, parentNow)
		if not parentNow then
			alive = false
			for _, tw in ipairs(tws) do
				tw:Cancel()
			end
		end
	end)

	-- respiracion (cuerpo y barriga se inflan suavemente)
	local breathT = rng:NextNumber(1.1, 1.6)
	local function breathe(part, props)
		local tw = TweenService:Create(
			part,
			TweenInfo.new(breathT, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			props
		)
		tw:Play()
		table.insert(tws, tw)
	end
	breathe(parts[5], { Position = UDim2.fromScale(0.12, 0.38), Size = UDim2.fromScale(0.76, 0.59) })
	breathe(parts[6], { Position = UDim2.fromScale(0.18, 0.49), Size = UDim2.fromScale(0.64, 0.47) })

	-- mirar alrededor y parpadear
	local function look(dx, dy)
		for _, i in ipairs({ 14, 15, 16, 17 }) do
			local p = FROG_PARTS[i]
			tween(parts[i], 0.15, { Position = UDim2.fromScale(p[1] + dx, p[2] + dy) })
		end
	end
	local function blink()
		for _, l in ipairs(lids) do
			tween(l.lid, 0.07, { Size = UDim2.fromScale(l.w, l.h) })
			task.delay(0.1, function()
				if alive then
					tween(l.lid, 0.1, { Size = UDim2.fromScale(l.w, 0) })
				end
			end)
		end
	end
	task.spawn(function()
		task.wait(rng:NextNumber(0, 2))
		while alive and f.Parent do
			task.wait(rng:NextNumber(1.6, 3.8))
			if not alive then
				break
			end
			if rng:NextNumber() < 0.65 then
				look(rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.02, 0.025))
			end
			task.wait(rng:NextNumber(0.2, 0.6))
			if not alive then
				break
			end
			blink()
			if rng:NextNumber() < 0.25 then
				task.wait(0.28)
				if alive then
					blink()
				end
			end
		end
	end)

	local api = {}
	local function squash(t, w, h, style, dir)
		tween(rig, t, { Size = UDim2.fromScale(w, h) }, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	end

	-- salto con anticipacion (agacharse), estirarse en el aire y aplastarse al caer
	function api.Hop(T, height, dir, crouch)
		crouch = crouch or 0.1
		squash(crouch, 1.16, 0.8)
		task.delay(crouch, function()
			if not alive then
				return
			end
			squash(T / 2, 0.88, 1.15)
			tween(f, T / 2, {
				Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset - height),
				Rotation = dir * 28,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		task.delay(crouch + T / 2, function()
			if not alive then
				return
			end
			squash(T / 2, 1, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(f, T / 2, { Position = base, Rotation = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		task.delay(crouch + T, function()
			if not alive then
				return
			end
			squash(0.07, 1.18, 0.78)
			task.delay(0.07, function()
				if alive then
					squash(0.3, 1, 1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end)
	end

	-- lengüetazo (angle: grados desde "arriba", len: largo relativo)
	function api.Flick(angle, len, tOut, tIn)
		if not alive then
			return
		end
		tOut = tOut or 0.1
		tIn = tIn or 0.18
		tHolder.Rotation = angle
		tween(tongue, tOut, { Size = UDim2.fromScale(0.45, len or 3.8) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(tOut + 0.02, function()
			if alive then
				tween(tongue, tIn, { Size = UDim2.fromScale(0.45, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end)
	end

	-- tragar: se infla, cierra los ojos satisfecha y vuelve a su forma
	function api.Gulp()
		if not alive then
			return
		end
		squash(0.1, 1.15, 0.88)
		task.delay(0.1, function()
			if alive then
				squash(0.14, 0.92, 1.1)
			end
		end)
		task.delay(0.24, function()
			if alive then
				squash(0.32, 1, 1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
		for _, l in ipairs(lids) do
			tween(l.lid, 0.08, { Size = UDim2.fromScale(l.w, l.h) })
			task.delay(0.45, function()
				if alive then
					tween(l.lid, 0.12, { Size = UDim2.fromScale(l.w, 0) })
				end
			end)
		end
	end

	return f, api
end

-- Mosca
local function buildFly(parent, maid)
	local fly = new("Frame", {
		Name = "Fly",
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.25),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, parent)
	local wingA = new("Frame", {
		Size = UDim2.fromScale(0.5, 0.28),
		Position = UDim2.fromScale(0.15, 0.1),
		Rotation = -25,
		BackgroundColor3 = Color3.fromRGB(215, 230, 235),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, fly)
	corner(wingA, UDim.new(0.5, 0))
	local wingB = new("Frame", {
		Size = UDim2.fromScale(0.5, 0.28),
		Position = UDim2.fromScale(0.32, 0.04),
		Rotation = 20,
		BackgroundColor3 = Color3.fromRGB(215, 230, 235),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, fly)
	corner(wingB, UDim.new(0.5, 0))
	local body = new("Frame", {
		Size = UDim2.fromScale(0.55, 0.38),
		Position = UDim2.fromScale(0.2, 0.42),
		BackgroundColor3 = Color3.fromRGB(35, 35, 40),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, fly)
	corner(body, UDim.new(0.5, 0))
	local head = new("Frame", {
		Size = UDim2.fromScale(0.28, 0.28),
		Position = UDim2.fromScale(0.64, 0.38),
		BackgroundColor3 = Color3.fromRGB(70, 70, 78),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, fly)
	corner(head, UDim.new(0.5, 0))
	loopTween(maid, wingA, 0.06, { Rotation = -5 }, Enum.EasingStyle.Linear)
	loopTween(maid, wingB, 0.06, { Rotation = 45 }, Enum.EasingStyle.Linear)
	return fly
end

-- Nenúfar con "corte" tipo pac-man
local function makeLilyPad(parent, size, pos, maid, still)
	local pad = new("Frame", {
		Name = "LilyPad",
		Size = UDim2.fromOffset(size, size),
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.PadGreen,
		BorderSizePixel = 0,
		ZIndex = 2,
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
	}, pad)
	corner(hl, UDim.new(0.5, 0))
	-- el "corte": varias barras desde el centro hacia el borde formando una cuña
	local len = 0.52
	for _, deg in ipairs({ -22, -11, 0, 11, 22 }) do
		local a = math.rad(deg)
		new("Frame", {
			Size = UDim2.fromScale(len, 0.14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.cos(a) * len / 2, 0.5 + math.sin(a) * len / 2),
			Rotation = deg,
			BackgroundColor3 = C.WaterCut,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, pad)
	end
	if not still then
		loopTween(
			maid,
			pad,
			rng:NextNumber(3.5, 6),
			{ Position = UDim2.new(pos.X.Scale, rng:NextInteger(-14, 14), pos.Y.Scale, rng:NextInteger(-10, 10)) }
		)
		loopTween(maid, pad, rng:NextNumber(6, 10), { Rotation = rng:NextInteger(-30, 30) })
	end
	return pad
end

-- Molino de agua giratorio
local function makeWatermill(parent, size, anchor, pos, maid, reverse)
	local holder = new("Frame", {
		Name = "Watermill",
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = anchor,
		Position = pos,
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, parent)
	local wheel = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, holder)
	local rim = new("Frame", {
		Size = UDim2.fromScale(0.86, 0.86),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, wheel)
	corner(rim, UDim.new(0.5, 0))
	stroke(rim, C.WoodLight, 3)
	for i = 0, 3 do
		new("Frame", {
			Size = UDim2.fromScale(0.86, 0.07),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = i * 45,
			BackgroundColor3 = C.WoodDark,
			BorderSizePixel = 0,
		}, wheel)
	end
	for i = 0, 7 do
		local a = math.rad(i * 45)
		local blade = new("Frame", {
			Size = UDim2.fromScale(0.13, 0.22),
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.46, 0.5 + math.sin(a) * 0.46),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = i * 45,
			BackgroundColor3 = C.Wood,
			BorderSizePixel = 0,
		}, wheel)
		corner(blade, UDim.new(0, 2))
		stroke(blade, C.WoodDark, 1)
	end
	local hub = new("Frame", {
		Size = UDim2.fromScale(0.24, 0.24),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.WoodDark,
		BorderSizePixel = 0,
	}, wheel)
	corner(hub, UDim.new(0.5, 0))
	local core = new("Frame", {
		Size = UDim2.fromScale(0.45, 0.45),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Neon,
		BorderSizePixel = 0,
	}, hub)
	corner(core, UDim.new(0.5, 0))
	loopTween(maid, wheel, 7, { Rotation = reverse and -360 or 360 }, Enum.EasingStyle.Linear, false)
	return holder
end

-- Fondo de charca animada (agua + nenúfares + molinos)
local function makeWater(parent, maid)
	local pond = new("Frame", {
		Name = "Pond",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.WaterMid,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, parent)
	corner(pond, UDim.new(0, 14))
	new("UIGradient", {
		Color = ColorSequence.new(C.WaterMid, C.WaterDark),
		Rotation = 90,
	}, pond)

	local waveSeq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.94),
		NumberSequenceKeypoint.new(0.2, 0.76),
		NumberSequenceKeypoint.new(0.4, 0.94),
		NumberSequenceKeypoint.new(0.6, 0.8),
		NumberSequenceKeypoint.new(0.8, 0.94),
		NumberSequenceKeypoint.new(1, 0.9),
	})
	local thinSeq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.97),
		NumberSequenceKeypoint.new(0.15, 0.82),
		NumberSequenceKeypoint.new(0.3, 0.97),
		NumberSequenceKeypoint.new(0.55, 0.97),
		NumberSequenceKeypoint.new(0.7, 0.84),
		NumberSequenceKeypoint.new(0.85, 0.97),
		NumberSequenceKeypoint.new(1, 0.97),
	})
	local defs = {
		{ color = C.WaterLight, rot = 18, speed = 0.55, phase = 0, amp = 0.45, seq = waveSeq },
		{ color = Color3.fromRGB(90, 225, 150), rot = -28, speed = 0.4, phase = 2, amp = 0.4, seq = waveSeq },
		{ color = Color3.fromRGB(235, 255, 255), rot = 72, speed = 0.75, phase = 4, amp = 0.35, seq = thinSeq },
	}
	local layers = {}
	for _, d in ipairs(defs) do
		local l = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = d.color,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, pond)
		local g = new("UIGradient", { Rotation = d.rot, Transparency = d.seq }, l)
		table.insert(layers, { grad = g, speed = d.speed, phase = d.phase, amp = d.amp })
	end
	local t0 = os.clock()
	maid:Add(RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		for _, l in ipairs(layers) do
			l.grad.Offset = Vector2.new(math.sin(t * l.speed + l.phase) * l.amp, math.cos(t * l.speed * 0.7 + l.phase) * 0.15)
		end
	end))

	-- nenúfares flotando
	local padDefs = {
		{ 0.12, 0.62, 30 },
		{ 0.34, 0.9, 38 },
		{ 0.58, 0.14, 26 },
		{ 0.82, 0.5, 34 },
		{ 0.92, 0.12, 24 },
		{ 0.46, 0.55, 22 },
	}
	for _, p in ipairs(padDefs) do
		makeLilyPad(pond, p[3], UDim2.fromScale(p[1], p[2]), maid, false)
	end

	-- molinos en esquina superior izquierda e inferior derecha
	makeWatermill(pond, 78, Vector2.new(0, 0), UDim2.fromOffset(-20, -20), maid, false)
	makeWatermill(pond, 78, Vector2.new(1, 1), UDim2.new(1, 20, 1, 20), maid, true)

	return pond
end

--------------------------------------------------------------------------
-- PANTALLA DE CARGA
--------------------------------------------------------------------------
local function runLoading(gui, size, title, onStart)
	local lmaid = newMaid()
	local root = new("Frame", {
		Name = "Loading",
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 20,
	}, gui)
	local pond = makeWater(root, lmaid)
	local pst = stroke(pond, C.Neon, 2)
	local pg = new("UIGradient", {
		Color = ColorSequence.new(C.Neon, C.WaterLight),
	}, pst)
	loopTween(lmaid, pg, 4, { Rotation = 360 }, Enum.EasingStyle.Linear, false)

	local ui = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 }, root)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromScale(0, 0.06),
		BackgroundTransparency = 1,
		Text = string.upper(title),
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = C.Neon,
	}, ui)

	local stage = new("Frame", {
		Position = UDim2.fromScale(0.08, 0.17),
		Size = UDim2.fromScale(0.84, 0.5),
		BackgroundTransparency = 1,
	}, ui)

	local padX = { 0.16, 0.5, 0.84 }
	for _, x in ipairs(padX) do
		makeLilyPad(stage, 58, UDim2.fromScale(x, 0.9), lmaid, true)
	end

	local holder = new("Frame", {
		Size = UDim2.fromOffset(46, 46),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(padX[2], 0.88),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, stage)
	local frog, frogApi = buildFrog(holder, UDim2.fromScale(1, 1))

	local fly = buildFly(stage, lmaid)
	local frogX = padX[2]
	local alive = true

	-- la rana salta de nenúfar en nenúfar (se agacha, se estira, gira y cae aplastada)
	local busy = false
	task.spawn(function()
		local cur = 2
		while alive do
			task.wait(1.1 + rng:NextNumber() * 0.9)
			if not alive then
				break
			end
			local nxt
			repeat
				nxt = rng:NextInteger(1, 3)
			until nxt ~= cur
			local dir = (nxt > cur) and 1 or -1
			cur = nxt
			frogX = padX[nxt]
			local T, crouch = 0.8, 0.14
			busy = true
			frogApi.Hop(T, 50, dir, crouch)
			task.wait(crouch)
			tween(holder, T, { Position = UDim2.fromScale(padX[nxt], 0.88) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(T + 0.4)
			busy = false
		end
	end)

	-- intenta cazar la mosca con la lengua (y falla, porque la mosca esquiva)
	task.spawn(function()
		while alive do
			task.wait(rng:NextNumber(2, 3.2))
			if not alive then
				break
			end
			if not busy and fly.Parent and frog.Parent then
				local fc = fly.AbsolutePosition + fly.AbsoluteSize / 2
				local gc = frog.AbsolutePosition + frog.AbsoluteSize / 2
				local d = fc - gc
				frogApi.Flick(math.deg(math.atan2(d.X, -d.Y)), math.clamp(d.Magnitude / (frog.AbsoluteSize.X * 0.2), 2, 5))
			end
		end
	end)

	-- la mosca esquiva a la rana
	task.spawn(function()
		while alive do
			local fx, fy
			repeat
				fx = rng:NextNumber(0.08, 0.92)
				fy = rng:NextNumber(0.08, 0.5)
			until math.abs(fx - frogX) > 0.28
			tween(fly, 0.9, { Position = UDim2.fromScale(fx, fy) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.9 + rng:NextNumber() * 0.3)
		end
	end)

	-- barra de progreso
	local msg = new("TextLabel", {
		Position = UDim2.fromScale(0.12, 0.73),
		Size = UDim2.new(0.76, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = "Invocando a la rana...",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ui)
	local pct = new("TextLabel", {
		Position = UDim2.fromScale(0.12, 0.73),
		Size = UDim2.new(0.76, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = "0%",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, ui)
	local barBg = new("Frame", {
		Position = UDim2.fromScale(0.12, 0.82),
		Size = UDim2.new(0.76, 0, 0, 16),
		BackgroundColor3 = C.DeepGreen,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, ui)
	corner(barBg, UDim.new(0.5, 0))
	stroke(barBg, C.WoodLight, 2)
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, barBg)
	corner(fill, UDim.new(0.5, 0))
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(60, 170, 255), C.Neon),
	}, fill)

	local nv = Instance.new("NumberValue")
	lmaid:Add(nv)
	lmaid:Add(nv.Changed:Connect(function(v)
		fill.Size = UDim2.fromScale(v / 100, 1)
		pct.Text = math.floor(v) .. "%"
		if v >= 80 then
			msg.Text = "Croac! Casi listo..."
		elseif v >= 40 then
			msg.Text = "Despertando la charca..."
		end
	end))

	local tw = TweenService:Create(nv, TweenInfo.new(3.6, Enum.EasingStyle.Linear), { Value = 100 })
	tw.Completed:Connect(function()
		alive = false
		task.spawn(function()
			-- esperar a que termine el salto en curso
			local t0 = os.clock()
			while busy and os.clock() - t0 < 2 do
				task.wait(0.05)
			end
			if not (root.Parent and frog.Parent and fly.Parent) then
				return
			end
			msg.Text = "Croac... algo vuela cerca"
			local sp = stage.AbsolutePosition

			-- la mosca se posa cerca de la rana (confiada)
			local side = (frogX < 0.5) and 1 or -1
			local gc = frog.AbsolutePosition + frog.AbsoluteSize / 2
			tween(fly, 0.5, { Position = UDim2.fromOffset(gc.X - sp.X + side * 52, gc.Y - sp.Y - 26) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.95)

			-- lengüetazo directo a la mosca
			local fc = fly.AbsolutePosition + fly.AbsoluteSize / 2
			gc = frog.AbsolutePosition + frog.AbsoluteSize / 2
			local d = fc - gc
			local len = math.clamp(d.Magnitude / (frog.AbsoluteSize.X * 0.2), 2, 9)
			frogApi.Flick(math.deg(math.atan2(d.X, -d.Y)), len, 0.12, 0.22)
			task.wait(0.14)

			-- la mosca queda pegada a la lengua y viaja hasta la boca
			local mouth = frog.AbsolutePosition + Vector2.new(frog.AbsoluteSize.X * 0.5, frog.AbsoluteSize.Y * 0.57)
			tween(fly, 0.22, { Position = UDim2.fromOffset(mouth.X - sp.X, mouth.Y - sp.Y) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.wait(0.24)
			fly.Visible = false
			frogApi.Gulp()
			msg.Text = "¡Ñam! Charca lista"
			task.wait(0.8)

			if onStart then
				onStart()
			end
			fadeOut(root, 0.55)
			task.delay(0.6, function()
				lmaid:Destroy()
				root:Destroy()
			end)
		end)
	end)
	tw:Play()
	lmaid:Add(function() end)
	return lmaid, function()
		alive = false
		lmaid:Destroy()
		if root then
			root:Destroy()
		end
	end
end

--------------------------------------------------------------------------
-- VENTANA
--------------------------------------------------------------------------
function UI_Library.CreateWindow(config)
	if type(config) ~= "table" then
		config = { Title = config }
	end
	local title = tostring(config.Title or config.Name or "Froggy Rivals")
	local subtitle = tostring(config.Subtitle or "Pond Edition")

	local maid = newMaid()
	local parent = resolveParent()
	local old = parent:FindFirstChild("FroggyRivalsDesign")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FroggyRivalsDesign"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	local okParent = pcall(function()
		gui.Parent = parent
	end)
	if not okParent or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local vp = viewport()
	local W = math.clamp(vp.X - 30, 300, 540)
	local H = math.clamp(vp.Y - 60, 240, 340)
	local SIDE = (W < 430) and 98 or 120

	local Window = {}
	local destroyed = false
	local loaded = false
	local minimized = false
	local cancelLoading

	------------------------------------------------------------------
	-- Ventana principal
	------------------------------------------------------------------
	local main = new("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)
	local mainScale = new("UIScale", { Scale = 0.7 }, main)

	local pond = makeWater(main, maid)
	local mst = stroke(pond, C.Neon, 2)
	local mg = new("UIGradient", { Color = ColorSequence.new(C.Neon, C.WaterLight) }, mst)
	loopTween(maid, mg, 4, { Rotation = 360 }, Enum.EasingStyle.Linear, false)

	local ui = new("Frame", {
		Name = "UI",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, main)

	-- barra de título
	local bar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = C.DeepGreen,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, ui)
	corner(bar, UDim.new(0, 14))
	new("Frame", {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 1, -1),
		BackgroundColor3 = C.Neon,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, bar)
	new("TextLabel", {
		Position = UDim2.fromOffset(56, 4),
		Size = UDim2.new(1, -150, 0, 20),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = C.Neon,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, bar)
	new("TextLabel", {
		Position = UDim2.fromOffset(56, 23),
		Size = UDim2.new(1, -150, 0, 14),
		BackgroundTransparency = 1,
		Text = subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, bar)

	local function ctrlButton(text, xOff, hoverColor)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOff, 0.5, 0),
			BackgroundColor3 = C.Wood,
			AutoButtonColor = false,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = C.Text,
		}, bar)
		corner(b, UDim.new(0, 8))
		local st = stroke(b, C.WoodDark, 2)
		b.MouseEnter:Connect(function()
			tween(st, 0.15, { Color = hoverColor })
			tween(b, 0.15, { TextColor3 = hoverColor })
		end)
		b.MouseLeave:Connect(function()
			tween(st, 0.15, { Color = C.WoodDark })
			tween(b, 0.15, { TextColor3 = C.Text })
		end)
		return b
	end
	local closeBtn = ctrlButton("X", -8, C.Red)
	local minBtn = ctrlButton("-", -42, C.Neon)

	makeDraggable(bar, main, maid)

	-- barra lateral de pestañas
	local sidebar = new("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(10, 48),
		Size = UDim2.new(0, SIDE, 1, -58),
		BackgroundColor3 = C.DeepGreen,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, ui)
	corner(sidebar, UDim.new(0, 10))
	stroke(sidebar, C.NeonDim, 1, 0.5)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, sidebar)

	local content = new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(SIDE + 18, 48),
		Size = UDim2.new(1, -(SIDE + 28), 1, -58),
		BackgroundColor3 = C.DeepGreen,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	}, ui)
	corner(content, UDim.new(0, 10))
	stroke(content, C.NeonDim, 1, 0.5)

	------------------------------------------------------------------
	-- Burbuja / rana flotante (minimizada)
	------------------------------------------------------------------
	local bubble = new("TextButton", {
		Name = "Bubble",
		Size = UDim2.fromOffset(62, 62),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(60, 120),
		BackgroundColor3 = C.WaterMid,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 10,
	}, gui)
	corner(bubble, UDim.new(0.5, 0))
	local bst = stroke(bubble, C.Neon, 2.5)
	local bg = new("UIGradient", { Color = ColorSequence.new(C.Neon, C.WaterLight) }, bst)
	loopTween(maid, bg, 3, { Rotation = 360 }, Enum.EasingStyle.Linear, false)
	local bScale = new("UIScale", { Scale = 0 }, bubble)
	new("UIGradient", { Color = ColorSequence.new(C.WaterLight, C.WaterDark), Rotation = 90 }, bubble)
	local bpad = new("Frame", {
		Size = UDim2.fromScale(0.82, 0.82),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.PadGreen,
		BorderSizePixel = 0,
	}, bubble)
	corner(bpad, UDim.new(0.5, 0))
	local bfrog = buildFrog(bubble, UDim2.fromScale(0.62, 0.62), { Position = UDim2.fromScale(0.5, 0.52) })
	loopTween(maid, bfrog, 1.1, { Position = UDim2.fromScale(0.5, 0.44) })
	local ring = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, bubble)
	corner(ring, UDim.new(0.5, 0))
	local rst = stroke(ring, C.Neon, 2, 0.2)
	loopTween(maid, ring, 1.6, { Size = UDim2.fromScale(1.7, 1.7) }, Enum.EasingStyle.Quad, false)
	loopTween(maid, rst, 1.6, { Transparency = 1 }, Enum.EasingStyle.Quad, false)

	local function minimize()
		if minimized or not loaded or destroyed then
			return
		end
		minimized = true
		local c = main.AbsolutePosition + main.AbsoluteSize / 2
		bubble.Position = UDim2.fromOffset(
			math.clamp(c.X, 31, viewport().X - 31),
			math.clamp(c.Y, 31, viewport().Y - 31)
		)
		tween(mainScale, 0.25, { Scale = 0.05 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.26, function()
			if minimized and not destroyed then
				main.Visible = false
			end
		end)
		bubble.Visible = true
		bScale.Scale = 0
		tween(bScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	local function restore()
		if not minimized or destroyed then
			return
		end
		minimized = false
		local p = bubble.Position
		local v = viewport()
		main.Position = UDim2.fromOffset(
			math.clamp(p.X.Offset, W / 2, math.max(W / 2, v.X - W / 2)),
			math.clamp(p.Y.Offset, H / 2, math.max(H / 2, v.Y - H / 2))
		)
		tween(bScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.21, function()
			if not minimized and not destroyed then
				bubble.Visible = false
			end
		end)
		main.Visible = true
		mainScale.Scale = 0.05
		tween(mainScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	makeDraggable(bubble, bubble, maid, { OnClick = restore, Clamp = 31 })
	minBtn.Activated:Connect(minimize)

	function Window:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if cancelLoading then
			cancelLoading()
		end
		maid:Destroy()
		gui:Destroy()
	end

	closeBtn.Activated:Connect(function()
		if destroyed then
			return
		end
		tween(mainScale, 0.25, { Scale = 0.05 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.27, function()
			Window:Destroy()
		end)
	end)

	------------------------------------------------------------------
	-- Pestañas
	------------------------------------------------------------------
	local tabs = {}
	local tabCount = 0

	local function selectTab(t)
		for _, o in ipairs(tabs) do
			local on = (o == t)
			o.page.Visible = on
			tween(o.btn, 0.2, {
				BackgroundColor3 = on and TAB_ACTIVE or TAB_WATER,
				TextColor3 = on and C.Neon or C.Text,
			})
			tween(o.stroke, 0.2, { Color = on and C.Neon or C.Wood })
		end
	end

	function Window:CreateTab(name)
		tabCount = tabCount + 1
		local btn = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = TAB_WATER,
			AutoButtonColor = false,
			Text = tostring(name),
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = C.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = tabCount,
		}, sidebar)
		corner(btn, UDim.new(0, 8))
		local st = stroke(btn, C.Wood, 2.5) -- marco de madera por fuera
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, btn)
		new("Frame", { -- brillo del agua en el centro
			Size = UDim2.new(0.6, 0, 0, 2),
			Position = UDim2.fromScale(0.5, 0.28),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
		}, btn)

		local page = new("ScrollingFrame", {
			Name = tostring(name),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.Neon,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, content)
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		new("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 12),
		}, page)

		local entry = { btn = btn, page = page, stroke = st }
		table.insert(tabs, entry)
		btn.Activated:Connect(function()
			selectTab(entry)
		end)
		btn.MouseEnter:Connect(function()
			if not page.Visible then
				tween(st, 0.15, { Color = C.NeonDim })
			end
		end)
		btn.MouseLeave:Connect(function()
			if not page.Visible then
				tween(st, 0.15, { Color = C.Wood })
			end
		end)
		if #tabs == 1 then
			selectTab(entry)
		end

		local Tab = {}
		local order = 0
		local function row(height)
			order = order + 1
			local r = new("Frame", {
				Size = UDim2.new(1, 0, 0, height),
				BackgroundColor3 = C.DeepGreen,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				LayoutOrder = order,
			}, page)
			corner(r, UDim.new(0, 10))
			stroke(r, C.NeonDim, 1, 0.55)
			return r
		end

		-- TOGGLE: nenúfar + rana saltarina
		function Tab:AddToggle(text, defaultState, callback)
			local state = defaultState and true or false
			local r = row(42)
			local label = new("TextLabel", {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -90, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(text),
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, r)

			local OFF = Color3.fromRGB(86, 110, 60)
			local ON = Color3.fromRGB(46, 170, 76)
			local track = new("Frame", {
				Size = UDim2.fromOffset(62, 30),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				BackgroundColor3 = state and ON or OFF,
				BorderSizePixel = 0,
			}, r)
			corner(track, UDim.new(0.5, 0))
			local tst = stroke(track, C.PadDark, 2)
			local vein = new("Frame", {
				Size = UDim2.fromScale(0.55, 0.4),
				Position = UDim2.fromScale(0.2, 0.3),
				BackgroundColor3 = C.PadLight,
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
			}, track)
			corner(vein, UDim.new(0.5, 0))
			new("Frame", { -- corte del nenúfar
				Size = UDim2.fromOffset(14, 3),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				BackgroundColor3 = C.WaterCut,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, track)

			local POS_OFF = UDim2.new(0, 2, 0.5, 0)
			local POS_ON = UDim2.new(1, -30, 0.5, 0)
			local holder = new("Frame", {
				Size = UDim2.fromOffset(28, 28),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and POS_ON or POS_OFF,
				BackgroundTransparency = 1,
				ZIndex = 3,
			}, track)
			local frog, frogApi = buildFrog(holder, UDim2.fromScale(1, 1))

			local function apply(v, animate)
				state = v
				local pos = v and POS_ON or POS_OFF
				if animate then
					frogApi.Hop(0.3, 14, v and 1 or -1, 0.07)
					task.delay(0.07, function()
						tween(holder, 0.3, { Position = pos }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					end)
				else
					holder.Position = pos
				end
				tween(track, 0.25, { BackgroundColor3 = v and ON or OFF })
				tween(tst, 0.25, { Color = v and C.Neon or C.PadDark })
				tween(label, 0.25, { TextColor3 = v and C.Neon or C.Text })
			end
			apply(state, false)
			label.TextColor3 = state and C.Neon or C.Text
			tst.Color = state and C.Neon or C.PadDark

			local hit = new("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 5,
			}, r)
			hit.Activated:Connect(function()
				apply(not state, true)
				fire(callback, state)
			end)

			local obj = {}
			function obj:Set(value, silent)
				value = value and true or false
				if value == state then
					return
				end
				apply(value, true)
				if not silent then
					fire(callback, state)
				end
			end
			function obj:Get()
				return state
			end
			return obj
		end

		-- SLIDER: barra de agua + gota
		function Tab:AddSlider(text, min, max, default, callback)
			min = tonumber(min) or 0
			max = tonumber(max) or 100
			if max < min then
				min, max = max, min
			end
			local range = math.max(max - min, 1e-9)
			local isInt = (min % 1 == 0) and (max % 1 == 0)
			local function snap(v)
				if isInt then
					return math.floor(v + 0.5)
				end
				return math.floor(v * 100 + 0.5) / 100
			end
			local function fmt(v)
				return isInt and tostring(v) or string.format("%.2f", v)
			end
			local value = snap(math.clamp(tonumber(default) or min, min, max))

			local r = row(56)
			new("TextLabel", {
				Position = UDim2.fromOffset(12, 6),
				Size = UDim2.new(1, -90, 0, 18),
				BackgroundTransparency = 1,
				Text = tostring(text),
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, r)
			local valueLbl = new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 6),
				Size = UDim2.fromOffset(70, 18),
				BackgroundTransparency = 1,
				Text = fmt(value),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextColor3 = C.Neon,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, r)

			local barFrame = new("Frame", {
				Position = UDim2.new(0, 14, 0, 38),
				Size = UDim2.new(1, -28, 0, 8),
				BackgroundColor3 = C.WaterDark,
				BorderSizePixel = 0,
			}, r)
			corner(barFrame, UDim.new(0.5, 0))
			stroke(barFrame, C.WoodLight, 1.5)
			local fill = new("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
			}, barFrame)
			corner(fill, UDim.new(0.5, 0))
			new("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(60, 170, 255), C.Neon),
			}, fill)

			-- gota de agua
			local knob = new("Frame", {
				Size = UDim2.fromOffset(18, 18),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundTransparency = 1,
				ZIndex = 3,
			}, barFrame)
			local kScale = new("UIScale", { Scale = 1 }, knob)
			local dropColor = Color3.fromRGB(120, 210, 255)
			local tail = new("Frame", {
				Size = UDim2.fromOffset(11, 11),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.08),
				Rotation = 45,
				BackgroundColor3 = dropColor,
				BorderSizePixel = 0,
			}, knob)
			corner(tail, UDim.new(0, 2))
			local drop = new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = dropColor,
				BorderSizePixel = 0,
			}, knob)
			corner(drop, UDim.new(0.5, 0))
			local shine = new("Frame", {
				Size = UDim2.fromScale(0.28, 0.28),
				Position = UDim2.fromScale(0.2, 0.22),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
			}, drop)
			corner(shine, UDim.new(0.5, 0))

			local function render(v)
				local a = (v - min) / range
				fill.Size = UDim2.fromScale(a, 1)
				knob.Position = UDim2.fromScale(a, 0.5)
				valueLbl.Text = fmt(v)
			end
			render(value)

			local function setValue(v, silent)
				v = snap(math.clamp(v, min, max))
				if v == value then
					return
				end
				value = v
				render(v)
				if not silent then
					fire(callback, v)
				end
			end

			local hit = new("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 12, 0, 30),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 4,
			}, barFrame)

			local dragging = false
			local function fromX(x)
				local a = math.clamp((x - barFrame.AbsolutePosition.X) / math.max(barFrame.AbsoluteSize.X, 1), 0, 1)
				setValue(min + range * a)
			end
			hit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					page.ScrollingEnabled = false
					tween(kScale, 0.15, { Scale = 1.3 }, Enum.EasingStyle.Back)
					fromX(input.Position.X)
				end
			end)
			maid:Add(UserInputService.InputChanged:Connect(function(input)
				if
					dragging
					and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
				then
					fromX(input.Position.X)
				end
			end))
			maid:Add(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if dragging then
						dragging = false
						page.ScrollingEnabled = true
						tween(kScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
					end
				end
			end))

			local obj = {}
			function obj:Set(v, silent)
				setValue(tonumber(v) or value, silent)
			end
			function obj:Get()
				return value
			end
			return obj
		end

		-- BOTÓN: madera / piedra de río
		function Tab:AddButton(text, callback)
			order = order + 1
			-- fondo de madera (el gradiente va en un Frame para no teñir el texto)
			local plank = new("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				LayoutOrder = order,
			}, page)
			corner(plank, UDim.new(0, 10))
			local bst2 = stroke(plank, C.WoodDark, 2)
			new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 116, 70)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 84, 52)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(92, 64, 40)),
				}),
				Rotation = 90,
			}, plank)
			local sc = new("UIScale", { Scale = 1 }, plank)
			local b = new("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = tostring(text),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextColor3 = C.Text,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 2,
			}, plank)

			b.MouseEnter:Connect(function()
				tween(bst2, 0.18, { Color = C.Neon, Thickness = 3 })
				tween(b, 0.18, { TextColor3 = C.Neon })
			end)
			b.MouseLeave:Connect(function()
				tween(bst2, 0.18, { Color = C.WoodDark, Thickness = 2 })
				tween(b, 0.18, { TextColor3 = C.Text })
				tween(sc, 0.12, { Scale = 1 })
			end)
			b.MouseButton1Down:Connect(function()
				tween(sc, 0.08, { Scale = 0.96 })
			end)
			b.MouseButton1Up:Connect(function()
				tween(sc, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
			end)
			b.Activated:Connect(function()
				tween(sc, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
				fire(callback)
			end)
			return {
				SetText = function(_, t)
					b.Text = tostring(t)
				end,
			}
		end

		return Tab
	end

	------------------------------------------------------------------
	-- Rana decorativa en la barra de título
	------------------------------------------------------------------
	local titleFrog = buildFrog(bar, UDim2.fromOffset(30, 30), {
		Position = UDim2.fromOffset(34, 20),
	})
	loopTween(maid, titleFrog, 1.2, { Position = UDim2.fromOffset(34, 17) })

	------------------------------------------------------------------
	-- Pantalla de carga -> ventana
	------------------------------------------------------------------
	local _, cancel = runLoading(gui, UDim2.fromOffset(W, H), title, function()
		if destroyed then
			return
		end
		loaded = true
		main.Visible = true
		mainScale.Scale = 0.7
		tween(mainScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	cancelLoading = cancel

	Window.Gui = gui
	return Window
end

return UI_Library
