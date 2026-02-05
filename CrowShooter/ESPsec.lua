-- ===================== ESP SECTION =====================
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Validate critical objects
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

local Camera = workspace.CurrentCamera
if not Camera then
    return
end

-- Validate _G.ESPTab (assumed to be defined in the larger script)
if not _G.ESPTab then
    return
end

-- Create ESP sections
local secesp = _G.ESPTab:AddSection("ESP", 1)
local seccustomesp = _G.ESPTab:AddSection("Customise ESP", 2)

-- Store references to all UI elements and ESP objects
local ESPObjects = {}

-- Tunable constants
local VISIBILITY_CACHE_INTERVAL = 0.2
local ESP_SETTINGS_SYNC_INTERVAL = 3

-- Store current settings; defaults must match slider defaults so visuals and sliders match on load
local ESPSettings = {
    BoxThickness = 1,
    TextSize = 15,
    TextColor = Color3.fromRGB(255, 255, 255),
    AllyColor = Color3.fromRGB(96, 205, 255),
    EnemyColor = Color3.fromRGB(255, 70, 70),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerOrigin = "Bottom",
    HealthBarWidth = 2,
    HealthBarOffset = 0,
    ESPScale = 1,
    SkeletonThickness = 1,
    TracerThickness = 1,
    NameTextOffset = 16,
    DistanceTextOffset = 2,
    VisibilityTextOffset = 2,
    MaxDistance = 500
}

-- Track health bar animation states
local HealthBarStates = {}

-- Setup Main ESP section
secesp:AddSeparator({
    text = "Main"
})

-- Main ESP Toggle
local ShowESP = secesp:AddToggle({
    text = "Enable ESP",
    state = false,
    tooltip = "Master switch for ESP features",
    flag = "ShowESP"
})

ShowESP:AddBind({
    text = "Toggle ESP",
    tooltip = "Hotkey to toggle ESP",
    mode = "toggle",
    bind = "NONE",
    flag = "ESPToggleKey",
    callback = function(state)
        ShowESP:SetState(state)
    end
})

-- Team check: right under Enable ESP (Separator=1, Enable ESP=2, so this must be 3)
secesp:AddToggle({
    text    = "Team check",
    state   = false,
    flag    = "ESPTeamCheck",
    tooltip = "Hide ESP for teammates (only show enemies)",
    order   = 3,
})

-- Team Colors: color ESP by player's Roblox team color (box, tracer, skeleton)
secesp:AddToggle({
    text    = "Team Colors",
    state   = false,
    flag    = "ESPTeamColors",
    tooltip = "Use each player's team color for box, tracer, and skeleton",
    order   = 4,
})

-- ESP Features Toggles
local ESPBox = secesp:AddToggle({
    text = "Show Box",
    state = false,
    tooltip = "Show box around players",
    flag = "ESPBox"
})

local ShowHealthBar = secesp:AddToggle({
    text = "Show Health Bar",
    state = false,
    tooltip = "Show health bar next to players",
    flag = "ShowHealthBar"
})

local ShowDistance = secesp:AddToggle({
    text = "Show Distance",
    state = false,
    tooltip = "Show distance to players",
    flag = "ShowDistance"
})

local ShowNames = secesp:AddToggle({
    text = "Show Names",
    state = false,
    tooltip = "Show player names",
    flag = "ShowNames"
})

local ShowVisibility = secesp:AddToggle({
    text = "Show Visibility",
    state = false,
    tooltip = "Show if players are visible",
    flag = "ShowVisibility"
})

local ShowSkeleton = secesp:AddToggle({
    text = "Show Skeleton",
    state = false,
    tooltip = "Show player skeleton",
    flag = "ShowSkeleton"
})

local ShowTracers = secesp:AddToggle({
    text = "Show Tracers",
    state = false,
    tooltip = "Show lines to players",
    flag = "ShowTracers"
})

local ShowTool = secesp:AddToggle({
    text = "Show Tool",
    state = false,
    tooltip = "Show equipped tool name below distance text",
    flag = "ShowTool"
})

local EnemyList = _G.CROW_EnemyList or {}
_G.CROW_EnemyList = EnemyList

