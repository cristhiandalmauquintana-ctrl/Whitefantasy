--// Main.lua - Froggy Hub (DIAGNÓSTICO)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local env = (getgenv and getgenv()) or _G

local designUrl = ROOT .. "design.lua"
local UI_Library = loadstring(game:HttpGet(designUrl))()

local assetsUrl = ROOT .. "assets.lua"
local Assets = loadstring(game:HttpGet(assetsUrl))()

local Window = UI_Library.CreateWindow({Title = "FROGGY HUB", Subtitle = "Diagnóstico"})
Assets.Extend(Window)

local TabMain = Window:CreateTab("MAIN")
local TabCombat = Window:CreateTab("COMBATE")
local TabVisual = Window:CreateTab("VISUAL")
local TabMovement = Window:CreateTab("MOVEMENT")
local TabAutoFarm = Window:CreateTab("AUTO FARM")

local folder = "ElementalMagicArena/"

-- 🔥 FUNCIÓN DE DESCARGA CON DIAGNÓSTICO
local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    print("[Froggy Debug] Intentando descargar:", name)
    
    local ok, res = pcall(game.HttpGet, game, url)
    if not ok then
        warn("[Froggy Debug] ❌ Error de red al descargar " .. name .. ": " .. tostring(res))
        return nil
    end
    
    if type(res) ~= "string" or #res == 0 then
        warn("[Froggy Debug] ❌ El archivo " .. name .. " está vacío o no existe.")
        return nil
    end

    if res:sub(1,3) == "404" or string.find(res, "<!DOCTYPE html>") then
        warn("[Froggy Debug] ❌ ERROR 404: El archivo " .. name .. " NO EXISTE en esa ruta de GitHub.")
        return nil
    end

    local fnOk, fn = pcall(loadstring, res)
    if not fnOk or type(fn) ~= "function" then
        warn("[Froggy Debug] ❌ ERROR DE SINTAXIS en " .. name .. ": " .. tostring(fn))
        return nil
    end

    local runOk, runErr = pcall(fn)
    if not runOk then
        warn("[Froggy Debug] ❌ ERROR DE EJECUCIÓN en " .. name .. ": " .. tostring(runErr))
        return nil
    end

    local config = env[key] or _G[key]
    if not config then
        warn("[Froggy Debug] ❌ El archivo " .. name .. " se ejecutó, pero NO creó la configuración " .. key)
        return nil
    end

    print("[Froggy Debug] ✅ " .. name .. " cargado con éxito.")
    return config
end

-- Descargamos los módulos
local CombC = download("AutoCombat.lua", "BF_COMBAT_CONFIG")
local EspC = download("EspElemental.lua", "BF_ESP_CONFIG")
local HitC = download("HitboxExpander.lua", "BF_HITBOX_CONFIG")
local MoveC = download("Movement.lua", "BF_MOVE_CONFIG")
local WaveCandyC = download("WaveCandyFarm.lua", "BF_WAVEFARM_CONFIG")

-- (Aquí irían los botones, pero para el diagnóstico no importa si aparecen o no)
if CombC then TabCombat:AddToggle("AUTO COMBAT", CombC.Enabled, function(s) CombC.Enabled = s end) end
if EspC then TabVisual:AddToggle("ESP", EspC.Enabled, function(s) EspC.Enabled = s end) end
if HitC then TabCombat:AddToggle("HITBOX", HitC.Enabled, function(s) HitC.Enabled = s end) end
if MoveC then TabMovement:AddToggle("SPEED", MoveC.SpeedEnabled, function(s) MoveC.SpeedEnabled = s end) end
if WaveCandyC then TabAutoFarm:AddToggle("HALLOWEEN", WaveCandyC.Enabled, function(s) WaveCandyC.Enabled = s end) end
