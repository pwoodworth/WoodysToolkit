--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
local SUBNAME = "Mouse"
local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, SUB)


_G["BINDING_NAME_WTKMLINVERT"]    = "Invert Mouselook"
_G["BINDING_NAME_WTKMLTOGGLE"]    = "Toggle Mouselook"
_G["BINDING_NAME_WTKMLENABLE"]    = "Enable Mouselook"
_G["BINDING_NAME_WTKMLDISABLE"]   = "Disable Mouselook"

local customEventFrame

local shouldMouselook = false

turnOrActionActive = false
cameraOrSelectOrMoveActive = false
clauseText = nil

mMouseLockEnabled = false
mMouseLockInverted = false

function SUB:predFun(enabled, inverted, clauseText, event, ...)
  return (enabled and not inverted) or (not enabled and inverted)
end

local function defer()
  if not db.profile.useDeferWorkaround then return end
  for i = 1, 5 do
    if _G.IsMouseButtonDown(i) then return true end
  end
end

-- Starts and stops mouselook if the API function IsMouselooking() doesn't match up with this mods
-- saved state.
local function rematch()
  if defer() then return end
  if db.profile.useSpellTargetingOverride and _G.SpellIsTargeting() then
    MouselookStop()
    return
  end
  if turnOrActionActive or cameraOrSelectOrMoveActive then return end

  if not IsMouselooking() then
    if shouldMouselook and not _G.GetCurrentKeyBoardFocus() then
      MouselookStart()
    end
  elseif IsMouselooking() then
    if not shouldMouselook or _G.GetCurrentKeyBoardFocus() then
      MouselookStop()
    end
  end
end

local function updateLock(event, ...)
  local shouldMouselookOld = shouldMouselook
  shouldMouselook = SUB:predFun(mMouseLockEnabled, mMouseLockInverted, clauseText, event, ...)
  if shouldMouselook ~= shouldMouselookOld then
    rematch()
  end
end

function MOD.LockInvert(val)
  mMouseLockInverted = val
  updateLock()
end

function MOD.LockToggle()
  mMouseLockEnabled = not mMouseLockEnabled
  updateLock()
end

function MOD.LockEnable()
  mMouseLockEnabled = true
  updateLock()
end

function MOD.LockDisable()
  mMouseLockEnabled = false
  updateLock()
end

local handlerFrame = _G.CreateFrame("Frame", MODNAME .. "handlerFrame")

-- http://www.wowinterface.com/forums/showthread.php?p=267998
handlerFrame:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function handlerFrame:onUpdate(...)
  rematch()
end

handlerFrame:SetScript("OnUpdate", handlerFrame.onUpdate)

_G.hooksecurefunc("TurnOrActionStart", function()
  turnOrActionActive = true
end)

_G.hooksecurefunc("TurnOrActionStop", function()
  turnOrActionActive = false
end)

_G.hooksecurefunc("CameraOrSelectOrMoveStart", function()
  cameraOrSelectOrMoveActive = true
end)

_G.hooksecurefunc("CameraOrSelectOrMoveStop", function()
  cameraOrSelectOrMoveActive = false
end)

function handlerFrame:PLAYER_ENTERING_WORLD()
  rematch()
end

function handlerFrame:PLAYER_LOGIN()
  -- Nothing here yet.
end

function handlerFrame:ADDON_LOADED()
  self:UnregisterEvent("ADDON_LOADED")
  self.ADDON_LOADED = nil
end

handlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
handlerFrame:RegisterEvent("PLAYER_LOGIN")
handlerFrame:RegisterEvent("ADDON_LOADED")

--------------------------------------------------------------------------------
-- < in-game configuration UI code > -------------------------------------------
--------------------------------------------------------------------------------

local function printDatabaseEntries()
  for k2, v2 in pairs(db.profile) do
    print("  entry: " .. k2 .. " ; type: " .. type(v2))
    if type(v2) == "table" then
      for k3, v3 in pairs(v2) do
        print("    entry: " .. k3 .. " ; type: " .. type(v3))
      end
    end
  end
end

local function applyOverrideBindings(info, val)
--  print("applyOverrideBindings")
--  printDatabaseEntries()
  if db.profile.useOverrideBindings then
    for key, command in _G.pairs(db.profile.mouseOverrideBindings) do
      _G.SetMouselookOverrideBinding(key, command == "" and nil or command)
    end
  else
    for key, _ in _G.pairs(db.profile.mouseOverrideBindings) do
      _G.SetMouselookOverrideBinding(key, nil)
    end
  end
end

local function setUseOverrideBindings(info, val)
  db.profile.useOverrideBindings = val
  applyOverrideBindings()
