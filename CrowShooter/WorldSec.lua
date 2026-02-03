    -- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
-- World Variables
_G.World = _G.World or {}
_G.World.OriginalSettings = {}
_G.World.ColorCorrection = nil
_G.World.DepthOfField = nil
_G.World.Blur = nil
_G.World.SunRays = nil
_G.World.Bloom = nil
_G.World.StretchConnection = nil

-- Store original lighting settings
local function storeOriginalSettings()
    _G.World.OriginalSettings = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness,
        ClockTime = Lighting.ClockTime,
        ExposureCompensation = Lighting.ExposureCompensation,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        FogColor = Lighting.FogColor
    }
end

-- Function to create/get ColorCorrection effect
local function getColorCorrection()
    if not _G.World.ColorCorrection then
        _G.World.ColorCorrection = Instance.new("ColorCorrectionEffect")
        _G.World.ColorCorrection.Parent = Lighting
        _G.World.ColorCorrection.Name = "CROW_ColorCorrection"
    end
    return _G.World.ColorCorrection
end

-- Function to create/get DepthOfField effect (FIXED)
local function getDepthOfField()
    if not _G.World.DepthOfField then
        _G.World.DepthOfField = Instance.new("DepthOfFieldEffect")
        _G.World.DepthOfField.Parent = Lighting
        _G.World.DepthOfField.Name = "CROW_DepthOfField"
        -- Set default values when creating
        _G.World.DepthOfField.FarIntensity = 0.75
        _G.World.DepthOfField.FocusDistance = 50
        _G.World.DepthOfField.InFocusRadius = 10
        _G.World.DepthOfField.NearIntensity = 0.75
        _G.World.DepthOfField.Enabled = false
    end
    return _G.World.DepthOfField
end

-- Function to create/get Blur effect
local function getBlur()
    if not _G.World.Blur then
        _G.World.Blur = Instance.new("BlurEffect")
        _G.World.Blur.Parent = Lighting
        _G.World.Blur.Name = "CROW_Blur"
    end
    return _G.World.Blur
end

-- Function to create/get SunRays effect
local function getSunRays()
    if not _G.World.SunRays then
        _G.World.SunRays = Instance.new("SunRaysEffect")
        _G.World.SunRays.Parent = Lighting
        _G.World.SunRays.Name = "CROW_SunRays"
    end
    return _G.World.SunRays
end

-- Function to create/get Bloom effect
local function getBloom()
    if not _G.World.Bloom then
        _G.World.Bloom = Instance.new("BloomEffect")
        _G.World.Bloom.Parent = Lighting
        _G.World.Bloom.Name = "CROW_Bloom"
    end
    return _G.World.Bloom
end

-- Function to restore original lighting
local function restoreOriginalLighting()
    for property, value in pairs(_G.World.OriginalSettings) do
        if Lighting[property] ~= nil then
            Lighting[property] = value
        end
    end
end

-- Function to apply horizontal stretch
local function applyHorizontalStretch(intensity)
    if _G.World.StretchConnection then
        _G.World.StretchConnection:Disconnect()
        _G.World.StretchConnection = nil
    end
    
    if intensity > 1 then
        _G.World.StretchConnection = RunService.Heartbeat:Connect(function()
            local camera = workspace.CurrentCamera
            if camera then
                -- Apply horizontal stretch by modifying CFrame
                local cf = camera.CFrame
                camera.CFrame = cf * CFrame.new(0, 0, 0, intensity, 0, 0, 0, 1, 0, 0, 0, 1)
            end
        end)
    end
end

-- Function to disable horizontal stretch
local function disableHorizontalStretch()
    if _G.World.StretchConnection then
        _G.World.StretchConnection:Disconnect()
        _G.World.StretchConnection = nil
    end
end

-- Initialize original settings
storeOriginalSettings()

-- Flags that affect the game world; when loading a config we update UI only (nocallback) so the game is not auto-applied
_G.WorldConfigFlags = {
    FullBright = true, NoShadows = true, NoFog = true,
    WorldBrightness = true, WorldExposure = true,
    ColorCorrectionEnabled = true, CCBrightness = true, CCContrast = true, CCSaturation = true, CCTintColor = true,
    AmbientColor = true, FogColor = true, OutdoorAmbientColor = true,
    TimeOfDay = true,
    BlurEnabled = true, BlurSize = true,
    DepthOfFieldEnabled = true, DOFFocusDistance = true, DOFInFocusRadius = true, DOFFarIntensity = true, DOFNearIntensity = true,
    BloomEnabled = true, BloomIntensity = true, BloomSize = true, BloomThreshold = true,
    SunRaysEnabled = true, SunRaysIntensity = true, SunRaysSpread = true,
    SelectedSkybox = true, CustomSkybox = true,
}

