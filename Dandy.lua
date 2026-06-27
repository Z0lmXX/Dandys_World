local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Global configuration states
_G.AutoInteract = false
_G.QTEAutomator = false
_G.ESPEnabled = false
_G.MonsterESPEnabled = false
_G.MachineESPEnabled = false
_G.LoopSpeedEnabled = false       
_G.CustomSpeedValue = 35          
_G.FlyEnabled = false
_G.FlySpeed = 50

local EspConnection, MonsterConnection, MachineLoop, QteConnection, FlyConnection

-- ==========================================
-- UNIVERSAL SCANNERS (TARGETED FOR DANDY'S WORLD)
-- ==========================================

local function isExtractor(obj)
	if not obj:IsA("Model") then return false end
	local name = obj.Name
	return name == "Ichor Extractor" or name == "Extractor" or name == "Generator" or name == "IchorExtractor"
end

local function getMachineProgress(machine)
	local progressObj = machine:FindFirstChild("Progress") or machine:FindFirstChild("ProgressValue") or machine:FindFirstChild("Percent")
	if progressObj and progressObj:IsA("ValueBase") then
		return progressObj.Value
	end
	
	local prompt = machine:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		return prompt.Enabled and 0 or 100
	end
	
	return 100
end

local function isTwistedMonster(obj)
	if not obj:IsA("Model") or Players:GetPlayerFromCharacter(obj) then return false end
	
	local nameLower = string.lower(obj.Name)
	if string.find(nameLower, "twisted") or obj:FindFirstChild("Enemy") or obj:FindFirstChild("Goon") then
		return true
	end
	
	local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
	if string.find(parentName, "monster") or string.find(parentName, "enemy") or string.find(parentName, "twisted") then
		return true
	end
	
	return false
end

-- ==========================================
-- 1. MAIN UI FRAMEWORK
-- ==========================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CapperFunctionalPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 320)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true 
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "CapperTitle"
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
titleLabel.Text = "  CAPPER PANEL v3"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 5)
headerFix.Position = UDim2.new(0, 0, 1, -5)
headerFix.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
headerFix.BorderSizePixel = 0
headerFix.Parent = titleLabel

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 120, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 10)
sidebarPadding.Parent = sidebar

local pagesContainer = Instance.new("Frame")
pagesContainer.Name = "PagesContainer"
pagesContainer.Size = UDim2.new(1, -135, 1, -55)
pagesContainer.Position = UDim2.new(0, 130, 0, 50)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

local savedStates = { Toggles = {}, Sliders = {} }
local tabsList = {}
local pageFrames = {}

-- ==========================================
-- 2. CORE UI CONSTRUCTORS
-- ==========================================

local function getPage(tabName)
	if pageFrames[tabName] then return pageFrames[tabName] end
	local newPage = Instance.new("Frame")
	newPage.Name = tabName .. "Page"
	newPage.Size = UDim2.new(1, 0, 1, 0)
	newPage.BackgroundTransparency = 1
	newPage.Visible = false
	newPage.Parent = pagesContainer
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = newPage
	
	pageFrames[tabName] = newPage
	return newPage
end

local function switchTab(targetTabName)
	for name, btn in pairs(tabsList) do
		if name == targetTabName then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 80, 220)}):Play()
			pageFrames[name].Visible = true
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
			pageFrames[name].Visible = false
		end
	end
end

local function createTab(text, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 105, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 12
	btn.LayoutOrder = layoutOrder
	btn.Parent = sidebar
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = btn
	
	tabsList[text] = btn
	getPage(text)
	
	btn.MouseButton1Click:Connect(function() switchTab(text) end)
end

local function createToggle(tabName, title, callback)
	local targetPage = getPage(tabName)
	savedStates.Toggles[title] = false
	
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	row.BorderSizePixel = 0
	row.Parent = targetPage
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.7, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = title
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = row
	
	local switch = Instance.new("Frame")
	switch.Size = UDim2.new(0, 38, 0, 20)
	switch.Position = UDim2.new(1, -48, 0.5, -10)
	switch.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	switch.Parent = row
	
	local swCorner = Instance.new("UICorner")
	swCorner.CornerRadius = UDim.new(1, 0)
	swCorner.Parent = switch
	
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 14, 0, 14)
	indicator.Position = UDim2.new(0, 3, 0.5, -7)
	indicator.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	indicator.Parent = switch
	
	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent = indicator

	clickBtn.MouseButton1Click:Connect(function()
		local newState = not savedStates.Toggles[title]
		savedStates.Toggles[title] = newState
		
		local targetColor = newState and Color3.fromRGB(50, 80, 220) or Color3.fromRGB(55, 55, 60)
		local targetPos = newState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		
		TweenService:Create(switch, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
		TweenService:Create(indicator, TweenInfo.new(0.15), {Position = targetPos}):Play()
		
		if callback then callback(newState) end
	end)
end

local function createActionButton(tabName, title, callback)
	local targetPage = getPage(tabName)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	btn.Text = title
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.Parent = targetPage
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		local oldColor = btn.BackgroundColor3
		btn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
		task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
		if callback then callback() end
	end)
