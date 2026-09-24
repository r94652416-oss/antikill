--// ============================================================
--// LOADING SCREEN (modern, animated, purple/black/grey)
--// ============================================================
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")

--// Safe LocalPlayer wait (works in executors and normal clients)
local LP = Players.LocalPlayer
if not LP then
	repeat task.wait(0.1) until Players.LocalPlayer
	LP = Players.LocalPlayer
end

--// Safe PlayerGui wait
local PlayerGui = LP:WaitForChild("PlayerGui", 10)
if not PlayerGui then
	warn("[Counter] PlayerGui never loaded — aborting loading screen.")
	return
end

--// Build GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CounterLoadScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = PlayerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
root.BorderSizePixel = 0
root.Parent = screenGui

--// Animated squares background
local squaresFrame = Instance.new("Frame")
squaresFrame.Size = UDim2.fromScale(1, 1)
squaresFrame.BackgroundTransparency = 1
squaresFrame.Parent = root

local squareColors = {
	Color3.fromRGB(120, 60, 220),   -- purple
	Color3.fromRGB(80, 30, 160),    -- deep purple
	Color3.fromRGB(50, 50, 60),     -- grey
	Color3.fromRGB(150, 150, 160),  -- light grey
	Color3.fromRGB(180, 100, 255),  -- bright purple
}

local squares = {}
for i = 1, 28 do
	local s = Instance.new("Frame")
	s.Size = UDim2.fromOffset(math.random(18, 60), math.random(18, 60))
	s.Position = UDim2.fromScale(math.random(), math.random())
	s.BackgroundColor3 = squareColors[math.random(1, #squareColors)]
	s.BackgroundTransparency = math.random(55, 90) / 100
	s.BorderSizePixel = 0
	s.Rotation = math.random(0, 360)
	s.Parent = squaresFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, math.random(2, 8))
	corner.Parent = s

	squares[#squares + 1] = {
		obj = s,
		speed = math.random(20, 70) / 100,
		rotSpeed = math.random(-40, 40) / 100,
		drift = (math.random() - 0.5) * 0.02,
	}
end

--// Subtle vignette / contrast overlay
local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vignette.BackgroundTransparency = 0.55
vignette.BorderSizePixel = 0
vignette.ZIndex = 2
vignette.Parent = root

local vignetteGrad = Instance.new("UIGradient")
vignetteGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.2),
	NumberSequenceKeypoint.new(0.5, 0.85),
	NumberSequenceKeypoint.new(1, 0.2),
})
vignetteGrad.Rotation = 90
vignetteGrad.Parent = vignette

--// Center panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(560, 280)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.ZIndex = 5
panel.Parent = root

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(140, 80, 255)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.25
panelStroke.Parent = panel

local panelGrad = Instance.new("UIGradient")
panelGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 45)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 12, 16)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 28)),
})
panelGrad.Rotation = 45
panelGrad.Parent = panel

--// Title
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.08)
title.Size = UDim2.fromScale(0.9, 0.2)
title.BackgroundTransparency = 1
title.Text = "COUNTER"
title.Font = Enum.Font.GothamBlack
title.TextSize = 42
title.TextColor3 = Color3.fromRGB(235, 225, 255)
title.TextStrokeTransparency = 0.6
title.TextStrokeColor3 = Color3.fromRGB(120, 60, 220)
title.ZIndex = 6
title.Parent = panel

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 160, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 100, 255)),
})
titleGrad.Rotation = 90
titleGrad.Parent = title

--// Subtitle (loading status)
local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.fromScale(0.5, 0.3)
subtitle.Size = UDim2.fromScale(0.9, 0.07)
subtitle.BackgroundTransparency = 1
subtitle.Text = "loading counter systems..."
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(180, 180, 195)
subtitle.TextTransparency = 0.15
subtitle.ZIndex = 6
subtitle.Parent = panel

