-- =====================================================================================
-- BC SNIPER - ULTIMATE EDITION (Panic Mode + Riddle Solver + HWID + ESP + Duyuru)
-- by Beko | Tester: Rexyqw2
-- =====================================================================================

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

local ThemeManager = {}
local function T(bg,pn,ac,acd,tx,txd,su,er,bk) return {Bg=bg,Panel=pn,Accent=ac,AccentDark=acd,Text=tx,TextDim=txd,Success=su,Error=er,Black=bk} end
local C = Color3.fromRGB
local Themes = {
	DarkRed = T(C(18,8,8),C(28,15,15),C(200,30,30),C(140,20,20),C(255,240,240),C(200,150,150),C(46,204,113),C(231,76,60),C(0,0,0)),
	Black   = T(C(10,10,10),C(20,20,20),C(60,60,60),C(40,40,40),C(255,255,255),C(150,150,150),C(46,204,113),C(231,76,60),C(0,0,0)),
	White   = T(C(240,240,245),C(220,220,225),C(100,100,100),C(80,80,80),C(20,20,20),C(80,80,80),C(39,174,96),C(192,57,43),C(255,255,255)),
	Blue    = T(C(8,12,20),C(15,25,40),C(50,150,255),C(30,100,200),C(240,245,255),C(150,170,200),C(46,204,113),C(231,76,60),C(0,0,0)),
	Green   = T(C(8,18,10),C(15,28,20),C(40,200,80),C(25,140,50),C(240,255,240),C(150,200,160),C(46,204,113),C(231,76,60),C(0,0,0)),
	Rainbow = T(C(12,12,15),C(22,22,28),C(255,0,0),C(150,0,0),C(255,255,255),C(180,180,180),C(46,204,113),C(231,76,60),C(0,0,0)),
}
local CurrentThemeName = "Blue"
local Theme = Themes[CurrentThemeName]
local RegisteredElements = {}
local RainbowConnection = nil

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
	CurrentThemeName = themeName; Theme = Themes[themeName]
	for _, el in ipairs(RegisteredElements) do
		if el.Object and el.Object.Parent and Theme[el.Role] then PaintObj(el.Object, el.Role, Theme[el.Role]) end
	end
	if RainbowConnection then RainbowConnection:Disconnect(); RainbowConnection = nil end
	if themeName == "Rainbow" then
		RainbowConnection = _RunService.RenderStepped:Connect(function()
			local col = Color3.fromHSV(tick() % 1, 0.8, 1)
			for _, el in ipairs(RegisteredElements) do
				local o = el.Object
				if o and o.Parent and el.Role == "Accent" then
					if o:IsA("UIStroke") then o.Color = col else o.BackgroundColor3 = col end
				end
			end
		end)
	end
end

local Config = { Enabled = true, AutoWrite = true, AutoSubmit = true, SubmitAfter = 1, MaxLogs = 200 }
local ESPEnabled = false
local ESPObjects = {}
local CodeHistory = {}
local State = { cooldowns = {}, queue = {}, buffer = "", collectedCount = 0, isWriting = false, isSubmitting = false, gui = nil, main = nil, tabs = {}, activeTab = "Main", statusLabel = nil, progressBar = nil, progressText = nil, logContainer = nil, boxRef = nil, connections = {}, startTime = os.clock() }

-- =====================================================================================
-- AYARLAR
-- =====================================================================================
local BLOB_URL = "https://api.npoint.io/a89d8daaf2073ce0d7d4"
local ANNOUNCE_URL = "https://api.npoint.io/7f1ba4c97e06ce1dd978"
local authFile = "bc_sniper_auth.txt"
local geminiFile = "bc_gemini_key.txt"
local ExpiryTimeStamp = 0
local RiddleCooldown = {}

local WEBHOOK_URL = "https://discord.com/api/webhooks/1561427931744440360/bAYX5nHpRqZzdPpThhy6MLvXmPstH_ntCsBYOm9GGF6CVGMfSV8x79JxZPCLEWbnFD-o"

local BlacklistedPlaces = {
	[131992906944920] = true,
	[73437505877429] = true,
	[110635270173920] = true
}

if BlacklistedPlaces[game.PlaceId] then
	_LocalPlayer:Kick("❌ BC Sniper bu oyunda blacklistlidir!")
	return
end

-- =====================================================================================
-- ESP
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
	local head = char:FindFirstChild("Head") or hrp
	if head:FindFirstChild("ESPBillboard") then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ESPBillboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.Adornee = head
	bb.Parent = char

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 0.5, 0)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "BC SNIPER"
	lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)

	local lbl2 = Instance.new("TextLabel", bb)
	lbl2.Size = UDim2.new(1, 0, 0.5, 0)
	lbl2.Position = UDim2.new(0, 0, 0.5, 0)
	lbl2.BackgroundTransparency = 1
	lbl2.Text = player.Name
	lbl2.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl2.Font = Enum.Font.GothamBold
	lbl2.TextSize = 11
	lbl2.TextStrokeTransparency = 0
	lbl2.TextStrokeColor3 = Color3.new(0, 0, 0)

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
	ESPEnabled = state
	if not state then
		ClearESP()
	else
		for _, p in ipairs(_Players:GetPlayers()) do
			ApplyESP(p)
		end
	end
end

-- =====================================================================================
-- PANIC MODE
-- =====================================================================================
local function ActivatePanicMode()
	for _, conn in pairs(State.connections) do
		if typeof(conn) == "RBXScriptConnection" then _pcall(function() conn:Disconnect() end) end
	end
	State.connections = {}
	local gui = _CoreGui:FindFirstChild("BCSniper") or _LocalPlayer.PlayerGui:FindFirstChild("BCSniper")
	if gui then gui:Destroy() end
	local authGui = _CoreGui:FindFirstChild("BCAuth")
	if authGui then authGui:Destroy() end
	Config.Enabled = false; Config.AutoWrite = false; Config.AutoSubmit = false
	ESPEnabled = false; ClearESP()
