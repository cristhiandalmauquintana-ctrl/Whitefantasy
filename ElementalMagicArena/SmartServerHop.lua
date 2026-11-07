--// Main.lua - Froggy Hub | Elemental Magic Arena (Meadow UI + Smart Hop Update)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local env = (getgenv and getgenv()) or _G

-- ==========================================
-- 1. SISTEMA DE PERSISTENCIA DE SESIÓN
-- ==========================================
local SavedState = {}
if isfile and readfile then
    local ok, data = pcall(function() return readfile("FroggyConfig.json") end)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 and decoded then SavedState = decoded end
    end
end

-- ==========================================
-- 2. SISTEMA INTELIGENTE DE IDIOMAS
-- ==========================================
local Translations = {
    ["es"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
        tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_config = "CONFIG",
        rejoin = "RECONECTAR SERVIDOR", auto_combat = "AUTO COMBAT (M1)", m1_delay = "RETRASO M1",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "TAMAÑO HITBOX (PELIGRO)",
        god_mode = "MODO DIOS", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "¡IMPORTANTE! El Attack All equipará automáticamente este elemento al morir.", 
        attack_all_notify = "Recuerda usar la Guadaña para máximo daño.",
        select_element = "SELECCIONA TU ELEMENTO",
        esp = "ESP JUGADORES", boxes = "CAJAS 2D", tracers = "TRACERS", health = "BARRA DE VIDA",
        speed = "SPEED HACK", speed_val = "VELOCIDAD", jump = "SUPER JUMP", jump_val = "ALTURA DE SALTO",
        farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Fija al jugador en el cielo y ataca automáticamente usando Energía.",
        silent_collect = "AUTO-RECOLECCIÓN SILENCIOSA",
        dev_zone = "ZONA DE DESARROLLADOR", pass = "CONTRASEÑA DE PRUEBAS", unlock = "DESBLOQUEAR PRUEBA", destroy_ui = "DESTRUIR UI", lang_sel = "CAMBIAR IDIOMA", lang_desc = "Selecciona un idioma y vuelve a ejecutar."
    },
    ["en"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
        tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_config = "CONFIG",
        rejoin = "REJOIN SERVER", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "HITBOX SIZE (DANGER)",
        god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "IMPORTANT! Attack All will auto-equip this element upon death.", 
        attack_all_notify = "Remember to use the Scythe for max damage.",
        select_element = "SELECT YOUR ELEMENT",
        esp = "PLAYER ESP", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "SPEED", jump = "SUPER JUMP", jump_val = "JUMP POWER",
        farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Anchors player in the sky and attacks automatically using Energy.",
        silent_collect = "SILENT AUTO-COLLECT",
        dev_zone = "DEVELOPER ZONE", pass = "TEST PASSWORD", unlock = "UNLOCK TEST", destroy_ui = "DESTROY UI", lang_sel = "CHANGE LANGUAGE", lang_desc = "Select a language and re-execute."
    },
    ["fil"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
        tab_main = "PANGUNAHIN", tab_combat = "LABANAN", tab_visual = "BISWAL", tab_movement = "GALAW", tab_farm = "AUTO FARM", tab_config = "KONFIG",
        rejoin = "SUMALI ULIT", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
        hitbox = "HITBOX EXPANDER", hitbox_size = "LAKI NG HITBOX",
        god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "MAHALAGA! Awtomatikong i-e-equip ang elementong ito kapag namatay.", 
        attack_all_notify = "Tandaan na gumamit ng Scythe para sa max damage.",
        select_element = "PUMILI NG ELEMENTO",
        esp = "ESP NG PLAYERS", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "BILIS", jump = "SUPER JUMP", jump_val = "TAAS NG TALON",
        farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Inaayos ang player sa langit at awtomatikong umaatake gamit ang Energy.",
        silent_collect = "SILENT AUTO-COLLECT",
        dev_zone = "DEV ZONE", pass = "PASSWORD", unlock = "I-UNLOCK", destroy_ui = "IRISAN ANG UI", lang_sel = "PALITAN ANG WIKA", lang_desc = "Pumili ng wika at i-execute ulit."
    }
}

