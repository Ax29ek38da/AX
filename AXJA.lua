local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local userInput = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")

-- المتغيرات العامة للتحكم
local originalWalkSpeed = 16
local originalJumpPower = 50

-- متغيرات خانة اللاعب
local isSpeedEnabled, customSpeed = false, 16
local isJumpEnabled, customJump = false, 50
local noclipConnection, isNoclipActive = nil, false
local wallWalkConnection, isWallWalkActive = false
local isInfJumpActive = false

-- متغيرات خانة الأدوات
local isAutoSpinActive, spinSpeed = false, 5
local autoSpinConnection = nil
local isFogRemoved = false
local isFullBright, fullBrightConnection = false, nil
local invisToolObj = nil
local isInvincibleActive = false
local customToolObj = nil
local isEspActive = false
local espBillboards = {}

-- متغيرات خانة الاستهداف
local selectedTargetPlayer = nil
local spectateConnection = nil
local backpackConnection = nil
local sitOnHeadConnection = nil
local flyingConnection = nil
local bangConnection = nil

-- متغيرات خانة العشوائيات
local vehicleFlyConnection = nil
local isVehicleFlyActive = false
local antiGravityConnection = nil
local isAntiGravityActive = false
local isInfZoomActive = false
local isWallZoomActive = false
local originalOcclusionMode = player.DevCameraOcclusionMode
local antiIdleConnection = nil
local isAntiIdleActive = false
local antiSitConnection = nil
local isAntiSitActive = false
local blockProtectionConnection = nil
local isBlockProtActive = false

-- متغيرات نظام الألوان المتحركة (Rainbow)
local isRainbowActive = false
local rainbowConnection = nil

-- 1. إنشاء الشاشة الرئيسية (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 2. زر فتح وإغلاق القائمة (دائري بحرف A) + خاصية التحريك (Draggable)
local menuButton = Instance.new("TextButton")
menuButton.Name = "ToggleMenuButton"
menuButton.Size = UDim2.new(0, 50, 0, 50)
menuButton.Position = UDim2.new(0, 20, 0, 20)
menuButton.BackgroundColor3 = Color3.fromRGB(200, 25, 25)
menuButton.Text = "A"
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.TextSize = 22
menuButton.Font = Enum.Font.GothamBold
menuButton.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = menuButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.Thickness = 2.5
btnStroke.Parent = menuButton

-- برمجة تحريك الزر باللمس أو الماوس
local dragging, dragInput, dragStart, startPos
menuButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = menuButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

menuButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

userInput.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		menuButton.Position = UDim2.new(
			startPos.X.Scale, 
			startPos.X.Offset + delta.X, 
			startPos.Y.Scale, 
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- 3. القائمة الرئيسية
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MainFrame"
menuFrame.Size = UDim2.new(0, 520, 0, 280)
menuFrame.Position = UDim2.new(0.5, -260, 0.5, -140)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuFrame.BackgroundTransparency = 0.2
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 16)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(255, 255, 255)
menuStroke.Thickness = 2
menuStroke.Transparency = 0.4
menuStroke.Parent = menuFrame

-- دالة عامة لتغيير لون القائمة والزر معاً
local function applyThemeColor(newColor)
	if isRainbowActive then
		isRainbowActive = false
		if rainbowConnection then rainbowConnection:Disconnect() rainbowConnection = nil end
	end
	menuFrame.BackgroundColor3 = newColor
	if menuFrame.Visible then
		menuButton.BackgroundColor3 = newColor
	end
end

--------------------------------------------------------------------------------
-- [ نظام الرتب التلقائي لمربعات الـ ESP (عضو vs مسؤول) ]
--------------------------------------------------------------------------------
local function applyRoleTag(character, targetPlayer)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if head and not head:FindFirstChild("GlobalRoleTag") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "GlobalRoleTag"
		billboard.Size = UDim2.new(0, 160, 0, 60)
		billboard.AlwaysOnTop = true
		billboard.StudsOffset = Vector3.new(0, 2.8, 0)
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextSize = 13
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextStrokeTransparency = 0
		
		-- التحقق من الحساب الخاص بك
		if targetPlayer.Name == "eokzmm" then
			textLabel.Text = "👑 [مسؤول السكربت]\n" .. targetPlayer.Name
			textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- لون ذهبي ملكي للأدمن
		else
			textLabel.Text = "👤 [عضو]\n" .. targetPlayer.Name
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- لون أبيض للأعضاء
		end
		
		textLabel.Parent = billboard
		billboard.Parent = head
	end
end

-- تفعيل رتبة الـ ESP لجميع اللاعبين تلقائياً
for _, p in ipairs(game.Players:GetPlayers()) do
	if p.Character then
		applyRoleTag(p.Character, p)
	end
	p.CharacterAdded:Connect(function(char)
		task.wait(1)
		applyRoleTag(char, p)
	end)
end

game.Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(1)
		applyRoleTag(char, p)
	end)
end)

