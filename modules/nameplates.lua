-- Nihui Nameplates - Main coordination module
local addonName, ns = ...

local Nameplates = {}
ns.modules.nameplates = Nameplates

-- Module functions
function Nameplates:OnEnable()
    local settings = ns.nameplateSettings()
    if not settings.enabled then return end
end

function Nameplates:OnDisable()
    print("|cff00ff00Nihui Nameplates:|r Main module disabled")
end

function Nameplates:ApplySettings()
    -- Coordinate updates across all nameplate modules
    if ns.modules.borders then
        ns.modules.borders:ApplySettings()
    end
    if ns.modules.animations then
        ns.modules.animations:ApplySettings()
    end
    if ns.modules.castbar then
        ns.modules.castbar:ApplySettings()
    end
end

-- Register the module
ns.addon:RegisterModule("nameplates", Nameplates)