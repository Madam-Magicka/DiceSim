-- Canvas management and camera functions.

local DiceSim = _G.DiceSim
local Clamp = DiceSim.Utils.Clamp

-- Canvas constants
local MIN_ZOOM = 0.20
local MAX_ZOOM = 2.0
local ZOOM_STEP = 0.08
local CANVAS_WIDTH = 4096
local CANVAS_HEIGHT = 2684
local CANVAS_CENTER_X = CANVAS_WIDTH / 2
local CANVAS_CENTER_Y = CANVAS_HEIGHT / 2
local CANVAS_OBJECT_PANEL_WIDTH = 300
local CANVAS_OBJECT_PANEL_HEIGHT = 420

local function CreateMetricBar(parent, color)
    return DiceSim:CreateMetricBar(parent, color)
end

local function MakeCanvasObjectDraggable(owner, object)
    object:EnableMouse(true)
    object:RegisterForDrag("LeftButton")
    object:SetMovable(false)

    object:HookScript("OnMouseDown", function(self)
        if CloseDropDownMenus then
            CloseDropDownMenus()
        end

        if owner.ActiveDropdown then
            owner.ActiveDropdown:Hide()

            if owner.ActiveDropdown.Submenu then
                owner.ActiveDropdown.Submenu:Hide()
            end
        end

        owner:BringCanvasObjectToFront(self)
    end)

    object:SetScript("OnDragStart", function(self)
        if not owner:CanManageTools() then
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()

        self.IsDraggingOnCanvas = true
        self.StartCursorX = cursorX / uiScale
        self.StartCursorY = cursorY / uiScale
        self.StartCanvasObjectX = self.CanvasObjectX or 0
        self.StartCanvasObjectY = self.CanvasObjectY or 0
        owner:BringCanvasObjectToFront(self)

        self:SetScript("OnUpdate", function()
            owner:UpdateCanvasObjectDrag(self)
        end)
    end)

    object:SetScript("OnDragStop", function(self)
        self.IsDraggingOnCanvas = false
        self:SetScript("OnUpdate", nil)

        if owner.SaveSessionSnapshot then
            owner:SaveSessionSnapshot()
        end
    end)

    object:SetScript("OnHide", function(self)
        self.IsDraggingOnCanvas = false
        self:SetScript("OnUpdate", nil)
    end)
end

