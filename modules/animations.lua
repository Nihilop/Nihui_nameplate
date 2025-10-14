-- Nihui Nameplates - Health Loss Animations (adapted from rnxmUI)
local addonName, ns = ...

-- Add LibSharedMedia support
local LSM = LibStub("LibSharedMedia-3.0", true)

local Animations = {}
ns.modules.animations = Animations

-- Animation tracking
local activeAnimations = {}
local animationCount = 0
local trackedNameplates = {}

-- Single shared event manager to prevent memory leaks
local healthEventManager = CreateFrame("Frame")
local healthEventRegistered = false

-- Get animation settings
local function GetAnimationSettings()
    local settings = ns.nameplateSettings and ns.nameplateSettings()
    if settings and settings.healthLoss then
        return {
            maxDistance = settings.healthLoss.maxDistance or 60,
            maxConcurrentAnimations = settings.healthLoss.maxConcurrent or 10,
            priorityUnits = {"target", "focus"},
            enableInCombatOnly = settings.healthLoss.combatOnly or false,
            enableForPlayer = settings.healthLoss.enableForPlayer ~= false,
            enableForFriendlyUnits = settings.healthLoss.enableForFriendlyUnits ~= false,
            enableForEnemyUnits = settings.healthLoss.enableForEnemyUnits ~= false,
            enableForNeutralUnits = settings.healthLoss.enableForNeutralUnits ~= false,
        }
    else
        return {
            maxDistance = 60,
            maxConcurrentAnimations = 10,
            priorityUnits = {"target", "focus"},
            enableInCombatOnly = false,
            enableForPlayer = true,
            enableForFriendlyUnits = true,
            enableForEnemyUnits = true,
            enableForNeutralUnits = true,
        }
    end
end

-- Check if animation should be enabled for unit
local function ShouldAnimateForUnit(unit)
    local settings = GetAnimationSettings()

    -- Check if it's the player
    if UnitIsUnit(unit, "player") then
        return settings.enableForPlayer
    end

    -- Check unit reaction
    local unitReaction = UnitReaction(unit, "player")
    if not unitReaction then
        return settings.enableForNeutralUnits
    end

    if unitReaction >= 5 then -- Friendly
        return settings.enableForFriendlyUnits
    elseif unitReaction <= 3 then -- Hostile
        return settings.enableForEnemyUnits
    else -- Neutral
        return settings.enableForNeutralUnits
    end
end

-- Base AnimatedHealthLossMixin
local AnimatedHealthLossMixin = {}

function AnimatedHealthLossMixin:OnLoad()
    self.animationStartTime = nil
    self.animationDuration = 2.0
    self.currentAnimationValue = 0
end

function AnimatedHealthLossMixin:ShouldAnimate()
    local settings = GetAnimationSettings()

    -- Check if enabled for this unit type
    if not ShouldAnimateForUnit(self.unit) then
        return false
    end

    -- Priority units always animate (if they pass unit type check above)
    for _, priorityUnit in ipairs(settings.priorityUnits) do
        if UnitIsUnit(self.unit, priorityUnit) then
            return true
        end
    end

    -- Check combat requirement
    if settings.enableInCombatOnly and not InCombatLockdown() then
        return false
    end

    -- Check animation limit
    if animationCount >= settings.maxConcurrentAnimations then
        return false
    end

    -- Check distance
    local distance = UnitDistanceSquared(self.unit)
    if distance and distance > (settings.maxDistance * settings.maxDistance) then
        return false
    end

    return true
end

function AnimatedHealthLossMixin:UpdateHealth(currentHealth, previousHealth)
    if not currentHealth or not previousHealth then return end
    if currentHealth >= previousHealth then return end -- Only animate health loss

    local maxHealth = UnitHealthMax(self.unit)
    if not maxHealth or maxHealth <= 0 then return end

    local currentPercentage = currentHealth / maxHealth
    local previousPercentage = previousHealth / maxHealth

    -- Start animation from previous health to current health
    self:BeginAnimation(previousPercentage, currentPercentage)
end

