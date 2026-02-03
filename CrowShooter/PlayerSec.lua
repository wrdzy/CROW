-- Configuration Table
local Config = {
    -- Movement settings
    minWalkSpeed = 0,
    maxWalkSpeed = 150,
    walkSpeedIncrement = 1,
    defaultJumpPower = 50,
    defaultJumpHeight = 7.2,
    jumpPowerMaxMultiplier = 3,
    jumpHeightMaxMultiplier = 2,
    jumpPowerIncrement = 1,
    jumpHeightIncrement = 0.5,
    
    -- FOV settings
    maxFOV = 120,
    fovIncrement = 1,
    
    -- Fly settings (dynamic; override in loader if needed)
    flySpeedMin = 20,
    flySpeedMax = 200,
    flySpeedIncrement = 10,
    defaultFlySpeed = 50,
    
    -- Update intervals
    propertyUpdateInterval = 1/30, -- 30 FPS for property updates
    partsCacheInterval = 0.5, -- Cache refresh interval
    rainbowUpdateInterval = 1/60, -- Rainbow effect update rate
    

    
    -- Character customization settings
    characterEffects = {
        rainbowSpeedMin = 0.1,
        rainbowSpeedMax = 5,
        rainbowSpeedDefault = 1,
        rainbowSpeedIncrement = 0.1,
        transparencyMin = 0,
        transparencyMax = 0.95,
        transparencyDefault = 0.5,
        transparencyIncrement = 0.05,
        glowIntensityMin = 0.1,
        glowIntensityMax = 3,
        glowIntensityDefault = 1,
        glowIntensityIncrement = 0.1,
        outlineThicknessMin = 0.05,
        outlineThicknessMax = 0.5,
        outlineThicknessDefault = 0.1,
        outlineThicknessIncrement = 0.05,
        defaultCustomColor = Color3.fromRGB(255, 255, 255),
        defaultGlowColor = Color3.fromRGB(255, 255, 255),
        defaultOutlineColor = Color3.fromRGB(0, 0, 0),
        defaultMaterial = "ForceField",
        glowRange = 10,
        outlineTransparency = 0.2
    },
    
    -- Available materials for character customization
    materials = {
        "ForceField", "Neon", "Glass", "Plastic", "Wood", "Slate", "Concrete",
        "CorrodedMetal", "DiamondPlate", "Foil", "Grass", "Ice", "Marble",
        "Granite", "Brick", "Pebble", "Sand", "Fabric", "SmoothPlastic",
        "Metal", "WoodPlanks", "Cobblestone", "Asphalt", "LeafyGrass",
        "Rock", "Cardboard", "Pavement"
    }
}

-- Player Section
local secplayer = _G.PlayerTab:AddSection("Player", 1)
secplayer:AddSeparator({ text = "Player" })

-- Service References
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Player References (do not block on character - UI loads immediately)
local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChild("Humanoid") or (character and character:WaitForChild("Humanoid", 2)) or nil
local camera = workspace.CurrentCamera

-- Validation checks
if not player then
    warn("LocalPlayer not found")
    return
end

if not camera then
    warn("Camera not found")
    return
end

-- Configuration values - from character when present, else defaults (Player tab still loads)
local speedValue, fovValue, originalFov
if humanoid then
    speedValue = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or Config.maxWalkSpeed / 2
    fovValue = camera.FieldOfView
    originalFov = camera.FieldOfView
else
    speedValue = Config.maxWalkSpeed / 2
    fovValue = camera.FieldOfView or 70
    originalFov = fovValue
    secplayer:AddSeparator({ text = "Waiting for character — options apply when you spawn" })
    task.spawn(function()
        character = player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        speedValue = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or Config.maxWalkSpeed / 2
        fovValue = camera.FieldOfView
        originalFov = camera.FieldOfView
        originalValues.walkSpeed = speedValue
        originalValues.fov = originalFov
        detectJumpProperty()
        originalValues.jumpValue = originalJumpValue
        setupCharacter(character)
        trackConnection(player.CharacterAdded:Connect(setupCharacter))
        if _G.CROW and _G.CROW.SendNotification then
            _G.CROW:SendNotification("Player tab ready", 2)
        end
    end)
end

-- Original lighting values storage
local originalLighting = {
    brightness = Lighting.Brightness,
    ambient = Lighting.Ambient,
    colorShift = Lighting.ColorShift_Top,
    fog = Lighting.FogEnd,
    shadowSoftness = Lighting.ShadowSoftness,
    time = Lighting.TimeOfDay,
    globalShadows = Lighting.GlobalShadows,
    clockTime = Lighting.ClockTime
}

-- Detect Jump Property
local jumpPropertyName = ""
local jumpValue, jumpMin, jumpMax, jumpMultiplier
local originalJumpValue = 0

local function detectJumpProperty()
    if not humanoid then return end
    
    if pcall(function() return humanoid.JumpPower end) then
        jumpPropertyName = "JumpPower"
        jumpValue = humanoid.JumpPower > 0 and humanoid.JumpPower or Config.defaultJumpPower
        originalJumpValue = jumpValue
        jumpMin = jumpValue
        jumpMax = jumpValue * Config.jumpPowerMaxMultiplier
        jumpMultiplier = Config.jumpPowerIncrement
    elseif pcall(function() return humanoid.JumpHeight end) then
        jumpPropertyName = "JumpHeight"
        jumpValue = humanoid.JumpHeight > 0 and humanoid.JumpHeight or Config.defaultJumpHeight
        originalJumpValue = jumpValue
        jumpMin = jumpValue
        jumpMax = jumpValue * Config.jumpHeightMaxMultiplier
        jumpMultiplier = Config.jumpHeightIncrement
    else
        jumpPropertyName = "JumpPower"
        jumpValue = Config.defaultJumpPower
        originalJumpValue = jumpValue
        jumpMin = jumpValue
        jumpMax = jumpValue * Config.jumpPowerMaxMultiplier
        jumpMultiplier = Config.jumpPowerIncrement
    end
end

detectJumpProperty()

-- When no character yet, use defaults so UI sliders work until character spawns
if not humanoid then
    jumpPropertyName = "JumpPower"
    jumpValue = Config.defaultJumpPower
    originalJumpValue = Config.defaultJumpPower
    jumpMin = jumpValue
    jumpMax = jumpValue * Config.jumpPowerMaxMultiplier
    jumpMultiplier = Config.jumpPowerIncrement
end

-- Store original values
local originalValues = {
    walkSpeed = speedValue,
    jumpValue = originalJumpValue,
    fov = originalFov
}

