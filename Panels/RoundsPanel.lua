local DiceSim = _G.DiceSim

local DEFAULT_ROUND = 1

function DiceSim:GetRoundNumber()
    self.RoundNumber = math.max(1, math.floor(tonumber(self.RoundNumber) or DEFAULT_ROUND))
    return self.RoundNumber
end

function DiceSim:RefreshRoundsTracker()
    if not self.RoundsTracker then
        return
    end

    self.RoundsTracker.Label:SetText("Round " .. self:GetRoundNumber())

    local canManage = self:CanManageTools()
    self.RoundsTracker.MinusButton:SetShown(canManage)
    self.RoundsTracker.PlusButton:SetShown(canManage)
end

function DiceSim:SetRoundNumber(value, shouldBroadcast)
    self.RoundNumber = math.max(1, math.floor(tonumber(value) or DEFAULT_ROUND))
    self:RefreshRoundsTracker()
    self:SaveSessionSnapshot()

    if shouldBroadcast then
        self:SendSessionMessage("RND:" .. self.RoundNumber .. ":" .. (self.RoundsTracker and self.RoundsTracker:IsShown() and "1" or "0"))
        self:AddEventLogEntry("Round set to " .. self.RoundNumber .. ".")
    end
end

function DiceSim:SetRoundsTrackerShown(isShown, shouldBroadcast)
    if not self.RoundsTracker then
        return
    end

    self.RoundsTracker:SetShown(isShown and true or false)
    self:RefreshRoundsTracker()
    self:SaveSessionSnapshot()

    if shouldBroadcast then
        self:SendSessionMessage("RND:" .. self:GetRoundNumber() .. ":" .. (isShown and "1" or "0"))
    end
end

function DiceSim:ToggleRoundsTracker()
    if not self:CanManageTools() then
        return
    end

    self:SetRoundsTrackerShown(not self.RoundsTracker:IsShown(), true)
end

function DiceSim:AdjustRound(delta)
    if not self:CanManageTools() then
        return
    end

    self:SetRoundNumber(self:GetRoundNumber() + (tonumber(delta) or 0), true)
end

function DiceSim:CreateRoundsTracker(parent)
    local tracker = CreateFrame("Frame", "DiceSimRoundsTracker", parent)
    tracker:SetSize(230, 64)
    tracker:SetPoint("TOP", parent, "TOP", 0, -34)
    tracker:SetFrameLevel(parent:GetFrameLevel() + 18)
    tracker:Hide()

    local background = tracker:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("CENTER")
    background:SetSize(180, 54)
    self:ApplyTextureOrAtlas(background, self.Theme.textures.roundTrackerBg)
    tracker.Background = background

    local label = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    label:SetPoint("CENTER", background, "CENTER", 0, 0)
    label:SetTextColor(0.78, 0.94, 1.0, 1)
    label:SetShadowColor(0, 0, 0, 0.95)
    label:SetShadowOffset(1, -1)
    tracker.Label = label

    local minus = CreateTrayButton(tracker, "DiceSimRoundsMinusButton", "Interface\\Buttons\\UI-MinusButton-Up", "Previous Round")
    minus:SetPoint("RIGHT", background, "LEFT", -4, 0)
    minus:SetSize(34, 34)
    minus:SetIconSize(24)
    minus:SetScript("OnClick", function()
        DiceSim:AdjustRound(-1)
    end)
    tracker.MinusButton = minus

    local plus = CreateTrayButton(tracker, "DiceSimRoundsPlusButton", "Interface\\Buttons\\UI-PlusButton-Up", "Next Round")
    plus:SetPoint("LEFT", background, "RIGHT", 4, 0)
    plus:SetSize(34, 34)
    plus:SetIconSize(24)
    plus:SetScript("OnClick", function()
        DiceSim:AdjustRound(1)
    end)
    tracker.PlusButton = plus

    self.RoundsTracker = tracker
    self.RoundNumber = self.RoundNumber or DEFAULT_ROUND
    self:RefreshRoundsTracker()
    return tracker
end