end

_UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Delete then
		ActivatePanicMode()
	end
	if input.KeyCode == Enum.KeyCode.F5 then
		ESPEnabled = not ESPEnabled
		ToggleESP(ESPEnabled)
	end
end)

-- =====================================================================================
-- WEBHOOK
-- =====================================================================================
local function SendLog(title, desc, color)
	if not WEBHOOK_URL or WEBHOOK_URL == "" then return end
	local req = request or http_request or syn.request
	if not req then return end
	local data = {
		["embeds"] = { { ["title"] = title, ["description"] = desc, ["color"] = color or 3447003, ["footer"] = { ["text"] = "BC Sniper Log | " .. os.date("%Y-%m-%d %H:%M:%S") } } }
	}
	_pcall(function() req({ Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _HttpService:JSONEncode(data) }) end)
end

-- =====================================================================================
-- GEMINI RIDDLE SOLVER
-- =====================================================================================
local CurrentGeminiKey = ""
local GeminiKeys = {}
local GeminiKeyIndex = 1
local AutoSolveRiddles = true

local function GetNextGeminiKey()
	if #GeminiKeys == 0 then return CurrentGeminiKey end
	local key = GeminiKeys[GeminiKeyIndex]
	GeminiKeyIndex = (GeminiKeyIndex % #GeminiKeys) + 1
	return key
end

local function SolveRiddle(text)
	local activeKey = GetNextGeminiKey()
	if not activeKey or activeKey == "" then
		Logger.Log("API Key eksik! Ayarlardan gir.", "error")
		return nil
	end

	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=" .. activeKey
	local prompt = "You are a riddle solver. Today is " .. os.date("%A, %B %d, %Y, %H:%M:%S") .. ". Answer the following riddle with ONLY the answer word or number. No explanation, no punctuation, no spaces, uppercase only. If it asks for a date, answer like MONDAY or JANUARY or 2024. Riddle: " .. text
	local body = { contents = { { parts = { { text = prompt } } } } }
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
			answer = string.upper(string.gsub(answer, "[^%w]", ""))
			answer = string.sub(answer, 1, 30)
			if answer == "" then Logger.Log("Gemini boş cevap döndü!", "error"); return nil end
			Logger.Log("Gemini Cevabı: " .. answer, "success")
			return answer
		end
	else
		local errBody = (res and res.Body) or "bilinmiyor"
		Logger.Log("Gemini Hatası! StatusCode: " .. tostring(res and res.StatusCode) .. " | " .. tostring(errBody):sub(1,60), "error")
	end
	return nil
end

local function LoadGeminiKey()
	if isfile and readfile and isfile(geminiFile) then
		local ok, data = pcall(readfile, geminiFile)
		if ok and data and data ~= "" then
			GeminiKeys = {}
			for k in data:gmatch("[^,]+") do
				local trimmed = k:match("^%s*(.-)%s*$")
				if trimmed ~= "" then table.insert(GeminiKeys, trimmed) end
			end
			CurrentGeminiKey = GeminiKeys[1] or data
		end
	end
end

local function SaveGeminiKey(key)
	GeminiKeys = {}
	for k in key:gmatch("[^,]+") do
		local trimmed = k:match("^%s*(.-)%s*$")
		if trimmed ~= "" then table.insert(GeminiKeys, trimmed) end
	end
	CurrentGeminiKey = GeminiKeys[1] or key
	if writefile then pcall(writefile, geminiFile, key) end
	Logger.Log(#GeminiKeys .. " key yüklendi!", "success")
end

-- =====================================================================================
-- VERİTABANI VE HWID
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
	if not req then return nil, "HTTP yok!" end
	local success, res = pcall(req, {Url = BLOB_URL, Method = "GET"})
	if not success then return nil, "Sunucuya ulaşılamadı!" end
	if res and res.StatusCode == 200 then
		if res.Body == "null" or res.Body == "" or res.Body == "1" then return {} end
		local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
		if ok then return data end
	end
	return nil, "Veritabanı okunamadı!"
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
	if ExpiryTimeStamp == nil or ExpiryTimeStamp == 0 then return "Sınırsız" end
	local diff = ExpiryTimeStamp - os.time()
	if diff <= 0 then return "Süresi Doldu" end
	local d, h, m, s = math.floor(diff/86400), math.floor((diff%86400)/3600), math.floor((diff%3600)/60), diff%60
	if d > 0 then return string.format("%dd %dh %dm", d, h, m)
	elseif h > 0 then return string.format("%dh %dm %ds", h, m, s)
	elseif m > 0 then return string.format("%dm %ds", m, s)
	else return string.format("%ds", s) end
end

function Auth.Verify(key)
	key = string.gsub(key, "%s+", "")
	local db, dbErr = GetDB()
	if not db then return false, dbErr or "Sunucuya bağlanılamadı!" end
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
			SendLog("✅ Yeni Key Kullanıldı", "**Oyuncu:** " .. playerName .. "\n**UserID:** " .. userId .. "\n**Key:** " .. key .. "\n**HWID:** " .. hwid .. "\n**Sunucu:** " .. jobId, 3066993)
			return true, "Başarılı (İlk Giriş)"
		else
			if keyData.hwid ~= hwid then
				SendLog("⛔ HWID Uyuşmazlığı", "**Oyuncu:** " .. playerName .. "\n**Key:** " .. key .. "\n**Saldırgan HWID:** " .. hwid, 15158332)
				return false, "Bu key başka bir HWID'ye bağlı!"
			end
			if keyData.expiry ~= 0 and keyData.expiry ~= nil and keyData.expiry <= os.time() then
				SendLog("⏳ Süresi Dolmuş Key", "**Oyuncu:** " .. playerName .. "\n**Key:** " .. key, 15105570)
				return false, "Süresi Dolmuş"
			end
			ExpiryTimeStamp = keyData.expiry or 0
			SendLog("🔑 Sisteme Giriş Yapıldı", "**Oyuncu:** " .. playerName .. "\n**Key:** " .. key .. "\n**HWID:** " .. hwid, 3447003)
			return true, "Başarılı"
		end
	else
		SendLog("❌ Geçersiz Key Denemesi", "**Oyuncu:** " .. playerName .. "\n**Girilen Key:** " .. key .. "\n**HWID:** " .. hwid, 15105570)
		return false, "Geçersiz Key (Sunucuda bulunamadı)"
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
	title.Size, title.Position, title.BackgroundTransparency, title.Text = UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), 1, "BC Sniper | Giriş"
	title.TextColor3, title.Font, title.TextSize = Theme.Text, Enum.Font.GothamBold, 16

	local box = Instance.new("TextBox", f)
	box.Size, box.Position, box.BackgroundColor3, box.PlaceholderText = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,50), Theme.Panel, "POLSEC-XXXX-XXXX"
	box.TextColor3, box.Font, box.TextSize = Theme.Text, Enum.Font.GothamBold, 14
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

	local btn = Instance.new("TextButton", f)
	btn.Size, btn.Position, btn.BackgroundColor3, btn.Text = UDim2.new(1,-40,0,35), UDim2.new(0,20,0,105), Theme.Success, "Doğrula"
	btn.Font, btn.TextSize, btn.TextColor3 = Enum.Font.GothamBold, 13, Color3.new(1,1,1)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

	local st = Instance.new("TextLabel", f)
	st.Size, st.Position, st.BackgroundTransparency, st.Text = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,150), 1, "Keyinizi girin."
	st.TextColor3, st.Font, st.TextSize, st.TextWrapped = Theme.TextDim, Enum.Font.Gotham, 11, true

	btn.MouseButton1Click:Connect(function()
		if btn.Text == "Bekleyin..." then return end
		btn.Text = "Bekleyin..."
		st.Text = "Kontrol ediliyor..."
		st.TextColor3 = Color3.fromRGB(241, 196, 15)
		task.spawn(function()
			local success, ok, msg = pcall(function() return Auth.Verify(box.Text) end)
			if not success then ok = false; msg = "Sistem Hatası" end
			if ok then
				SaveAuth(box.Text)
				st.Text = "✅ Başarılı! Giriş yapılıyor..."
				st.TextColor3 = Theme.Success
				task.wait(1)
				gui:Destroy()
				Initialize()
			else
				st.Text = "❌ " .. tostring(msg)
				st.TextColor3 = Theme.Error
				btn.Text = "Doğrula"
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
	local prefix = "[BİLGİ] "
	if logType == "success" then color = Theme.Success; prefix = "[BAŞARILI] "
	elseif logType == "error" then color = Theme.Error; prefix = "[HATA] " end
	local timeStr = string.format("[%02d:%02d]", math.floor((_clock() - State.startTime)/60), math.floor((_clock() - State.startTime)%60))
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16); lbl.BackgroundTransparency = 1; lbl.Text = timeStr .. " " .. prefix .. text
	lbl.TextColor3 = color; lbl.TextSize = 10; lbl.Font = Enum.Font.Code; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = State.logContainer
end

local Extractor = {}
local function Sanitize(text) return text and text:gsub("<[^>]->", ""):match("^%s*(.-)%s*$") or "" end
function Extractor.GetCode(text)
	if not text or text == "" then return nil end
	local clean = Sanitize(text)
	if clean:match("^[%w%s]+$") then local noSpace = clean:gsub("%s+", ""); if #noSpace >= 3 and #noSpace <= 30 then return noSpace end end
	local parts = {}
	for word in clean:gmatch("%w+") do
		if #word >= 2 and #word <= 30 and (word:match("%d") or (word == word:upper() and word:match("%a"))) then
			local blacklist = { ["NOTIFICATION"]=true, ["REDEEM"]=true, ["CODES"]=true, ["UPDATE"]=true, ["REWARD"]=true, ["AVAILABLE"]=true, ["YOUR"]=true, ["THE"]=true, ["AND"]=true, ["FOR"]=true }
			if not blacklist[word] then table.insert(parts, word) end
		end
	end
	if #parts > 0 then return table.concat(parts) end
	return nil
end

local Engine = {}
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
	if State.progressText and State.progressBar then
		State.progressText.Text = string.format("Collected: %d / %d", State.collectedCount, Config.SubmitAfter)
		_TweenService:Create(State.progressBar, TweenInfo.new(0.1), {Size = UDim2.new(math.min(State.collectedCount / Config.SubmitAfter, 1), 0, 1, 0)}):Play()
	end
end

function Engine.Submit()
	if State.isSubmitting then return end
	State.isSubmitting = true
	local codeToSend = State.buffer
	if codeToSend == "" then State.isSubmitting = false; return end
	local box = Engine.GetTextBox()
	if box then
		local confirm = box.Parent and box.Parent.Parent and box.Parent.Parent:FindFirstChild("Confirm")
		_pcall(function() box:CaptureFocus(); box.Text = codeToSend; box.CursorPosition = #codeToSend + 1 end)
		_wait(0.1)
		_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
		if confirm and firesignal and Config.AutoSubmit then
			_pcall(firesignal, confirm.MouseButton1Click)
			_pcall(firesignal, confirm.Activated)
		end
		Logger.Log("Kutuya yazıldı: " .. codeToSend, "success")
		State.buffer = ""; State.collectedCount = 0; Engine.UpdateProgress()
	else
		Logger.Log("Kod kutusu bulunamadı!", "error")
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
			local currentBox = Engine.GetTextBox(); if not currentBox then break end
			local code = table.remove(State.queue, 1); if not code then break end
			State.buffer = State.buffer .. code; State.collectedCount = State.collectedCount + 1; Engine.UpdateProgress()
			if Config.AutoSubmit and State.collectedCount >= Config.SubmitAfter then
				Engine.Submit()
			else
				_pcall(function() currentBox:CaptureFocus(); currentBox.Text = State.buffer; currentBox.CursorPosition = #State.buffer + 1 end)
				_pcall(function() currentBox:ReleaseFocus(false) end); _wait(0.05)
			end
		end
		State.isWriting = false
	end)
end

-- =====================================================================================
-- OLAY DİNLEYİCİSİ
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
						local foundCode = Extractor.GetCode(rawText)

						if AutoSolveRiddles and (#rawText > 15 or rawText:find("%?") or rawText:find("[Ww]hat") or rawText:find("[Hh]ow") or rawText:find("[Ww]hich") or rawText:find("[Ww]hen") or rawText:find("[Ww]ho") or rawText:find("[Ff]ill") or rawText:find("[Nn]ame") or rawText:find("[Gg]uess")) then
							if RiddleCooldown[rawText] and _clock() < RiddleCooldown[rawText] then return end
							RiddleCooldown[rawText] = _clock() + 30
							_spawn(function()
								Logger.Log("Soru: " .. rawText:sub(1,50), "success")
								local answer = SolveRiddle(rawText)
								if answer then
									if setclipboard then _pcall(setclipboard, answer) end
									local box = Engine.GetTextBox()
									if box then
										_pcall(function() box:CaptureFocus(); box.Text = answer; box.CursorPosition = #answer + 1 end)
										_wait(0.2)
										_pcall(function() box:ReleaseFocus(Config.AutoSubmit) end)
										_wait(0.1)
										if Config.AutoSubmit then
											local confirm = box.Parent and box.Parent.Parent and box.Parent.Parent:FindFirstChild("Confirm")
											if confirm then
												if firesignal then _pcall(firesignal, confirm.MouseButton1Click); _pcall(firesignal, confirm.Activated) end
												_pcall(function() local vgui = confirm:FindFirstChildWhichIsA("TextButton") or confirm; if vgui and vgui:IsA("TextButton") then vgui:MouseButton1Click() end end)
											end
										end
										Logger.Log("Cevap: " .. answer, "success")
									else Logger.Log("Kod kutusu yok!", "error") end
								end
							end)
							return
						end

						if foundCode then
							if State.cooldowns[foundCode] and _clock() < State.cooldowns[foundCode] then return end
							State.cooldowns[foundCode] = _clock() + 2.0
							if setclipboard then _pcall(setclipboard, foundCode) end
							Logger.Log("Kod: " .. foundCode, "success")
							table.insert(CodeHistory, {code = foundCode, time = os.date("%H:%M:%S")})
							if #CodeHistory > 50 then table.remove(CodeHistory, 1) end
							if writefile then
								local histStr = ""
								for _, h in ipairs(CodeHistory) do histStr = histStr .. h.time .. " - " .. h.code .. "\n" end
								_pcall(writefile, "bc_code_history.txt", histStr)
							end
							table.insert(State.queue, foundCode); Engine.ProcessQueue()
						end
					end
					obj:GetPropertyChangedSignal("Text"):Connect(function() _pcall(checkAndQueue) end); _pcall(checkAndQueue)
				end
			end)
			table.insert(State.connections, conn)
		end

		local guiNames = {"TopNotification", "CodeGui", "NotificationGui", "RedeemGui", "Notification", "RiddleGui", "QuestionGui", "EventGui"}
		for _, name in ipairs(guiNames) do
			local existing = pg:FindFirstChild(name)
			if existing then WatchGui(existing) end
		end
		local pgConn = pg.ChildAdded:Connect(function(child)
			for _, name in ipairs(guiNames) do
				if child.Name == name then WatchGui(child) end
			end
		end)
		table.insert(State.connections, pgConn)

		local topNotif = pg:WaitForChild("TopNotification", 20)
		if topNotif then WatchGui(topNotif) end
	end)
end

-- =====================================================================================
-- UI KÜTÜPHANESİ
-- =====================================================================================
local UILib = {}
function UILib.CreateFrame(parent, size, pos, role, cornerRadius)
	local frame = Instance.new("Frame"); frame.Size = size; frame.Position = pos; frame.BorderSizePixel = 0; frame.Parent = parent
	if cornerRadius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, cornerRadius); c.Parent = frame end
	ThemeManager.Register(frame, role); return frame
end
function UILib.CreateLabel(parent, text, size, pos, role, font, textSize)
	local label = Instance.new("TextLabel"); label.Size = size; label.Position = pos; label.BackgroundTransparency = 1; label.Text = text; label.Font = font or Enum.Font.GothamSemibold; label.TextSize = textSize or 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = parent
	ThemeManager.Register(label, role); return label
end
function UILib.CreateButton(parent, text, size, pos, role, callback)
	local btn = Instance.new("TextButton"); btn.Size = size; btn.Position = pos; btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.AutoButtonColor = false; btn.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
	ThemeManager.Register(btn, role); ThemeManager.Register(btn, "Text"); btn.MouseButton1Click:Connect(callback); return btn
end
function UILib.CreateToggle(parent, labelText, defaultState, yPos, callback)
	defaultState = defaultState == true
	local row = UILib.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yPos), "Bg")
	UILib.CreateLabel(row, labelText, UDim2.new(1, -100, 1, 0), UDim2.new(0, 0, 0, 0), "Text")
	local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 80, 0, 26); btn.Position = UDim2.new(1, -80, 0, 2); btn.Text = defaultState and "ON" or "OFF"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.AutoButtonColor = false; btn.Parent = row
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
	btn.BackgroundColor3 = defaultState and Theme.Success or Theme.Error
	local state = defaultState
	btn.MouseButton1Click:Connect(function() state = not state; btn.Text = state and "ON" or "OFF"; btn.BackgroundColor3 = state and Theme.Success or Theme.Error; callback(state) end)
	return row
