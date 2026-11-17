local _pcall = pcall
local _spawn = task.spawn
local _wait = task.wait
local _clock = os.clock
local _game = game
local _Players = _game:GetService("Players")
local _RunService = _game:GetService("RunService")
local _UserInputService = _game:GetService("UserInputService")
local _CoreGui = _game:GetService("CoreGui")
local _TweenService = _game:GetService("TweenService")
local _HttpService = _game:GetService("HttpService")
local _LocalPlayer = _Players.LocalPlayer
local Logger = {}
local Engine, State
local ThemeManager = {}
local function T(bg,pn,ac,acd,tx,txd,su,er,bk) return {Bg=bg,Panel=pn,Accent=ac,AccentDark=acd,Text=tx,TextDim=txd,Success=su,Error=er,Black=bk} end
local C = Color3.fromRGB
local TopBar = {}
local Themes = {
	DarkRed = T(C(18,8,8),C(28,15,15),C(200,30,30),C(140,20,20),C(255,240,240),C(200,150,150),C(46,204,113),C(231,76,60),C(0,0,0)),
	Black   = T(C(10,10,10),C(20,20,20),C(60,60,60),C(40,40,40),C(255,255,255),C(150,150,150),C(46,204,113),C(231,76,60),C(0,0,0)),
	White   = T(C(240,240,245),C(220,220,225),C(100,100,100),C(80,80,80),C(20,20,20),C(80,80,80),C(39,174,96),C(192,57,43),C(255,255,255)),
	Blue    = T(C(8,12,20),C(15,25,40),C(50,150,255),C(30,100,200),C(240,245,255),C(150,170,200),C(46,204,113),C(231,76,60),C(0,0,0)),
	Green   = T(C(8,18,10),C(15,28,20),C(40,200,80),C(25,140,50),C(240,255,240),C(150,200,160),C(46,204,113),C(231,76,60),C(0,0,0)),
	Rainbow = T(C(12,12,15),C(22,22,28),C(255,0,0),C(150,0,0),C(255,255,255),C(180,180,180),C(46,204,113),C(231,76,60),C(0,0,0)),
}
local CurrentThemeName = (Config and Config.ThemeName) or "Blue"
if not Themes[CurrentThemeName] then CurrentThemeName = "Blue" end
local Theme = Themes[CurrentThemeName]
local RegisteredElements = {}
local RainbowConnection = nil
local RainbowBtnConnection = nil -- NEW: Animation for the Rainbow button

local function PaintObj(obj, role, color)
	if obj:IsA("TextLabel") then obj.TextColor3 = color
	elseif obj:IsA("TextButton") or obj:IsA("TextBox") then
		if role == "Text" or role == "TextDim" or role == "Success" or role == "Error" then obj.TextColor3 = color
		else obj.BackgroundColor3 = color; obj.TextColor3 = Theme.Text end
	elseif obj:IsA("Frame") then obj.BackgroundColor3 = color
	elseif obj:IsA("UIStroke") then obj.Color = color end
end
function ThemeManager.Register(obj, role)
	if typeof(role) ~= "string" then
		if typeof(role) == "Color3" and obj:IsA("GuiObject") then obj.BackgroundColor3 = role end
		return
	end
	table.insert(RegisteredElements, {Object = obj, Role = role})
	if Theme[role] then PaintObj(obj, role, Theme[role]) end
end
function ThemeManager.Apply(themeName)
	CurrentThemeName = themeName
	-- NEW: STOP the animation if a theme other than Rainbow is selected
	if themeName ~= "Rainbow" then
		if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection = nil end
		if RainbowBtnConnection then RainbowBtnConnection:Disconnect(); RainbowBtnConnection = nil end
	end

	if Themes[themeName] then
		Theme = Themes[themeName]
		-- Preserve the custom color if one is set, and also update the background
		if Config and Config.CustomThemeHex and Config.CustomThemeHex ~= "RAINBOW" and #Config.CustomThemeHex == 6 then
			local r = tonumber(Config.CustomThemeHex:sub(1,2), 16) or 50
			local g = tonumber(Config.CustomThemeHex:sub(3,4), 16) or 150
			local b = tonumber(Config.CustomThemeHex:sub(5,6), 16) or 255
			
			local customColor = Color3.fromRGB(r, g, b)
			Theme.Accent = customColor
			Theme.AccentDark = Color3.new(r/255 * 0.6, g/255 * 0.6, b/255 * 0.6)
			Theme.Bg = Color3.new(r/255 * 0.15, g/255 * 0.15, b/255 * 0.15)
			Theme.Panel = Color3.new(r/255 * 0.25, g/255 * 0.25, b/255 * 0.25)
			
			-- NEW: Also update the header gradient
			if State and State.HeaderGradient then
				State.HeaderGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDark),
					ColorSequenceKeypoint.new(0.5, Theme.Panel),
					ColorSequenceKeypoint.new(1, Theme.AccentDark)
				})
			end
		end
	end
	for _, el in ipairs(RegisteredElements) do
		if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object, el.Role, Theme[el.Role]) end
	end
	if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection = nil end
	-- NEW: Also stop the Rainbow button's own animation
	if RainbowBtnConnection then RainbowBtnConnection:Disconnect(); RainbowBtnConnection = nil end

	if themeName == "Rainbow" then
		RainbowConnection = _RunService.RenderStepped:Connect(function()
			local col = Color3.fromHSV(tick() % 1, 0.8, 1)
			local darkCol = Color3.fromHSV(tick() % 1, 0.8, 0.15) -- Dark shade for the background
			
			-- NEW: Also update the header gradient
			if State and State.HeaderGradient then
				State.HeaderGradient.Color = ColorSequence.new(Color3.fromHSV(tick() % 1, 0.8, 0.6), Color3.fromHSV((tick() + 0.5) % 1, 0.8, 0.6))
			end
			
			-- Update all registered elements
			for _, el in ipairs(RegisteredElements) do
				local o = el.Object
				if o and o.Parent then
					if el.Role == "Accent" then
						if o:IsA("UIStroke") then o.Color = col else o.BackgroundColor3 = col end
					elseif el.Role == "Bg" or el.Role == "Panel" or el.Role == "Black" then
						if o:IsA("Frame") then o.BackgroundColor3 = darkCol end
					end
				end
			end
		end)
	end
end

local CONFIG_FILE = "bc_sniper_config.json"

local Config = {
	Enabled = false,
	AutoWrite = false,
	AutoSubmit = false,
	SubmitAfter = 6,
	MaxLogs = 200,
	RiddleCooldownTime = 30,
	AutoSolveRiddles = false,
	ESPEnabled = false,
	ThemeName = "Blue",
	CustomThemeHex = "" -- NEW: Added to save the color
}

-- =====================================================================================
-- CONFIG PRESET SYSTEM (save / load / delete / rename)
-- =====================================================================================
local CONFIG_DIR = "bc_sniper_configs"
local ActivePresetName = "default"

local function EnsureDir()
	if not (writefile and makefolder) then return false end
	if not (isfolder and isfolder(CONFIG_DIR)) then
		local ok = pcall(makefolder, CONFIG_DIR)
		if not ok then return false end
	end
	return true
end

local function SanitizeName(name)
	name = tostring(name or ""):gsub("[^%w_%- ]", ""):match("^%s*(.-)%s*$")
	if name == "" then return nil end
	if #name > 32 then name = name:sub(1, 32) end
	return name
end

local function PresetPath(name)
	local safe = SanitizeName(name)
	if not safe then return nil end
	return CONFIG_DIR .. "/" .. safe .. ".json"
end

local function ListPresets()
	local out = {}
	if not (isfolder and listfiles) then return out end
	if not isfolder(CONFIG_DIR) then return out end
	local ok, files = pcall(listfiles, CONFIG_DIR)
	if not ok or not files then return out end
	for _, f in ipairs(files) do
		local name = f:match("([^/\\]+)%.json$")
		if name then table.insert(out, name) end
	end
	table.sort(out)
	return out
end

-- ✅ DEFINE SaveConfig FIRST (preset functions need it)
local function SaveConfig()
	if not writefile then return end
	-- Copy the Config table and add the active preset name
	local saveData = {}
	for k, v in pairs(Config) do saveData[k] = v end
	saveData.ActivePresetName = ActivePresetName
	
	local ok, encoded = pcall(function() return _HttpService:JSONEncode(saveData) end)
	if ok then pcall(writefile, CONFIG_FILE, encoded) end
end

local function LoadConfig()
	if not (isfile and readfile) then return end
	if not isfile(CONFIG_FILE) then return end
	local ok, data = pcall(readfile, CONFIG_FILE)
	if not ok or not data or data == "" then return end
	local ok2, decoded = pcall(function() return _HttpService:JSONDecode(data) end)
	if not ok2 or type(decoded) ~= "table" then return end
	for k, v in pairs(decoded) do
		if Config[k] ~= nil and type(v) == type(Config[k]) then Config[k] = v end
	end
	-- Load the active preset name if it is saved in the file
	if decoded.ActivePresetName and type(decoded.ActivePresetName) == "string" then
		ActivePresetName = decoded.ActivePresetName
	end
	-- Load the custom color (if present)
	if decoded.CustomThemeHex then
		Config.CustomThemeHex = decoded.CustomThemeHex
	end
end

local function SavePreset(name)
	if not EnsureDir() then return false, "Could not create folder!" end
	local path = PresetPath(name)
	if not path then return false, "Invalid name!" end
	local ok, encoded = pcall(function() return _HttpService:JSONEncode(Config) end)
	if not ok then return false, "Encoding error!" end
	local wok = pcall(writefile, path, encoded)
	if not wok then return false, "Write error!" end
	ActivePresetName = SanitizeName(name)
	return true, "Saved: " .. ActivePresetName
end

local function LoadPreset(name)
	local path = PresetPath(name)
	if not path then return false, "Invalid name!" end
	if not (isfile and isfile(path)) then return false, "Preset not found!" end
	local ok, data = pcall(readfile, path)
	if not ok or not data then return false, "Read error!" end
	local ok2, decoded = pcall(function() return _HttpService:JSONDecode(data) end)
	if not ok2 or type(decoded) ~= "table" then return false, "Corrupted file!" end
	for k, v in pairs(decoded) do
		if Config[k] ~= nil and type(v) == type(Config[k]) then Config[k] = v end
	end
	ActivePresetName = SanitizeName(name)
	SaveConfig()
	return true, "Loaded: " .. ActivePresetName
end

local function DeletePreset(name)
	local path = PresetPath(name)
	if not path then return false, "Invalid name!" end
	if not (isfile and isfile(path)) then return false, "Preset not found!" end
	local ok = pcall(delfile, path)
	if not ok then return false, "Delete error!" end
	if SanitizeName(name) == ActivePresetName then ActivePresetName = "default" end
	return true, "Deleted: " .. SanitizeName(name)
end

local function RenamePreset(oldName, newName)
	local oldPath = PresetPath(oldName)
	local newPath = PresetPath(newName)
	if not oldPath or not newPath then return false, "Invalid name!" end
	if not (isfile and isfile(oldPath)) then return false, "Old preset not found!" end
	if isfile(newPath) then return false, "New name already exists!" end
	local ok, data = pcall(readfile, oldPath)
	if not ok or not data then return false, "Read error!" end
	local wok = pcall(writefile, newPath, data)
	if not wok then return false, "Write error!" end
	pcall(delfile, oldPath)
	if SanitizeName(oldName) == ActivePresetName then ActivePresetName = SanitizeName(newName) end
	return true, "Renamed: " .. SanitizeName(newName)
end

local Keybinds = {
	AutoSubmit = nil,
	AutoWrite = nil,
	Enabled = nil,
	ESPEnabled = nil,
	AutoSolveRiddles = nil,
}
local BindingTarget = nil
local BindingLabelRef = nil

-- ✅ FIX: Keybind persistence (was missing, causing InputBegan to crash)
local KEYBIND_FILE = "bc_sniper_keybinds.json"
local function SaveKeybinds()
	if not writefile then return end
	local ok, encoded = pcall(function() return _HttpService:JSONEncode(Keybinds) end)
	if ok then pcall(writefile, KEYBIND_FILE, encoded) end
end
local function LoadKeybinds()
	if not (isfile and readfile and isfile(KEYBIND_FILE)) then return end
	local ok, data = pcall(readfile, KEYBIND_FILE)
	if not ok or not data or data == "" then return end
	local ok2, decoded = pcall(function() return _HttpService:JSONDecode(data) end)
	if not ok2 or type(decoded) ~= "table" then return end
	for k, v in pairs(decoded) do
		if Keybinds[k] ~= nil and type(v) == "string" then Keybinds[k] = v end
	end
end
LoadKeybinds()

