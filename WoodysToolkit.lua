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

WoodysToolkit = {}
WoodysToolkit.data = setmetatable({}, {
    __index = function(table, key)
        if type(WoodysToolkit_acctData) ~= "table" then
            WoodysToolkit_acctData = {}
        end
        return WoodysToolkit_acctData[key]
    end,
    __newindex = function(table, key, value)
        if type(WoodysToolkit_acctData) ~= "table" then
            WoodysToolkit_acctData = {}
        end
        WoodysToolkit_acctData[key] = value
    end
})

local data = WoodysToolkit.data

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

local function status(bool)
    if bool then return "true" else return "false" end
end


local function WoodysToolkit_GetButton1Action()
    local b1name = "WoodysToolkit_mode_disable"
    if data.btn1backsup then
        b1name = "MOVEBACKWARD"
    end
    return b1name
end

local function WoodysToolkit_InitBindings()
    local b1name = WoodysToolkit_GetButton1Action()
    SetMouselookOverrideBinding("BUTTON1", b1name)
    SetMouselookOverrideBinding("BUTTON2", "MOVEFORWARD")
end

local function WoodysToolkit_ApplyMode()
    local shouldBeLooking = data.lockEnabled and not data.lockSuppressed
    if IsMouselooking() then
      if not shouldBeLooking then
        MouselookStop()
      end
    else
      if shouldBeLooking then
        MouselookStart()
      end
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
    data.lockEnabled = false
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Toggle()
    data.lockEnabled = not data.lockEnabled
    WoodysToolkit_ApplyMode()
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
    --Print("on event:" ..event)
    if event == "PLAYER_ENTERING_WORLD" then
        WoodysToolkit_InitBindings()
        WoodysToolkit_ApplyMode()
    end
end
