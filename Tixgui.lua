--[[
   ████████╗██╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗ 
      ██╔══╝██║╚██╗██╔╝    ██║  ██║██║   ██║██╔══██╗
      ██║   ██║ ╚███╔╝     ███████║██║   ██║██████╔╝
      ██║   ██║ ██╔██╗     ██╔══██║██║   ██║██╔══██╗
      ██║   ██║██╔╝ ██╗    ██║  ██║╚██████╔╝██████╔╝
      ╚═╝   ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ 
   
   Hub functions by tixik|tks
   UI design based on Uhhhhhh Reanimate by STEVETHEREALONE
   Point at this source if you used a snippet here.
]]

if _G.TixHubLoaded then return end
_G.TixHubLoaded = true

local HubVersion = "1.0"

-- ── Compatibility shims ───────────────────────────────────────────────
cloneref = cloneref or function(o) return o end
if not getcustomasset then
    getcustomasset = (rawget(_G, "getsynasset") or function() return "" end)
end
if not gethiddengui then
    gethiddengui = (rawget(_G, "get_hidden_gui") or rawget(_G, "gethui") or function() return nil end)
end
pcall(restorefunction, restorefunction)
pcall(restorefunction, sethiddenproperty)
pcall(restorefunction, replicatesignal)

-- ── Services ──────────────────────────────────────────────────────────
local Debris          = cloneref(game:GetService("Debris"))
local CoreGui         = cloneref(game:GetService("CoreGui"))
local Players         = cloneref(game:GetService("Players"))
local RunService      = cloneref(game:GetService("RunService"))
local StarterGui      = cloneref(game:GetService("StarterGui"))
local HttpService     = cloneref(game:GetService("HttpService"))
local TextService     = cloneref(game:GetService("TextService"))
local TweenService    = cloneref(game:GetService("TweenService"))
local TeleportService = game:GetService("TeleportService")
local UIS             = cloneref(game:GetService("UserInputService"))

local Player = Players.LocalPlayer

-- ── Util ──────────────────────────────────────────────────────────────
local Util = {}

Util.RandomString = function(length)
    length = length or math.random(32, 64)
    local s = ""
    for _ = 1, length do s ..= string.char(math.random(65, 122)) end
    return s
end
Util.DeepcopyTable = function(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = (type(v) == "table") and Util.DeepcopyTable(v) or v
    end
    return c
end
Util.Notify = function(text)
    StarterGui:SetCore("SendNotification", {Title = "tix Hub", Text = text, Duration = 5})
end
Util.Instance = function(cl, p)
    local i = Instance.new(cl)
    i.Name = Util.RandomString()
    i.Parent = p
    return i
end
Util.LinkDestroyI2I = function(a, b) a.Destroying:Once(function() b:Destroy()     end) end
Util.LinkDestroyI2C = function(a, b) a.Destroying:Once(function() b:Disconnect()  end) end
Util.LoopedHSV = function(h, s, v)
    h %= 1; s = math.clamp(s, 0, 1); v = math.clamp(v, 0, 1)
    return Color3.fromHSV(h, s, v)
end
local _scrsiz = Vector2.new(512, 512)
local Camera  = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then Camera = workspace.CurrentCamera end
end)
Util.GetScreenSize = function()
    if Camera then _scrsiz = Camera.ViewportSize end
    return _scrsiz
end
Util.Vector2ToUDim2Scale  = function(x) return UDim2.fromScale(x.X, x.Y) end
Util.Vector2ToUDim2Offset = function(x) return UDim2.fromOffset(x.X, x.Y) end
Util.UDim2ToVector2Scale  = function(x) return Vector2.new(x.X.Scale, x.Y.Scale) end
Util.UDim2ToVector2Offset = function(x) return Vector2.new(x.X.Offset, x.Y.Offset) end
Util.IsGuiVisible = function(g)
    if not g or not g:IsA("GuiObject") then return false end
    while g do
        if not g.Visible then return false end
        g = g:FindFirstAncestorWhichIsA("GuiObject")
    end
    return true
end

-- ── Wait for game load ────────────────────────────────────────────────
if not game:IsLoaded() then
    local msg = Instance.new("Message")
    xpcall(function() msg.Parent = CoreGui end, function() msg.Parent = workspace end)
    msg.Text = "tix Hub: waiting for game to load..."
    game.Loaded:Wait()
    task.wait(2)
    msg:Destroy()
end

-- ── ScreenGui + UIMainFrame ───────────────────────────────────────────
local SCREENGUI = Util.Instance("ScreenGui")
SCREENGUI.IgnoreGuiInset       = true
SCREENGUI.ZIndexBehavior       = Enum.ZIndexBehavior.Sibling
SCREENGUI.ClipToDeviceSafeArea = false
SCREENGUI.ResetOnSpawn         = false
SCREENGUI.ScreenInsets         = Enum.ScreenInsets.None
SCREENGUI.DisplayOrder         = 2147483647
do
    local hg = gethiddengui()
    if hg then SCREENGUI.Parent = hg else SCREENGUI.Parent = CoreGui end
end

local UIMainFrame = Util.Instance("Frame", SCREENGUI)
UIMainFrame.AnchorPoint            = Vector2.new(0, 0)
UIMainFrame.Position               = UDim2.new(0, 0, 0, 0)
UIMainFrame.Size                   = UDim2.new(1, 0, 1, 0)
UIMainFrame.BackgroundColor3       = Color3.new(0, 0, 0)
UIMainFrame.BackgroundTransparency = 1
UIMainFrame.BorderSizePixel        = 0
UIMainFrame.ZIndex                 = 2147483647

-- ── SaveData ──────────────────────────────────────────────────────────
local SaveData = {}
local _hasSaveOps = (type(rawget(_G, "makefolder")) == "function"
    and type(rawget(_G, "readfile"))   == "function"
    and type(rawget(_G, "writefile"))  == "function"
    and type(rawget(_G, "isfile"))     == "function")

if _hasSaveOps then
    pcall(makefolder, "tixHub")
    pcall(makefolder, "tixHub/Assets")
    local fn = "tixHub/save.json"
    local s, d = pcall(readfile, fn)
    if s and d then
        s, d = pcall(HttpService.JSONDecode, HttpService, d)
        if s and d then SaveData = d end
    end
    task.spawn(function()
        local od = nil
        while true do
            task.wait(3)
            local s, d = pcall(HttpService.JSONEncode, HttpService, SaveData)
            if s and d ~= od then od = d; pcall(writefile, fn, d) end
        end
    end)
end

-- ── CDN Asset Download ────────────────────────────────────────────────
local _CDNAssets = {
    "letriangul.graphic.png",
    "lightinursoul.graphic.png",
    "dm_keygen18.ft2.mp3",
    "dm_afterburner.ft2.mp3",
    "dm_robotadventure.ft2.mp3",
    "dm_keygen22.ft2.mp3",
    "dm_keygen31.ft2.mp3",
    "fr_keygen31.ft2.mp3",
    "dm_change.ft2.mp3",
    "dm_haze.ft2.mp3",
    "dm_keygen3.ft2.mp3",
    "dm_keygen8.ft2.mp3",
    "dm_keygen19.ft2.mp3",
    "dm_keygen20.ft2.mp3",
    "dm_keygen21.ft2.mp3",
    "dm_keygen21alt.ft2.mp3",
    "dm_keygen23.ft2.mp3",
    "dm_keygen30.ft2.mp3",
    "dm_reztro4.ft2.mp3",
    "4m_brokenheart.ft2.mp3",
    "dm_laparade.ft2.mp3",
    "dm_iostesso.ft2.mp3",
}
local _assetDir = "tixHub/Assets/"
local _hasCDN   = _hasSaveOps and getcustomasset("") ~= nil

