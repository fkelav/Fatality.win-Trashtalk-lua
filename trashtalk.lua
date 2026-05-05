--[[ trashtalk.lua by fkelav --]]
--[[ simple trashtalk lua i made cuz none on fata website seem to work lol --]]
local dd = gui.ComboBox('kill_say_mode')
dd:Add(gui.Selectable('kill_say_disabled', 'Disabled'))
dd:Add(gui.Selectable('kill_say_all', 'All kills'))
dd:Add(gui.Selectable('kill_say_onetap', 'Headshot / 1tap only'))

local custom_cb, custom_cb_row = gui.MakeControlEasy('kill_say_custom_enable', 'Use custom text', 'checkbox')
local custom_ti = gui.text_input('kill_say_custom_text')
custom_ti.placeholder = 'Enter custom text...'
local custom_ti_row = gui.MakeControl('Custom text', custom_ti)

local row = gui.MakeControl('Say 1 on kill', dd)

local group = gui.ctx:Find('lua>elements b')
group:Add(row)
group:Add(custom_cb_row)
group:Add(custom_ti_row)
group:Reset()

events.event:Add(function(e)
    if e:GetName() ~= 'player_death' then return end

    local bits = dd:Get()
    if bits:Get(0) or (not bits:Get(1) and not bits:Get(2)) then return end

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