end

-- =====================================================================================
-- OWNER TAG
-- =====================================================================================
local OWNER_ID = 0 -- BekoceybabaPro UserID buraya

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
				bb.Name = "OwnerBillboard"; bb.AlwaysOnTop = true; bb.Size = UDim2.new(0,140,0,40)
				bb.StudsOffset = Vector3.new(0,3.5,0); bb.Adornee = head; bb.Parent = head
				local bg = Instance.new("Frame", bb)
				bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(20,20,20)
				bg.BackgroundTransparency = 0.3; bg.BorderSizePixel = 0
				Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)
				local lbl = Instance.new("TextLabel", bg)
				lbl.Size = UDim2.new(1,0,0.5,0); lbl.Position = UDim2.new(0,0,0,0)
				lbl.BackgroundTransparency = 1; lbl.Text = "👑 OWNER"
				lbl.TextColor3 = Color3.fromRGB(255,215,0); lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 14; lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.new(0,0,0)
				local lbl2 = Instance.new("TextLabel", bg)
				lbl2.Size = UDim2.new(1,0,0.5,0); lbl2.Position = UDim2.new(0,0,0.5,0)
				lbl2.BackgroundTransparency = 1; lbl2.Text = "BekoceybabaPro"
				lbl2.TextColor3 = Color3.fromRGB(255,100,100); lbl2.Font = Enum.Font.GothamBold
				lbl2.TextSize = 11; lbl2.TextStrokeTransparency = 0; lbl2.TextStrokeColor3 = Color3.new(0,0,0)
			end
			addTag()
			player.CharacterAdded:Connect(function() task.wait(1); addTag() end)
		end
		for _, p in ipairs(_Players:GetPlayers()) do TagOwner(p) end
		_Players.PlayerAdded:Connect(TagOwner)
	end)
