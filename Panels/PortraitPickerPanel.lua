local DiceSim = _G.DiceSim

local PAGE_SIZE = 40
local ICON_SIZE = 42
local ICON_GAP = 6
local COLUMN_COUNT = 8
local ROW_COUNT = 5

local function FindPortraitIndex(startPath)
    if not startPath then
        return 1
    end

    if type(startPath) ~= "string" then
        return 1
    end

    local normalized = startPath:lower():gsub("/", "\\")

    for index, portrait in ipairs(DiceSim.GARRISON_PORTRAITS or {}) do
        if portrait.path:lower() == normalized then
            return index
        end
    end

    return 1
end

function DiceSim:CreatePortraitPickerPanel(parent)
    local panel = CreatePanel(parent, "DiceSimPortraitPickerPanel", 430, 430)
    panel.TutorialKey = "portraitPicker"
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    panel.StartIndex = 1

    local closeButton = CreateTrayButton(panel, "DiceSimPortraitPickerCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -18)
    title:SetText("Choose Portrait")

    local idInput = CreateInputBox(panel, 92, 28)
    idInput:SetPoint("TOP", panel, "TOP", -128, -56)
    idInput:SetNumeric(true)
    idInput:SetMaxLetters(4)
    idInput:SetText("1")
    panel.IdInput = idInput

    local jumpButton = CreatePanelButton(panel, "Jump")
    jumpButton:SetSize(78, 28)
    jumpButton:SetPoint("LEFT", idInput, "RIGHT", 8, 0)
    FitPanelButtonLabel(jumpButton)

    local prevButton = CreatePanelButton(panel, "Previous")
    prevButton:SetSize(94, 28)
    prevButton:SetPoint("LEFT", jumpButton, "RIGHT", 12, 0)
    FitPanelButtonLabel(prevButton)

    local nextButton = CreatePanelButton(panel, "Next")
    nextButton:SetSize(76, 28)
    nextButton:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
    FitPanelButtonLabel(nextButton)

    local pageText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageText:SetPoint("TOP", panel, "TOP", 0, -92)
    pageText:SetWidth(380)
    pageText:SetJustifyH("CENTER")
    panel.PageText = pageText

    local grid = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    grid:SetPoint("TOP", pageText, "BOTTOM", 0, -10)
    grid:SetSize((ICON_SIZE * COLUMN_COUNT) + (ICON_GAP * (COLUMN_COUNT - 1)) + 16, (ICON_SIZE * ROW_COUNT) + (ICON_GAP * (ROW_COUNT - 1)) + 16)
    DiceSim:ApplyBackdrop(grid, DiceSim.Theme.colors.insetBg, DiceSim.Theme.colors.insetBorder, 1)
    panel.Grid = grid
    panel.Buttons = {}

    local function refreshPage()
        local portraits = DiceSim.GARRISON_PORTRAITS or {}
        local total = #portraits
        local startIndex = math.max(1, tonumber(panel.StartIndex) or 1)

        if total > 0 then
            startIndex = math.min(startIndex, total)
        end

        panel.StartIndex = startIndex
        panel.IdInput:SetText(tostring(startIndex))

        if total == 0 then
            panel.PageText:SetText("No garrison portraits loaded")
        else
            panel.PageText:SetText(startIndex .. " - " .. math.min(startIndex + PAGE_SIZE - 1, total) .. " of " .. total)
        end

        for index = 1, PAGE_SIZE do
            local button = panel.Buttons[index]
            if not button then
                button = CreateFrame("Button", nil, grid, "BackdropTemplate")
                button:SetSize(ICON_SIZE, ICON_SIZE)
                DiceSim:ApplyBackdrop(button, DiceSim.Theme.colors.controlBg, DiceSim.Theme.colors.controlBorder, 1)

                local texture = button:CreateTexture(nil, "ARTWORK")
                texture:SetPoint("CENTER")
                texture:SetSize(ICON_SIZE - 6, ICON_SIZE - 6)
                button.Icon = texture

                button:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorderHover))
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:SetText(self.PortraitLabel or "Enemy Portrait")
                    GameTooltip:Show()
                end)

                button:SetScript("OnLeave", function(self)
                    self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorder))
                    GameTooltip:Hide()
                end)

                button:SetScript("OnClick", function(self)
                    if panel.OnSelect then
                        panel.OnSelect(self.PortraitPath, self.PortraitId)
                    end
                    panel:Hide()
                end)

                panel.Buttons[index] = button
            end

            local column = (index - 1) % COLUMN_COUNT
            local row = math.floor((index - 1) / COLUMN_COUNT)
            local portrait = portraits[startIndex + index - 1]

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", grid, "TOPLEFT", 8 + (column * (ICON_SIZE + ICON_GAP)), -8 - (row * (ICON_SIZE + ICON_GAP)))

            if portrait then
                button.PortraitId = portrait.id
                button.PortraitPath = portrait.path
                button.PortraitLabel = portrait.label or portrait.path
                button.Icon:SetTexture(portrait.path)
                button:Enable()
                button:SetAlpha(1)
                button:Show()
            else
                button.PortraitId = nil
                button.PortraitPath = nil
                button.PortraitLabel = nil
                button.Icon:SetTexture(nil)
                button:Disable()
                button:SetAlpha(0)
                button:Hide()
            end
        end
    end

    panel.RefreshPage = refreshPage

    jumpButton:SetScript("OnClick", function()
        panel.StartIndex = tonumber(idInput:GetText()) or 1
        refreshPage()
    end)

    idInput:SetScript("OnEnterPressed", function(self)
        panel.StartIndex = tonumber(self:GetText()) or 1
        self:ClearFocus()
        refreshPage()
    end)

    prevButton:SetScript("OnClick", function()
        panel.StartIndex = math.max(1, (tonumber(panel.StartIndex) or 1) - PAGE_SIZE)
        refreshPage()
    end)

    nextButton:SetScript("OnClick", function()
        panel.StartIndex = (tonumber(panel.StartIndex) or 1) + PAGE_SIZE
        refreshPage()
    end)

    panel:SetScript("OnShow", function(self)
        self:RefreshPage()
        DiceSim:BringWindowToFront(self)
    end)

    self.PortraitPickerPanel = panel
    return panel
end

function DiceSim:OpenPortraitPicker(onSelect, startPath)
    if not self.PortraitPickerPanel then
        self:CreatePortraitPickerPanel(self.Frame)
    end

    if startPath then
        self.PortraitPickerPanel.StartIndex = FindPortraitIndex(startPath)
    end

    self.PortraitPickerPanel.OnSelect = onSelect
    self.PortraitPickerPanel:Show()
end