function DiceSim:CreateCanvasPanelActionPanel(canvasPanel)
    local panel = CreatePanel(self.Frame, nil, 300, 220)
    panel.TutorialKey = "canvasActions"
    panel:SetPoint("CENTER", self.Frame, "CENTER", 0, 0)
    panel.TargetPanel = canvasPanel

    local closeButton = CreateTrayButton(panel, nil, "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -22)
    title:SetText("Actions")

    local contentWidth = 240
    local actionRow = CreateFrame("Frame", nil, panel)
    actionRow:SetSize(contentWidth, 30)
    actionRow:SetPoint("TOP", title, "BOTTOM", 0, -18)

    local actionDropdown = CreateDropdownField(actionRow, "Action", self:GetActionOptions())
    actionDropdown:SetPoint("LEFT", actionRow, "LEFT", 0, 0)
    actionDropdown:SetWidth(154)
    actionDropdown.Value = "default:str:melee_attack"
    actionDropdown.Label:SetText("Melee Attack")
    actionDropdown.RefreshOptions = function()
        return DiceSim:GetActionOptions()
    end
    self.CanvasActionDropdowns = self.CanvasActionDropdowns or {}
    table.insert(self.CanvasActionDropdowns, actionDropdown)

    local modifierInput = CreateInputBox(actionRow, 74, 26)
    modifierInput:SetPoint("RIGHT", actionRow, "RIGHT", 0, 0)
    modifierInput:SetNumeric(false)
    modifierInput:SetText("")
    SetInputPlaceholder(modifierInput, "Modifier")
    panel.ModifierInput = modifierInput

    local targetEffectRow = CreateFrame("Frame", nil, panel)
    targetEffectRow:SetSize(contentWidth, 30)
    targetEffectRow:SetPoint("TOP", actionRow, "BOTTOM", 0, -10)

    local targetDropdown = CreateDropdownField(targetEffectRow, "Target", self:GetTargetOptions())
    targetDropdown:SetPoint("LEFT", targetEffectRow, "LEFT", 0, 0)
    targetDropdown:SetWidth(114)
    targetDropdown.Value = "None"
    targetDropdown.Label:SetText("Target")
    targetDropdown.RefreshOptions = function()
        return self:GetTargetOptions()
    end

    local effectDropdown = CreateDropdownField(targetEffectRow, "Effect Dice", EFFECT_DICE_OPTIONS)
    effectDropdown:SetPoint("RIGHT", targetEffectRow, "RIGHT", 0, 0)
    effectDropdown:SetWidth(114)
    effectDropdown.Value = "None"
    effectDropdown.Label:SetText("Effect Dice")

    actionDropdown.OnSelect = function(value, option)
        local actionData = DiceSim:GetActionDataByValue(value, option)
        local modifier = DiceSim:CalculateActionModifier(actionData)
        modifierInput:SetText(tostring(modifier or 0))
        actionDropdown.SelectedActionData = actionData

        if actionData.effectDice then
            effectDropdown.Value = actionData.effectDice
            effectDropdown.Label:SetText(actionData.effectDice)
        end
    end

    local rollButton = CreatePanelButton(panel, "Roll")
    rollButton:SetSize(116, 30)
    rollButton:SetPoint("TOP", targetEffectRow, "BOTTOM", 0, -18)
    FitPanelButtonLabel(rollButton)

    rollButton:SetScript("OnClick", function()
        local targetPanel = panel.TargetPanel
        if not targetPanel then
            return
        end

        targetDropdown.Options = self:GetTargetOptions()
        local actionData = self:GetActionDataByValue(actionDropdown.Value, actionDropdown.SelectedOption)
        local action = actionData and actionData.label or "STR"
        local diceType = actionData and actionData.dice or "D20"
        local roll, _, _, rolls = self:RollDiceExpression(diceType)
        local target = targetDropdown.Value or "None"
        local modifier = tonumber(modifierInput:GetText()) or 0
        local affectModifier = self:CollectAffectRollModifier(targetPanel, action)
        local _, modifierAttribute = self:CalculateActionModifier(actionData)
        local modifierText = self:GetSignedNumber(modifier)
        if modifierAttribute then
            modifierText = modifierText .. " " .. modifierAttribute
        end
        local total = roll + modifier + affectModifier.total
        local lines = {
            targetPanel.TargetName .. " -> " .. target,
            "Action: " .. action,
            "Roll: " .. self:FormatDiceRoll(diceType, roll, rolls),
            "Modifier: " .. modifierText,
        }

        if affectModifier.total ~= 0 then
            table.insert(lines, "Buff/Debuff: " .. self:GetSignedNumber(affectModifier.total) .. " (" .. table.concat(affectModifier.parts, ", ") .. ")")
        end

        table.insert(lines, "Roll Total: " .. total)

        if self:IsInitiativeAction(action) then
            self:AddInitiativeEntry(targetPanel.TargetName, total, roll, modifier + affectModifier.total)
        end

        local effectDice = effectDropdown.Value or "None"
        if effectDice ~= "None" then
            local effectRoll, _, _, effectRolls = self:RollDiceExpression(effectDice)
            table.insert(lines, "Effect: " .. self:FormatDiceRoll(effectDice, effectRoll, effectRolls))
        end

        self:RecordRoll(table.concat(lines, "\n"), false)
    end)

    panel:SetScript("OnShow", function(self)
        targetDropdown.Options = DiceSim:GetTargetOptions()
        DiceSim:BringWindowToFront(self)
    end)

    canvasPanel.ActionPanel = panel
    return panel
end

function DiceSim:ToggleCanvasPanelActionPanel(canvasPanel)
    if not self:CanManageTools() then
        return
    end

    if not canvasPanel.ActionPanel then
        self:CreateCanvasPanelActionPanel(canvasPanel)
    end

    canvasPanel.ActionPanel.TargetPanel = canvasPanel
    canvasPanel.ActionPanel:SetShown(not canvasPanel.ActionPanel:IsShown())
end

function DiceSim:ClampCamera()
    local viewportWidth = self.Viewport:GetWidth()
    local viewportHeight = self.Viewport:GetHeight()
    local halfVisibleWidth = viewportWidth / (2 * self.Zoom)
    local halfVisibleHeight = viewportHeight / (2 * self.Zoom)

    if (CANVAS_WIDTH * self.Zoom) <= viewportWidth then
        self.CameraX = CANVAS_CENTER_X
    else
        self.CameraX = Clamp(self.CameraX or CANVAS_CENTER_X, halfVisibleWidth, CANVAS_WIDTH - halfVisibleWidth)
    end

    if (CANVAS_HEIGHT * self.Zoom) <= viewportHeight then
        self.CameraY = CANVAS_CENTER_Y
    else
        self.CameraY = Clamp(self.CameraY or CANVAS_CENTER_Y, halfVisibleHeight, CANVAS_HEIGHT - halfVisibleHeight)
    end
end

function DiceSim:RefreshCanvas()
    self.Zoom = Clamp(self.Zoom or 0.75, self:GetMinimumZoom(), MAX_ZOOM)
    self:ClampCamera()
    self.Canvas:SetScale(self.Zoom)
    self.Canvas:ClearAllPoints()
    self.CanvasX = (self.Viewport:GetWidth() / 2) - ((self.CameraX or CANVAS_CENTER_X) * self.Zoom)
    self.CanvasY = ((self.CameraY or CANVAS_CENTER_Y) * self.Zoom) - (self.Viewport:GetHeight() / 2)
    self.Canvas:SetPoint("TOPLEFT", self.Viewport, "TOPLEFT", self.CanvasX, self.CanvasY)
    self:RefreshCoordinateTracker()
end

function DiceSim:GetMinimumZoom()
    if not self.Viewport then
        return MIN_ZOOM
    end

    local viewportWidth = self.Viewport:GetWidth()
    local viewportHeight = self.Viewport:GetHeight()

    if viewportWidth <= 0 or viewportHeight <= 0 then
        return MIN_ZOOM
    end

    return math.max(MIN_ZOOM, math.max(viewportWidth / CANVAS_WIDTH, viewportHeight / CANVAS_HEIGHT))
end

function DiceSim:BringCanvasObjectToFront(object)
    local baseLevel = (self.Canvas and self.Canvas:GetFrameLevel() or 1) + 10
    self.CanvasObjectZIndex = math.max(self.CanvasObjectZIndex or baseLevel, baseLevel) + 10

    if self.CanvasObjectZIndex > baseLevel + 5000 then
        self.CanvasObjectZIndex = baseLevel + 10

        if self.CanvasObjects then
            for _, canvasObject in ipairs(self.CanvasObjects) do
                canvasObject:SetFrameLevel(baseLevel)
            end
        end

        if self.CanvasSymbols then
            for _, symbol in pairs(self.CanvasSymbols) do
                symbol:SetFrameLevel(baseLevel)
            end
        end
    end

    object:SetFrameLevel(self.CanvasObjectZIndex)

    if object.DeleteButton then
        object.DeleteButton:SetFrameLevel(self.CanvasObjectZIndex + 20)
    end

    if object.EditButton then
        object.EditButton:SetFrameLevel(self.CanvasObjectZIndex + 20)
    end

    if object.ActionButton then
        object.ActionButton:SetFrameLevel(self.CanvasObjectZIndex + 20)
    end

    if object.InfoButton then
        object.InfoButton:SetFrameLevel(self.CanvasObjectZIndex + 20)
    end

    if object.EditOverlay then
        object.EditOverlay:SetFrameLevel(self.CanvasObjectZIndex + 30)
    end
end

function DiceSim:RefreshCoordinateTracker()
    if not self.CoordinateText or not self.Viewport then
        return
    end

    local x = math.floor(self.CameraX or CANVAS_CENTER_X)
    local y = math.floor(self.CameraY or CANVAS_CENTER_Y)
    self.CoordinateText:SetText("X " .. x .. "  Y " .. y)
end

function DiceSim:CreateCoordinateTracker(parent)
    local theme = self.Theme
    local tracker = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tracker:SetSize(120, 28)
    tracker:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 26, 26)
    tracker:SetFrameLevel(parent:GetFrameLevel() + 9)
    tracker:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    tracker:SetBackdropColor(unpack(theme.colors.panelBg))
    tracker:SetBackdropBorderColor(unpack(theme.colors.panelBorder))

    local text = tracker:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText("X 0  Y 0")

    self.CoordinateTracker = tracker
    self.CoordinateText = text
    table.insert(self.MainContent, tracker)
    self:RefreshCoordinateTracker()
