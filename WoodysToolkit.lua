BINDING_HEADER_WOODYSTOOLKIT = 'WoodysToolkit'
BINDING_NAME_WOODYSMOUSELOCKTOGGLE  = "Toggle MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTART  = "Enable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTOP  = "Disable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKPAUSE    = "Suspend MouseLook While Pressed"

WoodysToolkit_debug = false
WoodysToolkit_acctData = {}

do
    local function IsDebug()
        return WoodysToolkit_debug and true
    end

    local function WTK_debug(...)
        if not DEFAULT_CHAT_FRAME or not IsDebug() then return end
        local msg = ''
        for k,v in ipairs(arg) do
            msg = msg .. tostring(v) .. ' : '
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    local function printd(text)
        if not DEFAULT_CHAT_FRAME or not IsDebug() then return end
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end

    local function printi(text)
        if not DEFAULT_CHAT_FRAME then return end
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end

    local function status(bool)
        if bool then return "true" else return "false" end
    end

    local function CreateSet(list)
        local set = {}
        for _, l in ipairs(list) do set[l] = true end
        return set
    end

    WTKUtil = {
        printd = printd,
        printi = printi,
        status = status,
        CreateSet = CreateSet,
    }
end

local status = WTKUtil.status
local printi = WTKUtil.printi
local printd = WTKUtil.printd
local WTK_createSet = WTKUtil.CreateSet

WoodysToolkit = {
    GOOD_DATAKEY_SET = WTKUtil.CreateSet({
        "version",
        "bindings",
        "lockEnabled",
        "lockSuppressed",
    }),
    OVERRIDE_KEYID_LIST = {
        "BUTTON1",
        "BUTTON2",
        "BUTTON3",
    },
    OVERRIDE_DEFAULTS = {
        BUTTON1 = "WOODYSMOUSELOCKSTOP",
        BUTTON2 = "MOVEFORWARD",
    }
}

WoodysToolkit.OVERRIDE_KEYID_SET = WTKUtil.CreateSet(WoodysToolkit.OVERRIDE_KEYID_LIST)

