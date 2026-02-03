-- ===================== MISC SECTION =====================
-- Custom Crosshair, Triggerbot, Hit markers, Kill counter, Coordinates, Time, Panic, Auto respawn, Third person, FPS. No sounds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not _G.MiscTab then
    return
end

local library = _G.library or _G.CROW
if not library then return end

local MiscMain = _G.MiscTab:AddSection("Misc", 1)
local MiscCombat = _G.MiscTab:AddSection("Combat", 2)
local MiscVisual = _G.MiscTab:AddSection("Visual", 2)
local MiscInfo = _G.MiscTab:AddSection("Info", 2)
local MiscUtility = _G.MiscTab:AddSection("Utility", 2)

local miscConnections = {}

local function trackMisc(conn)
    table.insert(miscConnections, conn)
    return conn
end

-- ===================== TRIGGERBOT (fixed: RenderStepped, hold click, optional aim-only) =====================
MiscCombat:AddSeparator({ text = "Triggerbot" })

local triggerbotEnabled = false
local triggerbotCooldown = 0.12
local triggerbotHoldTime = 0.03
local lastTriggerTime = 0
local triggerbotTeamCheck = false
local triggerbotRequireAim = false

local function isEnemy(player)
    if not player or player == LocalPlayer then return false end
    if not player:IsA("Player") then return false end
    if triggerbotTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team and player.Team.Neutral == false then
        return false
    end
    return true
end

local triggerbotConnection = nil
local function triggerbotStep()
    if not triggerbotEnabled or not Camera then return end
    if triggerbotRequireAim and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local now = tick()
    if now - lastTriggerTime < triggerbotCooldown then return end
    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
    local hit = workspace:Raycast(origin, direction * 2000, params)
    if not hit or not hit.Instance then return end
    local model = hit.Instance:FindFirstAncestorOfClass("Model")
    if not model then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local player = Players:GetPlayerFromCharacter(model)
    if not player or not isEnemy(player) then return end
    lastHitPlayer = player
    lastTriggerTime = now
    if hitMarkerEnabled then showHitMarker() end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim and vim.SendMouseButtonEvent then
            local viewport = Camera.ViewportSize
            local x, y = viewport.X / 2, viewport.Y / 2
            vim:SendMouseButtonEvent(x, y, 0, true)
            task.wait(triggerbotHoldTime)
            vim:SendMouseButtonEvent(x, y, 0, false)
        end
    end)
end

MiscCombat:AddToggle({
    text = "Triggerbot",
    state = false,
    flag = "TriggerbotEnabled",
    tooltip = "Auto-fire when crosshair on enemy (hold click for game compatibility)",
    callback = function(state)
        triggerbotEnabled = state
        if triggerbotConnection then
            triggerbotConnection:Disconnect()
            triggerbotConnection = nil
        end
        if state then
            triggerbotConnection = RunService.RenderStepped:Connect(triggerbotStep)
        end
    end
})

MiscCombat:AddToggle({
    text = "Triggerbot Team Check",
    state = false,
    flag = "TriggerbotTeamCheck",
    tooltip = "Don't fire at teammates",
    callback = function(state)
        triggerbotTeamCheck = state
    end
})

MiscCombat:AddToggle({
    text = "Require Aim (Right Mouse)",
    state = false,
    flag = "TriggerbotRequireAim",
    tooltip = "Only trigger when holding right mouse (aim-down-sights)",
    callback = function(state)
        triggerbotRequireAim = state
    end
})

MiscCombat:AddSlider({
    text = "Triggerbot Cooldown",
    min = 0.05,
    max = 0.5,
    increment = 0.01,
    default = 0.12,
    flag = "TriggerbotCooldown",
    tooltip = "Seconds between shots",
    callback = function(v)
        triggerbotCooldown = v
    end
})