end

function DiceSim:SetZoom(zoom, anchorX, anchorY)
    local oldZoom = self.Zoom
    self.Zoom = Clamp(zoom, self:GetMinimumZoom(), MAX_ZOOM)
    if self.Zoom == oldZoom then
        return
    end
    anchorX = anchorX or (self.Viewport:GetWidth() / 2)
    anchorY = anchorY or (self.Viewport:GetHeight() / 2)
    local viewportCenterX = self.Viewport:GetWidth() / 2
    local viewportCenterY = self.Viewport:GetHeight() / 2
    local worldAnchorX = (self.CameraX or CANVAS_CENTER_X) + ((anchorX - viewportCenterX) / oldZoom)
    local worldAnchorY = (self.CameraY or CANVAS_CENTER_Y) + ((anchorY - viewportCenterY) / oldZoom)
    self.CameraX = worldAnchorX - ((anchorX - viewportCenterX) / self.Zoom)
    self.CameraY = worldAnchorY - ((anchorY - viewportCenterY) / self.Zoom)
    self:RefreshCanvas()
end

function DiceSim:GetViewportCursorPosition()
    if not self.Viewport then
        return nil, nil
    end
    local cursorX, cursorY = GetCursorPosition()
    local scale = self.Viewport:GetEffectiveScale()
    return (cursorX / scale) - self.Viewport:GetLeft(), self.Viewport:GetTop() - (cursorY / scale)
end

function DiceSim:StartPan()
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    self.IsPanning = true
    self.PanStartCursorX = cursorX / uiScale
    self.PanStartCursorY = cursorY / uiScale
    self.PanStartCameraX = self.CameraX or CANVAS_CENTER_X
    self.PanStartCameraY = self.CameraY or CANVAS_CENTER_Y
    self.Viewport:SetScript("OnUpdate", function()
        self:UpdatePan()
    end)
end

function DiceSim:StopPan()
    self.IsPanning = false
    self.Viewport:SetScript("OnUpdate", nil)
end

function DiceSim:UpdatePan()
    if not self.IsPanning then
        return
    end
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale
    self.CameraX = self.PanStartCameraX - ((cursorX - self.PanStartCursorX) / self.Zoom)
    self.CameraY = self.PanStartCameraY + ((cursorY - self.PanStartCursorY) / self.Zoom)
    self:RefreshCanvas()
end

function DiceSim:SetCanvasObjectPosition(object, x, y)
    local maxX = math.max(0, CANVAS_WIDTH - object:GetWidth())
    local maxY = math.max(0, CANVAS_HEIGHT - object:GetHeight())
    object.CanvasObjectX = Clamp(x, 0, maxX)
    object.CanvasObjectY = Clamp(y, 0, maxY)
    object:ClearAllPoints()
    object:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", object.CanvasObjectX, -object.CanvasObjectY)
end

function DiceSim:ScheduleSessionSnapshot()
    if self.IsApplyingSessionSnapshot or not self.ActiveSessionId then
        return
    end
    self.SessionSnapshotQueued = true
end

function DiceSim:UpdateCanvasObjectDrag(object)
    if not object.IsDraggingOnCanvas then
        return
    end
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale
    local deltaX = (cursorX - object.StartCursorX) / self.Zoom
    local deltaY = (object.StartCursorY - cursorY) / self.Zoom
    self:SetCanvasObjectPosition(object, object.StartCanvasObjectX + deltaX, object.StartCanvasObjectY + deltaY)