local function ShowNotif(text, success)
	local existing = _CoreGui:FindFirstChild("BCNotif")
	if existing then existing:Destroy() end
	local sg = Instance.new("ScreenGui", _CoreGui)
	sg.Name = "BCNotif"
	sg.ResetOnSpawn = false
	local f = Instance.new("Frame", sg)
	f.Size = UDim2.new(0, 340, 0, 48)
	f.Position = UDim2.new(0.5, -170, 0, 15)
	f.BackgroundColor3 = success and Color3.fromRGB(20,60,20) or Color3.fromRGB(60,20,20)
	f.BorderSizePixel = 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", f)
	stroke.Color = success and Color3.fromRGB(46,204,113) or Color3.fromRGB(231,76,60)
	stroke.Thickness = 1.5
	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, -16, 1, -6)
	lbl.Position = UDim2.new(0, 8, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.TextWrapped = true
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Text = tostring(text)
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	_spawn(function() _wait(2); if sg and sg.Parent then sg:Destroy() end end)
end

LoadConfig()
local KeyCheckRunning = false
-- ESPEnabled is now Config.ESPEnabled (defined above)
local ESPObjects = {}
State = { cooldowns = {}, queue = {}, buffer = "", collectedCount = 0, isWriting = false, isSubmitting = false, gui = nil, main = nil, tabs = {}, activeTab = "Main", statusLabel = nil, progressBar = nil, progressText = nil, logContainer = nil, boxRef = nil, connections = {}, startTime = os.clock(), shutdown = false }
local UIOptions = { Language = "English", Animations = true, Blur = false, Scale = 1 }
local function TranslateUI()
    if not State.gui then return end
    local tr = UIOptions.Language == "Turkish"
    local enToTr = {
        ["Time Left: "]="Kalan Süre: ", ["PANIC"]="ACİL DURDUR", ["Gemini API Key:"]="Gemini API Anahtarı:",
        ["Save"]="Kaydet", ["💾 Save"]="💾 Kaydet", ["Clear API Key"]="API Anahtarını Sil",
        ["Auto-Riddle Solver:"]="Otomatik Bilmece Çözücü:", ["Auto Riddle Solver:"]="Otomatik Bilmece Çözücü:",
        ["Language: English"]="Dil: Türkçe", ["UI Size -"]="Arayüz -", ["UI Size +"]="Arayüz +",
        ["Animations: ON"]="Animasyon: AÇIK", ["Animations: OFF"]="Animasyon: KAPALI",
        ["Blur: ON"]="Bulanıklık: AÇIK", ["Blur: OFF"]="Bulanıklık: KAPALI",
        ["Sniper Active:"]="Sniper Aktif:", ["Auto-Write:"]="Otomatik Yazma:", ["Auto-Submit:"]="Otomatik Gönderim:",
        ["Submit After (X):"]="Kaç Koddan Sonra Gönder:", ["Collected: "]="Toplanan: ", ["System ready..."]="Sistem hazır...",
        ["Main"]="Ana Menü", ["Settings"]="Ayarlar", ["Helpers"]="Araçlar", ["Theme"]="Tema", ["Logs"]="Kayıtlar", ["Active"]="Aktif", ["Keys"]="Lisans",
        ["Helpers & Testing"]="Araçlar ve Test", ["Tester: Rexyqw2"]="Test Kullanıcısı: Rexyqw2",
        ["📋 Show Code History"]="📋 Kod Geçmişini Göster", ["History is empty!"]="Geçmiş boş!",
        ["ESP (Ad + Highlight):"]="ESP (İsim + Vurgu):", ["Preset Colors:"]="Hazır Renkler:",
        ["Custom RGB Settings:"]="Özel RGB Ayarları:", ["Config Manager"]="Yapılandırma Yöneticisi",
        ["Enter API key (hidden after save)"]="API anahtarını gir (kaydedince gizlenir)",
        ["Enter a new API key first"]="Önce yeni bir API anahtarı gir", ["API key cleared"]="API anahtarı silindi",
        ["Gemini key saved!"]="Gemini anahtarı kaydedildi!", ["Gemini key cleared."]="Gemini anahtarı silindi.",
        ["When the riddle solver is enabled, it answers in-game questions using the Gemini API."]="Bilmece çözücü açıldığında oyun içi soruları Gemini API ile yanıtlar.",
        ["preset name (e.g. main)"]="hazır ayar adı (örn. ana)", ["  (no presets)"]="  (hazır ayar yok)",
        ["ON"]="AÇIK", ["OFF"]="KAPALI", ["Active preset: "]="Aktif hazır ayar: ",
        ["Code detected: "]="Kod algılandı: ", ["Question detected: "]="Soru algılandı: ",
        ["Question: "]="Soru: ", ["Answer: "]="Yanıt: ", ["Answer entered: "]="Yanıt girildi: ",
        ["Code: "]="Kod: ", ["Known code found: "]="Bilinen kod bulundu: ", ["Loaded: "]="Yüklendi: ",
        ["Saved: "]="Kaydedildi: ", ["Deleted: "]="Silindi: ", ["Renamed: "]="Yeniden adlandırıldı: ",
        ["New Save: "]="Yeni kayıt: ", ["Overwritten: "]="Üzerine yazıldı: ",
        ["Please enter a valid name!"]="Geçerli bir ad gir!", ["Invalid name!"]="Geçersiz ad!", ["Invalid new name!"]="Yeni ad geçersiz!",
        ["Preset not found!"]="Hazır ayar bulunamadı!", ["Old preset not found!"]="Eski hazır ayar bulunamadı!",
        ["New name already exists!"]="Bu ad zaten mevcut!", ["Could not reach the server!"]="Sunucuya ulaşılamadı!",
        ["Could not connect to the server!"]="Sunucuya bağlanılamadı!", ["HTTP unavailable!"]="HTTP kullanılamıyor!",
        ["API Key missing! Enter in settings."]="API anahtarı eksik! Ayarlardan gir.", ["Checking..."]="Kontrol ediliyor...",
        ["Expired"]="Süresi doldu", ["System Error"]="Sistem Hatası", ["Confirm"]="Onayla", ["Clear"]="Temizle",
        ["Bind"]="Tuş Ata", ["Red (R): "]="Kırmızı (R): ", ["Green (G): "]="Yeşil (G): ", ["Blue (B): "]="Mavi (B): ",
        ["Code History"]="Kod Geçmişi", ["Auto-Submit OFF"]="Otomatik Gönderim KAPALI", ["Code box not found!"]="Kod kutusu bulunamadı!",
        ["Code input box not found!"]="Kod giriş kutusu bulunamadı!", ["No code box!"]="Kod kutusu yok!", ["No active users right now."]="Şu anda aktif kullanıcı yok.",
        ["Could not read the database!"]="Veritabanı okunamadı!", ["Corrupted file!"]="Dosya bozuk!", ["Encoding error!"]="Kodlama hatası!",
        ["Read error!"]="Okuma hatası!", ["Delete error!"]="Silme hatası!", ["Invalid Key (not found on the server)"]="Geçersiz anahtar (sunucuda bulunamadı)",
        ["Success (First Login)"]="Başarılı (İlk Giriş)", ["System Ready. Rexyqw2"]="Sistem Hazır. Rexyqw2", ["Custom RGB Settings:"]="Özel RGB Ayarları:",
        ["🎯 Sniper"]="🎯 Keskin Nişancı", ["⚙️ Settings"]="⚙️ Ayarlar", ["🧰 Helpers"]="🧰 Araçlar", ["🎨 Theme"]="🎨 Tema", ["📜 Logs"]="📜 Kayıtlar", ["👥 Active"]="👥 Aktif Kullanıcılar", ["⌨️ Keybinds"]="⌨️ Tuş Atamaları",
        ["Sniper"]="Keskin Nişancı", ["Theme"]="Tema", ["Logs"]="Kayıtlar", ["Keybinds"]="Tuş Atamaları",
        ["Waiting..."]="Bekleniyor...", ["Checking..."]="Kontrol ediliyor...", ["Verify"]="Doğrula", ["Auto-Submit OFF"]="Otomatik Gönderim KAPALI",
        ["Collected Codes"]="Toplanan Kodlar", ["Collected: 0 / "]="Toplanan: 0 / ", ["Collected: "]="Toplanan: ",
        ["📋 Show Code History"]="📋 Kod Geçmişini Göster", ["--- SUCCESSFULLY COLLECTED CODES ---"]="--- BAŞARIYLA TOPLANAN KODLAR ---",
        ["Active Users"]="Aktif Kullanıcılar", ["No active users right now."]="Şu anda aktif kullanıcı yok.",
        ["Red (R): "]="Kırmızı (R): ", ["Green (G): "]="Yeşil (G): ", ["Blue (B): "]="Mavi (B): ",
        ["Preset Colors:"]="Hazır Renkler:", ["Custom RGB Settings:"]="Özel RGB Ayarları:", ["Config Manager"]="Yapılandırma Yöneticisi",
        ["Save Preset"]="Ayarı Kaydet", ["Load"]="Yükle", ["Delete"]="Sil", ["Rename"]="Yeniden Adlandır", ["Apply"]="Uygula",
        ["No presets"]="Kayıtlı ayar yok", ["(no presets)"]="(kayıtlı ayar yok)", ["Preset name"]="Ayar adı", ["preset name (e.g. main)"]="ayar adı (örn. ana)",
        ["ESP (Ad + Highlight):"]="ESP (İsim + Vurgulama):", ["Auto-Write:"]="Otomatik Yazma:", ["Auto-Submit:"]="Otomatik Gönderim:",
        ["Panic Mode"]="Acil Durdurma", ["PANIC MODE"]="ACİL DURDURMA", ["RightShift / Delete always triggers PANIC MODE."]="RightShift / Delete her zaman ACİL DURDURMA'yı çalıştırır.",
        ["System ready..."]="Sistem hazır...", ["» System ready..."]="» Sistem hazır...", ["Time Left:"]="Kalan Süre:",
        ["Enabled"]="Etkin", ["Disabled"]="Devre Dışı", ["Status"]="Durum", ["Refresh"]="Yenile", ["Reset"]="Sıfırla", ["Close"]="Kapat", ["Cancel"]="İptal",
        ["Active preset: "]="Aktif ayar: ", ["Loaded: "]="Yüklendi: ", ["Saved: "]="Kaydedildi: ", ["Deleted: "]="Silindi: ", ["Renamed: "]="Yeniden adlandırıldı: ",
        ["Enter API key (hidden after save)"]="API anahtarını gir (kaydedince gizlenir)", ["API key cleared"]="API anahtarı silindi", ["Gemini key saved!"]="Gemini anahtarı kaydedildi!",
    }
    local trToEn = {}
    for en, translated in pairs(enToTr) do trToEn[translated] = en end
    for _, obj in ipairs(State.gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj:GetAttribute("BCOriginalText") == nil then obj:SetAttribute("BCOriginalText", obj.Text) end
            local original = obj:GetAttribute("BCOriginalText") or obj.Text
            if obj:IsA("TextBox") then
                if obj:GetAttribute("BCOriginalPlaceholder") == nil then obj:SetAttribute("BCOriginalPlaceholder", obj.PlaceholderText) end
                local ph = obj:GetAttribute("BCOriginalPlaceholder") or obj.PlaceholderText
                if tr then
                    local phMap = { ["Enter API key (hidden after save)"]="API anahtarını gir (kaydedince gizlenir)", ["preset name (e.g. main)"]="hazır ayar adı (örn. ana)", ["FFFFFF"]="FFFFFF" }
                    obj.PlaceholderText = phMap[ph] or ph
                else
                    local reversePH = { ["API anahtarını gir (kaydedince gizlenir)"]="Enter API key (hidden after save)", ["hazır ayar adı (örn. ana)"]="preset name (e.g. main)" }
                    obj.PlaceholderText = reversePH[ph] or ph
                end
            end
            local output = original
            if tr then
                output = enToTr[original] or original
                for en, translated in pairs(enToTr) do
                    if en:sub(-1) == ":" or en:sub(-1) == " " then
                        if original:sub(1, #en) == en then output = translated .. original:sub(#en+1); break end
                    end
                end
            else
                output = trToEn[original] or original
                for translated, en in pairs(trToEn) do
                    if translated:sub(-1) == ":" or translated:sub(-1) == " " then
                        if original:sub(1, #translated) == translated then output = en .. original:sub(#translated+1); break end
                    end
                end
            end
            obj.Text = output
            if obj:IsA("TextButton") then obj.TextScaled = false; obj.TextWrapped = true; obj.TextSize = math.clamp(obj.TextSize, 10, 13) end
        end
    end
end
-- =====================================================================================
-- SETTINGS
-- =====================================================================================
local BLOB_URL = "https://api.npoint.io/86230721e577a71e3d53"
local ANNOUNCE_URL = "https://api.npoint.io/7f1ba4c97e06ce1dd978"
local CodeHistory = {}
local authFile = "bc_sniper_auth.txt"
local geminiFile = "bc_gemini_key.txt"
local ExpiryTimeStamp = 0
local RiddleCooldown = {}
local RiddleQueue = {} -- Yeni: Gelen parçaları biriktirecek
local RiddleQueueTime = 0 -- Yeni: Son parçanın geldiği zaman

local WEBHOOK_URL = "" -- Disabled: never send license keys or HWID to an external webhook.

local BlacklistedPlaces = {
	[131992906944920] = true,
	[73437505877429] = true,
	[110635270173920] = true
}

if BlacklistedPlaces[game.PlaceId] then
	_LocalPlayer:Kick("❌ BC Sniper is blacklisted in this game!")
	return
end

-- =====================================================================================
-- PANIC MODE (Emergency Shutdown)
-- =====================================================================================
local function ClearESP()
	for _, t in pairs(ESPObjects) do
		if t.billboard and t.billboard.Parent then t.billboard:Destroy() end
		if t.highlight and t.highlight.Parent then t.highlight:Destroy() end
	end
	ESPObjects = {}
end

local function ApplyESP(player)
	if not player or player == _LocalPlayer then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Billboard (text above the character)
	local head = char:FindFirstChild("Head") or hrp
	local bb = Instance.new("BillboardGui")
	bb.Name = "ESPBillboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 120, 0, 30)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.Adornee = head
	bb.Parent = char

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "BC SNIPER\n" .. player.Name
	lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)

	-- Highlight
	local hl = Instance.new("Highlight")
	hl.Name = "ESPHighlight"
	hl.FillColor = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.Adornee = char
	hl.Parent = char

	ESPObjects[player.UserId] = { billboard = bb, highlight = hl }
end

local function ToggleESP(state)
	Config.ESPEnabled = state
	if not state then
		ClearESP()
	else
		for _, p in ipairs(_Players:GetPlayers()) do
			ApplyESP(p)
		end
	end
end

local function ActivatePanicMode()
	if State.shutdown then return end
	State.shutdown = true
	State.queue = {}
	State.isWriting = false; State.isSubmitting = false
	
	print("[BC Sniper] PANIC MODE ACTIVATED! Shutting down...")
	-- 1. Disconnect all connections
	for _, conn in pairs(State.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			_pcall(function() conn:Disconnect() end)
		end
	end
	State.connections = {}

	-- 2. Destroy all UI
	local gui = _CoreGui:FindFirstChild("BCSniper") or _LocalPlayer.PlayerGui:FindFirstChild("BCSniper")
	if gui then gui:Destroy() end

	local authGui = _CoreGui:FindFirstChild("BCAuth")
	if authGui then authGui:Destroy() end

	-- 3. Disable all features
	Config.Enabled = false
	Config.AutoWrite = false
	Config.AutoSubmit = false
	Config.AutoSolveRiddles = false
	Config.ESPEnabled = false
	SaveConfig()
	ToggleESP(false)
end

-- Key listener (RightShift or Delete)
-- (Mouse side buttons were removed because Roblox does not support them reliably)


-- CAPTURE MOUSE CLICKS (even when clicking the GUI)
_UserInputService.InputBegan:Connect(function(input, isProcessed)
	-- Binding mode (keyboard)
	if BindingTarget then
		local keyName
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keyName = "Key:" .. tostring(input.KeyCode.Name)
		end
		if keyName then
			Keybinds[BindingTarget] = keyName
			if BindingLabelRef then BindingLabelRef.Text = keyName end
			ShowNotif("✅ Key bound: " .. keyName, true)
			BindingTarget = nil
			BindingLabelRef = nil
			SaveKeybinds()
		end
		return
	end

	-- Don't trigger hotkeys while the user is typing in a TextBox.
	local focusedBox = _UserInputService:GetFocusedTextBox()
	if focusedBox and focusedBox:IsA("TextBox") and focusedBox:IsFocused() then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		_pcall(ActivatePanicMode)
		return
	end

	-- Keybind check
	local function matchInput(bind)
		if not bind then return false end
		local t, v = bind:match("([^:]+):(.+)")
		if t == "Key" then return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == v
		elseif t == "Mouse" then
			local n = tonumber(v)
			if n == 1 then return input.UserInputType == Enum.UserInputType.MouseButton1
			elseif n == 2 then return input.UserInputType == Enum.UserInputType.MouseButton2
			elseif n == 3 then return input.UserInputType == Enum.UserInputType.MouseButton3 end
		end
		return false
	end

	-- ✅ Engine and State are declared later in the script, so we must guard these calls.
if matchInput(Keybinds.AutoSubmit) then
    Config.AutoSubmit = not Config.AutoSubmit
    _pcall(SaveConfig)
    _pcall(function()
        if Engine and Engine.UpdateProgress then Engine.UpdateProgress() end
    end)
    ShowNotif("Auto-Submit: " .. (Config.AutoSubmit and "ON" or "OFF"), Config.AutoSubmit)
    _pcall(function()
        if State and State.RefreshUI then State.RefreshUI() end
    end)
end
	if matchInput(Keybinds.AutoWrite) then
		Config.AutoWrite = not Config.AutoWrite
		_pcall(SaveConfig)
		_pcall(function() if Engine and Engine.ProcessQueue then Engine.ProcessQueue() end end)
		ShowNotif("Auto-Write: " .. (Config.AutoWrite and "ON" or "OFF"), Config.AutoWrite)
		_pcall(function() if State and State.RefreshUI then State.RefreshUI() end end)
	end
	if matchInput(Keybinds.Enabled) then
		Config.Enabled = not Config.Enabled
		_pcall(SaveConfig)
		ShowNotif("Sniper: " .. (Config.Enabled and "ON" or "OFF"), Config.Enabled)
		_pcall(function() if State and State.RefreshUI then State.RefreshUI() end end)
	end
	if matchInput(Keybinds.ESPEnabled) then
		Config.ESPEnabled = not Config.ESPEnabled
		_pcall(function() ToggleESP(Config.ESPEnabled) end)
		_pcall(SaveConfig)
		ShowNotif("ESP: " .. (Config.ESPEnabled and "ON" or "OFF"), Config.ESPEnabled)
	_pcall(function() if State and State.RefreshUI then State.RefreshUI() end end)
	end
	if matchInput(Keybinds.AutoSolveRiddles) then
		Config.AutoSolveRiddles = not Config.AutoSolveRiddles
		_pcall(SaveConfig)
		ShowNotif("Riddle Solver: " .. (Config.AutoSolveRiddles and "ON" or "OFF"), Config.AutoSolveRiddles)
		_pcall(function() if State and State.RefreshUI then State.RefreshUI() end end)
	end
end)

-- =====================================================================================
-- WEBHOOK LOGGING SYSTEM
-- =====================================================================================
local function SendLog(title, desc, color)
    -- Intentionally disabled: authentication details and HWID must not be transmitted or displayed.
    return
end

-- =====================================================================================
-- GEMINI RIDDLE SOLVER ENGINE
-- =====================================================================================
local CurrentGeminiKey = ""

local function GetNextGeminiKey()
	return CurrentGeminiKey
end
-- AutoSolveRiddles is now Config.AutoSolveRiddles (defined above)

local function SolveRiddle(text)
	local low = string.lower(text)

	-- ── AKILLI SAYI YAKALAYICI (Örn: 67, 99, 100) ──────
	-- Sorunun içindeki rakamları bulur ve sonuna eklemek için hafızaya alır.
	local extraNumber = ""
	local numMatch = text:match("%d+") -- Metindeki ilk sayıyı bulur
	if numMatch then
		extraNumber = numMatch
	end

	-- ── DİNAMİK SIRALI ÇOKLU SORU KONTROLÜ ──────
	-- Kelimelerin cümle içindeki geçiş sırasına göre cevap oluşturur.
	local isMulti = false
	local multiAnswer = ""
	
	-- Kontrol edilecek kelimeler ve cevapları
	local terms = {
		{kw = "name", ans = "SAMMY"},
		{kw = "adim", ans = "SAMMY"},
		{kw = "ismim", ans = "SAMMY"},
		{kw = "cat", ans = "NOVA"},
		{kw = "kedi", ans = "NOVA"},
		{kw = "car", ans = "RED"},
		{kw = "araba", ans = "RED"},
		{kw = "age", ans = "24"},
		{kw = "yas", ans = "24"}
	}
	
	-- Her kelimenin cümledeki konumunu (index) bul
	local foundPositions = {}
	for _, t in ipairs(terms) do
		local startIdx, endIdx = low:find(t.kw)
		if startIdx then
			table.insert(foundPositions, {pos = startIdx, ans = t.ans})
		end
	end
	
	-- Eğer birden fazla özel kelime bulunduysa
	if #foundPositions > 1 then
		-- Kelimeleri cümledeki geçiş sırasına göre diz (küçükten büyüğe)
		table.sort(foundPositions, function(a, b) return a.pos < b.pos end)
		
		-- Sırayla cevabı oluştur
		local lastAns = ""
		for _, item in ipairs(foundPositions) do
			-- Aynı cevabın üst üste eklenmesini engelle (örn: "my name and my name")
			if item.ans ~= lastAns then
				multiAnswer = multiAnswer .. item.ans
				lastAns = item.ans
				isMulti = true
			end
		end
	end

	-- Eğer çoklu soru başarıyla oluşturulduysa döndür
	if isMulti and multiAnswer ~= "" then
		if extraNumber ~= "" then
			multiAnswer = multiAnswer .. extraNumber
		end
		Logger.Log("Multi-Question detected (Ordered). Answer: " .. multiAnswer, "success")
		return multiAnswer
	end

	-- ── TEKİL SORU KURALLARI (API Anahtarı GEREKTİRMEZ) ──────
	-- Araç rengi
	if low:find("car color") or low:find("araba rengi") or low:find("vehicle color") then return "RED" .. extraNumber end
	-- Sahip adı
	if low:find("my name") or low:find("adim ne") or low:find("ismim ne") then return "SAMMY" .. extraNumber end
	-- Kedi adı
	if low:find("cat") and (low:find("name") or low:find("called") or low:find("zekan")) then return "NOVA" .. extraNumber end
	-- Yaş
	if low:find("my age") or low:find("how old") or low:find("kac yasinda") then return "24" .. extraNumber end
	-- En iyi OG
	if (low:find("best og") or low:find("en iyi og")) and not low:find("secret") then return "SPYDERELEPHANT" .. extraNumber end
	-- En iyi Secret
	if low:find("best secret") or low:find("en iyi secret") then return "PHOENIX" .. extraNumber end
	-- En iyi Common
	if low:find("best common") or low:find("en iyi common") then return "HOLYAREPA" .. extraNumber end
	-- En iyi DLC/Toy/Plush
	if low:find("best dlc") or low:find("best toy") or low:find("best plush") then return "ARCABROS" .. extraNumber end
	-- En iyi genel brainrot
	if (low:find("best brainrot") or low:find("en iyi brainrot")) and not (low:find("og") or low:find("secret") or low:find("common") or low:find("dlc")) then return "SPYDERELEPHANT" .. extraNumber end

	-- ── GEMINI API KONTROLÜ (Sadece kurallar çalışmadıysa devreye girer) ──
	local activeKey = GetNextGeminiKey()
	if not activeKey or activeKey == "" then
		Logger.Log("API Key missing! Enter in settings.", "error")
		return nil
	end

	-- ── BİLİNEN KODLAR ───────────────────────────────────────────
	local knownCodes = {
		"BESTBRAINROTEVER","GREENHYDRASERPENT19","OCTOBLOCK555","FREEOCTOBLOCK777",
		"WSUMMERUPD1","ILOVEFOOD123","FREEOCTOBASE333W","NEEDTHIS4CRAFT333",
		"FREEPREMIUMOCTO777","CODESAREREAL321","FREEOCTO555","WAVERIDER4FREELOL",
		"CANDY24SAMMY","MAYMEOWLJANDEL","FREE500DRAGS","JOHNPORKDAPIGGY",
		"IMANEGG","PIZZAISYUM","DIVINECURSED","SATURN","OGBRAINROT",
		"HACKEDUPDATE","GATINO75","PUFFINO","AURAUPDATE","SECRET100MS",
		"WOW1MILFAVS","WOW7MILFAVS","ILOVETACOSS"
	}
	for _, code in ipairs(knownCodes) do
		if text:find(code) or text:upper():find(code) then
			Logger.Log("Known code found: " .. code, "success")
			return code
		end
	end

	-- ── STEAL A BRAINROT TAM VERİTABANI (tüm brainrotlar) ───────
	-- Rarity → best pick tablosu (web kaynaklı, güncel)
	local rarityMap = {
		["common"]   = "HOLYAREPA",
		["uncommon"] = "TRALALELO",
		["rare"]     = "BOMBARDIRO",
		["epic"]     = "TUNG TUNG TUNG SAHUR",
		["legendary"]= "BALLERINA CAPPUCCINA",
		["mythic"]   = "BRAINROTGOD",
		["secret"]   = "PHOENIX",
		["og"]       = "SPYDERELEPHANT",
		["dlc"]      = "ARCABROS",
		["toy"]      = "ARCABROS",
		["plush"]    = "ARCABROS",
	}
	for rarity, answer in pairs(rarityMap) do
		if low:find(rarity) then
			Logger.Log("Rarity match ["..rarity.."]: " .. answer, "success")
			return answer
		end
	end

	-- ── GEMİNİ'YE GÖNDERİLECEK DETAYLI PROMPT ──────────────────
	local prompt =
		"You are the ultimate expert on the Roblox game 'Steal a Brainrot'. "..
		"Today is "..os.date("%A, %B %d, %Y")..". "..
		"You have access to the FULL list of every brainrot, pet, mutation, item, and game mechanic that has EVER existed in this game. "..
		"Use web search to find the most up-to-date answer if needed. "..
		"\n\nCRITICAL RULES:\n"..
		"1. MY NAME = SAMMY\n"..
		"2. MY CAT NAME = NOVA\n"..
		"3. MY AGE = 24\n"..
		"4. MY CAR COLOR = RED\n"..
		"5. BEST OG = SPYDERELEPHANT\n"..
		"6. BEST SECRET = PHOENIX\n"..
		"7. BEST COMMON = HOLYAREPA\n"..
		"8. BEST DLC/TOY/PLUSH = ARCABROS\n"..
		"9. For MULTI-QUESTIONS: combine answers in order, NO SPACES, UPPERCASE.\n"..
		"   Example: 'best secret + my name + my age' → PHOENIXSAMMY24\n"..
		"10. Output ONLY the answer: UPPERCASE, NO SPACES, NO PUNCTUATION, NO EXPLANATION.\n"..
		"11. If a brainrot name is asked, return ONLY the brainrot's exact uppercase name.\n"..
		"12. Use your knowledge of ALL brainrots to answer accurately. DO NOT make up names.\n"..
		"\nRiddle: "..text

	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. activeKey
	local body = { 
		contents = { { parts = { { text = prompt } } } },
		tools = { { google_search = {} } } -- Google Arama özelliğini aktif et
	}
	local req = request or http_request or (syn and syn.request)
	if not req then return nil end

	local success, res = pcall(req, {
		Url = url, Method = "POST",
		Headers = {["Content-Type"]="application/json",["x-goog-api-key"]=activeKey},
		Body = _HttpService:JSONEncode(body)
	})

	if success and res and res.StatusCode == 200 then
		local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
		if ok and data.candidates and data.candidates[1] then
			local answer = data.candidates[1].content.parts[1].text
			answer = string.upper(string.gsub(answer, "[^%w]", ""))
			answer = string.sub(answer, 1, 60)
			if answer == "" then Logger.Log("Gemini returned empty!", "error"); return nil end
			Logger.Log("Gemini Answer: " .. answer, "success")
			return answer
		end
	else
		local errBody = (res and res.Body) or "unknown"
		Logger.Log("Gemini Error! Status: "..tostring(res and res.StatusCode).." | "..tostring(errBody):sub(1,60), "error")
	end
	return nil
end

local function LoadGeminiKey()
	if isfile and readfile and isfile(geminiFile) then
		local ok, data = pcall(readfile, geminiFile)
		if ok and data and data ~= "" then CurrentGeminiKey = data end
	end
end

local function SaveGeminiKey(key)
	key = (key or ""):match("^%s*(.-)%s*$")
	CurrentGeminiKey = key
	if writefile then pcall(writefile, geminiFile, key) end
	if key ~= "" then
		Logger.Log("Gemini key saved!", "success")
	else
		Logger.Log("Gemini key cleared.", "info")
	end
end

local function _UnusedSolveRiddleLegacy() -- ölü kod, artık çalışmıyor
	-- En İyi Secret
	if string.find(lowerText, "best secret") or string.find(lowerText, "en iyi secret") then
		Logger.Log("Best Secret detected. Answer: PHOENIX", "success")
		return "PHOENIX"
	end

	-- En İyi Common
	if string.find(lowerText, "best common") or string.find(lowerText, "en iyi common") then
		Logger.Log("Best Common detected. Answer: HOLYAREPA", "success")
		return "HOLYAREPA"
	end

	-- En İyi DLC / Toy
	if (string.find(lowerText, "best dlc") or string.find(lowerText, "best toy") or string.find(lowerText, "best plush")) then
		Logger.Log("Best DLC detected. Answer: ARCABROS", "success")
		return "ARCABROS"
	end

	-- En İyi Genel Brainrot
	if (string.find(lowerText, "best brainrot") or string.find(lowerText, "en iyi brainrot")) and not (string.find(lowerText, "og") or string.find(lowerText, "secret") or string.find(lowerText, "common") or string.find(lowerText, "dlc")) then
		Logger.Log("Best Brainrot detected. Answer: SPYDERELEPHANT", "success")
		return "SPYDERELEPHANT"
	end

	-- 2. QUICK CHECK: Known Codes
	local knownCodes = {
		"BESTBRAINROTEVER", "GREENHYDRASERPENT19", "OCTOBLOCK555", "FREEOCTOBLOCK777", 
		"WSUMMERUPD1", "ILOVEFOOD123", "FREEOCTOBASE333W", "NEEDTHIS4CRAFT333", 
		"FREEPREMIUMOCTO777", "CODESAREREAL321", "FREEOCTO555", "WAVERIDER4FREELOL", 
		"CANDY24SAMMY", "MAYMEOWLJANDEL", "FREE500DRAGS", "JOHNPORKDAPIGGY", 
		"IMANEGG", "PIZZAISYUM", "DIVINECURSED", "SATURN", "OGBRAINROT", 
		"HACKEDUPDATE", "GATINO75", "PUFFINO", "AURAUPDATE", "SECRET100MS", 
		"WOW1MILFAVS", "WOW7MILFAVS", "ILOVETACOSS"
	}
	
	for _, code in ipairs(knownCodes) do
		if string.find(text, code) or string.find(string.upper(text), code) then
			Logger.Log("Known code found: " .. code, "success")
			return code
		end
	end

	-- 3. DETAILED PROMPT TO SEND TO GEMINI (Sammy & Steal a Brainrot Expert)
	local prompt = "You are an advanced AI riddle solver and live database for the Roblox game 'Steal a Brainrot'. Today is " .. os.date("%A, %B %d, %Y") .. ". " ..
	"YOUR TASK: Answer the following riddle accurately. You have access to the entire internet and your training data. If the riddle asks about a specific brainrot, pet, item, or game mechanic, USE YOUR KNOWLEDGE to find the exact correct answer.\n" ..
	"CRITICAL RULES:\n" ..
	"1. If the riddle asks for 'MY NAME', answer 'SAMMY'.\n" ..
	"2. If the riddle asks for 'MY CAT NAME', answer 'NOVA'.\n" ..
	"3. If the riddle asks for 'MY AGE', answer '24'.\n" ..
	"4. KNOWLEDGE BASE: You are a LIVE DATABASE for 'Steal a Brainrot'. You know every single Brainrot, pet, item, mutation, and game mechanic that has EVER existed in the game. If the riddle asks for the 'BEST' brainrot of a specific rarity (Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret, OG), you MUST use your extensive knowledge to find the EXACT correct answer. DO NOT make up fake names. If you are unsure, think harder.\n" ..
	"5. If the riddle is a MULTI-QUESTION (asks for multiple things at once), combine the answers in the order they are asked, without spaces. (Example: 'BEST SECRET BRAINROT MY NAME MY AGE' -> 'PHOENIXSAMMY24').\n" ..
	"6. ALWAYS output the answer in UPPERCASE, with NO SPACES and NO PUNCTUATION.\n" ..
	"Riddle: " .. text
	
	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=" .. activeKey
	local body = { 
		contents = { { parts = { { text = prompt } } } }
	}
	local req = request or http_request or syn.request
	if not req then return nil end

	local headers = {
		["Content-Type"] = "application/json",
		["x-goog-api-key"] = activeKey
	}
	local success, res = pcall(req, {
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = _HttpService:JSONEncode(body)
	})

	if success and res and res.StatusCode == 200 then
		local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
		if ok and data.candidates and data.candidates[1] then
			local answer = data.candidates[1].content.parts[1].text
			-- Clean up: letters and numbers only; limit set to 60 for multiple answers
			answer = string.upper(string.gsub(answer, "[^%w]", ""))
			answer = string.sub(answer, 1, 60)
			if answer == "" then
				Logger.Log("Gemini returned empty!", "error")
				return nil
			end
			Logger.Log("Gemini Answer: " .. answer, "success")
			return answer
		end
	else
		local errBody = (res and res.Body) or "unknown"
		Logger.Log("Gemini Error! Status: "..tostring(res and res.StatusCode).." | "..tostring(errBody):sub(1,60), "error")
	end
	return nil
end

local GAME_NAMES = {
	[6516141723] = "Steal a Brainrot",
	[2788229376] = "Blox Fruits",
	[286090429]  = "Arsenal",
	[606849621]  = "Adopt Me",
}
local function GetGameName(placeId)
	local id = tonumber(placeId)
	if GAME_NAMES[id] then return GAME_NAMES[id] end
	return "PlaceId: " .. tostring(placeId)
end

local function StartHeartbeat()
	_spawn(function()
		while not State.shutdown do
			_pcall(function()
				local req = request or http_request or (syn and syn.request)
				if not req then return end
				-- Önce oku
				local res = req({Url = BLOB_URL, Method = "GET"})
				if not res or res.StatusCode ~= 200 then return end
				local ok, db = pcall(function() return _HttpService:JSONDecode(res.Body) end)
				if not ok or type(db) ~= "table" then db = {} end
				if not db.ActiveUsers then db.ActiveUsers = {} end
				-- Kendini yaz
				db.ActiveUsers[tostring(_LocalPlayer.UserId)] = {
					Name        = _LocalPlayer.Name,
					DisplayName = _LocalPlayer.DisplayName,
					LastSeen    = os.time(),
					PlaceId     = tostring(game.PlaceId),
					GameName    = GetGameName(game.PlaceId),
					JobId       = tostring(game.JobId):sub(1, 8)
				}
				-- 3 dakikadır görülmeyenleri temizle
				for id, data in pairs(db.ActiveUsers) do
					if os.time() - (data.LastSeen or 0) > 180 then
						db.ActiveUsers[id] = nil
					end
				end
				-- Geri yaz
				req({
					Url     = BLOB_URL,
					Method  = "POST",
					Headers = {["Content-Type"] = "application/json"},
					Body    = _HttpService:JSONEncode(db)
				})
			end)
			_wait(30) -- 60'tan 30 saniyeye indirdik, daha anlık
		end
	end)
end



-- =====================================================================================
-- DATABASE AND HWID
-- =====================================================================================
local function GetHWID()
	if gethwid then return gethwid() end
	if game.GetService then 
		local ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
		if ok and id then return id end
	end
	return "unknown_hwid"
end

local function SaveAuth(key) if writefile then pcall(writefile, authFile, key .. "|" .. GetHWID()) end end
local function LoadAuth()
	if isfile and readfile and isfile(authFile) then
		local ok, data = pcall(readfile, authFile)
		if ok and data then
			local sKey, sHwid = data:match("([^|]+)|([^|]+)")
			if sKey and sHwid == GetHWID() then return sKey end
		end
	end
	return nil
end

local function GetDB()
	local req = request or http_request or syn.request
	if not req then return nil, "HTTP unavailable!" end
	local success, res = pcall(req, {Url = BLOB_URL, Method = "GET"})
	if not success then return nil, "Could not reach the server!" end
	if res and res.StatusCode == 200 then
		if res.Body == "null" or res.Body == "" or res.Body == "1" then return {} end
		local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
		if ok then return data end
	end
	return nil, "Could not read the database!"
end

local function SaveDB(data)
	local req = request or http_request or syn.request
	if not req then return end
	pcall(req, {
		Url = BLOB_URL,
		Method = "POST", 
		Headers = {["Content-Type"] = "application/json"},
		Body = _HttpService:JSONEncode(data)
	})
end

-- =====================================================================================
-- KEY AUTH
-- =====================================================================================
local Auth = {}
local function GetRemainingTime()
	if ExpiryTimeStamp == nil or ExpiryTimeStamp == 0 then return "Unlimited" end
	local diff = ExpiryTimeStamp - os.time()
	if diff <= 0 then return "Expired" end
	local d, h, m, s = math.floor(diff/86400), math.floor((diff%86400)/3600), math.floor((diff%3600)/60), diff%60
	if d > 0 then return string.format("%dd %dh %dm", d, h, m)
	elseif h > 0 then return string.format("%dh %dm %ds", h, m, s)
	elseif m > 0 then return string.format("%dm %ds", m, s)
	else return string.format("%ds", s) end
end

function Auth.Verify(key)
	key = string.gsub(key, "%s+", "")
	local db, dbErr = GetDB()
	if not db then return false, dbErr or "Could not connect to the server!" end
	local hwid = GetHWID()
	local keyData = db[key]
	local playerName = _LocalPlayer.Name
	local userId = _LocalPlayer.UserId
	local jobId = game.JobId

	if type(keyData) == "table" then
		if keyData.status == "unused" then
			local new_expiry = 0
			if keyData.duration > 0 then new_expiry = os.time() + keyData.duration end
			db[key] = { status = "used", hwid = hwid, expiry = new_expiry }
			SaveDB(db)
			ExpiryTimeStamp = new_expiry
			SendLog("✅ New Key Used", "**Player:** " .. playerName .. "\n**UserID:** " .. userId .. "\n**Key:** " .. key .. "\n**HWID:** " .. hwid .. "\n**Server:** " .. jobId, 3066993)
			return true, "Success (First Login)"
		else
			if keyData.hwid ~= hwid then
				SendLog("⛔ HWID Mismatch", "**Player:** " .. playerName .. "\n**Key:** " .. key .. "\n**Unauthorized HWID:** " .. hwid, 15158332)
				return false, "This key is linked to another HWID!"
			end
			if keyData.expiry ~= 0 and keyData.expiry <= os.time() then
				SendLog("⏳ Expired Key", "**Player:** " .. playerName .. "\n**Key:** " .. key, 15105570)
				return false, "Expired"
			end
			ExpiryTimeStamp = keyData.expiry
			SendLog("🔑 Login Successful", "**Player:** " .. playerName .. "\n**Key:** " .. key .. "\n**HWID:** " .. hwid, 3447003)
			return true, "Success"
		end
	else
		SendLog("❌ Invalid Key Attempt", "**Player:** " .. playerName .. "\n**Entered Key:** " .. key .. "\n**HWID:** " .. hwid, 15105570)
		return false, "Invalid Key (not found on the server)"
	end
end

function Auth.Build()
	local gui = Instance.new("ScreenGui", _CoreGui)
	gui.Name = "BCAuth"
	local f = Instance.new("Frame", gui)
	f.Size, f.Position, f.BackgroundColor3 = UDim2.new(0,320,0,230), UDim2.new(0.5,-160,0.5,-115), Theme.Bg
	Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
	local stroke = Instance.new("UIStroke", f); stroke.Color = Theme.Accent; stroke.Thickness = 2

	local title = Instance.new("TextLabel", f)
	title.Size, title.Position, title.BackgroundTransparency, title.Text = UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), 1, "BC Sniper | Login"
	title.TextColor3, title.Font, title.TextSize = Theme.Text, Enum.Font.GothamBold, 16

	local box = Instance.new("TextBox", f)
	box.Size, box.Position, box.BackgroundColor3, box.PlaceholderText = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,50), Theme.Panel, "POLSEC-XXXX-XXXX"
	box.TextColor3, box.Font, box.TextSize = Theme.Text, Enum.Font.GothamBold, 14
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

	local btn = Instance.new("TextButton", f)
	btn.Size, btn.Position, btn.BackgroundColor3, btn.Text = UDim2.new(1,-40,0,35), UDim2.new(0,20,0,105), Theme.Success, "Verify"
	btn.Font, btn.TextSize, btn.TextColor3 = Enum.Font.GothamBold, 13, Color3.new(1,1,1)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

	local st = Instance.new("TextLabel", f)
	st.Size, st.Position, st.BackgroundTransparency, st.Text = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,150), 1, "Enter your key."
	st.TextColor3, st.Font, st.TextSize, st.TextWrapped = Theme.TextDim, Enum.Font.Gotham, 11, true

	btn.MouseButton1Click:Connect(function()
		if btn.Text == "Waiting..." then return end
		btn.Text = "Waiting..."
		st.Text = "Checking..." 
		st.TextColor3 = Color3.fromRGB(241, 196, 15)

		task.spawn(function()
			local success, ok, msg = pcall(function() return Auth.Verify(box.Text) end)
			if not success then ok = false msg = "System Error" end

			if ok then
				SaveAuth(box.Text)
				st.Text = "✅ Success! Logging in..." 
				st.TextColor3 = Theme.Success
				task.wait(1) 
				gui:Destroy() 
				Initialize()
			else
				st.Text = "❌ " .. tostring(msg) 
				st.TextColor3 = Theme.Error
				btn.Text = "Verify"
			end
		end)
	end)
end

-- =====================================================================================
-- MOTOR & LOGLAMA
-- =====================================================================================
function Logger.Init(container) State.logContainer = container end
function Logger.Log(text, logType)
	if not State.logContainer then return end
	local color = Theme.TextDim
	local prefix = "[INFO] "
	if logType == "success" then color = Theme.Success; prefix = "[SUCCESS] "
	elseif logType == "error" then color = Theme.Error; prefix = "[ERROR] " end
	local timeStr = string.format("[%02d:%02d]", math.floor((_clock() - State.startTime)/60), math.floor((_clock() - State.startTime)%60))
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16); lbl.BackgroundTransparency = 1; lbl.Text = timeStr .. " " .. prefix .. text
	lbl.TextColor3 = color; lbl.TextSize = 10; lbl.Font = Enum.Font.Code; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = State.logContainer
	local children = State.logContainer:GetChildren()
	if #children > Config.MaxLogs then for i = 1, #children - Config.MaxLogs do if children[i]:IsA("TextLabel") then children[i]:Destroy() end end end
