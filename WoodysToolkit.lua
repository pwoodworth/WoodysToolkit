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

function WoodysToolkit:GetVar(varname)
    if type(WoodysToolkit_acctData) ~= "table" then
        return nil
    else
        return WoodysToolkit_acctData[varname]
    end
end

function WoodysToolkit:SetVar(varname, varval)
    self:InitVars()
    WoodysToolkit_acctData[varname] = varval
end

function WoodysToolkit:IsButton1Backup()
    return self:GetVar("btn1backsup")
end

function WoodysToolkit:SetButton1Backup(val)
    self:SetVar("btn1backsup", val)
end

function WoodysToolkit:IsLockEnabled()
    return self:GetVar("lockEnabled")
end

function WoodysToolkit:SetLockEnabled(val)
    self:SetVar("lockEnabled", val)
end

function WoodysToolkit:IsLockSuppressed()
    return self:GetVar("lockSuppressed")
end

function WoodysToolkit:SetLockSuppressed(val)
    self:SetVar("lockSuppressed", val)
end

function WoodysToolkit:GetButton1Action()
    local b1name = "WoodysToolkit_mode_disable"
    if self:IsButton1Backup() then
        b1name = "MOVEBACKWARD"
    end
    return b1name
end

function WoodysToolkit:InitBindings()
    local b1name = self:GetButton1Action()
    SetMouselookOverrideBinding("BUTTON1", b1name)
    SetMouselookOverrideBinding("BUTTON2", "MOVEFORWARD")
end

function WoodysToolkit:ApplyMode()
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
    WoodysToolkit:SetLockEnabled(true)
    WoodysToolkit:ApplyMode()
end

function WoodysToolkit_Disable()
    WoodysToolkit:SetLockEnabled(false)
    WoodysToolkit:ApplyMode()
end

function WoodysToolkit_Toggle()
    local newval = not WoodysToolkit:IsLockEnabled()
    WoodysToolkit:SetLockEnabled(newval)
    WoodysToolkit:ApplyMode()
end

function WoodysToolkit_Momentary(keystate)
    local newval = keystate == "down"
    WoodysToolkit:SetLockSuppressed(newval)
    WoodysToolkit:ApplyMode()
end

function WoodysToolkit_SlashCommand(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    -- Any leading non-whitespace is captured into command;
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "reset" then
        WoodysToolkit:Reset()
    elseif command == "button1" then
        if rest == "backup" then
            WoodysToolkit:SetButton1Backup(true)
            WoodysToolkit:InitBindings()
        elseif rest == "cancel" then
            WoodysToolkit:SetButton1Backup(false)
            WoodysToolkit:InitBindings()
        else
            local curval = WoodysToolkit:IsButton1Backup() and 'backup' or 'cancel'
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
    WoodysToolkit:InitBindings()
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
    --Print("on event:" ..event)
    if event == "PLAYER_ENTERING_WORLD" then
        --Print("PLAYER_ENTERING_WORLD event")
        WoodysToolkit:InitVars()
        WoodysToolkit:InitBindings()
        WoodysToolkit:ApplyMode()
    end
end
