-- Nihui Nameplates - Slash Commands
local addonName, ns = ...

-- Register slash commands
SLASH_NIHUINAMEPLATES1 = "/nnp"
SLASH_NIHUINAMEPLATES2 = "/nihui_np"

SlashCmdList["NIHUINAMEPLATES"] = function(msg)
    local command = string.lower(msg or "")

    if command == "config" then
        if ns.GUI and ns.GUI.Toggle then
            ns.GUI:Toggle()
        else
            print("|cff00ff00Nihui Nameplates:|r GUI not available")
        end
    elseif command == "test" or command == "testcast" then
        -- Test castbar functionality
        if ns.modules.castbar and ns.modules.castbar.TestCastbars then
            ns.modules.castbar:TestCastbars()
        else
            print("|cff00ff00Nihui Nameplates:|r Castbar module or test function not available")
        end
    elseif command == "reload" or command == "rl" then
        ReloadUI()
    else
        if ns.GUI and ns.GUI.Toggle then
            ns.GUI:Toggle()
        else
            print("|cff00ff00Nihui Nameplates:|r GUI not available")
        end
        print("|cff00ff00Nihui Nameplates:|r Available commands:")
        print("  /nnp config - Open configuration")
        print("  /nnp test - Test castbar functionality")
        print("  /nnp reload - Reload UI")
    end
end