end

local function getUseOverrideBindings(info)
  return db.profile.useOverrideBindings
end

-- "Hint: Use info[#info] to get the leaf node name, info[#info-1] for the parent, and so on!"
-- http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/#w-callback-arguments

local suggestedCommands = {}
for _, v in _G.ipairs({
  "WTKMLDISABLE",
  "MOVEFORWARD",
  "MOVEBACKWARD",
  "TOGGLEAUTORUN",
  "STRAFELEFT",
  "STRAFERIGHT",
}) do
  suggestedCommands[v] = _G.GetBindingText(v, "BINDING_NAME_")
end

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

SUB.defaults = {
  profile = {
    ["newUser"] = true,
    ["useSpellTargetingOverride"] = true,
    ["useDeferWorkaround"] = true,
    ["useOverrideBindings"] = true,
    ["mouseOverrideBindings"] = {
      ["BUTTON1"] = "STRAFELEFT",
      ["BUTTON2"] = "STRAFERIGHT",
    },
  },
}

function SUB:ApplySettings()
  self:Printd("ApplySettings")
  applyOverrideBindings()
end

function SUB:PLAYER_ENTERING_WORLD()
  self:ApplySettings()
end

SUB:RegisterEvent("PLAYER_ENTERING_WORLD")

-- The key in the "Override bindings" section of the options frame that's currently being
-- configured.
local selectedKey = false


-- Called by AceAddon.
function SUB:OnInitialize()
  self:Printd("OnInitialize")
  self.db = MOD.db:RegisterNamespace(SUBNAME, SUB.defaults)
  db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:ApplySettings()
  updateLock()
end

