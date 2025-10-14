-- Nihui Nameplates - Castbar Module (uses Nihui_cb API if available)
local addonName, ns = ...

local Castbar = {}
ns.modules.castbar = Castbar

-- Nameplate cast bar manager
local nameplateCastBars = {} -- now keyed by unit (e.g. "nameplate1") => castBar
local nameplateUnits = {}    -- [unit] = nameplate frame
local NAMEPLATE_PATTERN = "^nameplate%d+$"

-- Get castbar configuration
local function GetCastbarConfig()
    local settings = ns.nameplateSettings()
    return {
        enabled = settings.castbar and settings.castbar.enabled ~= false or false,
        width = settings.castbar and settings.castbar.width or 110,
        height = settings.castbar and settings.castbar.height or 12,
        xOffset = settings.castbar and settings.castbar.xOffset or 0,
        yOffset = settings.castbar and settings.castbar.yOffset or 6,
        showIcon = settings.castbar and settings.castbar.showIcon ~= false or true,
        showText = settings.castbar and settings.castbar.showText ~= false or false,
        showTimer = settings.castbar and settings.castbar.showTimer ~= false or true,
        scale = settings.castbar and settings.castbar.scale or 1.0,
        hideBlizzardCastbar = settings.castbar and settings.castbar.hideBlizzardCastbar ~= false or true,

        -- Unit filtering
        enableForPlayer = settings.castbar and settings.castbar.enableForPlayer or false,
        enableForFriendlyUnits = settings.castbar and settings.castbar.enableForFriendlyUnits or false,
        enableForEnemyUnits = settings.castbar and settings.castbar.enableForEnemyUnits ~= false or true,
        enableForNeutralUnits = settings.castbar and settings.castbar.enableForNeutralUnits ~= false or true,
    }
end

-- Check if Nihui_cb addon is available
local function IsNihuiCbAvailable()

    local nihuiCbAPI = _G["NihuiCbAPI"]

    if nihuiCbAPI and nihuiCbAPI.modules and nihuiCbAPI.modules.castbars then
        return nihuiCbAPI.modules.castbars, nihuiCbAPI
    end

    return nil, nil
end

-- Check if unit should show castbar
local function ShouldShowCastBarForUnit(unit)
    if not unit or not UnitExists(unit) then return false end

    local config = GetCastbarConfig()

    -- Check if unit is the player
    if UnitIsUnit(unit, "player") then
        return config.enableForPlayer
    end

    -- Get unit reaction to determine unit type
    local reaction = UnitReaction("player", unit)

    if not reaction then
        return config.enableForNeutralUnits
    end

    if reaction <= 3 then
        -- Hostile/Enemy units
        return config.enableForEnemyUnits
    elseif reaction >= 5 then
        -- Friendly units
        return config.enableForFriendlyUnits
    else
        -- Neutral units (reaction == 4)
        return config.enableForNeutralUnits
    end
end

-- Clean up a Nihui_cb castbar completely and DESTROY the frame
local function CleanupNihuiCbCastBar(castBar)
    if not castBar then return end

    -- Cancel all animations first to stop any ongoing effects
    if castBar.CancelAllAnimations then
        pcall(castBar.CancelAllAnimations, castBar)
    end

    -- Stop any active casting
    if castBar.StopCast then
        pcall(castBar.StopCast, castBar)
    end

    -- Hide and cleanup interrupt holder
    if castBar.interruptHolder then
        -- Protected call to hide
        pcall(function()
            castBar.interruptHolder:Hide()
            if castBar.interruptHolder.spark then
                castBar.interruptHolder.spark:Hide()
            end
            if castBar.interruptHolder.interruptGlow then
                castBar.interruptHolder.interruptGlow:Hide()
            end
        end)
    end

    -- Clear any timers
    if castBar.interruptHolder and castBar.interruptHolder.hideTimer then
        if castBar.interruptHolder.hideTimer.Cancel then
            pcall(castBar.interruptHolder.hideTimer.Cancel, castBar.interruptHolder.hideTimer)
        end
        castBar.interruptHolder.hideTimer = nil
    end

    -- Hide main castbar (protected)
    pcall(function() castBar:Hide() end)

    -- IMPORTANT: Clear parent to prevent memory leak (protected)
    pcall(function()
        castBar:SetParent(nil)
        castBar:ClearAllPoints()
    end)

    -- Clear all references to help garbage collection
    castBar.unit = nil
    castBar.interruptHolder = nil