-- States
local states = {
    speedEnabled = false,
    jumpEnabled = false,
    fovEnabled = false,
    noclipEnabled = false,
    flyEnabled = false,
}

-- Movement State Tracking
local currentMovementMethod = "CFrame"
local connections = {}

-- Connection Management
local function trackConnection(connection, metadata)
    if metadata then
        table.insert(connections, {
            connection = connection,
            type = metadata
        })
    else
        table.insert(connections, connection)
    end
    return connection
end

local function cleanupConnections(connectionType)
    for i = #connections, 1, -1 do
        local conn = connections[i]
        if type(conn) == "table" then
            if not connectionType or conn.type == connectionType then
                if conn.connection and conn.connection.Connected then
                    conn.connection:Disconnect()
                end
                table.remove(connections, i)
            end
        elseif type(conn) == "userdata" and conn.Connected then
            conn:Disconnect()
            table.remove(connections, i)
        end
    end
end

-- Forward declarations for toggle functions
local toggleSpeed, toggleJump, toggleFOV, toggleNoclip, toggleFly

-- Character Setup (called when character spawns or respawns)
local function setupCharacter(char)
    if not char then return end
    
    -- Update character references
    character = char
    
    -- Wait for humanoid to be available with timeout
    humanoid = char:WaitForChild("Humanoid", 5)
    
    if not humanoid then
        warn("Failed to find Humanoid after character respawn")
        return
    end
    
    -- Store original values for new character
    originalValues.walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or Config.maxWalkSpeed / 2
    speedValue = originalValues.walkSpeed
    
    -- Re-detect jump property for new character
    detectJumpProperty()
    originalValues.jumpValue = originalJumpValue
    
    -- Reapply active states with a slight delay to ensure properties exist
    task.spawn(function()
        task.wait(0.5)
        if states.speedEnabled then toggleSpeed(true) end
        if states.jumpEnabled then toggleJump(true) end
        if states.noclipEnabled then toggleNoclip(true) end
        if states.flyEnabled then toggleFly(true) end
    end)
end

-- Movement Methods (use tick() for delta; no Heartbeat:Wait() to avoid blocking)
local lastCFrameTick, lastImpulseTick

local movementMethods = {
    ["CFrame"] = function()
        if not character or not humanoid then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            local normalizedDir = moveDirection.Unit
            local now = tick()
            local deltaTime = now - (lastCFrameTick or now)
            lastCFrameTick = now
            local stepSize = speedValue * math.min(deltaTime, 0.1) * 0.85
            
            rootPart.CFrame = rootPart.CFrame + (normalizedDir * stepSize)
            rootPart.Velocity = Vector3.new(
                rootPart.Velocity.X * 0.7,
                rootPart.Velocity.Y,
                rootPart.Velocity.Z * 0.7
            )
        end
        
        -- Apply jump enhancement for CFrame method
        if states.jumpEnabled and humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            rootPart.Velocity = rootPart.Velocity + Vector3.new(0, jumpValue * 0.5, 0)
        end
    end,
    
    ["Normal"] = function()
        if not character or not humanoid then return end
        
        if states.speedEnabled then
            humanoid.WalkSpeed = speedValue
        end
        
        if states.jumpEnabled and jumpPropertyName ~= "" then
            pcall(function()
                humanoid[jumpPropertyName] = jumpValue
            end)
        end
    end,
    
    ["Velocity"] = function()
        if not character or not humanoid then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            local normalizedDir = moveDirection.Unit
            
            rootPart.Velocity = Vector3.new(
                normalizedDir.X * speedValue * 1.2,
                rootPart.Velocity.Y,
                normalizedDir.Z * speedValue * 1.2
            )
        end
        
        if states.jumpEnabled and humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            rootPart.Velocity = Vector3.new(
                rootPart.Velocity.X,
                jumpValue * 1.2,
                rootPart.Velocity.Z
            )
        end
    end,
    
    ["BodyVelocity"] = function()
        if not character or not humanoid then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local bodyVelocity = rootPart:FindFirstChild("MovementBodyVelocity")
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "MovementBodyVelocity"
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.P = 4000
            bodyVelocity.Parent = rootPart
        end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            local normalizedDir = moveDirection.Unit
            bodyVelocity.Velocity = Vector3.new(
                normalizedDir.X * speedValue * 1.5,
                0,
                normalizedDir.Z * speedValue * 1.5
            )
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        if states.jumpEnabled and humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            local jumpVelocity = rootPart:FindFirstChild("JumpBodyVelocity")
            if not jumpVelocity then
                jumpVelocity = Instance.new("BodyVelocity")
                jumpVelocity.Name = "JumpBodyVelocity"
                jumpVelocity.MaxForce = Vector3.new(0, 100000, 0)
                jumpVelocity.P = 4000
                jumpVelocity.Parent = rootPart
            end
            
            jumpVelocity.Velocity = Vector3.new(0, jumpValue * 2, 0)
            
            task.spawn(function()
                task.wait(0.2)
                if jumpVelocity and jumpVelocity.Parent then
                    jumpVelocity:Destroy()
                end
            end)
        end
    end,
    
    ["Impulse"] = function()
        if not character or not humanoid then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            local normalizedDir = moveDirection.Unit
            local now = tick()
            local deltaTime = now - (lastImpulseTick or now)
            lastImpulseTick = now
            local impulseForce = normalizedDir * speedValue * math.min(deltaTime, 0.1) * 20
            
            -- Use AssemblyLinearVelocity for newer Roblox versions
            if rootPart.AssemblyLinearVelocity then
                rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + impulseForce
            else
                rootPart.Velocity = rootPart.Velocity + impulseForce
            end
        end
        
        if states.jumpEnabled and humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            if rootPart.AssemblyLinearVelocity then
                rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, jumpValue * 15, 0)
            else
                rootPart.Velocity = rootPart.Velocity + Vector3.new(0, jumpValue * 15, 0)
            end
        end
    end
}

-- Function to clean up movement method effects
local function cleanupMovementMethod(methodName)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if methodName == "BodyVelocity" or methodName == "all" then
        local bv = rootPart:FindFirstChild("MovementBodyVelocity")
        if bv then bv:Destroy() end
        
        local jumpBV = rootPart:FindFirstChild("JumpBodyVelocity")
        if jumpBV then jumpBV:Destroy() end
    end
end

-- FOV watcher - ensures FOV is always at the correct value
local function watchFOV()
    if not camera then return end
    cleanupConnections("fov_watcher")
    trackConnection(camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if states.fovEnabled and camera.FieldOfView ~= fovValue then
            camera.FieldOfView = fovValue
        end
    end), "fov_watcher")
end