function AnimatedHealthLossMixin:BeginAnimation(fromValue, toValue)
    if not self:ShouldAnimate() then
        return
    end

    if not fromValue or not toValue or fromValue <= toValue then
        return
    end

    local wasTracked = activeAnimations[self]

    self.animationStartTime = GetTime()
    self.animationFromValue = fromValue
    self.animationToValue = toValue

    -- Set up the animated loss bar
    self:SetMinMaxValues(0, 1)
    self:SetValue(fromValue)
    self:Show()

    -- Start update loop
    self:SetScript("OnUpdate", self.OnUpdate)

    -- Only increment counter if animation actually started and wasn't already tracked
    if not wasTracked and self.animationStartTime then
        activeAnimations[self] = true
        animationCount = animationCount + 1
    end
end

function AnimatedHealthLossMixin:OnUpdate(elapsed)
    if not self.animationStartTime then
        self:CancelAnimation()
        return
    end

    local currentTime = GetTime()
    local elapsed = currentTime - self.animationStartTime
    local progress = elapsed / self.animationDuration

    if progress >= 1 then
        self:CancelAnimation()
        return
    end

    -- Ease-out animation: animate from fromValue to toValue
    local easedProgress = 1 - ((1 - progress) ^ 3)
    local animatedValue = self.animationFromValue - (self.animationFromValue - self.animationToValue) * easedProgress

    self:SetValue(animatedValue)
    self:SetAlpha(1 - progress * 0.5) -- Fade out slightly over time
end

function AnimatedHealthLossMixin:CancelAnimation()
    -- Untrack this animation
    if activeAnimations[self] then
        activeAnimations[self] = nil
        animationCount = math.max(0, animationCount - 1)
    end

    self:SetScript("OnUpdate", nil)
    self:Hide()
    self.animationStartTime = nil
    self.currentAnimationValue = 0
    self.animationFromValue = nil
    self.animationToValue = nil
end

-- Create animated loss bar for nameplate
local function CreateNameplateAnimatedLossBar(nameplate, healthBar)
    local animatedLossBar = CreateFrame("StatusBar", nil, nameplate)

    -- Apply mixin
    Mixin(animatedLossBar, AnimatedHealthLossMixin)

    -- Set texture and layering
    local settings = ns.nameplateSettings()
    local texture = "Interface\\Buttons\\WHITE8x8" -- fallback

    if settings and settings.healthLoss and settings.healthLoss.texture then
        if LSM then
            local lsmTexture = LSM:Fetch("statusbar", settings.healthLoss.texture)
            if lsmTexture then
                texture = lsmTexture
            else
                texture = settings.healthLoss.texture
            end
        else
            texture = settings.healthLoss.texture
        end
    end

    animatedLossBar:SetStatusBarTexture(texture)
    animatedLossBar:SetFrameLevel(healthBar:GetFrameLevel() - 1)
    animatedLossBar:SetAllPoints(healthBar)

    -- Initialize
    animatedLossBar:OnLoad()

    -- Set blend mode from settings
    local blendMode = "ADD" -- fallback
    if settings and settings.healthLoss and settings.healthLoss.blendMode then
        blendMode = settings.healthLoss.blendMode
    end
    animatedLossBar:GetStatusBarTexture():SetBlendMode(blendMode)

    -- Set color from settings
    if settings and settings.healthLoss and settings.healthLoss.color then
        local color = settings.healthLoss.color
        animatedLossBar:SetStatusBarColor(color[1], color[2], color[3], 1)
    else
        -- Fallback red
        animatedLossBar:SetStatusBarColor(1, 0, 0, 1)
    end

    -- Set alpha to match nameplate
    local nameplateAlpha = nameplate:GetAlpha()
    animatedLossBar:SetAlpha(nameplateAlpha)

    return animatedLossBar
end

-- Clean up nameplate
local function CleanupNameplate(nameplate)
    if trackedNameplates[nameplate] then
        local data = trackedNameplates[nameplate]

        -- Clean up animated loss bar
        if data.animatedLossBar then
            data.animatedLossBar:CancelAnimation()
            if activeAnimations[data.animatedLossBar] then
                activeAnimations[data.animatedLossBar] = nil
                animationCount = math.max(0, animationCount - 1)
            end
            data.animatedLossBar.unit = nil
        end

        trackedNameplates[nameplate] = nil
    end