-- UI Sections with improved safety checks
local LightingSection, ColorSection, VisualSection, UtilitySection

-- First, verify that _G.WorldTab exists
if not _G.WorldTab then
    _G.CROW:SendNotification("WorldTab not found! Make sure the main script is loaded first.", 5)
    return
end

-- Create sections with individual error handling
local function createSections()
    local success = true
    local errorMsg = ""
    
    -- Try to create each section individually
    local sectionSuccess, sectionError = pcall(function()
        LightingSection = _G.WorldTab:AddSection("Lighting Effects", 1)
    end)
    if not sectionSuccess then
        success = false
        errorMsg = errorMsg .. "LightingSection: " .. tostring(sectionError) .. " | "
    end
    
    sectionSuccess, sectionError = pcall(function()
        ColorSection = _G.WorldTab:AddSection("Color Effects", 1)
    end)
    if not sectionSuccess then
        success = false
        errorMsg = errorMsg .. "ColorSection: " .. tostring(sectionError) .. " | "
    end
    
    sectionSuccess, sectionError = pcall(function()
        UtilitySection = _G.WorldTab:AddSection("Utilities", 1)
    end)
    if not sectionSuccess then
        success = false
        errorMsg = errorMsg .. "UtilitySection: " .. tostring(sectionError) .. " | "
    end
    
    sectionSuccess, sectionError = pcall(function()
        VisualSection = _G.WorldTab:AddSection("Visual Effects", 2)
    end)
    if not sectionSuccess then
        success = false
        errorMsg = errorMsg .. "VisualSection: " .. tostring(sectionError) .. " | "
    end
    
    
    return success, errorMsg
end

local success, error = createSections()

if not success then
    _G.CROW:SendNotification("Failed to create World sections: " .. error, 5)
    return
end

-- Additional safety check - verify all sections were created
if not LightingSection then
    _G.CROW:SendNotification("LightingSection is nil!", 5)
    return
end

if not ColorSection then
    _G.CROW:SendNotification("ColorSection is nil!", 5)
    return
end

if not VisualSection then
    _G.CROW:SendNotification("VisualSection is nil!", 5)
    return
end

if not UtilitySection then
    _G.CROW:SendNotification("UtilitySection is nil!", 5)
    return
end

-- Defaults from current game state so UI matches game and we don't auto-apply on load
local orig = _G.World.OriginalSettings

-- ===================== LIGHTING EFFECTS =====================
LightingSection:AddSeparator({ text = "Basic Lighting" })

LightingSection:AddToggle({
    text = "Full Bright",
    state = false,
    flag = "FullBright",
    tooltip = "Makes everything fully visible",
    callback = function(state)
        if state then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
            Lighting.ColorShift_Top = Color3.new(1, 1, 1)
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.ShadowSoftness = 0
        else
            restoreOriginalLighting()
        end
    end
})

LightingSection:AddToggle({
    text = "No Shadows",
    state = not Lighting.GlobalShadows,
    flag = "NoShadows",
    tooltip = "Removes all shadows",
    callback = function(state)
        Lighting.GlobalShadows = not state
    end
})

LightingSection:AddToggle({
    text = "No Fog",
    state = (Lighting.FogEnd > 1e5 or Lighting.FogStart >= Lighting.FogEnd),
    flag = "NoFog",
    tooltip = "Removes all fog effects",
    callback = function(state)
        if state then
            Lighting.FogStart = 0
            Lighting.FogEnd = math.huge
        else
            Lighting.FogStart = _G.World.OriginalSettings.FogStart
            Lighting.FogEnd = _G.World.OriginalSettings.FogEnd
        end
    end
})

LightingSection:AddSlider({
    enabled = true,
    text = "Brightness",
    tooltip = "Adjust world brightness",
    flag = "WorldBrightness",
    suffix = "",
    min = 0,
    max = 5,
    increment = 0.1,
    default = orig.Brightness or 1,
    risky = false,
    callback = function(value)
        Lighting.Brightness = value
    end
})

