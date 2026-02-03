local startupArgs = ({...})[1] or {}

if getgenv().library ~= nil then
    getgenv().library:Unload();
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function gs(a)
    return game:GetService(a)
end

-- // Variables
local players, http, runservice, inputservice, tweenService, stats, actionservice = gs('Players'), gs('HttpService'), gs('RunService'), gs('UserInputService'), gs('TweenService'), gs('Stats'), gs('ContextActionService')
local localplayer = players.LocalPlayer

local setByConfig = false
local floor, ceil, huge, pi, clamp = math.floor, math.ceil, math.huge, math.pi, math.clamp
local c3new, fromrgb, fromhsv = Color3.new, Color3.fromRGB, Color3.fromHSV
local next, newInstance, newUDim2, newVector2 = next, Instance.new, UDim2.new, Vector2.new
local isexecutorclosure = isexecutorclosure or iskrnlclosure or (type(identifyexecutor) == "function" and identifyexecutor() ~= nil);
local executor = (
    identifyexecutor and select(1, identifyexecutor()) or
    getexecutorname and getexecutorname() or
    'unknown'
)
getgenv().executor = executor


-- Central config: no hardcoded URLs/values in logic. Override library.config or startupArgs before init.
local defaultConfig = {
    DiscordInvite = 'https://discord.gg/gvU27E6BUY';
    ImageBaseUrl = 'https://raw.githubusercontent.com/portallol/luna/main/modules/';
    SignalUrl = 'https://raw.githubusercontent.com/wrdzy/CROWui/main/signal.lua';
    WatermarkRefreshrate = 100;
    RobloxGamesApi = 'https://games.roblox.com/v1/games/';
}
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
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and res and #res > 0 then body = res end
    end
    return body
end
local signalUrl = (startupArgs and startupArgs.config and startupArgs.config.SignalUrl) or defaultConfig.SignalUrl
local signalSrc = fetchUrl(signalUrl)
if not signalSrc or #signalSrc == 0 then
    local ok, res = pcall(game.HttpGet, game, signalUrl)
    if ok and res then signalSrc = res end