end

local Extractor = {}
local function Sanitize(text) return text and text:gsub("<[^>]->", ""):match("^%s*(.-)%s*$") or "" end
function Extractor.GetCode(text)
	if not text or text == "" then return nil end
	local clean = Sanitize(text)
	if clean:match("^%w+$") then local noSpace = clean:gsub("%s+", ""); if #noSpace >= 3 and #noSpace <= 30 then return noSpace end end
	local parts = {}
	for word in clean:gmatch("%w+") do 
		if #word >= 1 and #word <= 30 and (word:match("%d") or (word == word:upper() and word:match("%a"))) then
			local blacklist = { ["NOTIFICATION"]=true, ["REDEEM"]=true, ["CODES"]=true, ["UPDATE"]=true, ["REWARD"]=true, ["AVAILABLE"]=true, ["YOUR"]=true, ["THE"]=true, ["AND"]=true, ["FOR"]=true }
			if not blacklist[word] then table.insert(parts, word) end
		end
	end
	if #parts > 0 then return table.concat(parts) end
	return nil
end

Engine = {}
function Engine.GetTextBox()
	if State.boxRef and State.boxRef.Parent and State.boxRef.Visible then return State.boxRef end
	State.boxRef = nil
	local pg = _LocalPlayer:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("Codes") and pg.Codes:FindFirstChild("Codes") and pg.Codes.Codes:FindFirstChild("CodeRedeem") then
		local box = pg.Codes.Codes.CodeRedeem:FindFirstChild("TextBox")
		if box and box:IsA("TextBox") then State.boxRef = box; return box end
	end
	return nil
end

function Engine.UpdateProgress()
	local showCount = Config.AutoSubmit and State.collectedCount or 0
	if State.progressText then
		if Config.AutoSubmit then
			State.progressText.Text = string.format("Collected: %d / %d", State.collectedCount, Config.SubmitAfter)
		else
			State.progressText.Text = "Auto-Submit OFF"
		end
	end
	if State.dotContainer then
		for i, dot in ipairs(State.dotContainer:GetChildren()) do
			if dot:IsA("Frame") and dot.Name == "Dot" then
				local filled = i <= showCount
				dot.BackgroundColor3 = filled and Theme.Success or Theme.Panel
			end
		end
	end
end

function Engine.RebuildDots()
	if not State.dotContainer then return end
	for _, c in ipairs(State.dotContainer:GetChildren()) do
		if c:IsA("Frame") and c.Name == "Dot" then c:Destroy() end
	end
	local total = math.max(1, math.min(Config.SubmitAfter, 30))
	for i = 1, total do
		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.Size = UDim2.new(0, 14, 0, 14)
		dot.Position = UDim2.new(0, (i-1) * 18, 0, 0)
		dot.BackgroundColor3 = Theme.Panel
		dot.BorderSizePixel = 0
		dot.Parent = State.dotContainer
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end
	Engine.UpdateProgress()
end

function Engine.Submit()
	if State.isSubmitting then return end
	State.isSubmitting = true

	local codeToSend = State.buffer
	if codeToSend == "" then
		State.isSubmitting = false
		return
	end

	local box = Engine.GetTextBox()
	if box then
		local confirm = box.Parent and box.Parent.Parent and box.Parent.Parent:FindFirstChild("Confirm")
		-- 1) Focus the field and clear it
		_pcall(function() box:CaptureFocus() end)
		_pcall(function() box.Text = "" end)
		-- 2) Type the text
		_pcall(function()
			box.Text = codeToSend
			box.CursorPosition = #codeToSend + 1
		end)
		-- 3) Verify; if any characters were missed, type them again
		if box.Text ~= codeToSend then
			_pcall(function()
				box.Text = codeToSend
				box.CursorPosition = #codeToSend + 1
			end)
			_wait(0.2)
		end
		_pcall(function() box.CursorPosition = #codeToSend + 1 end)
		_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
		-- 4) Check after FocusLost
		if box.Text ~= codeToSend then
			_pcall(function()
				box:CaptureFocus()
				box.Text = codeToSend
				box.CursorPosition = #codeToSend + 1
			end)
			_wait(0.15)
			_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
			_wait(0.1)
		end
		-- 5) Confirm
		if confirm and firesignal then 
			_pcall(firesignal, confirm.MouseButton1Click)
			_pcall(firesignal, confirm.Activated)
		end

		-- 6) ✅ Auto-Submit CLEAR: gönderim sonrası kutuyu temizle (eski kodlar kalmasın)
		_pcall(function()
			box:CaptureFocus()
			box.Text = ""
			box.CursorPosition = 1
			box:ReleaseFocus(false)
		end)
		_wait(0.15)
		-- Eğer oyun kutuyu tekrar doldurduysa bir kez daha temizle
		if box.Text ~= "" then
			_pcall(function()
				box:CaptureFocus()
				box.Text = ""
				box.CursorPosition = 1
				box:ReleaseFocus(false)
			end)
			_wait(0.1)
		end
		-- Buffer ve sayaç zaten aşağıda sıfırlanıyor
		Logger.Log("Written to box: " .. codeToSend, "success")
		
		-- SAVE THE CODE TO THE SUCCESSFULLY COLLECTED HISTORY
		table.insert(CodeHistory, {code = codeToSend, time = os.date("%H:%M:%S")})
		if #CodeHistory > 50 then table.remove(CodeHistory, 1) end
		-- Also save to a file (optional, but useful)
		if writefile then
			local histStr = ""
			for _, h in ipairs(CodeHistory) do histStr = histStr .. h.time .. " - " .. h.code .. "\n" end
			_pcall(writefile, "bc_code_history.txt", histStr)
		end

		State.buffer = ""; State.collectedCount = 0; Engine.UpdateProgress()
		-- ✅ Submit sonrası cooldown'ları temizle (aynı kod hemen tekrar geçsin)
		State.cooldowns = {}
		-- Wait briefly after typing into the box so the game can detect the submission
		_wait(0.5) 
	else
		Logger.Log("Code input box not found!", "error")
	end

	_wait(0.1) 
	State.isSubmitting = false
end

function Engine.ProcessQueue()
	if not Config.Enabled or not Config.AutoWrite or State.isWriting or #State.queue == 0 then return end
	local box = Engine.GetTextBox(); if not box then return end
	State.isWriting = true
	_spawn(function()
		while #State.queue > 0 do
			local currentBox = Engine.GetTextBox()
			if not currentBox then
				Logger.Log("Kod kutusu bulunamadı, queue durdu.", "error")
				break
			end
			local code = table.remove(State.queue, 1); if not code then break end
			-- ✅ Aynı kod buffer'da zaten varsa tekrar ekleme (ama yeni kodsa ekle)
			if State.buffer ~= code then
				State.buffer = State.buffer .. code
			end

			if Config.AutoSubmit then
				State.collectedCount = State.collectedCount + 1
				Engine.UpdateProgress()
				if State.collectedCount < Config.SubmitAfter then
					_pcall(function()
						currentBox:CaptureFocus()
						currentBox.Text = State.buffer
						currentBox.CursorPosition = #State.buffer + 1
					end)
					_pcall(function() currentBox:ReleaseFocus(false) end)
					else
					Engine.Submit()
					break
				end
			else
				_pcall(function()
					currentBox:CaptureFocus()
					currentBox.Text = State.buffer
					currentBox.CursorPosition = #State.buffer + 1
				end)
				_pcall(function() currentBox:ReleaseFocus(false) end)
			end
		end
		State.isWriting = false
	end)
end
local SeenTexts = {}
local STARTUP_GRACE = 3   -- ignore the first 3 seconds after the script starts
local SEEN_TTL = 60       -- do not process the same text again within 60 seconds
local scriptStart = _clock()
local WatchedGuis = {}

local function IsReallyVisible(obj)
	local cur = obj
	while cur and cur ~= game do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		if cur:IsA("ScreenGui") and not cur.Enabled then return false end
		cur = cur.Parent
	end
	return true
end

local function IsFresh(text)
	local now = _clock()
	if now - scriptStart < STARTUP_GRACE then SeenTexts[text] = now; return false end
	local t = SeenTexts[text]
	if t and now - t < SEEN_TTL then return false end
	SeenTexts[text] = now
	return true