MiscCombat:AddSlider({
    text = "Click Hold Time",
    min = 0.01,
    max = 0.1,
    increment = 0.01,
    default = 0.03,
    flag = "TriggerbotHoldTime",
    tooltip = "How long to hold mouse1 (some games need this)",
    callback = function(v)
        triggerbotHoldTime = v
    end
})

-- Hit markers (visual when triggerbot fires)
MiscCombat:AddSeparator({ text = "Hit Markers" })

local hitMarkerEnabled = false
local hitMarkerDuration = 0.2
local hitMarkerLines = {}
local hitMarkerStartTime = 0
local hitMarkerVisible = false

local function createHitMarkerDrawings()
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.new(1, 1, 1)
        line.Transparency = 0.3
        line.Visible = false
        hitMarkerLines[i] = line
    end
end
local function showHitMarker()
    if not hitMarkerEnabled or not Camera then return end
    hitMarkerVisible = true
    hitMarkerStartTime = tick()
    local viewport = Camera.ViewportSize
    local cx, cy = viewport.X / 2, viewport.Y / 2
    local s = 6
    local positions = {
        { Vector2.new(cx - s, cy), Vector2.new(cx - 2, cy) },
        { Vector2.new(cx + 2, cy), Vector2.new(cx + s, cy) },
        { Vector2.new(cx, cy - s), Vector2.new(cx, cy - 2) },
        { Vector2.new(cx, cy + 2), Vector2.new(cx, cy + s) }
    }
    for i, line in pairs(hitMarkerLines) do
        if line and positions[i] then
            line.From = positions[i][1]
            line.To = positions[i][2]
            line.Visible = true
        end
    end
end
createHitMarkerDrawings()

-- Show hit marker when triggerbot fires (hook into lastTriggerTime and draw)
local hitMarkerConnection = nil

MiscCombat:AddToggle({
    text = "Hit Markers",
    state = false,
    flag = "HitMarkerEnabled",
    tooltip = "Show X on screen when triggerbot fires",
    callback = function(state)
        hitMarkerEnabled = state
        if not state then
            for _, line in pairs(hitMarkerLines) do
                if line then line.Visible = false end
            end
            hitMarkerVisible = false
        end
    end
})

MiscCombat:AddSlider({
    text = "Hit Marker Duration",
    min = 0.1,
    max = 0.5,
    increment = 0.05,
    default = 0.2,
    flag = "HitMarkerDuration",
    callback = function(v)
        hitMarkerDuration = v
    end
})

-- Kill counter
MiscCombat:AddSeparator({ text = "Kill Counter" })

local killCounterEnabled = false
local killCount = 0
local killCounterText = Drawing.new("Text")
killCounterText.Visible = false
killCounterText.Size = 18
killCounterText.Center = true
killCounterText.Outline = true
killCounterText.Color = Color3.new(1, 1, 1)

local lastHitPlayer = nil
local function onCharacterDied(humanoid)
    local victim = humanoid.Parent and Players:GetPlayerFromCharacter(humanoid.Parent)
    if victim and victim == lastHitPlayer then
        killCount = killCount + 1
    end
end

MiscCombat:AddToggle({
    text = "Kill Counter",
    state = false,
    flag = "KillCounterEnabled",
    tooltip = "Show kills (counts when you last hit then they die)",
    callback = function(state)
        killCounterEnabled = state
        killCounterText.Visible = state
        if not state then killCount = 0 end
    end
})

-- Track last hit for kill counter (when triggerbot fires we set lastHitPlayer)
-- We'll set lastHitPlayer in triggerbotStep when we fire

-- ===================== CUSTOM CROSSHAIR =====================
MiscVisual:AddSeparator({ text = "Crosshair" })

local crosshairEnabled = false
local crosshairSize = 8
local crosshairGap = 2
local crosshairColor = Color3.fromRGB(255, 255, 255)
local crosshairThickness = 1

local crosshairLines = {}
local function createCrosshairDrawings()
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = crosshairThickness
        line.Color = crosshairColor
        line.Transparency = 1
        line.Visible = false
        crosshairLines[i] = line
    end