if _hasCDN then
    local missing = false
    for _, f in _CDNAssets do
        local s, d = pcall(isfile, _assetDir .. f)
        if not (s and d) then missing = true; break end
    end
    if missing then
        local DL = Util.Instance("TextLabel", UIMainFrame)
        DL.AnchorPoint          = Vector2.new(0.5, 0.5)
        DL.Position             = UDim2.new(0.5, 0, 0.5, 0)
        DL.Size                 = UDim2.new(1, 0, 0, 0)
        DL.BackgroundColor3     = Color3.new(0, 0, 0)
        DL.BackgroundTransparency = 0.2
        DL.ClipsDescendants     = true
        DL.BorderSizePixel      = 0
        DL.TextColor3           = Color3.new(1, 1, 1)
        DL.TextSize             = 20
        DL.Font                 = Enum.Font.Code
        DL.Text                 = "Fetching asset metadata..."
        TweenService:Create(DL, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 32)}):Play()
        task.wait(0.4)
        local ok, res = pcall(game.HttpGet, game,
            "https://api.github.com/repos/STEVE-916-create/Uhhhhhh/contents/uiassets/")
        if ok and res then
            ok, res = pcall(HttpService.JSONDecode, HttpService, res)
            if ok and res then
                local total, done, skip = 0, 0, 0
                for _, meta in res do
                    if table.find(_CDNAssets, meta.name) then
                        total += 1
                        task.spawn(function()
                            if not pcall(writefile, _assetDir..meta.name, game:HttpGet(meta.download_url)) then
                                skip += 1
                            end
                            done += 1
                        end)
                    end
                end
                repeat
                    DL.Text = ("Downloading assets %d/%d... (%d skipped)"):format(done, total, skip)
                    DL.BackgroundColor3 = Color3.new(0, 0, 0)
                    task.wait()
                until done == total
                DL.Text = "Download complete! \\(^o^)/"
                DL.BackgroundColor3 = Color3.new(0, 0.7, 0)
            else
                DL.Text = "Asset parse failed. 3:"
                DL.BackgroundColor3 = Color3.new(0.7, 0, 0)
            end
        else
            DL.Text = "Asset fetch failed. 3:"
            DL.BackgroundColor3 = Color3.new(0.7, 0, 0)
        end
        task.wait(0.8)
        TweenService:Create(DL, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.5)
        DL:Destroy()
    end
end

Util.GetCDNAsset = function(filename)
    if not _hasCDN then return "" end
    local path = _assetDir .. filename
    local s, d = pcall(isfile, path)
    if s and d then
        s, d = pcall(getcustomasset, path)
        if s then return d end
    end
    return ""
end

