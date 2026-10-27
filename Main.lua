--// Main.lua - Froggy Hub | Elemental Magic Arena (Pond Edition Final Fix v3)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 1. DISEÑO Y ASSETS
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua"))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua"))()

-- 2. VENTANA
local Window = UI_Library.CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "Elemental Arena | Pond Edition"
})

pcall(Assets.Extend, Window)

-- 3. PESTAÑAS (cada una se extiende por separado)
local TabMain = Window:CreateTab("MAIN")
local TabCombat = Window:CreateTab("COMBATE")
local TabVisual = Window:CreateTab("VISUAL")
local TabMovement = Window:CreateTab("MOVEMENT")
local TabAutoFarm = Window:CreateTab("AUTO FARM")
local TabConfig = Window:CreateTab("CONFIG")

for _, tab in ipairs({TabMain, TabCombat, TabVisual, TabMovement, TabAutoFarm, TabConfig}) do
    local ok, err = pcall(Assets.Extend, tab)
    if not ok then
        warn("Extend falló en una pestaña: " .. tostring(err))
    end
end

-- Helper: ejecuta una sección sin que un error rompa las demás
local function section(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("❌ Error en sección " .. name .. ": " .. tostring(err))
        Assets.Notify({Title = "Error en " .. name, Text = tostring(err):sub(1, 80), Type = "danger", Duration = 10})
    end
end

-- ==========================================
-- 4. DESCARGA DE MÓDULOS
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, keys)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)

    if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then
            task.spawn(function()
                local runOk, runErr = pcall(fn)
                if not runOk then
                    warn("❌ Error al ejecutar " .. name .. ": " .. tostring(runErr))
                    Assets.Notify({Title = "Error de Módulo", Text = name .. " falló. Revisa la consola.", Type = "danger", Duration = 10})
                end
            end)
        else
            warn("❌ Error de sintaxis en " .. name .. ": " .. tostring(fn))
            Assets.Notify({Title = "Error de Sintaxis", Text = name .. " tiene un error de código.", Type = "danger", Duration = 10})
            return nil
        end
    else
        warn("❌ No se pudo descargar " .. name .. " de GitHub.")
        Assets.Notify({Title = "Error 404", Text = "No se encontró " .. name, Type = "danger", Duration = 10})
        return nil
    end

    local t = 0
    while t < 6 do
        for _, key in ipairs(keys) do
            local cfg = env[key] or _G[key]
            if type(cfg) == "table" then
                print("✅ " .. name .. " -> " .. key)
                return cfg
            end
        end
        task.wait(0.1)
        t = t + 0.1
    end

    warn("⚠️ " .. name .. " cargó pero no creó ninguna de estas variables: " .. table.concat(keys, ", "))
    Assets.Notify({Title = "Config no encontrada", Text = name .. " no definió " .. keys[1], Type = "warn", Duration = 10})
    return nil
end

local CombC      = download("AutoCombat.lua",     {"BF_COMBAT_CONFIG"})
local EspC       = download("EspElemental.lua",   {"BF_ESP_CONFIG", "BF_ESP"})
local HitC       = download("HitboxExpander.lua", {"BF_HITBOX_CONFIG"})
local MoveC      = download("Movement.lua",       {"BF_MOVE_CONFIG", "BF_MOVEMENT_CONFIG", "BF_MOVEMENT"})
local WaveCandyC = download("WaveCandyFarm.lua",  {"BF_WAVEFARM_CONFIG", "BF_WAVECANDY_CONFIG", "BF_WAVEFARM"})

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES A LA UI
-- ==========================================

