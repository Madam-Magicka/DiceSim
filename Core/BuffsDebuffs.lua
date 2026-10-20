-- Buffs and Debuffs management functions

local DiceSim = _G.DiceSim

DiceSim.BuffsDebuffs = DiceSim.BuffsDebuffs or {}

function DiceSim:RefreshAffectStrip(strip)
    if not strip or not strip.Icons then
        return
    end
    local previousIcon
    local visibleCount = 0
    for _, icon in ipairs(strip.Icons) do
        icon:ClearAllPoints()
        if icon:IsShown() then
            if previousIcon then
                icon:SetPoint("LEFT", previousIcon, "RIGHT", 6, 0)
            else
                icon:SetPoint("LEFT", strip.Content, "LEFT", 0, 0)
            end
            previousIcon = icon
            visibleCount = visibleCount + 1
        end
    end
    local iconSize = strip.IconSize or 26
    local contentWidth = math.max(260, (visibleCount * (iconSize + 6)) - 6)
    strip.Content:SetWidth(contentWidth)
    strip.ScrollBar:SetMinMaxValues(0, math.max(0, contentWidth - strip.ScrollFrame:GetWidth()))
end

function DiceSim:SetAffectRemoveMode(strip, button)
    local previousButton = self.ActiveAffectRemoveButton
    if self.ActiveAffectRemoveStrip and self.ActiveAffectRemoveStrip ~= strip then
        self.ActiveAffectRemoveStrip.RemoveMode = false
    end
    if previousButton and not previousButton.IsAssetButton then
        previousButton:SetBackdropBorderColor(unpack(self.Theme.colors.controlBorder))
    end
    strip.RemoveMode = not strip.RemoveMode
    self.ActiveAffectRemoveStrip = strip.RemoveMode and strip or nil
    self.ActiveAffectRemoveButton = strip.RemoveMode and button or nil
    if button and not button.IsAssetButton then
        if strip.RemoveMode then
            button:SetBackdropBorderColor(unpack(self.Theme.colors.danger))
        else
            button:SetBackdropBorderColor(unpack(self.Theme.colors.controlBorder))
        end
    end
    if strip.RemoveMode and SetCursor then
        SetCursor("CAST_CURSOR")
    elseif ResetCursor then
        ResetCursor()
    end
end

function DiceSim:ConfigureAffectIcon(icon, strip)
    strip.Icons = strip.Icons or {}
    table.insert(strip.Icons, icon)
    icon.AffectStrip = strip
    if strip.IconSize then
        icon:SetSize(strip.IconSize, strip.IconSize)
        if icon.Texture then
            icon.Texture:SetSize(strip.IconSize - 4, strip.IconSize - 4)
        end
    end
    if strip.HideIconBackdrop then
        if icon.SetBackdrop then
            icon:SetBackdrop(nil)
        end
    end
    icon:SetScript("OnEnter", function(self)
        if not self.AffectStrip.HideIconBackdrop then
            if self.AffectStrip.RemoveMode then
                self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.danger))
            else
                self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorderHover))
            end
        end
        if self.AffectData then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText((self.AffectData.name and self.AffectData.name ~= "" and self.AffectData.name) or (self.AffectData.type == "debuff" and "Debuff" or "Buff"))
            GameTooltip:AddLine(self.AffectData.type == "debuff" and "Debuff" or "Buff", 0.72, 0.68, 0.9)
            if self.AffectData.appliesTo then
                GameTooltip:AddLine("Applies to: " .. self.AffectData.appliesTo, 1, 1, 1)
            end
            GameTooltip:AddLine("Modifier: " .. DiceSim:GetSignedNumber(self.AffectData.modifier or 0), 1, 1, 1)
            if self.AffectData.details and self.AffectData.details ~= "" then
                GameTooltip:AddLine(self.AffectData.details, 0.78, 0.72, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    icon:SetScript("OnLeave", function(self)
        if not self.AffectStrip.HideIconBackdrop then
            self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorder))
        end
        GameTooltip:Hide()
    end)
    icon:SetScript("OnClick", function(self)
        if not self.AffectStrip.RemoveMode then
            return
        end
        self:Hide()
        if self.LinkedAffectIcon then
            self.LinkedAffectIcon:Hide()
            DiceSim:RefreshAffectStrip(self.LinkedAffectIcon.AffectStrip)
        end
        DiceSim:SetAffectRemoveMode(self.AffectStrip, nil)
        DiceSim:RefreshAffectStrip(self.AffectStrip)
        if self.AffectStrip and self.AffectStrip.OwnerContext == DiceSim.SheetPanel and DiceSim.ScheduleSheetBroadcast then
            DiceSim:ScheduleSheetBroadcast()
            if DiceSim.RefreshCharacterTabs then
                DiceSim:RefreshCharacterTabs()
            end
        elseif self.AffectStrip and self.AffectStrip.OwnerContext and DiceSim.SaveSessionSnapshot then
            DiceSim:SaveSessionSnapshot()
        end
    end)
end

