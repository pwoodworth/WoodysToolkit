--[[------------------------------------------------------------
    WoodyToolkit class
--------------------------------------------------------------]]

WoodysToolkit_acctData = {}

WoodyToolkit = {}

WoodyToolkit.utils = {}

function WoodyToolkit.utils.createSet(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function WoodyToolkit.utils.printd(text)
    if not DEFAULT_CHAT_FRAME or not WoodysToolkit_debug then return end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

function WoodyToolkit.utils.status(bool)
    if bool then return "true" else return "false" end
end

local printd = WoodyToolkit.utils.printd

WoodyToolkit.const = {}

WoodyToolkit.const.GOOD_DATAKEY_SET = WoodyToolkit.utils.createSet({
        "version",
        "bindings",
        "lockEnabled",
        "lockSuppressed",
    })

WoodyToolkit.const.OVERRIDE_KEYID_LIST = {
        "BUTTON1",
        "BUTTON2",
        "BUTTON3",
    }

WoodyToolkit.const.OVERRIDE_DEFAULTS = {
        BUTTON1 = "WOODYSMOUSELOCKSTOP",
        BUTTON2 = "MOVEFORWARD",
    }


WoodyToolkit.const.OVERRIDE_KEYID_SET = WoodyToolkit.utils.createSet(WoodyToolkit.const.OVERRIDE_KEYID_LIST)


WoodyToolkit.prototype = {}

WoodyToolkit.prototype.data = setmetatable({}, {
    __index = function(table, key)
        if key == "debug" then
            return WoodysToolkit_debug and true
        elseif not WoodyToolkit.const.GOOD_DATAKEY_SET[key] then
            printd("WARNING: Attempted get of non-whitelisted field: " .. key)
        elseif type(WoodysToolkit_acctData) == "table" then
            return WoodysToolkit_acctData[key]
        end
    end,
    __newindex = function(table, key, value)
        if key == "debug" then
            WoodysToolkit_debug = value and true
        elseif not WoodyToolkit.const.GOOD_DATAKEY_SET[key] then
            printd("WARNING: Attempted set of non-whitelisted field: " .. key)
        else
            if type(WoodysToolkit_acctData) ~= "table" then
                WoodysToolkit_acctData = {}
            end
            WoodysToolkit_acctData[key] = value
        end
    end
})

function WoodyToolkit.prototype.GetOverrideBindingKeys(self)
    return WoodyToolkit.const.OVERRIDE_KEYID_LIST
end

function WoodyToolkit.prototype.GetOverrideBindingAction(self, keyid)
    local bindings = self.data.bindings
    if type(bindings) ~= "table" then
        bindings = {}
        self.data.bindings = bindings
    end
    local defaultAction = WoodyToolkit.const.OVERRIDE_DEFAULTS[keyid]
    local actionid = bindings[keyid]
    if not actionid or actionid == "" then
        actionid = defaultAction
    end
    return actionid
end

function WoodyToolkit.prototype.PutOverrideBinding(self, keyid, actionid)
    local keyset = WoodyToolkit.const.OVERRIDE_KEYID_SET
    if not keyset[keyid] then
        return false
    end
    local defaultAction = WoodyToolkit.const.OVERRIDE_DEFAULTS[keyid]
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

function WoodyToolkit.prototype.GetConfigPanelName(self)
    return "WoodysToolkit" -- .. GetAddOnMetadata("WoodysToolkit", "Version");
end

function WoodyToolkit.prototype.InitBindings(self)
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

function WoodyToolkit.prototype.ApplyMode(self)
    local shouldBeLooking = self.data.lockEnabled and not self.data.lockSuppressed
    if shouldBeLooking then
        MouselookStart()
    else
        MouselookStop()
    end
end

function WoodyToolkit.prototype.ResetAddonState(self)
    WoodysToolkit_acctData = {}
    self:InitBindings()
    self:ApplyMode()
end

function WoodyToolkit.prototype.StartMouseLock(self)
    self.data.lockEnabled = true
    self:ApplyMode()
end

function WoodyToolkit.prototype.StopMouseLock(self)
    if self.state.moving then return end
    self.data.lockEnabled = false
    self:ApplyMode()
end

WoodyToolkit.mt = {}

function WoodyToolkit.new(o)
    if not o.state then
        o.state = {}
    end
    setmetatable(o, WoodyToolkit.mt)
    return o
end

WoodyToolkit.mt.__index = function(table, key)
    return WoodyToolkit.prototype[key]
end

WoodyToolkit.mt.__newindex = function(table, key, value)
    if WoodyToolkit.prototype[key] then
        printd("WARNING: Attempted set of protected field: " .. key)
    else
        rawset(table, key, value)
    end
end
