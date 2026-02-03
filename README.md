# CROW

One repo, three projects.

**Config folder layout (executor data):** There is always one top-level folder `CROW`. Inside it, each variant uses its own config subfolder, so configs don’t mix:

| Variant       | Config path (inside `CROW/`)   |
|---------------|--------------------------------|
| Crow Shooter  | `CROW_Shooter_Configs/`        |
| Crow Deepwoken| `CROW_Deepwoken_Configs/`      |

Example: `CROW/CROW_Shooter_Configs/Main.txt`, `CROW/CROW_Deepwoken_Configs/MyConfig.txt`. Other data (e.g. `assets/`) also lives under `CROW/` as needed.

---

| Folder | Name | Description |
|--------|------|-------------|
| **CrowShooter** | Crow Shooter | Main UI: Aimlock, Silent Aim, ESP, Player, World, Admin. Loads from `CrowShooter/`. |
| **CrowUiLib** | Crow UI Library | GUI and Drawing-only UI libraries + templates. Use `CrowUiLib/GUI/` or `CrowUiLib/DRAWING/`. |
| **CrowDeepwoken** | Crow Deepwoken | Drawing-only UI + Deepwoken template (Player, World, ESP, Settings). Loads from `CrowDeepwoken/`. |

---

## CrowShooter (main script)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowShooter/loader.lua"))()
```

---

## CrowUiLib (libraries + templates)

**GUI library:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/GUI/loader.lua"))()
```

**DRAWING library (needs Drawing API):**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowUiLib/DRAWING/loader.lua"))()
```

Templates: `CrowUiLib/GUI/template.lua`, `CrowUiLib/DRAWING/template.lua`.

---

## CrowDeepwoken

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/CROW/main/CrowDeepwoken/loader.lua"))()
```

Requires executor with Drawing API (e.g. KRNL, Fluxus).

---

Replace **wrdzy** with your GitHub username if you use a fork.
