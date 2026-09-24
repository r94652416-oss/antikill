--// Services
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

--// Local Player
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local Camera    = workspace.CurrentCamera

--// Config
local TOGGLE_KEY        = Enum.KeyCode.F6
local ATTACK_RATE       = 0.05          -- spam rate (20 clicks/sec)
local HP_STOP_PERCENT   = 0.05
local BEHIND_DIST       = 3.5
local FRONT_DIST        = 3.5
local TELEPORT_Y        = 0
local TELEPORT_COOLDOWN = 0
local MAX_ATTACK_TIME   = 8
local ATTACKER_MEMORY   = 3.0
local BULLET_WAIT       = 0.15
local CAMERA_HEIGHT     = 1.5

local DEBUG = true
local function log(...) if DEBUG then print("[Counter]", ...) end end

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

--// ---- MainGameEvent ----
local GameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
local MainGameEvent = GameRemotes and GameRemotes:FindFirstChild("MainGameEvent")
if not MainGameEvent then
	MainGameEvent = ReplicatedStorage:FindFirstChild("MainGameEvent")
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

--// ---- Damage trace ----
local function handleBulletPayload(...)
	local args = {...}
	if args[1] ~= "ClientBullet" then return end
	local shooter = args[2]
	if typeof(shooter) ~= "Instance" then return end

	local hitMe = false
	for i = 3, #args do
		local a = args[i]
		if typeof(a) == "Instance" and isMine(a) then
			hitMe = true
			break
		end
	end
	if not hitMe then return end

	local shooterPlayer = Players:GetPlayerFromCharacter(shooter)
	if not shooterPlayer and shooter:IsA("Player") then shooterPlayer = shooter end
	if not shooterPlayer or shooterPlayer == LP then return end

	lastAttacker = shooterPlayer
	lastAttackerTime = tick()
	lastBulletSeq = lastBulletSeq + 1
	log("Bullet hit me from:", shooterPlayer.Name, "(seq " .. lastBulletSeq .. ")")
end

if MainGameEvent then
	MainGameEvent.OnClientEvent:Connect(handleBulletPayload)
	log("Hooked MainGameEvent.OnClientEvent")
end

--// ---- Target hitbox lookup ----
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
local function startCameraLock(player)
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
	log("Camera locked onto:", player.Name)
end

local function stopCameraLock()
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
	log("Camera lock released")
end

--// ---- Number keys ----
local KEY_MAP = {
	[1]=Enum.KeyCode.One,[2]=Enum.KeyCode.Two,[3]=Enum.KeyCode.Three,
	[4]=Enum.KeyCode.Four,[5]=Enum.KeyCode.Five,[6]=Enum.KeyCode.Six,
	[7]=Enum.KeyCode.Seven,[8]=Enum.KeyCode.Eight,[9]=Enum.KeyCode.Nine,
}
local function pressNumberKey(n)
	local key = KEY_MAP[n] or Enum.KeyCode.One
	VirtualInputManager:SendKeyEvent(true,  key, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
	log("Pressed key: " .. n)
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

--// ---- Counter attack (slot 1 spam) ----
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

		-- Equip slot 1
		pressNumberKey(1)
		task.wait(0.15)

		-- Spam slot 1 until target <= 5% HP (or dead / timeout)
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

			local tool = getEquippedTool()
			if tool then tool:Activate() end

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

log("Loaded — slot 1 spam + camera lock. F6 to toggle.")