end

-- Create castbar using Nihui_cb API
local function CreateNameplateCastBarWithNihuiCb(nameplate, unit, nihuiCbAPI)
    local config = GetCastbarConfig()

    -- Prepare options for Nihui_cb
    local options = {
        width = config.width,
        height = config.height,
        showIcon = config.showIcon,
        showText = config.showText,
        showTimer = config.showTimer,
        -- Position relative to nameplate
        point = "TOP",
        relativeTo = nameplate,
        relativePoint = "BOTTOM",
        xOffset = config.xOffset,
        yOffset = -config.yOffset,
        movable = false
    }

    -- Create the castbar using Nihui_cb API with the REAL unit
    -- IMPORTANT: Pass the real unit (e.g., "nameplate1") so Nihui_cb can receive UNIT_SPELLCAST_* events
    local castBar = nihuiCbAPI.CreateCastBar(nameplate, unit, options)
    if castBar then
        castBar:SetScale(config.scale)
        -- Set position manually since it's a nameplate castbar
        castBar:ClearAllPoints()
        castBar:SetPoint("TOP", nameplate, "BOTTOM", config.xOffset, -config.yOffset)
        castBar.isNihuiCb = true  -- Mark that this was created with Nihui_cb API
    end

    return castBar
end

-- Simple fallback castbar (if Nihui_cb not available)
local function CreateSimpleFallbackCastBar(nameplate, unit)
    local config = GetCastbarConfig()

    local castBar = CreateFrame("StatusBar", nil, nameplate)
    castBar:SetSize(config.width, config.height)
    castBar:SetPoint("TOP", nameplate, "BOTTOM", config.xOffset, -config.yOffset)
    castBar:SetScale(config.scale)
    castBar:Hide()

    -- Set statusbar texture
    castBar:SetStatusBarTexture("Interface\\AddOns\\Nihui_np\\textures\\blizzrnxm0.tga")
    castBar:SetStatusBarColor(1, 0.7, 0, 1)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)

    -- Simple background
    local bg = castBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
    castBar.bg = bg

    -- Simple border
    local border = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    border:SetAllPoints(castBar)
    border:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\AddOns\\Nihui_np\\textures\\MirroredFrameSingle2.tga",
        edgeSize = 6,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Timer
    if config.showTimer then
        local timer = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        timer:SetPoint("CENTER", castBar, "CENTER", 0, 0)
        timer:SetTextColor(1, 1, 1, 1)
        timer:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        castBar.timer = timer
    end

    -- Spell text (if enabled)
    if config.showText then
        local text = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", castBar, "LEFT", 4, 0)
        text:SetJustifyH("LEFT")
        castBar.spellText = text
    end

    -- Store references for fallback functionality
    castBar.unit = unit
    castBar.isCasting = false
    castBar.isChanneling = false
    castBar.castStartTime = 0
    castBar.castEndTime = 0
    castBar.isFallback = true  -- Mark that this is a fallback castbar

    return castBar
end

-- Create castbar (try Nihui_cb first, fallback to simple)
local function CreateNameplateCastBar(nameplate, unit)
    local config = GetCastbarConfig()
    if not config.enabled then return nil end
    if not ShouldShowCastBarForUnit(unit) then return nil end

    -- Try to use Nihui_cb API first
    local nihuiCbAPI, nihuiCbNS = IsNihuiCbAvailable()
    if nihuiCbAPI then
        return CreateNameplateCastBarWithNihuiCb(nameplate, unit, nihuiCbAPI)
    else
        -- Fallback to simple castbar
        return CreateSimpleFallbackCastBar(nameplate, unit)
    end
