local DiceSim = _G.DiceSim

local HOME_CARD_SCALE = 0.78
local HOME_CARD_MIN_SIZE = 340
local HOME_CARD_MAX_SIZE = 620
local HOME_CONTENT_WIDTH_RATIO = 0.72
local HOME_CONTENT_HEIGHT_RATIO = 0.46
local HOME_CONTENT_X_OFFSET = 0
local HOME_CONTENT_Y_OFFSET = -18

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function LayoutHomePanel(panel)
    if not panel or not panel.Card then
        return
    end

    local width = panel:GetWidth() or 0
    local height = panel:GetHeight() or 0
    if width <= 0 or height <= 0 then
        return
    end

    local cardSize = Clamp(math.min(width, height) * HOME_CARD_SCALE, HOME_CARD_MIN_SIZE, HOME_CARD_MAX_SIZE)
    panel.Card:SetSize(cardSize, cardSize)

    local contentWidth = cardSize * HOME_CONTENT_WIDTH_RATIO
    local contentHeight = cardSize * HOME_CONTENT_HEIGHT_RATIO
    panel.Content:SetSize(contentWidth, contentHeight)
    panel.Content:ClearAllPoints()
    panel.Content:SetPoint("CENTER", panel.Card, "CENTER", HOME_CONTENT_X_OFFSET, HOME_CONTENT_Y_OFFSET)

    panel.Title:SetWidth(contentWidth)
    panel.Body:SetWidth(contentWidth)
end

function DiceSim:DismissHomePanel()
    local settings = self:GetSettings()
    settings.homeDismissed = true

    if self.HomePanel then
        self.HomePanel:Hide()
    end
end

function DiceSim:ShowHomePanel()
    if not self.HomePanel then
        return
    end

    if self:GetSettings().homeDismissed then
        self.HomePanel:Hide()
        return
    end

    self.HomePanel:Show()
end

function DiceSim:OpenHomePanel()
    if not self.HomePanel then
        return
    end

    self.HomePanel:Show()
end

function DiceSim:CreateHomePanel(parent)
    local panel = CreateFrame("Frame", "DiceSimHomePanel", parent)
    panel:SetAllPoints(parent)
    panel:SetFrameLevel(parent:GetFrameLevel() + 60)
    panel:EnableMouse(true)

    local shade = panel:CreateTexture(nil, "BORDER")
    shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    shade:SetAllPoints(panel)
    shade:SetColorTexture(0, 0, 0, 0.28)

    local card = CreateFrame("Frame", nil, panel)
    card:SetPoint("CENTER", panel, "CENTER", 0, 0)
    panel.Card = card

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(card)
    self:ApplyTextureOrAtlas(background, "shop-card-full-15thAnniversary")
    background:SetAlpha(0.96)
    panel.Background = background

    local content = CreateFrame("Frame", nil, card)
    panel.Content = content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", content, "TOP", 0, 0)
    title:SetJustifyH("CENTER")
    title:SetText("Welcome to DiceSim")
    panel.Title = title

    local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOP", title, "BOTTOM", 0, -18)
    body:SetJustifyH("CENTER")
    body:SetJustifyV("TOP")
    body:SetText("Build a neutral tabletop space with sheets, dice, canvas panels, buffs, debuffs, initiative, and hosted sessions. Start with placeholders, then import your own JSON when your group is ready.")
    panel.Body = body

    local startButton = CreatePanelButton(content, "Start")
    startButton:SetSize(120, 30)
    startButton:SetPoint("TOP", body, "BOTTOM", -70, -26)
    FitPanelButtonLabel(startButton)
    startButton:SetScript("OnClick", function()
        DiceSim:DismissHomePanel()
    end)

    local tutorialButton = CreatePanelButton(content, "Tutorial")
    tutorialButton:SetSize(120, 30)
    tutorialButton:SetPoint("LEFT", startButton, "RIGHT", 20, 0)
    FitPanelButtonLabel(tutorialButton)
    tutorialButton:SetScript("OnClick", function()
        DiceSim:StartTutorialTour()
    end)

    self.HomePanel = panel
    panel:SetScript("OnSizeChanged", LayoutHomePanel)
    LayoutHomePanel(panel)
    self:ShowHomePanel()
    return panel
end
