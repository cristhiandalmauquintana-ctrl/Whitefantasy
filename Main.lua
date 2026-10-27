--// Main.lua - Froggy Hub | Elemental Magic Arena (Pond Edition Final)
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

Assets.Extend(Window)

-- 3. CREAMOS LAS PESTAÑAS
local TabMain = Window:CreateTab("MAIN")
local TabCombat = Window:CreateTab("COMBATE")
local TabVisual = Window:CreateTab("VISUAL")
local TabMovement = Window:CreateTab("MOVEMENT")
local TabAutoFarm = Window:CreateTab("AUTO FARM")
local TabConfig = Window:CreateTab("CONFIG")

-- ==========================================
-- 4. DESCARGA DE MÓDULOS
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then pcall(fn) end
    end
    task.wait(0.1)
    return env[key] or _G[key]
end

local CombC = download("AutoCombat.lua", "BF_COMBAT_CONFIG")
local EspC = download("EspElemental.lua", "BF_ESP_CONFIG")
local HitC = download("HitboxExpander.lua", "BF_HITBOX_CONFIG")
local MoveC = download("Movement.lua", "BF_MOVE_CONFIG")
local WaveCandyC = download("WaveCandyFarm.lua", "BF_WAVEFARM_CONFIG")

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES A LA UI
-- ==========================================

-- === PESTAÑA MAIN ===
TabMain:AddButton("REJOIN SERVER", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- === PESTAÑA COMBATE ===
if CombC then
    TabCombat:AddToggle("AUTO COMBAT (M1/SKILLS)", CombC.Enabled, function(state)
        CombC.Enabled = state
    end)
    TabCombat:AddSlider("DELAY M1", 0.1, 1.0, CombC.M1Delay, function(val)
        CombC.M1Delay = val
    end)
end

-- Variable global para que la Config pueda activar el slider
local hitboxSlider = nil

if HitC then
    TabCombat:AddToggle("HITBOX EXPANDER (35 STUDS)", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)

    -- El slider se crea aquí, pero nace invisible
    hitboxSlider = TabCombat:AddSliderEx("TAMAÑO DE HITBOX (PELIGRO)", 35, 500, 35, function(val)
        HitC.Size = val
    end, "lily")
    
    hitboxSlider.Instance.Visible = false 
end

-- === PESTAÑA VISUAL ===
if EspC then
    TabVisual:AddToggle("ESP JUGADORES", EspC.Enabled, function(state)
        EspC.Enabled = state
    end)
    TabVisual:AddToggle("CAJAS 2D", EspC.Boxes, function(state)
        EspC.Boxes = state
    end)
    TabVisual:AddToggle("TRACERS", EspC.Tracers, function(state)
        EspC.Tracers = state
    end)
    TabVisual:AddToggle("BARRA DE VIDA", EspC.HealthBar, function(state)
        EspC.HealthBar = state
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
    TabMovement:AddSlider("ALTURA DE SALTO", 50, 300, MoveC.JumpPower or 100, function(val)
        MoveC.JumpPower = val
    end)
end

-- === PESTAÑA AUTO FARM ===
if WaveCandyC then
    TabAutoFarm:AddToggle("AUTOFARM HALLOWEEN EVENT", WaveCandyC.Enabled, function(state)
        WaveCandyC.Enabled = state
        if state and HitC then
            HitC.Enabled = true 
        end
    end)
    
    TabAutoFarm:AddSlider("RADIO DE CARAMELOS", 100, 2000, WaveCandyC.CandyRadius, function(val)
        WaveCandyC.CandyRadius = val
    end)
end

-- === PESTAÑA CONFIG (ZONA DEVELOPER) ===
TabConfig:AddSection("ZONA DE DESARROLLADOR")

local passBox = TabConfig:AddTextBox("CONTRASEÑA DE PRUEBAS", "Clave de desarrollador...", function() end, { ClearButton = true })

local unlockBtn = TabConfig:AddButtonEx("DESBLOQUEAR PRUEBA", function()
    -- 🔑 AQUÍ PONES TU CONTRASEÑA SECRETA:
    if passBox:Get() == "froggy_testing_2026" then
        Assets.Notify({Title = "Modo Pruebas Activado", Text = "Ve a la pestaña COMBATE para ver el slider.", Type = "warn"})
        -- Ocultamos la caja y el botón
        passBox.Instance.Visible = false
        unlockBtn.Instance.Visible = false
        -- Mostramos el slider en la pestaña de Combate
        if hitboxSlider then
            hitboxSlider.Instance.Visible = true
        end
    else
        Assets.Notify({Title = "Acceso Denegado", Text = "Clave de pruebas incorrecta.", Type = "danger"})
        passBox:Set("")
    end
end, "wood", "md")

TabConfig:AddButton("DESTRUIR UI", function()
    Window:Destroy()
end)

print("[Main] Froggy Hub cargado. Contraseña de pruebas lista.")
