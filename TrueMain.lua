--// Main.lua - FROGGY HUB (Elemental Magic Arena - V3.1 Recargado)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local env = (getgenv and getgenv()) or _G

-- 🛑 CANDADO ANTI-DOBLE EJECUCIÓN
if env.BF_CURRENT_UI then
    pcall(function() env.BF_CURRENT_UI:Destroy() end)
    env.BF_CURRENT_UI = nil
end

-- ==========================================
-- 1. SISTEMA DE PERSISTENCIA
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
-- 2. SISTEMA DE IDIOMAS (5 IDIOMAS)
-- ==========================================
local Translations = {
    ["es"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | CHIBI EDITION",
        tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_tourney = "TORNEO", tab_config = "CONFIG",
        rejoin = "RECONECTAR SERVIDOR", lang_sel = "CAMBIAR IDIOMA", lang_desc = "Selecciona un idioma y vuelve a ejecutar.",
        auto_combat = "AUTO COMBAT (M1)", m1_delay = "RETRASO M1", hitbox = "HITBOX EXPANDER", hitbox_size = "TAMAÑO HITBOX",
        attack_all = "ATTACK ALL (AUTO)", attack_all_warn = "¡IMPORTANTE! Attack All teletransporta el arma al enemigo sin M1.", select_element = "SELECCIONA ELEMENTO",
        esp = "ESP JUGADORES", boxes = "CAJAS 2D", tracers = "TRACERS", health = "BARRA DE VIDA",
        speed = "SPEED HACK", speed_val = "VELOCIDAD", jump = "SUPER JUMP", jump_val = "ALTURA SALTO",
        farm_players = "AUTO FARM", farm_desc = "Usa el Dropdown para elegir el elemento.", touch_tp = "TOUCH TP (TOOL)",
        tourney_desc = "Persigue al enemigo 10 studs atrás.", silent_collect = "AUTO-RECOLECCIÓN SILENCIOSA",
        no_robux = "BLOQUEAR COMPRAS DE ROBUX", no_robux_desc = "Evita que la espada abra tiendas.", no_popups = "BLOQUEAR VENTANAS", no_popups_desc = "Destruye menús del juego.",
        dev_zone = "ZONA DE DESARROLLADOR", pass = "CONTRASEÑA", unlock = "DESBLOQUEAR", destroy_ui = "DESTRUIR UI"
    },
    ["en"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | CHIBI EDITION",
        tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_tourney = "TOURNAMENT", tab_config = "CONFIG",
        rejoin = "REJOIN SERVER", lang_sel = "CHANGE LANGUAGE", lang_desc = "Select a language and re-execute.",
        auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY", hitbox = "HITBOX EXPANDER", hitbox_size = "HITBOX SIZE",
        attack_all = "ATTACK ALL (AUTO)", attack_all_warn = "IMPORTANT! Attack All teleports your weapon to the enemy without M1.", select_element = "SELECT ELEMENT",
        esp = "PLAYER ESP", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "SPEED", jump = "SUPER JUMP", jump_val = "JUMP POWER",
        farm_players = "AUTO FARM", farm_desc = "Use the Dropdown to select the element.", touch_tp = "TOUCH TP (TOOL)",
        tourney_desc = "Stalks the enemy 10 studs behind.", silent_collect = "SILENT AUTO-COLLECT",
        no_robux = "BLOCK ROBUX PURCHASES", no_robux_desc = "Prevents the sword from opening shops.", no_popups = "BLOCK POP-UPS", no_popups_desc = "Destroys game menus.",
        dev_zone = "DEVELOPER ZONE", pass = "PASSWORD", unlock = "UNLOCK", destroy_ui = "DESTROY UI"
    },
    ["fil"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | CHIBI EDITION",
        tab_main = "PANGUNAHIN", tab_combat = "LABANAN", tab_visual = "BISWAL", tab_movement = "GALAW", tab_farm = "AUTO FARM", tab_tourney = "TOURNAMENT", tab_config = "KONFIG",
        rejoin = "SUMALI ULIT", lang_sel = "PALITAN ANG WIKA", lang_desc = "Pumili ng wika at i-execute ulit.",
        auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY", hitbox = "HITBOX EXPANDER", hitbox_size = "LAKI NG HITBOX",
        attack_all = "ATTACK ALL (AUTO)", attack_all_warn = "MAHALAGA! Attack All nag-te-teleport ng sandata sa kalaban.", select_element = "PUMILI NG ELEMENTO",
        esp = "ESP NG PLAYERS", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "BILIS", jump = "SUPER JUMP", jump_val = "TAAS NG TALON",
        farm_players = "AUTO FARM", farm_desc = "Gamitin ang Dropdown para pumili ng elemento.", touch_tp = "TOUCH TP (TOOL)",
        tourney_desc = "Sinusundan ang kalaban 10 studs sa likod.", silent_collect = "SILENT AUTO-COLLECT",
        no_robux = "I-BLOCK ANG ROBUX", no_robux_desc = "Pigilan ang pagbukas ng shop.", no_popups = "I-BLOCK ANG POP-UPS", no_popups_desc = "Sinisirain ang mga menu.",
        dev_zone = "DEV ZONE", pass = "PASSWORD", unlock = "I-UNLOCK", destroy_ui = "IRISAN ANG UI"
    },
    ["vi"] = {
        title = "FROGGY HUB", subtitle = "200 THÀNH VIÊN | CHIBI",
        tab_main = "CHÍNH", tab_combat = "CHIẾN ĐẤU", tab_visual = "HÌNH ẢNH", tab_movement = "DI CHUYỂN", tab_farm = "AUTO FARM", tab_tourney = "GIẢI ĐẤU", tab_config = "CÀI ĐẶT",
        rejoin = "VÀO LẠI SERVER", lang_sel = "ĐỔI NGÔN NGỮ", lang_desc = "Chọn ngôn ngữ và chạy lại script.",
        auto_combat = "AUTO COMBAT (M1)", m1_delay = "ĐỘ TRỄ M1", hitbox = "MỞ RỘNG HITBOX", hitbox_size = "KÍCH THƯỚC HITBOX",
        attack_all = "TẤN CÔNG TẤT CẢ", attack_all_warn = "QUAN TRỌNG! Tự động dịch chuyển vũ khí đến kẻ địch.", select_element = "CHỌN NGUYÊN TỐ",
        esp = "ESP NGƯỜI CHƠI", boxes = "HỘP 2D", tracers = "ĐƯỜNG KẺ", health = "THANH MÁU",
        speed = "TỐC ĐỘ", speed_val = "TỐC ĐỘ CHẠY", jump = "NHẢY CAO", jump_val = "LỰC NHẢY",
        farm_players = "AUTO FARM", farm_desc = "Sử dụng Dropdown để chọn nguyên tố.", touch_tp = "TOUCH TP (TOOL)",
        tourney_desc = "Theo dõi kẻ địch từ phía sau.", silent_collect = "THU THẬP TỰ ĐỘNG",
        no_robux = "CHẶN MUA ROBUX", no_robux_desc = "Ngăn chặn cửa hàng mở ra.", no_popups = "CHẶN POP-UPS", no_popups_desc = "Phá hủy menu trò chơi.",
        dev_zone = "KHU VỰC DEV", pass = "MẬT KHẨU", unlock = "MỞ KHÓA", destroy_ui = "PHÁ HỦY UI"
    },
    ["ru"] = {
        title = "FROGGY HUB", subtitle = "200 УЧАСТНИКОВ | CHIBI",
        tab_main = "ГЛАВНАЯ", tab_combat = "БОЙ", tab_visual = "ВИЗУАЛ", tab_movement = "ДВИЖЕНИЕ", tab_farm = "АВТОФАРМ", tab_tourney = "ТУРНИР", tab_config = "НАСТРОЙКИ",
        rejoin = "ПЕРЕЗАЙТИ НА СЕРВЕР", lang_sel = "СМЕНИТЬ ЯЗЫК", lang_desc = "Выберите язык и перезапустите скрипт.",
        auto_combat = "АВТОБОЙ (M1)", m1_delay = "ЗАДЕРЖКА M1", hitbox = "РАСШИРИТЕЛЬ ХИТБОКСА", hitbox_size = "РАЗМЕР ХИТБОКСА",
        attack_all = "АТАКА ВСЕХ", attack_all_warn = "ВАЖНО! Автоматически телепортирует оружие к врагу.", select_element = "ВЫБЕРИТЕ ЭЛЕМЕНТ",
        esp = "ESP ИГРОКОВ", boxes = "2D БОКСЫ", tracers = "ТРАССЕРЫ", health = "ПОЛОСА ЗДОРОВЬЯ",
        speed = "СПИДХАК", speed_val = "СКОРОСТЬ", jump = "СУПЕР ПРЫЖОК", jump_val = "СИЛА ПРЫЖКА",
        farm_players = "АВТОФАРМ", farm_desc = "Используйте Dropdown, чтобы выбрать элемент.", touch_tp = "TOUCH TP (TOOL)",
        tourney_desc = "Преследует врага в 10 стадах позади.", silent_collect = "ТИХИЙ СБОР",
        no_robux = "БЛОКИРОВАТЬ ПОКУПКИ ROBUX", no_robux_desc = "Не дает мечу открывать магазины.", no_popups = "БЛОКИРОВАТЬ ОКНА", no_popups_desc = "Уничтожает меню игры.",
        dev_zone = "ЗОНА РАЗРАБОТЧИКА", pass = "ПАРОЛЬ", unlock = "РАЗБЛОКИРОВАТЬ", destroy_ui = "УНИЧТОЖИТЬ UI"
    }
}