-- local function enableNoclip()
--     if not character then return end
    
--     cleanupConnections("noclip")
    
--     local connection = RunService.Stepped:Connect(function()
--         if not character or not character.Parent then return end
        
--         for _, part in pairs(character:GetDescendants()) do
--             if part:IsA("BasePart") and part ~= character:FindFirstChild("HumanoidRootPart") then
--                 part.CanCollide = false
--             end
--         end
--     end)
    
--     trackConnection(connection, "noclip")
    
--     -- Also handle accessories and tools
--     local descendantConnection = character.DescendantAdded:Connect(function(descendant)
--         if states.noclipEnabled and descendant:IsA("BasePart") and descendant ~= character:FindFirstChild("HumanoidRootPart") then
--             descendant.CanCollide = false
--         end
--     end)
    
--     trackConnection(descendantConnection, "noclip")
-- end

-- local function disableNoclip()
--     if not character then return end
    
--     -- Remove noclip connections
--     cleanupConnections("noclip")
    
--     -- Restore collision
--     for _, part in pairs(character:GetDescendants()) do
--         if part:IsA("BasePart") and part ~= character:FindFirstChild("HumanoidRootPart") then
--             part.CanCollide = true
--         end
--     end
-- end

-- Optimized property enforcement with throttling
local lastPropertyUpdate = 0

local function enforceProperties()
    local now = tick()
    if now - lastPropertyUpdate < Config.propertyUpdateInterval then return end
    lastPropertyUpdate = now
    
    -- Check if character exists
    if not character or not character.Parent then
        character = player.Character
        if not character then return end
        humanoid = character:FindFirstChildOfClass("Humanoid")
    end
    
    if not humanoid then return end
    
    -- FOV enforcement (only if different)
    if states.fovEnabled and camera and math.abs(camera.FieldOfView - fovValue) > 0.1 then
        camera.FieldOfView = fovValue
    end
    
    -- Jump enforcement: only apply humanoid jump when using Normal movement method (other methods use Velocity/BodyVelocity/etc. in the movement loop)
    if states.jumpEnabled and jumpPropertyName ~= "" then
        if currentMovementMethod == "Normal" then
            local success, currentValue = pcall(function() return humanoid[jumpPropertyName] end)
            if success and math.abs(currentValue - jumpValue) > 0.1 then
                humanoid[jumpPropertyName] = jumpValue
            end
        else
            -- Keep humanoid at default so jump key triggers state; movement loop applies custom height
            local success, currentValue = pcall(function() return humanoid[jumpPropertyName] end)
            if success and math.abs(currentValue - originalValues.jumpValue) > 0.1 then
                humanoid[jumpPropertyName] = originalValues.jumpValue
            end
        end
    end
    
    -- Speed enforcement for Normal method (only if different)
    if currentMovementMethod == "Normal" and states.speedEnabled then
        if math.abs(humanoid.WalkSpeed - speedValue) > 0.1 then
            humanoid.WalkSpeed = speedValue
        end
    end

    -- Noclip enforced in Stepped loop (all parts)
end

-- Movement Controls
local function toggleMovement(state)
    states.speedEnabled = state
    
    -- Clean up previous movement connections
    cleanupConnections("movement")
    cleanupMovementMethod("all")
    
    if state then
        trackConnection(RunService.Heartbeat:Connect(movementMethods[currentMovementMethod]), "movement")
    else
        if humanoid then
            humanoid.WalkSpeed = originalValues.walkSpeed
        end
    end
end

toggleSpeed = function(state)
    states.speedEnabled = state
    toggleMovement(state)
    
    if humanoid then
        humanoid.WalkSpeed = state and speedValue or originalValues.walkSpeed
    end
end

toggleJump = function(state)
    states.jumpEnabled = state
    
    if humanoid and jumpPropertyName ~= "" then
        pcall(function()
            -- Normal method uses humanoid jump; other methods use movement loop (Velocity/BodyVelocity/etc.)
            if state then
                humanoid[jumpPropertyName] = (currentMovementMethod == "Normal") and jumpValue or originalValues.jumpValue
            else
                humanoid[jumpPropertyName] = originalValues.jumpValue
            end
        end)
    end
end

toggleFOV = function(state)
    states.fovEnabled = state
    
    if not camera then return end
    
    if state then
        camera.FieldOfView = fovValue
        watchFOV()
    else
        camera.FieldOfView = originalValues.fov
        cleanupConnections("fov_watcher")
    end
end

-- Noclip: same as commented "other" script — leave HumanoidRootPart alone (game uses it); only toggle limbs/accessories
local function setNoclipPartsCollide(collide)
    if not character or not character.Parent then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= hrp then
            part.CanCollide = collide
        end
    end
end

toggleNoclip = function(state)
    states.noclipEnabled = state
    cleanupConnections("noclip")
    if not character then return end
    if state then
        local connection = RunService.Stepped:Connect(function()
            if not states.noclipEnabled or not character or not character.Parent then return end
            setNoclipPartsCollide(false)
        end)
        trackConnection(connection, "noclip")
        local descendantConnection = character.DescendantAdded:Connect(function(descendant)
            if states.noclipEnabled and descendant:IsA("BasePart") and descendant ~= character:FindFirstChild("HumanoidRootPart") then
                descendant.CanCollide = false
            end
        end)
        trackConnection(descendantConnection, "noclip")
    else
        setNoclipPartsCollide(true)
    end
end

-- Fly: camera-based movement; when idle use deltaTime to stay exactly stationary (no drift)
local flyValue = Config.defaultFlySpeed or 50
local flyUpKey = Enum.KeyCode.Space
local flyDownKey = Enum.KeyCode.LeftControl
local flyLastTick = 0
toggleFly = function(state)
    states.flyEnabled = state
    cleanupConnections("fly")
    if not state then return end
    flyLastTick = tick()
    trackConnection(RunService.Heartbeat:Connect(function()
        if not character or not humanoid then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp or not camera then return end
        local now = tick()
        local dt = math.max(0.001, math.min(now - flyLastTick, 0.05))
        flyLastTick = now
        local gravity = workspace.Gravity
        local cf = camera.CFrame
        local look = cf.LookVector
        local right = cf.RightVector
        local w = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        local s = UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
        local a = UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0
        local d = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local up = UserInputService:IsKeyDown(flyUpKey) and 1 or 0
        local down = UserInputService:IsKeyDown(flyDownKey) and 1 or 0
        local forward = (w - s) * look
        local strafe = (d - a) * right
        local horizontal = forward + strafe
        local verticalInput = (up - down) * flyValue
        if horizontal.Magnitude > 0.01 then
            horizontal = horizontal.Unit * flyValue
        else
            horizontal = Vector3.zero
        end
        -- Vertical: up/down keys, or when idle counteract gravity so you stay stationary (no drift)
        local verticalVel = verticalInput ~= 0 and verticalInput or (gravity > 0 and gravity * dt or 0)
        hrp.Velocity = horizontal + Vector3.new(0, verticalVel, 0)
    end), "fly")
