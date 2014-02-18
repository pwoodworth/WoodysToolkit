--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G

-- Set the environment of the current function to the global table WoodysToolkit.
-- See: http://www.lua.org/pil/14.3.html
setmetatable(WoodysToolkit, getmetatable(WoodysToolkit) or {__index = _G})
setfenv(1, WoodysToolkit)

_G["BINDING_HEADER_WOODYSTOOLKIT"] = "Woody's Toolkit"

local WoodysToolkit = _G.WoodysToolkit
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("WoodysToolkit", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

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

MODNAME = "WoodysToolkit"

local MyAddOn = LibStub("AceAddon-3.0"):GetAddon(MODNAME)

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

wtkConfigFrame = nil

databaseDefaults = {
  ["global"] = {
    ["version"] = nil,
  },
  ["profile"] = {
    ["stopButtonToggle"] = false,
    ["idbpcHackToggle"] = false,
    ["viewport"] = {
      enable = false,
      top = 0,
      bottom = 0,
      left = 0,
      right = 0
    },
    selljunk = {
      auto = false,
      max12 = true,
      printGold = true,
      showSpam = true,
      exceptions = {},
    },
  },
}

--------------------------------------------------------------------------------
-- IDPC Function Hack
--------------------------------------------------------------------------------

idbpcFunc = nil

local function applyIdpcFuncHack()
  if db.profile.idbpcHackToggle then
    if not idbpcFunc then
      idbpcFunc = _G.C_StorePublic.IsDisabledByParentalControls
      _G.C_StorePublic.IsDisabledByParentalControls = function () return false end
    end
  end
end

local function setIdbpcHackToggle(info, val)
  db.profile.idbpcHackToggle = val
  applyIdpcFuncHack()
end

local function getIdbpcHackToggle(info)
  return db.profile.idbpcHackToggle
end

--------------------------------------------------------------------------------
-- Stop Button
--------------------------------------------------------------------------------

local STOP_BUTTON_NAME = "WoodysStopButton"
local STOP_MACRO_NAME = "wtkstop"

_G.setglobal("MACRO "..STOP_MACRO_NAME, "Stop casting, cancel targeting, and clear target.")

local function createStopButton()
    local b = _G[STOP_BUTTON_NAME] or _G.CreateFrame("Button", STOP_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "stop")
end

local function createStopMacro()
    local body = "/stopcasting\n/cleartarget\n/click "..STOP_BUTTON_NAME
    local idx = _G.GetMacroIndexByName(STOP_MACRO_NAME)
    if (idx == 0) then
        _G.CreateMacro(STOP_MACRO_NAME, "INV_Feather_02", body, nil)
    else
        _G.EditMacro(idx, STOP_MACRO_NAME, nil, body, 1, 1)
    end
end

local function applyStopButton()
  if db.profile.stopButtonToggle then
    createStopButton()
    createStopMacro()
  end
end

local function setStopButtonToggle(info, val)
  db.profile.stopButtonToggle = val
  applyStopButton()
end

local function getStopButtonToggle(info)
  return db.profile.stopButtonToggle
end

--------------------------------------------------------------------------------
-- Viewport
--------------------------------------------------------------------------------

ViewportOverlay = nil
originalViewport = nil

local function getCurrentScreenResolution()
  local resolution = ({_G.GetScreenResolutions()})[_G.GetCurrentResolution()]
  for width, height in string.gmatch(resolution, "(%w+)x(%w+)") do
--     print("w="..k.." h="..v)
    return _G.tonumber(width), _G.tonumber(height)
  end
end

local function getWorldFramePoint(point)
  for ii = 1, _G.WorldFrame:GetNumPoints(), 1 do
    local apoint, relativeTo, relativePoint, xOfs, yOfs = _G.WorldFrame:GetPoint(ii)
    if point == apoint then
      return xOfs, yOfs
    end
  end
end

local function getViewpointScaling()
  local width, height = getCurrentScreenResolution()
  local scaling = 768 / height
  return scaling
end

local function setupViewport(top, bottom, left, right)
  if not ViewportOverlay then
    ViewportOverlay = _G.WorldFrame:CreateTexture(nil, "BACKGROUND")
    ViewportOverlay:SetTexture(0, 0, 0, 1)
    ViewportOverlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, 1)
    ViewportOverlay:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1, -1)
  end

  local topLeftX = left
  local topLeftY = -(top)
  local bottomRightX = -(right)
  local bottomRightY = bottom

  _G.WorldFrame:SetPoint("TOPLEFT", topLeftX, topLeftY)
  _G.WorldFrame:SetPoint("BOTTOMRIGHT", bottomRightX, bottomRightY)
end

