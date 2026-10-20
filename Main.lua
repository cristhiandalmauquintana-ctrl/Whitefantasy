--[[
  WhiteFantasyCycle.lua
  Pegalo como LocalScript en StarterPlayer > StarterPlayerScripts.
  Requiere que WhiteFantasy.lua (v2) siga en ServerScriptService,
  porque este script ajusta los efectos WF_* que ese script crea.

  Hace: ciclo dia/noche suave, agua pastel y audio ambiental.
  Todos los jugadores ven la misma hora (usa la hora del servidor).
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- ============ AJUSTES ============
local CONFIG = {
	DayLengthSeconds = 600, -- duracion de un dia completo (600 = 10 minutos)
	StartHour = 12,         -- hora a la que empieza el juego

	-- Audio
	AmbientReverb = Enum.ReverbType.NoReverb, -- eco del mundo (NoReverb = sin eco; Forest/Hall = con eco)
	MusicReverb = false,    -- true = eco suave extra solo en la musica
	-- Lista de canciones (pon tus IDs). Vacia = sin musica.
	Playlist = {
		"rbxassetid://125199645515200",
		-- "rbxassetid://987654321",
	},
	Shuffle = true,          -- true = orden aleatorio, false = en orden
	MusicVolume = 0.35,
	FadeInSeconds = 4,       -- cuanto tarda en subir el volumen al empezar
	FadeOutSeconds = 5,      -- cuanto tarda en bajar el volumen al terminar
	GapSeconds = 2,          -- silencio entre una cancion y la siguiente
	NightVolume = 0.6,       -- multiplicador del volumen de noche (1 = igual que de dia)

	-- Graficos
	MaxGraphics = true,      -- true = calidad al maximo y todo el mapa en detalle completo

	-- Particulas y clima (todo del lado del cliente)
	FantasyParticles = true, -- luces flotantes de fantasia (mas visibles de noche)
	RainEnabled = true,      -- lluvia aleatoria con niebla
	RainClearMin = 120,      -- segundos de cielo despejado antes de la proxima lluvia (minimo)
	RainClearMax = 420,      -- ... (maximo)
	RainDurationMin = 60,    -- duracion de la lluvia en segundos (minimo)
	RainDurationMax = 180,   -- ... (maximo)
	FirstRainDelayMin = 20,  -- espera antes de la primera lluvia posible (minimo)
	FirstRainDelayMax = 90,  -- ... (maximo)
	RainSoundId = "",        -- "rbxassetid://..." con sonido de lluvia (vacio = sin sonido)
	RainVolume = 0.6,        -- volumen maximo del sonido de lluvia
}
-- =================================

-- Graficos al maximo (solo afecta al jugador local)
if CONFIG.MaxGraphics then
	local ok1, err1 = pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
	end)
	local ok2, err2 = pcall(function()
		local ugs = UserSettings():GetService("UserGameSettings")
		ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel10
	end)
	print("WhiteFantasyCycle: calidad Rendering =", ok1 and "ok" or tostring(err1), "| Guardada =", ok2 and "ok" or tostring(err2))
	Lighting.GlobalShadows = true

	-- Detalle completo a cualquier distancia (sin bajar la calidad de modelos lejanos)
	local function maxDetail(inst)
		if inst:IsA("Model") then
			inst.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
		elseif inst:IsA("MeshPart") then
			inst.RenderFidelity = Enum.RenderFidelity.Precise
		end
	end
	task.spawn(function()
		for i, inst in ipairs(workspace:GetDescendants()) do
			pcall(maxDetail, inst)
			if i % 500 == 0 then
				task.wait() -- evita tirones en mapas grandes
			end
		end
	end)
	workspace.DescendantAdded:Connect(function(inst)
		pcall(maxDetail, inst)
	end)
end

-- ============ PANEL DE ACTUALIZACION ============
local UPDATE_TITLE = "Novedades de la actualización"
local UPDATE_NOTES = {
	"Nueva música ambiental.",
	"Gráficos al máximo para ver todo el mapa en detalle.",
	"Luces y orbes flotantes de fantasía.",
	"Lluvia aleatoria con niebla y cielo nublado.",
	"Nuevo panel de novedades (cierra con la X).",
}

task.spawn(function()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "WF_UpdatePanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(340, 230)
	panel.BackgroundColor3 = Color3.fromRGB(245, 240, 255)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(200, 185, 235)
	stroke.Thickness = 2

	-- Evita que el panel se salga en pantallas pequeñas
	local limit = Instance.new("UISizeConstraint", panel)
	limit.MaxSize = Vector2.new(340, 230)
	limit.MinSize = Vector2.new(200, 140)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -60, 0, 30)
	title.Font = Enum.Font.GothamBold
	title.Text = UPDATE_TITLE
	title.TextColor3 = Color3.fromRGB(90, 70, 130)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(16, 48)
	body.Size = UDim2.new(1, -32, 1, -60)
	body.Font = Enum.Font.Gotham
	body.TextSize = 15
	body.TextColor3 = Color3.fromRGB(70, 60, 95)
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	local lines = {}
	for _, note in ipairs(UPDATE_NOTES) do
		table.insert(lines, "• " .. note)
	end
	body.Text = table.concat(lines, "\n\n")
	body.Parent = panel

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(28, 28)
	close.BackgroundColor3 = Color3.fromRGB(225, 205, 240)
	close.Font = Enum.Font.GothamBold
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(90, 70, 130)
	close.TextSize = 16
	close.AutoButtonColor = true
	close.Parent = panel
	Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

	close.Activated:Connect(function()
		gui:Destroy()
	end)
end)
-- ================================================

