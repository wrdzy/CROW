--[[
  Crow Deepwoken — Drawing UI Loader | Repo: wrdzy/CROW/main/CrowDeepwoken
  =========================================================================
  Loads the Drawing-only UI + Deepwoken template (Player, World, ESP, Settings).

  Run:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/loader.lua"))()

  Or with custom base URL (set before running):
    (getgenv().CROW_shared or getgenv()).CROW_RAW_URL = "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/"

  Config (set before running to override defaults; no hardcoded values):
    getgenv().CROW_Config = { ... }           -- library.config (UiInnitDrawingOnly)
    getgenv().CROW_ESPSettings = { ... }     -- ESP defaults (ESPsec)
    getgenv().CROW_ESPConfig = { ... }       -- ESP intervals (VISIBILITY_CACHE_INTERVAL, etc.)
    getgenv().CROW_PlayerConfig = { ... }    -- Player tab defaults (PlayerSec)
    getgenv().CROW_WindowConfig = { ... }    -- Window title/size/position (DrawingUITemplate)
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

-- Template-only mode: UiInnitDrawingOnly will skip the full CROW window; DrawingUITemplate creates the Deepwoken window.
shared.CROW_DRAWING_TEMPLATE_ONLY = true

-- Unload existing
local lib = shared.CROW or shared.library
if lib and type(lib.Unload) == "function" then pcall(lib.Unload, lib) end
shared.CROW = nil
shared.library = nil

if not Drawing or type(Drawing.new) ~= "function" then
    error("Deepwoken Loader: Drawing API missing. Use KRNL, Fluxus, or similar.")
end

-- Default: fetch from this repo root (standalone deepwoken repo)
local baseUrl = (shared.CROW_RAW_URL or "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/"):gsub("/$", "") .. "/"
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
        warn("[Deepwoken Loader] Failed to fetch: " .. url)
        return nil
    end
    local fn, err = loadstring("local _G = (getgenv and getgenv() or _G).CROW_shared or _G\n" .. content)
    if not fn then
        warn("[Deepwoken Loader] Compile error " .. name .. ": " .. tostring(err))
        return nil
    end
    if setfenv then setfenv(fn, shared) end
    return fn()
end

-- 1) Signal
loadScript("signal")
if shared.Signal then shared.Signal = shared.Signal end

-- 2) Drawing-only UI (no ScreenGui/CoreGui)
local library = loadScript("UiInnitDrawingOnly")
if not library then
    error("Deepwoken Loader: UiInnitDrawingOnly.lua failed to load.")
end
shared.CROW = library
shared.library = library
-- Sync to getgenv() so scripts that use getgenv().CROW / getgenv().library see the library
if getgenv then
    local g = getgenv()
    if g and type(g) == "table" then
        g.CROW = library
        g.library = library
    end
end

-- 3) Template (window: Player, World, ESP, Settings — Deepwoken)
loadScript("DrawingUITemplate")

-- 4) Player section (speed, fly, jump, FOV, noclip, character customization)
loadScript("PlayerSec")

-- 5) ESP section (boxes, health, names, tracers, skeleton, customise)
loadScript("ESPsec")

-- 6) World section (lighting, color correction, blur, fog, ambient, etc.)
loadScript("WorldSec")

return true
