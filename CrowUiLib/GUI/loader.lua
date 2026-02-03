--[[
  CrowUiLib GUI Loader | Repo: wrdzy/CROW/main/CrowUiLib/GUI
  ==========================================================
  Loads signal.lua then UiInnit.lua (GUI library). Returns the library table.

  Run: loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/loader.lua"))()

  Set base URL before running (optional):
    (getgenv().CROW_shared or getgenv()).CROW_RAW_URL = "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/"
]]

local function getEnv()
    if getgenv and getgenv() then return getgenv() end
    return _G
end
local shared = getEnv()
if not shared.CROW_shared then shared.CROW_shared = shared end
shared = shared.CROW_shared
shared._G = shared

if not game:IsLoaded() then game.Loaded:Wait() end

-- Unload existing
local lib = shared.CROW or shared.library
if lib and type(lib.Unload) == "function" then pcall(lib.Unload, lib) end
shared.CROW = nil
shared.library = nil

local baseUrl = (shared.CROW_RAW_URL or "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/"):gsub("/$", "") .. "/"

local function fetch(url)
    local body
    if type(request) == "function" then
        local ok, r = pcall(request, { Url = url, Method = "GET" })
        if ok and r and r.Body and #r.Body > 0 then body = r.Body end
    end
    if not body and type(http_request) == "function" then
        local ok, r = pcall(http_request, { Url = url, Method = "GET" })
        if ok and r and r.Body and #r.Body > 0 then body = r.Body end
    end
    if not body and game and type(game.HttpGet) == "function" then
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and res and #res > 0 then body = res end
    end
    return body
end

local function loadScript(name)
    local url = baseUrl .. name .. ".lua"
    local content = fetch(url)
    if not content or #content == 0 then
        warn("[CROWUI GUI Loader] Failed to fetch: " .. url)
        return nil
    end
    local injected = "local _G = (getgenv and getgenv() or _G).CROW_shared or _G\n" .. content
    local fn, err = loadstring(injected)
    if not fn then
        warn("[CROWUI GUI Loader] Compile error " .. name .. ": " .. tostring(err))
        return nil
    end
    if setfenv then setfenv(fn, shared) end
    return fn()
end

-- 1) Signal
loadScript("signal")
if shared.Signal then shared.Signal = shared.Signal end

-- 2) GUI library (UiInnit)
local library = loadScript("UiInnit")
if not library then
    error("CROWUI GUI Loader: UiInnit.lua failed to load.")
end
shared.CROW = library
shared.library = library
if getgenv then
    local g = getgenv()
    if g and type(g) == "table" then
        g.CROW = library
        g.library = library
    end
end

return library
