-- ===================== MISC SECTION =====================
-- Custom Crosshair, Triggerbot, etc. No sounds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
    -- Top, Bottom, Left, Right segments (gap in middle)
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
    tooltip = "Length of crosshair lines",
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
    tooltip = "Gap at center",
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

-- ===================== TRIGGERBOT =====================
MiscCombat:AddSeparator({ text = "Triggerbot" })

local triggerbotEnabled = false
local triggerbotCooldown = 0.15
local lastTriggerTime = 0
local triggerbotTeamCheck = false

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
    lastTriggerTime = now
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim and vim.SendMouseButtonEvent then
            local viewport = Camera.ViewportSize
            local x, y = viewport.X / 2, viewport.Y / 2
            vim:SendMouseButtonEvent(x, y, 0, true)
            task.wait()
            vim:SendMouseButtonEvent(x, y, 0, false)
        end
    end)
end

MiscCombat:AddToggle({
    text = "Triggerbot",
    state = false,
    flag = "TriggerbotEnabled",
    tooltip = "Auto-fire when crosshair on enemy (game-dependent)",
    callback = function(state)
        triggerbotEnabled = state
        if triggerbotConnection then
            triggerbotConnection:Disconnect()
            triggerbotConnection = nil
        end
        if state then
            triggerbotConnection = RunService.Heartbeat:Connect(triggerbotStep)
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

MiscCombat:AddSlider({
    text = "Triggerbot Cooldown",
    min = 0.05,
    max = 0.5,
    increment = 0.05,
    default = 0.15,
    flag = "TriggerbotCooldown",
    tooltip = "Seconds between shots",
    callback = function(v)
        triggerbotCooldown = v
    end
})

-- ===================== CLEANUP =====================
_G.MiscSecCleanup = function()
    crosshairEnabled = false
    triggerbotEnabled = false
    if crosshairConnection then
        crosshairConnection:Disconnect()
        crosshairConnection = nil
    end
    if triggerbotConnection then
        triggerbotConnection:Disconnect()
        triggerbotConnection = nil
    end
    removeCrosshairDrawings()
end
