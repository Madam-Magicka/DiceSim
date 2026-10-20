local DiceSim = _G.DiceSim

local TOUR_PANEL_WIDTH = 320
local TOUR_PANEL_HEIGHT = 168
local TOUR_CARD_GAP = 18

local function GetStepCount()
    return #(DiceSim.TutorialTourSteps or {})
end

local function GetSafeFrame(frame)
    if frame and frame.IsShown and frame:IsShown() then
        return frame
    end
    return DiceSim.Frame
end

local function ShowFloatingPanel(panel)
    if not panel then
        return
    end

    if DiceSim.IsMinimized and DiceSim.Expand then
        DiceSim:Expand()
    end

    panel:Show()
    if DiceSim.BringWindowToFront then
        DiceSim:BringWindowToFront(panel)
    end
end

local function RaiseTourPanel(panel)
    if not panel or not DiceSim.TutorialTour then
        return
    end

    DiceSim.TutorialTourRaisedFrames = DiceSim.TutorialTourRaisedFrames or {}
    if not DiceSim.TutorialTourRaisedFrames[panel] then
        DiceSim.TutorialTourRaisedFrames[panel] = {
            strata = panel:GetFrameStrata(),
            level = panel:GetFrameLevel(),
        }
    end

    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(DiceSim.TutorialTour:GetFrameLevel() + 8)
    if panel.ResizeGrip then
        panel.ResizeGrip:SetFrameLevel(panel:GetFrameLevel() + 20)
    end
end

local function RestoreTourPanels()
    for panel, state in pairs(DiceSim.TutorialTourRaisedFrames or {}) do
        if panel then
            panel:SetFrameStrata(state.strata or "DIALOG")
            panel:SetFrameLevel(state.level or 1)
            if panel.ResizeGrip then
                panel.ResizeGrip:SetFrameLevel(panel:GetFrameLevel() + 20)
            end
        end
    end

    DiceSim.TutorialTourRaisedFrames = nil
end

local function ClosePreviousTourPanel(nextPanel)
    local previousPanel = DiceSim.TutorialTourOpenPanel
    if previousPanel and previousPanel ~= nextPanel and previousPanel.Hide then
        previousPanel:Hide()
    end

    DiceSim.TutorialTourOpenPanel = nextPanel
end

local function PlaceTourCard(tour, target, avoidFrame)
    local card = tour and tour.Card
    local frame = DiceSim.Frame
    if not card or not target or not frame then
        return
    end

    card:ClearAllPoints()

    local frameCenter = frame:GetLeft() and (frame:GetLeft() + (frame:GetWidth() / 2)) or 0
    local targetCenter = target:GetLeft() and (target:GetLeft() + (target:GetWidth() / 2)) or frameCenter
    local anchor = avoidFrame or target

    if targetCenter <= frameCenter then
        card:SetPoint("LEFT", anchor, "RIGHT", TOUR_CARD_GAP, 0)
    else
        card:SetPoint("RIGHT", anchor, "LEFT", -TOUR_CARD_GAP, 0)
    end

    local left = card:GetLeft()
    local right = card:GetRight()
    local frameLeft = frame:GetLeft()
    local frameRight = frame:GetRight()

    if left and frameLeft and left < frameLeft + 14 then
        card:ClearAllPoints()
        card:SetPoint("LEFT", frame, "LEFT", 14, 0)
    elseif right and frameRight and right > frameRight - 14 then
        card:ClearAllPoints()
        card:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    end
end

function DiceSim:CreateTutorialTour(parent)
    local overlay = CreateFrame("Frame", "DiceSimTutorialTour", parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(parent:GetFrameLevel() + 200)
    overlay:EnableMouse(false)
    overlay:Hide()

    local shade = overlay:CreateTexture(nil, "BACKGROUND")
    shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    shade:SetAllPoints(overlay)
    shade:SetColorTexture(0, 0, 0, 0.36)
    overlay.Shade = shade

    local highlight = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    highlight:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    highlight:SetBackdropColor(0.08, 0.32, 0.62, 0.16)
    highlight:SetBackdropBorderColor(1.0, 0.78, 0.28, 1)
    highlight:SetFrameLevel(overlay:GetFrameLevel() + 5)
    overlay.Highlight = highlight

    local card = CreatePanel(overlay, "DiceSimTutorialTourCard", TOUR_PANEL_WIDTH, TOUR_PANEL_HEIGHT)
    card:SetFrameStrata("FULLSCREEN_DIALOG")
    card:SetFrameLevel(overlay:GetFrameLevel() + 10)
    card:Show()
    overlay.Card = card

    if card.InfoButton then
        card.InfoButton:Hide()
    end

    local closeButton = CreateTrayButton(card, "DiceSimTutorialTourCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        DiceSim:StopTutorialTour()
    end)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 18, -18)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -46, -18)
    title:SetHeight(24)
    title:SetJustifyH("LEFT")
    card.Title = title

    local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    body:SetPoint("RIGHT", card, "RIGHT", -18, 0)
    body:SetHeight(62)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetNonSpaceWrap(true)
    card.Body = body

    local previousButton = CreatePanelButton(card, "Previous")
    previousButton:SetSize(96, 24)
    previousButton:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 18, 16)
    FitPanelButtonLabel(previousButton)
    previousButton:SetScript("OnClick", function()
        DiceSim:ShowTutorialTourStep((DiceSim.TutorialTourIndex or 1) - 1)
    end)
    card.PreviousButton = previousButton

    local nextButton = CreatePanelButton(card, "Next")
    nextButton:SetSize(96, 24)
    nextButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -18, 16)
    FitPanelButtonLabel(nextButton)
    nextButton:SetScript("OnClick", function()
        local nextIndex = (DiceSim.TutorialTourIndex or 1) + 1
        if nextIndex > GetStepCount() then
            DiceSim:StopTutorialTour()
        else
            DiceSim:ShowTutorialTourStep(nextIndex)
        end
    end)
    card.NextButton = nextButton

    self.TutorialTour = overlay
    return overlay