end
-- =====================================================================================
-- EVENT LISTENER (QUESTION OR CODE)
-- =====================================================================================
local Events = {}
function Events.StartWatcher()
	_spawn(function()
		local pg = _LocalPlayer:WaitForChild("PlayerGui", 10); if not pg then return end

		local function WatchGui(guiInst)
			local conn = guiInst.DescendantAdded:Connect(function(obj)
				if not Config.Enabled then return end
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					local function checkAndQueue()
						local rawText = obj.Text
						if not rawText or rawText == "" then return end
                        
						-- NEW: Wait 1 second because the game types the question one character at a time
						local currentText = rawText
						_spawn(function()
							if obj.Text ~= currentText then return end -- Cancel if the text changed during this time
							
							local foundCode = Extractor.GetCode(rawText)
						
							-- Riddle Solver (Parçalı Gelen Soruları Birleştirir)
							if Config.AutoSolveRiddles and (#rawText > 5 or rawText:find("%?") or rawText:lower():find("name") or rawText:lower():find("age") or rawText:lower():find("car") or rawText:lower():find("color")) then
								
								-- Gelen parçayı hafızaya ekle
								table.insert(RiddleQueue, rawText)
								RiddleQueueTime = _clock()
								
								-- Bekleme süresini başlat (Oyun 3 kelimelik parçaları arka arkaya yollasın diye)
								_spawn(function()
									_wait(1.5) -- 1.5 saniye bekle
									
									-- Eğer bu süre zarfında yeni parça gelmediyse (süre dolduysa) VE hafızada soru varsa:
									if _clock() - RiddleQueueTime >= 1.4 and #RiddleQueue > 0 then
										
										-- Hafızadaki tüm parçaları tek bir cümle gibi birleştir
										local fullText = table.concat(RiddleQueue, " ")
										RiddleQueue = {} -- Hafızayı temizle
										
										-- Cooldown kontrolü (aynı soru tekrar gelmesin diye)
										if RiddleCooldown[fullText] and _clock() < RiddleCooldown[fullText] then return end
										RiddleCooldown[fullText] = _clock() + 30
										
										_spawn(function()
											Logger.Log("Question: " .. fullText:sub(1,60), "success")
											local answer = SolveRiddle(fullText)
											if answer then
												if setclipboard then _pcall(setclipboard, answer) end
												local box = Engine.GetTextBox()
												if box then
													-- 1) Focus the field and clear its contents
													_pcall(function() box:CaptureFocus() end)
													_wait(0.1)
													_pcall(function() box.Text = "" end)
													_wait(0.08)
													-- 2) Type the text
													_pcall(function()
														box.Text = answer
														box.CursorPosition = #answer + 1
													end)
													_wait(0.2)
													-- 3) Verify
													if box.Text ~= answer then
														_pcall(function()
															box.Text = answer
															box.CursorPosition = #answer + 1
														end)
														_wait(0.2)
													end
													-- 4) Move cursor to end and release focus
													_pcall(function() box.CursorPosition = #answer + 1 end)
													_wait(0.08)
													_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
													_wait(0.15)
													-- 5) Fix if last char lost
													if box.Text ~= answer then
														_pcall(function()
															box:CaptureFocus()
															box.Text = answer
															box.CursorPosition = #answer + 1
														end)
														_wait(0.15)
														_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
														_wait(0.1)
													end
													-- 6) Confirm
													local confirm = box.Parent and box.Parent.Parent and box.Parent.Parent:FindFirstChild("Confirm")
													if confirm then
														if firesignal then _pcall(firesignal, confirm.MouseButton1Click); _pcall(firesignal, confirm.Activated) end
														_pcall(function() local vgui = confirm:FindFirstChildWhichIsA("TextButton") or confirm; if vgui and vgui:IsA("TextButton") then vgui:MouseButton1Click() end end)
													end
													Logger.Log("Answer: " .. answer, "success")
												else Logger.Log("No code box!", "error") end
											end
										end)
									end
								end)
								return
							end
							
							-- Code Processing
							if foundCode then
								-- ✅ Aynı kod arka arkaya gelse bile geçir (cooldown kaldırıldı)
								-- Sadece 0.5 saniye içinde aynı kod gelirse engelle (spam koruması)
								if State.cooldowns[foundCode] and _clock() < State.cooldowns[foundCode] then return end
								State.cooldowns[foundCode] = _clock() + 0.5
								if setclipboard then _pcall(setclipboard, foundCode) end
								
								-- SAVE CODE TO HISTORY
								table.insert(CodeHistory, {code = foundCode, time = os.date("%H:%M:%S")})
								if #CodeHistory > 50 then table.remove(CodeHistory, 1) end
								_pcall(function() if State.RefreshCodeHistory then State.RefreshCodeHistory() end end)
								
								-- ✅ DÜZELTME: Auto-Submit kapalı olsa bile Auto-Write açıksa kutuya yaz!
								if not Config.AutoSubmit then
									Logger.Log("Code (Auto-Submit Off): " .. foundCode, "info")
									if Config.AutoWrite then
										table.insert(State.queue, foundCode)
										Engine.ProcessQueue()
									end
									return
								end
								
								Logger.Log("Code: " .. foundCode, "success")
								table.insert(State.queue, foundCode); Engine.ProcessQueue()
							end
						end) -- closes _spawn callback
					end -- closes checkAndQueue callback
					obj:GetPropertyChangedSignal("Text"):Connect(function() _pcall(checkAndQueue) end); _pcall(checkAndQueue)
				end
			end)
			table.insert(State.connections, conn)
		end

		-- WATCH ONLY TopNotification
		local topNotif = pg:WaitForChild("TopNotification", 10)
		if topNotif then 
			WatchGui(topNotif) 
		else
			Logger.Log("TopNotification GUI not found; codes may not be detected!", "error")
		end
	end)
end

function Events._StartWatcher_OLD()
	_spawn(function()
		local pg = _LocalPlayer:WaitForChild("PlayerGui", 10); if not pg then return end
		local topNotif = pg:WaitForChild("TopNotification", 20); if not topNotif then return end
		local conn = topNotif.DescendantAdded:Connect(function(obj)
			if not Config.Enabled then return end
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				local function checkAndQueue()
					local rawText = obj.Text
					if not rawText or rawText == "" then return end

					local foundCode = Extractor.GetCode(rawText)

					-- RIDDLE SOLVER CHECK
					if Config.AutoSolveRiddles and (#rawText > 20 or rawText:find("%?") or rawText:find("[Ww]hat") or rawText:find("[Hh]ow") or rawText:find("[Ww]hich") or rawText:find("[Ww]hen")) then
						if RiddleCooldown[rawText] and _clock() < RiddleCooldown[rawText] then return end
						RiddleCooldown[rawText] = _clock() + 8

						_spawn(function()
							Logger.Log("Question detected: " .. rawText:sub(1,40), "info")
							local answer = SolveRiddle(rawText)
							if answer then
								if setclipboard then _pcall(setclipboard, answer) end
								-- Submit directly
								local box = Engine.GetTextBox()
								if box then
									_pcall(function()
										box:CaptureFocus()
										box.Text = answer
										box.CursorPosition = #answer + 1
									end)
									_wait(0.2)
									_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
									_wait(0.1)
									local confirm = box.Parent and box.Parent.Parent and box.Parent.Parent:FindFirstChild("Confirm")
									if confirm then
										if firesignal then
											_pcall(firesignal, confirm.MouseButton1Click)
											_pcall(firesignal, confirm.Activated)
										end
										_pcall(function()
											local vgui = confirm:FindFirstChildWhichIsA("TextButton") or confirm
											if vgui and vgui:IsA("TextButton") then
												vgui:MouseButton1Click()
											end
										end)
									end
									Logger.Log("Answer entered: " .. answer, "success")
								else
									Logger.Log("Code box not found!", "error")
								end
							end
						end)
						return
					end

					-- NORMAL CODE PROCESSING
					if foundCode then
						if State.cooldowns[foundCode] and _clock() < State.cooldowns[foundCode] then return end
						State.cooldowns[foundCode] = _clock() + 2.0
						if setclipboard then _pcall(setclipboard, foundCode) end
						Logger.Log("Code detected: " .. foundCode, "success")
						-- Add to history
						table.insert(CodeHistory, {code = foundCode, time = os.date("%H:%M:%S")})
						if #CodeHistory > 50 then table.remove(CodeHistory, 1) end
						-- Save to a file
						if writefile then
							local histStr = ""
							for _, h in ipairs(CodeHistory) do
								histStr = histStr .. h.time .. " - " .. h.code .. "\n"
							end
							_pcall(writefile, "bc_code_history.txt", histStr)
						end
						table.insert(State.queue, foundCode); Engine.ProcessQueue()
					end
				end
				obj:GetPropertyChangedSignal("Text"):Connect(function() _pcall(checkAndQueue) end); _pcall(checkAndQueue)
			end
		end)
		table.insert(State.connections, conn)
	end)
end

-- =====================================================================================
-- UI LIBRARY & MENU
-- =====================================================================================
local UILib = {}

-- Custom Color Picker Component
function UILib.CreateColorPicker(parent, labelText, currentColor, yPos, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 35)
	row.Position = UDim2.new(0, 0, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent = parent
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Theme.Text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	local colorBtn = Instance.new("TextButton")
	colorBtn.Size = UDim2.new(0, 30, 0, 30)
	colorBtn.Position = UDim2.new(1, -30, 0, 2)
	colorBtn.BackgroundColor3 = currentColor
	colorBtn.Text = ""
	colorBtn.AutoButtonColor = false
	colorBtn.Parent = row
	Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke", colorBtn)
	stroke.Color = Theme.Text
	stroke.Thickness = 1
	
	colorBtn.MouseButton1Click:Connect(function()
		-- Simple Hex color input (TextBox)
		local oldText = colorBtn.Text
		colorBtn.Text = "Hex: #FFFFFF"
		colorBtn.TextColor3 = Theme.Black
		colorBtn.TextSize = 8
		
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 1, 0)
		box.BackgroundTransparency = 1
		box.Text = ""
		box.PlaceholderText = "FFFFFF"
		box.TextColor3 = Theme.Black
		box.Font = Enum.Font.Code
		box.TextSize = 10
		box.Parent = colorBtn
		box:CaptureFocus()
		
		box.FocusLost:Connect(function()
			local hex = box.Text:gsub("#", "")
			if #hex == 6 then
				local r = tonumber(hex:sub(1,2), 16) or 255
				local g = tonumber(hex:sub(3,4), 16) or 255
				local b = tonumber(hex:sub(5,6), 16) or 255
				local newColor = Color3.fromRGB(r, g, b)
				colorBtn.BackgroundColor3 = newColor
				callback(newColor)
			end
			box:Destroy()
			colorBtn.Text = ""
		end)
	end)
	return row
end

function UILib.CreateFrame(parent, size, pos, role, cornerRadius)
	local frame = Instance.new("Frame"); frame.Size = size; frame.Position = pos; frame.BorderSizePixel = 0; frame.Parent = parent
	if cornerRadius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, cornerRadius); c.Parent = frame end
	ThemeManager.Register(frame, role); return frame
end
function UILib.CreateLabel(parent, text, size, pos, role, font, textSize)
	local label = Instance.new("TextLabel"); label.Size = size; label.Position = pos; label.BackgroundTransparency = 1; label.Text = text; label.Font = font or Enum.Font.GothamSemibold; label.TextSize = textSize or 13; label.TextWrapped = true; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = parent
	ThemeManager.Register(label, role); return label
end
function UILib.CreateButton(parent, text, size, pos, role, callback)
	local btn = Instance.new("TextButton"); btn.Size = size; btn.Position = pos; btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.TextScaled = false; btn.TextWrapped = true; btn.AutoButtonColor = false; btn.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
	ThemeManager.Register(btn, role); ThemeManager.Register(btn, "Text"); btn.MouseButton1Click:Connect(callback); return btn
end
local AllToggles = {}

function UILib.CreateToggle(parent, labelText, defaultState, yPos, callback)
	defaultState = defaultState == true
	local row = UILib.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yPos), "Bg")
	UILib.CreateLabel(row, labelText, UDim2.new(1, -100, 1, 0), UDim2.new(0, 8, 0, 0), "Text")
	local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 80, 0, 26); btn.Position = UDim2.new(1, -80, 0, 2); btn.Text = defaultState and "ON" or "OFF"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.AutoButtonColor = false; btn.Parent = row
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
	btn.BackgroundColor3 = defaultState and Theme.Success or Theme.Error
	local state = defaultState
	
	table.insert(AllToggles, {
		Label = labelText,
		Button = btn,
		SetState = function(newState)
			state = newState
			btn.Text = state and "ON" or "OFF"
			btn.BackgroundColor3 = state and Theme.Success or Theme.Error
		end
	})

	btn.MouseButton1Click:Connect(function() 
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Theme.Success or Theme.Error
		callback(state) 
	end)
	return row
end