-- ── Pixel-font text renderer (from Uhhhhhh Reanimate) ─────────────────
Util.MakeText = function(text)
    text = text:upper()
    local ls = "BCDEIKOPQRSTUVYZ\\_`N^MJ"
    local lt = ""
    lt ..= "DDDDD@DFF@@@@@FSFSFSF@@@@@@@@@@@@@@EMMUKKTDD@@@@@DEEEEEDDBBBBBD@@@@@@@@@@@@@@@@@@@DE@@@G@@@@@@@@@DABBDEEI"
    lt ..= "GJJJJJGDVDDDDSGJAGIISRAAGAARWJJSAAASIIRAARGIIRJJGSAABBDDGJJGJJGGJJHAAG"
    lt ..= "@DD@DD@@DD@DE@@BDEDB@@@G@G@@@EDBDE@GJABD@D@@@@@@@"
    lt ..= "DFJSJJJRJJRJJRGJIIIJGRJJJJJRSIIRIISSIIRIIIHIILJJHJJJSJJJGDDDDDGAAAAAJHJKMOMKJIIIIIISJQNJJJJJJPNLJJGJJJJJGRJJRIIIGJJJNGCRJJRMKJGJIGAJGSDDDDDDJJJJJJGJJJJJFDJJJNQJJJJFDFJJJJFDDDDSABDEIS"
    local pixs, totalsize = {}, 0
    for i = 0, 6 do
        local row = {}
        for j = 1, text:len() do
            local c = text:byte(j, j)
            local w = 0
            if c ~= 0x20 then
                local k = (c - 33) * 7 + i
                w = lt:byte(k + 1, k + 1)
                if w ~= nil and w > 64 then
                    w = ls:byte(w - 64, w - 64) - 65
                else
                    w = 0
                end
            end
            for k = 0, 5 do
                local h = (j - 1) * 6 + (4 - k)
                totalsize = math.max(totalsize, h + 1)
                if (w // math.pow(2, k)) % 2 > 0 then row[h] = true end
            end
        end
        pixs[i] = row
    end
    local pivot = Util.Instance("Frame")
    pivot.AnchorPoint          = Vector2.new(0.5, 0.5)
    pivot.Position             = UDim2.new(0.5, 0, 0.5, 0)
    pivot.Size                 = UDim2.new(0, totalsize, 0, 7)
    pivot.BackgroundTransparency = 1
    pivot.BorderSizePixel      = 0
    for i = 0, 6 do
        local row  = pixs[i]
        local olde, olds = nil, 0
        for j = 0, totalsize - 1 do
            if row[j] == true then
                if olde then
                    olds += 1
                    olde.Size = UDim2.new(olds / totalsize, 0, 1 / 7, 0)
                else
                    olde = Util.Instance("Frame", pivot)
                    olde.AnchorPoint          = Vector2.new(0, 0)
                    olde.Position             = UDim2.new(j / totalsize, 0, i / 7, 0)
                    olde.Size                 = UDim2.new(1 / totalsize, 0, 1 / 7, 0)
                    olde.BackgroundTransparency = 1
                    olde.BorderSizePixel      = 0
                    olds = 1
                end
            else
                olde, olds = nil, 0
            end
        end
    end
    return pivot
end
Util.SetTextColor = function(textFrame, color, tran)
    for _, v in textFrame:GetChildren() do
        v.BackgroundColor3       = color
        v.BackgroundTransparency = tran
    end
end

-- ── Triforce renderer (from Uhhhhhh Reanimate) ────────────────────────
Util.MakeTriforce = function(tris, color, dur)
    dur = dur or 8
    local function CreateTriangle(parent, radius, width, rotation, col)
        local height = (math.sqrt(3) / 2) * width
        local pivot = Util.Instance("Frame", parent)
        pivot.AnchorPoint          = Vector2.new(0.5, 0.5)
        pivot.Position             = UDim2.new(0.5, 0, 0.5, 0)
        pivot.Size                 = UDim2.new(1, 0, 1, 0)
        pivot.BackgroundTransparency = 1
        pivot.BorderSizePixel      = 0
        pivot.Rotation             = rotation
        local tri = Util.Instance("ImageLabel", pivot)
        tri.AnchorPoint            = Vector2.new(0.5, 1)
        tri.Position               = UDim2.new(0.5, 0, 0.5 - radius, 0)
        tri.Size                   = UDim2.new(width, 0, height, 0)
        tri.BackgroundTransparency = 1
        tri.BorderSizePixel        = 0
        tri.Image                  = Util.GetCDNAsset("letriangul.graphic.png")
        local grey = math.max(col.R, col.G, col.B) * 0.5
        tri.ImageColor3 = Color3.new(grey, grey, grey)
        TweenService:Create(tri, TweenInfo.new(dur, Enum.EasingStyle.Linear), {ImageColor3 = col}):Play()
    end
    local radius = 0.1
    local pivot  = Util.Instance("Frame")
    pivot.AnchorPoint          = Vector2.new(0.5, 0.5)
    pivot.Position             = UDim2.new(0.5, 0, 0.5, 0)
    pivot.BackgroundTransparency = 1
    pivot.BorderSizePixel      = 0
    local width = 2 * radius * math.sin(math.pi / tris) * 2
    for i = 1, tris do
        CreateTriangle(pivot, radius, width, (i / tris) * 360, color)
    end
    return pivot
end

-- ── Music system ──────────────────────────────────────────────────────
local UISound = {}
UISound.Music = Util.Instance("Sound", UIMainFrame)
UISound.Music.Looped                = false
UISound.Music.PlaybackRegionsEnabled = false
UISound.Music.Volume                = 1
UISound.Music.PlaybackSpeed         = 1

UISound.Click = Util.Instance("Sound", UIMainFrame)
UISound.Click.SoundId       = "rbxassetid://6324790483"
UISound.Click.Volume        = 1
UISound.Click.PlaybackSpeed = 2

local MusicDB = {
    {"dm_keygen18.ft2.mp3",       "Dubmood - Keygen 18"},
    {"dm_afterburner.ft2.mp3",    "Dubmood - Afterburner"},
    {"dm_robotadventure.ft2.mp3", "Dubmood & Zabutom - Robot Adventure Remix"},
    {"4m_brokenheart.ft2.mp3",    "4-Mat - Broken Heart"},
    {"dm_change.ft2.mp3",         "Dubmood - Change"},
    {"dm_haze.ft2.mp3",           "Dubmood - Haze"},
    {"dm_keygen3.ft2.mp3",        "Dubmood - Keygen 3"},
    {"dm_keygen8.ft2.mp3",        "Dubmood - Keygen 8"},
    {"dm_keygen19.ft2.mp3",       "Dubmood - Keygen 19"},
    {"dm_keygen20.ft2.mp3",       "Dubmood - Keygen 20"},
    {"dm_keygen21.ft2.mp3",       "Dubmood - Keygen 21 (Installer Edit)"},
    {"dm_keygen21alt.ft2.mp3",    "Dubmood - Keygen 21"},
    {"dm_keygen22.ft2.mp3",       "Dubmood - Keygen 22"},
    {"dm_keygen23.ft2.mp3",       "Dubmood - Keygen 23"},
    {"dm_keygen30.ft2.mp3",       "Dubmood - Keygen 30"},
    {"dm_keygen31.ft2.mp3",       "Dubmood - Keygen 31"},
    {"fr_keygen31.ft2.mp3",       "Hoster's FR - Alternate Keygen 31"},
    {"dm_laparade.ft2.mp3",       "Dubmood & MBR - La Parade"},
    {"dm_reztro4.ft2.mp3",        "Dubmood - Rez Cracktro #4"},
    {"dm_iostesso.ft2.mp3",       "Dubmood - Io Stesso"},
}
local MusicPlayer = {Switching = false, LastMusic = nil}
MusicPlayer.Play = function(i)
    if MusicPlayer.Switching then return end
    MusicPlayer.Switching = true
    local last = MusicPlayer.LastMusic
    if not i then
        i = last
        while i == last do i = math.random(1, #MusicDB); task.wait() end
    end
    MusicPlayer.LastMusic = i
    local entry = MusicDB[i]
    UISound.Music.SoundId = Util.GetCDNAsset(entry[1])
    UISound.Music.Name    = entry[2]
    UISound.Music:Stop(); task.wait()
    UISound.Music.TimePosition = 0; task.wait()
    UISound.Music:Play(); task.wait()
    MusicPlayer.Switching = false
    if #UISound.Music.SoundId == 0 then MusicPlayer.Play() end
end
UISound.Music.Ended:Connect(function() MusicPlayer.Play() end)

-- ── Intro animation ───────────────────────────────────────────────────
SaveData.SkipIntro = not not SaveData.SkipIntro
if SaveData.SkipIntro then
    MusicPlayer.Play()
else
    UISound.Music.Volume = 0
    MusicPlayer.Play(1) -- Keygen 18 as intro
    repeat RunService.RenderStepped:Wait() until UISound.Music.IsLoaded
    UISound.Music:Stop(); task.wait()
    UISound.Music:Play()
    UISound.Music.Volume = 1
    UISound.Music.TimePosition = 0

    local scrolltexts = {
        "tixik presents: tix hub                                          ",
        "uhhhhhh design by stevetherealone                                ",
        "hi guys welcome to my game                                        ",
        "noclip speed fly esp and more                                     ",
        ":3 :3 :3 :3 :3 :3 :3 :3 :3 :3 :3 :3 :3 :3 :3 >:3 :3 :3 :3 :3  ",
        "meeeooowwwwwwwwww >:3                                          maw",
        "wwwwwwwwwwwwwwwwwww                         grass                 ",
        "all UI music credits to dubmood, 4mat and zabutom                 ",
        "fflags are dead lol                                               ",
        "          trust me the ui looks good             here it comes    ",
        "who the fuck even reads this??                     hi guys        ",
        "dying is scary, but living is difficult                           ",
        "even if I mope, nothing good will happen! gotta keep going!       ",
        "heres the triforce                  and heres the hub             ",
    }
    local scrolltext_str = scrolltexts[math.random(1, #scrolltexts)]

    local fade = TweenService:Create(UIMainFrame, TweenInfo.new(5), {BackgroundTransparency = 0.5})
    fade:Play()
    local scrolltext = Util.MakeText(scrolltext_str)
    scrolltext.Parent      = UIMainFrame
    scrolltext.ZIndex      = 0
    scrolltext.AnchorPoint = Vector2.new(0, 0.5)
    scrolltext.Position    = UDim2.new(1.5, 0, 0.5, 0)
    Util.SetTextColor(scrolltext, Color3.new(1,1,1), 0.6)
    TweenService:Create(scrolltext, TweenInfo.new(5.256, Enum.EasingStyle.Linear), {
        Position   = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
    }):Play()
    local scrolltextratio = scrolltext.Size.X.Offset / math.max(scrolltext.Size.Y.Offset, 1)

    local Triforce1 = Util.MakeTriforce(3, Color3.new(1, 0.7, 0), 4)
    local Triforce2 = Util.MakeTriforce(3, Color3.new(0.8, 0.4, 0), 4)
    Triforce1.ZIndex = 2; Triforce2.ZIndex = 1
    Triforce1.Parent = UIMainFrame; Triforce2.Parent = UIMainFrame

    local TRI_offset = 0.01
    local TRI_height = 0.5
    local TRI_rot    = 0
    local TRI_rotvel = 720
    local TRI_scale  = 0

    local hubLabel = Util.Instance("TextLabel", UIMainFrame)
    hubLabel.TextScaled           = true
    hubLabel.Font                 = Enum.Font.Arcade
    hubLabel.TextColor3           = Color3.new(1, 1, 1)
    hubLabel.BackgroundColor3     = Color3.new(0, 0, 0)
    hubLabel.BackgroundTransparency = 0
    hubLabel.BorderColor3         = Color3.new(1, 1, 1)
    hubLabel.BorderSizePixel      = 8
    hubLabel.AnchorPoint          = Vector2.new(0.5, 0.5)
    hubLabel.Position             = UDim2.new(0.5, 0, 0.5, 0)
    hubLabel.Size                 = UDim2.fromOffset(0, 0)
    hubLabel.Visible              = false
    hubLabel.ZIndex               = 3
    hubLabel.Text                 = "TIX\nHUB"
    local lp = Util.Instance("UIPadding", hubLabel)
    lp.PaddingLeft   = UDim.new(0, 10); lp.PaddingRight  = UDim.new(0, 10)
    lp.PaddingTop    = UDim.new(0, 10); lp.PaddingBottom = UDim.new(0, 10)

    while true do
        local dt = RunService.Heartbeat:Wait()
        local t  = UISound.Music.TimePosition
        if t >= 5.256 then break end
        local screensize = Util.GetScreenSize()
        local ysize = screensize.Y
        local height = ysize / 3
        scrolltext.Size = UDim2.fromOffset(height * scrolltextratio * 0.5, height)
        TRI_rot    = (TRI_rot + TRI_rotvel * dt) % 360
        TRI_rotvel = TRI_rotvel * math.exp(-0.25 * dt)
        Triforce1.Size = UDim2.fromOffset(TRI_scale * ysize * 0.8, TRI_scale * ysize * 0.8)
        if t >= 4.256 then
            local a = t - 4.256
            Triforce1.Size = Triforce1.Size:Lerp(UDim2.fromOffset(160, 160), a)
            TRI_height = 0.5 + (15 / ysize) * a
        end
        Triforce2.Size     = Triforce1.Size
        Triforce1.Position = UDim2.new(0.5, ysize * -TRI_offset, TRI_height, ysize * -TRI_offset)
        Triforce2.Position = UDim2.new(0.5, 0, TRI_height, 0)
        Triforce1.Rotation = TRI_rot
        Triforce2.Rotation = TRI_rot
        if t < 4.256 then
            TRI_scale = 1 - ((1 - math.min(1, t / 3)) ^ 2)
        else
            local a = t - 4.256
            TRI_scale = 1 + a * 13
            if a > 0.5 then Triforce1.ZIndex = 5; Triforce2.ZIndex = 4
            else             Triforce1.ZIndex = 2; Triforce2.ZIndex = 1 end
        end
        if t < 2.152 then
            hubLabel.Visible = false
        elseif t < 2.652 then
            local a = (t - 2.152) / 0.5
            local z = 20 * ((a * 100) // 20)
            hubLabel.Visible = true; hubLabel.Size = UDim2.fromOffset(z, z)
        elseif t < 4.756 then
            hubLabel.Visible = true; hubLabel.Size = UDim2.fromOffset(100, 100)
        else
            local a = (t - 4.756) / 0.5
            local x = 20 * ((a * 260 + 100) // 20)
            local y = 20 * ((math.min(1, a / 0.538) * 140 + 100) // 20)
            hubLabel.Visible = true; hubLabel.Size = UDim2.fromOffset(x, y)
        end
    end
    hubLabel:Destroy(); Triforce1:Destroy(); Triforce2:Destroy(); scrolltext:Destroy()
    fade:Cancel()
    UIMainFrame.BackgroundTransparency = 1
    local flash = Util.Instance("Frame", UIMainFrame)
    flash.Size                 = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3     = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel      = 0
    flash.Interactable         = false
    flash.ZIndex               = 256
    TweenService:Create(flash, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    Debris:AddItem(flash, 1)
end

SaveData.MuteUIMusic = not not SaveData.MuteUIMusic
if SaveData.MuteUIMusic then
    TweenService:Create(UISound.Music, TweenInfo.new(3, Enum.EasingStyle.Linear), {Volume = 0}):Play()
end

-- ── Theme / Stylize system ────────────────────────────────────────────
local StylizedObjs = {}
local ForceUIColor   = nil
local ForceUIBGColor = nil

local function Stylize(obj, options)
    options = options or {}
    Util.Instance("UICorner", obj).CornerRadius = UDim.new(0, 5)
    local Out = Util.Instance("UIStroke", obj)
    Out.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Out.Color           = Color3.new(1, 1, 1)
    Out.LineJoinMode    = Enum.LineJoinMode.Round
    Out.Thickness       = 1
    Out.Transparency    = 0
    Out.Enabled         = true
    obj.BackgroundColor3 = Color3.new(0, 0, 0)
    local Glos = {}
    if options.Glow == true then
        local GloF = Util.Instance("Frame", UIMainFrame)
        Util.LinkDestroyI2I(obj, GloF)
        GloF.Interactable         = false
        GloF.BackgroundTransparency = 1
        local function updateGlo()
            GloF.AnchorPoint = obj.AnchorPoint
            GloF.Position    = obj.Position
            GloF.Size        = obj.Size
            GloF.Visible     = obj.Visible
            GloF.ZIndex      = obj.ZIndex - 2
        end
        updateGlo()
        obj.Changed:Connect(updateGlo)
        local tex = Util.GetCDNAsset("lightinursoul.graphic.png")
        for x = 0, 2 do for y = 0, 2 do
            local Glo = Util.Instance("ImageLabel", GloF)
            Glo.AnchorPoint    = Vector2.new(1 - math.min(x,1), 1 - math.min(y,1))
            Glo.Position       = UDim2.fromScale(math.max(x-1,0), math.max(y-1,0))
            Glo.Size           = UDim2.new(1-math.abs(x-1), x==1 and 0 or 32, 1-math.abs(y-1), y==1 and 0 or 32)
            Glo.BackgroundTransparency = 1
            Glo.Image          = tex
            Glo.ImageRectOffset = Vector2.new(math.min(x,1)*256, math.min(y,1)*256)
            Glo.ImageRectSize  = Vector2.new(x==1 and 0 or 256, y==1 and 0 or 256)
            table.insert(Glos, Glo)
        end end
    end
    table.insert(StylizedObjs, {obj=obj, Out=Out, Glos=Glos, options=options})
end

local function GetUIColor(t)
    if ForceUIColor then
        local si = math.sin(math.pi * 2 * t / 10)
        local h, s, v = ForceUIColor:ToHSV()
        if s < 0.2 then v = v * (0.8 + si * 0.2)
        else h = h + si * 0.01 end
        return Util.LoopedHSV(h, s, v)
    end
    return Util.LoopedHSV(t / 10, 0.8, 1)
end
local function GetUIBGColor(t)
    if ForceUIBGColor then
        local h, s, v = ForceUIBGColor:ToHSV()
        return Util.LoopedHSV(h, s, v)
    end
    return Color3.new(0, 0, 0)
end

local UITextColor = Util.Instance("Color3Value")
UITextColor.Value = Color3.new(1, 1, 1)
local function RegisterTextLabel(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        obj.TextColor3 = UITextColor.Value
        Util.LinkDestroyI2C(obj, UITextColor.Changed:Connect(function(v) obj.TextColor3 = v end))
    end
    if obj:IsA("TextBox") then
        local h, s, v = UITextColor.Value:ToHSV()
        obj.TextColor3       = UITextColor.Value
        obj.PlaceholderColor3 = Color3.fromHSV(h, s, 0.5 + (v-0.5)*0.4)
        Util.LinkDestroyI2C(obj, UITextColor.Changed:Connect(function(val)
            h, s, v = val:ToHSV()
            obj.TextColor3        = val
            obj.PlaceholderColor3 = Color3.fromHSV(h, s, 0.5 + (v-0.5)*0.4)
        end))
    end
end
local function UpdateGrads(t)
    local c   = GetUIColor(t)
    local bgc = GetUIBGColor(t)
    for _, grad in StylizedObjs do
        local obj, Out, Glos, options = grad.obj, grad.Out, grad.Glos, grad.options
        Out.Color = c
        obj.BackgroundColor3 = options.Depthed and bgc:Lerp(Color3.new(0,0,0), 0.1) or bgc
        for _, gl in Glos do gl.ImageColor3 = c end
    end
end

-- ── UIMainWindow ──────────────────────────────────────────────────────
local UIMainWindow, WindowContent
do
    UIMainWindow = Util.Instance("Frame", UIMainFrame)
    UIMainWindow.Active           = true
    UIMainWindow.AnchorPoint      = Vector2.new(0.5, 0.5)
    UIMainWindow.Position         = UDim2.new(0.5, 0, 0.5, 0)
    UIMainWindow.Size             = UDim2.new(0, 360, 0, 240)
    UIMainWindow.BackgroundColor3 = Color3.new(0, 0, 0)
    UIMainWindow.BorderSizePixel  = 0
    Stylize(UIMainWindow, {Glow = true})

    -- Click sound registration
    local _clickSndActive = false
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            _clickSndActive = false
        end
    end)
    local function regClickSnd(v)
        if v:GetAttribute("CS") then return end
        v:SetAttribute("CS", true)
        v.InputBegan:Connect(function(inp)
            if _clickSndActive then return end
            if inp.UserInputState ~= Enum.UserInputState.Begin then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                UISound.Click:Play(); _clickSndActive = true
            end
        end)
    end
    regClickSnd(UIMainWindow)
    UIMainWindow.DescendantAdded:Connect(function(v)
        if v:IsA("GuiObject") then regClickSnd(v) end
    end)

    -- TopBar
    local TopBarFrame = Util.Instance("Frame", UIMainWindow)
    TopBarFrame.Position            = UDim2.new(0, 0, 0, 0)
    TopBarFrame.Size                = UDim2.new(1, 0, 0, 30)
    TopBarFrame.BackgroundColor3    = Color3.new(0, 0, 0)
    TopBarFrame.BorderSizePixel     = 0
    TopBarFrame.ClipsDescendants    = true
    TopBarFrame.ZIndex              = 1
    Stylize(TopBarFrame)

    local TopBarText = Util.Instance("TextLabel", TopBarFrame)
    TopBarText.AnchorPoint         = Vector2.new(0, 0.5)
    TopBarText.Position            = UDim2.new(0, 8, 0.5, 0)
    TopBarText.Size                = UDim2.new(1, -40, 1, 0)
    TopBarText.BackgroundTransparency = 1
    TopBarText.Font                = Enum.Font.Code
    TopBarText.TextSize            = 18
    TopBarText.TextXAlignment      = Enum.TextXAlignment.Left
    TopBarText.RichText            = true
    TopBarText.Text                = "tix Hub v" .. HubVersion .. "  |  by tixik"
    RegisterTextLabel(TopBarText)

    -- Minimise button
    local TopBarClose = Util.Instance("TextButton", TopBarFrame)
    TopBarClose.AnchorPoint        = Vector2.new(1, 0)
    TopBarClose.Position           = UDim2.new(1, 0, 0, 0)
    TopBarClose.Size               = UDim2.new(0, 30, 1, 0)
    TopBarClose.BackgroundTransparency = 1
    TopBarClose.Text               = ""
    do
        local A = Util.Instance("Frame", TopBarClose)
        A.Name = "A"
        A.AnchorPoint          = Vector2.new(0.5, 0.5)
        A.Position             = UDim2.new(0.5, 0, 0.5, 0)
        A.Size                 = UDim2.new(0, 16, 0, 2)
        A.BackgroundColor3     = Color3.new(1, 1, 1)
        A.BorderSizePixel      = 0
        local B = Util.Instance("Frame", A)
        B.Name = "B"
        B.AnchorPoint          = Vector2.new(0.5, 0.5)
        B.Position             = UDim2.new(0.5, 0, 0.5, 0)
        B.Size                 = UDim2.new(0, 2, 0, 0)
        B.BackgroundColor3     = Color3.new(1, 1, 1)
        B.BorderSizePixel      = 0
        UITextColor.Changed:Connect(function(v)
            A.BackgroundColor3 = v; B.BackgroundColor3 = v
        end)
    end

    -- WindowContent
    WindowContent = Util.Instance("Frame", UIMainWindow)
    WindowContent.Position             = UDim2.new(0, 0, 0, 30)
    WindowContent.Size                 = UDim2.new(1, 0, 1, -30)
    WindowContent.BackgroundTransparency = 1
    WindowContent.ClipsDescendants     = true
    WindowContent.ZIndex               = 0

    -- Minimise logic
    local Closed = false; local Tweening = false
    local PosOpen = UIMainWindow.Position
    local PosClose = SaveData.WindowClosedPosition and UDim2.new(unpack(SaveData.WindowClosedPosition)) or UDim2.new(0.5,0,0.5,0)
    TopBarClose.Activated:Connect(function()
        if Tweening then return end
        Tweening = true
        Closed   = not Closed
        if Closed then
            PosOpen = UIMainWindow.Position
            TweenService:Create(UIMainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                Position = PosClose, Size = UDim2.fromOffset(160, 30)
            }):Play()
            TweenService:Create(TopBarClose.A, TweenInfo.new(0.4), {Rotation = 180}):Play()
            TweenService:Create(TopBarClose.A.B, TweenInfo.new(0.4), {Size = UDim2.new(0,2,0,16)}):Play()
            task.delay(0.5, function() WindowContent.Visible = false; Tweening = false end)
        else
            WindowContent.Visible = true
            PosClose = UIMainWindow.Position
            SaveData.WindowClosedPosition = {PosClose.X.Scale, PosClose.X.Offset, PosClose.Y.Scale, PosClose.Y.Offset}
            TweenService:Create(UIMainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                Position = PosOpen, Size = UDim2.fromOffset(360, 240)
            }):Play()
            TweenService:Create(TopBarClose.A, TweenInfo.new(0.4), {Rotation = 0}):Play()
            TweenService:Create(TopBarClose.A.B, TweenInfo.new(0.4), {Size = UDim2.new(0,2,0,0)}):Play()
            task.delay(0.5, function() Tweening = false end)
        end
        WindowContent.Active       = not Closed
        WindowContent.Interactable = not Closed
    end)

    -- Drag
    local dragRef, dragOffset = nil, Vector2.zero
    TopBarFrame.InputBegan:Connect(function(inp)
        if dragRef then return end
        if inp.UserInputState ~= Enum.UserInputState.Begin then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            WindowContent.Interactable = false
            local screen = Util.GetScreenSize()
            local ch = Vector2.new(inp.Position.X, inp.Position.Y) / screen
            dragOffset = Util.UDim2ToVector2Scale(UIMainWindow.Position) - ch
            dragRef = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragRef then
            if inp.UserInputType == Enum.UserInputType.MouseMovement
            or (inp.UserInputType == Enum.UserInputType.Touch and dragRef == inp) then
                local screen = Util.GetScreenSize()
                UIMainWindow.Position = Util.Vector2ToUDim2Scale(
                    Vector2.new(inp.Position.X, inp.Position.Y) / screen + dragOffset)
            end
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if dragRef == inp then
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                WindowContent.Interactable = true; dragRef = nil
            end
        end
    end)
end

-- ── Render step ───────────────────────────────────────────────────────
local _renderFuncs = {}
local function AddRender(fn, linkto)
    table.insert(_renderFuncs, fn)
    if linkto then
        linkto.Destroying:Connect(function()
            local i = table.find(_renderFuncs, fn)
            if i then table.remove(_renderFuncs, i) end
        end)
    end
    return fn
end
local _totalTime = 0
RunService:BindToRenderStep("TixHub_" .. Util.RandomString(8), Enum.RenderPriority.Last.Value - 1, function(dt)
    _totalTime += dt
    UpdateGrads(_totalTime)
    WindowContent.Visible = UIMainWindow.Size.Y.Offset > 35
    for _, fn in _renderFuncs do
        local ok, err = pcall(fn, _totalTime, dt)
        if not ok then warn("[tixHub render] " .. tostring(err)) end
    end
end)

-- ── UI component factories ────────────────────────────────────────────
local UI = {}

function UI.CreatePage(parent)
    parent = parent or WindowContent
    local Frame = Util.Instance("ScrollingFrame", parent)
    Frame.AnchorPoint           = Vector2.new(0.5, 0)
    Frame.Position              = UDim2.new(0.5, 0, 0, 0)
    Frame.Size                  = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3      = Color3.new(0, 0, 0)
    Frame.BorderSizePixel       = 0
    Frame.Visible               = false
    Frame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    Frame.CanvasSize            = UDim2.new(0, 0, 0, 0)
    Frame.ScrollingDirection    = Enum.ScrollingDirection.Y
    Frame.ScrollBarThickness    = 2
    Frame.ScrollBarImageColor3  = Color3.new(0.4, 0.4, 0.4)
    Frame.ClipsDescendants      = true
    Frame.ZIndex                = 0
    AddRender(function(t)
        Frame.BackgroundColor3 = GetUIBGColor(t)
    end, Frame)
    local Pad = Util.Instance("UIPadding", Frame)
    Pad.PaddingTop = UDim.new(0, 4); Pad.PaddingBottom = UDim.new(0, 4)
    local UIList = Util.Instance("UIListLayout", Frame)
    UIList.FillDirection        = Enum.FillDirection.Vertical
    UIList.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    UIList.VerticalAlignment    = Enum.VerticalAlignment.Top
    UIList.Padding              = UDim.new(0, 0)
    UIList.SortOrder            = Enum.SortOrder.LayoutOrder
    return Frame
end

function UI.CreateText(parent, text, size, align)
    size  = size  or 18
    align = align or Enum.TextXAlignment.Left
    local margin = 5
    local Container = Util.Instance("Frame", parent)
    Container.AnchorPoint          = Vector2.new(0.5, 0)
    Container.Size                 = UDim2.new(1, 0, 0, 24)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder          = #parent:GetChildren()
    local Text = Util.Instance("TextLabel", Container)
    Text.Position           = UDim2.new(0, margin, 0, 0)
    Text.Size               = UDim2.new(1, -margin*2, 1, -margin)
    Text.BackgroundTransparency = 1
    Text.RichText           = true
    Text.Font               = Enum.Font.Code
    Text.TextXAlignment     = align
    Text.TextYAlignment     = Enum.TextYAlignment.Top
    Text.TextWrapped        = true
    Text.TextSize           = size
    Text.Text               = text
    RegisterTextLabel(Text)
    local function update()
        local x = parent.AbsoluteSize.X
        local s = TextService:GetTextSize(Text.ContentText, Text.TextSize, Text.Font, Vector2.new(x - margin*2, math.huge))
        Container.Size = UDim2.new(1, 0, 0, s.Y + margin)
    end
    update(); Text.Changed:Connect(update)
    return Text
end

function UI.CreateSeparator(parent)
    local Container = Util.Instance("Frame", parent)
    Container.AnchorPoint          = Vector2.new(0.5, 0)
    Container.Size                 = UDim2.new(1, 0, 0, 7)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder          = #parent:GetChildren()
    local Sep = Util.Instance("Frame", Container)
    Sep.AnchorPoint        = Vector2.new(0.5, 0.5)
    Sep.Position           = UDim2.new(0.5, 0, 0.5, 0)
    Sep.Size               = UDim2.new(1, -8, 0, 1)
    Sep.BackgroundColor3   = UITextColor.Value
    Sep.BackgroundTransparency = 0.7
    Sep.BorderSizePixel    = 0
    Util.LinkDestroyI2C(Sep, UITextColor.Changed:Connect(function(v) Sep.BackgroundColor3 = v end))
end

function UI.CreateButton(parent, text, size)
    size = size or 18
    local margin = 5
    local Container = Util.Instance("Frame", parent)
    Container.AnchorPoint          = Vector2.new(0.5, 0)
    Container.Size                 = UDim2.new(1, 0, 0, 32)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder          = #parent:GetChildren()
    local Button = Util.Instance("TextButton", Container)
    Button.Position          = UDim2.new(0, margin, 0, margin//2)
    Button.Size              = UDim2.new(1, -margin*2, 1, -margin)
    Button.BackgroundColor3  = Color3.new(0, 0, 0)
    Button.BorderSizePixel   = 0
    Button.Text              = ""
    Button.AutoButtonColor   = true
    local BText = Util.Instance("TextLabel", Button)
    BText.AnchorPoint           = Vector2.new(0.5, 0.5)
    BText.Position              = UDim2.new(0.5, 0, 0.5, 0)
    BText.Size                  = UDim2.new(1, 0, 1, -margin)
    BText.BackgroundTransparency = 1
    BText.RichText              = true
    BText.Font                  = Enum.Font.Code
    BText.TextXAlignment        = Enum.TextXAlignment.Center
    BText.TextWrapped           = true
    BText.TextSize              = size
    BText.Text                  = text
    RegisterTextLabel(BText)
    Stylize(Button)
    local function update()
        local x = parent.AbsoluteSize.X
        local s = TextService:GetTextSize(BText.ContentText, BText.TextSize, BText.Font, Vector2.new(x - margin*2, math.huge))
        Container.Size = UDim2.new(1, 0, 0, s.Y + margin*2)
    end
    update(); BText.Changed:Connect(update)
    return Button, BText
end

function UI.CreateSwitch(parent, text, value)
    local margin = 5; local sw = 28
    local Container = Util.Instance("Frame", parent)
    Container.AnchorPoint          = Vector2.new(0.5, 0)
    Container.Size                 = UDim2.new(1, 0, 0, 35)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder          = #parent:GetChildren()
    local Btn = Util.Instance("TextButton", Container)
    Btn.Size                 = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text                 = ""
    local BText = Util.Instance("TextLabel", Btn)
    BText.Position           = UDim2.new(0, margin, 0, 0)
    BText.Size               = UDim2.new(1, -margin*3 - sw, 1, 0)
    BText.BackgroundTransparency = 1
    BText.RichText           = true
    BText.Font               = Enum.Font.Code
    BText.TextXAlignment     = Enum.TextXAlignment.Left
    BText.TextYAlignment     = Enum.TextYAlignment.Center
    BText.TextWrapped        = true
    BText.TextSize           = 18
    BText.Text               = text
    RegisterTextLabel(BText)
    local function update()
        local x  = parent.AbsoluteSize.X
        local s  = TextService:GetTextSize(BText.ContentText, BText.TextSize, BText.Font, Vector2.new(x - margin*3 - sw, math.huge))
        Container.Size = UDim2.new(1, 0, 0, math.max(35, s.Y))
    end
    update(); BText.Changed:Connect(update)
    local Switch = Util.Instance("Frame", Container)
    Switch.AnchorPoint       = Vector2.new(1, 0.5)
    Switch.Position          = UDim2.new(1, -margin, 0.5, 0)
    Switch.Size              = UDim2.new(0, sw, 0, sw)
    Switch.BackgroundColor3  = Color3.new(0, 0, 0)
    Switch.BorderSizePixel   = 0
    Util.Instance("UICorner", Switch).CornerRadius = UDim.new(0, 5)
    Stylize(Switch)
    local Dot = Util.Instance("Frame", Switch)
    Dot.AnchorPoint          = Vector2.new(0.5, 0.5)
    Dot.Position             = UDim2.new(0.5, 0, 0.5, 0)
    Dot.Size                 = UDim2.new(0, sw-8, 0, sw-8)
    Dot.BackgroundTransparency = 0.2
    Dot.BackgroundColor3     = UITextColor.Value
    Dot.BorderSizePixel      = 0
    Util.Instance("UICorner", Dot).CornerRadius = UDim.new(0, 3)
    Util.LinkDestroyI2C(Dot, UITextColor.Changed:Connect(function(v) Dot.BackgroundColor3 = v end))
    local Lever = Util.Instance("BoolValue")
    Lever.Value = value
    local function updateDot() Dot.Visible = Lever.Value end
    Lever.Changed:Connect(updateDot); updateDot()
    Btn.Activated:Connect(function() Lever.Value = not Lever.Value end)
    return Lever, BText
end

function UI.CreateSlider(parent, text, value, min, max, step)
    min = min or 0; max = max or 100; step = math.abs(step or 0)
    local margin = 5
    local Container = Util.Instance("Frame", parent)
    Container.AnchorPoint          = Vector2.new(0.5, 0)
    Container.Size                 = UDim2.new(1, 0, 0, 60)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder          = #parent:GetChildren()
    local Label = Util.Instance("TextLabel", Container)
    Label.Position           = UDim2.new(0, margin, 0, 0)
    Label.Size               = UDim2.new(1, -margin*2, 0, 32)
    Label.BackgroundTransparency = 1
    Label.RichText           = true
    Label.Font               = Enum.Font.Code
    Label.TextXAlignment     = Enum.TextXAlignment.Left
    Label.TextYAlignment     = Enum.TextYAlignment.Center
    Label.TextSize           = 18
    Label.Text               = text
    RegisterTextLabel(Label)
    local ValBox = Util.Instance("Frame", Container)
    ValBox.AnchorPoint       = Vector2.new(1, 0)
    ValBox.Position          = UDim2.new(1, -margin, 0, margin)
    ValBox.Size              = UDim2.new(0, 72, 0, 22)
    ValBox.BackgroundColor3  = Color3.new(0, 0, 0)
    ValBox.BorderSizePixel   = 0
    local ValText = Util.Instance("TextBox", ValBox)
    ValText.AnchorPoint          = Vector2.new(0.5, 0.5)
    ValText.Position             = UDim2.new(0.5, 0, 0.5, 0)
    ValText.Size                 = UDim2.new(1, 0, 1, -margin)
    ValText.BackgroundTransparency = 1
    ValText.Font                 = Enum.Font.Code
    ValText.TextXAlignment       = Enum.TextXAlignment.Center
    ValText.TextSize             = 14
    ValText.ClearTextOnFocus     = false
    RegisterTextLabel(ValText)
    ValText.Focused:Connect(function() UISound.Click:Play() end)
    Stylize(ValBox, {Depthed = true})
    local SliderC = Util.Instance("TextButton", Container)
    SliderC.Position         = UDim2.new(0, 0, 0, 36)
    SliderC.Size             = UDim2.new(1, 0, 0, 20)
    SliderC.BackgroundTransparency = 1
    SliderC.Text             = ""
    local Track = Util.Instance("Frame", SliderC)
    Track.AnchorPoint        = Vector2.new(0.5, 0.5)
    Track.Position           = UDim2.new(0.5, 0, 0.5, 0)
    Track.Size               = UDim2.new(1, -margin*2-20, 0, 4)
    Track.BackgroundColor3   = Color3.new(1, 1, 1)
    Track.BorderSizePixel    = 0
    Stylize(Track, {Depthed = true})
    local Knob = Util.Instance("Frame", Track)
    Knob.AnchorPoint         = Vector2.new(0.5, 0.5)
    Knob.Position            = UDim2.new(0, 0, 0.5, 0)
    Knob.Size                = UDim2.new(0, 16, 0, 16)
    Knob.BackgroundColor3    = Color3.new(1, 1, 1)
    Knob.BorderSizePixel     = 0
    Knob.ZIndex              = 2
    Stylize(Knob)
    local Select = Util.Instance("NumberValue")
    local range  = max - min
    local function updateSlider()
        local v   = Select.Value
        local str = ("%.3f"):format(v)
        if str:find("%.") then
            while str:sub(-1) == "0" do str = str:sub(1,-2) end
            if str:sub(-1) == "."  then str = str:sub(1,-2) end
        end
        ValText.Text  = str
        Knob.Position = UDim2.new(math.clamp((v - min) / range, 0, 1), 0, 0.5, 0)
    end
    Select.Value = value; Select.Changed:Connect(updateSlider); updateSlider()
    ValText.FocusLost:Connect(function()
        Select.Value = math.clamp(tonumber(ValText.Text) or Select.Value, min, max)
        updateSlider()
    end)
    local function ondrag(x)
        local v = range * math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        if step > 0 then v = math.round(v / step) * step end
        Select.Value = math.clamp(v + min, min, max)
    end
    local dragRef, startPos = nil, nil
    SliderC.InputBegan:Connect(function(inp)
        if inp.UserInputState ~= Enum.UserInputState.Begin then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragRef = inp; startPos = inp.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragRef then
            if inp.UserInputType == Enum.UserInputType.MouseMovement
            or (inp.UserInputType == Enum.UserInputType.Touch and dragRef == inp) then
                if startPos then
                    local d = inp.Position - startPos
                    if d.Magnitude > 10 then
                        startPos = nil
                        if math.abs(d.X) < math.abs(d.Y) then dragRef = nil end
                    end
                else
                    ondrag(inp.Position.X)
                end
            end
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if dragRef == inp then
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                ondrag(inp.Position.X); dragRef = nil
            end
        end
    end)
    return Select
end

-- ── CracktroFrame (homepage) ──────────────────────────────────────────
local CracktroFrame = Util.Instance("Frame", WindowContent)
CracktroFrame.Active            = true
CracktroFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
CracktroFrame.Position          = UDim2.new(0.5, 0, 0.5, 0)
CracktroFrame.Size              = UDim2.new(1, 0, 1, 0)
CracktroFrame.BackgroundColor3  = Color3.new(0, 0, 0)
CracktroFrame.BorderSizePixel   = 1
CracktroFrame.BorderColor3      = Color3.new(1, 1, 1)
CracktroFrame.ZIndex            = 10
CracktroFrame.ClipsDescendants  = true
AddRender(function(t)
    CracktroFrame.BorderColor3    = GetUIColor(t)
    CracktroFrame.BackgroundColor3 = GetUIBGColor(t)
end, CracktroFrame)

do -- homepage content
    local Triforce = Util.MakeTriforce(3, Color3.new(1, 0.7, 0), 0)
    Triforce.AnchorPoint = Vector2.new(0.5, 0.5)
    Triforce.Position    = UDim2.new(0.5, 0, 0.4, 0)
    Triforce.Size        = UDim2.new(0, 100, 0, 100)
    Triforce.Parent      = CracktroFrame
    local trivel = 90

    local txtTitle = Util.MakeText("tix Hub v" .. HubVersion)
    txtTitle.AnchorPoint = Vector2.new(0.5, 1)
    txtTitle.Position    = UDim2.new(0.5, 0, 1, -30)
    txtTitle.ZIndex      = 3
    txtTitle.Parent      = CracktroFrame
    Util.SetTextColor(txtTitle, UITextColor.Value, 0)

    local txtSub = Util.MakeText("Click to open hub")
    txtSub.AnchorPoint = Vector2.new(0.5, 1)
    txtSub.Position    = UDim2.new(0.5, 0, 1, -18)
    txtSub.ZIndex      = 3
    txtSub.Parent      = CracktroFrame
    Util.SetTextColor(txtSub, UITextColor.Value, 0)

    UITextColor.Changed:Connect(function(v)
        Util.SetTextColor(txtTitle, v, 0)
        Util.SetTextColor(txtSub,   v, 0)
    end)

    AddRender(function(t, dt)
        if Util.IsGuiVisible(CracktroFrame) then
            local pbl = UISound.Music.PlaybackLoudness
            trivel = pbl * 1.5 * dt + trivel * math.exp(-6 * dt)
            Triforce.Rotation = (Triforce.Rotation + trivel) % 360
            local s = 90 + math.sin(t * 2) * 8
            Triforce.Size = UDim2.fromOffset(s, s)
        end
    end, CracktroFrame)

    local HubCTA = Util.Instance("TextButton", CracktroFrame)
    HubCTA.Size                 = UDim2.new(1, 0, 1, 0)
    HubCTA.BackgroundTransparency = 1
    HubCTA.Text                 = ""
    HubCTA.ZIndex               = 20
    HubCTA.Activated:Connect(function()
        TweenService:Create(CracktroFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }):Play()
        task.wait(0.3)
        CracktroFrame.Visible = false
    end)
end

-- ── Tab bar + Hub pages ───────────────────────────────────────────────
local TabBar = Util.Instance("Frame", WindowContent)
TabBar.AnchorPoint          = Vector2.new(0, 0)
TabBar.Position             = UDim2.new(0, 0, 0, 0)
TabBar.Size                 = UDim2.new(1, 0, 0, 22)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel      = 0
TabBar.ZIndex               = 5
TabBar.Visible              = false -- shown after homepage dismissed

local PageContainer = Util.Instance("Frame", WindowContent)
PageContainer.AnchorPoint   = Vector2.new(0, 0)
PageContainer.Position      = UDim2.new(0, 0, 0, 22)
PageContainer.Size          = UDim2.new(1, 0, 1, -22)
PageContainer.BackgroundTransparency = 1
PageContainer.BorderSizePixel = 0
PageContainer.ZIndex        = 0
PageContainer.Visible       = false -- shown after homepage dismissed

-- Show tab bar when cracktro is dismissed
local function showHub()
    TabBar.Visible      = true
    PageContainer.Visible = true
end
-- Hook into the cracktro's dismiss logic
do
    local orig = CracktroFrame:GetPropertyChangedSignal("Visible")
    orig:Connect(function()
        if not CracktroFrame.Visible then showHub() end
    end)
end

-- Tab definitions
local tabNames = {"MOVE", "VISUAL", "PLAYERS", "SERVER", "OTHER"}
local tabPages = {}
local activeTab = 1

local tabWidth = 360 / #tabNames
local tabButtons = {}

for i, name in ipairs(tabNames) do
    local TB = Util.Instance("TextButton", TabBar)
    TB.AnchorPoint          = Vector2.new(0, 0)
    TB.Position             = UDim2.new(0, (i-1) * tabWidth, 0, 0)
    TB.Size                 = UDim2.new(0, tabWidth, 1, 0)
    TB.BackgroundTransparency = 0
    TB.BackgroundColor3     = Color3.new(0, 0, 0)
    TB.BorderSizePixel      = 1
    TB.BorderColor3         = Color3.new(0.3, 0.3, 0.3)
    TB.Text                 = name
    TB.Font                 = Enum.Font.Code
    TB.TextSize             = 11
    TB.TextColor3           = Color3.new(0.7, 0.7, 0.7)
    TB.ZIndex               = 5
    tabButtons[i] = TB

    local page = UI.CreatePage(PageContainer)
    page.Size    = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    tabPages[i] = page

    TB.Activated:Connect(function()
        for j, pg in ipairs(tabPages) do
            pg.Visible = (j == i)
        end
        activeTab = i
        for j, btn in ipairs(tabButtons) do
            if j == i then
                btn.TextColor3           = UITextColor.Value
                btn.BackgroundTransparency = 0.3
            else
                btn.TextColor3           = Color3.new(0.5, 0.5, 0.5)
                btn.BackgroundTransparency = 0
            end
        end
    end)
end

-- Activate first tab by default
tabPages[1].Visible = true
tabButtons[1].TextColor3             = UITextColor.Value
tabButtons[1].BackgroundTransparency = 0.3
AddRender(function(t)
    for i, btn in ipairs(tabButtons) do
        btn.BorderColor3 = GetUIColor(t)
        if i == activeTab then
            btn.BackgroundColor3 = GetUIBGColor(t):Lerp(Color3.new(1,1,1), 0.1)
        else
            btn.BackgroundColor3 = GetUIBGColor(t)
        end
    end
end)

-- Update tab text colors when theme changes
UITextColor.Changed:Connect(function(v)
    tabButtons[activeTab].TextColor3 = v
end)

-- ── Character / humanoid tracking ────────────────────────────────────
local char      = Player.Character or Player.CharacterAdded:Wait()
local humanoid  = char:WaitForChild("Humanoid", 5)
Player.CharacterAdded:Connect(function(newChar)
    char     = newChar
    humanoid = newChar:WaitForChild("Humanoid", 5)
end)

-- ─────────────────────────────────────────────────────────────────────
-- PAGE 1 ── MOVEMENT
-- ─────────────────────────────────────────────────────────────────────
local movePage = tabPages[1]
UI.CreateText(movePage, "── Movement ──", 16, Enum.TextXAlignment.Center)

-- Noclip
local noclip = false
local noclipLever = UI.CreateSwitch(movePage, "Noclip", false)
noclipLever.Changed:Connect(function(v) noclip = v end)
RunService.Stepped:Connect(function()
    if noclip and char then
        for _, part in char:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

UI.CreateSeparator(movePage)

-- WalkSpeed
local wsSelect = UI.CreateSlider(movePage, "WalkSpeed", 16, 1, 500, 1)
wsSelect.Changed:Connect(function(v)
    if humanoid then humanoid.WalkSpeed = v end
end)

-- JumpPower
local jpSelect = UI.CreateSlider(movePage, "JumpPower", 50, 1, 500, 1)
jpSelect.Changed:Connect(function(v)
    if humanoid then humanoid.JumpPower = v end
end)

UI.CreateSeparator(movePage)

-- Fly
local flying  = false
local flyForce = nil
local flySpeed = 50
local flyLever = UI.CreateSwitch(movePage, "Fly  [WASD + Space/Shift]", false)
flyLever.Changed:Connect(function(v)
    flying = v
    local c = Player.Character
    if flying and c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            flyForce = Instance.new("BodyVelocity")
            flyForce.MaxForce = Vector3.new(4e4, 4e4, 4e4)
            flyForce.Velocity = Vector3.zero
            flyForce.Parent   = hrp
            if c:FindFirstChild("Humanoid") then c.Humanoid.PlatformStand = true end
        end
    else
        if flyForce then flyForce:Destroy(); flyForce = nil end
        if c and c:FindFirstChild("Humanoid") then c.Humanoid.PlatformStand = false end
    end
end)

UIS.InputChanged:Connect(function(inp)
    if flying and flyForce and inp.UserInputType == Enum.UserInputType.Keyboard then
        local d = Vector3.zero
        local cam = workspace.CurrentCamera
        if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector  * flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector  * flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector * flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector * flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then d = d + Vector3.new(0, flySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, flySpeed, 0) end
        flyForce.Velocity = d
    end
end)

local flySpeedSel = UI.CreateSlider(movePage, "Fly Speed", flySpeed, 1, 300, 1)
flySpeedSel.Changed:Connect(function(v) flySpeed = v end)

-- ─────────────────────────────────────────────────────────────────────
-- PAGE 2 ── VISUAL (ESP)
-- ─────────────────────────────────────────────────────────────────────
local visPage = tabPages[2]
UI.CreateText(visPage, "── Visuals ──", 16, Enum.TextXAlignment.Center)

local espOn = false
local function createESP(plr)
    if plr == Player then return end
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head
    if head:FindFirstChild("TixESP") then return end
    local bb  = Instance.new("BillboardGui")
    bb.Name         = "TixESP"
    bb.Size         = UDim2.new(0, 100, 0, 20)
    bb.AlwaysOnTop  = true
    bb.Adornee      = head
    bb.Parent       = head
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                    = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency  = 1
    lbl.TextColor3              = Color3.fromRGB(255, 60, 60)
    lbl.TextStrokeTransparency  = 0.3
    lbl.TextStrokeColor3        = Color3.new(0, 0, 0)
    lbl.Text                    = plr.Name
    lbl.TextScaled              = true
end
local function removeESP(plr)
    if plr.Character and plr.Character:FindFirstChild("Head") then
        local e = plr.Character.Head:FindFirstChild("TixESP")
        if e then e:Destroy() end
    end
end
local function refreshESP()
    for _, plr in Players:GetPlayers() do
        if espOn then createESP(plr) else removeESP(plr) end
    end
end
local espLever = UI.CreateSwitch(visPage, "Player ESP (names)", false)
espLever.Changed:Connect(function(v) espOn = v; refreshESP() end)
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espOn then task.wait(1); createESP(plr) end
    end)
end)

-- ─────────────────────────────────────────────────────────────────────
-- PAGE 3 ── PLAYERS
-- ─────────────────────────────────────────────────────────────────────
local plrPage = tabPages[3]
UI.CreateText(plrPage, "── Players ──", 16, Enum.TextXAlignment.Center)

-- Player list (refresh button + scrollable buttons)
local playerListContainer = nil
local function buildPlayerList()
    if playerListContainer then playerListContainer:Destroy() end

    -- container frame inside the page
    local Outer = Util.Instance("Frame", plrPage)
    Outer.AnchorPoint          = Vector2.new(0.5, 0)
    Outer.Size                 = UDim2.new(1, 0, 0, 130)
    Outer.BackgroundTransparency = 1
    Outer.LayoutOrder          = 999 -- after separator
    Outer.BorderSizePixel      = 0

    local Inner = Util.Instance("ScrollingFrame", Outer)
    Inner.Position             = UDim2.new(0, 5, 0, 2)
    Inner.Size                 = UDim2.new(1, -10, 1, -4)
    Inner.BackgroundColor3     = Color3.new(0, 0, 0)
    Inner.BackgroundTransparency = 0.3
    Inner.BorderSizePixel      = 1
    Inner.BorderColor3         = Color3.new(0.3, 0.3, 0.3)
    Inner.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    Inner.CanvasSize           = UDim2.new(0, 0, 0, 0)
    Inner.ScrollingDirection   = Enum.ScrollingDirection.Y
    Inner.ScrollBarThickness   = 3
    Inner.ClipsDescendants     = true
    local UIList2 = Util.Instance("UIListLayout", Inner)
    UIList2.FillDirection      = Enum.FillDirection.Vertical
    UIList2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIList2.SortOrder          = Enum.SortOrder.LayoutOrder

    local plrs = Players:GetPlayers()
    if #plrs <= 1 then
        local lbl = Util.Instance("TextLabel", Inner)
        lbl.Size               = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text               = "no other players"
        lbl.Font               = Enum.Font.Code
        lbl.TextSize           = 16
        lbl.TextColor3         = Color3.new(0.5, 0.5, 0.5)
    else
        for i, plr in ipairs(plrs) do
            if plr == Player then continue end
            local Row = Util.Instance("TextButton", Inner)
            Row.Size               = UDim2.new(1, 0, 0, 24)
            Row.BackgroundTransparency = 0
            Row.BackgroundColor3   = Color3.new(0.05, 0.05, 0.05)
            Row.BorderSizePixel    = 0
            Row.AutoButtonColor    = true
            Row.Text               = plr.Name
            Row.Font               = Enum.Font.Code
            Row.TextSize           = 15
            Row.TextColor3         = Color3.new(1, 1, 1)
            Row.TextXAlignment     = Enum.TextXAlignment.Left
            Row.LayoutOrder        = i
            local Pad = Util.Instance("UIPadding", Row)
            Pad.PaddingLeft = UDim.new(0, 6)
            Row.Activated:Connect(function()
                local target = Players:FindFirstChild(plr.Name)
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and Player.Character then
                    Player.Character:MoveTo(target.Character.HumanoidRootPart.Position + Vector3.new(2, 0, 2))
                    Util.Notify("Teleported to " .. plr.Name)
                else
                    Util.Notify("Can't reach " .. plr.Name)
                end
            end)
        end
    end
    playerListContainer = Outer
end

UI.CreateText(plrPage, "Click a player to teleport:", 15, Enum.TextXAlignment.Left)
buildPlayerList()
local refBtn = UI.CreateButton(plrPage, "↻  Refresh Player List", 16)
refBtn.Activated:Connect(function()
    buildPlayerList()
end)

-- ─────────────────────────────────────────────────────────────────────
-- PAGE 4 ── SERVER / OTHER
-- ─────────────────────────────────────────────────────────────────────
local srvPage = tabPages[4]
UI.CreateText(srvPage, "── Server ──", 16, Enum.TextXAlignment.Center)

local rejBtn = UI.CreateButton(srvPage, "Rejoin", 18)
rejBtn.Activated:Connect(function()
    TeleportService:Teleport(game.PlaceId, Player)
end)

local hopBtn = UI.CreateButton(srvPage, "Server Hop", 18)
hopBtn.Activated:Connect(function()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)))
    end)
    if ok and res and res.data then
        local servers = {}
        for _, s in ipairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Player)
        else
            Util.Notify("No available servers found.")
        end
    else
        Util.Notify("Server list request failed.")
    end
end)

