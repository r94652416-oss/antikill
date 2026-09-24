--// Services
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local UserInputService   = game:GetService("UserInputService")

--// Local Player
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")

--// Config
local TOGGLE_KEY        = Enum.KeyCode.F6
local SLOT1_CLICK_DELAY = 1.0
local SLOT3_ATTACK_RATE = 0.05
local HP_STOP_PERCENT   = 0.05
local BEHIND_DIST       = 3.5
local FRONT_DIST        = 3.5
local TELEPORT_Y        = 0
local TELEPORT_COOLDOWN = 0.5
local MAX_ATTACK_TIME   = 8
local ATTACKER_MEMORY   = 3.0
local BULLET_WAIT       = 0.15   -- wait this long for a bullet event before falling back

local DEBUG = true
local function log(...) if DEBUG then print("[Counter]", ...) end end

--// State
local lastHealth = Humanoid.Health
local isCountering = false
local ENABLED = true
local lastAttacker = nil
local lastAttackerTime = 0
local lastBulletSeq = 0        -- increments each time a bullet hits us
local lastTeleportTime = 0

--// ---- MainGameEvent ----
local GameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
local MainGameEvent = GameRemotes and GameRemotes:FindFirstChild("MainGameEvent")
if not MainGameEvent then
	MainGameEvent = ReplicatedStorage:FindFirstChild("MainGameEvent")
end

--// ---- "Am I this instance?" check ----
local function isMine(inst)
	if typeof(inst) ~= "Instance" then return false end
	-- Fast path: inside LP.Character
	local c = LP.Character
	if c and (inst == c or inst:IsDescendantOf(c)) then return true end
	-- Alternate container: Workspace.Players.<name>
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

	-- Does any instance arg belong to me?
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
else
	log("WARNING: MainGameEvent not found")
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

--// ---- Attacker resolution (with bullet-event wait) ----
local function resolveAttacker()
	-- 1) Fresh bullet trace
	if lastAttacker and (tick() - lastAttackerTime) <= ATTACKER_MEMORY then
		local c = lastAttacker.Character
		if lastAttacker.Parent and c and c:FindFirstChild("Humanoid")
			and c.Humanoid.Health > 0 then
			return lastAttacker
		end
	end

	-- 2) Wait a short beat in case the bullet event is still in flight
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

	-- 3) Humanoid attributes
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

	-- 4) Nearest (last resort)
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

		local tChar = attacker.Character
		local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
		local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if not (tHum and tRoot) then isCountering = false return end

		log("Attacking:", attacker.Name)

		pressNumberKey(1)
		task.wait(0.15)

		for i = 1, 2 do
			if not ENABLED then isCountering = false return end
			tChar = attacker.Character
			tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
			tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if not (tHum and tRoot) or tHum.Health <= 0 then
				isCountering = false
				return
			end
			teleportAround(tRoot, (i % 2 == 1) and 1 or -1)
			task.wait(0.03)
			local tool = getEquippedTool()
			if tool then tool:Activate() end
			log("Slot 1 click #" .. i)
			if i < 2 then task.wait(SLOT1_CLICK_DELAY) end
		end

		pressNumberKey(3)
		task.wait(0.15)
		log("Switched to slot 3 — spamming")

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
			task.wait(SLOT3_ATTACK_RATE)
		end

		log("Counter attack finished")
		isCountering = false
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
	end
end)

log("Loaded — bullet trace via Workspace.Players.<name>. F6 to toggle.")