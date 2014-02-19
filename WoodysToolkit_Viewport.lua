--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G
setfenv(1, WoodysToolkit)

MODNAME = "WoodysToolkit"

local WoodysToolkit = _G.WoodysToolkit
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("WoodysToolkit", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local MyAddOn = LibStub("AceAddon-3.0"):GetAddon(MODNAME)

-- upvalues
local print = print or _G.print
local string = string or _G.string
local floor = _G.floor
local mod = _G.mod
local pairs = _G.pairs
local wipe = _G.wipe
local select = _G.select

local thisPlugin = {
  name = "Viewport",
  defaults = {
    enable = false,
    top = 0,
    bottom = 0,
    left = 0,
    right = 0
  },
}

function thisPlugin:ApplySettings()
  createSellButton()
  if MyAddOn.db.profile.selljunk.auto then
    MyAddOn:JunkSell()
  end
end

function thisPlugin:CreateOptions()
  local options = {
    header = {
      type = "header",
      name = L["options.viewport.header"],
      order = 1,
    },
    toggle = {
      type = "toggle",
      name = L["options.viewport.name"],
      width = "full",
      get = getViewportToggle,
      set = setViewportToggle,
      order = 2,
    },
    top = {
      type = "range",
      name = L["Top"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[2] / 2,
      step = 1,
      bigStep = 5,
      order = 34,
    },
    bottom = {
      type = "range",
      name = L["Bottom"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[2] / 2,
      step = 1,
      bigStep = 5,
      order = 36,
    },
    left = {
      type = "range",
      name = L["Left"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[1] / 2,
      step = 1,
      bigStep = 5,
      order = 38,
    },
    right = {
      type = "range",
      name = L["Right"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[1] / 2,
      step = 1,
      bigStep = 5,
      order = 39,
    },
  }
  return options
end

mPlugins = mPlugins or {}
mPlugins["viewport"] = thisPlugin
