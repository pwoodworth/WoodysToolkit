local L = LibStub("AceLocale-3.0"):NewLocale("WoodysToolkit", "enUS", true, true)
if L then

L["options.name"] = [[Woody's Toolkit Options]]

L["options.config.name"] = [[Open options dialog]]

L["options.escapeButton.group.name"] = "Escape Button"
L["options.escapeButton.header"] = [[Custom Escape Button]]
L["options.escapeButton.name"] = [[Enable custom escape button]]

L["options.idbpcHack.name"] = [[Enable IsDisabledByParentalControls workaround]]

L["options.viewport.group.name"] = "Viewport"
L["options.viewport.header"] = [[Custom Viewport]]
L["options.viewport.name"] = [[Enable Viewport]]
L["options.viewport.coords.name"] = [[Viewport Coordinates]]

L["options.misc.header.name"] = "Miscellaneous"
L["options.reloadui.name"] = "Reload UI"

-- L["WTK"] = true
L["WTK"] = "Woody's Toolkit"
L["WTK left click"] = "|cffffff00Left-click|r to open/close options menu"
L["WTK right click"] = "|cffffff00Right-click|r to toggle locking all bar groups"
L["WTK shift left click"] = "|cffffff00Shift-left-click|r to enable/disable Woody's Toolkit"
L["WTK shift right click"] = "|cffffff00Shift-right-click|r to toggle Blizzard buffs"

L["mouse.lock.defer.desc"] = [[When clicking and holding any mouse button while ]]
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

L["mouse.lock.bind.desc"] = [[Enable to define a set of keybindings that only apply while mouselooking. ]]
    .. [[For example, you could strafe with the left (BUTTON1) and right (BUTTON2) mouse buttons.]]


L["Added"] = "Added"
L["Add item"] = "Add item"
L["Automatically sell junk"] = "Automatically sell junk"
L["Clear"] = "Clear"
L["Clear exceptions"] = "Clear exceptions"
L["Command accepts only itemlinks."] = "Command accepts only itemlinks."
L["copper"] = "copper"
L["Destroyed"] = "Destroyed"
L["Drag item into this window to add/remove it from exception list"] = "Drag item into this window to add/remove it from exception list"
L["Exceptions"] = "Exceptions"
L["Exceptions succesfully cleared."] = "Exceptions succesfully cleared."
L["Gained"] = "Gained"
L["gold"] = "gold"
L["<Item Link>"] = "<Item Link>"
L["Prints itemlinks to chat, when automatically selling items."] = "Prints itemlinks to chat, when automatically selling items."
L["Removed"] = "Removed"
L["Remove item"] = "Remove item"
L["Removes all exceptions."] = "Removes all exceptions."
L["Sell Junk"] = "Sell Junk"
L["Sell max. 12 items"] = "Sell max. 12 items"
L["Show gold gained"] = "Show gold gained"
L["Show 'item sold' spam"] = "Show 'item sold' spam"
L["Shows gold gained from selling trash."] = "Shows gold gained from selling trash."
L["silver"] = "silver"
L["Sold"] = "Sold"
L["This is failsafe mode. Will sell only 12 items in one pass. In case of an error, all items can be bought back from vendor."] = "This is failsafe mode. Will sell only 12 items in one pass. In case of an error, all items can be bought back from vendor."
L["Toggles the automatic selling of junk when the merchant window is opened."] = "Toggles the automatic selling of junk when the merchant window is opened."

end
