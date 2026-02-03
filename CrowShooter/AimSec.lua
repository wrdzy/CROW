    -- Core Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
-- Player References
local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer and LocalPlayer.GetMouse and LocalPlayer:GetMouse()

if not _G or not _G.Aimlock then
    return
end

if not workspace or not workspace.CurrentCamera then
    return
end
local Camera = workspace.CurrentCamera

-- Drawing Objects
local AimLockFOVCircle          = Drawing.new("Circle")
AimLockFOVCircle.Thickness      = 1
AimLockFOVCircle.NumSides       = 60
AimLockFOVCircle.Position       = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
AimLockFOVCircle.Radius         = 100
AimLockFOVCircle.Color          = Color3.new(0, 0, 1)
AimLockFOVCircle.Transparency   = 1
AimLockFOVCircle.Visible        = false

-- Drawing Objects
local SilentAimFOVCircle          = Drawing.new("Circle")
SilentAimFOVCircle.Thickness      = 2
SilentAimFOVCircle.NumSides       = 60
SilentAimFOVCircle.Position       = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
SilentAimFOVCircle.Radius         = 100
SilentAimFOVCircle.Color          = Color3.new(0, 0, 1)
SilentAimFOVCircle.Transparency   = 1
SilentAimFOVCircle.Visible        = false

local InfoBox            = Drawing.new("Square")
InfoBox.Size             = Vector2.new(200, 60)
InfoBox.Position         = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
InfoBox.Filled           = true
InfoBox.Visible          = false

local InfoBorder         = Drawing.new("Square")
InfoBorder.Size          = Vector2.new(200, 60)
InfoBorder.Position      = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
InfoBorder.Filled        = false
InfoBorder.Thickness      = 2
InfoBorder.Visible       = false

local StatusText         = Drawing.new("Text")
StatusText.Size          = 20
StatusText.Outline       = true
StatusText.Position      = Vector2.new(Camera.ViewportSize.X/2+5, Camera.ViewportSize.Y/2+5)
StatusText.Visible       = false

local HealthText         = Drawing.new("Text")
HealthText.Size          = 20
HealthText.Outline       = true
HealthText.Position      = Vector2.new(Camera.ViewportSize.X/2+5, Camera.ViewportSize.Y/2+30)
HealthText.Visible       = false

local TargetIndicator    = Drawing.new("Circle")
TargetIndicator.Thickness = 2
TargetIndicator.NumSides = 4
TargetIndicator.Radius   = 5
TargetIndicator.Color     = Color3.new(0, 0, 1)
TargetIndicator.Transparency = 1
TargetIndicator.Visible  = false

local SilentTargetIndicator = Drawing.new("Circle")
SilentTargetIndicator.Thickness = 2
SilentTargetIndicator.NumSides = 4
SilentTargetIndicator.Radius = 5
SilentTargetIndicator.Color = Color3.new(1, 0, 0)
SilentTargetIndicator.Transparency = 1
SilentTargetIndicator.Visible = false

-- State Variables
local CurrentTarget      = nil
local CurrentTargetPart  = nil
local AimlockConnection  = nil
local MouseMoveConnection= nil
local LastShotTime       = 0
local AutoShootCooldown  = 0.01

local STICKY_RANGE       = 15
local FOV_OFFSET_Y       = 57
local INDICATOR_OFFSET_Y = 57

-- Body Part Definitions (R6 & R15)
local BodyPartDefinitions = {
    Head  = {"Head"},
    Torso = {"HumanoidRootPart"},
    Legs  = {"Left Leg","LeftUpperLeg"}
}
local TargetPartOptions = {"Head","Torso","Legs"}

-- Utility Functions
local function FixTransparency(value)
    return 1 - value
end

local function HasForceField(character)
    if not character then return false end
    return character:FindFirstChildWhichIsA("ForceField") ~= nil
end

local function IsVisible(player, part)
    if not player or not player.Character or not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local origin = Camera.CFrame.Position
    local dir    = part.Position - origin
    local hit    = workspace:Raycast(origin, dir, params)
    return not (hit and not hit.Instance:IsDescendantOf(player.Character))
end

local function GetBestTargetPart(player, selectedParts)
    if not player or not player.Character then return nil end
    local valid = {}
    local wallCheck = library.flags["WallCheck"]
    for _, partType in ipairs(selectedParts) do
        local names = BodyPartDefinitions[partType]
        if names then
            for _, name in ipairs(names) do
                local part = player.Character:FindFirstChild(name)
                if part and part:IsA("BasePart") then
                    if not wallCheck or IsVisible(player, part) then
                        table.insert(valid, part)
                    end
                end
            end
        end
    end
    
    if #valid == 0 then return nil end
    
    if #selectedParts > 1 then
        local randomIndex = math.random(1, #valid)
        return valid[randomIndex]
    else
        local closest, minDist = nil, math.huge
        local refPoint
        if library.flags["AimMethod"] == "Camera" then
            refPoint = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            refPoint = Vector2.new(Mouse.X, Mouse.Y + FOV_OFFSET_Y)
        end

        for _, part in ipairs(valid) do
            local sp = Camera:WorldToScreenPoint(part.Position)
            if sp.Z > 0 then
                local screenPos = Vector2.new(sp.X, sp.Y)
                local dist = (screenPos - refPoint).Magnitude
                if dist < minDist then
                    closest, minDist = part, dist
                end
            end
        end
        return closest
    end
end

local function ApplyPrediction(part)
    local mode = library.flags["PredictionMode"]
    if mode == "Off" then return part.Position end
    local vel = part.Velocity
    if mode == "Manual" then
        return part.Position + vel * (library.flags["ManualPrediction"] or 0)
    elseif mode == "Auto" then
        local dist = (Camera.CFrame.Position - part.Position).Magnitude
        return part.Position + vel * (dist / 200)
    end
    return part.Position
end

local function CalculateMove(dx, dy)
    local smooth = library.flags["Smoothness"] or 0
    local stickyAim = library.flags["StickyAim"] or false
    
    if stickyAim then
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < STICKY_RANGE then
            local slowFactor = dist / STICKY_RANGE
            dx = dx * (slowFactor * 0.5)
            dy = dy * (slowFactor * 0.5)
        end
    end
    
    dx = dx * (1 - smooth)
    dy = dy * (1 - smooth)
    
    return dx, dy
end

local function UpdateFOVPosition()
    if library.flags["AimMethod"] == "Camera" then
        AimLockFOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        AimLockFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + FOV_OFFSET_Y)
    end