end

-- Simple casting event handling (for fallback only)
local function StartFallbackCast(castBar, spellName, startTimeMS, endTimeMS, isChannel)
    if not castBar then return end

    -- Validate input times to prevent aberrant durations
    if not startTimeMS or not endTimeMS then
        return
    end

    -- convert ms -> seconds
    local startS = startTimeMS / 1000
    local endS = endTimeMS / 1000
    local currentTime = GetTime()

    -- Sanity check: duration should be reasonable (between 0.1s and 10s for most casts)
    local duration = endS - startS
    if duration <= 0 or duration > 600 then
        -- Invalid duration (negative or > 10 minutes), abort
        return
    end

    -- For channels, adjust if start time is in the past
    if isChannel and startS < currentTime then
        -- For channels, start time should be current or future
        startS = currentTime
    end

    castBar.isCasting = not isChannel
    castBar.isChanneling = isChannel or false
    castBar.castStartTime = startS
    castBar.castEndTime = endS

    castBar:SetMinMaxValues(0, duration)
    castBar:SetValue(0)
    if castBar.spellText then castBar.spellText:SetText(spellName or "") end
    if castBar.timer then
        local remaining = endS - currentTime
        if remaining > 0 then
            castBar.timer:SetText(string.format("%.1f", remaining))
        else
            castBar.timer:SetText("0.0")
        end
    end
    castBar:Show()

    castBar:SetScript("OnUpdate", function(self, elapsed)
        local currentTime = GetTime()
        local remaining = self.castEndTime - currentTime

        if remaining <= 0 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self.isCasting = false
            self.isChanneling = false
            return
        end

        local duration = (self.castEndTime - self.castStartTime)
        local progress = duration - remaining
        self:SetValue(progress)

        if self.timer then
            self.timer:SetText(string.format("%.1f", remaining))
        end
    end)
end

local function StopFallbackCast(castBar)
    if not castBar then return end
    castBar:SetScript("OnUpdate", nil)
    castBar:Hide()
    castBar.isCasting = false
    castBar.isChanneling = false
end

-- Clean up a fallback castbar completely and DESTROY the frame
local function CleanupFallbackCastBar(castBar)
    if not castBar then return end

    -- Stop any active animation (protected)
    pcall(function()
        castBar:SetScript("OnUpdate", nil)
    end)

    castBar.isCasting = false
    castBar.isChanneling = false

    -- Hide the frame (protected)
    pcall(function()
        castBar:Hide()
    end)

    -- IMPORTANT: Clear parent and points to prevent memory leak (protected)
    pcall(function()
        castBar:SetParent(nil)
        castBar:ClearAllPoints()
    end)

    -- Clear all references to help garbage collection
    castBar.unit = nil
    castBar.timer = nil
    castBar.spellText = nil
end

