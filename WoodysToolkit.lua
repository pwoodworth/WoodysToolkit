--[[------------------------------------------------------------
    Woodys Toolkit v0.9

    By Patrick Woodworth

    Revision History
    0.9	Pre-release -- 1
--------------------------------------------------------------]]

BINDING_HEADER_WoodysToolkit = 'WoodysToolkit'
BINDING_NAME_WoodysToolkit_mode_toggle  = "Toggle MouseLook Lock"
BINDING_NAME_WoodysToolkit_mode_enable  = "Enable MouseLook Lock"
BINDING_NAME_WoodysToolkit_mode_disable  = "Disable MouseLook Lock"
BINDING_NAME_WoodysToolkit_momentary    = "Disable Lock While Pressed"

WoodysToolkit_acctData = {}

-- WoodysToolkit = {}

local WTK_DEBUG = false

local statedata = {}

local function WoodysToolkit_InitData()
    if type(WoodysToolkit_acctData) ~= "table" then
        WoodysToolkit_acctData = {}
    end
    if type(WoodysToolkit_acctData.bindings) ~= "table" then
        WoodysToolkit_acctData.bindings = {}
    end
end

local data = setmetatable({}, {
    __index = function(table, key)
        if key == "debug" then
            return WTK_DEBUG
        end
        WoodysToolkit_InitData()
        return WoodysToolkit_acctData[key]
    end,
    __newindex = function(table, key, value)
        if key == "debug" then
            return
        end
        WoodysToolkit_InitData()
        WoodysToolkit_acctData[key] = value
    end
})

WoodysToolkit = setmetatable({}, {
    __index = function(table, key)
        if key == "data" then
            return data
        end
    end,
    __newindex = function(table, key, value)
        if key == "data" then
            -- noop
        else
            rawset(table, key, value)
        end
    end
})

WoodysToolkit.OVERRIDE_DEFAULTS = {
    BUTTON1 = "WoodysToolkit_mode_disable",
    BUTTON2 = "MOVEFORWARD",
    BUTTON3 = "TOGGLEAUTORUN",
    LEFT = "STRAFELEFT",
    RIGHT = "STRAFERIGHT",
}

local function WTK_debug(...)
    if not DEFAULT_CHAT_FRAME or not data.debug then return end
    local msg = ''
    for k,v in ipairs(arg) do
        msg = msg .. tostring(v) .. ' : '
    end
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function Print(text)
    if not DEFAULT_CHAT_FRAME then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function dprint(text)
    if not DEFAULT_CHAT_FRAME or not data.debug then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function status(bool)
    if bool then return "true" else return "false" end
end

local function WoodysToolkit_InitBindings()
    for k,v in pairs(WoodysToolkit.OVERRIDE_DEFAULTS) do
        local val = data.bindings[k]
        if not val then
            val = v
        end
        SetMouselookOverrideBinding(k, val)
--        print('SetMouselookOverrideBinding("' .. k .. '", ' .. val .. ')')
    end
end

local function WoodysToolkit_ApplyMode()
    local shouldBeLooking = data.lockEnabled and not data.lockSuppressed
    if shouldBeLooking then
        MouselookStart()
    else
        MouselookStop()
    end
end

function WoodysToolkit_Reset()
    WoodysToolkit_acctData = {}
    WoodysToolkit_InitBindings()
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Enable()
    data.lockEnabled = true
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Disable()
    if statedata.moving then return end
    data.lockEnabled = false
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Toggle()
    if data.lockEnabled then
        WoodysToolkit_Disable()
    else
        WoodysToolkit_Enable()
    end
end