end

-- Hook nameplate events
local function OnNamePlateAdded(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate or not nameplate.UnitFrame then
        return
    end

    -- Check if we should animate this unit type before setting up
    if not ShouldAnimateForUnit(unit) then
        return
    end

    local unitFrame = nameplate.UnitFrame
    local healthBar = unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar

    if not healthBar then
        return
    end

    -- Check if we already have data for this nameplate (frame recycling)
    local existingData = trackedNameplates[nameplate]

    if existingData and existingData.animatedLossBar then
        -- REUSE EXISTING: Update the existing animated loss bar for the new unit
        local animatedLossBar = existingData.animatedLossBar

        -- Re-setup for the new unit
        animatedLossBar.unit = unit

        -- Re-apply the frame level (this gets lost when frames are recycled)
        animatedLossBar:SetFrameLevel(healthBar:GetFrameLevel() - 1)

        -- Update tracking data
        existingData.unit = unit
        existingData.healthBar = healthBar
        existingData.previousHealth = UnitHealth(unit) or 0

        -- Cancel any existing animation since this is a "new" unit
        animatedLossBar:CancelAnimation()

    else
        -- CREATE NEW: First time seeing this nameplate frame
        local animatedLossBar = CreateNameplateAnimatedLossBar(nameplate, healthBar)
        animatedLossBar.unit = unit

        -- Track this nameplate
        trackedNameplates[nameplate] = {
            unit = unit,
            healthBar = healthBar,
            animatedLossBar = animatedLossBar,
            previousHealth = UnitHealth(unit) or 0
        }
    end

    -- Register shared event handler only once
    if not healthEventRegistered then
        healthEventManager:RegisterEvent("UNIT_HEALTH")
        healthEventManager:SetScript("OnEvent", function(self, event, eventUnit)
            -- Find nameplate for this unit
            for np, data in pairs(trackedNameplates) do
                if data.unit == eventUnit then
                    local currentHealth = UnitHealth(eventUnit)
                    if currentHealth ~= data.previousHealth then
                        data.animatedLossBar:UpdateHealth(currentHealth, data.previousHealth)
                        data.previousHealth = currentHealth
                    end
                    break
                end
            end
        end)
        healthEventRegistered = true
    end
end

local function OnNamePlateRemoved(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and trackedNameplates[nameplate] then
        local data = trackedNameplates[nameplate]

        -- Don't destroy the animated loss bar - just clean up the unit reference
        if data.animatedLossBar then
            data.animatedLossBar:CancelAnimation()
            data.animatedLossBar.unit = nil
        end

        -- Clear the unit but keep the nameplate entry for reuse
        data.unit = nil
        data.previousHealth = 0
    end
end

-- Module functions
function Animations:OnEnable()
    local settings = ns.nameplateSettings()
    if not settings.enabled or not settings.healthLoss.enabled then return end

    -- Create main event frame
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")

        -- Register nameplate events
        self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "NAME_PLATE_UNIT_ADDED" then
                local unit = ...
                OnNamePlateAdded(unit)
            elseif event == "NAME_PLATE_UNIT_REMOVED" then
                local unit = ...
                OnNamePlateRemoved(unit)
            elseif event == "PLAYER_ENTERING_WORLD" then
                -- Clean up any leftover data
                for nameplate in pairs(trackedNameplates) do
                    CleanupNameplate(nameplate)
                end
                trackedNameplates = {}
                activeAnimations = {}
                animationCount = 0
            end
        end)
    end

end

function Animations:OnDisable()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
    end

    -- Cancel all active animations
    for nameplate in pairs(trackedNameplates) do
        CleanupNameplate(nameplate)
    end
    trackedNameplates = {}
    activeAnimations = {}
    animationCount = 0

    -- Clean up shared event manager
    if healthEventRegistered then
        healthEventManager:UnregisterAllEvents()
        healthEventManager:SetScript("OnEvent", nil)
        healthEventRegistered = false
    end
end

function Animations:ApplySettings()
    -- For now, just restart the system
    self:OnDisable()
    self:OnEnable()
end

-- Register the module
ns.addon:RegisterModule("animations", Animations)