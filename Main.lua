--// Main.lua - Froggy Hub | UI Épica v21.2 (Auto Farm + Hitbox Sync)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 1. CARGAMOS EL DISEÑO
local designUrl = ROOT .. "design.lua"
local UI_Library = loadstring(game:HttpGet(designUrl))()

-- 2. CREAMOS LA VENTANA
local Window = UI_Library.CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "SYS 0x5EE9"
})

-- 3. CREAMOS LAS PESTAÑAS
local TabMain = Window:CreateTab("MAIN")
local TabVisual = Window:CreateTab("VISUAL")
local TabMovement = Window:CreateTab("MOVEMENT")
local TabAutoFarm = Window:CreateTab("AUTO FARM (BETA)")
local TabConfig = Window:CreateTab("CONFIG")

-- ==========================================
-- 4. DETECCIÓN Y DESCARGA DE MÓDULOS
-- ==========================================
local isBloxFruits = (game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 7449423635)
local folder = isBloxFruits and "" or "ElementalMagicArena/"

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

local EspC, MoveC, HitC, CombC, CamC, AutoFarmC

if isBloxFruits then
    EspC = download({"Esp.lua"}, "BF_ESP_CONFIG")
    MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
    CamC = download({"Camlock.lua"}, "BF_CAM_CONFIG")
else
    EspC = download({"EspElemental.lua"}, "BF_ESP_CONFIG")
    MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
    HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
    CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")
    AutoFarmC = download({"AutoFarm.lua"}, "BF_AUTOFARM_CONFIG")
end

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES A LA LÓGICA
-- ==========================================

-- === PESTAÑA MAIN ===
TabMain:AddButton("REJOIN SERVER", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Guardamos la referencia al botón del Hitbox para poder activarlo desde el Auto Farm
local HitboxUI = nil
if HitC then
    HitboxUI = TabMain:AddToggle("HITBOX EXPANDER", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)
end

if CombC then
    TabMain:AddToggle("AUTO COMBAT", CombC.Enabled, function(state)
        CombC.Enabled = state
    end)
end

-- === PESTAÑA AUTO FARM (BETA) ===
if AutoFarmC then
    TabAutoFarm:AddButton("⚠️ ADVERTENCIA: FUNCIÓN EN BETA", function() end)
    
    TabAutoFarm:AddToggle("KAMIKAZE FARM (BETA)", AutoFarmC.Enabled, function(state)
        AutoFarmC.Enabled = state
        
        -- 🔥 LÓGICA DE SINCRONIZACIÓN: Si el Farm se activa, forzamos el Hitbox
        if state then
            if HitC and HitboxUI then
                HitC.Enabled = true
                HitboxUI:Set(true) -- Actualiza el botón visual en la pestaña MAIN
                print("[Auto Farm] Hitbox activado automáticamente.")
            end
        end
    end)
    
    TabAutoFarm:AddToggle("AUTO-EQUIPAR ARMA (BETA)", AutoFarmC.AutoEquip, function(state)
        AutoFarmC.AutoEquip = state
    end)
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
    
    TabMovement:AddSlider("ALTURA DE SALTO", 50, 300, MoveC.JumpPower or 100, function(val)
        MoveC.JumpPower = val
    end)
end

-- === PESTAÑA CONFIG ===
TabConfig:AddButton("DESTRUIR UI", function()
    Window:Destroy()
end)

print("[Main] Hub cargado con éxito. Pestaña Auto Farm conectada al Hitbox.")