end
local function removeCrosshairDrawings()
    for _, line in pairs(crosshairLines) do
        pcall(function() line:Remove() end)
    end
    table.clear(crosshairLines)
end
createCrosshairDrawings()

local crosshairConnection = nil
local function updateCrosshair()
    if not crosshairEnabled or not Camera then return end
    local viewport = Camera.ViewportSize
    local cx, cy = viewport.X / 2, viewport.Y / 2
    local s, g = crosshairSize, crosshairGap
    local positions = {
        { Vector2.new(cx, cy - s), Vector2.new(cx, cy - g) },
        { Vector2.new(cx, cy + g), Vector2.new(cx, cy + s) },
        { Vector2.new(cx - s, cy), Vector2.new(cx - g, cy) },
        { Vector2.new(cx + g, cy), Vector2.new(cx + s, cy) }
    }
    for i, line in pairs(crosshairLines) do
        local p = positions[i]
        if p and line then
            line.From = p[1]
            line.To = p[2]
            line.Color = crosshairColor
            line.Thickness = crosshairThickness
            line.Visible = true
        end
    end
end

MiscVisual:AddToggle({
    text = "Custom Crosshair",
    state = false,
    flag = "CustomCrosshair",
    tooltip = "Draw a crosshair at screen center",
    callback = function(state)
        crosshairEnabled = state
        if crosshairConnection then
            crosshairConnection:Disconnect()
            crosshairConnection = nil
        end
        for _, line in pairs(crosshairLines) do
            if line then line.Visible = false end
        end
        if state then
            if #crosshairLines == 0 then createCrosshairDrawings() end
            crosshairConnection = RunService.RenderStepped:Connect(updateCrosshair)
        end
    end
})

MiscVisual:AddSlider({
    text = "Crosshair Size",
    min = 4,
    max = 24,
    increment = 1,
    default = 8,
    flag = "CrosshairSize",
    callback = function(v)
        crosshairSize = v
    end
})

MiscVisual:AddSlider({
    text = "Crosshair Gap",
    min = 0,
    max = 10,
    increment = 1,
    default = 2,
    flag = "CrosshairGap",
    callback = function(v)
        crosshairGap = v
    end
})

MiscVisual:AddColor({
    text = "Crosshair Color",
    color = Color3.fromRGB(255, 255, 255),
    flag = "CrosshairColor",
    callback = function(c)
        crosshairColor = c
    end
})

-- ===================== INFO: Coordinates, Time, FPS =====================
MiscInfo:AddSeparator({ text = "Screen Info" })

local coordsEnabled = false
local coordsText = Drawing.new("Text")
coordsText.Visible = false
coordsText.Size = 14
coordsText.Center = false
coordsText.Outline = true
coordsText.Color = Color3.new(1, 1, 1)
coordsText.Position = Vector2.new(10, 10)

local timeEnabled = false
local timeText = Drawing.new("Text")
timeText.Visible = false
timeText.Size = 14
timeText.Center = false
timeText.Outline = true
timeText.Color = Color3.new(1, 1, 1)
timeText.Position = Vector2.new(10, 28)

local fpsEnabled = false
local fpsText = Drawing.new("Text")
fpsText.Visible = false
fpsText.Size = 14
fpsText.Center = false
fpsText.Outline = true
fpsText.Color = Color3.new(0, 1, 0)
fpsText.Position = Vector2.new(10, 46)

local lastFpsUpdate = 0
local fpsFrames = 0
local fpsValue = 0

MiscInfo:AddToggle({
    text = "Coordinates",
    state = false,
    flag = "CoordsEnabled",
    tooltip = "Show your position on screen",
    callback = function(state)
        coordsEnabled = state
        coordsText.Visible = state
    end
})

MiscInfo:AddToggle({
    text = "Game Time",
    state = false,
    flag = "TimeEnabled",
    tooltip = "Show game clock time",
    callback = function(state)
        timeEnabled = state
        timeText.Visible = state
    end
})

