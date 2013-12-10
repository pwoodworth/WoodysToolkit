local b = CreateFrame("Button", "WoodysEscapeButton", UIParent, "SecureActionButtonTemplate")
b:SetAttribute("type", "stop")

C_StorePublic.IsDisabledByParentalControls = function () return false end