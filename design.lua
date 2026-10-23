local UI_Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Theme = {
	Background = Color3.fromRGB(15, 15, 20),
	Row = Color3.fromRGB(17, 17, 26),
	TabOff = Color3.fromRGB(22, 22, 33),
	Off = Color3.fromRGB(44, 44, 62),
	Accent = Color3.fromRGB(150, 50, 200),
	Cyan = Color3.fromRGB(0, 255, 255),
	Light = Color3.fromRGB(190, 110, 255),
	Text = Color3.fromRGB(234, 246, 255),
	SubText = Color3.fromRGB(140, 147, 179),
	Danger = Color3.fromRGB(255, 61, 110),
	Green = Color3.fromRGB(61, 255, 154),
}

local W, H, CUT = 520, 360, 20
local TAU = math.pi * 2
local KP = ColorSequenceKeypoint.new
local PURPLE_CYAN = ColorSequence.new({ KP(0, Theme.Accent), KP(0.5, Theme.Cyan), KP(1, Theme.Accent) })

local function rand(a, b)
	return a + math.random() * (b - a)
end

local function create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function tween(inst, duration, props, style, direction)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function spin(inst, period, dir)
	inst.Rotation = 0
	local t = TweenService:Create(inst, TweenInfo.new(period, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = (dir or 1) * 360 })
	t:Play()
	return t
end

local function loopTween(inst, period, props)
	local t = TweenService:Create(inst, TweenInfo.new(period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), props)
	t:Play()
	return t
end

local function centerOf(inst)
	return inst.AbsolutePosition + inst.AbsoluteSize / 2
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function label(parent, text, props)
	local l = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
	for key, value in pairs(props or {}) do
		l[key] = value
	end
	return l
end

local function makeRing(parent, count, radius, w, h, colors, period, dir)
	local size = radius * 2 + 20
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	for i = 1, count do
		local a = (i - 1) / count * TAU
		local color = type(colors) == "table" and colors[(i % #colors) + 1] or colors
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * radius, 0.5, math.sin(a) * radius),
			Size = UDim2.fromOffset(w, h),
			Rotation = math.deg(a) + 90,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder,
		})
	end
	if period then
		spin(holder, period, dir)
	end
	return holder
end

local function resolveParent(gui)
	local candidates = {}
	if type(gethui) == "function" then
		table.insert(candidates, function() return gethui() end)
	end
	table.insert(candidates, function() return CoreGui end)
	table.insert(candidates, function() return Players.LocalPlayer:WaitForChild("PlayerGui") end)
	for _, getter in ipairs(candidates) do
		local ok, parent = pcall(getter)
		if ok and parent then
			local assigned = pcall(function()
				gui.Parent = parent
			end)
			if assigned and gui.Parent then
				return parent
			end
		end
	end
end

local function makeFX(layer, connections)
	local parts = {}
	local fx = {}

	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		local drag = 0.955 ^ (dt * 60)
		for i = #parts, 1, -1 do
			local p = parts[i]
			p.t += dt
			if p.t >= p.max then
				p.f:Destroy()
				table.remove(parts, i)
			else
				p.vx *= drag
				p.vy = p.vy * drag + 60 * dt
				p.x += p.vx * dt
				p.y += p.vy * dt
				local speed = math.sqrt(p.vx * p.vx + p.vy * p.vy)
				p.f.Size = UDim2.fromOffset(math.clamp(speed * 0.04, 2, 16), p.w)
				p.f.Position = UDim2.fromOffset(p.x, p.y)
				p.f.Rotation = math.deg(math.atan2(p.vy, p.vx))
				p.f.BackgroundTransparency = p.t / p.max
			end
		end
	end))

	function fx.spark(x, y, n, opts)
		opts = opts or {}
		for _ = 1, n do
			if #parts > 240 then
				return
			end
			local a = opts.a and (opts.a + rand(-(opts.s or 0.6), opts.s or 0.6)) or rand(0, TAU)
			local sp = rand(70, 260) * (opts.speed or 1)
			local color = opts.color or (math.random() < 0.5 and Theme.Cyan or Theme.Light)
			table.insert(parts, {
				x = x, y = y,
				vx = math.cos(a) * sp, vy = math.sin(a) * sp,
				t = 0, max = rand(0.35, 0.9), w = math.random(1, 2),
				f = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(4, 2),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Parent = layer,
				}),
			})
		end
	end

	function fx.ring(x, y, color, radius)
		local stroke = create("UIStroke", { Color = color or Theme.Cyan, Thickness = 3, Transparency = 0 })
		local ring = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(4, 4),
			BackgroundTransparency = 1,
			Parent = layer,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke })
		tween(ring, 0.7, { Size = UDim2.fromOffset(radius * 2, radius * 2) })
		tween(stroke, 0.7, { Transparency = 1, Thickness = 0.5 })
		task.delay(0.75, function()
			ring:Destroy()
		end)
	end

	function fx.sparkAt(inst, n, opts)
		local c = centerOf(inst)
		fx.spark(c.X, c.Y, n, opts)
	end

	return fx
end

local function makeDraggable(handle, target, connections, onClick, onMove)
	local dragging, moved = false, false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, moved = true, false
			dragInput = input
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
			local delta = input.Position - dragStart
			if delta.Magnitude > 5 then
				moved = true
			end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				if onMove then
					onMove()
				end
			end
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and isPress(input) then
			dragging = false
			if not moved and onClick then
				onClick()
			end
		end
	end))
