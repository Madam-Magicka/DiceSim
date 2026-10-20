local DiceSim = _G.DiceSim

function DiceSim:RefreshSessionPanel()
    if not self.SessionPanel then
        return
    end

    local session = self:GetActiveSession()
    local status = "No active session"

    if session then
        status = (self.SessionMode == "host" and "Hosting: " or "Joined: ") .. session.id
        if session.updated then
            status = status .. "\nSaved: " .. date("%H:%M:%S", session.updated)
        end
    end

    self.SessionPanel.StatusText:SetText(status)
    local canManageRoster = self.SessionMode == "host" and self.ActiveSessionId
    if self.SessionPanel.InviteButton then
        self.SessionPanel.InviteButton:SetShown(canManageRoster and true or false)
    end
    if self.SessionPanel.KickButton then
        self.SessionPanel.KickButton:SetShown(canManageRoster and true or false)
    end
end

function DiceSim:ToggleSessionPanel()
    if self.IsMinimized then
        self:Expand()
    end

    self.SessionPanel:SetShown(not self.SessionPanel:IsShown())
    if self.SessionPanel:IsShown() then
        self:RefreshSessionPanel()
        self:BringWindowToFront(self.SessionPanel)
    end
end

function DiceSim:ConfirmWipeSession()
    if not self.ActiveSessionId then
        return
    end

    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs.DICESIM_WIPE_LOCAL_SESSION = StaticPopupDialogs.DICESIM_WIPE_LOCAL_SESSION or {
            text = "Wipe your local DiceSim session data?\n\nThis only clears this client.",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                DiceSim:WipeSession()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("DICESIM_WIPE_LOCAL_SESSION")
        return
    end

    self.WipeSessionConfirmArmed = not self.WipeSessionConfirmArmed
    if self.WipeSessionConfirmArmed then
        print("DiceSim: click Wipe Local Session again to confirm.")
    else
        self:WipeSession()
    end
end

function DiceSim:PromptSessionInvite(sessionId, sender)
    if not sessionId or sessionId == "" then
        return
    end

    local now = time and time() or 0
    if self.PendingSessionInvite and self.PendingSessionInvite.sessionId == sessionId and now - (self.PendingSessionInvite.time or 0) < 10 then
        return
    end

    self.PendingSessionInvite = {
        sessionId = sessionId,
        sender = sender,
        time = now,
    }

    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs.DICESIM_SESSION_INVITE = StaticPopupDialogs.DICESIM_SESSION_INVITE or {
            text = "%s invited you to a DiceSim session.",
            button1 = ACCEPT,
            button2 = DECLINE,
            OnAccept = function()
                local invite = DiceSim.PendingSessionInvite
                if invite and invite.sessionId then
                    DiceSim:AcceptSessionInvite(invite.sessionId, invite.sender)
                end
                DiceSim.PendingSessionInvite = nil
            end,
            OnCancel = function()
                DiceSim.PendingSessionInvite = nil
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("DICESIM_SESSION_INVITE", sender or "A player")
        return
    end

    print("DiceSim: session invite from " .. (sender or "host") .. ". Open Session and enter: " .. sessionId)
end

function DiceSim:AcceptSessionInvite(sessionId, sender)
    if not sessionId or sessionId == "" then
        return
    end

    local playerKey = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey("player") or (self.PlayerKey or "player")
    self.SessionJoinGraceUntil = (time and time() or 0) + 20
    self:SendSessionMessage("ACCEPT:" .. sessionId .. ":" .. playerKey)
    if sender then
        self:SendSessionMessageTo("ACCEPT:" .. sessionId .. ":" .. playerKey, sender)
    end
    self:JoinSession(sessionId)
end

function DiceSim:ToggleSessionRosterMenu(anchor, mode)
    if self.SessionMode ~= "host" or not self.ActiveSessionId then
        print("DiceSim: host a session before managing players.")
        return
    end

    if self.SessionRosterMenu and self.SessionRosterMenu:IsShown() and self.SessionRosterMenu.Mode == mode then
        self.SessionRosterMenu:Hide()
        return
    end

    local menu = self.SessionRosterMenu
    if not menu then
        local theme = self.Theme
        menu = CreateFrame("Frame", "DiceSimSessionRosterMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        menu:SetBackdropColor(unpack(theme.colors.panelBg))
        menu:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
        menu.Rows = {}
        self.SessionRosterMenu = menu
    end

    for _, row in ipairs(menu.Rows) do
        row:Hide()
    end

    local members = {}
    for _, member in ipairs(self:GetGroupMemberOptions()) do
        if not self:IsSelfSessionMember(member.value) then
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

        local key = self:GetSessionMemberKey(member.value)
        local active = self.SessionPlayers and self.SessionPlayers[key]
        local pending = self.SessionPendingInvites and self.SessionPendingInvites[key]
        row.Label:SetText(member.label)
        if active then
            row.Bullet:SetVertexColor(1, 1, 1, 1)
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterFriend")
        elseif pending then
            row.Bullet:SetVertexColor(1, 1, 1, 1)
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterNeutral")
        else
            row.Bullet:SetVertexColor(1, 1, 1, 1)
            self:ApplyTextureOrAtlas(row.Bullet, "MonsterEnemy")
        end
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4 - ((index - 1) * 28))
        row:SetPoint("RIGHT", menu, "RIGHT", -4, 0)
        row:SetScript("OnClick", function()
            if mode == "invite" then
                DiceSim:InviteSessionMember(member.value)
            else
                DiceSim:KickSessionMember(member.value)
            end

            DiceSim:ToggleSessionRosterMenu(anchor, mode)
            DiceSim:ToggleSessionRosterMenu(anchor, mode)
        end)
        row:Show()
    end

    menu:SetFrameLevel((anchor:GetFrameLevel() or 1) + 80)
    menu:Show()
end

function DiceSim:CreateSessionPanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimSessionPanel", 360, 310)
    panel.TutorialKey = "session"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)

    local closeButton = CreateTrayButton(panel, "DiceSimSessionPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Session")

    local status = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOP", title, "BOTTOM", 0, -18)
    status:SetWidth(240)
    status:SetJustifyH("CENTER")
    status:SetText("No active session")
    panel.StatusText = status

    local hostButton = CreatePanelButton(panel, "Host Session")
    hostButton:SetSize(120, 24)
    hostButton:SetPoint("TOP", status, "BOTTOM", -68, -16)
    FitPanelButtonLabel(hostButton)
    hostButton:SetScript("OnClick", function()
        self:HostSession()
    end)

    local restoreButton = CreatePanelButton(panel, "Restore Saved")
    restoreButton:SetSize(120, 24)
    restoreButton:SetPoint("LEFT", hostButton, "RIGHT", 12, 0)
    FitPanelButtonLabel(restoreButton)
    restoreButton:SetScript("OnClick", function()
        self:RestoreSessionSnapshot()
    end)

    local joinInput = CreateTextInputBox(panel, 180, 30, 80, false)
    joinInput:SetPoint("TOP", panel, "TOP", -40, -128)
    SetInputPlaceholder(joinInput, "Session link or ID")
    panel.JoinInput = joinInput

    local joinButton = CreatePanelButton(panel, "Join")
    joinButton:SetSize(72, 30)
    joinButton:SetPoint("LEFT", joinInput, "RIGHT", 8, 0)
    FitPanelButtonLabel(joinButton)
    joinButton:SetScript("OnClick", function()
        self:JoinSession(joinInput:GetText())
    end)

    local rosterButtonRow = CreateFrame("Frame", nil, panel)
    rosterButtonRow:SetSize(252, 24)
    rosterButtonRow:SetPoint("TOP", panel, "TOP", 0, -170)

    local inviteButton = CreatePanelButton(rosterButtonRow, "Invite Player")
    inviteButton:SetSize(120, 24)
    inviteButton:SetPoint("LEFT", rosterButtonRow, "LEFT", 0, 0)
    FitPanelButtonLabel(inviteButton)
    inviteButton:SetScript("OnClick", function()
        self:ToggleSessionRosterMenu(inviteButton, "invite")
    end)
    panel.InviteButton = inviteButton

    local kickButton = CreatePanelButton(rosterButtonRow, "Kick Player")
    kickButton:SetSize(120, 24)
    kickButton:SetPoint("LEFT", inviteButton, "RIGHT", 12, 0)
    FitPanelButtonLabel(kickButton)
    kickButton:SetScript("OnClick", function()
        self:ToggleSessionRosterMenu(kickButton, "kick")
    end)
    panel.KickButton = kickButton

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOP", panel, "TOP", 0, -206)
    hint:SetSize(260, 44)
    hint:SetJustifyH("CENTER")
    hint:SetJustifyV("TOP")
    hint:SetText("Invite and kick controls use your current party or raid roster.")

    local wipeButton = CreatePanelButton(panel, "Wipe Local Session")
    wipeButton:SetSize(180, 24)
    wipeButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 18)
    FitPanelButtonLabel(wipeButton)
    wipeButton:SetScript("OnClick", function()
        self:ConfirmWipeSession()
    end)

    self.SessionPanel = panel
    self:RefreshSessionPanel()
    panel:Hide()
    return panel
end
