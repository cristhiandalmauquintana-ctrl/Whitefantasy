--// Main.lua - Froggy Hub | Elemental Magic Arena (Tournament & Device Update)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH .. "/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local env = (getgenv and getgenv()) or _G

-- ==========================================
-- LIMPIEZA DE EJECUCIONES ANTERIORES
-- ==========================================
if env.BF_CURRENT_UI then
	pcall(function() env.BF_CURRENT_UI:Destroy() end)
	env.BF_CURRENT_UI = nil
end

-- borra cualquier GUI vieja del hub que haya quedado viva
pcall(function()
	local root = (gethui and gethui()) or game:GetService("CoreGui")
	for _, g in ipairs(root:GetChildren()) do
		if g.Name:find("^FroggyHub_") or g.Name:find("^FroggyFarm_") then
			g:Destroy()
		end
	end
end)

-- ==========================================
-- 1. PERSISTENCIA Y DISPOSITIVO
-- ==========================================
local SavedState = {}
if isfile and readfile then
	local ok, data = pcall(function()
		if isfile("FroggyConfig.json") then return readfile("FroggyConfig.json") end
	end)
	if ok and data then
		local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
		if ok2 and type(decoded) == "table" then SavedState = decoded end
	end
end

local function persist()
	if writefile then
		pcall(function() writefile("FroggyConfig.json", HttpService:JSONEncode(SavedState)) end)
	end
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==========================================
-- 2. IDIOMAS
-- ==========================================
local Translations = {
	["es"] = {
		title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
		tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_tourney = "TORNEO", tab_config = "CONFIG",
		rejoin = "RECONECTAR SERVIDOR", auto_combat = "AUTO COMBAT (M1)", m1_delay = "RETRASO M1",
		hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "TAMAÑO HITBOX (PELIGRO)",
		god_mode = "MODO DIOS", attack_all = "ATTACK ALL (AUTO)",
		attack_all_warn = "¡IMPORTANTE! El Attack All equipará automáticamente este elemento al morir.",
		attack_all_notify = "Recuerda usar la Guadaña para máximo daño.",
		select_element = "SELECCIONA TU ELEMENTO",
		esp = "ESP JUGADORES", boxes = "CAJAS 2D", tracers = "TRACERS", health = "BARRA DE VIDA",
		speed = "SPEED HACK", speed_val = "VELOCIDAD", jump = "SUPER JUMP", jump_val = "ALTURA DE SALTO",
		farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Fija al jugador en el cielo y ataca automáticamente usando Energía.",
		tourney_desc = "Persigue al enemigo 10 studs atrás y arriba. Ideal para 1v1.",
		silent_collect = "AUTO-RECOLECCIÓN SILENCIOSA", utilities = "UTILIDADES",
		dev_zone = "ZONA DE DESARROLLADOR", pass = "CONTRASEÑA DE PRUEBAS", unlock = "DESBLOQUEAR PRUEBA", destroy_ui = "DESTRUIR UI", lang_sel = "CAMBIAR IDIOMA", lang_desc = "Selecciona un idioma y vuelve a ejecutar."
	},
	["en"] = {
		title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
		tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_tourney = "TOURNAMENT", tab_config = "CONFIG",
		rejoin = "REJOIN SERVER", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
		hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "HITBOX SIZE (DANGER)",
		god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)",
		attack_all_warn = "IMPORTANT! Attack All will auto-equip this element upon death.",
		attack_all_notify = "Remember to use the Scythe for max damage.",
		select_element = "SELECT YOUR ELEMENT",
		esp = "PLAYER ESP", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
		speed = "SPEED HACK", speed_val = "SPEED", jump = "SUPER JUMP", jump_val = "JUMP POWER",
		farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Anchors player in the sky and attacks automatically using Energy.",
		tourney_desc = "Stalks the enemy 10 studs behind and above. Ideal for 1v1s.",
		silent_collect = "SILENT AUTO-COLLECT", utilities = "UTILITIES",
		dev_zone = "DEVELOPER ZONE", pass = "TEST PASSWORD", unlock = "UNLOCK TEST", destroy_ui = "DESTROY UI", lang_sel = "CHANGE LANGUAGE", lang_desc = "Select a language and re-execute."
	},
	["fil"] = {
		title = "FROGGY HUB", subtitle = "200 MEMBERS | MEADOW EDITION",
		tab_main = "PANGUNAHIN", tab_combat = "LABANAN", tab_visual = "BISWAL", tab_movement = "GALAW", tab_farm = "AUTO FARM", tab_tourney = "TOURNAMENT", tab_config = "KONFIG",
		rejoin = "SUMALI ULIT", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
		hitbox = "HITBOX EXPANDER", hitbox_size = "LAKI NG HITBOX",
		god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)",
		attack_all_warn = "MAHALAGA! Awtomatikong i-e-equip ang elementong ito kapag namatay.",
		attack_all_notify = "Tandaan na gumamit ng Scythe para sa max damage.",
		select_element = "PUMILI NG ELEMENTO",
		esp = "ESP NG PLAYERS", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
		speed = "SPEED HACK", speed_val = "BILIS", jump = "SUPER JUMP", jump_val = "TAAS NG TALON",
		farm_players = "AUTO FARM PLAYERS (ENERGY)", farm_desc = "Inaayos ang player sa langit at awtomatikong umaatake gamit ang Energy.",
		tourney_desc = "Sinusundan ang kalaban 10 studs sa likod at itaas. Para sa 1v1.",
		silent_collect = "SILENT AUTO-COLLECT", utilities = "UTILITIES",
		dev_zone = "DEV ZONE", pass = "PASSWORD", unlock = "I-UNLOCK", destroy_ui = "IRISAN ANG UI", lang_sel = "PALITAN ANG WIKA", lang_desc = "Pumili ng wika at i-execute ulit."
	},
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
	local ok, savedLang = pcall(function()
		if isfile("FroggyLang.txt") then return readfile("FroggyLang.txt") end
	end)
	if ok and savedLang and Translations[savedLang] then currentLang = savedLang end