local function getSystemLanguage()
    local locale = "en"
    pcall(function()
        local id = LocalPlayer.LocaleId:lower()
        if id:find("es") then locale = "es"
        elseif id:find("fil") or id:find("tl") then locale = "fil"
        else locale = "en" end
    end)
    return locale
end

local currentLang = getSystemLanguage()
if isfile and readfile then
    local ok, savedLang = pcall(function() return readfile("FroggyLang.txt") end)
    if ok and Translations[savedLang] then currentLang = savedLang end
end

local function L(key) return Translations[currentLang][key] or Translations["en"][key] or key end

local SharedElements = {
    "energy", "luz", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad", 
    "lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido", 
    "aurora", "fenix", "caos", "tecnología", "diamante", "amor", "demon", 
    "ilusion", "campos de fuerza", "relampago", "telequinesis", "life", "mirror", 
    "time", "sueño", "creacion", "espacio", "realidad", "dios de elementos"
}

-- ==========================================
-- 3. CARGAMOS DISEÑO Y ASSETS
-- ==========================================
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua"))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua"))()

-- 🔥 IMPORTANTE: Guardar UI_Library y Assets globalmente para los módulos
env.BF_UI_LIBRARY = UI_Library 
env.BF_ASSETS_LIBRARY = Assets

local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle") })

local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabConfig = Window:CreateTab(L("tab_config"))

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
    else
        warn("❌ Could not download " .. name)
    end
    task.wait(0.1)
    return env[key] or _G[key]
end

local CombC = download("AutoCombat.lua", "BF_COMBAT_CONFIG")
local EspC = download("EspElemental.lua", "BF_ESP_CONFIG")
local HitC = download("HitboxExpander.lua", "BF_HITBOX_CONFIG")
local MoveC = download("Movement.lua", "BF_MOVE_CONFIG")
local AttackAllC = download("AttackAll.lua", "BF_ATTACKALL_CONFIG")
local SilentCollectC = download("SilentCollect.lua", "BF_SILENTCOLLECT_CONFIG")
local FarmC = download("PlayerFarm.lua", "BF_PLAYERFARM_CONFIG")
local HopC = download("SmartServerHop.lua", "BF_SERVERHOP_CONFIG")

-- ==========================================
-- 5. RESTAURADOR DE ESTADO Y CONEXIÓN UI
-- ==========================================
local function restoreToggle(configObj, savedKey, uiElement)
    if configObj and SavedState[savedKey] then
        configObj.Enabled = true
        if uiElement and uiElement.Set then 
            uiElement:Set(true, true) -- Silencioso (no spamea notificación)
        end
    end
end

