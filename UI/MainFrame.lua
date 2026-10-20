-- Main UI frame creation and management.

local DiceSim = _G.DiceSim

function DiceSim:Toggle()
    if not self.Frame then
        self:CreateMainFrame()
        self:RefreshPermissions()
        self.Frame:Show()
        return
    end

    self.Frame:SetShown(not self.Frame:IsShown())
end

function DiceSim:CreateMainFrame()
    local theme = self.Theme
    local frame = CreateFrame("Frame", "DiceSimFrame", UIParent, "BackdropTemplate")
    frame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("RightButton")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(unpack(theme.colors.frameBg))
    frame:SetBackdropBorderColor(unpack(theme.colors.frameBorder))
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    self.Frame = frame
    self.MainFrame = frame
    self.MainContent = {}

    self:MakeWindowInteractive(frame, {
        minWidth = MAIN_WIDTH,
        minHeight = MAIN_HEIGHT,
        maxWidth = 2600,
        maxHeight = 1600,
        onResize = function()
            self:RefreshCanvas()
        end,
    })

    if frame.ResizeGrip then
        table.insert(self.MainContent, frame.ResizeGrip)
    end

    self:CreateCharacterTabs(frame)

    local viewport = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    viewport:SetPoint("TOPLEFT", 16, -16)
    viewport:SetPoint("BOTTOMRIGHT", -16, 16)
    viewport:SetClipsChildren(true)
    viewport:EnableMouse(true)
    viewport:EnableMouseWheel(true)
    viewport:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    viewport:SetBackdropColor(unpack(theme.colors.insetBg))
    viewport:SetBackdropBorderColor(unpack(theme.colors.insetBorder))
    viewport:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            if CloseDropDownMenus then
                CloseDropDownMenus()
            end

            if self.ActiveDropdown then
                self.ActiveDropdown:Hide()

                if self.ActiveDropdown.Submenu then
                    self.ActiveDropdown.Submenu:Hide()
                end
            end

            self:StartPan()
        end
    end)
    viewport:SetScript("OnMouseUp", function()
        self:StopPan()
    end)
    viewport:SetScript("OnHide", function()
        self:StopPan()
    end)
    viewport:SetScript("OnMouseWheel", function(_, delta)
        local localX, localY = self:GetViewportCursorPosition()
        self:SetZoom((self.Zoom or 0.75) + (delta * 0.08), localX, localY)
    end)
    self.Viewport = viewport
    table.insert(self.MainContent, viewport)

    local canvas = CreateFrame("Frame", nil, viewport)
    canvas:SetSize(4096, 2684)
    canvas:SetFrameLevel(viewport:GetFrameLevel() + 1)
    self.Canvas = canvas
    self.CanvasObjects = self.CanvasObjects or {}
    self.CanvasSymbols = self.CanvasSymbols or {}
    self.Zoom = 0.75
    self.CameraX = 2048
    self.CameraY = 1342
    self.CanvasX = 0
    self.CanvasY = 0
    self:CreateGrid()

    if self.CreateHomePanel then
        self:CreateHomePanel(viewport)
    end

    local portrait = CreateFrame("Button", "DiceSimHomeButton", frame, "BackdropTemplate")
    portrait:SetSize(68, 68)
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", -20, 25)
    portrait:SetFrameLevel(frame:GetFrameLevel() + 8)
    portrait:SetBackdrop(nil)
    portrait:EnableMouse(true)

    local portraitMask = portrait:CreateMaskTexture()
    portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    portraitMask:SetAllPoints(portrait)

    local logo = portrait:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\DiceSim\\UI\\BLPs\\DiceSimLogo.blp")
    logo:SetAllPoints(portrait)
    logo:AddMaskTexture(portraitMask)

    local logoGlow = portrait:CreateTexture(nil, "HIGHLIGHT")
    logoGlow:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    logoGlow:SetSize(82, 82)
    self:ApplyTextureOrAtlas(logoGlow, "Artifacts-PerkRing-Final")
    logoGlow:SetBlendMode("ADD")
    logoGlow:SetVertexColor(1, 0.78, 0.28, 0.85)
    portrait:SetHighlightTexture(logoGlow, "ADD")
    portrait:SetScript("OnClick", function()
        if self.OpenHomePanel then
            self:OpenHomePanel()
        end
    end)
    portrait:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Home")
        GameTooltip:Show()
    end)
    portrait:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    self.HomeButton = portrait

    table.insert(self.MainContent, portrait)

    local topTray = CreateTray(frame, nil, 154, 40)
    topTray:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -14)
    topTray:SetFrameLevel(frame:GetFrameLevel() + 8)
    topTray.TrayButtonIconOffsetY = -1
    self:ApplyBackdrop(topTray, theme.colors.controlBg, theme.colors.controlBorder, 1)
    table.insert(self.MainContent, topTray)

    local settingsButton = CreateTrayButton(topTray, "DiceSimSettingsButton", theme.textures.settings, "Settings")
    settingsButton:SetSize(theme.sizes.iconButton, theme.sizes.iconButton)
    settingsButton:SetIconSize(35)
    settingsButton.AtlasSet = {
        normal = theme.textures.settings,
        hover = theme.textures.settingsHover,
        pressed = theme.textures.settingsPressed,
        disabled = theme.textures.settingsDisabled,
    }
    self:ApplyTextureOrAtlas(settingsButton.Icon, theme.textures.settings)
    settingsButton:SetScript("OnClick", function()
        self:ToggleSettingsPanel()
    end)
    self.SettingsButton = settingsButton

    local minimizeButton = CreateTrayButton(topTray, "DiceSimMinimizeButton", "Interface\\Buttons\\UI-MinusButton-Up", "Minimize")
    minimizeButton:SetScript("OnClick", function()
        self:Minimize()
    end)

    local fitButton = CreateTrayButton(topTray, "DiceSimFitButton", "Interface\\Buttons\\UI-Panel-BiggerButton-Up", "Fit Screen")
    fitButton:SetScript("OnClick", function()
        self:FitScreen()
    end)
    self.FitButton = fitButton

    local closeButton = CreateTrayButton(topTray, "DiceSimCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("RIGHT", topTray, "RIGHT", -3, 0)
    fitButton:SetPoint("RIGHT", closeButton, "LEFT", -1, 0)
    minimizeButton:SetPoint("RIGHT", fitButton, "LEFT", -1, 0)
    settingsButton:SetPoint("RIGHT", minimizeButton, "LEFT", -1, 0)
    WireCloseButton(closeButton, function()
        self:Close()
    end)
    self.TopCloseButton = closeButton

    local bottomTray = CreateTray(frame, nil, 238, 44)
    bottomTray:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14)
    bottomTray:SetFrameLevel(frame:GetFrameLevel() + 8)
    self:ApplyBackdrop(bottomTray, theme.colors.controlBg, theme.colors.controlBorder, 1)
    self.BottomTray = bottomTray
    table.insert(self.MainContent, bottomTray)

    local dmButton = CreateTrayButton(bottomTray, "DiceSimDMButton", theme.textures.dmIcon, "DM")
    dmButton.IconSize = 40
    dmButton.Icon:SetSize(40, 40)
    dmButton:SetScript("OnClick", function()
        self:ToggleDMPanel()
    end)
    self.DMButton = dmButton

    local logButton = CreateTrayButton(bottomTray, "DiceSimLogButton", theme.textures.eventLogIcon, "Event Log")
    logButton.IconSize = 40
    logButton.Icon:SetSize(40, 40)
    logButton:SetScript("OnClick", function()
        self:ToggleEventLogPanel()
    end)
    self.LogButton = logButton

    local unreadMarker = logButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unreadMarker:SetPoint("TOPRIGHT", logButton, "TOPRIGHT", -3, -1)
    unreadMarker:SetText("|cffff4040!|r")
    unreadMarker:Hide()
    self.EventLogUnreadMarker = unreadMarker

    local sheetButton = CreateTrayButton(bottomTray, "DiceSimSheetButton", theme.textures.sheetIcon, "Sheet")
    sheetButton:SetScript("OnClick", function()
        self:ToggleSheetPanel()
    end)
    self.SheetButton = sheetButton

    local diceButton = CreateTrayButton(bottomTray, "DiceSimDiceButton", theme.textures.diceIcon, "Dice")
    diceButton:SetScript("OnClick", function()
        self:ToggleDicePanel()
    end)
    self.DiceButton = diceButton

    local addButton = CreateTrayButton(bottomTray, "DiceSimAddButton", "Interface\\Buttons\\UI-PlusButton-Up", "Add")
    addButton.AtlasSet = {
        normal = theme.textures.topAdd,
        hover = theme.textures.topAdd,
        pressed = theme.textures.topAdd,
        disabled = theme.textures.plusDisabled,
    }
    self:ApplyTextureOrAtlas(addButton.Icon, theme.textures.topAdd)
    addButton:SetScript("OnClick", function()
        self:ToggleAddPanel()
    end)
    self.TopAddButton = addButton

    local sessionButton = CreateTrayButton(bottomTray, "DiceSimSessionButton", theme.textures.sessionIcon, "Session")
    sessionButton.IconSize = 40
    sessionButton.Icon:SetSize(40, 40)
    sessionButton:SetScript("OnClick", function()
        self:ToggleSessionPanel()
    end)
    self.SessionButton = sessionButton

    sessionButton:SetPoint("RIGHT", bottomTray, "RIGHT", -4, 0)
    addButton:SetPoint("RIGHT", sessionButton, "LEFT", -3, 0)
    diceButton:SetPoint("RIGHT", addButton, "LEFT", -3, 0)
    sheetButton:SetPoint("RIGHT", diceButton, "LEFT", -3, 0)
    logButton:SetPoint("RIGHT", sheetButton, "LEFT", -3, 0)
    dmButton:SetPoint("RIGHT", logButton, "LEFT", -3, 0)

    self:CreateAddPanel(frame, bottomTray)
    self:CreateSessionPanel(frame, bottomTray)
    self:CreateDicePanel(frame, bottomTray)
    self:CreateSheetPanel(frame, bottomTray)
    self:CreateDMPanel(frame, bottomTray)
    self:CreateRoundsTracker(frame)
    self:CreateEventLogPanel(frame, bottomTray)
    self:CreateSettingsPanel(frame, topTray)
    self:CreateCoordinateTracker(frame)
    self:CreateMinimizedBar(frame)
    self:RestoreSessionSnapshot()
    self:CenterCanvas()
    self:ApplySettings()

    frame:SetScript("OnSizeChanged", function()
        if not self.IsMinimized then
            self:RefreshCanvas()
        end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        self.FrameUpdateElapsed = (self.FrameUpdateElapsed or 0) + (elapsed or 0)

        if self.FrameUpdateElapsed < 0.25 then
            return
        end

        self.FrameUpdateElapsed = 0

        if self.SessionSnapshotQueued then
            self.SessionSnapshotQueued = false
            self:SaveSessionSnapshot()
        end

        if self.ProcessSessionSync then
            self:ProcessSessionSync()
        end
    end)

    return frame
