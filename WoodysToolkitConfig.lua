local myFrames = {}

function WoodysToolkitConfig_Close(self,...)
    WtkAddon.utils.printd("WoodysToolkitConfig_Close")

    for index, keyid in ipairs(WoodysToolkit:GetOverrideBindingKeys()) do
        local valBox = myFrames["WoodysConfigEditBoxVal" .. index]
        if valBox then
            local actionid = valBox:GetText()
            WoodysToolkit:PutOverrideBinding(keyid, actionid)
        end
        -- print('SetMouselookOverrideBinding("' .. k .. '", ' .. val .. ')')
    end
    WoodysToolkit:InitBindings()
end

function WoodysToolkitConfig_Refresh(self,...)
    WtkAddon.utils.printd("WoodysToolkitConfig_Refresh")
    for index, keyid in ipairs(WoodysToolkit:GetOverrideBindingKeys()) do
        WtkAddon.utils.printd("WoodysToolkitConfig_Refresh: " .. tostring(index))
        local editBox = myFrames["WoodysConfigEditBoxBindingName" .. index]
        if editBox then
            editBox:SetText("")
            editBox:SetText(keyid or "")
            editBox:SetCursorPosition(0)
        end
        local valBox = myFrames["WoodysConfigEditBoxVal" .. index]
        if valBox then
            local actionid = WoodysToolkit:GetOverrideBindingAction(keyid)
            valBox:SetText("")
            valBox:SetText(actionid or "")
            valBox:SetCursorPosition(0)
        end
        -- print('SetMouselookOverrideBinding("' .. k .. '", ' .. val .. ')')
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
    myFrames[name] = editBox
end

local function WoodysToolkitConfig_CreateOverrideWidget(index)
    WoodysToolkitConfig_CreateEditBox("WoodysConfigEditBoxBindingName" .. index, 20, index * -30)
    WoodysToolkitConfig_CreateEditBox("WoodysConfigEditBoxVal" .. index, 300, index * -30)
end

function WoodysToolkitConfig_OnLoad(panel,...)

    myFrames.Parent = panel

    for ii in ipairs(WoodysToolkit:GetOverrideBindingKeys()) do
        WoodysToolkitConfig_CreateOverrideWidget(ii)
    end

    -- Set the name for the Category for the Panel
    --
    panel.name = WoodysToolkit:GetConfigPanelName()

    -- When the player clicks okay, run this function.
    --
    panel.okay = function (self)
        WoodysToolkitConfig_Close();
    end;

    -- When the player clicks default, run this function.
    --
    panel.refresh = function (self)
        WoodysToolkitConfig_Refresh();
    end;


    -- When the player clicks cancel, run this function.
    --
    panel.cancel = function (self)
        WoodysToolkitConfig_CancelOrLoad();
    end;

    -- Add the panel to the Interface Options
    --
    InterfaceOptions_AddCategory(panel);
end
