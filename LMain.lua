--// Main.lua - Froggy Hub | Elemental Magic Arena (Pond Edition + Attack All)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- ==========================================
-- 1. CARGAMOS DISEÑO Y ASSETS
-- ==========================================
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua"))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua"))()

-- 2. CREAMOS LA VENTANA
local Window = UI_Library.CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "Elemental Arena | Attack All Update"
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
-- 4. DESCARGA DE MÓDULOS (Con Diagnóstico)
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)
    
    if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then 
            local runOk, runErr = pcall(fn)
            if not runOk then
                warn("❌ Error al ejecutar " .. name .. ": " .. tostring(runErr))
                Assets.Notify({Title = "Error de Módulo", Text = name .. " falló. Revisa la consola.", Type = "danger", Duration = 10})
            end
        else
            warn("❌ Error de sintaxis en " .. name .. ": " .. tostring(fn))
            Assets.Notify({Title = "Error de Sintaxis", Text = name .. " tiene un error.", Type = "danger", Duration = 10})
        end
    else
        warn("❌ No se pudo descargar " .. name)
        Assets.Notify({Title = "Error 404", Text = "No se encontró " .. name, Type = "danger", Duration = 10})
    end
    
    task.wait(0.1)
    return env[key] or _G[key]
end

-- Descargamos todos los módulos
local CombC = download("AutoCombat.lua", "BF_COMBAT_CONFIG")
local EspC = download("EspElemental.lua", "BF_ESP_CONFIG")
local HitC = download("HitboxExpander.lua", "BF_HITBOX_CONFIG")
local MoveC = download("Movement.lua", "BF_MOVE_CONFIG")
local WaveCandyC = download("WaveCandyFarm.lua", "BF_WAVEFARM_CONFIG")
local AttackAllC = download("AttackAll.lua", "BF_ATTACKALL_CONFIG")

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
    TabCombat:AddSlider("DELAY M1", 0.1, 1.0, CombC.M1Delay or 0.3, function(val)
        CombC.M1Delay = val
    end)
end

local hitboxSlider = nil
if HitC then
    TabCombat:AddToggle("HITBOX EXPANDER (35 STUDS)", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)

    -- El slider se crea oculto
    hitboxSlider = TabCombat:AddSliderEx("TAMAÑO DE HITBOX (PELIGRO)", 35, 500, 35, function(val)
        HitC.Size = val
    end, "lily")
    
    if hitboxSlider and hitboxSlider.Instance then
        hitboxSlider.Instance.Visible = false 
    end
end

-- 🔥 SECCIÓN DEL NUEVO MÓDULO ATTACK ALL
if AttackAllC then
    TabCombat:AddSection("MODO DIOS")
    
    TabCombat:AddToggle("ATTACK ALL (GUADAÑA)", AttackAllC.Enabled, function(state)
        AttackAllC.Enabled = state
        if state then
            Assets.Notify({
                Title = "ATTACK ALL ACTIVADO", 
                Text = "Equipa la Guadaña de Energía para el daño masivo.", 
                Type = "warn",
                Duration = 5
            })
        end
    end)
    
    TabCombat:AddInfo("¡IMPORTANTE! Solo funciona con la Guadaña del elemento ENERGÍA. Otras armas no harán el combo masivo.", "danger")
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
    
    TabAutoFarm:AddSlider("RADIO DE CARAMELOS", 100, 2000, WaveCandyC.CandyRadius or 500, function(val)
        WaveCandyC.CandyRadius = val
    end)

    TabAutoFarm:AddSection("SELECCIÓN DE ELEMENTO")
    local elementos = {"Light", "Fire", "Water", "Grass", "Earth", "Air", "Dark", "Energy"}
    
    TabAutoFarm:AddDropdown("ELEMENTO A EQUIPAR", elementos, WaveCandyC.SelectedElement or "Light", function(val)
        WaveCandyC.SelectedElement = val
        Assets.Notify({Title = "Elemento Guardado", Text = "Al morir irás a la placa: " .. val, Type = "success", Duration = 3})
    end)
end

-- === PESTAÑA CONFIG (ZONA DEVELOPER) ===
TabConfig:AddSection("ZONA DE DESARROLLADOR")

local passBox = TabConfig:AddTextBox("CONTRASEÑA DE PRUEBAS", "Clave de desarrollador...", function() end, { ClearButton = true })

local unlockBtn = TabConfig:AddButtonEx("DESBLOQUEAR PRUEBA", function()
    if passBox:Get() == "froggy_testing_2026" then
        Assets.Notify({Title = "Modo Pruebas Activado", Text = "Ve a la pestaña COMBATE para ver el slider.", Type = "warn"})
        passBox.Instance.Visible = false
        if unlockBtn and unlockBtn.Instance then unlockBtn.Instance.Visible = false end
        if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = true end
    else
        Assets.Notify({Title = "Acceso Denegado", Text = "Clave de pruebas incorrecta.", Type = "danger"})
        passBox:Set("")
    end
end, "wood", "md")

TabConfig:AddButton("DESTRUIR UI", function()
    Window:Destroy()
end)

print("[Main] Froggy Hub (Attack All Update) cargado con éxito.")