-- Event handling for casting
local function OnCastingEvent(self, event, unit, ...)
    local config = GetCastbarConfig()
    if not config.enabled then return end
    if not unit or not unit:match(NAMEPLATE_PATTERN) then return end
    if not ShouldShowCastBarForUnit(unit) then return end

    -- Always get fresh nameplate for this unit (like rnxmUI)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    -- Get or create castbar keyed by unit
    local castBar = nameplateCastBars[unit]
    local needsNewCastBar = false

    -- Check if Nihui_cb API is available
    local nihuiCbAvailable = IsNihuiCbAvailable() ~= nil

    if not castBar then
        needsNewCastBar = true
    else
        -- Protected checks to handle potentially destroyed frames
        local unitMismatch = castBar.unit ~= unit
        local parentMismatch = false
        local parentCheckSuccess, parent = pcall(function() return castBar:GetParent() end)
        if parentCheckSuccess then
            parentMismatch = parent ~= nameplate
        else
            -- GetParent failed, frame is likely destroyed
            needsNewCastBar = true
        end

        if not needsNewCastBar then
            if unitMismatch then
                -- Unit mismatch
                needsNewCastBar = true
            elseif parentMismatch then
                -- Nameplate changed (mob moved to different nameplate)
                needsNewCastBar = true
            elseif castBar.isNihuiCb and not nihuiCbAvailable then
                -- Nihui_cb was disabled, need to recreate as fallback
                needsNewCastBar = true
            elseif castBar.isFallback and nihuiCbAvailable then
                -- Nihui_cb was enabled, recreate to use API
                needsNewCastBar = true
            end
        end
    end

    if needsNewCastBar then
        -- Clean up old castbar if it exists AND remove from cache immediately
        if castBar then
            if castBar.StopCast or castBar.isNihuiCb then
                -- Nihui_cb castbar - use specialized cleanup
                CleanupNihuiCbCastBar(castBar)
            else
                -- Fallback castbar - use proper cleanup
                CleanupFallbackCastBar(castBar)
            end
            -- IMPORTANT: Remove from cache before creating new one
            nameplateCastBars[unit] = nil
            castBar = nil
        end

        -- Create new castbar for this unit and nameplate
        castBar = CreateNameplateCastBar(nameplate, unit)
        if castBar then
            nameplateCastBars[unit] = castBar
            nameplateUnits[unit] = nameplate
        else
            return
        end
    end

    -- If using Nihui_cb API, do nothing (it manages events)
    local nihuiCbAPI, _ = IsNihuiCbAvailable()
    if nihuiCbAPI then
        return
    end

    -- Fallback event handling
    if event == "UNIT_SPELLCAST_START" then
        local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
        if name then
            StartFallbackCast(castBar, name, startTimeMS, endTimeMS, false)
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        StopFallbackCast(castBar)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local name, _, _, startTimeMS, endTimeMS = UnitChannelInfo(unit)
        if name then
            StartFallbackCast(castBar, name, startTimeMS, endTimeMS, true)
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        StopFallbackCast(castBar)
    end
end

-- Nameplate events
local function OnNameplateEvent(self, event, unit)
    local config = GetCastbarConfig()
    if not config.enabled then return end

    if event == "NAME_PLATE_UNIT_ADDED" then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate then
            nameplateUnits[unit] = nameplate

            -- Hide Blizzard castbar if option is enabled
            if config.hideBlizzardCastbar then
                Castbar:DisableBlizzardCastbar(nameplate)
            end

            -- Ensure our castbar exists for this unit
            if ShouldShowCastBarForUnit(unit) then
                local existingCastBar = nameplateCastBars[unit]
                local nihuiCbAvailable = IsNihuiCbAvailable() ~= nil
                local needsRecreate = false

                if not existingCastBar then
                    needsRecreate = true
                else
                    -- Protected checks to handle potentially destroyed frames
                    if existingCastBar.unit ~= unit then
                        needsRecreate = true
                    else
                        -- Check if parent is still valid
                        local parentCheckSuccess, parent = pcall(function() return existingCastBar:GetParent() end)
                        if not parentCheckSuccess or parent ~= nameplate then
                            -- Parent is invalid or changed, need to recreate
                            needsRecreate = true
                        elseif existingCastBar.isNihuiCb and not nihuiCbAvailable then
                            -- Nihui_cb was disabled, need to recreate as fallback
                            needsRecreate = true
                        elseif existingCastBar.isFallback and nihuiCbAvailable then
                            -- Nihui_cb was enabled, recreate to use API
                            needsRecreate = true
                        end
                    end
                end

                if needsRecreate then
                    -- Clean up existing castbar if it exists AND remove from cache immediately
                    if existingCastBar then
                        if existingCastBar.StopCast or existingCastBar.isNihuiCb then
                            CleanupNihuiCbCastBar(existingCastBar)
                        else
                            CleanupFallbackCastBar(existingCastBar)
                        end
                        -- IMPORTANT: Remove from cache before creating new one
                        nameplateCastBars[unit] = nil
                        existingCastBar = nil
                    end

                    -- Create new castbar for this unit
                    local cb = CreateNameplateCastBar(nameplate, unit)
                    if cb then
                        nameplateCastBars[unit] = cb

                        -- Only manually initialize fallback castbars if unit is already casting
                        -- Nihui_cb castbars handle this automatically in SetupCastBarEvents
                        if cb.isFallback then
                            local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
                            if name then
                                StartFallbackCast(cb, name, startTimeMS, endTimeMS, false)
                            else
                                local cname, _, _, cstart, cend = UnitChannelInfo(unit)
                                if cname then
                                    StartFallbackCast(cb, cname, cstart, cend, true)
                                end
                            end
                        end
                    end
                end
            end
        end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        -- Clean up by unit key
        local castBar = nameplateCastBars[unit]
        if castBar then
            -- Proper cleanup depending on castbar type
            if castBar.StopCast or castBar.isNihuiCb then
                -- Nihui_cb castbar - use specialized cleanup
                CleanupNihuiCbCastBar(castBar)
            else
                -- Fallback castbar - use proper cleanup
                CleanupFallbackCastBar(castBar)
            end
            -- IMPORTANT: Clear from cache immediately
            nameplateCastBars[unit] = nil
        end
        nameplateUnits[unit] = nil
    end
