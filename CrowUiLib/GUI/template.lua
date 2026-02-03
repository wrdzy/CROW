--[[
  CROWUI GUI Template
  ==================
  Minimal example: load the GUI library then create a window with one tab and a few options.
  Run after loading the library (loader.lua). Example:

    local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/loader.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/template.lua"))()

  Or run loader and template in one go by having your executor fetch loader first, then template.
]]

local genv = (getgenv and getgenv()) or _G
local library = (genv and (genv.CROW or genv.library)) or _G.CROW or _G.library
if not library or type(library.NewWindow) ~= "function" then
    error("GUI Template: Load the GUI loader first so _G.CROW or _G.library exists.")
end

if not library.hasInit then
    library:init()
end
library:SetOpen(true)

local menu = library:NewWindow({
    title = "CROWUI GUI Example",
    size = UDim2.new(0, 500, 0, 550),
    position = UDim2.new(0, 200, 0, 150),
})

local mainTab = menu:AddTab("Main", 1)
local section = mainTab:AddSection("Options", 1)

section:AddToggle({
    text = "Example Toggle",
    state = false,
    flag = "ExampleToggle",
    callback = function(state)
        library:SendNotification(state and "Toggle ON" or "Toggle OFF", 2)
    end
})

section:AddSlider({
    text = "Example Slider",
    min = 0,
    max = 100,
    default = 50,
    suffix = "%",
    flag = "ExampleSlider"
})

section:AddList({
    text = "Example List",
    values = { "Option A", "Option B", "Option C" },
    default = "Option A",
    flag = "ExampleList"
})

library:CreateSettingsTab(menu)

return menu
