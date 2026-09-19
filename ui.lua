-- ============================================================
-- BitchBot UI Library v2
-- Usage: local Library = loadstring(game:HttpGet("URL"))()
-- ============================================================
local Library = {}
Library.Options = {}
Library.Toggles = {}
Library.Unloaded = false
getgenv().Options = Library.Options
getgenv().Toggles = Library.Toggles

-- ============================================================
-- SERVICES
-- ============================================================
local Players     = game:GetService("Players")
local UserInput   = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local GuiService  = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local INSET = Vector2.new(0, 0)
pcall(function() INSET = GuiService:GetGuiInset() end)

-- ============================================================
-- STATE
-- ============================================================
local ACCENT      = Color3.fromRGB(127, 72, 163)
local ACCENT_DARK = Color3.fromRGB(87, 32, 123)

local MOUSE  = Vector2.new()
local SCREEN = Camera.ViewportSize
local mouseConn = RunService.RenderStepped:Connect(function()
    local loc = UserInput:GetMouseLocation()
    MOUSE  = Vector2.new(loc.X, loc.Y)
    SCREEN = Camera.ViewportSize
end)

-- ============================================================
-- DRAW HELPERS + REGISTRY
-- ============================================================
local ALL_DRAWINGS = {}

local function reg(d, visibleIf)
    d.Visible = true
    d._visibleIf = visibleIf or function() return true end
    d._explicitlyHidden = false
    table.insert(ALL_DRAWINGS, d)
    return d
end

local function drawRect(filled, x, y, w, h, color, trans, visibleIf)
    local d = Drawing.new("Square")
    d.Filled = filled
    d.Position = Vector2.new(x, y)
    d.Size = Vector2.new(w, h)
    d.Color = color
    d.Transparency = trans or 1
    d.Thickness = 1
    return reg(d, visibleIf)
end

local function drawText(txt, x, y, size, color, center, visibleIf)
    local d = Drawing.new("Text")
    d.Text = txt
    d.Position = Vector2.new(x, y)
    d.Size = size or 13
    d.Color = color or Color3.new(1, 1, 1)
    d.Center = center or false
    d.Outline = true
    d.OutlineColor = Color3.new(0, 0, 0)
    d.Font = 2
    return reg(d, visibleIf)
end

local function drawTriangle(x1, y1, x2, y2, x3, y3, color, visibleIf)
    local d = Drawing.new("Triangle")
    d.PointA = Vector2.new(x1, y1)
    d.PointB = Vector2.new(x2, y2)
    d.PointC = Vector2.new(x3, y3)
    d.Color = color
    d.Filled = true
    return reg(d, visibleIf)
end

local function cleanupDrawings()
    for _, d in ipairs(ALL_DRAWINGS) do
        pcall(function() d:Remove() end)
    end
    ALL_DRAWINGS = {}
end

-- Global render loop : updates visibility on all drawings
local renderLoop = RunService.RenderStepped:Connect(function()
    for _, d in ipairs(ALL_DRAWINGS) do
        if d._explicitlyHidden then
            d.Visible = false
        else
            local ok, v = pcall(d._visibleIf)
            d.Visible = ok and v or false
        end
    end
end)

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local NOTIFS = {}
local notifConn = nil

function Library:Notify(text, duration)
    duration = duration or 4
    local n = {
        text = text,
        start = tick(),
        duration = duration,
        bg   = drawRect(true, 0, 0, 300, 26, Color3.fromRGB(20, 20, 20)),
        bar  = drawRect(true, 0, 0, 3, 26, ACCENT),
        lbl  = drawText(text, 0, 0, 13, Color3.new(1, 1, 1)),
        out  = drawRect(false, 0, 0, 302, 28, Color3.new(0, 0, 0)),
    }
    table.insert(NOTIFS, n)

    if not notifConn then
        notifConn = RunService.RenderStepped:Connect(function()
            local now = tick()
            local y = 40
            for i = #NOTIFS, 1, -1 do
                local n = NOTIFS[i]
                local age = now - n.start
                if age > n.duration then
                    n.bg:Remove() n.bar:Remove() n.lbl:Remove() n.out:Remove()
                    table.remove(NOTIFS, i)
                else
                    local alpha = 1
                    if age > n.duration - 1 then alpha = n.duration - age end
                    local x = 20
                    n.bg.Position  = Vector2.new(x, y)
                    n.bar.Position = Vector2.new(x, y)
                    n.lbl.Position = Vector2.new(x + 10, y + 5)
                    n.out.Position = Vector2.new(x - 1, y - 1)
                    n.bg.Transparency  = alpha * 0.15
                    n.bar.Transparency = alpha
                    n.lbl.Transparency = alpha
                    n.out.Transparency = alpha * 0.3
                    y = y + 32
                end
            end
        end)
    end
end

-- ============================================================
-- UTIL
-- ============================================================
local function inRegion(x, y, w, h)
    return MOUSE.X > x and MOUSE.X < x + w and MOUSE.Y > y and MOUSE.Y < y + h
end

local function fmtNum(n)
    if n == math.floor(n) then return tostring(math.floor(n)) end
    return string.format("%.2f", n)
end

-- ============================================================
-- ELEMENT FACTORIES
-- ============================================================
local Elements = {}

