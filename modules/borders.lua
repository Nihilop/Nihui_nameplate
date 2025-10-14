-- Nihui Nameplates - Border Styling (adapted from rnxmUI)
local addonName, ns = ...

local Borders = {}
ns.modules.borders = Borders


-- Get styling settings
local function GetStylingSettings()
    local settings = ns.nameplateSettings and ns.nameplateSettings()
    if settings then
        return {
            border = {
                enabled = settings.border.enabled,
                texture = settings.border.texture,
                color = settings.border.color,
                edgeSize = settings.border.edgeSize,
                offset = settings.border.offset,
                blendMode = settings.border.blendMode
            },
            glass = {
                enabled = settings.glass.enabled,
                texture = settings.glass.texture,
                alpha = settings.glass.alpha,
                blendMode = settings.glass.blendMode
            },
            statusbar = {
                enabled = settings.statusbar.enabled,
                texture = settings.statusbar.texture
            },
            targetHighlight = {
                enabled = settings.targetHighlight.enabled,
                color = settings.targetHighlight.color,
                useAdditive = settings.targetHighlight.useAdditive,
                removeDefault = settings.targetHighlight.removeDefault,
                enablePulse = settings.targetHighlight.enablePulse,
                texture = "Interface\\AddOns\\Nihui_np\\textures\\MirroredFrameSingle2hl.tga",
                alphaMax = settings.targetHighlight.alphaMax or 1.0,
                alphaMin = settings.targetHighlight.alphaMin or 0.5
            }
        }
    else
        -- Fallback hardcoded values
        return {
            border = {
                enabled = true,
                texture = "Interface\\AddOns\\Nihui_np\\textures\\MirroredFrameSingle2.tga",
                color = {0.5, 0.5, 0.5, 1},
                edgeSize = 13,
                offset = 10.5,
                blendMode = "BLEND"
            },
            glass = {
                enabled = true,
                texture = "Interface\\AddOns\\Nihui_np\\textures\\HPGlass.tga",
                alpha = 1,
                blendMode = "BLEND"
            },
            statusbar = {
                enabled = true,
                texture = "Interface\\AddOns\\Nihui_np\\textures\\blizzrnxm0.tga"
            },
            targetHighlight = {
                enabled = true,
                color = {1, 1, 0, 1}, -- Yellow
                useAdditive = true,
                removeDefault = true,
                enablePulse = true,
                texture = "Interface\\AddOns\\Nihui_np\\textures\\MirroredFrameSingle2hl.tga",
                alphaMax = 1.0,
                alphaMin = 0.5
            }
        }
    end
end