-- Si WhiteFantasy.lua no creo los efectos, se crean aqui (asi el script
-- nunca se detiene antes de llegar a la musica).
local function getEffect(name, class)
	local e = Lighting:WaitForChild(name, 5)
	if not e then
		warn("WhiteFantasyCycle: no se encontro " .. name .. ", creandolo (falta WhiteFantasy.lua en ServerScriptService?)")
		e = Instance.new(class)
		e.Name = name
		e.Parent = Lighting
	end
	return e
end
local atmosphere = getEffect("WF_Atmosphere", "Atmosphere")
local cc = getEffect("WF_ColorCorrection", "ColorCorrectionEffect")
local bloom = getEffect("WF_Bloom", "BloomEffect")

local terrain = workspace:WaitForChild("Terrain")

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Puntos clave del dia (hora 0 y 24 son iguales para que el ciclo cierre)
local NIGHT = {
	ambient = rgb(70, 70, 110), outdoor = rgb(80, 85, 130), brightness = 0.6,
	tint = rgb(215, 225, 255), atmoColor = rgb(170, 180, 230),
	density = 0.3, haze = 1.2, saturation = -0.15, bloom = 0.45,
	water = rgb(110, 130, 190), reflect = 0.3,
}
local KEYS = {
	{ t = 0, k = NIGHT },
	{ t = 6, k = {
		ambient = rgb(170, 150, 170), outdoor = rgb(200, 170, 190), brightness = 1.5,
		tint = rgb(255, 225, 235), atmoColor = rgb(255, 215, 225),
		density = 0.4, haze = 1.5, saturation = -0.15, bloom = 0.35,
		water = rgb(200, 190, 225), reflect = 0.45,
	} },
	{ t = 12, k = {
		ambient = rgb(150, 150, 175), outdoor = rgb(170, 170, 195), brightness = 2,
		tint = rgb(255, 245, 255), atmoColor = rgb(240, 240, 255),
		density = 0.35, haze = 1, saturation = -0.2, bloom = 0.35,
		water = rgb(170, 225, 235), reflect = 0.55,
	} },
	{ t = 18, k = {
		ambient = rgb(170, 140, 160), outdoor = rgb(200, 150, 170), brightness = 1.4,
		tint = rgb(255, 230, 215), atmoColor = rgb(255, 200, 190),
		density = 0.4, haze = 1.6, saturation = -0.1, bloom = 0.35,
		water = rgb(220, 180, 200), reflect = 0.5,
	} },
	{ t = 24, k = NIGHT },
}

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function sample(hour)
	for i = 1, #KEYS - 1 do
		local a, b = KEYS[i], KEYS[i + 1]
		if hour >= a.t and hour <= b.t then
			local alpha = (hour - a.t) / (b.t - a.t)
			alpha = alpha * alpha * (3 - 2 * alpha) -- transicion suave
			return a.k, b.k, alpha
		end
	end
	return NIGHT, NIGHT, 0