LightingSection:AddSlider({
    enabled = true,
    text = "Exposure",
    tooltip = "Adjust exposure compensation",
    flag = "WorldExposure",
    suffix = "",
    min = -3,
    max = 3,
    increment = 0.1,
    default = orig.ExposureCompensation or 0,
    risky = false,
    callback = function(value)
        Lighting.ExposureCompensation = value
    end
})

-- ===================== COLOR EFFECTS =====================
ColorSection:AddSeparator({ text = "Color Correction" })

ColorSection:AddToggle({
    text = "Enable Color Correction",
    state = false,
    flag = "ColorCorrectionEnabled",
    tooltip = "Enable color correction effects",
    callback = function(state)
        local cc = getColorCorrection()
        cc.Enabled = state
    end
})

ColorSection:AddSlider({
    enabled = true,
    text = "Brightness",
    tooltip = "Color correction brightness",
    flag = "CCBrightness",
    suffix = "",
    min = -1,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local cc = getColorCorrection()
        cc.Brightness = value
    end
})

ColorSection:AddSlider({
    enabled = true,
    text = "Contrast",
    tooltip = "Color correction contrast",
    flag = "CCContrast",
    suffix = "",
    min = -1,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local cc = getColorCorrection()
        cc.Contrast = value
    end
})

ColorSection:AddSlider({
    enabled = true,
    text = "Saturation",
    tooltip = "Color correction saturation",
    flag = "CCSaturation",
    suffix = "",
    min = -1,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local cc = getColorCorrection()
        cc.Saturation = value
    end
})

ColorSection:AddColor({
    enabled = true,
    text = "Tint Color",
    tooltip = "Apply color tint to the world",
    color = Color3.fromRGB(255, 255, 255),
    flag = "CCTintColor",
    trans = 0,
    open = false,
    risky = false,
    callback = function(color)
        local cc = getColorCorrection()
        cc.TintColor = color
    end
})

ColorSection:AddSeparator({ text = "Lighting Colors" })

ColorSection:AddColor({
    enabled = true,
    text = "Ambient Color",
    tooltip = "Change ambient lighting color",
    color = orig.Ambient or Color3.fromRGB(128, 128, 128),
    flag = "AmbientColor",
    trans = 0,
    open = false,
    risky = false,
    callback = function(color)
        Lighting.Ambient = color
    end
})

ColorSection:AddColor({
    enabled = true,
    text = "Fog Color",
    tooltip = "Change fog color",
    color = orig.FogColor or Color3.fromRGB(192, 192, 192),
    flag = "FogColor",
    trans = 0,
    open = false,
    risky = false,
    callback = function(color)
        Lighting.FogColor = color
    end
})

ColorSection:AddColor({
    enabled = true,
    text = "Outdoor Ambient",
    tooltip = "Change outdoor ambient color",
    color = orig.OutdoorAmbient or Color3.fromRGB(128, 128, 128),
    flag = "OutdoorAmbientColor",
    trans = 0,
    open = false,
    risky = false,
    callback = function(color)
        Lighting.OutdoorAmbient = color
    end
})



-- =====================TIME OF DAY =====================
VisualSection:AddSeparator({ text = "Time of Day" })
VisualSection:AddSlider({
    enabled = true,
    text = "Time of Day",
    tooltip = "Change time of day",
    flag = "TimeOfDay",
    suffix = ":00",
    min = 0,
    max = 24,
    increment = 0.5,
    default = orig.ClockTime or 14,
    risky = false,
    callback = function(value)
        Lighting.ClockTime = value
    end
})
-- ===================== VISUAL EFFECTS =====================
VisualSection:AddSeparator({ text = "Screen Effects" })

VisualSection:AddToggle({
    text = "Blur Effect",
    state = false,
    flag = "BlurEnabled",
    tooltip = "Apply blur effect to screen",
    callback = function(state)
        local blur = getBlur()
        blur.Enabled = state
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Blur Size",
    tooltip = "Blur effect intensity",
    flag = "BlurSize",
    suffix = "",
    min = 0,
    max = 56,
    increment = 1,
    risky = false,
    callback = function(value)
        local blur = getBlur()
        blur.Size = value
    end
})

