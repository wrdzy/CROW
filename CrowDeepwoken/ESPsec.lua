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

-- Library reference for flags (Drawing UI stores flags on _G.CROW / _G.library)
local library = (getgenv and getgenv()) and ((getgenv().CROW or getgenv().library)) or (_G.CROW or _G.library)
if not library or not library.flags then
    warn("[ESPsec] Library or library.flags not found; ESP toggles may not work until UI is ready.")
end

-- Override ESPSettings from config (nothing hardcoded; config wins)
do
    local cfg = (_G.CROW_ESPSettings) or (library and library.config and library.config.ESP)
    if cfg and type(cfg) == "table" then
        for k, v in pairs(cfg) do if v ~= nil then ESPSettings[k] = v end end
    end
    local cfg2 = (_G.CROW_ESPConfig) or (library and library.config and library.config.ESPConfig)
    if cfg2 and type(cfg2) == "table" then
        if cfg2.VISIBILITY_CACHE_INTERVAL ~= nil then VISIBILITY_CACHE_INTERVAL = cfg2.VISIBILITY_CACHE_INTERVAL end
        if cfg2.WORLD_CACHE_INTERVAL ~= nil then WORLD_CACHE_INTERVAL = cfg2.WORLD_CACHE_INTERVAL end
        if cfg2.ESP_SETTINGS_SYNC_INTERVAL ~= nil then ESP_SETTINGS_SYNC_INTERVAL = cfg2.ESP_SETTINGS_SYNC_INTERVAL end
    end
end

-- Sync ESPSettings from flags so Load/Save config applies (flags are the source of truth after load)
local function syncESPSettingsFromFlags(flags)
    if not flags then return end
    local num = function(k) local v = flags[k]; return type(v) == "number" and v or nil end
    local col = function(k) local v = flags[k]; return (v ~= nil and (type(v) == "userdata" or type(v) == "table")) and v or nil end
    if num("BoxThickness") then ESPSettings.BoxThickness = flags["BoxThickness"] end
    if num("TextSize") then ESPSettings.TextSize = flags["TextSize"] end
    if num("HealthBarWidth") then ESPSettings.HealthBarWidth = flags["HealthBarWidth"] end
    if num("HealthBarOffset") then ESPSettings.HealthBarOffset = flags["HealthBarOffset"] end
    if num("SkeletonThickness") then ESPSettings.SkeletonThickness = flags["SkeletonThickness"] end
    if num("TracerThickness") then ESPSettings.TracerThickness = flags["TracerThickness"] end
    if num("ESPScale") then ESPSettings.ESPScale = (flags["ESPScale"] or 100) / 100 end
    if num("ESPMaxDistance") then ESPSettings.MaxDistance = flags["ESPMaxDistance"] end
    if num("ClusterRange") then ESPSettings.ClusterRange = flags["ClusterRange"] end
    if num("NameTextOffset") then ESPSettings.NameTextOffset = flags["NameTextOffset"] end
    if num("DistanceTextOffset") then ESPSettings.DistanceTextOffset = flags["DistanceTextOffset"] end
    if num("VisibilityTextOffset") then ESPSettings.VisibilityTextOffset = flags["VisibilityTextOffset"] end
    if flags["TracerOrigin"] then ESPSettings.TracerOrigin = flags["TracerOrigin"] end
    if col("ESPTextColor") then ESPSettings.TextColor = flags["ESPTextColor"] end
    if col("AllyColor") then ESPSettings.AllyColor = flags["AllyColor"] end
    if col("EnemyColor") then ESPSettings.EnemyColor = flags["EnemyColor"] end
    if col("SkeletonColor") then ESPSettings.SkeletonColor = flags["SkeletonColor"] end
    if col("TracerColor") then ESPSettings.TracerColor = flags["TracerColor"] end
    if col("IngredientsColor") then ESPSettings.IngredientsColor = flags["IngredientsColor"] end
    if col("NPCsColor") then ESPSettings.NPCsColor = flags["NPCsColor"] end
    if col("MobsColor") then ESPSettings.MobsColor = flags["MobsColor"] end