-- === PESTAÑA MAIN ===
section("MAIN", function()
    TabMain:AddButton("REJOIN SERVER", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end)

-- === PESTAÑA COMBATE ===
local hitboxSlider = nil

section("COMBATE", function()
    if CombC then
        TabCombat:AddToggle("AUTO COMBAT (M1/SKILLS)", CombC.Enabled or false, function(state)
            CombC.Enabled = state
        end)
        TabCombat:AddSlider("DELAY M1", 0.1, 1.0, CombC.M1Delay or 0.3, function(val)
            CombC.M1Delay = val
        end)
    end

    if HitC then
        TabCombat:AddToggle("HITBOX EXPANDER (35 STUDS)", HitC.Enabled or false, function(state)
            HitC.Enabled = state
        end)

        hitboxSlider = TabCombat:AddSliderEx("TAMAÑO DE HITBOX (PELIGRO)", 35, 500, 35, function(val)
            HitC.Size = val
        end, "lily")

        if hitboxSlider and hitboxSlider.Instance then
            hitboxSlider.Instance.Visible = false
        end
    end
end)

-- === PESTAÑA VISUAL ===
section("VISUAL", function()
    if EspC then
        TabVisual:AddToggle("ESP JUGADORES", EspC.Enabled or false, function(state)
            EspC.Enabled = state
        end)
        TabVisual:AddToggle("CAJAS 2D", EspC.Boxes or false, function(state)
            EspC.Boxes = state
        end)
        TabVisual:AddToggle("TRACERS", EspC.Tracers or false, function(state)
            EspC.Tracers = state
        end)
        TabVisual:AddToggle("BARRA DE VIDA", EspC.HealthBar or false, function(state)
            EspC.HealthBar = state
        end)
    else
        TabVisual:AddButton("⚠ MÓDULO ESP NO CARGÓ (ver consola F9)", function() end)
    end
end)

-- === PESTAÑA MOVEMENT ===
section("MOVEMENT", function()
    if MoveC then
        TabMovement:AddToggle("SPEED HACK", MoveC.SpeedEnabled or false, function(state)
            MoveC.SpeedEnabled = state
        end)
        TabMovement:AddSlider("VELOCIDAD", 16, 200, MoveC.Speed or 60, function(val)
            MoveC.Speed = val
        end)

        TabMovement:AddToggle("SUPER JUMP", MoveC.JumpEnabled or false, function(state)
            MoveC.JumpEnabled = state
        end)
        TabMovement:AddSlider("ALTURA DE SALTO", 50, 300, MoveC.JumpPower or 100, function(val)
            MoveC.JumpPower = val
        end)
    else
        TabMovement:AddButton("⚠ MÓDULO MOVEMENT NO CARGÓ (ver consola F9)", function() end)
    end
end)

-- === PESTAÑA AUTO FARM ===
section("AUTO FARM", function()
    if WaveCandyC then
        TabAutoFarm:AddToggle("AUTOFARM HALLOWEEN EVENT", WaveCandyC.Enabled or false, function(state)
            WaveCandyC.Enabled = state
            if state and HitC then
                HitC.Enabled = true
            end
        end)

        TabAutoFarm:AddSlider("RADIO DE CARAMELOS", 100, 2000, WaveCandyC.CandyRadius or 500, function(val)
            WaveCandyC.CandyRadius = val
        end)
    else
        TabAutoFarm:AddButton("⚠ MÓDULO AUTOFARM NO CARGÓ (ver consola F9)", function() end)
    end
end)

-- === PESTAÑA CONFIG (ZONA DEVELOPER) ===
section("CONFIG", function()
    TabConfig:AddSection("ZONA DE DESARROLLADOR")

    local passBox = TabConfig:AddTextBox("CONTRASEÑA DE PRUEBAS", "Clave de desarrollador...", function() end, { ClearButton = true })

    local unlockBtn
    unlockBtn = TabConfig:AddButtonEx("DESBLOQUEAR PRUEBA", function()
        if passBox:Get() == "froggy_testing_2026" then
            Assets.Notify({Title = "Modo Pruebas Activado", Text = "Ve a la pestaña COMBATE para ver el slider.", Type = "warn"})
            passBox.Instance.Visible = false
            if unlockBtn and unlockBtn.Instance then
                unlockBtn.Instance.Visible = false
            end
            if hitboxSlider and hitboxSlider.Instance then
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
end)

print("[Main] Froggy Hub cargado. Módulos listos.")