--------------------------------------------------------------------------------
-- [ أنيميشن التحقق والهوية والبصمة عند التشغيل الأول ]
--------------------------------------------------------------------------------
local function playVerificationAnimation(onComplete)
	local animGui = Instance.new("ScreenGui")
	animGui.Name = "VerificationAnimGui"
	animGui.ResetOnSpawn = false
	animGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bg.BackgroundTransparency = 1
	bg.Parent = animGui

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 320, 0, 200)
	card.Position = UDim2.new(0.5, -160, 0.5, -100)
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	card.BackgroundTransparency = 1
	card.Parent = bg

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 12)
	cCorner.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(200, 25, 25)
	cStroke.Thickness = 2
	cStroke.Transparency = 1
	cStroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = "جاري التحقق من الهوية..."
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 1
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = card

	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, 0, 0, 20)
	idLabel.Position = UDim2.new(0, 0, 0, 50)
	idLabel.BackgroundTransparency = 1
	idLabel.Text = "المستخدم: " .. player.Name .. " | ID: " .. player.UserId
	idLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	idLabel.TextTransparency = 1
	idLabel.TextSize = 11
	idLabel.Font = Enum.Font.Gotham
	idLabel.Parent = card

	local fingerprint = Instance.new("TextButton")
	fingerprint.Size = UDim2.new(0, 60, 0, 60)
	fingerprint.Position = UDim2.new(0.5, -30, 0, 85)
	fingerprint.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fingerprint.BackgroundTransparency = 1
	fingerprint.Text = "🛡️"
	fingerprint.TextSize = 28
	fingerprint.Parent = card

	local fpCorner = Instance.new("UICorner")
	fpCorner.CornerRadius = UDim.new(1, 0)
	fpCorner.Parent = fingerprint

	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(1, 0, 0, 30)
	statusText.Position = UDim2.new(0, 0, 0, 155)
	statusText.BackgroundTransparency = 1
	statusText.Text = "اضغط على البصمة للبدء"
	statusText.TextColor3 = Color3.fromRGB(200, 25, 25)
	statusText.TextTransparency = 1
	statusText.TextSize = 12
	statusText.Font = Enum.Font.GothamBold
	statusText.Parent = card

	game:GetService("TweenService"):Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
	game:GetService("TweenService"):Create(card, TweenInfo.new(0.5), {BackgroundTransparency = 0.1}):Play()
	game:GetService("TweenService"):Create(cStroke, TweenInfo.new(0.5), {Transparency = 0}):Play()
	game:GetService("TweenService"):Create(title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	game:GetService("TweenService"):Create(idLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	game:GetService("TweenService"):Create(fingerprint, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	game:GetService("TweenService"):Create(statusText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	local verified = false
	fingerprint.MouseButton1Click:Connect(function()
		if verified then return end
		verified = true
		statusText.Text = "تم تأكيد البصمة بنجاح!"
		fingerprint.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		
		task.wait(0.8)
		
		game:GetService("TweenService"):Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		game:GetService("TweenService"):Create(card, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		game:GetService("TweenService"):Create(cStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
		game:GetService("TweenService"):Create(title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		game:GetService("TweenService"):Create(idLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		game:GetService("TweenService"):Create(fingerprint, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		game:GetService("TweenService"):Create(statusText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		
		task.wait(0.5)
		animGui:Destroy()
		if onComplete then onComplete() end
	end)
end

local hasVerified = false
menuButton.MouseButton1Click:Connect(function()
	if not hasVerified then
		playVerificationAnimation(function()
			hasVerified = true
			menuFrame.Visible = true
			if not isRainbowActive then
				menuButton.BackgroundColor3 = menuFrame.BackgroundColor3
			end
		end)
	else
		menuFrame.Visible = not menuFrame.Visible
		if menuFrame.Visible and not isRainbowActive then
			menuButton.BackgroundColor3 = menuFrame.BackgroundColor3
		end
	end
end)

-- 4. الهيدر العلوي
local headerContainer = Instance.new("Frame")
headerContainer.Size = UDim2.new(1, 0, 0, 32)
headerContainer.BackgroundTransparency = 1
headerContainer.Parent = menuFrame

local playersCountLabel = Instance.new("TextLabel")
playersCountLabel.Size = UDim2.new(0, 130, 0, 20)
playersCountLabel.Position = UDim2.new(0, 10, 0, 4)
playersCountLabel.BackgroundTransparency = 1
playersCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
playersCountLabel.TextSize = 11
playersCountLabel.Font = Enum.Font.GothamBold
playersCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playersCountLabel.Text = "اللاعبون: 0"
playersCountLabel.Parent = headerContainer

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 220, 0, 20)
titleLabel.Position = UDim2.new(0.5, -110, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Text = "سكريبت الشياطين الجديد"
titleLabel.Parent = headerContainer

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 110, 0, 20)
fpsLabel.Position = UDim2.new(1, -120, 0, 4)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
fpsLabel.TextSize = 11
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Text = "FPS: 60"
fpsLabel.Parent = headerContainer

local whiteLine = Instance.new("Frame")
whiteLine.Size = UDim2.new(1, -20, 0, 1)
whiteLine.Position = UDim2.new(0, 10, 0, 28)
whiteLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
whiteLine.BorderSizePixel = 0
whiteLine.Parent = headerContainer

local lastUpdate = 0
local frameCount = 0
runService.RenderStepped:Connect(function(dt)
	frameCount = frameCount + 1
	lastUpdate = lastUpdate + dt
	if lastUpdate >= 0.5 then
		local currentFps = math.floor(frameCount / lastUpdate)
		fpsLabel.Text = "FPS: " .. tostring(currentFps)
		playersCountLabel.Text = "اللاعبون: " .. tostring(#game.Players:GetPlayers())
		frameCount = 0
		lastUpdate = 0
	end
end)

-- 5. القائمة الجانبية (Sidebar)
local sidebar = Instance.new("ScrollingFrame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 130, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 36)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sidebar.BackgroundTransparency = 0.3
sidebar.CanvasSize = UDim2.new(0, 0, 0, 420)
sidebar.ScrollBarThickness = 2
sidebar.Parent = menuFrame

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 5)
sideLayout.Parent = sidebar

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 16)
sideCorner.Parent = sidebar

local function createTabButton(name, text, defaultColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = defaultColor
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	return btn
end

local playerTabBtn = createTabButton("PlayerTab", "خانة اللاعب", Color3.fromRGB(200, 25, 25))
playerTabBtn.Parent = sidebar
local toolsTabBtn = createTabButton("ToolsTab", "خانة الأدوات", Color3.fromRGB(60, 60, 60))
toolsTabBtn.Parent = sidebar
local targetTabBtn = createTabButton("TargetTab", "الاستهداف", Color3.fromRGB(60, 60, 60))
targetTabBtn.Parent = sidebar
local randomTabBtn = createTabButton("RandomTab", "عشوائيات", Color3.fromRGB(60, 60, 60))
randomTabBtn.Parent = sidebar
local serverTabBtn = createTabButton("ServerTab", "أقسام السيرفر", Color3.fromRGB(60, 60, 60))
serverTabBtn.Parent = sidebar
local scriptsTabBtn = createTabButton("ScriptsTab", "السكريبتات", Color3.fromRGB(60, 60, 60))
scriptsTabBtn.Parent = sidebar
local antiTabBtn = createTabButton("AntiTab", "سكريبتات المضاد", Color3.fromRGB(60, 60, 60))
antiTabBtn.Parent = sidebar
local leaderTabBtn = createTabButton("LeaderTab", "خاص بالقائد", Color3.fromRGB(150, 100, 0)) -- زر خاص مميز
leaderTabBtn.Parent = sidebar
local themeTabBtn = createTabButton("ThemeTab", "التخصيص والآلوان", Color3.fromRGB(60, 60, 60))
themeTabBtn.Parent = sidebar

local verticalDivider = Instance.new("Frame")
verticalDivider.Name = "Divider"
verticalDivider.Size = UDim2.new(0, 2, 1, -48)
verticalDivider.Position = UDim2.new(0, 135, 0, 40)
verticalDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
verticalDivider.BackgroundTransparency = 0.6
verticalDivider.Parent = menuFrame

local function createContentFrame(name, canvasHeight)
	local content = Instance.new("ScrollingFrame")
	content.Name = name
	content.Size = UDim2.new(1, -145, 1, -48)
	content.Position = UDim2.new(0, 142, 0, 40)
	content.BackgroundTransparency = 1
	content.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
	content.ScrollBarThickness = 4
	content.Visible = false
	
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = content
	
	content.Parent = menuFrame
	return content
end

local playerContent = createContentFrame("PlayerContent", 400)
playerContent.Visible = true
local toolsContent = createContentFrame("ToolsContent", 450)
local targetContent = createContentFrame("TargetContent", 650)
local randomContent = createContentFrame("RandomContent", 500)
local serverContent = createContentFrame("ServerContent", 350)
local scriptsContent = createContentFrame("ScriptsContent", 350)
local antiContent = createContentFrame("AntiContent", 300)
local leaderContent = createContentFrame("LeaderContent", 400)
local themeContent = createContentFrame("ThemeContent", 400)

local allTabs = {playerTabBtn, toolsTabBtn, targetTabBtn, randomTabBtn, serverTabBtn, scriptsTabBtn, antiTabBtn, leaderTabBtn, themeTabBtn}
local allContents = {playerContent, toolsContent, targetContent, randomContent, serverContent, scriptsContent, antiContent, leaderContent, themeContent}

local function switchTab(selectedBtn, selectedContent)
	for _, btn in ipairs(allTabs) do 
		if btn ~= leaderTabBtn then
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) 
		end
	end
	for _, content in ipairs(allContents) do content.Visible = false end
	if selectedBtn ~= leaderTabBtn then
		selectedBtn.BackgroundColor3 = Color3.fromRGB(200, 25, 25)
	end
	selectedContent.Visible = true
end

playerTabBtn.MouseButton1Click:Connect(function() switchTab(playerTabBtn, playerContent) end)
toolsTabBtn.MouseButton1Click:Connect(function() switchTab(toolsTabBtn, toolsContent) end)
targetTabBtn.MouseButton1Click:Connect(function() switchTab(targetTabBtn, targetContent) end)
randomTabBtn.MouseButton1Click:Connect(function() switchTab(randomTabBtn, randomContent) end)
serverTabBtn.MouseButton1Click:Connect(function() switchTab(serverTabBtn, serverContent) end)
scriptsTabBtn.MouseButton1Click:Connect(function() switchTab(scriptsTabBtn, scriptsContent) end)
antiTabBtn.MouseButton1Click:Connect(function() switchTab(antiTabBtn, antiContent) end)
themeTabBtn.MouseButton1Click:Connect(function() switchTab(themeTabBtn, themeContent) end)

local function createRow(parentContainer, name, isInputType, defaultVal, btnText1, btnText2, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.BackgroundTransparency = 0.4
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 135, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	
	if isInputType then
		local textBox = Instance.new("TextBox")
		textBox.Size = UDim2.new(0, 45, 0, 24)
		textBox.Position = UDim2.new(0, 145, 0.5, -12)
		textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		textBox.Text = tostring(defaultVal)
		textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		textBox.TextSize = 12
		textBox.Font = Enum.Font.Gotham
		textBox.Parent = row
		
		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 6)
		boxCorner.Parent = textBox
		
		local actBtn = Instance.new("TextButton")
		actBtn.Size = UDim2.new(0, 95, 0, 24)
		actBtn.Position = UDim2.new(0, 195, 0.5, -12)
		actBtn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		actBtn.Text = btnText1
		actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		actBtn.TextSize = 11
		actBtn.Font = Enum.Font.GothamBold
		actBtn.Parent = row
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = actBtn
		
		actBtn.MouseButton1Click:Connect(function()
			callback(textBox, actBtn)
		end)
	else
		local actBtn = Instance.new("TextButton")
		actBtn.Size = UDim2.new(0, 105, 0, 24)
		actBtn.Position = UDim2.new(1, -113, 0.5, -12)
		actBtn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		actBtn.Text = btnText2
		actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		actBtn.TextSize = 11
		actBtn.Font = Enum.Font.GothamBold
		actBtn.Parent = row
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = actBtn
		
		actBtn.MouseButton1Click:Connect(function()
			callback(actBtn)
		end)
	end
	
	row.Parent = parentContainer
end

--------------------------------------------------------------------------------
-- [ 1. خانة اللاعب ]
--------------------------------------------------------------------------------
createRow(playerContent, "سرعة اللاعب", true, 16, "تفعيل", "", function(textBox, btn)
	isSpeedEnabled = not isSpeedEnabled
	customSpeed = tonumber(textBox.Text) or 16
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if isSpeedEnabled then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		if hum then hum.WalkSpeed = customSpeed end
	else
		btn.Text = "تفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if hum then hum.WalkSpeed = originalWalkSpeed end
	end
end)

createRow(playerContent, "قوة القفز", true, 50, "تفعيل", "", function(textBox, btn)
	isJumpEnabled = not isJumpEnabled
	customJump = tonumber(textBox.Text) or 50
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if isJumpEnabled then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		if hum then hum.UseJumpPower = true hum.JumpPower = customJump end
	else
		btn.Text = "تفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if hum then hum.JumpPower = originalJumpPower end
	end
end)

createRow(playerContent, "اختراق الجدران", false, nil, "", "إيقاف", function(btn)
	isNoclipActive = not isNoclipActive
	if isNoclipActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		noclipConnection = runService.Stepped:Connect(function()
			local char = player.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
	end
end)

createRow(playerContent, "المشي على الجدران", false, nil, "", "إيقاف", function(btn)
	isWallWalkActive = not isWallWalkActive
	if isWallWalkActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		wallWalkConnection = runService.RenderStepped:Connect(function()
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local ray = Ray.new(hrp.Position, hrp.CFrame.LookVector * 2)
					local hit = workspace:FindPartOnRay(ray, char)
					if hit then hrp.Velocity = Vector3.new(hrp.Velocity.X, 35, hrp.Velocity.Z) end
				end
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if wallWalkConnection then wallWalkConnection:Disconnect() wallWalkConnection = nil end
	end
end)

createRow(playerContent, "ريست الشخصية", false, nil, "", "إيقاف", function(btn)
	btn.Text = "تم التنفيذ"
	btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
	task.delay(1, function() btn.Text = "إيقاف" btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20) end)
end)

createRow(playerContent, "قفز لانهائي", false, nil, "", "إيقاف", function(btn)
	isInfJumpActive = not isInfJumpActive
	if isInfJumpActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	end
end)

userInput.JumpRequest:Connect(function()
	if isInfJumpActive then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

--------------------------------------------------------------------------------
-- [ 2. خانة الأدوات ]
--------------------------------------------------------------------------------
createRow(toolsContent, "أداة الدوران", true, 5, "تفعيل", "", function(textBox, btn)
	spinSpeed = tonumber(textBox.Text) or 5
	isAutoSpinActive = not isAutoSpinActive
	if isAutoSpinActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		autoSpinConnection = runService.RenderStepped:Connect(function()
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0) end
		end)
	else
		btn.Text = "تفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if autoSpinConnection then autoSpinConnection:Disconnect() autoSpinConnection = nil end
	end
end)

createRow(toolsContent, "إزالة الضباب", false, nil, "", "إيقاف", function(btn)
	isFogRemoved = not isFogRemoved
	if isFogRemoved then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		lighting.FogEnd = 1000000
		lighting.GlobalShadows = false
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		lighting.FogEnd = 100000
		lighting.GlobalShadows = true
	end
end)

createRow(toolsContent, "إضاءة كاملة", true, 2, "تفعيل", "", function(textBox, btn)
	isFullBright = not isFullBright
	local brightnessVal = tonumber(textBox.Text) or 2
	if isFullBright then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		fullBrightConnection = runService.RenderStepped:Connect(function()
			lighting.Brightness = brightnessVal
			lighting.ClockTime = 14
		end)
	else
		btn.Text = "تفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if fullBrightConnection then fullBrightConnection:Disconnect() fullBrightConnection = nil end
		lighting.Brightness = 1
	end
end)

createRow(toolsContent, "أداة الاختفاء", false, nil, "", "تجهيز الأداة", function(btn)
	isInvincibleActive = not isInvincibleActive
	if isInvincibleActive then
		btn.Text = "إزالة الأداة"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		invisToolObj = Instance.new("Tool")
		invisToolObj.Name = "أداة الاختفاء"
		invisToolObj.RequiresHandle = false
		local invisLoop = nil
		invisToolObj.Equipped:Connect(function()
			invisLoop = task.spawn(function()
				while true do
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local oldPos = hrp.CFrame
						hrp.CFrame = CFrame.new(0, 99999, 0)
						task.wait(0.2)
						hrp.CFrame = oldPos
					end
					task.wait(0.5)
				end
			end)
		end)
		invisToolObj.Unequipped:Connect(function()
			if invisLoop then task.cancel(invisLoop) invisLoop = nil end
		end)
		invisToolObj.Parent = player.Backpack
	else
		btn.Text = "تجهيز الأداة"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if invisToolObj then invisToolObj:Destroy() invisToolObj = nil end
	end
end)

createRow(toolsContent, "أداة الحركة اليدوية", false, nil, "", "تجهيز الأداة", function(btn)
	local active = false
	active = not active
	if active then
		btn.Text = "حمل الأداة"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		customToolObj = Instance.new("Tool")
		customToolObj.Name = "أداة تفاعلية"
		customToolObj.RequiresHandle = false
		customToolObj.Activated:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hum and hrp then
				hum.WalkSpeed = 28
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
				task.wait(0.2)
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(-90), 0)
			end
		end)
		customToolObj.Parent = player.Backpack
	else
		btn.Text = "تجهيز الأداة"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if customToolObj then customToolObj:Destroy() customToolObj = nil end
	end
end)

createRow(toolsContent, "كشف اللاعبين (ESP)", false, nil, "", "إيقاف", function(btn)
	isEspActive = not isEspActive
	if isEspActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= player and p.Character then
				local head = p.Character:FindFirstChild("Head")
				if head and not head:FindFirstChild("ESP_Tag") then
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "ESP_Tag"
					billboard.Size = UDim2.new(0, 120, 0, 50)
					billboard.AlwaysOnTop = true
					billboard.StudsOffset = Vector3.new(0, 2.5, 0)
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
					textLabel.TextStrokeTransparency = 0
					textLabel.TextSize = 12
					textLabel.Font = Enum.Font.GothamBold
					textLabel.Parent = billboard
					billboard.Parent = head
					table.insert(espBillboards, billboard)
				end
			end
		end
		spawn(function()
			while isEspActive do
				local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				for _, b in ipairs(espBillboards) do
					if b and b.Parent and myHrp then
						local targetPart = b.Parent.Parent:FindFirstChild("HumanoidRootPart")
						if targetPart then
							local dist = math.floor((myHrp.Position - targetPart.Position).Magnitude)
							local playerName = b.Parent.Parent.Name
							b.TextLabel.Text = playerName .. "\n[" .. dist .. "m]"
						end
					end
				end
				task.wait(0.5)
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		isEspActive = false
		for _, b in ipairs(espBillboards) do if b then b:Destroy() end end
		espBillboards = {}
	end
end)

--------------------------------------------------------------------------------
-- [ 3. خانة الاستهداف ]
--------------------------------------------------------------------------------
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -10, 0, 160)
searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
searchFrame.BackgroundTransparency = 0.4
searchFrame.Parent = targetContent

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -16, 0, 30)
searchBox.Position = UDim2.new(0, 8, 0, 8)
searchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
searchBox.PlaceholderText = "اكتب 3 أحرف أو أكثر للبحث عن اللاعب..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 12
searchBox.Font = Enum.Font.Gotham
searchBox.Parent = searchFrame

local sBoxCorner = Instance.new("UICorner")
sBoxCorner.CornerRadius = UDim.new(0, 6)
sBoxCorner.Parent = searchBox

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, -16, 0, 105)
playersScroll.Position = UDim2.new(0, 8, 0, 46)
playersScroll.BackgroundTransparency = 1
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.ScrollBarThickness = 4
playersScroll.Parent = searchFrame

local pLayout = Instance.new("UIListLayout")
pLayout.SortOrder = Enum.SortOrder.LayoutOrder
pLayout.Padding = UDim.new(0, 4)
pLayout.Parent = playersScroll

local function updatePlayerList()
	for _, child in ipairs(playersScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local filterText = string.lower(searchBox.Text)
	local count = 0
	for _, p in ipairs(game.Players:GetPlayers()) do
		if p ~= player then
			local pName = string.lower(p.Name)
			local pDisplay = string.lower(p.DisplayName)
			if #filterText < 3 or string.sub(pName, 1, #filterText) == filterText or string.sub(pDisplay, 1, #filterText) == filterText then
				count = count + 1
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 28)
				btn.BackgroundColor3 = (selectedTargetPlayer == p) and Color3.fromRGB(20, 160, 20) or Color3.fromRGB(50, 50, 50)
				btn.Text = p.Name .. " (" .. p.DisplayName .. ")"
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.TextSize = 12
				btn.Font = Enum.Font.GothamSemibold
				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 6)
				bCorner.Parent = btn
				btn.MouseButton1Click:Connect(function()
					selectedTargetPlayer = p
					updatePlayerList()
				end)
				btn.Parent = playersScroll
			end
		end
	end
	playersScroll.CanvasSize = UDim2.new(0, 0, 0, count * 32)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(updatePlayerList)
game.Players.PlayerAdded:Connect(updatePlayerList)
game.Players.PlayerRemoving:Connect(updatePlayerList)
task.spawn(function()
	while true do updatePlayerList() task.wait(2) end
end)

createRow(targetContent, "مراقبة الشخص", false, nil, "", "إيقاف", function(btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً أولاً"
		task.delay(1.5, function() btn.Text = "إيقاف" end)
		return
	end
	if spectateConnection then
		spectateConnection:Disconnect()
		spectateConnection = nil
		camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	else
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		spectateConnection = runService.RenderStepped:Connect(function()
			if selectedTargetPlayer and selectedTargetPlayer.Character then
				local hum = selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if hum then camera.CameraSubject = hum end
			end
		end)
	end
end)

createRow(targetContent, "التنقل الفوري", false, nil, "", "انتقال", function(btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً أولاً"
		task.delay(1.5, function() btn.Text = "انتقال" end)
		return
	end
	local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local targetHrp = selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if myHrp and targetHrp then
		myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
		btn.Text = "تم التنقل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		task.delay(1, function() btn.Text = "انتقال" btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20) end)
	end
end)

createRow(targetContent, "حقيبة الظهر", false, nil, "", "إيقاف", function(btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً أولاً"
		task.delay(1.5, function() btn.Text = "إيقاف" end)
		return
	end
	if backpackConnection then
		backpackConnection:Disconnect()
		backpackConnection = nil
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	else
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		backpackConnection = runService.Stepped:Connect(function()
			local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local targetHrp = selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myHrp and targetHrp then
				myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1.2)
			end
		end)
	end
end)

createRow(targetContent, "جلوس على الرأس", false, nil, "", "إيقاف", function(btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً أولاً"
		task.delay(1.5, function() btn.Text = "إيقاف" end)
		return
	end
	if sitOnHeadConnection then
		sitOnHeadConnection:Disconnect()
		sitOnHeadConnection = nil
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = false end
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	else
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		sitOnHeadConnection = runService.Stepped:Connect(function()
			local myChar = player.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
			local targetHead = selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("Head")
			if myHrp and myHum and targetHead then
				myHum.Sit = true
				myHrp.CFrame = targetHead.CFrame + Vector3.new(0, 1.5, 0)
			end
		end)
	end
end)

createRow(targetContent, "فلينق (دوران بسرعة)", true, 10, "تفعيل", "", function(textBox, btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً"
		task.delay(1.5, function() btn.Text = "تفعيل" end)
		return
	end
	local speedVal = tonumber(textBox.Text) or 10
	if flyingConnection then
		flyingConnection:Disconnect()
		flyingConnection = nil
		btn.Text = "تفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	else
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		local angle = 0
		flyingConnection = runService.RenderStepped:Connect(function(dt)
			local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local targetHrp = selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myHrp and targetHrp then
				angle = angle + (speedVal * dt)
				local radius = 5
				local offset = Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
				myHrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
			end
		end)
	end
end)

createRow(targetContent, "بانق (+18)", false, nil, "", "إيقاف", function(btn)
	if not selectedTargetPlayer then
		btn.Text = "اختر لاعباً أولاً"
		task.delay(1.5, function() btn.Text = "إيقاف" end)
		return
	end
	if bangConnection then
		bangConnection:Disconnect()
		bangConnection = nil
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	else
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		local timePassed = 0
		bangConnection = runService.Stepped:Connect(function(dt)
			local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local targetHrp = selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myHrp and targetHrp then
				timePassed = timePassed + (dt * 15)
				local zOffset = 1.0 + (math.sin(timePassed) * 0.7)
				myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, zOffset)
			end
		end)
	end
end)

--------------------------------------------------------------------------------
-- [ 4. خانة العشوائيات ]
--------------------------------------------------------------------------------
createRow(randomContent, "طيران المركبة", false, nil, "", "إيقاف", function(btn)
	isVehicleFlyActive = not isVehicleFlyActive
	if isVehicleFlyActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		vehicleFlyConnection = runService.RenderStepped:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.SeatPart then
				local vehicle = hum.SeatPart.Parent
				local primaryPart = vehicle:IsA("Model") and vehicle.PrimaryPart or vehicle:FindFirstChild("HumanoidRootPart") or hum.SeatPart
				if primaryPart then
					primaryPart.AssemblyLinearVelocity = camera.CFrame.LookVector * 50
				end
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if vehicleFlyConnection then
			vehicleFlyConnection:Disconnect()
			vehicleFlyConnection = nil
		end
	end
end)

createRow(randomContent, "انعدام الجاذبية", false, nil, "", "إيقاف", function(btn)
	isAntiGravityActive = not isAntiGravityActive
	if isAntiGravityActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		workspace.Gravity = 0
		antiGravityConnection = runService.Stepped:Connect(function()
			workspace.Gravity = 0
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if antiGravityConnection then
			antiGravityConnection:Disconnect()
			antiGravityConnection = nil
		end
		workspace.Gravity = 196.2
	end
end)

createRow(randomContent, "زوم لا نهائي", false, nil, "", "إيقاف", function(btn)
	isInfZoomActive = not isInfZoomActive
	if isInfZoomActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		player.CameraMaxZoomDistance = 999999
		player.CameraMinZoomDistance = 0
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		player.CameraMaxZoomDistance = 400
		player.CameraMinZoomDistance = 0.5
	end
end)

createRow(randomContent, "زوم يخترق الجدران", false, nil, "", "إيقاف", function(btn)
	isWallZoomActive = not isWallZoomActive
	if isWallZoomActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		player.DevCameraOcclusionMode = originalOcclusionMode
	end
end)

createRow(randomContent, "مضاد طرد الخمول", false, nil, "", "إيقاف", function(btn)
	isAntiIdleActive = not isAntiIdleActive
	if isAntiIdleActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		local vu = game:GetService("VirtualUser")
		antiIdleConnection = player.Idled:Connect(function()
			vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if antiIdleConnection then
			antiIdleConnection:Disconnect()
			antiIdleConnection = nil
		end
	end
end)

createRow(randomContent, "مضاد الجلوس", false, nil, "", "إيقاف", function(btn)
	isAntiSitActive = not isAntiSitActive
	if isAntiSitActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		antiSitConnection = runService.RenderStepped:Connect(function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Sit then
				hum.Sit = false
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if antiSitConnection then
			antiSitConnection:Disconnect()
			antiSitConnection = nil
		end
	end
end)

createRow(randomContent, "حماية تطير البلوكات", false, nil, "", "إيقاف", function(btn)
	isBlockProtActive = not isBlockProtActive
	if isBlockProtActive then
		btn.Text = "تم التفعيل"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		blockProtectionConnection = runService.RenderStepped:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, part in ipairs(workspace:GetPartsInPart(hrp)) do
					if part and part.Parent ~= char and not part.Anchored and part.Name ~= "Terrain" then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		btn.Text = "إيقاف"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		if blockProtectionConnection then
			blockProtectionConnection:Disconnect()
			blockProtectionConnection = nil
		end
	end
end)

--------------------------------------------------------------------------------
-- [ 5. خانة أقسام السيرفر ]
--------------------------------------------------------------------------------
createRow(serverContent, "إعادة دخول السيرفر", false, nil, "", "إعادة دخول", function(btn)
	btn.Text = "جاري الدخول..."
	btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
	pcall(function()
		if #game.Players:GetPlayers() <= 1 then
			player:Kick("\nإعادة الدخول...")
			task.wait(0.5)
			teleportService:Teleport(game.PlaceId, player)
		else
			teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		end
	end)
end)

createRow(serverContent, "تغيير سيرفر عشوائي", false, nil, "", "تغيير", function(btn)
	btn.Text = "جاري البحث..."
	btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
	pcall(function()
		local servers = {}
		local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		local data = httpService:JSONDecode(req)
		if data and data.data then
			for _, s in ipairs(data.data) do
				if type(s) == "table" and s.id and s.playing < s.maxPlayers and s.id ~= game.JobId then
					table.insert(servers, s.id)
				end
			end
		end
		if #servers > 0 then
			teleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
		else
			btn.Text = "لا توجد سيرفرات"
			task.delay(1.5, function() btn.Text = "تغيير" btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20) end)
		end
	end)
end)

createRow(serverContent, "نسخ كود السيرفر الحالي", false, nil, "", "نسخ الكود", function(btn)
	pcall(function()
		if setclipboard then
			setclipboard(game.JobId)
		end
	end)
	btn.Text = "تم النسخ!"
	btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
	task.delay(1.5, function()
		btn.Text = "نسخ الكود"
		btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
	end)
end)

createRow(serverContent, "دخول بكود سيرفر", true, "", "دخول", "", function(textBox, btn)
	local targetJobId = textBox.Text
	if targetJobId and targetJobId ~= "" then
		btn.Text = "جاري النقل..."
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		pcall(function()
			teleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, player)
		end)
		task.delay(2, function()
			btn.Text = "دخول"
			btn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
		end)
	else
		btn.Text = "اكتب الكود أولاً"
		task.delay(1.5, function()
			btn.Text = "دخول"
		end)
	end
end)

--------------------------------------------------------------------------------
-- [ 6. قسم السكريبتات ]
--------------------------------------------------------------------------------
local function createScriptBoxButton(name, yPos, url)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 36)
	btn.Position = UDim2.new(0, 8, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(20, 20, 20)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.Parent = scriptsContent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 25, 25)
	stroke.Thickness = 1.5
	stroke.Parent = btn

	btn.MouseButton1Click:Connect(function()
		pcall(function()
			loadstring(game:HttpGet(url))()
		end)
		btn.Text = name .. " (تم التفعيل ✓)"
		btn.BackgroundColor3 = Color3.fromRGB(20, 160, 20)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		task.delay(2, function()
			btn.Text = name
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextColor3 = Color3.fromRGB(20, 20, 20)
		end)
	end)
end

createScriptBoxButton("الطيران (Flight)", 10, "https://rawscripts.net/raw/Universal-Script-flight-of-the-Invincible-59729")
createScriptBoxButton("الرقصات (Emotes)", 54, "https://rawscripts.net/raw/Universal-Script-Gaze-emotes-V1-54374")
createScriptBoxButton("النقاط (No9at Samlat)", 98, "https://rawscripts.net/raw/Universal-Script-NO9AT-SAMLAT-47637")
createScriptBoxButton("الاوتو كلكر (Auto Click)", 142, "https://rawscripts.net/raw/Universal-Script-AUTOCLICK-48479")

--------------------------------------------------------------------------------
-- [ 7. خانة سكريبتات المضاد ]
--------------------------------------------------------------------------------
local fpsScriptBtn = Instance.new("TextButton")
fpsScriptBtn.Size = UDim2.new(1, -16, 0, 36)
fpsScriptBtn.Position = UDim2.new(0, 8, 0, 10)
fpsScriptBtn.BackgroundColor3 = Color3.fromRGB(200, 25, 25)
fpsScriptBtn.Text = "تشغيل سكريبت 120 الفريم"
fpsScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsScriptBtn.TextSize = 12
fpsScriptBtn.Font = Enum.Font.GothamBold
fpsScriptBtn.Parent = antiContent

local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 6)
fpsCorner.Parent = fpsScriptBtn

fpsScriptBtn.MouseButton1Click:Connect(function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/MrLamon/MLamon-Hub/refs/heads/main/Protected_4747902775072511.lua.txt"))()
	end)
	fpsScriptBtn.Text = "تم تفعيل سكريبت 120 الفريم بنجاح!"
	task.delay(1.5, function()
		fpsScriptBtn.Text = "تشغيل سكريبت 120 الفريم"
	end)
end)

local antiAfkBtn = Instance.new("TextButton")
antiAfkBtn.Size = UDim2.new(1, -16, 0, 36)
antiAfkBtn.Position = UDim2.new(0, 8, 0, 54)
antiAfkBtn.BackgroundColor3 = Color3.fromRGB(200, 25, 25)
antiAfkBtn.Text = "تشغيل مضاد الخمول والطرد (Anti-AFK)"
antiAfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAfkBtn.TextSize = 12
antiAfkBtn.Font = Enum.Font.GothamBold
antiAfkBtn.Parent = antiContent

local antiAfkCorner = Instance.new("UICorner")
antiAfkCorner.CornerRadius = UDim.new(0, 6)
antiAfkCorner.Parent = antiAfkBtn

antiAfkBtn.MouseButton1Click:Connect(function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RealBatu20/AI-Scripts-2025/refs/heads/main/AntiAFK_AntiKickV3.lua", true))()
	end)
	antiAfkBtn.Text = "تم تفعيل مضاد الخمول والطرد بنجاح!"
	task.delay(1.5, function()
		antiAfkBtn.Text = "تشغيل مضاد الخمول والطرد (Anti-AFK)"
	end)
end)

--------------------------------------------------------------------------------
-- [ 8. خانة خاص بالقائد (مع حماية كلمة السر AX123 والزر الإضافي) ]
--------------------------------------------------------------------------------
-- حاوية إدخال كلمة السر
local passwordFrame = Instance.n