end

-- Agua pastel (valores fijos; el color cambia con la hora)
terrain.WaterTransparency = 0.6
terrain.WaterWaveSize = 0.15
terrain.WaterWaveSpeed = 8

-- Audio ambiental
SoundService.AmbientReverb = CONFIG.AmbientReverb

local group = Instance.new("SoundGroup")
group.Name = "WF_Music"
group.Volume = 1
group.Parent = SoundService

if CONFIG.MusicReverb then
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 1.5
	reverb.Density = 0.6
	reverb.Diffusion = 0.7
	reverb.DryLevel = 0
	reverb.WetLevel = -14
	reverb.Parent = group
end

-- Reproductor de lista con fundidos suaves
local sound = Instance.new("Sound")
sound.Name = "WF_Music"
sound.Looped = false
sound.Volume = 0
sound.SoundGroup = group
sound.Parent = SoundService

local function waitLoaded()
	local waited = 0
	while not sound.IsLoaded and waited < 10 do
		waited += task.wait(0.2)
	end
	return sound.IsLoaded and sound.TimeLength > 0
end

local function playTrack(id)
	sound:Stop()
	sound.SoundId = id
	sound.Volume = 0
	sound.TimePosition = 0
	if not waitLoaded() then
		warn("WhiteFantasyCycle: no se pudo cargar " .. id .. " (audio privado, sin permiso para este juego, o ID que no es de audio)")
		return
	end
	print("WhiteFantasyCycle: reproduciendo " .. id)

	local length = sound.TimeLength
	local fadeIn = math.min(CONFIG.FadeInSeconds, length / 2)
	local fadeOut = math.min(CONFIG.FadeOutSeconds, length / 2)

	sound:Play()
	TweenService:Create(sound, TweenInfo.new(fadeIn), { Volume = CONFIG.MusicVolume }):Play()

	-- Esperar hasta que toque bajar el volumen
	while sound.IsPlaying and sound.TimePosition < length - fadeOut do
		task.wait(0.25)
	end

	TweenService:Create(sound, TweenInfo.new(fadeOut), { Volume = 0 }):Play()
	while sound.IsPlaying and sound.TimePosition < length - 0.1 do
		task.wait(0.1)
	end

	sound:Stop()
	task.wait(CONFIG.GapSeconds)
end

local function buildOrder(lastId)
	local order = {}
	for _, id in ipairs(CONFIG.Playlist) do
		if id ~= "" then
			table.insert(order, id)
		end
	end
	if CONFIG.Shuffle then
		for i = #order, 2, -1 do
			local j = math.random(i)
			order[i], order[j] = order[j], order[i]
		end
		-- Evitar que la misma cancion suene dos veces seguidas
		if #order > 1 and order[1] == lastId then
			order[1], order[#order] = order[#order], order[1]
		end
	end
	return order
end

task.spawn(function()
	local lastId
	while true do
		local order = buildOrder(lastId)
		if #order == 0 then
			return
		end
		for _, id in ipairs(order) do
			playTrack(id)
			lastId = id
		end
	end
end)

-- ============ PARTICULAS DE FANTASIA Y LLUVIA ============
local rng = Random.new()
local fxFolder = Instance.new("Folder")
fxFolder.Name = "WF_FX"
fxFolder.Parent = workspace

local function makeEmitterPart(name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.Parent = fxFolder
	return p
end

-- Luces flotantes (siguen a la camara)
local motePart = makeEmitterPart("Motes", Vector3.new(90, 30, 90))

local motes = Instance.new("ParticleEmitter")
motes.Name = "Motes"
motes.Shape = Enum.ParticleEmitterShape.Box
motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
motes.Rate = 10
motes.Lifetime = NumberRange.new(7, 11)
motes.Speed = NumberRange.new(0.3, 1.5)
motes.SpreadAngle = Vector2.new(180, 180)
motes.Acceleration = Vector3.new(0, 0.15, 0)
motes.Drag = 0.5
motes.RotSpeed = NumberRange.new(-40, 40)
motes.Rotation = NumberRange.new(0, 360)
motes.LightEmission = 0.9
motes.LightInfluence = 0
motes.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.2, 0.7),
	NumberSequenceKeypoint.new(0.8, 0.5),
	NumberSequenceKeypoint.new(1, 0),
})
motes.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0.15),
	NumberSequenceKeypoint.new(0.8, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
motes.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 200, 230)),
	ColorSequenceKeypoint.new(0.5, rgb(200, 235, 255)),
	ColorSequenceKeypoint.new(1, rgb(225, 205, 255)),
})
motes.Enabled = CONFIG.FantasyParticles
motes.Parent = motePart

