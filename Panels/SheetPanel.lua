-- Sheet panel UI and controls.

local DiceSim = _G.DiceSim
local Clamp = DiceSim.Utils.Clamp

function DiceSim:CreateDiceSystemImportPanel(parent)
    local panel = CreatePanel(parent, "DiceSimDiceSystemImportPanel", 420, 360)
    panel.TutorialKey = "diceSystemImport"
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local closeButton = CreateTrayButton(panel, "DiceSimDiceSystemImportCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Import Dice System")

    local inputBox = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    inputBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -64)
    inputBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -22, 76)
    self:ApplyBackdrop(inputBox, self.Theme.colors.insetBg, self.Theme.colors.insetBorder, 1)

    local scroll = CreateFrame("ScrollFrame", nil, inputBox, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", inputBox, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", inputBox, "BOTTOMRIGHT", -28, 8)
    ApplyScrollBarSkin(scroll)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(unpack(self.Theme.colors.text))
    editBox:SetWidth(340)
    editBox:SetMaxLetters(12000)
    editBox:SetText("")
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnCursorChanged", function(_, _, y)
        scroll:SetVerticalScroll(y)
    end)
    scroll:SetScrollChild(editBox)
    panel.ImportInput = editBox

    local status = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("BOTTOM", panel, "BOTTOM", 0, 50)
    status:SetWidth(350)
    status:SetJustifyH("CENTER")
    status:SetText("")
    panel.StatusText = status

    local resetButton = CreatePanelButton(panel, "Reset")
    resetButton:SetSize(112, 28)
    resetButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 72, 18)
    FitPanelButtonLabel(resetButton)
    resetButton:SetScript("OnClick", function()
        DiceSim:ResetImportedDiceSystem()
        editBox:SetText("")
        status:SetText("|cff9ee8a5Imported dice data reset.|r")
    end)

    local importButton = CreatePanelButton(panel, "Import")
    importButton:SetSize(112, 28)
    importButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -72, 18)
    FitPanelButtonLabel(importButton)
    importButton:SetScript("OnClick", function()
        local ok, message = DiceSim:ImportDiceSystemJson(editBox:GetText())
        if ok then
            status:SetText("|cff9ee8a5Imported dice data.|r")
        else
            status:SetText("|cffff6060" .. tostring(message or "Import failed.") .. "|r")
        end
    end)

    self.DiceSystemImportPanel = panel
    return panel
end

function DiceSim:ToggleDiceSystemImportPanel()
    if not self.DiceSystemImportPanel then
        self:CreateDiceSystemImportPanel(self.Frame)
    end

    self.DiceSystemImportPanel:SetShown(not self.DiceSystemImportPanel:IsShown())
    if self.DiceSystemImportPanel:IsShown() then
        self:BringWindowToFront(self.DiceSystemImportPanel)
    end
end

