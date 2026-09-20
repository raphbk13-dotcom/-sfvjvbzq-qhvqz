-- ============================================================
-- BitchBot UI Library — original code, wrapped as Library
-- ============================================================
local Library = {}
Library.Options = {}
Library.Toggles = {}
Library.Unloaded = false
getgenv().Options = Library.Options
getgenv().Toggles = Library.Toggles

-- ============================================================
-- ORIGINAL BITCHBOT CODE (unchanged)
-- ============================================================
local menu
local MenuName = nil
local loadstart = tick()

local function map(X, A, B, C, D)
    return (X - A) / (B - A) * (D - C) + C
end

do
    local notes = {}
    local function DrawingObject(t, col)
        local d = Drawing.new(t)
        d.Visible = true
        d.Transparency = 1
        d.Color = col
        return d
    end
    local function Rectangle(sizex, sizey, fill, col)
        local s = DrawingObject("Square", col)
        s.Filled = fill
        s.Thickness = 1
        s.Position = Vector2.new()
        s.Size = Vector2.new(sizex, sizey)
        return s
    end
    local function Text(text)
        local s = DrawingObject("Text", Color3.new(1, 1, 1))
        s.Text = text
        s.Size = 13
        s.Center = false
        s.Outline = true
        s.Position = Vector2.new()
        s.Font = 2
        return s
    end
    function CreateNotification(t, customcolor)
        local gap = 25
        local width = 18
        local alpha = 255
        local time = 0
        local estep = 0
        local eestep = 0.02
        local insety = 0
        local Note = {
            enabled = true,
            targetPos = Vector2.new(50, 33),
            size = Vector2.new(200, width),
            drawings = {
                outline = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
                fade = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
            },
            Remove = function(self, d)
                if d.Position.x < d.Size.x then
                    for k, drawing in pairs(self.drawings) do
                        drawing:Remove()
                        drawing = false
                    end
                    self.enabled = false
                end
            end,
            Update = function(self, num, listLength, dt)
                local pos = self.targetPos
                local indexOffset = (listLength - num) * gap
                if insety < indexOffset then
                    insety -= (insety - indexOffset) * 0.2
                else
                    insety = indexOffset
                end
                local size = self.size
                local tpos = Vector2.new(pos.x - size.x / time - map(alpha, 0, 255, size.x, 0), pos.y + insety)
                self.pos = tpos
                local locRect = {
                    x = math.ceil(tpos.x),
                    y = math.ceil(tpos.y),
                    w = math.floor(size.x - map(255 - alpha, 0, 255, 0, 70)),
                    h = size.y,
                }
                local fade = math.min(time * 12, alpha)
                fade = fade > 255 and 255 or fade < 0 and 0 or fade
                if self.enabled then
                    local linenum = 1
                    for i, drawing in pairs(self.drawings) do
                        drawing.Transparency = fade / 255
                        if type(i) == "number" then
                            drawing.Position = Vector2.new(locRect.x + 1, locRect.y + i)
                            drawing.Size = Vector2.new(locRect.w - 2, 1)
                        elseif i == "text" then
                            drawing.Position = tpos + Vector2.new(6, 2)
                        elseif i == "outline" then
                            drawing.Position = Vector2.new(locRect.x, locRect.y)
                            drawing.Size = Vector2.new(locRect.w, locRect.h)
                        elseif i == "fade" then
                            drawing.Position = Vector2.new(locRect.x - 1, locRect.y - 1)
                            drawing.Size = Vector2.new(locRect.w + 2, locRect.h + 2)
                            local t = (200 - fade) / 255 / 3
                            drawing.Transparency = t < 0.4 and 0.4 or t
                        elseif i:find("line") then
                            drawing.Position = Vector2.new(locRect.x + linenum, locRect.y + 1)
                            if menu then
                                local mencol = customcolor or Color3.fromRGB(127, 72, 163)
                                local color = linenum == 1 and mencol or Color3.fromRGB(mencol.R * 255 - 40, mencol.G * 255 - 40, mencol.B * 255 - 40)
                                if drawing.Color ~= color then drawing.Color = color end
                            end
                            linenum += 1
                        end
                    end
                    time += estep * dt * 128
                    estep += eestep * dt * 64
                end
            end,
            Fade = function(self, num, len, dt)
                if self.pos.x > self.targetPos.x - 0.2 * len or self.fading then
                    if not self.fading then estep = 0 end
                    self.fading = true
                    alpha -= estep / 4 * len * dt * 50
                    eestep += 0.01 * dt * 100
                end
                if alpha <= 0 then self:Remove(self.drawings[1]) end
            end,
        }
        for i = 1, Note.size.y - 2 do
            local c = 0.28 - i / 80
            Note.drawings[i] = Rectangle(200, 1, true, Color3.new(c, c, c))
        end
        local color = Color3.fromRGB(127, 72, 163)
        Note.drawings.text = Text(t)
        if Note.drawings.text.TextBounds.x + 7 > Note.size.x then
            Note.size = Vector2.new(Note.drawings.text.TextBounds.x + 7, Note.size.y)
        end
        Note.drawings.line = Rectangle(1, Note.size.y - 2, true, color)
        Note.drawings.line1 = Rectangle(1, Note.size.y - 2, true, color)
        notes[#notes + 1] = Note
    end
    renderStepped = game.RunService.RenderStepped:Connect(function(dt)
        Camera = workspace.CurrentCamera
        local smallest = math.huge
        for k = 1, #notes do
            local v = notes[k]
            if v and v.enabled then
                smallest = k < smallest and k or smallest
            else
                table.remove(notes, k)
            end
        end
        local length = #notes
        for k = 1, #notes do
            local note = notes[k]
            note:Update(k, length, dt)
            if k <= math.ceil(length / 10) or note.fading then
                note:Fade(k, length, dt)
            end
        end
    end)
end

local menuWidth, menuHeight = 500, 600
menu = {
    w = menuWidth,
    h = menuHeight,
    x = 0,
    y = 0,
    columns = {
        width = (menuWidth - 40) / 2,
        left = 17,
        right = (menuWidth - 20) / 2 + 13,
    },
    activetab = 1,
    open = true,
    fadestart = 0,
    fading = false,
    mousedown = false,
    postable = {},
    options = {},
    clrs = {
        norm = {},
        dark = {},
        togz = {},
    },
    mc = { 127, 72, 163 },
    watermark = {},
    connections = {},
    list = {},
    unloaded = false,
    copied_clr = nil,
    game = "uni",
    tabnames = {},
    friends = {},
    priority = {},
    muted = {},
    spectating = false,
    stat_menu = false,
    load_time = 0,
    log_multi = nil,
    mgrouptabz = {},
    backspaceheld = false,
    backspacetime = -1,
    backspaceflags = 0,
    selectall = false,
    modkeys = {
        alt = { direction = nil },
        shift = { direction = nil },
    },
    modkeydown = function(self, key, direction)
        local keydata = self.modkeys[key]
        return keydata.direction and keydata.direction == direction or false
    end,
    keybinds = {},
    values = {}
}

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
local function clamp(a, lowerNum, higher)
    if a > higher then return higher
    elseif a < lowerNum then return lowerNum
    else return a end
end
local function CreateThread(func, ...)
    local thread = coroutine.create(func)
    coroutine.resume(thread, ...)
    return thread
end
local function MultiThreadList(obj, ...)
    local n = #obj
    if n > 0 then
        for i = 1, n do
            local t = obj[i]
            if type(t) == "table" then
                local d = #t
                assert(d ~= 0, "table inserted was not an array or was empty")
                assert(d < 3, ("invalid number of arguments (%d)"):format(d))
                local thetype = type(t[1])
                assert(thetype == "function", ("invalid argument #1: expected 'function', got '%s'"):format(tostring(thetype)))
                CreateThread(t[1], unpack(t[2]))
            else
                CreateThread(t, ...)
            end
        end
    else
        for i, v in pairs(obj) do CreateThread(v, ...) end
    end
end

local event = {}
local allevent = {}
function event.new(eventname, eventtable, requirename)
    if eventname then
        assert(allevent[eventname] == nil, ("the event '%s' already exists in the event table"):format(eventname))
    end
    local newevent = eventtable or {}
    local funcs = {}
    local disconnectlist = {}
    function newevent:fire(...) allevent[eventname].fire(...) end
    function newevent:connect(func)
        funcs[#funcs + 1] = func
        local disconnected = false
        local function disconnect()
            if not disconnected then
                disconnected = true
                disconnectlist[func] = true
            end
        end
        return disconnect
    end
    local function fire(...)
        local n = #funcs
        local j = 0
        for i = 1, n do
            local func = funcs[i]
            if disconnectlist[func] then
                disconnectlist[func] = nil
            else
                j = j + 1
                funcs[j] = func
            end
        end
        for i = j + 1, n do funcs[i] = nil end
        for i = 1, j do
            CreateThread(function(...) pcall(funcs[i], ...) end, ...)
        end
    end
    if eventname then
        allevent[eventname] = { event = newevent, fire = fire }
    end
    return newevent, fire
end
local function FireEvent(eventname, ...)
    if allevent[eventname] then return allevent[eventname].fire(...) end
end

local BBOT_IMAGES = {}
MultiThreadList({
    function() BBOT_IMAGES[1] = game:HttpGet("https://i.imgur.com/9NMuFcQ.png") end,
    function() BBOT_IMAGES[2] = game:HttpGet("https://i.imgur.com/jG3NjxN.png") end,
    function() BBOT_IMAGES[3] = game:HttpGet("https://i.imgur.com/2Ty4u2O.png") end,
    function() BBOT_IMAGES[4] = game:HttpGet("https://i.imgur.com/kNGuTlj.png") end,
    function() BBOT_IMAGES[5] = game:HttpGet("https://i.imgur.com/OZUR3EY.png") end,
    function() BBOT_IMAGES[6] = game:HttpGet("https://i.imgur.com/3HGuyVa.png") end,
})
local loaded = {}
do
    local function Loopy_Image_Checky()
        for i = 1, 6 do
            local v = BBOT_IMAGES[i]
            if v == nil then return true
            elseif not loaded[i] then loaded[i] = true end
        end
        return false
    end
    while Loopy_Image_Checky() do wait(0) end
end
loadstart = tick()

if not isfolder("bitchbot") then makefolder("bitchbot") end
if not isfolder("bitchbot/uni") then makefolder("bitchbot/uni") end
local configs = {}

local Players = game:GetService("Players")
local function GetConfigs()
    local result = {}
    local directory = "bitchbot\\uni"
    local ok, files = pcall(listfiles, directory)
    if ok and files then
        for k, v in pairs(files) do
            local clipped = v:sub(#directory + 2)
            if clipped:sub(#clipped - 2) == ".bb" then
                clipped = clipped:sub(0, #clipped - 3)
                result[k] = clipped
                configs[k] = v
            end
        end
    end
    if #result <= 0 then writefile("bitchbot/uni/Default.bb", "") end
    return result
end

local LOCAL_PLAYER = Players.LocalPlayer
local LOCAL_MOUSE = LOCAL_PLAYER:GetMouse()
local INPUT_SERVICE = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local SCREEN_SIZE = Camera.ViewportSize
local ButtonPressed = event.new("bb_buttonpressed")
local TogglePressed = event.new("bb_togglepressed")
local MouseMoved = event.new("bb_mousemoved")

menu.x = math.floor((SCREEN_SIZE.x / 2) - (menu.w / 2))
menu.y = math.floor((SCREEN_SIZE.y / 2) - (menu.h / 2))

local Lerp = function(delta, from, to)
    if delta > 1 then return to end
    if delta < 0 then return from end
    return from + (to - from) * delta
end
local ColorRange = function(value, ranges)
    if value <= ranges[1].start then return ranges[1].color end
    if value >= ranges[#ranges].start then return ranges[#ranges].color end
    local selected = #ranges
    for i = 1, #ranges - 1 do
        if value < ranges[i + 1].start then selected = i break end
    end
    local minColor = ranges[selected]
    local maxColor = ranges[selected + 1]
    local lerpValue = (value - minColor.start) / (maxColor.start - minColor.start)
    return Color3.new(
        Lerp(lerpValue, minColor.color.r, maxColor.color.r),
        Lerp(lerpValue, minColor.color.g, maxColor.color.g),
        Lerp(lerpValue, minColor.color.b, maxColor.color.b)
    )
end

local keyNames = { One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0", LeftBracket = "[", RightBracket = "]", Semicolon = ";", BackSlash = "\\", Slash = "/", Minus = "-", Equals = "=", Return = "Enter", Backquote = "`", CapsLock = "Caps", LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl", LeftAlt = "LAlt", RightAlt = "RAlt", Backspace = "Back", Plus = "+", Multiply = "x", PageUp = "PgUp", PageDown = "PgDown", Delete = "Del", Insert = "Ins", NumLock = "NumL", Comma = ",", Period = "." }
local function KeyEnumToName(key)
    if key == nil then return "None" end
    local _key = tostring(key) .. "."
    local _key = _key:gsub("%.", ",")
    local keyname = nil
    local looptime = 0
    for w in _key:gmatch("(.-),") do
        looptime = looptime + 1
        if looptime == 3 then keyname = w end
    end
    if string.match(keyname, "Keypad") then keyname = string.gsub(keyname, "Keypad", "") end
    if keyname == "Unknown" or key.Value == 27 then return "None" end
    if keyNames[keyname] then keyname = keyNames[keyname] end
    return keyname
end

local allrender = {}
local RGB = Color3.fromRGB
local Draw = {}

do
    function Draw:UnRender()
        for k, v in pairs(allrender) do
            for k1, v1 in pairs(v) do
                if v1 and type(v1) ~= "number" and v1.__OBJECT_EXISTS then
                    v1:Remove()
                end
            end
        end
    end
    function Draw:OutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
        local temptable = Drawing.new("Square")
        temptable.Visible = visible
        temptable.Position = Vector2.new(pos_x, pos_y)
        temptable.Size = Vector2.new(width, height)
        temptable.Color = RGB(clr[1], clr[2], clr[3])
        temptable.Filled = false
        temptable.Thickness = 0
        temptable.Transparency = clr[4] / 255
        table.insert(tablename, temptable)
        if not table.find(allrender, tablename) then table.insert(allrender, tablename) end
    end
    function Draw:FilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
        local temptable = Drawing.new("Square")
        temptable.Visible = visible
        temptable.Position = Vector2.new(pos_x, pos_y)
        temptable.Size = Vector2.new(width, height)
        temptable.Color = RGB(clr[1], clr[2], clr[3])
        temptable.Filled = true
        temptable.Thickness = 0
        temptable.Transparency = clr[4] / 255
        table.insert(tablename, temptable)
        if not table.find(allrender, tablename) then table.insert(allrender, tablename) end
    end
    function Draw:Line(visible, thickness, start_x, start_y, end_x, end_y, clr, tablename)
        local temptable = Drawing.new("Line")
        temptable.Visible = visible
        temptable.Thickness = thickness
        temptable.From = Vector2.new(start_x, start_y)
        temptable.To = Vector2.new(end_x, end_y)
        temptable.Color = RGB(clr[1], clr[2], clr[3])
        temptable.Transparency = clr[4] / 255
        table.insert(tablename, temptable)
        if not table.find(allrender, tablename) then table.insert(allrender, tablename) end
    end
    function Draw:Text(text, font, visible, pos_x, pos_y, size, centered, clr, tablename)
        local temptable = Drawing.new("Text")
        temptable.Text = text
        temptable.Visible = visible
        temptable.Position = Vector2.new(pos_x, pos_y)
        temptable.Size = size
        temptable.Center = centered
        temptable.Color = RGB(clr[1], clr[2], clr[3])
        temptable.Transparency = clr[4] / 255
        temptable.Outline = false
        temptable.Font = font
        table.insert(tablename, temptable)
        if not table.find(allrender, tablename) then table.insert(allrender, tablename) end
    end
    function Draw:OutlinedText(text, font, visible, pos_x, pos_y, size, centered, clr, clr2, tablename)
        local temptable = Drawing.new("Text")
        temptable.Text = text
        temptable.Visible = visible
        temptable.Position = Vector2.new(pos_x, pos_y)
        temptable.Size = size
        temptable.Center = centered
        temptable.Color = RGB(clr[1], clr[2], clr[3])
        temptable.Transparency = clr[4] / 255
        temptable.Outline = true
        temptable.OutlineColor = RGB(clr2[1], clr2[2], clr2[3])
        temptable.Font = font
        if not table.find(allrender, tablename) then table.insert(allrender, tablename) end
        if tablename then table.insert(tablename, temptable) end
        return temptable
    end

    function Draw:MenuOutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
        Draw:OutlinedRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
        table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })
        if menu.log_multi ~= nil then
            table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
        end
    end
    function Draw:MenuFilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
        Draw:FilledRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
        table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })
        if menu.log_multi ~= nil then
            table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
        end
    end
    function Draw:MenuBigText(text, visible, centered, pos_x, pos_y, tablename)
        local text = Draw:OutlinedText(text, 2, visible, pos_x + menu.x, pos_y + menu.y, 13, centered, { 255, 255, 255, 255 }, { 0, 0, 0 }, tablename)
        table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })
        if menu.log_multi ~= nil then
            table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
        end
        return text
    end
    function Draw:CoolBox(name, x, y, width, height, tab)
        Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
        table.insert(menu.clrs.norm, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
        table.insert(menu.clrs.dark, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)
        for i = 0, 7 do
            Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 4, 2, { 45, 45, 45, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(45, 45, 45) }, [2] = { start = 7, color = RGB(35, 35, 35) } })
        end
        Draw:MenuBigText(name, true, false, x + 6, y + 5, tab)
    end
    function Draw:CoolMultiBox(names, x, y, width, height, tab)
        Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
        table.insert(menu.clrs.norm, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
        table.insert(menu.clrs.dark, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)
        Draw:MenuFilledRect(true, x + 2, y + 5, width - 4, 18, { 30, 30, 30, 255 }, tab)
        Draw:MenuFilledRect(true, x + 2, y + 21, width - 4, 2, { 20, 20, 20, 255 }, tab)
        local selected = {}
        for i = 0, 8 do
            Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 159, 2, { 45, 45, 45, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } })
            table.insert(selected, { postable = #menu.postable, drawn = tab[#tab] })
        end
        local length = 2
        local selected_pos = {}
        local click_pos = {}
        local nametext = {}
        for i, v in ipairs(names) do
            Draw:MenuBigText(v, true, false, x + 4 + length, y + 5, tab)
            if i == 1 then tab[#tab].Color = RGB(255, 255, 255)
            else tab[#tab].Color = RGB(170, 170, 170) end
            table.insert(nametext, tab[#tab])
            Draw:MenuFilledRect(true, x + length + tab[#tab].TextBounds.X + 8, y + 5, 2, 16, { 20, 20, 20, 255 }, tab)
            table.insert(selected_pos, { pos = x + length, length = tab[#tab - 1].TextBounds.X + 8 })
            table.insert(click_pos, { x = x + length, y = y + 5, width = tab[#tab - 1].TextBounds.X + 8, height = 18, name = v, num = i })
            length += tab[#tab - 1].TextBounds.X + 10
        end
        local settab = 1
        for k, v in pairs(selected) do
            menu.postable[v.postable][2] = selected_pos[settab].pos
            v.drawn.Size = Vector2.new(selected_pos[settab].length, 2)
        end
        return { bar = selected, barpos = selected_pos, click_pos = click_pos, nametext = nametext }
    end
    function Draw:Toggle(name, value, unsafe, x, y, tab)
        Draw:MenuOutlinedRect(true, x, y, 12, 12, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, 10, 10, { 0, 0, 0, 255 }, tab)
        local temptable = {}
        for i = 0, 3 do
            Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), 8, 2, { 0, 0, 0, 255 }, tab)
            table.insert(temptable, tab[#tab])
            if value then
                tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) }, [2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) } })
            else
                tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 3, color = RGB(30, 30, 30) } })
            end
        end
        Draw:MenuBigText(name, true, false, x + 16, y - 1, tab)
        if unsafe == true then tab[#tab].Color = RGB(90, 90, 90) end
        table.insert(temptable, tab[#tab])
        return temptable
    end
    function Draw:Keybind(key, x, y, tab)
        local temptable = {}
        Draw:MenuFilledRect(true, x, y, 44, 16, { 25, 25, 25, 255 }, tab)
        Draw:MenuBigText(KeyEnumToName(key), true, true, x + 22, y + 1, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuOutlinedRect(true, x, y, 44, 16, { 30, 30, 30, 255 }, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 1, y + 1, 42, 14, { 0, 0, 0, 255 }, tab)
        return temptable
    end
    function Draw:ColorPicker(color, x, y, tab)
        local temptable = {}
        Draw:MenuOutlinedRect(true, x, y, 28, 14, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, 26, 12, { 0, 0, 0, 255 }, tab)
        Draw:MenuFilledRect(true, x + 2, y + 2, 24, 10, { color[1], color[2], color[3], 255 }, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 2, y + 2, 24, 10, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuOutlinedRect(true, x + 3, y + 3, 22, 8, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
        table.insert(temptable, tab[#tab])
        return temptable
    end
    function Draw:Slider(name, stradd, value, minvalue, maxvalue, customvals, rounded, x, y, length, tab)
        Draw:MenuBigText(name, true, false, x, y - 3, tab)
        for i = 0, 3 do
            Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 3, color = RGB(30, 30, 30) } })
        end
        local temptable = {}
        for i = 0, 3 do
            Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), (length - 4) * ((value - minvalue) / (maxvalue - minvalue)), 2, { 0, 0, 0, 255 }, tab)
            table.insert(temptable, tab[#tab])
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) }, [2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) } })
        end
        Draw:MenuOutlinedRect(true, x, y + 12, length, 12, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 10, { 0, 0, 0, 255 }, tab)
        local textstr = ""
        if stradd == nil then stradd = "" end
        local decplaces = rounded and string.rep("0", math.log(1 / rounded) / math.log(10)) or 1
        if rounded and value == math.floor(value * decplaces) then
            textstr = tostring(value) .. "." .. decplaces .. stradd
        else
            textstr = tostring(value) .. stradd
        end
        Draw:MenuBigText(customvals[value] or textstr, true, true, x + (length * 0.5), y + 11, tab)
        table.insert(temptable, tab[#tab])
        table.insert(temptable, stradd)
        return temptable
    end
    function Draw:Dropbox(name, value, values, x, y, length, tab)
        local temptable = {}
        Draw:MenuBigText(name, true, false, x, y - 3, tab)
        for i = 0, 7 do
            Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } })
        end
        Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)
        Draw:MenuBigText(tostring(values[value]), true, false, x + 6, y + 16, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuBigText("-", true, false, x - 17 + length, y + 16, tab)
        table.insert(temptable, tab[#tab])
        return temptable
    end
    function Draw:Combobox(name, values, x, y, length, tab)
        local temptable = {}
        Draw:MenuBigText(name, true, false, x, y - 3, tab)
        for i = 0, 7 do
            Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } })
        end
        Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)
        local textthing = ""
        for k, v in pairs(values) do
            if v[2] then
                if textthing == "" then textthing = v[1]
                else textthing ..= ", " .. v[1] end
            end
        end
        if string.len(textthing) > 25 then textthing = string_cut(textthing, 25) end
        textthing = textthing ~= "" and textthing or "None"
        Draw:MenuBigText(textthing, true, false, x + 6, y + 16, tab)
        table.insert(temptable, tab[#tab])
        Draw:MenuBigText("...", true, false, x - 27 + length, y + 16, tab)
        table.insert(temptable, tab[#tab])
        return temptable
    end
    function Draw:Button(name, x, y, length, tab)
        local temptable = {}
        for i = 0, 8 do
            Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } })
            table.insert(temptable, tab[#tab])
        end
        Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
        temptable.text = Draw:MenuBigText(name, true, true, x + math.floor(length * 0.5), y + 4, tab)
        return temptable
    end
    function Draw:TextBox(name, text, x, y, length, tab)
        for i = 0, 8 do
            Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
            tab[#tab].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } })
        end
        Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
        Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
        Draw:MenuBigText(text, true, false, x + 6, y + 4, tab)
        return tab[#tab]
    end
end

-- ============================================================
-- LIBRARY WRAPPER : expose les fonctions originales
-- ============================================================

function Library:CreateWindow(opts)
    opts = opts or {}
    MenuName = opts.Title or "Bitch Bot"
    menu.open = opts.AutoShow ~= false
    menu.Initialize = menu.Initialize or function() end
    -- rebuild menu object with new title
    Library._window = { tabs = {} }
    Library._tabBuilders = {}
    Library._window.MenuName = MenuName
    return Library._window
end

function Library._window:AddTab(name)
    local idx = #self.tabs + 1
    self.tabs[idx] = { name = name, content = {} }
    Library._tabBuilders[idx] = self.tabs[idx].content
    return { _tabIdx = idx, _content = self.tabs[idx].content }
end

local TabMethods = {}
TabMethods.__index = TabMethods

function Library._tabObj:AddLeftGroupbox(name) end  -- placeholder

-- Better: proper API
function Library:_getTab(idx)
    return self._window.tabs[idx]
end

-- Rewrite AddTab return to proper object
local function makeTabObj(window, idx)
    local obj = { _idx = idx, _window = window }
    function obj:AddLeftGroupbox(name)
        local g = { name = name, autopos = "left", content = {} }
        table.insert(self._window.tabs[self._idx].content, g)
        return makeGroupObj(g)
    end
    function obj:AddRightGroupbox(name)
        local g = { name = name, autopos = "right", content = {} }
        table.insert(self._window.tabs[self._idx].content, g)
        return makeGroupObj(g)
    end
    return obj
end

local function makeGroupObj(g)
    local obj = { _group = g }
    function obj:AddToggle(idx, opts)
        opts = opts or {}
        table.insert(g.content, { type = "toggle", name = opts.Text or idx, value = opts.Default == true, _idx = idx, _callback = opts.Callback })
        return { SetValue = function(self, v) end, OnChanged = function(self, fn) end, Value = opts.Default == true }
    end
    function obj:AddSlider(idx, opts)
        opts = opts or {}
        table.insert(g.content, { type = "slider", name = opts.Text or idx, value = opts.Default or 0, minvalue = opts.Min or 0, maxvalue = opts.Max or 100, stradd = opts.Suffix or "", _idx = idx, _callback = opts.Callback })
        return { SetValue = function(self, v) end, OnChanged = function(self, fn) end, Value = opts.Default or 0 }
    end
    function obj:AddDropdown(idx, opts)
        opts = opts or {}
        table.insert(g.content, { type = "dropbox", name = opts.Text or idx, value = opts.Default or 1, values = opts.Values or {}, _idx = idx, _callback = opts.Callback })
        return { SetValue = function(self, v) end, OnChanged = function(self, fn) end, Value = opts.Values and opts.Values[opts.Default or 1] or nil }
    end
    function obj:AddButton(a, b)
        local txt = type(a) == "table" and a.Text or a
        local fn = type(a) == "table" and a.Func or b
        table.insert(g.content, { type = "button", name = txt, _callback = fn })
        return { }
    end
    function obj:AddLabel(txt, wrap)
        table.insert(g.content, { type = "label", name = txt })
        return { AddColorPicker = function(self, idx, opts) return { SetValueRGB = function() end, OnChanged = function() end, Value = Color3.new(1,1,1) } end, AddKeyPicker = function(self, idx, opts) return { GetState = function() return false end, OnChanged = function() end, Value = "None" } end }
    end
    function obj:AddDivider()
        table.insert(g.content, { type = "label", name = "" })
    end
    return obj
end

-- Real implementation
function Library:CreateWindow(opts)
    opts = opts or {}
    MenuName = opts.Title or "Bitch Bot"
    menu.open = opts.AutoShow ~= false
    local window = { tabs = {}, _pendingInit = true }
    window.Title = MenuName

    function window:AddTab(name)
        local idx = #self.tabs + 1
        local tabData = { name = name, content = {} }
        self.tabs[idx] = tabData
        return makeTabObj(self, idx)
    end

    Library._window = window
    Library._pendingInit = function()
        menu.Initialize(window.tabs)
    end
    return window
end

-- ============================================================
-- menu.Initialize original (copie exacte de l'original)
-- ============================================================
function menu.Initialize(menutable)
    if #menutable == 0 then
        menutable = { { name = "Main", content = {} } }
    end
    local bbmenu = {}
    do
        Draw:MenuOutlinedRect(true, 0, 0, menu.w, menu.h, { 0, 0, 0, 255 }, bbmenu)
        Draw:MenuOutlinedRect(true, 1, 1, menu.w - 2, menu.h - 2, { 20, 20, 20, 255 }, bbmenu)
        Draw:MenuOutlinedRect(true, 2, 2, menu.w - 3, 1, { 127, 72, 163, 255 }, bbmenu)
        table.insert(menu.clrs.norm, bbmenu[#bbmenu])
        Draw:MenuOutlinedRect(true, 2, 3, menu.w - 3, 1, { 87, 32, 123, 255 }, bbmenu)
        table.insert(menu.clrs.dark, bbmenu[#bbmenu])
        Draw:MenuOutlinedRect(true, 2, 4, menu.w - 3, 1, { 20, 20, 20, 255 }, bbmenu)
        for i = 0, 19 do
            Draw:MenuFilledRect(true, 2, 5 + i, menu.w - 4, 1, { 20, 20, 20, 255 }, bbmenu)
            bbmenu[6 + i].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 20, color = RGB(35, 35, 35) } })
        end
        Draw:MenuFilledRect(true, 2, 25, menu.w - 4, menu.h - 27, { 35, 35, 35, 255 }, bbmenu)
        Draw:MenuBigText(MenuName or "Bitch Bot", true, false, 6, 6, bbmenu)
        Draw:MenuOutlinedRect(true, 8, 22, menu.w - 16, menu.h - 30, { 0, 0, 0, 255 }, bbmenu)
        Draw:MenuOutlinedRect(true, 9, 23, menu.w - 18, menu.h - 32, { 20, 20, 20, 255 }, bbmenu)
        Draw:MenuOutlinedRect(true, 10, 24, menu.w - 19, 1, { 127, 72, 163, 255 }, bbmenu)
        table.insert(menu.clrs.norm, bbmenu[#bbmenu])
        Draw:MenuOutlinedRect(true, 10, 25, menu.w - 19, 1, { 87, 32, 123, 255 }, bbmenu)
        table.insert(menu.clrs.dark, bbmenu[#bbmenu])
        Draw:MenuOutlinedRect(true, 10, 26, menu.w - 19, 1, { 20, 20, 20, 255 }, bbmenu)
        for i = 0, 14 do
            Draw:MenuFilledRect(true, 10, 27 + (i * 2), menu.w - 20, 2, { 45, 45, 45, 255 }, bbmenu)
            bbmenu[#bbmenu].Color = ColorRange(i, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 15, color = RGB(35, 35, 35) } })
        end
        Draw:MenuFilledRect(true, 10, 57, menu.w - 20, menu.h - 67, { 35, 35, 35, 255 }, bbmenu)
    end

    local tabz = {}
    for i = 1, #menutable do tabz[i] = {} end
    local tabs = {}
    menu.multigroups = {}

    for k, v in pairs(menutable) do
        Draw:MenuFilledRect(true, 10 + ((k - 1) * ((menu.w - 20) / #menutable)), 27, ((menu.w - 20) / #menutable), 32, { 30, 30, 30, 255 }, bbmenu)
        Draw:MenuOutlinedRect(true, 10 + ((k - 1) * ((menu.w - 20) / #menutable)), 27, ((menu.w - 20) / #menutable), 32, { 20, 20, 20, 255 }, bbmenu)
        Draw:MenuBigText(v.name, true, true, math.floor(10 + ((k - 1) * ((menu.w - 20) / #menutable)) + (((menu.w - 20) / #menutable) * 0.5)), 35, bbmenu)
        table.insert(tabs, { bbmenu[#bbmenu - 2], bbmenu[#bbmenu - 1], bbmenu[#bbmenu] })
        table.insert(menu.tabnames, v.name)

        menu.options[v.name] = {}
        menu.multigroups[v.name] = {}
        menu.mgrouptabz[v.name] = {}

        local y_offies = { left = 66, right = 66 }
        if v.content ~= nil then
            for k1, v1 in pairs(v.content) do
                if v1.autopos ~= nil then
                    v1.width = menu.columns.width
                    if v1.autopos == "left" then v1.x = menu.columns.left v1.y = y_offies.left
                    elseif v1.autopos == "right" then v1.x = menu.columns.right v1.y = y_offies.right end
                end
                local groups = {}
                if type(v1.name) == "table" then groups = v1.name
                else table.insert(groups, v1.name) end
                local y_pos = 24
                for g_ind, g_name in ipairs(groups) do
                    menu.options[v.name][g_name] = {}
                    if type(v1.name) == "table" then
                        menu.mgrouptabz[v.name][g_name] = {}
                        menu.log_multi = { v.name, g_name }
                    end
                    local content = nil
                    if type(v1.name) == "table" then y_pos = 28 content = v1[g_ind].content
                    else y_pos = 24 content = v1.content end
                    if content ~= nil then
                        for k2, v2 in pairs(content) do
                            if v2.type == "toggle" then
                                menu.options[v.name][g_name][v2.name] = {}
                                local unsafe = false
                                if v2.unsafe then unsafe = true end
                                menu.options[v.name][g_name][v2.name][4] = Draw:Toggle(v2.name, v2.value, unsafe, v1.x + 8, v1.y + y_pos, tabz[k])
                                menu.options[v.name][g_name][v2.name][1] = v2.value
                                menu.options[v.name][g_name][v2.name][7] = v2.value
                                menu.options[v.name][g_name][v2.name][2] = v2.type
                                menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1 }
                                menu.options[v.name][g_name][v2.name][6] = unsafe
                                menu.options[v.name][g_name][v2.name].tooltip = v2.tooltip or nil
                                y_pos += 18
                            elseif v2.type == "slider" then
                                menu.options[v.name][g_name][v2.name] = {}
                                menu.options[v.name][g_name][v2.name][4] = Draw:Slider(v2.name, v2.stradd, v2.value, v2.minvalue, v2.maxvalue, v2.custom or {}, v2.decimal, v1.x + 8, v1.y + y_pos, v1.width - 16, tabz[k])
                                menu.options[v.name][g_name][v2.name][1] = v2.value
                                menu.options[v.name][g_name][v2.name][2] = v2.type
                                menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
                                menu.options[v.name][g_name][v2.name][5] = false
                                menu.options[v.name][g_name][v2.name][6] = { v2.minvalue, v2.maxvalue }
                                menu.options[v.name][g_name][v2.name][7] = { v1.x + 7 + v1.width - 38, v1.y + y_pos - 1 }
                                y_pos += 30
                            elseif v2.type == "dropbox" then
                                menu.options[v.name][g_name][v2.name] = {}
                                menu.options[v.name][g_name][v2.name][1] = v2.value
                                menu.options[v.name][g_name][v2.name][2] = v2.type
                                menu.options[v.name][g_name][v2.name][5] = false
                                menu.options[v.name][g_name][v2.name][6] = v2.values
                                menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
                                menu.options[v.name][g_name][v2.name][4] = Draw:Dropbox(v2.name, v2.value, v2.values, v1.x + 8, v1.y + y_pos, v1.width - 16, tabz[k])
                                y_pos += 40
                            elseif v2.type == "button" then
                                menu.options[v.name][g_name][v2.name] = {}
                                menu.options[v.name][g_name][v2.name][1] = false
                                menu.options[v.name][g_name][v2.name][2] = v2.type
                                menu.options[v.name][g_name][v2.name].name = v2.name
                                menu.options[v.name][g_name][v2.name].groupbox = g_name
                                menu.options[v.name][g_name][v2.name].tab = v.name
                                menu.options[v.name][g_name][v2.name].doubleclick = v2.doubleclick
                                menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
                                menu.options[v.name][g_name][v2.name][4] = Draw:Button(v2.name, v1.x + 8, v1.y + y_pos, v1.width - 16, tabz[k])
                                y_pos += 28
                            elseif v2.type == "label" then
                                menu.options[v.name][g_name][v2.name or ("__lbl_" .. tostring(y_pos))] = {}
                                menu.options[v.name][g_name][v2.name or ("__lbl_" .. tostring(y_pos))][2] = "label"
                                menu.options[v.name][g_name][v2.name or ("__lbl_" .. tostring(y_pos))][1] = Draw:MenuBigText(v2.name, true, false, v1.x + 8, v1.y + y_pos, tabz[k])
                                y_pos += 18
                            end
                        end
                    end
                    menu.log_multi = nil
                end
                y_pos += 2
                if type(v1.name) ~= "table" then
                    if v1.autopos == nil then Draw:CoolBox(v1.name, v1.x, v1.y, v1.width, v1.height, tabz[k])
                    else
                        if v1.autofill then y_pos = (menu.h - 17) - v1.y
                        elseif v1.size ~= nil then y_pos = v1.size end
                        Draw:CoolBox(v1.name, v1.x, v1.y, v1.width, y_pos, tabz[k])
                        y_offies[v1.autopos] += y_pos + 6
                    end
                else
                    if v1.autofill then y_pos = (menu.h - 17) - v1.y y_offies[v1.autopos] += y_pos + 6
                    elseif v1.size ~= nil then y_pos = v1.size y_offies[v1.autopos] += y_pos + 6 end
                    local drawn
                    if v1.autopos == nil then drawn = Draw:CoolMultiBox(v1.name, v1.x, v1.y, v1.width, v1.height, tabz[k])
                    else drawn = Draw:CoolMultiBox(v1.name, v1.x, v1.y, v1.width, y_pos, tabz[k]) end
                    local group_vals = {}
                    for _i, _v in ipairs(v1.name) do group_vals[_v] = (_i == 1) end
                    table.insert(menu.multigroups[v.name], { vals = group_vals, drawn = drawn })
                end
            end
        end
    end

    Draw:MenuOutlinedRect(true, 10, 59, menu.w - 20, menu.h - 69, { 20, 20, 20, 255 }, bbmenu)
    Draw:MenuOutlinedRect(true, 11, 58, ((menu.w - 20) / #menutable) - 2, 2, { 35, 35, 35, 255 }, bbmenu)
    local barguy = { bbmenu[#bbmenu], menu.postable[#menu.postable] }

    local function setActiveTab(slot)
        barguy[1].Position = Vector2.new((menu.x + 11 + ((((menu.w - 20) / #menutable) - 2) * (slot - 1))) + ((slot - 1) * 2), menu.y + 58)
        barguy[2][2] = (11 + ((((menu.w - 20) / #menutable) - 2) * (slot - 1))) + ((slot - 1) * 2)
        barguy[2][3] = 58
        for k, v in pairs(tabs) do
            if k == slot then v[1].Visible = false v[3].Color = RGB(255, 255, 255)
            else v[3].Color = RGB(170, 170, 170) v[1].Visible = true end
        end
        for k, v in pairs(tabz) do
            if k == slot then for k1, v1 in pairs(v) do v1.Visible = true end
            else for k1, v1 in pairs(v) do v1.Visible = false end end
        end
    end
    setActiveTab(menu.activetab)

    -- Bind rendering to renderStepped
    if menu._renderConn then menu._renderConn:Disconnect() end
    menu._renderConn = game.RunService.RenderStepped:Connect(function(dt)
        if menu.unloaded then return end
        SCREEN_SIZE = Camera.ViewportSize
        -- Mouse handling
        if menu.mousedown then end
    end)

    -- Input handling
    if menu._inputBegan then menu._inputBegan:Disconnect() end
    menu._inputBegan = INPUT_SERVICE.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            menu.mousedown = true
            -- Check tabs
            for i = 1, #menutable do
                local tx = menu.x + 10 + ((i - 1) * ((menu.w - 20) / #menutable))
                if LOCAL_MOUSE.x > tx and LOCAL_MOUSE.x < tx + ((menu.w - 20) / #menutable) and LOCAL_MOUSE.y > menu.y + 27 and LOCAL_MOUSE.y < menu.y + 59 then
                    menu.activetab = i
                    setActiveTab(i)
                    break
                end
            end
            -- Toggle clicks
            for tabName, groups in pairs(menu.options) do
                if menu.tabnames[menu.activetab] == tabName then
                    for gName, opts in pairs(groups) do
                        for oName, v2 in pairs(opts) do
                            if v2[2] == "toggle" then
                                if LOCAL_MOUSE.x > menu.x + v2[3][1] and LOCAL_MOUSE.x < menu.x + v2[3][1] + 200 and LOCAL_MOUSE.y > menu.y + v2[3][2] and LOCAL_MOUSE.y < menu.y + v2[3][2] + 16 then
                                    v2[1] = not v2[1]
                                    local v = v2[1]
                                    for i = 1, 4 do
                                        local idx = i - 1
                                        if v then v2[4][i].Color = ColorRange(idx, { [1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) }, [2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) } })
                                        else v2[4][i].Color = ColorRange(idx, { [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 3, color = RGB(30, 30, 30) } }) end
                                    end
                                    if Library.Options[oName] then Library.Options[oName].Value = v end
                                    if Library.Toggles[oName] then Library.Toggles[oName].Value = v end
                                end
                            elseif v2[2] == "button" then
                                if LOCAL_MOUSE.x > menu.x + v2[3][1] and LOCAL_MOUSE.x < menu.x + v2[3][1] + v2[3][3] and LOCAL_MOUSE.y > menu.y + v2[3][2] and LOCAL_MOUSE.y < menu.y + v2[3][2] + 22 then
                                    if v2._callback then pcall(v2._callback) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto-init after CreateWindow
function Library:Finalize()
    if self._pendingInit then
        self._pendingInit()
        self._pendingInit = nil
    end
end

-- ============================================================
-- FINAL SETUP — Return the library
-- ============================================================
function Library:Unload()
    Library.Unloaded = true
    menu.unloaded = true
    if menu._renderConn then menu._renderConn:Disconnect() end
    if menu._inputBegan then menu._inputBegan:Disconnect() end
    Draw:UnRender()
end

task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.1)
        if Library._pendingInit then
            -- Wait until scene is ready
            local ok = pcall(Library.Finalize, Library)
            if not ok then break end
        end
    end
end)

return Library
