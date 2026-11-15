--// TrueMain.lua - DEEP BLUE HUB (V5.2 - Crystal API Fix)
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

local function restoreToggle(configObj, savedKey, uiElement)
    if configObj and SavedState[savedKey] then
        configObj.Enabled = true
        if uiElement and uiElement.Set then uiElement:Set(true) end
    end
end

-- ==========================================
-- CONEXIÓN UI (Usando el formato de tabla de Claude)
-- ==========================================

TabMain:AddButton({ Name = L("rejoin"), Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end })

TabMain:AddSection({ Name = L("lang_sel") })
TabMain:AddDropdown({ 
    Name = L("lang_sel"), 
    Options = {"en", "es"}, 
    Default = currentLang, 
    Callback = function(val)
        if writefile then pcall(function() writefile("DeepBlueLang.txt", val) end) end
        Window:Notify({Title = "Language", Content = L("lang_desc"), Type = "Info", Duration = 5})
    end 
})

if CombC then
    local t = TabCombat:AddToggle({ Name = L("auto_combat"), Default = false, Callback = function(state) CombC.Enabled = state end })
    restoreToggle(CombC, "AutoCombat", t)
    TabCombat:AddSlider({ 
        Name = L("m1_delay"), Min = 0.1, Max = 1.0, Default = CombC.M1Delay or 0.3, Increment = 0.1, 
        Callback = function(val) CombC.M1Delay = val end 
    })
end

local hitboxSlider = nil
if HitC then
    local t = TabCombat:AddToggle({ Name = L("hitbox"), Default = false, Callback = function(state) HitC.Enabled = state end })
    restoreToggle(HitC, "Hitbox", t)
    hitboxSlider = TabCombat:AddSlider({ 
        Name = L("hitbox_size"), Min = 35, Max = 500, Default = 35, Increment = 1, 
        Callback = function(val) HitC.Size = val end 
    })
    if hitboxSlider and hitboxSlider.Frame then hitboxSlider.Frame.Visible = false end
end

if AttackAllC then
    TabCombat:AddSection({ Name = L("attack_all") })
    local t = TabCombat:AddToggle({ Name = L("attack_all"), Default = false, Callback = function(state) AttackAllC.Enabled = state end })
    restoreToggle(AttackAllC, "AttackAll", t)
    TabCombat:AddDropdown({ 
        Name = L("select_element"), Options = SharedElements, Default = AttackAllC.SelectedElement, 
        Callback = function(val) AttackAllC.SelectedElement = val end 
    })
    TabCombat:AddInfo({ Title = "Info", Content = L("attack_all_warn") })
end

if TouchTPC then
    TabCombat:AddSection({ Name = "UTILIDADES MÓVILES" })
    TabCombat:AddToggle({ Name = L("touch_tp"), Default = false, Callback = function(state)
        if TouchTPC.SetEnabled then TouchTPC.SetEnabled(state) end
    end })
end

if EspC then
    local t1 = TabVisual:AddToggle({ Name = L("esp"), Default = false, Callback = function(state) EspC.Enabled = state end })
    restoreToggle(EspC, "ESP", t1)
    TabVisual:AddToggle({ Name = L("boxes"), Default = EspC.Boxes, Callback = function(state) EspC.Boxes = state end })
    TabVisual:AddToggle({ Name = L("tracers"), Default = EspC.Tracers, Callback = function(state) EspC.Tracers = state end })
    TabVisual:AddToggle({ Name = L("health"), Default = EspC.HealthBar, Callback = function(state) EspC.HealthBar = state end })
end

if MoveC then
    local t = TabMovement:AddToggle({ Name = L("speed"), Default = false, Callback = function(state) MoveC.SpeedEnabled = state end })
    restoreToggle(MoveC, "Speed", t)
    TabMovement:AddSlider({ 
        Name = L("speed_val"), Min = 16, Max = 200, Default = MoveC.Speed or 60, Increment = 1, 
        Callback = function(val) MoveC.Speed = val end 
    })
    TabMovement:AddToggle({ Name = L("jump"), Default = MoveC.JumpEnabled, Callback = function(state) MoveC.JumpEnabled = state end })
    TabMovement:AddSlider({ 
        Name = L("jump_val"), Min = 50, Max = 300, Default = MoveC.JumpPower or 100, Increment = 1, 
        Callback = function(val) MoveC.JumpPower = val end 
    })
end

if FarmC then
    TabFarm:AddSection({ Name = "AUTO FARM" })
    local t = TabFarm:AddToggle({ Name = L("farm_players"), Default = false, Callback = function(state) FarmC.Enabled = state end })
    restoreToggle(FarmC, "Farm", t)
    TabFarm:AddInfo({ Title = "Info", Content = L("farm_desc") })
end

if SilentCollectC then
    TabConfig:AddSection({ Name = "UTILIDADES" })
    local t = TabConfig:AddToggle({ Name = L("silent_collect"), Default = true, Callback = function(state) SilentCollectC.Enabled = state end })
    restoreToggle(SilentCollectC, "SilentCollect", t)
end

if HopC then
    TabConfig:AddSection({ Name = "SEGURIDAD DE SESIÓN" })
    local t = TabConfig:AddToggle({ Name = "AUTO SERVER HOP", Default = false, Callback = function(state) HopC.Enabled = state end })
    restoreToggle(HopC, "ServerHop", t)
    TabConfig:AddSlider({ 
        Name = "TIEMPO (MIN)", Min = 5, Max = 60, Default = 20, Increment = 1, 
        Callback = function(val) HopC.HopTime = val * 60 end 
    })
end

if NoRobuxC then
    TabConfig:AddSection({ Name = "SEGURIDAD EXTRA" })
    local t = TabConfig:AddToggle({ Name = L("no_robux"), Default = true, Callback = function(state) NoRobuxC.Enabled = state end })
    restoreToggle(NoRobuxC, "NoRobux", t)
    TabConfig:AddInfo({ Title = "Info", Content = L("no_robux_desc") })
end

if NoPopUpsC then
    local t = TabConfig:AddToggle({ Name = L("no_popups"), Default = true, Callback = function(state) NoPopUpsC.Enabled = state end })
    restoreToggle(NoPopUpsC, "NoPopUps", t)
    TabConfig:AddInfo({ Title = "Info", Content = L("no_popups_desc") })
end

TabConfig:AddSection({ Name = L("dev_zone") })
local passBox = TabConfig:AddTextbox({ Name = L("pass"), Default = "", Placeholder = "..." })
local unlockBtn = TabConfig:AddButton({ Name = L("unlock"), Callback = function()
    if passBox:Get() == "froggy_testing_2026" then
        passBox.Frame.Parent.Visible = false
        if unlockBtn and unlockBtn.Frame then unlockBtn.Frame.Parent.Visible = false end
        if hitboxSlider and hitboxSlider.Frame then hitboxSlider.Frame.Visible = true end
    else
        passBox:Set("")
    end
end })

TabConfig:AddButton({ Name = L("destroy_ui"), Callback = function() Window:Destroy() end })