--// Discord link row
local discordRow = Instance.new("Frame")
discordRow.AnchorPoint = Vector2.new(0.5, 0)
discordRow.Position = UDim2.fromScale(0.5, 0.39)
discordRow.Size = UDim2.fromScale(0.9, 0.09)
discordRow.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
discordRow.BackgroundTransparency = 0.25
discordRow.BorderSizePixel = 0
discordRow.ZIndex = 6
discordRow.Parent = panel

local discordRowCorner = Instance.new("UICorner")
discordRowCorner.CornerRadius = UDim.new(1, 0)
discordRowCorner.Parent = discordRow

local discordRowStroke = Instance.new("UIStroke")
discordRowStroke.Color = Color3.fromRGB(140, 80, 255)
discordRowStroke.Thickness = 1
discordRowStroke.Transparency = 0.5
discordRowStroke.Parent = discordRow

local discordIcon = Instance.new("TextLabel")
discordIcon.AnchorPoint = Vector2.new(0, 0.5)
discordIcon.Position = UDim2.fromScale(0.035, 0.5)
discordIcon.Size = UDim2.fromOffset(22, 22)
discordIcon.BackgroundTransparency = 1
discordIcon.Text = "🔗"
discordIcon.Font = Enum.Font.GothamBold
discordIcon.TextSize = 18
discordIcon.TextColor3 = Color3.fromRGB(200, 160, 255)
discordIcon.ZIndex = 7
discordIcon.Parent = discordRow

local discordLink = Instance.new("TextLabel")
discordLink.AnchorPoint = Vector2.new(0, 0.5)
discordLink.Position = UDim2.fromScale(0.11, 0.5)
discordLink.Size = UDim2.fromScale(0.6, 1)
discordLink.BackgroundTransparency = 1
discordLink.Text = "discord.gg/uqVep54qW9"
discordLink.Font = Enum.Font.GothamMedium
discordLink.TextSize = 14
discordLink.TextColor3 = Color3.fromRGB(215, 200, 255)
discordLink.TextXAlignment = Enum.TextXAlignment.Left
discordLink.ZIndex = 7
discordLink.Parent = discordRow

local copiedLabel = Instance.new("TextLabel")
copiedLabel.AnchorPoint = Vector2.new(1, 0.5)
copiedLabel.Position = UDim2.fromScale(0.965, 0.5)
copiedLabel.Size = UDim2.fromScale(0.28, 1)
copiedLabel.BackgroundTransparency = 1
copiedLabel.Text = "copied!"
copiedLabel.Font = Enum.Font.GothamBold
copiedLabel.TextSize = 13
copiedLabel.TextColor3 = Color3.fromRGB(160, 255, 180)
copiedLabel.TextTransparency = 1
copiedLabel.TextXAlignment = Enum.TextXAlignment.Right
copiedLabel.ZIndex = 7
copiedLabel.Parent = discordRow

--// Progress bar
local barBg = Instance.new("Frame")
barBg.AnchorPoint = Vector2.new(0.5, 0)
barBg.Position = UDim2.fromScale(0.5, 0.56)
barBg.Size = UDim2.fromScale(0.82, 0.04)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
barBg.BorderSizePixel = 0
barBg.ZIndex = 6
barBg.Parent = panel

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 7
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local barFillGrad = Instance.new("UIGradient")
barFillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255)),
})
barFillGrad.Parent = barFill

--// Credits
local credits = Instance.new("TextLabel")
credits.AnchorPoint = Vector2.new(0.5, 0)
credits.Position = UDim2.fromScale(0.5, 0.68)
credits.Size = UDim2.fromScale(0.9, 0.26)
credits.BackgroundTransparency = 1
credits.Text = "owner / lead developer / modeler  •  @kp3g\nco-owner / advertiser  •  @sch1uma"
credits.Font = Enum.Font.GothamMedium
credits.TextSize = 13
credits.TextColor3 = Color3.fromRGB(170, 165, 185)
credits.TextTransparency = 0.2
credits.TextYAlignment = Enum.TextYAlignment.Top
credits.ZIndex = 6
credits.Parent = panel

