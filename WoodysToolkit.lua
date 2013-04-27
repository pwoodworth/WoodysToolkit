BINDING_HEADER_WOODYSTOOLKIT = 'WoodysToolkit'
BINDING_NAME_WOODYSMOUSELOCKTOGGLE  = "Toggle MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTART  = "Enable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTOP  = "Disable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKPAUSE    = "Suspend MouseLook While Pressed"

WoodysToolkit_acctData = {}

WtkAddon = {}

WtkAddon.utils = {}

function WtkAddon.utils.createSet(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function WtkAddon.utils.printd(text)
    if not DEFAULT_CHAT_FRAME or not WoodysToolkit_debug then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

function WtkAddon.utils.status(bool)
    if bool then return "true" else return "false" end
end

WtkAddon.const = {}

WtkAddon.const.GOOD_DATAKEY_SET = WtkAddon.utils.createSet({
        "version",
        "bindings",
        "lockEnabled",
        "lockSuppressed",
    })

WtkAddon.const.OVERRIDE_KEYID_LIST = {
        "BUTTON1",
        "BUTTON2",
        "BUTTON3",
    }

WtkAddon.const.OVERRIDE_DEFAULTS = {
        BUTTON1 = "WOODYSMOUSELOCKSTOP",
        BUTTON2 = "MOVEFORWARD",
    }


WtkAddon.const.OVERRIDE_KEYID_SET = WtkAddon.utils.createSet(WtkAddon.const.OVERRIDE_KEYID_LIST)


WtkAddon.prototype = {}

WtkAddon.prototype.data = setmetatable({}, {
    __index = function(table, key)
        if key == "debug" then
            return WoodysToolkit_debug and true
        elseif not WtkAddon.const.GOOD_DATAKEY_SET[key] then
            WtkAddon.utils.printd("WARNING: Attempted get of non-whitelisted field: " .. key)
        elseif type(WoodysToolkit_acctData) == "table" then
            return WoodysToolkit_acctData[key]
        end
    end,
    __newindex = function(table, key, value)
        if key == "debug" then
            WoodysToolkit_debug = value and true
        elseif not WtkAddon.const.GOOD_DATAKEY_SET[key] then
            WtkAddon.utils.printd("WARNING: Attempted set of non-whitelisted field: " .. key)
        else
            if type(WoodysToolkit_acctData) ~= "table" then
                WoodysToolkit_acctData = {}
            end
            WoodysToolkit_acctData[key] = value
        end
    end
})

function WtkAddon.prototype.GetOverrideBindingKeys(self)
    return WtkAddon.const.OVERRIDE_KEYID_LIST
end

function WtkAddon.prototype.GetOverrideBindingAction(self, keyid)
    local bindings = self.data.bindings
    if type(bindings) ~= "table" then
        bindings = {}
        self.data.bindings = bindings
    end
    local defaultAction = WtkAddon.const.OVERRIDE_DEFAULTS[keyid]
    local actionid = bindings[keyid]
    if not actionid or actionid == "" then
        actionid = defaultAction
    end
    return actionid
end

function WtkAddon.prototype.PutOverrideBinding(self, keyid, actionid)
    local keyset = WtkAddon.const.OVERRIDE_KEYID_SET
    if not keyset[keyid] then
        return false
    end
    local defaultAction = WtkAddon.const.OVERRIDE_DEFAULTS[keyid]
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

function WtkAddon.prototype.GetConfigPanelName(self)
    return "WoodysToolkit" -- .. GetAddOnMetadata("WoodysToolkit", "Version");
end

function WtkAddon.prototype.InitBindings(self)
    for index, keyid in ipairs(self:GetOverrideBindingKeys()) do
        local val = self:GetOverrideBindingAction(keyid)
        if not val or val == "" or type(val) ~= "string" then
            val = nil
            WtkAddon.utils.printd('SetMouselookOverrideBinding("' .. keyid .. '", ' .. tostring(val) .. ')')
        else
            WtkAddon.utils.printd('SetMouselookOverrideBinding("' .. keyid .. '", "' .. val .. '")')
        end
        SetMouselookOverrideBinding(keyid, val)
    end
end

function WtkAddon.prototype.ApplyMode(self)
    local shouldBeLooking = self.data.lockEnabled and not self.data.lockSuppressed
    if shouldBeLooking then
        MouselookStart()
    else
        MouselookStop()
    end
end

function WtkAddon.prototype.ResetAddonState(self)
    WoodysToolkit_acctData = {}
    self:InitBindings()
    self:ApplyMode()
end

function WtkAddon.prototype.StartMouseLock(self)
    self.data.lockEnabled = true
    self:ApplyMode()
end

function WtkAddon.prototype.StopMouseLock(self)
    if self.state.moving then return end
    self.data.lockEnabled = false
    self:ApplyMode()
end

WtkAddon.mt = {}

function WtkAddon.new(o)
    if not o.state then
        o.state = {}
    end
    setmetatable(o, WtkAddon.mt)
    return o
end

WtkAddon.mt.__index = function(table, key)
    return WtkAddon.prototype[key]
end

WtkAddon.mt.__newindex = function(table, key, value)
    if WtkAddon.prototype[key] then
        WtkAddon.utils.printd("WARNING: Attempted set of protected field: " .. key)
    else
        rawset(table, key, value)
    end
end

local statedata = {}

WoodysToolkit = WtkAddon.new({ state = statedata })

function WoodysToolkit_StartBindingImpl()
    WoodysToolkit:StartMouseLock()
end

function WoodysToolkit_StopBindingImpl()
    WoodysToolkit:StopMouseLock()
end

function WoodysToolkit_ToggleBindingImpl()
    if WoodysToolkit.data.lockEnabled then
        WoodysToolkit:StopMouseLock()
    else
        WoodysToolkit:StartMouseLock()
    end
end

function WoodysToolkit_PauseBindingImpl(keystate)
    WoodysToolkit.data.lockSuppressed = (keystate == "down")
    WtkAddon.utils.printd("lockSuppressed: " .. WtkAddon.utils.status(WoodysToolkit.data.lockSuppressed))
    WoodysToolkit:ApplyMode()
end

do
    local function WoodysToolkit_MoveAndSteerStop()
        WoodysToolkit.state.steering = false
        WoodysToolkit:StopMouseLock()
        WtkAddon.utils.printd('statedata.steering: ' .. WtkAddon.utils.status(WoodysToolkit.state.steering))
    end

    local function WoodysToolkit_HookHandler(statekey, stateval)
        WoodysToolkit.state[statekey] = stateval
        WtkAddon.utils.printd('WoodysToolkit.state.' .. statekey .. ': ' .. tostring(WoodysToolkit.state[statekey]))
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

WoodysToolkit.COMMANDS = {
    debug = function(msg, command, rest)
        if rest == "true" or rest == "on" then
            WoodysToolkit.data.debug = true
        elseif rest ~= "" then
            WoodysToolkit.data.debug = false
        end
        print("debug: " .. WtkAddon.utils.status(WoodysToolkit.data.debug))
    end,
    config = function(msg, command, rest)
        InterfaceOptionsFrame_OpenToCategory(WoodysToolkit:GetConfigPanelName());
    end,
    reset = function(msg, command, rest)
        WoodysToolkit:ResetAddonState()
    end,
    remove = function(msg, command, rest)
        if rest == "" then return true end
        -- Handle removing of the contents of rest... to something.
        -- print(command, " : \"", rest, "\" )
        print(command, " : ", string.format("%s%s%s", '"', rest, '"'))
    end,
}

function WoodysToolkit_SlashCommand(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    -- Any leading non-whitespace is captured into command;
    -- the rest (minus leading whitespace) is captured into rest.
    local cmdfunc = WoodysToolkit.COMMANDS[command]
    local showhelp = false
    if type(cmdfunc) == "function" then
        showhelp = cmdfunc(msg, command, rest)
    else
        print('type(cmdfunc) == ' .. type(cmdfunc) .. '"');
        showhelp = true
    end
    if showhelp then
        -- If not handled above, display some sort of help message
        print("Usage: /woodystoolkit [reset||debug]");
        WoodysToolkit.COMMANDS.config(msg, command, rest)
--        InterfaceOptionsFrame_OpenToCategory(WoodysToolkit:GetConfigPanelName());
    end
end

function WoodysToolkit_OnLoad(self,...)
    WtkAddon.utils.printd("WoodysToolkit_OnLoad: " .. type(self))
    WoodysToolkitFrame:RegisterEvent("ADDON_LOADED")
    WoodysToolkitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
    WtkAddon.utils.printd("on event: " .. event)
    if event == "PLAYER_ENTERING_WORLD" then
        WoodysToolkit:InitBindings()
        WoodysToolkit:ApplyMode()
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