-- Toggle ------------------------------------------------------
function Elements.Toggle(parent, idx, opts)
    opts = opts or {}
    local val = opts.Default == true
    local y   = parent:_nextY()
    local boxX = parent._x + 8
    local visIf = parent:_visIf()

    local bg  = drawRect(false, boxX, y, 12, 12, Color3.fromRGB(30, 30, 30), 1, visIf)
    local bg2 = drawRect(false, boxX + 1, y + 1, 10, 10, Color3.new(0, 0, 0), 1, visIf)
    local fil = drawRect(true,  boxX + 2, y + 2, 8, 8, val and ACCENT or Color3.new(0, 0, 0), 1, visIf)
    local lbl = drawText(opts.Text or idx, boxX + 20, y, 13, Color3.new(1, 1, 1), false, visIf)

    local obj = { Value = val, _parent = parent, _idx = idx, _type = "Toggle" }

    function obj:SetValue(v)
        self.Value = v == true
        fil.Color = self.Value and ACCENT or Color3.new(0, 0, 0)
        if self._onChanged then self._onChanged(self.Value) end
    end
    function obj:OnChanged(fn) self._onChanged = fn end
    if opts.Callback then obj:OnChanged(opts.Callback) end

    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visIf() then return end
        if inRegion(boxX, y - 2, 200, 16) then
            obj:SetValue(not obj.Value)
        end
    end)

    parent:_pushOption(idx, obj, y)
    return obj
end

-- Slider ------------------------------------------------------
function Elements.Slider(parent, idx, opts)
    opts = opts or {}
    local min  = opts.Min or 0
    local max  = opts.Max or 100
    local rnd  = opts.Rounding or 0
    local val  = math.clamp(opts.Default or min, min, max)
    local y    = parent:_nextY()
    local visIf = parent:_visIf()

    local lbl  = drawText(opts.Text or idx, parent._x + 8, y, 13, Color3.new(1, 1, 1), false, visIf)
    local tx = parent._x + 8
    local tw = parent._width - 16
    local ty = y + 18

    local track = drawRect(true, tx, ty, tw, 4, Color3.fromRGB(30, 30, 30), 1, visIf)
    local fill  = drawRect(true, tx, ty, 0, 4, ACCENT, 1, visIf)
    local valLbl= drawText(fmtNum(val), tx + tw/2, ty - 2, 13, Color3.new(1, 1, 1), true, visIf)

    local obj = { Value = val, _parent = parent, _idx = idx, _type = "Slider" }

    local function apply()
        local w = tw * ((obj.Value - min) / (max - min))
        fill.Size = Vector2.new(w, 4)
        valLbl.Text = fmtNum(obj.Value)
    end

    function obj:SetValue(v)
        local nv = math.clamp(tonumber(v) or self.Value, min, max)
        if rnd > 0 then
            local m = 10 ^ rnd
            nv = math.floor(nv * m + 0.5) / m
        else
            nv = math.floor(nv)
        end
        self.Value = nv
        apply()
        if self._onChanged then self._onChanged(self.Value) end
    end
    function obj:OnChanged(fn) self._onChanged = fn end
    if opts.Callback then obj:OnChanged(opts.Callback) end
    apply()

    local dragging = false
    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visIf() then return end
        if inRegion(tx, ty - 6, tw, 16) then dragging = true end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local pct = math.clamp((MOUSE.X - tx) / tw, 0, 1)
            obj:SetValue(min + (max - min) * pct)
        end
    end)

    parent:_pushOption(idx, obj, y, 40)
    return obj
end

-- Dropdown ----------------------------------------------------
function Elements.Dropdown(parent, idx, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local val    = opts.Default or 1
    local multi  = opts.Multi == true
    local y      = parent:_nextY()
    local visIf  = parent:_visIf()

    local lbl  = drawText(opts.Text or idx, parent._x + 8, y, 13, Color3.new(1, 1, 1), false, visIf)
    local bx   = parent._x + 8
    local by   = y + 16
    local bw   = parent._width - 16

    local bg   = drawRect(true,  bx, by, bw, 22, Color3.fromRGB(30, 30, 30), 1, visIf)
    local valT = drawText("", bx + 6, by + 4, 13, Color3.new(1, 1, 1), false, visIf)
    local ind  = drawText("v", bx + bw - 16, by + 4, 13, ACCENT, false, visIf)

    local obj = { Value = multi and {} or (type(val) == "number" and values[val] or val), _parent = parent, _idx = idx, _type = "Dropdown", _multi = multi, _values = values }

    local function updateLabel()
        if multi then
            local parts = {}
            for k, v in pairs(obj.Value) do if v then table.insert(parts, k) end end
            valT.Text = #parts > 0 and table.concat(parts, ", ") or "None"
        else
            valT.Text = tostring(obj.Value or "None")
        end
    end

    local popupDrawings = {}
    local popupOpen = false

    local function buildPopup()
        for _, d in ipairs(popupDrawings) do pcall(function() d:Remove() end) end
        popupDrawings = {}

        local n = #values
        local ph = 22 * n + 6
        local px = bx
        local py = by + 24

        local vis = function() return visIf() and popupOpen end
        table.insert(popupDrawings, drawRect(true, px, py, bw, ph, Color3.fromRGB(20, 20, 20), 1, vis))
        table.insert(popupDrawings, drawRect(false, px - 1, py - 1, bw + 2, ph + 2, Color3.new(0, 0, 0), 1, vis))

        for i, v in ipairs(values) do
            local iy = py + 3 + (i - 1) * 22
            local isSel = (not multi and obj.Value == v) or (multi and obj.Value[v])
            local txt = drawText(tostring(v), px + 8, iy + 3, 13, isSel and ACCENT or Color3.new(1, 1, 1), false, vis)
            table.insert(popupDrawings, txt)

            UserInput.InputBegan:Connect(function(input, gp)
                if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if not vis() then return end
                if inRegion(px, iy, bw, 22) then
                    if multi then
                        obj.Value[v] = not obj.Value[v]
                        buildPopup()
                        updateLabel()
                        if obj._onChanged then obj._onChanged(obj.Value) end
                    else
                        obj:SetValue(v)
                        popupOpen = false
                    end
                end
            end)
        end
    end

    function obj:SetValue(v)
        if multi then
            if type(v) == "table" then self.Value = v end
        else
            if type(v) == "number" then self.Value = values[v] else self.Value = v end
        end
        updateLabel()
        if self._onChanged then self._onChanged(self.Value) end
    end
    function obj:OnChanged(fn) self._onChanged = fn end
    if opts.Callback then obj:OnChanged(opts.Callback) end

    if multi then
        for _, v in ipairs(values) do obj.Value[v] = false end
    end
    updateLabel()

    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visIf() then return end
        if inRegion(bx, by, bw, 22) then
            popupOpen = not popupOpen
            if popupOpen then buildPopup() end
        end
    end)

    parent:_pushOption(idx, obj, y, 44)
    return obj