function WoodysToolkit_Momentary(keystate)
    data.lockSuppressed = (keystate == "down")
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_SlashCommand(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    -- Any leading non-whitespace is captured into command;
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "reset" then
        WoodysToolkit_Reset()
    elseif command == "button1" then
        if rest == "backup" then
            data.btn1backsup = true
            WoodysToolkit_InitBindings()
        elseif rest == "cancel" then
            data.btn1backsup = false
            WoodysToolkit_InitBindings()
        else
            local curval = data.btn1backsup and 'backup' or 'cancel'
            print("button1 : ", curval)
        end
    elseif command == "remove" and rest ~= "" then
        -- Handle removing of the contents of rest... to something.
        -- print(command, " : \"", rest, "\" )
        print(command, " : ", string.format("%s%s%s", '"', rest, '"'))
    else
        -- If not handled above, display some sort of help message
        print("Usage: /woodystoolkit button1 [backup||cancel]");
    end
end

function WoodysToolkit_OnLoad(self,...)
    WoodysToolkitFrame:RegisterEvent("ADDON_LOADED")
    WoodysToolkitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
--    print("on event:" ..event)
    if event == "PLAYER_ENTERING_WORLD" then
        WoodysToolkit_InitBindings()
        WoodysToolkit_ApplyMode()
    end
end

function WoodysToolkit_MoveAndSteerStart()
    statedata.steering = true
    dprint('statedata.steering: ' .. status(statedata.steering))
end

function WoodysToolkit_MoveAndSteerStop()
    statedata.steering = false
    WoodysToolkit_Disable()
    dprint('statedata.steering: ' .. status(statedata.steering))
end

function WoodysToolkit_TurnOrActionStart()
    statedata.turning = true
    dprint('statedata.turning: ' .. status(statedata.turning))
end

function WoodysToolkit_TurnOrActionStop()
    statedata.turning = false
    dprint('statedata.turning: ' .. status(statedata.turning))
end

function WoodysToolkit_CameraOrSelectOrMoveStart()
    statedata.camera = true
    dprint('statedata.camera: ' .. status(statedata.camera))
end

function WoodysToolkit_CameraOrSelectOrMoveStop()
    statedata.camera = false
    dprint('statedata.camera: ' .. status(statedata.camera))
end

function WoodysToolkit_MoveForwardStart()
    statedata.moving = true
    dprint('statedata.moving1: ' .. status(statedata.moving))
end

function WoodysToolkit_MoveForwardStop()
    statedata.moving = false
    dprint('statedata.moving1: ' .. status(statedata.moving))
end

function WoodysToolkit_MoveBackwardStart()
    statedata.moving = true
    dprint('statedata.moving2: ' .. status(statedata.moving))
end

function WoodysToolkit_MoveBackwardStop()
    statedata.moving = false
    dprint('statedata.moving2: ' .. status(statedata.moving))
end

--[[
--]]
hooksecurefunc("MoveAndSteerStart", WoodysToolkit_MoveAndSteerStart);
hooksecurefunc("TurnOrActionStart", WoodysToolkit_TurnOrActionStart);
hooksecurefunc("TurnOrActionStop", WoodysToolkit_TurnOrActionStop);
hooksecurefunc("CameraOrSelectOrMoveStart", WoodysToolkit_CameraOrSelectOrMoveStart);
hooksecurefunc("CameraOrSelectOrMoveStop", WoodysToolkit_CameraOrSelectOrMoveStop);
hooksecurefunc("MoveAndSteerStop", WoodysToolkit_MoveAndSteerStop);
hooksecurefunc("MoveForwardStart", WoodysToolkit_MoveForwardStart);
hooksecurefunc("MoveForwardStop", WoodysToolkit_MoveForwardStop);
hooksecurefunc("MoveBackwardStart", WoodysToolkit_MoveBackwardStart);
hooksecurefunc("MoveBackwardStop", WoodysToolkit_MoveBackwardStop);

function is_main(_arg, ...)
    local n_arg = _arg and #_arg or 0;
    if n_arg == select("#", ...) then
        for i=1,n_arg do
            if _arg[i] ~= select(i, ...) then
                print(_arg[i], "does not match", (select(i, ...)))
                return false;
            end
        end
        return true;
    end
    return false;
end

-- if is_main(arg, ...) then
--    print("Main file");
--    WoodysToolkit_OnEvent(nil, "PLAYER_ENTERING_WORLD")
--    print("button1.action " .. WoodysToolkit.button1.action);
-- end