end

local function createTextBox(tabName, title, placeholder, defaultVal, callback)
	local targetPage = getPage(tabName)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	row.BorderSizePixel = 0
	row.Parent = targetPage
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = title
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 60, 0, 24)
	box.Position = UDim2.new(1, -70, 0.5, -12)
	box.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	box.Text = tostring(defaultVal)
	box.PlaceholderText = placeholder
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 12
	box.Parent = row
	
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = box
	
	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then if callback then callback(num) end else box.Text = tostring(defaultVal) end
	end)
end

-- Dragging Logic
local dragToggle, dragInput, dragStart, startPos
titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragToggle = true; dragStart = input.Position; startPos = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
	end
end)
titleLabel.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragToggle then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ==========================================
-- 3. INITIALIZE OPERATIONS
-- ==========================================

createTab("Automation", 1)
createTab("Movement", 2)
createTab("Visuals/ESP", 3)

-- [AUTOMATION TAB]
createToggle("Automation", "Auto-Interact Machines", function(isOn)
	_G.AutoInteract = isOn
	task.spawn(function()
		while _G.AutoInteract do
			task.wait(0.1)
			for _, obj in ipairs(workspace:GetDescendants()) do
				if isExtractor(obj) then
					local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
					if prompt and prompt.Enabled and getMachineProgress(obj) < 100 then
						prompt:InputBegan(player)
					end
				end
			end
		end
	end)
end)

createToggle("Automation", "Instant QTE Skill Checks", function(isOn)
	_G.QTEAutomator = isOn
	
	if isOn then
		QteConnection = playerGui.DescendantAdded:Connect(function(desc)
			if desc:IsA("Frame") and (string.find(string.lower(desc.Name), "minigame") or string.find(string.lower(desc.Name), "skill")) then
				task.spawn(function()
					local targetZone = desc:FindFirstChild("Zone") or desc:FindFirstChild("Yellow") or desc:FindFirstChild("Bar")
					local cursorLine = desc:FindFirstChild("Line") or desc:FindFirstChild("Pointer") or desc:FindFirstChild("Cursor")
					
					while _G.QTEAutomator and desc.IsDescendantOf(playerGui) do
						task.wait()
						if targetZone and cursorLine then
							local curX = cursorLine.AbsolutePosition.X
							local minX = targetZone.AbsolutePosition.X
							local maxX = targetZone.AbsolutePosition.X + targetZone.AbsoluteSize.X
							
							if curX >= minX and curX <= maxX then
								VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
								task.wait(0.03)
								VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
								break
							end
						end
					end
				end)
			end
		end)
	else
		if QteConnection then QteConnection:Disconnect() QteConnection = nil end
	end
end)

createActionButton("Automation", "Teleport to Incomplete Machine", function()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end
	
	if humanoid.Health <= 0 then return end

	local closestMachine = nil
	local shortestDistance = math.huge
	
	local searchPool = {}
	local mapFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Rooms")
	
	if mapFolder then
		searchPool = mapFolder:GetDescendants()
	else
		searchPool = workspace:GetChildren()
	end
	
	for _, obj in ipairs(searchPool) do
		if isExtractor(obj) then
			local objNameLower = string.lower(obj.Name)
			if not string.find(objNameLower, "soda") and not string.find(objNameLower, "vending") and not string.find(objNameLower, "shop") then
				if getMachineProgress(obj) < 100 then
					local pivot = obj:GetPivot()
					local distance = (rootPart.Position - pivot.Position).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestMachine = obj
					end
				end
			end
		end
	end
	
	if closestMachine then
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		rootPart.CFrame = closestMachine:GetPivot() * CFrame.new(0, 5, 0)
	end
end)

-- [MOVEMENT TAB]
createTextBox("Movement", "Set Custom Speed Value", "35", 35, function(value) _G.CustomSpeedValue = value end)

createToggle("Movement", "Enable Loop Speed Boost", function(isOn)
	_G.LoopSpeedEnabled = isOn
	if isOn then
		task.spawn(function()
			while _G.LoopSpeedEnabled do
				task.wait() 
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.WalkSpeed ~= _G.CustomSpeedValue then
					humanoid.WalkSpeed = _G.CustomSpeedValue
				end
			end
		end)
	else
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 16 end
	end
end)