end

function DiceSim:CreateMinimizedBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetAllPoints(parent)
    bar:SetFrameLevel(parent:GetFrameLevel() + 16)
    bar:Hide()

    local status = bar:CreateTexture(nil, "ARTWORK")
    status:SetSize(12, 12)
    status:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -8)
    self:ApplyTextureOrAtlas(status, self.Theme.textures.sessionStatusDot)
    status:SetVertexColor(0.10, 0.88, 0.34, 1)

    local text = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("CENTER", bar, "CENTER", -10, 0)
    text:SetText("No active session")
    self.MinimizedStatusText = text

    local expandButton = CreateTrayButton(bar, "DiceSimExpandButton", "Interface\\Buttons\\UI-PlusButton-Up", "Expand")
    expandButton:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
    expandButton:SetScript("OnClick", function()
        self:Expand()
    end)

    self.MinimizedBar = bar
    self.MinimizedStatusDot = status
    return bar
end

function DiceSim:RefreshMinimizedStatus()
    if not self.MinimizedStatusDot then
        return
    end

    if self.ActiveSessionId then
        self.MinimizedStatusDot:SetVertexColor(0.10, 0.88, 0.34, 1)
        if self.MinimizedStatusText then
            self.MinimizedStatusText:SetText("Ongoing session")
        end
    else
        self.MinimizedStatusDot:SetVertexColor(0.90, 0.12, 0.10, 1)
        if self.MinimizedStatusText then
            self.MinimizedStatusText:SetText("No active session")
        end
    end
