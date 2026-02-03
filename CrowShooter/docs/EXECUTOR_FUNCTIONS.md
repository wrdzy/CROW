# Roblox Executor Functions Reference

Common functions provided by Roblox executors (KRNL, Fluxus, etc.).  
Use this as a reference when writing scripts that run in executors. Availability varies by executor and version.

**User-facing docs:** See [README.md](../README.md) in the repo root for quick start, admins, config, and tabs.

---

## File system

| Function | Description |
|----------|-------------|
| `readfile(path)` | Reads file contents; returns string. Path is usually under executor's workspace (e.g. `workspace/script.txt`). |
| `writefile(path, contents)` | Writes string to file. Many executors block certain extensions (.exe, .bat, .ps1, etc.). |
| `appendfile(path, content)` | Appends content to existing file. |
| `loadfile(path)` | Loads file as Lua chunk (like loadstring for a file). |
| `isfile(path)` | Returns true if path is an existing file. |
| `isfolder(path)` | Returns true if path is an existing folder. |
| `makefolder(path)` | Creates a folder (and parents if needed). |
| `listfiles(folder)` | Returns table of file/folder names in that folder. |
| `delfile(path)` | Deletes a file. |
| `delfolder(path)` | Deletes a folder. |

Paths are often relative to the executor's data folder (e.g. `CROW/configs/`).

---

## Drawing API

Used for on-screen graphics (ESP, FOV circles, UI).  
**Required:** `Drawing` and `Drawing.new(type)` must exist. The return value must be an **object** with properties and `:Remove()`, not a numeric handle.

| Call | Returns | Common properties |
|------|---------|--------------------|
| `Drawing.new("Line")` | Line | `From`, `To`, `Thickness`, `Transparency`, `Color`, `Visible`, `Remove()` |
| `Drawing.new("Text")` | Text | `Text`, `Size`, `Font`, `Position`, `Center`, `Outline`, `OutlineColor`, `Color`, `Visible`, `Remove()` |
| `Drawing.new("Circle")` | Circle | `Position`, `Radius`, `NumSides`, `Filled`, `Thickness`, `Color`, `Transparency`, `Visible`, `Remove()` |
| `Drawing.new("Square")` | Square | `Position`, `Size`, `Filled`, `Thickness`, `Color`, `Transparency`, `Visible`, `Remove()` |
| `Drawing.new("Image")` | Image | `Data`, `Position`, `Size`, `Transparency`, `Visible`, `Remove()` |

**Fonts (typical):** `Drawing.Fonts.UI` (0), `System` (1), `Plex` (2), `Monospace` (3).

---

## Environment

| Function | Description |
|----------|-------------|
| `getgenv()` | Returns the global environment table (shared across scripts in same executor context). |
| `getfenv(fn)` | Returns the environment table of function `fn` (or current function if no arg). |
| `setfenv(fn, env)` | Sets the environment table for function `fn`. Used so scripts share globals (e.g. `_G`, library). |

Scripts that use `setfenv` when loading other scripts can make them all see the same `_G` / globals.

---

## Hooking / metatable (anti-cheat bypass)

Used to intercept function or method calls. Often stored in a backup table (e.g. `_G.CROW_bypass`) so scripts still work if the executor or game overwrites globals.

| Function | Description |
|----------|-------------|
| `hookfunction(original, hook)` | Replaces `original` so calls run `hook` instead. Hook usually calls the saved original. Returns the previous function. |
| `hookmetamethod(obj, method, hook)` | Hooks a metatable metamethod (e.g. `__namecall`) on `obj`. |
| `getrawmetatable(obj)` | Returns the raw metatable of `obj`, bypassing `__metatable`. |
| `setreadonly(tbl, readonly)` | Makes table read-only (true) or writable (false). Used before/after editing metatables. |
| `getnamecallmethod()` | Returns the name of the method being called (inside a `__namecall` hook). |
| `newcclosure(fn)` | Wraps a function as a C closure; some executors require this for hooks. |
| `checkcaller()` | Returns true if the current call is from the executor (not from game code). Used to avoid hooking game’s own calls. |

Example: hook `UserInputService.GetMouseLocation` to change where “mouse” is for silent aim; or hook `workspace.Raycast` / Instance `__namecall` to bend rays.

---

## Execution

| Function | Description |
|----------|-------------|
| `loadstring(source [, chunkname])` | Compiles and returns a function from Lua source string. Executors often restrict or sandbox this. |
| `game:HttpGet(url)` | Fetches URL content (string). Used to load scripts from GitHub raw, etc. |

---

## Executor HTTP (request)

When the game blocks or rate-limits `game:HttpGet`, executor request can succeed. CROW uses **general** executor APIs only (no executor-specific names like `syn`).

| Call | Returns | Notes |
|------|---------|--------|
| `request(options)` | Table with `Body`, `StatusCode`, etc. | `options.Url`, `options.Method = "GET"`. Fluxus and others. |
| `http_request(options)` | Same | Some executors. |

Use `r.Body` for the response body (string). CROW tries these before `game:HttpGet` in the loader and when loading Signal.

---

## Teleport (re-execute after server change)

| Function | Description |
|----------|-------------|
| `queue_on_teleport(code)` | Runs `code` (string) after the player teleports. General API (Fluxus and others). |

CROW uses `queue_on_teleport` when available so the loader re-runs after teleport (e.g. server hop, Rejoin). Connect to `Players.LocalPlayer.OnTeleport` with `Enum.TeleportState.Started` and pass a string that re-executes the loader (e.g. `loadstring(game:HttpGet(loaderUrl))()`).

---

## Clipboard

| Function | Description |
|----------|-------------|
| `setclipboard(text)` | Sets the system clipboard to `text`. General API. |

CROW uses clipboard when “Join Discord” is clicked but the executor has no `request` / `http_request`; it copies the invite link and notifies the user.

---

## CROW UI usage summary

- **File:** `readfile`, `writefile`, `makefolder`, `isfile` (configs, assets).
- **Drawing:** `Drawing.new("Circle")`, `("Line")`, `("Square")`, `("Text")` for ESP and aim FOV/indicators.
- **Environment:** `getgenv()` / shared `_G` so all loaded scripts see the same `library`, tabs, flags.
- **Hooking:** `hookfunction`, `hookmetamethod`, `getrawmetatable`, `setreadonly`, `getnamecallmethod` (optional, for silent aim); stored in `_G.CROW_bypass` so they survive if globals change.
- **Executor HTTP:** `request`, `http_request` (general APIs) used as fallback before `game:HttpGet` for loader and Signal.
- **Teleport:** `queue_on_teleport` used so CROW re-loads after server teleport when the executor provides it.
- **Clipboard:** `setclipboard` used for Discord link when executor has no request.

If your executor lacks any of these, the script may guard with `if func then ... end` or `pcall` and skip that feature.

---

## Stream proof (visible to you, hidden from recording)

**From Lua you cannot** make the overlay visible on your screen but excluded from OBS/screen capture. That requires the **executor** (or OS) to mark its overlay window as “exclude from capture” (e.g. Windows `SetWindowDisplayAffinity`). If your executor has a “Stream proof” or “Hide from OBS” option in its settings, use that; otherwise it is not possible from script alone.
