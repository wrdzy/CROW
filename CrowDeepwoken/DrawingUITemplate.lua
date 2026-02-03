--[[
  Drawing UI Template (Deepwoken)
  ===============================
  Drawing-only UI: Player (CFrame movement, fly, noclip), World (lighting), ESP (full), Settings.
  PlayerSec, WorldSec, ESPsec attach to _G.PlayerTab, _G.WorldTab, _G.ESPTab via loader-drawing.lua.
]]

local genv = (getgenv and getgenv()) or _G
local library = (genv and (genv.CROW or genv.library)) or _G.CROW or _G.library
if not library or type(library.NewWindow) ~= "function" then
    error("DrawingUITemplate: Load UiInnitDrawingOnly.lua first so _G.CROW or _G.library exists.")
end

-- Ensure init ran (e.g. when using loader-drawing.lua, init already ran but full window was skipped)
if not library.hasInit then
    library:init()
end

-- Open UI (when using template-only loader there is no safe mode dialog)
library:SetOpen(true)

-- Window from config (nothing hardcoded; _G.CROW_WindowConfig or library.config.Window wins)
local windowConfig = (library.config and library.config.Window) or _G.CROW_WindowConfig or {}
local windowTitle = windowConfig.title or "Deepwoken"
local windowSize = windowConfig.size or UDim2.new(0, 525, 0, 650)
local windowPosition = windowConfig.position or UDim2.new(0, 250, 0, 150)

local menu = library:NewWindow({
    title = windowTitle,
    size = windowSize,
    position = windowPosition,
})

-- ========== Tabs: Player, ESP, World (PlayerSec/ESPsec/WorldSec attach via _G), Settings ==========
_G.PlayerTab = menu:AddTab("Player", 1)
_G.ESPTab = menu:AddTab("ESP", 2)
_G.WorldTab = menu:AddTab("World", 3)

-- ========== Default Settings tab (same as UiInnit: Config, Main, Custom Theme) ==========
-- Configs work the same: Load/Save/Create/Delete, library:LoadConfig/SaveConfig/GetConfig, cheatname/configname folder.
library:CreateSettingsTab(menu)

return menu