createTextBox("Movement", "Set Custom Flight Speed", "50", 50, function(value) _G.FlySpeed = value end)

-- FIXED: Reliable CFrame updates that completely bypass obsolete engine physics properties
createToggle("Movement", "Enable Fly Hack", function(isOn)
	_G.FlyEnabled = isOn
	
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if isOn then
		if not character or not humanoid then return end
		
		-- Anchor character to prevent the internal state machine from dragging them down
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then rootPart.Anchored = true end
		
		local camera = workspace.CurrentCamera
		
		FlyConnection = RunService.RenderStepped:Connect(function(deltaTime)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root or not _G.FlyEnabled then return end
			
			-- Double check anchor stays true
			root.Anchored = true
			
			local lookVector = camera.CFrame.LookVector
			local rightVector = camera.CFrame.RightVector
			local moveDirection = Vector3.new(0, 0, 0)
			
			-- Map keyboard inputs directly to 3D spaces matching camera direction
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				moveDirection = moveDirection + lookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				moveDirection = moveDirection - lookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				moveDirection = moveDirection - rightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				moveDirection = moveDirection + rightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				moveDirection = moveDirection + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				moveDirection = moveDirection - Vector3.new(0, 1, 0)
			end
			
			if moveDirection.Magnitude > 0 then
				moveDirection = moveDirection.Unit
				root.CFrame = root.CFrame + (moveDirection * _G.FlySpeed * deltaTime)
			end
		end)
	else
		if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
		task.wait(0.05)
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart then 
			rootPart.Anchored = false 
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end
end)

-- [VISUALS / ESP TAB]
createToggle("Visuals/ESP", "Player Wallhack", function(isOn)
	_G.ESPEnabled = isOn
	local function applyESP(plr)
		if plr == player then return end 
		local function addHighlight(char)
			task.wait(0.1) 
			if _G.ESPEnabled and char and not char:FindFirstChild("PlayerHighlight") then
				local hl = Instance.new("Highlight", char)
				hl.Name = "PlayerHighlight"
				hl.FillColor = Color3.fromRGB(0, 255, 100)
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.FillTransparency = 0.5
			end
		end
		if plr.Character then addHighlight(plr.Character) end
		plr.CharacterAdded:Connect(addHighlight)
	end

	if isOn then
		for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
		EspConnection = Players.PlayerAdded:Connect(applyESP)
	else
		if EspConnection then EspConnection:Disconnect() EspConnection = nil end
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("PlayerHighlight") then p.Character.PlayerHighlight:Destroy() end
		end
	end
end)

createToggle("Visuals/ESP", "Monster ESP", function(isOn)
	_G.MonsterESPEnabled = isOn
	
	local function checkMonster(object)
		if not _G.MonsterESPEnabled then return end
		if isTwistedMonster(object) then
			if not object:FindFirstChild("MonsterHighlight") then
				local hl = Instance.new("Highlight", object)
				hl.Name = "MonsterHighlight"
				hl.FillColor = Color3.fromRGB(255, 0, 50)
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.FillTransparency = 0.3
			end
		end
	end

	if isOn then
		MonsterConnection = workspace.DescendantAdded:Connect(checkMonster)
		for _, obj in ipairs(workspace:GetDescendants()) do checkMonster(obj) end
	else
		if MonsterConnection then MonsterConnection:Disconnect() MonsterConnection = nil end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:FindFirstChild("MonsterHighlight") then obj.MonsterHighlight:Destroy() end
		end
	end
end)

createToggle("Visuals/ESP", "Machine ESP", function(isOn)
	_G.MachineESPEnabled = isOn
	
	if isOn then
		MachineLoop = task.spawn(function()
			while _G.MachineESPEnabled do
				for _, obj in ipairs(workspace:GetDescendants()) do
					if isExtractor(obj) then
						local hl = obj:FindFirstChild("MachineHighlight") or Instance.new("Highlight", obj)
						hl.Name = "MachineHighlight"
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.4
						
						if getMachineProgress(obj) < 100 then
							hl.FillColor = Color3.fromRGB(255, 0, 0)
						else
							hl.FillColor = Color3.fromRGB(0, 255, 0)
						end
					end
				end
				task.wait(1)
			end
		end)
	else
		if MachineLoop then task.cancel(MachineLoop); MachineLoop = nil end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:FindFirstChild("MachineHighlight") then obj.MachineHighlight:Destroy() end
		end
	end
end)

switchTab("Automation")