-- Orbes grandes y suaves (poco frecuentes)
local orbs = Instance.new("ParticleEmitter")
orbs.Name = "Orbs"
orbs.Shape = Enum.ParticleEmitterShape.Box
orbs.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
orbs.Rate = 2
orbs.Lifetime = NumberRange.new(10, 14)
orbs.Speed = NumberRange.new(0.2, 0.8)
orbs.SpreadAngle = Vector2.new(180, 180)
orbs.Acceleration = Vector3.new(0, 0.1, 0)
orbs.LightEmission = 1
orbs.LightInfluence = 0
orbs.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.5),
	NumberSequenceKeypoint.new(0.5, 1.4),
	NumberSequenceKeypoint.new(1, 0.5),
})
orbs.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.3, 0.7),
	NumberSequenceKeypoint.new(0.7, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})
orbs.Color = ColorSequence.new(rgb(235, 215, 255), rgb(205, 235, 255))
orbs.Enabled = CONFIG.FantasyParticles
orbs.Parent = motePart

-- Lluvia (cae desde arriba de la camara)
local rainPart = makeEmitterPart("Rain", Vector3.new(50, 2, 50))

local rain = Instance.new("ParticleEmitter")
rain.Name = "Rain"
rain.Shape = Enum.ParticleEmitterShape.Box
rain.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.Rate = 0
rain.Lifetime = NumberRange.new(0.28, 0.34)
rain.Speed = NumberRange.new(70, 80)
rain.Acceleration = Vector3.new(-6, 0, 0) -- ligera inclinacion por el viento
rain.Size = NumberSequence.new(0.3)
rain.Transparency = NumberSequence.new(0.3)
rain.Color = ColorSequence.new(rgb(225, 235, 255))
rain.LightEmission = 0.6
rain.LightInfluence = 0
rain.Enabled = false
rain.Parent = rainPart

local rainSound
if CONFIG.RainSoundId ~= "" then
	rainSound = Instance.new("Sound")
	rainSound.Name = "WF_Rain"
	rainSound.SoundId = CONFIG.RainSoundId
	rainSound.Looped = true
	rainSound.Volume = 0
	rainSound.Parent = SoundService
	rainSound:Play()
end

-- Cielo de lluvia: nubes que tapan el sol, sin brillo ni rayos
local clouds = terrain:FindFirstChildOfClass("Clouds")
if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Cover = 0 -- sin nubes cuando esta despejado
	clouds.Density = 0.7
	clouds.Parent = terrain
end
local sky = Lighting:FindFirstChildOfClass("Sky")
if not sky then
	sky = Instance.new("Sky")
	sky.Parent = Lighting
end
local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")

local baseCover, baseCloudDensity, baseCloudColor = clouds.Cover, clouds.Density, clouds.Color
local baseSunSize = sky.SunAngularSize
local baseRays = sunRays and sunRays.Intensity or 0
local baseExposure = Lighting.ExposureCompensation
local baseGlare = atmosphere.Glare
local baseDiffuse = Lighting.EnvironmentDiffuseScale
local baseSpecular = Lighting.EnvironmentSpecularScale

local function applyRainSky(r)
	local k = math.clamp(r * 1.6, 0, 1) -- las nubes cierran el cielo rapido
	clouds.Cover = lerp(baseCover, 0.95, k)
	clouds.Density = lerp(baseCloudDensity, 0.9, k)
	clouds.Color = baseCloudColor:Lerp(rgb(135, 140, 160), k)
	sky.SunAngularSize = lerp(baseSunSize, 0, k) -- se oculta el disco del sol
	if sunRays then
		sunRays.Intensity = lerp(baseRays, 0, k)
	end
	atmosphere.Glare = baseGlare * (1 - k)
	Lighting.ExposureCompensation = baseExposure - 0.5 * r
	Lighting.EnvironmentDiffuseScale = baseDiffuse * (1 - 0.4 * r)
	Lighting.EnvironmentSpecularScale = baseSpecular * (1 - 0.7 * r)