end

-- Input -------------------------------------------------------
function Elements.Input(parent, idx, opts)
    opts = opts or {}
    local val = opts.Default or ""
    local y   = parent:_nextY()
    local visIf = parent:_visIf()

    local lbl = drawText(opts.Text or idx, parent._x + 8, y, 13, Color3.new(1, 1, 1), false, visIf)
    local bx = parent._x + 8
    local by = y + 16
    local bw = parent._width - 16

    local bg  = drawRect(true, bx, by, bw, 22, Color3.fromRGB(30, 30, 30), 1, visIf)
    local vl  = drawText(val, bx + 6, by + 4, 13, Color3.new(1, 1, 1), false, visIf)

    local obj = { Value = val, _parent = parent, _idx = idx, _type = "Input", _focused = false, _numeric = opts.Numeric == true }

    function obj:SetValue(v)
        self.Value = tostring(v or "")
        vl.Text = self.Value
        if self._onChanged then self._onChanged(self.Value) end
    end
    function obj:OnChanged(fn) self._onChanged = fn end
    if opts.Callback then obj:OnChanged(opts.Callback) end

    UserInput.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and visIf() and inRegion(bx, by, bw, 22) then
            obj._focused = true
            bg.Color = ACCENT
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Keyboard then
            obj._focused = false
            bg.Color = Color3.fromRGB(30, 30, 30)
        end
    end)

    UserInput.InputBegan:Connect(function(input, gp)
        if not obj._focused then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Backspace then
            obj.Value = obj.Value:sub(1, -2)
        elseif kc == Enum.KeyCode.Space then
            obj.Value = obj.Value .. " "
        elseif kc == Enum.KeyCode.Return then
            obj._focused = false
            bg.Color = Color3.fromRGB(30, 30, 30)
        else
            local name = kc.Name
            if #name == 1 then
                local shift = UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or UserInput:IsKeyDown(Enum.KeyCode.RightShift)
                obj.Value = obj.Value .. (shift and name:upper() or name:lower())
            elseif kc == Enum.KeyCode.One then obj.Value = obj.Value .. "1"
            elseif kc == Enum.KeyCode.Two then obj.Value = obj.Value .. "2"
            elseif kc == Enum.KeyCode.Three then obj.Value = obj.Value .. "3"
            elseif kc == Enum.KeyCode.Four then obj.Value = obj.Value .. "4"
            elseif kc == Enum.KeyCode.Five then obj.Value = obj.Value .. "5"
            elseif kc == Enum.KeyCode.Six then obj.Value = obj.Value .. "6"
            elseif kc == Enum.KeyCode.Seven then obj.Value = obj.Value .. "7"
            elseif kc == Enum.KeyCode.Eight then obj.Value = obj.Value .. "8"
            elseif kc == Enum.KeyCode.Nine then obj.Value = obj.Value .. "9"
            elseif kc == Enum.KeyCode.Zero then obj.Value = obj.Value .. "0"
            end
        end
        vl.Text = obj.Value .. (obj._focused and "|" or "")
        if obj._onChanged then obj._onChanged(obj.Value) end
    end)

    parent:_pushOption(idx, obj, y, 44)
    return obj
end

