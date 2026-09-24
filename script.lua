--// ============================================================
--// COUNTER — loading screen + draggable status indicator + auto counter
--// Credits: @kp3g (owner/lead dev/modeler), @sch1uma (co-owner/advertiser)
--// ============================================================

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")

--// Wait for LocalPlayer properly
local LP
do
	local t = 0
	repeat
		LP = Players.LocalPlayer
		task.wait(0.05)
		t = t + 0.05
	until LP or t > 15
end
if not LP then
	warn("[Counter] No LocalPlayer — are you running this on the client?")
	return
end

local PlayerGui = LP:FindFirstChildOfClass("PlayerGui")
if not PlayerGui then
	local t = 0
	repeat
		PlayerGui = LP:FindFirstChildOfClass("PlayerGui")
		task.wait(0.05)
		t = t + 0.05
	until PlayerGui or t > 15
end
if not PlayerGui then
	warn("[Counter] No PlayerGui found")
	return
end

print("[Counter] PlayerGui ready, building UI...")

--// ============================================================
--// LOADING SCREEN
--// ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CounterLoadScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = PlayerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
root.BorderSizePixel = 0
root.Parent = screenGui

local squaresFrame = Instance.new("Frame")
squaresFrame.Size = UDim2.fromScale(1, 1)
squaresFrame.BackgroundTransparency = 1
squaresFrame.Parent = root

local squareColors = {
	Color3.fromRGB(120, 60, 220),
	Color3.fromRGB(80, 30, 160),
	Color3.fromRGB(50, 50, 60),
	Color3.fromRGB(150, 150, 160),
	Color3.fromRGB(180, 100, 255),
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
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, math.random(2, 8))
	c.Parent = s
	table.insert(squares, {
		obj = s,
		speed = math.random(20, 70) / 100,
		rotSpeed = math.random(-40, 40) / 100,
		drift = (math.random() - 0.5) * 0.02,
	})
end

local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vignette.BackgroundTransparency = 0.55
vignette.BorderSizePixel = 0
vignette.ZIndex = 2
vignette.Parent = root

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(560, 280)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.ZIndex = 5
panel.Parent = root

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 14)
pc.Parent = panel

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

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.fromScale(0.5, 0.3)
subtitle.Size = UDim2.fromScale(0.9, 0.07)
subtitle.BackgroundTransparency = 1
subtitle.Text = "loading counter systems..."
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(180, 180, 195)
subtitle.ZIndex = 6
subtitle.Parent = panel

local discordRow = Instance.new("Frame")
discordRow.AnchorPoint = Vector2.new(0.5, 0)
discordRow.Position = UDim2.fromScale(0.5, 0.39)
discordRow.Size = UDim2.fromScale(0.9, 0.09)
discordRow.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
discordRow.BackgroundTransparency = 0.25
discordRow.BorderSizePixel = 0
discordRow.ZIndex = 6
discordRow.Parent = panel

local drc = Instance.new("UICorner")
drc.CornerRadius = UDim.new(1, 0)
drc.Parent = discordRow

local drs = Instance.new("UIStroke")
drs.Color = Color3.fromRGB(140, 80, 255)
drs.Thickness = 1
drs.Transparency = 0.5
drs.Parent = discordRow

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

local barBg = Instance.new("Frame")
barBg.AnchorPoint = Vector2.new(0.5, 0)
barBg.Position = UDim2.fromScale(0.5, 0.56)
barBg.Size = UDim2.fromScale(0.82, 0.04)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
barBg.BorderSizePixel = 0
barBg.ZIndex = 6
barBg.Parent = panel

local bbc = Instance.new("UICorner")
bbc.CornerRadius = UDim.new(1, 0)
bbc.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 7
barFill.Parent = barBg

local bfc = Instance.new("UICorner")
bfc.CornerRadius = UDim.new(1, 0)
bfc.Parent = barFill

local credits = Instance.new("TextLabel")
credits.AnchorPoint = Vector2.new(0.5, 0)
credits.Position = UDim2.fromScale(0.5, 0.68)
credits.Size = UDim2.fromScale(0.9, 0.26)
credits.BackgroundTransparency = 1
credits.Text = "owner / lead developer / modeler  •  @kp3g\nco-owner / advertiser  •  @sch1uma"
credits.Font = Enum.Font.GothamMedium
credits.TextSize = 13
credits.TextColor3 = Color3.fromRGB(170, 165, 185)
credits.TextYAlignment = Enum.TextYAlignment.Top
credits.ZIndex = 6
credits.Parent = panel