end

function DiceSim:OpenBuffDebuffPanel(context, affectType)
    if not self.BuffDebuffPanel then
        self:CreateBuffDebuffPanel(self.Frame)
    end

    if context then
        local canEditContext = context == self.SheetPanel and self:CanEditSheet(self.SheetPanel.Unit or "player") or self:CanManageTools()
        if not canEditContext then
            return
        end

        self.BuffDebuffPanel.Context = context
        self.BuffDebuffPanel.AffectType = affectType or "buff"
        self.BuffDebuffPanel.Title:SetText((self.BuffDebuffPanel.AffectType == "debuff" and "Add Debuff" or "Add Buff"))
        if self.BuffDebuffPanel.DetailsInput then
            self.BuffDebuffPanel.DetailsInput:SetText("")
        end
        if self.BuffDebuffPanel.NameInput then
            self.BuffDebuffPanel.NameInput:SetText("")
        end
        self.BuffDebuffPanel.AppliesTo = nil
        if self.BuffDebuffPanel.AppliesToField then
            self.BuffDebuffPanel.AppliesToField.Value = nil
            self.BuffDebuffPanel.AppliesToField.Label:SetText("Applies to:")
            self.BuffDebuffPanel.AppliesToField.Options = self:GetAffectAppliesOptions()
        end
        if self.BuffDebuffPanel.ModifierInput then
            self.BuffDebuffPanel.ModifierInput:SetText("0")
        end
        self.BuffDebuffPanel.SelectedIcon = FALLBACK_AFFECT_ICON_OPTIONS[1].icon
        if self.BuffDebuffPanel.IconPreview then
            self.BuffDebuffPanel.IconPreview:SetTexture(self.BuffDebuffPanel.SelectedIcon)
        end
        if self.BuffDebuffPanel.IconButton then
            self.BuffDebuffPanel.IconButton.SelectedIcon = self.BuffDebuffPanel.SelectedIcon
        end
        self.BuffDebuffPanel:ClearAllPoints()
        self.BuffDebuffPanel:SetPoint("CENTER", self.Frame, "CENTER", 0, 0)
        self.BuffDebuffPanel:Show()
        self:BringWindowToFront(self.BuffDebuffPanel)
        return
    end

    return