VisualSection:AddToggle({
    text = "Depth of Field",
    state = false,
    flag = "DepthOfFieldEnabled",
    tooltip = "Apply depth of field effect",
    callback = function(state)
        local dof = getDepthOfField()
        dof.Enabled = state
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Focus Distance",
    tooltip = "Depth of field focus distance",
    flag = "DOFFocusDistance",
    suffix = "",
    min = 0.1,
    max = 200,
    increment = 0.5,
    risky = false,
    callback = function(value)
        local dof = getDepthOfField()
        dof.FocusDistance = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "In Focus Radius",
    tooltip = "Depth of field in focus radius",
    flag = "DOFInFocusRadius",
    suffix = "",
    min = 1,
    max = 100,
    increment = 1,
    risky = false,
    callback = function(value)
        local dof = getDepthOfField()
        dof.InFocusRadius = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Far Intensity",
    tooltip = "Depth of field far blur intensity",
    flag = "DOFFarIntensity",
    suffix = "",
    min = 0,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local dof = getDepthOfField()
        dof.FarIntensity = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Near Intensity",
    tooltip = "Depth of field near blur intensity",
    flag = "DOFNearIntensity",
    suffix = "",
    min = 0,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local dof = getDepthOfField()
        dof.NearIntensity = value
    end
})

VisualSection:AddToggle({
    text = "Bloom Effect",
    state = false,
    flag = "BloomEnabled",
    tooltip = "Apply bloom glow effect",
    callback = function(state)
        local bloom = getBloom()
        bloom.Enabled = state
        if state then
            bloom.Intensity = 0.4
            bloom.Size = 24
            bloom.Threshold = 1.2
        end
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Bloom Intensity",
    tooltip = "Bloom effect intensity",
    flag = "BloomIntensity",
    suffix = "",
    min = 0,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local bloom = getBloom()
        bloom.Intensity = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Bloom Size",
    tooltip = "Bloom effect size",
    flag = "BloomSize",
    suffix = "",
    min = 1,
    max = 56,
    increment = 1,
    risky = false,
    callback = function(value)
        local bloom = getBloom()
        bloom.Size = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Bloom Threshold",
    tooltip = "Bloom effect threshold",
    flag = "BloomThreshold",
    suffix = "",
    min = 0,
    max = 2,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local bloom = getBloom()
        bloom.Threshold = value
    end
})

VisualSection:AddToggle({
    text = "Sun Rays",
    state = false,
    flag = "SunRaysEnabled",
    tooltip = "Apply sun rays effect",
    callback = function(state)
        local sunRays = getSunRays()
        sunRays.Enabled = state
        if state then
            sunRays.Intensity = 0.25
            sunRays.Spread = 1
        end
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Sun Rays Intensity",
    tooltip = "Sun rays effect intensity",
    flag = "SunRaysIntensity",
    suffix = "",
    min = 0,
    max = 1,
    increment = 0.01,
    risky = false,
    callback = function(value)
        local sunRays = getSunRays()
        sunRays.Intensity = value
    end
})

VisualSection:AddSlider({
    enabled = true,
    text = "Sun Rays Spread",
    tooltip = "Sun rays spread amount",
    flag = "SunRaysSpread",
    suffix = "",
    min = 0.1,
    max = 3,
    increment = 0.1,
    risky = false,
    callback = function(value)
        local sunRays = getSunRays()
        sunRays.Spread = value
    end
})




UtilitySection:AddSeparator({ text = "Restore & Remove" })

-- Restore and Remove first so they're easy to find
UtilitySection:AddButton({
    enabled = true,
    text = "Restore Original Settings",
    tooltip = "Reset all lighting to original values and sync UI",
    callback = function()
        restoreOriginalLighting()
        storeOriginalSettings()
        if _G.World.ColorCorrection then
            _G.World.ColorCorrection.Enabled = false
        end
        if _G.World.Blur then
            _G.World.Blur.Enabled = false
        end
        if _G.World.DepthOfField then
            _G.World.DepthOfField.Enabled = false
        end
        if _G.World.SunRays then
            _G.World.SunRays.Enabled = false
        end
        if _G.World.Bloom then
            _G.World.Bloom.Enabled = false
        end
        syncWorldUIFromLighting()
        _G.CROW:SendNotification("Original settings restored", 3)
    end
})

