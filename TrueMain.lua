--// TrueMain.lua - DEEP BLUE HUB (V5.4 - OPSEC Fix)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local env = (getgenv and getgenv()) or _G

if env.BF_CURRENT_UI then
    pcall(function() env.BF_CURRENT_UI:Destroy() end)
    env.BF_CURRENT_UI = nil
end

local SavedState = {}
if isfile and readfile then
    local ok, data = pcall(function() return readfile("DeepBlueConfig.json") end)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 and decoded then SavedState = decoded end
    end
end

local Translations = {
    ["es"] = { title = "DEEP BLUE HUB", subtitle = "DEEP OCEAN EDITION", tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_config = "CONFIG", rejoin = "RECONECTAR", lang_sel = "IDIOMA", lang_desc = "Selecciona idioma.", auto_combat = "AUTO COMBAT", m1_delay = "RETRASO M1", hitbox = "HITBOX", hitbox_size = "TAMAÑO", attack_all = "ATTACK ALL", attack_all_warn = "Auto ataque.", select_element = "ELEMENTO", esp = "ESP", boxes = "CAJAS", tracers = "TRACERS", health = "VIDA", speed = "SPEED", speed_val = "VELOCIDAD", jump = "JUMP", jump_val = "SALTO", farm_players = "FARM", farm_desc = "Elige elemento.", touch_tp = "TOUCH TP", tourney_desc = "PvP.", silent_collect = "SILENT COLLECT", no_robux = "NO ROBUX", no_robux_desc = "Bloquea tiendas.", no_popups = "NO POPUPS", no_popups_desc = "Bloquea ventanas.", dev_zone = "DEV ZONE", pass = "CLAVE", unlock = "DESBLOQUEAR", destroy_ui = "DESTRUIR UI" },
    ["en"] = { title = "DEEP BLUE HUB", subtitle = "DEEP OCEAN EDITION", tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_config = "CONFIG", rejoin = "REJOIN", lang_sel = "LANGUAGE", lang_desc = "Select language.", auto_combat = "AUTO COMBAT", m1_delay = "M1 DELAY", hitbox = "HITBOX", hitbox_size = "SIZE", attack_all = "ATTACK ALL", attack_all_warn = "Auto attack.", select_element = "ELEMENT", esp = "ESP", boxes = "BOXES", tracers = "TRACERS", health = "HEALTH", speed = "SPEED", speed_val = "SPEED", jump = "JUMP", jump_val = "JUMP", farm_players = "FARM", farm_desc = "Select element.", touch_tp = "TOUCH TP", tourney_desc = "PvP.", silent_collect = "SILENT COLLECT", no_robux = "NO ROBUX", no_robux_desc = "Blocks shops.", no_popups = "NO POPUPS", no_popups_desc = "Blocks menus.", dev_zone = "DEV ZONE", pass = "PASS", unlock = "UNLOCK", destroy_ui = "DESTROY UI" }
}

local currentLang = "en"
local function L(key) return Translations[currentLang][key] or Translations["en"][key] or key end

local SharedElements = { "energy", "luz", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad", "lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido", "aurora", "fenix", "caos", "tecnología", "diamante", "amor", "demon", "ilusion", "campos de fuerza", "relampago", "telequinesis", "life", "mirror", "time", "sueño", "creacion", "espacio", "realidad", "dios de elementos" }

print("[Deep Blue] Iniciando carga de UI...")
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua?v=" .. os.time()))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua?v=" .. os.time()))()

local savedTheme = SavedState.Theme or "ocean"
local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle"), Theme = savedTheme })
env.BF_CURRENT_UI = Window

if Assets and type(Assets.Extend) == "function" then
    Assets.Extend(Window)
end

local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabConfig = Window:CreateTab(L("tab_config"))

local folder = "ElementalMagicArena/"

local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and type(res) == "string" and #res > 10 and res:sub(1,3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then pcall(fn) end
    else
        warn("❌ Fallo al descargar: " .. name)
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
local TouchTPC = download("TouchTp.lua", "BF_TOUCHTP_CONFIG")
local NoRobuxC = download("NoRobux.lua", "BF_NOROBUX_CONFIG")
local NoPopUpsC = download("NoPopUps.lua", "BF_NOPOPUPS_CONFIG")

-- 🔥 FIX CRÍTICO: FORZAR LAS DEFENSAS AL INICIAR (EVITA POPUPS Y LOBBY)
if NoRobuxC then NoRobuxC.Enabled = true end
if NoPopUpsC then NoPopUpsC.Enabled = true end

local function restoreToggle(configObj, savedKey, uiElement)
    if configObj and SavedState[savedKey] then
        configObj.Enabled = true
        if uiElement and uiElement.Set then uiElement:Set(true) end
    end
end

-- ==========================================
-- CONEXIÓN UI (Usando argumentos posicionales)
-- ==========================================