function DiceSim:CreateSheetPanel(parent, anchor)
    local theme = self.Theme
    local panel = CreatePanel(parent, "DiceSimSheetPanel", 440, 650)
    panel.TutorialKey = "sheet"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)
    if panel.BackgroundArt then
        self:ApplyTextureOrAtlas(panel.BackgroundArt, theme.textures.sheetPanelBg)
        panel.BackgroundArt:SetAlpha(0.56)
    end

    local SHEET_CONTENT_WIDTH = 390
    local BIO_WIDTH = 360
    local ATTRIBUTE_ROW_WIDTH = 238
    local METRIC_WIDTH = 116
    local METRIC_GAP = 10
    local totalMetricWidth = (METRIC_WIDTH * 3) + (METRIC_GAP * 2)
    local firstMetricX = -totalMetricWidth / 2 + METRIC_WIDTH / 2

    local closeButton = CreateTrayButton(panel, "DiceSimSheetPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local importButton = CreateTrayButton(panel, "DiceSimSheetImportButton", "AnimCreate_Icon_Folder", "Import Dice System")
    importButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -4, 0)
    importButton:SetScript("OnClick", function()
        if self:CanImportDiceSystem(panel.Unit or "player") then
            self:ToggleDiceSystemImportPanel()
        end
    end)
    panel.ImportButton = importButton

    panel.EditableInputs = {}
    panel.EditableControls = {}
    panel.IdentityInputs = {}
    panel.ProfileControls = {}

    local sheetScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    sheetScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
    sheetScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 12)
    ApplyScrollBarSkin(sheetScroll)

    local sheetContent = CreateFrame("Frame", nil, sheetScroll)
    sheetContent:SetSize(SHEET_CONTENT_WIDTH, 720)
    sheetScroll:SetScrollChild(sheetContent)
    panel.ScrollFrame = sheetScroll
    panel.Content = sheetContent

    local profiles = CreateDropdownField(sheetContent, "Profiles", self:GetSheetProfileOptions(), function(value)
        self:LoadSheetProfile(value)
    end)
    profiles:SetSize(180, 30)
    profiles:SetPoint("TOP", sheetContent, "TOP", 0, -16)
    profiles.RefreshOptions = function()
        return self:GetSheetProfileOptions()
    end
    panel.ProfileDropdown = profiles
    panel.ProfileLabel = profiles.Label
    table.insert(panel.ProfileControls, profiles)

    local profileNameInput = CreateTextInputBox(sheetContent, 132, 28, 40, false)
    profileNameInput:SetPoint("TOP", profiles, "BOTTOM", 0, -8)
    SetInputPlaceholder(profileNameInput, "Profile name")
    panel.ProfileNameInput = profileNameInput
    table.insert(panel.IdentityInputs, profileNameInput)

    local profileRemove = CreateTrayButton(sheetContent, nil, "Interface\\Buttons\\UI-MinusButton-Up", "Remove Profile")
    profileRemove:SetPoint("RIGHT", profileNameInput, "LEFT", -8, 0)
    profileRemove:SetScript("OnClick", function()
        self:RemoveSheetProfile()
    end)
    table.insert(panel.ProfileControls, profileRemove)

    local profileAdd = CreateTrayButton(sheetContent, nil, "Interface\\Buttons\\UI-PlusButton-Up", "Save Profile")
    profileAdd:SetPoint("LEFT", profileNameInput, "RIGHT", 8, 0)
    profileAdd:SetScript("OnClick", function()
        self:SaveSheetProfile()
    end)
    table.insert(panel.ProfileControls, profileAdd)

    local systemStatus = sheetContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    systemStatus:SetPoint("TOP", profileNameInput, "BOTTOM", 0, -6)
    systemStatus:SetWidth(260)
    systemStatus:SetJustifyH("CENTER")
    panel.SystemStatusText = systemStatus

    function panel:RefreshSystemStatus()
        local systemName = DiceSim:GetImportedDiceSystemName()
        if self.Unit ~= "player" and self.RemoteSheetSystem then
            self.SystemStatusText:SetText(self.RemoteSheetSystem)
        elseif systemName then
            self.SystemStatusText:SetText("Imported: " .. systemName)
        else
            self.SystemStatusText:SetText("")
        end
    end

    function DiceSim:RefreshSheetSystemStatus()
        if self.SheetPanel and self.SheetPanel.RefreshSystemStatus then
            self.SheetPanel:RefreshSystemStatus()
        end
    end

    local portrait = CreateFrame("Button", nil, sheetContent, "BackdropTemplate")
    portrait:SetSize(92, 92)
    portrait:SetPoint("TOP", profileNameInput, "BOTTOM", 0, -42)
    portrait:SetBackdrop(nil)
    portrait:EnableMouse(true)
    local portraitHover = portrait:CreateTexture(nil, "HIGHLIGHT")
    portraitHover:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    portraitHover:SetSize(118, 118)
    self:ApplyTextureOrAtlas(portraitHover, "Artifacts-PerkRing-Final")
    portraitHover:SetBlendMode("ADD")
    portraitHover:SetVertexColor(1.0, 0.74, 0.22, 0.9)
    portraitHover:SetAlpha(0.85)
    portrait:SetHighlightTexture(portraitHover, "ADD")
    portrait:SetScript("OnEnter", function()
        if self:CanEditSheetIdentity(panel.Unit or "player") then
            GameTooltip:SetOwner(portrait, "ANCHOR_TOP")
            GameTooltip:SetText("Choose Portrait Ring")
            GameTooltip:Show()
        end
    end)
    portrait:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    portrait:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and self:CanEditSheetIdentity(panel.Unit or "player") then
            self:OpenPortraitRingPicker()
        end
    end)

    local portraitMask = portrait:CreateMaskTexture()
    portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    portraitMask:SetAllPoints(portrait)

    local portraitTexture = portrait:CreateTexture(nil, "ARTWORK")
    portraitTexture:SetAllPoints(portrait)
    portraitTexture:AddMaskTexture(portraitMask)
    panel.PortraitTexture = portraitTexture

    local portraitRing = portrait:CreateTexture(nil, "OVERLAY")
    portraitRing:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    local initialRing = self.GetSheetPortraitRing and self:GetSheetPortraitRing() or "hud-PlayerFrame-portraitring-large"
    if self.ApplyPortraitRingTexture then
        self:ApplyPortraitRingTexture(portraitRing, initialRing, 112)
    else
        portraitRing:SetSize(112, 112)
        self:ApplyTextureOrAtlas(portraitRing, initialRing)
    end
    panel.PortraitRing = portraitRing

    if SetPortraitTexture then
        SetPortraitTexture(portraitTexture, "player")
    else
        portraitTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    local nameLabel = CreateLabel(sheetContent, "Name")
    nameLabel:SetPoint("TOPLEFT", portrait, "BOTTOM", -(BIO_WIDTH / 2), -24)

    local nameBox = CreateTextInputBox(sheetContent, 168, 30, 48, false)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)
    SetInputPlaceholder(nameBox, "Character name")
    nameBox:HookScript("OnTextChanged", function()
        if DiceSim.SaveCurrentSheetData then
            DiceSim:SaveCurrentSheetData()
        end
    end)
    panel.CharacterNameInput = nameBox
    table.insert(panel.IdentityInputs, nameBox)

    local classLabel = CreateLabel(sheetContent, "Class")
    classLabel:SetPoint("TOPLEFT", portrait, "BOTTOM", 10, -24)

    local classBox = CreateTextInputBox(sheetContent, 168, 30, 32, false)
    classBox:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", 0, -5)
    SetInputPlaceholder(classBox, "Class")
    classBox:HookScript("OnTextChanged", function()
        if DiceSim.SaveCurrentSheetData then
            DiceSim:SaveCurrentSheetData()
        end
    end)
    panel.ClassInput = classBox
    table.insert(panel.IdentityInputs, classBox)

    local biographyContainer = CreateFrame("Frame", nil, sheetContent, "BackdropTemplate")
    biographyContainer:SetSize(BIO_WIDTH, 96)
    biographyContainer:SetPoint("TOP", portrait, "BOTTOM", 0, -88)

    biographyContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })

    biographyContainer:SetBackdropColor(unpack(theme.colors.insetBg))
    biographyContainer:SetBackdropBorderColor(unpack(theme.colors.insetBorder))

    local biographyScroll = CreateFrame("ScrollFrame", nil, biographyContainer, "UIPanelScrollFrameTemplate")
    biographyScroll:SetPoint("TOPLEFT", biographyContainer, "TOPLEFT", 8, -8)
    biographyScroll:SetPoint("BOTTOMRIGHT", biographyContainer, "BOTTOMRIGHT", -28, 8)
    ApplyScrollBarSkin(biographyScroll)

    local biography = CreateFrame("EditBox", nil, biographyScroll)
    biography:SetMultiLine(true)
    biography:SetFontObject(ChatFontNormal)
    biography:SetWidth(BIO_WIDTH - 40)
    biography:SetAutoFocus(false)
    biography:SetMaxLetters(400)
    biography:SetTextInsets(2, 2, 2, 2)

    biography:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    biography:SetScript("OnCursorChanged", function(self, x, y, w, h)
        biographyScroll:SetVerticalScroll(y)
    end)

    biography:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""

        if text == "" then
            placeholder:Show()
        else
            placeholder:Hide()
        end
    end)
    biography:HookScript("OnTextChanged", function()
        if DiceSim.SaveCurrentSheetData then
            DiceSim:SaveCurrentSheetData()
        end
    end)

    biographyScroll:SetScrollChild(biography)

    local placeholder = biography:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    placeholder:SetPoint("TOPLEFT", biography, "TOPLEFT", 4, -4)
    placeholder:SetText("Biography")
    placeholder:SetTextColor(0.5, 0.5, 0.5, 0.8)

    panel.BiographyContainer = biographyContainer
    panel.BiographyInput = biography
    table.insert(panel.IdentityInputs, biography)

    panel.StatInputs = {}
    panel.StatRows = {}

    local pointBudgetRow = CreateFrame("Frame", nil, sheetContent)
    pointBudgetRow:SetSize(220, 26)
    pointBudgetRow:SetPoint("TOP", biographyContainer, "BOTTOM", 0, -12)

    local pointBudgetMinus = CreateProfileAdjustButton(pointBudgetRow, "Interface\\Buttons\\UI-MinusButton-Up", "Decrease Points")
    pointBudgetMinus:SetPoint("LEFT", pointBudgetRow, "LEFT", 0, 0)
    pointBudgetMinus:Show()
    pointBudgetMinus:SetScript("OnClick", function()
        self:AdjustSheetPointBudget(-1)
    end)
    table.insert(panel.EditableControls, pointBudgetMinus)

    local pointBudget = pointBudgetRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pointBudget:SetWidth(150)
    pointBudget:SetJustifyH("CENTER")
    pointBudget:SetPoint("LEFT", pointBudgetMinus, "RIGHT", 4, 0)
    pointBudget:SetText("Points: " .. CHARACTER_POINT_BUDGET .. "/" .. CHARACTER_POINT_BUDGET)
    panel.PointBudgetText = pointBudget

    local pointBudgetPlus = CreateProfileAdjustButton(pointBudgetRow, "Interface\\Buttons\\UI-PlusButton-Up", "Increase Points")
    pointBudgetPlus:SetPoint("LEFT", pointBudget, "RIGHT", 4, 0)
    pointBudgetPlus:Show()
    pointBudgetPlus:SetScript("OnClick", function()
        self:AdjustSheetPointBudget(1)
    end)
    table.insert(panel.EditableControls, pointBudgetPlus)

    local attributesHeaderRow = CreateFrame("Frame", nil, sheetContent)
    attributesHeaderRow:SetSize(170, 24)
    attributesHeaderRow:SetPoint("TOP", pointBudgetRow, "BOTTOM", 0, -16)

    local attributesTitle = sheetContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    attributesTitle:SetPoint("CENTER", attributesHeaderRow, "CENTER", 0, 0)
    attributesTitle:SetText("Attributes")
    panel.AttributesTitle = attributesTitle

    local removeAttributeButton = CreateProfileAdjustButton(sheetContent, "Interface\\Buttons\\UI-MinusButton-Up", "Remove Attribute")
    removeAttributeButton:SetPoint("RIGHT", attributesTitle, "LEFT", -10, 0)
    removeAttributeButton:Show()
    table.insert(panel.EditableControls, removeAttributeButton)

    local addAttributeButton = CreateProfileAdjustButton(sheetContent, "Interface\\Buttons\\UI-PlusButton-Up", "Add Attribute")
    addAttributeButton:SetPoint("LEFT", attributesTitle, "RIGHT", 10, 0)
    addAttributeButton:Show()
    table.insert(panel.EditableControls, addAttributeButton)

    local function layoutAttributeRows()
        local previous

        for index, row in ipairs(panel.StatRows) do
            row:ClearAllPoints()

            if index == 1 then
                row:SetPoint("TOP", attributesHeaderRow, "BOTTOM", 0, -8)
            else
                row:SetPoint("TOP", previous, "BOTTOM", 0, -5)
            end

            previous = row
        end

        if panel.MetricGroups then
            for _, metricGroup in ipairs(panel.MetricGroups) do
                metricGroup:ClearAllPoints()
                metricGroup:SetPoint("TOP", previous or attributesHeaderRow, "BOTTOM", metricGroup.XOffset or 0, -18)
            end
        end

        if panel.AffectSection then
            panel.AffectSection:ClearAllPoints()
            panel.AffectSection:SetPoint("TOP", previous or attributesHeaderRow, "BOTTOM", 0, -92)
        end

        local bottomY = 560 + (#panel.StatRows * 29)
        sheetContent:SetHeight(math.max(720, bottomY))
    end

    function panel:AddAttributeRow(name, value)
        local row = CreateFrame("Frame", nil, sheetContent)
        row:SetSize(ATTRIBUTE_ROW_WIDTH, 24)

        local statName = CreateTextInputBox(row, 118, 22, 24, false)
        statName:SetPoint("LEFT", row, "LEFT", 0, 0)
        statName:SetTextInsets(4, 0, 0, 0)
        statName:SetText(name or "")
        SetInputPlaceholder(statName, "Attribute")
        statName:SetScript("OnTextChanged", function()
            DiceSim:RefreshSheetMath()
        end)

        local input = CreateInputBox(row, 72, 22)
        input:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        input:SetText(tostring(value or CHARACTER_DEFAULT_STAT))
        SetInputPlaceholder(input, tostring(CHARACTER_DEFAULT_STAT))
        input:SetScript("OnTextChanged", function()
            DiceSim:RefreshSheetMath()
        end)
        input:SetScript("OnEditFocusLost", function(self)
            local statValue = Clamp(tonumber(self:GetText()) or CHARACTER_DEFAULT_STAT, CHARACTER_STAT_MIN, CHARACTER_STAT_MAX)
            self:SetText(tostring(statValue))

            if DiceSim.SheetPanel.PointsSpent and DiceSim.SheetPanel.PointsSpent > DiceSim:GetSheetPointBudget() then
                self:SetText(self.LastValidValue or tostring(CHARACTER_DEFAULT_STAT))
            end
        end)

        row.NameInput = statName
        row.ValueInput = input

        table.insert(panel.StatRows, row)
        table.insert(panel.EditableInputs, statName)
        table.insert(panel.EditableInputs, input)

        layoutAttributeRows()
        DiceSim:RefreshSheetMath()

        return row
    end

    function panel:RemoveAttributeRow()
        local row = table.remove(panel.StatRows)
        if row then
            row:Hide()
            layoutAttributeRows()
            DiceSim:RefreshSheetMath()
        end
    end

    function panel:ClearAttributeRows()
        for _, row in ipairs(panel.StatRows or {}) do
            row:Hide()
        end

        panel.StatRows = {}
        layoutAttributeRows()
    end

    addAttributeButton:SetScript("OnClick", function()
        if self:CanEditSheet(panel.Unit or "player") then
            panel:AddAttributeRow("Attribute", CHARACTER_DEFAULT_STAT)
            self:SetSheetEditable(true)
        end
    end)

    removeAttributeButton:SetScript("OnClick", function()
        if self:CanEditSheet(panel.Unit or "player") then
            panel:RemoveAttributeRow()
        end
    end)

    for _, stat in ipairs(CHARACTER_STATS) do
        panel:AddAttributeRow(stat, CHARACTER_DEFAULT_STAT)
    end

    panel.MetricCounters = {}
    panel.MetricGroups = {}

    local function createSheetMetric(metric, labelText, icon, xOffset)
        local group = CreateFrame("Frame", nil, sheetContent)
        group:SetSize(METRIC_WIDTH, 62)
        group.XOffset = xOffset
        group:SetPoint("TOP", attributesHeaderRow, "BOTTOM", xOffset, -190)

        local header = CreateLabel(group, labelText)
        header:SetPoint("TOP", group, "TOP", 0, 0)
        header:SetWidth(METRIC_WIDTH)
        header:SetJustifyH("CENTER")

        local minus = CreateProfileAdjustButton(group, "Interface\\Buttons\\UI-MinusButton-Up", "Decrease " .. labelText)
        minus:SetPoint("LEFT", group, "LEFT", 0, -12)
        minus:Show()

        local counter = CreateFrame("Frame", nil, group)
        counter:SetSize(54, 30)
        counter:SetPoint("CENTER", group, "CENTER", 0, -10)
        local defaultValue, defaultMax = self:GetDefaultSheetMetric(metric)
        counter.Value = defaultValue
        counter.Max = defaultMax

        local counterInput = CreateInputBox(counter, 54, 20)
        counterInput:SetPoint("CENTER", counter, "CENTER", 0, 0)
        counterInput:SetNumeric(false)
        counterInput:SetMaxLetters(7)
        counterInput:SetText(counter.Value .. "/" .. counter.Max)
        counterInput:SetScript("OnTextChanged", function(input)
            local currentText, maxText = string.match(input:GetText() or "", "^%s*(%-?%d+)%s*/%s*(%d+)%s*$")
            local maximum = Clamp(math.floor(tonumber(maxText) or counter.Max or 100), 0, 999)
            counter.Value = maximum > 0 and Clamp(math.floor(tonumber(currentText or input:GetText()) or 0), 0, maximum) or 0
            counter.Max = maximum
        end)
        counterInput:SetScript("OnEditFocusLost", function(input)
            self:SetSheetMetricValue(metric, input:GetText())
        end)
        counter.Input = counterInput

        local plus = CreateProfileAdjustButton(group, "Interface\\Buttons\\UI-PlusButton-Up", "Increase " .. labelText)
        plus:SetPoint("RIGHT", group, "RIGHT", 0, -12)
        plus:Show()

        minus:SetScript("OnClick", function()
            self:AdjustSheetMetric(metric, -1)
        end)

        plus:SetScript("OnClick", function()
            self:AdjustSheetMetric(metric, 1)
        end)

        panel.MetricCounters[metric] = counter
        table.insert(panel.MetricGroups, group)
        table.insert(panel.EditableInputs, counterInput)
        table.insert(panel.EditableControls, minus)
        table.insert(panel.EditableControls, plus)

        return counter
    end

    panel.HPCounter = createSheetMetric("hp", "HP", "Interface\\Icons\\Spell_Holy_BlessingOfStamina", firstMetricX)
    panel.EnergyCounter = createSheetMetric("energy", "Energy", "Interface\\Icons\\Spell_Nature_Lightning", 0)
    panel.ArmorCounter = createSheetMetric("armor", "Armor", "Interface\\Icons\\INV_Shield_06", -firstMetricX)

    local affectSection = CreateFrame("Frame", nil, sheetContent)
    affectSection:SetSize(320, 112)
    panel.AffectSection = affectSection

    local function createSheetAffectRow(labelText, anchor, affectType)
        local label = CreateLabel(affectSection, labelText)
        if anchor then
            label:SetPoint("TOP", anchor, "BOTTOM", 0, -8)
        else
            label:SetPoint("TOP", affectSection, "TOP", 0, 0)
        end
        label:SetWidth(320)
        label:SetJustifyH("CENTER")

        local row = CreateFrame("Frame", nil, affectSection)
        row:SetSize(320, 42)
        row:SetPoint("TOP", label, "BOTTOM", 0, -4)

        local minus = CreateTrayButton(row, nil, "Interface\\Buttons\\UI-MinusButton-Up", "Remove " .. labelText)
        minus:SetPoint("LEFT", row, "LEFT", 0, 0)
        minus:SetScript("OnClick", function()
            self:SetAffectRemoveMode(affectType == "debuff" and panel.DebuffStrip or panel.BuffStrip, minus)
        end)

        local strip = CreateHorizontalIconStrip(row)
        strip:SetSize(236, 42)
        strip.IconSize = 30
        strip.HideIconBackdrop = true
        strip.OwnerContext = panel
        strip:SetPoint("CENTER", row, "CENTER", 0, 0)

        local plus = CreateTrayButton(row, nil, "Interface\\Buttons\\UI-PlusButton-Up", "Add " .. labelText)
        plus:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        plus:SetScript("OnClick", function()
            self:OpenBuffDebuffPanel(panel, affectType)
        end)

        table.insert(panel.EditableControls, minus)
        table.insert(panel.EditableControls, plus)

        return row, strip
    end

    local buffRow, buffStrip = createSheetAffectRow("Buffs", nil, "buff")
    panel.BuffStrip = buffStrip
    panel.EditBuffStrip = buffStrip

    local _, debuffStrip = createSheetAffectRow("Debuffs", buffRow, "debuff")
    panel.DebuffStrip = debuffStrip
    panel.EditDebuffStrip = debuffStrip

    layoutAttributeRows()

    self.SheetPanel = panel
    self:LoadCurrentSheetData()
    self:RefreshSheetMath()
    self:RefreshSheetSystemStatus()
    self:SetSheetEditable(self:CanEditSheet("player"))

    return panel
end
