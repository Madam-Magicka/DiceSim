-- Add panel layout and behavior.

local DiceSim = _G.DiceSim

function DiceSim:CreateAddPanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimAddPanel", 230, 320)
    panel.TutorialKey = "add"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)

    local closeButton = CreateTrayButton(panel, "DiceSimAddPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 12)
    ApplyScrollBarSkin(scrollFrame)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(188, 430)
    scrollFrame:SetScrollChild(content)
    panel.ScrollFrame = scrollFrame
    panel.Content = content

    local symbols = CreateLabel(content, "Symbols")
    symbols:SetPoint("TOP", content, "TOP", 0, 0)

    local previousMarker
    for index, marker in ipairs(RAID_MARKERS) do
        local button = CreateTrayButton(content, nil, marker.icon, marker.label)
        button:SetScript("OnClick", function()
            self:CreateCanvasSymbol(marker)
        end)

        if index == 1 then
            button:SetPoint("TOPLEFT", content, "TOPLEFT", 15, -28)
        elseif index == 5 then
            button:SetPoint("TOPLEFT", content, "TOPLEFT", 15, -68)
        else
            button:SetPoint("LEFT", previousMarker, "RIGHT", 6, 0)
        end

        previousMarker = button
    end

    local symbolsDivider = CreateDivider(content)
    symbolsDivider:SetPoint("TOP", content, "TOP", 0, -106)

    local numbersLabel = CreateLabel(content, "Numbers")
    numbersLabel:SetPoint("TOP", symbolsDivider, "BOTTOM", 0, -10)

    local numberButtonSize = self.Theme.sizes.iconButton
    local numberGap = 8
    local numberColumns = 3
    local numberRowWidth = (numberButtonSize * numberColumns) + (numberGap * (numberColumns - 1))
    local numberStartX = -numberRowWidth / 2

    for index, marker in ipairs(NUMBER_SYMBOLS) do
        local button = CreateTrayButton(content, nil, marker.icon, marker.label)
        button:SetScript("OnClick", function()
            self:CreateCanvasSymbol(marker)
        end)

        local column = (index - 1) % numberColumns
        local row = math.floor((index - 1) / numberColumns)
        button:SetPoint("TOPLEFT", numbersLabel, "BOTTOM", numberStartX + (column * (numberButtonSize + numberGap)), -8 - (row * (numberButtonSize + numberGap)))
    end

    local numbersDivider = CreateDivider(content)
    numbersDivider:SetPoint("TOP", numbersLabel, "BOTTOM", 0, -132)

    local panelsLabel = CreateLabel(content, "Panels")
    panelsLabel:SetPoint("TOP", numbersDivider, "BOTTOM", 0, -10)

    local enemy = CreatePanelButton(content, "Add Enemy Panel")
    enemy:SetSize(180, 24)
    enemy:SetPoint("TOP", panelsLabel, "BOTTOM", 0, -8)
    FitPanelButtonLabel(enemy)
    enemy:SetScript("OnClick", function()
        self:CreateCanvasPanel("Enemy")
    end)

    local friendly = CreatePanelButton(content, "Add Friendly Panel")
    friendly:SetSize(180, 24)
    friendly:SetPoint("TOP", enemy, "BOTTOM", 0, -6)
    FitPanelButtonLabel(friendly)
    friendly:SetScript("OnClick", function()
        self:CreateCanvasPanel("Friendly")
    end)

    local neutral = CreatePanelButton(content, "Add Neutral Panel")
    neutral:SetSize(180, 24)
    neutral:SetPoint("TOP", friendly, "BOTTOM", 0, -6)
    FitPanelButtonLabel(neutral)
    neutral:SetScript("OnClick", function()
        self:CreateCanvasPanel("Neutral")
    end)

    local panelsDivider = CreateDivider(content)
    panelsDivider:SetPoint("TOP", neutral, "BOTTOM", 0, -12)

    local backgroundsLabel = CreateLabel(content, "Backgrounds")
    backgroundsLabel:SetPoint("TOP", panelsDivider, "BOTTOM", 0, -10)

    local backgrounds = CreateDropdownField(content, "Background", CANVAS_BACKGROUND_OPTIONS, function(value, option)
        self:SetCanvasBackground(value, option and option.label or "Default")
    end)
    backgrounds:SetSize(180, 30)
    backgrounds:SetPoint("TOP", backgroundsLabel, "BOTTOM", 0, -8)
    backgrounds.Value = self.CanvasBackground or "default"
    backgrounds.Label:SetText(self.CanvasBackgroundLabel or "Default")
    panel.BackgroundDropdown = backgrounds

    self.AddPanel = panel
    return panel
end
