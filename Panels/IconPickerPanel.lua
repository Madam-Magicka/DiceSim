local DiceSim = _G.DiceSim

local ICON_SIZE = 30
local ICON_GAP = 6
local COLUMN_COUNT = 8
local VISIBLE_ROWS = 7
local BUTTON_POOL_SIZE = COLUMN_COUNT * (VISIBLE_ROWS + 2)
local MIN_SEARCH_LENGTH = 2

local function NormalizeSearch(value)
    return string.lower(string.match(value or "", "^%s*(.-)%s*$"))
end

local function IconMatches(option, filter)
    if filter == "" then
        return false
    end

    local keywords = string.lower(tostring(option.keywords or ""))
    local label = string.lower(tostring(option.label or ""))
    local icon = string.lower(tostring(option.icon or option.value or ""))
    return string.find(keywords, filter, 1, true)
        or string.find(label, filter, 1, true)
        or string.find(icon, filter, 1, true)
end

local function SetStatus(panel, text)
    if panel.StatusText then
        panel.StatusText:SetText(text or "")
        panel.StatusText:SetShown(text and text ~= "")
    end
end

function DiceSim:CreateIconPickerPanel(parent)
    local panel = CreatePanel(parent, "DiceSimIconPickerPanel", 344, 382)
    panel.TutorialKey = "iconPicker"
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local closeButton = CreateTrayButton(panel, "DiceSimIconPickerCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -18)
    title:SetText("Choose Icon")
    panel.Title = title

    local search = CreateTextInputBox(panel, 250, 28, 80, false)
    search:SetPoint("TOP", title, "BOTTOM", 0, -12)
    SetInputPlaceholder(search, "Search macro icons")
    panel.SearchInput = search

    local scrollBox = CreateBox(panel, 270)
    scrollBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -86)
    scrollBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 18)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT", -24, 8)
    ApplyScrollBarSkin(scrollFrame)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize((ICON_SIZE + ICON_GAP) * COLUMN_COUNT, 1)
    scrollFrame:SetScrollChild(content)

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetPoint("TOP", content, "TOP", 0, -18)
    status:SetWidth((ICON_SIZE + ICON_GAP) * COLUMN_COUNT)
    status:SetJustifyH("CENTER")
    panel.StatusText = status

    panel.ScrollFrame = scrollFrame
    panel.Content = content
    panel.Buttons = {}
    panel.IconOptions = {}
    panel.FilteredIcons = {}

    local function createIconButton()
        local button = CreateFrame("Button", nil, content, "BackdropTemplate")
        button:SetSize(ICON_SIZE, ICON_SIZE)
        DiceSim:ApplyBackdrop(button, DiceSim.Theme.colors.controlBg, DiceSim.Theme.colors.controlBorder, 1)

        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("CENTER")
        texture:SetSize(ICON_SIZE - 6, ICON_SIZE - 6)
        button.Icon = texture

        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorderHover))
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.IconLabel or tostring(self.IconPath or "Macro Icon"))
            if self.IconPath then
                GameTooltip:AddLine(tostring(self.IconPath), 0.72, 0.72, 0.72)
            end
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorder))
            GameTooltip:Hide()
        end)

        button:SetScript("OnClick", function(self)
            if panel.OnSelect then
                panel.OnSelect(self.IconPath)
            end
            panel:Hide()
        end)

        button:Hide()
        return button
    end

    for index = 1, BUTTON_POOL_SIZE do
        panel.Buttons[index] = createIconButton()
    end

    function panel:FilterIcons()
        local filter = NormalizeSearch(self.SearchInput:GetText())
        self.FilteredIcons = {}

        if #filter < MIN_SEARCH_LENGTH then
            SetStatus(self, "Type at least " .. MIN_SEARCH_LENGTH .. " characters to search macro icons.")
            self.Content:SetHeight(1)
            self.ScrollFrame:SetVerticalScroll(0)
            return
        end

        for _, option in ipairs(self.IconOptions or {}) do
            if IconMatches(option, filter) then
                table.insert(self.FilteredIcons, option)
            end
        end

        if #self.FilteredIcons == 0 then
            SetStatus(self, "No matching macro icons.")
            self.Content:SetHeight(1)
        else
            SetStatus(self, "")
            local rows = math.ceil(#self.FilteredIcons / COLUMN_COUNT)
            self.Content:SetHeight(math.max(1, rows * (ICON_SIZE + ICON_GAP)))
        end

        self.ScrollFrame:SetVerticalScroll(0)
    end

    function panel:RefreshVisibleIcons()
        local filtered = self.FilteredIcons or {}
        local rowHeight = ICON_SIZE + ICON_GAP
        local firstRow = math.max(0, math.floor((self.ScrollFrame:GetVerticalScroll() or 0) / rowHeight))
        local firstIndex = (firstRow * COLUMN_COUNT) + 1

        for poolIndex, button in ipairs(self.Buttons) do
            local iconIndex = firstIndex + poolIndex - 1
            local option = filtered[iconIndex]

            if option then
                local absoluteIndex = iconIndex - 1
                local column = absoluteIndex % COLUMN_COUNT
                local row = math.floor(absoluteIndex / COLUMN_COUNT)

                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.Content, "TOPLEFT", column * rowHeight, -(row * rowHeight))
                button.IconPath = option.icon or option.value
                button.IconLabel = option.label
                DiceSim:ApplyTextureOrAtlas(button.Icon, button.IconPath)
                button:Show()
            else
                button.IconPath = nil
                button.IconLabel = nil
                button.Icon:SetTexture(nil)
                button:Hide()
            end
        end
    end

    function panel:RefreshIcons()
        self:FilterIcons()
        self:RefreshVisibleIcons()
    end

    search:HookScript("OnTextChanged", function()
        panel:RefreshIcons()
    end)

    scrollFrame:HookScript("OnVerticalScroll", function()
        panel:RefreshVisibleIcons()
    end)

    panel:SetScript("OnShow", function(self)
        self.IconOptions = DiceSim:GetMacroIconList()
        self.SearchInput:SetText("")
        self:RefreshIcons()
        DiceSim:BringWindowToFront(self)
    end)

    self.IconPickerPanel = panel
    return panel
end

function DiceSim:OpenIconPicker(title, onSelect)
    if not self.IconPickerPanel then
        self:CreateIconPickerPanel(self.Frame)
    end

    self.IconPickerPanel.Title:SetText(title or "Choose Icon")
    self.IconPickerPanel.OnSelect = onSelect
    self.IconPickerPanel:Show()
end