end

local function UpdateInfoUIVisibility()
    if not library.flags["ShowInfoUI"] or not CurrentTarget then
        InfoBox.Visible = false
        InfoBorder.Visible = false
        StatusText.Visible = false
        HealthText.Visible = false
        TargetIndicator.Visible = false
        return
    end

    InfoBox.Visible   = false
    InfoBorder.Visible= false
    StatusText.Visible= false

    StatusText.Text = "Target: " .. CurrentTarget.Name ..
        (CurrentTargetPart and " ("..CurrentTargetPart.Name..")" or "")

    local humanoid = CurrentTarget.Character and CurrentTarget.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        HealthText.Visible = false
        HealthText.Text    = "Health: " .. math.floor(humanoid.Health)
        if library.flags["DynamicHealthColor"] then
            local pct = humanoid.Health / humanoid.MaxHealth
            HealthText.Color = Color3.fromRGB(255*(1-pct),255*pct,0)
        else
            HealthText.Color       = library.flags["HealthTextColor"] or Color3.new(0,1,0)
            HealthText.Transparency= FixTransparency(library.flags["HealthTextTrans"] or 0)
        end
    else
        HealthText.Visible = false
    end
end

local function SetupFOVTracking()
    if MouseMoveConnection then MouseMoveConnection:Disconnect() end
    
    if library.flags["AimMethod"] == "Mouse" then
        MouseMoveConnection = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                AimLockFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + FOV_OFFSET_Y)
            end
        end)
    end
end

local function Cleanup()
    if AimlockConnection then AimlockConnection:Disconnect() end
    if MouseMoveConnection then MouseMoveConnection:Disconnect() end
    AimlockConnection, MouseMoveConnection = nil, nil
end

