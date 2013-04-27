--[[------------------------------------------------------------
    WtkAddon instance
--------------------------------------------------------------]]

BINDING_HEADER_WOODYSTOOLKIT = 'WoodysToolkit'
BINDING_NAME_WOODYSMOUSELOCKTOGGLE  = "Toggle MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTART  = "Enable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKSTOP  = "Disable MouseLook Lock"
BINDING_NAME_WOODYSMOUSELOCKPAUSE    = "Suspend MouseLook While Pressed"

local printd = WoodyToolkit.utils.printd

WtkAddon = WoodyToolkit.new({})

function WoodysToolkit_StartBindingImpl()
    WtkAddon:StartMouseLock()
end

function WoodysToolkit_StopBindingImpl()
    WtkAddon:StopMouseLock()
end

function WoodysToolkit_ToggleBindingImpl()
    if WtkAddon.data.lockEnabled then
        WtkAddon:StopMouseLock()
    else
        WtkAddon:StartMouseLock()
    end
end

function WoodysToolkit_PauseBindingImpl(keystate)
    WtkAddon.data.lockSuppressed = (keystate == "down")
    printd("lockSuppressed: " .. WoodyToolkit.utils.status(WtkAddon.data.lockSuppressed))
    WtkAddon:ApplyMode()
end

local function WoodysToolkit_MoveAndSteerStop()
    WtkAddon.state.steering = false
    WtkAddon:StopMouseLock()
    printd('WtkAddon.state.steering: ' .. WoodyToolkit.utils.status(WtkAddon.state.steering))
end

local function WoodysToolkit_HookHandler(statekey, stateval)
    WtkAddon.state[statekey] = stateval
    printd('WtkAddon.state.' .. statekey .. ': ' .. tostring(WtkAddon.state[statekey]))
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

WtkAddon.COMMANDS = {
    debug = function(msg, command, rest)
        if rest == "true" or rest == "on" then
            WtkAddon.data.debug = true
        elseif rest ~= "" then
            WtkAddon.data.debug = false
        end
        print("debug: " .. WoodyToolkit.utils.status(WtkAddon.data.debug))
    end,
    config = function(msg, command, rest)
        InterfaceOptionsFrame_OpenToCategory(WtkAddon:GetConfigPanelName());
    end,
    reset = function(msg, command, rest)
        WtkAddon:ResetAddonState()
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
    local cmdfunc = WtkAddon.COMMANDS[command]
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
        WtkAddon.COMMANDS.config(msg, command, rest)
--        InterfaceOptionsFrame_OpenToCategory(WtkAddon:GetConfigPanelName());
    end
end

function WoodysToolkit_OnLoad(self,...)
    printd("WoodysToolkit_OnLoad: " .. type(self))
    WoodysToolkitFrame:RegisterEvent("ADDON_LOADED")
    WoodysToolkitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SLASH_WoodysToolkit1, SLASH_WoodysToolkit2 = '/woodystoolkit', "/wtk";
    SlashCmdList["WoodysToolkit"] = WoodysToolkit_SlashCommand; -- Also a valid assignment strategy
end;

function WoodysToolkit_OnEvent(self,event,...)
    printd("on event: " .. event)
    if event == "PLAYER_ENTERING_WORLD" then
        WtkAddon:InitBindings()
        WtkAddon:ApplyMode()
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
--    print("button1.action " .. WtkAddon.button1.action);
-- end