function SUB:CreateOptions()
  local options = {
    general = {
      type = "group",
      name = "General",
      order = 100,
      args = {
        deferHeader = {
          type = "header",
          name = "General Options",
          order = 1,
        },
        deferToggle = {
          type = "toggle",
          name = "Enable defer stop workaround",
          desc = L["mouse.lock.defer.desc"],
          width = "full",
          set = function(info, val) db.profile.useDeferWorkaround = val end,
          get = function(info) return db.profile.useDeferWorkaround  end,
          order = 2,
        },
        spellTargetingOverrideToggle = {
          type = "toggle",
          name = "Disable while targeting spell",
          desc = L["Disable mouselook while a spell is awaiting a target."],
          width = "full",
          set = function(info, val) db.profile.useSpellTargetingOverride = val end,
          get = function(info) return db.profile.useSpellTargetingOverride end,
          order = 8,
        },
        overrideBindingsToggle = {
          type = "toggle",
          name = "Use mouselook override bindings",
          desc = L["mouse.lock.bind.desc"],
          width = "full",
          set = setUseOverrideBindings,
          get = getUseOverrideBindings,
          order = 12,
        },
      },
    },
    overrideBindings = {
      type = "group",
      name = "Mouselook Override Bindings",
      order = 110,
      hidden = function() return not getUseOverrideBindings() end,
      args = {
        bindingTableHeader = {
          type = "header",
          name = "Binding table",
          order = 130,
        },
        bindingTableDescription = {
          type = "description",
          name = "You can either create a new override binding by entering a binding key " ..
              "(|cFF3366BBhttp://wowprogramming.com/docs/api_types#binding|r) in the " ..
              "editbox, or select an existing override binding from the dropdown menu to " ..
              "review or modify it.",
          fontSize = "medium",
          order = 140,
        },
        newBindingInput = {
          type = "input",
          name = "New",
          desc = "Create a new mouselook override binding.",
          set = function(info, val)
            val = _G.string.upper(val)
            if not db.profile.mouseOverrideBindings[val] then
              db.profile.mouseOverrideBindings[val] = ""
            end
            selectedKey = val
          end,
          get = nil,
          order = 150,
        },
        bindingTableDropdown = {
          type = "select",
          style = "dropdown",
          name = "Key",
          desc = "Select one of your existing mouselook override bindings.",
          width = "normal",
          values = function()
            local overrideKeys = {}
            for k, v in pairs(db.profile.mouseOverrideBindings) do
              overrideKeys[k] = k
            end
            return overrideKeys
          end,
          set = function(info, value)
            selectedKey = value
          end,
          get = function(info)
            return selectedKey
          end,
          order = 160,
        },
        separator1 = {
          type = "header",
          name = "",
          order = 170,
        },
        suggestedCommands = {
          type = "select",
          style = "dropdown",
          name = "Suggestions",
          desc = "You can select one of these suggested actions and have the corresponding " ..
              "command inserted above.",
          values = function(info) return suggestedCommands end,
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          set = function(info, val)
            db.profile.mouseOverrideBindings[selectedKey] = val
            applyOverrideBindings()
          end,
          get = function(info)
            return db.profile.mouseOverrideBindings[selectedKey]
          end,
          order = 180,
        },
        commandInput = {
          name = "Command",
          desc = "The command to perform; can be any name attribute value of a " ..
              "Bindings.xml-defined binding, or an action command string.",
          type = "input",
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          set = function(info, val)
            if val == "" then val = nil end
            db.profile.mouseOverrideBindings[selectedKey] = val
            applyOverrideBindings()
          end,
          get = function(info)
            return db.profile.mouseOverrideBindings[selectedKey]
          end,
          order = 190,
        },
        commandDescription = {
          -- http://en.wikipedia.org/wiki/Help:Link_color
          name = "The command assigned to the key selected above. Can be any name attribute " ..
              "value of a Bindings.xml-defined binding, or an action command string. See " ..
              "|cFF3366BBhttp://wowpedia.org/API_SetBinding|r for more information.\n" ..
              "    You can select one of the suggested actions and have the corresponding " ..
              "command inserted above.",
          type = "description",
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          fontSize = "medium",
          order = 200,
        },
        spacer1 = {
          type = "description",
          name = "",
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          order = 210,
        },
        clearBindingButton = {
          type = "execute",
          name = "Delete",
          desc = "Delete the selected override binding.",
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          width = "half",
          confirm = true,
          confirmText = "This can't be undone. Continue?",
          func = function()
            _G.SetMouselookOverrideBinding(selectedKey, nil)
            db.profile.mouseOverrideBindings[selectedKey] = nil
            selectedKey = false
          end,
          order = 220,
        },
        deleteBindingDescription = {
          type = "description",
          name = "    Clear the selected override binding.",
          hidden = function() return not selectedKey or not db.profile.mouseOverrideBindings[selectedKey] end,
          width = "double",
          fontSize = "medium",
          order = 230,
        },
      },
    },
    binds = {
      type = "group",
      name = "Keybindings",
      order = 130,
      args = {
        toggleHeader = {
          type = "header",
          name = _G["BINDING_NAME_WTKMLTOGGLE"],
          order = 0,
        },
        toggleDescription = {
          type = "description",
          name = "Toggles the normal mouselook state.",
          width = "double",
          fontSize = "medium",
          order = 1,
        },
        toggle = {
          type = "keybinding",
          name = "",
          desc = "Toggles the normal mouselook state.",
          width = "half",
          set = function(info, key)
            local oldKey = (_G.GetBindingKey("WTKMLTOGGLE"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "WTKMLTOGGLE")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("WTKMLTOGGLE")) end,
          order = 2,
        },
        invertHeader = {
          type = "header",
          name = _G["BINDING_NAME_WTKMLINVERT"],
          order = 3,
        },
        invertDescription = {
          type = "description",
          name = "Inverts mouselook while the key is being held.",
          width = "double",
          fontSize = "medium",
          order = 4,
        },
        invert = {
          type = "keybinding",
          name = "",
          desc = "Inverts mouselook while the key is being held.",
          width = "half",
          set = function(info, key)
            local oldKey = (_G.GetBindingKey("WTKMLINVERT"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "WTKMLINVERT")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("WTKMLINVERT")) end,
          order = 5,
        },
        lockHeader = {
          type = "header",
          name = _G["BINDING_NAME_WTKMLENABLE"],
          order = 6,
        },
        lockDescription = {
          type = "description",
          name = "Sets the normal mouselook state to enabled.",
          width = "double",
          fontSize = "medium",
          order = 7,
        },
        lock = {
          type = "keybinding",
          name = "",
          desc = "Sets the normal mouselook state to enabled.",
          width = "half",
          set = function(info, key)
            local oldKey = (_G.GetBindingKey("WTKMLENABLE"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "WTKMLENABLE")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("WTKMLENABLE")) end,
          order = 8,
        },
        unlockHeader = {
          type = "header",
          name = _G["BINDING_NAME_WTKMLDISABLE"],
          order = 9,
        },
        unlockDescription = {
          type = "description",
          name = "Sets the normal mouselook state to disabled.",
          width = "double",
          fontSize = "medium",
          order = 10,
        },
        unlock = {
          type = "keybinding",
          name = "",
          desc = "Sets the normal mouselook state to disabled.",
          width = "half",
          set = function(info, key)
            local oldKey = (_G.GetBindingKey("WTKMLDISABLE"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "WTKMLDISABLE")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("WTKMLDISABLE")) end,
          order = 11,
        },
      },
    },
  }
  return options
end