end

-- Clima aleatorio: despejado -> lluvia -> despejado ...
local rainTarget, rainAmount = 0, 0
task.spawn(function()
	if not CONFIG.RainEnabled then
		return
	end
	if CONFIG.RainSoundId == "" then
		print("WhiteFantasyCycle: RainSoundId esta vacio, la lluvia no tendra sonido")
	end
	task.wait(rng:NextNumber(CONFIG.FirstRainDelayMin, CONFIG.FirstRainDelayMax))
	while true do
		rainTarget = rng:NextNumber(0.5, 1) -- intensidad de esta lluvia
		task.wait(rng:NextNumber(CONFIG.RainDurationMin, CONFIG.RainDurationMax))
		rainTarget = 0
		task.wait(rng:NextNumber(CONFIG.RainClearMin, CONFIG.RainClearMax))
	end
end)

local function updateFX(dt, daylight)
	-- Transicion suave de la lluvia (unos segundos al empezar y al terminar)
	rainAmount += (rainTarget - rainAmount) * math.clamp(dt * 0.4, 0, 1)
	if rainTarget == 0 and rainAmount < 0.01 then
		rainAmount = 0
	end

	-- Los emisores siguen a la camara
	local cam = workspace.CurrentCamera
	if cam then
		local pos = cam.CFrame.Position
		motePart.Position = pos
		rainPart.Position = pos + Vector3.new(0, 22, 0)
	end

	-- Mas luces de noche, menos cuando llueve
	local night = 1 - daylight
	local moteFactor = 1 - 0.7 * rainAmount
	motes.Rate = (8 + 14 * night) * moteFactor
	orbs.Rate = (1.5 + 2.5 * night) * moteFactor

	rain.Enabled = rainAmount > 0.02
	rain.Rate = 1200 * rainAmount

	if rainSound then
		rainSound.Volume = CONFIG.RainVolume * rainAmount
	end

	applyRainSky(rainAmount)
end
-- ==========================================================

-- Bucle principal
RunService.Heartbeat:Connect(function(dt)
	local hour = (CONFIG.StartHour + workspace:GetServerTimeNow() * 24 / CONFIG.DayLengthSeconds) % 24
	Lighting.ClockTime = hour

	local a, b, alpha = sample(hour)
	Lighting.Ambient = a.ambient:Lerp(b.ambient, alpha)
	Lighting.OutdoorAmbient = a.outdoor:Lerp(b.outdoor, alpha)
	Lighting.Brightness = lerp(a.brightness, b.brightness, alpha)

	cc.TintColor = a.tint:Lerp(b.tint, alpha)
	cc.Saturation = lerp(a.saturation, b.saturation, alpha)
	atmosphere.Color = a.atmoColor:Lerp(b.atmoColor, alpha)
	atmosphere.Density = lerp(a.density, b.density, alpha)
	atmosphere.Haze = lerp(a.haze, b.haze, alpha)
	bloom.Intensity = lerp(a.bloom, b.bloom, alpha)

	terrain.WaterColor = a.water:Lerp(b.water, alpha)
	terrain.WaterReflectance = lerp(a.reflect, b.reflect, alpha)

	-- Musica: un poco mas baja de noche (no afecta a los fundidos)
	local daylight = (math.cos((hour - 12) / 12 * math.pi) + 1) / 2
	group.Volume = lerp(CONFIG.NightVolume, 1, daylight)

	-- Particulas y lluvia
	updateFX(dt, daylight)

	-- Efecto de lluvia: cielo nublado, mas niebla y colores apagados
	local r = rainAmount
	if r > 0 then
		Lighting.Brightness *= (1 - 0.45 * r)
		Lighting.Ambient = Lighting.Ambient:Lerp(rgb(120, 125, 150), 0.35 * r)
		Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(rgb(125, 130, 155), 0.35 * r)
		cc.Saturation -= 0.1 * r
		cc.TintColor = cc.TintColor:Lerp(rgb(215, 225, 245), 0.4 * r)
		atmosphere.Density += 0.25 * r
		atmosphere.Haze += 2 * r
		atmosphere.Color = atmosphere.Color:Lerp(rgb(185, 192, 215), 0.5 * r)
	end
end)
