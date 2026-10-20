local DiceSim = _G.DiceSim

local ANNOUNCEMENT_POPUP_WIDTH = 560
local ANNOUNCEMENT_POPUP_HEIGHT = 190
local ANNOUNCEMENT_HOLD_SECONDS = 30

function DiceSim:ShowAnnouncementPopup(text)
    text = string.match(text or "", "^%s*(.-)%s*$")
    if text == "" then
        return
    end

    local popup = self.AnnouncementPopup
    if not popup then
        popup = CreateFrame("Frame", "DiceSimAnnouncementPopup", UIParent)
        popup:SetSize(ANNOUNCEMENT_POPUP_WIDTH, ANNOUNCEMENT_POPUP_HEIGHT)
        popup:SetPoint("TOP", UIParent, "TOP", 0, -150)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:EnableMouse(true)
        popup:Hide()

        local parchment = popup:CreateTexture(nil, "BACKGROUND")
        parchment:SetAllPoints()
        self:ApplyTextureOrAtlas(parchment, "adventureguide-pane-small")
        popup.Parchment = parchment

        local closeButton = CreateFrame("Button", nil, popup)
        closeButton:SetSize(34, 34)
        closeButton:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -18, -16)
        local closeIcon = closeButton:CreateTexture(nil, "ARTWORK")
        closeIcon:SetAllPoints()
        self:ApplyTextureOrAtlas(closeIcon, "adventureguide-redx")
        closeButton:SetScript("OnClick", function()
            if popup.Fade then
                popup.Fade:Stop()
            end
            popup:Hide()
        end)
        popup.CloseButton = closeButton

        local label = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("CENTER", popup, "CENTER", 0, -8)
        label:SetWidth(ANNOUNCEMENT_POPUP_WIDTH - 126)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetTextColor(0.08, 0.055, 0.035, 1)
        label:SetShadowColor(1, 0.88, 0.54, 0.45)
        label:SetShadowOffset(1, -1)
        popup.Label = label

        local fade = popup:CreateAnimationGroup()
        local hold = fade:CreateAnimation("Alpha")
        hold:SetFromAlpha(1)
        hold:SetToAlpha(1)
        hold:SetDuration(ANNOUNCEMENT_HOLD_SECONDS)
        hold:SetOrder(1)

        local out = fade:CreateAnimation("Alpha")
        out:SetFromAlpha(1)
        out:SetToAlpha(0)
        out:SetDuration(1.4)
        out:SetSmoothing("OUT")
        out:SetOrder(2)

        fade:SetScript("OnFinished", function()
            popup:Hide()
        end)
        popup.Fade = fade

        self.AnnouncementPopup = popup
    end

    popup.Fade:Stop()
    popup:SetAlpha(1)
    popup.Label:SetText(text)
    popup:Show()
    popup.Fade:Play()
end

function DiceSim:CreateDMPanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimDMPanel", 390, 450)
    panel.TutorialKey = "dm"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)

    local closeButton = CreateTrayButton(panel, "DiceSimDMPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("DM Panel")

    local toolRow = CreateFrame("Frame", nil, panel)
    toolRow:SetSize(172, 40)
    toolRow:SetPoint("TOP", title, "BOTTOM", 0, -18)

    local announce = CreateTrayButton(toolRow, "DiceSimRaidAnnounceButton", self.Theme.textures.raidAnnounce, "Raid Announce")
    announce:SetPoint("LEFT", toolRow, "LEFT", 0, 0)
    announce:SetScript("OnClick", function()
        panel.AnnounceInput:SetShown(not panel.AnnounceInput:IsShown())
        if panel.AnnounceInput:IsShown() then
            panel.AnnounceInput:SetFocus()
        end
    end)

    local announceInput = CreateTextInputBox(panel, 340, 32, 220, false)
    announceInput:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -104)
    announceInput:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    SetInputPlaceholder(announceInput, "Raid warning text")
    announceInput:SetScript("OnEnterPressed", function(self)
        DiceSim:AnnounceRaidWarning(self:GetText())
        self:SetText("")
        self:ClearFocus()
        self:Hide()
    end)
    announceInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:Hide()
    end)
    announceInput:Hide()
    panel.AnnounceInput = announceInput

    local player = CreateTrayButton(toolRow, "DiceSimDMRosterButton", self.Theme.textures.roster, "Add/Remove Player")
    player:SetPoint("LEFT", announce, "RIGHT", 6, 0)
    player:EnableMouse(true)
    player:SetScript("OnClick", function()
        self:ToggleDMRosterMenu(player, "player")
    end)

    local rank = CreateTrayButton(toolRow, "DiceSimDMAssistantButton", self.Theme.textures.promote, "Promote/Demote")
    rank:SetPoint("LEFT", player, "RIGHT", 6, 0)
    rank:EnableMouse(true)
    rank:SetScript("OnClick", function()
        self:ToggleDMRosterMenu(rank, "assistant")
    end)

    local rounds = CreateTrayButton(toolRow, "DiceSimDMRoundsButton", self.Theme.textures.rounds, "Rounds")
    rounds:SetPoint("LEFT", rank, "RIGHT", 6, 0)
    rounds:SetSize(40, 40)
    rounds:SetIconSize(31)
    self:ApplyTextureOrAtlas(rounds.Icon, self.Theme.textures.rounds)
    rounds:SetScript("OnClick", function()
        self:ToggleRoundsTracker()
    end)

    local divider = CreateDivider(panel)
    divider:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -150)
    divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -150)

    local sectionTitle = CreateLabel(panel, "Initiative List")
    sectionTitle:SetFontObject(GameFontNormalLarge)
    sectionTitle:SetPoint("TOP", divider, "BOTTOM", 0, -14)
    sectionTitle:SetWidth(280)
    sectionTitle:SetJustifyH("CENTER")

    local scrollBox = CreateScrollBox(panel)
    scrollBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -188)
    scrollBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 18)

    self.InitiativeScrollBox = scrollBox
    self.DMPanel = panel
    self:RefreshInitiativeList()
    return panel