local function saveOriginalViewport()
  if not originalViewport then
    local tlX, tlY = getWorldFramePoint("TOPLEFT")
    local brX, brY = getWorldFramePoint("BOTTOMRIGHT")
    originalViewport = {
      top = tlY,
      bottom = brY,
      left = tlX,
      right = brX
    }
  end
end

local function resetViewport()
  if originalViewport then
    local top = -(originalViewport["top"])
    local bottom = originalViewport["bottom"]
    local left = originalViewport["left"]
    local right = -(originalViewport["right"])
    setupViewport(top, bottom, left, right)
    originalViewport = nil
  end
end

local function applyViewport()
  if db.profile.viewport.enable then
    saveOriginalViewport()
    local top = db.profile.viewport["top"]
    local bottom = db.profile.viewport["bottom"]
    local left = db.profile.viewport["left"]
    local right = db.profile.viewport["right"]
    setupViewport(top, bottom, left, right)
  else
    resetViewport()
  end
end

local function getViewportCoordinate(info)
  local key = info[#info]
  local val = db.profile.viewport[key]
  if not val then
    val = 0
  end
  local scaling = getViewpointScaling()
  val = _G.math.floor((val / scaling) + 0.5)
  return val
end

local function setViewportCoordinate(info, val)
  local key = info[#info]
  if not val then
    val = 0
  end
  local scaling = getViewpointScaling()
  val = _G.math.floor((val * scaling) + 0.5)
  db.profile.viewport[key] = val
  applyViewport()
end

local function setViewportToggle(info, val)
  db.profile.viewport.enable = val
  applyViewport()
end

local function getViewportToggle(info)
  return db.profile.viewport.enable
end

--------------------------------------------------------------------------------
-- SellJunk
--------------------------------------------------------------------------------

MyAddOn.sellButton = _G.CreateFrame("Button", nil, MerchantFrame, "OptionsButtonTemplate")

if IsAddOnLoaded("GnomishVendorShrinker") then
  MyAddOn.sellButton:SetPoint("TOPRIGHT", -23, 0)
else
  MyAddOn.sellButton:SetPoint("TOPLEFT", 60, -32)
end

MyAddOn.sellButton:SetText(L["Sell Junk"])
MyAddOn.sellButton:SetScript("OnClick", function() WoodysToolkit:JunkSell() end)

function MyAddOn:AddProfit(profit)
  if profit then
    self.total = self.total + profit
  end
end

-------------------------------------------------------------
-- Sells items:                                            --
--   - grey quality, unless it's in exception list         --
--   - better than grey quality, if it's in exception list --
-------------------------------------------------------------
function MyAddOn:JunkSell()
  local limit = 0
  local currPrice
  local showSpam = MyAddOn.db.profile.selljunk.showSpam
  local max12 = MyAddOn.db.profile.selljunk.max12

  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag, slot)
      if item then
        -- is it grey quality item?
        local grey = string_find(item, "|cff9d9d9d")

        if (grey and (not MyAddOn:isJunkException(item))) or ((not grey) and (MyAddOn:isJunkException(item))) then
          currPrice = select(11, GetItemInfo(item)) * select(2, GetContainerItemInfo(bag, slot))
          -- this should get rid of problems with grey items, that cant be sell to a vendor
          if currPrice > 0 then
            MyAddOn:AddProfit(currPrice)
            PickupContainerItem(bag, slot)
            PickupMerchantItem()
            if showSpam then
              self:Print(L["Sold"] .. ": " .. item)
            end

            if max12 then
              limit = limit + 1
              if limit == 12 then
                return
              end
            end
          end
        end
      end
    end
  end

  if self.db.profile.selljunk.printGold then
    self:PrintGold()
  end
  self.total = 0
end

-------------------------------------------------------------
-- Destroys items:                                         --
--   - grey quality, unless it's in exception list         --
--   - better than grey quality, if it's in exception list --
-------------------------------------------------------------
function MyAddOn:JunkDestroy(count)
  local limit = 9001 -- it's over NINE THOUSAND!!!
  if count ~= nil then
    limit = count
  end

  local showSpam = MyAddOn.db.profile.selljunk.showSpam

  for bag = 0,4 do
    for slot = 1,GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
        -- is it grey quality item?
        local grey = string_find(item,"|cff9d9d9d")

        if (grey and (not MyAddOn:isJunkException(item))) or ((not grey) and (MyAddOn:isJunkException(item))) then
          PickupContainerItem(bag, slot)
          DeleteCursorItem()
          if showSpam then
            self:Print(L["Destroyed"]..": "..item)
          end
          limit = limit - 1
          if limit == 0 then
            break
          end
        end
      end
    end
    if limit == 0 then
      break
    end
  end

  if self.db.profile.selljunk.printGold then
    self:PrintGold()
  end
  self.total = 0
end

function MyAddOn:PrintGold()
  local ret = ""
  local gold = floor(self.total / (COPPER_PER_SILVER * SILVER_PER_GOLD));
  local silver = floor((self.total - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
  local copper = mod(self.total, COPPER_PER_SILVER);
  if gold > 0 then
    ret = gold .. " " .. L["gold"] .. " "
  end
  if silver > 0 or gold > 0 then
    ret = ret .. silver .. " " .. L["silver"] .. " "
  end
  ret = ret .. copper .. " " .. L["copper"]
  if silver > 0 or gold > 0 or copper > 0 then
    self:Print(L["Gained"] .. ": " .. ret)
  end
end

local function extractLink(link)
  -- remove all trailing whitespace
  link = strtrim(link)
  -- extract name from an itemlink
  local isLink, _, name = string_find(link, "^|c%x+|H.+|h.(.*)\].+")
  -- if it's not an itemlink, guess it's name of an item
  if not isLink then
    name = link
  end
  return link, isLink, name
end

function MyAddOn:JunkAdd(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  for k,v in pairs(exceptions) do
    if v == name or v == link then
      return
    end
  end
  -- append name of the item to global exception list
  exceptions[#exceptions + 1] = name
  self:Print(L["Added"] .. ": " .. link)
end

function MyAddOn:JunkRem(link)
  local link, isLink, name = extractLink(link)
  -- looping through exceptions
  local found = false
  local exception
  local exceptions = self.db.profile.selljunk.exceptions
  for k,v in pairs(exceptions) do
    found = false
    -- comparing exception list entry with given name
    if v:lower() == name:lower() then
      found = true
    end

    -- extract name from itemlink (only for compatibility with old saved variables)
    isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
    if isLink then
      -- comparing exception list entry with given name
      if exception:lower() == name:lower() then
        found = true
      end
    end

    if found then
      if exceptions[k + 1] then
        exceptions[k] = exceptions[k + 1]
      else
        exceptions[k] = nil
      end
      self:Print(L["Removed"]..": "..link)
      break
    end
  end
end

function MyAddOn:isJunkException(link)
  local link, isLink, name = extractLink(link)
  local exceptions = self.db.profile.selljunk.exceptions
  local exception = nil
  if exceptions then
    -- looping through global exceptions
    for k, v in pairs(exceptions) do

      -- comparing exception list entry with given name
      if v:lower() == name:lower() then
        return true
      end

      -- extract name from itemlink (only for compatibility with old saved variables)
      isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
      if isLink then
        -- comparing exception list entry with given name
        if exception:lower() == name:lower() then
          return true
        end
      end
    end
  end

  -- item not found in exception list
  return false
end

function MyAddOn:ClearDB()
  wipe(self.db.profile.selljunk.exceptions)
  self:Print(L["Exceptions succesfully cleared."])
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

local options = nil

local function applySettings()
  applyStopButton()
  applyIdpcFuncHack()
  applyViewport()
end

local function copyTable(src, dst)
  local dst = dst or {}
  for k,v in pairs(src) do
    dst[k] = v
  end
  return dst
end

function MyAddOn:CreateOptions()
  local options = {
    type = "group",
    name = L["options.name"],
    handler = WoodysToolkit,
    childGroups = "tree",
    args = {
      config = {
        type = "execute",
        name = L["options.config.name"],
        guiHidden = true,
        func = function()
            if not _G.InCombatLockdown() then
              _G.InterfaceOptionsFrame_OpenToCategory(wtkConfigFrame)
              -- Called twice to workaround UI bug
              _G.InterfaceOptionsFrame_OpenToCategory(wtkConfigFrame)
            end
          end,
        order = 1,
      },
      stopButtonHeader = {
        type = "header",
        name = L["options.escapeButton.header"],
        order = 10,
      },
      stopButton = {
        type = "toggle",
        name = L["options.escapeButton.name"],
        width = "full",
        set = setStopButtonToggle,
        get = getStopButtonToggle,
        order = 11,
      },
      viewport = {
        type = "group",
        name = L["Viewport"],
        guiInline = true,
        order = 20,
        args = {
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
        },
      },
      miscHeader = {
        type = "header",
        name = L["options.misc.header.name"],
        order = 90,
      },
      idbpcHack = {
        type = "toggle",
        name = L["options.idbpcHack.name"],
        width = "full",
        set = setIdbpcHackToggle,
        get = getIdbpcHackToggle,
        order = 91,
      },
      reloadButton = {
        type = "execute",
        name = L["options.reloadui.name"],
        cmdHidden = true,
        width = nil,
        func = function()
          _G.ReloadUI()
        end,
        order = 92,
      },
      selljunk = {
        order = 100,
        type = "group",
        name = "SellJunk",
        guiInline = true,
        args = {
          general = {
            order = 1,
            type = "group",
            name = "global",
            args = {
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
                set = function() self.db.profile.selljunk.auto = not self.db.profile.selljunk.auto end,
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
                set = function() self.db.profile.selljunk.max12 = not self.db.profile.selljunk.max12 end,
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
                set = function() self.db.profile.selljunk.printGold = not self.db.profile.selljunk.printGold end,
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
                func = function() MyAddOn:ClearDB() end,
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
          }
        }
      }
    },
  }
  return options
end

function MyAddOn:PopulateOptions()
  if not options then
    options = {}
    copyTable(MyAddOn:CreateOptions(), options)
  end
end

function WoodysToolkit:RefreshDB()
  WoodysToolkit:Print("Refreshing DB Profile")
  applySettings()
end

--------------------------------------------------------------------------------
-- </ Event Handlers > ------------------------------------------
--------------------------------------------------------------------------------

function WoodysToolkit:ADDON_LOADED()
  --_G.print("Woody's Toolkit loaded!")
  self:UnregisterEvent("ADDON_LOADED")
end

function WoodysToolkit:PLAYER_ENTERING_WORLD()
  applySettings()
end

function WoodysToolkit:PLAYER_LOGIN()
  -- Nothing here yet.
end

function MyAddOn:MERCHANT_SHOW()
  if MyAddOn.db.profile.auto then
    self:JunkSell()
  end
end

WoodysToolkit:RegisterEvent("ADDON_LOADED")
WoodysToolkit:RegisterEvent("PLAYER_ENTERING_WORLD")
WoodysToolkit:RegisterEvent("PLAYER_LOGIN")

--------------------------------------------------------------------------------
-- </ in-game configuration UI code > ------------------------------------------
--------------------------------------------------------------------------------

-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function WoodysToolkit:OnInitialize()
  -- The ".toc" need say "## SavedVariables: WoodysToolkitDB".
  self.db = LibStub("AceDB-3.0"):New(MODNAME .. "DB", databaseDefaults, true)

  local currentVersion = _G.GetAddOnMetadata(MODNAME, "Version")
  self.db.global.version = currentVersion

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  -- See: wowace.com/addons/ace3/pages/getting-started/#w-registering-the-options
  self:PopulateOptions()
  AceConfig:RegisterOptionsTable(MODNAME, options)

  -- Register the Ac3 profile options table
  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_Profiles", profiles)

  wtkConfigFrame = AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit")
  AceConfigDialog:AddToBlizOptions(MODNAME .. "_Profiles", profiles.name, "WoodysToolkit")
  wtkConfigFrame.default = function()
    self.db:ResetProfile()
  end

  LibStub("AceConfigCmd-3.0").CreateChatCommand(WoodysToolkit, "woodystoolkit", MODNAME)
  LibStub("AceConfigCmd-3.0").CreateChatCommand(WoodysToolkit, "wtk", MODNAME)
--   self:RegisterChatCommand("woodystoolkit", "ChatCommand")
--   self:RegisterChatCommand("wtk", "ChatCommand")

  self:RegisterChatCommand("selljunk", "HandleSlashCommands")
  self:RegisterChatCommand("sj", "HandleSlashCommands")

  applySettings()
end

-- Called by AceAddon.
function WoodysToolkit:OnEnable()
  self:RegisterEvent("MERCHANT_SHOW")
  self.total = 0
end

-- Called by AceAddon.
function WoodysToolkit:OnDisable()
  -- Nothing here yet.
end

-- function WoodysToolkit:ChatCommand(input)
--   LibStub("AceConfigCmd-3.0").HandleCommand(WoodysToolkit, "woodystoolkit", MODNAME, input)
-- end

function MyAddOn:HandleSlashCommands(input)
  local arg1, arg2 = self:GetArgs(input, 2, 1, input)
  if arg1 == 'destroy' then
    self:JunkDestroy(arg2)
  elseif arg1 == 'add' and arg2 ~= nil then
    if arg2:find('|Hitem') == nil then
      self:Print(L["Command accepts only itemlinks."])
    else
      self:JunkAdd(arg2, true)
    end
  elseif (arg1 == 'rem' or arg1 == 'remove') and arg2 ~= nil then
    if arg2:find('|Hitem') == nil then
      self:Print(L["Command accepts only itemlinks."])
    else
      self:JunkRem(arg2, true)
    end
  else
    InterfaceOptionsFrame_OpenToCategory(MyAddOn.optionsFrame)
  end
end