end


local function updateMovementMethod(method)
    cleanupMovementMethod(currentMovementMethod)
    currentMovementMethod = method
    
    -- Sync jump to movement method: Normal uses humanoid jump; others use movement loop only
    if humanoid and jumpPropertyName ~= "" and states.jumpEnabled then
        pcall(function()
            humanoid[jumpPropertyName] = (currentMovementMethod == "Normal") and jumpValue or originalValues.jumpValue
        end)
    end
    
    if states.speedEnabled then
        toggleMovement(false)
        toggleMovement(true)
    end
end

-- Connect to CharacterAdded event to handle respawns
trackConnection(player.CharacterAdded:Connect(setupCharacter))

-- Set up the continuous properties enforcement
trackConnection(RunService.RenderStepped:Connect(enforceProperties), "properties_enforcement")

-- Initial FOV watcher setup
watchFOV()

-- Cleanup Function
local function cleanupStats()
    cleanupConnections()
    cleanupMovementMethod("all")
    
    if humanoid then
        humanoid.WalkSpeed = originalValues.walkSpeed
        if jumpPropertyName ~= "" then
            pcall(function()
                humanoid[jumpPropertyName] = originalValues.jumpValue
            end)
        end
    end
    
    if camera then
        camera.FieldOfView = originalValues.fov
    end

    if states.noclipEnabled and character then
        setNoclipPartsCollide(true)
    end

    for key, _ in pairs(states) do
        states[key] = false
    end
end

-- UI ELEMENTS (CFrame movement only - no dropdown; undetected)
local speedSlider = secplayer:AddSlider({
    text = "WalkSpeed",
    tooltip = "Default = your current speed. Can go slower or faster.",
    flag = "walkspeed",
    min = Config.minWalkSpeed or 0,
    max = Config.maxWalkSpeed,
    increment = Config.walkSpeedIncrement,
    default = speedValue,
    value = speedValue,
    callback = function(v)
        speedValue = v
        if states.speedEnabled and humanoid then
            if currentMovementMethod == "Normal" then
                humanoid.WalkSpeed = speedValue
            end
        end
    end
})

local speedToggle = secplayer:AddToggle({
    text = "Speed",
    state = false,
    tooltip = "Toggle custom movement speed",
    flag = "Toggle_Speed",
    callback = function(state)
        toggleSpeed(state)
    end
})
speedToggle:AddBind({
    text = "Speed Key",
    tooltip = "Hotkey to toggle speed",
    mode = "toggle",
    flag = "ToggleKey_Speed",
    bind = "None",
    callback = function(v)
        speedToggle:SetState(v)
    end
})

local jumpSlider = secplayer:AddSlider({
    text = jumpPropertyName,
    tooltip = "Adjust jump height/power (uses movement method: Normal = humanoid, others = velocity/body)",
    flag = "jumpvalue",
    min = jumpMin,
    max = jumpMax,
    increment = jumpMultiplier,
    default = jumpValue,
    callback = function(v)
        jumpValue = v
        if states.jumpEnabled and humanoid and jumpPropertyName ~= "" and currentMovementMethod == "Normal" then
            pcall(function()
                humanoid[jumpPropertyName] = jumpValue
            end)
        end
    end
})

local jumpToggle = secplayer:AddToggle({
    text = "Jump",
    state = false,
    tooltip = "Toggle custom jump height",
    flag = "Toggle_Jump",
    callback = function(state)
        toggleJump(state)
    end
})
jumpToggle:AddBind({
    text = "Jump Key",
    tooltip = "Hotkey to toggle jump",
    mode = "toggle",
    flag = "ToggleKey_Jump",
    bind = "None",
    callback = function(v)
        jumpToggle:SetState(v)
    end
})

secplayer:AddSeparator({ text = "Movement" })

local noclipToggle = secplayer:AddToggle({
    text = "Noclip",
    state = false,
    tooltip = "Walk through walls (R6/R15; disables collision on all character parts; restores when off)",
    flag = "Toggle_Noclip",
    callback = function(state)
        toggleNoclip(state)
    end
})
noclipToggle:AddBind({
    text = "Noclip Key",
    tooltip = "Hotkey to toggle noclip",
    mode = "toggle",
    flag = "ToggleKey_Noclip",
    bind = "None",
    callback = function(v)
        noclipToggle:SetState(v)
    end
})

local flySlider = secplayer:AddSlider({
    text = "Fly speed",
    tooltip = "Horizontal and vertical speed when flying",
    flag = "flyvalue",
    min = Config.flySpeedMin or 20,
    max = Config.flySpeedMax or 200,
    increment = Config.flySpeedIncrement or 10,
    default = Config.defaultFlySpeed or 50,
    callback = function(v)
        flyValue = v
    end
})

local flyToggle = secplayer:AddToggle({
    text = "Fly",
    state = false,
    tooltip = "WASD = move in camera direction. Use Fly Up/Down keys below for vertical.",
    flag = "Toggle_Fly",
    callback = function(state)
        toggleFly(state)
    end
})
flyToggle:AddBind({
    text = "Fly Key",
    tooltip = "Hotkey to toggle fly",
    mode = "toggle",
    flag = "ToggleKey_Fly",
    bind = "None",
    callback = function(v)
        flyToggle:SetState(v)
    end
})

secplayer:AddBind({
    text = "Fly Up Key",
    tooltip = "Hold to move up while flying",
    flag = "FlyUpKey",
    bind = Enum.KeyCode.Space,
    keycallback = function(key)
        flyUpKey = (key and key ~= "none") and key or Enum.KeyCode.Space
    end
})

secplayer:AddBind({
    text = "Fly Down Key",
    tooltip = "Hold to move down while flying",
    flag = "FlyDownKey",
    bind = Enum.KeyCode.LeftControl,
    keycallback = function(key)
        flyDownKey = (key and key ~= "none") and key or Enum.KeyCode.LeftControl
    end
})

secplayer:AddSeparator({ text = "Misc" })

local fovSlider = secplayer:AddSlider({
    text = "Field of View",
    tooltip = "Adjust camera field of view",
    flag = "fov",
    min = originalFov,
    max = Config.maxFOV,
    increment = Config.fovIncrement,
    default = fovValue,
    callback = function(v)
        fovValue = v
        if states.fovEnabled and camera then
            camera.FieldOfView = v
        end
    end
})