end

local function L(key)
	return (Translations[currentLang] and Translations[currentLang][key]) or Translations["en"][key] or key
end

local SharedElements = {
	"energy", "luz", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad",
	"lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido",
	"aurora", "fenix", "caos", "tecnología", "diamante", "amor", "demon",
	"ilusion", "campos de fuerza", "relampago", "telequinesis", "life", "mirror",
	"time", "sueño", "creacion", "espacio", "realidad", "dios de elementos"
}

-- ==========================================
-- 3. DISEÑO Y ASSETS
-- ==========================================
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua?v=" .. os.time()))()
local okAssets, Assets = pcall(function()
	return loadstring(game:HttpGet(ROOT .. "assets.lua?v=" .. os.time()))()
end)
if not okAssets then Assets = nil end

env.BF_UI_LIBRARY = UI_Library
env.BF_ASSETS_LIBRARY = Assets

print("[Main] design.lua version:", UI_Library.Version)

-- design.lua ya NO tiene intro: la ventana abre directamente
local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle") })
env.BF_CURRENT_UI = Window

-- aviso de dispositivo
task.spawn(function()
	task.wait(2)
	if Assets and Assets.Notify then
		if isMobile then
			pcall(Assets.Notify, { Title = "📱 Mobile Detectado", Text = "Evita el ESP y el Farm extremo para no lagear.", Type = "warn", Duration = 6 })
		else
			pcall(Assets.Notify, { Title = "💻 PC Detectado", Text = "Modo de alto rendimiento listo.", Type = "success", Duration = 4 })
		end
	else
		Window:Notify({
			Title = isMobile and "Mobile" or "PC",
			Content = isMobile and "Evita el ESP y el Farm extremo para no lagear." or "Modo de alto rendimiento listo.",
			Type = isMobile and "warning" or "success",
			Duration = 4,
		})
	end
end)