local function UpdateTargetIndicator(target, targetPart)
    local crow = _G.CROW
    if not crow then return end
    local setVal = function(obj, val)
        if obj and obj.SetValue then obj:SetValue(tostring(val)) end
    end
    if not target or not target.Character then
        setVal(crow.targetName, 'nil')
        setVal(crow.targetDisplay, 'nil')
        setVal(crow.targetHealth, '0')
        setVal(crow.targetDistance, '0m')
        setVal(crow.targetTool, 'nil')
        setVal(crow.targetTarget, 'nil')
        return
    end
    setVal(crow.targetName, target.Name)
    setVal(crow.targetDisplay, target.DisplayName or target.Name)
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        setVal(crow.targetHealth, math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth))
    else
        setVal(crow.targetHealth, '0/0')
    end
    local localCharacter = LocalPlayer.Character
    if localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (localCharacter.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
        setVal(crow.targetDistance, math.floor(distance) .. 'm')
    else
        setVal(crow.targetDistance, '0m')
    end
    local tool = target.Character:FindFirstChildOfClass("Tool")
    setVal(crow.targetTool, tool and tool.Name or 'nil')
    setVal(crow.targetTarget, targetPart and targetPart.Name or 'nil')
end

local lastAimlockUpdate = 0
local AIMLOCK_UPDATE_INTERVAL = 1/60 -- 60 Hz for target search + heavy logic

local function StartAimlock()
    Cleanup()
    UpdateFOVPosition()
    SetupFOVTracking()
    math.randomseed(tick())

    AimlockConnection = RunService.RenderStepped:Connect(function()
        local flags = library and library.flags
        if not flags then return end
        if not flags["AimlockEnabled"] then
            InfoBox.Visible = false
            InfoBorder.Visible = false
            StatusText.Visible = false
            HealthText.Visible = false
            TargetIndicator.Visible = false
            UpdateTargetIndicator(nil, nil)
            return
        end

        local teamCheck       = flags["TeamCheck"]
        local wallCheck       = flags["WallCheck"]
        local forceFieldCheck = flags["ForceFieldCheck"]
        local aimMethod       = flags["AimMethod"]
        local partsList       = flags["TargetParts"] or {"Head"}
        local fovSize         = flags["FOVSize"] or 100
        local fovThickness   = flags["FOVThickness"] or 1
        local autoShoot       = flags["AutoShoot"] or false
        local shootCooldown   = flags["AutoShootCooldown"] or 0.01

        AimLockFOVCircle.Radius    = fovSize
        AimLockFOVCircle.Thickness = math.max(1, tonumber(fovThickness) or 1)
        AimLockFOVCircle.Visible   = true

        local now = tick()
        local runHeavy = (now - lastAimlockUpdate) >= AIMLOCK_UPDATE_INTERVAL
        if runHeavy then lastAimlockUpdate = now end

        if runHeavy and CurrentTarget then
            local char     = CurrentTarget.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0
            or (forceFieldCheck and HasForceField(char))
            or (wallCheck and CurrentTargetPart and not IsVisible(CurrentTarget, CurrentTargetPart)) then
                CurrentTarget, CurrentTargetPart = nil, nil
                UpdateInfoUIVisibility()
                TargetIndicator.Visible = false
                UpdateTargetIndicator(nil, nil)
            end
        end

        if runHeavy and not CurrentTarget then
            local closest = fovSize
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char     = player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then continue end
                if teamCheck then
                    local isEnemyFn = _G.CROW_IsEnemy
                    local enemy = (isEnemyFn and isEnemyFn(player)) or (player.Team ~= LocalPlayer.Team or not LocalPlayer.Team)
                    if not enemy then continue end
                end
                if forceFieldCheck and HasForceField(char) then continue end

                local part = GetBestTargetPart(player, partsList)
                if not part then continue end
                if wallCheck and not IsVisible(player, part) then continue end

                local sp = Camera:WorldToScreenPoint(part.Position)
                if sp.Z <= 0 then continue end

                local screenPos = Vector2.new(sp.X, sp.Y)
                local center
                if aimMethod == "Camera" then
                    center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                else
                    center = Vector2.new(Mouse.X, Mouse.Y + FOV_OFFSET_Y)
                end
                local dist = (screenPos - center).Magnitude

                if dist < closest then
                    CurrentTarget, CurrentTargetPart = player, part
                    closest = dist
                end
            end
            if runHeavy then
                UpdateInfoUIVisibility()
                UpdateTargetIndicator(CurrentTarget, CurrentTargetPart)
            end
        end

        if CurrentTarget and CurrentTargetPart then
            if runHeavy then
                UpdateInfoUIVisibility()
                UpdateTargetIndicator(CurrentTarget, CurrentTargetPart)
            end
            
            local targetPos = ApplyPrediction(CurrentTargetPart)

            if aimMethod == "Camera" then
                local goal = CFrame.new(Camera.CFrame.Position, targetPos)
                local smooth = flags["SmoothnessCamera"] or flags["Smoothness"] or 0
                Camera.CFrame = Camera.CFrame:Lerp(goal, 1 - smooth)
            else
                local sp = Camera:WorldToScreenPoint(targetPos)
                if sp.Z > 0 then
                    local dx, dy = sp.X - Mouse.X, sp.Y - Mouse.Y
                    local mx, my = CalculateMove(dx, dy)
                    if mx ~= 0 or my ~= 0 then
                        mousemoverel(mx, my)
                    end
                end
            end

            local sp2 = Camera:WorldToScreenPoint(targetPos)
            if sp2.Z > 0 then
                TargetIndicator.Position = Vector2.new(sp2.X, sp2.Y + INDICATOR_OFFSET_Y)
                TargetIndicator.Visible = true
                
                if autoShoot and tick() - LastShotTime >= shootCooldown then
                    LastShotTime = tick()
                    mouse1press()
                    task.defer(mouse1release)
                end
            else
                TargetIndicator.Visible = false
            end
        end
    end)
end

local function StopAimlock()
    Cleanup()
    AimLockFOVCircle.Visible = false
    InfoBox.Visible = false
    InfoBorder.Visible = false
    StatusText.Visible = false
    HealthText.Visible = false
    TargetIndicator.Visible = false
    CurrentTarget, CurrentTargetPart = nil, nil
    UpdateTargetIndicator(nil, nil)
end

-- UI Section
local secaim = _G.Aimlock:AddSection("Aim Lock", 1)

secaim:AddSeparator({ text = "Main" })

local aimlockToggle = secaim:AddToggle({
    text    = "Aim Lock",
    state   = false,
    flag    = "AimlockEnabled",
    tooltip = "Enable or disable aim lock",
    callback= function(on)
        if on then StartAimlock() else StopAimlock() end
    end
})
aimlockToggle:AddBind({
    text     = "Aim Lock Key",
    mode     = "toggle",
    bind     = "NONE",
    flag     = "ToggleKey_1",
    callback = function(on)
        if not library or not library.flags then return end
        library.flags["AimlockEnabled"] = on
        if on then StartAimlock() else StopAimlock() end
        pcall(function()
            local t = library.options and library.options["AimlockEnabled"]
            if t and type(t.SetState) == "function" then
                t:SetState(on, true)
            end
        end)
    end
})

-- Autoshoot Toggle
secaim:AddToggle({
    text    = "Auto Shoot",
    state   = false,
    flag    = "AutoShoot",
    tooltip = "Automatically shoot when targeting",
    callback= function(on)
        if not on then
            mouse1release()
        end
    end
})

secaim:AddToggle({
    text    = "Team Check",
    state   = false,
    flag    = "TeamCheck",
    tooltip = "Don't target allies (respects Roblox team or ESP enemy list)",
    callback= function() CurrentTarget, CurrentTargetPart = nil, nil end
})

secaim:AddToggle({
    text    = "Wall Check",
    state   = false,
    flag    = "WallCheck",
    tooltip = "Don't target through walls",
    callback= function() CurrentTarget, CurrentTargetPart = nil, nil end
})

secaim:AddToggle({
    text    = "ForceField Check",
    state   = false,
    flag    = "ForceFieldCheck",
    tooltip = "Don't target invulnerable players",
    callback= function() CurrentTarget, CurrentTargetPart = nil, nil end
})

secaim:AddToggle({
    text    = "Sticky Aim",
    state   = false,
    flag    = "StickyAim",
    tooltip = "Makes your aim stick to targets"
})

secaim:AddList({
    text     = "Aim Lock Method",
    selected = "Camera",
    values   = {"Camera","Mouse"},
    flag     = "AimMethod",
    tooltip  = "Choose aim method",
    callback = function()
        UpdateFOVPosition()
        SetupFOVTracking()
        CurrentTarget, CurrentTargetPart = nil, nil
    end
})

secaim:AddList({
    text     = "Target Body Parts",
    selected = {"Head"},
    multi    = true,
    values   = TargetPartOptions,
    flag     = "TargetParts",
    tooltip  = "Which body parts to aim at",
    callback = function() CurrentTarget, CurrentTargetPart = nil, nil end
})

secaim:AddSeparator({ text = "Settings" })

secaim:AddSlider({
    text      = "Mouse Smoothness",
    min       = 0,
    max       = 1.0,
    increment = 0.05,
    default   = 0.1,
    flag      = "Smoothness",
    tooltip   = "Higher = smoother (mouse aim only)"
})
secaim:AddSlider({
    text      = "Camera Smoothness",
    min       = 0,
    max       = 1.0,
    increment = 0.05,
    default   = 0.25,
    flag      = "SmoothnessCamera",
    tooltip   = "Higher = smoother camera aimlock"
})

secaim:AddSlider({
    text      = "FOV Size",
    min       = 50,
    max       = 500,
    increment = 1,
    default   = 50,
    suffix    = "px",
    flag      = "FOVSize",
    tooltip   = "Aim FOV radius",
    callback  = function(v)
        AimLockFOVCircle.Radius = v
        CurrentTarget, CurrentTargetPart = nil, nil
    end
})

secaim:AddSlider({
    text      = "FOV Thickness",
    min       = 1,
    max       = 10,
    increment = 1,
    default   = 1,
    suffix    = "px",
    flag      = "FOVThickness",
    tooltip   = "Aim FOV circle line thickness",
    callback  = function(v)
        AimLockFOVCircle.Thickness = math.max(1, v or 1)
    end
})

-- Added Auto Shoot Cooldown slider for Aim Lock
secaim:AddSlider({
    text      = "Auto Shoot Cooldown",
    min       = 0.01,
    max       = 1.0,
    increment = 0.01,
    default   = 0.01,
    suffix    = "s",
    flag      = "AutoShootCooldown",
    tooltip   = "Time between auto shots"
})

secaim:AddSeparator({ text = "Prediction" })

secaim:AddList({
    text     = "Prediction Mode",
    selected = "Off",
    values   = {"Off","Manual","Auto"},
    flag     = "PredictionMode",
    tooltip  = "Aim prediction"
})

secaim:AddSlider({
    text      = "Manual Prediction",
    min       = 0.1,
    max       = 0.5,
    increment = 0.01,
    default   = 0.1,
    flag      = "ManualPrediction",
    tooltip   = "Manual prediction strength"
})

local secedit = _G.Aimlock:AddSection("Aim Lock Visuals", 1)

secedit:AddSeparator({ text = "Colors" })
secedit:AddColor({
    text     = "FOV Circle Color",
    color    = Color3.new(0, 0, 1),
    trans    = 0,
    flag     = "FOVColor",
    tooltip  = "Circle color/transparency",
    callback = function(c,t)
        AimLockFOVCircle.Color        = c
        AimLockFOVCircle.Transparency = FixTransparency(t)
    end
})
secedit:AddColor({
    text     = "Indicator Color",
    color    = Color3.new(0, 0, 1),
    trans    = 0,
    flag     = "IndicatorColor",
    tooltip  = "Indicator color/transparency",
    callback = function(c,t)
        TargetIndicator.Color        = c
        TargetIndicator.Transparency = FixTransparency(t)
    end
})

-- ===================== SILENT AIM SECTION =====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GetMouseLocation = (UserInputService and UserInputService.GetMouseLocation) or function() return Vector2.new(0, 0) end

local resume = coroutine.resume 
local create = coroutine.create

-- Use bypass-backed APIs (single table, less obvious to AC)
local bypass = _G and _G.CROW_bypass
local hookmetamethod = (bypass and bypass.hookmetamethod) or hookmetamethod
local hookfunction = (bypass and bypass.hookfunction) or hookfunction
local newcclosure = (bypass and bypass.newcclosure) or newcclosure
local getnamecallmethod = (bypass and bypass.getnamecallmethod) or getnamecallmethod
local checkcaller = (bypass and bypass.checkcaller) or checkcaller
local getrawmetatable = (bypass and bypass.getrawmetatable) or getrawmetatable
local setreadonly = (bypass and bypass.setreadonly) or setreadonly

-- Performance optimization: Cache mouse position (use raw/original GetMouseLocation so FOV circle and getClosestPlayer use real mouse, not hooked)
local CachedMousePosition = Vector2.new(0, 0)
local LastMouseUpdate = 0
local MOUSE_UPDATE_INTERVAL = 0.00833
local rawGetMouseLocation = GetMouseLocation -- real mouse before any hook; never hook at load so AC doesn't detect

-- Performance optimization: Cache closest player
local CachedClosestPlayer = nil
local LastPlayerUpdate = 0
local PLAYER_UPDATE_INTERVAL = 0.00833 -- ~120 FPS

-- Drawing Objects
local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 130
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(255, 0, 0)

-- Expected Arguments (exact from Universal Silent Aim - Averiias, Stefanuk12, xaxa)
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

-- Map CROW UI (SilentTargetParts) to Universal TargetPart: "Head", "HumanoidRootPart", or "Random"
local function getTargetPartValue()
    local tp = library and library.flags and library.flags["SilentTargetParts"]
    if not tp or not tp[1] then return "HumanoidRootPart" end
    if tp[1] == "Random" then return "Random" end
    if tp[1] == "Head" then return "Head" end
    if tp[1] == "Torso" then return "HumanoidRootPart" end
    return "HumanoidRootPart"
end

-- Utility Functions
function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

-- Exact from Universal Silent Aim
local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

-- Exact from Universal Silent Aim (Options.TargetPart.Value -> getTargetPartValue())
local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, getTargetPartValue()) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