TabMain:AddButton(L("rejoin"), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

TabMain:AddSection(L("lang_sel"))
TabMain:AddDropdown(L("lang_sel"), {"en", "es"}, currentLang, function(val)
    if writefile then pcall(function() writefile("DeepBlueLang.txt", val) end) end
    Window:Notify({Title = "Language", Content = L("lang_desc"), Type = "info", Duration = 5})
end)

if CombC then
    local t = TabCombat:AddToggle(L("auto_combat"), false, function(state) CombC.Enabled = state end)
    restoreToggle(CombC, "AutoCombat", t)
    TabCombat:AddSlider(L("m1_delay"), 0.1, 1.0, CombC.M1Delay or 0.3, function(val) CombC.M1Delay = val end, 0.1)
end

local hitboxSlider = nil
if HitC then
    local t = TabCombat:AddToggle(L("hitbox"), false, function(state) HitC.Enabled = state end)
    restoreToggle(HitC, "Hitbox", t)
    hitboxSlider = TabCombat:AddSlider(L("hitbox_size"), 35, 500, 35, function(val) HitC.Size = val end, 1)
    if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = false end
end

if AttackAllC then
    TabCombat:AddSection(L("attack_all"))
    local t = TabCombat:AddToggle(L("attack_all"), false, function(state) AttackAllC.Enabled = state end)
    restoreToggle(AttackAllC, "AttackAll", t)
    TabCombat:AddDropdown(L("select_element"), SharedElements, AttackAllC.SelectedElement, function(val) AttackAllC.SelectedElement = val end)
    TabCombat:AddInfo(L("attack_all_warn"))
end

if TouchTPC then
    TabCombat:AddSection("UTILIDADES MÓVILES")
    TabCombat:AddToggle(L("touch_tp"), false, function(state)
        if TouchTPC.SetEnabled then TouchTPC.SetEnabled(state) end
    end)
end

if EspC then
    local t1 = TabVisual:AddToggle(L("esp"), false, function(state) EspC.Enabled = state end)
    restoreToggle(EspC, "ESP", t1)
    TabVisual:AddToggle(L("boxes"), EspC.Boxes, function(state) EspC.Boxes = state end)
    TabVisual:AddToggle(L("tracers"), EspC.Tracers, function(state) EspC.Tracers = state end)
    TabVisual:AddToggle(L("health"), EspC.HealthBar, function(state) EspC.HealthBar = state end)
end

if MoveC then
    local t = TabMovement:AddToggle(L("speed"), false, function(state) MoveC.SpeedEnabled = state end)
    restoreToggle(MoveC, "Speed", t)
    TabMovement:AddSlider(L("speed_val"), 16, 200, MoveC.Speed or 60, function(val) MoveC.Speed = val end, 1)
    TabMovement:AddToggle(L("jump"), MoveC.JumpEnabled, function(state) MoveC.JumpEnabled = state end)
    TabMovement:AddSlider(L("jump_val"), 50, 300, MoveC.JumpPower or 100, function(val) MoveC.JumpPower = val end, 1)
end

if FarmC then
    TabFarm:AddSection("AUTO FARM")
    local t = TabFarm:AddToggle(L("farm_players"), false, function(state) FarmC.Enabled = state end)
    restoreToggle(FarmC, "Farm", t)
    TabFarm:AddInfo(L("farm_desc"))
end

if SilentCollectC then
    TabConfig:AddSection("UTILIDADES")
    local t = TabConfig:AddToggle(L("silent_collect"), true, function(state) SilentCollectC.Enabled = state end)
    restoreToggle(SilentCollectC, "SilentCollect", t)
end

if HopC then
    TabConfig:AddSection("SEGURIDAD DE SESIÓN")
    local t = TabConfig:AddToggle("AUTO SERVER HOP", false, function(state) HopC.Enabled = state end)
    restoreToggle(HopC, "ServerHop", t)
    TabConfig:AddSlider("TIEMPO (MIN)", 5, 60, 20, function(val) HopC.HopTime = val * 60 end, 1)
end

if NoRobuxC then
    TabConfig:AddSection("SEGURIDAD EXTRA")
    local t = TabConfig:AddToggle(L("no_robux"), true, function(state) NoRobuxC.Enabled = state end)
    restoreToggle(NoRobuxC, "NoRobux", t)
    TabConfig:AddInfo(L("no_robux_desc"))
end

if NoPopUpsC then
    local t = TabConfig:AddToggle(L("no_popups"), true, function(state) NoPopUpsC.Enabled = state end)
    restoreToggle(NoPopUpsC, "NoPopUps", t)
    TabConfig:AddInfo(L("no_popups_desc"))
end

TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextbox(L("pass"), "", "...", function() end)
local unlockBtn = TabConfig:AddButton(L("unlock"), function()
    if passBox:Get() == "froggy_testing_2026" then
        if passBox.Frame and passBox.Frame.Parent then passBox.Frame.Parent.Visible = false end
        if unlockBtn and unlockBtn.Frame and unlockBtn.Frame.Parent then unlockBtn.Frame.Parent.Visible = false end
        if hitboxSlider and hitboxSlider.Frame and hitboxSlider.Frame.Parent then hitboxSlider.Frame.Parent.Visible = true end
    else
        passBox:Set("")
    end
end)

TabConfig:AddButton(L("destroy_ui"), function() Window:Destroy() end)
