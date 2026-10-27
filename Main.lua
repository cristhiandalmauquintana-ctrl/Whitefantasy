--// Main.lua - Froggy Hub | Elemental Magic Arena (Pond Edition + Assets)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 1. CARGAMOS EL DISEÑO Y LOS ASSETS
local designUrl = ROOT .. "design.lua"
local UI_Library = loadstring(game:HttpGet(designUrl))()

local assetsUrl = ROOT .. "assets.lua"
local Assets = loadstring(game:HttpGet(assetsUrl))()

-- 2. CREAMOS LA VENTANA PRINCIPAL
local Window = UI_Library.CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "Elemental Arena | Pond Edition"
})

-- Extendemos la ventana con los nuevos componentes (Textbox, Notify, etc.)
Assets.Extend(Window)

-- 3. CREAMOS LAS PESTAÑAS
local TabMain = Window:CreateTab("MAIN")
local TabCombat = Window:CreateTab("COMBATE")
local TabVisual = Window:CreateTab("VISUAL")
local TabMovement = Window:CreateTab("MOVEMENT")
local TabAutoFarm = Window:CreateTab("AUTO FARM")
local TabConfig = Window:CreateTab("CONFIG")

-- ==========================================
-- 4. DETECCIÓN Y DESCARGA DE MÓDULOS
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(names, key)
    for _, n in ipairs(names) do
        local url = ROOT .. folder .. n .. "?v=" .. os.time()
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
            local fnOk, fn = pcall(loadstring, res)
            if fnOk and type(fn) == "function" then pcall(fn) end
        end
    end
    task.wait(0.1)
    return env[key] or _G[key]
end

-- Descargamos los módulos
local EspC = download({"EspElemental.lua"}, "BF_ESP_CONFIG")
local MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
local HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
local CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")
local CamC = download({"Camlock.lua"}, "BF_CAM_CONFIG")
local KillC = download({"NearestKill.lua"}, "BF_KILL_CONFIG")
local WaveCandyC = download({"WaveCandyFarm.lua"}, "BF_WAVEFARM_CONFIG")

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES
-- ==========================================

-- === PESTAÑA MAIN ===
TabMain:AddButton("REJOIN SERVER", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

if KillC then
    TabMain:AddToggle("NEAREST KILL (BOTÓN FLOTANTE)", KillC.Enabled, function(state)
        KillC.Enabled = state
    end)
end

-- === PESTAÑA COMBATE ===
if CombC then
    TabCombat:AddToggle("AUTO COMBAT (M1/SKILLS)", CombC.Enabled, function(state)
        CombC.Enabled = state
    end)
    TabCombat:AddSlider("DELAY M1", 0.1, 1.0, CombC.M1Delay, function(val)
        CombC.M1Delay = val
    end)
end

if CamC then
    TabCombat:AddToggle("CAMLOCK", CamC.Enabled, function(state)
        CamC.Enabled = state
    end)
    TabCombat:AddSlider("FOV DEL CAMLOCK", 50, 600, CamC.FOV, function(val)
        CamC.FOV = val
    end)
end

-- === SECCIÓN HITBOX (NORMAL + BETA) ===
if HitC then
    -- 1. El botón normal (Seguro para todos)
    TabCombat:AddToggle("HITBOX EXPANDER (35 STUDS)", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)

    -- 2. Separador visual para la zona de pruebas
    TabCombat:AddSection("HITBOX EXPERIMENTAL (BETA)")

    -- 3. Caja de texto para la contraseña
    local passBox = TabCombat:AddTextBox("CONTRASEÑA DE PRUEBAS", "Clave de desarrollador...", function() end, { ClearButton = true })
    
    -- 4. Botón para verificar
    local unlockBtn = TabCombat:AddButtonEx("DESBLOQUEAR PRUEBA", function()
        -- 🔑 AQUÍ PONES TU CONTRASEÑA SECRETA:
        if passBox:Get() == "froggy_testing_2026" then
            Assets.Notify({Title = "Modo Pruebas Activado", Text = "Cuidado, el tamaño excesivo puede causar lag.", Type = "warn"})
            -- Ocultamos la caja y el botón
            passBox.Instance.Visible = false
            unlockBtn.Instance.Visible = false
            -- Mostramos el slider
            hitboxSlider.Instance.Visible = true
        else
            Assets.Notify({Title = "Acceso Denegado", Text = "Clave de pruebas incorrecta.", Type = "danger"})
            passBox:Set("")
        end
    end, "wood", "md")

    -- 5. El Slider gigante (Oculto por defecto)
    local hitboxSlider = TabCombat:AddSliderEx("TAMAÑO DE HITBOX (PELIGRO)", 35, 500, 35, function(val)
        HitC.Size = val
    end, "lily")
    
    -- Ocultamos el slider al iniciar
    hitboxSlider.Instance.Visible = false 
end

-- === PESTAÑA VISUAL ===
if EspC then
    TabVisual:AddToggle("ESP JUGADORES", EspC.Enabled, function(state)
        EspC.Enabled = state
    end)
end

-- === PESTAÑA MOVEMENT ===
if MoveC then
    TabMovement:AddToggle("SPEED HACK", MoveC.SpeedEnabled, function(state)
        MoveC.SpeedEnabled = state
    end)
    TabMovement:AddSlider("VELOCIDAD", 16, 200, MoveC.Speed or 60, function(val)
        MoveC.Speed = val
    end)
    TabMovement:AddToggle("SUPER JUMP", MoveC.JumpEnabled, function(state)
        MoveC.JumpEnabled = state
    end)
    TabMovement:AddSlider("ALTURA DE JUMP", 50, 300, MoveC.JumpPower or 100, function(val)
        MoveC.JumpPower = val
    end)
end

-- === PESTAÑA AUTO FARM ===
if WaveCandyC then
    local toggleHalloween
    
    toggleHalloween = TabAutoFarm:AddToggle("AUTOFARM HALLOWEEN EVENT", WaveCandyC.Enabled, function(state)
        WaveCandyC.Enabled = state
        -- Si se activa el evento, forzamos el Hitbox normal
        if state and HitC then
            HitC.Enabled = true 
        end
    end)
    
    TabAutoFarm:AddSlider("RADIO DE CARAMELOS", 100, 2000, WaveCandyC.CandyRadius, function(val)
        WaveCandyC.CandyRadius = val
    end)
end

-- === PESTAÑA CONFIG ===
TabConfig:AddButton("DESTRUIR UI", function()
    Window:Destroy()
end)

print("[Main] Froggy Hub (Pond Edition) cargado con éxito en Elemental Arena.")