-- Exact from Universal Silent Aim (Toggles/Options -> library.flags)
local function getClosestPlayer()
    local TargetPart = getTargetPartValue()
    if not TargetPart then return end
    local Closest
    local DistanceToMouse
    local Radius = (library and library.flags and library.flags["SilentFOVSize"]) or 130
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if (library and library.flags and library.flags["SilentTeamCheck"]) and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if (library and library.flags and library.flags["SilentVisibleCheck"]) and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Radius or 2000) then
            Closest = ((TargetPart == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[TargetPart])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

-- Function to update FOV visibility
local function updateFOVVisibility()
    if not library or not library.flags then
        if fov_circle then fov_circle.Visible = false end
        return
    end
    local isActive = library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
    if fov_circle then fov_circle.Visible = isActive end
end

-- Forward declare so toggle callback (created below) always has a non-nil reference
local applyAllSilentAimHooks

-- Apply workspace hooks at load so silent aim works; each hook in pcall so one failure doesn't block others
local oldRaycast, oldFindPartOnRayWithIgnoreList, oldFindPartOnRayWithWhitelist, oldFindPartOnRay, oldRaycastWithIgnoreList
local workspaceHooksApplied = false
function applyWorkspaceHooks()
    if workspaceHooksApplied then return end
    workspaceHooksApplied = true
    if not hookfunction or type(hookfunction) ~= "function" then return end
    pcall(function()
        local orig = workspace.Raycast
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, origin, direction, raycastParams)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "Raycast" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart then direction = getDirection(origin, HitPart.Position) end
                    end
                end)
                return (oldRaycast or orig)(self, origin, direction, raycastParams)
            end)
            if type(hooked) == "function" then oldRaycast = hooked end
        end
    end)
    pcall(function()
        local orig = workspace.FindPartOnRayWithIgnoreList
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, ray, ...)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "FindPartOnRayWithIgnoreList" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart and ray and ray.Origin then ray = Ray.new(ray.Origin, getDirection(ray.Origin, HitPart.Position)) end
                    end
                end)
                return (oldFindPartOnRayWithIgnoreList or orig)(self, ray, ...)
            end)
            if type(hooked) == "function" then oldFindPartOnRayWithIgnoreList = hooked end
        end
    end)
    pcall(function()
        local orig = workspace.FindPartOnRayWithWhitelist
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, ray, ...)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "FindPartOnRayWithWhitelist" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart and ray and ray.Origin then ray = Ray.new(ray.Origin, getDirection(ray.Origin, HitPart.Position)) end
                    end
                end)
                return (oldFindPartOnRayWithWhitelist or orig)(self, ray, ...)
            end)
            if type(hooked) == "function" then oldFindPartOnRayWithWhitelist = hooked end
        end
    end)
    pcall(function()
        local orig = workspace.FindPartOnRay
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, ray, ...)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "FindPartOnRay" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart and ray and ray.Origin then ray = Ray.new(ray.Origin, getDirection(ray.Origin, HitPart.Position)) end
                    end
                end)
                return (oldFindPartOnRay or orig)(self, ray, ...)
            end)
            if type(hooked) == "function" then oldFindPartOnRay = hooked end
        end
    end)
    -- RaycastWithIgnoreList (deprecated API still used by some games)
    pcall(function()
        local orig = workspace.RaycastWithIgnoreList
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, origin, direction, ignoreList)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "RaycastWithIgnoreList" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart then direction = getDirection(origin, HitPart.Position) end
                    end
                end)
                return (oldRaycastWithIgnoreList or orig)(self, origin, direction, ignoreList)
            end)
            if type(hooked) == "function" then oldRaycastWithIgnoreList = hooked end
        end
    end)