UI.CreateSeparator(srvPage)

local kickBtn = UI.CreateButton(srvPage, "Kick Yourself", 18)
kickBtn.Activated:Connect(function()
    Player:Kick("see ya, bye  -- tix hub")
end)

local destroyBtn = UI.CreateButton(srvPage, "Destroy GUI", 18)
destroyBtn.Activated:Connect(function()
    SCREENGUI:Destroy()
end)

UI.CreateSeparator(srvPage)
UI.CreateText(srvPage, "Music Controls", 16, Enum.TextXAlignment.Center)

local muteBtn = UI.CreateButton(srvPage, SaveData.MuteUIMusic and "Unmute UI Music" or "Mute UI Music", 16)
muteBtn.Activated:Connect(function()
    SaveData.MuteUIMusic = not SaveData.MuteUIMusic
    if SaveData.MuteUIMusic then
        TweenService:Create(UISound.Music, TweenInfo.new(1), {Volume = 0}):Play()
        -- find BText child
        for _, v in muteBtn:GetChildren() do if v:IsA("TextLabel") then v.Text = "Unmute UI Music" end end
    else
        TweenService:Create(UISound.Music, TweenInfo.new(1), {Volume = 1}):Play()
        for _, v in muteBtn:GetChildren() do if v:IsA("TextLabel") then v.Text = "Mute UI Music" end end
    end
end)