local enemyListPlayerList = secesp:AddList({
    text = "Select player",
    selected = {},
    multi = true,
    values = {"(Refresh to load)"},
    flag = "EnemyListSelectedPlayer",
    tooltip = "Click Refresh, then select one or more players to add or remove from enemy list"
})

secesp:AddButton({
    text = "Refresh players",
    callback = function()
        if enemyListPlayerList.ClearValues then enemyListPlayerList:ClearValues() end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p:IsA("Player") and enemyListPlayerList.AddValue then
                enemyListPlayerList:AddValue(p.Name)
            end
        end
        if enemyListPlayerList.values and #enemyListPlayerList.values == 0 and enemyListPlayerList.AddValue then
            enemyListPlayerList:AddValue("(No other players)")
        end
        -- Clear multi-selection after refresh
        if enemyListPlayerList.Select then
            enemyListPlayerList:Select({}, true)
        end
    end
})

secesp:AddButton({
    text = "Add to enemy list",
    callback = function()
        local sel = library and library.flags and library.flags["EnemyListSelectedPlayer"]
        if not sel then return end
        local names = type(sel) == "table" and sel or { sel }
        for _, name in ipairs(names) do
            if name and name ~= "(Refresh to load)" and name ~= "(No other players)" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == name then EnemyList[p] = true break end
                end
            end
        end
    end
})

secesp:AddButton({
    text = "Remove from enemy list",
    callback = function()
        local sel = library and library.flags and library.flags["EnemyListSelectedPlayer"]
        if not sel then return end
        local names = type(sel) == "table" and sel or { sel }
        for _, name in ipairs(names) do
            if name then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == name then EnemyList[p] = nil break end
                end
            end
        end
    end
})

-- IsEnemy: enemy list only (no teams). Used by AimSec.
local function isEnemy(player)
    return player and player ~= LocalPlayer and EnemyList[player] == true
end
_G.CROW_IsEnemy = isEnemy

-- Team check: true if player is on the same team as LocalPlayer (hide ESP for teammates).
local function isTeammate(player)
    if not player or player == LocalPlayer then return true end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if not myTeam or not theirTeam then return false end
    return myTeam == theirTeam
end

seccustomesp:AddSeparator({
    text = "Colors"
})

-- ESP Text Color (name, distance, visibility text)
local ESPTextColor = seccustomesp:AddColor({
    text = "ESP Text Color",
    tooltip = "Color for names, distance, and visibility text",
    color = ESPSettings.TextColor,
    flag = "ESPTextColor",
    trans = 0,
    callback = function(color)
        ESPSettings.TextColor = color or ESPSettings.TextColor
    end
})

-- Team color settings
local AllyColor = seccustomesp:AddColor({
    text = "Ally Color",
    tooltip = "Set the color for teammates",
    color = ESPSettings.AllyColor,
    flag = "AllyColor",
    trans = 0,
    callback = function(color)
        ESPSettings.AllyColor = color or ESPSettings.AllyColor
    end
})

local EnemyColor = seccustomesp:AddColor({
    text = "Enemy Color",
    tooltip = "Set the color for enemies",
    color = ESPSettings.EnemyColor,
    flag = "EnemyColor",
    trans = 0,
    callback = function(color)
        ESPSettings.EnemyColor = color or ESPSettings.EnemyColor
    end
})

local SkeletonColor = seccustomesp:AddColor({
    text = "Skeleton Color",
    tooltip = "Set the color for skeleton lines",
    color = ESPSettings.SkeletonColor,
    flag = "SkeletonColor",
    trans = 0,
    callback = function(color)
        ESPSettings.SkeletonColor = color or ESPSettings.SkeletonColor
    end
})

local TracerColor = seccustomesp:AddColor({
    text = "Tracer Color",
    tooltip = "Set the color for tracer lines",
    color = ESPSettings.TracerColor,
    flag = "TracerColor",
    trans = 0,
    callback = function(color)
        ESPSettings.TracerColor = color or ESPSettings.TracerColor
    end
})

