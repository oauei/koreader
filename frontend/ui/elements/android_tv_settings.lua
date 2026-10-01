local _ = require("gettext")
local Device = require("device")
local Event = require("ui/event")
local Screen = Device.screen
local T = require("ffi/util").template
local UIManager = require("ui/uimanager")

local function isForcedOn()
    return G_reader_settings and G_reader_settings:readSetting("force_tv_mode") == true
end

local function isForcedOff()
    return G_reader_settings and G_reader_settings:readSetting("force_tv_mode") == false
end

local function isAutoDetect()
    return G_reader_settings and G_reader_settings:readSetting("force_tv_mode") == nil
end

local function setTvMode(val)
    if G_reader_settings then
        G_reader_settings:saveSetting("force_tv_mode", val)
    end
    UIManager:askForRestart(_("Projector / TV mode setting changed. Please restart KOReader for full keymap adjustments to take effect."))
end

local function setProjectorDPI(dpi_val, label)
    if G_reader_settings then
        G_reader_settings:saveSetting("screen_dpi", dpi_val)
    end
    if Device and Device.setScreenDPI then
        Device:setScreenDPI(dpi_val)
    end
    local msg
    if dpi_val then
        msg = T(_("UI scaling set to %1 (%2 DPI). Restart KOReader to apply."), label, dpi_val)
    else
        msg = _("UI scaling reset to Auto / Default DPI. Restart KOReader to apply.")
    end
    UIManager:askForRestart(msg)
end

local function getRotationMode()
    if Device and Device.screen and Device.screen.getRotationMode then
        return Device.screen:getRotationMode()
    end
    return 0
end

local function setRotation(mode)
    UIManager:broadcastEvent(Event:new("SetRotationMode", mode))
    if G_reader_settings then
        G_reader_settings:saveSetting("fm_rotation_mode", mode)
    end
end

return {
    text = _("Smart Projector & Android TV"),
    help_text = _("Settings optimized for Android Smart Projectors, Android TV, and remote control operation."),
    sub_item_table = {
        {
            text = _("Projector / TV Mode"),
            help_text = _("Configures D-Pad navigation, remote control input mapping, and 10-foot UI focus traversal."),
            sub_item_table = {
                {
                    text = _("Auto-detect (Recommended)"),
                    help_text = _("Automatically detects Android TV, Google TV, or smart projector hardware."),
                    checked_func = isAutoDetect,
                    radio = true,
                    callback = function() setTvMode(nil) end,
                },
                {
                    text = _("Force Enabled"),
                    help_text = _("Always enable TV & remote navigation even if the device identifies as a phone/tablet."),
                    checked_func = isForcedOn,
                    radio = true,
                    callback = function() setTvMode(true) end,
                },
                {
                    text = _("Force Disabled"),
                    help_text = _("Use standard touchscreen mobile mode."),
                    checked_func = isForcedOff,
                    radio = true,
                    callback = function() setTvMode(false) end,
                },
            },
            separator = true,
        },
        {
            text = _("Remote Control Controls"),
            sub_item_table = {
                {
                    text = _("Left/Right D-Pad turns pages in reader"),
                    help_text = _("When checked, D-Pad Left and Right buttons turn pages in documents instead of jumping chapters."),
                    checked_func = function()
                        return G_reader_settings and G_reader_settings:nilOrTrue("left_right_keys_turn_pages")
                    end,
                    callback = function()
                        if G_reader_settings then
                            G_reader_settings:flipNilOrTrue("left_right_keys_turn_pages")
                        end
                        UIManager:broadcastEvent(Event:new("ReRegisterKeyEvents"))
                    end,
                },
                {
                    text = _("Center/OK button toggles Reader Menu"),
                    help_text = _("Pressing OK/Center on the remote while reading opens the top control menu."),
                    checked_func = function() return true end,
                    enabled_func = function() return false end,
                },
                {
                    text = _("Hybrid Input (Remote D-Pad + Air-Mouse)"),
                    help_text = _("Both directional remote buttons and pointer/touch air-mouse operate concurrently."),
                    checked_func = function() return true end,
                    enabled_func = function() return false end,
                },
            },
            separator = true,
        },
        {
            text = _("Distance UI Scaling (10-Foot UI)"),
            help_text = _("Scale the interface so menus, buttons, and file lists are easily readable from a couch across the room."),
            sub_item_table = {
                {
                    text = _("Auto / Default DPI"),
                    checked_func = function() return not G_reader_settings or G_reader_settings:readSetting("screen_dpi") == nil end,
                    radio = true,
                    callback = function() setProjectorDPI(nil, _("Auto")) end,
                },
                {
                    text = _("Medium Distance (240 DPI)"),
                    checked_func = function() return G_reader_settings and G_reader_settings:readSetting("screen_dpi") == 240 end,
                    radio = true,
                    callback = function() setProjectorDPI(240, _("Medium Distance")) end,
                },
                {
                    text = _("Large / Projector Standard (320 DPI)"),
                    checked_func = function() return G_reader_settings and G_reader_settings:readSetting("screen_dpi") == 320 end,
                    radio = true,
                    callback = function() setProjectorDPI(320, _("Projector Standard")) end,
                },
                {
                    text = _("Extra Large / Far Distance (400 DPI)"),
                    checked_func = function() return G_reader_settings and G_reader_settings:readSetting("screen_dpi") == 400 end,
                    radio = true,
                    callback = function() setProjectorDPI(400, _("Far Distance")) end,
                },
                {
                    text = _("Ultra Large (480 DPI)"),
                    checked_func = function() return G_reader_settings and G_reader_settings:readSetting("screen_dpi") == 480 end,
                    radio = true,
                    callback = function() setProjectorDPI(480, _("Ultra Large")) end,
                },
            },
            separator = true,
        },
        {
            text = _("Wall / Ceiling Software Rotation"),
            help_text = _("Rotate the software display 90 degrees for vertical projection walls or 180 degrees for ceiling mounts without distorting Android OS."),
            sub_item_table = {
                {
                    text = _("Landscape Upright (0°)"),
                    checked_func = function() return getRotationMode() == 0 end,
                    radio = true,
                    callback = function() setRotation(0) end,
                },
                {
                    text = _("Vertical Wall (90° Clockwise)"),
                    checked_func = function() return getRotationMode() == 1 end,
                    radio = true,
                    callback = function() setRotation(1) end,
                },
                {
                    text = _("Ceiling Mount (180° Inverted)"),
                    checked_func = function() return getRotationMode() == 2 end,
                    radio = true,
                    callback = function() setRotation(2) end,
                },
                {
                    text = _("Vertical Wall (270° Counter-Clockwise)"),
                    checked_func = function() return getRotationMode() == 3 end,
                    radio = true,
                    callback = function() setRotation(3) end,
                },
            },
        },
    },
}