-- Clean up target highlighting when nameplate is removed
local function CleanupTargetHighlight(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end

    local healthBar = nameplate.UnitFrame.HealthBarsContainer and nameplate.UnitFrame.HealthBarsContainer.healthBar
    if not healthBar then return end

    if healthBar.nihuiTargetBorder then
        -- Clean up animation to prevent memory leaks
        if healthBar.nihuiTargetBorder.pulseGroup then
            healthBar.nihuiTargetBorder.pulseGroup:Stop()
        end
        healthBar.nihuiTargetBorder:Hide()
        healthBar.nihuiTargetBorder = nil
    end
end

-- Remove styling from nameplate
local function UnstyieNameplate(nameplate)
    if not nameplate then return end

    -- Remove border
    if nameplate.nihuiBorder then
        nameplate.nihuiBorder:Hide()
        nameplate.nihuiBorder = nil
    end

    -- Remove glass
    if nameplate.nihuiGlass then
        nameplate.nihuiGlass:Hide()
        nameplate.nihuiGlass = nil
    end

    -- Remove target highlight
    CleanupTargetHighlight(nameplate)

    -- Reset tracking
    nameplate.nihuiLastUnit = nil

    if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        nameplate.UnitFrame.healthBar.nihuiStyled = nil
    end
end

-- Style a single nameplate
local function StyleNameplate(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end

    local settings = GetStylingSettings()
    local healthBar = nameplate.UnitFrame.HealthBarsContainer and nameplate.UnitFrame.HealthBarsContainer.healthBar

    if not healthBar then return end

    -- Reset styling when nameplate is recycled for a new unit
    if healthBar.nihuiStyled and nameplate.nihuiLastUnit ~= nameplate.namePlateUnitToken then
        -- This nameplate was recycled, clean up old styling
        UnstyieNameplate(nameplate)
    end

    -- Skip if already styled for this unit
    if healthBar.nihuiStyled and nameplate.nihuiLastUnit == nameplate.namePlateUnitToken then
        return
    end

    -- Remember which unit this nameplate is styled for
    nameplate.nihuiLastUnit = nameplate.namePlateUnitToken

    -- Apply statusbar texture
    if settings.statusbar.enabled then
        healthBar:SetStatusBarTexture(settings.statusbar.texture)
    end

    -- Create border
    if settings.border.enabled then
        local border = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        border:SetFrameLevel(healthBar:GetFrameLevel() + 1)

        -- Position border with configured offset
        local offset = settings.border.offset
        border:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -offset, offset)
        border:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", offset, -offset)

        -- Set backdrop
        border:SetBackdrop({
            bgFile = nil, -- Explicitly set to nil to avoid white background
            edgeFile = settings.border.texture,
            edgeSize = settings.border.edgeSize,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })

        -- Set border color
        local color = settings.border.color
        border:SetBackdropBorderColor(color[1], color[2], color[3], color[4])

        nameplate.nihuiBorder = border
    end

    -- Create glass overlay
    if settings.glass.enabled then
        local glass = healthBar:CreateTexture(nil, "OVERLAY")
        glass:SetTexture(settings.glass.texture)
        glass:SetAllPoints(healthBar)
        glass:SetAlpha(settings.glass.alpha)

        if settings.glass.blendMode then
            glass:SetBlendMode(settings.glass.blendMode)
        end

        nameplate.nihuiGlass = glass
    end

    -- Remove default target highlight
    if settings.targetHighlight.enabled and settings.targetHighlight.removeDefault then
        if nameplate.UnitFrame.HealthBarsContainer and nameplate.UnitFrame.HealthBarsContainer.border then
            nameplate.UnitFrame.HealthBarsContainer.border:SetAlpha(0)
        end
    end

    -- Mark as styled AFTER all styling is complete
    healthBar.nihuiStyled = true
end

-- Update target highlighting
local function UpdateTargetHighlight(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end

    local settings = GetStylingSettings()
    if not settings.targetHighlight.enabled then
        -- If highlight is disabled, make sure to hide any existing highlight
        CleanupTargetHighlight(nameplate)
        return
    end

    local healthBar = nameplate.UnitFrame.HealthBarsContainer and nameplate.UnitFrame.HealthBarsContainer.healthBar
    if not healthBar then return end

    local unit = nameplate.namePlateUnitToken
    if not unit or not UnitExists(unit) then
        -- Unit doesn't exist, hide highlight
        if healthBar.nihuiTargetBorder then
            healthBar.nihuiTargetBorder:Hide()
        end
        return
    end

    local isTarget = UnitIsUnit(unit, "target")

    -- Add/remove target border overlay
    if nameplate.nihuiBorder then
        if isTarget then
            -- Create target border overlay if it doesn't exist
            if not healthBar.nihuiTargetBorder then
                local targetBorder = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
                targetBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -settings.border.offset, settings.border.offset)
                targetBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", settings.border.offset, -settings.border.offset)
                targetBorder:SetFrameLevel(nameplate.nihuiBorder:GetFrameLevel() + 2) -- +2 pour être au-dessus

                targetBorder:SetBackdrop({
                    bgFile = nil, -- Explicitly no background
                    edgeFile = settings.targetHighlight.texture,
                    edgeSize = settings.border.edgeSize,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 }
                })
                targetBorder:SetBackdropBorderColor(unpack(settings.targetHighlight.color))

                -- Set blend mode to ADD on the target border textures
                if settings.targetHighlight.useAdditive then
                    local regions = {targetBorder:GetRegions()}
                    for _, region in ipairs(regions) do
                        if region and region:GetObjectType() == "Texture" then
                            region:SetBlendMode("ADD")
                        end
                    end
                end

                -- Create a simple pulse animation if enabled
                if settings.targetHighlight.enablePulse then
                    targetBorder.pulseGroup = targetBorder:CreateAnimationGroup()
                    targetBorder.pulseGroup:SetLooping("BOUNCE")

                    local fadeAnim = targetBorder.pulseGroup:CreateAnimation("Alpha")
                    fadeAnim:SetDuration(0.8)
                    fadeAnim:SetFromAlpha(settings.targetHighlight.alphaMax)
                    fadeAnim:SetToAlpha(settings.targetHighlight.alphaMin)
                end

                healthBar.nihuiTargetBorder = targetBorder
            end

            -- Stop any existing animations and start fresh
            if healthBar.nihuiTargetBorder.pulseGroup and healthBar.nihuiTargetBorder.pulseGroup:IsPlaying() then
                healthBar.nihuiTargetBorder.pulseGroup:Stop()
            end

            healthBar.nihuiTargetBorder:Show()
            if healthBar.nihuiTargetBorder.pulseGroup and settings.targetHighlight.enablePulse then
                healthBar.nihuiTargetBorder.pulseGroup:Play()
            end

        else
            -- Hide target border when not targeted
            if healthBar.nihuiTargetBorder then
                -- Stop animation
                if healthBar.nihuiTargetBorder.pulseGroup and healthBar.nihuiTargetBorder.pulseGroup:IsPlaying() then
                    healthBar.nihuiTargetBorder.pulseGroup:Stop()
                end
                healthBar.nihuiTargetBorder:Hide()
            end
        end
    end