end

local TabMethods = {}
TabMethods.__index = TabMethods

local function newRow(tab, height, clickable)
	tab._order += 1
	local win = tab._win
	local holder = create("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = tab._order,
		Parent = tab.Page,
	})
	local props = {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Row,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}
	if clickable then
		props.Text = ""
		props.AutoButtonColor = false
	end
	local row = create(clickable and "TextButton" or "Frame", props)
	local stroke = create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = row })
	create("UIGradient", { Color = ColorSequence.new({ KP(0, Theme.Accent), KP(0.45, Color3.fromRGB(80, 80, 110)), KP(1, Theme.Cyan) }), Parent = stroke })

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0, 3, 0.44, 0),
		BackgroundColor3 = Theme.Cyan,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = row,
	})
	local shine = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, -60, 0.5, 0),
		Size = UDim2.new(0, 40, 0, height * 2),
		Rotation = 20,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = row,
	})

	row.MouseEnter:Connect(function()
		tween(bar, 0.25, { Size = UDim2.new(0, 3, 1, 0) })
		tween(stroke, 0.2, { Thickness = 1.6 })
		shine.Position = UDim2.new(0, -60, 0.5, 0)
		tween(shine, 0.7, { Position = UDim2.new(1, 60, 0.5, 0) })
		local pos = row.AbsolutePosition
		win.FX.spark(pos.X + 2, pos.Y + row.AbsoluteSize.Y / 2, 4, { a = math.pi, s = 0.8, speed = 0.5 })
	end)
	row.MouseLeave:Connect(function()
		tween(bar, 0.25, { Size = UDim2.new(0, 3, 0.44, 0) })
		tween(stroke, 0.2, { Thickness = 1 })
	end)

	table.insert(tab._rows, row)
	return row
end

function TabMethods:_enter()
	for i, row in ipairs(self._rows) do
		row.Position = UDim2.fromOffset(-90, 0)
		task.delay(0.07 * (i - 1) + 0.05, function()
			if row.Parent then
				tween(row, 0.55, { Position = UDim2.new() })
			end
		end)
	end
end