local Menu = {}
function Menu.Build()
	local old = _CoreGui:FindFirstChild("BCSniper") or _LocalPlayer.PlayerGui:FindFirstChild("BCSniper")
	if old then old:Destroy() end
	State.gui = Instance.new("ScreenGui")
	State.gui.Name = "BCSniper"
	State.gui.ResetOnSpawn = false
	_pcall(function() State.gui.Parent = _CoreGui end)
	if not State.gui.Parent then State.gui.Parent = _LocalPlayer.PlayerGui end

	local BAR_H=36; local PANEL_W=480; local PANEL_H=500; local CORNER=10; local ANIM=0.28
	local isOpen = false

	-- ── TOP BAR
	local topBar=Instance.new("Frame"); topBar.Name="BCTopBar"
	topBar.Size=UDim2.new(0,PANEL_W,0,BAR_H)
	topBar.Position=UDim2.new(0.5,-PANEL_W/2,0,0)
	topBar.BackgroundColor3=Color3.fromRGB(10,10,15)
	topBar.BorderSizePixel=0; topBar.Active=true; topBar.Draggable=true
	topBar.Parent=State.gui
	-- Top bar sürüklenince paneli de birlikte hareket ettir
	local _lastBarPos = topBar.Position
	topBar:GetPropertyChangedSignal("Position"):Connect(function()
		local delta = topBar.Position - _lastBarPos
		_lastBarPos = topBar.Position
		if panel and panel.Parent then
			panel.Position = panel.Position + delta
		end
	end)
	Instance.new("UICorner",topBar).CornerRadius=UDim.new(0,CORNER)
	local barStroke=Instance.new("UIStroke",topBar); barStroke.Thickness=2
	ThemeManager.Register(barStroke,"Accent")
	local mainScale=Instance.new("UIScale",State.gui)
	mainScale.Name="BCSniperUIScale"; mainScale.Scale=UIOptions.Scale

	local titleLbl=Instance.new("TextLabel",topBar)
	titleLbl.Size=UDim2.new(0,160,1,0); titleLbl.Position=UDim2.new(0,10,0,0)
	titleLbl.BackgroundTransparency=1; titleLbl.Text="⚡ BC SNIPER // V2"
	titleLbl.TextColor3=Color3.fromRGB(0,220,255)
	titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=13
	titleLbl.TextXAlignment=Enum.TextXAlignment.Left

	local timeLbl=Instance.new("TextLabel",topBar)
	timeLbl.Size=UDim2.new(0,100,1,0); timeLbl.Position=UDim2.new(0,170,0,0)
	timeLbl.BackgroundTransparency=1; timeLbl.Text="⏱ "..GetRemainingTime()
	timeLbl.TextColor3=Theme.Success; timeLbl.Font=Enum.Font.Code; timeLbl.TextSize=10
	timeLbl.TextXAlignment=Enum.TextXAlignment.Left

	local function makeBarBtn(txt,xRight,col,cb)
		local b=Instance.new("TextButton",topBar)
		b.Size=UDim2.new(0,30,0,24); b.Position=UDim2.new(1,-xRight,0,6)
		b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.new(1,1,1)
		b.Font=Enum.Font.GothamBold; b.TextSize=11; b.AutoButtonColor=false
		Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
		b.MouseButton1Click:Connect(cb); return b
	end

	makeBarBtn("X",36,Color3.fromRGB(200,30,30),function()
		State.shutdown=true
		for _,c in pairs(State.connections) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end
		State.gui:Destroy()
	end)
	makeBarBtn("!",72,Color3.fromRGB(200,30,30),function() ActivatePanicMode() end)

	local sizeDownBtn=makeBarBtn("-",108,Theme.Panel,function()
		UIOptions.Scale=math.max(0.75,math.floor((UIOptions.Scale-0.1)*10+0.5)/10)
		local ms=State.gui:FindFirstChild("BCSniperUIScale",true)
		if ms then ms.Scale=UIOptions.Scale end
	end)
	local sizeUpBtn=makeBarBtn("+",138,Theme.Panel,function()
		UIOptions.Scale=math.min(1.35,math.floor((UIOptions.Scale+0.1)*10+0.5)/10)
		local ms=State.gui:FindFirstChild("BCSniperUIScale",true)
		if ms then ms.Scale=UIOptions.Scale end
	end)

	-- ok butonu
	local arrowBtn=Instance.new("TextButton",topBar)
	arrowBtn.Size=UDim2.new(0,30,0,24); arrowBtn.Position=UDim2.new(1,-174,0,6)
	arrowBtn.BackgroundColor3=Theme.Panel; arrowBtn.Text="▼"
	arrowBtn.TextColor3=Color3.new(1,1,1); arrowBtn.Font=Enum.Font.GothamBold
	arrowBtn.TextSize=11; arrowBtn.AutoButtonColor=false
	Instance.new("UICorner",arrowBtn).CornerRadius=UDim.new(0,6)
	arrowBtn.Parent=topBar

	-- ── ANA PANEL (topBar'ın altında açılır)
	local panel=Instance.new("Frame")
	panel.Name="BCPanel"
	panel.Size=UDim2.new(0,PANEL_W,0,PANEL_H)
	panel.Position=UDim2.new(0.5,-PANEL_W/2,0,BAR_H)
	panel.BackgroundColor3=Color3.fromRGB(10,10,15)
	panel.BorderSizePixel=0; panel.ClipsDescendants=true
	panel.Visible=false; panel.Parent=State.gui
	Instance.new("UICorner",panel).CornerRadius=UDim.new(0,CORNER)
	local panelStroke=Instance.new("UIStroke",panel); panelStroke.Thickness=2
	ThemeManager.Register(panelStroke,"Accent")
	State.main=panel

	-- Top bar sürüklenince paneli de birlikte hareket ettir
	local _lastBarPos = topBar.Position
	topBar:GetPropertyChangedSignal("Position"):Connect(function()
		local delta = topBar.Position - _lastBarPos
		_lastBarPos = topBar.Position
		if panel and panel.Parent then
			panel.Position = panel.Position + delta
		end
	end)

	-- panel aç/kapat animasyon
	local function togglePanel()
		isOpen=not isOpen
		arrowBtn.Text=isOpen and "▲" or "▼"
		panel.Visible=true
		if isOpen then
			panel.Size=UDim2.new(0,PANEL_W,0,0)
			_TweenService:Create(panel,TweenInfo.new(ANIM,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
				{Size=UDim2.new(0,PANEL_W,0,PANEL_H)}):Play()
		else
			_TweenService:Create(panel,TweenInfo.new(ANIM,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
				{Size=UDim2.new(0,PANEL_W,0,0)}):Play()
			task.delay(ANIM,function() if not isOpen then panel.Visible=false end end)
		end
	end
	arrowBtn.MouseButton1Click:Connect(togglePanel)

	-- zaman güncelle
	_spawn(function()
		while State.gui and State.gui.Parent do
			timeLbl.Text="⏱ "..GetRemainingTime()
			if GetRemainingTime()=="Expired" then
				Config.Enabled=false; Config.AutoWrite=false; Config.AutoSubmit=false
				Config.AutoSolveRiddles=false; Config.ESPEnabled=false
				ClearESP(); SaveConfig()
				for _,c in pairs(State.connections) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end
				State.connections={}; State.gui:Destroy()
				if isfile and isfile(authFile) then pcall(delfile,authFile) end
				Auth.Build(); break
			end
			_wait(1)
		end
	end)

	-- ── SIDEBAR + İÇERİK
	local sidebar=UILib.CreateFrame(panel,UDim2.new(0,130,1,0),UDim2.new(0,0,0,0),"Panel")
	local tabContainer=UILib.CreateFrame(sidebar,UDim2.new(1,-10,1,-10),UDim2.new(0,5,0,5),"Bg")
	local contentArea=UILib.CreateFrame(panel,UDim2.new(1,-130,1,0),UDim2.new(0,130,0,0),"Bg")
	local pages={}
	local SwitchTab
	local function CreatePage(name)
		local p=Instance.new("ScrollingFrame")
		p.Size=UDim2.new(1,-20,1,-20); p.Position=UDim2.new(0,10,0,10)
		p.BorderSizePixel=0; p.BackgroundColor3=Theme.Bg; p.BackgroundTransparency=0
		p.ScrollBarThickness=4; p.ScrollBarImageColor3=Theme.Accent
		p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y
		p.ScrollingDirection=Enum.ScrollingDirection.Y
		p.ClipsDescendants=true; p.Visible=false; p.Parent=contentArea
		ThemeManager.Register(p,"Bg"); pages[name]=p; return p
	end

	local pageMain=CreatePage("Main")
	State.statusLabel=UILib.CreateLabel(pageMain,"» System ready...",UDim2.new(1,-20,0,20),UDim2.new(0,10,1,-45),"TextDim",Enum.Font.Gotham,10)
	State.statusLabel.TextXAlignment=Enum.TextXAlignment.Center
	UILib.CreateLabel(pageMain,"by Beko",UDim2.new(1,-20,0,15),UDim2.new(0,0,1,-20),"AccentDark",Enum.Font.GothamBold,11).TextXAlignment=Enum.TextXAlignment.Center

	local y=0
	UILib.CreateToggle(pageMain,"Sniper Active:",Config.Enabled,y,function(v) Config.Enabled=v; SaveConfig() end); y=y+35
	UILib.CreateToggle(pageMain,"Auto-Write:",Config.AutoWrite,y,function(v) Config.AutoWrite=v; SaveConfig(); Engine.ProcessQueue() end); y=y+35
	UILib.CreateToggle(pageMain,"Auto-Submit:",Config.AutoSubmit,y,function(v) Config.AutoSubmit=v; SaveConfig(); Engine.UpdateProgress() end); y=y+40
	UILib.CreateToggle(pageMain,"Auto-Riddle Solver:",Config.AutoSolveRiddles,y,function(v) Config.AutoSolveRiddles=v; SaveConfig() end); y=y+35
	local countRow=UILib.CreateFrame(pageMain,UDim2.new(1,0,0,30),UDim2.new(0,0,0,y),"Bg")
	UILib.CreateLabel(countRow,"Submit After (X):",UDim2.new(1,-100,1,0),UDim2.new(0,8,0,0),"Text")
	local countBox=Instance.new("TextBox"); countBox.Size=UDim2.new(0,80,0,26); countBox.Position=UDim2.new(1,-80,0,2)
	countBox.Text=tostring(Config.SubmitAfter); countBox.Font=Enum.Font.GothamBold; countBox.TextSize=12
	countBox.ClearTextOnFocus=false; countBox.Parent=countRow
	ThemeManager.Register(countBox,"Panel"); ThemeManager.Register(countBox,"Text")
	Instance.new("UICorner",countBox).CornerRadius=UDim.new(0,6)
	countBox.FocusLost:Connect(function() local n=tonumber(countBox.Text) or 1; if n<1 then n=1 end; Config.SubmitAfter=n; countBox.Text=tostring(n); State.collectedCount=0; State.buffer=""; Engine.RebuildDots(); SaveConfig() end)
	y=y+40
	State.dotContainer=Instance.new("Frame"); State.dotContainer.Size=UDim2.new(1,0,0,16)
	State.dotContainer.Position=UDim2.new(0,8,0,y); State.dotContainer.BackgroundTransparency=1; State.dotContainer.Parent=pageMain; y=y+20
	State.progressText=UILib.CreateLabel(pageMain,"Collected: 0 / "..Config.SubmitAfter,UDim2.new(1,0,0,15),UDim2.new(0,8,0,y),"TextDim",Enum.Font.GothamBold,10)
	y=y+25; Engine.RebuildDots()

	-- SETTINGS
	local pageSettings=CreatePage("Settings")
	local sy=0
	local animBtn
	local langBtn; langBtn=UILib.CreateButton(pageSettings,"Language: English",UDim2.new(0.49,-3,0,27),UDim2.new(0,0,0,sy),"Panel",function()
		UIOptions.Language=UIOptions.Language=="English" and "Turkish" or "English"
		langBtn.Text=UIOptions.Language=="English" and "Language: English" or "Dil: Türkçe"
		TranslateUI()
	end)
	sy=sy+33
	animBtn=UILib.CreateButton(pageSettings,"Animations: ON",UDim2.new(0.49,-3,0,27),UDim2.new(0,0,0,sy),"Panel",function()
		UIOptions.Animations=not UIOptions.Animations
		animBtn.Text=UIOptions.Animations and "Animations: ON" or "Animations: OFF"
	end); sy=sy+36
	UILib.CreateLabel(pageSettings,"Gemini API Key:",UDim2.new(1,0,0,16),UDim2.new(0,0,0,sy),"Text",Enum.Font.GothamBold,11); sy=sy+18
	local apiBox=Instance.new("TextBox"); apiBox.Size=UDim2.new(1,0,0,28); apiBox.Position=UDim2.new(0,0,0,sy)
	apiBox.BackgroundColor3=Theme.Panel; apiBox.PlaceholderText="Enter Gemini API key here"
	apiBox.Text=""; apiBox.TextColor3=Theme.Text; apiBox.Font=Enum.Font.Code; apiBox.TextSize=12
	apiBox.ClearTextOnFocus=false; apiBox.Parent=pageSettings
	Instance.new("UICorner",apiBox).CornerRadius=UDim.new(0,6); sy=sy+36
	UILib.CreateButton(pageSettings,"Save",UDim2.new(0.48,-3,0,28),UDim2.new(0,0,0,sy),"Success",function()
		if apiBox.Text and apiBox.Text:match("%S") then SaveGeminiKey(apiBox.Text); apiBox.Text="" else ShowNotif("Enter a new API key first",false) end
	end)
	UILib.CreateButton(pageSettings,"Clear API Key",UDim2.new(0.48,-3,0,28),UDim2.new(0.52,3,0,sy),"Error",function()
		SaveGeminiKey(""); apiBox.Text=""; ShowNotif("API key cleared",true)
	end); sy=sy+42


	
	UILib.CreateLabel(pageSettings,"── Config Manager ──",UDim2.new(1,0,0,18),UDim2.new(0,0,0,sy),"Accent",Enum.Font.GothamBold,12); sy=sy+24
	local nameRow=UILib.CreateFrame(pageSettings,UDim2.new(1,0,0,30),UDim2.new(0,0,0,sy),"Bg")
	local cfgNameBox=Instance.new("TextBox"); cfgNameBox.Size=UDim2.new(1,-90,0,28); cfgNameBox.Position=UDim2.new(0,0,0,1)
	cfgNameBox.BackgroundColor3=Theme.Panel; cfgNameBox.PlaceholderText="preset name (e.g. main)"
	cfgNameBox.Text=ActivePresetName or "default"; cfgNameBox.TextColor3=Theme.Text
	cfgNameBox.Font=Enum.Font.GothamBold; cfgNameBox.TextSize=12; cfgNameBox.ClearTextOnFocus=false; cfgNameBox.Parent=nameRow
	Instance.new("UICorner",cfgNameBox).CornerRadius=UDim.new(0,6)
	local saveBtn=Instance.new("TextButton"); saveBtn.Size=UDim2.new(0,80,0,28); saveBtn.Position=UDim2.new(1,-80,0,1)
	saveBtn.BackgroundColor3=Theme.Success; saveBtn.Text="💾 Save"; saveBtn.TextColor3=Color3.new(1,1,1)
	saveBtn.Font=Enum.Font.GothamBold; saveBtn.TextSize=11; saveBtn.AutoButtonColor=false; saveBtn.Parent=nameRow
	Instance.new("UICorner",saveBtn).CornerRadius=UDim.new(0,6); sy=sy+36
	local listFrame=UILib.CreateFrame(pageSettings,UDim2.new(1,0,0,120),UDim2.new(0,0,0,sy),"Black",6)
	local listScroll=Instance.new("ScrollingFrame"); listScroll.Size=UDim2.new(1,-6,1,-6); listScroll.Position=UDim2.new(0,3,0,3)
	listScroll.BackgroundTransparency=1; listScroll.ScrollBarThickness=3; listScroll.CanvasSize=UDim2.new(0,0,0,0)
	listScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; listScroll.Parent=listFrame
	local listLayout=Instance.new("UIListLayout"); listLayout.Padding=UDim.new(0,2); listLayout.Parent=listScroll
	local function RefreshPresetList()
		for _,c in ipairs(listScroll:GetChildren()) do if c:IsA("Frame") and c.Name=="PresetRow" then c:Destroy() end end
		local presets=ListPresets()
		if #presets==0 then
			local empty=Instance.new("TextLabel"); empty.Name="PresetRow"; empty.Size=UDim2.new(1,0,0,24)
			empty.BackgroundTransparency=1; empty.Text="  (no presets)"; empty.TextColor3=Theme.TextDim
			empty.Font=Enum.Font.Gotham; empty.TextSize=11; empty.TextXAlignment=Enum.TextXAlignment.Left; empty.Parent=listScroll; return
		end
		for _,pname in ipairs(presets) do
			local row=Instance.new("Frame"); row.Name="PresetRow"; row.Size=UDim2.new(1,-4,0,26)
			row.BackgroundColor3=(pname==ActivePresetName) and Theme.Panel or Theme.Bg; row.BorderSizePixel=0; row.Parent=listScroll
			Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
			local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-180,1,0); lbl.Position=UDim2.new(0,8,0,0)
			lbl.BackgroundTransparency=1; lbl.Text=(pname==ActivePresetName and "● " or "○ ")..pname
			lbl.TextColor3=(pname==ActivePresetName) and Theme.Success or Theme.Text
			lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
			local function miniBtn(text,xOff,color,cb)
				local b=Instance.new("TextButton",row); b.Size=UDim2.new(0,50,0,22); b.Position=UDim2.new(1,xOff,0,2)
				b.BackgroundColor3=color; b.Text=text; b.TextColor3=Color3.new(1,1,1)
				b.Font=Enum.Font.GothamBold; b.TextSize=10; b.AutoButtonColor=false
				Instance.new("UICorner",b).CornerRadius=UDim.new(0,4); b.MouseButton1Click:Connect(cb); return b
			end
			miniBtn("📂 Load",-160,Theme.Accent,function()
				local ok,msg=LoadPreset(pname); Logger.Log(msg,ok and "success" or "error")
				if ok then cfgNameBox.Text=pname; SaveConfig(); if State.RefreshUI then State.RefreshUI() end; RefreshPresetList() end
			end)
			miniBtn("✏️ Rename",-108,Color3.fromRGB(180,130,40),function()
				local ok,msg=RenamePreset(pname,cfgNameBox.Text); Logger.Log(msg,ok and "success" or "error")
				if ok then RefreshPresetList() end
			end)
			miniBtn("🗑 Delete",-54,Theme.Error,function()
				local ok,msg=DeletePreset(pname); Logger.Log(msg,ok and "success" or "error")
				if ok then RefreshPresetList() end
			end)
		end
	end
	saveBtn.MouseButton1Click:Connect(function()
		local tn=cfgNameBox.Text; if tn=="" or not SanitizeName(tn) then Logger.Log("Please enter a valid name!","error"); return end
		local isOv=isfile and isfile(PresetPath(tn))
		local ok,msg=SavePreset(tn)
		if ok then Logger.Log(isOv and ("Overwritten: "..tn) or ("New Save: "..tn),"success"); RefreshPresetList() else Logger.Log(msg,"error") end
	end)
	RefreshPresetList(); sy=sy+128
	UILib.CreateLabel(pageSettings,"Riddle solver uses Gemini API for in-game questions.",UDim2.new(1,0,0,40),UDim2.new(0,0,0,sy),"TextDim",Enum.Font.Gotham,10)

	-- HELPERS
	local pageHelpers=CreatePage("Helpers")
	UILib.CreateLabel(pageHelpers,"Helpers & Testing",UDim2.new(1,0,0,20),UDim2.new(0,0,0,0),"Accent",Enum.Font.GothamBold,14)
	local testerBox=UILib.CreateFrame(pageHelpers,UDim2.new(1,0,0,40),UDim2.new(0,0,0,30),"Panel",8)
	UILib.CreateLabel(testerBox,"Tester: Rexyqw2",UDim2.new(1,-20,1,0),UDim2.new(0,10,0,0),"Success",Enum.Font.Code,14)
	-- Code History (canlı liste, Helpers içinde)
	UILib.CreateLabel(pageHelpers,"📜 Kod Geçmişi (canlı):",UDim2.new(1,0,0,18),UDim2.new(0,0,0,182),"Accent",Enum.Font.GothamBold,12)
	local histFrame = UILib.CreateFrame(pageHelpers, UDim2.new(1,0,0,140), UDim2.new(0,0,0,204), "Black", 6)
	local histScroll = Instance.new("ScrollingFrame")
	histScroll.Size = UDim2.new(1,-6,1,-6); histScroll.Position = UDim2.new(0,3,0,3)
	histScroll.BackgroundTransparency = 1; histScroll.ScrollBarThickness = 3
	histScroll.CanvasSize = UDim2.new(0,0,0,0); histScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	histScroll.Parent = histFrame
	local histLayout = Instance.new("UIListLayout"); histLayout.Padding = UDim.new(0,2); histLayout.Parent = histScroll
	State.codeHistoryList = histScroll

	State.RefreshCodeHistory = function()
		if not State.codeHistoryList then return end
		for _,c in ipairs(State.codeHistoryList:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		if #CodeHistory == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1,0,0,20); empty.BackgroundTransparency = 1
			empty.Text = "  (henüz kod yakalanmadı)"; empty.TextColor3 = Theme.TextDim
			empty.Font = Enum.Font.Gotham; empty.TextSize = 11
			empty.TextXAlignment = Enum.TextXAlignment.Left; empty.Parent = State.codeHistoryList
			return
		end
		-- En yeniden eskiye
		for i = #CodeHistory, 1, -1 do
			local h = CodeHistory[i]
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1,-6,0,18); lbl.BackgroundTransparency = 1
			lbl.Text = string.format("[%s]  %s", h.time, h.code)
			lbl.TextColor3 = Theme.Success
			lbl.Font = Enum.Font.Code; lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = State.codeHistoryList
		end
	end
	State.RefreshCodeHistory()

	-- Clear butonu
	UILib.CreateButton(pageHelpers,"🗑 Geçmişi Temizle",UDim2.new(0.49,-3,0,26),UDim2.new(0,0,0,355),"Error",function()
		CodeHistory = {}
		if State.RefreshCodeHistory then State.RefreshCodeHistory() end
	end)
	UILib.CreateToggle(pageHelpers,"ESP (Ad + Highlight):",Config.ESPEnabled,390,function(v) Config.ESPEnabled=v; SaveConfig(); ToggleESP(v) end)

	-- THEME
	local pageTheme=CreatePage("Theme")
	local ty=0
	UILib.CreateLabel(pageTheme,"Preset Colors:",UDim2.new(1,0,0,20),UDim2.new(0,0,0,ty),"Accent",Enum.Font.GothamBold,14); ty=ty+25
	local colorsGrid=UILib.CreateFrame(pageTheme,UDim2.new(1,0,0,100),UDim2.new(0,0,0,ty),"Bg")
	local presetColors={Color3.fromRGB(255,255,255),Color3.fromRGB(255,50,50),Color3.fromRGB(50,150,255),Color3.fromRGB(46,204,113),Color3.fromRGB(155,89,182),Color3.fromRGB(241,196,15),Color3.fromRGB(230,126,34),Color3.fromRGB(231,76,60),Color3.fromRGB(52,152,219),Color3.fromRGB(26,188,156),Color3.fromRGB(22,160,133),Color3.fromRGB(39,174,96),Color3.fromRGB(142,68,173),Color3.fromRGB(255,105,180),Color3.fromRGB(255,165,0),Color3.fromRGB(0,255,255),Color3.fromRGB(255,215,0),Color3.fromRGB(138,43,226),Color3.fromRGB(220,20,60),Color3.fromRGB(0,191,255),Color3.fromRGB(50,205,50)}
	local cx2,cy2=0,0
	for _,color in ipairs(presetColors) do
		local cBtn=Instance.new("TextButton",colorsGrid); cBtn.Size=UDim2.new(0,28,0,28); cBtn.Position=UDim2.new(0,cx2,0,cy2)
		cBtn.BackgroundColor3=color; cBtn.Text=""; cBtn.AutoButtonColor=false
		Instance.new("UICorner",cBtn).CornerRadius=UDim.new(0,4)
		local cs=Instance.new("UIStroke",cBtn); cs.Color=Theme.Text; cs.Thickness=1
		cBtn.MouseButton1Click:Connect(function()
			local r2,g2,b2=math.floor(color.R*255),math.floor(color.G*255),math.floor(color.B*255)
			Config.CustomThemeHex=string.format("%02X%02X%02X",r2,g2,b2)
			CurrentThemeName="Blue"
			if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection=nil end
			if RainbowBtnConnection then RainbowBtnConnection:Disconnect(); RainbowBtnConnection=nil end
			Theme.Accent=color
			if r2>200 and g2>200 and b2>200 then
				Theme.Bg=Color3.fromRGB(240,240,245); Theme.Panel=Color3.fromRGB(220,220,225)
				Theme.Text=Color3.fromRGB(20,20,20); Theme.TextDim=Color3.fromRGB(80,80,80); Theme.AccentDark=Color3.fromRGB(150,150,150)
			else
				Theme.AccentDark=Color3.new(color.R*0.6,color.G*0.6,color.B*0.6)
				Theme.Bg=Color3.new(color.R*0.15,color.G*0.15,color.B*0.15)
				Theme.Panel=Color3.new(color.R*0.25,color.G*0.25,color.B*0.25)
				Theme.Text=Color3.fromRGB(255,255,255); Theme.TextDim=Color3.fromRGB(150,150,150)
			end
			for _,el in ipairs(RegisteredElements) do if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object,el.Role,Theme[el.Role]) end end
			SaveConfig()
		end)
		cx2=cx2+32; if cx2>280 then cx2=0; cy2=cy2+32 end
	end
	local rbBtn=Instance.new("TextButton",colorsGrid); rbBtn.Size=UDim2.new(0,28,0,28); rbBtn.Position=UDim2.new(0,cx2,0,cy2)
	rbBtn.BackgroundColor3=Color3.fromRGB(255,0,128); rbBtn.Text=""; rbBtn.AutoButtonColor=false
	Instance.new("UICorner",rbBtn).CornerRadius=UDim.new(0,4)
	_spawn(function() while rbBtn and rbBtn.Parent do rbBtn.BackgroundColor3=Color3.fromHSV(tick()%1,0.8,1); _wait(0.1) end end)
	rbBtn.MouseButton1Click:Connect(function() Config.CustomThemeHex="RAINBOW"; SaveConfig(); ThemeManager.Apply("Rainbow") end)
	ty=ty+110
	UILib.CreateLabel(pageTheme,"Custom RGB Settings:",UDim2.new(1,0,0,20),UDim2.new(0,0,0,ty),"Accent",Enum.Font.GothamBold,14); ty=ty+25
	local cR,cG,cB=math.floor(Theme.Accent.R*255),math.floor(Theme.Accent.G*255),math.floor(Theme.Accent.B*255)
	local function ApplyRGB2()
		local hex=string.format("%02X%02X%02X",cR,cG,cB); Config.CustomThemeHex=hex
		CurrentThemeName="Blue"
		if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection=nil end
		local color=Color3.fromRGB(cR,cG,cB); Theme.Accent=color
		Theme.AccentDark=Color3.new(color.R*0.6,color.G*0.6,color.B*0.6)
		Theme.Bg=Color3.new(color.R*0.15,color.G*0.15,color.B*0.15)
		Theme.Panel=Color3.new(color.R*0.25,color.G*0.25,color.B*0.25)
		for _,el in ipairs(RegisteredElements) do if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object,el.Role,Theme[el.Role]) end end
		SaveConfig()
	end
	local rLbl=UILib.CreateLabel(pageTheme,"Red (R): "..cR,UDim2.new(1,0,0,16),UDim2.new(0,0,0,ty),"Text",Enum.Font.Gotham,11); ty=ty+18
	local rBar=Instance.new("TextButton"); rBar.Size=UDim2.new(1,0,0,6); rBar.Position=UDim2.new(0,0,0,ty); rBar.BackgroundColor3=Theme.Panel; rBar.Text=""; rBar.Parent=pageTheme; ty=ty+12
	local rFill=Instance.new("Frame",rBar); rFill.Size=UDim2.new(cR/255,0,1,0); rFill.BackgroundColor3=Color3.fromRGB(255,50,50); rFill.BorderSizePixel=0
	rBar.MouseButton1Down:Connect(function() local function u() local mx=_UserInputService:GetMouseLocation(); local rx=math.clamp((mx.X-rBar.AbsolutePosition.X)/rBar.AbsoluteSize.X,0,1); cR=math.floor(rx*255); rFill.Size=UDim2.new(rx,0,1,0); rLbl.Text="Red (R): "..cR; ApplyRGB2() end; u(); local conn; conn=_RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then u() else conn:Disconnect() end end) end)
	local gLbl=UILib.CreateLabel(pageTheme,"Green (G): "..cG,UDim2.new(1,0,0,16),UDim2.new(0,0,0,ty),"Text",Enum.Font.Gotham,11); ty=ty+18
	local gBar=Instance.new("TextButton"); gBar.Size=UDim2.new(1,0,0,6); gBar.Position=UDim2.new(0,0,0,ty); gBar.BackgroundColor3=Theme.Panel; gBar.Text=""; gBar.Parent=pageTheme; ty=ty+12
	local gFill=Instance.new("Frame",gBar); gFill.Size=UDim2.new(cG/255,0,1,0); gFill.BackgroundColor3=Color3.fromRGB(50,255,50); gFill.BorderSizePixel=0
	gBar.MouseButton1Down:Connect(function() local function u() local mx=_UserInputService:GetMouseLocation(); local rx=math.clamp((mx.X-gBar.AbsolutePosition.X)/gBar.AbsoluteSize.X,0,1); cG=math.floor(rx*255); gFill.Size=UDim2.new(rx,0,1,0); gLbl.Text="Green (G): "..cG; ApplyRGB2() end; u(); local conn; conn=_RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then u() else conn:Disconnect() end end) end)
	local bLbl=UILib.CreateLabel(pageTheme,"Blue (B): "..cB,UDim2.new(1,0,0,16),UDim2.new(0,0,0,ty),"Text",Enum.Font.Gotham,11); ty=ty+18
	local bBar=Instance.new("TextButton"); bBar.Size=UDim2.new(1,0,0,6); bBar.Position=UDim2.new(0,0,0,ty); bBar.BackgroundColor3=Theme.Panel; bBar.Text=""; bBar.Parent=pageTheme; ty=ty+12
	local bFill=Instance.new("Frame",bBar); bFill.Size=UDim2.new(cB/255,0,1,0); bFill.BackgroundColor3=Color3.fromRGB(50,50,255); bFill.BorderSizePixel=0
	bBar.MouseButton1Down:Connect(function() local function u() local mx=_UserInputService:GetMouseLocation(); local rx=math.clamp((mx.X-bBar.AbsolutePosition.X)/bBar.AbsoluteSize.X,0,1); cB=math.floor(rx*255); bFill.Size=UDim2.new(rx,0,1,0); bLbl.Text="Blue (B): "..cB; ApplyRGB2() end; u(); local conn; conn=_RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then u() else conn:Disconnect() end end) end)

	-- LOGS
	local pageLogs=CreatePage("Logs")
	UILib.CreateButton(pageLogs,"🗑 Clear Logs",UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),"Error",function()
		if State.logContainer then for _,c in ipairs(State.logContainer:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end end
	end)
	local logFrame=UILib.CreateFrame(pageLogs,UDim2.new(1,0,1,-34),UDim2.new(0,0,0,32),"Black",6)
	local logScroll=Instance.new("ScrollingFrame"); logScroll.Size=UDim2.new(1,-6,1,-6); logScroll.Position=UDim2.new(0,3,0,3)
	logScroll.BackgroundTransparency=1; logScroll.ScrollBarThickness=3; logScroll.CanvasSize=UDim2.new(0,0,0,0)
	logScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; logScroll.ScrollingDirection=Enum.ScrollingDirection.Y; logScroll.Parent=logFrame
	local logInner=UILib.CreateFrame(logScroll,UDim2.new(1,-4,0,0),UDim2.new(0,2,0,0),"Black")
	logInner.AutomaticSize=Enum.AutomaticSize.Y
	local logLayout=Instance.new("UIListLayout"); logLayout.Padding=UDim.new(0,2); logLayout.Parent=logInner
	logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() logScroll.CanvasPosition=Vector2.new(0,logScroll.AbsoluteCanvasSize.Y) end)
	Logger.Init(logInner)

	-- ACTIVE
	local pageActive=CreatePage("Active")
	local activeHeader=UILib.CreateLabel(pageActive,"🟢 Aktif: ... kullanıcı",UDim2.new(0.6,0,0,26),UDim2.new(0,0,0,0),"Success",Enum.Font.GothamBold,12)
	State.activeCountLabel=activeHeader
	UILib.CreateButton(pageActive,"🔄 Yenile",UDim2.new(0.38,0,0,26),UDim2.new(0.62,0,0,0),"Panel",function() if State.RefreshActiveUsers then State.RefreshActiveUsers() end end)
	local activeFrame=UILib.CreateFrame(pageActive,UDim2.new(1,0,1,-34),UDim2.new(0,0,0,32),"Black",6)
	local activeScroll=Instance.new("ScrollingFrame"); activeScroll.Size=UDim2.new(1,-6,1,-6); activeScroll.Position=UDim2.new(0,3,0,3)
	activeScroll.BackgroundTransparency=1; activeScroll.ScrollBarThickness=3; activeScroll.CanvasSize=UDim2.new(0,0,0,0)
	activeScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; activeScroll.Parent=activeFrame
	Instance.new("UIListLayout",activeScroll).Padding=UDim.new(0,2)
	State.activeUsersList=activeScroll
	State.RefreshActiveUsers = function()
		if not State.activeUsersList then return end
		for _, c in ipairs(State.activeUsersList:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
		end

		local req = request or http_request or (syn and syn.request)
		local activeSet = {}

		-- DB'den çek
		if req then
			_pcall(function()
				local res = req({Url = BLOB_URL, Method = "GET"})
				if res and res.StatusCode == 200 then
					local ok, db = pcall(function() return _HttpService:JSONDecode(res.Body) end)
					if ok and db and db.ActiveUsers then
						for uid, data in pairs(db.ActiveUsers) do
							if os.time() - (data.LastSeen or 0) <= 180 then
								activeSet[uid] = data
							end
						end
					end
				end
			end)
		end

		-- Kendini her zaman ekle
		activeSet[tostring(_LocalPlayer.UserId)] = {
			Name        = _LocalPlayer.Name,
			DisplayName = _LocalPlayer.DisplayName,
			LastSeen    = os.time(),
			PlaceId     = tostring(game.PlaceId),
			GameName    = GetGameName(game.PlaceId),
			JobId       = tostring(game.JobId):sub(1, 8)
		}

		local count = 0
		for uid, data in pairs(activeSet) do
			count = count + 1
			local isMe = uid == tostring(_LocalPlayer.UserId)

			local row = Instance.new("Frame", State.activeUsersList)
			row.Size = UDim2.new(1, -4, 0, 48)
			row.BackgroundColor3 = isMe and Color3.fromRGB(20, 40, 20) or Color3.fromRGB(15, 15, 25)
			row.BorderSizePixel = 0
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
			local rs = Instance.new("UIStroke", row)
			rs.Thickness = 1
			rs.Color = isMe and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 50, 80)

			-- İsim
			local nameLbl = Instance.new("TextLabel", row)
			nameLbl.Size = UDim2.new(1, -10, 0, 18)
			nameLbl.Position = UDim2.new(0, 8, 0, 4)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = (isMe and "● " or "○ ") .. count .. ". " .. (data.Name or "?") .. (isMe and " (sen)" or "")
			nameLbl.TextColor3 = isMe and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(220, 220, 220)
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 11
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left

			-- Oyun adı
			local gameLbl = Instance.new("TextLabel", row)
			gameLbl.Size = UDim2.new(1, -10, 0, 14)
			gameLbl.Position = UDim2.new(0, 8, 0, 20)
			gameLbl.BackgroundTransparency = 1
			gameLbl.Text = "🎮 " .. (data.GameName or GetGameName(data.PlaceId or "0"))
			gameLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
			gameLbl.Font = Enum.Font.GothamBold
			gameLbl.TextSize = 10
			gameLbl.TextXAlignment = Enum.TextXAlignment.Left

			-- Server ID
			local infoLbl = Instance.new("TextLabel", row)
			infoLbl.Size = UDim2.new(1, -10, 0, 12)
			infoLbl.Position = UDim2.new(0, 8, 0, 34)
			infoLbl.BackgroundTransparency = 1
			infoLbl.Text = "Server: " .. (data.JobId or "?")
			infoLbl.TextColor3 = Color3.fromRGB(80, 80, 120)
			infoLbl.Font = Enum.Font.Code
			infoLbl.TextSize = 9
			infoLbl.TextXAlignment = Enum.TextXAlignment.Left
		end

		if count == 0 then
			local lbl = Instance.new("TextLabel", State.activeUsersList)
			lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.BackgroundTransparency = 1
			lbl.Text = "Şu an aktif kullanıcı yok."
			lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
		end

		if State.activeCountLabel then
			State.activeCountLabel.Text = "🟢 Aktif: " .. count .. " kullanıcı"
		end
	end
	-- otomatik yenileme kapalı, sadece butonla yenilenir

	-- KEYBINDS
	local pageKeys=CreatePage("Keys")
	UILib.CreateLabel(pageKeys,"⌨️ Keybinds",UDim2.new(1,0,0,20),UDim2.new(0,0,0,0),"Accent",Enum.Font.GothamBold,14)
	UILib.CreateLabel(pageKeys,"Press [Bind] then press your desired key.",UDim2.new(1,0,0,26),UDim2.new(0,0,0,22),"TextDim",Enum.Font.Gotham,10)
	local bindItems={{label="Toggle Sniper",key="Enabled"},{label="Toggle Auto-Write",key="AutoWrite"},{label="Toggle Auto-Submit",key="AutoSubmit"},{label="Toggle ESP",key="ESPEnabled"},{label="Toggle Riddle Solver",key="AutoSolveRiddles"}}
	local ky=55
	for _,item in ipairs(bindItems) do
		local row=Instance.new("Frame",pageKeys); row.Size=UDim2.new(1,0,0,36); row.Position=UDim2.new(0,0,0,ky)
		row.BackgroundColor3=Color3.fromRGB(15,15,25); row.BorderSizePixel=0
		Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
		local rs=Instance.new("UIStroke",row); rs.Thickness=1; ThemeManager.Register(rs,"Accent")
		local nl=Instance.new("TextLabel",row); nl.Size=UDim2.new(0,130,1,0); nl.Position=UDim2.new(0,8,0,0)
		nl.BackgroundTransparency=1; nl.Text=item.label; nl.TextColor3=Color3.fromRGB(220,220,220)
		nl.Font=Enum.Font.GothamBold; nl.TextSize=10; nl.TextXAlignment=Enum.TextXAlignment.Left
		local kl=Instance.new("TextLabel",row); kl.Size=UDim2.new(0,80,1,0); kl.Position=UDim2.new(0,142,0,0)
		kl.BackgroundTransparency=1; kl.Text=Keybinds[item.key] or "None"; kl.TextColor3=Color3.fromRGB(0,200,255)
		kl.Font=Enum.Font.Code; kl.TextSize=10; kl.TextXAlignment=Enum.TextXAlignment.Left
		local ab=Instance.new("TextButton",row); ab.Size=UDim2.new(0,45,0,26); ab.Position=UDim2.new(1,-115,0,5)
		ab.BackgroundColor3=Color3.fromRGB(50,150,255); ab.Text="Bind"; ab.TextColor3=Color3.new(1,1,1)
		ab.Font=Enum.Font.GothamBold; ab.TextSize=11; ab.AutoButtonColor=false
		Instance.new("UICorner",ab).CornerRadius=UDim.new(0,6)
		local sb=Instance.new("TextButton",row); sb.Size=UDim2.new(0,45,0,26); sb.Position=UDim2.new(1,-60,0,5)
		sb.BackgroundColor3=Color3.fromRGB(200,30,30); sb.Text="Clear"; sb.TextColor3=Color3.new(1,1,1)
		sb.Font=Enum.Font.GothamBold; sb.TextSize=11; sb.AutoButtonColor=false
		Instance.new("UICorner",sb).CornerRadius=UDim.new(0,6)
		local ck,cl=item.key,kl
		ab.MouseButton1Click:Connect(function()
			BindingTarget=ck; BindingLabelRef=cl; cl.Text="Waiting..."; cl.TextColor3=Color3.fromRGB(241,196,15)
			ShowNotif("⌨️ Press a key...",true)
		end)
		sb.MouseButton1Click:Connect(function()
			Keybinds[ck]=nil; cl.Text="None"; cl.TextColor3=Color3.fromRGB(0,200,255)
			ShowNotif("🗑️ Keybind cleared!",true); _pcall(SaveKeybinds)
		end)
		ky=ky+42
	end

	-- TAB BUTTONS
	local tabNames={Main="🎯 Sniper",Settings="⚙️ Settings",Helpers="🧰 Helpers",Theme="🎨 Theme",Logs="📜 Logs",Active="👥 Active",Keys="⌨️ Keybinds"}
	local tabOrder={"Main","Settings","Helpers","Theme","Logs","Active","Keys"}
	local tabButtons={}
	local tabY2=0
	for _,key in ipairs(tabOrder) do
		local btn=UILib.CreateButton(tabContainer,tabNames[key],UDim2.new(1,0,0,30),UDim2.new(0,0,0,tabY2),"Panel",function() SwitchTab(key) end)
		btn.TextXAlignment=Enum.TextXAlignment.Left; btn.TextSize=12; tabButtons[key]=btn; tabY2=tabY2+34
	end
	SwitchTab=function(tabName)
		State.activeTab=tabName
		for name,page in pairs(pages) do page.Visible=(name==tabName) end
		for name,btn in pairs(tabButtons) do
			_TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=(name==tabName) and Theme.Accent or Theme.Panel}):Play()
		end
	end
	for key,btn in pairs(tabButtons) do
		btn.MouseEnter:Connect(function() if State.activeTab~=key then _TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Theme.AccentDark}):Play() end end)
		btn.MouseLeave:Connect(function() if State.activeTab~=key then _TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Theme.Panel}):Play() end end)
	end
	SwitchTab("Main")

	State.RefreshUI=function()
		for _,t in ipairs(AllToggles) do
			if t.Label=="Sniper Active:" then t.SetState(Config.Enabled) end
			if t.Label=="Auto-Write:" then t.SetState(Config.AutoWrite) end
			if t.Label=="Auto-Submit:" then t.SetState(Config.AutoSubmit) end
			if t.Label=="Auto Riddle Solver:" then t.SetState(Config.AutoSolveRiddles) end
			if t.Label=="ESP (Ad + Highlight):" then t.SetState(Config.ESPEnabled) end
		end
		if countBox then countBox.Text=tostring(Config.SubmitAfter) end
		if apiBox then apiBox.Text="" end
		Engine.RebuildDots()
		if Config.CustomThemeHex and Config.CustomThemeHex~="" and Config.CustomThemeHex~="RAINBOW" then
			local r3=tonumber(Config.CustomThemeHex:sub(1,2),16) or 50
			local g3=tonumber(Config.CustomThemeHex:sub(3,4),16) or 150
			local b3=tonumber(Config.CustomThemeHex:sub(5,6),16) or 255
			Theme.Accent=Color3.fromRGB(r3,g3,b3)
			Theme.AccentDark=Color3.new(r3/255*0.6,g3/255*0.6,b3/255*0.6)
			Theme.Bg=Color3.new(r3/255*0.15,g3/255*0.15,b3/255*0.15)
			Theme.Panel=Color3.new(r3/255*0.25,g3/255*0.25,b3/255*0.25)
			for _,el in ipairs(RegisteredElements) do if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object,el.Role,Theme[el.Role]) end end
		elseif Config.CustomThemeHex=="RAINBOW" then
			ThemeManager.Apply("Rainbow")
		else
			if Themes[Config.ThemeName] then ThemeManager.Apply(Config.ThemeName) end
		end
		Engine.UpdateProgress()
		ThemeManager.Apply(CurrentThemeName)
	end

	Engine.UpdateProgress(); ThemeManager.Apply(CurrentThemeName)
