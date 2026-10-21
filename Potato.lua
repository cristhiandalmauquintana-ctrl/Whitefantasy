--// Froggy Hub - Gráficos patata (optimización)
--// Reduce efectos, sombras, texturas y partículas. Se puede revertir al apagarlo.

local Lighting = game:GetService("Lighting")

local env = (getgenv and getgenv()) or _G
if env.__BF_POTATO_CLEANUP then
    pcall(env.__BF_POTATO_CLEANUP)
end

local Potato = {
    Enabled = false,
    NoParticles = true,   -- partículas, estelas, humo, fuego (quita casi todos los efectos de habilidades)
    NoTextures = true,    -- decals y texturas invisibles
    FlatMaterials = true, -- todo en SmoothPlastic, sin reflejos ni sombras
    NoPostFX = true,      -- blur, bloom, rayos de sol, atmósfera
    LowWater = true,      -- agua sin olas ni reflejos
}
env.BF_POTATO = Potato

--==================== Guardado de valores originales ====================
local original = setmetatable({}, { __mode = "k" }) -- [instancia] = { prop = valorOriginal }
local touched = {}                                  -- lista de instancias tocadas
local savedQuality = nil
local generation = 0                                -- se incrementa al activar/desactivar
local addedConn = nil

local function setProp(inst, prop, value)
    local ok, current = pcall(function() return inst[prop] end)
    if not ok then return end
    local rec = original[inst]
    if not rec then
        rec = {}
        original[inst] = rec
        table.insert(touched, inst)
    end
    if rec[prop] == nil then rec[prop] = current end
    pcall(function() inst[prop] = value end)
end

local EFFECT_CLASSES = {
    ParticleEmitter = true, Trail = true, Beam = true,
    Smoke = true, Fire = true, Sparkles = true,
}
local POST_CLASSES = {
    BlurEffect = true, BloomEffect = true, SunRaysEffect = true,
    ColorCorrectionEffect = true, DepthOfFieldEffect = true,
}

local function process(inst)
    if Potato.NoParticles and EFFECT_CLASSES[inst.ClassName] then
        setProp(inst, "Enabled", false)
    elseif Potato.NoTextures and (inst:IsA("Decal") or inst:IsA("Texture")) then
        setProp(inst, "Transparency", 1)
    elseif Potato.FlatMaterials and inst:IsA("BasePart") and not inst:IsA("Terrain") then
        setProp(inst, "Material", Enum.Material.SmoothPlastic)
        setProp(inst, "Reflectance", 0)
        setProp(inst, "CastShadow", false)
    elseif Potato.NoPostFX and POST_CLASSES[inst.ClassName] then
        setProp(inst, "Enabled", false)
    elseif Potato.NoPostFX and inst:IsA("Atmosphere") then
        setProp(inst, "Density", 0)
        setProp(inst, "Haze", 0)
    end
end

local function applyGlobal()
    -- iluminación
    setProp(Lighting, "GlobalShadows", false)

    -- agua
    if Potato.LowWater then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            setProp(terrain, "WaterWaveSize", 0)
            setProp(terrain, "WaterWaveSpeed", 0)
            setProp(terrain, "WaterReflectance", 0)
        end
    end

    -- nivel de calidad gráfica de Roblox
    pcall(function()
        local rendering = settings().Rendering
        if savedQuality == nil then savedQuality = rendering.QualityLevel end
        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function enable()
    generation = generation + 1
    local myGen = generation

    applyGlobal()

    -- cosas que aparezcan después (islas nuevas, habilidades, etc.)
    if addedConn then addedConn:Disconnect() end
    addedConn = workspace.DescendantAdded:Connect(function(inst)
        if Potato.Enabled and generation == myGen then
            process(inst)
        end
    end)

    -- todo lo que ya existe, en bloques para no congelar el juego
    task.spawn(function()
        for _, inst in ipairs(Lighting:GetDescendants()) do process(inst) end

        local count = 0
        for _, inst in ipairs(workspace:GetDescendants()) do
            if generation ~= myGen or not Potato.Enabled then return end
            process(inst)
            count = count + 1
            if count % 400 == 0 then task.wait() end
        end
    end)
end

local function disable()
    generation = generation + 1
    if addedConn then addedConn:Disconnect() addedConn = nil end

    for _, inst in ipairs(touched) do
        local rec = original[inst]
        if rec and inst.Parent then
            for prop, value in pairs(rec) do
                pcall(function() inst[prop] = value end)
            end
        end
    end
    table.clear(touched)
    original = setmetatable({}, { __mode = "k" })

    if savedQuality ~= nil then
        pcall(function() settings().Rendering.QualityLevel = savedQuality end)
        savedQuality = nil
    end
end

--// El panel llama a esto al pulsar el toggle
function Potato.Set(value)
    value = value and true or false
    if value == Potato.Enabled then return end
    Potato.Enabled = value
    if value then enable() else disable() end
end

env.__BF_POTATO_CLEANUP = function()
    Potato.Enabled = false
    disable()
    env.BF_POTATO = nil
    env.__BF_POTATO_CLEANUP = nil
end
