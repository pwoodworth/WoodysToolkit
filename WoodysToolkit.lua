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

WoodysMouse = {}
WoodysMouse.debug = false

function WoodysMouse:Reset()
    WoodysToolkit_acctData = {}
    WoodysToolkit_acctData["lockEnabled"] = false
    WoodysToolkit_acctData["lockSuppressed"] = false
    WoodysToolkit_acctData["btn1backsup"] = false
    WoodysToolkit_acctData["version"] = 1
end

function WoodysMouse:InitVars()
    if type(WoodysToolkit_acctData) ~= "table" then
      self:Reset()
    end
end

local function WoodMouse_InitVars()
    WoodysMouse:InitVars()
end

local function WoodMouse_Reset()
    WoodysMouse:Reset()
end

local function ML_debug(...)
    if not DEFAULT_CHAT_FRAME or not WoodysMouse.debug then return end
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

local function WoodMouse_GetVar(varname)
    if type(WoodysToolkit_acctData) ~= "table" then
        return nil
    else
        return WoodysToolkit_acctData[varname]
    end
end

local function WoodMouse_SetVar(varname, varval)
    --print("newval - ", varname, " : ", varval)
    WoodMouse_InitVars()
    WoodysToolkit_acctData[varname] = varval
end

local function WoodMouse_InitBindings()
    local b1name = "WoodMouse_mode_disable"
    if WoodMouse_GetVar("btn1backsup") then
      b1name = "MOVEBACKWARD"
    end
    SetMouselookOverrideBinding("BUTTON1", b1name)
    SetMouselookOverrideBinding("BUTTON2", "MOVEFORWARD")
end

local function WoodMouse_ApplyMode()
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

function WoodMouse_Enable()
    WoodMouse_SetVar("lockEnabled", true)
    WoodMouse_ApplyMode()
end

function WoodMouse_Disable()
    WoodMouse_SetVar("lockEnabled", false)
    WoodMouse_ApplyMode()
end

function WoodMouse_Toggle()
    local newval = not WoodMouse_GetVar("lockEnabled")
    WoodMouse_SetVar("lockEnabled", newval)
    WoodMouse_ApplyMode()
end

function WoodMouse_Momentary(keystate)
    local newval = keystate == "down"
    WoodMouse_SetVar("lockSuppressed", newval)
    WoodMouse_ApplyMode()
end

function WoodMouse_SlashCommand(msg, editbox)
 local command, rest = msg:match("^(%S*)%s*(.-)$");
 -- Any leading non-whitespace is captured into command;
 -- the rest (minus leading whitespace) is captured into rest.
 if command == "reset" then
    WoodMouse_Reset()
 elseif command == "button1" then
   if rest == "backup" then
     WoodMouse_SetVar("btn1backsup", true)
     WoodMouse_InitBindings()
   elseif rest == "cancel" then
     WoodMouse_SetVar("btn1backsup", false)
     WoodMouse_InitBindings()
   else
     local curval = WoodMouse_GetVar("btn1backsup") and 'backup' or 'cancel'
     print("button1 : ", curval)
   end
 elseif command == "remove" and rest ~= "" then
   -- Handle removing of the contents of rest... to something.
   -- print(command, " : \"", rest, "\" )
   print(command, " : ", string.format("%s%s%s",'"',rest,'"') )
 else
   -- If not handled above, display some sort of help message
   print("Usage: /woodmouse button1 [backup||cancel]");
 end
end

function WoodMouse_OnLoad(self,...)
    WoodMouseFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    WoodMouse_InitBindings()
    SLASH_WoodMouse1, SLASH_WoodMouse2 = '/woodmouse', "/woodysmouse";
    SlashCmdList["WoodMouse"] = WoodMouse_SlashCommand; -- Also a valid assignment strategy
end;

function WoodMouse_OnEvent(self,event,...)
    --Print("on event:" ..event)
    if event == "PLAYER_ENTERING_WORLD" then
        --Print("PLAYER_ENTERING_WORLD event")
        WoodMouse_InitVars()
        WoodMouse_InitBindings()
        WoodMouse_ApplyMode()
    end
end
