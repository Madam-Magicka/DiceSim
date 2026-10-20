local DiceSim = _G.DiceSim

local MAX_CHARACTER_TABS = 40

local function CreateCharacterTab(parent)
    local theme = DiceSim.Theme
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(46, 46)
    tab:SetBackdrop(nil)

    local portrait = tab:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(38, 38)
    portrait:SetPoint("CENTER", tab, "CENTER", 0, 0)
    portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local portraitMask = tab:CreateMaskTexture()
    portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    portraitMask:SetAllPoints(portrait)
    portrait:AddMaskTexture(portraitMask)

    local portraitRing = tab:CreateTexture(nil, "OVERLAY")
    portraitRing:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    portraitRing:SetSize(48, 48)
    DiceSim:ApplyTextureOrAtlas(portraitRing, "hud-PlayerFrame-portraitring-large")
    tab.PortraitRing = portraitRing

    tab.Portrait = portrait

    tab:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end

        DiceSim:OpenSheetPanel(self.Unit)
    end)

    tab:SetScript("OnEnter", function(self)
        DiceSim:ShowCharacterTabTooltip(self)
    end)

    tab:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    tab:Hide()
    return tab
end

local function AddRosterUnit(units, seen, unit)
    if seen[unit] then
        return
    end

    if unit ~= "player" and UnitExists and not UnitExists(unit) then
        return
    end

    local key = DiceSim.GetUnitSheetSyncKey and DiceSim:GetUnitSheetSyncKey(unit) or unit
    local name = UnitName and UnitName(unit) or unit

    if DiceSim.SessionHiddenPlayers and (DiceSim.SessionHiddenPlayers[key] or DiceSim.SessionHiddenPlayers[name]) then
        return
    end

    if unit ~= "player" then
        if DiceSim.SessionRosterLocked and DiceSim.SessionPlayers then
            if not DiceSim.SessionPlayers[key] and not DiceSim.SessionPlayers[name] then
                return
            end
        end
    end

    seen[unit] = true
    table.insert(units, unit)
end

function DiceSim:GetCharacterTabUnits()
    local units = {}
    local seen = {}

    AddRosterUnit(units, seen, "player")

    if IsInRaid and IsInRaid() then
        for index = 1, 40 do
            AddRosterUnit(units, seen, "raid" .. index)
        end
    elseif IsInGroup and IsInGroup() then
        for index = 1, 4 do
            AddRosterUnit(units, seen, "party" .. index)
        end
    end

    return units
end

function DiceSim:CreateCharacterTabs(parent)
    local layer = CreateFrame("Frame", nil, parent)
    layer:SetAllPoints(parent)
    layer:SetFrameLevel(parent:GetFrameLevel() + 9)
    self.CharacterTabLayer = layer
    self.CharacterTabs = {}

    for index = 1, MAX_CHARACTER_TABS do
        local tab = CreateCharacterTab(layer)
        tab:SetFrameLevel(layer:GetFrameLevel() + 1)
        table.insert(self.CharacterTabs, tab)
    end

    self:RefreshCharacterTabs()
    self:RefreshPermissions()
    table.insert(self.MainContent, layer)
end

function DiceSim:GetSheetHPForUnit(unit)
    unit = unit or "player"

    if unit ~= "player" then
        return nil
    end

    local hp = self:GetSheetMetricValue("hp")
    local _, defaultHpMax = self:GetDefaultSheetMetric("hp")
    local hpMax = self.GetSheetMetricMax and self:GetSheetMetricMax("hp") or defaultHpMax
    if hp and hp > 0 then
        return hp, hpMax
    end

    local profileName = self.SheetPanel and self.SheetPanel.ProfileDropdown and self.SheetPanel.ProfileDropdown.Value
    local profile = profileName and self:GetSheetProfileStore()[profileName]
    hp = profile and profile.metrics and tonumber(profile.metrics.hp)
    hpMax = profile and profile.metrics and tonumber(profile.metrics.hpMax) or defaultHpMax
    if hp and hp > 0 then
        return hp, hpMax
    end

    return nil