local fovToggle = secplayer:AddToggle({
    text = "FOV",
    state = false,
    tooltip = "Use the FOV slider value instead of default",
    flag = "Toggle_FOV",
    callback = function(state)
        toggleFOV(state)
    end
})
fovToggle:AddBind({
    text = "FOV Key",
    tooltip = "Hotkey to toggle FOV",
    mode = "toggle",
    flag = "ToggleKey_FOV",
    bind = "None",
    callback = function(v)
        fovToggle:SetState(v)
    end
})



-- Character Customization Section
local seccharacter = _G.PlayerTab:AddSection("Character Customization", 2)

-- Copy Avatar by User ID (order: first so user can set appearance before effects)
seccharacter:AddSeparator({ text = "Copy Avatar" })
seccharacter:AddBox({
    text = "User ID",
    tooltip = "Enter a Roblox User ID to copy that player's avatar",
    flag = "AvatarUserId",
    default = ""
})
seccharacter:AddButton({
    text = "Copy Avatar",
    tooltip = "Apply the avatar of the User ID above to your character (may require executor support)",
    callback = function()
        local lib = _G.library or _G.CROW
        local userIdStr = (lib and lib.flags and lib.flags["AvatarUserId"]) or ""
        local userId = tonumber(userIdStr)
        if not userId or userId < 1 then
            if lib and lib.SendNotification then lib:SendNotification("Enter a valid User ID", 3) end
            return
        end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then
            if lib and lib.SendNotification then lib:SendNotification("No character found", 3) end
            return
        end
        task.spawn(function()
            local ok, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
            end)
            if not ok or not desc then
                if lib and lib.SendNotification then lib:SendNotification("Failed to load avatar (UserId " .. userId .. ")", 4) end
                return
            end
            local applyOk, err = pcall(function()
                hum:ApplyDescription(desc)
            end)
            if applyOk and lib and lib.SendNotification then
                lib:SendNotification("Avatar applied: " .. userId, 3)
            elseif not applyOk and lib and lib.SendNotification then
                lib:SendNotification("Apply failed (server may block)", 4)
            end
        end)
    end
})

seccharacter:AddSeparator({ text = "Colors & Material" })

-- === OPTIMIZED CHARACTER CUSTOMIZER ===
local CharacterCustomizer = {
    -- State tracking
    state = {
        rainbowEnabled = false,
        customColorEnabled = false,
        materialEnabled = false,
        transparencyEnabled = false,
        glowEnabled = false,
        outlineEnabled = false
    },
    
    -- Settings
    settings = {
        customColor = Config.characterEffects.defaultCustomColor,
        rainbowSpeed = Config.characterEffects.rainbowSpeedDefault,
        selectedMaterial = Config.characterEffects.defaultMaterial,
        transparencyValue = Config.characterEffects.transparencyDefault,
        glowColor = Config.characterEffects.defaultGlowColor,
        glowIntensity = Config.characterEffects.glowIntensityDefault,
        outlineColor = Config.characterEffects.defaultOutlineColor,
        outlineThickness = Config.characterEffects.outlineThicknessDefault
    },
    
    -- Storage
    originalProperties = {},
    partsCache = {},
    lastCacheUpdate = 0,
    connections = {},
    isInitialized = false,
    lastRainbowUpdate = 0
}

local ARMS_EXCLUDED_NAMES = { ["HumanoidRootPart"] = true, ["Left Arm"] = true, ["Right Arm"] = true }

function CharacterCustomizer:GetAllParts()
    local now = tick()
    local camera = workspace.CurrentCamera
    local hasArms = camera and camera:FindFirstChild("Arms")
    -- When Arms exists, always rescan so we pick up the current weapon model (cache can be stale)
    if not hasArms and now - self.lastCacheUpdate < Config.partsCacheInterval and next(self.partsCache) then
        return self.partsCache
    end
    
    self.partsCache = {}
    
    if not character or not character.Parent then
        return self.partsCache
    end
    
    -- Character body parts: all direct BasePart children (player arms/body get colors; only camera Arms exclusions are below)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(self.partsCache, part)
        end
    end
    
    -- Accessories
    for _, accessory in pairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            local handle = accessory:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                table.insert(self.partsCache, handle)
            end
        end
    end

    if camera then
        local arms = camera:FindFirstChild("Arms")
        if arms then
            if rawget(_G, "CROW_DEBUG_ARMS") == true then
                local lastLog = rawget(_G, "CROW_DEBUG_ARMS_LAST") or 0
                if tick() - lastLog > 5 then
                    _G.CROW_DEBUG_ARMS_LAST = tick()
                    local lines = {"[CROW Arms Debug] workspace.CurrentCamera.Arms structure:"}
                    for _, child in ipairs(arms:GetChildren()) do
                        table.insert(lines, string.format("  Child: Name=%s ClassName=%s", tostring(child.Name), tostring(child.ClassName)))
                        if child:IsA("Model") or child:IsA("Tool") then
                            for _, sub in ipairs(child:GetChildren()) do
                                table.insert(lines, string.format("    -> %s (%s)", tostring(sub.Name), tostring(sub.ClassName)))
                            end
                        end
                    end
                    table.insert(lines, "[CROW Arms Debug] All descendants:")
                    for _, d in ipairs(arms:GetDescendants()) do
                        table.insert(lines, string.format("  %s | %s", tostring(d.Name), tostring(d.ClassName)))
                    end
                    warn(table.concat(lines, "\n"))
                end
            end
            for _, part in pairs(arms:GetDescendants()) do
                if not part:IsA("BasePart") then continue end
                if ARMS_EXCLUDED_NAMES[part.Name] then continue end
                local p = part.Parent
                while p and p ~= arms do
                    if p.Name == "CSSArms" then break end
                    p = p.Parent
                end
                if p == arms then
                    table.insert(self.partsCache, part)
                end
            end
        end
    end
    
    if rawget(_G, "CROW_DEBUG_ARMS") == true and next(self.partsCache) then
        local names = {}
        for _, p in ipairs(self.partsCache) do
            if p and p.Parent then names[#names + 1] = p.Name .. " (" .. p.Parent.Name .. ")" end
        end
        table.sort(names)
        warn("[CROW Character Customization] Parts (" .. #self.partsCache .. "): " .. table.concat(names, ", "))
    end

    self.lastCacheUpdate = now
    return self.partsCache
end

-- Store original properties
function CharacterCustomizer:StoreOriginalProperties()
    if self.isInitialized then return end
    
    local parts = self:GetAllParts()
    
    for _, part in pairs(parts) do
        if part and part.Parent then
            self.originalProperties[part] = {
                color = part.Color,
                material = part.Material,
                transparency = part.Transparency
            }
        end
    end
    
    -- Store face transparency
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face then
            self.originalProperties[face] = {
                transparency = face.Transparency
            }
        end
    end
    
    self.isInitialized = true
end

-- Rainbow effect with throttling
function CharacterCustomizer:UpdateRainbow()
    local now = tick()
    if now - self.lastRainbowUpdate < Config.rainbowUpdateInterval then return end
    self.lastRainbowUpdate = now
    
    if not self.state.rainbowEnabled then return end
    
    local hue = (now * self.settings.rainbowSpeed) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                part.Color = color
            end)
        end
    end
end

-- Apply custom color
function CharacterCustomizer:ApplyCustomColor()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                part.Color = self.settings.customColor
            end)
        end
    end