-- Tracer origin: where the line starts (Bottom, Top, Center, Mouse)
seccustomesp:AddList({
    text = "Tracer Origin",
    selected = "Bottom",
    values = {"Bottom", "Top", "Center", "Mouse"},
    flag = "TracerOrigin",
    tooltip = "Where tracer lines start: Bottom, Top, Center of screen, or Mouse",
    callback = function()
        if library and library.flags and library.flags["TracerOrigin"] then
            ESPSettings.TracerOrigin = library.flags["TracerOrigin"]
        end
    end
})

seccustomesp:AddSeparator({
    text = "Size Settings"
})

-- Box Thickness Slider
local BoxThickness = seccustomesp:AddSlider({
    text = "Box Thickness",
    min = 1,
    max = 5,
    default = 1,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the thickness of ESP boxes",
    flag = "BoxThickness",
    callback = function(value)
        ESPSettings.BoxThickness = value or 1
        for _, data in pairs(ESPObjects) do
            if data.Box then
                data.Box.Thickness = ESPSettings.BoxThickness
            end
        end
    end
})

-- Text Size Slider
local TextSize = seccustomesp:AddSlider({
    text = "Text Size",
    min = 10,
    max = 24,
    default = 15,
    increment = 1,
    suffix = "pt",
    tooltip = "Adjust the size of ESP text",
    flag = "TextSize",
    callback = function(value)
        ESPSettings.TextSize = value or 15
        for _, data in pairs(ESPObjects) do
            if data.Distance then data.Distance.Size = ESPSettings.TextSize end
            if data.Name then data.Name.Size = ESPSettings.TextSize end
            if data.Visibility then data.Visibility.Size = ESPSettings.TextSize end
        end
    end
})

-- Health Bar Width Slider (default = min)
local HealthBarWidth = seccustomesp:AddSlider({
    text = "Health Bar Width",
    min = 2,
    max = 8,
    default = 2,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the width of health bars",
    flag = "HealthBarWidth",
    callback = function(value)
        ESPSettings.HealthBarWidth = value or 2
    end
})

-- Health Bar Offset Slider
local HealthBarOffset = seccustomesp:AddSlider({
    text = "Health Bar Offset",
    min = 0,
    max = 10,
    default = 0,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the distance of health bar from box",
    flag = "HealthBarOffset",
    callback = function(value)
        ESPSettings.HealthBarOffset = value or 0
    end
})

-- Skeleton Thickness Slider
local SkeletonThickness = seccustomesp:AddSlider({
    text = "Skeleton Thickness",
    min = 1,
    max = 4,
    default = 1,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the thickness of skeleton lines",
    flag = "SkeletonThickness",
    callback = function(value)
        ESPSettings.SkeletonThickness = value or 1
        for _, data in pairs(ESPObjects) do
            for _, line in pairs(data.Skeleton or {}) do
                line.Thickness = ESPSettings.SkeletonThickness
            end
        end
    end
})

-- Tracer Thickness Slider
local TracerThickness = seccustomesp:AddSlider({
    text = "Tracer Thickness",
    min = 1,
    max = 4,
    default = 1,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the thickness of tracer lines",
    flag = "TracerThickness",
    callback = function(value)
        ESPSettings.TracerThickness = value or 1
        for _, data in pairs(ESPObjects) do
            if data.Tracer then
                data.Tracer.Thickness = ESPSettings.TracerThickness
            end
        end
    end
})

-- Name Text Offset Slider
local NameTextOffset = seccustomesp:AddSlider({
    text = "Name Text Offset",
    min = 0,
    max = 30,
    default = 16,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the distance of name text above box",
    flag = "NameTextOffset",
    callback = function(value)
        ESPSettings.NameTextOffset = value or 16
    end
})

-- Distance Text Offset Slider
local DistanceTextOffset = seccustomesp:AddSlider({
    text = "Distance Text Offset",
    min = 0,
    max = 20,
    default = 2,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the distance of distance text below box",
    flag = "DistanceTextOffset",
    callback = function(value)
        ESPSettings.DistanceTextOffset = value or 2
    end
})

-- Visibility Text Offset Slider
local VisibilityTextOffset = seccustomesp:AddSlider({
    text = "Visibility Text Offset",
    min = 0,
    max = 20,
    default = 2,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the distance of visibility text below box",
    flag = "VisibilityTextOffset",
    callback = function(value)
        ESPSettings.VisibilityTextOffset = value or 2
    end
})