end

function DiceSim:SetMainContentShown(isShown)
    for _, child in ipairs(self.MainContent) do
        child:SetShown(isShown)
    end
end

function DiceSim:Close()
    self.Frame:Hide()
end

function DiceSim:Minimize()
    self.IsMinimized = true
    self.WasAddPanelShown = self.AddPanel and self.AddPanel:IsShown()
    self.WasRoundsTrackerShown = self.RoundsTracker and self.RoundsTracker:IsShown()
    self:SetMainContentShown(false)

    if self.AddPanel then
        self.AddPanel:Hide()
    end
    if self.DicePanel then
        self.DicePanel:Hide()
    end
    if self.SheetPanel then
        self.SheetPanel:Hide()
    end
    if self.DMPanel then
        self.DMPanel:Hide()
    end
    if self.EventLogPanel then
        self.EventLogPanel:Hide()
    end
    if self.SessionPanel then
        self.SessionPanel:Hide()
    end
    if self.BuffDebuffPanel then
        self.BuffDebuffPanel:Hide()
    end
    if self.RoundsTracker then
        self.RoundsTracker:Hide()
    end
    self.Frame:SetSize(MINIMIZED_WIDTH, MINIMIZED_HEIGHT)
    self:RefreshMinimizedStatus()
    self.MinimizedBar:Show()