local langOrder = {"en", "es", "fil", "vi", "ru"}
local currentLang = "en"

-- Cargar idioma guardado
if isfile and readfile then
    local ok, savedLang = pcall(function() return readfile("FroggyLang.txt") end)
    if ok and Translations[savedLang] then currentLang = savedLang end
else
    -- Detección por sistema
    pcall(function()
        local id = LocalPlayer.LocaleId:lower()
        if id:find("es") then currentLang = "es"
        elseif id:find("fil") or id:find("tl") then currentLang = "fil"
        elseif id:find("vi") then currentLang = "vi"
        elseif id:find("ru") then currentLang = "ru" end
    end)
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
-- 3. CARGAMOS DISEÑO Y ASSETS (CON OS.TIME)
-- ==========================================
print("[Froggy] Cargando interfaz...")
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua?v=" .. os.time()))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua?v=" .. os.time()))()

env.BF_UI_LIBRARY = UI_Library 
env.BF_ASSETS_LIBRARY = Assets

local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle") })
env.BF_CURRENT_UI = Window

local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabTourney = Window:CreateTab(L("tab_tourney"))
local TabConfig = Window:CreateTab(L("tab_config"))

-- ==========================================
-- 4. DESCARGA DE MÓDULOS (CON OS.TIME ORIGINAL)
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time() -- 🔥 EL OS.TIME QUE PEDISTE
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
local TouchTPC = download("TouchTp.lua", "BF_TOUCHTP_CONFIG")
local TourneyC = nil -- AutoTournament.lua: pendiente (aún no está listo)