-- ESP Scale Slider
local ESPScale = seccustomesp:AddSlider({
    text = "ESP Scale",
    min = 50,
    max = 150,
    default = 100,
    increment = 10,
    suffix = "%",
    tooltip = "Adjust the overall scale of ESP elements",
    flag = "ESPScale",
    callback = function(value)
        ESPSettings.ESPScale = value / 100
    end
})

-- Max Distance (0 = no limit)
seccustomesp:AddSlider({
    text = "Max Distance",
    min = 0,
    max = 2000,
    default = 500,
    increment = 50,
    suffix = " studs",
    tooltip = "Hide ESP beyond this distance. 0 = no limit.",
    flag = "ESPMaxDistance",
    callback = function(value)
        ESPSettings.MaxDistance = value
    end
})

-- Sync ESPSettings from library.flags so slider defaults and config load match what ESP draws
local function syncESPSettingsFromFlags()
    local lib = library
    if not lib or not lib.flags then return end
    local f = lib.flags
    if f.BoxThickness ~= nil then ESPSettings.BoxThickness = f.BoxThickness end
    if f.TextSize ~= nil then ESPSettings.TextSize = f.TextSize end
    if f.HealthBarWidth ~= nil then ESPSettings.HealthBarWidth = f.HealthBarWidth end
    if f.HealthBarOffset ~= nil then ESPSettings.HealthBarOffset = f.HealthBarOffset end
    if f.SkeletonThickness ~= nil then ESPSettings.SkeletonThickness = f.SkeletonThickness end
    if f.TracerThickness ~= nil then ESPSettings.TracerThickness = f.TracerThickness end
    if f.NameTextOffset ~= nil then ESPSettings.NameTextOffset = f.NameTextOffset end
    if f.DistanceTextOffset ~= nil then ESPSettings.DistanceTextOffset = f.DistanceTextOffset end
    if f.VisibilityTextOffset ~= nil then ESPSettings.VisibilityTextOffset = f.VisibilityTextOffset end
    if f.ESPScale ~= nil then ESPSettings.ESPScale = f.ESPScale / 100 end
    if f.ESPMaxDistance ~= nil then ESPSettings.MaxDistance = f.ESPMaxDistance end
    if f.TracerOrigin ~= nil then ESPSettings.TracerOrigin = f.TracerOrigin end
end
task.defer(syncESPSettingsFromFlags)

-- Create ESP for a player
local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] or not player:IsA("Player") then
        return
    end
    
    local success, data = pcall(function()
        return {
            Box = Drawing.new("Square"),
            Distance = Drawing.new("Text"),
            HealthOutline = Drawing.new("Square"),
            HealthBar = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Visibility = Drawing.new("Text"),
            Tool = Drawing.new("Text"),
            Tracer = Drawing.new("Line"),
            Skeleton = {
                HeadTorso = Drawing.new("Line"),
                TorsoLeftArm = Drawing.new("Line"),
                TorsoRightArm = Drawing.new("Line"),
                TorsoLeftLeg = Drawing.new("Line"),
                TorsoRightLeg = Drawing.new("Line")
            }
        }
    end)
    
    if not success then
        return
    end
    
    -- Initialize ESP box
    data.Box.Thickness = ESPSettings.BoxThickness
    data.Box.Filled = false
    data.Box.Visible = false
    
    -- Initialize distance text
    data.Distance.Size = ESPSettings.TextSize
    data.Distance.Center = true
    data.Distance.Outline = true
    data.Distance.OutlineColor = Color3.new(0, 0, 0)
    data.Distance.Font = Drawing.Fonts.UI
    data.Distance.Visible = false
    
    -- Initialize health bar
    data.HealthOutline.Thickness = 1
    data.HealthOutline.Filled = true
    data.HealthOutline.Color = Color3.new(0, 0, 0)
    data.HealthOutline.Visible = false
    
    data.HealthBar.Thickness = 1
    data.HealthBar.Filled = true
    data.HealthBar.Color = Color3.new(0, 1, 0)
    data.HealthBar.Visible = false
    
    -- Initialize name
    data.Name.Size = ESPSettings.TextSize
    data.Name.Center = true
    data.Name.Outline = true
    data.Name.OutlineColor = Color3.new(0, 0, 0)
    data.Name.Font = Drawing.Fonts.UI
    data.Name.Visible = false
    
    -- Initialize visibility text
    data.Visibility.Size = ESPSettings.TextSize
    data.Visibility.Center = true
    data.Visibility.Outline = true
    data.Visibility.OutlineColor = Color3.new(0, 0, 0)
    data.Visibility.Font = Drawing.Fonts.UI
    data.Visibility.Visible = false

    -- Initialize tool text
    data.Tool.Size = ESPSettings.TextSize
    data.Tool.Center = true
    data.Tool.Outline = true
    data.Tool.OutlineColor = Color3.new(0, 0, 0)
    data.Tool.Font = Drawing.Fonts.UI
    data.Tool.Visible = false
    
    -- Initialize tracer
    data.Tracer.Thickness = ESPSettings.TracerThickness
    data.Tracer.Visible = false
    
    -- Initialize skeleton
    for _, line in pairs(data.Skeleton) do
        line.Thickness = ESPSettings.SkeletonThickness
        line.Visible = false
    end
    
    ESPObjects[player] = data
    HealthBarStates[player] = { CurrentHeight = 0 }