end

-- Module functions
function Castbar:OnEnable()
    local settings = ns.nameplateSettings()
    if not settings.enabled then return end

    local config = GetCastbarConfig()
    if not config.enabled then return end

    -- Hide Blizzard castbars if option is enabled
    if config.hideBlizzardCastbar then
        self:HideBlizzardCastbars()
    end

    -- Check if Nihui_cb is available
    local nihuiCbAPI, _ = IsNihuiCbAvailable()
    local usingNihuiCb = nihuiCbAPI ~= nil

    -- Create event frame
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")

        -- Register nameplate events (always needed)
        self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.eventFrame:RegisterEvent("NAME_PLATE_CREATED")

        -- Only register casting events if using fallback (Nihui_cb handles its own events)
        if not usingNihuiCb then
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            self.eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        end

        -- Event handler
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event:match("UNIT_SPELLCAST") then
                -- Only handle casting events if using fallback
                if not usingNihuiCb then
                    OnCastingEvent(frame, event, ...)
                end
            else
                OnNameplateEvent(frame, event, ...)
            end
        end)
    end

    -- Check and inform about Nihui_cb availability
    if usingNihuiCb then
        print("|cff00ff00Nihui Nameplates:|r Castbar enabled (using Nihui_cb API)")
    else
        print("|cff00ff00Nihui Nameplates:|r Castbar enabled (using fallback castbar)")
        print("|cff00ff00Nihui Nameplates:|r Install Nihui_cb for enhanced castbar features")
    end
end

function Castbar:OnDisable()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
    end

    -- Clean up existing castbars properly
    for unit, castBar in pairs(nameplateCastBars) do
        if castBar then
            -- Proper cleanup depending on castbar type
            if castBar.StopCast then
                -- Nihui_cb castbar - use specialized cleanup
                CleanupNihuiCbCastBar(castBar)
            else
                -- Fallback castbar - use proper cleanup
                CleanupFallbackCastBar(castBar)
            end
        end
    end
    nameplateCastBars = {}
    nameplateUnits = {}

    -- Restore Blizzard castbars
    self:ShowBlizzardCastbars()

    print("|cff00ff00Nihui Nameplates:|r Castbar disabled")
end

function Castbar:ApplySettings()
    -- Get current config
    local config = GetCastbarConfig()

    -- Handle Blizzard castbar hiding based on settings
    if config.enabled and config.hideBlizzardCastbar then
        self:HideBlizzardCastbars()
    else
        self:ShowBlizzardCastbars()
    end

    -- Restart the system to apply new settings
    self:OnDisable()
    self:OnEnable()
end