end

function DiceSim:GetSheetAffectsForUnit(unit)
    unit = unit or "player"

    if unit == "player" and self.SheetPanel then
        return {
            buffs = self:GetAffectStripData(self.SheetPanel.BuffStrip),
            debuffs = self:GetAffectStripData(self.SheetPanel.DebuffStrip),
        }
    end

    local key = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey(unit)
    local remote = key and self.GetRemoteSheetStore and self:GetRemoteSheetStore()[key]
    return remote and remote.affects or nil
end

function DiceSim:RefreshCharacterTab(tab, unit)
    unit = unit or "player"
    tab.Unit = unit

    if UnitExists and UnitExists(unit) then
        SetPortraitTexture(tab.Portrait, unit)
        local unitName = UnitName and UnitName(unit) or unit
        tab.DisplayName = unitName or unit
    else
        tab.Portrait:SetTexture("Interface\\Icons\\INV_Misc_Dice_01")
        tab.DisplayName = "Player"
    end

    local ring = "hud-PlayerFrame-portraitring-large"
    if unit == "player" and self.GetSheetPortraitRing then
        ring = self:GetSheetPortraitRing()
    else
        local key = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey(unit)
        local remote = key and self.GetRemoteSheetStore and self:GetRemoteSheetStore()[key]
        ring = remote and remote.portraitRing or ring
    end
    if self.ApplyPortraitRingTexture then
        self:ApplyPortraitRingTexture(tab.PortraitRing, ring, 48)
    else
        self:ApplyTextureOrAtlas(tab.PortraitRing, ring)
        tab.PortraitRing:SetSize(48, 48)
    end
end

local function AddAffectTooltipLines(title, affects)
    if not affects or #affects == 0 then
        return
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(title, 0.72, 0.68, 0.9)
    for _, affect in ipairs(affects) do
        local name = affect.name and affect.name ~= "" and affect.name or title
        local modifier = DiceSim:GetSignedNumber(affect.modifier or 0)
        local appliesTo = affect.appliesTo and affect.appliesTo ~= "" and (" - " .. affect.appliesTo) or ""
        GameTooltip:AddLine(name .. " " .. modifier .. appliesTo, 1, 1, 1)
    end
end

function DiceSim:ShowCharacterTabTooltip(tab)
    if not tab then
        return
    end

    GameTooltip:SetOwner(tab, "ANCHOR_TOP")
    GameTooltip:SetText(tab.DisplayName or "Player")

    local hp, hpMax = self:GetSheetHPForUnit(tab.Unit)
    if not hp and UnitExists and UnitExists(tab.Unit) and UnitHealthMax then
        hpMax = UnitHealthMax(tab.Unit)
        hp = UnitHealth and UnitHealth(tab.Unit) or nil
    end
    if hp and hpMax then
        GameTooltip:AddLine("HP: " .. hp .. "/" .. hpMax, 1, 1, 1)
    end

    local key = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey(tab.Unit)
    local remote = key and self.GetRemoteSheetStore and self:GetRemoteSheetStore()[key]
    if tab.Unit == "player" and self.GetImportedDiceSystemName then
        GameTooltip:AddLine(self:GetImportedDiceSystemName() and ("Imported: " .. self:GetImportedDiceSystemName()) or "Default", 0.72, 0.68, 0.9)
    elseif remote and remote.diceSystem then
        GameTooltip:AddLine(remote.diceSystem, 0.72, 0.68, 0.9)
    end

    local ring = tab.Unit == "player" and self.GetSheetPortraitRing and self:GetSheetPortraitRing() or remote and remote.portraitRing
    if ring then
        GameTooltip:AddLine("Ring: " .. ring, 0.72, 0.68, 0.9)
    end

    local affects = self:GetSheetAffectsForUnit(tab.Unit) or {}
    AddAffectTooltipLines("Buffs", affects.buffs)
    AddAffectTooltipLines("Debuffs", affects.debuffs)

    GameTooltip:Show()
end