end

-- Apply material
function CharacterCustomizer:ApplyMaterial()
    local materialEnum = Enum.Material[self.settings.selectedMaterial]
    if not materialEnum then return end
    
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                part.Material = materialEnum
            end)
        end
    end
end

-- Apply transparency
function CharacterCustomizer:ApplyTransparency()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = self.settings.transparencyValue
            end)
        end
    end
    
    -- Handle face transparency
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face then
            pcall(function()
                face.Transparency = self.settings.transparencyValue * 0.8
            end)
        end
    end
end

-- Apply glow effect
function CharacterCustomizer:ApplyGlow()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                -- Remove existing glow
                local oldGlow = part:FindFirstChild("CustomGlow")
                if oldGlow then oldGlow:Destroy() end
                
                -- Add new glow
                local light = Instance.new("PointLight")
                light.Name = "CustomGlow"
                light.Color = self.settings.glowColor
                light.Brightness = self.settings.glowIntensity
                light.Range = Config.characterEffects.glowRange
                light.Parent = part
            end)
        end
    end
end

-- Apply outline effect
function CharacterCustomizer:ApplyOutline()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                -- Remove existing outline
                local oldOutline = part:FindFirstChild("CustomOutline")
                if oldOutline then oldOutline:Destroy() end
                
                -- Add new outline
                local box = Instance.new("SelectionBox")
                box.Name = "CustomOutline"
                box.Adornee = part
                box.Color3 = self.settings.outlineColor
                box.LineThickness = self.settings.outlineThickness
                box.Transparency = Config.characterEffects.outlineTransparency
                box.Parent = part
            end)
        end
    end
end

-- Remove glow effects
function CharacterCustomizer:RemoveGlow()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                local glow = part:FindFirstChild("CustomGlow")
                if glow then glow:Destroy() end
            end)
        end
    end
end

-- Remove outline effects
function CharacterCustomizer:RemoveOutline()
    local parts = self:GetAllParts()
    for _, part in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                local outline = part:FindFirstChild("CustomOutline")
                if outline then outline:Destroy() end
            end)
        end
    end
end

-- Restore original properties
function CharacterCustomizer:RestoreColors()
    for part, props in pairs(self.originalProperties) do
        if part and part.Parent and props then
            if not self.state.rainbowEnabled and not self.state.customColorEnabled then
                pcall(function()
                    if props.color then
                        part.Color = props.color
                    end
                end)
            end
        end
    end
end

function CharacterCustomizer:RestoreMaterials()
    for part, props in pairs(self.originalProperties) do
        if part and part.Parent and props then
            pcall(function()
                if props.material then
                    part.Material = props.material
                end
            end)
        end
    end
end

function CharacterCustomizer:RestoreTransparency()
    for part, props in pairs(self.originalProperties) do
        if part and part.Parent and props then
            pcall(function()
                if props.transparency ~= nil then
                    part.Transparency = props.transparency
                else
                    part.Transparency = 0
                end
            end)
        end
    end
end

-- Toggle functions
function CharacterCustomizer:ToggleRainbow(state)
    self.state.rainbowEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        
        -- Disable custom color
        self.state.customColorEnabled = false
        
        -- Start rainbow effect
        self:CleanupConnections("rainbow")
        local conn = RunService.Heartbeat:Connect(function()
            self:UpdateRainbow()
        end)
        table.insert(self.connections, {connection = conn, type = "rainbow"})
    else
        self:CleanupConnections("rainbow")
        if not self.state.customColorEnabled then
            self:RestoreColors()
        end
    end
end

function CharacterCustomizer:ToggleCustomColor(state)
    self.state.customColorEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        
        -- Disable rainbow
        self.state.rainbowEnabled = false
        self:CleanupConnections("rainbow")
        
        self:ApplyCustomColor()
    else
        if not self.state.rainbowEnabled then
            self:RestoreColors()
        end
    end
end

function CharacterCustomizer:ToggleMaterial(state)
    self.state.materialEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        self:ApplyMaterial()
    else
        self:RestoreMaterials()
    end
end

function CharacterCustomizer:ToggleTransparency(state)
    self.state.transparencyEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        self:ApplyTransparency()
    else
        self:RestoreTransparency()
    end
end

function CharacterCustomizer:ToggleGlow(state)
    self.state.glowEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        self:ApplyGlow()
    else
        self:RemoveGlow()
    end
end

function CharacterCustomizer:ToggleOutline(state)
    self.state.outlineEnabled = state
    
    if state then
        if not self.isInitialized then
            self:StoreOriginalProperties()
        end
        self:ApplyOutline()
    else
        self:RemoveOutline()
    end
end

-- Connection management
function CharacterCustomizer:CleanupConnections(connectionType)
    for i = #self.connections, 1, -1 do
        local conn = self.connections[i]
        if type(conn) == "table" then
            if not connectionType or conn.type == connectionType then
                if conn.connection and conn.connection.Connected then
                    conn.connection:Disconnect()
                end
                table.remove(self.connections, i)
            end
        end
    end
end

-- Full restore function
function CharacterCustomizer:FullRestore()
    -- Disable all states
    for key in pairs(self.state) do
        self.state[key] = false
    end
    
    -- Clean up connections
    self:CleanupConnections()
    
    -- Remove effects
    self:RemoveGlow()
    self:RemoveOutline()
    
    -- Restore all properties
    for part, props in pairs(self.originalProperties) do
        if part and part.Parent and props then
            pcall(function()
                if props.color then
                    part.Color = props.color
                end
                if props.material then
                    part.Material = props.material
                end
                if props.transparency ~= nil then
                    part.Transparency = props.transparency
                else
                    part.Transparency = 0
                end
            end)
        end
    end
    
    -- Clear cache and reset
    self.partsCache = {}
    self.lastCacheUpdate = 0
    self.isInitialized = false
    self.originalProperties = {}
