# CrowUiLib (CROW UI Library)

Part of **CROW** repo. Two UI libraries + templates: **GUI** (ScreenGui) and **DRAWING** (Drawing API only).

Loadstrings use: `https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/...`

---

## CrowUiLib/GUI

GUI library (UiInnit) + minimal template. Uses Roblox instances (ScreenGui, frames, etc.).

### Load library

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/loader.lua"))()
```

### Run template (after loader)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/template.lua"))()
```

### Files

| File | Description |
|------|-------------|
| `loader.lua` | Loads signal → UiInnit, returns library |
| `signal.lua` | Signal dependency |
| `UiInnit.lua` | GUI library (windows, tabs, toggles, sliders, etc.) |
| `template.lua` | Minimal example window with one tab and options |

---

## CrowUiLib/DRAWING

Drawing-only UI library (UiInnitDrawingOnly) + minimal template. **Requires executor with Drawing API** (e.g. KRNL, Fluxus). No ScreenGui; all UI is drawn with `Drawing.new`.

### Load library

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/loader.lua"))()
```

### Run template (after loader)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/template.lua"))()
```

### Files

| File | Description |
|------|-------------|
| `loader.lua` | Loads signal → UiInnitDrawingOnly, returns library |
| `signal.lua` | Signal dependency |
| `UiInnitDrawingOnly.lua` | Drawing-only UI library |
| `template.lua` | Minimal example window (Drawing) |

---

## Custom base URL

Set before running a loader to use your own fork:

```lua
(getgenv().CROW_shared or getgenv()).CROW_RAW_URL = "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/"
-- or for DRAWING:
(getgenv().CROW_shared or getgenv()).CROW_RAW_URL = "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/"
```

Replace **wrdzy** with your GitHub username if needed.
