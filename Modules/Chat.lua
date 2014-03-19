--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
local SUBNAME = "Chat"
local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
setfenv(1, SUB)

function SUB:SetChatWindowSavedPosition(id, point, xOffset, yOffset)
  local data = self.db.profile.windowdata[id]
  data.point, data.xOffset, data.yOffset = point, xOffset, yOffset
end

function SUB:GetChatWindowSavedPosition(id)
  local data = self.db.profile.windowdata[id]
  if not data.point then
    data.point, data.xOffset, data.yOffset = self.hooks.GetChatWindowSavedPosition(id)
  end
  return data.point, data.xOffset, data.yOffset
end

function SUB:SetChatWindowSavedDimensions(id, width, height)
  local data = self.db.profile.windowdata[id]
  data.width, data.height = width, height
end

function SUB:GetChatWindowSavedDimensions(id)
  local data = self.db.profile.windowdata[id]
  if not data.width then
    data.width, data.height = self.hooks.GetChatWindowSavedDimensions(id)
  end
  return data.width, data.height
end

function SUB:UpdateWindowData()
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame" .. i]
    if frame and type(frame.GetID) == "function" then
      FloatingChatFrame_Update(frame:GetID())
    end
  end
end

local function getEnabledToggle(info)
  return db.profile.clientpos.enabled
end

local function setEnabledToggle(info, val)
  db.profile.clientpos.enabled = val
  SUB:ApplySettings()
end

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

SUB.defaults = {
  profile = {
    clientpos = {
      enabled = false,
    },
    windowdata = {
      ['*'] = {
        -- Blizzard defaults
        width = 430,
        height = 120,
      }
    }
  },
}

function SUB:ApplySettings()
  self:Printd("ApplySettings")
  self:UpdateWindowData()
end

function SUB:CreateOptions()
  local options = {
    header1 = {
      type = "header",
      name = L["Chat Options"],
      order = 10,
    },
    enabled = {
      type = "toggle",
      name = L["Enable client-side positioning"],
      width = "full",
      get = getEnabledToggle,
      set = setEnabledToggle,
      order = 11,
    },
  }
  return options
end

function SUB:OnEnable()
  self:Printd("OnEnable")
--  self:RawHook('SetChatWindowSavedPosition', true)
--  self:RawHook('GetChatWindowSavedPosition', true)
--  self:RawHook('SetChatWindowSavedDimensions', true)
--  self:RawHook('GetChatWindowSavedDimensions', true)
  self:UpdateWindowData()
end

function SUB:OnDisable()
  self:Printd("OnDisable")
  self:UnhookAll()
  self:UpdateWindowData()
end