end

function DiceSim:GetTutorialTourSteps()
    self.TutorialTourSteps = self.TutorialTourSteps or {
        {
            title = "Home",
            body = "The DiceSim icon opens this welcome screen again. Use it when you want to return to the starting point.",
            target = function() return DiceSim.HomeButton end,
        },
        {
            title = "Sheet",
            body = "Open your Sheet to manage profiles, attributes, HP, Energy, Armor, buffs, debuffs, and dice-system imports.",
            target = function() return DiceSim.SheetButton end,
            open = function() DiceSim:OpenSheetPanel("player") end,
            panel = function() return DiceSim.SheetPanel end,
        },
        {
            title = "Dice",
            body = "Use Dice for player rolls. Choose a dice type, action, target, modifier, and optional effect dice.",
            target = function() return DiceSim.DiceButton end,
            open = function() ShowFloatingPanel(DiceSim.DicePanel) end,
            panel = function() return DiceSim.DicePanel end,
        },
        {
            title = "Add",
            body = "Use Add to place raid markers, number symbols, canvas panels, and backgrounds.",
            target = function() return DiceSim.TopAddButton end,
            open = function() ShowFloatingPanel(DiceSim.AddPanel) end,
            panel = function() return DiceSim.AddPanel end,
        },
        {
            title = "DM",
            body = "The DM panel handles initiative, announcements, rounds, roster visibility, and assistant admins.",
            target = function() return DiceSim.DMButton end,
            open = function() ShowFloatingPanel(DiceSim.DMPanel) end,
            panel = function() return DiceSim.DMPanel end,
        },
        {
            title = "Session",
            body = "Host, invite, kick, restore, and wipe your local session from here. Invites use your party or raid roster.",
            target = function() return DiceSim.SessionButton end,
            open = function()
                ShowFloatingPanel(DiceSim.SessionPanel)
                if DiceSim.RefreshSessionPanel then
                    DiceSim:RefreshSessionPanel()
                end
            end,
            panel = function() return DiceSim.SessionPanel end,
        },
        {
            title = "Event Log",
            body = "The log records rolls, announcements, and session activity so the table can review what happened.",
            target = function() return DiceSim.LogButton end,
            open = function()
                ShowFloatingPanel(DiceSim.EventLogPanel)
                if DiceSim.RefreshEventLog then
                    DiceSim:RefreshEventLog()
                end
            end,
            panel = function() return DiceSim.EventLogPanel end,
        },
    }

    return self.TutorialTourSteps
end

function DiceSim:StartTutorialTour()
    if not self.Frame then
        return
    end

    if not self.TutorialTour then
        self:CreateTutorialTour(self.Frame)
    end

    self:GetTutorialTourSteps()
    self.TutorialTour:Show()
    self:ShowTutorialTourStep(1)
end

function DiceSim:StopTutorialTour()
    ClosePreviousTourPanel(nil)
    RestoreTourPanels()
    if self.TutorialTour then
        self.TutorialTour:Hide()
    end
end

function DiceSim:ShowTutorialTourStep(index)
    local steps = self:GetTutorialTourSteps()
    local count = #steps
    index = math.max(1, math.min(count, tonumber(index) or 1))

    local step = steps[index]
    self.TutorialTourIndex = index

    local tour = self.TutorialTour
    if not tour then
        return
    end

    local panel = step.panel and step.panel()
    ClosePreviousTourPanel(panel)

    if step.open then
        step.open()
        panel = step.panel and step.panel() or panel
        self.TutorialTourOpenPanel = panel
    end

    RaiseTourPanel(panel)
    local target = GetSafeFrame(step.target and step.target())
    tour.Card.Title:SetText(step.title or "Tutorial")
    tour.Card.Body:SetText(step.body or "")
    tour.Card.PreviousButton:SetEnabled(index > 1)
    tour.Card.NextButton:SetText(index == count and "Finish" or "Next")
    FitPanelButtonLabel(tour.Card.NextButton)

    tour.Highlight:ClearAllPoints()
    tour.Highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -8, 8)
    tour.Highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 8, -8)
    PlaceTourCard(tour, target, panel)
end
