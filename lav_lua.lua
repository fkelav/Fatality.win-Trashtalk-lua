--[[ lav.lua by fkelav --]]
--[[ fatality.win lua im making --]]

mods.events:AddListener('player_death')

local group = gui.ctx:Find('lua>elements b')

local wm_enable, wm_enable_row = gui.MakeControlEasy('wm_enable', 'Watermark', 'checkbox')
local wm_rounding, wm_rounding_row = gui.MakeControlEasy('wm_rounding', 'Rounding', 'slider', 0, 20, 6)
local wm_tz, wm_tz_row = gui.MakeControlEasy('wm_timezone', 'Timezone offset', 'slider', -12, 14, 0)
local wm_glow, wm_glow_row = gui.MakeControlEasy('wm_glow', 'Glow on kill', 'checkbox')
local wm_textglow, wm_textglow_row = gui.MakeControlEasy('wm_textglow', 'Text glow', 'checkbox')

local dd = gui.ComboBox('kill_say_mode')
dd:Add(gui.Selectable('kill_say_disabled', 'Disabled'))
dd:Add(gui.Selectable('kill_say_all', 'All kills'))
dd:Add(gui.Selectable('kill_say_onetap', 'Headshot / 1tap only'))

local custom_cb, custom_cb_row = gui.MakeControlEasy('kill_say_custom_enable', 'Use custom text', 'checkbox')
local custom_ti = gui.TextInput('kill_say_custom_text')
custom_ti.placeholder = 'Enter custom text...'
local custom_ti_row = gui.MakeControl('Custom text', custom_ti)

local trail_enable, trail_enable_row = gui.MakeControlEasy('trail_enable', 'Movement trail', 'checkbox')
local trail_color = gui.ColorPicker('trail_color', true)
local trail_color_row = gui.MakeControl('Trail color', trail_color)
local trail_thick, trail_thick_row = gui.MakeControlEasy('trail_thickness', 'Trail thickness', 'slider', 1, 100, 3)
local trail_len, trail_len_row = gui.MakeControlEasy('trail_length', 'Trail length', 'slider', 10, 500, 200)

local jump_enable, jump_enable_row = gui.MakeControlEasy('jump_enable', 'Jump circles', 'checkbox')
local jump_color = gui.ColorPicker('jump_color', true)
local jump_color_row = gui.MakeControl('Circle color', jump_color)
local jump_radius, jump_radius_row = gui.MakeControlEasy('jump_radius', 'Circle radius', 'slider', 5, 100, 30)
local jump_fade, jump_fade_row = gui.MakeControlEasy('jump_fade', 'Circle fade time', 'slider', 1, 10, 3)

local row = gui.MakeControl('Say 1 on kill', dd)

group:Add(row)
group:Add(custom_cb_row)
group:Add(custom_ti_row)
group:Add(wm_enable_row)
group:Add(wm_rounding_row)
group:Add(wm_tz_row)
group:Add(wm_glow_row)
group:Add(wm_textglow_row)
group:Add(trail_enable_row)
group:Add(trail_color_row)
group:Add(trail_thick_row)
group:Add(trail_len_row)
group:Add(jump_enable_row)
group:Add(jump_color_row)
group:Add(jump_radius_row)
group:Add(jump_fade_row)
group:Reset()

-- Use gui_bold for the big F, fall back to gui_main if not available
local font_normal = draw.fonts['gui_main']
local font_big    = draw.fonts['gui_bold'] or draw.fonts['gui_main']

local kills = 0
local deaths = 0
local glowTimer = 0
local GLOW_DURATION = 1.5

local trailPoints = {}
local lastPos = nil
local MIN_DIST = 1

local jumpCircles = {}
local lastOnGround = nil
local FL_ONGROUND = 1

events.event:Add(function(e)
    if e:GetName() ~= 'player_death' then return end

    local localController = entities.GetLocalController()
    if not localController then return end

    local attacker = e:GetController('attacker')
    local victim = e:GetController('userid')

    if attacker and attacker:GetName() == localController:GetName() then
        kills = kills + 1
        glowTimer = draw:GetTime() + GLOW_DURATION
    end

    if victim and victim:GetName() == localController:GetName() then
        deaths = deaths + 1
    end
end)

