local DiceSim = _G.DiceSim

function DiceSim:GetEventTimestamp()
    return date and date("%H:%M:%S") or "00:00:00"
end

function DiceSim:CreateEventLogPanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimEventLogPanel", 380, 360)
    panel.TutorialKey = "eventLog"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)

    local closeButton = CreateTrayButton(panel, "DiceSimEventLogPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Event Log")

    local scrollBox = CreateScrollBox(panel)
    scrollBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -54)
    scrollBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
    self.EventLogScrollBox = scrollBox

    self.EventLogPanel = panel
    return panel
end

function DiceSim:UpdateEventLogUnreadMarker()
    if self.EventLogUnreadMarker then
        self.EventLogUnreadMarker:SetShown(self.EventLogUnread and true or false)
    end
end

function DiceSim:RefreshEventLog()
    if not self.EventLogScrollBox then
        return
    end

    local entries = self.EventLogEntries or {}
    local content = self.EventLogScrollBox.Content
    local scrollFrame = self.EventLogScrollBox.ScrollFrame
    local rows = self.EventLogRows or {}
    self.EventLogRows = rows

    local availableWidth = math.max(220, (self.EventLogScrollBox:GetWidth() or 300) - 44)
    local offsetY = -6

    for index, entry in ipairs(entries) do
        local timeText = entry and entry.time or "00:00:00"
        local entryText = entry and entry.text or ""

        local row = rows[index]
        if not row then
            row = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row:SetJustifyH("LEFT")
            row:SetJustifyV("TOP")
            row:SetNonSpaceWrap(true)
            rows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, offsetY)
        row:SetWidth(availableWidth)
        row:SetText("|cffaaa0c8[" .. tostring(timeText) .. "]|r " .. tostring(entryText))
        row:Show()

        offsetY = offsetY - math.max(24, row:GetStringHeight() + 8)
    end

    for index = #entries + 1, #rows do
        rows[index]:Hide()
    end

    local height = math.max(1, -offsetY + 6)
    content:SetSize(availableWidth, height)
    scrollFrame:SetVerticalScroll(math.max(0, height - scrollFrame:GetHeight()))
end

function DiceSim:AddEventLogEntry(text)
    text = tostring(text or "")
    if text == "" then
        return
    end

    self.EventLogEntries = self.EventLogEntries or {}
    table.insert(self.EventLogEntries, {
        time = self:GetEventTimestamp(),
        text = text,
    })

    self:RefreshEventLog()

    if not self.EventLogPanel or not self.EventLogPanel:IsShown() then
        self.EventLogUnread = true
        self:UpdateEventLogUnreadMarker()
    end

    self:SaveSessionSnapshot()
end

function DiceSim:RecordRoll(text, showInDicePanel)
    self:AddEventLogEntry(text)

    if showInDicePanel then
        self:SetDiceOutput(text)
    end

    print(text)
end