MiscInfo:AddToggle({
    text = "FPS Counter",
    state = false,
    flag = "FPSEnabled",
    tooltip = "Show FPS on screen",
    callback = function(state)
        fpsEnabled = state
        fpsText.Visible = state
    end
})

-- ===================== UTILITY: Panic, Auto Respawn, Third Person =====================
MiscUtility:AddSeparator({ text = "Utility" })

local autoRespawnEnabled = false
local autoRespawnDelay = 2

local thirdPersonEnabled = false
local thirdPersonDistance = 20

MiscUtility:AddBind({
    text = "Panic Key",
    tooltip = "Press to disable triggerbot, crosshair, hit markers, coords, time, FPS",
    flag = "PanicKey",
    bind = "NONE",
    mode = "toggle",
    callback = function(state)
        if not state then return end
        triggerbotEnabled = false
        if triggerbotConnection then
            triggerbotConnection:Disconnect()
            triggerbotConnection = nil
        end
        crosshairEnabled = false
        if crosshairConnection then
            crosshairConnection:Disconnect()
            crosshairConnection = nil
        end
        for _, line in pairs(crosshairLines) do if line then line.Visible = false end end
        hitMarkerEnabled = false
        for _, line in pairs(hitMarkerLines) do if line then line.Visible = false end end
        coordsEnabled = false
        coordsText.Visible = false
        timeEnabled = false
        timeText.Visible = false
        fpsEnabled = false
        fpsText.Visible = false
        killCounterText.Visible = false
        if _G.CROW and _G.CROW.SendNotification then
            _G.CROW:SendNotification("Panic: misc disabled", 2)
        end
    end
})

MiscUtility:AddToggle({
    text = "Auto Respawn",
    state = false,
    flag = "AutoRespawnEnabled",
    tooltip = "Respawn automatically after death",
    callback = function(state)
        autoRespawnEnabled = state
    end
})

MiscUtility:AddSlider({
    text = "Respawn Delay",
    min = 0.5,
    max = 5,
    increment = 0.5,
    default = 2,
    flag = "AutoRespawnDelay",
    callback = function(v)
        autoRespawnDelay = v
    end
})

MiscUtility:AddToggle({
    text = "Force Third Person",
    state = false,
    flag = "ThirdPersonEnabled",
    tooltip = "Lock camera zoom to this distance (third person)",
    callback = function(state)
        thirdPersonEnabled = state
        if Camera then
            if state then
                Camera.CameraMinZoomDistance = thirdPersonDistance
                Camera.CameraMaxZoomDistance = thirdPersonDistance
            else
                Camera.CameraMinZoomDistance = 0.5
                Camera.CameraMaxZoomDistance = 128
            end
        end
    end
})

MiscUtility:AddSlider({
    text = "Third Person Distance",
    min = 5,
    max = 50,
    increment = 1,
    default = 20,
    flag = "ThirdPersonDistance",
    callback = function(v)
        thirdPersonDistance = v
        if thirdPersonEnabled and Camera then
            Camera.CameraMaxZoomDistance = v
        end
    end
})

MiscUtility:AddSeparator({ text = "Other" })

MiscUtility:AddButton({
    text = "Reset Kill Counter",
    tooltip = "Set kills back to 0",
    callback = function()
        killCount = 0
        if _G.CROW and _G.CROW.SendNotification then
            _G.CROW:SendNotification("Kill counter reset", 2)
        end
    end
})