end

-- Refresh all target highlights
local function RefreshAllTargetHighlights()
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        if nameplate and nameplate.UnitFrame and nameplate.namePlateUnitToken then
            -- Check if unit has changed and clean up if needed
            if nameplate.nihuiLastUnit and nameplate.nihuiLastUnit ~= nameplate.namePlateUnitToken then
                -- Unit changed, restyle the nameplate
                StyleNameplate(nameplate)
            end
            UpdateTargetHighlight(nameplate)
        end
    end
end

-- Module functions
function Borders:OnEnable()
    local settings = ns.nameplateSettings()
    if not settings.enabled then return end

    -- Style existing nameplates
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        StyleNameplate(nameplate)
    end

    -- Listen for new nameplates and target changes
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            -- Update all nameplate highlights
            C_Timer.After(0.05, RefreshAllTargetHighlights)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Clean up all nameplates and re-style them
            C_Timer.After(1, function()
                for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
                    if nameplate then
                        -- Force clean up and re-style
                        UnstyieNameplate(nameplate)
                        StyleNameplate(nameplate)
                    end
                end
                RefreshAllTargetHighlights()
            end)
        else
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate then
                if event == "NAME_PLATE_UNIT_ADDED" then
                    StyleNameplate(nameplate)
                    -- Update highlight for this new nameplate
                    C_Timer.After(0.1, function()
                        UpdateTargetHighlight(nameplate)
                    end)
                elseif event == "NAME_PLATE_UNIT_REMOVED" then
                    UnstyieNameplate(nameplate)
                end
            end
        end
    end)

    self.eventFrame = frame
end

function Borders:OnDisable()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame = nil
    end

    -- Remove styling from all nameplates
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        UnstyieNameplate(nameplate)
    end
end

function Borders:ApplySettings()
    -- Restart the system to apply new settings
    self:OnDisable()
    self:OnEnable()
end

-- Register the module
ns.addon:RegisterModule("borders", Borders)