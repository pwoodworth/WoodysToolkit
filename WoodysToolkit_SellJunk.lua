--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G

-- Set the environment of the current function to the global table WoodysToolkit.
-- See: http://www.lua.org/pil/14.3.html
setfenv(1, WoodysToolkit)

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

--------------------------------------------------------------------------------
-- SellJunk
--------------------------------------------------------------------------------

local function createSellButton()
  if MyAddOn.sellButton then
    return
  end
  MyAddOn.sellButton = _G.CreateFrame("Button", nil, _G.MerchantFrame, "OptionsButtonTemplate")
  if IsAddOnLoaded("GnomishVendorShrinker") then
    MyAddOn.sellButton:SetPoint("TOPRIGHT", -23, 0)
  else
    MyAddOn.sellButton:SetPoint("TOPLEFT", 60, -32)
  end
  MyAddOn.sellButton:SetText(L["Destroy Junk"])
  MyAddOn.sellButton:SetScript("OnClick", function() WoodysToolkit:JunkSell(true) end)
end

local function extractLink(link)
  -- remove all trailing whitespace
  link = _G.strtrim(link)
  -- extract name from an itemlink
  local isLink, _, name = string_find(link, "^|c%x+|H.+|h.(.*)\].+")
  -- if it's not an itemlink, guess it's name of an item
  if not isLink then
    name = link
  end
  return link, isLink, name
end

local function isJunkInList(exceptions, link)
  local link, isLink, name = extractLink(link)
  if exceptions then
    -- looping through global exceptions
    for k, v in pairs(exceptions) do
      if isLink then
        if v == link then
          return true
        end
      elseif k:lower() == name:lower() then
        return true
      end
    end
  end
  return false
end


local function isJunkException(link)
  local link, isLink, name = extractLink(link)
  local exceptions = MyAddOn.db.profile.selljunk.exceptions
  local found = isJunkInList(exceptions, link)
  if found then
    return true
  end
  return false
end

local function getJunkSaleValue(item, bag, slot)
  local grey = string_find(item, "|cff9d9d9d")
  local isException = isJunkException(item)
  if (grey and (not isException)) or ((not grey) and (isException)) then
    local currPrice = select(11, GetItemInfo(item)) * select(2, GetContainerItemInfo(bag, slot))
    -- this should get rid of problems with grey items, that cant be sell to a vendor
    return true, (currPrice > 0), currPrice
--    if currPrice > 0 then
--      return currPrice
--    end
  end
  return false, false, 0
end