end

-- Many games get the shot ray via Camera:ScreenPointToRay(mouse.X, mouse.Y) then Raycast. Hook at source so ray is bent.
local oldScreenPointToRay, oldViewportPointToRay
local cameraHooksApplied = false
function applyCameraHooks()
    if cameraHooksApplied then return end
    cameraHooksApplied = true
    if not hookfunction or type(hookfunction) ~= "function" then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    pcall(function()
        local orig = cam.ScreenPointToRay
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, x, y)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "ScreenPointToRay" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local origin = (self and self.CFrame and self.CFrame.Position) or Camera.CFrame.Position
                            local dir = getDirection(origin, HitPart.Position)
                            return Ray.new(origin, dir)
                        end
                    end
                end)
                return (oldScreenPointToRay or orig)(self, x, y)
            end)
            if type(hooked) == "function" then oldScreenPointToRay = hooked end
        end
    end)
    pcall(function()
        local orig = cam.ViewportPointToRay
        if type(orig) == "function" then
            local hooked = hookfunction(orig, function(self, x, y)
                pcall(function()
                    local silentAimActive = library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
                    local silentMethod = library and library.flags and library.flags["SilentMethod"]
                    if silentAimActive and (silentMethod == "ViewportPointToRay" or silentMethod == "ScreenPointToRay" or silentMethod == "All Methods") and CalculateChance(library.flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local origin = (self and self.CFrame and self.CFrame.Position) or Camera.CFrame.Position
                            local dir = getDirection(origin, HitPart.Position)
                            return Ray.new(origin, dir)
                        end
                    end
                end)
                return (oldViewportPointToRay or orig)(self, x, y)
            end)
            if type(hooked) == "function" then oldViewportPointToRay = hooked end
        end
    end)
end

-- ===================== SILENT AIM UI SECTION =====================
local SilentAimSection = _G.Aimlock:AddSection("Silent Aim", 2)

SilentAimSection:AddSeparator({ text = "Main" })

local silentAimToggle = SilentAimSection:AddToggle({
    text = "Silent Aim",
    state = false,
    flag = "SilentAimEnabled",
    tooltip = "Enable or disable silent aim",
    callback = function(state)
        pcall(function()
            local lib = library
            if not lib or not lib.flags then return end
            lib.flags["SilentAimEnabled"] = state
            lib.flags["SilentAimActive"] = state
            CachedClosestPlayer = nil
            updateFOVVisibility()
            if state and type(applyAllSilentAimHooks) == "function" then applyAllSilentAimHooks() end
        end)
    end
})
silentAimToggle:AddBind({
    text = "Silent Aim Key",
    mode = "toggle",
    bind = "NONE",
    flag = "SilentAimToggleKey",
    tooltip = "Toggle Silent Aim on/off (syncs with toggle above)",
    callback = function(state)
        pcall(function()
            local lib = library
            if not lib or not lib.flags then return end
            lib.flags["SilentAimEnabled"] = state
            lib.flags["SilentAimActive"] = state
            CachedClosestPlayer = nil
            updateFOVVisibility()
            if state and type(applyAllSilentAimHooks) == "function" then applyAllSilentAimHooks() end
            if silentAimToggle and type(silentAimToggle.SetState) == "function" then
                silentAimToggle.SetState(silentAimToggle, state, true)
            end
        end)
    end
})

SilentAimSection:AddToggle({
    text = "Auto Shoot",
    state = false,
    flag = "SilentAutoShoot",
    tooltip = "Automatically shoot when targeting with silent aim"
})

SilentAimSection:AddToggle({
    text = "Team Check",
    state = false,
    flag = "SilentTeamCheck",
    tooltip = "Don't target allies (respects Roblox team or ESP enemy list)",
    callback = function()
        CachedClosestPlayer = nil -- Clear cache when settings change
    end
})

SilentAimSection:AddToggle({
    text = "Wall Check",
    state = false,
    flag = "SilentVisibleCheck",
    tooltip = "Don't target through walls (line of sight only)",
    callback = function()
        CachedClosestPlayer = nil -- Clear cache when settings change
    end
})

SilentAimSection:AddToggle({
    text = "ForceField Check",
    state = false,
    flag = "SilentForceFieldCheck",
    tooltip = "Don't target players with ForceField (invulnerable)",
    callback = function()
        CachedClosestPlayer = nil
    end
})

SilentAimSection:AddList({
    text = "Target Body Parts",
    selected = "Torso",
    multi = true,
    values = {"Head", "Torso", "Legs", "Random"},
    flag = "SilentTargetParts",
    callback = function()
        CachedClosestPlayer = nil
    end
})

-- All Methods = try every hooked ray method (best compatibility).
-- Namecall (Universal) = single __namecall hook catches any Ray method the game uses.
SilentAimSection:AddList({
    text = "Silent Aim Method",
    selected = "Raycast",
    tooltip = "Which ray method to use. Raycast = Universal default. Mouse.Hit/Target for games that read Mouse.Target or Mouse.Hit.",
    values = {
        "All Methods",
        "Namecall (Universal)",
        "Mouse.Hit/Target",
        "ScreenPointToRay",
        "ViewportPointToRay",
        "Raycast",
        "RaycastWithIgnoreList",
        "FindPartOnRayWithIgnoreList",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRay",
        "GetMouseLocation"
    },
    flag = "SilentMethod"
})

SilentAimSection:AddSeparator({ text = "Settings" })

SilentAimSection:AddSlider({
    text = "Hit Chance",
    min = 1,
    max = 100,
    increment = 1,
    default = 100,
    suffix = "%",
    flag = "SilentHitChance"
})

SilentAimSection:AddSlider({
    text = "FOV Size",
    min = 50,
    max = 500,
    increment = 1,
    default = 130,
    suffix = "px",
    flag = "SilentFOVSize",
    callback = function(value)
        fov_circle.Radius = value
        CachedClosestPlayer = nil -- Clear cache when FOV changes
    end
})

SilentAimSection:AddSlider({
    text = "Auto Shoot Cooldown",
    min = 0.01,
    max = 1.0,
    increment = 0.01,
    default = 0.05,
    suffix = "s",
    flag = "SilentAutoShootCooldown"
})


SilentAimSection:AddSeparator({ text = "Prediction" })

SilentAimSection:AddList({
    text = "Prediction Mode",
    selected = "Off",
    values = {"Off", "Manual"},
    flag = "SilentPredictionMode"
})

SilentAimSection:AddSlider({
    text = "Manual Prediction",
    min = 0.01,
    max = 1,
    increment = 0.005,
    default = 0.165,
    flag = "SilentManualPrediction"
})

-- Silent Aim Visuals Section (same structure as Aim Lock Visuals: Colors only)
local SilentVisualsSection = _G.Aimlock:AddSection("Silent Aim Visuals", 2)

SilentVisualsSection:AddSeparator({ text = "Colors" })

SilentVisualsSection:AddColor({
    text = "FOV Circle Color",
    color = Color3.fromRGB(255, 0, 0),
    trans = 0,
    flag = "SilentFOVColor",
    callback = function(color, trans)
        fov_circle.Color = color
        fov_circle.Transparency = 1 - trans
    end
})

SilentVisualsSection:AddColor({
    text = "Target Indicator Color",
    color = Color3.new(1, 0, 0),
    trans = 0,
    flag = "SilentIndicatorColor",
    callback = function(color, trans)
        SilentTargetIndicator.Color = color
        SilentTargetIndicator.Transparency = 1 - trans
    end
})

-- Auto Shoot Variables
local LastSilentShotTime = 0

-- Optimized Render Loop with reduced frequency
local lastRenderTime = 0
local RENDER_INTERVAL = 0.00833 -- ~120 FPS cap

resume(create(function()
    RenderStepped:Connect(function()
        pcall(function()
            if not library or not library.flags or not Camera then return end
            local currentTime = tick()
            local silentAimActive = library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false)
            
            if silentAimActive then
                if fov_circle then
                    fov_circle.Visible = true
                    local fovSize = library.flags["SilentFOVSize"]
                    if type(fovSize) == "number" then fov_circle.Radius = fovSize end
                    local fn = rawGetMouseLocation or (UserInputService and UserInputService.GetMouseLocation)
                    if type(fn) == "function" then
                        local ok, pos = pcall(fn, UserInputService)
                        if ok and pos then fov_circle.Position = pos end
                    end
                end
            else
                if fov_circle then fov_circle.Visible = false end
            end
            
            if currentTime - lastRenderTime < RENDER_INTERVAL then return end
            lastRenderTime = currentTime
            
            if silentAimActive then
                local target = getClosestPlayer()
                if target and target.Parent then
                    local Root = target.Parent.PrimaryPart or target.Parent:FindFirstChild("HumanoidRootPart") or target
                    if Root and Root.Position then
                        local ok, RootToViewportPoint, IsOnScreen = pcall(WorldToViewportPoint, Camera, Root.Position)
                        if ok and RootToViewportPoint then
                            SilentTargetIndicator.Visible = IsOnScreen
                            SilentTargetIndicator.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
                        end
                    end
                    if library.flags["SilentAutoShoot"] then
                        local cooldown = library.flags["SilentAutoShootCooldown"] or 0.01
                        if currentTime - LastSilentShotTime >= cooldown then
                            LastSilentShotTime = currentTime
                            if mouse1press then pcall(mouse1press) end
                            if mouse1release then task.defer(pcall, mouse1release) end
                        end
                    end
                else
                    if SilentTargetIndicator then SilentTargetIndicator.Visible = false end
                end
            else
                if SilentTargetIndicator then SilentTargetIndicator.Visible = false end
            end
        end)
    end)
end))

