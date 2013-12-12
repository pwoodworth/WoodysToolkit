local L = LibStub("AceLocale-3.0"):NewLocale("MouselookHandler", "enUS", true, true)
if L then

L["options.name"] = [[MouselookHandler Options]]
L["options.general.name"] = [[General]]
L["options.keybindings.name"] = [[Keybindings]]
L["options.advanced.name"] = [[Advanced]]

L["options.defer.header"] = [[Defer stopping mouselook]]
L["options.defer.description"] = ""
    .. [[When clicking and holding any mouse button while ]]
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
L["options.defer.name"] = [[Enable defer workaround]]

L["options.bind.header"] = [[Strafe with left and right mouse while mouselooking]]
L["options.bind.description"] = ""
    .. [[Assign the "STRAFELEFT" and "STRAFERIGHT" actions to ]]
    .. [["BUTTON1" (left mouse button) and "BUTTON2" (right mouse button), ]]
    .. [[respectively.]] .. '\n'
    .. [[    While not mouselooking through this Addon those bindings don't ]]
    .. [[apply.]]
L["options.bind.name"] = [[Enable override bindings]]

L["options.spellTargetingOverride.header"] = [[Disable while targeting spell]]
L["options.spellTargetingOverride.description"] = [[Disable mouselook while a spell is awaiting a target.]]
L["options.spellTargetingOverride.name"] = [[Enable]]

L["options.luachunk.header"] = "Lua chunk"
L["options.luachunk.description"] = ""
    .. "You can provide a chunk of Lua code that will "
    .. "be compiled and ran when loading the addon "
    .. "(and when you change the Lua chunk). "
    .. "It must define a function "
    .. "\'MouselookHandler:predFun\' which will control "
    .. "when mouselook is started and stopped and "
    .. "gets called with these arguments:\n"
    .. " - the current default mouselook state (boolean),\n"
    .. " - the state of the temporary inversion switch; "
    .. "true while the key assigned is being held down (boolean),\n"
    .. " - the clause text obtained from your macro string; "
    .. "i.e., the text after whichever set of conditions applied (string), "
    .. "if any, and otherwise nil.\n\n"
    .. "Additionally, if it was called in response to an event the name "
    .. "of the event (string) and the event's specific arguments will "
    .. "be passed (See: wowprogramming.com/docs/events).\n"
    .. "    Mouselook will be enabled if true is returned and disabled otherwise."

L["options.luachunk.events.name"] = "Event list"
L["options.luachunk.events.desc"] = "Your function will be updated every time one of these events fires. Separate with spaces."

L["options.luachunk.macros.name"] = "Macro conditions"
L["options.luachunk.macros.desc"] = "Your function will be reevaluated whenever the macro conditions entered here change."


L["options.reloadui.header"] = "Reload UI"
L["options.reloadui.description"] = ""
    .. "Useful to get rid of side effects introduced by previous Lua chunks "
    .. "(e.g. global variables or hooks from hooksecurefunc()). Otherwise unnecessary."
L["options.reloadui.name"] = "Reload"

end