-- Button ------------------------------------------------------
function Elements.Button(parent, idxOrOpts, opts)
    local txt, fn, dc
    if type(idxOrOpts) == "table" then
        txt = idxOrOpts.Text or "Button"
        fn  = idxOrOpts.Func
        dc  = idxOrOpts.DoubleClick == true
    else
        txt = idxOrOpts
        fn  = type(opts) == "function" and opts or nil
    end

    local y = parent:_nextY()
    local visIf = parent:_visIf()
    local bx = parent._x + 8
    local by = y
    local bw = parent._width - 16

    local bg  = drawRect(true, bx, by, bw, 22, Color3.fromRGB(50, 50, 50), 1, visIf)
    local lbl = drawText(txt, bx + bw/2, by + 4, 13, Color3.new(1, 1, 1), true, visIf)

    local lastClick = 0
    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visIf() then return end
        if inRegion(bx, by, bw, 22) then
            bg.Color = ACCENT
            task.delay(0.15, function() bg.Color = Color3.fromRGB(50, 50, 50) end)
            if dc then
                if tick() - lastClick < 0.5 then
                    lastClick = 0
                    if fn then pcall(fn) end
                else
                    lastClick = tick()
                end
            else
                if fn then pcall(fn) end
            end
        end
    end)

    parent:_pushOption("__btn_" .. tostring(y), nil, y, 28)
    return { _bg = bg, _lbl = lbl }
end

-- Label -------------------------------------------------------
function Elements.Label(parent, text, wrap)
    local y = parent:_nextY()
    local visIf = parent:_visIf()
    local lbl = drawText(text, parent._x + 8, y, 13, Color3.new(1, 1, 1), false, visIf)
    local h = wrap and 60 or 18
    parent:_pushOption("__lbl_" .. tostring(y), nil, y, h)
    return { _lbl = lbl }
end

-- Divider -----------------------------------------------------
function Elements.Divider(parent)
    local y = parent:_nextY()
    local visIf = parent:_visIf()
    drawRect(true, parent._x + 8, y + 6, parent._width - 16, 1, Color3.fromRGB(60, 60, 60), 1, visIf)
    parent:_pushOption("__div_" .. tostring(y), nil, y, 16)
end

-- ============================================================
-- COLOR PICKER (attached to Label)
-- ============================================================
function Library:_openColorPicker(idx, opts, label)
    local val = opts.Default or Color3.fromRGB(255, 255, 255)
    local alpha = opts.Transparency and (opts.Default and opts.Default.A or 0) or nil

    -- popup drawings
    local px, py = MOUSE.X + 10, MOUSE.Y + 10
    local pw, ph = 220, 190 + (opts.Transparency and 30 or 0)

    local popup = {}
    local visible = true
    local visIf = function() return visible end

    table.insert(popup, drawRect(true,  px, py, pw, ph, Color3.fromRGB(20, 20, 20), 1, visIf))
    table.insert(popup, drawRect(false, px - 1, py - 1, pw + 2, ph + 2, Color3.new(0, 0, 0), 1, visIf))
    table.insert(popup, drawText(opts.Title or idx, px + 8, py + 4, 13, Color3.new(1, 1, 1), false, visIf))
    table.insert(popup, drawText("X", px + pw - 18, py + 4, 13, Color3.fromRGB(255, 80, 80), false, visIf))

    -- preview
    table.insert(popup, drawRect(true, px + 8, py + 24, pw - 16, 24, val, opts.Transparency and (1 - alpha) or 1, visIf))
    table.insert(popup, drawRect(false, px + 7, py + 23, pw - 14, 26, Color3.new(0, 0, 0), 1, visIf))

    local rgb = { val.R * 255, val.G * 255, val.B * 255 }
    local alphaVal = alpha or 0

    local function updatePreview()
        local c = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
        popup[4].Color = c
        if opts.Transparency then popup[4].Transparency = 1 - alphaVal end
    end

    local sliders = {}

    local function makeSlider(name, yPos, initial, minV, maxV, onChange)
        local lbl = drawText(name, px + 8, yPos, 12, Color3.fromRGB(180, 180, 180), false, visIf)
        local track = drawRect(true, px + 8, yPos + 16, pw - 16, 4, Color3.fromRGB(40, 40, 40), 1, visIf)
        local fill  = drawRect(true, px + 8, yPos + 16, 0, 4, ACCENT, 1, visIf)
        local valL  = drawText(tostring(math.floor(initial)), px + pw/2, yPos + 14, 12, Color3.new(1,1,1), true, visIf)

        local tw = pw - 16
        local tx = px + 8
        local ty = yPos + 16
        local dragging = false

        local function setVal(v)
            v = math.clamp(v, minV, maxV)
            fill.Size = Vector2.new(tw * ((v - minV) / (maxV - minV)), 4)
            valL.Text = tostring(math.floor(v))
            onChange(v)
        end
        setVal(initial)

        table.insert(popup, lbl) table.insert(popup, track) table.insert(popup, fill) table.insert(popup, valL)
        table.insert(sliders, {tx = tx, ty = ty, tw = tw, minV = minV, maxV = maxV, set = setVal})

        return ty
    end

    local cy = py + 60
    makeSlider("R", cy, rgb[1], 0, 255, function(v) rgb[1] = v updatePreview() end) cy = cy + 36
    makeSlider("G", cy, rgb[2], 0, 255, function(v) rgb[2] = v updatePreview() end) cy = cy + 36
    makeSlider("B", cy, rgb[3], 0, 255, function(v) rgb[3] = v updatePreview() end) cy = cy + 36
    if opts.Transparency then
        makeSlider("Alpha", cy, alphaVal * 255, 0, 255, function(v) alphaVal = v / 255 updatePreview() end)
    end

    -- apply button
    local applyY = py + ph - 26
    table.insert(popup, drawRect(true, px + 8, applyY, pw - 16, 20, Color3.fromRGB(50, 50, 50), 1, visIf))
    table.insert(popup, drawText("Apply", px + pw/2, applyY + 2, 13, Color3.new(1,1,1), true, visIf))

    local function close()
        visible = false
        for _, d in ipairs(popup) do pcall(function() d:Remove() end) end
    end

    -- mouse handling
    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visible then return end
        -- slider drag
        for _, s in ipairs(sliders) do
            if inRegion(s.tx, s.ty - 6, s.tw, 16) then
                local pct = math.clamp((MOUSE.X - s.tx) / s.tw, 0, 1)
                s.set(s.minV + (s.maxV - s.minV) * pct)
            end
        end
        -- apply
        if inRegion(px + 8, applyY, pw - 16, 20) then
            local c = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            if opts.Callback then opts.Callback(c, opts.Transparency and alphaVal or nil) end
            close()
            return
        end
        -- close
        if inRegion(px + pw - 22, py + 2, 20, 20) then close() return end
        -- click outside
        if not inRegion(px, py, pw, ph) then close() end
    end)

    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then end
    end)