function DiceSim:LayoutCharacterTabs(units)
    local parent = self.MainFrame
    if not parent then
        return
    end

    local count = math.min(#units, #self.CharacterTabs)
    local tabWidth = 46
    local tabHeight = 46
    local gap = 6
    local verticalGap = 6
    local parentWidth = parent:GetWidth() or MAIN_WIDTH or 960
    local parentHeight = parent:GetHeight() or MAIN_HEIGHT or 640
    local horizontalCapacity = math.max(1, math.floor((parentWidth + gap) / (tabWidth + gap)))
    local verticalCapacity = math.max(1, math.floor((parentHeight + gap) / (tabHeight + verticalGap)))
    local baseSideCount = math.ceil(count / 4)
    local topSlots = math.min(horizontalCapacity, baseSideCount)
    local bottomSlots = math.min(horizontalCapacity, baseSideCount)
    local leftSlots = math.min(verticalCapacity, baseSideCount)
    local rightSlots = math.min(verticalCapacity, baseSideCount)

    local assigned = topSlots + bottomSlots + leftSlots + rightSlots
    while assigned < count do
        local changed = false
        if topSlots < horizontalCapacity then
            topSlots = topSlots + 1
            assigned = assigned + 1
            changed = true
            if assigned >= count then
                break
            end
        end
        if bottomSlots < horizontalCapacity then
            bottomSlots = bottomSlots + 1
            assigned = assigned + 1
            changed = true
            if assigned >= count then
                break
            end
        end
        if leftSlots < verticalCapacity then
            leftSlots = leftSlots + 1
            assigned = assigned + 1
            changed = true
            if assigned >= count then
                break
            end
        end
        if rightSlots < verticalCapacity then
            rightSlots = rightSlots + 1
            assigned = assigned + 1
            changed = true
        end
        if not changed then
            break
        end
    end

    local function getEdgePosition(index)
        if index <= topSlots then
            local used = math.min(count, topSlots)
            local totalWidth = (used * tabWidth) + (math.max(0, used - 1) * gap)
            return "BOTTOM", parent, "TOP", -totalWidth / 2 + tabWidth / 2 + ((index - 1) * (tabWidth + gap)), 6
        end

        index = index - topSlots
        if index <= leftSlots then
            local used = math.min(math.max(0, count - topSlots), leftSlots)
            local totalHeight = (used * tabHeight) + (math.max(0, used - 1) * verticalGap)
            return "RIGHT", parent, "LEFT", -6, totalHeight / 2 - tabHeight / 2 - ((index - 1) * (tabHeight + verticalGap))
        end

        index = index - leftSlots
        if index <= bottomSlots then
            local remaining = math.max(0, count - topSlots - leftSlots)
            local used = math.min(remaining, bottomSlots)
            local totalWidth = (used * tabWidth) + (math.max(0, used - 1) * gap)
            return "TOP", parent, "BOTTOM", -totalWidth / 2 + tabWidth / 2 + ((index - 1) * (tabWidth + gap)), -6
        end

        index = index - bottomSlots
        local used = math.min(math.max(0, count - topSlots - leftSlots - bottomSlots), rightSlots)
        local totalHeight = (used * tabHeight) + (math.max(0, used - 1) * verticalGap)
        return "LEFT", parent, "RIGHT", 6, totalHeight / 2 - tabHeight / 2 - ((index - 1) * (tabHeight + verticalGap))
    end

    for index, tab in ipairs(self.CharacterTabs) do
        tab:ClearAllPoints()

        if index <= count then
            tab:SetPoint(getEdgePosition(index))
            tab:Show()
        else
            tab:Hide()
        end
    end
end

function DiceSim:RefreshCharacterTabs()
    if not self.CharacterTabs then
        return
    end

    local units = self:GetCharacterTabUnits()
    self:LayoutCharacterTabs(units)

    for index, unit in ipairs(units) do
        local tab = self.CharacterTabs[index]
        if tab then
            self:RefreshCharacterTab(tab, unit)
        end
    end
end
