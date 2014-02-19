--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
local howdy = _G.getfenv(1)
WoodysToolkit._G = WoodysToolkit._G or _G

-- Set the environment of the current function to the global table WoodysToolkit.
-- See: http://www.lua.org/pil/14.3.html
--setmetatable(WoodysToolkit, getmetatable(WoodysToolkit) or {__index = _G})
setfenv(1, WoodysToolkit)

local howdy2 = _G.getfenv(1)

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
local string_find = _G.string.find
local pairs = _G.pairs
local wipe = _G.wipe
local DeleteCursorItem = _G.DeleteCursorItem
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetItemInfo = _G.GetItemInfo
local PickupContainerItem = _G.PickupContainerItem
local PickupMerchantItem = _G.PickupMerchantItem
local IsAddOnLoaded = _G.IsAddOnLoaded
local select = _G.select
local COPPER_PER_SILVER = _G.COPPER_PER_SILVER
local SILVER_PER_GOLD = _G.SILVER_PER_GOLD

function WoodysToolkit:MERCHANT_SHOW2()
  print("howdy: "..(_G.tostring(howdy == WoodysToolkit)))
  print("howdy2: "..(_G.tostring(howdy2 == WoodysToolkit)))
  print("MyAddOn: "..(_G.tostring(MyAddOn == WoodysToolkit)))
  local ameta = _G.getmetatable(WoodysToolkit)
  print("metaidx: "..(_G.tostring(ameta["__index"] == _G)))

--  if MyAddOn.db.profile.selljunk.auto then
--    self:JunkSell()
--  end
end
