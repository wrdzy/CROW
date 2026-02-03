-- AdminPanel.lua - Comprehensive Admin Panel for CROW
-- This file should be hosted at: https://raw.githubusercontent.com/wrdzy/CROWui/main/AdminPanel.lua

if not _G.isAdmin then
    return
end

if _G.CROW and _G.CROW.SendNotification then
    _G.CROW:SendNotification("Loading Admin Panel...", 3)
end

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Admin Panel Variables
_G.AdminPanel = _G.AdminPanel or {}
_G.AdminPanel.BlacklistCache = {}
_G.AdminPanel.RefreshInProgress = false
_G.AdminPanel.AutoRefresh = false
_G.AdminPanel.MonitoringPlayers = false

-- UI Sections
local MainSection = _G.AdminTab:AddSection("Admin Controls", 1)
local BlacklistSection = _G.AdminTab:AddSection("Blacklist Management", 1)
local PlayerSection = _G.AdminTab:AddSection("Player Monitoring", 2)
local ServerSection = _G.AdminTab:AddSection("Server Management", 2)

-- ===================== MAIN ADMIN CONTROLS =====================
MainSection:AddSeparator({ text = "Admin Information" })

-- Admin Info Dropdown
MainSection:AddList({
    enabled = true,
    text = "Admin Information",
    tooltip = "View admin panel and user information",
    selected = {},
    multi = true,
    open = false,
    max = 4,
    values = {
        "Panel Version: v1.0.5",
        "Admin ID: " .. tostring(_G.userId),
        "Total Admins: " .. #_G.Admins,
        "Blacklisted Players: Loading..."
    },
    flag = "AdminInfoSelection",
    risky = false,
    callback = function(selected)
        for _, info in pairs(selected) do
            _G.CROW:SendNotification(info, 3)
        end
    end
})

MainSection:AddSeparator({ text = "Quick Actions" })