-- ===================== UPDATE LOOPS =====================
-- Hit marker timer + kill counter + coords + time + FPS update
RunService.RenderStepped:Connect(function()
    local cam = Camera
    if not cam then return end
    local viewport = cam.ViewportSize

    -- Hit marker
    if hitMarkerEnabled and hitMarkerVisible then
        local elapsed = tick() - hitMarkerStartTime
        if elapsed >= hitMarkerDuration then
            hitMarkerVisible = false
            for _, line in pairs(hitMarkerLines) do
                if line then line.Visible = false end
            end
        end
    end

    -- Show hit marker when triggerbot fires (set in triggerbotStep via lastHitPlayer; we show when we just fired)
    -- We need to show hit marker from triggerbot - set a flag when we fire and show in next frame
    -- Done below by checking lastTriggerTime and showing if within duration (alternative: set a "justFired" and showHitMarker() from triggerbotStep)
    -- So in triggerbotStep after we fire we call showHitMarker(). Let me add that in the triggerbot callback... Actually we already have showHitMarker() - we need to call it from triggerbotStep when we fire. Add showHitMarker() call in triggerbotStep after lastTriggerTime = now.

    -- Kill counter position
    if killCounterEnabled then
        killCounterText.Text = "Kills: " .. tostring(killCount)
        killCounterText.Position = Vector2.new(viewport.X / 2 - 30, 60)
        killCounterText.Visible = true
    end

    -- Coords
    if coordsEnabled and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            coordsText.Text = string.format("X: %.0f  Y: %.0f  Z: %.0f", p.X, p.Y, p.Z)
            coordsText.Visible = true
        end
    end

    -- Time
    if timeEnabled then
        timeText.Text = "Time: " .. (Lighting.ClockTime and string.format("%.1f", Lighting.ClockTime) or "?")
        timeText.Position = Vector2.new(10, 28)
        timeText.Visible = true
    end

    -- FPS
    fpsFrames = fpsFrames + 1
    local t = tick()
    if t - lastFpsUpdate >= 0.5 then
        fpsValue = math.floor(fpsFrames / (t - lastFpsUpdate))
        fpsFrames = 0
        lastFpsUpdate = t
    end
    if fpsEnabled then
        fpsText.Text = "FPS: " .. tostring(fpsValue)
        fpsText.Position = Vector2.new(10, 46)
        fpsText.Visible = true
    end
end)

-- Kill counter: listen for humanoid deaths to increment when lastHitPlayer dies
local function setupKillCounterListen()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h.Died:Connect(function()
                    if p == lastHitPlayer then
                        killCount = killCount + 1
                    end
                end)
            end
        end
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            local h = p.Character:WaitForChild("Humanoid", 5)
            if h then
                h.Died:Connect(function()
                    if p == lastHitPlayer then
                        killCount = killCount + 1
                    end
                end)
            end
        end)
    end)
end
pcall(setupKillCounterListen)

-- Auto respawn
LocalPlayer.CharacterAdded:Connect(function()
    lastHitPlayer = nil
end)
LocalPlayer.CharacterRemoving:Connect(function()
    if autoRespawnEnabled then
        task.delay(autoRespawnDelay, function()
            LocalPlayer:LoadCharacter()
        end)
    end
end)

-- ===================== CLEANUP =====================
_G.MiscSecCleanup = function()
    crosshairEnabled = false
    triggerbotEnabled = false
    hitMarkerEnabled = false
    killCounterEnabled = false
    coordsEnabled = false
    timeEnabled = false
    fpsEnabled = false
    if crosshairConnection then
        crosshairConnection:Disconnect()
        crosshairConnection = nil
    end
    if triggerbotConnection then
        triggerbotConnection:Disconnect()
        triggerbotConnection = nil
    end
    for _, line in pairs(crosshairLines) do if line then line.Visible = false end end
    for _, line in pairs(hitMarkerLines) do if line then line.Visible = false end end
    killCounterText.Visible = false
    coordsText.Visible = false
    timeText.Visible = false
    fpsText.Visible = false
    removeCrosshairDrawings()
    pcall(function() killCounterText:Remove() end)
    pcall(function() coordsText:Remove() end)
    pcall(function() timeText:Remove() end)
    pcall(function() fpsText:Remove() end)
    for _, line in pairs(hitMarkerLines) do pcall(function() line:Remove() end) end
end
</think>
Fixing MiscSec: correcting the triggerbot/hit-marker logic and removing the duplicate/invalid tail.
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
StrReplace