--// ---- Auto copy Discord link to clipboard ----
local DISCORD_LINK = "https://discord.gg/uqVep54qW9"

local function copyDiscordLink()
	local ok = pcall(function()
		if setclipboard then
			setclipboard(DISCORD_LINK)
		elseif toclipboard then
			toclipboard(DISCORD_LINK)
		else
			error("no clipboard function available")
		end
	end)
	if ok then
		copiedLabel.Text = "copied!"
		copiedLabel.TextColor3 = Color3.fromRGB(160, 255, 180)
		copiedLabel.TextTransparency = 0
		TweenService:Create(copiedLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	else
		copiedLabel.Text = "copy failed"
		copiedLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		copiedLabel.TextTransparency = 0
		TweenService:Create(copiedLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	end
end

task.spawn(function()
	task.wait(0.35)
	copyDiscordLink()
end)

--// Loading screen control
local loadDone = false
local progress = 0

-- animate squares
local squaresConn
squaresConn = RunService.RenderStepped:Connect(function(dt)
	for _, s in ipairs(squares) do
		local o = s.obj
		local pos = o.Position
		local newY = pos.Y.Scale + s.speed * dt * 0.08
		if newY > 1.1 then newY = -0.1 end
		o.Position = UDim2.fromScale(pos.X.Scale + s.drift * dt, newY)
		o.Rotation = o.Rotation + s.rotSpeed * dt * 20
	end
end)

-- animate progress + subtitle dots
local dotTime = 0
local progressConn
progressConn = RunService.RenderStepped:Connect(function(dt)
	if loadDone then return end
	dotTime = dotTime + dt

	local dots = string.rep(".", math.floor(dotTime * 3) % 4)
	subtitle.Text = "loading counter systems" .. dots

	local target = math.min(1, progress + dt * 0.42)
	progress = target
	barFill.Size = UDim2.fromScale(progress, 1)

	panelStroke.Transparency = 0.25 + math.sin(dotTime * 3) * 0.15
end)

-- finish loading
task.spawn(function()
	task.wait(2.6)
	loadDone = true
	progressConn:Disconnect()

	TweenService:Create(barFill, TweenInfo.new(0.25), {Size = UDim2.fromScale(1, 1)}):Play()
	task.wait(0.3)

	local fadeTime = 0.6
	local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, s in ipairs(squares) do
		TweenService:Create(s.obj, fadeInfo, {BackgroundTransparency = 1}):Play()
	end
	TweenService:Create(vignette, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(panel, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(panelStroke, fadeInfo, {Transparency = 1}):Play()
	TweenService:Create(title, fadeInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(subtitle, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(credits, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(barBg, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(barFill, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(discordRow, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(discordRowStroke, fadeInfo, {Transparency = 1}):Play()
	TweenService:Create(discordIcon, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(discordLink, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(copiedLabel, fadeInfo, {TextTransparency = 1}):Play()

	task.wait(fadeTime + 0.1)
	squaresConn:Disconnect()
	screenGui:Destroy()
end)

--// ============================================================
--// MAIN COUNTER SCRIPT
--// ============================================================

--// Local Player (already have LP from above)
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local Camera    = workspace.CurrentCamera

--// Config
local TOGGLE_KEY        = Enum.KeyCode.F6
local ATTACK_RATE       = 0
local HP_STOP_PERCENT   = 0.05
local BEHIND_DIST       = 4.5
local FRONT_DIST        = 4.5
local TELEPORT_Y        = 0
local TELEPORT_COOLDOWN = 0
local MAX_ATTACK_TIME   = 8
local ATTACKER_MEMORY   = 3.0
local BULLET_WAIT       = 0.15
local CAMERA_HEIGHT     = 1.5
local TARGET_TOOL_NAME  = "[Double-Barrel SG]"

local DEBUG = true
local function log(...) if DEBUG then print("[Counter]", ...) end end

log("Script starting...")

--// State
local lastHealth = Humanoid.Health
local isCountering = false
local ENABLED = true
local lastAttacker = nil
local lastAttackerTime = 0
local lastBulletSeq = 0
local lastTeleportTime = 0
local camLockTarget = nil
local camLockConn = nil
local mouseLockConn = nil

--// Forward declarations
local startCameraLock
local stopCameraLock
local startMouseLock
local stopMouseLock

--// ---- Mouse lock ----
function startMouseLock()
	if mouseLockConn then return end
	mouseLockConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		pcall(function()
			local vp = Camera and Camera.ViewportSize
			if vp then
				UserInputService:SetMouseLocation(vp.X / 2, vp.Y / 2)
			end
		end)
	end)
	log("Mouse locked to center")
end

function stopMouseLock()
	if mouseLockConn then
		mouseLockConn:Disconnect()
		mouseLockConn = nil
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	log("Mouse lock released")
end

--// ---- Target hitbox ----
local function getTargetHitbox(player)
	local char = player and player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local attach = root:FindFirstChild("RootAttachment")
	if attach then
		local hb = attach:FindFirstChild("Hitbox")
		if hb then return hb end
	end
	return root
end

--// ---- Camera lock ----
function startCameraLock(player)
	camLockTarget = player
	if camLockConn then camLockConn:Disconnect() end
	camLockConn = RunService.RenderStepped:Connect(function()
		if not camLockTarget then return end
		local hb = getTargetHitbox(camLockTarget)
		local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hb or not myRoot then return end
		local eye = myRoot.Position + Vector3.new(0, CAMERA_HEIGHT, 0)
		Camera.CFrame = CFrame.new(eye, hb.Position)
	end)
	startMouseLock()
	log("Camera locked onto:", player.Name)
end

function stopCameraLock()
	camLockTarget = nil
	if camLockConn then
		camLockConn:Disconnect()
		camLockConn = nil
	end
	if LP.Character then
		local hum = LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			Camera.CameraSubject = hum
			Camera.CameraType = Enum.CameraType.Custom
		end
	end
	stopMouseLock()
	log("Camera lock released")
end

--// ---- MainGameEvent ----
local GameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
local MainGameEvent = GameRemotes and GameRemotes:FindFirstChild("MainGameEvent")
if not MainGameEvent then
	MainGameEvent = ReplicatedStorage:FindFirstChild("MainGameEvent")
end

--// ---- Find DB SG tool ----
local function findTargetTool()
	local char = LP.Character
	local backpack = LP:FindFirstChildOfClass("Backpack")
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name == TARGET_TOOL_NAME then return t, "equipped" end
		end
	end
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t.Name == TARGET_TOOL_NAME then return t, "backpack" end
		end
	end
	local function matches(name)
		local n = name:lower()
		return n:find("double%-barrel", 1) ~= nil or n:find("double barrel", 1) ~= nil
	end
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and matches(t.Name) then return t, "equipped (fuzzy)" end
		end
	end
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and matches(t.Name) then return t, "backpack (fuzzy)" end
		end
	end
	return nil, nil
end

local SLOT_ATTRS = {"ToolSlot","Slot","EquipSlot","Index","HotbarSlot","SlotIndex","ToolIndex","HotbarIndex"}
local function getToolSlotNumber(tool)
	if not tool then return nil end
	for _, name in ipairs(SLOT_ATTRS) do
		local v = tool:GetAttribute(name)
		if typeof(v) == "number" then return v end
	end
	return nil
end

local function equipTargetTool()
	local char = LP.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local tool, where = findTargetTool()
	if not tool then
		log("❌ Could not find tool:", TARGET_TOOL_NAME)
		return nil
	end
	if tool.Parent == char then
		log("✔ Already equipped:", tool.Name)
		return tool
	end
	hum:EquipTool(tool)
	local t = 0
	while tool.Parent ~= char and t < 0.4 do
		task.wait(0.02)
		t = t + 0.02
	end
	if tool.Parent == char then
		local slotNum = getToolSlotNumber(tool)
		log("✔ Equipped:", tool.Name, "| via:", where, "| slot:", slotNum and tostring(slotNum) or "?")
		return tool
	else
		log("⚠ EquipTool failed")
		return nil
	end
end

--// ---- "Am I this instance?" ----
local function isMine(inst)
	if typeof(inst) ~= "Instance" then return false end
	local c = LP.Character
	if c and (inst == c or inst:IsDescendantOf(c)) then return true end
	local wp = Workspace:FindFirstChild("Players")
	if wp then
		local alt = wp:FindFirstChild(LP.Name)
		if alt and (inst == alt or inst:IsDescendantOf(alt)) then return true end
	end
	return false
end

--// ---- Teleport ----
local function setupNetwork()
	local char = LP.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then pcall(function() root:SetNetworkOwner(LP) end) end
end

local function teleportAround(targetRoot, dir)
	local now = tick()
	if now - lastTeleportTime < TELEPORT_COOLDOWN then return end
	lastTeleportTime = now
	local char = LP.Character
	if not char then return end
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local look = targetRoot.CFrame.LookVector
	local dist = (dir == 1) and BEHIND_DIST or FRONT_DIST
	local offset = look * (dist * dir * -1)
	local goal = targetRoot.Position + offset + Vector3.new(0, TELEPORT_Y, 0)
	local targetCF = CFrame.new(goal, targetRoot.Position)
	myRoot.CFrame = targetCF
	myRoot.AssemblyLinearVelocity = Vector3.zero
	myRoot.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(targetCF)
end

local function getEquippedTool()
	local char = LP.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Tool")
end

--// ---- Damage trace ----
local function handleBulletPayload(...)
	local args = {...}
	if args[1] ~= "ClientBullet" then return end
	local shooter = args[2]
	if typeof(shooter) ~= "Instance" then return end

	local hitMe = false
	for i = 3, #args do
		local a = args[i]
		if typeof(a) == "Instance" and isMine(a) then hitMe = true break end
	end
	if not hitMe then return end

	local shooterPlayer = Players:GetPlayerFromCharacter(shooter)
	if not shooterPlayer and shooter:IsA("Player") then shooterPlayer = shooter end
	if not shooterPlayer or shooterPlayer == LP then return end

	lastAttacker = shooterPlayer
	lastAttackerTime = tick()
	lastBulletSeq = lastBulletSeq + 1
	log("Bullet hit me from:", shooterPlayer.Name, "(seq " .. lastBulletSeq .. ")")

	if ENABLED and not isCountering then
		task.spawn(function()
			local shooterChar = shooterPlayer.Character
			local shooterRoot = shooterChar and shooterChar:FindFirstChild("HumanoidRootPart")
			if not shooterRoot then return end
			local char = LP.Character
			local myRoot = char and char:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end

			local look = shooterRoot.CFrame.LookVector
			local goal = shooterRoot.Position - look * BEHIND_DIST + Vector3.new(0, TELEPORT_Y, 0)
			local targetCF = CFrame.new(goal, shooterRoot.Position)

			myRoot.CFrame = targetCF
			myRoot.AssemblyLinearVelocity = Vector3.zero
			myRoot.AssemblyAngularVelocity = Vector3.zero
			char:PivotTo(targetCF)
			lastTeleportTime = tick()
			log("⚡ Instant teleport to", shooterPlayer.Name)

			if not camLockTarget then
				startCameraLock(shooterPlayer)
			end
		end)
	end
end

if MainGameEvent then
	MainGameEvent.OnClientEvent:Connect(handleBulletPayload)
	log("Hooked MainGameEvent.OnClientEvent")
else
	log("⚠ MainGameEvent not found")
end

--// ---- Attacker resolution ----
local function resolveAttacker()
	if lastAttacker and (tick() - lastAttackerTime) <= ATTACKER_MEMORY then
		local c = lastAttacker.Character
		if lastAttacker.Parent and c and c:FindFirstChild("Humanoid")
			and c.Humanoid.Health > 0 then
			return lastAttacker
		end
	end
	local seqBefore = lastBulletSeq
	local deadline = tick() + BULLET_WAIT
	while tick() < deadline do
		if lastBulletSeq ~= seqBefore then
			if lastAttacker and (tick() - lastAttackerTime) <= ATTACKER_MEMORY then
				local c = lastAttacker.Character
				if lastAttacker.Parent and c and c:FindFirstChild("Humanoid")
					and c.Humanoid.Health > 0 then
					return lastAttacker
				end
			end
		end
		task.wait(0.01)
	end
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local name = hum:GetAttribute("LastAttacker")
			or hum:GetAttribute("Damager")
			or hum:GetAttribute("Attacker")
		if name then
			local p = Players:FindFirstChild(name)
			if p then return p end
		end
	end
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	local closest, best = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			local r = p.Character:FindFirstChild("HumanoidRootPart")
			local h = p.Character:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = (r.Position - myRoot.Position).Magnitude
				if d < best then best, closest = d, p end
			end
		end
	end
	return closest
end

--// ---- Counter attack ----
local function counterAttack(attacker)
	if isCountering then return end
	if not attacker or not attacker.Character then return end
	isCountering = true

	task.spawn(function()
		local myChar = LP.Character
		if not myChar then isCountering = false return end
		local myHum = myChar:FindFirstChildOfClass("Humanoid")
		if not myHum then isCountering = false return end

		setupNetwork()
		startCameraLock(attacker)

		local tChar = attacker.Character
		local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
		local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if not (tHum and tRoot) then
			isCountering = false
			stopCameraLock()
			return
		end

		log("Attacking:", attacker.Name)

		local tool = equipTargetTool()
		if not tool then
			isCountering = false
			stopCameraLock()
			return
		end

		local side = 1
		local start = tick()
		while tick() - start < MAX_ATTACK_TIME do
			if not ENABLED then break end
			tChar = attacker.Character
			tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
			tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if not (tHum and tRoot) then break end
			if tHum.Health <= 0 then break end
			local pct = tHum.Health / tHum.MaxHealth
			if pct <= HP_STOP_PERCENT then break end

			teleportAround(tRoot, side)
			side = -side

			if tool.Parent ~= LP.Character then
				if tool.Parent == nil then
					tool = equipTargetTool()
					if not tool then break end
				else
					myHum:EquipTool(tool)
					task.wait(0.02)
				end
			end

			tool:Activate()
			task.wait(ATTACK_RATE)
		end

		log("Counter attack finished")
		isCountering = false
		stopCameraLock()
	end)
end

--// ---- Health watcher ----
local function onHealthChanged()
	local cur = Humanoid.Health
	if cur < lastHealth then
		if ENABLED then
			log("Took damage. HP:", lastHealth, "->", cur)
			task.spawn(function()
				local attacker = resolveAttacker()
				log("Attacker:", attacker and attacker.Name or "NONE")
				if attacker then counterAttack(attacker) end
			end)
		end
	end
	lastHealth = cur
end

Humanoid.HealthChanged:Connect(onHealthChanged)

LP.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	lastHealth = Humanoid.Health
	Humanoid.HealthChanged:Connect(onHealthChanged)
end)

--// ---- F6 toggle ----
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TOGGLE_KEY then
		ENABLED = not ENABLED
		log(ENABLED and "✅ ENABLED" or "⛔ DISABLED")
		if not ENABLED then stopCameraLock() end
	end
end)

log("Loaded — auto-equips " .. TARGET_TOOL_NAME .. ". F6 to toggle.")