-- Test function (updated for unit-keyed castbars)
function Castbar:TestCastbars()
    local config = GetCastbarConfig()
    if not config.enabled then
        print("|cff00ff00Nihui Nameplates:|r Castbars are disabled. Enable them first with /nnp config")
        return
    end

    local nihuiCbAPI, _ = IsNihuiCbAvailable()
    if nihuiCbAPI then
        print("|cff00ff00Nihui Nameplates:|r Testing castbars with Nihui_cb API")
    else
        print("|cff00ff00Nihui Nameplates:|r Testing fallback castbars")
    end

    local testCount = 0

    -- Test on visible enemy nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate and nameplate:IsShown() then
                local castBar = nameplateCastBars[unit]
                if not castBar then
                    castBar = CreateNameplateCastBar(nameplate, unit)
                    if castBar then
                        nameplateCastBars[unit] = castBar
                        nameplateUnits[unit] = nameplate
                    end
                end

                if castBar then
                    testCount = testCount + 1

                    -- Only test fallback castbars (Nihui_cb handles its own testing)
                    if not nihuiCbAPI and castBar.timer then
                        local startTime = GetTime() * 1000
                        local endTime = startTime + 3000
                        StartFallbackCast(castBar, "Test Spell", startTime, endTime)

                        -- Auto-complete after 3 seconds
                        C_Timer.After(2.8, function()
                            if castBar and castBar.isCasting then
                                castBar:SetScript("OnUpdate", nil)
                                castBar:Hide()
                                castBar.isCasting = false
                            end
                        end)
                    end
                end
            end
        end
    end

    if testCount == 0 then
        print("|cff00ff00Nihui Nameplates:|r No suitable enemy nameplates found to test castbars")
    else
        print("|cff00ff00Nihui Nameplates:|r Testing castbars on " .. testCount .. " nameplate(s)")
    end
end

-- Hide Blizzard castbars (improved approach)
function Castbar:HideBlizzardCastbars()
    -- Create frame if it doesn't exist
    if not self.blizzardHideFrame then
        self.blizzardHideFrame = CreateFrame("Frame")
        self.blizzardHideFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.blizzardHideFrame:RegisterEvent("NAME_PLATE_CREATED")

        self.blizzardHideFrame:SetScript("OnEvent", function(_, event, arg1)
            if event == "NAME_PLATE_UNIT_ADDED" then
                local plate = C_NamePlate.GetNamePlateForUnit(arg1)
                self:DisableBlizzardCastbar(plate)
            elseif event == "NAME_PLATE_CREATED" then
                local plate = arg1
                self:DisableBlizzardCastbar(plate)
            end
        end)
    end

    -- Hide existing castbars
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            self:DisableBlizzardCastbar(nameplate)
        end
    end

    self.blizzardCastbarsHidden = true
end

-- Show Blizzard castbars
function Castbar:ShowBlizzardCastbars()
    -- Remove event frame
    if self.blizzardHideFrame then
        self.blizzardHideFrame:UnregisterAllEvents()
        self.blizzardHideFrame = nil
    end

    -- Restore existing castbars (this requires a /reload to fully restore)
    print("|cff00ff00Nihui Nameplates:|r Blizzard castbars will be restored after /reload")

    self.blizzardCastbarsHidden = false
end

-- Helper function to disable a specific castbar (ChatGPT approach)
function Castbar:DisableBlizzardCastbar(plate)
    if not plate then return end

    -- Try exact rnxmUI approach first
    if plate.UnitFrame and plate.UnitFrame.castBar then
        plate.UnitFrame.castBar:Hide()
        plate.UnitFrame.castBar:SetScript("OnShow", plate.UnitFrame.castBar.Hide)
        return
    end

    -- Fallback to other possible locations
    local uf = plate.UnitFrame or plate.unitFrame
    if uf and uf.CastBar then
        uf.CastBar:Hide()
        uf.CastBar:SetScript("OnShow", uf.CastBar.Hide)
    elseif uf and uf.castBar then
        uf.castBar:Hide()
        uf.castBar:SetScript("OnShow", uf.castBar.Hide)
    end
end

-- Register the module
ns.addon:RegisterModule("castbar", Castbar)