end

-- Attach AddColorPicker to Label
function Elements.Label(parent, text, wrap)
    local y = parent:_nextY()
    local visIf = parent:_visIf()
    local lbl = drawText(text, parent._x + 8, y, 13, Color3.new(1, 1, 1), false, visIf)
    local h = wrap and 60 or 18
    parent:_pushOption("__lbl_" .. tostring(y), nil, y, h)
    local obj = { _lbl = lbl }

    function obj:AddColorPicker(idx, opts)
        opts = opts or {}
        local cbx = parent._x + parent._width - 36
        local cby = y
        local swatch = drawRect(true, cbx, cby, 28, 14, opts.Default or Color3.new(1,1,1), 1, visIf)
        local swatch2 = drawRect(false, cbx - 1, cby - 1, 30, 16, Color3.new(0,0,0), 1, visIf)

        UserInput.InputBegan:Connect(function(input, gp)
            if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not visIf() then return end
            if inRegion(cbx, cby, 28, 14) then
                Library:_openColorPicker(idx, opts, obj)
            end
        end)

        local cp = {
            Value = opts.Default or Color3.new(1, 1, 1),
            Transparency = opts.Transparency and 0 or nil,
            _swatch = swatch,
            _idx = idx,
        }
        function cp:SetValueRGB(c)
            self.Value = c
            swatch.Color = c
            if self._onChanged then self._onChanged(c) end
        end
        function cp:OnChanged(fn) self._onChanged = fn end
        if opts.Callback then cp:OnChanged(opts.Callback) end

        Library.Options[idx] = cp
        getgenv().Options[idx] = cp
        return cp
    end

    return obj
end

-- ============================================================
-- KEY PICKER (attached to Label)
-- ============================================================
function Library:_openKeyPicker(idx, opts, label)
    local cur = opts.Default or "None"
    local mode = opts.Mode or "Toggle"
    local state = false
    local waiting = true

    local obj = {
        Value = cur,
        Mode = mode,
        _state = false,
    }

    function obj:GetState() return self._state end
    function obj:SetValue(v) self.Value = v end
    function obj:OnClick(fn) self._onClick = fn end
    function obj:OnChanged(fn) self._onChanged = fn end

    Library.Options[idx] = obj
    getgenv().Options[idx] = obj

    UserInput.InputBegan:Connect(function(input, gp)
        if not waiting then
            if input.UserInputType ~= Enum.UserInputType.Keyboard and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            -- mode handling
        end
    end)

    -- First press = bind key
    local bindConn
    bindConn = UserInput.InputBegan:Connect(function(input, gp)
        if not waiting then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            obj.Value = input.KeyCode.Name
            waiting = false
            if opts.ChangedCallback then opts.ChangedCallback(input.KeyCode) end
            Library:Notify("Keybind set to: " .. input.KeyCode.Name, 2)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            obj.Value = "MB1"
            waiting = false
            Library:Notify("Keybind set to: MB1", 2)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            obj.Value = "MB2"
            waiting = false
            Library:Notify("Keybind set to: MB2", 2)
        end
    end)

    -- Ongoing keydown tracking
    UserInput.InputBegan:Connect(function(input, gp)
        if gp or waiting then return end
        local name = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name or
                     (input.UserInputType == Enum.UserInputType.MouseButton1 and "MB1") or
                     (input.UserInputType == Enum.UserInputType.MouseButton2 and "MB2") or nil
        if not name or name ~= obj.Value then return end
        if obj.Mode == "Toggle" then
            obj._state = not obj._state
            if obj._onClick then obj._onClick() end
        elseif obj.Mode == "Hold" then
            obj._state = true
            if obj._onClick then obj._onClick() end
        elseif obj.Mode == "Always" then
            obj._state = true
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if waiting then return end
        local name = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name or
                     (input.UserInputType == Enum.UserInputType.MouseButton1 and "MB1") or
                     (input.UserInputType == Enum.UserInputType.MouseButton2 and "MB2") or nil
        if not name or name ~= obj.Value then return end
        if obj.Mode == "Hold" then obj._state = false end
    end)

    return obj
end