end
local library = {
    windows = {};
    indicators = {};
    flags = {};
    options = {};
    connections = {};
    drawings = {};
    instances = {};
    utility = {};
    notifications = {};
    tweens = {};
    theme = {};
    config = (startupArgs and startupArgs.config) or (getgenv and getgenv().CROW_Config) or defaultConfig;
    zindexOrder = {
        ['indicator'] = 950;
        ['window'] = 1000;
        ['dropdown'] = 1200;
        ['colorpicker'] = 1100;
        ['watermark'] = 1300;
        ['notification'] = 1400;
        ['cursor'] = 1500;
    },
    stats = { ['fps'] = 0; ['ping'] = 0; };
    images = {};
    numberStrings = {['Zero'] = 0, ['One'] = 1, ['Two'] = 2, ['Three'] = 3, ['Four'] = 4, ['Five'] = 5, ['Six'] = 6, ['Seven'] = 7, ['Eight'] = 8, ['Nine'] = 9};
    signal = (_G.Signal or (signalSrc and #signalSrc > 0 and loadstring(signalSrc)()) or loadstring(game:HttpGet(signalUrl))());
    open = false;
    opening = false;
    hasInit = false;
    cheatname = startupArgs.cheatname or 'CROW';
    configname = startupArgs.configname or 'CROW_Shooter_Configs';
    fileext = startupArgs.fileext or '.txt';
}
do
    local base = (library.config and library.config.ImageBaseUrl) or defaultConfig.ImageBaseUrl
    library.images['gradientp90'] = base .. 'gradient90.png'
    library.images['gradientp45'] = base .. 'gradient45.png'
    library.images['colorhue'] = base .. 'lgbtqshit.png'
    library.images['colortrans'] = base .. 'trans.png'
end

library.themes = {
    {
        name = 'Default',
        theme = {
            ['Accent']                    = fromrgb(25,118,210);  -- Vibrant deep blue
            ['Background']                = fromrgb(17,17,17);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(47,47,47);
            ['Border 2']                  = fromrgb(17,17,17);
            ['Border 3']                  = fromrgb(10,10,10);
            ['Primary Text']              = fromrgb(235,235,235);
            ['Group Background']          = fromrgb(17,17,17);
            ['Selected Tab Background']   = fromrgb(17,17,17);
            ['Unselected Tab Background'] = fromrgb(17,17,17);
            ['Selected Tab Text']         = fromrgb(245,245,245);
            ['Unselected Tab Text']       = fromrgb(145,145,145);
            ['Section Background']        = fromrgb(17,17,17);
            ['Option Text 1']             = fromrgb(245,245,245);
            ['Option Text 2']             = fromrgb(195,195,195);
            ['Option Text 3']             = fromrgb(145,145,145);
            ['Option Border 1']           = fromrgb(47,47,47);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(35,35,35);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Midnight',
        theme = {
            ['Accent']                    = fromrgb(103,89,179);
            ['Background']                = fromrgb(22,22,31);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(50,50,50);
            ['Border 2']                  = fromrgb(24,25,37);
            ['Border 3']                  = fromrgb(10,10,10);
            ['Primary Text']              = fromrgb(235,235,235);
            ['Group Background']          = fromrgb(24,25,37);
            ['Selected Tab Background']   = fromrgb(24,25,37);
            ['Unselected Tab Background'] = fromrgb(22,22,31);
            ['Selected Tab Text']         = fromrgb(245,245,245);
            ['Unselected Tab Text']       = fromrgb(145,145,145);
            ['Section Background']        = fromrgb(22,22,31);
            ['Option Text 1']             = fromrgb(245,245,245);
            ['Option Text 2']             = fromrgb(195,195,195);
            ['Option Text 3']             = fromrgb(145,145,145);
            ['Option Border 1']           = fromrgb(50,50,50);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(24,25,37);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Nekocheat',
        theme = {
            ["Accent"]                    = fromrgb(226, 30, 112);
            ["Background"]                = fromrgb(18,18,18);
            ["Border"]                    = fromrgb(0,0,0);
            ["Border 1"]                  = fromrgb(60,60,60);
            ["Border 2"]                  = fromrgb(18,18,18);
            ["Border 3"]                  = fromrgb(10,10,10);
            ["Primary Text"]              = fromrgb(255,255,255);
            ["Group Background"]          = fromrgb(18,18,18);
            ["Selected Tab Background"]   = fromrgb(18,18,18);
            ["Unselected Tab Background"] = fromrgb(18,18,18);
            ["Selected Tab Text"]         = fromrgb(245,245,245);
            ["Unselected Tab Text"]       = fromrgb(145,145,145);
            ["Section Background"]        = fromrgb(18,18,18);
            ["Option Text 1"]             = fromrgb(255,255,255);
            ["Option Text 2"]             = fromrgb(255,255,255);
            ["Option Text 3"]             = fromrgb(255,255,255);
            ["Option Border 1"]           = fromrgb(50,50,50);
            ["Option Border 2"]           = fromrgb(0,0,0);
            ["Option Background"]         = fromrgb(23,23,23);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Nekocheat Blue',
        theme = {
            ["Accent"]                    = fromrgb(0, 247, 255);
            ["Background"]                = fromrgb(18,18,18);
            ["Border"]                    = fromrgb(0,0,0);
            ["Border 1"]                  = fromrgb(60,60,60);
            ["Border 2"]                  = fromrgb(18,18,18);
            ["Border 3"]                  = fromrgb(10,10,10);
            ["Primary Text"]              = fromrgb(255,255,255);
            ["Group Background"]          = fromrgb(18,18,18);
            ["Selected Tab Background"]   = fromrgb(18,18,18);
            ["Unselected Tab Background"] = fromrgb(18,18,18);
            ["Selected Tab Text"]         = fromrgb(245,245,245);
            ["Unselected Tab Text"]       = fromrgb(145,145,145);
            ["Section Background"]        = fromrgb(18,18,18);
            ["Option Text 1"]             = fromrgb(255,255,255);
            ["Option Text 2"]             = fromrgb(255,255,255);
            ["Option Text 3"]             = fromrgb(255,255,255);
            ["Option Border 1"]           = fromrgb(50,50,50);
            ["Option Border 2"]           = fromrgb(0,0,0);
            ["Option Background"]         = fromrgb(23,23,23);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Fatality',
        theme = {
            ['Accent']                    = fromrgb(197,7,83);
            ['Background']                = fromrgb(25,19,53);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(60,53,93);
            ['Border 2']                  = fromrgb(29,23,66);
            ['Border 3']                  = fromrgb(10,10,10);
            ['Primary Text']              = fromrgb(235,235,235);
            ['Group Background']          = fromrgb(29,23,66);
            ['Selected Tab Background']   = fromrgb(29,23,66);
            ['Unselected Tab Background'] = fromrgb(25,19,53);
            ['Selected Tab Text']         = fromrgb(245,245,245);
            ['Unselected Tab Text']       = fromrgb(145,145,145);
            ['Section Background']        = fromrgb(25,19,53);
            ['Option Text 1']             = fromrgb(245,245,245);
            ['Option Text 2']             = fromrgb(195,195,195);
            ['Option Text 3']             = fromrgb(145,145,145);
            ['Option Border 1']           = fromrgb(60,53,93);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(29,23,66);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Gamesense',
        theme = {
            ['Accent']                    = fromrgb(147,184,26);
            ['Background']                = fromrgb(17,17,17);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(47,47,47);
            ['Border 2']                  = fromrgb(17,17,17);
            ['Border 3']                  = fromrgb(10,10,10);
            ['Primary Text']              = fromrgb(235,235,235);
            ['Group Background']          = fromrgb(17,17,17);
            ['Selected Tab Background']   = fromrgb(17,17,17);
            ['Unselected Tab Background'] = fromrgb(17,17,17);
            ['Selected Tab Text']         = fromrgb(245,245,245);
            ['Unselected Tab Text']       = fromrgb(145,145,145);
            ['Section Background']        = fromrgb(17,17,17);
            ['Option Text 1']             = fromrgb(245,245,245);
            ['Option Text 2']             = fromrgb(195,195,195);
            ['Option Text 3']             = fromrgb(145,145,145);
            ['Option Border 1']           = fromrgb(47,47,47);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(35,35,35);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Twitch',
        theme = {
            ['Accent']                    = fromrgb(169,112,255);
            ['Background']                = fromrgb(14,14,14);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(45,45,45);
            ['Border 2']                  = fromrgb(31,31,35);
            ['Border 3']                  = fromrgb(10,10,10);
            ['Primary Text']              = fromrgb(235,235,235);
            ['Group Background']          = fromrgb(31,31,35);
            ['Selected Tab Background']   = fromrgb(31,31,35);
            ['Unselected Tab Background'] = fromrgb(17,17,17);
            ['Selected Tab Text']         = fromrgb(225,225,225);
            ['Unselected Tab Text']       = fromrgb(160,170,175);
            ['Section Background']        = fromrgb(17,17,17);
            ['Option Text 1']             = fromrgb(245,245,245);
            ['Option Text 2']             = fromrgb(195,195,195);
            ['Option Text 3']             = fromrgb(145,145,145);
            ['Option Border 1']           = fromrgb(45,45,45);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(24,24,27);
            ["Risky Text"]                = fromrgb(175, 21, 21);
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41);
        }
    },
    {
        name = 'Ocean Breeze',
        theme = {
            ['Accent']                    = fromrgb(0,188,212);
            ['Background']                = fromrgb(11,19,43);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(38,50,76);
            ['Border 2']                  = fromrgb(15,23,47);
            ['Border 3']                  = fromrgb(8,12,24);
            ['Primary Text']              = fromrgb(230,245,255);
            ['Group Background']          = fromrgb(15,23,47);
            ['Selected Tab Background']   = fromrgb(15,23,47);
            ['Unselected Tab Background'] = fromrgb(11,19,43);
            ['Selected Tab Text']         = fromrgb(230,245,255);
            ['Unselected Tab Text']       = fromrgb(140,160,180);
            ['Section Background']        = fromrgb(11,19,43);
            ['Option Text 1']             = fromrgb(230,245,255);
            ['Option Text 2']             = fromrgb(180,200,220);
            ['Option Text 3']             = fromrgb(140,160,180);
            ['Option Border 1']           = fromrgb(38,50,76);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(19,27,51);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Forest Night',
        theme = {
            ['Accent']                    = fromrgb(76,175,80);
            ['Background']                = fromrgb(16,24,16);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(42,52,42);
            ['Border 2']                  = fromrgb(20,28,20);
            ['Border 3']                  = fromrgb(10,14,10);
            ['Primary Text']              = fromrgb(230,245,230);
            ['Group Background']          = fromrgb(20,28,20);
            ['Selected Tab Background']   = fromrgb(20,28,20);
            ['Unselected Tab Background'] = fromrgb(16,24,16);
            ['Selected Tab Text']         = fromrgb(230,245,230);
            ['Unselected Tab Text']       = fromrgb(140,170,140);
            ['Section Background']        = fromrgb(16,24,16);
            ['Option Text 1']             = fromrgb(230,245,230);
            ['Option Text 2']             = fromrgb(180,210,180);
            ['Option Text 3']             = fromrgb(140,170,140);
            ['Option Border 1']           = fromrgb(42,52,42);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(24,32,24);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Sunset Glow',
        theme = {
            ['Accent']                    = fromrgb(255,152,0);
            ['Background']                = fromrgb(26,18,11);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(56,42,28);
            ['Border 2']                  = fromrgb(30,22,15);
            ['Border 3']                  = fromrgb(15,11,8);
            ['Primary Text']              = fromrgb(255,245,230);
            ['Group Background']          = fromrgb(30,22,15);
            ['Selected Tab Background']   = fromrgb(30,22,15);
            ['Unselected Tab Background'] = fromrgb(26,18,11);
            ['Selected Tab Text']         = fromrgb(255,245,230);
            ['Unselected Tab Text']       = fromrgb(180,160,140);
            ['Section Background']        = fromrgb(26,18,11);
            ['Option Text 1']             = fromrgb(255,245,230);
            ['Option Text 2']             = fromrgb(220,200,180);
            ['Option Text 3']             = fromrgb(180,160,140);
            ['Option Border 1']           = fromrgb(56,42,28);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(34,26,19);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Arctic Ice',
        theme = {
            ['Accent']                    = fromrgb(79,195,247);
            ['Background']                = fromrgb(18,22,25);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(48,56,64);
            ['Border 2']                  = fromrgb(22,26,29);
            ['Border 3']                  = fromrgb(12,14,16);
            ['Primary Text']              = fromrgb(245,250,255);
            ['Group Background']          = fromrgb(22,26,29);
            ['Selected Tab Background']   = fromrgb(22,26,29);
            ['Unselected Tab Background'] = fromrgb(18,22,25);
            ['Selected Tab Text']         = fromrgb(245,250,255);
            ['Unselected Tab Text']       = fromrgb(160,180,200);
            ['Section Background']        = fromrgb(18,22,25);
            ['Option Text 1']             = fromrgb(245,250,255);
            ['Option Text 2']             = fromrgb(200,220,240);
            ['Option Text 3']             = fromrgb(160,180,200);
            ['Option Border 1']           = fromrgb(48,56,64);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(26,30,33);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Crimson Blade',
        theme = {
            ['Accent']                    = fromrgb(220,38,127);
            ['Background']                = fromrgb(20,12,14);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(52,32,36);
            ['Border 2']                  = fromrgb(24,16,18);
            ['Border 3']                  = fromrgb(12,8,10);
            ['Primary Text']              = fromrgb(255,240,245);
            ['Group Background']          = fromrgb(24,16,18);
            ['Selected Tab Background']   = fromrgb(24,16,18);
            ['Unselected Tab Background'] = fromrgb(20,12,14);
            ['Selected Tab Text']         = fromrgb(255,240,245);
            ['Unselected Tab Text']       = fromrgb(180,140,150);
            ['Section Background']        = fromrgb(20,12,14);
            ['Option Text 1']             = fromrgb(255,240,245);
            ['Option Text 2']             = fromrgb(220,180,190);
            ['Option Text 3']             = fromrgb(180,140,150);
            ['Option Border 1']           = fromrgb(52,32,36);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(28,20,22);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Cyber Matrix',
        theme = {
            ['Accent']                    = fromrgb(0,255,65);
            ['Background']                = fromrgb(5,10,5);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(25,45,25);
            ['Border 2']                  = fromrgb(8,15,8);
            ['Border 3']                  = fromrgb(3,6,3);
            ['Primary Text']              = fromrgb(0,255,65);
            ['Group Background']          = fromrgb(8,15,8);
            ['Selected Tab Background']   = fromrgb(8,15,8);
            ['Unselected Tab Background'] = fromrgb(5,10,5);
            ['Selected Tab Text']         = fromrgb(0,255,65);
            ['Unselected Tab Text']       = fromrgb(0,180,45);
            ['Section Background']        = fromrgb(5,10,5);
            ['Option Text 1']             = fromrgb(0,255,65);
            ['Option Text 2']             = fromrgb(0,220,55);
            ['Option Text 3']             = fromrgb(0,180,45);
            ['Option Border 1']           = fromrgb(25,45,25);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(12,20,12);
            ["Risky Text"]                = fromrgb(255, 65, 65);
            ["Risky Text Enabled"]        = fromrgb(255, 85, 85);
        }
    },
    {
        name = 'Royal Purple',
        theme = {
            ['Accent']                    = fromrgb(156,39,176);
            ['Background']                = fromrgb(18,10,20);
            ['Border']                    = fromrgb(0,0,0);
            ['Border 1']                  = fromrgb(48,30,52);
            ['Border 2']                  = fromrgb(22,14,24);
            ['Border 3']                  = fromrgb(10,6,12);
            ['Primary Text']              = fromrgb(250,240,255);
            ['Group Background']          = fromrgb(22,14,24);
            ['Selected Tab Background']   = fromrgb(22,14,24);
            ['Unselected Tab Background'] = fromrgb(18,10,20);
            ['Selected Tab Text']         = fromrgb(250,240,255);
            ['Unselected Tab Text']       = fromrgb(170,140,180);
            ['Section Background']        = fromrgb(18,10,20);
            ['Option Text 1']             = fromrgb(250,240,255);
            ['Option Text 2']             = fromrgb(210,180,220);
            ['Option Text 3']             = fromrgb(170,140,180);
            ['Option Border 1']           = fromrgb(48,30,52);
            ['Option Border 2']           = fromrgb(0,0,0);
            ['Option Background']         = fromrgb(26,18,28);
            ["Risky Text"]                = fromrgb(255, 87, 87);
            ["Risky Text Enabled"]        = fromrgb(255, 107, 107);
        }
    },
    {
        name = 'Ghost White',
        theme = {
            ['Accent']                    = fromrgb(96,125,139);
            ['Background']                = fromrgb(250,250,250);
            ['Border']                    = fromrgb(200,200,200);
            ['Border 1']                  = fromrgb(220,220,220);
            ['Border 2']                  = fromrgb(240,240,240);
            ['Border 3']                  = fromrgb(230,230,230);
            ['Primary Text']              = fromrgb(33,33,33);
            ['Group Background']          = fromrgb(245,245,245);
            ['Selected Tab Background']   = fromrgb(240,240,240);
            ['Unselected Tab Background'] = fromrgb(250,250,250);
            ['Selected Tab Text']         = fromrgb(33,33,33);
            ['Unselected Tab Text']       = fromrgb(117,117,117);
            ['Section Background']        = fromrgb(248,248,248);
            ['Option Text 1']             = fromrgb(33,33,33);
            ['Option Text 2']             = fromrgb(66,66,66);
            ['Option Text 3']             = fromrgb(117,117,117);
            ['Option Border 1']           = fromrgb(220,220,220);
            ['Option Border 2']           = fromrgb(200,200,200);
            ['Option Background']         = fromrgb(255,255,255);
            ["Risky Text"]                = fromrgb(211, 47, 47);
            ["Risky Text Enabled"]        = fromrgb(244, 67, 54);
        }
    }
}

local blacklistedKeys = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,
    Enum.KeyCode.Slash,
    Enum.KeyCode.Tab,
    Enum.KeyCode.Escape
}

local whitelistedBoxKeys = {
    Enum.KeyCode.Zero,
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
    Enum.KeyCode.Nine
}

local keyNames = {
    [Enum.KeyCode.LeftControl] = 'LCTRL';
    [Enum.KeyCode.RightControl] = 'RCTRL';
    [Enum.KeyCode.LeftShift] = 'LSHIFT';
    [Enum.KeyCode.RightShift] = 'RSHIFT';
    [Enum.UserInputType.MouseButton1] = 'MB1';
    [Enum.UserInputType.MouseButton2] = 'MB2';
    [Enum.UserInputType.MouseButton3] = 'MB3';
}

library.button1down = library.signal.new()
library.button1up   = library.signal.new()
library.mousemove   = library.signal.new()
library.unloaded    = library.signal.new();

local button1down, button1up, mousemove = library.button1down, library.button1up, library.mousemove
local mb1down = false;

local utility = library.utility
do

    function utility:Connection(signal, func)
        local c = signal:Connect(func)
        table.insert(library.connections, c)
        return c
    end

    function utility:Instance(class, properties)
        local inst = newInstance(class)
        for prop, val in next, properties or {} do
            local s,e = pcall(function()
                inst[prop] = val
            end)
            if not s then
                printconsole(e, 255,0,0)
            end
        end
        return inst
    end

    function utility:HasProperty(obj, prop)
        return ({(pcall(function() local a = obj[prop] end))})[1]
    end

    function utility:ToRGB(c3)
        return c3.R*255,c3.G*255,c3.B*255
    end

    function utility:AddRGB(a,b)
        local r1,g1,b1 = self:ToRGB(a);
        local r2,g2,b2 = self:ToRGB(b);
        return fromrgb(clamp(r1+r2,0,255),clamp(g1+g2,0,255),clamp(b1+b2,0,255))
    end

    function utility:ConvertNumberRange(val,oldmin,oldmax,newmin,newmax)
        return (((val - oldmin) * (newmax - newmin)) / (oldmax - oldmin)) + newmin
    end

    function utility:UDim2ToVector2(udim2, vector2)
        local x,y
        x = udim2.X.Offset + self:ConvertNumberRange(udim2.X.Scale,0,1,0,vector2.X)
        y = udim2.Y.Offset + self:ConvertNumberRange(udim2.Y.Scale,0,1,0,vector2.Y)
        return newVector2(x,y)
    end

    function utility:Lerp(a,b,c)
        return a + (b-a) * c
    end

    function utility:Tween(obj, prop, val, time, direction, style)
        if self:HasProperty(obj, prop) then
            if library.tweens[obj] then
                if library.tweens[obj][prop] then
                    pcall(function() library.tweens[obj][prop]:Cancel() end)
                end
            end

            local startVal = obj[prop];
            local a = 0;
            local tween = {
                Completed = library.signal.new();
            };

            library.tweens[obj] = library.tweens[obj] or {};
            library.tweens[obj][prop] = tween;

            tween.Connection = self:Connection(runservice.RenderStepped, function(dt)
                a = a + (dt / time);
                if a >= 1 or obj == nil then
                    tween:Cancel();
                end
                pcall(function()
                    local progress = tweenService:GetValue(a, style or Enum.EasingStyle.Linear, direction or Enum.EasingDirection.In)
                    local newVal
                    if typeof(startVal) == 'number' then
                        newVal = utility:Lerp(startVal, val, progress);
                    else
                        newVal = startVal:Lerp(val, progress);
                    end
                    obj[prop] = newVal;
                end)
            end)

            function tween:Cancel()
                pcall(function()
                    if tween.Connection and tween.Connection.Disconnect then
                        tween.Connection:Disconnect()
                    end
                end)
                pcall(function()
                    if tween.Completed and tween.Completed.Fire then
                        tween.Completed:Fire()
                    end
                end)
                table.clear(tween);
                if library.tweens and obj and library.tweens[obj] then
                    library.tweens[obj][prop] = nil;
                end
            end
            
            return tween;
        else
            printconsole('unable to tween: invalid property '..tostring(prop)..' for object '..tostring(obj), 255,0,0)
        end
    end

    function utility:DetectTableChange(indexcallback,newindexcallback)
        if indexcallback == nil then
            warn('DetectTableChange: Argument #1 (indexcallback) is nil, function may not work as expected.')
        elseif newindexcallback == nil then
            warn('DetectTableChange: Argument #2 (newindexcallback) is nil, function may not work as expected.')
        end
        local proxy = newproxy(true);
        local mt = getmetatable(proxy);
        mt.__index = indexcallback
        mt.__newindex = newindexcallback
        return proxy
    end

    function utility:MouseOver(obj)
        local mousePos = inputservice:GetMouseLocation();
        local x1 = obj.Position.X
        local y1 = obj.Position.Y
        local x2 = x1 + obj.Size.X
        local y2 = y1 + obj.Size.Y
        return (mousePos.X >= x1 and mousePos.Y >= y1 and mousePos.X <= x2 and mousePos.Y <= y2)
    end

    function utility:GetHoverObject()
        local objects = {}
        for i,v in next, library.drawings do
            if v and v.Object and (type(v.Object) == "userdata" or type(v.Object) == "table") and v.Object.Visible and v.Class == 'Square' and self:MouseOver(v.Object) then
                table.insert(objects,v.Object)
            end
        end
        table.sort(objects,function(a,b)
            return a.ZIndex > b.ZIndex
        end)
        return objects[1]
    end

    function utility:Draw(class, properties)
        if not Drawing or type(Drawing.new) ~= "function" then
            error("CROW UI requires an executor with Drawing API. Drawing or Drawing.new is missing.")
        end
        local rawObj = Drawing.new(class)
        if rawObj == nil then
            error("CROW UI: Drawing.new returned nil. Use an executor that supports the Drawing API.")
        end
        if type(rawObj) == "number" then
            error("CROW UI: This executor returns a numeric handle from Drawing.new; we need an object with .Visible, .Position, etc. Use KRNL, Fluxus, or an executor that provides Drawing objects (see executor docs).")
        end
        if type(rawObj) ~= "userdata" and type(rawObj) ~= "table" then
            error("CROW UI: Drawing.new returned " .. type(rawObj) .. "; expected Drawing object. Use an executor that supports Drawing API.")
        end
        local blacklistedProperties = {'Object','Children','Class'}
        local drawing = {
            Object = rawObj;
            Children = {};
            ThemeColor = '';
            OutlineThemeColor = '';
            ThemeColorOffset = 0;
            OutlineThemeColorOffset = 0;
            Parent = nil;
            Size = newUDim2(0,0,0,0);
            Position = newUDim2(0,0,0,0);
            AbsoluteSize = newVector2(0,0);
            AbsolutePosition = newVector2(0,0);
            Hover = false;
            Visible = true;
            MouseButton1Down = library.signal.new();
            MouseButton2Down = library.signal.new();
            MouseButton1Up = library.signal.new();
            MouseButton2Up = library.signal.new();
            MouseEnter = library.signal.new();
            MouseLeave = library.signal.new();
            Class = class;
        }

        function drawing:Update()
            local obj = drawing.Object
            if obj == nil or type(obj) == "number" or (type(obj) ~= "userdata" and type(obj) ~= "table") then
                return
            end
            local parent = drawing.Parent ~= nil and library.drawings[drawing.Parent and drawing.Parent.Object] or nil
            local parentSize,parentPos,parentVis = workspace.CurrentCamera.ViewportSize, Vector2.new(0,0), true;
            if parent ~= nil and parent.Object and (type(parent.Object) == "userdata" or type(parent.Object) == "table") then
                parentSize = (parent.Class == 'Square' or parent.Class == 'Image') and parent.Object.Size or parent.Class == 'Text' and parent.TextBounds or workspace.CurrentCamera.ViewportSize
                parentPos = parent.Object.Position
                parentVis = parent.Object.Visible
            end

            if drawing.Class == 'Square' or drawing.Class == 'Image' then
                obj.Size = typeof(drawing.Size) == 'Vector2' and drawing.Size or typeof(drawing.Size) == 'UDim2' and utility:UDim2ToVector2(drawing.Size,parentSize)
            end

            if drawing.Class == 'Square' or drawing.Class == 'Image' or drawing.Class == 'Circle' or drawing.Class == 'Text' then
                obj.Position = parentPos + (typeof(drawing.Position) == 'Vector2' and drawing.Position or utility:UDim2ToVector2(drawing.Position,parentSize))
            end

            pcall(function() obj.Visible = (parentVis and drawing.Visible) and true or false end)
            drawing:UpdateChildren()
        end

        function drawing:UpdateChildren()
            for i,v in next, drawing.Children do
                v:Update()
            end
        end

        function drawing:GetDescendants()
            local descendants = {};
            local function a(t)
                for _,v in next, t.Children do
                    table.insert(descendants, v);
                    a(v)
                end
            end
            a(self)
            return descendants;
        end

        library.drawings[drawing.Object] = drawing

        -- Reject numbers (some 2026 executors return handle IDs); we need indexable objects with .Visible, etc.
        local function objOk(o)
            return o ~= nil and type(o) ~= "number" and (type(o) == "userdata" or type(o) == "table")
        end
        local proxy = utility:DetectTableChange(
        function(obj,i)
            if drawing[i] ~= nil then return drawing[i] end
            if not objOk(drawing.Object) then return nil end
            return drawing.Object[i]
        end,
        function(obj,i,v)
            if not table.find(blacklistedProperties,i) then

                local lastval = drawing[i]

                if not objOk(drawing.Object) then
                    drawing[i] = v
                    return
                end
                if i == 'Size' and (class == 'Square' or class == 'Image') then
                    drawing.Size = v
                    drawing.Object.Size = utility:UDim2ToVector2(v,drawing.Parent == nil and workspace.CurrentCamera.ViewportSize or (drawing.Parent and objOk(drawing.Parent.Object) and drawing.Parent.Object.Size) or workspace.CurrentCamera.ViewportSize);
                    drawing.AbsoluteSize = drawing.Object.Size;
                elseif i == 'Position' and (class == 'Square' or class == 'Image' or class == 'Text') then
                    drawing.Position = v
                    drawing.Object.Position =  utility:UDim2ToVector2(v,drawing.Parent == nil and newVector2(0,0) or (drawing.Parent and objOk(drawing.Parent.Object) and drawing.Parent.Object.Position) or newVector2(0,0));
                    drawing.AbsolutePosition = drawing.Object.Position;
                elseif i == 'Parent' then
                    if drawing.Parent ~= nil then
                        drawing.Parent.Children[drawing] = nil
                    end
                    if v ~= nil then
                        table.insert(v.Children,drawing)
                    end
                elseif i == 'Visible' then
                    drawing.Visible = v
                elseif i == 'Font' then
                if executor == 'Wave' and v == 2 then
                    v = 1
                elseif executor == 'Sirhurt' and v == 2 then
                    v = 1
                elseif executor == 'Solware' and v == 2 then
                    v = 1
                elseif executor == 'AWP.GG' and v == 3 then
                    v = 2
                elseif executor == 'Potassium' and v == 2 then
                    v = 1
                elseif executor == 'Loveware' and v == 2 then
                    v = 1
                end
            elseif i == 'Size' and drawing.Class == 'Text' then
                -- Text size scaling for different executors
                local scaleFactors = {
                    ['Wave'] = 1.0,
                    ['Zenith'] = 1.0,
                    ['AWP.GG'] = 0.95,
                    ['Volcano'] = 1.0,
                    ['Velocity'] = 1.0,
                    ['Swift'] = 1.0,
                    ['Solware'] = 0.9,
                    ['Potassium'] = 0.95,
                    ['Solara'] = 1.0,
                    ['Visual'] = 1.0,
                    ['Xeno'] = 1.0,
                    ['Sirhurt'] = 0.85,
                    ['Loveware'] = 0.9
                }
                local scale = scaleFactors[executor] or 1.0
                v = math.floor(v * scale)
            end

                pcall(function()
                    drawing.Object[i] = v
                end)
                if drawing[i] ~= nil or i == 'Parent' then
                    drawing[i] = v
                end

                if table.find({'Size','Position','Position','Visible','Parent'},i) then
                    drawing:Update()
                end
                if table.find({'ThemeColor','OutlineThemeColor','ThemeColorOffset','OutlineThemeColorOffset'},i) and lastval ~= v then
                    library.UpdateThemeColors()
                end

            end
        end)

        function drawing:Remove()
            for i,v in next, self.Children do
                v:Remove();
            end

            if drawing.Parent then
                drawing.Parent.Children[drawing.Object] = nil;
            end

            library.drawings[drawing.Object] = nil;
            if type(drawing.Object) ~= "number" and (type(drawing.Object) == "userdata" or type(drawing.Object) == "table") then
                pcall(function() drawing.Object:Remove() end)
            end
            table.clear(drawing);

        end

        properties = typeof(properties) == 'table' and properties or {}

        if class == 'Square' and properties.Filled == nil then
            properties.Filled = true;
        end

        if properties.Visible == nil then
            properties.Visible = true;
        end

        for i,v in next, properties do
            proxy[i] = v
        end

        drawing:Update()
        return proxy
    end
end

library.utility = utility

function library:Unload()
    library.unloaded:Fire();
    for _,c in next, self.connections do
        pcall(function() c:Disconnect() end)
    end
    for obj in next, self.drawings do
        pcall(function() obj:Remove() end)
    end
    table.clear(self.drawings)
    local g = getgenv and getgenv() or _G
    if g then
        g.library = nil
        g.CROW = nil
        g.PlayerTab = nil
        g.ESPTab = nil
        g.Aimlock = nil
        g.WorldTab = nil
        g.AdminTab = nil
    end
end

function library:init()
    if self.hasInit then
        return
    end

    local tooltipObjects = {};

    -- Wrap executor-only calls so init can complete and define NewWindow even if these fail
    pcall(function()
        if makefolder then
            makefolder(self.cheatname)
            makefolder(self.cheatname..'/assets')
            makefolder(self.cheatname..'/'..self.configname)
        end
    end)

    function self:SetTheme(theme)
        for i,v in next, theme do
            self.theme[i] = v;
        end
        self.UpdateThemeColors();
    end

    function self:GetConfig(name)
        name = tostring(name or ""):gsub("[^%w%-%_]", "")
        if name == "" then return nil end
        local path = self.cheatname..'/'..self.configname..'/'..name..self.fileext
        if isfile and isfile(path) then
            return readfile(path)
        end
        return nil
    end

    function library:LoadConfig(name)
    name = tostring(name or ""):gsub("[^%w%-%_]", "")
    if name == "" then
        self:SendNotification('Invalid config name.', 5, c3new(1,0,0))
        return
    end
    local cfg = self:GetConfig(name)
    if not cfg then
        self:SendNotification('Config does not exist: '..name, 5, c3new(1,0,0))
        return
    end

    local s,e = pcall(function()
        setByConfig = true
        
        -- Decode the JSON config
        local decodedCfg = http:JSONDecode(cfg)
        
        -- Validate that decodedCfg is a table
        if type(decodedCfg) ~= "table" then
            error("Invalid config format: expected table, got " .. type(decodedCfg))
        end

        local worldNoApply = (_G.WorldConfigFlags and type(_G.WorldConfigFlags) == "table") and _G.WorldConfigFlags or {}
        local function applyDefault(option)
            if not option or not option.flag then return end
            local noApply = worldNoApply[option.flag]
            if option.class == 'toggle' then
                option:SetState(option.state == true, noApply)
            elseif option.class == 'slider' then
                option:SetValue(option.default or option.min or 0, noApply)
            elseif option.class == 'bind' then
                option:SetBind('none')
            elseif option.class == 'color' then
                -- keep current or skip
            elseif option.class == 'list' then
                local def = option.default or (option.values and #option.values > 0 and option.values[1]) or (option.multi and {} or '')
                option:Select(def, true)
            elseif option.class == 'box' then
                option:SetInput(option.default or '')
            end
        end

        if next(decodedCfg) == nil then
            for _, option in next, library.options do
                applyDefault(option)
            end
        else
            for flag, value in next, decodedCfg do
                local option = library.options[flag]
                if option and option.class then
                    local noApply = worldNoApply[flag]
                    if option.class == 'toggle' then
                        option:SetState(value == nil and false or (value == 1 or value == true), noApply);
                    elseif option.class == 'slider' then
                        local v = value
                        if type(v) ~= "number" then v = option.default or option.min end
                        option:SetValue(v, noApply)
                    elseif option.class == 'bind' then
                        local bindVal = 'none'
                        if value ~= nil and type(value) == 'string' and value ~= '' and value:lower() ~= 'none' then
                            if utility:HasProperty(Enum.KeyCode, value) then
                                bindVal = Enum.KeyCode[value]
                            elseif utility:HasProperty(Enum.UserInputType, value) then
                                bindVal = Enum.UserInputType[value]
                            end
                        end
                        option:SetBind(bindVal)
                    elseif option.class == 'color' then
                        if type(value) == "table" and #value >= 3 then
                            local r, g, b = tonumber(value[1]) or 0, tonumber(value[2]) or 0, tonumber(value[3]) or 0
                            option:SetColor(c3new(r, g, b), noApply)
                            if value[4] ~= nil then
                                option:SetTrans(tonumber(value[4]) or 0, noApply)
                            end
                        end
                    elseif option.class == 'list' then
                        local v = value
                        if v == nil then v = option.default or (option.values and option.values[1]) or '' end
                        option:Select(v, true)
                    elseif option.class == 'box' then
                        option:SetInput(value == nil and (option.default or '') or tostring(value))
                    end
                end
            end
        end
        setByConfig = false
    end)

    if s then
        self:SendNotification('Successfully loaded config: '..name, 5, c3new(0,1,0));
    else
        self:SendNotification('Error loading config: '..tostring(e)..'. ('..tostring(name)..')', 5, c3new(1,0,0));
        
        -- If the config is corrupted, offer to reset it
        if e and (e:find("invalid argument") or e:find("JSONDecode")) then
            self:SendNotification('Config appears to be corrupted. Creating backup and resetting...', 5, c3new(1,0.5,0));
            
            -- Create a backup of the corrupted config
            pcall(function()
                writefile(self.cheatname..'/'..self.configname..'/'..name..'_backup_'..os.time()..self.fileext, cfg);
            end)
            
            -- Reset the config file with empty data
            pcall(function()
                writefile(self.cheatname..'/'..self.configname..'/'..name..self.fileext, http:JSONEncode({}));
            end)
        end
    end
end

-- SaveConfig: save current options to named config; create file and folder if needed
function library:SaveConfig(name)
    name = tostring(name or ""):gsub("[^%w%-%_]", "")
    if name == "" then
        self:SendNotification('Invalid config name.', 5, c3new(1,0,0))
        return
    end
    pcall(function()
        if makefolder then
            makefolder(self.cheatname)
            makefolder(self.cheatname..'/'..self.configname)
        end
    end)

    local s,e = pcall(function()
        local cfg = {};
        for flag,option in next, self.options do
            if not option or not option.class then continue end
            if option.class == 'toggle' then
                local state = (self.flags and self.flags[flag] ~= nil) and self.flags[flag] or option.state;
                cfg[flag] = state and 1 or 0;
            elseif option.class == 'slider' then
                cfg[flag] = option.value;
            elseif option.class == 'bind' then
                local b = option.bind;
                cfg[flag] = (type(b) == "userdata" and b and b.Name) or "none";
            elseif option.class == 'color' then
                local c = option.color;
                local r = (c and (c.R or c.r)) or 0;
                local g = (c and (c.G or c.g)) or 0;
                local b = (c and (c.B or c.b)) or 0;
                cfg[flag] = { r, g, b, option.trans or 0 };
            elseif option.class == 'list' then
                cfg[flag] = option.selected;
            elseif option.class == 'box' then
                cfg[flag] = option.input or "";
            end
        end
        writefile(self.cheatname..'/'..self.configname..'/'..name..self.fileext, http:JSONEncode(cfg));
    end)

    if s then
        self:SendNotification('Successfully saved config: '..name, 5, c3new(0,1,0));
    else
        self:SendNotification('Error saving config: '..tostring(e)..'. ('..tostring(name)..')', 5, c3new(1,0,0));
    end
end

    pcall(function()
        for i,v in next, self.images do
            if type(v) == 'string' and v:match('^https?://') then
                if isfile and not isfile(self.cheatname..'/assets/'..i..'.oh') then
                    if writefile and game and game.HttpGet then
                        local ok, data = pcall(game.HttpGet, game, v)
                        if ok and data and #data > 0 then
                            writefile(self.cheatname..'/assets/'..i..'.oh', data)
                        end
                    end
                end
                if readfile and isfile and isfile(self.cheatname..'/assets/'..i..'.oh') then
                    self.images[i] = readfile(self.cheatname..'/assets/'..i..'.oh');
                end
                -- If still a URL (download failed), clear so Drawing doesn't get URL as Data
                if type(self.images[i]) == 'string' and self.images[i]:match('^https?://') then
                    self.images[i] = nil
                end
            end
        end
    end)

    self.cursor1 = utility:Draw('Triangle', {Filled = true, Color = fromrgb(255,255,255), ZIndex = self.zindexOrder.cursor});
    self.cursor2 = utility:Draw('Triangle', {Filled = true, Color = fromrgb(85,85,85), self.zindexOrder.cursor-1});
    local function updateCursor()
        self.cursor1.Visible = self.open
        self.cursor2.Visible = self.open
        if self.cursor1.Visible then
            local pos = inputservice:GetMouseLocation();
            self.cursor1.PointA = pos;
            self.cursor1.PointB = pos + newVector2(16,5);
            self.cursor1.PointC = pos + newVector2(5,16);
            self.cursor2.PointA = self.cursor1.PointA + newVector2(0, 0)
            self.cursor2.PointB = self.cursor1.PointB + newVector2(1, 1)
            self.cursor2.PointC = self.cursor1.PointC + newVector2(1, 1)
        end
    end

    -- Create fullscreen overlay only when main menu is opened (not during safe mode). No ScreenGui exists until first SetOpen(true).
    library.screenGui = nil

    local function ensureScreenGui()
        if library.screenGui and library.screenGui.Parent then return library.screenGui end
        local sg = Instance.new('ScreenGui')
        sg.Parent = game:GetService('CoreGui')
        utility:Instance('ImageButton', {
            Parent = sg,
            Visible = true,
            Modal = true,
            Size = UDim2.new(1,0,1,0),
            ZIndex = 9999999999,
            Transparency = 1;
        })
        library.screenGui = sg
        return sg
    end

    utility:Connection(library.unloaded, function()
        if library.screenGui then pcall(function() library.screenGui:Destroy() end) library.screenGui = nil end
    end)

    -- True when main menu is open OR a modal dialog window is visible (e.g. safe mode). Lets dialog receive clicks/hover without SetOpen(true).
    local function inputActive()
        if library.open then return true end
        if library._dialogWindow and library._dialogWindow.objects and library._dialogWindow.objects.background then
            return library._dialogWindow.objects.background.Visible
        end
        return false
    end

    utility:Connection(inputservice.InputBegan, function(input, gpe)
        if self.hasInit then
            if input.KeyCode == self.toggleKey and not library.opening and not gpe then
                library.opening = true
                self:SetOpen(not self.open)
                task.spawn(function()
                    task.wait(.15)
                    library.opening = false
                end)
            end
            if inputActive() then
                local hoverObj = utility:GetHoverObject();
                local hoverObjData = library.drawings[hoverObj];
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mb1down = true;
                    button1down:Fire()
                    if hoverObj and hoverObjData then
                        hoverObjData.MouseButton1Down:Fire(inputservice:GetMouseLocation())
                    end

                    -- // Update Sliders Click
                    if library.draggingSlider ~= nil then
                        local rel = inputservice:GetMouseLocation() - library.draggingSlider.objects.background.Object.Position;
                        local val = utility:ConvertNumberRange(rel.X, 0 , library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max);
                        library.draggingSlider:SetValue(val)
                    end

                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    if hoverObj and hoverObjData then
                        hoverObjData.MouseButton2Down:Fire(inputservice:GetMouseLocation())
                    end
                end
            end
        end
    end)

    utility:Connection(inputservice.InputEnded, function(input, gpe)
        if self.hasInit and inputActive() then
            local hoverObj = utility:GetHoverObject();
            local hoverObjData = library.drawings[hoverObj];

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mb1down = false;
                button1up:Fire();
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton1Up:Fire(inputservice:GetMouseLocation())
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton2Up:Fire(inputservice:GetMouseLocation())
                end
            end
        end
    end)

    utility:Connection(inputservice.InputChanged, function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if inputActive() then
                mousemove:Fire(inputservice:GetMouseLocation());
                updateCursor();

                if library.CurrentTooltip ~= nil then
                    local mousePos = inputservice:GetMouseLocation()
                    tooltipObjects.background.Position = UDim2.new(0,mousePos.X + 15,0,mousePos.Y + 15)
                    tooltipObjects.background.Size = UDim2.new(0,tooltipObjects.text.TextBounds.X + 6 + (library.CurrentTooltip.risky and 60 or 0),0,tooltipObjects.text.TextBounds.Y + 2)
                end

                local hoverObj = utility:GetHoverObject();
                for _,v in next, library.drawings do
                    local hover = hoverObj == v.Object;
                    if hover and not v.Hover then
                        v.Hover = true;
                        v.MouseEnter:Fire(inputservice:GetMouseLocation());
                    elseif not hover and v.Hover then
                        v.Hover = false;
                        v.MouseLeave:Fire(inputservice:GetMouseLocation());
                    end
                end

                if mb1down then

                    -- // Update Sliders Drag
                    if library.draggingSlider ~= nil then
                        local rel = inputservice:GetMouseLocation() - library.draggingSlider.objects.background.Object.Position;
                        local val = utility:ConvertNumberRange(rel.X, 0 , library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max);
                        library.draggingSlider:SetValue(val)
                    end

                end
            end
        end
    end)
    
    function self:SetOpen(bool)
    self.open = bool;
    pcall(function()
        if bool then
            local sg = ensureScreenGui()
            if sg and sg.Enabled ~= nil then sg.Enabled = true end
        elseif library.screenGui and library.screenGui.Enabled ~= nil then
            library.screenGui.Enabled = false
        end
    end)

    -- Hide or show the Roblox cursor based on menu state
    local function hideCursor()
        pcall(function()
            inputservice.MouseIconEnabled = false
            local mouse = localplayer and localplayer:GetMouse()
            if mouse then
                mouse.Icon = "rbxasset://textures/Blank.png"
            end
            actionservice:BindAction("HideCursor", function()
                return Enum.ContextActionResult.Sink
            end, false, Enum.UserInputType.MouseMovement)
        end)
    end

    local function showCursor()
        pcall(function()
            inputservice.MouseIconEnabled = true
            local mouse = localplayer and localplayer:GetMouse()
            if mouse then
                mouse.Icon = ""
            end
            actionservice:UnbindAction("HideCursor")
        end)
    end

    if bool then
        hideCursor()
    else
        showCursor()
    end

    if bool and library.flags.disablemenumovement then
        actionservice:BindAction(
            'FreezeMovement',
            function()
                return Enum.ContextActionResult.Sink
            end,
            false,
            unpack(Enum.PlayerActions:GetEnumItems())
        )
    else
        actionservice:UnbindAction('FreezeMovement');
    end

    updateCursor();
    for _, window in next, self.windows do
        pcall(function()
            if window and window.SetOpen then
                window:SetOpen(bool);
            end
        end)
    end

    library.CurrentTooltip = nil;
    pcall(function()
        if tooltipObjects and tooltipObjects.background then
            tooltipObjects.background.Visible = false
        end
    end)
end


    function self.UpdateThemeColors()
        for _,v in next, library.drawings do
            if type(v.Object) == "number" or (type(v.Object) ~= "userdata" and type(v.Object) ~= "table") then continue end
            if v.ThemeColor and library.theme[v.ThemeColor] then
                pcall(function() v.Object.Color = utility:AddRGB(library.theme[v.ThemeColor],fromrgb(v.ThemeColorOffset,v.ThemeColorOffset,v.ThemeColorOffset)) end)
            end
            if v.ThemeColorOutline and library.theme[v.ThemeColorOutline] then
                pcall(function() v.Object.OutlineColor = utility:AddRGB(library.theme[v.ThemeColorOutline],fromrgb(v.OutlineThemeColorOffset,v.OutlineThemeColorOffset,v.OutlineThemeColorOffset)) end)
            end
        end
    end

    function self:SendNotification(message, time, color)
        time = time or 5
        if typeof(message) ~= 'string' then
            return error(string.format('invalid message type, got %s, expected string', typeof(message)))
        elseif typeof(time) ~= 'number' then
            return error(string.format('invalid time type, got %s, expected number', typeof(time)))
        elseif color ~= nil and typeof(color) ~= 'Color3' then
            return error(string.format('invalid color type, got %s, expected color3', typeof(time)))
        end

        local notification = {};

        self.notifications[notification] = true

        do
            local objs = notification;
            local z = self.zindexOrder.notification;

            notification.holder = utility:Draw('Square', {
                Position = newUDim2(0, 0, 0, 75);
                Transparency = 0;
            })
            
            notification.background = utility:Draw('Square', {
                Size = newUDim2(1,0,1,0);
                Position = newUDim2(0, -500, 0, 0);
                Parent = notification.holder;
                ThemeColor = 'Background';
                ZIndex = z;
            })

            notification.border1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 2';
                Parent = notification.background;
                ZIndex = z-1;
            })

            objs.border2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                Parent = objs.border1;
                ZIndex = z-2;
            })

            notification.gradient = utility:Draw('Image', {
                Size = newUDim2(1,0,1,0);
                Data = self.images.gradientp90;
                Parent = notification.background;
                Transparency = .5;
                ZIndex = z+1;
            })

            notification.accentBar = utility:Draw('Square',{
                Size = newUDim2(0,5,1,4);
                Position = newUDim2(0,0,0,-2);
                Parent = notification.background;
                ThemeColor = color == nil and 'Accent' or '';
                ZIndex = z+5;
            })

            notification.text = utility:Draw('Text', {
                Position = newUDim2(0,13,0,2);
                ThemeColor = 'Primary Text';
                Text = message;
                Outline = true;
                Font = 2;
                Size = 13;
                ZIndex = z+4;
                Parent = notification.background;
            })

            if color then
                notification.accentBar.Color = color;
            end

        end

        function notification:Remove()
            library.notifications[notification] = nil;
            self.holder:Remove();
            library:UpdateNotifications()
        end

        task.spawn(function()
            self:UpdateNotifications();
            notification.background.Size = newUDim2(0, notification.text.TextBounds.X + 20, 0, 19)
            task.wait();
            utility:Tween(notification.background, 'Position', newUDim2(0,0,0, 0), .1);
            task.wait(time);
            for i,v in next, notification do
                if typeof(v) ~= 'function' then
                    utility:Tween(v, 'Transparency', 0, .15);
                end
            end
            utility:Connection(utility:Tween(notification.background, 'Position', newUDim2(0,-500,0, 0), .25).Completed, (function()
                notification:Remove();
            end))
        end)

    end

    function self:UpdateNotifications()
        local i = 0
        for v in next, self.notifications do
            utility:Tween(v.holder, 'Position', newUDim2(0,0,0, 75 + (i * 30)), .15)
            i += 1
        end
    end

    function self.NewIndicator(data)
        local indicator = {
            title = data.title or 'indicator',
            enabled = data.enabled or false,
            position = data.position or newUDim2(0,15,0,300),
            values = {},
            objects = {valueObjects = {}},
            spacing = '   ',
        };

        table.insert(self.indicators, indicator)

        -- Create Objects --
        do
            local z = self.zindexOrder.indicator;
            local objs = indicator.objects;

            objs.background = utility:Draw('Square', {
                Size = newUDim2(0, 200, 0, 16);
                Position = indicator.position;
                ThemeColor = 'Background';
                ZIndex = z;
            })

            objs.border1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 2';
                Parent = objs.background;
                ZIndex = z-1;
            })

            objs.border2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                Parent = objs.border1;
                ZIndex = z-2;
            })

            objs.topborder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                Parent = objs.background;
                ZIndex = z+1;
            })

            objs.textlabel = utility:Draw('Text', {
                Position = newUDim2(.5,0,0,1);
                ThemeColor = 'Primary Text';
                Text = indicator.title;
                Size = 13;
                Font = 2;
                ZIndex = z+2;
                Center = true;
                Outline = true;
                Parent = objs.background;
            });

        end
        --------------------

        function indicator:Update()
            local xSize  = 125
            local yPos  = 0
            table.sort(self.values, function(a,b)
                return a.order < b.order;
            end)

            for _,v in next, self.values do
                v.objects.keyLabel.Text = tostring(v.key);
                v.objects.valueLabel.Text = tostring(v.value);
            
                v.objects.valueLabel.Position = newUDim2(1,-(v.objects.valueLabel.TextBounds.X + 3),0,0)
                v.objects.background.Position = newUDim2(0,0,1,3 + yPos)
                v.objects.background.Visible = v.enabled

                if v.enabled then
                    yPos = yPos + 16 + 3
                    local x = (v.objects.keyLabel.TextBounds.X + 10 + v.objects.valueLabel.TextBounds.X)
                    if x > xSize then
                        xSize = x
                    end
                end
            end

            self.objects.background.Size = newUDim2(0,xSize + 8,0,16)
            self.objects.background.Position = self.position
        end

        function indicator:AddValue(data)
            local value = {
                key = data.key or '',
                value = data.value or '',
                order = data.order or #self.values+1,
                enabled = data.enabled == nil and true or data.enabled,
                objects = {},
            }

            table.insert(self.values, value);

            -- Create Objects --
            do
                local z = library.zindexOrder.indicator;
                local objs = value.objects;

                objs.background = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 16);
                    ThemeColor = 'Background';
                    ZIndex = z;
                    Parent = indicator.objects.background;
                })
    
                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 2';
                    Parent = objs.background;
                    ZIndex = z-1;
                })
    
                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 3';
                    Parent = objs.border1;
                    ZIndex = z-2;
                })
    
                objs.keyLabel = utility:Draw('Text', {
                    Position = newUDim2(0,3,0,1);
                    ThemeColor = 'Option Text 2';
                    Size = 13;
                    Font = 2;
                    ZIndex = z+2;
                    Outline = true;
                    Parent = objs.background;
                });

                objs.valueLabel = utility:Draw('Text', {
                    Position = newUDim2(0,0,0,1);
                    ThemeColor = 'Option Text 2';
                    Size = 13;
                    Font = 2;
                    ZIndex = z+2;
                    Outline = true;
                    Parent = objs.background;
                });

            end
            --------------------

            function value:Remove()
                table.remove(indicator.values, table.find(indicator.values, value))
                self.objects.background:Remove()
                table.clear(self)
                indicator:Update();
            end

            function value:SetEnabled(bool)
                if typeof(bool) == 'boolean' then
                    self.enabled = bool
                    indicator:Update()
                end
            end

            function value:SetValue(str)
                if typeof(str) == 'string' then
                    self.value = str
                    indicator:Update()
                end
            end

            function value:SetKey(str)
                if typeof(str) == 'string' then
                    self.key = str
                    indicator:Update()
                end
            end

            self:Update()
            return value
        end

        function indicator:GetValue(idx)
            if typeof(idx) == 'number' then
                return self.values[idx]
            else
                for i,v in next, self.values do
                    if v.key == idx then
                        return v
                    end
                end
            end
        end

        function indicator:SetEnabled(bool)
            if typeof(bool) == 'boolean' then
                self.enabled = bool;
                self.objects.background.Visible = bool;
                self:Update();
            end
        end

        function indicator:SetPosition(udim2)
            if typeof(udim2) == 'UDim2' then
                self.position = udim2
                self.objects.background.Position = udim2;
            end
        end

        for i,v in next, data.values or {} do
            indicator:AddValue({key = tostring(i), value = tostring(v)})
        end

        indicator:SetEnabled(indicator.enabled);
        return indicator
    end

    function self.NewWindow(data)
        local window = {
            title = data.title or '';
            selectedTab = nil;
            tabs = {};
            objects = {};
            resizeToContent = data.resizeToContent == true;
            _contentMinWidth = data.contentMinWidth or 320;
            _contentCenter = data.contentCenter ~= false;
            colorpicker = {
                objects = {};
                color = c3new(1,0,0);
                trans = 0;
            };
            dropdown = {
                objects = {
                    values = {};
                };
                max = 5;
            }
        };

        table.insert(library.windows, window);

        ----- Create Objects ----
        do
            local size = data.size or newUDim2(0, 525, 0, 650);
            local position = data.position or newUDim2(0, 250, 0, 150);
            local objs = window.objects;
            local z = library.zindexOrder.window;

            objs.background = utility:Draw('Square', {
                Size = size;
                Position = position;
                ThemeColor = 'Background';
                ZIndex = z;
            })

            objs.innerBorder1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z-1;
                Parent = objs.background;
            })

            objs.innerBorder2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z-2;
                Parent = objs.innerBorder1;
            })

            objs.midBorder = utility:Draw('Square', {
                Size = newUDim2(1,10,1,25);
                Position = newUDim2(0,-5,0,-20);
                ThemeColor = 'Border 2';
                ZIndex = z-3;
                Parent = objs.innerBorder2;
            })

            objs.outerBorder1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z-4;
                Parent = objs.midBorder;
            })

            objs.outerBorder2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z-5;
                Parent = objs.outerBorder1;
            })

            objs.topBorder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                ZIndex = z+1;
                Parent = objs.background;
            })

            objs.title = utility:Draw('Text', {
                Position = newUDim2(0,7,0,2);
                ThemeColor = 'Primary Text';
                Text = window.title;
                Font = 2;
                Size = 13;
                ZIndex = z+1;
                Outline = true;
                Parent = objs.midBorder;
            })

            objs.groupBackground = utility:Draw('Square', {
                Size = newUDim2(1,-16,1,-(16+23));
                Position = newUDim2(0,8,0,8+23);
                ThemeColor = 'Group Background';
                ZIndex = z+5;
                Parent = objs.background;
            })

            objs.groupInnerBorder = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 1';
                ZIndex = z+4;
                Parent = objs.groupBackground;
            })

            objs.groupOuterBorder = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                ZIndex = z+3;
                Parent = objs.groupInnerBorder;
            })

            objs.tabHolder = utility:Draw('Square', {
                Size = newUDim2(1,0,0,20);
                Position = newUDim2(0,0,0,-21);
                Parent = objs.groupBackground;
                Transparency = 0;
                ZIndex = z+1;
            })

            objs.columnholder1 = utility:Draw('Square', {
                Size = newUDim2(.48, 0, .96, 0);
                Position = newUDim2(.01, 0, .02, 0);
                Transparency = 0;
                ZIndex = z+6;
                Parent = objs.groupBackground;
            })

            objs.columnholder2 = utility:Draw('Square', {
                Size = newUDim2(.48, 0, .96, 0);
                Position = newUDim2(1 - (.48 + .01), 0, .02, 0);
                Transparency = 0;
                ZIndex = z+6;
                Parent = objs.groupBackground;
            })


            objs.dragdetector = utility:Draw('Square',{
                Size = newUDim2(1,0,1,0);
                Parent = objs.midBorder;
                Transparency = 0;
                ZIndex = z+2;
            })

            local dragging, mouseStart, objStart;

            utility:Connection(objs.dragdetector.MouseButton1Down, function(pos)
                dragging = true;
                mouseStart = newUDim2(0, pos.X, 0, pos.Y);
                objStart = objs.background.Position;
            end)

            utility:Connection(button1up, function()
                dragging = false;
            end)

            utility:Connection(mousemove, function(pos)
                if dragging then
                    if window.open then
                        objs.background.Position = objStart + newUDim2(0, pos.X, 0, pos.Y) - mouseStart;
                    else
                        dragging = false
                    end
                end
            end)

        end
        -------------------------

        -- Create Color Picker --
        do
            -- Objects
            do
                local objs = window.colorpicker.objects;
                local z = library.zindexOrder.colorpicker;

                objs.background = utility:Draw('Square', {
                    Visible = false;
                    Size = newUDim2(0,200,0,242);
                    Position = newUDim2(1,-200,1,10);
                    ThemeColor = 'Background';
                    ZIndex = z;
                    Parent = window.objects.background;
                })

                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-1;
                    Parent = objs.background;
                })

                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 1';
                    ZIndex = z-2;
                    Parent = objs.border1;
                })

                objs.border3 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-3;
                    Parent = objs.border2;
                })

                objs.statusText = utility:Draw('Text', {
                    Position = newUDim2(0,5,0,4);
                    Text = 'colorpicker_status_text';
                    ThemeColor = 'Option Text 1';
                    Size = 13;
                    Font = 2;
                    Outline = true;
                    ZIndex = z+1;
                    Parent = objs.background;
                })

                objs.mainColor = utility:Draw('Square', {
                    Size = newUDim2(0, 175, 0, 175);
                    Position = newUDim2(0, 5, 0, 25);
                    Color = c3new(1,0,0);
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.sat1 = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = crypt.base64decode("iVBORw0KGgoAAAANSUhEUgAAAaQAAAGkCAQAAADURZm+AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JQAAgIMAAPn/AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VGAAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQflBwwSLzK3wl3KAAADrElEQVR42u3TORLCMBBFwT+6/50hMqXSZgonBN0BWCDGYPwqeSWVZPWYVHd0Pc5H86v9areu4Sz9u7XZXT/vvtZtu6dtJtYw525iGya05afnWW17ltPE8fzfTZy/yf3vmCes59xf0Sf/42l3lnvGOyyH+y/bo/X689wCPCYkEBIICYQECAmEBEICIQFCAiGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEguAQgJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEiAkEBIICYQECAmEBEICIQFCAiGBkEBIgJBASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZAAIYGQQEggJEBIICQQEggJEBIICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIgJBASCAmEBAgJhARCAiEBQgIhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEICIQFCAiGBkEBILgEICYQEQgKEBEICIYGQACGBkEBIICRASCAkEBIICRASCAmEBEIChARCAiGBkAAhgZBASICQQEggJBASICQQEggJhAQICYQEQgIhAUICIYGQQEiAkEBIICQQEiAkEBIICYQECAmEBEIChARCAiGBkAAhgZBASCAkQEggJBASCAkQEggJhARCAoQEQgIhgZAAIYGQQEggJEBIICQQEiAkEBL8lzft9AVFFzN+ywAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0xMlQxODo0Nzo1MCswMDowMIxlM90AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMTJUMTg6NDc6NTArMDA6MDD9OIthAAAAAElFTkSuQmCC");
                    ZIndex = z+3;
                    Parent = objs.mainColor;
                })

                objs.sat2 = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = crypt.base64decode("iVBORw0KGgoAAAANSUhEUgAAAaQAAAGkCAQAAADURZm+AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JQAAgIMAAPn/AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VGAAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQflBwwSLyBEeyyCAAAD4klEQVR42u3YwQnAQAhFQTek/5pz9eBtEYzMlBD4PDcRADDBieMjwK3HJwBDghFepx0oEhgSOO0ARQJDAqcdKBJgSGBI4I0EhgQ47cCQwJDAGwlQJDAkcNqBIgGKBIoEhgROO0CRQJFAkQBDAqcdGBI47QBFAkUCQwKnHaBIoEigSKBIgCKBIYHTDhQJUCQwJHDagSIBigSGBE47UCRAkcCQwGkHKBIoEigSGBLgtANDAkMCbyTAkMBpB4oEigQoEhgSOO1AkQBDAqcdKBIoEqBIYEjgtANFUiRQJFAkMCTAaQeKBIoEigQYEjjtQJFAkQBFAkMCpx0oEmBI4LQDRQJFAhQJDAmcdqBIgCKBIoEhAU47UCRQJFAkwJDAaQeKBIYEOO1AkUCRYHuRTAmcduC0A0UCFAkUCQwJnHaAIoEigSKBIQFOO2gvkimBIoE3EhgS4LQDRQJDAqcdoEigSKBIYEiAIYEhwXx+NoAigSGB0w5QJDAkMCQwJKDiZwMoEhgSOO0ARQJFgnlFMiVw2oHTDhQJUCRQJDAkcNoBVZFMCRQJvJHAkACnHSgSKBIoElANSZPAaQdOOzAkwGkHigSGBIYEGBK08LMBFAkUCRQJMCQwJDAkWMjPBlAkMCRw2gG5SKYEigTeSGBIgNMOFAkMCQwJMCRo4WcDKBIYEjjtgFwkUwJFAm8kMCTAaQeKBIoEigRUQ9IkcNqB0w4MCXDagSKBIsHCIpkSOO3AaQeKBCgSKBIYEhgSYEjQws8GUCQwJHDaAblIpgSKBN5IYEiA0w4UCQwJDAkwJGjhZwMoEhgSOO0ARQJDAkMCQwIqfjaAIoEigSIBhgROO5hXJFMCpx047UCRAEUCRQJDAqcdUBXJlECRwBsJDAlw2oEigSKBIgGGBIYEhgSL+dkAigSGBE47QJHAkMBpB4oEGBIYEhgSrOZnAygSKBIoEmBI4LQDRQJFAhQJDAmcdrC8SKYEigTeSGBIgNMOFAkMCZx2gCKBIoEigSEBTjtQJFAkUCTAkMBpB4oEigQoEhgSOO1AkQBDAqcdKBKgSKBIYEjgtAMUCRQJFAkMCXDagSKBIoEiAYYETjtQJFAkQJHAkMBpB4oEGBI47UCRQJEARQJDAqcdoEigSGBI4LQDFAkUCRQJFAkwJHDagSKBIQFOOzAkMCTwRgIMCZx2oEigSIAigSKBIYHTzkcARQJFAkMCnHZgSGBI4I0EGBI47UCRQJEAQwKnHSgSKBKgSGBI4LQDRQIUCRQJDAmcdoAigSGB0w5QJFAkUCQwJMBpB4oEhgROO0CRwJDAkMAbCVAkMCT4gw/reQYigE05fAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0xMlQxODo0NzozMiswMDowMN2VK3MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMTJUMTg6NDc6MzIrMDA6MDCsyJPPAAAAAElFTkSuQmCC");
                    ZIndex = z+4;
                    Parent = objs.mainColor;
                })

                objs.colorBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.mainColor;
                })

                objs.mainDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Transparency = 0;
                    ZIndex = z+10;
                    Parent = objs.mainColor;
                })

                objs.hue = utility:Draw('Image', {
                    Size = newUDim2(0,175,0,10);
                    Position = newUDim2(0,5,0,205);
                    Data = library.images.colorhue;
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.hueBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.hue;
                })

                objs.hueDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Transparency = 0;
                    ZIndex = z+10;
                    Parent = objs.hue;
                })

                objs.transColor = utility:Draw('Square', {
                    Size = newUDim2(0,10,0,175);
                    Position = newUDim2(0,185,0,25);
                    Color = c3new(1,0,0);
                    ZIndex = z+2;
                    Parent = objs.background;
                })

                objs.trans = utility:Draw('Image', {
                    Size = newUDim2(1,0,1,0);
                    Data = library.images.colortrans;
                    ZIndex = z+3;
                    Parent = objs.transColor;
                })

                objs.transBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z+1;
                    Parent = objs.transColor;
                })

                objs.transDetector = utility:Draw('Square',{
                    Size = newUDim2(1,0,1,0);
                    Transparency = 0;
                    ZIndex = z+10;
                    Parent = objs.transColor;
                })

                objs.pointer = utility:Draw('Square', {
                    Size = newUDim2(0,2,0,2);
                    Position = newUDim2(0,0,0,0);
                    Color = c3new(1,1,1);
                    ZIndex = z+6;
                    Parent = objs.mainColor;
                })

                objs.pointerBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+5;
                    Parent = objs.pointer;
                })

                objs.hueSlider = utility:Draw('Square', {
                    Size = newUDim2(0,1,1,0);
                    Color = c3new(1,1,1);
                    ZIndex = z+4;
                    Parent = objs.hue;
                })

                objs.hueSliderBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+3;
                    Parent = objs.hueSlider;
                })

                objs.transSlider = utility:Draw('Square', {
                    Size = newUDim2(1,0,0,1);
                    Color = c3new(1,1,1);
                    ZIndex = z+5;
                    Parent = objs.trans;
                })

                objs.transSliderBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+4;
                    Parent = objs.transSlider;
                })

                objs.rBackground = utility:Draw('Square', {
                    Size = newUDim2(0, 60, 0, 15);
                    Position = newUDim2(0, 5, 1, - 20);
                    ThemeColor = 'Option Background';
                    Parent = objs.background;
                    ZIndex = z+5;
                })

                objs.rBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+4;
                    Parent = objs.rBackground;
                })

                objs.rText = utility:Draw('Text', {
                    Position = newUDim2(.5,0,0,0);
                    Color = c3new(1,.1,.1);
                    Text = 'R';
                    Size = 13;
                    Font = 2;
                    Outline = true;
                    Center = true;
                    ZIndex = z+6;
                    Parent = objs.rBackground;
                })

                objs.gBackground = utility:Draw('Square', {
                    Size = newUDim2(0, 60, 0, 15);
                    Position = newUDim2(0, 70, 1, - 20);
                    ThemeColor = 'Option Background';
                    Parent = objs.background;
                    ZIndex = z+5;
                })

                objs.gBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+4;
                    Parent = objs.gBackground;
                })

                objs.gText = utility:Draw('Text', {
                    Position = newUDim2(.5,0,0,0);
                    Color = c3new(.1,1,.1);
                    Text = 'G';
                    Size = 13;
                    Font = 2;
                    Outline = true;
                    Center = true;
                    ZIndex = z+6;
                    Parent = objs.gBackground;
                })

                objs.bBackground = utility:Draw('Square', {
                    Size = newUDim2(0, 60, 0, 15);
                    Position = newUDim2(0, 135, 1, - 20);
                    ThemeColor = 'Option Background';
                    Parent = objs.background;
                    ZIndex = z+5;
                })

                objs.bBorder = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    Color = c3new(0,0,0);
                    ZIndex = z+4;
                    Parent = objs.bBackground;
                })

                objs.bText = utility:Draw('Text', {
                    Position = newUDim2(.5,0,0,0);
                    Color = c3new(.1,.1,1);
                    Text = 'B';
                    Size = 13;
                    Font = 2;
                    Outline = true;
                    Center = true;
                    ZIndex = z+6;
                    Parent = objs.bBackground;
                })

                local draggingHue, draggingSat, draggingTrans = false, false, false;

                local function updateSatVal(pos)
                    if window.colorpicker.selected ~= nil then
                        local hue, sat, val = window.colorpicker.selected.color:ToHSV()
                        X = (objs.mainColor.Object.Position.X + objs.mainColor.Object.Size.X) - objs.mainColor.Object.Position.X
                        Y = (objs.mainColor.Object.Position.Y + objs.mainColor.Object.Size.Y) - objs.mainColor.Object.Position.Y
                        X = math.clamp((pos.X - objs.mainColor.Object.Position.X) / X, 0, 0.995)
                        Y = math.clamp((pos.Y - objs.mainColor.Object.Position.Y) / Y, 0, 0.995)
                        sat, val = 1 - X, 1 - Y;
                        window.colorpicker.selected:SetColor(fromhsv(hue,sat,val));
                        window.colorpicker:Visualize(fromhsv(hue, sat, val), window.colorpicker.selected.trans);
                    end
                end

                local function updateHue(pos)
                    if window.colorpicker.selected ~= nil then
                        local hue, sat, val = window.colorpicker.selected.color:ToHSV()
                        X = (objs.hue.Object.Position.X + objs.hue.Object.Size.X) - objs.hue.Object.Position.X
                        X = math.clamp((pos.X - objs.hue.Object.Position.X) / X, 0, 0.995)
                        hue = 1 - X
                        window.colorpicker.selected:SetColor(fromhsv(hue,sat,val));
                        window.colorpicker:Visualize(fromhsv(hue, sat, val), window.colorpicker.selected.trans);
                    end
                end

                local function updateTrans(pos)
                    if window.colorpicker.selected ~= nil then
                        Y = (objs.trans.Object.Position.Y + objs.trans.Object.Size.Y) - objs.trans.Object.Position.Y
                        Y = math.clamp((pos.Y - objs.transColor.Object.Position.Y) / Y, 0, 0.995)
                        window.colorpicker.selected:SetTrans(Y);
                        window.colorpicker:Visualize(window.colorpicker.selected.color, Y);
                    end
                end

                utility:Connection(objs.mainDetector.MouseButton1Down, function(pos)
                    draggingSat = true;
                    updateSatVal(pos)
                end)

                utility:Connection(objs.hueDetector.MouseButton1Down, function(pos)
                    draggingHue = true;
                    updateHue(pos)
                end)

                utility:Connection(objs.transDetector.MouseButton1Down, function(pos)
                    draggingTrans = true;
                    updateTrans(pos)
                end)

                utility:Connection(mousemove, function(pos)
                    if library.open then
                        if draggingSat then
                            updateSatVal(pos)
                        elseif draggingHue then
                            updateHue(pos)
                        elseif draggingTrans then
                            updateTrans(pos)
                        end
                    end
                end)

                utility:Connection(button1up, function()
                    draggingSat = false;
                    draggingHue = false;
                    draggingTrans = false;
                end)

            end

            function window.colorpicker:Visualize(c3, a)
                if typeof(c3) ~= 'Color3' then return end
                if typeof(a) ~= 'number' then return end
                local h,s,v = c3:ToHSV();
                h = h == 0 and 1 or h;
                self.color = c3;
                self.trans = a;
                self.objects.mainColor.Color = fromhsv(h,1,1);
                self.objects.transColor.Color = fromhsv(h,s,v);
                self.objects.hueSlider.Position = newUDim2(1 - h, 0,0,0);
                self.objects.transSlider.Position = newUDim2(0,0,a,0);
                self.objects.pointer.Position = newUDim2(1 - s, 0, 1 - v, 0);
                self.objects.statusText.Text = 'Editing : Unknown';
                if self.selected ~= nil then
                    local txt = 'Editing : Unknown';
                    if self.selected.text ~= nil and self.selected.text ~= '' then
                        txt = tostring(self.selected.text)
                    elseif self.selected.flag ~= nil and self.selected.flag ~= '' then
                        txt = tostring(self.selected.flag)
                    end
                    self.objects.statusText.Text = tostring(txt);
                end
            end
            
            window.colorpicker:Visualize(window.colorpicker.color, window.colorpicker.trans)

        end
        -------------------------

        ---- Create Dropdown ----
        do
            -- Default Objects
            do
                local objs = window.dropdown.objects;
                local z = library.zindexOrder.dropdown;

                objs.background = utility:Draw('Square', {
                    Visible = false;
                    Size = newUDim2(1,-3,0,50);
                    Position = newUDim2(0,3,1,0);
                    ThemeColor = 'Background';
                    ZIndex = z;
                    Parent = window.objects.background;
                })

                objs.border1 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-1;
                    Parent = objs.background;
                })

                objs.border2 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border 1';
                    ZIndex = z-2;
                    Parent = objs.border1;
                })

                objs.border3 = utility:Draw('Square', {
                    Size = newUDim2(1,2,1,2);
                    Position = newUDim2(0,-1,0,-1);
                    ThemeColor = 'Border';
                    ZIndex = z-3;
                    Parent = objs.border2;
                })

            end

            function window.dropdown:Refresh()
                if self.selected ~= nil then
                    local list = self.selected
                    for idx, value in next, list.values do
                        local valueObject = self.objects.values[idx]
                        if valueObject == nil then
                            valueObject = {};
                            valueObject.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,0,18);
                                Color = Color3.new(.25,.25,.25);
                                Transparency = 0;
                                ZIndex = library.zindexOrder.dropdown+1;
                                Parent = self.objects.background;
                            })
                            valueObject.text = utility:Draw('Text', {
                                Position = newUDim2(0,3,0,1);
                                ThemeColor = 'Option Text 2';
                                Text = tostring(value);
                                Size = 13;
                                Font = 2;
                                ZIndex = library.zindexOrder.dropdown+2;
                                Parent = valueObject.background;
                            })
                            valueObject.connection = utility:Connection(valueObject.background.MouseButton1Down, function()
                                local currentList = self.selected
                                if currentList then
                                    local val = currentList.values[idx]
                                    local currentSelected = currentList.selected;
                                    local newSelected = currentList.multi and {} or val;
                                    
                                    if currentList.multi then
                                        for i,v in next, currentSelected do
                                            if v == "none" then continue end
                                            newSelected[i] = v;
                                        end
                                        if table.find(newSelected, val) then
                                            table.remove(newSelected, table.find(newSelected, val));
                                        else
                                            table.insert(newSelected, val)
                                        end
                                    end

                                    currentList:Select(newSelected);
                                    if not currentList.multi then
                                        currentList.open = false;
                                        currentList.objects.openText.Text = '+';
                                        window.dropdown.selected = nil;
                                        window.dropdown.objects.background.Visible = false;
                                    end

                                    for idx, val in next, currentList.values do
                                        local valueObj = self.objects.values[idx]
                                        if valueObj then
                                            valueObj.background.Transparency = (typeof(newSelected) == 'table' and table.find(newSelected, val) or newSelected == val) and 1 or 0
                                        end
                                    end

                                end
                            end)
                            self.objects.values[idx] = valueObject
                        end
                    end

                    for idx, val in next, list.values do
                        local valueObj = self.objects.values[idx]
                        if valueObj then
                            valueObj.background.Transparency = (typeof(list.selected) == 'table' and table.find(list.selected, val) or list.selected == val) and 1 or 0
                        end
                    end

                    local y,padding = 2,2
                    for idx, obj in next, self.objects.values do
                        local valueStr = list.values[idx]
                        obj.background.Visible = valueStr ~= nil
                        if valueStr ~= nil then
                            obj.background.Position = newUDim2(0,2,0,y);
                            obj.text.Text = valueStr;
                            y = y + obj.background.Object.Size.Y + padding;
                        end
                    end

                    self.objects.background.Size = newUDim2(1,-6,0,y);    

                end
            end
        
            window.dropdown:Refresh();
        end
        -------------------------

        local function tooltip(option)
            utility:Connection(option.objects.holder.MouseEnter, function()
                tooltipObjects.background.Visible = (not (option.tooltip == '' or option.tooltip == nil)) and true or false;
                tooltipObjects.riskytext.Visible = option.risky;
                tooltipObjects.text.Position = option.risky and newUDim2(0,60,0,0) or newUDim2(0,3,0,0)
                tooltipObjects.text.Text = tostring(option.tooltip);
                library.CurrentTooltip = option;
            end)
            utility:Connection(option.objects.holder.MouseLeave, function()
                if library.CurrentTooltip == option then
                    library.CurrentTooltip = nil;
                    tooltipObjects.background.Visible = false
                end
            end)
        end


        local visValues = {};

        function window:SetOpen(bool)
            if typeof(bool) ~= 'boolean' then return end
            pcall(function()
                self.open = bool
                self.setOpenVersion = (self.setOpenVersion or 0) + 1
                local version = self.setOpenVersion
                local bg = self.objects and self.objects.background
                if not bg then return end
                local objs = {}
                local ok, list = pcall(function() return bg:GetDescendants() end)
                if ok and type(list) == 'table' then
                    for _, v in next, list do
                        if v then table.insert(objs, v) end
                    end
                end
                table.insert(objs, bg)

                task.spawn(function()
                    local wantOpen = bool
                    if not wantOpen then
                        task.wait(.1)
                    end
                    pcall(function()
                        if self.objects and self.objects.background and self.open == wantOpen and self.setOpenVersion == version then
                            self.objects.background.Visible = wantOpen
                        end
                    end)
                end)

                for _, v in next, objs do
                    if not v or not v.Object or type(v.Object) == 'number' then continue end
                    local obj = v.Object
                    local hasTrans = (type(obj) == 'userdata' or type(obj) == 'table') and obj.Transparency ~= nil
                    if not hasTrans or obj.Transparency == 0 then continue end
                    task.spawn(function()
                        pcall(function()
                            if self.setOpenVersion ~= version then return end
                            if self.open ~= bool then return end
                            if bool then
                                utility:Tween(obj, 'Transparency', visValues[v] or 1, .1)
                            else
                                visValues[v] = obj.Transparency
                                utility:Tween(obj, 'Transparency', .05, .1)
                            end
                        end)
                    end)
                end
            end)
        end

        function window:AddTab(text, order)
            local tab = {
                text = text;
                order = order or #self.tabs+1;
                callback = function() end;
                objects = {};
                sections = {};
            }

            table.insert(self.tabs, tab);

            --- Create Objects ---
            -- NEW tab creation part (no changes needed here, the magic happens in UpdateTabs)