local function drawGlowText(layer, pos, text, col, glowCol)
    local offsets = { {-1,-1},{1,-1},{-1,1},{1,1},{-2,0},{2,0},{0,-2},{0,2} }
    for _, o in ipairs(offsets) do
        layer:AddText(draw.Vec2(pos.x + o[1], pos.y + o[2]), text, glowCol)
    end
    layer:AddText(pos, text, col)
end

events.presentQueue:Add(function()
    local layer = draw.surface
    local now = draw:GetTime()

    -- Jump circles
    if jump_enable:GetValue():Get() then
        local localController = entities.GetLocalController()
        if localController then
            local pawn = localController:GetPawn()
            if pawn and pawn:IsAlive() then
                local flags = pawn.m_fFlags:Get()
                local onGround = bit.band(flags, FL_ONGROUND) ~= 0

                if lastOnGround ~= nil and lastOnGround and not onGround then
                    local pos = pawn:GetAbsOrigin():Clone()
                    table.insert(jumpCircles, { pos = pos, time = now })
                end

                lastOnGround = onGround
            end
        end

        local fadeTime = jump_fade:GetValue():Get()
        local col = jump_color:Get()
        local r = col:GetR()
        local g = col:GetG()
        local b = col:GetB()
        local maxA = col:GetA()
        local radius = jump_radius:GetValue():Get()

        local i = 1
        while i <= #jumpCircles do
            local circle = jumpCircles[i]
            local age = now - circle.time
            if age >= fadeTime then
                table.remove(jumpCircles, i)
            else
                local fadeRatio = 1.0 - (age / fadeTime)
                local alpha = math.floor(maxA * fadeRatio)
                local screenPos = math.WorldToScreen(circle.pos)

                if screenPos then
                    layer:AddCircle(screenPos, radius + 6, draw.Color(r, g, b, math.floor(alpha * 0.3)), 36, 1.0, 6.0)
                    layer:AddCircle(screenPos, radius + 3, draw.Color(r, g, b, math.floor(alpha * 0.5)), 36, 1.0, 3.0)
                end
                i = i + 1
            end
        end
    else
        jumpCircles = {}
        lastOnGround = nil
    end

    -- Trail
    if trail_enable:GetValue():Get() then
        local localController = entities.GetLocalController()
        if localController then
            local pawn = localController:GetPawn()
            if pawn then
                local origin = pawn:GetAbsOrigin()

                local shouldAdd = false
                if lastPos == nil then
                    shouldAdd = true
                else
                    local dx = origin.x - lastPos.x
                    local dy = origin.y - lastPos.y
                    local dz = origin.z - lastPos.z
                    if (dx*dx + dy*dy + dz*dz) > (MIN_DIST * MIN_DIST) then
                        shouldAdd = true
                    end
                end

                if shouldAdd then
                    table.insert(trailPoints, origin:Clone())
                    lastPos = origin:Clone()
                    local maxLen = trail_len:GetValue():Get()
                    while #trailPoints > maxLen do
                        table.remove(trailPoints, 1)
                    end
                end

                if #trailPoints >= 2 then
                    local col = trail_color:Get()
                    local r = col:GetR()
                    local g = col:GetG()
                    local b = col:GetB()
                    local a = col:GetA()
                    local thickness = trail_thick:GetValue():Get()
                    local count = #trailPoints

                    for i = 1, count - 1 do
                        local p1 = math.WorldToScreen(trailPoints[i])
                        local p2 = math.WorldToScreen(trailPoints[i + 1])
                        if p1 and p2 then
                            local alpha1 = math.floor(a * ((i - 1) / count))
                            local alpha2 = math.floor(a * (i / count))
                            layer:AddLineMulticolor(p1, p2, draw.Color(r, g, b, alpha1), draw.Color(r, g, b, alpha2), thickness)
                        end
                    end
                end
            end
        end
    else
        trailPoints = {}
        lastPos = nil
    end

    -- Watermark
    if not wm_enable:GetValue():Get() then return end

    local font = font_normal
    if not font then return end

    local time = utils.GetDate()
    local tzOffset = wm_tz:GetValue():Get()
    local hour = (time.hour + tzOffset) % 24
    local timeStr = string.format('%02d:%02d:%02d', hour, time.minute, time.second)

    local fatalityUser = gui.ctx.user.username or 'unknown'

    local pingStr = '0ms'
    local chan = game.engine:GetNetChan()
    if chan and not chan:IsNull() then
        pingStr = string.format('%dms', math.floor(chan:GetLatency() * 1000))
    end

    local kdStr  = string.format('K %d  D %d', kills, deaths)

    local partF    = 'F'
    local partRest = 'atality.win'
    local partLav  = '   lav.lua'
    local partMain = '   ' .. fatalityUser .. '   ' .. timeStr .. '   ' .. pingStr .. '   ' .. kdStr

    layer.font = font_big
    local sizeF    = font_big:GetTextSize(partF)

    layer.font = font
    local sizeRest = font:GetTextSize(partRest)
    local sizeLav  = font:GetTextSize(partLav)
    local sizeMain = font:GetTextSize(partMain)

    local padding  = 8
    local bigH     = sizeF.y
    local normH    = sizeRest.y
    local vOffset  = math.floor((bigH - normH) / 2)

    local totalW   = sizeF.x + sizeRest.x + sizeLav.x + sizeMain.x + padding * 2
    local h        = bigH + padding * 2
    local screen   = draw:GetDisplay()
    local x        = screen.x - totalW - 10
    local y        = 10
    local rounding = wm_rounding:GetValue():Get()
    local rect     = draw.Rect(x, y, x + totalW, y + h)

    if wm_glow:GetValue():Get() and now < glowTimer then
        local timeLeft  = glowTimer - now
        local fadeRatio = timeLeft / GLOW_DURATION
        local alpha     = math.floor(fadeRatio * 180)
        layer:AddGlow(rect, 8, draw.Color(255, 255, 255, alpha))
    end

    layer:AddRectFilledRounded(rect, draw.Color(15, 15, 15, 220), rounding)

    local useGlow    = wm_textglow:GetValue():Get()
    local purpleCol  = draw.Color(180, 0, 255, 255)
    local purpleGlow = draw.Color(180, 0, 255, 80)
    local whiteCol   = draw.Color(255, 255, 255, 255)
    local whiteGlow  = draw.Color(255, 255, 255, 60)

    local curX  = x + padding
    local baseY = y + padding

    -- Big purple F
    layer.font = font_big
    if useGlow then
        drawGlowText(layer, draw.Vec2(curX, baseY), partF, purpleCol, purpleGlow)
    else
        layer:AddText(draw.Vec2(curX, baseY), partF, purpleCol)
    end
    curX = curX + sizeF.x

    -- White "atality.win"
    layer.font = font
    if useGlow then
        drawGlowText(layer, draw.Vec2(curX, baseY + vOffset), partRest, whiteCol, whiteGlow)
    else
        layer:AddText(draw.Vec2(curX, baseY + vOffset), partRest, whiteCol)
    end
    curX = curX + sizeRest.x

    -- White "lav.lua"
    if useGlow then
        drawGlowText(layer, draw.Vec2(curX, baseY + vOffset), partLav, whiteCol, whiteGlow)
    else
        layer:AddText(draw.Vec2(curX, baseY + vOffset), partLav, whiteCol)
    end
    curX = curX + sizeLav.x

    -- White main info
    if useGlow then
        drawGlowText(layer, draw.Vec2(curX, baseY + vOffset), partMain, whiteCol, whiteGlow)
    else
        layer:AddText(draw.Vec2(curX, baseY + vOffset), partMain, whiteCol)
    end
end)

events.event:Add(function(e)
    if e:GetName() ~= 'player_death' then return end

    local bits = dd:Get()
    if bits:Get(0) then return end

    local localController = entities.GetLocalController()
    if not localController then return end

    local attacker = e:GetController('attacker')
    if not attacker then return end

    if attacker:GetName() ~= localController:GetName() then return end

    local useCustom  = custom_cb:GetValue():Get()
    local customText = custom_ti.value
    local msg = (useCustom and customText and customText ~= '') and customText or '1'

    if bits:Get(1) then
        game.engine:ClientCmd('say "' .. msg .. '"')
    elseif bits:Get(2) then
        local headshot = e:GetBool('headshot')
        local damage   = e:GetInt('dmg_health')
        if headshot or damage >= 100 then
            game.engine:ClientCmd('say "' .. msg .. '"')
        end
    end
end)