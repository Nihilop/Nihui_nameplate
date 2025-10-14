-- Nihui Nameplates - GUI with AceConfig
local addonName, ns = ...

-- Check if AceConfig is available
local AceConfig = LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
local AceDBOptions = LibStub("AceDBOptions-3.0", true)

if not AceConfig or not AceConfigDialog then
    print("|cff00ff00Nihui Nameplates:|r AceConfig not available, using simple GUI")
    return
end

local GUI = {}
ns.GUI = GUI

-- Create the configuration table
local function CreateConfigTable()
    return {
        type = "group",
        name = "|cff00ff00Nihui|r Nameplates",
        args = {
            enabled = {
                order = 1,
                type = "toggle",
                name = "Enable Nameplate Enhancements",
                desc = "Master toggle for all nameplate features",
                width = "full",
                get = function()
                    return ns.nameplateSettings().enabled
                end,
                set = function(_, val)
                    ns.nameplateSettings().enabled = val
                    if ns.modules.nameplates then
                        if val then
                            ns.modules.nameplates:OnEnable()
                            if ns.modules.borders then ns.modules.borders:OnEnable() end
                            if ns.modules.animations then ns.modules.animations:OnEnable() end
                            if ns.modules.castbar then ns.modules.castbar:OnEnable() end
                        else
                            ns.modules.nameplates:OnDisable()
                            if ns.modules.borders then ns.modules.borders:OnDisable() end
                            if ns.modules.animations then ns.modules.animations:OnDisable() end
                            if ns.modules.castbar then ns.modules.castbar:OnDisable() end
                        end
                    end
                end,
            },

            resetButton = {
                order = 2,
                type = "execute",
                name = "Reset to Defaults",
                desc = "Reset all settings to default values",
                func = function()
                    if ns.Config then
                        ns.Config:ResetToDefaults()
                    end
                end,
                width = 1.5,
                confirm = true,
                confirmText = "Are you sure you want to reset all settings to defaults?",
            },

            -- Health Loss Animations Group
            healthLossGroup = {
                order = 10,
                type = "group",
                name = "Health Loss Animations",
                inline = true,
                disabled = function() return not ns.nameplateSettings().enabled end,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Health Loss Animations",
                        desc = "Show red animation when units lose health",
                        width = "full",
                        get = function()
                            return ns.nameplateSettings().healthLoss.enabled
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.enabled = val
                            ns.Config:UpdateNameplates()
                        end,
                    },

                    maxDistance = {
                        order = 2,
                        type = "range",
                        name = "Max Distance",
                        desc = "Maximum distance to show animations",
                        min = 20,
                        max = 100,
                        step = 5,
                        get = function()
                            return ns.nameplateSettings().healthLoss.maxDistance
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.maxDistance = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    maxConcurrent = {
                        order = 3,
                        type = "range",
                        name = "Max Concurrent",
                        desc = "Maximum number of simultaneous animations",
                        min = 5,
                        max = 50,
                        step = 1,
                        get = function()
                            return ns.nameplateSettings().healthLoss.maxConcurrent
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.maxConcurrent = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    combatOnly = {
                        order = 4,
                        type = "toggle",
                        name = "Combat Only",
                        desc = "Only show animations during combat",
                        get = function()
                            return ns.nameplateSettings().healthLoss.combatOnly
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.combatOnly = val
                            ns.Config:UpdateNameplates()
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    -- Unit Filtering
                    unitFilterHeader = {
                        order = 5,
                        type = "header",
                        name = "Unit Filtering",
                    },

                    enableForPlayer = {
                        order = 6,
                        type = "toggle",
                        name = "Player",
                        desc = "Show animations on player nameplate",
                        get = function()
                            return ns.nameplateSettings().healthLoss.enableForPlayer
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.enableForPlayer = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 0.8,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    enableForFriendlyUnits = {
                        order = 7,
                        type = "toggle",
                        name = "Friendly",
                        desc = "Show animations on friendly units",
                        get = function()
                            return ns.nameplateSettings().healthLoss.enableForFriendlyUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.enableForFriendlyUnits = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 0.8,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    enableForEnemyUnits = {
                        order = 8,
                        type = "toggle",
                        name = "Enemy",
                        desc = "Show animations on enemy units",
                        get = function()
                            return ns.nameplateSettings().healthLoss.enableForEnemyUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.enableForEnemyUnits = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 0.8,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },

                    enableForNeutralUnits = {
                        order = 9,
                        type = "toggle",
                        name = "Neutral",
                        desc = "Show animations on neutral units",
                        get = function()
                            return ns.nameplateSettings().healthLoss.enableForNeutralUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().healthLoss.enableForNeutralUnits = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 0.8,
                        disabled = function()
                            return not ns.nameplateSettings().healthLoss.enabled
                        end,
                    },
                },
            },

            -- Border Settings Group
            borderGroup = {
                order = 20,
                type = "group",
                name = "Border Settings",
                inline = true,
                disabled = function() return not ns.nameplateSettings().enabled end,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Borders",
                        desc = "Add custom borders around nameplates",
                        width = "full",
                        get = function()
                            return ns.nameplateSettings().border.enabled
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().border.enabled = val
                            ns.Config:UpdateNameplates()
                        end,
                    },

                    edgeSize = {
                        order = 2,
                        type = "range",
                        name = "Edge Size",
                        desc = "Size of the border edge",
                        min = 8,
                        max = 20,
                        step = 1,
                        get = function()
                            return ns.nameplateSettings().border.edgeSize
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().border.edgeSize = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().border.enabled
                        end,
                    },

                    offset = {
                        order = 3,
                        type = "range",
                        name = "Offset",
                        desc = "Distance of border from health bar",
                        min = 5,
                        max = 20,
                        step = 0.5,
                        get = function()
                            return ns.nameplateSettings().border.offset
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().border.offset = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().border.enabled
                        end,
                    },

                    color = {
                        order = 4,
                        type = "color",
                        name = "Border Color",
                        desc = "Color of the border",
                        hasAlpha = true,
                        get = function()
                            local color = ns.nameplateSettings().border.color
                            return color[1], color[2], color[3], color[4]
                        end,
                        set = function(_, r, g, b, a)
                            ns.nameplateSettings().border.color = {r, g, b, a}
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.0,
                        disabled = function()
                            return not ns.nameplateSettings().border.enabled
                        end,
                    },
                },
            },

            -- Glass Overlay Group
            glassGroup = {
                order = 30,
                type = "group",
                name = "Glass Overlay",
                inline = true,
                disabled = function() return not ns.nameplateSettings().enabled end,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Glass Effect",
                        desc = "Add glass overlay effect to health bars",
                        width = "full",
                        get = function()
                            return ns.nameplateSettings().glass.enabled
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().glass.enabled = val
                            ns.Config:UpdateNameplates()
                        end,
                    },

                    alpha = {
                        order = 2,
                        type = "range",
                        name = "Glass Alpha",
                        desc = "Transparency of the glass effect",
                        min = 0,
                        max = 1,
                        step = 0.1,
                        get = function()
                            return ns.nameplateSettings().glass.alpha
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().glass.alpha = val
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().glass.enabled
                        end,
                    },
                },
            },

            -- Target Highlight Group
            targetGroup = {
                order = 40,
                type = "group",
                name = "Target Highlight",
                inline = true,
                disabled = function() return not ns.nameplateSettings().enabled end,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Target Highlight",
                        desc = "Highlight the currently targeted nameplate",
                        width = "full",
                        get = function()
                            return ns.nameplateSettings().targetHighlight.enabled
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().targetHighlight.enabled = val
                            ns.Config:UpdateNameplates()
                        end,
                    },

                    removeDefault = {
                        order = 2,
                        type = "toggle",
                        name = "Remove Default Highlight",
                        desc = "Remove Blizzard's default target highlight",
                        get = function()
                            return ns.nameplateSettings().targetHighlight.removeDefault
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().targetHighlight.removeDefault = val
                            ns.Config:UpdateNameplates()
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().targetHighlight.enabled
                        end,
                    },

                    enablePulse = {
                        order = 3,
                        type = "toggle",
                        name = "Enable Pulse Effect",
                        desc = "Add pulsing animation to target highlight",
                        get = function()
                            return ns.nameplateSettings().targetHighlight.enablePulse
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().targetHighlight.enablePulse = val
                            ns.Config:UpdateNameplates()
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().targetHighlight.enabled
                        end,
                    },

                    useAdditive = {
                        order = 4,
                        type = "toggle",
                        name = "Use Additive Blend",
                        desc = "Use additive blending for brighter highlight",
                        get = function()
                            return ns.nameplateSettings().targetHighlight.useAdditive
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().targetHighlight.useAdditive = val
                            ns.Config:UpdateNameplates()
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().targetHighlight.enabled
                        end,
                    },

                    color = {
                        order = 5,
                        type = "color",
                        name = "Highlight Color",
                        desc = "Color of the target highlight",
                        hasAlpha = true,
                        get = function()
                            local color = ns.nameplateSettings().targetHighlight.color
                            return color[1], color[2], color[3], color[4]
                        end,
                        set = function(_, r, g, b, a)
                            ns.nameplateSettings().targetHighlight.color = {r, g, b, a}
                            ns.Config:UpdateNameplates()
                        end,
                        width = 1.0,
                        disabled = function()
                            return not ns.nameplateSettings().targetHighlight.enabled
                        end,
                    },
                },
            },

            -- Castbar Settings Group
            castbarGroup = {
                order = 45,
                type = "group",
                name = "Castbar Settings",
                inline = true,
                disabled = function() return not ns.nameplateSettings().enabled end,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Castbar",
                        desc = "Show casting bars on nameplates",
                        width = "full",
                        get = function()
                            return ns.nameplateSettings().castbar.enabled
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.enabled = val
                            if ns.modules.castbar then
                                if val then
                                    ns.modules.castbar:OnEnable()
                                else
                                    ns.modules.castbar:OnDisable()
                                end
                            end
                        end,
                    },

                    -- Unit Filtering
                    unitFilterHeader = {
                        order = 10,
                        type = "header",
                        name = "Unit Filtering",
                    },

                    enableForPlayer = {
                        order = 11,
                        type = "toggle",
                        name = "Player",
                        desc = "Show castbar on player nameplate",
                        get = function()
                            return ns.nameplateSettings().castbar.enableForPlayer
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.enableForPlayer = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    enableForFriendlyUnits = {
                        order = 12,
                        type = "toggle",
                        name = "Friendly",
                        desc = "Show castbar on friendly units",
                        get = function()
                            return ns.nameplateSettings().castbar.enableForFriendlyUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.enableForFriendlyUnits = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    enableForEnemyUnits = {
                        order = 13,
                        type = "toggle",
                        name = "Enemy",
                        desc = "Show castbar on enemy units",
                        get = function()
                            return ns.nameplateSettings().castbar.enableForEnemyUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.enableForEnemyUnits = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    enableForNeutralUnits = {
                        order = 14,
                        type = "toggle",
                        name = "Neutral",
                        desc = "Show castbar on neutral units",
                        get = function()
                            return ns.nameplateSettings().castbar.enableForNeutralUnits
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.enableForNeutralUnits = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    -- Display Options
                    displayHeader = {
                        order = 20,
                        type = "header",
                        name = "Display Options",
                    },

                    showIcon = {
                        order = 21,
                        type = "toggle",
                        name = "Show Icon",
                        desc = "Display spell icon next to castbar",
                        get = function()
                            return ns.nameplateSettings().castbar.showIcon
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.showIcon = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    showText = {
                        order = 22,
                        type = "toggle",
                        name = "Show Text",
                        desc = "Display spell name below castbar",
                        get = function()
                            return ns.nameplateSettings().castbar.showText
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.showText = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    showTimer = {
                        order = 23,
                        type = "toggle",
                        name = "Show Timer",
                        desc = "Display remaining cast time",
                        get = function()
                            return ns.nameplateSettings().castbar.showTimer
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.showTimer = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    -- Position Options
                    positionHeader = {
                        order = 30,
                        type = "header",
                        name = "Position Options",
                    },

                    yOffset = {
                        order = 31,
                        type = "range",
                        name = "Y Position",
                        desc = "Vertical offset of castbar from nameplate",
                        min = -20,
                        max = 30,
                        step = 1,
                        get = function()
                            return ns.nameplateSettings().castbar.yOffset
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.yOffset = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },

                    hideBlizzardCastbar = {
                        order = 32,
                        type = "toggle",
                        name = "Hide Blizzard Castbar",
                        desc = "Hide default Blizzard castbar when Nihui castbar is enabled",
                        get = function()
                            return ns.nameplateSettings().castbar.hideBlizzardCastbar
                        end,
                        set = function(_, val)
                            ns.nameplateSettings().castbar.hideBlizzardCastbar = val
                            if ns.modules.castbar then ns.modules.castbar:ApplySettings() end
                        end,
                        disabled = function()
                            return not ns.nameplateSettings().castbar.enabled
                        end,
                    },
                },
            },

        },
    }
end

-- Initialize the GUI
function GUI:Initialize()
    -- Register the config table
    AceConfig:RegisterOptionsTable("NihuiNameplates", CreateConfigTable)

    -- Create the dialog
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("NihuiNameplates", "|cff00ff00Nihui|r Nameplates")

    print("|cff00ff00Nihui Nameplates:|r GUI initialized. Use '/nnp config' or check Interface > AddOns")
end

-- Toggle the configuration window
function GUI:Toggle()
    if self.optionsFrame then
        -- Use new Settings API for modern WoW versions
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(self.optionsFrame.name)
        elseif SettingsPanel then
            -- Fallback for SettingsPanel
            if SettingsPanel:IsShown() then
                SettingsPanel:Hide()
            else
                SettingsPanel:Open()
            end
        elseif InterfaceOptionsFrame_OpenToCategory then
            -- Legacy support for older versions
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        else
            -- Final fallback - use AceConfigDialog directly
            AceConfigDialog:Open("NihuiNameplates")
        end
    else
        print("|cff00ff00Nihui Nameplates:|r Configuration not available")
    end
end

-- Initialize when addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        C_Timer.After(0.5, function()
            GUI:Initialize()
        end)
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)