UtilitySection:AddButton({
    enabled = true,
    text = "Remove All Effects",
    tooltip = "Remove CROW-added effects from Lighting (Color Correction, Blur, DoF, etc.)",
    callback = function()
        if _G.World.ColorCorrection then
            _G.World.ColorCorrection:Destroy()
            _G.World.ColorCorrection = nil
        end
        if _G.World.Blur then
            _G.World.Blur:Destroy()
            _G.World.Blur = nil
        end
        if _G.World.DepthOfField then
            _G.World.DepthOfField:Destroy()
            _G.World.DepthOfField = nil
        end
        if _G.World.SunRays then
            _G.World.SunRays:Destroy()
            _G.World.SunRays = nil
        end
        if _G.World.Bloom then
            _G.World.Bloom:Destroy()
            _G.World.Bloom = nil
        end
        syncWorldUIFromLighting()
        _G.CROW:SendNotification("All effects removed", 3)
    end
})

UtilitySection:AddSeparator({ text = "Performance" })

UtilitySection:AddButton({
    enabled = true,
    text = "Potato Mode",
    tooltip = "Max performance: remove textures/decals, disable particles, full bright, no shadows/fog",
    callback = function()
        -- Lighting: full bright, no shadows, no fog
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ShadowSoftness = 0
        Lighting.FogStart = 0
        Lighting.FogEnd = math.huge
        -- Disable CROW post-effects
        if _G.World.Bloom then _G.World.Bloom.Enabled = false end
        if _G.World.Blur then _G.World.Blur.Enabled = false end
        if _G.World.DepthOfField then _G.World.DepthOfField.Enabled = false end
        if _G.World.SunRays then _G.World.SunRays.Enabled = false end
        if _G.World.ColorCorrection then _G.World.ColorCorrection.Enabled = false end
        -- Remove all Decals and Textures in workspace (genuinely remove textures)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj:Destroy() end)
            elseif obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            elseif obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("Trail") then
                obj.Enabled = false
            end
        end
        -- Lowest quality level
        pcall(function()
            if settings().Rendering and settings().Rendering.QualityLevel then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end
        end)
        syncWorldUIFromLighting()
        _G.CROW:SendNotification("Potato Mode applied (decals/textures removed)", 3)
    end
})

UtilitySection:AddSeparator({ text = "Skybox" })

local selectedSkybox = nil
local customSkyboxEnabled = false

local skyboxes = {
    ["Fog on the Water"] = {
        SkyboxBk = "15876597103",
        SkyboxDn = "15876592775",
        SkyboxFt = "15876640231",
        SkyboxLf = "15876638420",
        SkyboxRt = "15876595486",
        SkyboxUp = "15876639348"
    },
    ["Sunset"] = {
        SkyboxBk = "600830446",
        SkyboxDn = "600831635",
        SkyboxFt = "600832720",
        SkyboxLf = "600886090",
        SkyboxRt = "600833862",
        SkyboxUp = "600835177"
    },
    ["Space"] = {
        SkyboxBk = "14270181284",
        SkyboxDn = "14270179389",
        SkyboxFt = "14270177253",
        SkyboxLf = "14270175047",
        SkyboxRt = "14270172896",
        SkyboxUp = "14270170618"
    },
    ["Purple Nebula"] = {
        SkyboxBk = "159454299",
        SkyboxDn = "159454296",
        SkyboxFt = "159454293",
        SkyboxLf = "159454286",
        SkyboxRt = "159454300",
        SkyboxUp = "159454288"
    },
    ["Vaporwave"] = {
        SkyboxBk = "1417494030",
        SkyboxDn = "1417494146",
        SkyboxFt = "1417494253",
        SkyboxLf = "1417494402",
        SkyboxRt = "1417494499",
        SkyboxUp = "1417494643"
    },
    ["Night Sky"] = {
        SkyboxBk = "12064107",
        SkyboxDn = "12064152",
        SkyboxFt = "12064121",
        SkyboxLf = "12064115",
        SkyboxRt = "12064131",
        SkyboxUp = "12064130"
    },
    ["Ocean"] = {
        SkyboxBk = "570557620",
        SkyboxDn = "570557729",
        SkyboxFt = "570557799",
        SkyboxLf = "570557860",
        SkyboxRt = "570557934",
        SkyboxUp = "570558017"
    },
    ["Desert"] = {
        SkyboxBk = "323493360",
        SkyboxDn = "323494035",
        SkyboxFt = "323494143",
        SkyboxLf = "323494252",
        SkyboxRt = "323494381",
        SkyboxUp = "323494503"
    }
}

local skyboxList = {"Fog on the Water", "Sunset", "Space", "Purple Nebula", "Vaporwave", "Night Sky", "Ocean", "Desert"}

