--[[ lav.lua by fkelav --]]
--[[ fatality.win lua im making --]]

mods.events:AddListener('player_death')

local group = gui.ctx:Find('lua>elements b')

local wm_enable, wm_enable_row = gui.MakeControlEasy('wm_enable', 'Watermark', 'checkbox')
local wm_rounding, wm_rounding_row = gui.MakeControlEasy('wm_rounding', 'Rounding', 'slider', 0, 20, 6)
local wm_tz, wm_tz_row = gui.MakeControlEasy('wm_timezone', 'Timezone offset', 'slider', -12, 14, 0)
local wm_glow, wm_glow_row = gui.MakeControlEasy('wm_glow', 'Glow on kill', 'checkbox')

local dd = gui.ComboBox('kill_say_mode')
dd:Add(gui.Selectable('kill_say_disabled', 'Disabled'))
dd:Add(gui.Selectable('kill_say_all', 'All kills'))
dd:Add(gui.Selectable('kill_say_onetap', 'Headshot / 1tap only'))

local custom_cb, custom_cb_row = gui.MakeControlEasy('kill_say_custom_enable', 'Use custom text', 'checkbox')
local custom_ti = gui.TextInput('kill_say_custom_text')
custom_ti.placeholder = 'Enter custom text...'
local custom_ti_row = gui.MakeControl('Custom text', custom_ti)

local row = gui.MakeControl('Say 1 on kill', dd)

group:Add(row)
group:Add(custom_cb_row)
group:Add(custom_ti_row)
group:Add(wm_enable_row)
group:Add(wm_rounding_row)
group:Add(wm_tz_row)
group:Add(wm_glow_row)
group:Reset()


local kills = 0
local deaths = 0
local glowTimer = 0


events.event:Add(function(e)
    if e:GetName() ~= 'player_death' then return end

    local localController = entities.GetLocalController()
    if not localController then return end


    local attacker = e:GetController('attacker')
    local victim   = e:GetController('userid')

    if attacker and attacker:GetName() == localController:GetName() then
        kills = kills + 1
        glowTimer = draw.GetTime() + 1.5
    end

    if victim and victim:GetName() == localController:GetName() then
        deaths = deaths + 1
    end
end)


events.presentQueue:Add(function()
    if not wm_enable:GetValue():Get() then return end

    local layer = draw.surface
    local font = draw.fonts['gui_main']
    if not font then return end

    local time = utils.GetDate()
    local tzOffset = wm_tz:GetValue():Get()
    local hour = (time.hour + tzOffset) % 24
    local timeStr = string.format('%02d:%02d:%02d', hour, time.minute, time.second)

    local localController = entities.GetLocalController()
    local name = localController and localController:GetName() or 'unknown'

    local pingStr = '0ms'
    local chan = game.engine:GetNetChan()
    if chan and not chan:IsNull() then
        pingStr = string.format('%dms', math.floor(chan:GetLatency() * 1000))
    end

    local kdStr = string.format('K %d  D %d', kills, deaths)
    local text = name .. '   ' .. timeStr .. '   ' .. pingStr .. '   ' .. kdStr

    layer.font = font
    local textSize = font:GetTextSize(text)
    local padding = 8
    local w = textSize.x + padding * 2
    local h = textSize.y + padding * 2
    local screen = draw.GetDisplay()
    local x = screen.x - w - 10
    local y = 10
    local rounding = wm_rounding:GetValue():Get()
    local rect = draw.Rect(x, y, x + w, y + h)

    if wm_glow:GetValue():Get() and draw.GetTime() < glowTimer then
        layer:AddGlow(rect, 8, draw.Color(255, 255, 255, 180))
    end

    layer:AddRectFilledRounded(rect, draw.Color(15, 15, 15, 220), rounding)
    layer:AddText(draw.Vec2(x + padding, y + padding), text, draw.Color(255, 255, 255))
end)


events.event:Add(function(e)
    if e:GetName() ~= 'player_death' then return end

    local bits = dd:GetValue():Get()
    if bits:Get(0) then return end

    local localController = entities.GetLocalController()
    if not localController then return end

    
    local attacker = e:GetController('attacker')
    if not attacker then return end

    if attacker:GetName() ~= localController:GetName() then return end

    local useCustom = custom_cb:GetValue():Get()
    local customText = custom_ti.value
    local msg = (useCustom and customText and customText ~= '') and customText or '1'

    if bits:Get(1) then
        game.engine:ClientCmd('say "' .. msg .. '"')
    elseif bits:Get(2) then
        local headshot = e:GetBool('headshot')
        local damage = e:GetInt('dmg_health')
        if headshot or damage >= 100 then
            game.engine:ClientCmd('say "' .. msg .. '"')
        end
    end
end)