end

function DiceSim:GetCanvasCenterPosition(width, height)
    return CANVAS_CENTER_X - (width / 2), CANVAS_CENTER_Y - (height / 2)
end

function DiceSim:CenterCanvas()
    if not self.Viewport then
        return
    end
    self.CameraX = CANVAS_CENTER_X
    self.CameraY = CANVAS_CENTER_Y
    self:RefreshCanvas()
end

function DiceSim:FitScreen()
    if not self.Frame then
        return
    end
    if self.IsMinimized then
        self:Expand()
    end
    local width = UIParent:GetWidth()
    local height = UIParent:GetHeight()
    self.Frame:ClearAllPoints()
    self.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.Frame:SetSize(math.max(720, width - 80), math.max(480, height - 90))
    self:RefreshCanvas()
end

function DiceSim:GetPanelTypeCount(panelType)
    local used = {}
    if self.CanvasObjects then
        for _, object in ipairs(self.CanvasObjects) do
            if object:IsShown() and object.PanelType == panelType and object.PanelNumber then
                used[object.PanelNumber] = true
            end
        end
    end
    local number = 1
    while used[number] do
        number = number + 1
    end
    return number
end

function DiceSim:RemoveCanvasObject(object)
    if not object then
        return
    end
    object:Hide()
    if object.EditOverlay then
        object.EditOverlay:Hide()
    end
    if object.ActionPanel then
        object.ActionPanel:Hide()
    end
    if self.BuffDebuffPanel and self.BuffDebuffPanel.Context == object then
        self.BuffDebuffPanel:Hide()
    end
    self:RefreshDiceTargets()
    self:SaveSessionSnapshot()
end

function DiceSim:CreateCanvasMetricBar(parent, color, topAnchor)
    local bar = CreateMetricBar(parent, color)
    bar.Color = color
    bar:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -6)
    bar:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    bar:SetHeight(12)
    return bar
end

function DiceSim:MakeCanvasMetricEditable(bar)
    if not bar or bar.MetricInput then
        return
    end

    bar:EnableMouse(true)

    local input = CreateInputBox(bar, 74, 18)
    input:SetPoint("CENTER", bar, "CENTER", 0, 0)
    input:SetNumeric(false)
    input:SetMaxLetters(11)
    input:Hide()
    bar.MetricInput = input

    local function applyValue()
        if not input:IsShown() then
            return
        end

        local text = input:GetText() or ""
        local valueText, maxText = string.match(text, "^%s*(%-?%d+)%s*/%s*(%d+)%s*$")
        local value = tonumber(valueText or text)
        local maximum = tonumber(maxText) or tonumber(bar.MetricMax) or 100
        if value then
            self:SetMetricBar(bar, value, math.max(0, maximum, value))
            if self.ScheduleSessionSnapshot then
                self:ScheduleSessionSnapshot()
            end
        end

        input:Hide()
    end

    bar:SetScript("OnMouseDown", function()
        if not self:CanManageTools() then
            return
        end

        input:SetText(math.floor((tonumber(bar.MetricValue) or 0) + 0.5) .. "/" .. math.floor((tonumber(bar.MetricMax) or 0) + 0.5))
        input:Show()
        input:SetFocus()
        input:HighlightText()
    end)

    input:SetScript("OnEnterPressed", function()
        applyValue()
    end)
    input:SetScript("OnEscapePressed", function(self)
        self:Hide()
        self:ClearFocus()
    end)
    input:SetScript("OnEditFocusLost", function()
        applyValue()
    end)
end

