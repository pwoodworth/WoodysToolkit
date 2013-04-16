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

local function WTK_debug(...)
    if not DEFAULT_CHAT_FRAME or not WoodysToolkit.debug then return end
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

WoodysToolkit = {}
WoodysToolkit.debug = false

local function WoodysToolkit_Reset()
    WoodysToolkit_acctData = {}
    WoodysToolkit_acctData["lockEnabled"] = false
    WoodysToolkit_acctData["lockSuppressed"] = false
    WoodysToolkit_acctData["btn1backsup"] = false
    WoodysToolkit_acctData["version"] = 1
end

local function WoodysToolkit_InitVars()
    if type(WoodysToolkit_acctData) ~= "table" then
        WoodysToolkit_Reset()
    end
end

local function WoodysToolkit_GetVar(varname)
    if type(WoodysToolkit_acctData) ~= "table" then
        return nil
    else
        return WoodysToolkit_acctData[varname]
    end
end

local function WoodysToolkit_SetVar(varname, varval)
    WoodysToolkit_InitVars()
    WoodysToolkit_acctData[varname] = varval
end

local function WoodysToolkit_IsButton1Backup()
    return WoodysToolkit_GetVar("btn1backsup")
end

local function WoodysToolkit_SetButton1Backup(val)
    WoodysToolkit_SetVar("btn1backsup", val)
end

local function WoodysToolkit_IsLockEnabled()
    return WoodysToolkit_GetVar("lockEnabled")
end

local function WoodysToolkit_SetLockEnabled(val)
    WoodysToolkit_SetVar("lockEnabled", val)
end

local function WoodysToolkit_IsLockSuppressed()
    return WoodysToolkit_GetVar("lockSuppressed")
end

local function WoodysToolkit_SetLockSuppressed(val)
    WoodysToolkit_SetVar("lockSuppressed", val)
end

local function WoodysToolkit_GetButton1Action()
    local b1name = "WoodysToolkit_mode_disable"
    if WoodysToolkit_IsButton1Backup() then
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
    local shouldBeLooking = false
    if type(WoodysToolkit_acctData) == "table" then
      if WoodysToolkit_acctData["lockEnabled"] and not WoodysToolkit_acctData["lockSuppressed"] then
        shouldBeLooking = true
      end
    end
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

function WoodysToolkit_Enable()
    WoodysToolkit_SetLockEnabled(true)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Disable()
    WoodysToolkit_SetLockEnabled(false)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Toggle()
    local newval = not WoodysToolkit_IsLockEnabled()
    WoodysToolkit_SetLockEnabled(newval)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Momentary(keystate)
    local newval = keystate == "down"
    WoodysToolkit_SetLockSuppressed(newval)
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
            WoodysToolkit_SetButton1Backup(true)
            WoodysToolkit_InitBindings()
        elseif rest == "cancel" then
            WoodysToolkit_SetButton1Backup(false)
            WoodysToolkit_InitBindings()
        else
            local curval = WoodysToolkit_IsButton1Backup() and 'backup' or 'cancel'
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
    WoodysToolkitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    WoodysToolkit_InitBindings()
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
    --Print("on event:" ..event)
    if event == "PLAYER_ENTERING_WORLD" then
        --Print("PLAYER_ENTERING_WORLD event")
        WoodysToolkit_InitVars()
        WoodysToolkit_InitBindings()
        WoodysToolkit_ApplyMode()
    end
end