function Elements.Label_AddKeyPicker(label, parent, idx, opts)
    opts = opts or {}
    local keyText = opts.Default or "None"
    local kbx = parent._x + parent._width - 60
    local kby = label._lbl.Position.Y
    local visIf = parent:_visIf()

    local bg  = drawRect(true, kbx, kby, 50, 16, Color3.fromRGB(30, 30, 30), 1, visIf)
    local txt = drawText(keyText, kbx + 25, kby + 1, 12, Color3.new(1,1,1), true, visIf)
    local outline = drawRect(false, kbx - 1, kby - 1, 52, 18, Color3.new(0,0,0), 1, visIf)

    local picker = Library:_openKeyPicker(idx, opts, label)
    picker._txt = txt

    UserInput.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not visIf() then return end
        if inRegion(kbx, kby, 50, 16) then
            Library:Notify("Press any key to bind...", 2)
        end
    end)

    -- update text periodically
    task.spawn(function()
        while not Library.Unloaded do
            task.wait(0.1)
            if txt and picker then txt.Text = picker.Value or "None" end
        end
    end)

    return picker
end

-- Patch AddLabel to return keypicker-capable label
local _oldAddLabel = Elements.Label
Elements.Label = function(parent, text, wrap)
    local lbl = _oldAddLabel(parent, text, wrap)
    function lbl:AddKeyPicker(idx, opts)
        return Elements.Label_AddKeyPicker(lbl, parent, idx, opts)
    end
    return lbl
end

-- ============================================================
-- GROUPBOX
-- ============================================================
local Groupbox = {}
Groupbox.__index = Groupbox

local function makeGroup(tab, name, side)
    local g = setmetatable({}, Groupbox)
    g._tab = tab
    g._name = name
    g._side = side
    g._x = tab._parent.X + (side == "left" and 17 or (tab._parent.Width / 2 + 3))
    g._width = (tab._parent.Width - 40) / 2
    g._optionsY = 30
    g._drawings = {}
    g._optList = {}

    -- compute Y offset (stack groups on same side)
    local stackY = tab._parent.Y + 66
    for _, other in ipairs(tab._groups) do
        if other._side == side then
            stackY = stackY + other._bodySize + 6
        end
    end
    g._y = stackY

    local visIf = function() return tab:isActive() end
    g._visIfRoot = visIf

    -- header
    g._h1 = drawRect(true,  g._x, g._y, g._width, 22, Color3.fromRGB(30, 30, 30), 1, visIf)
    g._h2 = drawRect(true,  g._x + 2, g._y + 2, g._width - 4, 1, ACCENT, 1, visIf)
    g._h3 = drawRect(true,  g._x + 2, g._y + 3, g._width - 4, 1, ACCENT_DARK, 1, visIf)
    g._t  = drawText(name, g._x + 6, g._y + 5, 13, Color3.new(1, 1, 1), false, visIf)

    g._body = drawRect(true, g._x, g._y + 22, g._width, 30, Color3.fromRGB(40, 40, 40), 1, visIf)
    g._bodySize = 30

    table.insert(tab._groups, g)
    return g
end

function Groupbox:_visIf()
    return self._visIfRoot
end

function Groupbox:_nextY()
    return self._y + self._optionsY
end

function Groupbox:_pushOption(idx, obj, y, h)
    h = h or 22
    self._optionsY = self._optionsY + h
    self._bodySize = self._optionsY + 6
    self._body.Size = Vector2.new(self._width, self._bodySize - 22)
    if idx and obj then table.insert(self._optList, { idx = idx, obj = obj }) end
end

function Groupbox:AddToggle(idx, opts) return Elements.Toggle(self, idx, opts) end
function Groupbox:AddSlider(idx, opts) return Elements.Slider(self, idx, opts) end
function Groupbox:AddDropdown(idx, opts) return Elements.Dropdown(self, idx, opts) end
function Groupbox:AddInput(idx, opts) return Elements.Input(self, idx, opts) end
function Groupbox:AddButton(a, b) return Elements.Button(self, a, b) end
function Groupbox:AddLabel(t, w) return Elements.Label(self, t, w) end
function Groupbox:AddDivider() return Elements.Divider(self) end

function Groupbox:AddDependencyBox()
    local parent = self
    local Depbox = {}

    -- 🔑 Copie directe des propriétés du parent (fix du nil + number)
    Depbox._parent = parent
    Depbox._conditions = {}
    Depbox._x = parent._x
    Depbox._y = parent._y
    Depbox._width = parent._width
    Depbox._bodySize = parent._bodySize
    Depbox._visIfRoot = parent._visIfRoot

    function Depbox:_visIf()
        for _, cond in ipairs(Depbox._conditions) do
            local tgl, want = cond[1], cond[2]
            if tgl.Value ~= want then return false end
        end
        return parent:_visIf()
    end

    function Depbox:_nextY()
        return parent:_nextY()
    end

    function Depbox:_pushOption(idx, obj, y, h)
        h = h or 22
        parent._optionsY = parent._optionsY + h
        parent._bodySize = parent._optionsY + 6
        parent._body.Size = Vector2.new(parent._width, parent._bodySize - 22)
        if idx and obj then
            table.insert(parent._optList, { idx = idx, obj = obj })
        end
    end

    function Depbox:AddToggle(idx, opts)   return Elements.Toggle(Depbox, idx, opts)   end
    function Depbox:AddSlider(idx, opts)   return Elements.Slider(Depbox, idx, opts)   end
    function Depbox:AddDropdown(idx, opts) return Elements.Dropdown(Depbox, idx, opts) end
    function Depbox:AddInput(idx, opts)    return Elements.Input(Depbox, idx, opts)    end
    function Depbox:AddButton(a, b)        return Elements.Button(Depbox, a, b)        end
    function Depbox:AddLabel(t, w)         return Elements.Label(Depbox, t, w)         end
    function Depbox:AddDivider()           return Elements.Divider(Depbox)             end

    function Depbox:SetupDependencies(deps)
        Depbox._conditions = deps or {}
    end

    return Depbox