end

-- Remove ESP for a player
local function removeESP(player)
    local data = ESPObjects[player]
    if not data then
        return
    end
    
    for _, obj in pairs(data) do
        if type(obj) == "table" then
            for _, line in pairs(obj) do
                if line and line.Remove then
                    line:Remove()
                end
            end
        elseif obj and obj.Remove then
            obj:Remove()
        end
    end
    ESPObjects[player] = nil
    HealthBarStates[player] = nil
end

-- Check if player is visible
local function isPlayerVisible(character)
    if not LocalPlayer.Character or not character then
        return false
    end
    
    local localHead = LocalPlayer.Character:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    
    if not localHead or not targetHead then
        return false
    end
    
    local ray = Ray.new(localHead.Position, (targetHead.Position - localHead.Position).Unit * 1000)
    local ignoreList = {LocalPlayer.Character}
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    
    return hitPart and hitPart:IsDescendantOf(character)
end

-- Update all ESP settings
local function updateAllESPSettings()
    for _, data in pairs(ESPObjects) do
        if data.Box then data.Box.Thickness = ESPSettings.BoxThickness end
        if data.Distance then data.Distance.Size = ESPSettings.TextSize end
        if data.Name then data.Name.Size = ESPSettings.TextSize end
        if data.Visibility then data.Visibility.Size = ESPSettings.TextSize end
        if data.Tool then data.Tool.Size = ESPSettings.TextSize end
        if data.Tracer then data.Tracer.Thickness = ESPSettings.TracerThickness end
        for _, line in pairs(data.Skeleton or {}) do
            line.Thickness = ESPSettings.SkeletonThickness
        end
    end
end

-- Create ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Handle player joining and leaving
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    EnemyList[player] = nil
    removeESP(player)
end)

-- Hide all drawing objects for one player's ESP data (shared by toggle-off, invalid player, team check, max dist)
local function setESPDataVisible(data, visible)
    for _, obj in pairs(data) do
        if type(obj) == "table" then
            for _, line in pairs(obj) do
                if line and line.Visible ~= nil then line.Visible = visible end
            end
        elseif obj and obj.Visible ~= nil then
            obj.Visible = visible
        end
    end
end

local lastESPShow = false
local visibilityCache = {}
local visibilityCacheTime = 0