-- ==========================================
-- 4. PESTAÑAS
-- ==========================================
local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabTourney = Window:CreateTab(L("tab_tourney"))
local TabConfig = Window:CreateTab(L("tab_config"))

-- ==========================================
-- 5. DESCARGA DE MÓDULOS
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, key)
	local url = ROOT .. folder .. name .. "?v=" .. os.time()
	local ok, res = pcall(game.HttpGet, game, url)
	if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then
		local fnOk, fn = pcall(loadstring, res)
		if fnOk and type(fn) == "function" then
			local runOk, err = pcall(fn)
			if not runOk then warn("❌ Error ejecutando " .. name .. ": " .. tostring(err)) end
		else
			warn("❌ Error de sintaxis en " .. name)
		end
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
local TourneyC = download("AutoTournament.lua", "BF_TOURNAMENT_CONFIG")

-- ==========================================
-- 6. HELPERS (estado guardado y visibilidad)
-- ==========================================

-- Crea un toggle que guarda su estado y lo restaura al volver a ejecutar.
-- configObj[field] es la bandera del módulo (Enabled, SpeedEnabled, etc.)
local function persistentToggle(tab, text, configObj, field, key, extra)
	local startOn = SavedState[key] == true
	local t = tab:AddToggle(text, startOn, function(state)
		configObj[field] = state
		SavedState[key] = state or nil
		persist()
		if extra then extra(state) end
	end)
	if startOn then
		configObj[field] = true
	end
	return t
end

-- Oculta/muestra un elemento completo (incluye su contenedor, para que
-- el cambio de pestaña no lo vuelva a mostrar y no quede hueco).
local function setElementVisible(el, visible)
	if not el or not el.Instance then return end
	local target = el.Instance.Parent
	if target and target:IsA("GuiObject") then
		target.Visible = visible
	else
		el.Instance.Visible = visible
	end
end

local function notify(title, content, kind)
	if Window.Notify then Window:Notify({ Title = title, Content = content, Type = kind or "info" }) end
end