end

function DiceSim:GetGroupMemberOptions()
    local options = {}
    local seen = {}

    local function addUnit(unit)
        if UnitExists and not UnitExists(unit) then
            return
        end

        local name = UnitName and UnitName(unit) or unit
        if not name or seen[name] then
            return
        end

        seen[name] = true
        table.insert(options, { label = name, value = name, unit = unit })
    end

    addUnit("player")

    if IsInRaid and IsInRaid() then
        for index = 1, 40 do
            addUnit("raid" .. index)
        end
    elseif IsInGroup and IsInGroup() then
        for index = 1, 4 do
            addUnit("party" .. index)
        end
    end

    return options
end

function DiceSim:GetSessionMemberKey(name)
    name = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey(name) or name
    return name
end

local function GetShortSessionName(name)
    name = tostring(name or "")
    return string.lower(string.match(name, "^[^-]+") or name)
end

function DiceSim:IsSelfSessionMember(name)
    local key = self:GetSessionMemberKey(name)
    local playerKey = self:GetSessionMemberKey("player")
    local playerName = UnitName and UnitName("player") or self.PlayerKey or "player"

    local keyShort = GetShortSessionName(key)
    return keyShort ~= "" and (
        keyShort == GetShortSessionName(playerKey)
        or keyShort == GetShortSessionName(playerName)
    )
end

function DiceSim:InitializeSessionRosterFromGroup()
    self.SessionPlayers = self.SessionPlayers or {}

    for _, member in ipairs(self:GetGroupMemberOptions()) do
        local key = self:GetSessionMemberKey(member.value)
        self.SessionPlayers[key] = true
    end

    self.SessionRosterLocked = true
end

function DiceSim:ToggleSessionMember(name)
    local key = self:GetSessionMemberKey(name)
    self.SessionHiddenPlayers = self.SessionHiddenPlayers or {}
    self.SessionHiddenPlayers[key] = not self.SessionHiddenPlayers[key] or nil
    self:AddEventLogEntry((self.SessionHiddenPlayers[key] and "Hid " or "Showed ") .. key .. " on the character frame.")
    if self.ActiveSessionId then
        self:SendSessionMessage("HIDE:" .. self.ActiveSessionId .. ":" .. key .. ":" .. (self.SessionHiddenPlayers[key] and "1" or "0"))
    end
    self:SaveSessionSnapshot()
    if self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end
end

function DiceSim:InviteSessionMember(name)
    if not self.ActiveSessionId or self.SessionMode ~= "host" then
        print("DiceSim: host a session before inviting players.")
        return
    end

    local key = self:GetSessionMemberKey(name)
    if self:IsSelfSessionMember(key) then
        print("DiceSim: you are already in your own session.")
        return
    end
    self.SessionPlayers = self.SessionPlayers or {}
    if not self.SessionRosterLocked then
        self:InitializeSessionRosterFromGroup()
    end
    self.SessionRosterLocked = true
    self.SessionPendingInvites = self.SessionPendingInvites or {}
    self.SessionPendingInvites[key] = true
    self:SendSessionMessage("INVITE:" .. self.ActiveSessionId .. ":" .. key)
    self:SendSessionMessageTo("INVITE:" .. self.ActiveSessionId .. ":" .. key, key)
    self:AddEventLogEntry("Invited " .. key .. " to the session.")
    self:RefreshSessionPanel()
end