--- Create Objects ---
do
    local objs = tab.objects;
    local z = library.zindexOrder.window + 5;

    objs.background = utility:Draw('Square', {
        Size = newUDim2(0,50,1,0); -- This initial size will be overridden by UpdateTabs
        Parent = self.objects.tabHolder;
        ThemeColor = 'Unselected Tab Background';
        ZIndex = z;
    })

    objs.innerBorder = utility:Draw('Square', {
        Size = newUDim2(1,2,1,2);
        Position = newUDim2(0,-1,0,-1);
        ThemeColor = 'Border 1';
        ZIndex = z-1;
        Parent = objs.background;
    })

    objs.outerBorder = utility:Draw('Square', {
        Size = newUDim2(1,2,1,2);
        Position = newUDim2(0,-1,0,-1);
        ThemeColor = 'Border 3';
        ZIndex = z-2;
        Parent = objs.innerBorder;
    })

    objs.topBorder = utility:Draw('Square', {
        Size = newUDim2(1,0,0,1);
        ThemeColor = 'Unselected Tab Background';
        ZIndex = z+1;
        Parent = objs.background;
    })

    objs.text = utility:Draw('Text', {
        ThemeColor = 'Unselected Tab Text';
        Text = text;
        Size = 13;
        Font = 2;
        ZIndex = z+1;
        Outline = true;
        Center = true;
        Parent = objs.background;
    })

    utility:Connection(objs.background.MouseButton1Down, function()
        tab:Select();
    end)