end

-- Character respawn handling
function CharacterCustomizer:HandleCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 5)
    
    -- Reset everything
    self.partsCache = {}
    self.lastCacheUpdate = 0
    self.isInitialized = false
    self.originalProperties = {}
    
    -- Wait for character to fully load
    task.wait(1)
    
    -- Reapply active effects
    local activeEffects = {}
    for effect, enabled in pairs(self.state) do
        if enabled then
            activeEffects[effect] = true
        end
    end
    
    -- Store originals first
    if next(activeEffects) then
        self:StoreOriginalProperties()
        
        -- Reapply effects
        if activeEffects.rainbowEnabled then
            self:ToggleRainbow(true)
        elseif activeEffects.customColorEnabled then
            self:ApplyCustomColor()
        end
        
        if activeEffects.materialEnabled then
            self:ApplyMaterial()
        end
        
        if activeEffects.transparencyEnabled then
            self:ApplyTransparency()
        end
        
        if activeEffects.glowEnabled then
            self:ApplyGlow()
        end
        
        if activeEffects.outlineEnabled then
            self:ApplyOutline()
        end
    end
end

-- === UI ELEMENTS ===

-- Rainbow Section
local rainbowToggle = seccharacter:AddToggle({
    text = "Rainbow Character",
    state = false,
    tooltip = "Makes your character cycle through rainbow colors",
    flag = "Toggle_Rainbow",
    callback = function(state)
        CharacterCustomizer:ToggleRainbow(state)
    end
})
rainbowToggle:AddBind({
    text = "Rainbow Key",
    tooltip = "Hotkey to toggle rainbow effect",
    mode = "toggle",
    flag = "ToggleKey_Rainbow",
    bind = "None",
    callback = function(v)
        rainbowToggle:SetState(v)
    end
})

seccharacter:AddSlider({
    text = "Rainbow Speed",
    tooltip = "Adjust the speed of the rainbow effect",
    flag = "rainbowspeed",
    min = Config.characterEffects.rainbowSpeedMin,
    max = Config.characterEffects.rainbowSpeedMax,
    increment = Config.characterEffects.rainbowSpeedIncrement,
    default = Config.characterEffects.rainbowSpeedDefault,
    callback = function(v)
        CharacterCustomizer.settings.rainbowSpeed = v
    end
})

-- Custom Color Section
local customColorToggle = seccharacter:AddToggle({
    text = "Custom Color",
    state = false,
    tooltip = "Apply a custom color to your character",
    flag = "Toggle_CustomColor",
    callback = function(state)
        CharacterCustomizer:ToggleCustomColor(state)
    end
})
customColorToggle:AddBind({
    text = "Color Key",
    tooltip = "Hotkey to toggle custom color",
    mode = "toggle",
    flag = "ToggleKey_CustomColor",
    bind = "None",
    callback = function(v)
        customColorToggle:SetState(v)
    end
})

seccharacter:AddColor({
    text = "Character Color",
    tooltip = "Choose a color for your character",
    color = CharacterCustomizer.settings.customColor,
    trans = 0,
    callback = function(color)
        CharacterCustomizer.settings.customColor = color
        if CharacterCustomizer.state.customColorEnabled then
            CharacterCustomizer:ApplyCustomColor()
        end
    end
})

-- Material Section
local materialToggle = seccharacter:AddToggle({
    text = "Custom Material",
    state = false,
    tooltip = "Apply a custom material to your character",
    flag = "Toggle_Material",
    callback = function(state)
        CharacterCustomizer:ToggleMaterial(state)
    end
})
materialToggle:AddBind({
    text = "Material Key",
    tooltip = "Hotkey to toggle custom material",
    mode = "toggle",
    flag = "ToggleKey_Material",
    bind = "None",
    callback = function(v)
        materialToggle:SetState(v)
    end
})

seccharacter:AddList({
    text = "Material Type",
    tooltip = "Select character material",
    selected = Config.characterEffects.defaultMaterial,
    multi = false,
    max = 10,
    values = Config.materials,
    callback = function(v)
        CharacterCustomizer.settings.selectedMaterial = v
        if CharacterCustomizer.state.materialEnabled then
            CharacterCustomizer:ApplyMaterial()
        end
    end
})

seccharacter:AddSeparator({ text = "Transparency & Effects" })

-- Transparency Section
local transparencyToggle = seccharacter:AddToggle({
    text = "Character Transparency",
    state = false,
    tooltip = "Make your character transparent",
    flag = "Toggle_Transparency",
    callback = function(state)
        CharacterCustomizer:ToggleTransparency(state)
    end
})
transparencyToggle:AddBind({
    text = "Transparency Key",
    tooltip = "Hotkey to toggle transparency",
    mode = "toggle",
    flag = "ToggleKey_Transparency",
    bind = "None",
    callback = function(v)
        transparencyToggle:SetState(v)
    end
})

seccharacter:AddSlider({
    text = "Transparency Level",
    tooltip = "Adjust character transparency",
    flag = "transparencylevel",
    min = Config.characterEffects.transparencyMin,
    max = Config.characterEffects.transparencyMax,
    increment = Config.characterEffects.transparencyIncrement,
    default = Config.characterEffects.transparencyDefault,
    callback = function(v)
        CharacterCustomizer.settings.transparencyValue = v
        if CharacterCustomizer.state.transparencyEnabled then
            CharacterCustomizer:ApplyTransparency()
        end
    end
})

-- Glow Section
local glowToggle = seccharacter:AddToggle({
    text = "Character Glow",
    state = false,
    tooltip = "Add a glowing effect to your character",
    flag = "Toggle_Glow",
    callback = function(state)
        CharacterCustomizer:ToggleGlow(state)
    end
})
glowToggle:AddBind({
    text = "Glow Key",
    tooltip = "Hotkey to toggle glow effect",
    mode = "toggle",
    flag = "ToggleKey_Glow",
    bind = "None",
    callback = function(v)
        glowToggle:SetState(v)
    end
})

seccharacter:AddColor({
    text = "Glow Color",
    tooltip = "Choose the glow color",
    color = CharacterCustomizer.settings.glowColor,
    trans = 0,
    callback = function(color)
        CharacterCustomizer.settings.glowColor = color
        if CharacterCustomizer.state.glowEnabled then
            CharacterCustomizer:ApplyGlow()
        end
    end
})