-- === MAIN ===
TabMain:AddButton(L("rejoin"), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- === COMBAT ===
if CombC then
    local t = TabCombat:AddToggle(L("auto_combat"), false, function(state) CombC.Enabled = state end)
    restoreToggle(CombC, "AutoCombat", t)
    TabCombat:AddSlider(L("m1_delay"), 0.1, 1.0, CombC.M1Delay or 0.3, function(val) CombC.M1Delay = val end)
end

local hitboxSlider = nil
if HitC then
    local t = TabCombat:AddToggle(L("hitbox"), false, function(state) HitC.Enabled = state end)
    restoreToggle(HitC, "Hitbox", t)
    hitboxSlider = TabCombat:AddSlider(L("hitbox_size"), 35, 500, 35, function(val) HitC.Size = val end)
    if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = false end
end

if AttackAllC then
    TabCombat:AddSection(L("god_mode"))
    local t = TabCombat:AddToggle(L("attack_all"), false, function(state) AttackAllC.Enabled = state end)
    restoreToggle(AttackAllC, "AttackAll", t)
    
    TabCombat:AddDropdown(L("select_element"), SharedElements, AttackAllC.SelectedElement, function(val)
        AttackAllC.SelectedElement = val
        if Window.Notify then Window:Notify({Title = "Element Selected", Content = val, Type = "success"}) end
    end)
    
    TabCombat:AddInfo(L("attack_all_warn"))
end

-- === VISUAL ===
if EspC then
    local t1 = TabVisual:AddToggle(L("esp"), false, function(state) EspC.Enabled = state end)
    restoreToggle(EspC, "ESP", t1)
    TabVisual:AddToggle(L("boxes"), EspC.Boxes, function(state) EspC.Boxes = state end)
    TabVisual:AddToggle(L("tracers"), EspC.Tracers, function(state) EspC.Tracers = state end)
    TabVisual:AddToggle(L("health"), EspC.HealthBar, function(state) EspC.HealthBar = state end)
end

-- === MOVEMENT ===
if MoveC then
    local t = TabMovement:AddToggle(L("speed"), false, function(state) MoveC.SpeedEnabled = state end)
    restoreToggle(MoveC, "Speed", t)
    TabMovement:AddSlider(L("speed_val"), 16, 200, MoveC.Speed or 60, function(val) MoveC.Speed = val end)
    
    TabMovement:AddToggle(L("jump"), MoveC.JumpEnabled, function(state) MoveC.JumpEnabled = state end)
    TabMovement:AddSlider(L("jump_val"), 50, 300, MoveC.JumpPower or 100, function(val) MoveC.JumpPower = val end)
end

-- === AUTO FARM ===
if FarmC then
    TabFarm:AddSection("AUTO FARM")
    local t = TabFarm:AddToggle(L("farm_players"), false, function(state)
        FarmC.Enabled = state
        if state then 
            if Window.Notify then Window:Notify({Title = "Farm", Content = "Iniciando Farm de Energía...", Type = "success"}) end
        else 
            if Window.Notify then Window:Notify({Title = "Farm", Content = "Farmeo Detenido.", Type = "warning"}) end
        end
    end)
    restoreToggle(FarmC, "Farm", t)
    TabFarm:AddInfo(L("farm_desc"))
end

-- === CONFIG ===
if SilentCollectC then
    TabConfig:AddSection(L("utilities"))
    local t = TabConfig:AddToggle(L("silent_collect"), true, function(state) SilentCollectC.Enabled = state end)
    restoreToggle(SilentCollectC, "SilentCollect", t)
end

-- 🔥 SMART SERVER HOP SECTION
if HopC then
    TabConfig:AddSection("SEGURIDAD DE SESIÓN")
    
    TabConfig:AddToggle("AUTO SERVER HOP", HopC.Enabled, function(state)
        HopC.Enabled = state
        if state and Window.Notify then 
            Window:Notify({Title = "Server Hop", Content = "El temporizador de seguridad está activo.", Type = "success"}) 
        end
    end)
    
    TabConfig:AddSlider("TIEMPO EN SERVIDOR (MIN)", 5, 60, 20, function(val)
        HopC.HopTime = val * 60
    end)
    
    TabConfig:AddInfo("Si el Auto Farm está activo, cambiará de servidor solo. Si no, te preguntará mediante un panel.")
end

TabConfig:AddSection(L("lang_sel"))
TabConfig:AddDropdown(L("lang_sel"), {"es", "en", "fil"}, currentLang, function(val)
    if writefile then pcall(function() writefile("FroggyLang.txt", val) end) end
    if Window.Notify then Window:Notify({Title = "Language", Content = L("lang_desc"), Type = "info", Duration = 5}) end
end)

TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextbox(L("pass"), "", "...", function() end)
local unlockBtn = TabConfig:AddButton(L("unlock"), function()
    if passBox:Get() == "froggy_testing_2026" then
        if Window.Notify then Window:Notify({Title = "OK", Content = L("dev_zone"), Type = "warning"}) end
        passBox.Instance.Visible = false
        if unlockBtn and unlockBtn.Instance then unlockBtn.Instance.Visible = false end
        if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = true end
    else
        if Window.Notify then Window:Notify({Title = "Error", Content = "Wrong password", Type = "error"}) end
        passBox:Set("")
    end
end)

TabConfig:AddButton(L("destroy_ui"), function()
    Window:Destroy()
end)

print("[Main] Froggy Hub (Meadow UI + Smart Hop) cargado con éxito.")
