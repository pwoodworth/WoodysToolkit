_G["BINDING_HEADER_MOUSELOOKHANDLER"] = "Mouselook Handler"
_G["BINDING_NAME_INVERTMOUSELOOK"] = "Invert Mouselook"
_G["BINDING_NAME_TOGGLEMOUSELOOK"] = "Toggle Mouselook"
_G["BINDING_NAME_LOCKMOUSELOOK"] = "Lock Mouselook"
_G["BINDING_NAME_UNLOCKMOUSELOOK"] = "Unlock Mouselook"

WoodysToolkit = LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0")
WoodysToolkit._G = _G

-- Set the environment of the current function to the global table MouselookHandler.
-- See: http://www.lua.org/pil/14.3.html
setfenv(1, WoodysToolkit)

local WoodysToolkit = _G.MouselookHandler
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("MouselookHandler", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local IsMouselooking = _G.IsMouselooking
local MouselookStart, MouselookStop = _G.MouselookStart, _G.MouselookStop
local SetMouselookOverrideBinding = _G.SetMouselookOverrideBinding

modName = "WoodysToolkit"

local customFunction = nil
function MouselookHandler:predFun() return false end
local stateHandler, customEventFrame = nil, nil

turnOrActionActive, cameraOrSelectOrMoveActive = false, false
clauseText = nil

enabled = false
inverted = false

local function defer()
  if not db.profile.useDeferWorkaround then return end
  for i=1,5 do
    if _G.IsMouseButtonDown(i) then return true end
  end
end

-- Starts ans stops mouselook if the API function IsMouselooking() doesn't
-- match up with this mods saved state.
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
  --shouldMouselook = customFunction(enabled, inverted, clauseText, event, ...)
  local shouldMouselookOld = shouldMouselook
  shouldMouselook = MouselookHandler:predFun(enabled, inverted, clauseText, event, ...)
  if shouldMouselook ~= shouldMouselookOld then rematch() end
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
  --_G.print("Mouselook Handler loaded!")
  self:UnregisterEvent("ADDON_LOADED")
  --self.ADDON_LOADED = nil
end

handlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
handlerFrame:RegisterEvent("PLAYER_LOGIN")
handlerFrame:RegisterEvent("ADDON_LOADED")

--------------------------------------------------------------------------------
-- < in-game configuration UI code > -------------------------------------------
--------------------------------------------------------------------------------

local function applyOverrideBinding(button)
  if db.profile.useOverrideBindings then
    local binding = db.profile.mouseOverrideBindings[button]
    SetMouselookOverrideBinding(button, binding and binding or nil)
  else
    SetMouselookOverrideBinding(button, nil)
  end
end

local function applyUseOverrideBindings(info, val)
  applyOverrideBinding("BUTTON1")
  applyOverrideBinding("BUTTON2")
  applyOverrideBinding("BUTTON3")
end

local function setUseOverrideBindings(info, val)
  db.profile.useOverrideBindings = val
  applyUseOverrideBindings()
end

local function getUseOverrideBindings(info)
  return db.profile.useOverrideBindings
end

local options = {
  type = "group",
  name = L["options.name"],
  handler = MouselookHandler,
  childGroups = "tree",
  args = {
    deferHeader = {
      type = "header",
      name = L["options.defer.header"],
      order = 0,
    },
    deferDescription = {
      type = "description",
      name = L["options.defer.description"],
      fontSize = "medium",
      order = 1,
    },
    deferToggle = {
      type = "toggle",
      name = L["options.defer.name"],
      width = "full",
      set = function(info, val) db.profile.useDeferWorkaround = val end,
      get = function(info) return db.profile.useDeferWorkaround  end,
      order = 2,
    },
    bindHeader = {
      type = "header",
      name = L["options.bind.header"],
      order = 3,
    },
    bindDescription = {
      type = "description",
      name = L["options.bind.description"],
      fontSize = "medium",
      order = 4,
    },
    bindToggle = {
      type = "toggle",
      name = L["options.bind.name"],
      width = "full",
      set = setUseOverrideBindings,
      get = getUseOverrideBindings,
      order = 5,
    },
  },
}

--------------------------------------------------------------------------------
-- </ in-game configuration UI code > ------------------------------------------
--------------------------------------------------------------------------------

databaseDefaults = {
  ["global"] = {
    ["version"] = nil,
  },
  ["profile"] = {
    ["newUser"] = true,
    ["useSpellTargetingOverride"] = true,
    ["useDeferWorkaround"] = true,
    ["useOverrideBindings"] = true,
    ["mouseOverrideBindings"] = {
        ["BUTTON1"] = "STRAFELEFT",
        ["BUTTON2"] = "STRAFERIGHT",
    },
    macroText = "",
    eventList = ""
  },
}

-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function WoodysToolkit:OnInitialize()
  -- The ".toc" need say "## SavedVariables: MouselookHandlerDB".
  self.db = LibStub("AceDB-3.0"):New(addonName .. "DB", databaseDefaults, true)

  local currentVersion = _G.GetAddOnMetadata(modName, "Version")
  self.db.global.version = currentVersion

  if db.profile.newUser then
    WoodysToolkit:Print("This seems to be your first time using this AddOn. To get started " ..
      "you should bring up the configuration UI (/mh) and assign keys to the two actions " ..
      "provided.")
  end

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  if validateCustomFunction(nil, db.profile.customFunction) == true then
    setCustomFunction(nil, db.profile.customFunction)
  end

  -- See: wowace.com/addons/ace3/pages/getting-started/#w-registering-the-options
  AceConfig:RegisterOptionsTable(modName, options)

  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfigRegistry:RegisterOptionsTable(modName .. "_Profiles", profiles)

  local configFrame = AceConfigDialog:AddToBlizOptions(modName, "MouselookHandler", nil, "general")
  AceConfigDialog:AddToBlizOptions(modName, options.args.binds.name, "MouselookHandler", "binds")
  AceConfigDialog:AddToBlizOptions(modName, options.args.advanced.name, "MouselookHandler", "advanced")
  AceConfigDialog:AddToBlizOptions(modName .. "_Profiles", profiles.name, "MouselookHandler")
  configFrame.default = function()
    self.db:ResetProfile()
  end

  --------------------------------------------------------------------------------------------------
  stateHandler = _G.CreateFrame("Frame", modName .. "stateHandler", UIParent, "SecureHandlerStateTemplate")
  function stateHandler:onMouselookState(newstate)
    _G["MouselookHandler"]["clauseText"] = newstate
    _G["MouselookHandler"].update()
  end
  stateHandler:SetAttribute("_onstate-mouselookstate", [[
    self:CallMethod("onMouselookState", newstate)
  ]])
  _G.RegisterStateDriver(stateHandler, "mouselookstate", db.profile.macroText)
  ------------------------------------------------------------------------------
  customEventFrame = _G.CreateFrame("Frame", modName .. "customEventFrame")
  customEventFrame:SetScript("OnEvent", function(self, event, ...)
    _G["MouselookHandler"].update(event, ...)
  end)
  for event in _G.string.gmatch(db.profile.eventList, "[^%s]+") do
    customEventFrame:RegisterEvent(event)
  end
  --------------------------------------------------------------------------------------------------

  local function toggleOptionsUI()
    if not _G.InCombatLockdown() then
      _G.InterfaceOptionsFrame_OpenToCategory(configFrame)
      -- Called twice to workaround UI bug
      _G.InterfaceOptionsFrame_OpenToCategory(configFrame)
      db.profile.newUser = false
    end
  end
  self:RegisterChatCommand("mouselookhandler", toggleOptionsUI)
  self:RegisterChatCommand("mh", toggleOptionsUI)

  update()
end

function WoodysToolkit:RefreshDB()
    MouselookHandler:Print("Refreshing DB Profile")
    applyUseOverrideBindings()
end

-- Called by AceAddon.
function WoodysToolkit:OnEnable()
  -- Nothing here yet.
end

-- Called by AceAddon.
function WoodysToolkit:OnDisable()
  -- Nothing here yet.
end

