--[[
COMBAT_LOG_EVENT_UNFILTERED, PLAYER_ENTERING_WORLD, ACTIONBAR_UPDATE_COOLDOWN, SPELL_UPDATE_COOLDOWN
--]]

that = function(event, _, logevent, _, ...)
  local reverse = false
  local trigger = false
  local now = GetTime()
  local start, _, enable = GetInventoryItemCooldown("player", 10)
  local castart, caduration, caenabled = GetSpellCooldown("Celestial Alignment")
  local caleft = 0
  if enable and start and castart and start == 0 and castart > 0 then
    caleft = ((castart + caduration) - now)
    if (caleft > 60) then
      trigger = true
    end
  end
  if trigger ~= reverse then
    -- local prefix = trigger and "TRIGGER" or "UNTRIGGER"
    -- print(prefix.." caleft: "..caleft)
    return true
  end
  return false
end

-- Tempus Repit  -- Sinister Primal Diamond