do
    local function WTK_GetValidatedData()
        if type(WoodysToolkit_acctData) ~= "table" then
            WoodysToolkit_acctData = {}
        end
        local items = WoodysToolkit.GOOD_DATAKEY_SET
        for k,v in pairs(WoodysToolkit_acctData) do
            if not items[k] then
                WoodysToolkit_acctData[k] = nil
            end
        end
        return WoodysToolkit_acctData
    end

    local data = setmetatable({}, {
        __index = function(table, key)
            if key == "debug" then
                return WoodysToolkit_debug and true
            end
            return WTK_GetValidatedData()[key]
        end,
        __newindex = function(table, key, value)
            if key == "debug" then
                WoodysToolkit_debug = value and true
                return
            end
            WTK_GetValidatedData()[key] = value
        end
    })

     setmetatable(WoodysToolkit, {
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

    function WoodysToolkit:GetOverrideBindingKeys()
        return self.OVERRIDE_KEYID_LIST
    end

    function WoodysToolkit:GetOverrideBindingAction(keyid)
        local bindings = self.data.bindings
        if type(bindings) ~= "table" then
            bindings = {}
            self.data.bindings = bindings
        end
        local defaultAction = WoodysToolkit.OVERRIDE_DEFAULTS[keyid]
        local actionid = bindings[keyid]
        if not actionid or actionid == "" then
            actionid = defaultAction
        end
        return actionid
    end

    function WoodysToolkit:PutOverrideBinding(keyid, actionid)
        local keyset = self.OVERRIDE_KEYID_SET
        if not keyset[keyid] then
            return false
        end
        local defaultAction = WoodysToolkit.OVERRIDE_DEFAULTS[keyid]
        if type(actionid) ~= "string" or actionid == "" or actionid == defaultAction then
            actionid = nil
        end

        local bindings = self.data.bindings
        if type(bindings) ~= "table" then
            bindings = {}
            self.data.bindings = bindings
        end

        bindings[keyid] = actionid
        return true
    end

    function WoodysToolkit:GetConfigPanelName()
        return "WoodysToolkit" -- .. GetAddOnMetadata("WoodysToolkit", "Version");
    end

    function WoodysToolkit:InitBindings()
        for index, keyid in ipairs(self:GetOverrideBindingKeys()) do
            local val = self:GetOverrideBindingAction(keyid)
            if not val or val == "" or type(val) ~= "string" then
                val = nil
                printd('SetMouselookOverrideBinding("' .. keyid .. '", ' .. tostring(val) .. ')')
            else
                printd('SetMouselookOverrideBinding("' .. keyid .. '", "' .. val .. '")')
            end
            SetMouselookOverrideBinding(keyid, val)
        end
    end

    function WoodysToolkit:ApplyMode()
        local shouldBeLooking = self.data.lockEnabled and not self.data.lockSuppressed
        if shouldBeLooking then
            MouselookStart()
        else
            MouselookStop()
        end
    end

    function WoodysToolkit:ResetAddonState()
        WoodysToolkit_acctData = {}
        WoodysToolkit:InitBindings()
        WoodysToolkit:ApplyMode()
    end
end

local data = WoodysToolkit.data

local statedata = {}

local function WTK_ApplyMode()
    WoodysToolkit:ApplyMode()
end

local function WTK_ResetAddon()
    WoodysToolkit:ResetAddonState()
end

local function WTK_StartMouseLock()
    data.lockEnabled = true
    WTK_ApplyMode()
end

local function WTK_StopMouseLock()
    if statedata.moving then return end
    data.lockEnabled = false
    WTK_ApplyMode()
end

function WoodysToolkit_StartBindingImpl()
    WTK_StartMouseLock()
end

function WoodysToolkit_StopBindingImpl()
    WTK_StopMouseLock()
end

function WoodysToolkit_ToggleBindingImpl()
    if data.lockEnabled then
        WTK_StopMouseLock()
    else
        WTK_StartMouseLock()
    end
end

function WoodysToolkit_PauseBindingImpl(keystate)
    data.lockSuppressed = (keystate == "down")
    printd("lockSuppressed: " .. status(data.lockSuppressed))
    WTK_ApplyMode()
end

do
    local function WoodysToolkit_MoveAndSteerStop()
        statedata.steering = false
        WTK_StopMouseLock()
        printd('statedata.steering: ' .. status(statedata.steering))
    end

    local function WoodysToolkit_HookHandler(statekey, stateval)
        statedata[statekey] = stateval
        printd('statedata.' .. statekey .. ': ' .. tostring(statedata[statekey]))
    end

    local function WoodysToolkit_HookIt(funcname, statekey, stateval)
        hooksecurefunc(funcname, function()
            WoodysToolkit_HookHandler(statekey, stateval)
        end);
    end

    WoodysToolkit_HookIt("MoveAndSteerStart", "steering", true);
    WoodysToolkit_HookIt("TurnOrActionStart", "turning", true);
    WoodysToolkit_HookIt("TurnOrActionStop", "turning", false);
    WoodysToolkit_HookIt("CameraOrSelectOrMoveStart", "camera", true);
    WoodysToolkit_HookIt("CameraOrSelectOrMoveStop", "camera", false);
    WoodysToolkit_HookIt("MoveForwardStart", "moving", true);
    WoodysToolkit_HookIt("MoveForwardStop", "moving", false);
    WoodysToolkit_HookIt("MoveBackwardStart", "moving", true);
    WoodysToolkit_HookIt("MoveBackwardStop", "moving", false);

    hooksecurefunc("MoveAndSteerStop", WoodysToolkit_MoveAndSteerStop);
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
        WTK_ResetAddon()
    elseif command == "remove" and rest ~= "" then
        -- Handle removing of the contents of rest... to something.
        -- print(command, " : \"", rest, "\" )
        print(command, " : ", string.format("%s%s%s", '"', rest, '"'))
    else
        -- If not handled above, display some sort of help message
        print("Usage: /woodystoolkit [reset||debug]");
        InterfaceOptionsFrame_OpenToCategory(WoodysToolkit:GetConfigPanelName());
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
        WoodysToolkit:InitBindings()
        WTK_ApplyMode()
    end
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
