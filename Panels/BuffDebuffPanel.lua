local DiceSim = _G.DiceSim

local DESCRIPTION_WORD_LIMIT = 300

local function LimitInputWords(input, limit)
    input:HookScript("OnTextChanged", function(self)
        if self.IsLimitingWords then
            return
        end

        local text = self:GetText() or ""
        local count = 0
        local cutoff

        for _, finish in text:gmatch("()%S+()") do
            count = count + 1
            if count > limit then
                cutoff = finish
                break
            end
        end

        if cutoff then
            self.IsLimitingWords = true
            self:SetText(text:sub(1, cutoff - 1):gsub("%s+$", ""))
            self:SetCursorPosition(#self:GetText())
            self.IsLimitingWords = false
        end
    end)
end

function DiceSim:CreateBuffDebuffPanel(parent)
    local panel = CreatePanel(parent, "DiceSimBuffDebuffPanel", 390, 370)
    panel.TutorialKey = "buffDebuff"
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local closeButton = CreateTrayButton(panel, "DiceSimBuffDebuffPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Add Buff/Debuff")
    panel.Title = title

    panel.SelectedIcon = FALLBACK_AFFECT_ICON_OPTIONS[1].icon

    local iconLabel = CreateLabel(panel, "Portrait")
    iconLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 42, -58)
    panel.IconLabel = iconLabel

    local iconButton = CreateFrame("Button", nil, panel)
    iconButton:SetPoint("TOP", iconLabel, "BOTTOM", 0, -6)
    iconButton:SetSize(64, 64)
    panel.IconButton = iconButton

    local iconPreview = iconButton:CreateTexture(nil, "ARTWORK")
    iconPreview:SetSize(44, 44)
    iconPreview:SetPoint("CENTER")
    iconPreview:SetTexture(panel.SelectedIcon)
    panel.IconPreview = iconPreview

    local iconRing = iconButton:CreateTexture(nil, "OVERLAY")
    iconRing:SetAllPoints()
    self:ApplyTextureOrAtlas(iconRing, "GarrMission_PortraitRing_Empty")
    panel.IconRing = iconRing

    local iconGlow = iconButton:CreateTexture(nil, "HIGHLIGHT")
    iconGlow:SetAllPoints()
    self:ApplyTextureOrAtlas(iconGlow, "GarrMission_PortraitRing_Empty")
    iconGlow:SetBlendMode("ADD")
    iconGlow:SetVertexColor(1.0, 0.74, 0.22, 0.9)
    iconButton:SetHighlightTexture(iconGlow, "ADD")

    iconButton:SetScript("OnClick", function()
        self:OpenIconPicker("Choose Buff Icon", function(icon)
            panel.SelectedIcon = icon
            panel.IconPreview:SetTexture(icon)
            panel.IconButton.SelectedIcon = icon
        end)
    end)

    local nameLabel = CreateLabel(panel, "Name")
    nameLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 206, -62)

    local nameInput = CreateTextInputBox(panel, 166, 32, 36, false)
    nameInput:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -6)
    nameInput:SetText("")
    SetInputPlaceholder(nameInput, "Buff name")
    panel.NameInput = nameInput

    local detailsInput = CreateTextInputBox(panel, 354, 86, 2400, true)
    detailsInput:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -150)
    detailsInput:SetWidth(354)
    detailsInput:SetHeight(86)
    detailsInput:SetTextInsets(8, 8, 8, 8)
    detailsInput:SetJustifyH("LEFT")
    detailsInput:SetJustifyV("TOP")
    detailsInput:SetText("")
    SetInputPlaceholder(detailsInput, "Description")
    if detailsInput.Placeholder then
        detailsInput.Placeholder:ClearAllPoints()
        detailsInput.Placeholder:SetPoint("TOPLEFT", detailsInput, "TOPLEFT", 8, -8)
        detailsInput.Placeholder:SetPoint("RIGHT", detailsInput, "RIGHT", -8, 0)
    end
    detailsInput:HookScript("OnTextChanged", function(self)
        self:SetHeight(86)
    end)
    LimitInputWords(detailsInput, DESCRIPTION_WORD_LIMIT)
    panel.DetailsInput = detailsInput

    local affects = CreateDropdownField(panel, "Applies to:", self:GetAffectAppliesOptions(), function(value, option)
        local actionData = option and option.actionData
        panel.AppliesTo = actionData and actionData.label or value
    end)
    affects:SetPoint("TOPLEFT", detailsInput, "BOTTOMLEFT", 0, -12)
    affects:SetWidth(166)
    affects.Value = nil
    affects.RefreshOptions = function()
        return DiceSim:GetAffectAppliesOptions()
    end
    panel.AppliesToField = affects

    local modifiersLabel = CreateLabel(panel, "Modifiers")
    modifiersLabel:SetPoint("TOPLEFT", affects, "TOPLEFT", 188, 0)

    local modifiers = CreateInputBox(panel, 166, 32)
    modifiers:SetPoint("TOPLEFT", modifiersLabel, "BOTTOMLEFT", 0, -6)
    modifiers:SetNumeric(false)
    modifiers:SetText("0")
    SetInputPlaceholder(modifiers, "+/- modifier")
    panel.ModifierInput = modifiers

    local divider = CreateDivider(panel)
    divider:SetPoint("TOPLEFT", affects, "BOTTOMLEFT", 0, -22)
    divider:SetPoint("TOPRIGHT", modifiers, "BOTTOMRIGHT", 0, -22)

    local addButton = CreatePanelButton(panel, "ADD")
    addButton:SetPoint("TOP", divider, "BOTTOM", 0, -18)
    addButton:SetSize(82, 34)
    addButton:SetHeight(34)
    FitPanelButtonLabel(addButton)
    addButton:SetScript("OnClick", function()
        local context = panel.Context
        local affectType = panel.AffectType or "buff"

        DiceSim:AddAffectToContext(context, affectType, {
            type = affectType,
            icon = panel.SelectedIcon,
            name = panel.NameInput and panel.NameInput:GetText() or "",
            details = panel.DetailsInput and panel.DetailsInput:GetText() or "",
            appliesTo = panel.AppliesTo or (panel.AppliesToField and panel.AppliesToField.Value) or nil,
            modifier = panel.ModifierInput and (tonumber(panel.ModifierInput:GetText()) or 0) or 0,
        })
        panel:Hide()
    end)

    self.BuffDebuffPanel = panel
    panel:Hide()
    return panel
end
