# Crow Shooter

Part of **CROW** repo. Roblox executor UI with Player, ESP, Aimlock, Silent Aim, World, and Admin tabs. Uses the Drawing API and supports configs, themes, and re-execution.

---

## Quick start

1. Use an executor that supports **Drawing** (object-style, not numeric handles), e.g. KRNL, Fluxus.
2. Run:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowShooter/loader.lua"))()
   ```
3. Open the UI with **Insert** (default keybind). Close with Insert again.

---

## Requirements

- **Executor:** Must provide `Drawing` and `Drawing.new()` returning an **object** with `.Visible`, `.Position`, `:Remove()`, etc. (KRNL, Fluxus, and similar).
- **Game:** Script waits for game load only; UI loads immediately. The **Player** tab shows "Waiting for character" until you spawn, then activates (you get a short notification when it's ready).

---

## Adding admins

Only users in the admin list see the **Admin** tab and get admin notifications.

**Option A – Edit the loader (persistent)**  
In `loader.lua`, set `shared.Admins` to a list of Roblox **UserIds** (numbers):

```lua
shared.Admins = { 647347039 }                    -- one admin
shared.Admins = { 647347039, 12345678, 98765432 }  -- multiple
```

**Option B – Set before loading (one-time)**  
In your executor, run this **before** executing the loader:

```lua
(getgenv().CROW_shared or getgenv()).Admins = { 647347039 }
```

Then run the loader as usual. Find UserIds from Roblox profile URLs or user lookup tools.

---

## Config / rebrand

Override config **before** loading the loader so all scripts use your values.

| Variable | Description |
|----------|-------------|
| `CROW_RAW_URL` | Base URL for scripts (default: GitHub raw main branch). |
| `CROW_Config` | Table with: `DiscordInvite`, `ImageBaseUrl`, `SignalUrl`, `WatermarkRefreshrate`, `RobloxGamesApi`. |
| `Admins` | Table of admin UserIds (see above). |
| `CROW_EnemyList` | Table of UserIds for “Enemy list” detection when not using teams. |
| `CROW_DEBUG` | Set to `true` for loader load logs. |

Example (run before loader):

```lua
local g = getgenv().CROW_shared or getgenv()
g.CROW_RAW_URL = "https://your-site.com/scripts/"
g.CROW_Config = {
    DiscordInvite = "https://discord.gg/your-invite",
    ImageBaseUrl = "https://your-site.com/images/",
    WatermarkRefreshrate = 100
}
g.Admins = { 647347039 }
```

In-game, the **Settings** tab lets you change watermark, keybinds, and themes.

---

## Tabs

| Tab | Description |
|-----|-------------|
| **Settings** | Watermark, keybinds, themes, configs, Discord, rejoin, server hop. |
| **Player** | Speed, jump, fly, FOV, noclip, character customization (color, material, glow, outline). |
| **ESP** | Enable ESP, boxes, health, names, tracers, skeleton, team check, customise options. |
| **Aimlock** | Aimlock and Silent Aim (FOV, smoothness, target parts, team/wall check). |
| **World** | Lighting, color correction, blur, fog, ambient. |
| **Admin** | Visible only to users in `Admins`. Blacklist, player list, kick, server info, export. |

---

## Re-execution and teleport

- **Run again:** Execute the loader a second time to unload the current UI and load a fresh one. Safe to run multiple times.
- **After teleport:** If your executor provides `queue_on_teleport`, CROW registers so the loader re-runs after server hop / rejoin (no need to re-paste).

---

## Debug

Set before running the loader:

```lua
(getgenv().CROW_shared or getgenv()).CROW_DEBUG = true
```

Loader will warn script names and basic load progress.

---

## Drawing-only UI (template)

A version of the UI that uses **only** the Drawing API (no `Instance.new`, ScreenGui, or CoreGui):

- **`UiInnitDrawingOnly.lua`** – Same layout/API as UiInnit.lua but 100% Drawing (Square, Text, Circle, Line, Image).
- **`DrawingUITemplate.lua`** – Script template with example window, tabs, sections, and controls: Button, Toggle, Slider, List, Box, Bind, Color, Text, Separator. Copy this file to build your own UI.
- **`loader-drawing.lua`** – Loads Drawing-only UI + template (one window with example controls).

**Run template only (one window with buttons, toggles, etc.):**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROWui/main/loader-drawing.lua"))()
```
Open/close: **Insert** (or use the "Open / Close" keybind in the Main tab). Edit `DrawingUITemplate.lua` to add your options.

---

## File structure

| File | Purpose |
|------|---------|
| `loader.lua` | Entry point: wait for game/character, load scripts, set admins. |
| `loader-drawing.lua` | Loads Drawing-only UI + template (one example window). |
| `UiInnit.lua` | Core UI library, Settings tab, window/tabs. |
| `UiInnitDrawingOnly.lua` | Same UI using only Drawing API (no ScreenGui/CoreGui). |
| `DrawingUITemplate.lua` | Template script: window, tabs, sections, Button/Toggle/Slider/List/Box/Bind/Color. |
| `PlayerSec.lua` | Player tab (speed, fly, character). |
| `ESPsec.lua` | ESP tab. |
| `AimSec.lua` | Aimlock + Silent Aim. |
| `WorldSec.lua` | World tab (lighting, etc.). |
| `AdminPanel.lua` | Admin tab (runs only if user is in `Admins`). |
| `BlacklistedPlayers.lua` | Blacklist data. |
| `signal.lua` | Signal library (loaded by UiInnit). |
| `docs/EXECUTOR_FUNCTIONS.md` | Executor API reference for developers. |

Configs are stored under the executor’s data folder (e.g. `CROW/GameConfigs/`).