end

-- =====================================================================================
-- DUYURU SİSTEMİ
-- =====================================================================================
local function CheckAnnouncement()
	_spawn(function()
		local lastMsg = ""
		while State.gui and State.gui.Parent do
			local req = request or http_request or syn.request
			if req then
				_pcall(function()
					local res = req({Url = ANNOUNCE_URL, Method = "GET"})
					if res and res.StatusCode == 200 then
						local ok, data = pcall(function() return _HttpService:JSONDecode(res.Body) end)
						if ok and data and data.message and data.message ~= "" and data.message ~= lastMsg then
							lastMsg = data.message
							local existing = _CoreGui:FindFirstChild("BCAnnounce")
							if existing then existing:Destroy() end
							local ag = Instance.new("ScreenGui", _CoreGui)
							ag.Name = "BCAnnounce"; ag.ResetOnSpawn = false
							local af = Instance.new("Frame", ag)
							af.Size = UDim2.new(0,360,0,80); af.Position = UDim2.new(0.5,-180,0,10)
							af.BackgroundColor3 = Color3.fromRGB(20,20,30); af.BorderSizePixel = 0
							Instance.new("UICorner", af).CornerRadius = UDim.new(0,8)
							local stroke = Instance.new("UIStroke", af)
							stroke.Color = Color3.fromRGB(255,200,0); stroke.Thickness = 1.5
							local title = Instance.new("TextLabel", af)
							title.Size = UDim2.new(1,-10,0,24); title.Position = UDim2.new(0,10,0,5)
							title.BackgroundTransparency = 1; title.Text = "📢 BC Sniper - Duyuru"
							title.TextColor3 = Color3.fromRGB(255,200,0); title.Font = Enum.Font.GothamBold
							title.TextSize = 12; title.TextXAlignment = Enum.TextXAlignment.Left
							local msg = Instance.new("TextLabel", af)
							msg.Size = UDim2.new(1,-10,0,40); msg.Position = UDim2.new(0,10,0,30)
							msg.BackgroundTransparency = 1; msg.Text = data.message
							msg.TextColor3 = Color3.fromRGB(255,255,255); msg.Font = Enum.Font.Gotham
							msg.TextSize = 12; msg.TextWrapped = true; msg.TextXAlignment = Enum.TextXAlignment.Left
							_spawn(function() _wait(10); if ag and ag.Parent then ag:Destroy() end end)
						end
					end
				end)
			end
			_wait(60)
		end
	end)
