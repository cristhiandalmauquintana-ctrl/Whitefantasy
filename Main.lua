--// Main.lua - Froggy Hub (loader + panel) | UI v5.0: Multi-Game Support

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"

-- 🔥 CONFIGURACIÓN MULTI-JUEGO 🔥
local SUPPORTED_GAMES = {
    [2753915549] = "BloxFruits",
    [4442272183] = "BloxFruits",
    [7449423635] = "BloxFruits",
    [7243409883] = "ElementalMagicArena", -- 🎯 Elemental Magic Arena
}

local CurrentGameFolder = SUPPORTED_GAMES[game.PlaceId] or "Universal"
local GameDisplayName = "Desconocido"
if CurrentGameFolder == "BloxFruits" then GameDisplayName = "Blox Fruits"
elseif CurrentGameFolder == "ElementalMagicArena" then GameDisplayName = "Elemental Magic Arena"
elseif CurrentGameFolder == "Universal" then GameDisplayName = "Universal" end

-- La URL ahora apunta a la carpeta del juego correspondiente
local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH, CurrentGameFolder)

local ESP_FILES = { "Esp.lua", "esp.lua" }
local MOVE_FILES = { "Movement.lua", "movement.lua" }
local CAM_FILES = { "Camlock.lua", "camlock.lua" }
local DODGE_FILES = { "AutoDodge.lua", "autododge.lua" }
local SA_FILES = { "SilentAim.lua", "silentaim.lua" }
local POT_FILES = { "Potato.lua", "potato.lua" }
local TP_FILES = { "Teleport.lua", "teleport.lua" }
local LIFT_FILES = { "AutoLift.lua", "autolift.lua" }
local DIAMOND_FILES = { "AutoDiamonds.lua", "autodiamonds.lua" } -- Solo para Elemental Magic Arena
local LOGO_FILES = { "logo.png", "Logo.png" }
local HUB_NAME = "Froggy Hub | " .. GameDisplayName

-- (El resto de la configuración de UI y descarga es idéntico al Main.lua v4.2 que ya tienes)
-- ... [Aquí va todo el código de la interfaz, funciones new, corner, stroke, etc.] ...

--==================== CARGA DE MÓDULOS ====================
setProgress(0.1, "Cargando logo...")
local logoAsset = fetchLogo()
-- ...

setProgress(0.3, "Descargando ESP...")
local source = downloadModule(ESP_FILES); if not source then fail("No se pudo descargar Esp.lua") return end
-- ...

setProgress(0.7, "Descargando movimiento...") local MoveConfig = loadOptional(MOVE_FILES, "Movement.lua", "BF_MOVE_CONFIG")
setProgress(0.8, "Descargando camlock...") local CamConfig = loadOptional(CAM_FILES, "Camlock.lua", "BF_CAM_CONFIG")
setProgress(0.85, "Descargando Auto Dodge...") local DodgeConfig = loadOptional(DODGE_FILES, "AutoDodge.lua", "BF_DODGE_CONFIG")

-- 🎯 MÓDULOS EXCLUSIVOS PARA ELEMENTAL MAGIC ARENA
if CurrentGameFolder == "ElementalMagicArena" then
    setProgress(0.87, "Cargando Auto Diamantes...")
    local DiamondConfig = loadOptional(DIAMOND_FILES, "AutoDiamonds.lua", "BF_DIAMOND_CONFIG")
    -- Puedes añadir más módulos exclusivos aquí (Auto TP a jugadores, etc.)
end

-- El Silent Aim solo se carga si estamos en un juego que lo permita (Papa)
if CurrentGameFolder == "Universal" or CurrentGameFolder == "ElementalMagicArena" then
    setProgress(0.88, "Descargando Silent Aim...")
    local SAConfig = loadOptional(SA_FILES, "SilentAim.lua", "BF_SA_CONFIG")
end

-- ... (El resto de la carga: Teleport, Lift, Potato, etc.) ...