function DiceSim:CreateCanvasPanelEditOverlay(panel)
    local theme = self.Theme
    local overlay = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    overlay:SetAllPoints(panel)
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    overlay:SetBackdropColor(unpack(theme.colors.panelBg))
    overlay:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
    overlay:SetFrameLevel(panel:GetFrameLevel() + 5)
    overlay:Hide()

    local closeButton = CreateTrayButton(overlay, nil, "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -8, -8)
    WireCloseButton(closeButton, function()
        overlay:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, overlay, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", overlay, "TOPLEFT", 8, -38)
    scrollFrame:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -28, 8)
    ApplyScrollBarSkin(scrollFrame)

    local editContent = CreateFrame("Frame", nil, scrollFrame)
    editContent:SetSize(CANVAS_OBJECT_PANEL_WIDTH - 44, 560)
    scrollFrame:SetScrollChild(editContent)
    overlay.ScrollFrame = scrollFrame
    overlay.EditContent = editContent

    local portraitTitle = CreateLabel(editContent, "Portrait")
    portraitTitle:SetPoint("TOP", editContent, "TOP", 0, -2)

    local portraitButton = CreateFrame("Button", nil, editContent)
    portraitButton:SetPoint("TOP", portraitTitle, "BOTTOM", 0, -6)
    portraitButton:SetSize(70, 70)
    overlay.PortraitButton = portraitButton

    local portraitPreview = portraitButton:CreateTexture(nil, "ARTWORK")
    portraitPreview:SetPoint("CENTER")
    portraitPreview:SetSize(48, 48)
    portraitPreview:SetTexture(panel.Portrait:GetTexture())
    portraitButton.Preview = portraitPreview

    local portraitRing = portraitButton:CreateTexture(nil, "OVERLAY")
    portraitRing:SetAllPoints()
    self:ApplyTextureOrAtlas(portraitRing, "Artifacts-PerkRing-Final")
    portraitButton.Ring = portraitRing

    local portraitGlow = portraitButton:CreateTexture(nil, "HIGHLIGHT")
    portraitGlow:SetAllPoints()
    self:ApplyTextureOrAtlas(portraitGlow, "Artifacts-PerkRing-Final")
    portraitGlow:SetBlendMode("ADD")
    portraitGlow:SetVertexColor(1.0, 0.74, 0.22, 0.9)
    portraitButton:SetHighlightTexture(portraitGlow, "ADD")

    portraitButton:SetScript("OnClick", function()
        self:OpenPortraitPicker(function(path)
            panel.Portrait:SetTexture(path)
            portraitPreview:SetTexture(path)
            portraitButton.SelectedPortrait = path
            self:ScheduleSessionSnapshot()
        end, panel.Portrait:GetTexture())
    end)

    local portraitDivider = CreateDivider(editContent)
    portraitDivider:SetPoint("TOP", portraitButton, "BOTTOM", 0, -10)
    portraitDivider:SetWidth(210)

    local titleLabel = CreateLabel(editContent, "Title")
    titleLabel:SetPoint("TOP", portraitDivider, "BOTTOM", 0, -10)

    local nameInput = CreateTextInputBox(editContent, 176, 28, 40, false)
    nameInput:SetPoint("TOP", titleLabel, "BOTTOM", 0, -4)
    nameInput:SetJustifyH("CENTER")
    nameInput:SetText(panel.TargetName)
    SetInputPlaceholder(nameInput, "Enemy name")
    nameInput:SetScript("OnEnterPressed", function(self)
        panel.TargetName = self:GetText()
        panel.NameLabel:SetText(panel.TargetName)
        self:ClearFocus()
        DiceSim:RefreshDiceTargets()
    end)
    overlay.NameInput = nameInput

local contentWidth = CANVAS_OBJECT_PANEL_WIDTH - 54
local buttonWidth = 130

local function CenterButton(button, anchor, yOffset, width, height)
    button:ClearAllPoints()
    button:SetSize(width or buttonWidth, height or 28)
    button:SetPoint("TOP", anchor, "BOTTOM", 0, yOffset)

    FitPanelButtonLabel(button)
end

local metricRows = {}

local function createMetricEditorRow(label, bar, anchor)
    local row = CreateFrame("Frame", nil, editContent)
    row:SetSize(contentWidth, 24)
    row:SetPoint("TOP", anchor, "BOTTOM", 0, -8)

    local rowLabel = CreateLabel(row, label)
    rowLabel:SetWidth(46)
    rowLabel:SetJustifyH("RIGHT")
    rowLabel:SetPoint("LEFT", row, "LEFT", 0, 0)

    local minus = CreateTrayButton(row, nil, "Interface\\Buttons\\UI-MinusButton-Up", "Decrease " .. label)
    minus:SetPoint("LEFT", rowLabel, "RIGHT", 6, 0)

    local plus = CreateTrayButton(row, nil, "Interface\\Buttons\\UI-PlusButton-Up", "Increase " .. label)
    plus:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    local miniBar = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
    miniBar:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    miniBar:SetPoint("RIGHT", plus, "LEFT", -6, 0)
    miniBar:SetHeight(12)
    miniBar:SetStatusBarTexture(bar.MetricTexture or "Interface\\Buttons\\WHITE8X8")
    miniBar:SetStatusBarColor(1, 1, 1, 1)
    miniBar:SetMinMaxValues(0, 100)
    miniBar:SetValue(100)
    miniBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    miniBar:SetBackdropColor(unpack(theme.colors.insetBg))
    miniBar:SetBackdropBorderColor(unpack(theme.colors.insetBorder))
    miniBar.Color = bar.Color
    miniBar.MetricValue = bar.MetricValue
    miniBar.MetricMax = bar.MetricMax
    miniBar.MetricStep = bar.MetricStep

    local miniText = miniBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    miniText:SetPoint("CENTER")
    miniBar.Text = miniText

    self:LinkMetricBars(bar, miniBar)
    self:MakeCanvasMetricEditable(bar)
    self:MakeCanvasMetricEditable(miniBar)

    minus:SetScript("OnClick", function()
        self:AdjustMetricBar(bar, -1)
    end)

    plus:SetScript("OnClick", function()
        self:AdjustMetricBar(bar, 1)
    end)

    table.insert(metricRows, row)
    return row
end

local hpRow = createMetricEditorRow("HP", panel.HPBar, nameInput)
local energyRow = createMetricEditorRow("Energy", panel.EnergyBar, hpRow)
local armorRow = createMetricEditorRow("Armor", panel.ArmorBar, energyRow)

local topDivider = CreateDivider(editContent)
topDivider:SetPoint("TOP", armorRow, "BOTTOM", 0, -12)
topDivider:SetWidth(contentWidth)

local buffLabel = CreateLabel(editContent, "Buffs")
buffLabel:SetPoint("TOP", topDivider, "BOTTOM", 0, -12)
buffLabel:SetWidth(contentWidth)
buffLabel:SetJustifyH("CENTER")

local buffRow = CreateFrame("Frame", nil, editContent)
buffRow:SetSize(contentWidth, 46)
buffRow:SetPoint("TOP", buffLabel, "BOTTOM", 0, -4)

local buffStrip = CreateHorizontalIconStrip(buffRow)
buffStrip:SetSize(210, 46)
buffStrip.IconSize = 34
buffStrip.HideIconBackdrop = true
buffStrip.OwnerContext = panel
buffStrip:SetPoint("CENTER", buffRow, "CENTER", 0, 0)
panel.EditBuffStrip = buffStrip

local buffMinus = CreateTrayButton(buffRow, nil, "Interface\\Buttons\\UI-MinusButton-Up", "Remove Buff")
buffMinus:SetPoint("LEFT", buffRow, "LEFT", 0, 0)
buffMinus:SetScript("OnClick", function()
    self:SetAffectRemoveMode(buffStrip, buffMinus)
end)

local buffPlus = CreateTrayButton(buffRow, nil, "Interface\\Buttons\\UI-PlusButton-Up", "Add Buff")
buffPlus:SetPoint("RIGHT", buffRow, "RIGHT", 0, 0)
buffPlus:SetScript("OnClick", function()
    self:OpenBuffDebuffPanel(panel, "buff")
end)

local debuffLabel = CreateLabel(editContent, "Debuffs")
debuffLabel:SetPoint("TOP", buffRow, "BOTTOM", 0, -8)
debuffLabel:SetWidth(contentWidth)
debuffLabel:SetJustifyH("CENTER")

local debuffRow = CreateFrame("Frame", nil, editContent)
debuffRow:SetSize(contentWidth, 46)
debuffRow:SetPoint("TOP", debuffLabel, "BOTTOM", 0, -4)

local debuffStrip = CreateHorizontalIconStrip(debuffRow)
debuffStrip:SetSize(210, 46)
debuffStrip.IconSize = 34
debuffStrip.HideIconBackdrop = true
debuffStrip.OwnerContext = panel
debuffStrip:SetPoint("CENTER", debuffRow, "CENTER", 0, 0)
panel.EditDebuffStrip = debuffStrip

local debuffMinus = CreateTrayButton(debuffRow, nil, "Interface\\Buttons\\UI-MinusButton-Up", "Remove Debuff")
debuffMinus:SetPoint("LEFT", debuffRow, "LEFT", 0, 0)
debuffMinus:SetScript("OnClick", function()
    self:SetAffectRemoveMode(debuffStrip, debuffMinus)
end)

local debuffPlus = CreateTrayButton(debuffRow, nil, "Interface\\Buttons\\UI-PlusButton-Up", "Add Debuff")
debuffPlus:SetPoint("RIGHT", debuffRow, "RIGHT", 0, 0)
debuffPlus:SetScript("OnClick", function()
    self:OpenBuffDebuffPanel(panel, "debuff")
end)

local buffDivider = CreateDivider(editContent)
buffDivider:SetPoint("TOP", debuffRow, "BOTTOM", 0, -12)
buffDivider:SetWidth(contentWidth)

local doneButton = CreatePanelButton(editContent, "Done editing")
CenterButton(doneButton, buffDivider, -12, 130, 30)
doneButton:SetScript("OnClick", function()
        panel.TargetName = nameInput:GetText()
        panel.NameLabel:SetText(panel.TargetName)
        overlay:Hide()
        DiceSim:RefreshDiceTargets()
        DiceSim:SaveSessionSnapshot()
    end)

    panel.EditOverlay = overlay
    panel.EditButton:SetScript("OnClick", function()
        if not self:CanManageTools() then
            return
        end

        if not panel.EditOverlay then
            self:CreateCanvasPanelEditOverlay(panel)
        end

        if self.SyncAffectEditStrips then
            self:SyncAffectEditStrips(panel)
        end
        panel.EditOverlay:SetShown(not panel.EditOverlay:IsShown())
        self:BringCanvasObjectToFront(panel)
    end)

    return overlay
end

function DiceSim:CreateCanvasPanel(panelType)
    if not self:CanManageTools() and not self.IsApplyingSessionSnapshot then
        print("DiceSim: only admins and assistant admins can add panels.")
        return nil
    end

    local config = PANEL_TYPES[panelType] or PANEL_TYPES.Neutral
    self.CanvasObjects = self.CanvasObjects or {}
    local number = self:GetPanelTypeCount(panelType)
    local targetName = panelType .. " " .. number

    local panel = CreateFrame("Button", nil, self.Canvas, "BackdropTemplate")
    panel:SetSize(CANVAS_OBJECT_PANEL_WIDTH, CANVAS_OBJECT_PANEL_HEIGHT)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    panel:SetBackdropColor(unpack(self.Theme.colors.panelBg))
    panel:SetBackdropBorderColor(config.border[1], config.border[2], config.border[3], config.border[4])
    panel:SetClipsChildren(true)
    panel.PanelType = panelType
    panel.PanelNumber = number
    panel.TargetName = targetName

    local backgroundArt = panel:CreateTexture(nil, "BORDER")
    backgroundArt:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -6)
    backgroundArt:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 6)
    self:ApplyTextureOrAtlas(backgroundArt, config.background)
    backgroundArt:SetAlpha(0.58)
    panel.BackgroundArt = backgroundArt

    local infoButton = CreateContainerInfoButton(panel)
    infoButton:ClearAllPoints()
    infoButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    infoButton:SetScript("OnClick", function()
        self:OpenTutorial("canvasPanel")
    end)
    panel.InfoButton = infoButton

    local numberLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    numberLabel:SetPoint("LEFT", infoButton, "RIGHT", 2, 0)
    numberLabel:SetText("#" .. number)
    panel.NumberLabel = numberLabel

    local deleteButton = CreateTrayButton(panel, nil, self.Theme.textures.remove, "Remove")
    deleteButton:SetSize(30, 30)
    deleteButton.IconSize = 25
    deleteButton.Icon:SetSize(25, 25)
    deleteButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    deleteButton:SetScript("OnClick", function()
        if not self:CanDeleteCanvasObjects() then
            return
        end

        self:RemoveCanvasObject(panel)
    end)
    panel.DeleteButton = deleteButton
    deleteButton:SetShown(self:CanDeleteCanvasObjects())

    local editButton = CreateEditButton(panel, nil)
    editButton:SetPoint("TOPRIGHT", deleteButton, "TOPLEFT", -3, 0)
    panel.EditButton = editButton

    local actionButton = CreateTrayButton(panel, nil, self.Theme.textures.actionDice, "Actions")
    actionButton:SetSize(self.Theme.sizes.smallIconButton, self.Theme.sizes.smallIconButton)
    actionButton.IconSize = self.Theme.sizes.smallIcon
    actionButton.Icon:SetSize(self.Theme.sizes.smallIcon, self.Theme.sizes.smallIcon)
    actionButton.AtlasSet = {
        normal = self.Theme.textures.actionDice,
        hover = self.Theme.textures.actionDiceHover,
        pressed = self.Theme.textures.actionDiceHover,
        disabled = self.Theme.textures.actionDice,
    }
    actionButton:SetPoint("TOPRIGHT", editButton, "TOPLEFT", -3, 0)
    actionButton:SetScript("OnClick", function()
        self:ToggleCanvasPanelActionPanel(panel)
    end)
    panel.ActionButton = actionButton
    actionButton:SetShown(self:CanManageTools())

    local contentWidth = 220
    local barWidth = 220
    local iconSize = 30
    local iconGap = 6
    local iconCount = 6
    local iconRowWidth = (iconSize * iconCount) + (iconGap * (iconCount - 1))

    local portrait = panel:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(52, 52)
    portrait:SetPoint("TOP", panel, "TOP", 0, -12)
    portrait:SetTexture(config.portrait)

    local mask = panel:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(portrait)
    portrait:AddMaskTexture(mask)

    local name = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    name:SetPoint("TOP", portrait, "BOTTOM", 0, -8)
    name:SetWidth(contentWidth)
    name:SetJustifyH("CENTER")
    name:SetText(targetName)
    panel.NameLabel = name
    panel.Portrait = portrait

    local divider = CreateDivider(panel)
    divider:SetPoint("TOP", name, "BOTTOM", 0, -10)
    divider:SetWidth(contentWidth)

    local function CreateCenteredMetric(labelText, anchor, color, current, max)
        local label = CreateLabel(panel, labelText)
        label:SetPoint("TOP", anchor, "BOTTOM", 0, -8)
        label:SetWidth(contentWidth)
        label:SetJustifyH("CENTER")

        local bar = self:CreateCanvasMetricBar(panel, color, label)
        bar:ClearAllPoints()
        bar:SetPoint("TOP", label, "BOTTOM", 0, -4)
        bar:SetSize(barWidth, 18)

        self:SetMetricBar(bar, current, max)
        self:MakeCanvasMetricEditable(bar)

        return label, bar
    end

    local defaultHp, defaultHpMax = self:GetDefaultSheetMetric("hp")
    local defaultEnergy, defaultEnergyMax = self:GetDefaultSheetMetric("energy")
    local defaultArmor, defaultArmorMax = self:GetDefaultSheetMetric("armor")

    local hpLabel, hpBar = CreateCenteredMetric("HP", divider, { r = 0.78, g = 0.12, b = 0.12 }, defaultHp, defaultHpMax)
    panel.HPBar = hpBar

    local energyLabel, energyBar = CreateCenteredMetric("Energy", hpBar, { r = 0.92, g = 0.78, b = 0.18 }, defaultEnergy, defaultEnergyMax)
    panel.EnergyBar = energyBar

    local armorLabel, armorBar = CreateCenteredMetric("Armor", energyBar, { r = 0.18, g = 0.45, b = 0.95 }, defaultArmor, defaultArmorMax)
    panel.ArmorBar = armorBar

    local lowerDivider = CreateDivider(panel)
    lowerDivider:SetPoint("TOP", armorBar, "BOTTOM", 0, -12)
    lowerDivider:SetWidth(contentWidth)

    local buffLabel = CreateLabel(panel, "Buffs")
    buffLabel:SetPoint("TOP", lowerDivider, "BOTTOM", 0, -10)
    buffLabel:SetWidth(contentWidth)
    buffLabel:SetJustifyH("CENTER")

    local buffStrip = CreateHorizontalIconStrip(panel)
    buffStrip:SetSize(iconRowWidth, 42)
    buffStrip:SetPoint("TOP", buffLabel, "BOTTOM", 0, -4)
    buffStrip.HideIconBackdrop = true
    buffStrip.IconSize = iconSize
    buffStrip.OwnerContext = panel
    panel.BuffStrip = buffStrip

    local debuffLabel = CreateLabel(panel, "Debuffs")
    debuffLabel:SetPoint("TOP", buffStrip, "BOTTOM", 0, -10)
    debuffLabel:SetWidth(contentWidth)
    debuffLabel:SetJustifyH("CENTER")

    local debuffStrip = CreateHorizontalIconStrip(panel)
    debuffStrip:SetSize(iconRowWidth, 42)
    debuffStrip:SetPoint("TOP", debuffLabel, "BOTTOM", 0, -4)
    debuffStrip.HideIconBackdrop = true
    debuffStrip.IconSize = iconSize
    debuffStrip.OwnerContext = panel
    panel.DebuffStrip = debuffStrip

    MakeCanvasObjectDraggable(self, panel)
    self:BringCanvasObjectToFront(panel)
    panel.EditButton:SetScript("OnClick", function()
        if not self:CanManageTools() then
            return
        end

        if not panel.EditOverlay then
            self:CreateCanvasPanelEditOverlay(panel)
        end

        if self.SyncAffectEditStrips then
            self:SyncAffectEditStrips(panel)
        end
        panel.EditOverlay:SetShown(not panel.EditOverlay:IsShown())
        self:BringCanvasObjectToFront(panel)
    end)

    local x, y = self:GetCanvasCenterPosition(panel:GetWidth(), panel:GetHeight())
    self:SetCanvasObjectPosition(panel, x, y)
    self:BringCanvasObjectToFront(panel)
    table.insert(self.CanvasObjects, panel)
    self:RefreshDiceTargets()
    self:SaveSessionSnapshot()
    return panel
