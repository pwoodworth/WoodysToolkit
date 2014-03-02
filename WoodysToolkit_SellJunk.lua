--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME = ...
local MOD = LibStub("AceAddon-3.0"):GetAddon(MODNAME)
setfenv(1, MOD)
local SUBNAME = "SellJunk"
local upvalues = setmetatable({}, { __index = _G })
local SUB = MOD:NewModule(SUBNAME, upvalues, "AceConsole-3.0", "AceEvent-3.0")

-- upvalues
local string_find = _G.string.find

--------------------------------------------------------------------------------
-- SellJunk
--------------------------------------------------------------------------------

local function createSellButton()
  if MOD.sellButton then
    return
  end
  MOD.sellButton = _G.CreateFrame("Button", nil, _G.MerchantFrame, "OptionsButtonTemplate")
  if IsAddOnLoaded("GnomishVendorShrinker") then
    MOD.sellButton:SetPoint("TOPRIGHT", -23, 0)
  else
    MOD.sellButton:SetPoint("TOPLEFT", 60, -32)
  end
  MOD.sellButton:SetText(L["Sell Junk"])
  MOD.sellButton:SetScript("OnClick", function() MOD:JunkSell() end)

  _G.StaticPopupDialogs["WoodysToolkit_DestroyConfirmation"] = {
    text = "Do you want to destroy %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function (self, bag, slot)
      local item = _G.GetContainerItemLink(bag, slot)
      if item then
        PickupContainerItem(bag, slot)
        DeleteCursorItem()
        local showSpam = MOD.db.profile.selljunk.showSpam
        if showSpam then
          print(L["Destroyed"] .. ": " .. item)
        end
      end
    end,
    timeout = 30,
    hideOnEscape = true,
  }
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
      end
      if k:lower() == name:lower() then
        return true
      end
    end
  end
  return false
end


local function isJunkException(link)
  local link, isLink, name = extractLink(link)
  local exceptions = MOD.db.profile.selljunk.exceptions
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
    MOD:Print(L["Gained"] .. ": " .. ret)
  end
end

-------------------------------------------------------------
-- Sells items:                                            --
--   - grey quality, unless it's in exception list         --
--   - better than grey quality, if it's in exception list --
-------------------------------------------------------------
function MOD:JunkSell()
  local limit = 0
  local destroy = MOD.db.profile.selljunk.destroy
  local showSpam = MOD.db.profile.selljunk.showSpam
  local max12 = MOD.db.profile.selljunk.max12
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
              local dialog = _G.StaticPopup_Show("WoodysToolkit_DestroyConfirmation", item)
              if (dialog) then
                dialog.data  = bag
                dialog.data2 = slot
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

function MOD:JunkAdd(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  exceptions[name] = link
  self:Print(L["Added"] .. ": " .. link)
end

function MOD:JunkRem(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  local found = isJunkInList(exceptions, link)
  if found then
    exceptions[name] = nil
    self:Print(L["Removed"]..": "..link)
  end
end

function MOD:ListExceptions()
  local exceptions = self.db.profile.selljunk.exceptions
  if exceptions then
    for k, v in pairs(exceptions) do
      local link, isLink, name = extractLink(v)
      self:Print(L["Exception"]..": "..link)
    end
  end
end

function MOD:JunkClearDB()
  wipe(self.db.profile.selljunk.destroyables)
  wipe(self.db.profile.selljunk.exceptions)
  self:Print(L["Exceptions succesfully cleared."])
end

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

SUB.defaults = {
  profile = {
    auto = false,
    destroy = true,
    max12 = true,
    printGold = true,
    showSpam = true,
    exceptions = {},
    destroyables = {},
  },
}

function SUB:MERCHANT_SHOW()
  createSellButton()
  if MOD.db.profile.selljunk.auto then
    MOD:JunkSell()
  end
end

-- Called by AceAddon.
function SUB:OnInitialize()
--  self.db = MOD.db
  self:Print("SUBNAME: " .. SUBNAME)
end

-- Called by AceAddon.
function SUB:OnEnable()
  self:RegisterEvent("MERCHANT_SHOW")
end

-- Called by AceAddon.
function SUB:OnDisable()
  -- Nothing here yet.
end

function SUB:CreateOptions()
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
      get = function() return MOD.db.profile.selljunk.auto end,
      set = function() MOD.db.profile.selljunk.auto = not MOD.db.profile.selljunk.auto end,
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
      get = function() return MOD.db.profile.selljunk.max12 end,
      set = function() MOD.db.profile.selljunk.max12 = not MOD.db.profile.selljunk.max12 end,
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
      get = function() return MOD.db.profile.selljunk.printGold end,
      set = function() MOD.db.profile.selljunk.printGold = not MOD.db.profile.selljunk.printGold end,
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
      get = function() return MOD.db.profile.selljunk.showSpam end,
      set = function() MOD.db.profile.selljunk.showSpam = not MOD.db.profile.selljunk.showSpam end,
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
      func = function() MOD:JunkClearDB() end,
    },
    listglobal = {
      order = 11,
      type = "execute",
      name = L["List"],
      desc = L["List all exceptions."],
      func = function() MOD:ListExceptions() end,
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
      set = function(info, v) MOD:JunkAdd(v) end,
    },
    rem = {
      order = 16,
      type = "input",
      name = L["Remove item"] .. ':',
      usage = L["<Item Link>"],
      get = false,
      set = function(info, v) MOD:JunkRem(v) end,
    },
  }
  return options
end