local function printGold(total)
  local ret = ""
  local gold = floor(total / (COPPER_PER_SILVER * SILVER_PER_GOLD));
  local silver = floor((total - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
  local copper = mod(total, COPPER_PER_SILVER);
  if gold > 0 then
    ret = gold .. " " .. L["gold"] .. " "
  end
  if silver > 0 or gold > 0 then
    ret = ret .. silver .. " " .. L["silver"] .. " "
  end
  ret = ret .. copper .. " " .. L["copper"]
  if silver > 0 or gold > 0 or copper > 0 then
    MyAddOn:Print(L["Gained"] .. ": " .. ret)
  end
end

-------------------------------------------------------------
-- Sells items:                                            --
--   - grey quality, unless it's in exception list         --
--   - better than grey quality, if it's in exception list --
-------------------------------------------------------------
function MyAddOn:JunkSell(destroy)
  local limit = 0
  local showSpam = MyAddOn.db.profile.selljunk.showSpam
  local max12 = MyAddOn.db.profile.selljunk.max12
  local profit = 0
  for bag = 0, 4 do
    for slot = 1, _G.GetContainerNumSlots(bag) do
      local item = _G.GetContainerItemLink(bag, slot)
      if item then
        local isJunk, sellable, currPrice = getJunkSaleValue(item, bag, slot)
        if isJunk then
          if sellable then
            profit = profit + currPrice
            PickupContainerItem(bag, slot)
            PickupMerchantItem()
            if showSpam then
              print(L["Sold"] .. ": " .. item)
            end
            if max12 then
              limit = limit + 1
              if limit == 12 then
                return
              end
            end
          else
            if destroy then
--              PickupContainerItem(bag, slot)
--              _G.DeleteCursorItem()
              if showSpam then
                print(L["Destroyed"] .. ": " .. item)
              end
            else
              if showSpam then
                print(L["Would Destroy"] .. ": " .. item)
              end
            end
          end
        end
      end
    end
  end

  if self.db.profile.selljunk.printGold then
    printGold(profit)
  end
end

function MyAddOn:JunkAdd(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  exceptions[name] = link
  self:Print(L["Added"] .. ": " .. link)
end

function MyAddOn:JunkRem(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  local found = isJunkInList(exceptions, link)
  if found then
    exceptions[name] = nil
    self:Print(L["Removed"]..": "..link)
  end
end

function MyAddOn:ListExceptions()
  local exceptions = self.db.profile.selljunk.exceptions
  if exceptions then
    for k, v in pairs(exceptions) do
      local link, isLink, name = extractLink(v)
      self:Print(L["Exception"]..": "..link)
    end
  end
end

function MyAddOn:JunkClearDB()
  wipe(self.db.profile.selljunk.destroyables)
  wipe(self.db.profile.selljunk.exceptions)
  self:Print(L["Exceptions succesfully cleared."])
end

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

local thisPlugin = {
  name = "SellJunk",
  defaults = {
    profile = {
      auto = false,
      max12 = true,
      printGold = true,
      showSpam = true,
      exceptions = {},
      destroyables = {},
    },
  }
}

function thisPlugin:MERCHANT_SHOW()
  createSellButton()
  if MyAddOn.db.profile.selljunk.auto then
    MyAddOn:JunkSell()
  end
end

function thisPlugin:CreateOptions()
  local options = {
    divider1 = {
      order = 1,
      type = "description",
      name = "",
    },
    auto = {
      order = 2,
      type = "toggle",
      name = L["Automatically sell junk"],
      desc = L["Toggles the automatic selling of junk when the merchant window is opened."],
      get = function() return MyAddOn.db.profile.selljunk.auto end,
      set = function() MyAddOn.db.profile.selljunk.auto = not MyAddOn.db.profile.selljunk.auto end,
    },
    divider2 = {
      order = 3,
      type = "description",
      name = "",
    },
    max12 = {
      order = 4,
      type = "toggle",
      name = L["Sell max. 12 items"],
      desc = L["This is failsafe mode. Will sell only 12 items in one pass. In case of an error, all items can be bought back from vendor."],
      get = function() return MyAddOn.db.profile.selljunk.max12 end,
      set = function() MyAddOn.db.profile.selljunk.max12 = not MyAddOn.db.profile.selljunk.max12 end,
    },
    divider3 = {
      order = 5,
      type = "description",
      name = "",
    },
    printGold = {
      order = 6,
      type = "toggle",
      name = L["Show gold gained"],
      desc = L["Shows gold gained from selling trash."],
      get = function() return MyAddOn.db.profile.selljunk.printGold end,
      set = function() MyAddOn.db.profile.selljunk.printGold = not MyAddOn.db.profile.selljunk.printGold end,
    },
    divider4 = {
      order = 7,
      type = "description",
      name = "",
    },
    showSpam = {
      order = 8,
      type = "toggle",
      name = L["Show 'item sold' spam"],
      desc = L["Prints itemlinks to chat, when automatically selling items."],
      get = function() return MyAddOn.db.profile.selljunk.showSpam end,
      set = function() MyAddOn.db.profile.selljunk.showSpam = not MyAddOn.db.profile.selljunk.showSpam end,
    },
    divider5 = {
      order = 9,
      type = "header",
      name = L["Clear exceptions"],
    },
    clearglobal = {
      order = 10,
      type = "execute",
      name = L["Clear"],
      desc = L["Removes all exceptions."],
      func = function() MyAddOn:JunkClearDB() end,
    },
    listglobal = {
      order = 11,
      type = "execute",
      name = L["List"],
      desc = L["List all exceptions."],
      func = function() MyAddOn:ListExceptions() end,
    },
    divider6 = {
      order = 12,
      type = "description",
      name = "",
    },
    header1 = {
      order = 13,
      type = "header",
      name = L["Exceptions"],
    },
    note1 = {
      order = 14,
      type = "description",
      name = L["Drag item into this window to add/remove it from exception list"],
    },
    add = {
      order = 15,
      type = "input",
      name = L["Add item"] .. ':',
      usage = L["<Item Link>"],
      get = false,
      set = function(info, v) MyAddOn:JunkAdd(v) end,
    },
    rem = {
      order = 16,
      type = "input",
      name = L["Remove item"] .. ':',
      usage = L["<Item Link>"],
      get = false,
      set = function(info, v) MyAddOn:JunkRem(v) end,
    },
  }
  return options
end

mPlugins = mPlugins or {}
mPlugins["selljunk"] = thisPlugin
