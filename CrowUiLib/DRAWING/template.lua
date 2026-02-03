--[[
  CROWUI DRAWING Template
  =======================
  Minimal example: load the Drawing library then create a Drawing-only window (no ScreenGui).
  Run after loading the library (loader.lua). Requires executor with Drawing API.

  Example:
    local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/loader.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/template.lua"))()
]]

local genv = (getgenv and getgenv()) or _G
local library = (genv and (genv.CROW or genv.library)) or _G.CROW or _G.library
if not library or type(library.NewWindow) ~= "function" then
    error("DRAWING Template: Load the DRAWING loader first so _G.CROW or _G.library exists.")
end

if not library.hasInit then
    library:init()
end
library:SetOpen(true)

local menu = library:NewWindow({
    title = "CROWUI Drawing Example",
    size = UDim2.new(0, 450, 0, 500),
    position = UDim2.new(0, 250, 0, 120),
})

local mainTab = menu:AddTab("Main", 1)
local section = mainTab:AddSection("Options", 1)

section:AddToggle({
    text = "Example Toggle",
    state = false,
    flag = "DrawingExampleToggle",
    callback = function(state)
        if library.SendNotification then
            library:SendNotification(state and "Toggle ON" or "Toggle OFF", 2)
        end
    end
})

section:AddSlider({
    text = "Example Slider",
    min = 0,
    max = 100,
    default = 50,
    suffix = "%",
    flag = "DrawingExampleSlider"
})

section:AddList({
    text = "Example List",
    values = { "Option A", "Option B", "Option C" },
    default = "Option A",
    flag = "DrawingExampleList"
})

library:CreateSettingsTab(menu)

return menu
