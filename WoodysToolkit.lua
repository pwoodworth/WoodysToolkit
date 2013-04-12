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

local b = CreateFrame("Button", "WoodysSpellStopTargetingButton", UIParent, "SecureActionButtonTemplate")
b:SetAttribute("type", "stop")

WoodysToolkit = {}
WoodysToolkit.debug = false

function WoodysToolkit:Reset()
    WoodysToolkit_acctData = {}
    WoodysToolkit_acctData["lockEnabled"] = false
    WoodysToolkit_acctData["lockSuppressed"] = false
    WoodysToolkit_acctData["btn1backsup"] = false
    WoodysToolkit_acctData["version"] = 1
end

function WoodysToolkit:InitVars()
    if type(WoodysToolkit_acctData) ~= "table" then
      self:Reset()
    end
end

local function WoodysToolkit_InitVars()
    WoodysToolkit:InitVars()
end

local function WoodysToolkit_Reset()
    WoodysToolkit:Reset()
end

local function ML_debug(...)
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

local function WoodysToolkit_GetVar(varname)
    if type(WoodysToolkit_acctData) ~= "table" then
        return nil
    else
        return WoodysToolkit_acctData[varname]
    end
end

local function WoodysToolkit_SetVar(varname, varval)
    --print("newval - ", varname, " : ", varval)
    WoodysToolkit_InitVars()
    WoodysToolkit_acctData[varname] = varval
end

local function WoodysToolkit_InitBindings()
    local b1name = "WoodysToolkit_mode_disable"
    if WoodysToolkit_GetVar("btn1backsup") then
      b1name = "MOVEBACKWARD"
    end
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
    WoodysToolkit_SetVar("lockEnabled", true)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Disable()
    WoodysToolkit_SetVar("lockEnabled", false)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Toggle()
    local newval = not WoodysToolkit_GetVar("lockEnabled")
    WoodysToolkit_SetVar("lockEnabled", newval)
    WoodysToolkit_ApplyMode()
end

function WoodysToolkit_Momentary(keystate)
    local newval = keystate == "down"
    WoodysToolkit_SetVar("lockSuppressed", newval)
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
            WoodysToolkit_SetVar("btn1backsup", true)
            WoodysToolkit_InitBindings()
        elseif rest == "cancel" then
            WoodysToolkit_SetVar("btn1backsup", false)
            WoodysToolkit_InitBindings()
        else
            local curval = WoodysToolkit_GetVar("btn1backsup") and 'backup' or 'cancel'
            print("button1 : ", curval)
        end
    elseif command == "remove" and rest ~= "" then
        -- Handle removing of the contents of rest... to something.
        -- print(command, " : \"", rest, "\" )
        print(command, " : ", string.format("%s%s%s", '"', rest, '"'))
    else
        -- If not handled above, display some sort of help message
        print("Usage: /woodmouse button1 [backup||cancel]");
    end
end

function WoodysToolkit_OnLoad(self,...)
    WoodMouseFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
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
