--[[------------------------------------------------------------
    WoodysToolkitConfig
--------------------------------------------------------------]]

local printd = WoodyToolkit.utils.printd
local status = WoodyToolkit.utils.status

WoodysGuiToolkit = {}

WoodysGuiToolkit.prototype = {}

function WoodysGuiToolkit.prototype.GetBindingFieldName(self, index)
    return self.frames.Parent:GetName() .. "BindingEditor" .. index
end

function WoodysGuiToolkit.prototype.GetBindingField(self, index)
    local name = self:GetBindingFieldName(index)
    return self.frames[name]
end

function WoodysGuiToolkit.prototype.GetOrCreateBindingField(self, index)
    local name = self:GetBindingFieldName(index)
    local editBox = self.frames[name]
    if not editBox then
        editBox = CreateFrame("EditBox", name, self.frames.Parent, "WoodysToolkitInputBoxTemplate")
        editBox:SetPoint("TOPLEFT", self.frames.Parent, "TOPLEFT", 20, index * -30)
        editBox:Disable()
--        editBox:SetNormalFontObject("GameFontHighlight");
--        local font = editBox:GetNormalFontObject();
--        font:SetTextColor(1, 0.5, 0.25, 1.0);
--        editBox:SetNormalFontObject(font);
        self.frames[name] = editBox
    end
    return editBox
end

function WoodysGuiToolkit.prototype.GetActionFieldName(self, index)
    return self.frames.Parent:GetName() .. "ActionEditor" .. index
end

function WoodysGuiToolkit.prototype.GetActionField(self, index)
    local name = self:GetActionFieldName(index)
    return self.frames[name]
end

function WoodysGuiToolkit.prototype.GetOrCreateActionField(self, index)
    local name = self:GetActionFieldName(index)
    local editBox = self.frames[name]
    if not editBox then
        editBox = CreateFrame("EditBox", name, self.frames.Parent, "WoodysToolkitInputBoxFancyTemplate")
        editBox:SetPoint("TOPLEFT", self.frames.Parent, "TOPLEFT", 300, index * -30)
        self.frames[name] = editBox
    end
    return editBox
end

WoodysGuiToolkit.mt = {}

function WoodysGuiToolkit.new(o)
    if not o.frames then o.frames = {} end
    setmetatable(o, WoodysGuiToolkit.mt)
    return o
end

WoodysGuiToolkit.mt.__index = function(table, key)
    return WoodysGuiToolkit.prototype[key]
end

gWtkConfig = WoodysGuiToolkit.new({})

function WoodysToolkitConfig_Close(panel,...)
    printd("panel.okay: status(parent == panel) = " .. status(gWtkConfig.frames.Parent == panel))
    printd("panel.okay: parent:GetName() = " .. gWtkConfig.frames.Parent:GetName())
    for index, keyid in ipairs(WtkAddon:GetOverrideBindingKeys()) do
        local valBox = gWtkConfig:GetActionField(index)
        if valBox then
            local actionid = valBox:GetText()
            WtkAddon:PutOverrideBinding(keyid, actionid)
        end
    end
    WtkAddon:InitBindings()
end

function WoodysToolkitConfig_Refresh(panel,...)
    printd("panel.refresh: status(parent == panel) = " .. status(gWtkConfig.frames.Parent == panel))
    for index, keyid in ipairs(WtkAddon:GetOverrideBindingKeys()) do
        local editBox = gWtkConfig:GetOrCreateBindingField(index)
        if editBox then
            editBox:SetText("")
            editBox:SetText(keyid or "")
            editBox:SetCursorPosition(0)
        end
        local valBox = gWtkConfig:GetOrCreateActionField(index)
        if valBox then
            local actionid = WtkAddon:GetOverrideBindingAction(keyid)
            valBox:SetText("")
            valBox:SetText(actionid or "")
            valBox:SetCursorPosition(0)
        end
    end

end

function WoodysToolkitConfig_CancelOrLoad(panel,...)
    printd("panel.cancel: status(parent == panel) = " .. status(gWtkConfig.frames.Parent == panel))
end

function WoodysToolkitConfig_OnLoad(panel,...)

    gWtkConfig.frames.Parent = panel

--    for ii in ipairs(WtkAddon:GetOverrideBindingKeys()) do
--        gWtkConfig:CreateOverrideWidget(ii)
--    end

    -- Set the name for the Category for the Panel
    --
    panel.name = WtkAddon:GetConfigPanelName()

    -- When the player clicks okay, run this function.
    --
    panel.okay = WoodysToolkitConfig_Close

    -- When the player clicks default, run this function.
    --
    panel.refresh = WoodysToolkitConfig_Refresh

    -- When the player clicks cancel, run this function.
    --
    panel.cancel = WoodysToolkitConfig_CancelOrLoad

    -- Add the panel to the Interface Options
    --
    InterfaceOptions_AddCategory(panel);
end
