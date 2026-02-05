--[[ CROW Shooter Loader | Repo: wrdzy/CROW/main/CrowShooter
    Run: loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowShooter/loader.lua"))()
    Full docs: see README.md (admins, config, rebrand, tabs).
    Load order: BlacklistedPlayers → signal → UiInnit → AdminPanel → AimSec → ESPsec → PlayerSec → WorldSec.
    AC bypass: _G.CROW_bypass backs up hook APIs before scripts load. Silent aim: no hooks until enabled.
    Debug: _G.CROW_DEBUG = true for load logs. ]]

local function getLoaderEnv()
    if getfenv and getfenv(1) then return getfenv(1) end
    if getgenv and getgenv() then return getgenv() end
    return _G
end

-- Force all scripts to share the same globals (executors may sandbox each loadstring)
local env = getLoaderEnv()

-- Optional: validate Drawing API for 2026 executors (fail fast with clear message)
if not Drawing or type(Drawing.new) ~= "function" then
    error("CROW Loader: Drawing API missing. Use an executor that provides Drawing and Drawing.new (e.g. KRNL, Fluxus).")
end
local testDraw = Drawing.new("Circle")
if testDraw == nil then
    error("CROW Loader: Drawing.new returned nil. Check your executor's Drawing API.")
end
if type(testDraw) == "number" then
    error("CROW Loader: This executor returns a numeric handle from Drawing.new; CROW needs objects with .Visible, .Position, etc. Check your 2026 executor's Drawing docs.")
end
if type(testDraw) == "userdata" or type(testDraw) == "table" then
    pcall(function() testDraw:Remove() end)
end
if not env.CROW_shared then
    env.CROW_shared = env
end
local shared = env.CROW_shared
-- So injected "local _G = ... CROW_shared or _G" resolves to this table in every script
shared._G = shared

-- Wait for game only; UI loads immediately. Player tab activates when character spawns (see PlayerSec).
pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)

-- Loading indicator: show "Loading CROW..." until all scripts are done (removed at end)
local loadingDraw = nil
pcall(function()
    loadingDraw = Drawing.new("Text")
    loadingDraw.Visible = true
    loadingDraw.Center = true
    loadingDraw.Outline = true
    loadingDraw.Size = 24
    loadingDraw.Text = "Loading CROW..."
    loadingDraw.Color = Color3.fromRGB(255, 255, 255)
    local cam = game:GetService("Workspace") and game.Workspace.CurrentCamera
    if cam and cam.ViewportSize then
        loadingDraw.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2 - 40)
    end
end)

-- Re-execution: unload existing UI then clear shared refs so new run gets fresh tabs.
local existingLib = shared.CROW or shared.library
if existingLib and type(existingLib.Unload) == "function" then
    pcall(existingLib.Unload, existingLib)
end
shared.CROW = nil
shared.library = nil
shared.PlayerTab = nil
shared.ESPTab = nil
shared.Aimlock = nil
shared.MiscTab = nil
shared.WorldTab = nil
shared.AdminTab = nil

-- Script persistence: read saved state from file (only thing that saves without a config). No file / first run = on.
if shared.CROW_ScriptPersistenceEnabled == nil then
    shared.CROW_ScriptPersistenceEnabled = true
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, "CROW/PersistenceEnabled.txt")
        if ok and content and type(content) == "string" then
            local v = content:gsub("^%s+", ""):gsub("%s+$", ""):lower()
            if v == "false" or v == "0" then
                shared.CROW_ScriptPersistenceEnabled = false
            end
        end
    end
end

-- Admin list: only users in this table see the Admin tab. Set your admin UserIds here or before loading (see README).
if shared.Admins == nil then
    shared.Admins = {}
end
-- Enemy list (UserId -> true): for games that don't use Roblox teams. Used when "Enemy detection" = "Enemy list".
if shared.CROW_EnemyList == nil then
    shared.CROW_EnemyList = {}
end

-- ========== ANTI-CHEAT BYPASS (run before any script loads) ==========
-- Backup APIs in one table (less obvious than global _hookfunction etc).
pcall(function()
    shared.CROW_bypass = shared.CROW_bypass or {}
    local b = shared.CROW_bypass
    if hookmetamethod and type(hookmetamethod) == "function" then b.hookmetamethod = hookmetamethod end
    if hookfunction and type(hookfunction) == "function" then b.hookfunction = hookfunction end
    if getrawmetatable and type(getrawmetatable) == "function" then b.getrawmetatable = getrawmetatable end
    if setreadonly and type(setreadonly) == "function" then b.setreadonly = setreadonly end
    if newcclosure and type(newcclosure) == "function" then b.newcclosure = newcclosure end
    if getnamecallmethod and type(getnamecallmethod) == "function" then b.getnamecallmethod = getnamecallmethod end
    if checkcaller and type(checkcaller) == "function" then b.checkcaller = checkcaller end
end)

-- Debug: set _G.CROW_DEBUG = true before running loader for verbose logs
local DEBUG = shared.CROW_DEBUG == true

local function debugLog(msg)
    if DEBUG then
        warn("[CROW Debug] " .. tostring(msg))
    end
end