-- No hooks at load: anti-cheat detects hooked Raycast/GetMouseLocation/__namecall. Apply hooks only when user enables Silent Aim.
-- No __index / GetMouse / __newindex: avoids indexInstance detector (Error 267).

local getMouseLocationHookApplied = false
local oldGetMouseLocation = GetMouseLocation
local function applyGetMouseLocationHooks()
    if getMouseLocationHookApplied then return end
    if not hookfunction or not UserInputService or not UserInputService.GetMouseLocation then return end
    getMouseLocationHookApplied = true
    pcall(function()
        local hooked = hookfunction(UserInputService.GetMouseLocation, function(...)
            local ok, result = pcall(function()
                local flags = library and library.flags
                if not flags or not Camera then return nil end
                local enabled = flags["SilentAimEnabled"]
                local active = flags["SilentAimActive"] ~= false
                local method = flags["SilentMethod"]
                if enabled and active and (method == "GetMouseLocation" or method == "All Methods") then
                    if CalculateChance(flags["SilentHitChance"] or 100) then
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local Vec3, OnScreen = WorldToViewportPoint(Camera, HitPart.Position)
                            if OnScreen and Vec3 then
                                return Vector2.new(Vec3.X, Vec3.Y)
                            end
                        end
                    end
                end
                return nil
            end)
            if ok and result then return result end
            return oldGetMouseLocation(...)
        end)
        if type(hooked) == "function" then oldGetMouseLocation = hooked end
    end)