end

-- (eski UI bloğu silindi)

--[[ ESKİ UI BLOĞU
	State.main = Instance.new("ImageLabel")
	State.main.Size = UDim2.new(0, 450, 0, 480)
	State.main.Position = UDim2.new(0.5, 0, 0.5, -240)
	State.main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	State.main.Image = "rbxassetid://1316045217" -- Dark, futuristic background image
	State.main.ImageTransparency = 0.3
	State.main.ScaleType = Enum.ScaleType.Crop
	State.main.Active = true; State.main.Draggable = true
	State.main.Parent = State.gui
    local mainScale = Instance.new("UIScale")
    mainScale.Name = "BCSniperUIScale"
    mainScale.Scale = UIOptions.Scale
    mainScale.Parent = State.main
    if UIOptions.Animations then
        local finalSize = State.main.Size
        State.main.Size = UDim2.new(0, 0, 0, 0)
        _TweenService:Create(State.main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = finalSize}):Play()
    end

	-- Main Frame and Neon Line
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = State.main
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(0, 255, 255); stroke.Parent = State.main; ThemeManager.Register(stroke, "Accent")
	
	-- Outer Neon Shadow
	local shadow = Instance.new("UIStroke")
	shadow.Thickness = 8
	shadow.Color = Color3.fromRGB(0, 255, 255)
	shadow.Transparency = 0.6
	shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shadow.Parent = State.main

	-- Header (Title Part)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	header.BackgroundTransparency = 0.2
	header.Parent = State.main
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
	
	-- Header Bottom Line
	local headerLine = Instance.new("Frame")
	headerLine.Size = UDim2.new(1, 0, 0, 2)
	headerLine.Position = UDim2.new(0, 0, 1, -2)
	headerLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	headerLine.BorderSizePixel = 0
	headerLine.Parent = header

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0, 155, 1, 0)
	titleLbl.Position = UDim2.new(0, 12, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "BC SNIPER // V2"
	titleLbl.TextColor3 = Color3.fromRGB(0, 255, 255) -- Neon Cyan
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = header

	local timeLbl = UILib.CreateLabel(header, "Time Left: " .. GetRemainingTime(), UDim2.new(0, 92, 1, 0), UDim2.new(0, 166, 0, 0), "Success", Enum.Font.Code, 9)

	_spawn(function()
		while State.gui and State.gui.Parent do
			timeLbl.Text = (UIOptions.Language == "Turkish" and "Kalan Süre: " or "Time Left: ") .. GetRemainingTime()

			if GetRemainingTime() == "Expired" then
				Config.Enabled = false; Config.AutoWrite = false; Config.AutoSubmit = false
				Config.AutoSolveRiddles = false; Config.ESPEnabled = false; ClearESP(); SaveConfig()
				for _, conn in pairs(State.connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
				State.connections = {}; State.gui:Destroy()
				if isfile and isfile(authFile) then pcall(delfile, authFile) end
				Auth.Build(); break
			end
			_wait(1)
		end
	end)

	UILib.CreateButton(header, "PANIC", UDim2.new(0, 45, 0, 24), UDim2.new(1, -114, 0, 8), Color3.fromRGB(200, 30, 30), function() ActivatePanicMode() end)
	local minBtn = UILib.CreateButton(header, "-", UDim2.new(0, 24, 0, 24), UDim2.new(1, -64, 0, 8), "Panel", function() end)

	UILib.CreateButton(header, "X", UDim2.new(0, 24, 0, 24), UDim2.new(1, -34, 0, 8), "Error", function() 
        State.shutdown = true; 
		for _, conn in pairs(State.connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
		State.gui:Destroy() 
	end)

	local miniBtn = UILib.CreateButton(State.gui, "BC", UDim2.new(0, 50, 0, 50), UDim2.new(0, 10, 0.5, -25), "Panel", function() end)
	miniBtn.Visible = false
	local miniStroke = Instance.new("UIStroke"); miniStroke.Thickness = 2; miniStroke.Parent = miniBtn; ThemeManager.Register(miniStroke, "Accent")

	local isMinimized = false
	local originalPos = UDim2.new(0.5, -200, 0.5, -200)

	minBtn.MouseButton1Click:Connect(function()
		if isMinimized then return end
		isMinimized = true
		_TweenService:Create(State.main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0, -450, originalPos.Y.Scale, originalPos.Y.Offset)}):Play()
		_wait(0.3) State.main.Visible = false miniBtn.Visible = true
		_TweenService:Create(miniBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, 10, 0.5, -20)}):Play()
	end)
	miniBtn.MouseButton1Click:Connect(function()
		if not isMinimized then return end
		isMinimized = false
		_TweenService:Create(miniBtn, TweenInfo.new(0.2), {Position = UDim2.new(0, -50, 0.5, -20)}):Play()
		_wait(0.2) miniBtn.Visible = false State.main.Visible = true
		State.main.Position = UDim2.new(0, -450, originalPos.Y.Scale, originalPos.Y.Offset)
		_TweenService:Create(State.main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = originalPos}):Play()
	end)

	local sidebar = UILib.CreateFrame(State.main, UDim2.new(0, 130, 1, -40), UDim2.new(0, 0, 0, 40), "Panel")
	local tabContainer = UILib.CreateFrame(sidebar, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), "Bg")
	local contentArea = UILib.CreateFrame(State.main, UDim2.new(1, -130, 1, -40), UDim2.new(0, 130, 0, 40), "Bg")
	local pages = {}
	local SwitchTab
	local function CreatePage(name)
        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, -20, 1, -20); p.Position = UDim2.new(0, 10, 0, 10)
        p.BorderSizePixel = 0; p.BackgroundColor3 = Theme.Bg; p.BackgroundTransparency = 0
        p.ScrollBarThickness = 4; p.ScrollBarImageColor3 = Theme.Accent
        p.CanvasSize = UDim2.new(0, 0, 0, 0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        p.ScrollingDirection = Enum.ScrollingDirection.Y; p.ClipsDescendants = true; p.Visible = false; p.Parent = contentArea
        ThemeManager.Register(p, "Bg"); pages[name] = p; return p
    end

	local pageMain = CreatePage("Main")
	
	State.statusLabel = UILib.CreateLabel(pageMain, "» System ready...", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 1, -45), "TextDim", Enum.Font.Gotham, 10); State.statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	local signature = UILib.CreateLabel(pageMain, "by Beko", UDim2.new(1, -20, 0, 15), UDim2.new(0, 0, 1, -20), "AccentDark", Enum.Font.GothamBold, 11); signature.TextXAlignment = Enum.TextXAlignment.Center
	
	local y = 0
	UILib.CreateToggle(pageMain, "Sniper Active:", Config.Enabled, y, function(v) Config.Enabled = v; SaveConfig() end); y = y + 35
	UILib.CreateToggle(pageMain, "Auto-Write:", Config.AutoWrite, y, function(v) Config.AutoWrite = v; SaveConfig(); Engine.ProcessQueue() end); y = y + 35
	UILib.CreateToggle(pageMain, "Auto-Submit:", Config.AutoSubmit, y, function(v) Config.AutoSubmit = v; SaveConfig(); Engine.UpdateProgress() end); y = y + 40
	UILib.CreateToggle(pageMain, "Auto-Riddle Solver:", Config.AutoSolveRiddles, y, function(v)
		Config.AutoSolveRiddles = v
		SaveConfig()
		Logger.Log("Riddle Solver: " .. (v and "ON" or "OFF"), "info")
	end); y = y + 35
	local countRow = UILib.CreateFrame(pageMain, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), "Bg")
	UILib.CreateLabel(countRow, "Submit After (X):", UDim2.new(1, -100, 1, 0), UDim2.new(0, 8, 0, 0), "Text")
	local countBox = Instance.new("TextBox"); countBox.Size = UDim2.new(0, 80, 0, 26); countBox.Position = UDim2.new(1, -80, 0, 2); countBox.Text = tostring(Config.SubmitAfter); countBox.Font = Enum.Font.GothamBold; countBox.TextSize = 12; countBox.ClearTextOnFocus = false; countBox.Parent = countRow
	ThemeManager.Register(countBox, "Panel"); ThemeManager.Register(countBox, "Text")
	local cbc2 = Instance.new("UICorner"); cbc2.CornerRadius = UDim.new(0, 6); cbc2.Parent = countBox
	countBox.FocusLost:Connect(function() local n = tonumber(countBox.Text) or 1; if n < 1 then n = 1 end; Config.SubmitAfter = n; countBox.Text = tostring(n); State.collectedCount = 0; State.buffer = ""; Engine.RebuildDots(); SaveConfig() end)
	y = y + 40
	State.dotContainer = Instance.new("Frame")
	State.dotContainer.Size = UDim2.new(1, 0, 0, 16)
	State.dotContainer.Position = UDim2.new(0, 8, 0, y)
	State.dotContainer.BackgroundTransparency = 1
	State.dotContainer.Parent = pageMain
	y = y + 20
	State.progressText = UILib.CreateLabel(pageMain, "Collected: 0 / " .. Config.SubmitAfter, UDim2.new(1, 0, 0, 15), UDim2.new(0, 8, 0, y), "TextDim", Enum.Font.GothamBold, 10)
	y = y + 25
	Engine.RebuildDots()

	-- SETTINGS PAGE (SINGLE GEMINI API KEY)
	local pageSettings = CreatePage("Settings")
	local sy = 0
    local animBtn
    local langBtn; langBtn = UILib.CreateButton(pageSettings, "Language: English", UDim2.new(0.49, -3, 0, 27), UDim2.new(0, 0, 0, sy), "Panel", function()
        UIOptions.Language = UIOptions.Language == "English" and "Turkish" or "English"
        langBtn.Text = UIOptions.Language == "English" and "Language: English" or "Dil: Türkçe"
        TranslateUI()
        if animBtn then if UIOptions.Language == "Turkish" then animBtn.Text = UIOptions.Animations and "Animasyon: AÇIK" or "Animasyon: KAPALI" else animBtn.Text = UIOptions.Animations and "Animations: ON" or "Animations: OFF" end end
    end)
    UILib.CreateButton(pageSettings, "UI Size -", UDim2.new(0.23, -3, 0, 27), UDim2.new(0.51, 0, 0, sy), "Panel", function()
        UIOptions.Scale = math.max(0.75, math.floor((UIOptions.Scale - 0.1) * 10 + 0.5) / 10)
        if mainScale and mainScale.Parent then mainScale.Scale = UIOptions.Scale end
    end)
    UILib.CreateButton(pageSettings, "UI Size +", UDim2.new(0.23, -3, 0, 27), UDim2.new(0.76, 0, 0, sy), "Panel", function()
        UIOptions.Scale = math.min(1.35, math.floor((UIOptions.Scale + 0.1) * 10 + 0.5) / 10)
        if mainScale and mainScale.Parent then mainScale.Scale = UIOptions.Scale end
    end)
    sy = sy + 33
    animBtn = UILib.CreateButton(pageSettings, "Animations: ON", UDim2.new(0.49, -3, 0, 27), UDim2.new(0.00, 0, 0, sy), "Panel", function()
        UIOptions.Animations = not UIOptions.Animations
        if UIOptions.Language == "Turkish" then animBtn.Text = UIOptions.Animations and "Animasyon: AÇIK" or "Animasyon: KAPALI" else animBtn.Text = UIOptions.Animations and "Animations: ON" or "Animations: OFF" end
    end)
    sy = sy + 36
	UILib.CreateLabel(pageSettings, "Gemini API Key:", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, sy), "Text", Enum.Font.GothamBold, 11); sy = sy + 18
	local apiBox = Instance.new("TextBox")
	apiBox.Size = UDim2.new(1, 0, 0, 28)
	apiBox.Position = UDim2.new(0, 0, 0, sy)
	apiBox.BackgroundColor3 = Theme.Panel
	apiBox.PlaceholderText = "Enter Gemini API key here; it clears after saving"
	apiBox.Text = ""
	apiBox.TextColor3 = Theme.Text
	apiBox.Font = Enum.Font.Code
	apiBox.TextSize = 12
	apiBox.ClearTextOnFocus = false
	apiBox.TextTransparency = 0 -- Must be visible so the user can see and edit the entered key.
	apiBox.TextEditable = true
	apiBox.Parent = pageSettings
	Instance.new("UICorner", apiBox).CornerRadius = UDim.new(0, 6)
	sy = sy + 36

	UILib.CreateButton(pageSettings, "Save", UDim2.new(0.48, -3, 0, 28), UDim2.new(0, 0, 0, sy), "Success", function()
        if apiBox.Text and apiBox.Text:match("%S") then SaveGeminiKey(apiBox.Text); apiBox.Text = "" else ShowNotif("Enter a new API key first", false) end
    end)
    UILib.CreateButton(pageSettings, "Clear API Key", UDim2.new(0.48, -3, 0, 28), UDim2.new(0.52, 3, 0, sy), "Error", function()
        SaveGeminiKey(""); apiBox.Text = ""; ShowNotif("API key cleared", true)
    end); sy = sy + 42


	-- ============================ CONFIG MANAGER ============================
	UILib.CreateLabel(pageSettings, "── Config Manager ──", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, sy), "Accent", Enum.Font.GothamBold, 12); sy = sy + 24

	local nameRow = UILib.CreateFrame(pageSettings, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, sy), "Bg")
	local cfgNameBox = Instance.new("TextBox")
	cfgNameBox.Size = UDim2.new(1, -90, 0, 28)
	cfgNameBox.Position = UDim2.new(0, 0, 0, 1)
	cfgNameBox.BackgroundColor3 = Theme.Panel
	cfgNameBox.PlaceholderText = "preset name (e.g. main)"
	cfgNameBox.Text = ActivePresetName or "default"
	cfgNameBox.TextColor3 = Theme.Text
	cfgNameBox.Font = Enum.Font.GothamBold
	cfgNameBox.TextSize = 12
	cfgNameBox.ClearTextOnFocus = false
	cfgNameBox.Parent = nameRow
	Instance.new("UICorner", cfgNameBox).CornerRadius = UDim.new(0, 6)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0, 80, 0, 28)
	saveBtn.Position = UDim2.new(1, -80, 0, 1)
	saveBtn.BackgroundColor3 = Theme.Success
	saveBtn.Text = "💾 Save"
	saveBtn.TextColor3 = Color3.new(1,1,1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 11
	saveBtn.AutoButtonColor = false
	saveBtn.Parent = nameRow
	Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
	sy = sy + 36

	-- Preset list (scrollable)
	local listFrame = UILib.CreateFrame(pageSettings, UDim2.new(1, 0, 0, 120), UDim2.new(0, 0, 0, sy), "Black", 6)
	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, -6, 1, -6)
	listScroll.Position = UDim2.new(0, 3, 0, 3)
	listScroll.BackgroundTransparency = 1
	listScroll.ScrollBarThickness = 3
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.Parent = listFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = listScroll

	local function RefreshPresetList()
		for _, c in ipairs(listScroll:GetChildren()) do
			if c:IsA("Frame") and c.Name == "PresetRow" then c:Destroy() end
		end
		local presets = ListPresets()
		if #presets == 0 then
			local empty = Instance.new("TextLabel")
			empty.Name = "PresetRow"
			empty.Size = UDim2.new(1, 0, 0, 24)
			empty.BackgroundTransparency = 1
			empty.Text = "  (no presets)"
			empty.TextColor3 = Theme.TextDim
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 11
			empty.TextXAlignment = Enum.TextXAlignment.Left
			empty.Parent = listScroll
			return
		end
		for _, pname in ipairs(presets) do
			local row = Instance.new("Frame")
			row.Name = "PresetRow"
			row.Size = UDim2.new(1, -4, 0, 26)
			row.BackgroundColor3 = (pname == ActivePresetName) and Theme.Panel or Theme.Bg
			row.BorderSizePixel = 0
			row.Parent = listScroll
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -180, 1, 0)
			lbl.Position = UDim2.new(0, 8, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = (pname == ActivePresetName and "● " or "○ ") .. pname
			lbl.TextColor3 = (pname == ActivePresetName) and Theme.Success or Theme.Text
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = row

			local function miniBtn(text, xOff, color, cb)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0, 50, 0, 22)
				b.Position = UDim2.new(1, xOff, 0, 2)
				b.BackgroundColor3 = color
				b.Text = text
				b.TextColor3 = Color3.new(1,1,1)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 10
				b.AutoButtonColor = false
				b.Parent = row
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
				b.MouseButton1Click:Connect(cb)
				return b
			end

			miniBtn("📂 Load", -160, Theme.Accent, function()
				local ok, msg = LoadPreset(pname)
				Logger.Log(msg, ok and "success" or "error")
				if ok then
					cfgNameBox.Text = pname
					SaveConfig() -- Save the active preset name to the main config
					if State.RefreshUI then State.RefreshUI() end
					RefreshPresetList()
				end
			end)

			miniBtn("✏️ Rename", -108, Color3.fromRGB(180, 130, 40), function()
				local newName = cfgNameBox.Text
				if SanitizeName(newName) == nil then
					Logger.Log("Invalid new name!", "error")
					return
				end
				local ok, msg = RenamePreset(pname, newName)
				Logger.Log(msg, ok and "success" or "error")
				if ok then RefreshPresetList() end
			end)

			miniBtn("🗑 Delete", -54, Theme.Error, function()
				local ok, msg = DeletePreset(pname)
				Logger.Log(msg, ok and "success" or "error")
				if ok then RefreshPresetList() end
			end)
		end
	end

	saveBtn.MouseButton1Click:Connect(function()
		local targetName = cfgNameBox.Text
		if targetName == "" or not SanitizeName(targetName) then
			Logger.Log("Please enter a valid name!", "error")
			return
		end
		
		-- Overwrite check (optional warning log)
		local isOverwrite = false
		if isfile and isfile(PresetPath(targetName)) then isOverwrite = true end
		
		local ok, msg = SavePreset(targetName)
		if ok then
			Logger.Log(isOverwrite and ("Overwritten: " .. targetName) or ("New Save: " .. targetName), "success")
			RefreshPresetList() 
		else
			Logger.Log(msg, "error")
		end
	end)

	RefreshPresetList()
	sy = sy + 120 -- Slightly reduced the spacing after the list
	UILib.CreateLabel(pageSettings, "When the riddle solver is enabled, it answers in-game questions using the Gemini API.", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, sy), "TextDim", Enum.Font.Gotham, 10)

	-- HELPERS TAB
	local pageHelpers = CreatePage("Helpers")
	UILib.CreateLabel(pageHelpers, "Helpers & Testing", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), "Accent", Enum.Font.GothamBold, 14)
	local testerBox = UILib.CreateFrame(pageHelpers, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 30), "Panel", 8)
	UILib.CreateLabel(testerBox, "Tester: Rexyqw2", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), "Success", Enum.Font.Code, 14)
	-- Theme selection was moved to the separate "Theme" tab.
	UILib.CreateButton(pageHelpers, "📋 Show Code History", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 185), "Panel", function()
		if #CodeHistory == 0 then
			Logger.Log("History is empty!", "error")
			return
		end
		
		-- Clear logs so only the history is visible
		if State.logContainer then
			for _, c in ipairs(State.logContainer:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy() end
			end
		end
		
		-- Add a title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 20)
		title.BackgroundTransparency = 1
		title.Text = "--- SUCCESSFULLY COLLECTED CODES ---"
		title.TextColor3 = Theme.Accent
		title.Font = Enum.Font.GothamBold
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Center
		title.Parent = State.logContainer
		
		-- List the codes
		for _, h in ipairs(CodeHistory) do
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 16)
			lbl.BackgroundTransparency = 1
			lbl.Text = string.format("[%s] %s", h.time, h.code)
			lbl.TextColor3 = Theme.Success
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = State.logContainer
		end
	end)
	UILib.CreateToggle(pageHelpers, "ESP (Ad + Highlight):", Config.ESPEnabled, 220, function(v)
		Config.ESPEnabled = v
		SaveConfig()
		ToggleESP(v)
	end)
	-- ============================ THEME TAB (20 COLORS + RGB) ============================
	local pageTheme = CreatePage("Theme")
	local ty = 0
	UILib.CreateLabel(pageTheme, "Preset Colors:", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, ty), "Accent", Enum.Font.GothamBold, 14); ty = ty + 25
	
	local colorsGrid = UILib.CreateFrame(pageTheme, UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 0, ty), "Bg")
	local presetColors = {
		Color3.fromRGB(255, 255, 255), -- White was added first
		Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 150, 255), Color3.fromRGB(46, 204, 113),
		Color3.fromRGB(155, 89, 182), Color3.fromRGB(241, 196, 15), Color3.fromRGB(230, 126, 34),
		Color3.fromRGB(231, 76, 60), Color3.fromRGB(52, 152, 219), Color3.fromRGB(26, 188, 156),
		Color3.fromRGB(22, 160, 133), Color3.fromRGB(39, 174, 96), Color3.fromRGB(142, 68, 173),
		Color3.fromRGB(255, 105, 180), Color3.fromRGB(255, 165, 0), Color3.fromRGB(0, 255, 255),
		Color3.fromRGB(255, 215, 0), Color3.fromRGB(138, 43, 226), Color3.fromRGB(220, 20, 60),
		Color3.fromRGB(0, 191, 255), Color3.fromRGB(50, 205, 50)
	}
	
	local cx, cy = 0, 0
	for i, color in ipairs(presetColors) do
		local cBtn = Instance.new("TextButton")
		cBtn.Size = UDim2.new(0, 28, 0, 28)
		cBtn.Position = UDim2.new(0, cx, 0, cy)
		cBtn.BackgroundColor3 = color
		cBtn.Text = ""
		cBtn.AutoButtonColor = false
		cBtn.Parent = colorsGrid
		Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
		local cStroke = Instance.new("UIStroke", cBtn); cStroke.Color = Theme.Text; cStroke.Thickness = 1
		
		cBtn.MouseButton1Click:Connect(function()
			local r, g, b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
			Config.CustomThemeHex = string.format("%02X%02X%02X", r, g, b)
			
			-- Exit Rainbow mode (stop the animation)
			CurrentThemeName = "Blue" -- VERY IMPORTANT: Prevents Apply from restarting Rainbow
			if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection = nil end
			if RainbowBtnConnection then RainbowBtnConnection:Disconnect(); RainbowBtnConnection = nil end
			
			-- Instantly update the background, panel, and accent
			Theme.Accent = color
			
			-- White-theme check (to keep text readable)
			if r > 200 and g > 200 and b > 200 then
				Theme.Bg = Color3.fromRGB(240, 240, 245)
				Theme.Panel = Color3.fromRGB(220, 220, 225)
				Theme.Text = Color3.fromRGB(20, 20, 20)
				Theme.TextDim = Color3.fromRGB(80, 80, 80)
				Theme.AccentDark = Color3.fromRGB(150, 150, 150)
				-- Make the top bar text black in the white theme
				if State and State.HeaderGradient and State.HeaderGradient.Parent then
					local hStroke = State.HeaderGradient.Parent:FindFirstChildOfClass("UIStroke")
					if hStroke then hStroke.Color = Theme.Text end
				end
			else
				Theme.AccentDark = Color3.new(color.R * 0.6, color.G * 0.6, color.B * 0.6)
				Theme.Bg = Color3.new(color.R * 0.15, color.G * 0.15, color.B * 0.15)
				Theme.Panel = Color3.new(color.R * 0.25, color.G * 0.25, color.B * 0.25)
				Theme.Text = Color3.fromRGB(255, 255, 255)
				Theme.TextDim = Color3.fromRGB(150, 150, 150)
			end
			
			-- DO NOT CALL Apply (because Apply restores the old Hex value from Config)
			-- Manually recolor the elements only
			for _, el in ipairs(RegisteredElements) do
				if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object, el.Role, Theme[el.Role]) end
			end
			
			-- Also update the header gradient immediately
			if State and State.HeaderGradient then
				State.HeaderGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDark),
					ColorSequenceKeypoint.new(0.5, Theme.Panel),
					ColorSequenceKeypoint.new(1, Theme.AccentDark)
				})
			end
			
			SaveConfig()
		end)
		
		cx = cx + 32
		if cx > 280 then cx = 0; cy = cy + 32 end
	end
	
	-- Rainbow Square Button (added at the very end)
	local rbBtn = Instance.new("TextButton")
	rbBtn.Size = UDim2.new(0, 28, 0, 28)
	rbBtn.Position = UDim2.new(0, cx, 0, cy) -- Place it where the squares end
	rbBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
	rbBtn.Text = ""
	rbBtn.AutoButtonColor = false
	rbBtn.Parent = colorsGrid
	Instance.new("UICorner", rbBtn).CornerRadius = UDim.new(0, 4)
	
	-- Keep the button's own background changing continuously
	_spawn(function()
		while rbBtn and rbBtn.Parent do
			rbBtn.BackgroundColor3 = Color3.fromHSV(tick() % 1, 0.8, 1)
			_wait(0.1)
		end
	end)

	rbBtn.MouseButton1Click:Connect(function()
		Config.CustomThemeHex = "RAINBOW"
		SaveConfig()
		ThemeManager.Apply("Rainbow") -- This makes the entire menu (Bg, Panel, Accent) colorful
	end)
	
	ty = ty + 110 -- Space for RGB controls at the bottom
	
	UILib.CreateLabel(pageTheme, "Custom RGB Settings:", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, ty), "Accent", Enum.Font.GothamBold, 14); ty = ty + 25
	
	local currentR, currentG, currentB = math.floor(Theme.Accent.R*255), math.floor(Theme.Accent.G*255), math.floor(Theme.Accent.B*255)
	
	local function ApplyRGB()
		local hex = string.format("%02X%02X%02X", currentR, currentG, currentB)
		Config.CustomThemeHex = hex
		
		-- Exit Rainbow mode (stop the animation)
		CurrentThemeName = "Blue" -- Prevents Apply from restarting Rainbow
		if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection = nil end
		if RainbowBtnConnection then RainbowBtnConnection:Disconnect(); RainbowBtnConnection = nil end
		
		local color = Color3.fromRGB(currentR, currentG, currentB)
		Theme.Accent = color
		Theme.AccentDark = Color3.new(color.R * 0.6, color.G * 0.6, color.B * 0.6)
		Theme.Bg = Color3.new(color.R * 0.15, color.G * 0.15, color.B * 0.15)
		Theme.Panel = Color3.new(color.R * 0.25, color.G * 0.25, color.B * 0.25)
		
		-- DO NOT CALL Apply (because Apply restores the old Hex value from Config)
		for _, el in ipairs(RegisteredElements) do
			if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object, el.Role, Theme[el.Role]) end
		end
		
		-- Also update the header gradient immediately
		if State and State.HeaderGradient then
			State.HeaderGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme.AccentDark),
				ColorSequenceKeypoint.new(0.5, Theme.Panel),
				ColorSequenceKeypoint.new(1, Theme.AccentDark)
			})
		end
		
		SaveConfig()
	end
	
	-- Red Slider
	local rLbl = UILib.CreateLabel(pageTheme, "Red (R): " .. currentR, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, ty), "Text", Enum.Font.Gotham, 11); ty = ty + 18
	local rBar = Instance.new("TextButton"); rBar.Size = UDim2.new(1, 0, 0, 6); rBar.Position = UDim2.new(0, 0, 0, ty); rBar.BackgroundColor3 = Theme.Panel; rBar.Text = ""; rBar.Parent = pageTheme; ty = ty + 12
	local rFill = Instance.new("Frame"); rFill.Size = UDim2.new(currentR/255, 0, 1, 0); rFill.BackgroundColor3 = Color3.fromRGB(255,50,50); rFill.BorderSizePixel = 0; rFill.Parent = rBar
	rBar.MouseButton1Down:Connect(function()
		local function update() local mouse = _UserInputService:GetMouseLocation(); local relX = math.clamp((mouse.X - rBar.AbsolutePosition.X) / rBar.AbsoluteSize.X, 0, 1); currentR = math.floor(relX * 255); rFill.Size = UDim2.new(relX, 0, 1, 0); rLbl.Text = "Red (R): " .. currentR; ApplyRGB() end
		update()
		local conn; conn = _RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then update() else conn:Disconnect() end end)
	end)

	-- Green Slider
	local gLbl = UILib.CreateLabel(pageTheme, "Green (G): " .. currentG, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, ty), "Text", Enum.Font.Gotham, 11); ty = ty + 18
	local gBar = Instance.new("TextButton"); gBar.Size = UDim2.new(1, 0, 0, 6); gBar.Position = UDim2.new(0, 0, 0, ty); gBar.BackgroundColor3 = Theme.Panel; gBar.Text = ""; gBar.Parent = pageTheme; ty = ty + 12
	local gFill = Instance.new("Frame"); gFill.Size = UDim2.new(currentG/255, 0, 1, 0); gFill.BackgroundColor3 = Color3.fromRGB(50,255,50); gFill.BorderSizePixel = 0; gFill.Parent = gBar
	gBar.MouseButton1Down:Connect(function()
		local function update() local mouse = _UserInputService:GetMouseLocation(); local relX = math.clamp((mouse.X - gBar.AbsolutePosition.X) / gBar.AbsoluteSize.X, 0, 1); currentG = math.floor(relX * 255); gFill.Size = UDim2.new(relX, 0, 1, 0); gLbl.Text = "Green (G): " .. currentG; ApplyRGB() end
		update()
		local conn; conn = _RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then update() else conn:Disconnect() end end)
	end)

	-- Blue Slider
	local bLbl = UILib.CreateLabel(pageTheme, "Blue (B): " .. currentB, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, ty), "Text", Enum.Font.Gotham, 11); ty = ty + 18
	local bBar = Instance.new("TextButton"); bBar.Size = UDim2.new(1, 0, 0, 6); bBar.Position = UDim2.new(0, 0, 0, ty); bBar.BackgroundColor3 = Theme.Panel; bBar.Text = ""; bBar.Parent = pageTheme; ty = ty + 12
	local bFill = Instance.new("Frame"); bFill.Size = UDim2.new(currentB/255, 0, 1, 0); bFill.BackgroundColor3 = Color3.fromRGB(50,50,255); bFill.BorderSizePixel = 0; bFill.Parent = bBar
	bBar.MouseButton1Down:Connect(function()
		local function update() local mouse = _UserInputService:GetMouseLocation(); local relX = math.clamp((mouse.X - bBar.AbsolutePosition.X) / bBar.AbsoluteSize.X, 0, 1); currentB = math.floor(relX * 255); bFill.Size = UDim2.new(relX, 0, 1, 0); bLbl.Text = "Blue (B): " .. currentB; ApplyRGB() end
		update()
		local conn; conn = _RunService.RenderStepped:Connect(function() if _UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then update() else conn:Disconnect() end end)
	end)

	-- Logs Page