-- === MAIN ===
TabMain:AddButton(L("rejoin"), function()
	game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- === COMBAT ===
if CombC then
	persistentToggle(TabCombat, L("auto_combat"), CombC, "Enabled", "AutoCombat")
	TabCombat:AddSlider(L("m1_delay"), 0.1, 1.0, CombC.M1Delay or 0.3, function(val) CombC.M1Delay = val end, 0.05)
end

local hitboxSlider = nil
if HitC then
	persistentToggle(TabCombat, L("hitbox"), HitC, "Enabled", "Hitbox")
	hitboxSlider = TabCombat:AddSlider(L("hitbox_size"), 35, 500, 35, function(val) HitC.Size = val end, 1)
	setElementVisible(hitboxSlider, false)
end

if AttackAllC then
	TabCombat:AddSection(L("god_mode"))
	persistentToggle(TabCombat, L("attack_all"), AttackAllC, "Enabled", "AttackAll")

	TabCombat:AddDropdown(L("select_element"), SharedElements, AttackAllC.SelectedElement, function(val)
		AttackAllC.SelectedElement = val
		notify("Element Selected", tostring(val), "success")
	end)

	TabCombat:AddInfo(L("attack_all_warn"))
end

-- === VISUAL ===
if EspC then
	persistentToggle(TabVisual, L("esp"), EspC, "Enabled", "ESP", function(state)
		if isMobile and state then
			notify("⚠️ Mobile", "El ESP puede causar lag en tu celular.", "warning")
		end
	end)
	TabVisual:AddToggle(L("boxes"), EspC.Boxes, function(state) EspC.Boxes = state end)
	TabVisual:AddToggle(L("tracers"), EspC.Tracers, function(state) EspC.Tracers = state end)
	TabVisual:AddToggle(L("health"), EspC.HealthBar, function(state) EspC.HealthBar = state end)
end

-- === MOVEMENT ===
if MoveC then
	persistentToggle(TabMovement, L("speed"), MoveC, "SpeedEnabled", "Speed")
	TabMovement:AddSlider(L("speed_val"), 16, 200, MoveC.Speed or 60, function(val) MoveC.Speed = val end, 1)

	TabMovement:AddToggle(L("jump"), MoveC.JumpEnabled, function(state) MoveC.JumpEnabled = state end)
	TabMovement:AddSlider(L("jump_val"), 50, 300, MoveC.JumpPower or 100, function(val) MoveC.JumpPower = val end, 1)
end

-- === AUTO FARM ===
if FarmC then
	TabFarm:AddSection("AUTO FARM")
	persistentToggle(TabFarm, L("farm_players"), FarmC, "Enabled", "Farm", function(state)
		if state then
			notify("Farm", "Iniciando Farm de Energía...", "success")
		else
			notify("Farm", "Farmeo Detenido.", "warning")
		end
	end)
	TabFarm:AddInfo(L("farm_desc"))
end

-- === AUTO TOURNAMENT ===
if TourneyC then
	TabTourney:AddSection("AUTO TOURNAMENT (1v1)")
	persistentToggle(TabTourney, "AUTO TOURNAMENT", TourneyC, "Enabled", "Tournament", function(state)
		if state then
			notify("Torneo", "Persiguiendo al enemigo...", "success")
		else
			notify("Torneo", "Detenido.", "warning")
		end
	end)
	TabTourney:AddInfo(L("tourney_desc"))
end

-- === CONFIG ===
if SilentCollectC then
	TabConfig:AddSection(L("utilities"))
	-- por defecto activado, salvo que lo hayas apagado antes
	local scOn = SavedState.SilentCollect ~= false
	SilentCollectC.Enabled = scOn
	TabConfig:AddToggle(L("silent_collect"), scOn, function(state)
		SilentCollectC.Enabled = state
		SavedState.SilentCollect = state
		persist()
	end)
end

if HopC then
	TabConfig:AddSection("SEGURIDAD DE SESIÓN")
	TabConfig:AddToggle("AUTO SERVER HOP", HopC.Enabled or false, function(state)
		HopC.Enabled = state
		if state then notify("Server Hop", "El temporizador de seguridad está activo.", "success") end
	end)
	TabConfig:AddSlider("TIEMPO EN SERVIDOR (MIN)", 5, 60, 20, function(val) HopC.HopTime = val * 60 end, 1)
	TabConfig:AddInfo("Si el Auto Farm está activo, cambiará de servidor solo. Si no, te preguntará mediante un panel.")
end

TabConfig:AddSection(L("lang_sel"))
TabConfig:AddDropdown(L("lang_sel"), { "es", "en", "fil" }, currentLang, function(val)
	if writefile then pcall(function() writefile("FroggyLang.txt", val) end) end
	notify("Language", L("lang_desc"), "info")
end)

TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextbox(L("pass"), "", "...", function() end)
local unlockBtn -- se declara antes para poder usarla dentro del callback
unlockBtn = TabConfig:AddButton(L("unlock"), function()
	if passBox:Get() == "froggy_testing_2026" then
		notify("OK", L("dev_zone"), "warning")
		setElementVisible(passBox, false)
		setElementVisible(unlockBtn, false)
		setElementVisible(hitboxSlider, true)
	else
		notify("Error", "Wrong password", "error")
		passBox:Set("")
	end
end)

TabConfig:AddButton(L("destroy_ui"), function()
	Window:Destroy()
	if env.BF_CURRENT_UI == Window then
		env.BF_CURRENT_UI = nil
	end
end)

print("[Main] Froggy Hub cargado con éxito (sin intro).")
