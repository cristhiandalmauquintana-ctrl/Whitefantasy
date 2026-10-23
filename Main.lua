--// Main.lua - Froggy Hub | Conectado al Design de Claude
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 1. CARGAMOS EL DISEÑO DE CLAUDE (design.lua)
local designUrl = ROOT .. "design.lua"
local UI_Library = loadstring(game:HttpGet(designUrl))()

-- 2. CREAMOS LA VENTANA CON EL DISEÑO ÉPICO
local Window = UI_Library.CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "SYS 0x5EE9"
})

-- 3. CREAMOS LAS PESTAÑAS (Tabs)
local TabMain = Window:CreateTab("MAIN")
local TabVisual = Window:CreateTab("VISUAL")
local TabConfig = Window:CreateTab("CONFIG")

-- ==========================================
-- 4. LÓGICA DE DETECCIÓN Y CARGA DE MÓDULOS
-- ==========================================
-- Detectamos si el juego es Blox Fruits por su PlaceID
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

-- Descargamos los módulos según el juego
local EspC, MoveC, HitC, CombC, CamC

if isBloxFruits then
    EspC = download({"Esp.lua"}, "BF_ESP_CONFIG")
    MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
    CamC = download({"Camlock.lua"}, "BF_CAM_CONFIG")
else
    EspC = download({"EspElemental.lua"}, "BF_ESP_CONFIG")
    MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
    HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
    CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")
end

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES DEL DISEÑO A LA LÓGICA
-- ==========================================

-- === PESTAÑA MAIN ===
TabMain:AddButton("REJOIN SERVER", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

if CombC then
    TabMain:AddToggle("AUTO COMBAT", CombC.Enabled, function(state)
        CombC.Enabled = state
    end)
end

if CamC then
    TabMain:AddToggle("CAMLOCK (BLOX FRUITS)", CamC.Enabled, function(state)
        CamC.Enabled = state
    end)
end

-- === PESTAÑA VISUAL ===
if EspC then
    TabVisual:AddToggle("ESP JUGADORES", EspC.Enabled, function(state)
        EspC.Enabled = state
    end)
end

if HitC then
    TabVisual:AddToggle("HITBOX EXPANDER (35)", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)
end

if MoveC then
    TabVisual:AddToggle("SPEED HACK", MoveC.SpeedEnabled, function(state)
        MoveC.SpeedEnabled = state
    end)
    
    TabVisual:AddSlider("VELOCIDAD", 16, 200, MoveC.Speed or 60, function(val)
        MoveC.Speed = val
    end)
    
    TabVisual:AddToggle("SUPER JUMP", MoveC.JumpEnabled, function(state)
        MoveC.JumpEnabled = state
    end)
end

-- === PESTAÑA CONFIG ===
TabConfig:AddButton("DESTRUIR UI", function()
    Window:Destroy()
end)

print("[Main] Hub conectado al diseño de Claude con éxito.")