function TabMethods:AddToggle(text, defaultState, callback)
	local win = self._win
	local state = defaultState and true or false
	local row = newRow(self, 44, true)

	label(row, string.upper(text), { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -140, 1, 0) })
	local st = label(row, state and "ON" or "OFF", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -80, 0.5, 0),
		Size = UDim2.fromOffset(34, 20),
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = state and Theme.Cyan or Theme.SubText,
	})

	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(56, 22),
		BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Off,
		BorderSizePixel = 0,
		Parent = row,
	}, { create("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Cyan) }) })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, state and 30 or 4, 0.5, 0),
		Size = UDim2.fromOffset(22, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = track,
	})

	local function render()
		tween(knob, 0.32, { Position = UDim2.new(0, state and 30 or 4, 0.5, 0) }, Enum.EasingStyle.Back)
		tween(track, 0.25, { BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Off })
		st.Text = state and "ON" or "OFF"
		tween(st, 0.2, { TextColor3 = state and Theme.Cyan or Theme.SubText })
	end

	local function set(value, silent)
		state = value and true or false
		render()
		if not silent then
			tween(knob, 0.08, { Size = UDim2.fromOffset(14, 20) })
			task.delay(0.08, function()
				tween(knob, 0.3, { Size = UDim2.fromOffset(22, 16) }, Enum.EasingStyle.Back)
			end)
			local c = centerOf(track)
			local color = state and Theme.Cyan or Theme.Danger
			win.FX.spark(c.X, c.Y, state and 18 or 8, { color = color })
			win.FX.ring(c.X, c.Y, color, 46)
			win._fire(320, 4)
			if callback then
				task.spawn(callback, state)
			end
		end
	end

	row.Activated:Connect(function()
		set(not state)
	end)

	return {
		Set = function(_, value) set(value, true) end,
		Get = function() return state end,
	}
end

function TabMethods:AddButton(text, callback)
	local win = self._win
	local row = newRow(self, 44, true)

	label(row, string.upper(text), {
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.SciFi,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local function bracket(side)
		local holder = create("Frame", {
			AnchorPoint = Vector2.new(side == 1 and 0 or 1, 0.5),
			Position = side == 1 and UDim2.new(0, 16, 0.5, 0) or UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(8, 20),
			BackgroundTransparency = 1,
			Parent = row,
		})
		local function bar(x, y, w, h)
			create("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = Theme.Cyan, BorderSizePixel = 0, Parent = holder })
		end
		if side == 1 then
			bar(0, 0, 2, 20); bar(0, 0, 8, 2); bar(0, 18, 8, 2)
		else
			bar(6, 0, 2, 20); bar(0, 0, 8, 2); bar(0, 18, 8, 2)
		end
		return holder
	end
	local left, right = bracket(1), bracket(-1)

	local function place(offset)
		tween(left, 0.25, { Position = UDim2.new(0, 16 + offset, 0.5, 0) }, Enum.EasingStyle.Back)
		tween(right, 0.25, { Position = UDim2.new(1, -16 - offset, 0.5, 0) }, Enum.EasingStyle.Back)
	end
	row.MouseEnter:Connect(function() place(-5) end)
	row.MouseLeave:Connect(function() place(0) end)
	row.MouseButton1Down:Connect(function() place(50) end)
	row.MouseButton1Up:Connect(function() place(-5) end)

	row.Activated:Connect(function(input)
		local c = centerOf(row)
		local x = (input and input.Position and input.Position.X) or c.X
		local scale = win._root.AbsoluteSize.X / W
		local rip = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((x - row.AbsolutePosition.X) / scale, 22),
			Size = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
			Parent = row,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			create("UIStroke", { Color = Theme.Cyan, Thickness = 2 }),
		})
		tween(rip, 0.6, { Size = UDim2.fromOffset(420, 420) })
		tween(rip.UIStroke, 0.6, { Transparency = 1 })
		task.delay(0.65, function() rip:Destroy() end)
		win.FX.spark(x, c.Y, 22, { speed = 1.2 })
		win.FX.ring(x, c.Y, Theme.Light, 60)
		win._fire(450, 6)
		if callback then
			task.spawn(callback)
		end
	end)

	return row
end

function TabMethods:AddSlider(text, min, max, default, callback)
	local win = self._win
	local isInt = math.floor(min) == min and math.floor(max) == max and math.floor(default) == default
	local step = isInt and 1 or 0.01
	local row = newRow(self, 64, false)

	label(row, string.upper(text), { Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -120, 0, 24) })
	local valueLabel = label(row, "", {
		Position = UDim2.new(1, -96, 0, 6),
		Size = UDim2.fromOffset(78, 24),
		Font = Enum.Font.Code,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.Cyan,
	})

	local hit = create("TextButton", {
		Position = UDim2.fromOffset(20, 34),
		Size = UDim2.new(1, -40, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	local track = create("Frame", {
		Position = UDim2.new(0, 0, 0.5, -4),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = Color3.fromRGB(40, 40, 58),
		BorderSizePixel = 0,
		Parent = hit,
	})
	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, { create("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Cyan) }) })
	for k = 1, 9 do
		create("Frame", {
			Position = UDim2.new(k / 10, -1, 0, 0),
			Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = Color3.fromRGB(12, 12, 18),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		})
	end
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = hit,
	}, { create("UIStroke", { Color = Theme.Accent, Thickness = 2 }) })

	local value
	local function apply(raw, animate, silent)
		raw = math.clamp(raw, min, max)
		raw = math.floor(raw / step + 0.5) * step
		if not isInt then
			raw = tonumber(string.format("%.2f", raw))
		end
		raw = math.clamp(raw, min, max)
		local changed = raw ~= value
		value = raw
		valueLabel.Text = isInt and tostring(value) or string.format("%.2f", value)
		local rel = (max == min) and 0 or (value - min) / (max - min)
		if animate then
			tween(fill, 0.1, { Size = UDim2.new(rel, 0, 1, 0) })
			tween(knob, 0.1, { Position = UDim2.new(rel, 0, 0.5, 0) })
		else
			fill.Size = UDim2.new(rel, 0, 1, 0)
			knob.Position = UDim2.new(rel, 0, 0.5, 0)
		end
		if changed and not silent and callback then
			task.spawn(callback, value)
		end
	end
	apply(default, false, true)

	local dragging = false
	local function fromX(x)
		local rel = math.clamp((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1), 0, 1)
		apply(min + (max - min) * rel, false)
		local c = centerOf(knob)
		win.FX.spark(c.X, c.Y, 2, { a = rand(0, TAU), s = 3, speed = 0.5 })
	end

	hit.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			self.Page.ScrollingEnabled = false
			tween(knob, 0.15, { Size = UDim2.fromOffset(20, 20) })
			fromX(input.Position.X)
			win._fire(200, 0)
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and isPress(input) then
			dragging = false
			self.Page.ScrollingEnabled = true
			tween(knob, 0.15, { Size = UDim2.fromOffset(14, 14) })
			local c = centerOf(knob)
			win.FX.spark(c.X, c.Y, 14)
			win.FX.ring(c.X, c.Y, Theme.Cyan, 40)
		end
	end))

	return {
		Set = function(_, v) apply(v, true, true) end,
		Get = function() return value end,
	}
end

local WindowMethods = {}
WindowMethods.__index = WindowMethods

function WindowMethods:CreateTab(name)
	local tab = setmetatable({
		Name = name,
		_order = 0,
		_rows = {},
		_win = self,
		_connections = self._connections,
	}, TabMethods)

	tab.Button = create("TextButton", {
		Size = UDim2.new(0, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.TabOff,
		AutoButtonColor = false,
		Text = string.upper(name),
		TextColor3 = Theme.SubText,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = #self.Tabs + 1,
		Parent = self._tabBar,
	}, { create("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }) })

	tab.Bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Theme.Cyan,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = tab.Button,
	})
	local shine = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, -30, 0.5, 0),
		Size = UDim2.fromOffset(24, 90),
		Rotation = 20,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		Parent = tab.Button,
	})

	tab.Page = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		Parent = self._pages,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6) }),
	})

	tab.Button.Activated:Connect(function()
		if self._active ~= tab then
			shine.Position = UDim2.new(0, -30, 0.5, 0)
			tween(shine, 0.55, { Position = UDim2.new(1, 30, 0.5, 0) })
			local c = centerOf(tab.Button)
			self.FX.spark(c.X, c.Y, 10)
			self._fire(260, 3)
		end
		self:_select(tab)
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:_select(tab, true)
	end
	return tab
end

function WindowMethods:_select(tab, instant)
	if self._active == tab then
		return
	end
	self._active = tab
	for _, other in ipairs(self.Tabs) do
		local on = other == tab
		other.Page.Visible = on
		tween(other.Button, 0.25, {
			BackgroundColor3 = on and Theme.Accent or Theme.TabOff,
			TextColor3 = on and Theme.Text or Theme.SubText,
		})
		tween(other.Bar, 0.25, { BackgroundTransparency = on and 0 or 1 })
	end
	if not instant and self._ready then
		tab:_enter()
	end
end

function WindowMethods:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	task.spawn(function()
		self._fire(500, 12)
		self._main.Visible = false
		tween(self._body, 0.35, { Size = UDim2.fromOffset(W, 2) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.wait(0.36)
		local c = centerOf(self._root)
		self.FX.spark(c.X, c.Y, 30, { a = 0, s = 0.1, speed = 2 })
		self.FX.spark(c.X, c.Y, 30, { a = math.pi, s = 0.1, speed = 2 })
		tween(self._body, 0.25, { Size = UDim2.fromOffset(0, 2) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		for _, edge in ipairs(self._edges) do
			tween(edge, 0.5, { Size = UDim2.fromOffset(0, 2) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
		task.wait(0.55)
		for _, connection in ipairs(self._connections) do
			connection:Disconnect()
		end
		self._gui:Destroy()
	end)
end

local function buildCorner(parent, sx, sy, c, index)
	local function place(x, y, w, h)
		return UDim2.fromOffset(sx == 1 and x or (W - x - w), sy == 1 and y or (H - y - h))
	end
	local function rect(x, y, w, h, color)
		return create("Frame", {
			Position = place(x, y, w, h),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = parent,
		})
	end
	local function glow(frame)
		return create("UIStroke", { Color = Theme.Cyan, Thickness = 0, Transparency = 0.2, Parent = frame })
	end

	local corner = { bars = {}, glows = {}, latches = {} }
	local hbar = rect(c, 0, 40, 3, Theme.Cyan)
	local vbar = rect(0, c, 3, 40, Theme.Cyan)
	corner.bars = { hbar, vbar }
	if c > 0 then
		local diag = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(sx == 1 and c / 2 or W - c / 2, sy == 1 and c / 2 or H - c / 2),
			Size = UDim2.fromOffset(c * 1.414 + 3, 3),
			Rotation = -45,
			BackgroundColor3 = Theme.Cyan,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = parent,
		})
		table.insert(corner.bars, diag)
	end
	for _, bar in ipairs(corner.bars) do
		table.insert(corner.glows, glow(bar))
	end

	local function latch(x, y, w, h, dirX, dirY)
		local fireWrap = rect(x, y, w, h, Theme.Accent)
		fireWrap.BackgroundTransparency = 1
		local creep = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = fireWrap })
		local body = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = creep })
		local origin = fireWrap.Position
		task.delay(index * 0.6, function()
			if creep.Parent then
				loopTween(creep, 2.6, { Position = UDim2.fromOffset(dirX * 12, dirY * 12) })
			end
		end)
		table.insert(corner.latches, {
			wrap = fireWrap, body = body, origin = origin,
			target = UDim2.new(origin.X.Scale, origin.X.Offset + dirX * 30, origin.Y.Scale, origin.Y.Offset + dirY * 30),
		})
	end
	latch(c + 48, 8, 28, 4, sx, 0)
	latch(8, c + 48, 4, 28, 0, sy)

	local gx, gy = (c > 0 and c * 0.3 or 15), (c > 0 and c * 0.3 or 15)
	local gsize = c > 0 and 7 or 10
	local gearAnchor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(sx == 1 and gx or W - gx, sy == 1 and gy or H - gy),
		Size = UDim2.fromOffset(gsize, gsize),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = parent,
	})
	corner.burst = create("Frame", { Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = gearAnchor })
	local outer = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = corner.burst }, { create("UIStroke", { Color = Theme.Light, Thickness = 1.5 }) })
	local inner = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Cyan, BorderSizePixel = 0, Parent = corner.burst })
	spin(outer, 4, sx * sy)
	spin(inner, 2.5, -sx * sy)

	corner.anchor = gearAnchor
	corner.dirX = sx == 1 and -1 or 1
	corner.dirY = sy == 1 and -1 or 1
	return corner
