-- Dice roll panel UI and behavior.

local DiceSim = _G.DiceSim

function DiceSim:SetDiceOutput(text)
    if self.DiceOutputText then
        self.DiceOutputText:SetText(text)
    end
end

function DiceSim:CreateDicePanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimDicePanel", 420, 430)
    panel.TutorialKey = "dice"
    panel:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 8)

    local closeButton = CreateTrayButton(panel, "DiceSimDicePanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Roll Your Dice")

    local diceTypeLabel = CreateLabel(panel, "Dice Type")
    diceTypeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -58)

    local modifiersLabel = CreateLabel(panel, "Modifiers")
    modifiersLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 218, -58)

    local diceType = CreateDropdownField(panel, "D20", DICE_OPTIONS)
    diceType:SetPoint("TOPLEFT", diceTypeLabel, "BOTTOMLEFT", 0, -6)
    diceType:SetWidth(184)
    diceType.Value = "D20"
    self.DiceTypeField = diceType

    local modifiers = CreateInputBox(panel, 184, 34)
    modifiers:SetPoint("TOPLEFT", modifiersLabel, "BOTTOMLEFT", 0, -6)
    modifiers:SetWidth(184)
    modifiers:SetNumeric(false)
    modifiers:SetText("0")
    SetInputPlaceholder(modifiers, "+/- modifier")
    self.ModifierInput = modifiers

    local actionLabel = CreateLabel(panel, "Action")
    actionLabel:SetPoint("TOPLEFT", diceType, "BOTTOMLEFT", 0, -16)

    local targetLabel = CreateLabel(panel, "Target")
    targetLabel:SetPoint("TOPLEFT", modifiers, "BOTTOMLEFT", 0, -16)

    local action = CreateDropdownField(panel, "STR", self:GetActionOptions())
    action:SetPoint("TOPLEFT", actionLabel, "BOTTOMLEFT", 0, -6)
    action:SetWidth(184)
    action.Value = "default:str:melee_attack"
    action.Label:SetText("Melee Attack")
    action.RefreshOptions = function()
        return self:GetActionOptions()
    end
    action.OnSelect = function(value, option)
        self:ApplyActionSelection(action, value, option)
    end
    self.ActionField = action

    local target = CreateDropdownField(panel, "None", self:GetTargetOptions())
    target:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -6)
    target:SetWidth(184)
    target.Value = "None"
    target.RefreshOptions = function()
        return self:GetTargetOptions()
    end
    self.DiceTargetField = target

    local customLabel = CreateLabel(panel, "Custom Action")
    customLabel:SetPoint("TOPLEFT", action, "BOTTOMLEFT", 0, -14)

    local effectLabel = CreateLabel(panel, "Effect Dice")
    effectLabel:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 0, -14)

    local customAction = CreateTextInputBox(panel, 184, 30, 40, false)
    customAction:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -6)
    customAction:SetText("")
    SetInputPlaceholder(customAction, "Custom action")
    self.CustomActionInput = customAction

    local effectDice = CreateDropdownField(panel, "None", EFFECT_DICE_OPTIONS)
    effectDice:SetPoint("TOPLEFT", effectLabel, "BOTTOMLEFT", 0, -6)
    effectDice:SetWidth(184)
    effectDice.Value = "None"
    self.EffectDiceField = effectDice

    local divider = CreateDivider(panel)
    divider:SetPoint("TOPLEFT", customAction, "BOTTOMLEFT", 0, -18)
    divider:SetPoint("TOPRIGHT", effectDice, "BOTTOMRIGHT", 0, -18)

    local resultArea = CreateFrame("Frame", nil, panel)
    resultArea:SetHeight(126)
    resultArea:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -16)
    resultArea:SetPoint("RIGHT", panel, "RIGHT", -18, 0)

    local outputBox = CreateFrame("Frame", nil, resultArea, "BackdropTemplate")
    outputBox:SetPoint("TOPLEFT", resultArea, "TOPLEFT", 10, -10)
    outputBox:SetPoint("RIGHT", resultArea, "RIGHT", -10, 0)
    outputBox:SetHeight(76)
    self:ApplyBackdrop(outputBox, self.Theme.colors.insetBg, self.Theme.colors.insetBorder, 1)

    local outputText = outputBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    outputText:SetPoint("TOPLEFT", outputBox, "TOPLEFT", 8, -7)
    outputText:SetPoint("BOTTOMRIGHT", outputBox, "BOTTOMRIGHT", -8, 7)
    outputText:SetJustifyH("LEFT")
    outputText:SetJustifyV("TOP")
    outputText:SetNonSpaceWrap(true)
    outputText:SetText("Roll results will appear here.")
    self.DiceOutputText = outputText

    local rollButton = CreateTrayButton(resultArea, "DiceSimRollButton", self.Theme.textures.rollDice, "Roll")
    rollButton:SetSize(42, 42)
    rollButton.IconSize = 34
    rollButton.Icon:SetSize(34, 34)
    rollButton:SetPoint("CENTER", resultArea, "CENTER", 0, -42)
    rollButton:SetScript("OnClick", function()
        self:RefreshDiceTargets()
        self:RollDice()
    end)

    self.DicePanel = panel
    return panel
end