task.spawn(function()
	task.wait(0.4)
	local ok = pcall(function()
		if setclipboard then setclipboard("https://discord.gg/uqVep54qW9")
		elseif toclipboard then toclipboard("https://discord.gg/uqVep54qW9") end
	end)
	if ok then
		copiedLabel.TextTransparency = 0
		TweenService:Create(copiedLabel, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	end
end)

local dotTime = 0
local progress = 0
local done = false

local animConn = RunService.RenderStepped:Connect(function(dt)
	if done then return end
	dotTime = dotTime + dt
	progress = math.min(1, progress + dt * 0.42)
	barFill.Size = UDim2.fromScale(progress, 1)
	subtitle.Text = "loading counter systems" .. string.rep(".", math.floor(dotTime * 3) % 4)
	panelStroke.Transparency = 0.25 + math.sin(dotTime * 3) * 0.15
	for _, s in ipairs(squares) do
		local o = s.obj
		local p = o.Position
		local ny = p.Y.Scale + s.speed * dt * 0.08
		if ny > 1.1 then ny = -0.1 end
		o.Position = UDim2.fromScale(p.X.Scale + s.drift * dt, ny)
		o.Rotation = o.Rotation + s.rotSpeed * dt * 20
	end
end)

task.spawn(function()
	task.wait(3)
	done = true
	animConn:Disconnect()
	local fi = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(root, fi, {BackgroundTransparency = 1}):Play()
	TweenService:Create(panel, fi, {BackgroundTransparency = 1}):Play()
	TweenService:Create(panelStroke, fi, {Transparency = 1}):Play()
	TweenService:Create(title, fi, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(subtitle, fi, {TextTransparency = 1}):Play()
	TweenService:Create(credits, fi, {TextTransparency = 1}):Play()
	TweenService:Create(barBg, fi, {BackgroundTransparency = 1}):Play()
	TweenService:Create(barFill, fi, {BackgroundTransparency = 1}):Play()
	TweenService:Create(discordRow, fi, {BackgroundTransparency = 1}):Play()
	TweenService:Create(drs, fi, {Transparency = 1}):Play()
	TweenService:Create(discordIcon, fi, {TextTransparency = 1}):Play()
	TweenService:Create(discordLink, fi, {TextTransparency = 1}):Play()
	TweenService:Create(copiedLabel, fi, {TextTransparency = 1}):Play()
	for _, s in ipairs(squares) do
		TweenService:Create(s.obj, fi, {BackgroundTransparency = 1}):Play()
	end
	TweenService:Create(vignette, fi, {BackgroundTransparency = 1}):Play()
	task.wait(0.7)
	screenGui:Destroy()
end)

--// ============================================================
--// STATUS INDICATOR (draggable + pulsing)
--// ============================================================
local indicatorGui = Instance.new("ScreenGui")
indicatorGui.Name = "CounterStatusIndicator"
indicatorGui.IgnoreGuiInset = true
indicatorGui.ResetOnSpawn = false
indicatorGui.DisplayOrder = 500
indicatorGui.Parent = PlayerGui

-- Outer wrapper handles dragging
local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.AnchorPoint = Vector2.new(0.5, 1)
indicator.Position = UDim2.new(0.5, 0, 1, -24)
indicator.Size = UDim2.fromOffset(210, 44)
indicator.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
indicator.BackgroundTransparency = 0.05
indicator.BorderSizePixel = 0
indicator.Active = true
indicator.Draggable = false -- we implement our own so AnchorPoint works
indicator.Parent = indicatorGui

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(1, 0)
ic.Parent = indicator

local iStroke = Instance.new("UIStroke")
iStroke.Color = Color3.fromRGB(150, 90, 255)
iStroke.Thickness = 1.6
iStroke.Transparency = 0.15
iStroke.Parent = indicator

local iGrad = Instance.new("UIGradient")
iGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 22, 55)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 14)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 32)),
})
iGrad.Rotation = 45
iGrad.Parent = indicator

-- inner glow that pulses when ON
local innerGlow = Instance.new("Frame")
innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
innerGlow.Position = UDim2.fromScale(0.5, 0.5)
innerGlow.Size = UDim2.fromScale(1, 1)
innerGlow.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
innerGlow.BackgroundTransparency = 0.85
innerGlow.BorderSizePixel = 0
innerGlow.ZIndex = 0
innerGlow.Parent = indicator