local skipBtn = UI.CreateButton(srvPage, "Skip Song", 16)
skipBtn.Activated:Connect(function()
    MusicPlayer.Play()
end)

UI.CreateSeparator(srvPage)
local skipIntroLever = UI.CreateSwitch(srvPage, "Skip Intro on Reload", SaveData.SkipIntro)
skipIntroLever.Changed:Connect(function(v) SaveData.SkipIntro = v end)

-- ─────────────────────────────────────────────────────────────────────
-- PAGE 5 ── OTHER STUFF
-- ─────────────────────────────────────────────────────────────────────
local otherPage = tabPages[5]
UI.CreateText(otherPage, "── Other ──", 16, Enum.TextXAlignment.Center)

-- Infinite Jump
local infJump = false
local infJumpLever = UI.CreateSwitch(otherPage, "Infinite Jump", false)
infJumpLever.Changed:Connect(function(v) infJump = v end)
UIS.JumpRequest:Connect(function()
    if infJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UI.CreateSeparator(otherPage)

-- FullBright
local origAmbient  = game.Lighting.Ambient
local origOutdoor  = game.Lighting.OutdoorAmbient
local origBrightness = game.Lighting.Brightness
local fbLever = UI.CreateSwitch(otherPage, "FullBright", false)
fbLever.Changed:Connect(function(v)
    if v then
        game.Lighting.Ambient        = Color3.new(1, 1, 1)
        game.Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        game.Lighting.Brightness     = 2
    else
        game.Lighting.Ambient        = origAmbient
        game.Lighting.OutdoorAmbient = origOutdoor
        game.Lighting.Brightness     = origBrightness
    end
end)

UI.CreateSeparator(otherPage)

-- Gravity
local gravSel = UI.CreateSlider(otherPage, "Gravity", math.floor(workspace.Gravity), 0, 500, 1)
gravSel.Changed:Connect(function(v) workspace.Gravity = v end)

-- FOV
local fovSel = UI.CreateSlider(otherPage, "FOV", 70, 30, 120, 1)
fovSel.Changed:Connect(function(v)
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
end)

-- ── Done ──────────────────────────────────────────────────────────────
Util.Notify("tix Hub loaded! Click the window to open.")