RunService.RenderStepped:Connect(function(delta)
    local lib = library
    if not lib or not lib.flags then return end
    if not lib.flags["ShowESP"] then
        if lastESPShow then
            for _, data in pairs(ESPObjects) do setESPDataVisible(data, false) end
            lastESPShow = false
        end
        return
    end
    lastESPShow = true

    local flags = lib.flags
    local now = tick()
    local refreshVisibility = (now - visibilityCacheTime) >= VISIBILITY_CACHE_INTERVAL
    if refreshVisibility then visibilityCacheTime = now end

    -- Tracer origin: compute once per frame (avoids N× GetMouseLocation / math per player)
    local vw, vh = Camera.ViewportSize.X, Camera.ViewportSize.Y
    local originMode = flags["TracerOrigin"] or ESPSettings.TracerOrigin or "Bottom"
    local tracerFromPos
    if originMode == "Top" then
        tracerFromPos = Vector2.new(vw * 0.5, 0)
    elseif originMode == "Center" then
        tracerFromPos = Vector2.new(vw * 0.5, vh * 0.5)
    elseif originMode == "Mouse" then
        local ok, mousePos = pcall(UserInputService.GetMouseLocation, UserInputService)
        tracerFromPos = (ok and mousePos) and Vector2.new(mousePos.X, mousePos.Y) or Vector2.new(vw * 0.5, vh)
    else
        tracerFromPos = Vector2.new(vw * 0.5, vh)
    end

    -- Use flags when present so slider/config values always match what ESP draws
    local boxThickness = (flags.BoxThickness ~= nil) and flags.BoxThickness or ESPSettings.BoxThickness
    local textSize = (flags.TextSize ~= nil) and flags.TextSize or ESPSettings.TextSize
    local healthBarWidth = (flags.HealthBarWidth ~= nil) and flags.HealthBarWidth or ESPSettings.HealthBarWidth
    local healthBarOffset = (flags.HealthBarOffset ~= nil) and flags.HealthBarOffset or ESPSettings.HealthBarOffset
    local nameTextOffset = (flags.NameTextOffset ~= nil) and flags.NameTextOffset or ESPSettings.NameTextOffset
    local distanceTextOffset = (flags.DistanceTextOffset ~= nil) and flags.DistanceTextOffset or ESPSettings.DistanceTextOffset
    local visibilityTextOffset = (flags.VisibilityTextOffset ~= nil) and flags.VisibilityTextOffset or ESPSettings.VisibilityTextOffset
    local espScale = (flags.ESPScale ~= nil) and (flags.ESPScale / 100) or ESPSettings.ESPScale
    local maxDist = (flags.ESPMaxDistance ~= nil) and flags.ESPMaxDistance or ESPSettings.MaxDistance
    local skeletonThickness = (flags.SkeletonThickness ~= nil) and flags.SkeletonThickness or ESPSettings.SkeletonThickness
    local tracerThickness = (flags.TracerThickness ~= nil) and flags.TracerThickness or ESPSettings.TracerThickness

    for player, data in pairs(ESPObjects) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if not (player:IsA("Player") and character and hrp and humanoid and humanoid.Health > 0) then
            setESPDataVisible(data, false)
            continue
        end

        -- Team check: only show ESP for enemies when toggle is on
        if flags["ESPTeamCheck"] and isTeammate(player) then
            setESPDataVisible(data, false)
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        if maxDist > 0 and distance > maxDist then
            setESPDataVisible(data, false)
            continue
        end
        local scale = math.clamp(1 / (distance / 50), 0.5, 2) * espScale
        local boxW, boxH = 50 * scale, 100 * scale
        local boxX, boxY = pos.X - boxW / 2, pos.Y - boxH / 2

        -- Team Colors = use player's team color; else team check / enemy list logic
        local color
        if flags["ESPTeamColors"] and player.Team and player.Team.TeamColor then
            color = player.Team.TeamColor.Color
        else
            color = (flags["ESPTeamCheck"] and ESPSettings.EnemyColor) or (EnemyList[player] and ESPSettings.EnemyColor) or ESPSettings.AllyColor
        end

        if flags["ESPBox"] and data.Box then
            data.Box.Position = Vector2.new(boxX, boxY)
            data.Box.Size = Vector2.new(boxW, boxH)
            data.Box.Color = color
            data.Box.Thickness = boxThickness
            data.Box.Visible = onScreen
        elseif data.Box then
            data.Box.Visible = false
        end

        if flags["ShowHealthBar"] and data.HealthOutline and data.HealthBar then
            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barWidth = healthBarWidth
            local state = HealthBarStates[player]
            state.CurrentHeight = state.CurrentHeight + (healthRatio - state.CurrentHeight) * math.min(10 * delta, 1)
            
            data.HealthOutline.Position = Vector2.new(boxX - barWidth - healthBarOffset, boxY)
            data.HealthOutline.Size = Vector2.new(barWidth, boxH)
            data.HealthOutline.Visible = onScreen

            data.HealthBar.Position = Vector2.new(boxX - barWidth - healthBarOffset, boxY + (1 - state.CurrentHeight) * boxH)
            data.HealthBar.Size = Vector2.new(barWidth, boxH * state.CurrentHeight)
            data.HealthBar.Color = Color3.fromRGB(255 * (1 - state.CurrentHeight), 255 * state.CurrentHeight, 0)
            data.HealthBar.Visible = onScreen
        else
            if data.HealthBar then data.HealthBar.Visible = false end
            if data.HealthOutline then data.HealthOutline.Visible = false end
        end

        local textColor = ESPSettings.TextColor
        if flags["ShowDistance"] and data.Distance then
            data.Distance.Text = "[" .. math.floor(distance) .. "]"
            data.Distance.Position = Vector2.new(pos.X, boxY + boxH + distanceTextOffset)
            data.Distance.Color = textColor
            data.Distance.Size = textSize
            data.Distance.Visible = onScreen
        elseif data.Distance then
            data.Distance.Visible = false
        end
        
        if flags["ShowNames"] and data.Name then
            data.Name.Text = player.Name
            data.Name.Position = Vector2.new(pos.X, boxY - nameTextOffset)
            data.Name.Color = textColor
            data.Name.Size = textSize
            data.Name.Visible = onScreen
        elseif data.Name then
            data.Name.Visible = false
        end
        
        if flags["ShowVisibility"] and data.Visibility then
            local isVisible
            if refreshVisibility then
                isVisible = isPlayerVisible(character)
                visibilityCache[player] = isVisible
            else
                isVisible = visibilityCache[player] == true
            end
            local visText = isVisible and "Visible" or "Hidden"
            local yOffset = flags["ShowDistance"] and distanceTextOffset + textSize + visibilityTextOffset or visibilityTextOffset
            
            data.Visibility.Text = visText
            data.Visibility.Position = Vector2.new(pos.X, boxY + boxH + yOffset)
            data.Visibility.Color = textColor
            data.Visibility.Size = textSize
            data.Visibility.Visible = onScreen
        elseif data.Visibility then
            data.Visibility.Visible = false
        end

        if flags["ShowTool"] and data.Tool then
            -- Tool name = character.Tool, or the weapon model name in character.Arms (Folder/Model with most BaseParts, not CSSArms)
            local toolObj = character:FindFirstChildOfClass("Tool")
            if not toolObj and character:FindFirstChild("Arms") then
                local arms = character.Arms
                local bestCount = 0
                for _, child in ipairs(arms:GetChildren()) do
                    if (child:IsA("Folder") or child:IsA("Model")) and child.Name ~= "CSSArms" then
                        local count = 0
                        for _, d in ipairs(child:GetDescendants()) do
                            if d:IsA("BasePart") then count = count + 1 end
                        end
                        if count > bestCount then
                            bestCount = count
                            toolObj = child
                        end
                    end
                end
            end
            local rawName = (toolObj and toolObj.Name) or ""
            -- EquippedTool StringValue (anywhere under character): .Value = weapon name; use when present so ESP shows it
            local equippedVal = character:FindFirstChild("EquippedTool", true)
            if equippedVal and equippedVal:IsA("StringValue") and equippedVal.Value and equippedVal.Value ~= "" then
                rawName = equippedVal.Value
            end
            local toolName = (rawName == "" or rawName:lower() == "unarmed") and "" or rawName
            data.Tool.Text = toolName
            local toolYOff = distanceTextOffset + textSize + 4
            if flags["ShowVisibility"] then
                toolYOff = toolYOff + textSize + visibilityTextOffset
            end
            data.Tool.Position = Vector2.new(pos.X, boxY + boxH + toolYOff)
            data.Tool.Color = textColor
            data.Tool.Size = textSize
            data.Tool.Visible = onScreen and (toolName ~= "")
        elseif data.Tool then
            data.Tool.Visible = false
        end

        if flags["ShowSkeleton"] and data.Skeleton then
            local bodyParts = {
                Head = character:FindFirstChild("Head"),
                UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
                RightUpperArm = character:FindFirstChild("RightUpperArm"),
                LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
                RightLowerLeg = character:FindFirstChild("RightLowerLeg")
            }

            if bodyParts.Head and bodyParts.UpperTorso then
                local headPos = Camera:WorldToViewportPoint(bodyParts.Head.Position)
                local torsoPos = Camera:WorldToViewportPoint(bodyParts.UpperTorso.Position)
                
                local skeletonColor = (flags["ESPTeamColors"] and color) or ESPSettings.SkeletonColor
                data.Skeleton.HeadTorso.From = Vector2.new(headPos.X, headPos.Y)
                data.Skeleton.HeadTorso.To = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.HeadTorso.Color = skeletonColor
                data.Skeleton.HeadTorso.Thickness = skeletonThickness
                data.Skeleton.HeadTorso.Visible = onScreen

                if bodyParts.LeftUpperArm then
                    local armPos = Camera:WorldToViewportPoint(bodyParts.LeftUpperArm.Position)
                    data.Skeleton.TorsoLeftArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoLeftArm.To = Vector2.new(armPos.X, armPos.Y)
                    data.Skeleton.TorsoLeftArm.Color = skeletonColor
                    data.Skeleton.TorsoLeftArm.Thickness = skeletonThickness
                    data.Skeleton.TorsoLeftArm.Visible = onScreen
                else
                    data.Skeleton.TorsoLeftArm.Visible = false
                end

                if bodyParts.RightUpperArm then
                    local armPos = Camera:WorldToViewportPoint(bodyParts.RightUpperArm.Position)
                    data.Skeleton.TorsoRightArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoRightArm.To = Vector2.new(armPos.X, armPos.Y)
                    data.Skeleton.TorsoRightArm.Color = skeletonColor
                    data.Skeleton.TorsoRightArm.Thickness = skeletonThickness
                    data.Skeleton.TorsoRightArm.Visible = onScreen
                else
                    data.Skeleton.TorsoRightArm.Visible = false
                end

                if bodyParts.LeftLowerLeg then
                    local legPos = Camera:WorldToViewportPoint(bodyParts.LeftLowerLeg.Position)
                    data.Skeleton.TorsoLeftLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoLeftLeg.To = Vector2.new(legPos.X, legPos.Y)
                    data.Skeleton.TorsoLeftLeg.Color = skeletonColor
                    data.Skeleton.TorsoLeftLeg.Thickness = skeletonThickness
                    data.Skeleton.TorsoLeftLeg.Visible = onScreen
                else
                    data.Skeleton.TorsoLeftLeg.Visible = false
                end

                if bodyParts.RightLowerLeg then
                    local legPos = Camera:WorldToViewportPoint(bodyParts.RightLowerLeg.Position)
                    data.Skeleton.TorsoRightLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoRightLeg.To = Vector2.new(legPos.X, legPos.Y)
                    data.Skeleton.TorsoRightLeg.Color = skeletonColor
                    data.Skeleton.TorsoRightLeg.Thickness = skeletonThickness
                    data.Skeleton.TorsoRightLeg.Visible = onScreen
                else
                    data.Skeleton.TorsoRightLeg.Visible = false
                end
            else
                for _, line in pairs(data.Skeleton) do
                    line.Visible = false
                end
            end
        elseif data.Skeleton then
            for _, line in pairs(data.Skeleton) do
                line.Visible = false
            end
        end

        if flags["ShowTracers"] and data.Tracer then
            data.Tracer.From = tracerFromPos
            data.Tracer.To = Vector2.new(pos.X, pos.Y)
            data.Tracer.Color = (flags["ESPTeamColors"] and color) or ESPSettings.TracerColor
            data.Tracer.Thickness = tracerThickness
            data.Tracer.Visible = onScreen
        elseif data.Tracer then
            data.Tracer.Visible = false
        end
    end
end)

-- Periodic sync of thickness/size (sliders already update on change; this is a backup, run less often to save CPU)
task.spawn(function()
    while true do
        task.wait(ESP_SETTINGS_SYNC_INTERVAL)
        updateAllESPSettings()
    end
end)