local igc = Instance.new("UICorner")
igc.CornerRadius = UDim.new(1, 0)
igc.Parent = innerGlow

local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0, 0.5)
dot.Position = UDim2.new(0, 16, 0.5, 0)
dot.Size = UDim2.fromOffset(10, 10)
dot.BackgroundColor3 = Color3.fromRGB(160, 255, 180)
dot.BorderSizePixel = 0
dot.ZIndex = 2
dot.Parent = indicator

local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(1, 0)
dc.Parent = dot

local dotGlow = Instance.new("Frame")
dotGlow.AnchorPoint = Vector2.new(0.5, 0.5)
dotGlow.Position = UDim2.fromScale(0.5, 0.5)
dotGlow.Size = UDim2.fromOffset(10, 10)
dotGlow.BackgroundColor3 = Color3.fromRGB(160, 255, 180)
dotGlow.BackgroundTransparency = 0.4
dotGlow.BorderSizePixel = 0
dotGlow.ZIndex = 1
dotGlow.Parent = dot

local dgc = Instance.new("UICorner")
dgc.CornerRadius = UDim.new(1, 0)
dgc.Parent = dotGlow

local statusLabel = Instance.new("TextLabel")
statusLabel.AnchorPoint = Vector2.new(0, 0.5)
statusLabel.Position = UDim2.new(0, 36, 0.5, 0)
statusLabel.Size = UDim2.new(1, -80, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "COUNTER  •  ON"
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(245, 240, 255)
statusLabel.TextStrokeTransparency = 0.75
statusLabel.TextStrokeColor3 = Color3.fromRGB(60, 20, 110)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 2
statusLabel.Parent = indicator

local statusGrad = Instance.new("UIGradient")
statusGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 190, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
statusGrad.Rotation = 90
statusGrad.Parent = statusLabel

local keyHint = Instance.new("TextLabel")
keyHint.AnchorPoint = Vector2.new(1, 0.5)
keyHint.Position = UDim2.new(1, -14, 0.5, 0)
keyHint.Size = UDim2.fromOffset(30, 20)
keyHint.BackgroundColor3 = Color3.fromRGB(35, 26, 55)
keyHint.BackgroundTransparency = 0.15
keyHint.BorderSizePixel = 0
keyHint.Text = "F6"
keyHint.Font = Enum.Font.GothamBold
keyHint.TextSize = 11
keyHint.TextColor3 = Color3.fromRGB(220, 190, 255)
keyHint.ZIndex = 2
keyHint.Parent = indicator

local khc = Instance.new("UICorner")
khc.CornerRadius = UDim.new(0, 5)
khc.Parent = keyHint

local khs = Instance.new("UIStroke")
khs.Color = Color3.fromRGB(150, 90, 255)
khs.Thickness = 1
khs.Transparency = 0.35
khs.Parent = keyHint

-- ============================================================
--// DRAGGING
-- ============================================================
do
	local dragging = false
	local dragStart
	local startPos

	local function beginDrag(input)
		dragging = true
		dragStart = input.Position
		startPos = indicator.Position
		-- switch anchor to top-left while dragging for smooth math
		indicator.AnchorPoint = Vector2.new(0, 0)
		local absPos = indicator.AbsolutePosition
		indicator.Position = UDim2.fromOffset(absPos.X, absPos.Y)
	end

	local function updateDrag(input)
		if not dragging then return end
		local delta = input.Position - dragStart
		indicator.Position = UDim2.fromOffset(
			startPos.X.Offset + delta.X,
			startPos.Y.Offset + delta.Y
		)
	end

	local function endDrag()
		dragging = false
	end

	indicator.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	indicator.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)
end

-- ============================================================
--// PULSE ANIMATION
-- ============================================================
local pulseT = 0
RunService.RenderStepped:Connect(function(dt)
	pulseT = pulseT + dt
	if _G.COUNTER_ENABLED then
		-- pulsing dot glow
		local pulse = (math.sin(pulseT * 4) + 1) / 2
		dotGlow.BackgroundTransparency = 0.15 + pulse * 0.55
		local size = 10 + pulse * 10
		dotGlow.Size = UDim2.fromOffset(size, size)
		-- pulsing inner glow (background contrast)
		innerGlow.BackgroundTransparency = 0.75 - pulse * 0.35
		-- pulsing stroke
		iStroke.Transparency = 0.05 + pulse * 0.25
		-- slight scale pulse on whole pill (subtle)
		local scale = 1 + pulse * 0.02
		indicator.Size = UDim2.fromOffset(210 * scale, 44 * scale)
	else
		dotGlow.BackgroundTransparency = 1
		innerGlow.BackgroundTransparency = 1
		iStroke.Transparency = 0.65
		indicator.Size = UDim2.fromOffset(210, 44)
	end
end)