function DiceSim:AddAffectIcon(strip, data)
    if not strip then
        return nil
    end
    strip.Icons = strip.Icons or {}
    local icon = CreatePlaceholderIcon(strip.Content, #strip.Icons + 1)
    icon.AffectData = data or {}
    if data and data.icon then
        icon.Texture:SetTexture(data.icon)
    end
    self:ConfigureAffectIcon(icon, strip)
    self:RefreshAffectStrip(strip)
    return icon
end

function DiceSim:AddAffectToContext(context, affectType, data)
    if not context then
        return
    end
    local editStrip = affectType == "debuff" and context.EditDebuffStrip or context.EditBuffStrip
    local displayStrip = affectType == "debuff" and context.DebuffStrip or context.BuffStrip
    local editIcon
    local displayIcon
    if editStrip then
        editIcon = self:AddAffectIcon(editStrip, data)
    end
    if displayStrip and displayStrip ~= editStrip then
        displayIcon = self:AddAffectIcon(displayStrip, data)
    end
    if editIcon and displayIcon then
        editIcon.LinkedAffectIcon = displayIcon
        displayIcon.LinkedAffectIcon = editIcon
    end

    if context == self.SheetPanel and self.ScheduleSheetBroadcast then
        self:ScheduleSheetBroadcast()
        if self.RefreshCharacterTabs then
            self:RefreshCharacterTabs()
        end
    elseif self.SaveSessionSnapshot and not self.IsApplyingSessionSnapshot then
        self:SaveSessionSnapshot()
    end
end

function DiceSim:GetAffectStripData(strip)
    local data = {}

    for _, icon in ipairs((strip and strip.Icons) or {}) do
        if icon:IsShown() and icon.AffectData then
            table.insert(data, {
                type = icon.AffectData.type,
                icon = icon.AffectData.icon,
                name = icon.AffectData.name,
                details = icon.AffectData.details,
                appliesTo = icon.AffectData.appliesTo,
                modifier = icon.AffectData.modifier,
            })
        end
    end

    return data
end

function DiceSim:SyncAffectEditStrips(context)
    if not context then
        return
    end

    local function syncStrip(displayStrip, editStrip)
        if not displayStrip or not editStrip or displayStrip == editStrip then
            return
        end

        self:ClearAffectStrip(editStrip)
        for _, displayIcon in ipairs(displayStrip.Icons or {}) do
            if displayIcon:IsShown() and displayIcon.AffectData then
                local editIcon = self:AddAffectIcon(editStrip, displayIcon.AffectData)
                if editIcon then
                    editIcon.LinkedAffectIcon = displayIcon
                    displayIcon.LinkedAffectIcon = editIcon
                end
            end
        end
    end

    syncStrip(context.BuffStrip, context.EditBuffStrip)
    syncStrip(context.DebuffStrip, context.EditDebuffStrip)
end

function DiceSim:ClearAffectStrip(strip)
    for _, icon in ipairs((strip and strip.Icons) or {}) do
        icon:Hide()
    end

    self:RefreshAffectStrip(strip)
end

function DiceSim:ApplyAffectsToContext(context, affects)
    if not context then
        return
    end

    self:ClearAffectStrip(context.BuffStrip)
    self:ClearAffectStrip(context.DebuffStrip)
    if context.EditBuffStrip and context.EditBuffStrip ~= context.BuffStrip then
        self:ClearAffectStrip(context.EditBuffStrip)
    end
    if context.EditDebuffStrip and context.EditDebuffStrip ~= context.DebuffStrip then
        self:ClearAffectStrip(context.EditDebuffStrip)
    end

    for _, data in ipairs((affects and affects.buffs) or {}) do
        data.type = "buff"
        self:AddAffectToContext(context, "buff", data)
    end

    for _, data in ipairs((affects and affects.debuffs) or {}) do
        data.type = "debuff"
        self:AddAffectToContext(context, "debuff", data)
    end
end

function DiceSim:DoesAffectApplyToAction(appliesTo, action)
    if not appliesTo or appliesTo == "" then
        return false
    end
    if appliesTo == "All Rolls" then
        return true
    end
    action = action or ""
    if string.lower(appliesTo) == string.lower(action) then
        return true
    end
    return self:IsInitiativeAction(appliesTo) and self:IsInitiativeAction(action)
end

function DiceSim:CollectAffectRollModifier(context, action)
    local result = {
        total = 0,
        parts = {},
    }
    if not context then
        return result
    end
    local strips = { context.BuffStrip, context.DebuffStrip }
    for _, strip in ipairs(strips) do
        for _, icon in ipairs((strip and strip.Icons) or {}) do
            local data = icon:IsShown() and icon.AffectData or nil
            if data and self:DoesAffectApplyToAction(data.appliesTo, action) then
                local modifier = tonumber(data.modifier) or 0
                if modifier ~= 0 then
                    result.total = result.total + modifier
                    local name = data.name and data.name ~= "" and data.name or (data.type == "debuff" and "Debuff" or "Buff")
                    table.insert(result.parts, name .. " " .. self:GetSignedNumber(modifier))
                end
            end
        end
    end
    return result
end