local pageLogs = CreatePage("Logs")
UILib.CreateButton(pageLogs, "🗑 Clear Logs", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "Error", function()
	if State.logContainer then
		for _, c in ipairs(State.logContainer:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
	end
end)
local logFrame = UILib.CreateFrame(pageLogs, UDim2.new(1, 0, 1, -34), UDim2.new(0, 0, 0, 32), "Black", 6)
local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1,-6,1,-6)
logScroll.Position = UDim2.new(0,3,0,3)
logScroll.BackgroundTransparency = 1
logScroll.ScrollBarThickness = 3
logScroll.CanvasSize = UDim2.new(0,0,0,0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ScrollingDirection = Enum.ScrollingDirection.Y
logScroll.Parent = logFrame
local logInner = UILib.CreateFrame(logScroll, UDim2.new(1,-4,0,0), UDim2.new(0,2,0,0), "Black")
logInner.AutomaticSize = Enum.AutomaticSize.Y
local logLayout = Instance.new("UIListLayout"); logLayout.Padding = UDim.new(0, 2); logLayout.Parent = logInner
logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
end)
Logger.Init(logInner)

	-- ACTIVE USERS PAGE
	local pageActive = CreatePage("Active")
	UILib.CreateButton(pageActive, "🔄 Refresh", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "Panel", function()
		if State.RefreshActiveUsers then State.RefreshActiveUsers() end
	end)
	local activeFrame = UILib.CreateFrame(pageActive, UDim2.new(1, 0, 1, -34), UDim2.new(0, 0, 0, 32), "Black", 6)
	local activeScroll = Instance.new("ScrollingFrame")
	activeScroll.Size = UDim2.new(1, -6, 1, -6)
	activeScroll.Position = UDim2.new(0, 3, 0, 3)
	activeScroll.BackgroundTransparency = 1
	activeScroll.ScrollBarThickness = 3
	activeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	activeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	activeScroll.Parent = activeFrame
	local activeLayout = Instance.new("UIListLayout")
	activeLayout.Padding = UDim.new(0, 2)
	activeLayout.Parent = activeScroll
	State.activeUsersList = activeScroll
	
	-- FUNCTION DEFINED HERE (Bug Fix)
	State.RefreshActiveUsers = function()
		if not State.activeUsersList then return end
		for _, c in ipairs(State.activeUsersList:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		
		local db = GetDB()
		local activeSet = {}
		
		-- Get entries from the database (users active in the last 5 minutes)
		if db and db.ActiveUsers then
			for uid, data in pairs(db.ActiveUsers) do
				if os.time() - data.LastSeen <= 300 then
					activeSet[uid] = data.Name
				end
			end
		end
		
		-- ALWAYS ADD YOURSELF TO THE LIST (so you can see yourself even if the database is delayed)
		activeSet[tostring(_LocalPlayer.UserId)] = _LocalPlayer.Name

		local count = 0
		for uid, name in pairs(activeSet) do
			count = count + 1
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -10, 0, 20)
			lbl.Position = UDim2.new(0, 5, 0, (count - 1) * 22)
			lbl.BackgroundTransparency = 1
			lbl.Text = count .. ". " .. name -- NAME ONLY
			lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = State.activeUsersList
		end
		
		if count == 0 then
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.BackgroundTransparency = 1
			lbl.Text = "No active users right now."
			lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
			lbl.Parent = State.activeUsersList
		end
	end
	
	-- Refresh every 15 seconds while the Active Users tab is open
	_spawn(function()
		while State.gui and State.gui.Parent do
			if State.activeTab == "Active" then
				State.RefreshActiveUsers()
			end
			_wait(15)
		end
	end)

	-- KEYBINDS PAGE
	local pageKeys = CreatePage("Keys")
	UILib.CreateLabel(pageKeys, "⌨️ Keybinds", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), "Accent", Enum.Font.GothamBold, 14)
	UILib.CreateLabel(pageKeys, "Press [Bind] then press your desired key.", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 22), "TextDim", Enum.Font.Gotham, 10)

	local bindItems = {
		{label = "Toggle Sniper", key = "Enabled"},
		{label = "Toggle Auto-Write", key = "AutoWrite"},
		{label = "Toggle Auto-Submit", key = "AutoSubmit"},
		{label = "Toggle ESP", key = "ESPEnabled"},
		{label = "Toggle Riddle Solver", key = "AutoSolveRiddles"},
	}
	local ky = 55
	for _, item in ipairs(bindItems) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.Position = UDim2.new(0, 0, 0, ky)
		row.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		row.BorderSizePixel = 0
		row.Parent = pageKeys
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		local rowStroke = Instance.new("UIStroke", row)
		rowStroke.Thickness = 1
		ThemeManager.Register(rowStroke, "Accent")

		local nameLbl = Instance.new("TextLabel", row)
		nameLbl.Size = UDim2.new(0, 130, 1, 0)
		nameLbl.Position = UDim2.new(0, 8, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = item.label
		nameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 10
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local keyLbl = Instance.new("TextLabel", row)
		keyLbl.Size = UDim2.new(0, 80, 1, 0)
		keyLbl.Position = UDim2.new(0, 142, 0, 0)
		keyLbl.BackgroundTransparency = 1
		keyLbl.Text = Keybinds[item.key] or "None"
		keyLbl.TextColor3 = Color3.fromRGB(0, 200, 255)
		keyLbl.Font = Enum.Font.Code
		keyLbl.TextSize = 10
		keyLbl.TextXAlignment = Enum.TextXAlignment.Left

		local ataBtn = Instance.new("TextButton", row)
		ataBtn.Size = UDim2.new(0, 45, 0, 26)
		ataBtn.Position = UDim2.new(1, -115, 0, 5)
		ataBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
		ataBtn.Text = "Bind"
		ataBtn.TextColor3 = Color3.new(1,1,1)
		ataBtn.Font = Enum.Font.GothamBold
		ataBtn.TextSize = 11
		ataBtn.AutoButtonColor = false
		Instance.new("UICorner", ataBtn).CornerRadius = UDim.new(0, 6)

		-- NEW: Delete Button
		local silBtn = Instance.new("TextButton", row)
		silBtn.Size = UDim2.new(0, 45, 0, 26)
		silBtn.Position = UDim2.new(1, -60, 0, 5)
		silBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		silBtn.Text = "Clear"
		silBtn.TextColor3 = Color3.new(1,1,1)
		silBtn.Font = Enum.Font.GothamBold
		silBtn.TextSize = 11
		silBtn.AutoButtonColor = false
		Instance.new("UICorner", silBtn).CornerRadius = UDim.new(0, 6)

		local capturedKey = item.key
		local capturedLbl = keyLbl
		ataBtn.MouseButton1Click:Connect(function()
			if BindingTarget then
				BindingTarget = nil
				BindingLabelRef = nil
			end
			BindingTarget = capturedKey
			BindingLabelRef = capturedLbl
			capturedLbl.Text = "Waiting..."
			capturedLbl.TextColor3 = Color3.fromRGB(241, 196, 15)
			ShowNotif("⌨️ Press a key...", true)
		end)

		-- NEW: Delete Button Event
silBtn.MouseButton1Click:Connect(function()
    Keybinds[capturedKey] = nil
    capturedLbl.Text = "None"
    capturedLbl.TextColor3 = Color3.fromRGB(0, 200, 255)
    ShowNotif("🗑️ Keybind cleared!", true)
    _pcall(SaveKeybinds)
end)

		ky = ky + 42
	end

	UILib.CreateLabel(pageKeys, "⚠️ RightShift / Delete always triggers PANIC MODE.", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, ky + 5), "Error", Enum.Font.Gotham, 10)

	local tabNames = { Main = "🎯 Sniper", Settings = "⚙️ Settings", Helpers = "🧰 Helpers", Theme = "🎨 Theme", Logs = "📜 Logs", Active = "👥 Active", Keys = "⌨️ Keybinds" }
	local tabOrder = { "Main", "Settings", "Helpers", "Theme", "Logs", "Active", "Keys" }
	local tabButtons = {}
	local tabY = 0

	-- Create the buttons first
	for _, key in ipairs(tabOrder) do
		local display = tabNames[key]
		local btn = UILib.CreateButton(tabContainer, display, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, tabY), "Panel", function() SwitchTab(key) end)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextSize = 12
		tabButtons[key] = btn
		tabY = tabY + 34
	end

	-- Redefine SwitchTab after creating the buttons (local assignment)
	SwitchTab = function(tabName)
		State.activeTab = tabName
		for name, page in pairs(pages) do page.Visible = (name == tabName) end
		for name, btn in pairs(tabButtons) do
			local targetColor = (name == tabName) and Theme.Accent or Theme.Panel
			_TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
		end
	end

	-- Hover effect (connect after redefining SwitchTab)
	for key, btn in pairs(tabButtons) do
		btn.MouseEnter:Connect(function()
			if State.activeTab ~= key then
				_TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentDark}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if State.activeTab ~= key then
				_TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}):Play()
			end
		end)
	end

	SwitchTab("Main")

	-- (System-ready and signature labels were moved into the Main tab)

	-- ==========================================
	-- ZOKTA AND THE FLIPPING-OFF UNCLE (IMAGES)
	-- ==========================================
	-- NOTE: Enter the Asset IDs of the images you uploaded to Roblox here.
	-- Example: rbxassetid://1234567890
	local zoktaId = "rbxassetid://0" -- ENTER THE ZOKTA IMAGE ID HERE
	local dayiId = "rbxassetid://0"  -- ENTER THE UNCLE IMAGE ID HERE

	if zoktaId ~= "rbxassetid://0" then
		local zoktaImg = Instance.new("ImageLabel")
		zoktaImg.Size = UDim2.new(0, 60, 0, 60)
		zoktaImg.Position = UDim2.new(0, -70, 0.5, -30)
		zoktaImg.BackgroundTransparency = 1
		zoktaImg.Image = zoktaId
		zoktaImg.Parent = State.main
		
		-- Jump Animation
		_spawn(function()
			while zoktaImg.Parent do
				_TweenService:Create(zoktaImg, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(0, -70, 0.5, -40)}):Play()
				_wait(0.5)
				_TweenService:Create(zoktaImg, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(0, -70, 0.5, -30)}):Play()
				_wait(0.5)
			end
		end)
	end

	if dayiId ~= "rbxassetid://0" then
		local dayiImg = Instance.new("ImageLabel")
		dayiImg.Size = UDim2.new(0, 80, 0, 80)
		dayiImg.Position = UDim2.new(1, 10, 0.5, -40)
		dayiImg.BackgroundTransparency = 1
		dayiImg.Image = dayiId
		dayiImg.Parent = State.main
		
		-- Waving Animation (as if flipping someone off)
		_spawn(function()
			while dayiImg.Parent do
				_TweenService:Create(dayiImg, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Rotation = 10}):Play()
				_wait(0.2)
				_TweenService:Create(dayiImg, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Rotation = -10}):Play()
				_wait(0.2)
			end
			-- NOTE: The image background must be transparent to use Rotation on an ImageLabel.
		end)
	end
	-- Function that updates the GUI when Config is loaded
	local function RefreshUIFromConfig()
		for _, t in ipairs(AllToggles) do
			if t.Label == "Sniper Active:" then t.SetState(Config.Enabled) end
			if t.Label == "Auto-Write:" then t.SetState(Config.AutoWrite) end
			if t.Label == "Auto-Submit:" then t.SetState(Config.AutoSubmit) end
			if t.Label == "Auto Riddle Solver:" then t.SetState(Config.AutoSolveRiddles) end
			if t.Label == "ESP (Ad + Highlight):" then t.SetState(Config.ESPEnabled) end
		end
		
		if countBox then countBox.Text = tostring(Config.SubmitAfter) end
		if apiBox then apiBox.Text = "" end
		
		Engine.RebuildDots()
		
		-- Apply the custom color (Hex) if present; otherwise apply the default theme
		if Config.CustomThemeHex and Config.CustomThemeHex ~= "" and Config.CustomThemeHex ~= "RAINBOW" then
			local r = tonumber(Config.CustomThemeHex:sub(1,2), 16) or 50
			local g = tonumber(Config.CustomThemeHex:sub(3,4), 16) or 150
			local b = tonumber(Config.CustomThemeHex:sub(5,6), 16) or 255
			Theme.Accent = Color3.fromRGB(r, g, b)
			Theme.AccentDark = Color3.new(r/255 * 0.6, g/255 * 0.6, b/255 * 0.6)
			Theme.Bg = Color3.new(r/255 * 0.15, g/255 * 0.15, b/255 * 0.15)
			Theme.Panel = Color3.new(r/255 * 0.25, g/255 * 0.25, b/255 * 0.25)
			
			for _, el in ipairs(RegisteredElements) do
				if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object, el.Role, Theme[el.Role]) end
			end
		elseif Config.CustomThemeHex == "RAINBOW" then
			ThemeManager.Apply("Rainbow")
		else
			if Themes[Config.ThemeName] then ThemeManager.Apply(Config.ThemeName) end
		end
		
		-- Update the header color
		if State.HeaderGradient then
			if Config.CustomThemeHex == "RAINBOW" then
				State.HeaderGradient.Color = ColorSequence.new(Color3.fromHSV(tick() % 1, 0.8, 0.6), Color3.fromHSV((tick() + 0.5) % 1, 0.8, 0.6))
			else
				State.HeaderGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDark),
					ColorSequenceKeypoint.new(0.5, Theme.Panel),
					ColorSequenceKeypoint.new(1, Theme.AccentDark)
				})
			end
		end
	end