local function setIndicator(enabled)
	_G.COUNTER_ENABLED = enabled
	if enabled then
		dot.BackgroundColor3 = Color3.fromRGB(160, 255, 180)
		dotGlow.BackgroundColor3 = Color3.fromRGB(160, 255, 180)
		statusLabel.Text = "COUNTER  •  ON"
		statusLabel.TextColor3 = Color3.fromRGB(245, 240, 255)
		statusGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 190, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		iStroke.Color = Color3.fromRGB(150, 90, 255)
		keyHint.BackgroundColor3 = Color3.fromRGB(35, 26, 55)
		keyHint.TextColor3 = Color3.fromRGB(220, 190, 255)
		khs.Color = Color3.fromRGB(150, 90, 255)
	else
		dot.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
		dotGlow.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
		statusLabel.Text = "COUNTER  •  OFF"
		statusLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
		statusGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 130)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 200)),
		})
		iStroke.Color = Color3.fromRGB(70, 70, 80)
		keyHint.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
		keyHint.TextColor3 = Color3.fromRGB(140, 140, 150)
		khs.Color = Color3.fromRGB(80, 80, 90)
	end
end

-- ============================================================
--// MAIN COUNTER
--// ============================================================
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local Camera    = workspace.CurrentCamera

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

setIndicator(ENABLED)

local startCameraLock, stopCameraLock, startMouseLock, stopMouseLock

function startMouseLock()
	if mouseLockConn then return end
	mouseLockConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end)
end

function stopMouseLock()
	if mouseLockConn then mouseLockConn:Disconnect() mouseLockConn = nil end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

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
end

function stopCameraLock()
	camLockTarget = nil
	if camLockConn then camLockConn:Disconnect() camLockConn = nil end
	if LP.Character then
		local hum = LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			Camera.CameraSubject = hum
			Camera.CameraType = Enum.CameraType.Custom
		end
	end
	stopMouseLock()
end

local GameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
local MainGameEvent = GameRemotes and GameRemotes:FindFirstChild("MainGameEvent")
if not MainGameEvent then
	MainGameEvent = ReplicatedStorage:FindFirstChild("MainGameEvent")
end

local function findTargetTool()
	local char = LP.Character
	local backpack = LP:FindFirstChildOfClass("Backpack")
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name == TARGET_TOOL_NAME then return t end
		end
	end
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t.Name == TARGET_TOOL_NAME then return t end
		end
	end
	return nil
end

local function equipTargetTool()
	local char = LP.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local tool = findTargetTool()
	if not tool then return nil end
	if tool.Parent == char then return tool end
	hum:EquipTool(tool)
	task.wait(0.1)
	if tool.Parent == char then return tool end
	return nil
end

local function isMine(inst)
	if typeof(inst) ~= "Instance" then return false end
	local c = LP.Character
	if c and (inst == c or inst:IsDescendantOf(c)) then return true end
	return false
end

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
			if not camLockTarget then startCameraLock(shooterPlayer) end
		end)
	end
end

if MainGameEvent then
	MainGameEvent.OnClientEvent:Connect(handleBulletPayload)
end

local function resolveAttacker()
	if lastAttacker and (tick() - lastAttackerTime) <= ATTACKER_MEMORY then
		local c = lastAttacker.Character
		if lastAttacker.Parent and c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
			return lastAttacker
		end
	end
	local char = LP.Character
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
			if (tHum.Health / tHum.MaxHealth) <= HP_STOP_PERCENT then break end
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
		isCountering = false
		stopCameraLock()
	end)
end

local function onHealthChanged()
	local cur = Humanoid.Health
	if cur < lastHealth then
		if ENABLED then
			task.spawn(function()
				local attacker = resolveAttacker()
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TOGGLE_KEY then
		ENABLED = not ENABLED
		setIndicator(ENABLED)
		if not ENABLED then stopCameraLock() end
		print("[Counter] " .. (ENABLED and "ENABLED" or "DISABLED"))
	end
end)

print("[Counter] Loaded successfully.")