end

function DiceSim:CreateCanvasSymbol(marker)
    if not self:CanManageTools() and not self.IsApplyingSessionSnapshot then
        print("DiceSim: only admins and assistant admins can add symbols.")
        return nil
    end

    self.CanvasSymbols = self.CanvasSymbols or {}

    if self.CanvasSymbols[marker.label] then
        if not self:CanDeleteCanvasObjects() then
            return self.CanvasSymbols[marker.label]
        end

        self.CanvasSymbols[marker.label]:Hide()
        self.CanvasSymbols[marker.label] = nil
        self:SaveSessionSnapshot()
        return nil
    end

    local token = CreateFrame("Button", nil, self.Canvas)
    token:SetSize(72, 72)

    local icon = token:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(58, 58)
    if not self:ApplyTextureOrAtlas(icon, marker.icon) then
        icon:SetTexture(marker.icon)
    end
    token.IconPath = marker.icon

    MakeCanvasObjectDraggable(self, token)
    self:BringCanvasObjectToFront(token)

    local x, y = self:GetCanvasCenterPosition(token:GetWidth(), token:GetHeight())
    self:SetCanvasObjectPosition(token, x, y)
    self:BringCanvasObjectToFront(token)
    self.CanvasSymbols[marker.label] = token
    self:SaveSessionSnapshot()
    return token