-- ESKİ UI BLOĞU SONU ]]

local OWNER_ID = 0 -- Enter BekoceybabaPro's Roblox User ID here

local function ApplyOwnerTag()
	_spawn(function()
		local function TagOwner(player)
			if player.UserId ~= OWNER_ID then return end
			local function addTag()
				local char = player.Character
				if not char then return end
				local head = char:FindFirstChild("Head")
				if not head then return end
				if head:FindFirstChild("OwnerBillboard") then return end

				local bb = Instance.new("BillboardGui")
				bb.Name = "OwnerBillboard"
				bb.AlwaysOnTop = true
				bb.Size = UDim2.new(0, 140, 0, 40)
				bb.StudsOffset = Vector3.new(0, 3.5, 0)
				bb.Adornee = head
				bb.Parent = head

				local bg = Instance.new("Frame", bb)
				bg.Size = UDim2.new(1, 0, 1, 0)
				bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				bg.BackgroundTransparency = 0.3
				bg.BorderSizePixel = 0
				Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

				local lbl = Instance.new("TextLabel", bg)
				lbl.Size = UDim2.new(1, 0, 0.5, 0)
				lbl.Position = UDim2.new(0, 0, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = "👑 OWNER"
				lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 14
				lbl.TextStrokeTransparency = 0
				lbl.TextStrokeColor3 = Color3.new(0, 0, 0)

				local lbl2 = Instance.new("TextLabel", bg)
				lbl2.Size = UDim2.new(1, 0, 0.5, 0)
				lbl2.Position = UDim2.new(0, 0, 0.5, 0)
				lbl2.BackgroundTransparency = 1
				lbl2.Text = "BekoceybabaPro"
				lbl2.TextColor3 = Color3.fromRGB(255, 100, 100)
				lbl2.Font = Enum.Font.GothamBold
				lbl2.TextSize = 11
				lbl2.TextStrokeTransparency = 0
				lbl2.TextStrokeColor3 = Color3.new(0, 0, 0)
			end
			addTag()
			player.CharacterAdded:Connect(function()
				task.wait(1)
				addTag()
			end)
		end

		for _, p in ipairs(_Players:GetPlayers()) do TagOwner(p) end
		_Players.PlayerAdded:Connect(TagOwner)
	end)
end

local function CheckAnnouncement()
	_spawn(function()
		while State.gui and State.gui.Parent do
			local req = request or http_request or syn.request
			if req then
				_pcall(function()
					local res = req({Url = ANNOUNCE_URL, Method = "GET"})
					if res and res.StatusCode == 200 then
						local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
						if ok and data and data.message and data.message ~= "" then
							-- Show the announcement GUI
							local existing = _CoreGui:FindFirstChild("BCAnnounce")
							if existing then existing:Destroy() end
							local ag = Instance.new("ScreenGui", _CoreGui)
							ag.Name = "BCAnnounce"
							ag.ResetOnSpawn = false
							local af = Instance.new("Frame", ag)
							af.Size = UDim2.new(0, 360, 0, 80)
							af.Position = UDim2.new(0.5, -180, 0, 10)
							af.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
							af.BorderSizePixel = 0
							Instance.new("UICorner", af).CornerRadius = UDim.new(0, 8)
							local stroke = Instance.new("UIStroke", af)
							stroke.Color = Color3.fromRGB(255, 200, 0)
							stroke.Thickness = 1.5
							local title = Instance.new("TextLabel", af)
							title.Size = UDim2.new(1, -10, 0, 24)
							title.Position = UDim2.new(0, 10, 0, 5)
							title.BackgroundTransparency = 1
							title.Text = "📢 BC Sniper - Announcement"
							title.TextColor3 = Color3.fromRGB(255, 200, 0)
							title.Font = Enum.Font.GothamBold
							title.TextSize = 12
							title.TextXAlignment = Enum.TextXAlignment.Left
							local msg = Instance.new("TextLabel", af)
							msg.Size = UDim2.new(1, -10, 0, 40)
							msg.Position = UDim2.new(0, 10, 0, 30)
							msg.BackgroundTransparency = 1
							msg.Text = data.message
							msg.TextColor3 = Color3.fromRGB(255, 255, 255)
							msg.Font = Enum.Font.Gotham
							msg.TextSize = 12
							msg.TextWrapped = true
							msg.TextXAlignment = Enum.TextXAlignment.Left
							-- Close after 10 seconds
							_spawn(function()
								_wait(10)
								if ag and ag.Parent then ag:Destroy() end
							end)
						end
					end
				end)
			end
			_wait(60) -- Check every 60 seconds
		end
	end)
end

local function UpdateLastSeen()
	_spawn(function()
		while State.gui and State.gui.Parent do
			local savedKey = LoadAuth()
			if savedKey then
				local req = request or http_request or syn.request
				if req then
					_pcall(function()
						local res = req({Url = BLOB_URL, Method = "GET"})
						if res and res.StatusCode == 200 then
							local ok, db = pcall(function() return _HttpService:JSONDecode(res.Body) end)
							if ok and db and db[savedKey] then
								db[savedKey]["last_seen"] = os.time()
								req({
									Url = BLOB_URL,
									Method = "POST",
									Headers = {["Content-Type"] = "application/json"},
									Body = _HttpService:JSONEncode(db)
								})
							end
						end
					end)
				end
			end
			_wait(120) -- Update every 2 minutes
		end
	end)
end

function Initialize()
	StartHeartbeat()
	LoadConfig() -- Automatically load the last settings so the script does not start from scratch
	
	-- Apply the custom theme color (if present)
	if Config.CustomThemeHex == "RAINBOW" then
		-- When the Rainbow square button in the Theme tab is clicked
		ThemeManager.Apply("Rainbow")
	elseif Config.CustomThemeHex and #Config.CustomThemeHex == 6 then
		local r = tonumber(Config.CustomThemeHex:sub(1,2), 16) or 50
		local g = tonumber(Config.CustomThemeHex:sub(3,4), 16) or 150
		local b = tonumber(Config.CustomThemeHex:sub(5,6), 16) or 255
		Theme.Accent = Color3.fromRGB(r, g, b)
		Theme.AccentDark = Color3.new(r/255 * 0.7, g/255 * 0.7, b/255 * 0.7)
	end
	
	LoadGeminiKey()
	Menu.Build()
	-- After building the menu, apply the loaded Config to the interface
	if State.RefreshUI then State.RefreshUI() end
	Events.StartWatcher()
	ApplyOwnerTag()
	CheckAnnouncement()
	UpdateLastSeen()
	local pg = _LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		local conn = pg.DescendantAdded:Connect(function(obj)
			if obj:IsA("TextBox") and obj.Visible then
				local hint = string.lower((obj.PlaceholderText or "") .. " " .. obj.Name)
				if string.find(hint, "code") or string.find(hint, "redeem") then State.boxRef = obj; Engine.ProcessQueue() end
			end
		end)
		table.insert(State.connections, conn)
	end
	if Config.ESPEnabled then ToggleESP(true) end
	_Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if Config.ESPEnabled then ApplyESP(p) end
		end)
	end)
	for _, p in ipairs(_Players:GetPlayers()) do
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if Config.ESPEnabled then ApplyESP(p) end
		end)
	end
	if Themes[Config.ThemeName] then ThemeManager.Apply(Config.ThemeName) end
	
	-- Set the header gradient when the game starts
	if State and State.HeaderGradient then
		if Config.CustomThemeHex == "RAINBOW" then
			-- Rainbow already creates its own connection inside Apply, so nothing else is needed
		else
			State.HeaderGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme.AccentDark),
				ColorSequenceKeypoint.new(0.5, Theme.Panel),
				ColorSequenceKeypoint.new(1, Theme.AccentDark)
			})
		end
	end
	
	Engine.RebuildDots()
	Logger.Log("System Ready. Rexyqw2", "success")
	Logger.Log("Active preset: " .. ActivePresetName, "info")
	Logger.Log("All features started OFF. You can enable them in Config.", "info")
end

-- LAUNCHER (AUTO-LOGIN)
local savedKey = LoadAuth()
if savedKey then
	local ok, msg = Auth.Verify(savedKey)
	if ok then 
		Initialize() 
	else 
		if isfile and isfile(authFile) then pcall(delfile, authFile) end 
		Auth.Build() 
	end
else
	Auth.Build()
end
