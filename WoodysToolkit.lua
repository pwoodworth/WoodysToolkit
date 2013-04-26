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

WoodysToolkit_GOOD_VARS = {
    "version",
    "bindings",
    "lockEnabled",
    "lockSuppressed",
}


WoodysToolkit_OVERRIDE_BINDINGS = {
    "BUTTON1",
    "BUTTON2",
    "BUTTON3",
}

WoodysToolkit_OVERRIDE_DEFAULTS = {
    BUTTON1 = "WoodysToolkit_mode_disable",
    BUTTON2 = "MOVEFORWARD",
}

local function WTK_createSet(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

local statedata = {}

local function WoodysToolkit_InitData()
    if type(WoodysToolkit_acctData) ~= "table" then
        WoodysToolkit_acctData = {}
    end
    if type(WoodysToolkit_acctData.bindings) ~= "table" then
        WoodysToolkit_acctData.bindings = {}
    end
    local items = WTK_createSet(WoodysToolkit_GOOD_VARS)
    for k,v in pairs(WoodysToolkit_acctData) do
        if not items[k] then
          WoodysToolkit_acctData[k] = nil
        end
    end
end

local function createOverrideEntry(overidx)
    return setmetatable({}, {
        __index = function(table, key, value)
            local bVal = WoodysToolkit_OVERRIDE_BINDINGS[overidx]
            if key == "binding" then
                return bVal
            elseif key == "action" then
                local aVal = WoodysToolkit_acctData.bindings[bVal]
                if not aVal or aVal == "" then
                    if bVal then
                        aVal = WoodysToolkit_OVERRIDE_DEFAULTS[bVal]
                    else
                        aVal = false
                    end
                end
                return aVal
            end
        end,
        __newindex = function(table, key, value)
            local bVal = WoodysToolkit_OVERRIDE_BINDINGS[overidx]
            if key == "action" then
                if type(value) ~= "string" or value == "" or value == WoodysToolkit_OVERRIDE_DEFAULTS[bVal] then
                    WoodysToolkit_acctData.bindings[bVal] = nil
                else
                    WoodysToolkit_acctData.bindings[bVal] = value
                end
            end
        end
    })
end


local function createDataTable()
    local overrides = { }
    for ii in ipairs(WoodysToolkit_OVERRIDE_BINDINGS) do
        overrides[ii] = createOverrideEntry(ii)
    end
    setmetatable(overrides, {
        __newindex = function(table, key, value)
            return
        end
    })

    return setmetatable({}, {
        __index = function(table, key)
            if key == "debug" then
                return WTK_DEBUG
            elseif key == "overrides" then
                WoodysToolkit_InitData()
                return overrides
            end
            WoodysToolkit_InitData()
            return WoodysToolkit_acctData[key]
        end,
        __newindex = function(table, key, value)
            if key == "debug" then
                WTK_DEBUG = value
                return
            elseif key == "overrides" then
                return
            end
            WoodysToolkit_InitData()
            WoodysToolkit_acctData[key] = value
        end
    })
end

local data = createDataTable()

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

local function printd(text)
    if not DEFAULT_CHAT_FRAME or not data.debug then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function printi(text)
    if not DEFAULT_CHAT_FRAME then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function status(bool)
    if bool then return "true" else return "false" end
end

local function WoodysToolkit_InitBindings()
    for index,override in ipairs(data.overrides) do
        local val = override.action
        if not val or val == "" or type(val) ~= "string" then
            val = nil
            printd('SetMouselookOverrideBinding("' .. override.binding .. '", nilit ' .. tostring(val) .. ')')
        else
            printd('SetMouselookOverrideBinding("' .. override.binding .. '", "' .. val .. '")')
--        SetMouselookOverrideBinding(override.binding, val)
        end
        SetMouselookOverrideBinding(override.binding, val)
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

local function WoodysToolkit_GetConfigPanelName()
    return "WoodysToolkit" -- .. GetAddOnMetadata("WoodysToolkit", "Version");
end

function WoodysToolkit_SlashCommand(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    -- Any leading non-whitespace is captured into command;
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "debug" then
        if rest == "true" or rest == "on" then
            data.debug = true
        elseif rest ~= "" then
            data.debug = false
        end
        printi("debug: " .. status(data.debug))
    elseif command == "reset" then
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
        InterfaceOptionsFrame_OpenToCategory(WoodysToolkit_GetConfigPanelName());
    end
end

function WoodysToolkit_OnLoad(self,...)
    WoodysToolkitFrame:RegisterEvent("ADDON_LOADED")
    WoodysToolkitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
    printd("on event: " .. event)
    if event == "PLAYER_ENTERING_WORLD" then
        WoodysToolkit_InitBindings()
        WoodysToolkit_ApplyMode()
    end
end

local myFrames = {}

function WoodysToolkitConfig_Close(self,...)
    printd("WoodysToolkitConfig_Close")
    for index, override in ipairs(data.overrides) do
        local k = override.binding
        local valBox = myFrames["WoodysConfigEditBoxVal" .. index]
        if valBox then
            local val = valBox:GetText()
            override.action = val
        end
--        print('SetMouselookOverrideBinding("' .. k .. '", ' .. val .. ')')
    end
    WoodysToolkit_InitBindings()
end

function WoodysToolkitConfig_Refresh(self,...)
    printd("WoodysToolkitConfig_Refresh")
    for index, override in ipairs(data.overrides) do
        local k = override.binding
        local val = override.action
        local editBox = myFrames["WoodysConfigEditBoxBindingName" .. index]
        if editBox then
            editBox:SetText("")
            editBox:SetText(k or "")
            editBox:SetCursorPosition(0)
        end
        local valBox = myFrames["WoodysConfigEditBoxVal" .. index]
        if valBox then
            valBox:SetText("")
            valBox:SetText(val or "")
            valBox:SetCursorPosition(0)
        end
--        print('SetMouselookOverrideBinding("' .. k .. '", ' .. val .. ')')
    end

end

function WoodysToolkitConfig_CancelOrLoad(self,...)
    -- Set the name for the Category for the Panel
end

local function WoodysToolkitConfig_CreateEditBox(name, xpos, ypos)
    if myFrames[name] then
        return
    end
    local editBox = CreateFrame("EditBox", name, myFrames.Parent, "InputBoxTemplate")
    editBox:SetMaxLetters(80)
    editBox:SetWidth(250)
    editBox:SetHeight(20)
    editBox:SetPoint("TOPLEFT", myFrames.Parent, "TOPLEFT", xpos, ypos)
--    editBox:SetFontObject("ChatFontNormal")
    myFrames[name] = editBox
end

local function WoodysToolkitConfig_CreateOverrideWidget(index)
    WoodysToolkitConfig_CreateEditBox("WoodysConfigEditBoxBindingName" .. index, 20, index * -30)
    WoodysToolkitConfig_CreateEditBox("WoodysConfigEditBoxVal" .. index, 300, index * -30)
end

function WoodysToolkitConfig_OnLoad(panel,...)

    myFrames.Parent = panel

    for ii in ipairs(WoodysToolkit_OVERRIDE_BINDINGS) do
        WoodysToolkitConfig_CreateOverrideWidget(ii)
    end

    -- Set the name for the Category for the Panel
    --
    panel.name = WoodysToolkit_GetConfigPanelName()

    -- When the player clicks okay, run this function.
    --
    panel.okay = function (self)
        WoodysToolkitConfig_Close();
    end;

    -- When the player clicks okay, run this function.
    --
    panel.refresh = function (self)
        WoodysToolkitConfig_Refresh();
    end;


    -- When the player clicks cancel, run this function.
    --
    panel.cancel = function (self)  WoodysToolkitConfig_CancelOrLoad();  end;

    -- Add the panel to the Interface Options
    --
    InterfaceOptions_AddCategory(panel);
end


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
