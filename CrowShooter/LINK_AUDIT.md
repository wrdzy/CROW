# CROW UI – Link audit

All URLs used in scripts, checked for correctness and availability.

## Your repo (wrdzy/CROWui) – **OK**

| Script | URL | Status |
|--------|-----|--------|
| loader.lua | `https://raw.githubusercontent.com/wrdzy/CROWui/main/` | Base URL, used for all script loads |
| loader.lua | `https://raw.githubusercontent.com/wrdzy/CROWui/main/loader.lua` | Verified online |
| UiInnit.lua | `https://raw.githubusercontent.com/wrdzy/CROWui/main/signal.lua` | Verified online |
| AdminPanel.lua | Comment only: `.../main/AdminPanel.lua` | Correct format |

Scripts loaded by loader (all use baseUrl + name + ".lua"):  
BlacklistedPlayers.lua, signal.lua, UiInnit.lua, AdminPanel.lua, AimSec.lua, ESPsec.lua, PlayerSec.lua, WorldSec.lua.

---

## External – Luna assets (portallol/luna)

Used in **UiInnit.lua** for gradients and color-picker images:

| Key | URL | Repo path | Note |
|-----|-----|-----------|------|
| gradientp90 | `.../portallol/luna/main/modules/gradient90.png` | modules/gradient90.png | Path exists in repo |
| gradientp45 | `.../portallol/luna/main/modules/gradient45.png` | modules/gradient45.png | Path exists in repo |
| colorhue | `.../portallol/luna/main/modules/lgbtqshit.png` | modules/lgbtqshit.png | Path exists in repo |
| colortrans | `.../portallol/luna/main/modules/trans.png` | modules/trans.png | Path exists in repo |

Repo: https://github.com/portallol/luna (branch main, folder modules).  
If these 404 in-game, host your own copies (e.g. in wrdzy/CROWui or another repo) and update `library.images` in UiInnit.lua.

---

## Roblox APIs – **OK** (runtime)

| Script | URL / Endpoint | Use |
|--------|----------------|-----|
| AdminPanel.lua | `https://users.roblox.com/v1/users/{userId}` | GET user info |
| AdminPanel.lua | `https://users.roblox.com/v1/usernames/users` | POST resolve username → userId |
| UiInnit.lua | `https://games.roblox.com/v1/games/{placeId}/servers/Public?...` | Server list (Server Hop) |

These are official Roblox APIs; no change needed.

---

## Other

| Script | URL | Use |
|--------|-----|-----|
| UiInnit.lua | `https://discord.gg/gvU27E6BUY` | Discord invite (Join Discord button) |

Update this if you use a different Discord invite.

---

## Summary

- **CROWui raw links:** Correct and loader/signal verified.
- **Luna image links:** Paths match repo; if they fail in-game, replace with your own hosted copies.
- **Roblox / Discord:** Standard endpoints/links; update Discord if needed.