end

-- ============================================================
-- TAB
-- ============================================================
local Tab = {}
Tab.__index = Tab

local function makeTab(window, name)
    local t = setmetatable({}, Tab)
    t._parent = window
    t._name = name
    t._groups = {}
    t._active = (#window.Tabs == 0)
    t._btn = {}

    table.insert(window.Tabs, t)
    window:_refreshTabButtons()
    return t
end

function Tab:isActive() return self._active end

function Tab:AddLeftGroupbox(name)  return makeGroup(self, name, "left")  end
function Tab:AddRightGroupbox(name) return makeGroup(self, name, "right") end

-- ============================================================
-- WINDOW
-- ============================================================
local Window = {}
Window.__index = Window

function Library:CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, Window)
    self.Title  = opts.Title or "Library"
    self.Width  = opts.Width or 500
    self.Height = opts.Height or 600
    self.X      = math.floor((SCREEN.X - self.Width) / 2)
    self.Y      = math.floor((SCREEN.Y - self.Height) / 2)
    self.Tabs   = {}
    self.ActiveTab = 1
    self.Open   = opts.AutoShow ~= false
    self.Dragging = false
    self.DragOff  = Vector2.new()
    self._btnDrawings = {}

    self:_buildBg()
    self:_bindInput()

    Library.Window = self
    return self
end

function Window:_buildBg()
    local visIf = function() return true end
    self._bg1 = drawRect(true, self.X, self.Y, self.Width, self.Height, Color3.fromRGB(0, 0, 0), 1, visIf)
    self._bg2 = drawRect(true, self.X + 1, self.Y + 1, self.Width - 2, self.Height - 2, Color3.fromRGB(20, 20, 20), 1, visIf)
    self._top1 = drawRect(true, self.X + 2, self.Y + 2, self.Width - 3, 1, ACCENT, 1, visIf)
    self._top2 = drawRect(true, self.X + 2, self.Y + 3, self.Width - 3, 1, ACCENT_DARK, 1, visIf)
    self._title = drawText(self.Title, self.X + 6, self.Y + 6, 14, Color3.new(1, 1, 1), false, visIf)
    self._body = drawRect(true, self.X + 10, self.Y + 59, self.Width - 20, self.Height - 69, Color3.fromRGB(35, 35, 35), 1, visIf)
    self._closeX = drawText("X", self.X + self.Width - 20, self.Y + 6, 14, Color3.fromRGB(255, 80, 80), false, visIf)
end

function Window:_refreshPositions()
    local x, y = self.X, self.Y
    self._bg1.Position   = Vector2.new(x, y)
    self._bg2.Position   = Vector2.new(x + 1, y + 1)
    self._top1.Position  = Vector2.new(x + 2, y + 2)
    self._top2.Position  = Vector2.new(x + 2, y + 3)
    self._title.Position = Vector2.new(x + 6, y + 6)
    self._body.Position  = Vector2.new(x + 10, y + 59)
    self._closeX.Position= Vector2.new(x + self.Width - 20, y + 6)

    self:_refreshTabButtons()
    for _, tab in ipairs(self.Tabs) do
        for _, g in ipairs(tab._groups) do
            local gx = self.X + (g._side == "left" and 17 or (self.Width / 2 + 3))
            g._x = gx
            -- recompute group Y (stack)
            local gY = self.Y + 66
            for _, o in ipairs(tab._groups) do
                if o._side == g._side and o ~= g then
                    gY = gY + o._bodySize + 6
                    if o == g then break end
                end
            end
            -- simpler: just move all groups uniformly
            g._y = g._y + (self.Y - self._lastY or 0)
        end
    end
    self._lastY = self.Y
end