end

-- =====================================================================================
-- LAST SEEN (Kullanıcı sayacı için)
-- =====================================================================================
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
								req({Url = BLOB_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _HttpService:JSONEncode(db)})
							end
						end
					end)
				end
			end
			_wait(120)
		end
	end)
end

-- =====================================================================================
-- MENÜ
-- =====================================================================================
local Menu = {}
function Menu.Build()
	local old = _CoreGui:FindFirstChild("BCSniper") or _LocalPlayer.PlayerGui:FindFirstChild("BCSniper")
	if old then old:Destroy() end
	State.gui = Instance.new("ScreenGui"); State.gui.Name = "BCSniper"; State.gui.ResetOnSpawn = false
	_pcall(function() State.gui.Parent = _CoreGui end)
	if not State.gui.Parent then State.gui.Parent = _LocalPlayer.PlayerGui end

	State.main = UILib.CreateFrame(State.gui, UDim2.new(0,400,0,400), UDim2.new(0.5,-200,0.5,-200), "Bg", 12)
	State.main.Active = true; State.main.Draggable = true
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = State.main; ThemeManager.Register(stroke, "Accent")

	local header = UILib.CreateFrame(State.main, UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), "Panel", 12)
	UILib.CreateLabel(header, "BC Sniper", UDim2.new(1,-180,1,0), UDim2.new(0,15,0,0), "Text", Enum.Font.GothamBold, 16)
	local timeLbl = UILib.CreateLabel(header, "Kalan: " .. GetRemainingTime(), UDim2.new(0,90,1,0), UDim2.new(0,110,0,0), "Success", Enum.Font.Code, 10)

	-- Key kontrol döngüsü
	_spawn(function()
		while State.gui and State.gui.Parent do
			timeLbl.Text = "Kalan: " .. GetRemainingTime()

			if math.floor((_clock() - State.startTime) % 10) == 0 then
				_spawn(function()
					local db, _ = GetDB()
					local savedKey = LoadAuth()
					if db and savedKey then
						local keyData = db[savedKey]
						local isValid = false
						if type(keyData) == "table" then
							local hwid = GetHWID()
							if keyData.status == "used" and keyData.hwid == hwid then
								if keyData.expiry == nil or keyData.expiry == 0 or keyData.expiry > os.time() then
									isValid = true
								end
							elseif keyData.status == "unused" then
								isValid = true
							end
						end
						if not isValid then
							Config.Enabled = false; Config.AutoWrite = false; Config.AutoSubmit = false
							AutoSolveRiddles = false; ESPEnabled = false; ClearESP()
							for _, conn in pairs(State.connections) do
								if typeof(conn) == "RBXScriptConnection" then _pcall(function() conn:Disconnect() end) end
							end
							State.connections = {}
							if State.gui and State.gui.Parent then State.gui:Destroy() end
							if isfile and isfile(authFile) then _pcall(delfile, authFile) end
							Auth.Build()
							return
						end
					end
				end)
			end

			if GetRemainingTime() == "Süresi Doldu" then
				Config.Enabled = false; Config.AutoWrite = false; Config.AutoSubmit = false
				AutoSolveRiddles = false; ESPEnabled = false; ClearESP()
				for _, conn in pairs(State.connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
				State.connections = {}; State.gui:Destroy()
				if isfile and isfile(authFile) then pcall(delfile, authFile) end
				Auth.Build(); break
			end
			_wait(1)
		end
	end)

	UILib.CreateButton(header, "PANIC", UDim2.new(0,45,0,24), UDim2.new(1,-114,0,8), Color3.fromRGB(200,30,30), function() ActivatePanicMode() end)
	local minBtn = UILib.CreateButton(header, "-", UDim2.new(0,24,0,24), UDim2.new(1,-64,0,8), "Panel", function() end)
	UILib.CreateButton(header, "X", UDim2.new(0,24,0,24), UDim2.new(1,-34,0,8), "Error", function()
		for _, conn in pairs(State.connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
		State.gui:Destroy()
	end)

	local miniBtn = UILib.CreateButton(State.gui, "BC", UDim2.new(0,40,0,40), UDim2.new(0,-50,0.5,-20), "Panel", function() end)
	miniBtn.Visible = false
	local miniStroke = Instance.new("UIStroke"); miniStroke.Thickness = 2; miniStroke.Parent = miniBtn; ThemeManager.Register(miniStroke, "Accent")
	local isMinimized = false
	local originalPos = UDim2.new(0.5,-200,0.5,-200)
	minBtn.MouseButton1Click:Connect(function()
		if isMinimized then return end; isMinimized = true
		_TweenService:Create(State.main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0,-450,originalPos.Y.Scale,originalPos.Y.Offset)}):Play()
		_wait(0.3); State.main.Visible = false; miniBtn.Visible = true
		_TweenService:Create(miniBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0,10,0.5,-20)}):Play()
	end)
	miniBtn.MouseButton1Click:Connect(function()
		if not isMinimized then return end; isMinimized = false
		_TweenService:Create(miniBtn, TweenInfo.new(0.2), {Position = UDim2.new(0,-50,0.5,-20)}):Play()
		_wait(0.2); miniBtn.Visible = false; State.main.Visible = true
		State.main.Position = UDim2.new(0,-450,originalPos.Y.Scale,originalPos.Y.Offset)
		_TweenService:Create(State.main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = originalPos}):Play()
	end)

	local sidebar = UILib.CreateFrame(State.main, UDim2.new(0,100,1,-40), UDim2.new(0,0,0,40), "Panel")
	local tabContainer = UILib.CreateFrame(sidebar, UDim2.new(1,-10,1,-10), UDim2.new(0,5,0,5), "Bg")
	local contentArea = UILib.CreateFrame(State.main, UDim2.new(1,-100,1,-40), UDim2.new(0,100,0,40), "Bg")
	local pages = {}
	local function SwitchTab(tabName) for name, page in pairs(pages) do page.Visible = (name == tabName) end end
	local function CreatePage(name) local p = UILib.CreateFrame(contentArea, UDim2.new(1,-20,1,-20), UDim2.new(0,10,0,10), "Bg"); p.Visible = false; pages[name] = p; return p end

	-- MAIN SEKME
	local pageMain = CreatePage("Main")
	local y = 0
	UILib.CreateToggle(pageMain, "Sniper Active:", Config.Enabled, y, function(v) Config.Enabled = v end); y = y + 35
	UILib.CreateToggle(pageMain, "Auto-Write:", Config.AutoWrite, y, function(v) Config.AutoWrite = v; Engine.ProcessQueue() end); y = y + 35
	UILib.CreateToggle(pageMain, "Auto-Submit:", Config.AutoSubmit, y, function(v) Config.AutoSubmit = v end); y = y + 40
	local countRow = UILib.CreateFrame(pageMain, UDim2.new(1,0,0,30), UDim2.new(0,0,0,y), "Bg")
	UILib.CreateLabel(countRow, "Submit After (X):", UDim2.new(1,-100,1,0), UDim2.new(0,0,0,0), "Text")
	local countBox = Instance.new("TextBox"); countBox.Size = UDim2.new(0,80,0,26); countBox.Position = UDim2.new(1,-80,0,2); countBox.Text = tostring(Config.SubmitAfter); countBox.Font = Enum.Font.GothamBold; countBox.TextSize = 12; countBox.ClearTextOnFocus = false; countBox.Parent = countRow
	ThemeManager.Register(countBox, "Panel"); ThemeManager.Register(countBox, "Text")
	Instance.new("UICorner", countBox).CornerRadius = UDim.new(0,6)
	countBox.FocusLost:Connect(function() local n = tonumber(countBox.Text) or 1; if n < 1 then n = 1 end; Config.SubmitAfter = n; countBox.Text = tostring(n); State.collectedCount = 0; State.buffer = ""; Engine.UpdateProgress() end)
	y = y + 40
	local pbBg = UILib.CreateFrame(pageMain, UDim2.new(1,0,0,12), UDim2.new(0,0,0,y), "Panel", 12)
	State.progressBar = UILib.CreateFrame(pbBg, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0), "Accent", 12)
	State.progressText = UILib.CreateLabel(pageMain, "Collected: 0 / " .. Config.SubmitAfter, UDim2.new(1,0,0,15), UDim2.new(0,0,0,y+15), "TextDim", Enum.Font.GothamBold, 10)
	y = y + 45
	UILib.CreateButton(pageMain, "FORCE SUBMIT", UDim2.new(1,0,0,26), UDim2.new(0,0,0,y), "Error", function() if State.buffer ~= "" then Engine.Submit() else Logger.Log("Kod yok!", "error") end end)

	-- AYARLAR SEKME
	local pageSettings = CreatePage("Settings")
	local sy = 0
	UILib.CreateLabel(pageSettings, "Gemini API Key 1:", UDim2.new(1,0,0,16), UDim2.new(0,0,0,sy), "Text", Enum.Font.GothamBold, 11); sy = sy + 18
	local apiBox1 = Instance.new("TextBox"); apiBox1.Size = UDim2.new(1,0,0,26); apiBox1.Position = UDim2.new(0,0,0,sy); apiBox1.BackgroundColor3 = Theme.Panel; apiBox1.PlaceholderText = "AIzaSy..."; apiBox1.Text = GeminiKeys[1] or ""; apiBox1.TextColor3 = Theme.Text; apiBox1.Font = Enum.Font.Code; apiBox1.TextSize = 10; apiBox1.ClearTextOnFocus = false; apiBox1.Parent = pageSettings
	Instance.new("UICorner", apiBox1).CornerRadius = UDim.new(0,6); sy = sy + 32
	UILib.CreateLabel(pageSettings, "Gemini API Key 2:", UDim2.new(1,0,0,16), UDim2.new(0,0,0,sy), "Text", Enum.Font.GothamBold, 11); sy = sy + 18
	local apiBox2 = Instance.new("TextBox"); apiBox2.Size = UDim2.new(1,0,0,26); apiBox2.Position = UDim2.new(0,0,0,sy); apiBox2.BackgroundColor3 = Theme.Panel; apiBox2.PlaceholderText = "AIzaSy..."; apiBox2.Text = GeminiKeys[2] or ""; apiBox2.TextColor3 = Theme.Text; apiBox2.Font = Enum.Font.Code; apiBox2.TextSize = 10; apiBox2.ClearTextOnFocus = false; apiBox2.Parent = pageSettings
	Instance.new("UICorner", apiBox2).CornerRadius = UDim.new(0,6); sy = sy + 32
	UILib.CreateLabel(pageSettings, "Gemini API Key 3:", UDim2.new(1,0,0,16), UDim2.new(0,0,0,sy), "Text", Enum.Font.GothamBold, 11); sy = sy + 18
	local apiBox3 = Instance.new("TextBox"); apiBox3.Size = UDim2.new(1,0,0,26); apiBox3.Position = UDim2.new(0,0,0,sy); apiBox3.BackgroundColor3 = Theme.Panel; apiBox3.PlaceholderText = "AIzaSy..."; apiBox3.Text = GeminiKeys[3] or ""; apiBox3.TextColor3 = Theme.Text; apiBox3.Font = Enum.Font.Code; apiBox3.TextSize = 10; apiBox3.ClearTextOnFocus = false; apiBox3.Parent = pageSettings
	Instance.new("UICorner", apiBox3).CornerRadius = UDim.new(0,6); sy = sy + 32
	UILib.CreateButton(pageSettings, "Kaydet", UDim2.new(1,0,0,26), UDim2.new(0,0,0,sy), "Success", function()
		local combined = apiBox1.Text .. "," .. apiBox2.Text .. "," .. apiBox3.Text
		SaveGeminiKey(combined)
	end); sy = sy + 40
	UILib.CreateToggle(pageSettings, "Oto-Bilmece Çözücü:", AutoSolveRiddles, sy, function(v) AutoSolveRiddles = v; Logger.Log("Riddle Solver: " .. (v and "Açık" or "Kapalı"), "success") end)
	UILib.CreateLabel(pageSettings, "Birden fazla key virgülle ayrılarak girilir.", UDim2.new(1,0,0,30), UDim2.new(0,0,0,sy+35), "TextDim", Enum.Font.Gotham, 10)

	-- HELPERS SEKME
	local pageHelpers = CreatePage("Helpers")
	UILib.CreateLabel(pageHelpers, "Yardımcılar & Test", UDim2.new(1,0,0,20), UDim2.new(0,0,0,0), "Accent", Enum.Font.GothamBold, 14)
	local testerBox = UILib.CreateFrame(pageHelpers, UDim2.new(1,0,0,40), UDim2.new(0,0,0,25), "Panel", 8)
	UILib.CreateLabel(testerBox, "Tester: Rexyqw2", UDim2.new(1,-20,1,0), UDim2.new(0,10,0,0), "Success", Enum.Font.Code, 14)
	UILib.CreateLabel(pageHelpers, "Tema Seçimi:", UDim2.new(1,0,0,20), UDim2.new(0,0,0,75), "Text", Enum.Font.GothamBold, 12)
	local themeGrid = UILib.CreateFrame(pageHelpers, UDim2.new(1,0,0,80), UDim2.new(0,0,0,95), "Bg")
	local themesList = {"DarkRed","Black","White","Blue","Rainbow","Green"}; local btnX, btnY = 0, 0
	for _, themeName in ipairs(themesList) do
		local displayName = (themeName == "DarkRed") and "Red" or themeName
		UILib.CreateButton(themeGrid, displayName, UDim2.new(0,85,0,26), UDim2.new(0,btnX,0,btnY), "Panel", function() ThemeManager.Apply(themeName) end)
		btnX = btnX + 90; if btnX > 170 then btnX = 0; btnY = btnY + 30 end
	end
	UILib.CreateToggle(pageHelpers, "ESP (Ad + Highlight):", ESPEnabled, 185, function(v) ESPEnabled = v; ToggleESP(v) end)
	UILib.CreateButton(pageHelpers, "📋 Kod Geçmişini Göster", UDim2.new(1,0,0,26), UDim2.new(0,0,0,220), "Panel", function()
		if #CodeHistory == 0 then Logger.Log("Geçmiş boş!", "error"); return end
		for _, h in ipairs(CodeHistory) do Logger.Log("[" .. h.time .. "] " .. h.code, "success") end
	end)

	-- LOGLAR SEKME
	local pageLogs = CreatePage("Logs")
	UILib.CreateButton(pageLogs, "🗑 Logları Temizle", UDim2.new(1,0,0,26), UDim2.new(0,0,0,0), "Error", function()
		if State.logContainer then
			for _, c in ipairs(State.logContainer:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy() end
			end
		end
	end)
	local logFrame = UILib.CreateFrame(pageLogs, UDim2.new(1,0,1,-34), UDim2.new(0,0,0,32), "Black", 6)
	local logScroll = Instance.new("ScrollingFrame")
	logScroll.Size = UDim2.new(1,-6,1,-6); logScroll.Position = UDim2.new(0,3,0,3)
	logScroll.BackgroundTransparency = 1; logScroll.ScrollBarThickness = 3
	logScroll.CanvasSize = UDim2.new(0,0,0,0); logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logScroll.ScrollingDirection = Enum.ScrollingDirection.Y; logScroll.Parent = logFrame
	local logInner = UILib.CreateFrame(logScroll, UDim2.new(1,-4,0,0), UDim2.new(0,2,0,0), "Black")
	logInner.AutomaticSize = Enum.AutomaticSize.Y
	local logLayout = Instance.new("UIListLayout"); logLayout.Padding = UDim.new(0,2); logLayout.Parent = logInner
	logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
	end)
	Logger.Init(logInner)

	-- TAB BUTONLARI
	local tabNames = {{"Main","Sniper"},{"Settings","Ayarlar"},{"Helpers","Helpers"},{"Logs","Loglar"}}
	local tabY = 0
	for _, t in ipairs(tabNames) do
		UILib.CreateButton(tabContainer, t[2], UDim2.new(1,0,0,28), UDim2.new(0,0,0,tabY), "Panel", function() SwitchTab(t[1]) end); tabY = tabY + 32
	end
	SwitchTab("Main")

	State.statusLabel = UILib.CreateLabel(State.main, "» Sistem hazır...", UDim2.new(1,-20,0,20), UDim2.new(0,10,1,-45), "TextDim", Enum.Font.Gotham, 10)
	State.statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	local signature = UILib.CreateLabel(State.main, "by Beko", UDim2.new(1,0,0,15), UDim2.new(0,0,1,-20), "AccentDark", Enum.Font.GothamBold, 11)
	signature.TextXAlignment = Enum.TextXAlignment.Center
	Engine.UpdateProgress(); ThemeManager.Apply(CurrentThemeName)
end

function Initialize()
	LoadGeminiKey()
	Menu.Build()
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
	_Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function() task.wait(1); if ESPEnabled then ApplyESP(p) end end)
	end)
	for _, p in ipairs(_Players:GetPlayers()) do
		p.CharacterAdded:Connect(function() task.wait(1); if ESPEnabled then ApplyESP(p) end end)
	end
	Logger.Log("Sistem Hazır. Rexyqw2", "success")
end

-- BAŞLATICI
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