seccharacter:AddSlider({
    text = "Glow Intensity",
    tooltip = "Adjust glow brightness",
    flag = "glowintensity",
    min = Config.characterEffects.glowIntensityMin,
    max = Config.characterEffects.glowIntensityMax,
    increment = Config.characterEffects.glowIntensityIncrement,
    default = Config.characterEffects.glowIntensityDefault,
    callback = function(v)
        CharacterCustomizer.settings.glowIntensity = v
        if CharacterCustomizer.state.glowEnabled then
            CharacterCustomizer:ApplyGlow()
        end
    end
})

-- Outline Section
local outlineToggle = seccharacter:AddToggle({
    text = "Character Outline",
    state = false,
    tooltip = "Add an outline to your character",
    flag = "Toggle_Outline",
    callback = function(state)
        CharacterCustomizer:ToggleOutline(state)
    end
})
outlineToggle:AddBind({
    text = "Outline Key",
    tooltip = "Hotkey to toggle outline",
    mode = "toggle",
    flag = "ToggleKey_Outline",
    bind = "None",
    callback = function(v)
        outlineToggle:SetState(v)
    end
})

seccharacter:AddColor({
    text = "Outline Color",
    tooltip = "Choose the outline color",
    color = CharacterCustomizer.settings.outlineColor,
    trans = 0,
    callback = function(color)
        CharacterCustomizer.settings.outlineColor = color
        if CharacterCustomizer.state.outlineEnabled then
            CharacterCustomizer:ApplyOutline()
        end
    end
})

seccharacter:AddSlider({
    text = "Outline Thickness",
    tooltip = "Adjust outline thickness",
    flag = "outlinethickness",
    min = Config.characterEffects.outlineThicknessMin,
    max = Config.characterEffects.outlineThicknessMax,
    increment = Config.characterEffects.outlineThicknessIncrement,
    default = Config.characterEffects.outlineThicknessDefault,
    callback = function(v)
        CharacterCustomizer.settings.outlineThickness = v
        if CharacterCustomizer.state.outlineEnabled then
            CharacterCustomizer:ApplyOutline()
        end
    end
})

seccharacter:AddSeparator({ text = "Reset & Refresh" })

seccharacter:AddButton({
    text = "Reset All Effects",
    tooltip = "Turn off all effects and restore character colors/material/transparency",
    callback = function()
        CharacterCustomizer:FullRestore()
        local lib = _G.library or _G.CROW
        local characterEffectFlags = {"Toggle_Rainbow", "Toggle_CustomColor", "Toggle_Material", "Toggle_Transparency", "Toggle_Glow", "Toggle_Outline"}
        for _, flagName in ipairs(characterEffectFlags) do
            local opt = lib and lib.options and lib.options[flagName]
            if opt and opt.SetState then
                pcall(function() opt:SetState(false, true) end)
            end
        end
        if lib and lib.SendNotification then
            lib:SendNotification("All character effects reset", 3)
        end
    end
})

seccharacter:AddButton({
    text = "Refresh Character",
    tooltip = "Re-detect character and reapply any enabled effects (e.g. after respawn)",
    callback = function()
        local char = player.Character
        if char then
            character = char
            humanoid = char:FindFirstChildOfClass("Humanoid")
            CharacterCustomizer:HandleCharacterAdded(char)
            if _G.CROW and _G.CROW.SendNotification then
                _G.CROW:SendNotification("Character refreshed", 2)
            end
        elseif _G.CROW and _G.CROW.SendNotification then
            _G.CROW:SendNotification("No character to refresh", 3)
        end
    end
})

-- === EVENT CONNECTIONS ===

-- Connect to character events
player.CharacterAdded:Connect(function(char)
    CharacterCustomizer:HandleCharacterAdded(char)
end)

-- Helper: print Arms structure for debugging (so we know where the weapon is)
local function printArmsDebug(arms)
    if not arms then return end
    local lines = {"[CROW Arms Debug] workspace.CurrentCamera.Arms structure:"}
    for _, child in ipairs(arms:GetChildren()) do
        table.insert(lines, string.format("  Child: Name=%s ClassName=%s", tostring(child.Name), tostring(child.ClassName)))
        if child:IsA("Model") or child:IsA("Tool") then
            for _, sub in ipairs(child:GetChildren()) do
                table.insert(lines, string.format("    -> %s (%s)", tostring(sub.Name), tostring(sub.ClassName)))
            end
        end
    end
    table.insert(lines, "[CROW Arms Debug] All descendants:")
    for _, d in ipairs(arms:GetDescendants()) do
        table.insert(lines, string.format("  %s | %s", tostring(d.Name), tostring(d.ClassName)))
    end
    local out = table.concat(lines, "\n")
    print(out)
    warn(out)
end

-- Monitor arms addition/removal
local cam = workspace.CurrentCamera
if cam then
    cam.ChildAdded:Connect(function(child)
        if child.Name == "Arms" then
            task.wait(0.1)
            -- Always print Arms structure when Arms is added (so user sees it in output)
            printArmsDebug(child)
            CharacterCustomizer.partsCache = {}
            CharacterCustomizer.lastCacheUpdate = 0
            
            -- Reapply effects to arms
            if CharacterCustomizer.isInitialized then
                if CharacterCustomizer.state.rainbowEnabled then
                    -- Rainbow will handle automatically
                elseif CharacterCustomizer.state.customColorEnabled then
                    CharacterCustomizer:ApplyCustomColor()
                end
                
                if CharacterCustomizer.state.materialEnabled then
                    CharacterCustomizer:ApplyMaterial()
                end
                
                if CharacterCustomizer.state.transparencyEnabled then
                    CharacterCustomizer:ApplyTransparency()
                end
                
                if CharacterCustomizer.state.glowEnabled then
                    CharacterCustomizer:ApplyGlow()
                end
                
                if CharacterCustomizer.state.outlineEnabled then
                    CharacterCustomizer:ApplyOutline()
                end
            end
        end
    end)
    -- If Arms already exists (e.g. script ran after game loaded), print once
    task.defer(function()
        local arms = cam:FindFirstChild("Arms")
        if arms and not _G.CROW_DEBUG_ARMS_LOGGED then
            _G.CROW_DEBUG_ARMS_LOGGED = true
            printArmsDebug(arms)
        end
    end)
end

-- Initialize for existing character
if character then
    task.spawn(function()
        CharacterCustomizer:HandleCharacterAdded(character)
    end)
end

-- Cleanup function for character effects
local function cleanupCharacterEffects()
    CharacterCustomizer:CleanupConnections()
    CharacterCustomizer:FullRestore()
end

-- Store cleanup function for external access
_G.PlayerTab.CleanupCharacterEffects = cleanupCharacterEffects