end

function DiceSim:Expand()
    self.IsMinimized = false
    self.MinimizedBar:Hide()
    self.Frame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    self:SetMainContentShown(true)
    if self.AddPanel and self.WasAddPanelShown then
        self.AddPanel:Show()
    end
    if self.RoundsTracker and self.WasRoundsTrackerShown then
        self.RoundsTracker:Show()
    end
    self:RefreshCanvas()
end

function DiceSim:ToggleAddPanel()
    if not self:CanManageTools() then
        print("DiceSim: only admins and assistant admins can add canvas objects.")
        return
    end
    if self.IsMinimized then
        self:Expand()
    end
    self.AddPanel:SetShown(not self.AddPanel:IsShown())
end

function DiceSim:ToggleDicePanel()
    if self.IsMinimized then
        self:Expand()
    end
    self.DicePanel:SetShown(not self.DicePanel:IsShown())
end

function DiceSim:ToggleSheetPanel()
    self:OpenSheetPanel("player")
end

function DiceSim:OpenSheetPanel(unit)
    if self.IsMinimized then
        self:Expand()
    end
    if not self.SheetPanel and self.CreateSheetPanel and self.Frame then
        self:CreateSheetPanel(self.Frame, self.BottomTray or self.Frame)
    end
    if not self.SheetPanel then
        print("DiceSim: Sheet panel is not available.")
        return
    end
    local nextUnit = unit or "player"
    if (self.SheetPanel.Unit or "player") == "player" and nextUnit ~= "player" and self.GetSheetData then
        self.LocalSheetPanelData = self:GetSheetData()
    end
    self.SheetPanel.Unit = unit or "player"
    self.SheetPanel.RemoteSheetSystem = nil
    if self.SheetPanel.ProfileLabel and not self.SheetPanel.ProfileDropdown.Value then
        self.SheetPanel.ProfileLabel:SetText("Profiles")
    end
    if self.SheetPanel.PortraitTexture then
        if SetPortraitTexture then
            SetPortraitTexture(self.SheetPanel.PortraitTexture, self.SheetPanel.Unit)
        else
            self.SheetPanel.PortraitTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    end
    if self.SheetPanel.PortraitRing then
        local ring = self.GetSheetPortraitRing and self:GetSheetPortraitRing() or "hud-PlayerFrame-portraitring-large"
        if self.ApplyPortraitRingTexture then
            self:ApplyPortraitRingTexture(self.SheetPanel.PortraitRing, ring, 112)
        else
            self:ApplyTextureOrAtlas(self.SheetPanel.PortraitRing, ring)
            self.SheetPanel.PortraitRing:SetSize(112, 112)
        end
    end
    if self.SheetPanel.Unit == "player" and self.LocalSheetPanelData and self.ApplySheetData then
        self.IsApplyingRemoteSheet = true
        self:ApplySheetData(self.LocalSheetPanelData)
        self.IsApplyingRemoteSheet = false
        self:SetSheetEditable(self:CanEditSheet("player"))
    elseif self.SheetPanel.Unit ~= "player" and self.ApplyRemoteSheetForUnit then
        self:ApplyRemoteSheetForUnit(self.SheetPanel.Unit)
    elseif self.RefreshSheetSystemStatus then
        self:RefreshSheetSystemStatus()
    end
    self.SheetPanel:Show()
    self:BringWindowToFront(self.SheetPanel)
    self:RefreshPermissions()
end

function DiceSim:ToggleDMPanel()
    if not self:CanManageTools() then
        return
    end
    if self.IsMinimized then
        self:Expand()
    end
    self.DMPanel:SetShown(not self.DMPanel:IsShown())
end

function DiceSim:ToggleEventLogPanel()
    if self.IsMinimized then
        self:Expand()
    end
    self.EventLogPanel:SetShown(not self.EventLogPanel:IsShown())
    if self.EventLogPanel:IsShown() then
        self.EventLogUnread = false
        self:RefreshEventLog()
        self:UpdateEventLogUnreadMarker()
    end
end