function Window:_refreshTabButtons()
    local w = (self.Width - 20) / math.max(1, #self.Tabs)
    for i, tab in ipairs(self.Tabs) do
        local x = self.X + 10 + (i - 1) * w
        if not tab._btn.bg then
            tab._btn.bg   = drawRect(true, x, self.Y + 27, w, 32, Color3.fromRGB(30, 30, 30), 1)
            tab._btn.line = drawRect(true, x, self.Y + 27, w, 1, ACCENT, 1)
            tab._btn.txt  = drawText(tab._name, x + w/2, self.Y + 36, 13, Color3.new(1, 1, 1), true)
        else
            tab._btn.bg.Position   = Vector2.new(x, self.Y + 27)
            tab._btn.bg.Size       = Vector2.new(w, 32)
            tab._btn.line.Position = Vector2.new(x, self.Y + 27)
            tab._btn.line.Size     = Vector2.new(w, 1)
            tab._btn.txt.Position  = Vector2.new(x + w/2, self.Y + 36)
        end
    end
end

function Window:_bindInput()
    local self_ = self
    UserInput.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        -- close button
        if MOUSE.X > self_.X + self_.Width - 26 and MOUSE.X < self_.X + self_.Width - 4
            and MOUSE.Y > self_.Y + 4 and MOUSE.Y < self_.Y + 24 then
            Library:Unload()
            return
        end
        -- title drag
        if MOUSE.X > self_.X and MOUSE.X < self_.X + self_.Width - 30
            and MOUSE.Y > self_.Y and MOUSE.Y < self_.Y + 25 then
            self_.Dragging = true
            self_.DragOff = Vector2.new(MOUSE.X - self_.X, MOUSE.Y - self_.Y)
        end
        -- tab switch
        local w = (self_.Width - 20) / math.max(1, #self_.Tabs)
        for i, tab in ipairs(self_.Tabs) do
            local tx = self_.X + 10 + (i - 1) * w
            if inRegion(tx, self_.Y + 27, w, 32) then
                self_:_switchTab(i)
                break
            end
        end
    end)

    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self_.Dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if self_.Dragging then
            self_.X = MOUSE.X - self_.DragOff.X
            self_.Y = MOUSE.Y - self_.DragOff.Y
            self_:_refreshPositions()
        end
    end)
end

function Window:_switchTab(idx)
    self.ActiveTab = idx
    for i, tab in ipairs(self.Tabs) do
        tab._active = (i == idx)
        tab._btn.txt.Color = tab._active and Color3.new(1, 1, 1) or Color3.fromRGB(170, 170, 170)
    end
end

function Window:AddTab(name)
    return makeTab(self, name)
end

-- ============================================================
-- SAVE MANAGER
-- ============================================================
local SaveManager = {}
SaveManager.__index = SaveManager
SaveManager.Folder = "BitchBot"
SaveManager.Ignore = {}

function SaveManager:SetFolder(path)
    self.Folder = path
    if not isfolder(path) then makefolder(path) end
end

function SaveManager:SetIgnoreIndexes(list)
    self.Ignore = list or {}
end

function SaveManager:_isIgnored(idx)
    for _, v in ipairs(self.Ignore) do if v == idx then return true end end
    return false
end

function SaveManager:Save(name)
    local data = {}
    for idx, obj in pairs(Library.Options) do
        if not self:_isIgnored(idx) then
            if obj._type == "Toggle" then
                data[idx] = { t = "t", v = obj.Value }
            elseif obj._type == "Slider" then
                data[idx] = { t = "s", v = obj.Value }
            elseif obj._type == "Dropdown" then
                data[idx] = { t = "d", v = obj.Value }
            elseif obj._type == "Input" then
                data[idx] = { t = "i", v = obj.Value }
            else
                if obj.Value and typeof(obj.Value) == "Color3" then
                    data[idx] = { t = "c", v = { obj.Value.R, obj.Value.G, obj.Value.B } }
                else
                    data[idx] = { t = "k", v = obj.Value }
                end
            end
        end
    end
    local encoded = HttpService:JSONEncode(data)
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    writefile(self.Folder .. "/" .. name .. ".json", encoded)
    Library:Notify("Config saved: " .. name)
end

function SaveManager:Load(name)
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then Library:Notify("Config not found: " .. name, 3) return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then Library:Notify("Failed to load config", 3) return end
    for idx, entry in pairs(data) do
        local obj = Library.Options[idx]
        if obj then
            if entry.t == "t" then obj:SetValue(entry.v)
            elseif entry.t == "s" then obj:SetValue(entry.v)
            elseif entry.t == "d" then obj:SetValue(entry.v)
            elseif entry.t == "i" then obj:SetValue(entry.v)
            elseif entry.t == "c" then obj:SetValueRGB(Color3.new(entry.v[1], entry.v[2], entry.v[3]))
            elseif entry.t == "k" then if obj.SetValue then obj:SetValue(entry.v) end
            end
        end
    end
    Library:Notify("Config loaded: " .. name)
end

function SaveManager:BuildConfigSection(tab)
    local group = tab:AddRightGroupbox("Configs")
    group:AddInput("__cfg_name", { Text = "Config name", Default = "default" })
    group:AddButton({ Text = "Save", Func = function()
        local name = getgenv().Options.__cfg_name and getgenv().Options.__cfg_name.Value or "default"
        SaveManager:Save(name)
    end })
    group:AddButton({ Text = "Load", Func = function()
        local name = getgenv().Options.__cfg_name and getgenv().Options.__cfg_name.Value or "default"
        SaveManager:Load(name)
    end })
    group:AddButton({ Text = "Delete", Func = function()
        local name = getgenv().Options.__cfg_name and getgenv().Options.__cfg_name.Value or "default"
        local path = SaveManager.Folder .. "/" .. name .. ".json"
        if isfile(path) then delfile(path) Library:Notify("Deleted: " .. name) end
    end })
end

Library.SaveManager = SaveManager

-- ============================================================
-- UNLOAD
-- ============================================================
function Library:Unload()
    Library.Unloaded = true
    if mouseConn then mouseConn:Disconnect() end
    if notifConn then notifConn:Disconnect() end
    if renderLoop then renderLoop:Disconnect() end
    cleanupDrawings()
    getgenv().Options = nil
    getgenv().Toggles = nil
end

return Library