end

-- Create ESP sections
local secesp = _G.ESPTab:AddSection("ESP", 1)
local seccustomesp = _G.ESPTab:AddSection("Customise ESP", 2)

-- Store references to all UI elements and ESP objects
local ESPObjects = {}
local WorldESPObjects = {} -- [instance] = { Name, Distance [, HP for mobs] }

-- Tunable constants: no frame cap on ESP; update every frame (override via _G.CROW_ESPConfig or library.config.ESPConfig)
local VISIBILITY_CACHE_INTERVAL = 0
local ESP_SETTINGS_SYNC_INTERVAL = 3
local WORLD_CACHE_INTERVAL = 0

-- Store current settings values with defaults; overridden by _G.CROW_ESPSettings or library.config.ESP; synced from flags when config is loaded
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
    MaxDistance = 500,
    IngredientsColor = Color3.fromRGB(200, 200, 100),
    NPCsColor = Color3.fromRGB(100, 200, 255),
    MobsColor = Color3.fromRGB(255, 120, 80),
    ClusterRange = 25
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

secesp:AddSeparator({ text = "World" })

local ShowIngredients = secesp:AddToggle({
    text = "Show Ingredients",
    state = false,
    tooltip = "ESP for parts in workspace.Ingredients",
    flag = "ShowIngredients"
})

local ShowNPCs = secesp:AddToggle({
    text = "Show NPCs",
    state = false,
    tooltip = "ESP for models in workspace.NPCs",
    flag = "ShowNPCs"
})

local ShowMobs = secesp:AddToggle({
    text = "Show Mobs (Live)",
    state = false,
    tooltip = "ESP for mobs in workspace.Live (names cleaned: no leading ., no trailing numbers)",
    flag = "ShowMobs"
})

-- Multi-select: which specific ingredients/NPCs/mobs to show (empty = show all when toggle on)
secesp:AddSeparator({ text = "Filter by name" })