-- ==========================================
-- 5. CONEXIÓN UI Y RESTAURACIÓN DE ESTADO
-- ==========================================
local function restoreToggle(configObj, savedKey, uiElement)
    if configObj and SavedState[savedKey] then
        configObj.Enabled = true
        if uiElement and uiElement.Set then 
            uiElement:Set(true, true) 
        end
    end
end

-- === MAIN ===
TabMain:AddButton(L("rejoin"), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

TabMain:AddSection(L("lang_sel"))
TabMain:AddDropdown(L("lang_sel"), langOrder, currentLang, function(val)
    if writefile then pcall(function() writefile("FroggyLang.txt", val) end) end
    Window:Notify({Title = "Language", Content = L("lang_desc"), Type = "info", Duration = 5})
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
    TabCombat:AddSection(L("attack_all"))
    local t = TabCombat:AddToggle(L("attack_all"), false, function(state) AttackAllC.Enabled = state end)
    restoreToggle(AttackAllC, "AttackAll", t)
    
    TabCombat:AddDropdown(L("select_element"), SharedElements, AttackAllC.SelectedElement, function(val)
        AttackAllC.SelectedElement = val
        if Window.Notify then Window:Notify({Title = "Element Selected", Content = val, Type = "success"}) end
    end)
    TabCombat:AddInfo(L("attack_all_warn"))
end

-- Módulo Touch TP (Movido a Combate)
if TouchTPC then
    TabCombat:AddSection("UTILIDADES MÓVILES")
    TabCombat:AddToggle(L("touch_tp"), false, function(state)
        if TouchTPC.SetEnabled then
            TouchTPC.SetEnabled(state)
            if state and Window.Notify then 
                Window:Notify({Title = "Touch TP", Content = "Botón flotante creado.", Type = "success"}) 
            end
        end
    end)
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
            if Window.Notify then Window:Notify({Title = "Farm", Content = "Iniciando Farm...", Type = "success"}) end
        else 
            if Window.Notify then Window:Notify({Title = "Farm", Content = "Farmeo Detenido.", Type = "warning"}) end
        end
    end)
    restoreToggle(FarmC, "Farm", t)
    TabFarm:AddInfo(L("farm_desc"))
end

-- === TOURNEY ===
if TourneyC then
    TabTourney:AddSection("AUTO TOURNAMENT (1v1)")
    TabTourney:AddToggle("AUTO TOURNAMENT", false, function(state) TourneyC.Enabled = state end)
    TabTourney:AddInfo(L("tourney_desc"))
end

-- === CONFIG ===
if SilentCollectC then
    TabConfig:AddSection("UTILIDADES")
    local t = TabConfig:AddToggle(L("silent_collect"), true, function(state) SilentCollectC.Enabled = state end)
    restoreToggle(SilentCollectC, "SilentCollect", t)
end

if HopC then
    TabConfig:AddSection("SEGURIDAD DE SESIÓN")
    TabConfig:AddToggle("AUTO SERVER HOP", false, function(state)
        HopC.Enabled = state
        if state and Window.Notify then Window:Notify({Title = "Server Hop", Content = "Temporizador activo.", Type = "success"}) end
    end)
    TabConfig:AddSlider("TIEMPO EN SERVIDOR (MIN)", 5, 60, 20, function(val) HopC.HopTime = val * 60 end)
end

if NoRobuxC then
    TabConfig:AddSection("SEGURIDAD EXTRA")
    TabConfig:AddToggle(L("no_robux"), true, function(state) NoRobuxC.Enabled = state end)
    TabConfig:AddInfo(L("no_robux_desc"))
end

if NoPopUpsC then
    TabConfig:AddToggle(L("no_popups"), true, function(state) NoPopUpsC.Enabled = state end)
    TabConfig:AddInfo(L("no_popups_desc"))
end

-- === DEV ZONE ===
TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextbox(L("pass"), "", "...", function() end)
local unlockBtn = TabConfig:AddButton(L("unlock"), function()
    if passBox:Get() == "froggy_testing_2026" then
        if Window.Notify then Window:Notify({Title = "OK", Content = L("dev_zone"), Type = "warning"}) end
        passBox.Instance.Parent.Visible = false
        if unlockBtn and unlockBtn.Instance then unlockBtn.Instance.Parent.Visible = false end
        if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Parent.Visible = true end
    else
        if Window.Notify then Window:Notify({Title = "Error", Content = "Wrong password", Type = "error"}) end
        passBox:Set("")
    end
end)

TabConfig:AddButton(L("destroy_ui"), function()
    Window:Destroy()
end)

print("[Main] Froggy Hub V3.1 cargado exitosamente.")
