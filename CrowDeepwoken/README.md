# Crow Deepwoken

Part of **CROW** repo. Drawing-only UI with the Deepwoken template: Player (fly, noclip, speed, etc.), World (lighting), ESP (boxes, health, tracers), and Settings (configs).

Requires an executor with the **Drawing API** (e.g. KRNL, Fluxus).

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/loader.lua"))()
```

Replace **wrdzy** with your GitHub username if you use a fork.

## Custom base URL

Set before running the loader:

```lua
(getgenv().CROW_shared or getgenv()).CROW_RAW_URL = "https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/"
```

## Config (optional, set before running)

- `getgenv().CROW_Config` — library config (UiInnitDrawingOnly)
- `getgenv().CROW_ESPSettings` — ESP defaults
- `getgenv().CROW_ESPConfig` — ESP intervals
- `getgenv().CROW_PlayerConfig` — Player tab defaults
- `getgenv().CROW_WindowConfig` — Window title/size/position

## Files

| File | Description |
|------|-------------|
| `loader.lua` | Entry point; loads signal → UiInnitDrawingOnly → DrawingUITemplate → PlayerSec → ESPsec → WorldSec |
| `signal.lua` | Signal library (required by UI) |
| `UiInnitDrawingOnly.lua` | Drawing-only UI library (no ScreenGui) |
| `DrawingUITemplate.lua` | Deepwoken window: Player, ESP, World, Settings tabs |
| `PlayerSec.lua` | Player tab: fly, noclip, speed, FOV, etc. |
| `ESPsec.lua` | ESP: boxes, health, names, tracers, skeleton |
| `WorldSec.lua` | World tab: lighting, color correction, fog, etc. |