local worldIngredientsList = secesp:AddList({
    text = "Ingredients",
    selected = {},
    multi = true,
    values = { "(Click Refresh)" },
    flag = "SelectedWorldIngredients",
    tooltip = "Select which ingredients to show. Refresh uses names already seen by ESP (no scan on click)."
})
secesp:AddButton({
    text = "Refresh Ingredients",
    callback = function()
        local ingNames = {}
        for k in pairs(cachedIngredientNames) do ingNames[#ingNames + 1] = k end
        table.sort(ingNames)
        if worldIngredientsList and worldIngredientsList.ClearValues then worldIngredientsList:ClearValues() end
        if #ingNames == 0 and worldIngredientsList and worldIngredientsList.AddValue then worldIngredientsList:AddValue("(None seen yet - enable Show Ingredients and wait)") end
        for _, n in ipairs(ingNames) do if worldIngredientsList and worldIngredientsList.AddValue then worldIngredientsList:AddValue(n) end end
    end
})

local worldNPCsList = secesp:AddList({
    text = "NPCs",
    selected = {},
    multi = true,
    values = { "(Click Refresh)" },
    flag = "SelectedWorldNPCs",
    tooltip = "Select which NPCs to show. Refresh uses names already seen by ESP (no scan on click)."
})
secesp:AddButton({
    text = "Refresh NPCs",
    callback = function()
        local npcNames = {}
        for k in pairs(cachedNPCNames) do npcNames[#npcNames + 1] = k end
        table.sort(npcNames)
        if worldNPCsList and worldNPCsList.ClearValues then worldNPCsList:ClearValues() end
        if #npcNames == 0 and worldNPCsList and worldNPCsList.AddValue then worldNPCsList:AddValue("(None seen yet - enable Show NPCs and wait)") end
        for _, n in ipairs(npcNames) do if worldNPCsList and worldNPCsList.AddValue then worldNPCsList:AddValue(n) end end
    end
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

-- IsEnemy: enemy list only (no teams). Used by ESP and AimSec.
local function isEnemy(player)
    return player and player ~= LocalPlayer and EnemyList[player] == true
end
_G.CROW_IsEnemy = isEnemy

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

seccustomesp:AddSeparator({ text = "World ESP Colors" })

local IngredientsColor = seccustomesp:AddColor({
    text = "Ingredients Color",
    tooltip = "Color for ingredient ESP text",
    color = ESPSettings.IngredientsColor,
    flag = "IngredientsColor",
    trans = 0,
    callback = function(color)
        ESPSettings.IngredientsColor = color or ESPSettings.IngredientsColor
    end
})

local NPCsColorPicker = seccustomesp:AddColor({
    text = "NPCs Color",
    tooltip = "Color for NPC ESP text",
    color = ESPSettings.NPCsColor,
    flag = "NPCsColor",
    trans = 0,
    callback = function(color)
        ESPSettings.NPCsColor = color or ESPSettings.NPCsColor
    end
})

local MobsColorPicker = seccustomesp:AddColor({
    text = "Mobs Color",
    tooltip = "Color for mob ESP text (name, distance, HP)",
    color = ESPSettings.MobsColor,
    flag = "MobsColor",
    trans = 0,
    callback = function(color)
        ESPSettings.MobsColor = color or ESPSettings.MobsColor
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

-- Health Bar Width Slider
local HealthBarWidth = seccustomesp:AddSlider({
    text = "Health Bar Width",
    min = 2,
    max = 8,
    default = 4,
    increment = 1,
    suffix = "px",
    tooltip = "Adjust the width of health bars",
    flag = "HealthBarWidth",
    callback = function(value)
        ESPSettings.HealthBarWidth = value or 4
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

-- Cluster Range (ingredients/mobs within this many studs show as "Name x count")
seccustomesp:AddSlider({
    text = "Cluster Range",
    min = 10,
    max = 80,
    default = 25,
    increment = 5,
    suffix = " studs",
    tooltip = "Group ingredients/mobs within this range and show count (e.g. Iron Ore x3)",
    flag = "ClusterRange",
    callback = function(value)
        ESPSettings.ClusterRange = value
    end
})

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

-- Clean Live mob name: strip leading ".", strip trailing digits (e.g. ".carbuncle2" -> "carbuncle")
local function cleanLiveMobName(name)
    if not name or type(name) ~= "string" then return "?" end
    local s = name:gsub("^%.", ""):gsub("%d+$", "")
    return s ~= "" and s or name
end

-- Get world position from a Part, Model, or container (e.g. Folder with parts)
local function getWorldPosition(inst)
    if inst:IsA("BasePart") then
        return inst.Position
    end
    if inst:IsA("Model") then
        local pp = inst.PrimaryPart
        if pp then return pp.Position end
        local ok, pos = pcall(function() return inst:GetPivot().Position end)
        if ok and pos then return pos end
        local first = inst:FindFirstChildWhichIsA("BasePart")
        if first then return first.Position end
    end
    local first = inst:FindFirstChildWhichIsA("BasePart", true)
    if first then return first.Position end
    return nil
end

-- Create world ESP: text only (Name, Distance; mobs also get HP). Key = string (clusterKey) or instance.
local function createWorldESP(key, displayName, category, count, primaryInstance)
    if WorldESPObjects[key] then return end
    local isMob = (category == "mobs")
    local success, data = pcall(function()
        local d = {
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text")
        }
        if isMob then
            d.HP = Drawing.new("Text")
        end
        return d
    end)
    if not success then return end
    local textSize = ESPSettings.TextSize
    data.Name.Size = textSize
    data.Name.Center = true
    data.Name.Outline = true
    data.Name.OutlineColor = Color3.new(0, 0, 0)
    data.Name.Font = Drawing.Fonts.UI
    data.Name.Visible = false
    data.Name.Text = (count and count > 1) and (displayName .. " x" .. tostring(count)) or (displayName or "")
    data.Distance.Size = textSize
    data.Distance.Center = true
    data.Distance.Outline = true
    data.Distance.OutlineColor = Color3.new(0, 0, 0)
    data.Distance.Font = Drawing.Fonts.UI
    data.Distance.Visible = false
    if data.HP then
        data.HP.Size = textSize
        data.HP.Center = true
        data.HP.Outline = true
        data.HP.OutlineColor = Color3.new(0, 0, 0)
        data.HP.Font = Drawing.Fonts.UI
        data.HP.Visible = false
    end
    WorldESPObjects[key] = data
end

local function removeWorldESP(instance)
    local data = WorldESPObjects[instance]
    if not data then return end
    for _, obj in pairs(data) do
        if obj and obj.Remove then obj:Remove() end
    end
    WorldESPObjects[instance] = nil
end

-- Collect current world objects: Ingredients (parts), NPCs (models), Live (mobs with cleaned names)
local function getWorldObjects()
    local list = {}
    local ingredients = workspace:FindFirstChild("Ingredients")
    if ingredients then
        for _, child in ipairs(ingredients:GetChildren()) do
            if child:IsA("BasePart") then
                local pos = getWorldPosition(child)
                if pos then list[#list + 1] = { instance = child, position = pos, displayName = child.Name, category = "ingredients" } end
            end
        end
    end
    local npcs = workspace:FindFirstChild("NPCs")
    if npcs then
        for _, child in ipairs(npcs:GetChildren()) do
            if child:IsA("Model") then
                local pos = getWorldPosition(child)
                if pos then list[#list + 1] = { instance = child, position = pos, displayName = child.Name, category = "npcs" } end
            end
        end
    end
    local live = workspace:FindFirstChild("Live")
    if live then
        for _, child in ipairs(live:GetChildren()) do
            -- Exclude ALL player characters (any model that is a Player's character)
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                local playerFromChar = Players:GetPlayerFromCharacter(child)
                if playerFromChar ~= nil then
                    continue
                end
            end
            local pos = getWorldPosition(child)
            if pos then
                local displayName = cleanLiveMobName(child.Name)
                list[#list + 1] = { instance = child, position = pos, displayName = displayName, category = "mobs" }
            end
        end
    end
    return list
end

-- Cluster ingredients and mobs (same category+name within ClusterRange) into single entries with count
local function clusterWorldObjects(rawList)
    local rangeSq = (ESPSettings.ClusterRange or 25) ^ 2
    local clusters = {}
    local used = {}
    for i, entry in ipairs(rawList) do
        if used[i] then continue end
        local cat, name = entry.category, entry.displayName
        local clusterable = (cat == "ingredients" or cat == "mobs")
        if not clusterable then
            clusters[#clusters + 1] = { key = cat.."|"..name.."|"..tostring(entry.position.X).."|"..tostring(entry.position.Z), position = entry.position, displayName = name, category = cat, count = 1, primaryInstance = entry.instance }
            continue
        end
        local group = { entry }
        used[i] = true
        for j = i + 1, #rawList do
            if used[j] then continue end
            local o = rawList[j]
            if o.category ~= cat or o.displayName ~= name then continue end
            local dx = o.position.X - entry.position.X
            local dy = o.position.Y - entry.position.Y
            local dz = o.position.Z - entry.position.Z
            if dx*dx + dy*dy + dz*dz <= rangeSq then
                group[#group + 1] = o
                used[j] = true
            end
        end
        local cx, cy, cz = 0, 0, 0
        for _, g in ipairs(group) do
            cx = cx + g.position.X
            cy = cy + g.position.Y
            cz = cz + g.position.Z
        end
        local n = #group
        cx, cy, cz = cx / n, cy / n, cz / n
        local key = string.format("%s|%s|%.0f|%.0f", cat, name, cx, cz)
        clusters[#clusters + 1] = { key = key, position = Vector3.new(cx, cy, cz), displayName = name, category = cat, count = n, primaryInstance = group[1].instance }
    end
    return clusters
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
    for _, data in pairs(WorldESPObjects) do
        if data.Name then data.Name.Size = ESPSettings.TextSize end
        if data.Distance then data.Distance.Size = ESPSettings.TextSize end
        if data.HP then data.HP.Size = ESPSettings.TextSize end
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
local cachedWorldClusters = {}
local cachedWorldClustersTime = 0
-- Names seen by ESP (filled when world list is refreshed); Refresh buttons use this only - no workspace scan on click (avoids ban)
local cachedIngredientNames = {}
local cachedNPCNames = {}
local cachedMobNames = {}

-- Unframecapped: update every frame; heavy work (world list, visibility raycasts) stays cached
RunService.RenderStepped:Connect(function(delta)
    local lib = library or _G.CROW or _G.library
    if not lib or not lib.flags then return end
    if not lib.flags["ShowESP"] then
        if lastESPShow then
            for _, data in pairs(ESPObjects) do setESPDataVisible(data, false) end
            for _, data in pairs(WorldESPObjects) do setESPDataVisible(data, false) end
            lastESPShow = false
        end
        return
    end
    lastESPShow = true

    local flags = lib.flags
    syncESPSettingsFromFlags(flags)
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

    for player, data in pairs(ESPObjects) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if not (player:IsA("Player") and character and hrp and humanoid and humanoid.Health > 0) then
            setESPDataVisible(data, false)
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local maxDist = ESPSettings.MaxDistance or 0
        if maxDist > 0 and distance > maxDist then
            setESPDataVisible(data, false)
            continue
        end
        local scale = math.clamp(1 / (distance / 50), 0.5, 2) * ESPSettings.ESPScale
        local boxW, boxH = 50 * scale, 100 * scale
        local boxX, boxY = pos.X - boxW / 2, pos.Y - boxH / 2

        -- Color by enemy list only (no teams)
        local color = (EnemyList[player] and ESPSettings.EnemyColor) or ESPSettings.AllyColor

        if flags["ESPBox"] and data.Box then
            data.Box.Position = Vector2.new(boxX, boxY)
            data.Box.Size = Vector2.new(boxW, boxH)
            data.Box.Color = color
            data.Box.Thickness = ESPSettings.BoxThickness
            data.Box.Visible = onScreen
        elseif data.Box then
            data.Box.Visible = false
        end

        if flags["ShowHealthBar"] and data.HealthOutline and data.HealthBar then
            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barWidth = ESPSettings.HealthBarWidth
            local state = HealthBarStates[player]
            state.CurrentHeight = state.CurrentHeight + (healthRatio - state.CurrentHeight) * math.min(10 * delta, 1)
            
            data.HealthOutline.Position = Vector2.new(boxX - barWidth - ESPSettings.HealthBarOffset, boxY)
            data.HealthOutline.Size = Vector2.new(barWidth, boxH)
            data.HealthOutline.Visible = onScreen

            data.HealthBar.Position = Vector2.new(boxX - barWidth - ESPSettings.HealthBarOffset, boxY + (1 - state.CurrentHeight) * boxH)
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
            data.Distance.Position = Vector2.new(pos.X, boxY + boxH + ESPSettings.DistanceTextOffset)
            data.Distance.Color = textColor
            data.Distance.Size = ESPSettings.TextSize
            data.Distance.Visible = onScreen
        elseif data.Distance then
            data.Distance.Visible = false
        end
        
        if flags["ShowNames"] and data.Name then
            data.Name.Text = player.Name
            data.Name.Position = Vector2.new(pos.X, boxY - ESPSettings.NameTextOffset)
            data.Name.Color = textColor
            data.Name.Size = ESPSettings.TextSize
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
            local yOffset = flags["ShowDistance"] and ESPSettings.DistanceTextOffset + ESPSettings.TextSize + ESPSettings.VisibilityTextOffset or ESPSettings.VisibilityTextOffset
            
            data.Visibility.Text = visText
            data.Visibility.Position = Vector2.new(pos.X, boxY + boxH + yOffset)
            data.Visibility.Color = textColor
            data.Visibility.Size = ESPSettings.TextSize
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
            local toolYOff = ESPSettings.DistanceTextOffset + ESPSettings.TextSize + 4
            if flags["ShowVisibility"] then
                toolYOff = toolYOff + ESPSettings.TextSize + ESPSettings.VisibilityTextOffset
            end
            data.Tool.Position = Vector2.new(pos.X, boxY + boxH + toolYOff)
            data.Tool.Color = textColor
            data.Tool.Size = ESPSettings.TextSize
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
                
                data.Skeleton.HeadTorso.From = Vector2.new(headPos.X, headPos.Y)
                data.Skeleton.HeadTorso.To = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.HeadTorso.Color = ESPSettings.SkeletonColor
                data.Skeleton.HeadTorso.Visible = onScreen

                if bodyParts.LeftUpperArm then
                    local armPos = Camera:WorldToViewportPoint(bodyParts.LeftUpperArm.Position)
                    data.Skeleton.TorsoLeftArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoLeftArm.To = Vector2.new(armPos.X, armPos.Y)
                    data.Skeleton.TorsoLeftArm.Color = ESPSettings.SkeletonColor
                    data.Skeleton.TorsoLeftArm.Visible = onScreen
                else
                    data.Skeleton.TorsoLeftArm.Visible = false
                end

                if bodyParts.RightUpperArm then
                    local armPos = Camera:WorldToViewportPoint(bodyParts.RightUpperArm.Position)
                    data.Skeleton.TorsoRightArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoRightArm.To = Vector2.new(armPos.X, armPos.Y)
                    data.Skeleton.TorsoRightArm.Color = ESPSettings.SkeletonColor
                    data.Skeleton.TorsoRightArm.Visible = onScreen
                else
                    data.Skeleton.TorsoRightArm.Visible = false
                end

                if bodyParts.LeftLowerLeg then
                    local legPos = Camera:WorldToViewportPoint(bodyParts.LeftLowerLeg.Position)
                    data.Skeleton.TorsoLeftLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoLeftLeg.To = Vector2.new(legPos.X, legPos.Y)
                    data.Skeleton.TorsoLeftLeg.Color = ESPSettings.SkeletonColor
                    data.Skeleton.TorsoLeftLeg.Visible = onScreen
                else
                    data.Skeleton.TorsoLeftLeg.Visible = false
                end

                if bodyParts.RightLowerLeg then
                    local legPos = Camera:WorldToViewportPoint(bodyParts.RightLowerLeg.Position)
                    data.Skeleton.TorsoRightLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.TorsoRightLeg.To = Vector2.new(legPos.X, legPos.Y)
                    data.Skeleton.TorsoRightLeg.Color = ESPSettings.SkeletonColor
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
            data.Tracer.Color = ESPSettings.TracerColor
            data.Tracer.Thickness = ESPSettings.TracerThickness
            data.Tracer.Visible = onScreen
        elseif data.Tracer then
            data.Tracer.Visible = false
        end
    end

    -- World ESP: use cached clustered list, refresh every WORLD_CACHE_INTERVAL to reduce lag
    local now = tick()
    if now - cachedWorldClustersTime >= WORLD_CACHE_INTERVAL then
        cachedWorldClustersTime = now
        local rawList = getWorldObjects()
        cachedWorldClusters = clusterWorldObjects(rawList)
        -- Update name caches so Refresh buttons can repopulate dropdowns without scanning workspace (avoids ban on Live etc.)
        for _, entry in ipairs(rawList) do
            if entry.displayName and entry.displayName ~= "" then
                if entry.category == "ingredients" then cachedIngredientNames[entry.displayName] = true
                elseif entry.category == "npcs" then cachedNPCNames[entry.displayName] = true
                elseif entry.category == "mobs" then cachedMobNames[entry.displayName] = true
                end
            end
        end
    end
    local worldList = cachedWorldClusters
    local worldCurrentSet = {}
    for _, w in ipairs(worldList) do worldCurrentSet[w.key] = true end
    for key in pairs(WorldESPObjects) do
        if not worldCurrentSet[key] then removeWorldESP(key) end
    end
    local selectedIng = flags["SelectedWorldIngredients"]
    local selectedNpc = flags["SelectedWorldNPCs"]
    local placeholders = { ["(Click Refresh)"] = true, ["(None in workspace)"] = true, ["(None seen yet - enable Show Ingredients and wait)"] = true, ["(None seen yet - enable Show NPCs and wait)"] = true }
    local function nameInSelection(displayName, sel)
        if not sel or (type(sel) == "table" and #sel == 0) then return true end
        local list = type(sel) == "table" and sel or { sel }
        local hasReal = false
        for _, n in ipairs(list) do
            if n and not placeholders[n] then
                hasReal = true
                if n == displayName then return true end
            end
        end
        return not hasReal
    end
    for _, w in ipairs(worldList) do
        local catShow = (w.category == "ingredients" and flags["ShowIngredients"]) or (w.category == "npcs" and flags["ShowNPCs"]) or (w.category == "mobs" and flags["ShowMobs"])
        local filterOk = (w.category == "ingredients" and nameInSelection(w.displayName, selectedIng)) or (w.category == "npcs" and nameInSelection(w.displayName, selectedNpc)) or (w.category == "mobs")
        local show = catShow and filterOk
        if not show then
            local data = WorldESPObjects[w.key]
            if data then setESPDataVisible(data, false) end
        else
            local distance = (Camera.CFrame.Position - w.position).Magnitude
            local maxDist = ESPSettings.MaxDistance or 0
            if maxDist > 0 and distance > maxDist then
                local data = WorldESPObjects[w.key]
                if data then setESPDataVisible(data, false) end
            else
                if not WorldESPObjects[w.key] then createWorldESP(w.key, w.displayName, w.category, w.count, w.primaryInstance) end
                local data = WorldESPObjects[w.key]
                if not data then continue end
                local pos, onScreen = Camera:WorldToViewportPoint(w.position)
                local textSize = ESPSettings.TextSize
                local lineHeight = textSize + 2
                local categoryColor = (w.category == "ingredients" and ESPSettings.IngredientsColor) or (w.category == "npcs" and ESPSettings.NPCsColor) or ESPSettings.MobsColor
                data.Name.Text = (w.count and w.count > 1) and (w.displayName .. " x" .. tostring(w.count)) or w.displayName
                data.Name.Position = Vector2.new(pos.X, pos.Y)
                data.Name.Color = categoryColor
                data.Name.Size = textSize
                data.Name.Visible = onScreen
                data.Distance.Text = "[" .. math.floor(distance) .. "]"
                data.Distance.Position = Vector2.new(pos.X, pos.Y + lineHeight)
                data.Distance.Color = categoryColor
                data.Distance.Size = textSize
                data.Distance.Visible = onScreen
                local hpInstance = w.primaryInstance or w.instance
                if data.HP and w.category == "mobs" and hpInstance then
                    local humanoid = hpInstance:FindFirstChildOfClass("Humanoid") or hpInstance:FindFirstChild("Humanoid")
                    if humanoid then
                        data.HP.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                        data.HP.Position = Vector2.new(pos.X, pos.Y + lineHeight * 2)
                        data.HP.Color = categoryColor
                        data.HP.Size = textSize
                        data.HP.Visible = onScreen
                    else
                        data.HP.Visible = false
                    end
                elseif data.HP then
                    data.HP.Visible = false
                end
            end
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
