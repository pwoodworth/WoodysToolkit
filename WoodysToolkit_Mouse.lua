_G["BINDING_HEADER_MOUSELOOKHANDLER"] = "MouselookHandler"
_G["BINDING_NAME_INVERTMOUSELOOK"]    = "Invert Mouselook"
_G["BINDING_NAME_TOGGLEMOUSELOOK"]    = "Toggle Mouselook"
_G["BINDING_NAME_LOCKMOUSELOOK"]      = "Enable Mouselook"
_G["BINDING_NAME_UNLOCKMOUSELOOK"]    = "Disable Mouselook"

--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G
setfenv(1, WoodysToolkit)

MODNAME = "WoodysToolkit"

local WoodysToolkit = _G.WoodysToolkit
local MOD = WoodysToolkit
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("WoodysToolkit", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local MyAddOn = LibStub("AceAddon-3.0"):GetAddon(MODNAME)


local MouselookHandler = _G.WoodysToolkit

local IsMouselooking = _G.IsMouselooking
local MouselookStart, MouselookStop = _G.MouselookStart, _G.MouselookStop

local modName = "MouselookHandler"

local customEventFrame

local shouldMouselook = false

turnOrActionActive, cameraOrSelectOrMoveActive = false, false
clauseText = nil

enabled, inverted = false, false

function MouselookHandler:predFun(enabled, inverted, clauseText, event, ...)
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
    MouselookStop(); return
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

function update(event, ...)
  local shouldMouselookOld = shouldMouselook
  shouldMouselook = MouselookHandler:predFun(enabled, inverted, clauseText, event, ...)
  if shouldMouselook ~= shouldMouselookOld then
    rematch()
  end
end

function invert()
  inverted = true
  update()
end

function revert()
  inverted = false
  update()
end

function toggle()
  enabled = not enabled
  update()
end

function lock()
  enabled = true
  update()
end

function unlock()
  enabled = false
  update()
end

local handlerFrame = _G.CreateFrame("Frame", modName .. "handlerFrame")

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
  --_G.print("MouselookHandler loaded!")
  self:UnregisterEvent("ADDON_LOADED")
  self.ADDON_LOADED = nil
end

handlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
handlerFrame:RegisterEvent("PLAYER_LOGIN")
handlerFrame:RegisterEvent("ADDON_LOADED")

--------------------------------------------------------------------------------
-- < in-game configuration UI code > -------------------------------------------
--------------------------------------------------------------------------------

local function applyOverrideBindings(info, val)
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
for _, v in _G.ipairs({"UNLOCKMOUSELOOK", "MOVEFORWARD", "MOVEBACKWARD", "TOGGLEAUTORUN",
  "STRAFELEFT", "STRAFERIGHT"}) do
  suggestedCommands[v] = _G.GetBindingText(v, "BINDING_NAME_")
end

-- The key in the "Override bindings" section of the options frame that's currently being
-- configured.
local selectedKey

-- Array containing all the keys from db.profile.mouseOverrideBindings.
local overrideKeys = {}

local deferText = [[When clicking and holding any mouse button while ]]
  .. [[mouselooking, but only releasing it after stopping mouselooking, the ]]
  .. [[mouse button's binding won't be run on release.]] .. '\n'
  .. [[    For example, consider having "BUTTON1" bound to "STRAFELEFT". ]]
  .. [[Now, when mouselook is active and the left mouse button is pressed ]]
  .. [[and held, stopping mouselook will result in releasing the mouse ]]
  .. [[button to no longer have it's effect of cancelling strafing. ]]
  .. [[Instead, the player will be locked into strafing left until ]]
  .. [[clicking the left mouse button again.]] .. '\n'
  .. [[    This setting will cause slightly less obnoxious behavior: it will ]]
  .. [[defer stopping mouselook until all mouse buttons have been released.]]

local bindText = [[Enable to define a set of keybindings that only apply while mouselooking. ]]
  .. [[For example, you could strafe with the left (BUTTON1) and right (BUTTON2) mouse buttons.]]

local spellTargetingOverrideText = [[Disable mouselook while a spell is awaiting a target.]]

--local options = {
--  type = "group",
--  name = "MouselookHandler Options",
--  handler = MouselookHandler,
--  childGroups = "tree",
--  args = {
--  },
--}

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

local thisPlugin = {
  name = "Mouse",
  defaults = {
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
}

function thisPlugin:OnInitialize()
  for k, _ in _G.pairs(db.profile.mouseOverrideBindings) do
    if not (_G.type(k) == "string") then
      db.profile.mouseOverrideBindings[k] = nil
    else
      _G.table.insert(overrideKeys, (k))
    end
  end
  _G.table.sort(overrideKeys)
  update()
end

function thisPlugin:ApplySettings()
  applyOverrideBindings()
end

function thisPlugin:CreateOptions()
  local options = {
    general = {
      type = "group",
      name = "General",
      order = 100,
      args = {
        deferHeader = {
          type = "header",
          name = "Defer stopping mouselook",
          order = 0,
        },
        deferDescription = {
          type = "description",
          name = deferText,
          fontSize = "medium",
          order = 1,
        },
        deferToggle = {
          type = "toggle",
          name = "Enable defer workaround",
          width = "full",
          set = function(info, val) db.profile.useDeferWorkaround = val end,
          get = function(info) return db.profile.useDeferWorkaround  end,
          order = 2,
        },
        spellTargetingOverrideHeader = {
          type = "header",
          name = "Disable while targeting spell",
          order = 6,
        },
        spellTargetingOverrideDescription = {
          type = "description",
          name = spellTargetingOverrideText,
          fontSize = "medium",
          order = 7,
        },
        spellTargetingOverrideToggle = {
          type = "toggle",
          name = "Enable",
          width = "full",
          set = function(info, val) db.profile.useSpellTargetingOverride = val end,
          get = function(info) return db.profile.useSpellTargetingOverride end,
          order = 8,
        },
      },
    },
    overrideBindings = {
      type = "group",
      name = "Override bindings",
      order = 110,
      args = {
        overrideBindingsHeader = {
          type = "header",
          name = "Mouselook override bindings",
          order = 100,
        },
        overrideBindingsDescription = {
          type = "description",
          name = bindText,
          fontSize = "medium",
          order = 110,
        },
        overrideBindingsToggle = {
          type = "toggle",
          name = "Use override bindings",
          width = "full",
          set = setUseOverrideBindings,
          get = getUseOverrideBindings,
          order = 120,
        },
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
              --overrideKeys[#overrideKeys + 1] = val
              _G.table.insert(overrideKeys, val)
              -- http://stackoverflow.com/questions/2038418/associatively-sorting-a-table-by-v
              _G.table.sort(overrideKeys, function(a, b)
                return a < b
              end)
            end
            for i = 0, #overrideKeys do
              if overrideKeys[i] == val then
                selectedKey = i
                return
              end
            end
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
          values = function() return overrideKeys end,
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
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          set = function(info, val)
            db.profile.mouseOverrideBindings[overrideKeys[selectedKey]] = val
            applyOverrideBindings()
          end,
          get = function(info)
            return db.profile.mouseOverrideBindings[overrideKeys[selectedKey]]
          end,
          order = 180,
        },
        commandInput = {
          name = "Command",
          desc = "The command to perform; can be any name attribute value of a " ..
              "Bindings.xml-defined binding, or an action command string.",
          type = "input",
          width = "double",
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          set = function(info, val)
            if val == "" then val = nil end
            db.profile.mouseOverrideBindings[overrideKeys[selectedKey]] = val
            applyOverrideBindings()
          end,
          get = function(info)
            return db.profile.mouseOverrideBindings[overrideKeys[selectedKey]]
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
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          fontSize = "medium",
          order = 200,
        },
        spacer1 = {
          type = "description",
          name = "",
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          order = 210,
        },
        clearBindingButton = {
          type = "execute",
          name = "Delete",
          desc = "Delete the selected override binding.",
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          width = "half",
          confirm = true,
          confirmText = "This can't be undone. Continue?",
          func = function()
            _G.SetMouselookOverrideBinding(overrideKeys[selectedKey], nil)
            db.profile.mouseOverrideBindings[overrideKeys[selectedKey]] = nil
            -- This wont shift down the remaining integer keys: overrideKeys[selectedKey] = nil
            _G.table.remove(overrideKeys, selectedKey)
            selectedKey = 0
          end,
          order = 220,
        },
        deleteBindingDescription = {
          type = "description",
          name = "    Clear the selected override binding.",
          hidden = function() return not selectedKey or not overrideKeys[selectedKey] end,
          width = "double",
          fontSize = "medium",
          order = 230,
        },
      },
    },
    advanced = {
      type = "group",
      name = "Advanced",
      order = 120,
      args = {
        header1 = {
          type = "header",
          name = "Lua chunk",
          order = 0,
        },
        desc1 = {
          type = "description",
          name = "You can provide a chunk of Lua code that will " ..
              "be compiled and ran when loading the addon " ..
              "(and when you change the Lua chunk). " ..
              "It must define a function " ..
              "\'MouselookHandler:predFun\' which will control " ..
              "when mouselook is started and stopped and " ..
              "gets called with these arguments:\n" ..
              " - the current default mouselook state (boolean),\n" ..
              " - the state of the temporary inversion switch; " ..
              "true while the key assigned is being held down (boolean),\n" ..
              " - the clause text obtained from your macro string; " ..
              "i.e., the text after whichever set of conditions applied (string), " ..
              "if any, and otherwise nil.\n\n" ..
              "Additionally, if it was called in response to an event the name " ..
              "of the event (string) and the event's specific arguments will be passed " ..
              "(See |cFF3366BBhttp://wowprogramming.com/docs/events|r).\n" ..
              "    Mouselook will be enabled if true is returned and disabled otherwise.",
          fontSize = "medium",
          order = 1,
        },
        header2 = {
          type = "header",
          name = "Reset advanced settings",
          order = 4,
        },
        desc2 = {
          type = "description",
          name = "Reenter the default events, macro text and function.",
          fontSize = "medium",
          width = "double",
          order = 5,
        },
        advanced1 = {
          type = "group",
          name = "Lua chunk",
          args = {
            header2 = {
              type = "header",
              name = "Reload UI",
              order = 2,
            },
            desc1 = {
              type = "description",
              name = "Useful to get rid of side effects introduced by previous Lua chunks " ..
                  "(e.g. global variables or hooks from hooksecurefunc()). Otherwise unnecessary.",
              fontSize = "medium",
              width = "double",
              order = 3,
            },
            reloadButton = {
              type = "execute",
              name = "Reload",
              width = "half",
              func = function()
                _G.ReloadUI()
              end,
              order = 4,
            },
          },
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
          name = _G["BINDING_NAME_TOGGLEMOUSELOOK"],
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
            local oldKey = (_G.GetBindingKey("TOGGLEMOUSELOOK"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "TOGGLEMOUSELOOK")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("TOGGLEMOUSELOOK")) end,
          order = 2,
        },
        invertHeader = {
          type = "header",
          name = _G["BINDING_NAME_INVERTMOUSELOOK"],
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
            local oldKey = (_G.GetBindingKey("INVERTMOUSELOOK"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "INVERTMOUSELOOK")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("INVERTMOUSELOOK")) end,
          order = 5,
        },
        lockHeader = {
          type = "header",
          name = _G["BINDING_NAME_LOCKMOUSELOOK"],
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
            local oldKey = (_G.GetBindingKey("LOCKMOUSELOOK"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "LOCKMOUSELOOK")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("LOCKMOUSELOOK")) end,
          order = 8,
        },
        unlockHeader = {
          type = "header",
          name = _G["BINDING_NAME_UNLOCKMOUSELOOK"],
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
            local oldKey = (_G.GetBindingKey("UNLOCKMOUSELOOK"))
            if oldKey then _G.SetBinding(oldKey) end
            _G.SetBinding(key, "UNLOCKMOUSELOOK")
            _G.SaveBindings(_G.GetCurrentBindingSet())
          end,
          get = function(info) return (_G.GetBindingKey("UNLOCKMOUSELOOK")) end,
          order = 11,
        },
      },
    },
  }
  return options
end

mPlugins = mPlugins or {}
mPlugins["mouse"] = thisPlugin