-- Quick Actions Dropdown
MainSection:AddList({
    enabled = true,
    text = "Quick Actions",
    tooltip = "Select actions to perform",
    selected = {},
    multi = true,
    open = false,
    max = 4,
    values = {
        "Refresh All Data",
        "Refresh Blacklist Only",
        "Update Player List",
        "Check Server Status"
    },
    flag = "QuickActionsSelection",
    risky = false,
    callback = function(selected)
        for _, action in pairs(selected) do
            if action == "Refresh All Data" then
                refreshAllData()
            elseif action == "Refresh Blacklist Only" then
                refreshBlacklistInfo()
            elseif action == "Update Player List" then
                updatePlayerList()
            elseif action == "Check Server Status" then
                _G.CROW:SendNotification("Server: " .. game.JobId:sub(1,8) .. "... | Players: " .. #Players:GetPlayers(), 3)
            end
        end
    end
})

MainSection:AddToggle({
    text = "Auto Refresh Data",
    state = false,
    flag = "AdminAutoRefresh",
    tooltip = "Automatically refresh blacklist every 30 seconds",
    callback = function(state)
        _G.AdminPanel.AutoRefresh = state
        if state then
            startAutoRefresh()
        end
    end
})

-- ===================== BLACKLIST MANAGEMENT =====================
BlacklistSection:AddSeparator({ text = "Blacklist Controls" })

BlacklistSection:AddBox({
    enabled = true,
    name = "Add Player to Blacklist",
    flag = "AddPlayerInput",
    input = "Enter UserID or Username",
    focused = false,
    risky = false,
    callback = function(input)
        if input and input ~= "" then
            addPlayerToBlacklist(input)
        end
    end
})

BlacklistSection:AddBox({
    enabled = true,
    name = "Remove Player from Blacklist",
    flag = "RemovePlayerInput", 
    input = "Enter UserID",
    focused = false,
    risky = false,
    callback = function(input)
        if input and input ~= "" then
            removePlayerFromBlacklist(input)
        end
    end
})

BlacklistSection:AddSeparator({ text = "Search & Display" })

BlacklistSection:AddBox({
    enabled = true,
    name = "Search Blacklist",
    flag = "SearchBlacklistInput",
    input = "Search by name, display name, or ID",
    focused = false,
    risky = false,
    callback = function(input)
        searchBlacklist(input)
    end
})

BlacklistSection:AddToggle({
    text = "Show Detailed Info",
    state = true,
    flag = "ShowDetailedBlacklistInfo",
    tooltip = "Show creation date, status, etc.",
    callback = function(state)
        updateBlacklistDisplay()
    end
})

BlacklistSection:AddSlider({
    enabled = true,
    text = "Max Display Results",
    tooltip = "Maximum players to show in list",
    flag = "MaxDisplayResults",
    suffix = " players",
    min = 5,
    max = 50,
    increment = 5,
    risky = false,
    callback = function(value)
        updateBlacklistDisplay()
    end
})

-- Blacklist Display Button (keeping as button since it shows dynamic content)
_G.AdminPanel.BlacklistDisplay = BlacklistSection:AddButton({
    enabled = true,
    text = "Loading blacklisted players...",
    tooltip = "Click to refresh blacklist display",
    callback = function()
        refreshBlacklistInfo()
    end
})

BlacklistSection:AddSeparator({ text = "Blacklist Actions" })

-- Blacklist Actions Dropdown
BlacklistSection:AddList({
    enabled = true,
    text = "Blacklist Actions",
    tooltip = "Select blacklist management actions",
    selected = {},
    multi = true,
    open = false,
    max = 4,
    values = {
        "Export Blacklist",
        "Clear Search Filter",
        "Refresh Display",
        "Show Statistics"
    },
    flag = "BlacklistActionsSelection",
    risky = false,
    callback = function(selected)
        for _, action in pairs(selected) do
            if action == "Export Blacklist" then
                exportBlacklist()
            elseif action == "Clear Search Filter" then
                library.flags["SearchBlacklistInput"] = ""
                updateBlacklistDisplay()
            elseif action == "Refresh Display" then
                updateBlacklistDisplay()
            elseif action == "Show Statistics" then
                _G.CROW:SendNotification("Blacklist Stats: " .. #_G.BlacklistedPlayers .. " total players", 3)
            end
        end
    end
})

-- ===================== PLAYER MONITORING ===================== 
PlayerSection:AddSeparator({ text = "Current Players" })

-- Player count display (keeping as button for dynamic updates)
_G.AdminPanel.PlayerCountButton = PlayerSection:AddButton({
    enabled = true,
    text = "Players in server: " .. #Players:GetPlayers(),
    tooltip = "Click to refresh player list",
    callback = function()
        updatePlayerList()
    end
})

PlayerSection:AddToggle({
    text = "Monitor Player Activity",
    state = false,
    flag = "MonitorPlayers", 
    tooltip = "Track player joins/leaves and display info",
    callback = function(state)
        _G.AdminPanel.MonitoringPlayers = state
        if state then
            startPlayerMonitoring()
        end
    end
})

PlayerSection:AddList({
    enabled = true,
    text = "Player Info Display",
    tooltip = "Choose how much player info to show",
    selected = "Basic",
    multi = false,
    open = false,
    max = 4,
    values = {"Basic", "Detailed", "Advanced"},
    flag = "PlayerInfoLevel",
    risky = false,
    callback = function(value)
        updatePlayerList()
    end
})

-- Player list display button (keeping as button for dynamic content)
_G.AdminPanel.PlayerListDisplay = PlayerSection:AddButton({
    enabled = true,
    text = "Enable monitoring to see player list",
    tooltip = "Shows current players in server",
    callback = function()
        if _G.AdminPanel.MonitoringPlayers then
            updatePlayerList()
        else
            _G.CROW:SendNotification("Enable player monitoring first", 2)
        end
    end
})

PlayerSection:AddSeparator({ text = "Player Actions" })

PlayerSection:AddBox({
    enabled = true,
    name = "Kick Player",
    flag = "KickPlayerInput",
    input = "Enter username or UserID",
    focused = false,
    risky = true,
    callback = function(input)
        if input and input ~= "" then
            kickPlayer(input)
        end
    end
})

PlayerSection:AddBox({
    enabled = true,
    name = "Get Player Info",
    flag = "PlayerInfoInput",
    input = "Enter username or UserID",
    focused = false,
    risky = false,
    callback = function(input)
        if input and input ~= "" then
            getDetailedPlayerInfo(input)
        end
    end
})

-- ===================== SERVER MANAGEMENT =====================
ServerSection:AddSeparator({ text = "Server Controls" })

-- Server Actions Dropdown
ServerSection:AddList({
    enabled = true,
    text = "Server Actions",
    tooltip = "Select server management actions",
    selected = {},
    multi = true,
    open = false,
    max = 4,
    values = {
        "Kick All Non-Admins",
        "Show Server Info",
        "Check Performance",
        "Restart Monitoring"
    },
    flag = "ServerActionsSelection",
    risky = true,
    callback = function(selected)
        for _, action in pairs(selected) do
            if action == "Kick All Non-Admins" then
                kickAllNonAdmins()
            elseif action == "Show Server Info" then
                local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
                _G.CROW:SendNotification("Game: " .. (gameInfo.Name or "Unknown") .. " | Place ID: " .. tostring(game.PlaceId), 5)
            elseif action == "Check Performance" then
                _G.CROW:SendNotification("Performance check initiated", 2)
            elseif action == "Restart Monitoring" then
                if _G.AdminPanel.MonitoringPlayers then
                    startPlayerMonitoring()
                    _G.CROW:SendNotification("Player monitoring restarted", 2)
                end
            end
        end
    end
})

ServerSection:AddToggle({
    text = "Auto-Kick Blacklisted",
    state = true,
    flag = "AutoKickBlacklisted",
    tooltip = "Automatically kick players when they join if blacklisted"
})

ServerSection:AddSeparator({ text = "Server Information" })

-- Server Info Dropdown
local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
ServerSection:AddList({
    enabled = true,
    text = "Server Information",
    tooltip = "View server details",
    selected = {},
    multi = true,
    open = false,
    max = 4,
    values = {
        "Game: " .. (gameInfo.Name or "Unknown"),
        "Place ID: " .. tostring(game.PlaceId),
        "Job ID: " .. tostring(game.JobId):sub(1, 8) .. "...",
        "Players: " .. #Players:GetPlayers()
    },
    flag = "ServerInfoSelection",
    risky = false,
    callback = function(selected)
        for _, info in pairs(selected) do
            if string.find(info, "Job ID:") then
                _G.CROW:SendNotification("Full Job ID: " .. tostring(game.JobId), 5)
            else
                _G.CROW:SendNotification(info, 3)
            end
        end
    end
})

ServerSection:AddSeparator({ text = "Performance" })

-- Performance monitoring buttons (keeping as buttons for real-time updates)
_G.AdminPanel.FPSButton = ServerSection:AddButton({
    enabled = true,
    text = "FPS: Calculating...",
    tooltip = "Current frames per second",
    callback = function() end
})

_G.AdminPanel.PingButton = ServerSection:AddButton({
    enabled = true,
    text = "Ping: Calculating...",
    tooltip = "Current network ping",
    callback = function() end
})

-- ===================== FUNCTIONS =====================

-- Function to get player info from UserID
local function getPlayerInfo(userId)
    local success, result = pcall(function()
        local url = "https://users.roblox.com/v1/users/" .. tostring(userId)
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        return {
            id = data.id,
            name = data.name,
            displayName = data.displayName,
            description = data.description or "No description",
            created = data.created or "Unknown",
            isBanned = data.isBanned or false,
            hasVerifiedBadge = data.hasVerifiedBadge or false
        }
    end)
    
    if success then
        return result
    else
        return {
            id = userId,
            name = "Unknown",
            displayName = "Unknown",
            description = "Failed to fetch", 
            created = "Unknown",
            isBanned = false,
            hasVerifiedBadge = false
        }
    end
end

-- Function to refresh all admin data
function refreshAllData()
    _G.CROW:SendNotification("Refreshing all admin data...", 3)
    refreshBlacklistInfo()
    updatePlayerList()
    
    -- Update dropdown values
    updateDropdownValues()
end

-- Function to update dropdown values with current data
function updateDropdownValues()
    -- Update admin info dropdown values
    local adminInfoValues = {
        "Panel Version: v1.0.5",
        "Admin ID: " .. tostring(_G.userId),
        "Total Admins: " .. #_G.Admins,
        "Blacklisted Players: " .. #_G.BlacklistedPlayers
    }
    
    -- Update server info dropdown values
    local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    local serverInfoValues = {
        "Game: " .. (gameInfo.Name or "Unknown"),
        "Place ID: " .. tostring(game.PlaceId),
        "Job ID: " .. tostring(game.JobId):sub(1, 8) .. "...",
        "Players: " .. #Players:GetPlayers()
    }
    
    -- Note: In a real implementation, you'd need to update the dropdown values
    -- This would require additional UI library methods
end

-- Function to refresh blacklist information
function refreshBlacklistInfo()
    if _G.AdminPanel.RefreshInProgress then
        _G.CROW:SendNotification("Refresh already in progress...", 2)
        return
    end
    
    _G.AdminPanel.RefreshInProgress = true
    _G.CROW:SendNotification("Refreshing blacklist...", 2)
    
    task.spawn(function()
        _G.AdminPanel.BlacklistCache = {}
        
        for i, userId in ipairs(_G.BlacklistedPlayers) do
            local playerInfo = getPlayerInfo(userId)
            table.insert(_G.AdminPanel.BlacklistCache, playerInfo)
            
            if i % 3 == 0 or i == #_G.BlacklistedPlayers then
                updateBlacklistDisplay()
                task.wait(0.2)
            end
        end
        
        updateBlacklistDisplay()
        _G.AdminPanel.RefreshInProgress = false
        
        -- Update blacklist count
        updateDropdownValues()
        
        _G.CROW:SendNotification("Blacklist refreshed! (" .. #_G.BlacklistedPlayers .. " players)", 3)
    end)
end

-- Function to update blacklist display
function updateBlacklistDisplay()
    if not _G.AdminPanel.BlacklistDisplay then return end
    
    local maxResults = library.flags["MaxDisplayResults"] or 15
    local showDetailed = library.flags["ShowDetailedBlacklistInfo"]
    local searchQuery = library.flags["SearchBlacklistInput"] or ""
    
    local displayText = "=== BLACKLISTED PLAYERS (" .. #_G.BlacklistedPlayers .. ") ==="
    
    local playersToShow = _G.AdminPanel.BlacklistCache
    
    -- Apply search filter
    if searchQuery and searchQuery ~= "" then
        local filteredPlayers = {}
        local query = string.lower(searchQuery)
        
        for _, player in ipairs(_G.AdminPanel.BlacklistCache) do
            local name = string.lower(player.name)
            local displayName = string.lower(player.displayName)
            local id = tostring(player.id)
            
            if string.find(name, query) or string.find(displayName, query) or string.find(id, query) then
                table.insert(filteredPlayers, player)
            end
        end
        
        playersToShow = filteredPlayers
        displayText = "=== SEARCH: '" .. searchQuery .. "' (" .. #filteredPlayers .. " results) ==="
    end
    
    if #playersToShow == 0 then
        displayText = displayText .. "\nNo players found."
    else
        local count = 0
        for i, player in ipairs(playersToShow) do
            if count >= maxResults then
                displayText = displayText .. "\n... and " .. (#playersToShow - maxResults) .. " more players"
                break
            end
            
            count = count + 1
            if showDetailed then
                displayText = displayText .. string.format(
                    "\n[%d] %s (@%s) | ID: %s | Status: %s%s | Created: %s",
                    i,
                    player.displayName,
                    player.name,
                    tostring(player.id),
                    player.isBanned and "BANNED" or "Active",
                    player.hasVerifiedBadge and " ✓" or "",
                    string.sub(player.created, 1, 10)
                )
            else
                displayText = displayText .. string.format(
                    "\n[%d] %s (@%s) | %s",
                    i,
                    player.displayName,
                    player.name,
                    tostring(player.id)
                )
            end
        end
    end
    
    _G.AdminPanel.BlacklistDisplay:SetText(displayText)
end

-- Function to search blacklist
function searchBlacklist(query)
    updateBlacklistDisplay()
    if query and query ~= "" then
        _G.CROW:SendNotification("Searching for: " .. query, 2)
    else
        _G.CROW:SendNotification("Search cleared", 2)
    end
end

-- Function to add player to blacklist
function addPlayerToBlacklist(input)
    if not input or input == "" then
        _G.CROW:SendNotification("Please enter a UserID or Username", 3)
        return
    end
    
    task.spawn(function()
        local userId = tonumber(input)
        
        -- If input is not a number, try to get UserID from username
        if not userId then
            local success, result = pcall(function()
                local url = "https://users.roblox.com/v1/usernames/users"
                local postData = HttpService:JSONEncode({
                    usernames = {input}
                })
                local response = HttpService:PostAsync(url, postData, Enum.HttpContentType.ApplicationJson)
                local data = HttpService:JSONDecode(response)
                if data.data and data.data[1] then
                    return data.data[1].id
                end
                return nil
            end)
            
            if success and result then
                userId = result
            else
                _G.CROW:SendNotification("Failed to find user: " .. input, 3)
                return
            end
        end
        
        -- Check if already blacklisted
        for _, blacklistedId in ipairs(_G.BlacklistedPlayers) do
            if blacklistedId == userId then
                _G.CROW:SendNotification("User already blacklisted!", 3)
                return
            end
        end
        
        -- Add to blacklist (Note: This only adds locally)
        table.insert(_G.BlacklistedPlayers, userId)
        _G.CROW:SendNotification("Added UserID " .. userId .. " to blacklist", 3)
        
        -- Refresh display
        refreshBlacklistInfo()
        
        -- Check if the user is currently in the server
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId then
                _G.CROW:SendNotification("Kicking newly blacklisted player: " .. player.Name, 3)
                player:Kick("You have been blacklisted from using this script")
            end
        end
    end)
end

-- Function to remove player from blacklist
function removePlayerFromBlacklist(input)
    local userId = tonumber(input)
    if not userId then
        _G.CROW:SendNotification("Please enter a valid UserID", 3)
        return
    end
    
    local found = false
    for i, blacklistedId in ipairs(_G.BlacklistedPlayers) do
        if blacklistedId == userId then
            table.remove(_G.BlacklistedPlayers, i)
            found = true
            break
        end
    end
    
    if found then
        _G.CROW:SendNotification("Removed UserID " .. userId .. " from blacklist", 3)
        refreshBlacklistInfo()
    else
        _G.CROW:SendNotification("UserID not found in blacklist", 3)
    end
end

-- Function to update player list
function updatePlayerList()
    if not _G.AdminPanel.PlayerListDisplay then return end
    
    local currentPlayers = Players:GetPlayers()
    local playerInfo = library.flags["PlayerInfoLevel"] or "Basic"
    
    local displayText = "=== CURRENT PLAYERS (" .. #currentPlayers .. ") ==="
    
    for i, player in ipairs(currentPlayers) do
        local isAdmin = false
        for _, adminId in ipairs(_G.Admins) do
            if player.UserId == adminId then
                isAdmin = true
                break
            end
        end
        
        local isBlacklisted = false
        for _, blacklistedId in ipairs(_G.BlacklistedPlayers) do
            if player.UserId == blacklistedId then
                isBlacklisted = true
                break
            end
        end
        
        if playerInfo == "Basic" then
            displayText = displayText .. string.format(
                "\n[%d] %s%s%s",
                i,
                player.Name,
                isAdmin and " [ADMIN]" or "",
                isBlacklisted and " [BLACKLISTED]" or ""
            )
        elseif playerInfo == "Detailed" then
            displayText = displayText .. string.format(
                "\n[%d] %s (@%s) | ID: %s%s%s",
                i,
                player.DisplayName or player.Name,
                player.Name,
                tostring(player.UserId),
                isAdmin and " [ADMIN]" or "",
                isBlacklisted and " [BLACKLISTED]" or ""
            )
        else -- Advanced
            local character = player.Character
            local health = "N/A"
            local tool = "None"
            
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    health = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                end
                
                local equippedTool = character:FindFirstChildOfClass("Tool")
                if equippedTool then
                    tool = equippedTool.Name
                else
                    -- EquippedTool StringValue can be anywhere under character; .Value = weapon name
                    local equippedVal = character:FindFirstChild("EquippedTool", true)
                    if equippedVal and equippedVal:IsA("StringValue") and equippedVal.Value and equippedVal.Value ~= "" then
                        tool = equippedVal.Value
                    end
                end
            end
            
            displayText = displayText .. string.format(
                "\n[%d] %s (@%s) | ID: %s | HP: %s | Tool: %s%s%s",
                i,
                player.DisplayName or player.Name,
                player.Name,
                tostring(player.UserId),
                health,
                tool,
                isAdmin and " [ADMIN]" or "",
                isBlacklisted and " [BLACKLISTED]" or ""
            )
        end
    end
    
    _G.AdminPanel.PlayerListDisplay:SetText(displayText)
    
    -- Update player count
    if _G.AdminPanel.PlayerCountButton then
        _G.AdminPanel.PlayerCountButton:SetText("Players in server: " .. #currentPlayers)
    end
    
    -- Update dropdown values
    updateDropdownValues()
end

-- Function to kick player
function kickPlayer(input)
    local targetPlayer = nil
    local userId = tonumber(input)
    
    -- Find player by UserID or username
    for _, player in ipairs(Players:GetPlayers()) do
        if userId and player.UserId == userId then
            targetPlayer = player
            break
        elseif string.lower(player.Name) == string.lower(input) then
            targetPlayer = player
            break
        end
    end
    
    if targetPlayer then
        -- Check if trying to kick admin
        for _, adminId in ipairs(_G.Admins) do
            if targetPlayer.UserId == adminId then
                _G.CROW:SendNotification("Cannot kick admin: " .. targetPlayer.Name, 3)
                return
            end
        end
        
        targetPlayer:Kick("Kicked by admin")
        _G.CROW:SendNotification("Kicked player: " .. targetPlayer.Name, 3)
        task.wait(1)
        updatePlayerList()
    else
        _G.CROW:SendNotification("Player not found: " .. input, 3)
    end
end

-- Function to get detailed player info
function getDetailedPlayerInfo(input)
    local targetPlayer = nil
    local userId = tonumber(input)
    
    -- Find player by UserID or username
    for _, player in ipairs(Players:GetPlayers()) do
        if userId and player.UserId == userId then
            targetPlayer = player
            break
        elseif string.lower(player.Name) == string.lower(input) then
            targetPlayer = player
            break
        end
    end
    
    if targetPlayer then
        local info = string.format(
            "=== PLAYER INFO === Name: %s | Display: %s | UserID: %s | Account Age: %d days | Team: %s",
            targetPlayer.Name,
            targetPlayer.DisplayName or targetPlayer.Name,
            tostring(targetPlayer.UserId),
            targetPlayer.AccountAge,
            targetPlayer.Team and targetPlayer.Team.Name or "None"
        )
        
        _G.CROW:SendNotification("Player info retrieved for " .. targetPlayer.Name, 2)
        _G.CROW:SendNotification(info, 10) -- Longer duration for detailed info
    else
        _G.CROW:SendNotification("Player not found: " .. input, 3)
    end
end

-- Function to kick all non-admins
function kickAllNonAdmins()
    local kicked = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local isAdmin = false
        for _, adminId in ipairs(_G.Admins) do
            if player.UserId == adminId then
                isAdmin = true
                break
            end
        end
        
        if not isAdmin then
            player:Kick("Server cleared by admin")
            kicked = kicked + 1
        end
    end
    
    _G.CROW:SendNotification("Kicked " .. kicked .. " non-admin players", 3)
    task.wait(2)
    updatePlayerList()
end

-- Function to export blacklist
function exportBlacklist()
    local exportData = "Blacklisted Players Export: "
    for i, player in ipairs(_G.AdminPanel.BlacklistCache) do
        exportData = exportData .. string.format(
            "%d. %s (@%s) - ID: %s | ",
            i,
            player.displayName,
            player.name,
            tostring(player.id)
        )
    end
    
    _G.CROW:SendNotification(exportData, 10) -- Show export data in notification
    _G.CROW:SendNotification("Blacklist exported", 3)
end

-- Function to start auto refresh
function startAutoRefresh()
    task.spawn(function()
        while _G.AdminPanel.AutoRefresh do
            task.wait(30) -- Wait 30 seconds
            if _G.AdminPanel.AutoRefresh then
                refreshBlacklistInfo()
            end
        end
    end)
end

-- Function to start player monitoring
function startPlayerMonitoring()
    -- Update player list immediately
    updatePlayerList()
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        if _G.AdminPanel.MonitoringPlayers then
            _G.CROW:SendNotification("Player joined: " .. player.Name, 2)
            
            -- Check if blacklisted and auto-kick is enabled
            if library.flags["AutoKickBlacklisted"] then
                for _, blacklistedId in ipairs(_G.BlacklistedPlayers) do
                    if player.UserId == blacklistedId then
                        _G.CROW:SendNotification("Auto-kicking blacklisted player: " .. player.Name, 3)
                        player:Kick("You are blacklisted from using this script")
                        return
                    end
                end
            end
            
            task.wait(1)
            updatePlayerList()
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if _G.AdminPanel.MonitoringPlayers then
            _G.CROW:SendNotification("Player left: " .. player.Name, 2)
            task.wait(1)
            updatePlayerList()
        end
    end)
end

-- Performance monitoring (no blocking while loops)
local frameCount = 0
local fpsLastTime = tick()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - fpsLastTime >= 1 then
        local fps = math.floor(frameCount / (currentTime - fpsLastTime))
        if _G.AdminPanel and _G.AdminPanel.FPSButton then
            pcall(function() _G.AdminPanel.FPSButton:SetText("FPS: " .. fps) end)
        end
        frameCount = 0
        fpsLastTime = currentTime
    end
end)

-- Ping monitoring (throttled, no blocking loop)
local function updatePing()
    pcall(function()
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        if _G.AdminPanel and _G.AdminPanel.PingButton then
            _G.AdminPanel.PingButton:SetText("Ping: " .. math.floor(ping) .. "ms")
        end
    end)
    task.delay(5, updatePing)
end
task.delay(5, updatePing)

-- Initialize everything
refreshBlacklistInfo()

-- Admin Panel Cleanup
_G.AdminPanel.Cleanup = function()
    _G.AdminPanel.BlacklistCache = {}
    _G.AdminPanel.RefreshInProgress = false
    _G.AdminPanel.AutoRefresh = false
    _G.AdminPanel.MonitoringPlayers = false
    _G.CROW:SendNotification("Admin Panel cleaned up", 2)
end

_G.CROW:SendNotification("Admin Panel loaded successfully!", 3)
