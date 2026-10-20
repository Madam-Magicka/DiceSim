local DiceSim = _G.DiceSim

DiceSim.Theme = {
    colors = {
        frameBg = { 0.030, 0.024, 0.018, 0.98 },
        frameBorder = { 0.96, 0.72, 0.22, 0.96 },
        panelBg = { 0.050, 0.038, 0.026, 0.98 },
        panelBorder = { 0.96, 0.72, 0.22, 0.94 },
        insetBg = { 0.018, 0.014, 0.010, 0.96 },
        insetBorder = { 0.55, 0.40, 0.18, 0.92 },
        controlBg = { 0.105, 0.078, 0.045, 0.96 },
        controlHover = { 0.170, 0.120, 0.060, 0.98 },
        controlPressed = { 0.055, 0.038, 0.020, 1 },
        controlBorder = { 0.72, 0.54, 0.24, 0.92 },
        controlBorderHover = { 1.00, 0.78, 0.30, 1 },
        text = { 0.94, 0.88, 0.74, 1 },
        textMuted = { 0.70, 0.62, 0.48, 1 },
        danger = { 0.85, 0.20, 0.16, 1 },
        success = { 0.36, 0.62, 0.22, 1 },
        accent = { 1.00, 0.74, 0.22, 1 },
        accentGold = { 1.00, 0.74, 0.22, 1 },
        pearl = { 0.96, 0.90, 0.76, 1 },
    },
    sizes = {
        iconButton = 36,
        icon = 26,
        smallIconButton = 28,
        smallIcon = 20,
        resizeGrip = 26,
        scrollbarWidth = 12,
        scrollbarThumbWidth = 6,
        scrollbarThumbHeight = 28,
        scrollbarArrow = 10,
        fieldHeight = 30,
        textButtonHeight = 28,
        menuRowHeight = 25,
        border = 12,
        gap = 8,
    },
    textures = {
        solid = "Interface\\Buttons\\WHITE8X8",
        panelBg = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        panelBorder = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        genericPanelBg = "gearUpdate-BG",
        sheetPanelBg = "tradeskill-background-recipe",
        tooltipBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
        logoRing = "talents-heroclass-ring-selectionpane-yellow",
        scrollbarThumb = "Minimal_Scrollbar_Thumb",
        scrollbarThumbFallback = "minimal-scrollbar-small-thumb-middle-over",
        scrollbarArrowBottom = "Minimal_Scrollbar_Arrow_Bottom",
        scrollbarArrowTop = "Minimal_Scrollbar_Arrow_Top",
        scrollbarArrowBottomFallback = "minimal-scrollbar-small-arrow-bottom-over",
        scrollbarArrowTopFallback = "minimal-scrollbar-small-arrow-top-down",
        dropdownNormal = "common-dropdown-b-button",
        dropdownHover = "common-dropdown-b-button-hover",
        dropdownOpen = "common-dropdown-b-button-open",
        dropdownPressed = "common-dropdown-b-button-pressed",
        dropdownPressedHover = "common-dropdown-b-button-pressedhover",
        dropdownItem = "perks-dropdownbox",
        dropdownArrow = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up",
        redCondense = "RedButton-Condense",
        redCondenseDisabled = "RedButton-Condense-disabled",
        redCondensePressed = "RedButton-Condense-Pressed",
        redExit = "RedButton-Exit",
        redExitDisabled = "RedButton-Exit-Disabled",
        redExitPressed = "RedButton-exit-pressed",
        redExpand = "RedButton-Expand",
        redExpandDisabled = "RedButton-Expand-Disabled",
        redExpandPressed = "RedButton-Expand-Pressed",
        redMiniCondense = "RedButton-MiniCondense",
        redMiniCondenseDisabled = "RedButton-MiniCondense-disabled",
        redMiniCondensePressed = "RedButton-MiniCondense-pressed",
        redButton = "UI-DialogBox-Button-Up",
        redButtonDisabled = "UI-DialogBox-Button-Up",
        redButtonPressed = "UI-DialogBox-Button-Down",
        redButtonHighlight = "UI-DialogBox-Button-Highlight",
        topAdd = "communities-icon-addgroupplus",
        sessionIcon = "QuestSharing-DialogIcon",
        dmIcon = "poi-nzothvision",
        eventLogIcon = "lorewalking-map-icon",
        sheetIcon = "housing-map-deed",
        diceIcon = "charactercreate-icon-dice",
        rollDice = "charactercreate-icon-dice",
        resizeGrip = "UI-HUD-UnitFrame-Player-PortraitOn-CornerEmbellishment",
        sessionStatusDot = "LevelUp-Dot-Green",
        info = "Interface\\Common\\help-i",
        settings = "common-dropdown-a-button-settings-shadowless",
        settingsDisabled = "common-dropdown-a-button-settings-disabled-shadowless",
        settingsOpen = "common-dropdown-a-button-settings-open-shadowless",
        settingsPressedHover = "common-dropdown-a-button-settings-pressedhover-shadowless",
        settingsHover = "common-dropdown-a-button-settings-hover-shadowless",
        settingsPressed = "common-dropdown-a-button-settings-pressed-shadowless",
        raidAnnounce = "voicechat-icon-speaker",
        roster = "squad_size_trios",
        promote = "plunderstorm-glues-icon-leader",
        rounds = "TaxiNode_Continent_Neutral_Timed",
        roundTrackerBg = "challenges-timerbg",
        announcementParchment = "islands-queue-card2",
        actionDice = "lootroll-toast-icon-need-up",
        actionDiceHover = "lootroll-toast-icon-need-highlight",
        remove = "common-icon-redx",
        plus = "glues-characterSelect-icon-plus",
        plusDisabled = "glues-characterSelect-icon-plus-disabled",
        plusHover = "glues-characterSelect-icon-plus-hover",
        minus = "glues-characterSelect-icon-minus",
        minusDisabled = "glues-characterSelect-icon-minus-disabled",
        minusHover = "glues-characterSelect-icon-minus-hover",
        divider = "UI-Journeys-Renown-divider",
        output = "Interface\\AddOns\\DiceSim\\Interface\\Common\\house-list-container-open.blp",
    },
}