function DiceSim:KickSessionMember(name)
    if not self.ActiveSessionId or self.SessionMode ~= "host" then
        print("DiceSim: only the host can kick session members.")
        return
    end

    if not self.SessionRosterLocked then
        self:InitializeSessionRosterFromGroup()
    end

    local key = self:GetSessionMemberKey(name)
    if self:IsSelfSessionMember(key) then
        print("DiceSim: you cannot kick yourself from your own session.")
        return
    end
    self.SessionPlayers = self.SessionPlayers or {}
    self.SessionPlayers[key] = nil
    self.SessionAssistants = self.SessionAssistants or {}
    self.SessionAssistants[key] = nil
    self.SessionPendingInvites = self.SessionPendingInvites or {}
    self.SessionPendingInvites[key] = nil
    self:SendSessionMessage("KICK:" .. self.ActiveSessionId .. ":" .. key)
    self:SendSessionMessageTo("KICK:" .. self.ActiveSessionId .. ":" .. key, key)
    self:AddEventLogEntry("Kicked " .. key .. " from the session.")
    self:SaveSessionSnapshot()
    if self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end
end

function DiceSim:ToggleAssistant(name)
    name = self:GetSessionMemberKey(name)
    if self:IsSelfSessionMember(name) then
        return
    end

    self.SessionAssistants = self.SessionAssistants or {}
    self.SessionAssistants[name] = not self.SessionAssistants[name] or nil
    self:AddEventLogEntry(name .. (self.SessionAssistants[name] and " promoted to DM assistant." or " demoted from DM assistant."))
    self:SaveSessionSnapshot()
    self:RefreshPermissions()
end

function DiceSim:ToggleDMRosterMenu(anchor, mode)
    if self.DMRosterMenu and self.DMRosterMenu:IsShown() and self.DMRosterMenu.Mode == mode then
        self.DMRosterMenu:Hide()
        return
    end

    local menu = self.DMRosterMenu
    if not menu then
        local theme = self.Theme
        menu = CreateFrame("Frame", "DiceSimDMRosterMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        menu:SetBackdropColor(unpack(theme.colors.panelBg))
        menu:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
        menu.Rows = {}
        self.DMRosterMenu = menu
    end

    for _, row in ipairs(menu.Rows) do
        row:Hide()
    end

    local members = {}
    for _, member in ipairs(self:GetGroupMemberOptions()) do
        if mode ~= "assistant" or not self:IsSelfSessionMember(member.value) then
            table.insert(members, member)
        end
    end
    local width = math.max(anchor:GetWidth(), 220)
    menu:SetSize(width, math.max(1, #members) * 28 + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    menu.Mode = mode

    for index, member in ipairs(members) do
        local row = menu.Rows[index]
        if not row then
            local theme = DiceSim.Theme
            row = CreateFrame("Button", nil, menu, "BackdropTemplate")
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            row:SetBackdropColor(unpack(theme.colors.controlBg))
            row:SetBackdropBorderColor(unpack(theme.colors.controlBorder))
            row:SetHeight(26)

            local bullet = row:CreateTexture(nil, "OVERLAY")
            bullet:SetSize(18, 18)
            bullet:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.Bullet = bullet

            local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            label:SetPoint("LEFT", bullet, "RIGHT", 8, 0)
            label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            label:SetJustifyH("LEFT")
            if DiceSim.ApplyFontStringScale then
                DiceSim:ApplyFontStringScale(label)
            end
            row.Label = label
            menu.Rows[index] = row
        end

        local memberKey = self:GetSessionMemberKey(member.value)
        local active = mode == "assistant" and self.SessionAssistants and self.SessionAssistants[memberKey]
            or mode == "player" and not (self.SessionHiddenPlayers and self.SessionHiddenPlayers[memberKey])

        row.Label:SetText(member.label)
        row.Bullet:SetVertexColor(1, 1, 1, 1)
        if active then
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterFriend")
        elseif mode == "assistant" then
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterNeutral")
        else
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterEnemy")
        end
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4 - ((index - 1) * 28))
        row:SetPoint("RIGHT", menu, "RIGHT", -4, 0)
        row:SetScript("OnClick", function()
            if mode == "assistant" then
                DiceSim:ToggleAssistant(member.value)
            else
                DiceSim:ToggleSessionMember(member.value)
            end

            DiceSim:ToggleDMRosterMenu(anchor, mode)
            DiceSim:ToggleDMRosterMenu(anchor, mode)
        end)
        row:Show()
    end

    menu:SetFrameLevel((anchor:GetFrameLevel() or 1) + 80)
    menu:Show()
end

function DiceSim:AnnounceRaidWarning(text)
    text = string.match(text or "", "^%s*(.-)%s*$")
    if text == "" then
        return
    end

    self:ShowAnnouncementPopup(text)
    self:SendSessionMessage("ANN:" .. text)

    if SendChatMessage and IsInRaid and IsInRaid() then
        SendChatMessage(text, "RAID_WARNING")
    elseif SendChatMessage and IsInGroup and IsInGroup() then
        SendChatMessage(text, "PARTY")
    else
        print("DiceSim announcement: " .. text)
    end

    self:AddEventLogEntry("Raid Announce: " .. text)
end