local function applySkybox(skyboxData)
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://" .. skyboxData.SkyboxBk
    sky.SkyboxDn = "rbxassetid://" .. skyboxData.SkyboxDn
    sky.SkyboxFt = "rbxassetid://" .. skyboxData.SkyboxFt
    sky.SkyboxLf = "rbxassetid://" .. skyboxData.SkyboxLf
    sky.SkyboxRt = "rbxassetid://" .. skyboxData.SkyboxRt
    sky.SkyboxUp = "rbxassetid://" .. skyboxData.SkyboxUp
    sky.Parent = Lighting
end

UtilitySection:AddList({
    enabled = true,
    text = "Skybox Selector",
    default = "",
    tooltip = "Choose a predefined skybox",
    multi = false,
    open = false,
    max = 5,
    values = skyboxList,
    risky = false,
    flag = "SelectedSkybox",
    callback = function(selectedName)
        if skyboxes[selectedName] then
            selectedSkybox = skyboxes[selectedName]
            if customSkyboxEnabled then
                applySkybox(selectedSkybox)
            end
        else
            selectedSkybox = nil
        end
    end
})

UtilitySection:AddToggle({
    text = "Custom Skybox",
    state = false,
    flag = "CustomSkybox",
    tooltip = "Enable custom skybox from selector",
    callback = function(state)
        customSkyboxEnabled = state
        if state then
            local lib = _G.library or _G.CROW
            local currentSelected = (lib and lib.flags and lib.flags.SelectedSkybox) or (_G.Flags and _G.Flags.SelectedSkybox)
            if currentSelected and skyboxes[currentSelected] then
                selectedSkybox = skyboxes[currentSelected]
                applySkybox(selectedSkybox)
            elseif selectedSkybox then
                applySkybox(selectedSkybox)
            end
        end
    end
})





-- Sync World tab UI to current Lighting state (call after restore so toggles/sliders match game)
local function syncWorldUIFromLighting()
    local lib = _G.library or _G.CROW
    if not lib or not lib.options then return end
    local opt = lib.options
    local function set(flag, value, kind)
        local o = opt[flag]
        if not o or not o.class then return end
        if kind == "toggle" and o.SetState then pcall(function() o:SetState(value == true, true) end) end
        if kind == "slider" and o.SetValue then pcall(function() o:SetValue(value, true) end) end
        if kind == "color" and o.SetColor then pcall(function() o:SetColor(value, true) end) end
    end
    set("FullBright", false, "toggle")
    set("NoShadows", not Lighting.GlobalShadows, "toggle")
    set("NoFog", Lighting.FogEnd > 1e5 or Lighting.FogStart >= Lighting.FogEnd, "toggle")
    set("WorldBrightness", Lighting.Brightness, "slider")
    set("WorldExposure", Lighting.ExposureCompensation, "slider")
    set("ColorCorrectionEnabled", false, "toggle")
    set("AmbientColor", Lighting.Ambient, "color")
    set("FogColor", Lighting.FogColor, "color")
    set("OutdoorAmbientColor", Lighting.OutdoorAmbient, "color")
    set("TimeOfDay", Lighting.ClockTime, "slider")
    set("BlurEnabled", false, "toggle")
    set("DepthOfFieldEnabled", false, "toggle")
    set("BloomEnabled", false, "toggle")
    set("SunRaysEnabled", false, "toggle")
    set("CustomSkybox", false, "toggle")
end

-- Cleanup function (safe: no dependency on undefined toggleWidescreen/restoreOriginalFOV)
_G.World.Cleanup = function()
    restoreOriginalLighting()
    storeOriginalSettings()
    pcall(function() if type(toggleWidescreen) == "function" then toggleWidescreen(false) end end)
    pcall(function() if type(restoreOriginalFOV) == "function" then restoreOriginalFOV() end end)
    if _G.World.ColorCorrection then
        _G.World.ColorCorrection:Destroy()
        _G.World.ColorCorrection = nil
    end
    if _G.World.Blur then
        _G.World.Blur:Destroy()
        _G.World.Blur = nil
    end
    if _G.World.DepthOfField then
        _G.World.DepthOfField:Destroy()
        _G.World.DepthOfField = nil
    end
    if _G.World.SunRays then
        _G.World.SunRays:Destroy()
        _G.World.SunRays = nil
    end
    if _G.World.Bloom then
        _G.World.Bloom:Destroy()
        _G.World.Bloom = nil
    end
    syncWorldUIFromLighting()
    _G.CROW:SendNotification("World section cleaned up", 2)
end
