-- Nihui Nameplates - Core initialization
local addonName, ns = ...

-- Addon instance
ns.addon = {}
ns.modules = {}

-- Default configuration
local defaults = {
    nameplates = {
        enabled = true,

        -- Health Loss Animations
        healthLoss = {
            enabled = true,
            maxDistance = 60,
            maxConcurrent = 10,
            combatOnly = false,
            enableForPlayer = true,
            enableForFriendlyUnits = true,
            enableForEnemyUnits = true,
            enableForNeutralUnits = true,
        },

        -- Border Settings
        border = {
            enabled = true,
            texture = "Interface\\AddOns\\Nihui_np\\textures\\MirroredFrameSingle2.tga",
            color = {0.5, 0.5, 0.5, 1},
            edgeSize = 13,
            offset = 4,
            blendMode = "BLEND"
        },

        -- Glass Overlay
        glass = {
            enabled = true,
            texture = "Interface\\AddOns\\Nihui_np\\textures\\HPGlass.tga",
            alpha = 1,
            blendMode = "BLEND"
        },

        -- Target Highlight
        targetHighlight = {
            enabled = true,
            color = {1, 1, 0, 1}, -- Yellow
            useAdditive = true,
            removeDefault = false,
            enablePulse = true,
            alphaMax = 1.0,
            alphaMin = 0.6
        },

        -- StatusBar Texture
        statusbar = {
            enabled = true,
            texture = "Interface\\AddOns\\Nihui_np\\textures\\blizzrnxm0.tga"
        },


        -- Castbar Settings
        castbar = {
            enabled = true,
            width = 110,
            height = 12,
            xOffset = 0,
            yOffset = 6,
            showIcon = true,
            showText = false,
            showTimer = true,
            scale = 1.0,

            -- Unit filtering
            enableForPlayer = false,
            enableForFriendlyUnits = false,
            enableForEnemyUnits = true,
            enableForNeutralUnits = true,
        }
    },
}

-- Initialize SavedVariables
function ns.addon:InitializeDB()
    if not NihuiNameplatesDB then
        NihuiNameplatesDB = CopyTable(defaults)
    else
        -- Merge any missing defaults
        for category, settings in pairs(defaults) do
            if not NihuiNameplatesDB[category] then
                NihuiNameplatesDB[category] = CopyTable(settings)
            else
                for key, value in pairs(settings) do
                    if NihuiNameplatesDB[category][key] == nil then
                        NihuiNameplatesDB[category][key] = value
                    elseif type(value) == "table" and type(NihuiNameplatesDB[category][key]) == "table" then
                        for subkey, subvalue in pairs(value) do
                            if NihuiNameplatesDB[category][key][subkey] == nil then
                                NihuiNameplatesDB[category][key][subkey] = subvalue
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Settings accessor
function ns.nameplateSettings()
    return NihuiNameplatesDB.nameplates
end

-- Module registration
function ns.addon:RegisterModule(name, module)
    ns.modules[name] = module
    if module.OnEnable then
        C_Timer.After(1, function()
            module:OnEnable()
        end)
    end
end

-- Event frame for addon events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        ns.addon:InitializeDB()
        print("|cff00ff00Nihui Nameplates|r loaded successfully!")
    elseif event == "PLAYER_LOGIN" then
        -- Initialize modules after login
        for name, module in pairs(ns.modules) do
            if module.OnEnable then
                module:OnEnable()
            end
        end
    end
end)

-- Slash command
SLASH_NIHUINP1 = "/nnp"
SLASH_NIHUINP2 = "/nihuinp"
SlashCmdList["NIHUINP"] = function(msg)
    if msg == "config" or msg == "" then
        if ns.GUI and ns.GUI.Toggle then
            ns.GUI:Toggle()
        else
            print("|cff00ff00Nihui Nameplates:|r GUI not loaded yet")
        end
    elseif msg == "reset" then
        NihuiNameplatesDB = CopyTable(defaults)
        ReloadUI()
    else
        print("|cff00ff00Nihui Nameplates Commands:|r")
        print("/nnp config - Open configuration")
        print("/nnp reset - Reset to defaults (requires reload)")
    end
end