end

function DiceSim:CreateGrid()
    local background = self.Canvas:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(self.Canvas)
    background:SetAlpha(0.82)
    background:Hide()
    self.CanvasBackgroundTexture = background

    local major = 64
    for x = 0, CANVAS_WIDTH, major do
        local line = self.Canvas:CreateTexture(nil, "BORDER")
        line:SetColorTexture(0.46, 0.34, 0.16, x % 512 == 0 and 0.34 or 0.12)
        line:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", x, 0)
        line:SetPoint("BOTTOMLEFT", self.Canvas, "BOTTOMLEFT", x, 0)
        line:SetWidth(1)
    end

    for y = 0, CANVAS_HEIGHT, major do
        local line = self.Canvas:CreateTexture(nil, "BORDER")
        line:SetColorTexture(0.46, 0.34, 0.16, y % 512 == 0 and 0.34 or 0.12)
        line:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", 0, -y)
        line:SetPoint("TOPRIGHT", self.Canvas, "TOPRIGHT", 0, -y)
        line:SetHeight(1)
    end

    local horizontal = self.Canvas:CreateTexture(nil, "OVERLAY")
    horizontal:SetColorTexture(1.00, 0.74, 0.22, 0.95)
    horizontal:SetPoint("CENTER", self.Canvas, "TOPLEFT", CANVAS_CENTER_X, -CANVAS_CENTER_Y)
    horizontal:SetSize(90, 2)

    local vertical = self.Canvas:CreateTexture(nil, "OVERLAY")
    vertical:SetColorTexture(1.00, 0.74, 0.22, 0.95)
    vertical:SetPoint("CENTER", self.Canvas, "TOPLEFT", CANVAS_CENTER_X, -CANVAS_CENTER_Y)
    vertical:SetSize(2, 90)

    local dot = self.Canvas:CreateTexture(nil, "OVERLAY")
    dot:SetColorTexture(1.0, 0.74, 0.22, 1)
    dot:SetPoint("CENTER", self.Canvas, "TOPLEFT", CANVAS_CENTER_X, -CANVAS_CENTER_Y)
    dot:SetSize(8, 8)

    local label = self.Canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", dot, "BOTTOM", 0, -6)
    label:SetText("CENTER")
    label:SetTextColor(0.78, 0.94, 1.0, 1)
end

function DiceSim:SetCanvasBackground(value, label)
    value = value or "default"
    self.CanvasBackground = value
    self.CanvasBackgroundLabel = label or "Default"

    if self.CanvasBackgroundTexture then
        if value == "default" then
            self.CanvasBackgroundTexture:Hide()
        else
            if self:ApplyTextureOrAtlas(self.CanvasBackgroundTexture, value) then
                self.CanvasBackgroundTexture:Show()
            else
                self.CanvasBackgroundTexture:Hide()
            end
        end
    end

    if self.AddPanel and self.AddPanel.BackgroundDropdown then
        self.AddPanel.BackgroundDropdown.Value = value
        self.AddPanel.BackgroundDropdown.Label:SetText(self.CanvasBackgroundLabel)
    end

    self:ScheduleSessionSnapshot()
end
