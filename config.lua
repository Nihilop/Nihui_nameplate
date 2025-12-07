-- Nihui Nameplates - Configuration utilities
local addonName, ns = ...

-- Configuration helper functions
ns.Config = {}

-- Make config accessible globally
ns.config = nil

-- Initialize config from saved variables
function ns.Config:Initialize()
    local settings = ns.nameplateSettings()
    ns.config = settings
end

function ns.Config:GetNameplateSettings()
    return ns.nameplateSettings()
end

function ns.Config:UpdateNameplates()
    if ns.modules.nameplates and ns.modules.nameplates.ApplySettings then
        ns.modules.nameplates:ApplySettings()
    end
    if ns.modules.borders and ns.modules.borders.ApplySettings then
        ns.modules.borders:ApplySettings()
    end
    if ns.modules.animations and ns.modules.animations.ApplySettings then
        ns.modules.animations:ApplySettings()
    end
end

function ns.Config:ResetToDefaults()
    local defaults = {
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
            offset = 10.5,
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
            removeDefault = true,
            enablePulse = false
        },

        -- StatusBar Texture
        statusbar = {
            enabled = true,
            texture = "Interface\\AddOns\\Nihui_np\\textures\\blizzrnxm0.tga"
        },

        -- Castbar Settings
        castbar = {
            enabled = false,
            yOffset = 6,
            hideBlizzardCastbar = true,
            enableForPlayer = false,
            enableForFriendlyUnits = false,
            enableForEnemyUnits = true,
            enableForNeutralUnits = true,
            showIcon = true,
            showText = false,
            showTimer = true,
        },

        -- Scaling Settings
        scaling = {
            enabled = true,  -- OPTIMIZED: Enabled by default for better visibility
            normalWidth = 1.0,  -- Keep width normal
            normalHeight = 1.15,  -- OPTIMIZED: +15% height for all nameplates
            targetWidth = 1.0,  -- Keep target width normal (or 1.1 for slight increase)
            targetHeight = 1.5  -- OPTIMIZED: +50% height for target (very visible!)
        }
    }

    local settings = ns.nameplateSettings()
    for key, value in pairs(defaults) do
        if type(value) == "table" and type(settings[key]) == "table" then
            for subkey, subvalue in pairs(value) do
                if type(subvalue) == "table" and type(settings[key][subkey]) == "table" then
                    for subsubkey, subsubvalue in pairs(subvalue) do
                        settings[key][subkey][subsubkey] = subsubvalue
                    end
                else
                    settings[key][subkey] = subvalue
                end
            end
        else
            settings[key] = value
        end
    end

    self:UpdateNameplates()

    print("|cff00ff00Nihui Nameplates:|r Settings reset to defaults!")
end