function DiceSim:ApplyTextureOrAtlas(texture, source, useAtlasSize)
    if not texture or not source then
        return false
    end

    if type(source) == "number" then
        if texture.SetTexture then
            texture:SetTexture(source)
            return true
        end

        return false
    end

    local sourceText = tostring(source)
    local sourceNumber = tonumber(sourceText)
    if sourceNumber then
        if texture.SetTexture then
            texture:SetTexture(sourceNumber)
            return true
        end

        return false
    end

    local looksLikePath = string.find(sourceText, "\\", 1, true) or string.find(sourceText, "/", 1, true)

    if texture.SetAtlas and not looksLikePath then
        local ok = pcall(texture.SetAtlas, texture, sourceText, useAtlasSize and true or false)
        if ok then
            return true
        end
    end

    if texture.SetTexture then
        texture:SetTexture(sourceText)
        return true
    end

    return false
end

function DiceSim:ApplyBackdrop(frame, bgColor, borderColor, edgeSize, insets)
    if not frame or not frame.SetBackdrop then
        return
    end

    local theme = self.Theme
    frame:SetBackdrop({
        bgFile = theme.textures.solid,
        edgeFile = theme.textures.solid,
        edgeSize = edgeSize or 1,
        insets = insets or { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(unpack(bgColor or theme.colors.panelBg))
    frame:SetBackdropBorderColor(unpack(borderColor or theme.colors.panelBorder))
end

function DiceSim:SetFontColor(fontString, color)
    if fontString and fontString.SetTextColor then
        fontString:SetTextColor(unpack(color or self.Theme.colors.text))
    end

    if self.ApplyFontStringScale then
        self:ApplyFontStringScale(fontString)
    end
end
