--// Main.lua - Froggy Hub | UI Épica v19
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 1. CARGAMOS EL DISEÑO DE CLAUDE
local designUrl = ROOT .. "design.lua"
local UI_Library = loadstring(game:HttpGet(designUrl))()

-- 2. CREAMOS LA VENTANA PRINCIPAL
-- (Ajusta los textos según lo que Claude haya programado)
local Window = UI_Library:CreateWindow({
    Title = "FROGGY HUB",
    Subtitle = "SYS 0x5EE9" 
})

-- 3. CREAMOS LAS PESTAÑAS
local TabMain = Window:CreateTab("MAIN")
local TabVisual = Window:CreateTab("VISUAL")
local TabConfig = Window:CreateTab("CONFIG")

-- ==========================================
-- 4. LÓGICA DE CARGA DE MÓDULOS (Como ya la tenías)
-- ==========================================
local function download(names, key)
    for _, n in ipairs(names) do
        local ok, res = pcall(game.HttpGet, game, ROOT .. "ElementalMagicArena/" .. n .. "?v=" .. os.time())
        if ok and type(res) == "string" and #res > 0 then
            local fnOk, fn = pcall(loadstring, res)
            if fnOk and type(fn) == "function" then pcall(fn) end
        end
    end
    task.wait(0.1)
    return env[key] or _G[key]
end

-- Descargamos los módulos (Variables globales)
local EspC = download({"EspElemental.lua"}, "BF_ESP_CONFIG")
local MoveC = download({"Movement.lua"}, "BF_MOVE_CONFIG")
local HitC = download({"HitboxExpander.lua"}, "BF_HITBOX_CONFIG")
local CombC = download({"AutoCombat.lua"}, "BF_COMBAT_CONFIG")

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES DEL DISEÑO A LA LÓGICA
-- ==========================================

-- === PESTAÑA MAIN ===
if EspC then
    TabMain:AddToggle("ESP JUGADORES", EspC.Enabled, function(state)
        EspC.Enabled = state
    end)
end

if HitC then
    -- Aquí conectamos el botón de Auto Farm que sale en tu foto
    TabMain:AddToggle("AUTO FARM (Hitbox)", HitC.Enabled, function(state)
        HitC.Enabled = state
    end)
end

-- Botón de Teletransportar (como en tu foto)
TabMain:AddButton("TELETRANSPORTAR", function()
    -- Aquí pones la lógica de teletransporte, por ejemplo a un spawn
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0) -- Cambia por la coordenada que quieras
    end
end)

-- === PESTAÑA VISUAL ===
if MoveC then
    -- El slider de velocidad que sale en tu foto
    TabVisual:AddSlider("VELOCIDAD", 16, 200, MoveC.Speed or 60, function(value)
        MoveC.Speed = value
        -- Si el módulo de movimiento tiene un toggle para activar el speed
        if MoveC.SpeedEnabled == false then
            MoveC.SpeedEnabled = true 
        end
    end)
end

-- === PESTAÑA CONFIG ===
TabConfig:AddButton("REJOIN SERVER", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

print("[Main] Hub conectado al diseño de Claude con éxito.")
