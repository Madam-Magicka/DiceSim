local DiceSim = _G.DiceSim

function DiceSim:AddInitiativeEntry(actor, total, roll, modifier)
    self.InitiativeEntries = self.InitiativeEntries or {}
    self.InitiativeEntries[actor] = {
        actor = actor,
        total = total,
        roll = roll,
        modifier = modifier or 0,
    }

    self:RefreshInitiativeList()
    self:SaveSessionSnapshot()
end

function DiceSim:RefreshInitiativeList()
    if not self.InitiativeScrollBox then
        return
    end

    local entries = {}
    for _, entry in pairs(self.InitiativeEntries or {}) do
        table.insert(entries, entry)
    end

    table.sort(entries, function(a, b)
        if a.total == b.total then
            return a.actor < b.actor
        end

        return a.total > b.total
    end)

    local content = self.InitiativeScrollBox.Content
    local rows = self.InitiativeRows or {}
    self.InitiativeRows = rows

    for index, entry in ipairs(entries) do
        local row = rows[index]
        if not row then
            row = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row:SetJustifyH("LEFT")
            rows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -6 - ((index - 1) * 22))
        row:SetWidth(math.max(220, self.InitiativeScrollBox:GetWidth() - 44))
        row:SetText(index .. ". " .. entry.actor .. " - " .. entry.total .. " (" .. entry.roll .. " " .. self:GetSignedNumber(entry.modifier) .. ")")
        row:Show()
    end

    for index = #entries + 1, #rows do
        rows[index]:Hide()
    end

    content:SetSize(1, math.max(1, (#entries * 22) + 12))
end