end
            ----------------------

            function tab:AddSection(text, side, order)
                local section = {
                    text = tostring(text);
                    side = side == nil and 1 or clamp(side,1,2);
                    order = order or #self.sections+1;
                    enabled = true;
                    objects = {};
                    options = {};
                };

                table.insert(self.sections, section);

                --- Create Objects ---
                do
                    local objs = section.objects;
                    local z = library.zindexOrder.window+15;

                    objs.background = utility:Draw('Square', {
                        ThemeColor = 'Section Background';
                        ZIndex = z;
                        Parent = window.objects['columnholder'..(section.side)];
                    })

                    objs.innerBorder = utility:Draw('Square', {
                        Size = newUDim2(1,2,1,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Border 3';
                        ZIndex = z-1;
                        Parent = objs.background;
                    })

                    objs.outerBorder = utility:Draw('Square', {
                        Size = newUDim2(1,2,1,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Border 1';
                        ZIndex = z-2;
                        Parent = objs.innerBorder;
                    })

                    objs.topBorder1 = utility:Draw('Square', {
                        Size = newUDim2(.025,1,0,1);
                        Position = newUDim2(0,-1,0,0);
                        ThemeColor = 'Accent';
                        ZIndex = z+1;
                        Parent = objs.background;
                    })

                    objs.topBorder2 = utility:Draw('Square', {
                        ThemeColor = 'Accent';
                        ZIndex = z+1;
                        Parent = objs.background;
                    })

                    objs.textlabel = utility:Draw('Text', {
                        Position = newUDim2(.0425,0,0,-7);
                        ThemeColor = 'Primary Text';
                        Size = 13;
                        Font = 2;
                        ZIndex = z+1;
                        Parent = objs.background;
                    })

                    objs.optionholder = utility:Draw('Square',{
                        Size = newUDim2(1-.03,0,1,-15);
                        Position = newUDim2(.015,0,0,13);
                        Transparency = 0;
                        ZIndex = z+1;
                        Parent = objs.background;
                    })
                    
                end
                ----------------------

                function section:SetText(text)
                    self.text = tostring(text);
                    self.objects.textlabel.Text = self.text;
                    local x = self.objects.background.Object.Size.X - self.objects.textlabel.TextBounds.X - 13
                    self.objects.topBorder2.Size = newUDim2(0, x, 0, 1)
                    self.objects.topBorder2.Position = newUDim2(1, 1 + -x, 0, 0)
                end

                function section:UpdateOptions()
                    table.sort(self.options, function(a,b)
                        return a.order < b.order
                    end)

                    local ySize, padding = 15, 0;
                    for i,option in next, self.options do
                        option.objects.holder.Visible = option.enabled
                        if option.enabled then
                            option.objects.holder.Position = newUDim2(0,0,0,ySize-15);
                            ySize += option.objects.holder.Object.Size.Y + padding;
                        end
                    end

                    self.objects.background.Size = newUDim2(1,0,0,ySize);

                end

                function section:SetEnabled(bool)
                    if typeof(bool) == 'boolean' then
                        section.enabled = bool;
                        tab:UpdateSections();
                    end
                end

                ------- Options -------

                -- // Toggle
                function section:AddToggle(data)
                    local toggle = {
                        class = 'toggle';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        state = false;
                        risky = false;
                        callback = function() end;
                        enabled = true;
                        options = {};
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) ~= toggle[i] ~= nil then
                            toggle[i] = v
                        end
                    end

                    table.insert(self.options, toggle)

                    if toggle.flag then
                        library.flags[toggle.flag] = toggle.state;
                        library.options[toggle.flag] = toggle;
                    end

                    --- Create Objects ---
                    do
                        local objs = toggle.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,17);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(0,8,0,8);
                            Position = newUDim2(0,2,0,4);
                            ThemeColor = 'Option Background';
                            ZIndex = z+3;
                            Parent = objs.holder;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp45;
                            Transparency = .25;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+2;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z+1;
                            Parent = objs.border1;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,19,0,1);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })
                        if toggle.text and toggle.text ~= '' then
                            objs.text.Text = toggle.text;
                        end

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = toggle.state and 'Accent' or 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            toggle:SetState(not toggle.state);
                        end)

                    end
                    ----------------------

                    function toggle:SetState(bool, nocallback)
                        if typeof(bool) == 'boolean' then
                            self.state = bool;
                            if self.flag then
                                library.flags[self.flag] = bool;
                            end

                            self.objects.border1.ThemeColor = bool and 'Accent' or (self.objects.holder.Hover and 'Accent' or 'Option Border 1');
                            self.objects.text.ThemeColor = bool and (self.risky and 'Risky Text Enabled' or 'Option Text 1') or (self.risky and 'Risky Text' or 'Option Text 3');
                            self.objects.background.ThemeColor = bool and 'Accent' or 'Option Background';
                            self.objects.background.ThemeColorOffset = bool and -55 or 0

                            if not nocallback then
                                self.callback(bool);
                            end

                        end
                    end

                    function toggle:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function toggle:UpdateOptions()
                        table.sort(self.options, function(a,b)
                            return a.order < b.order
                        end)

                        local x, y = 0, 0
                        for i,option in next, self.options do
                            option.objects.holder.Visible = option.enabled
                            if option.enabled then
                                if option.class == 'color' or option.class == 'bind' then
                                    option.objects.holder.Position = newUDim2(1,-option.objects.holder.Object.Size.X-x,0,0);
                                    x = x + option.objects.holder.Object.Size.X;
                                elseif option.class == 'slider' or option.class == 'list' then
                                    option.objects.holder.Position = newUDim2(0,0,1,-option.objects.holder.Object.Size.Y-y);
                                    y = y + option.objects.holder.Object.Size.Y;
                                end
                            end
                        end

                        self.objects.holder.Size = newUDim2(1,0,0,17 + y);
                        section:UpdateOptions()

                    end

                    -- // Toggle Addons
                    function toggle:AddColor(data)
                        local color = {
                            class = 'color';
                            flag = data.flag;
                            text = '';
                            tooltip = '';
                            order = #self.options+1;
                            callback = function() end;
                            color = Color3.new(1,1,1);
                            trans = 0;
                            open = false;
                            enabled = true;
                            objects = {};
                        };
    
                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and color[i] ~= nil then
                                color[i] = v
                            end
                        end
                        
                        table.insert(self.options, color)
    
                        if color.flag then
                            library.flags[color.flag] = color.color;
                            library.options[color.flag] = color;
                        end
    
                        --- Create Objects ---
                        do
                            local objs = color.objects;
                            local z = library.zindexOrder.window+25;
    
                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(0,21,0,17);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = self.objects.holder;
                            })
    
                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(0,15,0,8);
                                Position = newUDim2(0,4,0,5);
                                ZIndex = z+3;
                                Parent = objs.holder;
                            })
    
                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp45;
                                Transparency = .25;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })
    
                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+2;
                                Parent = objs.background;
                            })
    
                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z+1;
                                Parent = objs.border1;
                            })
    
                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)
    
                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = color.state and 'Accent' or 'Option Border 1';
                            end)
    
                            utility:Connection(objs.holder.MouseButton1Down, function()
                                color:SetOpen(not color.open);
                            end)
    
                        end
                        ----------------------

    
                        function color:SetColor(c3, nocallback)
                            if typeof(c3) == 'Color3' then
                                local h,s,v = c3:ToHSV(); c3 = fromhsv(h, clamp(s,.005,.995), clamp(v,.005,.995))
                                self.color = c3;
                                self.objects.background.Color = c3;
                                if not nocallback then
                                    self.callback(c3, self.trans);
                                end
                                if self.open then
                                    window.colorpicker:Visualize(self.color, self.trans);
                                end
                                if self.flag then
                                    library.flags[self.flag] = c3;
                                end
                            end
                        end
    
                        function color:SetTrans(trans, nocallback)
                            if typeof(trans) == 'number' then
                                self.trans = trans;
                                if not nocallback then
                                    self.callback(self.color, trans);
                                end
                                if self.open then
                                    window.colorpicker:Visualize(self.color, self.trans);
                                end
                            end
                        end
    
                        function color:SetOpen(bool)
                            if typeof(bool) == 'boolean' then
                                self.open = bool
                                if bool then
                                    if window.colorpicker.selected then
                                        window.colorpicker.selected.open = false;
                                    end
                                    window.colorpicker.selected = color
                                    window.colorpicker.objects.background.Parent = self.objects.background;
                                    window.colorpicker.objects.background.Visible = true;
                                    window.colorpicker:Visualize(color.color, color.trans)
                                elseif window.colorpicker.selected == color then
                                    window.colorpicker.selected = nil;
                                    window.colorpicker.objects.background.Parent = window.objects.background;
                                    window.colorpicker.objects.background.Visible = false;
                                end
                            end
                        end
    
                        tooltip(color);
                        color:SetColor(color.color, true);
                        color:SetTrans(color.trans, true);
                        self:UpdateOptions();
                        return color
                    end

                    function toggle:AddBind(data)
                        local bind = {
                            class = 'bind';
                            flag = data.flag;
                            text = '';
                            tooltip = '';
                            bind = 'none';
                            mode = 'toggle';
                            order = #self.options+1;
                            callback = function() end;
                            keycallback = function() end;
                            indicatorValue = library.keyIndicator:AddValue({value = 'value', key = 'key', enabled = false});
                            noindicator = false;
                            invertindicator = false;
                            state = false;
                            nomouse = false;
                            enabled = true;
                            binding = false;
                            objects = {};
                        };
    
                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and bind[i] ~= nil then
                                bind[i] = v
                            end
                        end
                        
                        table.insert(self.options, bind)
    
                        if bind.flag then
                            library.options[bind.flag] = bind;
                        end

                        if bind.bind == 'none' then
                            bind.state = true
                            if bind.flag then
                                library.flags[bind.flag] = bind.state;
                            end
                            bind.callback(true)
                            local display = bind.state; if bind.invertindicator then display = not bind.state; end
                            bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            bind.indicatorValue:SetKey((bind.text == nil or bind.text == '') and (bind.flag == nil and 'unknown' or bind.flag) or bind.text); -- this is so dumb
                            bind.indicatorValue:SetValue('[Always]');
                        end
    
                        --- Create Objects ---
                        do
                            local objs = bind.objects;
                            local z = library.zindexOrder.window+25;
    
                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(0,0,0,17);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = self.objects.holder;
                            })
    
                            objs.keyText = utility:Draw('Text', {
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+1;
                                Parent = objs.holder;
                            })
    
                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.keyText.ThemeColor = 'Accent';
                            end)
    
                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.keyText.ThemeColor = bind.binding and 'Accent' or 'Option Text 3';
                            end)
    
                            utility:Connection(objs.holder.MouseButton1Down, function()
                                if not bind.binding then
                                    bind:SetKeyText('...');
                                    bind.binding = true;
                                end
                            end)
    
                        end
                        ----------------------
    
                        local c
                        function bind:SetBind(keybind)
                            if c then
                                c:Disconnect();
                                if bind.flag then
                                    library.flags[bind.flag] = false;
                                end
                                bind.callback(false);
                            end
                            local keyName = 'NONE'
                            if keybind == nil or keybind == true or keybind == false then
                                keybind = 'none'
                            end
                            self.bind = (keybind and keybind ~= 'none') and keybind or self.bind
                            if self.bind == Enum.KeyCode.Backspace then
                                self.bind = 'none';

                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                self.callback(true)
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            else
                                if self.bind ~= 'none' then
                                    keyName = keyNames[self.bind] or (type(self.bind) == "userdata" or type(self.bind) == "table") and self.bind.Name or tostring(self.bind)
                                end
                            end
                            if self.bind ~= 'none' then
                                bind.state = false
                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                self.callback(false)
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                            end
                            self.keycallback(self.bind);
                            self:SetKeyText(keyName:upper());
                            self.indicatorValue:SetKey((self.text == nil or self.text == '') and (self.flag == nil and 'unknown' or self.flag) or self.text); -- this is so dumb
                            self.indicatorValue:SetValue('['..keyName:upper()..']');
                            if self.bind == 'none' then

                            end
                            self.objects.keyText.ThemeColor = self.objects.holder.Hover and 'Accent' or 'Option Text 3';
                        end
    
                        function bind:SetKeyText(str)
                            str = tostring(str);
                            self.objects.keyText.Text = '['..str..']';
                            self.objects.keyText.Position = newUDim2(0, 2, 0, 2);
                            self.objects.holder.Size = newUDim2(0,self.objects.keyText.TextBounds.X+2,0,17)
                            toggle:UpdateOptions();
                        end
    
                        utility:Connection(inputservice.InputBegan, function(inp)
                            if inputservice:GetFocusedTextBox() then
                                return
                            elseif bind.binding then
                                local key = (table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}, inp.UserInputType) and not bind.nomouse) and inp.UserInputType
                                bind:SetBind(key or (not table.find(blacklistedKeys, inp.KeyCode)) and inp.KeyCode)
                                bind.binding = false
                            elseif not bind.binding and self.bind == 'none' then
                                bind.state = true
                                library.flags[bind.flag] = bind.state
                                local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                bind.indicatorValue:SetEnabled(display and not bind.noindicator)
                            elseif (inp.KeyCode == bind.bind or inp.UserInputType == bind.bind) and not bind.binding then
                                if bind.mode == 'toggle' then
                                    bind.state = not bind.state
                                    if bind.flag then
                                        library.flags[bind.flag] = bind.state;
                                    end
                                    bind.callback(bind.state)
                                    local display = bind.state; if bind.invertindicator then display = not bind.state; end
                                    bind.indicatorValue:SetEnabled(display and not bind.noindicator);
                                elseif bind.mode == 'hold' then
                                    if bind.flag then
                                        library.flags[bind.flag] = true;
                                    end
                                    bind.indicatorValue:SetEnabled((not bind.invertindicator and true or false) and not bind.noindicator);
                                    c = utility:Connection(runservice.RenderStepped, function()
                                        if bind.callback then
                                            bind.callback(true);
                                        end
                                    end)
                                end
                            end
                        end)
    
                        utility:Connection(inputservice.InputEnded, function(inp)
                            if bind.bind ~= 'none' then
                                if inp.KeyCode == bind.bind or inp.UserInputType == bind.bind then
                                    if c then
                                        c:Disconnect();
                                        if bind.flag then
                                            library.flags[bind.flag] = false;
                                        end
                                        if bind.callback then
                                            bind.callback(false);
                                        end
                                        bind.indicatorValue:SetEnabled(bind.invertindicator and true or false);
                                    end
                                end
                            end
                        end)
    
                        tooltip(bind);
                        bind:SetBind(bind.bind);
                        self:UpdateOptions();
                        return bind
                    end

                    function toggle:AddSlider(data)
                        local slider = {
                            class = 'slider';
                            flag = data.flag;
                            suffix = '';
                            tooltip = '';
                            order = #self.options+1;
                            value = 0;
                            min = 0;
                            max = 100;
                            increment = 1;
                            callback = function() end;
                            enabled = true;
                            dragging = false;
                            focused = false;
                            objects = {};
                        };
    
                        local blacklist = {'objects', 'dragging'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and (slider[i] ~= nil and typeof(slider[i]) == typeof(v)) then
                                slider[i] = v;
                            end
                        end
                        slider.value = data.value or data.default or slider.value;
                        slider.default = data.default or slider.value;

                        table.insert(self.options, slider)

                        if slider.flag then
                            library.flags[slider.flag] = slider.value;
                            library.options[slider.flag] = slider;
                        end

                        --- Create Objects ---
                        do
                            local objs = slider.objects;
                            local z = library.zindexOrder.window+25;

                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,0,20);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = toggle.objects.holder;
                            })

                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })

                            objs.slider = utility:Draw('Square', {
                                Size = newUDim2(0,0,1,0);
                                ThemeColor = 'Accent';
                                ZIndex = z+3;
                                Parent = objs.background;
                            })

                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })

                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })
    
                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .65;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })
    
                            objs.text = utility:Draw('Text', {
                                Position = newUDim2(.5,0,0,-1);
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Center = true;
                                Parent = objs.background;
                            })

                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)
    
                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = slider.dragging and 'Accent' or 'Option Border 1';
                            end)
    
                            local c;
                            local inputNumber = '';
                            utility:Connection(slider.objects.holder.MouseButton1Down, function()
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                    if slider.focused then
                                        slider.focused = false;
                                        c:Disconnect();
                                    else
                                        objs.text.Text = tostring(slider.value)..tostring(slider.suffix)..'/'..tostring(slider.max)..tostring(slider.suffix)..' []';
                                        slider.focused = true;
                                        inputNumber = '';
                                        c = utility:Connection(inputservice.InputBegan, function(inp)
                                            if library.numberStrings[inp.KeyCode.Name] then
                                                local number = library.numberStrings[inp.KeyCode.Name];
                                                inputNumber = inputNumber..tostring(number);
                                                objs.text.Text = string.format("%.14g", slider.value) .. tostring(slider.suffix) .. "/" .. slider.max .. tostring(slider.suffix) .. " [" .. inputNumber .. "]";
                                            elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                                inputNumber = inputNumber:sub(1,-2);
                                                objs.text.Text = string.format("%.14g", slider.value)..tostring(slider.suffix)..'/'..slider.max..tostring(slider.suffix)..' ['..inputNumber..']';
                                            elseif inp.KeyCode == Enum.KeyCode.Return then
                                                slider:SetValue(tonumber(inputNumber))
                                                slider.focused = false;
                                                c:Disconnect();
                                            elseif inp.KeyCode == Enum.KeyCode.Escape then
                                                slider:SetValue(slider.value, true)
                                                slider.focused = false;
                                                c:Disconnect();
                                            end
                                        end)
                                    end
                                else
                                    slider.dragging = true;
                                    library.draggingSlider = slider;
                                end
                            end)
    
                            utility:Connection(button1up, function()
                                objs.border1.ThemeColor = objs.holder.Hover and 'Accent' or 'Option Border 1';
                                slider.dragging = false;
                                library.draggingSlider = nil;
                            end)
    
                        end
                        ----------------------
    
                        function slider:SetValue(value, nocallback)
                            if typeof(value) == 'number' then
                                local newValue = clamp(self.increment * floor(value/self.increment), self.min, self.max);
                                local size, pos = self.objects.slider.Size, self.objects.slider.Position;
    
                                if self.min >= 0 then
                                    size = newUDim2((newValue - self.min) / (self.max - self.min), 0, 1, 0);
                                else
                                    size = newUDim2(newValue / (self.max - self.min), 0, 1, 0);
                                    pos = newUDim2((0 - self.min) / (self.max - self.min), 0, 0, 0);
                                end
    
                                utility:Tween(self.objects.slider, 'Size', size, .05, Enum.EasingDirection.Out, Enum.EasingStyle.Quad);
                                utility:Tween(self.objects.slider, 'Position', pos, .05, Enum.EasingDirection.Out, Enum.EasingStyle.Quad);
    
                                self.value = newValue;
                                library.flags[self.flag] = newValue;
                                self.objects.text.Text = string.format("%.14g",newValue)..tostring(self.suffix)..'/'..self.max..tostring(self.suffix);
                                self.objects.text.ThemeColor = (self.min < 0 and newValue == 0 or newValue == self.min)  and (self.risky and 'Risky Text' or 'Option Text 3') or (self.risky and 'Risky Text Enabled' or 'Option Text 1');
    
                                if not nocallback then
                                    self.callback(newValue);
                                end
    
                            end
                        end

                        tooltip(slider);
                        slider:SetValue(slider.value, true);
                        self:UpdateOptions();
                        return slider
                    end

                    function toggle:AddList(data)
                        local list = {
                            class = 'list';
                            flag = data.flag;
                            text = '';
                            selected = '';
                            tooltip = '';
                            order = #self.options+1;
                            callback = function() end;
                            enabled = true;
                            multi = false;
                            open = false;
                            values = {};
                            objects = {};
                        }
    
                        table.insert(self.options, list);
    
                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) ~= list[i] ~= nil then
                                list[i] = v
                            end
                        end
    
                        if list.flag then
                            library.flags[list.flag] = list.selected;
                            library.options[list.flag] = list;
                        end
    
                        -- Create Objects --
                        do
                            local objs = list.objects;
                            local z = library.zindexOrder.window+25;
    
                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,0,22);
                                Transparency = 0;
                                ZIndex = z+6;
                                Parent = toggle.objects.holder;
                            })
    
                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })
    
                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })
    
                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })
    
                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .65;
                                ZIndex = z+4;
                                Parent = objs.background;
                            })
    
                            objs.inputText = utility:Draw('Text', {
                                Position = newUDim2(0,4,0,0);
                                ThemeColor = 'Option Text 2';
                                Text = 'none',
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Parent = objs.background;
                            })
    
                            objs.openText = utility:Draw('Text', {
                                Position = newUDim2(1,-10,0,0);
                                ThemeColor = 'Option Text 3';
                                Text = '+';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+5;
                                Outline = true;
                                Parent = objs.background;
                            })
    
                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)
    
                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = 'Option Border 1';
                            end)
    
                            utility:Connection(objs.holder.MouseButton1Down, function()
                                if list.open then
                                    list.open = false;
                                    objs.openText.Text = '+';
                                    if window.dropdown.selected == list then
                                        window.dropdown.selected = nil;
                                        window.dropdown.objects.background.Visible = false;
                                    end
                                else
                                    if window.dropdown.selected ~= nil then
                                        window.dropdown.selected.open = false
                                    end
                                    list.open = true;
                                    objs.openText.Text = '-';
                                    window.dropdown.selected = list;
                                    window.dropdown.objects.background.Visible = true;
                                    window.dropdown.objects.background.Parent = objs.holder;
                                    window.dropdown:Refresh();
                                end
                            end)
    
    
                        end
                        --------------------
    
                        function list:Select(option, nocallback)
                            option = typeof(option) == 'table' and (self.multi == true and option or (#option == 0 and nil or option[1])) or self.multi == true and {option} or option;
                            if option ~= nil then
                                self.selected = option;
                                local text = typeof(option) == 'table' and (#option == 0 and "none" or table.concat(option, ', ')) or tostring(option);
                                local label = self.objects.inputText
                                label.Text = text;
                                if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                    local split = text:split('');
                                    for i = 1,#split do
                                        label.Text = table.concat(split, '', 1, i)
                                        if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                            label.Text = label.Text:sub(1,-6)..'...';
                                            break
                                        end
                                    end
                                end
                                if self.flag then
                                    library.flags[self.flag] = self.selected
                                end
                                if not nocallback then
                                    self.callback(self.selected);
                                end
                            end
                        end
    
                        function list:AddValue(value)
                            table.insert(list.values, tostring(value));
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end
    
                        function list:RemoveValue(value)
                            if table.find(list.values, value) then
                                table.remove(list.values, table.find(list.values, value));
                                if window.dropdown.selected == list then
                                    window.dropdown:Refresh()
                                end
                            end
                        end
    
                        function list:ClearValues()
                            table.clear(list.values);
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end
    
                        tooltip(list);
                        list.default = data.default or data.selected or data.value;
                        list:Select((data.value or data.selected or data.default) or (list.multi and 'none' or list.values[1]), true);
                        self:UpdateOptions();
                        return list
                    end

                    tooltip(toggle);
                    toggle:SetText(toggle.text);
                    toggle:SetState(toggle.state, true);
                    self:UpdateOptions();
                    return toggle
                end

                -- // Slider
                function section:AddSlider(data)
                    local slider = {
                        class = 'slider';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        suffix = '';
                        order = #self.options+1;
                        value = 0;
                        min = 0;
                        max = 100;
                        increment = 1;
                        callback = function() end;
                        enabled = true;
                        dragging = false;
                        focused = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and (slider[i] ~= nil and typeof(slider[i]) == typeof(v)) then
                            slider[i] = v;
                        end
                    end
                    slider.value = data.value or data.default or slider.value;
                    slider.default = data.default or slider.value;

                    table.insert(self.options, slider)

                    if slider.flag then
                        library.flags[slider.flag] = slider.value;
                        library.options[slider.flag] = slider;
                    end

                    --- Create Objects ---
                    do
                        local objs = slider.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,32);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,11);
                            Position = newUDim2(0,2,1,-14);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.slider = utility:Draw('Square', {
                            Size = newUDim2(0,0,1,0);
                            ThemeColor = 'Accent';
                            ZIndex = z+3;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .65;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,1);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.plusDetector = utility:Draw('Square', {
                            Size = newUDim2(0,14,0,14);
                            Position = newUDim2(1,-28,0,1);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = objs.holder;
                        })

                        objs.minusDetector = utility:Draw('Square', {
                            Size = newUDim2(0,14,0,14);
                            Position = newUDim2(1,-14,0,1);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = objs.holder;
                        })

                        objs.plusText = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,-1);
                            ThemeColor = 'Option Text 3';
                            Text = '+';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+4;
                            Center = true;
                            Outline = true;
                            Parent = objs.plusDetector;
                        })

                        objs.minusText = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,-1);
                            ThemeColor = 'Option Text 3';
                            Text = '-';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+4;
                            Center = true;
                            Outline = true;
                            Parent = objs.minusDetector;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = slider.dragging and 'Accent' or 'Option Border 1';
                        end)

                        utility:Connection(slider.objects.plusDetector.MouseButton1Down,function()
                            slider:SetValue(slider.value + (inputservice:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or slider.increment))
                        end)
    
                        utility:Connection(slider.objects.minusDetector.MouseButton1Down,function()
                            slider:SetValue(slider.value - (inputservice:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or slider.increment))
                        end)


                        local c;
                        local inputNumber = '';
                        utility:Connection(slider.objects.holder.MouseButton1Down, function()
                            if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                if slider.focused then
                                    slider.focused = false;
                                    c:Disconnect();
                                else
                                    objs.text.Text = slider.text..': '..tostring(slider.value)..tostring(slider.suffix)..' []';
                                    slider.focused = true;
                                    inputNumber = '';
                                    c = utility:Connection(inputservice.InputBegan, function(inp)
                                        if library.numberStrings[inp.KeyCode.Name] then
                                            local number = library.numberStrings[inp.KeyCode.Name];
                                            inputNumber = inputNumber..tostring(number);
                                            objs.text.Text = slider.text..': '..string.format("%.14g",slider.value)..tostring(slider.suffix)..' ['..inputNumber..']';
                                        elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                            inputNumber = inputNumber:sub(1,-2);
                                            objs.text.Text = slider.text..': '..string.format("%.14g",slider.value)..tostring(slider.suffix)..' ['..inputNumber..']';
                                        elseif inp.KeyCode == Enum.KeyCode.Return then
                                            slider:SetValue(tonumber(inputNumber))
                                            slider.focused = false;
                                            c:Disconnect();
                                        elseif inp.KeyCode == Enum.KeyCode.Escape then
                                            slider:SetValue(slider.value, true)
                                            slider.focused = false;
                                            c:Disconnect();
                                        end
                                    end)

                                end


                            else
                                slider.dragging = true;
                                library.draggingSlider = slider;
                            end
                        end)

                        utility:Connection(button1up, function()
                            objs.border1.ThemeColor = objs.holder.Hover and 'Accent' or 'Option Border 1';
                            slider.dragging = false;
                            library.draggingSlider = nil;
                        end)

                    end
                    ----------------------

                    function slider:SetValue(value, nocallback)
                        if typeof(value) == 'number' then
                            local newValue = clamp(self.increment * floor(value/self.increment), self.min, self.max);
                            local size, pos = self.objects.slider.Size, self.objects.slider.Position;

                            if self.min >= 0 then
                                size = newUDim2((newValue - self.min) / (self.max - self.min), 0, 1, 0);
                            else
                                size = newUDim2(newValue / (self.max - self.min), 0, 1, 0);
                                pos = newUDim2((0 - self.min) / (self.max - self.min), 0, 0, 0);
                            end

                            utility:Tween(self.objects.slider, 'Size', size, .05, Enum.EasingDirection.Out, Enum.EasingStyle.Quad);
                            utility:Tween(self.objects.slider, 'Position', pos, .05, Enum.EasingDirection.Out, Enum.EasingStyle.Quad);

                            self.value = newValue;
                            library.flags[self.flag] = newValue;
                            self.objects.text.Text = slider.text..': '..string.format("%.14g",newValue)..tostring(self.suffix);
                            self.objects.text.ThemeColor = (self.min < 0 and newValue == 0 or newValue == self.min)  and (self.risky and 'Risky Text' or 'Option Text 3') or (self.risky and 'Risky Text Enabled' or 'Option Text 1');

                            if not nocallback then
                                self.callback(newValue);
                            end

                        end
                    end

                    function slider:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str..': '..tostring(self.value)..tostring(self.suffix);
                        end
                    end

                    tooltip(slider);
                    slider:SetText(slider.text);
                    slider:SetValue(slider.value, true);
                    self:UpdateOptions();
                    return slider
                end

                -- // Button
                function section:AddButton(data)
                    local button = {
                        class = 'button';
                        flag = data.flag;
                        text = '';
                        suffix = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        confirm = false;
                        enabled = true;
                        risky = false;
                        objects = {};
                        subbuttons = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and button[i] ~= nil then
                            button[i] = v;
                        end
                    end
        
                    table.insert(self.options, button)

                    if button.flag then
                        library.options[button.flag] = button;
                    end

                    --- Create Objects ---
                    do
                        local objs = button.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,22);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,14);
                            Position = newUDim2(0,2,0,4);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .65;
                            ZIndex = z+3;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,0);
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+4;
                            Outline = true;
                            Center = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                            objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                            objs.background.ThemeColor = 'Option Background';
                            objs.background.ThemeColorOffset = 0;
                        end)

                        utility:Connection(objs.holder.MouseButton1Up, function()
                            objs.text.ThemeColor = self.risky and 'Risky Text' or  'Option Text 3';
                            objs.background.ThemeColor = 'Option Background';
                            objs.background.ThemeColorOffset = 0;
                        end)

                        local clicked, counting = false, false
                        utility:Connection(objs.holder.MouseButton1Down, function()
                            objs.text.ThemeColor = self.risky and 'Risky Text Enabled' or 'Option Text 2';
                            objs.background.ThemeColor = 'Accent';
                            objs.background.ThemeColorOffset = -95;

                            task.spawn(function() -- this is ugly and i do not care :)
                                if button.confirm then
                                    if clicked then
                                        clicked = false
                                        counting = false
                                        objs.text.Text = button.text
                                        button.callback()
                                    else
                                        clicked = true
                                        counting = true
                                        for i = 3,1,-1 do
                                            if not counting then
                                                break
                                            end
                                            objs.text.Text = 'Confirm '..button.text..'? '..tostring(i)
                                            wait(1)
                                        end
                                        clicked = false
                                        counting = false
                                        objs.text.Text = button.text
                                    end
                                else
                                    button.callback()
                                end
                            end)

                        end)

                    end
                    ----------------------
                    function button:AddButton(data)
                        local button = {
                            class = 'button';
                            flag = data.flag;
                            text = '';
                            suffix = '';
                            tooltip = '';
                            order = #self.subbuttons+1;
                            callback = function() end;
                            confirm = false;
                            enabled = true;
                            objects = {};
                        };
    
                        local blacklist = {'objects'};
                        for i,v in next, data do
                            if not table.find(blacklist, i) and button[i] ~= nil then
                                button[i] = v;
                            end
                        end
            
                        table.insert(self.subbuttons, button)
    
                        if button.flag then
                            library.options[button.flag] = button;
                        end
    
                        --- Create Objects ---
                        do
                            local objs = button.objects;
                            local z = library.zindexOrder.window+25;
    
                            objs.holder = utility:Draw('Square', {
                                Size = newUDim2(1,0,1,0);
                                Transparency = 0;
                                ZIndex = z+5;
                                Parent = self.objects.holder;
                            })
    
                            objs.background = utility:Draw('Square', {
                                Size = newUDim2(1,-4,1,-8);
                                Position = newUDim2(0,2,0,4);
                                ThemeColor = 'Option Background';
                                ZIndex = z+2;
                                Parent = objs.holder;
                            })
    
                            objs.border1 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 1';
                                ZIndex = z+1;
                                Parent = objs.background;
                            })
    
                            objs.border2 = utility:Draw('Square', {
                                Size = newUDim2(1,2,1,2);
                                Position = newUDim2(0,-1,0,-1);
                                ThemeColor = 'Option Border 2';
                                ZIndex = z;
                                Parent = objs.border1;
                            })
    
                            objs.gradient = utility:Draw('Image', {
                                Size = newUDim2(1,0,1,0);
                                Data = library.images.gradientp90;
                                Transparency = .65;
                                ZIndex = z+3;
                                Parent = objs.background;
                            })
    
                            objs.text = utility:Draw('Text', {
                                Position = newUDim2(.5,0,0,0);
                                ThemeColor = 'Option Text 3';
                                Size = 13;
                                Font = 2;
                                ZIndex = z+4;
                                Outline = true;
                                Center = true;
                                Parent = objs.background;
                            })
    
                            utility:Connection(objs.holder.MouseEnter, function()
                                objs.border1.ThemeColor = 'Accent';
                            end)
    
                            utility:Connection(objs.holder.MouseLeave, function()
                                objs.border1.ThemeColor = 'Option Border 1';
                                objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                                objs.background.ThemeColor = 'Option Background';
                                objs.background.ThemeColorOffset = 0;
                            end)
    
                            utility:Connection(objs.holder.MouseButton1Up, function()
                                objs.text.ThemeColor = self.risky and 'Risky Text' or 'Option Text 3';
                                objs.background.ThemeColor = 'Option Background';
                                objs.background.ThemeColorOffset = 0;
                            end)
    
                            local clicked, counting = false, false
                            utility:Connection(objs.holder.MouseButton1Down, function()
                                objs.text.ThemeColor = self.risky and 'Risky Text Enabled' or 'Option Text 2';
                                objs.background.ThemeColor = 'Accent';
                                objs.background.ThemeColorOffset = -95;
    
                                task.spawn(function() -- this is ugly and i do not care :)
                                    if button.confirm then
                                        if clicked then
                                            clicked = false
                                            counting = false
                                            objs.text.Text = button.text
                                            button.callback()
                                        else
                                            clicked = true
                                            counting = true
                                            for i = 3,1,-1 do
                                                if not counting then
                                                    break
                                                end
                                                objs.text.Text = 'Confirm '..button.text..'? '..tostring(i)
                                                wait(1)
                                            end
                                            clicked = false
                                            counting = false
                                            objs.text.Text = button.text
                                        end
                                    else
                                        button.callback()
                                    end
                                end)
    
                            end)
    
                        end
                        ----------------------
    
                        function button:SetText(str)
                            if typeof(str) == 'string' then
                                self.text = str;
                                self.objects.text.Text = str;
                            end
                        end
    
                        tooltip(button);
                        button:SetText(button.text);
                        self:UpdateOptions();
                        return button
                    end
                    ----------------------

                    function button:UpdateOptions() -- this so dumb XD
                        local buttons = 1 + #self.subbuttons;
                        local buttonSize = (1 / buttons) - .005;
                        self.objects.background.Size = newUDim2(buttonSize,-4,0,14);
                        for i,v in next, self.subbuttons do
                            v.objects.holder.Size = newUDim2(buttonSize,0,1,0);
                            v.objects.holder.Position = newUDim2(i * buttonSize + .01, 0, 0, 0)
                        end
                    end

                    function button:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    tooltip(button);
                    button:SetText(button.text);
                    self:UpdateOptions();
                    return button
                end

                -- // Separator
                function section:AddSeparator(data)
                    local separator = {
                        class = 'separator';
                        flag = data.flag;
                        text = '';
                        order = #self.options+1;
                        enabled = true;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and (separator[i] ~= nil and typeof(separator[i]) == typeof(v)) then
                            separator[i] = v;
                        end
                    end
        
                    table.insert(self.options, separator)

                    --- Create Objects ---
                    do
                        local objs = separator.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,18);
                            Transparency = 0;
                            ZIndex = z;
                            Parent = section.objects.optionholder;
                        })

                        objs.line1 = utility:Draw('Square', {
                            Position = newUDim2(0,0,0,1);
                            ThemeColor = 'Option Background';
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        objs.line2 = utility:Draw('Square', {
                            Position = newUDim2(0,0,0,1);
                            ThemeColor = 'Option Background';
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.line1;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.line2;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(.5,0,0,1);
                            ThemeColor = 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z;
                            Outline = true;
                            Center = true;
                            Parent = objs.holder;
                        })

                    end
                    ----------------------

                    function separator:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            local xScale = ( 1- utility:ConvertNumberRange(self.objects.text.TextBounds.X, 0, self.objects.holder.Object.Size.X, 0, 1)) / 2 - (str == '' and 0 or .04)
                            self.objects.line1.Size = newUDim2(xScale, 0, 0, 1)
                            self.objects.line2.Size = newUDim2(xScale, 0, 0, 1)
                            self.objects.line1.Position = newUDim2(0,1,.5,-1)
                            self.objects.line2.Position = newUDim2(1 - self.objects.line2.Size.X.Scale,-1,.5,-1)
                        end
                    end

                    separator:SetText(separator.text);
                    self:UpdateOptions();
                    return separator
                end

                -- // Color Picker
                function section:AddColor(data)
                    local color = {
                        class = 'color';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        color = Color3.new(1,1,1);
                        trans = 0;
                        open = false;
                        enabled = true;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and color[i] ~= nil then
                            color[i] = v
                        end
                    end
                    
                    table.insert(self.options, color)

                    if color.flag then
                        library.flags[color.flag] = color.color;
                        library.options[color.flag] = color;
                    end

                    --- Create Objects ---
                    do
                        local objs = color.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,19);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(0,15,0,8);
                            Position = newUDim2(1,-16,0,5);
                            ZIndex = z+3;
                            Parent = objs.holder;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp45;
                            Transparency = .25;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+2;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z+1;
                            Parent = objs.border1;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = color.risky and 'Risky Text Enabled' or 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = color.state and 'Accent' or 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            color:SetOpen(not color.open);
                        end)

                    end
                    ----------------------

                    function color:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function color:SetColor(c3, nocallback)
                        if typeof(c3) == 'Color3' then
                            local h,s,v = c3:ToHSV(); c3 = fromhsv(h, clamp(s,.005,.995), clamp(v,.005,.995));
                            self.color = c3;
                            self.objects.background.Color = c3;
                            if not nocallback then
                                self.callback(c3, self.trans);
                            end
                            if self.open then
                                window.colorpicker:Visualize(self.color, self.trans);
                            end
                            if self.flag then
                                library.flags[self.flag] = c3;
                            end
                        end
                    end

                    function color:SetTrans(trans, nocallback)
                        if typeof(trans) == 'number' then
                            self.trans = trans;
                            if not nocallback then
                                self.callback(self.color, trans);
                            end
                            if self.open then
                                window.colorpicker:Visualize(self.color, self.trans);
                            end
                        end
                    end

                    function color:SetOpen(bool)
                        if typeof(bool) == 'boolean' then
                            self.open = bool
                            if bool then
                                if window.colorpicker.selected then
                                    window.colorpicker.selected.open = false;
                                end
                                window.colorpicker.selected = color
                                window.colorpicker.objects.background.Parent = self.objects.background;
                                window.colorpicker.objects.background.Visible = true;
                                window.colorpicker:Visualize(color.color, color.trans)
                            elseif window.colorpicker.selected == color then
                                window.colorpicker.selected = nil;
                                window.colorpicker.objects.background.Parent = window.objects.background;
                                window.colorpicker.objects.background.Visible = false;
                            end
                        end
                    end

                    tooltip(color);
                    color:SetText(color.text);
                    color:SetColor(color.color, true);
                    color:SetTrans(color.trans, true);
                    self:UpdateOptions();
                    return color
                end

                -- // Text Box
                function section:AddBox(data)
                    local box = {
                        class = 'box';
                        flag = data.flag;
                        text = '';
                        input = '';
                        order = #self.options+1;
                        callback = function() end;
                        enabled = true;
                        focused = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects', 'dragging'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and box[i] ~= nil then
                            box[i] = v;
                        end
                    end
                    box.input = data.input or data.default or box.input;
                    box.default = data.default or box.input;

                    table.insert(self.options, box)

                    if box.flag then
                        library.flags[box.flag] = box.input;
                        library.options[box.flag] = box;
                    end

                    --- Create Objects ---
                    do
                        local objs = box.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,37);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,15);
                            Position = newUDim2(0,2,1,-17);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .65;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = box.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.inputText = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,0);
                            ThemeColor = 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if box.focused then
                                box:ReleaseFocus();
                                actionservice:UnbindAction('FreezeMovement');
                            else
                                actionservice:BindAction(
                                    'FreezeMovement',
                                    function()
                                        return Enum.ContextActionResult.Sink
                                    end,
                                    false,
                                    unpack(Enum.PlayerActions:GetEnumItems())
                                )
                                box:CaptureFocus(inputservice:IsKeyDown(Enum.KeyCode.LeftControl));
                                if inputservice:IsKeyDown(Enum.KeyCode.LeftControl) then
                                    objs.inputText.Text = '';
                                end
                            end
                        end)

                    end
                    ----------------------

                    function box:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function box:SetInput(str, nocallback)
                        if typeof(str) == 'string' then
                            self.input = str;
                            self.objects.inputText.Text = str;
                            if not nocallback then
                                self.callback(str);
                            end
                            if self.flag then
                                library.flags[self.flag] = str;
                            end
                        end
                    end

                    local c
                    local input = box.input;
                    function box:CaptureFocus(clear)
                        box.focused = true

                        if clear then
                            input = '';
                        end

                        self.objects.inputText.ThemeColor = 'Option Text 1';
                        c = utility:Connection(inputservice.InputBegan, function(inp)
                            if inp.KeyCode == Enum.KeyCode.Return or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                                box:ReleaseFocus(true);
                            elseif inp.KeyCode == Enum.KeyCode.Escape then
                                input = self.input
                                self.objects.inputText.Text = input;
                                box:ReleaseFocus();
                            elseif inp.KeyCode == Enum.KeyCode.Backspace then
                                input = input:sub(1,-2);
                                self.objects.inputText.Text = input;
                            elseif #inp.KeyCode.Name == 1 or table.find(whitelistedBoxKeys, inp.KeyCode) or inp.KeyCode.Name == 'Space' or inp.KeyCode.Name == 'Minus' or inp.KeyCode.Name == 'Equals' or inp.KeyCode.Name == 'Backquote' then
                                local wlIdx = table.find(whitelistedBoxKeys, inp.KeyCode)
                                local keyString = inp.KeyCode.Name == 'Space' and ' ' or inp.KeyCode.Name == 'Minus' and '_' or inp.KeyCode.Name == 'Equals' and '+' or inp.KeyCode.Name == 'Backquote' and '~' or wlIdx ~= nil and tostring(wlIdx-1) or inp.KeyCode.Name
                                if not (inputservice:IsKeyDown(Enum.KeyCode.LeftShift) and not inputservice:IsKeyDown(Enum.KeyCode.RightShift)) then
                                    keyString = keyString:lower();
                                    if inp.KeyCode.Name == 'Minus' then
                                        keyString = '-'
                                    elseif inp.KeyCode.Name == 'Equals' then
                                        keyString = '='
                                    elseif inp.KeyCode.Name == 'Backquote' then
                                        keyString = '`'
                                    end
                                else
                                    if keyString == '1' then
                                        keyString = '!'
                                    elseif keyString == '2' then
                                        keyString = '@'
                                    elseif keyString == '3' then
                                        keyString = '#'
                                    elseif keyString == '4' then
                                        keyString = '$'
                                    elseif keyString == '5' then
                                        keyString = '%'
                                    elseif keyString == '6' then
                                        keyString = '^'
                                    elseif keyString == '7' then
                                        keyString = '&'
                                    elseif keyString == '8' then
                                        keyString = '*'
                                    elseif keyString == '9' then
                                        keyString = '('
                                    elseif keyString == '0' then
                                        keyString = ')'
                                    end
                                end
                                input = input..keyString;
                                self.objects.inputText.Text = input;
                            end
                        end)

                    end

                    function box:ReleaseFocus(apply)
                        box.focused = false;
                        self.objects.inputText.ThemeColor = 'Option Text 2';
                        if apply then
                            box:SetInput(input);
                        end
                        c:Disconnect();
                    end

                    tooltip(box);
                    box:SetText(box.text);
                    box:SetInput(box.input, true);
                    self:UpdateOptions();
                    return box
                end

                -- // Keybind
                function section:AddBind(data)
                    local bind = {
                        class = 'bind';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        bind = 'none';
                        mode = 'toggle';
                        order = #self.options+1;
                        callback = function() end;
                        keycallback = function() end;
                        indicatorValue = library.keyIndicator:AddValue({value = 'value', key = 'key', enabled = false});
                        noindicator = false;
                        state = false;
                        nomouse = false;
                        enabled = true;
                        binding = false;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and bind[i] ~= nil then
                            bind[i] = v
                        end
                    end
                    
                    table.insert(self.options, bind)

                    if bind.flag then
                        library.options[bind.flag] = bind;
                    end

                    --- Create Objects ---
                    do
                        local objs = bind.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,19);
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = bind.risky and 'Risky Text' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.keyText = utility:Draw('Text', {
                            ThemeColor = 'Option Text 3';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Parent = objs.holder;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.keyText.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.keyText.ThemeColor = bind.binding and 'Accent' or 'Option Text 3';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if not bind.binding then
                                bind:SetKeyText('...');
                                bind.binding = true;
                            end
                        end)

                    end
                    ----------------------

                    local c

                    function bind:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            self.indicatorValue:SetKey(str);
                        end
                    end

                    function bind:SetBind(keybind)
                        if c then
                            c:Disconnect();
                            if bind.flag then
                                library.flags[bind.flag] = false;
                            end
                            bind.callback(false);
                        end
                        local keyName = 'NONE'
                        if keybind == nil or keybind == true or keybind == false then
                            keybind = 'none'
                        end
                        self.bind = (keybind and keybind ~= 'none') and keybind or self.bind
                        if self.bind == Enum.KeyCode.Backspace then
                            self.bind = 'none';
                        end
                        if self.bind ~= 'none' then
                            keyName = keyNames[self.bind] or (type(self.bind) == "userdata" or type(self.bind) == "table") and self.bind.Name or tostring(self.bind)
                        end
                        self.keycallback(self.bind);
                        self:SetKeyText(keyName:upper());
                        self.indicatorValue:SetKey((self.text == nil or self.text == '') and (self.flag == nil and 'unknown' or self.flag) or self.text); -- this is so dumb
                        self.indicatorValue:SetValue('['..keyName:upper()..']');
                        self.objects.keyText.ThemeColor = self.objects.holder.Hover and 'Accent' or 'Option Text 3';
                    end

                    function bind:SetKeyText(str)
                        str = tostring(str);
                        self.objects.keyText.Text = '['..str..']';
                        self.objects.keyText.Position = newUDim2(1,-self.objects.keyText.TextBounds.X, 0, 2);
                    end

                    utility:Connection(inputservice.InputBegan, function(inp)
                        if inputservice:GetFocusedTextBox() then
                            return
                        elseif bind.binding then
                            local key = (table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}, inp.UserInputType) and not bind.nomouse) and inp.UserInputType
                            bind:SetBind(key or (not table.find(blacklistedKeys, inp.KeyCode)) and inp.KeyCode)
                            bind.binding = false
                        elseif not bind.binding and self.bind == 'none' then
                            bind.state = true
                            library.flags[bind.flag] = bind.state
                        elseif (inp.KeyCode == bind.bind or inp.UserInputType == bind.bind) and not bind.binding then
                            if bind.mode == 'toggle' then
                                bind.state = not bind.state
                                if bind.flag then
                                    library.flags[bind.flag] = bind.state;
                                end
                                bind.callback(bind.state)
                                bind.indicatorValue:SetEnabled(bind.state and not bind.noindicator);
                            elseif bind.mode == 'hold' then
                                if bind.flag then
                                    library.flags[bind.flag] = true;
                                end
                                bind.indicatorValue:SetEnabled(true and not bind.noindicator);
                                c = utility:Connection(runservice.RenderStepped, function()
                                    bind.callback(true);
                                end)
                            end
                        end
                    end)

                    utility:Connection(inputservice.InputEnded, function(inp)
                        if bind.bind ~= 'none' then
                            if inp.KeyCode == bind.bind or inp.UserInputType == bind.bind then
                                if c then
                                    c:Disconnect();
                                    if bind.flag then
                                        library.flags[bind.flag] = false;
                                    end
                                    bind.callback(false);
                                    bind.indicatorValue:SetEnabled(false);
                                end
                            end
                        end
                    end)

                    tooltip(bind);
                    bind:SetBind(bind.bind);
                    bind:SetText(bind.text);
                    self:UpdateOptions();
                    return bind
                end

                -- // Dropdown
                function section:AddList(data)
                    local list = {
                        class = 'list';
                        flag = data.flag;
                        text = '';
                        selected = '';
                        tooltip = '';
                        order = #self.options+1;
                        callback = function() end;
                        enabled = true;
                        multi = false;
                        open = false;
                        risky = false;
                        values = {};
                        objects = {};
                    }

                    table.insert(self.options, list);

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) ~= list[i] ~= nil then
                            list[i] = v
                        end
                    end

                    if list.flag then
                        library.flags[list.flag] = list.selected;
                        library.options[list.flag] = list;
                    end

                    -- Create Objects --
                    do
                        local objs = list.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Size = newUDim2(1,0,0,40);
                            Transparency = 0;
                            ZIndex = z+4;
                            Parent = section.objects.optionholder;
                        })

                        objs.background = utility:Draw('Square', {
                            Size = newUDim2(1,-4,0,15);
                            Position = newUDim2(0,2,1,-19);
                            ThemeColor = 'Option Background';
                            ZIndex = z+2;
                            Parent = objs.holder;
                        })

                        objs.border1 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 1';
                            ZIndex = z+1;
                            Parent = objs.background;
                        })

                        objs.border2 = utility:Draw('Square', {
                            Size = newUDim2(1,2,1,2);
                            Position = newUDim2(0,-1,0,-1);
                            ThemeColor = 'Option Border 2';
                            ZIndex = z;
                            Parent = objs.border1;
                        })

                        objs.gradient = utility:Draw('Image', {
                            Size = newUDim2(1,0,1,0);
                            Data = library.images.gradientp90;
                            Transparency = .65;
                            ZIndex = z+4;
                            Parent = objs.background;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = list.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })

                        objs.inputText = utility:Draw('Text', {
                            Position = newUDim2(0,4,0,0);
                            ThemeColor = 'Option Text 2';
                            Text = 'none',
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        objs.openText = utility:Draw('Text', {
                            Position = newUDim2(1,-10,0,0);
                            ThemeColor = 'Option Text 3';
                            Text = '+';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+5;
                            Outline = true;
                            Parent = objs.background;
                        })

                        utility:Connection(objs.holder.MouseEnter, function()
                            objs.border1.ThemeColor = 'Accent';
                        end)

                        utility:Connection(objs.holder.MouseLeave, function()
                            objs.border1.ThemeColor = 'Option Border 1';
                        end)

                        utility:Connection(objs.holder.MouseButton1Down, function()
                            if list.open then
                                list.open = false;
                                objs.openText.Text = '+';
                                if window.dropdown.selected == list then
                                    window.dropdown.selected = nil;
                                    window.dropdown.objects.background.Visible = false;
                                end
                            else
                                if window.dropdown.selected ~= nil then
                                    window.dropdown.selected.open = false
                                end
                                list.open = true;
                                objs.openText.Text = '-';
                                window.dropdown.selected = list;
                                window.dropdown.objects.background.Visible = true;
                                window.dropdown.objects.background.Parent = objs.holder;
                                window.dropdown:Refresh();
                            end
                        end)


                    end
                    --------------------

                    function list:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                        end
                    end

                    function list:Select(option, nocallback)
                        option = typeof(option) == 'table' and (self.multi == true and option or (#option == 0 and nil or option[1])) or self.multi == true and {option} or option;
                        if option ~= nil then
                            self.selected = option;
                            local text = typeof(option) == 'table' and (#option == 0 and "none" or table.concat(option, ', ')) or tostring(option);
                            local label = self.objects.inputText
                            label.Text = text;
                            if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                local split = text:split('');
                                for i = 1,#split do
                                    label.Text = table.concat(split, '', 1, i)
                                    if label.TextBounds.X > self.objects.background.Object.Size.X - 10 then
                                        label.Text = label.Text:sub(1,-6)..'...';
                                        break
                                    end
                                end
                            end
                            if self.flag then
                                library.flags[self.flag] = self.selected
                            end
                            if not nocallback then
                                self.callback(self.selected);
                            end
                        end
                    end

                    function list:AddValue(value)
                        table.insert(list.values, tostring(value));
                        if window.dropdown.selected == list then
                            window.dropdown:Refresh()
                        end
                    end

                    function list:RemoveValue(value)
                        if table.find(list.values, value) then
                            table.remove(list.values, table.find(list.values, value));
                            if window.dropdown.selected == list then
                                window.dropdown:Refresh()
                            end
                        end
                    end

                    function list:ClearValues()
                        table.clear(list.values);
                        if window.dropdown.selected == list then
                            window.dropdown:Refresh()
                        end
                    end

                    tooltip(list);
                    list.default = data.default or data.selected or data.value;
                    list:Select((data.value or data.selected or data.default) or (list.multi and 'none' or list.values[1]), true);
                    list:SetText(list.text);
                    self:UpdateOptions();
                    return list
                end

                -- Text
                function section:AddText(data)
                    local text = {
                        class = 'text';
                        flag = data.flag;
                        text = '';
                        tooltip = '';
                        order = #self.options+1;
                        enabled = true;
                        risky = false;
                        objects = {};
                    };

                    local blacklist = {'objects'};
                    for i,v in next, data do
                        if not table.find(blacklist, i) and text[i] ~= nil then
                            text[i] = v
                        end
                    end

                    if data.flag then
                        library.options[data.flag] = text;
                    end

                    table.insert(self.options, text)

                    --- Create Objects ---
                    do
                        local objs = text.objects;
                        local z = library.zindexOrder.window+25;

                        objs.holder = utility:Draw('Square', {
                            Transparency = 0;
                            ZIndex = z+5;
                            Parent = section.objects.optionholder;
                        })

                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0,2,0,2);
                            ThemeColor = text.risky and 'Risky Text Enabled' or 'Option Text 2';
                            Size = 13;
                            Font = 2;
                            ZIndex = z+1;
                            Outline = true;
                            Parent = objs.holder;
                        })
                    end
                    ----------------------

                    function text:SetText(str)
                        if typeof(str) == 'string' then
                            self.text = str;
                            self.objects.text.Text = str;
                            self.objects.holder.Size = newUDim2(1,0,0,self.objects.text.TextBounds.Y + 6);
                            section:UpdateOptions();
                        end
                    end

                    text:SetText(text.text);
                    self:UpdateOptions();
                    return text
                end

                -----------------------

                section:UpdateOptions();
                section:SetText(section.text);
                self:UpdateSections();
                return section;
            end

            function tab:UpdateSections()
                table.sort(self.sections, function(a,b)
                    return a.order < b.order
                end)

                local last1,last2;
                local padding = 15;
                for _,section in next, self.sections do

                    if section.objects.background.Visible ~= (section.enabled and tab.selected) then
                        section.objects.background.Visible = section.enabled and tab.selected
                        section:UpdateOptions();
                    end
                    
                    if section.enabled then
                        if section.side == 1 then
                            if last1 then
                                section.objects.background.Position = last1.objects.background.Position + newUDim2(0,0,0,last1.objects.background.Object.Size.Y + padding);
                            end
                            last1 = section;
                        elseif section.side == 2 then
                            if last2 then
                                section.objects.background.Position = last2.objects.background.Position + newUDim2(0,0,0,last2.objects.background.Object.Size.Y + padding);
                            end
                            last2 = section;
                        end
                    end

                    section:SetText(section.text)
                    
                end
            end

            function tab:SetText(str)
                if typeof(str) == 'string' then
                    self.text = str;
                    self.objects.text.Text = str;
                    window:UpdateTabs();
                end
            end

            function tab:Select()
                window.selectedTab = tab;
                window:UpdateTabs();
                for i,v in next, window.tabs do
                    if v.callback then
                        v.callback(v == tab)
                    end
                end
            end

            if window.selectedTab == nil then
                tab:Select();
            end

            tab:SetText(tab.text);
            window:UpdateTabs();
            return tab;
        end

        function window:UpdateTabs()
    table.sort(self.tabs, function(a,b)
        return a.order < b.order
    end)
    
    -- Calculate dynamic tab width based on UI width and number of tabs
    local totalWidth = self.objects.tabHolder.Object.Size.X
    local tabCount = #self.tabs
    
    if tabCount == 0 then return end
    
    local spacing = 1 -- 1 pixel spacing between tabs
    local totalSpacing = (tabCount - 1) * spacing
    local availableWidth = totalWidth - totalSpacing
    
    -- Calculate base tab width and distribute any remaining pixels
    local baseTabWidth = math.floor(availableWidth / tabCount)
    local remainingPixels = availableWidth - (baseTabWidth * tabCount)
    
    local pos = 0;
    for i,v in next, self.tabs do
        local objs = v.objects;
        v.selected = v == self.selectedTab;
        objs.background.ThemeColor = v.selected and 'Selected Tab Background' or 'Unselected Tab Background';
        
        -- Give extra pixels to the first tabs to ensure full coverage
        local tabWidth = baseTabWidth
        if i <= remainingPixels then
            tabWidth = tabWidth + 1
        end
        
        -- The last tab should extend to fill any remaining space
        if i == tabCount then
            tabWidth = totalWidth - pos
        end
        
        objs.background.Size = newUDim2(0, tabWidth, 1, v.selected and 1 or 0);
        objs.background.Position = newUDim2(0, pos, 0, 0)

        objs.text.ThemeColor = v.selected and 'Selected Tab Text' or 'Unselected Tab Text';
        objs.text.Position = newUDim2(.5, 0, 0, 3);

        objs.topBorder.ThemeColor = v.selected and 'Accent' or 'Unselected Tab Background';

        -- Update position for next tab
        if i < tabCount then
            pos = pos + tabWidth + spacing
        end

        v:UpdateSections();

    end
    -- Content-sized windows: resize to fit after laying out tabs/sections
    if self.resizeToContent then
        self:UpdateSizeFromContent()
    end
    -- Single-tab window: hide tab bar for a clean dialog-style layout
    if tabCount == 1 then
        self.objects.tabHolder.Visible = false
    else
        self.objects.tabHolder.Visible = true
    end
end

        function window:Destroy()
            if library._dialogWindow == self then library._dialogWindow = nil end
            pcall(function() self.objects.background:Remove() end);
            for i, w in next, library.windows do
                if w == self then library.windows[i] = nil break end
            end
        end

        -- Height per option class (matches holder sizes in AddToggle, AddButton, etc.)
        local function getOptionHeight(option)
            if not option or not option.class then return 22 end
            local h = { toggle = 17, button = 22, slider = 22, list = 22, separator = 18, color = 19, box = 37, bind = 19, text = 19 }
            return h[option.class] or 22
        end

        function window:UpdateSizeFromContent()
            if self._fixedSize then
                self.objects.background.Size = self._fixedSize
                if self.objects.background.Update then self.objects.background:Update() end
                if self._fixedPosition then
                    self.objects.background.Position = self._fixedPosition
                    if self.objects.background.Update then self.objects.background:Update() end
                end
                return
            end
            if not self.resizeToContent then return end
            local sectionPadding = 15
            local fixedTop = 8 + 23
            local fixedBottom = 16 + 23
            local tabRowH = 20
            local contentH = 0
            local contentW = self._contentMinWidth or 320
            for _, tab in next, self.tabs do
                local col1, col2 = 0, 0
                for _, section in next, tab.sections do
                    if not section.enabled then continue end
                    local sectionH = 15
                    for _, option in next, section.options do
                        if option.enabled then
                            sectionH = sectionH + getOptionHeight(option)
                        end
                    end
                    if section.side == 1 then
                        col1 = col1 + sectionH + sectionPadding
                    else
                        col2 = col2 + sectionH + sectionPadding
                    end
                end
                local tabH = col1 > col2 and col1 or col2
                if tabH > contentH then contentH = tabH end
            end
            local totalH = fixedTop + tabRowH + contentH + fixedBottom
            -- Single-tab content window: no visible tab row, so don't reserve height for it
            if #self.tabs == 1 then
                totalH = fixedTop + contentH + fixedBottom
            end
            totalH = clamp(totalH, 100, 800)
            contentW = clamp(contentW, 260, 1200)
            self.objects.background.Size = newUDim2(0, contentW, 0, totalH)
            if self.objects.background.Update then
                self.objects.background:Update()
            end
            if self._contentCenter then
                local cam = workspace.CurrentCamera
                local vw = (cam and cam.ViewportSize and cam.ViewportSize.X) or 800
                local vh = (cam and cam.ViewportSize and cam.ViewportSize.Y) or 600
                self.objects.background.Position = newUDim2(0, vw / 2 - contentW / 2, 0, vh / 2 - totalH / 2)
            end
        end

        window:SetOpen(true);
        return window;
    end

    -- Tooltip
    do
        local z = library.zindexOrder.window + 2000;
        tooltipObjects.background = utility:Draw('Square', {
            ThemeColor = 'Group Background';
            ZIndex = z;
            Visible = false;
        })

        tooltipObjects.border1 = utility:Draw('Square', {
            Size = UDim2.new(1,2,1,2);
            Position = UDim2.new(0,-1,0,-1);
            ThemeColor = 'Border 1';
            ZIndex = z-1;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.border2 = utility:Draw('Square', {
            Size = UDim2.new(1,4,1,4);
            Position = UDim2.new(0,-2,0,-2);
            ThemeColor = 'Border 3';
            ZIndex = z-2;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.text = utility:Draw('Text', {
            Position = UDim2.new(0,3,0,0);
            ThemeColor = 'Primary Text';
            Size = 13;
            Font = 2;
            ZIndex = z+1;
            Outline = true;
            Parent = tooltipObjects.background;
        })

        tooltipObjects.riskytext = utility:Draw('Text', {
            Position = UDim2.new(0,3,0,0);
            ThemeColor = 'Risky Text Enabled';
            Text = '[RISKY]';
            Size = 13;
            Font = 2;
            ZIndex = z+1;
            Outline = true;
            Parent = tooltipObjects.background;
        })

    end
    
    -- Watermark
    do
        if not IonHub_User then
            getgenv().IonHub_User = {
                UID = 0, 
                User = "admin"
            }
        end

    
       self.watermark = {
            objects = {};
            text = {
                {"CROW", true},
                {executor, true},
                {game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, true},
                {'0 fps', true},
                {'0ms', true},
                {'00:00:00', true},
                {'M, D, Y', true},
            };
            lock = 'custom';
            position = newUDim2(0,0,0,0);
            refreshrate = (library.config and library.config.WatermarkRefreshrate) or defaultConfig.WatermarkRefreshrate;
        }

        function self.watermark:Update()
            self.objects.background.Visible = library.flags.watermark_enabled
            if library.flags.watermark_enabled then
                local date = {os.date('%b',os.time()), os.date('%d',os.time()), os.date('%Y',os.time())}
                local daySuffix = math.floor(date[2]%10)
                date[2] = date[2]..(daySuffix == 1 and 'st' or daySuffix == 2 and 'nd' or daySuffix == 3 and 'rd' or 'th')

                self.text[4][1] = library.stats.fps..' fps'
                self.text[5][1] = floor(library.stats.ping)..'ms'
                self.text[6][1] = os.date('%X', os.time())
                self.text[7][1] = table.concat(date, ', ')

                local text = {};
                for _,v in next, self.text do
                    if v[2] then
                        table.insert(text, v[1]);
                    end
                end

                self.objects.text.Text = table.concat(text,' | ')
                self.objects.background.Size = newUDim2(0, self.objects.text.TextBounds.X + 10, 0, 17)

                local size = self.objects.background.Object.Size;
                local screensize = workspace.CurrentCamera.ViewportSize;

                self.position = (
                    self.lock == 'Top Right' and newUDim2(0, screensize.X - size.X - 15, 0, 15) or
                    self.lock == 'Top Left' and newUDim2(0, 15, 0, 15) or
                    self.lock == 'Bottom Right' and newUDim2(0, screensize.X - size.X - 15, 0, screensize.Y - size.Y - 15) or
                    self.lock == 'Bottom Left' and newUDim2(0, 15, 0, screensize.Y - size.Y - 15) or
                    self.lock == 'Top' and newUDim2(0, screensize.X / 2 - size.X / 2, 0, 15) or
                    newUDim2(library.flags.watermark_x / 100, 0, library.flags.watermark_y / 100, 0)
                )

                self.objects.background.Position = self.position
            end
        end

        do
            local objs = self.watermark.objects;
            local z = self.zindexOrder.watermark;
            
            objs.background = utility:Draw('Square', {
                Visible = false;
                Size = newUDim2(0, 200, 0, 17);
                Position = newUDim2(0,800,0,100);
                ThemeColor = 'Background';
                ZIndex = z;
            })

            objs.border1 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 2';
                Parent = objs.background;
                ZIndex = z-1;
            })

            objs.border2 = utility:Draw('Square', {
                Size = newUDim2(1,2,1,2);
                Position = newUDim2(0,-1,0,-1);
                ThemeColor = 'Border 3';
                Parent = objs.border1;
                ZIndex = z-2;
            })
            
            objs.topbar = utility:Draw('Square', {
                Size = newUDim2(1,0,0,1);
                ThemeColor = 'Accent';
                ZIndex = z+1;
                Parent = objs.background;
            })

            objs.text = utility:Draw('Text', {
                Position = newUDim2(.5,0,0,2);
                ThemeColor = 'Primary Text';
                Text = 'Watermark Text';
                Size = 13;
                Font = 2;
                ZIndex = z+1;
                Outline = true;
                Center = true;
                Parent = objs.background;
            })

        end
    end

    local lasttick = 0;
    utility:Connection(runservice.RenderStepped, function(step)
        if (tick()-lasttick)*1000 > library.watermark.refreshrate then
            lasttick = tick()
            library.stats.fps = floor(1/step)
            pcall(function()
                library.stats.ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            library.stats.sendkbps = stats.DataSendKbps
            library.stats.receivekbps = stats.DataReceiveKbps
            library.watermark:Update()
        end
    end)

    self.keyIndicator = self.NewIndicator({title = 'Keybinds', pos = newUDim2(0,15,0,325), enabled = true});
    
    self.targetIndicator = self.NewIndicator({title = 'Target Info', pos = newUDim2(0,75,0,350), enabled = false});
    self.targetName = self.targetIndicator:AddValue({key = 'Name     :', value = 'nil'})
    self.targetDisplay = self.targetIndicator:AddValue({key = 'DName    :', value = 'nil'})
    self.targetHealth = self.targetIndicator:AddValue({key = 'Health   :', value = '0'})
    self.targetDistance = self.targetIndicator:AddValue({key = 'Distance :', value = '0m'})
    self.targetTool = self.targetIndicator:AddValue({key = 'Weapon   :', value = 'nil'})
    self.targetTarget = self.targetIndicator:AddValue({key = 'Target   :', value = 'nil'})

    -- Ensure theme is populated so safe mode dialog (and all UI) gets correct colors. library.theme starts empty and is only filled from presets/config later; use default theme until then.
    if next(library.theme) == nil and library.themes and library.themes[1] and library.themes[1].theme then
        for i, v in next, library.themes[1].theme do
            library.theme[i] = v
        end
    end
    self:SetTheme(library.theme);
    -- Do not SetOpen(true) here; safe mode runs first (real UiInnit window), then main window loads after YES/NO.

    -- Safe mode: single panel (one rect), draggable, sized from actual content. Blocks until YES/NO clicked; returns true/false.
    function self:ShowSafeModeDialog()
        local cam = workspace.CurrentCamera
        local vw = (cam and cam.ViewportSize and cam.ViewportSize.X) or 800
        local vh = (cam and cam.ViewportSize and cam.ViewportSize.Y) or 600
        -- Content width: one value used for window; section optionholder is 97% of column, column = full width
        local contentWidth = 360
        local padH = 16
        local posX = floor(vw / 2 - contentWidth / 2)
        local posY = floor(vh / 2 - 60) -- temp; final pos set after we know safeH
        local win = self:NewWindow({
            title = "";
            size = newUDim2(0, contentWidth, 0, 80);
            position = newUDim2(0, posX, 0, posY);
            resizeToContent = false;
        })
        library._dialogWindow = win
        local objs = win.objects
        local z = library.zindexOrder.window
        -- Match main window: keep outer outline (innerBorder1/2), hide title bar chrome only
        if objs.midBorder then objs.midBorder.Visible = false end
        if objs.title then objs.title.Visible = false end
        if objs.outerBorder1 then objs.outerBorder1.Visible = false end
        if objs.outerBorder2 then objs.outerBorder2.Visible = false end
        if objs.tabHolder then objs.tabHolder.Visible = false end
        if objs.topBorder then objs.topBorder.Visible = false end
        -- innerBorder1 + innerBorder2 stay visible = same outer outline as main window (Border 3 + Border 1)
        -- Content only: no header bar or blue line; groupBackground = full area with nested frame (groupInnerBorder + groupOuterBorder)
        if objs.groupBackground then
            objs.groupBackground.Position = newUDim2(0, 0, 0, 0)
            objs.groupBackground.Size = newUDim2(1, 0, 1, 0)
        end
        if objs.columnholder1 then
            objs.columnholder1.Position = newUDim2(0, 0, 0, 0)
            objs.columnholder1.Size = newUDim2(1, 0, 1, 0)
        end
        if objs.columnholder2 then objs.columnholder2.Visible = false end
        -- groupInnerBorder + groupOuterBorder stay visible = nested content frame only
        local tab = win:AddTab("", 1)
        local sec = tab:AddSection("", 1)
        -- Flat panel: no section frame, title, or accent lines (single clean panel)
        if sec.objects.topBorder1 then sec.objects.topBorder1.Visible = false end
        if sec.objects.topBorder2 then sec.objects.topBorder2.Visible = false end
        if sec.objects.textlabel then sec.objects.textlabel.Visible = false end
        if sec.objects.innerBorder then sec.objects.innerBorder.Visible = false end
        if sec.objects.outerBorder then sec.objects.outerBorder.Visible = false end
        -- AddText sets holder Size to (1,0,0, TextBounds.Y+6) in SetText; keep that so text row = 100% optionholder
        sec:AddText({ text = "SAFE MODE?" })
        for _, opt in next, sec.options do
            if opt.class == "text" and opt.objects and opt.objects.text then
                opt.objects.text.Center = true
                opt.objects.text.Position = newUDim2(0.5, 0, 0, 2)
                if opt.objects.text.Update then opt.objects.text:Update() end
                break
            end
        end
        local result = nil
        local function closeDialog()
            library._dialogWindow = nil
            local bg = win.objects and win.objects.background
            if not bg then return end
            local function hideAll(d)
                if not d then return end
                d.Visible = false
                pcall(function() if d.Object and type(d.Object) ~= "number" then d.Object.Visible = false end end)
                if d.Update then pcall(function() d:Update() end) end
                for _, ch in next, (d.Children or {}) do hideAll(ch) end
            end
            hideAll(bg)
            pcall(function() win:Destroy() end)
        end
        local yesBtn = sec:AddButton({ text = "YES", callback = function()
            result = true
            closeDialog()
        end })
        yesBtn:AddButton({ text = "NO", callback = function()
            result = false
            closeDialog()
        end })
        -- Button holder stays default (1,0,0,22) = 100% optionholder width; UpdateOptions splits YES/NO 50-50
        yesBtn:UpdateOptions()
        sec:UpdateOptions()
        -- Section height comes from section:UpdateOptions: ySize = 15 + sum(option.objects.holder.Object.Size.Y)
        local contentH = 70
        local secBg = sec.objects.background
        if secBg then
            if secBg.Object and secBg.Object.Size and type(secBg.Object.Size.Y) == "number" then
                contentH = secBg.Object.Size.Y
            elseif secBg.Size and secBg.Size.Y and type(secBg.Size.Y.Offset) == "number" then
                contentH = secBg.Size.Y.Offset
            end
        end
        -- Remove bottom strip: optionholder default (1,-.03,1,-15) leaves 2px section background visible; extend to -13 so it fills to bottom
        if sec.objects.optionholder then
            sec.objects.optionholder.Size = newUDim2(1 - .03, 0, 1, -13)
            sec.objects.optionholder.Position = newUDim2(0.015, 0, 0, 13)
        end
        local safeW = contentWidth
        local safeH = contentH + padH
        posY = floor(vh / 2 - safeH / 2)
        win._fixedSize = newUDim2(0, safeW, 0, safeH)
        win._fixedPosition = newUDim2(0, posX, 0, posY)
        local bg = objs.background
        bg.Size = newUDim2(0, safeW, 0, safeH)
        bg.Position = newUDim2(0, posX, 0, posY)
        if bg.Update then bg:Update() end
        -- Draggable: whole dialog (background, outer frame, content frame, section area) — not the drag strip
        local dragging, mouseStartX, mouseStartY, objStartX, objStartY
        local function startDrag(pos)
            dragging = true
            mouseStartX = pos.X
            mouseStartY = pos.Y
            local p = objs.background.Object and objs.background.Object.Position
            if p and (type(p) == "userdata" or type(p) == "table") and type(p.X) == "number" and type(p.Y) == "number" then
                objStartX, objStartY = p.X, p.Y
            else
                objStartX, objStartY = posX, posY
            end
        end
        for _, el in next, { objs.background, objs.innerBorder1, objs.innerBorder2, objs.groupBackground, objs.groupInnerBorder, objs.groupOuterBorder, sec.objects.background } do
            if el and el.MouseButton1Down then
                utility:Connection(el.MouseButton1Down, startDrag)
            end
        end
        utility:Connection(button1up, function()
            dragging = false
        end)
        utility:Connection(mousemove, function(pos)
            if dragging and objs.background then
                local nx = objStartX + (pos.X - mouseStartX)
                local ny = objStartY + (pos.Y - mouseStartY)
                objs.background.Position = newUDim2(0, nx, 0, ny)
                win._fixedPosition = objs.background.Position
                if objs.background.Update then objs.background:Update() end
            end
        end)
        library:UpdateThemeColors()
        repeat task.wait() until result ~= nil
        return result
    end

    -- New content-sized window: same CROWui theme and API as the main cheat window. Use for dialogs or a second window.
    -- Window sizes to its contents (e.g. text + 2 buttons side by side = horizontal rectangle; text on top, buttons below).
    -- Options: title, position, contentMinWidth (default 320), contentCenter (default true). Returns window; use AddTab/AddSection/AddText/AddButton like the main UI.
    -- Example (second window with text + two buttons):
    --   local w = CROW:NewContentSizedWindow({ title = "Confirm" })
    --   local tab = w:AddTab("", 1)
    --   local sec = tab:AddSection("", 1)
    --   sec:AddText({ text = "Are you sure?" })
    --   sec:AddButton({ text = "Yes", callback = fnYes }):AddButton({ text = "No", callback = fnNo })
    -- Size updates automatically when you add content (no need to call UpdateSizeFromContent).
    function self:NewContentSizedWindow(data)
        data = data or {}
        local cam = workspace.CurrentCamera
        local vw = (cam and cam.ViewportSize and cam.ViewportSize.X) or 800
        local vh = (cam and cam.ViewportSize and cam.ViewportSize.Y) or 600
        local w = data.contentMinWidth or 320
        local h = 150
        local pos = data.position or newUDim2(0, vw / 2 - w / 2, 0, vh / 2 - h / 2)
        return self:NewWindow({
            title = data.title or '';
            size = data.size or newUDim2(0, w, 0, h);
            position = pos;
            resizeToContent = true;
            contentMinWidth = data.contentMinWidth or 320;
            contentCenter = data.contentCenter ~= false;
        })
    end

    self.hasInit = true

end

-- Fixed CreateSettingsTab function
function library:CreateSettingsTab(menu)
    local settingsTab = menu:AddTab('Settings', 999);
    local configSection = settingsTab:AddSection('Config', 1);
    local mainSection = settingsTab:AddSection('Main', 1);

    configSection:AddBox({text = 'Config Name', flag = 'configinput', default = ''})
    configSection:AddList({text = 'Config', flag = 'selectedconfig', default = ''})

    local function refreshConfigs()
        library.options.selectedconfig:ClearValues();
        for _,v in next, listfiles(self.cheatname..'/'..self.configname) do
            local ext = '.'..v:split('.')[#v:split('.')];
            if ext == self.fileext then
                library.options.selectedconfig:AddValue(v:split('\\')[#v:split('\\')]:sub(1,-#ext-1))
            end
        end
    end

    configSection:AddButton({text = 'Load', confirm = true, callback = function()
        library:LoadConfig(library.flags.selectedconfig);
    end}):AddButton({text = 'Save', confirm = true, callback = function()
        library:SaveConfig(library.flags.selectedconfig);
    end})

    configSection:AddButton({text = 'Create', confirm = true, callback = function()
        local name = tostring(library.flags.configinput or ""):gsub("[^%w%-%_]", "")
        if name == "" then
            library:SendNotification('Enter a config name.', 5, c3new(1,0,0))
            return
        end
        if library:GetConfig(name) then
            library:SendNotification('Config already exists: '..name, 5, c3new(1,0,0))
            return
        end
        pcall(function() makefolder(self.cheatname) makefolder(self.cheatname..'/'..self.configname) end)
        writefile(self.cheatname..'/'..self.configname..'/'..name..self.fileext, http:JSONEncode({}))
        refreshConfigs()
        library:SendNotification('Created config: '..name, 3, c3new(0,1,0))
    end}):AddButton({text = 'Delete', confirm = true, callback = function()
        local name = tostring(library.flags.selectedconfig or ""):gsub("[^%w%-%_]", "")
        if name == "" then
            library:SendNotification('Select a config to delete.', 5, c3new(1,0,0))
            return
        end
        if library:GetConfig(name) then
            pcall(function() delfile(self.cheatname..'/'..self.configname..'/'..name..self.fileext) end)
            refreshConfigs()
            library:SendNotification('Deleted config: '..name, 5, c3new(0,1,0))
        else
            library:SendNotification('Config does not exist: '..name, 5, c3new(1,0,0))
        end
    end})

    refreshConfigs()
    -- If config list has entries but none selected, select the first so Load/Save work
    pcall(function()
        local list = library.options.selectedconfig
        if list and list.values and #list.values > 0 and (list.selected == nil or list.selected == '' or (type(list.selected) == 'table' and #list.selected == 0)) then
            list:Select(list.values[1], true)
        end
    end)

    mainSection:AddBind({text = 'Open / Close', flag = 'togglebind', nomouse = true, noindicator = true, bind = Enum.KeyCode.Insert, callback = function(state)
        library:SetOpen(state)
    end});

    mainSection:AddButton({text = 'Join Discord', flag = 'joindiscord', confirm = true, callback = function()
        local url = library.config and library.config.DiscordInvite or defaultConfig.DiscordInvite
        if type(request) == "function" then
            request({Url = url, Method = "GET"})
        elseif type(http_request) == "function" then
            http_request({Url = url, Method = "GET"})
        else
            setclipboard(url)
            library:SendNotification(library.cheatname..' | Discord link copied to clipboard!', 3);
            return
        end
        library:SendNotification(library.cheatname..' | Opening Discord in browser!', 3);
    end})

    mainSection:AddButton({text = 'Rejoin Server', confirm = true, callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId);
    end})

    mainSection:AddButton({text = 'Server Hop', confirm = true, callback = function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")

        local function serverHop()
            local apiBase = (library.config and library.config.RobloxGamesApi) or defaultConfig.RobloxGamesApi
            local success, servers = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(apiBase .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)
            
            if success and servers.data then
                local availableServers = {}
                
                for _, server in pairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(availableServers, server.id)
                    end
                end
                
                if #availableServers > 0 then
                    local randomServer = availableServers[math.random(1, #availableServers)]
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer)
                else
                    TeleportService:Teleport(game.PlaceId)
                end
            else
                TeleportService:Teleport(game.PlaceId)
            end
        end
        serverHop()
    end})

    mainSection:AddButton({text = 'Rejoin Game', confirm = true, callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId);
    end})

    mainSection:AddButton({text = 'Copy Join Script', callback = function()
        setclipboard(([[game:GetService("TeleportService"):TeleportToPlaceInstance(%s, "%s")]]):format(game.PlaceId, game.JobId))
    end})

    mainSection:AddButton({text = "Unload", confirm = true,
       callback = function(bool)
           if bool then
               library:Unload() 
           else
               library:Unload() 
           end
       end})

    mainSection:AddSeparator({text = 'Indicators'});

    mainSection:AddToggle({text = 'Watermark', flag = 'watermark_enabled', state = true,});

    mainSection:AddSlider({text = 'Custom X', flag = 'watermark_x', suffix = '%', min = 0, max = 100, increment = .1, default = 6, value = 6});
    mainSection:AddSlider({text = 'Custom Y', flag = 'watermark_y', suffix = '%', min = 0, max = 100, increment = .1, default = 1, value = 1});

    mainSection:AddToggle({text = 'Keybinds', flag = 'keybind_indicator', state = true, callback = function(bool)
        library.keyIndicator:SetEnabled(bool);
    end})
    mainSection:AddSlider({text = 'Position X', flag = 'keybind_indicator_x', min = 0, max = 100, increment = .1, default = 0.5, value = 0.5, callback = function()
        library.keyIndicator:SetPosition(newUDim2(library.flags.keybind_indicator_x / 100, 0, library.flags.keybind_indicator_y / 100, 0));    
    end});
    mainSection:AddSlider({text = 'Position Y', flag = 'keybind_indicator_y', min = 0, max = 100, increment = .1, default = 30, value = 30, callback = function()
        library.keyIndicator:SetPosition(newUDim2(library.flags.keybind_indicator_x / 100, 0, library.flags.keybind_indicator_y / 100, 0));    
    end});


    mainSection:AddToggle({text = 'Target Indicator', flag = 'target_indicator', state = false, callback = function(bool)
        library.targetIndicator:SetEnabled(bool);
    end})
    mainSection:AddSlider({text = 'Position X', flag = 'target_indicator_x', min = 0, max = 100, increment = .1, default = 0.5, value = 0.5, callback = function()
        library.targetIndicator:SetPosition(newUDim2(library.flags.target_indicator_x / 100, 0, library.flags.target_indicator_y / 100, 0));    
    end});
    mainSection:AddSlider({text = 'Position Y', flag = 'target_indicator_y', min = 0, max = 100, increment = .1, default = 30, value = 30, callback = function()
        library.targetIndicator:SetPosition(newUDim2(library.flags.target_indicator_x / 100, 0, library.flags.target_indicator_y / 100, 0));    
    end});





    local themeStrings = {"Custom"};
    for _,v in next, library.themes do
        table.insert(themeStrings, v.name)
    end
    local themeSection = settingsTab:AddSection('Custom Theme', 2);
    local setByPreset = false
themeSection:AddList({text = 'Presets', flag = 'preset_theme', values = themeStrings, default = 'Custom', callback = function(newTheme)
        if newTheme == "Custom" then return end
        setByPreset = true
        for _,v in next, library.themes do
            if v.name == newTheme then
                for x, d in pairs(library.options) do
                    if v.theme[tostring(x)] ~= nil then
                        d:SetColor(v.theme[tostring(x)])
                    end
                end
                library:SetTheme(v.theme)
                break
            end
        end
        setByPreset = false
    end}):Select('Default');

    for i, v in pairs(library.theme) do
        themeSection:AddColor({text = i, flag = i, color = library.theme[i], callback = function(c3)
            library.theme[i] = c3
            library:SetTheme(library.theme)
            if not setByPreset and not setByConfig then 
                library.options.preset_theme:Select('Custom')
            end
        end});
    end

    return settingsTab;
end

-- Create main window and expose CROW + tabs globally so tab scripts (AdminPanel, PlayerSec, etc.) can use them
-- NewWindow is defined inside library:init(), so init must run first
-- Use _G (loader's shared table) so all scripts see the same CROW/AdminTab/etc.; getgenv() can differ per script
local g = _G
local debugCROW = (getgenv and getgenv() or _G).CROW_DEBUG == true
local function dbg(msg) if debugCROW then warn("[CROW UiInnit Debug] " .. tostring(msg)) end end

local ok, err = pcall(function()
    dbg("Calling library:init() ...")
    library:init()
    dbg("init() OK. Showing safe mode (UiInnit window) ...")
    local safeModeResult = library:ShowSafeModeDialog()
    if _G then _G.CROW_SafeMode = safeModeResult end
    library:SetOpen(true)
    library.keyIndicator:SetEnabled(true)
    dbg("Safe mode answered. Calling NewWindow ...")
    local menu = library:NewWindow({title = library.cheatname or "CROW"})
    if type(menu) ~= "table" then
        error("NewWindow returned " .. type(menu) .. ", expected table")
    end
    dbg("NewWindow OK. Adding tabs ...")
    g.AdminTab = nil
    local admins = _G.Admins
    local isAdmin = type(admins) == "table" and localplayer and (table.find(admins, localplayer.UserId) ~= nil)
    _G.isAdmin = isAdmin
    if _G.userId == nil and localplayer then
        _G.userId = localplayer.UserId
    end
    g.PlayerTab = menu:AddTab('Player', 2)
    g.ESPTab = menu:AddTab('ESP', 3)
    g.Aimlock = menu:AddTab('Aimlock', 4)
    g.WorldTab = menu:AddTab('World', 5)
    if isAdmin then
        g.AdminTab = menu:AddTab('Admin', 6)
    end
    g.CROW = library
    if menu.targetName then library.targetName = menu.targetName end
    if menu.targetDisplay then library.targetDisplay = menu.targetDisplay end
    if menu.targetHealth then library.targetHealth = menu.targetHealth end
    if menu.targetDistance then library.targetDistance = menu.targetDistance end
    if menu.targetTool then library.targetTool = menu.targetTool end
    if menu.targetTarget then library.targetTarget = menu.targetTarget end
    dbg("Calling CreateSettingsTab ...")
    library:CreateSettingsTab(menu)
    dbg("Window setup OK. CROW, AdminTab, PlayerTab, etc. set on _G (shared).")
    -- Also set on getgenv() so tab scripts see them if executor ignores setfenv or uses different _G
    local real = (getgenv and getgenv() or _G)
    if real and real ~= g then
        real.CROW = g.CROW
        real.AdminTab = g.AdminTab or nil
        real.PlayerTab = g.PlayerTab
        real.ESPTab = g.ESPTab
        real.Aimlock = g.Aimlock
        real.WorldTab = g.WorldTab
        real.library = library
    end
end)

if not ok then
    warn("[CROW UiInnit] Window setup failed: " .. tostring(err))
    if debugCROW and type(err) == "string" then
        warn("[CROW UiInnit Debug] Full error: " .. err)
    end
end

g.library = library
return library