-- Raw GitHub base URL (branch = main). Override before loading: shared.CROW_RAW_URL = "https://..."; shared.CROW_Config = { DiscordInvite, ImageBaseUrl, SignalUrl, WatermarkRefreshrate }.
local baseUrl = (shared.CROW_RAW_URL or "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowShooter/"):gsub("/$", "") .. "/"

-- Fetch URL using executor request first (request / http_request), then game:HttpGet. General executor APIs only.
local function fetchUrl(url)
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
        local ok, result = pcall(game.HttpGet, game, url)
        if ok and result and #result > 0 then body = result end
    end
    return body
end

local scriptsToLoad = {
    { name = "BlacklistedPlayers", captureReturn = false },
    { name = "signal", captureReturn = true, globalName = "Signal" },
    { name = "UiInnit", captureReturn = false },
    { name = "AdminPanel", captureReturn = false },
    { name = "AimSec", captureReturn = false },
    { name = "ESPsec", captureReturn = false },
    { name = "PlayerSec", captureReturn = false },
    { name = "WorldSec", captureReturn = false },
    { name = "MiscSec", captureReturn = false },
}

-- Safe mode: UiInnit shows a CROWui window ("SAFE MODE?" + YES/NO) after init, before main window.
shared.CROW_SafeMode = false

local function loadScript(name)
    local url = baseUrl .. name .. ".lua"
    -- Cache-bust UiInnit so safe mode / UI fixes are always fetched fresh after updates
    if name == "UiInnit" then
        url = url .. "?v=" .. tostring(tick())
    end
    debugLog("Loading: " .. name .. ".lua ...")
    local content = fetchUrl(url)
    if content and #content > 0 then
        debugLog("  Fetched " .. #content .. " bytes from " .. url)
    end
    if not content or #content == 0 then
        warn("[CROW Loader] Failed to fetch: " .. url .. " (check CROW_RAW_URL or network)")
        return nil
    end
    -- Inject shared _G so executor sandboxes still see UiInnit's CROW, AdminTab, etc.
    local injected = "local _G = (getgenv and getgenv() or _G).CROW_shared or _G\n" .. content
    local fn, err = loadstring(injected)
    if not fn then
        warn("[CROW Loader] Failed to compile " .. name .. ".lua: " .. tostring(err))
        return nil
    end
    pcall(function()
        if setfenv and type(setfenv) == "function" then
            setfenv(fn, shared)
        end
    end)
    local ret = fn()
    debugLog("  " .. name .. ".lua finished OK")
    return ret
end

for i, entry in ipairs(scriptsToLoad) do
    debugLog("--- Script " .. i .. "/" .. #scriptsToLoad .. ": " .. entry.name .. " ---")
    local success, result = pcall(loadScript, entry.name)
    if not success then
        warn("[CROW Loader] Error running " .. entry.name .. ".lua: " .. tostring(result))
        if DEBUG and type(result) == "string" then
            warn("[CROW Debug] Full error: " .. result)
        end
        if entry.name == "UiInnit" then
            debugLog("UiInnit failed - CROW/AdminTab/etc. may be nil. shared.CROW = " .. tostring(shared.CROW))
        end
        -- Still remove loading indicator and try to notify on any failure
        pcall(function()
            if loadingDraw then
                if loadingDraw.Remove then loadingDraw:Remove() else loadingDraw.Visible = false end
                loadingDraw = nil
            end
        end)
        local lib = shared.CROW or shared.library
        if lib and type(lib.SendNotification) == "function" then
            pcall(lib.SendNotification, lib, "CROW load failed: " .. entry.name, 5, Color3.fromRGB(255, 100, 100))
        end
    else
        if entry.captureReturn and result and entry.globalName then
            shared[entry.globalName] = result
            debugLog("  Set shared." .. entry.globalName)
        end
        -- Show "Loading CROW..." in UI as soon as library exists (after UiInnit)
        if entry.name == "UiInnit" then
            pcall(function()
                local lib = shared.CROW or shared.library
                if lib and type(lib.SendNotification) == "function" then
                    -- Shorter duration so the loading notification doesn't linger after CROW is fully loaded
                    lib:SendNotification("Loading CROW...", 5, Color3.fromRGB(255, 255, 255))
                end
            end)
        end
    end
end

-- Remove loading indicator and notify when done
pcall(function()
    if loadingDraw then
        if loadingDraw.Remove then loadingDraw:Remove() else loadingDraw.Visible = false end
        loadingDraw = nil
    end
end)
pcall(function()
    local lib = shared.CROW or shared.library
    if lib and type(lib.SendNotification) == "function" then
        local green = (Color3 and Color3.fromRGB and Color3.fromRGB(0, 255, 0)) or nil
        lib:SendNotification("CROW loaded", 3, green)
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        if lp and not lp.Character then
            lib:SendNotification("Player tab will activate when you spawn", 4)
        end
    end
end)

-- Script persistence (save loader to file + queue_on_teleport) is set up in UiInnit after UI/config is ready.

-- No metatable locking: setreadonly on game/workspace can trigger indexInstance detector (Error 267). Instance metatable left untouched.

if DEBUG then
    debugLog("Done. shared.CROW = " .. tostring(shared.CROW) .. ", shared.AdminTab = " .. tostring(shared.AdminTab) .. ", shared.PlayerTab = " .. tostring(shared.PlayerTab))
end

return true