end

-- Mouse.Hit/Target hook: when game reads Mouse.Target or Mouse.Hit, return silent aim target (logic from Universal Silent Aim - Averiias/Stefanuk12)
local mouseHitTargetHookApplied = false
local oldMouseIndex = nil
local function applyMouseHitTargetHook()
    if mouseHitTargetHookApplied then return end
    if not Mouse or not getrawmetatable or not hookmetamethod or not checkcaller then return end
    mouseHitTargetHookApplied = true
    pcall(function()
        local mt = getrawmetatable(Mouse)
        if not mt or type(mt) ~= "table" then return end
        oldMouseIndex = mt.__index
        if type(oldMouseIndex) ~= "function" and type(oldMouseIndex) ~= "table" then return end
        local function indexHook(self, Index)
            if checkcaller and checkcaller() then
                if type(oldMouseIndex) == "function" then return oldMouseIndex(self, Index) end
                if type(oldMouseIndex) == "table" and oldMouseIndex[Index] ~= nil then return oldMouseIndex[Index] end
                return nil
            end
            local flags = library and library.flags
            if flags and flags["SilentAimEnabled"] and (flags["SilentAimActive"] ~= false) and (flags["SilentMethod"] == "Mouse.Hit/Target" or flags["SilentMethod"] == "All Methods") and getClosestPlayer() then
                local HitPart = getClosestPlayer()
                if Index == "Target" or Index == "target" then
                    return HitPart
                elseif Index == "Hit" or Index == "hit" then
                    local Prediction = (flags["SilentPredictionMode"] == "Manual")
                    local Amount = (flags["SilentManualPrediction"]) or PredictionAmount
                    return ((Prediction and (HitPart.CFrame + (HitPart.Velocity * Amount))) or (not Prediction and HitPart.CFrame))
                elseif Index == "X" or Index == "x" then
                    return oldMouseIndex(self, Index)
                elseif Index == "Y" or Index == "y" then
                    return oldMouseIndex(self, Index)
                elseif Index == "UnitRay" then
                    return oldMouseIndex(self, Index)
                end
            end
            if type(oldMouseIndex) == "function" then return oldMouseIndex(self, Index) end
            if type(oldMouseIndex) == "table" and oldMouseIndex[Index] ~= nil then return oldMouseIndex[Index] end
            return nil
        end
        if setreadonly then pcall(function() setreadonly(mt, false) end) end
        mt.__index = newcclosure and newcclosure(indexHook) or indexHook
        if setreadonly then pcall(function() setreadonly(mt, true) end) end
    end)