end

function UI_Library.CreateWindow(config)
	config = config or {}
	local title = string.upper(tostring(config.Title or "Window"))
	local subtitle = tostring(config.Subtitle or "")

	local gui = create("ScreenGui", {
		Name = "EpicDarkUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	local parent = resolveParent(gui)
	if not parent then
		warn("[design.lua] No se pudo asignar el ScreenGui")
		return
	end
	for _, old in ipairs(parent:GetChildren()) do
		if old ~= gui and old.Name == "EpicDarkUI" then
			old:Destroy()
		end
	end

	local window = setmetatable({ Tabs = {}, _connections = {}, _gui = gui, _visible = false, _ready = false, _edges = {} }, WindowMethods)
	local connections = window._connections

	local fxLayer = create("Frame", { Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = gui })
	local fx = makeFX(fxLayer, connections)
	window.FX = fx

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(900, 600)
	local baseScale = math.min(1, (viewport.X - 14) / W, (viewport.Y - 14) / H)

	local root = create("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { create("UIScale", { Scale = baseScale }) })
	window._root = root

	local anim = create("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local animScale = create("UIScale", { Scale = 1, Parent = anim })

	local body = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = anim,
	})
	window._body = body
	local content = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1,
		Parent = body,
	})

	local function glassRect(x, y, w, h)
		return create("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Parent = content,
		})
	end
	glassRect(0, CUT, W, H - CUT * 2)
	glassRect(CUT, 0, W - CUT, CUT)
	glassRect(0, H - CUT, W - CUT, CUT)

	local function glassTriangle(x, y, sign)
		local clip = create("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(CUT, CUT),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Parent = content,
		})
		local s = CUT * 3
		local offset = CUT / 2 + sign * (s / 2) * 0.7071
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(offset, offset),
			Size = UDim2.fromOffset(s, s),
			Rotation = 45,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Parent = clip,
		})
	end
	glassTriangle(0, 0, 1)
	glassTriangle(W - CUT, H - CUT, -1)

	create("Frame", {
		Position = UDim2.fromOffset(0, CUT),
		Size = UDim2.fromOffset(W, 140),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = content,
	}, { create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.93, 1) }) })

	local scan = create("Frame", {
		Position = UDim2.fromOffset(CUT, -50),
		Size = UDim2.fromOffset(W - CUT * 2, 50),
		BackgroundColor3 = Theme.Cyan,
		BorderSizePixel = 0,
		Parent = content,
	}, { create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 1) }) }) })
	TweenService:Create(scan, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Position = UDim2.fromOffset(CUT, H) }):Play()

	local moteLayer = create("Frame", {
		Position = UDim2.fromOffset(CUT, 0),
		Size = UDim2.fromOffset(W - CUT * 2, H),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = content,
	})
	local motes = {}
	for i = 1, 26 do
		motes[i] = {
			x = rand(0, W - CUT * 2), y = rand(0, H),
			vx = rand(-8, 8), vy = rand(-18, -4),
			f = create("Frame", {
				Size = UDim2.fromOffset(2, 2),
				BackgroundColor3 = math.random() < 0.5 and Theme.Cyan or Theme.Light,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Parent = moteLayer,
			}),
		}
	end

	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not window._visible then
			return
		end
		local scale = math.max(root.AbsoluteSize.X / W, 0.01)
		local mouse = (UserInputService:GetMouseLocation() - moteLayer.AbsolutePosition) / scale
		for _, m in ipairs(motes) do
			m.x += m.vx * dt
			m.y += m.vy * dt
			if m.y < -4 then m.y = H + 4; m.x = rand(0, W - CUT * 2) end
			if m.x < -4 then m.x = W - CUT * 2 + 4 end
			if m.x > W - CUT * 2 + 4 then m.x = -4 end
			local dx, dy = mouse.X - m.x, mouse.Y - m.y
			local d = math.sqrt(dx * dx + dy * dy)
			if d < 90 then
				m.x += dx * dt * 0.8
				m.y += dy * dt * 0.8
				m.f.BackgroundTransparency = 0.35 - (1 - d / 90) * 0.35
			else
				m.f.BackgroundTransparency = 0.35
			end
			m.f.Position = UDim2.fromOffset(m.x, m.y)
		end
	end))

	local main = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content })
	window._main = main

	local header = create("Frame", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, Parent = main })
	local emblemOuter = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(50, 27), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1, Parent = header,
	}, { create("UIStroke", { Color = Theme.Cyan, Thickness = 1.5 }) })
	local emblemInner = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(50, 27), Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = header,
	})
	spin(emblemOuter, 8, 1)
	spin(emblemInner, 5, -1)

	local titleLabel = label(header, title, {
		Position = UDim2.fromOffset(74, 7), Size = UDim2.new(1, -200, 0, 24),
		Font = Enum.Font.SciFi, TextSize = 20,
	})
	create("UIStroke", { Color = Theme.Cyan, Thickness = 1, Transparency = 0.7, Parent = titleLabel })

	local led1 = create("Frame", { Position = UDim2.fromOffset(76, 37), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Green, BorderSizePixel = 0, Parent = header })
	local led2 = create("Frame", { Position = UDim2.fromOffset(86, 37), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = header })
	loopTween(led1, 0.7, { BackgroundTransparency = 0.8 })
	task.delay(0.35, function() loopTween(led2, 0.7, { BackgroundTransparency = 0.8 }) end)
	local subLabel = label(header, subtitle, {
		Position = UDim2.fromOffset(98, 31), Size = UDim2.new(1, -230, 0, 18),
		Font = Enum.Font.Code, TextSize = 12, TextColor3 = Theme.SubText,
	})
	task.spawn(function()
		while gui.Parent and not window._destroyed do
			subLabel.Text = (subtitle ~= "" and (subtitle .. "  |  ") or "") .. string.format("SYS 0x%04X", math.random(4096, 65535))
			task.wait(0.14)
		end
	end)

	local function headerButton(text, x, hoverColor)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(x, 7),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = Theme.Row,
			AutoButtonColor = false,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			BorderSizePixel = 0,
			Parent = header,
		})
		local stroke = create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Parent = button })
		create("UIGradient", { Color = ColorSequence.new(Theme.Cyan, Theme.Accent), Parent = stroke })
		button.MouseEnter:Connect(function()
			tween(button, 0.15, { BackgroundColor3 = hoverColor })
			window._fire(260, 2)
		end)
		button.MouseLeave:Connect(function()
			tween(button, 0.15, { BackgroundColor3 = Theme.Row })
		end)
		return button
	end
	local closeButton = headerButton("×", W - 14 - 40, Theme.Danger)
	local minimizeButton = headerButton("–", W - 14 - 40 - 46, Color3.fromRGB(42, 42, 58))

	local dragHandle = create("Frame", { Size = UDim2.new(1, -112, 1, 0), BackgroundTransparency = 1, ZIndex = 0, Parent = header })

	create("Frame", {
		Position = UDim2.fromOffset(CUT, 63), Size = UDim2.fromOffset(W - CUT * 2, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = main,
	}, { create("UIGradient", { Color = PURPLE_CYAN, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1) }) }) })

	local tabBar = create("ScrollingFrame", {
		Position = UDim2.fromOffset(18, 66),
		Size = UDim2.fromOffset(W - 36, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		Parent = main,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	window._tabBar = tabBar
	window._pages = create("Frame", {
		Position = UDim2.fromOffset(18, 114),
		Size = UDim2.fromOffset(W - 36, H - 114 - 18),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})

	local function mkEdge(cx, cy, len, rot)
		local f = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(0, 2),
			Rotation = rot,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 7,
			Parent = anim,
		})
		local g = create("UIGradient", { Color = PURPLE_CYAN, Parent = f })
		create("UIStroke", { Color = Theme.Cyan, Thickness = 2, Transparency = 0.75, Parent = f })
		spin(g, 5, 1)
		f:SetAttribute("Len", len)
		table.insert(window._edges, f)
	end
	mkEdge((CUT + W) / 2, 1, W - CUT, 0)
	mkEdge((W - CUT) / 2, H - 1, W - CUT, 0)
	mkEdge(1, (CUT + H) / 2, H - CUT, 90)
	mkEdge(W - 1, (H - CUT) / 2, H - CUT, 90)
	mkEdge(CUT / 2, CUT / 2, CUT * 1.414, -45)
	mkEdge(W - CUT / 2, H - CUT / 2, CUT * 1.414, -45)

	local corners = {
		buildCorner(anim, 1, 1, CUT, 0),
		buildCorner(anim, -1, 1, 0, 1),
		buildCorner(anim, -1, -1, CUT, 2),
		buildCorner(anim, 1, -1, 0, 3),
	}

	function window._fire(duration, sparks)
		for _, corner in ipairs(corners) do
			for _, bar in ipairs(corner.bars) do
				tween(bar, 0.12, { BackgroundColor3 = Color3.new(1, 1, 1) })
			end
			for _, g in ipairs(corner.glows) do
				tween(g, 0.12, { Thickness = 2.5 })
			end
			for _, l in ipairs(corner.latches) do
				tween(l.wrap, 0.28, { Position = l.target }, Enum.EasingStyle.Back)
				tween(l.body, 0.15, { BackgroundColor3 = Theme.Cyan })
			end
			tween(corner.burst, 0.35, { Rotation = 180 })
			if sparks > 0 and window._visible then
				local c = centerOf(corner.anchor)
				fx.spark(c.X, c.Y, sparks, { a = math.atan2(corner.dirY, corner.dirX), s = 0.9 })
			end
			task.delay(duration / 1000, function()
				for _, bar in ipairs(corner.bars) do
					tween(bar, 0.25, { BackgroundColor3 = Theme.Cyan })
				end
				for _, g in ipairs(corner.glows) do
					tween(g, 0.25, { Thickness = 0 })
				end
				for _, l in ipairs(corner.latches) do
					tween(l.wrap, 0.4, { Position = l.origin })
					tween(l.body, 0.3, { BackgroundColor3 = Theme.Accent })
				end
				corner.burst.Rotation = 0
			end)
		end
	end

	local bootF = create("CanvasGroup", {
		Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false, ZIndex = 10, Parent = content,
	})
	local bootScale = create("UIScale", { Scale = 1, Parent = bootF })
	create("Frame", {
		Position = UDim2.fromOffset(CUT, CUT), Size = UDim2.fromOffset(W - CUT * 2, H - CUT * 2),
		BackgroundColor3 = Color3.fromRGB(8, 8, 14), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = bootF,
	})
	local reactor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(W / 2, 104), Size = UDim2.fromOffset(120, 120),
		BackgroundTransparency = 1, Parent = bootF,
	})
	makeRing(reactor, 24, 54, 2, 6, Theme.Cyan, 6, 1)
	makeRing(reactor, 8, 44, 16, 4, Theme.Accent, 4, -1)
	makeRing(reactor, 10, 34, 8, 2, Theme.Cyan, 1.6, 1)
	makeRing(reactor, 6, 18.2, 21, 2, Theme.Text, 7, -1)
	local core = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Theme.Cyan, BorderSizePixel = 0, Parent = reactor,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	loopTween(core, 0.5, { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0.5 })

	local bootTitle = label(bootF, title, {
		Position = UDim2.fromOffset(0, 172), Size = UDim2.fromOffset(W, 28),
		Font = Enum.Font.SciFi, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center,
	})
	create("UIStroke", { Color = Theme.Cyan, Thickness = 1.5, Transparency = 0.6, Parent = bootTitle })
	local segHolder = create("Frame", { Position = UDim2.fromOffset(0, 210), Size = UDim2.fromOffset(W, 9), BackgroundTransparency = 1, Parent = bootF }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 3) }),
	})
	local segs = {}
	for i = 1, 24 do
		segs[i] = create("Frame", { Size = UDim2.fromOffset(13, 8), BackgroundColor3 = Color3.fromRGB(34, 34, 48), BorderSizePixel = 0, Parent = segHolder })
	end
	local pctLabel = label(bootF, "000%", {
		Position = UDim2.fromOffset(0, 226), Size = UDim2.fromOffset(W, 20),
		Font = Enum.Font.SciFi, TextSize = 15, TextColor3 = Theme.Cyan, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local logLabel = label(bootF, "", {
		Position = UDim2.fromOffset(0, 248), Size = UDim2.fromOffset(W, 18),
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local flash = create("Frame", {
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 20, Parent = content,
	})

	local bubble = create("Frame", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(84, 84),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	makeRing(bubble, 24, 38, 6, 2, { Theme.Accent, Theme.Cyan }, 10, 1)
	local plates = {}
	for k = 0, 3 do
		local holder = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1, Parent = bubble,
		})
		local m = math.rad(k * 90 + 45)
		local segsList = {}
		for j = 0, 4 do
			local a = math.rad(k * 90 + 14 + j * 15.5)
			table.insert(segsList, create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(a) * 29, 0.5, math.sin(a) * 29),
				Size = UDim2.fromOffset(9, 5),
				Rotation = math.deg(a) + 90,
				BackgroundColor3 = Theme.Cyan,
				BorderSizePixel = 0,
				Parent = holder,
			}))
		end
		plates[k + 1] = { holder = holder, dx = math.cos(m), dy = math.sin(m), segs = segsList }
	end
	local coreHolder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(84, 84),
		BackgroundTransparency = 1, Parent = bubble,
	})
	local coreScale = create("UIScale", { Scale = 1, Parent = coreHolder })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = coreHolder,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = Theme.Accent, Thickness = 1.5 }) })
	makeRing(coreHolder, 6, 18.2, 21, 2, Theme.Light, 6, -1)
	makeRing(coreHolder, 3, 31, 5, 5, { Theme.Text, Theme.Cyan, Theme.Light }, 3, 1)
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.Cyan, BackgroundTransparency = 0.85, BorderSizePixel = 0, Parent = coreHolder,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = Theme.Cyan, Thickness = 1.5 }) })
	label(coreHolder, string.sub(title, 1, 1), {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22),
		Font = Enum.Font.SciFi, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local bubbleButton = create("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 30, Parent = bubble,
	})

	local function setPlates(offset, transparency, color, duration, style)
		for k, plate in ipairs(plates) do
			task.delay((k - 1) * 0.07, function()
				tween(plate.holder, duration, { Position = UDim2.new(0.5, plate.dx * offset, 0.5, plate.dy * offset) }, style or Enum.EasingStyle.Back)
				for _, seg in ipairs(plate.segs) do
					tween(seg, duration * 0.6, { BackgroundTransparency = transparency, BackgroundColor3 = color })
				end
			end)
		end
	end

	local hovered = false
	bubbleButton.MouseEnter:Connect(function()
		hovered = true
		setPlates(4, 0, Color3.new(1, 1, 1), 0.3)
	end)
	bubbleButton.MouseLeave:Connect(function()
		hovered = false
		setPlates(0, 0, Theme.Cyan, 0.3)
	end)
	local sparkTimer = 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if hovered and bubble.Visible then
			sparkTimer += dt
			if sparkTimer > 0.06 then
				sparkTimer = 0
				local c = centerOf(bubble)
				local a = rand(0, TAU)
				fx.spark(c.X + math.cos(a) * 34, c.Y + math.sin(a) * 34, 2, { a = a, s = 0.3, speed = 0.6 })
			end
		end
	end))

	local function assemble()
		bubble.Visible = true
		coreScale.Scale = 0
		for _, plate in ipairs(plates) do
			plate.holder.Position = UDim2.new(0.5, plate.dx * 38, 0.5, plate.dy * 38)
			for _, seg in ipairs(plate.segs) do
				seg.BackgroundTransparency = 1
				seg.BackgroundColor3 = Theme.Cyan
			end
		end
		setPlates(0, 0, Theme.Cyan, 0.6)
		tween(coreScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(0.45, function()
			local c = centerOf(bubble)
			fx.ring(c.X, c.Y, Theme.Cyan, 80)
			fx.spark(c.X, c.Y, 30, { speed = 1.3 })
		end)
	end

	local minimized = false
	local function minimize()
		if minimized or not window._ready then
			return
		end
		minimized = true
		window._fire(600, 14)
		local c = centerOf(root)
		fx.ring(c.X, c.Y, Theme.Light, 140)
		tween(animScale, 0.55, { Scale = 0.05 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(anim, 0.55, { Rotation = 200, GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.52, function()
			root.Visible = false
			window._visible = false
			bubble.Position = UDim2.fromOffset(c.X, c.Y)
			assemble()
		end)
	end

	local function restore()
		if not minimized then
			return
		end
		minimized = false
		hovered = false
		local c = centerOf(bubble)
		setPlates(38, 1, Theme.Cyan, 0.35, Enum.EasingStyle.Quint)
		tween(coreScale, 0.35, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		fx.spark(c.X, c.Y, 34, { speed = 1.5 })
		fx.ring(c.X, c.Y, Color3.new(1, 1, 1), 90)
		task.delay(0.38, function()
			bubble.Visible = false
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or viewport
			local hw, hh = W * baseScale / 2, H * baseScale / 2
			root.Position = UDim2.fromOffset(math.clamp(c.X, hw, math.max(hw, vp.X - hw)), math.clamp(c.Y, hh, math.max(hh, vp.Y - hh)))
			animScale.Scale = 0.05
			anim.Rotation = 200
			anim.GroupTransparency = 1
			root.Visible = true
			window._visible = true
			tween(animScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(anim, 0.6, { Rotation = 0, GroupTransparency = 0 })
			task.delay(0.26, function()
				window._fire(600, 14)
			end)
		end)
	end

	minimizeButton.Activated:Connect(minimize)
	closeButton.Activated:Connect(function()
		window:Destroy()
	end)

	makeDraggable(dragHandle, root, connections)
	makeDraggable(bubbleButton, bubble, connections, restore, function()
		local c = centerOf(bubble)
		fx.spark(c.X, c.Y, 1, { speed = 0.4 })
	end)

	local function runBoot()
		local messages = { { 0, "SINCRONIZANDO NUCLEO" }, { 20, "CARGANDO ESCUDOS" }, { 42, "ARMANDO MODULOS" }, { 64, "CALIBRANDO SENSORES" }, { 86, "ENLACE ESTABLECIDO" } }
		local paused, fired = { [38] = false, [80] = false }, { [25] = false, [50] = false, [75] = false }
		local p, litCount = 0, 0

		task.spawn(function()
			while bootF.Visible and gui.Parent do
				task.wait(rand(0.8, 2))
				if not bootF.Visible then
					break
				end
				bootTitle.Position = UDim2.fromOffset(rand(-5, 5), 172)
				bootTitle.TextColor3 = Color3.fromRGB(255, 80, 255)
				task.wait(0.06)
				bootTitle.Position = UDim2.fromOffset(0, 172)
				bootTitle.TextColor3 = Theme.Text
			end
		end)

		while p < 100 do
			p = math.min(100, p + rand(0.8, 3.4))
			local lit = math.floor(p / 100 * 24)
			while litCount < lit do
				litCount += 1
				segs[litCount].BackgroundColor3 = Theme.Accent:Lerp(Theme.Cyan, litCount / 24)
			end
			pctLabel.Text = string.format("%03d%%", math.floor(p))
			for i = #messages, 1, -1 do
				if p >= messages[i][1] then
					logLabel.Text = "> " .. messages[i][2] .. " ..."
					break
				end
			end
			for threshold, done in pairs(fired) do
				if p >= threshold and not done then
					fired[threshold] = true
					window._fire(380, 7)
					local c = centerOf(root)
					fx.ring(c.X, c.Y - 40, Theme.Cyan, 70)
				end
			end
			for threshold, done in pairs(paused) do
				if p >= threshold and not done then
					paused[threshold] = true
					task.wait(0.3)
				end
			end
			task.wait(0.036)
		end

		flash.BackgroundTransparency = 0.1
		tween(flash, 0.6, { BackgroundTransparency = 1 })
		local c = centerOf(root)
		fx.spark(c.X, c.Y, 70, { speed = 1.8 })
		fx.ring(c.X, c.Y, Color3.new(1, 1, 1), 160)
		fx.ring(c.X, c.Y, Theme.Light, 110)
		window._fire(700, 14)

		tween(bootF, 0.6, { GroupTransparency = 1 })
		tween(bootScale, 0.6, { Scale = 1.2 })
		main.Visible = true
		header.Position = UDim2.fromOffset(0, -30)
		tween(header, 0.6, { Position = UDim2.fromOffset(0, 8) }, Enum.EasingStyle.Back)
		tabBar.Position = UDim2.fromOffset(-60, 66)
		tween(tabBar, 0.6, { Position = UDim2.fromOffset(18, 66) })
		window._ready = true
		if window._active then
			window._active:_enter()
		end
		task.wait(0.65)
		bootF.Visible = false
	end

	local function openSeq()
		window._visible = true
		for _, edge in ipairs(window._edges) do
			edge.Size = UDim2.fromOffset(0, 2)
		end
		root.Visible = true
		animScale.Scale = 1
		anim.Rotation = 0
		anim.GroupTransparency = 0
		bootF.GroupTransparency = 0
		bootScale.Scale = 1
		bootF.Visible = true

		for i, edge in ipairs(window._edges) do
			task.delay((i - 1) * 0.06, function()
				tween(edge, 0.9, { Size = UDim2.fromOffset(edge:GetAttribute("Len"), 2) })
			end)
		end
		task.wait(0.3)
		tween(body, 0.45, { Size = UDim2.fromOffset(W, 2) })
		local c = centerOf(root)
		fx.spark(c.X, c.Y, 18, { a = 0, s = 0.1, speed = 2 })
		fx.spark(c.X, c.Y, 18, { a = math.pi, s = 0.1, speed = 2 })
		task.wait(0.5)
		window._fire(500, 10)
		tween(body, 0.65, { Size = UDim2.fromOffset(W, H) })
		task.wait(0.7)
		runBoot()
	end

	task.spawn(openSeq)

	return window
end

return UI_Library