end

-- __namecall hook (Universal Silent Aim - workspace only, ValidateArguments)
local namecallHooksApplied = false
local function applyNamecallHooks()
    if namecallHooksApplied then return end
    if not getrawmetatable or type(getrawmetatable) ~= "function" then return end
    if not getnamecallmethod or type(getnamecallmethod) ~= "function" then return end
    if not hookmetamethod or type(hookmetamethod) ~= "function" then return end
    namecallHooksApplied = true
    pcall(function()
        local mt = getrawmetatable(game) or (workspace and getrawmetatable(workspace))
        if not mt or type(mt) ~= "table" then return end
        local oldNamecall = mt.__namecall
        if type(oldNamecall) ~= "function" then return end
        if setreadonly then pcall(function() setreadonly(mt, false) end) end
        local function namecallHook(self, ...)
            local Method = getnamecallmethod and getnamecallmethod()
            local Arguments = {...}
            local chance = CalculateChance(library and library.flags and library.flags["SilentHitChance"] or 100)
            if library and library.flags and library.flags["SilentAimEnabled"] and (library.flags["SilentAimActive"] ~= false) and self == workspace and checkcaller and not checkcaller() and chance then
                local silentMethod = library.flags["SilentMethod"]
                if Method == "FindPartOnRayWithIgnoreList" and (silentMethod == Method or silentMethod == "Namecall (Universal)" or silentMethod == "All Methods") then
                    if ValidateArguments({self, table.unpack(Arguments)}, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                        local A_Ray = Arguments[1]
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local Origin = A_Ray.Origin
                            local Direction = getDirection(Origin, HitPart.Position)
                            Arguments[1] = Ray.new(Origin, Direction)
                            return oldNamecall(self, table.unpack(Arguments))
                        end
                    end
                elseif Method == "FindPartOnRayWithWhitelist" and (silentMethod == Method or silentMethod == "Namecall (Universal)" or silentMethod == "All Methods") then
                    if ValidateArguments({self, table.unpack(Arguments)}, ExpectedArguments.FindPartOnRayWithWhitelist) then
                        local A_Ray = Arguments[1]
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local Origin = A_Ray.Origin
                            local Direction = getDirection(Origin, HitPart.Position)
                            Arguments[1] = Ray.new(Origin, Direction)
                            return oldNamecall(self, table.unpack(Arguments))
                        end
                    end
                elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and silentMethod and (silentMethod == Method or silentMethod:lower() == Method:lower() or silentMethod == "Namecall (Universal)" or silentMethod == "All Methods") then
                    if ValidateArguments({self, table.unpack(Arguments)}, ExpectedArguments.FindPartOnRay) then
                        local A_Ray = Arguments[1]
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local Origin = A_Ray.Origin
                            local Direction = getDirection(Origin, HitPart.Position)
                            Arguments[1] = Ray.new(Origin, Direction)
                            return oldNamecall(self, table.unpack(Arguments))
                        end
                    end
                elseif Method == "Raycast" and (silentMethod == Method or silentMethod == "Namecall (Universal)" or silentMethod == "All Methods") then
                    if ValidateArguments({self, table.unpack(Arguments)}, ExpectedArguments.Raycast) then
                        local A_Origin = Arguments[1]
                        local HitPart = getClosestPlayer()
                        if HitPart then
                            Arguments[2] = getDirection(A_Origin, HitPart.Position)
                            return oldNamecall(self, table.unpack(Arguments))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end
        mt.__namecall = newcclosure and newcclosure(namecallHook) or namecallHook
        if setreadonly then pcall(function() setreadonly(mt, true) end) end
    end)
end

-- Single entry point: apply silent aim hooks when user enables (Universal: __namecall + Mouse __index only)
applyAllSilentAimHooks = function()
    pcall(applyMouseHitTargetHook)
    pcall(applyNamecallHooks)
end

-- No __newindex hook: avoids indexInstance detector (Error 267).
